-- Modelo de mapa con entradas sintéticas; las ventanas se prueban en Mudlet real.
-- luacheck: globals os.rename os.remove
-- luacheck: globals RL_mostrar_links_viaje_room RL_buscar_salas RL_dame_string_salidas RL_speed_walk_to RL_speed_walk_sigilar_to RL_speed_walk_reset createRoomID addRoom setRoomName setExit deleteRoom getRoomName expandAlias RHOM_TEST_MAP_KEYBOARD
local suite = {}
local function equal(actual, expected)
  assert(actual == expected, "Esperado " .. tostring(expected) .. "; obtenido " .. tostring(actual))
end
local function write(path, text)
  local file = assert(io.open(path, "wb"))
  assert(file:write(text))
  assert(file:close())
end
function suite.run(case, path, mock)
  local config = require("configuracion")
  local before = config.get("mapa_destinos")
  local ficha = require("ficha")
  local ficha_anterior, gmcp_anterior = ficha.datos(), gmcp
  local function identificar(nombre)
    gmcp = { Char = { Ficha = { nombre = nombre } } }
    raiseEvent("gmcp.Char", "gmcp.Char.Ficha")
  end
  identificar("Personaje A")
  local original, buscar, salidas = RL_mostrar_links_viaje_room, RL_buscar_salas, RL_dame_string_salidas
  local map, openings, entries = nil, 0, {}
  local favorite_path = getMudletHomeDir() .. "/destinos_favoritos.json"
  local previous = io.open(favorite_path, "rb")
  local contents
  if previous then contents = assert(previous:read("*a")); assert(previous:close()) end
  local function fresh(enabled)
    if map then map.destruir() end
    config.set("mapa_destinos", enabled or false)
    map = dofile(path)
    map.iniciar()
    openings = 0
    map.mostrar = function() openings = openings + 1 end
    return map
  end
  RL_buscar_salas = function(criterio)
    assert(type(criterio) == "string")
    return entries
  end
  RL_dame_string_salidas = function(id, corto)
    assert(type(id) == "number" and corto == true)
    return "[n,s]"
  end
  local ok, message = pcall(function()
    os.remove(favorite_path)
    case("Mapa: interfaz oficial seleccionada y favorito ausente es conjunto vacío", function()
      fresh()
      equal(RL_mostrar_links_viaje_room, original)
      equal(#map.estado().favoritos, 0)
      equal(#map.estado().resultados, 0)
    end)
    case("Mapa: activar sustituye solo la presentación; desactivar restaura la original", function()
      config.set("mapa_destinos", true)
      map.aplicar_configuracion()
      assert(RL_mostrar_links_viaje_room ~= original)
      local replacement = RL_mostrar_links_viaje_room
      map.aplicar_configuracion()
      equal(RL_mostrar_links_viaje_room, replacement)
      config.set("mapa_destinos", false)
      map.aplicar_configuracion()
      equal(RL_mostrar_links_viaje_room, original)
    end)
    case("Mapa: destinos homónimos conservan ID, salidas y modo sigiloso sin imprimir filas", function()
      fresh(true)
      entries = { [12] = "Plaza", [8] = "Plaza [e,o]", [14] = "Plaza" }
      local printed = #mock.output
      RL_mostrar_links_viaje_room("Plaza", true)
      equal(#map.estado().resultados, 3)
      equal(#mock.output, printed)
      local ids = {}
      for _, destino in ipairs(map.estado().resultados) do
        ids[destino.id] = true
        equal(destino.sigilar, true)
      end
      assert(ids[8] and ids[12] and ids[14])
      local copy = map.estado()
      copy.resultados[1].nombre = "Alterado"
      assert(map.estado().resultados[1].nombre ~= "Alterado")
      mock.advance(0)
      equal(openings, 1)
    end)
    case("Mapa: búsqueda vacía retira resultados anteriores y no borra favoritos", function()
      entries = {}
      map.recibir("Nada", false)
      equal(#map.estado().resultados, 0)
      mock.advance(0)
      equal(openings, 1)
    end)
    case("Mapa: JSON válido conserva destinos favoritos al renovar el módulo", function()
      write(favorite_path, '{"version":2,"personajes":{"Personaje A":[{"id":8,"nombre":"Plaza","salidas":"[e,o]","sigilar":false}]}}')
      fresh(true)
      equal(map.path(), favorite_path)
      equal(#map.estado().favoritos, 1)
      equal(map.estado().favoritos[1].id, 8)
      entries = { [12] = "Plaza" }
      map.recibir("Plaza", false)
      equal(#map.estado().resultados, 1)
      fresh(true)
      equal(#map.estado().resultados, 0)
      equal(#map.estado().favoritos, 1)
    end)
    case("Mapa: añadir y eliminar favoritos persiste sin duplicar sala y modo", function()
      local destino = { id = 33, nombre = "Destino", salidas = "[n]", sigilar = false }
      assert(map.agregar_favorito(destino))
      equal(map.agregar_favorito(destino), false)
      equal(#map.estado().favoritos, 2)
      destino.sigilar = true
      assert(map.agregar_favorito(destino))
      fresh(true)
      equal(#map.estado().favoritos, 3)
      assert(map.eliminar_favorito(destino))
      fresh(true)
      equal(#map.estado().favoritos, 2)
      destino.sigilar = false
      assert(map.eliminar_favorito(destino))
      fresh(true)
      equal(#map.estado().favoritos, 1)
    end)
    case("Mapa: fallo al sustituir favoritos restaura archivo y no publica el cambio", function()
      local rename = os.rename
      os.rename = function(from, to)
        if from == favorite_path .. ".tmp" then return nil, "Fallo de movimiento provocado" end
        return rename(from, to)
      end
      local saved = pcall(map.agregar_favorito,
        { id = 34, nombre = "No guardado", salidas = "[s]", sigilar = false })
      os.rename = rename
      equal(saved, false)
      equal(#map.estado().favoritos, 1)
      fresh(true)
      equal(#map.estado().favoritos, 1)
      os.remove(favorite_path .. ".tmp")
    end)
    case("Mapa: fallo al limpiar respaldo revierte disco y memoria y permite reintentar", function()
      local remove = os.remove
      os.remove = function(pathname)
        if pathname == favorite_path .. ".bak" then return nil, "Fallo de limpieza provocado" end
        return remove(pathname)
      end
      local destino = { id = 35, nombre = "Limpieza fallida", salidas = "[e]", sigilar = false }
      local saved = pcall(map.agregar_favorito, destino)
      os.remove = remove
      equal(saved, false)
      equal(#map.estado().favoritos, 1)
      assert(not lfs.attributes(favorite_path .. ".bak", "mode"))
      fresh(true)
      equal(#map.estado().favoritos, 1)
      assert(map.agregar_favorito(destino))
      fresh(true)
      equal(#map.estado().favoritos, 2)
      assert(map.eliminar_favorito(destino))
    end)
    case("Mapa: favoritos separados por personaje y borrado persistente sin afectar a otros", function()
      local destino = { id = 66, nombre = "Propio", salidas = "[o]", sigilar = false }
      identificar("Personaje B")
      equal(#map.estado().favoritos, 0)
      assert(map.agregar_favorito(destino))
      identificar("Personaje A")
      equal(#map.estado().favoritos, 1)
      assert(map.agregar_favorito(destino))
      assert(map.eliminar_favorito(destino))
      local file = assert(io.open(favorite_path, "rb"))
      local guardados = yajl.to_value(file:read("*a")); file:close()
      equal(#guardados.personajes["Personaje A"], 1)
      equal(guardados.personajes["Personaje B"][1].id, 66)
      identificar("Personaje B")
      equal(map.estado().favoritos[1].id, 66)
      assert(map.eliminar_favorito(destino))
      fresh(true)
      equal(#map.estado().favoritos, 0)
      identificar(nil)
      equal(#map.estado().favoritos, 0)
      equal(map.agregar_favorito(destino), false)
      identificar("Personaje A")
      equal(#map.estado().favoritos, 1)
    end)
    case("Mapa: formato antiguo se vacía y se convierte sin asignar destinos", function()
      write(favorite_path, '{"version":1,"destinos":[{"id":8,"nombre":"Antiguo","salidas":"[n]","sigilar":false}]}')
      fresh(true)
      equal(#map.estado().favoritos, 0)
      local file = assert(io.open(favorite_path, "rb"))
      local guardados = yajl.to_value(file:read("*a")); file:close()
      equal(guardados.version, 2)
      equal(next(guardados.personajes), nil)
      equal(guardados.destinos, nil)
    end)
    case("Mapa: retirada cancela apertura pendiente y respeta una sustitución posterior", function()
      entries = { [12] = "Plaza" }
      map.recibir("Plaza", false)
      local another = function() end
      RL_mostrar_links_viaje_room = another
      map.destruir()
      map = nil
      mock.advance(0)
      equal(openings, 0)
      equal(RL_mostrar_links_viaje_room, another)
      RL_mostrar_links_viaje_room = original
    end)
    case("Mapa: JSON inválido lanza error y conserva el archivo intacto", function()
      write(favorite_path, "{incorrecto")
      equal(pcall(fresh), false)
      local file = assert(io.open(favorite_path, "rb"))
      equal(file:read("*a"), "{incorrecto")
      assert(file:close())
      os.remove(favorite_path)
    end)
    case("Mapa: buscador ausente produce error en lugar de una lista vacía", function()
      fresh(true)
      RL_buscar_salas = nil
      equal(pcall(map.recibir, "Plaza", false), false)
    end)
  end)
  if map then map.destruir() end
  RL_mostrar_links_viaje_room, RL_buscar_salas, RL_dame_string_salidas = original, buscar, salidas
  config.set("mapa_destinos", before)
  gmcp = gmcp_anterior
  ficha.detener()
  ficha.iniciar(ficha_anterior)
  if contents then write(favorite_path, contents) else os.remove(favorite_path) end
  assert(ok, message)
end
-- Integración: controles y funciones oficiales reales en el perfil aislado.
function suite.real(case, root)
  local config = RhomScripts.modules.configuracion
  local previous_option = config.get("mapa_destinos")
  local ficha_anterior, gmcp_anterior = require("ficha").datos(), gmcp
  gmcp = { Char = { Ficha = { nombre = "Personaje A" } } }
  raiseEvent("gmcp.Char", "gmcp.Char.Ficha")
  local present = RL_mostrar_links_viaje_room
  local walk, sneak = RL_speed_walk_to, RL_speed_walk_sigilar_to
  local current = RL_vars.mapa.actual
  local created, calls, map = {}, {}, nil
  local capture_steps = false
  local reproducir, sonidos = playSoundFile, {}
  playSoundFile = function(opciones)
    sonidos[#sonidos + 1] = opciones.key
    return reproducir(opciones)
  end
  local speak, readings = announce, {}
  announce = function(text) readings[#readings + 1] = text; return speak(text) end
  local favorite_path = getMudletHomeDir() .. "/destinos_favoritos.json"
  local function room(name)
    local id = createRoomID()
    assert(addRoom(id, -1))
    created[#created + 1] = id
    setRoomName(id, name)
    equal(getRoomName(id), name)
    return id
  end
  local function modal(action, show)
    local returned, failure
    map.vista.dialogo:CallAfter(function()
      returned, failure = xpcall(action, debug.traceback)
      if not returned then map.cerrar() end
    end)
    local open = show or map.mostrar
    open()
    assert(returned, failure or "El diálogo no ejecutó el callback real")
  end
  local ok, message = xpcall(function()
    local source = room("RhomScripts origen sintético")
    local destination = room("RhomScripts destino sintético")
    assert(setExit(source, destination, "n"))
    assert(setExit(destination, source, "s"))
    write(favorite_path, yajl.to_string({ version = 2, personajes = { ["Personaje A"] = {
      { id = destination, nombre = "RhomScripts destino sintético", salidas = "[s]", sigilar = false },
    } } }))
    config.set("mapa_destinos", true)
    assert(config.save())
    dofile(root .. "/rhomscripts/init.lua")
    map = RhomScripts.modules.mapa
    -- El arranque oficial puede volver a cargar su mapa desde disco.
    if not getRoomName(source) then assert(addRoom(source, -1)) end
    if not getRoomName(destination) then assert(addRoom(destination, -1)) end
    setRoomName(source, "RhomScripts origen sintético")
    setRoomName(destination, "RhomScripts destino sintético")
    assert(setExit(source, destination, "n"))
    assert(setExit(destination, source, "s"))
    RL_vars.mapa.actual = source
    RL_speed_walk_to = function(id, sigilar)
      assert(not map.vista.mostrando, "El viaje comenzó antes de retornar el diálogo")
      calls[#calls + 1] = { id = id, sigilar = sigilar ~= nil }
      local result = walk(id, sigilar)
      assert(#RL_vars.mapa.speedwalk.timers > 0, "El motor real no preparó el camino")
      if not capture_steps then RL_speed_walk_reset() end
      return result
    end
    -- El wrapper sigiloso oficial delega al motor instrumentado real.
    RL_speed_walk_sigilar_to = function(id) return sneak(id) end
    case("Mapa real: ventana oculta, favoritos JSON y atajo central registrado", function()
      assert(map.vista and map.lista and map.pestanyas)
      assert(not map.vista.dialogo:IsShown())
      equal(#map.estado().resultados, 0)
      equal(#map.estado().favoritos, 1)
      local found = 0
      for _, key in ipairs(RhomScripts.modules.keys.consultar()) do
        if key.nombre == "mapa.mostrar" then
          equal(key.combinacion, "Ctrl+Shift+M")
          found = found + 1
        end
      end
      equal(found, 1)
      assert(RL_mostrar_links_viaje_room ~= present)
    end)
    case("Mapa real: reapertura conserva pestaña; Tab y Escape no viajan", function()
      sonidos = {}
      modal(function()
        equal(map.estado().pestana, 1)
        equal(map.lista:GetItemCount(), 0)
        equal(map.vista.dialogo:GetTitle(), "Destinos del mapa: Resultados")
        local n = #sonidos
        local avisos = #readings
        local componente = map.componente
        local seleccionar, actualizar = componente.seleccionar_pestana, componente.actualizar
        local selecciones_pagina, filas = 0, {}
        componente.seleccionar_pestana = function(self, ...)
          selecciones_pagina = selecciones_pagina + 1
          return seleccionar(self, ...)
        end
        componente.actualizar = function(self, elementos, ...)
          filas[#filas + 1] = elementos
          return actualizar(self, elementos, ...)
        end
        local ok, fallo = xpcall(function()
          map.vista.tab(1)
          equal(#sonidos, n + 1)
          equal(sonidos[#sonidos], "rhom:catalogo:ui.pestana")
          equal(#readings, avisos + 1)
          equal(readings[#readings], "Favoritos")
          equal(map.vista.dialogo:GetTitle(), "Destinos del mapa: Favoritos")
          map.vista.tab(-1)
          equal(#sonidos, n + 2)
          equal(sonidos[#sonidos], "rhom:catalogo:ui.pestana")
          equal(#readings, avisos + 2)
          equal(readings[#readings], "Resultados")
          equal(map.vista.dialogo:GetTitle(), "Destinos del mapa: Resultados")
          map.vista.tab(1)
          equal(#sonidos, n + 3)
          equal(sonidos[#sonidos], "rhom:catalogo:ui.pestana")
          equal(map.estado().pestana, 2)
          equal(map.vista.dialogo:GetTitle(), "Destinos del mapa: Favoritos")
          equal(#readings, avisos + 3)
          equal(readings[#readings], "Favoritos")
          equal(selecciones_pagina, 3)
          equal(#filas, 3)
          equal(filas[1], filas[3]) -- Volver reutiliza las filas sin reconstruir textos.
          seleccionar(componente, "favoritos")
          equal(#readings, avisos + 3) -- La misma pestaña no vuelve a anunciarse.
        end, debug.traceback)
        componente.seleccionar_pestana, componente.actualizar = seleccionar, actualizar
        assert(ok, fallo)
        equal(map.lista:GetItemCount(), 1)
        map.vista.cancelar()
      end)
      modal(function()
        equal(map.estado().pestana, 2)
        equal(map.vista.dialogo:GetTitle(), "Destinos del mapa: Favoritos")
        equal(map.lista:GetItemCount(), 1)
        map.vista.cancelar()
      end)
      equal(#calls, 0)
      equal(sonidos[1], "rhom:catalogo:ui.abrir_mapa")
      equal(sonidos[2], "rhom:catalogo:ui.pestana")
      equal(sonidos[3], "rhom:catalogo:ui.pestana")
      equal(sonidos[4], "rhom:catalogo:ui.pestana")
      equal(sonidos[5], "rhom:catalogo:ui.plegar")
      equal(sonidos[6], "rhom:catalogo:ui.abrir_mapa")
      equal(sonidos[7], "rhom:catalogo:ui.plegar")
      equal(#sonidos, 7)
    end)
    if RHOM_TEST_MAP_KEYBOARD then
    case("Mapa real: teclado Windows " .. RHOM_TEST_MAP_KEYBOARD .. " activa el destino", function()
      local runtime = package.loaded.rhom_nativo_runtime
      runtime.ffi.cdef [[
        int PostMessageW(RHOM_HWND hwnd, unsigned int message, unsigned long long wparam, long long lparam);
        RHOM_HWND GetForegroundWindow(void);
        RHOM_HWND GetFocus(void);
        short GetAsyncKeyState(int key);
        typedef struct { unsigned int type; union {
          struct { unsigned short wVk, wScan; unsigned int dwFlags, time; unsigned long long dwExtraInfo; } ki;
          unsigned char size_mouse[32];
        } data; } RHOM_TEST_INPUT;
        unsigned int SendInput(unsigned int count, RHOM_TEST_INPUT *inputs, int size);
      ]]
      equal(runtime.ffi.sizeof("RHOM_TEST_INPUT"), 40)
      local ui = require("ui")
      local traces, commands = {}, {}
      local original_send = send
      send = function(command, ...)
        commands[#commands + 1] = command
        return original_send(command, ...)
      end
      local _, _, connected = getConnectionInfo()
      assert(not connected, "La prueba de envío exige perfil desconectado")
      capture_steps = true
      local key_handler, accept, cancel = map.vista.tecla, map.aceptar, map.vista.cancelar
      map.vista.tecla = function(event)
        traces[#traces + 1] = "hook:" .. event:GetKeyCode() .. ":" .. event:GetModifiers()
        return key_handler(event)
      end
      map.aceptar = function()
        traces[#traces + 1] = "aceptar"
        return accept()
      end
      map.vista.cancelar = function()
        traces[#traces + 1] = "cancelar"
        return cancel()
      end
      map.lista:Connect(map.vista.wx.wxEVT_KEY_DOWN, function(event)
        traces[#traces + 1] = "keydown:" .. event:GetKeyCode() .. ":" .. event:GetModifiers()
        event:Skip()
      end)
      map.lista:Connect(map.vista.wx.wxEVT_COMMAND_LIST_ITEM_ACTIVATED, function(event)
        traces[#traces + 1] = "activado:" .. event:GetIndex()
        event:Skip()
      end)
      local function press(vk, scan, extended, physical)
        local timed_out, timeout, input_error
        map.vista.dialogo:CallAfter(function()
          local sent, failure = xpcall(function()
            map.lista:SetFocus()
            local focus = map.vista.wx.wxWindow.FindFocus()
            equal(focus:GetId(), map.lista:GetId())
            local hwnd = ui.nativo.handle(map.lista)
            timeout = tempTimer(2, function()
              timeout, timed_out = nil, true
              map.cerrar()
            end)
            if physical then
              -- SendInput afecta al foco global: comprobar ambos HWND justo
              -- antes de inyectar y no intentar corregir un foco ajeno.
              assert(runtime.user32.GetForegroundWindow() == ui.nativo.handle(map.vista.dialogo),
                "Se omitió SendInput porque otra ventana está en primer plano")
              assert(runtime.user32.GetFocus() == hwnd, "Se omitió SendInput porque el foco no es la lista aislada")
              for _, modifier in ipairs({ vk, 16, 17, 18, 91, 92 }) do
                assert(runtime.user32.GetAsyncKeyState(modifier) >= 0, "Hay un modificador físico pulsado")
              end
              local inputs = runtime.ffi.new("RHOM_TEST_INPUT[2]")
              for i = 0, 1 do
                inputs[i].type = 1
                inputs[i].data.ki.wScan = scan
                inputs[i].data.ki.dwFlags = 8 + (extended and 1 or 0) + i * 2
              end
              traces[#traces + 1] = "SendInput:" .. vk .. ":" .. tostring(extended)
              equal(runtime.user32.SendInput(2, inputs, 40), 2)
            else
              local parameter = 1 + scan * 65536 + (extended and 16777216 or 0)
              traces[#traces + 1] = "PostMessage:" .. vk .. ":" .. tostring(extended)
              assert(runtime.user32.PostMessageW(hwnd, 256, vk, parameter) ~= 0)
              assert(runtime.user32.PostMessageW(hwnd, 257, vk, parameter + 3221225472) ~= 0)
            end
          end, debug.traceback)
          if not sent then input_error = failure; map.cerrar() end
        end)
        map.mostrar()
        if timeout then killTimer(timeout) end
        assert(not input_error, input_error)
        assert(not timed_out, "La tecla Windows no cerró el diálogo: " .. table.concat(traces, ", "))
      end
      local function process_steps()
        -- Devolver eventos reales a Qt dentro de un diálogo sin aceptar otro
        -- destino. El primer paso oficial llama a send en el perfil offline.
        map.vista.dialogo:CallAfter(function()
          tempTimer(0.1, function() map.cerrar() end)
        end)
        map.mostrar()
        RL_speed_walk_reset()
      end
      local checked, failure = xpcall(function()
        local before
        for _, numeric in ipairs({ false, true }) do
          map.recibir("RhomScripts destino sintético", numeric)
          before = #calls
          press(13, 28, numeric, RHOM_TEST_MAP_KEYBOARD == "sendinput")
          assert(#calls == before + 1, "SendInput Enter sin viaje: " .. table.concat(traces, ", "))
          process_steps()
          equal(commands[#commands], numeric and "sigilar norte" or "norte")
        end
        if RHOM_TEST_MAP_KEYBOARD == "sendinput" then
          map.recibir("RhomScripts destino sintético", false)
          before = #calls
          local sent = #commands
          press(27, 1, false, true)
          equal(#calls, before)
          equal(#commands, sent)
        end
      end, debug.traceback)
      capture_steps = false
      send = original_send
      RL_speed_walk_reset()
      map.vista.tecla, map.aceptar, map.vista.cancelar = key_handler, accept, cancel
      assert(checked, failure)
      case("Mapa teclado: " .. table.concat(traces, ", ") .. "; envíos: " .. table.concat(commands, ", "), function() end)
      calls = {}
    end)
    end
    case("Mapa real: aceptación nativa wxID_OK viaja sin snapshot previo y Cancel no viaja", function()
      map.recibir("RhomScripts destino sintético", false)
      local before = #calls
      sonidos = {}
      modal(function() map.vista:ocultar(map.vista.wx.wxID_OK) end)
      equal(sonidos[1], "rhom:catalogo:ui.abrir_mapa")
      equal(sonidos[2], "rhom:catalogo:ui.seleccionar_mapa")
      equal(#sonidos, 2)
      equal(#calls, before + 1)
      equal(calls[#calls].id, destination)
      modal(function() map.vista:ocultar(map.vista.wx.wxID_CANCEL) end)
      equal(#calls, before + 1)
      calls = {}
    end)
    case("Mapa real: alias oficial encuentra destinos sin imprimirlos en terminal", function()
      local before = getLastLineNumber("main")
      expandAlias("irsala RhomScripts destino sintético", false)
      equal(#map.estado().resultados, 1)
      equal(map.estado().resultados[1].id, destination)
      equal(getRoomName(destination), "RhomScripts destino sintético")
      equal(getLastLineNumber("main"), before)
      modal(function()
        equal(map.estado().pestana, 1)
        equal(map.lista:GetItemCount(), 1)
        assert(map.lista:GetItemText(0):find("RhomScripts destino sintético", 1, true))
        equal(getRoomName(destination), "RhomScripts destino sintético")
        map.aceptar()
        map.aceptar() -- Un segundo evento de aceptación no duplica la acción.
        equal(#calls, 0)
      end)
      assert(#calls == 1, "Viaje no ejecutado: " .. table.concat(readings, " / "))
      equal(calls[1].id, destination)
      equal(calls[1].sigilar, false)
    end)
    case("Mapa real: alias sigiloso conserva modo y ejecuta el motor oficial una vez", function()
      expandAlias("sigilarsala RhomScripts destino sintético", false)
      sonidos = {}
      modal(function() map.aceptar() end)
      equal(sonidos[1], "rhom:catalogo:ui.abrir_mapa")
      equal(sonidos[2], "rhom:catalogo:ui.seleccionar_mapa")
      equal(#sonidos, 2)
      equal(#calls, 2)
      equal(calls[2].id, destination)
      equal(calls[2].sigilar, true)
    end)
    case("Mapa real: botones reutilizados quitan y añaden favoritos sin iniciar viajes", function()
      local before = #calls
      map.componente:seleccionar_pestana("favoritos")
      modal(function()
        local componente, wx = map.componente, map.vista.wx
        map.lista:SetFocus()
        assert(componente:tecla(wx.WXK_RIGHT, 0))
        equal(wx.wxWindow.FindFocus():GetId(), componente.botones[1]:GetId())
        assert(componente:tecla(wx.WXK_UP, 0))
        equal(componente.botones[1]:GetLabel(), "Eliminar de favoritos")
        local n = #readings
        assert(componente:tecla(wx.WXK_RETURN, 0))
        equal(#readings, n + 1)
        equal(readings[#readings], "Eliminado de favoritos.")
        equal(#map.estado().favoritos, 0)
        equal(wx.wxWindow.FindFocus():GetId(), map.lista:GetId())
        equal(#calls, before)
        map.cerrar()
      end)
      map.recibir("RhomScripts destino sintético", false)
      modal(function()
        local componente, wx = map.componente, map.vista.wx
        equal(map.estado().pestana, 1)
        map.lista:SetFocus()
        assert(componente:tecla(wx.WXK_RIGHT, 0))
        assert(componente:tecla(wx.WXK_RETURN, 0))
        equal(#map.estado().favoritos, 1)
        local boton = componente.botones[1]
        assert(boton:IsShown() and boton:IsEnabled())
        equal(boton:GetLabel(), "Eliminar de favoritos")
        equal(wx.wxWindow.FindFocus():GetId(), boton:GetId())
        local n = #readings
        assert(componente:tecla(wx.WXK_RETURN, 0))
        equal(#readings, n + 1)
        equal(readings[#readings], "Eliminado de favoritos.")
        equal(map.lista:GetItemCount(), 1)
        equal(#map.estado().favoritos, 0)
        equal(boton:GetLabel(), "Añadir a favoritos")
        equal(wx.wxWindow.FindFocus():GetId(), boton:GetId())
        assert(componente:tecla(wx.WXK_RETURN, 0))
        equal(#map.estado().favoritos, 1)
        equal(boton:GetLabel(), "Eliminar de favoritos")
        equal(#calls, before)
        map.cerrar()
      end)
    end)
    case("Mapa real: cambiar personaje refresca favoritos y eliminar borra solo los propios del JSON", function()
      local destino = map.estado().favoritos[1]
      assert(destino)
      map.componente:seleccionar_pestana("favoritos")
      modal(function()
        gmcp = { Char = { Ficha = { nombre = "Personaje B" } } }
        raiseEvent("gmcp.Char", "gmcp.Char.Ficha")
        equal(require("ficha").obtener("nombre"), "Personaje B")
        equal(map.lista:GetItemCount(), 0)
        assert(map.agregar_favorito(destino))
        equal(map.lista:GetItemCount(), 1)
        gmcp.Char.Ficha.nombre = "Personaje A"
        raiseEvent("gmcp.Char", "gmcp.Char.Ficha")
        equal(map.lista:GetItemCount(), 1)
        assert(map.eliminar_favorito(destino))
        equal(map.lista:GetItemCount(), 0)
        local file = assert(io.open(favorite_path, "rb"))
        local guardados = yajl.to_value(file:read("*a")); file:close()
        equal(#guardados.personajes["Personaje A"], 0)
        equal(guardados.personajes["Personaje B"][1].id, destino.id)
        assert(map.agregar_favorito(destino))
        gmcp.Char.Ficha.nombre = nil
        raiseEvent("gmcp.Char", "gmcp.Char.Ficha")
        equal(map.lista:GetItemCount(), 0)
        equal(map.agregar_favorito(destino), false)
        gmcp.Char.Ficha.nombre = "Personaje B"
        raiseEvent("gmcp.Char", "gmcp.Char.Ficha")
        equal(map.lista:GetItemCount(), 1)
        assert(map.eliminar_favorito(destino))
        gmcp.Char.Ficha.nombre = "Personaje A"
        raiseEvent("gmcp.Char", "gmcp.Char.Ficha")
        equal(map.lista:GetItemCount(), 1)
        map.cerrar()
      end)
    end)
    case("Mapa real: salidas reordenadas y marcas de puertas permiten viajar al destino encontrado", function()
      setRoomName(destination, "RhomScripts destino sintético [s,|n|]")
      expandAlias("irsala RhomScripts destino sintético [n,s]", false)
      equal(#map.estado().resultados, 1)
      modal(function() map.aceptar() end)
      equal(#calls, 3)
      equal(calls[3].id, destination)
      setRoomName(destination, "RhomScripts destino sintético")
    end)
    case("Mapa real: evento de reinstalación oficial repone el adaptador sin envolverlo dos veces", function()
      RL_mostrar_links_viaje_room = present
      raiseEvent("sysInstallPackage", "OtroPaquete")
      equal(RL_mostrar_links_viaje_room, present)
      raiseEvent("sysInstallPackage", "RLMud_Config")
      assert(RL_mostrar_links_viaje_room ~= present)
      local replacement = RL_mostrar_links_viaje_room
      raiseEvent("sysInstallPackage", "RLMud_Config")
      equal(RL_mostrar_links_viaje_room, replacement)
    end)
    case("Mapa real: favorito cambiado no inicia viaje", function()
      setRoomName(destination, "RhomScripts sala reasignada")
      map.recibir("RhomScripts sin coincidencias", false)
      map.componente:seleccionar_pestana("favoritos")
      modal(function()
        equal(map.estado().pestana, 2)
        map.aceptar()
      end)
      equal(#calls, 3)
      setRoomName(destination, "RhomScripts destino sintético")
    end)
    case("Mapa real: recarga descarta resultados y conserva favoritos y adaptación única", function()
      map.recibir("RhomScripts destino sintético", false)
      equal(#map.estado().resultados, 1)
      local old, wx = map, map.vista.wx
      local destroyed = false
      old.vista.dialogo:Connect(wx.wxEVT_DESTROY, function(event)
        destroyed = true
        event:Skip()
      end)
      dofile(root .. "/rhomscripts/init.lua")
      map = RhomScripts.modules.mapa
      assert(old ~= map and destroyed)
      equal(#map.estado().resultados, 0)
      equal(#map.estado().favoritos, 1)
      assert(not map.vista.dialogo:IsShown())
      config = RhomScripts.modules.configuracion
    end)
    case("Mapa real: desactivar restaura función oficial y Cancelar no la sustituye", function()
      config.set("mapa_destinos", false)
      map.aplicar_configuracion()
      equal(RL_mostrar_links_viaje_room, present)
      local session = RhomScripts.modules.configurador.nueva_sesion()
      session:cambiar("mapa_destinos", 1)
      equal(config.get("mapa_destinos"), false)
      equal(RL_mostrar_links_viaje_room, present)
      assert(session:guardar())
      equal(config.get("mapa_destinos"), true)
      assert(RL_mostrar_links_viaje_room ~= present)
    end)
  end, debug.traceback)
  announce = speak
  playSoundFile = reproducir
  RL_speed_walk_to, RL_speed_walk_sigilar_to = walk, sneak
  RL_speed_walk_reset()
  RL_vars.mapa.actual = current
  config = RhomScripts.modules.configuracion
  config.set("mapa_destinos", previous_option)
  gmcp = gmcp_anterior
  require("ficha").detener()
  require("ficha").iniciar(ficha_anterior)
  assert(config.save())
  os.remove(favorite_path)
  dofile(root .. "/rhomscripts/init.lua")
  for _, id in ipairs(created) do deleteRoom(id) end
  assert(ok, message)
end
-- Apertura automática real después de cerrar otro diálogo modal.
function suite.automatic(case, done)
  local map = RhomScripts.modules.mapa
  local config = RhomScripts.modules.configuracion
  local configurator = RhomScripts.modules.configurador
  local previous = config.get("mapa_destinos")
  local fired = false
  local id = createRoomID()
  assert(addRoom(id, -1))
  setRoomName(id, "RhomScripts apertura pospuesta con resultados")
  local function complete(ok, message)
    local cleaned, cleanup_error = pcall(function()
      deleteRoom(id)
      config.set("mapa_destinos", previous)
      assert(config.save())
      map.aplicar_configuracion()
    end)
    if not cleaned then done(false, cleanup_error) else done(ok, message) end
  end
  local ok, message = xpcall(function()
    local session = configurator.nueva_sesion()
    if not session:get("mapa_destinos") then session:cambiar("mapa_destinos", 1) end
    assert(session:guardar())
    map.vista.dialogo:Connect(map.vista.wx.wxEVT_SHOW, function(event)
      event:Skip()
      if fired or not map.vista.dialogo:IsShown() then return end
      fired = true
      map.vista.dialogo:CallAfter(function()
        local checked, failure = xpcall(function()
          case("Mapa real: apertura automática con resultados espera al cierre del configurador", function()
            assert(not configurator.activo and map.vista.mostrando)
            equal(map.estado().pestana, 1)
            equal(map.lista:GetItemCount(), 1)
          end)
        end, debug.traceback)
        map.cerrar()
        tempTimer(0, function() complete(checked, failure) end)
      end)
    end)
    configurator.ventana:CallAfter(function()
      local checked, failure = xpcall(function()
        assert(configurator.activo)
        map.recibir("RhomScripts destino inexistente para apertura pospuesta", false)
        case("Mapa real: búsqueda vacía no programa apertura", function()
          equal(map.lista:GetItemCount(), 0)
          assert(not map.vista.mostrando)
        end)
        map.recibir("RhomScripts apertura pospuesta con resultados", false)
        assert(not map.vista.mostrando, "Se abrió un segundo diálogo encima del configurador")
      end, debug.traceback)
      configurator.cerrar()
      if not checked then tempTimer(0, function() complete(false, failure) end) end
    end)
    configurator.abrir()
    assert(not fired, "La ventana de destinos se abrió antes de retornar el configurador")
  end, debug.traceback)
  if not ok then complete(false, message) end
end
return suite
