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
  ratio_controls = 1/10

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



function periodic_index(i,N) 
  mod = i % N
  return mod == 0 ? N : mod
end


function Base.display(presentation::Presentation)
  slides = presentation.slides
  @assert length(slides) > 0
  N_slides = length(slides)


  ### Use only one figure and display current slide within slide_pane
  ### Right now this is not possible, because Makie cannot yet move plot objects in between figures
  ### See https://discourse.julialang.org/t/makie-is-there-an-easy-way-to-combine-several-figures-into-a-new-figure-without-re-plotting/64874
  # figure = Figure()
  # figure[1,1] = slide_pane = GridLayout()
  # figure[2,1] = control_pane = GridLayout(tellwidth=false)
  # control_labels = [ "Previous", "Next" ]
  # control_buttons = control_pane[1,1:2] = [ Button(figure, label = l) for l in control_labels ]
  #
  # index = 1
  # on(events(figure).keyboardbutton) do event
  #   # register control button actions
  #   end
  # end
  # show first slide
  # slide_pane = slides[index].figure[1,1]
  # display(figure)

  # Right now we must register events for every slide separately
  for (index, slide) in enumerate(slides)
    on(events(slide.figure).keyboardbutton) do event
      if event.action == Keyboard.press
        index_next = if event.key in (Keyboard.left, Keyboard.h)
          periodic_index(index-1, N_slides)
        elseif event.key in (Keyboard.down, Keyboard.j)
          periodic_index(index-1, N_slides)
        elseif event.key in (Keyboard.right, Keyboard.l)
          periodic_index(index+1, N_slides)
        elseif event.key in (Keyboard.up, Keyboard.k)
          periodic_index(index+1, N_slides)
        # TODO add close window
        else
          @warn "Unused key pressed: $(event.key)"
          index
        end
        display(slides[index_next].figure)
      end
    end
  end
  # show first slide
  display(slides[1])

  return
end


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
