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


local _M = loadPrevious(...)

-- Set a flag so we know if we're currently doing timed effects.
local timedEffects = _M.timedEffects
function _M:timedEffects(filter)
	self.in_timed_effects = true
	timedEffects(self, filter)
	self.in_timed_effects = nil
end

return _M
