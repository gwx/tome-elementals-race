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


-- 1.1.5 require bug workaround. Mark all packages we're going to
-- superload as unloaded.
for _, p in pairs {'Actor', 'interface.Combat',} do
	package.loaded['mod.class.'..p] = nil
end

-- Add our own packages.
for _, p in pairs {'util', 'active-terrain',} do
	package.preload['elementals-race.'..p] =
		loadfile('/data-elementals-race/packages/'..p..'.lua')
end
