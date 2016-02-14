-- Author      : Kurapica
-- Create Date : 2015/06/24
-- ChangeLog   :

_ENV = Module "System.Text.UTF8Encoding" "1.0.0"

namespace "System.Text"

REPLACE_CHARACTER = "\0xFFFD"

_Cache = setmetatable({}, {__call = function(self, key) if key then for i in ipairs(key) do key[i] = nil end tinsert(self, key) else return tremove(self) or {} end end})

--[[
7	U+0000		U+007F		1	0xxxxxxx
11	U+0080		U+07FF		2	110xxxxx	10xxxxxx
16	U+0800		U+FFFF		3	1110xxxx	10xxxxxx	10xxxxxx
21	U+10000		U+1FFFFF	4	11110xxx	10xxxxxx	10xxxxxx	10xxxxxx
26	U+200000	U+3FFFFFF	5	111110xx	10xxxxxx	10xxxxxx	10xxxxxx	10xxxxxx
31	U+4000000	U+7FFFFFFF	6	1111110x	10xxxxxx	10xxxxxx	10xxxxxx	10xxxxxx	10xxxxxx
]]
__Doc__[[Represents the utf-8 encoding.]]
__Abstract__() class "UTF8Encoding" (function(_ENV)
	inherit "Encoding"

	__Static__()
	property "EncodingName" { Set = false, Default = "UTF-8" }

	__Doc__[[Decode to the unicode code points]]
	function Decode(str, startp) return decode, str, startp or 1 end

	__Doc__[[Encode the unicode code points]]
	function Encode(codes, arg1, arg2)
		local ty = type(codes)
		if ty == "number" then
			return encode(codes)
		elseif ty == "table" then
			local cache = _Cache()

			for _, code in ipairs(codes) do
				tinsert(cache, encode(code))
			end

			local ret = tconcat(cache)
			_Cache(cache)
			return ret
		elseif ty == "function" then
			local cache = _Cache()

			for _, code in codes, arg1, arg2 do
				tinsert(cache, encode(code))
			end

			local ret = tconcat(cache)
			_Cache(cache)
			return ret
		end
	end
end)

-------------------------------
-- Encoding Helper
-------------------------------
strbyte = string.byte
strchar = string.char
tinsert = table.insert
tconcat = table.concat
floor = math.floor
LUA_VERSION = tonumber(_G._VERSION:match("[%d%.]+")) or 5.1

-- Default
function decode(str, startp)
	if not startp then return nil end

	local byte = strbyte(str, startp)
	if not byte then return nil end

	if byte < 0x80 then
		-- 1-byte
		return startp + 1, byte
	elseif byte	< 0xC2 then
		-- Error
		return startp + 1, byte + 0xDC00
	elseif byte < 0xE0 then
		-- 2-byte
		local sbyte = strbyte(str, startp + 1)
		if not sbyte or floor(sbyte / 0x40) ~= 2 then
			-- Error
			return startp + 1, byte + 0xDC00
		end
		return startp + 2, (byte * 0x40) + sbyte - 0x3080
	elseif byte < 0xF0 then
		-- 3-byte
		local sbyte, tbyte = strbyte(str, startp + 1, startp + 2)
		if not (sbyte and tbyte) or floor(sbyte / 0x40) ~= 2 or (byte == 0xE0 and sbyte < 0xA0) or floor(tbyte / 0x40) ~= 2 then
			-- Error
			return startp + 1, byte + 0xDC00
		end
		return startp + 3, (byte * 0x1000) + (sbyte * 0x40) + tbyte - 0xE2080
	elseif byte < 0xF5 then
		-- 4-byte
		local sbyte, tbyte, fbyte = strbyte(str, startp + 1, startp + 3)
		if not (sbyte and tbyte and fbyte) or floor(sbyte / 0x40) ~= 2 or (byte == 0xF0 and sbyte < 0x90) or (byte == 0xF4 and sbyte >= 0x90) or floor(tbyte / 0x40) ~= 2 or floor(fbyte / 0x40) ~= 2 then
			-- Error
			return startp + 1, byte + 0xDC00
		end

	    return startp + 4, (byte * 0x40000) + (sbyte * 0x1000) + (tbyte * 0x40) + fbyte - 0x3C82080
	else
		-- Error
		return startp + 1, byte + 0xDC00
	end
end

function encode(code)
	if code >= 0 then
		-- 1
		if code <= 0x7F then return strchar( code ) end

		-- 2
		if code <= 0x7FF then
			return strchar(
				floor(code / 0x40) + 0xC0,
				code % 0x40 + 0x80
			)
		end

		-- 3
		if code <= 0xFFFF then
			return strchar(
				floor(code / 0x1000) + 0xE0,
				floor(code / 0x40) % 0x40 + 0x80,
				code % 0x40 + 0x80
			)
		end

		-- 4
		if code <= 0x1FFFFF then
			return strchar(
				floor(code / 0x40000) + 0xF0,
				floor(code / 0x1000) % 0x40 + 0x80,
				floor(code / 0x40) % 0x40 + 0x80,
				code % 0x40 + 0x80
			)
		end
	end

	error(("%s is not a valid unicode."):format(code))
end

