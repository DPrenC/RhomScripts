-------------------------------------------------------------------------------
-- Modulo: movimiento
-- Migracion funcional desde Movimiento_keys.set y Movimiento_propio.set.
-------------------------------------------------------------------------------

local audio = require("audio")
local config = require("config")
local corrector = require("corrector")
local lector = require("lector")
local listas = require("listas")

local movimiento = {}

movimiento.direccion = nil
movimiento.direccion_retorno = "El Limbo"
movimiento.localizacion = ""
movimiento.salidas_especiales = ""
movimiento.salidas_especiales_lista = {}
movimiento.ultimo_movimiento_a = ""
movimiento.ultimo_movimiento_e = ""
movimiento.historial_a = {}
movimiento.historial_e = {}
movimiento.objetivo_se_va = ""
movimiento.objetivo_llega = ""
movimiento.presentes = {}
movimiento.presentes_enemigos = {}

local opuestas = {
  n = "s",
  s = "n",
  e = "o",
  o = "e",
  ne = "so",
  no = "se",
  se = "no",
  so = "ne",
  ar = "ab",
  ab = "ar",
  de = "fu",
  fu = "de",
}

local key_names = {
  ["8"] = mudlet.key["8"],
  ["9"] = mudlet.key["9"],
  ["7"] = mudlet.key["7"],
  k = mudlet.key.K,
  o = mudlet.key.O,
  u = mudlet.key.U,
  l = mudlet.key.L,
  j = mudlet.key.J,
  i = mudlet.key.I,
  m = mudlet.key.M,
  comma = mudlet.key.Comma,
  period = mudlet.key.Period,
}

local function mudlet_key(...)
  for index = 1, select("#", ...) do
    local name = select(index, ...)
    if mudlet.key[name] then
      return mudlet.key[name]
    end
  end
  return nil
end

local unpack_list = rawget(table, "unpack") or unpack

local direcciones_primarias = {
  { "8", "n" },
  { "k", "s" },
  { "o", "e" },
  { "u", "o" },
  { "9", "ne" },
  { "7", "no" },
  { "l", "se" },
  { "j", "so" },
  { "i", "ar" },
  { "m", "ab" },
  { "comma", "de" },
  { "period", "fu" },
}

local direcciones_numpad = {
  { { "Num8", "Numpad8", "Keypad8" }, "n", "Numpad8" },
  { { "Num2", "Numpad2", "Keypad2" }, "s", "Numpad2" },
  { { "Num6", "Numpad6", "Keypad6" }, "e", "Numpad6" },
  { { "Num4", "Numpad4", "Keypad4" }, "o", "Numpad4" },
  { { "Num9", "Numpad9", "Keypad9" }, "ne", "Numpad9" },
  { { "Num7", "Numpad7", "Keypad7" }, "no", "Numpad7" },
  { { "Num3", "Numpad3", "Keypad3" }, "se", "Numpad3" },
  { { "Num1", "Numpad1", "Keypad1" }, "so", "Numpad1" },
  { { "Num5", "Numpad5", "Keypad5" }, "ar", "Numpad5" },
  { { "Num0", "Numpad0", "Keypad0" }, "ab", "Numpad0" },
  { { "NumPeriod", "NumpadPeriod", "KeypadPeriod", "NumDecimal" }, "de", "Numpad." },
  { { "NumPlus", "NumpadPlus", "KeypadPlus" }, "fu", "Numpad+" },
}

local function trim(text)
  if type(text) ~= "string" then
    return ""
  end
  return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function play(path)
  audio.play(path, { volume = 80 })
end

local function normalizar(text)
  return trim(text):lower()
end

local function acortar_direccion(text)
  local value = normalizar(text):gsub("^el%s+", ""):gsub("^la%s+", "")
  local mapa = {
    norte = "n",
    sur = "s",
    este = "e",
    oeste = "o",
    noreste = "ne",
    noroeste = "no",
    sudeste = "se",
    sureste = "se",
    sudoeste = "so",
    suroeste = "so",
    arriba = "ar",
    abajo = "ab",
    dentro = "de",
    fuera = "fu",
  }
  return mapa[value] or value
