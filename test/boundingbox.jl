using MakieSlides
using GLMakie
GLMakie.activate!()

f = Figure()
box1, box2 = [ Box(f) for _ = 1:2 ]
gl = GridLayout()
gl[1:2,1] = [box1, box2]
f.layout[1,1] = gl

f
