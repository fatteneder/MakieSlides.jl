"""
    text(text::Markdown.MD)

Plots `Markdown` formatted text.

"""
@recipe(FormattedText, text) do scene
    Attributes(;
        default_theme(scene)...,
        color = theme(scene, :textcolor),
        font = theme(scene, :font),
        emojifont = Makie.to_font("OpenMoji"),
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


Makie.convert_attribute(f, ::Makie.key"emojifont") = Makie.convert_attribute(f, Makie.key"font"())

# convert strings to Markdown.MD
function Makie.convert_arguments(::Type{<: FormattedText}, str::AbstractString)
    return (Markdown.parse(str),)
end

function Makie.convert_arguments(::Type{<: FormattedText}, markdown:Markdown.MD)

    ###
    # Notes:
    # - literals (`...`) and code blocks (```...```) are both wrapped as Markdown.Code.
    # It think the way to distinguish them is to check whether one appears within the contents
    # of a Markdown.Paragraph (=^= literal) or Markdown.MD(=^= code block).

    all_elements = Any[]
    for (index, element) in enumerate(markdown.content)
        if !(element isa Markdown.Paragraph)
            error("Cannot format markdown element '$element'")
        end
        append!(all_elements, element.content)
        index < length(markdown.content) && push!(all_elements, "\n")
    end

    one_paragraph = Markdown.Paragraph(all_elements)
    
    return (one_paragraph,)
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
    onany(text_elements_fonts, plot.emojifont, plot.textsize, plot.align, plot.rotation, 
          plot.justification, plot.lineheight, plot.color, plot.strokecolor, plot.strokewidth, 
          plot.word_wrap_width) do elements_fonts, emojifont, ts, al, rot, jus, lh, col, scol, swi, www

        ts = to_textsize(ts)
        rot = to_rotation(rot)
        col = to_color(col)
        scol = to_color(scol)

        glc, emc = layout_formatted_text(elements_fonts, emojifont, ts, al, rot, jus, lh, col, scol, swi, www)
        glyphcollection[] = glc
        emojicollection[] = emc
    end

    # render text
    notify(plot.text)
    textplot = text!(plot, glyphcollection; plot.attributes...)

    # determine which emojis to load and where to place them
    emoji_positions = Observable{Vector{Point2f}}(Point2f[(0,0)])
    emoji_images    = Observable{Vector{Matrix{RGBAf}}}(Matrix{RGBAf}[rand(RGBAf, 1,1)])
    emoji_sizes     = Observable{Vector{Vec2f}}(Vec2f[(0,0)])
    emoji_offsets   = Observable{Vector{Vec2f}}(Vec2f[(0,0)])
    onany(emojicollection, plot.align) do ec, align
        empty!(emoji_positions.val)
        empty!(emoji_images.val)
        empty!(emoji_sizes.val)
        empty!(emoji_offsets.val)
        sizehint!(emoji_positions.val, length(ec))
        sizehint!(emoji_images.val, length(ec))
        sizehint!(emoji_sizes.val, length(ec))
        sizehint!(emoji_offsets.val, length(ec))

        anchor = Point2f(plot.position[])
        gc = glyphcollection[]

        for (shorthand, pos) in ec
            glyph_bb, extent = Makie.FreeTypeAbstraction.metrics_bb(
                gc.glyphs[pos], gc.fonts[pos], gc.scales[pos])

            scaled_pad = EMOJIS_PADDING * gc.scales[pos] / EMOJIS_SIZE
            push!(emoji_positions.val, Point2f(gc.origins[pos]) + anchor)
            push!(emoji_images.val, load_emoji_image(shorthand))
            push!(emoji_sizes.val, widths(glyph_bb) + 2scaled_pad)
            push!(emoji_offsets.val, minimum(glyph_bb) - scaled_pad)
        end

        notify(emoji_positions)
        notify(emoji_images)
        notify(emoji_sizes)
        notify(emoji_offsets)
    end

    # place emojis
    notify(emojicollection)
    if length(emojicollection[]) > 0
        scatter!(plot, emoji_positions;
            marker = emoji_images, markersize = emoji_sizes, space = plot.space,
            markerspace = plot.markerspace, marker_offset = emoji_offsets)
    end

    plot
end

# Don't draw the emoji scatter in CairoMakie, since it should be able to render the text directly.
# Unfortunately, Cairo does not draw emojis with colour, so we should draw PNGs (or perhaps SVGs) instead!
# This could be used as a hook in which to do the SVG drawing.
# CairoMakie.draw_plot(scene::Scene, screen::CairoMakie.CairoScreen, txt::T) where T <: FormattedText = CairoMakie.draw_atomic(scene, screen, txt.plots[1])


function Makie.convert_arguments(::Type{<: FormattedText}, md::Union{Markdown.Admonition, 
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
                                                         Markdown.Table})
    error("plot! method for `FormattedText` not implemented for argument type '$(md)'")
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
        emojifont::Makie.FreeTypeAbstraction.FTFont,
        textsize::Union{AbstractVector, Number}, align, rotation, justification, lineheight,
        color, strokecolor, strokewidth, word_wrap_width
    )

    rscale = to_textsize(textsize)
    rot = to_rotation(rotation)

    text = ""
    fontperchar = Any[]
    textsizeperchar = Any[]
    colorperchar = Any[]
    emojicollection = Tuple{String,Int64}[] # (shorthand, char index in text)
    scanned_chars = 0
    for (element, font) in text_elements_fonts

        # query shorthands and replace them with a placeholder character
        # later we plot the actual emoji ontop of the placeholder
        element_emojis = Tuple{String,Int64}[]
        m = match(RGX_EMOJI, element)
        while !isnothing(m)
            e = first(m.captures)
            placeholder_e = '\UFFFD'
            pos_lhs_colon = prevind(element, m.offset)
            pos_rhs_colon = nextind(element, m.offset+ncodeunits(e)+1)
            element = element[begin:pos_lhs_colon] * "$placeholder_e" * element[pos_rhs_colon:end]
            isunknown = !(e in keys(EMOJIS_MAP))
            !isunknown && push!(element_emojis, (e, scanned_chars+length(element[begin:m.offset])))
            m = match(RGX_EMOJI, element)
        end
        append!(emojicollection, element_emojis)

        scanned_chars += length(element)
        text = text * element

        element_fontperchar = Makie.attribute_per_char(element, font)
        element_textsizeperchar = Makie.attribute_per_char(element, rscale)
        element_colorperchar = collect(Makie.attribute_per_char(element, color))

        # make emoji placeholders transparent
        for (_, pos) in element_emojis
            element_colorperchar[pos] = RGBA{Float32}(0,0,0,0)
            element_fontperchar[pos] = emojifont
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
