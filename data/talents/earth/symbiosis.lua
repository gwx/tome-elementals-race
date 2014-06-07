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

newTalentType {
	type = 'elemental/symbiosis',
	name = 'Symbiosis',
	generic = true,
	description = 'Covering Vines',
	allow_random = true,}

local make_require = function(tier)
	return {
		stat = {mag = function(level) return 2 + tier * 8 + level * 2 end,},
		level = function(level) return -5 + tier * 4 + level end,}
end

local get_tree_points_raw = function(self)
	local amt = 0
	for _, talent in pairs {'T_IVY_MESH', 'T_PUT_ROOTS', 'T_PREDATORY_VINES', 'T_YGGDRASIL'} do
		amt = amt + self:getTalentLevelRaw(talent)
	end
	return amt
end

local passive_block = function(self, t, p)
	local block = self:getTalentLevelRaw(t) * 5
	self:talentTemporaryValue(p, 'partial_block_types', {
															[DamageType.NATURE] = block,
															[DamageType.BLIGHT] = block,})
end

local block_info = function(self, t)
	local points = get_tree_points_raw(self)
	return ('Also allows handheld shields to always block nature and blight damage types with at least %d%% power.')
		:format(util.bound(points * 5, 0, 100))
end

newTalent {
	name = 'Ivy Mesh',
	type = {'elemental/symbiosis', 1,},
	require = make_require(1),
	points = 5,
	mode = 'passive',
	poison = function(self, t) return self:combatTalentSpellDamage(t, 20, 80) end,
	save_per = function(self, t) return 2 + self:getTalentLevel(t) * 0.5 end,
	save_max = function(self, t) return 14 + self:getTalentLevel(t) * 2 end,
	passives = function(self, t, p)
		passive_block(self, t, p)
	end,
	info = function(self, t)
		return ([[The Jadir's body has become overgrown with thorny vines, any enemy attacking in melee is poisoned and suffers %d nature damage each turn for 3 turns, halving each turn.
The fresh residue of the vines increases your spell save by %d, for every enemy currently afflicted with the poison, up to %d.
Damage done increases with spellpower.

%s]])
			:format(
				Talents.damDesc(self, DamageType.NATURE, t.poison(self, t)),
				t.save_per(self, t),
				t.save_max(self, t),
				block_info(self, t))
	end,}

newTalent {
	name = 'Put Roots',
	type = {'elemental/symbiosis', 2,},
	require = make_require(2),
	points = 5,
	essence = 20,
	cooldown = 26,
	tactical = {ATTACKAREA = {NATURE = 1,}, DISABLE = {pin = 1,},},
	range = 0,
	radius = function(self, t)
		return math.floor(1.5 + self:getTalentLevel(t) * 0.5)
	end,
	duration = function(self, t)
		return math.floor(4.5 + self:getTalentLevel(t) * 0.5)
	end,
	healing = function(self, t)
		return 0.1 + self:combatTalentSpellDamage(t, 0.2, 0.4)
	end,
	save = function(self, t)
		return 8 + self:combatTalentSpellDamage(t, 6, 18)
	end,
	damage = function(self, t)
		return self:combatTalentSpellDamage(t, 5, 40)
	end,
	target = function(self, t)
		return {type = 'ball',
						range = util.getval(t.range, self, t),
						radius = util.getval(t.radius, self, t),
						selffire = false, talent = t,}
	end,
	passives = function(self, t, p)
		passive_block(self, t, p)
	end,
	action = function(self, t)
		local effect = game.level.map:addEffect(
			self, self.x, self.y, t.duration(self, t),
			DamageType.SYMBIOTIC_ROOTS, {
				healing = t.healing(self, t),
				save = t.save(self, t),
				damage = self:spellCrit(t.damage(self, t)),},
			t.radius(self, t), 5, nil, {
				type = 'moss',})
		-- Let damage type know about original effect
		effect.dam.effect = effect
		game:playSoundNear(self, 'talents/slime')
		return true
	end,
	info = function(self, t)
		return ([[Send entangling roots out in radius %d for %d turns. While standing in them, the roots will increase your healing factor by %d%% and your physical save by %d. Any enemy moving through them wil take %d nature damage, and will be pinned for 4 turns the fourth and subsequent times which they receive damage.
Healing factor, damage and pinning power increase with spellpower.

%s]])
			:format(
				util.getval(t.radius, self, t),
				util.getval(t.duration, self, t),
				t.healing(self, t) * 100,
				t.save(self, t),
				Talents.damDesc(self, DamageType.NATURE, t.damage(self, t)),
				block_info(self, t))
	end,}

