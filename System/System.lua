-- Author      : Kurapica
-- Create Date : 2013/08/13
-- ChangeLog   :

_ENV = Module "System" "1.0.0"

namespace "System"

-- Common features
strlen = string.len
strformat = string.format
strfind = string.find
strsub = string.sub
strbyte = string.byte
strchar = string.char
strrep = string.rep
strsub = string.gsub
strupper = string.upper
strlower = string.lower
strtrim = strtrim or function(s)
  return (s:gsub("^%s*(.-)%s*$", "%1")) or ""
end
strmatch = string.match

wipe = wipe or function(t)
	for k in pairs(t) do
		t[k] = nil
	end
	return t
end

geterrorhandler = geterrorhandler or function()
	return print
end

errorhandler = errorhandler or function(err)
	return geterrorhandler()(err)
end

tblconcat = table.concat
tinsert = tinsert or table.insert
tremove = tremove or table.remove

floor = math.floor
ceil = math.ceil
log = math.log
pow = math.pow
min = math.min
max = math.max
random = math.random

date = date or (os and os.date)

create = coroutine.create
resume = coroutine.resume
running = coroutine.running
status = coroutine.status
wrap = coroutine.wrap
yield = coroutine.yield

loadstring = loadstring or load
loadfile = loadfile or load

-----------------------------
-- Struct
-----------------------------
struct "Integer" { 0,
	function (value)
		if type(value) ~= "number" then error(("%s must be a number, got %s."):format("%s", type(value)))  end
		return floor(value)
	end
}

struct "NaturalNumber"  { 0,
	function (value)
		if type(value) ~= "number" then error(("%s must be a number, got %s."):format("%s", type(value))) end
		assert(value >= 0, "%s can't be less than zero.")
		return floor(value)
	end
}
