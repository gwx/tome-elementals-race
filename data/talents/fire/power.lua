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
	type = 'elemental/power',
	name = 'Power',
	description = 'Burning Might',
	allow_random = true,}

local make_require = function(tier)
	return {
		stat = {mag = function(level) return 2 + tier * 8 + level * 2 end,},
		level = function(level) return -5 + tier * 4 + level end,}
end

newTalent {
	name = 'Shining Burst',
	type = {'elemental/power', 1,},
	require = make_require(1),
	points = 5,
	cooldown = 15,
	heat_gain = 40,
	light_damage = function(self, t)
		return self:combatTalentSpellDamage(t, 10, 70) * (10 + (self.lite or 2)) * 0.1
	end,
	fire_damage = function(self, t, light_damage, heat)
		return (light_damage or util.getval(t.light_damage, self, t)) * (heat or self.heat) * 0.005
	end,
	stealth = function(self, t)
		return self:elementalScale(t, 'mag', 15, 50)
	end,
	accuracy = function(self, t)
		return self:elementalScale(t, 'mag', 10, 30)
	end,
	duration = function(self, t)
		return 3 + math.floor(self:getMag(4, true))
	end,
	radius = function(self, t)
		return math.floor(self:combatTalentScale(t, 3, 5))
	end,
	range = 0,
	target = function(self, t)
		return {type = 'ball', talent = t, selffire = false,
						range = util.getval(t.range, self, t),
						radius = util.getval(t.radius, self, t),}
	end,
	action = function(self, t)
		local tg = util.getval(t.target, self, t)

		local light_damage = self:spellCrit(self:heatScale(util.getval(t.light_damage, self, t)))
		local fire_damage = util.getval(t.fire_damage, self, t, light_damage)
		local stealth = util.getval(t.stealth, self, t)
		local accuracy = util.getval(t.accuracy, self, t)
		local duration = util.getval(t.duration, self, t)
		local hit = false
		local projector = function(x, y, tg, self)
			local actor = game.level.map(x, y, ACTOR)
			if not actor then return end
			hit = true
			damage_type:get('LIGHT').projector(self, x, y, 'LIGHT', light_damage)
			damage_type:get('FIRE').projector(self, x, y, 'FIRE', fire_damage)
			actor:setEffect('EFF_LUMINESCENCE', duration, {power = stealth,})
			if actor:canBe 'blind' then
				if self:checkHit(self:combatSpellpower(), actor:combatSpellResist()) then
					actor:setEffect('EFF_BLINDED', duration, {})
				else
					actor:setEffect('EFF_PARTIALLY_BLINDED', duration, {power = accuracy,})
				end
			end
		end
		self:project(tg, self.x, self.y, projector)

		if hit then self:incHeat(util.getval(t.heat_gain, self, t)) end

		game.level.map:particleEmitter(self.x, self.y, tg.radius, 'sunburst', {radius = tg.radius,})
		game:playSoundNear(actor, 'talents/fire')
		return true
	end,
	info = function(self, t)
		return ([[Ripples out a wave of blinding light in radius %d, dealing %d <%d> light damage and %d <%d> fire damage. Targets hit will be illuminated, losing %d stealth power. Targets will either be blinded or lose %d accuracy for %d turns, depending on whether or not they pass a spell save.
This recovers %d heat if it hits anything.
Debuff strength and duration increase with magic, damage with light radius and spellpower.
#GREY#Numbers shown are for 100%% heat, numbers in <brackets> are the actual amounts based on your current heat.]])
			:format(util.getval(t.radius, self, t),
							Talents.damDesc(self, 'LIGHT', self:heatScale(util.getval(t.light_damage, self, t), 100)),
							Talents.damDesc(self, 'LIGHT', self:heatScale(util.getval(t.light_damage, self, t))),
							Talents.damDesc(self, 'FIRE', self:heatScale(util.getval(t.fire_damage, self, t, nil, 100), 100)),
							Talents.damDesc(self, 'FIRE', self:heatScale(util.getval(t.fire_damage, self, t))),
							util.getval(t.stealth, self, t),
							util.getval(t.accuracy, self, t),
							util.getval(t.duration, self, t),
							util.getval(t.heat_gain, self, t))
	end,}
