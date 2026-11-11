-- Comunicaciones GMCP: historial temporal, ventana nativa y voz por canal.
-- Contrato y procedencia: Doc/migraciones/panel-canales.md.
local configuracion = require("configuracion")
local lector = require("lector")
local audio = require("audio")
local ui = require("ui")
local comunicaciones = {}
local canales, registros, categorias, selecciones = {}, {}, { "global" }, {}
local seleccion, secuencia, cantidad = "global", 0, 0
local primero, ultimo
local handlers = {}
local avisos_canal = {}
local avisos_historicos = {}
local renderizados, paginas, posiciones = {}, {}, {}
local retirados = false
local actualizando = false
local refrescar, sincronizar_pestanyas

-- Nombres de Comunicaciones.set y de la migración Lua archivada.
local contextos = {
  bando = { "Bueno", "Malo", "Mercenario", "Anarquico", "Renegado" },
  interbando = { "Malvados", "Solitarios" },
  ciudadania = {
    "Kheleb", "Kattak", "Ak'anon", "Anduar", "Veleiron", "Grimoszk", "Takome", "Thorin", "Poldarn",
    "Eloras", "Eldor", "Ar'kaindia", "Dendra", "Mor_groddur", "Golthur", "Ancarak", "Keel",
  },
  gremio = {
    "Alianza", "Horda_negra", "Cruzada_eralie", "Ej_dendra", "Dhara", "Inquisicion", "Guante_blanco",
    "las_garzas", "colmillos_venenosos", "viuda_negra", "custodios_del_eter", "sombras_del_baltia",
    "sello_carmesí", "sello_carmesi",
  },
  chat = { "Chat" },
  rol = { "Rol" },
  novato = { "Novato" },
  consulta = { "Consulta", "Consulta." },
  trivial = { "Trivial" },
  taberna = { "Taberna" },
  avatar = { "Avatar" },
  creadores = { "Cre" },
}

local function normalizar_canal(id)
  return (id:match("^%s*(.-)%s*$"):lower():gsub("%s+", "_"))
end

local function indexar_contextos()
  local indice = {}
  for contexto, nombres in pairs(contextos) do
    local ficha = { contexto = contexto, sonido = "comunicaciones." .. contexto }
    for _, nombre in ipairs(nombres) do
      local id = normalizar_canal(nombre)
      local anterior = indice[id]
      if anterior and anterior ~= ficha then
        error(string.format("Canal %s asignado a los contextos %s y %s", id, anterior.contexto, contexto))
      end
      indice[id] = ficha
    end
  end
  return indice
end

local contexto_por_canal = indexar_contextos()

local function sonido_de_mensaje(id)
  local normalizado = normalizar_canal(id)
  local ficha = contexto_por_canal[normalizado]
  if ficha then return ficha.sonido end
  if normalizado:match("^grupo%-.+") then return "comunicaciones.grupo" end
  return "comunicaciones.clan"
end

local function decir(texto)
  lector.verbalizar(texto, lector.prioridades.ALTA)
end

local function sonido(clave)
  audio.reproducir("ui." .. clave)
end

local function primer_aviso_de_tanda(avisos, id)
  local anterior = avisos[id]
  if anterior then
    killTimer(anterior)
    avisos[id] = nil
  end
  -- Un aviso inmediato por ráfaga; cada evento prolonga la misma agrupación.
  avisos[id] = assert(tempTimer(0.25, function() avisos[id] = nil end))
  return not anterior
end

local function sonido_canal(encendido)
  local clave = encendido and "on" or "off"
  if primer_aviso_de_tanda(avisos_canal, clave) then
    audio.reproducir("comunicaciones.canal_" .. clave)
  end
end

