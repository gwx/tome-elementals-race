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
local ACTOR = map.ACTOR

newTalentType {
	type = 'elemental/cliffside',
	name = 'Cliffside',
	--generic = true,
	description = 'Shields.',
	allow_random = true,}

local make_require = function(tier)
	return {
		stat = {str = function(level) return 2 + tier * 8 + level * 2 end,},
		level = function(level) return -5 + tier * 4 + level end,}
end

newTalent {
	name = 'Pestle',
	type = {'elemental/cliffside', 1,},
	require = make_require(1),
	points = 5,
	mode = 'passive',
	damage = function(self, t) return self:combatTalentScale(t, 1, 1.2) end,
	chance = function(self, t) return self:combatTalentScale(t, 35, 60) end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, 'block_always_counterstrike', 1)
	end,
	info = function(self, t)
		return ([[Every time you make a melee attack with your weapon, you have a %d%% chance to bash with your shield for %d%% damage. If this attack is a counterstrike, the bash is guaranteed and is a crushing blow (deals %d%% (half of your crit. power) more damage if it would be enough to bring the target to 0 or less life).
Allows counterstrikes after incomplete blocks.]])
			:format(util.getval(t.chance, self, t),
							util.getval(t.damage, self, t) * 100,
							25 + (self.combat_critical_power or 0) * 0.5)
	end,}

newTalent {
	name = 'Shield Stomper',
	type = {'elemental/cliffside', 2,},
	require = make_require(2),
	points = 5,
	essence = 10,
	cooldown = 14,
	range = 1,
	requires_target = true,
	tactical = {ATTACK = 2,},
	target = function(self, t)
		return {type = 'hit', range = util.getval(t.range, self, t),}
	end,
	tactical = { ATTACK = { PHYSICAL = 1 } },
	damage = function(self, t) return self:combatTalentScale(t, 1, 1.5) end,
	constrict = function(self, t) return math.floor(self:combatTalentScale(t, 2, 4)) end,
	on_pre_use = function(self, t, silent)
		if not self:hasShield() then
			if not silent then
				game.logPlayer(self, 'You must be wielding a shield to use this talent.')
			end
			return false
		end
		return true
	end,
	action = function(self, t)
		local tg = util.getval(t.target, self, t)
		local x, y, actor = self:getTarget(tg)
		if not x or not y or not actor then return end
		if core.fov.distance(self.x, self.y, x, y) > tg.range then return end

		local combat = self:hasShield().special_combat
		local damage = util.getval(t.damage, self, t) * combat.block
		local speed, hit = self:attackTargetWith(actor, combat, nil, nil, damage)

		if hit and self.turn_procs.counterstrike_activated and actor:canBe('pin') then
			actor:setEffect('EFF_CONSTRICTED', util.getval(t.constrict, self, t), {
												src = self,
												apply_power = self:combatPhysicalpower(),})
		end
		return true
	end,
	info = function(self, t)
		return ([[Buries the target enemy under the sheer power of your shield, dealing %d%% of the shield's block value as physical damage. If this is a counterstrike, the target is constricted for %d turns as well.]])
			:format(util.getval(t.damage, self, t) * 100,
							util.getval(t.constrict, self, t))
	end,}
