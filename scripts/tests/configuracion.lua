-- Suite compartida: JSON real en disco; yajl real en Mudlet y puente JSON en Lupa.
-- luacheck: globals io.open os.rename
local suite = {}

local function equal(actual, expected)
  assert(actual == expected, "Esperado " .. tostring(expected) .. "; obtenido " .. tostring(actual))
end

local function read(path)
  local file = assert(io.open(path, "rb"))
  local text = assert(file:read("*a"))
  assert(file:close())
  return text
end

local function write(path, text)
  local file = assert(io.open(path, "wb"))
  assert(file:write(text))
  assert(file:close())
end

local function restore_after(action, cleanup)
  local ok, message = pcall(action)
  cleanup()
  assert(ok, message)
end

function suite.run(case, init_path)
  local config = RhomScripts.modules.configuracion
  local path = config.path()
  local announcements = {}
  local original_announce = announce
  announce = function(text)
    announcements[#announcements + 1] = text
    return original_announce(text)
  end
  local function defaults()
    config.reset()
    assert(config.save())
  end
  restore_after(function()
    case("Configuración JSON: creación con los cinco volúmenes predeterminados", function()
      assert(os.remove(path))
      config.load()
      equal(path, getMudletHomeDir() .. "/config.json")
      local document = yajl.to_value(read(path))
      equal(document.version, 2)
      for _, name in ipairs({ "volumen_general", "volumen_interfaz", "volumen_comunicaciones", "volumen_combate" }) do
        equal(document.valores[name], 80)
        equal(config.get(name), 80)
      end
      equal(document.valores.volumen_ambiente, 70)
      equal(config.get("volumen_ambiente"), 70)
      equal(document.valores.ventanasflotantes, true)
      equal(config.get("ventanasflotantes"), true)
    end)

    case("Configuración JSON: migra versión1 conservando volúmenes y añade oficiales", function()
      write(path, '{"version":1,"valores":{"volumen_general":35,"volumen_interfaz":40,"volumen_combate":45,"volumen_ambiente":50}}')
      assert(config.load())
      equal(config.get("volumen_general"), 35)
      equal(config.get("volumen_interfaz"), 40)
      equal(config.get("volumen_combate"), 45)
      equal(config.get("volumen_ambiente"), 50)
      local document = yajl.to_value(read(path))
      equal(document.version, 2)
      equal(document.valores.volumen_comunicaciones, 80)
      equal(document.valores.ventanasflotantes, true)
      equal(config.get("oficial_interfaz"), true)
      equal(config.get("oficial_macros"), false)
      equal(config.get("oficial_fuente_canales"), 0)
      config.set("oficial_interfaz", false)
      assert(config.save())
      assert(config.load())
      equal(config.get("oficial_interfaz"), false)
      defaults()
    end)

    case("Configuración JSON: añade retención a versión2 sin perder preferencias previas", function()
      defaults()
      local document = yajl.to_value(read(path))
      document.valores.canales_limite, document.valores.canales_total = nil, nil
      document.valores.oficial_interfaz = false
      document.valores.volumen_general = 35
      write(path, yajl.to_string(document))
      assert(config.load())
      equal(config.get("oficial_interfaz"), false)
      equal(config.get("volumen_general"), 35)
      equal(config.get("canales_limite"), 500)
      equal(config.get("canales_total"), 5000)
      document = yajl.to_value(read(path))
      equal(document.valores.canales_limite, 500)
      equal(document.valores.canales_total, 5000)
      defaults()
    end)

    case("Configuración JSON: amplía versión2 antigua conservando preferencias", function()
      defaults()
      local document = yajl.to_value(read(path))
      document.valores.ventanasflotantes = nil
      document.valores.volumen_comunicaciones = nil
      document.valores.volumen_general = 35
      document.valores.oficial_interfaz = false
      document.valores.oficial_fuente_canales = 12
      write(path, yajl.to_string(document))
      local before = #announcements
      assert(config.load())
      equal(#announcements, before)
      equal(config.get("ventanasflotantes"), true)
      equal(config.get("volumen_general"), 35)
      equal(config.get("oficial_interfaz"), false)
      equal(config.get("oficial_fuente_canales"), 12)
      local upgraded = yajl.to_value(read(path))
      equal(upgraded.version, 2)
      equal(upgraded.valores.ventanasflotantes, true)
      equal(upgraded.valores.volumen_general, 35)
      equal(upgraded.valores.volumen_comunicaciones, 80)
      equal(upgraded.valores.oficial_interfaz, false)
      assert(not config.dirty)
      defaults()
    end)

    case("Configuración JSON: ventanas flotantes false persiste y el borrador es independiente", function()
      defaults()
      config.set("ventanasflotantes", false)
      assert(config.save())
      config.set("ventanasflotantes", true)
      assert(config.load())
      equal(config.get("ventanasflotantes"), false)
      equal(yajl.to_value(read(path)).valores.ventanasflotantes, false)
      local contents = read(path)
      local session = require("configurador").nueva_sesion()
      equal(session:get("ventanasflotantes"), false)
      local changed, limit = session:cambiar("ventanasflotantes", 1)
      assert(changed and not limit)
      equal(session:get("ventanasflotantes"), true)
      equal(config.get("ventanasflotantes"), false)
      session:reset()
      equal(session:get("ventanasflotantes"), true)
      equal(config.get("ventanasflotantes"), false)
      equal(read(path), contents)
      -- Descartar la sesión no requiere lectura ni publica su restablecimiento.
      equal(require("configurador").nueva_sesion():get("ventanasflotantes"), false)
      defaults()
      equal(config.get("ventanasflotantes"), true)
    end)

    case("Configuración JSON: ampliar no admite tipos inválidos ni campos originales ausentes", function()
      defaults()
      local contents = read(path)
      for _, invalid in ipairs({ "false", 0 }) do
        assert(not pcall(config.set, "ventanasflotantes", invalid))
        equal(config.get("ventanasflotantes"), true)
      end
      equal(read(path), contents)
      for _, invalid_case in ipairs({ "tipo", "volumen", "oficial" }) do
        local document = yajl.to_value(contents)
        document.valores.volumen_general = 35
        document.valores.ventanasflotantes = nil
        if invalid_case == "tipo" then document.valores.ventanasflotantes = "false"
        elseif invalid_case == "volumen" then document.valores.volumen_combate = nil
        else document.valores.oficial_macros = nil end
        write(path, yajl.to_string(document))
        local before = #announcements
        assert(config.load())
        assert(#announcements > before, "La ampliación aceptó una configuración incorrecta")
        equal(config.get("volumen_general"), 80)
        equal(config.get("ventanasflotantes"), true)
      end
    end)

    case("Configuración JSON: cambios en memoria y persistencia explícita", function()
      local before = read(path)
      config.set("volumen_general", 35)
      equal(config.get("volumen_general"), 35)
      assert(config.dirty)
      equal(read(path), before)
      assert(config.save())
      assert(not config.dirty)
      config.set("volumen_general", 45)
      config.load()
      equal(config.get("volumen_general"), 35)
      defaults()
    end)

    case("Configuración JSON: valores fuera de contrato no modifican memoria", function()
      for _, value in ipairs({ -5, 105, 81, "80", false }) do
        pcall(config.set, "volumen_general", value)
        equal(config.get("volumen_general"), 80)
      end
    end)

    case("Configuración JSON: archivo incorrecto se sustituye completo y se anuncia", function()
      local invalid = {
        "{esto no es json", "[]", "null", "true",
        '{"version":3,"valores":{}}',
        '{"version":1,"valores":{"volumen_general":35,"volumen_interfaz":80,"volumen_combate":80,"volumen_ambiente":105}}',
        '{"version":1,"valores":{"volumen_general":35,"volumen_interfaz":80,"volumen_combate":80}}',
      }
      for _, text in ipairs(invalid) do
        write(path, text)
        local before = #announcements
        config.load()
        assert(#announcements > before, "Archivo inválido sin anuncio")
        local actual = yajl.to_value(read(path))
        equal(actual.version, 2)
        equal(actual.valores.volumen_general, 80)
        equal(actual.valores.volumen_ambiente, 70)
      end
      equal(io.open(path .. ".bak", "rb"), nil)
    end)

    case("Configuración JSON: fallos de lectura y escritura se anuncian", function()
      local original_open = io.open
      local contents = read(path)
      config.set("volumen_general", 35)
      local before = #announcements
      io.open = function(file_path, mode)
        if file_path == path and mode:find("r", 1, true) then return nil, "Lectura denegada en prueba", 13 end
        return original_open(file_path, mode)
      end
      restore_after(function() config.load() end, function() io.open = original_open end)
      assert(#announcements > before, "Fallo de lectura sin anuncio")
      equal(read(path), contents)
      equal(config.get("volumen_general"), 35)
      assert(not config.save(), "Una lectura fallida permitió sobrescribir el archivo")
      equal(read(path), contents)
      assert(config.load(), "Una lectura correcta no recuperó el estado")
      config.set("volumen_general", 25)
      before = #announcements
      io.open = function(file_path, mode)
        if mode:find("w", 1, true) then return nil, "Escritura denegada en prueba", 13 end
        return original_open(file_path, mode)
      end
      restore_after(function()
        assert(not config.save(), "Se anunció éxito al fallar la escritura")
      end, function() io.open = original_open end)
      assert(#announcements > before, "Fallo de guardado sin anuncio")
      assert(config.dirty, "El fallo de escritura olvidó cambios pendientes")
      equal(read(path), contents)
      assert(config.save(), "No se pudo reintentar el guardado")
      equal(yajl.to_value(read(path)).valores.volumen_general, 25)
      defaults()
    end)

    case("Configuración JSON: errores read y close conservan memoria y archivo", function()
      local original_open = io.open
      local contents = read(path)
      config.set("volumen_general", 35)
      io.open = function(file_path, mode)
        if file_path == path and mode:find("r", 1, true) then
          return {
            read = function() return nil, "Fallo read provocado" end,
            close = function() return true end,
          }
        end
        return original_open(file_path, mode)
      end
      local before = #announcements
      restore_after(function() assert(not config.load()) end, function() io.open = original_open end)
      assert(#announcements > before)
      equal(config.get("volumen_general"), 35)
      assert(not config.save())
      equal(read(path), contents)
      assert(config.load())
      config.set("volumen_general", 35)
      io.open = function(file_path, mode)
        local file, message, code = original_open(file_path, mode)
        if file and mode:find("w", 1, true) then
          return {
            write = function(_, text) return file:write(text) end,
            close = function()
              assert(file:close())
              return nil, "Fallo close provocado"
            end,
          }
        end
        return file, message, code
      end
      before = #announcements
      restore_after(function() assert(not config.save()) end, function() io.open = original_open end)
      assert(#announcements > before)
      assert(config.dirty)
      equal(read(path), contents)
      assert(config.save())
      equal(yajl.to_value(read(path)).valores.volumen_general, 35)
      defaults()
    end)

    case("Configuración JSON: recuperación del temporal tras fallo de reemplazo", function()
      config.set("volumen_general", 45)
      local original_rename = os.rename
      local attempts = 0
      os.rename = function(source, destination)
        if destination == path then
          attempts = attempts + 1
          return nil, "Fallo rename provocado", 13
        end
        return original_rename(source, destination)
      end
      local before = #announcements
      restore_after(function() assert(not config.save()) end, function() os.rename = original_rename end)
      equal(attempts, 2)
      assert(#announcements > before)
      assert(config.dirty)
      equal(io.open(path, "rb"), nil)
      equal(yajl.to_value(read(path .. ".tmp")).valores.volumen_general, 45)
      -- Instancia nueva: representa el arranque posterior al fallo de reemplazo.
      local fresh = dofile(init_path:gsub("init%.lua$", "configuracion.lua"))
      local temporary_contents = read(path .. ".tmp")
      os.rename = function() return nil, "Recuperación denegada en prueba", 13 end
      before = #announcements
      restore_after(function() assert(not fresh.load()) end, function() os.rename = original_rename end)
      assert(#announcements > before)
      assert(fresh.dirty)
      equal(read(path .. ".tmp"), temporary_contents)
      equal(io.open(path, "rb"), nil)
      local original_open = io.open
      io.open = function(file_path, mode)
        assert(not mode:find("w", 1, true), "La recuperación intentó reescribir el único temporal válido")
        return original_open(file_path, mode)
      end
      restore_after(function() assert(fresh.load()) end, function() io.open = original_open end)
      equal(fresh.get("volumen_general"), 45)
      equal(yajl.to_value(read(path)).valores.volumen_general, 45)
      equal(io.open(path .. ".tmp", "rb"), nil)
      assert(config.load())
      equal(config.get("volumen_general"), 45)
      defaults()
    end)

    case("Borrador: editar y restablecer no publican ni escriben preferencias", function()
      defaults()
      local contents = read(path)
      local session = require("configurador").nueva_sesion()
      assert(session:cambiar("volumen_general", 1))
      equal(session:get("volumen_general"), 85)
      equal(config.get("volumen_general"), 80)
      equal(read(path), contents)
      assert(not config.dirty)
      session:reset()
      equal(session:get("volumen_general"), 80)
      equal(read(path), contents)
      equal(config.get("volumen_general"), 80)
    end)

    case("Borrador: límites, booleanos y salto de fuente entre cero y ocho", function()
      defaults()
      local session = require("configurador").nueva_sesion()
      local changed, limit
      for _ = 1, 3 do
        changed, limit = session:cambiar("volumen_general", 1)
        assert(changed and not limit, "Un ajuste intermedio se marcó como límite")
      end
      changed, limit = session:cambiar("volumen_general", 1)
      assert(changed and not limit, "Llegar al máximo no debe indicar límite")
      for _ = 1, 30 do session:cambiar("volumen_general", 1) end
      equal(session:get("volumen_general"), 100)
      changed, limit = session:cambiar("volumen_general", 1)
      assert(not changed and limit, "El límite superior simuló un cambio o no avisó")
      for _ = 1, 19 do session:cambiar("volumen_general", -1) end
      changed, limit = session:cambiar("volumen_general", -1)
      assert(changed and not limit, "Llegar al mínimo no debe indicar límite")
      equal(session:get("volumen_general"), 0)
      assert(not session:cambiar("volumen_general", -1))
      changed, limit = session:cambiar("oficial_interfaz", -1)
      assert(changed and not limit, "Cambiar un booleano no debe anunciar límite numérico")
      equal(session:get("oficial_interfaz"), false)
      changed, limit = session:cambiar("oficial_interfaz", 1)
      assert(changed and not limit)
      equal(session:get("oficial_interfaz"), true)
      changed, limit = session:cambiar("oficial_interfaz", 1)
      assert(changed and not limit, "Los booleanos deben alternar sin límite")
      equal(session:get("oficial_interfaz"), false)
      changed, limit = session:cambiar("oficial_interfaz", -1)
      assert(changed and not limit)
      equal(session:get("oficial_interfaz"), true)
      changed, limit = session:cambiar("oficial_interfaz", -1)
      assert(changed and not limit)
      equal(session:get("oficial_interfaz"), false)
      changed, limit = session:cambiar("oficial_fuente_canales", 1)
      assert(changed and not limit)
      equal(session:get("oficial_fuente_canales"), 8)
      changed, limit = session:cambiar("oficial_fuente_canales", -1)
      assert(changed and not limit)
      equal(session:get("oficial_fuente_canales"), 0)
    end)

    case("Borrador: validar todos los campos precede a escribir o publicar", function()
      defaults()
      local contents = read(path)
      for _, invalid in ipairs({ "falta", "fuera", "desconocido" }) do
        local session = require("configurador").nueva_sesion()
        if invalid == "falta" then session.valores.volumen_general = nil
        elseif invalid == "fuera" then session.valores.volumen_general = 101
        else session.valores.ajena = true end
        assert(not pcall(function() session:guardar() end))
        equal(read(path), contents)
        equal(config.get("volumen_general"), 80)
      end
    end)

    case("Borrador: escritura fallida conserva edición sin publicar ni aplicar", function()
      defaults()
      local contents = read(path)
      local session = require("configurador").nueva_sesion()
      session:cambiar("oficial_interfaz", -1)
      local oficial = require("arranque")
      local apply, calls = oficial.aplicar_configuracion, 0
      oficial.aplicar_configuracion = function(settings)
        calls = calls + 1
        equal(yajl.to_value(read(path)).valores.oficial_interfaz, settings.get("oficial_interfaz"))
        return apply(settings)
      end
      local original_open = io.open
      restore_after(function()
        io.open = function(file_path, mode)
          if mode:find("w", 1, true) then return nil, "Disco lleno en prueba", 28 end
          return original_open(file_path, mode)
        end
        local ok = session:guardar()
        assert(not ok)
        equal(calls, 0)
        equal(config.get("oficial_interfaz"), true)
        equal(session:get("oficial_interfaz"), false)
        assert(not session.guardado)
        io.open = original_open
        equal(read(path), contents)
        assert(session:guardar())
        equal(calls, 1)
        equal(config.get("oficial_interfaz"), false)
        equal(yajl.to_value(read(path)).valores.oficial_interfaz, false)
        assert(session.guardado)
      end, function()
        io.open = original_open
        oficial.aplicar_configuracion = apply
      end)
      defaults()
      oficial.aplicar_configuracion(config)
    end)

    case("Borrador: aplicación fallida conserva JSON publicado y permite reintentar", function()
      defaults()
      local session = require("configurador").nueva_sesion()
      session:cambiar("oficial_interfaz", -1)
      local oficial = require("arranque")
      local apply = oficial.aplicar_configuracion
      oficial.aplicar_configuracion = function() error("Aplicación oficial denegada en prueba") end
      restore_after(function()
        local ok, message = pcall(function() return session:guardar() end)
        assert(not ok and tostring(message):find("Aplicación oficial denegada", 1, true))
        assert(session.guardado)
        equal(yajl.to_value(read(path)).valores.oficial_interfaz, false)
        equal(config.get("oficial_interfaz"), false)
        -- Una edición posterior sigue aislada y no puede deshacer lo guardado.
        session:cambiar("volumen_general", 1)
        equal(session:get("volumen_general"), 85)
        equal(config.get("volumen_general"), 80)
        oficial.aplicar_configuracion = apply
        assert(session:guardar())
        equal(config.get("volumen_general"), 85)
        equal(RL_vars.opciones.no_mostrar_interfaz, true)
      end, function() oficial.aplicar_configuracion = apply end)
      defaults()
      oficial.aplicar_configuracion(config)
    end)

    case("Configuración JSON: APIs ausentes producen error", function()
      for _, name in ipairs({ "to_value", "to_string" }) do
        local original = yajl[name]
        yajl[name] = nil
        local ok = pcall(name == "to_value" and config.load or config.save)
        yajl[name] = original
        assert(not ok, "Se ocultó yajl." .. name .. " ausente")
      end
    end)

    case("Sonidos nativos: API de reproducción ausente produce error", function()
      local original = playSoundFile
      playSoundFile = nil
      local ok = pcall(require("ui").sonido_configurador, "abrir")
      playSoundFile = original
      assert(not ok, "Se ocultó playSoundFile ausente")
    end)

    case("Borrador: recarga conserva confirmados y descarta edición pendiente", function()
      defaults()
      local session = require("configurador").nueva_sesion()
      session:cambiar("volumen_general", -1)
      equal(session:get("volumen_general"), 75)
      dofile(init_path)
      config = RhomScripts.modules.configuracion
      equal(config.get("volumen_general"), 80)
      assert(not RhomScripts.modules.configurador.activo)
      equal(yajl.to_value(read(path)).valores.volumen_general, 80)
    end)
  end, function() announce = original_announce end)
end

return suite
