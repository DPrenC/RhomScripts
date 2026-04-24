--------------------------------------------------------------------------------- MÓDULO: aliases
-- Descripción: Orquestador centralizado de aliases/comandos.
--              Descubre y registra automáticamente todos los aliases definidos
--              en los módulos del sistema. Cada módulo define sus aliases
--              y este módulo se encarga de registrarlos en Mudlet.
-- Autor: RhomScripts
-- Fecha: 2026
-- Versión: 2.0 - Sistema modular y escalable de gestión de aliases
-------------------------------------------------------------------------------

local aliases = {}

-- En Mudlet, tempAlias() registra los aliases directamente sin necesidad de handles
-- La desvinculación se realiza automáticamente al terminar la sesión

-- ============================================================================
-- FUNCIONES INTERNAS DE REGISTRO BAJO NIVEL
-- ============================================================================

-------------------------------------------------------------------------------
-- FUNCIÓN: local function register_alias()
-- Descripción: Registra un alias en Mudlet
-- Parámetros:
--   - pattern: Patrón regex que activará el alias
--   - action: Función a ejecutar cuando se active el alias
--   - alias_name: Nombre descriptivo del alias
--   - alias_desc: Descripción de lo que hace el alias
--   - module_name: Nombre del módulo que define el alias
-- Retorno: true si se registró, false en caso contrario
-------------------------------------------------------------------------------
local function register_alias(pattern, action, alias_name, alias_desc, module_name)
  if type(tempAlias) ~= "function" then
    return false
  end

  tempAlias(pattern, function()
    action()
  end)

  local debug = RhomScripts and RhomScripts.modules and RhomScripts.modules.debug
  if debug then
    debug.register_alias_from_module(module_name, alias_name, alias_desc)
  end

  return true
end

-- ============================================================================
-- FUNCIONES PÚBLICAS DEL ORQUESTADOR
-- ============================================================================

-------------------------------------------------------------------------------
-- FUNCIÓN: aliases.descubrir_aliases()
-- Descripción: Descubre todos los aliases definidos en los módulos cargados.
--              Itera sobre los módulos y recopila sus aliases.
-- Parámetros: Ninguno
-- Retorno: Tabla con estructura {module_name, alias_def} para cada alias
-------------------------------------------------------------------------------
function aliases.descubrir_aliases()
  local discovered = {}

  -- Iterar sobre todos los módulos cargados
  if not RhomScripts or not RhomScripts.modules then
    print("Error: No se pueden acceder a los módulos cargados")
    return discovered
  end

  for module_name, module in pairs(RhomScripts.modules) do
    -- Verificar si el módulo tiene definidos aliases
    if module and type(module.aliases) == "table" then
      for _, alias_def in ipairs(module.aliases) do
        table.insert(discovered, {
          module = module_name,
          alias = alias_def
        })
      end
    end
  end

  return discovered
end

-------------------------------------------------------------------------------
-- FUNCIÓN: aliases.registrar()
-- Descripción: Registra todos los aliases encontrados en los módulos.
--              Esta es la función principal que se llama desde init.lua
-- Parámetros: Ninguno
-- Retorno: tabla {success=count, errors=count, total=count}
-------------------------------------------------------------------------------
function aliases.registrar()
  -- Verificar que la API tempAlias de Mudlet esté disponible
  if type(tempAlias) ~= "function" then
    print("Error: tempAlias no es una función disponible en Mudlet")
    return { success = 0, errors = 1, total = 0 }
  end

  local discovered = aliases.descubrir_aliases()
  local success_count = 0
  local error_count = 0

  -- Registrar cada alias descubierto
  for _, item in ipairs(discovered) do
    local alias_def = item.alias
    local module_name = item.module
    local is_valid = true

    -- Validar que el alias tenga los campos necesarios
    if not alias_def.pattern then
      print("Error: Alias del módulo '" .. module_name .. "' sin campo 'pattern'")
      is_valid = false
      error_count = error_count + 1
    elseif not alias_def.action or type(alias_def.action) ~= "function" then
      print("Error: Alias '" .. (alias_def.name or "desconocido") .. "' del módulo '" .. module_name .. "' sin función 'action' válida")
      is_valid = false
      error_count = error_count + 1
    elseif not alias_def.name then
      print("Error: Alias del módulo '" .. module_name .. "' sin campo 'name'")
      is_valid = false
      error_count = error_count + 1
    end

    if is_valid then
      if register_alias(alias_def.pattern, alias_def.action, alias_def.name, alias_def.desc, module_name) then
        success_count = success_count + 1
      end
    end
  end

  return { success = success_count, errors = error_count, total = success_count + error_count }
end

-------------------------------------------------------------------------------
-- FUNCIÓN: aliases.desregistrar()
-- Descripción: Limpia el registro de aliases en debug.
--              Los aliases se desvinculan automáticamente con tempAlias.
-- Parámetros: Ninguno
-- Retorno: Ninguno
-------------------------------------------------------------------------------
function aliases.desregistrar()
  print("Los aliases registrados con tempAlias se desvinculaán automáticamente")

  -- Limpiar el registro en debug
  local debug = RhomScripts and RhomScripts.modules and RhomScripts.modules.debug
  if debug then
    debug.clear_aliases()
  end
end

-------------------------------------------------------------------------------
-- FUNCIÓN: aliases.listar_aliases()
-- Descripción: Lista todos los aliases registrados y sus descripciones.
--              Recorre automáticamente todos los aliases registrados en el sistema.
-- Parámetros: Ninguno
-- Retorno: Ninguno
-------------------------------------------------------------------------------
function aliases.listar_aliases()
  local debug = RhomScripts and RhomScripts.modules and RhomScripts.modules.debug

  if not debug or not debug.registered or not debug.registered.aliases_by_module then
    print("No hay información de aliases registrados disponible")
    return
  end

  local aliases_by_module = debug.registered.aliases_by_module
  local total_aliases = 0

  -- Ordenar módulos alfabéticamente para mejor presentación
  local module_names = {}
  for module_name, _ in pairs(aliases_by_module) do
    table.insert(module_names, module_name)
  end
  table.sort(module_names)

  print("═══════════════════════════════════════════════════════════════")
  print("ALIASES REGISTRADOS")
  print("═══════════════════════════════════════════════════════════════")

  -- Recorrer cada módulo y sus aliases
  for _, module_name in ipairs(module_names) do
    local aliases_list = aliases_by_module[module_name]

    if aliases_list and #aliases_list > 0 then
      print("")
      print("─── MÓDULO: " .. module_name:upper() .. " ─────────────────────────────")

      -- Ordenar los aliases por nombre
      local sorted_aliases = {}
      for _, alias_info in ipairs(aliases_list) do
        table.insert(sorted_aliases, alias_info)
      end
      table.sort(sorted_aliases, function(a, b) return a.name < b.name end)

      -- Mostrar cada alias y su descripción
      for _, alias_info in ipairs(sorted_aliases) do
        print(string.format("  %s: %s", alias_info.name, alias_info.action))
        total_aliases = total_aliases + 1
      end
    end
  end

  print("")
  print("═══════════════════════════════════════════════════════════════")
  print(string.format("TOTAL: %d aliases registrados", total_aliases))
  print("═══════════════════════════════════════════════════════════════")
end

-- ============================================================================
-- DEFINICIÓN DE ALIASES DEL MÓDULO
-- ============================================================================

aliases.aliases = {
  {
    pattern = "^listalias$",
    action = function()
      aliases.listar_aliases()
    end,
    name = "listalias",
    desc = "Lista todos los aliases registrados en el sistema"
  }
}

return aliases
