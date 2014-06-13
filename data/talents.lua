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


newTalentType {
	type = 'elemental/other',
	name = 'Misc. Elemental Talents',
	description = 'More Talents.',}

for folder, files in pairs {
	earth = {'misc', 'mountain', 'avalanche', 'symbiosis', 'geokinesis',
					 'geothermal', 'eyal-resolver', 'erosion',
					 'earth-metamorphosis', 'tectonic', 'cliffside',},
	fire = {'misc', 'brand',},}
do
	for _, file in pairs(files) do
		load('/data-elementals-race/talents/'..folder..'/'..file..'.lua')
	end
end

load('/data-elementals-race/talents/misc.lua')
