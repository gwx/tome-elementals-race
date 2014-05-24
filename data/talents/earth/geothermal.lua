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
local active_terrain = require 'elementals-race.active-terrain'
local grid = require 'mod.class.Grid'
local stats = require 'engine.interface.ActorStats'
local object = require 'mod.class.Object'

newTalentType {
	type = 'elemental/geothermal',
	name = 'Geothermal',
	description = 'Burning Earth',}

local make_require = function(tier)
	return {
		stat = {mag = function(level) return 2 + tier * 8 + level * 2 end,},
		level = function(level) return -5 + tier * 4 + level end,}
end

newTalent {
	name = 'Rock Mortar',
	type = {'elemental/geothermal', 1,},
	require = make_require(1),
	points = 5,
	essence = 5,
	cooldown = 3,
	tactical = {ATTACKAREA = 2,},
	range = 4, radius = 1,
	damage = function(self, t)
		return self:combatTalentSpellDamage(t, 15, 180)
	end,
	reflect = function(self, t)
		return self:combatTalentScale(t, 0.03, 0.1)
	end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, 'jaggedbody_reflect', util.getval(t.reflect, self, t))
	end,
	target = function(self, t)
		return {
			type = 'ball', talent = t,
			range = util.getval(t.range, self, t),
			radius = util.getval(t.radius, self, t),}
	end,
	action = function(self, t)
		local _
		local tg = self:getTalentTarget(t)
		local x, y = self:getTarget(tg)
		if not x or not y then return end
		_, _, _, x, y = self:canProject(tg, x, y)

		local dam = self:spellCrit(util.getval(t.damage, self, t))
		local projector = function(x, y, tg, self)
			DamageType:get(DamageType.PHYSICAL).projector(
				self, x, y, DamageType.PHYSICAL, dam)
			DamageType:get(DamageType.FIRE).projector(
				self, x, y, DamageType.FIRE, dam)
		end
		self:project(tg, x, y, projector)

		game.level.map:particleEmitter(x, y, tg.radius, "ball_earth", {radius = tg.radius,})
		game:playSoundNear(self, 'talents/fire')
		return true
	end,
	info = function(self, t)
		local damage = util.getval(t.damage, self, t)
		return ([[Fires a rock mortar at the target, dealing %d physical and %d fire damage in radius %d.
Also, Jagged Body returns %d%% more damage.
Damage increases with spellpower.]])
			:format(
				Talents.damDesc(self, DamageType.PHYSICAL, damage),
				Talents.damDesc(self, DamageType.FIRE, damage),
				util.getval(t.radius, self, t),
				util.getval(t.reflect, self, t) * 100)
	end,}

newTalent {
	name = 'Insulation',
	type = {'elemental/geothermal', 2,},
	require = make_require(2),
	points = 5,
	mode = 'passive',
	resist = function(self, t)
		return self:combatTalentScale(t, 3, 10)
	end,
	conversion = function(self, t)
		return self:combatTalentScale(t, 25, 60) * (0.5 + self:getMag(0.5, true))
	end,
	jagged = function(self, t)
		return self:combatTalentScale(t, 0.1, 0.35)
	end,
	-- If we unlearn the last level, passives never gets called.
	on_unlearn = function(self, t, p)
		if self:getTalentLevelRaw(t) == 0 then
			game:onTickEnd(function() self:recomputePassives('T_JAGGED_BODY') end)
		end
	end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, 'max_jaggedbody_mult', util.getval(t.jagged, self, t))
		self:recomputePassives('T_JAGGED_BODY')
		local resists = {
			[DamageType.PHYSICAL] = util.getval(t.resist, self, t),
			-- XXX Add these in so that conversion resists are properly displayed even if they're 0.
			[DamageType.FIRE] = 0.000001,
			[DamageType.COLD] = 0.000001,}
		self:talentTemporaryValue(p, 'resists', resists)
		local conversion = util.getval(t.conversion, self, t)
		resists = {
			[DamageType.FIRE] = {[DamageType.PHYSICAL] = conversion,},
			[DamageType.COLD] = {[DamageType.PHYSICAL] = conversion,},}
		self:talentTemporaryValue(p, 'conversion_resists', resists)
	end,
	recompute_passives = {stats = {stats.STAT_MAG,},},
	info = function(self, t)
		return ([[Your hard outer shell does good to keep the gooey candy center warm.
Increases physical resistance by %d%% and increases the maximum capacity of Jagged Body by %d%%.
Also, %d%% (scaling with magic) of your physical resistance is added to your to fire and cold resistance.]])
			:format(
				util.getval(t.resist, self, t),
				util.getval(t.jagged, self, t) * 100,
				util.getval(t.conversion, self, t))
	end,}

