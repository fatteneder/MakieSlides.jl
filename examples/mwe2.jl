using GLMakie, MakieSlides, Colors
GLMakie.activate!()

# define some colors and configure our Makie theme
fontblue=colorant"#2325C0"
blue=colorant"#0000a3"
yellow=colorant"#ffe200"
set_theme!(Theme(Box=Theme(strokevisible=false)))


# create a presentation
p = Presentation(figure_padding=0)

### setup a slide master for our presentation
### whenever we add a slide and draw on it then elements from the slidemaster are added,
### unless we override them locally

new_slidemaster!(p)
add_to_slide!(p, element=:footer) do fig
  # footer with page number
  i = MakieSlides.current_index(p)
  n = length(p)
  Box(fig[1,1], color=blue, strokevisible=false)
  Box(fig[1,2], color=yellow, strokevisible=false)
  Label(fig[1,3], "$i/$n", textsize=30, tellheight=false)
  colgap!(fig.layout, 0)
end

### populate slides

new_slide!(p)
add_to_slide!(p) do fig
  FormattedLabel(fig[1,1], "MWE with MakieSlides",
                 textsize=80, halign=:center)
end


new_slide!(p)
add_to_slide!(p, element=:header) do fig
  Box(fig[1,1], color=blue)
  Box(fig[1,2], color=yellow)
  colgap!(fig.layout, 0)
end
add_to_slide!(p) do fig
  FormattedLabel(fig[1,1], "A very long heading that should suffer from a line break at some point", textsize=40,
                 valign=:top, backgroundcolor=yellow, backgroundvisible=true,
                 strokevisible=false, color=fontblue)
  Box(fig[2,1], tellheight=true, visible=false)
end

p
