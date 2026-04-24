-------------------------------------------------------------------------------
-- MÓDULO: triggers
-- Descripción: Orquestador centralizado de triggers.
--              Descubre y registra automáticamente todos los triggers definidos
--              en los módulos del sistema. Cada módulo define sus triggers
--              y este módulo se encarga de registrarlos en Mudlet.
-- Autor: RhomScripts
-- Fecha: 2026
-- Versión: 1.0 - Sistema modular y escalable de gestión de triggers
-------------------------------------------------------------------------------

local triggers = {}

-- En Mudlet, tempRegexTrigger() registra los triggers usando expresiones regulares
-- La desvinculación se realiza automáticamente al terminar la sesión

-- ============================================================================
-- FUNCIONES INTERNAS DE REGISTRO BAJO NIVEL
-- ============================================================================

-------------------------------------------------------------------------------
-- FUNCIÓN: local function register_trigger()
-- Descripción: Registra un trigger en Mudlet usando expresiones regulares
--              Y también registra un event handler para responder a eventos de prueba
-- Parámetros:
--   - pattern: Expresión regular que activará el trigger
--   - action: Función a ejecutar cuando se active el trigger
--   - trigger_name: Nombre descriptivo del trigger
--   - trigger_desc: Descripción de lo que hace el trigger
--   - module_name: Nombre del módulo que define el trigger
-- Retorno: true si se registró, false en caso contrario
-------------------------------------------------------------------------------
local function register_trigger(pattern, action, trigger_name, trigger_desc, module_name)
  if type(tempRegexTrigger) ~= "function" then
    return false
  end

  -- Registrar trigger para líneas reales del MUD
  tempRegexTrigger(pattern, function()
    action()
  end)

  -- Registrar event handler para responder a eventos de prueba
  registerAnonymousEventHandler("rhomscripts.test.line", function(event, linea)
    -- Verificar si la línea coincide con el patrón del trigger
    if string.find(linea, pattern) then
      action()
    end
  end)

  local debug = RhomScripts and RhomScripts.modules and RhomScripts.modules.debug
  if debug then
    debug.register_trigger_from_module(module_name, trigger_name, trigger_desc)
  end

  return true
end

-- ============================================================================
-- FUNCIONES PÚBLICAS DEL ORQUESTADOR
-- ============================================================================

-------------------------------------------------------------------------------
-- FUNCIÓN: triggers.descubrir_triggers()
-- Descripción: Descubre todos los triggers definidos en los módulos cargados.
--              Itera sobre los módulos y recopila sus triggers.
-- Parámetros: Ninguno
-- Retorno: Tabla con estructura {module_name, trigger_def} para cada trigger
-------------------------------------------------------------------------------
function triggers.descubrir_triggers()
  local discovered = {}

  -- Iterar sobre todos los módulos cargados
  if not RhomScripts or not RhomScripts.modules then
    print("Error: No se pueden acceder a los módulos cargados")
    return discovered
  end

  for module_name, module in pairs(RhomScripts.modules) do
    -- Verificar si el módulo tiene definidos triggers
    if module and type(module.triggers) == "table" then
      for _, trigger_def in ipairs(module.triggers) do
        table.insert(discovered, {
          module = module_name,
          trigger = trigger_def
        })
      end
    end
  end

  return discovered
end

