using MakieSlides
using GLMakie
GLMakie.activate!()


f = Figure()

txt = text(f[1,1], "text function")
fmttxt = formattedtext(f[1,2], "*formattedtext* **function**", word_wrap_width=10.0)

# txt = text!(f.scene, "text function")
# bbox = boundingbox(txt)
# fmttxt = formattedtext!(f.scene, "*formattedtext* **function** which (hopefully) wraps by itself asdfadsf adsfdas  fdas fdas fds fasd asf", word_wrap_width=100)
# bbox = boundingbox(txt)

f
