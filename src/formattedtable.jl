# Note: All implementation details of @Layoutables are spread across three files within Makie.
# We have combined those details into one file here.


# from src/makielayout/types.jl
@Block FormattedTable begin
    @forwarded_layout
    # sliders::Vector{Slider}
    # valuelabels::Vector{Label}
    # labels::Vector{Label}
    @attributes begin
        "The displayed markdown list."
        md_table = md"""
            | Column One | Column Two | Column Three |
            |:---------- | ---------- |:------------:|
            | Row 1      | Column 2   |              |
            | Row 2      | Row 2      | Column 3     |
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
        "Controls if table's column width should be adjusted to their contents width"
        column_distribution = :equal
        "The vertical alignment of the cell's content"
        valign_cells = :center
    end
end


# @doc """
# FormattedTable has the following attributes:

# $(let
#     _, docs, defaults = default_attributes(FormattedTable, nothing)
#     docvarstring(docs, defaults)
# end)
# """
# FormattedTable
FormattedTable(x, text; kwargs...) = FormattedTable(x, md_table = text; kwargs...)


const MARKDOWN_TO_MAKIE_HALIGNS = Dict(:l => :left, :c => :center, :r => :right)


function initialize_block!(l::FormattedTable)
    blockscene = l.blockscene
    layoutobservables = l.layoutobservables

    # blockscene = get_blockscene(fig_or_scene)
    # default_attrs = default_attributes(FormattedTable, blockscene).attributes
    # theme_attrs = subtheme(blockscene, :FormattedTable)
    # attrs = merge!(merge!(Attributes(kwargs), theme_attrs), default_attrs)

    # @extract attrs (md_table, textsize, font, color, visible,
    #                 rotation, padding, strokecolor, strokewidth, strokevisible,
    #                 backgroundcolor, backgroundvisible, tellwidth, tellheight)

    # layoutobservables = LayoutObservables(attrs.width, attrs.height, attrs.tellwidth, 
    #     attrs.tellheight, attrs.halign, attrs.valign, attrs.alignmode; suggestedbbox = bbox)

    strokecolor_with_visibility = lift(l.strokecolor, l.strokevisible) do col, vis
        vis ? col : RGBAf(0, 0, 0, 0)
    end

    table = l.md_table[].content[1]
    halign_cells = map(a -> MARKDOWN_TO_MAKIE_HALIGNS[a], table.align)
    rows = table.rows
    n_rows, n_cols = length(rows), length(halign_cells)
    for (i, row) in enumerate(rows)
        for (j, (cell, halign)) in enumerate(zip(row, halign_cells))
            text = string(cell...)
            l.layout[i, j] = FormattedLabel(blockscene, text=text,
                                              halign=l.halign, valign=l.valign_cells)
        end
    end
    #
    # # fix width of label_fillbox to maximum width of list symbols
    # on(label_fillbox.layoutobservables.computedbbox) do bbox
    #     current_w = label_fillbox.width[].x
    #     max_w = 0.0
    #     for lbl in symbol_labels
    #         textbb = Rect2f(boundingbox(lbl.elements[:text]))
    #         tw = width(textbb)
    #         if max_w < tw; max_w = tw; end
    #     end
    #     if max_w != current_w
    #         label_fillbox.width[] = Fixed(max_w)
    #     end
    # end
    #
    # label_fillbox.layoutobservables.suggestedbbox[] =
    #     label_fillbox.layoutobservables.suggestedbbox[]
    #
    rowgap!(l.layout, 5)
    colgap!(l.layout, 5)

    # FormattedTable(fig_or_scene, layoutobservables, attrs, Dict(:l.layout => l.layout))
    return l
end


# function column_distribution(mode)
#
# end


# function Base.setindex!(gp::GridPosition, fmtlist::FormattedTable)
#     gp.layout[gp.span.rows, gp.span.cols, gp.side] = fmtlist.elements[:l.layout]
# end


# function Base.setindex!(fig::Figure, fmtlist::FormattedTable, rows, cols, side = GridLayoutBase.Inner())
#     fig.layout[rows, cols, side] = fmtlist.elements[:l.layout]
#     fmtlist
# end
