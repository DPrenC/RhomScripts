-- Preferencias persistentes. No depende del menú ni del motor de sonido.
-- luacheck: globals RL_fijar_opcion
local configuracion = { dirty = false }
local valores = {}
local lectura_bloqueada = false
local debug_guardado_pendiente = false

configuracion.opciones = {
  { id = "volumen_general", nombre = "Volumen general", tipo = "numero", defecto = 80, minimo = 0, maximo = 100, paso = 5 },
  { id = "volumen_interfaz", nombre = "Volumen de interfaz", tipo = "numero", defecto = 80, minimo = 0, maximo = 100, paso = 5 },
  { id = "volumen_comunicaciones", nombre = "Volumen de comunicaciones", tipo = "numero", defecto = 80, minimo = 0, maximo = 100, paso = 5 },
  { id = "volumen_combate", nombre = "Volumen de combate", tipo = "numero", defecto = 80, minimo = 0, maximo = 100, paso = 5 },
  { id = "volumen_ambiente", nombre = "Volumen de ambiente", tipo = "numero", defecto = 70, minimo = 0, maximo = 100, paso = 5 },
  { id = "ventanasflotantes", nombre = "Ventanas flotantes", tipo = "booleano", defecto = true, categoria = "interfaz" },
  { id = "mapa_destinos", nombre = "Interfaz del mapa", tipo = "selector", defecto = true, categoria = "interfaz",
    opciones = { { valor = true, nombre = "Rhomscripts" }, { valor = false, nombre = "Config oficial" } } },
  { id = "oficial_depuracion", nombre = "Modo debug", tipo = "booleano", defecto = false,
    categoria = "interfaz", persistente = false },
  { id = "canales_limite", nombre = "Mensajes por canal", tipo = "numero", defecto = 500,
    minimo = 100, maximo = 5000, paso = 100, unidad = "mensajes", categoria = "canales" },
  { id = "canales_total", nombre = "Mensajes totales", tipo = "numero", defecto = 5000,
    minimo = 100, maximo = 20000, paso = 100, unidad = "mensajes", categoria = "canales" },
  { id = "oficial_interfaz", nombre = "Mostrar interfaz oficial", tipo = "booleano", defecto = true, categoria = "oficial" },
  { id = "oficial_canales", nombre = "Mostrar panel de canales", tipo = "booleano", defecto = true, categoria = "oficial" },
  { id = "oficial_canales_consola", nombre = "Mostrar canales en la consola principal", tipo = "booleano", defecto = true, categoria = "oficial",
    aviso = "La copia oficial de mensajes requiere que su interfaz y panel de canales estén visibles." },
  { id = "oficial_teclado", nombre = "Teclado numérico oficial", tipo = "booleano", defecto = true, categoria = "oficial",
    aviso = "Puede coincidir con el movimiento de RhomScripts." },
  { id = "oficial_macros", nombre = "Macros oficiales F1 a F12", tipo = "booleano", defecto = false, categoria = "oficial",
    aviso = "Pueden coincidir con las teclas de RhomScripts. Su activación necesita datos del personaje." },
  { id = "oficial_msp", nombre = "Sonidos y música MSP oficiales", tipo = "booleano", defecto = true, categoria = "oficial",
    aviso = "El sistema oficial puede detener sonidos de RhomScripts." },
  { id = "oficial_discord", nombre = "Integración con Discord", tipo = "booleano", defecto = true, categoria = "oficial" },
  { id = "oficial_descargar_mapa", nombre = "Descargar mapa automáticamente cuando falta", tipo = "booleano", defecto = true, categoria = "oficial" },
  { id = "oficial_fuente_canales", nombre = "Tamaño de letra del panel de canales", tipo = "numero", defecto = 0,
    minimo = 0, minimo_positivo = 8, maximo = 50, paso = 1, unidad = "puntos",
    cero = "Predeterminado del paquete", categoria = "oficial" },
  { id = "oficial_comunicaciones", nombre = "Recibir comunicaciones GMCP", tipo = "booleano", defecto = true, categoria = "oficial" },
  { id = "oficial_msp_debug", nombre = "Depuración MSP", tipo = "booleano", defecto = false, categoria = "oficial" },
}

