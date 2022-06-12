using MakieSlides
using GLMakie
GLMakie.activate!()

all_emojis = collect(keys(MakieSlides.EMOJIS_MAP))
txt = ":" * join(all_emojis, ": :") * ":"

f = Figure()
FormattedLabel(f[1,1], txt, textsize=40)

f
