-- Recepción textual de Comunicaciones.set, líneas 319 a 346.
local captura = {}

local emisor = [=[[^\s:\[\]>][^:\r\n]*?]=]
-- Mudlet añade un salto de línea al texto que recibe el motor de triggers.
local mensaje = [=[:[ \t]+\S[^\r\n]*(?=\n?\z)]=]
local verbo_telepatia = [=[te[ \t]+(?:dice|exclama|pregunta)]=]
local fecha_historica = [=[[0-9]{1,4}-[0-9]{1,2}-[0-9]{1,4}[ \t]+\([0-9]{1,2}:[0-9]{2}\)[ \t]+-[ \t]+]=]

local patrones = {
  telepatia = [=[(?i)\A[ \t]*(?:]=] .. emisor .. "[ \\t]+" .. verbo_telepatia
    .. "|" .. fecha_historica .. emisor .. "[ \\t]+te[ \\t]+dijo)" .. mensaje,
  -- La cabecera termina en los primeros dos puntos, para no confundir el texto citado con otro mensaje.
  room = [=[(?i)\A[ \t]*(?!(?:dices|preguntas|exclamas|susurras|balbuceas|ordenas|respondes)(?:[ \t]|:))]=]
    .. [=[(?![^:\r\n]*[ \t]+]=] .. verbo_telepatia .. ":)"
    .. [=[(?:Oyes[ \t]+una[ \t]+voz[ \t]+[^:\r\n]+[ \t]+de[ \t]+[^:\r\n]+[ \t]+decir|]=]
    .. emisor .. [=[[ \t]+(?:(?:pregunta|exclama|dice|balbucea)(?:[ \t]+[^:\r\n]+)?|te[ \t]+susurra|ordena|responde))]=]
    .. mensaje,
}

function captura.nueva()
  local instancia, registros = {}, {}
  local iniciada = false

  function instancia.cantidad()
    return #registros
  end

  function instancia.consultar()
    local resultado = {}
    for _, registro in ipairs(registros) do
      resultado[#resultado + 1] = { modulo = "comunicaciones", nombre = registro.nombre,
        descripcion = "Captura mensajes de " .. registro.nombre, patron = patrones[registro.nombre],
        accion = "comunicaciones.historiales." .. registro.nombre .. ".recibir_texto",
        id = registro.id, estado = iniciada and "registrado" or "inactivo" }
    end
    return resultado
  end

  function instancia.detener()
    iniciada = false
    local errores = {}
    for i = #registros, 1, -1 do
      local id = registros[i].id
      local correcto, resultado = pcall(function()
        assert(killTrigger(id), "No se pudo retirar el trigger de comunicaciones " .. id)
      end)
      if correcto then
        table.remove(registros, i)
      else
        errores[#errores + 1] = tostring(resultado)
      end
    end
    if #errores > 0 then error(table.concat(errores, "\n"), 0) end
  end

  function instancia.iniciar(recibir)
    if iniciada then return end
    assert(type(recibir) == "function", "Falta la recepción de comunicaciones")
    assert(#registros == 0, "Quedan triggers de comunicaciones pendientes de retirar")
    local correcto, mensaje_error = pcall(function()
      for _, historial in ipairs({ "telepatia", "room" }) do
        local id, fallo = tempRegexTrigger(patrones[historial], function()
          if iniciada then recibir(historial, matches[1]) end
        end)
        assert(type(id) == "number" and id > 0, fallo or "No se pudo registrar el trigger de " .. historial)
        registros[#registros + 1] = { id = id, nombre = historial }
      end
    end)
    if not correcto then
      local limpio, error_limpieza = pcall(instancia.detener)
      if not limpio then mensaje_error = tostring(mensaje_error) .. "\n" .. tostring(error_limpieza) end
      error(mensaje_error, 0)
    end
    iniciada = true
  end

  return instancia
end

return captura
