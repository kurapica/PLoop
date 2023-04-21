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

            IObservable
        }

        -----------------------------------------------------------------------
        --                            inner type                             --
        -----------------------------------------------------------------------
        class "BehaviorSubject"         {}

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        __Arguments__{ Table/nil }
        function __ctor(self, init)
            local fields                = {}
            rawset(self, Reactive, fields)
            if init then
                for k, v in pairs(init) do
                    if type(k) == "string" then
                        if isObjectType(v, IObservable) then
                            fields[k]   = BehaviorSubject()
                            v:Subscribe(fields[k])
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

            if isObjectType(value, IObservable) then
                fields[key]             = BehaviorSubject()
                value:Subscribe(fields[k])
            else
                fields[key]             = BehaviorSubject(value)
            end
        end

        --- Gets the subject
        function __call(self, key)
            return rawget(self, Reactive)[key]
        end
    end)
end)