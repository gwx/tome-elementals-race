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
local eutil = require 'elementals-race.util'
local target = require 'engine.Target'
local map = require 'engine.Map'

-- Learn Essence Pool
local learnPool = _M.learnPool
function _M:learnPool(t)
	local tt = self:getTalentTypeFrom(t.type[1])
	if t.essence or t.sustain_essence then
		self:checkPool(t.id, 'T_ESSENCE_POOL')
	end
	learnPool(self, t)
end

local regenResources = _M.regenResources
function _M:regenResources()
	-- Update essence values with latest life values.
	if self:knowTalent('T_ESSENCE_POOL') then
		self.max_essence = self.max_life * 0.67 * (100 - (self.sustain_essence or 0)) * 0.01
		if self:attr('no_life_regen') then
			self.essence_regen = 0
		else
			self.essence_regen =
				(self.max_essence * 0.01 + self.life_regen) *
				util.bound((self.healing_factor or 1), 0, 2.5)
		end
	end
	regenResources(self)
end

-- Retrieve the actual essence cost.
function _M:essenceCost(percent)
	return percent * self:realMaxEssence() * 0.01
end

-- Get the actualy max essence, minus sustains.
function _M:realMaxEssence()
	return 100 * self:getMaxEssence() / (100 - (self.sustain_essence or 0))
end

-- Recompute the passives on a given talent.
function _M:recomputePassives(talent)
	local t = self:getTalentFromId(talent)
	if self:knowTalent(talent) and t.passives then
		self.talents_learn_vals[t.id] = self.talents_learn_vals[t.id] or {}
		local p = self.talents_learn_vals[t.id]

		if p.__tmpvals then for i = 1, #p.__tmpvals do
				self:removeTemporaryValue(p.__tmpvals[i][1], p.__tmpvals[i][2])
		end end

		if self:knowTalent(t.id) then
			self.talents_learn_vals[t.id] = {}
			t.passives(self, t, self.talents_learn_vals[t.id])
		else
			self.talents_learn_vals[t.id] = nil
		end
	end
end

local learnTalent = _M.learnTalent
function _M:learnTalent(t_id, force, nb, extra)
	if learnTalent(self, t_id, force, nb, extra) then
		local t = self:getTalentFromId(t_id)
		-- Add in passive updates on changes
		if t.recompute_passives then
			self.recompute_passives =
				self.recompute_passives or {stats = {}, attributes = {}}
			for _, stat in pairs(t.recompute_passives.stats or {}) do
				local self_stats = self.recompute_passives.stats
				self_stats[stat] = self_stats[stat] or {}
				self_stats[stat][t_id] = true
			end
			for _, attribute in pairs(t.recompute_passives.attributes or {}) do
				local self_attributes = self.recompute_passives.attributes
				self_attributes[attribute] = self_attributes[attribute] or {}
				self_attributes[attribute][t_id] = true
			end
		end
		return true
	end
end

local unlearnTalent = _M.unlearnTalent
function _M:unlearnTalent(t_id, nb, no_unsustain, extra)
	if unlearnTalent(self, t_id, nb, no_unsustain, extra) then
		-- Strip out passive updates on stat changes
		if self:getTalentLevelRaw(t_id) <= 0 then
			local t = self:getTalentFromId(t_id)
			if t.recompute_passives then
				self.recompute_passives = self.recompute_passives or {stats = {}}
				for _, stat in pairs(t.recompute_passives.stats or {}) do
					local self_stats = self.recompute_passives.stats
					self_stats[stat] = self_stats[stat] or {}
					self_stats[stat][t_id] = nil
				end
				for _, attribute in pairs(t.recompute_passives.attributes or {}) do
					local self_attributes = self.recompute_passives.attributes
					self_attributes[attribute] = self_attributes[attribute] or {}
					self_attributes[attribute][t_id] = nil
				end
			end
		end
		return true
	end
end

-- Check for recompute_passives on talents.
local onStatChange = _M.onStatChange
function _M:onStatChange(stat, v)
	onStatChange(self, stat, v)
	for tid, _ in pairs(eutil.get(self, 'recompute_passives', 'stats', stat) or {}) do
		self:recomputePassives(tid)
	end
end

local onTemporaryValueChange = _M.onTemporaryValueChange
function _M:onTemporaryValueChange(prop, v, base)
	onTemporaryValueChange(self, prop, v, base)
	if base == self then
		local rp = eutil.get(self, 'recompute_passives', 'attributes', prop) or {}
		for tid, _ in pairs(rp) do
			self:recomputePassives(tid)
		end
	end
end

