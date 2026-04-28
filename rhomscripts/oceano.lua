-------------------------------------------------------------------------------
-- Modulo: oceano
-- Migracion funcional desde Oceano.set y Embarcaciones.set.
-------------------------------------------------------------------------------

local audio = require("audio")
local config = require("config")
local eventos = require("eventos")
local lector = require("lector")

local oceano = {}

oceano.embarcado = false
oceano.navegando = false
oceano.control_activo = 0
oceano.en_puente = false
oceano.control_mov_barco = 0
oceano.ultima_posicion = ""
oceano.salidas_marinero = ""

local function trim(text)
  if type(text) ~= "string" then
    return ""
  end
  return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function play(path, pan)
  audio.play(path, { volume = 82, pan = pan })
end

local function evento(text)
  eventos.registrar(text)
end

local function movimiento()
  return RhomScripts and RhomScripts.modules and RhomScripts.modules.movimiento
end

local function modo_experto()
  local modes = RhomScripts and RhomScripts.modules and RhomScripts.modules.modes
  return modes and modes.get_flag and modes.get_flag("experto")
end

local function set_embarcado(value)
  oceano.embarcado = value and true or false
  config.set("embarcado", oceano.embarcado)
end

local function set_navegando(value)
  oceano.navegando = value and true or false
  config.set("navegando", oceano.navegando)
end

function oceano.desactivar_marinero()
  if config.get("modo_marinero") then
    config.set("modo_marinero", false)
    lector.decir("Modo marinero desactivado")
    play("RL/Modos/Off.wav")
  end
end

local function limpiar_presentes()
  local mov = movimiento()
  if mov then
    mov.presentes = {}
    mov.presentes_enemigos = {}
  end
end

function oceano.control_room(texto)
  local value = trim(texto)
  local en_puente = value:find("Puente de Gobierno", 1, true) or value:find("Ars Strategvm", 1, true)
  oceano.en_puente = not not en_puente
  oceano.control_activo = en_puente and 1 or 0
  return oceano.control_activo
end

function oceano.marcar_timon()
  if oceano.control_activo == 1 then
    oceano.control_activo = 2
    play("RL/Modos/Especial disponible.wav")
  end
end

local function registrar_movimiento_barco(nombre, direccion, entrada, texto)
  local mov = movimiento()
  if mov and mov.registrar_movimiento_otro then
    mov.registrar_movimiento_otro(nombre, direccion, entrada, texto, "embarcacion")
  end
end

function oceano.llegada_barco(titulo, oeste, sur)
  local room = trim(titulo)
  if room:find("SL:", 1, true) then
    return
  end

  set_embarcado(true)
  oceano.ultima_posicion = string.format("%s: %s %s", room, trim(oeste), trim(sur or ""))
  oceano.salidas_marinero = string.format("%s %s. %s", trim(oeste), trim(sur or ""), room)
  oceano.control_mov_barco = oceano.control_mov_barco + 1
  if oceano.control_mov_barco > 4 then
    oceano.control_mov_barco = 1
  end

  local pan = (oceano.control_mov_barco == 1 or oceano.control_mov_barco == 3) and -4000 or 4000
  play("RL/Oceano/Movimiento barco *4.wav", pan)
  if modo_experto() then
    lector.decir(oceano.ultima_posicion)
  end

  local mov = movimiento()
  if mov then
    mov.salidas_especiales = oceano.ultima_posicion
    mov.salidas_especiales_lista = { trim(oeste), trim(sur or "") }
  end

  limpiar_presentes()
end

