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
local eutil = require 'elementals-race.util'
local hook

-- Actor:takeHit
hook = function(self, data)
	local value = data.value
	local src = data.src
	local damtype = eutil.get(data, 'death_note', 'damtype')

	-- Jagged Body
	if value > 0 and self:knowTalent('T_JAGGED_BODY') then
		local blocked = math.min(self.jaggedbody, value)
		self.jaggedbody = self.jaggedbody - blocked
		value = value - blocked
		game:delayedLogDamage(
			src, self, 0, ('#SLATE#(%d absorbed)#LAST#'):format(blocked), false)

		if damtype == DamageType.PHYSICAL and
			src.x and src.y and not src.dead and
			not self.jaggedbody_reflecting
		then
			self.jaggedbody_reflecting = true

			local reflected = self.jaggedbody_reflect * blocked
			src:takeHit(reflected, self)

			game:delayedLogDamage(
				self, src, reflected,
				('#SLATE#%d reflected#LAST#'):format(reflected), false)
			game:delayedLogMessage(
				self, src, 'reflection',
				'#CRIMSON##Source# reflects damage back to #Target#!#LAST#')

			self.jaggedbody_reflecting = nil
		end
	end

	data.value = value
	return true
end
class:bindHook('Actor:takeHit', hook)

-- Actor:preUseTalent
hook = function(self, data)
	local ab, silent = data.t, data.silent
	-- Check for essence requirements.
	if not self:attr('force_talent_ignore_ressources') then
		if ab.essence and (100 * self:getEssence() / self:getMaxEssence()) < ab.essence then
			if not silent then
				game.logPlayer(self, "You do not have enough essence to cast %s.", ab.name)
			end
			return true
		end
	end
end
class:bindHook('Actor:preUseTalent', hook)

-- Actor:postUseTalent
hook = function(self, data)
	local ab, trigger = data.t, data.trigger
	-- Use up essence
	if not self:attr('force_talent_ignore_ressources') then
		if ab.essence and not self:attr('zero_resource_cost') then
			trigger = true
			local value = util.getval(ab.essence, self, ab) * 0.01 * self:getMaxEssence()
			self:incEssence(-value)
			self:incJaggedbody(value * 0.33)
		end
	end
	data.trigger = trigger
	return true
end
class:bindHook('Actor:postUseTalent', hook)
