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
        tellwidth::Bool = false
        "Controls if the parent layout can adjust to this element's height"
        tellheight::Bool = true
        "The align mode of the text in its parent GridLayout."
        alignmode = Inside()
        "Controls if the background is visible."
        backgroundvisible::Bool = false
        "The color of the background. "
        backgroundcolor::RGBAf = RGBf(0.9, 0.9, 0.9)
    end
end


MarkdownBox(x, text::AbstractString; kwargs...) = MarkdownBox(x, text = Markdown.parse(text); kwargs...)
MarkdownBox(x, text::Markdown.MD; kwargs...) = MarkdownBox(x, text = text; kwargs...)


function initialize_block!(l::MarkdownBox)
    blockscene = l.blockscene
    layoutobservables = l.layoutobservables

    for (idx, md_element) in enumerate(l.text[].content)
        FormattedLabel(l.layout[idx, 1], text = md_element,
                       halign = :left, valign = :top,
                       tellwidth = true, tellheight = true,
                       backgroundvisible = l.backgroundvisible,
                       backgroundcolor = l.backgroundcolor)
    end
    l.layout[end, 1] = Box(blockscene, tellheight=false, visible=l.backgroundvisible,
                             color=l.backgroundcolor)

    layoutobservables.suggestedbbox[] = layoutobservables.suggestedbbox[]

    rowgap!(l.layout, 0)

    return l
end
