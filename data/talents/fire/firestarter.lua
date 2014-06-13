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
local ACTOR = require('engine.Map').ACTOR
local TERRAIN = require('engine.Map').TERRAIN

newTalentType {
	type = 'elemental/firestarter',
	name = 'Firestarter',
	description = 'Fan the Flames',
	allow_random = true,}

local make_require = function(tier)
	return {
		stat = {dex = function(level) return 2 + tier * 8 + level * 2 end,},
		level = function(level) return -5 + tier * 4 + level end,}
end

newTalent {
	name = 'Blazing Rush',
	type = {'elemental/firestarter', 1,},
	require = make_require(1),
	points = 5,
	cooldown = 16,
	tactical = {ESCAPE = 2,},
	range = function(self, t) return self:combatTalentScale(t, 2, 6) end,
	damage = function(self, t) return self:elementalScale(t, 'dex', 10, 25) end,
	heat = 0, -- Make you learn heat pool.
	heat_gain = 25,
	no_energy = 'fake',
	target = function(self, t)
		return {type = 'hit', range = util.getval(t.range, self, t), talent = t,}
	end,
	action = function(self, t)
		local _
		local tg = util.getval(t.target, self, t)
		local x, y = self:getTarget(tg)
		if not x or not y then return end
		_, x, y = self:canProject(tg, x, y)
		if not self:canMove(x, y) then return end

		local damage = self:heatScale(util.getval(t.damage, self, t))
		local duration = 1
		local hit = false

		local block = function(_, x, y)
			return game.level.map:checkEntity(x, y, TERRAIN, 'block_move', self)
		end
		local line = self:lineFOV(x, y, block)
		local lx, ly = self.x, self.y
		local blocked
		while not blocked and lx and ly and (lx ~= x or ly ~= y) and not block(nil, lx, ly) do
			local effect = game.level.map:addEffect(
				self, lx, ly, duration, 'FIRE', self:spellCrit(damage),
				0, 5, nil, {type = 'inferno',}, nil, false)
			effect.name = 'flames'
			duration = duration + 1

			local actor = game.level.map(lx, ly, ACTOR)
			if actor and actor ~= self then
				hit = true
			end

			lx, ly, blocked = line:step()
		end

		local ox, oy = self.x, self.y
		self:move(x, y, true)
		if config.settings.tome.smooth_move > 0 then
			self:resetMoveAnim()
			self:setMoveAnim(ox, oy, 8, 5)
		end

		if hit then self:incHeat(util.getval(t.heat_gain, self, t)) end

		game:playSoundNear(self, 'talents/fire')

		return true
	end,
	info = function(self, t)
		local damage = util.getval(t.damage, self, t)
		return ([[Rushes through enemies to target position up to %d tiles away, creating a wake of flames in the path. The flames deal %d <%d> fire damage to anything standing in them. The furthest flame lasts 1 turn, with each closer flame lasting 1 more turn. If you strike any enemies during the rush, you will gain %d heat.
This is a movement action.
Fire damage scales with dexterity.
#GREY#Numbers shown are for 100%% heat, numbers in <brackets> are the actual amounts based on your current heat.]])
			:format(util.getval(t.range, self, t),
							Talents.damDesc(self, 'FIRE', self:heatScale(damage, 100)),
							Talents.damDesc(self, 'FIRE', self:heatScale(damage)),
							util.getval(t.heat_gain, self, t))
	end,}
