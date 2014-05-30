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
local stats = require 'engine.interface.ActorStats'
local map = require 'engine.Map'
local active_terrain = require 'elementals-race.active-terrain'

newTalentType {
	type = 'elemental/earth-metamorphosis',
	name = 'Metamorphosis',
	description = 'Strength of Stone',
	allow_random = true,}

local make_require = function(tier)
	return {
		stat = {con = function(level) return 12 + tier * 8 + level * 2 end,},
		level = function(level) return 5 + tier * 4 + level end,}
end

newTalent {
	name = 'Temper Weapon',
	type = {'elemental/earth-metamorphosis', 1,},
	require = make_require(1),
	points = 5,
	mode = 'passive',
	physical = function(self, t)
		return self:combatTalentScale(t, 10, 25)
	end,
	unarmed = function(self, t)
		return 12 + self:getStr(12, true)
	end,
	mace = function(self, t)
		return 7 + self:getStr(7, true)
	end,
	greatmaul = function(self, t)
		return 11 + self:getStr(11, true)
	end,
	staff = function(self, t)
		return 9 + self:getMag(9, true)
	end,
	-- Recomputed in onWear/onTakeoff.
	passives = function(self, t, p)
		local power = util.getval(t.physical, self, t)
		self:talentTemporaryValue(p, 'inc_damage', {
																[DamageType.PHYSICAL] = power})

		-- We can just stick the glove bonus on the actor's combat table
		-- directly. This also means it'll apply to unarmed strikes
		-- properly even if we're wearing a weapon.
		local unarmed = {atk = util.getval(t.unarmed, self, t),}
		self:talentTemporaryValue(p, 'combat', unarmed)

		local type = eutil.get(self:getInven 'MAINHAND', 1, 'subtype')

		if type == 'mace' then
			local power = util.getval(t.mace, self, t)
			self:talentTemporaryValue(p, 'combat_critical_power', power)
			self:talentTemporaryValue(p, 'combat_physcrit', power)
		elseif type == 'greatmaul' then
			self:talentTemporaryValue(p, 'combat_apr', util.getval(t.greatmaul, self, t))
		elseif type == 'staff' then
			local power = util.getval(t.staff, self, t)
			local bonus = {
				[DamageType.NATURE] = power,
				[DamageType.FIRE] = power,}
			self:talentTemporaryValue(p, 'inc_damage', bonus)
			self:talentTemporaryValue(p, 'resists_pen', bonus)
		end
	end,
	recompute_passives = {stats = {stats.STAT_STR, stats.STAT_MAG,},},
	info = function(self, t)
		return ([[Your mastery over density and weight allows it to tune the weight and grave power of all stone it commands, increasing all physical damage done by %d%%.

Also gives an extra bonus to melee combat depending on the type of weapon used:
Gloves/Unarmed: Accuracy increased by %d. (Scales with strength)
Mace: Increases critical chance and multiplier by %d%%. (Scales with strength)
Greatmaul: Increases armor penetration by %d. (Scales with strength)
Staves: Increase all nature/fire damage done nature/fire penetration by %d%%. (Scales with magic)]])
			:format(util.getval(t.physical, self, t),
							util.getval(t.unarmed, self, t),
							util.getval(t.mace, self, t),
							util.getval(t.greatmaul, self, t),
							util.getval(t.staff, self, t))
	end,}

