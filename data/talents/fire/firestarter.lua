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
local stats = require 'engine.interface.ActorStats'

newTalentType {
	type = 'elemental/firestarter',
	name = 'Firestarter',
	generic = true,
	description = 'Fan the Flames',
	allow_random = true,}

local make_require = function(tier)
	return {
		stat = {dex = function(level) return 2 + tier * 8 + level * 2 end,},
		level = function(level) return -5 + tier * 4 + level end,}
end

newTalent {
	name = 'Firedancer',
	type = {'elemental/firestarter', 1,},
	require = make_require(1),
	points = 5,
	mode = 'passive',
	speed = function(self, t) return self:elementalScale(t, 'dex', 0.03, 0.2) end,
	accuracy = function(self, t) return self:elementalScale(t, 'dex', 10, 40) end,
	crit = function(self, t) return self:elementalScale(t, 'dex', 2, 10) end,
	heat_gain = function(self, t) return math.floor(self:combatTalentScale(t, 2, 6)) end,
	heat_threshold = 50,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, 'global_speed_add', self:heatScale(util.getval(t.speed, self, t)))
		self:talentTemporaryValue(p, 'combat_atk', self:heatScale(util.getval(t.accuracy, self, t)))
		self:talentTemporaryValue(p, 'combat_physcrit', self:heatScale(util.getval(t.crit, self, t)))
		self:talentTemporaryValue(p, 'heat_step_threshold', util.getval(t.heat_threshold, self, t))
		self:talentTemporaryValue(p, 'heat_step_gain', util.getval(t.heat_gain, self, t))
	end,
	recompute_passives = {stats = {stats.STAT_DEX,},},
	info = function(self, t)
		local speed = util.getval(t.speed, self, t) * 100
		local accuracy = util.getval(t.accuracy, self, t)
		local crit = util.getval(t.crit, self, t)
		return ([[Increases your global speed by %d%% <%d%%>, your accuracy by %d <%d> and physical crit chance by %d%% <%d%%>. These scale with dexterity.
You recover %d heat with every tile you moved, provided you are under %d heat.
#GREY#Numbers shown are for 100%% heat, numbers in <brackets> are the actual amounts based on your current heat.]])
			:format(self:heatScale(speed, 100), self:heatScale(speed),
							self:heatScale(accuracy, 100), self:heatScale(accuracy),
							self:heatScale(crit, 100), self:heatScale(crit),
							util.getval(t.heat_gain, self, t),
							util.getval(t.heat_threshold, self, t))
	end,}

newTalent {
	name = 'Blazing Rush',
	type = {'elemental/firestarter', 2,},
	require = make_require(2),
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
