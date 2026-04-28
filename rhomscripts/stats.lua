-------------------------------------------------------------------------------
-- Modulo: stats
-- Migracion funcional desde Stats.set.
-------------------------------------------------------------------------------

local audio = require("audio")
local config = require("config")
local corrector = require("corrector")
local lector = require("lector")
local listas = require("listas")

local stats = {}

stats.pvs = 0
stats.pvs_max = 0
stats.pe = 0
stats.pe_max = 0
stats.fe = nil
stats.xp = 0
stats.po = 0
stats.soc = 0
stats.salidas = ""
stats.salidas_lista = {}
stats.pieles = nil
stats.imagenes = nil
stats.ultimo_enemigo = ""
stats.ultimo_aliado = ""
stats.peleas = ""
stats.historial_cpvs = {}
stats.ultimo_cpvs = nil
stats.alertas = {
  vida50 = nil,
  vida30 = nil,
  vida10 = nil,
}

local function trim(text)
  if type(text) ~= "string" then
    return ""
  end
  return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function split_names(text)
  local value = corrector.players(text or "")
  value = value:gsub("%s+y%s+", "|"):gsub(",%s*", "|")

  local result = {}
  for item in value:gmatch("[^|]+") do
    local name = trim(item)
    if name ~= "" then
      table.insert(result, name)
    end
  end
  return result
end

local function join(list)
  return table.concat(list or {}, ", ")
end

local function stop_alert(key)
  if stats.alertas[key] then
    audio.stop(stats.alertas[key])
    stats.alertas[key] = nil
  end
end

local function start_alert(key, path)
  if not stats.alertas[key] then
    stats.alertas[key] = audio.loop(path, { volume = 75, key = "rhom:alerta:" .. key })
  end
end

function stats.actualizar_alertas()
  if not config.get("alerta_vida") then
    stop_alert("vida50")
    stop_alert("vida30")
    stop_alert("vida10")
    return
  end

  if stats.pvs_max <= 0 then
    return
  end

  local pct = (stats.pvs * 100) / stats.pvs_max
  if pct <= 50 and pct > 30 then
    start_alert("vida50", "RL/Combate/Alerta vida 50.wav")
  else
    stop_alert("vida50")
  end

  if pct <= 30 and pct > 10 then
    start_alert("vida30", "RL/Combate/Alerta vida 30.wav")
  else
    stop_alert("vida30")
  end

  if pct <= 10 and pct >= 0 then
    start_alert("vida10", "RL/Combate/Alerta vida 10.wav")
  else
    stop_alert("vida10")
  end
end

function stats.registrar_cpvs(valor)
  local delta = tonumber(valor) or 0
  if delta == 0 then
    return
  end

  stats.ultimo_cpvs = delta
  table.insert(stats.historial_cpvs, 1, tostring(delta))
  while #stats.historial_cpvs > 10 do
    table.remove(stats.historial_cpvs)
  end

  if delta < 0 then
    lector.decir("Vida perdida: " .. tostring(delta))
  else
    lector.decir("Vida ganada: " .. tostring(delta))
  end
end

function stats.actualizar_prompt(pvs, pvs_max, pe, pe_max, xp)
  stats.pvs = tonumber(pvs) or stats.pvs
  stats.pvs_max = tonumber(pvs_max) or stats.pvs_max
  stats.pe = tonumber(pe) or stats.pe
  stats.pe_max = tonumber(pe_max) or stats.pe_max
  stats.xp = tonumber(xp) or stats.xp

  if stats.pvs == stats.pvs_max then
    stats.historial_cpvs = {}
    stats.ultimo_cpvs = nil
  end

  stats.actualizar_alertas()
end

function stats.actualizar_salidas(texto)
  stats.salidas = trim(texto)
  stats.salidas_lista = {}
  local limpio = corrector.salidas(texto):gsub(",", "|")
  for salida in limpio:gmatch("[^|]+") do
    local value = trim(salida)
    if value ~= "" then
      table.insert(stats.salidas_lista, value)
    end
  end
