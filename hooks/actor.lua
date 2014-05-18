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


local DamageType = require 'engine.DamageType'
local util = require 'elementals-race.util'
local hook

hook = function(self, data)
	local value = data.value
	local src = data.src
	local damtype = util.get(data, 'death_note', 'damtype')

	-- Jagged Body
	if value > 0 and self.jagged_body then
		local blocked = math.min(self.jagged_body, value)
		self.jagged_body = self.jagged_body - blocked
		value = value - blocked
		game:delayedLogDamage(
			src, self, 0, ('#SLATE#(%d absorbed)#LAST#'):format(blocked), false)

		if damtype == DamageType.PHYSICAL and
			src.x and src.y and not src.dead and
			not self.jagged_body_reflecting
		then
			self.jagged_body_reflecting = true

			local reflected = self.jagged_body_reflect * blocked
			src:takeHit(reflected, self)

			game:delayedLogDamage(
				self, src, reflected,
				('#SLATE#%d reflected#LAST#'):format(reflected), false)
			game:delayedLogMessage(
				self, src, 'reflection',
				'#CRIMSON##Source# reflects damage back to #Target#!#LAST#')

			self.jagged_body_reflecting = nil
		end
	end

	data.value = value
	return true
end
class:bindHook('Actor:takeHit', hook)

hook = function(self, data)
	if self.jagged_body_regen then
		self.jagged_body = math.min((self.jagged_body or 0) + self.jagged_body_regen,
																self.max_jagged_body)
	end
	return true
end
class:bindHook('Actor:actBase:Effects', hook)
