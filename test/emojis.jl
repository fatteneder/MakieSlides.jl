using MakieSlides
using GLMakie
GLMakie.activate!()


f = Figure()

fmttxt = formattedtext(f[1,1], ":smile:", textsize=80)

fmttxt = formattedtext(f[2,1], ":flag-at:", textsize=80,
                       font=MakieSlides.NativeFont(joinpath(@__DIR__, "..", "assets", "OpenMoji-Color.ttf")))
                       # font=MakieSlides.NativeFont(joinpath(@__DIR__, "..", "assets", "NotoColorEmoji.ttf")))

f
