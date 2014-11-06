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
local ACTOR = require('engine.Map').ACTOR

newTalentType {
	type = 'elemental/brand',
	name = 'Brand',
	description = 'Burning Blade',
	allow_random = true,}

local make_require = function(tier)
	return {
		stat = {str = function(level) return 2 + tier * 8 + level * 2 end,},
		level = function(level) return -5 + tier * 4 + level end,}
end

newTalent {
	name = 'Wrathful Strike',
	type = {'elemental/brand', 1,},
	require = make_require(1),
	points = 5,
	cooldown = 4,
	tactical = {ATTACK = 3,},
	range = 1,
	no_energy = 'fake',
	damage = function(self, t)
		return self:elementalScale(t, 'str', 1, 1.7)
	end,
	fire = function(self, t)
		return self:combatTalentScale(t, 50, 80)
	end,
	heat = 0, -- Make you learn heat pool.
	heat_gain = 25,
	target = function(self, t)
		return {type = 'hit', range = util.getval(t.range, self, t), talent = t,}
	end,
	action = function(self, t)
		local _
		local tg = util.getval(t.target, self, t)
		local x, y = self:getTarget(tg)
		if not x or not y then return end
		_, x, y = self:canProject(tg, x, y)
		local actor = game.level.map(x, y, ACTOR)
		if not actor then return end

		local damage = self:heatScale(util.getval(t.damage, self, t) - 1) + 1
		local fire = util.bound(self:getHeat() * 0.01 * util.getval(t.fire, self, t), 0, 100)

		-- Add fire conversion to weapons.
		local f = eutil.attr_changer(fire)
		local mainhand = eutil.get(self:getInven('MAINHAND'), 1, 'combat')
		local offhand = eutil.get(self:getInven('OFFHAND'), 1, 'combat')
		local psionic = eutil.get(self:getInven('PSIONIC_FOCUS'), 1, 'combat')
		if mainhand then eutil.update(f, mainhand, 'convert_damage', 'FIRE') end
		if offhand then eutil.update(f, offhand, 'convert_damage', 'FIRE') end
		if psionic then eutil.update(f, psionic, 'convert_damage', 'FIRE') end

		if self:attackTarget(actor, nil, damage) then
			self:incHeat(util.getval(t.heat_gain, self, t))
		end

		-- Remove fire conversion from weapons.
		f = eutil.attr_changer(-fire)
		if mainhand then eutil.update(f, mainhand, 'convert_damage', 'FIRE') end
		if offhand then eutil.update(f, offhand, 'convert_damage', 'FIRE') end
		if psionic then eutil.update(f, psionic, 'convert_damage', 'FIRE') end

		return true
	end,
	info = function(self, t)
		local damage = util.getval(t.damage, self, t) * 100
		local fire = util.getval(t.fire, self, t)
		return ([[Strike the target enemy for %d%% <%d%%> weapon damage, %d%% <%d%%> of which is converted to fire damage. If this hits, gain %d heat.
Damage increases with strength and heat.
#GREY#Numbers shown are for 100%% heat, numbers in <brackets> are the actual amounts based on your current heat.]])
			:format(self:heatScale(damage - 100, 100) + 100,
							self:heatScale(damage - 100) + 100,
							fire,
							util.bound(self:getHeat() * 0.01 * fire, 0, 100),
							util.getval(t.heat_gain, self, t))
	end,}

newTalent {
	name = 'Blazes',
	type = {'elemental/brand', 2,},
	require = make_require(2),
	points = 5,
	mode = 'sustained',
	base_heat_regen = -5,
	min_heat_regen = -5,
	hit_heat_regen = 5,
	cooldown = 26,
	power = function(self, t) return self:elementalScale(t, 'str', 8, 18) end,
	fire = function(self, t) return self:elementalScale(t, 'str', 16, 48) end,
	activate = function(self, t)
		local p = {}
		self:talentTemporaryValue(p, 'combat_dam', util.getval(t.power, self, t))
		self:talentTemporaryValue(p, 'melee_project_percent', {
																FIRE = self:heatScale(util.getval(t.fire, self, t))})
		self:talentTemporaryValue(p, 'base_heat_regen', util.getval(t.base_heat_regen, self, t))
		self:talentTemporaryValue(p, 'min_heat_regen', util.getval(t.min_heat_regen, self, t))
		self:talentTemporaryValue(p, 'hit_heat_regen', util.getval(t.hit_heat_regen, self, t))
		return p
	end,
	deactivate = function(self, t) return true end,
	info = function(self, t)
		local fire = util.getval(t.fire, self, t)
		return ([[Increases your physical power by %d and adds an additional %d%% <%d%%> fire damage to your weapon attacks.
This costs %d heat per turn, but you will gain a net %d heat on any turn on which you deal damage.
Scales with Strength.
#GREY#Numbers shown are for 100%% heat, numbers in <brackets> are the actual amounts based on your current heat.]])
			:format(util.getval(t.power, self, t),
							self:heatScale(fire, 100),
							self:heatScale(fire),
							-util.getval(t.base_heat_regen, self, t),
							util.getval(t.hit_heat_regen, self, t))
	end,}

newTalent {
	name = 'Relentless Fires',
	type = {'elemental/brand', 3,},
	require = make_require(3),
	points = 5,
	cooldown = 9,
	tactical = {ATTACK = 3,},
	range = 1,
	hits = 5,
	damage = function(self, t) return self:elementalScale(t, 'str', 0.2, 0.4) end,
	heat_gain = 4,
	action = function(self, t)
		local tg = {type = 'ball', range = 0, radius = util.getval(t.range, self, t), selffire = false,}
		local actors = {}
		local is_hostile = function(target) return self:reactionToward(target) < 0 end
		self:project(tg, self.x, self.y, eutil.actor_grabber(actors, is_hostile))

		if #actors == 0 then return end

		local damage = self:heatScale(util.getval(t.damage, self, t) - 0.1) + 0.1
		local heat_gain = util.getval(t.heat_gain, self, t)
		for i = 1, util.getval(t.hits, self, t) do
			local actor = rng.table(actors)
			if self:attackTarget(actor, nil, damage, true) then
				self:incHeat(heat_gain)
			end
			if actor.dead then table.removeFromList(actors, actor) end
			if #actors == 0 then break end
		end

		return true
	end,
	info = function(self, t)
		local damage = util.getval(t.damage, self, t) * 100
		return ([[Randomly strikes nearby enemies %d times for %d%% <%d%%> weapon damage, gaining %d heat for every hit.
Scales with strength.
#GREY#Numbers shown are for 100%% heat, numbers in <brackets> are the actual amounts based on your current heat.]])
			:format(util.getval(t.hits, self, t),
							self:heatScale(damage - 10, 100) + 10,
							self:heatScale(damage - 10) + 10,
							util.getval(t.heat_gain, self, t))
	end,}

newTalent {
	name = 'Eruption',
	type = {'elemental/brand', 4,},
	require = make_require(4),
	points = 5,
	cooldown = 36,
	tactical = {ATTACKAREA = 3,},
	range = 1,
	fire = function(self, t) return self:elementalScale(t, 'str', 10, 17) end,
	duration = function(self, t) return math.floor(self:combatTalentScale(t, 2, 5)) end,
	heat_gain = 100,
	action = function(self, t)
		self:resetHeat()
		self:incHeat(util.getval(t.heat_gain, self, t))
		self:setEffect('EFF_ERUPTION', util.getval(t.duration, self, t), {
										 fire = util.getval(t.fire, self, t),})
		game:playSoundNear(self, 'talents/fire')
		return true
	end,
	info = function(self, t)
		return ([[Instantly heats up, increasing all fire damage done by %d%% for %d turns.
Damage scales with strength.]])
			:format(util.getval(t.fire, self, t),
							util.getval(t.duration, self, t))
	end,}
