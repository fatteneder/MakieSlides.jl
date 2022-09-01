@Block MarkdownBox begin
    @forwarded_layout
    @attributes begin
        "The displayed Markdown block."
        md::Markdown.MD = md"""

        # MarkdownBox

        Deliver content with ease :smile:
        """
        "Controls if the text is visible."
        visible::Bool = true
        "The color of the text."
        color::RGBAf = inherit(scene, :textcolor, :black)
        "The font size of the text."
        textsize::Float32 = inherit(scene, :fontsize, 20f0)
        "The font size of the headers."
        header_textsize::Vector{Float32} = [ 40f0, 36f0, 32f0, 28f0, 25f0, 22f0 ]
        "The font family of the text."
        font::Makie.FreeTypeAbstraction.FTFont = inherit(scene, :font, "DejaVu Sans")
        "The justification of the text (:left, :right, :center)."
        justification = :left
        "The justification of the headers (:left, :right, :center)."
        header_justification = :center
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
        tellwidth::Bool = false
        "Controls if the parent layout can adjust to this element's height"
        tellheight::Bool = true
        "The align mode of the text in its parent GridLayout."
        alignmode = Inside()
        "Controls if the background is visible."
        backgroundvisible::Bool = false
        "The color of the background. "
        backgroundcolor::RGBAf = RGBf(0.9, 0.9, 0.9)
        "The color of the background of a code snippet. Set to `nothing` to use background color from syntax highlighter."
        code_backgroundcolor::Union{RGBAf,Nothing} = nothing
        "The syntax highlighting theme."
        codestyle::Symbol = :material
        "The @printf pattern to format enumeration items"
        enumeration_pattern = "%i)"
        "The symbol for itemization items"
        itemization_symbol = "•"
        "The horizontal divider's lineheight multiplier for the text."
        divider_color::RGBAf = :lightgray
    end
end


MarkdownBox(x, md::AbstractString; kwargs...) = MarkdownBox(x, md = Markdown.parse(text); kwargs...)
MarkdownBox(x, md::Markdown.MD; kwargs...) = MarkdownBox(x, md = md; kwargs...)


header_level(h::Markdown.Header{T}) where T = T


function render_element(md::Markdown.Header, scene, l::MarkdownBox)
    lvl = header_level(md)
    textsize = if lvl <= 6
        l.header_textsize[][lvl]
    else
        l.textsize
    end
    text = Markdown.Paragraph(md.text)
    FormattedLabel(scene, text = text,
                   visible = l.visible, color = l.color,
                   textsize = textsize, font = l.font,
                   lineheight = l.lineheight,
                   rotation = l.rotation, padding = l.padding,
                   halign = :center, valign = :center,
                   tellwidth = false, tellheight = true,
                   width = l.width, height = l.height,
                   alignmode = l.alignmode,
                   backgroundvisible = l.backgroundvisible,
                   backgroundcolor = l.backgroundcolor)
end


function render_element(md::Markdown.Paragraph, scene, l::MarkdownBox)
    FormattedLabel(scene, md,
                   visible = l.visible, color = l.color,
                   textsize = l.textsize, font = l.font,
                   lineheight = l.lineheight,
                   rotation = l.rotation, padding = l.padding,
                   halign = :left, valign = :top,
                   tellwidth = false, tellheight = true,
                   width = l.width, height = l.height,
                   alignmode = l.alignmode,
                   backgroundvisible = l.backgroundvisible,
                   backgroundcolor = l.backgroundcolor)
end


function render_element(md::Markdown.Table, scene, l::MarkdownBox)
    FormattedTable(scene, md,
                   visible = l.visible, color = l.color,
                   textsize = l.textsize, font = l.font,
                   lineheight = l.lineheight,
                   rotation = l.rotation, padding = l.padding,
                   halign = :left, valign = :top,
                   tellwidth = false, tellheight = true,
                   width = l.width, height = l.height,
                   alignmode = l.alignmode,
                   backgroundvisible = l.backgroundvisible,
                   backgroundcolor = l.backgroundcolor)
end


function render_element(md::Markdown.Code, scene, l::MarkdownBox)
    FormattedCodeblock(scene, md,
                   visible = l.visible, color = l.color,
                   textsize = l.textsize, font = l.font,
                   lineheight = l.lineheight,
                   rotation = l.rotation,
                   halign = :left, valign = :top,
                   tellwidth = false, tellheight = true,
                   width = l.width, height = l.height,
                   alignmode = l.alignmode,
                   backgroundvisible = true,
                   backgroundcolor = l.code_backgroundcolor,
                   codestyle = l.codestyle,
                   language = Symbol(md.language))
end


function render_element(md::Markdown.List, scene, l::MarkdownBox)
    FormattedList(scene, md,
                   visible = l.visible, color = l.color,
                   textsize = l.textsize, font = l.font,
                   lineheight = l.lineheight,
                   rotation = l.rotation,
                   halign = :left, valign = :top,
                   tellwidth = false, tellheight = true,
                   width = l.width, height = l.height,
                   alignmode = l.alignmode,
                   backgroundvisible = true,
                   backgroundcolor = l.backgroundcolor,
                   enumeration_pattern = l.enumeration_pattern,
                   itemization_symbol = l.itemization_symbol)
end


function render_element(md::Markdown.HorizontalRule, scene, l::MarkdownBox)
    lsc = LScene(scene; height = l.textsize, show_axis = false, tellheight=true)
    update_cam!(lsc.scene, Makie.campixel!)
    lines!(lsc.scene, Point2f[(-1,0), (1,0)]; space = :clip, color=l.divider_color)
    lsc
end


function render_element(md::Markdown.LaTeX, scene, l::MarkdownBox)
    latex = latexstring(strip(md.formula))
    Label(scene, latex, color=l.color, textsize=l.textsize,
          padding=l.padding, rotation=l.rotation, tellwidth=false, tellheight=true)
end


function render_element(md, scene, l::MarkdownBox)
    error("MarkdownBox: Cannot render Markdown elements of type '$(typeof(md))'")
end


function initialize_block!(l::MarkdownBox)
    blockscene = l.blockscene
    layoutobservables = l.layoutobservables

    for (idx, md_element) in enumerate(l.md[].content)
        l.layout[idx,1] = render_element(md_element, blockscene, l)
    end
    l.layout[end, 1] = Box(blockscene, tellheight=false, visible=false,
                           height=Auto())

    on(l.textsize) do ts
        rowgap!(l.layout, ts)
    end

    return l
end
