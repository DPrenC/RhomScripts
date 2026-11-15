-------------------------------------------------------------------------------
-- Modulo: generales
-- Migracion funcional desde Generales.set.
-------------------------------------------------------------------------------

local audio = require("audio")
local eventos = require("eventos")
local lector = require("lector")

local generales = {}

generales.ultimo_conectado = "Nadie"
generales.ultimo_desconectado = "Nadie"

local function trim(text)
  if type(text) ~= "string" then
    return ""
  end
  return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function first_word(text)
  return trim(text):match("^(%S+)") or trim(text)
end

local function connected_name(text)
  local words = {}
  for word in trim(text):gmatch("%S+") do
    table.insert(words, word)
  end

  if words[2] == "Legendario" or words[2] == "Legendaria" then
    return words[3] or words[1] or "Nadie", true
  end

  return words[1] or "Nadie", false
end

local function play(path)
  audio.play(path, { volume = 80 })
end

local function registrar_xp(texto, cantidad)
  local xp = tonumber(cantidad) or 0
  if xp >= 10000 then
    eventos.registrar(texto)
    play("RL/Generales/XP ganada.wav")
    return
  end
  lector.decir(tostring(xp) .. " XP")
end

generales.triggers = {
  {
    pattern = "^\\[(.+) orbita a Eirea.*\\].*$",
    action = function()
      local nombre, legendario = connected_name(matches[2])
      generales.ultimo_conectado = nombre
      if legendario then
        play("RL/Generales/Orbita l1.wav")
      end
      play("RL/Generales/Orbita 1.wav")
    end,
    name = "orbita_eirea",
    desc = "Detecta conexiones por orbita"
  },
  {
    pattern = "^\\[(.+) orbita al Limbo.*\\].*$",
    action = function()
      local nombre, legendario = connected_name(matches[2])
      generales.ultimo_desconectado = nombre
      if legendario then
        play("RL/Generales/Orbita l2.wav")
      end
      play("RL/Generales/Orbita 2.wav")
    end,
    name = "orbita_limbo",
    desc = "Detecta desconexiones por orbita"
  },
  {
    pattern = "^Una intensa luz desciende hasta la zona y se concentra formando la figura de .+\\.$",
    action = function()
      play("RL/Sucesos/Orbita room.wav")
    end,
    name = "orbita_room",
    desc = "Sonido de entrada en la room"
  },
  {
    pattern = "^Eirea acaba de sufrir el caos, has de esperar almenos 2 minutos para poder entrar\\.$",
    action = function()
      play("RL/Generales/Orbita caos.wav")
    end,
    name = "orbita_caos",
    desc = "Sonido de caos de Eirea"
  },
  {
    pattern = "^\\[(.+) entra en juego en modo tutorial\\]$",
    action = function()
      generales.ultimo_conectado = first_word(matches[2])
      play("RL/Generales/Orbita 1.wav")
    end,
    name = "tutorial_conexion",
    desc = "Detecta entrada en tutorial"
  },
  {
    pattern = "^(.+) ha reconectado\\.$",
    action = function()
      play("RL/Generales/Conexion recuperada.wav")
    end,
    name = "conexion_recuperada",
    desc = "Sonido de conexion recuperada"
  },
  {
    pattern = "^(.+) empieza a brillar y parece perder la conciencia\\.$",
    action = function()
      play("RL/Generales/Conexion perdida.wav")
    end,
    name = "conexion_perdida",
    desc = "Sonido de conexion perdida"
  },
  {
    pattern = "^\\[Obtienes ([0-9]+) puntos de experiencia\\]$",
    action = function()
      registrar_xp(matches[1], matches[2])
    end,
    name = "xp_ganada",
    desc = "Detecta experiencia ganada"
  },
  {
    pattern = "^.*Cola de comandos borrada.*$",
    action = function()
      play("RL/Generales/Parar.wav")
    end,
    name = "cola_borrada",
    desc = "Sonido de cola de comandos borrada"
  },
  {
    pattern = "^.*Ignorando '.+'. No puedes ejecutar mas acciones de ese tipo durante este turno\\.$",
    action = function()
      play("RL/Generales/Turno completo.wav")
    end,
    name = "turno_completo",
    desc = "Sonido de turno completo"
  },
  {
    pattern = "^.*No est.s suficientemente calmad..*$",
    action = function()
      play("RL/Generales/Habilidad no disponible.wav")
    end,
    name = "habilidad_no_disponible",
    desc = "Sonido de habilidad no disponible"
  },
  {
    pattern = "^Est.s concentrad. en otra habilidad y te resulta dificil .*$",
    action = function()
      play("RL/Generales/Habilidad ocupada.wav")
    end,
    name = "habilidad_ocupada",
    desc = "Sonido de habilidad ocupada"
  },
  {
    pattern = "^\\[Tiradas\\].*Tirada: .*\\((.+)\\).*$",
    action = function()
      eventos.registrar(matches[1])
      play("RL/Generales/Tirada dados.wav")
      if matches[2] == "Exito" or matches[2] == "Éxito" then
        play("RL/Generales/Tirada acierto.wav")
      else
        play("RL/Generales/Tirada fallo.wav")
      end
    end,
    name = "tirada_dados",
    desc = "Detecta tiradas de dados"
  },
  {
    pattern = "^.*Te preparas para ejecutar .*$",
    action = function()
      play("RL/Habilidades/Generales/Impulso1.wav")
    end,
    name = "inicio_habilidad",
    desc = "Sonido de inicio de habilidad generica"
  },
  {
    pattern = "^Un disfraz ha caido en el Reino de .+, en la zona conocida como .+\\.$",
    action = function()
      eventos.registrar(matches[1] or line or "")
      play("RL/Generales/Carnaval 1.wav")
    end,
    name = "carnaval_inicio",
    desc = "Detecta evento de carnaval"
  },
  {
    pattern = "^Parece que alguien ha encontrado el disfraz de carnaval\\.$",
    action = function()
      eventos.registrar(matches[1] or line or "")
      play("RL/Generales/Carnaval 2.wav")
    end,
    name = "carnaval_encontrado",
    desc = "Detecta disfraz encontrado"
  },
  {
    pattern = "^Parece que nadie ha encontrado el disfraz de carnaval\\.$",
    action = function()
      eventos.registrar(matches[1] or line or "")
      play("RL/Generales/Carnaval 3.wav")
    end,
    name = "carnaval_no_encontrado",
    desc = "Detecta disfraz no encontrado"
  },
}

