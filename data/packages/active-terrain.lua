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
local object = require 'engine.Object'
local map = require 'engine.Map'
module('elementals-race.active-terrain', package.seeall, class.inherit(object))

function _M:init(t, no_default)
	-- Update own metatable to route through terrain.
	local meta = getmetatable(self)
	local class = meta.__index
	meta.__index = function(self, key)
		local result = class[key]
		if result == nil then result = self.terrain[key] end
		return result
	end

	self.in_level = false
	self.in_map = false
	self.active_terrain = true

	t = t or {}
	object.init(self, t, no_default)

	self:addMap()
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

		if self.nicer_tiles then
			game.nicer_tiles:updateAround(game.level, self.x, self.y)
		end
	end
end

function _M:removeMap()
	if self.in_map then
		game.level.map:remove(self.x, self.y, map.TERRAIN)
		self.in_map = false

		-- Replace the terrain we were covering.
		if self.covering then
			if self.covering.active_terrain then
				self.covering:addMap()
			else
				game.level.map(self.x, self.y, map.TERRAIN, self.covering)
			end
			self.covering = nil
		end

		if self.nicer_tiles then
			game.nicer_tiles:updateAround(game.level, self.x, self.y)
		end
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

	-- Then add self to the map.
	self:addMap()
end

-- Override to allow active terrain to merge into each other.
-- Rturn true to stop the rest of the move function.
function _M:merge(other) return end

function _M:act()
	self:useEnergy()
	-- Temporary terrain.
	if self.temporary then
		self.temporary = self.temporary - 1
		if self.temporary <= 0 then
			if self.timeout then return self:timeout() end
			return self:removeLevel()
		end
	end
end
