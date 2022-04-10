using PackageCompiler

PackageCompiler.create_sysimage(
		[:CairoMakie,:GLMakie],
		sysimage_path=joinpath(@__DIR__, "MakieSys.so"),
		precompile_execution_file=joinpath(@__DIR__, "dummyplot.jl"))
