# Instructions

1. Instantiate
```sh
julia --project instantiate.jl
```

2. Precompile (this might take some time, around 7 min on my i7-5820K @ 3.30 GHz)
```sh
julia --project precompile.jl
```
If precompilation was successful you should find a file `MakieSys.so` inside this folder.

# Usage

Start Julia using the sysimage
```sh
julia --project -J precompile/MakieSys.so
```
