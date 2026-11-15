-- Ensayo optativo: asociar/desasociar ventanas sin cambiar el configurador.
local ui = require("ui")
local nativo = ui.nativo
local prueba = { abierta = false, cerrando = false, nativo = nativo }

function prueba.cerrar()
  if prueba.abierta and not prueba.cerrando then
    prueba.cerrando = true
    prueba.ventana:EndModal(prueba.wx.wxID_CANCEL)
  end
  return true
end

function prueba.vincular()
  if not prueba.abierta or prueba.cerrando then return end
  nativo.asociar(prueba.ventana, prueba.propietaria)
  prueba.estado:SetLabel("Asociada a Mudlet.")
  announce("Asociada a Mudlet.")
end

function prueba.desvincular()
  if not prueba.abierta or prueba.cerrando then return end
  nativo.asociar(prueba.ventana, nil)
  prueba.estado:SetLabel("Ventana independiente.")
  announce("Ventana independiente.")
end

function prueba.abrir()
  if prueba.cerrando then return end
  if prueba.abierta then prueba.ventana:Raise(); return end
  -- Capturar la propietaria Qt antes de abrir nuestro diálogo wx.
  local propietaria = nativo.mudlet()
  local vista = ui.nueva("RhomScripts. Prueba de asociación.")
  local wx, dialogo = vista.wx, vista.dialogo
  prueba.wx, prueba.ventana, prueba.propietaria = wx, dialogo, propietaria
  local correcto, resultado = pcall(function()
    local contenido = wx.wxBoxSizer(wx.wxVERTICAL)
    contenido:Add(wx.wxStaticText(dialogo, wx.wxID_ANY,
      "Compare la ventana asociada con la independiente.\nVincular y Desvincular cambian solo esta prueba. Escape cierra."), 0, wx.wxALL, 12)
    local lista = wx.wxListBox(dialogo, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxSize(420, 180),
      { "Elemento 1", "Elemento 2", "Elemento 3", "Elemento 4", "Elemento 5" }, wx.wxLB_SINGLE)
    lista:SetName("Elementos de prueba")
    lista:SetSelection(0)
    prueba.lista = lista
    contenido:Add(lista, 1, wx.wxEXPAND + wx.wxLEFT + wx.wxRIGHT, 12)
    prueba.estado = wx.wxStaticText(dialogo, wx.wxID_ANY,
      vista.propietaria and "Asociada a Mudlet." or "Ventana independiente.")
    contenido:Add(prueba.estado, 0, wx.wxALL, 12)
    local botones = wx.wxBoxSizer(wx.wxHORIZONTAL)
    local vincular = wx.wxButton(dialogo, wx.wxID_ANY, "&Vincular")
    local desvincular = wx.wxButton(dialogo, wx.wxID_ANY, "&Desvincular")
    local cerrar = wx.wxButton(dialogo, wx.wxID_CANCEL, "&Cerrar")
    prueba.vincular_boton, prueba.desvincular_boton, prueba.cerrar_boton = vincular, desvincular, cerrar
    for _, boton in ipairs({ vincular, desvincular, cerrar }) do botones:Add(boton, 0, wx.wxALL, 6) end
    contenido:Add(botones, 0, wx.wxALIGN_RIGHT + wx.wxALL, 6)
    dialogo:SetSizerAndFit(contenido)
    vincular:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, prueba.vincular)
    desvincular:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, prueba.desvincular)
    cerrar:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, prueba.cerrar)
    vista.controles = { lista, vincular, desvincular, cerrar }
    vista.cancelar = prueba.cerrar
    vista.tecla = function() return false end
    prueba.abierta = true
    vista:preparar()
    return vista:mostrar()
  end)
  prueba.abierta, prueba.cerrando = false, true
  local destruido, error_destruccion = pcall(function() vista:destruir() end)
  prueba.ventana, prueba.lista, prueba.estado, prueba.propietaria = nil, nil, nil, nil
  prueba.vincular_boton, prueba.desvincular_boton, prueba.cerrar_boton = nil, nil, nil
  prueba.cerrando = false
  if not correcto then
    if not destruido then error(tostring(resultado) .. "\nError al cerrar: " .. tostring(error_destruccion), 0) end
    error(resultado, 0)
  end
  if not destruido then error(error_destruccion, 0) end
  return resultado
end

prueba.aliases = {{ name = "pruebacffi", pattern = "^pruebacffi$",
  desc = "Prueba la asociación de una ventana nativa a Mudlet", action = prueba.abrir }}
return prueba
