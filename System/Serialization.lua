-- Author      : Kurapica
-- Create Date : 2015/07/22
-- ChangeLog   :

Module "System.Serialization" "0.1.0"

namespace "System"

import "System.Reflector"
import "System.__Attribute__"

__Doc__ [[Serialization is the process of converting the state of an object into a form that can be persisted or transported.]]
__Final__() __Sealed__()
interface "Serialization" (function (_ENV)

	local function Serialize2Info(object, oType)
		if type(object) == "table" then
			local info = SerializationInfo()

			local cls = getmetatable(object)

			if IsClass(cls) then
				if IsExtendedInterface(cls, ISerializable) then
					object:Serialize(info)
				else
					for prop in GetAllProperties(cls) do
						if IsPropertyReadable(cls, prop) and not GetPropertyAttribute(cls, prop, __NonSerialized__) then
							local value = object[prop]

							if IsSerializable(value) then
								info[prop] = Serialize2Info(value)
							end
						end
					end
				end

				return info
			end

			if IsStruct(oType) then
				local stype = GetStructType(oType)

				if stype == "ARRAY" then
					for i, v in ipairs(object) do

					end

					return info
				else
					for _, member in GetStructMembers(oType) do

					end

					return info
				end
			end

			-- Default
			for k, v in pairs(object) do
				local ty = type(k)

				if (ty == "string" or ty == "number") and IsSerializable(v) then
					info[k] = Serialize2Info(v)
				end
			end

			return info
		else
			return object
		end
	end

	local function Info2Object(info, oType)

	end

	--------------------------------------
	-- Sub-NameSpace
	--------------------------------------
	__AttributeUsage__ { AttributeTarget = AttributeTargets.Class, Inherited = false, RunOnce = false }
	__Doc__ [[Indicates that a class can be serialized.(struct is always serializable.)]]
	__Unique__() __Sealed__() __Final__()
	class "__Serializable__" { __Attribute__ }

	__AttributeUsage__ { AttributeTarget = AttributeTargets.Property + AttributeTargets.Member, Inherited = false, RunOnce = false }
	__Doc__ [[Indicates that a property of a serializable class should not be serialized.]]
	__Unique__() __Sealed__() __Final__()
	class "__NonSerialized__" { __Attribute__ }

	__Doc__ [[Allows an object to control its own serialization and deserialization.]]
	interface "ISerializable" (function (_ENV)
		__Doc__[[Use a SerializationInfo to serialize the target object.]]
		__Require__() function Serialize(self, info) end
	end)

	__Sealed__() struct "Serializable" { function (value) assert(IsSerializable(value), "%s must be serializable.") end }

	__Doc__ [[Stores all the data needed to serialize or deserialize an object. ]]
	__Sealed__() __Final__() struct "SerializationInfo" (function (_ENV)
		__Doc__[[Store the data to the SerializationInfo.]]
		function SetValue(self, name, value, oType)
			assert(IsSerializable(value), "SerializationInfo:SetValue(name, value[, oType]) - value must be serializable")

			if type(value) == "table" then
				self[name] = Serialize2Info(value, oType)
			else
				self[name] = value
			end
		end

		__Doc__[[Get the data from the SerializationInfo with data type.]]
		function GetValue(self, name, oType)
			local val = self[name]

			if type(val) == "table" then
				return Info2Object(val, oType)
			else
				return val
			end
		end

		-- Use Validator as constructor
		function SerializationInfo() return {} end
	end)

	--------------------------------------
	-- Static Method
	--------------------------------------
	__Doc__ [[Whether the object is serializable]]
	__Static__() function IsSerializable(obj)
		local otype = type(obj)

		if otype == "table" then
			local cls = getmetatable(otype)

			if cls == nil then
				return true
			else
				return GetClassAttribute(cls, __Serializable__) and true or false
			end
		else
			return otype == "string" or otype == "number" or otype == "boolean"
		end
	end

	__Arguments__{ String }
	__Static__() function Deserialize(data)

	end

	__Arguments__{ System.Text.TextReader }
	__Static__() function Deserialize(reader)

	end

	__Arguments__{ Serializable }
	__Static__() function Serialize(object)
		if type(object) == "table" then
			local cls = getmetatable(object)

			if cls and IsExtendedInterface(cls, IsSerializable) then
			else
			end
		else
		end
	end

	__Arguments__{ Serializable, Function }
	__Static__() function Serialize(object, write)
		if type(object) == "table" then

		else
		end
	end

	__Arguments__{ Serializable, System.Text.TextWriter }
	__Static__() function Serialize(object, writer)
		if type(object) == "table" then

		else
		end
	end
end)
