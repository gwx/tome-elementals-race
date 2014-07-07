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
local map = require 'engine.Map'
local ACTOR = map.ACTOR
local hook

hook = function(self, data)
	local src = data.src
	local x, y = data.x, data.y
	local type = data.type
	local dam = data.dam
	local tmp = data.tmp
	local no_martyr = data.no_martyr
	local target = game.level.map(x, y, ACTOR)
	local stopped

	-- Lifepyre
	local lifepyre = target:hasEffect 'EFF_LIFEPYRE'
	if lifepyre then
		target:setEffect('EFF_LIFEPYRE_HEALING', lifepyre.smearing, {
											 healing = dam * lifepyre.healing * 0.01 / lifepyre.smearing,})
	end

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

	local resist_heat_conversion = eutil.get(self, 'resist_heat_conversions', type)
	if resist_heat_conversion then
		local resisted
		-- Find amount resisted.
		local pen = 0
		if src.resists_pen then pen = (src.resists_pen.all or 0) + (src.resists_pen[type] or 0) end
		local dominated = target:hasEffect(target.EFF_DOMINATED)
		if dominated and dominated.src == src then pen = pen + (dominated.resistPenetration or 0) end
		if target:attr("sleep") and src.attr and src:attr("night_terror") then pen = pen + src:attr("night_terror") end
		local res = target:combatGetResist(type)
		pen = util.bound(pen, 0, 100)
		if res > 0 then	res = res * (100 - pen) / 100 end
		print("[PROJECTOR] res", res, (100 - res) / 100, " on dam", dam)
		if res >= 100 then resisted = dam
		elseif res <= 0 then resisted = 0
		else resisted = dam * res * 0.01
		end
		-- Add heat.
		target:incHeat(resisted * resist_heat_conversion * 0.01)
	end

	data.dam = dam
	data.stopped = stopped
	return true
end
class:bindHook('DamageProjector:base', hook)
