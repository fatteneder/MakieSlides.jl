using MakieSlides
using Markdown
using GLMakie

f = Figure()

fmtlbl = FormattedList(f[1,1], 
md_list=md"""
- item 1
- item 2
- item 3
""")

f
