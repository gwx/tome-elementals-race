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

newTalent {
	name = 'Microwave',
	type = {'elemental/power', 2,},
	require = make_require(2),
	points = 5,
	cooldown = 10,
	heat_gain = 40,
	lightning_damage = function(self, t, target)
		return self:combatTalentSpellDamage(t, 20, 120) *
			(100 + (target and target:combatArmor() or 0)) * 0.01
	end,
	fire_damage = function(self, t, lightning_damage, heat)
		return (lightning_damage or util.getval(t.lightning_damage, self, t)) * (heat or self.heat) * 0.005
	end,
	armor = function(self, t) return self:elementalScale(t, 'mag', 20, 50) end,
	duration = function(self, t) return 3 + math.floor(self:getMag(4, true)) end,
	range = 3,
	target = function(self, t)
		return {type = 'hit', talent = t, selffire = false,
						range = util.getval(t.range, self, t),}
	end,
	requires_target = true,
	action = function(self, t)
		local tg = util.getval(t.target, self, t)
		local x, y, actor = self:getTarget(tg)
		if not x or not y or not actor then return end
		if core.fov.distance(self.x, self.y, x, y) > tg.range then return end

		local lightning_damage = self:spellCrit(self:heatScale(util.getval(t.lightning_damage, self, t, actor)))
		local fire_damage = util.getval(t.fire_damage, self, t, lightning_damage)
		local armor = util.getval(t.armor, self, t)
		local duration = util.getval(t.duration, self, t)

		damage_type:get('LIGHTNING').projector(self, x, y, 'LIGHTNING', lightning_damage)
		damage_type:get('FIRE').projector(self, x, y, 'FIRE', fire_damage)
		actor:setEffect('EFF_COOKED', duration, {power = armor * actor:combatArmor() * 0.01,})
		self:incHeat(util.getval(t.heat_gain, self, t))

		game.level.map:particleEmitter(x, y, tg.radius, 'ball_lightning', {radius = tg.radius,})
		game:playSoundNear(actor, 'talents/lightning')
		return true
	end,
	info = function(self, t)
		return ([[Sends out electromagentic waves to cook the target enemy in range of 3 alive in their armor. Target takes %d <%d> lightning damage, %d <%d> fire damage,  and loses %d%% armour for %d turns.
This recovers %d heat if it hits anything.
Debuff strength and duration increase with magic, damage with target's armour and spellpower.
#GREY#Numbers shown are for 100%% heat, numbers in <brackets> are the actual amounts based on your current heat.]])
			:format(Talents.damDesc(self, 'LIGHTNING', self:heatScale(util.getval(t.lightning_damage, self, t), 100)),
							Talents.damDesc(self, 'LIGHTNING', self:heatScale(util.getval(t.lightning_damage, self, t))),
							Talents.damDesc(self, 'FIRE', self:heatScale(util.getval(t.fire_damage, self, t, nil, 100), 100)),
							Talents.damDesc(self, 'FIRE', self:heatScale(util.getval(t.fire_damage, self, t))),
							util.getval(t.armor, self, t),
							util.getval(t.duration, self, t),
							util.getval(t.heat_gain, self, t))
	end,}

newTalent {
	name = 'Lifepyre',
	type = {'elemental/power', 3,},
	require = make_require(3),
	points = 5,
	cooldown = 26,
	heat_gain = 40,
	healing = function(self, t) return self:combatTalentScale(t, 70, 90) end,
	duration = 2,
	smearing = function(self, t, heat)
		return math.max(2, 5 - math.floor((heat or self:getHeat()) / 40))
	end,
	action = function(self, t)
		self:incHeat(util.getval(t.heat_gain, self, t))
		local duration = util.getval(t.duration, self, t)
		self:setEffect('EFF_LIFEPYRE', duration, {
										 healing = util.getval(t.healing, self, t),
										 smearing = util.getval(t.smearing, self, t),})
		return true
	end,
	info = function(self, t)
		return ([[You undergo a rapid metamorphosis, absorbing any force that tries to harm you. For %d turns, heal %d%% of any damage you take #SLATE#(before resists)#LAST# over %d <%d> turns.
#GREY#Numbers shown are for 100%% heat, numbers in <brackets> are the actual amounts based on your current heat.]])
			:format(util.getval(t.duration, self, t),
							util.getval(t.healing, self, t),
							util.getval(t.smearing, self, t, 100),
							util.getval(t.smearing, self, t))
	end,}

newTalent {
	name = 'Charged Arms',
	type = {'elemental/power', 4,},
	require = make_require(4),
	points = 5,
	mode = 'passive',
	dammod = function(self, t) return math.floor(self:combatTalentScale(t, 20, 40)) end,
	crit_chance = function(self, t) return self:elementalScale(t, 'mag', 2, 16) end,
	crit_power = function(self, t) return self:elementalScale(t, 'mag', 4, 32) end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, 'bonus_dammod', {mag = 0.01 * util.getval(t.dammod, self, t),})
		local crit_chance = util.getval(t.crit_chance, self, t)
		self:talentTemporaryValue(p, 'combat_physcrit', crit_chance)
		self:talentTemporaryValue(p, 'combat_mindcrit', crit_chance)
		self:talentTemporaryValue(p, 'combat_spellcrit', crit_chance)
		self:talentTemporaryValue(p, 'combat_critical_power', util.getval(t.crit_power, self, t))
	end,
	recompute_passives = {stats = {stats.STAT_MAG,},},
	info = function(self, t)
		return ([[A touch of your hands charges up the weapons you carry with ambient forces. Grants an extra %d%% magic damage modifier to your attacks.
Also increases all your critical hit chances by %d%% and the multiplier by %d%%.
Critical hit chance and multiplier increase with magic.]])
			:format(util.getval(t.dammod, self, t),
							util.getval(t.crit_chance, self, t),
							util.getval(t.crit_power, self, t))
	end,}
