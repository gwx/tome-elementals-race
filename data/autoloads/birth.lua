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


for _, world in pairs {'Maj\'Eyal', 'Infinite', 'Arena',} do
	local bd = getBirthDescriptor('world', world)
	if bd then
		bd.descriptor_choices.race.Elemental = 'allow'
	end
end

-- TODO: Prevent from learning combat training (in ID).
newBirthDescriptor {
	type = 'race',
	name = 'Elemental',
	desc = {'Sentient beings created as part of nature\'s reaction to its gradual corruption by the spellblaze.',
					'Elementals are immune to disease and poison but cannot use runes.',},
	descriptor_choices = {
		subrace = {
			__ALL__ = 'disallow',
			Jadir = 'allow',
			Asha = config.settings.cheat and 'allow' or 'disallow',
			['Hybrid Elemental'] = config.settings.cheat and 'allow' or 'disallow',},
		class = {
			__ALL__ = 'disallow',
			None = 'allow',},},
	random_escort_possibilities = {
		{'tier1.1', 1, 2}, {'tier1.2', 1, 2}, {'daikara', 1, 2},
		{'old-forest', 1, 4}, {'dreadfell', 1, 8}, {'reknor', 1, 2},},
	moddable_attachement_spots = 'race_human',
	copy = {
		faction = 'allied-kingdoms',
		type = 'elemental',
		resolvers.inventory{id = true, {defined = 'ORB_SCRYING',},},
		resolvers.inscription(
			'INFUSION:_REGENERATION', {cooldown = 10, dur = 5, heal = 60,}),
		resolvers.inscription(
			'INFUSION:_WILD',
			{cooldown = 12, what = {physical = true,}, dur = 4, power = 14,}),
		moddable_tile = 'human_#sex#',
		moddable_tile_base = 'base_cornac_01.png',
		random_name_def = 'cornac_#sex#',
		default_wilderness = {'playerpop', 'allied'},
		starting_zone = 'trollmire',
		starting_quest = 'start-allied',
		starting_intro = 'cornac',
		forbid_combat_training = true,
		inscription_restrictions = {
			['inscriptions/infusions'] = true,},
		disease_immune = 1,
		poison_immune = 1,},}

