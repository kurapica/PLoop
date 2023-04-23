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
            getmetatable                = getmetatable,
            isObjectType                = Class.IsObjectType,

            IObservable, Reactive
        }

        -----------------------------------------------------------------------
        --                            inner type                             --
        -----------------------------------------------------------------------
        class "BehaviorSubject"         {} -- declare only

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        __Arguments__{ Table/nil }
        function __ctor(self, init)
            local fields                = {}
            rawset(self, Reactive, fields)

            -- Init
            if init then
                for k, v in pairs(init) do
                    if type(k) == "string" and k ~= "" and type(v) ~= "function" then
                        fields[k]       = reactive(v)
                    end
                end
            end
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
        end

        --- Send the new value
        function __newindex(self, key, value)
            local fields                = rawget(self, Reactive)
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
            return rawget(self, Reactive)[key]
        end
    end)

    --- Register as keyword
    export                              {
        type                            = type,
        getmetatable                    = getmetatable,
        isObjectType                    = Class.IsObjectType,
        getObjectClass                  = Class.GetObjectClass,

        Reactive, BehaviorSubject
    }

    Environment.RegisterRuntimeKeyword  {
        reactive                        = function(value)
            if value == nil then return Reactive() end

            -- Check the value
            local tval                  = type(value)
            if tval == "table" then
                if isObjectType(value, Reactive) or isObjectType(value, BehaviorSubject) then
                    return value
                elseif getObjectClass(value) then
                    -- pass
                else
                    return Reactive(value)
                end
            elseif tval == "number" or tval == "string" or tval == "boolean" then
                return BehaviorSubject(value)
            end

            error("Usage: reactive(data) - The data must be a table or scalar value", 2)
        end
    }
end)