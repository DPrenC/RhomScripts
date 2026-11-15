-- Ejecutado por scripts/validation.py con Lua 5.1 y LuaJIT y un puente PCRE2.
-- Para validar el proyecto: scripts/validate.ps1.
assert(validateRegex and matchRegex, "Ejecutar scripts/validate.ps1: falta el puente PCRE2")
local mock = dofile("scripts/tests/mudlet_mock.lua")
dofile("rhomscripts/init.lua")
assert(RhomScripts.initialized, "Inicialización incompleta")

local function check_keys()
  local signatures = {}
  for _, key in pairs(mock.keys) do
    local signature = key.modifiers .. ":" .. key.key
    assert(not signatures[signature], "Atajo duplicado: " .. signature)
    signatures[signature] = true
  end
end

check_keys()
local cases = dofile("scripts/tests/behavior.lua").run(mock)
check_keys()
return {
  cases = cases,
  counts = {
    keys = mock.count(mock.keys),
    aliases = mock.count(mock.aliases),
    triggers = mock.count(mock.triggers),
    handlers = mock.count(mock.handlers),
  }
}
