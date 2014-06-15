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

local chance = 100

return {
	generator = function()
		local velv = 0 --rng.float(0, 0.3)
		return {
			life = rng.range(200, 300),
			size = rng.float(8, 11), sizev = 0, sizea = 0,
			x = rng.float(-16, 16), xv = 0, xa = 0,
			y = rng.float(-16, 16), yv = 0, ya = 0,

			dir = math.rad(rng.float(0, 360)),
			dirv = math.rad(rng.float(-50, 50)),
			dira = 0,

			vel = rng.float(0.05, 0.25),
			velv = velv,
			vela = -0.1 * velv,

			r = rng.float(0.0, 0.4), rv = rng.float(-0.001, 0), ra = 0,
			g = rng.float(0.0, 0.2), gv = rng.float(-0.001, 0), ga = 0,
			b = rng.float(0.0, 0.2), bv = rng.float(-0.001, 0), ba = 0,
			a = rng.float(0.1, 0.4), av = rng.float(-0.005, 0), aa = 0,}
	end,},
function(self)
	if rng.percent(chance) then
		self.ps:emit(2)
		if chance > 30 then chance = chance - 1 end
	end
end