newBirthDescriptor {
	type = 'subrace',
	name = 'Jadir',
	desc = {
		'The Earth Elemental.',
		'Jadir have Jagged Body, a passive shield that reflects physical damage. Their main resource is Essence, which has its max value and regen rate tied to that of your Life.',
		'Jadir may always equip heavy armour and shields, despite not being able to learn Armour Training.',
		'#GOLD#Stat modifiers:',
		'#LIGHT_BLUE# * +4 Strength, -2 Dexterity, +5 Constitution',
		'#LIGHT_BLUE# * +4 Magic, +0 Willpower, -2 Cunning',
		'#GOLD#Life per level:#LIGHT_BLUE# 13',
		'#GOLD#Experience penalty:#LIGHT_BLUE# 40%',
		'',
		'#GREY#',
		'Jadir is, if the element doesn\'t betray it already, the beefier of the four classes. If it hits, it hits hard, if it tanks, it tanks even harder. I wanted this class to have the most "inert" of skillsets, that is skills that don\'t require complex targeting, as it would be more fitting for a class that\'s supposed to rely less on mobility and more on the raw stat bulk - hence the majority of the skills having a focus on point-blank AoE skills, sustains or enhancements.',
		'This does of course not mean that it\'s a class entirely grounded in it\'s ability to manipulate the game elements beyond just punching them. To compensate for the lack of speed it has a variety of skills that affect the environment, in particular walls. It felt very fitting, both for the lore and the general playstyle, an earth elemental controlling natural solid physical obstacles.'},
	inc_stats = {str = 4, dex = -2, con = 5, mag = 4, cun = -2,},
	power_source = {nature = true,},
	talents_types = {
		['elemental/mountain'] = {true, 0.3,},
		['elemental/avalanche'] = {true, 0.3,},
		['elemental/symbiosis'] = {true, 0.3,},
		['elemental/geokinesis'] = {true, 0.3,},
		['elemental/geothermal'] = {true, 0.3,},
		['elemental/erosion'] = {true, 0.3,},
		['elemental/eyal-resolver'] = {true, 0.3,},
		['elemental/cliffside'] = {true, 0.3,},
		['elemental/tectonic'] = {false, 0.3,},
		['elemental/earth-metamorphosis'] = {false, 0.3,},},
	talents = {
		T_PINPOINT_TOSS = 1,
		T_EARTHEN_GUN = 1,
		T_JAGGED_BODY = 1,},
	experience = 1.4,
	copy = {
		moddable_tile = 'jadir',
		moddable_tile_nude = true,
		moddable_tile_base = 'base_01.png',
		subtype = 'earth',
		max_life = 130,
		life_rating = 13,
		no_breath = 1,
		show_gloves_combat = 1,
		equip_only_armour_training = 2, -- Fake armour training levels for equipping stuff.
		resolvers.equip {
			id = true,
			{type = 'weapon', subtype = 'greatmaul', name = 'iron greatmaul',
			 autoreq = true, ego_chance = -1000},
 			{type = 'armor', subtype = 'heavy', name = 'iron mail armour',
			 autoreq = false, ego_chance = -1000},
			{type = 'armor', subtype = 'hands', name = 'iron gauntlets',
			 autoreq = false, ego_chance = -1000},
			{type = 'ammo', subtype = 'shot', name = 'pouch of iron shots',
			 autoreq = false, ego_chance = -1000},},
		resolvers.inventory {
			id = true, inven = 'QS_MAINHAND',
			{type = 'weapon', subtype = 'mace', name = 'iron mace',
			 autoreq = true, ego_chance = -1000,},},
		resolvers.inventory {
			id = true, inven = 'QS_OFFHAND',
			{type = 'armor', subtype = 'shield', name = 'iron shield',
			 autoreq = true, ego_chance = -1000,},},},}

newBirthDescriptor {
	type = 'subrace',
	name = 'Asha',
	desc = {
		'The Fire Elemental.',
		'#GOLD#Stat modifiers:',
		'#LIGHT_BLUE# * +3 Strength, +5 Dexterity, -2 Constitution',
		'#LIGHT_BLUE# * +4 Magic, -1 Willpower, +0 Cunning',
		'#GOLD#Life per level:#LIGHT_BLUE# 10',
		'#GOLD#Experience penalty:#LIGHT_BLUE# 40%',
		'',
		'#GREY#',
		'Asha is probably my favourite designed class, or at least the most favourite in terms of theoretical gameplay. It\'s fast-paced, full of synergetic chains of skills, but streamlined to the point where there\'s no need for overthinking to play it effectively. It\'s centered on the wedge of offensive play and mobility and the player is rewarded for remaining in fight, for as long as possible.',},
	inc_stats = {str = 3, dex = 5, con = -2, mag = 4, wil = -1,},
	power_source = {nature = true,},
	talents_types = {
		['elemental/brand'] = {true, 0.3,},
		['elemental/heat'] = {true, 0.3,},
		['elemental/firestarter'] = {true, 0.3,},
		['elemental/pyrokinesis'] = {true, 0.3,},
		['elemental/power'] = {true, 0.3,},
		['elemental/chaos'] = {true, 0.3,},
		['elemental/illusions-of-fire'] = {true, 0.3,},
		['elemental/magma'] = {false, 0.3,},
		['elemental/fire-metamorphosis'] = {false, 0.3,},},
	talents = {
		T_WRATHFUL_STRIKE = 1,
		T_FIREDANCER = 1,},
	experience = 1.4,
	copy = {
		moddable_tile = "human_#sex#",
		moddable_tile_base = "base_higher_01.png",
		--moddable_tile_nude = true,
		subtype = 'fire',
		max_life = 100,
		life_rating = 10,
		resolvers.equip {
			id = true,
			{type = 'weapon', subtype = 'greatsword', name = 'iron greatsword',
			 autoreq = true, ego_chance = -1000},
 			{type = 'armor', subtype = 'light', name = 'rough leather armour',
			 autoreq = true, ego_chance = -1000},
			{type = 'armor', subtype = 'hands', name = 'rough leather gloves',
			 autoreq = true, ego_chance = -1000},},},}

