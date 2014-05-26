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


base_size = 32

local count = count or 20
local radius = radius or 2

return {
	generator = function()
		local ad = rng.range(0, 360)
		local a = math.rad(ad)
		local dir = math.rad(ad + 90)
		local maxr = 32 * radius
		local r = rng.float(0, 1.5 * maxr)
		if r > maxr * 0.8 then r = maxr * 0.8 end
		r = r + rng.float(0, 0.2 * maxr)
		local vel = rng.float(6, 11) * r / maxr
		local dirv = vel / (math.rad(72) * r)
		local alpha = rng.float(0.3, 0.6) + (r / maxr) * 0.3

		local rg = rng.float(0.4, 0.7)
		local b = rng.float(0, 0.1) + (r / maxr) * 0.2
		local size = rng.float(3, 7) + (r / maxr) * 2

		return {
			life = rng.range(200, 300),
			size = size, sizev = -0.005, sizea = 0,
			x = r * math.cos(a), xv = 0, xa = 0,
			y = r * math.sin(a), yv = 0, ya = 0,
			dir = dir, dirv = dirv, dira = 0,
			vel = vel, velv = 0, vela = 0,

			r = rg, rv = 0, ra = 0,
			g = rg, gv = 0, ga = 0,
			b = b, bv = 0, ba = 0,
			a = alpha, av = 0, aa = 0,}
	end,},
function(self)
	self.ps:emit(count)
end


--[[
return { generator = function()
	local ad = rng.range(0, 360)
	local a = math.rad(ad)
	local dir = math.rad(ad + 90)
	local r = rng.avg(1, 40 * 3)
	local dirv = math.rad(5)
	local rg = rng.range(150, 200)

	return {
		trail = 1,
		life = 50,
		size = rng.range(3, 6), sizev = -0.1, sizea = 0,

		x = r * math.cos(a), xv = 0, xa = 0,
		y = r * math.sin(a), yv = 0, ya = 0,
		dir = dir, dirv = dirv, dira = 0,
		vel = 5, velv = 0, vela = 0,

		r = rg/255,   rv = 0, ra = 0,
		g = rg/255,   gv = 0, ga = 0,
		b = rng.range(0, 10)/255,      bv = 0, ba = 0,
		a = rng.range(200, 255)/255,    av = 0, aa = 0.005,
	}
end, },
function(self)
	self.ps:emit(10)
end --,
--500,
--'particle_torus'
--'weather/snowflake'
--]]
