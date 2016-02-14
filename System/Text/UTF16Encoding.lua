-- Author      : Kurapica
-- Create Date : 2015/06/24
-- ChangeLog   :

_ENV = Module "System.Text.UTF16Encoding" "1.0.0"

namespace "System.Text"

_Cache = setmetatable({}, {__call = function(self, key) if key then for i in ipairs(key) do key[i] = nil end tinsert(self, key) else return tremove(self) or {} end end})

__Doc__[[Represents the utf-16 encoding with little-endian.]]
__Abstract__() class "UTF16EncodingLE" (function(_ENV)
	inherit "Encoding"

	__Static__()
	property "EncodingName" { Set = false, Default = "UTF-16LE" }

	__Doc__[[Decode to the unicode code points]]
	function Decode(str, startp) return decodeLE, str, startp or 1 end

	__Doc__[[Encode the unicode code points]]
	function Encode(codes, arg1, arg2)
		if type(codes) == "number" then
			return encodeLE(codes)
		elseif type(codes) == "table" then
			local cache = _Cache()

			for _, code in ipairs(codes) do
				tinsert(cache, encodeLE(code))
			end

			local ret = tconcat(cache)
			_Cache(cache)
			return ret
		elseif type(codes) == "function" then
			local cache = _Cache()

			for _, code in codes, arg1, arg2 do
				tinsert(cache, encodeLE(code))
			end

			local ret = tconcat(cache)
			_Cache(cache)
			return ret
		end
	end
end)

