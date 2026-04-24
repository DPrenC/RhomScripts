if RhomLoader and RhomLoader.reload then
  RhomLoader.reload()
else
  if cecho then
    cecho("<red>[RhomLoader] No está cargado (falta RhomLoader.reload)\n")
  else
    print("[RhomLoader] No está cargado (falta RhomLoader.reload)")
  end
end
