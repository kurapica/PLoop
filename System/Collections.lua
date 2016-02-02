-- Author      : Kurapica
-- Create Date : 2016/01/24
-- ChangeLog   :

_ENV = Module "System.Collections" "0.1.0"

namespace "System.Collections"

-----------------------
-- List
-----------------------
__Doc__[[Provider basic support for list collection]]
__Sealed__() interface "IList" (function (_ENV)

	__Doc__[[Return the iterator, the list]]
	__Require__() function GetIterator(self) end

	__Doc__[[Call the function for each element or set property's value for each element]]
	__Arguments__{ Function }
	function Each(self, func) for _, obj in self:GetIterator() do func(obj) end end

	__Arguments__{ String, Any }
	function Each(self, prop, value) for _, obj in self:GetIterator() do obj[prop] = value end end
end)

__Sealed__() class "List" { IList,
	-- Override
	GetIterator = ipairs,
	-- Meta-method
	__call = function(self)
		return self:GetIterator()
	end,
}

-----------------------
-- Dictionary
-----------------------
__Doc__[[Provider basic support for collection of key-value pairs]]
__Sealed__() interface "IDictionary" (function (_ENV)

	__Doc__[[Return the key-value pair iterator, the dicationary]]
	__Require__() function GetIterator(self) end

	__Doc__[[Call the function for each key-value pair]]
	__Arguments__{ Function }
	function Each(self, func) for k, v in self:GetIterator() do func(k, v) end end
end)