end

function stats.actualizar_enemigos(texto)
  local nombres = split_names(texto)
  stats.ultimo_enemigo = join(nombres)
  if stats.ultimo_enemigo ~= "" then
    audio.play("RL/Generales/Enemigo.wav", { volume = 80, key = "rhom:enemigo" })
  end
end

function stats.actualizar_aliados(texto)
  local nombres = split_names(texto)
  stats.ultimo_aliado = join(nombres)
  if stats.ultimo_aliado ~= "" then
    local grupos = RhomScripts and RhomScripts.modules and RhomScripts.modules.grupos
    local agrupado = false
    if grupos and grupos.es_miembro then
      for _, nombre in ipairs(nombres) do
        if grupos.es_miembro(nombre) then
          agrupado = true
          break
        end
      end
    end
    audio.play(agrupado and "RL/Generales/Agrupados.wav" or "RL/Generales/Aliado.wav", { volume = 80, key = "rhom:aliado" })
  end
end

function stats.actualizar_jugadores(texto)
  local nombres = split_names(texto)
  local aliados = {}
  local enemigos = {}
  local nicks = RhomScripts and RhomScripts.modules and RhomScripts.modules.nicks

  for _, nombre in ipairs(nombres) do
    local enemigo = false
    if nicks and nicks.nickx then
      local low = nombre:lower()
      for _, nick in ipairs(nicks.nickx) do
        if low == tostring(nick):lower() then
          enemigo = true
          break
        end
      end
    end
    table.insert(enemigo and enemigos or aliados, nombre)
  end

  if #aliados > 0 then
    stats.actualizar_aliados(table.concat(aliados, "|"))
  end
  if #enemigos > 0 then
    stats.actualizar_enemigos(table.concat(enemigos, "|"))
  end
end

function stats.actualizar_peleas(texto)
  local nombres = split_names(texto)
  stats.peleas = join(nombres)
  if stats.peleas ~= "" then
    audio.play("RL/Generales/En peleas.wav", { volume = 80, key = "rhom:peleas" })
  end
end

function stats.mostrar_historial_cpvs()
  if #stats.historial_cpvs == 0 then
    lector.decir("Historial de PVS vacio")
    return
  end

  listas.nueva("Historial de PVS")
  for index = #stats.historial_cpvs, 1, -1 do
    local value = stats.historial_cpvs[index]
    listas.agregar("Historial de PVS", value, function()
      lector.copiar(value, "PVS copiado")
    end)
  end
  listas.leer_actual()
end

