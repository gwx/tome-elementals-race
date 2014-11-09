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

local get = util.getval

newTalentType {
	type = 'elemental/chaos',
	name = 'Chaos',
	generic = true,
	description = 'A true flame cannot be controlled.',
	allow_random = true,}

local make_require = function(tier)
	return {
		stat = {mag = function(level) return 2 + tier * 8 + level * 2 end,},
		level = function(level) return -5 + tier * 4 + level end,}
	end

newTalent {
	name = 'Backburner',
	type = {'elemental/chaos', 1,},
	mode = 'sustained',
	points = 5,
	cooldown = 25,
	require = make_require(1),
	heat_inc = function(self, t) return self:scale {low = 20, high = 40, t} end,
	activate = function(self, t) return {current_heat = 0, last_heat = 0} end,
	deactivate = function(self, t) return true end,
	callbackOnIncHeat = function(self, t, heat)
		if self:attr '__inhibit_backburner' then return end
		heat.value = (100 + get(t.heat_inc, self, t)) * heat.value * 0.005
		local p = self:isTalentActive(t.id)
		p.current_heat = p.current_heat + heat.value
		return true end,
	callbackOnActBase = function(self, t)
		local p = self:isTalentActive(t.id)

		self:attr('__inhibit_backburner', 1)
		self:incHeat(p.last_heat)
		self:attr('__inhibit_backburner', -1)

		p.last_heat = p.current_heat
		p.current_heat = 0
		end,
	info = function(self, t)
		return ([[Your flames burn hotter, but take longer to set in.
While this talent is active you generate %d%% #SLATE#[*]#LAST# more heat from all sources, but smeared over 2 turns.]]):format(get(t.heat_inc, self, t))
		end,}
