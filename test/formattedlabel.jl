using MakieSlides
using GLMakie

f = Figure()

lorem_ipsum = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat."

haligns = (:left,:center,:right)
valigns = (:top,:center,:bottom)

for i = 1:3, j = 1:3
  FormattedLabel(f[i,j], lorem_ipsum, tellwidth=false, backgroundvisible=true,
                 halign=haligns[3-j+1], valign=valigns[3-i+1],
                 justification=haligns[3-j+1])
end

f
