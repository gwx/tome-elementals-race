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


local hook = function(self, data)
	if self.name ~= 'last-hope-weapon-store' then return end
	local training = self:get('training').answers
	for _, v in pairs(training) do
		if v[1] == 'Please train me in generic weapons and armour usage.' then
			local original = v.cond
			v.cond = function(npc, player)
				if player.forbid_combat_training then return end
				return original(npc, player)
			end
			break
		end
	end
end
class:bindHook('Chat:load', hook)
