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

function _M:getType(t)
	if not t then return {} end
	-- Add the default values
	t = table.clone(t)
	-- Default type def
	local target_type = {
		range = 20,
		selffire = true,
		friendlyfire = true,
		friendlyblock = true,
		--- Determines how a path is blocked for a target type
		--@param typ The target type table
		block_path = function(typ, lx, ly, for_highlights)
			if not game.level.map:isBound(lx, ly) then
				return true, false, false
			elseif not typ.no_restrict then
				if typ.range and typ.start_x then
					local dist = core.fov.distance(typ.start_x, typ.start_y, lx, ly)
					if dist > typ.range then return true, false, false end
				elseif typ.range and typ.source_actor and typ.source_actor.x then
					local dist = core.fov.distance(typ.source_actor.x, typ.source_actor.y, lx, ly)
					if dist > typ.range then return true, false, false end
				end
				if typ.range2 and typ.start_x2 and typ.start_y2 then
					local dist = core.fov.distance(typ.start_x2, typ.start_y2, lx, ly)
					if dist > typ.range2 then return true, false, false end
				end
				local is_known = game.level.map.remembers(lx, ly) or game.level.map.seens(lx, ly)
				if typ.requires_knowledge and not is_known then
					return true, false, false
				end
				local terrain = game.level.map(lx, ly, engine.Map.TERRAIN)
				local pass_terrain =
					type(typ.pass_terrain) == 'function' and
					typ.pass_terrain(terrain, lx, ly) or
					typ.pass_terrain
				if not pass_terrain and
					game.level.map:checkEntity(lx, ly, engine.Map.TERRAIN, 'block_move') and
					not game.level.map:checkEntity(lx, ly, engine.Map.TERRAIN, 'pass_projectile')
				then
					if for_highlights and not is_known then
						return false, 'unknown', true
					else
						return true, true, false
					end
				-- If we explode due to something other than terrain, then we should explode ON the tile, not before it
				elseif typ.stop_block then
					local nb = game.level.map:checkAllEntitiesCount(lx, ly, 'block_move')
					-- Reduce for pass_projectile or pass_terrain, which was handled above
					if game.level.map:checkEntity(lx, ly, engine.Map.TERRAIN, 'block_move') and (typ.pass_terrain or game.level.map:checkEntity(lx, ly, engine.Map.TERRAIN, 'pass_projectile')) then
						nb = nb - 1
					end
					-- Reduce the nb blocking for friendlies
					if not typ.friendlyblock and typ.source_actor and typ.source_actor.reactionToward then
						local a = game.level.map(lx, ly, engine.Map.ACTOR)
						if a and typ.source_actor:reactionToward(a) > 0 then
							nb = nb - 1
						end
					end
					if nb > 0 then
						if for_highlights then
							-- Targeting highlight should be yellow if we don't know what we're firing through
							if not is_known then
								return false, 'unknown', true
							-- Don't show the path as blocked if it's blocked by an actor we can't see
							elseif nb == 1 and typ.source_actor and typ.source_actor.canSee and not typ.source_actor:canSee(game.level.map(lx, ly, engine.Map.ACTOR)) then
								return false, true, true
							end
						end
						return true, true, true
					end
				end
				if for_highlights and not is_known then
					return false, 'unknown', true
				end
			end
			-- If we don't block the path, then the explode point should be here
			return false, true, true
		end,
		block_radius = function(typ, lx, ly, for_highlights)
			return not typ.no_restrict and game.level.map:checkEntity(lx, ly, engine.Map.TERRAIN, 'block_move') and not game.level.map:checkEntity(lx, ly, engine.Map.TERRAIN, 'pass_projectile') and not (for_highlights and not (game.level.map.remembers(lx, ly) or game.level.map.seens(lx, ly)))
		end
	}

	-- And now modify for the default types
	if t.type then
		if t.type:find('ball') then
			target_type.ball = t.radius
		end
		if t.type:find('cone') then
			target_type.cone = t.radius
			target_type.cone_angle = t.cone_angle or 55
			target_type.selffire = false
		end
		if t.type:find('wall') then
			if util.isHex() then
				--with a hex grid, a wall should only be defined by the number of spots
				t.halfmax_spots = t.halflength
				t.halflength = 2*t.halflength
			end
			target_type.wall = t.halflength
		end
		if t.type:find('bolt') then
			target_type.stop_block = true
		elseif t.type:find('beam') then
			target_type.line = true
		end
		if t.type:find('rect') then
			target_type.rect = {w = t.w or 1, h = t.h or 1,}
			if t.x then target_type.start_x = t.x end
			if t.y then target_type.start_y = t.y end
			target_type.no_line = true
		end
	end
	table.update(t, target_type)
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
		if self.target_type.filter and not self.target_type.filter(tx, ty) then
			texture = self.sr
		end

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

	if self.target_type.include_start then
		display_highlight(self.sb, self.target_type.start_x, self.target_type.start_y)
	end

	local blob = self.target_type.blob or {}
	local blob_target_type = {range = false, range2 = false, __index = self.target_type,}
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
			elseif self.target_type.line_red_past_radius then
				s = self.sr
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
		local x, y = stop_radius_x, stop_radius_y
		if self.target_type.ball_not_radius then
			x, y = stop_x, stop_y
		end
		core.fov.calc_circle(
			x, y,
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
				else
					display_highlight(self.sg, px, py)
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
