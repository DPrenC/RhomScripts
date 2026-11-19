-- luacheck: globals RHOM_WX_ROOT RHOM_WX_RESULT RHOM_WX_PROFILE getMudletVersion io.open
-- UI wx y eventos Mudlet reales; datos sintéticos, perfil aislado sin servidor.
local root = RHOM_WX_ROOT
assert(getMudletHomeDir() == RHOM_WX_PROFILE, "Perfil ajeno al ensayo")
RhomScripts = { root = root .. "/rhomscripts", modules = {} }
RhomScripts.modules.debug = assert(loadfile(RhomScripts.root .. "/debug.lua"))()
package.path = RhomScripts.root .. "/?.lua;" .. package.path
local results, timers, finished = {}, {}, false
local ticks = 0
local config = require("configuracion")
assert(config.load())
local audio = require("audio")
assert(audio.iniciar().estado == "cargado")
require("arranque").bibliotecas()
local c = require("comunicaciones")
local ui = require("ui")
local function case(name, action)
  action()
  results[#results + 1] = name
end
local function after(delay, action)
  local id
  id = tempTimer(delay, function() timers[id] = nil; action() end)
  timers[id] = true
end
local function beat()
  if finished then return end
  ticks = ticks + 1
  after(0.05, beat)
end
local function equal(actual, expected)
  assert(actual == expected, "Esperado " .. tostring(expected) .. "; obtenido " .. tostring(actual))
end
local function con_dialogo(historial, action)
  local completed, message
  local view = historial.vista
  view.dialogo:CallAfter(function()
    after(0.1, function()
      completed, message = xpcall(action, debug.traceback)
      view.cancelar()
    end)
  end)
  historial.mostrar_historial()
  assert(completed, message or "El diálogo no ejecutó la comprobación")
end
local function capturar_avisos(action)
  local lector = require("lector")
  local sounds, readings = {}, {}
  local reproduce, speak = audio.reproducir, lector.verbalizar
  audio.reproducir = function(key, options)
    sounds[#sounds + 1] = key
    return reproduce(key, options)
  end
  lector.verbalizar = function(text, priority)
    equal(priority, lector.prioridades.ALTA)
    readings[#readings + 1] = text
    return speak(text, priority)
  end
  local ok, message = xpcall(function() action(sounds, readings) end, debug.traceback)
  audio.reproducir, lector.verbalizar = reproduce, speak
  assert(ok, message)
end
local function feed(line)
  assert(feedTriggers(line .. "\n"))
end
local function comprobar_apertura()
  local lector = require("lector")
  local mensajes, original = {}, lector.verbalizar
  local sonidos, reproducir = {}, playSoundFile
  playSoundFile = function(settings)
    sonidos[#sonidos + 1] = settings.key
    return reproducir(settings)
  end
  lector.verbalizar = function(texto, prioridad)
    mensajes[#mensajes + 1] = { texto = texto, prioridad = prioridad }
    return original(texto, prioridad)
  end
  local ok, message = pcall(c.mostrar_historial)
  lector.verbalizar = original
  playSoundFile = reproducir
  assert(ok, message)
  equal(#mensajes, 0)
  equal(#sonidos, 2)
  equal(sonidos[1], "rhom:catalogo:ui.abrir_com")
  equal(sonidos[2], "rhom:catalogo:ui.cerrar_com")
  equal(c.vista.dialogo:GetTitle(), "Historial de canales")
end
local function run()
  case("Modelo compartido con announce real, datos sintéticos y sin portapapeles", function()
    dofile(root .. "/scripts/tests/comunicaciones.lua").run(case, root .. "/rhomscripts/comunicaciones.lua")
  end)
  case("Ventana preparada oculta con lista nativa reutilizable", function()
    c.preparar()
    assert(c.vista and c.lista and c.pestanyas)
    assert(not c.vista.dialogo:IsShown())
    local view, list = c.vista, c.lista
    c.preparar()
    equal(c.vista, view)
    equal(c.lista, list)
  end)
  local window, list = c.vista.dialogo, c.lista
  case("Sin canales abiertos Tab y atajos de cambio reproducen Límite", function()
    local sounds, original = {}, audio.reproducir
    audio.reproducir = function(key, options)
      sounds[#sounds + 1] = key
      return original(key, options)
    end
    local ok, message = pcall(function()
      equal(c.vista.tab(1), false)
      equal(c.vista.tab(-1), false)
      assert(c.tecla(string.byte(","), c.vista.wx.wxMOD_CONTROL))
      assert(c.tecla(string.byte("."), c.vista.wx.wxMOD_CONTROL))
      equal(#sounds, 4)
      for _, key in ipairs(sounds) do equal(key, "ui.limite") end
      equal(c.estado().seleccion, "global")
    end)
    audio.reproducir = original
    assert(ok, message)
    local callback_error
    window:CallAfter(function()
      local accepted, error_text = pcall(function()
        equal(c.estado_texto:GetLabel(), "Todos los canales apagados")
        equal(list:GetName(), "Todos los canales apagados")
      end)
      if not accepted then callback_error = error_text end
      c.cerrar()
    end)
    comprobar_apertura()
    assert(not callback_error, callback_error)
  end)
  case("Global y canales vacíos presentan nombre y aviso de límite", function()
    equal(c.pestanyas:GetPageText(0), "global")
    equal(list:GetName(), "Todos los canales apagados")
    equal(c.estado_texto:GetLabel(), "Todos los canales apagados")
    equal(c.leer_ultimo(), "No hay mensajes en el canal global")
    c.abrir_canal("vacio", true)
    c.cambiar_categoria(1)
    equal(list:GetName(), "No hay mensajes en el canal vacio")
    equal(window:GetTitle(), "Historial de canales")
    assert(c.texto_estado:find("No hay mensajes en el canal vacio", 1, true))
    local sounds, original = {}, audio.reproducir
    audio.reproducir = function(key, options)
      if key == "ui.limite" then sounds[#sounds + 1] = key end
      return original(key, options)
    end
    local ok, message = pcall(function()
      con_dialogo(c, function()
      assert(c.tecla(c.vista.wx.WXK_UP, 0))
      assert(c.tecla(c.vista.wx.WXK_DOWN, 0))
      equal(#sounds, 2)
      equal(sounds[1], "ui.limite")
      equal(sounds[2], "ui.limite")
      end)
    end)
    audio.reproducir = original
    assert(ok, message)
    c.cerrar_canal("vacio", true)
  end)
  case("Altas y bajas usan los sonidos de Comunicaciones sin duplicar transiciones", function()
    local sounds, original = {}, audio.reproducir
    audio.reproducir = function(key, options)
      equal(options and options.grupo, nil)
      sounds[#sounds + 1] = key
      return original(key, options)
    end
    local ok, message = pcall(function()
      c.abrir_canal("sonido")
      c.abrir_canal("sonido")
      c.cerrar_canal("sonido")
      c.cerrar_canal("sonido")
      c.reconciliar({ sonido = {} })
      c.reconciliar({})
      for index = 1, 30 do
        gmcp = { Comm = { EnciendeCanal = { canal = "lote" .. index } } }
        raiseEvent("gmcp.Comm.EnciendeCanal")
      end
      equal(c.pestanyas:GetPageCount(), 31)
      for index = 1, 30 do
        gmcp.Comm.ApagaCanal = { canal = "lote" .. index }
        raiseEvent("gmcp.Comm.ApagaCanal")
      end
      equal(c.pestanyas:GetPageCount(), 1)
      equal(c.pestanyas:GetPageText(0), "global")
      equal(#sounds, 2)
      equal(sounds[1], "comunicaciones.canal_on")
      equal(sounds[2], "comunicaciones.canal_off")
    end)
    audio.reproducir = original
    assert(ok, message)
  end)
  case("El filtro de nombres genéricos solo se aplica a altas y bajas individuales", function()
    gmcp = { Comm = { Canales = { alianza = "alianza" } } }
    raiseEvent("gmcp.Comm.Canales")
    local genericos = { "bando", "ciu", "clan", "gremio" }
    for _, id in ipairs(genericos) do
      gmcp.Comm.EnciendeCanal = { canal = id }
      raiseEvent("gmcp.Comm.EnciendeCanal")
      equal(c.estado().canales[id], nil)
      gmcp.Comm.Canales[id] = id
    end
    equal(c.pestanyas:GetPageCount(), 2)
    equal(c.pestanyas:GetPageText(1), "alianza")

    raiseEvent("gmcp.Comm.Canales")
    for _, id in ipairs(genericos) do
      gmcp.Comm.ApagaCanal = { canal = id }
      raiseEvent("gmcp.Comm.ApagaCanal")
      assert(c.estado().canales[id].abierto)
    end
    equal(c.pestanyas:GetPageCount(), 6)
    gmcp.Comm.Canales = {}
    raiseEvent("gmcp.Comm.Canales")
    equal(c.pestanyas:GetPageCount(), 1)
  end)
  case("Altas y recepción por manejadores reales sin interfaz oficial instalada", function()
    gmcp = { Comm = { Canales = { chat = {}, ciudadania = {} } } }
    raiseEvent("gmcp.Comm.Canales")
    gmcp.Comm.MensajeCanal = { canal = "chat", mensaje = "Primero del chat" }
    raiseEvent("gmcp.Comm.MensajeCanal")
    equal(c.estado().cantidad, 1)
    equal(c.lista:GetItemCount(), 1)
    c.cambiar_categoria(1)
    equal(c.estado().seleccion, "chat")
    equal(c.lista, list)
    assert(not c.botones[1]:IsEnabled() and not c.botones[2]:IsEnabled())
    assert(c.botones[3]:IsEnabled(), "Copiar debe estar disponible para el mensaje seleccionado")
    c.alternar_silencio()
    c.alternar_silencio()
    equal(list:GetItemCount(), 1)
    gmcp.Comm.MensajeCanal = { canal = "ciudadania", mensaje = "Otro canal no duplica chat" }
    raiseEvent("gmcp.Comm.MensajeCanal")
    equal(list:GetItemCount(), 1)
  end)
  beat()
  local callback_error, qt_delivered = nil, false
  local before_ticks = ticks
  window:CallAfter(function()
    local ok, message = xpcall(function()
      assert(window:IsShown() and ui.ocupada())
      -- El callback de Qt debe ejecutarse dentro del diálogo modal wx.
      after(0.3, function()
        local accepted, error_text = xpcall(function()
          qt_delivered = true
          local focus = c.vista.wx.wxWindow.FindFocus()
          assert(focus and focus:GetId() == list:GetId(), "Lista no recibe foco inicial; obtenido=" .. (focus and focus:GetName() or "ninguno") .. "; esperado=" .. list:GetName())
          assert(ticks > before_ticks, "Qt dejó de procesar temporizadores")
          local selected = c.estado().selecciones.chat
          gmcp.Comm.MensajeCanal = { canal = "chat", mensaje = "Llegada durante ShowModal" }
          raiseEvent("gmcp.Comm.MensajeCanal")
          equal(list:GetItemCount(), 2)
          equal(c.estado().seleccion, "chat")
          equal(c.lista, list)
          local messages = c.estado().canales.chat.mensajes
          equal(list:GetItemData(0), messages[2].id)
          equal(list:GetItemData(1), messages[1].id)
          equal(c.estado().selecciones.chat, selected)
          assert(list:GetItemState(1, c.vista.wx.wxLIST_STATE_SELECTED) ~= 0,
            "La llegada desplazó la selección a otro mensaje")
          c.vista.cancelar()
        end, debug.traceback)
        if not accepted then callback_error = error_text; c.vista.cancelar() end
      end)
    end, debug.traceback)
    if not ok then callback_error = message; c.vista.cancelar() end
  end)
  c.mostrar_historial()
  assert(not callback_error, callback_error)
  assert(qt_delivered, "El diálogo retornó sin recibir evento Qt")
  results[#results + 1] = "Qt sigue activo y GMCP actualiza la lista durante ShowModal"
  case("Tras la ráfaga vuelve a sonar una operación independiente y detener cancela avisos", function()
    local sounds, original = {}, audio.reproducir
    audio.reproducir = function(key, options)
      sounds[#sounds + 1] = key
      return original(key, options)
    end
    local ok, message = pcall(function()
      c.abrir_canal("posterior")
      c.cerrar_canal("posterior")
      equal(#sounds, 2)
      c.detener()
      c.iniciar()
      c.abrir_canal("posterior")
      c.cerrar_canal("posterior")
      equal(#sounds, 4)
    end)
    audio.reproducir = original
    assert(ok, message)
  end)
  case("Cerrar conserva categoría y lista; reabrir reutiliza controles", function()
    equal(c.estado().seleccion, "chat")
    equal(c.lista, list)
    assert(not window:IsShown())
    window:CallAfter(function() c.vista.cancelar() end)
    comprobar_apertura()
    equal(c.vista.dialogo, window)
    equal(c.lista, list)
    equal(c.estado().seleccion, "chat")
    equal(list:GetItemCount(), 2)
    local messages = c.estado().canales.chat.mensajes
    equal(list:GetItemData(0), messages[2].id)
    equal(list:GetItemData(1), messages[1].id)
  end)
  case("Tab y atajos locales comparten categoría, último mensaje y silencio", function()
    c.vista.tab(1)
    equal(c.estado().seleccion, "ciudadania")
    equal(window:GetTitle(), "Historial de canales")
    c.vista.tab(-1)
    equal(c.estado().seleccion, "chat")
    local wx = c.vista.wx
    assert(not c.tecla(string.byte("S"), wx.wxMOD_CONTROL + wx.wxMOD_SHIFT))
    capturar_avisos(function(_, readings)
      assert(c.tecla(wx.WXK_F1, wx.wxMOD_CONTROL))
      equal(c.estado().canales.chat.silenciado, true)
      assert(c.tecla(wx.WXK_F1, wx.wxMOD_CONTROL))
      equal(c.estado().canales.chat.silenciado, false)
      equal(readings[1], "canal chat, silenciado.")
      equal(readings[2], "canal chat, lectura activada.")
    end)
    assert(c.tecla(wx.WXK_F1, wx.wxMOD_CONTROL))
    equal(c.estado().canales.chat.silenciado, true)
    assert(c.tecla(wx.WXK_F1, wx.wxMOD_ALT))
    assert(c.tecla(string.byte("."), wx.wxMOD_CONTROL))
    equal(c.estado().seleccion, "ciudadania")
    assert(c.tecla(string.byte(","), wx.wxMOD_CONTROL))
    equal(c.estado().seleccion, "chat")
    equal(list:GetItemCount(), 2)
  end)
  case("Flechas suenan solo al intentar rebasar los extremos", function()
    local wx = c.vista.wx
    local state = wx.wxLIST_STATE_SELECTED + wx.wxLIST_STATE_FOCUSED
    local sounds, original = {}, audio.reproducir
    audio.reproducir = function(key, options)
      if key == "ui.limite" then sounds[#sounds + 1] = key end
      return original(key, options)
    end
    local ok, message = pcall(function()
      con_dialogo(c, function()
      list:SetItemState(0, state, state)
      assert(c.tecla(wx.WXK_UP, 0))
      assert(not c.tecla(wx.WXK_DOWN, 0))
      list:SetItemState(1, state, state)
      assert(c.tecla(wx.WXK_DOWN, 0))
      assert(not c.tecla(wx.WXK_UP, 0))
      equal(#sounds, 2)
      equal(sounds[1], "ui.limite")
      equal(sounds[2], "ui.limite")
      equal(list:GetItemCount(), 2)
      end)
    end)
    audio.reproducir = original
    assert(ok, message)
  end)
  case("Orden descendente conserva selección y retira mensajes antiguos al final", function()
    local previous = config.get("canales_limite")
    config.set("canales_limite", 100)
    for index = 1, 105 do c.recibir({canal = "chat", mensaje = "Orden " .. index}) end
    equal(list:GetItemCount(), 100)
    local messages = c.estado().canales.chat.mensajes
    for index = 0, 99 do equal(list:GetItemData(index), messages[100 - index].id) end
    local flag = c.vista.wx.wxLIST_STATE_SELECTED + c.vista.wx.wxLIST_STATE_FOCUSED
    list:SetItemState(50, flag, flag)
    local selected = c.estado().selecciones.chat
    c.recibir({canal = "chat", mensaje = "Nuevo arriba"})
    equal(c.estado().selecciones.chat, selected)
    equal(list:GetItemData(51), selected)
    assert(list:GetItemState(51, c.vista.wx.wxLIST_STATE_SELECTED) ~= 0)
    equal(list:GetItemCount(), 100)
    config.set("canales_limite", previous)
  end)
  case("Reabrir lleva al inicio la lista actual y la primera visita a otra pestaña", function()
    local wx = c.vista.wx
    local flag = wx.wxLIST_STATE_SELECTED + wx.wxLIST_STATE_FOCUSED
    c.cambiar_categoria(-1)
    list:SetItemState(50, flag, flag)
    c.cambiar_categoria(1)
    assert(list:EnsureVisible(51))
    assert(list:GetTopItem() > 0, "La prueba debe empezar con la lista desplazada")

    local ok, message
    window:CallAfter(function()
      ok, message = xpcall(function()
        equal(c.estado().seleccion, "chat")
        equal(list:GetTopItem(), 0)
        equal(list:GetItemState(0, flag), flag)
        equal(c.estado().selecciones.chat, list:GetItemData(0))
        c.cambiar_categoria(-1)
        equal(c.estado().seleccion, "global")
        equal(list:GetTopItem(), 0)
        equal(list:GetItemState(0, flag), flag)
        equal(c.estado().selecciones.global, list:GetItemData(0))
        c.cambiar_categoria(1)
      end, debug.traceback)
      c.vista.cancelar()
    end)
    c.mostrar_historial()
    assert(ok, message)
  end)
  case("Botones contextuales conservan mensaje y foco durante llegadas; Copiar no abre detalle", function()
    con_dialogo(c, function()
      local wx = c.vista.wx
      local list_size = c.lista:GetClientSize()
      assert(list_size:GetWidth() > 100 and list_size:GetHeight() > 100, "La lista debe ocupar una superficie útil")
      local page = c.pestanyas:GetPage(c.pestanyas:GetSelection())
      local page_size = page:GetClientSize()
      assert(page_size:GetWidth() > 100 and page_size:GetHeight() > 100, "La pestaña debe mostrar su contenido")
      local button_size = c.botones[3]:GetClientSize()
      assert(button_size:GetWidth() > 0 and button_size:GetHeight() > 0 and c.botones[3]:IsShown(), "El botón Copiar debe ser visible")
      local selected = c.componente:seleccionado()
      assert(selected and selected.datos.texto)
      local id, text = selected.id, selected.datos.texto
      local clipboard, copied, details = setClipboardText, {}, 0
      local show = c.detalle.mostrar
      setClipboardText = function(value) copied[#copied + 1] = value end
      c.detalle.mostrar = function() details = details + 1 end
      local ok, message = xpcall(function()
        c.lista:SetFocus()
        assert(c.tecla(wx.WXK_RIGHT, 0))
        local focus = wx.wxWindow.FindFocus()
        assert(focus and focus:GetId() == c.botones[3]:GetId(), "Derecha debe saltar respuestas no disponibles")
        assert(c.tecla(wx.WXK_UP, 0) and c.tecla(wx.WXK_DOWN, 0))
        equal(c.componente:seleccionado().id, id)
        c.recibir({ canal = "chat", mensaje = "Nueva llegada mientras se enfoca Copiar" })
        equal(c.componente:seleccionado().id, id)
        focus = wx.wxWindow.FindFocus()
        assert(focus and focus:GetId() == c.botones[3]:GetId(), "La actualización robó el foco del botón")
        assert(c.tecla(wx.WXK_RETURN, 0))
        equal(#copied, 1)
        equal(copied[1], text)
        equal(details, 0)
        assert(c.tecla(wx.WXK_LEFT, 0))
        focus = wx.wxWindow.FindFocus()
        assert(focus and focus:GetId() == c.lista:GetId())
      end, debug.traceback)
      setClipboardText, c.detalle.mostrar = clipboard, show
      assert(ok, message)
    end)
  end)
  case("Pestañas nativas por clic y Tab usan el mismo contenido y recuerdan la categoría", function()
    con_dialogo(c, function()
      local page = c.pestanyas:GetSelection()
      c.pestanyas:SetSelection(page == 0 and 1 or 0)
      equal(c.componente.pestana, c.estado().seleccion)
      equal(c.pestanyas:GetPageText(c.pestanyas:GetSelection()), c.estado().seleccion)
      c.vista.tab(1)
      equal(c.componente.pestana, c.estado().seleccion)
    end)
    local category = c.estado().seleccion
    con_dialogo(c, function()
      equal(c.estado().seleccion, category)
      local selected = c.componente:seleccionado()
      if selected then equal(selected.id, c.lista:GetItemData(0)) end
    end)
    -- Continuar el ensayo de retención sobre el canal concreto de la prueba.
    while c.estado().seleccion ~= "chat" do c.cambiar_categoria(1) end
  end)
  case("Retirar el mensaje de un botón devuelve el foco a la lista sin copiar otro mensaje", function()
    local previous = config.get("canales_limite")
    config.set("canales_limite", 100)
    c.aplicar_limites()
    con_dialogo(c, function()
      local wx = c.vista.wx
      local last = c.lista:GetItemCount() - 1
      local flag = wx.wxLIST_STATE_SELECTED + wx.wxLIST_STATE_FOCUSED
      c.lista:SetItemState(last, flag, flag)
      local old = c.componente:seleccionado().id
      c.lista:SetFocus()
      assert(c.tecla(wx.WXK_RIGHT, 0))
      c.recibir({ canal = "chat", mensaje = "El límite retira el mensaje asociado al botón" })
      assert(c.componente:seleccionado().id ~= old)
      local focus = wx.wxWindow.FindFocus()
      assert(focus and focus:GetId() == c.lista:GetId(), "Al retirar el mensaje debe abandonarse su botón")
      equal(c.estado().selecciones.chat, c.componente:seleccionado().id)
    end)
    config.set("canales_limite", previous)
  end)
  case("Enter abre detalle nativo readonly estable y retorna al mismo historial", function()
    con_dialogo(c, function()
      local element = c.componente:seleccionado()
      assert(element)
      local snapshot = element.datos.texto
      local detail, checked, failure = c.detalle, false, nil
      detail.vista.dialogo:CallAfter(function()
        checked, failure = xpcall(function()
          assert(detail.vista.dialogo:IsShown())
          equal(detail.control:GetValue(), snapshot)
          assert(not detail.control:IsEditable(), "El detalle debe ser solo lectura")
          c.recibir({ canal = "chat", mensaje = "Otro mensaje con el detalle abierto" })
          equal(detail.control:GetValue(), snapshot)
        end, debug.traceback)
        detail:cerrar()
      end)
      c.lista:SetFocus()
      assert(c.tecla(c.vista.wx.WXK_RETURN, 0))
      assert(checked, failure or "No se abrió el detalle")
      assert(c.vista.dialogo:IsShown() and not detail.vista.dialogo:IsShown())
      equal(c.componente:seleccionado().id, element.id)
    end)
  end)
  case("Todos apagados se muestra incluso conservando mensajes anteriores", function()
    local count = c.estado().cantidad
    for _, id in ipairs(c.estado().categorias) do
      if id ~= "global" then
        gmcp.Comm.ApagaCanal = { canal = id }
        raiseEvent("gmcp.Comm.ApagaCanal")
      end
    end
    equal(#c.estado().categorias, 1)
    equal(c.estado_texto:GetLabel(), "Todos los canales apagados")
    equal(list:GetName(), "Todos los canales apagados")
    equal(list:GetItemCount(), count)
    equal(c.pestanyas:GetPageCount(), 1)
    equal(c.pestanyas:GetPageText(0), "global")
  end)
  case("Desconectar descarta mensajes y silencio sin destruir controles", function()
    raiseEvent("sysDisconnectionEvent")
    equal(c.estado().cantidad, 0)
    equal(c.estado().seleccion, "global")
    equal(list:GetItemCount(), 0)
    equal(c.lista, list)
    c.abrir_canal("chat", true)
    equal(c.estado().canales.chat.silenciado, false)
  end)
  case("El temporizador real permite otro aviso histórico del mismo canal tras la pausa", function()
    c.abrir_canal("bueno", true)
    c.alternar_silencio()
    local bando, original = 0, audio.reproducir
    audio.reproducir = function(key, options)
      if key == "comunicaciones.bando" then bando = bando + 1 end
      return original(key, options)
    end
    local function historico()
      gmcp.Comm.MensajeCanalHistorico = { canal = "bueno", mensaje = "Histórico de bando" }
      raiseEvent("gmcp.Comm.MensajeCanalHistorico")
    end
    local finalizado, fallo = false, nil
    local ok, message = xpcall(function()
      historico()
      historico()
      equal(bando, 1)
      after(0.35, function()
        finalizado, fallo = xpcall(function()
          historico()
          equal(bando, 2)
          equal(c.estado().canales.bueno.cantidad, 3)
        end, debug.traceback)
        c.vista.cancelar()
      end)
      c.mostrar_historial()
    end, debug.traceback)
    audio.reproducir = original
    assert(ok, message)
    assert(finalizado, fallo or "El temporizador de comprobación no se ejecutó")
  end)
  local room, tel = c.historiales.room, c.historiales.telepatia
  case("Room y telepatía preparan ventanas independientes con sus controles nativos", function()
    assert(room.vista.dialogo ~= tel.vista.dialogo and room.vista.dialogo ~= window and tel.vista.dialogo ~= window)
    assert(room.lista ~= tel.lista and room.lista ~= list and tel.lista ~= list)
    assert(not room.vista.dialogo:IsShown() and not tel.vista.dialogo:IsShown())
    equal(room.vista.dialogo:GetTitle(), "Historial Room")
    equal(tel.vista.dialogo:GetTitle(), "Historial de telepatía")
    equal(room.pestanyas:GetPageCount(), 3)
    equal(room.pestanyas:GetPageText(0), "global")
    equal(room.pestanyas:GetPageText(1), "Jugadores")
    equal(room.pestanyas:GetPageText(2), "PNJs")
    equal(tel.pestanyas, nil)
  end)
  case("Los triggers reales separan Room y telepatía y avisan una vez por mensaje", function()
    local channel_count = c.estado().cantidad
    local room_line = "La capitana dice: A las tres: ven."
    local tel_line = "Ariadna te dice: Mensaje privado: hola."
    local whisper = "Ariadna te susurra: En secreto."
    local historical = "2026-11-11 (21:05) - Ariadna te dijo: Mensaje histórico: hola."
    local quoted = "La capitana dice: Ariadna te dice: Ven."
    capturar_avisos(function(sounds, readings)
      feed(room_line)
      feed(tel_line)
      feed("[Chat] Ariadna dice: No es Room.")
      feed("Dices: No es una llegada.")
      feed(whisper)
      feed(room_line)
      feed(historical)
      feed(quoted)
      equal(#sounds, 6)
      equal(sounds[1], "comunicaciones.room")
      equal(sounds[2], "comunicaciones.telepatia")
      equal(sounds[3], "comunicaciones.room")
      equal(sounds[4], "comunicaciones.room")
      equal(sounds[5], "comunicaciones.telepatia")
      equal(sounds[6], "comunicaciones.room")
      equal(#readings, 6)
      equal(readings[1], room_line)
      equal(readings[2], tel_line)
      equal(readings[3], whisper)
      equal(readings[4], room_line)
      equal(readings[5], historical)
      equal(readings[6], quoted)
    end)
    local room_messages, tel_messages = room.estado().mensajes, tel.estado().mensajes
    equal(#room_messages, 4)
    equal(#tel_messages, 2)
    equal(room_messages[1].texto, room_line)
    equal(room_messages[2].texto, whisper)
    equal(room_messages[3].texto, room_line)
    equal(room_messages[4].texto, quoted)
    assert(room_messages[1].id ~= room_messages[3].id)
    equal(tel_messages[1].texto, tel_line)
    equal(tel_messages[2].texto, historical)
    equal(c.estado().cantidad, channel_count)
  end)
  case("Atajos nativos de Room recorren pestañas y separan silencio general y por pestaña", function()
    local wx = room.vista.wx
    local mods = wx.wxMOD_CONTROL + wx.wxMOD_SHIFT
    equal(room.estado().seleccion, "global")
    capturar_avisos(function(_, readings)
      assert(room.tecla(string.byte(","), mods))
      equal(readings[1], "Room PNJs")
    end)
    equal(room.estado().seleccion, "pnjs")
    assert(room.tecla(wx.WXK_F2, wx.wxMOD_CONTROL))
    assert(room.estado().canales.pnjs.silenciado and not room.estado().silenciado)
    capturar_avisos(function(sounds, readings)
      assert(room.tecla(wx.WXK_F2, wx.wxMOD_ALT))
      equal(readings[1], "No hay mensajes en Room, PNJs")
      equal(#sounds, 0)
      assert(room.estado().canales.pnjs.silenciado)
    end)
    capturar_avisos(function(_, readings)
      assert(room.tecla(string.byte(":"), mods))
      equal(room.estado().seleccion, "global")
      assert(room.tecla(string.byte("."), mods))
      equal(readings[1], "Room global")
      equal(readings[2], "Room Jugadores")
    end)
    equal(room.estado().seleccion, "jugadores")
    con_dialogo(room, function()
      equal(room.pestanyas:GetSelection(), 1)
      equal(room.lista:GetItemCount(), 0)
      assert(room.tecla(string.byte(";"), mods))
      equal(room.pestanyas:GetSelection(), 0)
      capturar_avisos(function(sounds, readings)
        assert(room.tecla(wx.WXK_F2, wx.wxMOD_CONTROL))
        assert(room.estado().silenciado)
        equal(readings[1], "Room silenciada.")
        local mensajes = room.estado().mensajes
        assert(room.tecla(wx.WXK_F2, wx.wxMOD_ALT))
        equal(readings[2], mensajes[#mensajes].texto)
        equal(room.pestanyas:GetSelection(), 0)
        assert(room.tecla(wx.WXK_F2, wx.wxMOD_CONTROL))
        equal(readings[3], "Room, lectura activada.")
        equal(table.concat(sounds, ","), "ui.comunicacion_mute,ui.comunicacion_unmute")
      end)
      assert(not room.estado().silenciado and room.estado().canales.pnjs.silenciado)
      assert(room.vista.tab(-1))
      equal(room.pestanyas:GetSelection(), 2)
      equal(room.lista:GetItemCount(), 0)
      assert(room.tecla(wx.WXK_F2, wx.wxMOD_CONTROL))
      assert(not room.estado().canales.pnjs.silenciado)
      assert(room.vista.tab(1))
      equal(room.estado().seleccion, "global")
    end)
  end)
  case("Silenciar conserva historial y sonido; Alt+F3 lee incluso en silencio", function()
    local wx = room.vista.wx
    assert(room.tecla(wx.WXK_F2, wx.wxMOD_CONTROL))
    local room_line = "La capitana dice: Room sigue guardando."
    local tel_line = "Ariadna te pregunta: ¿Sigues ahí?"
    capturar_avisos(function(sounds, readings)
      feed(room_line)
      feed(tel_line)
      equal(#readings, 1)
      equal(readings[1], tel_line)
      equal(#sounds, 2)
      equal(sounds[1], "comunicaciones.room")
      equal(sounds[2], "comunicaciones.telepatia")
    end)
    local room_messages = room.estado().mensajes
    equal(room_messages[#room_messages].texto, room_line)
    assert(room.tecla(wx.WXK_F2, wx.wxMOD_CONTROL))
    capturar_avisos(function(_, readings)
      assert(tel.tecla(wx.WXK_F3, wx.wxMOD_CONTROL))
      equal(readings[1], "Telepatía silenciada.")
    end)
    local silent = "Ariadna te exclama: Telepatía sigue guardando."
    capturar_avisos(function(sounds, readings)
      feed(silent)
      equal(#sounds, 1)
      equal(sounds[1], "comunicaciones.telepatia")
      equal(#readings, 0)
      assert(tel.tecla(wx.WXK_F3, wx.wxMOD_ALT))
      equal(#readings, 1)
      equal(readings[1], silent)
      equal(#sounds, 1)
    end)
    capturar_avisos(function(_, readings)
      assert(tel.tecla(wx.WXK_F3, wx.wxMOD_CONTROL))
      equal(readings[1], "Telepatía, lectura activada.")
    end)
  end)
  case("Las llegadas a Room durante el diálogo conservan el mensaje seleccionado", function()
    local wx = room.vista.wx
    local flag = wx.wxLIST_STATE_SELECTED + wx.wxLIST_STATE_FOCUSED
    local room_list, room_view = room.lista, room.vista
    con_dialogo(room, function()
      assert(room_view.dialogo:IsShown() and not tel.vista.dialogo:IsShown() and not window:IsShown())
      local focus = wx.wxWindow.FindFocus()
      assert(focus and focus:GetId() == room_list:GetId(), "La lista de Room debe recibir foco inicial")
      equal(room_list:GetItemState(0, flag), flag)
      local selected = room_list:GetItemData(0)
      local count = room_list:GetItemCount()
      feed("La capitana dice: Llegada durante Room.")
      equal(room_list:GetItemCount(), count + 1)
      equal(room_list:GetItemData(1), selected)
      equal(room_list:GetItemState(1, flag), flag)
      equal(room.estado().selecciones.global, selected)
    end)
    con_dialogo(room, function()
      equal(room.lista, room_list)
      equal(room.vista, room_view)
      equal(room_list:GetItemState(0, flag), flag)
      equal(room_list:GetTopItem(), 0)
    end)
    capturar_avisos(function(sounds, readings)
      con_dialogo(tel, function()
        local focus = wx.wxWindow.FindFocus()
        assert(focus and focus:GetId() == tel.lista:GetId(), "La lista de telepatía debe recibir foco inicial")
        equal(tel.lista:GetItemState(0, flag), flag)
        equal(tel.lista:GetItemCount(), #tel.estado().mensajes)
        assert(not room_view.dialogo:IsShown())
      end)
      equal(#sounds, 2)
      equal(sounds[1], "ui.abrir_com")
      equal(sounds[2], "ui.cerrar_com")
      equal(#readings, 0)
    end)
  end)
  case("Desconectar vacía Room y telepatía, restablece silencios y conserva los controles", function()
    local room_list, tel_list = room.lista, tel.lista
    local wx = room.vista.wx
    assert(room.tecla(wx.WXK_F2, wx.wxMOD_CONTROL))
    assert(tel.tecla(wx.WXK_F3, wx.wxMOD_CONTROL))
    raiseEvent("sysDisconnectionEvent")
    equal(#room.estado().mensajes, 0)
    equal(#tel.estado().mensajes, 0)
    assert(not room.estado().silenciado and not tel.estado().silenciado)
    equal(room.lista, room_list)
    equal(tel.lista, tel_list)
    feed("La capitana dice: Una nueva sesión de Room.")
    feed("Ariadna te dice: Una nueva sesión de telepatía.")
    equal(#room.estado().mensajes, 1)
    equal(#tel.estado().mensajes, 1)
  end)
  case("Detener retira suscripción y evita nuevas capturas", function()
    c.detener()
    local count = c.estado().cantidad
    local room_count, tel_count = #room.estado().mensajes, #tel.estado().mensajes
    gmcp.Comm.MensajeCanal = { canal = "chat", mensaje = "No capturar tras detener" }
    raiseEvent("gmcp.Comm.MensajeCanal")
    feed("La capitana dice: No capturar tras detener.")
    feed("Ariadna te dice: No capturar tras detener.")
    equal(c.estado().cantidad, count)
    equal(#room.estado().mensajes, room_count)
    equal(#tel.estado().mensajes, tel_count)
  end)
  case("Destruir y recargar descarta historial conservando bibliotecas nativas", function()
    local native = package.loaded.wx
    local previous_view, previous_detail = c.vista, c.detalle
    c.destruir()
    assert(previous_view.destruida and previous_detail.vista.destruida, "Destruir debe retirar también el detalle preparado")
    package.loaded.comunicaciones = nil
    c = require("comunicaciones")
    equal(c.estado().cantidad, 0)
    c.preparar()
    equal(package.loaded.wx, native)
    local new_room, new_tel = c.historiales.room, c.historiales.telepatia
    equal(#new_room.estado().mensajes, 0)
    equal(#new_tel.estado().mensajes, 0)
    c.iniciar()
    feed("La capitana dice: Una captura tras recargar.")
    feed("Ariadna te dice: Una captura tras recargar.")
    equal(#new_room.estado().mensajes, 1)
    equal(#new_tel.estado().mensajes, 1)
    c.destruir()
  end)
end
local ok, message = xpcall(run, debug.traceback)
finished = true
for id in pairs(timers) do killTimer(id) end
audio.stop_tag()
local file = assert(io.open(RHOM_WX_RESULT .. ".tmp", "w"))
file:write(ok and "STATUS OK\n" or "STATUS ERROR\n")
file:write("VERSION ", getMudletVersion("string"), "\nLUA ", _VERSION, "\n")
file:write("WX ", package.loaded.wx.wxVERSION_STRING, "\nQT_HEARTBEAT ", tostring(ticks), "\n")
file:write("OMITIDA Teclado físico, experiencia auditiva y lector externo\n")
file:write("OMITIDA Servidor: entradas GMCP sintéticas en perfil desconectado\n")
file:write("OMITIDA Portapapeles: no se lee ni escribe\n")
for _, name in ipairs(results) do file:write("CASE ", name, "\n") end
if not ok then file:write("ERROR ", tostring(message), "\n") end
file:close()
assert(os.rename(RHOM_WX_RESULT .. ".tmp", RHOM_WX_RESULT))
if not ok then error(message, 0) end
