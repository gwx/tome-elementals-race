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
	type = 'elemental/erosion',
	name = 'Erosion',
	generic = true,
	description = 'Sand is more dangerous than you think',
	allow_random = true,}

local make_require = function(tier)
	return {
		stat = {con = function(level) return 2 + tier * 8 + level * 2 end,},
		level = function(level) return -5 + tier * 4 + level end,}
end

newTalent {
	name = 'Sharkskin',
	type = {'elemental/erosion', 1,},
	require = make_require(1),
	points = 5,
	mode = 'passive',
	duration = 5,
	stacks = function(self, t)
		return math.floor(self:combatTalentScale(t, 10, 15) * (0.5 + self:getCon(0.5, true)))
	end,
	defense = function(self, t)
		return self:combatTalentScale(t, 3, 7) * (0.5 + self:getCon(0.5, true))
	end,
	power = function(self, t) return 2 + self:getCon(2, true) end,
	disarm = function(self, t)
		return math.floor(self:combatTalentScale(t, 2, 6) * (0.5 + self:getCon(0.5, true)))
	end,
	disarm_cooldown = 5,
	on_hit = function(self, t)
		self:setEffect('EFF_SHARKSKIN', util.getval(t.duration, self, t), {
										 amount = 1,
										 max = util.getval(t.stacks, self, t),
										 defense = util.getval(t.defense, self, t),
										 power = util.getval(t.power, self, t),
										 disarm_cooldown = util.getval(t.disarm_cooldown, self, t),
										 disarm = util.getval(t.disarm, self, t),})
	end,
	info = function(self, t)
		return ([[Your 'skin' has dried and cracked, forming a rough mesh of hooked scales if put to stress. Every time you are hit with a melee or archery attack, you gain a stack of Sharkskin for %d turns, up to %d stacks.
Each stack gives %d points to ranged defense and increases physical power by %d. Any enemy that lands a critical melee strike, up to once every %d turns, must pass a physical power check against your physical save or be disarmed for %d turns.
Defense, physical power, disarm duration and maximum stacks scale with constitution.]])
			:format(util.getval(t.duration, self, t),
							util.getval(t.stacks, self, t),
							util.getval(t.defense, self, t),
							util.getval(t.power, self, t),
							util.getval(t.disarm_cooldown, self, t),
							util.getval(t.disarm, self, t))
	end,}
