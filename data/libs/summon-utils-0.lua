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


superload('mod.class.Actor', function(_M)
		function _M:setupSummon(summon)
			summon.unused_stats = 0
			summon.unused_talents = 0
			summon.unused_generics = 0
			summon.unused_talents_types = 0
			summon.no_inventory_access = true
			summon.no_points_on_levelup = true
			summon.save_hotkeys = true
			summon.ai_state = summon.ai_state or {}
			summon.ai_state.tactic_leash = 10
			summon.ai_talents = table.get(self, 'stored_ai_talents', summon.name) or {}
			summon.silent_levelup = true
			end

		end)
