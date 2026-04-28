-------------------------------------------------------------------------------
-- Modulo: comunicaciones
-- Migracion funcional desde Comunicaciones.set.
--
-- Centraliza telepatias, conversaciones de room y canales. Los historiales se
-- publican como listas navegables para que el mismo sistema sirva despues a
-- tiendas, eventos y otros dominios.
-------------------------------------------------------------------------------

local audio = require("audio")
local lector = require("lector")
local listas = require("listas")

local comunicaciones = {}

local canales = {
  { id = "general", nombre = "Historial general", silencio = false, ultimo = "No hay mensajes en ningun canal" },
  { id = "bando", nombre = "Historial bando", silencio = false, ultimo = "No hay mensajes en el canal bando" },
  { id = "ciudadania", nombre = "Historial ciudadania", silencio = false, ultimo = "No hay mensajes en el canal ciudadania" },
  { id = "chat", nombre = "Historial chat", silencio = false, ultimo = "No hay mensajes en el canal chat" },
  { id = "gremio", nombre = "Historial gremio", silencio = false, ultimo = "No hay mensajes en el canal gremio" },
  { id = "familia", nombre = "Historial familia", silencio = false, ultimo = "No hay mensajes en el canal familiar" },
  { id = "rol", nombre = "Historial rol", silencio = false, ultimo = "No hay mensajes en el canal rol" },
  { id = "varios", nombre = "Historial varios", silencio = false, ultimo = "No hay mensajes en canales variados" },
  { id = "especiales", nombre = "Historial especiales", silencio = false, ultimo = "No hay mensajes de canales especiales" },
}

local canal_por_id = {}
for index, canal in ipairs(canales) do
  canal.index = index
  canal.historial = {}
  canal_por_id[canal.id] = canal
end

comunicaciones.seleccion = 1
comunicaciones.telepatia = {
  historial = {},
  remitentes = {},
  remitente = nil,
  ultimo = "No hay mensajes de telepatia",
  silencio = false,
}
comunicaciones.room = {
  historial = {},
  ultimo = "No hay mensajes en la room",
  silencio = false,
}

local bandos = {
  Bueno = true,
  Malo = true,
  Mercenario = true,
  Anarquico = true,
  Renegado = true,
  Malvados = true,
  Solitarios = true,
}

local ciudadanias = {
  Kheleb = true,
  Kattak = true,
  ["Ak'anon"] = true,
  Anduar = true,
  Veleiron = true,
  Grimoszk = true,
  Takome = true,
  Thorin = true,
  Poldarn = true,
  Eloras = true,
  Eldor = true,
  ["Ar'kaindia"] = true,
  Dendra = true,
  Mor_groddur = true,
  Golthur = true,
  Ancarak = true,
  Keel = true,
}

local gremios = {
  Alianza = true,
  Horda_negra = true,
  Cruzada_eralie = true,
  Ej_dendra = true,
  Dhara = true,
  Inquisicion = true,
  Guante_blanco = true,
  las_garzas = true,
  colmillos_venenosos = true,
  viuda_negra = true,
  custodios_del_eter = true,
  sombras_del_baltia = true,
  ["sello_carmesi"] = true,
}

local familias = {
  Girlhim = true,
  Ethengard = true,
  Throril = true,
  Gutjjakar = true,
}