local move = _M.move
function _M:move(x, y, force)
	-- Amorphous Cloud gives you free movement.
	local free_move = false
	if self:knowTalent('T_AMORPHOUS') then
		local effects = game.level.map:getEffects(x, y, 'dust_storm')
		free_move = #effects > 0
	end

	-- Unleashed always allows movement.
	local unleashed_activated = false
	if self:attr('never_move') and self:hasEffect('EFF_UNLEASHED') then
		unleashed_activated = self.never_move
		self.never_move = nil
		self:reduceUnleashed(unleashed_activated)
	end

	self.moving = true
	-- Leash
	if not force and self.hard_leash then
		for src, distance in pairs(self.hard_leash) do
			if not src.dead then
				local cur_dist = core.fov.distance(self.x, self.y, src.x, src.y)
				local new_dist = core.fov.distance(x, y, src.x, src.y)
				if new_dist > distance and new_dist > cur_dist then
					game.logPlayer(self, 'You are leashed to %s and cannot move there!', src.name)
					return
				end
			end
		end
	end

	local sx, sy = self.x, self.y
	local nowhere = not sx or not sy

	local cancel_move = false

	-- Living Mural
	if self:isTalentActive('T_LIVING_MURAL') then
		local deactivate = false

		-- See if present location and target location are passable.
		local pass = eutil.get(self, 'can_pass', 'pass_wall')
		eutil.set(self, 'can_pass', 'pass_wall', 0)
		local self_free = nowhere or self:canMove(sx, sy, true)
		local target_free = self:canMove(x, y, true)
		self.can_pass.pass_wall = pass

		-- If we presently don't have a location, then discard the anchor
		-- and prevent moving to target space if its solid.
		if nowhere and not target_free then
			self.living_mural_anchor = nil
			cancel_move = true

		-- If we're currently free, but target is not, just set the anchor
		-- to present location.
		elseif self_free and not target_free then
			self.living_mural_anchor = {x = sx, y = sy,}

	  -- If we're moving to a free location from a free location then discard anchor.
		elseif self_free and target_free then
			self.living_mural_anchor = nil

		-- We're moving from wall to wall. Cancel out if we're trying to move more than one space.
		elseif not nowhere and core.fov.distance(x, y, sx, sy) > 1 then
			deactivate = true

		-- Try to move the anchor.
		else
			local dx, dy
			local old_anchor = self.living_mural_anchor
			if nowhere then
				dx = util.bound(x - old_anchor.x, -1, 1)
				dy = util.bound(y - old_anchor.y, -1, 1)
			else
				dx = util.bound(x - sx, -1, 1)
				dy = util.bound(y - sy, -1, 1)
			end
			local new_anchor = {
				x = old_anchor.x + dx,
				y = old_anchor.y + dy,}

			-- Test if the new anchor is a wall.
			local pass = eutil.get(self, 'can_pass', 'pass_wall')
			eutil.set(self, 'can_pass', 'pass_wall', 0)
			local new_anchor_free = self:canMove(new_anchor.x, new_anchor.y, true)
			self.can_pass.pass_wall = pass

			-- If the new anchor is valid, use it.
			if new_anchor_free then
				self.living_mural_anchor = new_anchor
			end

			-- Test if the new location is close enough to the current anchor
			if core.fov.distance(self.living_mural_anchor.x, self.living_mural_anchor.y, x, y) > 1 then
				-- We can't move here. If this is a forced move, deactivate living mural.
				if force then
					deactivate = true
				else
					cancel_move = true
				end
			end
		end

		if deactivate then self.living_mural_anchor = nil end

		-- Deactivate if necessary.
		if deactivate then
			if self:isTalentActive('T_LIVING_MURAL') then
				self:forceUseTalent('T_LIVING_MURAL', {ignore_energy = true,})
			end
		end
	end

	-- Actual move
	local result
	if cancel_move then
		result = false
	else
		if free_move then self.did_energy = true end
		result = move(self, x, y, force)
		if free_move then self.did_energy = false end
	end

	-- Update the lock beam.
	if self:isTalentActive('T_LIVING_MURAL') then
		local lm = self:getTalentFromId('T_LIVING_MURAL')
		local p = self.sustain_talents['T_LIVING_MURAL']
		lm.update_after_move(self, lm, p)
	end


	-- Brutish Stride
	if self:knowTalent('T_BRUTISH_STRIDE') and
		not nowhere and
		(self.x ~= sx or self.y ~= sy)
	then
		local t = self:getTalentFromId('T_BRUTISH_STRIDE')
		local move = util.getval(t.move, self, t)
		self:setEffect('EFF_BRUTISH_STRIDE', 1, {
										 move = move, max = move * 10,
										 damage = util.getval(t.damage, self, t),
										 radius = util.getval(t.radius, self, t),
										 angle = util.getval(t.angle, self, t),})
	end

	self.moving = nil
	if unleashed_activated then
		self.never_move = unleashed_activated
	end
	return result