-------------------------------------------------------------------------------
-- FUNCIÓN: triggers.registrar()
-- Descripción: Registra todos los triggers encontrados en los módulos.
--              Esta es la función principal que se llama desde init.lua
-- Parámetros: Ninguno
-- Retorno: tabla {success=count, errors=count, total=count}
-------------------------------------------------------------------------------
function triggers.registrar()
  -- Verificar que la API tempRegexTrigger de Mudlet esté disponible
  if type(tempRegexTrigger) ~= "function" then
    print("Error: tempRegexTrigger no es una función disponible en Mudlet")
    return { success = 0, errors = 1, total = 0 }
  end

  local discovered = triggers.descubrir_triggers()
  local success_count = 0
  local error_count = 0

  -- Registrar cada trigger descubierto
  for _, item in ipairs(discovered) do
    local trigger_def = item.trigger
    local module_name = item.module
    local is_valid = true

    -- Validar que el trigger tenga los campos necesarios
    if not trigger_def.pattern then
      print("Error: Trigger del módulo '" .. module_name .. "' sin campo 'pattern'")
      is_valid = false
      error_count = error_count + 1
    elseif not trigger_def.action or type(trigger_def.action) ~= "function" then
      print("Error: Trigger '" .. (trigger_def.name or "desconocido") .. "' del módulo '" .. module_name .. "' sin función 'action' válida")
      is_valid = false
      error_count = error_count + 1
    elseif not trigger_def.name then
      print("Error: Trigger del módulo '" .. module_name .. "' sin campo 'name'")
      is_valid = false
      error_count = error_count + 1
    end

    if is_valid then
      if register_trigger(trigger_def.pattern, trigger_def.action, trigger_def.name, trigger_def.desc, module_name) then
        success_count = success_count + 1
      end
    end
  end

  return { success = success_count, errors = error_count, total = success_count + error_count }
end

-------------------------------------------------------------------------------
-- FUNCIÓN: triggers.desregistrar()
-- Descripción: Limpia el registro de triggers en debug.
--              Los triggers se desvinculan automáticamente con tempRegexTrigger.
-- Parámetros: Ninguno
-- Retorno: Ninguno
-------------------------------------------------------------------------------
function triggers.desregistrar()
  print("Los triggers registrados con tempRegexTrigger se desvinculan automáticamente")

  -- Limpiar el registro en debug
  local debug = RhomScripts and RhomScripts.modules and RhomScripts.modules.debug
  if debug then
    debug.clear_triggers()
  end
end

-------------------------------------------------------------------------------
-- FUNCIÓN: triggers.listar_triggers()
-- Descripción: Lista todos los triggers registrados y sus descripciones.
--              Recorre automáticamente todos los triggers registrados en el sistema.
-- Parámetros: Ninguno
-- Retorno: Ninguno
-------------------------------------------------------------------------------
function triggers.listar_triggers()
  local debug = RhomScripts and RhomScripts.modules and RhomScripts.modules.debug

  if not debug or not debug.registered or not debug.registered.triggers_by_module then
    print("No hay información de triggers registrados disponible")
    return
  end

  local triggers_by_module = debug.registered.triggers_by_module
  local total_triggers = 0

  -- Ordenar módulos alfabéticamente para mejor presentación
  local module_names = {}
  for module_name, _ in pairs(triggers_by_module) do
    table.insert(module_names, module_name)
  end
  table.sort(module_names)

  print("═══════════════════════════════════════════════════════════════")
  print("TRIGGERS REGISTRADOS")
  print("═══════════════════════════════════════════════════════════════")

  -- Recorrer cada módulo y sus triggers
  for _, module_name in ipairs(module_names) do
    local triggers_list = triggers_by_module[module_name]

    if triggers_list and #triggers_list > 0 then
      print("")
      print("─── MÓDULO: " .. module_name:upper() .. " ─────────────────────────────")

      -- Ordenar los triggers por nombre
      local sorted_triggers = {}
      for _, trigger_info in ipairs(triggers_list) do
        table.insert(sorted_triggers, trigger_info)
      end
      table.sort(sorted_triggers, function(a, b) return a.name < b.name end)

      -- Mostrar cada trigger y su descripción
      for _, trigger_info in ipairs(sorted_triggers) do
        print(string.format("  %s: %s", trigger_info.name, trigger_info.desc))
        total_triggers = total_triggers + 1
      end
    end
  end

  print("")
  print("═══════════════════════════════════════════════════════════════")
  print(string.format("TOTAL: %d triggers registrados", total_triggers))
  print("═══════════════════════════════════════════════════════════════")
end

-- ============================================================================
-- DEFINICIÓN DE ALIASES DEL MÓDULO
-- ============================================================================

triggers.aliases = {
  {
    pattern = "^listtriggers$",
    action = function()
      triggers.listar_triggers()
    end,
    name = "listtriggers",
    desc = "Lista todos los triggers registrados en el sistema"
  }
}

return triggers
