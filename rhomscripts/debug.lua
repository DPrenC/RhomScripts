-------------------------------------------------------------------------------
-- MÓDULO: debug
-- Descripción: Módulo centralizado para gestionar información--              estadísticas del sistema. Recopila datos de todos los módulos
--              y proporciona funciones para mostrar información del sistema.
-- Autor: Rhomdur
-- Fecha: 08/02/2026
-------------------------------------------------------------------------------

local debug = {}

-- ============================================================================
-- DEFINICIÓN DE ALIASES DEL MÓDULO
-- ============================================================================

debug.aliases = {
  {
    pattern = "^estadisticas$",
    action = function()
      debug.info(false)
    end,
    name = "estadisticas",
    desc = "Muestra estadísticas generales del sistema"
  },
  {
    pattern = "^debug$",
    action = function()
      debug.info(true)
    end,
    name = "debug",
    desc = "Muestra información detallada del sistema"
  }
}

-- ============================================================================
-- VARIABLES DE ESTADO Y ESTADÍSTICAS
-- ============================================================================

-- Tabla para almacenar estadísticas de diferentes componentes
debug.stats = {
  modules_loaded = 0,      -- Total de módulos cargados
  keys_registered = 0,     -- Total de atajos de teclado registrados
  aliases_registered = 0,  -- Total de aliases registrados
  triggers_registered = 0, -- Total de triggers registrados
}

-- Lista detallada de elementos registrados
debug.registered = {
  modules = {},           -- Lista de nombres de módulos cargados
  keys = {},              -- Lista de teclas registradas con sus funciones (deprecated, usar keys_by_module)
  keys_by_module = {},    -- Teclas agrupadas por módulo de origen
  aliases = {},           -- Lista de aliases registrados (deprecated, usar aliases_by_module)
  aliases_by_module = {}, -- Aliases agrupados por módulo de origen
  triggers = {},          -- Lista de triggers registrados (deprecated, usar triggers_by_module)
  triggers_by_module = {},-- Triggers agrupados por módulo de origen
}

-- Información de configuración del sistema
debug.system_info = {
  name = "RhomScriptsRL",
  version = "1.0, 07/02/2026",
  author = "Rhomdur",
  description =
  "Scripts para Reinos de leyenda en el cliente Mudlet, especialmente diseñados para el uso con lectores de pantalla.",
  initialized = false,
  init_time = nil,
}

-- ============================================================================
-- FUNCIONES DE REGISTRO
-- ============================================================================

-------------------------------------------------------------------------------
-- FUNCIÓN: debug.register_module()
-- Descripción: Registra un módulo como cargado
-- Parámetros:
--   - name (string): Nombre del módulo
-- Retorno: Ninguno
-------------------------------------------------------------------------------
function debug.register_module(name)
  if not name then return end

  -- Evitar duplicados
  for _, mod_name in ipairs(debug.registered.modules) do
    if mod_name == name then return end
  end

  table.insert(debug.registered.modules, name)
  debug.stats.modules_loaded = #debug.registered.modules
end

-------------------------------------------------------------------------------
-- FUNCIÓN: debug.register_key()
-- Descripción: Registra un atajo de teclado (compatibilidad hacia atrás)
-- Parámetros:
--   - key (string): Nombre de la tecla (ej: "F12")
--   - action (string): Descripción de la acción que realiza
-- Retorno: Ninguno
-------------------------------------------------------------------------------
function debug.register_key(key, action)
  if not key or not action then return end

  debug.registered.keys[key] = action
  debug.stats.keys_registered = debug.stats.keys_registered + 1
end

-------------------------------------------------------------------------------
-- FUNCIÓN: debug.register_key_from_module()
-- Descripción: Registra una tecla enlazada a su módulo de origen
-- Parámetros:
--   - module_name (string): Nombre del módulo que define la tecla
--   - key_name (string): Nombre de la tecla (ej: "F12")
--   - action_desc (string): Descripción de la acción que realiza
-- Retorno: Ninguno
-------------------------------------------------------------------------------
function debug.register_key_from_module(module_name, key_name, action_desc)
  if not module_name or not key_name or not action_desc then return end

  if not debug.registered.keys_by_module[module_name] then
    debug.registered.keys_by_module[module_name] = {}
  end

  table.insert(debug.registered.keys_by_module[module_name], {
    key = key_name,
    action = action_desc
  })

  debug.stats.keys_registered = debug.stats.keys_registered + 1
end

