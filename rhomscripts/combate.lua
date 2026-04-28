-------------------------------------------------------------------------------
-- Modulo: combate
-- Migracion funcional desde Combate.set, Bloqueos.set y Estados.set.
-------------------------------------------------------------------------------

local audio = require("audio")
local eventos = require("eventos")
local lector = require("lector")
local listas = require("listas")

local combate = {}

combate.heridas = ""
combate.historial_estados = {}
combate.ultimo_estado = ""
combate.estado_en_curso = false
combate.bloqueos_clase = false

local function trim(text)
  if type(text) ~= "string" then
    return ""
  end
  return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function play(path, pan)
  audio.play(path, { volume = 80, pan = pan })
end

local function registrar(text)
  eventos.registrar(text)
end

local function modo_experto()
  local modes = RhomScripts and RhomScripts.modules and RhomScripts.modules.modes
  return modes and modes.get_flag and modes.get_flag("experto")
end

local function say_experto(text)
  if modo_experto() then
    lector.decir(text)
  end
end

local function sujeto_es_grupo(name)
  local grupos = RhomScripts and RhomScripts.modules and RhomScripts.modules.grupos
  return grupos and grupos.es_miembro and grupos.es_miembro(name)
end

local function sujeto_es_enemigo(name)
  local stats = RhomScripts and RhomScripts.modules and RhomScripts.modules.stats
  local value = trim(name):lower()
  if value == "" then
    return false
  end
  if sujeto_es_grupo(value) then
    return false
  end
  local enemigos = stats and stats.ultimo_enemigo and stats.ultimo_enemigo:lower() or ""
  return enemigos:find(value, 1, true) ~= nil
end

local function sonido_sujeto(name, aliado_sound, enemigo_sound)
  if sujeto_es_enemigo(name) then
    play(enemigo_sound, -4500)
  else
    play(aliado_sound, 4500)
  end
end

local kill_propios = {
  { "consigue esquivar", "RL/Combate/Kills/Propios/esquivado*4.wav" },
  { "consigue parar", "RL/Combate/Kills/Propios/bloqueado*4.wav" },
  { "sin producir ning", "RL/Combate/Kills/Propios/Sin daño*4.wav" },
  { "Aplastas", "RL/Combate/Kills/Propios/aplastante*4.wav" },
  { "Perforas", "RL/Combate/Kills/Propios/penetrante*4.wav" },
  { "Laceras", "RL/Combate/Kills/Propios/lacerante*4.wav" },
  { "Rajas", "RL/Combate/Kills/Propios/cortante*4.wav" },
  { "Electrocutas", "RL/Combate/Kills/Propios/electrico*4.wav" },
  { "Quemas", "RL/Combate/Kills/Propios/fuego*4.wav" },
  { "Mojas", "RL/Combate/Kills/Propios/agua*4.wav" },
  { "Apedreas", "RL/Combate/Kills/Propios/tierra*4.wav" },
  { "Soplas", "RL/Combate/Kills/Propios/aire*4.wav" },
  { "Corroes", "RL/Combate/Kills/Propios/Acido*4.wav" },
  { "Envenenas", "RL/Combate/Kills/Propios/Veneno*4.wav" },
  { "Congelas", "RL/Combate/Kills/Propios/Hielo*4.wav" },
  { "Muerdes", "RL/Combate/Kills/Propios/desarmado*4.wav" },
  { "Pateas", "RL/Combate/Kills/Propios/desarmado*4.wav" },
  { "Cabeceas", "RL/Combate/Kills/Propios/desarmado*4.wav" },
  { "Golpeas", "RL/Combate/Kills/Propios/desarmado*4.wav" },
}

