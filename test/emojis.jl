using MakieSlides
using GLMakie
GLMakie.activate!()


f = Figure()

fmttxt = FormattedLabel(f[1,1], "This is some text that contains an emoji: :smile: :undefined:",
                        textsize=40, halign=:center)

f