generales.key_bindings = {
  {
    modifiers = mudlet.keymodifier.Alt,
    key = mudlet.key["5"],
    action = function()
      lector.decir("Conectado: " .. generales.ultimo_conectado)
    end,
    name = "Alt+5",
    desc = "Lee el ultimo conectado"
  },
  {
    modifiers = mudlet.keymodifier.Shift + mudlet.keymodifier.Alt,
    key = mudlet.key["5"],
    action = function()
      lector.copiar(generales.ultimo_conectado, "Conectado copiado")
    end,
    name = "Shift+Alt+5",
    desc = "Copia el ultimo conectado"
  },
  {
    modifiers = mudlet.keymodifier.Control + mudlet.keymodifier.Alt + mudlet.keymodifier.Shift,
    key = mudlet.key["5"],
    action = function()
      send("diplomacia " .. generales.ultimo_conectado)
    end,
    name = "Ctrl+Alt+Shift+5",
    desc = "Envia diplomacia al ultimo conectado"
  },
  {
    modifiers = mudlet.keymodifier.Alt,
    key = mudlet.key["6"],
    action = function()
      lector.decir("Desconectado: " .. generales.ultimo_desconectado)
    end,
    name = "Alt+6",
    desc = "Lee el ultimo desconectado"
  },
  {
    modifiers = mudlet.keymodifier.Shift + mudlet.keymodifier.Alt,
    key = mudlet.key["6"],
    action = function()
      lector.copiar(generales.ultimo_desconectado, "Desconectado copiado")
    end,
    name = "Shift+Alt+6",
    desc = "Copia el ultimo desconectado"
  },
}

return generales
