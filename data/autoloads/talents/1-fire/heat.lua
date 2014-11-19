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
local stats = require 'engine.interface.ActorStats'

newTalentType {
	type = 'elemental/heat',
	name = 'Heat',
	description = 'Don\'t Touch',
	generic = true,
	allow_random = true,}

local make_require = function(tier)
	return {
		stat = {mag = function(level) return 2 + tier * 8 + level * 2 end,},
		level = function(level) return -5 + tier * 4 + level end,}
end

newTalent {
	name = 'Energy Forge',
	type = {'elemental/heat', 1,},
	require = make_require(1),
	points = 5,
	mode = 'passive',
	resist = function(self, t) return self:scale {low = 3, high = 8, t, 'spell',} end,
	heat_conversion = 50,
	armor = function(self, t) return self:scale {low = 4, high = 12, t, 'spell',} end,
	hardiness = function(self, t) return self:scale {low = 10, high = 20, t, 'spell',} end,
	passives = function(self, t, p)
		local convert = get(t.heat_conversion, self, t)
		local conversions = {FIRE = convert, LIGHTNING = convert, ARCANE = convert, LIGHT = convert,}
		self:talentTemporaryValue(p, 'resist_heat_conversions', conversions)
		local resist = get(t.resist, self, t)
		local resists = {FIRE = resist, LIGHTNING = resist, ARCANE = resist, LIGHT = resist,}
		self:talentTemporaryValue(p, 'resists', resists)
		self:talentTemporaryValue(p, 'combat_armor', get(t.armor, self, t))
		self:talentTemporaryValue(p, 'combat_armor_hardiness', get(t.hardiness, self, t))
	end,
	recompute_passives = {stats = {stats.STAT_MAG,},
												attributes = {'combat_spellpower',},},
	info = function(self, t)
		return ([[Grants %d%% #SLATE#[*, spell]#LAST# resistance to #LIGHT_RED#Fire#LAST#, #ROYAL_BLUE#Lightning#LAST#, #PURPLE#Arcane#LAST#, and #YELLOW#Light#LAST#. %d%% of resisted damage of those types is absorbed as #FF6100#heat#LAST#. Also increases your armor by %d #SLATE#[*, spell]#LAST# and armor hardiness by %d%% #SLATE#[*, spell]#LAST#.]])
			:format(
				get(t.resist, self, t),
				self:heatGain(get(t.heat_conversion, self, t)),
				get(t.armor, self, t),
				get(t.hardiness, self, t))
	end,}

newTalent {
	name = 'Spark of Defiance',
	type = {'elemental/heat', 2,},
	require = make_require(2),
	points = 5,
	mode = 'passive',
	power_base = 1,
	power_heat = 0.005,
	reflect = function(self, t) return self:scale {low = 0.3, high = 0.5, t,} end,
	cooldown = 16,
	cooldown_heat = 100,
	max_heat = function(self, t) return self:scale{low = 10, high = 30, t, after = 'floor',} end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, 'max_heat', get(t.max_heat, self, t))
	end,
	info = function(self, t)
		local heat = self:getHeat()
		local power_base = get(t.power_base, self, t)
		local power_heat = get(t.power_heat, self, t)
		return ([[You burn brighter every time somebody tries to put you out. Every challenge is answered in overwhelming tones.
Passing a save will roll %d%% <%d%%> of your associated power against the enemy's save. Successful roll will not only negate the effect, but reflect it at %d%% #SLATE#[*]#LAST# power. #SLATE#Unimplemented:(Any damage reflected is converted into fire.)#WHITE#
This effect has a cooldown of %d turns, but cools down twice as fast if your heat is %d or more.
Also increases your maximum Heat by %d #SLATE#[*]#LAST#.
#SLATE#Numbers shown are for 100%% heat, numbers in <brackets> are the actual amounts based on your current heat.]])
			:format((power_base + 100 * power_heat) * 100,
							(power_base + heat * power_heat) * 100,
							get(t.reflect, self, t) * 100,
							get(t.cooldown, self, t),
							get(t.cooldown_heat, self, t),
							get(t.max_heat, self, t))
	end,}

newTalent {
	name = 'Consume',
	type = {'elemental/heat', 3,},
	require = make_require(3),
	points = 5,
	cooldown = 24,
	tactical = {HEAL = 3,},
	range = 0,
	power = function(self, t) return self:scale {low = 1, high = 2.2, t, 'spell',} end,
	duration = 4,
	heat_gain = 0.75,
	speed = 'spell',
	action = function(self, t)
		local heat = self:getHeat()
		self:incHeat(-heat)
		self:heal(self:spellCrit(heat * get(t.power, self, t)), self)
		local duration = get(t.duration, self, t)
		self:setEffect('EFF_CONSUMED_FLAME', duration, {
										 heat = get(t.heat_gain, self, t) * heat / duration,})
		game:playSoundNear(self, 'talents/fire')
		return true
	end,
	info = function(self, t)
		return ([[Consume all your #FF6100#heat#LAST# to heal %d%% #SLATE#[*, spell]#LAST# as much life.
Recovers %d%% of consumed heat over %d turns.]])
			:format(
				get(t.power, self, t) * 100,
				self:heatGain(get(t.heat_gain, self, t) * 100),
				get(t.duration, self, t))
	end,}

newTalent {
	name = 'Heat Overflow',
	type = {'elemental/heat', 4,},
	require = make_require(4),
	points = 5,
	mode = 'passive',
	power = function(self, t) return self:scale {low = 1, high = 1.7, t, 'spell',} end,
	radius = function(self, t) return self:scale {low = 1.5, high = 4.5, t, after = 'floor',} end,
	callbackOnWait = function(self, t)
		if self:attr('heat_overflow') then
			local tg = {type = 'ball', range = 0, radius = get(t.radius, self, t),
									talent = t, selffire = false,}
			self:project(tg, self.x, self.y, 'FIRE', get(t.power, self, t) * self.heat_overflow)
			game:playSoundNear(self, 'talents/fire')
			game.level.map:particleEmitter(self.x, self.y, tg.radius, 'ball_fire', {radius = tg.radius,})
		end
		self.heat_overflow = 0
	end,
	info = function(self, t)
		return ([[Your fiery touch knows no bound - should you gain heat in excess of your maximum heat, this unused heat will scorch all enemies in radius %d #SLATE#[*]#LAST# with %d%% #SLATE#[*, spell]#LAST# as much #LIGHT_RED#fire#LAST# damage.]])
			:format(
				get(t.radius, self, t),
				get(t.power, self, t) * 100)
	end,}
