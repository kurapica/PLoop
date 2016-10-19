--========================================================--
--                System                                  --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2013/08/13                              --
--========================================================--

--========================================================--
_ENV = Module     "System"                           "1.0.0"
--========================================================--

namespace "System"

------------------------------------------------------------
--                          APIS                          --
------------------------------------------------------------
strlen          = string.len
strformat       = string.format
strfind         = string.find
strsub          = string.sub
strbyte         = string.byte
strchar         = string.char
strrep          = string.rep
strsub          = string.gsub
strupper        = string.upper
strlower        = string.lower
strtrim         = strtrim or function(s) return (s:gsub("^%s*(.-)%s*$", "%1")) or "" end
strmatch        = string.match

wipe            = wipe or function(t) for k in pairs(t) do t[k] = nil end return t end

tblconcat       = table.concat
tinsert         = table.insert
tremove         = table.remove

floor           = math.floor
ceil            = math.ceil
log             = math.log
pow             = math.pow
min             = math.min
max             = math.max
random          = math.random

date            = date or (os and os.date)

create          = coroutine.create
resume          = coroutine.resume
running         = coroutine.running
status          = coroutine.status
wrap            = coroutine.wrap
yield           = coroutine.yield

loadstring      = loadstring or load
loadfile        = loadfile or load

------------------------------------------------------------
--                         Struct                         --
------------------------------------------------------------
__Base__(Number)
struct "PositiveNumber" { function(val) assert(val > 0, "%s must be greater than zero.") end }

__Base__(Number)
struct "NegtiveNumber"  { function(val) assert(val < 0, "%s must be less than zero.") end }

__Base__(Number) __Default__(0)
struct "Integer"        { function(val) assert(floor(val) == val, "%s must be an integer.") end }

__Base__(Integer)
struct "PositiveInteger"{ function(val) assert(val > 0, "%s must be greater than zero.") end }

__Base__(Integer)
struct "NegtiveInteger" { function(val) assert(val < 0, "%s must be less than zero.") end }

__Base__(Integer) __Default__(0)
struct "NaturalNumber"  { function(val) assert(val >= 0, "%s must be natural number.") end }