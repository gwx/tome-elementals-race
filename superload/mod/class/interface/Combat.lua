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

-- Add in the conversion resists
local combatGetResist = _M.combatGetResist
function _M:combatGetResist(type)
	local add = 0
	local conversions = eutil.get(self, 'conversion_resists', type)
	if conversions and not conversions.__disabled then
		-- Disable to get rid of potential infinite loop.
		conversions.__disabled = true
		for conv_type, conv_pct in pairs(conversions) do
			-- Filter out the __disabled we just put in.
			if conv_type ~= '__disabled' then
				add = add + self:combatGetResist(conv_type) * conv_pct * 0.01
			end
		end
		conversions.__disabled = nil
	end
	local temp = self:addTemporaryValue('resists', {[type]= add,})
	local total = combatGetResist(self, type)
	self:removeTemporaryValue('resists', temp)
	return total
end

-- Brutish Stride
local attackTargetWith = _M.attackTargetWith
function _M:attackTargetWith(target, weapon, damtype, mult, force_dam)
	mult = mult or 1
	local stride = self:hasEffect('EFF_BRUTISH_STRIDE')
	local radius_id, angle_id
	if stride then
		local emult = stride.move / stride.max
		local radius = math.floor(stride.radius * emult)
		if radius >= 1 then
			radius_id = self:addTemporaryValue('physical_echo_radius', radius)
			angle_id = self:addTemporaryValue('physical_echo_angle', stride.angle * emult)
		end
		mult = mult + stride.damage * emult
	end

	local results = {attackTargetWith(self, target, weapon, damtype, mult, force_dam)}

	if stride then
		if radius_id then
			self:removeTemporaryValue('physical_echo_radius', radius_id)
			self:removeTemporaryValue('physical_echo_angle', angle_id)
		end
		self:removeEffect('EFF_BRUTISH_STRIDE', nil, true)
	end

	return unpack(results)
end

return _M
