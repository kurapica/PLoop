--===========================================================================--
--                                                                           --
--                           System.Serialization                            --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2015/07/22                                               --
-- Update Date  :   2020/05/28                                               --
-- Version      :   1.1.5                                                    --
--===========================================================================--

PLoop(function(_ENV)
    export {
        type                = type,
        rawset              = rawset,
        rawget              = rawget,
        ipairs              = ipairs,
        pairs               = pairs,
        pcall               = pcall,
        getmetatable        = getmetatable,
        strformat           = string.format,
        safeset             = Toolset.safeset,
        isclass             = Class.Validate,
        isstruct            = Struct.Validate,
        isenum              = Enum.Validate,
        issubtype           = Class.IsSubType,
        isselfreferenced    = Struct.IsSelfReferenced,
        getarrayelement     = Struct.GetArrayElement,
        getmembers          = Struct.GetMembers,
        getfeatures         = Class.GetFeatures,
        getstructcategory   = Struct.GetStructCategory,
        getComboTypes       = Struct.GetComboTypes,
        MEMBER              = StructCategory.MEMBER,
        CUSTOM              = StructCategory.CUSTOM,
        ARRAY               = StructCategory.ARRAY,
        DICTIONARY          = StructCategory.DICTIONARY,
        getnamespace        = Namespace.Validate,
        validenum           = Enum.ValidateValue,
        validstruct         = Struct.ValidateValue,
        validclass          = Class.ValidateValue,
        validprop           = Property.Validate,
        gettemplate         = Class.GetTemplate,
        gettemplatepars     = Class.GetTemplateParameters,
        getstructtemplate   = Struct.GetTemplate,
        getstrcuttemppars   = Struct.GetTemplateParameters,
        getbasestruct       = Struct.GetBaseStruct,
        getdictkey          = Struct.GetDictionaryKey,
        getdictval          = Struct.GetDictionaryValue,
    }
    export { Enum, Struct, Class, Property }

    -----------------------------------------------------------
    --                        storage                        --
    -----------------------------------------------------------
    local _SerializableType     = {}
    local _SerializeInfo        = {}
    local _DefaultInfo          = {}
    local _NonSerializableInfo  = {}

    -----------------------------------------------------------
    --                        helpers                        --
    -----------------------------------------------------------
    export {
        savenonserializable = false,
        regSerializableType = false,
        saveTypeInfo        = false,
        isSerializable      = false,
        isSerializableType  = false,
        serialize           = false,
        deserialize         = false,

        yield               = coroutine.yield,
    }

    savenonserializable     = function(smem) _NonSerializableInfo = safeset(_NonSerializableInfo, smem, true) end

    -- Reset the cache if re-defined
    Runtime.OnTypeDefined   = Runtime.OnTypeDefined + function(type, target) if _SerializeInfo[target] then _SerializeInfo[target] = false end end

    function regSerializableType(type)
        _SerializableType   = safeset(_SerializableType, type, true)
    end

    function saveTypeInfo(type)
        _SerializeInfo      = safeset(_SerializeInfo, type, true)

        -- Cache the field info for quick access
        if isclass(type) and not issubtype(type, ISerializable) then
            local fieldInfo = {}
            local dftInfo

            for name, prop in getfeatures(type) do
                if validprop(prop) and not _NonSerializableInfo[prop] and prop:IsReadable() and prop:IsWritable() then
                    local ptype = prop:GetType()
                    if not ptype then
                        fieldInfo[name] = false
                    elseif isSerializableType(ptype) then
                        fieldInfo[name] = ptype
                    end

                    local default = prop:GetDefault()
                    if default ~= nil then
                        dftInfo         = dftInfo or {}
                        dftInfo[name]   = default
                    end
                end
            end

            _SerializeInfo  = safeset(_SerializeInfo, type, fieldInfo)
            if dftInfo or _DefaultInfo[type] then
                _DefaultInfo= safeset(_DefaultInfo, type, dftInfo)
            end
        elseif isstruct(type) and getstructcategory(type) == MEMBER then
            local fieldInfo = {}

            for _, mem in getmembers(type) do
                if not _NonSerializableInfo[mem] then
                    local mtype = mem:GetType()
                    if not mtype then
                        fieldInfo[mem:GetName()] = false
                    elseif isSerializableType(mtype) then
                        fieldInfo[mem:GetName()] = mtype
                    end
                end
            end

            _SerializeInfo  = safeset(_SerializeInfo, type, fieldInfo)
        end
    end

    function chkSerializableType(type, cache)
        if isenum (type)       then return true end
        if isclass(type)       then
            local template      = gettemplate(type)
            if template and isSerializableType(template) then
                for _,  par in ipairs{ gettemplatepars(type) } do if getnamespace(par) and not isSerializableType(par) then return false end end
                return true
            end
            return false
        end
        if not isstruct(type)  then return false end

        local category          = getstructcategory(type)

        if category == CUSTOM then
            local base          = getbasestruct(type)
            if base and isSerializableType(base) then return true end
            local template      = getstructtemplate(type)
            if template and isSerializableType(template) then
                for _,  par in ipairs{ getstrcuttemppars(type) } do if getnamespace(par) and not isSerializableType(par) then return false end end
                return true
            end
            local comba, comb   = getComboTypes(type)
            if comba and comb and isSerializableType(comba) and isSerializableType(comb) then
                return true
            end
        elseif category == ARRAY then
            cache               = cache or isselfreferenced(type) and {}
            if cache then cache[type] = true end
            if isSerializableType(getarrayelement(type), cache) then
                return true
            end
        elseif category == MEMBER then
            cache               = cache or isselfreferenced(type) and {}
            if cache then cache[type] = true end
            for _, member in getmembers(type) do
                if not _NonSerializableInfo[member] then
                    local mtype = member:GetType()
                    if mtype and not isSerializableType(mtype, cache) then return false end
                end
            end
            return true
        elseif category == DICTIONARY then
            cache               = cache or isselfreferenced(type) and {}
            if cache then cache[type] = true end
            local ktype         = getdictkey(type)
            if not (isstruct(ktype) and getstructcategory(ktype) == CUSTOM and isSerializableType(ktype)) then return false end
            local vtype         = getdictval(type)
            if not (vtype and isSerializableType(vtype, cache)) then return false end
            return true
        end

        return false
    end

    function isSerializableType(type, cache)
        if not type             then return false end
        if _SerializeInfo[type] then return true  end
        if cache and cache[type]then return true  end

        if _SerializableType[type] or chkSerializableType(type, cache) then
            saveTypeInfo(type)
            return true
        end

        return false
    end

    function isSerializable(obj)
        local otype             = type(obj)
        if otype == "table" then
            local cls           = getmetatable(obj)
            return (cls == nil or isSerializableType(cls)) and true or false
        else
            return otype == "string" or otype == "number" or otype == "boolean"
        end
    end

    function getAvailableContainerTypes(stype)
        local scategory = getstructcategory(stype)

        if scategory == CUSTOM then
            local comba, comb   = getComboTypes(stype)
            if comba and comb then
                if isclass(comba) then
                    yield(comba)
                elseif isstruct(comba) then
                    if getstructcategory(comba) == CUSTOM then
                        getAvailableContainerTypes(comba)
                    else
                        yield(comba)
                    end
                end

                if isclass(comb) then
                    yield(comb)
                elseif isstruct(comb) then
                    if getstructcategory(comb) == CUSTOM then
                        getAvailableContainerTypes(comb)
                    else
                        yield(comb)
                    end
                end
            end
        end
    end

    __Iterator__()
    function iterCombType(stype)
        getAvailableContainerTypes(stype)
    end

    function serialize(object, otype, cache)
        if cache[object] then throw("Duplicated object is not supported by System.Serialization") end
        cache[object]   = true

        local storage   = {}
        local stype     = otype or getmetatable(object)

        if isclass(stype) then
            if issubtype(stype, ISerializable) then
                local sinfo = SerializationInfo(storage, cache)
                object:Serialize(sinfo)
            else
                local srinfo = _SerializeInfo[stype]
                if srinfo and type(srinfo) == "table" then
                    local default = _DefaultInfo[stype]
                    if default then
                        for name, ptype in pairs(srinfo) do
                            local val = object[name]
                            if val ~= nil and val ~= default[name] then
                                if type(val) == "table" then
                                    val = serialize(val, ptype, cache)
                                end
                                storage[name] = val
                            end
                        end
                    else
                        for name, ptype in pairs(srinfo) do
                            local val = object[name]
                            if val ~= nil then
                                if type(val) == "table" then
                                    val = serialize(val, ptype, cache)
                                end
                                storage[name] = val
                            end
                        end
                    end
                else
                    for name, prop in getfeatures(stype) do
                        if validprop(prop) and not _NonSerializableInfo[prop] and prop:IsReadable() and prop:IsWritable() then
                            local ptype     = prop:GetType()
                            if not ptype or isSerializableType(ptype) then
                                local val   = object[name]
                                if val ~= nil then
                                    if type(val) == "table" then
                                        val = serialize(val, ptype, cache)
                                    end
                                    storage[name] = val
                                end
                            end
                        end
                    end
                end
            end
        elseif isstruct(stype) then
            local scategory = getstructcategory(stype)

            if scategory == CUSTOM then
                for ctype in iterCombType(stype) do
                    if isclass(ctype) and validclass(ctype, object, true) then
                        return serialize(object, ctype, {})
                    elseif isstruct(ctype) and validstruct(ctype, object, true) then
                        return serialize(object, ctype, {})
                    end
                end

                stype       = nil
            elseif scategory == ARRAY then
                local etype = getarrayelement(stype)
                if isSerializableType(etype) then
                    for i, val in ipairs(object) do
                        if type(val) == "table" then val = serialize(val, etype, cache) end
                        storage[i] = val
                    end
                else
                    for i, val in ipairs(object) do
                        if isSerializable(val) then
                            if type(val) == "table" then val = serialize(val, etype, cache) end
                            storage[i] = val
                        end
                    end
                end
            elseif scategory == MEMBER then
                local srinfo = _SerializeInfo[stype]
                if srinfo and type(srinfo) == "table" then
                    for name, mtype in pairs(srinfo) do
                        local val = object[name]
                        if val ~= nil then
                            if type(val) == "table" then
                                val = serialize(val, mtype, cache)
                            end
                            storage[name] = val
                        end
                    end
                else
                    for _, mem in getmembers(stype) do
                        if not _NonSerializableInfo[mem] then
                            local mtype = mem:GetType()
                            if not mtype or isSerializableType(mtype) then
                                local name = mem:GetName()
                                local val = object[name]
                                if val ~= nil then
                                    if type(val) == "table" then
                                        val = serialize(val, mtype, cache)
                                    end
                                    storage[name] = val
                                end
                            end
                        end
                    end
                end
            elseif scategory == DICTIONARY then
                local vtype = getdictval(stype)
                if isSerializableType(vtype) then
                    for k, v in pairs(object) do
                        local tk = type(k)

                        if (tk == "string" or tk == "number") then
                            if type(v) == "table" then v = serialize(v, vtype, cache) end
                            storage[k] = v
                        end
                    end
                else
                    for k, v in pairs(object) do
                        local tk = type(k)

                        if (tk == "string" or tk == "number") and isSerializable(v) then
                            if type(v) == "table" then v = serialize(v, vtype, cache) end
                            storage[k] = v
                        end
                    end
                end
            else
                stype = nil
            end
        else
            stype = nil
        end

        if not stype then
            for k, v in pairs(object) do
                local tk = type(k)

                if (tk == "string" or tk == "number") and isSerializable(v) then
                    if type(v) == "table" then v = serialize(v, nil, cache) end
                    storage[k] = v
                end
            end
        else
            -- save the object type
            storage[Serialization.ObjectTypeField] = stype
        end

        return storage
    end

    function deserialize(storage, otype)
        if type(storage) == "table" then
            local dtype = storage[Serialization.ObjectTypeField]
            if dtype ~= nil then
                storage[Serialization.ObjectTypeField] = nil

                dtype   = getnamespace(dtype)

                if dtype and (isclass(dtype) or isstruct(dtype)) then otype = dtype end
            end

            otype = dtype or otype

            if otype then
                if isclass(otype) then
                    if issubtype(otype, ISerializable) then
                        return otype(SerializationInfo(storage))
                    else
                        local srinfo = _SerializeInfo[otype]
                        if srinfo and type(srinfo) == "table" then
                            for name, ptype in pairs(srinfo) do
                                local val = storage[name]
                                if val ~= nil then
                                    storage[name] = deserialize(val, ptype)
                                end
                            end
                        else
                            for name, prop in getfeatures(otype) do
                                if validprop(prop) and not _NonSerializableInfo[prop] and prop:IsWritable() then
                                    local val = storage[name]
                                    if val ~= nil then
                                        storage[name] = deserialize(val, prop:GetType())
                                    end
                                end
                            end
                        end

                        -- As init-table
                        return otype(storage)
                    end
                elseif isstruct(otype) then
                    local scategory = getstructcategory(otype)

                    if scategory == CUSTOM then
                        for ctype in iterCombType(otype) do
                            local ok, ret = pcall(deserialize, storage, ctype)
                            if ok then return ret end
                        end
                    elseif scategory == ARRAY then
                        local etype = getarrayelement(otype)

                        for i, v in ipairs(storage) do
                            storage[i] = deserialize(v, etype)
                        end

                        return otype(storage)
                    elseif scategory == MEMBER then
                        local srinfo = _SerializeInfo[otype]
                        if srinfo and type(srinfo) == "table" then
                            for name, mtype in pairs(srinfo) do
                                local val = storage[name]
                                if val ~= nil then
                                    storage[name] = deserialize(val, mtype)
                                end
                            end
                        else
                            for _, mem in getmembers(otype) do
                                if not _NonSerializableInfo[mem] then
                                    local name  = mem:GetName()
                                    local val   = storage[name]

                                    if val ~= nil then
                                        storage[name] = deserialize(val, mem:GetType())
                                    end
                                end
                            end
                        end

                        return otype(storage)
                    elseif scategory == DICTIONARY then
                        local vtype = getdictval(otype)

                        for k, v in pairs(storage) do
                            storage[k] = deserialize(v, vtype)
                        end

                        return otype(storage)
                    end
                end
            end

            -- Default for no-type data or custom table struct data
            for k, v in pairs(storage) do
                if type(v) == "table" then
                    storage[k] = deserialize(v)
                end
            end

            return storage
        else
            if otype then
                if isstruct(otype) and getstructcategory(otype) == CUSTOM then
                    return validstruct(otype, storage)
                elseif isenum(otype) then
                    return validenum(otype, storage)
                else
                    throw(strformat("Deserialize non-table data to %s is not supported.", tostring(otype)))
                end
            else
                return storage
            end
        end
    end

    --- Serialization is the process of converting the state of an object into a form that can be persisted or transported.
    __Final__() __Sealed__()
    interface (_ENV, "System.Serialization") (function (_ENV)
        export {
            regSerializableType = regSerializableType,
            savenonserializable = savenonserializable,
            isSerializableType  = isSerializableType,
            isSerializable      = isSerializable,
            serialize           = serialize,
            deserialize         = deserialize,
            error               = error,
            type                = type,
        }

        export { AttributeTargets, StructCategory, Struct }

        --- indicates that a class or custom struct can be serialized
        __Sealed__() __Final__()
        class "__Serializable__" { IAttachAttribute,
            AttachAttribute     = function (self, target, targettype, owner, name, stack)
                if targettype == AttributeTargets.Struct and Struct.GetStructCategory(target) ~= StructCategory.CUSTOM then
                    error("the `__Serializable__` can only applied on custom struct or class", stack + 1)
                end

                regSerializableType(target)
            end,
            AttributeTarget     = { type = AttributeTargets, default = AttributeTargets.Struct + AttributeTargets.Class },
        }

        --- indicates that a member of struct or property of class can't be serialized
        __Sealed__() __Final__()
        class "__NonSerialized__" { IAttachAttribute,
            AttachAttribute     = function (self, target, targettype, owner, name, stack)
                savenonserializable(target)
            end,
            AttributeTarget     = { type = AttributeTargets, default = AttributeTargets.Property + AttributeTargets.Member },
        }

        --- allows classes to control its own serialization and deserialization,
        -- the class should define a method *Serialize* used to save its properties
        -- into the serialization info, also need a constructor that can accept
        -- the data of System.Serialization.SerializationInfo
        __Sealed__()
        interface "ISerializable" {
            --- Use a SerializationInfo to serialize the target object
            -- @owner   ISerializable
            -- @method  Serialize
            -- @param   info            the serialization info
            __Abstract__(),
            Serialize           = function(self, info) end
        }

        --- represents the serializable values
        __Sealed__()
        struct "Serializable"       { function(val) return not isSerializable(val) and (onlyvalid or "the %s must be serializable") or nil end }

        --- represents the serializable types
        __Sealed__()
        struct "SerializableType"   { function(type, onlyvalid) return not isSerializableType(type) and (onlyvalid or "the %s must be a serializable type") or nil end }

        --- stores all the data needed to serialize or deserialize an object
        __Sealed__() __Final__()
        class "SerializationInfo" {
            --- save the object data to the SerializationInfo
            -- @owner   SerializationInfo
            -- @method  SetValue
            -- @param   name        -- the field name
            -- @param   value       -- the field value
            -- @param   type        -- the value type
            SetValue            = function(self, name, value, vtype)
                if value == nil then return end

                if not isSerializable(value) then
                    throw("SerializationInfo:SetValue(name, value[, valuetype]) - value must be serializable")
                end

                if type(value) == "table" then
                    self.__storage[name] = serialize(value, vtype, self.__cache)
                else
                    self.__storage[name] = value
                end
            end,

            --- get the object data from the SerializationInfo
            -- @owner   SerializationInfo
            -- @method  GetValue
            -- @param   name        -- the field name
            -- @param   type        -- the value type
            -- @return  value       -- the field value
            GetValue            = function(self, name, vtype)
                local val       = self.__storage[name]
                if type(val) == "table" then
                    return deserialize(val, vtype)
                else
                    return val
                end
            end,

            __new               = function(_, storage, cache)
                return { __storage = storage, __cache = cache }, true
            end,
        }

        --- Provide a format for serialization. Used to serialize the table data to target format or convert the target format data to the table data
        __Abstract__() __Sealed__()
        class "FormatProvider" (function(_ENV)
            --- Serialize the common lua data to the target format for storage.
            __Abstract__()
            function Serialize(self, data, writer) end

            --- Deserialize the data to common lua data.
            __Abstract__()
            function Deserialize(self, reader) end
        end)

        -----------------------------------------------------------------------
        --                          static property                          --
        -----------------------------------------------------------------------
        --- The field that used to store the object type
        __Static__()
        property "ObjectTypeField" { type = NEString, default = "__PLoop_Serial_ObjectType" }

        -----------------------------------------------------------------------
        --                           static method                           --
        -----------------------------------------------------------------------
        __Arguments__{ FormatProvider, Any + Function + System.IO.TextReader, SerializableType/nil }
        __Static__() function Deserialize(provider, reader, otype)
            return deserialize(provider:Deserialize(reader), otype)
        end

        __Arguments__{ FormatProvider, Serializable, (Function + System.IO.TextWriter)/nil }
        __Static__() function Serialize(provider, object, writer)
            if type(object) ~= "table" then return provider:Serialize(object, writer) end
            return provider:Serialize(serialize(object, nil, {}), writer)
        end

        __Arguments__{ FormatProvider, Serializable, SerializableType, (Function + System.IO.TextWriter)/nil }
        __Static__() function Serialize(provider, object, otype, writer)
            if type(object) ~= "table" then return provider:Serialize(object, writer) end
            return provider:Serialize(serialize(object, otype, {}), writer)
        end
    end)

    -----------------------------------------------------------------------
    --                              prepare                              --
    -----------------------------------------------------------------------
    regSerializableType(Boolean)
    regSerializableType(String)
    regSerializableType(Number)
    regSerializableType(AnyBool)
    regSerializableType(NEString)
    regSerializableType(PositiveNumber)
    regSerializableType(NegativeNumber)
    regSerializableType(Integer)
    regSerializableType(NaturalNumber)
    regSerializableType(NegativeInteger)
    regSerializableType(Guid)

    export { Serialization, Serialization.SerializationInfo, Serialization.ISerializable }
end)