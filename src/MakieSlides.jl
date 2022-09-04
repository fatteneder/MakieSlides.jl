module MakieSlides


using CairoMakie
using Colors
using FileIO
using GLMakie
using JSON
using LaTeXStrings
using Makie
using Markdown
using Printf
using ZipFile
import PyCall
import Cairo


# Makie internal dependencies of formattedtext.jl, formattedcode.jl
import Makie: NativeFont, gl_bboxes, attribute_per_char, glyph_collection, RGBAf, GridLayoutBase
import MakieCore: automatic
# Makie internal dependencies of formattedlabel.jl, formattedlist, markdownbox.jl
using Makie.MakieLayout
import Makie.MakieLayout: @Block, inherit, round_to_IRect2D, initialize_block!


# Use a wrapper type to avoid type piracy for conversion pipeline of
# @Block attriubtes.
# See also https://github.com/JuliaPlots/Makie.jl/issues/2247
struct Maybe{T}
    value::Union{T,Nothing}
end
Base.convert(::Type{Maybe{T}}, x) where T = Maybe{T}(x)
Base.convert(::Type{Maybe{T}}, x::Maybe{T}) where T = x
Makie.convert_for_attribute(t::Type{Maybe{RGBAf}}, x) =
    isnothing(x) ? nothing : Maybe{RGBAf}(to_color(x))


# Resolve method ambiguity. Remove ASAP with next Makie update.
# This is type piracy!
Makie.convert_for_attribute(t::Type{Makie.FreeTypeAbstraction.FTFont},
                            x::Makie.FreeTypeAbstraction.FTFont) = to_font(x)


export Presentation, new_slide!, add_to_slide!, reset!, save
export formattedtext, formattedtext!
export FormattedLabel, FormattedList, FormattedTable, MarkdownBox, FormattedCodeblock


include("utilities.jl")
include("formattedtext.jl")
include("formattedlabel.jl")
include("formattedlist.jl")
include("formattedtable.jl")
include("formattedcode.jl")
include("formattedcodeblock.jl")
include("markdownbox.jl")


mutable struct SlideElement
    parent::Figure
    fig::Figure
    span::NTuple{2,Union{Int64,UnitRange{Int64}}}
end


function SlideElement(parent::Figure, element_scene::Scene, span;
        layout_kwargs...)
    layout = Makie.GridLayout(; layout_kwargs...)
    parent.layout[span...] = layout
    fig = Figure(element_scene, layout, [], Attributes(), Ref{Any}(nothing))
    layout.parent = fig
    return SlideElement(parent, fig, span)
end


mutable struct Presentation
    parent::Figure
    elements::Dict{Symbol,SlideElement}

    idx::Int
    slides::Vector{Dict{Symbol,Function}}
    clear::Vector{Bool}
    locked::Bool
end


function Base.getproperty(p::Presentation, s::Symbol)
    el_names = keys(getfield(p, :elements))
    if s in el_names
        return getfield(p, :elements)[s]
    else
        return getfield(p, s)
    end
end


function Base.propertynames(p::Presentation, private::Bool=false)
    return [ fieldnames(Presentation)..., keys(p.elements)... ]
end


