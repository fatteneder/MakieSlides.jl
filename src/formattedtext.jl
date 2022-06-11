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
    glyphcollection = Observable{Makie.GlyphCollection}()
    emojicollection = Observable{Vector{Tuple{String,Int64}}}()
    onany(text_elements_fonts, plot.textsize, plot.align, plot.rotation, 
          plot.justification, plot.lineheight, plot.color, plot.strokecolor, plot.strokewidth, 
          plot.word_wrap_width) do elements_fonts, ts, al, rot, jus, lh, col, scol, swi, www

        ts = to_textsize(ts)
        rot = to_rotation(rot)
        col = to_color(col)
        scol = to_color(scol)

        glc, emc = layout_formatted_text(elements_fonts, ts, al, rot, jus, lh, col, scol, swi, www)
        glyphcollection[] = glc
        emojicollection[] = emc
    end

    notify(plot.text)
    textplot = text!(plot, glyphcollection; plot.attributes...)

    glyphbbs = lift(glyphcollection) do glc
        gl_bboxes(glc)
    end

    on(emojicollection) do ec
        # txtbbox = Rect2f(boundingbox(textplot))
        # bbox = Rect2f(0,0,0,0)
        # for bb in glyphbbs[]
        #     display(bb.origin)
        # end
        for (shorthand, pos) in ec
            filename = emoji_filename_png(shorthand)
            e_img = load_emoji_image(filename)
            bbox = glyphbbs[][pos]
            w, h = width(bbox), height(bbox)
            # these bboxes don't know about their predecessors, hence, the emojis are placed wrongly
            box, boy = bbox.origin
            msize = max(w, h)
            scatter!(plot, (box, boy), marker=e_img, markersize=200, markerspace=:data,
                     space=:data)
        end
    end

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
    colorperchar = Any[]
    emojicollection = Tuple{String,Int64}[]
    scanned_position = 0
    for (element, font) in text_elements_fonts

        # replace emojis here which are given by the syntax :emoij_shorthand:
        element_emojis = Tuple{String,Int64}[]
        m = match(RGX_EMOJI, element)
        while !isnothing(m)
            # query shorthands and replace them with a placeholder character
            # later we plot the actual emoji ontop of the placeholder
            e = first(m.captures)
            isunknown = !(e in keys(EMOJIS_MAP))
            placeholder_e = isunknown ? '\UFFFD' #= � =# : first(EMOJIS_MAP[e])
            pos_lhs_colon = prevind(element, m.offset)
            pos_rhs_colon = nextind(element, m.offset+length(e)+1)
            element = element[1:pos_lhs_colon] * "$placeholder_e" * element[pos_rhs_colon:end]
            !isunknown && push!(element_emojis, (e, scanned_position+m.offset))
            m = match(RGX_EMOJI, element)
        end
        append!(emojicollection, element_emojis)

        scanned_position += length(element)
        text = text * element

        element_fontperchar = Makie.attribute_per_char(element, font)
        element_textsizeperchar = Makie.attribute_per_char(element, rscale)
        element_colorperchar = collect(Makie.attribute_per_char(element, color))

        # make emoji placeholders transparent
        for (_, pos) in element_emojis
            element_colorperchar[pos] = RGBA{Float32}(0,0,0,0)
        end

        append!(fontperchar, element_fontperchar)
        append!(textsizeperchar, element_textsizeperchar)
        append!(colorperchar, element_colorperchar)
    end

    glyphcollection = Makie.glyph_collection(text, fontperchar, textsizeperchar, align[1],
        align[2], lineheight, justification, rot, colorperchar, strokecolor, strokewidth,
        word_wrap_width)

    return glyphcollection, emojicollection
end
