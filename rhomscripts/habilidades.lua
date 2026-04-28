-------------------------------------------------------------------------------
-- Modulo: habilidades
-- Migracion funcional desde HHFunciones.set, Habilidades_otros.set,
-- Hechizos_otros.set y Magia.set.
-------------------------------------------------------------------------------

local audio = require("audio")
local eventos = require("eventos")
local lector = require("lector")

local habilidades = {}

local alertas_habilidades = {
  aplastar = true, apunalar = true, arremeter = true, ataquedoble = true,
  ataquefurtivo = true, atrapar = true, atravesar = true, azuneu = true,
  azurae = true, cabezazo = true, carga = true, cazar = true,
  disparoapuntado = true, disparoincapacitador = true, doblegolpe = true,
  embestir = true, empalar = true, escupitajo = true, estocada = true,
  frenesi = true, golpear = true, golpearcano = true, golpecertero = true,
  hender = true, herir = true, instigar = true, lanzar = true, mordisco = true,
  oleada = true, pulverizar = true, saltoheroico = true, salva = true,
  tajar = true, vortice = true, zarpazo = true,
}

local impactos_habilidades = {
  aplastar = true, apuntar = true, arrojar = true, atravesar = true,
  cabezazo = true, disparoapuntado = true, disparocertero = true,
  disparoincapacitador = true, escupitajo = true, frenesi = true,
  golpecertero = true, herir = true, mordisco = true, saltoheroico = true,
  salva = true, tajar = true,
}

local impactos_hechizos = {
  ["cono de frio"] = "cono de frio",
  ["cono de frío"] = "cono de frio",
  defenestrar = "defenestrar",
  desintegrar = "desintegrar",
  ["flecha acida"] = "flecha acida",
  ["flecha ácida"] = "flecha acida",
  ["flecha de llamas"] = "flecha de llamas",
  ["flecha de fuego"] = "flecha de llamas",
  ["golpe de rayo"] = "golpe de rayo",
  relampago = "Relampago",
  ["relámpago"] = "Relampago",
}

local function trim(text)
  if type(text) ~= "string" then
    return ""
  end
  return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function lower(text)
  return trim(text):lower()
end

local function play(path, pan)
  audio.play(path, { volume = 80, pan = pan })
end

local function modo_experto()
  local modes = RhomScripts and RhomScripts.modules and RhomScripts.modules.modes
  return modes and modes.get_flag and modes.get_flag("experto")
end

local function es_grupo(name)
  local grupos = RhomScripts and RhomScripts.modules and RhomScripts.modules.grupos
  return grupos and grupos.es_miembro and grupos.es_miembro(name)
end

local function es_enemigo(name)
  if es_grupo(name) then
    return false
  end
  local stats = RhomScripts and RhomScripts.modules and RhomScripts.modules.stats
  local enemigos = stats and stats.ultimo_enemigo and stats.ultimo_enemigo:lower() or ""
  local value = lower(name)
  return value ~= "" and enemigos:find(value, 1, true) ~= nil
end

local function verbalizar(text)
  if modo_experto() then
    lector.decir(text)
  end
end

local function direccion(d)
  if not d or d == "" or d == "0" then
    return ""
  end
  return " desde " .. trim(d)
end

local function habilidad_sound(name, folder)
  local value = lower(name)
  if folder == "alerta" and alertas_habilidades[value] then
    return "RL/HHOtros/Alerta enemigos/" .. value .. ".wav"
  end
  if folder == "impacto" and impactos_habilidades[value] then
    return "RL/HHOtros/Habilidades impacto/" .. value .. ".wav"
  end
  local hechizo = impactos_hechizos[value]
  if folder == "impacto" and hechizo then
    return "RL/HHOtros/Hechizos impacto/" .. hechizo .. ".wav"
  end
  return nil
end

