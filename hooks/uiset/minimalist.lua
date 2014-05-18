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

local hook = function(self, data)
local shader = require "engine.Shader"

	local a = data.a
  local player = data.player
	local x = data.x
	local y = data.y
	local bx = data.bx
	local by = data.by
	local orient = data.orient
	local scale = data.scale

	local sshat = self.sshat
	local bshat = self.bshat
	--local life_c = self.life_c
	--local life_sha = self.life_sha
	--local equi_c = self.equi_c
	--local equi_sha = self.equi_sha
	local shat = self.shat
	local fshat = self.fshat
	local fshat_life_dark = self.fshat_life_dark
	local fshat_life = self.fshat_life
	local fshat_equi_dark = self.fshat_equi_dark
	local fshat_equi = self.fshat_equi
	local font_sha = self.font_sha
	local sfont_sha = self.sfont_sha

	local jb_c = {0x83/255, 0x7b/255, 0x33/255}
	local jb_sha = shader.new("resources", {require_shader=4, delay_load=true, color=jb_c, speed=1000, distort={1.5,1.5}})
	local essence_c = {0x94/255, 0xdf/255, 0xe8/255}
	local essence_sha = shader.new("resources", {require_shader=4, delay_load=true, color=essence_c, speed=1000, distort={1.5,1.5}})

	-- Jagged Body health bar
	local jb = player:knowTalent('T_JAGGED_BODY')
	if jb and not player._hide_resource_jaggedbody then
		sshat[1]:toScreenFull(x-6, y+8, sshat[6], sshat[7], sshat[2], sshat[3], 1, 1, 1, a)
		bshat[1]:toScreenFull(x, y, bshat[6], bshat[7], bshat[2], bshat[3], 1, 1, 1, a)
		if jb_sha.shad then jb_sha:setUniform("a", a) jb_sha.shad:use(true) end
		local p = math.min(1, math.max(0, player.jaggedbody / player.max_jaggedbody))
		shat[1]:toScreenPrecise(x+49, y+10, shat[6] * p, shat[7], 0, p * 1/shat[4], 0, 1/shat[5], jb_c[1], jb_c[2], jb_c[3], a)
		if jb_sha.shad then jb_sha.shad:use(false) end

		local jb_regen = player.jaggedbody_regen
		if not self.res.jb or self.res.jb.vc ~= player.jaggedbody or self.res.jb.vm ~= player.max_jaggedbody or self.res.jb.vr ~= jb_regen then
			self.res.jb = {
				vc = player.jaggedbody, vm = player.max_jaggedbody, vr = jb_regen,
				cur = {core.display.drawStringBlendedNewSurface(font_sha, (player.jaggedbody < 0) and "???" or ("%d/%d"):format(player.jaggedbody, player.max_jaggedbody), 255, 255, 255):glTexture()},
				regen={core.display.drawStringBlendedNewSurface(sfont_sha, ("%+0.2f"):format(jb_regen), 255, 255, 255):glTexture()},
			}
		end
		local dt = self.res.jb.cur
		dt[1]:toScreenFull(2+x+64, 2+y+10 + (shat[7]-dt[7])/2, dt[6], dt[7], dt[2], dt[3], 0, 0, 0, 0.7 * a)
		dt[1]:toScreenFull(x+64, y+10 + (shat[7]-dt[7])/2, dt[6], dt[7], dt[2], dt[3], 1, 1, 1, a)
		dt = self.res.jb.regen
		dt[1]:toScreenFull(2+x+144, 2+y+10 + (shat[7]-dt[7])/2, dt[6], dt[7], dt[2], dt[3], 0, 0, 0, 0.7 * a)
		dt[1]:toScreenFull(x+144, y+10 + (shat[7]-dt[7])/2, dt[6], dt[7], dt[2], dt[3], 1, 1, 1, a)

		local front = fshat_life_dark
		if player.jaggedbody >= player.max_jaggedbody then front = fshat_life end
		front[1]:toScreenFull(x, y, front[6], front[7], front[2], front[3], 1, 1, 1, a)
		self:showResourceTooltip(bx+x*scale, by+y*scale, fshat[6], fshat[7], "res:jaggedbody", self.TOOLTIP_JAGGEDBODY)
		x, y = self:resourceOrientStep(orient, bx, by, scale, x, y, fshat[6], fshat[7])
	elseif game.mouse:getZone('res:jaggedbody') then
		game.mouse:unregisterZone('res:jaggedbody')
	end


	-- Essence Pool
	if player:knowTalent('T_ESSENCE_POOL') and not player._hide_resource_essence then
		sshat[1]:toScreenFull(x-6, y+8, sshat[6], sshat[7], sshat[2], sshat[3], 1, 1, 1, a)
		bshat[1]:toScreenFull(x, y, bshat[6], bshat[7], bshat[2], bshat[3], 1, 1, 1, a)
		if essence_sha.shad then essence_sha:setUniform("a", a) essence_sha.shad:use(true) end
		local p = math.min(1, math.max(0, player.essence / player.max_essence))
		shat[1]:toScreenPrecise(x+49, y+10, shat[6] * p, shat[7], 0, p * 1/shat[4], 0, 1/shat[5], essence_c[1], essence_c[2], essence_c[3], a)
		if essence_sha.shad then essence_sha.shad:use(false) end

		local regen = player.essence_regen
		local max = player.max_essence
		if not self.res.essence or self.res.essence.vc ~= player.essence or self.res.essence.vm ~= max or self.res.essence.vr ~= regen then
			self.res.essence = {
				vc = player.essence, vm = max, vr = regen,
				cur = {core.display.drawStringBlendedNewSurface(font_sha, (player.essence < 0) and "???" or ("%d/%d"):format(player.essence, player.max_essence), 255, 255, 255):glTexture()},
				regen={core.display.drawStringBlendedNewSurface(sfont_sha, ("%+0.2f"):format(regen), 255, 255, 255):glTexture()},
			}
		end
		local dt = self.res.essence.cur
		dt[1]:toScreenFull(2+x+64, 2+y+10 + (shat[7]-dt[7])/2, dt[6], dt[7], dt[2], dt[3], 0, 0, 0, 0.7 * a)
		dt[1]:toScreenFull(x+64, y+10 + (shat[7]-dt[7])/2, dt[6], dt[7], dt[2], dt[3], 1, 1, 1, a)
		dt = self.res.essence.regen
		dt[1]:toScreenFull(2+x+144, 2+y+10 + (shat[7]-dt[7])/2, dt[6], dt[7], dt[2], dt[3], 0, 0, 0, 0.7 * a)
		dt[1]:toScreenFull(x+144, y+10 + (shat[7]-dt[7])/2, dt[6], dt[7], dt[2], dt[3], 1, 1, 1, a)

		local front = fshat_equi_dark
		if player.essence >= max then front = fshat_equi end
		front[1]:toScreenFull(x, y, front[6], front[7], front[2], front[3], 1, 1, 1, a)
		self:showResourceTooltip(bx+x*scale, by+y*scale, fshat[6], fshat[7], "res:essence", self.TOOLTIP_ESSENCE)
		x, y = self:resourceOrientStep(orient, bx, by, scale, x, y, fshat[6], fshat[7])
	elseif game.mouse:getZone('res:essence') then
		game.mouse:unregisterZone('res:essence')
	end

	data.x = x
	data.y = y
  return true
end
class:bindHook('UISet:Minimalist:Resources', hook)
