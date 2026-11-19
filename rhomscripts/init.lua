-- Entrada de configuración, configurador, ficha, lector, comunicaciones, mapa y teclas.
-- Audio, catálogo de sonidos, paquete oficial y registro de comandos son dependencias de soporte.
local depuracion
local startup_audio
local failure_reported = false

local function failure(message)
  RhomScripts.initialized = false
  RhomScripts.loading = false
  if failure_reported then error(message, 0) end
  failure_reported = true
  local errores = {}
  local function limpiar(accion)
    local correcto, mensaje = pcall(accion)
    if not correcto then errores[#errores + 1] = tostring(mensaje) end
  end
  if RhomScripts.recarga_timer then
    limpiar(function() killTimer(RhomScripts.recarga_timer); RhomScripts.recarga_timer = nil end)
  end
  if RhomScripts.arranque_oficial then limpiar(function() RhomScripts.arranque_oficial:cancelar() end) end
  if RhomScripts.oficial_configuracion then limpiar(RhomScripts.oficial_configuracion.cancelar_configuracion) end
  local modules, soporte = RhomScripts.modules, RhomScripts.soporte
  if soporte and soporte.arranque then limpiar(soporte.arranque.cancelar_configuracion) end
  if modules then
    if modules.mapa then limpiar(modules.mapa.destruir) end
    if modules.ficha then limpiar(modules.ficha.detener) end
    if modules.comunicaciones then limpiar(modules.comunicaciones.destruir) end
    if modules.configurador then limpiar(modules.configurador.destruir) end
    if modules.keys then limpiar(modules.keys.desregistrar) end
  end
  if soporte then
    if soporte.ui then limpiar(soporte.ui.destruir) end
    if soporte.aliases then
      limpiar(function()
        local propietarios = {}
        for _, registro in ipairs(soporte.aliases.consultar()) do propietarios[registro.modulo] = true end
        for nombre in pairs(propietarios) do
          if nombre ~= "debug" then limpiar(function() soporte.aliases.desregistrar(nombre) end) end
        end
      end)
    end
  end
  -- Completar la retirada antes de presentar: una API de salida también puede ser el fallo original.
  local detalle = tostring(message)
  if #errores > 0 then detalle = detalle .. "\nErrores adicionales de limpieza: " .. table.concat(errores, "\n") end
  local correcto, error_aviso = pcall(function()
    if depuracion then depuracion.fallar_carga(detalle)
    else
      local text = "RhomScripts: error de carga. " .. detalle
      echo(text .. "\n")
      announce(text)
    end
  end)
  if not correcto then detalle = detalle .. "\nError adicional al presentar el fallo: " .. tostring(error_aviso) end
  if startup_audio then
    local played, sound_error = pcall(startup_audio.reproducir, "ui.carga_erronea")
    if not played then detalle = detalle .. "\nError adicional en el aviso sonoro: " .. tostring(sound_error) end
  end
  error(detalle, 0)
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
  local datos_ficha
  if previous then
    if previous.mapa then previous.mapa.destruir() end
    if previous.ficha then
      datos_ficha = previous.ficha.datos()
      previous.ficha.detener()
    end
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
    for name in pairs(previous) do if name ~= "debug" then package.loaded[name] = nil end end
  end
  if soporte then
    if soporte.ui then soporte.ui.destruir() end
    if soporte.aliases then soporte.aliases.desregistrar() end
    if soporte.audio then soporte.audio.stop_tag() end
  end
  -- Mantener las instancias nativas wx/cffi cargadas; renovar solo adaptadores Lua.
  -- Retirar también nombres antiguos para actualizar sesiones anteriores a las fusiones.
  for _, name in ipairs({ "configuracion", "configurador", "lector", "comunicaciones", "comunicaciones_captura",
    "comunicaciones_historial", "mapa", "keys", "audio", "sonidos",
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

  depuracion = assert(loadfile(root .. "/debug.lua"))()
  RhomScripts.modules.debug = depuracion
  depuracion.iniciar_carga()
  depuracion.planificar({
    { nombre = "debug", tipo = "funcional" },
    { nombre = "aliases", dependencias = { "debug" } },
    { nombre = "arranque", dependencias = { "debug" } },
    { nombre = "ficha", tipo = "funcional", dependencias = { "arranque" } },
    { nombre = "configuracion", tipo = "funcional" },
    { nombre = "sonidos" },
    { nombre = "audio", dependencias = { "sonidos", "configuracion" } },
    { nombre = "ui", dependencias = { "audio", "configuracion", "arranque" } },
    { nombre = "configurador", tipo = "funcional", dependencias = { "ui" } },
    { nombre = "mapa", tipo = "funcional", dependencias = { "ui", "arranque", "ficha" } },
    { nombre = "lector", tipo = "funcional" },
    { nombre = "comunicaciones_historial", dependencias = { "ui" } },
    { nombre = "comunicaciones_captura" },
    { nombre = "comunicaciones", tipo = "funcional", dependencias = { "comunicaciones_historial", "comunicaciones_captura" } },
    { nombre = "keys", tipo = "funcional" },
  })
  depuracion.modulo("debug", "cargado")
  local function cargar(nombre, destino, preparar)
    depuracion.modulo(nombre, "iniciando")
    local correcto, resultado = pcall(function()
      local modulo = require(nombre)
      destino[nombre] = modulo
      if preparar then preparar(modulo) end
      return modulo
    end)
    if not correcto then
      depuracion.modulo(nombre, "error", tostring(resultado))
      error(resultado, 0)
    end
    depuracion.modulo(nombre, "cargado")
    return resultado
  end
  local aliases = cargar("aliases", RhomScripts.soporte, function(modulo)
    depuracion.proveedor("alias", modulo.consultar)
    modulo.registrar_modulo("debug", depuracion.aliases)
  end)
  local arranque = cargar("arranque", RhomScripts.soporte)
  cargar("ficha", RhomScripts.modules, function(modulo) modulo.iniciar(datos_ficha) end)
  arranque.monitorizacion.iniciar()
  arranque.estado.actualizar("scripts", "iniciando", depuracion.detalle("scripts_iniciando"), "carga")
  local configuracion = cargar("configuracion", RhomScripts.modules, function(modulo)
    assert(modulo.load(), "No se pudo leer la configuración de RhomScripts")
  end)

  local function load_modules()
    cargar("sonidos", RhomScripts.soporte, function(modulo)
      depuracion.proveedor("sonidos", modulo.consultar)
    end)
    startup_audio = cargar("audio", RhomScripts.soporte, function(modulo)
      startup_audio = modulo
      modulo.iniciar()
    end)
    cargar("configurador", RhomScripts.modules)
    cargar("lector", RhomScripts.modules)
    cargar("comunicaciones", RhomScripts.modules, function(modulo)
      depuracion.proveedor("triggers", modulo.consultar_triggers)
      modulo.iniciar()
    end)
    cargar("mapa", RhomScripts.modules, function(modulo) modulo.iniciar() end)
    -- Dependencias cargadas por sus dominios: se exponen sin duplicar instancias.
    for _, nombre in ipairs({ "comunicaciones_historial", "comunicaciones_captura" }) do
      RhomScripts.soporte[nombre] = package.loaded[nombre]
      depuracion.modulo(nombre, "cargado")
    end
    cargar("ui", RhomScripts.soporte, function(modulo) modulo.preparar() end)
    cargar("keys", RhomScripts.modules, function(modulo)
      depuracion.proveedor("keys", modulo.consultar)
      modulo.registrar()
    end)
    local correcto, aliases_result = pcall(aliases.registrar)
    if not correcto then
      depuracion.modulo("aliases", "error", tostring(aliases_result))
      error(aliases_result, 0)
    end
    assert(aliases_result.errors == 0, "No se pudieron registrar los comandos activos")
    RhomScripts.init_time = os.time()
    RhomScripts.initialized = true
    RhomScripts.loading = false
    arranque.estado.actualizar("scripts", "cargados", depuracion.detalle("scripts_cargados"), "carga")
    raiseEvent("rl.init.done")
    raiseEvent("rhomscripts.ready", depuracion.version())
    startup_audio.reproducir("ui.carga_ok")
    depuracion.terminar_carga()
  end

  -- Dependencia de las preferencias oficiales del configurador, sin conectar al juego.
  RhomScripts.arranque_oficial = arranque.nuevo()
  RhomScripts.arranque_oficial:iniciar(function()
    protected(function()
      local resultado = arranque.aplicar_configuracion(configuracion)
      for _, mensaje in ipairs(resultado.pendientes) do depuracion.texto("arranque", mensaje) end
      arranque.vigilar()
      load_modules()
    end)
  end, failure)
end

protected(initialize)
