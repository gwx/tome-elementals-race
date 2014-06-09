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
local damage_type = require 'engine.DamageType'
local hook

hook = function(self, data)
	local target = data.target
	local hitted = data.hitted
	local crit = data.crit
	local weapon = data.weapon
	local damtype = data.damtype
	local mult = data.mult
	local dam = data.dam
	local t

	-- Heavy Arms daze
	t = self:getTalentFromId('T_HEAVY_ARMS')
	if self:knowTalent('T_HEAVY_ARMS') and hitted and
		eutil.hasv({'mace', 'axe', 'sword', 'unarmed', 'staff'},
							 eutil.get(data, 'weapon', 'talented')) and
		rng.percent(t.daze(self, t))
	then
		if target:canBe('stun') then
			local daze = function()
				target:setEffect('EFF_DAZED', 1, {
																apply_power = self:combatPhysicalpower(1, data.weapon),})
			end
			game:onTickEnd(daze)
		else
			game.logSeen(target, '%s avoids being dazed by the weight of %s\'s attack.',
									 target.name:capitalize(), self.name)
		end
	end

	-- Ivy Mesh retribution
	local t = target:getTalentFromId('T_IVY_MESH')
	if target:knowTalent('T_IVY_MESH') and hitted then
		if self:canBe('poison') then
			self:setEffect('EFF_IVY_MESH_POISON', 3, {
											 src = target,
											 power = t.poison(target, t),
											 no_ct_effect = true,})
		end
	end

	-- Afterecho
	if self:attr('physical_echo') and hitted and target then
		if self:attr('physical_echo_radius') then
			local tg = {
				type = 'cone',
				radius = self.physical_echo_radius + 1,
				cone_angle = 55 + (self.physical_echo_angle or 0),
				start_x = target.x, start_y = target.x,}
			local dx, dy = target.x - self.x, target.y - self.y
			local x, y = dx + target.x, dy + target.y
			self:project(
				tg, x, y,
				damage_type.PHYSICAL, dam * self.physical_echo)
			game.level.map:particleEmitter(
				target.x, target.y, tg.radius, 'temporal_breath',
				{radius = tg.radius, tx = dx, ty = dy,})
			game:playSoundNear(target, 'talents/lightning')
		else
			local _, dx, dy = util.getDir(self.x, self.y, target.x, target.y)
			damage_type:get(damage_type.PHYSICAL).projector(
				self, target.x - dx, target.y - dy, damage_type.PHYSICAL, dam * self.physical_echo)
		end
	end

	-- Pestle extra hit.
	if hitted and not target.dead and
		self:knowTalent('T_PESTLE') and not self:attr('in_pestle')
	then
		self:attr('in_pestle', 1)
		local shield = self:hasShield()
		local pestle = self:getTalentFromId('T_PESTLE')
		local chance = util.getval(pestle.chance, self, pestle)
		local counterstrike = false
		if self.turn_procs.counterstrike_activated then
			counterstrike = true
			chance = 100
			self:attr('crushing_blow', 1)
		end
		if shield and rng.percent(chance) then
			local damage = util.getval(pestle.damage, self, pestle)
			self:attackTargetWith(target, shield.special_combat, damtype, damage)
		end
		if counterstrike then self:attr('crushing_blow', -1) end
		self:attr('in_pestle', -1)
	end

	-- Sharkskin add effect.
	if target and target:knowTalent('T_SHARKSKIN') and hitted then
		target:callTalent('T_SHARKSKIN', 'on_hit')
	end

	-- Sharkskin disarm self.
	local sharkskin = target and target:hasEffect('EFF_SHARKSKIN')
	if sharkskin and not sharkskin.disarm_counter and hitted and crit then
		if not self:checkHit(self:combatPhysicalpower(1, weapon), target:combatPhysicalResist(), 0, 95) then
			self:setEffect('EFF_DISARMED', sharkskin.disarm, {})
			sharkskin.disarm_counter = sharkskin.disarm_cooldown
		else
			game.logSeen(self, '%s\'s sharkskin fails to disarm %s!', target.name:capitalize(), self.name)
		end
	end

	-- Discard any counterstrike being activated.
	self.turn_procs.counterstrike_activated = nil

	return true
end
class:bindHook('Combat:attackTargetWith', hook)
