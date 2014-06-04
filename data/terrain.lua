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
	z = 1,
	always_remember = true,
	does_block_move = true,
	can_pass = {pass_wall = 1,},
	block_sight = false,
	air_level = -10,}

-- Walls, without any background image, meant to be set upon creation.
newEntity{
	define_as = 'WALL_TEMP',
	type = 'wall', subtype = 'floor',
	name = 'wall',
	display = '#', color_r=255, color_g=255, color_b=255, back_color=colors.GREY,
	add_displays = {class.new {image = 'terrain/granite_wall1.png',},},
	z = 1,
	nice_tiler = {
		method = 'wall3d',
		inner = {'WALL_TEMP', 100, 1, 5,},
		north = {'WALL_TEMP_NORTH', 100, 1, 5,},
		south = {'WALL_TEMP_SOUTH', 10, 1, 17,},
		north_south = 'WALL_TEMP_NORTH_SOUTH',
		small_pillar = 'WALL_TEMP_SMALL_PILLAR',
		pillar_2 = 'WALL_TEMP_PILLAR_2',
		pillar_8 = {'WALL_TEMP_PILLAR_8', 100, 1, 5,},
		pillar_4 = 'WALL_TEMP_PILLAR_4',
		pillar_6 = 'WALL_TEMP_PILLAR_6',},
	always_remember = true,
	does_block_move = true,
	can_pass = {pass_wall = 1,},
	block_sight = true,
	air_level = -20,}

for i = 1, 5 do
	newEntity {
		base = 'WALL_TEMP',
		define_as = 'WALL_TEMP'..i,
		add_displays = {class.new {image = 'terrain/granite_wall1_'..i..'.png', z = 3,},},}
	newEntity {
		base = 'WALL_TEMP',
		define_as = 'WALL_TEMP_NORTH'..i,
		add_displays = {
			class.new {image = 'terrain/granite_wall1_'..i..'.png', z = 3,},
			class.new {image = 'terrain/granite_wall3.png', z = 18, display_y = -1,},},}
	newEntity {
		base = 'WALL_TEMP',
		define_as = 'WALL_TEMP_PILLAR_8'..i,
		add_displays = {
			class.new {image = 'terrain/granite_wall1_'..i..'.png', z = 3,},
			class.new {image = 'terrain/granite_wall_pillar_8.png', z = 18, display_y = -1,},},}
end
newEntity {
	base = 'WALL_TEMP',
	define_as = 'WALL_TEMP_NORTH_SOUTH',
	add_displays = {
		class.new {image = 'terrain/granite_wall2.png', z = 3,},
		class.new {image = 'terrain/granite_wall3.png', z = 18, display_y = -1,},},}
newEntity {
	base = 'WALL_TEMP',
	define_as = 'WALL_TEMP_SOUTH',
	add_displays = {
		class.new {image = 'terrain/granite_wall2.png', z = 3,},},}
for i = 1, 17 do
	newEntity {
		base = 'WALL_TEMP',
		define_as = 'WALL_TEMP_SOUTH'..i,
		add_displays = {class.new {image = 'terrain/granite_wall2_'..i..'.png', z = 3,},},}
end
newEntity {
	base = 'WALL_TEMP',
	define_as = 'WALL_TEMP_SMALL_PILLAR',
	add_displays = {
		class.new {image = 'terrain/granite_wall_pillar_small.png', z = 3,},
		class.new {image = 'terrain/granite_wall_pillar_small_top.png', z = 18, display_y = -1,},},}
newEntity{
	base = 'WALL_TEMP',
	define_as = 'WALL_TEMP_PILLAR_6',
	add_displays = {
		class.new {image = 'terrain/granite_wall_pillar_3.png', z = 3,},
		class.new {image = 'terrain/granite_wall_pillar_9.png', z = 18, display_y = -1,},},}
newEntity{
	base = 'WALL_TEMP',
	define_as = 'WALL_TEMP_PILLAR_4',
	add_displays = {
		class.new {image = 'terrain/granite_wall_pillar_1.png', z = 3,},
		class.new {image = 'terrain/granite_wall_pillar_7.png', z = 18, display_y = -1,},},}
newEntity{
	base = 'WALL_TEMP',
	define_as = 'WALL_TEMP_PILLAR_2',
	add_displays = {
		class.new {image = 'terrain/granite_wall_pillar_2.png', z = 3,},},}
