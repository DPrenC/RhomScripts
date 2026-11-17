-------------------------------------------------------------------------------
-- Modulo: lector
-- Capa accesible comun para hablar, copiar texto y exponer atajos de lectura.
-------------------------------------------------------------------------------

local audio = require("audio")

local lector = {}
lector.prioridades = { ALTA = "alta" }

-- Contrato de prioridades preparado; todavía conserva announce estándar.
function lector.verbalizar(mensaje, prioridad)
  assert(type(mensaje) == "string" and mensaje ~= "", "El mensaje debe ser texto no vacío")
  assert(prioridad == lector.prioridades.ALTA, "Prioridad de verbalización desconocida")
  announce(mensaje)
end

local function speak(text)
  if type(text) ~= "string" or text == "" then
    text = "Sin informacion"
  end
  announce(text)
end

function lector.decir(text)
  speak(text)
end

function lector.copiar(texto)
  assert(type(texto) == "string", "El texto para copiar debe ser una cadena")
  setClipboardText(texto)
  announce(texto)
  announce("Copiado")
  audio.reproducir("ui.portapapeles")
  return texto
end

-- Índices relativos entre líneas con contenido, sin caché.
-- getLines usa índices desde cero y extremo final exclusivo.
function lector.buscar_linea(numero)
  local indice = numero == nil and 1 or tonumber(numero)
  if not indice or indice < 1 or indice % 1 ~= 0 or indice == math.huge then
    return nil, "El índice debe ser un entero positivo"
  end
  local ultima = getLastLineNumber("main")
  local encontradas = 0
  -- Leer por bloques evita una llamada a Mudlet por cada blanco y no copia
  -- todo el búfer cuando solo se necesitan sus últimas líneas con contenido.
  while ultima >= 0 do
    local primera = math.max(0, ultima - 63)
    local lineas = getLines("main", primera, ultima + 1)
    assert(type(lineas) == "table", "Mudlet no devolvió las líneas solicitadas")
    for posicion = ultima - primera + 1, 1, -1 do
      local texto = lineas[posicion]
      assert(type(texto) == "string", "Mudlet no devolvió la línea solicitada")
      if texto:find("%S") then
        encontradas = encontradas + 1
        if encontradas == indice then return texto end
      end
    end
    ultima = primera - 1
  end
  return nil, "No hay línea disponible"
end

function lector.leer_linea(numero)
  local text, mensaje = lector.buscar_linea(numero)
  speak(text or mensaje)
  return text, mensaje
end

function lector.copiar_linea(numero)
  local text, mensaje = lector.buscar_linea(numero)
  if text == nil then
    speak(mensaje)
    return nil, mensaje
  end
  return lector.copiar(text)
end

-- Compatibilidad temporal con llamadas ya existentes en modulos antiguos Lua.
function lector.buscarLinea(numero)
  return lector.buscar_linea(numero)
end

function lector.leerLinea(numero)
  lector.leer_linea(numero)
  return true
end

function lector.copiarLinea(numero)
  lector.copiar_linea(numero)
  return true
end

local function add_line_key(pulsaciones, index)
  pulsaciones[#pulsaciones + 1] = {
    combinacion = { tecla = mudlet.key[tostring(index)], modificadores = { mudlet.keymodifier.Control } },
    nombre = "lector.leer_linea_" .. index,
    funcion = function() return lector.leer_linea(index) end,
    descripcion = "Lee la línea reciente número " .. index, grupo = "lectura"
  }
  pulsaciones[#pulsaciones + 1] = {
    combinacion = { tecla = mudlet.key[tostring(index)],
      modificadores = { mudlet.keymodifier.Control, mudlet.keymodifier.Shift } },
    nombre = "lector.copiar_linea_" .. index,
    funcion = function() return lector.copiar_linea(index) end,
    descripcion = "Copia la línea reciente número " .. index, grupo = "lectura"
  }
end

lector.pulsaciones = {}
for index = 1, 9 do add_line_key(lector.pulsaciones, index) end

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