end

local function split_players(text)
  local limpio = corrector.players(text or ""):gsub("%s+y%s+", "|"):gsub(",%s*", "|")
  local result = {}
  for item in limpio:gmatch("[^|]+") do
    local value = trim(item)
    if value ~= "" then
      table.insert(result, value)
    end
  end
  return result
end

local function objetivo_actual()
  local nicks = RhomScripts and RhomScripts.modules and RhomScripts.modules.nicks
  return nicks and nicks.objetivo or ""
end

local function es_grupo(name)
  local grupos = RhomScripts and RhomScripts.modules and RhomScripts.modules.grupos
  return grupos and grupos.es_miembro and grupos.es_miembro(name)
end

local function es_enemigo(name)
  local value = normalizar(name)
  if value == "" or es_grupo(value) then
    return false
  end
  local stats = RhomScripts and RhomScripts.modules and RhomScripts.modules.stats
  local enemigos = stats and stats.ultimo_enemigo and stats.ultimo_enemigo:lower() or ""
  return enemigos:find(value, 1, true) ~= nil
end

local function sonido_sujeto(name, aliado, enemigo)
  if es_enemigo(name) then
    audio.play(enemigo, { volume = 80, pan = -4500 })
  else
    audio.play(aliado, { volume = 80, pan = 4500 })
  end
end

local function salida_valida(direccion)
  local stats = RhomScripts and RhomScripts.modules and RhomScripts.modules.stats
  if not stats or not stats.salidas_lista then
    return true
  end
  if stats.salidas == "No ves nada" or stats.salidas == "Todas" then
    return true
  end
  for _, salida in ipairs(stats.salidas_lista) do
    if salida == direccion then
      return true
    end
  end
  for _, salida in ipairs(movimiento.salidas_especiales_lista) do
    if salida == direccion then
      return true
    end
  end
  return false
end

function movimiento.actualizar_retorno()
  movimiento.direccion_retorno = opuestas[movimiento.direccion] or movimiento.direccion_retorno
end

function movimiento.mover(direccion, secundario)
  local dir = trim(direccion)
  if dir == "" then
    return
  end

  movimiento.direccion = dir
  movimiento.actualizar_retorno()

  if not secundario and config.get("filtro_salidas") and not salida_valida(dir) then
    play("RL/Movimiento/Direccion erronea.wav")
    return
  end

  if secundario then
    if config.get("montado") then
      send("galopar " .. dir)
    elseif config.get("modo_marinero") then
      send(dir)
      config.set("modo_marinero", false)
    else
      play("RL/Generales/Tecla bloqueada.wav")
    end
    return
  end

  if movimiento.localizacion:find("Arbol: Entre las ramas", 1, true) then
    send("saltar " .. dir)
  elseif movimiento.localizacion:find("Fondo Marino", 1, true) or movimiento.localizacion:find("Bajo el Oceano", 1, true) then
    send("nadar " .. dir)
  elseif config.get("modo_sigilar") then
    send("sigilar " .. dir)
  else
    send(dir)
  end
end

function movimiento.llegada_room(titulo, salidas)
  movimiento.localizacion = trim(titulo)
  local stats = RhomScripts and RhomScripts.modules and RhomScripts.modules.stats
  if stats and salidas then
    stats.actualizar_salidas(salidas)
  end

  local oceano = RhomScripts and RhomScripts.modules and RhomScripts.modules.oceano
  if oceano and oceano.control_room then
    oceano.control_room(movimiento.localizacion)
  end

  movimiento.actualizar_retorno()
  play(config.get("montado") and "RL/Monturas/Movimiento*4.wav" or "RL/Movimiento/Movimiento.wav")

  local listas_mod = RhomScripts and RhomScripts.modules and RhomScripts.modules.listas
  if listas_mod then
    listas_mod.limpiar("Tienda")
    listas_mod.limpiar("Baul")
    listas_mod.limpiar("Embarcaciones")
  end
