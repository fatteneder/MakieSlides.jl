using MakieSlides
using GLMakie


slide = Slide(hide_decorations=false)
slideheader!(slide, "My first slide")
# slidetext!(slide, L"a^2 + b^2 = c^2")
slidetext!(slide, """
hello world! Here follows a very long text which I don't know about
whether it will line break or not... probably not

$(L"
  a^2 + b^2 = c^2
  ")

- blabla
- mimimi
- uga-aga-uga-aga
""")
slidefooter!(slide, "Florian Atteneder")

MakieSlides.save("slide.pdf", slide)

display(slide)
# f, a, p = slide
# println("hello")
# text("Hello")
# # text!([("hello",Point2f(1.0,1.0))])
# display(slide)
