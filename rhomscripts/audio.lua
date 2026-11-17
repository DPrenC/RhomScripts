-- Reproducción por clave y volúmenes de RhomScripts.
local sonidos = require("sonidos")
local audio = {}
local volumenes

audio.default_tag = "rhomscripts"
audio.active = {}

local function leer_volumenes(borrador)
  local configuracion = require("configuracion")
  local function valor(id)
    if borrador then return borrador[id] end
    return configuracion.get(id)
  end
  local interfaz = valor("volumen_interfaz")
  return {
    general = valor("volumen_general"),
    grupos = {
      ui = interfaz,
      interfaz = interfaz,
      comunicaciones = valor("volumen_comunicaciones"),
      combate = valor("volumen_combate"),
      ambiente = valor("volumen_ambiente"),
    },
  }
end

function audio.aplicar_volumenes(borrador)
  volumenes = leer_volumenes(borrador)
end

function audio.iniciar(root)
  audio.aplicar_volumenes()
  local resumen = sonidos.cargar_catalogo(root)
  RhomScripts.modules.debug.catalogo(resumen)
  return resumen
end

-- Se reproduce una vez el primer archivo válido, con el volumen de la solicitud y del grupo.
function audio.reproducir(clave, opciones)
  assert(type(clave) == "string" and clave ~= "", "La clave sonora debe ser una cadena no vacía")
  assert(opciones == nil or type(opciones) == "table", "Las opciones de audio deben ser una tabla")
  local catalogo = sonidos.catalogo
  if not catalogo then return nil, "Catálogo de sonidos de RhomScripts no disponible" end
  local entry = catalogo.sonidos[clave]
  if not entry then return nil, "Clave sonora no disponible: " .. clave end
  opciones = opciones or {}
  local solicitado = opciones.volumen
  if solicitado == nil then solicitado = 100 end
  assert(type(solicitado) == "number" and solicitado >= 0 and solicitado <= 100,
    "El volumen solicitado debe estar entre 0 y 100")
  local niveles = volumenes or leer_volumenes()
  local factor_grupo = niveles.grupos[entry.grupo] or 100
  local efectivo = solicitado * factor_grupo * niveles.general / 10000
  if efectivo == 0 then return nil end
  local settings = {
    name = entry.archivos[1],
    volume = math.max(1, math.floor(efectivo + 0.5)),
    key = "rhom:catalogo:" .. clave,
    tag = audio.default_tag,
  }
  local result, message = playSoundFile(settings)
  if result == false or (result == nil and message) then
    error("Error al reproducir clave sonora " .. clave .. ": " .. tostring(message), 2)
  end
  audio.active[settings.key] = { path = settings.name, settings = settings }
  return settings.key
end

function audio.stop(key_or_opts)
  local settings
  if type(key_or_opts) == "table" then
    settings = key_or_opts
  elseif type(key_or_opts) == "string" then
    settings = { key = key_or_opts }
  else
    return
  end

  stopSounds(settings)
  if settings.key then
    audio.active[settings.key] = nil
  end
end

function audio.stop_tag(tag)
  stopSounds({ tag = tag or audio.default_tag })
  if not tag or tag == audio.default_tag then
    audio.active = {}
  end
end

return audio
