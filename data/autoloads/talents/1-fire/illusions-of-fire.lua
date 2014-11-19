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

		local mind_damage = self:mindCrit(self:heatScale(get(t.mind_damage, self, t)))
		local fire_damage = self:heatScale(get(t.fire_damage, self, t)) -- crits on actual application every turn.
		local duration = get(t.duration, self, t)
		local talent_count = get(t.talent_count, self, t)
		self:project(tg, x, y, function(x, y)
				local actor = game.level.map(x, y, Map.ACTOR)
				if not actor then return end
				self:projectOn(actor, 'MIND', mind_damage)
				actor:setEffect('EFF_SEARING_VISIONS', duration, {
						src = self,
						talent_count = talent_count,
						fire_damage = fire_damage,})
				end)

		game.level.map:particleEmitter(x, y, tg.radius + 0.5, 'ball_fire', {radius = tg.radius + 0.5,})
		game:playSoundNear({x = x, y = y,}, 'talents/spell_generic')
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