local function aviso(operacion, mensaje)
  local texto = RhomScripts.modules.debug.error_configuracion(operacion, mensaje)
  configuracion.ultimo_error = texto
  return nil, texto
end

local function opcion(id)
  for _, entrada in ipairs(configuracion.opciones) do
    if entrada.id == id then return entrada end
  end
end

local function valido(entrada, valor)
  if entrada.tipo == "selector" then
    for _, alternativa in ipairs(entrada.opciones) do
      if valor == alternativa.valor then return true end
    end
    return false
  end
  if entrada.tipo == "booleano" then return type(valor) == "boolean" end
  return type(valor) == "number" and valor >= entrada.minimo and valor <= entrada.maximo
    and valor % entrada.paso == 0
    and (not entrada.minimo_positivo or valor == 0 or valor >= entrada.minimo_positivo)
end

function configuracion.path()
  return getMudletHomeDir() .. "/config.json"
end

function configuracion.get(id)
  assert(opcion(id), "Opción de configuración desconocida: " .. tostring(id))
  if id == "oficial_depuracion" then
    return RL_vars ~= nil and RL_vars.opciones ~= nil and RL_vars.opciones.depuracion == true
  end
  return valores[id]
end

function configuracion.set(id, valor)
  local entrada = assert(opcion(id), "Opción de configuración desconocida: " .. tostring(id))
  assert(valido(entrada, valor), "Valor inválido para " .. id .. ": " .. tostring(valor))
  if entrada.persistente == false then
    if configuracion.get(id) ~= valor or debug_guardado_pendiente then
      debug_guardado_pendiente = true
      assert(RL_fijar_opcion("depuracion", valor), "No se pudo guardar el modo debug compartido")
      debug_guardado_pendiente = false
    end
    return
  end
  if valores[id] ~= valor then
    valores[id] = valor
    configuracion.dirty = true
  end
end

function configuracion.reset()
  for _, entrada in ipairs(configuracion.opciones) do
    if entrada.persistente ~= false then configuracion.set(entrada.id, entrada.defecto) end
  end
  configuracion.dirty = true
end

local function persistir(datos, guardar_actual)
  if lectura_bloqueada then
    return aviso("guardar", "no se sustituirá un archivo que no se pudo leer; vuelva a cargar la configuración antes de guardar")
  end
  if guardar_actual then configuracion.dirty = true end
  local ruta = configuracion.path()
  local temporal = ruta .. ".tmp"
  local contenido = yajl.to_string({ version = 2, valores = datos })
  local archivo, mensaje = io.open(temporal, "wb")
  if not archivo then return aviso("guardar", mensaje) end
  local escrito, error_escritura = archivo:write(contenido .. "\n")
  local cerrado, error_cierre = archivo:close()
  if not escrito or not cerrado then
    os.remove(temporal)
    return aviso("guardar", error_escritura or error_cierre)
  end
  local movido, error_movimiento = os.rename(temporal, ruta)
  -- El CRT de Windows no sustituye un destino existente con rename.
  -- Retirar el destino solo después de cerrar correctamente el temporal.
  if not movido and lfs.attributes(ruta, "mode") == "file" then
    local retirado, error_retirada = os.remove(ruta)
    if not retirado then return aviso("guardar", error_retirada) end
    movido, error_movimiento = os.rename(temporal, ruta)
  end
  if not movido then return aviso("guardar", error_movimiento) end
  configuracion.dirty = false
  configuracion.ultimo_error = nil
  return true
end

function configuracion.save()
  return persistir(valores, true)
end

