-------------------------------------------------------------------------------
-- Modulo: general
-- Migracion funcional desde Alias_Macros.set y parte util de start.set.
-------------------------------------------------------------------------------

local lector = require("lector")

local general = {}

general.version = "RhomScriptsRL 1.0"
general.nickx = {}
general.objetivo = nil

local function trim(text)
  if type(text) ~= "string" then
    return ""
  end
  return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function send_many(commands)
  for _, command in ipairs(commands) do
    send(command)
  end
end

local function clipboard()
  return getClipboardText() or ""
end

local function remitente_actual()
  local comunicaciones = RhomScripts and RhomScripts.modules and RhomScripts.modules.comunicaciones
  if comunicaciones and comunicaciones.telepatia then
    return comunicaciones.telepatia.remitente or ""
  end
  return ""
end

local function nickx_text()
  if #general.nickx == 0 then
    return ""
  end
  return table.concat(general.nickx, ",")
end

function general.configurar_ficha()
  lector.decir("Configurando tu ficha")
  send_many({
    "inform alineamiento on",
    "inform bloqueos on",
    "inform ataques_a_otros on",
    "inform ataques_invocaciones on",
    "inform xp-ganada on",
    "consentir accesibilidad on",
    "consentir detallado off",
    "consentir menus off",
    "consentir gmcp off",
    "consentir mudlet_gui off",
    "consentir MSP off",
    "columnas 180",
    "filas 80",
    "terminal ansi",
    "charset resetear",
    "ojear configurar jugadores linea npcs linea short espacio s_cortas espacio linea objetos",
  })
end

function general.configurar_prompt(tipo)
  local prompts = {
    B = [[prompt $lPv:$v\$V Pe:$g\$G Xp:$x$lSL:$s$lPL:$a$lNM:$k$lLD:$K$l]],
    BM = [[prompt $lPv:$v\$V Pe:$g\$G Xp:$x$lSL:$s$lPL:$a$lNM:$k$lLD:$K$lImagenes:$e$lPieles:$p$l]],
    a = [[prompt $lPv:$v\$V Pe:$g\$G Xp:$x$lSL:$s$lPL:$a$lNM:$b$lLD:$K$l]],
    AM = [[prompt $lPv:$v\$V Pe:$g\$G Xp:$x$lSL:$s$lPL:$a$lNM:$b$lLD:$K$lImagenes:$e$lPieles:$p$l]],
    x = [[prompt $lPv:$v\$V Pe:$g\$G Xp:$x$lSL:$s$lPL:$a$lJgd:$j$l]],
    xm = [[prompt $lPv:$v\$V Pe:$g\$G Xp:$x$lSL:$s$lPL:$a$lJgd:$j$lImagenes:$e$lPieles:$p$l]],
  }

  local prompt = prompts[tipo]
  if not prompt then
    return
  end
  send(prompt)
  send(prompt:gsub("^prompt", "promptcombate"))
end

