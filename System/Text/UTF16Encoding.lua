-- Author      : Kurapica
-- Create Date : 2015/06/24
-- ChangeLog   :

Module "System.Text.UTF16Encoding" "0.1.0"

namespace "System.Text"

__Doc__[[Represents the utf-16 encoding.]]
__Abstract__() class "UTF16Encoding" (function(_ENV)
	inherit "Encoding"

	__Static__()
	property "EncodingName" { Set = false, Default = "UTF-16" }

	__Doc__[[Whether the encoding is big-endian]]
	property "IsBigEndian" { Type = Boolean, Default = true }
end)