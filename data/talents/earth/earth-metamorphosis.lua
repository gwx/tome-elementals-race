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
local stats = require 'engine.interface.ActorStats'

newTalentType {
	type = 'elemental/earth-metamorphosis',
	name = 'Metamorphosis',
	description = 'Strength of Stone',
	allow_random = true,}

local make_require = function(tier)
	return {
		stat = {con = function(level) return 12 + tier * 8 + level * 2 end,},
		level = function(level) return 5 + tier * 4 + level end,}
end

newTalent {
	name = 'Temper Weapon',
	type = {'elemental/earth-metamorphosis', 1,},
	require = make_require(1),
	points = 5,
	mode = 'passive',
	physical = function(self, t)
		return self:combatTalentScale(t, 10, 25)
	end,
	unarmed = function(self, t)
		return 12 + self:getStr(12, true)
	end,
	mace = function(self, t)
		return 7 + self:getStr(7, true)
	end,
	greatmaul = function(self, t)
		return 11 + self:getStr(11, true)
	end,
	staff = function(self, t)
		return 9 + self:getMag(9, true)
	end,
	-- Recomputed in onWear/onTakeoff.
	passives = function(self, t, p)
		local power = util.getval(t.physical, self, t)
		self:talentTemporaryValue(p, 'inc_damage', {
																[DamageType.PHYSICAL] = power})

		-- We can just stick the glove bonus on the actor's combat table
		-- directly. This also means it'll apply to unarmed strikes
		-- properly even if we're wearing a weapon.
		local unarmed = {atk = util.getval(t.unarmed, self, t),}
		self:talentTemporaryValue(p, 'combat', unarmed)

		local type = eutil.get(self:getInven 'MAINHAND', 1, 'subtype')

		if type == 'mace' then
			local power = util.getval(t.mace, self, t)
			self:talentTemporaryValue(p, 'combat_critical_power', power)
			self:talentTemporaryValue(p, 'combat_physcrit', power)
		elseif type == 'greatmaul' then
			self:talentTemporaryValue(p, 'combat_apr', util.getval(t.greatmaul, self, t))
		elseif type == 'staff' then
			local power = util.getval(t.staff, self, t)
			local bonus = {
				[DamageType.NATURE] = power,
				[DamageType.FIRE] = power,}
			self:talentTemporaryValue(p, 'inc_damage', bonus)
			self:talentTemporaryValue(p, 'resists_pen', bonus)
		end
	end,
	recompute_passives = {stats = {stats.STAT_STR, stats.STAT_MAG,},},
	info = function(self, t)
		return ([[Your mastery over density and weight allows it to tune the weight and grave power of all stone it commands, increasing all physical damage done by %d%%.

Also gives an extra bonus to melee combat depending on the type of weapon used:
Gloves/Unarmed: Accuracy increased by %d. (Scales with strength)
Mace: Increases critical chance and multiplier by %d%%. (Scales with strength)
Greatmaul: Increases armor penetration by %d. (Scales with strength)
Staves: Increase all nature/fire damage done nature/fire penetration by %d%%. (Scales with magic)]])
			:format(util.getval(t.physical, self, t),
							util.getval(t.unarmed, self, t),
							util.getval(t.mace, self, t),
							util.getval(t.greatmaul, self, t),
							util.getval(t.staff, self, t))
	end,}
