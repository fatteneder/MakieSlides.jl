using MakieSlides
using GLMakie
GLMakie.activate!()


f = Figure()

haligns = (:left,:center,:right)
valigns = (:top,:center,:bottom)

txt = ":smile: :smile: :sweat-smile: This is some text that contains an emoji: :smile: :undefined: Some more text trailing the emojis."

for i = 1:3, j = 1:3
  FormattedLabel(f[i,j], txt, halign=haligns[3-j+1], valign=valigns[3-i+1], textsize=40,
                 justification=haligns[3-j+1], padding=(10,10,10,10))
end

f
