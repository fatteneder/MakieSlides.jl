@Block FormattedList begin
    @forwarded_layout
    @attributes begin
        "The displayed markdown list."
        list::Markdown.List = first(md"""
            - item 1
            - item 2
            - item 3
        """.content)
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
        backgroundvisible::Bool = true
        "The color of the background. "
        backgroundcolor::RGBAf = RGBf(0.9, 0.9, 0.9)
        "The line width of the rectangle's border."
        strokewidth::Float32 = 1f0
        "Controls if the border of the rectangle is visible."
        strokevisible::Bool = true
        "The color of the border."
        strokecolor::RGBAf = RGBf(0, 0, 0)
        "The @printf pattern to format enumeration items"
        enumeration_pattern = "%i)"
        "The symbol for itemization items"
        itemization_symbol = "•"
    end
end


function FormattedList(x, md::Markdown.MD; kwargs...)
    list = first(md.content)
    if !(list isa Markdown.List)
        error("Failed to extract markdown list.")
    end
    FormattedList(x, list; kwargs...)
end
FormattedList(x, list; kwargs...) = FormattedList(x, list = list; kwargs...)


function initialize_block!(l::FormattedList)

    items_ordered = Observable(-1)
    on(l.list) do list
        items_ordered = list.ordered
    end

    symbol_fn = lift(items_ordered, l.itemization_symbol, l.enumeration_pattern) do ordered,
            item_symbol, enum_pattern

        # item_symbol = l.itemization_symbol[]
        # bullet_match = match(r"^\s*(\*|\+|-)", item_symbol)
        # item_symbol = if !isnothing(bullet_match)
        #     # escape bullet for Markdown.parse
        #     offset = bullet_match.offset
        #     string(item_symbol[1:offset-1], '\\', item_symbol[offset:end])
        # end

        if ordered < 0
            return i -> item_symbol
        else
            format_enum_pttrn = Printf.Format(enum_pattern)
            return i -> Printf.format(format_enum_pttrn, i+ordered-1)
        end
    end

    # we don't listen to l.list here, because there is not yet a way to clear parts of a figure
    # so that we can relayout the list if new elements were inserted
    # listening to symbol_fn is then also pointless
    for (idx, item) in enumerate(l.list[].items)
        # fmtlbl = FormattedLabel(fig_or_scene, text=symbol(idx), halign=:left, valign=:top)
        # using Label for now, because FormattedLabel promotes strings to Markdown.MD and
        # symbols like "1." would be parsed as Markdown.Lists, but the underlyinig 
        # formattedtext only works with Markdown.Paragraphs
        lbl = Label(l.blockscene, text=symbol_fn[](idx), halign=:left, valign=:top,
                    tellwidth=true, word_wrap=false)
        l.layout[idx, 1] = lbl
        l.layout[idx, 2] = FormattedLabel(l.blockscene, text=first(item),
                                          halign=:left, valign=:top,
                                          tellwidth=false, tellheight=true,
                                          textsize=l.textsize, font=l.font,
                                          lineheight=l.lineheight, rotation=l.rotation)
    end

    on(l.textsize) do textsize
        rowgap!(l.layout, 0.5*textsize)
        colgap!(l.layout, 0.5*textsize)
    end

    return l
end
