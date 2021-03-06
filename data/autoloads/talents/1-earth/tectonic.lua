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
local map = require 'engine.Map'
local ACTOR = map.ACTOR
local TERRAIN = map.TERRAIN
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
				if not game.level.map(wx, wy, Map.ACTOR) and not terrain.does_block_move then
					local e = active_terrain.create {
						src = self,
						terrain_name = 'BOULDER',
						terrain_file = '/data-elementals-race/terrain.lua',
						name = self.name:capitalize()..'\'s Chasm',
						desc = 'a rocky chasm',
						temporary = duration + 1,
						x = wx, y = wy,
						nice_tiler = false,
						copy_missing = terrain,
						can_dig = true,
						nicer_tiles = 'self',}
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
							Talents.damDesc(self, DamageType.PHYSICAL, util.getval(t.physical_damage, self, t)),
							util.getval(t.duration, self, t))
	end,}

newTalent {
	name = 'Separation',
	type = {'elemental/tectonic', 2,},
	require = make_require(2),
	points = 5,
	essence = 14,
	cooldown = 10,
	range = 0,
	radius = 4,
	damage = function(self, t)
		return self:combatTalentPhysicalDamage(t, 70, 280)
	end,
	stun = 2,
	tactical = {ATTACKAREA = {PHYSICAL = 2}, DISABLE = {STUN = 1,},},
	target = function(self, t)
		return {type = 'ball', talent = t, selffire = false,
						range = util.getval(t.range, self, t),
						radius = util.getval(t.radius, self, t) - 1,}
	end,
	action = function(self, t)
		local tg = util.getval(t.target, self, t)
		local radius = tg.radius + 1
		local targets = {}
		local projector = function(x, y, tg, self)
			local actor = game.level.map(x, y, ACTOR)
			if not actor then return end
			table.insert(targets, {
										 x = x,
										 y = y,
										 actor = actor,
										 distance = core.fov.distance(self.x, self.y, x, y),})
		end
		self:project(tg, self.x, self.y, projector)

		game.level.map:particleEmitter(
			self.x, self.y, radius, 'shout', {
				additive = true,
				life = 6,
				size = 12,
				distorion_factor = -1,
				radius = radius,
				nb_circles = 5,
				rm = 0.3, rM = 0.7,
				gm = 0.3, gM = 0.7,
				bm = 0.1, bM = 0.2,
				am = 0.4, aM = 0.6})
		game:playSoundNear(self, 'talents/earth')

		if #targets == 0 then return true end

		table.sort(targets, function(a, b) return a.distance > b.distance end)

		local damage = util.getval(t.damage, self, t)
		local stun = util.getval(t.stun, self, t)
		local power = self:combatPhysicalpower()
		for _, target in pairs(targets) do
			local actor = target.actor
			if actor:canBe('knockback') then
				-- If we hit a solid tile, take damage and stun.
				local on_terrain = function(terrain, x, y)
					if not actor:canMove(x, y, true) then
						-- onTickEnd so we can see them get knocked back before they die.
						game:onTickEnd(
							function()
								local dam = self:physicalCrit(
									damage, nil, actor, self:combatAttack(), actor:combatDefense())
								DamageType:get(DamageType.PHYSICAL).projector(
									self, actor.x, actor.y, DamageType.PHYSICAL, dam)
								if actor:canBe('stun') then
									actor:setEffect('EFF_STUNNED', stun, {apply_power = power,})
								end
						end)
						return true
					end
				end
				actor:knockback(self.x, self.y, radius - target.distance, nil, on_terrain)
			end
		end

		return true
	end,
	info = function(self, t)
		return ([[Knocks back all nearby enemies out to a radius of %d. Enemies knocked into walls take %d physical damage and are stunned for %d turns.]])
			:format(util.getval(t.radius, self, t),
							Talents.damDesc(self, DamageType.PHYSICAL, util.getval(t.damage, self, t)),
							util.getval(t.stun, self, t))
	end,}

newTalent {
	name = 'Resonating Stone',
	type = {'elemental/tectonic', 3,},
	require = make_require(3),
	points = 5,
	mode = 'passive',
	duration = function(self, t)
		return math.floor(self:combatTalentScale(t, 3, 5))
	end,
	radius = function(self, t)
		return math.floor(self:combatTalentScale(t, 1, 3))
	end,
	damage = function(self, t)
		return self:combatTalentPhysicalDamage(t, 20, 80)
	end,
	gloom = function(self, t)
		return self:combatTalentSpellDamage(t, 0, 25)
	end,
	resonate_action = function(terrain)
		terrain.resonating.duration = terrain.resonating.duration - 1
		if terrain.resonating.duration <= 0 then
			terrain:removeAction('resonate')
		else
			game.level.map:particleEmitter(
				terrain.x, terrain.y, radius, 'shout', {
					additive = true,
					life = 4,
					size = 2,
					distorion_factor = 0.3,
					radius = 1,
					nb_circles = 3,
					rm = 0.7, rM = 0.9,
					gm = 0.7, gM = 0.9,
					bm = 0.7, bM = 0.9,
					am = 0.4, aM = 0.6})
			local tg = {type = 'ball', range = 0, radius = 1,
									selffire = false, friendlyfire = false,
									start_x = terrain.x, start_y = terrain.y,}
			local damage_type = require 'engine.DamageType'
			terrain.src.__project_source = {name = ('%s\'s resonance'):format(terrain.src.name:capitalize())}
			terrain.src:project(
				tg, terrain.x, terrain.y, damage_type.PHYSICAL, terrain.resonating.damage)
			terrain.src:project(
				tg, terrain.x, terrain.y, damage_type.ITEM_MIND_GLOOM, terrain.resonating.gloom)
			terrain.src.__project_source = nil
		end
	end,
	info = function(self, t)
		return ([[All walls manipulated or created by you resonate for %d turns.
Destroying walls also resonates all walls within radius %d.
Resonating terrain deals %d physical damage and has a %d%% chance to cause random insanity to adjacent enemies each turn.]])
			:format(util.getval(t.duration, self, t),
							util.getval(t.radius, self, t),
							Talents.damDesc(self, DamageType.PHYSICAL, util.getval(t.damage, self, t)),
							util.getval(t.gloom, self, t))
	end,}

