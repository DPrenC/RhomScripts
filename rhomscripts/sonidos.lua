-- Inventario de los WAV incluidos con RhomScripts.
local sonidos = {}

local function ruta_hija(raiz, nombre)
  return raiz:gsub("/+$", "") .. "/" .. nombre
end

local function raiz_sonidos(raiz)
  if raiz == nil then
    local raiz_scripts = RhomScripts and RhomScripts.root or getMudletHomeDir() .. "/rhomscripts"
    raiz = ruta_hija(raiz_scripts:gsub("\\", "/"), "sonidos")
  end
  assert(type(raiz) == "string" and raiz ~= "", "Raíz de sonidos inválida")
  raiz = raiz:gsub("\\", "/")
  if not raiz:match("^/") and not raiz:match("^%a:/") then
    raiz = ruta_hija(assert(lfs.currentdir()):gsub("\\", "/"), raiz)
  end
  if raiz == "/" or raiz:match("^%a:/$") then return raiz end
  return (raiz:gsub("/+$", ""))
end

local function nombres(directorio)
  local entradas = {}
  for nombre in lfs.dir(directorio) do
    if nombre ~= "." and nombre ~= ".." then entradas[#entradas + 1] = nombre end
  end
  table.sort(entradas)
  return entradas
end

local function normalizar(nombre)
  local identificador = nombre:lower():gsub(" +", "_")
  if identificador:match("^[a-z0-9_][a-z0-9_%-]*$") then return identificador end
end

local function incidencia(resumen, mensaje)
  resumen.incidencias[#resumen.incidencias + 1] = mensaje
end

local function listar_grupo(directorio, carpeta, candidatos, resumen)
  local grupo = normalizar(carpeta)
  if not grupo then
    incidencia(resumen, "Nombre de grupo inválido: " .. carpeta)
    return
  end
  for _, archivo in ipairs(nombres(directorio)) do
    local base = archivo:match("^(.*)%.[wW][aA][vV]$")
    if base then
      local ruta = ruta_hija(directorio, archivo)
      local modo = lfs.symlinkattributes(ruta, "mode")
      local nombre = normalizar(base)
      if modo == "file" and nombre then
        local clave = grupo .. "." .. nombre
        local fuentes = candidatos[clave] or {}
        fuentes[#fuentes + 1] = { grupo = grupo, ruta = ruta }
        candidatos[clave] = fuentes
      elseif modo ~= "directory" then
        resumen.archivos_erroneos = resumen.archivos_erroneos + 1
        incidencia(resumen, "Nombre o archivo WAV inválido: " .. ruta)
      end
    end
  end
end

local function comprobar_archivos(candidatos, resumen)
  local entradas = {}
  for clave, fuentes in pairs(candidatos) do
    resumen.claves_total = resumen.claves_total + 1
    if #fuentes > 1 then
      local rutas = {}
      for _, fuente in ipairs(fuentes) do rutas[#rutas + 1] = fuente.ruta end
      resumen.archivos_erroneos = resumen.archivos_erroneos + #fuentes
      incidencia(resumen, "Clave duplicada " .. clave .. ": " .. table.concat(rutas, ", "))
    else
      local fuente = fuentes[1]
      local archivo = io.open(fuente.ruta, "rb")
      if archivo then
        archivo:close()
        entradas[clave] = { grupo = fuente.grupo, archivos = { fuente.ruta }, seleccion = "fija" }
        resumen.archivos_correctos = resumen.archivos_correctos + 1
        resumen.claves_disponibles = resumen.claves_disponibles + 1
      else
        resumen.archivos_erroneos = resumen.archivos_erroneos + 1
        incidencia(resumen, "Archivo ausente o inaccesible: " .. fuente.ruta)
      end
    end
  end
  table.sort(resumen.incidencias)
  return entradas
end

function sonidos.cargar_catalogo(raiz)
  sonidos.catalogo = nil
  sonidos.resumen_catalogo = nil
  local resumen = {
    estado = "ausente", raiz = raiz_sonidos(raiz), claves_total = 0,
    claves_disponibles = 0, archivos_correctos = 0, archivos_erroneos = 0, incidencias = {},
  }
  local modo = lfs.symlinkattributes(resumen.raiz, "mode")
  if modo == "directory" then
    local candidatos = {}
    for _, carpeta in ipairs(nombres(resumen.raiz)) do
      local directorio = ruta_hija(resumen.raiz, carpeta)
      if lfs.symlinkattributes(directorio, "mode") == "directory" then
        listar_grupo(directorio, carpeta, candidatos, resumen)
      end
    end
    local entradas = comprobar_archivos(candidatos, resumen)
    if resumen.claves_disponibles > 0 then
      sonidos.catalogo = { sonidos = entradas }
      resumen.estado = #resumen.incidencias == 0 and "cargado" or "parcial"
    else
      resumen.estado = "invalido"
      if #resumen.incidencias == 0 then incidencia(resumen, "No hay archivos WAV utilizables.") end
    end
  elseif modo then
    resumen.estado = "invalido"
    incidencia(resumen, "La ruta de sonidos no es una carpeta: " .. resumen.raiz)
  end
  resumen.mensaje = RhomScripts.modules.debug.formato_catalogo(resumen)
  sonidos.resumen_catalogo = resumen
  return resumen
end

-- Disponibilidad del catálogo, no confirmación de reproducción o decodificación.
function sonidos.consultar()
  local resultado = {}
  local raiz = (RhomScripts.root .. "/sonidos/"):gsub("\\", "/")
  for clave, entrada in pairs(sonidos.catalogo and sonidos.catalogo.sonidos or {}) do
    local archivo = entrada.archivos[1]:gsub("\\", "/")
    if archivo:sub(1, #raiz) == raiz then archivo = archivo:sub(#raiz + 1) end
    resultado[#resultado + 1] = { modulo = "sonidos", nombre = clave, grupo = entrada.grupo,
      archivo = archivo, estado = "archivo accesible en catálogo; reproducción sin comprobar" }
  end
  local resumen = sonidos.resumen_catalogo
  for indice, mensaje in ipairs(resumen and resumen.incidencias or {}) do
    resultado[#resultado + 1] = { modulo = "sonidos", nombre = "Incidencia " .. indice,
      estado = "incidencia", detalle = mensaje }
  end
  if resumen and not sonidos.catalogo and #resultado == 0 then
    resultado[1] = { modulo = "sonidos", nombre = "Catálogo", estado = resumen.estado, detalle = resumen.mensaje }
  end
  return resultado
end

return sonidos