"""
    Presentation(; kwargs...)

Creates a `pres::Presentation` with a background figure `parent::Figure`
and a set of `element::SlideElement` for slide content.
that allow to partition the slide for content placement.
The former remains static during the presentation and acts as the background and 
window. The latter act as partioning of a slide into which content can be added.
They can get cleared and reassambled every time a new slide is requested.
(This includes events.)

To add a slide use:

    new_slide!(pres)
    add_to_slide!(pres[, element = :body, clear = true]) do fig
        # Plot your content to fig
    end

Note that `new_slide!` inserts a new slides, whereas `add_to_slide!` adds content to the
currently active (or previously created) slide. The added content is drawn immediately,
this is done to get rid of compilation times beforehand.

Available slide elements:
- `:body`: the main place to put content, its the default element for `add_to_slide!`
- `:header`: space above `:body` to put dates, section titles, etc.
- `:footer`: space below `:body`, to put dates, section titles, etc.
- `:sidebar_lhs`: space left to `:body`, could be used for a quick overview
- `:sidebar_rhs`: space right to `:body`, could be used for a quick overview

To switch to a different slide:
- `next_slide!(pres)`: Advance to the next slide. Default keys: Keyboard.right, Keyboard.enter
- `previous_slide!(pres)`: Go to the previous slide. Default keys: Keyboard.left
- `reset!(pres)`: Go to the first slide. Defaults keys: Keyboard.home
- `set_slide_idx!(pres, idx)`: Go a specified slide.
"""
function Presentation(; kwargs...)
    # This is a modified version of the Figure() constructor.
    parent = Figure(; kwargs...)
    # translate!(parent.scene, 0, 0, 1) # more will be incompatible with space = :relative

    kwargs_dict = Dict(kwargs)
    padding = pop!(kwargs_dict, :figure_padding, Makie.current_default_theme()[:figure_padding])

    # Separate events from the parent (static background) and slide figure so
    # that slide events can be cleared without clearing slide events (like 
    # moving to the next slide)
    separated_events = Events()
    _events = parent.scene.events
    for fieldname in fieldnames(Events)
        obs = getfield(separated_events, fieldname)
        if obs isa Makie.AbstractObservable
            on(v -> obs[] = v, getfield(_events, fieldname), priority = 100)
        end
    end

    # we need a separate scene for each figure element so that we can
    # clear them separately
    make_scene() = Scene(parent.scene; camera=campixel!, clear = false,
                         events = separated_events, kwargs_dict...)

    elements = Dict{Symbol,SlideElement}()
    elements[:header]       = SlideElement(parent, make_scene(), (1,1:3);
                                           height=Fixed(50), tellwidth=false, valign=:top)
    elements[:sidebar_lhs]  = SlideElement(parent, make_scene(), (2,1);
                                           width=Fixed(50), tellheight=false, halign=:left)
    elements[:body]         = SlideElement(parent, make_scene(), (2,2);
                                           tellheight=false, tellwidth=false)
    elements[:sidebar_rhs]  = SlideElement(parent, make_scene(), (2,3);
                                           width=Fixed(50), tellheight=false, halign=:right)
    elements[:footer]       = SlideElement(parent, make_scene(), (3,1:3);
                                           height=Fixed(50), tellwidth=false, valign=:bottom)

    padding = padding isa Observable ? padding : Observable{Any}(padding)
    alignmode = lift(Outside ∘ Makie.to_rectsides, padding)
    on(alignmode) do al
        for (_, el) in elements
            el.fig.layout.alignmode[] = al
            GridLayoutBase.update!(el.fig.layout)
        end
    end
    notify(alignmode)

    p = Presentation(parent, elements, 1, Function[], Bool[], false)

    # Interactions
    on(events(parent.scene).keyboardbutton, priority = -1) do event
        if event.action == Keyboard.release
            if event.key in (Keyboard.right, Keyboard.enter)
                next_slide!(p)
            elseif event.key in (Keyboard.left,)
                previous_slide!(p)
            elseif event.key in (Keyboard.home,)
                reset!(p)
            end
        end
    end

    return p
end


function deactivate_element!(p::Presentation, name::Symbol)
    name ∉ keys(p.elements) && error("unknown slide element '$name'")
    el = p.elements[name]
    # remove scene
    s_idx = findfirst(s -> s === el.fig.scene, p.parent.scene.children)
    !isnothing(s_idx) && deleteat!(p.parent.scene.children, s_idx)
    # remove layout
    l_idx = findfirst(l -> l === el.fig.layout, p.parent.layout.content)
    !isnothing(l_idx) && deleteat!(p.parent.layout.content, l_idx)
    return
end


