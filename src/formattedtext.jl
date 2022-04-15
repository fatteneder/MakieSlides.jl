import Makie: gl_bboxes


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
        maxwidth = 50.0
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
    # In the following example the literal is wrapped into a paragraph which is inside
    # a List object, so it seems to work:
    # md"""
    # - item with a `literal`
    # - another item
    # """
    #
    # But what about
    # md"""
    # - item 
    # ```
    # nested code block here?
    # ```
    # """
    # Markdown.jl interprets this as two separate objects, namely a Markdown.List and a
    # Markdown.Code, so nothing to worry here.

    markdown = plot[1][]
    all_elements = Any[]
    for (index, element) in enumerate(markdown.content)
        if !(element isa Markdown.Paragraph)
            error("Cannot plot markdown element '$element'")
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
            plot.color, plot.strokecolor, plot.strokewidth, linewrap_positions) do str,
                ts, f, al, rot, jus, lh, col, scol, swi, positions
        ts = to_textsize(ts)
        f = to_font(f)
        rot = to_rotation(rot)
        col = to_color(col)
        scol = to_color(scol)

        layout_formatted_text(str, positions, ts, f, al, rot, jus, lh, col, scol, swi)
    end

    default_glyphs   = glyphcollection[].glyphs
    default_glyphbbs = gl_bboxes(glyphcollection[])
    on(plot.maxwidth) do maxwidth
        # bbox = boundingbox(glyphcollection[], Point3f(0,0,0), Quaternion(0,0,0,1))
        linewrap_positions[] = estimate_linewrap_positions(default_glyphs, default_glyphbbs, maxwidth)
        # display(positions)
        # wrapped_text = if length(positions) > 0
        #     wrapped_text = ""
        #     for pos in positions
        #         wrapped_text *= text[1:pos] * "\n"
        #     end
        #     wrapped_text *= text[positions[end]:end]
        # else
        #     text
        # end
        # display(text)
        # display(wrapped_text)
        # display(bbox.widths)
        # line break manually here
    end

    text!(plot, glyphcollection; plot.attributes...)

    plot
end


function estimate_linewrap_positions(glyphs, glyphbbs, maxwidth)
    N = length(glyphs)
    @assert N == length(glyphbbs)
    positions = Int64[]
    last_linewrap_pos = 1
    width = 0
    for (pos, (g, bb)) in enumerate(zip(glyphs, glyphbbs))
        width += bb.widths[1]
        if width > maxwidth
            # time to wrap, but we need a white space to do so, hence, search backwards
            whitespace_pos = pos
            for gg in reverse(glyphs[last_linewrap_pos:pos])
                gg == ' ' && break
            end
            if whitespace_pos == last_linewrap_pos
                @info "Failed to find whitespace for line wrapping, skipping ..."
                return positions
            end
            push!(positions, whitespace_pos)
            width = 0 # reset width count
            last_linewrap_pos = whitespace_pos + 1
        end
    end
    return positions
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
        paragraph::Markdown.Paragraph, positions_linewraps::Vector{Int64},
        textsize::Union{AbstractVector, Number},
        font, align, rotation, justification, lineheight, color, strokecolor, strokewidth
    )

    rscale = to_textsize(textsize)
    rot = to_rotation(rotation)

    string = ""
    fontperchar = Any[]
    textsizeperchar = Any[]
    scanned_length = 1
    display(positions_linewraps)
    iterate_position = iterate(positions_linewraps)
    for element in paragraph.content

        element_string, element_ft_font = if element isa Markdown.Bold
            element.text[1], to_bold_font(font)
        elseif element isa Markdown.Italic
            element.text[1], to_italic_font(font)
        elseif element isa Markdown.Code
            element.code, to_code_font(font)
        elseif element isa String
            element, to_font(font)
        else
            error("Cannot handle paragraph element '$(element)' which is of type '$(typeof(element))'")
        end

        element_length = length(element_string)
        if iterate_position !== nothing
            next_position, state_position = iterate_position
            delta_position = next_position - scanned_length
            if delta_position < element_length
                element_string = element_string[1:delta_position] * "\n" *
                                 element_string[delta_position+1:end]
                element_length += 1
                iterate_position = iterate(iterate_position, state_position)
            end
        end

        scanned_length += element_length
        string = string * element_string

        element_fontperchar = Makie.attribute_per_char(element_string, element_ft_font)
        element_textsizeperchar = Makie.attribute_per_char(element_string, rscale)

        append!(fontperchar, element_fontperchar)
        append!(textsizeperchar, element_textsizeperchar)
    end

    glyphcollection = Makie.glyph_collection(string, fontperchar, textsizeperchar, align[1],
        align[2], lineheight, justification, rot, color, strokecolor, strokewidth)

    return glyphcollection
end
