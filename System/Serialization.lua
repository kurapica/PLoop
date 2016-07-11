-- Author      : Kurapica
-- Create Date : 2015/07/22
-- ChangeLog   :

_ENV = Module "System.Serialization" "1.0.0"

namespace "System"

import "System.Reflector"

__Doc__ [[Serialization is the process of converting the state of an object into a form that can be persisted or transported.]]
__Final__() __Sealed__()
interface "Serialization" (function (_ENV)

	--------------------------------------
	-- Helper
	--------------------------------------
	class "SerializationInfo" {}

	_Cache = setmetatable({}, {
		__call = function(self, key)
			if key then
				wipe(key)
				tinsert(self, key)
			else
				return tremove(self) or {}
			end
		end,
	})

	local function Serialize2Data(object, oType, cache)
		assert(not cache[object], "Duplicated object is not supported by System.Serialization .")
		cache[object] = true

		local storage = {}

		local cls = getmetatable(object) or oType
		local clsType = cls and GetNameSpaceType(cls)

		if clsType == "Class" then
			if IsExtendedInterface(cls, ISerializable) then
				local info = rycInfo()
				_InfoStorage[info] = storage
				_InfoCache[info] = cache

				object:Serialize(info)

				rycInfo(info)
			else
				for prop in GetProperties(cls) do
					if IsPropertyReadable(cls, prop) and not __NonSerialized__:GetPropertyAttribute(cls, prop) then
						local value = object[prop]

						if value ~= nil and IsSerializable(value) then
							if type(value) == "table" then value = Serialize2Data(value, GetPropertyType(cls, prop), cache) end
							storage[prop] = value
						end
					end
				end
			end
		elseif clsType == "Struct" then
			local stype = GetStructType(oType)

			if stype == "ARRAY" then
				local eleType = GetStructArrayElement(oType)

				for _, value in ipairs(object) do
					if IsSerializable(value) then
						if type(value) == "table" then value = Serialize2Data(value, eleType, cache) end
						tinsert(storage, value)
					end
				end
			elseif stype == "MEMBER" then
				for _, member in GetStructMembers(oType) do
					if not __NonSerialized__:GetMemberAttribute(cls, member) then
						local value = object[member]

						if type(value) == "table" then value = Serialize2Data(value, GetStructMember(oType, member), cache) end
						storage[member] = value
					end
				end
			--[[elseif type(object.Serialize) == "function" then
				local info = rycInfo()
				_InfoStorage[info] = storage
				_InfoCache[info] = cache

				object:Serialize(info)

				rycInfo(info)--]]
			else
				-- A custom table data, can't know its true type, works as default
				clsType = nil
			end
		else
			clsType = nil
		end

		if not clsType then
			-- Default
			for key, value in pairs(object) do
				local ty = type(key)

				if (ty == "string" or ty == "number") and IsSerializable(value) then
					if type(value) == "table" then value = Serialize2Data(value, nil, cache) end
					storage[key] = value
				end
			end
		else
			-- Save the data type
			storage[Serialization.ObjectTypeField] = cls
		end

		return storage
	end

	local function Deserialize2Object(storage, oType)
		if type(storage) == "table" then
			local objTypeField = Serialization.ObjectTypeField
			local tarType = storage[objTypeField]
			local clsType

			if tarType ~= nil then
				storage[objTypeField] = nil

				if type(tarType) == "string" then
					tarType = GetNameSpaceForName(tarType)
				end

				clsType = tarType and GetNameSpaceType(tarType)

				if clsType == "Class" or clsType == "Struct" then oType = tarType end
			end

			clsType = oType and GetNameSpaceType(oType)

			if clsType == "Class" then
				if IsExtendedInterface(oType, ISerializable) then
					local info = rycInfo()
					_InfoStorage[info] = storage

					local obj = oType(info)

					rycInfo(info)

					return obj
				else
					for prop in GetProperties(oType) do
						if IsPropertyWritable(oType, prop) and not __NonSerialized__:GetPropertyAttribute(oType, prop) then
							local value = storage[prop]

							if value ~= nil then
								storage[prop] = Deserialize2Object(value, GetPropertyType(oType, prop))
							end
						end
					end

					return oType(storage)
				end
			end

			if clsType == "Struct" then
				local stype = GetStructType(oType)

				if stype == "ARRAY" then
					local eleType = GetStructArrayElement(oType)

					for i, v in ipairs(storage) do
						storage[i] = Deserialize2Object(v, eleType)
					end

					return oType(storage)
				elseif stype == "MEMBER" then
					for _, member in GetStructMembers(oType) do
						local val = storage[member]

						if val ~= nil then
							storage[member] = Deserialize2Object(val, GetStructMember(oType, member))
						end
					end

					return oType(storage)
				end
			end

			-- Default for no-type data or custom table struct data
			for k, v in pairs(storage) do
				if type(v) == "table" then
					storage[k] = Deserialize2Object(v)
				end
			end
		else
			clsType = oType and GetNameSpaceType(oType)

			if clsType then
				if clsType == "Struct" then
					if GetStructType(oType) == "CUSTOM" then
						return oType(storage)
					end
				elseif clsType == "Enum" then
					if oType(storage) ~= nil then
						return storage
					end
				end

				error(("Deserialize non-table data to %s is not supported."):format(tostring(oType)), 3)
			end
		end

		return storage
	end

	rycInfo = Recycle(SerializationInfo)
	_InfoStorage = {}
	_InfoCache = {}

	function rycInfo:OnPush(info)
		_InfoStorage[info] = nil
		_InfoCache[info] = nil
	end

	--------------------------------------
	-- Sub-NameSpace
	--------------------------------------
	__AttributeUsage__ { AttributeTarget = AttributeTargets.Class }
	__Doc__ [[Indicates that a class can be serialized.(struct is always serializable.)]]
	__Unique__() __Sealed__() __Final__()
	class "__Serializable__" { IAttribute }

	__AttributeUsage__ { AttributeTarget = AttributeTargets.Property + AttributeTargets.Member }
	__Doc__ [[Indicates that a property of a serializable class should not be serialized.]]
	__Unique__() __Sealed__() __Final__()
	class "__NonSerialized__" { IAttribute }

	__Doc__ [[Allows an object to control its own serialization and deserialization.]]
	interface "ISerializable" (function (_ENV)
		__Doc__[[Use a SerializationInfo to serialize the target object.]]
		__Require__() function Serialize(self, info) end
	end)

	__Sealed__()
	struct "Serializable" { function (value) assert(IsSerializable(value), "%s must be serializable.") end }

	__Doc__ [[Stores all the data needed to serialize or deserialize an object. ]]
	__Sealed__() __Final__()
	class "SerializationInfo" (function (_ENV)
		__Doc__[[Store the data to the SerializationInfo.]]
		function SetValue(self, name, value, oType)
			if value == nil then return end

			local storage = _InfoStorage[self]

			assert(storage, "SerializationInfo:SetValue(name, value[, oType]) - access denied.")
			assert(IsSerializable(value), "SerializationInfo:SetValue(name, value[, oType]) - value must be serializable.")

			if type(value) == "table" then
				storage[name] = Serialize2Data(value, oType, _InfoCache[self])
			else
				storage[name] = value
			end
		end

		__Doc__[[Get the data from the SerializationInfo with data type.]]
		function GetValue(self, name, oType)
			local storage = _InfoStorage[self]

			assert(storage, "SerializationInfo:SetValue(name, value[, oType]) - access denied.")
			local val = storage[name]

			if type(val) == "table" then
				return Deserialize2Object(val, oType)
			else
				return val
			end
		end
	end)

	__Doc__ [[Provide a format for serialization. Used to serialize the table data to target format or convert the target format data to the table data.]]
	__Abstract__()
	class "FormatProvider" (function (_ENV)
		__Doc__[[Serialize the common lua data to the target format for storage.]]
		__Arguments__{ Any }
		function Serialize(self, data)
			error(("%s has no implementation for FormatProvider:Serialize(System.Any)"):format(getmetatable(self)))
		end

		__Arguments__{ Any, Function }
		function Serialize(self, data, write)
			error(("%s has no implementation for FormatProvider:Serialize(System.Any, write)"):format(getmetatable(self)))
		end

		__Arguments__{ Any, System.IO.TextWriter }
		function Serialize(self, data, writer)
			error(("%s has no implementation for FormatProvider:Serialize(System.Any, System.IO.TextWriter)"):format(getmetatable(self)))
		end

		__Doc__[[Deserialize the data to common lua data.]]
		__Arguments__{ Any }
		function Deserialize(self, data)
			error(("%s has no implementation for FormatProvider:Deserialize(System.Any)"):format(getmetatable(self)))
		end

		__Arguments__{ System.IO.TextReader }
		function Deserialize(self, reader)
			error(("%s has no implementation for FormatProvider:Deserialize(System.IO.TextReader)"):format(getmetatable(self)))
		end
	end)

	--------------------------------------
	-- Static Property
	--------------------------------------
	__Doc__[[The field that used to store the object's type]]
	__Static__() property "ObjectTypeField" { Type = String , Default = "__PLoop_ObjectType" }

	--------------------------------------
	-- Static Method
	--------------------------------------
	__Doc__ [[Whether the object is serializable]]
	__Static__() function IsSerializable(obj)
		local otype = type(obj)

		if otype == "table" then
			local cls = getmetatable(obj)

			if cls == nil then
				return true
			else
				return __Serializable__:GetClassAttribute(cls) and true or false
			end
		else
			return otype == "string" or otype == "number" or otype == "boolean"
		end
	end

	__Arguments__{ FormatProvider, Any }
	__Static__() function Deserialize(provider, data)
		return Deserialize2Object(provider:Deserialize(data))
	end

	__Arguments__{ FormatProvider, System.IO.TextReader }
	__Static__() function Deserialize(provider, reader)
		return Deserialize2Object(provider:Deserialize(reader))
	end

	__Arguments__{ FormatProvider, Any, AnyType }
	__Static__() function Deserialize(provider, data, oType)
		return Deserialize2Object(provider:Deserialize(data), oType)
	end

	__Arguments__{ FormatProvider, System.IO.TextReader, AnyType }
	__Static__() function Deserialize(provider, reader, oType)
		return Deserialize2Object(provider:Deserialize(reader), oType)
	end

	__Arguments__{ FormatProvider, Serializable }
	__Static__() function Serialize(provider, object)
		if type(object) ~= "table" then return provider:Serialize(object) end

		local cache = _Cache()
		local ret = provider:Serialize(Serialize2Data(object, nil, cache))
		_Cache(cache)
		return ret
	end

	__Arguments__{ FormatProvider, Serializable, Function }
	__Static__() function Serialize(provider, object, write)
		if type(object) ~= "table" then return provider:Serialize(object, write) end

		local cache = _Cache()
		provider:Serialize(Serialize2Data(object, nil, cache), write)
		_Cache(cache)
	end

	__Arguments__{ FormatProvider, Serializable, System.IO.TextWriter }
	__Static__() function Serialize(provider, object, writer)
		if type(object) ~= "table" then return provider:Serialize(object, writer) end

		local cache = _Cache()
		provider:Serialize(Serialize2Data(object, nil, cache), writer)
		_Cache(cache)
	end

	__Arguments__{ FormatProvider, Serializable, AnyType }
	__Static__() function Serialize(provider, object, oType)
		if type(object) ~= "table" then return provider:Serialize(object) end

		local cache = _Cache()
		local ret = provider:Serialize(Serialize2Data(object, oType, cache))
		_Cache(cache)
		return ret
	end

	__Arguments__{ FormatProvider, Serializable, AnyType, Function }
	__Static__() function Serialize(provider, object, oType, write)
		if type(object) ~= "table" then return provider:Serialize(object, write) end

		local cache = _Cache()
		provider:Serialize(Serialize2Data(object, oType, cache), write)
		_Cache(cache)
	end

	__Arguments__{ FormatProvider, Serializable, AnyType, System.IO.TextWriter }
	__Static__() function Serialize(provider, object, oType, writer)
		if type(object) ~= "table" then return provider:Serialize(object, writer) end

		local cache = _Cache()
		provider:Serialize(Serialize2Data(object, oType, cache), writer)
		_Cache(cache)
	end
end)