local kill_enemigos = {
  { "Logras esquivar", "RL/Combate/Kills/Enemigos/esquivado*4.wav" },
  { "Logras parar", "RL/Combate/Kills/Enemigos/bloqueado*4.wav" },
  { "sin producir ning", "RL/Combate/Kills/Enemigos/Sin daño*4.wav" },
  { "te aplasta", "RL/Combate/Kills/Enemigos/Aplastante*4.wav" },
  { "te perfora", "RL/Combate/Kills/Enemigos/Penetrante*4.wav" },
  { "te lacera", "RL/Combate/Kills/Enemigos/Lacerante*4.wav" },
  { "te raja", "RL/Combate/Kills/Enemigos/Cortante*4.wav" },
  { "te electrocuta", "RL/Combate/Kills/Enemigos/Electrico*4.wav" },
  { "te quema", "RL/Combate/Kills/Enemigos/Fuego*4.wav" },
  { "te apedrea", "RL/Combate/Kills/Enemigos/Tierra*4.wav" },
  { "te sopla", "RL/Combate/Kills/Enemigos/Aire*4.wav" },
  { "te congela", "RL/Combate/Kills/Enemigos/Hielo*4.wav" },
  { "te envenena", "RL/Combate/Kills/Enemigos/Veneno*4.wav" },
  { "te corroe", "RL/Combate/Kills/Enemigos/Acido*4.wav" },
  { "te muerde", "RL/Combate/Kills/Enemigos/desarmado*4.wav" },
  { "te patea", "RL/Combate/Kills/Enemigos/desarmado*4.wav" },
  { "te cabecea", "RL/Combate/Kills/Enemigos/desarmado*4.wav" },
  { "te golpea", "RL/Combate/Kills/Enemigos/desarmado*4.wav" },
}

local function play_kill(text, own)
  local rules = own and kill_propios or kill_enemigos
  local pan = own and 4500 or -4500
  if text:find("cr.ticamente") or text:find("criticamente") then
    play(own and "RL/Combate/Kills/Propios/Critico.wav" or "RL/Combate/Kills/Enemigos/Critico.wav", pan)
  end
  for _, rule in ipairs(rules) do
    if text:find(rule[1], 1, true) then
      play(rule[2], pan)
      return
    end
  end
  play(own and "RL/Combate/Kills/Propios/generico.wav" or "RL/Combate/Kills/Enemigos/generico.wav", pan)
end

local function set_heridas(text)
  combate.heridas = trim((text or ""):gsub("una%s+", ""):gsub("un%s+", ""):gsub("la%s+", ""):gsub("el%s+", ""):gsub("!", ""))
end

function combate.dano_recibido(text)
  local stats = RhomScripts and RhomScripts.modules and RhomScripts.modules.stats
  if stats and stats.registrar_cpvs then
    stats.registrar_cpvs(tonumber(text) or -1)
  end
end

function combate.bloqueo(nombre)
  local value = trim(nombre)
  play("RL/Bloqueos/Bloqueo.wav")
  if value == "concentracion" then
    play("RL/Bloqueos/Concentracion.wav")
  else
    registrar("Bloqueo " .. value)
    say_experto(value)
  end
end

function combate.registrar_estado(nombre, vida, energia)
  local pct = tonumber(vida) or 0
  local name = trim(nombre)
  local texto
  if energia and energia ~= "" then
    texto = string.format("%s Vida: %s%%, Energia: %s%%", name, pct, energia)
  else
    texto = string.format("%s %s%%", name, pct)
  end

  combate.ultimo_estado = texto
  table.insert(combate.historial_estados, 1, texto)
  while #combate.historial_estados > 50 do
    table.remove(combate.historial_estados)
  end

  local enemigo = sujeto_es_enemigo(name)
  local side = enemigo and "enemigo" or "aliado"
  local pan = enemigo and -4500 or 4500
  local level = pct >= 90 and "100" or (pct >= 60 and "90" or (pct >= 30 and "60" or "30"))
  play("RL/Combate/Estado " .. side .. " " .. level .. ".wav", pan)
  if pct < 30 then
    registrar(name .. " " .. tostring(pct) .. "%")
  end
  lector.decir(texto)
end

