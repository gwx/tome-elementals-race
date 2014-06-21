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
local damage_type = require 'engine.DamageType'
local stats = require 'engine.interface.ActorStats'

newTalentType {
	type = 'elemental/pyrokinesis',
	name = 'Pyrokinesis',
	description = 'FIRE',
	allow_random = true,}

local make_require = function(tier)
	return {
		stat = {mag = function(level) return 2 + tier * 8 + level * 2 end,},
		level = function(level) return -5 + tier * 4 + level end,}
end

newTalent {
	name = 'Ignite',
	type = {'elemental/pyrokinesis', 1,},
	require = make_require(1),
	points = 5,
	cooldown = 3,
	heat_gain = function(self, t) return self:combatTalentScale(t, 20, 30) end,
	damage = function(self, t) return self:combatTalentSpellDamage(t, 20, 100) end,
	radius = 1,
	range = 5,
	duration = 3,
	target = function(self, t)
		return {type = 'ball', talent = t, selffire = false,
						range = util.getval(t.range, self, t),
						radius = util.getval(t.radius, self, t),}
	end,
	action = function(self, t)
		local tg = util.getval(t.target, self, t)
		local x, y, actor = self:getTarget(tg)
		if not x or not y or not actor then return end
		if core.fov.distance(self.x, self.y, x, y) > tg.range then return end

		local damage = self:spellCrit(self:heatScale(util.getval(t.damage, self, t)))
		self:project(tg, x, y, 'FIRE', damage)
		local duration = util.getval(t.duration, self, t)
		actor:setEffect('EFF_BURNING', duration, {src = self, power = damage,})

		self:incHeat(util.getval(t.heat_gain, self, t))

		game.level.map:particleEmitter(x, y, tg.radius + 0.5, 'ball_fire', {radius = tg.radius + 0.5,})
		game:playSoundNear(actor, 'talents/fire')
		return true
	end,
	info = function(self, t)
		local damage = self:spellCrit(self:heatScale(util.getval(t.damage, self, t)))
		return ([[Sets the target on fire, dealing %d <%d> fire damage in radius %d, burning the center target for the same amount of damage each turn for %d turns.
This recovers %d heat.
#GREY#Numbers shown are for 100%% heat, numbers in <brackets> are the actual amounts based on your current heat.]])
			:format(Talents.damDesc(self, 'FIRE', self:heatScale(damage, 100)),
							Talents.damDesc(self, 'FIRE', self:heatScale(damage)),
							util.getval(t.radius, self, t),
							util.getval(t.duration, self, t),
							util.getval(t.heat_gain, self, t))
	end,}

newTalent {
	name = 'Radiation',
	type = {'elemental/pyrokinesis', 2,},
	require = make_require(2),
	mode = 'sustained',
	points = 5,
	cooldown = 26,
	heat_gain = 2,
	damage = function(self, t) return self:combatTalentSpellDamage(t, 5, 30) end,
	radius = function(self, t, heat) return 1 + math.ceil((heat or self.heat) / 25) end,
	range = 0,
	target = function(self, t)
		return {type = 'ball', talent = t, selffire = false,
						range = util.getval(t.range, self, t),
						radius = util.getval(t.radius, self, t),}
	end,
	activate = function(self, t) return {} end,
	deactivate = function(self, t) return true end,
	callbackOnActBase = function(self, t, p)
		local tg = util.getval(t.target, self, t)

		local indirect = self.indirect_damage
		self.indirect_damage = true
		local damage = self:spellCrit(self:heatScale(util.getval(t.damage, self, t)))
		local heat_gain = util.getval(t.heat_gain, self, t)
		local heat = 0
		local projector = function(x, y, tg, self)
			local actor = game.level.map(x, y, ACTOR)
			if not actor then return end
			heat = heat + heat_gain
			damage_type:get('FIRE').projector(self, x, y, 'FIRE', damage)
			--game.level.map:particleEmitter(x, y, 0.5, 'ball_fire', {radius = 0.5,})
		end
		self:project(tg, self.x, self.y, projector)
		self.indirect_damage = indirect

		self:incHeat(heat)

		game.level.map:particleEmitter(self.x, self.y, tg.radius + 0.5, 'ball_fire', {radius = tg.radius + 0.5,})
		game:playSoundNear(actor, 'talents/fire')
		return true
	end,
	info = function(self, t)
		local damage = util.getval(t.damage, self, t)
		return ([[Unleashes fiery rage as an aura of intense heat, burning all enemies in radius %d <%d> dealing %d <%d> fire damage. You will get %d heat for every enemy hit. This talent will not reset your heat loss.
#GREY#Numbers shown are for 100%% heat, numbers in <brackets> are the actual amounts based on your current heat.]])
			:format(util.getval(t.radius, self, t, 100),
							util.getval(t.radius, self, t),
							Talents.damDesc(self, 'FIRE', self:heatScale(damage, 100)),
							Talents.damDesc(self, 'FIRE', self:heatScale(damage)),
							util.getval(t.heat_gain, self, t))
	end,}