-- Lua 5.3 - bitwise oper
if LUA_VERSION >= 5.3 then
	-- Use load since 5.1 & 5.2 can't read the bitwise oper
	decode = load[[
		local strbyte = ...
		return function (str, startp)
			if not startp then return nil end

			local byte = strbyte(str, startp)
			if not byte then return nil end

			if byte < 0x80 then
				-- 1-byte
				return startp + 1, byte
			elseif byte	< 0xC2 then
				-- Error
				return startp + 1, byte + 0xDC00
			elseif byte < 0xE0 then
				-- 2-byte
				local sbyte = strbyte(str, startp + 1)
				if not sbyte or (sbyte & 0xC0) ~= 0x80 then
					-- Error
					return startp + 1, byte + 0xDC00
				end
				return startp + 2, (byte << 6) + sbyte - 0x3080
			elseif byte < 0xF0 then
				-- 3-byte
				local sbyte, tbyte = strbyte(str, startp + 1, startp + 2)
				if not (sbyte and tbyte) or (sbyte & 0xC0) ~= 0x80 or (byte == 0xE0 and sbyte < 0xA0) or (tbyte & 0xC0) ~= 0x80 then
					-- Error
					return startp + 1, byte + 0xDC00
				end
				return startp + 3, (byte << 12) + (sbyte << 6) + tbyte - 0xE2080
			elseif byte < 0xF5 then
				-- 4-byte
				local sbyte, tbyte, fbyte = strbyte(str, startp + 1, startp + 3)
				if not (sbyte and tbyte and fbyte) or (sbyte & 0xC0) ~= 0x80 or (byte == 0xF0 and sbyte < 0x90) or (byte == 0xF4 and sbyte >= 0x90) or (tbyte & 0xC0) ~= 0x80 or (fbyte & 0xC0) ~= 0x80 then
					-- Error
					return startp + 1, byte + 0xDC00
				end
			    return startp + 4, (byte << 18) + (sbyte << 12) + (tbyte << 6) + fbyte - 0x3C82080
			else
				return startp + 1, byte + 0xDC00
			end
		end
	]](strbyte)

	encode = load[[
		local strchar = ...
		return function (code)
			if code >= 0 then
				-- 1
				if code <= 0x7F then return strchar( code ) end

				-- 2
				if code <= 0x7FF then
					return strchar(
						(code >> 6) + 0xC0,
						code & 0x3F + 0x80
					)
				end

				-- 3
				if code <= 0xFFFF then
					return strchar(
						(code >> 12) + 0xE0,
						(code >> 6) & 0x3F + 0x80,
						code & 0x3F + 0x80
					)
				end

				-- 4
				if code <= 0x1FFFFF then
					return strchar(
						(code >> 18) + 0xF0,
						(code >> 12) & 0x3F + 0x80,
						(code >> 6) & 0x3F + 0x80,
						code & 0x3F + 0x80
					)
				end
			end

			error(("%s is not a valid code_point."):format(code))
		end
	]](strchar)
end

-- Lua 5.2 - bit32 lib or luajit bit lib
if (LUA_VERSION == 5.2 and type(bit32) == "table") or (LUA_VERSION == 5.1 and type(bit) == "table") then
	band = bit32 and bit32.band or bit.band
	lshift = bit32 and bit32.lshift or bit.lshift
	rshift = bit32 and bit32.rshift or bit.rshift

	function decode(str, startp)
		if not startp then return nil end

		local byte = strbyte(str, startp)
		if not byte then return nil end

		if byte < 0x80 then
			-- 1-byte
			return startp + 1, byte
		elseif byte	< 0xC2 then
			-- Error
			return startp + 1, byte + 0xDC00
		elseif byte < 0xE0 then
			-- 2-byte
			local sbyte = strbyte(str, startp + 1)
			if not sbyte or band(sbyte, 0xC0) ~= 0x80 then
				-- Error
				return startp + 1, byte + 0xDC00
			end
			return startp + 2, lshift(byte, 6) + sbyte - 0x3080
		elseif byte < 0xF0 then
			-- 3-byte
			local sbyte, tbyte = strbyte(str, startp + 1, startp + 2)
			if not (sbyte and tbyte) or band(sbyte, 0xC0) ~= 0x80 or (byte == 0xE0 and sbyte < 0xA0) or band(tbyte, 0xC0) ~= 0x80 then
				-- Error
				return startp + 1, byte + 0xDC00
			end
			return startp + 3, lshift(byte, 12) + lshift(sbyte, 6) + tbyte - 0xE2080
		elseif byte < 0xF5 then
			-- 4-byte
			local sbyte, tbyte, fbyte = strbyte(str, startp + 1, startp + 3)
			if not (sbyte and tbyte and fbyte) or band(sbyte, 0xC0) ~= 0x80 or (byte == 0xF0 and sbyte < 0x90) or (byte == 0xF4 and sbyte >= 0x90) or band(tbyte, 0xC0) ~= 0x80 or band(fbyte, 0xC0) ~= 0x80 then
				-- Error
				return startp + 1, byte + 0xDC00
			end
		    return startp + 4, lshift(byte, 18) + lshift(sbyte, 12) + lshift(tbyte, 6) + fbyte - 0x3C82080
		else
			return startp + 1, byte + 0xDC00
		end
	end

	function encode(code)
		if code >= 0 then
			-- 1
			if code <= 0x7F then return strchar( code ) end

			-- 2
			if code <= 0x7FF then
				return strchar(
					rshift(code, 6) + 0xC0,
					band(code, 0x3F) + 0x80
				)
			end

			-- 3
			if code <= 0xFFFF then
				return strchar(
					rshift(code, 12) + 0xE0,
					band(rshift(code, 6), 0x3F) + 0x80,
					band(code, 0x3F) + 0x80
				)
			end

			-- 4
			if code <= 0x1FFFFF then
				return strchar(
					rshift(code, 18) + 0xF0,
					band(rshift(code, 12), 0x3F) + 0x80,
					band(rshift(code, 6), 0x3F) + 0x80,
					band(code, 0x3F) + 0x80
				)
			end
		end

		error(("%s is not a valid code_point."):format(code))
	end
end