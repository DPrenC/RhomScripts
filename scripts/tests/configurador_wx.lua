-- luacheck: globals io.open
-- Prueba nativa aislada: no instala paquetes del juego ni toca portapapeles.
local root, result_path = RHOM_WX_ROOT, RHOM_WX_RESULT
assert(getMudletHomeDir() == RHOM_WX_PROFILE, "El perfil no está en la carpeta aislada prevista")
RhomScripts = { root = root .. "/rhomscripts" }
package.path = RhomScripts.root .. "/?.lua;" .. package.path

local results, timers = {}, {}
local ticks, finished = 0, false
local config = require("configuracion")
assert(config.load())
local audio = require("audio")
local sonidos = require("sonidos")
assert(audio.iniciar().estado == "cargado")
local demo = require("configurador")
local comprobaciones = require("arranque")
comprobaciones.bibliotecas()
local nativo = require("ui").nativo
local ui = require("ui")

local function journal(message)
  local file = assert(io.open(result_path .. ".progress", "a"))
  file:write(message, "\n")
  file:close()
end

local function after(delay, action)
  local id
  id = tempTimer(delay, function()
    timers[id] = nil
    action()
  end)
  timers[id] = true
  return id
end

local function beat()
  if finished then return end
  ticks = ticks + 1
  after(0.1, beat)
end

local function finish(ok, message)
  finished = true
  for id in pairs(timers) do killTimer(id) end
  timers = {}
  local file = assert(io.open(result_path .. ".tmp", "w"))
  file:write(ok and "STATUS OK\n" or "STATUS ERROR\n")
  file:write("VERSION ", getMudletVersion("string"), "\nLUA ", _VERSION, "\n")
  if demo.wx then file:write("WX ", demo.wx.wxVERSION_STRING, "\n") end
  file:write("QT_HEARTBEAT ", tostring(ticks), "\n")
  file:write("OMITIDA Teclado físico y lector externo: esta prueba no los simula\n")
  file:write("OMITIDA Portapapeles: conservado sin lecturas ni modificaciones\n")
  for _, name in ipairs(results) do file:write("CASE ", name, "\n") end
  if not ok then file:write("ERROR ", tostring(message), "\n") end
  file:close()
  assert(os.rename(result_path .. ".tmp", result_path))
end

local function equal(actual, expected)
  assert(actual == expected, "Esperado " .. tostring(expected) .. "; obtenido " .. tostring(actual))
end

