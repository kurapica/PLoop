-- Author      : Kurapica
-- Create Date : 2014/10/05
-- ChangeLog   :

Module "System.Text" "0.1.0"

namespace "System.Text"

__Doc__[[Represents a character encoding.]]
__Abstract__() class "Encoding" (function(_ENV)

	__Doc__[[The name of the encoding]]
	property "EncodingName" { Set = false, Default = "Encoding" }

	__Doc__[[Gets or sets the DecoderFallback object for the current Encoding object.]]
	property "DecoderFallback" { Type = Function + String }

	__Doc__[[Gets or sets the EncoderFallback object for the current Encoding object.]]
	property "EncoderFallback" { Type = Function + String }
end)

__Doc__[[Represents an ASCII character encoding of Unicode characters.]]
class "ASCIIEncoding" (function(_ENV)
	inherit "Encoding"

	property "EncodingName" { Set = false, Default = "ASCIIEncoding" }
end)

__Doc__[[Represents the utf-8 encoding.]]
class "UTF8Encoding" (function(_ENV)
	inherit "Encoding"

	property "EncodingName" { Set = false, Default = "UTF8Encoding" }
end)

__Doc__[[Represents the utf-16 encoding.]]
class "UTF16Encoding" (function(_ENV)
	inherit "Encoding"

	property "EncodingName" { Set = false, Default = "UTF16Encoding" }

	__Doc__[[Whether the encoding is big-endian]]
	property "IsBigEndian" { Type = Boolean, Default = true }
end)