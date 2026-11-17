-- Diagnóstico compartido: APIs reales en Mudlet y doble explícito en Lua local.
-- luacheck: globals echo cecho RL_fijar_opcion killAlias expandAlias announce
local suite = {}
local function equal(actual, expected)
  assert(actual == expected, "Esperado " .. tostring(expected) .. "; obtenido " .. tostring(actual))
end
function suite.run(case, init_path, mock)
  local initial_mode = RL_vars.opciones.depuracion == true
  local original_echo, original_cecho = echo, cecho
  local output, cecho_depth = {}, 0
  echo = function(text, ...)
    if cecho_depth == 0 then output[#output + 1] = text end
    return original_echo(text, ...)
  end
  cecho = function(text, ...)
    if cecho_depth == 0 then output[#output + 1] = text end
    cecho_depth = cecho_depth + 1
    local displayed, result = pcall(original_cecho, text, ...)
    cecho_depth = cecho_depth - 1
    if not displayed then error(result, 0) end
    return result
  end
  local function mode(value)
    assert(RL_fijar_opcion("depuracion", value))
  end
  local function diagnostic() return RhomScripts.modules.debug end
  local ok, message = pcall(function()
    case("Debug: la opción oficial gobierna inmediatamente ambos sentidos", function()
      mode(false)
      equal(diagnostic().activo(), false)
      equal(RhomScripts.modules.configuracion.get("oficial_depuracion"), false)
      mode(true)
      equal(diagnostic().activo(), true)
      equal(RhomScripts.modules.configuracion.get("oficial_depuracion"), true)
      mode(false)
    end)
    case("Debug: los mensajes apagados se conservan sin salida automática", function()
      mode(false)
      local before = #output
      diagnostic().texto("prueba", "Mensaje técnico sintético oculto")
      equal(#output, before)
      local messages = diagnostic().consultar("mensajes", "prueba")
      assert(#messages > 0, "No se conservó el diagnóstico oculto")
      diagnostic().mostrar("mensajes", "prueba")
      assert(#output > before, "La consulta explícita quedó silenciada")
      assert(table.concat(output):find("Mensaje técnico sintético oculto", 1, true))
      mode(true)
      before = #output
      diagnostic().texto("prueba", "Mensaje técnico sintético visible")
      assert(#output > before, "El modo oficial no habilitó la salida de RhomScripts")
      mode(false)
    end)
    case("Debug: historial limitado a 500 y consultas independientes", function()
      for index = 1, 510 do diagnostic().texto("limite", "Entrada " .. index) end
      local entries = diagnostic().consultar("mensajes")
      equal(#entries, 500)
      local filtered = diagnostic().consultar("mensajes", "limite")
      equal(#filtered, 500)
      equal(filtered[1].texto, "Entrada 11")
      equal(filtered[500].texto, "Entrada 510")
      filtered[1].modulo = "modificado"
      equal(diagnostic().consultar("mensajes", "limite")[1].modulo, "limite")
    end)
    case("Debug: inventarios efectivos y copias conservan teclas, aliases y triggers", function()
      for _, kind in ipairs({ "keys", "alias", "triggers" }) do
        local entries = diagnostic().consultar(kind)
        local expected = kind == "keys" and 39 or (kind == "alias" and 3 or 2)
        equal(#entries, expected)
        local first = entries[1]
        assert(first.modulo and first.nombre and first.id, "Inventario sin identidad real: " .. kind)
        assert(type(first.id) == "number")
        assert(first.funcion == nil and type(first.accion) ~= "function", "Se expuso un callback")
        local original_name = first.nombre
        first.nombre = "modificado"
        equal(diagnostic().consultar(kind)[1].nombre, original_name)
      end
      local keys = diagnostic().consultar("keys", "lector")
      equal(#keys, 18)
      for _, entry in ipairs(keys) do equal(entry.modulo, "lector") end
    end)
    case("Debug: alias incremental no duplica y conserva ID si no se retira", function()
      local aliases = RhomScripts.soporte.aliases
      local before = #aliases.consultar()
      local definitions = {{ name = "prueba_retirada", desc = "Retirada sintética",
        pattern = "^prueba_retirada$", action = function() end }}
      aliases.registrar_modulo("prueba_retirada", definitions)
      equal(#aliases.consultar(), before + 1)
      aliases.registrar_modulo("prueba_retirada", definitions)
      equal(#aliases.consultar(), before + 1)
      local original_kill = killAlias
      killAlias = function() return false end
      local removed = pcall(aliases.desregistrar, "prueba_retirada")
      killAlias = original_kill
      assert(not removed, "Se ocultó un fallo de retirada")
      equal(#aliases.consultar(), before + 1)
      aliases.desregistrar("prueba_retirada")
      equal(#aliases.consultar(), before)
    end)
    case("Debug: comandos de consulta funcionan con modo desactivado", function()
      mode(false)
      local count = #output
      for _, kind in ipairs({ "estado", "modulos", "keys", "alias", "triggers", "sonidos", "mensajes" }) do
        local text = diagnostic().mostrar(kind)
        assert(type(text) == "string" and text ~= "", "Informe vacío: " .. kind)
      end
      assert(#output > count)
      if mock then
        for _, command in ipairs({ "rhomscripts", "rhomscripts estado", "rhomscripts modulos", "rhomscripts keys", "rhomscripts alias", "rhomscripts triggers", "rhomscripts sonidos", "rhomscripts mensajes", "rhomscripts version", "rhomscripts keys lector", "Rhomscripts version" }) do
          mock.alias(command)
        end
      else
        -- El motor real resuelve los patrones y consume estos comandos locales
        -- en el perfil desconectado, sin simular una pulsación física.
        for _, command in ipairs({ "rhomscripts", "rhomscripts estado", "rhomscripts modulos", "rhomscripts keys", "rhomscripts alias", "rhomscripts triggers", "rhomscripts sonidos", "rhomscripts mensajes", "rhomscripts version", "rhomscripts keys lector", "Rhomscripts version" }) do
          local before = #output
          expandAlias(command, false)
          assert(#output > before, "El motor no ejecutó el alias de diagnóstico " .. command)
        end
      end
    end)
    case("Debug: una sola familia sustituye todos los accesos duplicados", function()
      local legacy = { rhomdebug = true, listkeys = true, listalias = true, listtriggers = true,
        listmodulos = true, listsonidos = true, estado = true, rhomestado = true }
      local diagnostic_aliases = 0
      for _, alias in ipairs(RhomScripts.soporte.aliases.consultar()) do
        assert(not legacy[alias.nombre], "Permanece el comando duplicado " .. alias.nombre)
        if alias.modulo == "debug" then
          diagnostic_aliases = diagnostic_aliases + 1
          equal(alias.nombre, "rhomscripts")
        end
      end
      equal(diagnostic_aliases, 1)
    end)
    case("Debug: versión consultada y evento ready coinciden tras recargar", function()
      local event_version
      local handler = registerAnonymousEventHandler("rhomscripts.ready", function(_, value) event_version = value end)
      local loaded, failure = pcall(dofile, init_path)
      killAnonymousEventHandler(handler)
      assert(loaded, failure)
      equal(event_version, diagnostic().version())
      equal(event_version, "1.0, 17/11/2026")
      local original_announce, announced = announce, {}
      announce = function(text)
        announced[#announced + 1] = text
        return original_announce(text)
      end
      local before = #output
      local displayed, text = pcall(diagnostic().mostrar, "version")
      announce = original_announce
      assert(displayed, text)
      assert(type(text) == "string" and text:find(event_version, 1, true))
      assert(#output > before)
      equal(output[#output], text .. "\n")
      equal(#announced, 1)
      equal(announced[1], text)
    end)
    case("Debug: borrador cancelar no cambia oficial y guardar lo comparte", function()
      local configurador = RhomScripts.modules.configurador
      mode(false)
      local session = configurador.nueva_sesion()
      assert(session:cambiar("oficial_depuracion", 1))
      equal(session:get("oficial_depuracion"), true)
      equal(diagnostic().activo(), false)
      session = configurador.nueva_sesion() -- representa descartar el borrador
      equal(session:get("oficial_depuracion"), false)
      assert(session:cambiar("oficial_depuracion", 1))
      assert(session:guardar())
      equal(diagnostic().activo(), true)
      local file = assert(io.open(RhomScripts.modules.configuracion.path(), "rb"))
      local document = yajl.to_value(file:read("*a"))
      file:close()
      equal(document.valores.oficial_depuracion, nil)
      mode(false)
    end)
    case("Debug: cambios oficiales no editados sobreviven al guardar otro ajuste", function()
      mode(false)
      local session = RhomScripts.modules.configurador.nueva_sesion()
      mode(true)
      assert(session:guardar())
      equal(diagnostic().activo(), true)
      mode(false)
    end)
    case("Debug: JSON antiguo descarta la copia sin cambiar el valor oficial", function()
      local config = RhomScripts.modules.configuracion
      local path = config.path()
      local file = assert(io.open(path, "rb"))
      local document = yajl.to_value(file:read("*a"))
      file:close()
      document.valores.oficial_depuracion = false
      file = assert(io.open(path, "wb"))
      assert(file:write(yajl.to_string(document)))
      assert(file:close())
      mode(true)
      assert(config.load())
      equal(config.get("oficial_depuracion"), true)
      file = assert(io.open(path, "rb"))
      document = yajl.to_value(file:read("*a"))
      file:close()
      equal(document.valores.oficial_depuracion, nil)
      mode(false)
    end)
    case("Debug: reaplicar preferencias no restaura una copia obsoleta", function()
      mode(true)
      require("arranque").aplicar_configuracion(RhomScripts.modules.configuracion)
      equal(diagnostic().activo(), true)
      mode(false)
      require("arranque").aplicar_configuracion(RhomScripts.modules.configuracion)
      equal(diagnostic().activo(), false)
    end)
    case("Debug: recarga reinicia mensajes sin sustituir biblioteca estándar", function()
      local lua_debug, loaded_debug = debug, package.loaded.debug
      diagnostic().texto("anterior", "Solo generación anterior")
      local previous = diagnostic()
      mode(true)
      dofile(init_path)
      equal(RhomScripts.modules.configuracion.get("oficial_depuracion"), true)
      assert(diagnostic() ~= previous)
      equal(#diagnostic().consultar("mensajes", "anterior"), 0)
      equal(debug, lua_debug)
      equal(package.loaded.debug, loaded_debug)
      assert(type(debug.traceback) == "function")
      mode(false)
    end)
    case("Debug: arranque normal apagado solo emite dos hitos propios", function()
      mode(false)
      output = {}
      dofile(init_path)
      equal(#output, 2)
      local text = table.concat(output)
      assert(text:find("Cargando", 1, true) and text:find("Carga correcta", 1, true))
    end)
    case("Debug: salida ausente se propaga al consultar y al emitir detalles", function()
      local actual_echo = echo
      echo = nil
      local displayed = pcall(diagnostic().mostrar, "keys")
      echo = actual_echo
      assert(not displayed, "Se ocultó echo ausente en una consulta")
      mode(true)
      actual_echo = echo
      echo = nil
      local emitted = pcall(diagnostic().texto, "prueba", "Fallo API sintético")
      echo = actual_echo
      mode(false)
      assert(not emitted, "Se ocultó echo ausente en el debug activo")
    end)
  end)
  echo, cecho = original_echo, original_cecho
  mode(initial_mode)
  assert(ok, tostring(message))
end
return suite