-- Los controles y el bucle son reales. La aplicación oficial se cubre por la
-- integración general; aquí solo se aísla ese callback de dominio.
local sound_requests = {}
local native_sounds = {}
local play_sound = playSoundFile
playSoundFile = function(settings)
  native_sounds[#native_sounds + 1] = settings
  return play_sound(settings)
end
local reproduce = audio.reproducir
audio.reproducir = function(id, options)
  sound_requests[#sound_requests + 1] = id
  return reproduce(id, options)
end

local function click(button, expected_sound)
  local before = #sound_requests
  local wx = demo.wx
  local event = wx.wxCommandEvent(wx.wxEVT_COMMAND_BUTTON_CLICKED, button:GetId())
  event:SetEventObject(button)
  assert(button:ProcessWindowEvent(event), "Botón nativo sin manejador")
  event:delete()
  if expected_sound then
    equal(#sound_requests, before + 1)
    equal(sound_requests[#sound_requests], expected_sound)
  end
end

local function focus(control)
  local actual = demo.wx.wxWindow.FindFocus()
  assert(actual and actual:GetId() == control:GetId(), "Foco nativo inesperado: "
    .. (actual and actual:GetName() or "ninguno") .. "; esperado: " .. control:GetName())
end

-- Invoca el mismo controlador que el hook nativo con constantes reales. No
-- construye un wxKeyEvent falso ni demuestra entrega física de pulsaciones.
local function key(code, consumed, sounds)
  local before = #sound_requests
  local adjusting = demo.ajuste
  local previous_value = adjusting and demo.sesion:get(adjusting)
  local readings, original_announce = {}, announce
  announce = function(text)
    readings[#readings + 1] = text
    return original_announce(text)
  end
  local ok, handled = pcall(demo.tecla, code)
  announce = original_announce
  assert(ok, handled)
  equal(handled, consumed)
  if adjusting and (code == demo.wx.WXK_UP or code == demo.wx.WXK_DOWN) then
    local value = demo.sesion:get(adjusting)
    local text = type(value) == "boolean" and (value and "Activado" or "Desactivado") or tostring(value)
    if value == previous_value then
      equal(#readings, 1) -- Sin cambio nativo, announce informa del valor.
      equal(readings[1], text)
    else
      equal(#readings, 0) -- El cambio de nodo se deja al lector nativo.
    end
    equal(demo.arbol.control:GetItemText(demo.arbol.items[adjusting]), text)
  end
  if not adjusting and demo.ajuste then
    equal(#readings, 1)
    equal(readings[1], "Ajustando valor.")
    equal(demo.estado:GetLabel(), "Ajustando valor.")
  elseif adjusting and code == demo.wx.WXK_LEFT then
    equal(#readings, 0) -- El nodo recupera su nombre sin anuncio duplicado.
  end
  if sounds then
    equal(#sound_requests, before + #sounds)
    for index, sound in ipairs(sounds) do equal(sound_requests[before + index], sound) end
  end
  return readings
end

local function exercise(name, action)
  local delayed_error
  local before = ticks
  local window_name = "RhomScripts_configurador_" .. tostring(#results + 1)
  journal("ABRIR " .. name)
  local function comprobar()
    local ok, message = xpcall(function()
      assert(demo.activo and demo.ventana and demo.arbol)
      equal(demo.ventana:GetTitle(), "RhomScripts. Configuración.")
      local runtime = comprobaciones.cargar_nativo()
      equal(nativo.propietario(demo.ventana), config.get("ventanasflotantes") and nativo.mudlet() or runtime.ffi.nullptr)
      demo.ventana:SetName(window_name)
      focus(demo.arbol.control)
      assert(ticks > before + 2, "El diálogo bloqueó los temporizadores Qt")
      for _, id in ipairs({ "volumenes", "interfaz", "canales", "oficial", "restablecer" }) do
        assert(not demo.arbol.control:IsExpanded(demo.arbol.items[id]), "Rama abierta al iniciar: " .. id)
      end
      action()
    end, debug.traceback)
    if not ok then
      delayed_error = message
      journal("FALLO DIFERIDO " .. tostring(message))
      demo.cerrar()
    end
  end
  -- El diálogo ya existe oculto; programar las comprobaciones al mostrarlo.
  local vista, ventana, tree = demo.vista, demo.ventana, demo.arbol
  local guardar, cancelar, estado = demo.guardar_boton, demo.cancelar_boton, demo.estado
  local mostrar, crear, crear_arbol = vista.mostrar, ui.nueva, ui.arbol
  local constructors = 0
  ui.nueva = function(...)
    constructors = constructors + 1
    return crear(...)
  end
  ui.arbol = function(...)
    constructors = constructors + 1
    return crear_arbol(...)
  end
  vista.mostrar = function(self)
    -- Medir constructores de abrir, no los diálogos auxiliares explícitos del caso.
    ui.nueva, ui.arbol = crear, crear_arbol
    self.dialogo:CallAfter(function()
      before = ticks
      after(0.8, comprobar)
    end)
    return mostrar(self)
  end
  local opening_sound = #sound_requests + 1
  local opened, message = pcall(demo.abrir)
  vista.mostrar, ui.nueva, ui.arbol = mostrar, crear, crear_arbol
  assert(opened, message)
  assert(not delayed_error, delayed_error)
  equal(sound_requests[opening_sound], "ui.abrir_config")
  equal(constructors, 0)
  equal(demo.vista, vista)
  equal(demo.ventana, ventana)
  equal(demo.arbol, tree)
  equal(demo.guardar_boton, guardar)
  equal(demo.cancelar_boton, cancelar)
  equal(demo.estado, estado)
  assert(not demo.activo and not ventana:IsShown(), "Quedó una ventana visible")
  equal(demo.sesion, nil)
  equal(demo.ajuste, nil)
  assert(not demo.cerrando, "Quedó bloqueada la fase de cierre")
  local remaining = demo.wx.wxWindow.FindWindowByName(window_name)
  assert(remaining and remaining:GetId() == ventana:GetId(), "Se destruyó la ventana al cerrar")
  results[#results + 1] = name
  journal("CERRADA " .. name)
end

local function run()
  journal("INICIO " .. getMudletVersion("string") .. " PERFIL " .. getMudletHomeDir())
  -- La medida siguiente corresponde al bucle modal, no a cargar DLL por
  -- primera vez: esa carga puede consumir el plazo del temporizador de prueba.
  comprobaciones.cargar_wx()
  comprobaciones.cargar_nativo()
  do
  local sounds_before, readings = #sound_requests, 0
  local original_announce = announce
  local wx = comprobaciones.cargar_wx()
  local focus_before = wx.wxWindow.FindFocus()
  local focus_id = focus_before and focus_before:GetId()
  announce = function(text)
    readings = readings + 1
    return original_announce(text)
  end
  local prepared, preparation_error = pcall(demo.preparar)
  announce = original_announce
  assert(prepared, preparation_error)
  local view, tree, window = demo.vista, demo.arbol, demo.ventana
  demo.preparar()
  equal(demo.vista, view)
  equal(demo.arbol, tree)
  equal(demo.ventana, window)
  assert(not window:IsShown() and not demo.activo and not demo.sesion)
  equal(#sound_requests, sounds_before)
  equal(readings, 0)
  local focus_after = wx.wxWindow.FindFocus()
  equal(focus_after and focus_after:GetId(), focus_id)
  results[#results + 1] = "Preparación idempotente crea controles ocultos sin audio, anuncio ni cambio de foco"
  end
  after(0.1, beat)
  if RHOM_WX_INTERACTIVE then
    exercise("Configurador interactivo", function()
      journal("INTERACTIVA: comprobar árbol, flechas, Tab, guardar y Escape con lector")
    end)
    return
  end
  local oficial = require("arranque")
  local apply = oficial.aplicar_configuracion
  local apply_calls = 0
  oficial.aplicar_configuracion = function(settings)
    apply_calls = apply_calls + 1
    local file = assert(io.open(config.path(), "r"))
    local data = yajl.to_value(file:read("*a"))
    file:close()
    equal(data.valores.volumen_general, settings.get("volumen_general"))
    return { pendientes = {} }
  end
  local ok, message = xpcall(function()
    do
    local original_text, changes = demo.arbol.texto, {}
    demo.arbol.texto = function(self, id, text)
      local changed = original_text(self, id, text)
      if changed then changes[#changes + 1] = id end
      return changed
    end
    exercise("Reabrir reutiliza ventana y controles sin reconstrucción ni cambios de texto idéntico", function()
      equal(#changes, 0)
      click(demo.cancelar_boton, "ui.cerrar_config")
    end)
    config.set("volumen_general", 75)
    assert(config.save())
    changes = {}
    exercise("Abrir actualiza únicamente el valor confirmado modificado", function()
      equal(#changes, 1)
      equal(changes[1], "volumen_general")
      equal(demo.sesion:get("volumen_general"), 75)
      click(demo.cancelar_boton, "ui.cerrar_config")
    end)
    demo.arbol.texto = original_text
    config.set("volumen_general", 80)
    assert(config.save())
    end
    exercise("Ajustes sin consultas de selección y etiquetas sin repintados idénticos", function()
      local tree, wx = demo.arbol, demo.wx
      local original_text = tree.control:GetItemText(tree.items.volumenes)
      equal(tree:texto("volumenes", original_text), false)
      equal(tree:texto("volumenes", "Volúmenes de prueba"), true)
      equal(tree.control:GetItemText(tree.items.volumenes), "Volúmenes de prueba")
      equal(tree:texto("volumenes", "Volúmenes de prueba"), false)
      equal(tree:texto("volumenes", original_text), true)
      tree:seleccionar("volumen_general")
      key(wx.WXK_RIGHT, true, { "ui.desplegar" })
      local selection_queries, original_selection = 0, tree.seleccion
      tree.seleccion = function(self)
        selection_queries = selection_queries + 1
        return original_selection(self)
      end
      key(wx.WXK_UP, true, { "ui.boton_1" })
      key(wx.WXK_DOWN, true, { "ui.boton_1" })
      key(wx.WXK_RIGHT, true, {})
      key(wx.WXK_LEFT, true, { "ui.plegar" })
      key(wx.WXK_UP, false, {})
      key(wx.WXK_DOWN, false, {})
      equal(selection_queries, 0)
      tree.seleccion = original_selection
      equal(demo.sesion:get("volumen_general"), 80)
      click(demo.cancelar_boton, "ui.cerrar_config")
    end)
    exercise("Enter despliega ramas, alterna booleanos y abre ajustes numéricos", function()
      local tree, wx = demo.arbol, demo.wx
      equal(tree:seleccion(), "volumenes")
      key(wx.WXK_RETURN, true, { "ui.desplegar" })
      key(wx.WXK_RETURN, true, {})
      assert(tree.control:IsExpanded(tree.items.volumenes))
      equal(tree:seleccion(), "volumenes")
      tree:seleccionar("volumen_general")
      key(wx.WXK_RETURN, true, { "ui.desplegar" })
      equal(demo.ajuste, "volumen_general")
      equal(demo.sesion:get("volumen_general"), 80)
      key(wx.WXK_UP, true, { "ui.boton_1" })
      equal(demo.sesion:get("volumen_general"), 85)
      key(wx.WXK_LEFT, true, { "ui.plegar" })

      tree:seleccionar("oficial")
      key(wx.WXK_NUMPAD_ENTER, true, { "ui.desplegar" })
      tree:seleccionar("oficial_interfaz")
      equal(#key(wx.WXK_RETURN, true, { "ui.boton_2" }), 0)
      equal(demo.ajuste, nil)
      equal(tree:seleccion(), "oficial_interfaz")
      equal(demo.sesion:get("oficial_interfaz"), false)
      equal(config.get("oficial_interfaz"), true)
      equal(tree.control:GetItemText(tree.items.oficial_interfaz), "Mostrar interfaz oficial: Desactivado")
      key(wx.WXK_NUMPAD_ENTER, true, { "ui.boton_2" })
      equal(demo.sesion:get("oficial_interfaz"), true)
      key(wx.WXK_RIGHT, true, { "ui.desplegar" })
      equal(demo.ajuste, "oficial_interfaz")
      equal(demo.sesion:get("oficial_interfaz"), true)
      key(wx.WXK_LEFT, true, { "ui.plegar" })
      key(wx.WXK_RETURN, true, { "ui.boton_2" })
      click(demo.cancelar_boton, "ui.cerrar_config")
      equal(config.get("oficial_interfaz"), true)
    end)
    exercise("Flechas: entrar y salir de ajustes, sonidos y límites", function()
      local tree, wx = demo.arbol, demo.wx
      key(wx.WXK_UP, false, {})
      key(wx.WXK_DOWN, false, {})
      key(wx.WXK_RIGHT, false, {}) -- La rama conserva su navegación nativa.
      tree.control:Expand(tree.items.volumenes)
      local before = #sound_requests
      tree:seleccionar("volumen_general")
      equal(sound_requests[#sound_requests], "ui.clic_1")
      equal(#sound_requests, before + 1)
      assert(sonidos.catalogo.sonidos["ui.clic_1"].archivos[1]:find("Clic 1.wav", 1, true))
      key(wx.WXK_RIGHT, true, { "ui.desplegar" })
      equal(demo.ajuste, "volumen_general")
      equal(demo.sesion:get("volumen_general"), 80)
      key(wx.WXK_UP, true, { "ui.boton_1" })
      equal(demo.sesion:get("volumen_general"), 85)
      equal(native_sounds[#native_sounds].volume, 68)
      equal(tree:seleccion(), "volumen_general")
      assert(tree.control:GetItemText(tree.items.volumen_general):find("85", 1, true))
      equal(config.get("volumen_general"), 80)
      key(wx.WXK_LEFT, true, { "ui.plegar" })
      equal(demo.ajuste, nil)
      equal(tree:seleccion(), "volumen_general")
      assert(tree.control:GetItemText(tree.items.volumen_general):find("Volumen general", 1, true))
      key(wx.WXK_UP, false, {}) -- Fuera del ajuste vuelve a recorrer el árbol.
      key(wx.WXK_RIGHT, true, { "ui.desplegar" })
      key(wx.WXK_UP, true, { "ui.boton_1" }) -- 90
      key(wx.WXK_UP, true, { "ui.boton_1" }) -- 95
      key(wx.WXK_UP, true, { "ui.boton_1" }) -- Llega a 100 sin aviso de límite.
      key(wx.WXK_UP, true, { "ui.limite" }) -- Repite contra el máximo.
      equal(demo.sesion:get("volumen_general"), 100)
      for _ = 1, 19 do key(wx.WXK_DOWN, true, { "ui.boton_1" }) end
      local played_before_zero = #native_sounds
      key(wx.WXK_DOWN, true, { "ui.boton_1" }) -- Llega a cero sin aviso de límite.
      key(wx.WXK_DOWN, true, { "ui.limite" })
      equal(demo.sesion:get("volumen_general"), 0)
      equal(#native_sounds, played_before_zero)
      tree:seleccionar("oficial_interfaz")
      equal(demo.ajuste, nil) -- Seleccionar otra fila termina el ajuste anterior.
      key(wx.WXK_RIGHT, true, { "ui.desplegar" })
      key(wx.WXK_DOWN, true, { "ui.boton_2" })
      equal(demo.sesion:get("oficial_interfaz"), false)
      key(wx.WXK_DOWN, true, { "ui.boton_2" })
      equal(demo.sesion:get("oficial_interfaz"), true)
      key(wx.WXK_UP, true, { "ui.boton_2" })
      equal(demo.sesion:get("oficial_interfaz"), false)
      key(wx.WXK_UP, true, { "ui.boton_2" })
      equal(demo.sesion:get("oficial_interfaz"), true)
      tree:seleccionar("oficial_fuente_canales")
      key(wx.WXK_RIGHT, true, { "ui.desplegar" })
      key(wx.WXK_UP, true, { "ui.boton_1" }) -- Predeterminado 0 pasa a 8.
      key(wx.WXK_DOWN, true, { "ui.boton_1" }) -- Anuncia solo 0.
      key(wx.WXK_DOWN, true, { "ui.limite" })
      demo.vista:pasar_foco(1)
      focus(demo.guardar_boton)
      equal(demo.ajuste, nil) -- Tab no deja un ajuste retenido al volver.
      demo.vista:pasar_foco(-1)
      focus(tree.control)
      key(wx.WXK_UP, false, {})
      click(demo.cancelar_boton, "ui.cerrar_config")
      equal(native_sounds[#native_sounds].volume, 64)
    end)
    exercise("Árbol nativo, foco circular y confirmación de predeterminados", function()
      local tree = demo.arbol
      equal(tree:seleccion(), "volumenes")
      equal(tree.control:GetName(), "Opciones de configuración")
      assert(not tree.items.guardar, "Guardar sigue siendo una fila del árbol")
      demo.vista:pasar_foco(1)
      focus(demo.guardar_boton)
      demo.vista:pasar_foco(1)
      focus(demo.cancelar_boton)
      demo.vista:pasar_foco(1)
      focus(tree.control)
      demo.vista:pasar_foco(-1)
      focus(demo.cancelar_boton)
      demo.vista:pasar_foco(-1)
      focus(demo.guardar_boton)
      demo.vista:pasar_foco(-1)
      focus(tree.control)
      tree:seleccionar("oficial_fuente_canales")
      equal(tree:seleccion(), "oficial_fuente_canales")
      assert(tree.control:GetItemText(tree.items.oficial_fuente_canales):find("Predeterminado del paquete", 1, true))
      demo.sesion:cambiar("volumen_general", -1)
      demo.activar("restablecer")
      equal(tree:seleccion(), "restablecer_no")
      demo.activar("restablecer_no")
      equal(demo.sesion:get("volumen_general"), 75)
      demo.activar("restablecer")
      tree:seleccionar("restablecer_si")
      demo.activar("restablecer_si")
      equal(demo.sesion:get("volumen_general"), 80)
      equal(tree:seleccion(), "restablecer")
      assert(not tree.control:IsExpanded(tree.items.restablecer))
      click(demo.cancelar_boton, "ui.cerrar_config")
    end)
    exercise("Cancelar descarta borrador sin lectura JSON", function()
      demo.sesion:cambiar("volumen_general", 1)
      equal(demo.sesion:get("volumen_general"), 85)
      equal(config.get("volumen_general"), 80)
      local original_open = io.open
      io.open = function() error("Cancelar intentó I/O") end
      local closed, error_message = pcall(function() click(demo.cancelar_boton, "ui.cerrar_config") end)
      io.open = original_open
      assert(closed, error_message)
    end)
    equal(config.get("volumen_general"), 80)
    equal(apply_calls, 0)
    exercise("Enter dentro del ajuste guarda todo el borrador y cierra", function()
      local tree, wx = demo.arbol, demo.wx
      tree:seleccionar("volumen_ambiente")
      key(wx.WXK_RIGHT, true, { "ui.desplegar" })
      key(wx.WXK_UP, true, { "ui.boton_1" })
      key(wx.WXK_LEFT, true, { "ui.plegar" })
      tree:seleccionar("volumen_general")
      key(wx.WXK_RETURN, true, { "ui.desplegar" })
      key(wx.WXK_UP, true, { "ui.boton_1" })
      key(wx.WXK_RETURN, true, { "ui.aceptar" })
    end)
    equal(config.get("volumen_general"), 85)
    equal(config.get("volumen_ambiente"), 75)
    equal(apply_calls, 1)
    exercise("Fallo de escritura al pulsar Enter conserva el ajuste y permite cancelar", function()
      local tree, wx = demo.arbol, demo.wx
      tree:seleccionar("oficial_interfaz")
      key(wx.WXK_RIGHT, true, { "ui.desplegar" })
      key(wx.WXK_DOWN, true, { "ui.boton_2" })
      local original_open = io.open
      io.open = function(path, mode)
        if mode:find("w", 1, true) then return nil, "Disco lleno provocado", 28 end
        return original_open(path, mode)
      end
      local readings, original_announce = {}, announce
      announce = function(text)
        readings[#readings + 1] = text
        return original_announce(text)
      end
      local saved, error_message = pcall(key, wx.WXK_NUMPAD_ENTER, true, { "ui.error" })
      announce = original_announce
      io.open = original_open
      assert(saved, error_message)
      equal(#readings, 1)
      assert(readings[1]:find("Disco lleno provocado", 1, true), readings[1])
      assert(demo.activo)
      equal(demo.ajuste, "oficial_interfaz")
      equal(config.get("oficial_interfaz"), true)
      equal(demo.sesion:get("oficial_interfaz"), false)
      equal(apply_calls, 1)
      click(demo.cancelar_boton, "ui.cerrar_config")
    end)
    exercise("Aplicación fallida conserva guardados y permite reintentar", function()
      local previous_apply = oficial.aplicar_configuracion
      oficial.aplicar_configuracion = function() error("Aplicación denegada provocada") end
      demo.sesion:cambiar("volumen_general", 1)
      local saved, error_message = pcall(demo.guardar)
      oficial.aplicar_configuracion = previous_apply
      assert(not saved and tostring(error_message):find("Aplicación denegada provocada", 1, true))
      assert(demo.activo and demo.sesion.guardado)
      equal(config.get("volumen_general"), 90)
      assert(demo.estado:GetLabel():find("guardadas", 1, true))
      click(demo.guardar_boton, "ui.aceptar")
    end)
    equal(config.get("volumen_general"), 90)
    exercise("Interfaz: borrador de ventanas flotantes no altera asociación y Cancelar conserva preferencia", function()
      local tree, wx = demo.arbol, demo.wx
      equal(config.get("ventanasflotantes"), true)
      equal(tree.control:GetItemText(tree.items.interfaz), "Interfaz")
      equal(tree.control:GetItemText(tree.control:GetItemParent(tree.items.ventanasflotantes)), "Interfaz")
      tree:seleccionar("ventanasflotantes")
      key(wx.WXK_RIGHT, true, { "ui.desplegar" })
      key(wx.WXK_DOWN, true, { "ui.boton_2" })
      equal(demo.sesion:get("ventanasflotantes"), false)
      equal(config.get("ventanasflotantes"), true)
      local owner = nativo.propietario(demo.ventana)
      equal(owner, nativo.mudlet())
      local additional = ui.nueva("Ventana durante edición sin guardar")
      local checked, check_error = pcall(function()
        equal(nativo.propietario(additional.dialogo), owner)
        equal(nativo.propietario(demo.ventana), owner)
      end)
      additional:destruir()
      assert(checked, check_error)
      click(demo.cancelar_boton, "ui.cerrar_config")
    end)
    equal(config.get("ventanasflotantes"), true)
    exercise("Interfaz: Guardar persiste false sin cambiar la ventana ya construida", function()
      local owner = nativo.propietario(demo.ventana)
      demo.arbol:seleccionar("ventanasflotantes")
      key(demo.wx.WXK_RIGHT, true, { "ui.desplegar" })
      key(demo.wx.WXK_DOWN, true, { "ui.boton_2" })
      local previous_apply = oficial.aplicar_configuracion
      oficial.aplicar_configuracion = function(settings)
        equal(settings.get("ventanasflotantes"), false)
        equal(nativo.propietario(demo.ventana), owner)
        return previous_apply(settings)
      end
      local saved, save_error = pcall(function() click(demo.guardar_boton, "ui.aceptar") end)
      oficial.aplicar_configuracion = previous_apply
      assert(saved, save_error)
    end)
    equal(config.get("ventanasflotantes"), false)
    exercise("Interfaz: próxima apertura independiente conserva false al cancelar", function()
      local runtime = comprobaciones.cargar_nativo()
      equal(nativo.propietario(demo.ventana), runtime.ffi.nullptr)
      local file = assert(io.open(config.path(), "r"))
      local document = yajl.to_value(file:read("*a"))
      file:close()
      equal(document.valores.ventanasflotantes, false)
      demo.sesion:cambiar("ventanasflotantes", 1)
      equal(demo.sesion:get("ventanasflotantes"), true)
      equal(nativo.propietario(demo.ventana), runtime.ffi.nullptr)
      click(demo.cancelar_boton, "ui.cerrar_config")
    end)
    equal(config.get("ventanasflotantes"), false)
    config.set("ventanasflotantes", true)
    assert(config.save())
    local original_associate = nativo.asociar
    local failed_window = "RhomScripts_error_asociacion_constructor"
    nativo.asociar = function(window)
      window:SetName(failed_window)
      error("Asociación denegada provocada", 0)
    end
    local constructed, constructor_error = pcall(ui.nueva, "Constructor con fallo de asociación")
    nativo.asociar = original_associate
    assert(not constructed and tostring(constructor_error):find("Asociación denegada provocada", 1, true))
    local remaining = demo.wx.wxWindow.FindWindowByName(failed_window)
    assert(not remaining or remaining == demo.wx.NULL, "El constructor fallido dejó una ventana huérfana")
    results[#results + 1] = "Constructor propaga fallo de asociación y destruye la ventana incompleta"
    exercise("Interfaz: asociación predeterminada recuperada tras error del constructor", function()
      equal(nativo.propietario(demo.ventana), nativo.mudlet())
      click(demo.cancelar_boton, "ui.cerrar_config")
    end)
    equal(apply_calls, 3)
    local destruction_seen, reentry_error = false, nil
    local destroyed_window = demo.ventana
    local window_name = destroyed_window:GetName()
    demo.ventana:Connect(demo.wx.wxEVT_DESTROY, function(event)
      destruction_seen = true
      local protected, callback_error = xpcall(function()
        assert(demo.cerrando and not demo.activo, "Destrucción sin guardia de cierre")
        local window, session = demo.ventana, demo.sesion
        local sounds_before, applications_before = #sound_requests, apply_calls
        demo.abrir()
        demo.guardar()
        demo.activar("restablecer")
        assert(demo.cerrar())
        equal(demo.ventana, window)
        equal(demo.sesion, session)
        equal(#sound_requests, sounds_before)
        equal(apply_calls, applications_before)
      end, debug.traceback)
      if not protected then reentry_error = callback_error end
      event:Skip()
    end)
    demo.destruir()
    assert(destruction_seen, "No se observó el evento nativo de destrucción")
    assert(not reentry_error, reentry_error)
    local destroyed_remaining = demo.wx.wxWindow.FindWindowByName(window_name)
    assert(not destroyed_remaining or destroyed_remaining == demo.wx.NULL, "La destrucción explícita dejó una ventana")
    results[#results + 1] = "Destrucción explícita impide reapertura y acciones reentrantes"
    demo.preparar()
    local view, destroy = demo.vista, demo.vista.destruir
    view.destruir = function(self)
      destroy(self)
      error("Fallo de destrucción provocado", 0)
    end
    local destroyed, destruction_error = pcall(demo.destruir)
    assert(not destroyed and tostring(destruction_error):find("Fallo de destrucción provocado", 1, true))
    for _, field in ipairs({ "ventana", "arbol", "vista", "sesion", "estado", "guardar_boton", "cancelar_boton", "ajuste" }) do
      equal(demo[field], nil)
    end
    results[#results + 1] = "Fallo tras destruir se propaga y limpia recursos"
    local previous_native = package.loaded.wx
    package.loaded.configurador = nil
    demo = require("configurador")
    demo.preparar()
    exercise("X tras preparar de nuevo conserva DLL y descarta edición", function()
      equal(package.loaded.wx, previous_native)
      demo.sesion:cambiar("volumen_general", -1)
      assert(demo.ventana:Close())
    end)
    equal(config.get("volumen_general"), 90)
    demo.destruir()
  end, debug.traceback)
  oficial.aplicar_configuracion = apply
  audio.reproducir = reproduce
  audio.stop_tag()
  assert(ok, message)
end

local ok, message = xpcall(run, debug.traceback)
finish(ok, message)
if not ok then error(message, 0) end
