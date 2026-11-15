-- Los ensayos locales de copia usan el doble; los reales no tocan el portapapeles.
local suite = {}
local function equal(actual, expected)
  assert(actual == expected, "Esperado " .. tostring(expected) .. "; obtenido " .. tostring(actual))
end

function suite.run(mock, case)
  local lector = RhomScripts.modules.lector
  local buffer, clipboard = mock.buffer, mock.clipboard
  local ok, message = pcall(function()
    mock.buffer = { "primera", "  segunda con espacios  ", "", "última" }
    case("Lector: orden relativo, espacios y blancos sin caché", function()
      equal(lector.leer_linea(), "última")
      equal(lector.leer_linea(2), "  segunda con espacios  ")
      equal(lector.buscar_linea(3), "primera")
      equal(lector.buscar_linea(4), nil)
      mock.buffer = {}
      equal(lector.buscar_linea(1), nil)
      mock.buffer = { "primera", "  segunda con espacios  ", "", "última" }
    end)
    case("Lector: nueve líneas con blancos entre bloques y al final", function()
      mock.buffer = {}
      for index = 9, 1, -1 do
        mock.buffer[#mock.buffer + 1] = "  contenido " .. index .. "  "
        for _ = 1, 70 do mock.buffer[#mock.buffer + 1] = " \t " end
      end
      for index = 1, 9 do
        equal(lector.buscar_linea(index), "  contenido " .. index .. "  ")
      end
      equal(lector.buscar_linea(10), nil)
      mock.buffer = { "", " \t ", "" }
      mock.clipboard = "conservar"
      equal(lector.leer_linea(1), nil)
      equal(mock.announcements[#mock.announcements], "No hay línea disponible")
      equal(lector.copiar_linea(1), nil)
      equal(mock.clipboard, "conservar")
      mock.buffer = { "primera", "  segunda con espacios  ", "", "última" }
    end)
    case("Lector: copia exacta, sonido del catálogo y blancos", function()
      equal(lector.copiar_linea(2), "  segunda con espacios  ")
      equal(mock.clipboard, "  segunda con espacios  ")
      assert(mock.sounds["rhom:catalogo:ui.portapapeles"])
      equal(lector.copiar_linea(3), "primera")
      equal(mock.clipboard, "primera")
      equal(mock.announcements[#mock.announcements], "Copiado")
    end)
    case("Lector: copia una sola vez y solicita texto, sonido y Copiado en ese orden", function()
      local audio = RhomScripts.soporte.audio
      local original_clipboard, original_announce, original_audio = setClipboardText, announce, audio.reproducir
      local calls = {}
      setClipboardText = function(text)
        calls[#calls + 1] = "portapapeles:" .. text
        return original_clipboard(text)
      end
      announce = function(text)
        calls[#calls + 1] = "voz:" .. text
        return original_announce(text)
      end
      audio.reproducir = function(key, options)
        calls[#calls + 1] = "sonido:" .. key
        return original_audio(key, options)
      end
      local success, err = pcall(lector.copiar_linea, 2)
      setClipboardText, announce, audio.reproducir = original_clipboard, original_announce, original_audio
      assert(success, err)
      equal(#calls, 4)
      equal(calls[1], "portapapeles:  segunda con espacios  ")
      equal(calls[2], "voz:  segunda con espacios  ")
      equal(calls[3], "sonido:ui.portapapeles")
      equal(calls[4], "voz:Copiado")
      equal(mock.clipboard, "  segunda con espacios  ")
    end)
    case("Lector: nueve códigos españoles ejecutan copia y solicitan su sonido", function()
      mock.buffer = {}
      for index = 9, 1, -1 do
        mock.buffer[#mock.buffer + 1] = "  línea " .. index .. "  "
        mock.buffer[#mock.buffer + 1] = ""
      end
      for index, codigo in ipairs({ 33, 34, 183, 36, 37, 38, 47, 40, 41 }) do
        mock.sounds["rhom:catalogo:ui.portapapeles"] = nil
        mock.key(mudlet.keymodifier.Control + mudlet.keymodifier.Shift, codigo)
        equal(mock.clipboard, "  línea " .. index .. "  ")
        equal(mock.announcements[#mock.announcements], "Copiado")
        assert(mock.sounds["rhom:catalogo:ui.portapapeles"])
      end
      mock.buffer = { "primera", "  segunda con espacios  ", "", "última" }
    end)
    case("Lector: sin catálogo de sonidos la copia y el anuncio siguen disponibles", function()
      local sonidos = RhomScripts.soporte.sonidos
      local catalogo = sonidos.catalogo
      sonidos.catalogo = nil
      local success, err = pcall(lector.copiar_linea, 1)
      sonidos.catalogo = catalogo
      assert(success, err)
      equal(mock.clipboard, "última")
      equal(mock.announcements[#mock.announcements], "Copiado")
    end)
    case("Lector: índices inválidos o ausentes no copian ni anuncian éxito", function()
      mock.clipboard = "conservar"
      for _, index in ipairs({ 0, -1, 1.5, math.huge, -math.huge, 0/0, "incorrecto", 100 }) do
        equal(lector.copiar_linea(index), nil)
        equal(mock.clipboard, "conservar")
        assert(mock.announcements[#mock.announcements] ~= "Copiado")
      end
    end)
    case("Lector: comandos leerlinea y copiarlinea usan el índice solicitado", function()
      mock.alias("leerlinea 2")
      equal(mock.announcements[#mock.announcements], "  segunda con espacios  ")
      mock.alias("copiarlinea 3")
      equal(mock.clipboard, "primera")
    end)
    case("Lector: APIs ausentes propagan error sin aviso de copia correcta", function()
      for _, test in ipairs({
        { "getLastLineNumber", function() lector.buscar_linea(1) end },
        { "getLines", function() lector.buscar_linea(1) end },
        { "setClipboardText", function() lector.copiar_linea(1) end },
        { "announce", function() lector.leer_linea(1) end },
        { "playSoundFile", function() lector.copiar_linea(1) end },
      }) do
        local original = _G[test[1]]
        _G[test[1]] = nil
        local success = pcall(test[2])
        _G[test[1]] = original
        assert(not success, "Se ocultó " .. test[1])
      end
    end)
  end)
  mock.buffer, mock.clipboard = buffer, clipboard
  assert(ok, message)
end

function suite.real(case)
  local lector = RhomScripts.modules.lector
  case("Lector real: última línea sin salto y orden de nueve líneas", function()
    echo("\n")
    for index = 9, 2, -1 do echo("Lector real " .. index .. "\n\n \t \n") end
    echo("Lector real 1")
    for index = 1, 9 do equal(lector.buscar_linea(index), "Lector real " .. index) end
    equal(lector.leer_linea(1), "Lector real 1")
  end)
  case("Lector real: salto final y blancos no cuentan; conserva espacios", function()
    echo("\n  espacios conservados  \n\n")
    equal(lector.leer_linea(1), "  espacios conservados  ")
    equal(lector.buscar_linea(2), "Lector real 1")
    equal(lector.buscar_linea(getLastLineNumber("main") + 2), nil)
  end)
  case("Lector real: sonido de copia desde el catálogo sin tocar portapapeles", function()
    local audio = RhomScripts.soporte.audio
    local original_play, received = playSoundFile, nil
    playSoundFile = function(settings)
      received = settings.name
      return original_play(settings)
    end
    local success, key = pcall(audio.reproducir, "ui.portapapeles")
    playSoundFile = original_play
    assert(success, key)
    assert(key, "No está disponible el sonido de copia")
    equal(received, RhomScripts.soporte.sonidos.catalogo.sonidos["ui.portapapeles"].archivos[1])
    audio.stop(key)
  end)
  case("Lector real: texto recibido con feedTriggers", function()
    assert(feedTriggers("Lector recibido alfa\nLector recibido beta\n"))
    equal(lector.leer_linea(1), "Lector recibido beta")
    equal(lector.buscar_linea(2), "Lector recibido alfa")
  end)
end
return suite
