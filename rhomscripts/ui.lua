-- Ventanas, controles reutilizables, navegación y operaciones nativas.
-- Las bibliotecas se preparan antes de arrancar, en arranque.lua.
local ui = {}
local audio = require("audio")
local ventanas = {}
local cierres = {}
local ocultando = false
local continuar_ocultando
local nativo = {}
ui.nativo = nativo

local function runtime_nativo()
  return assert(package.loaded.rhom_nativo_runtime, "Windows no está preparado; ejecute las comprobaciones de arranque")
end

local function propio(runtime, hwnd)
  local pid = runtime.ffi.new("RHOM_DWORD[1]")
  local hilo = runtime.user32.GetWindowThreadProcessId(hwnd, pid)
  return hilo ~= 0 and pid[0] == runtime.kernel32.GetCurrentProcessId()
end

local function validar(runtime, hwnd)
  assert(runtime.user32.IsWindow(hwnd) ~= 0, "Identificador de ventana inválido")
  assert(propio(runtime, hwnd), "La ventana no pertenece a esta instancia de Mudlet")
  return hwnd
end

function nativo.handle(ventana)
  local runtime = runtime_nativo()
  -- GetHandle devuelve lightuserdata, no un número ni el objeto wxWindow.
  return validar(runtime, runtime.ffi.cast("RHOM_HWND", ventana:GetHandle()))
end

