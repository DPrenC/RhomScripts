-------------------------------------------------------------------------------
-- MÓDULO: keys
-- Descripción: Orquestador centralizado de atajos de teclado.
--              Descubre y registra automáticamente todas las teclas definidas
--              en los módulos del sistema de forma simplificada.
-- Autor: RhomScripts
-- Fecha: 2026
-- Versión: 4.0 - Sintaxis correcta de tempKey
-------------------------------------------------------------------------------

local keys = {}

-- ============================================================================
-- ALIASES DEL MÓDULO
-- ============================================================================

keys.aliases = {
  {
    pattern = "^listkeys$",
    action = function() keys.listar_teclas() end,
    name = "listkeys",
    desc = "Lista todos los atajos de teclado registrados"
  }
}


-- ============================================================================
-- FUNCIÓN INTERNA ÚNICA DE REGISTRO
-- ============================================================================

-------------------------------------------------------------------------------
-- FUNCIÓN: local function register_key(binding, module_name)
-- Descripción: Registra atajos de teclado sin modificarlos.
--              Los módulos son responsables de definir los modificadores correctamente.
--
-- Parámetros:
--   - binding: tabla con campos {key, action, name, desc, modifiers (opcional)}
--     - key: mudlet.key.* (requerido)
--     - action: función a ejecutar (requerido)
--     - name: nombre del atajo (requerido)
--     - desc: descripción (requerido)
--     - modifiers: número opcional (mudlet.keymodifier.* o combinación con +), NO una tabla
--   - module_name: nombre del módulo de origen
--
-- Retorno: true si se registró correctamente, false en caso contrario
--
-- Formatos esperados de binding.modifiers (ya procesados por los módulos):
--   - nil: sin modificadores → tempKey(mudlet.key.F1, function)
--   - número: mudlet.keymodifier.Control → tempKey(mudlet.keymodifier.Control, mudlet.key.F1, function)
--   - número: mudlet.keymodifier.Control + mudlet.keymodifier.Shift → tempKey(combined, mudlet.key.F1, function)
-------------------------------------------------------------------------------
local function register_key(binding, module_name)
  local key_code = binding.key
  local action = binding.action
  local modifiers = binding.modifiers

  -- Registrar sin modificadores
  if not modifiers then
    tempKey(key_code, function() action() end)
  else
    -- Registrar con modificadores (ya combinados correctamente por el módulo)
    tempKey(modifiers, key_code, function() action() end)
  end

  -- Registrar en debug si está disponible
  local debug = RhomScripts and RhomScripts.modules and RhomScripts.modules.debug
  if debug then
    debug.register_key_from_module(module_name, binding.name, binding.desc)
  end

  return true
end

-- ============================================================================
-- FUNCIONES PÚBLICAS
-- ============================================================================

-------------------------------------------------------------------------------
-- FUNCIÓN: keys.descubrir_teclas()
-- Retorno: Tabla con estructura {module_name, binding}
-------------------------------------------------------------------------------
function keys.descubrir_teclas()
  local bindings = {}

  if not RhomScripts or not RhomScripts.modules then
    print("Error: No se pueden acceder a los módulos cargados")
    return bindings
  end

  for module_name, module in pairs(RhomScripts.modules) do
    if module and type(module.key_bindings) == "table" then
      for _, binding in ipairs(module.key_bindings) do
        table.insert(bindings, { module = module_name, binding = binding })
      end
    end
  end

  return bindings
end

-------------------------------------------------------------------------------
-- FUNCIÓN: keys.registrar()
-- Registra todos los atajos de teclado encontrados en los módulos
-- Retorno: tabla {success, errors, total}
-------------------------------------------------------------------------------
function keys.registrar()
  if type(tempKey) ~= "function" then
    print("Error: tempKey no disponible en Mudlet")
    return { success = 0, errors = 1, total = 0 }
  end

  local bindings = keys.descubrir_teclas()
  local success_count = 0
  local error_count = 0

  for _, item in ipairs(bindings) do
    local binding = item.binding
    local module_name = item.module

    -- Validación mínima
    if not binding.key or not binding.action or type(binding.action) ~= "function" or not binding.name then
      print("Error: Binding inválido en módulo '" .. module_name .. "'")
      error_count = error_count + 1
    else
      if register_key(binding, module_name) then
        success_count = success_count + 1
      else
        error_count = error_count + 1
      end
    end
  end

  return { success = success_count, errors = error_count, total = success_count + error_count }
end

-------------------------------------------------------------------------------
-- FUNCIÓN: keys.desregistrar()
-- Limpia el registro de teclas en debug
-------------------------------------------------------------------------------
function keys.desregistrar()
  local debug = RhomScripts and RhomScripts.modules and RhomScripts.modules.debug
  if debug then
    debug.clear_keys()
  end
end

-------------------------------------------------------------------------------
-- FUNCIÓN: keys.listar_teclas()
-- Lista todas las teclas registradas y sus descripciones
-------------------------------------------------------------------------------
function keys.listar_teclas()
  local debug = RhomScripts and RhomScripts.modules and RhomScripts.modules.debug

  if not debug or not debug.registered or not debug.registered.keys_by_module then
    print("No hay información de teclas registradas disponible")
    return
  end

  local keys_by_module = debug.registered.keys_by_module
  local total_keys = 0
  local module_names = {}

  for module_name, _ in pairs(keys_by_module) do
    table.insert(module_names, module_name)
  end
  table.sort(module_names)

  print("\n" .. string.rep("═", 63))
  print("ATAJOS DE TECLADO REGISTRADOS")
  print(string.rep("═", 63))

  for _, module_name in ipairs(module_names) do
    local keys_list = keys_by_module[module_name]
    if keys_list and #keys_list > 0 then
      print("\n─── " .. module_name:upper() .. " " .. string.rep("─", 45 - #module_name))

      local sorted_keys = {}
      for _, key_info in ipairs(keys_list) do
        table.insert(sorted_keys, key_info)
      end
      table.sort(sorted_keys, function(a, b) return a.key < b.key end)

      for _, key_info in ipairs(sorted_keys) do
        print(string.format("  %s: %s", key_info.key, key_info.action))
        total_keys = total_keys + 1
      end
    end
  end

  print("\n" .. string.rep("═", 63))
  print(string.format("TOTAL: %d teclas registradas", total_keys))
  print(string.rep("═", 63) .. "\n")
end

return keys
