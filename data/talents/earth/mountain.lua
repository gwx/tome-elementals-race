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


local stats = require 'engine.interface.ActorStats'

newTalentType {
	type = 'elemental/mountain',
	name = 'Mountain',
	generic = true,
	description = 'Tanking',}

local make_require = function(tier)
	return {
		stat = {con = function(level) return 2 + tier * 8 + level * 2 end,},
		level = function(level) return -5 + tier * 4 + level end,}
end

newTalent {
	name = 'Jagged Body',
	type = {'elemental/mountain', 1,},
	require = make_require(1),
	points = 5,
	mode = 'passive',
	no_unlearn_last = true,
	callbackOnRest = function(self)
		return self.jaggedbody_regen > 0 and self.jaggedbody < self.max_jaggedbody
	end,
	power = function(self, t)
		return math.floor(
			(1 + (self.max_jaggedbody_mult or 0)) *
				(5 + self:getCon(5, true)) * self:combatTalentLimit(t, 25, 10, 20))
	end,
	reflect = function(self, t) return self:combatTalentScale(t, 0.15, 0.3) end,
	on_learn = function(self, t)
		if self:getTalentLevelRaw(t) == 1 then
			self.jaggedbody = t.power(self, t)
		end
	end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, 'max_jaggedbody', t.power(self, t))
		self:talentTemporaryValue(p, 'jaggedbody_reflect', t.reflect(self, t))
		self:talentTemporaryValue(p, 'jaggedbody_regen_percent', 2)
		self.jaggedbody_regen =
			(self.jaggedbody_regen_flat or 0) +
			self.jaggedbody_regen_percent * 0.01 * self.max_jaggedbody
	end,
	recompute_passives = {stats = {stats.STAT_CON,},},
	info = function(self, t)
		return ('Your earthen body sprouts many sharp, rock-hard protrusions, blocking up to %d damage (scaling with Constitution) of any kind, recharging by 2%% per turn. In additon, %d%% of all physical damage this blocks will be returned to the attacker.')
			:format(t.power(self, t), t.reflect(self, t) * 100)
	end,}

-- TODO: Should only reduced phys/magic crit instead of all, but
-- that's really complicated and this is sufficient for now.
newTalent {
	name = 'Rock Shell',
	type = {'elemental/mountain', 2,},
	require = make_require(2),
	points = 5,
	mode = 'passive',
	crit_reduction = function(self, t)
		return (0.5 + self:getCon(0.5, true)) * self:combatTalentScale(t, 3, 10)
	end,
	damage_reduction = function(self, t)
		return math.min(50, (0.5 + self:getCon(0.5, true)) * self:combatTalentScale(t, 8, 30))
	end,
	armor = function(self, t)
		return (0.5 + self:getCon(0.5, true)) * self:combatTalentScale(t, 8, 20)
	end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, 'combat_armor', t.armor(self, t))
		self:talentTemporaryValue(p, 'ignore_direct_crits', t.crit_reduction(self, t))
	end,
	recompute_passives = {stats = {stats.STAT_CON,},},
	info = function(self, t)
		return ([[Your body is used to powerful blows and the ravages of magic, decreasing the chance to receive a critical strike by %d%%. Any damage that would deal over 30%% of your current Life is reduced by %d%%.
Armor is increased by %d.
At talent level 5, you may avoid mortal damage. For 1 turn all damage which would reduce you below 1 Life is ignored. This effect is regained when you reach full Life.
Critical chance reduction, armor, and damage reduction scale with Constitution.]])
			:format(
				t.crit_reduction(self, t),
				t.damage_reduction(self, t),
				t.armor(self, t))
	end,}

