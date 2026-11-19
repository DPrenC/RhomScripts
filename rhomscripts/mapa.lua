-- Destinos del mapa: presentación nativa sobre búsqueda y viajes oficiales.
-- luacheck: globals RL_mostrar_links_viaje_room RL_buscar_salas RL_dame_string_salidas RL_ordenar_salidas RL_speed_walk_to RL_speed_walk_sigilar_to getRoomName
local ui = require("ui")
local configuracion = require("configuracion")
local audio = require("audio")
local ficha = require("ficha")
local mapa = {}
local resultados, favoritos = {}, {}
local personaje
local selecciones, pestana = { 1, 1 }, 1
local original, adaptador, timer, pendiente, viaje
local handlers, iniciada, retirada = {}, false, false
local nombres = { "Resultados", "Favoritos" }
local criterio_actual = ""
local refrescar
local filas_cache = {}
local datos_renderizados, nombre_lista, texto_estado
local sonidos = { abrir = "abrir_mapa", cerrar = "plegar", seleccionar = "seleccionar_mapa",
  limite = "limite",
  error = "error" }
local function sonido(evento)
  audio.reproducir("ui." .. assert(sonidos[evento], "Evento sonoro del mapa desconocido"))
end
local function identidad(destino) return destino.id .. ":" .. tostring(destino.sigilar) end

local function copiar(destino)
  return { id = destino.id, nombre = destino.nombre, salidas = destino.salidas, sigilar = destino.sigilar }
end

local function conjunto()
  return pestana == 1 and resultados or favoritos
end

local function descomponer(nombre, id)
  local corto, salidas = nombre:match("^(.*)%s(%[.*%])$")
  if corto then return corto, salidas end
  return nombre, RL_dame_string_salidas(id, true)
end

local function etiqueta(destino)
  return destino.nombre .. " " .. destino.salidas .. ". Sala " .. destino.id
    .. (destino.sigilar and ". Viaje sigiloso" or "")
end

function mapa.path()
  return getMudletHomeDir() .. "/destinos_favoritos.json"
end

local function validar_lista(destinos)
  assert(type(destinos) == "table", "Lista de favoritos inválida")
  local lista, vistos, cantidad = {}, {}, 0
  for indice, destino in pairs(destinos) do
    assert(type(indice) == "number" and indice >= 1 and indice % 1 == 0
      and type(destino) == "table" and type(destino.id) == "number" and destino.id > 0
      and destino.id < math.huge and destino.id % 1 == 0
      and type(destino.nombre) == "string" and destino.nombre:find("%S")
      and type(destino.salidas) == "string" and type(destino.sigilar) == "boolean",
      "Destino favorito inválido")
    local clave = identidad(destino)
    assert(not vistos[clave], "Destino favorito duplicado")
    vistos[clave], cantidad = true, cantidad + 1
    lista[indice] = copiar(destino)
  end
  for i = 1, cantidad do assert(lista[i], "La lista de favoritos debe ser consecutiva") end
  return lista
end

local function nombre_personaje()
  local nombre = ficha.obtener("nombre")
  if type(nombre) == "string" and nombre:find("%S") then return nombre end
end

local function leer_documento()
  local ruta = mapa.path()
  if not lfs.attributes(ruta, "mode") and lfs.attributes(ruta .. ".bak", "mode") == "file" then
    local restaurado, error_restauracion = os.rename(ruta .. ".bak", ruta)
    assert(restaurado, "No se pudo recuperar el respaldo de favoritos: " .. tostring(error_restauracion))
  end
  local archivo, mensaje, codigo = io.open(mapa.path(), "rb")
  if not archivo then
    assert(codigo == 2, "No se pudieron leer los destinos favoritos: " .. tostring(mensaje))
    return { version = 2, personajes = {} }
  end
  local contenido, error_lectura = archivo:read("*a")
  local cerrado, error_cierre = archivo:close()
  assert(contenido and cerrado, error_lectura or error_cierre)
  local datos = yajl.to_value(contenido)
  assert(type(datos) == "table", "Formato incorrecto en destinos_favoritos.json")
  if datos.version == 1 then
    validar_lista(datos.destinos)
    -- El usuario ha autorizado vaciar el formato antiguo sin propietario.
    return { version = 2, personajes = {} }, true
  end
  assert(datos.version == 2 and type(datos.personajes) == "table",
    "Formato incorrecto en destinos_favoritos.json")
  local personajes = {}
  for nombre, destinos in pairs(datos.personajes) do
    assert(type(nombre) == "string" and nombre:find("%S"), "Nombre de personaje inválido")
    personajes[nombre] = validar_lista(destinos)
  end
  return { version = 2, personajes = personajes }
