-------------------------------------------------------------------------------
-- Modulo: historial
-- Migracion funcional desde start.set: lectura y copia de ultimas lineas.
-------------------------------------------------------------------------------

local historial = {}

historial.max_cache = 200
historial.cache = {}

local function trim(text)
  if type(text) ~= "string" then
    return ""
  end
  return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function from_buffer(index)
  local last = getLastLineNumber("main")
  local target = last - index + 1
  if target < 0 then
    return ""
  end

  local lines = getLines("main", target, target)
  if type(lines) == "table" then
    return trim(lines[1] or lines[target] or "")
  end

  return ""
end

function historial.registrar(linea)
  local text = trim(linea)
  if text == "" then
    return
  end

  table.insert(historial.cache, 1, text)
  while #historial.cache > historial.max_cache do
    table.remove(historial.cache)
  end
end

function historial.ultima_linea(index)
  local offset = tonumber(index) or 1
  if offset < 1 then
    offset = 1
  end

  local from_mudlet = from_buffer(offset)
  if from_mudlet ~= "" then
    return from_mudlet
  end

  return historial.cache[offset] or "No hay linea disponible"
end

function historial.ultimas(cantidad)
  local total = tonumber(cantidad) or 9
  local result = {}
  for index = 1, total do
    table.insert(result, historial.ultima_linea(index))
  end
  return result
end

-- Trigger amplio para mantener una cache propia. Las teclas usan primero el
-- buffer nativo de Mudlet; la cache queda como respaldo y como fuente futura para
-- modulos que necesiten reaccionar a lineas ya normalizadas.
historial.triggers = {
  {
    pattern = "^(.*)$",
    action = function()
      historial.registrar(matches[2] or line or "")
    end,
    name = "historial_lineas",
    desc = "Guarda las lineas recientes del MUD"
  }
}

return historial
