-- luacheck: globals package.loadlib
-- Integración con APIs reales en un perfil aislado y desconectado.
-- RHOM_TEST_ROOT y RHOM_TEST_RESULT los proporciona run_mudlet_validation.py.
local root = RHOM_TEST_ROOT
assert(getMudletHomeDir() == RHOM_TEST_PROFILE, "El perfil real no está en la carpeta aislada prevista")
local results = {}
local originals = {}
local live = { keys = {}, aliases = {}, triggers = {}, ficha = {} }
-- El portapapeles es global al escritorio, no al perfil aislado. No tocarlo por defecto.
local saved_clipboard
if RHOM_TEST_CLIPBOARD then saved_clipboard = getClipboardText() end

local function equal(actual, expected)
  assert(actual == expected, "Esperado " .. tostring(expected) .. "; obtenido " .. tostring(actual))
end

local function case(name, action)
  local progress = assert(io.open(RHOM_TEST_RESULT .. ".progress", "a"))
  assert(progress:write("START ", name, "\n"))
  assert(progress:close())
  action()
  results[#results + 1] = name
end

local function track(create_name, kill_name, collection, filter)
  originals[create_name] = _G[create_name]
  originals[kill_name] = _G[kill_name]
  _G[create_name] = function(...)
    local id = originals[create_name](...)
    assert(type(id) == "number", create_name .. " no devolvió identificador")
    if not filter or filter == select(1, ...) then collection[id] = true end
    return id
  end
  _G[kill_name] = function(id)
    if filter and not collection[id] then return originals[kill_name](id) end
    local result = originals[kill_name](id)
    assert(result, kill_name .. " no eliminó " .. tostring(id))
    collection[id] = nil
    return result
  end
end

local function count(collection)
  local total = 0
  for _ in pairs(collection) do total = total + 1 end
  return total
end

local function run()
  case("Paquete oficial real instalado e inicializado sin conexión al juego", function()
    local found = false
    for _, name in ipairs(getPackages()) do if name == "RLMud_Config" then found = true end end
    assert(found, "La descarga real no instaló el paquete oficial")
    assert(RL_vars and RL_vars.name == "RLMud_Config" and type(RL_vars.opciones) == "table",
      "El paquete oficial no terminó su inicialización local")
  end)
  track("tempKey", "killKey", live.keys)
  track("tempAlias", "killAlias", live.aliases)
  track("tempRegexTrigger", "killTrigger", live.triggers)
  track("registerAnonymousEventHandler", "killAnonymousEventHandler", live.ficha, "gmcp.Char")
  RhomScriptsBasePath = root .. "/rhomscripts"
  dofile(root .. "/rhomscripts/init.lua")
  assert(RhomScripts.initialized)

  dofile(root .. "/scripts/tests/ui_componentes.lua").real(case)

  case("Preparación nativa real carga wx/cffi al inicio y reutiliza sus instancias", function()
    local comprobaciones = require("arranque")
    local wx, ffi, runtime = package.loaded.wx, package.loaded.cffi, package.loaded.rhom_nativo_runtime
    assert(wx and ffi and runtime, "El inicio no preparó ambas bibliotecas")
    equal(ffi.sizeof("void *"), 8)
    equal(ffi.sizeof("RHOM_LONG_PTR"), 8)
    local original_loadlib, loads = package.loadlib, 0
    package.loadlib = function(...)
      loads = loads + 1
      return original_loadlib(...)
    end
    local ok, message = pcall(function()
      for _ = 1, 2 do
        local prepared = comprobaciones.bibliotecas()
        equal(prepared.wx, wx)
        equal(prepared.nativo, runtime)
      end
    end)
    package.loadlib = original_loadlib
    assert(ok, message)
    equal(loads, 0)
  end)

  case("Preparación nativa: DLL y API de carga ausentes producen error", function()
    local comprobaciones = require("arranque")
    local original_root, original_loadlib = RhomScripts.root, package.loadlib
    local wx, ffi, runtime = package.loaded.wx, package.loaded.cffi, package.loaded.rhom_nativo_runtime
    local ok, message = pcall(function()
      for _, loader in ipairs({ comprobaciones.cargar_wx, comprobaciones.cargar_nativo }) do
        package.loaded.wx, package.loaded.cffi, package.loaded.rhom_nativo_runtime = nil, nil, nil
        RhomScripts.root = RHOM_TEST_PROFILE .. "/bibliotecas-ausentes"
        local loaded, load_error = pcall(loader)
        assert(not loaded and tostring(load_error) ~= "", "Se ocultó la DLL ausente")
        RhomScripts.root = original_root
        package.loadlib = nil
        loaded, load_error = pcall(loader)
        package.loadlib = original_loadlib
        assert(not loaded and tostring(load_error):find("loadlib", 1, true), "Se ocultó package.loadlib ausente")
      end
    end)
    RhomScripts.root, package.loadlib = original_root, original_loadlib
    package.loaded.wx, package.loaded.cffi, package.loaded.rhom_nativo_runtime = wx, ffi, runtime
    assert(ok, message)
  end)

  case("Arranque prepara ventana y controles nativos ocultos sin sesión de edición", function()
    local configurador = RhomScripts.modules.configurador
    assert(configurador.vista and configurador.arbol and configurador.ventana)
    assert(configurador.guardar_boton and configurador.cancelar_boton and configurador.estado)
    assert(not configurador.ventana:IsShown() and not configurador.activo and not configurador.sesion)
    configurador.preparar()
    assert(not configurador.ventana:IsShown())
  end)

  case("Carga inicial con APIs reales", function()
    equal(count(live.keys), 40)
    equal(count(live.aliases), 3)
    equal(count(live.triggers), 2)
    equal(RhomScripts.modules.comunicaciones.cantidad_triggers(), 2)
    local expected, total = {
      configuracion = true, configurador = true, keys = true, lector = true, comunicaciones = true, ficha = true, debug = true, mapa = true,
    }, 0
    for name in pairs(RhomScripts.modules) do
      assert(expected[name], "Módulo no migrado conectado: " .. name)
      total = total + 1
    end
    equal(total, 8)
    assert(package.loaded.config == nil and package.loaded.modes == nil)
    local old_config = io.open(RHOM_TEST_PROFILE .. "/rl_config.lua", "rb")
    if old_config then old_config:close() end
    assert(not old_config, "Se creó la configuración antigua")
    local aliases = RhomScripts.soporte.aliases.descubrir_aliases()
    equal(#aliases, 3)
    assert(not package.loaded.historial)
  end)

  dofile(root .. "/scripts/tests/catalogo.lua").run(
    RhomScripts.soporte.sonidos, RhomScripts.root .. "/sonidos", RHOM_TEST_PROFILE, case)

  dofile(root .. "/scripts/tests/inicio.lua").run(
    root .. "/rhomscripts/init.lua", RHOM_TEST_PROFILE .. "/no-existe", case)

  dofile(root .. "/scripts/tests/configuracion.lua").run(case, root .. "/rhomscripts/init.lua")
  -- Registra con tempKey real e invoca sus callbacks; no simula pulsaciones físicas.
  dofile(root .. "/scripts/tests/keys.lua").run(root .. "/rhomscripts/keys.lua", case)

  dofile(root .. "/scripts/tests/oficial_configuracion.lua").run(case, root .. "/rhomscripts/init.lua")

  dofile(root .. "/scripts/tests/depuracion.lua").run(case, root .. "/rhomscripts/init.lua")

  dofile(root .. "/scripts/tests/lector.lua").real(case)
  -- Eventos de red simulados; handlers registrados y retirados mediante APIs reales.
  dofile(root .. "/scripts/tests/estado_arranque.lua").run(case, root .. "/rhomscripts/arranque.lua")
  dofile(root .. "/scripts/tests/comunicaciones.lua").run(case, root .. "/rhomscripts/comunicaciones.lua")

  case("Llamada real a announce para lector de pantalla externo", function()
    RhomScripts.modules.keys.establecer_ayuda(true)
    RhomScripts.modules.keys.establecer_ayuda(false)
  end)

  if RHOM_TEST_CLIPBOARD then
    case("Prueba optativa del portapapeles de texto", function()
      RhomScripts.modules.lector.copiar("RhomScripts copia real")
      equal(getClipboardText(), "RhomScripts copia real")
    end)
  end

  case("Audio real: reproduce los WAV integrados con el volumen de su grupo", function()
    local audio = RhomScripts.soporte.audio
    local sonidos = RhomScripts.soporte.sonidos
    local borrador = RhomScripts.modules.configurador.nueva_sesion().valores
    borrador.volumen_general = 90
    borrador.volumen_interfaz = 50
    borrador.volumen_comunicaciones = 70
    local original = playSoundFile
    local received
    playSoundFile = function(settings)
      received = settings
      return original(settings)
    end
    local ok, key = pcall(function()
      audio.aplicar_volumenes(borrador)
      local function reproducir(clave, opciones, volumen)
        received = nil
        local identificador = assert(audio.reproducir(clave, opciones))
        equal(received.volume, volumen)
        return identificador
      end
      audio.stop(reproducir("ui.boton_1", nil, 45))
      audio.stop(reproducir("comunicaciones.chat", nil, 63))
      return reproducir("ui.boton_1", {
        volumen = 80, paneo = -80, repeticiones = 3,
        instancia = "prueba", simultaneidad = "ignorar", importancia = "alta",
      }, 36)
    end)
    playSoundFile = original
    audio.aplicar_volumenes()
    assert(ok, key)
    equal(received.name, sonidos.catalogo.sonidos["ui.boton_1"].archivos[1])
    equal(received.pan, nil)
    equal(received.loops, nil)
    equal(received.priority, nil)
    equal(received.key, key)
    -- La observación del motor se realiza tras procesar Qt en execute_suite;
    -- ui.boton_1 dura 0.1306 s y este lote aún contiene paradas de la misma clave.
    audio.stop(key)
    equal(audio.reproducir("ui.no_existe"), nil)
  end)



  case("Recarga retira registros reales y conserva los recuentos", function()
    local before = { count(live.keys), count(live.aliases), count(live.triggers) }
    local old_triggers = {}
    for id in pairs(live.triggers) do old_triggers[#old_triggers + 1] = id end
    local old_communications = RhomScripts.modules.comunicaciones
    local wx, runtime = package.loaded.wx, package.loaded.rhom_nativo_runtime
    local old = RhomScripts.soporte
    local old_window = RhomScripts.modules.configurador.ventana
    local old_handle = require("ui").nativo.handle(old_window)
    local destroyed = false
    old_window:Connect(wx.wxEVT_DESTROY, function(event)
      destroyed = true
      event:Skip()
    end)
    local previous_path = package.path
    dofile(root .. "/rhomscripts/init.lua")
    equal(count(live.keys), before[1])
    equal(count(live.aliases), before[2])
    equal(count(live.triggers), before[3])
    equal(old_communications.cantidad_triggers(), 0)
    for _, id in ipairs(old_triggers) do assert(not live.triggers[id], "Quedó un trigger de la instancia anterior") end
    equal(package.path, previous_path)
    assert(old.audio ~= RhomScripts.soporte.audio)
    assert(old.sonidos ~= RhomScripts.soporte.sonidos)
    equal(package.loaded.wx, wx)
    equal(package.loaded.rhom_nativo_runtime, runtime)
    assert(destroyed, "La recarga no destruyó la ventana anterior")
    equal(runtime.user32.IsWindow(old_handle), 0)
    local configurador = RhomScripts.modules.configurador
    assert(configurador.ventana and not configurador.ventana:IsShown() and not configurador.sesion)
    assert(RhomScripts.modules.configurador and RhomScripts.modules.keys)
  end)

  case("Tras recargar cada línea llega una sola vez a su historial", function()
    local histories = RhomScripts.modules.comunicaciones.historiales
    assert(feedTriggers("Ariadna dice: Hola: ven aquí.\nAriadna te dice: Hola.\n"))
    equal(#histories.room.estado().mensajes, 1)
    equal(#histories.telepatia.estado().mensajes, 1)
  end)

  case("Instalación real de RhomLoader y recarga con los sonidos integrados", function()
    local before = { count(live.keys), count(live.aliases), count(live.triggers) }
    local indexed = RhomScripts.soporte.sonidos.resumen_catalogo.claves_disponibles
    assert(installPackage(RHOM_TEST_PACKAGE), "No se instaló RhomLoader")
    assert(RhomScripts.initialized)
    assert(RhomLoader.reload())
    local summary = RhomScripts.soporte.sonidos.resumen_catalogo
    equal(summary.estado, "cargado")
    equal(summary.raiz, RhomScripts.root .. "/sonidos")
    assert(indexed > 0)
    equal(summary.claves_disponibles, indexed)
    equal(count(live.keys), before[1])
    equal(count(live.aliases), before[2])
    equal(count(live.triggers), before[3])
  end)

  case("Una API ausente falla también en Mudlet real", function()
    local original = announce
    announce = nil
    local ok = pcall(function() RhomScripts.modules.keys.establecer_ayuda(true) end)
    announce = original
    assert(not ok, "Se ocultó la ausencia de announce")
  end)
end

local reload_cleanup
local function finish(ok, err)
  if reload_cleanup then reload_cleanup(); reload_cleanup = nil end
  for name, original in pairs(originals) do _G[name] = original end
  if RHOM_TEST_CLIPBOARD then setClipboardText(saved_clipboard) end
  local file = assert(io.open(RHOM_TEST_RESULT .. ".tmp", "w"))
  file:write(ok and "STATUS OK\n" or "STATUS ERROR\n")
  file:write("VERSION " .. getMudletVersion("string") .. "\n")
  file:write("LUA " .. _VERSION .. "\n")
  if not RHOM_TEST_CLIPBOARD then file:write("OMITIDA Copia real: portapapeles del usuario conservado sin modificaciones\n") end
  for _, name in ipairs(results) do file:write("CASE " .. name .. "\n") end
  file:write(string.format("REGISTROS %d keys, %d aliases, %d triggers\n", count(live.keys), count(live.aliases), count(live.triggers)))
  if not ok then file:write("ERROR " .. tostring(err) .. "\n") end
  file:close()
  assert(os.rename(RHOM_TEST_RESULT .. ".tmp", RHOM_TEST_RESULT))
  if not ok then error(err, 0) end
end

-- La recarga se solicita desde el bucle wx real y debe esperar a su retorno.
local reload_state
local function reload_from_modal()
  local configurador = RhomScripts.modules.configurador
  local ui = require("ui")
  local runtime = package.loaded.rhom_nativo_runtime
  local state = { ready = 0, returned = false, destroyed = false,
    old = configurador, hwnd = ui.nativo.handle(configurador.ventana), runtime = runtime,
    confirmed = RhomScripts.modules.configuracion.get("volumen_general") }
  reload_state = state
  reload_cleanup = function()
    if state.handler then killAnonymousEventHandler(state.handler); state.handler = nil end
  end
  state.handler = registerAnonymousEventHandler("rhomscripts.ready", function()
    state.ready = state.ready + 1
    assert(state.returned, "Se emitió ready antes de retornar ShowModal")
  end)
  configurador.ventana:Connect(configurador.wx.wxEVT_DESTROY, function(event)
    state.destroyed = true
    state.destroyed_after_return = state.returned
    event:Skip()
  end)
  configurador.ventana:CallAfter(function()
    local checked, message = xpcall(function()
      assert(configurador.activo and ui.ocupada(), "El callback no entró en el diálogo real")
      configurador.sesion:cambiar("volumen_general", 1)
      dofile(root .. "/rhomscripts/init.lua")
      assert(RhomScripts.loading and not RhomScripts.initialized)
      equal(RhomScripts.modules.configurador, configurador)
      equal(state.ready, 0)
      assert(not state.destroyed, "Se destruyó la ventana mientras ShowModal seguía en pila")
      assert(runtime.user32.IsWindow(state.hwnd) ~= 0, "El HWND dejó de existir antes del retorno")
      assert(RhomScripts.recarga_timer, "No se programó la recarga diferida")
    end, debug.traceback)
    if not checked then
      state.callback_error = message
      configurador.cerrar()
    end
  end)
  configurador.abrir()
  state.returned = true
  assert(not state.callback_error, state.callback_error)
  assert(not ui.ocupada(), "El diálogo siguió ocupado tras retornar")
  equal(configurador.sesion, nil)
end

local function reload_from_detail(done)
  local function progress(message)
    local file = assert(io.open(RHOM_TEST_RESULT .. ".detail-progress", "a"))
    assert(file:write(message .. "\n"))
    assert(file:close())
  end
  progress("Preparando recarga anidada")
  local history = RhomScripts.modules.comunicaciones.historiales.room
  local ui = require("ui")
  local detail = history.detalle
  local runtime = package.loaded.rhom_nativo_runtime
  local parent_hwnd = ui.nativo.handle(history.vista.dialogo)
  local detail_hwnd = ui.nativo.handle(detail.vista.dialogo)
  local returned, detail_returned, ready, callback_error = false, false, 0
  local handler = registerAnonymousEventHandler("rhomscripts.ready", function()
    ready = ready + 1
    assert(returned and detail_returned, "Ready antes de retornar los dos diálogos")
  end)
  reload_cleanup = function() killAnonymousEventHandler(handler) end
  history.recibir_texto("Mensaje sintético para recargar desde su detalle.")
  history.vista.dialogo:CallAfter(function()
    progress("Callback padre")
    local ok, message = xpcall(function()
      detail.vista.dialogo:CallAfter(function()
        progress("Callback detalle")
        local ok, message = xpcall(function()
          assert(history.vista.mostrando and detail.vista.mostrando)
          dofile(root .. "/rhomscripts/init.lua")
          progress("Init diferido")
          assert(RhomScripts.loading and RhomScripts.recarga_timer)
          equal(runtime.user32.IsWindow(parent_hwnd), 1)
          equal(runtime.user32.IsWindow(detail_hwnd), 1)
          equal(ready, 0)
        end, debug.traceback)
        if not ok then callback_error = message; ui.ocultar() end
      end)
      history.abrir_detalle(history.componente:seleccionado())
      progress("Retorno detalle")
      detail_returned = true
      assert(not detail.vista.mostrando)
    end, debug.traceback)
    if not ok then callback_error = message; ui.ocultar() end
  end)
  history.mostrar_historial()
  progress("Retorno padre")
  returned = true
  tempTimer(0.2, function()
    progress("Validacion diferida")
    local ok, message = xpcall(function()
      assert(not callback_error, callback_error)
      assert(detail_returned and not ui.ocupada())
      assert(RhomScripts.initialized and not RhomScripts.recarga_timer)
      equal(ready, 1)
      equal(runtime.user32.IsWindow(parent_hwnd), 0)
      equal(runtime.user32.IsWindow(detail_hwnd), 0)
      assert(RhomScripts.modules.comunicaciones.historiales.room ~= history)
      equal(count(live.keys), 40)
      equal(count(live.aliases), 3)
      equal(count(live.triggers), 2)
      results[#results + 1] = "Recarga desde detalle real retorna hijo y padre antes de destruir y emite ready una vez"
    end, debug.traceback)
    killAnonymousEventHandler(handler)
    reload_cleanup = nil
    done(ok, message)
  end)
end

local function execute_audio_checks()
  -- Mantener un sonido de prueba activo mientras Qt procesa eventos, para
  -- comprobar la parada asíncrona con el motor nativo.
  local loop_key = "rhom:integration-loop"
  local started, start_error = xpcall(function()
    local audio = RhomScripts.soporte.audio
    audio.stop_tag()
    playSoundFile({
      name = RhomScripts.soporte.sonidos.catalogo.sonidos["ui.error"].archivos[1],
      key = loop_key, tag = audio.default_tag, volume = 1, loops = -1,
    })
  end, debug.traceback)
  if not started then finish(false, start_error); return end
  tempTimer(0.5, function()
    local playing, playing_error = xpcall(function()
      assert(#getPlayingSounds({ key = loop_key }) > 0,
        "No hay bucle en el motor de audio real tras procesar eventos Qt")
      RhomScripts.soporte.audio.stop(loop_key)
      results[#results + 1] = "Audio real: sonido de prueba activo y solicitud de parada por identificador"
      reload_from_modal()
    end, debug.traceback)
    if not playing then finish(false, playing_error); return end
    tempTimer(1, function()
      local stopped, stop_error = xpcall(function()
        equal(#getPlayingSounds({ key = loop_key }), 0)
        results[#results + 1] = "Motor de audio confirma parada tras procesar eventos"
        local state = reload_state
        assert(state and not state.callback_error, state and state.callback_error)
        assert(state.returned and state.destroyed and state.destroyed_after_return)
        equal(state.runtime.user32.IsWindow(state.hwnd), 0)
        assert(RhomScripts.initialized and not RhomScripts.loading and not RhomScripts.recarga_timer)
        equal(state.ready, 1)
        local configurador = RhomScripts.modules.configurador
        assert(configurador ~= state.old and configurador.vista and configurador.arbol)
        assert(not configurador.ventana:IsShown() and not configurador.sesion)
        equal(RhomScripts.modules.configuracion.get("volumen_general"), state.confirmed)
        equal(count(live.keys), 40)
        equal(count(live.aliases), 3)
        equal(count(live.triggers), 2)
        killAnonymousEventHandler(state.handler)
        state.handler = nil
        results[#results + 1] = "Recarga desde diálogo real espera retorno modal, descarta sesión y prepara una única nueva instancia"
        -- La negociación de prueba afecta al perfil aislado. Ejecutarla tras
        -- las comprobaciones asíncronas de audio y de la ventana modal.
        dofile(root .. "/scripts/tests/ficha.lua").run(
          case, root .. "/rhomscripts/init.lua", function() return live.ficha end, true)
      end, debug.traceback)
      if not stopped then finish(false, stop_error); return end
      local nested, nested_error = xpcall(function() reload_from_detail(finish) end, debug.traceback)
      if not nested then finish(false, nested_error) end
    end)
  end)
end

-- Las solicitudes se verifican arriba; la reproducción nativa requiere devolver
-- el control a Qt. Usar ui.carga_ok (1.2718 s), en vez del botón de 0.1306 s,
-- permite observar una reproducción de catálogo real antes de solicitar su parada.
local function execute_suite()
  local ok, err = xpcall(run, debug.traceback)
  if not ok then finish(false, err); return end
  RhomScripts.soporte.audio.stop_tag()
  tempTimer(0.1, function()
    -- Los ensayos anteriores programan reaplicaciones de preferencias. Dejarlas
    -- terminar antes de crear salas que una reinicialización oficial reemplazaría.
    local mapped, map_error = xpcall(function()
      dofile(root .. "/scripts/tests/mapa.lua").real(case, root)
    end, debug.traceback)
    if not mapped then finish(false, map_error); return end
    local requested, catalog_key = xpcall(function()
      return assert(RhomScripts.soporte.audio.reproducir("ui.carga_ok", { volumen = 1 }))
    end, debug.traceback)
    if not requested then finish(false, catalog_key); return end
    tempTimer(0.1, function()
      local observed, message = xpcall(function()
        equal(catalog_key, "rhom:catalogo:ui.carga_ok")
        assert(#getPlayingSounds({ key = catalog_key }) > 0,
          "La clave de catálogo no llegó al motor real tras procesar eventos Qt")
        RhomScripts.soporte.audio.stop(catalog_key)
        results[#results + 1] = "Audio real: clave de catálogo observada en el motor tras procesar Qt"
      end, debug.traceback)
      if not observed then finish(false, message); return end
      dofile(root .. "/scripts/tests/mapa.lua").automatic(case, function(opened, opening_error)
        if not opened then finish(false, opening_error); return end
        execute_audio_checks()
      end)
    end)
  end)
end

-- Ejercicio real de downloadFile con Qt y del instalador del paquete oficial.
-- El perfil recién creado no tiene RLMud_Config; no se sustituye la descarga.
local function start_official()
  for _, name in ipairs(getPackages()) do
    assert(name ~= "RLMud_Config", "El ensayo exige comenzar sin paquete oficial")
  end
  RhomScripts = RhomScripts or {}
  RhomScripts.root = root .. "/rhomscripts"
  RhomScripts.modules = { debug = assert(loadfile(RhomScripts.root .. "/debug.lua"))() }
  local control = dofile(root .. "/rhomscripts/arranque.lua").nuevo()
  RhomScripts.arranque_oficial = control
  control:iniciar(function()
    assert(control.estado == "activo")
    assert(next(control.temporizadores) == nil and next(control.handlers) == nil)
    results[#results + 1] = "Descarga Qt, instalación oficial y señal local reales sin GMCP"
    -- No crear el mapa sintético mientras una descarga oficial pueda
    -- reemplazarlo al volver al bucle de eventos dentro de un diálogo.
    local function when_map_ready()
      if RL_vars.mapa.descargando then tempTimer(0.05, when_map_ready)
      else execute_suite() end
    end
    tempTimer(0, when_map_ready)
  end, function(message)
    -- El estado de fallo se escribe para que el ejecutor no espere hasta timeout.
    finish(false, message)
  end)
  assert(control.estado == "esperando", "La descarga real no dejó una espera asíncrona")
  assert(not RhomScripts.initialized, "Se anunció carga antes de disponer del paquete")
end

local ok, err = xpcall(start_official, debug.traceback)
if not ok then finish(false, err) end
