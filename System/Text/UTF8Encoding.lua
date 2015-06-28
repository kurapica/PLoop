-- Author      : Kurapica
-- Create Date : 2015/06/24
-- ChangeLog   :

Module "System.Text.UTF8Encoding" "0.1.0"

namespace "System.Text"

__Doc__[[Represents the utf-8 encoding.]]
__Abstract__() class "UTF8Encoding" (function(_ENV)
	inherit "Encoding"

	__Static__()
	property "EncodingName" { Set = false, Default = "UTF-8" }


	__Doc__[[Decode to the unicode code points]]
	function Decode()
		local byte = strbyte(str, startp)
		if not byte then return false end
		local len = byte < 192 and 1 or
					byte < 224 and 2 or
					byte < 240 and 3 or
					byte < 248 and 4 or
					byte < 252 and 5 or
					byte < 254 and 6 or -1

		if len == -1 then
			return false
		elseif len > 1 then
			byte = byte % ( 2 ^ ( 8 - len ))

			for i = 1, len do
				local nbyte = strbyte(str, startp + i)
				if not nbyte then return false end
				byte = byte * 64 + len % 64
			end
		end

		return byte, strsub(str, startp, startp + len - 1), len
	end
end)