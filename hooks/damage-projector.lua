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
local damage_type = require 'engine.DamageType'
local hook

hook = function(self, data)
	local src = data.src
	local x, y = data.x, data.y
	local type = data.type
	local dam = data.dam
	local tmp = data.tmp
	local no_martyr = data.no_martyr
	local stopped

	local convert_received = eutil.get(self, 'convert_received', type)
	if convert_received and not convert_received.__disabled then
		local total = 0
		-- Disable to get rid of potential infinite loop.
		convert_received.__disabled = true
		for conv_type, conv_pct in pairs(convert_received) do
			-- Filter out the __disabled we just put in.
			if conv_type ~= '__disabled' then
				total = total + conv_pct
				damage_type:get(conv_type).projector(
					src, x, y, conv_type, dam * conv_pct * 0.01, tmp, no_martyr)
			end
		end
		convert_received.__disabled = nil
		-- Reduce total damage.
		dam = dam * math.max(0, 100 - total) * 0.01
	end

	data.dam = dam
	data.stopped = stopped
	return true
end
class:bindHook('DamageProjector:base', hook)