end

function movimiento.registrar_movimiento(tipo, texto, enemigo)
  local history = enemigo and movimiento.historial_e or movimiento.historial_a
  table.insert(history, 1, texto)
  while #history > 10 do
    table.remove(history)
  end
  if enemigo then
    movimiento.ultimo_movimiento_e = texto
  else
    movimiento.ultimo_movimiento_a = texto
  end
end

function movimiento.registrar_presencia(texto)
  movimiento.presentes = split_players(texto)
  movimiento.presentes_enemigos = {}

  local stats = RhomScripts and RhomScripts.modules and RhomScripts.modules.stats
  local objetivo = normalizar(objetivo_actual())

  for _, nombre in ipairs(movimiento.presentes) do
    if es_enemigo(nombre) then
      table.insert(movimiento.presentes_enemigos, nombre)
    end
    if objetivo ~= "" and normalizar(nombre) == objetivo then
      audio.play("RL/Movimiento/Objetivo aqui.wav", { volume = 85, key = "rhom:objetivo:aqui" })
    end
  end

  if stats and #movimiento.presentes_enemigos > 0 then
    stats.ultimo_enemigo = table.concat(movimiento.presentes_enemigos, ", ")
    audio.play("RL/Generales/Enemigo.wav", { volume = 80, key = "rhom:enemigo:room" })
  end
end

function movimiento.registrar_movimiento_otro(nombre, direccion, entrada, texto, tipo, extra)
  local sujeto = trim(nombre)
  local dir = acortar_direccion(direccion)
  local enemigo = es_enemigo(sujeto)
  local objetivo = normalizar(objetivo_actual())
  local frase

  if entrada then
    frase = string.format("%s. %s%s llega %s", dir, sujeto, extra and (" (" .. extra .. ")") or "", tipo or "")
    if normalizar(sujeto) == objetivo then
      movimiento.objetivo_llega = dir
      movimiento.objetivo_se_va = ""
      audio.play("RL/Movimiento/Objetivo llega.wav", { volume = 85 })
    end
  else
    frase = string.format("%s. %s%s se va %s", dir, sujeto, extra and (" (" .. extra .. ")") or "", tipo or "")
    if normalizar(sujeto) == objetivo then
      movimiento.objetivo_se_va = dir
      movimiento.objetivo_llega = ""
      audio.play("RL/Movimiento/Objetivo se va.wav", { volume = 85 })
    end
  end

  movimiento.registrar_movimiento(entrada and "entrada" or "salida", trim(frase), enemigo)

  local modes = RhomScripts and RhomScripts.modules and RhomScripts.modules.modes
  if modes and modes.get_flag and modes.get_flag("experto") then
    lector.decir(trim(frase))
  elseif dir == "" or dir:find("%s") then
    lector.decir(texto)
    audio.play("RL/Movimiento/Se va desconocido.wav", { volume = 80 })
  end
end

local function mostrar_historial(nombre, history)
  if #history == 0 then
    lector.decir(nombre .. " vacio")
    return
  end
  listas.nueva(nombre)
  for index = #history, 1, -1 do
    local value = history[index]
    listas.agregar(nombre, value, function()
      lector.copiar(value, "Movimiento copiado")
    end)
  end
  listas.leer_actual()
end

