### 
# This file implements a layoutable type FormattedLabel that is quite similar to the 
# Label type. We do so to avoid type piracy from Makie. The only thing by which 
# FormattedLabel and Label differ (for now) is the use of `formattedtext!` instead of `text!`
# to print the text. We also adjusted the defaults so that text is 
# - valign = :top
# - halign = :left
# - tellwidth = false
#
# Note: All implementation details of Label are spread across three files. We have combined
# those details into one file here.


export FormattedLabel

# imports
using Makie.MakieLayout
import Makie.MakieLayout: @Layoutable, layoutable, get_topscene,
                          @documented_attributes, lift_parent_attribute, docvarstring,
                          subtheme, LayoutObservables, round_to_IRect2D


# from src/makielayout/types.jl
@Layoutable FormattedLabel


# from Makie/src/makielayout/default_attributes.jl
function default_attributes(::Type{FormattedLabel}, scene)
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
        "Controls if the background is visible."
        backgroundvisible = true
        "The color of the background. "
        backgroundcolor = RGBf(0.9, 0.9, 0.9)
        "The line width of the rectangle's border."
        strokewidth = 1f0
        "Controls if the border of the rectangle is visible."
        strokevisible = true
        "The color of the border."
        strokecolor = RGBf(0, 0, 0)
    end
    (attributes = attrs, documentation = docdict, defaults = defaultdict)
end

@doc """
FormattedLabel has the following attributes:

$(let
    _, docs, defaults = default_attributes(FormattedLabel, nothing)
    docvarstring(docs, defaults)
end)
"""
FormattedLabel


# from Makie/src/makielayout/layoutables/label.jl
function layoutable(::Type{FormattedLabel}, fig_or_scene, text; kwargs...)
    layoutable(FormattedLabel, fig_or_scene; text = text, kwargs...)
end


function layoutable(::Type{FormattedLabel}, fig_or_scene; bbox = nothing, kwargs...)

    topscene = get_topscene(fig_or_scene)
    default_attrs = default_attributes(FormattedLabel, topscene).attributes
    theme_attrs = subtheme(topscene, :FormattedLabel)
    attrs = merge!(merge!(Attributes(kwargs), theme_attrs), default_attrs)

    @extract attrs (text, textsize, font, color, visible, halign, valign,
                    rotation, padding, strokecolor, strokewidth, strokevisible,
                    backgroundcolor, backgroundvisible, tellwidth, tellheight)

    layoutobservables = LayoutObservables(attrs.width, attrs.height, 
                                          attrs.tellwidth, attrs.tellheight, halign, valign, 
                                          attrs.alignmode; suggestedbbox = bbox)

    strokecolor_with_visibility = lift(strokecolor, strokevisible) do col, vis
        vis ? col : RGBAf(0, 0, 0, 0)
    end

    textpos = Observable(Point3f(0, 0, 0))

    ibbox = lift(layoutobservables.computedbbox) do bbox
        round_to_IRect2D(bbox)
    end
    bg = poly!(topscene, ibbox, color = backgroundcolor, visible = backgroundvisible,
               strokecolor = strokecolor_with_visibility, strokewidth = strokewidth,
               inspectable = false)

    # here we use now formattedtext! instead of text!
    fmttxt = formattedtext!(topscene, text, position = textpos, textsize = textsize, 
        font = font, color = color, visible = visible, align = (halign, valign), 
        rotation = rotation, markerspace = :data, justification = attrs.justification,
        lineheight = attrs.lineheight, inspectable = false)

    onany(layoutobservables.computedbbox, padding, valign, halign, tellwidth, tellheight) do bbox, 
            padding, valign, halign, tellwidth, tellheight

        textbb = Rect2f(boundingbox(fmttxt))
        tw, th = width(textbb), height(textbb)
        w, h = width(bbox), height(bbox)
        println("Dimensions: $w, $h, $th")
        box, boy = bbox.origin

        # position text
        tx = box + padding[1]
        tx += if halign === :right
            w
        elseif halign === :center
            0.5 * w
        elseif halign === :left
            0
        end
        ty = boy + padding[3]
        ty += if valign === :top
            h
        elseif valign === :center
            0.5 * h
        elseif valign === :bottom
            0
        end
        textpos[] = Point3f(tx, ty, 0)
        println("Text position: $(textpos[])")

        # trigger text wrapping
        println("       $tw, $w")
        fmttxt.maxwidth[] = w

        if h != th
            println("   Line height: $h -> $th")
            layoutobservables.autosize[] = (nothing, th)
            # layoutobservables.computedbbox[] = Rect2f(box, boy, w + padding[1] + padding[2], th)
            return
        end
    end

    lt = FormattedLabel(fig_or_scene, layoutobservables, attrs, 
                        Dict(:formattedtext => fmttxt, :background => bg))

    lt
end
