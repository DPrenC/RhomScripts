-- Registro central de pulsaciones. Véase rhomscripts/doc/teclado.md.
local keys = {}
local registros = {}
local ayuda = false

keys.aliases = {{
  pattern = "^listkeys$", action = function() keys.listar_teclas() end,
  name = "listkeys", desc = "Lista las pulsaciones registradas"
}}

function keys.ayuda_activa() return ayuda end

function keys.establecer_ayuda(activa)
  assert(type(activa) == "boolean", "El estado de ayuda debe ser booleano")
  ayuda = activa
  announce(activa and "Ayuda de teclado activada." or "Ayuda de teclado desactivada.")
  return ayuda
end

function keys.alternar_ayuda() return keys.establecer_ayuda(not ayuda) end

keys.pulsaciones = {{
  combinacion = { tecla = mudlet.key.H,
    modificadores = { mudlet.keymodifier.Control, mudlet.keymodifier.Shift } },
  nombre = "keys.alternar_ayuda", funcion = keys.alternar_ayuda,
  descripcion = "Activa o desactiva la ayuda de teclado", grupo = "sistema"
}}

local function texto(valor)
  return type(valor) == "string" and valor:find("%S") ~= nil
end

local function lista(valor)
  assert(type(valor) == "table", "Se esperaba una lista")
  local longitud = #valor
  for indice in pairs(valor) do
    assert(type(indice) == "number" and indice % 1 == 0 and indice >= 1 and indice <= longitud,
      "La lista debe ser consecutiva")
  end
end

