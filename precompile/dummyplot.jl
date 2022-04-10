function dummyplotting()
  xs = range(0,10,length=250)
  ys = range(0,15,length=150)
  zs = [cos(x)*sin(y) for x in xs, y in ys]

  f = Figure()

  heatmap(f[1,1], xs, ys, zs)
  contourf(f[1,2], xs, ys, zs)
  lines(f[2,1], xs, xs)
  scatter(f[2,2], xs, xs)
  scatterlines(f[3,1:2], xs, xs)

  return f
end


using CairoMakie
CairoMakie.activate!()
f = dummyplotting()
save(Base.Filesystem.tempname() * ".pdf", f)
save(Base.Filesystem.tempname() * ".png", f)

using GLMakie
GLMakie.activate!()
f = dummyplotting()
display(f)
