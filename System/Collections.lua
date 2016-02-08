-- Author      : Kurapica
-- Create Date : 2016/01/24
-- ChangeLog   :

_ENV = Module "System.Collections" "0.1.0"

namespace "System.Collections"

-----------------------
-- Interface
-----------------------
__Doc__[[Provide basic support for list collection]]
__Sealed__() interface "IList" (function (_ENV)

	__Doc__[[Return the iterator, the list]]
	__Require__() function GetIterator(self) end
end)

__Doc__[[The object should provide a Count property]]
__Sealed__() interface "ICountable" (function (_ENV)
	__Doc__[[Get the count of items in the object]]
	__Require__() property "Count" { Set = false, Get = function (self) return #self end }
end)

__Doc__[[Provide basic support for collection of key-value pairs]]
__Sealed__() interface "IDictionary" (function (_ENV)

	__Doc__[[Return the key-value pair iterator, the dicationary]]
	__Require__() function GetIterator(self) end
end)

-----------------------
-- Attribute
-----------------------
__Doc__[[Notice the system that this class is an indexed list, so, the system can use obj[idx] to access datas. ]]
__AttributeUsage__{AttributeTarget = AttributeTargets.Class}
__Sealed__() __Unique__()
class "__IndexedList__" { IAttribute }

-----------------------
-- List
-----------------------
__Sealed__() __SimpleClass__() __IndexedList__()
class "List" (function (_ENV)
	extend "IList" "ICountable"

	-----------------------
	-- Method
	-----------------------
	GetIterator = ipairs

	__Doc__[[Add an item to the list]]
	Add = tinsert

	__Doc__[[Remove an item from the tail of the given index]]
	Remove = tremove

	-----------------------
	-- Constructor
	-----------------------
	__Arguments__{ }
	function List(self) end

	__Arguments__{ IList }
	function List(self, lst) for _, item in lst:GetIterator() do self:Add(item) end end

	__Arguments__{ Callable, Argument(Any, true), Argument(Any, true) }
	function List(self, iter, obj, idx) for idx, item in iter(obj, idx) do self:Add(item) end end

	__Arguments__{ NaturalNumber, Argument(Any, true) }
	function List(self, count, initValue)
		if initValue ~= nil then
			for i = 1, count do self:Add(initValue) end
		else
			for i = 1, count do self:Add(i) end
		end
	end

	-----------------------
	-- Meta-method
	-----------------------
	function __call(self) return self:GetIterator() end
end)

-----------------------
-- Dictionary
-----------------------
__Sealed__()
class "Dictionary" (function (_ENV)
	extend "IDictionary"

	-----------------------
	-- Property
	-----------------------
	property "Items" { Type = Table, Default = function(self) return {} end }

	-----------------------
	-- Method
	-----------------------
	GetIterator = function(self) return pairs(self.Items) end

	__Doc__[[Add an key-value pair to the dicationary]]
	function Add(self, key, value) self.Items[key] = value end

	__Doc__[[Remove an key from the dicationary]]
	function Remove(self, key) self.Items[key] = nil end

	-----------------------
	-- Constructor
	-----------------------
	__Arguments__{ }
	function Dictionary(self) end

	__Arguments__{ Table }
	function Dictionary(self, tbl) self.Items = tbl end

	__Arguments__{ IDictionary }
	function Dictionary(self, dict) for key, value in lst:GetIterator() do self:Add(key, value) end end

	__Arguments__{ IList, IList }
	function Dictionary(self, lstKey, lstValue)
		local iter, o, idx, value = lstValue:GetIterator()
		for _, key in lstKey:GetIterator() do
			idx, value = iter(o, idx)
			if idx then
				self:Add(key, value)
			else
				break
			end
		end
	end

	-----------------------
	-- Meta-method
	-----------------------
	function __call(self) return self:GetIterator() end
end)

-----------------------
-- Struct
-----------------------
__Default__(List)
struct "IListClass" { function(value) assert(Reflector.IsExtendedInterface(value, IList), "%s must be a class extend from System.Collections.IList") end }