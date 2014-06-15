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
local map = require 'engine.Map'
local ACTOR = map.ACTOR

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

newDamageType {
	name = 'blinding sand', type = 'SANDSTORM',
	projector = function(src, x, y, t, dam)
		if type(dam) ~= 'table' then dam = {accuracy = dam} end
		local accuracy = dam.accuracy or 3
		local max = dam.max or accuracy * 3
		local effect_duration = dam.effect_duration or 2

		local target = game.level.map(x, y, Map.ACTOR)
		if not target or src == target then return 0 end
		target:setEffect('EFF_BLINDING_SAND', effect_duration, {
											 accuracy = accuracy,
											 max = max,})
		return 0
	end,}

-- Suffocate, silence, blind, and increased incoming crit chance.
newDamageType {
	name = 'billowing carpet', type = 'BILLOWING_CARPET',
	projector = function(src, x, y, t, dam)
		if type(dam) ~= 'table' then dam = {crit = dam} end
		local crit = dam.crit or 5
		local heat_gain = dam.heat_gain or 10
		local stealth = dam.stealth or 0.10
		local duration = dam.duration or 2
		local air = dam.air or 12
		local src = dam.src

		local actor = game.level.map(x, y, ACTOR)
		if src and actor == src then
			local depth = 1
			if dam.origin_x and dam.origin_y and dam.max_depth then
				depth = dam.max_depth - core.fov.distance(dam.origin_x, dam.origin_y, x, y)
			end
			actor:setEffect('EFF_BILLOWING_CARPET_COVER', 1, {
												heat_gain = heat_gain,
												stealth = stealth * depth,})
		elseif actor then
			actor:setEffect('EFF_BILLOWING_CARPET', duration, {
												 src = src,
												 crit = crit,
												 air = air,
												 no_ct_effect = true,
												 apply_power = src and src:combatAttack(),})
		end
		return 0
	end,}
