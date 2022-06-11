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
tellwidth=false, backgroundvisible=true)

lbl = FormattedLabel(f[1,2],
"""
Label
*Label*
**Label**
`Label`
""",
tellwidth=false, backgroundvisible=true)

lbl = FormattedLabel(f[2,1],
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
tellwidth=false, backgroundvisible=true)

lbl = FormattedLabel(f[2,2],
"""
Label
*Label*
**Label**
`Label`
""",
tellwidth=false, backgroundvisible=true)

f