newTalent {
	name = 'Predatory Vines',
	type = {'elemental/symbiosis', 3,},
	require = make_require(3),
	points = 5,
	essence = 10,
	cooldown = 13,
	tactical = {ATTACKAREA = {NATURE = 2,}, DISABLE = {pin = 2,},},
	range = 0,
	radius = 3,
	duration = 5,
	damage = function(self, t) return self:combatTalentSpellDamage(t, 15, 30) end,
	shots = function(self, t) return 1 + math.floor(self:getTalentLevel(t) * 0.4) end,
	target = function(self, t)
		return {type = 'ball',
						range = util.getval(t.range, self, t),
						radius = util.getval(t.radius, self, t),
						selffire = false, talent = t,}
	end,
	passives = function(self, t, p)
		passive_block(self, t, p)
	end,
	action = function(self, t)
		-- Grab valid targets.
		local tg = util.getval(t.target, self, t)
		local targets = {}
		local is_hostile = function(target) return self:reactionToward(target) < 0 end
		self:project(tg, self.x, self.y, eutil.actor_grabber(targets, is_hostile))
		if 0 == #targets then return end

		-- Fill hits table with {target -> hit count}
		local hits = {}
		table.shuffle(targets)
		local shots = util.getval(t.shots, self, t)
		while shots > 0 do
			for _, target in pairs(targets) do
				hits[target] = (hits[target] or 0) + 1
				shots = shots - 1
				if shots == 0 then break end
			end
		end

		-- Apply debuff to each target
		local damage = t.damage(self, t)
		for target, power in pairs(hits) do
			target:setEffect('EFF_PREDATORY_VINES', 5, {
												 src = self,
												 damage = damage * power,
												 leash = 6 - power,})
			game.level.map:particleEmitter(target.x, target.y, 1, 'slime')
		end
		game:playSoundNear(self, 'talents/slime')
		return true
	end,
	info = function(self, t)
		return ([[An entire ecosystem begins to form on your body. At your command, %d carnivorous vines shoot forth, attaching themselves to a random enemy in radius %d for 5 turns. Each turn they deal %d nature damage and apply or refresh the Ivy Mesh poison. Affected enemies cannot escape the leash range of 5 tiles away from you.
Multiple vines may stack onto the same target if there are no other targets present, stacking the damage and decreasing the leash range by 1 for each extra vine attached.
Damage increases with spellpower.

%s]])
			:format(
				util.getval(t.shots, self, t),
				util.getval(t.radius, self, t),
				Talents.damDesc(self, DamageType.NATURE, util.getval(t.damage, self, t)),
				block_info(self, t))
	end,}

newTalent {
	name = 'Yggdrasil',
	type = {'elemental/symbiosis', 4,},
	require = make_require(4),
	points = 5,
	cooldown = 31,
	mode = 'sustained',
	heal = function(self, t) return 0.3 + self:getTalentLevel(t) * 0.05 end,
	resist = function(self, t)
		return 15 + self:combatTalentSpellDamage(t, 0, 30)
	end,
	activate = function(self, t)
		local p = {}
		self:talentTemporaryValue(p, 'essence_consumption', 0.1)
		self:talentTemporaryValue(p, 'essence_consumption_heal', t.heal(self, t))
		return p
	end,
	deactivate = function(self, t, p) return true end,
	passives = function(self, t, p)
		if self:isTalentActive(t.id) then
			local resist = t.resist(self, t) * self:getEssence() / self:getMaxEssence()
			self:talentTemporaryValue(p, 'resists', {
																	[DamageType.NATURE] = resist,
																	[DamageType.BLIGHT] = resist,})
		end
		passive_block(self, t, p)
	end,
	info = function(self, t)
		return ([[Surge essence through your body to make it bloom with life. Consumes 10%% of your current essence each turn, healing you for %d%% of the essence used. This will also give you nature and blight resistance, ranging from 0%% at 0%% essence to %d%% at 100%% essence (scaling with spellpower).

%s]])
			:format(t.heal(self, t) * 100, t.resist(self, t),
							block_info(self, t))
	end,}
