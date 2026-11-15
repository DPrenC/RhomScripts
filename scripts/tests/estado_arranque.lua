-- Transiciones de red simuladas; registro y retirada delegan a las APIs del entorno.
-- No se emiten eventos GMCP globales que activen servicios del paquete oficial.
-- luacheck: globals gmcp RL_vars getConnectionInfo registerAnonymousEventHandler killAnonymousEventHandler raiseEvent
local suite = {}

local function equal(actual, expected)
  assert(actual == expected, "Esperado " .. tostring(expected) .. "; obtenido " .. tostring(actual))
end

function suite.run(case, module_path)
  local original_register, original_kill = registerAnonymousEventHandler, killAnonymousEventHandler
  local original_connection, original_gmcp, original_raise = getConnectionInfo, gmcp, raiseEvent
  local original_rl = RL_vars
  local handlers, changes = {}, {}
  local connected = false
  local monitor
  local function live_count()
    local count = 0
    for _ in pairs(handlers) do count = count + 1 end
    return count
  end
  local function dispatch(event, ...)
    local pending = {}
    for _, handler in pairs(handlers) do
      if handler.event == event then pending[#pending + 1] = handler.callback end
    end
    for _, callback in ipairs(pending) do callback(event, ...) end
  end
  local function state(component)
    return assert(monitor.estado.consultar()[component], "Falta el componente " .. component)
  end
  local function prepare()
    monitor.monitorizacion.detener()
    connected, gmcp = false, {}
    monitor.monitorizacion.iniciar()
  end
  registerAnonymousEventHandler = function(event, callback, ...)
    local id = original_register(event, callback, ...)
    handlers[id] = { event = event, callback = callback }
    return id
  end
  killAnonymousEventHandler = function(id)
    local result = original_kill(id)
    handlers[id] = nil
    return result
  end
  getConnectionInfo = function() return "servidor-simulado", 0, connected end
  raiseEvent = function(event, ...)
    if event == "rhomscripts.estado.cambiado" then changes[#changes + 1] = { ... } end
    return original_raise(event, ...)
  end
  local ok, message = pcall(function()
    monitor = dofile(module_path)

    case("Estado: opciones anidadas no retroceden a inicializando al terminar config_loaded", function()
      RL_vars = { name = "RLMud_Config", path = "estado-oficial/" }
      prepare()
      dispatch("rlmud_config_loaded")
      equal(state("paquete").codigo, "inicializando")
      RL_vars.opciones = {}
      dispatch("rlmud_opciones_inicializadas")
      equal(state("paquete").codigo, "preparado")
      -- El listener externo recibe config_loaded después del evento anidado.
      dispatch("rlmud_config_loaded")
      equal(state("paquete").codigo, "preparado")
      RL_vars.path = ""
      dispatch("rlmud_opciones_inicializadas")
      equal(state("paquete").codigo, "inicializando")
      RL_vars = original_rl
    end)

    case("Estado: consulta devuelve copias y un cambio idéntico no emite otro evento", function()
      prepare()
      monitor.estado.actualizar("scripts", "iniciando", "Inicio de prueba", "prueba")
      local snapshot = monitor.estado.consultar()
      equal(snapshot.scripts.codigo, "iniciando")
      assert(type(snapshot.scripts.actualizado) == "number")
      equal(snapshot.scripts.causa, "prueba")
      assert(not pcall(monitor.estado.actualizar, "scripts", "iniciando", "Inválido", {}),
        "La causa no puede introducir referencias mutables en las consultas")
      snapshot.scripts.codigo = "alterado"
      equal(state("scripts").codigo, "iniciando")
      local entry = monitor.estado.consultar("scripts")
      entry.detalle = "alterado"
      equal(state("scripts").detalle, "Inicio de prueba")
      local count = #changes
      monitor.estado.actualizar("scripts", "iniciando", "Inicio de prueba", "otra causa")
      equal(#changes, count)
      monitor.estado.actualizar("scripts", "iniciando", "Nuevo detalle", "prueba")
      equal(#changes, count + 1)
      equal(changes[#changes][1], "scripts")
      equal(changes[#changes][2], "iniciando")
      equal(changes[#changes][3], "Nuevo detalle")
    end)

    case("Estado: protocolo deshabilitado retira datos sin declarar desconexión TCP", function()
      prepare()
      connected = true
      dispatch("sysConnectionEvent")
      gmcp = { Core = { Hello = {} } }
      dispatch("gmcp.Core.Hello")
      dispatch("gmcp.Char.Ficha")
      dispatch("sysProtocolDisabled", "MSDP")
      equal(state("gmcp").codigo, "activo")
      dispatch("sysProtocolDisabled", "GMCP")
      equal(state("gmcp").codigo, "deshabilitado")
      equal(state("ficha").codigo, "pendiente")
      equal(state("conexion").codigo, "conectada")
    end)

    case("Estado: una carga tardía toma datos GMCP existentes solo estando conectado", function()
      prepare()
      monitor.monitorizacion.detener()
      connected = true
      gmcp = { Core = { Hello = {} }, Char = { Ficha = {}, Status = {} }, Comm = { Canales = {} } }
      monitor.monitorizacion.iniciar()
      equal(state("gmcp").codigo, "activo")
      equal(state("ficha").codigo, "recibido")
      equal(state("estado_personaje").codigo, "recibido")
      equal(state("comunicaciones").codigo, "recibido")
      monitor.monitorizacion.detener()
      connected = false
      monitor.monitorizacion.iniciar()
      equal(state("gmcp").codigo, "desconectado")
      equal(state("ficha").codigo, "pendiente")
    end)

    case("Estado: recursos MSP filtran descargas ajenas y separan descarga de extracción", function()
      RL_vars = { opciones = {}, msp = { archivo = "estado-prueba/sonidos.zip", descargando = true } }
      prepare()
      equal(state("msp").codigo, "inicializado")
      equal(state("recursos_msp").codigo, "descargando")
      dispatch("sysDownloadDone", "estado-prueba/mapa.zip")
      equal(state("recursos_msp").codigo, "descargando")
      dispatch("sysDownloadDone", RL_vars.msp.archivo)
      equal(state("recursos_msp").codigo, "extrayendo")
      dispatch("sysUnzipDone", RL_vars.msp.archivo, "estado-prueba/")
      equal(state("recursos_msp").codigo, "disponibles")
      dispatch("sysDownloadError", "fallo simulado", "estado-prueba/mapa.zip")
      equal(state("recursos_msp").codigo, "disponibles")
      dispatch("sysDownloadError", "fallo simulado", RL_vars.msp.archivo)
      equal(state("recursos_msp").codigo, "error")
      RL_vars = original_rl
    end)

    case("Estado: cambiar el directorio MSP invalida la disponibilidad de la ruta anterior", function()
      RL_vars = { opciones = {}, msp = { archivo = "estado-ruta/sonidos.zip",
        default_path = "estado-ruta/", path = "estado-ruta/", descargando = false } }
      prepare()
      dispatch("sysUnzipDone", RL_vars.msp.archivo, RL_vars.msp.path)
      equal(state("recursos_msp").codigo, "disponibles")
      RL_vars.msp.descargando = true -- Indicador de una descarga de la ruta anterior.
      RL_vars.opciones.msp_directorio_sonidos = "estado-ruta-nueva/"
      dispatch("rlmud_fijar_opcion_msp_directorio_sonidos", RL_vars.opciones.msp_directorio_sonidos)
      equal(state("recursos_msp").codigo, "sin_verificar")
      dispatch("sysUnzipDone", RL_vars.msp.archivo, RL_vars.msp.path)
      equal(state("recursos_msp").codigo, "sin_verificar")
      RL_vars = original_rl
    end)

    case("Estado: un error MSP persiste al revisar un indicador de descarga obsoleto", function()
      RL_vars = { opciones = {}, msp = { archivo = "estado-error/sonidos.zip",
        default_path = "estado-error/", path = "estado-error/", descargando = true } }
      prepare()
      equal(state("recursos_msp").codigo, "descargando")
      dispatch("sysDownloadError", "fallo simulado", RL_vars.msp.archivo)
      equal(state("recursos_msp").codigo, "error")
      assert(RL_vars.msp.descargando, "La prueba necesita el indicador oficial obsoleto")
      dispatch("rl_gmcp_hello")
      equal(state("recursos_msp").codigo, "error")
      RL_vars = original_rl
    end)

    case("Estado: conexión, protocolo y saludo son confirmaciones diferentes", function()
      prepare()
      connected = true
      dispatch("sysConnectionEvent")
      equal(state("gmcp").codigo, "esperando")
      dispatch("sysProtocolEnabled", "GMCP")
      equal(state("gmcp").codigo, "habilitado")
      dispatch("rl_gmcp_hello")
      assert(state("gmcp").codigo ~= "activo", "La señal local simuló un saludo del servidor")
      gmcp.Core = { Hello = { name = "servidor-simulado" } }
      dispatch("gmcp.Core.Hello")
      equal(state("gmcp").codigo, "activo")
    end)

    case("Estado: recepción por módulo y desconexión retiran confirmaciones antiguas", function()
      prepare()
      connected = true
      dispatch("sysConnectionEvent")
      gmcp = { Core = { Hello = {} }, Char = { Ficha = {}, Status = {} }, Comm = { Canales = {} } }
      dispatch("gmcp.Core.Hello")
      dispatch("gmcp.Char.Ficha")
      dispatch("gmcp.Char.Status")
      dispatch("gmcp.Comm.Canales")
      equal(state("ficha").codigo, "recibido")
      equal(state("estado_personaje").codigo, "recibido")
      equal(state("comunicaciones").codigo, "recibido")
      connected = false
      dispatch("sysDisconnectionEvent")
      equal(state("gmcp").codigo, "desconectado")
      for _, component in ipairs({ "ficha", "estado_personaje", "comunicaciones" }) do
        equal(state(component).codigo, "pendiente")
      end
      connected = true
      dispatch("sysConnectionEvent")
      assert(state("gmcp").codigo ~= "activo", "La conexión nueva reutilizó Hello antiguo")
    end)

    case("Estado: iniciar dos veces sustituye listeners y detener los retira", function()
      prepare()
      local count = live_count()
      assert(count > 0, "No se registró la vigilancia")
      monitor.monitorizacion.iniciar()
      equal(live_count(), count)
      monitor.monitorizacion.detener()
      equal(live_count(), 0)
      local previous = state("gmcp").codigo
      dispatch("gmcp.Core.Hello")
      equal(state("gmcp").codigo, previous)
    end)

    case("Estado: API de eventos ausente produce error y permite reintento limpio", function()
      monitor.monitorizacion.detener()
      local wrapped_register = registerAnonymousEventHandler
      registerAnonymousEventHandler = nil
      local started = pcall(monitor.monitorizacion.iniciar)
      registerAnonymousEventHandler = wrapped_register
      assert(not started, "Se ocultó registerAnonymousEventHandler ausente")
      equal(live_count(), 0)
      -- El intento fallido debe limpiarse solo; no detener antes del reintento.
      monitor.monitorizacion.iniciar()
      assert(live_count() > 0, "El inicio fallido dejó el monitor bloqueado para reintentar")
    end)
  end)
  if monitor then monitor.monitorizacion.detener() end
  registerAnonymousEventHandler, killAnonymousEventHandler = original_register, original_kill
  getConnectionInfo, gmcp, raiseEvent = original_connection, original_gmcp, original_raise
  RL_vars = original_rl
  assert(ok, message)
  equal(live_count(), 0)
end

return suite
