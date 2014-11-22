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
	type = 'elemental/chaos',
	name = 'Chaos',
	generic = true,
	description = 'A true flame cannot be controlled.',
	allow_random = true,}

local make_require = function(tier)
	return {
		stat = {mag = function(level) return 2 + tier * 8 + level * 2 end,},
		level = function(level) return -5 + tier * 4 + level end,}
	end

newTalent {
	name = 'Backburner',
	type = {'elemental/chaos', 1,},
	mode = 'sustained',
	points = 5,
	cooldown = 25,
	require = make_require(1),
	heat_inc = function(self, t) return self:scale {low = 20, high = 40, t} end,
	activate = function(self, t) return {current_heat = 0, last_heat = 0} end,
	deactivate = function(self, t) return true end,
	speed = 'spell',
	callbackOnIncHeat = function(self, t, heat)
		if self:attr '__inhibit_backburner' then return end
		if heat.value < 0 then return end
		heat.value = (100 + get(t.heat_inc, self, t)) * heat.value * 0.005
		local p = self:isTalentActive(t.id)
		p.current_heat = p.current_heat + heat.value
		return true end,
	callbackOnActBase = function(self, t)
		local p = self:isTalentActive(t.id)

		self:attr('__inhibit_backburner', 1)
		self:incHeat(p.last_heat)
		self:attr('__inhibit_backburner', -1)

		p.last_heat = p.current_heat
		p.current_heat = 0
		end,
	info = function(self, t)
		return ([[Your flames burn hotter, but take longer to set in.
While this talent is active you generate %d%% #SLATE#[*]#LAST# more #FF6100#heat#LAST# from all sources, but smeared over 2 turns.]]):format(get(t.heat_inc, self, t))
		end,}

newTalent {
	name = 'Mindless Fires',
	type = {'elemental/chaos', 2,},
	points = 5,
	cooldown = 25,
	require = make_require(2),
	heat_per = 20,
	damage_penalty = function(self, t) return self:scale {low = 84, high = 60, t, 'dex',} end,
	damaged_mult = function(self, t) return self:scale {low = 250, high = 180, limit = 100, t, 'dex',} end,
	max_count = 3,
	recovery_range = 3,
	recovery_heat = 20,
	recovery_cooldown = 2,
	speed = 'spell',
	target = function(self, t)
		return {type = 'ball', range = 0, radius = 1, talent = t,}
		end,
	on_pre_use = function(self, t, silent)
		if not game.level then return true end
		if not util.findFreeGrid(self.x, self.y, 1, true, {[Map.ACTOR] = true,}) then
			if not silent then game.logPlayer(self, 'No free space to summon.') end
			return
			end
		if self:getHeat() < get(t.heat_per, self, t) then
			if not silent then game.logPlayer(self, 'Not enough heat.') end
			return
			end
		return true
		end,
	action = function(self, t)
		local NPC = require 'mod.class.NPC'
		local _

		-- First, clear existing summons.
		for _, fire in pairs(self.mindless_fires or {}) do fire:die() end

		-- Find valid spaces.
		local tg = get(t.target, self, t)
		local spaces = {}
		self:project(tg, self.x, self.y, function(x, y)
				if game.level.map(x, y, Map.ACTOR) then return end
				if not self:canMove(x, y, true) then return end
				table.insert(spaces, {x, y,})
				end)

		local heat_per = get(t.heat_per, self, t)
		local count = math.min(self:getHeat() / heat_per, get(t.max_count, self, t))
		count = math.min(#spaces, count)
		if count == 0 then return end

		self:incHeat(-heat_per * count)

		table.shuffle(spaces)

		self.mindless_fires = {}
		local recovery_range = get(t.recovery_range, self, t)
		local recovery_heat = get(t.recovery_heat, self, t)
		local recovery_cooldown = get(t.recovery_cooldown, self, t)
		local damage_penalty = -get(t.damage_penalty, self, t)
		local damaged_mult = get(t.damaged_mult, self, t) * 0.01
		local talents
		if self:knowTalent 'T_INSCRIBED_FLAMES' then
			local ins = self:getTalentFromId 'T_INSCRIBED_FLAMES'
			talents = table.clone(self.inscribed_flames)

			-- Strip out extra talents we've selected if the talent has since leveled down.
			local pool_size = get(ins.talents_pool, self, ins)
			while #talents > pool_size do table.remove(talents) end

			talents.known = math.min(#talents, get(ins.talents_known, self, ins))
			talents.level = get(ins.talent_level, self, ins)
			end
		for i = 1, count do
			local x, y = unpack(spaces[i])
			local e = NPC.new(self:clone {
				name = 'mindless fire', summoner = self, summoner_gain_exp = true,
				color = colors.LIGHT_RED, shader = 'shadow_simulacrum',
				shader_args = {color = {1.0, 0.7, 0.2,}, base = 0.2, time_factor = 4000,},
				desc = 'A burning, mindless flame.',
				body = {INVEN = 10, MAINHAND = 1, BODY = 1,},

				ai = 'summoned', ai_real = 'dumb_talented_simple',
				ai_state = {ai_move = 'move_complex', talent_in = 2, ally_compassion = 10,},

				on_cremation = function(self, src)
					self.heat = self.max_heat
					return false end,

				recovery_range = recovery_range,
				recovery_heat = recovery_heat,
				recovery_cooldown = recovery_cooldown,
				damaged_mult = damaged_mult,})
			self:setupSummon(e)
			e:removeAllMOs()
			e.make_escort = nil
			e.on_added_to_level = nil

			e.energy.value = 0
			e.player = nil
			e.forceLevelup = function() end
			e.die = nil
			e.on_die = function(self, src, death_note)
				if not self.summoner or not self.summoner.x or not self.summoner.y then return end
				if core.fov.distance(self.x, self.y, self.summoner.x, self.summoner.y) <= self.recovery_range then
					self.summoner:incHeat(self.recovery_heat * self.heat / 100)
					local summoner = self.summoner
					local recovery_cooldown = -self.recovery_cooldown
					game:onTickEnd(function() summoner:alterTalentCoolingdown('T_MINDLESS_FIRES', recovery_cooldown) end)
					end
				end
			e.on_acquire_target = nil
			e.seen_by = nil
			e.can_talk = nil
			e.puuid = nil
			e.on_takehit = nil
			e.exp_worth = 0
			e.no_inventory_access = true
			e.clone_on_hit = nil

			local tids = table.keys(e.talents)
			for i, tid in ipairs(tids) do
				e:unlearnTalent(tid, e:getTalentLevelRaw(tid))
				end
			-- Inscribed Flames
			if talents then
				table.shuffle(talents)
				for i = 1, talents.known do
					local talent_id = talents[i]
					local talent = self:getTalentFromId(talent_id)
					e:learnTalent(talent_id, true, 1)
					e:setTalentTypeMastery(talent.type[1], talents.level)
					end
				end

			e.remove_from_party_on_death = true
			e.takeHit = function(self, dam, src, death_note)
				return mod.class.NPC.takeHit(self, dam * self.damaged_mult, src, death_note)
				end
			e.all_damage_convert = 'FIRE'
			e.all_damage_convert_percent = 50

			table.set(e, 'inc_damage', 'all', damage_penalty + (table.get(e.inc_damage, 'all') or 0))

			game.zone:addEntity(game.level, e, 'actor', x, y)
			game.level.map:particleEmitter(x, y, 1, 'summon')
			table.insert(self.mindless_fires, e)

			if game.party:hasMember(self) then
				game.party:addMember(e, {
					control = 'no',
					type = 'mindless fire',
					title = 'Mindless Fire',})
				end
			game:playSoundNear(e, 'talents/spell_generic2')
			end

		return true
		end,
	info = function(self, t)
		return ([[A spark alone suffices to start more fires. Suffices to say, a living spark like yours can bring forth even more devastating things.
Creates up to %d duplicates of your fiery being adjacent to yourself, each costing %d heat.
Each duplicate is uncontrollable and attacks in blind rage, with no use of your talents. They have -%d%% #SLATE#[*, dex]#LAST# all damage modifier and take %d%% #SLATE#[*, dex]#LAST# as much damage from enemies. 50%% of their damage dealt is converted to #LIGHT_RED#fire#LAST# damage.
Duplicates are able to generate #FF6100#heat#LAST#.

Their life force is tethered to you - if they remain within range %d of you when dying, you regain up #FF6100#%d heat#LAST# based on their current heat and the cooldown of this talent is reduced by %d.
Activating this talent will instantly extinguish all already active duplicates.]])
			:format(
				get(t.max_count, self, t),
				get(t.heat_per, self, t),
				get(t.damage_penalty, self, t),
				get(t.damaged_mult, self, t),
				get(t.recovery_range, self, t),
				self:heatGain(get(t.heat_per, self, t)),
				get(t.recovery_cooldown, self, t))
		end,}

newTalent {
	name = 'Inscribed Flames',
	type = {'elemental/chaos', 3,},
	points = 5,
	require = make_require(3),
	no_energy = true,
	talents_known = function(self, t) return self:scale {low = 1, high = 1.8, t, after = 'floor',} end,
	talents_pool = function(self, t) return self:scale {low = 1, high = 5, t, curve = 1, after = 'floor',} end,
	talent_level = function(self, t) return self:scale {low = 1, high = 2.5, t, 'dex',} end,
	on_pre_use = function(self, t, silent)
		self.inscribed_flames = self.inscribed_flames or {}
		if get(t.talents_pool, self, t) <= #self.inscribed_flames then
			if not silent then game.logPlayer(self, 'You have no talent selections left.') end
			return end
		return true
		end,
	talent_filter = function(self, t)
		local selected = table.reverse(self.inscribed_flames)
		return function(talent)
			if not self:knowTalent(talent.id) then return false end
			if selected[talent.id] then return false end
			if talent.innate then return false end
			if talent.is_inscription then return false end
			if talent.type[1] == 'elemental/chaos' then return false end
			if talent.mode ~= 'activated' then return false end
			if talent.hide then return false end
			return true
			end
		end,
	action = function(self, t)
		self.inscribed_flames = self.inscribed_flames or {}
		local talent_id = self:talentDialog(grayswandir.class.SelectTalentDialog.new {
				actor = self,
				filter = get(t.talent_filter, self, t),
				message = 'Select a new talent for your Mindless Fires.',
				title = 'Mindless Fires',})
		if not talent_id then return end
		table.insert(self.inscribed_flames, talent_id)
		end,
	info = function(self, t)
		local pool_size = get(t.talents_pool, self, t)

		local talents = ''
		self.inscribed_flames = self.inscribed_flames or {}
		if #self.inscribed_flames > 0 then
			talents = {'\n\nSelected Talents:',}
			for index, id in ipairs(self.inscribed_flames) do
				color = index > pool_size and '#SLATE#' or '#WHITE#'
				local talent = self:getTalentFromId(id)
				table.insert(talents, color..'* '..talent.name..'#LAST#')
				end
			talents = table.concat(talents, '\n')
			end

		return ([[Your fire carries over not just your power, but your knowledge as well.
Your mindless fires will be able to use %d #SLATE#[*]#LAST# different talents at talent level 1, with category mastery %.1f #SLATE#[*, dex]#LAST#. These talents are chosen randomly from a pool of %d #SLATE#[*]#LAST# talents that you know, which are permanent once chosen. #SLATE#(Use this skill to select them.)#LAST#%s]])
			:format(
				get(t.talents_known, self, t),
				get(t.talent_level, self, t),
				pool_size,
				talents)
		end,}

newTalent {
	name = 'Cremation',
	type = {'elemental/chaos', 4,},
	points = 5,
	require = make_require(4),
	mode = 'sustained',
	cooldown = 36,
	heat_per = 20,
	range = 0,
	radius = 6,
	speed = 'spell',
	target = function(self, t) return {
			type = 'cone', cone_angle = 90,
			range = get(t.range, self, t),
			radius = get(t.radius, self, t),}
		end,
	fire_damage = function(self, t)
		return self:scale {low = 100, high = 200, t, 'dex', after = 'damage',}
		end,
	on_pre_use = function(self, t, silent)
		if self:getHeat() < get(t.heat_per, self, t) then
			if not silent then game.logPlayer(self, 'You do not have enough heat to cast Cremation.') end
			return false
			end
		return true
		end,
	trigger = function(self, t, p)
		if self:getHeat() < p.heat_per then
			self:forceUseTalent(t.id, {ignore_energy = true,})
			return
			end

		self:incHeat(-p.heat_per)

		local tg, x, y = p.tg, self.x + p.dx, self.y + p.dy
		local damage = self:spellCrit(self:heatScale(get(t.fire_damage, self, t)))
		self:project(tg, x, y, function(x, y)
				local actor = game.level.map(x, y, Map.ACTOR)
				if not actor then return end
				if not actor.on_cremation or actor:on_cremation(self) then
					actor:setEffect('EFF_CREMATED', 1, {src = self,})
					self:projectOn(actor, 'FIRE', damage)
					end
				end)
		game.level.map:particleEmitter(self.x, self.y, tg.radius, 'breath_fire',
			{radius = tg.radius, tx = p.dx, ty = p.dy,})
		game:playSoundNear(self, 'talents/fireflash')
		end,
	activate = function(self, t)
		local tg = get(t.target, self, t)
		local x, y = self:getTarget(tg)
		if not x or not y then return end
		local p = {tg = tg, dx = x - self.x, dy = y - self.y,
			heat_per = get(t.heat_per, self, t),}
		t.trigger(self, t, p)
		return p
		end,
	callbackOnWait = function(self, t)
		if not self:isTalentActive(t.id) then return end
		local p = self:isTalentActive 'T_CREMATION'
		t.trigger(self, t, p)
		end,
	callbackOnMove = function(self, t)
		if self:isTalentActive(t.id) then self:forceUseTalent(t.id, {ignore_energy = true,}) end
		end,
	callbackOnTalentPost = function(self, t)
		if self:isTalentActive(t.id) then self:forceUseTalent(t.id, {ignore_energy = true,}) end
		end,
	deactivate = function(self, t) return true end,
	info = function(self, t)
		local damage = self:damDesc('FIRE', get(t.fire_damage, self, t))
		return ([[Lets loose an almighty wave of fire to purge the last speck of life from the target wide cone with radius %d, draining %d heat per turn of use.
Enemies caught in that area take %d <%d> #LIGHT_RED#fire#LAST# damage and have -100%% healing modifier.
This talent has to be channeled every turn with no interruption. Any action other than waiting will deactivate it.

Mindless fires caught in the flames gain maximal heat.
#SLATE#Numbers shown are for 100%% heat, numbers in <brackets> are the actual amounts based on your current heat.#LAST#]])
			:format(
				get(t.radius, self, t),
				get(t.heat_per, self, t),
				self:heatScale(damage, 100),
				self:heatScale(damage))
		end,}
