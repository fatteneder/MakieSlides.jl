using Pkg
try
  Pkg.instantiate()
catch e
  if e isa AssertionException
    Pkg.resolve()
    Pkg.instantiate()
  else
    rethrow(e)
  end
end
using CairoMakie
using GLMakie