newTalent {
	name = 'Pyroclastic Burst',
	type = {'elemental/geothermal', 3,},
	require = make_require(3),
	points = 5,
	essence = 20,
	cooldown = 17,
	tactical = {ATTACKAREA = 2, DISABLE = {PIN = 1},},
	range = 0, radius = 1,
	damage = function(self, t)
		return self:combatTalentSpellDamage(t, 10, 70)
	end,
	restore = function(self, t)
		return self:combatTalentScale(t, 0.25, 0.6)
	end,
	regen = function(self, t)
		return self:combatTalentScale(t, 3, 8) * (0.5 + self:getMag(0.5, true))
	end,
	duration = function(self, t)
		return math.ceil(self:getTalentLevel(t) * 0.5)
	end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, 'jaggedbody_regen_flat', util.getval(t.regen, self, t))
		self:recomputePassives('T_JAGGED_BODY')
	end,
	recompute_passives = {stats = {stats.STAT_MAG,},},
	-- If we unlearn the last level, passives never gets called.
	on_unlearn = function(self, t, p)
		if self:getTalentLevelRaw(t) == 0 then
			game:onTickEnd(function() self:recomputePassives('T_JAGGED_BODY') end)
		end
	end,
	target = function(self, t)
		return {
			type = 'ball', talent = t, selffire = false,
			range = util.getval(t.range, self, t),
			radius = util.getval(t.radius, self, t),}
	end,
	action = function(self, t)
		local restore = util.getval(t.restore, self, t)
		self:incJaggedbody(restore * (self:getMaxJaggedbody() - self:getJaggedbody()))
		local tg = util.getval(t.target, self, t)
		local damage = self:spellCrit(util.getval(t.damage, self, t))
		local duration = util.getval(t.duration, self, t)
		local projector = function(x, y, tg, self)
			local target = game.level.map(x, y, Map.ACTOR)
			if not target then return end
			target:setEffect('EFF_PYROCLASTIC_PIN', duration, {
												 src = self,
												 apply_power = self:combatSpellpower(),
												 damage = damage,})
		end
		self:project(tg, self.x, self.y, projector)

		game.level.map:particleEmitter(x, y, tg.radius, "ball_fire", {radius = tg.radius,})
		game:playSoundNear(self, 'talents/fire')
		return true
	end,
	info = function(self, t)
		local restore = util.getval(t.restore, self, t)
		return ([[Bouts of molten rage explode from within, solidifying on both you and the immediate surroundings.
Instantly regenerates %d%% of your missing Jagged Body shield and pins all adjacent for %d turns. Each turn, those pinned take %d fire damage (scaling with spellpower).
Passively increases jagged body regeneration by %.1f points per turn (scaling with magic).
Total jagged body restoration, including that from spent essence, will be %d.]])
			:format(
				restore * 100,
				util.getval(t.duration, self, t),
				Talents.damDesc(self, DamageType.FIRE, util.getval(t.damage, self, t)),
				util.getval(t.regen, self, t),
				restore * (self:getMaxJaggedbody() - self:getJaggedbody()) +
					self:essenceCost(util.getval(t.essence, self, t)))
	end,}
