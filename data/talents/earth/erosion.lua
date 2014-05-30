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

newTalentType {
	type = 'elemental/erosion',
	name = 'Erosion',
	generic = true,
	description = 'Sand is more dangerous than you think',
	allow_random = true,}

local make_require = function(tier)
	return {
		stat = {con = function(level) return 2 + tier * 8 + level * 2 end,},
		level = function(level) return -5 + tier * 4 + level end,}
end

newTalent {
	name = 'Sharkskin',
	type = {'elemental/erosion', 1,},
	require = make_require(1),
	points = 5,
	mode = 'passive',
	duration = 5,
	stacks = function(self, t)
		return math.floor(self:combatTalentScale(t, 10, 15) * (0.5 + self:getCon(0.5, true)))
	end,
	defense = function(self, t)
		return self:combatTalentScale(t, 3, 7) * (0.5 + self:getCon(0.5, true))
	end,
	power = function(self, t) return 2 + self:getCon(2, true) end,
	disarm = function(self, t)
		return math.floor(self:combatTalentScale(t, 2, 6) * (0.5 + self:getCon(0.5, true)))
	end,
	disarm_cooldown = 5,
	on_hit = function(self, t)
		self:setEffect('EFF_SHARKSKIN', util.getval(t.duration, self, t), {
										 amount = 1,
										 max = util.getval(t.stacks, self, t),
										 defense = util.getval(t.defense, self, t),
										 power = util.getval(t.power, self, t),
										 disarm_cooldown = util.getval(t.disarm_cooldown, self, t),
										 disarm = util.getval(t.disarm, self, t),})
	end,
	info = function(self, t)
		return ([[Your 'skin' has dried and cracked, forming a rough mesh of hooked scales if put to stress. Every time you are hit with a melee or archery attack, you gain a stack of Sharkskin for %d turns, up to %d stacks.
Each stack gives %d points to ranged defense and increases physical power by %d. Any enemy that lands a critical melee strike, up to once every %d turns, must pass a physical power check against your physical save or be disarmed for %d turns.
Defense, physical power, disarm duration and maximum stacks scale with constitution.]])
			:format(util.getval(t.duration, self, t),
							util.getval(t.stacks, self, t),
							util.getval(t.defense, self, t),
							util.getval(t.power, self, t),
							util.getval(t.disarm_cooldown, self, t),
							util.getval(t.disarm, self, t))
	end,}

-- Make movement normal, make a secondary talent that teleports you to
-- target square instead of moving, maybe look into a mouse-click
-- teleport as well.
newTalent {
	name = 'Amorphous',
	type = {'elemental/erosion', 2,},
	require = make_require(2),
	points = 5,
	essence = 15,
	cooldown = 19,
	range = 0,
	radius = function(self, t)
		return math.floor(util.bound(self:getTalentLevel(t), 2, 2.8))
	end,
	damage = function(self, t)
		return self:combatTalentScale(t, 30, 180) * (0.5 + self:getCon(0.5, true))
	end,
	duration = function(self, t)
		return math.floor(2 + self:combatTalentScale(t, 0, 3) * (0.5 + self:getCon(0.5, true)))
	end,
	tactical = {ATTACKAREA = 2, ESCAPE = 1,},
	target = function(self, t)
		return {type = 'ball', selffire = false, talent = t,
						range = util.getval(t.range, self, t),
						radius = util.getval(t.radius, self, t),}
	end,
	action = function(self, t)
		local tg = util.getval(t.target, self, t)
		-- Damage
		local base_damage = util.getval(t.damage, self, t)
		local projector = function(x, y, tg, self)
			local target = game.level.map(x, y, Map.ACTOR)
			if not target then return end
			local damage = self:physicalCrit(
				base_damage, nil, target, self:combatAttackRanged(), target:combatDefenseRanged())
			DamageType:get(DamageType.PHYSICAL).projector(
				self, x, y, DamageType.PHYSICAL, damage)
		end
		self:project(tg, self.x, self.y, projector)
		-- Map Effect
		local duration = util.getval(t.duration, self, t)
		local effect = game.level.map:addEffect(
			self, self.x, self.y, duration,
			DamageType.NULL,
			-- We're coopting the damage amount to hold various info.
			{effect_type = 'dust_storm',},
			tg.radius, 5, nil, {type = 'dust_storm'})
		effect.name = 'dust storm'
		-- Pretties
		game.level.map:particleEmitter(self.x, self.y, tg.radius, 'ball_earth', {radius = tg.radius + 1,})
		game:playSoundNear(self, 'talents/earth')
		return true
	end,
	info = function(self, t)
		return ([[Explodes in a radius %d burst of sand, dealing %d physical damage. For the next %d turns, you can freely move to any square inside the affected area in a single turn, as long as you are inside it.
Damage and duration increase with constitution.]])
			:format(util.getval(t.radius, self, t),
							Talents.damDesc(self, DamageType.PHYSICAL, util.getval(t.damage, self, t)),
							util.getval(t.duration, self, t))
	end,}

