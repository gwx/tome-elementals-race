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


local stats = require 'engine.interface.ActorStats'

newTalentType {
	type = 'elemental/cliffside',
	name = 'Cliffside',
	--generic = true,
	description = 'Shields.',
	allow_random = true,}

local make_require = function(tier)
	return {
		stat = {str = function(level) return 2 + tier * 8 + level * 2 end,},
		level = function(level) return -5 + tier * 4 + level end,}
end

newTalent {
	name = 'Pestle',
	type = {'elemental/cliffside', 1,},
	require = make_require(1),
	points = 5,
	mode = 'passive',
	damage = function(self, t) return self:combatTalentScale(t, 1, 1.2) end,
	chance = function(self, t) return self:combatTalentScale(t, 35, 60) end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, 'block_always_counterstrike', 1)
	end,
	info = function(self, t)
		return ([[Every time you make a melee attack with your weapon, you have a %d%% chance to bash with your shield for %d%% damage. If this attack is a counterstrike, the bash is guaranteed and is a crushing blow (deals %d%% (half of your crit. power) more damage if it would be enough to bring the target to 0 or less life).
Allows counterstrikes after incomplete blocks.]])
			:format(util.getval(t.chance, self, t),
							util.getval(t.damage, self, t) * 100,
							25 + (self.combat_critical_power or 0) * 0.5)
	end,}
