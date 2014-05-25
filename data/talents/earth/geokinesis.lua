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
local entity = require 'engine.Entity'
local object = require 'mod.class.Object'
local stats = require 'engine.interface.ActorStats'
local particles = require 'engine.Particles'

newTalentType {
	type = 'elemental/geokinesis',
	name = 'Geokinesis',
	description = 'Magic Rocks.',}

local make_require = function(tier)
	return {
		stat = {mag = function(level) return 2 + tier * 8 + level * 2 end,},
		level = function(level) return -5 + tier * 4 + level end,}
end

newTalent {
	name = 'Earthen Gun',
	type = {'elemental/geokinesis', 1,},
	require = make_require(1),
	points = 5,
	essence = 3,
	range = 8,
	cooldown = 2,
	no_energy = 'fake',
	tactical = {ATTACK = 2,},
	autolearn_talent = 'T_RELOAD',
	target = function(self, t)
		return {type = 'beam', on_move = t.on_move, pierce = t.pierce(self, t),
						range = util.getval(t.range, self, t),}
	end,
	damage = function(self, t) return self:combatTalentSpellDamage(t, 50, 200) end,
	pierce = function(self, t) return 30 + self:combatSpellpower() * 0.7 end,
	shooter = entity.new {
		name = 'earthen gun',
		combat = {
			talented = 'earthen-gun', accuracy_effect = 'mace',
			sound = 'actions/sling', sound_miss = 'actions/sling',
			range = 8, physspeed = 0.8,},
		proj_image = resolvers.image_material('shot_s', 'metal'),},
	default_ammo = entity.new {
		combat = {
			shots_left = 0,
			accuracy_effect = 'mace', damrange = 1.2,
			dam = 5, apr = 1, physcrit = 3,
			dammod = {dex = 0.7, cun = 0.5,},},
		infinite = true,},
	passives = function(self, t, p)
		self:talentTemporaryValue(p, 'shots_sub_mag', 1)
	end,
	-- See Actor:projectDoMove.
	on_move = function(self, typ, tgtx, tgty, x, y, srcx, srcy, lx, ly, act, stop)
		if not stop and (x ~= srcx or y ~= srcy) then
			local actor = game.level.map(x, y, Map.ACTOR)
			if actor and not actor.dead and not rng.percent(typ.pierce) then
				stop = true
			end
		end
		return lx, ly, act, stop
	end,
	action = function(self, t)
		local default_ammo = false
		local ammo = eutil.get(self:getInven('QUIVER'), 1)
		if not ammo or
			((eutil.get(ammo, 'combat', 'shots_left') or 0) == 0 and not ammo.infinite)
		then
			default_ammo = true
			ammo = t.default_ammo
		end

		local archery_weapon_override = self.archery_weapon_override
		self.archery_weapon_override = {t.shooter, ammo,}

		local tg = util.getval(t.target, self, t)
		tg.speed = default_ammo and 10 or 20
		local targets = self:archeryAcquireTargets(tg, {one_shot = true,})
		if not targets then
			self.archery_weapon_override = archery_weapon_override
			return
		end

		local combat = table.clone(ammo.combat)
		combat.dammod.mag = (ammo.combat.dammod.mag or 0) + (combat.dammod.dex or 0)
		combat.dammod.str = (ammo.combat.dammod.str or 0) + (combat.dammod.cun or 0)
		combat.dammod.dex = nil
		combat.dammod.cun = nil
		eutil.update(
			eutil.adder(self:spellCrit(t.damage(self, t))),
			combat, 'ranged_project', DamageType.PHYSICAL)

		self.archery_weapon_override = {t.shooter, ammo,}
		for _, target in pairs(targets) do
			target.ammo = combat
		end

		self:archeryShoot(targets, t, tg, {atk = self:getMag() - self:getDex()})

		self.archery_weapon_override = archery_weapon_override
		return true
	end,
	info = function(self, t)
		return ([[Picks up a small pebble and accelerates it to 1000%% base speed to hit the target enemy for %d physical damage. If you are wearing shots in your ammo slot this applies the possible ammo effects to the shot, increases speed to 2000%% of base and allows the shot to pierce targets with %d%% chance.
Damage increases with spellpower, strength, and magic. Pierce chance increase with spellpower. Uses magic for accuracy instead of dexterity.
This allows you to substitute magic for dexterity when equipping shots.]])
			:format(t.damage(self, t), t.pierce(self, t))
	end,}

