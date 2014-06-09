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


-- Allow partial blocking amounts.
local blocking = TemporaryEffects.tempeffect_def.EFF_BLOCKING
blocking.do_block = function(type, dam, eff, self, src)
	local dur_inc = 0
	local crit_inc = 0
	local nb = 1
	if self:knowTalent(self.T_RIPOSTE) then
		local t = self:getTalentFromId(self.T_RIPOSTE)
		dur_inc = t.getDurInc(self, t)
		crit_inc = t.getCritInc(self, t)
		nb = nb + dur_inc
	end
	local b = eff.d_types[type]
	if not b then return dam end
	if not self:knowTalent(self.T_ETERNAL_GUARD) then eff.dur = 0 end
	local power = eff.power
	if _G.type(b) == 'number' then power = power * util.bound(b * 0.01, 0, 1) end
	local amt = util.bound(dam - power, 0, dam)
	local blocked = dam - amt
	local shield = self:hasShield()
	if shield and shield.on_block and shield.on_block.fct then shield.on_block.fct(shield, self, src, type, dam, eff) end
	if eff.properties.br then
		self:heal(blocked, src)
		game:delayedLogMessage(self, src, "block_heal", "#CRIMSON##Source# heals from blocking with %s shield!", string.his_her(self))
	end
	if eff.properties.ref and src.life then DamageType.defaultProjector(src, src.x, src.y, type, blocked, tmp, true) end
	if (self:knowTalent(self.T_RIPOSTE) or self:attr('block_always_counterstrike') or amt == 0) and src.life then
		src:setEffect('EFF_COUNTERSTRIKE', (1 + dur_inc) * math.max(1, (src.global_speed or 1)), {
										power = eff.power,
										no_ct_effect = true,
										src = self,
										crit_inc = crit_inc,
										nb = nb})
		if eff.properties.sb then
			if src:canBe("disarm") then
				src:setEffect(src.EFF_DISARMED, 3, {apply_power = self:combatPhysicalpower()})
			else
				game.logSeen(target, "%s resists the disarming attempt!", src.name:capitalize())
			end
		end
	end
	return amt
end

-- Remember being counterstriked for rest of the attack.
local counterstrike = TemporaryEffects.tempeffect_def.EFF_COUNTERSTRIKE
local onStrike = counterstrike.onStrike
counterstrike.onStrike = function(self, eff, dam, src)
	if src then src.turn_procs.counterstrike_activated = true end
	return onStrike(self, eff, dam, src)
end
