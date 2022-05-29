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
    glyphcollection_emojicollection = lift(text, plot.textsize, plot.font, plot.align,
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

    # since lift can only return one Observable at a time we have to unpack
    # glyphcollection_emojicollection here
    glyphcollection = Observable(glyphcollection_emojicollection[][1])
    emojicollection = Observable(glyphcollection_emojicollection[][2])
    glyphbbs = Observable(gl_bboxes(glyphcollection_emojicollection[][1]))
    on(glyphcollection_emojicollection) do gc_ec
        gc, ec = gc_ec
        glyphcollection[] = gc
        emojicollection[] = ec
        glyphbbs[] = gl_bboxes(gc)
    end

    default_glyphs   = glyphcollection[].glyphs
    default_glyphbbs = gl_bboxes(glyphcollection[])
    on(plot.maxwidth) do maxwidth

        # split up glyphs and bboxes into blocks corresponding to the parapgrah blocks that
        # are separated by empty lines
        splits = [ firstindex(default_glyphs),
                   findall(g -> g == '\n', default_glyphs)...,
                   lastindex(default_glyphs) ]
        s1, s2 = @view(splits[1:end-1]), @view(splits[2:end])
        glyph_blocks     = [ view( default_glyphs,
                                  (n == 1 ? i1 : i1+1):(n == length(splits)-1 ? i2 : i2-1)
                                 )
                             for (n, (i1, i2)) in enumerate(zip(s1, s2)) ]
        glyphbbox_blocks = [ view( default_glyphbbs,
                                  (n == 1 ? i1 : i1+1):(n == length(splits)-1 ? i2 : i2-1)
                                 )
                            for (n, (i1, i2)) in enumerate(zip(s1, s2)) ]
        linewrap_positions_per_block = estimate_linewrap_positions.(glyph_blocks, 
                                                                    glyphbbox_blocks,
                                                                    maxwidth)
        # add index offsets
        for (idx, offset) in enumerate(s1)
            linewrap_positions_per_block[idx] .+= idx == 1 ? 0 : offset
        end

        linewrap_positions[] = vcat(linewrap_positions_per_block...)
    end

    plot.maxwidth[] = plot.maxwidth[]

    txt = text!(plot, glyphcollection; plot.attributes...)

    on(emojicollection) do ec
        # txtbbox = Rect2f(boundingbox(txt))
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

    notify(glyphcollection_emojicollection)

    plot
end


function estimate_linewrap_positions(glyphs, glyphbbs, maxwidth)
    fullwidth = sum(width.(glyphbbs))
    (maxwidth <= 0 || maxwidth > fullwidth) && return Int64[]
    N = length(glyphs)
    @assert N == length(glyphbbs)
    positions = Int64[]
    last_linewrap_pos, accumulated_width, pos = 1, 0, 1
    while pos <= N
        bb = glyphbbs[pos]
        accumulated_width += width(bb)
        if accumulated_width > maxwidth
            # time to wrap, search backwards for first whitespace
            whitespace_pos = pos
            for j = reverse(last_linewrap_pos+1:pos-1)
                if glyphs[j] == ' '; whitespace_pos = j; break; end
            end
            if whitespace_pos == pos
                # failed to find any whitespace and exact wrapping has now failed
                # we search forwards for the next whitespace
                # this will yield overly high boundingboxes -- is that an issue?
                while whitespace_pos <= N
                    if glyphs[whitespace_pos] == ' '; break; end
                    whitespace_pos += 1
                end
            end
            push!(positions, whitespace_pos)
            accumulated_width, last_linewrap_pos = 0, whitespace_pos
            pos = last_linewrap_pos + 1 # + 1 to skip the whitespace at which we line wrap
        else
            pos += 1
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
        paragraph::Markdown.Paragraph, linewrap_positions::Vector{Int64},
        textsize::Union{AbstractVector, Number},
        font, align, rotation, justification, lineheight, color, strokecolor, strokewidth
    )

    rscale = to_textsize(textsize)
    rot = to_rotation(rotation)

    string = ""
    fontperchar = Any[]
    textsizeperchar = Any[]
    colorperchar = Any[]
    emojicollection = Tuple{String,Int64}[]
    scanned_position = 0
    iter = iterate(linewrap_positions)
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

        # replace emojis here which are given by the syntax :emoij_shorthand:
        textelement_emojis = Tuple{String,Int64}[]
        m = match(RGX_EMOJI, textelement_string)
        while !isnothing(m)
            # query shorthands and replace them with a placeholder character
            # later we plot the actual emoji ontop of the placeholder
            e = first(m.captures)
            isunknown = !(e in keys(EMOJIS_MAP))
            placeholder_e = isunknown ? '\UFFFD' #= � =# : first(EMOJIS_MAP[e])
            start_pos     = prevind(textelement_string, m.offset) # starting colon
            end_pos       = nextind(textelement_string, m.offset+length(e)+1) # ending colon
            textelement_string = textelement_string[1:start_pos] * "$placeholder_e" *
                textelement_string[end_pos:end]
            !isunknown && push!(textelement_emojis, (e, scanned_position+m.offset))
            m = match(RGX_EMOJI, textelement_string)
        end
        append!(emojicollection, textelement_emojis)

        textelement_length = length(textelement_string)

        while iter !== nothing 
            next_linewrap_position, state = iter
            next_linewrap_position > scanned_position + textelement_length && break
            # whitespace in current textelement
            whitespace_position = next_linewrap_position - scanned_position
            textelement_string = textelement_string[1:whitespace_position-1] * "\n" *
                             textelement_string[whitespace_position+1:end]
            textelement_length = length(textelement_string)
            iter = iterate(linewrap_positions, state)
        end

        scanned_position += textelement_length
        string = string * textelement_string

        textelement_fontperchar = Makie.attribute_per_char(textelement_string, textelement_ft_font)
        textelement_textsizeperchar = Makie.attribute_per_char(textelement_string, rscale)
        textelement_colorperchar = collect(Makie.attribute_per_char(textelement_string, color))

        # make emoji placeholders transparent
        for (e, pos) in textelement_emojis
            textelement_colorperchar[pos] = RGBA{Float32}(0,0,0,0)
        end

        append!(fontperchar, textelement_fontperchar)
        append!(textsizeperchar, textelement_textsizeperchar)
        append!(colorperchar, textelement_colorperchar)
    end

    glyphcollection = Makie.glyph_collection(string, fontperchar, textsizeperchar, align[1],
        align[2], lineheight, justification, rot, colorperchar, strokecolor, strokewidth)

    return glyphcollection, emojicollection
end
