-- Prueba optativa de compatibilidad nativa. No carga la DLL al arrancar.
-- wx conserva su estado nativo entre recargas: no invalidar package.loaded.wx.
local ui = require("ui")
local prueba = { abierta = false, cerrando = false }

function prueba.cerrar()
  if prueba.abierta and not prueba.cerrando then
    prueba.cerrando = true
    prueba.ventana:EndModal(prueba.wx.wxID_CANCEL)
  end
end

function prueba.abrir()
  if prueba.cerrando then return end
  assert(not prueba.abierta, "La ventana de prueba de wxLua ya está abierta")
  local vista = ui.nueva("Prueba de wxLua - RhomScripts")
  local wx, dialogo = vista.wx, vista.dialogo
  prueba.wx = wx
  prueba.ventana = dialogo
  local correcto, resultado = pcall(function()
    local contenido = wx.wxBoxSizer(wx.wxVERTICAL)
    contenido:Add(wx.wxStaticText(dialogo, wx.wxID_ANY, "&Elementos:"), 0, wx.wxALL, 10)
    local lista = wx.wxListBox(dialogo, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxSize(320, 180),
      { "Elemento 1", "Elemento 2", "Elemento 3", "Elemento 4", "Elemento 5" }, wx.wxLB_SINGLE)
    lista:SetName("Elementos")
    lista:SetSelection(0)
    contenido:Add(lista, 1, wx.wxEXPAND + wx.wxLEFT + wx.wxRIGHT, 10)
    local botones = wx.wxBoxSizer(wx.wxHORIZONTAL)
    local aceptar = wx.wxButton(dialogo, wx.wxID_OK, "&Aceptar")
    local cancelar = wx.wxButton(dialogo, wx.wxID_CANCEL, "&Cancelar")
    botones:Add(aceptar, 0, wx.wxALL, 5)
    botones:Add(cancelar, 0, wx.wxALL, 5)
    contenido:Add(botones, 0, wx.wxALIGN_RIGHT + wx.wxALL, 5)
    dialogo:SetSizerAndFit(contenido)
    aceptar:SetDefault()
    prueba.lista, prueba.aceptar, prueba.cancelar = lista, aceptar, cancelar
    vista.controles = { lista, aceptar, cancelar }
    vista.cancelar = prueba.cerrar
    vista.tecla = function() return false end
    prueba.abierta = true
    -- ShowModal aporta la navegación nativa de Tab y los botones estándar.
    -- No inicia ni detiene un MainLoop global de wx; se verifica en Mudlet real.
    vista:preparar()
    return vista:mostrar()
  end)
  prueba.abierta, prueba.cerrando = false, true
  local retirado, error_retirada = pcall(function() vista:destruir() end)
  prueba.ventana, prueba.lista, prueba.aceptar, prueba.cancelar = nil, nil, nil, nil
  prueba.cerrando = false
  if not correcto then
    if not retirado then error(tostring(resultado) .. "\nError al cerrar: " .. tostring(error_retirada), 0) end
    error(resultado, 0)
  end
  if not retirado then error(error_retirada, 0) end
  prueba.ultimo_resultado = resultado
  return resultado
end

prueba.aliases = {
  { name = "pruebawx", pattern = "^pruebawx$", desc = "Abre la prueba nativa de wxLua con cinco elementos",
    action = prueba.abrir },
}

return prueba
