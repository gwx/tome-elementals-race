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

-- Amorphous Reform on click.
local mouseMove = _M.mouseMove
function _M:mouseMove(x, y, force)
	if self:knowTalent('T_AMORPHOUS_REFORM') and x and y then
		local t = self:getTalentFromId('T_AMORPHOUS_REFORM')
		if t.on_pre_use(self, t, true, x, y) then
			self.turn_procs.reformed = false
			self:forceUseTalent(
				'T_AMORPHOUS_REFORM', {force_target = {x = x, y = y},})
			if self.turn_procs.reformed then return end
		end
	end

	return mouseMove(self, x, y, force)
end

return _M
