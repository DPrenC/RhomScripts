-- ============================================================================
-- Módulo: init.lua
-- Versión: 1.0, 07/02/2026
-- Descripción: Módulo de inicialización principal del sistema de scripts.
--              Punto de entrada que configura el entorno, carga módulos
--              necesarios e inicializa todos los componentes del sistema
-- Autor: Rhomdur
-- ============================================================================


-- Crear el namespace global RhomScripts para evitar conflictos con otros scripts
-- Todos los módulos y datos del sistema estarán contenidos en este namespace
if not RhomScripts then
  RhomScripts = {}
end

-- Tabla para almacenar referencias a todos los módulos cargados
RhomScripts.modules = {}


-- CONFIGURACIÓN DE RUTAS

-- Determina el directorio raíz donde se encuentran los scripts
-- Verifica si está ejecutándose en Mudlet o en modo desarrollo/testing
local root
if type(getMudletHomeDir) == "function" and type(getProfileName) == "function" then
  -- Modo Mudlet: construye la ruta completa al directorio de scripts dentro del perfil
  root = string.format("%s/profiles/%s/rhomscripts", getMudletHomeDir(), getProfileName())
else
  -- Modo desarrollo/testing: usa el directorio actual
  root = "."
end

-- Añade el directorio raíz al path de búsqueda de módulos de Lua
-- Esto permite que require() encuentre los módulos en la ubicación correcta
package.path = root .. "/?.lua;" .. package.path

-- ============================================================================
-- INFORMACIÓN DEL SISTEMA
-- ============================================================================

local system_info = {
  name = "RhomScriptsRL",
  version = "1.0, 07/02/2026",
  author = "Rhomdur",
  description =
  "Scripts para Reinos de leyenda en el cliente Mudlet, especialmente diseñados para el uso con lectores de pantalla.",
}

-- ============================================================================
-- CARGA DE MÓDULOS
-- ============================================================================

-- Variables para rastrear el estado de la carga
local load_errors = 0
local modules_loaded = 0
local keys_loaded = 0
local aliases_loaded = 0
local triggers_loaded = 0

-- Función helper para cargar módulos con manejo de errores
local function load_module(module_name, register)
  package.loaded[module_name] = nil
  local success, result = pcall(require, module_name)
  if not success then
    print("Error en la carga del módulo: " .. module_name)
    print(tostring(result))
    load_errors = load_errors + 1
    -- No registrar el módulo fallido
    RhomScripts.modules[module_name] = nil
    return nil
  end

  RhomScripts.modules[module_name] = result
  modules_loaded = modules_loaded + 1

  if register then
    RhomScripts.modules.debug.register_module(module_name)
  end

  return result
end

-- Mensaje inicial
print("\nInicializando " .. system_info.name .. "...")

-- Cargar módulos del sistema
print("\nCargando módulos...")

-- Cargar primero el módulo debug para poder registrar el resto
RhomScripts.modules.debug = load_module("debug", false)
local debug = RhomScripts.modules.debug

if not debug then
  print("Error crítico: no se pudo cargar el módulo debug")
  return
end

-- Inicializar información del sistema en debug
debug.init_system_info(system_info)

RhomScripts.modules.config = load_module("config", true)
RhomScripts.modules.modes = load_module("modes", true)
RhomScripts.modules.keys = load_module("keys", true)
RhomScripts.modules.aliases = load_module("aliases", true)
RhomScripts.modules.triggers = load_module("triggers", true)
RhomScripts.modules.lector = load_module("lector", true)
RhomScripts.modules.pruebas = load_module("pruebas", true)

-- Crear alias locales para compatibilidad y facilidad de uso
local config = RhomScripts.modules.config
local modes = RhomScripts.modules.modes
local keys = RhomScripts.modules.keys
local aliases = RhomScripts.modules.aliases
local triggers = RhomScripts.modules.triggers

-- ============================================================================
-- INICIALIZACIÓN DEL SISTEMA
-- ============================================================================

-- Referencias locales
local sysinfo = debug.system_info

-- 1. Carga la configuración desde archivo o valores por defecto
config.load()

-- 2. Inicializa el sistema de modos con la configuración cargada
modes.init(config.all())

-- 3. Registra todos los atajos de teclado
print("\nCargando atajos de teclado...")
local keys_result = keys.registrar()
if keys_result and keys_result.errors > 0 then
  load_errors = load_errors + keys_result.errors
end
if keys_result then
  keys_loaded = keys_result.success
end

-- 4. Registra todos los aliases/comandos personalizados
print("\nCargando aliases...")
local aliases_result = aliases.registrar()
if aliases_result and aliases_result.errors > 0 then
  load_errors = load_errors + aliases_result.errors
end
if aliases_result then
  aliases_loaded = aliases_result.success
end

-- 5. Registra todos los triggers
print("\nCargando triggers...")
local triggers_result = triggers.registrar()
if triggers_result and triggers_result.errors > 0 then
  load_errors = load_errors + triggers_result.errors
end
if triggers_result then
  triggers_loaded = triggers_result.success
end


-- ============================================================================
-- FINALIZACIÓN
-- ============================================================================

-- Flags de estado del sistema
RhomScripts.initialized = (load_errors == 0)
RhomScripts.init_time = os.time()

-- Actualizar información de inicialización en debug
debug.set_system_info({
  initialized = (load_errors == 0),
  init_time = os.time(),
})

-- Mensajes finales
print("\n" .. string.rep("=", 60))
if load_errors == 0 then
  print(sysinfo.name .. " cargados correctamente")
else
  print(sysinfo.name .. " cargados con errores")
end
print(string.rep("=", 60))

-- Resumen en una línea
local summary = string.format("%d módulos, %d atajos de teclado, %d aliases, %d triggers", 
  modules_loaded, keys_loaded, aliases_loaded, triggers_loaded)
print(summary)

if load_errors > 0 then
  print("⚠ Error en la carga, los scripts no funcionarán correctamente.")
end

print(string.rep("=", 60))
print(sysinfo.name .. " v" .. sysinfo.version)
print("Por " .. sysinfo.author)
print(string.rep("=", 60) .. "\n")

-- Lanza un evento global para notificar que la inicialización está completa
-- Otros scripts pueden escuchar este evento para ejecutar código post-inicialización
raiseEvent("rl.init.done")
raiseEvent("rhomscripts.ready", sysinfo.version)


keys.listar_teclas()
aliases.listar_aliases()
triggers.listar_triggers()