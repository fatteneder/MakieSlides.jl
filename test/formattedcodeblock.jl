using MakieSlides
using Markdown
using GLMakie

f = Figure()

md = md"""
```julia
function main()
  println("Sers, universe!")
end
```
"""

codeblock = FormattedCodeblock(f[1,1], md,
tellwidth=false, hjustify=:left, vjustify=:top, backgroundvisible=true)

f
