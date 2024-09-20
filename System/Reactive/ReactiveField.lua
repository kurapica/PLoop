--===========================================================================--
--                                                                           --
--                       System.Reactive.ReactiveField                        --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2024/05/22                                               --
-- Update Date  :   2024/09/20                                               --
-- Version      :   2.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    --- Represents the field in reactive objects
    __Sealed__()
    __Arguments__{ AnyType/nil }
    class"System.Reactive.ReactiveField"(function(_ENV, valtype)
        inherit "Subject"
        extend "IValueWrapper" "IReactive"

        export                          {
            rawset                      = rawset,
            rawget                      = rawget,
            subscribe                   = Subject.Subscribe,
            onnext                      = Subject.OnNext,
            onerror                     = Subject.OnError,
            geterrormessage             = Struct.GetErrorMessage,
            issubtype                   = Class.ValidateValue,

            IObservable
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
        if not valtype or Platform.TYPE_VALIDATION_DISABLED and getmetatable(valtype).IsImmutable(valtype) then
            function OnNext(self, val)
                self[3]                 = val

                -- save to the container
                self[1].Value[self[2]]  = val

                return onnext(self, val)
            end
        else
            local valid                 = getmetatable(valtype).ValidateValue
            function OnNext(self, val)
                local ret, msg          = valid(valtype, val)
                if msg then return onerror(self, geterrormessage(msg, "value")) end
                self[3]                 = ret

                -- save to the container
                self[1].Value[self[2]]  = ret

                return onnext(self, ret)
            end
        end

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- The reactive container
        property "Container"            { type = Reactive, set = false, field = 1 }

        --- The field
        property "Field"                { type = String,   set = false, field = 2 }

        --- Whether always connect the observable
        property "KeepAlive"            { type = Boolean,  default = true }

        --- The current value, use handler not set to detect the value change
        property "Value"                { type = valtype,  field = 3, handler = "OnNext" }

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        -- Binding the behavior subject to a reactive object's field
        __Arguments__{ Reactive, String, IObservable/nil }
        function __ctor(self, react, field, observable)
            self[1]                     = react
            self[2]                     = field
            super(self, observable)

            -- Refresh
            local container             = react.Value
            if observable then
                raw[field]              = rawget(self, 3)
            else
                local value             = raw[field]
                if self[3] == value then return end

                self[3]                 = value
                return onnext(self, value)
            end
        end
    end)
end)