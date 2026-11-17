-- Diagnóstico de sesión. Se carga por ruta: la biblioteca estándar debug queda intacta.
local depuracion = {}
local version_distribucion = "1.0, 17/11/2026"
local estados, modulos, proveedores = {}, {}, {}
local historial, primero, cantidad = {}, 1, 0
local limite = 500
local avisos = {}
local indices_avisos = {}
local nombres = { scripts = "Scripts", paquete = "Paquete oficial", preferencias = "Preferencias oficiales",
  conexion = "Conexión", gmcp = "GMCP", ficha = "Ficha", estado_personaje = "Estado del personaje",
  comunicaciones = "Comunicaciones", msp = "MSP", recursos_msp = "Recursos MSP" }
local orden = { "scripts", "paquete", "preferencias", "conexion", "gmcp", "ficha",
  "estado_personaje", "comunicaciones", "msp", "recursos_msp" }
local plantillas = {
  oficial_instalado = "Paquete oficial: instalado.",
  oficial_activo = "Paquete oficial: activo (inicialización local).",
  oficial_esperando = "Paquete oficial: esperando inicialización local.",
  oficial_instalando = "Paquete oficial: no instalado. Instalando.",
  fuente_pendiente = "Fuente de canales: al mostrar la interfaz y el panel.",
  macros_pendientes = "Macros: pendientes de conexión y ficha del personaje.",
  discord_pendiente = "Discord: pendiente de conexión y negociación GMCP.",
  comunicaciones_pendientes = "Comunicaciones: suscripción local preparada; pendiente de GMCP.",
}

local detalles = {
  local_listo = "inicialización local confirmada",
  local_iniciando = "inicializando servicios locales",
  datos_pendientes = "sin datos confirmados de esta conexión",
  desconectada = "desconectada",
  sin_conexion = "sin conexión",
  sonidos_sin_verificar = "ruta configurada; integridad de sonidos sin verificar",
  opciones_pendientes = "esperando las opciones oficiales",
  sin_comprobar = "sin comprobar",
  desactivado = "desactivado en las preferencias",
  msp_inicializado = "inicializado localmente; reproducción no confirmada",
  sonidos_descargando = "descargando el paquete de sonidos",
  msp_esperando = "habilitado; esperando inicialización local",
  sonidos_extrayendo = "descarga terminada; esperando extracción",
  sonidos_extraidos = "paquete de sonidos extraído; reproducción no confirmada",
  conectada = "conectada",
  gmcp_esperando = "esperando negociación y saludo del servidor",
  gmcp_habilitado = "protocolo habilitado; esperando saludo del servidor",
  gmcp_deshabilitado = "protocolo deshabilitado",
  gmcp_activo = "saludo del servidor recibido",
  gmcp_finalizado = "despedida GMCP recibida",
  datos_recibidos = "datos recibidos en esta conexión",
  paquete_ausente = "paquete oficial desinstalado",
  paquete_no_disponible = "paquete oficial no disponible",
  ficha_disponible = "ficha disponible",
  estado_disponible = "estado disponible",
  comunicaciones_disponibles = "comunicaciones disponibles",
  paquete_comprobando = "comprobando paquete oficial",
  local_esperando = "esperando inicialización local",
  paquete_descargando = "descargando paquete oficial",
  paquete_instalando = "instalando paquete oficial",
  preferencias_aplicando = "aplicando preferencias guardadas",
  preferencias_aplicadas = "preferencias aplicadas",
  gmcp_disponible = "saludo disponible en la conexión actual",
  error_extraer_sonidos = "error al extraer el paquete de sonidos",
  scripts_iniciando = "iniciando scripts",
  scripts_cargados = "scripts cargados correctamente",
}

function depuracion.detalle(codigo)
  return assert(detalles[codigo], "Detalle desconocido: " .. tostring(codigo))
end

local function copiar(valor)
  if type(valor) ~= "table" then return valor end
  local copia = {}
  for clave, dato in pairs(valor) do copia[clave] = copiar(dato) end
  return copia
end

