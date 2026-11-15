-- Doble explícito de APIs documentadas. No define APIs desconocidas.
local mock = {
  keys = {}, aliases = {}, triggers = {}, handlers = {}, events = {},
  sends = {}, sounds = {}, announcements = {}, output = {}, clipboard = "",
  buffer = { "primera linea", "segunda linea", "tercera linea" },
  persisted = {}, next_id = 0, timers = {}, now = 0, downloads = {}, installs = {},
  packages = { "RLMud_Config" }, install_ready = true,
  official_calls = { gui = 0, saved = 0, msp = 0, msp_stop = 0, discord = 0, fonts = {} },
  official_keys = { RLMud_Config = true, Config = true, Numpad = true, Macros = false },
  modules = {}, connected = false, font_size = 12,
}

dofile("doc/mudlet/KeyCodes.lua")
setmetatable(mudlet.key, {
  __index = function(_, name) error("Tecla no documentada: " .. tostring(name)) end,
})

local function register(collection, entry)
  mock.next_id = mock.next_id + 1
  collection[mock.next_id] = entry
  return mock.next_id
end

local function remove(collection, id)
  assert(collection[id], "Identificador de registro inexistente: " .. tostring(id))
  collection[id] = nil
  return true
end

function tempKey(modifier, key, action)
  if action == nil then action, key, modifier = key, modifier, 0 end
  assert(type(key) == "number" and type(modifier) == "number" and type(action) == "function")
  return register(mock.keys, { modifiers = modifier, key = key, action = action })
end

function tempAlias(pattern, action)
  assert(type(pattern) == "string" and type(action) == "function")
  validateRegex(pattern)
  return register(mock.aliases, { pattern = pattern, action = action })
end

function tempRegexTrigger(pattern, action)
  assert(type(pattern) == "string" and type(action) == "function")
  validateRegex(pattern)
  return register(mock.triggers, { pattern = pattern, action = action })
end

function killKey(id) return remove(mock.keys, id) end
function killAlias(id) return remove(mock.aliases, id) end
function killTrigger(id) return remove(mock.triggers, id) end

function registerAnonymousEventHandler(event, action)
  assert(type(event) == "string" and type(action) == "function")
  return register(mock.handlers, { event = event, action = action })
end

function killAnonymousEventHandler(id) return remove(mock.handlers, id) end

