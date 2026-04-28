-------------------------------------------------------------------------------
-- Modulo: listas
-- Migracion funcional desde Listas.set.
--
-- Gestiona listas navegables reutilizables: tiendas, baules, mochilas,
-- embarcaciones y cualquier otro modulo que quiera publicar informacion
-- seleccionable para lector de pantalla.
-------------------------------------------------------------------------------

local audio = require("audio")
local lector = require("lector")

local listas = {}

listas.activa = nil
listas.datos = {}

local tipos = {
  tienda = "Tienda",
  baul = "Baul",
  mochila = "Mochila",
  embarcaciones = "Embarcaciones",
  generica = "Generica",
}

local function trim(text)
  if type(text) ~= "string" then
    return ""
  end
  return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function current()
  if not listas.activa then
    return nil
  end
  return listas.datos[listas.activa]
end

local function speak(text)
  lector.decir(text)
end

local function ensure(tipo)
  local key = tipo or tipos.generica
  if not listas.datos[key] then
    listas.datos[key] = {
      tipo = key,
      items = {},
      index = 0,
    }
  end
  listas.activa = key
  return listas.datos[key]
end

function listas.nueva(tipo)
  local lista = ensure(tipo)
  lista.items = {}
  lista.index = 0
  audio.lista()
  speak("Lista " .. lista.tipo)
  return lista
end

function listas.limpiar(tipo)
  if tipo then
    listas.datos[tipo] = nil
    if listas.activa == tipo then
      listas.activa = nil
    end
    return
  end

  listas.datos = {}
  listas.activa = nil
end

function listas.agregar(tipo, texto, accion)
  local lista = ensure(tipo)
  local item = {
    texto = trim(texto),
    accion = accion,
  }
  if item.texto == "" then
    return nil
  end

  table.insert(lista.items, item)
  if lista.index == 0 then
    lista.index = 1
  end
  return item
end

function listas.seleccion()
  local lista = current()
  if not lista or #lista.items == 0 or lista.index == 0 then
    return nil
  end
  return lista.items[lista.index], lista
end

