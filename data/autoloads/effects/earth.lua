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
	name = 'IVY_MESH_POISON', image = 'effects/poisoned.png',
	desc = 'Symbiotic Poison',
	long_desc = function(self, eff)
		return ([[Take %d nature damage, halving every turn.
This effect also contributes spell save to its source.]])
			:format(eff.power)
	end,
	type = 'physical',
	subtype = {poison = true, nature = true, earth = true,}, no_ct_effect = true,
	status = 'detrimental',
	parameters = {power = 20,},
	on_gain = function(self, eff)
		return '#Target# is poisoned by ivy thorns!', '+Symbiotic Poison'
	end,
	on_lose = function(self, eff)
		return '#Target# is no longer poisoned!', '-Symbiotic Poison'
	end,
	activate = function(self, eff)
		if eff.src then
			eff.src:setEffect('EFF_IVY_MESH', 1, {targets = {[self] = true,},})
		end
	end,
	on_timeout = function(self, eff)
		if self:attr('purify_poison') then
			self:heal(eff.power, eff.src)
		else
			DamageType:get(DamageType.NATURE).projector(
				eff.src, self.x, self.y, DamageType.NATURE, eff.power)
		end
		eff.power = eff.power * 0.5
	end,}

newEffect {
	name = 'IVY_MESH', image = 'talents/ivy_mesh.png',
	desc = 'Poison Residue',
	long_desc = function(self, eff)
		return ([[Your ivy mesh has poisoned targets, giving you %d spell save while it remains active.]])
			:format(eff.save)
	end,
	decrease = 0, no_remove = true,
	type = 'physical',
	subtype = {poison = true, nature = true, earth = true,},
	status = 'beneficial',
	parameters = {targets = {}, save = 1},
	charges = function(self, eff) return math.floor(eff.save) end,
	activate = function(self, eff)
		local t = self:getTalentFromId('T_IVY_MESH')
		eff.save = math.min(#table.keys(eff.targets) * t.save_per(self, t),
												t.save_max(self, t))
		eff.save_id = self:addTemporaryValue('combat_spellresist', eff.save)
	end,
	on_merge = function(self, old, new)
		self:removeTemporaryValue('combat_spellresist', old.save_id)
		local t = self:getTalentFromId('T_IVY_MESH')
		table.merge(new.targets, old.targets)
		new.save = math.min(#table.keys(new.targets) * t.save_per(self, t),
												t.save_max(self, t))
		new.save_id = self:addTemporaryValue('combat_spellresist', new.save)
		return new
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue('combat_spellresist', eff.save_id)
	end,
	on_timeout = function(self, eff)
		local count = 0
		for target, _ in pairs(eff.targets) do
			if target and not target.dead and target:hasEffect('EFF_IVY_MESH_POISON') then
				count = count + 1
			else
				eff.targets[target] = nil
			end
		end

		if count == 0 then
			self:removeEffect('EFF_IVY_MESH', nil, true)
		else
			self:removeTemporaryValue('combat_spellresist', eff.save_id)
			local t = self:getTalentFromId('T_IVY_MESH')
			eff.save = math.min(count * t.save_per(self, t), t.save_max(self, t))
			eff.save_id = self:addTemporaryValue('combat_spellresist', eff.save)
		end
	end,}

newEffect {
	name = 'BROKEN_SHELL',
	desc = 'Broken Shell',
	long_desc = function(self, eff)
		return 'Your rock shell has broken, and will no longer prevent you from going below 1 Life. This effect will heal when you reach max Life.'
	end,
	type = 'other',
	subtype = {earth = true,},
	decrease = 0, no_remove = true,
	status = 'detrimental',
	parameters = {},
	on_gain = function(self, eff)
		return '#RED##Target#\'s rock shell has cracked open!#LAST#', '-Rock Shell'
	end,
	on_lose = function(self, eff)
		return '#Target#\'s rock shell has been repaired!', '+Rock Shell'
	end,
	on_timeout = function(self, eff)
		if self.life >= self.max_life then
			self:removeEffect('EFF_BROKEN_SHELL', nil, true)
		end
	end,}

newEffect {
	name = 'SYMBIOTIC_ROOTS', image = 'talents/put_roots.png',
	desc = 'Symbiotic Roots',
	long_desc = function(self, eff)
		return ('Symbiotic Roots have increased your healing factor by %d%% and your physical save by %d.')
			:format(eff.healing * 100, eff.save)
	end,
	type = 'physical',
	subtype = {nature = true, earth = true,},
	status = 'beneficial',
	parameters = {healing = 0.1, save = 10,},
	activate = function(self, eff)
		self:effectTemporaryValue(eff, 'healing_factor', eff.healing)
		self:effectTemporaryValue(eff, 'combat_physresist', eff.save)
	end,}

