-- Fuentes y atajos de los historiales de comunicaciones.
local historial = require("comunicaciones_historial")
local captura = require("comunicaciones_captura").nueva()
local comunicaciones = historial.nuevo({ titulo = "Historial de canales", tecla = "F1",
  ayuda = "Tab: cambiar canal. Flechas: mensajes. Alt+F1: último. Ctrl+F1: silencio. Escape: salir." })
local room = historial.nuevo({ titulo = "Historial Room", tecla = "F2", tipo = "room",
  ayuda = "Tab: cambiar pestaña. Alt+F2: último. Ctrl+F2: silencio. Escape: salir." })
local telepatia = historial.nuevo({ titulo = "Historial de telepatía", tecla = "F3", tipo = "telepatia",
  ayuda = "Flechas: mensajes. Alt+F3: último. Ctrl+F3: silencio. Escape: salir." })
comunicaciones.historiales = { room = room, telepatia = telepatia }
comunicaciones.cantidad_triggers = captura.cantidad
comunicaciones.consultar_triggers = captura.consultar
local handlers = {}
local preparar_canales, reiniciar_canales, destruir_canales =
  comunicaciones.preparar, comunicaciones.reiniciar, comunicaciones.destruir

local function intentar(errores, funcion, ...)
  local correcto, mensaje = pcall(funcion, ...)
  if not correcto then errores[#errores + 1] = tostring(mensaje) end
end

function comunicaciones.detener()
  local errores = {}
  intentar(errores, captura.detener)
  intentar(errores, comunicaciones.cancelar_avisos)
  for _, id in ipairs(handlers) do
    intentar(errores, killAnonymousEventHandler, id)
  end
  handlers = {}
  comunicaciones.iniciado = false
  if #errores > 0 then error(table.concat(errores, "\n"), 0) end
end

function comunicaciones.reiniciar()
  reiniciar_canales()
  room.reiniciar()
  telepatia.reiniciar()
end

function comunicaciones.destruir()
  local errores = {}
  intentar(errores, comunicaciones.detener)
  intentar(errores, destruir_canales)
  intentar(errores, room.destruir)
  intentar(errores, telepatia.destruir)
  if #errores > 0 then error(table.concat(errores, "\n"), 0) end
end

function comunicaciones.preparar()
  local correcto, mensaje = pcall(function()
    preparar_canales()
    room.preparar()
    telepatia.preparar()
    comunicaciones.iniciar()
  end)
  if not correcto then
    local limpio, error_limpieza = pcall(comunicaciones.destruir)
    if not limpio then mensaje = tostring(mensaje) .. "\n" .. tostring(error_limpieza) end
    error(mensaje, 0)
  end
end

local canales_genericos = { gremio = true, bando = true, ciu = true, clan = true }

local function aplicar_cambio_canal(datos, aplicar)
  local id = datos.canal
  if not canales_genericos[id] then aplicar(id) end
end

function comunicaciones.iniciar()
  if comunicaciones.iniciado then return end
  local function escuchar(evento, funcion)
    handlers[#handlers + 1] = registerAnonymousEventHandler(evento, funcion)
  end
  local correcto, mensaje = pcall(function()
    escuchar("gmcp.Comm.Canales", function() comunicaciones.reconciliar(gmcp.Comm.Canales) end)
    escuchar("gmcp.Comm.EnciendeCanal", function()
      aplicar_cambio_canal(gmcp.Comm.EnciendeCanal, comunicaciones.abrir_canal)
    end)
    escuchar("gmcp.Comm.ApagaCanal", function()
      aplicar_cambio_canal(gmcp.Comm.ApagaCanal, comunicaciones.cerrar_canal)
    end)
    escuchar("gmcp.Comm.MensajeCanal", function() comunicaciones.recibir(gmcp.Comm.MensajeCanal, false) end)
    escuchar("gmcp.Comm.MensajeCanalHistorico", function() comunicaciones.recibir(gmcp.Comm.MensajeCanalHistorico, true) end)
    escuchar("sysDisconnectionEvent", comunicaciones.reiniciar)
    escuchar("sysConnectionEvent", comunicaciones.reiniciar)
    captura.iniciar(function(id, texto) comunicaciones.historiales[id].recibir_texto(texto) end)
    local _, _, conectado = getConnectionInfo()
    if conectado and gmcp and gmcp.Comm and gmcp.Comm.Canales then
      comunicaciones.reconciliar(gmcp.Comm.Canales, true)
    end
    comunicaciones.iniciado = true
  end)
  if not correcto then
    local limpio, error_limpieza = pcall(comunicaciones.detener)
    if not limpio then mensaje = tostring(mensaje) .. "\n" .. tostring(error_limpieza) end
    error(mensaje, 0)
  end
end

local function anterior() return comunicaciones.cambiar_categoria(-1) end
local function siguiente() return comunicaciones.cambiar_categoria(1) end
local function room_anterior() return room.cambiar_categoria(-1) end
local function room_siguiente() return room.cambiar_categoria(1) end
local function pulsacion(tecla, modificadores, id, funcion, descripcion)
  return { combinacion = { tecla = tecla, modificadores = modificadores },
    nombre = "comunicaciones." .. id, funcion = funcion, descripcion = descripcion, grupo = "comunicaciones" }
end
comunicaciones.pulsaciones = {
  pulsacion(mudlet.key.F1, { mudlet.keymodifier.Shift }, "mostrar_historial", comunicaciones.mostrar_historial, "Abre el historial de canales"),
  pulsacion(mudlet.key.F1, { mudlet.keymodifier.Alt }, "leer_ultimo", comunicaciones.leer_ultimo, "Lee el último mensaje de la categoría seleccionada"),
  pulsacion(mudlet.key.Comma, { mudlet.keymodifier.Control }, "anterior", anterior, "Selecciona la categoría anterior"),
  pulsacion(mudlet.key.Period, { mudlet.keymodifier.Control }, "siguiente", siguiente, "Selecciona la categoría siguiente"),
  pulsacion(mudlet.key.F1, { mudlet.keymodifier.Control }, "silenciar_canales", comunicaciones.alternar_silencio, "Alterna el silencio del canal seleccionado"),
  pulsacion(mudlet.key.F2, { mudlet.keymodifier.Shift }, "mostrar_room", room.mostrar_historial, "Abre el historial de Room"),
  pulsacion(mudlet.key.F2, { mudlet.keymodifier.Alt }, "leer_room", room.leer_ultimo, "Lee el último mensaje de la pestaña seleccionada de Room"),
  pulsacion(mudlet.key.F2, { mudlet.keymodifier.Control }, "silenciar_room", room.alternar_silencio, "Alterna el silencio de la pestaña seleccionada de Room"),
  pulsacion(mudlet.key.F3, { mudlet.keymodifier.Shift }, "mostrar_telepatia", telepatia.mostrar_historial, "Abre el historial de telepatía"),
  pulsacion(mudlet.key.F3, { mudlet.keymodifier.Alt }, "leer_telepatia", telepatia.leer_ultimo, "Lee el último mensaje de telepatía"),
  pulsacion(mudlet.key.F3, { mudlet.keymodifier.Control }, "silenciar_telepatia", telepatia.alternar_silencio, "Alterna el silencio de telepatía"),
  pulsacion(mudlet.key.Comma, { mudlet.keymodifier.Control, mudlet.keymodifier.Shift }, "room_anterior", room_anterior, "Selecciona la pestaña anterior de Room"),
  pulsacion(mudlet.key.Period, { mudlet.keymodifier.Control, mudlet.keymodifier.Shift }, "room_siguiente", room_siguiente, "Selecciona la pestaña siguiente de Room"),
}

return comunicaciones
