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


local DamageType = require 'engine.DamageType'
local eutil = require 'elementals-race.util'
local hook

-- Actor:takeHit
hook = function(self, data)
	local value = data.value
	local src = data.src
	local damtype = eutil.get(data, 'death_note', 'damtype')

	-- Rock Shell Damage Reduction
	if self:knowTalent('T_ROCK_SHELL') and value >= self.life * 0.3 then
		local t = self:getTalentFromId('T_ROCK_SHELL')
		value = value * (100 - t.damage_reduction(self, t)) * 0.01
	end

	-- Jagged Body
	if value > 0 and self:knowTalent('T_JAGGED_BODY') then
		local blocked = math.min(self.jaggedbody, value)
		self.jaggedbody = self.jaggedbody - blocked
		value = value - blocked
		game:delayedLogDamage(
			src, self, 0, ('#SLATE#(%d absorbed)#LAST#'):format(blocked), false)

		if damtype == DamageType.PHYSICAL and
			src.x and src.y and not src.dead and src ~= self and src.takeHit and
			not self.jaggedbody_reflecting
		then
			self.jaggedbody_reflecting = true

			local reflected = self.jaggedbody_reflect * blocked
			src:takeHit(reflected, self)

			game:delayedLogDamage(
				self, src, reflected,
				('#SLATE#%d reflected#LAST#'):format(reflected), false)
			game:delayedLogMessage(
				self, src, 'reflection',
				'#CRIMSON##Source# reflects damage back to #Target#!#LAST#')

			self.jaggedbody_reflecting = nil
		end
	end

	-- Rock Shell Life Save
	if self:getTalentLevel('T_ROCK_SHELL') >= 5 and
		value >= self.life - 1 and
		not self:hasEffect('EFF_BROKEN_SHELL')
	then
		if not self.pending_rock_shell_break then
			game:playSoundNear(self, 'talents/lightning_loud')
			self.pending_rock_shell_break = true
		end
		if self.life < 1 then self.life = 1 end
		local blocked = value - self.life + 1
		game:delayedLogDamage(
			src, self, 0, ('#RED#(%d negated)#LAST#'):format(blocked), false)
		value = self.life - 1
	end

	-- Cry of Eyal
	if self:attr('max_life_damage') then
		local damage = math.min(self.life - 1, value)
		value = value - damage
		self.max_life_damage_taken = (self.max_life_damage_taken or 0) + damage
		self.max_life = self.max_life - damage
	end

	data.value = value
	return true
end
class:bindHook('Actor:takeHit', hook)


-- Actor:actBase:Effects
hook = function(self, data)
	-- Yggdrasil heal.
	if self:attr('essence_consumption') then
		local value = self:getEssence() * self.essence_consumption
		self:heal(value * (self.essence_consumption_heal or 0), self)
		self:incEssence(-value)
		self:incJaggedbody(value * 0.33)
	end

	-- Break the rock shell.
	if self.pending_rock_shell_break then
		self:setEffect('EFF_BROKEN_SHELL', 1, {})
		self.pending_rock_shell_break = nil
	end

	-- Update Yggdrasil passive.
	if self:knowTalent('T_YGGDRASIL') then
		self:recomputePassives('T_YGGDRASIL')
	end

	-- Update Blazes.
	self:recomputeSustain('T_BLAZES')
end
class:bindHook('Actor:actBase:Effects', hook)

-- Actor:preUseTalent
hook = function(self, data)
	local ab, silent, fake = data.t, data.silent, data.fale
	-- Check for essence requirements.
	if ab.mode == 'sustained' then
		if ab.sustain_essence and
			((self.sustain_essence or 0) + ab.sustain_essence) > 99 -- 100 will cause div by 0 later.
		then
			if not silent then
				game.logPlayer(self, 'You do not have enough essence to activate %s.', ab.name)
			end
			return true
		end
	elseif not self:attr('force_talent_ignore_ressources') then
		if ab.essence and self:essenceCost(ab.essence) > self:getEssence() then
			if not silent then
				game.logPlayer(self, 'You do not have enough essence to cast %s.', ab.name)
			end
			return true
		end
	end

	-- Check for a on_pre_deactivate.
	if (ab.mode == "sustained" and self:isTalentActive(ab.id)) and
		ab.on_pre_deactivate and not ab.on_pre_deactivate(self, ab, silent, fake)
	then return true end
end
class:bindHook('Actor:preUseTalent', hook)

-- Actor:postUseTalent
hook = function(self, data)
	local ab, trigger = data.t, data.trigger
	-- Use up essence
	if ab.mode == 'sustained' then
		if not self:isTalentActive(ab.id) then
			if ab.sustain_essence then
				trigger = true
				local essence = util.getval(ab.sustain_essence, self, ab)
				self.sustain_essence = (self.sustain_essence or 0) + essence
			end
		else
			if ab.sustain_essence then
				trigger = true
				local essence = util.getval(ab.sustain_essence, self, ab)
				self.sustain_essence = (self.sustain_essence or 0) - essence
			end
		end
	elseif not self:attr('force_talent_ignore_ressources') then
		if ab.essence and not self:attr('zero_resource_cost') then
			trigger = true
			local value = self:essenceCost(util.getval(ab.essence, self, ab))
			self:incEssence(-value)
			self:incJaggedbody(value * 0.33)
		end
	end
	data.trigger = trigger
	return true
end
class:bindHook('Actor:postUseTalent', hook)

-- Actor:getTalentFullDescription:ressources
hook = function(self, data)
	local t, d = data.t, data.str
	if t.essence then
		local percent = util.getval(t.essence, self, t) * (100 + self:combatFatigue()) * 0.01
		local amount = self:essenceCost(percent, true)
		local str = ('%.1f%% (%.1f)'):format(percent, amount)
		d:add({'color',0x6f,0xff,0x83}, 'Essence cost: ', {'color',164,190,77}, str, true)
	end
	if t.sustain_essence then
		local percent = util.getval(t.sustain_essence, self, t)
		local amount = self:realMaxEssence() * percent * 0.01
		local str = ('%d%% (%.1f)'):format(percent, amount)
		d:add({'color',0x6f,0xff,0x83}, 'Sustain essence cost: ', {'color',164,190,77}, str, true)
	end
end
class:bindHook('Actor:getTalentFullDescription:ressources', hook)

-- self:triggerHook{"Actor:move", moved=moved, force=force, ox=ox, oy=oy}
-- Actor:move
hook = function(self, data)
	local predatory_vines = self:hasEffect('EFF_PREDATORY_VINES')
	if predatory_vines then
		self.tempeffect_def.EFF_PREDATORY_VINES
			.update_particles(self, predatory_vines)
	end
end
class:bindHook('Actor:move', hook)