newBirthDescriptor {
	type = 'subrace',
	name = 'Hybrid Elemental',
	locked = function()
		return profile.mod.allow_build.adventurer or
			config.settings.cheat or
			'hide'
	end,
	desc = {
		'Some elementals do not fall strictly along the elemental lines, and may be composed of several different elements.',
		'#GOLD#Stat modifiers:',
		'#LIGHT_BLUE# * +2 Strength, +2 Dexterity, +2 Constitution',
		'#LIGHT_BLUE# * +2 Magic, +2 Willpower, +2 Cunning',
		'#GOLD#Life per level:#LIGHT_BLUE# 10',
		'#GOLD#Experience penalty:#LIGHT_BLUE# 40%',
		'',
		'#GREY#',},
	inc_stats = {str = 2, dex = 2, con = 2, mag = 2, wil = 2, cun = 2,},
	power_source = {nature = true,},
	talents_types = function(birth)
		local tts = {}
		local race = getBirthDescriptor('race', 'Elemental')
		for elemental, allow in pairs(race.descriptor_choices.subrace) do
			if elemental ~= '__ALL__' and elemental ~= 'Hybrid Elemental' then
				elemental = getBirthDescriptor('subrace', elemental)
				if elemental.talents_types then
					local tt = elemental.talents_types
					if type(tt) == 'function' then tt = tt(birth) end
					for t, _ in pairs(tt) do
						tts[t] = {false, 0}
					end
				end
				if elemental.unlockable_talents_types then
					local tt = elemental.unlockable_talents_types
					if type(tt) == 'function' then tt = tt(birth) end
					for t, v in pairs(tt) do
						if profile.mod.allow_build[v[3]] then
							tts[t] = {false, 0}
						end
					end
				end
			end
		end
		return tts
	end,
	experience = 1.4,
	copy_add = {
		unused_generics = 2,
		unused_talents = 3,
		unused_talents_types = 7,},
	copy = {
		moddable_tile = "human_#sex#",
		moddable_tile_base = "base_higher_01.png",
		--moddable_tile_nude = true,
		subtype = 'hybrid',
		max_life = 100,
		life_rating = 10,
		resolvers.inventorybirth{ id=true, transmo=true,
			{type="weapon", subtype="dagger", name="iron dagger", autoreq=true, ego_chance=-1000},
			{type="weapon", subtype="dagger", name="iron dagger", autoreq=true, ego_chance=-1000},
			{type="weapon", subtype="longsword", name="iron longsword", ego_chance=-1000, ego_chance=-1000},
			{type="weapon", subtype="longsword", name="iron longsword", ego_chance=-1000, ego_chance=-1000},
			{type="weapon", subtype="staff", name="elm staff", autoreq=true, ego_chance=-1000},
			{type="weapon", subtype="mindstar", name="mossy mindstar", autoreq=true, ego_chance=-1000},
			{type="weapon", subtype="mindstar", name="mossy mindstar", autoreq=true, ego_chance=-1000},
			{type="armor", subtype="hands", name="iron gauntlets", autoreq=true, ego_chance=-1000, ego_chance=-1000},
			{type="armor", subtype="hands", name="rough leather gloves", ego_chance=-1000, ego_chance=-1000},
			{type="armor", subtype="light", name="rough leather armour", ego_chance=-1000, ego_chance=-1000},
			{type="armor", subtype="cloth", name="linen robe", autoreq=true, ego_chance=-1000},
			{type="weapon", subtype="longbow", name="elm longbow", autoreq=true, ego_chance=-1000},
			{type="ammo", subtype="arrow", name="quiver of elm arrows", autoreq=true, ego_chance=-1000},
			{type="weapon", subtype="sling", name="rough leather sling", autoreq=true, ego_chance=-1000},
			{type="ammo", subtype="shot", name="pouch of iron shots", autoreq=true, ego_chance=-1000},
		},
	},}