end

-- Reduce unleashed duration.
function _M:reduceUnleashed(count)
	count = count or 1
	local unleashed = self:hasEffect('EFF_UNLEASHED')
	if unleashed then
		unleashed.dur = unleashed.dur - count
		if unleashed.dur <= 0 then
			self:removeEffect('EFF_UNLEASHED')
		end
		-- Brutish Stride stacks
		if unleashed.stride and self:knowTalent('T_BRUTISH_STRIDE') then
			local stride = self:getTalentFromId('T_BRUTISH_STRIDE')
			local move = util.getval(stride.move, self, stride)
			local stacks = count * unleashed.stride
			self:setEffect('EFF_BRUTISH_STRIDE', 1, {
											 move = move * stacks, max = move * 10,
											 damage = util.getval(stride.damage, self, stride),
											 radius = util.getval(stride.radius, self, stride),
											 angle = util.getval(stride.angle, self, stride),})
		end
	end
end

local knockback = _M.knockback
function _M:knockback(srcx, srcy, dist, recursive, on_terrain)
	-- If unleashed is on, ignore the knockback and reduce it.
	if self:hasEffect('EFF_UNLEASHED') then
		self:reduceUnleashed()
		return
	end

	-- Turn off living mural so we don't break things horribly.
	if self:isTalentActive('T_LIVING_MURAL') then
		local ox, oy = self.x, self.y
		local pass = eutil.get(self, 'can_pass', 'pass_wall')
		local pass_id = self:addTemporaryValue('can_pass', {pass_wall = pass})

		local result = {knockback(self, srcx, srcy, dist, recursive, on_terrain)}

		self:removeTemporaryValue('can_pass', pass_id)
		if ox ~= self.x or oy ~= self.y then
			self.living_mural_anchor = nil
		end
		return unpack(result)
	end

	return knockback(self, srcx, srcy, dist, recursive, on_terrain)
end

-- Allow overrideable archery weapon.
local hasArcheryWeapon = _M.hasArcheryWeapon
function _M:hasArcheryWeapon(type)
	if self:attr('disarmed') then return nil, 'disarmed' end
	if self.archery_weapon_override then
		return unpack(self.archery_weapon_override)
	end
	return hasArcheryWeapon(self, type)
end

-- Mistarget on source.
local project = _M.project
function _M:project(t, x, y, damtype, dam, particles)
	if self.mistarget_chance and rng.percent(self.mistarget_chance) then
		local distance = core.fov.distance(self.x, self.y, x, y)
		if distance > 1 then
			local angle = math.rad(rng.range(0, 360))
			distance = distance * rng.float(0, self.mistarget_percent)
			x = math.floor(x + 0.5 + math.cos(angle) * distance)
			y = math.floor(y + 0.5 + math.sin(angle) * distance)
			game.logSeen(self, '%s mistargets by %.1f!', self.name:capitalize(), distance)
		end
	end

	return project(self, t, x, y, damtype, dam, particles)
end

-- Let projectiles modify their movement.
local projectDoMove = _M.projectDoMove
function _M:projectDoMove(typ, tgtx, tgty, x, y, srcx, srcy)
	local lx, ly, act, stop = projectDoMove(self, typ, tgtx, tgty, x, y, srcx, srcy)
	if typ.on_move then
		lx, ly, act, stop = typ.on_move(
			self, typ, tgtx, tgty, x, y, srcx, srcy, lx, ly, act, stop)
	end
	return lx, ly, act, stop
end

-- Earthen Gun allows you to substitute mag for dex.
-- Remove shield reqs if you know buckler stuff
local canWearObject = _M.canWearObject
function _M:canWearObject(o, try_slot)
  if self:attr('shots_sub_mag') and o.subtype == 'shot' then
		local dex, mag
		local req = rawget(o, 'require')
		if req.stat then
			dex = req.stat.dex
			mag = req.stat.mag
			req.stat.dex = nil
			if dex then req.stat.mag = math.max(dex, mag or 0) end
		end

		local result = {canWearObject(self, o, try_slot)}

		if req.stat then
			req.stat.dex = dex
			req.stat.mag = mag
		end

		return unpack(result)
	end

	return canWearObject(self, o, try_slot)
end