local function normalizar(modulo, entrada)
  assert(type(entrada) == "table", "Pulsación inválida en " .. modulo)
  assert(texto(entrada.nombre), "Falta nombre de función en " .. modulo)
  assert(type(entrada.funcion) == "function", "Función inválida: " .. entrada.nombre)
  assert(texto(entrada.descripcion), "Falta descripción: " .. entrada.nombre)
  assert(texto(entrada.grupo), "Falta grupo: " .. entrada.nombre)
  local combinacion = entrada.combinacion
  assert(type(combinacion) == "table", "Combinación inválida: " .. entrada.nombre)
  local tecla = combinacion.tecla
  local nombre_tecla
  for nombre, codigo in pairs(mudlet.key) do
    if codigo == tecla and (not nombre_tecla or nombre < nombre_tecla) then nombre_tecla = nombre end
  end
  assert(nombre_tecla, "Código de tecla desconocido: " .. entrada.nombre)
  local modificadores = combinacion.modificadores or {}
  lista(modificadores)
  assert(#modificadores <= 2, "Se admiten como máximo dos modificadores")
  local permitidos = {
    { mudlet.keymodifier.Control, "Ctrl" }, { mudlet.keymodifier.Alt, "Alt" },
    { mudlet.keymodifier.Shift, "Shift" }, { mudlet.keymodifier.Meta, "Meta" },
    { mudlet.keymodifier.Keypad, "Keypad" }, { mudlet.keymodifier.GroupSwitch, "GroupSwitch" }
  }
  local vistos, etiquetas, suma = {}, {}, 0
  for _, modificador in ipairs(modificadores) do
    local valido = false
    for _, permitido in ipairs(permitidos) do
      if modificador == permitido[1] then valido = true end
    end
    assert(valido and not vistos[modificador], "Modificador inválido o repetido: " .. entrada.nombre)
    vistos[modificador] = true
    suma = suma + modificador
  end
  for _, permitido in ipairs(permitidos) do
    if vistos[permitido[1]] then etiquetas[#etiquetas + 1] = permitido[2] end
  end
  assert(tecla ~= mudlet.key.Escape or suma ~= 0, "Escape sin modificadores está reservado por Mudlet")
  etiquetas[#etiquetas + 1] = nombre_tecla
  -- Qt entrega el símbolo de Mayús, no el dígito, en el teclado español
  -- de España. Mantener la combinación declarada para ayuda y listkeys.
  if vistos[mudlet.keymodifier.Control] and vistos[mudlet.keymodifier.Shift] then
    local numeros_es = {
      [mudlet.key["1"]] = mudlet.key.Exclam,
      [mudlet.key["2"]] = mudlet.key.QuoteDbl,
      [mudlet.key["3"]] = mudlet.key.periodcentered,
      [mudlet.key["4"]] = mudlet.key.Dollar,
      [mudlet.key["5"]] = mudlet.key.Percent,
      [mudlet.key["6"]] = mudlet.key.Ampersand,
      [mudlet.key["7"]] = mudlet.key.Slash,
      [mudlet.key["8"]] = mudlet.key.ParenLeft,
      [mudlet.key["9"]] = mudlet.key.ParenRight,
    }
    tecla = numeros_es[tecla] or tecla
  end
  return { modulo = modulo, nombre = entrada.nombre, funcion = entrada.funcion,
    descripcion = entrada.descripcion, grupo = entrada.grupo, tecla = tecla, modificadores = suma,
    combinacion = table.concat(etiquetas, "+"), firma = tostring(suma) .. ":" .. tostring(tecla),
    control_ayuda = modulo == "keys" and entrada.funcion == keys.alternar_ayuda }
end

local function preparar(items, existentes)
  local nombres, firmas, preparados = {}, {}, {}
  for _, registro in ipairs(existentes) do
    nombres[registro.nombre], firmas[registro.firma] = true, true
  end
  for _, item in ipairs(items) do
    local registro = normalizar(item.module, item.binding)
    assert(not nombres[registro.nombre], "Nombre de función duplicado: " .. registro.nombre)
    assert(not firmas[registro.firma], "Combinación duplicada: " .. registro.combinacion)
    nombres[registro.nombre], firmas[registro.firma] = true, true
    preparados[#preparados + 1] = registro
  end
  return preparados
end

local function instalar(preparados)
  local inicio = #registros
  local ok, mensaje = pcall(function()
    for _, registro in ipairs(preparados) do
      local function ejecutar()
        if ayuda and not registro.control_ayuda then
          announce(registro.descripcion)
        else
          return registro.funcion()
        end
      end
      local id
      if registro.modificadores == 0 then
        id = tempKey(registro.tecla, ejecutar)
      else
        id = tempKey(registro.modificadores, registro.tecla, ejecutar)
      end
      assert(type(id) == "number" and id > 0, "Mudlet no registró " .. registro.nombre)
      registro.id = id
      registros[#registros + 1] = registro
    end
  end)
  if not ok then
    local limpio, error_limpieza = pcall(function()
      while #registros > inicio do
        local registro = registros[#registros]
        assert(killKey(registro.id), "No se pudo retirar " .. registro.nombre)
        registros[#registros] = nil
      end
    end)
    if not limpio then
      error(tostring(mensaje) .. "\nError adicional al retirar pulsaciones: " .. tostring(error_limpieza), 0)
    end
    error(mensaje, 0)
  end
  return { success = #preparados, errors = 0, total = #preparados }
end

-- Declaración por módulo: solo se lee pulsaciones; key_bindings queda sin registrar.
function keys.descubrir_teclas()
  local encontrados, nombres = {}, {}
  assert(RhomScripts and RhomScripts.modules, "No hay módulos cargados")
  for nombre in pairs(RhomScripts.modules) do nombres[#nombres + 1] = nombre end
  table.sort(nombres)
  for _, nombre in ipairs(nombres) do
    local pulsaciones = RhomScripts.modules[nombre].pulsaciones
    if pulsaciones ~= nil then
      lista(pulsaciones)
      for _, entrada in ipairs(pulsaciones) do
        encontrados[#encontrados + 1] = { module = nombre, binding = entrada }
      end
    end
  end
  return encontrados
end

function keys.registrar_modulo(modulo, pulsaciones)
  assert(texto(modulo), "Nombre de módulo inválido")
  lista(pulsaciones)
  local items = {}
  for _, entrada in ipairs(pulsaciones) do items[#items + 1] = { module = modulo, binding = entrada } end
  return instalar(preparar(items, registros))
end

function keys.desregistrar()
  -- Retirar del final: ante error se conservan los identificadores aún pendientes.
  while #registros > 0 do
    local registro = registros[#registros]
    assert(killKey(registro.id), "No se pudo retirar " .. registro.nombre)
    registros[#registros] = nil
  end
  ayuda = false
end

function keys.registrar()
  local preparados = preparar(keys.descubrir_teclas(), {})
  keys.desregistrar()
  return instalar(preparados)
end

function keys.listar_teclas()
  print("Pulsaciones registradas: " .. #registros)
  for _, registro in ipairs(registros) do
    print(registro.combinacion .. ": " .. registro.descripcion .. ". Función: " .. registro.nombre
      .. ". Grupo: " .. registro.grupo .. ". Módulo: " .. registro.modulo)
  end
end

return keys