newTalent{
	name = 'Sandstorm',
	type = {'elemental/erosion', 3,},
	require = make_require(3),
	points = 5,
	essence = 15,
	cooldown = 23,
	range = 0,
	radius = 2,
	duration = function(self, t)
		return math.floor(5 + 5 * (0.5 + self:getCon(0.5, true)))
	end,
	accuracy = function(self, t)
		return self:combatTalentScale(t, 6, 11) * (0.5 + self:getCon(0.5, true))
	end,
	accuracy_duration = 2,
	stacks = 3,
	tactical = {ATTACKAREA = {PHYSICAL = 2}, DISABLE = {BLIND = 1,},},
	target = function(self, t)
		return {type = 'ball',
						range = util.getval(t.range, self, t),
						radius = util.getval(t.radius, self, t),}
	end,
	action = function(self, t)
		local radius = util.getval(t.radius, self, t)
		local duration = self:spellCrit(util.getval(t.duration, self, t))
		local accuracy = util.getval(t.accuracy, self, t)
		local accuracy_duration = util.getval(t.accuracy_duration, self, t)
		local stacks = util.getval(t.stacks, self, t)
		-- Add a lasting map effect
		local effect =
			game.level.map:addEffect(
				self, self.x, self.y, duration,
				DamageType.SANDSTORM, {
					accuracy = accuracy,
					max = accuracy * stacks,
					effect_duration = accuracy_duration,},
				radius, 5, nil,
				{type = 'sandstorm', args = {radius = radius,}, only_one = true,},
				function(e)
					e.x = e.src.x
					e.y = e.src.y
					return true
				end,
				false)
		effect.name = 'sandstorm'
		game:playSoundNear(self, 'talents/breath')
		return true
	end,
	info = function(self, t)
		local accuracy = util.getval(t.accuracy, self, t)
		return ([[A fierce sandstorm rages in radius %d around you for %d turns. #SLATE#(UNIMPLEMENTED: Enemy projectiles move 50%% slower through it,)#LAST# while anything inside loses %d accuracy every turn, stacking to a max of %d, at which point they become blinded as well.
Durration and accuracy reduction scale with constitution.]])
			:format(util.getval(t.radius, self, t),
							util.getval(t.duration, self, t),
							accuracy,
							accuracy * util.getval(t.stacks, self, t))
	end,}

