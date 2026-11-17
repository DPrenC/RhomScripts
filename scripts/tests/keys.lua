-- luacheck: globals print
-- Suite compartida: APIs reales en Mudlet; doble explícito en Lua 5.1/LuaJIT.
-- Los callbacks registrados se invocan directamente; no prueba teclado físico.
local suite = {}

local function equal(actual, expected)
  assert(actual == expected, "Esperado " .. tostring(expected) .. "; obtenido " .. tostring(actual))
end

function suite.run(path, case)
  local original_temp, original_kill, original_announce = tempKey, killKey, announce
  local saved_modules = RhomScripts.modules
  local callbacks, announcements = {}, {}
  local keys = dofile(path)
  local function count()
    local total = 0
    for _ in pairs(callbacks) do total = total + 1 end
    return total
  end
  tempKey = function(modifier, code, action)
    if action == nil then action, code, modifier = code, modifier, 0 end
    local id = original_temp(modifier, code, action)
    callbacks[id] = { modifier = modifier, code = code, action = action }
    return id
  end
  killKey = function(id)
    local result = original_kill(id)
    callbacks[id] = nil
    return result
  end
  announce = function(text)
    announcements[#announcements + 1] = text
    return original_announce(text)
  end
  local function press(modifier, code)
    local found
    for _, binding in pairs(callbacks) do
      if binding.modifier == modifier and binding.code == code then
        assert(not found, "Combinación duplicada")
        found = binding.action
      end
    end
    assert(found, "Combinación no registrada")
    found()
  end
  local control, shift = mudlet.keymodifier.Control, mudlet.keymodifier.Shift
  -- Códigos recibidos con Ctrl+Mayús+1…9 en español de España.
  local copia_es = { 33, 34, 183, 36, 37, 38, 47, 40, 41 }
  local calls = 0
  local function entry(name, code, modifiers)
    return {
      combinacion = { tecla = code, modificadores = modifiers or {} },
      nombre = name, funcion = function() calls = calls + 1 end,
      descripcion = "Descripción " .. name, grupo = "prueba",
    }
  end
  local ok, message = pcall(function()
    RhomScripts.modules = { keys = keys, antiguo = {
      key_bindings = {{ key = mudlet.key.F7, action = function() error("Atajo antiguo ejecutado") end,
        name = "F7", desc = "No debe registrarse" }},
    } }
    case("Teclas: inicio ignora definiciones antiguas y registra solo ayuda", function()
      local summary = keys.registrar()
      equal(summary.errors, 0)
      equal(count(), 1)
      equal(keys.ayuda_activa(), false)
    end)
    case("Teclas: una tecla y combinaciones de dos y tres ejecutan la función", function()
      keys.registrar_modulo("prueba", {
        entry("prueba.simple", mudlet.key.F6),
        entry("prueba.doble", mudlet.key.F6, { control }),
        entry("prueba.triple", mudlet.key.F6, { control, shift }),
      })
      press(0, mudlet.key.F6)
      press(control, mudlet.key.F6)
      press(control + shift, mudlet.key.F6)
      equal(calls, 3)
    end)
    case("Teclas: ayuda anuncia descripción y su combinación permite salir", function()
      press(control + shift, mudlet.key.H)
      equal(keys.ayuda_activa(), true)
      for _, modifier in ipairs({ 0, control, control + shift }) do press(modifier, mudlet.key.F6) end
      equal(calls, 3)
      equal(announcements[#announcements - 2], "Descripción prueba.simple")
      equal(announcements[#announcements - 1], "Descripción prueba.doble")
      equal(announcements[#announcements], "Descripción prueba.triple")
      press(control + shift, mudlet.key.H)
      equal(keys.ayuda_activa(), false)
      press(control + shift, mudlet.key.F6)
      equal(calls, 4)
    end)
    case("Teclas: configurador publica Ctrl+Shift+C y la ayuda no abre la ventana", function()
      local configurador = saved_modules.configurador
      local pulsacion = configurador.pulsaciones[1]
      equal(pulsacion.nombre, "configurador.abrir")
      equal(pulsacion.funcion, configurador.abrir)
      equal(pulsacion.grupo, "sistema")
      local ventana = configurador.ventana
      local sesion = configurador.sesion
      keys.registrar_modulo("configurador", configurador.pulsaciones)
      press(control + shift, mudlet.key.H)
      press(control + shift, mudlet.key.C)
      equal(announcements[#announcements], "Abre el configurador nativo")
      equal(configurador.ventana, ventana)
      equal(configurador.sesion, sesion)
      press(control + shift, mudlet.key.H)
    end)
    case("Teclas: lector registra dieciocho combinaciones y la ayuda no lee ni copia", function()
      local lector = saved_modules.lector
      equal(#lector.pulsaciones, 18)
      keys.registrar_modulo("lector", lector.pulsaciones)
      local read, copy = lector.leer_linea, lector.copiar_linea
      local read_index, copy_index
      lector.leer_linea = function(index) read_index = index end
      lector.copiar_linea = function(index) copy_index = index end
      local success, err = pcall(function()
        for index = 1, 9 do
          press(control, mudlet.key[tostring(index)])
          equal(read_index, index)
          press(control + shift, copia_es[index])
          equal(copy_index, index)
        end
        press(control + shift, mudlet.key.H)
        read_index, copy_index = nil, nil
        for index = 1, 9 do
          local reading, copying = lector.pulsaciones[2 * index - 1], lector.pulsaciones[2 * index]
          equal(reading.grupo, "lectura")
          equal(copying.grupo, "lectura")
          press(control, mudlet.key[tostring(index)])
          equal(announcements[#announcements], reading.descripcion)
          press(control + shift, copia_es[index])
          equal(announcements[#announcements], copying.descripcion)
        end
        equal(read_index, nil)
        equal(copy_index, nil)
        press(control + shift, mudlet.key.H)
      end)
      lector.leer_linea, lector.copiar_linea = read, copy
      assert(success, err)
    end)
    case("Teclas: español conserva etiquetas y detecta colisiones por símbolo efectivo", function()
      local inventory = keys.consultar()
      for index = 1, 9 do
        local found = false
        for _, entry_info in ipairs(inventory) do
          if entry_info.combinacion == "Ctrl+Shift+" .. index
              and entry_info.nombre == "lector.copiar_linea_" .. index then found = true end
        end
        assert(found, "El inventario perdió la combinación numérica " .. index)
        local before = count()
        assert(not pcall(keys.registrar_modulo, "colision", {
          entry("colision.simbolo_" .. index, copia_es[index], { control, shift }),
        }))
        equal(count(), before)
        assert(not pcall(press, control + shift, mudlet.key[tostring(index)]),
          "Sigue registrado el código numérico que Qt no entrega")
      end
      local before = count()
      assert(not pcall(keys.registrar_modulo, "colision", {
        entry("colision.numero", mudlet.key["1"], { shift, control }),
      }))
      equal(count(), before)
    end)
    case("Teclas: Alt+Mayús con 1, 2 y 0 usa los símbolos del teclado español", function()
      local alt = mudlet.keymodifier.Alt
      local codigos = { ["1"] = 33, ["2"] = 34, ["0"] = 61 }
      for _, indice in ipairs({ "1", "2", "0" }) do
        local nombre = "prueba.alt_mayus_" .. indice
        keys.registrar_modulo("prueba", { entry(nombre, mudlet.key[indice], { alt, shift }) })
        local antes = calls
        press(alt + shift, codigos[indice])
        equal(calls, antes + 1)
        assert(not pcall(press, alt + shift, mudlet.key[indice]))
      end
    end)
    case("Teclas: Mayús+coma y Mayús+punto usan los símbolos del teclado español", function()
      local punctuation = {
        { tecla = mudlet.key.Comma, codigo = mudlet.key.Semicolon, nombre = "Comma" },
        { tecla = mudlet.key.Period, codigo = mudlet.key.Colon, nombre = "Period" },
      }
      for _, binding in ipairs(punctuation) do
        local name = "puntuacion." .. binding.nombre
        keys.registrar_modulo("puntuacion", { entry(name, binding.tecla, { control, shift }) })
        local before = calls
        press(control + shift, binding.codigo)
        equal(calls, before + 1)
        assert(not pcall(press, control + shift, binding.tecla))
        assert(not pcall(keys.registrar_modulo, "colision", {
          entry("colision." .. binding.nombre, binding.codigo, { control, shift }),
        }))
      end
      for _, binding in ipairs(punctuation) do
        local found = false
        for _, registered in ipairs(keys.consultar()) do
          if registered.combinacion == "Ctrl+Shift+" .. binding.nombre then found = true end
        end
        assert(found, "El inventario perdió la combinación de puntuación")
      end
    end)
    case("Teclas: colisiones de nombre y combinación se rechazan sin registrar el lote", function()
      local before = count()
      assert(not pcall(keys.registrar_modulo, "otro", {
        entry("otro.libre", mudlet.key.F7), entry("prueba.simple", mudlet.key.F8),
      }))
      equal(count(), before)
      assert(not pcall(keys.registrar_modulo, "otro", {
        entry("otro.colision", mudlet.key.F6, { shift, control }),
      }))
      equal(count(), before)
      assert(not pcall(keys.registrar_modulo, "otro", {
        entry("otro.reservada", mudlet.key.H, { control, shift }),
      }))
      equal(count(), before)
    end)
    case("Teclas: datos incorrectos y modificadores repetidos se rechazan", function()
      local before = count()
      local invalid = entry("prueba.invalida", mudlet.key.F9)
      invalid.funcion = "función inventada"
      assert(not pcall(keys.registrar_modulo, "prueba", { invalid }))
      assert(not pcall(keys.registrar_modulo, "prueba", {
        entry("prueba.repetida", mudlet.key.F9, { control, control }),
      }))
      assert(not pcall(keys.registrar_modulo, "prueba", {
        entry("prueba.cuatro", mudlet.key.F9, { control, shift, mudlet.keymodifier.Alt }),
      }))
      equal(count(), before)
    end)
    case("Teclas: announce y tempKey ausentes propagan error", function()
      local before = calls
      keys.establecer_ayuda(true)
      announce = nil
      local announced = pcall(press, 0, mudlet.key.F6)
      announce = function(text)
        announcements[#announcements + 1] = text
        return original_announce(text)
      end
      assert(not announced)
      equal(calls, before)
      keys.establecer_ayuda(false)
      local registration = tempKey
      tempKey = nil
      local registered = pcall(keys.registrar_modulo, "ausente", { entry("ausente.funcion", mudlet.key.F10) })
      tempKey = registration
      assert(not registered)
    end)
    case("Teclas: fallo de función se propaga y ayuda evita sus efectos", function()
      local failing = entry("prueba.fallo", mudlet.key.F11)
      failing.funcion = function() error("Fallo funcional deliberado") end
      keys.registrar_modulo("prueba", { failing })
      local executed, failure = pcall(press, 0, mudlet.key.F11)
      assert(not executed and tostring(failure):find("Fallo funcional deliberado", 1, true))
      keys.establecer_ayuda(true)
      press(0, mudlet.key.F11)
      equal(announcements[#announcements], "Descripción prueba.fallo")
      keys.establecer_ayuda(false)
    end)
    case("Teclas: fallo del segundo registro retira el primero del lote", function()
      local before = count()
      local registration, attempts = tempKey, 0
      tempKey = function(...)
        attempts = attempts + 1
        if attempts == 2 then error("Fallo de registro deliberado") end
        return registration(...)
      end
      local registered, failure = pcall(keys.registrar_modulo, "lote", {
        entry("lote.primera", mudlet.key.F8), entry("lote.segunda", mudlet.key.F9),
      })
      tempKey = registration
      assert(not registered and tostring(failure):find("Fallo de registro deliberado", 1, true))
      equal(attempts, 2)
      equal(count(), before)
      keys.registrar_modulo("lote", { entry("lote.primera", mudlet.key.F8) })
      equal(count(), before + 1)
    end)
    case("Teclas: retirada y doble registro no acumulan callbacks", function()
      keys.desregistrar()
      equal(count(), 0)
      RhomScripts.modules.prueba = { pulsaciones = { entry("prueba.descubierta", mudlet.key.F9) } }
      keys.registrar()
      equal(count(), 2)
      keys.registrar()
      equal(count(), 2)
      local before = calls
      press(0, mudlet.key.F9)
      equal(calls, before + 1)
      local removal = killKey
      killKey = nil
      local removed = pcall(keys.desregistrar)
      killKey = removal
      assert(not removed, "Se ocultó killKey ausente")
      keys.desregistrar()
      equal(count(), 0)
    end)
  end)
  -- Restaurar instrumentación incluso si una aserción falla; conservar el error.
  announce = original_announce
  tempKey = original_temp
  killKey = original_kill
  for id in pairs(callbacks) do original_kill(id) end
  RhomScripts.modules = saved_modules
  assert(ok, message)
end

return suite