local sound_rules = {
  { "^(.+) acaba de atracar en el muelle\\.$", "RL/Oceano/Atraca.wav" },
  { "^Realizas un gesto a uno de los miembros de las Autoridades Portuarias.*$", "RL/Oceano/Recuperar embarcacion.wav" },
  { "^(.+) realiza un gesto a uno de los miembros de las Autoridades Portuarias.*$", "RL/Oceano/Recuperar embarcacion.wav" },
  { "^Agarras con fuerza un cabo libre del muelle y amarras .*$", "RL/Oceano/Amarrar embarcacion.wav" },
  { "^(.+) agarra con fuerza un cabo libre del muelle y amarra .*$", "RL/Oceano/Amarrar embarcacion.wav" },
  { "^(.+) desenrolla la Escalera de Embarque de.*$", "RL/Oceano/Suelta escalera.wav" },
  { "^(.+) recoge la Escalera de Embarque de.*$", "RL/Oceano/Recoge escalera.wav" },
  { "^(.+) suelta el ancla de.*$", "RL/Oceano/Suelta ancla.wav" },
  { "^(.+) leva el ancla de.*$", "RL/Oceano/Recoge ancla.wav" },
  { "^Empieza a soplar viento de direcci.n .+\\.$", "RL/Oceano/Viento aumenta*3.wav" },
  { "^.*Resto.* de un.* naufragio.*\\.$", "RL/Oceano/Restos.wav" },
  { "^Algo sucede en el exterior: .+$", "RL/Oceano/Exterior.wav" },
  { "^(.+) llega de la superficie\\.$", "RL/Oceano/Salir agua otro*2.wav" },
  { "^Desenrollas la Escalera de Embarque anclada.*$", "RL/Oceano/Soltar escalera.wav" },
  { "^Recoges lentamente la pesada Escalera de Embarque.*$", "RL/Oceano/Recoger escalera.wav" },
  { "^(.+) desenrolla la Escalera de Embarque anclada.*$", "RL/Oceano/Suelta escalera.wav" },
  { "^(.+) recoge la Escalera de Embarque anclada.*$", "RL/Oceano/Recoge escalera.wav" },
  { "^Giras la pesada manivela que controla el Molinete del Ancla.*aparece.*$", "RL/Oceano/Recoger ancla.wav" },
  { "^Giras la manivela que controla el Molinete del Ancla.*desaparecer.*$", "RL/Oceano/Soltar ancla.wav" },
  { "^(.+) gira una manivela y, en el exterior, el ancla.*zambulle.*$", "RL/Oceano/Suelta ancla.wav" },
  { "^(.+) gira una manivela y recoge el ancla.*$", "RL/Oceano/Recoge ancla.wav" },
  { "^Con esfuerzo arrojas cuerpo de .* por la borda.*$", "RL/Oceano/Por la borda.wav" },
  { "^La embarcaci.n termina de orientarse hacia el .+\\.$", "RL/Oceano/Vela*4.wav", function() set_navegando(true) end },
  { "^.*Viento en popa.*corriente favorable.*$", "RL/Oceano/Corriente favorable.wav" },
  { "^.*La fuerte corriente ralentiza la navegaci.n.*$", "RL/Oceano/Corriente desfavorable 1.wav" },
  { "^.*La fort.sima corriente ralentiza terriblemente.*$", "RL/Oceano/Corriente desfavorable 2.wav" },
  { "^Hab.is sido avistados por los piratas.*$", "RL/Oceano/Ataque piratas.wav" },
  { "^.* explota en miles de pedazos.* y T. eres uno de esos pedazos!$", "RL/Oceano/Hundimiento propio.wav", function()
    set_embarcado(false)
    set_navegando(false)
    oceano.desactivar_marinero()
  end },
  { "^.* explota en miles de pedazos.*$", "RL/Oceano/Hundimiento otro.wav", function()
    if line and line:find("eres uno de esos pedazos", 1, true) then
      return false
    end
  end },
}

