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
--local stats = require 'engine.interface.ActorStats'
--local object = require 'mod.class.Object'

newTalentType {
	type = 'elemental/tectonic',
	name = 'Tectonic',
	description = 'Shake the Earth.',
	allow_random = true,}

local make_require = function(tier)
	return {
		stat = {str = function(level) return 12 + tier * 8 + level * 2 end,},
		level = function(level) return 5 + tier * 4 + level end,}
end

newTalent {
	name = 'Chasm',
	type = {'elemental/tectonic', 1,},
	require = make_require(1),
	points = 5,
	essence = 10,
	cooldown = 13,
	weapon_damage = 1,
	physical_damage = function(self, t)
		return self:combatTalentPhysicalDamage(t, 30, 140)
	end,
	duration = function(self, t)
		return math.ceil(self:combatTalentScale(t, 3, 5))
	end,
	range = 4,
	tactical = {ATTACK = {WEAPON = 2, PHYSICAL = 2},},
	target = function(self, t)
		return {type = 'bolt', talent = t,
						range = util.getval(t.range, self, t),}
	end,
	action = function(self, t)
		local _
		local tg = util.getval(t.target, self, t)
		local x, y = self:getTarget(tg)
		if not x or not y then return end
		if x == self.x and y == self.y then return end
		_, x, y = self:canProject(tg, x, y)

		local projector = function(x, y, tg, self)
			local target = game.level.map(x, y, Map.ACTOR)

			-- Damage part.
			if target then
				self:attackTarget(target, nil, util.getval(t.weapon_damage, self, t))

				local damage = util.getval(t.physical_damage, self, t)
				damage = self:physicalCrit(damage, nil, target, self:combatAttack(), target:combatDefense())
				DamageType:get(DamageType.PHYSICAL).projector(
					self, x, y, DamageType.PHYSICAL, damage)
			end

			-- Wall part.

			-- Figure out the wall shape.
			local dir = util.getDir(x, y, self.x, self.y)
			local dx, dy = util.dirToCoord(dir)
			local walls
			-- Diagonal.
			if dx ~= 0 and dy ~= 0 then
				walls = {
					{x = dx, y = -dy,},
					{x = dx, y = 0,},
					{x = dx, y = dy,},
					{x = 0, y = dy,},
					{x = -dx, y = dy,},}
			-- Horizontal.
			elseif dx ~= 0 then
				walls = {
					{x = 0, y = 1,},
					{x = dx, y = 1,},
					{x = dx, y = 0,},
					{x = 2 * dx, y = 0,},
					{x = dx, y = -1,},
					{x = 0, y = -1},}
			-- Vertical.
			elseif dy ~= 0 then
				walls = {
					{x = 1, y = 0,},
					{x = 1, y = dy,},
					{x = 0, y = dy,},
					{x = 0, y = 2 * dy,},
					{x = -1, y = -dy,},
					{x = -1, y = 0,},}
			-- Failure.
			else
				return
			end

			-- Loop through and make the walls.
			local duration = util.getval(t.duration, self, t)
			for _, offsets in pairs(walls) do
				local wx, wy = x + offsets.x, y + offsets.y
				local terrain = game.level.map(wx, wy, Map.TERRAIN)
				if not terrain.does_block_move and
					not terrain.active_terrain and
					not terrain.special and not terrain.temporary and
					not game.level.map(wx, wy, Map.ACTOR)
				then
					local e = active_terrain.new {
						terrain = grid.new {
							type = terrain.type, subtype = terrain.subtype,
							name = self.name:capitalize()..'\'s Chasm',
							image = 'terrain/huge_rock.png',
							display = '#', color=colors.WHITE, --back_color=colors.DARK_GREY,
							always_remember = true,
							desc = 'a chasm',
							type = 'wall',
							can_pass = {pass_wall = 1},
							does_block_move = true,
							show_tooltip = true,
							block_move = true,
							block_sight = true,},
						temporary = duration + 1,
						x = wx, y = wy,
						canAct = false,
						dig = function(src, x, y, self)
							self:removeLevel()
						end,
						summoner_gain_exp = true,
						summoner = self,}
				end
				game.level.map:particleEmitter(wx, wy, 1, 'ball_matter', {radius = 1,})
			end
			game:playSoundNear({x = x, y = y,}, 'talents/earth')
		end

		self:project(tg, x, y, projector)
		return true
	end,
	info = function(self, t)
		return ([[Smites down an enemy in range %d, hitting them for %d%% weapon damage plus an additional %d physical damage. A prison of rocks will form behind them, cutting off their retreat for %d turns.]])
			:format(util.getval(t.range, self, t),
							util.getval(t.weapon_damage, self, t) * 100,
							util.getval(t.physical_damage, self, t),
							util.getval(t.duration, self, t))
	end,}
