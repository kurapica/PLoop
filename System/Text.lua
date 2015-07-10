-- Author      : Kurapica
-- Create Date : 2014/10/05
-- ChangeLog   :

Module "System.Text" "0.1.0"

namespace "System.Text"

__Doc__[[Represents a character encoding.]]
__Abstract__() class "Encoding" (function(_ENV)
	__Doc__[[The name of the encoding]]
	__Static__()
	property "EncodingName" { Set = false, Default = "Encoding" }
end)
