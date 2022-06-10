using MakieSlides
using GLMakie

f = Figure()

lbl = FormattedLabel(f[1,1],
"""
lots of text blabla
lots of text blabla
lots of text blabla
lots of text blabla
lots of text blabla

lots of text blabla
lots of text blabla
lots of text blabla
lots of text blabla
lots of text blabla

sers
""",
tellwidth=false, backgroundvisible=true, padding=(0.0,0.0,0.0,0.0))

lbl = Label(f[1,2],
"""
Label
*Label*
**Label**
`Label`
""", tellwidth=false, halign=:left, valign=:top)

box = Box(f[2,:], tellheight=false, visible=false)

f