movimiento.triggers = {
  {
    pattern = "^(.+) \\[(.+)\\]\\s*$",
    action = function()
      local salidas = matches[3]
      if salidas ~= "s/n/salir" then
        movimiento.llegada_room(matches[2], salidas)
      end
    end,
    name = "llegada_room",
    desc = "Detecta llegada a room con salidas"
  },
  {
    pattern = "^arbol: Entre las ramas \\((.+)\\)\\s*$",
    action = function()
      movimiento.llegada_room(matches[1], matches[2])
      movimiento.salidas_especiales = "Ramas " .. matches[2]
      movimiento.salidas_especiales_lista = { corrector.salidas(matches[2]) }
    end,
    name = "llegada_arbol",
    desc = "Detecta room de arbol"
  },
  {
    pattern = "^No logras seguir a (.+) en direccion (.+)\\.$",
    action = function()
      play("RL/Sucesos/No seguir.wav")
    end,
    name = "no_sigues",
    desc = "Sonido de no seguir"
  },
  {
    pattern = "^Sigues a (.+) en direccion (.+)\\.$",
    action = function()
      movimiento.direccion = matches[3]
      movimiento.actualizar_retorno()
      play("RL/Sucesos/Sigues.wav")
    end,
    name = "sigues",
    desc = "Sonido de seguir"
  },
  {
    pattern = "^Parece que .* no produjo efecto alguno\\.$",
    action = function()
      play("RL/Movimiento/Direccion erronea.wav")
    end,
    name = "direccion_erronea",
    desc = "Direccion erronea"
  },
  {
    pattern = "^La puerta .* esta cerrada\\.$",
    action = function()
      play("RL/Movimiento/Puerta cerrada.wav")
    end,
    name = "puerta_cerrada",
    desc = "Puerta cerrada"
  },
  {
    pattern = "^.* bloquea habilmente la salida impidiendote pasar\\.$",
    action = function()
      play("RL/Movimiento/Salida bloqueada.wav")
    end,
    name = "salida_bloqueada",
    desc = "Salida bloqueada"
  },
  {
    pattern = "^Con esfuerzo, consigues avanzar pesadamente sobre la nieve\\.$",
    action = function()
      play("RL/Movimiento/Nieve*5.wav")
    end,
    name = "nieve",
    desc = "Movimiento en nieve"
  },
  {
    pattern = "^La nieve dificulta tu paso impidiendote continuar avanzando\\.$",
    action = function()
      play("RL/Movimiento/Nieve bloquea.wav")
    end,
    name = "nieve_bloquea",
    desc = "Nieve bloquea"
  },
  {
    pattern = "^Avanzas chapoteando.*$",
    action = function()
      play("RL/Movimiento/Pantano*3.wav")
    end,
    name = "pantano",
    desc = "Movimiento en pantano"
  },
  {
    pattern = "^Intentas avanzar, pero.*lodo.*$",
    action = function()
      play("RL/Movimiento/Pantano Bloquea.wav")
    end,
    name = "pantano_bloquea",
    desc = "Pantano bloquea"
  },
}