stats.triggers = {
  {
    pattern = "^Pv:([0-9]+)\\\\([0-9]+) Pe:([0-9]+)\\\\([0-9]+) Xp:([0-9]+)",
    action = function()
      stats.actualizar_prompt(matches[2], matches[3], matches[4], matches[5], matches[6])
    end,
    name = "prompt_pv_pe_xp",
    desc = "Captura vida, energia y experiencia desde prompt"
  },
  {
    pattern = "^SL:\\s*[\\[\\(](.*)[\\]\\)]",
    action = function()
      stats.actualizar_salidas(matches[2])
    end,
    name = "prompt_salidas",
    desc = "Captura salidas del prompt"
  },
  {
    pattern = "^NM:(.*)$",
    action = function()
      stats.actualizar_enemigos(matches[2])
    end,
    name = "prompt_enemigos",
    desc = "Captura enemigos presentes"
  },
  {
    pattern = "^PL:(.*)$",
    action = function()
      stats.actualizar_peleas(matches[2])
    end,
    name = "prompt_peleas",
    desc = "Captura personajes en pelea"
  },
  {
    pattern = "^LD:(.*)$",
    action = function()
      stats.actualizar_aliados(matches[2])
    end,
    name = "prompt_aliados",
    desc = "Captura aliados presentes"
  },
  {
    pattern = "^Pieles:(.*)$",
    action = function()
      stats.pieles = tonumber(matches[2]) or matches[2]
    end,
    name = "prompt_pieles",
    desc = "Captura pieles"
  },
  {
    pattern = "^Im.genes:(.*)$",
    action = function()
      stats.imagenes = tonumber(matches[2]) or matches[2]
    end,
    name = "prompt_imagenes",
    desc = "Captura imagenes"
  },
  {
    pattern = "^Jgd:(.*)$",
    action = function()
      stats.actualizar_jugadores(matches[2])
    end,
    name = "prompt_jugadores",
    desc = "Captura jugadores presentes"
  },
  {
    pattern = "^Pvs: ([0-9]+)/([0-9]+) \\(([-0-9]+)\\) Pe: ([0-9]+)/([0-9]+) \\(([-0-9]+)\\)",
    action = function()
      stats.pvs = tonumber(matches[2]) or stats.pvs
      stats.pvs_max = tonumber(matches[3]) or stats.pvs_max
      stats.pe = tonumber(matches[5]) or stats.pe
      stats.pe_max = tonumber(matches[6]) or stats.pe_max
      stats.registrar_cpvs(matches[4])
      stats.actualizar_alertas()
    end,
    name = "monitor_combate",
    desc = "Captura monitor de combate"
  },
  {
    pattern = "^Pvs: ([0-9]+)\\(([0-9]+)\\)\\s+Pe: ([0-9]+)\\(([0-9]+)\\)\\s+Po: ([0-9]+)\\s+Xp: ([0-9]+)\\s+Psoc: ([0-9]+)",
    action = function()
      stats.pvs = tonumber(matches[2]) or stats.pvs
      stats.pvs_max = tonumber(matches[3]) or stats.pvs_max
      stats.pe = tonumber(matches[4]) or stats.pe
      stats.pe_max = tonumber(matches[5]) or stats.pe_max
      stats.po = tonumber(matches[6]) or stats.po
      stats.xp = tonumber(matches[7]) or stats.xp
      stats.soc = tonumber(matches[8]) or stats.soc
      stats.actualizar_alertas()
    end,
    name = "sc_basico",
    desc = "Captura datos del comando sc"
  },
  {
    pattern = "^Pvs: ([0-9]+)\\(([0-9]+)\\)\\s+Pe: ([0-9]+)\\(([0-9]+)\\)\\s+Fe: ([0-9]+)\\(([0-9]+)\\)\\s+Po: ([0-9]+)\\s+Xp: ([0-9]+)\\s+Psoc: ([0-9]+)",
    action = function()
      stats.pvs = tonumber(matches[2]) or stats.pvs
      stats.pvs_max = tonumber(matches[3]) or stats.pvs_max
      stats.pe = tonumber(matches[4]) or stats.pe
      stats.pe_max = tonumber(matches[5]) or stats.pe_max
      stats.fe = tonumber(matches[6]) or matches[6]
      stats.po = tonumber(matches[8]) or stats.po
      stats.xp = tonumber(matches[9]) or stats.xp
      stats.soc = tonumber(matches[10]) or stats.soc
      stats.actualizar_alertas()
    end,
    name = "sc_con_fe",
    desc = "Captura datos del comando sc con fe"
  },
}