function activate_element!(p::Presentation, name::Symbol)
    name ∉ keys(p.elements) && error("unknown slide element '$name'")
    el = p.elements[name]
    # insert scene, but only if not already present
    s_idx = findfirst(s -> s === el.fig.scene, p.parent.scene.children)
    isnothing(s_idx) && push!(p.parent.scene.children, el.fig.scene)
    # insert layout, but only if not already present
    l_idx = findfirst(l -> l === el.fig.layout, p.parent.layout.content)
    isnothing(l_idx) && (p.parent.layout[el.span...] = el.fig.layout)
    return
end


function _set_slide_idx!(p::Presentation, i)
    # Moving through slides quickly seems to sometimes trigger plot insertion 
    # before or during the `empty!(fig)` procedure. This causes emptying to
    # fail and leaves orphaned plots behind. To avoid this we have a lock here
    # which disables slide changes until the previous change is finished.
    if !p.locked && i != p.idx && (1 <= i <= length(p))
        p.locked = true
        p.idx = i
        for (name, el) in p.elements
            p.clear[p.idx] && empty!(el.fig)
            f_el = get(p.slides[p.idx], name, nothing)
            !isnothing(f_el) && f_el(el.fig)
        end
        p.locked = false
    end
    return
end


function set_slide_idx!(p::Presentation, i)
    # If we jump randomly we need to start from the last cleared slide and build
    # the current slide up from there.
    N = length(p.slides)
    i = i < 1 ? 1 : i
    i = i > N ? N : i
    if p.idx == i
        return
    elseif p.clear[i]
        _set_slide_idx!(p, i)
    else
        idx = i
        while !p.clear[idx] && idx > 1
            idx -= 1
        end
        for j in idx:i
            _set_slide_idx!(p, j)
        end
    end
    return
end


Base.display(p::Presentation) = display(p.parent)
Base.length(p::Presentation) = length(p.slides)
Base.eachindex(p::Presentation) = 1:length(p.slides)
next_slide!(p::Presentation) = set_slide_idx!(p, p.idx + 1)
previous_slide!(p::Presentation) = set_slide_idx!(p, p.idx - 1)
reset!(p::Presentation) = set_slide_idx!(p, 1)
current_index(p::Presentation) = p.idx


function new_slide!(p::Presentation)
    for el in values(p.elements)
        empty!(el.fig)
    end
    push!(p.slides, Dict())
    push!(p.clear, p.idx == 1 || clear) # always clear first slide
    p.idx = length(p.slides)
end


"""
    add_to_slide!(f::Function, presentation[, clear = true])

Adds a new slide add the end of the Presentation. If `clear = true` the previous
figure will be reset before drawing.
"""
function add_to_slide!(f::Function, p::Presentation; element::Symbol = :body, clear = true)
    # This is set up to render each slide immediately to get compilation times 
    # out of the way and perhaps catch errors a bit earlier
    try
        # with_updates_suspended should stop layouting to trigger when the slide
        # gets set up. This should speed up slide creation a bit.
        fig = p.elements[element].fig
        with_updates_suspended(() -> f(fig), fig.layout)
        p.slides[p.idx][element] = f
    catch e
        @error "Failed to add slide - maybe the function signature does not match f(::Presentation)?"
        rethrow(e)
    end
    return
end


function save(name, presentation::Presentation; aspect=(16,9))
    CairoMakie.activate!()

    @assert length(presentation) > 0

    ratio = aspect[1] / aspect[2]
    width = 1400
    height = width / ratio
    resolution = (width*1.05,height*1.05) # add some border outlines

    scene = presentation.parent.scene
    resize!(scene, resolution)
    screen = CairoMakie.CairoScreen(scene, name, :pdf)

    for idx in eachindex(presentation)
        set_slide_idx!(presentation, idx)
        CairoMakie.cairo_draw(screen, scene)
        Cairo.show_page(screen.context)
        Cairo.restore(screen.context)
    end
    Cairo.finish(screen.surface)

    GLMakie.activate!()
    return
end


function save(name, p::Presentation, idx::Int)
    CairoMakie.activate!()
  
    set_slide_idx!(p, idx)
    scene = p.parent.scene
    screen = CairoMakie.CairoScreen(scene, name, :pdf)
    CairoMakie.cairo_draw(screen, scene)
    Cairo.finish(screen.surface)
  
    GLMakie.activate!()
    return
