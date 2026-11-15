-- Preferencias oficiales: misma suite con dobles y con el paquete real, offline.
-- luacheck: globals RL_gui_reinicializar RL_salvar_opciones
local suite = {}
local function equal(actual, expected)
  assert(actual == expected, "Esperado " .. tostring(expected) .. "; obtenido " .. tostring(actual))
end

function suite.run(case, init_path, mock)
  local config = RhomScripts.modules.configuracion
  local oficial = require("arranque")
  local function save_apply()
    assert(config.save())
    return oficial.aplicar_configuracion(config)
  end
  local function defaults()
    config.reset()
    return save_apply()
  end
  local function pending(result, text)
    for _, message in ipairs(result.pendientes) do
      if message:find(text, 1, true) then return true end
    end
    return false
  end

  case("Oficial preferencias: lote aplica interfaz, canales, teclado, audio y opciones", function()
    defaults()
    for _, key in ipairs({ "interfaz", "canales", "canales_consola", "teclado", "msp", "discord", "descargar_mapa", "comunicaciones" }) do
      config.set("oficial_" .. key, false)
    end
    config.set("oficial_depuracion", true)
    config.set("oficial_msp_debug", true)
    config.set("oficial_fuente_canales", 15)
    local result = save_apply()
    for _, key in ipairs({ "no_mostrar_interfaz", "no_mostrar_canales", "sin_canales_pantalla_principal", "msp_desactivar", "no_discord", "no_descargar_mapa", "depuracion", "msp_debug" }) do
      equal(RL_vars.opciones[key], true)
    end
    equal(RL_vars.opciones.tamanyo_fuente_canales, 15)
    equal(isActive("Numpad", "keybind"), 0)
    equal(isActive("Macros", "keybind"), 0)
    assert(RL_vars.GUI.contenedores.contenedor_derecho.hidden)
    assert(pending(result, "Fuente"))
    local registered = gmod.isRegisteredModule("Comm")
    assert(not registered or (not registered.RhomScripts and not registered[""]))
    defaults()
  end)

  case("Oficial preferencias: interfaz y canales reconstruyen una vez; repetición idempotente", function()
    defaults()
    local original, calls = RL_gui_reinicializar, 0
    RL_gui_reinicializar = function(...)
      calls = calls + 1
      return original(...)
    end
    local ok, message = pcall(function()
      config.set("oficial_interfaz", false)
      config.set("oficial_canales", false)
      save_apply()
      equal(calls, 1)
      save_apply()
      equal(calls, 1)
      config.set("oficial_interfaz", true)
      config.set("oficial_canales", true)
      save_apply()
      equal(calls, 2)
      assert(not RL_vars.GUI.contenedores.contenedor_derecho.hidden)
      assert(not RL_vars.GUI.contenedores.widget_comm.hidden)
      save_apply()
      equal(calls, 2)
    end)
    RL_gui_reinicializar = original
    assert(ok, message)
    defaults()
  end)

  case("Oficial preferencias: fuente cambia sin reconstruir y cero recupera predeterminado", function()
    defaults()
    local original_gui, original_font = RL_gui_reinicializar, RL_gui_fijar_tamanyo_fuente_consola
    local rebuilds, sizes = 0, {}
    RL_gui_reinicializar = function(...)
      rebuilds = rebuilds + 1
      return original_gui(...)
    end
    RL_gui_fijar_tamanyo_fuente_consola = function(tab, size)
      sizes[tab] = size
      return original_font(tab, size)
    end
    local ok, message = pcall(function()
      config.set("oficial_fuente_canales", 18)
      save_apply()
      equal(RL_vars.opciones.tamanyo_fuente_canales, 18)
      equal(sizes.global, 18)
      equal(rebuilds, 0)
      config.set("oficial_fuente_canales", 0)
      save_apply()
      equal(RL_vars.opciones.tamanyo_fuente_canales, nil)
      equal(sizes.global, getFontSize())
      equal(rebuilds, 0)
    end)
    RL_gui_reinicializar, RL_gui_fijar_tamanyo_fuente_consola = original_gui, original_font
    assert(ok, message)
    defaults()
  end)

  case("Oficial preferencias: offline conserva suscripción y declara macros y Discord pendientes", function()
    defaults()
    local _, _, connected = getConnectionInfo()
    assert(not connected, "Esta suite debe permanecer desconectada")
    config.set("oficial_interfaz", false)
    config.set("oficial_canales", false)
    config.set("oficial_macros", true)
    local result = save_apply()
    assert(pending(result, "Macros") and pending(result, "Discord") and pending(result, "Comunicaciones"))
    assert(gmod.isRegisteredModule("Comm").RhomScripts)
    equal(isActive("Macros", "keybind"), 0)
    equal(isActive("Numpad", "keybind"), 1)
    defaults()
  end)

  case("Oficial preferencias: API ausente se propaga y permite reintento", function()
    defaults()
    config.set("oficial_depuracion", true)
    assert(config.save())
    local original = RL_salvar_opciones
    RL_salvar_opciones = nil
    local ok, message = pcall(oficial.aplicar_configuracion, config)
    RL_salvar_opciones = original
    assert(not ok and tostring(message):find("RL_salvar_opciones", 1, true))
    -- La memoria oficial ya pudo cambiar: el reintento debe guardar el mismo
    -- objetivo pendiente, aunque no haya diferencias nuevas que calcular.
    local retries = 0
    RL_salvar_opciones = function(...)
      retries = retries + 1
      return original(...)
    end
    local retried, retry_message = pcall(oficial.aplicar_configuracion, config)
    RL_salvar_opciones = original
    assert(retried, retry_message)
    equal(retries, 1)
    equal(RL_vars.opciones.depuracion, true)
    defaults()
  end)

  case("Oficial preferencias: recarga corrige deriva sin perder preferencias guardadas", function()
    config.set("oficial_interfaz", false)
    config.set("oficial_teclado", false)
    config.set("oficial_comunicaciones", true)
    save_apply()
    RL_vars.opciones.no_mostrar_interfaz = false
    enableKey("Numpad")
    dofile(init_path)
    config = RhomScripts.modules.configuracion
    oficial = require("arranque")
    equal(config.get("oficial_interfaz"), false)
    equal(RL_vars.opciones.no_mostrar_interfaz, true)
    equal(isActive("Numpad", "keybind"), 0)
    assert(gmod.isRegisteredModule("Comm").RhomScripts)
    defaults()
  end)

  if mock then
    case("Oficial preferencias: reaplicación usa guardado y no cambios del menú en memoria", function()
      defaults()
      config.set("oficial_interfaz", false) -- No guardar ni aplicar.
      raiseEvent("rlmud_gui_reinicializada")
      mock.advance(0)
      equal(RL_vars.opciones.no_mostrar_interfaz or false, false)
      assert(not RL_vars.GUI.contenedores.contenedor_derecho.hidden)
      assert(config.load())
      defaults()
    end)
  end
end
return suite
