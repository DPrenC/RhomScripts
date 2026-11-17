-- luacheck: globals feedTelnet setConfig
local suite = {}

local function equal(actual, expected)
  assert(actual == expected, "Esperado " .. tostring(expected) .. "; obtenido " .. tostring(actual))
end

local function send_protocol(orden)
  assert(feedTelnet("<T_IAC>" .. orden .. "<O_GMCP>"))
end

local function send_packet(path, data)
  assert(feedTelnet("<T_IAC><T_SB><O_GMCP>" .. path .. " " .. data .. "<T_IAC><T_SE>"))
end

local function simulate_packet(path, data)
  local data_table = gmcp
  local last = path:match("[^.]+$")
  for field in path:sub(1, #path - #last):gmatch("[^.]+") do
    data_table[field] = data_table[field] or {}
    data_table = data_table[field]
  end
  data_table[last] = assert(yajl.to_value(data))
  raiseEvent("gmcp.Char", "gmcp." .. path)
end

function suite.run(case, init_path, handlers, native)
  local original_gmcp = gmcp
  gmcp = { Char = { Ficha = { clase = "dato previo" } } }
  local send = native and send_packet or simulate_packet
  local ok, message = xpcall(function()
    local ficha = RhomScripts.modules.ficha

    case("Ficha: espera la primera llegada y conserva Ficha, Stats y Status", function()
      equal(next(ficha.datos()), nil)
      equal(ficha.obtener("clase"), nil)
      if native then
        equal(select(3, getConnectionInfo()), false)
        assert(setConfig("enableGMCP", true))
        send_protocol("<T_WILL>")
      end
      send("Char.Ficha", [[{"nombre":"Persona de prueba","clase":"clase de prueba","oficio":"prueba",
        "genero":2,"raza":"raza de prueba","especializacion":"prueba","nivel":3}]])
      send("Char.Stats", [[{"fue":9,"fue_extrema":0,"con_origen":5}]])
      send("Char.Status", [[{"pvs":{"min":0,"max":10},"pe":{"min":5,"max":6}}]])
      equal(ficha.obtener("clase"), "clase de prueba")
      equal(ficha.obtener("nombre"), "Persona de prueba")
      equal(ficha.obtener("oficio"), "prueba")
      equal(ficha.obtener("sexo"), 2)
      equal(ficha.obtener("raza"), "raza de prueba")
      equal(ficha.obtener("Ficha.especializacion"), "prueba")
      equal(ficha.obtener("Stats.fue"), 9)
      equal(ficha.obtener("Stats.fue_extrema"), 0)
      equal(ficha.obtener("vida_actual"), 0)
      equal(ficha.obtener("vida_maxima"), 10)
      equal(ficha.obtener("Status.pe.min"), 5)
      equal(ficha.obtener("Status.escudo.min"), nil)
      if native then
        send_packet("Room.Actual", [["Lugar de prueba"]])
        equal(ficha.obtener("Room.Actual"), nil)
      end
    end)

    case("Ficha: acepta paquetes nuevos y devuelve copias de las tablas", function()
      send("Char.Status.Estados.set", '[]')
      equal(next(ficha.obtener("Status.Estados.set")), nil)
      send("Char.Status.Estados.set", [=[[{"nombre":"estado de prueba","tipo":"estado","corto":"P","ayuda":"prueba"}]]=])
      send("Char.Otro.Detalle", [[{"habilitado":false,"lista":[3]}]])
      equal(ficha.obtener("Otro.Detalle.habilitado"), false)
      local lista = ficha.obtener("Otro.Detalle.lista")
      equal(lista[1], 3)
      lista[1] = 99
      local copia = ficha.datos()
      copia.Status.Estados.set[1].nombre = "otro estado"
      gmcp.Char.Otro.Detalle.lista[1] = 88
      equal(ficha.obtener("Otro.Detalle.lista")[1], 3)
      equal(ficha.obtener("Status.Estados.set")[1].nombre, "estado de prueba")
    end)

    case("Ficha: conserva la vida máxima cuando llega solo la actual", function()
      send("Char.Status", [[{"pvs":{"min":4}}]])
      equal(ficha.obtener("vida_actual"), 4)
      equal(ficha.obtener("vida_maxima"), 10)
      equal(gmcp.Char.Status.pvs.max, nil)
      if native then
        equal(ficha.obtener("Status.pe.max"), 6)
        equal(ficha.obtener("Status.Estados.set")[1].nombre, "estado de prueba")
      end
      send("Char.Status.pvs", [[{"max":12}]])
      equal(ficha.obtener("vida_actual"), 4)
      equal(ficha.obtener("vida_maxima"), 12)
    end)

    case("Ficha: los paquetes independientes se conservan y Ficha se reemplaza", function()
      send("Char.Ficha", [[{"clase":"clase revisada","genero":1}]])
      equal(ficha.obtener("clase"), "clase revisada")
      equal(ficha.obtener("nombre"), nil)
      equal(ficha.obtener("sexo"), 1)
      equal(ficha.obtener("Ficha.especializacion"), nil)
      equal(ficha.obtener("Stats.fue"), 9)
      equal(ficha.obtener("Otro.Detalle.lista")[1], 3)
    end)

    case("Ficha: la recarga conserva lo recibido y sustituye el manejador", function()
      local anterior = ficha
      local id_anterior = assert(next(handlers()))
      dofile(init_path)
      local actuales = handlers()
      local id_nuevo = assert(next(actuales))
      assert(id_nuevo ~= id_anterior and not next(actuales, id_nuevo))
      ficha = RhomScripts.modules.ficha
      assert(ficha ~= anterior, "Se conservó la instancia anterior al recargar")
      equal(ficha.obtener("Stats.fue"), 9)
      equal(ficha.obtener("Otro.Detalle.lista")[1], 3)
      equal(ficha.obtener("vida_actual"), 4)
      equal(ficha.obtener("vida_maxima"), 12)
      send("Char.Otro.Detalle", [[{"habilitado":true}]])
      equal(ficha.obtener("Otro.Detalle.habilitado"), true)
      assert(anterior.obtener("Otro.Detalle.habilitado") ~= true, "El manejador antiguo recibió un mensaje")
    end)

    case("Ficha: conexión, despedida y desconexión vacían los datos privados", function()
      for _, event in ipairs({ "gmcp.Core.Goodbye", "sysDisconnectionEvent", "sysConnectionEvent" }) do
        send("Char.Stats", [[{"fue":7}]])
        equal(ficha.obtener("Stats.fue"), 7)
        raiseEvent(event)
        equal(next(ficha.datos()), nil)
        equal(gmcp.Char.Stats.fue, 7)
      end
    end)

    case("Ficha: deshabilitar GMCP vacía la copia sin alterar la tabla de Mudlet", function()
      send("Char.Status", [[{"pe":{"min":3,"max":6},"pvs":{"min":5,"max":10}}]])
      equal(ficha.obtener("Status.pe.min"), 3)
      raiseEvent("sysProtocolDisabled", "MSDP")
      equal(ficha.obtener("Status.pe.min"), 3)
      if native then send_protocol("<T_WONT>") else raiseEvent("sysProtocolDisabled", "GMCP") end
      equal(next(ficha.datos()), nil)
      equal(gmcp.Char.Status.pe.min, 3)
      if native then
        send_protocol("<T_WILL>")
        send("Char.Status", [[{"escudo":{"min":0,"max":0}}]])
        equal(gmcp.Char.Status.pvs.max, 10)
        equal(ficha.obtener("vida_actual"), nil)
        equal(ficha.obtener("vida_maxima"), nil)
        send("Char.Status", [[{"pvs":{"min":8}}]])
        equal(ficha.obtener("vida_actual"), 8)
        equal(ficha.obtener("vida_maxima"), nil)
        equal(ficha.obtener("Status.pe.min"), 3) -- Mudlet conserva su fusión al renegociar.
        equal(ficha.obtener("clase"), nil)
        send_protocol("<T_WONT>")
        equal(next(ficha.datos()), nil)
      end
    end)

    case("Ficha: Alt+1, Alt+2 y Alt+0 anuncian pares en una sola interrupción", function()
      local pulsaciones = ficha.pulsaciones
      local function verbalizar()
        for i = 1, 3 do pulsaciones[i].funcion() end
      end
      for i, tecla in ipairs({ "1", "2", "0" }) do
        equal(pulsaciones[i].combinacion.tecla, mudlet.key[tecla])
        equal(pulsaciones[i].combinacion.modificadores[1], mudlet.keymodifier.Alt)
        equal(pulsaciones[i].grupo, "informacion")
      end
      local anuncios, original = {}, announce
      announce = function(mensaje, modo)
        anuncios[#anuncios + 1] = mensaje
        equal(modo, "importantmostrecent")
        if native then original(mensaje, modo) end
      end
      local correcto, error_prueba = pcall(function()
        if native then send_protocol("<T_WILL>") end
        verbalizar()
        equal(#anuncios, 3)
        equal(anuncios[1], [[sin datos\sin datos]])
        equal(anuncios[2], [[sin datos\sin datos, sin datos\sin datos]])
        equal(anuncios[3], [[xp: sin datos\sin datos, puntos de oficio: sin datos\sin datos]])
        send("Char.Status", [[{"pvs":{"min":0,"max":120},"pe":{"min":50,"max":80},"escudo":{"min":0,"max":0},
          "xp":{"min":40,"max":600},"xp_oficio":{"min":0,"max":20}}]])
        verbalizar()
        equal(#anuncios, 6)
        equal(anuncios[4], [[0\120]])
        equal(anuncios[5], [[50\80, 0\0]])
        equal(anuncios[6], [[xp: 40\600, puntos de oficio: 0\20]])
        send("Char.Status", [[{"pvs":{"min":1},"pe":{"min":1},"escudo":{"min":0,"max":0},
          "xp":{"max":600},"xp_oficio":{"min":0}}]])
        verbalizar()
        equal(#anuncios, 9)
        equal(anuncios[7], [[1\120]])
        equal(anuncios[8], [[1\sin datos, 0\0]])
        equal(anuncios[9], [[xp: sin datos\600, puntos de oficio: 0\sin datos]])
      end)
      announce = original
      if native then send_protocol("<T_WONT>") end
      assert(correcto, error_prueba)
    end)

    case("Ficha: la copia común anuncia el texto con prefijos, Copiado y el sonido", function()
      if native then send_protocol("<T_WILL>") end
      send("Char.Status", [[{"pvs":{"min":40,"max":120},"pe":{"min":50},"escudo":{"min":0,"max":0},
        "xp":{"min":40,"max":600},"xp_oficio":{"min":0,"max":20}}]])
      local audio = require("audio")
      local lector = RhomScripts.modules.lector
      local original_clipboard, original_sonido = setClipboardText, audio.reproducir
      local original_copiar = lector.copiar
      local original_announce = announce
      local acciones = {}
      local delegadas = 0
      setClipboardText = function(texto) acciones[#acciones + 1] = texto end
      announce = function(texto)
        acciones[#acciones + 1] = texto
        if native then original_announce(texto) end
      end
      lector.copiar = function(texto, ...)
        equal(select("#", ...), 0)
        delegadas = delegadas + 1
        return original_copiar(texto)
      end
      audio.reproducir = function(clave)
        acciones[#acciones + 1] = clave
        if native then return original_sonido(clave) end
      end
      local correcto, error_prueba = pcall(function()
        for i = 4, 6 do ficha.pulsaciones[i].funcion() end
        equal(delegadas, 3)
        local textos = {
          [[pvs: 40\120]],
          [[energía: 50\sin datos, escudos: 0\0]],
          [[xp: 40\600, puntos de oficio: 0\20]],
        }
        equal(#acciones, 4 * #textos)
        for i, texto in ipairs(textos) do
          local inicio = (i - 1) * 4
          equal(acciones[inicio + 1], texto)
          equal(acciones[inicio + 2], texto)
          equal(acciones[inicio + 3], "Copiado")
          equal(acciones[inicio + 4], "ui.portapapeles")
        end
      end)
      setClipboardText, audio.reproducir = original_clipboard, original_sonido
      lector.copiar = original_copiar
      announce = original_announce
      if native then send_protocol("<T_WONT>") end
      assert(correcto, error_prueba)
    end)
  end, debug.traceback)
  gmcp = original_gmcp
  assert(ok, message)
end

return suite
