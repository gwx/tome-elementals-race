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


local talents = require 'engine.interface.ActorTalents'
local damDesc = talents.damDesc
local particles = require 'engine.Particles'
local map = require 'engine.Map'

newEffect {
	name = 'ERUPTION', image = 'talents/eruption.png',
	desc = 'Eruption Power',
	long_desc = function(self, eff)
		return ([[Target's fire damage is increased by %d%%.]]):format(eff.fire)
	end,
	type = 'physical',
	subtype = {nature = true, fire = true,},
	status = 'beneficial',
	parameters = {fire = 10,},
	on_gain = function(self, eff)
		return '#Target# erupts with firey energy!', '+Eruption Power'
	end,
	on_lose = function(self, eff)
		return '#Target# has lost some firey energy!', '-Eruption Power'
	end,
	activate = function(self, eff)
		self:effectTemporaryValue(eff, 'inc_damage', {FIRE = eff.fire,})
	end,}

newEffect {
	name = 'CONSUMED_FLAME', image = 'talents/consume.png',
	desc = 'Consumed Flame',
	long_desc = function(self, eff)
		return ([[Target gains %d heat every turn.]]):format(eff.heat)
	end,
	type = 'physical',
	subtype = {nature = true, fire = true,},
	status = 'beneficial',
	parameters = {heat = 10,},
	on_gain = function(self, eff)
		return '#Target# consumes its own heat!', '+Consumed Flame'
	end,
	on_lose = function(self, eff)
		return '#Target#\'s consumed heat runs out!', '-Consumed Flame'
	end,
	on_timeout = function(self, eff)
		self:incHeat(eff.heat)
	end,}
