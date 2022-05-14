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
        inspectable = theme(scene, :inspectable)
    )
end


function Makie.plot!(plot::FormattedCode{<:Tuple{<:Markdown.Code}})

    md_code = plot[:code]

    # attach a function to any text that calculates the glyph syntax highlighting
    # and layout and stores it
    glyphcollection = lift(md_code, plot.textsize, plot.font, plot.align,
            plot.rotation, plot.justification, plot.lineheight,
            plot.color, plot.strokecolor, plot.strokewidth) do code,
                ts, f, al, rot, jus, lh, col, scol, swi

        ts = to_textsize(ts)
        f = to_font(f)
        rot = to_rotation(rot)
        col = to_color(col)
        scol = to_color(scol)

        layout_code(code, ts, f, al, rot, jus, lh, col, scol, swi)
    end

    text!(plot, glyphcollection; plot.attributes...)

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
        md_code::Markdown.Code, textsize::Union{AbstractVector, Number},
        font, align, rotation, justification, lineheight, color, strokecolor, strokewidth
    )

    rscale = to_textsize(textsize)
    rot = to_rotation(rotation)

    string = ""
    fontperchar = Any[]
    textsizeperchar = Any[]
    colorperchar = Any[]

    code, lang = md_code.code, md_code.language
    lexer = pygments_lexers.get_lexer_by_name(lang)
    style = pygments_styles.get_style_by_name("gruvbox-light")
    tokens = lexer.get_tokens(code)
    for (token, token_string) in tokens
        token_style = style.style_for_token(token)
        color       = color_from_style(token_style)
        ft_font     = font_from_style(token_style)

        token_fontperchar  = attribute_per_char(token_string, ft_font)
        token_sizeperchar  = attribute_per_char(token_string, rscale)
        token_colorperchar = attribute_per_char(token_string, color)

        string *= token_string

        append!(fontperchar, token_fontperchar)
        append!(textsizeperchar, token_sizeperchar)
        append!(colorperchar, token_colorperchar)
    end

    glyphcollection = glyph_collection(
        string, fontperchar, textsizeperchar, align[1], align[2], 
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


function color_from_style(style)
    rgbcolor = if !isnothing(style["color"])
        parse(RGBAf, "#$(style["color"])")
    elseif !isnothing(style["ansicolor"])
        parse(RGBAf, PYGMENTS_ANSICOLORS[style["ansicolor"]])
    else
        RGBAf(0.0,0.0,0.0,1.0) # default black to black if no color is provided
    end
    return rgbcolor
end


function font_from_style(style)
    # unused font attributes so far
    # style["roman"],
    # style["sans"],
    # style["mono"],
    # style["underline"] ]
    guess_font_name = ""
    guess_font_name *= style["bold"] ? " bold" : ""
    guess_font_name *= style["italic"] ? " italic" : ""
    to_font(guess_font_name)
end
