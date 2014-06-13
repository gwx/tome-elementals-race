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
local stats = require 'engine.interface.ActorStats'

newTalentType {
	type = 'elemental/heat',
	name = 'Heat',
	description = 'Don\'t Touch',
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
	resist = function(self, t) return self:elementalScalePower(t, 'spell', 3, 8) end,
	heat_conversion = 50,
	armor = function(self, t) return self:elementalScalePower(t, 'spell', 4, 12) end,
	hardiness = function(self, t) return self:elementalScalePower(t, 'spell', 10, 20) end,
	passives = function(self, t, p)
		local convert = util.getval(t.heat_conversion, self, t)
		local conversions = {FIRE = convert, LIGHTNING = convert, ARCANE = convert, LIGHT = convert,}
		self:talentTemporaryValue(p, 'resist_heat_conversions', conversions)
		local resist = util.getval(t.resist, self, t)
		local resists = {FIRE = resist, LIGHTNING = resist, ARCANE = resist, LIGHT = resist,}
		self:talentTemporaryValue(p, 'resists', resists)
		self:talentTemporaryValue(p, 'combat_armor', util.getval(t.armor, self, t))
		self:talentTemporaryValue(p, 'combat_armor_hardiness', util.getval(t.hardiness, self, t))
	end,
	recompute_passives = {stats = {stats.STAT_MAG,},
												attributes = {'combat_spellpower',},},
	info = function(self, t)
		return ([[Grants %d%% resistance to Fire, Lightning, Arcane, and Light. %d%% of resisted damage of those types is absorbed as heat. Also increases your armor by %d and armor hardiness by %d%%.
Scales with spellpower.]])
			:format(util.getval(t.resist, self, t),
							util.getval(t.heat_conversion, self, t),
							util.getval(t.armor, self, t),
							util.getval(t.hardiness, self, t))
	end,}

newTalent {
	name = 'Spark of Defiance',
	type = {'elemental/heat', 2,},
	require = make_require(2),
	points = 5,
	mode = 'passive',
	power_base = 1,
	power_heat = 0.005,
	reflect = function(self, t) return self:combatTalentScale(t, 0.3, 0.5) end,
	cooldown = 16,
	cooldown_heat = 100,
	max_heat = function(self, t) return math.floor(self:combatTalentScale(t, 10, 30)) end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, 'max_heat', util.getval(t.max_heat, self, t))
	end,
	info = function(self, t)
		local heat = self:getHeat()
		local power_base = util.getval(t.power_base, self, t)
		local power_heat = util.getval(t.power_heat, self, t)
		return ([[You burn brighter every time somebody tries to put you out. Every challenge is answered in overwhelming tones.
Passing a save will roll %d%% <%d%%> of your associated power against the enemy's save. Successful roll will not only negate the effect, but reflect it at %d%% power. #SLATE#Unimplemented:(Any damage reflected is converted into fire.)#WHITE#
This effect has a cooldown of %d turns, but cools down twice as fast if your heat is %d or more.
Also increases your maximum Heat by %d.
#GREY#Numbers shown are for 100%% heat, numbers in <brackets> are the actual amounts based on your current heat.]])
			:format((power_base + 100 * power_heat) * 100,
							(power_base + heat * power_heat) * 100,
							util.getval(t.reflect, self, t) * 100,
							util.getval(t.cooldown, self, t),
							util.getval(t.cooldown_heat, self, t),
							util.getval(t.max_heat, self, t))
	end,}
