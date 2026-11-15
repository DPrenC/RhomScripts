-------------------------------------------------------------------------------
-- Modulo: emociones
-- Migracion funcional desde Emociones.set.
-------------------------------------------------------------------------------

local audio = require("audio")

local emociones = {}

local function trim(text)
  if type(text) ~= "string" then
    return ""
  end
  return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function word_count(text)
  local count = 0
  for _ in trim(text):gmatch("%S+") do
    count = count + 1
  end
  return count
end

function emociones.reproducir(sujeto, sonido)
  if word_count(sujeto) > 1 then
    return
  end
  audio.play("RL/Emociones/Emocion.wav", { volume = 70 })
  audio.play("RL/Emociones/" .. sonido, { volume = 85 })
end

local rules = {
  { "^(.+) te besa.*\\.$", "Beso1.wav" },
  { "^(.+) te da un morreo .*\\.$", "Beso2.wav" },
  { "^(.+) te da un profundo.*beso.*$", "Beso2.wav" },
  { "^(.+) te besa en el cuello.*$", "Beso1.wav" },
  { "^(.+) te dice adios.*\\.$", "Adios.wav" },
  { "^(.+) te saluda.*\\.$", "Hola.wav" },
  { "^(.+) te echa mas polvos que un polvero\\.$", "Polvazo.wav" },
  { "^Oyes sonar tu timbre.*ver a (.+) huir.*$", "Huir.wav" },
  { "^(.+) te frota por el lado que no es\\.$", "Frotar.wav" },
  { "^(.+) te hace B O N K ! en la cabeza\\.$", "Bonk.wav" },
  { "^(.+) te da un susto de muerte\\.$", "Asustar.wav" },
  { "^(.+) te lame.*\\.$", "Lamer.wav" },
  { "^(.+) te espera.*\\.$", "Esperar.wav" },
  { "^(.+)  se rie de ti\\.$", "Reir.wav" },
  { "^(.+) se descojona de ti.*$", "Descojonarse.wav" },
  { "^(.+) te tira de la manga.*$", "Tirar*2.wav" },
  { "^(.+) te muerde.*\\.$", "Morder.wav" },
  { "^(.+) salta encima de ti\\.$", "Saltar.wav" },
  { "^(.+) te escupe\\.$", "Escupir.wav" },
  { "^(.+) te hace ascos\\.$", "Asqueado.wav" },
  { "^(.+) te pincha .*\\.$", "Pincha.wav" },
  { "^(.+) te echa encima hasta la primera papilla\\.$", "Vomitar.wav" },
  { "^(.+) te saca la lengua\\.$", "Sacalengua.wav" },
  { "^(.+) te dice que no tiene sociales\\.$", "Nosoc.wav" },
  { "^(.+) niega todo lo que has dicho\\.$", "Negar*2.wav" },
  { "^(.+) te hace mimos\\.$", "Mimos.wav" },
  { "^(.+) te anima.*\\.$", "Animar*2.wav" },
  { "^(.+) descarga su furia sobre ti.*bofetada.*$", "Bofetada*2.wav" },
  { "^(.+) te idolatra\\.$", "Idolatra*2.wav" },
  { "^.*Menuda colleja acaba de soltarte (.+)!$", "Colleja.wav" },
  { "^(.+) te propina un soberano pu.etazo en la cara\\.$", "Punetazo.wav" },
  { "^(.+) te patea el culo\\.$", "Patada.wav" },
}

emociones.triggers = {}

for index, rule in ipairs(rules) do
  table.insert(emociones.triggers, {
    pattern = rule[1],
    action = function()
      emociones.reproducir(matches[2], rule[2])
    end,
    name = "emocion_" .. index,
    desc = "Sonido de emocion"
  })
end

return emociones
