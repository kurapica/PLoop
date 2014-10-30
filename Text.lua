-- Author      : Kurapica
-- Create Date : 2014/10/05
-- ChangeLog   :

if require then require "System" end

Module "System.Text" "0.1.0"

namespace "System.Text"

__Doc__[[Represents a character encoding.]]
__Abstract__()
class "Encoding" {

}

__Doc__[[Represents the utf-8 encoding.]]
class "UTF8Encoding" {
	-- Super Class
	Encoding,
	-- Property
	IsBigEndian = Boolean,
	-- Method
	Parse = function (self, data)

	end,
}

__Doc__[[Represents the utf-16 encoding.]]
class "UTF16Encoding" {
	-- Super Class
	Encoding,
	-- Property
	IsBigEndian = Boolean,

}