newTalent {
	name = 'Choking Dust',
	type = {'elemental/geokinesis', 2,},
	require = make_require(2),
	points = 5,
	essence = 10,
	cooldown = 15,
	range = 4,
	tactical = {ATTACK = 2, DISABLE = {SILENCE = 2,},},
	target = function(self, t)
		return {type = 'hit', range = util.getval(t.range, self, t),
						talent = t,}
	end,
	damage = function(self, t) return self:combatTalentSpellDamage(t, 30, 80) end,
	air = function(self, t) return 10 + self:combatTalentSpellDamage(t, 10, 20) end,
	ranged_penalty = function(self, t)
		return 10 + self:combatTalentSpellDamage(t, 0, 30)
	end,
	mistarget_chance = function(self, t)
		return 10 + self:combatTalentSpellDamage(t, 0, 50)
	end,
	mistarget_percent = function(self, t)
		return 0.4 + self:combatTalentSpellDamage(t, 0, 0.4)
	end,
	duration = function(self, t)
		return math.floor(2.5 + self:getTalentLevel(t) * 0.4)
	end,
	silence = function(self, t)
		return math.floor(self:getTalentLevel(t) * 0.35)
	end,
	action = function(self, t)
		local tg = util.getval(t.target, self, t)
		local x, y = self:getTarget(tg)
		if not x or not y then return end

		local target = game.level.map(x, y, Map.ACTOR)
		if not target then return end

		local spellpower = self:combatSpellpower()
		target:setEffect(
			'EFF_CHOKING_DUST', util.getval(t.duration, self, t), {
				src = self,
				damage = self:spellCrit(util.getval(t.damage, self, t)),
				air = util.getval(t.air, self, t),
				ranged_penalty = util.getval(t.ranged_penalty, self, t),
				mistarget_chance = util.getval(t.mistarget_chance, self, t),
				mistarget_percent = util.getval(t.mistarget_percent, self, t),
				apply_power = spellpower})

		local silence = util.getval(t.silence, self, t)
		if silence > 0 then
			target:setEffect('EFF_SILENCED', silence, {apply_power = spellpower,})
		end

		game.level.map:particleEmitter(x, y, 1, 'choking_dust', {})
		game:playSoundNear(target, 'talents/earth')
		return true
	end,
	info = function(self, t)
		return ([[Engulfs the target in a cloud of dust, suffocating it for %d turns. Each turn it will take %d physical damage and lose %d air. It will also have %d less ranged accuracy and have a %d%% chance to misaim its ranged attacks by up to %d%% of the original distance.
You will also silence the target for %d turns.
Damage and penalty strengths scale with spellpower.]])
			:format(
				t.duration(self, t),
				Talents.damDesc(self, DamageType.PHYSICAL, t.damage(self, t)),
				t.air(self, t),
				t.ranged_penalty(self, t),
				t.mistarget_chance(self, t),
				t.mistarget_percent(self, t) * 100,
				t.silence(self, t))
	end,}

local lm_preuse = function(self, t, silent)
	if not game.level then return true end

	local pass = eutil.get(self, 'can_pass', 'pass_wall')
	eutil.set(self, 'can_pass', 'pass_wall', 0)
	local use = self:canMove(self.x, self.y, true)
	self.can_pass.pass_wall = pass

	if not use and not silent then
		game.logPlayer(self, 'You cannot use this talent while on a solid tile.')
	end
	return use
end

