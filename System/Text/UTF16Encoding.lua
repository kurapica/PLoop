-- Author      : Kurapica
-- Create Date : 2015/06/24
-- ChangeLog   :

Module "System.Text.UTF16Encoding" "0.1.0"

namespace "System.Text"

strbyte = string.byte
strchar = string.char
tinsert = table.insert
tconcat = table.concat
floor = math.floor

__Doc__[[Represents the utf-16 encoding with little-endian.]]
__Abstract__() class "UTF16EncodingLE" (function(_ENV)
	inherit "Encoding"

	local function decode(str, startp)
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

	local function encode(code)
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

	__Static__()
	property "EncodingName" { Set = false, Default = "UTF-16" }

	__Doc__[[Decode to the unicode code points]]
	__Static__()
	function Decode(str, startp) return decode, str, startp or 1 end

	__Doc__[[Encode the unicode code points]]
	__Static__()
	function Encode(codes)
		if type(codes) == "number" then
			return encode(codes)
		elseif type(codes) == "table" then
			local cache = {}

			for _, code in ipairs(codes) do
				tinsert(cache, encode(code))
			end

			return tconcat(cache)
		end
	end
end)

__Doc__[[Represents the utf-16 encoding big-endian.]]
__Abstract__() class "UTF16EncodingBE" (function(_ENV)
	inherit "Encoding"

	local function decode(str, startp)
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

	local function encode(code)
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

	__Static__()
	property "EncodingName" { Set = false, Default = "UTF-16" }

	__Doc__[[Whether the encoding is big-endian]]
	property "IsBigEndian" { Type = Boolean, Default = true }

	__Doc__[[Decode to the unicode code points]]
	__Static__()
	function Decode(str, startp) return decode, str, startp or 1 end

	__Doc__[[Encode the unicode code points]]
	__Static__()
	function Encode(codes)
		if type(codes) == "number" then
			return encode(codes)
		elseif type(codes) == "table" then
			local cache = {}

			for _, code in ipairs(codes) do
				tinsert(cache, encode(code))
			end

			return tconcat(cache)
		end
	end
end)