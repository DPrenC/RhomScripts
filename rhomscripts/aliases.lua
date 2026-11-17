-- Registro incremental de comandos; sus informes pertenecen al módulo debug.
local aliases = {}
local registros = {}

local function texto(valor)
  return type(valor) == "string" and valor:find("%S") ~= nil
end

local function copia(registro)
  return { modulo = registro.modulo, nombre = registro.nombre,
    descripcion = registro.descripcion, patron = registro.patron, uso = registro.uso,
    accion = registro.accion, id = registro.id, estado = "registrado" }
end

function aliases.consultar()
  local resultado = {}
  for _, registro in ipairs(registros) do resultado[#resultado + 1] = copia(registro) end
  return resultado
end

-- El identificador solo se retira del inventario después de confirmar su baja.
function aliases.desregistrar(modulo)
  local errores = {}
  for indice = #registros, 1, -1 do
    local registro = registros[indice]
    if modulo == nil or registro.modulo == modulo then
      local correcto, mensaje = pcall(function()
        assert(killAlias(registro.id), "No se pudo retirar el alias " .. registro.nombre)
      end)
      if correcto then table.remove(registros, indice)
      else errores[#errores + 1] = tostring(mensaje) end
    end
  end
  if #errores > 0 then error(table.concat(errores, "\n"), 0) end
end

function aliases.registrar_modulo(modulo, definiciones)
  assert(texto(modulo), "Nombre de módulo de aliases inválido")
  assert(type(definiciones) == "table", "Se esperaba una lista de aliases")
  local preparados, nombres, patrones = {}, {}, {}
  for _, registro in ipairs(registros) do
    nombres[registro.nombre], patrones[registro.patron] = registro, registro
  end
  for _, entrada in ipairs(definiciones) do
    assert(type(entrada) == "table" and texto(entrada.name), "Alias sin nombre en " .. modulo)
    assert(texto(entrada.pattern), "Alias sin patrón: " .. entrada.name)
    assert(type(entrada.action) == "function", "Alias sin acción: " .. entrada.name)
    assert(texto(entrada.desc), "Alias sin descripción: " .. entrada.name)
    local anterior = nombres[entrada.name]
    if anterior then
      assert(anterior.modulo == modulo and anterior.patron == entrada.pattern
        and anterior.funcion == entrada.action, "Alias duplicado: " .. entrada.name)
    else
      assert(not patrones[entrada.pattern], "Patrón de alias duplicado: " .. entrada.name)
      local registro = { modulo = modulo, nombre = entrada.name, descripcion = entrada.desc,
        patron = entrada.pattern, uso = entrada.uso or entrada.name,
        accion = entrada.accion or (modulo .. "." .. entrada.name), funcion = entrada.action }
      preparados[#preparados + 1] = registro
      nombres[registro.nombre], patrones[registro.patron] = registro, registro
    end
  end
  local inicio = #registros
  local correcto, mensaje = pcall(function()
    for _, registro in ipairs(preparados) do
      local id = tempAlias(registro.patron, registro.funcion)
      assert(type(id) == "number" and id > 0, "Mudlet no registró el alias " .. registro.nombre)
      registro.id = id
      registros[#registros + 1] = registro
    end
  end)
  if not correcto then
    local errores = { tostring(mensaje) }
    for indice = #registros, inicio + 1, -1 do
      local registro = registros[indice]
      local limpio, fallo = pcall(function()
        assert(killAlias(registro.id), "No se pudo retirar el alias " .. registro.nombre)
      end)
      if limpio then table.remove(registros, indice)
      else errores[#errores + 1] = tostring(fallo) end
    end
    error(table.concat(errores, "\n"), 0)
  end
  return { success = #preparados, errors = 0, total = #preparados }
end

function aliases.descubrir_aliases()
  assert(RhomScripts and RhomScripts.modules, "No hay módulos cargados")
  local nombres, encontrados = {}, {}
  for nombre in pairs(RhomScripts.modules) do nombres[#nombres + 1] = nombre end
  table.sort(nombres)
  for _, nombre in ipairs(nombres) do
    local definiciones = RhomScripts.modules[nombre].aliases
    if definiciones ~= nil then
      assert(type(definiciones) == "table", "Aliases inválidos en " .. nombre)
      for _, entrada in ipairs(definiciones) do
        encontrados[#encontrados + 1] = { module = nombre, alias = entrada }
      end
    end
  end
  return encontrados
end

-- Incorporar los módulos tardíos no sustituye los comandos tempranos de debug.
function aliases.registrar()
  local por_modulo, orden = {}, {}
  for _, encontrado in ipairs(aliases.descubrir_aliases()) do
    local nombre = encontrado.module
    if not por_modulo[nombre] then
      por_modulo[nombre] = {}
      orden[#orden + 1] = nombre
    end
    por_modulo[nombre][#por_modulo[nombre] + 1] = encontrado.alias
  end
  for _, nombre in ipairs(orden) do aliases.registrar_modulo(nombre, por_modulo[nombre]) end
  return { success = #registros, errors = 0, total = #registros }
end

function aliases.listar_aliases()
  return RhomScripts.modules.debug.mostrar("alias")
end

return aliases
