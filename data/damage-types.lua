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

local project_damage = function(src, x, y, type, dam)
	type = DamageType[type]
	return DamageType:get(type).projector(src, x, y, type, dam)
end

newDamageType {
	name = 'entangling roots', type = 'SYMBIOTIC_ROOTS', text_color = '#DARK_GREEN#',
	projector = function(src, x, y, t, dam)
		if type(dam) ~= 'table' then dam = {damage = dam} end
		local target = game.level.map(x, y, Map.ACTOR)
		if not target then return 0 end
		if src == target or src:reactionToward(target) >= 0 then
			target:setEffect('EFF_SYMBIOTIC_ROOTS', 1, {
												 healing = dam.healing or 0.1,
												 save = dam.save or 10,})
		else
			local move_update = function(t)
				if t then
					return {
						x = target.x,
						y = target.y,
						moved = not t.x or target.x ~= t.x or not t.y or target.y ~= t.y}
				else
					return {
						x = target.x,
						y = target.y,
						moved = true,}
				end
			end
			local moved = eutil.update(move_update, dam, 'effect', 'target_move', target.uid)
			if moved.moved then
				local inc = function(x) return (x or 0) + 1 end
				local count = eutil.update(inc, dam, 'effect', 'hits', target.uid)
				if count >= 4 then
					local power =
						dam.apply_power or
						(src and src:combatSpellpower()) or
						20
					target:setEffect('EFF_PINNED', 4, {apply_power = power,})
				end
				return project_damage(src, x, y, 'NATURE', dam.damage or 10)
			end
		end
		return 0
	end,}

newDamageType{name = 'null', type = 'NULL', projector = function() end,}
