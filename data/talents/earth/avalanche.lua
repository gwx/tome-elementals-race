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


newTalentType {
	type = 'elemental/avalanche',
	name = 'Avalanche',
	description = 'Physical Caster',}

local make_require = function(tier)
	return {
		stat = {str = function(level) return 2 + tier * 8 + level * 2 end,},
		level = function(level) return -5 + tier * 4 + level end,}
end

newTalent {
	name = 'Heavy Arms',
	type = {'elemental/avalanche', 1,},
	require = make_require(1),
	points = 5,
	mode = 'passive',
	getWeaponPower = function(self, t) return self:getTalentLevel(t) * 0.7 end,
	getDamage = function(self, t) return t.getWeaponPower(self, t) * 10 end,
	getPercentInc = function(self, t)
		return math.sqrt(t.getWeaponPower(self, t) / 5) / 2
	end,
	daze = function(self, t) return 10 + self:getStr(15, true) end,
	info = function(self, t)
		return ([[The Jadir's body gives it a huge advantage when fighting in close quarters.
Increases physical power by %d and damage done by %d%% with standard weapons.
Also gives each blow a %d%% chance (scaling with Strength) to daze the enemy for 1 turn.]])
			:format(t.getDamage(self, t),
							t.getPercentInc(self, t) * 100,
							t.daze(self, t))
	end,}

newTalent {
	name = 'Pinpoint Toss',
	type = {'elemental/avalanche', 2,},
	require = make_require(1),
	points = 5,
	essence = 15,
	cooldown = 8,
	accuracy = function(self, t)
		return self:combatTalentScale(t, 10, 20) * (5 + self:getStr(5, true))
	end,
	damage = function(self, t)
		return self:combatTalentPhysicalDamage(t, 50, 300)
	end,
	range = function(self, t)
		return math.min(10, 3 + self:getStr(5))
	end,
	duration = function(self, t)
		return math.floor(self:combatTalentScale(self:getStr(5, true), 2, 5))
	end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, 'combat_atk', t.accuracy(self, t))
	end,
	action = function(self, t)
		return true
	end,
	info = function(self, t)
		return ([[Rip an enormous bulk of stone out of the ground and throw it, dealing %d physical damage and leaving a stone wall there for %d turns.
This also passively increases your accuracy by %d.
Cannot be used while in water or floating.
Damage, range, accuracy, and duration scale with Strength.]])
			:format(t.damage(self, t),
							t.duration(self, t),
							t.accuracy(self, t))
	end,}
