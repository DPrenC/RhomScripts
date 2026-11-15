-- luacheck: globals ansi2string
-- Modelo real del dominio con entradas sintéticas; no conecta al servidor.
local suite = {}
local function equal(actual, expected)
  assert(actual == expected, "Esperado " .. tostring(expected) .. "; obtenido " .. tostring(actual))
end

function suite.run(case, path)
  local config, lector, audio = require("configuracion"), require("lector"), require("audio")
  local limit, total = config.get("canales_limite"), config.get("canales_total")
  local original = lector.verbalizar
  local readings = {}
  lector.verbalizar = function(text, priority)
    equal(priority, lector.prioridades.ALTA)
    readings[#readings + 1] = text
    return original(text, priority)
  end
  local c = dofile(path)
  local function receive(channel, text, historical)
    return c.recibir({ canal = channel, mensaje = text }, historical)
  end
  local function fresh()
    c.detener()
    c = dofile(path)
    c.reconciliar({ ciudadania = {}, chat = {} }, true)
    readings = {}
  end
  local function capture_sounds(action)
    local sounds, reproduce = {}, audio.reproducir
    audio.reproducir = function(key, options)
      equal(options and options.grupo, nil)
      sounds[#sounds + 1] = key
      return reproduce(key, options)
    end
    local ok, message = pcall(action, sounds)
    audio.reproducir = reproduce
    assert(ok, message)
  end
  local ok, message = pcall(function()
    case("Comunicaciones: esqueleto de voz conserva announce y rechaza prioridad inválida", function()
      lector.verbalizar("Prueba de prioridad alta", lector.prioridades.ALTA)
      assert(not pcall(original, "texto", "inventada"))
      assert(not pcall(original, false, lector.prioridades.ALTA))
      local announce_original = announce
      announce = nil
      local accepted = pcall(lector.verbalizar, "texto", lector.prioridades.ALTA)
      announce = announce_original
      assert(not accepted, "Se ocultó announce ausente")
    end)
    case("Comunicaciones: categorías dinámicas y orden estable, sin duplicados", function()
      fresh()
      local state = c.estado()
      equal(state.categorias[1], "global")
      equal(state.categorias[2], "chat")
      equal(state.categorias[3], "ciudadania")
      c.abrir_canal("chat", true)
      equal(#c.estado().categorias, 3)
    end)
    case("Comunicaciones: llegada tiene un registro global y una sola verbalización", function()
      fresh()
      receive("ciudadania", "Mensaje con ñ y acentos")
      local state = c.estado()
      equal(state.cantidad, 1)
      equal(state.canales.ciudadania.cantidad, 1)
      equal(state.mensajes[1].id, state.canales.ciudadania.mensajes[1].id)
      equal(#readings, 1)
      assert(readings[1]:find("Mensaje con ñ y acentos", 1, true))
      state.canales.ciudadania.mensajes[1].texto = "mutado"
      assert(c.estado().mensajes[1].texto ~= "mutado", "estado expone datos mutables")
    end)
    case("Comunicaciones: contexto por nombre, grupos y sonido Clan por defecto", function()
      fresh()
      local cases = {
        { "bueno", "bando" }, { "MALO", "bando" }, { "solitarios", "interbando" },
        { "Mor Groddur", "ciudadania" }, { "Ak'anon", "ciudadania" }, { "alianza", "gremio" },
        { "sello_carmesí", "gremio" }, { "sello_carmesi", "gremio" }, { "Consulta.", "consulta" },
        { "Cre", "creadores" }, { "GRUPO-viajeros", "grupo" }, { "GRUPO-", "clan" },
        { "Girlhim", "clan" }, { "gremio", "clan" }, { "neutral", "clan" },
      }
      capture_sounds(function(sounds)
        for index, expected in ipairs(cases) do
          local id, key = expected[1], expected[2]
          c.abrir_canal(id, true)
          receive(id, "mensaje " .. index)
          equal(sounds[index], "comunicaciones." .. key)
          equal(c.estado().canales[id].mensajes[1].canal, id)
        end
        receive("no abierto", "descartar")
        receive("chat", "  ")
        equal(#sounds, #cases)
      end)
    end)
    case("Comunicaciones: históricos agrupados por canal y sonido independiente de la voz", function()
      fresh()
      c.abrir_canal("bueno", true)
      c.abrir_canal("malo", true)
      c.alternar_silencio()
      readings = {}
      capture_sounds(function(sounds)
        receive("bueno", "primer histórico", true)
        receive("bueno", "segundo histórico", true)
        receive("malo", "otro canal con el mismo sonido", true)
        receive("bueno", "nuevo durante la tanda")
        receive("bueno", "otro nuevo durante la tanda")
        receive("bueno", "tercer histórico", true)
        equal(#sounds, 4)
        for _, key in ipairs(sounds) do equal(key, "comunicaciones.bando") end
        equal(#readings, 0)
        equal(c.estado().cantidad, 6)
        c.reiniciar()
        c.abrir_canal("bueno", true)
        receive("bueno", "histórico de la siguiente sesión", true)
        equal(#sounds, 5)
      end)
    end)
    case("Comunicaciones: cambio anuncia el nombre y usa el mismo sonido UI en global", function()
      fresh()
      capture_sounds(function(sounds)
        c.cambiar_categoria(1)
        equal(#readings, 1)
        equal(readings[1], "canal chat")
        c.alternar_silencio()
        c.cambiar_categoria(-1)
        equal(readings[#readings], "canal global")
        local before = #readings
        c.cambiar_categoria(1)
        equal(#readings, before + 1)
        equal(readings[#readings], "canal chat")
        c.leer_ultimo()
        equal(readings[#readings], "No hay mensajes en el canal chat")
        equal(table.concat(sounds, ","), "ui.seleccion_canal,ui.comunicacion_mute,ui.seleccion_canal,ui.seleccion_canal")
      end)
    end)
    case("Comunicaciones: último por categoría y selección compartida con ventana cerrada", function()
      fresh()
      receive("chat", "primero chat")
      receive("ciudadania", "último ciudadania")
      c.cambiar_categoria(1)
      equal(c.estado().seleccion, "chat")
      equal(readings[#readings], "canal chat")
      c.leer_ultimo()
      assert(readings[#readings]:find("primero chat", 1, true))
      c.cambiar_categoria(-1)
      c.leer_ultimo()
      assert(readings[#readings]:find("último ciudadania", 1, true))
      equal(c.estado().seleccion, "global")
    end)
    case("Comunicaciones: silencio conserva recepción y permite lectura explícita", function()
      fresh()
      c.cambiar_categoria(1)
      c.alternar_silencio()
      equal(readings[#readings], "canal chat, silenciado.")
      local before = #readings
      receive("chat", "guardado sin voz")
      equal(#readings, before)
      equal(c.estado().canales.chat.cantidad, 1)
      c.leer_ultimo()
      equal(#readings, before + 1)
      assert(readings[#readings]:find("guardado sin voz", 1, true))
      c.reconciliar({ ciudadania = {}, chat = {} }, true)
      equal(c.estado().canales.chat.silenciado, true)
      c.abrir_canal("chat", true)
      equal(c.estado().canales.chat.silenciado, true)
      c.alternar_silencio()
      equal(readings[#readings], "canal chat, lectura activada.")
      c.alternar_silencio()
    end)
    case("Comunicaciones: Todos silencia conjunto mixto y reactiva todos", function()
      c.cambiar_categoria(-1)
      equal(c.estado().seleccion, "global")
      c.alternar_silencio()
      equal(c.estado().canales.chat.silenciado, true)
      equal(c.estado().canales.ciudadania.silenciado, true)
      equal(readings[#readings], "canal global, silenciado.")
      c.alternar_silencio()
      equal(c.estado().canales.chat.silenciado, false)
      equal(c.estado().canales.ciudadania.silenciado, false)
      equal(readings[#readings], "canal global, lectura activada.")
    end)
    case("Comunicaciones: cierre descarta tardíos e históricos y reapertura conserva historial", function()
      fresh()
      receive("chat", "conservado")
      c.cambiar_categoria(1)
      c.alternar_silencio()
      c.cerrar_canal("chat", true)
      equal(c.estado().seleccion, "global")
      local before = #readings
      receive("chat", "tardío")
      receive("chat", "histórico tardío", true)
      equal(c.estado().cantidad, 1)
      equal(#readings, before)
      c.abrir_canal("chat", true)
      equal(c.estado().canales.chat.silenciado, false)
      equal(c.estado().canales.chat.cantidad, 1)
      receive("chat", "histórico reabierto", true)
      equal(c.estado().cantidad, 2)
      equal(c.estado().mensajes[2].historico, true)
    end)
    case("Comunicaciones: texto idéntico legítimo no se deduplica y desconocido se descarta", function()
      fresh()
      receive("chat", "repetido")
      receive("chat", "repetido")
      receive("desconocido", "descartar")
      equal(c.estado().cantidad, 2)
      equal(#readings, 2)
    end)
    case("Comunicaciones: ANSI se retira antes de almacenar y verbalizar", function()
      fresh()
      receive("chat", "\27[31mtexto rojo\27[0m")
      equal(c.estado().mensajes[1].texto, "texto rojo")
      assert(not readings[1]:find("\27", 1, true))
      local conversion = ansi2string
      ansi2string = nil
      local accepted = pcall(receive, "chat", "texto")
      ansi2string = conversion
      assert(not accepted, "Se ocultó ansi2string ausente")
    end)
    case("Comunicaciones: fallo parcial de registros retira todos los creados", function()
      c = dofile(path)
      local register, kill = registerAnonymousEventHandler, killAnonymousEventHandler
      local calls, created, removed = 0, {}, {}
      registerAnonymousEventHandler = function(...)
        calls = calls + 1
        if calls == 3 then error("Registro de comunicaciones denegado", 0) end
        local id = register(...)
        created[id] = true
        return id
      end
      killAnonymousEventHandler = function(id)
        removed[id] = true
        return kill(id)
      end
      local accepted, error_text = pcall(c.iniciar)
      registerAnonymousEventHandler, killAnonymousEventHandler = register, kill
      assert(not accepted and tostring(error_text):find("Registro de comunicaciones denegado", 1, true))
      assert(not c.iniciado)
      for id in pairs(created) do assert(removed[id], "Registro parcial no retirado") end
      c.iniciar()
      assert(c.iniciado)
      c.detener()
      assert(not c.iniciado)
    end)
    case("Comunicaciones: límite por canal elimina las referencias más antiguas", function()
      fresh()
      config.set("canales_limite", 100)
      config.set("canales_total", 500)
      c.cambiar_categoria(1)
      c.alternar_silencio()
      for index = 1, 115 do receive("chat", "registro " .. index) end
      local state = c.estado()
      equal(state.cantidad, 100)
      equal(state.canales.chat.cantidad, 100)
      equal(state.mensajes[1].texto, "registro 16")
      equal(state.mensajes[100].texto, "registro 115")
    end)
    case("Comunicaciones: límite total incluye canales cerrados y aplica reducciones", function()
      fresh()
      config.set("canales_limite", 200)
      config.set("canales_total", 300)
      c.alternar_silencio()
      for index = 1, 60 do receive("chat", "viejo " .. index) end
      c.cerrar_canal("chat", true)
      for index = 1, 120 do receive("ciudadania", "nuevo " .. index) end
      config.set("canales_total", 100)
      c.aplicar_limites()
      local state = c.estado()
      equal(state.cantidad, 100)
      equal(state.mensajes[1].texto, "nuevo 21")
      assert(not state.canales.chat or state.canales.chat.cantidad == 0)
    end)
  end)
  lector.verbalizar = original
  config.set("canales_limite", limit)
  config.set("canales_total", total)
  c.detener()
  assert(ok, message)
end
return suite
