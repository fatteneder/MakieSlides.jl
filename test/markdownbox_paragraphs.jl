using Markdown
using MakieSlides
using GLMakie
GLMakie.activate!()


f = Figure()

mdbox = MarkdownBox(f[1,1], md"""
Hello World!
This is a first attempt on formatted and layoutable text box with Makie.

Ideally, a line break should insert a new paragraph which in turn then will add two
layoutable FormattedLabel objects into a MarkdownBox.

Did it work?
""")

# mdbox = MarkdownBox(f[1,2], md"""
# Hello World!
# This is a first attempt on formatted and layoutable text box with Makie.
#
# Ideally, a line break should insert a new paragraph which in turn then will add two
# layoutable FormattedLabel objects into a MarkdownBox.
#
# Did it work?
# """)

f
