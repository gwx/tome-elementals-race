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

newTalentType {
	type = 'elemental/eyal-resolver',
	name = 'Eyal Resolver',
	description = 'Unstoppable Boulder',}

local make_require = function(tier)
	return {
		stat = {str = function(level) return 2 + tier * 8 + level * 2 end,},
		level = function(level) return -5 + tier * 4 + level end,}
end

newTalent {
	name = 'Afterecho',
	type = {'elemental/eyal-resolver', 1,},
	require = make_require(1),
	points = 5,
	mode = 'passive',
	inc_damage = function(self, t)
		return self:combatTalentScale(t, 30, 70) * (0.5 + self:getStr(0.5, true))
	end,
	echo = function(self, t)
		return self:combatTalentScale(t, 0.25, 0.6) * (0.5 + self:getStr(0.5, true))
	end,
	-- Recomputed in onWear/onTakeoff.
	passives = function(self, t, p)
		if self:isUnarmed() then
			local inc_damage = {[DamageType.PHYSICAL] = util.getval(t.inc_damage, self, t),}
			self:talentTemporaryValue(p, 'inc_damage', inc_damage)
			self:talentTemporaryValue(p, 'physical_echo', util.getval(t.echo, self, t))
		end
	end,
	info = function(self, t)
		return ([[While unarmed:
Increases all physical damage done by %d%%.
Successful melee attacks will echo, hitting the space directly behind the target for %d%% of damage done.
Scales with strength.]])
			:format(util.getval(t.inc_damage, self, t),
							util.getval(t.echo, self, t) * 100)
	end,}

newTalent {
	name = 'Brutish Stride',
	type = {'elemental/eyal-resolver', 2,},
	require = make_require(2),
	points = 5,
	mode = 'passive',
	move = function(self, t)
		return self:combatTalentScale(t, 1.5, 3)
	end,
	damage = function(self, t)
		return self:combatTalentScale(t, 0.5, 1.5)
	end,
	radius = 2,
	angle = 30,
	info = function(self, t)
		local move = util.getval(t.move, self, t)
		return ([[Your joints do not tire, your arms do not rest. Every time you move a tile, you gain speed for a charge - your movement speed increases by %d%% #SLATE#(UNIMPLEMENTED: 5x this if no enemy is in sight)#LAST#, to a maximum of %d%%.
Your first weapon strike will consume the charge. At full charge, this will make it deal %d%% extra weapon damage (scaling with strength) and expand the afterecho's range to a radius %d cone with %d extra degrees of coverage. These effects will be lesser for lesser amounts of charge.
Any action but movement cuts the current charge in half. Standing still removes it completely.]])
			:format(move, move * 10,
							util.getval(t.damage, self, t) * 100,
							util.getval(t.radius, self, t) + 1,
							util.getval(t.angle, self, t))
	end,}

newTalent{
	name = 'Unleashed',
	type = {'elemental/eyal-resolver', 3},
	require = make_require(3),
	points = 5,
	--no_energy = true,
	cooldown = 22,
	tactical = { DEFEND = 1,  CURE = 1 },
	essence = 12,
	duration = function(self, t)
		return self:combatTalentScale(t, 6, 10) * (0.5 + self:getStr(0.5, true))
	end,
	action = function(self, t)
		self:setEffect('EFF_UNLEASHED', util.getval(t.duration, self, t), {})
		return true
	end,
	info = function(self, t)
		return ([[Nothing dare stop you dead in your tracks. When activated, you become unleashed for %d turns. While unleashed, you are immune to effects that would slow you down, knock you back or immobilize you.
This does not negate the application of harmful skills however, only their slowing/knock-backing/immbolizing effect and the duration of Unleashed decreases by 1 for every effect it negates.
Duration increases with strength.]])
			:format(util.getval(t.duration, self, t))
	end,}

newTalent {
	name = 'Cry of Eyal',
	type = {'elemental/eyal-resolver', 4,},
	require = make_require(4),
	points = 5,
	mode = 'sustained',
	sustain_essence = 25,
	cooldown = 41,
	speed_penalty = 0.33,
	scale_point = 0.67,
	damage = function(self, t)
		return self:combatTalentPhysicalDamage(t, 100, 500)
	end,
	radius = 5,
	activate = function(self, t)
		local p = {}
		self:talentTemporaryValue(p, 'max_life_damage', 1)
		self:talentTemporaryValue(p, 'global_speed_add', -util.getval(t.speed_penalty, self, t))
		return p
	end,
	deactivate = function(self, t, p)
		local taken = self.max_life_damage_taken or 0
		self.max_life_damage_taken = 0
		local max = self.max_life + taken
		self.max_life = max
		local power = math.min(1, (taken / max) / util.getval(t.scale_point, self, t))
		local damage = util.getval(t.damage, self, t) * power
		local tg = {type = 'ball', range = 0, radius = util.getval(t.radius, self, t), selffire = false,}
		local projector = function(x, y, tg, self)
			local target = game.level.map(x, y, Map.ACTOR)
			if not target then return end
			local dam = self:physicalCrit(damage, nil, target, 0, 0)
			DamageType:get(DamageType.PHYSICAL).projector(
				self, x, y, DamageType.PHYSICAL, dam)
		end
		self:project(tg, self.x, self.y, projector)
		game.level.map:particleEmitter(self.x, self.y, tg.radius, 'ball_earth', {radius = tg.radius,})
		game:playSoundNear(self, 'talents/lightning_loud')
		return true
	end,
	info = function(self, t)
		return ([[You cry out for the defiance of the planet itself to embody you. While active, enemy damage reduces your maximum life instead of your current life and your global speed is reduced by %d%%. (Your current life still decreases if maximum life is lower than it.)
When deactivated, you release all this power in a cataclysmic display of might, dealing physical damage in a ball of radius %d. The damage scales from 0 at 0%% max life lost to %d at %d%% or greater max life lost.
Damage scales with physical power.]])
			:format(
				util.getval(t.speed_penalty, self, t) * 100,
				util.getval(t.radius, self, t),
				Talents.damDesc(self, DamageType.PHYSICAL, util.getval(t.damage, self, t)),
				util.getval(t.scale_point, self, t) * 100)
	end,}