-------------------------------------------------------------------------------
-- FUNCIÓN: debug.register_alias()
-- Descripción: Registra un alias/comando (compatibilidad hacia atrás)
-- Parámetros:
--   - name (string): Nombre del alias
--   - description (string): Descripción del alias
-- Retorno: Ninguno
-------------------------------------------------------------------------------
function debug.register_alias(name, description)
  if not name then return end

  debug.registered.aliases[name] = description or "Sin descripción"
  debug.stats.aliases_registered = debug.stats.aliases_registered + 1
end

-------------------------------------------------------------------------------
-- FUNCIÓN: debug.register_alias_from_module()
-- Descripción: Registra un alias enlazado a su módulo de origen
-- Parámetros:
--   - module_name (string): Nombre del módulo que define el alias
--   - alias_name (string): Nombre del alias (ej: "listalias")
--   - action_desc (string): Descripción de la acción que realiza
-- Retorno: Ninguno
-------------------------------------------------------------------------------
function debug.register_alias_from_module(module_name, alias_name, action_desc)
  if not module_name or not alias_name or not action_desc then return end

  if not debug.registered.aliases_by_module[module_name] then
    debug.registered.aliases_by_module[module_name] = {}
  end

  table.insert(debug.registered.aliases_by_module[module_name], {
    name = alias_name,
    action = action_desc
  })

  debug.stats.aliases_registered = debug.stats.aliases_registered + 1
end

-------------------------------------------------------------------------------
-- FUNCIÓN: debug.register_trigger()
-- Descripción: Registra un trigger (compatibilidad hacia atrás)
-- Parámetros:
--   - name (string): Nombre del trigger
--   - description (string): Descripción del trigger
-- Retorno: Ninguno
-------------------------------------------------------------------------------
function debug.register_trigger(name, description)
  if not name then return end

  debug.registered.triggers[name] = description or "Sin descripción"
  debug.stats.triggers_registered = debug.stats.triggers_registered + 1
end

-------------------------------------------------------------------------------
-- FUNCIÓN: debug.register_trigger_from_module()
-- Descripción: Registra un trigger enlazado a su módulo de origen
-- Parámetros:
--   - module_name (string): Nombre del módulo que define el trigger
--   - trigger_name (string): Nombre del trigger
--   - trigger_desc (string): Descripción de lo que hace el trigger
-- Retorno: Ninguno
-------------------------------------------------------------------------------
function debug.register_trigger_from_module(module_name, trigger_name, trigger_desc)
  if not module_name or not trigger_name or not trigger_desc then return end

  if not debug.registered.triggers_by_module[module_name] then
    debug.registered.triggers_by_module[module_name] = {}
  end

  table.insert(debug.registered.triggers_by_module[module_name], {
    name = trigger_name,
    desc = trigger_desc
  })

  debug.stats.triggers_registered = debug.stats.triggers_registered + 1
end

-------------------------------------------------------------------------------
-- FUNCIÓN: debug.clear_keys()
-- Descripción: Limpia el registro de teclas (usado al des-registrarlas)
-- Parámetros: Ninguno
-- Retorno: Ninguno
-------------------------------------------------------------------------------
function debug.clear_keys()
  debug.registered.keys = {}
  debug.registered.keys_by_module = {}
  debug.stats.keys_registered = 0
end

-------------------------------------------------------------------------------
-- FUNCIÓN: debug.clear_aliases()
-- Descripción: Limpia el registro de aliases
-- Parámetros: Ninguno
-- Retorno: Ninguno
-------------------------------------------------------------------------------
function debug.clear_aliases()
  debug.registered.aliases = {}
  debug.registered.aliases_by_module = {}
  debug.stats.aliases_registered = 0
end

-------------------------------------------------------------------------------
-- FUNCIÓN: debug.clear_triggers()
-- Descripción: Limpia el registro de triggers (usado al des-registrarlos)
-- Parámetros: Ninguno
-- Retorno: Ninguno
-------------------------------------------------------------------------------
function debug.clear_triggers()
  debug.registered.triggers = {}
  debug.registered.triggers_by_module = {}
  debug.stats.triggers_registered = 0
end

-- ============================================================================
-- FUNCIONES DE INFORMACIÓN
-- ============================================================================

