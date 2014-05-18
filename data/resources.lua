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


local resources = require 'engine.interface.ActorResource'

resources:defineResource('Jagged Body', 'jaggedbody', 'T_JAGGED_BODY', 'jaggedbody_regen', 'Your earthen body sprouts many sharp, rock-hard protrusions, blocking damage of any kind.', 0, 0)

resources:defineResource('Essence', 'essence', 'T_ESSENCE_POOL', 'essence_regen', 'Essence is your ability to manipulate the earth. It regenerates at the same rate as your life and your jagged body shield is increased by 33% of all essence spent.')
