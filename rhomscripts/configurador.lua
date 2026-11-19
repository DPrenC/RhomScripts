-- Configurador: sesión de edición y ventana nativa accesible.
local configuracion = require("configuracion")
local audio = require("audio")
local ui = require("ui")
local sonidos = {
  abrir = "abrir_config", cancelar = "cerrar_config", guardar = "aceptar",
  desplegar = "desplegar", plegar = "plegar", numero = "boton_1", volumen = "clic_2", booleano = "boton_2", selector = "boton_2",
  limite = "limite", error = "error",
}
local function sonido(evento)
  audio.reproducir("ui." .. assert(sonidos[evento], "Evento sonoro desconocido"))
end
local configurador = { activo = false, cerrando = false }
configurador.sonido = sonido
local definiciones = {}
for _, entrada in ipairs(configuracion.opciones) do definiciones[entrada.id] = entrada end

-- El borrador no modifica preferencias confirmadas hasta Guardar.
local Sesion = {}
Sesion.__index = Sesion
local function opcion(id)
  if definiciones[id] then return definiciones[id] end
  error("Opción de configuración desconocida: " .. tostring(id), 3)
end

function configurador.nueva_sesion()
  local sesion = setmetatable({ valores = {}, guardado = false }, Sesion)
  for _, entrada in ipairs(configuracion.opciones) do
    sesion.valores[entrada.id] = configuracion.get(entrada.id)
  end
  return sesion
end

function Sesion:get(id)
  opcion(id)
  if id == "oficial_depuracion" and not self.debug_editado then
    self.valores[id] = configuracion.get(id)
  end
  return self.valores[id]
end

