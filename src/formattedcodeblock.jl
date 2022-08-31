@Block FormattedCodeblock begin
    @forwarded_layout
    @attributes begin
        "The displayed text string."
        code::Markdown.Code = first(md"""
            ```julia
            function main()
                println("Hello, world!")
            end
            ```
            """.content)
        "Controls if the text is visible."
        visible::Bool = true
        "The color of the text."
        color::RGBAf = inherit(scene, :textcolor, :black)
        "The font size of the text."
        textsize::Float32 = inherit(scene, :fontsize, 20f0)
        "The font family of the text."
        font::Makie.FreeTypeAbstraction.FTFont = inherit(scene, :font, "DejaVu Sans")
        "The lineheight multiplier for the text."
        lineheight::Float32 = 1.0
        "The vertical alignment of the text in its suggested boundingbox"
        valign = :center
        "The horizontal alignment of the text in its suggested boundingbox"
        halign = :center
        "The counterclockwise rotation of the text in radians."
        rotation::Float32 = 0f0
        "The extra space added to the sides of the text boundingbox."
        padding = (10f0, 10f0, 10f0, 10f0)
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
        "The line width of the rectangle's border."
        strokewidth::Float32 = 1f0
        "Controls if the border of the rectangle is visible."
        strokevisible::Bool = true
        "The color of the border."
        strokecolor::RGBAf = RGBf(0, 0, 0)
        "The syntax highlighting theme."
        codestyle::Symbol = :material
        "The code language."
        language::Symbol = :julia
    end
end


function FormattedCodeblock(x, md::Markdown.MD; kwargs...)
    code = first(md.content)
    if !(code isa Markdown.Code)
        error("Failed to extract code snippet.")
    end
    FormattedCodeblock(x, code; kwargs...)
end
FormattedCodeblock(x, code; kwargs...) = FormattedCodeblock(x, code = code; kwargs...)


function initialize_block!(l::FormattedCodeblock)
    blockscene = l.blockscene
    layoutobservables = l.layoutobservables

    textpos = Observable(Point3f(0, 0, 0))
    textbb = Ref(BBox(0, 1, 0, 1))
    maxwidth = Observable(0.0)

    all_styles = Symbol.(collect(pygments_styles.get_all_styles()))
    pygstyler = lift(l.codestyle) do style
        if !(style in all_styles)
            @warn "Could not find style '$style', using style friendly."
            style = :friendly
            l.codestyle[] = style
        end
        pygstyler = pygments_styles.get_style_by_name(string(style))
    end

    all_lexers = lowercase.(first.(collect(pygments_lexers.get_all_lexers())))
    pyglexer = lift(l.language) do lang
        if !(string(lang) in all_lexers)
            @warn "Language '$lang' not supported, using language julia."
            lang = :julia
            l.language[] = lang
        end
        pyglexer = pygments_lexers.get_lexer_by_name(string(lang))
    end

    backgroundcolor = lift(pygstyler) do styler
        parse(RGBAf, styler.background_color)
    end

    fmtcode = formattedcode!(
        blockscene, l.code, position = textpos, textsize = l.textsize,
        font = l.font, visible = l.visible, align = (:left, :top), 
        rotation = l.rotation, markerspace = :data, justification = :left,
        lineheight = l.lineheight, inspectable = false,
        pygstyler = pygstyler, pyglexer = pyglexer, maxwidth=maxwidth
    )

    # fit bounding box to text
    onany(l.code, maxwidth, l.padding) do _, _, padding
        textbb[] = Rect2f(boundingbox(fmtcode))
        autoheight = height(textbb[]) + padding[3] + padding[4]
        layoutobservables.autosize[] = (nothing, autoheight)
    end

    # adjust textbox width to new layout
    onany(layoutobservables.computedbbox, l.padding, l.halign, l.valign) do bbox, 
            padding, halign, valign

        w, h = width(bbox), height(bbox)
        box, boy = bbox.origin

        tx = box + padding[1]
        ty = boy + h - padding[3]
        textpos[] = Point3f(tx, ty, 0)

        tw = w - padding[1] - padding[2]
        if tw != maxwidth[]
            maxwidth[] = tw
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
    bg = poly!(blockscene, ibbox, color = backgroundcolor, visible = l.backgroundvisible,
               strokecolor = strokecolor_with_visibility, strokewidth = l.strokewidth,
               inspectable = false)
    translate!(bg, 0, 0, -10) # move behind text

    return l
end