local function ordenar(lista)
  table.sort(lista, function(a, b)
    if a.modulo ~= b.modulo then return a.modulo < b.modulo end
    return (a.nombre or a.componente or "") < (b.nombre or b.componente or "")
  end)
  return lista
end

function depuracion.activo()
  return RL_vars ~= nil and RL_vars.opciones ~= nil and RL_vars.opciones.depuracion == true
end

function depuracion.version()
  return version_distribucion
end

local function registrar(modulo, codigo, texto)
  local entrada = { modulo = modulo, codigo = codigo, texto = tostring(texto), actualizado = os.time() }
  local posicion = ((primero + cantidad - 1) % limite) + 1
  if cantidad == limite then
    posicion = primero
    primero = (primero % limite) + 1
  else
    cantidad = cantidad + 1
  end
  historial[posicion] = entrada
  return entrada
end

function depuracion.texto(modulo, texto)
  local entrada = registrar(modulo, "texto", texto)
  if depuracion.activo() then echo("[RhomScripts · " .. modulo .. "] " .. entrada.texto .. "\n") end
end

function depuracion.mensaje(modulo, codigo, datos)
  local texto = assert(plantillas[codigo], "Mensaje de debug desconocido: " .. tostring(codigo))
  if datos then texto = string.format(texto, unpack(datos)) end
  registrar(modulo, codigo, texto)
  if depuracion.activo() then echo("[RhomScripts · " .. modulo .. "] " .. texto .. "\n") end
  return texto
end

function depuracion.pendiente(codigo)
  return assert(plantillas[codigo], "Pendiente desconocido: " .. tostring(codigo))
end

local function hito(texto, color)
  registrar("arranque", "hito", texto)
  cecho("<" .. color .. "><b>RhomScripts</b><reset> · " .. texto .. "<reset>\n")
  announce("RhomScripts: " .. texto)
end

function depuracion.iniciar_carga() hito("Cargando…", "cyan") end

function depuracion.terminar_carga()
  if #avisos > 0 then hito("Carga con avisos. Consulte rhomscripts estado.", "yellow")
  else hito("Carga correcta.", "green") end
end

function depuracion.fallar_carga(mensaje)
  depuracion.estado.actualizar("scripts", "error", tostring(mensaje), "carga")
  -- El error es texto externo: no se interpreta como etiquetas de color.
  hito("Error de carga.", "red")
  echo(tostring(mensaje) .. "\n")
  announce(tostring(mensaje))
end

