-- Author      : Kurapica
-- Create Date : 2014/10/05
-- ChangeLog   :

_ENV = Module "System.Text" "0.1.0"

namespace "System.Text"

__Doc__[[Represents a character encoding.]]
__Abstract__() class "Encoding" (function(_ENV)
	__Doc__[[The name of the encoding]]
	__Static__()
	property "EncodingName" { Set = false, Default = "Encoding" }

	__Doc__[[Decode to the unicode code points]]
	function Decode() end

	__Doc__[[Encode the unicode code points]]
	function Encode() end
end)