oceano.triggers = {
  {
    pattern = "^(.+) surca las aguas en direcci.n (.+)\\.$",
    action = function()
      registrar_movimiento_barco(matches[2], matches[3], false, line)
      play("RL/Oceano/Embarcacion se va.wav")
    end,
    name = "oceano_barco_se_va",
    desc = "Embarcacion se va desde puerto"
  },
  {
    pattern = "^(.+) leva anclas y parte a sucar los mares en direcci.n (.+)\\.$",
    action = function()
      registrar_movimiento_barco(matches[2], matches[3], false, line)
      play("RL/Oceano/Embarcacion se va.wav")
    end,
    name = "oceano_leva_anclas",
    desc = "Embarcacion leva anclas"
  },
  {
    pattern = "^(.+) da un salto y se zambulle en el agua\\.$",
    action = function()
      evento(line)
      play("RL/Movimiento/Se va saltando.wav")
      play("RL/Oceano/Zambullirse otro.wav")
    end,
    name = "oceano_zambulle_otro",
    desc = "Alguien se zambulle"
  },
  {
    pattern = "^[¡!]?(.-) se zambulle en el agua repentinamente saltando por la borda de .+!$",
    action = function()
      evento(line)
      play("RL/Oceano/Zambullirse otro.wav")
    end,
    name = "oceano_zambulle_borda",
    desc = "Alguien salta por la borda"
  },
  {
    pattern = "^[¡!]?(.-) aparece repentinamente saltando por la borda .+!$",
    action = function()
      evento(line)
      play("RL/Movimiento/Llega saltando.wav")
    end,
    name = "oceano_aparece_borda",
    desc = "Alguien aparece por la borda"
  },
  {
    pattern = "^(.+) se embarca en (.+)\\.$",
    action = function()
      evento(line)
      play("RL/Oceano/Embarcar otro.wav")
      if matches[3] and matches[3]:find(matches[2], 1, true) then
        play("RL/Oceano/Bienvenida tripulacion otro.wav")
      end
    end,
    name = "oceano_embarca_otro",
    desc = "Alguien embarca"
  },
  {
    pattern = "^Cruzas la pasarela de acceso al (.+) y llegas a su cubierta\\.$",
    action = function()
      set_embarcado(true)
      play("RL/Oceano/Embarcar.wav")
      play("RL/Oceano/Bienvenida tripulacion.wav")
    end,
    name = "barco_embarcar_pasarela",
    desc = "Embarcas por pasarela"
  },
  {
    pattern = "^Te las apa.as como puedes para trepar la escalera .* y llegar.*a su cubierta\\.$",
    action = function()
      set_embarcado(true)
      play("RL/Oceano/Subir escalerilla.wav")
      play("RL/Oceano/Bienvenida tripulacion.wav")
    end,
    name = "barco_subir_escalerilla",
    desc = "Embarcas por escalerilla"
  },
  {
    pattern = "^Coges carrerilla hasta saltar por la borda del .* y (.+)$",
    action = function()
      set_embarcado(false)
      set_navegando(false)
      oceano.desactivar_marinero()
      play("RL/Movimiento/Saltando.wav")
      if matches[2]:find("agua", 1, true) then
        play("RL/Oceano/Zambullirse*2.wav")
      end
    end,
    name = "barco_saltar_borda",
    desc = "Sales saltando por la borda"
  },
  {
    pattern = "^Desciendes por la escalera de.* hasta llegar (.+)\\.$",
    action = function()
      set_embarcado(false)
      set_navegando(false)
      oceano.desactivar_marinero()
      play("RL/Oceano/Bajar escalerilla.wav")
      if matches[2]:find("agua", 1, true) then
        play("RL/Oceano/En el agua*2.wav")
      end
    end,
    name = "barco_bajar_escalera",
    desc = "Desembarcas por escalera"
  },
  {
    pattern = "^Cierras los ojos, rezas tus plegarias y te lanzas al vac.o.*$",
    action = function()
      set_embarcado(false)
      play("RL/Movimiento/Saltando.wav")
    end,
    name = "barco_salto_mastil",
    desc = "Salto desde mastil"
  },
  {
    pattern = "^Al ver que el barco explota, te lanzas desesperadamente por la borda\\.$",
    action = function()
      set_embarcado(false)
      set_navegando(false)
      oceano.desactivar_marinero()
      play("RL/Oceano/Zambullirse*2.wav")
    end,
    name = "barco_explota_saltas",
    desc = "Saltas por explosion"
  },
  {
    pattern = "^Por suerte has ca.do en tierra firme.*$",
    action = function()
      set_embarcado(false)
      set_navegando(false)
      play("RL/Combate/Caida*4.wav")
    end,
    name = "barco_caida_tierra",
    desc = "Caida en tierra"
  },
  {
    pattern = "^(.+) \\[(.+) Oeste, (.+) Sur\\]$",
    action = function()
      oceano.llegada_barco(matches[2], matches[3], matches[4])
    end,
    name = "barco_llegada_coordenadas",
    desc = "Llegada a room de barco con coordenadas"
  },
  {
    pattern = "^(.+) \\[Todas\\]$",
    action = function()
      oceano.llegada_barco(matches[2], "todas", "")
    end,
    name = "barco_llegada_todas",
    desc = "Llegada a room de barco con todas las salidas"
  },
  {
    pattern = "^(.+) se aproxima a.*posici.n desde el (.+)\\.$",
    action = function()
      registrar_movimiento_barco(matches[2], matches[3], true, line)
      play("RL/Oceano/Embarcacion llega.wav")
    end,
    name = "barco_aproxima",
    desc = "Embarcacion se aproxima"
  },
  {
    pattern = "^(.+) se aleja de.*posici.n en direcci.n (.+)\\.$",
    action = function()
      registrar_movimiento_barco(matches[2], matches[3], false, line)
      play("RL/Oceano/Embarcacion se va.wav")
    end,
    name = "barco_aleja",
    desc = "Embarcacion se aleja"
  },
  {
    pattern = "^[¡!]?(.-) acaba de llegar a la cubierta del (.+)!$",
    action = function()
      evento(line)
      play("RL/Oceano/Llega a bordo.wav")
      local stats = RhomScripts and RhomScripts.modules and RhomScripts.modules.stats
      if stats and stats.ultimo_enemigo and stats.ultimo_enemigo:lower():find(trim(matches[2]):lower(), 1, true) then
        play("RL/Oceano/Enemigo a bordo*2.wav")
      end
    end,
    name = "barco_llega_bordo",
    desc = "Alguien llega a bordo"
  },
  {
    pattern = "^(.+) salta por la borda de la embarcaci.n y se zambulle en el agua\\.$",
    action = function()
      evento(line)
      play("RL/Movimiento/Se va saltando.wav")
      play("RL/Oceano/Zambullirse otro.wav")
    end,
    name = "barco_otro_borda",
    desc = "Alguien salta por la borda"
  },
  {
    pattern = "^.*Se produce una gran sacudida.*la embarcaci.n .*$",
    action = function()
      set_navegando(false)
      play("RL/Oceano/Choque barco.wav")
    end,
    name = "barco_choque",
    desc = "Choque de barco"
  },
  {
    pattern = "^La embarcaci.n se detiene al haber llegado a un muelle\\.$",
    action = function()
      set_navegando(false)
      play("RL/Oceano/Atracar.wav")
      limpiar_presentes()
    end,
    name = "barco_atracar",
    desc = "Barco llega a muelle"
  },
  {
    pattern = "^La embarcaci.n se detiene\\.$",
    action = function()
      set_navegando(false)
      play("RL/Oceano/Vela abajo.wav")
      play("RL/Oficios/Marinero/Navegar Detener.wav")
    end,
    name = "barco_detiene",
    desc = "Barco se detiene"
  },
  {
    pattern = "^.*nadie est. manejando el tim.n.*$",
    action = function()
      set_navegando(false)
      play("RL/Oceano/Vela abajo.wav")
    end,
    name = "barco_sin_timon",
    desc = "Navegacion sin timon"
  },
}

