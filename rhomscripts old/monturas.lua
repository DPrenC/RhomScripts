-------------------------------------------------------------------------------
-- Modulo: monturas
-- Migracion funcional desde Monturas.set.
-------------------------------------------------------------------------------

local audio = require("audio")
local config = require("config")
local lector = require("lector")

local monturas = {}

monturas.montado = false
monturas.galopando = false

local function play(path)
  audio.play(path, { volume = 80 })
end

local function set_montado(value)
  monturas.montado = value and true or false
  config.set("montado", monturas.montado)
end

local function set_galopando(value)
  monturas.galopando = value and true or false
  config.set("galopando", monturas.galopando)
end

local function salidas()
  local stats = RhomScripts and RhomScripts.modules and RhomScripts.modules.stats
  return stats and stats.salidas or ""
end

monturas.triggers = {
  {
    pattern = "^.*Tiras de las riendas de .* haciendo que te siga\\.$",
    action = function()
      play("RL/Monturas/Riendas*5.wav")
    end,
    name = "montura_riendas",
    desc = "Sonido de riendas"
  },
  {
    pattern = "^Empiezas a montar en .+\\.$",
    action = function()
      play("RL/Monturas/Montar inicio.wav")
    end,
    name = "montura_montar_inicio",
    desc = "Inicio de montar"
  },
  {
    pattern = "^Montas en .+\\.$",
    action = function()
      set_montado(true)
      play("RL/Monturas/Montar terminar.wav")
    end,
    name = "montura_montar_fin",
    desc = "Fin de montar"
  },
  {
    pattern = "^Comienzas a galopar en direccion .+\\.$",
    action = function()
      set_galopando(true)
      play("RL/Monturas/Espoleas.wav")
    end,
    name = "montura_galope_inicio",
    desc = "Inicio de galope"
  },
  {
    pattern = "^Te detienes para poder decidir el camino a seguir\\.$",
    action = function()
      set_galopando(false)
      play("RL/Monturas/Galope propio detenido.wav")
      if salidas() ~= "" then
        lector.decir(salidas())
      end
    end,
    name = "montura_galope_detiene",
    desc = "Galope detenido"
  },
  {
    pattern = "^Tu .* aterriza para que decidas el camino a seguir\\.$",
    action = function()
      set_galopando(false)
      play("RL/Monturas/Galope propio detenido.wav")
    end,
    name = "montura_aterriza",
    desc = "Montura aterriza"
  },
  {
    pattern = "^Se ha acabado el camino es imposible seguir adelante\\.$",
    action = function()
      set_galopando(false)
      play("RL/Monturas/Galope propio detenido.wav")
    end,
    name = "montura_camino_fin",
    desc = "Galope bloqueado"
  },
  {
    pattern = "^Tiras de .* obligandole a frenar\\.$",
    action = function()
      set_galopando(false)
      play("RL/Monturas/Galope propio detenido.wav")
    end,
    name = "montura_frenar",
    desc = "Frena montura"
  },
  {
    pattern = "^Tiras de las riendas a la vez que frenas a .+\\.$",
    action = function()
      set_galopando(false)
      play("RL/Monturas/Galope propio detenido.wav")
    end,
    name = "montura_frenar_riendas",
    desc = "Frena con riendas"
  },
  {
    pattern = "^Empiezas a desmontar tu .+\\.$",
    action = function()
      play("RL/Monturas/Desmontar inicio.wav")
    end,
    name = "montura_desmontar_inicio",
    desc = "Inicio desmontar"
  },
  {
    pattern = "^Desmontas de tu .+\\.$",
    action = function()
      set_montado(false)
      set_galopando(false)
      play("RL/Monturas/Desmontar terminar.wav")
    end,
    name = "montura_desmontar_fin",
    desc = "Fin desmontar"
  },
}

return monturas
