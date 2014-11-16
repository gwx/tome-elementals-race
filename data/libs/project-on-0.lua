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

-- Convenience function for projecting directly.
superload('mod.class.Actor', function(_M)
		function _M:projectOn(actor, type, damage)
			if not actor or not actor.x or not actor.y then return end
			return engine.DamageType:get(type).projector(self, actor.x, actor.y, type, damage)
			end
		end)