function habilidades.preparando(ejecutante, habilidad, objetivo)
  local caster = trim(ejecutante)
  local skill = lower(habilidad)
  local target = trim(objetivo)
  local own = target == "" or target == "0" or target == "ti"
  local grouped_caster = es_grupo(caster)
  local grouped_target = es_grupo(target)
  local enemy_caster = es_enemigo(caster)

  eventos.registrar("Alerta " .. skill .. " de " .. caster .. (own and "" or " sobre " .. target))

  local sound = habilidad_sound(skill, "alerta")
  if sound then
    if grouped_caster then
      play("RL/HHOtros/Alerta aliados/" .. skill .. ".wav", 4500)
    elseif enemy_caster or own then
      play(sound, -4500)
    end
  else
    play(grouped_caster and "RL/HHOtros/Alerta aliados/Alerta propia.wav" or "RL/HHOtros/Alerta enemigos/Alerta propia.wav")
  end

  if own then
    verbalizar(skill .. " de " .. caster)
  elseif grouped_caster then
    play(grouped_target and "RL/HHOtros/Alerta aliados/Alerta agrupado-aliado.wav" or "RL/HHOtros/Alerta aliados/Alerta agrupado-enemigo.wav")
    verbalizar(skill .. " a " .. target)
  elseif grouped_target then
    play(enemy_caster and "RL/HHOtros/Alerta enemigos/Alerta enemigo-agrupado.wav" or "RL/HHOtros/Alerta aliados/Alerta aliado-aliado.wav")
    verbalizar(skill .. " de " .. caster)
  else
    verbalizar(caster .. " " .. skill .. " " .. target)
  end
end

function habilidades.impacto(ejecutante, habilidad, receptor, critico, resultado, dir)
  local caster = trim(ejecutante)
  local skill = lower(habilidad)
  local target = trim(receptor)
  local own = target == "" or target == "0" or target == "ti"
  local result = tonumber(resultado) or 1
  local critical = critico == true or tostring(critico) == "1"

  if result == 1 then
    eventos.registrar("Impacto " .. skill .. (critical and " critico" or "") .. (caster ~= "0" and " de " .. caster or "") .. (own and "" or " sobre " .. target) .. direccion(dir))
  elseif result == 2 then
    eventos.registrar(skill .. " sin objetivo")
  elseif result == 3 then
    eventos.registrar((own and "Esquivas " or target .. " esquiva ") .. skill .. " de " .. caster)
  elseif result == 4 then
    eventos.registrar((own and "Paras " or target .. " para ") .. skill .. " de " .. caster)
  end

  if critical then
    play("RL/HHOtros/Generales/Critico otro.wav")
  end

  if result == 1 then
    local sound = habilidad_sound(skill, "impacto")
    if sound then
      play(sound)
    elseif own then
      play("RL/HHOtros/Generales/Impacto generico propio.wav")
    elseif es_grupo(target) then
      play("RL/HHOtros/Generales/Impacto generico enemigo-agrupado.wav")
    elseif es_grupo(caster) then
      play("RL/HHOtros/Generales/Impacto generico agrupado-enemigo.wav")
    else
  play("RL/HHOtros/Generales/Impacto enemigo-enemigo.wav")
    end
    if own then
      local combate = RhomScripts and RhomScripts.modules and RhomScripts.modules.combate
      if combate and combate.dano_recibido then
        combate.dano_recibido()
      end
    end
  elseif result == 2 then
    play(es_grupo(caster) and "RL/HHOtros/Generales/Sin objetivo agrupado.wav" or "RL/HHOtros/Generales/Sin objetivo enemigo.wav")
  elseif result == 3 then
    play(own and "RL/HHOtros/Generales/Esquiva propia.wav" or "RL/HHOtros/Generales/Esquiva otro.wav")
  elseif result == 4 then
    play(own and "RL/HHOtros/Generales/Parada propia.wav" or "RL/HHOtros/Generales/Parada otro.wav")
  end

  verbalizar((own and skill .. " " .. caster or caster .. " " .. skill .. " " .. target) .. direccion(dir))
end

