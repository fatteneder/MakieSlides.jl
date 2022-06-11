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
        inspectable = theme(scene, :inspectable),
        word_wrap_width = 0.0
    )
end


# convert strings to Markdown.MD
function Makie.plot!(plot::FormattedText{<:Tuple{<:AbstractString}}) 
    markdown = Markdown.parse(plot[:text][])
    formattedtext!(plot, markdown; plot.attributes...)
end


function Makie.plot!(plot::FormattedText{<:Tuple{<:Markdown.MD}})

    ###
    # Notes:
    # - literals (`...`) and code blocks (```...```) are both wrapped as Markdown.Code.
    # It think the way to distinguish them is to check whether one appears within the contents
    # of a Markdown.Paragraph (=^= literal) or Markdown.MD(=^= code block).

    markdown = plot[1][]
    all_elements = Any[]
    for (index, element) in enumerate(markdown.content)
        if !(element isa Markdown.Paragraph)
            error("Cannot format markdown element '$element'")
        end
        append!(all_elements, element.content)
        index < length(markdown.content) && push!(all_elements, "\n")
    end

    one_paragraph = Markdown.Paragraph(all_elements)
    formattedtext!(plot, one_paragraph; plot.attributes...)

    plot
end


function Makie.plot!(plot::FormattedText{<:Tuple{<:Markdown.Paragraph}})

    text = plot[:text]
    linewrap_positions = Observable(Int64[])

    text_elements_fonts = Observable(Tuple{String,Makie.FreeTypeAbstraction.FTFont}[])
    onany(text, plot.font) do paragraph, font
        empty!(text_elements_fonts.val)
        for md_element in paragraph.content
            element_string, element_ft_font = if md_element isa Markdown.Bold
                first(md_element.text), to_bold_font(font)
            elseif md_element isa Markdown.Italic
                first(md_element.text), to_italic_font(font)
            elseif md_element isa Markdown.Code
                md_element.code, to_code_font(font)
            elseif md_element isa String
                md_element, to_font(font)
            else
                error("Cannot handle paragraph text element '$(md_element)' which " *
                      "is of type '$(typeof(md_element))'")
            end
            push!(text_elements_fonts.val, (element_string, element_ft_font))
        end
        notify(text_elements_fonts)
    end

    # attach a function to any text that calculates the glyph layout and stores it
    glyphcollection = lift(text_elements_fonts, plot.textsize, plot.align,
            plot.rotation, plot.justification, plot.lineheight,
            plot.color, plot.strokecolor, plot.strokewidth, 
            plot.word_wrap_width) do elements_fonts, ts, al, rot, jus, lh, col, scol, 
                swi, word_wrap_width

        ts = to_textsize(ts)
        rot = to_rotation(rot)
        col = to_color(col)
        scol = to_color(scol)

        layout_formatted_text(elements_fonts, ts, al, rot, jus, lh, col, scol, swi, word_wrap_width)
    end

    text!(plot, glyphcollection; plot.attributes...)

    notify(plot.text)

    plot
end


function Makie.plot!(plot::FormattedText{<:Tuple{<:Union{Markdown.Admonition, 
                                                         Markdown.BlockQuote,
                                                         Markdown.Bold,
                                                         Markdown.Code,
                                                         Markdown.Footnote,
                                                         Markdown.Header,
                                                         Markdown.HorizontalRule,
                                                         Markdown.Image,
                                                         Markdown.Italic,
                                                         Markdown.LaTeX,
                                                         Markdown.LineBreak,
                                                         Markdown.Link,
                                                         Markdown.List,
                                                         Markdown.MD,
                                                         Markdown.Paragraph,
                                                         Markdown.Table}}})
    error("plot! method not implemented for argument type '$(typeof(plot[1]))'")
end


to_bold_font(x::Union{Symbol, String}) = to_font("$(string(x)) bold")
to_bold_font(x::Vector{String}) = to_bold_font.(x)
to_bold_font(x::NativeFont) = to_bold_font(x.family_name)
to_bold_font(x::Vector{NativeFont}) = x


to_italic_font(x::Union{Symbol, String}) = to_font("$(string(x)) oblique")
to_italic_font(x::Vector{String}) = to_italic_font.(x)
to_italic_font(x::NativeFont) = to_italic_font(x.family_name)
to_italic_font(x::Vector{NativeFont}) = x


to_code_font(x::Union{Symbol, String}) = to_font("Times New Roman") # who codes with this font? :)
to_code_font(x::Vector{String}) = to_code_font.(x)
to_code_font(x::NativeFont) = to_code_font(x.family_name)
to_code_font(x::Vector{NativeFont}) = x


function layout_formatted_text(
        text_elements_fonts::Vector{Tuple{String,Makie.FreeTypeAbstraction.FTFont}},
        textsize::Union{AbstractVector, Number}, align, rotation, justification, lineheight,
        color, strokecolor, strokewidth, word_wrap_width
    )

    rscale = to_textsize(textsize)
    rot = to_rotation(rotation)

    text = ""
    fontperchar = Any[]
    textsizeperchar = Any[]
    for (element, font) in text_elements_fonts

        text = text * element

        element_fontperchar = Makie.attribute_per_char(element, font)
        element_textsizeperchar = Makie.attribute_per_char(element, rscale)

        append!(fontperchar, element_fontperchar)
        append!(textsizeperchar, element_textsizeperchar)
    end

    glyphcollection = Makie.glyph_collection(text, fontperchar, textsizeperchar, align[1],
                                             align[2], lineheight, justification, rot, color, 
                                             strokecolor, strokewidth, word_wrap_width)

    return glyphcollection
end
