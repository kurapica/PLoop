--===========================================================================--
--                                                                           --
--                              System.Reactive                              --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2023/04/20                                               --
-- Update Date  :   2023/04/20                                               --
-- Version      :   1.0.0                                                    --
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

            Class, Reactive, Property
        }

        local reactiveMap               = Toolset.newtable(true)
        local setObjectProp             = function(self, key, value) self[key] = value end

        -----------------------------------------------------------------------
        --                            inner type                             --
        -----------------------------------------------------------------------
        class "BehaviorSubject"         {} -- declare only
        class "__Observable__"          {}

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        __Arguments__{ Table/nil }
        function __ctor(self, init)
            local fields                = {}
            rawset(self, Reactive, fields)

            -- Init
            if init then
                local cls                   = Class.GetObjectClass(init)
                if cls then
                    -- as a proxy
                    local validProp         = Property.Validate
                    local isObservable      = __Observable__.IsObservableProperty
                    local getPropertyOb     = __Observable__.GetPropertyObservable

                    -- wrap all observable properties
                    for name, prop in Class.GetFeatures(cls, true) do
                        if validProp(prop) and isObservable(prop) then
                            local subject   = getPropertyOb(prop, init)
                            if isObjectType(subject, BehaviorSubject) then
                                fields[name]= subject
                            else
                                fields[name]= BehaviorSubject(subject)
                            end
                        end
                    end

                    if not next(fields) then
                        throw("The " .. tostring(cls) .. " class doesn't provide observable properties")
                    end

                    rawset(self, Class, init)
                    reactiveMap[init]       = self
                else
                    -- as init table
                    for k, v in pairs(init) do
                        if type(k) == "string" and k ~= "" and type(v) ~= "function" then
                            fields[k]   = reactive(v)
                        end
                    end
                end
            end
        end

        -- use the wrap for objects
        function __exist(_, init)
            return init and reactiveMap[init]
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
                if isObjectType(subject, BehaviorSubject) then
                    return subject:OnNext(value)
                else
                    if type(value) == "table" and getmetatable(value) == nil then
                        local sfields   = rawget(subject, Reactive)
                        for sname in pairs(sfields) do
                            subject[sname] = value[sname]
                        end

                        for k, v in pairs(value) do
                            if not sfields[k] and type(k) == "string" and k ~= "" and v ~= nil and type(v) ~= "function" then
                                sfields[k] = reactive(v)
                            end
                        end

                        return
                    else
                        error("The reactive field " .. tostring(key) .. " is a reactive table, only accept table value", 2)
                    end
                end
            end

            if type(key) == "string" and key ~= "" and value ~= nil and type(value) ~= "function" then
                fields[key]             = reactive(value)
                return
            end

            error("The reactive field " .. tostring(key) .. " can't be defined", 2)
        end

        --- Gets the subject
        function __call(self, key)
            local subject               =  rawget(self, Reactive)[key]
            return isObjectType(subject, BehaviorSubject) and subject or nil
        end
    end)

    --- Register as keyword
    export                              {
        type                            = type,
        pcall                           = pcall,
        error                           = error,
        tostring                        = tostring,
        isObjectType                    = Class.IsObjectType,

        IObservable, Reactive, BehaviorSubject
    }

    Environment.RegisterRuntimeKeyword  {
        reactive                        = function(value, silent)
            if value == nil then return Reactive() end

            -- Check the value
            local tval                  = type(value)
            if tval == "table" then
                -- don't wrap the reactive object or non behavior subject
                if isObjectType(value, Reactive) or isObjectType(value, BehaviorSubject) then
                    return value

                -- wrap the observable as behavior subject
                elseif isObjectType(value, IObservable) then
                    return BehaviorSubject(value)

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
                error("Usage: reactive(data) - The data must be a table or scalar value", 2)
            end
        end
    }
end)