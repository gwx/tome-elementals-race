-- Elementals Race, for Tales of Maj'Eyal.
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.


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
  Replace nested value with the result of applying f to it.
	Return the new value.
]=]
function _M.update(f, table, ...)
  if type(table) ~= 'table' then return end
  local args = {...}
  for i = 1, #args - 1 do
    local key = args[i]
    local subtable = table[key]
    if not subtable then
      subtable = {}
      table[key] = subtable
    end
    table = subtable
  end
	local result = f(table[args[#args]])
  table[args[#args]] = result
	return result
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

--[=[
	Create a new function(x, y, tg, self) which adds the actor at x, y
	to fill_table.  If filter is a function, it only does this if
	filter(target, x, y, tg, self) is truthy.

	Meant to be used in a project call:

	local targets = {}
	local is_hostile =
	  function(target) return self:reactionToward(target) < 0 end
	self:project(tg, x, y, eutil.actor_grabber(targets, is_hostile))
]=]
function _M.actor_grabber(fill_table, filter)
	local Map = require 'engine.Map'
	return function(x, y, tg, self)
		local actor = game.level.map(x, y, Map.ACTOR)
		if not actor then return end
		if type(filter) ~= 'function' or filter(actor, x, y, tg, self) then
			table.insert(fill_table, actor)
		end
	end
end

-- Various Functions:
function _M.adder(amt)
	return function(x) return amt + (x or 0) end
end

-- Clone table by reference
function _M.ref_clone(table)
	local result = {}
	setmetatable(result, {__index = table,})
	return result
end

return _M
