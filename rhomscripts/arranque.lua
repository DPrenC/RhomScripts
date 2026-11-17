-- Coordinación de arranque, preferencias oficiales y estado de la sesión.
local arranque = { nombre = "RLMud_Config",
  url = "https://mudlet.reinosdeleyenda.es/RLMud_Config.zip", espera = 60 }

-- El registro y la presentación pertenecen a debug; las señales siguen aquí.
local depuracion = assert(RhomScripts.modules.debug)
arranque.estado = depuracion.estado
arranque.monitorizacion = {}
local orden = { "scripts", "paquete", "preferencias", "conexion", "gmcp", "ficha",
  "estado_personaje", "comunicaciones", "msp", "recursos_msp" }
local monitor_handlers = {}
local monitor_activo = false
local sesion_gmcp = false
local ruta_recursos_msp
local descarga_msp_terminada = false
local function activo()
  return RL_vars and RL_vars.name == arranque.nombre
    and type(RL_vars.path) == "string" and RL_vars.path ~= ""
    and type(RL_vars.opciones) == "table"
end

-- Monitor: señales del servidor y estado local son evidencias independientes.
local actualizar = arranque.estado.actualizar
local function revisar_paquete(causa)
  if activo() then
    actualizar("paquete", "preparado", depuracion.detalle("local_listo"), causa)
  else
    actualizar("paquete", "inicializando", depuracion.detalle("local_iniciando"), causa)
  end
end

local function datos_pendientes(causa)
  for _, nombre in ipairs({ "ficha", "estado_personaje", "comunicaciones" }) do
    actualizar(nombre, "pendiente", depuracion.detalle("datos_pendientes"), causa)
  end
end

local function desconectado(causa)
  sesion_gmcp = false
  actualizar("conexion", "desconectada", depuracion.detalle("desconectada"), causa)
  actualizar("gmcp", "desconectado", depuracion.detalle("sin_conexion"), causa)
  datos_pendientes(causa)
end

local function revisar_msp(causa)
  local opciones = RL_vars and RL_vars.opciones
  local msp = RL_vars and RL_vars.msp
  local ruta = opciones and (opciones.msp_directorio_sonidos or (msp and msp.default_path))
    or (msp and msp.path)
  if ruta ~= ruta_recursos_msp then
    ruta_recursos_msp = ruta
    descarga_msp_terminada = false
    actualizar("recursos_msp", "sin_verificar", depuracion.detalle("sonidos_sin_verificar"), causa)
  end
  if not RL_vars or not RL_vars.opciones then
    actualizar("msp", "pendiente", depuracion.detalle("opciones_pendientes"), causa)
    actualizar("recursos_msp", "pendiente", depuracion.detalle("sin_comprobar"), causa)
  elseif RL_vars.opciones.msp_desactivar then
    actualizar("msp", "desactivado", depuracion.detalle("desactivado"), causa)
  elseif RL_vars.msp then
    actualizar("msp", "inicializado", depuracion.detalle("msp_inicializado"), causa)
    if RL_vars.msp.descargando and not descarga_msp_terminada
        and (not ruta_recursos_msp or RL_vars.msp.path == ruta_recursos_msp) then
      actualizar("recursos_msp", "descargando", depuracion.detalle("sonidos_descargando"), causa)
    elseif not arranque.estado.consultar("recursos_msp") or arranque.estado.consultar("recursos_msp").codigo == "pendiente" then
      actualizar("recursos_msp", "sin_verificar", depuracion.detalle("sonidos_sin_verificar"), causa)
    end
  else
    actualizar("msp", "pendiente", depuracion.detalle("msp_esperando"), causa)
  end
end

local function descarga_msp(evento, primero, segundo)
  local msp = RL_vars and RL_vars.msp
  if not msp then return end
  local archivo = evento == "sysDownloadError" and segundo or primero
  if archivo ~= msp.archivo then return end
  if ruta_recursos_msp and msp.path ~= ruta_recursos_msp then return end
  descarga_msp_terminada = true
  if evento == "sysDownloadDone" then
    actualizar("recursos_msp", "extrayendo", depuracion.detalle("sonidos_extrayendo"), evento)
  elseif evento == "sysUnzipDone" then
    actualizar("recursos_msp", "disponibles", depuracion.detalle("sonidos_extraidos"), evento)
  else
    actualizar("recursos_msp", "error", evento == "sysDownloadError"
      and ("error de descarga: " .. tostring(primero)) or depuracion.detalle("error_extraer_sonidos"), evento)
  end
