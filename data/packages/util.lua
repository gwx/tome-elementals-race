module('elementals-race.util', package.seeall)

--[=[
  Decends recursively through a table by the given list of keys.

  1st return: The first non-table value found, or the final value if
  we ran out of keys.

  2nd return: If the list of keys was exhausted

  Meant to replace multiple ands to get a value:
  "a and a.b and a.b.c" turns to "rget(a, 'b', 'c')"
]=]
function _M.get(table, ...)
  if type(table) ~= 'table' then return table, false end
  for _, key in ipairs({...}) do
    if type(table) ~= 'table' then return table, false end
    table = table[key]
  end
  return table, true
end

--[=[
  Set the nested value in a table, creating empty tables as needed.
]=]
function _M.set(table, ...)
  if type(table) ~= 'table' then return false end
  local args = {...}
  for i = 1, #args - 2 do
    local key = args[i]
    local subtable = table[key]
    if not subtable then
      subtable = {}
      table[key] = subtable
    end
    table = subtable
  end
  table[args[#args - 1]] = args[#args]
end

--[=[
  If the source contains the given value.
  returns the key, the value, and if it succeeded.
]=]
function _M.hasv(source, value)
  for k, v in pairs(source) do
    if v == value then return k, v, true end
  end
  return nil, nil, false
end

return _M
