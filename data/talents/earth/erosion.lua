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


local stats = require 'engine.interface.ActorStats'

newTalentType {
	type = 'elemental/erosion',
	name = 'Erosion',
	generic = true,
	description = 'Sand is more dangerous than you think',
	allow_random = true,}

local make_require = function(tier)
	return {
		stat = {con = function(level) return 2 + tier * 8 + level * 2 end,},
		level = function(level) return -5 + tier * 4 + level end,}
end

newTalent {
	name = 'Sharkskin',
	type = {'elemental/erosion', 1,},
	require = make_require(1),
	points = 5,
	mode = 'passive',
	duration = 5,
	stacks = function(self, t)
		return math.floor(self:combatTalentScale(t, 10, 15) * (0.5 + self:getCon(0.5, true)))
	end,
	defense = function(self, t)
		return self:combatTalentScale(t, 3, 7) * (0.5 + self:getCon(0.5, true))
	end,
	power = function(self, t) return 2 + self:getCon(2, true) end,
	disarm = function(self, t)
		return math.floor(self:combatTalentScale(t, 2, 6) * (0.5 + self:getCon(0.5, true)))
	end,
	disarm_cooldown = 5,
	on_hit = function(self, t)
		self:setEffect('EFF_SHARKSKIN', util.getval(t.duration, self, t), {
										 amount = 1,
										 max = util.getval(t.stacks, self, t),
										 defense = util.getval(t.defense, self, t),
										 power = util.getval(t.power, self, t),
										 disarm_cooldown = util.getval(t.disarm_cooldown, self, t),
										 disarm = util.getval(t.disarm, self, t),})
	end,
	info = function(self, t)
		return ([[Your 'skin' has dried and cracked, forming a rough mesh of hooked scales if put to stress. Every time you are hit with a melee or archery attack, you gain a stack of Sharkskin for %d turns, up to %d stacks.
Each stack gives %d points to ranged defense and increases physical power by %d. Any enemy that lands a critical melee strike, up to once every %d turns, must pass a physical power check against your physical save or be disarmed for %d turns.
Defense, physical power, disarm duration and maximum stacks scale with constitution.]])
			:format(util.getval(t.duration, self, t),
							util.getval(t.stacks, self, t),
							util.getval(t.defense, self, t),
							util.getval(t.power, self, t),
							util.getval(t.disarm_cooldown, self, t),
							util.getval(t.disarm, self, t))
	end,}

newTalent {
	name = 'Amorphous',
	type = {'elemental/erosion', 2,},
	require = make_require(2),
	points = 5,
	essence = 15,
	cooldown = 19,
	range = 0,
	radius = function(self, t)
		return math.floor(util.bound(self:getTalentLevel(t), 2, 2.8))
	end,
	damage = function(self, t)
		return self:combatTalentScale(t, 30, 180) * (0.5 + self:getCon(0.5, true))
	end,
	duration = function(self, t)
		return math.floor(2 + self:combatTalentScale(t, 0, 3) * (0.5 + self:getCon(0.5, true)))
	end,
	tactical = {ATTACKAREA = 2, ESCAPE = 1,},
	target = function(self, t)
		return {type = 'ball', selffire = false, talent = t,
						range = util.getval(t.range, self, t),
						radius = util.getval(t.radius, self, t),}
	end,
	action = function(self, t)
		local tg = util.getval(t.target, self, t)
		-- Damage
		local base_damage = util.getval(t.damage, self, t)
		local projector = function(x, y, tg, self)
			local target = game.level.map(x, y, Map.ACTOR)
			if not target then return end
			local damage = self:physicalCrit(
				base_damage, nil, target, self:combatAttackRanged(), target:combatDefenseRanged())
			DamageType:get(DamageType.PHYSICAL).projector(
				self, x, y, DamageType.PHYSICAL, damage)
		end
		self:project(tg, self.x, self.y, projector)
		-- Map Effect
		local duration = util.getval(t.duration, self, t)
		local effect = game.level.map:addEffect(
			self, self.x, self.y, duration,
			DamageType.NULL,
			-- We're coopting the damage amount to hold various info.
			{effect_type = 'dust_storm',},
			tg.radius, 5, nil, {type = 'dust_storm'})
		effect.name = 'dust storm'
		-- Pretties
		game.level.map:particleEmitter(self.x, self.y, tg.radius, 'ball_earth', {radius = tg.radius + 1,})
		game:playSoundNear(self, 'talents/earth')
		return true
	end,
	info = function(self, t)
		return ([[Explodes in a radius %d burst of sand, dealing %d physical damage. For the next %d turns, you can freely move to any square inside the affected area in a single turn, as long as you are inside it.
Damage and duration increase with constitution.]])
			:format(util.getval(t.radius, self, t),
							Talents.damDesc(self, DamageType.PHYSICAL, util.getval(t.damage, self, t)),
							util.getval(t.duration, self, t))
	end,}

newTalent{
	name = 'Sandstorm',
	type = {'elemental/erosion', 3,},
	require = make_require(3),
	points = 5,
	essence = 15,
	cooldown = 23,
	range = 0,
	radius = 2,
	duration = function(self, t)
		return math.floor(5 + 5 * (0.5 + self:getCon(0.5, true)))
	end,
	accuracy = function(self, t)
		return self:combatTalentScale(t, 6, 11) * (0.5 + self:getCon(0.5, true))
	end,
	accuracy_duration = 2,
	stacks = 3,
	tactical = {ATTACKAREA = {PHYSICAL = 2}, DISABLE = {BLIND = 1,},},
	target = function(self, t)
		return {type = 'ball',
						range = util.getval(t.range, self, t),
						radius = util.getval(t.radius, self, t),}
	end,
	action = function(self, t)
		local radius = util.getval(t.radius, self, t)
		local duration = self:spellCrit(util.getval(t.duration, self, t))
		local accuracy = util.getval(t.accuracy, self, t)
		local accuracy_duration = util.getval(t.accuracy_duration, self, t)
		local stacks = util.getval(t.stacks, self, t)
		-- Add a lasting map effect
		local effect =
			game.level.map:addEffect(
				self, self.x, self.y, duration,
				DamageType.SANDSTORM, {
					accuracy = accuracy,
					max = accuracy * stacks,
					effect_duration = accuracy_duration,},
				radius, 5, nil,
				{type = 'sandstorm', args = {radius = radius,}, only_one = true,},
				function(e)
					e.x = e.src.x
					e.y = e.src.y
					return true
				end,
				false)
		effect.name = 'sandstorm'
		game:playSoundNear(self, 'talents/breath')
		return true
	end,
	info = function(self, t)
		local accuracy = util.getval(t.accuracy, self, t)
		return ([[A fierce sandstorm rages in radius %d around you for %d turns. #SLATE#(UNIMPLEMENTED: Enemy projectiles move 50%% slower through it,)#LAST# while anything inside loses %d accuracy every turn, stacking to a max of %d, at which point they become blinded as well.
Durration and accuracy reduction scale with constitution.]])
			:format(util.getval(t.radius, self, t),
							util.getval(t.duration, self, t),
							accuracy,
							accuracy * util.getval(t.stacks, self, t))
	end,
}