end

function arranque.monitorizacion.detener()
  for _, id in ipairs(monitor_handlers) do killAnonymousEventHandler(id) end
  monitor_handlers = {}
  monitor_activo = false
end

local function iniciar_monitor()
  local function escuchar(evento, accion)
    monitor_handlers[#monitor_handlers + 1] = registerAnonymousEventHandler(evento, accion)
  end
  for _, nombre in ipairs(orden) do
    if not arranque.estado.consultar(nombre) then actualizar(nombre, "pendiente", depuracion.detalle("sin_comprobar"), "monitor") end
  end
  escuchar("sysConnectionEvent", function(evento)
    sesion_gmcp = false
    actualizar("conexion", "conectada", depuracion.detalle("conectada"), evento)
    actualizar("gmcp", "esperando", depuracion.detalle("gmcp_esperando"), evento)
    datos_pendientes(evento)
  end)
  escuchar("sysDisconnectionEvent", desconectado)
  escuchar("sysProtocolEnabled", function(evento, protocolo)
    if protocolo == "GMCP" and not sesion_gmcp then
      actualizar("gmcp", "habilitado", depuracion.detalle("gmcp_habilitado"), evento)
    end
  end)
  escuchar("sysProtocolDisabled", function(evento, protocolo)
    if protocolo == "GMCP" then
      sesion_gmcp = false
      actualizar("gmcp", "deshabilitado", depuracion.detalle("gmcp_deshabilitado"), evento)
      datos_pendientes(evento)
    end
  end)
  escuchar("gmcp.Core.Hello", function(evento)
    sesion_gmcp = true
    actualizar("gmcp", "activo", depuracion.detalle("gmcp_activo"), evento)
  end)
  escuchar("gmcp.Core.Goodbye", function(evento)
    sesion_gmcp = false
    actualizar("gmcp", "finalizado", depuracion.detalle("gmcp_finalizado"), evento)
    datos_pendientes(evento)
  end)
  local recibidos = { ["gmcp.Char.Ficha"] = "ficha", ["gmcp.Char.Status"] = "estado_personaje",
    ["gmcp.Comm.Canales"] = "comunicaciones", ["gmcp.Comm.MensajeCanal"] = "comunicaciones",
    ["gmcp.Comm.MensajeCanalHistorico"] = "comunicaciones" }
  for evento, componente in pairs(recibidos) do
    local nombre = componente
    escuchar(evento, function(causa) actualizar(nombre, "recibido", depuracion.detalle("datos_recibidos"), causa) end)
  end
  escuchar("rlmud_config_loaded", function(evento)
    revisar_paquete(evento)
    revisar_msp(evento)
  end)
  escuchar("rlmud_opciones_inicializadas", function(evento)
    revisar_paquete(evento)
    revisar_msp(evento)
  end)
  for _, evento in ipairs({ "rlmud_fijar_opcion_msp_desactivar", "rlmud_borrar_opcion_msp_desactivar",
    "rlmud_fijar_opcion_msp_directorio_sonidos", "rl_gmcp_hello" }) do
    escuchar(evento, revisar_msp)
  end
  for _, evento in ipairs({ "sysDownloadDone", "sysDownloadError", "sysUnzipDone", "sysUnzipError" }) do
    escuchar(evento, descarga_msp)
  end
  escuchar("sysUninstallPackage", function(evento, nombre)
    if nombre == arranque.nombre then
      actualizar("paquete", "ausente", depuracion.detalle("paquete_ausente"), evento)
      actualizar("preferencias", "pendientes", depuracion.detalle("paquete_no_disponible"), evento)
      actualizar("msp", "pendiente", depuracion.detalle("paquete_no_disponible"), evento)
    end
  end)
  local _, _, conectado = getConnectionInfo()
  if conectado then
    actualizar("conexion", "conectada", depuracion.detalle("conectada"), "consulta inicial")
    sesion_gmcp = gmcp and gmcp.Core and gmcp.Core.Hello and true or false
    actualizar("gmcp", sesion_gmcp and "activo" or "esperando",
      sesion_gmcp and depuracion.detalle("gmcp_disponible") or depuracion.detalle("gmcp_esperando"), "consulta inicial")
    if sesion_gmcp then
      if gmcp.Char and gmcp.Char.Ficha then actualizar("ficha", "recibido", depuracion.detalle("ficha_disponible"), "consulta inicial") end
      if gmcp.Char and gmcp.Char.Status then actualizar("estado_personaje", "recibido", depuracion.detalle("estado_disponible"), "consulta inicial") end
      if gmcp.Comm and next(gmcp.Comm) then actualizar("comunicaciones", "recibido", depuracion.detalle("comunicaciones_disponibles"), "consulta inicial") end
    end
  else
    desconectado("consulta inicial")
  end
  revisar_msp("consulta inicial")
end

function arranque.monitorizacion.iniciar()
  if monitor_activo then return end
  local correcto, mensaje = pcall(iniciar_monitor)
  if not correcto then
    local limpio, error_limpieza = pcall(arranque.monitorizacion.detener)
    if not limpio then mensaje = tostring(mensaje) .. "\nError al limpiar el monitor: " .. tostring(error_limpieza) end
    error(mensaje, 0)
  end
  monitor_activo = true
end

-- Bibliotecas: las instancias nativas sobreviven a la recarga de la fachada Lua.

local function biblioteca(nombre, ruta, simbolo, ...)
  if package.loaded[nombre] then return package.loaded[nombre] end
  local iniciar, mensaje = package.loadlib(assert(RhomScripts.root) .. ruta, simbolo)
  assert(iniciar, "No se pudo cargar " .. nombre .. ": " .. tostring(mensaje))
  local modulo = assert(iniciar(...), nombre .. " no devolvió su módulo")
  package.loaded[nombre] = modulo
  return modulo
end

function arranque.cargar_wx()
  return biblioteca("wx", "/lib/windows-x64/wxlua/wx.dll", "luaopen_wx", "wx")
end

function arranque.cargar_nativo()
  if package.loaded.rhom_nativo_runtime then return package.loaded.rhom_nativo_runtime end
  local ffi = biblioteca("cffi", "/lib/windows-x64/cffi/cffi.dll", "luaopen_cffi")
  assert(ffi.sizeof("void *") == 8, "La integración nativa requiere Windows x64")
  ffi.cdef [[
    typedef void * RHOM_HWND;
    typedef unsigned int RHOM_DWORD;
    typedef long long RHOM_LONG_PTR;
    typedef int (__stdcall *RHOM_WNDENUMPROC)(RHOM_HWND, RHOM_LONG_PTR);
    RHOM_DWORD GetCurrentProcessId(void);
    RHOM_DWORD GetLastError(void);
    void SetLastError(RHOM_DWORD);
    int IsWindow(RHOM_HWND);
    int IsWindowVisible(RHOM_HWND);
    RHOM_DWORD GetWindowThreadProcessId(RHOM_HWND, RHOM_DWORD *);
    RHOM_HWND GetActiveWindow(void);
    RHOM_HWND GetAncestor(RHOM_HWND, unsigned int);
    RHOM_HWND GetWindow(RHOM_HWND, unsigned int);
    RHOM_LONG_PTR SetWindowLongPtrW(RHOM_HWND, int, RHOM_LONG_PTR);
    int EnumWindows(RHOM_WNDENUMPROC, RHOM_LONG_PTR);
    int GetClassNameW(RHOM_HWND, unsigned short *, int);
  ]]
  local runtime = { ffi = ffi, user32 = ffi.load("user32.dll"), kernel32 = ffi.load("kernel32.dll") }
  package.loaded.rhom_nativo_runtime = runtime
  return runtime
end

function arranque.bibliotecas()
  return { wx = arranque.cargar_wx(), nativo = arranque.cargar_nativo() }
end

local function instalado()
  for _, nombre in ipairs(getPackages()) do
    if nombre == arranque.nombre then return true end
  end
  return false
end

function arranque.nuevo()
  local control = { estado = "pendiente", handlers = {}, temporizadores = {} }

  function control:cancelar()
    for _, id in ipairs(self.handlers) do killAnonymousEventHandler(id) end
    self.handlers = {}
    for id in pairs(self.temporizadores) do killTimer(id) end
    self.temporizadores = {}
    if self.estado == "esperando" or self.estado == "pendiente" then
      self.estado = "cancelado"
    end
  end

  function control:iniciar(continuar, fallar)
    assert(self.estado == "pendiente", "El arranque oficial ya se ha iniciado")
    self.estado = "esperando"
    local function fallo(mensaje)
      self:cancelar()
      self.estado = "error"
      actualizar("paquete", "error", tostring(mensaje), "preparación")
      fallar("Comprobaciones previas: " .. tostring(mensaje))
    end
    local function protegido(accion)
      local ok, mensaje = pcall(accion)
      if not ok then
        if self.estado == "activo" or self.estado == "error" then error(mensaje, 0) end
        fallo(mensaje)
      end
    end
    local function comprobar()
      if self.estado ~= "esperando" then return end
      if instalado() and activo() then
        self:cancelar()
        self.estado = "activo"
        actualizar("paquete", "preparado", depuracion.detalle("local_listo"), "comprobación")
        depuracion.mensaje("arranque", "oficial_activo")
        continuar()
      end
    end
    local function temporizador(segundos, accion)
      local id
      id = tempTimer(segundos, function()
        self.temporizadores[id] = nil
        protegido(accion)
      end)
      self.temporizadores[id] = true
    end
    local function escuchar(evento, accion)
      self.handlers[#self.handlers + 1] = registerAnonymousEventHandler(evento, function(...)
        local args = { ... }
        protegido(function() accion(unpack(args)) end)
      end)
    end
    -- Dejar terminar los listeners oficiales de opciones antes de continuar.
    local function despues_del_evento()
      temporizador(0, comprobar)
    end

    protegido(function()
      actualizar("paquete", "comprobando", depuracion.detalle("paquete_comprobando"), "preparación")
      arranque.bibliotecas()
      escuchar("rlmud_opciones_inicializadas", despues_del_evento)
      escuchar("sysInstallPackage", function(_, nombre)
        if nombre == arranque.nombre then despues_del_evento() end
      end)
      temporizador(arranque.espera, function()
        error("No se ha confirmado la inicialización local en " .. arranque.espera .. " segundos.")
      end)

      if instalado() then
        depuracion.mensaje("arranque", "oficial_instalado")
        comprobar()
        if self.estado == "esperando" then
          actualizar("paquete", "esperando", depuracion.detalle("local_esperando"), "preparación")
          depuracion.mensaje("arranque", "oficial_esperando")
        end
        return
      end

      depuracion.mensaje("arranque", "oficial_instalando")
      actualizar("paquete", "descargando", depuracion.detalle("paquete_descargando"), "preparación")
      -- Una ruta por intento impide confundir descargas antiguas al recargar.
      RhomScripts.oficial_generacion = (RhomScripts.oficial_generacion or 0) + 1
      self.archivo = getMudletHomeDir() .. "/rhomscripts-oficial-"
        .. os.time() .. "-" .. RhomScripts.oficial_generacion .. ".zip"
      escuchar("sysDownloadError", function(_, motivo, archivo)
        if archivo == self.archivo then error("Error de descarga: " .. tostring(motivo)) end
      end)
      escuchar("sysDownloadDone", function(_, archivo)
        if archivo ~= self.archivo then return end
        actualizar("paquete", "instalando", depuracion.detalle("paquete_instalando"), "descarga")
        local ok, motivo = installPackage(archivo)
        if not ok then error("Error de instalación: " .. tostring(motivo)) end
        if not instalado() then error("La instalación no registró RLMud_Config.") end
        depuracion.mensaje("arranque", "oficial_instalado")
        os.remove(archivo)
        despues_del_evento()
      end)
      downloadFile(self.archivo, arranque.url)
    end)
  end

  return control
end

-- Preferencias oficiales de Reinos y aplicación durante la sesión.
-- El paquete mantiene su mapa, sus preferencias y sus servicios.

-- Las preferencias guardadas son la autoridad. Esta copia evita aplicar las
-- ediciones todavía no guardadas del menú al recibir un evento de conexión.
local preferencias
local aplicando = false
local handlers_configuracion = {}
local timer_configuracion
local guardado_pendiente = false
local claves = {
  "interfaz", "canales", "canales_consola", "teclado", "macros", "msp",
  "discord", "descargar_mapa", "fuente_canales", "comunicaciones", "msp_debug",
}

local function preparado_gmcp()
  local _, _, conectado = getConnectionInfo()
  return conectado and gmcp and gmcp.Core and gmcp.Core.Hello
end

local function tecla(nombre, habilitar)
  if (isActive(nombre, "keybind") > 0) ~= habilitar then
    if habilitar then enableKey(nombre) else disableKey(nombre) end
  end
end

local function aplicar(valores)
  assert(RL_vars and type(RL_vars.opciones) == "table", "El paquete oficial no está inicializado")
  local resultado = { pendientes = {} }
  local opciones = RL_vars.opciones
  local interfaz_anterior = not opciones.no_mostrar_interfaz
  local canales_anteriores = not opciones.no_mostrar_canales
  local msp_anterior = not opciones.msp_desactivar
  local discord_anterior = not opciones.no_discord
  local macros_anteriores = opciones.macros == true
  local fuente_anterior = opciones.tamanyo_fuente_canales
  local fuente = valores.fuente_canales ~= 0 and valores.fuente_canales or nil
  local objetivo = {
    no_mostrar_interfaz = not valores.interfaz,
    no_mostrar_canales = not valores.canales,
    sin_canales_pantalla_principal = not valores.canales_consola,
    macros = valores.macros,
    msp_desactivar = not valores.msp,
    no_discord = not valores.discord,
    no_descargar_mapa = not valores.descargar_mapa,
    msp_debug = valores.msp_debug,
  }
  local cambiado = fuente_anterior ~= fuente
  for nombre, valor in pairs(objetivo) do
    -- nil ya representa el valor predeterminado falso de estas opciones.
    if (opciones[nombre] or false) ~= valor then
      opciones[nombre] = valor
      cambiado = true
    end
  end
  opciones.tamanyo_fuente_canales = fuente
  -- El listener oficial de fuente falla con el panel oculto. Guardar el lote
  -- mediante su función pública y aplicar explícitamente evita ese listener.
  if cambiado or guardado_pendiente then
    guardado_pendiente = true
    assert(RL_salvar_opciones(true), "No se pudieron guardar las preferencias oficiales")
    guardado_pendiente = false
  end

  local contenedores = RL_vars.GUI and RL_vars.GUI.contenedores or {}
  local derecho = contenedores.contenedor_derecho
  local panel = contenedores.widget_comm
  local visible = derecho ~= nil and not derecho.hidden
  local panel_visible = panel ~= nil and not panel.hidden
  local reconstruir = interfaz_anterior ~= valores.interfaz
    or (valores.interfaz and canales_anteriores ~= valores.canales)
    or visible ~= valores.interfaz
    or (valores.interfaz and panel_visible ~= valores.canales)
  if reconstruir then
    -- Una sola reconstrucción para interfaz y canales. No reinicia el perfil.
    RL_gui_reinicializar()
  end
  if valores.interfaz and valores.canales then
    -- Actualizar las consolas existentes sin recrear pestañas ni historiales.
    local tamanyo = math.max(8, math.min(50, fuente or getFontSize()))
    for nombre in pairs(RL_vars.GUI.contenedores) do
      local canal = nombre:match("^widget_comm_consola_(.+)$")
      if canal and getFontSize(nombre) ~= tamanyo then
        assert(RL_gui_fijar_tamanyo_fuente_consola(canal, tamanyo), "No se pudo ajustar la fuente del canal " .. canal)
      end
    end
  elseif fuente ~= nil then
    resultado.pendientes[#resultado.pendientes + 1] = depuracion.pendiente("fuente_pendiente")
  end

  if valores.teclado or valores.macros then
    tecla("RLMud_Config", true)
    tecla("Config", true)
  end
  tecla("Numpad", valores.teclado)
  if valores.macros then
    local clase = preparado_gmcp() and gmcp.Char and gmcp.Char.Ficha and gmcp.Char.Ficha.clase
    if clase then
      if not macros_anteriores or isActive("Macros", "keybind") == 0
          or RL_vars.macros.current_clase ~= tostring(clase) then
        assert(RL_macros_activar(true), "No se pudieron activar las macros oficiales")
      end
    else
      tecla("Macros", false)
      resultado.pendientes[#resultado.pendientes + 1] = depuracion.pendiente("macros_pendientes")
    end
  else
    tecla("Macros", false)
  end

  if valores.msp then
    if not msp_anterior or not RL_vars.msp then RL_inicializar_MSP() end
  elseif msp_anterior or (RL_vars.msp and next(RL_vars.msp.data or {}) ~= nil) then
    if RL_vars.msp then RL_msp_stop_all() end
  end

  if valores.discord then
    if preparado_gmcp() then
      if not discord_anterior or not RL_vars.discord then RL_discord_inicializar() end
    else
      resultado.pendientes[#resultado.pendientes + 1] = depuracion.pendiente("discord_pendiente")
    end
  elseif RL_vars.discord and RL_vars.discord.timer_actualizar then
    killTimer(RL_vars.discord.timer_actualizar)
    RL_vars.discord.timer_actualizar = nil
  end

  -- La GUI oficial puede cambiar Comm al reinicializarse. Nuestra suscripción
  -- usa su propio usuario y se aplica siempre después de la GUI.
  local registrados = gmod.isRegisteredModule("Comm")
  if valores.comunicaciones then
    if not registrados or not registrados.RhomScripts then gmod.enableModule("RhomScripts", "Comm") end
    if not preparado_gmcp() then
      resultado.pendientes[#resultado.pendientes + 1] = depuracion.pendiente("comunicaciones_pendientes")
    end
  else
    if registrados and registrados[""] then gmod.disableModule("", "Comm") end
    if registrados and registrados.RhomScripts then gmod.disableModule("RhomScripts", "Comm") end
  end
  arranque.resultado = resultado
  return resultado
end

local function aplicar_protegido(valores)
  aplicando = true
  actualizar("preferencias", "aplicando", depuracion.detalle("preferencias_aplicando"), "configuración")
  local ok, resultado = pcall(aplicar, valores)
  aplicando = false
  if not ok then
    actualizar("preferencias", "error", tostring(resultado), "configuración")
    error(resultado, 0)
  end
  actualizar("preferencias", "aplicadas", #resultado.pendientes == 0 and depuracion.detalle("preferencias_aplicadas")
    or ("preferencias aplicadas; " .. table.concat(resultado.pendientes, " ")), "configuración")
  revisar_msp("configuración")
  return resultado
end

function arranque.aplicar_configuracion(configuracion)
  local valores = {}
  for _, clave in ipairs(claves) do valores[clave] = configuracion.get("oficial_" .. clave) end
  preferencias = valores
  return aplicar_protegido(valores)
end

function arranque.cancelar_configuracion()
  for _, id in ipairs(handlers_configuracion) do killAnonymousEventHandler(id) end
  handlers_configuracion = {}
  if timer_configuracion then killTimer(timer_configuracion); timer_configuracion = nil end
end

function arranque.vigilar()
  arranque.cancelar_configuracion()
  local function programar()
    if aplicando or timer_configuracion or not preferencias then return end
    timer_configuracion = tempTimer(0, function()
      timer_configuracion = nil
      local ok, mensaje = pcall(aplicar_protegido, preferencias)
      if not ok then
        local texto = "Error al reaplicar las preferencias del paquete oficial: " .. tostring(mensaje)
        depuracion.aviso("arranque", "preferencias_error", texto)
        error(mensaje, 0)
      end
    end)
  end
  for _, evento in ipairs({ "rlmud_opciones_inicializadas", "rlmud_gui_inicializada",
      "rlmud_gui_reinicializada", "rlmud_gui_noinicializada", "rl_gmcp_hello", "gmcp.Char.Ficha" }) do
    handlers_configuracion[#handlers_configuracion + 1] = registerAnonymousEventHandler(evento, programar)
  end
end

return arranque
