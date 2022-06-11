@Block FormattedLabel begin
    @attributes begin
        "The displayed text string."
        text = "Text"
        "Controls if the text is visible."
        visible::Bool = true
        "The color of the text."
        color::RGBAf = inherit(scene, :textcolor, :black)
        "The font size of the text."
        textsize::Float32 = inherit(scene, :fontsize, 16f0)
        "The font family of the text."
        font::Makie.FreeTypeAbstraction.FTFont = inherit(scene, :font, "DejaVu Sans")
        "The justification of the text (:left, :right, :center)."
        justification = :left
        "The lineheight multiplier for the text."
        lineheight::Float32 = 1.0
        "The vertical alignment of the text in its suggested boundingbox"
        valign = :top
        "The horizontal alignment of the text in its suggested boundingbox"
        halign = :left
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
        tellheight::Bool = true
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
        "Enable word wrapping to the suggested width of the Label."
        word_wrap::Bool = true
    end
end


FormattedLabel(x, text; kwargs...) = FormattedLabel(x, text = text; kwargs...)


function initialize_block!(l::FormattedLabel)
    blockscene = l.blockscene
    layoutobservables = l.layoutobservables

    textpos = Observable(Point3f(0, 0, 0))
    textbb = Ref(BBox(0, 1, 0, 1))
    word_wrap_width = Observable(-1f0)

    fmttxt = formattedtext!(
        blockscene, l.text, position = textpos, textsize = l.textsize, font = l.font, color = l.color,
        visible = l.visible, align = (l.halign,l.valign), rotation = l.rotation, markerspace = :data,
        justification = l.justification, lineheight = l.lineheight, inspectable = false,
        word_wrap_width=word_wrap_width)


    onany(l.text, l.textsize, l.font, l.rotation, word_wrap_width, l.padding) do _, _, _, _, _, padding
        textbb[] = Rect2f(boundingbox(fmttxt))
        autowidth = width(textbb[]) + padding[1] + padding[2]
        autoheight = height(textbb[]) + padding[3] + padding[4]
        if l.word_wrap[]
            layoutobservables.autosize[] = (nothing, autoheight)
        else
            layoutobservables.autosize[] = (autowidth, autoheight)
        end
        return
    end

    onany(layoutobservables.computedbbox, l.padding, l.halign, l.valign) do bbox, padding,
            halign, valign

        if l.word_wrap[]
            tw = width(bbox) - padding[1] - padding[2]
        else
            tw = width(textbb[])
        end
        th = height(textbb[])

        w, h = width(bbox), height(bbox)
        box = bbox.origin[1]
        boy = bbox.origin[2]

        tx = box
        tx += if halign === :left
            padding[1]
        elseif halign === :center
            tw/2
        else #halign === :right
            tw + padding[2]
        end
        ty = boy
        ty += if valign === :top
            th + padding[3]
        elseif valign === :center
            th/2
        else #valign === :bottom
            padding[4]
        end

        textpos[] = Point3f(tx, ty, 0)

        if l.word_wrap[] && (word_wrap_width[] != tw)
            word_wrap_width[] = tw
        end

        return
    end

    notify(l.text)
    layoutobservables.suggestedbbox[] = layoutobservables.suggestedbbox[]

    # background box
    strokecolor_with_visibility = lift(l.strokecolor, l.strokevisible) do col, vis
        vis ? col : RGBAf(0, 0, 0, 0)
    end

    ibbox = lift(layoutobservables.computedbbox) do bbox
        round_to_IRect2D(layoutobservables.computedbbox[])
    end

    # TODO: simplify this to lines and move backgroundcolor to blockscene?
    bg = poly!(blockscene, ibbox, color = l.backgroundcolor, visible = l.backgroundvisible,
               strokecolor = strokecolor_with_visibility, strokewidth = l.strokewidth,
               inspectable = false, tellwidth=l.tellwidth, tellheight=l.tellheight)
    translate!(bg, 0, 0, -10) # move behind text

    return l
end
