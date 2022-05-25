using GLMakie, Markdown, MakieSlides

pres = Presentation(figure_padding = (50, 50, 50, 50))
display(pres)

add_slide!(pres) do fig
    Label(fig[1, 1], "This is a title", textsize = 100, tellwidth = false)
    Label(fig[2, 1], "with a subtitle", textsize = 60, tellwidth = false)
    rowgap!(fig.layout, 1, Fixed(10))
end

add_slide!(pres) do fig
    Label(fig[1, 1:2], "Example Slide without text wrapping", textsize = 40, tellwidth = false)
    scene = LScene(fig[2, 1], tellwidth = false)
    campixel!(scene)

    formattedtext!(scene, """
    Hello world! 
    
    Here follows a very long text which I don't know about whether it will line break or not... probably not
    
    ... above line should have wrapped around :(
    
    But here is some formatted text
    
    *italic* works
    
    **bold** works
    
    `code` works (ignoring language for now; colored background would be cool)
    """)

    ax = Axis(fig[2, 2], title = "A fancy plot")
    scatter!(ax, range(0, 4pi, length=101), sin)
end

add_slide!(pres) do fig
    Label(fig[1, 1:2], "Using FormattedLabel", textsize = 40, tellwidth = false)

    # # TODO: This errors because of string indexing
    FormattedList(fig[2, 1], md"""
- *italic* text
- **bold** text
- `code`
    """, tellheight = false, tellwidth = false
    )
    str = """
    Look at this long line of text. Because it is long it would usually flow out of the Label but we have word wrapping so it doesn't!
    
    *italic* works
    
    **bold** works
    
    `code` works (ignoring language for now; colored background would be cool)
    """
    # FormattedLabel(fig[2, 1], str, halign = :right, valign = :bottom, tellheight = false, tellwidth = false)
    FormattedLabel(fig[2, 2], str, halign = :left,  valign = :top, tellheight = false, tellwidth = false)
    FormattedLabel(fig[3, 1], str, hjustify = :center, tellheight = false, tellwidth = false)
    FormattedLabel(fig[3, 2], str, hjustify = :right, tellheight = false, tellwidth = false)
end

add_slide!(pres) do fig
    Label(fig[1, 1], "Example List", textsize = 40, tellwidth = false)
    Box(fig[2, 1], visible = false) # Spacer
    FormattedList(fig[3, 1], md"""
    - First Entry

    - Second Entry

    - Third Entry
    """)
end

add_slide!(pres) do fig
    Label(fig[1, 1], "Example Table", textsize = 40, tellwidth = false)
    FormattedTable(fig[2, 1], md"""
| Column One | Column Two | Column Three |
|:---------- | ---------- |:------------:|
| Row 1      | Column 2   |              |
| Row 2      | Row 2      | Column 3     |
    """, tellwidth = false)
end

add_slide!(pres) do fig
    Label(fig[1, 1], "Example code block", textsize = 40, tellwidth=false)
    FormattedCodeblock(fig[2, 1], md"""
    ```julia
    # by Lazaro Alonso - BeautifulMakie
    let
        x = 0:0.05:1
        y = x .^ 2
        ax = Axis(fig[1, 2], xlabel = "x", ylabel = "y")
        lines!(ax, x, y, color = :orangered, label = "Label")
        band!(ax, x, fill(0, length(x)), y; color = (:orange, 0.25), label = "Label")
        axislegend(ax ; merge = true, position = :lt)
    end;
    ```
    """, tellwidth=false)
    let
        x = 0:0.05:1
        y = x .^ 2
        ax = Axis(fig[3,1], xlabel = "x", ylabel = "y", tellheight=true)
        lines!(ax, x, y, color = :orangered, label = "Label")
        band!(ax, x, fill(0, length(x)), y; color = (:orange, 0.25), label = "Label")
        axislegend(ax ; merge = true, position = :lt)
    end
end

add_slide!(pres) do fig
    MarkdownBox(fig[1, 1], md"""
# MarkdownBox

## What is a MarkdownBox?

MarkdownBox allows you to use standard Markdown syntax to fill your slides with
content. So far we support
- Lists
- Enumerations
- Tables
- Codeblocks
- Headings

---

## Example

```
using GLMakie
GLMakie.activate!()

f = Figure()
MarkdownBox(fig[1,1], md\"""
Here goes your markdown text, e.g. a shopping list with
- milk
- cookies
- bananas
\"""
```

""")
end

add_slide!(pres) do fig
    Label(fig[1, 1], "TODO", textsize = 40, tellwidth=false)
    FormattedList(fig[2,1], md"""
- [x] Bold and italic text
- [x] Automatically insert blank lines in paragraphs
- [x] Automatic line wrapping
- [x] Itemizations and enumerations
- [x] Tables
- [x] Code blocks with syntax highlighting
- [x] Headings
- [x] Horizontal dividers
- [x] Equations
- [ ] Links
- [ ] Inline code
- [ ] Inline equations
- [ ] Headers/Footers/citations
- [ ] Emojis
- [ ] More stylized fonts, e.g. underline and strikethrough
- [ ] `CommonMark.jl` as alternative Markdown parser
""")
end

# Move to first slide
reset!(pres)

# # save pdf
# thisdir = basename(@__DIR__)
# MakieSlides.save(joinpath(thisdir, "presentation.pdf"), pres)