__Doc__[[Represents the utf-16 encoding with big-endian.]]
__Abstract__() class "UTF16EncodingBE" (function(_ENV)
	inherit "Encoding"

	__Static__()
	property "EncodingName" { Set = false, Default = "UTF-16BE" }

	__Doc__[[Decode to the unicode code points]]
	function Decode(str, startp) return decodeBE, str, startp or 1 end

	__Doc__[[Encode the unicode code points]]
	function Encode(codes, arg1, arg2)
		if type(codes) == "number" then
			return encodeBE(codes)
		elseif type(codes) == "table" then
			local cache = {}

			for _, code in ipairs(codes) do
				tinsert(cache, encodeBE(code))
			end

			return tconcat(cache)
		elseif type(codes) == "function" then
			local cache = {}

			for _, code in codes, arg1, arg2 do
				tinsert(cache, encodeBE(code))
			end

			return tconcat(cache)
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
function decodeLE(str, startp)
	if not startp then return nil end

	local sbyte, obyte = strbyte(str, startp, startp + 1)
	if not obyte or not sbyte then return nil end

	if obyte <= 0xD7 or obyte >= 0xE0 then
		-- two bytes
		return startp + 2, obyte * 0x100 + sbyte
	elseif obyte >= 0xD8 and obyte <= 0xDB then
		-- four byte
		local fbyte, tbyte = strbyte(str, startp + 2, startp + 3)
		if not tbyte or not fbyte then return false end

		if tbyte >= 0xDC and tbyte <= 0xDF then
			return startp + 4, ((obyte - 0xD8) * 0x100 + sbyte) * 0x400 + ((tbyte - 0xDC) * 0x100 + fbyte) + 0x10000
		else
			return nil
		end
	else
		return nil
	end
end

function encodeLE(code)
	if code >= 0 then
		-- 2
		if code <= 0xD7FF or (code >= 0xE000 and code <= 0xFFFF) then
			return strchar(
				code % 0x100,
				floor(code / 0x100)
			)
		end

		-- 4 surrogate pairs
		if code >= 0x10000 and code <= 0x10FFFF then
			code = code - 0x10000
			local high = floor(code / 0x400)
			local low = code % 0x400
			return strchar(
				high % 0x100,
				0xD8 + floor(high / 0x100),
				low % 0x100,
				0xDC + floor(low / 0x100)
			)
		end
	end

	error(("%s is not a valid unicode."):format(code))
end

function decodeBE(str, startp)
	if not startp then return nil end

	local obyte, sbyte = strbyte(str, startp, startp + 1)
	if not obyte or not sbyte then return nil end

	if obyte <= 0xD7 or obyte >= 0xE0 then
		-- two bytes
		return startp + 2, obyte * 0x100 + sbyte
	elseif obyte >= 0xD8 and obyte <= 0xDB then
		-- four byte
		local tbyte, fbyte = strbyte(str, startp + 2, startp + 3)
		if not tbyte or not fbyte then return false end

		if tbyte >= 0xDC and tbyte <= 0xDF then
			return startp + 4, ((obyte - 0xD8) * 0x100 + sbyte) * 0x400 + ((tbyte - 0xDC) * 0x100 + fbyte) + 0x10000
		else
			return nil
		end
	else
		return nil
	end
end

function encodeBE(code)
	if code >= 0 then
		-- 2
		if code <= 0xD7FF or (code >= 0xE000 and code <= 0xFFFF) then
			return strchar(
				floor(code / 0x100),
				code % 0x100
			)
		end

		-- 4 surrogate pairs
		if code >= 0x10000 and code <= 0x10FFFF then
			code = code - 0x10000
			local high = floor(code / 0x400)
			local low = code % 0x400
			return strchar(
				0xD8 + floor(high / 0x100),
				high % 0x100,
				0xDC + floor(low / 0x100),
				low % 0x100
			)
		end
	end

	error(("%s is not a valid unicode."):format(code))
end

-- Lua 5.3 - bitwise oper
if LUA_VERSION >= 5.3 then
	-- Use load since 5.1 & 5.2 can't read the bitwise oper
	decodeLE, encodeLE, decodeBE, encodeBE = load[[
		local strbyte, strchar = ...

		return function (str, startp)
			if not startp then return nil end

			local sbyte, obyte = strbyte(str, startp, startp + 1)
			if not obyte or not sbyte then return nil end

			if obyte <= 0xD7 or obyte >= 0xE0 then
				-- two bytes
				return startp + 2, (obyte << 8) + sbyte
			elseif obyte >= 0xD8 and obyte <= 0xDB then
				-- four byte
				local fbyte, tbyte = strbyte(str, startp + 2, startp + 3)
				if not tbyte or not fbyte then return false end

				if tbyte >= 0xDC and tbyte <= 0xDF then
					return startp + 4, ((((obyte - 0xD8) << 8) + sbyte) << 10) + (((tbyte - 0xDC) << 8) + fbyte) + 0x10000
				else
					return nil
				end
			else
				return nil
			end
		end,

		function (code)
			if code >= 0 then
				-- 2
				if code <= 0xD7FF or (code >= 0xE000 and code <= 0xFFFF) then
					return strchar(
						code & 0xff,
						code >> 8
					)
				end

				-- 4 surrogate pairs
				if code >= 0x10000 and code <= 0x10FFFF then
					code = code - 0x10000
					local high = code >> 10
					local low = code & 0x3ff
					return strchar(
						high & 0xff,
						0xD8 + high >> 8,
						low & 0xff,
						0xDC + low >> 8
					)
				end
			end

			error(("%s is not a valid unicode."):format(code))
		end,

		function (str, startp)
			if not startp then return nil end

			local obyte, sbyte = strbyte(str, startp, startp + 1)
			if not obyte or not sbyte then return nil end

			if obyte <= 0xD7 or obyte >= 0xE0 then
				-- two bytes
				return startp + 2, (obyte << 8) + sbyte
			elseif obyte >= 0xD8 and obyte <= 0xDB then
				-- four byte
				local tbyte, fbyte = strbyte(str, startp + 2, startp + 3)
				if not tbyte or not fbyte then return false end

				if tbyte >= 0xDC and tbyte <= 0xDF then
					return startp + 4, ((((obyte - 0xD8) << 8) + sbyte) << 10) + (((tbyte - 0xDC) << 8) + fbyte) + 0x10000
				else
					return nil
				end
			else
				return nil
			end
		end,

		function (code)
			if code >= 0 then
				-- 2
				if code <= 0xD7FF or (code >= 0xE000 and code <= 0xFFFF) then
					return strchar(
						code >> 8,
						code & 0xff
					)
				end

				-- 4 surrogate pairs
				if code >= 0x10000 and code <= 0x10FFFF then
					code = code - 0x10000
					local high = code >> 10
					local low = code & 0x3ff
					return strchar(
						0xD8 + high >> 8,
						high & 0xff,
						0xDC + low >> 8,
						low & 0xff
					)
				end
			end

			error(("%s is not a valid unicode."):format(code))
		end
	]](strbyte, strchar)
end


-- Lua 5.2 - bit32 lib or luajit bit lib
if (LUA_VERSION == 5.2 and type(bit32) == "table") or (LUA_VERSION == 5.1 and type(bit) == "table") then
	band = bit32 and bit32.band or bit.band
	lshift = bit32 and bit32.lshift or bit.lshift
	rshift = bit32 and bit32.rshift or bit.rshift

	function decodeLE(str, startp)
		if not startp then return nil end

		local sbyte, obyte = strbyte(str, startp, startp + 1)
		if not obyte or not sbyte then return nil end

		if obyte <= 0xD7 or obyte >= 0xE0 then
			-- two bytes
			return startp + 2, lshift(obyte, 8) + sbyte
		elseif obyte >= 0xD8 and obyte <= 0xDB then
			-- four byte
			local fbyte, tbyte = strbyte(str, startp + 2, startp + 3)
			if not tbyte or not fbyte then return false end

			if tbyte >= 0xDC and tbyte <= 0xDF then
				return startp + 4, lshift((lshift((obyte - 0xD8), 8) + sbyte), 10) + (lshift((tbyte - 0xDC), 8) + fbyte) + 0x10000
			else
				return nil
			end
		else
			return nil
		end
	end

	function encodeLE(code)
		if code >= 0 then
			-- 2
			if code <= 0xD7FF or (code >= 0xE000 and code <= 0xFFFF) then
				return strchar(
					band(code, 0xff),
					rshift(code, 8)
				)
			end

			-- 4 surrogate pairs
			if code >= 0x10000 and code <= 0x10FFFF then
				code = code - 0x10000
				local high = rshift(code, 10)
				local low = band(code, 0x3ff)
				return strchar(
					band(high, 0xff),
					0xD8 + rshift(high, 8),
					band(low, 0xff),
					0xDC + rshift(low, 8)
				)
			end
		end

		error(("%s is not a valid unicode."):format(code))
	end

	function decodeBE(str, startp)
		if not startp then return nil end

		local obyte, sbyte = strbyte(str, startp, startp + 1)
		if not obyte or not sbyte then return nil end

		if obyte <= 0xD7 or obyte >= 0xE0 then
			-- two bytes
			return startp + 2, lshift(obyte, 8) + sbyte
		elseif obyte >= 0xD8 and obyte <= 0xDB then
			-- four byte
			local tbyte, fbyte = strbyte(str, startp + 2, startp + 3)
			if not tbyte or not fbyte then return false end

			if tbyte >= 0xDC and tbyte <= 0xDF then
				return startp + 4, lshift((lshift((obyte - 0xD8), 8) + sbyte), 10) + (lshift((tbyte - 0xDC), 8) + fbyte) + 0x10000
			else
				return nil
			end
		else
			return nil
		end
	end

	function encodeBE(code)
		if code >= 0 then
			-- 2
			if code <= 0xD7FF or (code >= 0xE000 and code <= 0xFFFF) then
				return strchar(
					rshift(code, 8),
					band(code, 0xff)
				)
			end

			-- 4 surrogate pairs
			if code >= 0x10000 and code <= 0x10FFFF then
				code = code - 0x10000
				local high = rshift(code, 10)
				local low = band(code, 0x3ff)
				return strchar(
					0xD8 + rshift(high, 8),
					band(high, 0xff),
					0xDC + rshift(low, 8),
					band(low, 0xff)
				)
			end
		end

		error(("%s is not a valid unicode."):format(code))
	end
end