-- Copia de los paquetes de personaje observados durante la sesión GMCP.
local ficha = {}
local datos = {}
local handlers = {}
local ruta_pvs = { "Status", "pvs" }
local ultimo_pvs_gmcp

local rutas = {
  nombre = "Ficha.nombre",
  clase = "Ficha.clase",
  oficio = "Ficha.oficio",
  sexo = "Ficha.genero",
  raza = "Ficha.raza",
  vida_actual = "Status.pvs.min",
  vida_maxima = "Status.pvs.max",
}

local function copiar(valor)
  if type(valor) ~= "table" then return valor end
  local copia = {}
  for clave, campo in pairs(valor) do copia[clave] = copiar(campo) end
  return copia
end

local function segmentos(ruta)
  local campos = {}
  for campo in ruta:gmatch("[^.]+") do campos[#campos + 1] = campo end
  return campos
end

local function leer(tabla, campos)
  for _, campo in ipairs(campos) do
    if type(tabla) ~= "table" then return nil end
    tabla = tabla[campo]
  end
  return tabla
end

function ficha.obtener(ruta)
  local campos = segmentos(rutas[ruta] or ruta)
  if #campos == 0 then return nil end
  return copiar(leer(datos, campos))
end

function ficha.datos()
  return copiar(datos)
end

local function formatear_valor(valor)
  return type(valor) == "number" and tostring(valor) or "sin datos"
end

local function formatear_par(bloque, prefijo)
  local valores = leer(datos, { "Status", bloque })
  if type(valores) ~= "table" then valores = {} end
  return (prefijo or "") .. formatear_valor(valores.min) .. "\\" .. formatear_valor(valores.max)
end

local function unir_pares(primero, segundo)
  return segundo and primero .. ", " .. segundo or primero
end

local function anunciar_pares(primero, segundo)
  announce(unir_pares(primero, segundo), "importantmostrecent")
end

local function copiar_pares(primero, segundo)
  require("lector").copiar(unir_pares(primero, segundo))
end

ficha.pulsaciones = {
  {
    combinacion = { tecla = mudlet.key["1"], modificadores = { mudlet.keymodifier.Alt } },
    nombre = "ficha.verbalizar_vida", funcion = function() anunciar_pares(formatear_par("pvs")) end,
    descripcion = "Verbaliza la vida", grupo = "informacion",
  },
  {
    combinacion = { tecla = mudlet.key["2"], modificadores = { mudlet.keymodifier.Alt } },
    nombre = "ficha.verbalizar_energia_y_escudo",
    funcion = function() anunciar_pares(formatear_par("pe"), formatear_par("escudo")) end,
    descripcion = "Verbaliza la energía y el escudo", grupo = "informacion",
  },
  {
    combinacion = { tecla = mudlet.key["0"], modificadores = { mudlet.keymodifier.Alt } },
    nombre = "ficha.verbalizar_xp_y_oficio",
    funcion = function()
      anunciar_pares(formatear_par("xp", "xp: "), formatear_par("xp_oficio", "puntos de oficio: "))
    end,
    descripcion = "Verbaliza la experiencia y los puntos de oficio", grupo = "informacion",
  },
  {
    combinacion = { tecla = mudlet.key["1"], modificadores = { mudlet.keymodifier.Alt, mudlet.keymodifier.Shift } },
    nombre = "ficha.copiar_vida", funcion = function() copiar_pares(formatear_par("pvs", "pvs: ")) end,
    descripcion = "Copia la vida", grupo = "informacion",
  },
  {
    combinacion = { tecla = mudlet.key["2"], modificadores = { mudlet.keymodifier.Alt, mudlet.keymodifier.Shift } },
    nombre = "ficha.copiar_energia_y_escudos",
    funcion = function()
      copiar_pares(formatear_par("pe", "energía: "), formatear_par("escudo", "escudos: "))
    end,
    descripcion = "Copia la energía y los escudos", grupo = "informacion",
  },
  {
    combinacion = { tecla = mudlet.key["0"], modificadores = { mudlet.keymodifier.Alt, mudlet.keymodifier.Shift } },
    nombre = "ficha.copiar_xp_y_oficio",
    funcion = function()
      copiar_pares(formatear_par("xp", "xp: "), formatear_par("xp_oficio", "puntos de oficio: "))
    end,
    descripcion = "Copia la experiencia y los puntos de oficio", grupo = "informacion",
  },
}

local function completar_pvs(combinado, anterior)
  if type(combinado) == "table" and type(anterior) == "table" then
    if combinado.min == nil then combinado.min = anterior.min end
    if combinado.max == nil then combinado.max = anterior.max end
  end
  return combinado
end

local function recibir(_, paquete)
  if type(paquete) ~= "string" then return end
  local rama = gmcp and gmcp.Char
  if type(rama) ~= "table" then return end
  if paquete == "gmcp.Char" then
    datos = copiar(rama)
    ultimo_pvs_gmcp = leer(rama, ruta_pvs)
    return
  end
  local ruta = paquete:match("^gmcp%.Char%.(.+)$")
  if not ruta then return end
  local campos = segmentos(ruta)
  if #campos == 0 then return end
  local valor = leer(rama, campos)
  local copia = copiar(valor)
  if ruta == "Status" then
    local pvs = leer(rama, ruta_pvs)
    if type(copia) == "table" then
      local anterior = leer(datos, ruta_pvs)
      -- Mudlet conserva la misma subtabla cuando el paquete solo actualiza otros bloques.
      if pvs == nil or pvs == ultimo_pvs_gmcp then
        copia.pvs = anterior
      else
        copia.pvs = completar_pvs(copia.pvs, anterior)
      end
    end
    ultimo_pvs_gmcp = pvs
  elseif ruta == "Status.pvs" then
    copia = completar_pvs(copia, leer(datos, ruta_pvs))
    ultimo_pvs_gmcp = valor
  end
  local destino = datos
  for i = 1, #campos - 1 do
    local campo = campos[i]
    if type(destino[campo]) ~= "table" then destino[campo] = {} end
    destino = destino[campo]
  end
  destino[campos[#campos]] = copia
end

local function vaciar()
  datos = {}
  ultimo_pvs_gmcp = leer(gmcp and gmcp.Char, ruta_pvs)
end

function ficha.iniciar(datos_previos)
  if #handlers > 0 then return end
  datos = datos_previos and copiar(datos_previos) or {}
  ultimo_pvs_gmcp = leer(gmcp and gmcp.Char, ruta_pvs)
  local function escuchar(evento, accion)
    handlers[#handlers + 1] = registerAnonymousEventHandler(evento, accion)
  end
  escuchar("gmcp.Char", recibir)
  escuchar("sysConnectionEvent", vaciar)
  escuchar("sysDisconnectionEvent", vaciar)
  escuchar("gmcp.Core.Goodbye", vaciar)
  escuchar("sysProtocolDisabled", function(_, protocolo)
    if protocolo == "GMCP" then vaciar() end
  end)
end

function ficha.detener()
  vaciar()
  for _, id in ipairs(handlers) do killAnonymousEventHandler(id) end
  handlers = {}
end

return ficha