for index, rule in ipairs(sound_rules) do
  table.insert(oceano.triggers, {
    pattern = rule[1],
    action = function()
      if type(rule[3]) == "function" and rule[3]() == false then
        return
      end
      play(rule[2])
    end,
    name = "oceano_sonido_" .. index,
    desc = "Evento sonoro de oceano"
  })
end

table.insert(oceano.triggers, {
  pattern = "^.*Tim.n.*$",
  action = function()
    oceano.marcar_timon()
  end,
  name = "barco_timon_disponible",
  desc = "Detecta timon en puente de gobierno"
})

local viento_rules = {
  { "manteni", "RL/Oceano/Viento mantiene*2.wav" },
  { "aumentando", "RL/Oceano/Viento aumenta*3.wav" },
  { "disminuyendo", "RL/Oceano/Viento disminuye.wav" },
}

local function sonido_viento(texto)
  local value = (texto or ""):lower()
  for _, rule in ipairs(viento_rules) do
    if value:find(rule[1], 1, true) then
      play(rule[2])
      return
    end
  end
end

table.insert(oceano.triggers, {
  pattern = "^El viento cambia de direcci.n y empieza a soplar del (.+), (.+) su intensidad\\.$",
  action = function()
    sonido_viento(matches[3])
  end,
  name = "oceano_viento_cambia",
  desc = "Cambio de viento"
})

