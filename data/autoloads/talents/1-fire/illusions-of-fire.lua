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

newTalentType {
	type = 'elemental/illusions-of-fire',
	name = 'Illusions of Fire',
	description = 'The dancing of flames can birth powerful illusions.',
	allow_random = true,}

local make_require = function(tier)
	return {
		stat = {wil = function(level) return 2 + tier * 8 + level * 2 end,},
		level = function(level) return -5 + tier * 4 + level end,}
	end

local burst_chain
burst_chain = function (self, target, action, chance, already_hit)
	already_hit = already_hit or {}
	if already_hit[target] then return end
	already_hit[target] = true
	local burst = rng.percent(chance)
	action(self, target, burst)
	if burst then self:project(
			{type = 'ball', range = math.huge, radius = 1, friendlyfire = false,},
			target.x, target.y,
			function(x, y)
				local actor = game.level.map(x, y, Map.ACTOR)
				if not actor then return end
				burst_chain(self, actor, action, chance, already_hit)
				end)
		end
	end

newTalent {
	name = 'Mindflare',
	type = {'elemental/illusions-of-fire', 1,},
	require = make_require(1),
	points = 5,
	heat = -35,
	cooldown = 9,
	range = 6,
	radius = 0,
	target = function(self, t)
		return {type = 'ball', talent = t, friendlyfire = false,
			radius = get(t.radius, self, t),
			range = get(t.range, self, t),}
		end,
	mind_damage = function(self, t) return self:scale {low = 20, high = 120, t, 'mind', after = 'damage',} end,
	fire_damage = function(self, t) return self:scale {low = 20, high = 70, t, 'mind', after = 'damage',} end,
	talent_count = function(self, t) return self:scale {low = 3, high = 4.5, t, after = 'floor',} end,
	duration = function(self, t) return self:scale {low = 4, high = 8, t, after = 'floor',} end,
	action = function(self, t)
		local _
		local tg = get(t.target, self, t)
		local x, y = self:getTarget(tg)
		if not x or not y then return end
		_, x, y = self:canProject(tg, x, y)
		local actor = game.level.map(x, y, Map.ACTOR)
		if not actor then return end

		local mind_damage = self:mindCrit(self:heatScale(get(t.mind_damage, self, t)))
		local fire_damage = self:heatScale(get(t.fire_damage, self, t)) -- crits on actual application every turn.
		local duration = get(t.duration, self, t)
		local talent_count = get(t.talent_count, self, t)
		local burst_chance = 0
		if self:knowTalent 'T_ELEMENTAL_MASS_HYSTERIA' then
			burst_chance = self:callTalent('T_ELEMENTAL_MASS_HYSTERIA', 'burst_chance')
			end
		local hit = function(self, target, is_burst)
			self:projectOn(target, 'MIND', mind_damage)
			target:setEffect('EFF_SEARING_VISIONS', duration, {
					src = self,
					talent_count = talent_count,
					fire_damage = fire_damage,})
			local radius = 0.5
			if is_burst then radius = 1.5 end
			game.level.map:particleEmitter(target.x, target.y, radius, 'ball_fire', {radius = radius,})
			game:playSoundNear(target, 'talents/spell_generic')
			end
		burst_chain(self, actor, hit, burst_chance)
		return true
		end,
	info = function(self ,t)
		return ([[Sears the enemy's mind with psychic visions of fire, dealing %d <%d> #SLATE#[*, mind, crit]#LAST# #YELLOW#mind#LAST# damage, as your will invades theirs.
The vivid psychic link of flames is then imprinted upon %d #SLATE#[*]#LAST# random talents for %d #SLATE#[*]#LAST# turns. If the enemy uses them during that duration, they receive a backlash of psychic fire, taking %d <%d> #SLATE#[*, mind, crit]#LAST# #LIGHT_RED#fire#LAST# damage.
#SLATE#Numbers shown are for 100%% heat, numbers in <brackets> are the actual amounts based on your current heat.]])
			:format(
				self:damDesc('MIND', self:heatScale(get(t.mind_damage, self, t), 100)),
				self:damDesc('MIND', self:heatScale(get(t.mind_damage, self, t))),
				get(t.talent_count, self, t),
				get(t.duration, self, t),
				self:damDesc('FIRE', self:heatScale(get(t.fire_damage, self, t), 100)),
				self:damDesc('FIRE', self:heatScale(get(t.fire_damage, self, t))))
		end,}

newTalent {
	name = 'Third Degree',
	type = {'elemental/illusions-of-fire', 1,},
	require = make_require(2),
	points = 5,
	mode = 'passive',
	damage_percent = function(self, t) return self:scale {low = 10, high = 26, t, 'wil', synergy = 0.25,} end,
	duration = 3,
	callbackOnDealDamage = function(self, t, val, target, dead, death_note)
		if not death_note or death_note.damtype ~= 'FIRE' then return end
		if not target or not target.setEffect then return end
		target:setEffect('EFF_THIRD_DEGREE', 3, {
				src = self, power = val * 0.01 * get(t.damage_percent, self, t),})
		end,
	info = function(self, t)
		return ([[Your fires keep burning in the mind of your victims, long after they have died down.
%d%% #SLATE#[*, wil, crit]#LAST# of any #LIGHT_RED#fire#LAST# damage you deal keeps burning your enemies for %d more turns, dealing #YELLOW#mind#LAST# damage.
The amount of damage will halve each turn, but being hit by #LIGHT_RED#fire#LAST# damage will bring it back up to the original amount. This will not affect the duration.]])
			:format(
				get(t.damage_percent, self, t),
				get(t.duration, self, t))
		end,}

newTalent {
	name = 'Burnout',
	type = {'elemental/illusions-of-fire', 3,},
	require = make_require(3),
	points = 5,
	heat = -35,
	cooldown = 25,
	range = 6,
	radius = 0,
	target = function(self, t)
		return {type = 'ball', talent = t, friendlyfire = false,
			radius = get(t.radius, self, t),
			range = get(t.range, self, t),}
		end,
	damage_percent = function(self, t) return self:scale {low = 60, high = 80, t, 'wil',} end,
	elite_mult = 0.67,
	damage_cap = function(self, t) return self:scale {low = 150, high = 350, t, 'wil', after = 'damage',} end,
	action = function(self, t)
		local _
		local tg = get(t.target, self, t)
		local x, y = self:getTarget(tg)
		if not x or not y then return end
		_, x, y = self:canProject(tg, x, y)
		local actor = game.level.map(x, y, Map.ACTOR)
		if not actor then return end

		local damage_percent = get(t.damage_percent, self, t)
		local div = 100 + self:combatGetDamageIncrease('FIRE', straight)
		if div == 0 then div = 0.01 end
		damage_percent = damage_percent * 100 / div
		local elite_mult = get(t.elite_mult, self, t)
		local damage_cap = self:mindCrit(self:heatScale(get(t.damage_cap, self, t)))
		local burst_chance = 0
		if self:knowTalent 'T_ELEMENTAL_MASS_HYSTERIA' then
			burst_chance = self:callTalent('T_ELEMENTAL_MASS_HYSTERIA', 'burst_chance')
			end
		local hit = function(self, target, is_burst)
			if target.life <= 0 then return end
			local percent = damage_percent * 0.01
			if target.rank >= 3 then percent = percent * elite_mult end
			self:projectOn(target, 'FIRE', math.min(target.life * percent, damage_cap))
			local radius = 0.5
			if is_burst then radius = 1.5 end
			game.level.map:particleEmitter(target.x, target.y, radius, 'ball_fire', {radius = radius,})
			game:playSoundNear(target, 'talents/spell_generic')
			end
		burst_chain(self, actor, hit, burst_chance)
		return true
		end,
	info = function(self, t)
		return ([[Attempts to conflagrate the target mind outright. Hit the target for #LIGHT_RED#fire#LAST# damage equal to %d%% (%d%% if elite or greater) #SLATE#[*, wil]#LAST# of their current life, with a maximum of %d <%d> #SLATE#[*, wil, crit]#LAST#.
#SLATE#Numbers shown are for 100%% heat, numbers in <brackets> are the actual amounts based on your current heat.]])
			:format(
				get(t.damage_percent, self, t),
				get(t.elite_mult, self, t) * get(t.damage_percent, self, t),
				self:damDesc('FIRE', self:heatScale(get(t.damage_cap, self, t), 100)),
				self:damDesc('FIRE', self:heatScale(get(t.damage_cap, self, t))))
		end,}

newTalent {
	name = 'Mass Hysteria', short_name = 'ELEMENTAL_MASS_HYSTERIA',
	type = {'elemental/illusions-of-fire', 4,},
	require = make_require(4),
	points = 5,
	mode = 'passive',
	damage_div = function(self, t) return self:scale {low = 100, high = 60, limit = 20, t, 'mind',} end,
	duration = 5,
	reduction = function(self, t) return self:scale {low = 2, high = 16, t, 'u.mind',} end,
	reduction_max = function(self, t) return self:scale {low = 20, high = 60, t, 'mind',} end,
	burst_chance = function(self, t) return self:scale {low = 30, high = 70, t, 'mind',} end,
	callbackOnDealDamage = function(self, t, val, target, dead, death_note)
		if not death_note or death_note.damtype ~= 'FIRE' then return end
		if not target or not target.setEffect then return end
		local count = math.floor(val / get(t.damage_div, self, t))
		if count <= 0 then return end
		target:setEffect('EFF_BURNING_HYSTERIA', get(t.duration, self, t), {
				reduction = get(t.reduction, self, t),
				reduction_max = get(t.reduction_max, self, t),})
		end,
	info = function(self, t)
		return ([[Your illusory flames become real to the point of being contagious, just like real fire.
Every %d #SLATE#[*, mind]#LAST# points of #LIGHT_RED#fire#LAST# damage dealt to an enemy reduces their mindpower and mind save by %d #SLATE#[*, mind]#LAST# for %d turns, stacking up to a maximum of %d #SLATE#[*, mind]#LAST#.

Additionally, Mindflare and Burnout have a %d%% #SLATE#[*, mind]#LAST# chance to burst in radius of 1. This can chain, but no target is hit more than once per action.]])
			:format(
				get(t.damage_div, self, t),
				get(t.reduction, self, t),
				get(t.duration, self, t),
				get(t.reduction_max, self, t),
				get(t.burst_chance, self, t))
		end,}
