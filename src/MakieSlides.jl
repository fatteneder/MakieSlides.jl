module MakieSlides


using GLMakie
using CairoMakie


export Slide,
       slidetext!,
       slideheader!,
       slidefooter!,
       save

#=
mutable sturct Presentation
  slides::Vector{Slides}
  title::String
  author::String
  slidenumbers::Bool
end
=#


struct Slide
  fig
  axis::Dict
end


function Slide(; hide_decorations::Bool=true, 
                 title="",
                 aspect=(16,9))

  @assert all(aspect .> 0)

  fig = Figure()

  axis = Dict(:header  => Axis(fig[1,1]),
              :content => Axis(fig[2,1]),
              :footer  => Axis(fig[3,1]))

  ratio_header = 1/10
  rowsize!(fig.layout, 1, Auto(ratio_header))
  ratio_footer = 1/10
  rowsize!(fig.layout, 3, Auto(ratio_footer))

  aspects = Dict(:header => (aspect[1], 1+aspect[2]*ratio_header),
                 :content => aspect,
                 :footer => (aspect[1], 1+aspect[2]*ratio_footer))

  for (k, ax) in pairs(axis)
    asp = aspects[k]
    limits!(ax, 1, asp[1], 1, asp[2])
    if hide_decorations
      hidedecorations!(ax,grid=true)
      hidespines!(ax)
    end
  end

  rowgap!(fig.layout, 5)
  colgap!(fig.layout, 5)

  return Slide(fig, axis)
end


function slidetext!(slide, text)
  pane = slide.axis[:content]
  rect = pane.targetlimits[]
  xwidth, ywidth = rect.widths
  xorigin, yorigin = rect.origin
  origin_text = Point2f(xorigin,yorigin+ywidth)
  t = text!(pane, text, position=origin_text, align=(:left,:top))
  display(t.attributes)
end


function slideheader!(slide, text)
  pane = slide.axis[:header]
  rect = pane.targetlimits[]
  xwidth, ywidth = rect.widths
  xorigin, yorigin = rect.origin
  origin_text = Point2f(xorigin,yorigin+ywidth/2)
  t = text!(pane, text, position=origin_text, align=(:left,:center))
  display(t.attributes)
end


function slidefooter!(slide, text)
  pane = slide.axis[:footer]
  rect = pane.targetlimits[]
  xwidth, ywidth = rect.widths
  xorigin, yorigin = rect.origin
  origin_text = Point2f(xorigin,yorigin+ywidth/2)
  t = text!(pane, text, position=origin_text, align=(:left,:center))
  display(t.attributes)
end


Base.display(s::Slide) = display(s.fig)


function save(name, s::Slide)
  CairoMakie.activate!()
  CairoMakie.save(name, s.fig)
  GLMakie.activate!()
end


end # module
