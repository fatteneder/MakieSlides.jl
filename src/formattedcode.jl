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
        codestyle = :friendly
    )
end


function Makie.plot!(plot::FormattedCode{<:Tuple{<:Markdown.Code}})

    all_styles = Symbol.(collect(pygments_styles.get_all_styles()))

    # attach a function to any text that calculates the glyph syntax highlighting
    # and layout and stores it
    glyphcollection = lift(plot.code, plot.textsize, plot.font, plot.align,
            plot.rotation, plot.justification, plot.lineheight,
            plot.color, plot.strokecolor, plot.strokewidth, plot.codestyle,
            plot.space) do code, ts, f, al, rot, jus, lh, col, scol, swi, style, codestyle

        if !(style in all_styles)
            @warn "Could not find style '$style', using friendly."
            plot.style[] = :default
        end

        ts = to_textsize(ts)
        f = to_font(f)
        rot = to_rotation(rot)
        col = to_color(col)
        scol = to_color(scol)

        layout_code(code, style, ts, f, al, rot, jus, lh, col, scol, swi)
    end

    text_attributes = copy(plot.attributes)
    delete!(text_attributes, :codestyle)
    text!(plot, glyphcollection; text_attributes...)

    plot
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
