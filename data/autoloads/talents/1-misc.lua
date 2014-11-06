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

-- I can carry the world learnable from fake armour training.
Talents:getTalentFromId('T_NO_FATIGUE').require.special.fct = function(self)
	return ((self.equip_only_armour_training or 0) +
						self:getTalentLevelRaw('T_ARMOUR_TRAINING'))
		>= 3
end

-- Partial blocking damage types.
local block = Talents:getTalentFromId('T_BLOCK')
local getBlockedTypes = block.getBlockedTypes
block.getBlockedTypes = function(self, t)
	local types, msg = getBlockedTypes(self, t)
	if type(types) ~= 'table' then return nil, msg end
	for t, percent in pairs(self.partial_block_types or {}) do
		if not types[t] then types[t] = percent end
	end
	return types, msg
end
