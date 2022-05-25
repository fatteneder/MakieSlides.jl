@Block MarkdownBox begin
    @forwarded_layout
    @attributes begin
        "The displayed text string."
        text = "Text"
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
        "The syntax highlighting theme."
        codestyle::Symbol = :material
        "The code language."
        language::Symbol = :julia
        "The @printf pattern to format enumeration items"
        enumeration_pattern = "%i)"
        "The symbol for itemization items"
        itemization_symbol = "•"
        "The horizontal divider's lineheight multiplier for the text."
        divider_color::RGBAf = :lightgray
    end
end


MarkdownBox(x, text::AbstractString; kwargs...) = MarkdownBox(x, text = Markdown.parse(text); kwargs...)
MarkdownBox(x, text::Markdown.MD; kwargs...) = MarkdownBox(x, text = text; kwargs...)


header_level(h::Markdown.Header{T}) where T = T


function render_element(md::Markdown.Header, l::MarkdownBox, idx)
    lvl = header_level(md)
    textsize = if lvl <= 6
        l.header_textsize[][lvl]
    else
        l.textsize
    end
    text = Markdown.Paragraph(md.text)
    FormattedLabel(l.layout[idx,1], text = text,
                   visible = l.visible, color = l.color,
                   textsize = textsize, font = l.font,
                   hjustify = l.header_justification, vjustify = :top,
                   lineheight = l.lineheight,
                   rotation = l.rotation, padding = l.padding,
                   halign = :center, valign = :top,
                   tellwidth = true, tellheight = false,
                   width = l.width, height = l.height,
                   alignmode = l.alignmode,
                   backgroundvisible = l.backgroundvisible,
                   backgroundcolor = l.backgroundcolor)
end


function render_element(md::Markdown.Paragraph, l::MarkdownBox, idx)
    FormattedLabel(l.layout[idx,1], md,
                   visible = l.visible, color = l.color,
                   textsize = l.textsize, font = l.font,
                   hjustify = l.justification, vjustify = :top,
                   lineheight = l.lineheight,
                   rotation = l.rotation, padding = l.padding,
                   halign = :left, valign = :top,
                   tellwidth = true, tellheight = false,
                   width = l.width, height = l.height,
                   alignmode = l.alignmode,
                   backgroundvisible = l.backgroundvisible,
                   backgroundcolor = l.backgroundcolor)
end


function render_element(md::Markdown.Table, l::MarkdownBox, idx)
    FormattedTable(l.layout[idx,1], md,
                   visible = l.visible, color = l.color,
                   textsize = l.textsize, font = l.font,
                   lineheight = l.lineheight,
                   rotation = l.rotation, padding = l.padding,
                   halign = :left, valign = :top,
                   tellwidth = true, tellheight = false,
                   width = l.width, height = l.height,
                   alignmode = l.alignmode,
                   backgroundvisible = l.backgroundvisible,
                   backgroundcolor = l.backgroundcolor)
end


function render_element(md::Markdown.Code, l::MarkdownBox, idx)
    FormattedCodeblock(l.layout[idx,1], md,
                   visible = l.visible, color = l.color,
                   textsize = l.textsize, font = l.font,
                   lineheight = l.lineheight,
                   rotation = l.rotation,
                   halign = :left, valign = :top,
                   tellwidth = true, tellheight = false,
                   width = l.width, height = l.height,
                   alignmode = l.alignmode,
                   backgroundvisible = true,
                   codestyle = l.codestyle,
                   language = l.language)
end


function render_element(md::Markdown.List, l::MarkdownBox, idx)
    FormattedList(l.layout[idx,1], md,
                   visible = l.visible, color = l.color,
                   textsize = l.textsize, font = l.font,
                   lineheight = l.lineheight,
                   rotation = l.rotation,
                   halign = :left, valign = :top,
                   tellwidth = true, tellheight = false,
                   width = l.width, height = l.height,
                   alignmode = l.alignmode,
                   backgroundvisible = true,
                   backgroundcolor = l.backgroundcolor,
                   enumeration_pattern = l.enumeration_pattern,
                   itemization_symbol = l.itemization_symbol)
end



function render_element(md::Markdown.HorizontalRule, l::MarkdownBox, idx)
    ax = Axis(l.layout[idx,1], height=l.textsize)
    hidespines!(ax)
    hidedecorations!(ax)
    lines!(ax, [-1,1], [0,0], color=l.divider_color)
end


function initialize_block!(l::MarkdownBox)
    blockscene = l.blockscene
    layoutobservables = l.layoutobservables

    for (idx, md_element) in enumerate(l.text[].content)
        render_element(md_element, l, idx)
    end
    l.layout[end, 1] = Box(blockscene, tellheight=false, visible=l.backgroundvisible,
                             color=l.backgroundcolor)

    layoutobservables.suggestedbbox[] = layoutobservables.suggestedbbox[]

    on(l.textsize) do ts
        rowgap!(l.layout, ts)
    end
    notify(l.textsize)

    return l
end
