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


local _M = loadPrevious(...)

-- Add T_HEAVY_ARMS to weapon masteries.
for _, x in pairs {'axe', 'mace', 'sword', 'unarmed',} do
	_M:addCombatTraining(x, 'T_HEAVY_ARMS')
end

-- Make combat training pick the strongest one
function _M:combatGetTraining(weapon)
	if not weapon then return end
	if not weapon.talented then return end
	if not _M.weapon_talents[weapon.talented] then return end
	if type(_M.weapon_talents[weapon.talented]) == "table" then
    local max, ktid = nil, nil
    for i, tid in ipairs(_M.weapon_talents[weapon.talented]) do
      if self:knowTalent(tid) then
        local t = self:getTalentFromId(tid)
				-- Workaround for addons that don't implement getWeaponPower
				local strength = self:getTalentLevel(t)
				if t.getWeaponPower then
					strength = t.getWeaponPower(self, t, weapon)
				end
        if not max or strength > max then
          max = strength
          ktid = tid
        end
      end
    end
		return self:getTalentFromId(ktid)
	else
		return self:getTalentFromId(_M.weapon_talents[weapon.talented])
	end
end

-- Get the combat training with the strongest power
_M.combatCheckTraining = function(self, weapon)
	local t = self:combatGetTraining(weapon)
	if not t then return 0 end
	return (t.getWeaponPower or self.getTalentLevel)(self, t, weapon)
end

-- Reduce ranged accuracy.
local combatAttackRanged = _M.combatAttackRanged
function _M:combatAttackRanged(weapon, ammo)
	local base = self.combat_atk or 0
	local ranged = self.combat_ranged_atk or 0
	self.combat_atk = base + ranged
	local atk = combatAttackRanged(self, weapon, ammo)
	self.combat_atk = base
	return atk
end

return _M