local sonidos = {
  telepatia = "RL/Comunicaciones/telepatia.wav",
  room = "RL/Comunicaciones/Room.wav",
  room_enviada = "RL/Comunicaciones/Room e.wav",
  telepatia_enviada = "RL/Comunicaciones/Telepatia e.wav",
  mencion = "RL/Comunicaciones/Mencion.wav",
  bando = "RL/Comunicaciones/Bando.wav",
  interbando = "RL/Comunicaciones/Interbando.wav",
  ciudadania = "RL/Comunicaciones/Ciudadania.wav",
  chat = "RL/Comunicaciones/Chat.wav",
  gremio = "RL/Comunicaciones/Gremio.wav",
  familia = "RL/Comunicaciones/Clan.wav",
  rol = "RL/Comunicaciones/Rol.wav",
  grupo = "RL/Comunicaciones/Grupo.wav",
  novato = "RL/Comunicaciones/Novato.wav",
  consulta = "RL/Comunicaciones/Consulta.wav",
  trivial = "RL/Comunicaciones/Trivial.wav",
  taberna = "RL/Comunicaciones/Taberna.wav",
  avatar = "RL/Comunicaciones/Avatar.wav",
  creadores = "RL/Comunicaciones/Creadores.wav",
  gritar = "RL/Comunicaciones/Gritar.wav",
  info = "RL/Comunicaciones/Info.wav",
  diplomacia = "RL/Comunicaciones/Diplomacia.wav",
  canal_on = "RL/Comunicaciones/Canal on.wav",
  canal_off = "RL/Comunicaciones/Canal off.wav",
  muteado = "RL/Comunicaciones/Canal muteado.wav",
  desmuteado = "RL/Comunicaciones/Canal desmuteado.wav",
  seleccion = "RL/Comunicaciones/Seleccion canal.wav",
  seleccion_defecto = "RL/Comunicaciones/Seleccion canal defecto.wav",
  mail = "RL/Comunicaciones/Mail.wav",
  noticias = "RL/Comunicaciones/Noticias.wav",
  asunto = "RL/Comunicaciones/Asunto.wav",
  infiel = "RL/Comunicaciones/Infiel.wav",
  conexion_perdida = "RL/Comunicaciones/Conexion perdida.wav",
  omiq1 = "RL/Comunicaciones/Omiq 1.wav",
  omiq2 = "RL/Comunicaciones/Omiq 2.wav",
}

local function trim(text)
  if type(text) ~= "string" then
    return ""
  end
  return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function speak(text)
  lector.decir(text)
end

local function push(history, text)
  table.insert(history, 1, text)
  while #history > 99 do
    table.remove(history)
  end
end

local function play(path)
  audio.play(path, { volume = 80 })
end

local function copy_action(text)
  return function()
    lector.copiar(text, "Mensaje copiado")
  end
end

local function mostrar_historial(nombre, history)
  if #history == 0 then
    speak(nombre .. " vacio")
    return
  end

  listas.nueva(nombre)
  for index = #history, 1, -1 do
    listas.agregar(nombre, history[index], copy_action(history[index]))
  end
  listas.leer_actual()
end

local function canal_actual()
  return canales[comunicaciones.seleccion] or canales[1]
end

local function canal_desde_nombre(nombre)
  local limpio = trim(nombre):gsub("%s+", "_")

  if bandos[limpio] then
    local sonido = sonidos.bando
    if limpio == "Malvados" or limpio == "Solitarios" then
      sonido = sonidos.interbando
    end
    return canal_por_id.bando, sonido
  end
  if ciudadanias[limpio] then
    return canal_por_id.ciudadania, sonidos.ciudadania
  end
  if gremios[limpio] then
    return canal_por_id.gremio, sonidos.gremio
  end
  if familias[limpio] then
    return canal_por_id.familia, sonidos.familia
  end
  if limpio == "Chat" then
    return canal_por_id.chat, sonidos.chat
  end
  if limpio == "Rol" then
    return canal_por_id.rol, sonidos.rol
  end
  if limpio == "Novato" then
    return canal_por_id.varios, sonidos.novato
  end
  if limpio == "Consulta" or limpio == "Consulta." then
    return canal_por_id.varios, sonidos.consulta
  end
  if limpio == "Trivial" then
    return canal_por_id.varios, sonidos.trivial
  end
  if limpio == "Taberna" then
    return canal_por_id.varios, sonidos.taberna
  end
  if limpio == "Avatar" then
    return canal_por_id.varios, sonidos.avatar
  end
  if limpio == "Cre" then
    return canal_por_id.varios, sonidos.creadores
  end

  return canal_por_id.especiales, sonidos.info
end

function comunicaciones.agregar_canal(id, texto, sonido)
  local canal = canal_por_id[id] or canal_por_id.especiales
  local mensaje = trim(texto)
  if mensaje == "" then
    return
  end

  canal.ultimo = mensaje
  push(canal.historial, mensaje)

  if id ~= "general" then
    local general = canal_por_id.general
    general.ultimo = mensaje
    push(general.historial, mensaje)
  end

  if not canal.silencio then
    speak(mensaje)
  end
  if sonido then
    play(sonido)
  end
end

function comunicaciones.telepatia_entrante(remitente, verbo, mensaje)
  local nombre = trim(remitente)
  local texto = string.format("%s. %s %s", nombre, trim(verbo), trim(mensaje))

  comunicaciones.telepatia.remitente = nombre
  comunicaciones.telepatia.ultimo = texto
  comunicaciones.telepatia.remitentes[nombre] = true
  push(comunicaciones.telepatia.historial, texto)

  if not comunicaciones.telepatia.silencio then
    speak(texto)
  end
  play(sonidos.telepatia)
