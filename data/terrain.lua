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


-- This has no image set. Meant to be filled in with whatever it's
-- 'overlaying'. See the copy_missing option in active_terrain.
newEntity {
	define_as = 'BOULDER',
	type = 'wall', subtype = 'floor',
	name = 'boulder',
	add_mos = {{image = 'terrain/huge_rock.png',},},
	display = '#', color_r = 210, color_g = 210, color_b = 30, back_color = colors.GREY,
	z = 3,
	always_remember = true,
	does_block_move = true,
	can_pass = {pass_wall = 1,},
	block_sight = false,
	air_level = -10,}
