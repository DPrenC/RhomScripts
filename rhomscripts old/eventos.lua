-------------------------------------------------------------------------------
-- Modulo: eventos
-- Migracion funcional desde Eventos.set.
-------------------------------------------------------------------------------

local lector = require("lector")
local listas = require("listas")

local eventos = {}

eventos.historial = {}
eventos.ultimo = "No hay eventos registrados"

local function trim(text)
  if type(text) ~= "string" then
    return ""
  end
  return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function copiar(text)
  return function()
    lector.copiar(text, "Evento copiado")
  end
end

function eventos.registrar(texto)
  local evento = trim(texto)
  if evento == "" then
    return
  end

  eventos.ultimo = evento
  table.insert(eventos.historial, 1, evento)
  while #eventos.historial > 99 do
    table.remove(eventos.historial)
  end
end

function eventos.mostrar_historial()
  if #eventos.historial == 0 then
    lector.decir("Historial de eventos vacio")
    return
  end

  listas.nueva("Historial de eventos")
  for index = #eventos.historial, 1, -1 do
    listas.agregar("Historial de eventos", eventos.historial[index], copiar(eventos.historial[index]))
  end
  listas.leer_actual()
end

eventos.aliases = {
  {
    pattern = "^evento\\s+(.+)$",
    action = function()
      eventos.registrar(matches[2])
    end,
    name = "evento",
    desc = "Registra manualmente un evento"
  }
}

eventos.key_bindings = {
  {
    modifiers = mudlet.keymodifier.Shift,
    key = mudlet.key.F4,
    action = function()
      eventos.mostrar_historial()
    end,
    name = "Shift+F4",
    desc = "Muestra historial de eventos"
  },
  {
    key = mudlet.key.F4,
    action = function()
      lector.decir(eventos.ultimo)
    end,
    name = "F4",
    desc = "Lee el ultimo evento"
  },
}

return eventos