function combate.mostrar_estados()
  if #combate.historial_estados == 0 then
    lector.decir("Historial de estados vacio")
    return
  end
  listas.nueva("Historial de estados")
  for index = #combate.historial_estados, 1, -1 do
    local value = combate.historial_estados[index]
    listas.agregar("Historial de estados", value, function()
      lector.copiar(value, "Estado copiado")
    end)
  end
  listas.leer_actual()
end

local sound_rules = {
  { "^.* da un grito desgarrador antes de que su espiritu abandone Eirea\\.$", "RL/Combate/Muerte enemigo.wav", true },
  { "^Propinas el golpe mortal a (.+)", "RL/Combate/Muerte.wav", true },
  { "^.* propina el golpe mortal a .+", "RL/Combate/Muerte otro.wav", true },
  { "^Tu cuerpo sin vida cae al .* Parece que te han matado", "RL/Combate/Muerte propia.wav", false },
  { "^Recuperas tu forma .+ Notas tu cuerpo algo mas estropeado\\.$", "RL/Sucesos/Perder con.wav", false },
  { "^\\[Obtienes .* puntos de gloria\\]$", "RL/Combate/Gloria.wav", true },
  { "^.*Te encaras contra .* en posicion de combate\\.$", "RL/Combate/Atacar.wav", false },
  { "^.* pierde la concentracion!$", "RL/HHOtros/Generales/Pierde concentracion enemigo.wav", false },
  { "^.*Tu golpe causa una profunda hemorragia a .* en .*!$", "RL/Combate/Hemorrajia.wav", false },
  { "^.*Lo que te parecio ser .* desaparece al golpearl.*\\.$", "RL/Combate/Golpear imagen.wav", false },
  { "^Empiezas a calmarte y reconsiderar a tus enemigos", "RL/Combate/Peleas parando.wav", false },
  { "^Finalmente logras calmarte y olvidas tus peleas con .+\\.$", "RL/Combate/Peleas paradas.wav", false },
  { "^Estas en mitad de una lucha, no es momento para calmarse\\.$", "RL/Combate/Peleas no paradas.wav", false },
  { "^.*Estas persiguiendo a (.+)", "RL/Combate/Persiguiendo.WAV", false },
  { "^.*Estas siendo atacad. por (.+)", "RL/Combate/Siendo atacado.wav", true },
  { "^.*Paras de perseguir a .+\\.$", "RL/Combate/Parar perseguir.wav", false },
  { "^.* machaca tu armadura con sus ataques!$", "RL/Combate/Armadura propia dañada.wav", true },
  { "^.*Tu armadura recupera su fortaleza tras la carga de .+\\.$", "RL/Combate/Armadura propia recuperada.wav", true },
  { "^.*Tu armadura deja de estar expuesta\\.$", "RL/Combate/Armadura propia recuperada.wav", true },
  { "^.* consigue escurrirse entre ti y .* protegiendole\\.$", "RL/Combate/Proteger enemigo.wav", true },
  { "^.* te protege\\.$", "RL/Combate/Proteger recibido.wav", true },
  { "^.* os protege a .* y a ti\\.$", "RL/Combate/Proteger recibido.wav", true },
  { "^.*Proteges a .+\\.$", "RL/Combate/Proteger.wav", false },
  { "^.*Proteges valientemente a .+\\.$", "RL/Combate/Proteger.wav", false },
  { "^Tu cuerpo responde y finalmente logra contener tu herida", "RL/Combate/Cicatrizar.wav", false },
  { "^Tu hemorragia se detiene\\.$", "RL/Combate/Cicatrizar.wav", false },
  { "^Algunas de tus heridas multiples logran estabilizarse", "RL/Combate/Cicatrizar.wav", false },
  { "^Dejas de sangrar por todas tus heridas multiples\\.$", "RL/Combate/Cicatrizar.wav", false },
  { "^El enorme boquete que tenias se cicatriza", "RL/Combate/Cicatrizar.wav", false },
  { "^Oyes el gotear de la sangre\\.$", "RL/Combate/Gotear sangre.wav", false },
  { "^.*Vientos nauseabundos y gritos de combate llegan", "RL/Combate/Vientos de guerra.wav", true },
  { "^.*Suena el cuerno de piedra de la guardia de Kheleb Dum!$", "RL/Combate/Ciudades/Kheleb.wav", false },
  { "^.*La campana de la Torre de la Santa Cruzada", "RL/Combate/Ciudades/Takome.wav", false },
  { "^.*Escuchas repicar las campanas de la ciudad de Anduar\\.$", "RL/Combate/Ciudades/Anduar.wav", false },
  { "^.*Un gutural grito de Loredor", "RL/Combate/Ciudades/Thorin.wav", false },
  { "^.*rafaga de fuegos artificiales", "RL/Combate/Ciudades/Veleiron.wav", false },
  { "^.*salva de canones avisa del asedio", "RL/Combate/Ciudades/Poldarn.wav", false },
  { "^.*soldados.*Galador", "RL/Combate/Ciudades/Galador.wav", false },
  { "^.*campesinos de Brenoic", "RL/Combate/Ciudades/Brenoic.wav", false },
  { "^.*jinetes de Injhan", "RL/Combate/Ciudades/Dara.wav", false },
  { "^.*Gong de Ozomatli", "RL/Combate/Ciudades/Grimoszk.wav", false },
  { "^La horrenda apariencia de .* no consigue remover", "RL/Combate/Miedo resistir.wav", true },
  { "^.*Dejas de sentir esa sensacion de valor", "RL/Combate/Valor fin.wav", false },
  { "^.*La horrenda apariencia de .* hace que un escalofrio", "RL/Combate/Miedo fallar.WAV", true },
  { "^.*Estas muerto de miedo", "RL/Combate/Huir.WAV", false },
  { "^Varios abrojos puntiagudos\\.$", "RL/Combate/Abrojos 1.wav", false },
  { "^.* pisas sin querer uno de los afilados abrojos", "RL/Combate/Abrojos 1.wav", false },
  { "^Oyes pequenos ruidos metalicos cayendo", "RL/Combate/Abrojos 2.wav", false },
  { "^.* caes al suelo rendido\\.$", "RL/Combate/Dormirse.wav", true },
  { "^Te despiertas\\.$", "RL/Combate/Despertarse.wav", false },
  { "^.* se despierta\\.$", "RL/Combate/Despertarse otro.wav", false },
  { "^Sin darte cuenta introduces .* en un cepo", "RL/Combate/Cepo.wav", false },
  { "^Encuentras una trampa en el suelo\\.?$", "RL/Combate/Trampa.wav", false },
  { "^Ves una trampa semiescondida", "RL/Combate/Trampa.wav", false },
  { "^.* se pilla con un cepo\\.$", "RL/Combate/Cepo otro.wav", true },
  { "^.* se desploma a causa de la perdida de sangre\\.$", "RL/Combate/Stun.wav", true },
  { "^.* empieza a centrar sus golpes sobre .+", "RL/Combate/Centrar otros.wav", true },
  { "^Rastro de Restos de visceras\\. en direccion .+\\.$", "RL/Combate/Rastro visceras*2.wav", true },
  { "^Rastro de Charco de sangre en direccion .+\\.$", "RL/Combate/Rastro sangre*2.wav", true },
}

