--===========================================================================--
--                                                                           --
--                              System.Reactive                              --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2023/04/20                                               --
-- Update Date  :   2023/10/20                                               --
-- Version      :   2.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)

    --- Object used to gain simple access to observable values
    __Sealed__()
    class "System.Reactive"             (function(_ENV)

        export {
            type                        = type,
            pairs                       = pairs,
            error                       = error,
            tostring                    = tostring,
            rawget                      = rawget,
            rawset                      = rawset,
            next                        = next,
            pcall                       = pcall,
            getmetatable                = getmetatable,
            isObjectType                = Class.IsObjectType,
            getObjectClass              = Class.GetObjectClass,
            validProp                   = Property.Validate,
            getFeatures                 = Class.GetFeatures,

            Class, Reactive, Property
        }

        local setObjectProp             = function(self, key, value) self[key] = value end

        -----------------------------------------------------------------------
        --                     inner type - declare only                     --
        -----------------------------------------------------------------------
        class "BehaviorSubject"         {}
        class "ReactiveList"            {}
        class "__Observable__"          {}

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        __Arguments__{ Table/nil }
        function __ctor(self, init)
            local fields                = {}
            rawset(self, Reactive, fields)
            if not init then return end

            -- Init
            local cls                   = getObjectClass(init)
            if cls then
                -- As proxy
                local isObservable      = __Observable__.IsObservableProperty
                local getPropertyOb     = __Observable__.GetPropertyObservable

                -- Wrap all observable properties
                for name, prop in getFeatures(cls, true) do
                    if validProp(prop) and isObservable(prop) then
                        local subject   = getPropertyOb(prop, init)
                        fields[name]    = isObjectType(subject, BehaviorSubject) and subject or BehaviorSubject(subject)
                    end
                end

                if not next(fields) then throw("The " .. tostring(cls) .. " class doesn't provide observable properties") end

                -- Bind the reactive with object
                rawset(self, Class, init)
                rawset(init, Reactive, self)
            else
                -- As init table, hash table only
                for k, v in pairs(init) do
                    if type(k) == "string" and k ~= "" and type(v) ~= "function" then
                        fields[k]       = reactive(v)
                    end
                end
            end
        end

        -- use the wrap for objects
        function __exist(_, init)
            return init and rawget(init, Reactive)
        end

        -----------------------------------------------------------------------
        --                            meta method                            --
        -----------------------------------------------------------------------
        --- Gets the current value
        function __index(self, key)
            local subject               =  rawget(self, Reactive)[key]
            if subject then
                if isObjectType(subject, BehaviorSubject) then
                    return subject:GetValue()
                else
                    -- inner reactive
                    return subject
                end
            end

            -- Check the proxy class
            local object                = rawget(self, Class)
            if object then return object[key] end
        end

        --- Send the new value
        function __newindex(self, key, value)
            local fields                = rawget(self, Reactive)
            local object                = rawget(self, Class)

            -- Set the object is exist
            if object then
                local ok, err           = pcall(setObjectProp, object, key, value)
                if not ok then error(err, 2) end
                return
            end

            -- Send the value
            local subject               = fields[key]
            if subject then
                -- BehaviorSubject
                if isObjectType(subject, BehaviorSubject) then
                    return subject:OnNext(value)

                -- Reactive
                elseif type(value) == "table" and getmetatable(value) == nil then
                    local sfields       = rawget(subject, Reactive)
                    for sname in pairs(sfields) do
                        subject[sname]  = value[sname]
                    end

                    for k, v in pairs(value) do
                        if not sfields[k] and type(k) == "string" and k ~= "" and v ~= nil and type(v) ~= "function" then
                            sfields[k]  = reactive(v)
                        end
                    end

                    return

                -- Not valid
                else
                    error("The reactive field " .. tostring(key) .. " is a reactive table, only accept table value", 2)
                end
            end

            -- New reactive - hash key only
            if type(key) == "string" and key ~= "" and value ~= nil and type(value) ~= "function" then
                fields[key]             = reactive(value)
                return
            end

            error("The reactive field " .. tostring(key) .. " can't be defined", 2)
        end

        --- Gets the subject
        function __call(self, key)
            local subject               =  rawget(self, Reactive)[key]
            if subject ~= nil then
                return isObjectType(subject, BehaviorSubject) and subject or nil
            else
                local fields            = rawget(self, Reactive)

                -- New reactive used for subscribe
                if type(key) == "string" and key ~= ""  then
                    fields[key]         = reactive(nil)
                    return fields[key]
                end
            end
        end
    end)

    --- Register as keyword
    export                              {
        type                            = type,
        pcall                           = pcall,
        error                           = error,
        tostring                        = tostring,
        getmetatable                    = getmetatable,
        isSubType                       = Class.IsSubType,
        isObjectType                    = Class.IsObjectType,
        isarray                         = Toolset.isarray,
        isValueType                     = Class.IsValueType,

        IObservable, Reactive, ReactiveList, BehaviorSubject, Date, TimeSpan
    }

    Environment.RegisterRuntimeKeyword  {
        --- Wrap the target value to a Reactive(for table or object), ReactiveList(for list) or BehaviorSubjcet(for value)
        reactive                        = function(value, silent)
            if value == nil then        return Reactive() end

            -- Check the value
            local tval                  = type(value)
            if tval == "table" then
                local cls               = getmetatable(value)

                if cls then
                    -- Already wrap
                    if isSubType(cls, Reactive) or isSubType(cls, ReactiveList) or isSubType(cls, BehaviorSubject) then
                        return value

                    -- wrap the observable or value type as behavior subject
                    elseif isSubType(cls, IObservable) or isValueType(cls) then
                        return BehaviorSubject(value)

                    -- wrap List or Array to reactive list
                    elseif isSubType(cls, List) then
                        return ReactiveList(value)
                    end

                -- wrap array to reactive list
                elseif isarray(value) then
                    return ReactiveList(value)

                -- wrap the value no matter class or object
                else
                    local ok, res       = pcall(Reactive, value)
                    if not ok and not silent then error(tostring(res), 2) end
                    return res
                end

            -- wrap scalar value to behavior subject
            elseif tval == "number" or tval == "string" or tval == "boolean" then
                return BehaviorSubject(value)
            end

            if not silent then
                error("Usage: reactive(data[, silent]) - The data must be a table or scalar value", 2)
            end
        end
    }
end)