newTalent {
	name = 'Living Mural',
	type = {'elemental/geokinesis', 3,},
	require = make_require(3),
	points = 5,
	mode = 'sustained',
	sustain_essence = 10,
	cooldown = 26,
	defense = function(self, t)
		return self:combatTalentSpellDamage(t, 8, 20)
	end,
	spellpower = function(self, t)
		return self:getTalentLevel(t) * 4
	end,
	on_pre_use = lm_preuse,
	on_pre_deactivate = lm_preuse,
	activate = function(self, t)
		local p = {}
		self:talentTemporaryValue(p, 'can_pass', {pass_wall = 70,})
		return p
	end,
	update_after_move = function(self, t, p)
		-- See if present location is passable.
		local pass = eutil.get(self, 'can_pass', 'pass_wall')
		eutil.set(self, 'can_pass', 'pass_wall', 0)
		local self_free = self:canMove(self.x, self.y, true)
		self.can_pass.pass_wall = pass

		-- Manage stats bonuses.
		if not self_free then
			if not p.defense then
				p.defense = self:addTemporaryValue('combat_def', util.getval(t.defense, self, t))
			end
			if not p.spell then
				p.spell = self:addTemporaryValue('combat_spellpower', util.getval(t.spellpower, self, t))
			end
		else
			if p.defense then
				self:removeTemporaryValue('combat_def', p.defense)
				p.defense = nil
			end
			if p.spell then
				self:removeTemporaryValue('combat_spellpower', p.spell)
				p.spell = nil
			end
		end

		if p.particles then
			self:removeParticles(p.particles)
			p.particles = nil
		end

		local anchor = self.living_mural_anchor
		if not self_free and anchor and (anchor.x ~= self.x or anchor.y ~= self.y) then
			local dx, dy = anchor.x - self.x, anchor.y - self.y
			p.particles = particles.new(
				'living_mural', math.max(math.abs(dx), math.abs(dy)), {tx = dx, ty = dy,})
			p.particles.tx = dx
			p.particles.ty = dy
			p.particles.x = self.x
			p.particles.y = self.y
			self:addParticles(p.particles)
		end
	end,
	deactivate = function(self, t, p)
		if p.defense then
			self:removeTemporaryValue('combat_def', p.defense)
			p.defense = nil
		end
		if p.spell then
			self:removeTemporaryValue('combat_spellpower', p.spell)
				p.spell = nil
		end
		if p.particles then
			self:removeParticles(p.particles)
			p.particles = nil
		end
		return true
	end,
	info = function(self, t)
		return ([[This allows you to enter walls 1 tile deep. Being submerged in a wall increases your defense by %d and spellpower by %d.
This ability cannot be used to pass through a thin wall. (A beam will appear to indicate which side of the wal you are currently on.)
Defense increases with spellpower.]])
			:format(util.getval(t.defense, self, t),
							util.getval(t.spellpower, self, t))
	end,}