end

local function guardar_documento(datos)
  local ruta, temporal, respaldo = mapa.path(), mapa.path() .. ".tmp", mapa.path() .. ".bak"
  local contenido = yajl.to_string(datos)
  local archivo, mensaje = io.open(temporal, "wb")
  assert(archivo, "No se pudieron guardar los favoritos: " .. tostring(mensaje))
  local escrito, error_escritura = archivo:write(contenido .. "\n")
  local cerrado, error_cierre = archivo:close()
  assert(escrito and cerrado, "No se pudieron guardar los favoritos: " .. tostring(error_escritura or error_cierre))
  local existe = lfs.attributes(ruta, "mode") == "file"
  if existe then
    assert(not lfs.attributes(respaldo, "mode"), "Existe un respaldo pendiente de favoritos; revise destinos_favoritos.json.bak")
    local movido, error_movimiento = os.rename(ruta, respaldo)
    assert(movido, "No se pudo conservar el archivo de favoritos: " .. tostring(error_movimiento))
  end
  local movido, error_movimiento = os.rename(temporal, ruta)
  if not movido then
    if existe then
      local restaurado, error_restauracion = os.rename(respaldo, ruta)
      assert(restaurado, "No se pudo restaurar el archivo de favoritos: " .. tostring(error_restauracion))
    end
    error("No se pudieron guardar los favoritos: " .. tostring(error_movimiento), 0)
  end
  if existe then
    local eliminado, error_eliminacion = os.remove(respaldo)
    if not eliminado then
      -- Volver al archivo anterior sin borrar ninguna de las dos versiones.
      local apartado, error_apartado = os.rename(ruta, temporal)
      if not apartado then
        favoritos = (personaje and datos.personajes[personaje]) or {} -- El archivo publicado continúa siendo el nuevo.
        error("Favoritos guardados; respaldo pendiente y no se pudo revertir: " .. tostring(error_apartado), 0)
      end
      local restaurado, error_restauracion = os.rename(respaldo, ruta)
      if not restaurado then
        local repuesto, error_reposicion = os.rename(temporal, ruta)
        if repuesto then favoritos = (personaje and datos.personajes[personaje]) or {} end
        error("No se pudo restaurar el respaldo: " .. tostring(error_restauracion)
          .. (repuesto and ". El archivo nuevo sigue publicado." or ". Nuevos datos en .tmp: " .. tostring(error_reposicion)), 0)
      end
      -- Original y memoria vuelven al estado previo; el temporal puede
      -- conservarse para diagnóstico si tampoco se permite retirarlo.
      os.remove(temporal)
      error("No se pudo retirar el respaldo; se restauraron los favoritos anteriores: " .. tostring(error_eliminacion), 0)
    end
  end
end

local function cargar_favoritos()
  -- Retirar la lista anterior antes de leer datos para otra identidad.
  personaje, favoritos = nombre_personaje(), {}
  if mapa.componente and pestana == 2 then mapa.componente:actualizar({}, { primero = true }) end
  local datos, antiguo = leer_documento()
  if antiguo then guardar_documento(datos) end
  favoritos = (personaje and datos.personajes[personaje]) or {}
end

local function sincronizar_personaje()
  if nombre_personaje() == personaje then return false end
  cargar_favoritos()
  selecciones[2] = 1
  return true
end

local function guardar_favoritos(nuevos)
  assert(personaje and personaje == nombre_personaje(), "No hay un personaje identificado para guardar favoritos")
  local datos = leer_documento()
  datos.personajes[personaje] = validar_lista(nuevos)
  guardar_documento(datos)
  favoritos = nuevos
end

local function indice_favorito(destino)
  for i, favorito in ipairs(favoritos) do if identidad(favorito) == identidad(destino) then return i end end
