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
import Makie: NativeFont, gl_bboxes, attribute_per_char, glyph_collection, RGBAf
import MakieCore: automatic
# Makie internal dependencies of formattedlabel.jl, formattedlist, markdownbox.jl
using Makie.MakieLayout
import Makie.MakieLayout: @Block, inherit, round_to_IRect2D, initialize_block!


# Resolve method ambiguity. Remove ASAP with next Makie update.
Makie.MakieLayout.convert_for_attribute(t::Type{Makie.FreeTypeAbstraction.FTFont},
                            x::Makie.FreeTypeAbstraction.FTFont) = to_font(x)


export Presentation, add_slide!, reset!, save
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


mutable struct Presentation
    parent::Figure
    figures::Dict{Symbol,Figure}

    idx::Int
    slides::Vector{Function}
    clear::Vector{Bool}
    locked::Bool
end


function Base.getproperty(p::Presentation, s::Symbol)
    fig_names = keys(getfield(p, :figures))
    if s in fig_names
        return getfield(p, :figures)[s]
    else
        return getfield(p, s)
    end
end


function Base.propertynames(p::Presentation, private::Bool=false)
    return [ fieldnames(Presentation)..., keys(p.figures)... ]
end



"""
    Presentation(; kwargs...)

Creates a `pres::Presentation` with a background figure `parent`
and a set of content figures `figures`.
The former remains static during the presentation and acts as the background and 
window. The latter act as thes slide and they get cleared and reassambled every
time a new slide is requested. (This includes events.)

To add a slide use:

    add_slide!(pres[, clear = true]) do fig
        # Plot your slide to fig
    end

Note that `add_slide!` immediately switches to and draws the newly added slide. 
This is done to get rid of compilation times beforehand.

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

    scene = Scene(
        parent.scene; camera=campixel!, clear = false, 
        events = separated_events, kwargs_dict...
    )

    padding = padding isa Observable ? padding : Observable{Any}(padding)
    alignmode = lift(Outside ∘ Makie.to_rectsides, padding)

    layouts = Dict{Symbol, Makie.GridLayout}()
    layouts[:header]      = Makie.GridLayout(parent[1,1:3], height=Fixed(50),
                                             tellwidth=false, valign=:top)
    layouts[:sidebar_lhs] = Makie.GridLayout(parent[2,1], width=Fixed(50),
                                             tellheight=false, halign=:left)
    layouts[:body]        = Makie.GridLayout(parent[2,2], tellheight=false, tellwidth=false)
    layouts[:sidebar_rhs] = Makie.GridLayout(parent[2,3], width=Fixed(50),
                                             tellheight=false, halign=:right)
    layouts[:footer]      = Makie.GridLayout(parent[3,1:3], height=Fixed(50),
                                             tellwidth=false, valign=:bottom)

    alignmode = lift(Outside ∘ Makie.to_rectsides, padding)
    on(alignmode) do al
        for layout in values(layouts)
            layout.alignmode[] = al
            Makie.GridLayoutBase.update!(layout)
        end
    end
    notify(alignmode)

    figures = Dict( name => Figure(scene, layout, [], Attributes(), Ref{Any}(nothing))
                    for (name, layout) in layouts )
    for (fig, layout) in zip(values(figures), values(layouts))
        layout.parent = fig
    end

    p = Presentation(parent, figures, 1, Function[], Bool[], false)

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


function _set_slide_idx!(p::Presentation, i)
    # Moving through slides quickly seems to sometimes trigger plot insertion 
    # before or during the `empty!(fig)` procedure. This causes emptying to
    # fail and leaves orphaned plots behind. To avoid this we have a lock here
    # which disables slide changes until the previous change is finished.
    if !p.locked && i != p.idx && (1 <= i <= length(p.slides))
        p.locked = true
        p.idx = i
        for (name, fig) in p.figures
            name === :body || continue
            p.clear[p.idx] && empty!(fig)
            name === :body && p.slides[p.idx](fig)
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
reset!(p::Presentation) = _set_slide_idx!(p, 1)
current_index(p::Presentation) = p.idx


"""
    add_slide!(f::Function, presentation[, clear = true])

Adds a new slide add the end of the Presentation. If `clear = true` the previous
figure will be reset before drawing.
"""
function add_slide!(f::Function, p::Presentation, clear = true)
    # This is set up to render each slide immediately to get compilation times 
    # out of the way and perhaps catch errors a bit earlier
    try
        for (name, fig) in p.figures
            name === :body || continue
            clear && empty!(fig)
            # with_updates_suspended should stop layouting to trigger when the slide
            # gets set up. This should speed up slide creation a bit.
            name === :body && with_updates_suspended(() -> f(fig), fig.layout)
        end
        push!(p.slides, f)
        push!(p.clear, p.idx == 1 || clear) # always clear first slide
        p.idx = length(p.slides)
    catch e
        @error "Failed to add slide - maybe the function signature does not match f(::Presentation)?"
        rethrow(e)
    end
    return
end


function save(name, presentation::Presentation; aspect=(16,9))
    CairoMakie.activate!()

    @assert length(presentation.slides) > 0

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
  

const pygments = PyCall.PyNULL()
const pygments_lexers = PyCall.PyNULL()
const pygments_styles = PyCall.PyNULL()
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


function __init__()
    GLMakie.activate!() # Just to make sure
    copy!(pygments, PyCall.pyimport_conda("pygments", "pygments"))
    copy!(pygments_lexers, PyCall.pyimport_conda("pygments.lexers", "pygments"))
    copy!(pygments_styles, PyCall.pyimport_conda("pygments.styles", "pygments"))
    emojis_map = JSON.parsefile(joinpath(@__DIR__, "..", "assets", "emojis.json"))
    # replace all _ in shorthands with -, because _ is parsed as emphasis in Markdown
    md_emojis_map = Dict( [ replace(sh, "_" => "-") => e for (sh, e) in pairs(emojis_map) ] )
    copy!(EMOJIS_MAP, md_emojis_map)
    if !isdir(EMOJIS_PNG_PATH)
        unzip(joinpath(@__DIR__, "..", "assets", "openmoji-png-color.zip"), EMOJIS_PNG_PATH)
    end
end


end # module