local movimiento_otros = {
  {
    pattern = "^(.+) est.n aqui\\.$",
    action = function()
      movimiento.registrar_presencia(matches[2])
    end,
    name = "presentes_plural",
    desc = "Detecta presentes en la sala"
  },
  {
    pattern = "^(.+) est. aqui\\.$",
    action = function()
      if not line:find("Nada con el nombre", 1, true) then
        movimiento.registrar_presencia(matches[2])
      end
    end,
    name = "presentes_singular",
    desc = "Detecta presente en la sala"
  },
  {
    pattern = "^(.+) se va en direcci.n (.+) seguid. de (.+)\\.$",
    action = function()
      movimiento.registrar_movimiento_otro(matches[2], matches[3], false, line, "", matches[4])
      sonido_sujeto(matches[4], "RL/Movimiento/Sigue aliado se va.wav", "RL/Movimiento/Sigue enemigo se va.wav")
    end,
    name = "mov_salida_seguido",
    desc = "Movimiento de salida con seguidores"
  },
  {
    pattern = "^(.+) se va(.*)hacia (.+)\\.$",
    action = function()
      local tipo = trim(matches[3])
      movimiento.registrar_movimiento_otro(matches[2], matches[4], false, line, tipo)
      if tipo:find("Nadando", 1, true) or tipo:find("nadando", 1, true) then
        play("RL/Oceano/Nadando*3.wav")
      end
    end,
    name = "mov_salida_hacia",
    desc = "Movimiento de salida hacia direccion"
  },
  {
    pattern = "^(.+) sale galopando en su (.+) en direcci.n (.+)\\.$",
    action = function()
      movimiento.registrar_movimiento_otro(matches[2], matches[4], false, line, "galopando")
      audio.play("RL/Monturas/Galope*5.wav", { volume = 80 })
    end,
    name = "mov_salida_galope",
    desc = "Salida galopando"
  },
  {
    pattern = "^(.+) se va, desliz.ndose velozmente, en direcci.n (.+)\\.$",
    action = function()
      movimiento.registrar_movimiento_otro(matches[2], matches[3], false, line, "deslizandose")
      audio.play("RL/Monturas/Montura magica salida.wav", { volume = 80 })
    end,
    name = "mov_salida_deslizandose",
    desc = "Salida deslizandose"
  },
  {
    pattern = "^(.+) se va galopando en direccion (.+), levitando.*$",
    action = function()
      movimiento.registrar_movimiento_otro(matches[2], matches[3], false, line, "levitando")
      audio.play("RL/Monturas/Montura magica salida.wav", { volume = 80 })
    end,
    name = "mov_salida_levitando",
    desc = "Salida levitando"
  },
  {
    pattern = "^Ves a (.+) irse en direcci.n (.+) alej.ndose del .rbol\\.$",
    action = function()
      movimiento.registrar_movimiento_otro(matches[2], matches[3], false, line, "alejandose del arbol")
      audio.play("RL/Movimiento/Arbol*5.wav", { volume = 80 })
    end,
    name = "mov_salida_arbol",
    desc = "Salida desde arbol"
  },
  {
    pattern = "^(.+) salta hacia (.+)\\.$",
    action = function()
      movimiento.registrar_movimiento_otro(matches[2], matches[3], false, line, "saltando")
      audio.play("RL/Movimiento/Se va saltando.wav", { volume = 80 })
    end,
    name = "mov_salida_saltando",
    desc = "Salida saltando"
  },
  {
    pattern = "^Notas marcharse a alguien que estaba aqui\\.$",
    action = function()
      audio.play("RL/Movimiento/Se va desconocido.wav", { volume = 80 })
    end,
    name = "mov_salida_desconocida",
    desc = "Salida desconocida"
  },
  {
    pattern = "^(.+) llega(.*)desde (.+) seguid. de (.+)\\.$",
    action = function()
      movimiento.registrar_movimiento_otro(matches[2], matches[4], true, line, trim(matches[3]), matches[5])
      sonido_sujeto(matches[5], "RL/Movimiento/Sigue aliado llega.wav", "RL/Movimiento/Sigue enemigo llega.wav")
    end,
    name = "mov_entrada_seguido",
    desc = "Entrada con seguidores"
  },
  {
    pattern = "^(.+) llega(.*)desde (.+)\\.$",
    action = function()
      local tipo = trim(matches[3])
      local dir = matches[4]
      movimiento.registrar_movimiento_otro(matches[2], dir, true, line, tipo)
      local lower_tipo = tipo:lower()
      if lower_tipo:find("galopando", 1, true) then
        audio.play("RL/Monturas/Galope*5.wav", { volume = 80 })
      elseif lower_tipo:find("saltando", 1, true) then
        audio.play("RL/Movimiento/Llega saltando.wav", { volume = 80 })
      elseif lower_tipo:find("desplom", 1, true) then
        audio.play("RL/Movimiento/Desplomandose*3.wav", { volume = 80 })
      elseif lower_tipo:find("surcando", 1, true) then
        audio.play("RL/Oceano/Embarcacion llega.wav", { volume = 80 })
      elseif lower_tipo:find("nadando", 1, true) then
        audio.play("RL/Oceano/Nadando*3.wav", { volume = 80 })
      end
    end,
    name = "mov_entrada_desde",
    desc = "Entrada desde direccion"
  },
  {
    pattern = "^(.+) llega de (.+) seguid. de (.+)\\.$",
    action = function()
      movimiento.registrar_movimiento_otro(matches[2], matches[3], true, line, "", matches[4])
      sonido_sujeto(matches[4], "RL/Movimiento/Sigue aliado llega.wav", "RL/Movimiento/Sigue enemigo llega.wav")
    end,
    name = "mov_entrada_de_seguido",
    desc = "Entrada de direccion con seguidores"
  },
  {
    pattern = "^(.+) llega de (.+)\\.$",
    action = function()
      movimiento.registrar_movimiento_otro(matches[2], matches[3], true, line, "")
    end,
    name = "mov_entrada_de",
    desc = "Entrada de direccion"
  },
  {
    pattern = "^(.+) llega galopando desde (.+), levitando.*$",
    action = function()
      movimiento.registrar_movimiento_otro(matches[2], matches[3], true, line, "levitando")
      audio.play("RL/Monturas/Montura magica llegada.wav", { volume = 80 })
    end,
    name = "mov_entrada_levitando",
    desc = "Entrada levitando"
  },
  {
    pattern = "^(.+) llega desde el (.+), dejando un rastro de agua.*$",
    action = function()
      movimiento.registrar_movimiento_otro(matches[2], matches[3], true, line, "rastro de agua")
      audio.play("RL/Monturas/Montura magica llegada.wav", { volume = 80 })
    end,
    name = "mov_entrada_agua",
    desc = "Entrada con rastro de agua"
  },
  {
    pattern = "^Ves a (.+) llegar al pie del .rbol\\.$",
    action = function()
      movimiento.registrar_movimiento_otro(matches[2], "arbol", true, line, "arbol")
      audio.play("RL/Movimiento/Arbol*5.wav", { volume = 80 })
    end,
    name = "mov_entrada_arbol",
    desc = "Entrada al pie del arbol"
  },
  {
    pattern = "^Notas que alguien llega a tu posici.n\\.$",
    action = function()
      audio.play("RL/Movimiento/Llega desconocido.wav", { volume = 80 })
    end,
    name = "mov_entrada_desconocida",
    desc = "Entrada desconocida"
  },
  {
    pattern = "^De repente y sin saber c.mo (.+) aparece en un lugar cercano\\.$",
    action = function()
      movimiento.registrar_movimiento_otro(matches[2], "desconocida", true, line, "aparece")
      audio.play("RL/Movimiento/Llega desconocido.wav", { volume = 80 })
    end,
    name = "mov_entrada_aparece_cerca",
    desc = "Aparicion cercana"
  },
  {
    pattern = "^(.+) aparece de la nada\\.$",
    action = function()
      movimiento.registrar_movimiento_otro(matches[2], "desconocida", true, line, "de la nada")
      audio.play("RL/Movimiento/Llega desconocido.wav", { volume = 80 })
    end,
    name = "mov_entrada_nada",
    desc = "Aparece de la nada"
  },
  {
    pattern = "^(.+) detiene su montura para decidir el camino a seguir\\.$",
    action = function()
      audio.play("RL/Monturas/Galope ageno detenido.wav", { volume = 80 })
      lector.decir(matches[2])
    end,
    name = "mov_montura_detiene",
    desc = "Montura ajena detenida"
  },
  {
    pattern = "^(.+) espolea su montura y galopa raudo en direcci.n (.+)\\.$",
    action = function()
      audio.play("RL/Monturas/Espolea.wav", { volume = 80 })
    end,
    name = "mov_montura_espolea",
    desc = "Espolea montura"
  },
  {
    pattern = "^(.+) comienza a seguirte\\.$",
    action = function()
      sonido_sujeto(matches[2], "RL/Movimiento/Te sigue aliado inicio.wav", "RL/Movimiento/Te sigue enemigo inicio.wav")
    end,
    name = "seguirte_inicio",
    desc = "Alguien empieza a seguirte"
  },
  {
    pattern = "^(.+) te da esquinazo\\.$",
    action = function()
      audio.play("RL/Sucesos/No seguir.wav", { volume = 80 })
    end,
    name = "te_da_esquinazo",
    desc = "Pierdes seguimiento"
  },
  {
    pattern = "^(.+) te sigue.*\\.$",
    action = function()
      sonido_sujeto(matches[2], "RL/Movimiento/Te sigue aliado.wav", "RL/Movimiento/Te sigue enemigo.wav")
      if es_enemigo(matches[2]) then
        local eventos = RhomScripts and RhomScripts.modules and RhomScripts.modules.eventos
        if eventos then
          eventos.registrar(trim(matches[2]) .. " te sigue!")
        end
      end
    end,
    name = "te_sigue",
    desc = "Alguien te sigue"
  },
  {
    pattern = "^(.+) intenta seguirte pero le das esquinazo\\.$",
    action = function()
      audio.play("RL/Sucesos/Das esquinazo.wav", { volume = 80 })
    end,
    name = "das_esquinazo",
    desc = "Das esquinazo"
  },
  {
    pattern = "^(.+) sigue a .+ hacia .+\\.$",
    action = function()
      if es_enemigo(matches[2]) then
        audio.play("RL/Movimiento/Te sigue enemigo.wav", { volume = 80 })
      end
    end,
    name = "sigue_a_otro",
    desc = "Seguimiento de terceros"
  },
  {
    pattern = "^(.+) cae del .rbol\\.$",
    action = function()
      audio.play("RL/Combate/Caida*4.wav", { volume = 80 })
    end,
    name = "arbol_cae",
    desc = "Caida de arbol"
  },
  {
    pattern = "^(.+) cae al suelo d.ndose un buen porrazo\\.$",
    action = function()
      audio.play("RL/Combate/Caida*4.wav", { volume = 80 })
    end,
    name = "arbol_porazo",
    desc = "Caida con porrazo"
  },
  {
    pattern = "^(.+) empieza a trepar el .rbol.*$",
    action = function()
      audio.play("RL/Movimiento/Trepa empezar.wav", { volume = 80 })
    end,
    name = "arbol_trepa_inicio",
    desc = "Empieza a trepar"
  },
  {
    pattern = "^(.+) desaparece entre las ramas.*$",
    action = function()
      audio.play("RL/Movimiento/Trepa terminar.wav", { volume = 80 })
    end,
    name = "arbol_trepa_fin",
    desc = "Desaparece entre ramas"
  },
  {
    pattern = "^Ves moverse las ramas del .rbol por encima de ti\\.$",
    action = function()
      audio.play("RL/Movimiento/Movimiento ramas.wav", { volume = 80 })
    end,
    name = "arbol_ramas",
    desc = "Movimiento de ramas"
  },
  {
    pattern = "^(.+) aparece trepando por el tronco del .rbol\\.$",
    action = function()
      audio.play("RL/Movimiento/Trepa terminar.wav", { volume = 80 })
    end,
    name = "arbol_aparece",
    desc = "Aparece trepando"
  },
  {
    pattern = "^(.+) est. all.\\.$",
    action = function()
      sonido_sujeto(matches[2], "RL/Generales/Aliado alli.wav", "RL/Generales/Enemigo alli.wav")
      lector.decir(matches[2])
    end,
    name = "sujeto_alla",
    desc = "Detecta sujeto en otra room"
  },
}

