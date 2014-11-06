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

-- Magic to find the current addon name.
local index = 1
local name, value
while true do
	name, value = debug.getlocal(3, index)
	if not name then
		error 'Could not find current addon name.'
	elseif 'dir' == name then
		__loading_addon = value:sub(8) -- strip off '/hooks/'
		break
	else
		index = index + 1
		end	end

----------------------------------------------------------------
-- Libs System v1

if not lib then
	lib = {}
	lib.version = {}
	lib.loaded = {}
	lib.require = function(name, min_version)
		min_version = min_version or -math.huge
		local libs_dir = '/data-'..__loading_addon..'/libs/'
		local libs = fs.list(libs_dir)
		local matcher = '^'..name:gsub('%-', '%%-')..'%-([%d%.]+)%.lua$'
		for _, libname in pairs(libs) do
			local version = tonumber(({libname:find(matcher)})[3])
			if version and
				version > (lib.version[name] or -math.huge) and
				version >= min_version
			then
				local err
				lib.loaded[name], err = loadfile(libs_dir..libname)
				if err then error(err) end
				setfenv(lib.loaded[name], setmetatable({
							superload = function(class, fun) util.add_superload(class, name, fun) end,
							hook = function(hook, fun) util.bind_hook(hook, name, fun) end,},
						{__index = _G,}))
				lib.version[name] = version
				lib.loaded[name]()
				return true end end
		assert(lib.version[name],
			('Addon <%s> could not find needed lib <%s>.'):format(__loading_addon, name))
		assert(lib.version[name] >= min_version,
			('Addon <%s> needs lib <%s> of at least version %s.'):format(__loading_addon, name, min_version))
		end
	lib.require_all = function()
		local libs_dir = '/data-'..__loading_addon..'/libs/'
		local libs = fs.list(libs_dir)
		local matcher = '^(.+)%-([%d%.]+)%.lua$'
		for _, libname in pairs(libs) do
			local _, _, name, version = libname:find(matcher)
			version = tonumber(version)
			if version and version > (lib.version[name] or -math.huge) then
				local err
				lib.loaded[name], err = loadfile(libs_dir..libname)
				if err then error(err) end
				setfenv(lib.loaded[name], setmetatable({
							superload = function(class, fun) util.add_superload(class, name, fun) end,
							hook = function(hook, fun) util.bind_hook(hook, name, fun) end,},
						{__index = _G,}))
				lib.version[name] = version
				lib.loaded[name]()
				end end end end


----------------------------------------------------------------
-- Hooks Id v1
if not util.bind_hook then
	local _hooks
	local i = 1
	while true do
		local name, value = debug.getupvalue(class.bindHook, i)
		if not name then error('Cannot find _hooks.') end
		if '_hooks' == name then
			_hooks = value
			break end
		i = i + 1
		end

	local hook_indices = {}
	util.bind_hook = function(hook_name, id, fun)
		local hook = hook_indices[hook_name]
		if not hook then
			hook = {}
			hook_indices[hook_name] = hook
			end

		if not hook[id] then
			class:bindHook(hook_name, fun)
			hook[id] = #_hooks.list[hook_name]
		else
			_hooks.list[hook_name] = fun
			end
		end
	end

----------------------------------------------------------------
-- Additional Superloads

if not __additional_superloads then
	__additional_superloads = {}

	--- Adds a superload for a class.
	-- @param class the class name to superload
	-- @param fun the superloading function - takes the class as an argument
	util.add_superload = function(class, id, fun)
		local class_superloads = table.get(_G, '__additional_superloads', class)
		if not class_superloads then
			class_superloads = {}
			table.set(_G, '__additional_superloads', class, class_superloads)
			end
		if class_superloads[id] then
			-- Overwrite original definition.
			class_superloads[class_superloads[id]] = fun
		else
			-- Insert and save position.
			table.insert(class_superloads, fun)
			class_superloads[id] = #class_superloads
			end end

	local te4_loader = package.loaders[3]
	package.loaders[3] = function(name)
		local base = te4_loader(name)
		if base then
			local superloads = _G.__additional_superloads[name] or {}
			for id, index in pairs(superloads) do
				if type(id) ~= 'number' then
					local f = superloads[index]
					local prev = base
					base = function(name)
						prev(name)
						print('FROM', name, id, 'loading special.')
						local _M = package.loaded[name]
						f(_M)
						return _M
						end
					end
				end
			return base
			end
		end
	end

----------------------------------------------------------------

lib.require_all()

-- Load all other hook files.
local hooks_dir = '/hooks/'..__loading_addon..'/'
for _, file in ipairs(fs.list(hooks_dir)) do
	if file ~= 'load.lua' then
		dofile(hooks_dir..file)
		end
	end

----------------------------------------------------------------

__loading_addon = nil
