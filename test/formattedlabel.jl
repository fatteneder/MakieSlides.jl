using MakieSlides
using GLMakie

f = Figure()

lbl = Label(f[1,2],
"""
Label
*Label*
**Label**
`Label`
""", tellwidth=false, halign=:left, valign=:top)
box = Box(f[2,2], tellheight=false, visible=false)

lbl = FormattedLabel(f[1,1], 
"""
FormattedLabel

*FormattedLabel*

**FormattedLabel**

`FormattedLabel`
""", tellwidth=false, halign=:left, valign=:top, backgroundvisible=true)
box = Box(f[2,1], tellheight=false, visible=false)

f
