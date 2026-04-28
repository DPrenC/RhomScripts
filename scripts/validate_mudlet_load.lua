-- Loads the Mudlet entry point with local stubs so migration work can be
-- validated without opening the client.

RhomScripts = nil
matches = {}
line = ""

local real_print = print
local output_log = {}

local function record_output(...)
  local parts = {}
  for index = 1, select("#", ...) do
    parts[index] = tostring(select(index, ...))
  end
  table.insert(output_log, table.concat(parts, "\t"))
end

local function dump_recent_output()
  local first = math.max(1, #output_log - 40)
  for index = first, #output_log do
    io.stderr:write(output_log[index] .. "\n")
  end
end

function print(...)
  record_output(...)
end

local registrations = {
  keys = {},
  aliases = {},
  triggers = {},
  handlers = {},
  events = {},
  sends = {},
  sounds = {},
  clipboard = "",
}

local key_names = {
  "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12",
  "Up", "Down", "Left", "Right", "PageUp", "PageDown", "Home", "End", "Insert",
  "Delete", "Return", "Enter", "Space", "Tab", "Backspace", "Escape", "Comma",
  "Period", "Slash", "Backslash", "Minus", "Equal", "N", "O", "P", "A", "L", "I",
  "U", "J", "B", "H", "Y", "M", "T", "C", "V", "W", "Q", "E", "R", "S", "D", "Z",
  "X", "Num0", "Num1", "Num2", "Num3", "Num4", "Num5", "Num6", "Num7", "Num8", "Num9",
}

mudlet = {
  key = {},
  keymodifier = {
    Control = 0x01,
    Shift = 0x02,
    Alt = 0x04,
    Meta = 0x08,
  },
}

for index, name in ipairs(key_names) do
  mudlet.key[name] = index
end

local next_dynamic_key = 1000
setmetatable(mudlet.key, {
  __index = function(tbl, key)
    next_dynamic_key = next_dynamic_key + 1
    local value = next_dynamic_key
    rawset(tbl, key, value)
    return value
  end,
})

function tempKey(...)
  table.insert(registrations.keys, {...})
  return #registrations.keys
end

function tempAlias(pattern, action)
  table.insert(registrations.aliases, { pattern = pattern, action = action })
  return #registrations.aliases
end

function tempRegexTrigger(pattern, action)
  table.insert(registrations.triggers, { pattern = pattern, action = action })
  return #registrations.triggers
end

function registerAnonymousEventHandler(event, action)
  table.insert(registrations.handlers, { event = event, action = action })
  return #registrations.handlers
end

function raiseEvent(event, ...)
  table.insert(registrations.events, { event = event, args = {...} })
end

function send(command)
  table.insert(registrations.sends, command)
end

function announce(text)
  registrations.last_announcement = text
end

function echo(text)
  registrations.last_echo = text
end

function cecho(text)
  registrations.last_cecho = text
end

function playSoundFile(path, options)
  table.insert(registrations.sounds, { path = path, options = options })
  return #registrations.sounds
end

function stopSounds()
  registrations.sounds = {}
end

function setSoundPan(handle, pan)
  registrations.last_pan = { handle = handle, pan = pan }
end

function getLastLineNumber()
  return 3
end

function getLines(_, first, last)
  local sample = {
    [1] = "primera linea",
    [2] = "segunda linea",
    [3] = "tercera linea",
  }
  local output = {}
  for index = first, last do
    table.insert(output, sample[index] or "")
  end
  return table.concat(output, "\n")
end

function setClipboardText(text)
  registrations.clipboard = text
end

function getClipboardText()
  return registrations.clipboard
end

function loadTable()
  return nil
end

function saveTable()
  return true
end

package.path = "rhomscripts/?.lua;" .. package.path

local ok, err = pcall(dofile, "rhomscripts/init.lua")
if not ok then
  dump_recent_output()
  io.stderr:write(tostring(err) .. "\n")
  os.exit(1)
end

if not RhomScripts or not RhomScripts.initialized then
  dump_recent_output()
  io.stderr:write("RhomScripts did not finish initialization cleanly\n")
  os.exit(1)
end

local seen_keys = {}
for _, args in ipairs(registrations.keys) do
  local modifier = 0
  local key = args[1]
  if #args == 3 then
    modifier = args[1]
    key = args[2]
  end
  local signature = tostring(modifier) .. ":" .. tostring(key)
  if seen_keys[signature] then
    io.stderr:write("Duplicate key binding detected: " .. signature .. "\n")
    os.exit(1)
  end
  seen_keys[signature] = true
end

local summary = string.format(
  "mudlet load OK: %d keys, %d aliases, %d triggers, %d handlers",
  #registrations.keys,
  #registrations.aliases,
  #registrations.triggers,
  #registrations.handlers
)

real_print(summary)