combate.triggers = {
  {
    pattern = "^\\[.*\\] (.+)$",
    action = function()
      play_kill(matches[2], false)
    end,
    name = "kill_enemigo",
    desc = "Sonidos de impactos recibidos o enemigos"
  },
  {
    pattern = "^\\[#\\] (.+)$",
    action = function()
      play_kill(matches[2], true)
    end,
    name = "kill_propio",
    desc = "Sonidos de impactos propios"
  },
  {
    pattern = "^\\[El bloqueo '(.+)' termina\\]$",
    action = function()
      combate.bloqueo(matches[2])
    end,
    name = "bloqueo_fin",
    desc = "Avisa fin de bloqueo"
  },
  {
    pattern = "^.*De un fugaz vistazo, examinas el estado de los que te rodean\\.$",
    action = function()
      combate.estado_en_curso = true
    end,
    name = "estado_inicio",
    desc = "Inicia captura de estados"
  },
  {
    pattern = "^(.+) Vida: ([0-9]+)% Energia: ([0-9]+)%",
    action = function()
      if combate.estado_en_curso then
        combate.registrar_estado(matches[2], matches[3], matches[4])
      end
    end,
    name = "estado_vida_energia",
    desc = "Captura estado con vida y energia"
  },
  {
    pattern = "^(.+) ([0-9]+)%$",
    action = function()
      if combate.estado_en_curso then
        combate.registrar_estado(matches[2], matches[3])
      end
    end,
    name = "estado_vida",
    desc = "Captura estado con vida"
  },
  {
    pattern = "^.*Te desangras.* en (.+)",
    action = function()
      set_heridas(matches[2])
      combate.dano_recibido()
      play("RL/Combate/Desangrar.wav")
    end,
    name = "herida_desangra",
    desc = "Actualiza herida por desangrado"
  },
  {
    pattern = "^.*El golpe de .* te causa una profunda herida en (.+)!$",
    action = function()
      set_heridas(matches[2])
      combate.dano_recibido()
      play("RL/Combate/Desangrar.wav")
    end,
    name = "herida_profunda",
    desc = "Actualiza herida profunda"
  },
  {
    pattern = "^Un enorme boquete se te abre en (.+) y comienza a sangrar",
    action = function()
      set_heridas(matches[2])
      combate.dano_recibido()
      play("RL/Combate/Desangrar.wav")
    end,
    name = "herida_boquete",
    desc = "Actualiza boquete"
  },
  {
    pattern = "^.*El ataque de .* te clava un proyectil en (.+), causando",
    action = function()
      set_heridas("Proyectil " .. matches[2])
      combate.dano_recibido()
      play("RL/Combate/Desangrar.wav")
    end,
    name = "herida_proyectil",
    desc = "Actualiza herida de proyectil"
  },
}

