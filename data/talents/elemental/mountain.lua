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
	type = 'elemental/mountain',
	name = 'Mountain',
	generic = true,
	description = 'Tanking',}

local make_require = function(tier)
	return {
		stat = {con = function(level) return 2 + tier * 8 + level * 2 end,},
		level = function(level) return -5 + tier * 4 + level end,}
end

newTalent {
	name = 'Jagged Body',
	type = {'elemental/mountain', 1,},
	require = make_require(1),
	points = 5,
	mode = 'passive',
	no_unlearn_last = true,
	callbackOnRest = function(self)
		return self.jagged_body_regen > 0 and self.jagged_body < self.max_jagged_body
	end,
	power = function(self, t)
		return math.floor(
			(5 + self:getCon(5, true)) * self:combatTalentLimit(t, 25, 10, 20))
	end,
	reflect = function(self, t) return self:combatTalentScale(t, 0.15, 0.3) end,
	regen = function(self, t)
		return 0.02 * t.power(self, t)
	end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, 'max_jagged_body', t.power(self, t))
		if not self.jagged_body then self.jagged_body = self.max_jagged_body end
		self:talentTemporaryValue(p, 'jagged_body_reflect', t.reflect(self, t))
		self:talentTemporaryValue(p, 'jagged_body_regen', t.regen(self, t))
	end,
	info = function(self, t)
		return ('Your earthen body sprouts many sharp, rock-hard protrusions, blocking up to %d damage (scaling with Constitution) of any kind, recharging by 2%% per turn. In additon, %d%% of all physical damage this blocks will be returned to the attacker.')
			:format(t.power(self, t), t.reflect(self, t) * 100)
	end,}
