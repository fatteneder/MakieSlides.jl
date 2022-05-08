# Note: All implementation details of @Layoutables are spread across three files within Makie.
# We have combined those details into one file here.


# from src/makielayout/types.jl
@Block FormattedList begin
    @forwarded_layout
    @attributes begin
        "The displayed markdown list."
        md_list = md"""
            - item 1
            - item 2
            - item 3
        """
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


# @doc """
# FormattedList has the following attributes:

# $(let
#     _, docs, defaults = default_attributes(FormattedList, nothing)
#     docvarstring(docs, defaults)
# end)
# """
# FormattedList
FormattedList(x, text; kwargs...) = FormattedList(x, md_list = text; kwargs...)


function initialize_block!(l::FormattedList)
    blockscene = l.blockscene

    # default_attrs = default_attributes(FormattedList, blockscene).attributes
    # theme_attrs = subtheme(blockscene, :FormattedList)
    # attrs = merge!(merge!(Attributes(kwargs), theme_attrs), default_attrs)

    # @extract attrs (md_list, textsize, font, color, visible, halign, valign,
    #                 rotation, padding, strokecolor, strokewidth, strokevisible,
    #                 backgroundcolor, backgroundvisible, tellwidth, tellheight,
    #                 enumeration_pattern, itemization_symbol)

    # layoutobservables = LayoutObservables(attrs.width, attrs.height, attrs.tellwidth, 
    #     attrs.tellheight, halign, valign, attrs.alignmode; suggestedbbox = bbox)

    # strokecolor_with_visibility = lift(l.strokecolor, l.strokevisible) do col, vis
    #     vis ? col : RGBAf(0, 0, 0, 0)
    # end

    item_symbol = l.itemization_symbol[]
    # bullet_match = match(r"^\s*(\*|\+|-)", item_symbol)
    # item_symbol = if !isnothing(bullet_match)
    #     # escape bullet for Markdown.parse
    #     offset = bullet_match.offset
    #     string(item_symbol[1:offset-1], '\\', item_symbol[offset:end])
    # end

    list = l.md_list[].content[]
    items, ordered = list.items, list.ordered
    symbol = if ordered < 0
        i -> item_symbol
    else
        format_enum_pttrn = Printf.Format(l.enumeration_pattern[])
        i -> Printf.format(format_enum_pttrn, i+ordered-1)
    end

    symbol_labels = Label[]
    for (idx, item) in enumerate(items)
        # fmtlbl = FormattedLabel(fig_or_scene, text=symbol(idx), halign=:left, valign=:top)
        # using Label for now, because FormattedLabel promotes strings to Markdown.MD and
        # symbols like "1." would be parsed as Markdown.Lists, but the underlyinig 
        # formattedtext only works with Markdown.Paragraphs
        lbl = Label(blockscene, text=symbol(idx), halign=:left, valign=:top)
        push!(symbol_labels, lbl)
        l.layout[idx, 1] = lbl
        l.layout[idx, 2] = FormattedLabel(blockscene, text=first(item),
                                            halign=:left, valign=:top, tellwidth=false)
    end

    label_fillbox = Box(blockscene, width=Fixed(1000.0 #= will be adjusted below=#))
    text_fillbox  = Box(blockscene)
    l.layout[length(items)+1, 1] = label_fillbox
    l.layout[length(items)+1, 2] = text_fillbox

    # fix width of label_fillbox to maximum width of list symbols
    on(label_fillbox.layoutobservables.computedbbox) do bbox
        current_w = label_fillbox.width[].x
        max_w = 0.0
        for lbl in symbol_labels
            textbb = Rect2f(boundingbox(lbl.blockscene.plots[1]))
            tw = width(textbb)
            if max_w < tw; max_w = tw; end
        end
        if max_w != current_w
            label_fillbox.width[] = Fixed(max_w)
        end
    end

    label_fillbox.layoutobservables.suggestedbbox[] = 
        label_fillbox.layoutobservables.suggestedbbox[]

    rowgap!(l.layout, 5)
    colgap!(l.layout, 5)

    return l
end


# function Base.setindex!(gp::GridPosition, fmtlist::FormattedList)
#     @info "setindex 1"
#     gp.layout[gp.span.rows, gp.span.cols, gp.side] = fmtlist.elements[:l.layout]
# end


# function Base.setindex!(fig::Figure, fmtlist::FormattedList, rows, cols, side = GridLayoutBase.Inner())
#     @info "setindex 2"
#     fig.layout[rows, cols, side] = fmtlist.elements[:l.layout]
#     fmtlist
# end
