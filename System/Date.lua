-- Author      : Kurapica
-- Create Date : 2016/03/08
-- ChangeLog   :

_ENV = Module "System.Date" "1.0.0"

namespace "System"

__Final__() __Sealed__() __SimpleClass__()
class "Date" (function (_ENV)
	extend "ICloneable"

	local date = os.date
	local time = os.time
	local diff = os.difftime

	local function r2Time(self) self.time = time(self) end
	local function r4Time(self) for k, v in pairs(date("*t", self.time)) do rawset(self, k, v) end end

	------------------------------------
	-- Static Property
	------------------------------------
	__Doc__ [[Gets a DateTime object that is set to the current date and time on this computer, expressed as the local time.]]
	__Static__() property "Now" { Get = function() return Date( time() ) end }

	------------------------------------
	-- Property
	------------------------------------
	__Doc__ [[The year of the date]]
	property "Year" { Type = Integer, Field = "year", Handler = r2Time }

	__Doc__ [[The month of the year, 1-12]]
	property "Month" { Type = Integer, Field = "month", Handler = function(self, value) r2Time(self) if value < 1 or value > 12 then r4Time(self) end end }

	__Doc__ [[The day of the month, 1-31]]
	property "Day" { Type = Integer, Field = "day", Handler = function(self, value) r2Time(self) if value < 1 or value > 28 then r4Time(self) end end }

	__Doc__ [[The hour of the day, 0-23]]
	property "Hour" { Type = Integer, Field = "hour", Handler = function(self, value) r2Time(self) if value < 0 or value > 23 then r4Time(self) end end }

	__Doc__ [[The minute of the hour, 0-59]]
	property "Minute" { Type = Integer, Field = "min", Handler = function(self, value) r2Time(self) if value < 0 or value > 59 then r4Time(self) end end }

	__Doc__ [[The Second of the minute, 0-61]]
	property "Second" { Type = Integer, Field = "sec", Handler = function(self, value) r2Time(self) if value < 0 or value > 59 then r4Time(self) end end }

	__Doc__ [[The weekday, Sunday is 1]]
	property "DayOfWeek" { Get = function(self) return date("*t", self.time).wday end }

	__Doc__ [[The day of the year]]
	property "DayOfYear" { Get = function(self) return date("*t", self.time).yday end }

	__Doc__ [[Indicates whether this instance of DateTime is within the daylight saving time range for the current time zone.]]
	property "IsDaylightSavingTime" { Get = function(self) return date("*t", self.time).isdst end }

	__Doc__ [[Gets the time that represent the date and time of this instance.]]
	property "Time" { Type = Integer, Field = "time", Handler = r4Time }

	------------------------------------
	-- Method
	------------------------------------
	__Doc__ [[Return the diff second for the two Date object]]
	__Arguments__{ Date }
	function Diff(self, obj) return diff(self.time, obj.time) end

	__Doc__ [[
		Converts the value of the current DateTime object to its equivalent string representation using the specified format.
		Using "!" at the start of the format to get Coordinated Universal Time display.

		Time Format:
			%a abbreviated weekday name (e.g., Wed)
			%A full weekday name (e.g., Wednesday)
			%b abbreviated month name (e.g., Sep)
			%B full month name (e.g., September)
			%c date and time (e.g., 09/16/98 23:48:10), default format
			%d day of the month (16) [01-31]
			%H hour, using a 24-hour clock (23) [00-23]
			%I hour, using a 12-hour clock (11) [01-12]
			%M minute (48) [00-59]
			%m month (09) [01-12]
			%p either "am" or "pm" (pm)
			%S second (10) [00-61]
			%w weekday (3) [0-6 = Sunday-Saturday]
			%x date (e.g., 09/16/98)
			%X time (e.g., 23:48:10)
			%Y full year (1998)
			%y two-digit year (98) [00-99]
	]]
	__Arguments__{ Argument(String, true, "%c") }
	function ToString(self, fmt)
		return date(fmt, self.time)
	end

	__Doc__ [[
		Converts the value of the current DateTime object to its equivalent UTC string representation using the specified format.
		Using "!" at the start of the format to get Coordinated Universal Time display.

		Time Format:
			%a abbreviated weekday name (e.g., Wed)
			%A full weekday name (e.g., Wednesday)
			%b abbreviated month name (e.g., Sep)
			%B full month name (e.g., September)
			%c date and time (e.g., 09/16/98 23:48:10), default format
			%d day of the month (16) [01-31]
			%H hour, using a 24-hour clock (23) [00-23]
			%I hour, using a 12-hour clock (11) [01-12]
			%M minute (48) [00-59]
			%m month (09) [01-12]
			%p either "am" or "pm" (pm)
			%S second (10) [00-61]
			%w weekday (3) [0-6 = Sunday-Saturday]
			%x date (e.g., 09/16/98)
			%X time (e.g., 23:48:10)
			%Y full year (1998)
			%y two-digit year (98) [00-99]
	]]
	__Arguments__{ Argument(String, true, "%c") }
	function ToUTCString(self, fmt)
		if not fmt:find("^!") then fmt = "!" .. fmt end
		return date(fmt, self.time)
	end

	__Doc__ [[Adds the specified number of years to the value of this instance, and return a new date object.]]
	__Arguments__{ Integer }
	function AddYears(self, years)
		return Date(self.year + years, self.month, self.day, self.hour, self.min, self.sec)
	end

	__Doc__ [[Adds the specified number of months to the value of this instance, and return a new date object.]]
	__Arguments__{ Integer }
	function AddMonths(self, months)
		return Date(self.year, self.month + months, self.day, self.hour, self.min, self.sec)
	end

	__Doc__ [[Adds the specified number of months to the value of this instance, and return a new date object.]]
	__Arguments__{ Integer }
	function AddDays(self, days)
		return Date(self.year, self.month, self.day + days, self.hour, self.min, self.sec)
	end

	__Doc__ [[Adds the specified number of hours to the value of this instance, and return a new date object.]]
	__Arguments__{ Integer }
	function AddHours(self, hours)
		return Date(self.year, self.month, self.day, self.hour + hours, self.min, self.sec)
	end

	__Doc__ [[Adds the specified number of minutes to the value of this instance, and return a new date object.]]
	__Arguments__{ Integer }
	function AddMinutes(self, minutes)
		return Date(self.year, self.month, self.day, self.hour, self.min + minutes, self.sec)
	end

	__Doc__ [[Adds the specified number of seconds to the value of this instance, and return a new date object.]]
	__Arguments__{ Integer }
	function AddSeconds(self, seconds)
		return Date(self.year, self.month, self.day, self.hour, self.min, self.sec + seconds)
	end

	__Doc__ [[Return a Clone of the date oject.]]
	function Clone(self)
		return Date(self.Time)
	end

	------------------------------------
	-- Constructor
	------------------------------------
	__Arguments__{ Argument(Integer, nil, nil, "time") }
	function Date(self, time)
		self.time = time
		return r4Time(self)
	end

	__Arguments__{
		Argument(Integer, nil, nil, "year"),
		Argument(Integer, nil, nil, "month"),
		Argument(Integer, nil, nil, "day"),
		Argument(Integer, true, 12, "hour"),
		Argument(Integer, true, 0, "min"),
		Argument(Integer, true, 0, "sec")
	}
	function Date(self, year, month, day, hour, min, sec)
		self.year = year
		self.month = month
		self.day = day
		self.hour = hour
		self.min = min
		self.sec = sec

		r2Time(self)
		r4Time(self)
	end

	------------------------------------
	-- Meta-method
	------------------------------------
	__Arguments__{ Date }
	function __eq(self, obj) return self.time == obj.time end

	__Arguments__{ Date }
	function __lt(self, obj) return self.time < obj.time end

	__Arguments__{ Date }
	function __le(self, obj) return self.time <= obj.time end

	__tostring = ToString
end)