-- Delta expresa dirección, no cantidad: los pasos pertenecen a la definición.
-- Los selectores son circulares, los booleanos alternan y los números aumentan/disminuyen.
-- Devuelve cambio y límite: solo intentar superar un extremo es límite.
function Sesion:cambiar(id, delta)
  local entrada = opcion(id)
  assert(delta == -1 or delta == 1, "La dirección debe ser -1 o 1")
  local anterior = self:get(id)
  local siguiente
  if entrada.tipo == "selector" then
    for indice, alternativa in ipairs(entrada.opciones) do
      if alternativa.valor == anterior then
        siguiente = entrada.opciones[(indice - 1 + delta) % #entrada.opciones + 1].valor
        break
      end
    end
  elseif entrada.tipo == "booleano" then
    siguiente = not anterior
  else
    siguiente = anterior + delta * entrada.paso
    if entrada.minimo_positivo and siguiente > 0 and siguiente < entrada.minimo_positivo then
      siguiente = delta > 0 and entrada.minimo_positivo or 0
    end
    if siguiente < entrada.minimo or siguiente > entrada.maximo then return false, true end
  end
  if anterior == siguiente then return false, true end
  self.valores[id] = siguiente
  if id == "oficial_depuracion" then self.debug_editado = true end
  return true, false
end

function Sesion:reset()
  local cambio = false
  for _, entrada in ipairs(configuracion.opciones) do
    if self:get(entrada.id) ~= entrada.defecto then cambio = true end
    self.valores[entrada.id] = entrada.defecto
  end
  self.debug_editado = true
  return cambio
end

function Sesion:guardar()
  -- Una preferencia externa modificada mientras el menú estaba abierto solo
  -- se sustituye si el usuario editó expresamente este campo (o Restablecer).
  local modo_debug = self:get("oficial_depuracion")
  self.etapa = "escritura"
  local correcto, mensaje = configuracion.guardar_valores(self.valores)
  if not correcto then return nil, mensaje, self.etapa end
  -- A partir de aquí Cancelar no revierte el archivo ni efectos oficiales.
  self.guardado = true
  self.etapa = "aplicacion"
  configuracion.set("oficial_depuracion", modo_debug)
  audio.aplicar_volumenes()
  -- La retención pertenece al dominio y se aplica tras confirmar la escritura.
  local comunicaciones = RhomScripts and RhomScripts.modules and RhomScripts.modules.comunicaciones
  if comunicaciones then comunicaciones.aplicar_limites() end
  local mapa = RhomScripts and RhomScripts.modules and RhomScripts.modules.mapa
  if mapa then mapa.aplicar_configuracion() end
  -- Una API ausente o un fallo oficial se propaga. La vista puede añadir
  -- contexto y mantener el diálogo, sin confundirlo con un fallo de escritura.
  local resultado = require("arranque").aplicar_configuracion(configuracion)
  self.etapa = nil
  return true, resultado
end

local function valor_ajustado(entrada)
  local valor
  if configurador.sesion then valor = configurador.sesion:get(entrada.id)
  else valor = configuracion.get(entrada.id) end
  local texto = tostring(valor)
  if entrada.tipo == "booleano" then texto = valor and "Activado" or "Desactivado" end
  if entrada.tipo == "selector" then
    for _, alternativa in ipairs(entrada.opciones) do
      if alternativa.valor == valor then texto = alternativa.nombre; break end
    end
  end
  return texto, valor
end

local function etiqueta(entrada)
  local texto, valor = valor_ajustado(entrada)
  if configurador.ajuste == entrada.id then return texto end
  if entrada.tipo == "numero" then
    texto = valor == 0 and entrada.cero or texto .. " " .. (entrada.unidad or "por ciento")
  end
  return entrada.nombre .. ": " .. texto
end

local function mostrar_estado(texto)
  if configurador.texto_estado == texto then return end
  configurador.estado:SetLabel(texto)
  configurador.estado:Wrap(600)
  configurador.ventana:Layout()
  configurador.texto_estado = texto
end

local function informar(texto)
  mostrar_estado(texto)
  announce(texto)
end

function configurador.salir_ajuste()
  local id = configurador.ajuste
  if not id then return end
  configurador.ajuste = nil
  configurador.arbol:texto(id, etiqueta(definiciones[id]))
  sonido("plegar")
  mostrar_estado("Seleccione una opción.")
end

function configurador.entrar_ajuste(id)
  local entrada = assert(definiciones[id], "La selección no es una opción configurable")
  if configurador.ajuste == id then return end
  configurador.salir_ajuste()
  if configurador.arbol:seleccion() ~= id then configurador.arbol:seleccionar(id) end
  configurador.ajuste = id
  configurador.arbol:texto(id, etiqueta(entrada))
  sonido("desplegar")
  informar("Ajustando valor.")
end

local function cambiar_opcion(entrada, delta)
  local id = entrada.id
  local cambio, limite = configurador.sesion:cambiar(id, delta)
  if cambio then
    audio.aplicar_volumenes(configurador.sesion.valores)
    configurador.arbol:texto(id, etiqueta(entrada))
    local evento = entrada.tipo == "booleano" and "booleano" or "numero"
    if entrada.tipo == "selector" then evento = "selector" end
    if entrada.id:match("^volumen_") then evento = "volumen" end
    sonido(evento)
  end
  if limite then sonido("limite") end
  -- El lector recibe el cambio del nodo nativo. No duplicarlo con announce
  -- ni con otra etiqueta de estado. Sin cambio, el nodo no emite ese aviso.
  if not cambio then announce((valor_ajustado(entrada))) end
  return cambio, limite
end

function configurador.ajustar(delta)
  local id = assert(configurador.ajuste, "No hay un ajuste activo")
  return cambiar_opcion(definiciones[id], delta)
end

-- La vista filtra el foco y los modificadores; las teclas no consumidas
-- continúan por el árbol nativo. El ajuste conserva el nodo seleccionado.
function configurador.tecla(codigo)
  if not configurador.activo or configurador.cerrando then return false end
  local wx = configurador.wx
  local enter = codigo == wx.WXK_RETURN or codigo == wx.WXK_NUMPAD_ENTER
  if configurador.ajuste then
    if enter then
      configurador.guardar()
      return true
    end
    if codigo == wx.WXK_LEFT then configurador.salir_ajuste(); return true end
    if codigo == wx.WXK_UP or codigo == wx.WXK_DOWN then
      configurador.ajustar(codigo == wx.WXK_UP and 1 or -1)
      return true
    end
    if codigo == wx.WXK_RIGHT then return true end
  end
  if codigo ~= wx.WXK_RIGHT and not enter then return false end
  local id = configurador.arbol:seleccion()
  if not id then return false end
  if codigo == wx.WXK_RIGHT and definiciones[id] then configurador.entrar_ajuste(id); return true end
  if enter then configurador.activar(id, true); return true end
  return false
end

local function finalizar(codigo, evento, mensaje)
  configurador.cerrando = true
  configurador.ajuste = nil
  local correcto, error_cierre = pcall(function()
    sonido(evento)
    -- El diálogo se cierra inmediatamente: no recalcular su distribución.
    announce(mensaje)
    configurador.vista:ocultar(codigo)
  end)
  if not correcto then
    configurador.cerrando = false
    error(error_cierre, 0)
  end
  return true
end

function configurador.cerrar()
  if not configurador.activo or configurador.cerrando then return true end
  audio.aplicar_volumenes()
  return finalizar(configurador.wx.wxID_CANCEL, "cancelar", configurador.sesion.guardado
    and "Edición cancelada. Se conserva lo guardado."
    or "Cambios descartados.")
end

function configurador.guardar()
  if not configurador.activo or configurador.cerrando then return nil end
  local ok, guardado, resultado = pcall(function() return configurador.sesion:guardar() end)
  if not ok then
    sonido("error")
    local contexto = configurador.sesion.etapa == "aplicacion"
      and "Preferencias guardadas. Error al aplicar: "
      or "Error al guardar: "
    informar(contexto .. tostring(guardado)
      .. ". Reintente Guardar o cancele la edición pendiente.")
    error(guardado, 0)
  end
  if not guardado then
    sonido("error")
    -- La persistencia ya ha anunciado el error; mantener aquí solo el estado.
    mostrar_estado(tostring(resultado) .. ". Reintente o cancele.")
    return nil, resultado
  end
  local pendientes = resultado.pendientes
  return finalizar(configurador.wx.wxID_OK, "guardar", #pendientes > 0
    and "Configuración guardada. Pendiente: " .. table.concat(pendientes, "; ")
    or "Configuración guardada y aplicada.")
end

function configurador.activar(id, con_enter)
  if not configurador.activo or configurador.cerrando then return end
  local arbol = configurador.arbol
  local seleccionada = definiciones[id]
  if seleccionada then
    if con_enter and not configurador.ajuste and (seleccionada.tipo == "booleano" or seleccionada.tipo == "selector") then
      cambiar_opcion(seleccionada, 1)
    else
      configurador.entrar_ajuste(id)
    end
  elseif id == "restablecer" then
    arbol.control:Expand(arbol.items[id])
    arbol:seleccionar("restablecer_no")
    informar("¿Restablecer valores predeterminados?")
  elseif id == "restablecer_si" or id == "restablecer_no" then
    if id == "restablecer_si" then
      configurador.sesion:reset()
      audio.aplicar_volumenes(configurador.sesion.valores)
      for _, entrada in ipairs(configuracion.opciones) do arbol:texto(entrada.id, etiqueta(entrada)) end
      informar("Predeterminados restablecidos. Pulse Guardar para aplicarlos.")
    end
    arbol:seleccionar("restablecer")
    arbol.control:Collapse(arbol.items.restablecer)
  else
    local item = assert(arbol.items[id], "Nodo de configuración desconocido: " .. tostring(id))
    if not arbol.control:IsExpanded(item) then arbol.control:Expand(item)
    elseif not con_enter then arbol.control:Collapse(item) end
  end
end

function configurador.preparar()
  if configurador.vista then return end
  local vista = ui.nueva("RhomScripts. Configuración.")
  local wx, dialogo = vista.wx, vista.dialogo
  configurador.wx, configurador.ventana, configurador.vista = wx, dialogo, vista
  local correcto, resultado = pcall(function()
    local contenido = wx.wxBoxSizer(wx.wxVERTICAL)
    local ayuda = wx.wxStaticText(dialogo, wx.wxID_ANY,
      "Enter: desplegar, cambiar un selector o booleano, o ajustar un número.\n"
      .. "Flechas: navegar. Derecha despliega o abre el ajuste. Izquierda pliega.\n"
      .. "En un ajuste: Arriba/Abajo cambian el valor; Izquierda vuelve.\n"
      .. "Enter dentro de un ajuste guarda los cambios y cierra.\n"
      .. "Tab: opciones y botones. Escape: cancelar.")
    contenido:Add(ayuda, 0, wx.wxALL, 12)
    local arbol = ui.arbol(wx, dialogo, sonido, "Opciones de configuración", "Configuración")
    configurador.arbol = arbol
    arbol.al_seleccionar = function()
      if configurador.activo and not configurador.cerrando then configurador.salir_ajuste() end
    end
    arbol.control:Connect(wx.wxEVT_KILL_FOCUS, function(evento)
      if configurador.activo and not configurador.cerrando then configurador.salir_ajuste() end
      evento:Skip()
    end)
    arbol:agregar("volumenes", "Volúmenes")
    arbol:agregar("interfaz", "Interfaz")
    arbol:agregar("canales", "Canales")
    arbol:agregar("oficial", "Paquete oficial RLMud_Config")
    for _, entrada in ipairs(configuracion.opciones) do
      arbol:agregar(entrada.id, etiqueta(entrada), entrada.categoria or "volumenes")
    end
    arbol:agregar("restablecer", "Restablecer valores predeterminados")
    arbol:agregar("restablecer_no", "No, conservar el borrador", "restablecer")
    arbol:agregar("restablecer_si", "Sí, restablecer el borrador", "restablecer")
    contenido:Add(arbol.control, 1, wx.wxEXPAND + wx.wxLEFT + wx.wxRIGHT, 12)
    configurador.texto_estado = "Seleccione una opción."
    configurador.estado = wx.wxStaticText(dialogo, wx.wxID_ANY, configurador.texto_estado)
    contenido:Add(configurador.estado, 0, wx.wxALL, 12)
    local botones = wx.wxBoxSizer(wx.wxHORIZONTAL)
    local guardar = ui.boton(wx, dialogo, wx.wxID_ANY, "&Guardar", configurador.guardar)
    local cancelar = ui.boton(wx, dialogo, wx.wxID_CANCEL, "&Cancelar", configurador.cerrar)
    configurador.guardar_boton, configurador.cancelar_boton = guardar, cancelar
    botones:Add(guardar, 0, wx.wxALL, 6)
    botones:Add(cancelar, 0, wx.wxALL, 6)
    contenido:Add(botones, 0, wx.wxALIGN_RIGHT + wx.wxALL, 6)
    dialogo:SetSizerAndFit(contenido)
    dialogo:SetMinSize(dialogo:GetSize())
    vista.controles = { arbol.control, guardar, cancelar }
    vista.cancelar = configurador.cerrar
    vista.tecla = function(evento)
      local foco = wx.wxWindow.FindFocus()
      if not foco or foco:GetId() ~= arbol.control:GetId() or evento:GetModifiers() ~= 0 then return false end
      return configurador.tecla(evento:GetKeyCode())
    end
    arbol.control:Connect(wx.wxEVT_TREE_ITEM_ACTIVATED, function()
      if configurador.activo and not configurador.cerrando then configurador.activar(arbol:seleccion()) end
    end)
    arbol:seleccionar("volumenes")
    vista:preparar()
  end)
  if not correcto then
    local destruido, error_destruccion = pcall(configurador.destruir)
    if not destruido then error(tostring(resultado) .. "\nError al limpiar: " .. tostring(error_destruccion), 0) end
    error(resultado, 0)
  end
end

function configurador.destruir()
  configurador.cerrando = true
  configurador.activo = false
  local vista = configurador.vista
  if configurador.sesion then audio.aplicar_volumenes() end
  if configurador.arbol then configurador.arbol.pronta = false end
  local correcto, mensaje = pcall(function() if vista then vista:destruir() end end)
  configurador.ventana, configurador.arbol, configurador.vista = nil, nil, nil
  configurador.estado, configurador.guardar_boton, configurador.cancelar_boton = nil, nil, nil
  configurador.sesion, configurador.ajuste, configurador.texto_estado = nil, nil, nil
  configurador.cerrando = false
  if not correcto then error(mensaje, 0) end
  return true
end

function configurador.abrir()
  if configurador.cerrando then return end
  if configurador.activo then configurador.ventana:Raise(); return end
  local vista = assert(configurador.vista, "El configurador no se preparó durante el arranque")
  local correcto, resultado = pcall(function()
    configurador.sesion = configurador.nueva_sesion()
    configurador.ajuste = nil
    -- El árbol conserva controles e identificadores; solo escribe textos distintos.
    for _, entrada in ipairs(configuracion.opciones) do
      configurador.arbol:texto(entrada.id, etiqueta(entrada))
    end
    mostrar_estado("Seleccione una opción.")
    configurador.arbol.control:CollapseAll()
    configurador.arbol:seleccionar("volumenes")
    configurador.arbol.pronta, configurador.activo = true, true
    sonido("abrir")
    return vista:mostrar()
  end)
  configurador.cerrando = true
  configurador.activo = false
  configurador.arbol.pronta = false
  -- Cerrar conserva los objetos; invalidar cualquier foco pendiente incluso ante error.
  local oculto, error_ocultar = pcall(function() vista:ocultar() end)
  if configurador.sesion then audio.aplicar_volumenes() end
  configurador.sesion, configurador.ajuste = nil, nil
  configurador.cerrando = false
  if not oculto then
    if not correcto then error(tostring(resultado) .. "\nError al ocultar: " .. tostring(error_ocultar), 0) end
    error(error_ocultar, 0)
  end
  if not correcto then error(resultado, 0) end
  return resultado
end

configurador.pulsaciones = {{
  combinacion = { tecla = mudlet.key.C,
    modificadores = { mudlet.keymodifier.Control, mudlet.keymodifier.Shift } },
  nombre = "configurador.abrir", funcion = configurador.abrir,
  descripcion = "Abre el configurador nativo", grupo = "sistema",
}}
return configurador
