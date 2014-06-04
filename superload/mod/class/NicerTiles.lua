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


-- For active terrain.
local map = require 'engine.Map'
local TERRAIN = map.TERRAIN
local _M = loadPrevious(...)

local replaceAll = _M.replaceAll
function _M:replaceAll(level)
	local overlay = function(self, level, mode, i, j, g) return g end
	if level.data.nicer_tiler_overlay then
		overlay = self['overlay'..level.data.nicer_tiler_overlay]
	end

	for _, r in pairs(self.repl) do
		-- Safety check
		local og = level.map(r[1], r[2], TERRAIN)
		if og and (og.change_zone or og.change_level) then
			print('[NICE TILER] *warning* refusing to remove zone/level changer at ', r[1], r[2], og.change_zone, og.change_level)
		elseif og.active_terrain then
			og.terrain = r[3]
			og._mo = nil
			og._last_mo = nil
			level.map.changed = true
			level.map:updateMap(r[1], r[2])
		else
			level.map(r[1], r[2], TERRAIN, overlay(self, level, 'replace', r[1], r[2], r[3]))
		end
	end
	self.repl = {}

	-- In-place entities edition, now this is becoming tricky, but powerful
	for i, jj in pairs(self.edits) do for j, ee in pairs(jj) do
		local g = level.map(i, j, TERRAIN)
		local active
		if g.active_terrain then
			active = g
			g = g.terrain
		end
		if g.__nice_tile_base then
			local base = g.__nice_tile_base
			g = base:clone()
			g:removeAllMOs()
			g.__nice_tile_base = base
		else
			g = g:clone()
			g:removeAllMOs()
			g.__nice_tile_base = g:clone()
		end

		local id = {g.name or "???"}
		for __, e in ipairs(ee) do
			if not e.use_id then id = nil break end
			id[#id+1] = e.use_id
		end
		if id then id = table.concat(id, "|") end

		-- If we made this one already, use it
		if self.edit_entity_store and self.edit_entity_store[id] then
			if active then
				active.terrain = self.edit_entity_store[id]
			else
				level.map(i, j, TERRAIN, self.edit_entity_store[id])
			end
		-- Otherwise compute this new combo and store the entity
		else
			local cloned = false
			if not g.force_clone or not self.edit_entity_store then g = g:cloneFull() g.force_clone = true cloned = true end

			g:removeAllMOs(true)

			-- Edit the first add_display entity, or add a dummy if none
			if not g.__edit_d then
				g.add_displays = g.add_displays or {}
				g.add_displays[#g.add_displays+1] = require(g.__CLASSNAME).new{image="invis.png", force_clone=true}
				g.__edit_d = #g.add_displays
			end
			local gd = g.add_displays[g.__edit_d]

			for __, e in ipairs(ee) do
				local gd = gd
				if e.z then
					if g.__edit_d_z and g.__edit_d_z[e.z] and g.add_displays[g.__edit_d_z[e.z]] then
						gd = g.add_displays[g.__edit_d_z[e.z]]
					else
						g.__edit_d_z = g.__edit_d_z or {}
						g.add_displays[#g.add_displays+1] = require(g.__CLASSNAME).new{image="invis.png", force_clone=true, z=e.z}
						g.__edit_d_z[e.z] = #g.add_displays
						gd = g.add_displays[g.__edit_d_z[e.z]]
					end
				end
				if e.copy_base then gd.image = g.image end
				if e.add_mos then
					-- Add all the mos
					gd.add_mos = gd.add_mos or {}
					local mos = gd.add_mos
					for i = 1, #e.add_mos do
						mos[#mos+1] = table.clone(e.add_mos[i])
						mos[#mos].image = mos[#mos].image:format(rng.range(e.min or 1, e.max or 1))
					end
					if e.add_mos_shader then gd.shader = e.add_mos_shader end
					gd._mo = nil
					gd._last_mo = nil
				end
				if e.add_displays then
					g.add_displays = g.add_displays or {}
					for i = 1, #e.add_displays do
						 g.add_displays[#g.add_displays+1] = require(g.__CLASSNAME).new(e.add_displays[i])
						g.add_displays[#g.add_displays].image = g.add_displays[#g.add_displays].image:format(rng.range(e.min or 1, e.max or 1))
					end
				end
				if active then game.log('ACTIVE1: %s', rawget(active, 'image')) end
				if e.image then g.image = e.image:format(rng.range(e.min or 1, e.max or 1)) end
				if active then game.log('ACTIVE2: %s', rawget(active, 'image')) end
			end

			if active then
				active.terrain = g
			else
				level.map(i, j, TERRAIN, g)
			end
			level.map:updateMap(i, j)
			if self.edit_entity_store then self.edit_entity_store[id] = g end
		end
	end end
	self.edits = {}

	return replaceAll(self, level)
end

return _M
