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

local get = util.getval
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
		return self:scale {low = 0, high = 100, t, 'spell', 20 + (self.lite or 2) * 8, after = 'damage',}
		end,
	fire_damage_mult = function(self, t, heat) return (heat or self.heat) * 0.5 end,
	stealth = function(self, t)
		return self:scale {low = 15, high = 50, t, 'mag',}
		end,
	accuracy = function(self, t)
		return self:scale {low = 10, high = 30, t, 'mag',}
		end,
	duration = function(self, t)
		return self:scale {low = 3, high = 7, 'mag', after = 'floor',}
		end,
	radius = function(self, t)
		return self:scale {low = 3, high = 5, t, after = 'floor',}
		end,
	range = 0,
	target = function(self, t)
		return {type = 'ball', talent = t, selffire = false,
			range = get(t.range, self, t),
			radius = get(t.radius, self, t),}
		end,
	speed = 'spell',
	action = function(self, t)
		local tg = get(t.target, self, t)

		local light_damage = self:spellCrit(self:heatScale(get(t.light_damage, self, t)))
		local fire_damage = get(t.fire_damage_mult, self, t) * light_damage * 0.01
		local stealth = get(t.stealth, self, t)
		local accuracy = get(t.accuracy, self, t)
		local duration = get(t.duration, self, t)
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

		if hit then self:incHeat(get(t.heat_gain, self, t)) end

		game.level.map:particleEmitter(self.x, self.y, tg.radius, 'sunburst', {radius = tg.radius,})
		game:playSoundNear(actor, 'talents/fire')
		return true
		end,
	info = function(self, t)
		local light_damage = get(t.light_damage, self, t)
		local fire_desc = self:damDesc('FIRE', 1) / self:damDesc('LIGHT', 1)
		return ([[Ripples out a wave of blinding light in radius %d #SLATE#[*]#LAST#, dealing %d <%d> #SLATE#[*, spell, crit, light radius]#LAST# #YELLOW#light#LAST# damage and %d%% <%d%%> as much #LIGHT_RED#fire#LAST# damage. Targets hit will be illuminated, losing %d #SLATE#[*, mag]#LAST# stealth power. Targets will either be #YELLOW#blinded#LAST# or lose %d #SLATE#[*, mag]#LAST# accuracy for %d #SLATE#[mag]#LAST# turns, depending on whether or not they pass a spell save.
This recovers #FF6100#%d heat#LAST# if it hits anything.
#SLATE#Numbers shown are for 100%% heat, numbers in <brackets> are the actual amounts based on your current heat.]])
			:format(
				get(t.radius, self, t),
				self:damDesc('LIGHT', self:heatScale(light_damage, 100)),
				self:damDesc('LIGHT', self:heatScale(light_damage)),
				self:heatScale(fire_desc * get(t.fire_damage_mult, self, t), 100),
				self:heatScale(fire_desc * get(t.fire_damage_mult, self, t)),
				get(t.stealth, self, t),
				get(t.accuracy, self, t),
				get(t.duration, self, t),
				self:heatGain(get(t.heat_gain, self, t)))
		end,}

newTalent {
	name = 'Microwave',
	type = {'elemental/power', 2,},
	require = make_require(2),
	points = 5,
	cooldown = 10,
	heat_gain = 40,
	speed = 'spell',
	lightning_damage = function(self, t, armor)
		return self:scale {low = 0, high = 160, t, 'spell', 25 + (armor or 0) * 1.5, after = 'damage',}
		end,
	fire_damage_mult = function(self, t, heat) return (heat or self.heat) * 0.5 end,
	armor = function(self, t) return self:scale {low = 20, high = 50, t, 'mag',} end,
	duration = function(self, t) return self:scale {low = 3, high = 7, 'mag', after = 'floor',} end,
	range = 3,
	target = function(self, t)
		return {type = 'hit', talent = t, selffire = false,
			range = get(t.range, self, t),}
		end,
	requires_target = true,
	action = function(self, t)
		local tg = get(t.target, self, t)
		local x, y, actor = self:getTarget(tg)
		if not x or not y or not actor then return end
		if core.fov.distance(self.x, self.y, x, y) > tg.range then return end

		local lightning_damage = self:spellCrit(self:heatScale(
				get(t.lightning_damage, self, t, actor:combatArmor())))
		local fire_damage = get(t.fire_damage_mult, self, t) * lightning_damage * 0.01
		local armor = get(t.armor, self, t)
		local duration = get(t.duration, self, t)

		damage_type:get('LIGHTNING').projector(self, x, y, 'LIGHTNING', lightning_damage)
		damage_type:get('FIRE').projector(self, x, y, 'FIRE', fire_damage)
		actor:setEffect('EFF_COOKED', duration, {power = armor * actor:combatArmor() * 0.01,})
		self:incHeat(get(t.heat_gain, self, t))

		game.level.map:particleEmitter(x, y, tg.radius, 'ball_lightning', {radius = tg.radius,})
		game:playSoundNear(actor, 'talents/lightning')
		return true
		end,
	info = function(self, t)
		local lightning_damage = get(t.lightning_damage, self, t)
		local fire_mult = self:damDesc('FIRE', 1) / self:damDesc('LIGHTNING', 1) * get(t.fire_damage_mult, self, t)
		return ([[Sends out electromagentic waves to cook the target enemy in range of %d alive in their armor. Target takes %d <%d> #SLATE#[*, spell, target's armor, crit]#LAST# #ROYAL_BLUE#lightning#LAST# damage, %d%% <%d%%> as much #LIGHT_RED#fire#LAST# damage, and loses %d%% #SLATE#[*, mag]#LAST# armour for %d #SLATE#[mag]#LAST# turns.
This recovers #FF6100#%d heat#LAST# if it hits anything.
#SLATE#Numbers shown are for 100%% heat, numbers in <brackets> are the actual amounts based on your current heat.]])
			:format(
				get(t.range, self, t),
				self:damDesc('LIGHTNING', self:heatScale(lightning_damage, 100)),
				self:damDesc('LIGHTNING', self:heatScale(lightning_damage)),
				self:heatScale(fire_mult, 100),
				self:heatScale(fire_mult),
				get(t.armor, self, t),
				get(t.duration, self, t),
				get(t.heat_gain, self, t))
		end,}

newTalent {
	name = 'Lifepyre',
	type = {'elemental/power', 3,},
	require = make_require(3),
	points = 5,
	cooldown = 26,
	heat_gain = 40,
	speed = 'spell',
	healing = function(self, t) return self:scale {low = 70, high = 90, t,} end,
	duration = 2,
	smearing = function(self, t, heat)
		return math.max(2, 5 - math.floor((heat or self:getHeat()) / 40))
		end,
	action = function(self, t)
		self:incHeat(get(t.heat_gain, self, t))
		local duration = get(t.duration, self, t)
		self:setEffect('EFF_LIFEPYRE', duration, {
				healing = get(t.healing, self, t),
				smearing = get(t.smearing, self, t),})
		return true
		end,
	info = function(self, t)
		return ([[You undergo a rapid metamorphosis, absorbing any force that tries to harm you. For %d turns, heal %d%% #SLATE#[*]#LAST# of any damage you take #SLATE#(before resists)#LAST# over %d <%d> turns.
#SLATE#Numbers shown are for 100%% heat, numbers in <brackets> are the actual amounts based on your current heat.]])
			:format(
				get(t.duration, self, t),
				get(t.healing, self, t),
				get(t.smearing, self, t, 100),
				get(t.smearing, self, t))
		end,}

newTalent {
	name = 'Charged Arms',
	type = {'elemental/power', 4,},
	require = make_require(4),
	points = 5,
	mode = 'passive',
	dammod = function(self, t) return self:scale {low = 20, high = 40, t, after = 'floor',} end,
	crit_chance = function(self, t) return self:scale {low = 2, high = 16, t, 'mag',} end,
	crit_power = function(self, t) return self:scale {low = 4, high = 32, t, 'mag',} end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, 'bonus_dammod', {mag = 0.01 * get(t.dammod, self, t),})
		local crit_chance = get(t.crit_chance, self, t)
		self:talentTemporaryValue(p, 'combat_physcrit', crit_chance)
		self:talentTemporaryValue(p, 'combat_mindcrit', crit_chance)
		self:talentTemporaryValue(p, 'combat_spellcrit', crit_chance)
		self:talentTemporaryValue(p, 'combat_critical_power', get(t.crit_power, self, t))
		end,
	recompute_passives = {stats = {stats.STAT_MAG,},},
	info = function(self, t)
		return ([[A touch of your hands charges up the weapons you carry with ambient forces. Grants an extra %d%% #SLATE#[*]#LAST# magic damage modifier to your attacks.
Also increases all your critical hit chances by %d%% #SLATE#[*, mag]#LAST# and the multiplier by %d%% #SLATE#[*, mag]#LAST#.]])
			:format(
				get(t.dammod, self, t),
				get(t.crit_chance, self, t),
				get(t.crit_power, self, t))
		end,}
