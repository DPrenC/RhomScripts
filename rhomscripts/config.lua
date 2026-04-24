local config = {}

config.defaults = {
    silent = false,
    experto = true,
    ambientacion = true,
    mono = false,
    modo_juego = "combate",
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
    if type(getMudletHomeDir) == "function" and type(getProfileName) == "function" then
        return string.format("%s/profiles/%s/rl_config.lua", getMudletHomeDir(), getProfileName())
    end
    return "rl_config.lua"
end

local function load_table(path)
    if type(table.load) == "function" then
        local ok, data = pcall(table.load, path)
        if ok and type(data) == "table" then
            return data
        end
    end
    if type(loadTable) == "function" then
        local ok, data = pcall(loadTable, path)
        if ok and type(data) == "table" then
            return data
        end
    end
    return nil
end

local function save_table(data, path)
    if type(table.save) == "function" then
        local ok = pcall(table.save, data, path)
        if ok then
            return true
        end
        ok = pcall(table.save, path, data)
        return ok
    end
    if type(saveTable) == "function" then
        local ok = pcall(saveTable, data, path)
        if ok then
            return true
        end
        ok = pcall(saveTable, path, data)
        return ok
    end
    return false
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
