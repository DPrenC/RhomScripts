-- Casos compartidos con Lua local y Mudlet real.
local suite = {}

local expected = {
  ["comunicaciones.canal_off"] = "Comunicaciones/Canal off.wav",
  ["comunicaciones.canal_on"] = "Comunicaciones/Canal on.wav",
  ["comunicaciones.room"] = "Comunicaciones/room.wav",
  ["ui.abrir_com"] = "UI/Abrir com.wav",
  ["ui.cerrar_com"] = "UI/Cerrar com.wav",
  ["ui.comunicacion_mute"] = "UI/Comunicacion mute.wav",
  ["ui.comunicacion_unmute"] = "UI/Comunicacion unmute.wav",
  ["ui.abrir_config"] = "UI/Abrir config.wav",
  ["ui.cerrar_config"] = "UI/Cerrar config.wav",
  ["ui.abrir_historial"] = "UI/Abrir historial.wav",
  ["ui.cerrar_historial"] = "UI/Cerrar historial.wav",
  ["ui.ir_sala"] = "UI/Ir sala.WAV",
}

local function equal(actual, wanted)
  assert(actual == wanted, "Esperado " .. tostring(wanted) .. ", obtenido " .. tostring(actual))
end

local function write(path)
  local file = assert(io.open(path, "wb"))
  assert(file:write("archivo de prueba sin reproducción"))
  assert(file:close())
end

function suite.run(sonidos, resource_root, profile_root, case)
  case("Sonidos: conserva claves, rutas y grupos migrados sin reproducir", function()
    local original, calls = playSoundFile, 0
    playSoundFile = function(...)
      calls = calls + 1
      return original(...)
    end
    local ok, summary = pcall(sonidos.cargar_catalogo, resource_root)
    playSoundFile = original
    assert(ok, summary)
    equal(calls, 0)
    equal(summary.estado, "cargado")
    local count = 0
    for key, entry in pairs(sonidos.catalogo.sonidos) do
      equal(entry.grupo, key:match("^[^.]+"))
      equal(#entry.archivos, 1)
      count = count + 1
    end
    equal(summary.claves_total, count)
    equal(summary.claves_disponibles, count)
    equal(summary.archivos_correctos, count)
    equal(summary.archivos_erroneos, 0)
    equal(#summary.incidencias, 0)
    for key, relative_path in pairs(expected) do
      local entry = assert(sonidos.catalogo.sonidos[key], "Falta clave " .. key)
      equal(entry.archivos[1], summary.raiz .. "/" .. relative_path)
      local file = assert(io.open(entry.archivos[1], "rb"))
      file:close()
    end
    equal(sonidos.resumen_catalogo, summary)
    assert(summary.mensaje ~= "")
  end)

  local fixture = profile_root .. "/prueba-sonidos"
  local group = fixture .. "/Prueba"
  case("Sonidos: distingue una carpeta ausente de una sin recursos utilizables", function()
    equal(sonidos.cargar_catalogo(fixture).estado, "ausente")
    assert(lfs.mkdir(fixture))
    local summary = sonidos.cargar_catalogo(fixture)
    equal(summary.estado, "invalido")
    assert(#summary.incidencias > 0)
    equal(summary.claves_disponibles, 0)
    assert(lfs.mkdir(group))
    assert(lfs.mkdir(group .. "/Anidados"))
  end)

  case("Sonidos: la recarga detecta altas y bajas e ignora archivos ajenos al catálogo", function()
    write(fixture .. "/Suelto.wav")
    write(group .. "/Anidados/Sonido.wav")
    write(group .. "/Notas.txt")
    write(group .. "/Aviso Prueba.WAV")
    local summary = sonidos.cargar_catalogo(fixture)
    equal(summary.estado, "cargado")
    equal(summary.claves_disponibles, 1)
    local entry = assert(sonidos.catalogo.sonidos["prueba.aviso_prueba"])
    equal(entry.grupo, "prueba")
    equal(entry.archivos[1], group .. "/Aviso Prueba.WAV")
    assert(os.remove(group .. "/Aviso Prueba.WAV"))
    write(group .. "/Nuevo.wav")
    summary = sonidos.cargar_catalogo(fixture)
    equal(summary.claves_disponibles, 1)
    equal(sonidos.catalogo.sonidos["prueba.aviso_prueba"], nil)
    equal(sonidos.catalogo.sonidos["prueba.nuevo"].archivos[1], group .. "/Nuevo.wav")
  end)

  case("Sonidos: las claves en colisión se excluyen y se conservan las demás", function()
    write(group .. "/Aviso Repetido.wav")
    write(group .. "/Aviso_repetido.wav")
    local summary = sonidos.cargar_catalogo(fixture)
    equal(summary.estado, "parcial")
    equal(summary.claves_disponibles, 1)
    equal(sonidos.catalogo.sonidos["prueba.aviso_repetido"], nil)
    assert(sonidos.catalogo.sonidos["prueba.nuevo"])
    assert(table.concat(summary.incidencias, " "):find("prueba.aviso_repetido", 1, true))
  end)

  case("Sonidos: las APIs de archivos ausentes producen error", function()
    for _, api in ipairs({ "dir", "symlinkattributes", "currentdir" }) do
      local original = lfs[api]
      lfs[api] = nil
      local ok, message = pcall(sonidos.cargar_catalogo, api == "currentdir" and "." or resource_root)
      lfs[api] = original
      assert(not ok and tostring(message):find(api, 1, true), "Se ocultó la ausencia de lfs." .. api)
    end
  end)

  sonidos.cargar_catalogo(resource_root)
end

return suite
