using MakieSlides
using Markdown
using GLMakie

f = Figure()

lorem_ipsum = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat."

FormattedList(f[1,1], 
md"""
- bullet 1 $lorem_ipsum
- bullet 2 $lorem_ipsum
- bullet 3 $lorem_ipsum
- bullet 4 $lorem_ipsum
""")

FormattedList(f[2,1], 
md"""
1. enum $lorem_ipsum
2. enum $lorem_ipsum
""")

FormattedList(f[1,2],
md"""
4. enum $lorem_ipsum
5. enum $lorem_ipsum
6. enum $lorem_ipsum
""")

FormattedList(f[2,2],
md"""
- bullet 5
- bullet 6
- bullet 7
- bullet 8
""")

f
