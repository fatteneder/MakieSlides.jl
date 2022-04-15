export MarkdownBox

# imports
using Makie.MakieLayout
import Makie.MakieLayout: @Layoutable, layoutable, get_topscene,
                          @documented_attributes, lift_parent_attribute, docvarstring,
                          subtheme, LayoutObservables
using Makie.GridLayoutBase


@Layoutable MarkdownBox


# from Makie/src/makielayout/default_attributes.jl
function default_attributes(::Type{MarkdownBox}, scene)
    attrs, docdict, defaultdict = @documented_attributes begin
        "The displayed text string."
        text = "Text"
        "Controls if the text is visible."
        visible = true
        "The color of the text."
        color = lift_parent_attribute(scene, :textcolor, :black)
        "The font size of the text."
        textsize = lift_parent_attribute(scene, :fontsize, 16f0)
        "The font family of the text."
        font = lift_parent_attribute(scene, :font, "DejaVu Sans")
        "The justification of the text (:left, :right, :center)."
        justification = :left
        "The lineheight multiplier for the text."
        lineheight = 1.0
        "The vertical alignment of the text in its suggested boundingbox"
        valign = :top
        "The horizontal alignment of the text in its suggested boundingbox"
        halign = :left
        "The counterclockwise rotation of the text in radians."
        rotation = 0f0
        "The extra space added to the sides of the text boundingbox."
        padding = (0f0, 0f0, 0f0, 0f0)
        "The height setting of the text."
        height = Auto()
        "The width setting of the text."
        width = Auto()
        "Controls if the parent layout can adjust to this element's width"
        tellwidth = false
        "Controls if the parent layout can adjust to this element's height"
        tellheight = true
        "The align mode of the text in its parent GridLayout."
        alignmode = Inside()
    end
    (attributes = attrs, documentation = docdict, defaults = defaultdict)
end

@doc """
MarkdownBox has the following attributes:

$(let
    _, docs, defaults = default_attributes(MarkdownBox, nothing)
    docvarstring(docs, defaults)
end)
"""
MarkdownBox


# highjacking setindex! for GridPosition here to unpack the gridlayout from a MarkdownBox directly
# Needed for
# ```julia
#   f = Figure()
#   MarkdownBox(f[1,1], "hello world!")
# ```
# This seems hackish, but it does work out off the box for Labels.
function Base.setindex!(gp::GridPosition, mdbox::MarkdownBox)
    gp.layout[gp.span.rows, gp.span.cols, gp.side] = mdbox.elements[:gridlayout]
end


# highjacking setindex! for Figure here to unpack the gridlayout from a MarkdownBox directly
# Needed for
# ```julia
#   f = Figure()
#   f[1,1] = MarkdownBox(f, "hello world!")
# ```
# This seems hackish, but it does work out off the box for Labels.
function Base.setindex!(fig::Figure, mdbox::MarkdownBox, rows, cols, side = GridLayoutBase.Inner())
    fig.layout[rows, cols, side] = mdbox.elements[:gridlayout]
    mdbox
end


# from Makie/src/makielayout/layoutables/label.jl
function layoutable(::Type{MarkdownBox}, fig_or_scene, text::AbstractString; kwargs...)
    mdtext = Markdown.parse(text)
    layoutable(MarkdownBox, fig_or_scene; text = mdtext, kwargs...)
end


# from Makie/src/makielayout/layoutables/label.jl
function layoutable(::Type{MarkdownBox}, fig_or_scene, md::Markdown.MD; kwargs...)
    layoutable(MarkdownBox, fig_or_scene; text = md, kwargs...)
end


function layoutable(::Type{MarkdownBox}, fig_or_scene; bbox = nothing, kwargs...)

    topscene = get_topscene(fig_or_scene)
    default_attrs = default_attributes(MarkdownBox, topscene).attributes
    theme_attrs = subtheme(topscene, :MarkdownBox)
    attrs = merge!(merge!(Attributes(kwargs), theme_attrs), default_attrs)

    @extract attrs (text, textsize, font, color, visible, halign, valign,
        rotation, padding)

    layoutobservables = LayoutObservables(attrs.width, attrs.height, attrs.tellwidth, attrs.tellheight,
        halign, valign, attrs.alignmode; suggestedbbox = bbox)

    scene = fig_or_scene isa Figure ? fig_or_scene.scene : fig_or_scene

    # could also use Makie.vgrid! which is an alias to GridLayoutBase.vbox! which does just the
    # same thing as we do here
    n_elements = length(text[].content) + 1 # + 1 for spacefilling box at the end
    gridlayout = GridLayout(n_elements, 1)     
    for (idx, paragraph) in enumerate(text[].content)
        gridlayout[idx,1] = FormattedLabel(fig_or_scene, text=paragraph)
    end
    gridlayout[end, 1] = Box(fig_or_scene, tellheight=false)

    gridlayoutbb = Ref(BBox(0, 1, 0, 1))
    onany(text, textsize, font, rotation, padding) do text, textsize, font, rotation, padding
        scene = fig_or_scene isa Figure ? fig_or_scene.scene : fig_or_scene
        gridlayoutbb[] = Rect2f(boundingbox(scene))
        autowidth = width(gridlayoutbb[]) + padding[1] + padding[2]
        autoheight = height(gridlayoutbb[]) + padding[3] + padding[4]
        layoutobservables.autosize[] = (autowidth, autoheight)
    end

    textpos = Observable(Point3f(0, 0, 0))
    onany(layoutobservables.computedbbox, padding) do bbox, padding
        tw = width(gridlayoutbb[])
        th = height(gridlayoutbb[])
        box = bbox.origin[1]
        boy = bbox.origin[2]
        # this is also part of the hack to improve left alignment until
        # boundingboxes are perfect
        tx = box + padding[1] + 0.5 * tw
        ty = boy + padding[3] + 0.5 * th
        textpos[] = Point3f(tx, ty, 0)
    end

    lift(gridlayout.layoutobservables.computedbbox) do gl_bbox
        # w, h = gl_bbox.widths
        # display("$w, $h")
    end

    # trigger first update, otherwise bounds are wrong somehow
    text[] = text[]
    # trigger bbox
    layoutobservables.suggestedbbox[] = layoutobservables.suggestedbbox[]

    lt = MarkdownBox(fig_or_scene, layoutobservables, attrs, Dict(:gridlayout => gridlayout))

    lt
end
