-------------------------------------------------------------------------------
-- Modulo: npcs
-- Migracion funcional desde NPCs.set.
-------------------------------------------------------------------------------

local audio = require("audio")
local eventos = require("eventos")

local npcs = {
  activos = {
    lessirnak = false,
    mergan = false,
    lish = false,
  }
}

local function play(path)
  audio.play(path, { volume = 85 })
end

local function evento(text)
  eventos.registrar(text)
end

local rules = {
  { "^.*Lessirnak, el Gran Wyrm Infernal aterriza.*crater.*$", "RL/NPCS/Lessirnak/Aterrizaje.wav" },
  { "^.*Estas siendo atacad. por Lessirnak, el Gran Wyrm Infernal\\.$", "RL/NPCs/Lessirnak/Atacando.wav", "lessirnak", true },
  { "^.*Lessirnak, el Gran Wyrm Infernal salta sobre ti.*$", "RL/NPCs/Lessirnak/Llegada.wav", nil, nil, "RL/Combate/Stun propio.wav" },
  { "^.*Lessirnak, el Gran Wyrm Infernal llega a la sala.*$", "RL/NPCs/Lessirnak/Llegada.wav" },
  { "^Lessirnak, el Gran Wyrm Infernal abre sus fauces.*$", "RL/NPCs/Lessirnak/Aliento amenaza.wav" },
  { "^Lessirnak, el Gran Wyrm Infernal levanta el vuelo.*$", "RL/NPCs/Lessirnak/Vuelo.wav", nil, nil, "RL/NPCS/Lessirnak/Rugido aliento.wav" },
  { "^Lessirnak, el Gran Wyrm Infernal bate sus alas.*$", "RL/NPCs/Lessirnak/Vuelo.wav" },
  { "^.*Lessirnak, el Gran Wyrm Infernal pasa.*vuelo rasante.*$", "RL/NPCs/Lessirnak/Vuelo rasante.wav" },
  { "^Lessirnak, el Gran Wyrm Infernal aterriza de nuevo.*$", "RL/NPCS/Lessirnak/Aterrizaje.wav" },
  { "^.*Eres electrocutado por el infierno.*Lessirnak.*$", "RL/NPCs/Lessirnak/Impacto aliento electrico.wav", nil, nil, nil, true },
  { "^.*Ardes bajo el fuego infernal de Lessirnak.*$", "RL/NPCs/Lessirnak/Impacto aliento fuego.wav", nil, nil, nil, true },
  { "^.*Sucumbes ante el infierno de acido.*Lessirnak.*$", "RL/NPCs/Lessirnak/Impacto aliento acido *2.wav", nil, nil, nil, true },
  { "^.*Lessirnak, el Gran Wyrm Infernal se alza.*$", "RL/NPCS/Lessirnak/Rugido atrapar 1.wav" },
  { "^Lessirnak, el Gran Wyrm Infernal atrapa.*$", "RL/NPCS/Lessirnak/Rugido atrapar 2.wav", nil, nil, "RL/NPCs/Lessirnak/Vuelo.wav" },
  { "^Ves como Lessirnak.* suelta a .* en lo alto.*$", "RL/NPCS/Lessirnak/Caida 1.wav" },
  { "^.* cae al suelo con un .* crujir de huesos.*$", "RL/NPCS/Lessirnak/Caida 2.wav", nil, nil, nil, false, true },
  { "^Lessirnak, el Gran Wyrm Infernal se detiene.*embelesado.*$", "RL/NPCS/Lessirnak/Embelesado.wav" },
  { "^Lessirnak, el Gran Wyrm Infernal empieza a aburrirse.*$", "RL/NPCS/Lessirnak/Aburrido*6.wav" },
  { "^Cria de Dragon Infernal abre sus fauces.*$", "RL/NPCs/Lessirnak/Cria amenaza.wav" },
  { "^.*Ardes bajo el fuego infernal de Cria de Dragon Infernal.*$", "RL/NPCs/Lessirnak/Cria aliento fuego.wav", nil, nil, nil, true },
  { "^.*Eres electrocutado por el infierno.*Cria de Dragon Infernal.*$", "RL/NPCs/Lessirnak/Cria aliento electrico.wav", nil, nil, nil, true },
  { "^.*Sucumbes ante el infierno de acido.*Cria de Dragon Infernal.*$", "RL/NPCs/Lessirnak/Cria aliento acido.wav", nil, nil, nil, true },
  { "^.*crias de dragon infernal emergen.*$", "RL/NPCs/Lessirnak/Crias spawn.wav", nil, nil, nil, false, true },
  { "^Cria de Dragon Infernal esta aqui\\.$", "RL/NPCs/Lessirnak/Cria *2.wav" },
  { "^.*crias de Dragon Infernal estan aqui\\.$", "RL/NPCs/Lessirnak/Cria *2.wav" },
  { "^Cria de Dragon Infernal cae al suelo sin vida\\.$", "RL/NPCs/Lessirnak/Cria muerte *2.wav" },
  { "^Lessirnak, el Gran Wyrm Infernal cae al suelo sin vida\\.$", "RL/NPCs/Lessirnak/Muerte.wav", "lessirnak", false },
  { "^Paras de perseguir a Lessirnak.*$", nil, "lessirnak", false },
  { "^.*Estas siendo atacad. por Mergandevinasander.*$", "RL/NPCs/Mergan/Atacando.wav", "mergan", true },
  { "^Mergandevinasander.*abre sus fauces.*$", "RL/NPCS/Mergan/Aliento amenaza.wav" },
  { "^Mergandevinasander.*cae al suelo sin vida\\.$", "RL/NPCS/Mergan/Muerte.wav", "mergan", false },
  { "^Paras de perseguir a Mergandevinasander.*$", nil, "mergan", false },
  { "^.*Estas siendo atacad. por Lish.*$", "RL/NPCs/Lish/Atacando.wav", "lish", true },
  { "^Lish la Aborrecible.*abre sus fauces.*$", "RL/NPCS/Lish/Aliento amenaza.wav" },
  { "^El gutural sonido de una poderosa inspiracion.*$", "RL/NPCs/Lish/Inspiracion.wav" },
  { "^Lish la Aborrecible.*Infierno al expirar.*$", "RL/NPCS/Lish/Aliento*2.wav" },
  { "^.*Lish la Aborrecible.*golpea las paredes.*$", "RL/NPCs/Lish/Ataque final.wav" },
  { "^Lish la Aborrecible.*cae al suelo sin vida\\.$", "RL/NPCS/Lish/Muerte.wav", "lish", false },
  { "^Paras de perseguir a Lish.*$", nil, "lish", false },
  { "^Un escalofriante gemido proveniente del norte.*$", "RL/NPCs/Anarcam alerta cacofonia.wav" },
  { "^.*torrente de almas condenadas llega.*$", "RL/NPCs/Anarcam impacto cacofonia.wav" },
  { "^.*Huevo de Hidra Marina se rompe.*$", "RL/NPCs/Hidras/Nace cria.wav" },
  { "^El lugar por donde la cabeza.*sutura.*$", "RL/NPCs/Hidras/Sutura herida.wav" },
  { "^Rebanas una de las cabezas de la hidra\\.$", "RL/NPCs/Hidras/Rebanas cabeza.wav" },
  { "^La hidra cae abatida.*$", "RL/NPCs/Hidras/Muerte.wav" },
  { "^.*La hidra te golpea brutalmente con su cola\\.$", "RL/NPCs/Hidras/Coletazo.wav" },
  { "^.*Das un salto esquivando la cola.*$", "RL/NPCs/Hidras/Coletazo falla.wav" },
  { "^El troll se interpone en tu camino.*$", "RL/NPCs/trolls/troll grunido.wav" },
  { "^Troll esta aqui\\.$", "RL/NPCs/trolls/troll aquí.wav" },
  { "^Troll coge el palo.*$", "RL/NPCs/trolls/troll coge palo.wav" },
  { "^Ves un par de pedruscos volando.*$", "RL/NPCs/trolls/troll voraz grunido.wav" },
  { "^Troll Voraz esta aqui\\.$", "RL/NPCs/trolls/troll voraz aquí.wav" },
  { "^Al ser impactado por la luz del Sol, el Troll.*$", "RL/NPCs/trolls/troll voraz muere.wav" },
}

npcs.triggers = {}

for index, rule in ipairs(rules) do
  table.insert(npcs.triggers, {
    pattern = rule[1],
    action = function()
      if rule[3] then
        npcs.activos[rule[3]] = rule[4] and true or false
      end
      if rule[7] then
        evento(line)
      end
      if rule[5] then
        play(rule[5])
      end
      if rule[2] then
        play(rule[2])
      end
      if rule[6] then
        local combate = RhomScripts and RhomScripts.modules and RhomScripts.modules.combate
        if combate and combate.dano_recibido then
          combate.dano_recibido()
        end
      end
    end,
    name = "npc_" .. index,
    desc = "Trigger de NPC especial"
  })
end

return npcs
