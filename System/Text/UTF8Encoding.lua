-- Author      : Kurapica
-- Create Date : 2015/06/24
-- ChangeLog   :

Module "System.Text.UTF8Encoding" "0.1.0"

namespace "System.Text"

strbyte = string.byte
strchar = string.char
tinsert = table.insert
tconcat = table.concat
floor = math.floor

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

	local function decode(str, startp)
		if not startp then return nil end

		local byte = strbyte(str, startp)
		if not byte then return nil end
		local len = byte < 0x80 and 1 or
					byte < 0xE0 and 2 or
					byte < 0xF0 and 3 or
					byte < 0xF8 and 4 or
					byte < 0xFC and 5 or
					byte < 0xFE and 6 or -1

		if len == -1 then
			return nil
		elseif len > 1 then
			byte = byte % ( 2 ^ ( 7 - len ))

			for i = 1, len-1 do
				local nbyte = strbyte(str, startp + i)
				if not nbyte then return nil end
				byte = byte * 64 + nbyte % 64
			end
		end

		return startp + len, byte
	end

	local function encode(code)
		if code >= 0 then
			-- 1
			if code <= 0x7F then
				return strchar(
					code
				)
			end

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
					floor(code / 0x40) % 0x40 + 0x80 ,
					code % 0x40 + 0x80
				)
			end

			-- 4
			if code <= 0x1FFFFF then
				return strchar(
					floor(code / 0x40000) + 0xF0,
					floor(code / 0x1000) % 0x40 + 0x80 ,
					floor(code / 0x40) % 0x40 + 0x80 ,
					code % 0x40 + 0x80
				)
			end

			-- 5
			if code <= 0x3FFFFFF then
				return strchar(
					floor(code / 0x1000000) + 0xF0,
					floor(code / 0x40000) % 0x40 + 0x80 ,
					floor(code / 0x1000) % 0x40 + 0x80 ,
					floor(code / 0x40) % 0x40 + 0x80 ,
					code % 0x40 + 0x80
				)
			end

			-- 6
			if code <= 0x7FFFFFFF then
				return strchar(
					floor(code / 0x40000000) + 0xF0,
					floor(code / 0x1000000) % 0x40 + 0x80 ,
					floor(code / 0x40000) % 0x40 + 0x80 ,
					floor(code / 0x1000) % 0x40 + 0x80 ,
					floor(code / 0x40) % 0x40 + 0x80 ,
					code % 0x40 + 0x80
				)
			end
		end

		error(("%s is not a valid unicode."):format(code))
	end

	__Static__()
	property "EncodingName" { Set = false, Default = "UTF-8" }

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