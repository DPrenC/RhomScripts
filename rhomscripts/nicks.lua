-------------------------------------------------------------------------------
-- Modulo: nicks
-- Migracion funcional desde Nicks.set.
-------------------------------------------------------------------------------

local audio = require("audio")
local corrector = require("corrector")
local lector = require("lector")
local listas = require("listas")

local nicks = {}

nicks.nickx = {}
nicks.objetivo = nil

local function trim(text)
  if type(text) ~= "string" then
    return ""
  end
  return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function sync_general()
  local general = RhomScripts and RhomScripts.modules and RhomScripts.modules.general
  if general then
    general.nickx = nicks.nickx
    general.objetivo = nicks.objetivo
  end
end

function nicks.fijar_nickx(texto)
  local limpio = tostring(texto or ""):gsub(",", "|"):gsub("%.", "")
  nicks.nickx = {}
  for item in limpio:gmatch("[^|]+") do
    local nombre = corrector.players(trim(item))
    if nombre ~= "" then
      table.insert(nicks.nickx, nombre)
    end
  end

  nicks.objetivo = nicks.nickx[1]
  sync_general()
  audio.play("RL/Combate/Nick fijado.wav", { volume = 80, key = "rhom:nickx" })
end

function nicks.borrar_nickx()
  nicks.nickx = {}
  nicks.objetivo = nil
  sync_general()
  lector.decir("Nick x borrado")
end

function nicks.fijar_objetivo(nombre)
  local objetivo = trim(nombre)
  if objetivo == "" then
    lector.decir("Para fijar un objetivo enemigo: obj nombre")
    return
  end

  nicks.objetivo = objetivo
  sync_general()
  lector.decir("Objetivo enemigo fijado en " .. objetivo)
  audio.play("RL/Combate/Objetivo fijado.wav", { volume = 80, key = "rhom:objetivo" })
end

function nicks.leer_objetivo()
  if nicks.objetivo and nicks.objetivo ~= "" then
    lector.decir(nicks.objetivo .. " Objetivo enemigo")
  else
    lector.decir("No hay un objetivo enemigo definido. Define el nick X antes")
  end
end

function nicks.mostrar_nickx()
  if #nicks.nickx == 0 then
    lector.decir("No hay nick x almacenado")
    return
  end

  listas.nueva("Nick X")
  for _, nombre in ipairs(nicks.nickx) do
    listas.agregar("Nick X", nombre, function()
      send("mnick x " .. nombre)
    end)
  end
  listas.leer_actual()
end

nicks.aliases = {
  {
    pattern = "^obj\\s*(.*)$",
    action = function()
      nicks.fijar_objetivo(matches[2])
    end,
    name = "obj",
    desc = "Fija el objetivo enemigo"
  }
}

nicks.triggers = {
  {
    pattern = "^Nombre corto .* x quedando (.+)$",
    action = function()
      nicks.fijar_nickx(matches[2])
    end,
    name = "nickx_quedando",
    desc = "Captura nick x desde nombre corto"
  },
  {
    pattern = "^. Nombre corto .* x quedando (.+)$",
    action = function()
      nicks.fijar_nickx(matches[2])
    end,
    name = "nickx_quedando_eco",
    desc = "Captura nick x desde eco de nombre corto"
  },
  {
    pattern = "^Anadiendo nombre corto x como (.+)$",
    action = function()
      nicks.fijar_nickx(matches[2])
    end,
    name = "nickx_anadiendo",
    desc = "Captura nick x al anadirlo"
  },
  {
    pattern = "^Nombre corto x cambiado de .+ a (.+)$",
    action = function()
      nicks.fijar_nickx(matches[2])
      lector.decir("Nick x cambiado a " .. matches[2])
    end,
    name = "nickx_cambiado",
    desc = "Captura cambio de nick x"
  },
  {
    pattern = "^. Nombre corto x cambiado de .+ a (.+)$",
    action = function()
      nicks.fijar_nickx(matches[2])
      lector.decir("Nick x cambiado a " .. matches[2])
    end,
    name = "nickx_cambiado_eco",
    desc = "Captura eco de cambio de nick x"
  },
  {
    pattern = "^El nickname x equivale a (.+)$",
    action = function()
      nicks.fijar_nickx(matches[2])
    end,
    name = "nickx_equivale",
    desc = "Captura equivalencia de nick x"
  },
  {
    pattern = "^. El nickname x equivale a (.+)$",
    action = function()
      nicks.fijar_nickx(matches[2])
    end,
    name = "nickx_equivale_eco",
    desc = "Captura eco de equivalencia de nick x"
  },
  {
    pattern = "^Nombre corto x borrado\\.$",
    action = function()
      nicks.borrar_nickx()
    end,
    name = "nickx_borrado",
    desc = "Limpia nick x"
  }
}

nicks.key_bindings = {
  {
    modifiers = mudlet.keymodifier.Control + mudlet.keymodifier.Shift,
    key = mudlet.key.N,
    action = function()
      nicks.mostrar_nickx()
    end,
    name = "Ctrl+Shift+N",
    desc = "Muestra nick x"
  },
  {
    modifiers = mudlet.keymodifier.Control + mudlet.keymodifier.Shift,
    key = mudlet.key.O,
    action = function()
      nicks.leer_objetivo()
    end,
    name = "Ctrl+Shift+O",
    desc = "Lee objetivo enemigo"
  },
}

return nicks