-------------------------------------------------------------------------------
-- FUNCIÓN: debug.info()
-- Descripción: Muestra información completa del sistema y estadísticas
-- Parámetros:
--   - detailed (boolean): Si es true, muestra información detallada
-- Retorno: Ninguno
-------------------------------------------------------------------------------
function debug.info(detailed)
  local separator = string.rep("=", 70)

  print("\n" .. separator)
  print("  " .. debug.system_info.name .. " - Información del Sistema")
  print(separator)

  -- Información básica
  print("\n[INFORMACIÓN GENERAL]")
  print("  Versión:       " .. debug.system_info.version)
  print("  Autor:         " .. debug.system_info.author)
  print("  Inicializado:  " .. (debug.system_info.initialized and "Sí" or "No"))

  if debug.system_info.init_time then
    print("  Tiempo de inicio: " .. os.date("%Y-%m-%d %H:%M:%S", debug.system_info.init_time))
    local uptime = os.time() - debug.system_info.init_time
    print("  Tiempo activo: " .. uptime .. " segundos")
  end

  -- Estadísticas
  print("\n[ESTADÍSTICAS]")
  print("  Módulos cargados:      " .. debug.stats.modules_loaded)
  print("  Atajos registrados:    " .. debug.stats.keys_registered)
  print("  Aliases registrados:   " .. debug.stats.aliases_registered)
  print("  Triggers registrados:  " .. debug.stats.triggers_registered)

  -- Información detallada (opcional)
  if detailed then
    -- Lista de módulos
    if debug.stats.modules_loaded > 0 then
      print("\n[MÓDULOS CARGADOS]")
      table.sort(debug.registered.modules)
      for _, mod_name in ipairs(debug.registered.modules) do
        print("  • " .. mod_name)
      end
    end

    -- Lista de teclas por módulo
    if debug.stats.keys_registered > 0 then
      print("\n[ATAJOS DE TECLADO POR MÓDULO]")
      
      -- Mostrar teclas organizadas por módulo
      local modules_with_keys = {}
      for module_name, _ in pairs(debug.registered.keys_by_module) do
        table.insert(modules_with_keys, module_name)
      end
      table.sort(modules_with_keys)
      
      for _, module_name in ipairs(modules_with_keys) do
        print("\n  [" .. module_name .. "]")
        for _, key_info in ipairs(debug.registered.keys_by_module[module_name]) do
          print(string.format("    %-12s → %s", key_info.key, key_info.action))
        end
      end
    end

    -- Lista de aliases
    if debug.stats.aliases_registered > 0 then
      print("\n[ALIASES REGISTRADOS]")
      local sorted_aliases = {}
      for alias, _ in pairs(debug.registered.aliases) do
        table.insert(sorted_aliases, alias)
      end
      table.sort(sorted_aliases)

      for _, alias in ipairs(sorted_aliases) do
        print(string.format("  %-15s → %s", alias, debug.registered.aliases[alias]))
      end
    end
  end

  print("\n" .. separator)
  print("  Usa 'debug.info(true)' para ver información detallada")
  print(separator .. "\n")
end

-------------------------------------------------------------------------------
-- FUNCIÓN: debug.set_system_info()
-- Descripción: Configura la información del sistema
-- Parámetros:
--   - info (table): Tabla con campos: name, version, author, description
-- Retorno: Ninguno
-------------------------------------------------------------------------------
function debug.set_system_info(info)
  if not info then return end

  if info.name then debug.system_info.name = info.name end
  if info.version then debug.system_info.version = info.version end
  if info.author then debug.system_info.author = info.author end
  if info.description then debug.system_info.description = info.description end
  if info.initialized ~= nil then debug.system_info.initialized = info.initialized end
  if info.init_time then debug.system_info.init_time = info.init_time end
end

-------------------------------------------------------------------------------
-- FUNCIÓN: debug.init_system_info()
-- Descripción: Inicializa completamente la información del sistema
-- Parámetros:
--   - info (table): Tabla con campos: name, version, author, description
-- Retorno: Ninguno
-------------------------------------------------------------------------------
function debug.init_system_info(info)
  if not info then return end
  
  debug.system_info = {
    name = info.name or "RhomScriptsRL",
    version = info.version or "1.0",
    author = info.author or "Rhomdur",
    description = info.description or "",
    initialized = false,
    init_time = nil,
  }
end

-------------------------------------------------------------------------------
-- FUNCIÓN: debug.get_stats()
-- Descripción: Obtiene la tabla de estadísticas
-- Parámetros: Ninguno
-- Retorno: Tabla con estadísticas
-------------------------------------------------------------------------------
function debug.get_stats()
  return debug.stats
end

-------------------------------------------------------------------------------
-- FUNCIÓN: debug.reset()
-- Descripción: Reinicia todas las estadísticas (útil para recargas)
-- Parámetros: Ninguno
-- Retorno: Ninguno
-------------------------------------------------------------------------------
function debug.reset()
  debug.stats = {
    modules_loaded = 0,
    keys_registered = 0,
    aliases_registered = 0,
    triggers_registered = 0,
  }

  debug.registered = {
    modules = {},
    keys = {},
    keys_by_module = {},
    aliases = {},
    triggers = {},
  }

  debug.system_info.initialized = false
  debug.system_info.init_time = nil

  print("[DEBUG] Estadísticas reiniciadas")
end

return debug
