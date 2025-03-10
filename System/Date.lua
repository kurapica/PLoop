--===========================================================================--
--                                                                           --
--                                System.Date                                --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2016/03/08                                               --
-- Update Date  :   2021/06/01                                               --
-- Version      :   1.0.3                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System"

    import "System.Serialization"

    export                              {
        strfind                         = string.find,
        strgmatch                       = string.gmatch,

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
        ALLOW_TIMEFORMAT                = (function() local r = {} ("aAbBcdHIjmMpSUwWxXyYZ"):gsub("%w", function(w) r[w] = true end) return r end)()
    }

    --- Represents the time format can be used in date api
    __Sealed__() __Base__(String)
    struct "TimeFormat"         {
        function(val, onlyvalid)
            if strfind(val, "*t") then
                return onlyvalid or "the %s can't contains '*t' as time format"
            else
                local hasfmt            = false
                for s in strgmatch(val, "%%(.)") do
                    if ALLOW_TIMEFORMAT[s] then
                        hasfmt          = true
                    else
                        return onlyvalid or "the '" .. s .. "' can't be used as time format"
                    end
                end
                if not hasfmt then return "the %s doesn't contains any time formats" end
            end
        end
    }

    class "Date"                {}

    --- Represents a time interval
    __Final__() __Sealed__() __ValueType__() __Serializable__() __SerializeFormat__(TargetFormat.NUMBER)
    class "TimeSpan"                    (function(_ENV)
        extend "ICloneable" "ISerializable"

        export                          {
            TimeSpan,

            floor                       = math.floor,
            abs                         = math.abs,
            tonumber                    = tonumber,
        }

        local function parseString(str)
            local n, d, h, m, s, ml     = str:match("^(%-?)(%d*)%.?(%d+):(%d+):(%d+)%.?(%d*)")
            h                           = h and tonumber(h)
            m                           = m and tonumber(m)
            s                           = s and tonumber(s)

            if h and m and s then
                return (n == "-" and -1 or 1) * (tonumber(d or 0) * 86400 + h * 3600 + m * 60 + s + (tonumber(ml or 0) / 1000))
            end
        end

        -----------------------------------------------------------
        --                   static property                     --
        -----------------------------------------------------------
        __Static__()
        property "Zero"                 { set = false, default = function() return TimeSpan(0) end }

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- Gets the number of ticks that represent the value of the current TimeSpan structure.
        property "Ticks"                { field = "ticks" }

        --- Gets the days component of the time interval represented by the current TimeSpan structure.
        property "Days"                 { type = Integer, get = function(self) return (self.ticks < 0 and -1 or 1) * floor(abs(self.ticks) / 86400) end }

        --- Gets the hours component of the time interval represented by the current TimeSpan structure.
        property "Hours"                { type = Integer, get = function(self) return (self.ticks < 0 and -1 or 1) * floor(abs(self.ticks) % 86400 / 3600)  end }

        --- Gets the minutes component of the time interval represented by the current TimeSpan structure.
        property "Minutes"              { type = Integer, get = function(self) return (self.ticks < 0 and -1 or 1) * floor(abs(self.ticks) % 3600 / 60)  end }

        --- Gets the seconds component of the time interval represented by the current TimeSpan structure.
        property "Seconds"              { type = Integer, get = function(self) return (self.ticks < 0 and -1 or 1) * floor(abs(self.ticks) % 60) end }

        --- Gets the milliseconds component of the time interval represented by the current TimeSpan structure
        property "Milliseconds"         { type = Integer, get = function(self) return (self.ticks < 0 and -1 or 1) * floor(abs(self.ticks * 1000) % 1000) end }

        --- Gets the value of the current TimeSpan structure expressed in whole and fractional days.
        property "TotalDays"            { get = function(self) return self.ticks / 86400 end }

        --- Gets the value of the current TimeSpan structure expressed in whole and fractional hours.
        property "TotalHours"           { get = function(self) return self.ticks / 3600  end }

        --- Gets the value of the current TimeSpan structure expressed in whole and fractional minutes.
        property "TotalMinutes"         { get = function(self) return self.ticks / 60 end }

        --- Gets the value of the current TimeSpan structure expressed in whole and fractional seconds.
        property "TotalSeconds"         { get = function(self) return self.ticks end }

        --- Gets the value of the current TimeSpan structure expressed in whole and fractional milliseconds
        property "TotalMilliseconds"    { get = function(self) return self.ticks * 1000 end }

        -----------------------------------------------------------
        --                    static method                      --
        -----------------------------------------------------------
        --- Parse the string to the TimeSpan
        __Static__() __Arguments__{ String }
        function Parse(str)
            local ticks                 = parseString(str)
            return ticks and TimeSpan(ticks)
        end

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- Serialize the date
        function Serialize(self, info)
            if info == TargetFormat.STRING then
                return self:ToString()
            elseif info == TargetFormat.NUMBER then
                return self.ticks
            else
                info:SetValue("ticks", self.ticks)
            end
        end

        --- Converts the value of the current TimeSpan object to its equivalent string representation.
        function ToString(self)
            -- [-][d.]hh:mm:ss
            local ticks                 = self.ticks
            local isneg                 = ticks < 0
            ticks                       = abs(ticks)

            local day                   = floor(ticks / 86400)
            local hour                  = floor(ticks % 86400 / 3600)
            local mins                  = floor(ticks % 3600 / 60)
            local sec                   = floor(ticks % 60)
            local ml                    = floor(ticks * 1000) % 1000

            return (isneg and "-" or "") ..
                   (day > 0 and (day .. ".") or "") ..
                   hour .. ":" .. mins .. ":" .. sec ..
                   (ml > 0 and (".%03d"):format(ml) or "")
        end

        --- Return a Clone of the date oject
        function Clone(self)
            return TimeSpan(self.Ticks)
        end

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{ TargetFormat, Any }
        function __new(_, fmt, value)
            local vtype                 = type(value)
            if vtype == "number" then
                return { ticks = floor(value) }, true
            elseif vtype == "string" then
                local ticks             = parseString(value)
                if hour then return { ticks = ticks }, true end
            end
            throw("The value can't be deserialized to TimeSpan object")
        end

        __Arguments__{ SerializationInfo }
        function __new(_, info)
            return { ticks = info:GetValue("ticks") or 0 }, true
        end

        __Arguments__{ Integer, Integer, Integer, Integer, Integer }
        function __new(_, day, hour, min, sec, milliseconds)
            return { ticks = day * 86400 + hour * 3600 + min * 60 + sec + milliseconds/1000 }, true
        end

        __Arguments__{ Integer, Integer, Integer, Integer }
        function __new(_, day, hour, min, sec)
            return { ticks = day * 86400 + hour * 3600 + min * 60 + sec }, true
        end

        __Arguments__{ Integer, Integer, Integer }
        function __new(_, hour, min, sec)
            return { ticks = hour * 3600 + min * 60 + sec }, true
        end

        __Arguments__{ Number }
        function __new(_, ticks)
            return { ticks = ticks }, true
        end

        -----------------------------------------------------------
        --                      Meta-method                      --
        -----------------------------------------------------------
        __Arguments__{ TimeSpan }
        function __eq(self, obj) return self.ticks == obj.ticks end

        __Arguments__{ Integer }
        function __eq(self, int) return self.ticks == int end

        __Arguments__{ TimeSpan }
        function __lt(self, obj) return self.ticks < obj.ticks end

        __Arguments__{ Integer }
        function __lt(self, int) return self.ticks < int end

        __Arguments__{ TimeSpan }
        function __le(self, obj) return self.ticks <= obj.ticks end

        __Arguments__{ Integer }
        function __le(self, int) return self.ticks <= int end

        __Arguments__{ TimeSpan }
        function __add(self, add) return TimeSpan(self.ticks + add.ticks) end

        __Arguments__{ Integer }
        function __add(self, add) return TimeSpan(self.ticks + add) end

        __Arguments__{ TimeSpan }
        function __sub(self, del) return TimeSpan(self.ticks - del.ticks) end

        __Arguments__{ Integer }
        function __sub(self, del) return TimeSpan(self.ticks - del) end

        __tostring              = ToString
    end)

    --- Represents the date object
    __Final__() __Sealed__() __ValueType__() __Serializable__() __NoRawSet__(false) __NoNilValue__(false) __SerializeFormat__(TargetFormat.NUMBER)
    class "Date"                        (function (_ENV)
        extend "ICloneable" "ISerializable"

        export {
            date                        = _G.os and os.date or _G.date,
            time                        = _G.os and os.time or _G.time,
            diff                        = _G.os and os.difftime or _G.difftime,
            floor                       = math.floor,
            abs                         = math.abs,
            pairs                       = pairs,
            type                        = type,
            getmetatable                = getmetatable,
            strfind                     = strfind,
            rawset                      = rawset,
            tonumber                    = tonumber,

            Serialization.TargetFormat, TimeSpan
        }

        local offset                    = diff(time(date("*t", 10^8)), time(date("!*t", 10^8)))
        local r2Time                    = function (self) self.time = time(self) + (self.msec and self.msec / 1000 or 0) end
        local r4Time                    = function (self) for k, v in pairs(date("*t", self.time)) do rawset(self, k, v) end end
        local getnow                    = time

        local parseString               = function(s)
            local year, month, day, hour, min, sec, msec
            local index                 = 0

            for n in s:gmatch("%d+") do
                index                   = index + 1
                if index == 1 then
                    year                = tonumber(n)
                elseif index == 2 then
                    month               = tonumber(n)
                elseif index == 3 then
                    day                 = tonumber(n)
                elseif index == 4 then
                    hour                = tonumber(n)
                elseif index == 5 then
                    min                 = tonumber(n)
                elseif index == 6 then
                    sec                 = tonumber(n)
                elseif index == 7 then
                    msec                = tonumber(n)
                    break
                end
            end

            if (year and month and day and year >= 1970 and month >= 1 and month <= 12 and day >= 1 and day <= 31)
                and (not hour or (hour >= 0 and hour < 24))
                and (not min  or (min  >= 0 and min < 60))
                and (not sec  or (sec  >= 0 and sec < 60)) then

                return year, month, day, hour, min, sec, msec
            end
        end

        local function handleMilliseconds(self, value)
            if value < 0 or value >= 1000 then
                local sec               = floor(value / 1000)
                value                   = value - sec * 1000

                sec                     = self.sec + sec

                rawset(self, "sec", sec)
                rawset(self, "msec", value)
                r2Time(self)

                if sec < 0 or sec > 59 then r4Time(self) end
            else
                -- simple modify the time
                self.time               = floor(self.time) + value / 1000
            end
        end

        -----------------------------------------------------------
        --                    static property                    --
        -----------------------------------------------------------
        --- Gets a DateTime object that is set to the current date and time on this computer, expressed as the local time.
        __Static__()
        property "Now"                  { get = function() return Date() end }

        --- Gets and Sets the function that return the current time value(the total second from 1970/1/1 00:00:00)
        __Static__()
        property "GetTimeOfDay"         { type = Function, set = function(self, val) getnow = val end, get = function() return getnow end }

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- The year of the date
        property "Year"                 { field = "year", set = false }

        --- The month of the year, 1-12
        property "Month"                { field = "month", set = false }

        --- The day of the month, 1-31
        property "Day"                  { field = "day",   set = false }

        --- The hour of the day, 0-23
        property "Hour"                 { field = "hour",  set = false }

        --- The minute of the hour, 0-59
        property "Minute"               { field = "min",   set = false }

        --- The Second of the minute, 0-61
        property "Second"               { field = "sec",   set = false }

        --- Gets the milliseconds of date, 0-999
        property "Milliseconds"         { field = "msec", default = 0,  set = false }

        --- The week number, with the mondy is the first day
        property "Week"                 { get = function(self) return tonumber(date("%W", self.time)) end}

        --- The weekday 0 (for Sunday) to 6 (for Saturday)
        property "DayOfWeek"            { get = function(self) return self.wday -1 end }

        --- The day of the year
        property "DayOfYear"            { field = "yday", set = false }

        --- Indicates whether this instance of DateTime is within the daylight saving time range for the current time zone.
        property "IsDaylightSavingTime" { field = "isdst", set = false }

        --- Gets the time that represent the date and time of this instance.
        property "Time"                 { field = "time",  set = false }

        -----------------------------------------------------------
        --                     static method                     --
        -----------------------------------------------------------
        --- Parse a string data to Date object
        __Static__() __Arguments__{ NEString, TimeFormat, Boolean/false }
        function Parse(s, format, isutc)
            local year, month, day, hour, min, sec
            local index                 = 1

            if format:find("^!") then
                isutc                   = true
                format                  = format:sub(2)
            end

            -- %d  Day of the month, zero-padded (01-31)                                        23
            -- %H  Hour in 24h format (00-23)                                                   14
            -- %m  Month as a decimal number (01-12)                                            08
            -- %M  Minute (00-59)                                                               55
            -- %S  Second (00-61)                                                               02
            -- %X  Time representation                                                          14:55:02
            -- %Y  Year                                                                         2001
            local pattern               = format:gsub("%%(.)", function(w)
                if w == "d" then
                    day                 = index
                    index               = index + 1
                    return "(%d?%d)"
                elseif w == "H" then
                    hour                = index
                    index               = index + 1
                    return "(%d?%d)"
                elseif w == "m" then
                    month               = index
                    index               = index + 1
                    return "(%d?%d)"
                elseif w == "M" then
                    min                 = index
                    index               = index + 1
                    return "(%d?%d)"
                elseif w == "S" then
                    sec                 = index
                    index               = index + 1
                    return "(%d?%d)"
                elseif w == "X" then
                    hour                = index
                    index               = index + 1

                    min                 = index
                    index               = index + 1

                    sec                 = index
                    index               = index + 1

                    return "(%d?%d):(%d?%d):(%d?%d)"
                elseif w == "Y" then
                    year                = index
                    index               = index + 1
                    return "(%d%d%d%d)"
                end
            end)

            if not (year and month and day) or ((hour or min or sec) and not (hour and min and sec)) then
                error("Usage: Date.Parse(s[, format][,isutc]) - the format isn't valid", 2)
            end

            local rs                    = { s:match(pattern) }
            year                        = tonumber(rs[year])
            month                       = tonumber(rs[month])
            day                         = tonumber(rs[day])

            if hour then
                hour                    = tonumber(rs[hour])
                min                     = tonumber(rs[min])
                sec                     = tonumber(rs[sec])
            end

            if not (year and month and day) or ((hour or min or sec) and not (hour and min and sec)) then
                return
            end

            return Date(year, month, day, hour, min, sec, isutc)
        end

        __Static__() __Arguments__{ NEString, Boolean/false, Boolean/false }
        function Parse(s, isEndOfDay, isutc)
            local year, month, day, hour, min, sec, msec = parseString(s)
            if year then
                return Date(year, month, day, hour or isEndOfDay and 23 or 0, min or isEndOfDay and 59 or 0, sec or isEndOfDay and 59 or 0, msec or 0, isutc)
            end
        end

        __Static__() __Arguments__{ Number }
        function Parse(time)
            return Date(time)
        end

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- Serialize the date
        function Serialize(self, info)
            if info == TargetFormat.STRING then
                return self:ToString()
            elseif info == TargetFormat.NUMBER then
                return self.Time
            else
                info:SetValue("time", self.Time)
            end
        end

        --- Return the diff second for the two Date object
        __Arguments__{ Date }
        function Diff(self, obj)
            return self.time - obj.time
        end

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
            return Date(self.Time + seconds)
        end

        __Arguments__{ TimeSpan }
        function AddSeconds(self, span)
            return Date(self.Time + span.Ticks)
        end

        --- Adds the specified number of milliseconds to the value of this instance, and return a new date object
        __Arguments__{ Integer }
        function AddMilliseconds(self, milliseconds)
            return Date(self.Time + milliseconds/1000)
        end

        --- Return a Clone of the date oject
        function Clone(self)
            return Date(self.Time)
        end

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{ TargetFormat, Any }
        function __new(_, fmt, value)
            local vtype                 = type(value)
            if vtype == "number" then
                local self              = { time = value, msec = floor(value * 1000) % 1000 / 1000 }
                r4Time(self)
                return self, true
            elseif vtype == "string" then
                local year, month, day, hour, min, sec, msec = parseString(value)
                if year then
                    if msec and (msec < 0 or msec >= 1000) then
                        local diff      = floor(msec/1000)
                        msec            = msec - diff * 1000
                        sec             = sec + diff
                    end

                    local self          = {
                        year            = year,
                        month           = month,
                        day             = day,
                        hour            = hour,
                        min             = min,
                        sec             = sec,
                        msec            = msec,
                    }

                    r2Time(self)
                    r4Time(self)

                    return self, true
                end
            end
            throw("The value can't be deserialized to Date object")
        end

        __Arguments__{ SerializationInfo }
        function __new(_, info)
            local self                  = { time = info:GetValue("time") or 0 }
            r4Time(self)
            return self, true
        end

        __Arguments__{ RawTable }
        function __new(_, time)
            -- No more check
            return time, true
        end

        __Arguments__{ Variable("time", Number, true) }
        function __new(_, tm)
            if (tm and tm < 0) then throw("Usage: Date(time) - the time must can't be negative") end

            local self                  = { time = tm or getnow(), msec = tm and floor(tm * 1000) % 1000 / 1000 }
            r4Time(self)
            return self, true
        end

        __Arguments__{
            Variable("year",  NaturalNumber),
            Variable("month", Integer),
            Variable("day",   Integer),
            Variable("hour",  Integer, true, 12),
            Variable("min",   Integer, true, 0),
            Variable("sec",   Integer, true, 0),
            Variable("utc",   Boolean, true, false)
        }
        function __new(_, year, month, day, hour, min, sec, utc)
            local self                  = {
                year                    = year,
                month                   = month,
                day                     = day,
                hour                    = hour,
                min                     = min,
                sec                     = utc and (sec + offset) or sec,
            }

            r2Time(self)
            r4Time(self)

            return self, true
        end

        __Arguments__{
            Variable("year",  NaturalNumber),
            Variable("month", Integer),
            Variable("day",   Integer),
            Variable("hour",  Integer, true, 12),
            Variable("min",   Integer, true, 0),
            Variable("sec",   Integer, true, 0),
            Variable("msec",  Integer, true, 0),
            Variable("utc",   Boolean, true, false)
        }
        function __new(_, year, month, day, hour, min, sec, msec, utc)
            if msec and (msec < 0 or msec >= 1000) then
                local diff              = floor(msec/1000)
                msec                    = msec - diff * 1000
                sec                     = sec + diff
            end

            local self                  = {
                year                    = year,
                month                   = month,
                day                     = day,
                hour                    = hour,
                min                     = min,
                sec                     = utc and (sec + offset) or sec,
                msec                    = msec,
            }

            r2Time(self)
            r4Time(self)

            return self, true
        end

        -----------------------------------------------------------
        --                      Meta-method                      --
        -----------------------------------------------------------
        __Arguments__{ Date }
        function __eq(self, obj) return self.time == obj.time end

        __Arguments__{ Date }
        function __lt(self, obj) return self.time < obj.time end

        __Arguments__{ Date }
        function __le(self, obj) return self.time <= obj.time end

        __add                           = AddSeconds
        __sub                           = Diff
        __tostring                      = ToString

        export { Date }
    end)
end)