-- Ventanas, controles reutilizables, navegación y operaciones nativas.
-- Las bibliotecas se preparan antes de arrancar, en arranque.lua.
local ui = {}
local ventanas = {}
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
    if not correcto then error(resultado, 0) end
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

function ui.ocultar()
  for ventana in pairs(ventanas) do
    if ventana.mostrando then ventana.cancelar() end
  end
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
    if vista.pronta then sonido("navegar") end
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

local sonidos_configurador = {
  abrir = "abrir_config", cancelar = "cerrar_config", guardar = "aceptar", navegar = "clic_1",
  desplegar = "desplegar", plegar = "plegar",
  numero = "boton_1", booleano = "boton_2", limite = "limite", error = "error",
}
function ui.sonido_configurador(evento)
  require("audio").reproducir("ui." .. assert(sonidos_configurador[evento], "Evento sonoro desconocido"))
end

return ui
