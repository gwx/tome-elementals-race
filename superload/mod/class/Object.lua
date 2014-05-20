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

  return getRequirementDesc(self, who)
end

return _M
