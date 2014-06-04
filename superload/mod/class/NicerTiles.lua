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


-- For active terrain.
local map = require 'engine.Map'
local TERRAIN = map.TERRAIN
local _M = loadPrevious(...)

local replaceAll = _M.replaceAll
function _M:replaceAll(level)
	local overlay = function(self, level, mode, i, j, g) return g end
	if level.data.nicer_tiler_overlay then
		overlay = self['overlay'..level.data.nicer_tiler_overlay]
	end

	for _, r in pairs(self.repl) do
		-- Safety check
		local og = level.map(r[1], r[2], TERRAIN)
		if og and (og.change_zone or og.change_level) then
			print('[NICE TILER] *warning* refusing to remove zone/level changer at ', r[1], r[2], og.change_zone, og.change_level)
		elseif og.active_terrain then
			og.terrain = r[3]
			og._mo = nil
			og._last_mo = nil
			level.map.changed = true
			level.map:updateMap(r[1], r[2])
		else
			level.map(r[1], r[2], TERRAIN, overlay(self, level, 'replace', r[1], r[2], r[3]))
		end
	end
	self.repl = {}

	return replaceAll(self, level)
end

return _M
