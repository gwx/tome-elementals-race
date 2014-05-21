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
		self.max_essence = self.max_life * 0.67
		if self:attr('no_life_regen') then
			self.essence_regen = 0
		else
			self.essence_regen =
				(self.max_essence * 0.02 + self.life_regen) *
				util.bound((self.healing_factor or 1), 0, 2.5)
		end
	end
	regenResources(self)
end

-- Recompute the passives on a given talent.
function _M:recomputePassives(talent)
	local t = self:getTalentFromId(talent)
	if t.passives then
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

-- Leash
local move = _M.move
function _M:move(x, y, force)
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
	return move(self, x, y, force)
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

return _M
