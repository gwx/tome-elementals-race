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


local eutil = require 'elementals-race.util'
local active_terrain = require 'elementals-race.active-terrain'
local grid = require 'mod.class.Grid'
local stats = require 'engine.interface.ActorStats'
local object = require 'mod.class.Object'

newTalentType {
	type = 'elemental/geothermal',
	name = 'Geothermal',
	description = 'Burning Earth',}

local make_require = function(tier)
	return {
		stat = {mag = function(level) return 2 + tier * 8 + level * 2 end,},
		level = function(level) return -5 + tier * 4 + level end,}
end

newTalent {
	name = 'Rock Mortar',
	type = {'elemental/geothermal', 1,},
	require = make_require(1),
	points = 5,
	essence = 5,
	cooldown = 3,
	tactical = {ATTACK = 3,},
	range = 4, radius = 1,
	damage = function(self, t)
		return self:combatTalentSpellDamage(t, 15, 180)
	end,
	reflect = function(self, t)
		return self:combatTalentScale(t, 0.03, 0.1)
	end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, 'jaggedbody_reflect', util.getval(t.reflect, self, t))
	end,
	target = function(self, t)
		return {
			type = 'ball', talent = t,
			range = util.getval(t.range, self, t),
			radius = util.getval(t.radius, self, t),}
	end,
	action = function(self, t)
		local _
		local tg = self:getTalentTarget(t)
		local x, y = self:getTarget(tg)
		if not x or not y then return end
		_, _, _, x, y = self:canProject(tg, x, y)

		local dam = util.getval(t.damage, self, t)
		local projector = function(x, y, tg, self)
			DamageType:get(DamageType.PHYSICAL).projector(
				self, x, y, DamageType.PHYSICAL, dam)
			DamageType:get(DamageType.FIRE).projector(
				self, x, y, DamageType.FIRE, dam)
		end
		self:project(tg, x, y, projector)

		game.level.map:particleEmitter(x, y, tg.radius, "ball_earth", {radius = tg.radius,})
		game:playSoundNear(self, 'talents/fire')
		return true
	end,
	info = function(self, t)
		local damage = util.getval(t.damage, self, t)
		return ([[Fires a rock mortar at the target, dealing %d physical and %d fire damage in radius %d.
Also, Jagged Body returns %d%% more damage.
Damage increases with spellpower.]])
			:format(
				Talents.damDesc(self, DamageType.PHYSICAL, damage),
				Talents.damDesc(self, DamageType.FIRE, damage),
				util.getval(t.radius, self, t),
				util.getval(t.reflect, self, t) * 100)
	end,}
