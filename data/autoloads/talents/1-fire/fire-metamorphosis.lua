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
local Stats = require 'engine.interface.ActorStats'
local Object = require 'mod.class.Object'

newTalentType {
	type = 'elemental/fire-metamorphosis',
	name = 'Metamorphosis',
	description = 'Raging Flames',
	allow_random = true,}

local make_require = function(tier)
	return {
		stat = {mag = function(level) return 12 + tier * 8 + level * 2 end,},
		level = function(level) return 5 + tier * 4 + level end,}
end

newTalent {
	name = 'Insurmountable Glut',
	type = {'elemental/fire-metamorphosis', 1,},
	require = make_require(1),
	points = 5,
	mode = 'passive',
	combat_dam = function(self, t) return self:scale {low = 5, high = 30, t, 'mag',} end,
	fire_pen = function(self, t) return self:scale {low = 5, high = 21, t,} end,
	lite = function(self, t) return self:scale {low = 1, high = 5, t, 'mag', after = 'floor',} end,
	passives = function(self, t, p)
		self:autoTemporaryValues(p, {
				combat_dam = get(t.combat_dam, self, t),
				resists_pen = {FIRE = get(t.fire_pen, self, t),},
				lite = get(t.lite, self, t),})
		end,
	recompute_passives = {stats = {Stats.STAT_MAG,},},
	info = function(self, t)
		return ([[You glow red with might, increasing your physical power by %d #SLATE#[*, mag]#LAST#, your #LIGHT_RED#fire#LAST# penetration by %d%% #SLATE#[*]#LAST#, and your light radius by %d #SLATE#[*, mag]#LAST#.]])
			:format(
				get(t.combat_dam, self, t),
				get(t.fire_pen, self, t),
				get(t.lite, self, t))
		end,}

newTalent {
	name = 'Energy',
	type = {'elemental/fire-metamorphosis', 2,},
	require = make_require(2),
	points = 5,
	cooldown = 31,
	no_energy = true,
	duration = function(self, t) return self:scale {low = 4, high = 6.5, t, after = 'floor',} end,
	spell_crit_mod = 40,
	spell_crit = function(self, t)
		return get(t.spell_crit_mod, self, t) * 0.01 *
			((self.resists_pen.all or 0) + (self.resists_pen.FIRE or 0))
		end,
	stun_chance = function(self, t) return self:scale {low = 20, high = 60, t,} end,
	stun_duration = 2,
	action = function(self, t)
		self:setEffect('EFF_ENERGY', get(t.duration, self, t), {
				crit = get(t.spell_crit, self, t),})
		return true
		end,
	callbackOnDealDamage = function(self, t, val, target, dead, death_note)
		if 'spell' ~= self.turn_procs.is_crit then return end
		if not target then return end
		if not rng.percent(get(t.stun_chance, self, t)) then return end
		if not target:canBe 'stun' then return end
		target:setEffect('EFF_STUNNED', get(t.stun_duration, self, t), {apply_power = self:combatSpellpower(),})
		end,
	info = function(self, t)
		return ([[Conducts fire to energy. For the next %d #SLATE#[*]#LAST# turns all #LIGHT_RED#fire#LAST# damage inflicted turns into #ROYAL_BLUE#lightning#LAST# damage and increases your critical spell chance by %d%% of your #LIGHT_RED#fire#LAST# penetration. This will also increase your +#ROYAL_BLUE#lightning#LAST#%% damage to your +#LIGHT_RED#fire#LAST#%% damage if it is higher.

Your critical spell strikes now have a %d%% chance to #ORANGE#stun#LAST# #SLATE#[spell vs. phys, stun]#LAST# enemies hit for %d turns. This will apply to at most one target per critical check.]])
			:format(
				get(t.duration, self, t),
				get(t.spell_crit_mod, self, t),
				get(t.stun_chance, self, t),
				get(t.stun_duration, self, t))
		end,}

newTalent {
	name = 'Charred Armour',
	type = {'elemental/fire-metamorphosis', 3,},
	require = make_require(3),
	points = 5,
	mode = 'passive',
	resists_percent = function(self, t) return self:scale {low = 50, high = 135, t, 'mag',} end,
	resists = function(self, t) return get(t.resists_percent, self, t) * self:combatArmor() * 0.0001 end,
	passives = function(self, t, p)
		local resist = get(t.resists, self, t)
		self:autoTemporaryValues(p, {
				equip_only_armour_training = 1,
				pin_immune = resist,
				stun_immune = resist,})
		end,
	recompute_passives = {
		stats = {Stats.STAT_MAG,},
		attributes = {'combat_armor',},},
	callbackOnCanBe = function(self, t, what)
		if 'stun' == what or 'pin' == what then self:updateTalentPassives(t.id) end
		end,
	info = function(self, t)
		return ([[Nothing can weigh down your flames.
Allows you to wear heavy armour. %d%% #SLATE#[*, mag]#LAST# of your armour rating is added to your pin and stun resistance. (Currently %d%%.)]])
			:format(
				get(t.resists_percent, self, t),
				get(t.resists, self, t) * 100)
		end,}

newTalent {
	name = 'Solar Grasp',
	type = {'elemental/fire-metamorphosis', 4,},
	require = make_require(4),
	points = 5,
	mode = 'passive',
	armor = function(self, t) return self:scale {low = 6, high = 10, t,} end,
	defense = function(self, t) return self:scale {low = 8, high = 16, t,} end,
	str = function(self, t) return self:scale {low = 4, high = 8, t,} end,
	mag = function(self, t) return self:scale {low = 4, high = 8, t,} end,
	resist_cap = function(self, t) return self:scale {low = 10, high = 18, t,} end,
	resist_pen = function(self, t) return self:scale {low = 10, high = 18, t,} end,
	inc_damage = function(self, t) return self:scale {low = 6, high = 13, t,} end,
	physcrit = 15,
	spellcrit = function(self, t) return self:scale {low = 10, high = 16, t,} end,
	critical_power = function(self, t) return self:scale {low = 25, high = 45, t, after = 'floor',} end,
	lite = function(self, t) return self:scale {low = 2, high = 4, t, after = 'floor',} end,
	create_armor = function(self, t)
		local armor = Object.new {
			define_as = 'SOLAR_GRASP',
			name = 'Solar Grasp',
			slot = 'HANDS',
			type = 'armor', subtype = 'hands',
			display = '[', colors = colors.LIGHT_RED, image = 'object/artifact/solar_grasp.png',
			moddable_tile = resolvers.moddable_tile('gauntlets'),
			encumber = 1.5,
			require = {'T_SOLAR_GRASP'},
			metallic = true,
			desc = ('These gauntlets radiate vast amounts of heat and light. As the Champion of Fire, you have earned the right to wear them.'),
			material_level = 5,
			plot = true,
			quest = true,
			unique = true,
			identified = true,
			no_drop = true,
			wielder = {},
			max_power = 40, power_regen = 1,
			use_talent = {id = 'T_SUN_FLARE', level = 1, power = 40,},}
		armor:resolve()
		self:addObject('INVEN', armor)
		return armor
	end,
	update_armor = function(self, t, armor, wearing)
		if wearing then self:onTakeoff(armor, true) end

		armor.wielder = {
			combat_armor = get(t.armor, self, t),
			combat_def = get(t.defense, self, t),
			inc_stats = {
				[Stats.STAT_STR] = get(t.str, self, t),
				[Stats.STAT_MAG] = get(t.mag, self, t),},
			resists_cap = {FIRE = get(t.resist_cap, self, t),},
			resists_pen = {FIRE = get(t.resist_pen, self, t),},
			inc_damage = {
				FIRE = get(t.inc_damage, self, t),
				LIGHT = get(t.inc_damage, self, t),},
			combat_physcrit = get(t.physcrit, self, t),
			combat_spellcrit = get(t.spellcrit, self, t),
			combat_critical_power = get(t.critical_power, self, t),
			lite = get(t.lite, self, t),}

		armor.use_talent.level = self:getTalentLevelRaw(t.id)

		if wearing then self:onWear(armor, true) end
	end,
	no_unlearn_last = true,
	on_learn = function(self, t)
		local armor, _, slot = self:findInAllInventoriesBy('define_as', 'SOLAR_GRASP')
		if not armor then armor = t.create_armor(self, t) end
		t.update_armor(self, t, armor, slot == self.INVEN_HANDS)

		if not self:getInven('HANDS')[1] then
			self:wearObject(armor)
		end
	end,
	on_unlearn = function(self, t)
		local armor, index, slot = self:findInAllInventoriesBy('define_as', 'SOLAR_GRASP')
		if not armor then return end

		if self:getTalentLevelRaw(t) == 0 then
			self:removeObject(slot, index)
		else
			t.update_armor(self, t, armor, slot == self.INVEN_HANDS)
		end
	end,
	info = function(self, t)
		return ([[Having proven your excellence, you are bestowed with the Solar Grasp, a unique artifact of incredible power. The Solar Grasp cannot leave your possession, be sold or transmogrified. It has the following stats, which will increase with talent level:

Armour: +%d, Defense: +%d
Stats:  +%d Strength, +%d Magic
Resistance Cap: +%d%% #LIGHT_RED#fire#LAST#
Resistance Penetration: +%d%% #LIGHT_RED#fire#LAST#
Damage: +%d%% #LIGHT_RED#fire#LAST#, +%d%% #YELLOW#light#LAST#
Critical Chance: +%d%% physical, +%d%% spell
Critical Power: +%d%%
Light Radius: +%d]])
			:format(
				get(t.armor, self, t),
				get(t.defense, self, t),
				get(t.str, self, t),
				get(t.mag, self, t),
				get(t.resist_cap, self, t),
				get(t.resist_pen, self, t),
				get(t.inc_damage, self, t),
				get(t.inc_damage, self, t),
				get(t.physcrit, self, t),
				get(t.spellcrit, self, t),
				get(t.critical_power, self, t),
				get(t.lite, self, t))
		end,}