-- Add in blob targeting.
function _M:canProject(t, x, y)
	local typ = target:getType(t)
	typ.source_actor = self
	typ.start_x = typ.start_x or typ.x or typ.source_actor and typ.source_actor.x or self.x
	typ.start_y = typ.start_y or typ.y or typ.source_actor and typ.source_actor.y or self.y

	local blob = typ.blob or {}
	local blob_typ = {range = false, __index = typ}
	setmetatable(blob_typ, blob_typ)

	-- Stop at range or on block
	local stop_x, stop_y = typ.start_x, typ.start_y
	local stop_radius_x, stop_radius_y = typ.start_x, typ.start_y
	local l, is_corner_blocked
	if typ.source_actor.lineFOV then
		l = typ.source_actor:lineFOV(x, y, nil, nil, typ.start_x, typ.start_y)
	else
		l = core.fov.line(typ.start_x, typ.start_y, x, y)
	end
	local block_corner = typ.block_path and function(_, bx, by) local b, h, hr = typ:block_path(bx, by, true) ; return b and h and not hr end
		or function(_, bx, by) return false end

	l:set_corner_block(block_corner)
	local lx, ly, blocked_corner_x, blocked_corner_y = l:step()

	-- Being completely blocked by the corner of an adjacent tile is annoying, so let's make it a special case and hit it instead
	if blocked_corner_x then
		stop_x = blocked_corner_x
		stop_y = blocked_corner_y
	else
		while lx and ly do
			local block, hit, hit_radius = false, true, true
			if is_corner_blocked then
				stop_x = stop_radius_x
				stop_y = stop_radius_y
				break
			elseif typ.block_path then
				block, hit, hit_radius = typ:block_path(lx, ly)
				for _, offsets in pairs(blob) do
					local block2, hit2, hit_radius2 =
						blob_typ:block_path(lx + offsets.x, ly + offsets.y, true)
					block = block or block2
					hit = hit and hit2
					hit_radius = hit_radius and hit_radius2
				end
			end
			if hit then
				stop_x, stop_y = lx, ly
			end
			if hit_radius then
				stop_radius_x, stop_radius_y = lx, ly
			end

			if block then break end
			lx, ly, is_corner_blocked = l:step()
		end
	end

	-- Check for minimum range
	if typ.min_range and core.fov.distance(typ.start_x, typ.start_y, stop_x, stop_y) < typ.min_range then
		return
	end

	local is_hit = stop_x == x and stop_y == y
	return is_hit, stop_x, stop_y, stop_radius_x, stop_radius_y
end

-- Jaggedbody
local incJaggedbody = _M.incJaggedbody
function _M:incJaggedbody(v)
	incJaggedbody(self, v)
	self:recomputePassives('T_SMOLDERING_CORE')
end

-- Afterecho
local onWear = _M.onWear
function _M:onWear(o, bypass_set)
	onWear(self, o, bypass_set)
	if o.slot == 'MAINHAND' or o.slot == 'OFFHAND' or
		o.offslot == 'MAINHAND' or o.offslot == 'OFFHAND'
	then
		self:recomputePassives('T_AFTERECHO')
	end
end

local onTakeoff = _M.onTakeoff
function _M:onTakeoff(o, bypass_set)
	onTakeoff(self, o, bypass_set)
	if o.slot == 'MAINHAND' or o.slot == 'OFFHAND' or
		o.offslot == 'MAINHAND' or o.offslot == 'OFFHAND'
	then
		self:recomputePassives('T_AFTERECHO')
	end
end

-- Brutish Stride
local breakStepUp = _M.breakStepUp
function _M:breakStepUp()
	breakStepUp(self)
	if self:hasEffect('EFF_BRUTISH_STRIDE') then
		game:onTickEnd(
			function()
				local stride = self:hasEffect('EFF_BRUTISH_STRIDE')
				if stride and not self.turn_procs.stride_broken then
					self.turn_procs.stride_broken = true
					local move = stride.move * 0.5
					if move < 1 then
						self:removeEffect('EFF_BRUTISH_STRIDE')
					else
						stride.move = move
					end
				end
		end)
	end
end

-- So we can check wait action.
local postUseTalent = _M.postUseTalent
function _M:postUseTalent(ab, ret, silent)
  self.__talent_running_post = ab
  local ret = {postUseTalent(self, ab, ret, silent)}
  self.__talent_running_post = nil
  return unpack(ret)
end

-- On Wait.
local useEnergy = _M.useEnergy
function _M:useEnergy(val)
  useEnergy(self, val)
  if not self.__talent_running and
    not self.__talent_running_post
  then
		if self:hasEffect('EFF_BRUTISH_STRIDE') and not self.moving then
			self:removeEffect('EFF_BRUTISH_STRIDE', nil, true)
		end
  end
end

return _M