stats.key_bindings = {
  {
    modifiers = mudlet.keymodifier.Alt,
    key = mudlet.key.Backslash,
    action = function()
      local oceano = RhomScripts and RhomScripts.modules and RhomScripts.modules.oceano
      local movimiento = RhomScripts and RhomScripts.modules and RhomScripts.modules.movimiento
      if oceano and oceano.salidas_marinero ~= "" then
        lector.decir(oceano.salidas_marinero)
      elseif stats.salidas ~= "" then
        local extra = movimiento and movimiento.salidas_especiales or ""
        lector.decir(stats.salidas .. (extra ~= "" and ". " .. extra or ""))
      else
        lector.decir("No hay salidas registradas")
      end
    end,
    name = "Alt+\\",
    desc = "Lee salidas"
  },
  {
    modifiers = mudlet.keymodifier.Alt + mudlet.keymodifier.Shift,
    key = mudlet.key.Backslash,
    action = function()
      lector.copiar(stats.salidas, "Salidas copiadas")
    end,
    name = "Alt+Shift+\\",
    desc = "Copia salidas"
  },
  {
    modifiers = mudlet.keymodifier.Alt,
    key = mudlet.key["1"],
    action = function()
      lector.decir(string.format("%s(%s)", stats.pvs, stats.pvs_max))
    end,
    name = "Alt+1",
    desc = "Lee vida"
  },
  {
    modifiers = mudlet.keymodifier.Alt + mudlet.keymodifier.Shift,
    key = mudlet.key["1"],
    action = function()
      lector.copiar(stats.pvs .. "\\" .. stats.pvs_max, "Vida copiada")
    end,
    name = "Alt+Shift+1",
    desc = "Copia vida"
  },
  {
    modifiers = mudlet.keymodifier.Alt,
    key = mudlet.key["2"],
    action = function()
      local partes = {}
      if stats.pieles and tonumber(stats.pieles) and tonumber(stats.pieles) > 0 then
        table.insert(partes, tostring(stats.pieles) .. " Pieles")
      end
      if stats.imagenes and tonumber(stats.imagenes) and tonumber(stats.imagenes) > 0 then
        table.insert(partes, tostring(stats.imagenes) .. " Imagenes")
      end
      table.insert(partes, string.format("%s(%s)", stats.pe, stats.pe_max))
      if stats.fe then
        table.insert(partes, "Fe: " .. tostring(stats.fe))
      end
      lector.decir(table.concat(partes, ". "))
    end,
    name = "Alt+2",
    desc = "Lee energia"
  },
  {
    modifiers = mudlet.keymodifier.Alt + mudlet.keymodifier.Shift,
    key = mudlet.key["2"],
    action = function()
      lector.copiar(stats.pe .. "\\" .. stats.pe_max, "Energia copiada")
    end,
    name = "Alt+Shift+2",
    desc = "Copia energia"
  },
  {
    modifiers = mudlet.keymodifier.Alt,
    key = mudlet.key["0"],
    action = function()
      lector.decir("XP: " .. tostring(stats.xp) .. ". Puntos de oficio: " .. tostring(stats.po))
    end,
    name = "Alt+0",
    desc = "Lee XP y puntos de oficio"
  },
  {
    modifiers = mudlet.keymodifier.Shift,
    key = mudlet.key.F6,
    action = function()
      stats.mostrar_historial_cpvs()
    end,
    name = "Shift+F6",
    desc = "Muestra historial de PVS"
  },
  {
    key = mudlet.key.F6,
    action = function()
      lector.decir(stats.ultimo_cpvs and tostring(stats.ultimo_cpvs) or "No has recibido dano por el momento")
    end,
    name = "F6",
    desc = "Lee ultimo dano recibido"
  },
  {
    key = mudlet.key.F2,
    action = function()
      lector.decir(stats.ultimo_enemigo ~= "" and stats.ultimo_enemigo or "No has visto a ningun enemigo recientemente")
    end,
    name = "F2",
    desc = "Lee ultimo enemigo"
  },
  {
    modifiers = mudlet.keymodifier.Shift + mudlet.keymodifier.Alt,
    key = mudlet.key.F2,
    action = function()
      lector.copiar(stats.ultimo_enemigo, "Enemigos copiados")
    end,
    name = "Shift+Alt+F2",
    desc = "Copia ultimo enemigo"
  },
  {
    key = mudlet.key.F3,
    action = function()
      lector.decir(stats.ultimo_aliado ~= "" and stats.ultimo_aliado or "No has visto a ningun aliado recientemente")
    end,
    name = "F3",
    desc = "Lee ultimo aliado"
  },
  {
    modifiers = mudlet.keymodifier.Shift + mudlet.keymodifier.Alt,
    key = mudlet.key.F3,
    action = function()
      lector.copiar(stats.ultimo_aliado, "Aliados copiados")
    end,
    name = "Shift+Alt+F3",
    desc = "Copia ultimo aliado"
  },
}

return stats
