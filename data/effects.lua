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
			eff.src:setEffect('EFF_IVY_MESH', 1, {targets = {[self.uid] = true,},})
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
		for uid, _ in pairs(eff.targets) do
			local target = __uids[uid]
			if target and not target.dead and target:hasEffect('EFF_IVY_MESH_POISON') then
				count = count + 1
			else
				eff.targets[uid] = nil
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
			damage = damDesc(self, DamageType.NATURE, damage)
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
