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

        export                          {
            subscribe                   = Subject.Subscribe,
            onnext                      = Subject.OnNext,
            onerror                     = Subject.OnError,
            geterrormessage             = Struct.GetErrorMessage,
            toraw                       = Reactive.ToRaw,

            refreshvalue                = function(self)
                local container         = self[1]
                local field             = self[2]
                if container and field then
                    local raw           = toraw(self.Container)
                    if raw then
                        self.Value      = raw[field]
                        return
                    end
                end
                self.Value              = nil
            end,
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
                return onnext(self, val)
            end
        else
            local valid                 = getmetatable(valtype).ValidateValue
            function OnNext(self, val)
                local ret, msg          = valid(valtype, val)
                if msg then return onerror(self, geterrormessage(msg, "value")) end
                self[3]                 = ret
                return onnext(self, ret)
            end
        end

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- Whether always connect the observable
        property "KeepAlive"            { type = Boolean,  default = true }

        --- The reactive container
        property "Container"            { type = Reactive, field = 1, handler = refreshvalue }

        --- The field
        property "Field"                { type = String,   field = 2, handler = refreshvalue }

        --- The current value, use handler not set to detect the value change
        property "Value"                { type = valtype,  field = 3, handler = "OnNext" }

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        -- Binding the behavior subject to a reactive object's field
        __Arguments__{ Reactive, String }
        function __ctor(self, react, field, val)
            super(self)

            local raw                   = toraw(react)

            self[1]                     = react
            self[2]                     = field
            self[3]                     = raw and raw[field]

            -- write back to the container's field
            subscribe(self, function(value)
                local raw               = toraw(react)
                if raw then raw[field]  = value end
            end)
        end
    end)
end)