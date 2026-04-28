-------------------------------------------------------------------------------
-- Modulo: lector
-- Capa accesible comun para hablar, copiar texto y exponer atajos de lectura.
-------------------------------------------------------------------------------

local audio = require("audio")
local historial = require("historial")

local lector = {}

local function speak(text)
  if type(text) ~= "string" or text == "" then
    text = "Sin informacion"
  end
  announce(text)
end

function lector.decir(text)
  speak(text)
end

function lector.copiar(text, aviso)
  local value = text or ""
  setClipboardText(value)
  audio.portapapeles()
  speak(aviso or "Copiado")
  return value
end

function lector.leer_linea(numero)
  local text = historial.ultima_linea(numero)
  speak(text)
  return text
end

function lector.copiar_linea(numero)
  local text = historial.ultima_linea(numero)
  lector.copiar(text, "Linea copiada")
  return text
end

-- Compatibilidad temporal con llamadas ya existentes en modulos antiguos Lua.
function lector.buscarLinea(numero)
  return historial.ultima_linea(numero)
end

function lector.leerLinea(numero)
  lector.leer_linea(numero)
  return true
end

function lector.copiarLinea(numero)
  lector.copiar_linea(numero)
  return true
end

local function add_line_key(bindings, index)
  table.insert(bindings, {
    modifiers = mudlet.keymodifier.Control,
    key = mudlet.key[tostring(index)],
    action = function()
      lector.leer_linea(index)
    end,
    name = "Ctrl+" .. index,
    desc = "Lee la linea reciente numero " .. index
  })

  table.insert(bindings, {
    modifiers = mudlet.keymodifier.Control + mudlet.keymodifier.Shift,
    key = mudlet.key[tostring(index)],
    action = function()
      lector.copiar_linea(index)
    end,
    name = "Ctrl+Shift+" .. index,
    desc = "Copia la linea reciente numero " .. index
  })
end

lector.key_bindings = {}
for index = 1, 9 do
  add_line_key(lector.key_bindings, index)
end

lector.aliases = {
  {
    pattern = "^leerlinea\\s+([0-9]+)$",
    action = function()
      lector.leer_linea(tonumber(matches[2]))
    end,
    name = "leerlinea",
    desc = "Lee una linea reciente por indice"
  },
  {
    pattern = "^copiarlinea\\s+([0-9]+)$",
    action = function()
      lector.copiar_linea(tonumber(matches[2]))
    end,
    name = "copiarlinea",
    desc = "Copia una linea reciente por indice"
  }
}

return lector