for _, trigger in ipairs(movimiento_otros) do
  table.insert(movimiento.triggers, trigger)
end

movimiento.key_bindings = {}

for _, item in ipairs(direcciones_primarias) do
  local key_name = item[1]
  local direccion = item[2]
  table.insert(movimiento.key_bindings, {
    modifiers = mudlet.keymodifier.Alt,
    key = key_names[key_name],
    action = function()
      movimiento.mover(direccion, false)
    end,
    name = "Alt+" .. key_name,
    desc = "Movimiento primario " .. direccion
  })
  table.insert(movimiento.key_bindings, {
    modifiers = mudlet.keymodifier.Alt + mudlet.keymodifier.Shift,
    key = key_names[key_name],
    action = function()
      movimiento.mover(direccion, true)
    end,
    name = "Alt+Shift+" .. key_name,
    desc = "Movimiento secundario " .. direccion
  })
end

for _, item in ipairs(direcciones_numpad) do
  local key = mudlet_key(unpack_list(item[1]))
  if key then
    local direccion = item[2]
    table.insert(movimiento.key_bindings, {
      key = key,
      action = function()
        movimiento.mover(direccion, false)
      end,
      name = item[3],
      desc = "Movimiento numpad " .. direccion
    })
  end
end

movimiento.key_bindings[#movimiento.key_bindings + 1] = {
  modifiers = mudlet.keymodifier.Alt,
  key = mudlet.key["3"],
  action = function()
    lector.decir(movimiento.ultimo_movimiento_e ~= "" and movimiento.ultimo_movimiento_e or "Aun no has visto moverse a ningun enemigo")
  end,
  name = "Alt+3",
  desc = "Lee ultimo movimiento enemigo"
}

