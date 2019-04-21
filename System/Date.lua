--===========================================================================--
--                                                                           --
--                                System.Date                                --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2016/03/08                                               --
-- Update Date  :   2019/04/21                                               --
-- Version      :   1.0.2                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System"

    import "System.Serialization"

    export {
        strfind             = string.find,
        strgmatch           = string.gmatch,

        -- %a  Abbreviated weekday name                                                     Thu
        -- %A  Full weekday namespace                                                       Thursday
        -- %b  Abbreviated month name                                                       Aug
        -- %B  Full month name                                                              August
        -- %c  Date and time representation                                                 Thu Aug 23 14:55:02 2001
        -- %d  Day of the month, zero-padded (01-31)                                        23
        -- %H  Hour in 24h format (00-23)                                                   14
        -- %I  Hour in 12h format (01-12)                                                   02
        -- %j  Day of the year (001-366)                                                    235
        -- %m  Month as a decimal number (01-12)                                            08
        -- %M  Minute (00-59)                                                               55
        -- %p  AM or PM designation                                                         PM
        -- %S  Second (00-61)                                                               02
        -- %U  Week number with the first Sunday as the first day of week one (00-53)       33
        -- %w  Weekday as a decimal number with Sunday as 0 (0-6)                           4
        -- %W  Week number with the first Monday as the first day of week one (00-53)       34
        -- %x  Date representation                                                          08/23/01
        -- %X  Time representation                                                          14:55:02
        -- %y  Year, last two digits (00-99)                                                01
        -- %Y  Year                                                                         2001
        -- %Z  Timezone name or abbreviation                                                CDT
        ALLOW_TIMEFORMAT    = (function() local r = {} ("aAbBcdHIjmMpSUwWxXyYZ"):gsub("%w", function(w) r[w] = true end) return r end)()
    }

    --- Represents the time format can be used in date api
    __Sealed__() __Base__(String)
    struct "TimeFormat" {
        function(val, onlyvalid)
            if strfind(val, "*t") then
                return onlyvalid or "the %s can't contains '*t' as time format"
            else
                local hasfmt    = false
                for s in strgmatch(val, "%%(.)") do
                    if ALLOW_TIMEFORMAT[s] then
                        hasfmt  = true
                    else
                        return onlyvalid or "the '" .. s .. "' can't be used as time format"
                    end
                end
                if not hasfmt then return "the %s doesn't contains any time formats" end
            end
        end
    }

    --- Represents the date object
    __Final__() __Sealed__() __Serializable__() __NoRawSet__(false) __NoNilValue__(false)
    class "Date" (function (_ENV)
        extend "ICloneable" "ISerializable"

        export {
            date        = _G.os and os.date or _G.date,
            time        = _G.os and os.time or _G.time,
            diff        = _G.os and os.difftime or _G.difftime,
            pairs       = pairs,
            type        = type,
            getmetatable= getmetatable,
            strfind     = strfind,
            rawset      = rawset,
            tonumber    = tonumber,
        }

        local offset    = diff(time(date("*t", 10^8)), time(date("!*t", 10^8)))
        local r2Time    = function (self) self.time = time(self) end
        local r4Time    = function (self) for k, v in pairs(date("*t", self.time)) do rawset(self, k, v) end end
        local getnow    = time

        -----------------------------------------------------------
        --                    static property                    --
        -----------------------------------------------------------
        --- Gets a DateTime object that is set to the current date and time on this computer, expressed as the local time.
        __Static__() property "Now" { get = function() return Date() end }

        --- Gets and Sets the function that return the current time value(the total second from 1970/1/1 00:00:00)
        __Static__() property "GetTimeOfDay" { type = Function, set = function(self, val) getnow = val end, get = function() return getnow end }

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- The year of the date
        property "Year" { type = Integer,   field = "year", handler = r2Time }

        --- The month of the year, 1-12
        property "Month" { type = Integer,  field = "month",handler = function(self, value) r2Time(self) if value < 1 or value > 12 then r4Time(self) end end }

        --- The day of the month, 1-31
        property "Day" { type = Integer,    field = "day",  handler = function(self, value) r2Time(self) if value < 1 or value > 28 then r4Time(self) end end }

        --- The hour of the day, 0-23
        property "Hour" { type = Integer,   field = "hour", handler = function(self, value) r2Time(self) if value < 0 or value > 23 then r4Time(self) end end }

        --- The minute of the hour, 0-59
        property "Minute" { type = Integer, field = "min",  handler = function(self, value) r2Time(self) if value < 0 or value > 59 then r4Time(self) end end }

        --- The Second of the minute, 0-61
        property "Second" { type = Integer, field = "sec",  handler = function(self, value) r2Time(self) if value < 0 or value > 59 then r4Time(self) end end }

        --- The weekday, Sunday is 1
        property "DayOfWeek" { get = function(self) return date("*t", self.time).wday end }

        --- The day of the year
        property "DayOfYear" { get = function(self) return date("*t", self.time).yday end }

        --- Indicates whether this instance of DateTime is within the daylight saving time range for the current time zone.
        property "IsDaylightSavingTime" { get = function(self) return date("*t", self.time).isdst end }

        --- Gets the time that represent the date and time of this instance.
        property "Time" { type = Integer, field = "time", handler = r4Time }

        -----------------------------------------------------------
        --                     static method                     --
        -----------------------------------------------------------
        --- Parse a string data to Date object
        __Static__() __Arguments__{ NEString, TimeFormat/"%Y-%m-%d %X", Boolean/false }
        function Parse(s, format, isutc)
            local year, month, day, hour, min, sec
            local index = 1

            if format:find("^!") then
                isutc   = true
                format  = format:sub(2)
            end

            -- %d  Day of the month, zero-padded (01-31)                                        23
            -- %H  Hour in 24h format (00-23)                                                   14
            -- %m  Month as a decimal number (01-12)                                            08
            -- %M  Minute (00-59)                                                               55
            -- %S  Second (00-61)                                                               02
            -- %X  Time representation                                                          14:55:02
            -- %Y  Year                                                                         2001
            local pattern   = format:gsub("%%(.)", function(w)
                if w == "d" then
                    day     = index
                    index   = index + 1
                    return "(%d?%d)"
                elseif w == "H" then
                    hour    = index
                    index   = index + 1
                    return "(%d?%d)"
                elseif w == "m" then
                    month   = index
                    index   = index + 1
                    return "(%d?%d)"
                elseif w == "M" then
                    min     = index
                    index   = index + 1
                    return "(%d?%d)"
                elseif w == "S" then
                    sec     = index
                    index   = index + 1
                    return "(%d?%d)"
                elseif w == "X" then
                    hour    = index
                    index   = index + 1

                    min     = index
                    index   = index + 1

                    sec     = index
                    index   = index + 1

                    return "(%d?%d):(%d?%d):(%d?%d)"
                elseif w == "Y" then
                    year    = index
                    index   = index + 1
                    return "(%d%d%d%d)"
                end
            end)

            if not (year and month and day) or ((hour or min or sec) and not (hour and min and sec)) then
                error("Usage: Date.Parse(s[, format][,isutc]) - the format isn't valid", 2)
            end

            local rs        = { s:match(pattern) }
            year            = tonumber(rs[year])
            month           = tonumber(rs[month])
            day             = tonumber(rs[day])

            if hour then
                hour        = tonumber(rs[hour])
                min         = tonumber(rs[min])
                sec         = tonumber(rs[sec])
            end

            if not (year and month and day) or ((hour or min or sec) and not (hour and min and sec)) then
                return
            end

            return Date(year, month, day, hour, min, sec, isutc)
        end

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- Serialize the date
        function Serialize(self, info)
            info:SetValue("time", self.Time)
        end

        --- Return the diff second for the two Date object
        __Arguments__{ Date }
        function Diff(self, obj) return diff(self.time, obj.time) end

        --- Converts the value of the current DateTime object to its equivalent string representation using the specified format.
        __Arguments__{ TimeFormat/"%Y-%m-%d %X" }
        function ToString(self, fmt)
            return date(fmt, self.time)
        end

        --- Converts the value of the current DateTime object to its equivalent UTC string representation using the specified format.
        __Arguments__{ TimeFormat/"!%Y-%m-%d %X" }
        function ToUTCString(self, fmt)
            if not strfind(fmt, "^!") then fmt = "!" .. fmt end
            return date(fmt, self.time)
        end

        --- Adds the specified number of years to the value of this instance, and return a new date object
        __Arguments__{ Integer }
        function AddYears(self, years)
            return Date(self.year + years, self.month, self.day, self.hour, self.min, self.sec)
        end

        --- Adds the specified number of months to the value of this instance, and return a new date object
        __Arguments__{ Integer }
        function AddMonths(self, months)
            return Date(self.year, self.month + months, self.day, self.hour, self.min, self.sec)
        end

        --- Adds the specified number of months to the value of this instance, and return a new date object
        __Arguments__{ Integer }
        function AddDays(self, days)
            return Date(self.year, self.month, self.day + days, self.hour, self.min, self.sec)
        end

        --- Adds the specified number of hours to the value of this instance, and return a new date object
        __Arguments__{ Integer }
        function AddHours(self, hours)
            return Date(self.year, self.month, self.day, self.hour + hours, self.min, self.sec)
        end

        --- Adds the specified number of minutes to the value of this instance, and return a new date object
        __Arguments__{ Integer }
        function AddMinutes(self, minutes)
            return Date(self.year, self.month, self.day, self.hour, self.min + minutes, self.sec)
        end

        --- Adds the specified number of seconds to the value of this instance, and return a new date object
        __Arguments__{ Integer }
        function AddSeconds(self, seconds)
            return Date(self.year, self.month, self.day, self.hour, self.min, self.sec + seconds)
        end

        --- Return a Clone of the date oject
        function Clone(self)
            return Date(self.Time)
        end

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{ SerializationInfo }
        function __new(_, info)
            local self = { time = info:GetValue("time") or 0 }
            r4Time(self)
            return self, true
        end

        __Arguments__{ RawTable }
        function __new(_, time)
            -- No more check
            return time, true
        end

        __Arguments__{ Variable("time", Integer, true) }
        function __new(_, tm)
            local self = { time = tm or getnow() }
            r4Time(self)
            return self, true
        end

        __Arguments__{
            Variable("year",  Integer),
            Variable("month", Integer),
            Variable("day",   Integer),
            Variable("hour",  Integer, true, 12),
            Variable("min",   Integer, true, 0),
            Variable("sec",   Integer, true, 0),
            Variable("utc",   Boolean, true, false)
        }
        function __new(_, year, month, day, hour, min, sec, utc)
            local self  = {
                year    = year,
                month   = month,
                day     = day,
                hour    = hour,
                min     = min,
                sec     = utc and (sec + offset) or sec,
            }

            r2Time(self)
            r4Time(self)

            return self, true
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

        __sub       = Diff
        __tostring  = ToString

        export { Date }
    end)
end)