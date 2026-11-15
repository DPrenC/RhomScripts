-------------------------------------------------------------------------------
-- Modulo: grupos
-- Migracion funcional desde Grupos.set.
-------------------------------------------------------------------------------

local audio = require("audio")
local eventos = require("eventos")
local lector = require("lector")
local listas = require("listas")

local grupos = {}

grupos.miembros = {}
grupos.lider = ""

local function trim(text)
  if type(text) ~= "string" then
    return ""
  end
  return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function normalizar(text)
  return trim(text):lower()
end

local function play(path)
  audio.play(path, { volume = 80 })
end

local function registrar_evento(text)
  eventos.registrar(text)
end

local function add_member(name)
  local value = trim(name)
  if value == "" then
    return
  end
  for _, member in ipairs(grupos.miembros) do
    if normalizar(member) == normalizar(value) then
      return
    end
  end
  table.insert(grupos.miembros, value)
end

local function remove_member(name)
  local value = normalizar(name)
  for index = #grupos.miembros, 1, -1 do
    if normalizar(grupos.miembros[index]) == value then
      table.remove(grupos.miembros, index)
    end
  end
end

function grupos.reset()
  grupos.miembros = {}
  grupos.lider = ""
end

function grupos.set_lider(name)
  grupos.lider = trim(name)
  add_member(grupos.lider)
end

function grupos.es_miembro(name)
  local value = normalizar(name)
  if value == "" then
    return false
  end
  for _, member in ipairs(grupos.miembros) do
    if normalizar(member) == value then
      return true
    end
  end
  return false
end

function grupos.obtener_lider()
  return grupos.lider
end

function grupos.listar_miembros()
  local result = {}
  for _, member in ipairs(grupos.miembros) do
    table.insert(result, member)
  end
  return result
end

function grupos.mostrar()
  if #grupos.miembros == 0 and grupos.lider == "" then
    lector.decir("No perteneces a ningun grupo")
    return
  end

  listas.nueva("Grupo")
  if grupos.lider ~= "" then
    listas.agregar("Grupo", "Lider: " .. grupos.lider)
  end
  for _, member in ipairs(grupos.miembros) do
    listas.agregar("Grupo", member)
  end
  listas.leer_actual()
end

