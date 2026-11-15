--------------------------------------------------
--  RhomLoader (paquete Mudlet)
--  Carga un proyecto externo rhomscripts desde disco
--------------------------------------------------

-- ===== CONFIGURACION =====
local BASE_PATH = "PONER_RUTA_AQUI" -- PONER RUTA AQUI

--------------------------------------------------
-- Logging
--------------------------------------------------
local function log(msg, color)
  color = color or "green"
  cecho(string.format("<%s>[RhomLoader] %s\n", color, msg))
end

--------------------------------------------------
-- Path setup
--------------------------------------------------
local function setupPath()
  if not BASE_PATH:match("/$") then
    BASE_PATH = BASE_PATH .. "/"
  end

  _G.RhomScriptsBasePath = BASE_PATH:gsub("/$", "")

  local entry = BASE_PATH .. "?.lua"
  if not (";" .. package.path .. ";"):find(";" .. entry .. ";", 1, true) then
    package.path = entry .. ";" .. package.path
  end

  log("package.path configurado: " .. BASE_PATH)
end

--------------------------------------------------
-- La entrada init.lua retira los registros y renueva los módulos al recargar.
--------------------------------------------------

--------------------------------------------------
-- Load project entrypoint
--------------------------------------------------
local function loadProject()
  log("Iniciando carga...")
  setupPath()

  dofile(BASE_PATH .. "init.lua")
  assert(RhomScripts.initialized or RhomScripts.loading, "RhomScripts no ha completado la inicialización")
  if RhomScripts.loading then log("Esperando al paquete oficial.") end
  return true
end

--------------------------------------------------
-- Public API (global unico)
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
