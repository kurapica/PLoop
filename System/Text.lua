-- Author      : Kurapica
-- Create Date : 2014/10/05
-- ChangeLog   :

Module "System.Text" "0.1.0"

namespace "System.Text"

__Doc__[[Represents a character encoding.]]
__Abstract__() class "Encoding" {

}

__Doc__[[Represents the utf-8 encoding.]]
class "UTF8Encoding" (function(_ENV)
	inherit "Encoding"


end)

__Doc__[[Represents the utf-16 encoding.]]
class "UTF16Encoding" (function(_ENV)
	inherit "Encoding"

	__Doc__[[Whether the encoding is big-endian]]
	property "IsBigEndian" { Type = Boolean, Default = true }
end)