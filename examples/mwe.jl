using GLMakie, Markdown, MakieSlides

pres = Presentation(figure_padding = (50, 50, 50, 50))
display(pres)

add_slide!(pres) do fig
    Label(fig[1, 1], "This is a title", textsize = 100, tellwidth = false)
    Label(fig[2, 1], "with a subtitle", textsize = 60, tellwidth = false)
    rowgap!(fig.layout, 1, Fixed(10))
end


add_slide!(pres) do fig
    MarkdownBox(fig[1, 1], md"""
# MarkdownBox

## What is a MarkdownBox?

MarkdownBox allows you to use standard Markdown syntax to fill your slides with
content. So far we support
- Lists & Enumerations
- Tables
- Codeblocks
- Headings
- Horizontal dividers
- Equations
- *italic text*
- **bold text**
- `inline code`
- Emoijs :smile: :tada: :heart:

""")

end


add_slide!(pres) do fig

    MarkdownBox(fig[1,1], md"""
# Code block

```
using MakieSlides
using Markdown

f = Figure()
MarkdownBox(fig[1,1], md\"""
## Shopping list
---
- milk
- cookies
- bananas
\""")
```
""")

    MarkdownBox(fig[1,2], md"""
## Shopping list
---
- milk
- cookies
- bananas
""")

end


add_slide!(pres) do fig

    MarkdownBox(fig[1,1], md"""
# Table

| Region  | Rep      | Item   | Units  | Unit Cost | Total     |
|:--------|:---------|:-------|-------:|----------:|----------:|
| East    | Jones    | Pencil |      95|  1.99     |    189.05 |
| Central | Kivell   | Binder |      50|  19.99    |    999.50 |
| Central | Jardine  | Pencil |      36|  4.99     |    179.64 |
| Central | Gill     | Pen    |      27|  19.99    |    539.73 |
""")

end


add_slide!(pres) do fig
    MarkdownBox(fig[1, 1], md"""
# Split slides
""")

    MarkdownBox(fig[2, 1], md"""
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
    """)

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
# Equations

## Einstein field equations
```math
    G_{\mu\nu} = \frac{8 \pi G}{c^4} T_{\mu\nu}
```

## Schroedinger equation
```math
    i \hbar \partial_t \psi = \hat{H} \psi
```

## Maxwell equations
```math
    \partial_\beta F^{\alpha\beta} = \mu_0 J^\alpha
    \qquad
    \partial_{\alpha} F_{\beta\gamma} + \partial_{\beta} F_{\gamma\alpha} + \partial_{\gamma} F_{\alpha\beta} = 0
```
""")
end


add_slide!(pres) do fig
    MarkdownBox(fig[1,1], md"""
# TODO

- [-] Inline code (colored background missing)
- [ ] Links
- [ ] Inline equations
- [ ] Slide headers, footers, page numbers
- [ ] Citations
- [ ] More stylized fonts, e.g. underline and strikethrough)
- [ ] `CommonMark.jl` as alternative Markdown parser
""")
end


# save pdf
MakieSlides.save(joinpath(@__DIR__, "presentation.pdf"), pres)

# Move to first slide
reset!(pres)
