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


require 'engine.class'
local eutil = require 'elementals-race.util'
local object = require 'engine.Object'
local map = require 'engine.Map'
local TERRAIN = map.TERRAIN
local grid = require 'mod.class.Grid'
module('elementals-race.active-terrain', package.seeall, class.inherit(object))

-- Return if the target tile is free to place active terrain on.
function _M.tile_free(x, y)
	local tile = game.level.map(x, y, TERRAIN)
	local reasons = {'special', 'temporary', 'change_level', 'change_zone', 'active_terrain'}
	local reason = eutil.any_key(tile, reasons)
	if reason then
		return nil, reason
	end
	return true
end

-- Attempt to create terrain, checking for existing terrain that would
-- cause it to fail. Returns the terrain if succesful, nil if not.
function _M.create(t)
	if t.x and t.y then
		-- Check for existing terrain.
		local original = game.level.map(x, y, TERRAIN)
		-- If it's active terrain, run our own on_replace_active.
		if eutil.get(original, 'active_terrain') and t.on_replace_active then
			return t.on_replace_active(t, original, x, y)
		end
		-- Fail if there's some weird terrain at the target.
		local ok, reason = _M.tile_free(t.x, t.y)
		if not ok then return nil, reason end
	end
	-- Otherwise create as normal.
	return _M.new(t)
end

-- Update own metatable to route through terrain.
local set_meta = function(self)
	local meta = getmetatable(self)
	local class = meta.__index
	meta.__index = function(self, key)
		-- First try immediate class stuff.
		local result = rawget(class, key)
		-- Then try stuff from terrain.
		if result == nil then
			local terrain = rawget(self, 'terrain')
			result = terrain and terrain[key]
		end
		-- Then try deep class stuff.
		if result == nil then
			result = class[key]
		end
		return result
	end
	meta.__newindex = function(self, key, value)
		local terrain = rawget(self, 'terrain')
		if (key == '_mo' or key == '_last_mo') and terrain then
			terrain[key] = value
		else
			rawset(self, key, value)
		end
	end
end

function _M:init(t, no_default)
	set_meta(self)

	self.in_level = false
	self.in_map = false
	self.active_terrain = true
	self.action_list = {}
	self.canAct = false

	self.tooltip = grid.tooltip

	t = t or {}
	object.init(self, t, no_default)

	if not self.terrain and self.terrain_name then
		--self.terrain = game.level:findEntity({define_as = self.terrain_name,})
		self.terrain = game.nicer_tiles:getTile(self.terrain_name)
		if not self.terrain and self.terrain_file then
			grid:loadList(self.terrain_file, nil, game.zone.grid_list)
			self.terrain = game.zone:makeEntityByName(game.level, 'terrain', self.terrain_name)
		end
		--self.terrain_name = nil
		--self.terrain_file = nil
	end

	if self.can_dig and not self.dig then
		self.dig = function(src, x, y, self) self:removeLevel() end
		self.can_dig = nil
	end

	if self.copy_missing then
		table.update(self, self.copy_missing)
		self._last_mo = nil
		self._mo = nil
	end


	if self.no_add then
		self.no_add = nil
	else
		self:addMap()
	end
end


function _M:loaded()
	set_meta(self)
	object.loaded(self)
end

-- Add to level if necessary.
function _M:addLevel()
	if not self.in_level then
		game.level:addEntity(self)
		self.in_level = true
	end
end

-- Remove from level if necessary.
function _M:removeLevel()
	if self.in_level then
		self:removeMap()
		game.level:removeEntity(self)
		self.in_level = false
	end
end

-- Do nicer tiles.
function _M:doNicerTiles()
	local map = require 'engine.Map'
	if not map.tiles.nicer_tiles then return end
	if self.nicer_tiles == 'self' then
		game.nicer_tiles:handle(game.level, self.x, self.y)
	elseif self.nicer_tiles == 'around' then
		for x = self.x - 1, self.x + 1 do
			for y = self.y - 1, self.y + 1 do
				game.nicer_tiles:handle(game.level, x, y)
			end
		end
	end
	-- onTickEnd so if we change several adjacent tiles at once, they
	-- don't all get messed up.
	if self.nicer_tiles then
		game.nicer_tiles:replaceAll(game.level)
	end
end

function _M:addMap(force)
	if (not self.in_map or force) and self.x and self.y then
		-- Grab the new terrain we're covering.
		local present = game.level.map(self.x, self.y, map.TERRAIN)
		if present then
			if present.active_terrain then
				-- Allow special rules for merging.
				if present:merge(self) then return end
				present:removeLevel()
			end
			self.covering = present
		end

		self:addLevel()
		game.level.map(self.x, self.y, map.TERRAIN, self)
		self.in_map = true

		self:doNicerTiles()
	end
end

function _M:removeMap()
	if self.in_map then
		game.level.map:remove(self.x, self.y, map.TERRAIN)
		self.in_map = false

		-- Replace the terrain we were covering.
		if self.covering then
			if self.covering.active_terrain then
				self.covering.x = self.x
				self.covering.y = self.y
				self.covering:addMap()
			else
				game.level.map(self.x, self.y, map.TERRAIN, self.covering)
			end
			self.covering = nil
		else
			game.level.map:remove(self.x, self.y, map.TERRAIN)
		end

		self:doNicerTiles()
	end
end

function _M:move(x, y, force)
	if not x or not y then return end
	if not force and (x == self.x and y == self.y) then return end

	-- First remove self from map.
	self:removeMap()

	-- Move own coordinates.
	self.x = x
	self.y = y

	if self.terrain.active_terrain then
		self.terrain.x = x
		self.terrain.y = y
	end

	-- Then add self to the map.
	self:addMap()
end

-- Add an action to be performed every turn.
function _M:addAction(action)
	table.insert(self.action_list, action)
end

-- Override to allow active terrain to merge into each other.
-- Return true to stop the rest of the addMap function.
function _M:merge(other) return end

function _M:act()
	self:useEnergy()
	-- Actions
	for _, action in pairs(self.action_list) do action(self) end
	-- Temporary terrain.
	if self.temporary then
		self.temporary = self.temporary - 1
		if self.temporary <= 0 then
			if self.temporary_timeout then return self:temporary_timeout() end
			return self:removeLevel()
		end
	end
end
