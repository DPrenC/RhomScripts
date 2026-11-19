-- Infraestructura activa: seis módulos y dependencias de soporte.
-- luacheck: globals print
local suite = {}
local function equal(actual, expected)
  assert(actual == expected, "Esperado " .. tostring(expected) .. "; obtenido " .. tostring(actual))
end
function suite.run(mock)
  local passed = {}
  local function case(name, action)
    action()
    passed[#passed + 1] = name
  end
  local function active_modules()
    local expected = {
      configuracion = true, configurador = true, keys = true, lector = true, comunicaciones = true, ficha = true, debug = true, mapa = true,
    }
    local count = 0
    for name in pairs(RhomScripts.modules) do
      assert(expected[name], "Módulo no migrado conectado: " .. name)
      count = count + 1
    end
    equal(count, 8)
    equal(mock.count(mock.triggers), 2)
    equal(RhomScripts.modules.comunicaciones.cantidad_triggers(), 2)
    equal(mock.count(mock.keys), 40)
    equal(mock.count(mock.aliases), 3)
    assert(not package.loaded.historial)
    assert(package.loaded.config == nil and package.loaded.modes == nil)
    assert(mock.persisted[getMudletHomeDir() .. "/rl_config.lua"] == nil)
  end
  case("Arranque: ocho módulos, cuarenta teclas, tres comandos y dos triggers", function()
    active_modules()
    assert(table.concat(mock.output):find("Carga correcta", 1, true))
  end)
  case("Arranque solicita preparación de ventanas antes de completar", function()
    assert(mock.ui_preparations and mock.ui_preparations > 0)
  end)
  case("Ctrl+F1 registrado alterna la lectura automática de canales", function()
    local callback
    for _, key in pairs(mock.keys) do
      if key.key == mudlet.key.F1 and key.modifiers == mudlet.keymodifier.Control then
        assert(not callback, "Ctrl+F1 duplicado")
        callback = key.action
      end
    end
    assert(callback, "Falta Ctrl+F1")
    local comunicaciones = RhomScripts.modules.comunicaciones
    comunicaciones.reconciliar({ chat = {} }, true)
    assert(callback())
    equal(comunicaciones.estado().canales.chat.silenciado, true)
    equal(mock.announcements[#mock.announcements], "canal global, silenciado.")
    equal(callback(), false)
    equal(comunicaciones.estado().canales.chat.silenciado, false)
    equal(mock.announcements[#mock.announcements], "canal global, lectura activada.")
    comunicaciones.reiniciar()
  end)
  dofile("scripts/tests/catalogo.lua").run(
    RhomScripts.soporte.sonidos, RhomScripts.root .. "/sonidos", TEST_PROFILE_PATH, case)
  dofile("scripts/tests/oficial.lua").run(mock, case)
  dofile("scripts/tests/inicio.lua").run("rhomscripts/init.lua", TEST_PROFILE_PATH .. "/no-existe", case)
  dofile("scripts/tests/configuracion.lua").run(case, "rhomscripts/init.lua")
  dofile("scripts/tests/oficial_configuracion.lua").run(case, "rhomscripts/init.lua", mock)
  dofile("scripts/tests/mapa.lua").run(case, "rhomscripts/mapa.lua", mock)
  dofile("scripts/tests/keys.lua").run("rhomscripts/keys.lua", case)
  dofile("scripts/tests/lector.lua").run(mock, case)
  dofile("scripts/tests/depuracion.lua").run(case, "rhomscripts/init.lua", mock)
  dofile("scripts/tests/estado_arranque.lua").run(case, "rhomscripts/arranque.lua")
  dofile("scripts/tests/comunicaciones.lua").run(case, "rhomscripts/comunicaciones.lua")
  dofile("scripts/tests/ficha.lua").run(case, "rhomscripts/init.lua", function()
    local handlers = {}
    for id, handler in pairs(mock.handlers) do
      if handler.event == "gmcp.Char" then handlers[id] = true end
    end
    return handlers
  end, false)
  case("Estado: rhomscripts estado imprime y anuncia el mismo resumen sin reproducir audio", function()
    local monitor = RhomScripts.soporte.arranque
    local expected = monitor.estado.resumen()
    local sounds, announcements = mock.count(mock.sounds), #mock.announcements
    mock.alias("rhomscripts estado")
    equal(mock.output[#mock.output], expected .. "\n")
    equal(#mock.announcements, announcements + 1)
    equal(mock.announcements[#mock.announcements], expected)
    equal(mock.count(mock.sounds), sounds)
  end)
  case("Audio: combina volumen solicitado, grupo y general sin aplicar opciones futuras", function()
    local audio = RhomScripts.soporte.audio
    local sonidos = RhomScripts.soporte.sonidos
    audio.aplicar_volumenes()
    local options = { volumen = 12, paneo = -80, repeticiones = 3,
      instancia = "prueba", simultaneidad = "ignorar", importancia = "alta" }
    local key = audio.reproducir("ui.boton_1", options)
    local settings = assert(mock.sounds[key])
    equal(settings.name, sonidos.catalogo.sonidos["ui.boton_1"].archivos[1])
    equal(settings.volume, 8)
    equal(settings.pan, nil)
    equal(settings.loops, nil)
    equal(settings.priority, nil)
    equal(settings.tag, audio.default_tag)
    equal(options.repeticiones, 3)
    audio.stop(key)
    equal(mock.sounds[key], nil)
    equal(audio.reproducir("ui.boton_1", { volumen = 0 }), nil)
    equal(mock.sounds[key], nil)
    local borrador = RhomScripts.modules.configurador.nueva_sesion().valores
    borrador.volumen_comunicaciones = 25
    audio.aplicar_volumenes(borrador)
    local communications = audio.reproducir("comunicaciones.chat")
    equal(mock.sounds[communications].volume, 20)
    audio.stop(communications)
    audio.aplicar_volumenes()
    equal(audio.reproducir("ui.no_existe"), nil)
    local saved = sonidos.catalogo
    sonidos.catalogo = nil
    equal(audio.reproducir("ui.boton_1"), nil)
    sonidos.catalogo = saved
    local original = playSoundFile
    playSoundFile = nil
    local ok = pcall(audio.reproducir, "ui.boton_1")
    playSoundFile = original
    assert(not ok, "Se ocultó la API de reproducción ausente")
  end)

  case("Audio: parada por identificador y por etiqueta", function()
    local audio = RhomScripts.soporte.audio
    local first = assert(audio.reproducir("ui.boton_1"))
    local second = assert(audio.reproducir("ui.boton_2"))
    assert(mock.sounds[first] and mock.sounds[second])
    audio.stop(first)
    equal(mock.sounds[first], nil)
    assert(mock.sounds[second])
    audio.stop_tag()
    equal(mock.count(mock.sounds), 0)
  end)

  case("Rhomscripts keys describe la ayuda", function()
    local original, output = echo, {}
    echo = function(text) output[#output + 1] = text end
    local ok, message = pcall(mock.alias, "rhomscripts keys")
    echo = original
    assert(ok, message)
    local found = false
    for _, text in ipairs(output) do
      if text:find("keys.alternar_ayuda", 1, true) then found = true end
    end
    assert(found, "rhomscripts keys no describe la pulsación de ayuda")
  end)
  case("Ausencia de APIs activas se propaga", function()
    local tests = {
      { "announce", function() RhomScripts.modules.keys.establecer_ayuda(true) end },
      { "playSoundFile", function() RhomScripts.soporte.audio.reproducir("ui.boton_1") end },
      { "stopSounds", function() RhomScripts.soporte.audio.stop_tag() end },
      { "getMudletHomeDir", function() RhomScripts.modules.configuracion.path() end },
      { "tempKey", function() RhomScripts.modules.keys.registrar() end },
      { "tempAlias", function() RhomScripts.soporte.aliases.registrar_modulo("ausente", {{ name = "prueba", desc = "API ausente", pattern = "^prueba$", action = function() end }}) end },
    }
    for _, test in ipairs(tests) do
      local original = _G[test[1]]
      _G[test[1]] = nil
      local ok = pcall(test[2])
      _G[test[1]] = original
      assert(not ok, "Se ocultó API ausente: " .. test[1])
    end
    dofile("rhomscripts/init.lua")
  end)
  case("Una API ausente aborta la carga y no emite ready", function()
    local original = tempAlias
    tempAlias = nil
    local before = #mock.events
    local ok = pcall(dofile, "rhomscripts/init.lua")
    tempAlias = original
    equal(ok, false)
    equal(RhomScripts.initialized, false)
    equal(mock.count(mock.triggers), 0)
    for index = before + 1, #mock.events do
      assert(mock.events[index][1] ~= "rhomscripts.ready", "Se anunció éxito tras fallar la carga")
    end
    dofile("rhomscripts/init.lua")
  end)
  case("Fallo del segundo trigger deshace el primero y permite recargar", function()
    local original, calls = tempRegexTrigger, 0
    tempRegexTrigger = function(pattern, action)
      calls = calls + 1
      if calls == 2 then error("Segundo trigger denegado") end
      return original(pattern, action)
    end
    local ok, message = pcall(dofile, "rhomscripts/init.lua")
    tempRegexTrigger = original
    assert(not ok and tostring(message):find("Segundo trigger denegado", 1, true), message)
    equal(mock.count(mock.triggers), 0)
    equal(RhomScripts.modules.comunicaciones.cantidad_triggers(), 0)
    assert(not RhomScripts.initialized)
    dofile("rhomscripts/init.lua")
    active_modules()
  end)
  case("Fallo de limpieza de ventana no impide retirar teclas y aliases", function()
    local configurador = RhomScripts.modules.configurador
    local destroy = configurador.destruir
    configurador.destruir = function() error("Fallo de limpieza de ventana provocado", 0) end
    local before = #mock.events
    local ok, message = pcall(dofile, "rhomscripts/init.lua")
    configurador.destruir = destroy
    assert(not ok and tostring(message):find("Fallo de limpieza de ventana provocado", 1, true))
    assert(tostring(message):find("Errores adicionales de limpieza", 1, true))
    equal(mock.count(mock.keys), 0)
    equal(mock.count(mock.aliases), 1) -- Consultas de diagnóstico conservadas tras fallo.
    equal(mock.count(mock.triggers), 0)
    assert(not RhomScripts.initialized and not RhomScripts.loading)
    for index = before + 1, #mock.events do
      assert(mock.events[index][1] ~= "rhomscripts.ready")
    end
    dofile("rhomscripts/init.lua")
    active_modules()
  end)
  case("Transición retira registros de módulos antiguos sin reactivarlos", function()
    local key = tempKey(mudlet.key.F9, function() error("Tecla antigua activa") end)
    local alias = tempAlias("^pruebaantigua$", function() error("Alias antiguo activo") end)
    local trigger = tempRegexTrigger("^Prueba antigua$", function() error("Trigger antiguo activo") end)
    local current = RhomScripts.modules.keys
    RhomScripts.modules.keys = { desregistrar = function()
      current.desregistrar()
      killKey(key)
    end }
    RhomScripts.modules.aliases = { desregistrar = function() killAlias(alias) end }
    RhomScripts.modules.triggers = { desregistrar = function() killTrigger(trigger) end }
    dofile("rhomscripts/init.lua")
    assert(not mock.keys[key] and not mock.aliases[alias] and not mock.triggers[trigger])
    active_modules()
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
  case("Recarga conserva alcance, retira registros y cambia las instancias", function()
    local old_modules, old_support = RhomScripts.modules, RhomScripts.soporte
    local previous_path = package.path
    local old_triggers = mock.ids(mock.triggers)
    dofile("rhomscripts/init.lua")
    active_modules()
    for _, id in ipairs(old_triggers) do assert(not mock.triggers[id], "Quedó un trigger de la instancia anterior") end
    equal(package.path, previous_path)
    assert(old_modules.keys ~= RhomScripts.modules.keys)
    assert(old_support.audio ~= RhomScripts.soporte.audio)
    assert(old_support.sonidos ~= RhomScripts.soporte.sonidos)
    assert(RhomScripts.initialized)
  end)
  return passed
end
return suite
