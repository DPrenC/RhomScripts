-- Casos compartidos: doble local y APIs reales de Mudlet, siempre desconectado.
-- luacheck: globals require raiseEvent
local suite = {}

function suite.run(init_path, missing_root, case)
  local function load(options)
    options = options or {}
    local original_require = require
    local original_play = playSoundFile
    local original_raise, ready = raiseEvent, 0
    raiseEvent = function(event, ...)
      if event == "rhomscripts.ready" then ready = ready + 1 end
      return original_raise(event, ...)
    end
    local calls = {}
    local communications
    local native_calls = 0
    local native_volume
    require = function(name)
      if name == options.fail_module then error("Fallo de módulo provocado: " .. name) end
      local module = original_require(name)
      if name == "comunicaciones" then communications = module end
      if name == "ui" and options.fail_ventanas then
        module.preparar = function() error("Fallo de preparación de ventanas provocado") end
      end
      if name == "arranque" and options.fail_bibliotecas then
        module.bibliotecas = function() error("Fallo de biblioteca provocado") end
      end
      if name == "audio" and not module.startup_test_wrapped then
        module.startup_test_wrapped = true
        local reproduce = module.reproducir
        module.reproducir = function(key, settings)
          calls[#calls + 1] = key
          return reproduce(key, settings)
        end
        if options.missing_sounds then
          local start = module.iniciar
          module.iniciar = function() return start(missing_root) end
        end
      end
      return module
    end
    if options.missing_api then
      playSoundFile = nil
    else
      playSoundFile = function(settings)
        native_calls = native_calls + 1
        native_volume = settings.volume
        return original_play(settings)
      end
    end
    local ok, message = pcall(dofile, init_path)
    require = original_require
    playSoundFile = original_play
    raiseEvent = original_raise
    return ok, message, calls, native_calls, ready, communications, native_volume
  end

  case("Inicio: éxito solicita solo carga correcta en UI", function()
    local ok, message, calls, native_calls = load()
    assert(ok, message)
    assert(RhomScripts.initialized)
    assert(#calls == 1 and calls[1] == "ui.carga_ok")
    assert(native_calls == 1, "El aviso no llegó al reproductor")
  end)

  case("Inicio: la recarga usa volúmenes persistidos antes del aviso", function()
    local config = RhomScripts.modules.configuracion
    local general, interfaz = config.get("volumen_general"), config.get("volumen_interfaz")
    config.set("volumen_general", 40)
    config.set("volumen_interfaz", 25)
    assert(config.save())
    local ok, message, _, native_calls, _, _, volume = load()
    local reloaded = require("configuracion")
    reloaded.set("volumen_general", general)
    reloaded.set("volumen_interfaz", interfaz)
    assert(reloaded.save())
    assert(ok, message)
    assert(native_calls == 1 and volume == 10, "El aviso no tomó los volúmenes guardados")
  end)

  case("Inicio: errores de módulos tempranos y tardíos conservan error y avisan en UI", function()
    for _, name in ipairs({ "configurador", "comunicaciones", "keys" }) do
      local ok, message, calls, native_calls = load({ fail_module = name })
      assert(not ok and tostring(message):find("Fallo de módulo provocado: " .. name, 1, true))
      assert(not RhomScripts.initialized)
      assert(#calls == 1 and calls[1] == "ui.carga_erronea")
      assert(native_calls == 1)
    end
  end)

  case("Inicio: sin carpeta de sonidos carga correctamente y no reproduce error", function()
    local ok, message, calls, native_calls = load({ missing_sounds = true })
    assert(ok, message)
    assert(RhomScripts.initialized)
    assert(RhomScripts.soporte.sonidos.resumen_catalogo.estado == "ausente")
    assert(#calls == 1 and calls[1] == "ui.carga_ok")
    assert(native_calls == 0)
  end)

  case("Inicio: fallo de módulo sin carpeta de sonidos conserva el error original", function()
    local ok, message, calls, native_calls = load({ missing_sounds = true, fail_module = "keys" })
    assert(not ok and tostring(message):find("Fallo de módulo provocado: keys", 1, true))
    assert(not RhomScripts.initialized)
    assert(#calls == 1 and calls[1] == "ui.carga_erronea")
    assert(native_calls == 0)
  end)

  case("Inicio: fallo de bibliotecas impide registrar módulos y no anuncia éxito", function()
    local ok, message, calls, native_calls = load({ fail_bibliotecas = true })
    assert(not ok and tostring(message):find("Fallo de biblioteca provocado", 1, true))
    assert(not RhomScripts.initialized and not RhomScripts.loading)
    assert(not RhomScripts.modules.configurador and not RhomScripts.modules.keys)
    assert(#calls == 0 and native_calls == 0, "Se reprodujo audio sin completar preparación")
    local control = RhomScripts.arranque_oficial
    assert(control.estado == "error")
    assert(next(control.handlers) == nil and next(control.temporizadores) == nil)
  end)

  case("Inicio: fallo preparando ventanas impide ready y propaga el error", function()
    local ok, message, _, _, ready, communications = load({ fail_ventanas = true })
    assert(not ok and tostring(message):find("Fallo de preparación de ventanas provocado", 1, true))
    assert(ready == 0, "Se anunció ready sin ventanas preparadas")
    assert(communications and not communications.iniciado, "Quedaron manejadores de comunicaciones tras fallo")
    assert(not RhomScripts.initialized and not RhomScripts.loading)
  end)

  case("Inicio: API de audio ausente propaga el error", function()
    local ok, message = load({ missing_api = true })
    assert(not ok and tostring(message):find("playSoundFile", 1, true))
    assert(not RhomScripts.initialized)
  end)

  -- Dejar una instancia nueva sin instrumentación para el resto de pruebas.
  dofile(init_path)
end

return suite
