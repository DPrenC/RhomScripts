local lector = {}

-- ============================================================================
-- CONFIGURACIÓN DE ATAJOS DE TECLADO
-- ============================================================================
-- Los atajos se definen aquí pero son registrados por keys.lua
-- Formato requerido por keys.lua: modifiers debe ser un número (o nil)

lector.key_bindings = {
  -- Ctrl+1: Leer línea 1
  {
    modifiers = mudlet.keymodifier.Control,
    key = mudlet.key['1'],
    action = function() RhomScripts.modules.lector.leerLinea(1) end,
    name = "Ctrl+1",
    desc = "Leer línea 1"
  },

  -- Ctrl+Shift+1: Copiar línea 1
  {
    modifiers = mudlet.keymodifier.Control + mudlet.keymodifier.Shift,
    key = mudlet.key['2'],
    action = function() announce("jajeijoju") end,
    name = "Ctrl+Shift+1",
    desc = "Copiar línea 1"
  }
}

-- ============================================================================
-- FUNCIONES DEL MÓDULO
-- ============================================================================

-- Función para buscar línea
function lector.buscarLinea(numero)
  return "linea de prueba"
end

-- Función para leer línea
function lector.leerLinea(numero)
  announce(lector.buscarLinea(numero))
  return true
end

-- Función para copiar línea
function lector.copiarLinea(numero)
  announce("Copiando línea ")
  setClipboardText(lector.buscarLinea(numero))
  announce("Línea copiada")
  return true
end

-- Función de diagnóstico para verificar las teclas
function lector.diagnostico()
  print("\n=== Diagnóstico de Lector ===")
  print("Cantidad de teclas definidas: " .. #lector.key_bindings)

  for i, binding in ipairs(lector.key_bindings) do
    print(string.format("%d. %s - %s", i, binding.name, binding.desc))

    if type(binding.modifiers) == "table" then
      local mods = {}
      for _, mod in ipairs(binding.modifiers) do
        table.insert(mods, tostring(mod))
      end
      print("   Modificadores: [" .. table.concat(mods, ", ") .. "]")
    elseif binding.modifiers then
      print("   Modificadores: " .. tostring(binding.modifiers))
    else
      print("   Modificadores: ninguno")
    end

    print("   Tecla: " .. tostring(binding.key))
    print("   Acción: " .. type(binding.action))
  end

  print("\nVerificando funciones de Mudlet:")
  print("  tempKey: " .. type(tempKey))
  print("  announce: " .. type(announce))
  print("  setClipboardText: " .. type(setClipboardText))
  print("  mudlet.keymodifier.Control: " .. tostring(mudlet.keymodifier.Control))
  print("  mudlet.keymodifier.Shift: " .. tostring(mudlet.keymodifier.Shift))
  print("  mudlet.keymodifier.Control + mudlet.keymodifier.Shift: " ..
    tostring(mudlet.keymodifier.Control + mudlet.keymodifier.Shift))
  print("============================\n")
end

return lector
