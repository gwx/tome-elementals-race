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


newTalentType {
	type = 'elemental/symbiosis',
	name = 'Symbiosis',
	generic = true,
	description = 'Covering Vines',}

local make_require = function(tier)
	return {
		stat = {mag = function(level) return 2 + tier * 8 + level * 2 end,},
		level = function(level) return -5 + tier * 4 + level end,}
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
	info = function(self, t)
		return ([[The Jadir's body has become overgrown with thorny vines, any enemy attacking in melee is poisoned and suffers %d nature damage each turn for 3 turns, halving each turn.
The fresh residue of the vines increases your spell save by %d, for every enemy currently afflicted with the poison, up to %d.
Damage done increases with spellpower.]])
			:format(
				Talents.damDesc(self, DamageType.NATURE, t.poison(self, t)),
				t.save_per(self, t),
				t.save_max(self, t))
	end,}

newTalent {
	name = 'Put Roots',
	type = {'elemental/symbiosis', 2,},
	require = make_require(2),
	points = 5,
	essence = 20,
	cooldown = 25,
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
	action = function(self, t)
		local effect = game.level.map:addEffect(
			self, self.x, self.y, t.duration(self, t),
			DamageType.SYMBIOTIC_ROOTS, {
				healing = t.healing(self, t),
				save = t.save(self, t),
				damage = t.damage(self, t),},
			t.radius(self, t), 5, nil, {
				type = 'moss',})
		-- Let damage type know about original effect
		effect.dam.effect = effect
		game:playSoundNear(self, 'talents/slime')
		return true
	end,
	info = function(self, t)
		return ([[Send entangling roots out in radius %d for %d turns. While standing in them, the roots will increase your healing factor by %d%% and your physical save by %d. Any enemy moving through them wil take %d nature damage, and will be pinned for 4 turns the fourth and subsequent times which they receive damage.
Healing factor, damage and pinning power increase with spellpower.]])
			:format(
				util.getval(t.radius, self, t),
				util.getval(t.duration, self, t),
				t.healing(self, t) * 100,
				t.save(self, t),
				Talents.damDesc(self, DamageType.NATURE, t.damage(self, t)))
	end,}