grupos.triggers = {
  {
    pattern = "^.*\\[Grupo\\] Eres invitado al grupo liderado por (.+)",
    action = function()
      registrar_evento(line)
      play("RL/Generales/Grupo invitacion.wav")
    end,
    name = "grupo_invitacion_recibida",
    desc = "Detecta invitacion a grupo"
  },
  {
    pattern = "^.*\\[Grupo\\] .* invita a .* al grupo\\.$",
    action = function()
      registrar_evento(line)
      play("RL/Generales/Grupo invitacion.wav")
    end,
    name = "grupo_invitacion_otros",
    desc = "Detecta invitaciones de grupo"
  },
  {
    pattern = "^.*\\[Grupo\\] Invitas a (.+) a tu grupo\\.$",
    action = function()
      registrar_evento(line)
      play("RL/Generales/Grupo invitacion.wav")
    end,
    name = "grupo_invitas",
    desc = "Detecta invitacion enviada"
  },
  {
    pattern = "^.*Has creado tu propio grupo\\.$",
    action = function()
      grupos.reset()
      registrar_evento(line)
      play("RL/Generales/Grupo evento.wav")
    end,
    name = "grupo_creado",
    desc = "Detecta creacion de grupo"
  },
  {
    pattern = "^.*\\[Grupo\\] Te unes al grupo liderado por (.+)\\.$",
    action = function()
      grupos.reset()
      grupos.set_lider(matches[2])
      registrar_evento(line)
      play("RL/Generales/Grupo evento.wav")
    end,
    name = "grupo_te_unes",
    desc = "Detecta union a grupo"
  },
  {
    pattern = "^.*\\[Grupo\\] (.+) se une al grupo\\.$",
    action = function()
      add_member(matches[2])
      registrar_evento(line)
      play("RL/Generales/Grupo evento.wav")
    end,
    name = "grupo_se_une",
    desc = "Agrega miembro al grupo"
  },
  {
    pattern = "^.*\\[Grupo\\] Unes al grupo a (.+)\\.$",
    action = function()
      add_member(matches[2])
      registrar_evento(line)
      play("RL/Generales/Grupo evento.wav")
    end,
    name = "grupo_unes",
    desc = "Agrega miembro invitado"
  },
  {
    pattern = "^.*\\[Grupo\\] (.+) abandona el grupo\\.$",
    action = function()
      remove_member(matches[2])
      registrar_evento(line)
      play("RL/Generales/Grupo evento.wav")
    end,
    name = "grupo_abandona",
    desc = "Elimina miembro que abandona"
  },
  {
    pattern = "^.*\\[Grupo\\] Expulsas del grupo a (.+)\\.$",
    action = function()
      remove_member(matches[2])
      registrar_evento(line)
      play("RL/Generales/Grupo evento.wav")
    end,
    name = "grupo_expulsas",
    desc = "Elimina miembro expulsado"
  },
  {
    pattern = "^.*\\[Grupo\\] (.+) es expulsad. del grupo\\.$",
    action = function()
      remove_member(matches[2])
      registrar_evento(line)
      play("RL/Generales/Grupo evento.wav")
    end,
    name = "grupo_expulsado",
    desc = "Elimina miembro expulsado por otros"
  },
  {
    pattern = "^.*\\[Grupo\\] Eres expulsado del grupo liderado por .+",
    action = function()
      grupos.reset()
      registrar_evento(line)
      play("RL/Generales/Grupo disolucion.wav")
    end,
    name = "grupo_te_expulsan",
    desc = "Limpia grupo al ser expulsado"
  },
  {
    pattern = "^.*\\[Grupo\\] .* disuelve el grupo\\.$",
    action = function()
      grupos.reset()
      registrar_evento(line)
      play("RL/Generales/Grupo disolucion.wav")
    end,
    name = "grupo_disuelto",
    desc = "Limpia grupo disuelto"
  },
  {
    pattern = "^.*\\[Grupo\\] Disuelves tu grupo\\.$",
    action = function()
      grupos.reset()
      registrar_evento(line)
      play("RL/Generales/Grupo disolucion.wav")
    end,
    name = "grupo_disuelves",
    desc = "Limpia grupo propio disuelto"
  },
  {
    pattern = "^.*\\[Grupo\\] Abandonas el grupo liderado por .+",
    action = function()
      grupos.reset()
      registrar_evento(line)
      play("RL/Generales/Grupo disolucion.wav")
    end,
    name = "grupo_abandonas",
    desc = "Limpia grupo al abandonar"
  },
  {
    pattern = "^.*\\[Grupo\\] Cedes el liderazgo del grupo a (.+)\\.$",
    action = function()
      grupos.set_lider(matches[2])
      registrar_evento(line)
      play("RL/Generales/Grupo evento.wav")
    end,
    name = "grupo_cedes_lider",
    desc = "Actualiza lider cedido"
  },
  {
    pattern = "^.*\\[Grupo\\] (.+) cede el liderazgo del grupo a (.+)\\.$",
    action = function()
      grupos.set_lider(matches[3])
      registrar_evento(line)
      play("RL/Generales/Grupo evento.wav")
    end,
    name = "grupo_ceden_lider",
    desc = "Actualiza lider"
  },
  {
    pattern = "^.*\\[Grupo\\] (.+) te entrega el liderazgo del grupo\\.$",
    action = function()
      grupos.lider = "tu"
      registrar_evento(line)
      play("RL/Generales/Grupo evento.wav")
    end,
    name = "grupo_liderazgo_recibido",
    desc = "Detecta liderazgo recibido"
  },
  {
    pattern = "^Grupo liderado por: (.+)$",
    action = function()
      grupos.reset()
      grupos.set_lider(matches[2])
    end,
    name = "grupo_listado_lider",
    desc = "Inicia actualizacion de grupo"
  },
  {
    pattern = "^\\s+-\\s+(.+)$",
    action = function()
      add_member(matches[2])
    end,
    name = "grupo_listado_miembro",
    desc = "Captura miembro listado"
  },
}

grupos.key_bindings = {
  {
    modifiers = mudlet.keymodifier.Control + mudlet.keymodifier.Shift,
    key = mudlet.key.G,
    action = function()
      grupos.mostrar()
    end,
    name = "Ctrl+Shift+G",
    desc = "Muestra miembros del grupo"
  },
}

return grupos