end

local function persistir_favoritos(nuevos)
  local correcto, mensaje = pcall(guardar_favoritos, nuevos)
  if not correcto then
    announce("No se pudieron guardar los favoritos: " .. tostring(mensaje))
    sonido("error")
    error(mensaje, 0)
  end
end

function mapa.agregar_favorito(destino)
  sincronizar_personaje()
  if not personaje then announce("Todavía no se conoce el nombre del personaje. No se ha guardado el favorito."); return false end
  if indice_favorito(destino) then announce("El destino ya está en favoritos."); return false end
  local nuevos = {}
  for i, favorito in ipairs(favoritos) do nuevos[i] = copiar(favorito) end
  nuevos[#nuevos + 1] = copiar(destino)
  persistir_favoritos(nuevos)
  refrescar()
  announce("Destino añadido a favoritos.")
  return true
end

function mapa.eliminar_favorito(destino)
  sincronizar_personaje()
  if not personaje then return false end
  local indice = indice_favorito(destino)
  if not indice then return false end
  local nuevos = {}
  for i, favorito in ipairs(favoritos) do if i ~= indice then nuevos[#nuevos + 1] = copiar(favorito) end end
  persistir_favoritos(nuevos)
  refrescar(nil, false)
  announce("Eliminado de favoritos.")
  return true
end

refrescar = function(primero, aviso_retirado)
  sincronizar_personaje()
  if not mapa.vista then return end
  local lista, datos = mapa.lista, conjunto()
  local cache = filas_cache[pestana]
  if not cache or cache.datos ~= datos then
    cache = { datos = datos, elementos = {} }
    for i, destino in ipairs(datos) do
      cache.elementos[i] = { id = identidad(destino), textos = { etiqueta(destino) }, datos = destino }
    end
    filas_cache[pestana] = cache
  end
  local id_pestana = pestana == 1 and "resultados" or "favoritos"
  if mapa.componente.pestana ~= id_pestana then mapa.componente:seleccionar_pestana(id_pestana, true) end
  if datos_renderizados ~= datos or primero then
    mapa.componente:actualizar(cache.elementos, { primero = primero, aviso_retirado = aviso_retirado })
    datos_renderizados = datos
  else
    mapa.componente:refrescar_acciones()
  end
  local titulo = "Destinos del mapa: " .. nombres[pestana]
  if mapa.vista.dialogo:GetTitle() ~= titulo then mapa.vista.dialogo:SetTitle(titulo) end
  local descripcion = nombres[pestana] .. ": " .. #datos .. " destinos"
  if #datos == 0 then descripcion = nombres[pestana] .. ": sin destinos" end
  if pestana == 1 and criterio_actual ~= "" then descripcion = descripcion .. ". Búsqueda: " .. criterio_actual end
  if nombre_lista ~= descripcion then lista:SetName(descripcion); nombre_lista = descripcion end
  if texto_estado ~= descripcion then mapa.estado_texto:SetLabel(descripcion); texto_estado = descripcion end
end

local function cancelar_timer()
  if timer then killTimer(timer); timer = nil end
end

local function programar()
  if retirada or not pendiente or timer or ui.ocupada() then return end
  timer = tempTimer(0, function()
    timer = nil
    if retirada or not pendiente or ui.ocupada() then return end
    pendiente = false
    mapa.mostrar()
  end)
end

function mapa.recibir(criterio, sigilar)
  local encontrados = RL_buscar_salas(criterio)
  local nuevos = {}
  for id, nombre in pairs(encontrados) do
    local corto, salidas = descomponer(nombre, id)
    nuevos[#nuevos + 1] = { id = id, nombre = corto, salidas = salidas, sigilar = sigilar == true }
  end
  table.sort(nuevos, function(a, b)
    if a.nombre == b.nombre then return a.id < b.id end
    return a.nombre < b.nombre
  end)
  resultados, selecciones[1], criterio_actual = nuevos, 1, criterio
  if #resultados == 0 then
    pendiente = false
    cancelar_timer()
    refrescar()
    announce("No se encontraron destinos.")
    return
  end
  pestana = 1
  refrescar(true)
  if mapa.vista and mapa.vista.mostrando then return end
  pendiente = true
  programar()
end

function mapa.cambiar_pestana(delta)
  mapa.componente:cambiar_pestana(delta)
end

function mapa.cerrar()
  viaje, pendiente = nil, false
  cancelar_timer()
  if mapa.vista then
    if mapa.vista.mostrando then sonido("cerrar") end
    mapa.vista:ocultar()
  end
end

function mapa.aceptar()
  if viaje then return end
  local elemento = mapa.componente:seleccionado()
  local destino = elemento and elemento.datos
  if not destino then announce("No hay ningún destino seleccionado."); return end
  -- Conservar la acción fuera del bucle modal: no enviar movimientos al cerrar.
  viaje = copiar(destino)
  mapa.vista:ocultar(mapa.vista.wx.wxID_OK)
end

local function viajar(destino)
  local nombre = getRoomName(destino.id)
  if not nombre or nombre == "" then
    announce("El destino ya no existe en el mapa. No se ha iniciado el viaje.")
    return
  end
  local corto, salidas = descomponer(nombre, destino.id)
  local function normalizar_salidas(valor)
    return RL_ordenar_salidas((valor:gsub("[|-]", "")))
  end
  if corto:lower() ~= destino.nombre:lower()
    or normalizar_salidas(salidas) ~= normalizar_salidas(destino.salidas) then
    announce("El destino ha cambiado en el mapa. Vuelva a buscarlo antes de viajar.")
    return
  end
  sonido("seleccionar")
  if destino.sigilar then RL_speed_walk_sigilar_to(destino.id)
  else RL_speed_walk_to(destino.id) end
end

function mapa.mostrar()
  if not configuracion.get("mapa_destinos") then
    announce("La lista de destinos de RhomScripts está desactivada.")
    return
  end
  local vista = assert(mapa.vista, "La lista de destinos no se preparó durante el arranque")
  if vista.mostrando then vista.dialogo:Raise(); return end
  if ui.ocupada() then pendiente = true; return end
  refrescar(true)
  pendiente, viaje = false, nil
  cancelar_timer()
  local correcto, resultado = pcall(function() sonido("abrir"); return vista:mostrar() end)
  local destino = viaje
  viaje = nil
  if not correcto then vista:ocultar(); error(resultado, 0) end
  -- wxDialog también puede aceptar Enter mediante su acción estándar (wxID_OK).
  -- Respetar ese resultado aunque no haya pasado por nuestro CHAR_HOOK.
  if resultado == vista.wx.wxID_OK then
    if not destino then
      local seleccionado = mapa.componente:seleccionado()
      if seleccionado then destino = copiar(seleccionado.datos) end
    end
    if destino and not retirada and configuracion.get("mapa_destinos") then viajar(destino) end
  end
end

function mapa.aplicar_configuracion()
  if configuracion.get("mapa_destinos") then
    if RL_mostrar_links_viaje_room ~= adaptador then
      original = RL_mostrar_links_viaje_room
      -- Asignar una función ausente es un error de integración, nunca un modo alternativo.
      assert(original ~= nil, "El paquete oficial no ha definido RL_mostrar_links_viaje_room")
      RL_mostrar_links_viaje_room = adaptador
    end
  else
    mapa.cerrar()
    if adaptador and RL_mostrar_links_viaje_room == adaptador then RL_mostrar_links_viaje_room = original end
    original = nil
  end
end

function mapa.iniciar()
  assert(not iniciada, "El módulo mapa ya está iniciado")
  iniciada, retirada = true, false
  cargar_favoritos()
  handlers[#handlers + 1] = registerAnonymousEventHandler("rhomscripts.ficha.nombre", function()
    if sincronizar_personaje() then refrescar(true) end
  end)
  adaptador = function(criterio, sigilar) return mapa.recibir(criterio, sigilar) end
  ui.al_cerrar(mapa, programar)
  mapa.aplicar_configuracion()
  -- La inicialización oficial vuelve a definir sus funciones al reinstalarse.
  for _, evento in ipairs({ "rlmud_opciones_inicializadas", "sysInstallPackage" }) do
    handlers[#handlers + 1] = registerAnonymousEventHandler(evento, function(_, nombre)
      if evento ~= "sysInstallPackage" or nombre == "RLMud_Config" then mapa.aplicar_configuracion() end
    end)
  end
end

function mapa.preparar()
  if mapa.vista then return end
  local vista = ui.nueva("Destinos del mapa")
  mapa.vista = vista
  local wx, dialogo = vista.wx, vista.dialogo
  local contenido = wx.wxBoxSizer(wx.wxVERTICAL)
  contenido:Add(wx.wxStaticText(dialogo, wx.wxID_ANY,
    "Flechas: elegir destino. Enter: viajar. Tab: cambiar pestaña. Escape: cerrar."), 0, wx.wxALL, 12)
  local componente = ui.lista(vista, {
    columnas = { { titulo = "Destino", ancho = 680 } }, pestanas = true, max_acciones = 1,
    sonido = sonido,
    activar = function() mapa.aceptar() end,
    al_seleccionar = function(elemento)
      for i, destino in ipairs(conjunto()) do
        if identidad(destino) == elemento.id then selecciones[pestana] = i; break end
      end
    end,
    al_pestana = function(id)
      pestana = id == "resultados" and 1 or 2
      refrescar()
      if vista.mostrando then announce(nombres[pestana]) end
    end,
    acciones = function(elemento)
      local destino = elemento.datos
      if indice_favorito(destino) then
        return { { id = "favorito", nombre = "Eliminar de favoritos", ejecutar = function(fila)
          mapa.eliminar_favorito(fila.datos)
        end } }
      end
      return { { id = "favorito", nombre = "Añadir a favoritos", habilitada = personaje ~= nil,
        ejecutar = function(fila) mapa.agregar_favorito(fila.datos) end } }
    end,
  })
  mapa.componente, mapa.lista, mapa.pestanyas = componente, componente.control, componente.pestanyas
  componente:actualizar_pestanas({ { id = "resultados", nombre = "Resultados" },
    { id = "favoritos", nombre = "Favoritos" } }, "resultados")
  mapa.pestanyas:SetName("Listas de destinos")
  contenido:Add(componente.sizer, 1, wx.wxEXPAND + wx.wxALL, 12)
  mapa.estado_texto = wx.wxStaticText(dialogo, wx.wxID_ANY, "")
  contenido:Add(mapa.estado_texto, 0, wx.wxALL, 12)
  dialogo:SetSizerAndFit(contenido)
  vista.cancelar = mapa.cerrar
  vista.tecla = function(evento)
    return componente:tecla(evento:GetKeyCode(), evento:GetModifiers())
  end
  refrescar()
  vista:preparar()
end

function mapa.estado()
  sincronizar_personaje()
  local estado = { resultados = {}, favoritos = {}, pestana = pestana,
    criterio = criterio_actual, personaje = personaje,
    selecciones = { selecciones[1], selecciones[2] } }
  for i, destino in ipairs(resultados) do estado.resultados[i] = copiar(destino) end
  for i, destino in ipairs(favoritos) do estado.favoritos[i] = copiar(destino) end
  return estado
end

function mapa.destruir()
  retirada = true
  mapa.cerrar()
  ui.retirar_al_cerrar(mapa)
  if adaptador and RL_mostrar_links_viaje_room == adaptador then RL_mostrar_links_viaje_room = original end
  for _, id in ipairs(handlers) do killAnonymousEventHandler(id) end
  handlers = {}
  if mapa.vista then mapa.vista:destruir() end
  mapa.vista, mapa.lista, mapa.pestanyas, mapa.estado_texto, mapa.componente = nil, nil, nil, nil, nil
  resultados, favoritos, selecciones = {}, {}, { 1, 1 }
  criterio_actual, personaje = "", nil
  filas_cache, datos_renderizados, nombre_lista, texto_estado = {}, nil, nil, nil
  pestana = 1
  original, adaptador, iniciada = nil, nil, false
end

mapa.pulsaciones = {{ combinacion = { tecla = mudlet.key.M,
  modificadores = { mudlet.keymodifier.Control, mudlet.keymodifier.Shift } },
  nombre = "mapa.mostrar", funcion = mapa.mostrar, descripcion = "Abre la lista de destinos del mapa", grupo = "mapa" }}

return mapa