function nativo.ventanas()
  local runtime = runtime_nativo()
  local encontradas, error_callback = {}, nil
  local callback = runtime.ffi.cast("RHOM_WNDENUMPROC", function(hwnd)
    local correcto, mensaje = pcall(function()
      if propio(runtime, hwnd) then encontradas[#encontradas + 1] = hwnd end
    end)
    if not correcto then error_callback = mensaje; return 0 end
    return 1
  end)
  local correcto, resultado = pcall(runtime.user32.EnumWindows, callback, 0)
  callback:free()
  if not correcto then error(resultado, 0) end
  if error_callback then error(error_callback, 0) end
  assert(resultado ~= 0, "EnumWindows falló: " .. tostring(runtime.kernel32.GetLastError()))
  return encontradas
end

local function clase(runtime, hwnd)
  local buffer = runtime.ffi.new("unsigned short[256]")
  local cantidad = runtime.user32.GetClassNameW(hwnd, buffer, 256)
  assert(cantidad > 0, "No se pudo identificar la clase de ventana")
  local caracteres = {}
  for indice = 0, cantidad - 1 do
    local codigo = tonumber(buffer[indice])
    -- Las clases Qt utilizadas aquí son ASCII; no interpretar títulos del usuario.
    caracteres[#caracteres + 1] = codigo < 128 and string.char(codigo) or "?"
  end
  return table.concat(caracteres)
end

function nativo.mudlet()
  local runtime = runtime_nativo()
  local user32, null = runtime.user32, runtime.ffi.nullptr
  local activa = user32.GetActiveWindow()
  if activa ~= null then
    local raiz = user32.GetAncestor(activa, 3) -- GA_ROOTOWNER
    if raiz ~= null and propio(runtime, raiz) and clase(runtime, raiz):match("^Qt") then return raiz end
  end
  local candidatas = {}
  for _, hwnd in ipairs(nativo.ventanas()) do
    if user32.IsWindowVisible(hwnd) ~= 0 and user32.GetWindow(hwnd, 4) == null
      and clase(runtime, hwnd):match("^Qt%d+QWindowIcon$") then
      candidatas[#candidatas + 1] = hwnd
    end
  end
  assert(#candidatas == 1, "No se pudo identificar una única ventana de Mudlet; active su ventana y reintente")
  return candidatas[1]
end

function nativo.propietario(ventana)
  return runtime_nativo().user32.GetWindow(nativo.handle(ventana), 4) -- GW_OWNER
end

function nativo.asociar(ventana, propietaria)
  local runtime = runtime_nativo()
  local ffi, user32, kernel32 = runtime.ffi, runtime.user32, runtime.kernel32
  local hwnd = nativo.handle(ventana)
  assert(user32.GetAncestor(hwnd, 2) == hwnd, "Solo se asocian ventanas superiores")
  local destino = propietaria == nil and ffi.nullptr or ffi.cast("RHOM_HWND", propietaria)
  if destino ~= ffi.nullptr then
    validar(runtime, destino)
    assert(user32.GetAncestor(destino, 2) == destino, "La propietaria debe ser una ventana superior")
    local antecesora, pasos = destino, 0
    while antecesora ~= ffi.nullptr do
      assert(antecesora ~= hwnd, "La asociación crearía un ciclo de ventanas")
      pasos = pasos + 1
      assert(pasos < 128, "Cadena de ventanas demasiado larga")
      antecesora = user32.GetWindow(antecesora, 4)
    end
  end
  local anterior = user32.GetWindow(hwnd, 4)
  -- La asociación ya es la solicitada: no volver a escribirla (incluido NULL).
  if anterior == destino then return anterior end
  -- Resolver símbolos y convertir argumentos antes de limpiar LastError:
  -- la carga de un símbolo puede modificar el error nativo del hilo.
  local asignar = user32.SetWindowLongPtrW
  local limpiar, leer_error = kernel32.SetLastError, kernel32.GetLastError
  local valor = ffi.cast("RHOM_LONG_PTR", destino)
  limpiar(0)
  local resultado = asignar(hwnd, -8, valor)
  local error_windows = leer_error()
  assert(not (ffi.tonumber(resultado) == 0 and error_windows ~= 0),
    "No se pudo asociar la ventana: " .. tostring(error_windows))
  assert(user32.GetWindow(hwnd, 4) == destino, "Windows no confirmó la asociación de ventanas")
  return anterior
end


function ui.nueva(titulo)
  local flotante = require("configuracion").get("ventanasflotantes")
  local propietaria
  if flotante then propietaria = nativo.mudlet() end
  local wx = assert(package.loaded.wx, "wxLua no está preparado; ejecute las comprobaciones de arranque")
  local ventana = { wx = wx, controles = {}, propietaria = propietaria, flotante = flotante, generacion = 0 }
  ventana.dialogo = wx.wxDialog(wx.NULL, wx.wxID_ANY, titulo,
    wx.wxDefaultPosition, wx.wxDefaultSize,
    wx.wxDEFAULT_DIALOG_STYLE + wx.wxRESIZE_BORDER + wx.wxDIALOG_NO_PARENT)
  if flotante then
    local correcto, mensaje = pcall(nativo.asociar, ventana.dialogo, propietaria)
    if not correcto then
      local retirado, error_retirada = pcall(function()
        ventana.dialogo:Destroy()
        wx.wxGetApp():Yield(true)
      end)
      if not retirado then error(tostring(mensaje) .. "\nError al cerrar: " .. tostring(error_retirada), 0) end
      error(mensaje, 0)
    end
  end
  function ventana:pasar_foco(delta)
    local foco = wx.wxWindow.FindFocus()
    local indice = 1
    for i, control in ipairs(self.controles) do
      if foco and foco:GetId() == control:GetId() then indice = i; break end
    end
    self.controles[(indice - 1 + delta) % #self.controles + 1]:SetFocus()
  end
  function ventana:tratar_tecla(evento)
    local codigo, modificadores = evento:GetKeyCode(), evento:GetModifiers()
    if codigo == wx.WXK_ESCAPE then self.cancelar()
    elseif codigo == wx.WXK_TAB and (modificadores == 0 or modificadores == wx.wxMOD_SHIFT) then
      local delta = modificadores == wx.wxMOD_SHIFT and -1 or 1
      if self.tab then self.tab(delta) else self:pasar_foco(delta) end
    elseif not self.tecla(evento) then evento:Skip() end
  end
  ventana.dialogo:Connect(wx.wxEVT_CHAR_HOOK, function(evento) ventana:tratar_tecla(evento) end)
  ventana.dialogo:Connect(wx.wxEVT_CLOSE_WINDOW, function() ventana.cancelar() end)
  -- Preparar no muestra ventanas ni solicita foco o sonidos.
  function ventana:preparar()
    if self.preparada then return end
    self.dialogo:CentreOnScreen()
    self.preparada = true
  end
  function ventana:sincronizar_asociacion()
    local asociada = require("configuracion").get("ventanasflotantes")
    if self.flotante == asociada then return false end
    local destino
    if asociada then destino = nativo.mudlet() end
    nativo.asociar(self.dialogo, destino)
    self.flotante, self.propietaria = asociada, destino
    return true
  end
  function ventana:mostrar()
    assert(not self.destruida and self.preparada, "La ventana no está preparada")
    assert(not self.mostrando, "La ventana ya está mostrada")
    self:sincronizar_asociacion()
    self.generacion = self.generacion + 1
    local generacion = self.generacion
    self.mostrando = true
    local correcto, resultado = pcall(function()
      self.dialogo:CallAfter(function()
        if self.mostrando and self.generacion == generacion then
          self.dialogo:Raise()
          self.controles[1]:SetFocus()
        end
      end)
      return self.dialogo:ShowModal()
    end)
    self.mostrando = false
    self.generacion = self.generacion + 1
    local cierre_global = ocultando
    -- EndModal del padre debe esperar a que ShowModal del hijo haya retornado.
    -- Cerrarlo mientras sigue ejecutándose el bucle hijo puede dejarlo bloqueado.
    if ocultando then continuar_ocultando() end
    if not correcto then error(resultado, 0) end
    if not cierre_global then
      for _, callback in pairs(cierres) do callback() end
    end
    return resultado
  end
  function ventana:ocultar(codigo)
    if self.destruida then return end
    self.generacion = self.generacion + 1
    if not self.dialogo:IsShown() then return end
    if self.dialogo:IsModal() then self.dialogo:EndModal(codigo or wx.wxID_CANCEL)
    else self.dialogo:Show(false) end
  end
  function ventana:destruir()
    if self.destruida then return end
    assert(not self.mostrando, "No se puede destruir una ventana hasta que termine su diálogo")
    self:ocultar()
    self.mostrando = false
    assert(self.dialogo:Destroy(), "No se pudo destruir la ventana")
    self.destruida = true
    ventanas[self] = nil
    wx.wxGetApp():Yield(true)
  end
  ventanas[ventana] = true
  return ventana
end

-- Los dominios pueden posponer una apertura hasta que termine el diálogo actual.
function ui.al_cerrar(propietario, callback) cierres[propietario] = callback end
function ui.retirar_al_cerrar(propietario) cierres[propietario] = nil end

-- Los dominios construyen sus controles en preparar(), antes de ready.
function ui.preparar()
  local nombres = {}
  for nombre in pairs(RhomScripts.modules) do nombres[#nombres + 1] = nombre end
  table.sort(nombres)
  for _, nombre in ipairs(nombres) do
    local modulo = RhomScripts.modules[nombre]
    if modulo.preparar then modulo.preparar() end
  end
  for ventana in pairs(ventanas) do ventana:preparar() end
end

function ui.ocupada()
  for ventana in pairs(ventanas) do if ventana.mostrando then return true end end
  return false
end

continuar_ocultando = function()
  local pendientes = false
  for ventana in pairs(ventanas) do
    if ventana.mostrando then
      pendientes = true
      local tiene_hijo = false
      for otra in pairs(ventanas) do
        if otra.mostrando then
          local padre = otra.padre
          while padre do
            if padre == ventana then tiene_hijo = true; break end
            padre = padre.padre
          end
        end
        if tiene_hijo then break end
      end
      if not tiene_hijo then ventana.cancelar() end
    end
  end
  ocultando = pendientes
end

function ui.ocultar()
  ocultando = true
  for ventana in pairs(ventanas) do
    -- Invalidar ya el retorno del foco del detalle aunque el cierre del padre
    -- se difiera hasta que termine el diálogo descendiente.
    if ventana.mostrando then ventana.generacion = ventana.generacion + 1 end
  end
  continuar_ocultando()
end

function ui.destruir()
  local pendientes, errores = {}, {}
  for ventana in pairs(ventanas) do pendientes[#pendientes + 1] = ventana end
  for _, ventana in ipairs(pendientes) do
    local correcto, mensaje = pcall(function() ventana:destruir() end)
    if not correcto then errores[#errores + 1] = tostring(mensaje) end
  end
  if #errores > 0 then error(table.concat(errores, "\n"), 0) end
end


-- Sonido común de pestañas, también para cambios de categoría mediante atajos.
function ui.sonido_pestana(clave)
  return audio.reproducir(clave or "ui.pestana")
end

-- Política común de pulsación, compartida por botones nativos y sus atajos.
function ui.pulsar_boton(accion, ...)
  audio.reproducir("ui.boton_1")
  return accion(...)
end

function ui.boton(wx, padre, id, texto, accion)
  local boton = wx.wxButton(padre, id, texto)
  boton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, function() ui.pulsar_boton(accion) end)
  return boton
end

function ui.arbol(wx, padre, sonido, nombre, raiz)
  assert(type(nombre) == "string" and nombre ~= "", "Falta el nombre accesible del árbol")
  assert(type(raiz) == "string" and raiz ~= "", "Falta la raíz del árbol")
  local vista = { items = {}, etiquetas = {} }
  local control = wx.wxTreeCtrl(padre, wx.wxID_ANY, wx.wxDefaultPosition,
    wx.wxSize(600, 350), wx.wxTR_DEFAULT_STYLE + wx.wxTR_HIDE_ROOT)
  vista.control = control
  control:SetName(nombre)
  vista.raiz = control:AddRoot(raiz)
  function vista:agregar(id, texto, padre_id)
    local item = control:AppendItem(padre_id and self.items[padre_id] or self.raiz,
      texto, -1, -1, wx.wxLuaTreeItemData(id))
    self.items[id] = item
    self.etiquetas[id] = texto
    return item
  end
  function vista:seleccion()
    local item = self.control:GetSelection()
    if not item:IsOk() then return nil end
    return control:GetItemData(item):GetData()
  end
  function vista:seleccionar(id)
    control:SelectItem(assert(self.items[id]))
    control:EnsureVisible(self.items[id])
  end
  function vista:texto(id, texto)
    local item = assert(self.items[id])
    if self.etiquetas[id] == texto then return false end
    control:SetItemText(item, texto)
    self.etiquetas[id] = texto
    return true
  end
  -- Actualizar etiquetas no simula navegación.
  control:Connect(wx.wxEVT_TREE_SEL_CHANGED, function(evento)
    if vista.al_seleccionar then vista.al_seleccionar(vista:seleccion()) end
    if vista.pronta then audio.reproducir("ui.clic_1") end
    evento:Skip()
  end)
  control:Connect(wx.wxEVT_TREE_ITEM_EXPANDED, function(evento)
    if vista.pronta then sonido("desplegar") end
    evento:Skip()
  end)
  control:Connect(wx.wxEVT_TREE_ITEM_COLLAPSED, function(evento)
    if vista.pronta then sonido("plegar") end
    evento:Skip()
  end)
  return vista
end

-- Lista persistente: los dominios entregan datos/acciones; el componente conserva
-- identidad y foco. Las pestañas son páginas nativas que comparten el panel.
function ui.lista(ventana, opciones)
  local wx, dialogo = ventana.wx, ventana.dialogo
  local lista = { elementos = {}, indices = {}, botones = {}, paginas = {}, orden = {}, cache = {}, opciones = opciones }
  local sonido = assert(opciones.sonido, "Falta el contrato sonoro de la lista")
  local contenido = wx.wxPanel(dialogo, wx.wxID_ANY)
  local horizontal = wx.wxBoxSizer(wx.wxHORIZONTAL)
  local control = wx.wxListCtrl(contenido, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxSize(700, 360),
    wx.wxLC_REPORT + wx.wxLC_SINGLE_SEL)
  lista.control, lista.panel = control, contenido
  control:SetName(opciones.nombre or "Elementos")
  for i, columna in ipairs(opciones.columnas) do
    assert(control:InsertColumn(i - 1, columna.titulo, wx.wxLIST_FORMAT_LEFT, columna.ancho) == i - 1)
  end
  horizontal:Add(control, 1, wx.wxEXPAND)
  local acciones_sizer = wx.wxBoxSizer(wx.wxVERTICAL)
  horizontal:Add(acciones_sizer, 0, wx.wxEXPAND + wx.wxLEFT, 12)
  contenido:SetSizer(horizontal)
  lista.sizer = wx.wxBoxSizer(wx.wxVERTICAL)
  if opciones.pestanas then
    lista.pestanyas = wx.wxNotebook(dialogo, wx.wxID_ANY)
    lista.pestanyas:SetName(opciones.nombre_pestanas or "Pestañas")
    lista.sizer:Add(lista.pestanyas, 1, wx.wxEXPAND)
  else lista.sizer:Add(contenido, 1, wx.wxEXPAND) end
  local function posicion_foco()
    local foco = wx.wxWindow.FindFocus()
    if not foco then return nil end
    if foco:GetId() == control:GetId() then return 0 end
    for i, boton in ipairs(lista.botones) do if foco:GetId() == boton:GetId() then return i end end
  end
  local function emitir(evento)
    if ventana.mostrando then sonido(evento) end
  end
  function lista:seleccionado() return self.indices[self.seleccion] and self.elementos[self.indices[self.seleccion]] end
  function lista:refrescar_acciones()
    local elemento = self:seleccionado()
    self.acciones = elemento and opciones.acciones and opciones.acciones(elemento) or {}
    assert(#self.acciones <= #self.botones, "El número de acciones supera max_acciones preparado")
    for i, boton in ipairs(self.botones) do
      local accion = self.acciones[i]
      if accion then
        if boton:GetLabel() ~= accion.nombre then boton:SetLabel(accion.nombre) end
        local nombre = accion.nombre .. ": " .. table.concat(elemento.textos, ". ")
        if boton:GetName() ~= nombre then boton:SetName(nombre) end
        if boton:IsEnabled() ~= (accion.habilitada ~= false) then boton:Enable(accion.habilitada ~= false) end
      end
      if boton:IsShown() ~= (accion ~= nil) then boton:Show(accion ~= nil) end
    end
    contenido:Layout()
  end
  function lista:ejecutar_accion(indice)
    local accion, elemento = self.acciones[indice], self:seleccionado()
    if not elemento or not accion or accion.habilitada == false then emitir("limite"); return false end
    if self.ejecutando then return false end
    self.ejecutando = true
    local correcto, resultado = pcall(ui.pulsar_boton, accion.ejecutar, elemento)
    self.ejecutando = false
    if not correcto then error(resultado, 0) end
    return true
  end
  for i = 1, opciones.max_acciones or 3 do
    local indice = i
    local boton = wx.wxButton(contenido, wx.wxID_ANY, "")
    lista.botones[i] = boton
    acciones_sizer:Add(boton, 0, wx.wxEXPAND + wx.wxBOTTOM, 6)
    boton:Show(false)
    boton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, function() lista:ejecutar_accion(indice) end)
  end
  function lista:seleccionar(id, visible)
    local indice = self.indices[id]
    self.seleccion = indice and id or nil
    self.actualizando = true
    local estado = wx.wxLIST_STATE_SELECTED + wx.wxLIST_STATE_FOCUSED
    local seleccionada = control:GetNextItem(-1, wx.wxLIST_NEXT_ALL, wx.wxLIST_STATE_SELECTED)
    if seleccionada >= 0 and seleccionada ~= (indice and indice - 1) then
      assert(control:SetItemState(seleccionada, 0, estado))
    end
    if indice then
      if control:GetItemState(indice - 1, estado) ~= estado then
        assert(control:SetItemState(indice - 1, estado, estado))
      end
      if visible then control:EnsureVisible(indice - 1) end
    end
    self.actualizando = false
    self:refrescar_acciones()
    return self:seleccionado()
  end
  function lista:primero()
    return self:seleccionar(self.elementos[1] and self.elementos[1].id, true)
  end
  function lista:actualizar(elementos, ajustes)
    ajustes = ajustes or {}
    local anteriores = self.elementos
    local anterior, indice_anterior, foco = self.seleccion, self.indices[self.seleccion], posicion_foco()
    local accion_anterior = foco and foco > 0 and self.acciones[foco] and self.acciones[foco].id
    local deseados = {}
    for _, elemento in ipairs(elementos) do
      assert(elemento.id ~= nil and not deseados[elemento.id], "Identificador de lista ausente o duplicado")
      deseados[elemento.id] = elemento
    end
    self.actualizando = true
    for i = #self.orden, 1, -1 do
      if not deseados[self.orden[i]] then
        assert(control:DeleteItem(i - 1))
        self.cache[self.orden[i]] = nil
        table.remove(self.orden, i)
      end
    end
    for i, elemento in ipairs(elementos) do
      local insertado = false
      if self.orden[i] ~= elemento.id then
        local existente
        if self.indices[elemento.id] then
          for j = i + 1, #self.orden do if self.orden[j] == elemento.id then existente = j; break end end
        end
        if existente then assert(control:DeleteItem(existente - 1)); table.remove(self.orden, existente) end
        assert(control:InsertItem(i - 1, elemento.textos[1]) == i - 1)
        table.insert(self.orden, i, elemento.id)
        insertado = true
      end
      local cache = self.cache[elemento.id] or { textos = {} }
      for j, texto in ipairs(elemento.textos) do
        if (insertado and j > 1) or (not insertado and cache.textos[j] ~= texto) then
          assert(control:SetItem(i - 1, j - 1, texto))
        end
        cache.textos[j] = texto
      end
      local token = type(elemento.id) == "number" and elemento.id or i
      if insertado or cache.token ~= token then assert(control:SetItemData(i - 1, token)) end
      cache.token = token
      self.cache[elemento.id] = cache
    end
    self.elementos, self.indices = elementos, {}
    for i, elemento in ipairs(elementos) do self.indices[elemento.id] = i end
    self.actualizando = false
    local id = ajustes.seleccion or anterior
    if ajustes.primero then id = elementos[1] and elementos[1].id end
    local retirado = anterior ~= nil and not self.indices[anterior]
    if not self.indices[id] then
      id = nil
      if indice_anterior then
        for i = indice_anterior + 1, #anteriores do
          if self.indices[anteriores[i].id] then id = anteriores[i].id; break end
        end
        if not id then
          for i = indice_anterior - 1, 1, -1 do
            if self.indices[anteriores[i].id] then id = anteriores[i].id; break end
          end
        end
      end
      if not id then id = elementos[1] and elementos[1].id end
    end
    self:seleccionar(id, ajustes.primero or ajustes.visible)
    if foco and foco > 0 then
      local destino
      if not retirado and anterior == self.seleccion then
        for i, accion in ipairs(self.acciones) do
          if accion.id == accion_anterior and accion.habilitada ~= false then destino = self.botones[i]; break end
        end
      end
      if ventana.mostrando then (destino or control):SetFocus() end
      if retirado and ventana.mostrando and ajustes.aviso_retirado ~= false then
        announce("El elemento seleccionado se ha retirado. Se ha vuelto a la lista.")
      end
    end
  end
  function lista:activar()
    local elemento = self:seleccionado()
    if not elemento or not opciones.activar then emitir("limite"); return false end
    if self.ejecutando then return false end
    self.ejecutando = true
    local correcto, resultado = pcall(opciones.activar, elemento)
    self.ejecutando = false
    if not correcto then error(resultado, 0) end
    return true
  end
  function lista:tecla(codigo, modificadores)
    local foco = posicion_foco()
    if foco == nil then return false end
    if modificadores ~= 0 then return false end
    if codigo == wx.WXK_RETURN or codigo == wx.WXK_NUMPAD_ENTER then
      if foco == 0 then self:activar() else self:ejecutar_accion(foco) end
      return true
    end
    if foco > 0 and codigo == wx.WXK_SPACE then self:ejecutar_accion(foco); return true end
    if codigo == wx.WXK_LEFT or codigo == wx.WXK_RIGHT then
      local delta = codigo == wx.WXK_RIGHT and 1 or -1
      local nuevo = foco + delta
      while nuevo > 0 and nuevo <= #self.acciones and self.acciones[nuevo].habilitada == false do nuevo = nuevo + delta end
      if nuevo == 0 then control:SetFocus()
      elseif nuevo > 0 and nuevo <= #self.acciones then self.botones[nuevo]:SetFocus()
      else emitir("limite") end
      return true
    end
    if codigo == wx.WXK_UP or codigo == wx.WXK_DOWN then
      if foco > 0 then return true end
      local indice = self.indices[self.seleccion]
      if not indice or (codigo == wx.WXK_UP and indice == 1)
        or (codigo == wx.WXK_DOWN and indice == #self.elementos) then emitir("limite"); return true end
    end
    return false
  end
  control:Connect(wx.wxEVT_COMMAND_LIST_ITEM_SELECTED, function(evento)
    if not lista.actualizando then
      local elemento = lista.elementos[evento:GetIndex() + 1]
      lista.seleccion = elemento and elemento.id
      lista:refrescar_acciones()
      if opciones.al_seleccionar then opciones.al_seleccionar(elemento) end
      if ventana.mostrando then audio.reproducir("ui.clic_1") end
    end
    evento:Skip()
  end)
  control:Connect(wx.wxEVT_COMMAND_LIST_ITEM_ACTIVATED, function(evento)
    if lista.actualizando or not ventana.mostrando then return end
    local elemento = lista.elementos[evento:GetIndex() + 1]
    lista:seleccionar(elemento and elemento.id)
    lista:activar()
  end)
  local function alojar(id)
    if lista.alojada == id then return end
    if lista.alojada then assert(lista.paginas[lista.alojada].sizer:Detach(contenido)) end
    local pagina = assert(lista.paginas[id])
    assert(contenido:Reparent(pagina.panel))
    pagina.sizer:Add(contenido, 1, wx.wxEXPAND)
    lista.alojada = id
    contenido:Show(true)
    pagina.panel:Layout()
  end
  function lista:seleccionar_pestana(id, silencioso)
    if not self.paginas[id] then return false end
    local anterior = self.pestana
    self.pestana = id
    alojar(id)
    self.pestanyas:ChangeSelection(self.paginas[id].indice - 1)
    if not silencioso and anterior ~= id then
      if opciones.al_pestana then opciones.al_pestana(id) end
      if ventana.mostrando then ui.sonido_pestana(opciones.sonido_pestana) end
      if ventana.mostrando then control:SetFocus() end
    end
    return true
  end
  function lista:actualizar_pestanas(paginas, preferida)
    assert(self.pestanyas, "La lista no tiene pestañas")
    self.actualizando_pestanas = true
    local deseadas = {}
    for _, pagina in ipairs(paginas) do assert(not deseadas[pagina.id], "Pestaña duplicada"); deseadas[pagina.id] = true end
    -- Apartar el contenido solo si desaparece su página.
    if self.alojada and not deseadas[self.alojada] then
      assert(self.paginas[self.alojada].sizer:Detach(contenido))
      assert(contenido:Reparent(dialogo))
      contenido:Show(false)
      self.alojada = nil
    end
    local orden = self.ids_pestanas or {}
    for i = #orden, 1, -1 do
      local id = orden[i]
      if not deseadas[id] then
        assert(self.pestanyas:DeletePage(i - 1))
        self.paginas[id] = nil
        table.remove(orden, i)
      end
    end
    -- Insertar, mover y renombrar sin reconstruir las pestañas conservadas.
    for i, datos in ipairs(paginas) do
      local pagina = self.paginas[datos.id]
      if not pagina then
        pagina = { panel = wx.wxPanel(self.pestanyas, wx.wxID_ANY), sizer = wx.wxBoxSizer(wx.wxVERTICAL) }
        pagina.panel:SetSizer(pagina.sizer)
        self.paginas[datos.id] = pagina
      end
      if orden[i] ~= datos.id then
        local existente
        for j = i + 1, #orden do if orden[j] == datos.id then existente = j; break end end
        if existente then assert(self.pestanyas:RemovePage(existente - 1)); table.remove(orden, existente) end
        assert(self.pestanyas:InsertPage(i - 1, pagina.panel, datos.nombre, false))
        table.insert(orden, i, datos.id)
      elseif self.pestanyas:GetPageText(i - 1) ~= datos.nombre then
        assert(self.pestanyas:SetPageText(i - 1, datos.nombre))
      end
      pagina.indice = i
    end
    self.ids_pestanas = orden
    local id = preferida or self.pestana
    if not self.paginas[id] then id = paginas[1] and paginas[1].id end
    if id then self:seleccionar_pestana(id, true) else self.pestana = nil end
    self.actualizando_pestanas = false
  end
  function lista:cambiar_pestana(delta)
    local cantidad = #(self.ids_pestanas or {})
    if cantidad < 2 then emitir("limite"); return false end
    local indice = self.paginas[self.pestana].indice
    return self:seleccionar_pestana(self.ids_pestanas[(indice - 1 + delta) % cantidad + 1])
  end
  if lista.pestanyas then
    lista.pestanyas:Connect(wx.wxEVT_COMMAND_NOTEBOOK_PAGE_CHANGED, function(evento)
      if not lista.actualizando_pestanas then
        local id = lista.ids_pestanas[evento:GetSelection() + 1]
        if id then lista:seleccionar_pestana(id) end
      end
      evento:Skip()
    end)
    ventana.tab = function(delta) lista:cambiar_pestana(delta) end
  end
  ventana.controles = { control }
  return lista
end

-- El detalle se prepara con su propietario. Su texto es una instantánea y no
-- cambia cuando el historial recibe mensajes o elimina registros antiguos.
function ui.detalle(padre, opciones)
  opciones = opciones or {}
  local vista = ui.nueva(opciones.titulo or "Detalle del mensaje")
  vista.padre = padre
  local wx = vista.wx
  local detalle = { vista = vista }
  local contenido = wx.wxBoxSizer(wx.wxVERTICAL)
  detalle.control = wx.wxTextCtrl(vista.dialogo, wx.wxID_ANY, "", wx.wxDefaultPosition,
    wx.wxSize(650, 350), wx.wxTE_MULTILINE + wx.wxTE_READONLY)
  detalle.control:SetName("Texto completo del mensaje")
  contenido:Add(detalle.control, 1, wx.wxEXPAND + wx.wxALL, 12)
  vista.dialogo:SetSizerAndFit(contenido)
  vista.controles = { detalle.control }
  vista.tecla = function() return false end
  function detalle:cerrar() self.vista:ocultar() end
  vista.cancelar = function() detalle:cerrar() end
  function detalle:mostrar(texto)
    assert(type(texto) == "string", "El detalle necesita texto")
    if vista.mostrando then return end
    self.control:ChangeValue(texto)
    self.control:SetInsertionPoint(0)
    local foco = wx.wxWindow.FindFocus()
    local generacion = padre.generacion
    local correcto, resultado = pcall(function()
      if opciones.sonido then opciones.sonido("abrir") end
      return vista:mostrar()
    end)
    vista:ocultar()
    if padre.mostrando and padre.generacion == generacion then
      if foco then foco:SetFocus() end
      if opciones.sonido then opciones.sonido("cerrar") end
    end
    if not correcto then error(resultado, 0) end
    return resultado
  end
  function detalle:destruir() self.vista:destruir() end
  vista:preparar()
  return detalle
end

return ui