-- El borrador no sustituye los valores confirmados hasta que el archivo se ha
-- escrito. Copiar y validar también impide conservar referencias de la vista.
function configuracion.guardar_valores(borrador)
  assert(type(borrador) == "table", "El borrador debe ser una tabla")
  local copia = {}
  for _, entrada in ipairs(configuracion.opciones) do
    local valor = borrador[entrada.id]
    assert(valido(entrada, valor), "Valor inválido para " .. entrada.id .. ": " .. tostring(valor))
    if entrada.persistente ~= false then copia[entrada.id] = valor end
  end
  for id in pairs(borrador) do
    assert(opcion(id), "Opción de configuración desconocida: " .. tostring(id))
  end
  local correcto, mensaje = persistir(copia)
  if not correcto then return nil, mensaje end
  valores = copia
  return true
end

local function estructura_valida(datos)
  if type(datos) ~= "table" or (datos.version ~= 1 and datos.version ~= 2)
      or type(datos.valores) ~= "table" then return false end
  local ampliada = false
  -- La copia histórica deja de ser autoridad: conservar la opción oficial y
  -- retirar únicamente el campo antiguo, sin aplicarlo al paquete.
  if datos.valores.oficial_depuracion ~= nil then
    datos.valores.oficial_depuracion = nil
    ampliada = true
  end
  for _, entrada in ipairs(configuracion.opciones) do
    if entrada.persistente ~= false then
      -- Completar las preferencias incorporadas después de los primeros perfiles.
      if datos.valores[entrada.id] == nil and (entrada.id == "ventanasflotantes" or entrada.id == "mapa_destinos"
        or entrada.id == "volumen_comunicaciones" or entrada.categoria == "canales"
        or (datos.version == 1 and entrada.categoria == "oficial")) then
        datos.valores[entrada.id] = entrada.defecto
        ampliada = true
      end
      if not valido(entrada, datos.valores[entrada.id]) then return false end
    end
  end
  for id in pairs(datos.valores) do
    if not opcion(id) then return false end
  end
  return true, ampliada
end

function configuracion.load()
  local ruta = configuracion.path()
  local archivo, mensaje, codigo = io.open(ruta, "rb")
  local recuperando = false
  if not archivo and codigo == 2 then
    -- Tras una interrupción entre remove y rename en Windows, el temporal
    -- cerrado conserva los valores nuevos. Validarlo antes de recuperarlo.
    archivo, mensaje, codigo = io.open(ruta .. ".tmp", "rb")
    recuperando = archivo ~= nil
  end
  if not archivo then
    if codigo ~= 2 then
      lectura_bloqueada = true
      return aviso("leer", mensaje)
    end
    lectura_bloqueada = false
    configuracion.reset()
    return configuracion.save()
  end
  local texto, error_lectura = archivo:read("*a")
  local cerrado, error_cierre = archivo:close()
  if not texto or not cerrado then
    lectura_bloqueada = true
    return aviso("leer", error_lectura or error_cierre)
  end
  lectura_bloqueada = false
  -- La llamada directa propaga una API ausente. Solo el análisis del contenido
  -- externo se protege: un JSON mal formado es un error de datos recuperable.
  yajl.to_value("{}")
  local correcto, datos = pcall(yajl.to_value, texto)
  local valida, ampliada
  if correcto then valida, ampliada = estructura_valida(datos) end
  if not valida then
    aviso("leer", "archivo JSON incorrecto; se restablecen los valores predeterminados")
    configuracion.reset()
    configuracion.dirty = true
    return configuracion.save()
  end
  for _, entrada in ipairs(configuracion.opciones) do
    if entrada.persistente ~= false then valores[entrada.id] = datos.valores[entrada.id] end
  end
  if recuperando then
    RhomScripts.modules.debug.configuracion_recuperada()
    -- El temporal es la única copia persistida: promoverlo sin truncarlo.
    configuracion.dirty = true
    local movido, error_movimiento = os.rename(ruta .. ".tmp", ruta)
    if not movido then return aviso("guardar", error_movimiento) end
  end
  if datos.version == 1 or ampliada then return configuracion.save() end
  configuracion.dirty = false
  configuracion.ultimo_error = nil
  return true
end

configuracion.reset()
return configuracion
