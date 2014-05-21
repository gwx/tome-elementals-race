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

return {
	generator = function()
		local rg = rng.float(0.1, 0.4)
		local velv = rng.float(0, 0.3)
		return {
			life = rng.range(8, 20),
			size = rng.float(5, 8), sizev = 0, sizea = 0,
			x = rng.float(-12, 12), xv = 0, xa = 0,
			y = rng.float(-12, 12), yv = 0, ya = 0,

			dir = math.rad(rng.float(0, 360)),
			dirv = math.rad(rng.float(-50, 50)),
			dira = 0,

			vel = rng.float(0.1, 0.3),
			velv = velv,
			vela = -0.1 * velv,

			r = rg, rv = rng.float(-0.01, 0), ra = 0,
			g = rg, gv = rng.float(-0.01, 0), ga = 0,
			b = rng.float(0.0, 0.1), bv = 0, ba = 0,
			a = rng.float(0.5, 0.9), av = rng.float(-0.01, 0), aa = 0,}
	end,},
function(self)
	self.nb = (self.nb or 0) + 1
	if self.nb < 6 then
		self.ps:emit(100)
	end
end
