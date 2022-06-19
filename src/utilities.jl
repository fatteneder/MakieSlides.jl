# taken from https://discourse.julialang.org/t/how-to-extract-a-file-in-a-zip-archive-without-using-os-specific-tools/34585/5
# might be worth to open a PR at ZipFile, see https://github.com/fhs/ZipFile.jl/issues/74
function unzip(file,exdir="")
  fileFullPath = isabspath(file) ? file : joinpath(pwd(),file)
  basePath = dirname(fileFullPath)
  display(exdir)
  outPath = (exdir == "" ? basePath : (isabspath(exdir) ? exdir : joinpath(pwd(),exdir)))
  isdir(outPath) || mkdir(outPath)
  zarchive = ZipFile.Reader(fileFullPath)
  for f in zarchive.files
    fullFilePath = joinpath(outPath,f.name)
    if (endswith(f.name,"/") || endswith(f.name,"\\"))
      mkdir(fullFilePath)
    else
      write(fullFilePath, read(f))
    end
  end
  close(zarchive)
  return
end