newEffect {
	name = 'PREDATORY_VINES', image = 'talents/predatory_vines.png',
	desc = 'Predatory Vines',
	long_desc = function(self, eff)
		local damage = eff.damage
		local leash = ''
		if eff.src then
			damage = damDesc(eff.src, DamageType.NATURE, damage)
			leash = (' and preventing you from moving more than %d tiles away from %s.')
				:format(eff.leash, eff.src.name)
		end
		return ('Predatory vines have latched onto your body, dealing %d nature damage per turn%s.')
			:format(damage, leash)
	end,
	type = 'physical',
	subtype = {nature = true, earth = true,},
	status = 'detrimental',
	parameters = {damage = 10,},
	activate = function(self, eff)
		if eff.src then
			-- Add leash range.
			self:effectTemporaryValue(eff, 'hard_leash', {[eff.src] = eff.leash})
			-- Add ivy mesh poison.
			if eff.src:knowTalent('T_IVY_MESH') and self:canBe('poison') then
				local t = eff.src:getTalentFromId('T_IVY_MESH')
				self:setEffect('EFF_IVY_MESH_POISON', 3, {
												 src = eff.src,
												 power = t.poison(eff.src, t),
												 no_ct_effect = true,})
			end
			self.tempeffect_def.EFF_PREDATORY_VINES.update_particles(self, eff)
		end
	end,
	deactivate = function(self, eff)
		if eff.particles then
			self:removeParticles(eff.particles)
			eff.particles = nil
		end
	end,
	on_timeout = function(self, eff)
		-- Direct Damage
		DamageType:get(DamageType.NATURE).projector(
			eff.src, self.x, self.y, DamageType.NATURE, eff.damage)
		-- Refresh ivy mesh poison.
		if eff.src and eff.src:knowTalent('T_IVY_MESH') and self:canBe('poison') then
			local t = eff.src:getTalentFromId('T_IVY_MESH')
			self:setEffect('EFF_IVY_MESH_POISON', 3, {
											 src = eff.src,
											 power = t.poison(eff.src, t),
											 no_ct_effect = true,})
		end
	end,
	update_particles = function(self, eff)
		if not eff.src or eff.src.dead or self.dead or
			not game.level:hasEntity(eff.src) or
			not game.level:hasEntity(self)
		then
			if eff.particles then
				self:removeParticles(eff.particles)
				eff.particles = nil
			end
			return
		end

		-- update particles position
		if not eff.particles or
			eff.particles.x ~= eff.src.x or
			eff.particles.y ~= eff.src.y or
			eff.particles.tx ~= self.x or
			eff.particles.ty ~= self.y
		then
			if eff.particles then
				self:removeParticles(eff.particles)
			end
			-- add updated particle emitter
			local dx, dy = eff.src.x - self.x, eff.src.y - self.y
			eff.particles = particles.new(
				'predatory_vines', math.max(math.abs(dx), math.abs(dy)), {tx = dx, ty = dy,})
			eff.particles.tx = eff.src.x
			eff.particles.ty = eff.src.y
			eff.particles.x = self.x
			eff.particles.y = self.y
			self:addParticles(eff.particles)
		end
	end,}

newEffect {
	name = 'CHOKING_DUST', image = 'talents/choking_dust.png',
	desc = 'Choking Dust',
	long_desc = function(self, eff)
		return ('Engulfed in a cloud of dust. Each turn takes %d physical damage and loses %d air. Also reduces ranged accuracy by %d, and gives a %d%% chance to misaim ranged attacks by up to %d%% of the original distance.')
			:format(eff.damage, eff.air, eff.ranged_penalty,
							eff.mistarget_chance, eff.mistarget_percent * 100)
	end,
	type = 'physical',
	subtype = {nature = true, earth = true,},
	status = 'detrimental',
	parameters = {damage = 10, air = 5, ranged_penalty = 10,
								mistarget_chance = 10, mistarget_percent = 0.2,},
	activate = function(self, eff)
		self:effectTemporaryValue(eff, 'combat_ranged_atk', -eff.ranged_penalty)
		self:effectTemporaryValue(eff, 'mistarget_chance', eff.mistarget_chance)
		self:effectTemporaryValue(eff, 'mistarget_percent', eff.mistarget_percent)
	end,
	on_timeout = function(self, eff)
		DamageType:get(DamageType.PHYSICAL).projector(
			eff.src, self.x, self.y, DamageType.PHYSICAL, eff.damage)
		self:suffocate(eff.air, eff.src)
	end,}

