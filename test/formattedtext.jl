using MakieSlides
using GLMakie
GLMakie.activate!()


f = Figure()

txt = text(f[1,1], "text function")
fmttxt = formattedtext(f[1,2], "*formattedtext* **function**")

# txt = text!(f.scene, "text function")
# bbox = boundingbox(txt)
# fmttxt = formattedtext!(f.scene, "*formattedtext* **function** which (hopefully) wraps by itself asdfadsf adsfdas  fdas fdas fds fasd asf", maxwidth=100)
# bbox = boundingbox(txt)

f