table.insert(oceano.triggers, {
  pattern = "^El viento sigue soplando del (.+), (.+) su intensidad\\.$",
  action = function()
    sonido_viento(matches[3])
  end,
  name = "oceano_viento_sigue",
  desc = "Viento sigue soplando"
})

local disparos = {
  { "bala", "RL/Oceano/Cañonazo enemigo *5.wav" },
  { "silbido", "RL/Oceano/Cañonazo enemigo *5.wav" },
  { "saetas", "RL/Oceano/Saeta enemigo *5.wav" },
  { "saeta", "RL/Oceano/Saeta enemigo *5.wav" },
}

for index, rule in ipairs(disparos) do
  table.insert(oceano.triggers, {
    pattern = "^.*\\[.*\\].*" .. rule[1] .. ".*$",
    action = function()
      play(rule[2])
    end,
    name = "barco_disparo_" .. index,
    desc = "Disparo de embarcacion enemiga"
  })
end

oceano.aliases = {
  {
    pattern = "^FuncOceanoControl\\s*(.*)$",
    action = function()
      oceano.control_room(matches[2] or "")
    end,
    name = "FuncOceanoControl",
    desc = "Alias historico: actualiza el control de puente/timon"
  },
  {
    pattern = "^FuncMovBarco\\s+(.+)$",
    action = function()
      local raw = trim(matches[2] or "")
      local titulo, oeste, sur = raw:match("^(.-)%s+([^%s]+)%s+([^%s]+)$")
      if not titulo or titulo == "" then
        titulo, oeste = raw:match("^(.-)%s+(todas)$")
      end
      if titulo and oeste then
        oceano.llegada_barco(titulo, oeste, sur or "")
      else
        lector.decir("Uso: FuncMovBarco titulo oeste sur")
      end
    end,
    name = "FuncMovBarco",
    desc = "Alias historico: registra movimiento de la embarcacion"
  },
  {
    pattern = "^oceanoestado$",
    action = function()
      local estado = oceano.embarcado and "embarcado" or "en tierra"
      local navegacion = oceano.navegando and "navegando" or "detenido"
      local puente = oceano.control_activo == 2 and "timon disponible" or (oceano.en_puente and "en puente" or "sin puente")
      lector.decir(estado .. ", " .. navegacion .. ", " .. puente)
    end,
    name = "oceanoestado",
    desc = "Lee el estado de oceano y embarcacion"
  },
}

return oceano
