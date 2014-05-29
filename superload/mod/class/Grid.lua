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
	if e and e.isTalentActive and e:isTalentActive('T_LIVING_MURAL') and
		not e.__living_mural_disabled and
		e.x and e.y and x and y and
		not (math.abs(x - e.x) > 1 or math.abs(y - e.y) > 1)
	then
		local move_anchor = function(anchor, dx, dy)

			local cx, cy = anchor.x, anchor.y
			if math.abs(cx - x) <= 1 and
				math.abs(cy - y) <= 1 and
				e:canMove(cx, cy, true)
			then
				return {x = cx, y = cy}
			end

			if dx ~= 0 and dy ~= 0 then
				local cx, cy = anchor.x + dx, anchor.y + dy
				if math.abs(cx - x) <= 1 and
					math.abs(cy - y) <= 1 and
					e:canMove(cx, cy, true)
				then
					return {x = cx, y = cy}
				end
			end

			if dx ~= 0 then
				local cx, cy = anchor.x + dx, anchor.y
				if math.abs(cx - x) <= 1 and
					math.abs(cy - y) <= 1 and
					e:canMove(cx, cy, true)
				then
					return {x = cx, y = cy}
				end
			end

			if  dy ~= 0 then
				local cx, cy = anchor.x, anchor.y + dy
				if math.abs(cx - x) <= 1 and
					math.abs(cy - y) <= 1 and
					e:canMove(cx, cy, true)
				then
					return {x = cx, y = cy}
				end
			end
		end

		local disabled = e.__living_mural_disabled
		e.__living_mural_disabled = true

		local anchor = e.living_mural_anchor
		local origin_terrain = game.level.map(e.x, e.y, map.TERRAIN)
		local origin_free = e:canMove(e.x, e.y, true)

		-- If we're moving from a wall to open space, make sure we're not moving through the wall.
		if not blocked and not origin_free and anchor then
			local new_anchor = move_anchor(
				anchor, util.bound(x - e.x, -1, 1), util.bound(y - e.y, -1, 1))
			if not new_anchor then
				blocked = true
			end
		-- We're a blocking wall, so see if we're reachable.
		elseif blocked and self.dig and eutil.get(self, 'can_pass', 'pass_wall') then
			-- If we have an anchor, then try to find the next position for it.
			if anchor then
				local new_anchor = move_anchor(
					anchor, util.bound(x - e.x, -1, 1), util.bound(y - e.y, -1, 1))
				if new_anchor then
					blocked = false
				end

			-- If we have no anchor, then just check to make sure there /is/ an open adjacent space.
			else
				local disabled = e.__living_mural_disabled
				e.__living_mural_disabled = true

				local open = false
				for cx = x - 1, x + 1 do
					for cy = y -1, y + 1 do
						if cx ~= x or cy ~= y then
							if e:canMove(cx, cy, true) then
								open = true
								--e.living_mural_next_anchor = {x = cx, y = cy}
								blocked = false
								break
							end
						end
					end
					if open then break end
				end

			end
		end
		e.__living_mural_disabled = disabled
	end
	return blocked
end

return _M