end

function comunicaciones.room_entrante(texto)
  local mensaje = trim(texto)
  if mensaje == "" then
    return
  end

  comunicaciones.room.ultimo = mensaje
  push(comunicaciones.room.historial, mensaje)

  if not comunicaciones.room.silencio then
    speak(mensaje)
  end
  play(sonidos.room)
end

function comunicaciones.canal_entrante(nombre, texto)
  local canal, sonido = canal_desde_nombre(nombre)
  local mensaje = "[" .. trim(nombre) .. "] " .. trim(texto)
  comunicaciones.agregar_canal(canal.id, mensaje, sonido)
end

function comunicaciones.especial(texto, sonido)
  comunicaciones.agregar_canal("especiales", trim(texto), sonido or sonidos.info)
end

function comunicaciones.seleccionar(delta)
  comunicaciones.seleccion = comunicaciones.seleccion + delta
  if comunicaciones.seleccion < 1 then
    comunicaciones.seleccion = #canales
  elseif comunicaciones.seleccion > #canales then
    comunicaciones.seleccion = 1
  end

  local canal = canal_actual()
  speak(canal.nombre)
  play(canal.id == "general" and sonidos.seleccion_defecto or sonidos.seleccion)
end

function comunicaciones.toggle_canal_actual()
  local canal = canal_actual()

  if canal.id == "general" then
    local alguno_silenciado = false
    for _, item in ipairs(canales) do
      if item.id ~= "general" and item.silencio then
        alguno_silenciado = true
        break
      end
    end

    local nuevo_estado = not alguno_silenciado
    for _, item in ipairs(canales) do
      item.silencio = nuevo_estado
    end
    speak(nuevo_estado and "Todos los canales silenciados" or "Todos los canales activados")
    play(nuevo_estado and sonidos.muteado or sonidos.desmuteado)
    return
  end

  canal.silencio = not canal.silencio
  speak(canal.nombre .. (canal.silencio and " silenciado" or " activado"))
  play(canal.silencio and sonidos.muteado or sonidos.desmuteado)
end

function comunicaciones.toggle_telepatia()
  local data = comunicaciones.telepatia
  data.silencio = not data.silencio
  speak(data.silencio and "Lectura de tels desactivada" or "Lectura de tels activada")
  play(data.silencio and sonidos.muteado or sonidos.desmuteado)
end

function comunicaciones.toggle_room()
  local data = comunicaciones.room
  data.silencio = not data.silencio
  speak(data.silencio and "Lectura de room desactivada" or "Lectura de room activada")
  play(data.silencio and sonidos.muteado or sonidos.desmuteado)
end

function comunicaciones.responder(texto)
  local remitente = comunicaciones.telepatia.remitente
  if not remitente or remitente == "" then
    speak("Nadie te ha enviado mensajes de telepatia por el momento")
    return
  end
  send("t " .. remitente .. " " .. trim(texto))
end

function comunicaciones.mostrar_remitentes()
  local hay = false
  listas.nueva("Remitentes de telepatia")
  for remitente, _ in pairs(comunicaciones.telepatia.remitentes) do
    hay = true
    listas.agregar("Remitentes de telepatia", remitente, function()
      comunicaciones.telepatia.remitente = remitente
      speak("Telepatia con " .. remitente)
    end)
  end
  if hay then
    listas.leer_actual()
  else
    speak("Nadie te ha enviado mensajes de telepatia por el momento")
  end
end

function comunicaciones.leer_remitente()
  local remitente = comunicaciones.telepatia.remitente
  if remitente and remitente ~= "" then
    speak("Telepatia con " .. remitente)
  else
    speak("Nadie te ha enviado mensajes de telepatia por el momento")
  end
end

function comunicaciones.mostrar_historial_telepatia()
  mostrar_historial("Historial de telepatia", comunicaciones.telepatia.historial)
end

function comunicaciones.mostrar_historial_room()
  mostrar_historial("Historial de room", comunicaciones.room.historial)
end

function comunicaciones.mostrar_historial_canal()
  local canal = canal_actual()
  mostrar_historial(canal.nombre, canal.historial)
end

