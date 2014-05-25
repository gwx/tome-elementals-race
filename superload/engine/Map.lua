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


local eutil = require 'elementals-race.util'

local _M = loadPrevious(...)

-- Get all effects at target location. If type is truthy, it will
-- filter them based on effect.dam.effect_type == type.
function _M:getEffects(x, y, type)
	local effects = {}
	for _, effect in pairs(self.effects or {}) do
		if not type or eutil.get(effect.dam, 'effect_type') == type then
			if eutil.get(effect.grids, x, y) then
				table.insert(effects, effect)
			end
		end
	end
	return effects
end

return _M
