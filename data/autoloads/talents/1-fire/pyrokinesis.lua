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
local get = util.getval
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
	heat = function(self, t) return self:scale {low = -20, high = -30, t,} end,
	damage = function(self, t) return self:scale {low = 20, high = 100, t, 'spell', after = 'damage',}  end,
	radius = 1,
	range = 5,
	duration = 3,
	speed = 'spell',
	target = function(self, t)
		return {type = 'ball', talent = t, friendlyfire = false,
			range = get(t.range, self, t),
			radius = get(t.radius, self, t),}
		end,
	action = function(self, t)
		local tg = get(t.target, self, t)
		local x, y, actor = self:getTarget(tg)
		if not x or not y or not actor then return end
		if core.fov.distance(self.x, self.y, x, y) > tg.range then return end

		local damage = self:spellCrit(self:heatScale(get(t.damage, self, t)))
		self:project(tg, x, y, 'FIRE', damage)
		local duration = util.getval(t.duration, self, t)
		actor:setEffect('EFF_BURNING', duration, {src = self, power = damage,})

		game:playSoundNear(actor, 'talents/fire')
		return true
		end,
	info = function(self, t)
		local damage = util.getval(t.damage, self, t)
		return ([[Sets the target on fire, dealing %d <%d> #SLATE#[*, spell, crit]#LAST# #LIGHT_RED#fire#LAST# damage in radius %d, burning the center target for the same amount of damage each turn for %d turns.
This recovers %d #SLATE#[*]#LAST# #FF6100#heat#LAST#.
#SLATE#Numbers shown are for 100%% heat, numbers in <brackets> are the actual amounts based on your current heat.]])
			:format(self:damDesc('FIRE', self:heatScale(damage, 100)),
				self:damDesc('FIRE', self:heatScale(damage)),
				get(t.radius, self, t),
				get(t.duration, self, t),
				self:heatGain(-get(t.heat, self, t)))
		end,}

newTalent {
	name = 'Radiation',
	type = {'elemental/pyrokinesis', 2,},
	require = make_require(2),
	mode = 'sustained',
	points = 5,
	cooldown = 26,
	heat_gain = 2,
	damage = function(self, t) return self:scale {low = 5, high = 30, t, 'spell', after = 'damage',} end,
	radius = function(self, t, heat) return 1 + math.ceil((heat or self.heat) / 25) end,
	range = 0,
	target = function(self, t)
		return {type = 'ball', talent = t, friendlyfire = false,
			range = get(t.range, self, t),
			radius = get(t.radius, self, t),}
		end,
	speed = 'spell',
	activate = function(self, t) return {} end,
	deactivate = function(self, t) return true end,
	callbackOnActBase = function(self, t, p)
		local tg = get(t.target, self, t)

		local indirect = self.indirect_damage
		self.indirect_damage = true
		local damage = self:spellCrit(self:heatScale(get(t.damage, self, t)))
		local heat_gain = get(t.heat_gain, self, t)
		local heat = 0
		local projector = function(x, y, tg, self)
			local actor = game.level.map(x, y, ACTOR)
			if not actor then return end
			heat = heat + heat_gain
			damage_type:get('FIRE').projector(self, x, y, 'FIRE', damage)
			end
		self:project(tg, self.x, self.y, projector)
		self.indirect_damage = indirect

		self:incHeat(heat)

		game.level.map:particleEmitter(self.x, self.y, tg.radius + 0.5, 'ball_fire', {radius = tg.radius + 0.5,})
		game:playSoundNear(actor, 'talents/fire')
		return true
		end,
	info = function(self, t)
		local damage = get(t.damage, self, t)
		return ([[Unleashes fiery rage as an aura of intense heat, burning all enemies in radius %d <%d> dealing %d <%d> #SLATE#[*, spell, crit]#LAST# #LIGHT_RED#fire#LAST# damage. You will get #FF6100#%d heat#LAST# for every enemy hit. This talent will not reset your heat loss.
#SLATE#Numbers shown are for 100%% heat, numbers in <brackets> are the actual amounts based on your current heat.]])
			:format(get(t.radius, self, t, 100),
				get(t.radius, self, t),
				Talents.damDesc(self, 'FIRE', self:heatScale(damage, 100)),
				Talents.damDesc(self, 'FIRE', self:heatScale(damage)),
				get(t.heat_gain, self, t))
		end,}

newTalent {
	name = 'Explosion',
	type = {'elemental/pyrokinesis', 3,},
	require = make_require(3),
	points = 5,
	cooldown = 9,
	heat_gain = 50,
	damage = function(self, t) return self:scale {low = 30, high = 160, t, 'spell',} end,
	knockback = function(self, t, heat)
		return 2 + math.floor((heat or self.heat) / 50)
		end,
	range = 4,
	radius = 3,
	speed = 'spell',
	target = function(self, t)
		return {type = 'ball', talent = t, friendlyfire = false, nowarning = true,
			range = get(t.range, self, t),
			radius = get(t.radius, self, t),}
		end,
	action = function(self, t)
		local _
		local tg = get(t.target, self, t)
		local x, y, actor = self:getTarget(tg)
		if not x or not y then return end
		_, _, _, x, y = self:canProject(tg, x, y)

		local damage = self:spellCrit(self:heatScale(get(t.damage, self, t)))
		local knockback = get(t.knockback, self, t)
		local hit = false
		local projector = function(px, py, tg, self)
			local actor = game.level.map(px, py, ACTOR)
			if not actor then return end
			hit = true
			damage_type:get('PHYSICAL').projector(self, px, py, 'PHYSICAL', damage)
			damage_type:get('FIRE').projector(self, px, py, 'FIRE', damage)
			if px ~= x or py ~= y then actor:knockback(x, y, knockback) end
			end
		self:project(tg, x, y, projector)

		if hit then self:incHeat(get(t.heat_gain, self, t)) end

		game.level.map:particleEmitter(x, y, tg.radius, 'fireflash', {radius = tg.radius,})
		game:playSoundNear(actor, 'talents/fire')
		return true
		end,
	info = function(self, t)
		local damage = get(t.damage, self, t)
		return ([[Causes a localized, fiery explosion at target position, dealing %d <%d> #SLATE#[*, spell, crit]#LAST# physical and %d <%d> #SLATE#[*, spell, crit]#LAST# #LIGHT_RED#fire#LAST# damage to all targets in radius %d. #SLATE#(Both damages crit together.)#LAST# Those hit are knocked back from the explosion point by %d <%d> tiles.
This recovers #FF6100#%d heat#LAST# if it hits anything.
#SLATE#Numbers shown are for 100%% heat, numbers in <brackets> are the actual amounts based on your current heat.]])
			:format(
				self:damDesc('PHYSICAL', self:heatScale(damage, 100)),
				self:damDesc('PHYSICAL', self:heatScale(damage)),
				self:damDesc('FIRE', self:heatScale(damage, 100)),
				self:damDesc('FIRE', self:heatScale(damage)),
				get(t.radius, self, t),
				get(t.knockback, self, t, 100),
				get(t.knockback, self, t),
				self:heatGain(get(t.heat_gain, self, t)))
		end,}

newTalent {
	name = 'Lingering Fires',
	type = {'elemental/pyrokinesis', 4,},
	require = make_require(4),
	points = 5,
	mode = 'passive',
	min_heat = function(self, t) return self:scale {low = 5, high = 40, t, 'spell',} end,
	damage_scale = function(self, t) return self:scale {low = 0.4, high = 1.0, t, 'spell'} end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, 'heat_rest', get(t.min_heat, self, t))
		self:talentTemporaryValue(p, 'heat_absorb_damage_ratio', get(t.damage_scale, self, t))
		end,
	recompute_passives = {
		stats = {stats.STAT_MAG,},
		attributes = {'combat_spellpower',},},
	info = function(self, t)
		return ([[Your body never truly cools down. Prevents heat degeneration from dropping you below #FF6100#%d heat#WHITE#.
If you would take damage that would kill you, it will instead reduce your heat by %d%% #SLATE#[*, spell]#LAST# of the damage taken. If this makes you run out of heat, you really do die.]])
			:format(
				get(t.min_heat, self, t),
				100 / get(t.damage_scale, self, t))
		end,}
