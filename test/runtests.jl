using Test
using MakieSlides


@testset "Emoji regex pattern" begin
  testcases = [
              #(test text, emoji identifier)
               ("Some text with an :emoji: in it",                  "emoji")
               ("Some text with an :name-with-dashes: in it",       "name-with-dashes")
               ("Some text with an :name-with-numbers-123: in it",  "name-with-numbers-123")
               ("Some text with an :missing-ending-colon in it",    nothing)
               ("Some text with an missing-starting-colon: in it",  nothing)
               ("Some text with a plus in the shorthand :+1:",      "+1")
              ]

  for (text, matched_name) in testcases
    m = match(MakieSlides.RGX_EMOJI, text)
    if isnothing(m)
      @test isnothing(matched_name)
    else
      @test first(m.captures) == matched_name
    end
  end
end
