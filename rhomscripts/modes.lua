local config = require("config")
local audio = require("audio")

local modes = {}

-- ============================================================================
-- CONFIGURACIÓN DE ATAJOS DE TECLADO
-- ============================================================================
-- Los atajos se definen aquí pero son registrados por keys.lua
-- Formato estandarizado para que keys.lua los descubra automáticamente

modes.key_bindings = {
  {
    type = "simple",
    key = mudlet.key.F8,
    action = function() modes.toggle("mono") end,
    name = "F8",
    desc = "Alternar modo mono (audio monoaural/simplificado)"
  },
  {
    type = "simple",
    key = mudlet.key.F9,
    action = function() modes.toggle("ambientacion") end,
    name = "F9",
    desc = "Alternar sonidos ambientales (ambientación)"
  },
  {
    type = "simple",
    key = mudlet.key.F10,
    action = function() modes.toggle("experto") end,
    name = "F10",
    desc = "Alternar modo experto (información adicional/avanzada)"
  },
  {
    type = "simple",
    key = mudlet.key.F11,
    action = function() modes.cycle_modo_juego(1) end,
    name = "F11",
    desc = "Ciclar entre diferentes modos de juego (avanzar al siguiente)"
  },
  {
    type = "simple",
    modifiers = mudlet.keymodifier.Shift,
    key = mudlet.key.F11,
    action = function() modes.cycle_modo_juego(-1) end,
    name = "Shift+F11",
    desc = "Ciclar entre diferentes modos de juego (retroceder)"
  },
  {
    type = "simple",
    key = mudlet.key.F12,
    action = function() modes.toggle("silent") end,
    name = "F12",
    desc = "Alternar modo silencioso (sin sonidos)"
  },
}

-- ============================================================================
-- CONFIGURACIÓN DE ALIASES
-- ============================================================================
-- Los aliases se definen aquí pero son registrados por aliases.lua
-- Formato estandarizado para que aliases.lua los descubra automáticamente

modes.aliases = {
  {
    pattern = "^modos$",
    action = function() modes.toggle("silent") end,
    name = "modos",
    desc = "Alternar modo silencioso"
  },
  {
    pattern = "^modoe$",
    action = function() modes.toggle("experto") end,
    name = "modoe",
    desc = "Alternar modo experto"
  },
  {
    pattern = "^ModoE$",
    action = function() modes.toggle("experto") end,
    name = "ModoE",
    desc = "Alternar modo experto"
  },
  {
    pattern = "^modoa$",
    action = function() modes.toggle("ambientacion") end,
    name = "modoa",
    desc = "Alternar ambientación"
  },
  {
    pattern = "^modom$",
    action = function() modes.toggle("mono") end,
    name = "modom",
    desc = "Alternar modo mono"
  }
}

modes.state = {}
modes.volume_normal = 100
modes.volume_idle = 30

local valid_modo_juego = {
  combate = true,
  xp = true,
  idle = true,
}

local function output_text(text)
  if type(text) ~= "string" or text == "" then
    return
  end
  if type(cecho) == "function" then
    cecho(text .. "\n")
  elseif type(echo) == "function" then
    echo(text .. "\n")
  end
end

local function announce_mode(name, state)
  if type(announce) == "function" then
    local status = state and "activado" or "desactivado"
    announce(string.format("Modo %s %s", name, status))
  end
end

local function apply_silent(on)
  announce_mode("silencioso", on)
  raiseEvent("rl.silent.changed", on)
end

local function apply_experto(on)
  announce_mode("experto", on)
  raiseEvent("rl.experto.changed", on)
end

local function apply_ambientacion(on)
  announce_mode("ambientación", on)
  if on then
    raiseEvent("rl.ambientacion.enabled")
  else
    raiseEvent("rl.ambientacion.disabled")
  end
end

local function apply_mono(on)
  announce_mode("mono", on)
  audio.set_mono(on)
  raiseEvent("rl.mono.changed", on)
end

local function apply_modo_juego(value)
  if type(announce) == "function" then
    announce(string.format("Modo de juego: %s", value))
  end
  if value == "idle" then
    audio.set_master(modes.volume_idle)
    raiseEvent("rl.alerts.enabled", false)
  else
    audio.set_master(modes.volume_normal)
    raiseEvent("rl.alerts.enabled", true)
  end
  raiseEvent("rl.modo_juego.changed", value)
end

function modes.init(state)
  modes.state = {}
  for key, value in pairs(config.defaults) do
    modes.state[key] = value
  end
  if type(state) == "table" then
    for key, value in pairs(state) do
      modes.state[key] = value
    end
  end

  apply_silent(modes.state.silent)
  apply_experto(modes.state.experto)
  apply_ambientacion(modes.state.ambientacion)
  apply_mono(modes.state.mono)
  apply_modo_juego(modes.state.modo_juego)
end

function modes.get()
  return modes.state
end

function modes.get_flag(name)
  return modes.state[name]
end

function modes.set_flag(name, value)
  if modes.state[name] == value then
    return
  end
  modes.state[name] = value
  config.set(name, value)

  if name == "silent" then
    apply_silent(value)
  elseif name == "experto" then
    apply_experto(value)
  elseif name == "ambientacion" then
    apply_ambientacion(value)
  elseif name == "mono" then
    apply_mono(value)
  end

  audio.play(value and "RL/Modos/On.wav" or "RL/Modos/Off.wav", { volume = 80, key = "rhom:modo:" .. name })
end

function modes.toggle(name)
  local current = not not modes.state[name]
  modes.set_flag(name, not current)
end

function modes.set_modo_juego(value)
  if not valid_modo_juego[value] then
    return
  end
  if modes.state.modo_juego == value then
    return
  end
  modes.state.modo_juego = value
  config.set("modo_juego", value)
  audio.play("RL/Modos/Boton.wav", { volume = 80, key = "rhom:modo:juego" })
  apply_modo_juego(value)
end

function modes.cycle_modo_juego(step)
  local order = {"combate", "xp", "idle"}
  local index = 1
  for i, value in ipairs(order) do
    if value == modes.state.modo_juego then
      index = i
      break
    end
  end
  local next_index = index + (step or 1)
  if next_index > #order then
    next_index = 1
  elseif next_index < 1 then
    next_index = #order
  end
  modes.set_modo_juego(order[next_index])
end

function modes.should_say()
  return not modes.state.silent
end

function modes.say(text)
  if not modes.should_say() then
    return
  end
  output_text(text)
  raiseEvent("rl.say", text)
end

return modes
