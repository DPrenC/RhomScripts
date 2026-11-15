-- Entrada de configuración, configurador, lector, comunicaciones y teclas.
-- Audio, catálogo de sonidos, paquete oficial y registro de comandos son dependencias de soporte.
local startup_audio
local failure_reported = false
local version = "1.0, 07/02/2026"

local function failure(message)
  RhomScripts.initialized = false
  RhomScripts.loading = false
  local arranque = RhomScripts.soporte and RhomScripts.soporte.arranque
  if arranque then arranque.estado.actualizar("scripts", "error", tostring(message), "carga") end
  if RhomScripts.recarga_timer then killTimer(RhomScripts.recarga_timer); RhomScripts.recarga_timer = nil end
  if RhomScripts.arranque_oficial then RhomScripts.arranque_oficial:cancelar() end
  if RhomScripts.oficial_configuracion then RhomScripts.oficial_configuracion.cancelar_configuracion() end
  if RhomScripts.soporte and RhomScripts.soporte.arranque then RhomScripts.soporte.arranque.cancelar_configuracion() end
  if failure_reported then error(message, 0) end
  failure_reported = true
  local errores = {}
  local function limpiar(accion)
    local correcto, mensaje = pcall(accion)
    if not correcto then errores[#errores + 1] = tostring(mensaje) end
  end
  local modules, soporte = RhomScripts.modules, RhomScripts.soporte
  if modules then
    if modules.comunicaciones then limpiar(modules.comunicaciones.destruir) end
    if modules.configurador then limpiar(modules.configurador.destruir) end
    if modules.keys then limpiar(modules.keys.desregistrar) end
  end
  if soporte then
    if soporte.ui then limpiar(soporte.ui.destruir) end
    if soporte.aliases then limpiar(soporte.aliases.desregistrar) end
  end
  if #errores > 0 then message = tostring(message) .. "\nErrores adicionales de limpieza: " .. table.concat(errores, "\n") end
  local text = "RhomScripts: error de carga. " .. tostring(message)
  echo(text .. "\n")
  announce(text)
  if startup_audio then
    local played, sound_error = pcall(startup_audio.reproducir, "ui.carga_erronea")
    if not played then
      error(tostring(message) .. "\nError adicional en el aviso sonoro: " .. tostring(sound_error), 0)
    end
  end
  error(message, 0)
end

local function protected(action)
  local ok, message = pcall(action)
  if not ok then failure(message) end
end

local function initialize()
  RhomScripts = RhomScripts or {}
  if RhomScripts.recarga_timer then killTimer(RhomScripts.recarga_timer); RhomScripts.recarga_timer = nil end
  RhomScripts.initialized = false
  RhomScripts.loading = true
  -- EndModal debe devolver el control antes de destruir objetos wx.
  local interfaz = RhomScripts.soporte and RhomScripts.soporte.ui
  if interfaz and interfaz.ocupada() then
    interfaz.ocultar()
    RhomScripts.recarga_timer = tempTimer(0, function()
      RhomScripts.recarga_timer = nil
      protected(initialize)
    end)
    return
  end
  if RhomScripts.arranque_oficial then RhomScripts.arranque_oficial:cancelar() end
  if RhomScripts.soporte and RhomScripts.soporte.arranque then
    RhomScripts.soporte.arranque.cancelar_configuracion()
    RhomScripts.soporte.arranque.monitorizacion.detener()
  end
  if RhomScripts.oficial_configuracion then
    RhomScripts.oficial_configuracion.cancelar_configuracion()
    RhomScripts.oficial_configuracion = nil
  end
  local previous = RhomScripts.modules
  local soporte = RhomScripts.soporte
  if previous and (previous.keys or previous.aliases or previous.triggers) and RhomScripts.registration_generation ~= 2 then
    error("Esta actualización requiere cerrar y reabrir el perfil una vez: los registradores antiguos no conservaban identificadores. No se ha iniciado una nueva carga.")
  end
  RhomScripts.registration_generation = 2
  if previous then
    if previous.comunicaciones then previous.comunicaciones.destruir() end
    -- Transición desde el arranque completo: retirar recursos sin volver a cargar dominios.
    if previous.prueba_cffi then previous.prueba_cffi.cerrar() end
    if previous.prueba_wxlua then previous.prueba_wxlua.cerrar() end
    if previous.oficial then previous.oficial.cancelar_configuracion() end
    if previous.configurador then
      local cerrado, mensaje
      if previous.configurador.destruir then cerrado, mensaje = previous.configurador.destruir()
      else cerrado, mensaje = previous.configurador.cerrar() end
      assert(cerrado, "No se puede recargar sin cerrar el configurador: " .. tostring(mensaje))
    end
    if previous.interfaz then previous.interfaz.destruir() end
    for _, name in ipairs({ "keys", "aliases", "triggers" }) do
      if previous[name] then previous[name].desregistrar() end
    end
    if previous.audio then previous.audio.stop_tag() end
    for name in pairs(previous) do package.loaded[name] = nil end
  end
  if soporte then
    if soporte.ui then soporte.ui.destruir() end
    if soporte.aliases then soporte.aliases.desregistrar() end
    if soporte.audio then soporte.audio.stop_tag() end
  end
  -- Mantener las instancias nativas wx/cffi cargadas; renovar solo adaptadores Lua.
  -- Retirar también nombres antiguos para actualizar sesiones anteriores a las fusiones.
  for _, name in ipairs({ "configuracion", "configurador", "lector", "comunicaciones", "comunicaciones_captura",
    "comunicaciones_historial", "keys", "audio", "sonidos",
    "oficial", "aliases", "comprobaciones", "arranque", "configurador_modelo", "ui", "ui.arbol", "ui.sonidos", "nativo", "interfaz", "pruebas" }) do
    package.loaded[name] = nil
  end
  RhomScripts.modules = {}
  RhomScripts.soporte = {}

  local root
  if type(RhomScriptsBasePath) == "string" and RhomScriptsBasePath ~= "" then
    root = RhomScriptsBasePath
  else
    root = getMudletHomeDir() .. "/rhomscripts"
  end
  root = root:gsub("[/\\]$", "")
  RhomScripts.root = root
  local module_path = root .. "/?.lua"
  if not (";" .. package.path .. ";"):find(";" .. module_path .. ";", 1, true) then
    package.path = module_path .. ";" .. package.path
  end

  local arranque = require("arranque")
  RhomScripts.soporte.arranque = arranque
  arranque.monitorizacion.iniciar()
  arranque.estado.actualizar("scripts", "iniciando", "iniciando scripts", "carga")
  local configuracion = require("configuracion")
  assert(configuracion.load(), "No se pudo leer la configuración de RhomScripts")
  RhomScripts.modules.configuracion = configuracion

  local function load_modules()
    echo("RhomScriptsRL - inicializando configuración, lector, comunicaciones y teclado...\n")
    startup_audio = require("audio")
    RhomScripts.soporte.audio = startup_audio
    RhomScripts.soporte.sonidos = require("sonidos")
    startup_audio.iniciar()
    RhomScripts.modules.configurador = require("configurador")
    RhomScripts.modules.lector = require("lector")
    RhomScripts.modules.comunicaciones = require("comunicaciones")
    RhomScripts.modules.comunicaciones.iniciar()
    RhomScripts.modules.keys = require("keys")
    local ui = require("ui")
    RhomScripts.soporte.ui = ui
    ui.preparar()
    local keys_result = RhomScripts.modules.keys.registrar()
    -- Descubrir únicamente los comandos de los módulos activos.
    local aliases = require("aliases")
    RhomScripts.soporte.aliases = aliases
    local aliases_result = aliases.registrar()
    assert(aliases_result.errors == 0, "No se pudieron registrar los comandos activos")
    echo(string.format("5 módulos, %d atajos de teclado, %d aliases de módulos y rhomestado, %d triggers\n",
      keys_result.success, aliases_result.success, RhomScripts.modules.comunicaciones.cantidad_triggers()))
    RhomScripts.init_time = os.time()
    RhomScripts.initialized = true
    RhomScripts.loading = false
    arranque.estado.actualizar("scripts", "cargados", "scripts cargados correctamente", "carga")
    raiseEvent("rl.init.done")
    raiseEvent("rhomscripts.ready", version)
    startup_audio.reproducir("ui.carga_ok")
    echo("RhomScriptsRL cargados correctamente\n")
    announce("RhomScripts: carga correcta.")
  end

  -- Dependencia de las preferencias oficiales del configurador, sin conectar al juego.
  RhomScripts.arranque_oficial = arranque.nuevo()
  RhomScripts.arranque_oficial:iniciar(function()
    protected(function()
      local resultado = arranque.aplicar_configuracion(configuracion)
      for _, mensaje in ipairs(resultado.pendientes) do echo(mensaje .. "\n") end
      arranque.vigilar()
      load_modules()
    end)
  end, failure)
end

protected(initialize)