end
  

const PYGMENTS = PyCall.PyNULL()
const PYGMENTS_LEXERS = PyCall.PyNULL()
const PYGMENTS_STYLES = PyCall.PyNULL()
const PYGMENTS_LEXERS_LANG_LIST = Symbol[]
const PYGMENTS_STYLES_LIST = Symbol[]
const RGX_EMOJI = r":([^\s]+):"
const EMOJIS_MAP = Dict{String,String}()
const EMOJIS_PNG_PATH = normpath(joinpath(@__DIR__, "..", "assets", "openmoji_png"))
const EMOJIS_PADDING = 12f0
const EMOJIS_SIZE = 71f0
const EMOJIS_PNG_CACHE = Dict{String,Matrix{RGBAf}}()


function emoji_filename(shorthand, use_all_code_points=true)
    !haskey(EMOJIS_MAP, shorthand) && error("Unknown emoji shorthand '$shorthand'")
    emoji = EMOJIS_MAP[shorthand]
    if use_all_code_points
        unicodes = [ @sprintf "%04X" codepoint(c) for c in emoji ]
        return join(unicodes, "-")
    else
        return @sprintf "%04X" codepoint(emoji[begin])
    end
end

function emoji_filename_png(shorthand)
    filename = joinpath(EMOJIS_PNG_PATH, emoji_filename(shorthand) * ".png")
    isfile(filename) && return filename
    filename = joinpath(EMOJIS_PNG_PATH, emoji_filename(shorthand, false) * ".png")
    isfile(filename) && return filename
    emoji = EMOJIS_MAP[shorthand]
    error("No emoji png file found for shorthand '$shorthand' and unicode sequence " *
          "$(emoji_filename(shorthand))")
end

function load_emoji_image(shorthand)
    haskey(EMOJIS_PNG_CACHE, shorthand) && return EMOJIS_PNG_CACHE[shorthand]
    filename = emoji_filename_png(shorthand)
    img = load(filename)
    img = convert.(RGBAf, img)
    EMOJIS_PNG_CACHE[shorthand] = img
    return img
end


# workaround for Conda.exists which is currenlty broken, see
# https://github.com/JuliaPy/Conda.jl/pull/167
function conda_exists(pkgname)
    pkgs = PyCall.Conda._installed_packages()
    pkgname ∈ pkgs
end


function __init__()

    GLMakie.activate!() # Just to make sure

    # setup python
    # add a custom Julia lexer for Pygments
    if !conda_exists("pygments-julia")
        PyCall.Conda.pip("install", "git+https://github.com/sisl/pygments-julia#egg=pygments_julia")
    end
    copy!(PYGMENTS, PyCall.pyimport_conda("pygments", "pygments"))
    copy!(PYGMENTS_LEXERS, PyCall.pyimport_conda("pygments.lexers", "pygments"))
    copy!(PYGMENTS_STYLES, PyCall.pyimport_conda("pygments.styles", "pygments"))
    all_lexer_langs = [ [lex[2]...] for lex in PYGMENTS_LEXERS.get_all_lexers() ]
    copy!(PYGMENTS_LEXERS_LANG_LIST, Symbol.(vcat(all_lexer_langs...)))
    all_styles = collect(PYGMENTS_STYLES.get_all_styles())
    copy!(PYGMENTS_STYLES_LIST, Symbol.(all_styles))

    # setup emoji list
    emojis_map = JSON.parsefile(joinpath(@__DIR__, "..", "assets", "emojis.json"))
    # replace all _ in shorthands with -, because _ is parsed as emphasis in Markdown
    md_emojis_map = Dict( [ replace(sh, "_" => "-") => e for (sh, e) in pairs(emojis_map) ] )
    copy!(EMOJIS_MAP, md_emojis_map)
    if !isdir(EMOJIS_PNG_PATH)
        unzip(joinpath(@__DIR__, "..", "assets", "openmoji-png-color.zip"), EMOJIS_PNG_PATH)
    end
end


end # module
