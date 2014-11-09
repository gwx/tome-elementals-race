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

superload('mod.class.interface.Combat', function(_M)
		function _M:unscaleCombatStats(scaled_value)
			local unscaled = 0
			local tier = math.floor(scaled_value / 20)
			while tier >= 0 do
				local points = scaled_value - tier * 20
				unscaled = unscaled + points * (tier + 1)
				scaled_value = scaled_value - points
				tier = tier - 1
				end
			return unscaled
			end
		end)
