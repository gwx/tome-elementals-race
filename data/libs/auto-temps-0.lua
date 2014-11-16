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


superload('mod.class.Actor', function(_M)
		--- Apply the temporary values defined in a table.
		-- The values will be recorded in source.__tmpvals to be automatically
		-- discarded at the appropriate time.
		-- @param source The source we're applying the values from/to.
		-- @param values The table of {attribute -> increase} values we're applying. Defaults to source.temps.
		function _M:autoTemporaryValues(source, values)
			values = values or source.temps
			for attribute, value in pairs(values) do
				self:effectTemporaryValue(source, attribute, value)
				end
			return source
			end

		--- Remove the temporary values defined by autoTemporaryValues, or similar calls.
		-- Removes all values in source.__tmpvals.
		-- @param source The source we're applying the values of.
		function _M:autoTemporaryValuesRemove(source)
			values = values or source.temps
			if not source.__tmpvals then return end
			for _, val in pairs(source.__tmpvals) do
				self:removeTemporaryValue(val[1], val[2])
				end
			source.__tmpvals = nil
			end
		end)
