-- Author      : Kurapica
-- Create Date : 2012/06/03
-- ChangeLog   :

Module "System.Error" "0.1.0"

namespace "System"

class "Error"
	doc [======[
		@name Error
		@type class
		@desc Error object is used to contain the error messages and debug informations.
		@param message string, the error message
	]======]

	--------------------------------------
	--- Method
	--------------------------------------
	doc [======[
		@name Throw
		@type method
		@desc Throw out self as an error
		@return nil
	]======]
	function Throw(self)
		error(self, 2)
	end

	--------------------------------------
	--- Property
	--------------------------------------
	doc [======[
		@name Name
		@type property
		@desc The type name of the error object
	]======]
	property "Name" {
		Get = function(self)
			return Reflector.GetName(Reflector.GetObjectClass(self))
		end,
	}

	doc [======[
		@name Message
		@type property
		@desc The error message
	]======]
	property "Message" { Type = System.String + nil }

	--------------------------------------
	--- Constructor
	--------------------------------------
	function Error(self, message)
		self.__Message = type(message) == "string" and message or nil
	end

	--------------------------------------
	--- Metamethod
	--------------------------------------
	function __tostring(self)
		return self.Message or self.Name
	end
endclass "Error"