movimiento.key_bindings[#movimiento.key_bindings + 1] = {
  modifiers = mudlet.keymodifier.Alt + mudlet.keymodifier.Shift,
  key = mudlet.key["3"],
  action = function()
    mostrar_historial("Historial de movimientos enemigos", movimiento.historial_e)
  end,
  name = "Alt+Shift+3",
  desc = "Muestra historial de movimientos enemigos"
}

movimiento.key_bindings[#movimiento.key_bindings + 1] = {
  modifiers = mudlet.keymodifier.Alt,
  key = mudlet.key["4"],
  action = function()
    lector.decir(movimiento.ultimo_movimiento_a ~= "" and movimiento.ultimo_movimiento_a or "Aun no has visto moverse a ningun aliado")
  end,
  name = "Alt+4",
  desc = "Lee ultimo movimiento aliado"
}

movimiento.key_bindings[#movimiento.key_bindings + 1] = {
  modifiers = mudlet.keymodifier.Alt + mudlet.keymodifier.Shift,
  key = mudlet.key["4"],
  action = function()
    mostrar_historial("Historial de movimientos aliados", movimiento.historial_a)
  end,
  name = "Alt+Shift+4",
  desc = "Muestra historial de movimientos aliados"
}

movimiento.key_bindings[#movimiento.key_bindings + 1] = {
  modifiers = mudlet.keymodifier.Control,
  key = mudlet.key.D,
  action = function()
    send("parar")
  end,
  name = "Ctrl+D",
  desc = "Detiene movimiento y cola de comandos"
}

