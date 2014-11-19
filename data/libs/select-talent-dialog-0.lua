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

-- Lets the user select from a list of talents an actor knows.

local Dialog = require 'engine.ui.Dialog'
local Textzone = require 'engine.ui.Textzone'
local TextzoneList = require 'engine.ui.TextzoneList'
local TreeList = require 'engine.ui.TreeList'
local Separator = require 'engine.ui.Separator'

if not select(2, table.get('grayswandir', 'class')) then table.set(_G, 'grayswandir', 'class', {}) end

local STD = {}
grayswandir.class.SelectTalentDialog = class.make(STD)
class.inherit(Dialog)(STD)

function STD:init(t)
	self.actor = t.actor
	assert(t.actor, 'SelectTalentDialog:init - No actor.')
	self.filter = t.filter
	self.actor.hotkey = self.actor.hotkey or {}
	Dialog.init(self, t.title or 'Select Talent', game.w * 0.6, game.h * 0.8)

	local child_width = math.floor(self.iw / 2 - 10)

	self.c_tut = Textzone.new {
		width = child_width,
		height = 1, auto_height = true,
		no_color_bleed = true,
		text = t.message or 'Select a talent.',}

	self.c_desc = TextzoneList.new {
		width = child_width,
		height = self.ih - self.c_tut.h - 20,
		scrollbar = true, no_color_bleed = true,}

	self:generateList()

	local cols = {
		{name = '', width = {40, 'fixed',}, display_prop = 'char',},
		{name = 'Talent', width = 80, display_prop = 'name',},}

	self.c_list = TreeList.new {
		width = child_width,
		height = self.ih - 10,
		all_clicks = true, scrollbark = true,
		columns = cols, tree = self.list,
		fct = function(item, sel, button) self:use(item, button) end,
		select = function(item, sel) self:select(item) end,}
	self.c_list.cur_col = 2

	self:loadUI {
		{left = 0, top = 0, ui = self.c_list,},
		{right = 0, top = self.c_tut.h + 20, ui = self.c_desc,},
		{right = 0, top = 0, ui = self.c_tut,},
		{hcenter = 0, top = 5, ui = Separator.new {dir = 'horizontal', size = self.ih - 10,},},}
	self:setFocus(self.c_list)
	self:setupUI()

	self.key:addBinds {
		EXIT = function() game:unregisterDialog(self) end,}

	end

function STD:on_register()
	game:onTickEnd(function() self.key:unicodeInput(true) end)
	end

function STD:select(item)
	if not item then return end
	self.c_desc:switchItem(item, item.desc)
	self.cur_item = item
	end

function STD:use(item)
	if not item or not item.talent then return end
	self.actor:talentDialogReturn(item.talent)
	game:unregisterDialog(self)
	end

-- Display the player tile
function STD:innerDisplay(x, y, nb_keyframes)
	if not self.cur_item or not self.cur_item.entity then return end
	self.cur_item.entity:toScreen(
		game.uiset.hotkeys_display_icons.tiles,
		x + self.iw - 64,
		y + self.iy + self.c_tut.h - 32 + 10,
		64, 64)
	end

function STD:generateList()
	-- Makes up the list
	local list = {}
	local letter = 1

	local talents = {}
	local chars = {}

	-- Generate lists of all talents by category
	for j, t in pairs(self.actor.talents_def) do
		if not self.filter or self.filter(t) then
			local nodes = talents
			local status = tstring{{"color", "LIGHT_GREEN"}, "Talents"}

			-- Pregenerate icon with the Tiles instance that allows images
			if t.display_entity then t.display_entity:getMapObjects(game.uiset.hotkeys_display_icons.tiles, {}, 1) end

			table.insert(nodes, {
				name = ((t.display_entity and t.display_entity:getDisplayString() or "")..t.name):toTString(),
				cname = t.name,
				status = status,
				entity = t.display_entity,
				talent = t.id,
				desc = self.actor:getTalentFullDescription(t),
				color = function() return {0xFF, 0xFF, 0xFF} end,})
			end
		end
	table.sort(talents, function(a, b) return a.cname < b.cname end)

	for i, node in ipairs(talents) do
		node.char = self:makeKeyChar(letter)
		chars[node.char] = node
		letter = letter + 1
		end

	list = {{char = '', name = ('#{bold}#Choose a talent#{normal}#'):toTString(),
			status='', hotkey='', desc = 'All available talents.',
			color = function() return colors.simple(colors.LIGHT_GREEN) end,
			nodes = talents, shown = true,},
		chars = chars,}

	self.list = list
	end
