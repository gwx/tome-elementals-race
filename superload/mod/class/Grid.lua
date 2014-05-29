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
local map = require 'engine.Map'

local _M = loadPrevious(...)

local block_move = _M.block_move
function _M:block_move(x, y, e, act, couldpass)
	local blocked = block_move(self, x, y, e, act, couldpass)

	-- Test for living mural.
	if blocked and
		e and e.isTalentActive and e:isTalentActive('T_LIVING_MURAL') and
		not e.__living_mural_disabled and
		self.dig and
		eutil.get(self, 'can_pass', 'pass_wall') and
		e.x and e.y and x and y and
		not (math.abs(x - e.x) > 1 or math.abs(y - e.y) > 1)
	then
		local anchor = e.living_mural_anchor
		-- If we have an anchor, then try to find the next position for it.
		if anchor then
			game.log("ANCHOR")
			local disabled = e.__living_mural_disabled
			e.__living_mural_disabled = true

			local dx, dy = x - e.x, y - e.y
			game.log("DX %s, DY %s", dx, dy)

			local new_anchor
			if dx ~= 0 and dy ~= 0 then
				local cx, cy = anchor.x + dx, anchor.y + dy
				game.log("D CX %s, CY %s", cx, cy)
				local terrain = game.level.map(cx, cy, map.TERRAIN)
				if math.abs(cx - x) <= 1 and
					math.abs(cy - y) <= 1 and
					terrain and not terrain:block_move(cx, cy, e, act, couldpass)
				then
					new_anchor = {x = cx, y = cy}
				end
			end

			if not new_anchor and dx ~= 0 then
				local cx, cy = anchor.x + dx, anchor.y
				game.log("H CX %s, CY %s", cx, cy)
				local terrain = game.level.map(cx, cy, map.TERRAIN)
				if math.abs(cx - x) <= 1 and
					math.abs(cy - y) <= 1 and
					terrain and not terrain:block_move(cx, cy, e, act, couldpass)
				then
					new_anchor = {x = cx, y = cy}
				end
			end

			if not new_anchor and dy ~= 0 then
				local cx, cy = anchor.x, anchor.y + dy
				game.log("V CX %s, CY %s", cx, cy)
				local terrain = game.level.map(cx, cy, map.TERRAIN)
				if math.abs(cx - x) <= 1 and
					math.abs(cy - y) <= 1 and
					terrain and not terrain:block_move(cx, cy, e, act, couldpass)
				then
					new_anchor = {x = cx, y = cy}
				end
			end

			if not new_anchor then
				local cx, cy = anchor.x, anchor.y
				game.log("0 CX %s, CY %s", cx, cy)
				local terrain = game.level.map(cx, cy, map.TERRAIN)
				if math.abs(cx - x) <= 1 and
					math.abs(cy - y) <= 1 and
					terrain and not terrain:block_move(cx, cy, e, act, couldpass)
				then
					new_anchor = {x = cx, y = cy}
				end
			end

			if new_anchor then
				self.living_mural_next_anchor = new_anchor
				blocked = false
			end

			e.__living_mural_disabled = disabled

		-- If we have no anchor, then just check to make sure there /is/ an open adjacent space.
		else
			game.log("NO ANCHOR")
			local disabled = e.__living_mural_disabled
			e.__living_mural_disabled = true

			local open = false
			for cx = x - 1, x + 1 do
				for cy = y -1, y + 1 do
					if cx ~= x or cy ~= y then
						local terrain = game.level.map(cx, cy, map.TERRAIN)
						if terrain and not terrain:block_move(cx, cy, e, act, couldpass) then
							open = true
							e.living_mural_next_anchor = {x = cx, y = cy}
							blocked = false
							break
						end
					end
				end
				if open then break end
			end

			e.__living_mural_disabled = disabled
		end
	end

	return blocked
end

return _M
