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

local getRequirementDesc = _M.getRequirementDesc
function _M:getRequirementDesc(who)
	if who:attr('shots_sub_mag') and self.subtype == 'shot' then
		local dex, mag
		local req = rawget(self, 'require')
		if req.stat then
			dex = req.stat.dex
			mag = req.stat.mag
			req.stat.dex = nil
			if dex then req.stat.mag = math.max(dex, mag or 0) end
		end

		local result = {getRequirementDesc(self, who)}

		if req.stat then
			req.stat.dex = dex
			req.stat.mag = mag
		end

		return unpack(result)
	end

	-- Allow equip_only_armour_training
	local require = rawget(self, 'require')
	if who.equip_only_armour_training and require then
		local talents = require.talent or {}
		for k, req in pairs(talents) do
			local armor_req
			if type(req) == 'table' and req[1] == 'T_ARMOUR_TRAINING' then
				armor_req = req[2]
			elseif req == 'T_ARMOUR_TRAINING' then
				armor_req = 1
			end
			if armor_req then
				local new_self = table.clone(self)
				new_self.require = table.clone(self.require)
				new_self.require.talent = table.clone(self.require.talent, true)
				armor_req = armor_req - who.equip_only_armour_training
				if armor_req < 1 then
					new_self.require.talent[k] = nil
				elseif armor_req == 1 then
					new_self.require.talent[k] = 'T_ARMOUR_TRAINING'
				else
					new_self.require.talent[k] = {'T_ARMOUR_TRAINING', armor_req,}
				end
				self = new_self
			end
		end
	end

  return getRequirementDesc(self, who)
end

return _M
