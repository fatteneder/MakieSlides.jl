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
        maxwidth = 0.0
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

    # attach a function to any text that calculates the glyph layout and stores it
    glyphcollection = lift(text, plot.textsize, plot.font, plot.align,
            plot.rotation, plot.justification, plot.lineheight,
            plot.color, plot.strokecolor, plot.strokewidth, linewrap_positions, 
            plot.maxwidth) do str, ts, f, al, rot, jus, lh, col, scol, swi, positions, maxwidth

        ts = to_textsize(ts)
        f = to_font(f)
        rot = to_rotation(rot)
        col = to_color(col)
        scol = to_color(scol)

        layout_formatted_text(str, positions, ts, f, al, rot, jus, lh, col, scol, swi, maxwidth)
    end

    text!(plot, glyphcollection; plot.attributes...)

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
        paragraph::Markdown.Paragraph, linewrap_positions::Vector{Int64},
        textsize::Union{AbstractVector, Number},
        font, align, rotation, justification, lineheight, color, strokecolor, strokewidth,
        word_wrap_width
    )

    rscale = to_textsize(textsize)
    rot = to_rotation(rotation)

    text = ""
    fontperchar = Any[]
    textsizeperchar = Any[]
    for textelement in paragraph.content

        textelement_string, textelement_ft_font = if textelement isa Markdown.Bold
            first(textelement.text), to_bold_font(font)
        elseif textelement isa Markdown.Italic
            first(textelement.text), to_italic_font(font)
        elseif textelement isa Markdown.Code
            textelement.code, to_code_font(font)
        elseif textelement isa String
            textelement, to_font(font)
        else
            error("Cannot handle paragraph text element '$(textelement)' which " *
                  "is of type '$(typeof(textelement))'")
        end

        # textelement_length = length(textelement_string)

        # while iter !== nothing
        #     next_linewrap_position, state = iter
        #     next_linewrap_position > scanned_position + textelement_length && break
        #     # whitespace in current textelement
        #     whitespace_position = next_linewrap_position - scanned_position
        #     textelement_string = textelement_string[1:whitespace_position-1] * "\n" *
        #                      textelement_string[whitespace_position+1:end]
        #     textelement_length = length(textelement_string)
        #     iter = iterate(linewrap_positions, state)
        # end

        # scanned_position += textelement_length
        text = text * textelement_string

        textelement_fontperchar = Makie.attribute_per_char(textelement_string, textelement_ft_font)
        textelement_textsizeperchar = Makie.attribute_per_char(textelement_string, rscale)

        append!(fontperchar, textelement_fontperchar)
        append!(textsizeperchar, textelement_textsizeperchar)
    end

    glyphcollection = Makie.glyph_collection(text, fontperchar, textsizeperchar, align[1],
                                             align[2], lineheight, justification, rot, color, 
                                             strokecolor, strokewidth, word_wrap_width)

    return glyphcollection
end