function comunicaciones.leer_ultimo_canal()
  speak(canal_actual().ultimo)
end

comunicaciones.aliases = {
  {
    pattern = "^r\\s*(.*)$",
    action = function()
      comunicaciones.responder(matches[2] or "")
    end,
    name = "r",
    desc = "Responde al ultimo remitente de telepatia"
  }
}

comunicaciones.triggers = {
  {
    pattern = "^(.+) te dice: (.+)$",
    action = function()
      comunicaciones.telepatia_entrante(matches[2], "te dice.", matches[3])
    end,
    name = "tel_dice",
    desc = "Captura telepatia entrante"
  },
  {
    pattern = "^(.+) te exclama: (.+)$",
    action = function()
      comunicaciones.telepatia_entrante(matches[2], "te exclama.", matches[3])
    end,
    name = "tel_exclama",
    desc = "Captura telepatia entrante"
  },
  {
    pattern = "^(.+) te pregunta: (.+)$",
    action = function()
      comunicaciones.telepatia_entrante(matches[2], "te pregunta.", matches[3])
    end,
    name = "tel_pregunta",
    desc = "Captura telepatia entrante"
  },
  {
    pattern = "^.* - (.+) te dijo: (.+)$",
    action = function()
      comunicaciones.telepatia_entrante(matches[2], "te dijo.", matches[3])
    end,
    name = "tel_pasado",
    desc = "Captura telepatia historica"
  },
  {
    pattern = "^(.+) (pregunta|exclama|dice|balbucea|ordena|responde).*: (.+)$",
    action = function()
      comunicaciones.room_entrante(matches[2] .. " " .. matches[3] .. ": " .. matches[4])
    end,
    name = "room_habla",
    desc = "Captura conversaciones en la room"
  },
  {
    pattern = "^(.+) te susurra: (.+)$",
    action = function()
      comunicaciones.room_entrante(matches[2] .. " te susurra: " .. matches[3])
    end,
    name = "room_susurro",
    desc = "Captura susurros en la room"
  },
  {
    pattern = "^Oyes una voz (.+) de (.+) decir: (.+)$",
    action = function()
      comunicaciones.room_entrante("Voz " .. matches[2] .. " de " .. matches[3] .. ": " .. matches[4])
    end,
    name = "room_voz",
    desc = "Captura voces anonimas"
  },
  {
    pattern = "^\\[(.+)\\]\\s+(.+)$",
    action = function()
      comunicaciones.canal_entrante(matches[2], matches[3])
    end,
    name = "canal_generico",
    desc = "Captura canales entre corchetes"
  },
  {
    pattern = "^(.+) grita.*: (.+)$",
    action = function()
      comunicaciones.especial(matches[2] .. " grita: " .. matches[3], sonidos.gritar)
    end,
    name = "canal_grito",
    desc = "Captura gritos"
  },
  {
    pattern = "^.*\\[Info.*\\].*$",
    action = function()
      comunicaciones.especial(matches[1] or line or "", sonidos.info)
    end,
    name = "canal_info",
    desc = "Captura informacion especial"
  },
  {
    pattern = "^\\[Diplomacia\\]: (.+)$",
    action = function()
      comunicaciones.especial("[Diplomacia]: " .. matches[2], sonidos.diplomacia)
    end,
    name = "canal_diplomacia",
    desc = "Captura diplomacia"
  },
  {
    pattern = "^Ok, activas el canal-.+\\.$",
    action = function()
      play(sonidos.canal_on)
    end,
    name = "canal_on",
    desc = "Sonido al activar canal"
  },
  {
    pattern = "^Ok, apagas el canal-.+\\.$",
    action = function()
      play(sonidos.canal_off)
    end,
    name = "canal_off",
    desc = "Sonido al apagar canal"
  },
  {
    pattern = "^Pierdes conexion con el canal .+\\.$",
    action = function()
      play(sonidos.conexion_perdida)
    end,
    name = "canal_conexion_perdida",
    desc = "Sonido de perdida de canal"
  },
  {
    pattern = "^(Dices|Preguntas|Exclamas)\\s+(.+): (.+)$",
    action = function()
      local destino = matches[3] or ""
      if destino:match("^a%s+") then
        play(sonidos.telepatia_enviada)
      else
        play(sonidos.room_enviada)
      end
    end,
    name = "comunicacion_enviada",
    desc = "Sonido para comunicaciones enviadas"
  },
  {
    pattern = "^.*Nuevo correo de .*$",
    action = function()
      comunicaciones.especial(matches[1] or line or "", sonidos.mail)
    end,
    name = "mail_nuevo",
    desc = "Detecta correo nuevo"
  },
  {
    pattern = "^- Tienes .* correo.* sin leer\\..*$",
    action = function()
      comunicaciones.especial(matches[1] or line or "", sonidos.mail)
    end,
    name = "mail_pendiente",
    desc = "Detecta correos pendientes"
  },
  {
    pattern = "^- Tienes .* noticia.* sin leer\\..*$",
    action = function()
      comunicaciones.especial(matches[1] or line or "", sonidos.noticias)
    end,
    name = "noticia_pendiente",
    desc = "Detecta noticias pendientes"
  },
  {
    pattern = "^Asunto: .+$",
    action = function()
      play(sonidos.asunto)
    end,
    name = "mail_asunto",
    desc = "Sonido de asunto"
  },
}

