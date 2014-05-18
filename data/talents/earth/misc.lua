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


newTalent {
	name = 'Essence Pool',
	type = {'base/class', 1,},
	info = 'Allows you to have an essence pool. Essence is used to manipulate earth.',
	mode = 'passive',
	hide = 'always',
	no_unlearn_last = true,
	callbackOnRest = function(self)
		return self.essence_regen > 0 and self.essence < self.max_essence
	end,}
