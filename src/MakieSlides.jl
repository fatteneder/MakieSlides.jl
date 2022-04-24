module MakieSlides


using GLMakie
using CairoMakie
using Markdown
using Makie
using Printf
import Cairo


# dependencies on Makie internals
import Makie: NativeFont
import MakieCore: automatic


export Slide, slidetext!, slideheader!, slidefooter!, Presentation, save
export formattedtext, formattedtext!


include("formattedtext.jl")
include("formattedlabel.jl")
include("formattedlist.jl")
include("markdownbox.jl")


struct Slide
  figure
  panes::Dict
end


function Slide(; hide_decorations::Bool=true, 
                 title="",
                 aspect=(16,9))

  @assert all(aspect .> 0)

  # TODO 
  # 1. Right now the content has a fixed size. If we resize the window below that size
  # then the content gets cropped. Can we make it such that instead of cropping we resize
  # it and maintain the aspect ratio?
  # 2. Figure out how to maintain the figure size between different slides. Can this be done with
  # observables?
  # 3. We deactivated zooming for indiviual axis. Can be enable a global zooming that adjusts
  # the figure resolution? Might also be useful for 1.

  ratio = aspect[1] / aspect[2]
  width = 1400
  height = width / ratio
  resolution = (width*1.05,height*1.05) # add some border outlines
  figure = Figure(resolution=resolution)

  axis_options = (; xzoomlock=true, xpanlock=true, xrectzoom=false,
                    yzoomlock=true, ypanlock=true, yrectzoom=false)
  panes = Dict(:header  => Axis(figure[1,1]; axis_options...),
               :content => Axis(figure[2,1]; axis_options...),
               :footer  => Axis(figure[3,1]; axis_options...))

  linkxaxes!(panes[:content], panes[:header])
  linkxaxes!(panes[:content], panes[:footer])
  colsize!(figure.layout, 1, Fixed(width))

  ratio_header = 1/10
  ratio_footer = 1/10
  rowsize!(figure.layout, 1, Fixed(height * ratio_header))
  rowsize!(figure.layout, 2, Fixed(height * (1 - ratio_header - ratio_footer)))
  rowsize!(figure.layout, 3, Fixed(height * ratio_header))

  pane_aspects = Dict(:header => (aspect[1], 1+aspect[2] * ratio_header),
                      :content =>(aspect[1], 1+aspect[2] * (1 - ratio_header - ratio_footer)),
                      :footer => (aspect[1], 1+aspect[2] * ratio_footer))

  for (k, pane) in pairs(panes)
    asp = pane_aspects[k]
    limits!(pane, 1, asp[1], 1, asp[2])
    if hide_decorations
      hidedecorations!(pane, grid=true)
      hidespines!(pane)
    end
  end

  rowgap!(figure.layout, 0)
  colgap!(figure.layout, 0)

  return Slide(figure, panes)
end


function slidetext!(slide, text)
  pane = slide.panes[:content]
  rect = pane.targetlimits[]
  xwidth, ywidth = rect.widths
  xorigin, yorigin = rect.origin
  origin_text = Point2f(xorigin,yorigin+ywidth)
  t = formattedtext!(pane, text, position=origin_text, align=(:left,:top),
                     space=:data, textsize=0.5)
end


function slideheader!(slide, text)
  pane = slide.panes[:header]
  rect = pane.targetlimits[]
  xwidth, ywidth = rect.widths
  xorigin, yorigin = rect.origin
  origin_text = Point2f(xorigin,yorigin+ywidth/2)
  t = formattedtext!(pane, text, position=origin_text, align=(:left,:center),
                     space=:data, textsize=0.5)
end


function slidefooter!(slide, text)
  pane = slide.panes[:footer]
  rect = pane.targetlimits[]
  xwidth, ywidth = rect.widths
  xorigin, yorigin = rect.origin
  origin_text = Point2f(xorigin,yorigin+ywidth/2)
  t = formattedtext!(pane, text, position=origin_text, align=(:left,:center),
                     space=:data, textsize=0.5)
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


function save(name, presentation::Presentation; aspect=(16,9))
  CairoMakie.activate!()

  slides = presentation.slides
  @assert length(slides) > 0

  ratio = aspect[1] / aspect[2]
  width = 1400
  height = width / ratio
  resolution = (width*1.05,height*1.05) # add some border outlines
  figure = Figure(resolution=resolution)
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