function raiseEvent(event, ...)
  mock.events[#mock.events + 1] = { event, ... }
  for _, id in ipairs(mock.ids(mock.handlers)) do
    local handler = mock.handlers[id]
    if handler and handler.event == event then handler.action(event, ...) end
  end
end

-- Contratos explícitos de Mudlet; los tiempos avanzan solo mediante mock.advance.
function tempTimer(delay, action)
  assert(type(delay) == "number" and delay >= 0 and type(action) == "function")
  return register(mock.timers, { deadline = mock.now + delay, action = action })
end

function killTimer(id) return remove(mock.timers, id) end

function mock.advance(seconds)
  local until_time = mock.now + seconds
  local executions = 0
  while true do
    local selected, deadline
    for id, timer in pairs(mock.timers) do
      if timer.deadline <= until_time and (not deadline or timer.deadline < deadline
          or (timer.deadline == deadline and id < selected)) then
        selected, deadline = id, timer.deadline
      end
    end
    if not selected then break end
    executions = executions + 1
    assert(executions < 10000, "Bucle de temporizadores en el doble")
    mock.now = deadline
    local action = mock.timers[selected].action
    mock.timers[selected] = nil -- Un temporizador de un solo uso ya no existe al ejecutarse.
    action()
  end
  mock.now = until_time
end

function getPackages()
  local packages = {}
  for index, name in ipairs(mock.packages) do packages[index] = name end
  return packages
end

function downloadFile(path, url)
  assert(type(path) == "string" and type(url) == "string")
  mock.downloads[#mock.downloads + 1] = { path = path, url = url }
  return url
end

function mock.official_ready()
  RL_vars = {
    name = "RLMud_Config", path = TEST_PROFILE_PATH .. "/RLMud_Config/", opciones = {},
    msp = { data = {} }, macros = { current = {}, clases = {} },
    GUI = { contenedores = {
      contenedor_superior = { hidden = true }, contenedor_derecho = { hidden = false },
      widget_comm = { hidden = false }, widget_comm_consola_global = { hidden = false },
    }, widget_comm = { current = "global" } },
  }
end

-- APIs oficiales leídas del XML instalado. Este doble solo modela efectos
-- necesarios para aplicar preferencias; no declara que pruebe controles nativos o GMCP real.
function RL_salvar_opciones(silent)
  assert(silent == nil or type(silent) == "boolean")
  mock.official_calls.saved = mock.official_calls.saved + 1
  return true
end
local function official_gui(reinitializing)
  mock.official_calls.gui = mock.official_calls.gui + 1
  local disabled = RL_vars.opciones.no_mostrar_interfaz
  for _, container in pairs(RL_vars.GUI.contenedores) do container.hidden = not not disabled end
  RL_vars.GUI.contenedores.widget_comm.hidden = not not (disabled or RL_vars.opciones.no_mostrar_canales)
  if disabled then raiseEvent("rlmud_gui_noinicializada")
  else raiseEvent(reinitializing and "rlmud_gui_reinicializada" or "rlmud_gui_inicializada") end
end
function RL_gui_reinicializar() official_gui(true) end
function RL_gui_fijar_tamanyo_fuente_consola(tab, size)
  assert(type(tab) == "string" and type(size) == "number")
  mock.official_calls.fonts[tab] = size
  return true
end
function getFontSize(window)
  if window then
    local tab = window:match("^widget_comm_consola_(.+)$")
    if tab and mock.official_calls.fonts[tab] then return mock.official_calls.fonts[tab] end
  end
  return mock.font_size
end
function getConnectionInfo() return "", 0, mock.connected end
function isActive(name, kind, ancestors)
  assert(kind == "keybind" and mock.official_keys[name] ~= nil, "Grupo oficial no declarado")
  local active = mock.official_keys[name]
  if ancestors and name ~= "RLMud_Config" then active = active and mock.official_keys.RLMud_Config end
  return active and 1 or 0
end
function enableKey(name)
  assert(mock.official_keys[name] ~= nil, "Grupo oficial no declarado")
  mock.official_keys[name] = true
end
function disableKey(name)
  assert(mock.official_keys[name] ~= nil, "Grupo oficial no declarado")
  mock.official_keys[name] = false
end
function RL_macros_activar()
  if not (gmcp and gmcp.Char and gmcp.Char.Ficha and gmcp.Char.Ficha.clase) then return false end
  RL_vars.macros.current_clase = tostring(gmcp.Char.Ficha.clase)
  enableKey("Macros")
  return true
end
function RL_inicializar_MSP()
  mock.official_calls.msp = mock.official_calls.msp + 1
  if RL_vars.opciones.msp_desactivar then return false end
  RL_vars.msp = RL_vars.msp or { data = {} }
end
function RL_msp_stop_all()
  mock.official_calls.msp_stop = mock.official_calls.msp_stop + 1
  RL_vars.msp.data = {}
  mock.sounds = {}
end
function RL_discord_inicializar()
  mock.official_calls.discord = mock.official_calls.discord + 1
  RL_vars.discord = {}
end
-- GMCP.lua de Mudlet5.1.1: registro local de usuarios, incluso sin conexión.
gmod = {}
function gmod.enableModule(user, name)
  assert(type(user) == "string" and type(name) == "string")
  mock.modules[name] = mock.modules[name] or {}
  mock.modules[name][user] = true
end
function gmod.disableModule(user, name)
  assert(type(user) == "string" and type(name) == "string")
  if not mock.modules[name] then return "no registered module" end
  mock.modules[name][user] = nil
  if not next(mock.modules[name]) then mock.modules[name] = nil end
end
function gmod.isRegisteredModule(name) return mock.modules[name] or false end

function installPackage(path)
  assert(type(path) == "string")
  mock.installs[#mock.installs + 1] = path
  if mock.install_error then return nil, mock.install_error end
  mock.packages = { "RLMud_Config" }
  if mock.install_ready then
    mock.official_ready()
    raiseEvent("rlmud_opciones_inicializadas")
  end
  raiseEvent("sysInstallPackage", "RLMud_Config", path)
  return true
end

function send(command)
  assert(type(command) == "string")
  mock.sends[#mock.sends + 1] = command
end

-- Manual Lua_Functions: ansi2string(text) retira secuencias ANSI SGR.
-- Este doble cubre SGR; la conversión completa se contrasta en Mudlet real.
-- luacheck: globals ansi2string
function ansi2string(text)
  assert(type(text) == "string")
  return (text:gsub("\27%[[0-9;]*m", ""))
end

function announce(text)
  assert(type(text) == "string")
  mock.announcements[#mock.announcements + 1] = text
end

function echo(text) mock.output[#mock.output + 1] = text end
function cecho(text) mock.output[#mock.output + 1] = text end

function playSoundFile(settings)
  assert(type(settings) == "table" and type(settings.name) == "string")
  -- Son campos opcionales en la firma oficial; conservar su ausencia permite
  -- comprobar que la interfaz por clave no aplica todavía opciones futuras.
  assert(settings.volume == nil or (settings.volume >= 0 and settings.volume <= 100))
  assert(settings.pan == nil or (settings.pan >= -100 and settings.pan <= 100))
  assert(settings.loops == nil or settings.loops == -1 or settings.loops >= 1)
  mock.sounds[settings.key] = settings
  return true
end

function stopSounds(settings)
  assert(type(settings) == "table")
  for key, sound in pairs(mock.sounds) do
    if (not settings.key or settings.key == key) and (not settings.tag or settings.tag == sound.tag) then
      mock.sounds[key] = nil
    end
  end
end

function getMudletHomeDir() return TEST_PROFILE_PATH end
function getProfileName() return "RhomScripts-pruebas" end
function getLastLineNumber() return #mock.buffer - 1 end

function getLines(window, first, last)
  assert(window == "main" and first >= 0 and last >= first)
  local result = {}
  for index = first, last - 1 do result[#result + 1] = mock.buffer[index + 1] or "" end
  return result
end

function setClipboardText(text) mock.clipboard = text end
function getClipboardText() return mock.clipboard end

function table.save(path, data)
  assert(type(path) == "string" and type(data) == "table")
  local copy = {}
  for key, value in pairs(data) do copy[key] = value end
  mock.persisted[path] = copy
  local file = assert(io.open(path, "w"))
  file:write("-- Marcador del doble de persistencia; no es una serialización Mudlet.\n")
  file:close()
end

function table.load(path, target)
  assert(type(path) == "string" and type(target) == "table")
  assert(mock.persisted[path], "Persistencia simulada inexistente")
  for key, value in pairs(mock.persisted[path]) do target[key] = value end
end

local function dispatch(collection, text)
  for _, id in ipairs(mock.ids(collection)) do
    local item = collection[id]
    local captures = matchRegex(item.pattern, text)
    if captures then
      local previous_matches = matches
      matches = captures
      item.action()
      matches = previous_matches
    end
  end
end

function feedTriggers(text)
  assert(type(text) == "string")
  for value in text:gmatch("([^\n]+)") do
    line = value
    mock.buffer[#mock.buffer + 1] = value
    dispatch(mock.triggers, value)
  end
end

function mock.alias(text) dispatch(mock.aliases, text) end

function mock.ids(collection)
  local ids = {}
  for id in pairs(collection) do ids[#ids + 1] = id end
  table.sort(ids)
  return ids
end

function mock.count(collection) return #mock.ids(collection) end

function mock.key(modifiers, key)
  for _, binding in pairs(mock.keys) do
    if binding.modifiers == modifiers and binding.key == key then
      binding.action()
      return
    end
  end
  error("Atajo no registrado")
end

-- Aislar las DLL en las suites locales: no se simulan controles wx ni Win32.
-- La carga y compatibilidad reales se verifican en los perfiles Mudlet nativos.
package.preload.arranque = function()
  local comprobaciones = dofile("rhomscripts/arranque.lua")
  comprobaciones.bibliotecas = function() end
  return comprobaciones
end

-- El doble local aísla la construcción, sin inventar widgets nativos.
package.preload.ui = function()
  local ui = dofile("rhomscripts/ui.lua")
  ui.preparar = function() mock.ui_preparations = (mock.ui_preparations or 0) + 1 end
  return ui
end

mock.official_ready()
matches = {}
line = ""
return mock