local function cancelar_avisos_canal()
  local errores = {}
  for _, avisos in ipairs({ avisos_canal, avisos_historicos }) do
    for clave, id in pairs(avisos) do
      local correcto, mensaje = pcall(killTimer, id)
      if not correcto then errores[#errores + 1] = tostring(mensaje) end
      avisos[clave] = nil
    end
  end
  if #errores > 0 then error(table.concat(errores, "\n"), 0) end
end

local function nombre(id)
  return id
end

local function historial_vacio(id)
  return "No hay mensajes en el canal " .. nombre(id)
end

local function etiqueta(id)
  local canal = canales[id]
  return nombre(id) .. (canal and canal.silenciado and " (silenciado)" or "")
end

local function valido(id)
  return type(id) == "string" and id ~= "" and id ~= "global"
end

local function recategorizar()
  categorias = { "global" }
  for id, canal in pairs(canales) do
    if canal.abierto then categorias[#categorias + 1] = id end
  end
  table.sort(categorias, function(a, b)
    if a == b then return false end
    if a == "global" then return true end
    if b == "global" then return false end
    return a < b
  end)
  if seleccion ~= "global" and not (canales[seleccion] and canales[seleccion].abierto) then
    seleccion = "global"
  end
  if sincronizar_pestanyas then sincronizar_pestanyas() end
  if refrescar then refrescar() end
end

local function extremo(id, final)
  if id == "global" then return final and ultimo or primero end
  local canal = canales[id]
  if canal then return final and canal.ultimo or canal.primero end
end

local function siguientes(registro, id)
  return id == "global" and registro.siguiente or registro.siguiente_canal
end

-- Mantener índices de llegada permite insertar arriba sin reindexar el modelo.
local function fila_visible(id)
  local posicion = posiciones[id]
  if posicion then return #renderizados - 1 - posicion end
end

local function eliminar(registro)
  local canal = canales[registro.canal]
  if registro.anterior then registros[registro.anterior].siguiente = registro.siguiente
  else primero = registro.siguiente end
  if registro.siguiente then registros[registro.siguiente].anterior = registro.anterior
  else ultimo = registro.anterior end
  if registro.anterior_canal then registros[registro.anterior_canal].siguiente_canal = registro.siguiente_canal
  else canal.primero = registro.siguiente_canal end
  if registro.siguiente_canal then registros[registro.siguiente_canal].anterior_canal = registro.anterior_canal
  else canal.ultimo = registro.anterior_canal end
  local movida = false
  for _, id in ipairs({ "global", registro.canal }) do
    if selecciones[id] == registro.id then
      selecciones[id] = (id == "global" and (registro.siguiente or registro.anterior))
        or registro.siguiente_canal or registro.anterior_canal
      if id == seleccion then movida = true end
    end
  end
  retirados = true
  registros[registro.id] = nil
  cantidad, canal.cantidad = cantidad - 1, canal.cantidad - 1
  if not canal.abierto and canal.cantidad == 0 then
    canales[registro.canal], selecciones[registro.canal] = nil, nil
  end
  return movida
end

function comunicaciones.aplicar_limites()
  local limite = configuracion.get("canales_limite")
  local total = configuracion.get("canales_total")
  local movida = false
  for _, canal in pairs(canales) do
    while canal.cantidad > limite do
      if eliminar(registros[canal.primero]) then movida = true end
    end
  end
  while cantidad > total do
    if eliminar(registros[primero]) then movida = true end
  end
  if refrescar then refrescar() end
  if movida and comunicaciones.activo then decir("El mensaje seleccionado se retiró por el límite del historial.") end
end

function comunicaciones.abrir_canal(id, silencioso)
  assert(valido(id), "Identificador de canal inválido")
  local canal = canales[id]
  if canal and canal.abierto then return false end
  canal = canal or { cantidad = 0 }
  canal.abierto, canal.silenciado = true, false
  canales[id] = canal
  recategorizar()
  if not silencioso then sonido_canal(true) end
  return true
end

function comunicaciones.cerrar_canal(id, silencioso)
  assert(valido(id), "Identificador de canal inválido")
  local canal = canales[id]
  if not canal or not canal.abierto then return false end
  local seleccionada = seleccion == id
  canal.abierto, canal.silenciado = false, false
  if canal.cantidad == 0 then canales[id], selecciones[id] = nil, nil end
  recategorizar()
  if not silencioso then
    sonido_canal(false)
    if seleccionada then decir("Canal " .. id .. " cerrado. global.") end
  end
  return true
end

function comunicaciones.reconciliar(lista, silencioso)
  assert(type(lista) == "table", "La lista GMCP de canales debe ser una tabla")
  local altas, bajas = false, false
  local anterior = seleccion
  -- Reconciliar en un lote, sin reconstruir ni anunciar cada canal.
  for id in pairs(lista) do assert(valido(id), "Identificador de canal inválido") end
  for id, canal in pairs(canales) do
    if canal.abierto and lista[id] == nil then
      canal.abierto, canal.silenciado, bajas = false, false, true
      if canal.cantidad == 0 then canales[id], selecciones[id] = nil, nil end
    end
  end
  for id in pairs(lista) do
    local canal = canales[id]
    if not canal or not canal.abierto then
      canal = canal or { cantidad = 0 }
      canal.abierto, canal.silenciado = true, false
      canales[id], altas = canal, true
    end
  end
  recategorizar()
  if not silencioso then
    if bajas then sonido_canal(false) end
    if altas then sonido_canal(true) end
    if anterior ~= seleccion then decir("Canal " .. anterior .. " cerrado. global.") end
  end
end

function comunicaciones.recibir(datos, historico)
  assert(type(datos) == "table" and valido(datos.canal) and type(datos.mensaje) == "string",
    "Mensaje GMCP de canal inválido")
  local canal = canales[datos.canal]
  if not canal or not canal.abierto then return nil end
  local texto = ansi2string(datos.mensaje)
  assert(type(texto) == "string", "ansi2string no devolvió texto")
  if not texto:find("%S") then return nil end
  secuencia = secuencia + 1
  local registro = { id = secuencia, canal = datos.canal, texto = texto, historico = historico == true,
    anterior = ultimo, anterior_canal = canal.ultimo }
  registros[secuencia] = registro
  if ultimo then registros[ultimo].siguiente = secuencia else primero = secuencia end
  if canal.ultimo then registros[canal.ultimo].siguiente_canal = secuencia else canal.primero = secuencia end
  ultimo, canal.ultimo = secuencia, secuencia
  cantidad, canal.cantidad = cantidad + 1, canal.cantidad + 1
  comunicaciones.aplicar_limites()
  if not canal.silenciado then decir(texto) end
  if not registro.historico or primer_aviso_de_tanda(avisos_historicos, registro.canal) then
    audio.reproducir(sonido_de_mensaje(registro.canal))
  end
  return secuencia
end

function comunicaciones.cambiar_categoria(delta)
  assert(delta == 1 or delta == -1, "Dirección de categoría inválida")
  local indice = 1
  for i, id in ipairs(categorias) do if id == seleccion then indice = i; break end end
  local nueva = categorias[(indice - 1 + delta) % #categorias + 1]
  if nueva == seleccion then sonido("limite"); return false end
  seleccion = nueva
  if not selecciones[nueva] then selecciones[nueva] = extremo(nueva, true) end
  if sincronizar_pestanyas then sincronizar_pestanyas() end
  if refrescar then refrescar(true) end
  sonido("seleccion_canal")
  decir("canal " .. nombre(seleccion))
  if comunicaciones.activo then comunicaciones.lista:SetFocus() end
  return true
end

function comunicaciones.leer_ultimo()
  local id = extremo(seleccion, true)
  local texto = id and registros[id].texto or historial_vacio(seleccion)
  decir(texto)
  return texto
end

function comunicaciones.alternar_silencio()
  local silencioso
  if seleccion == "global" then
    if #categorias == 1 then decir("No hay canales abiertos."); return false end
    silencioso = false
    for _, canal in pairs(canales) do
      if canal.abierto and not canal.silenciado then silencioso = true; break end
    end
    for _, canal in pairs(canales) do if canal.abierto then canal.silenciado = silencioso end end
  else
    local canal = assert(canales[seleccion], "Canal seleccionado inexistente")
    silencioso = not canal.silenciado
    canal.silenciado = silencioso
  end
  if sincronizar_pestanyas then sincronizar_pestanyas() end
  if refrescar then refrescar() end
  sonido(silencioso and "off" or "on")
  decir(nombre(seleccion) .. (silencioso and ": silenciado." or ": sonido activado."))
  return silencioso
end

local function mensajes(id)
  local lista, actual = {}, extremo(id)
  while actual do
    local registro = registros[actual]
    lista[#lista + 1] = { id = registro.id, canal = registro.canal, texto = registro.texto, historico = registro.historico }
    actual = siguientes(registro, id)
  end
  return lista
end

function comunicaciones.estado()
  local copia = { seleccion = seleccion, cantidad = cantidad, categorias = {}, canales = {},
    selecciones = {}, mensajes = mensajes("global") }
  for _, id in ipairs(categorias) do copia.categorias[#copia.categorias + 1] = id end
  for id, canal in pairs(canales) do
    copia.canales[id] = { abierto = canal.abierto, silenciado = canal.silenciado,
      cantidad = canal.cantidad, mensajes = mensajes(id) }
  end
  for id, valor in pairs(selecciones) do copia.selecciones[id] = valor end
  return copia
end

function comunicaciones.reiniciar()
  cancelar_avisos_canal()
  canales, registros, selecciones = {}, {}, {}
  seleccion, cantidad, primero, ultimo = "global", 0, nil, nil
  retirados = true
  recategorizar()
end

function comunicaciones.detener()
  local errores = {}
  local cancelado, error_cancelacion = pcall(cancelar_avisos_canal)
  if not cancelado then errores[#errores + 1] = tostring(error_cancelacion) end
  for _, id in ipairs(handlers) do
    local correcto, mensaje = pcall(killAnonymousEventHandler, id)
    if not correcto then errores[#errores + 1] = tostring(mensaje) end
  end
  handlers = {}
  comunicaciones.iniciado = false
  if #errores > 0 then error(table.concat(errores, "\n"), 0) end
end

local canales_genericos = { gremio = true, bando = true, ciu = true, clan = true }

local function aplicar_cambio_canal(datos, aplicar)
  local id = datos.canal
  if not canales_genericos[id] then aplicar(id) end
end

function comunicaciones.iniciar()
  if comunicaciones.iniciado then return end
  local function escuchar(evento, funcion)
    handlers[#handlers + 1] = registerAnonymousEventHandler(evento, funcion)
  end
  local correcto, mensaje = pcall(function()
    escuchar("gmcp.Comm.Canales", function() comunicaciones.reconciliar(gmcp.Comm.Canales) end)
    escuchar("gmcp.Comm.EnciendeCanal", function()
      aplicar_cambio_canal(gmcp.Comm.EnciendeCanal, comunicaciones.abrir_canal)
    end)
    escuchar("gmcp.Comm.ApagaCanal", function()
      aplicar_cambio_canal(gmcp.Comm.ApagaCanal, comunicaciones.cerrar_canal)
    end)
    escuchar("gmcp.Comm.MensajeCanal", function() comunicaciones.recibir(gmcp.Comm.MensajeCanal, false) end)
    escuchar("gmcp.Comm.MensajeCanalHistorico", function() comunicaciones.recibir(gmcp.Comm.MensajeCanalHistorico, true) end)
    escuchar("sysDisconnectionEvent", comunicaciones.reiniciar)
    escuchar("sysConnectionEvent", comunicaciones.reiniciar)
    local _, _, conectado = getConnectionInfo()
    if conectado and gmcp and gmcp.Comm and gmcp.Comm.Canales then
      comunicaciones.reconciliar(gmcp.Comm.Canales, true)
    end
    comunicaciones.iniciado = true
  end)
  if not correcto then
    local limpio, error_limpieza = pcall(comunicaciones.detener)
    if not limpio then mensaje = tostring(mensaje) .. "\n" .. tostring(error_limpieza) end
    error(mensaje, 0)
  end
end

local function actualizar_estado()
  if not comunicaciones.vista then return end
  local _, _, conectado = getConnectionInfo()
  local posicion = fila_visible(selecciones[seleccion])
  local texto = etiqueta(seleccion) .. ". " .. (posicion and tostring(posicion + 1) .. " de " or "")
    .. tostring(#renderizados) .. " mensajes. "
    .. (conectado and "Conectado." or "Desconectado.")
  if #renderizados == 0 then texto = historial_vacio(seleccion) .. ". "
    .. (conectado and "Conectado." or "Desconectado.") end
  if #categorias == 1 then texto = "Todos los canales apagados" end
  if comunicaciones.texto_estado ~= texto then
    comunicaciones.estado_texto:SetLabel(texto)
    comunicaciones.texto_estado = texto
  end
end

sincronizar_pestanyas = function()
  if not comunicaciones.vista then return end
  actualizando = true
  local tabs, wx = comunicaciones.pestanyas, comunicaciones.vista.wx
  -- Bajas de derecha a izquierda; no destruir páginas conservadas.
  local abiertos = {}
  for _, id in ipairs(categorias) do abiertos[id] = true end
  for i = #paginas, 1, -1 do
    if not abiertos[paginas[i]] then
      assert(tabs:DeletePage(i - 1), "No se pudo retirar la pestaña")
      table.remove(paginas, i)
    end
  end
  for i, id in ipairs(categorias) do
    if paginas[i] ~= id then
      assert(tabs:InsertPage(i - 1, wx.wxPanel(tabs, wx.wxID_ANY), etiqueta(id), false), "No se pudo crear la pestaña")
      table.insert(paginas, i, id)
    elseif tabs:GetPageText(i - 1) ~= etiqueta(id) then
      assert(tabs:SetPageText(i - 1, etiqueta(id)), "No se pudo actualizar la pestaña")
    end
    if id == seleccion then tabs:ChangeSelection(i - 1) end
  end
  actualizando = false
end

refrescar = function(cambio)
  if not comunicaciones.vista then return end
  local lista, wx = comunicaciones.lista, comunicaciones.vista.wx
  actualizando = true
  if comunicaciones.categoria_renderizada ~= seleccion then
    assert(lista:DeleteAllItems(), "No se pudo cambiar el historial")
    renderizados, posiciones = {}, {}
    comunicaciones.categoria_renderizada = seleccion
    cambio = true
  end
  -- Índices internos cronológicos; el control presenta las filas en orden inverso.
  if retirados then
    for i = #renderizados, 1, -1 do
      if not registros[renderizados[i]] then
        assert(lista:DeleteItem(#renderizados - i), "No se pudo retirar el mensaje")
        table.remove(renderizados, i)
      end
    end
    posiciones = {}
    for i, id in ipairs(renderizados) do posiciones[id] = i - 1 end
    retirados = false
  end
  local despues
  if #renderizados > 0 then despues = siguientes(registros[renderizados[#renderizados]], seleccion)
  else despues = extremo(seleccion) end
  while despues do
    local registro = registros[despues]
    local fila = lista:InsertItem(0, registro.canal)
    assert(fila >= 0, "No se pudo insertar el mensaje")
    lista:SetItem(fila, 1, registro.texto)
    assert(lista:SetItemData(fila, registro.id), "No se pudo identificar el mensaje")
    renderizados[#renderizados + 1] = registro.id
    posiciones[registro.id] = #renderizados - 1
    despues = siguientes(registro, seleccion)
  end
  if not selecciones[seleccion] and (comunicaciones.activo or comunicaciones.visitando) then
    selecciones[seleccion] = extremo(seleccion, true)
  end
  local seleccionado = selecciones[seleccion]
  local estado = wx.wxLIST_STATE_SELECTED + wx.wxLIST_STATE_FOCUSED
  local fila = fila_visible(seleccionado)
  if fila then
    if lista:GetItemState(fila, estado) ~= estado then lista:SetItemState(fila, estado, estado) end
    if cambio then lista:EnsureVisible(fila) end
  end
  local nombre_lista = "Historial de " .. etiqueta(seleccion)
  if #renderizados == 0 then nombre_lista = historial_vacio(seleccion) end
  if #categorias == 1 then nombre_lista = "Todos los canales apagados" end
  if comunicaciones.nombre_lista ~= nombre_lista then
    lista:SetName(nombre_lista)
    comunicaciones.nombre_lista = nombre_lista
  end
  actualizar_estado()
  actualizando = false
end

function comunicaciones.cerrar()
  if not comunicaciones.activo then return end
  comunicaciones.activo = false
  sonido("cerrar_com")
  comunicaciones.vista:ocultar()
end

function comunicaciones.mostrar_historial()
  local vista = assert(comunicaciones.vista, "El historial no se preparó durante el arranque")
  if comunicaciones.activo then vista.dialogo:Raise(); return end
  comunicaciones.visitando = true
  refrescar(true)
  comunicaciones.visitando = false
  comunicaciones.activo = true
  sonido("abrir_com")
  local correcto, resultado = pcall(function() return vista:mostrar() end)
  comunicaciones.activo = false
  local oculto, error_ocultar = pcall(function() vista:ocultar() end)
  if not oculto then
    if not correcto then error(tostring(resultado) .. "\n" .. tostring(error_ocultar), 0) end
    error(error_ocultar, 0)
  end
  if not correcto then error(resultado, 0) end
  return resultado
end

function comunicaciones.tecla(codigo, modificadores)
  local wx = comunicaciones.vista.wx
  if modificadores == 0 and (codigo == wx.WXK_UP or codigo == wx.WXK_DOWN) then
    local fila = fila_visible(selecciones[seleccion])
    if #renderizados == 0 or (codigo == wx.WXK_UP and fila == 0)
      or (codigo == wx.WXK_DOWN and fila == #renderizados - 1) then
      sonido("limite")
      return true
    end
  end
  if codigo == wx.WXK_F1 and modificadores == wx.wxMOD_ALT then comunicaciones.leer_ultimo(); return true end
  if codigo == wx.WXK_F1 and modificadores == wx.wxMOD_SHIFT then return true end
  if modificadores == wx.wxMOD_CONTROL then
    if codigo == string.byte(",") then comunicaciones.cambiar_categoria(-1); return true end
    if codigo == string.byte(".") then comunicaciones.cambiar_categoria(1); return true end
  end
  if codigo == string.byte("S") and modificadores == wx.wxMOD_CONTROL + wx.wxMOD_SHIFT then
    comunicaciones.alternar_silencio(); return true
  end
  if modificadores == 0 and (codigo == wx.WXK_RIGHT or codigo == wx.WXK_LEFT) then
    sonido("limite"); return true
  end
  return false
end

function comunicaciones.preparar()
  if comunicaciones.vista then return end
  local vista = ui.nueva("Historial de canales")
  comunicaciones.vista = vista
  local wx, dialogo = vista.wx, vista.dialogo
  local correcto, mensaje = pcall(function()
    local contenido = wx.wxBoxSizer(wx.wxVERTICAL)
    local ayuda = wx.wxStaticText(dialogo, wx.wxID_ANY,
      "Tab: cambiar canal. Flechas: mensajes. Alt+F1: último. Ctrl+Mayús+S: silencio. Escape: salir.")
    contenido:Add(ayuda, 0, wx.wxALL, 12)
    local tabs = wx.wxNotebook(dialogo, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxSize(700, 42))
    tabs:SetName("Canales abiertos")
    comunicaciones.pestanyas = tabs
    contenido:Add(tabs, 0, wx.wxEXPAND + wx.wxLEFT + wx.wxRIGHT, 12)
    local centro = wx.wxBoxSizer(wx.wxHORIZONTAL)
    local lista = wx.wxListCtrl(dialogo, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxSize(700, 360),
      wx.wxLC_REPORT + wx.wxLC_SINGLE_SEL)
    comunicaciones.lista = lista
    assert(lista:InsertColumn(0, "Canal", wx.wxLIST_FORMAT_LEFT, 140) == 0)
    assert(lista:InsertColumn(1, "Mensaje", wx.wxLIST_FORMAT_LEFT, 550) == 1)
    centro:Add(lista, 1, wx.wxEXPAND + wx.wxTOP + wx.wxBOTTOM, 12)
    local acciones = wx.wxBoxSizer(wx.wxVERTICAL)
    acciones:Add(wx.wxStaticText(dialogo, wx.wxID_ANY, "Acciones del mensaje\n(próximamente)"), 0, wx.wxALL, 8)
    comunicaciones.botones = {}
    for _, titulo in ipairs({ "Responder", "Responder en privado", "Copiar" }) do
      local boton = wx.wxButton(dialogo, wx.wxID_ANY, titulo)
      boton:SetName(titulo .. " al mensaje seleccionado. No disponible todavía")
      boton:Enable(false)
      acciones:Add(boton, 0, wx.wxEXPAND + wx.wxALL, 6)
      comunicaciones.botones[#comunicaciones.botones + 1] = boton
    end
    centro:Add(acciones, 0, wx.wxLEFT + wx.wxTOP, 12)
    contenido:Add(centro, 1, wx.wxEXPAND + wx.wxLEFT + wx.wxRIGHT, 12)
    comunicaciones.estado_texto = wx.wxStaticText(dialogo, wx.wxID_ANY, "")
    contenido:Add(comunicaciones.estado_texto, 0, wx.wxALL, 12)
    dialogo:SetSizerAndFit(contenido)
    dialogo:SetMinSize(wx.wxSize(700, 400))
    vista.controles = { lista }
    vista.cancelar = comunicaciones.cerrar
    vista.tab = comunicaciones.cambiar_categoria
    vista.tecla = function(evento) return comunicaciones.tecla(evento:GetKeyCode(), evento:GetModifiers()) end
    lista:Connect(wx.wxEVT_COMMAND_LIST_ITEM_SELECTED, function(evento)
      if not actualizando then
        selecciones[seleccion] = renderizados[#renderizados - evento:GetIndex()]
        if comunicaciones.activo then sonido("clic_1") end
        actualizar_estado()
      end
      evento:Skip()
    end)
    tabs:Connect(wx.wxEVT_COMMAND_NOTEBOOK_PAGE_CHANGED, function(evento)
      if not actualizando then
        local id = paginas[evento:GetSelection() + 1]
        if id and id ~= seleccion then
          seleccion = id
          if not selecciones[id] then selecciones[id] = extremo(id, true) end
          refrescar(true)
          if comunicaciones.activo then
            sonido("seleccion_canal")
            decir("canal " .. nombre(id))
            lista:SetFocus()
          end
        end
      end
      evento:Skip()
    end)
    sincronizar_pestanyas()
    refrescar()
    vista:preparar()
    comunicaciones.iniciar()
  end)
  if not correcto then
    local limpio, error_limpieza = pcall(comunicaciones.destruir)
    if not limpio then mensaje = tostring(mensaje) .. "\n" .. tostring(error_limpieza) end
    error(mensaje, 0)
  end
end

function comunicaciones.destruir()
  local errores = {}
  local function limpiar(funcion)
    local correcto, mensaje = pcall(funcion)
    if not correcto then errores[#errores + 1] = tostring(mensaje) end
  end
  limpiar(comunicaciones.detener)
  local vista = comunicaciones.vista
  if vista then limpiar(function() vista:destruir() end) end
  comunicaciones.vista, comunicaciones.lista, comunicaciones.pestanyas = nil, nil, nil
  comunicaciones.estado_texto, comunicaciones.botones, comunicaciones.texto_estado = nil, nil, nil
  comunicaciones.categoria_renderizada, comunicaciones.nombre_lista, comunicaciones.activo = nil, nil, false
  renderizados, paginas, posiciones, retirados = {}, {}, {}, false
  comunicaciones.reiniciar()
  if #errores > 0 then error(table.concat(errores, "\n"), 0) end
end

local function anterior() return comunicaciones.cambiar_categoria(-1) end
local function siguiente() return comunicaciones.cambiar_categoria(1) end
local function pulsacion(tecla, modificadores, id, funcion, descripcion)
  return { combinacion = { tecla = tecla, modificadores = modificadores },
    nombre = "comunicaciones." .. id, funcion = funcion, descripcion = descripcion, grupo = "comunicaciones" }
end
comunicaciones.pulsaciones = {
  pulsacion(mudlet.key.F1, { mudlet.keymodifier.Shift }, "mostrar_historial", comunicaciones.mostrar_historial, "Abre el historial de canales"),
  pulsacion(mudlet.key.F1, { mudlet.keymodifier.Alt }, "leer_ultimo", comunicaciones.leer_ultimo, "Lee el último mensaje de la categoría seleccionada"),
  pulsacion(mudlet.key.Comma, { mudlet.keymodifier.Control }, "anterior", anterior, "Selecciona la categoría anterior"),
  pulsacion(mudlet.key.Period, { mudlet.keymodifier.Control }, "siguiente", siguiente, "Selecciona la categoría siguiente"),
  pulsacion(mudlet.key.S, { mudlet.keymodifier.Control, mudlet.keymodifier.Shift }, "alternar_silencio", comunicaciones.alternar_silencio, "Alterna el silencio de la categoría seleccionada"),
}

return comunicaciones
