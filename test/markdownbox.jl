using MakieSlides
using GLMakie
GLMakie.activate!()


f = Figure()

# mdbox = MarkdownBox(f[1,1], "hello world!")
# mdbox = MarkdownBox(f[1,2], "hello universe!")

f[1,1] = MarkdownBox(f, "hello world!")
f[1,2] = MarkdownBox(f, "hello universe!")

# lbl = Label(f[1,1], "hello world!")
# lbl = Label(f[1,2], "hello universe!")

# f[1,1] = Label(f, "hello world!")
# f[1,2] = Label(f, "hello universe!")

f
