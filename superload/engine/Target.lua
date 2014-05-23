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


local Map = require "engine.Map"
local Shader = require "engine.Shader"

local _M = loadPrevious(...)

function core.fov.calc_rect(source_x, source_y, x, y, w, h, filter, apply)
	if w then
		w = w - 1
		if x > source_x and x - source_x > w then
			x = source_x + w
		elseif x < source_x and source_x - x > w then
			x = source_x - w
		end
	end
	if h then
		h = h - 1
		if y > source_y and y - source_y > h then
			y = source_y + h
		elseif y < source_y and source_y - y > h then
			y = source_y - h
		end
	end
	if x < source_x then x, source_x = source_x, x end
	if y < source_y then y, source_y = source_y, y end

	for tx = source_x, x do
		for ty = source_y, y do
			if not filter or filter(tx, ty) then
				apply(nil, tx, ty)
			end
		end
	end
end

local getType = _M.getType
function _M:getType(t)
	t = getType(self, t)
	local update = {}

	if t.type then
		if t.type:find('rect') then
			update.rect = {w = t.w or 1, h = t.h or 1,}
			if t.x then update.start_x = t.x end
			if t.y then update.start_y = t.y end
			update.no_line = true
		end
	end

	table.update(t, update)
	return t
end

-- We basically need to override the whole function here, because it
-- doesn't have hooks or anything, because no one else is this crazy.
function _M:realDisplay(dispx, dispy)
	-- Make sure we have a source
	if not self.target_type.source_actor then
		self.target_type.source_actor = self.source_actor
	end
	-- Entity tracking, if possible and if visible
	if self.target.entity and self.target.entity.x and self.target.entity.y and game.level.map.seens(self.target.entity.x, self.target.entity.y) then
		self.target.x, self.target.y = self.target.entity.x, self.target.entity.y
	end
	self.target.x = self.target.x or self.source_actor.x
	self.target.y = self.target.y or self.source_actor.y

	self.target_type.start_x = self.target_type.start_x or self.target_type.x or self.target_type.source_actor and self.target_type.source_actor.x or self.x
	self.target_type.start_y = self.target_type.start_y or self.target_type.y or self.target_type.source_actor and self.target_type.source_actor.y or self.y


