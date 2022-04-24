using MakieSlides
using GLMakie
GLMakie.activate!()


f = Figure()

txt = text(f[1,1], "text function")
ftxt = formattedtext(f[2,1], "*formattedtext* **function** which (hopefully) wraps by itself asdfadsf adsfdas  fdas fdas fds fasd asf", maxwidth=100)

f
