-- Pruebas de estados observables del arranque con doble explícito, sin servidor.
-- luacheck: globals RL_vars getPackages downloadFile installPackage
local suite = {}

function suite.run(mock, case)
  require("arranque").cancelar_configuracion()
  local comprobaciones = require("arranque")
  -- Las recargas fallidas pueden retirar el dominio de comunicaciones completo.
  -- Contar solo eventos ajenos a ese dominio al verificar el cargador oficial.
  local function startup_handlers()
    local count = 0
    for _, handler in pairs(mock.handlers) do
      if not handler.event:match("^gmcp%.Comm%.")
        and handler.event ~= "sysConnectionEvent" and handler.event ~= "sysDisconnectionEvent" then
        count = count + 1
      end
    end
    return count
  end
  local baseline = startup_handlers()
  local function reset()
    mock.packages = { "RLMud_Config" }
    mock.install_ready, mock.install_error = true, nil
    mock.official_ready()
  end
  local function clean(control)
    control:cancelar()
    assert(startup_handlers() == baseline, "Quedaron handlers del arranque")
    assert(mock.count(mock.timers) == 0, "Quedaron temporizadores del arranque")
    reset()
  end
  local function rethrow(message) error(message, 0) end

  case("Oficial: instalado y activo continúa sin descarga ni GMCP", function()
    reset()
    local downloads, calls = #mock.downloads, 0
    local first = #mock.announcements + 1
    local control = comprobaciones.nuevo()
    control:iniciar(function() calls = calls + 1 end, rethrow)
    assert(calls == 1 and control.estado == "activo")
    assert(#mock.downloads == downloads)
    assert(mock.announcements[first] == "Paquete oficial: instalado.")
    assert(mock.announcements[first + 1] == "Paquete oficial: activo (inicialización local).")
    clean(control)
  end)

  case("Oficial: espera inicialización local y continúa una vez después del evento", function()
    reset()
    RL_vars = nil
    local calls = 0
    local control = comprobaciones.nuevo()
    control:iniciar(function() calls = calls + 1 end, rethrow)
    assert(calls == 0 and control.estado == "esperando")
    raiseEvent("sysInstallPackage", "OtroPaquete", "otro.zip")
    mock.advance(0)
    assert(calls == 0)
    mock.official_ready()
    raiseEvent("rlmud_opciones_inicializadas")
    assert(calls == 0, "Continuó antes de terminar los listeners oficiales")
    mock.advance(0)
    assert(calls == 1 and control.estado == "activo")
    raiseEvent("rlmud_opciones_inicializadas")
    mock.advance(0)
    assert(calls == 1)
    clean(control)
  end)

  case("Oficial: descarga e instala solo el archivo de este intento", function()
    reset()
    mock.packages, RL_vars = {}, nil
    local calls, installs = 0, #mock.installs
    local control = comprobaciones.nuevo()
    control:iniciar(function() calls = calls + 1 end, rethrow)
    assert(calls == 0 and #mock.installs == installs)
    assert(mock.downloads[#mock.downloads].url == comprobaciones.url)
    raiseEvent("sysDownloadDone", "ajeno.zip")
    raiseEvent("sysDownloadError", "error ajeno", "ajeno.zip")
    assert(#mock.installs == installs and control.estado == "esperando")
    raiseEvent("sysDownloadDone", control.archivo)
    assert(mock.installs[#mock.installs] == control.archivo)
    assert(calls == 0)
    mock.advance(0)
    assert(calls == 1 and control.estado == "activo")
    clean(control)
  end)

  case("Oficial: fallos de descarga e instalación impiden continuar y limpian", function()
    for _, failure in ipairs({ "descarga", "instalacion" }) do
      reset()
      mock.packages, RL_vars = {}, nil
      local calls = 0
      local control = comprobaciones.nuevo()
      control:iniciar(function() calls = calls + 1 end, rethrow)
      local ok, message
      if failure == "descarga" then
        ok, message = pcall(raiseEvent, "sysDownloadError", "fallo HTTP provocado", control.archivo)
        assert(not ok and tostring(message):find("fallo HTTP provocado", 1, true))
      else
        mock.install_error = "archivo incorrecto provocado"
        ok, message = pcall(raiseEvent, "sysDownloadDone", control.archivo)
        assert(not ok and tostring(message):find("archivo incorrecto provocado", 1, true))
      end
      assert(calls == 0 and control.estado == "error")
      clean(control)
    end
  end)

  case("Oficial: límite de espera falla sin cargar y permite nuevo intento", function()
    reset()
    RL_vars = nil
    local calls = 0
    local control = comprobaciones.nuevo()
    control:iniciar(function() calls = calls + 1 end, rethrow)
    local ok, message = pcall(mock.advance, comprobaciones.espera)
    assert(not ok and tostring(message):find("inicialización local", 1, true))
    assert(calls == 0 and control.estado == "error")
    clean(control)
  end)

  case("Oficial: cancelar retira registros e ignora la descarga anterior", function()
    reset()
    mock.packages, RL_vars = {}, nil
    local calls = 0
    local old = comprobaciones.nuevo()
    old:iniciar(function() calls = calls + 1 end, rethrow)
    old:cancelar()
    old:cancelar()
    assert(old.estado == "cancelado")
    local current = comprobaciones.nuevo()
    current:iniciar(function() calls = calls + 1 end, rethrow)
    assert(old.archivo ~= current.archivo)
    raiseEvent("sysDownloadDone", old.archivo)
    mock.advance(0)
    assert(calls == 0)
    raiseEvent("sysDownloadDone", current.archivo)
    mock.advance(0)
    assert(calls == 1)
    clean(current)
  end)

  case("Oficial: APIs ausentes producen error y no un falso éxito", function()
    for _, name in ipairs({ "getPackages", "downloadFile", "installPackage" }) do
      reset()
      if name ~= "getPackages" then mock.packages, RL_vars = {}, nil end
      local original = _G[name]
      local calls = 0
      local control = comprobaciones.nuevo()
      _G[name] = nil
      local ok, message
      if name == "installPackage" then
        control:iniciar(function() calls = calls + 1 end, rethrow)
        ok, message = pcall(raiseEvent, "sysDownloadDone", control.archivo)
      else
        ok, message = pcall(function()
          control:iniciar(function() calls = calls + 1 end, rethrow)
        end)
      end
      _G[name] = original
      assert(not ok and tostring(message):find(name, 1, true))
      assert(calls == 0 and control.estado == "error")
      clean(control)
    end
  end)

  case("Inicio: espera oficial no anuncia éxito ni registra módulos; recarga cancela espera", function()
    reset()
    RL_vars = nil
    dofile("rhomscripts/init.lua")
    local previous = RhomScripts.arranque_oficial
    assert(RhomScripts.loading and not RhomScripts.initialized)
    assert(package.loaded.configuracion, "Las preferencias deben cargarse antes de la dependencia")
    assert(RhomScripts.modules.configuracion and not RhomScripts.modules.configurador and not RhomScripts.modules.keys,
      "La espera oficial debe conservar solo preferencias, sin registrar interfaz o teclado")
    assert(mock.sounds["rhom:catalogo:ui.carga_ok"] == nil, "Sonó éxito durante espera")
    local sounds = #mock.announcements
    local ready_before = 0
    for _, event in ipairs(mock.events) do
      if event[1] == "rhomscripts.ready" then ready_before = ready_before + 1 end
    end
    local output_before = #mock.output
    dofile("rhomscripts/init.lua")
    assert(previous.estado == "cancelado")
    assert(RhomScripts.loading and not RhomScripts.initialized)
    assert(mock.count(mock.keys) == 0 and mock.count(mock.aliases) == 1 and mock.count(mock.triggers) == 0)
    assert(RhomScripts.soporte.arranque.estado.consultar("scripts").codigo == "iniciando")
    for index = output_before + 1, #mock.output do
      assert(not mock.output[index]:find("cargados correctamente", 1, true), "Se anunció éxito durante espera")
    end
    mock.official_ready()
    raiseEvent("rlmud_opciones_inicializadas")
    mock.advance(0)
    assert(RhomScripts.initialized and not RhomScripts.loading)
    assert(#mock.announcements > sounds)
    -- El historial de eventos permite comprobar que solo una carga alcanzó ready.
    local ready = 0
    for _, event in ipairs(mock.events) do
      if event[1] == "rhomscripts.ready" then ready = ready + 1 end
    end
    assert(ready == ready_before + 1, "La recarga pendiente produjo más de un ready")
    reset()
  end)

  case("Inicio: fallo asíncrono de dependencia cancela loading sin éxito", function()
    reset()
    mock.packages, RL_vars = {}, nil
    dofile("rhomscripts/init.lua")
    assert(RhomScripts.loading and not RhomScripts.initialized)
    local control = RhomScripts.arranque_oficial
    local ready_before = 0
    for _, event in ipairs(mock.events) do
      if event[1] == "rhomscripts.ready" then ready_before = ready_before + 1 end
    end
    local output_before = #mock.output
    local ok, message = pcall(raiseEvent, "sysDownloadError", "HTTP asíncrono provocado", control.archivo)
    assert(not ok and tostring(message):find("HTTP asíncrono provocado", 1, true))
    assert(RhomScripts.soporte.arranque.estado.consultar("scripts").codigo == "error")
    assert(not RhomScripts.loading and not RhomScripts.initialized)
    assert(mock.sounds["rhom:catalogo:ui.carga_ok"] == nil, "Sonó éxito tras fallo de dependencia")
    local ready_after = 0
    for _, event in ipairs(mock.events) do
      if event[1] == "rhomscripts.ready" then ready_after = ready_after + 1 end
    end
    assert(ready_after == ready_before)
    for index = output_before + 1, #mock.output do
      assert(not mock.output[index]:find("cargados correctamente", 1, true))
    end
    clean(control)
    dofile("rhomscripts/init.lua")
    assert(RhomScripts.initialized)
  end)
end

return suite