--	self.cursor:toScreen(dispx + (self.target.x - game.level.map.mx) * self.tile_w * Map.zoom, dispy + (self.target.y - game.level.map.my) * self.tile_h * Map.zoom, self.tile_w * Map.zoom, self.tile_h * Map.zoom)

	-- Do not display if not requested
	if not self.active then return end

	local pending_highlights = {}
	local display_highlight = function(texture, tx, ty)
		if not pending_highlights[tx] then
			pending_highlights[tx] = {}
		end
		pending_highlights[tx][ty] = texture
	end

	local display_highlight_real
	if util.isHex() then
		display_highlight_real = function(texture, tx, ty)
			texture:toScreenHighlightHex(
				dispx + (tx - game.level.map.mx) * self.tile_w * Map.zoom,
				dispy + (ty - game.level.map.my + util.hexOffset(tx)) * self.tile_h * Map.zoom,
				self.tile_w * Map.zoom,
				self.tile_h * Map.zoom)
			end
	else
		display_highlight_real = function(texture, tx, ty)
			texture:toScreen(
				dispx + (tx - game.level.map.mx) * self.tile_w * Map.zoom,
				dispy + (ty - game.level.map.my) * self.tile_h * Map.zoom,
				self.tile_w * Map.zoom,
				self.tile_h * Map.zoom)
			end
	end

	local blob = self.target_type.blob or {}
	local blob_target_type = {range = false, __index = self.target_type}
	setmetatable(blob_target_type, blob_target_type)

	local s = self.sb
	local l
	if self.target_type.source_actor.lineFOV then
		l = self.target_type.source_actor:lineFOV(self.target.x, self.target.y, nil, nil, self.target_type.start_x, self.target_type.start_y)
	else
		l = core.fov.line(self.target_type.start_x, self.target_type.start_y, self.target.x, self.target.y)
	end
	local block_corner = self.target_type.block_path and function(_, bx, by) local b, h, hr = self.target_type:block_path(bx, by, true) ; return b and h and not hr end
		or function(_, bx, by) return false end

	l:set_corner_block(block_corner)
	local lx, ly, blocked_corner_x, blocked_corner_y = l:step()

	local stop_x, stop_y = self.target_type.start_x, self.target_type.start_y
	local stop_radius_x, stop_radius_y = self.target_type.start_x, self.target_type.start_y
	local stopped = false
	local block, hit, hit_radius

	local firstx, firsty = lx, ly

	-- Being completely blocked by the corner of an adjacent tile is annoying, so let's make it a special case and hit it instead
	if blocked_corner_x then
		block = true
		hit = true
		hit_radius = false
		stopped = true
		if self.target_type.min_range and core.fov.distance(self.target_type.start_x, self.target_type.start_y, lx, ly) < self.target_type.min_range then
			s = self.sr
		end
		if game.level.map:isBound(blocked_corner_x, blocked_corner_y) then
			display_highlight(s, blocked_corner_x, blocked_corner_y)
		end
		s = self.sr
	end

	while lx and ly do
		if not stopped then
			block, hit, hit_radius = false, true, true
			if self.target_type.block_path then
				block, hit, hit_radius = self.target_type:block_path(lx, ly, true)
				for _, offsets in pairs(blob) do
					local block2, hit2, hit_radius2 =
						blob_target_type:block_path(lx + offsets.x, ly + offsets.y, true)
					block = block or block2
					if hit ~= 'unknown' then hit = hit and hit2 end
					hit_radius = hit_radius and hit_radius2
				end
			end

			-- Update coordinates and set color
			if hit then
				stop_x, stop_y = lx, ly
				if not block and hit == "unknown" then s = self.sy end
			else
				s = self.sr
			end
			if hit_radius then
				stop_radius_x, stop_radius_y = lx, ly
			end
			if self.target_type.min_range then
				-- Check if we should be "red"
				if core.fov.distance(self.target_type.start_x, self.target_type.start_y, lx, ly) < self.target_type.min_range then
					s = self.sr
					-- Check if we were only "red" because of minimum distance
				elseif s == self.sr then
					s = self.sb
				end
			end
		end
		if not self.target_type.no_line then
			display_highlight(s, lx, ly)
			for _, offsets in pairs(blob) do
				display_highlight(s, lx + offsets.x, ly + offsets.y)
			end
		end
		if block then
			s = self.sr
			stopped = true
		end

		lx, ly, blocked_corner_x, blocked_corner_y = l:step()

		if blocked_corner_x and not stopped then
			block = true
			stopped = true
			hit_radius = false
			s = self.sr
			-- double the fun :-P
			if game.level.map:isBound(blocked_corner_x, blocked_corner_y) then
				display_highlight({s, 2}, blocked_corner_x, blocked_corner_y)
			end
		end
	end

	if self.target_type.final_green == 'radius' then
		display_highlight(self.sg, stop_radius_x, stop_radius_y)
		for _, offsets in pairs(blob) do
			display_highlight(self.sg, stop_radius_x + offsets.x, stop_radius_y + offsets.y)
		end
	elseif self.target_type.final_green then
		display_highlight(self.sg, stop_x, stop_y)
		for _, offsets in pairs(blob) do
			display_highlight(self.sg, stop_x + offsets.x, stop_y + offsets.y)
		end
	end

	if self.target_type.ball and self.target_type.ball > 0 then
		core.fov.calc_circle(
			stop_radius_x,
			stop_radius_y,
			game.level.map.w,
			game.level.map.h,
			self.target_type.ball,
			function(_, px, py)
				if self.target_type.block_radius and self.target_type:block_radius(px, py, true) then return true end
			end,
			function(_, px, py)
				if not self.target_type.no_restrict and not game.level.map.remembers(px, py) and not game.level.map.seens(px, py) then
					display_highlight(self.syg, px, py)
				else
					display_highlight(self.sg, px, py)
				end
			end,
		nil)
	elseif self.target_type.cone and self.target_type.cone > 0 then
		--local dir_angle = math.deg(math.atan2(self.target.y - self.source_actor.y, self.target.x - self.source_actor.x))
		core.fov.calc_beam_any_angle(
			stop_radius_x,
			stop_radius_y,
			game.level.map.w,
			game.level.map.h,
			self.target_type.cone,
			self.target_type.cone_angle,
			self.target_type.start_x,
			self.target_type.start_y,
			self.target.x - self.target_type.start_x,
			self.target.y - self.target_type.start_y,
			function(_, px, py)
				if self.target_type.block_radius and self.target_type:block_radius(px, py, true) then return true end
			end,
			function(_, px, py)
				if not self.target_type.no_restrict and not game.level.map.remembers(px, py) and not game.level.map.seens(px, py) then
					display_highlight(self.syg, px, py)
				else
					display_highlight(self.sg, px, py)
				end
			end,
		nil)
	elseif self.target_type.wall and self.target_type.wall > 0 then
		core.fov.calc_wall(
			stop_radius_x,
			stop_radius_y,
			game.level.map.w,
			game.level.map.h,
			self.target_type.wall,
			self.target_type.halfmax_spots,
			self.target_type.start_x,
			self.target_type.start_y,
			self.target.x - self.target_type.start_x,
			self.target.y - self.target_type.start_y,
			function(_, px, py)
				if self.target_type.block_radius and self.target_type:block_radius(px, py, true) then return true end
			end,
			function(_, px, py)
				if not self.target_type.no_restrict and not game.level.map.remembers(px, py) and not game.level.map.seens(px, py) then
					display_highlight(self.syg, px, py)
				else
					display_highlight(self.sg, px, py)
				end
			end,
		nil)
	-- New stuff starts here.
	elseif self.target_type.rect then
		local filter = self.target_type.filter
		core.fov.calc_rect(
			self.target_type.start_x,
			self.target_type.start_y,
			stop_radius_x,
			stop_radius_y,
			self.target_type.rect.w,
			self.target_type.rect.h,
			nil,
			function(_, px, py)
				if not self.target_type.no_restrict and not game.level.map.remembers(px, py) and not game.level.map.seens(px, py) then
					display_highlight(self.syg, px, py)
				elseif not filter or filter(px, py) then
					display_highlight(self.sg, px, py)
				else
					display_highlight(self.sr, px, py)
				end
			end
		)
	end

	for x, ys in pairs(pending_highlights) do
		for y, tex in pairs(ys) do
			if type(tex) == 'table' then
				for i = 1, tex[2] do
					display_highlight_real(tex[1], x, y)
				end
			else
				display_highlight_real(tex, x, y)
			end
		end
	end
end

return _M
