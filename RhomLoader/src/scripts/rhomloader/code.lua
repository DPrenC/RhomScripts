--------------------------------------------------
--  RhomLoader (paquete Mudlet)
--  Carga un proyecto externo rhomscripts desde disco
--------------------------------------------------

-- ===== CONFIGURACIÓN =====
local BASE_PATH = "C:/Users/DPrenC/proyectos/scrips lua/rhomscripts/" -- CAMBIA ESTO
local MODULE_PREFIX = "rhomscripts" -- prefijo de módulos a recargar

--------------------------------------------------
-- Logging
--------------------------------------------------
local function log(msg, color)
  color = color or "green"
  if cecho then
    cecho(string.format("<%s>[RhomLoader] %s\n", color, msg))
  else
    print("[RhomLoader] " .. msg)
  end
end

--------------------------------------------------
-- Path setup
--------------------------------------------------
local function setupPath()
  if not BASE_PATH:match("/$") then
    BASE_PATH = BASE_PATH .. "/"
  end

  package.path = package.path
    .. ";" .. BASE_PATH .. "?.lua"
    .. ";" .. BASE_PATH .. "?/init.lua"

  log("package.path configurado: " .. BASE_PATH)
end

--------------------------------------------------
-- Clear cached modules for hot reload
--------------------------------------------------
local function clearModules()
  local count = 0

  for name in pairs(package.loaded) do
    if name == MODULE_PREFIX or name:match("^" .. MODULE_PREFIX .. "%.") then
      package.loaded[name] = nil
      count = count + 1
    end
  end

  log("Módulos liberados: " .. count)
end

--------------------------------------------------
-- Load project entrypoint
--------------------------------------------------
local function loadProject()
  log("Iniciando carga...")
  setupPath()
  clearModules()

  local ok, err = pcall(function()
    dofile(BASE_PATH .. "init.lua")
  end)

  if not ok then
    log("ERROR: " .. tostring(err), "red")
    return false
  end

  log("rhomscripts cargado correctamente")
  return true
end

--------------------------------------------------
-- Public API (global único)
--------------------------------------------------
_G.RhomLoader = _G.RhomLoader or {}

function RhomLoader.load()
  return loadProject()
end

function RhomLoader.reload()
  return loadProject()
end

--------------------------------------------------
-- Auto-load on import (opcional)
--------------------------------------------------
RhomLoader.load()
