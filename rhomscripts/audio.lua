-------------------------------------------------------------------------------
-- Modulo: audio
-- Dominio migrado desde VIPMud: Funciones.set, start.set y usos #Play/#PlayLoop.
--
-- Esta API centraliza la reproduccion de sonidos para que el resto de modulos no
-- dependan de detalles de rutas, volumenes, loops o paneo. La migracion conserva
-- la intencion de FuncPlayPan: sonido centrado en modo mono, paneo aproximado en
-- modo estereo y recuerdo del ultimo paneo usado.
-------------------------------------------------------------------------------

local audio = {}

audio.master_volume = 100
audio.mono = false
audio.last_pan = 0
audio.default_tag = "rhomscripts"
audio.active = {}

local function clamp(value, min_value, max_value)
  if value < min_value then
    return min_value
  end
  if value > max_value then
    return max_value
  end
  return value
end

local function normalize_slashes(path)
  return (path:gsub("\\", "/"))
end

local function normalize_pan(pan)
  if type(pan) ~= "number" then
    return 0
  end

  -- VIPMud usaba valores amplios como -5000..5000. Mudlet trabaja mejor con
  -- rangos pequenos, asi que se conserva la direccion y se aproxima la fuerza.
  if math.abs(pan) > 100 then
    pan = pan / 50
  end

  return clamp(pan, -100, 100)
end

local function is_absolute(path)
  return path:match("^/") or path:match("^%a:[/\\]")
end

local function file_exists(path)
  local file = io.open(path, "rb")
  if file then
    file:close()
    return true
  end
  return false
end

local function variant_paths(path)
  local prefix, count, ext = path:match("^(.-)%*(%d+)(%.[^./\\]+)$")
  count = tonumber(count)
  if not prefix or not count or count < 1 then
    return { path }
  end

  local index = math.random(count)
  local candidates = { prefix .. index .. ext }
  if not prefix:match("%s$") then
    candidates[#candidates + 1] = prefix .. " " .. index .. ext
  end
  return candidates
end

local function profile_root()
  if type(getMudletHomeDir) == "function" and type(getProfileName) == "function" then
    return string.format("%s/profiles/%s", getMudletHomeDir(), getProfileName())
  end
  return "."
end

local function candidate_roots()
  local profile = profile_root()
  return {
    profile .. "/media",
    profile .. "/sounds",
    profile .. "/rhomscripts/sounds",
    profile .. "/rhomscripts/../sounds",
    ".",
    "./sounds",
  }
end

local function build_key(path, opts)
  if opts and opts.key then
    return opts.key
  end
  return "rhom:" .. normalize_slashes(path)
end

function audio.resolve(path)
  if type(path) ~= "string" or path == "" then
    return nil
  end

  local variants = variant_paths(normalize_slashes(path))
  local normalized = variants[1]
  if is_absolute(normalized) or normalized:match("^https?://") then
    return normalized
  end

  if normalized:match("^sounds/") then
    for _, variant in ipairs(variants) do
      if file_exists(variant) then
        return variant
      end
    end
    return normalized:gsub("^sounds/", "")
  end

  for _, root in ipairs(candidate_roots()) do
    for _, variant in ipairs(variants) do
      local candidate = normalize_slashes(root .. "/" .. variant)
      if file_exists(candidate) then
        return candidate
      end

      candidate = normalize_slashes(root .. "/sounds/" .. variant)
      if file_exists(candidate) then
        return candidate
      end
    end
  end

  -- Si el archivo esta empaquetado en la carpeta media de Mudlet, la ruta
  -- relativa es suficiente para playSoundFile().
  return normalized
end

function audio.settings(path, opts)
  opts = opts or {}
  local volume = opts.volume or audio.master_volume
  local loops = opts.loop and -1 or opts.loops or 1

  return {
    name = audio.resolve(path),
    volume = clamp(volume, 1, 100),
    loops = loops,
    key = build_key(path, opts),
    tag = opts.tag or audio.default_tag,
    priority = opts.priority,
    fadein = opts.fadein,
    fadeout = opts.fadeout,
  }
end

function audio.play(path, opts)
  if type(path) ~= "string" or path == "" then
    return nil
  end

  local settings = audio.settings(path, opts)
  local handle = playSoundFile(settings)
  audio.active[settings.key] = {
    path = path,
    settings = settings,
    handle = handle,
  }

  local pan = audio.mono and 0 or normalize_pan(opts and opts.pan or audio.last_pan)
  audio.last_pan = pan

  -- Mudlet documenta playSoundFile/stopSounds como API moderna. Algunas
  -- instalaciones exponen tambien setSoundPan para paneo; se usa si existe.
  if handle and type(setSoundPan) == "function" then
    pcall(setSoundPan, handle, pan)
  end

  return settings.key
end

function audio.play_pan(path, pan, opts)
  opts = opts or {}
  opts.pan = pan
  return audio.play(path, opts)
end

function audio.loop(path, opts)
  opts = opts or {}
  opts.loop = true
  return audio.play(path, opts)
end

function audio.stop(key_or_opts)
  local settings
  if type(key_or_opts) == "table" then
    settings = key_or_opts
  elseif type(key_or_opts) == "string" then
    settings = { key = key_or_opts }
  else
    return
  end

  stopSounds(settings)
  if settings.key then
    audio.active[settings.key] = nil
  end
end

function audio.stop_tag(tag)
  stopSounds({ tag = tag or audio.default_tag })
  if not tag or tag == audio.default_tag then
    audio.active = {}
  end
end

function audio.set_master(volume)
  if type(volume) ~= "number" then
    return
  end
  audio.master_volume = clamp(volume, 1, 100)
end

function audio.set_mono(on)
  audio.mono = not not on
end

function audio.portapapeles()
  audio.play("RL/Generales/Portapapeles.wav", { volume = 80, key = "rhom:clipboard" })
end

function audio.lista()
  audio.play("RL/Generales/Lista.wav", { volume = 80, key = "rhom:lista" })
end

function audio.scroll()
  audio.play("RL/Generales/Scroll.wav", { volume = 75, key = "rhom:scroll" })
end

function audio.error()
  audio.play("RL/Generales/Error.wav", { volume = 80, key = "rhom:error" })
end

audio.aliases = {
  {
    pattern = "^music\\s+(.+)$",
    action = function()
      audio.loop(matches[2], { volume = 50, key = "rhom:music" })
    end,
    name = "music",
    desc = "Reproduce musica en bucle"
  },
  {
    pattern = "^StopMusic$",
    action = function()
      audio.stop("rhom:music")
    end,
    name = "StopMusic",
    desc = "Detiene la musica en bucle"
  },
}

return audio
