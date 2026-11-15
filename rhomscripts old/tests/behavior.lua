-- Histórica: dominios desconectados del arranque. No ejecutar como suite activa.
-- Casos observables de infraestructura. Las regex se evalúan con PCRE2.
local suite = {}

local function equal(actual, expected)
  assert(actual == expected, "Esperado " .. tostring(expected) .. "; obtenido " .. tostring(actual))
end

local function last(values) return values[#values] end

function suite.run(mock)
  local passed = {}
  local function case(name, action)
    action()
    passed[#passed + 1] = name
  end

  dofile("scripts/tests/catalogo.lua").run(RhomScripts.modules.audio, "RhomSounds", TEST_PROFILE_PATH, case)

  case("Arranque descubre RhomSounds de desarrollo y escribe un resumen", function()
    equal(RhomScripts.modules.audio.resumen_catalogo.estado, "cargado")
    local summary = RhomScripts.modules.audio.resumen_catalogo
    local expected = summary.claves_disponibles .. " claves sonoras y " .. summary.archivos_correctos .. " archivos"
    local summary_found = false
    for _, message in ipairs(mock.output) do
      if message:find("RhomSounds", 1, true) and message:find(expected, 1, true) then summary_found = true end
    end
    assert(summary_found, "No se mostró resumen accesible de RhomSounds")
  end)

  dofile("scripts/tests/oficial.lua").run(mock, case)

  dofile("scripts/tests/inicio.lua").run("rhomscripts/init.lua", TEST_PROFILE_PATH .. "/no-existe", case)

  dofile("scripts/tests/configuracion.lua").run(case, "rhomscripts/init.lua")
  dofile("scripts/tests/keys.lua").run("rhomscripts/keys.lua", case)
  dofile("scripts/tests/oficial_configuracion.lua").run(case, "rhomscripts/init.lua", mock)

  case("Lectura y copia desde buffer sin atajos antiguos", function()
    mock.buffer = { "primera linea", "segunda linea", "tercera linea" }
    RhomScripts.modules.lector.leer_linea(1)
    equal(last(mock.announcements), "tercera linea")
    RhomScripts.modules.lector.copiar_linea(2)
    equal(mock.clipboard, "segunda linea")
    equal(last(mock.announcements), "Linea copiada")
  end)

  case("Alias PCRE con capturas lee el índice solicitado", function()
    mock.alias("leerlinea 2")
    equal(last(mock.announcements), "segunda linea")
  end)

  case("Configurar ficha conserva las decisiones de servicios oficiales", function()
    local before = #mock.sends
    mock.alias("configurarficha")
    assert(#mock.sends > before)
    for index = before + 1, #mock.sends do
      local command = mock.sends[index]:lower()
      assert(not command:find("consentir gmcp", 1, true))
      assert(not command:find("consentir mudlet_gui", 1, true))
      assert(not command:find("consentir msp", 1, true))
    end
  end)

  case("Trigger PCRE captura el texto completo en el historial", function()
    feedTriggers("Mensaje de muestra sin eventos del juego\n")
    equal(RhomScripts.modules.historial.cache[1], "Mensaje de muestra sin eventos del juego")
  end)

  case("feedTriggers usa el trigger real de diagnóstico", function()
    local before = #mock.output
    RhomScripts.modules.pruebas.test_trigger("esto es una prueba de triggers")
    local found = false
    for index = before + 1, #mock.output do
      if mock.output[index]:find("PRUEBA DETECTADA", 1, true) then found = true end
    end
    assert(found, "No se ejecutó el trigger de prueba")
  end)

  case("Lista: anuncios ordenados, límites circulares y copia", function()
    local listas = RhomScripts.modules.listas
    listas.nueva("Prueba")
    equal(last(mock.announcements), "Lista Prueba")
    listas.agregar("Prueba", "Espada")
    listas.agregar("Prueba", "Escudo")
    listas.leer_actual()
    equal(last(mock.announcements), "1 de 2. Espada")
    listas.anterior()
    equal(last(mock.announcements), "2 de 2. Escudo")
    listas.siguiente()
    equal(last(mock.announcements), "1 de 2. Espada")
    listas.copiar_actual()
    equal(mock.clipboard, "Espada")
    listas.limpiar()
    listas.leer_actual()
    equal(last(mock.announcements), "No hay ninguna lista disponible")
  end)

  case("Audio: reproducción por clave sin aplicar opciones futuras", function()
    local audio = RhomScripts.modules.audio
    local options = { volumen = 12, paneo = -80, repeticiones = 3, grupo = "interfaz",
      instancia = "prueba", simultaneidad = "ignorar", importancia = "alta" }
    local key = audio.reproducir("ui.boton", options)
    local settings = assert(mock.sounds[key])
    equal(settings.name, audio.catalogo.sonidos["ui.boton"].archivos[1])
    equal(settings.volume, nil)
    equal(settings.pan, nil)
    equal(settings.loops, nil)
    equal(settings.priority, nil)
    equal(settings.tag, audio.default_tag)
    equal(options.repeticiones, 3)
    audio.stop(key)
    equal(mock.sounds[key], nil)
    equal(audio.reproducir("ui.no_existe"), nil)
    local saved = audio.catalogo
    audio.catalogo = nil
    equal(audio.reproducir("ui.boton"), nil)
    audio.catalogo = saved
    local original = playSoundFile
    playSoundFile = nil
    local ok = pcall(audio.reproducir, "ui.boton")
    playSoundFile = original
    assert(not ok, "Se ocultó la API de reproducción ausente")
  end)

  case("Audio: paneo oficial, mono, bucle y parada por clave", function()
    local audio = RhomScripts.modules.audio
    audio.set_mono(false)
    audio.play_pan("RL/Generales/Error.wav", -2500, { volume = 75, key = "test:pan" })
    equal(mock.sounds["test:pan"].pan, -50)
    equal(mock.sounds["test:pan"].volume, 75)
    audio.set_mono(true)
    audio.loop("RL/Generales/Error.wav", { key = "test:loop", pan = 80 })
    equal(mock.sounds["test:loop"].pan, 0)
    equal(mock.sounds["test:loop"].loops, -1)
    audio.stop("test:loop")
    equal(mock.sounds["test:loop"], nil)
    assert(mock.sounds["test:pan"])
    audio.stop_tag()
    equal(mock.count(mock.sounds), 0)
    audio.set_mono(false)
  end)

  case("Persistencia: ruta de perfil y firmas table.save/load", function()
    local config = RhomScripts.modules.config
    config.set("prueba_persistencia", "valor")
    config.data = {}
    config.load()
    equal(config.get("prueba_persistencia"), "valor")
    assert(mock.persisted[getMudletHomeDir() .. "/rl_config.lua"])
  end)

  case("Movimiento envía la dirección sin atajo antiguo", function()
    RhomScripts.modules.movimiento.mover("n", false)
    equal(last(mock.sends), "n")
  end)

  case("Teclas desconocidas y APIs inexistentes producen error", function()
    local ok = pcall(function() return mudlet.key.TeclaInventada end)
    equal(ok, false)
    equal(rawget(_G, "setSoundPan"), nil)
    equal(rawget(_G, "loadTable"), nil)
    equal(rawget(_G, "saveTable"), nil)
  end)

  local function group_event()
    local text = "Has creado tu propio grupo."
    local eventos = RhomScripts.modules.eventos
    eventos.historial = {}
    eventos.ultimo = ""
    feedTriggers(text .. "\n")
    equal(eventos.ultimo, text)
    equal(#eventos.historial, 1)
    RhomScripts.modules.lector.decir(eventos.ultimo)
    equal(last(mock.announcements), text)
    eventos.mostrar_historial()
    equal(last(mock.announcements), "1 de 1. " .. text)
  end

  case("Evento de grupo visible y lectura por funciones de dominio", group_event)

  case("La ausencia de cada API usada no se oculta", function()
    local tests = {
      { "announce", function() RhomScripts.modules.lector.decir("prueba") end },
      { "setClipboardText", function() RhomScripts.modules.lector.copiar("prueba") end },
      { "playSoundFile", function() RhomScripts.modules.audio.play("RL/Generales/Error.wav") end },
      { "stopSounds", function() RhomScripts.modules.audio.stop_tag() end },
      { "feedTriggers", function() RhomScripts.modules.pruebas.test_trigger("prueba") end },
      { "getLines", function() RhomScripts.modules.historial.ultima_linea(1) end },
      { "getMudletHomeDir", function() RhomScripts.modules.config.save() end },
      { "tempKey", function() RhomScripts.modules.keys.registrar() end },
      { "tempAlias", function() RhomScripts.modules.aliases.registrar() end },
      { "tempRegexTrigger", function() RhomScripts.modules.triggers.registrar() end },
    }
    for _, test in ipairs(tests) do
      local original = _G[test[1]]
      _G[test[1]] = nil
      local ok = pcall(test[2])
      _G[test[1]] = original
      assert(not ok, "Se ocultó API ausente: " .. test[1])
    end
    for _, name in ipairs({ "save", "load" }) do
      local original = table[name]
      rawset(table, name, nil)
      local ok = pcall(RhomScripts.modules.config[name])
      rawset(table, name, original)
      assert(not ok, "Se ocultó table." .. name)
    end
  end)

  case("Una API ausente aborta la carga y no emite ready", function()
    local original = tempAlias
    tempAlias = nil
    local before = #mock.events
    local ok = pcall(dofile, "rhomscripts/init.lua")
    tempAlias = original
    equal(ok, false)
    equal(RhomScripts.initialized, false)
    for index = before + 1, #mock.events do
      assert(mock.events[index][1] ~= "rhomscripts.ready", "Se anunció éxito tras fallar la carga")
    end
  end)

  case("Una sesión antigua exige reinicio antes de registrar nada", function()
    local saved = RhomScripts
    RhomScripts = { modules = { keys = { desregistrar = function() error("No debe ejecutarse") end } } }
    local before = mock.count(mock.keys)
    local ok, message = pcall(dofile, "rhomscripts/init.lua")
    RhomScripts = saved
    equal(ok, false)
    assert(tostring(message):find("cerrar y reabrir", 1, true))
    equal(mock.count(mock.keys), before)
  end)

  case("Carga repetida sin duplicar registros ni package.path", function()
    -- Los ensayos de API ausente retiraron registros antes del error.
    dofile("rhomscripts/init.lua")
    local counts = { mock.count(mock.keys), mock.count(mock.aliases), mock.count(mock.triggers), mock.count(mock.handlers) }
    local previous_path = package.path
    local previous_modules = RhomScripts.modules
    dofile("rhomscripts/init.lua")
    equal(mock.count(mock.keys), counts[1])
    equal(mock.count(mock.aliases), counts[2])
    equal(mock.count(mock.triggers), counts[3])
    equal(mock.count(mock.handlers), counts[4])
    equal(package.path, previous_path)
    assert(previous_modules.lector ~= RhomScripts.modules.lector)
    assert(RhomScripts.initialized)
    mock.buffer = { "después de recargar" }
    RhomScripts.modules.lector.leer_linea(1)
    equal(last(mock.announcements), "después de recargar")
  end)

  case("Evento de grupo sigue visible después de recargar", group_event)

  return passed
end

return suite
