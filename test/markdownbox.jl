using Markdown
using MakieSlides
using GLMakie
GLMakie.activate!()


f = Figure()

mdbox = MarkdownBox(f[1,1], md"""
# Testbox1

## Hello World!
This is a first attempt on formatted and layoutable text box with Makie.

Ideally, a line break should insert a new paragraph which in turn then will add two
layoutable FormattedLabel objects into a MarkdownBox.

## Of course we need a table

| Region  | Rep      | Item   | Units  | Unit Cost | Total     |
|:--------|:---------|:-------|-------:|----------:|----------:|
| East    | Jones    | Pencil |      95|  1.99     |    189.05 |
| Central | Kivell   | Binder |      50|  19.99    |    999.50 |
| Central | Jardine  | Pencil |      36|  4.99     |    179.64 |
""")

mdbox = MarkdownBox(f[1,2], md"""
# Testbox2

----

## What about some code?

---

```julia
# BeautifulAlgorithms.jl

# Bogo Sort
function bogo_sort!(X)
    while !issorted(X)
        shuffle!(X)
    end
end
```

---

## Shopping list

---

- Cookies
- Milk
- Bananas
""")

f