newTalent {
	name = 'Architect\'s Wrath', short_name = 'ARCHITECTS_WRATH',
	type = {'elemental/geokinesis', 4,},
	require = make_require(4),
	points = 5,
	cooldown = 21,
	essence = 25,
	range = function(self, t)
		return 3 + math.floor(self:getTalentLevel(t) * 0.35)
	end,
	move = function(self, t)
		return 1 + math.floor(self:getTalentLevel(t) * 0.7)
	end,
	damage = function(self, t)
		return self:combatTalentSpellDamage(t, 70, 250)
	end,
	size = function(self, t)
		return math.min(3, 1 + math.floor(self:getTalentLevel(t) * 0.5))
	end,
	duration = 3,
	action = function(self, t)
		local _
		local is_wall = function(x, y)
			local terrain = game.level.map(x, y, Map.TERRAIN)
			return terrain.dig and eutil.get(terrain, 'can_pass', 'pass_wall')
		end

		-- Get first corner of wall section.
		local range = util.getval(t.range, self, t)
		local tg = {type = 'hit', range = range,}
		local x1, y1 = self:getTarget(tg)
		if not x1 or not y1 then return end
		_, x1, y1 = self:canProject(tg, x1, y1)
		if not is_wall(x1, y1) then return end

		-- Get rest of wall section (if necessary).
		local size = util.getval(t.size, self, t)
		local x2, y2
		if size > 1 then
			tg = {type = 'rect', x = x1, y = y1, w = size, h = size,
						pass_terrain = true, stop_block = false, filter = is_wall,}
			x2, y2 = self:getTarget(tg)
		else
			x2, y2 = x1, y1
		end
		if not x2 or not y2 then return end

		-- Grab all of the walls.
		local targets = {}
		local by_coord = {}
		core.fov.calc_rect(
			x1, y1, x2, y2, size, size, is_wall,
			function(_, x, y)
				table.insert(targets, {x = x - x1,y = y - y1,})
				by_coord[x] = by_coord[x] or {}
				by_coord[x][y] = true
		end)

		-- Use custom block_path
		local block_path = function(typ, x, y, for_highlights)
			if not game.level.map:isBound(x, y) then
				return true, true, false
			elseif typ.range and typ.start_x then
				local dist = core.fov.distance(typ.start_x, typ.start_y, x, y)
				if dist > typ.range then return true, false, false end
			end

			local is_known = game.level.map.remembers(x, y) or game.level.map.seens(x, y)
			if (not by_coord[x] or not by_coord[x][y]) and
				(game.level.map:checkEntity(x, y, Map.TERRAIN, 'block_move') or
					 game.level.map:checkEntity(x, y, Map.TERRAIN, 'temporary') or
					 game.level.map:checkEntity(x, y, Map.TERRAIN, 'change_level') or
					 game.level.map:checkEntity(x, y, Map.TERRAIN, 'change_zone'))
			then
				if for_highlights and not is_known then
					return false, 'unknown', true
				else
					return true, true, false
				end
			end

			if for_highlights and not is_known then
				return false, 'unknown', true
			end

			return false, true, true
		end

		-- Grab the target destination.
		local move = util.getval(t.move, self, t)
		tg = {type = 'hit', final_green = 'radius', block_path = block_path,
					start_x = x1, start_y = y1, range = move, blob = targets,}
		local x3, y3 = self:getTarget(tg)
		if not x3 or not y3 then return end
		_, _, _, x3, y3 = self:canProject(tg, x3, y3)


		-- Dig original walls.
		for _, target in pairs(targets) do
			local sx, sy = x1 + target.x, y1 + target.y
			target.terrain = game.level.map(sx, sy, Map.TERRAIN)
			if not target.terrain.temporary then
				DamageType:get(DamageType.DIG).projector(self, sx, sy, DamageType.DIG)
			elseif target.terrain.active_terrain then
				target.terrain:removeLevel()
			end
		end

		-- Place walls.
		local damage = self:spellCrit(util.getval(t.damage, self, t))
		for _, target in pairs(targets) do
			local duration = util.getval(t.duration, self, t) + rng.range(0, 2)
			local sx, sy = x1 + target.x, y1 + target.y
			local tx, ty = x3 + target.x, y3 + target.y
			local target_floor = game.level.map(tx, ty, Map.TERRAIN)

			target.active = active_terrain.new {
				terrain = target.terrain,
				old_source = target.terrain,
				old_target = target_floor,
				temporary = duration,
				nicer_tiles = true,
				x = tx, y = ty, sx = sx, sy = sy,
				canAct = false,
				dig = false,
				temporary_timeout = function(self)
					local map = require 'engine.Map'
					self:removeLevel()
					local present = game.level.map(self.sx, self.sy, map.TERRAIN)
					if present and present.active_terrain then
						present:removeLevel()
					end
					if self.old_source.active_terrain then
						self.old_source:move(self.sx, self.sy)
					else
						game.level.map(self.sx, self.sy, map.TERRAIN, self.old_source)
					end
					game.nicer_tiles:updateAround(game.level, self.sx, self.sy)
				end,}

			-- Damage.
			DamageType:get(DamageType.PHYSICAL).projector(
				self, tx, ty, DamageType.PHYSICAL, damage)
		end

		-- Nicer tile the walls.
		for _, target in pairs(targets) do
			game.nicer_tiles:updateAround(game.level, target.active.x, target.active.y)
		end

		game:playSoundNear(self, 'talents/earth')
		return true
	end,
	info = function(self, t)
		local size = util.getval(t.size, self, t)
		return ([[Move a chunk of walls up to %dx%d big in a line up to %d tiles. The rushing wall deals %d physical damage to any enemy hit #SLATE#(UNIMPLEMENTED:, and the same amount again and a 3 turn stun if there is a wall directly behind them to slam them into)#LAST#. After 3 - 5 turns the walls will return to their original position.
Damage increases with spellpower.]])
			:format(size, size,
							util.getval(t.move, self, t),
							Talents.damDesc(self, DamageType.PHYSICAL, util.getval(t.damage, self, t)))
	end,}