comunicaciones.key_bindings = {
  {
    modifiers = mudlet.keymodifier.Shift,
    key = mudlet.key.F3,
    action = function()
      comunicaciones.mostrar_historial_telepatia()
    end,
    name = "Shift+F3",
    desc = "Muestra historial de telepatia"
  },
  {
    modifiers = mudlet.keymodifier.Alt,
    key = mudlet.key.F3,
    action = function()
      speak(comunicaciones.telepatia.ultimo)
    end,
    name = "Alt+F3",
    desc = "Lee el ultimo tel"
  },
  {
    modifiers = mudlet.keymodifier.Control,
    key = mudlet.key.F3,
    action = function()
      comunicaciones.toggle_telepatia()
    end,
    name = "Ctrl+F3",
    desc = "Activa o desactiva lectura de tels"
  },
  {
    modifiers = mudlet.keymodifier.Alt,
    key = mudlet.key.T,
    action = function()
      comunicaciones.leer_remitente()
    end,
    name = "Alt+T",
    desc = "Lee el remitente del ultimo tel"
  },
  {
    modifiers = mudlet.keymodifier.Control,
    key = mudlet.key.T,
    action = function()
      comunicaciones.mostrar_remitentes()
    end,
    name = "Ctrl+T",
    desc = "Muestra remitentes recientes"
  },
  {
    modifiers = mudlet.keymodifier.Shift,
    key = mudlet.key.F2,
    action = function()
      comunicaciones.mostrar_historial_room()
    end,
    name = "Shift+F2",
    desc = "Muestra historial de room"
  },
  {
    modifiers = mudlet.keymodifier.Alt,
    key = mudlet.key.F2,
    action = function()
      speak(comunicaciones.room.ultimo)
    end,
    name = "Alt+F2",
    desc = "Lee el ultimo mensaje de room"
  },
  {
    modifiers = mudlet.keymodifier.Control,
    key = mudlet.key.F2,
    action = function()
      comunicaciones.toggle_room()
    end,
    name = "Ctrl+F2",
    desc = "Activa o desactiva lectura de room"
  },
  {
    modifiers = mudlet.keymodifier.Shift,
    key = mudlet.key.F1,
    action = function()
      comunicaciones.mostrar_historial_canal()
    end,
    name = "Shift+F1",
    desc = "Muestra historial del canal seleccionado"
  },
  {
    modifiers = mudlet.keymodifier.Alt,
    key = mudlet.key.F1,
    action = function()
      comunicaciones.leer_ultimo_canal()
    end,
    name = "Alt+F1",
    desc = "Lee el ultimo mensaje del canal seleccionado"
  },
  {
    modifiers = mudlet.keymodifier.Control,
    key = mudlet.key.F1,
    action = function()
      comunicaciones.toggle_canal_actual()
    end,
    name = "Ctrl+F1",
    desc = "Silencia o activa el canal seleccionado"
  },
  {
    modifiers = mudlet.keymodifier.Control,
    key = mudlet.key.Period,
    action = function()
      comunicaciones.seleccionar(1)
    end,
    name = "Ctrl+.",
    desc = "Selecciona el siguiente canal"
  },
  {
    modifiers = mudlet.keymodifier.Control,
    key = mudlet.key.Comma,
    action = function()
      comunicaciones.seleccionar(-1)
    end,
    name = "Ctrl+,",
    desc = "Selecciona el canal anterior"
  },
}

return comunicaciones