for _, rule in ipairs(sound_rules) do
  table.insert(combate.triggers, {
    pattern = rule[1],
    action = function()
      if rule[3] then
        registrar(line)
      end
      play(rule[2])
    end,
    name = "combate_sonido_" .. tostring(#combate.triggers + 1),
    desc = "Trigger sonoro de combate"
  })
end

combate.key_bindings = {
  {
    key = mudlet.key.F5,
    action = function()
      lector.decir(combate.ultimo_estado ~= "" and combate.ultimo_estado or "No has comprobado ningun estado por el momento")
    end,
    name = "F5",
    desc = "Lee ultimo estado"
  },
  {
    modifiers = mudlet.keymodifier.Shift,
    key = mudlet.key.F5,
    action = function()
      combate.mostrar_estados()
    end,
    name = "Shift+F5",
    desc = "Muestra historial de estados"
  },
  {
    modifiers = mudlet.keymodifier.Alt,
    key = mudlet.key.G,
    action = function()
      lector.decir(combate.heridas ~= "" and combate.heridas or "No tienes heridas")
    end,
    name = "Alt+G",
    desc = "Lee heridas"
  },
  {
    modifiers = mudlet.keymodifier.Alt + mudlet.keymodifier.Shift,
    key = mudlet.key.G,
    action = function()
      if combate.heridas ~= "" then
        send("vendar " .. combate.heridas)
      else
        lector.decir("No tienes heridas")
      end
    end,
    name = "Alt+Shift+G",
    desc = "Venda heridas"
  },
  {
    modifiers = mudlet.keymodifier.Alt,
    key = mudlet.key.Return,
    action = function()
      local modes = RhomScripts and RhomScripts.modules and RhomScripts.modules.modes
      local mode = modes and modes.get and modes.get().modo_juego or "combate"
      if mode == "xp" then
        send("matar xp")
      else
        send("matar x")
      end
    end,
    name = "Alt+Enter",
    desc = "Ataca objetivo principal"
  },
}

return combate
