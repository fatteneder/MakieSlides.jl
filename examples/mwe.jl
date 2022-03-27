using MakieSlides


thisdir = basename(@__DIR__)
hide_decorations = true

slide1 = Slide(hide_decorations=hide_decorations)
slideheader!(slide1, "My first slide")
slidetext!(slide1, """
hello world! Here follows a very long text which I don't know about
whether it will line break or not... probably not

- blabla
- mimimi
- uga-aga-uga-aga
""")
slidefooter!(slide1, "Florian Atteneder")
@time MakieSlides.save(joinpath(thisdir, "slide1.pdf"), slide1)


slide2 = Slide(hide_decorations=hide_decorations)
slideheader!(slide2, "My first slide")
slidetext!(slide2, """
# Is this really page 2?
""")
slidefooter!(slide2, "Florian Atteneder")

@time MakieSlides.save(joinpath(thisdir, "slide2.pdf"), slide2)


presentation = Presentation()
append!(presentation.slides, [ slide1, slide2 ])
@time MakieSlides.save(joinpath(thisdir, "presentation.pdf"), presentation)

presentation
