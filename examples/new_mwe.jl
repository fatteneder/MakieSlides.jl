using GLMakie, MakieSlides

pres = Presentation(figure_padding = (50, 50, 50, 50))
display(pres)

add_slide!(pres) do fig
    Label(fig[1, 1], "This is a title", textsize = 100, tellwidth = false)
    Label(fig[2, 1], "with a subtitle", textsize = 60, tellwidth = false)
    rowgap!(fig.layout, 1, Fixed(10))
end

add_slide!(pres) do fig
    Label(fig[1, 1:2], "This is a Slide title", textsize = 40, tellwidth = false)
    scene = LScene(fig[2, 1], tellwidth = false)
    campixel!(scene)

    formattedtext!(scene, """
    Hello world! 
    
    Here follows a very long text which I don't know about whether it will line break or not... probably not
    
    ... above line should have wrapped around :(
    
    But here is some formatted text
    
    *italic* works
    
    **bold** works
    
    `code` works (ignoring language for now; colored background would be cool)
    """)

    ax = Axis(fig[2, 2], title = "A fancy plot")
    scatter!(ax, range(0, 4pi, length=101), sin)
end

add_slide!(pres) do fig
    Label(fig[1, 1:2], "Another title", textsize = 40, tellwidth = false)

    # TODO: This errors because of string indexing
    # FormattedLabel(fig[2, 1], """
    # FormattedLabel test\n
    # • *italic* text\n
    # • **bold** text\n
    # • `code`\n
    # And a very long line that should really wrap so you can actually read it but probably wont because it's not implemented yet?
    # """, tellheight = false, tellwidth = false
    # )
    str = """
    Look at this long line of text. Because it is long it would usually flow out of the Label but we have word wrapping so it doesn't!
    
    *italic* works
    
    **bold** works
    
    `code` works (ignoring language for now; colored background would be cool)
    """
    FormattedLabel(fig[2, 1], str, halign = :right, valign = :bottom, tellheight = false, tellwidth = false)
    FormattedLabel(fig[2, 2], str, halign = :left,  valign = :top, tellheight = false, tellwidth = false)
    FormattedLabel(fig[3, 1], str, tellheight = false, tellwidth = false)
    FormattedLabel(fig[3, 2], str, justification = :right, tellheight = false, tellwidth = false)
end

# Move to first slide
reset!(pres)