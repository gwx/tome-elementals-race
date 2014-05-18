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