newTalent {
	name = 'Teluric Fist',
	type = {'elemental/mountain', 3,},
	require = make_require(3),
	points = 5,
	essence = 12,
	cooldown = 11,
	range = 1,
	requires_target = true,
	no_energy = 'fake',
	tactical = {ATTACK = {weapon = 2}, ESCAPE = {knockback = 2,},},
	target = function(self, t)
		return {type = 'hit', range = util.getval(t.range, self, t),}
	end,
	tactical = { ATTACK = { PHYSICAL = 1 } },
	damage = function(self, t)
		return 1 + self:combatTalentScale(t, 0, 1) * (0.5 + self:getCon(0.5, true))
	end,
	distance = function(self, t)
		return math.floor(self:combatTalentScale(t, 3, 5))
	end,
	action = function(self, t)
		local tg = t.target(self, t)
		local x, y, target = self:getTarget(tg)
		if not x or not y or not target then return end
		if core.fov.distance(self.x, self.y, x, y) > tg.range then return end

		local enhanced = self:attr('enhanced_teluric_fist')

		if self:attackTarget(target, nil, t.damage(self, t)) then
			if target.dead then return true end
			if (enhanced and rng.percent(25)) or target:canBe('knockback') then
				-- Try to dig out terrain.
				local on_terrain = function(terrain, x, y)
					if terrain and terrain.dig and (enhanced or rng.percent(50)) then
						-- Dig the location.
						local new_name, new_terrain = terrain.dig, nil, false
						if type(terrain.dig) == 'function' then
							new_name, new_terrain = terrain.dig(self, x, y, terrain)
						end
						new_terrain = new_terrain or game.zone.grid_list[new_name]
						if new_terrain then
							game.level.map(x, y, Map.TERRAIN, new_terrain)
							-- Makes trees change, so took it out.
							--game.nicer_tiles:updateAround(game.level, x, y)
						end
						-- Take damage.
						game.logSeen(target, '%s breaks through %s',
												 target.name:capitalize(), terrain.name)
						self:attackTarget(target, DamageType.PHYSICAL, 0.1, true)
					end
				end
				target:knockback(self.x, self.y, t.distance(self, t), nil, on_terrain)
			else
				game.logSeen(target, "%s resists being knocked back!", target.name:capitalize())
			end
		end
		return true
	end,
	info = function(self, t)
		return ([[Hit the target enemy for %d%% damage, knocking it back %d tiles. If the enemy hits a wall during the knockback, there is a 50%% chance to break through it, receiving an additional 10%% extra damage.
Damage increases with Constitution.]])
			:format(t.damage(self, t) * 100, t.distance(self, t))
	end,}

newTalent {
	name = 'Composure',
	type = {'elemental/mountain', 4,},
	require = make_require(4),
	points = 5,
	mode = 'passive',
	life = function(self, t)
		return self:combatTalentScale(t, 30, 80) * (0.5 + self:getCon(0.5, true))
	end,
	-- If we unlearn the last level, passives never gets called.
	on_unlearn = function(self, t, p)
		if self:getTalentLevelRaw(t) == 0 then
			game:onTickEnd(function() self:recomputePassives('T_JAGGED_BODY') end)
		end
	end,
	passives = function(self, t, p)
		local level = self:getTalentLevelRaw(t)
		if level >= 1 then self:talentTemporaryValue(p, 'combat_armor_hardiness', 25) end
		if level >= 2 then
			self:talentTemporaryValue(p, 'stun_immune', 0.25)
			self:talentTemporaryValue(p, 'knockback_immune', 0.25)
		end
		if level >= 3 then self:talentTemporaryValue(p, 'jaggedbody_regen_percent', 2) end
		if level >= 4 then self:talentTemporaryValue(p, 'enhanced_teluric_fist', 1) end
		if level >= 5 then
			self:talentTemporaryValue(p, 'resists', {[DamageType.PHYSICAL] = 10,})
		end
		self:talentTemporaryValue(p, 'max_life', t.life(self, t))
		self:recomputePassives('T_JAGGED_BODY')
	end,
	recompute_passives = {stats = {stats.STAT_CON,},},
	info = function(self, t)
		return ([[Change the material composition of your body, increasing max life by %d and conferring an additional benefit for each talent point:
1 Point:  Increases armor hardiness by 25%%.
2 Points: Increases Stun and Knockback resistance by 25%%.
3 Points: Increases Jagged Body shield regeneration by an extra 2%%.
4 Points: Teluric Fist's breakthrough chance is now 100%% and will ignore target's knockback resistance 25%% of the time.
5 Points: Physical resistance raised by 10%%.]])
			:format(t.life(self, t))
	end,}
