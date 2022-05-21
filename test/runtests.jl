using Test


@testset "Emoji regex pattern" begin
  testcases = [
              #(test text, emoji identifier)
               ("Some text with an :emoji: in it",                  "emoji")
               ("Some text with an :name_with_underscores: in it",  "name_with_underscores")
               ("Some text with an :name-with-dashes: in it",       "name-with-dashes")
               ("Some text with an :name_with-numbers-123: in it",  "name_with-numbers-123")
               ("Some text with an :missing_ending_colon in it",    nothing)
               ("Some text with an missing_starting_colon: in it",  nothing)
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