newTalent {
	name = 'Detonation',
	type = {'elemental/tectonic', 4,},
	require = make_require(4),
	points = 5,
	essence = 18,
	cooldown = 14,
	tactical = {ATTACKAREA = {PHYSICAL = 2}, DISABLE = {CONFUSE = 1,},},
	range = function(self, t)
		return math.floor(self:combatTalentScale(t, 3, 5))
	end,
	damage = function(self, t)
		return self:combatTalentPhysicalDamage(t, 60, 220)
	end,
	bleed = 3,
	radius = 3,
	radius2 = 1,
	target = function(self, t)
		return {type = 'ball', ball_not_radius = true,
						range = util.getval(t.range, self, t),
						radius = util.getval(t.radius, self, t),}
	end,
	damage = function(self, t)
		return self:combatTalentPhysicalDamage(t, 70, 280)
	end,
	confuse_power = function(self, t)
		return self:combatTalentPhysicalDamage(t, 20, 70)
	end,
	confuse = 2,
	action = function(self, t)
		local _
		local tg = util.getval(t.target, self, t)
		local x, y = self:getTarget(tg)
		if not x or not y then return end
		_, x, y = self:canProject(tg, x, y)

		local terrain = game.level.map(x, y, map.TERRAIN)
		if not terrain.dig then return end

		self:project({type = 'hit', range = tg.range,}, x, y, DamageType.DIG)

		-- Damage
		tg = {type = 'ball', selffire = false,
					range = 0, start_x = x, start_y = y,
					radius = util.getval(t.radius, self, t),}
		local damage = util.getval(t.damage, self, t)
		local bleed_duration = util.getval(t.bleed, self, t)
		local bleed = damage / bleed_duration
		local radius2 = util.getval(t.radius2, self, t)
		local confuse = util.getval(t.confuse, self, t)
		local confuse_power = util.getval(t.confuse_power, self, t)
		local projector = function(x, y, tg, self)
			local crit_add = 0
			local do_confuse = false

			local range = core.fov.distance(self.x, self.y, x, y)
			if range <= radius2 then
				crit_add = 100
				do_confuse = true
			end

			local actor = game.level.map(x, y, ACTOR)
			if not actor then return end

			local mult = self:physicalCrit(1, nil, actor, self:combatAttack(), actor:combatDefense(), crit_add)
			DamageType:get(DamageType.PHYSICAL).projector(
				self, x, y, DamageType.PHYSICAL, damage * mult)

			if actor:canBe('cut') then
				actor:setEffect('EFF_CUT', bleed_duration, {power = bleed * mult,})
			end

			if do_confuse and actor:canBe('confuse') then
				actor:setEffect('EFF_CONFUSED', confuse, {
													apply_power = self:combatPhysicalpower(),
													power = confuse_power,})
			end
		end
		self:project(tg, x, y, projector)

		game.level.map:particleEmitter(x, y, tg.radius + 1, 'ball_earth', {radius = tg.radius + 1,})
		game:playSoundNear({x = x, y = y,}, 'talents/lightning_loud')

		if self:knowTalent('T_RESONATING_STONE') then
			tg = {type = 'ball', no_restrict = true,
						filter = function(x, y)
							local terrain = game.level.map(x, y, TERRAIN)
							return terrain.dig
						end,
						range = 0,
						radius = self:callTalent('T_RESONATING_STONE', 'radius'),
						start_x = x, start_y = y,}
			projector = function(x, y, tg, self)
				local terrain = game.level.map(x, y, TERRAIN)
				if terrain.resonate then
					terrain:resonate()
				else
					active_terrain.create {
						src = self,
						terrain = terrain,
						x = x, y = y,
						action_list = {
							stop_on_resonate_finish = function(self)
								local eutil = require 'elementals-race.util'
								local duration = eutil.get(self, 'resonating', 'duration')
								if not duration or duration <= 0 then
									self:removeLevel()
								end
							end,},}
				end
			end
			self:project(tg, x, y, projector)
		end

		return true
	end,
	info = function(self, t)
		return ([[Detonates the target wall in range of %d, showering all targets within %d tiles with deadly shrapnel, destroying the wall in the process. Targets hit take %d physical damage, once on hit and once as bleeding damage over %d turns.
Targets within %d tile(s) of the destroyed wall are hit critically and are also confused with %d%% power for %d turns.
Damage, confusion chance and power scale with physical power.]])
			:format(util.getval(t.range, self, t),
							util.getval(t.radius, self, t),
							Talents.damDesc(self, DamageType.PHYSICAL, util.getval(t.damage, self, t)),
							util.getval(t.bleed, self ,t),
							util.getval(t.radius2, self, t),
							util.getval(t.confuse_power, self, t),
							util.getval(t.confuse, self, t))
	end,}