local function preparar(pattern, skill, own)
  return {
    pattern = pattern,
    action = function()
      local objetivo = "0"
      if not own then
        objetivo = skill and matches[3] or matches[4]
      end
      habilidades.preparando(matches[2], skill or matches[3], objetivo)
    end,
    name = "hh_prepara_" .. tostring(#habilidades.triggers + 1),
    desc = "Detecta preparacion de habilidad"
  }
end

habilidades.triggers = {}

local preparaciones = {
  { "^(.+) se prepara para ejecutar (.+) sobre ti\\.$", nil, true },
  { "^(.+) se prepara para ejecutar (.+) sobre (.+)\\.$", nil, false },
  { "^(.+) enarbola .* y te examina con .+\\.$", "herir", true },
  { "^(.+) enarbola .* y examina a (.+) con .+\\.$", "herir", false },
  { "^(.+) comienza a serpentear a tu alrededor mientras se relame.*$", "mordisco", true },
  { "^(.+) serpentea alrededor de (.+), buscando puntos ciegos.*$", "mordisco", false },
  { "^(.+) te mira mientras comprime toda su musculatura\\.$", "lanzar", true },
  { "^(.+) observa a (.+) mientras comprime toda su musculatura\\.$", "lanzar", false },
  { "^(.+) agarra con fuerza su .* haciendo que sus nudillos se vuelvan blancos\\.$", "frenesi", true },
  { "^(.+) te insulta .* mientras se lanza a la carga\\.$", "carga", true },
  { "^(.+) espolea a su montura y se lanza a la carga contra ti\\.$", "carga", true },
  { "^(.+) insulta .* a (.+) y se lanza a la carga\\.$", "carga", false },
  { "^De repente (.+) abre los ojos y te mira con una.*sonrisa.*$", "azurae", true },
  { "^(.+) traza en el aire unos.*simbolos.*$", "azuneu", true },
  { "^(.+) pronuncia una.*palabra.*Espada Arcana.*$", "kalfue", true },
  { "^(.+) coloca .* en el suelo delante de .* y prepara.*$", "salva", true },
  { "^(.+) expulsa todo el aire de sus pulmones.* mientras te apunta.*$", "apuntar", true },
  { "^Sientes una grave cacofon.* de la boca de (.+).*$", "lamento", true },
  { "^Un horrible .*cantico.* boca de (.+).*$", "aullido infernal", true },
}

for _, item in ipairs(preparaciones) do
  table.insert(habilidades.triggers, preparar(item[1], item[2], item[3]))
end

local impactos = {
  { "^.* (.+) te alcanza.*con su maniobra de (.+)!$", nil, 0, 1 },
  { "^.*Logras parar.*a (.+) y su (.+)!$", nil, 0, 4 },
  { "^.*Logras esquivar.*a (.+) y su (.+)!$", nil, 0, 3 },
  { "^.*(.+) alcanza.*a (.+) con su maniobra de (.+)!$", nil, nil, 1 },
  { "^.*(.+) detiene su maniobra de (.+) cuando sus objetivos dejan.*$", nil, 1, 2 },
  { "^.*(.+) logra esquivar.*a (.+) y su (.+)!$", nil, nil, 3 },
  { "^.*(.+) logra parar.*a (.+) y su (.+)!$", nil, nil, 4 },
  { "^.*(.+) te entierra su .* en .* ignorando tus defensas\\.$", "herir", 0, 1 },
  { "^(.+) hunde su .* en .* de (.+), ignorando sus defensas\\.$", "herir", nil, 1 },
  { "^.*(.+) se abalanza sobre ti y te muerde.*$", "mordisco", 0, 1 },
  { "^(.+) se abalanza sobre (.+), destroz.*$", "mordisco", nil, 1 },
  { "^.*Eres agarrado brutalmente por (.+) y no puedes moverte!$", "lanzar", 0, 1 },
  { "^.*(.+) agarra con una fuerza brutal a (.+) mientras.*$", "lanzar", nil, 1 },
  { "^.*(.+) te sorprende con .* ataques!$", "sorprender", 0, 1 },
  { "^.*(.+) te impacta en .* con un fugaz disparo incapacitador!$", "disparoincapacitador", 0, 1 },
  { "^.*(.+) descarga contra ti un letal disparo apuntado!$", "disparoapuntado", 0, 1 },
  { "^.*(.+) lanza un disparocertero contra ti!$", "disparocertero", 0, 1 },
  { "^.*(.+) te dispara con su .* desde el (.+)!$", "apuntar", 0, 1 },
  { "^.*(.+) dispara contra (.+) desde el (.+)!$", "apuntar", nil, 1 },
  { "^.*Un rayo surge de las manos de (.+) electrocut.*$", "golpe de rayo", 0, 1 },
  { "^Un rayo surge de las manos de (.+) e impacta sobre (.+)\\.$", "golpe de rayo", nil, 1 },
  { "^.*(.+) extiende las palmas.* mortal rayo.*$", "desintegrar", 0, 1 },
  { "^.*te precipitas violentamente.*ventana.*$", "defenestrar", 0, 1 },
  { "^.*(.+) sale disparad.* atravesar la ventana.*$", "defenestrar", nil, 1 },
  { "^.*(.+) dispara .* flecha.* de fuego contra ti!$", "flecha de fuego", 0, 1 },
  { "^.*(.+) dispara una flecha .cida contra ti.*$", "flecha acida", 0, 1 },
  { "^.*(.+) dispara una flecha .cida contra (.+), impregnando.*$", "flecha acida", nil, 1 },
  { "^.*(.+) misiles m.gicos surgen de los dedos de (.+) e impactan.*tu pecho\\.$", "proyectil magico", 0, 1 },
  { "^.* meteoros diminutos surgen de la mano de (.+) y estallan.*tu pecho\\.$", "meteoros de ignis", 0, 1 },
  { "^.*cono helado surgiera de las manos de (.+),.*$", "cono de frio", 0, 1 },
  { "^.*devastad. por el lamento de la banshee!$", "lamento", 0, 1 },
  { "^.*aullido de (.+) penetra en tu cabeza.*$", "aullido infernal", 0, 1 },
  { "^.*(.+) invoca una columna de fuego sobre ti!$", "columna de fuego", 0, 1 },
  { "^.*terremoto te sacude.*$", "terremoto", 0, 1 },
  { "^.*rel.mpago invocado por (.+) te electrocuta!$", "relampago", 0, 1 },
}

for index, item in ipairs(impactos) do
  table.insert(habilidades.triggers, {
    pattern = item[1],
    action = function()
      local caster = matches[2] or "0"
      local skill = item[2] or matches[3] or "habilidad"
      local target = item[3] == 0 and "0" or (matches[3] or "0")
      if item[2] and item[3] == nil then
        target = matches[3] or "0"
      end
      habilidades.impacto(caster, skill, target, false, item[4], matches[4] or "0")
    end,
    name = "hh_impacto_" .. index,
    desc = "Detecta impacto de habilidad o hechizo"
  })
end

local magia_generica = {
  { "^(.+) empieza a formular un hechizo\\.$", "RL/Hechizos/Hechizo enemigo.wav", "formula hechizo" },
  { "^(.+) toca con su mano derecha su Cinturon del Guardian de la Magia\\.$", "RL/Hechizos/Hechizo enemigo.wav", "activa cinturon magico" },
  { "^(.+) alza un brazo al frente y extiende la palma.*$", "RL/Hechizos/Hechizo enemigo.wav", "formula hechizo" },
  { "^(.+) pronuncia el cantico: (.+)$", "RL/Hechizos/Pronuncia enemigo.wav", "pronuncia cantico" },
  { "^.*Resistes los efectos del hechizo de .+!$", "RL/Hechizos/Resistes hechizo.wav", "resiste hechizo" },
  { "^Resistes los efectos del conjuro de .+", "RL/Hechizos/Resistes hechizo.wav", "resiste conjuro" },
  { "^.*El hechizo de .* no tiene ningun efecto.*$", "RL/Hechizos/Hechizo sin efecto.wav", "hechizo sin efecto" },
  { "^La piel de (.+) vuelve a su estado normal\\.$", "RL/Hechizos/Pieles_espejos agenos off.wav", "sin pieles" },
  { "^Las imagenes de (.+) se desvanecen\\.$", "RL/Hechizos/Pieles_espejos agenos off.wav", "sin imagenes" },
  { "^.*Tu movimiento rompe tu concentracion.*$", "RL/Hechizos/Hechizo arruinado.wav", "hechizo arruinado" },
  { "^.*Tu ataque rebota en la piel de piedra de .+", "RL/Hechizos/Piel de piedra.wav", "piel de piedra" },
  { "^Las espadas guardianas que rodeaban a (.+) desaparecen\\.$", "RL/Hechizos/Espadas guardianas agenas off.wav", "espadas guardianas off" },
  { "^.* deja de ser una estatua de piedra.*$", "RL/Hechizos/Piedra a carne.wav", "piedra a carne" },
  { "^.* aparece repentinamente ante tus ojos!$", "RL/Hechizos/Aparecer.wav", "aparece" },
  { "^.*Sientes como una fuerza divina te rodea.*$", "RL/Hechizos/Retener recibido.wav", "retenido" },
  { "^Puedes moverte libremente de nuevo\\.$", "RL/Combate/Libre propio.wav", "libre" },
  { "^.* queda liberad. de la fuerza que le reten.a\\.$", "RL/Combate/Libre enemigo.wav", "liberado" },
  { "^.*Paralizas a .* con tus ataque!$", "RL/Hechizos/Retener.wav", "retener" },
  { "^.*Tu piel vuelve a su estado normal\\.$", "RL/Hechizos/Pieles_espejos off.wav", "piel normal" },
  { "^Tu piel se transforma en dura corteza de roble\\.$", "RL/Hechizos/Piel de corteza.wav", "piel corteza" },
  { "^.*Inicias una salmodia.*$", "RL/Hechizos/Salmodia propia.wav", "salmodia propia" },
  { "^.* inicia una salmodia.*$", "RL/Hechizos/Salmodia agena.wav", "salmodia ajena" },
  { "^.*aura de color amarillo.*cosquillas\\.$", "RL/Hechizos/Accion libre on.wav", "accion libre on" },
  { "^.*aura de proteccion de movimientos.*desaparecer\\.$", "RL/Hechizos/Accion libre off.wav", "accion libre off" },
  { "^Finalizas el hechizo 'disipar magia'.*$", "RL/Hechizos/Disipar magia.wav", "disipar magia" },
  { "^Tu hechizo contra .* falla\\.$", "RL/Hechizos/Hechizo sin objetivo.wav", "hechizo sin objetivo" },
  { "^.* cura algunas de sus heridas.*$", "RL/Hechizos/Cura otro.wav", "cura otro" },
  { "^.* te toca, cur.*$", "RL/Sucesos/Cura recibida.wav", "cura recibida" },
  { "^.*tormenta de luz curativa.*$", "RL/Sucesos/Cura recibida.wav", "cura recibida" },
  { "^Algunas de tus heridas sanan m.gicamente\\.$", "RL/Sucesos/Cura recibida.wav", "regeneracion magica" },
    { "^De repente percibes una sombra magica acechante\\.$", "RL/Hechizos/Sombra mágica.wav", "sombra magica" },
  { "^Un brillante globo de fuerza surge.*intent.*engullirte.*$", "RL/Hechizos/Wilan fallo.wav", "wilan fallida" },
  { "^Un brillante globo de fuerza surge.*dejandote encerrad.*$", "RL/Hechizos/Wilan on.wav", "wilan on" },
  { "^La esfera de energia que te envolvia desaparece\\.$", "RL/Hechizos/Wilan off.wav", "wilan off" },
  { "^Tu resistencia de .* se desvanece\\.$", "RL/Hechizos/Protes resis of.wav", "resistencia off" },
  { "^Eres cubierto por un aura .+\\.$", "RL/Hechizos/Protes resis on.wav", "proteccion on" },
  { "^.*notas una conexion con el\\.$", "RL/Hechizos/Enlace vital on.wav", "enlace vital on" },
  { "^Tu hechizo de 'enlace vital' desaparece\\.$", "RL/Hechizos/Enlace vital of.wav", "enlace vital off" },
  { "^.*El cielo ruge cuando invocas un relampago.*$", "RL/Hechizos/Relampago.wav", "relampago" },
  { "^.*regeneraci.n.* sobre ti\\.$", "RL/Hechizos/Regeneracion on.wav", "regeneracion on" },
  { "^.*fin del hechizo de 'regeneraci.n'.*$", "RL/Hechizos/Regeneracion off.wav", "regeneracion off" },
  { "^Sientes como un poder magico.*hace anicos.*$", "RL/Hechizos/Disipar magia recibido.wav", "disipar recibido" },
  { "^La tierra tiembla.*UN TERREMOTO.*$", "RL/Hechizos/Terremoto.wav", "terremoto" },
}

for index, rule in ipairs(magia_generica) do
  table.insert(habilidades.triggers, {
    pattern = rule[1],
    action = function()
      eventos.registrar(rule[3])
      play(rule[2])
      verbalizar(rule[3])
    end,
    name = "magia_general_" .. index,
    desc = "Trigger general de magia"
  })
end

return habilidades