function listas.leer_actual()
  local item, lista = listas.seleccion()
  if not item then
    speak("No hay ninguna lista disponible")
    return nil
  end

  speak(string.format("%d de %d. %s", lista.index, #lista.items, item.texto))
  return item
end

function listas.mover(delta)
  local lista = current()
  if not lista or #lista.items == 0 then
    speak("No hay ninguna lista disponible")
    return nil
  end

  lista.index = lista.index + delta
  if lista.index < 1 then
    lista.index = #lista.items
  elseif lista.index > #lista.items then
    lista.index = 1
  end

  return listas.leer_actual()
end

function listas.siguiente()
  return listas.mover(1)
end

function listas.anterior()
  return listas.mover(-1)
end

function listas.ejecutar_actual()
  local item = listas.seleccion()
  if not item then
    speak("No hay ningun elemento seleccionado")
    return
  end

  if type(item.accion) == "function" then
    item.accion(item)
  elseif type(item.accion) == "string" and item.accion ~= "" then
    send(item.accion)
  else
    speak(item.texto)
  end
end

function listas.copiar_actual()
  local item = listas.seleccion()
  if not item then
    speak("No hay ningun elemento seleccionado")
    return
  end
  lector.copiar(item.texto, "Elemento copiado")
end

local function accion_tienda(item_id)
  return function(item)
    local cantidad = item.cantidad or 1
    if cantidad > 1 then
      send("comprar 1 # " .. item_id)
    else
      send("comprar # " .. item_id)
    end
  end
end

local function agregar_tienda(id, objeto, cantidad_texto, precio)
  local cantidad = tonumber(cantidad_texto) or 1
  local texto = string.format(
    "%s. %s disponibles. Precio aproximado %s. Item numero %s",
    trim(objeto),
    cantidad,
    trim(precio),
    trim(id)
  )
  local item = listas.agregar(tipos.tienda, texto, accion_tienda(trim(id)))
  if item then
    item.cantidad = cantidad
  end
end

local function recuperar_por_id(id)
  return function()
    send("recuperar # " .. trim(id))
  end
end

local function coger_de_mochila(nombre)
  return function()
    send("coger " .. trim(nombre) .. " de mochila")
  end
end

local function agregar_baul(id, nombre)
  listas.agregar(tipos.baul, trim(nombre) .. ". Item " .. trim(id), recuperar_por_id(id))
end

local function agregar_mochila(nombre)
  listas.agregar(tipos.mochila, trim(nombre), coger_de_mochila(nombre))
end

local function agregar_embarcacion(id, nombre, tipo)
  local texto = trim(nombre) .. " de " .. trim(tipo) .. ". Item " .. trim(id)
  listas.agregar(tipos.embarcaciones, texto, recuperar_por_id(id))
end

listas.triggers = {
  {
    pattern = "^N.  Objeto .* Cantidad .* Precio aproximado",
    action = function()
      listas.nueva(tipos.tienda)
    end,
    name = "lista_tienda_inicio",
    desc = "Detecta el inicio de una lista de tienda"
  },
  {
    pattern = "^\\s*Listado de objetos:",
    action = function()
      listas.nueva(tipos.baul)
    end,
    name = "lista_baul_inicio",
    desc = "Detecta el inicio de una lista de baul"
  },
  {
    pattern = "^Contenidos de .*:",
    action = function()
      listas.nueva(tipos.mochila)
    end,
    name = "lista_mochila_inicio",
    desc = "Detecta el inicio de una lista de contenedor"
  },
  {
    pattern = "^Hay .* embarcaciones amarradas",
    action = function()
      listas.nueva(tipos.embarcaciones)
    end,
    name = "lista_embarcaciones_inicio",
    desc = "Detecta lista de embarcaciones"
  },
  {
    pattern = "^Se encontr.* embarcaci.* amarrada",
    action = function()
      listas.nueva(tipos.embarcaciones)
    end,
    name = "lista_embarcaciones_inicio_2",
    desc = "Detecta lista de embarcaciones"
  },
  {
    pattern = "^\\s*([0-9]+)#\\)\\s+(.+)\\s+([0-9]+)\\s+M\\.(.+)$",
    action = function()
      agregar_tienda(matches[2], matches[3], matches[4], matches[5])
    end,
    name = "lista_tienda_item",
    desc = "Agrega items de tienda a la lista activa"
  },
  {
    pattern = "^Contenido ba.l: Desde .*",
    action = function()
      audio.scroll()
    end,
    name = "lista_baul_scroll",
    desc = "Indica desplazamiento de baul"
  },
  {
    pattern = "^\\s*([0-9]+)#\\)\\s+(.+)$",
    action = function()
      agregar_baul(matches[2], matches[3])
    end,
    name = "lista_baul_item",
    desc = "Agrega item numerado de baul"
  },
  {
    pattern = "^\\s*-\\s+(.+)$",
    action = function()
      agregar_mochila(matches[2])
    end,
    name = "lista_mochila_item",
    desc = "Agrega item de mochila"
  },
  {
    pattern = "^\\s*\\[#\\]([0-9]+)\\s+(.+)\\s+de\\s+(.+)$",
    action = function()
      agregar_embarcacion(matches[2], matches[3], matches[4])
    end,
    name = "lista_embarcacion_item",
    desc = "Agrega embarcacion a la lista activa"
  },
  {
    pattern = "^Lista de embarcaciones amarradas: Desde .*",
    action = function()
      audio.scroll()
    end,
    name = "lista_embarcaciones_scroll",
    desc = "Indica desplazamiento de lista de embarcaciones"
  }
}

listas.key_bindings = {
  {
    key = mudlet.key.Up,
    action = function()
      listas.anterior()
    end,
    name = "Arriba",
    desc = "Selecciona el elemento anterior de la lista activa"
  },
  {
    key = mudlet.key.Down,
    action = function()
      listas.siguiente()
    end,
    name = "Abajo",
    desc = "Selecciona el elemento siguiente de la lista activa"
  },
  {
    key = mudlet.key.Return,
    modifiers = mudlet.keymodifier.Control,
    action = function()
      listas.ejecutar_actual()
    end,
    name = "Ctrl+Enter",
    desc = "Ejecuta la accion del elemento seleccionado"
  },
  {
    key = mudlet.key.L,
    modifiers = mudlet.keymodifier.Control + mudlet.keymodifier.Shift,
    action = function()
      listas.leer_actual()
    end,
    name = "Ctrl+Shift+L",
    desc = "Lee el elemento seleccionado de la lista activa"
  },
  {
    key = mudlet.key.C,
    modifiers = mudlet.keymodifier.Control + mudlet.keymodifier.Shift,
    action = function()
      listas.copiar_actual()
    end,
    name = "Ctrl+Shift+C",
    desc = "Copia el elemento seleccionado de la lista activa"
  }
}

listas.aliases = {
  {
    pattern = "^lista$",
    action = function()
      listas.leer_actual()
    end,
    name = "lista",
    desc = "Lee el elemento seleccionado de la lista activa"
  },
  {
    pattern = "^listasiguiente$",
    action = function()
      listas.siguiente()
    end,
    name = "listasiguiente",
    desc = "Avanza en la lista activa"
  },
  {
    pattern = "^listaanterior$",
    action = function()
      listas.anterior()
    end,
    name = "listaanterior",
    desc = "Retrocede en la lista activa"
  },
  {
    pattern = "^listaaccion$",
    action = function()
      listas.ejecutar_actual()
    end,
    name = "listaaccion",
    desc = "Ejecuta la accion del elemento seleccionado"
  },
  {
    pattern = "^listalimpiar$",
    action = function()
      listas.limpiar()
      speak("Listas limpiadas")
    end,
    name = "listalimpiar",
    desc = "Limpia las listas activas"
  }
}

return listas