newEffect {
	name = 'PYROCLASTIC_PIN', image = 'talents/pyroclastic_burst.png',
	desc = 'Pyroclastic Pin',
	long_desc = function(self, eff)
		return ('Molten rock has formed around your legs, pinning you in place and dealing %d fire damage each turn.')
			:format(damDesc(eff.src or {}, DamageType.FIRE, eff.damage))
	end,
	type = 'physical',
	subtype = {earth = true, fire = true, pin = true,},
	status = 'detrimental',
	parameters = {damage = 10,},
	activate = function(self, eff)
		self:effectTemporaryValue(eff, 'never_move', 1)
	end,
	on_timeout = function(self, eff)
		DamageType:get(DamageType.FIRE).projector(
			eff.src or {}, self.x, self.y, DamageType.FIRE, eff.damage)
	end,}

newEffect {
	name = 'BRUTISH_STRIDE', image = 'talents/brutish_stride.png',
	desc = 'Brutish Stride',
	long_desc =  function(self, eff)
		local radius = math.floor(eff.radius * eff.move / eff.max)
		local afterecho = ''
		if radius >= 1 then
			local angle = math.floor(eff.angle * eff.move / eff.max)
			afterecho = (' This will have a larger afterecho, dealing damage in a radius %d cone, with %d extra degrees of coverage.'):format(radius + 1, angle)
		end
		local damage = eff.damage * 100 * eff.move / eff.max
		return ([[Your movements have built up inertia, increasing your movement speed by %d%%. Your next weapon strike will consume this effect to deal %d%% extra weapon damage.%s
Any action but an attack will halve this bonus. Standing still will remove it completely.]])
			:format(eff.move, damage, afterecho)
	end,
	type = 'physical',
	subtype = {earth = true, speed = true, tactic = true,},
	status = 'beneficial',
	parameters = {move = 1, max = 10, damage = 10, radius = 1, angle = 10,},
	charges = function(self, eff) return math.floor(10.1 * eff.move / eff.max) end,
	decrease = 0, no_remove = true,
	activate = function(self, eff)
		eff.move_id = self:addTemporaryValue('movement_speed', eff.move * 0.01)
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue('movement_speed', eff.move_id)
	end,
	on_merge = function(self, old, new)
		self:removeTemporaryValue('movement_speed', old.move_id)
		new.max = math.max(old.max, new.max)
		new.move = math.min(new.max, old.move + new.move)
		new.move_id = self:addTemporaryValue('movement_speed', new.move * 0.01)
		return new
	end,
	callbackOnWait = function(self, eff)
		self:removeEffect('EFF_BRUTISH_STRIDE', true, true)
		end,}

newEffect {
	name = 'UNLEASHED', image = 'talents/unleashed.png',
	desc = 'Unleashed',
	long_desc = function(self, eff)
		return ([[Nothing dare stop you dead in your tracks. You are immune to effects that would slow you down, knock you back or immobilize you. This does not negate the application of harmful skills however, only their slowing/knock-backing/immbolizing effect and the duration decreases by 1 for every effect it negates. Negating an effect will give you %d stacks of Brutish Stride.]])
			:format(eff.stride)
	end,
	type = 'physical',
	subtype = {earth = true,},
	status = 'beneficial',
	parameters = {},}

newEffect {
	name = 'SHARKSKIN', image = 'talents/sharkskin.png',
	desc = 'Sharkskin',
	long_desc = function(self, eff)
		local counter = ''
		if eff.disarm_counter then
			counter = ('\nThe disarm effect is on cooldown for %d more turns.'):format(eff.disarm_counter)
		end
		return ([[Your 'skin' has formed a rough mesh of hooked scales. You gain %d ranged defense and %d physical power. Anytime an enemy critically hits you in melee, up to once every %d turns, they must pass a physical power vs. your physical save check or be disarmed for %d turns.%s]])
			:format(eff.defense * eff.amount, eff.power * eff.amount,
							eff.disarm_cooldown, eff.disarm, counter)
	end,
	type = 'physical',
	subtype = {earth = true,},
	status = 'beneficial',
	parameters = {defense = 2, power = 2, disarm = 1,},
	charges = function(self, eff) return eff.amount end,
	activate = function(self, eff)
		eff.defense_id = self:addTemporaryValue('combat_def_ranged', eff.defense * eff.amount)
		eff.power_id = self:addTemporaryValue('combat_dam', eff.power * eff.amount)
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue('combat_def_ranged', eff.defense_id)
		self:removeTemporaryValue('combat_dam', eff.power_id)
	end,
	on_merge = function(self, old, new)
		self:removeTemporaryValue('combat_def_ranged', old.defense_id)
		self:removeTemporaryValue('combat_dam', old.power_id)
		new.max = math.max(old.max, new.max)
		new.amount = math.min(new.max, old.amount + new.amount)
		new.disarm_counter = old.disarm_counter
		new.defense_id = self:addTemporaryValue('combat_def_ranged', new.defense * new.amount)
		new.power_id = self:addTemporaryValue('combat_dam', new.power * new.amount)
		return new
	end,
	on_timeout = function(self, eff)
		if eff.disarm_counter then
			eff.disarm_counter = eff.disarm_counter - 1
			if eff.disarm_counter == 0 then
				eff.disarm_counter = nil
			end
		end
	end,}

