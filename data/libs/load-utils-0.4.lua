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


-- Add autolevel loadDefinition.
superload('engine.Autolevel', function(_M)
		function _M:loadDefinition(file, env)
			local f, err = util.loadfilemods(file, setmetatable(env or {
						registerScheme = function(t) self:registerScheme(t) end,
						load = function(f) self:loadDefinition(f, getfenv(2)) end
						}, {__index=_G}))
			if not f and err then error(err) end
			f()
			end
		end)

util.dir_actions = {
	birth = 'birth',
	talents = 'talent',
	effects = 'effect',
	lore = 'lore',
	['damage-types'] = 'damage_type',
	damage_types = 'damage_type',
	autolevels = 'autolevel',
	autolevel_schemes = 'autolevel',
	ai = function(filename) require('engine.interface.ActorAI'):loadDefinition(filename) end,
	achievements = function(filename) require('engine.interface.WorldAchievements'):loadDefinition(filename) end,
	objects = 'object',
	encounters = 'encounter',
	stores = 'store',
	egos = 'ego',
	npcs = 'npc',}

local entity_list = function(directory)
	if directory:sub(-1) ~= '/' then directory = directory .. '/' end
	return function(full, base)
		local f, err = loadfile(full)
		if err then error(err) end
		class:bindHook('Entity:loadList', function(self, data)
				if data.file ~= directory..base or data.loaded[full] then return end
				self:loadList(full, data.no_default, data.res, data.mod, data.loaded)
				end)
		end end

util.load_actions = {
	birth = function(filename) require('engine.Birther'):loadDefinition(filename) end,
	talent = function(filename) require('engine.interface.ActorTalents'):loadDefinition(filename) end,
	effect = function(filename) require('engine.interface.ActorTemporaryEffects'):loadDefinition(filename) end,
	lore = function(filename) require('mod.class.interface.PartyLore'):loadDefinition(filename) end,
	damage_type = function(filename) require('engine.DamageType'):loadDefinition(filename) end,
	autolevel = function(filename) require('engine.Autolevel'):loadDefinition(filename) end,
	object = entity_list '/data/general/objects/',
	ego = entity_list '/data/general/objects/egos/',
	npc = entity_list '/data/general/npcs/',
	encounter = entity_list '/data/general/encounters/',
	store = function(filename)
		-- Won't work until 1.3. So we'll call that code directly.
		-- mod.class.Store:loadStores(filename)
		mod.class.Store:loadList(filename, nil, mod.class.Store.stores_def)
		end,}

util.file_actions = {
	['birth.lua'] = 'birth',
	['talents.lua'] = 'talent',
	['effects.lua'] = 'effect',
	['lore.lua'] = 'lore',
	['damage-types.lua'] = 'damage_type',
	['damage_types.lua'] = 'damage_type',
	['autolevels.lua'] = 'autolevel',
	['autolevel_schemes.lua'] = 'autolevel',
	['stores.lua'] = 'store',}

--- Recursively load a directory according to file names.
function util.load_dir(dir, mode)
	for _, file in ipairs(fs.list(dir)) do
		local full = dir .. '/' .. file
		if fs.isdir(full) then
			local sub_mode = mode
			if not sub_mode then
				full = full .. '/'
				sub_mode = util.getval(util.dir_actions[file], full, file) end
			util.load_dir(full, sub_mode)
		else
			local action = util.load_actions[mode or util.file_actions[file]]
			if action then action(full, file) end
			end end end
