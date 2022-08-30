"""
    formattedcode(code::Markdown.Code)

Plots syntax highlighted code.
"""
@recipe(FormattedCode, code) do scene
    Attributes(;
        default_theme(scene)...,
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
        pygstyler = pygments_styles.get_style_by_name("friendly"),
        pyglexer = pygments_lexers.get_lexer_by_name("julia"),
        maxwidth = 0.0
    )
end


function Makie.plot!(plot::FormattedCode{<:Tuple{<:Markdown.Code}})
    code, lang = plot.code[].code, plot.code[].language
    all_lexers = lowercase.(first.(collect(pygments_lexers.get_all_lexers())))
    if !(lang in all_lexers)
        @warn "Language '$lang' not supported, using julia."
        lang = :julia
    end
    pyglexer = pygments_lexers.get_lexer_by_name(lang)
    attrs = plot.attributes
    attrs[:pyglexer] = pyglexer
    formattedcode!(plot, code; attrs...)
end


function Makie.plot!(plot::FormattedCode{<:Tuple{<:AbstractString}})

    default_textsize = plot.textsize[]

    glyphcollection = lift(plot.code, plot.pygstyler, plot.pyglexer,
            plot.textsize, plot.font, plot.align,
            plot.rotation, plot.justification, plot.lineheight, plot.strokecolor,
            plot.strokewidth) do code, styler, lexer, ts, f, al, rot, jus, lh, scol, swi

        ts = to_textsize(ts)
        f = to_font(f)
        rot = to_rotation(rot)
        scol = to_color(scol)

        layout_code(code, styler, lexer, ts, f, al, rot, jus, lh, scol, swi)
    end

    # For codeblocks we don't want automatic line wrapping. Instead we adjust
    # the font size such that the boundingbox's width is smaller than plot.maxwidth.
    prev_maxwidth = 0.0
    onany(glyphcollection, plot.maxwidth) do glc, maxwidth

        (maxwidth <= 0.0 || prev_maxwidth == maxwidth) && return

        w = estimate_width(glyphcollection[])
        grad_maxwidth = maxwidth - prev_maxwidth
        prev_maxwidth = maxwidth
        if grad_maxwidth < 0 && w > maxwidth && plot.textsize[] - 1 > 0
            plot.textsize[] -= 1
        elseif grad_maxwidth > 0 && w < maxwidth && plot.textsize[] + 1 <= default_textsize
            plot.textsize[] += 1
        end
    end

    text_attributes = copy(plot.attributes)
    delete!(text_attributes, :pygstyler)
    delete!(text_attributes, :pyglexer)
    text!(plot, glyphcollection; text_attributes...)

    plot
end


function estimate_width(glyphcollection)
    max_w, w = 0.0, 0.0
    glyphs, glyphbbs = glyphcollection.glyphs, gl_bboxes(glyphcollection)
    for (g, bb) in zip(glyphs, glyphbbs)
        w += width(bb)
        if g == '\n'
            max_w = max(max_w, w)
            w = 0.0
        end
    end
    max_w = max(max_w, w)
    return max_w
end


"""
    layout_code(
        string::AbstractString, textsize::Union{AbstractVector, Number},
        font, align, rotation, justification, lineheight
    )

Compute a GlyphCollection for a `string` given textsize, font, align, rotation, model, 
justification, and lineheight.
"""
function layout_code(
        code, pygstyler, pyglexer, textsize::Union{AbstractVector, Number},
        font, align, rotation, justification, lineheight, strokecolor, strokewidth
    )

    rscale = to_textsize(textsize)
    rot    = to_rotation(rotation)

    glyph_string    = ""
    fontperchar     = Any[]
    textsizeperchar = Any[]
    colorperchar    = Any[]

    tokens     = pyglexer.get_tokens(code)
    for (token, token_string) in tokens
        token_pygstyle = pygstyler.style_for_token(token)
        color          = color_from_pygstyle(token_pygstyle)
        ft_font        = font_from_pygstyle(token_pygstyle, font)

        token_fontperchar  = attribute_per_char(token_string, ft_font)
        token_sizeperchar  = attribute_per_char(token_string, rscale)
        token_colorperchar = attribute_per_char(token_string, color)

        glyph_string *= token_string

        append!(fontperchar, token_fontperchar)
        append!(textsizeperchar, token_sizeperchar)
        append!(colorperchar, token_colorperchar)
    end
    
    word_wrap_width = -1 # deactivate line wrapping
    glyphcollection = glyph_collection(
        glyph_string, fontperchar, textsizeperchar, align[1], align[2],
        lineheight, justification, rot, colorperchar, strokecolor, strokewidth, word_wrap_width
    )

    return glyphcollection
end


const PYGMENTS_ANSICOLORS = Dict(
    "ansiblack"         => "black",
    "ansired"           => "red",
    "ansigreen"         => "green",
    "ansiyellow"        => "yellow",
    "ansiblue"          => "blue",
    "ansimagenta"       => "magenta",
    "ansicyan"          => "cyan",
    "ansigray"          => "gray",
    "ansibrightblack"   => "brightblack",
    "ansibrightred"     => "brightred",
    "ansibrightgreen"   => "brighgreen",
    "ansibrightyellow"  => "brightyellow",
    "ansibrightblue"    => "brightblue",
    "ansibrightmagenta" => "brightmagenta",
    "ansibrightcyan"    => "brightcyan",
    "ansiwhite"         => "white"
    )


function color_from_pygstyle(pygstyle)
    rgbcolor = if !isnothing(pygstyle["color"])
        parse(RGBAf, "#$(pygstyle["color"])")
    elseif !isnothing(pygstyle["ansicolor"])
        parse(RGBAf, PYGMENTS_ANSICOLORS[pygstyle["ansicolor"]])
    else
        RGBAf(0.0,0.0,0.0,1.0) # default to black if no color is provided
    end
    return rgbcolor
end


function font_from_pygstyle(pygstyle, basefont::Makie.FreeTypeAbstraction.FTFont)
    # unused font attributes
    # pygstyle["roman"],
    # pygstyle["sans"],
    # pygstyle["mono"],
    # pygstyle["underline"] ]
    guess_font_name = string(basefont.family_name)
    guess_font_name *= pygstyle["bold"] ? " bold" : ""
    guess_font_name *= pygstyle["italic"] ? " italic" : ""
    to_font(guess_font_name)
end