newEffect {
	name = 'BLINDING_SAND', image = 'talents/sandstorm.png',
	desc = 'Blinding Sand',
	long_desc = function(self, eff)
		local blind = ''
		if eff.blind_id then
			blind = ' and blinded you'
		end
		return ([[Whirling sand has reduced your accuracy by %d%s.]])
			:format(eff.accuracy, blind)
	end,
	type = 'physical',
	subtype = {earth = true, blind = true,},
	status = 'detrimental',
	parameters = {accuracy = 3, max = 9,},
	activate = function(self, eff)
		eff.accuracy_id = self:addTemporaryValue('combat_atk', -eff.accuracy)
		if eff.accuracy >= eff.max then
			eff.blind_id = self:addTemporaryValue('blind', 1)
		end
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue('combat_atk', eff.accuracy_id)
		if eff.blind_id then
			self:removeTemporaryValue('blind', eff.blind_id)
		end
	end,
	on_merge = function(self, old, new)
		self:removeTemporaryValue('combat_atk', old.accuracy_id)
		if old.blind_id then
			self:removeTemporaryValue('blind', old.blind_id)
		end
		new.max = math.max(old.max, new.max)
		new.accuracy = math.min(new.max, old.accuracy + new.accuracy)
		new.accuracy_id = self:addTemporaryValue('combat_atk', -new.accuracy)
		if new.accuracy >= new.max then
			new.blind_id = self:addTemporaryValue('blind', 1)
		end
		return new
	end,}

newEffect{
	name = 'SILICINE_WOUND', image = 'talents/silicine_slicers.png',
	desc = 'Silicine Wound',
	long_desc = function(self, eff)
		return ('Crystals have cut you and caused you to bleed, dealing %d physical damage each turn and slowing your global speed by %d%%.'):format(
			damDesc(eff.src, DamageType.PHYSICAL, eff.damage),
			eff.speed * 100)
	end,
	type = 'physical',
	subtype = {wound = true, cut = true, earth = true,},
	status = 'detrimental',
	parameters = {damage = 10, speed = 0.1,},
	on_gain = function(self, err) return '#Target# is cut by crystals.', '+Silicine Wound' end,
	on_lose = function(self, err) return '#Target# stops bleeding from the crystal cuts.', '-Silicine Wound' end,
	activate = function(self, eff)
		self:effectTemporaryValue(eff, 'global_speed_add', -eff.speed)
	end,
	on_timeout = function(self, eff)
		DamageType:get(DamageType.PHYSICAL).projector(
			eff.src or self, self.x, self.y, DamageType.PHYSICAL, eff.damage)
	end,}

newEffect{
	name = 'PRIMORDIAL_PETRIFICATION', image = 'talents/stone_touch.png',
	desc = 'Primordial Petrification',
	long_desc = function(self, eff)
		return [[Target has been encased in stone! Target is subject to shattering but improving physical(+20%), fire(+80%) and lightning(+50%) resistances.
If the tile that the target is standing on is no longer solid, then this will immediately drop to having 1 turn left for every 33% Life the target is missing.]]
	end,
	type = 'physical',
	subtype = {earth = true, stone = true,},
	status = 'detrimental',
	parameters = {},
	on_gain = function(self, err) return '#Target# is encased in stone.', '+Primordial Petrification' end,
	on_lose = function(self, err) return '#Target# is no longer encased in stone.', '-Primordial Petrification' end,
	activate = function(self, eff)
		self:effectTemporaryValue(eff, 'stoned', 1)
		self:effectTemporaryValue(eff, 'resists', {
																[DamageType.PHYSICAL] = 20,
																[DamageType.FIRE] = 80,
																[DamageType.LIGHTNING] = 50,})
		game:playSoundNear(self, 'talents/ice')
	end,
	on_timeout = function(self, eff)
		if not eff.reduced and self:canMove(self.x, self.y, true) then
			eff.reduced = true
			local target_dur = math.floor(math.max(0, self.max_life - self.life) * 3 / self.max_life) - 1
			eff.dur = math.min(eff.dur, target_dur)
		end
	end,}
