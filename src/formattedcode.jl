"""
    formattedcode(code::Markdown.Code)

Plots syntax highlighted code.
"""
@recipe(FormattedCode, code) do scene
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
        codestyle = :friendly,
        maxwidth = 0.0
    )
end


function Makie.plot!(plot::FormattedCode{<:Tuple{<:Markdown.Code}})

    all_styles = Symbol.(collect(pygments_styles.get_all_styles()))
    default_textsize = plot.textsize[]

    # For codeblocks we don't want automatic line wrapping. Instead we adjust
    # the font size such that the boundingbox's width is smaller than plot.maxwidth.
    # We iteratively shrink it starting from plot.textsize.
    settled_on_textsize = false

    glyphcollection = lift(plot.code, plot.codestyle, plot.textsize, plot.font, plot.align,
            plot.rotation, plot.justification, plot.lineheight, plot.color, plot.strokecolor,
            plot.strokewidth) do code, codestyle, ts, f, al, rot, jus, lh, col, scol, swi

        if !(codestyle in all_styles)
            @warn "Could not find style '$codestyle', using friendly."
            plot.style[] = :friendly
        end

        if settled_on_textsize
            # any update requires us to restart the textsize iteration
            settled_on_textsize = false
            plot.textsize[] = default_textsize
        end

        ts = to_textsize(ts)
        f = to_font(f)
        rot = to_rotation(rot)
        col = to_color(col)
        scol = to_color(scol)

        layout_code(code, codestyle, ts, f, al, rot, jus, lh, col, scol, swi)
    end

    onany(glyphcollection, plot.maxwidth) do glc, maxwidth
        if maxwidth > 0.0
            w = estimate_width(glyphcollection[])
            if w > maxwidth
                ts = plot.textsize[] - 1
                ts <= 0 && @warn "FormattedCode: Cannot shrink font size any further."
                plot.textsize[] = ts
            else
                settled_on_textsize = true
            end
        end
    end

    notify(plot.maxwidth)

    text_attributes = copy(plot.attributes)
    delete!(text_attributes, :codestyle)
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
        md_code::Markdown.Code, style, textsize::Union{AbstractVector, Number},
        font, align, rotation, justification, lineheight, color, strokecolor, strokewidth
    )

    rscale = to_textsize(textsize)
    rot    = to_rotation(rotation)

    glyph_string    = ""
    fontperchar     = Any[]
    textsizeperchar = Any[]
    colorperchar    = Any[]

    code, lang = md_code.code, md_code.language
    pylexer    = pygments_lexers.get_lexer_by_name(lang)
    pygstyler  = pygments_styles.get_style_by_name(string(style))
    tokens     = pylexer.get_tokens(code)
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

    glyphcollection = glyph_collection(
        glyph_string, fontperchar, textsizeperchar, align[1], align[2],
        lineheight, justification, rot, colorperchar, strokecolor, strokewidth
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
    # unused font attributes so far
    # pygstyle["roman"],
    # pygstyle["sans"],
    # pygstyle["mono"],
    # pygstyle["underline"] ]
    guess_font_name = string(basefont.family_name)
    guess_font_name *= pygstyle["bold"] ? " bold" : ""
    guess_font_name *= pygstyle["italic"] ? " italic" : ""
    to_font(guess_font_name)
end
