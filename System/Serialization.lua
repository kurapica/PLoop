-- Author      : Kurapica
-- Create Date : 2015/07/22
-- ChangeLog   :

Module "System.Serialization" "0.1.0"

namespace "System"

__Doc__ [[Serialization is the process of converting the state of an object into a form that can be persisted or transported.]]
__Final__() __Sealed__()
interface "Serialization" (function (_ENV)

	__AttributeUsage__ { AttributeTarget = AttributeTargets.Class, Inherited = false, RunOnce = false }
	__Doc__ [[Indicates that a class can be serialized.(struct is always serializable.)]]
	__Unique__() __Sealed__() __Final__()
	class "__Serializable__" { __Attribute__ }

	__AttributeUsage__ { AttributeTarget = AttributeTargets.Property + AttributeTargets.Member, Inherited = false, RunOnce = false }
	__Doc__ [[Indicates that a field of a serializable class should not be serialized.]]
	__Unique__() __Sealed__() __Final__()
	class "__NonSerialized__" { __Attribute__ }

	__Doc__ [[Allows an object to control its own serialization and deserialization.]]
	interface "ISerializable" (function (_ENV)
		__Doc__[[Populates a SerializationInfo with the data needed to serialize the target object.]]
		__Require__() function Serialize(self, info) end
	end)

	__Doc__ [[Stores all the data needed to serialize or deserialize an object. ]]
	__Abstract__() class "SerializationInfo" (function (_ENV)
		__Doc__[[Adds the value into the SerializationInfo store.]]
		function SetValue(self, name, value, valueType)
		end

		__Doc__[[Retrieves the value from the SerializationInfo store.]]
		function GetValue(self, name, valueType)
		end
	end)

	__Doc__ [[Whether the object is serializable]]
	__Static__() function IsSerializable(obj)
		local otype = type(obj)

		if otype == "table" then
			local cls = getmetatable(otype)

			if cls == nil then
				return true
			elseif Reflector.IsClass(cls) then
				return __Attribute__.GetClassAttribute(cls, __Serializable__) and true or false
			end
		elseif otype == "boolean" or otype == "string" or otype == "number" then
			return true
		end

		return false
	end

	__Static__() function Deserialize(data)

	end

	__Static__() function Serialize(object, )

	end
end)