movimiento.key_bindings[#movimiento.key_bindings + 1] = {
  modifiers = mudlet.keymodifier.Control,
  key = mudlet.key.H,
  action = function()
    lector.decir(movimiento.localizacion ~= "" and movimiento.localizacion or "No hay localizacion registrada")
  end,
  name = "Ctrl+H",
  desc = "Lee localizacion"
}

movimiento.key_bindings[#movimiento.key_bindings + 1] = {
  modifiers = mudlet.keymodifier.Control + mudlet.keymodifier.Shift,
  key = mudlet.key.P,
  action = function()
    lector.decir("Has llegado desde " .. movimiento.direccion_retorno)
  end,
  name = "Ctrl+Shift+P",
  desc = "Lee direccion de retorno"
}

movimiento.key_bindings[#movimiento.key_bindings + 1] = {
  modifiers = mudlet.keymodifier.Alt,
  key = mudlet.key.P,
  action = function()
    local nicks = RhomScripts and RhomScripts.modules and RhomScripts.modules.nicks
    local objetivo = nicks and nicks.objetivo
    if not objetivo or objetivo == "" then
      lector.decir("No hay un objetivo definido. Define el nick X antes")
    elseif movimiento.objetivo_se_va ~= "" then
      lector.decir(movimiento.objetivo_se_va .. ". " .. objetivo .. " se va")
    elseif movimiento.objetivo_llega ~= "" then
      lector.decir(movimiento.objetivo_llega .. ". " .. objetivo .. " llega")
    else
      lector.decir("No has visto moverse a " .. objetivo)
    end
  end,
  name = "Alt+P",
  desc = "Lee movimiento del objetivo"
}

return movimiento
