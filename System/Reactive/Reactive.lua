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
                    if type(k) == "string" and k ~= "" and type(value) ~= "function" then
                        if isObjectType(v, BehaviorSubject) then
                            fields[k]   = v
                        else
                            fields[k]   = BehaviorSubject(v)
                        end
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
            if subject then return subject:GetValue() end
        end

        --- Send the new value
        function __newindex(self, key, value)
            local fields                = rawget(self, Reactive)
            local subject               = fields[key]
            if subject then return subject:OnNext(value) end

            if type(key) == "string" and key ~= "" and value ~= nil and type(value) ~= "function" then
                fields[key]             = BehaviorSubject(value)
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
    Environment.RegisterRuntimeKeyword {
        reactive                        = Reactive
    }
end)