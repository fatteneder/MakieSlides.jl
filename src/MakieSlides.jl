module MakieSlides


using GLMakie
using CairoMakie
import Cairo


export Slide,
       slidetext!,
       slideheader!,
       slidefooter!,
       Presentation,
       save


struct Slide
  figure
  panes::Dict
end


function Slide(; hide_decorations::Bool=true, 
                 title="",
                 aspect=(16,9))

  @assert all(aspect .> 0)

  figure = Figure()

  panes = Dict(:header  => Axis(figure[1,1]),
               :content => Axis(figure[2,1]),
               :footer  => Axis(figure[3,1]))

  ratio_header = 1/10
  rowsize!(figure.layout, 1, Auto(ratio_header))
  ratio_footer = 1/10
  rowsize!(figure.layout, 3, Auto(ratio_footer))

  aspects = Dict(:header => (aspect[1], 1+aspect[2]*ratio_header),
                 :content => aspect,
                 :footer => (aspect[1], 1+aspect[2]*ratio_footer))

  for (k, pane) in pairs(panes)
    asp = aspects[k]
    limits!(pane, 1, asp[1], 1, asp[2])
    if hide_decorations
      hidedecorations!(pane, grid=true)
      hidespines!(pane)
    end
  end

  rowgap!(figure.layout, 5)
  colgap!(figure.layout, 5)

  return Slide(figure, panes)
end


function slidetext!(slide, text)
  pane = slide.panes[:content]
  rect = pane.targetlimits[]
  xwidth, ywidth = rect.widths
  xorigin, yorigin = rect.origin
  origin_text = Point2f(xorigin,yorigin+ywidth)
  t = text!(pane, text, position=origin_text, align=(:left,:top))
end


function slideheader!(slide, text)
  pane = slide.panes[:header]
  rect = pane.targetlimits[]
  xwidth, ywidth = rect.widths
  xorigin, yorigin = rect.origin
  origin_text = Point2f(xorigin,yorigin+ywidth/2)
  t = text!(pane, text, position=origin_text, align=(:left,:center))
end


function slidefooter!(slide, text)
  pane = slide.panes[:footer]
  rect = pane.targetlimits[]
  xwidth, ywidth = rect.widths
  xorigin, yorigin = rect.origin
  origin_text = Point2f(xorigin,yorigin+ywidth/2)
  t = text!(pane, text, position=origin_text, align=(:left,:center))
end


Base.display(s::Slide) = display(s.figure)


function save(name, s::Slide)
  CairoMakie.activate!()

  scene = s.figure.scene
  screen = CairoMakie.CairoScreen(scene, name, :pdf)
  CairoMakie.cairo_draw(screen, scene)
  Cairo.finish(screen.surface)

  GLMakie.activate!()
end


Base.@kwdef mutable struct Presentation
  slides::Vector{Slide} = Slide[]
  title::String = ""
  author::String = ""
  slidenumbers::Bool = false
end


# function Base.display(presentation::Presentation)
#   #display(s.figure)
# end


function save(name, presentation::Presentation)
  CairoMakie.activate!()

  slides = presentation.slides
  @assert length(slides) > 0

  figure = Figure()
  scene = figure.scene
  screen = CairoMakie.CairoScreen(scene, name, :pdf)

  for (idx, slide) in enumerate(slides)
    CairoMakie.cairo_draw(screen, slide.figure.scene)
    idx == length(slides) && break
    Cairo.show_page(screen.context)
    Cairo.restore(screen.context)
  end
  Cairo.finish(screen.surface)

  GLMakie.activate!()
end


end # module
