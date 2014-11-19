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
local damage_type = require 'engine.DamageType'
local particles = require 'engine.Particles'
local map = require 'engine.Map'

newEffect {
	name = 'ERUPTION', image = 'talents/eruption.png',
	desc = 'Eruption Power',
	long_desc = function(self, eff)
		return ([[Target's fire damage is increased by %d%%.]]):format(eff.fire)
	end,
	type = 'physical',
	subtype = {nature = true, fire = true,},
	status = 'beneficial',
	parameters = {fire = 10,},
	on_gain = function(self, eff)
		return '#Target# erupts with firey energy!', '+Eruption Power'
	end,
	on_lose = function(self, eff)
		return '#Target# has lost some firey energy!', '-Eruption Power'
	end,
	activate = function(self, eff)
		self:effectTemporaryValue(eff, 'inc_damage', {FIRE = eff.fire,})
	end,}

newEffect {
	name = 'CONSUMED_FLAME', image = 'talents/consume.png',
	desc = 'Consumed Flame',
	long_desc = function(self, eff)
		return ([[Target gains %d heat every turn.]]):format(eff.heat)
	end,
	type = 'physical',
	subtype = {nature = true, fire = true,},
	status = 'beneficial',
	parameters = {heat = 10,},
	on_gain = function(self, eff)
		return '#Target# consumes its own heat!', '+Consumed Flame'
	end,
	on_lose = function(self, eff)
		return '#Target#\'s consumed heat runs out!', '-Consumed Flame'
	end,
	on_timeout = function(self, eff)
		self:incHeat(eff.heat)
	end,}

newEffect {
	name = 'BILLOWING_CARPET', image = 'talents/billowing_carpet.png',
	desc = 'Billowing Carpet',
	long_desc = function(self, eff)
		local blind, silence = '', ''
		if eff.blind_dur then blind = (' blinded for %d turns,'):format(eff.blind_dur) end
		if eff.silence_dur then
			silence = (' silenced for %d turns,'):format(eff.silence_dur)
		end
		return ([[You are%s%s losing %d air every turn and are %d%% more likely to be hit with a critical.]])
			:format(blind, silence, eff.air, eff.crit)
	end,
	type = 'physical',
	subtype = {air = true, fire = true,},
	status = 'detrimental',
	parameters = {crit = 5, air = 12,},
	on_gain = function(self, eff)
		return '#Target# is covered by the billowing carpet!', '+Billowing Carpet'
	end,
	on_lose = function(self, eff)
		return '#Target#\'s escapes from the billowing carpet!', '-Billowing Carpet'
	end,
	activate = function(self, eff)
		if self:canBe('blind') then
			eff.blind_id = self:addTemporaryValue('blind', 1)
			eff.blind_dur = eff.dur
		end
		if self:canBe('silence') then
			eff.silence_id = self:addTemporaryValue('silence', 1)
			eff.silence_dur = eff.dur
		end
		eff.crit_id = self:addTemporaryValue('combat_crit_vulnerable', eff.crit)
	end,
	deactivate = function(self, eff)
		if eff.blind_id then self:removeTemporaryValue('blind', eff.blind_id) end
		if eff.silence_id then self:removeTemporaryValue('silence', eff.silence_id) end
		self:removeTemporaryValue('combat_crit_vulnerable', eff.crit_id)
	end,
	on_merge = function(self, old, new)
		if self:canBe('blind') then
			if old.blind_id then
				new.blind_id = old.blind_id
				new.blind_dur = math.max(old.blind_dur, new.dur)
			else
				new.blind_id = self:addTemporaryValue('blind', 1)
				new.blind_dur = eff.dur
			end
		else
			new.blind_id = old.blind_id
			new.blind_dur = old.blind_dur
		end

		if self:canBe('silence') then
			if old.silence_id then
				new.silence_id = old.silence_id
				new.silence_dur = math.max(old.silence_dur, new.dur)
			else
				new.silence_id = self:addTemporaryValue('silence', 1)
				new.silence_dur = eff.dur
			end
		else
			new.silence_id = old.silence_id
			new.silence_dur = old.silence_dur
		end

		if new.crit > old.crit then
			self:removeTemporaryValue('combat_crit_vulnerable', old.crit_id)
			new.crit_id = self:addTemporaryValue('combat_crit_vulnerable', new.crit)
		else
			new.crit_id = old.crit_id
		end

		new.air = math.max(old.air, new.air)

		return new
	end,
	on_timeout = function(self, eff)
		if eff.blind_dur then
			eff.blind_dur = eff.blind_dur - 1
			if eff.blind_dur <= 0 then
				self:removeTemporaryValue('blind', eff.blind_id)
				eff.blind_id = nil
				eff.blind_dur = nil
			end
		end
		if eff.silence_dur then
			eff.silence_dur = eff.silence_dur - 1
			if eff.silence_dur <= 0 then
				self:removeTemporaryValue('silence', eff.silence_id)
				eff.silence_id = nil
				eff.silence_dur = nil
			end
		end

		self:suffocate(eff.air, eff.src, (' was suffocated to death by %s\'s billowing carpet.')
										 :format(eff.src.unique and eff.src.name or eff.src.name:a_an()))
	end,}

newEffect {
	name = 'BILLOWING_CARPET_COVER', image = 'talents/billowing_carpet.png',
	desc = 'Billowing Carpet Cover',
	long_desc = function(self, eff)
		return ([[You are covered by the billowing carpet, giving you %d heat every turn and increasing your stealth and defense by %d. (%d%% of your Cunning)]])
			:format(eff.heat_gain, eff.stealth * self:getCun(), eff.stealth * 100)
	end,
	type = 'physical',
	subtype = {nature = true, fire = true,},
	status = 'beneficial',
	parameters = {stealth = 0.1, heat_gain = 10,},
	on_gain = function(self, eff)
		return '#Target# is covered by the billowing carpet.', '+Billowing Carpet Cover'
	end,
	on_lose = function(self, eff)
		return '#Target# has exited the billowing carpet.', '-Billowing Carpet Cover'
	end,
	activate = function(self, eff)
		local bonus = self:getCun() * eff.stealth
		self:effectTemporaryValue(eff, 'inc_stealth', bonus)
		self:effectTemporaryValue(eff, 'combat_def', bonus)
		if not self:isTalentActive('T_STEALTH') then
			local hide_chance = self.hide_chance
			self.hide_chance = 100
			self:forceUseTalent('T_STEALTH', {
														force_level = self:getTalentLevel('T_STEALTH') or 1,
														ignore_energy = true,
														ignore_cd = true,
														ignore_ressources = true,})
			self.hide_chance = hide_chance
		end
	end,
	deactivate = function(self, eff)
		if not eff.no_deactivate_stealth and
			not self:knowTalent('T_STEALTH') and
			self:isTalentActive('T_STEALTH')
		then
			self:forceUseTalent('T_STEALTH', {ignore_energy = true, ignore_cd = true,})
		end
	end,
	on_merge = function(self, old, new)
		old.no_deactivate_stealth = true
		self.tempeffect_def.EFF_BILLOWING_CARPET_COVER.deactivate(self, old)
		self.tempeffect_def.EFF_BILLOWING_CARPET_COVER.activate(self, new)
		return new
	end,
	on_timeout = function(self, eff)
		self:incHeat(eff.heat_gain)
	end,}

newEffect {
	name = 'FIERY_BINDINGS', image = 'talents/tendrils_of_fire.png',
	desc = 'Fiery Bindings',
	long_desc = function(self, eff)
		local src = eff.src.unique and eff.src.name or eff.src.name:a_an()
		return ([[Target is lashed to %s with tendrils of flame, taking %d fire damage every turn and moving along with them. This also generates %d heat for %s every turn.]])
			:format(src,
							damDesc(eff.src, 'FIRE', eff.src:heatScale(eff.damage)),
							eff.heat_gain,
							src)
	end,
	type = 'physical',
	subtype = {pin = true, fire = true,},
	status = 'detrimental',
	parameters = {damage = 10,},
	on_gain = function(self, eff)
		return '#Target# is bound with fiery tendrils!', '+Fiery Bindings'
	end,
	on_lose = function(self, eff)
		return '#Target# escapes the fiery tendrils!!', '-Fiery Bindings'
	end,
	activate = function(self, eff)
		self:effectTemporaryValue(eff, 'never_move', 1)
		if core.fov.distance(self.x, self.y, eff.src.x, eff.src.y) > 1 then
			self:pull(eff.src.x, eff.src.y, 1000)
		end
	end,
	deactivate = function(self, eff)
		eff.src:forceUseTalent('T_TENDRILS_OF_FIRE', {ignore_energy = true,})
		return true
	end,
	on_timeout = function(self, eff)
		if core.fov.distance(eff.src.x, eff.src.y, self.x, self.y) > 1 then
			self:removeEffect('EFF_FIERY_BINDINGS', false, true)
		else
			damage_type:get('FIRE').projector(
				eff.src, self.x, self.y, 'FIRE', eff.src:heatScale(eff.damage))
			eff.src:incHeat(eff.heat_gain)
		end
	end,}

newEffect{
	name = 'PARTIALLY_BLINDED', image = 'effects/blinded.png',
	desc = 'Partially Blinded',
	long_desc = function(self, eff)
		return ('The target is partially blinded, reducing accuracy by %d.'):format(eff.power)
	end,
	type = 'physical',
	subtype = {blind = true},
	status = 'detrimental',
	parameters = {power = 10,},
	on_gain = function(self, err) return '#Target# struggles to see!', '+Partial Blindness' end,
	on_lose = function(self, err) return '#Target# recovers sight.', '-Partial Blindness' end,
	activate = function(self, eff)
		self:effectTemporaryValue(eff, 'combat_atk', -eff.power)
	end,}

newEffect{
	name = 'COOKED', image = 'talents/microwave.png',
	desc = 'Cooked',
	long_desc = function(self, eff)
		return ('The target is cooked in it\'s armour, reducing it by %d.'):format(eff.power)
	end,
	type = 'physical',
	subtype = {sunder = true, lightning = true,},
	status = 'detrimental',
	parameters = {power = 10,},
	on_gain = function(self, err) return '#Target# is cooked!', '+Cooked' end,
	on_lose = function(self, err) return '#Target# armour recovers.', '-Cooked' end,
	activate = function(self, eff)
		self:effectTemporaryValue(eff, 'combat_armor', -eff.power)
	end,}

newEffect {
	name = 'LIFEPYRE', image = 'talents/lifepyre.png',
	desc = 'Lifepyre',
	long_desc = function(self, eff)
		return ('The target will heal %d%% of all damage taken #SLATE#(before resists)#LAST# over %d turns.'):format(eff.healing, eff.smearing)
	end,
	type = 'magical',
	subtype = {healing = true, fire = true,},
	status = 'beneficial',
	parameters = {healing = 50, smearing = 10,},
	on_gain = function(self, eff) return '#Target# burns brilliantly!', '+Lifepyre' end,
	on_lose = function(self, eff) return '#Target# stops burning brilliantly.', '-Lifepyre' end,}

newEffect {
	name = 'LIFEPYRE_HEALING',
	desc = 'Lifepyre Healing',
	long_desc = function(self, eff)
		return ('The target is regenerating %d per turn.'):format(eff.healing)
	end,
	type = 'magical',
	subtype = {healing = true, fire = true, nature = true,},
	status = 'beneficial',
	parameters = {healing = 10,},
	activate = function(self, eff)
		eff.heal_id = self:addTemporaryValue('life_regen', eff.healing)

		if core.shader.active(4) then
			eff.particle1 = self:addParticles(particles.new("shader_shield", 1, {toback=true,  size_factor=1.5, y=-0.3, img="healarcane"}, {type="healing", time_factor=4000, noup=2.0, circleColor={0,0,0,0}, beamColor1 = {0.7,0.3,0.0,1.0,}, beamColor2 = {1.0,0.6,0.1,1.0,}, beamsCount=9}))
			eff.particle2 = self:addParticles(particles.new("shader_shield", 1, {toback=false,  size_factor=1.5, y=-0.3, img="healarcane"}, {type="healing", time_factor=4000, noup=2.0, circleColor={0,0,0,0}, beamColor1 = {0.7,0.3,0.0,1.0,}, beamColor2 = {1.0,0.6,0.1,1.0,}, beamsCount=9}))
		end
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue('life_regen', eff.heal_id)
		self:removeParticles(eff.particle1)
		self:removeParticles(eff.particle2)
	end,
	on_merge = function(self, old, new)
		self:removeTemporaryValue('life_regen', old.heal_id)
		old.healing = (old.healing * old.dur + new.healing * new.dur) / new.dur
		old.dur = new.dur
		old.heal_id = self:addTemporaryValue('life_regen', old.healing)
		return old
	end,}

newEffect {
	name = 'CREMATED',
	desc = 'Cremated',
	image = 'talents/cremation.png',
	long_desc = function(self, eff)
		return ('The target is subject to intense heat, decreasing its healing modifier by %d%%.')
			:format(eff.power)
		end,
	type = 'other',
	subtype = {fire = true,},
	parameters = {power = 100,},
	activate = function(self, eff)
		self:autoTemporaryValues(eff, {healing_factor = -0.01 * eff.power,})
		end,
	deactivate = function(self, eff) return true end,}

newEffect {
	name = 'SEARING_VISIONS',
	desc = 'Searing Visions',
	image = 'talents/mindflare.png',
	long_desc = function(self, eff)
		if not eff.src or eff.src.dead then return 'ERROR: No Source.' end
		local talents = table.mapv(function(tid) return self:getTalentFromId(tid).name end, eff.talents)
		return ('Target is plagued by visions of dancing flame. Using one of the following talents will deal them %d #SLATE#[spell crit]#LAST# #LIGHT_RED#fire#LAST# damage:\n%s')
			:format(
				eff.src:damDesc('FIRE', eff.fire_damage),
				table.concat(talents, '\n'))
		end,
	type = 'mental',
	subtype = {fire = true,},
	parameters = {fire_damage = 10, talent_count = 2,},
	callbackOnTalentPost = function(self, eff, ab, ret, silent)
		for _, talent_id in pairs(eff.talents) do
			if talent_id == ab.id then
				eff.src:projectOn(self, 'FIRE', eff.src:mindCrit(eff.fire_damage))
				return
				end end
		end,
	activate = function(self, eff)
		-- Grab all talents.
		eff.talents = {}
		for id, level in pairs(self.talents) do
			local talent = self:getTalentFromId(id)
			local usable = talent.mode == 'activated' or
				(talent.mode == 'sustained' and not self:isTalentActive(id))
			if usable and not talent.innate then table.insert(eff.talents, id) end
			end
		table.shuffle(eff.talents)
		while #eff.talents > eff.talent_count do table.remove(eff.talents) end
		end,
	deactivate = function(self, eff) return true end,}
