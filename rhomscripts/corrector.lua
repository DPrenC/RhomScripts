-------------------------------------------------------------------------------
-- Modulo: corrector
-- Migracion funcional desde Corrector.set.
-------------------------------------------------------------------------------

local corrector = {}

local function trim(text)
  if type(text) ~= "string" then
    return ""
  end
  return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function replace_all(text, search, replacement)
  local value = tostring(text or "")
  local needle = tostring(search or "")
  local repl = replacement or ""

  if needle == "" then
    return value
  end

  local result = {}
  local index = 1
  while true do
    local first, last = value:find(needle, index, true)
    if not first then
      table.insert(result, value:sub(index))
      break
    end
    table.insert(result, value:sub(index, first - 1))
    table.insert(result, repl)
    index = last + 1
  end

  return table.concat(result)
end

function corrector.signos(text)
  local value = tostring(text or "")
  local replacements = {
    { ":", "." },
    { "[", "" },
    { "]", "" },
    { "¨", "" },
    { "|", "" },
    { "^", "" },
    { "_", "-" },
    { "·", "" },
    { "*", "" },
    { "-=(", "" },
    { ")=-", "" },
    { '"', "" },
  }

  for _, item in ipairs(replacements) do
    value = replace_all(value, item[1], item[2])
  end
  return trim(value)
end

function corrector.players(text)
  local value = tostring(text or "")
  local replacements = {
    "]", "[", "> ", "\\", "|", "-", "/", "+", "*",
    " (Hum", " (Ena", " (Mdro", " (Melf", " (Hal", " (Gno",
    " (Orc", " (Sem", " (Gob", " (Kob", " (Org", " (Hlag",
    "(", ")es", ")",
  }

  for _, item in ipairs(replacements) do
    value = replace_all(value, item, "")
  end

  value = value:gsub("%s%s+", " ")
  return trim(value)
end

function corrector.salidas(text)
  local value = tostring(text or "")
  value = replace_all(value, "-", "")
  value = replace_all(value, "|", "")
  return trim(value)
end

function corrector.canales(text)
  return tostring(text or "")
end

corrector.aliases = {
  {
    pattern = "^corrsignos\\s+(.+)$",
    action = function()
      print(corrector.signos(matches[2]))
    end,
    name = "corrsignos",
    desc = "Corrige signos de un texto"
  },
  {
    pattern = "^corrplayers\\s+(.+)$",
    action = function()
      print(corrector.players(matches[2]))
    end,
    name = "corrplayers",
    desc = "Corrige nombres de jugadores"
  },
}

return corrector
