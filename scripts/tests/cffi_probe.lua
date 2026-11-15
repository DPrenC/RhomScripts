-- Sondeo real de cffi-lua/Win32. Solo se modifican ventanas del proceso aislado.
local root, result_path = RHOM_WX_ROOT, RHOM_WX_RESULT
local results, timers = {}, {}
local ticks, finished = 0, false
local nativo, api, wx, demo
local config
local process_id

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
end

local function beat()
  if finished then return end
  ticks = ticks + 1
  after(0.1, beat)
end

local function equal(actual, expected)
  assert(actual == expected, "Esperado " .. tostring(expected) .. "; obtenido " .. tostring(actual))
end

local function case(name, action)
  journal("INICIO " .. name)
  action()
  results[#results + 1] = name
  journal("OK " .. name)
end

local function pid(window)
  local value = api.ffi.new("RHOM_DWORD[1]")
  assert(api.user32.GetWindowThreadProcessId(window, value) ~= 0, "HWND sin hilo propietario")
  return api.ffi.tonumber(value[0])
end

local function own(window)
  assert(api.user32.IsWindow(window) ~= 0, "HWND no válido")
  equal(pid(window), process_id)
end

local function click(button)
  local event = wx.wxCommandEvent(wx.wxEVT_COMMAND_BUTTON_CLICKED, button:GetId())
  event:SetEventObject(button)
  assert(button:ProcessWindowEvent(event), "Botón nativo sin manejador")
  event:delete()
end

local function dialogs(action)
  local windows = {}
  local function create(title)
    local window = wx.wxDialog(wx.NULL, wx.wxID_ANY, title)
    windows[#windows + 1] = window
    return window
  end
  local ok, message = xpcall(function() action(create) end, debug.traceback)
  local cleaned, cleanup_message = pcall(function()
    for index = #windows, 1, -1 do windows[index]:Destroy() end
    wx.wxGetApp():Yield(true)
  end)
  if not ok then
    if not cleaned then error(tostring(message) .. "\nError de limpieza: " .. tostring(cleanup_message), 0) end
    error(message, 0)
  end
  assert(cleaned, cleanup_message)
end

local function exercise(name, interactive, minimize)
  local delayed_error
  local before = ticks
  local owner_to_restore
  local function checked(action)
    local ok, message = xpcall(action, debug.traceback)
    if not ok then
      delayed_error = message
      journal("ERROR DIFERIDO " .. tostring(message))
      if owner_to_restore then api.user32.ShowWindow(owner_to_restore, 9) end
      demo.cerrar()
    end
  end
  after(0.8, function()
    checked(function()
      assert(demo.abierta and demo.ventana, "La demostración no está abierta")
      local window = nativo.handle(demo.ventana)
      own(window)
      own(demo.propietaria)
      equal(nativo.propietario(demo.ventana), config.get("ventanasflotantes") and demo.propietaria or api.ffi.nullptr)
      equal(demo.propietaria, nativo.mudlet())
      assert(ticks > before + 2, "No avanzan los temporizadores de Mudlet")
      journal("ASOCIADA " .. tostring(window) .. " A " .. tostring(demo.propietaria))
      if interactive then return end
      local readings, original_announce = {}, announce
      announce = function(text)
        readings[#readings + 1] = text
        return original_announce(text)
      end
      local toggled, toggle_error = xpcall(function()
        click(demo.desvincular_boton)
        equal(nativo.propietario(demo.ventana), api.ffi.nullptr)
        equal(demo.estado:GetLabel(), "Ventana independiente.")
        equal(nativo.mudlet(), demo.propietaria)
        click(demo.vincular_boton)
        equal(nativo.propietario(demo.ventana), demo.propietaria)
        equal(demo.estado:GetLabel(), "Asociada a Mudlet.")
        equal(#readings, 2)
        equal(readings[1], "Ventana independiente.")
        equal(readings[2], "Asociada a Mudlet.")
      end, debug.traceback)
      announce = original_announce
      assert(toggled, toggle_error)
      if not minimize then click(demo.cerrar_boton); return end
      owner_to_restore = demo.propietaria
      api.user32.ShowWindow(owner_to_restore, 6) -- SW_MINIMIZE: solo el proceso aislado.
      after(0.25, function()
        checked(function()
          assert(api.user32.IsIconic(owner_to_restore) ~= 0, "Mudlet no se minimizó")
          equal(api.user32.IsWindowVisible(window), 0)
          api.user32.ShowWindow(owner_to_restore, 9) -- SW_RESTORE, antes de cualquier salida.
          after(0.25, function()
            checked(function()
              equal(api.user32.IsIconic(owner_to_restore), 0)
              assert(api.user32.IsWindowVisible(window) ~= 0, "La ventana asociada no reapareció")
              equal(nativo.propietario(demo.ventana), owner_to_restore)
              owner_to_restore = nil
              click(demo.cerrar_boton)
            end)
          end)
        end)
      end)
    end)
  end)
  demo.abrir()
  assert(not delayed_error, delayed_error)
  assert(not demo.abierta and not demo.ventana, "Quedó la demostración abierta")
  results[#results + 1] = name
  journal("OK " .. name)
end

local function run()
  assert(getMudletHomeDir() == RHOM_WX_PROFILE, "El perfil no corresponde al proceso aislado")
  RhomScripts = { root = root .. "/rhomscripts" }
  package.path = RhomScripts.root .. "/?.lua;" .. root .. "/rhomscripts old/?.lua;" .. package.path
  config = require("configuracion")
  assert(config.load())
  nativo = require("ui").nativo
  api = require("arranque").cargar_nativo()
  process_id = api.ffi.tonumber(api.kernel32.GetCurrentProcessId())
  assert(process_id > 0)
  journal("PID " .. tostring(process_id))
  after(0.1, beat)
  case("cffi real: ABI x64, cdef, Kernel32 y PID del proceso aislado", function()
    equal(api.ffi.sizeof("void *"), 8)
    equal(api.ffi.sizeof("RHOM_DWORD"), 4)
    equal(api.ffi.sizeof("RHOM_LONG_PTR"), 8)
    -- API oficial Windows 2000+, declarada únicamente para una prueba negativa.
    api.ffi.cdef [[
      RHOM_HWND GetDesktopWindow(void);
      int ShowWindow(RHOM_HWND, int);
      int IsIconic(RHOM_HWND);
    ]]
    assert(api.user32.GetDesktopWindow() ~= api.ffi.nullptr)
    local loaded, error_message = pcall(api.ffi.load, RhomScripts.root .. "/lib/no-existe-cffi-probe.dll")
    assert(not loaded and tostring(error_message) ~= "", "Una DLL ausente no produjo error")
  end)
  wx = require("arranque").cargar_wx()
  case("EnumWindows identifica solo ventanas de este proceso y su raíz Mudlet", function()
    local windows = nativo.ventanas()
    assert(#windows > 0, "No se enumeraron ventanas del proceso")
    for _, window in ipairs(windows) do own(window) end
    own(nativo.mudlet())
  end)
  case("wxLua GetHandle, asociación y restauración de propietario real", function()
    dialogs(function(create)
      local parent = create("Propietaria de prueba cffi")
      local child = create("Ventana asociada de prueba cffi")
      local parent_handle = nativo.handle(parent)
      own(parent_handle)
      own(nativo.handle(child))
      local original_owner = nativo.propietario(child)
      equal(nativo.asociar(child, parent_handle), original_owner)
      equal(nativo.propietario(child), parent_handle)
      equal(nativo.asociar(child, api.ffi.nullptr), parent_handle)
      equal(nativo.propietario(child), api.ffi.nullptr)
      local restored, restore_error = pcall(nativo.asociar, child, original_owner)
      if not restored then
        journal("RESTAURAR origen=" .. tostring(original_owner)
          .. " actual=" .. tostring(nativo.propietario(child))
          .. " ventana=" .. tostring(nativo.handle(child)))
        error(restore_error, 0)
      end
      equal(nativo.propietario(child), original_owner)
    end)
  end)
  case("Asociación rechaza propietarios ajenos, autoasociación y ciclos", function()
    dialogs(function(create)
      local parent = create("Origen negativo cffi")
      local child = create("Destino negativo cffi")
      local parent_handle = nativo.handle(parent)
      local child_handle = nativo.handle(child)
      local original_owner = nativo.propietario(child)
      local external = api.user32.GetDesktopWindow()
      assert(pid(external) ~= process_id, "El escritorio pertenece al proceso de prueba")
      assert(not pcall(nativo.asociar, child, external), "Se admitió propietario de otro proceso")
      equal(nativo.propietario(child), original_owner)
      assert(not pcall(nativo.asociar, child, child_handle), "Se admitió propiedad sobre sí misma")
      nativo.asociar(child, parent_handle)
      assert(not pcall(nativo.asociar, parent, child_handle), "Se admitió un ciclo de propietarios")
      nativo.asociar(child, original_owner)
    end)
  end)
  case("Recarga Lua conserva cffi y sus bibliotecas nativas", function()
    local previous_module, previous_runtime = package.loaded.cffi, api
    package.loaded.ui = nil
    package.loaded.arranque = nil
    nativo = require("ui").nativo
    equal(require("arranque").cargar_nativo(), previous_runtime)
    equal(package.loaded.cffi, previous_module)
  end)
  demo = require("prueba_cffi")
  exercise("Demostración asociada: botones, minimización, restauración y heartbeat Qt", RHOM_WX_INTERACTIVE, true)
  if not RHOM_WX_INTERACTIVE then
    package.loaded.prueba_cffi = nil
    demo = require("prueba_cffi")
    exercise("Reapertura de demostración sin reinicializar cffi ni wx", false)
    config.set("ventanasflotantes", false)
    assert(config.save())
    exercise("Demostración respeta configuración independiente y permite vincular explícitamente", false)
    config.set("ventanasflotantes", true)
    assert(config.save())
  end
end

local ok, message = xpcall(run, debug.traceback)
finished = true
for id in pairs(timers) do killTimer(id) end
local file = assert(io.open(result_path .. ".tmp", "w"))
file:write(ok and "STATUS OK\n" or "STATUS ERROR\n")
file:write("VERSION ", getMudletVersion("string"), "\nLUA ", _VERSION, "\n")
if process_id then file:write("PID ", tostring(process_id), "\n") end
if wx then file:write("WX ", wx.wxVERSION_STRING, "\n") end
file:write("QT_HEARTBEAT ", tostring(ticks), "\n")
file:write("OMITIDA Portapapeles: no se lee ni modifica\n")
file:write("OMITIDA Teclado físico, lector externo y seguimiento de movimiento\n")
for _, name in ipairs(results) do file:write("CASE ", name, "\n") end
if not ok then file:write("ERROR ", tostring(message), "\n") end
file:close()
assert(os.rename(result_path .. ".tmp", result_path))
if not ok then error(message, 0) end