newTalent {
	name = 'Silicine Slicers',
	type = {'elemental/erosion', 4,},
	require = make_require(4),
	points = 5,
	mode = 'sustained',
	essence = 20,
	cooldown = 21,
	no_npc_use = true,
	-- Enable timer on icon for 1.2:
	--[[
	iconOverlay = function(self, t, p)
		local _, crystal = next(p.crystals)
		if not crystal then return '' end
		local fnt = 'buff_font_small'
		return tostring(math.ceil(crystal.temporary)), fnt
	end,
	--]]
	length = function(self, t)
		return math.ceil(self:combatTalentScale(t, 5, 8)) * (0.5 + self:getCon(0.5, true))
	end,
	range = 5,
	duration = function(self, t)
		return math.ceil(self:combatTalentScale(t, 5, 8)) * (0.5 + self:getCon(0.5, true))
	end,
	damage = function(self, t)
		return self:combatTalentScale(t, 30, 200) * (0.5 + self:getCon(0.5, true))
	end,
	speed = function(self, t) return self:combatTalentScale(t, 0.2, 0.275) end,
	effect_duration = 2,
	radius = 1,
	target_filter = function(self, t)
		return function(x, y)
			return not game.level.map.seens(x, y) or not game.level.map(x, y, Map.TRAP)
		end
	end,
	target = function(self, t)
		return {type = 'hit', range = util.getval(t.range, self, t), talent = t,
						line_red_past_radius = true,}
	end,
	target2 = function(self, t, start_x, start_y)
		return {type = 'beam', radius = 0, talent = t,
						include_start = true, line_red_past_radius = true,
						start_x = start_x, start_y = start_y, range = util.getval(t.length, self, t),
						start_x2 = self.x, start_y2 = self.y, range2 = util.getval(t.range, self, t),
						filter = util.getval(t.target_filter, self, t),}
	end,
	activate = function(self, t)
		local _
		local p = {}
		local tg = util.getval(t.target, self, t)
		local x, y = self:getTarget(tg)
		if not x or not y then return end
		_, _, _, x, y = self:canProject(tg, x, y)

		tg = util.getval(t.target2, self, t, x, y)
		local x2, y2 = self:getTarget(tg)
		if not x2 or not y2 then return end
		_, _, _, x2, y2 = self:canProject(tg, x2, y2)

		local duration = util.getval(t.duration, self, t)
		local effect_duration = util.getval(t.effect_duration, self, t)
		local damage = util.getval(t.damage, self, t) / effect_duration
		local speed = util.getval(t.speed, self, t)

		-- Enforce no deep copy
		p.__CLASSNAME = 'tracker'
		p.crystals = {}
		p.count = 0
		-- TODO Crystal image
		local projector = function(x, y, tg, self)
			p.count = p.count + 1
			local trap = require 'mod.class.Trap'
			local crystal = trap.new {
				name = 'silicine slicers', type = 'physical',
				id_by_type = true, unided_name = 'strewn crystals',
				display = '^', color = colors.WHITE, --image =
				faction = self.faction,
				summoner = self, summoner_gain_exp = true,
				temporary = duration,
				damage = damage,
				speed = speed,
				removed = false,
				tracker = p,
				effect_duration = effect_duration,
				x = x, y = y,
				canAct = false,
				energy = {value = 0,},
				disarm = function() end,
				act = function(self)
					self:useEnergy()
					self.temporary = self.temporary - 1
					if self.temporary <= 0 then
						if game.level.map(self.x, self.y, engine.Map.TRAP) == self then
							game.level.map:remove(self.x, self.y, engine.Map.TRAP)
						end
						game.level:removeEntity(self)
						self.removed = true
						-- Auto deactivate base talent.
						self.tracker.count = self.tracker.count - 1
						if self.tracker.count <= 0 and self.summoner:isTalentActive('T_SILICINE_SLICERS') then
							self.tracker.no_explode = true
							self.summoner:forceUseTalent('T_SILICINE_SLICERS', {ignore_energy = true,})
						end
					end
				end,
				triggered = function(self, x, y, who)
					if who and who:canBe('cut') then
						who:setEffect('EFF_SILICINE_WOUND', self.effect_duration, {
														src = self.summoner,
														damage = self.damage,
														speed = self.speed,})
					end
					return true, false
				end,}
			table.insert(p.crystals, crystal)

			crystal:identify(true)
			crystal:resolve() crystal:resolve(nil, true)
			crystal:setKnown(self, true)
			game.level:addEntity(crystal)
			game.zone:addEntity(game.level, crystal, 'trap', x, y)
			game.level.map:particleEmitter(x, y, 1, 'summon')
		end
		self:project(tg, x2, y2, projector)

		return p
	end,
	deactivate = function(self, t, p)
		local radius = util.getval(t.radius, self, t)
		for _, crystal in pairs(p.crystals) do
			-- Deal Effect in radius
			if not p.no_explode then
				local tg = {type = 'ball', radius = radius, range = 0, friendlyfire = false,}
				local projector = function(x, y)
					local target = game.level.map(x, y, engine.Map.ACTOR)
					crystal.triggered(crystal, x, y, target)
				end
				crystal:project(tg, crystal.x, crystal.y, projector)
				game.level.map:particleEmitter(
					crystal.x, crystal.y, tg.radius, 'ball_matter', {radius = tg.radius,})
			end

			-- Remove Crystal
			if not crystal.removed then
				if game.level.map(crystal.x, crystal.y, engine.Map.TRAP) == crystal then
					game.level.map:remove(crystal.x, crystal.y, engine.Map.TRAP)
				end
				game.level:removeEntity(crystal)
			end
		end
		return true
	end,
	info = function(self, t)
		local timer = ''
		if self:isTalentActive('T_SILICINE_SLICERS') then
			local _, crystal = next(self.sustain_talents['T_SILICINE_SLICERS'].crystals)
			if crystal then
				timer = ('#GOLD#TURNS LEFT: %d#LAST#\n'):format(crystal.temporary)
			end
		end
		return ([[%sCreates a length %d line of sharp crystals in a target line between two points, neither farther than %d from you. The line persists for %d turns. Any enemy walking into the wickedly sharp crystals bleeds for %d physical damage over %d turns and has their global speed cut by %d%% for the duration.
Deactivating the ability early shatters the crystals. Every crystal rains shrapnel, applying the above effect in radius %d.
Damage, maximum line length and duration increase scale with constitution.]])
			:format(timer,
							util.getval(t.length, self, t),
							util.getval(t.range, self, t),
							util.getval(t.duration, self, t),
							Talents.damDesc(self, DamageType.PHYSICAL, util.getval(t.damage, self, t)),
							util.getval(t.effect_duration, self, t),
							util.getval(t.speed, self, t) * 100,
							util.getval(t.radius, self, t))
	end,}
