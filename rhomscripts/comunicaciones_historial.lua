-- Almacén y vista nativa compartidos por los historiales de comunicaciones.
local configuracion = require("configuracion")
local lector = require("lector")
local audio = require("audio")
local ui = require("ui")

local historial = {}
local nombres_room = { jugadores = "Jugadores", pnjs = "PNJs" }

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

function historial.nuevo(opciones)
  local comunicaciones = {}
  local tipo = opciones.tipo
  local es_room = tipo == "room"
  local es_telepatia = tipo == "telepatia"
  local limite_texto = 500
  local canales, registros, categorias, selecciones = {}, {}, { "global" }, {}
  local silencio_general = false
  local seleccion, secuencia, cantidad = "global", 0, 0
  local primero, ultimo
  local avisos_canal = {}
  local avisos_historicos = {}
  local renderizados, posiciones = {}, {}
  local refrescar, sincronizar_pestanyas

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
    if es_room then return nombres_room[id] or id end
    return id
  end

  local function historial_vacio(id)
    if es_telepatia then return "No hay mensajes de telepatía" end
    if es_room then return "No hay mensajes en Room, " .. nombre(id) end
    return "No hay mensajes en el canal " .. nombre(id)
  end

  local function etiqueta(id)
    local canal = canales[id]
    local silenciado = (tipo and id == "global" and silencio_general) or (canal and canal.silenciado)
    local texto = es_telepatia and "Telepatía" or nombre(id)
    return texto .. (silenciado and " (silenciado)" or "")
  end

  local function valido(id)
    return type(id) == "string" and id ~= "" and id ~= "global"
  end

  local function recategorizar()
    if tipo then
      categorias = es_room and { "global", "jugadores", "pnjs" } or { "global" }
      if es_room then
        canales = { jugadores = { abierto = true, cantidad = 0 }, pnjs = { abierto = true, cantidad = 0 } }
      end
      if sincronizar_pestanyas then sincronizar_pestanyas() end
      if refrescar and comunicaciones.activo then refrescar() end
      return
    end
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
    if id == "global" then return registro.siguiente end
    return registro.siguiente_canal
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
    if canal then
      if registro.anterior_canal then registros[registro.anterior_canal].siguiente_canal = registro.siguiente_canal
      else canal.primero = registro.siguiente_canal end
      if registro.siguiente_canal then registros[registro.siguiente_canal].anterior_canal = registro.anterior_canal
      else canal.ultimo = registro.anterior_canal end
      canal.cantidad = canal.cantidad - 1
    end
    local movida = false
    for _, id in ipairs({ "global", registro.canal }) do
      if selecciones[id] == registro.id then
        selecciones[id] = (id == "global" and (registro.siguiente or registro.anterior))
          or registro.siguiente_canal or registro.anterior_canal
        if id == seleccion then movida = true end
      end
    end
    registros[registro.id] = nil
    cantidad = cantidad - 1
    if canal and not canal.abierto and canal.cantidad == 0 then
      canales[registro.canal], selecciones[registro.canal] = nil, nil
    end
    return movida
  end

  local function aplicar_limites(canal_afectado)
    local total = tipo and limite_texto or configuracion.get("canales_total")
    local movida = false
    if not tipo then
      local limite = configuracion.get("canales_limite")
      local function recortar(canal)
        while canal.cantidad > limite do
          if eliminar(registros[canal.primero]) then movida = true end
        end
      end
      if canal_afectado then recortar(canal_afectado)
      else for _, canal in pairs(canales) do recortar(canal) end
      end
    end
    while cantidad > total do
      if eliminar(registros[primero]) then movida = true end
    end
    if refrescar and (not tipo or comunicaciones.activo) then refrescar() end
    if movida and comunicaciones.activo then decir("El mensaje seleccionado se retiró por el límite del historial.") end
  end

  function comunicaciones.aplicar_limites()
    aplicar_limites()
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

  local function guardar(texto, id_canal, historico)
    if not texto:find("%S") then return nil end
    local canal = canales[id_canal]
    secuencia = secuencia + 1
    local registro = { id = secuencia, canal = id_canal, texto = texto, historico = historico == true,
      anterior = ultimo }
    registros[secuencia] = registro
    if ultimo then registros[ultimo].siguiente = secuencia else primero = secuencia end
    if canal then
      registro.anterior_canal = canal.ultimo
      if canal.ultimo then registros[canal.ultimo].siguiente_canal = secuencia else canal.primero = secuencia end
      canal.ultimo, canal.cantidad = secuencia, canal.cantidad + 1
    end
    ultimo, cantidad = secuencia, cantidad + 1
    aplicar_limites(canal)
    if not silencio_general and not (canal and canal.silenciado) then decir(texto) end
    if tipo then audio.reproducir("comunicaciones." .. tipo)
    elseif not registro.historico or primer_aviso_de_tanda(avisos_historicos, id_canal) then
      audio.reproducir(sonido_de_mensaje(id_canal))
    end
    return secuencia
  end

  function comunicaciones.recibir(datos, historico)
    assert(type(datos) == "table" and valido(datos.canal) and type(datos.mensaje) == "string",
      "Mensaje GMCP de canal inválido")
    local canal = canales[datos.canal]
    if not canal or not canal.abierto then return nil end
    local texto = ansi2string(datos.mensaje)
    assert(type(texto) == "string", "ansi2string no devolvió texto")
    return guardar(texto, datos.canal, historico)
  end

  function comunicaciones.recibir_texto(texto)
    assert(tipo and type(texto) == "string", "Texto de comunicaciones inválido")
    return guardar(texto)
  end

  local function seleccionar_categoria(nueva, desde_pestana)
    seleccion = nueva
    if not selecciones[nueva] then selecciones[nueva] = extremo(nueva, true) end
    sincronizar_pestanyas()
    if not tipo or comunicaciones.activo then refrescar(true) end
    if not desde_pestana then ui.sonido_pestana("ui.seleccion_canal") end
    decir((es_room and "Room " or "canal ") .. nombre(nueva))
    if comunicaciones.activo then comunicaciones.lista:SetFocus() end
  end

  function comunicaciones.cambiar_categoria(delta)
    assert(delta == 1 or delta == -1, "Dirección de categoría inválida")
    local indice = 1
    for i, id in ipairs(categorias) do if id == seleccion then indice = i; break end end
    local nueva = categorias[(indice - 1 + delta) % #categorias + 1]
    if nueva == seleccion then sonido("limite"); return false end
    seleccionar_categoria(nueva)
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
    local ambito = tipo and (es_room and "Room" or "Telepatía") or "canal " .. nombre(seleccion)
    if tipo and seleccion == "global" then
      silencio_general = not silencio_general
      silencioso = silencio_general
    elseif seleccion == "global" then
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
    sincronizar_pestanyas()
    if not tipo or comunicaciones.activo then refrescar() end
    sonido(silencioso and "comunicacion_mute" or "comunicacion_unmute")
    local aviso = ", lectura activada."
    if silencioso then aviso = tipo and " silenciada." or ", silenciado." end
    decir(ambito .. aviso)
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
    if tipo then copia.silenciado = silencio_general end
    for _, id in ipairs(categorias) do copia.categorias[#copia.categorias + 1] = id end
    for id, canal in pairs(canales) do
      copia.canales[id] = { abierto = canal.abierto, silenciado = canal.silenciado,
        cantidad = canal.cantidad, mensajes = mensajes(id) }
    end
    for id, valor in pairs(selecciones) do copia.selecciones[id] = valor end
    return copia
  end

  function comunicaciones.cancelar_avisos()
    cancelar_avisos_canal()
  end

  local function reiniciar()
    comunicaciones.cancelar_avisos()
    canales, registros, selecciones = {}, {}, {}
    seleccion, cantidad, primero, ultimo = "global", 0, nil, nil
    silencio_general = false
    recategorizar()
  end
  comunicaciones.reiniciar = reiniciar

  local function actualizar_estado()
    if not comunicaciones.vista then return end
    local _, _, conectado = getConnectionInfo()
    local posicion = fila_visible(selecciones[seleccion])
    local texto = etiqueta(seleccion) .. ". " .. (posicion and tostring(posicion + 1) .. " de " or "")
      .. tostring(#renderizados) .. " mensajes. "
      .. (conectado and "Conectado." or "Desconectado.")
    if #renderizados == 0 then texto = historial_vacio(seleccion) .. ". "
      .. (conectado and "Conectado." or "Desconectado.") end
    if not tipo and #categorias == 1 then texto = "Todos los canales apagados" end
    if comunicaciones.texto_estado ~= texto then
      comunicaciones.estado_texto:SetLabel(texto)
      comunicaciones.texto_estado = texto
    end
  end

  sincronizar_pestanyas = function()
    if not comunicaciones.componente or es_telepatia then return end
    local paginas = {}
    for _, id in ipairs(categorias) do paginas[#paginas + 1] = { id = id, nombre = etiqueta(id) } end
    comunicaciones.componente:actualizar_pestanas(paginas, seleccion)
  end

  refrescar = function(cambio)
    if not comunicaciones.componente then return end
    local elementos = {}
    renderizados, posiciones = {}, {}
    local actual = extremo(seleccion)
    while actual do
      local registro = registros[actual]
      renderizados[#renderizados + 1] = registro.id
      posiciones[registro.id] = #renderizados - 1
      actual = siguientes(registro, seleccion)
    end
    for i = #renderizados, 1, -1 do
      local registro = registros[renderizados[i]]
      elementos[#elementos + 1] = { id = registro.id,
        textos = tipo and { registro.texto } or { registro.canal, registro.texto },
        datos = registro }
    end
    local componente = comunicaciones.componente
    if not selecciones[seleccion] and comunicaciones.activo then
      selecciones[seleccion] = extremo(seleccion, true)
    end
    componente:actualizar(elementos, { seleccion = selecciones[seleccion], aviso_retirado = false })
    local elegido = componente:seleccionado()
    selecciones[seleccion] = elegido and elegido.id or nil
    if cambio and elegido then componente:seleccionar(elegido.id, true) end
    local nombre_lista = "Historial de " .. etiqueta(seleccion)
    if #renderizados == 0 then nombre_lista = historial_vacio(seleccion) end
    if not tipo and #categorias == 1 then nombre_lista = "Todos los canales apagados" end
    if comunicaciones.nombre_lista ~= nombre_lista then
      comunicaciones.lista:SetName(nombre_lista)
      comunicaciones.nombre_lista = nombre_lista
    end
    actualizar_estado()
  end

  function comunicaciones.abrir_detalle(elemento)
    local registro = elemento and registros[elemento.id]
    if not registro then decir("No hay ningún mensaje seleccionado."); return false end
    -- Una copia del texto mantiene el detalle estable aunque se recorte el historial.
    comunicaciones.detalle:mostrar(registro.texto)
    return true
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
    if ui.ocupada() then return end
    selecciones = { [seleccion] = extremo(seleccion, true) }
    refrescar(true)
    comunicaciones.activo = true
    local correcto, resultado = pcall(function()
      sonido("abrir_com")
      return vista:mostrar()
    end)
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
    local control_mayus = wx.wxMOD_CONTROL + wx.wxMOD_SHIFT
    if codigo == wx["WXK_" .. opciones.tecla] then
      if modificadores == wx.wxMOD_ALT then comunicaciones.leer_ultimo(); return true end
      if modificadores == wx.wxMOD_CONTROL then comunicaciones.alternar_silencio(); return true end
      if modificadores == wx.wxMOD_SHIFT then return true end
    end
    if es_room and modificadores == control_mayus then
      if codigo == string.byte(",") or codigo == string.byte(";") then comunicaciones.cambiar_categoria(-1); return true end
      if codigo == string.byte(".") or codigo == string.byte(":") then comunicaciones.cambiar_categoria(1); return true end
    elseif not tipo and modificadores == wx.wxMOD_CONTROL then
      if codigo == string.byte(",") then comunicaciones.cambiar_categoria(-1); return true end
      if codigo == string.byte(".") then comunicaciones.cambiar_categoria(1); return true end
    end
    return comunicaciones.componente:tecla(codigo, modificadores)
  end

  function comunicaciones.preparar()
    if comunicaciones.vista then return end
    local vista = ui.nueva(opciones.titulo)
    comunicaciones.vista = vista
    local wx, dialogo = vista.wx, vista.dialogo
    local correcto, mensaje = pcall(function()
      local contenido = wx.wxBoxSizer(wx.wxVERTICAL)
      local ayuda = wx.wxStaticText(dialogo, wx.wxID_ANY, opciones.ayuda)
      contenido:Add(ayuda, 0, wx.wxALL, 12)
      local sonidos_interfaz = { limite = "limite" }
      local componente = ui.lista(vista, {
        nombre = "Historial de mensajes",
        columnas = tipo and { { titulo = "Mensaje", ancho = 690 } }
          or { { titulo = "Canal", ancho = 140 }, { titulo = "Mensaje", ancho = 550 } },
        pestanas = not es_telepatia,
        sonido_pestana = "ui.seleccion_canal",
        sonido = function(evento)
          if comunicaciones.activo then
            sonido(assert(sonidos_interfaz[evento], "Evento sonoro desconocido"))
          end
        end,
        activar = comunicaciones.abrir_detalle,
        acciones = function()
          return {
            { id = "responder", nombre = "Responder. No disponible todavía", habilitada = false,
              ejecutar = function() error("Respuesta pendiente de verificar el protocolo") end },
            { id = "privado", nombre = "Responder en privado. No disponible todavía", habilitada = false,
              ejecutar = function() error("Respuesta privada pendiente de identificar el autor") end },
            { id = "copiar", nombre = "Copiar", ejecutar = function(elemento)
              lector.copiar(elemento.datos.texto)
            end },
          }
        end,
        al_seleccionar = function(elemento)
          selecciones[seleccion] = elemento and elemento.id or nil
          actualizar_estado()
        end,
        al_pestana = function(id)
          if id ~= seleccion then seleccionar_categoria(id, true) end
        end,
      })
      comunicaciones.componente, comunicaciones.lista = componente, componente.control
      comunicaciones.pestanyas, comunicaciones.botones = componente.pestanyas, componente.botones
      if comunicaciones.pestanyas then
        comunicaciones.pestanyas:SetName(es_room and "Pestañas de Room" or "Canales abiertos")
      end
      contenido:Add(componente.sizer, 1, wx.wxEXPAND + wx.wxLEFT + wx.wxRIGHT, 12)
      comunicaciones.estado_texto = wx.wxStaticText(dialogo, wx.wxID_ANY, "")
      contenido:Add(comunicaciones.estado_texto, 0, wx.wxALL, 12)
      vista.controles = { comunicaciones.lista }
      vista.cancelar = comunicaciones.cerrar
      if not es_telepatia then vista.tab = comunicaciones.cambiar_categoria end
      vista.tecla = function(evento) return comunicaciones.tecla(evento:GetKeyCode(), evento:GetModifiers()) end
      -- El sistema declara silencioso el detalle; las llegadas conservan sus avisos propios.
      comunicaciones.detalle = ui.detalle(vista, { titulo = "Detalle del mensaje", sonido = function() end })
      sincronizar_pestanyas()
      refrescar()
      -- Calcular el tamaño después de alojar el contenido en una página real.
      dialogo:SetSizerAndFit(contenido)
      dialogo:SetMinSize(wx.wxSize(700, 400))
      vista:preparar()
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
    local vista = comunicaciones.vista
    if comunicaciones.detalle then limpiar(function() comunicaciones.detalle:destruir() end) end
    if vista then limpiar(function() vista:destruir() end) end
    comunicaciones.vista, comunicaciones.lista, comunicaciones.pestanyas = nil, nil, nil
    comunicaciones.estado_texto, comunicaciones.botones, comunicaciones.texto_estado = nil, nil, nil
    comunicaciones.categoria_renderizada, comunicaciones.nombre_lista, comunicaciones.activo = nil, nil, false
    comunicaciones.componente, comunicaciones.detalle = nil, nil
    renderizados, posiciones = {}, {}
    reiniciar()
    if #errores > 0 then error(table.concat(errores, "\n"), 0) end
  end

  if tipo then recategorizar() end
  return comunicaciones
end

return historial
