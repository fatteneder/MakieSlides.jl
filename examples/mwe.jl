using MakieSlides


thisdir = basename(@__DIR__)
hide_decorations = true

slide1 = Slide(hide_decorations=hide_decorations)
slideheader!(slide1, "My first slide")
slidetext!(slide1, """
Hello world! 

Here follows a very long text which I don't know about whether it will line break or not... probably not

... above line should have wrapped around :(


But here is some formatted text


*italic* works

**bold** works

`code` works (ignoring language for now; colored background would be cool;\n
Dejavu Sans Mono not available on my system ...)
""")
slidefooter!(slide1, "Florian")
@time MakieSlides.save(joinpath(thisdir, "slide1.pdf"), slide1)


slide2 = Slide(hide_decorations=hide_decorations)
slideheader!(slide2, "TODO Formatted text")
slidetext!(slide2, """
[x] Bold and italic text

[ ] Automatic line wrapping (really needed, cf. Marpit)

[ ] Line breaks (require an empty line between paragraphs or use single line breaks?)

[ ] Itemizations and enumerations

[ ] Horizontal divider

[ ] Table formatting

[ ] Code formatting

[ ] Equation formatting

[ ] Links

[ ] Footers/citations
""")
# slidetext!(slide2, """
# - formatted text
# - (inlined) math
# - formatted tables
# - code blocks
# """)
slidefooter!(slide2, "Florian")

@time MakieSlides.save(joinpath(thisdir, "slide2.pdf"), slide2)


presentation = Presentation()
append!(presentation.slides, [ slide1, slide2 ])
@time MakieSlides.save(joinpath(thisdir, "presentation.pdf"), presentation)

presentation
