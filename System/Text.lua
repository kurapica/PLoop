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

require "PLoop.System.Text.UTF8Encoding"
require "PLoop.System.Text.UTF16Encoding"

class "Encoding" (function(_ENV)
	__Doc__[[epresents the utf-8 encoding.]]
	__Static__()
	property "UTF8Encoding" { Set = false, Default = UTF8Encoding }

	__Doc__[[Represents the utf-16 encoding.]]
	__Static__()
	property "UTF16Encoding" { Set = false, Default = UTF16Encoding }
end)