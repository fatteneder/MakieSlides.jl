"""
    text(text::Markdown.MD)

Plots `Markdown` formatted text.

"""
@recipe(FormattedText, text) do scene
    Attributes(;
        default_theme(scene)...,
        color = theme(scene, :textcolor),
        font = theme(scene, :font),
        strokecolor = (:black, 0.0),
        strokewidth = 0,
        align = (:left, :bottom),
        rotation = 0.0,
        textsize = 20,
        position = (0.0, 0.0),
        justification = automatic,
        lineheight = 1.0,
        space = :data,
        markerspace = :pixel,
        offset = (0.0, 0.0),
        inspectable = theme(scene, :inspectable)
    )
end


# convert strings to Markdown.MD
function Makie.plot!(plot::FormattedText{<:Tuple{<:AbstractString}}) 
    md = Markdown.parse(plot[:text][])
    formattedtext!(plot, md)
end


function Makie.plot!(plot::FormattedText{<:Tuple{<:Markdown.MD}})

    markdown = plot[1][]
    all_elements = Any[]
    for (index, element) in enumerate(markdown.content)
        if !(element isa Markdown.Paragraph)
            display(typeof(element))
            error("Cannot plot markdown element '$element'")
        end
        append!(all_elements, element.content)
        index < length(markdown.content) && push!(all_elements, "\n")
    end

    one_paragraph = Markdown.Paragraph(all_elements)
    formattedtext!(plot, one_paragraph; plot.attributes)

    plot
end


function Makie.plot!(plot::FormattedText{<:Tuple{<:Markdown.Paragraph}})

    # attach a function to any text that calculates the glyph layout and stores it
    glyphcollection = lift(plot[1], plot.textsize, plot.font, plot.align,
            plot.rotation, plot.justification, plot.lineheight,
            plot.color, plot.strokecolor, plot.strokewidth) do str,
                ts, f, al, rot, jus, lh, col, scol, swi
        ts = to_textsize(ts)
        f = to_font(f)
        rot = to_rotation(rot)
        col = to_color(col)
        scol = to_color(scol)

        layout_formatted_text(str, ts, f, al, rot, jus, lh, col, scol, swi)
    end

    text!(plot, glyphcollection)

    plot
end


to_bold_font(x::Union{Symbol, String}) = to_font("$(string(x)) bold")
to_bold_font(x::Vector{String}) = to_bold_font.(x)
to_bold_font(x::NativeFont) = to_bold_font(x.family_name)
to_bold_font(x::Vector{NativeFont}) = x


to_italic_font(x::Union{Symbol, String}) = to_font("$(string(x)) oblique")
to_italic_font(x::Vector{String}) = to_italic_font.(x)
to_italic_font(x::NativeFont) = to_italic_font(x.family_name)
to_italic_font(x::Vector{NativeFont}) = x


function layout_formatted_text(
        paragraph::Markdown.Paragraph, textsize::Union{AbstractVector, Number},
        font, align, rotation, justification, lineheight, color, strokecolor, strokewidth
    )

    rscale = to_textsize(textsize)
    rot = to_rotation(rotation)

    string = ""
    fontperchar = Any[]
    textsizeperchar = Any[]
    for element in paragraph.content

        element_string, element_ft_font = if element isa Markdown.Bold
            element.text[1], to_bold_font(font)
        elseif element isa Markdown.Italic
            element.text[1], to_italic_font(font)
        elseif element isa String
            element, to_font(font)
        else
            error("Cannot handle paragraph element '$(element)' which is of type '$(typeof(element))'")
        end

        element_fontperchar = Makie.attribute_per_char(element_string, element_ft_font)
        element_textsizeperchar = Makie.attribute_per_char(element_string, rscale)

        string = string * element_string
        append!(fontperchar, element_fontperchar)
        append!(textsizeperchar, element_textsizeperchar)
    end

    glyphcollection = Makie.glyph_collection(string, fontperchar, textsizeperchar, align[1],
        align[2], lineheight, justification, rot, color, strokecolor, strokewidth)

    return glyphcollection
end
