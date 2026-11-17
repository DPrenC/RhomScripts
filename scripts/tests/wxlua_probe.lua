-- Prueba nativa aislada: no instala paquetes del juego ni toca portapapeles.
local root, result_path = RHOM_WX_ROOT, RHOM_WX_RESULT
assert(getMudletHomeDir() == RHOM_WX_PROFILE, "El perfil no está en la carpeta aislada prevista")
RhomScripts = { root = root .. "/rhomscripts", modules = {} }
RhomScripts.modules.debug = assert(loadfile(RhomScripts.root .. "/debug.lua"))()
package.path = RhomScripts.root .. "/?.lua;" .. root .. "/rhomscripts old/?.lua;" .. package.path
local config = require("configuracion")
assert(config.load())
local comprobaciones = require("arranque")
comprobaciones.bibliotecas()
local nativo = require("ui").nativo

local results, timers = {}, {}
local ticks, finished = 0, false
local demo = require("prueba_wxlua")

local function journal(message)
  local file = assert(io.open(result_path .. ".progress", "a"))
  file:write(message, "\n")
  file:close()
end

local function after(delay, action)
  local id
  id = tempTimer(delay, function()
    timers[id] = nil
    action()
  end)
  timers[id] = true
  return id
end

local function beat()
  if finished then return end
  ticks = ticks + 1
  after(0.1, beat)
end

local function finish(ok, message)
  finished = true
  for id in pairs(timers) do killTimer(id) end
  timers = {}
  local file = assert(io.open(result_path .. ".tmp", "w"))
  file:write(ok and "STATUS OK\n" or "STATUS ERROR\n")
  file:write("VERSION ", getMudletVersion("string"), "\nLUA ", _VERSION, "\n")
  if demo.wx then file:write("WX ", demo.wx.wxVERSION_STRING, "\n") end
  file:write("QT_HEARTBEAT ", tostring(ticks), "\n")
  file:write("OMITIDA Teclado físico y lector externo: esta prueba no los simula\n")
  file:write("OMITIDA Portapapeles: conservado sin lecturas ni modificaciones\n")
  for _, name in ipairs(results) do file:write("CASE ", name, "\n") end
  if not ok then file:write("ERROR ", tostring(message), "\n") end
  file:close()
  assert(os.rename(result_path .. ".tmp", result_path))
end

local function equal(actual, expected)
  assert(actual == expected, "Esperado " .. tostring(expected) .. "; obtenido " .. tostring(actual))
end

local function exercise(name, button, interactive)
  local delayed_error
  local before = ticks
  local window_name = "RhomScripts_wxLua_probe_" .. tostring(#results + 1)
  journal("ABRIR " .. name)
  after(1, function()
    local ok, message = xpcall(function()
      assert(demo.abierta and demo.ventana and demo.lista, "El diálogo no permanece abierto")
      local runtime = comprobaciones.cargar_nativo()
      equal(nativo.propietario(demo.ventana), config.get("ventanasflotantes") and nativo.mudlet() or runtime.ffi.nullptr)
      demo.ventana:SetName(window_name)
      equal(demo.lista:GetCount(), 5)
      for index = 0, 4 do equal(demo.lista:GetString(index), "Elemento " .. tostring(index + 1)) end
      equal(demo.lista:GetSelection(), 0)
      local foco = demo.wx.wxWindow.FindFocus()
      journal("FOCO " .. (foco and foco:GetName() or "ninguno"))
      -- FindFocus devuelve wxWindow; wxLua puede crear otro userdata para el
      -- mismo control wxListBox. Comparar la identidad nativa, no la tabla Lua.
      assert(foco and foco:GetId() == demo.lista:GetId(), "El foco inicial no corresponde a la lista")
      assert(ticks > before + 2, "El bucle modal no permite avanzar temporizadores Qt")
      journal("VISIBLE " .. name .. " QT_HEARTBEAT " .. tostring(ticks - before))
      if interactive then
        journal("INTERACTIVA: comprobar Tab y flechas físicamente; cerrar con Aceptar o Cancelar")
        return
      end
      demo.lista:SetSelection(4)
      equal(demo.lista:GetSelection(), 4)
      if button == "cerrar" then
        assert(demo.ventana:Close(), "La ventana rechazó el cierre")
      else
        local wx = demo.wx
        local id = button == "aceptar" and wx.wxID_OK or wx.wxID_CANCEL
        local source = button == "aceptar" and demo.aceptar or demo.cancelar
        local event = wx.wxCommandEvent(wx.wxEVT_COMMAND_BUTTON_CLICKED, id)
        event:SetEventObject(source)
        assert(source:ProcessWindowEvent(event), "El botón no procesó el evento nativo")
        event:delete()
      end
    end, debug.traceback)
    if not ok then
      delayed_error = message
      journal("FALLO DIFERIDO " .. tostring(message))
      demo.cerrar()
    end
  end)
  local result = demo.abrir()
  assert(not delayed_error, delayed_error)
  local wx = demo.wx
  if interactive then assert(result == wx.wxID_OK or result == wx.wxID_CANCEL)
  else equal(result, button == "aceptar" and wx.wxID_OK or wx.wxID_CANCEL) end
  assert(not demo.abierta and not demo.ventana and not demo.lista, "Quedaron referencias de ventana abiertas")
  local remaining = wx.wxWindow.FindWindowByName(window_name)
  assert(not remaining or remaining == wx.NULL, "La ventana nativa sigue registrada después de Destroy/Yield")
  journal("CERRADA " .. name .. " RESULTADO " .. tostring(result))
  results[#results + 1] = name
end

local function run()
  journal("INICIO " .. getMudletVersion("string") .. " PERFIL " .. getMudletHomeDir())
  after(0.1, beat)
  if RHOM_WX_INTERACTIVE then
    exercise("Ventana interactiva: cinco elementos y botones", nil, true)
  else
    config.set("ventanasflotantes", false)
    assert(config.save())
    exercise("Preferencia desactivada abre independiente con dependencias preparadas", "cancelar")
    config.set("ventanasflotantes", true)
    assert(config.save())
    exercise("Aceptar: cinco elementos, selección y heartbeat Qt", "aceptar")
    local previous_native = package.loaded.wx
    exercise("Cancelar: reapertura con el mismo módulo nativo", "cancelar")
    equal(package.loaded.wx, previous_native)
    config.set("ventanasflotantes", false)
    assert(config.save())
    exercise("Preferencia desactivada: ventana wx independiente", "cancelar")
    config.set("ventanasflotantes", true)
    assert(config.save())
    exercise("Preferencia reactivada: ventana wx asociada", "cancelar")
    package.loaded.prueba_wxlua = nil
    demo = require("prueba_wxlua")
    exercise("Cerrar: recarga Lua sin reinicializar la DLL", "cerrar")
    equal(package.loaded.wx, previous_native)
  end
end

local ok, message = xpcall(run, debug.traceback)
finish(ok, message)
if not ok then error(message, 0) end