newTalent {
	name = 'Primordial Stone',
	type = {'elemental/earth-metamorphosis', 2,},
	require = make_require(2),
	points = 5,
	essence = 15,
	cooldown = 26,
	tactical = {ESCAPE = 2,},
	range = function(self, t) return math.ceil(self:combatTalentScale(t, 2, 6)) end,
	duration = 3,
	damage = function(self, t)
		return self:combatTalentSpellDamage(t, 80, 300)
	end,
	target = function(self, t)
		return {
			type = 'beam', talent = t, selffire = false,
			requires_knowledge = true,
			pass_terrain = function(terrain, x, y)
				return not terrain.does_block_move or terrain.dig
			end,
			range = util.getval(t.range, self, t),}
	end,
	action = function(self, t)
		local _
		local sx, sy = self.x, self.y

		local tg = self:getTalentTarget(t)
		local x, y = self:getTarget(tg)
		if not x or not y then return end
		_, x, y = self:canProject(tg, x, y)

		if not self:canMove(x, y) then
			game.logPlayer(self, 'You cannot move there.')
			return
		end

		game.level.map:particleEmitter(
			x, y, math.max(math.abs(x - sx), math.abs(y - sy)),
			'earth_beam', {tx = sx - x, ty = sy - y})

		tg.filter = function(tx, ty)
			if tx == x and ty == y then return end
			local terrain = game.level.map(tx, ty, map.TERRAIN)
			return not terrain.does_block_move and not terrain.active_terrain
		end

		local targets = {}
		local projector = function(x, y, tg, self)
			table.insert(targets, {x = x, y = y,})
		end
		self:project(tg, x, y, projector)

		local damage = self:spellCrit(util.getval(t.damage, self, t))
		local duration = util.getval(t.duration, self, t)
		for _, target in pairs(targets) do
			local x, y = target.x, target.y

			local oe = game.level.map(x, y, Map.TERRAIN)
			if oe and oe.special then return end
			if oe and oe:attr('temporary') and not oe.active_terrain then return end

			local e = active_terrain.new {
				terrain = game.zone:makeEntityByName(game.level, 'terrain', 'WALL'),
				name = self.name:capitalize()..'\'s Primordial Stone',
				temporary = duration + 1,
				x = x, y = y,
				canAct = false,
				dig = function(src, x, y, self)
					self:removeLevel()
				end,
				nicer_tiles = true,
				summoner_gain_exp = true,
				summoner = self,}

			DamageType:get(DamageType.PHYSICAL).projector(
				self, x, y, DamageType.PHYSICAL, damage)

			local actor = game.level.map(x, y, map.ACTOR)
			if actor then
				actor:setEffect('EFF_PRIMORDIAL_PETRIFICATION', 10, {apply_power = self:combatSpellpower(),})
			end
		end

		-- Nicer tile the walls.
		for _, target in pairs(targets) do
			game.nicer_tiles:updateAround(game.level, target.x, target.y)
		end

		self:move(x, y, true)
		game:playSoundNear(self, 'talents/earth')
		return true
	end,
	info = function(self, t)
		local damage = util.getval(t.damage, self, t)
		return ([[Briefly becomes the very essence of earth, quickly sliding up to %d tiles away. This can move you through diggable walls, but the exit tile must be free. All tiles passed, except for the exit tile, become encased in stone for %d turns.
Targets passed over take %d physical damage and become petrified until the walls dissipate. Even then they remain petrified for 1 more turn for every 33%% of hp missing.
Damage and pertification chance scales with spellpower.]])
			:format(
				util.getval(t.range, self, t),
				util.getval(t.duration, self, t),
				Talents.damDesc(self, DamageType.PHYSICAL, util.getval(t.damage, self, t)))
	end,}

newTalent {
	name = 'Impregnable Armour',
	type = {'elemental/earth-metamorphosis', 3,},
	require = make_require(3),
	points = 5,
	mode = 'passive',
	resist = function(self, t)
		return self:combatTalentScale(t, 0.2, 0.6) * (0.5 + self:getStr(0.5, true))
	end,
	-- Recomputed in onWear/onTakeoff.
	passives = function(self, t, p)
		self:talentTemporaryValue(p, 'equip_only_armour_training', 1)

		local armor = eutil.get(self:getInven('BODY'), 1)
		if armor and armor.subtype == 'massive' then
			local mult = util.getval(t.resist, self, t)
			local resists = {}
			for type, amount in pairs(eutil.get(armor, 'wielder', 'resists') or {}) do
				if type ~= DamageType.PHYSICAL and type ~= DamageType.MIND then
					resists[type] = mult * amount
				end
			end
			self:talentTemporaryValue(p, 'resists', resists)
		end
	end,
	recompute_passives = {stats = {stats.STAT_STR,},},
	info = function(self, t)
		return ([[Lets you wear massive armour. Also amplifies any elemental (not physical or mind) resistance bonus on a massive armor by %d%% (scaling with strength).

(Bonus will not show up on the armour itself.)]])
			:format(util.getval(t.resist, self, t) * 100)
	end,}
