--===========================================================================--
--                                                                           --
--                       System.Reactive.ReactiveField                        --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2024/05/22                                               --
-- Update Date  :   2024/05/22                                               --
-- Version      :   2.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    --- Represents the field in reactive objects
    __Sealed__()
    __Arguments__{ AnyType/nil }
    class"System.Reactive.ReactiveField"(function(_ENV, valtype)
        inherit "Subject"
        extend "IValueWrapper"

        export {
            subscribe                   = Subject.Subscribe,
            onnext                      = Subject.OnNext,
            onerror                     = Subject.OnError,
            geterrormessage             = Struct.GetErrorMessage,

            RawTable
        }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        --- Subscribe the observer
        function Subscribe(self, ...)
            local subscription, observer= subscribe(self, ...)
            observer:OnNext(self[3])
            return subscription, observer
        end

        --- Provides the observer with new data
        if valtype then
            if Platform.TYPE_VALIDATION_DISABLED and getmetatable(valtype).IsImmutable(valtype) then
                function OnNext(self, val)
                    self[3]             = val
                    return onnext(self, val)
                end
            else
                local valid             = getmetatable(valtype).ValidateValue
                function OnNext(self, val)
                    local ret, msg      = valid(valtype, val)
                    if msg then return onerror(self, geterrormessage(msg, "value")) end
                    self[3]             = ret
                    return onnext(self, ret)
                end
            end
        else
            function OnNext(self, val)
                self[3]                 = val
                return onnext(self, val)
            end
        end

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- Whether always connect the observable
        property "KeepAlive"            { type = Boolean,  default = true }

        --- The reactive container
        property "Container"            { type = Reactive, field = 1 }

        --- The field
        property "Field"                { type = String,   field = 2 }

        --- The current value, use handler not set to detect the value change
        property "Value"                { type = valtype,  field = 3, handler = "OnNext" }

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        -- Binding the behavior subject to a reactive object's field
        __Arguments__{ Reactive, String }
        function __ctor(self, react, field)
            super(self)

            local raw                   = rawget(react, RawTable)

            self[0]                     = 1
            self[1]                     = raw and raw[field]

            subscribe(self, function(value)
                local raw               = rawget(react, RawTable)
                if raw then raw[field]  = value end
            end)
        end
    end)
end)