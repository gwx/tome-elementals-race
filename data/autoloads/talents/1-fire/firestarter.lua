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
local eutil = require 'elementals-race.util'
local ACTOR = require('engine.Map').ACTOR
local TERRAIN = require('engine.Map').TERRAIN
local stats = require 'engine.interface.ActorStats'
local particles = require 'engine.Particles'

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
	heat = 0, -- Make you learn heat pool.
	mode = 'passive',
	speed = function(self, t) return self:scale {low = 0.03, high = 0.2, t, 'dex',} end,
	accuracy = function(self, t) return self:scale {low = 10, high = 40, t, 'dex',} end,
	crit = function(self, t) return self:scale {low = 2, high = 10, t, 'dex',} end,
	heat_gain = function(self, t) return self:scale {low = 2, high = 6, t, after = 'floor',} end,
	heat_threshold = 50,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, 'global_speed_add', self:heatScale(get(t.speed, self, t)))
		self:talentTemporaryValue(p, 'combat_atk', self:heatScale(get(t.accuracy, self, t)))
		self:talentTemporaryValue(p, 'combat_physcrit', self:heatScale(get(t.crit, self, t)))
		self:talentTemporaryValue(p, 'heat_step_threshold', get(t.heat_threshold, self, t))
		self:talentTemporaryValue(p, 'heat_step_gain', get(t.heat_gain, self, t))
	end,
	recompute_passives = {stats = {stats.STAT_DEX,},},
	info = function(self, t)
		local speed = get(t.speed, self, t) * 100
		local accuracy = get(t.accuracy, self, t)
		local crit = get(t.crit, self, t)
		return ([[Increases your global speed by %d%% <%d%%> #SLATE#[*, dex]#LAST#, your accuracy by %d <%d> #SLATE#[*, dex]#LAST# and physical crit chance by %d%% <%d%%> #SLATE#[*, dex]#LAST#.
You recover %d #SLATE#[*]#LAST# #FF6100#heat#LAST# with every tile you move, provided you are under #FF6100#%d heat#LAST#.
#SLATE#Numbers shown are for 100%% heat, numbers in <brackets> are the actual amounts based on your current heat.]])
			:format(self:heatScale(speed, 100), self:heatScale(speed),
							self:heatScale(accuracy, 100), self:heatScale(accuracy),
							self:heatScale(crit, 100), self:heatScale(crit),
							get(t.heat_gain, self, t),
							get(t.heat_threshold, self, t))
	end,}

newTalent {
	name = 'Blazing Rush',
	type = {'elemental/firestarter', 2,},
	require = make_require(2),
	points = 5,
	cooldown = 16,
	tactical = {ESCAPE = 2,},
	range = function(self, t) return self:scale {low = 2.5, high = 6.5, t, after = 'floor',} end,
	damage = function(self, t) return self:scale {low = 10, high = 25, t, 'dex', after = 'damage',} end,
	heat_gain = 25,
	no_energy = 'fake',
	target = function(self, t)
		return {type = 'hit', range = get(t.range, self, t), talent = t,}
	end,
	action = function(self, t)
		local _
		local tg = get(t.target, self, t)
		local x, y = self:getTarget(tg)
		if not x or not y then return end
		_, x, y = self:canProject(tg, x, y)
		if not self:canMove(x, y) then return end

		local damage = self:heatScale(get(t.damage, self, t))
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

		if hit then self:incHeat(get(t.heat_gain, self, t)) end

		game:playSoundNear(self, 'talents/fire')

		return true
	end,
	info = function(self, t)
		local damage = get(t.damage, self, t)
		return ([[Rushes through enemies to target position up to %d #SLATE#[*]#LAST# tiles away, creating a wake of flames in the path. The flames deal %d <%d> #SLATE#[*, dex, spell crit]#LAST# #LIGHT_RED#fire#LAST# damage to anything standing in them. The furthest flame lasts 1 turn, with each closer flame lasting 1 more turn. If you strike any enemies during the rush, you will gain #FF6100#%d heat#LAST#.
#SLATE#Numbers shown are for 100%% heat, numbers in <brackets> are the actual amounts based on your current heat.]])
			:format(
				get(t.range, self, t),
				self:damDesc('FIRE', self:heatScale(damage, 100)),
				self:damDesc('FIRE', self:heatScale(damage)),
				self:heatGain(get(t.heat_gain, self, t)))
	end,}

newTalent {
	name = 'Billowing Carpet',
	type = {'elemental/firestarter', 3,},
	require = make_require(3),
	points = 5,
	cooldown = 21,
	tactical = {ESCAPE = 2, DEBUFF = 1,},
	range = 0,
	radius = function(self, t) return self:scale {low = 3, high = 4.5, t, after = 'floor',} end,
	duration = function(self, t) return self:scale {low = 2, high = 6.5, t, 'dex', after = 'floor',} end,
	effect_duration = 2,
	crit = function(self, t) return self:scale {low = 3, high = 10, t, 'dex',} end,
	stealth = 0.15,
	heat_gain = 15,
	no_break_stealth = true,
	target = function(self, t)
		return {type = 'ball', talent = t, selffire = true,
						range = get(t.range, self, t),
						radius = get(t.radius, self, t),}
	end,
	action = function(self, t)
		local _
		local tg = get(t.target, self, t)

		local stealth = get(t.stealth, self, t)
		local duration = self:spellCrit(get(t.duration, self, t))
		local effect_duration = get(t.effect_duration, self, t)
		local heat_gain = get(t.heat_gain, self, t)
		local crit = get(t.crit, self, t)
		local effect = game.level.map:addEffect(
			self, self.x, self.y, duration, 'BILLOWING_CARPET',
			{src = self, origin_x = self.x, origin_y = self.y, stealth = stealth, heat_gain = heat_gain,
			 duration = effect_duration, crit = crit, max_depth = tg.radius + 1,},
			tg.radius, 5, nil, {type = 'smoke_storm',})
		effect.name = ('%s\'s billowing carpet'):format(self.name:capitalize())
		game:playSoundNear(self, 'talents/fire')
		return true
	end,
	info = function(self, t)
		local damage = get(t.damage, self, t)
		return ([[Lets out a carpet of choking black smoke to cover an area around you in radius %d #SLATE#[*]#LAST# for %d #SLATE#[*, dex]#LAST# turns.
Enemies inside the cloud are suffocated, silenced, blinded, and %d%% #SLATE#[*, dex]#LAST# more susceptable to critical hits until they leave the cloud, with the effects persisting for %d turns after leaving it. You will get #FF6100#%d heat#LAST# for every turn spent inside the cloud and gain %d%% of your cunning as stealth power and ranged defense for every tile deep you are inside of the cloud.
Duration and critical chance scale with dexterity.]])
			:format(
				get(t.radius, self, t),
				get(t.duration, self, t),
				get(t.crit, self, t),
				get(t.effect_duration, self, t),
				get(t.heat_gain, self, t),
				get(t.stealth, self, t) * 100)
	end,}

newTalent {
	name = 'Tendrils of Fire',
	type = {'elemental/firestarter', 4,},
	require = make_require(4),
	points = 5,
	cooldown = 26,
	tactical = {DAMAGE = 2, DEBUFF = 1,},
	mode = 'sustained',
	iconOverlay = function(self, t, p)
		local target = p.target
		if not target then return '' end
		local fnt = 'buff_font_small'
		local effect = target:hasEffect('EFF_FIERY_BINDINGS')
		if effect.src ~= self then return '' end
		return tostring(math.ceil(effect.dur)), fnt
	end,
	range = 2,
	duration = function(self, t) return self:scale {low = 2, high = 6, t, after = 'floor',} end,
	damage = function(self, t) return self:scale {low = 25, high = 60, 'dex',} end,
	heat_gain = 15,
	target = function(self, t)
		return {type = 'bolt', talent = t, range = get(t.range, self, t),}
	end,
	activate = function(self, t)
		local _
		local tg = get(t.target, self, t)
		local x, y = self:getTarget(tg)
		if not x or not y then return end
		_, x, y = self:canProject(tg, x, y)
		local actor = game.level.map(x, y, ACTOR)
		if not actor then return end

		if not actor:canBe('knockback') then
			game.logSeen(self, '%s resists %s\'s fiery tendrils!', actor.name:capitalize(), self.name)
			self:useEnergy()
			return
		end

		local duration = get(t.duration, self, t)
		local damage = get(t.damage, self, t)
		local heat_gain = get(t.heat_gain, self, t)
		actor:setEffect('EFF_FIERY_BINDINGS', duration, {
											src = self, damage = damage, heat_gain = heat_gain,})

		local effect = actor:hasEffect('EFF_FIERY_BINDINGS')
		if effect and effect.src == self then
			local p = {target = actor,}
			t.update_particles(self, t, p)
			return p
		else
			self:useEnergy()
			return
		end
	end,
	deactivate = function(self, t, p)
		p.target:removeEffect('EFF_FIERY_BINDINGS', false, true)
		if p.particles then self:removeParticles(p.particles) end
		return true
	end,
	update_particles = function(self, t, p)
		local p = p or self:isTalentActive(t.id)

		if not p.target or p.target.dead or self.dead or
			not game.level:hasEntity(p.target) or
			not game.level:hasEntity(self)
		then
			if p.particles then
				self:removeParticles(p.particles)
				p.particles = nil
			end
			return
		end

		-- update particles position
		if not p.particles or
			p.particles.x ~= self.x or
			p.particles.y ~= self.y or
			p.particles.tx ~= p.target.x or
			p.particles.ty ~= p.target.y
		then
			game.log('ADJUST')
			if p.particles then
				self:removeParticles(p.particles)
			end
			-- add updated particle emitter
			local dx, dy = p.target.x - self.x, p.target.y - self.y
			p.particles = particles.new(
				'fiery_bindings', math.max(math.abs(dx), math.abs(dy)), {tx = dx, ty = dy,})
			p.particles.tx = p.target.x
			p.particles.ty = p.target.y
			p.particles.x = self.x
			p.particles.y = self.y
			self:addParticles(p.particles)
		end
	end,
	info = function(self, t)
		local damage = get(t.damage, self, t)
		return ([[Snatches a nearby enemy with fiery wires, instantly pulling it to you and entangling it by your side #SLATE#[acc vs. phys, knockback]#LAST# for %d #SLATE#[*]#LAST# turns.
While entangled the enemy is immobile and takes %d <%d> #SLATE#[dex]#LAST# #LIGHT_RED#fire#LAST# damage each turn. It is pulled along with you when you move.
The entanglement is broken instantly if a gap forms between you and the target.
#SLATE#Numbers shown are for 100%% heat, numbers in <brackets> are the actual amounts based on your current heat.]])
			:format(
				get(t.duration, self, t),
				self:damDesc('FIRE', self:heatScale(damage, 100)),
				self:damDesc('FIRE', self:heatScale(damage)))
	end,}
