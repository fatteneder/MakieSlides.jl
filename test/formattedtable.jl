using MakieSlides
using Markdown
using GLMakie

f = Figure()

md = md"""
| Column One | Column Two | Column Three |
|:---------- | ---------- |:------------:|
| Row 1 has a lot of content to display    | Column 2 |              |
| Row 2    | Row 2  | Column 3 |
"""

tbl = md.content[1]

FormattedTable(f[1,1], md_table=md)

# FormattedList(f[1,1],
# md_list=md"""
# - bullet 1 $lorem_ipsum
# - bullet 2 $lorem_ipsum
# - bullet 3 $lorem_ipsum
# - bullet 4 $lorem_ipsum
# """)
#
# FormattedList(f[2,1],
# md_list=md"""
# 1. enum $lorem_ipsum
# 2. enum $lorem_ipsum
# """)
#
# FormattedList(f[1,2],
# md_list=md"""
# 4. enum $lorem_ipsum
# 5. enum $lorem_ipsum
# 6. enum $lorem_ipsum
# """)
#
# FormattedList(f[2,2],
# md_list=md"""
# - bullet 5
# - bullet 6
# - bullet 7
# - bullet 8
# """)
#
f
