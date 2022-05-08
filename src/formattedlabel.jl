# Note: All implementation details of @Layoutables are spread across three files within Makie.
# We have combined those details into one file here.


# from src/makielayout/types.jl
@Block FormattedLabel begin
    @attributes begin
        "The displayed text string."
        text::String = "Text"
        "Controls if the text is visible."
        visible::Bool = true
        "The color of the text."
        color::RGBAf = inherit(scene, :textcolor, :black)
        "The font size of the text."
        textsize::Float32 = inherit(scene, :fontsize, 16f0)
        "The font family of the text."
        font::Makie.FreeTypeAbstraction.FTFont = inherit(scene, :font, "DejaVu Sans")
        vjustify = :top
        "The horizontal justification of the text (:left, :right, :center)."
        hjustify = :left
        "The lineheight multiplier for the text."
        lineheight::Float32 = 1.0
        "The vertical alignment of the text in its suggested boundingbox"
        valign = :center
        "The horizontal alignment of the text in its suggested boundingbox"
        halign = :center
        "The counterclockwise rotation of the text in radians."
        rotation::Float32 = 0f0
        "The extra space added to the sides of the text boundingbox."
        padding = (0f0, 0f0, 0f0, 0f0)
        "The height setting of the text."
        height = Auto()
        "The width setting of the text."
        width = Auto()
        "Controls if the parent layout can adjust to this element's width"
        tellwidth::Bool = true
        "Controls if the parent layout can adjust to this element's height"
        tellheight::Bool = false
        "The align mode of the text in its parent GridLayout."
        alignmode = Inside()
        "Controls if the background is visible."
        backgroundvisible::Bool = false
        "The color of the background. "
        backgroundcolor::RGBAf = RGBf(0.9, 0.9, 0.9)
        "The line width of the rectangle's border."
        strokewidth::Float32 = 1f0
        "Controls if the border of the rectangle is visible."
        strokevisible::Bool = true
        "The color of the border."
        strokecolor::RGBAf = RGBf(0, 0, 0)
    end
end


# @doc """
# FormattedLabel has the following attributes:

# $(let
#     _, docs, defaults = default_attributes(FormattedLabel, nothing)
#     docvarstring(docs, defaults)
# end)
# """
# FormattedLabel


# from Makie/src/makielayout/blocks/label.jl
FormattedLabel(x, text; kwargs...) = FormattedLabel(x, text = text; kwargs...)
# function layoutable(::Type{FormattedLabel}, fig_or_scene, text; kwargs...)
#     layoutable(FormattedLabel, fig_or_scene; text = text, kwargs...)
# end


function initialize_block!(l::FormattedLabel)
    topscene = l.blockscene
    layoutobservables = l.layoutobservables

    # default_attrs = default_attributes(FormattedLabel, topscene).attributes
    # theme_attrs = subtheme(topscene, :FormattedLabel)
    # attrs = merge!(merge!(Attributes(kwargs), theme_attrs), default_attrs)

    # @extract attrs (text, textsize, font, color, visible, halign, valign,
    #                 rotation, padding, strokecolor, strokewidth, strokevisible,
    #                 backgroundcolor, backgroundvisible, hjustify, vjustify)

    # layoutobservables = LayoutObservables(attrs.width, attrs.height, 
    #                                       attrs.tellwidth, attrs.tellheight, halign, valign, 
    #                                       attrs.alignmode; suggestedbbox = bbox)

    textpos = Observable(Point3f(0, 0, 0))
    textbb = Ref(BBox(0, 1, 0, 1))

    # the text
    fmttxt = formattedtext!(
        topscene, l.text, position = textpos, textsize = l.textsize, 
        font = l.font, color = l.color, visible = l.visible, align = (l.hjustify,l.vjustify), 
        rotation = l.rotation, markerspace = :data, justification = l.hjustify,
        lineheight = l.lineheight, inspectable = false
    )

    # onany(l.text, l.textsize, l.font, #=l.rotation,=# l.padding) do _, _, _, #=_,=# padding
    #     textbb[] = Rect2f(boundingbox(fmttxt))
    #     autoheight = height(textbb[]) + padding[3] + padding[4]
    #     layoutobservables.autosize[] = (nothing, autoheight)
    #     return
    # end

    onany(layoutobservables.computedbbox, l.padding, l.halign, l.valign, 
          l.hjustify, l.vjustify) do bbox, padding, halign, valign, hjustify, vjustify

        textbb = Rect2f(boundingbox(fmttxt))
        tw, th = width(textbb), height(textbb)
        w = width(bbox)
        h = height(bbox)
        box, boy = bbox.origin

        # position text
        tx = box
        tx += if hjustify === :left
            padding[1]
        elseif hjustify === :center
            w/2
        elseif hjustify === :right
            w - padding[2]
        end
        ty = boy
        ty += if vjustify === :top
            h - padding[3]
        elseif vjustify === :center
            h/2
        elseif vjustify === :bottom
            padding[4]
        end
        textpos[] = Point3f(tx, ty, 0)

        fmttxt.maxwidth[] = w - padding[1] - padding[2]
        
        autoheight = th + padding[3] + padding[4]
        if !isapprox(h, autoheight)
            layoutobservables.reportedsize[] = (nothing, autoheight)
        end
    end

    # background box
    strokecolor_with_visibility = lift(l.strokecolor, l.strokevisible) do col, vis
        vis ? col : RGBAf(0, 0, 0, 0)
    end

    ibbox = lift(layoutobservables.computedbbox) do bbox
        round_to_IRect2D(layoutobservables.suggestedbbox[])
    end

    # TODO: simplify this to lines and move backgroundcolor to blockscene?
    bg = poly!(topscene, ibbox, color = l.backgroundcolor, visible = l.backgroundvisible,
               strokecolor = strokecolor_with_visibility, strokewidth = l.strokewidth,
               inspectable = false)
    translate!(bg, 0, 0, -10) # move behind text

    return l
end
