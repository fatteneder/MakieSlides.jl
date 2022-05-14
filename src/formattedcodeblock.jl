@Block FormattedCodeblock begin
    @forwarded_layout
    @attributes begin
        "The displayed text string."
        code::Markdown.MD = md"""
            ```julia
            function main()
                println("Hello, world!")
            end
            ```
            """
        "Controls if the text is visible."
        visible::Bool = true
        "The color of the text."
        color::RGBAf = inherit(scene, :textcolor, :black)
        "The font size of the text."
        textsize::Float32 = inherit(scene, :fontsize, 16f0)
        "The font family of the text."
        font::Makie.FreeTypeAbstraction.FTFont = inherit(scene, :font, "DejaVu Sans")
        "The vertical justification of the text (:top, :bottom, :center)."
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
        backgroundvisible::Bool = true
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


FormattedCodeblock(x, code; kwargs...) = FormattedCodeblock(x, code = code; kwargs...)


function initialize_block!(l::FormattedCodeblock)
    blockscene = l.blockscene
    layoutobservables = l.layoutobservables

    textpos = Observable(Point3f(0, 0, 0))
    textbb = Ref(BBox(0, 1, 0, 1))

    code = l.code[].content[1]

    # the text
    fmtcode = formattedcode!(
        blockscene, code, position = textpos, textsize = l.textsize, 
        font = l.font, color = l.color, visible = l.visible, align = (l.hjustify,l.vjustify), 
        rotation = l.rotation, markerspace = :data, justification = l.hjustify,
        lineheight = l.lineheight, inspectable = false
    )

    onany(layoutobservables.computedbbox, l.padding, l.halign, l.valign, 
          l.hjustify, l.vjustify) do bbox, padding, halign, valign, hjustify, vjustify

        textbb = Rect2f(boundingbox(fmtcode))
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
    end

    # # background box
    strokecolor_with_visibility = lift(l.strokecolor, l.strokevisible) do col, vis
        vis ? col : RGBAf(0, 0, 0, 0)
    end

    ibbox = lift(layoutobservables.computedbbox) do bbox
        round_to_IRect2D(layoutobservables.suggestedbbox[])
    end

    # TODO: simplify this to lines and move backgroundcolor to blockscene?
    bg = poly!(blockscene, ibbox, color = l.backgroundcolor, visible = l.backgroundvisible,
               strokecolor = strokecolor_with_visibility, strokewidth = l.strokewidth,
               inspectable = false)
    translate!(bg, 0, 0, -10) # move behind text

    return l
end