function depuracion.aviso(modulo, codigo, texto)
  local clave = modulo .. ":" .. codigo
  local indice = indices_avisos[clave]
  indice = indice or (#avisos + 1)
  indices_avisos[clave] = indice
  avisos[indice] = { modulo = modulo, codigo = codigo, detalle = texto }
  registrar(modulo, codigo, texto)
  echo("RhomScripts: aviso. " .. texto .. "\n")
  announce("RhomScripts: aviso. " .. texto)
end

function depuracion.error_configuracion(operacion, mensaje)
  local texto = "Error al " .. operacion .. " la configuración: " .. tostring(mensaje)
  depuracion.aviso("configuracion", "error_" .. operacion, texto)
  return texto
end

function depuracion.configuracion_recuperada()
  depuracion.aviso("configuracion", "recuperada",
    "Se recupera la configuración desde el archivo temporal de un guardado interrumpido.")
end

depuracion.estado = {}
function depuracion.estado.consultar(componente)
  if componente then
    assert(nombres[componente], "Componente de estado desconocido: " .. tostring(componente))
    return copiar(estados[componente])
  end
  return copiar(estados)
end

function depuracion.estado.actualizar(componente, codigo, detalle, causa)
  assert(nombres[componente], "Componente de estado desconocido: " .. tostring(componente))
  assert(type(codigo) == "string" and type(detalle) == "string", "Estado y detalle deben ser texto")
  assert(causa == nil or type(causa) == "string", "La causa del estado debe ser texto")
  local anterior = estados[componente]
  if anterior and anterior.codigo == codigo and anterior.detalle == detalle then return false end
  estados[componente] = { codigo = codigo, detalle = detalle, actualizado = os.time(), causa = causa or "local" }
  if codigo == "error" then registrar("arranque", "error", nombres[componente] .. ": " .. detalle)
  else depuracion.texto("arranque", nombres[componente] .. ": " .. detalle) end
  raiseEvent("rhomscripts.estado.cambiado", componente, codigo, detalle)
  return true
end

function depuracion.estado.resumen()
  local lineas = {}
  for _, nombre in ipairs(orden) do
    local entrada = estados[nombre]
    lineas[#lineas + 1] = nombres[nombre] .. ": " .. (entrada and entrada.detalle or "sin comprobar") .. "."
  end
  for _, aviso in ipairs(avisos) do lineas[#lineas + 1] = "Aviso de " .. aviso.modulo .. ": " .. aviso.detalle end
  return table.concat(lineas, "\n")
end

function depuracion.estado.mostrar()
  local texto = depuracion.estado.resumen()
  echo(texto .. "\n")
  announce(texto)
  return texto
end

function depuracion.planificar(definiciones)
  for _, entrada in ipairs(definiciones) do
    assert(not modulos[entrada.nombre], "Módulo de carga duplicado: " .. entrada.nombre)
    modulos[entrada.nombre] = { modulo = entrada.nombre, nombre = entrada.nombre,
      tipo = entrada.tipo or "soporte", dependencias = entrada.dependencias or {}, estado = "pendiente" }
  end
end

function depuracion.modulo(nombre, estado, error_carga)
  local entrada = assert(modulos[nombre], "Módulo no planificado: " .. nombre)
  entrada.estado, entrada.error = estado, error_carga
  entrada.actualizado = os.time()
  local texto = estado .. (error_carga and (": " .. tostring(error_carga)) or "")
  if estado == "error" then registrar(nombre, "error", texto)
  else depuracion.texto(nombre, texto) end
end

function depuracion.proveedor(tipo, consulta)
  assert(type(consulta) == "function", "La consulta del inventario debe ser una función")
  proveedores[tipo] = consulta
end

function depuracion.formato_catalogo(resumen)
  if resumen.estado == "ausente" then
    return "Carpeta de sonidos de RhomScripts ausente. Audio no disponible."
  elseif resumen.estado == "invalido" then
    return "No se pudo construir el catálogo de sonidos de RhomScripts. " .. resumen.incidencias[1]
  elseif resumen.estado == "parcial" then
    return string.format("Catálogo de sonidos parcial: %d de %d claves disponibles. %d archivos correctos y %d erróneos. %d incidencias.",
      resumen.claves_disponibles, resumen.claves_total, resumen.archivos_correctos,
      resumen.archivos_erroneos, #resumen.incidencias)
  end
  return string.format("Catálogo de sonidos de RhomScripts: %d claves y %d archivos verificados. Sin incidencias.",
    resumen.claves_disponibles, resumen.archivos_correctos)
end

function depuracion.catalogo(resumen)
  depuracion.texto("sonidos", resumen.mensaje)
  if resumen.estado ~= "cargado" then
    depuracion.aviso("sonidos", "catalogo", resumen.mensaje)
  end
end

function depuracion.consultar(tipo, filtro)
  local lista = {}
  if tipo == "mensajes" then
    for indice = 0, cantidad - 1 do lista[#lista + 1] = copiar(historial[((primero + indice - 1) % limite) + 1]) end
  elseif tipo == "modulos" then
    for _, entrada in pairs(modulos) do lista[#lista + 1] = copiar(entrada) end
  elseif tipo == "estado" then
    for _, entrada in pairs(modulos) do lista[#lista + 1] = copiar(entrada) end
    for _, nombre in ipairs(orden) do
      local entrada = copiar(estados[nombre]) or { codigo = "pendiente", detalle = "sin comprobar" }
      entrada.modulo, entrada.componente, entrada.nombre = "arranque", nombre, nombres[nombre]
      lista[#lista + 1] = entrada
    end
    for _, aviso in ipairs(avisos) do lista[#lista + 1] = copiar(aviso) end
  elseif proveedores[tipo] then
    lista = copiar(proveedores[tipo]())
  else
    assert(tipo == "keys" or tipo == "alias" or tipo == "triggers" or tipo == "sonidos",
      "Consulta desconocida: " .. tostring(tipo))
  end
  if tipo ~= "mensajes" then ordenar(lista) end
  if not filtro or filtro == "" then return lista end
  local filtrados = {}
  for _, entrada in ipairs(lista) do
    if entrada.modulo == filtro or entrada.grupo == filtro or entrada.componente == filtro then
      filtrados[#filtrados + 1] = entrada
    end
  end
  return filtrados
end

local campos = { { "descripcion", "Descripción" }, { "uso", "Uso" }, { "grupo", "Grupo" },
  { "combinacion", "Combinación" }, { "tecla", "Código efectivo" }, { "modificadores", "Modificadores" },
  { "patron", "Patrón PCRE" }, { "accion", "Acción" }, { "id", "Identificador" },
  { "tipo", "Tipo" }, { "estado", "Estado" }, { "codigo", "Código" }, { "detalle", "Detalle" },
  { "archivo", "Archivo" }, { "error", "Error" }, { "causa", "Causa" },
  { "actualizado", "Instante" }, { "texto", "Mensaje" } }

function depuracion.mostrar(tipo, filtro)
  if tipo == "version" then
    local texto = "RhomScripts · Versión " .. depuracion.version()
    echo(texto .. "\n")
    announce(texto)
    return texto
  end
  if tipo == "estado" and not filtro then return depuracion.estado.mostrar() end
  local lista = depuracion.consultar(tipo, filtro)
  local lineas = { "RhomScripts · " .. tipo .. ": " .. #lista .. " entradas." }
  if tipo == "modulos" then
    local correctos, errores, pendientes = 0, 0, 0
    for _, entrada in ipairs(lista) do
      if entrada.estado == "cargado" then correctos = correctos + 1
      elseif entrada.estado == "error" then errores = errores + 1
      else pendientes = pendientes + 1 end
    end
    lineas[#lineas + 1] = string.format("%d módulos cargados correctamente, %d con errores, %d pendientes o en proceso.",
      correctos, errores, pendientes)
  end
  local modulo
  for _, entrada in ipairs(lista) do
    if entrada.modulo ~= modulo then
      modulo = entrada.modulo
      lineas[#lineas + 1] = "\nMódulo: " .. modulo .. "."
    end
    lineas[#lineas + 1] = "\n" .. (entrada.nombre or entrada.componente or entrada.codigo or "Entrada") .. ":"
    for _, campo in ipairs(campos) do
      if entrada[campo[1]] ~= nil then lineas[#lineas + 1] = campo[2] .. ": " .. tostring(entrada[campo[1]]) end
    end
    if entrada.dependencias then lineas[#lineas + 1] = "Dependencias: " .. table.concat(entrada.dependencias, ", ") end
  end
  local texto = table.concat(lineas, "\n")
  echo(texto .. "\n")
  return texto
end

local function ayuda()
  local texto = "RhomScripts · Debug " .. (depuracion.activo() and "activado" or "desactivado")
    .. ". Modo compartido con los scripts oficiales.\n"
    .. "Consultas: rhomscripts estado, modulos, keys, alias, triggers, sonidos, mensajes o version.\n"
    .. "Añada un módulo como filtro; sonidos permite un grupo. Historial: últimos 500 mensajes de esta carga."
  echo(texto .. "\n")
  return texto
end

local tipos = { estado = true, modulos = true, keys = true, alias = true, version = true,
  triggers = true, sonidos = true, mensajes = true }
depuracion.aliases = {{ name = "rhomscripts", pattern = "(?i)^rhomscripts(?:[ \\t]+(.*?))?[ \\t]*$",
  desc = "Consulta el diagnóstico y la versión; admite tipo y filtro por módulo", uso = "rhomscripts [tipo] [modulo]",
  action = function()
    local argumentos = matches[2] or ""
    local tipo, filtro = argumentos:match("^(%S+)%s*(.-)%s*$")
    if tipo then tipo = tipo:lower() end
    if not tipo or not tipos[tipo] then return ayuda() end
    return depuracion.mostrar(tipo, filtro ~= "" and filtro or nil)
  end }}
return depuracion
