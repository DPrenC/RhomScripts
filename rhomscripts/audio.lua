local audio = {}

audio.master_volume = 100
audio.mono = false
audio.handles = {}

local function safe_call(fn, ...)
  if type(fn) == "function" then
    pcall(fn, ...)
  end
end

function audio.play(path, opts)
  if not path or path == "" then
    return nil
  end

  local handle
  if type(playSoundFile) == "function" then
    local ok, result = pcall(playSoundFile, path)
    if ok then
      handle = result
    end
  end

  if not handle then
    return nil
  end

  audio.handles[handle] = true

  local volume = audio.master_volume
  if opts and type(opts.volume) == "number" then
    volume = opts.volume
  end
  safe_call(setSoundVolume, handle, volume)

  local pan = 0
  if opts and type(opts.pan) == "number" then
    pan = opts.pan
  end
  audio.set_pan(handle, pan)

  return handle
end

function audio.stop(handle)
  if not handle then
    return
  end
  safe_call(stopSound, handle)
  audio.handles[handle] = nil
end

function audio.set_master(volume)
  if type(volume) ~= "number" then
    return
  end
  audio.master_volume = volume
  for handle, _ in pairs(audio.handles) do
    safe_call(setSoundVolume, handle, volume)
  end
end

function audio.set_pan(handle, pan)
  if not handle then
    return
  end
  if audio.mono then
    pan = 0
  end
  if type(pan) ~= "number" then
    pan = 0
  end
  safe_call(setSoundPan, handle, pan)
end

function audio.set_mono(on)
  audio.mono = not not on
  if audio.mono then
    for handle, _ in pairs(audio.handles) do
      safe_call(setSoundPan, handle, 0)
    end
  end
end

return audio
