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

lib.require 'current-actor'

superload('mod.class.Actor', function(_M)
		local on_set_temporary_effect = _M.on_set_temporary_effect
		function _M:on_set_temporary_effect(eff_id, e, p)
			p.src = p.src or game.current_actor
			return on_set_temporary_effect(self, eff_id, e, p)
			end
		end)
