-- Author      : Kurapica
-- Create Date : 2012/06/03
-- ChangeLog   :

_ENV = Module "System.Error" "0.1.0"

namespace "System"

__Doc__[[Error object is used to contain the error messages and debug informations]]
class "Error" (function(_ENV)

	--------------------------------------
	--- Method
	--------------------------------------
	__Doc__[[Throw out self as an error]]
	Throw = error

	--------------------------------------
	--- Property
	--------------------------------------
	__Doc__[[The type name of the error object]]
	property "Name" {
		Get = function(self)
			return Reflector.GetNameSpaceName(Reflector.GetObjectClass(self))
		end,
	}

	__Doc__[[The error message]]
	property "Message" { Type = System.String }

	--------------------------------------
	--- Constructor
	--------------------------------------
	__Arguments__{ String }
	function Error(self, message) self.Message = message end

	__Arguments__{}
	function Error(self) end

	--------------------------------------
	--- Metamethod
	--------------------------------------
	function __tostring(self)
		return self.Message or self.Name
	end
end)