function general.canales_colores()
  send_many({
    [[alias t telepatia $1$ %^BOLD%^RED%^ $2*$]],
    [[alias ' decir %^BOLD%^RED%^$*$]],
    [[alias ciu ciudadania %^BOLD%^RED%^$*$]],
    [[alias ba bando %^BOLD%^RED%^$*$]],
    [[alias gre gremio %^BOLD%^RED%^$*$]],
    [[alias cla clan %^BOLD%^RED%^$*$]],
    [[alias cha chat %^BOLD%^RED%^$*$]],
    [[alias ro rol %^BOLD%^RED%^$*$]],
    [[alias gru grupo %^BOLD%^RED%^$*$]],
    [[alias int interbando %^BOLD%^RED%^$*$]],
    [[alias co consulta %^BOLD%^RED%^$*$]],
    [[alias av avatar %^BOLD%^RED%^$*$]],
  })
end

function general.reportar(destino, texto)
  local value = trim(texto)
  if value == "" then
    value = clipboard()
  end

  if destino == "decir" then
    send("' " .. value)
  elseif destino == "bando" then
    send("ba " .. value)
  elseif destino == "ciudadania" then
    send("ciu " .. value)
  elseif destino == "chat" then
    send("cha " .. value)
  elseif destino == "gremio" then
    send("gre " .. value)
  elseif destino == "tel_remitente" then
    send("t " .. remitente_actual() .. " " .. value)
  elseif destino == "tel" then
    local nombre, mensaje = value:match("^(%S+)%s+(.+)$")
    if nombre and mensaje then
      send("t " .. nombre .. " " .. mensaje)
    end
  end
end

function general.version_scripts()
  lector.decir(general.version .. ", escritos para Mudlet por Rhomdur.")
end

local function simple_alias(pattern, command, name, desc)
  return {
    pattern = pattern,
    action = function()
      local rest = trim(matches[2] or "")
      if rest ~= "" then
        send(command .. " " .. rest)
      else
        send(command)
      end
    end,
    name = name,
    desc = desc,
  }
end

general.aliases = {
  simple_alias("^oj$", "ojear", "oj", "Ejecuta ojear"),
  simple_alias("^m\\s*(.*)$", "mirar", "m", "Ejecuta mirar"),
  {
    pattern = "^versionscrips$",
    action = function()
      general.version_scripts()
    end,
    name = "versionscrips",
    desc = "Lee la version de RhomScripts"
  },
  {
    pattern = "^configurarficha$",
    action = function()
      general.configurar_ficha()
    end,
    name = "configurarficha",
    desc = "Configura opciones funcionales de la ficha"
  },
  {
    pattern = "^configurarpromptB$",
    action = function()
      general.configurar_prompt("B")
    end,
    name = "configurarpromptB",
    desc = "Configura prompt tipo B"
  },
  {
    pattern = "^configurarpromptBM$",
    action = function()
      general.configurar_prompt("BM")
    end,
    name = "configurarpromptBM",
    desc = "Configura prompt tipo BM"
  },
  {
    pattern = "^configurarprompta$",
    action = function()
      general.configurar_prompt("a")
    end,
    name = "configurarprompta",
    desc = "Configura prompt tipo a"
  },
  {
    pattern = "^configurarpromptAM$",
    action = function()
      general.configurar_prompt("AM")
    end,
    name = "configurarpromptAM",
    desc = "Configura prompt tipo AM"
  },
  {
    pattern = "^configurarpromptx$",
    action = function()
      general.configurar_prompt("x")
    end,
    name = "configurarpromptx",
    desc = "Configura prompt tipo x"
  },
  {
    pattern = "^configurarpromptxm$",
    action = function()
      general.configurar_prompt("xm")
    end,
    name = "configurarpromptxm",
    desc = "Configura prompt tipo xm"
  },
  {
    pattern = "^canalescolores$",
    action = function()
      general.canales_colores()
    end,
    name = "canalescolores",
    desc = "Configura aliases de canales con color"
  },
  {
    pattern = "^repd$",
    action = function()
      general.reportar("decir")
    end,
    name = "repd",
    desc = "Reporta portapapeles por decir"
  },
  {
    pattern = "^repb$",
    action = function()
      general.reportar("bando")
    end,
    name = "repb",
    desc = "Reporta portapapeles por bando"
  },
  {
    pattern = "^repr$",
    action = function()
      general.reportar("tel_remitente")
    end,
    name = "repr",
    desc = "Reporta portapapeles al ultimo remitente"
  },
  {
    pattern = "^rept\\s+(.+)$",
    action = function()
      send("t " .. trim(matches[2]) .. " " .. clipboard())
    end,
    name = "rept",
    desc = "Reporta portapapeles a un jugador"
  },
  {
    pattern = "^repc$",
    action = function()
      general.reportar("ciudadania")
    end,
    name = "repc",
    desc = "Reporta portapapeles por ciudadania"
  },
  {
    pattern = "^repch$",
    action = function()
      general.reportar("chat")
    end,
    name = "repch",
    desc = "Reporta portapapeles por chat"
  },
  {
    pattern = "^repdx$",
    action = function()
      general.reportar("decir", nickx_text())
    end,
    name = "repdx",
    desc = "Reporta NickX por decir"
  },
  {
    pattern = "^repcx$",
    action = function()
      general.reportar("ciudadania", nickx_text())
    end,
    name = "repcx",
    desc = "Reporta NickX por ciudadania"
  },
  {
    pattern = "^repbx$",
    action = function()
      general.reportar("bando", nickx_text())
    end,
    name = "repbx",
    desc = "Reporta NickX por bando"
  },
  {
    pattern = "^repgx$",
    action = function()
      general.reportar("gremio", nickx_text())
    end,
    name = "repgx",
    desc = "Reporta NickX por gremio"
  },
  {
    pattern = "^reprx$",
    action = function()
      general.reportar("tel_remitente", nickx_text())
    end,
    name = "reprx",
    desc = "Reporta NickX al ultimo remitente"
  },
  {
    pattern = "^reptx\\s+(.+)$",
    action = function()
      send("t " .. trim(matches[2]) .. " " .. nickx_text())
    end,
    name = "reptx",
    desc = "Reporta NickX a un jugador"
  },
}

local function key(modifiers, key_code, command, name, desc)
  return {
    modifiers = modifiers,
    key = key_code,
    action = function()
      send(command)
    end,
    name = name,
    desc = desc,
  }
end

general.key_bindings = {
  {
    modifiers = mudlet.keymodifier.Control,
    key = mudlet.key.O,
    action = function()
      if general.objetivo and general.objetivo ~= "" then
        send("seguir " .. general.objetivo)
      else
        lector.decir("No hay objetivo seleccionado")
      end
    end,
    name = "Ctrl+O",
    desc = "Seguir objetivo"
  },
  key(mudlet.keymodifier.Control, mudlet.key.M, "mano", "Ctrl+M", "Ejecuta mano"),
  key(mudlet.keymodifier.Control, mudlet.key.P, "perder todo", "Ctrl+P", "Ejecuta perder todo"),
  key(mudlet.keymodifier.Alt, mudlet.key.B, "buscar", "Alt+B", "Ejecuta buscar"),
  key(mudlet.keymodifier.Control, mudlet.key.A, "agacharse", "Ctrl+A", "Ejecuta agacharse"),
  key(mudlet.keymodifier.Control, mudlet.key.L, "levantarse", "Ctrl+L", "Ejecuta levantarse"),
  key(mudlet.keymodifier.Control, mudlet.key.I, "enterrar cuerpos", "Ctrl+I", "Entierra cuerpos"),
  key(mudlet.keymodifier.Control, mudlet.key.U, "estado -b x", "Ctrl+U", "Estado breve de objetivo"),
  key(mudlet.keymodifier.Control, mudlet.key.J, "estado -b todo", "Ctrl+J", "Estado breve completo"),
  key(mudlet.keymodifier.Alt, mudlet.key.H, "m1", "Alt+H", "Macro m1"),
  key(mudlet.keymodifier.Alt, mudlet.key.N, "m2", "Alt+N", "Macro m2"),
  key(mudlet.keymodifier.Alt, mudlet.key.Y, "m3", "Alt+Y", "Macro m3"),
  key(mudlet.keymodifier.Alt + mudlet.keymodifier.Control, mudlet.key.H, "m4", "Alt+Ctrl+H", "Macro m4"),
  key(mudlet.keymodifier.Alt + mudlet.keymodifier.Control, mudlet.key.N, "m5", "Alt+Ctrl+N", "Macro m5"),
  key(mudlet.keymodifier.Alt + mudlet.keymodifier.Control, mudlet.key.Y, "m6", "Alt+Ctrl+Y", "Macro m6"),
  key(mudlet.keymodifier.Shift + mudlet.keymodifier.Control + mudlet.keymodifier.Alt, mudlet.key.H, "m7", "Shift+Ctrl+Alt+H", "Macro m7"),
  key(mudlet.keymodifier.Shift + mudlet.keymodifier.Control + mudlet.keymodifier.Alt, mudlet.key.N, "m8", "Shift+Ctrl+Alt+N", "Macro m8"),
  key(mudlet.keymodifier.Shift + mudlet.keymodifier.Control + mudlet.keymodifier.Alt, mudlet.key.Y, "m9", "Shift+Ctrl+Alt+Y", "Macro m9"),
}

return general
