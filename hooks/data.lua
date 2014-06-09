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
  local load_data = function(loader, name)
    require(loader):loadDefinition('/data-elementals-race/'..name..'.lua')
  end
  load_data('engine.interface.ActorTalents', 'talents')
  load_data('engine.interface.ActorTemporaryEffects', 'effects')
	load_data('engine.Birther', 'birth')
  load_data('engine.DamageType', 'damage-types')
end
class:bindHook('ToME:load', hook)
