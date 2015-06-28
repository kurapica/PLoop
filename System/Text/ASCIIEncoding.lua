-- Author      : Kurapica
-- Create Date : 2015/06/24
-- ChangeLog   :

Module "System.Text.ASCIIEncoding" "0.1.0"

namespace "System.Text"

__Doc__[[Represents an ASCII character encoding of Unicode characters.]]
__Abstract__() class "ASCIIEncoding" (function(_ENV)
	inherit "Encoding"

	__Static__()
	property "EncodingName" { Set = false, Default = "ASCII" }
end)