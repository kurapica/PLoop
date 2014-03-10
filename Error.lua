-- Author      : Kurapica
-- Create Date : 2012/06/03
-- ChangeLog   :

Module "System.Error" "0.1.0"

namespace "System"

__Doc__[[Error object is used to contain the error messages and debug informations]]
class "Error"

	--------------------------------------
	--- Method
	--------------------------------------
	__Doc__[[Throw out self as an error]]
	function Throw(self)
		error(self, 2)
	end

	--------------------------------------
	--- Property
	--------------------------------------
	__Doc__[[The type name of the error object]]
	property "Name" {
		Get = function(self)
			return Reflector.GetName(Reflector.GetObjectClass(self))
		end,
	}

	__Doc__[[The error message]]
	property "Message" { Type = System.String + nil }

	--------------------------------------
	--- Constructor
	--------------------------------------
	function Error(self, message)
		self.Message = type(message) == "string" and message or nil
	end

	--------------------------------------
	--- Metamethod
	--------------------------------------
	function __tostring(self)
		return self.Message or self.Name
	end
endclass "Error"