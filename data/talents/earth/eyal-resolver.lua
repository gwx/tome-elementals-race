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

newTalentType {
	type = 'elemental/eyal-resolver',
	name = 'Eyal Resolver',
	description = 'Unstoppable Boulder',}

local make_require = function(tier)
	return {
		stat = {str = function(level) return 2 + tier * 8 + level * 2 end,},
		level = function(level) return -5 + tier * 4 + level end,}
end

newTalent {
	name = 'Afterecho',
	type = {'elemental/eyal-resolver', 1,},
	require = make_require(1),
	points = 5,
	mode = 'passive',
	inc_damage = function(self, t)
		return self:combatTalentScale(t, 30, 70) * (0.5 + self:getStr(0.5, true))
	end,
	echo = function(self, t)
		return self:combatTalentScale(t, 0.25, 0.6) * (0.5 + self:getStr(0.5, true))
	end,
	-- Recomputed in onWear/onTakeoff.
	passives = function(self, t, p)
		if self:isUnarmed() then
			local inc_damage = {[DamageType.PHYSICAL] = util.getval(t.inc_damage, self, t),}
			self:talentTemporaryValue(p, 'inc_damage', inc_damage)
			self:talentTemporaryValue(p, 'physical_echo', util.getval(t.echo, self, t))
		end
	end,
	info = function(self, t)
		return ([[While unarmed:
Increases all physical damage done by %d%%.
Successful melee attacks will echo, hitting the space directly behind the target for %d%% of damage done.
Scales with strength.]])
			:format(util.getval(t.inc_damage, self, t),
							util.getval(t.echo, self, t) * 100)
	end,}
