local config = {}

config.defaults = {
    silent = false,
    experto = true,
    ambientacion = true,
    asignacion_ambiente_room = false,
    mono = false,
    modo_juego = "combate",
    modo_path = 0,
    alerta_vida = true,
    auto_centrar = true,
    seleccion_canal = 1,
    filtro_salidas = false,
    modo_sigilar = false,
    modo_marinero = false,
    montado = false,
    galopando = false,
    embarcado = false,
    navegando = false,
}

config.data = {}
config.auto_save = true

local function file_exists(path)
    local file = io.open(path, "r")
    if file then
        file:close()
        return true
    end
    return false
end

local function config_path()
    return getMudletHomeDir() .. "/rl_config.lua"
end

local function load_table(path)
    local data = {}
    table.load(path, data)
    return data
end

local function save_table(data, path)
    table.save(path, data)
    return true
end

local function merge_defaults(data)
    for key, value in pairs(config.defaults) do
        if data[key] == nil then
            data[key] = value
        end
    end
end

function config.load()
    local path = config_path()
    local data = {}
    if file_exists(path) then
        data = load_table(path) or {}
    end
    merge_defaults(data)
    config.data = data
    return config.data
end

function config.save()
    local path = config_path()
    return save_table(config.data, path)
end

function config.get(key)
    return config.data[key]
end

function config.set(key, value)
    config.data[key] = value
    if config.auto_save then
        config.save()
    end
end

function config.all()
    return config.data
end

return config
