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

        local function refresh(self)
            -- clear the observable since it binds in this for the old container field
            self.Observable             = nil

            -- update the value without data push
            local value                 = self[1][self[2]]
            if rawget(self, 3) == value then return end

            rawset(self, 3, value)
            return onnext(self, value)
        end

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
                -- save
                self[3]                 = val
                self[1][self[2]]        = val
                return onnext(self, val)
            end
        else
            local valid                 = getmetatable(valtype).ValidateValue
            function OnNext(self, val)
                local ret, msg          = valid(valtype, val)
                if msg then return onerror(self, geterrormessage(msg, "value")) end

                -- save
                self[3]                 = ret
                self[1][self[2]]        = ret
                return onnext(self, ret)
            end
        end

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- Whether always connect the observable
        property "KeepAlive"            { type = Boolean, default = true }

        --- The reactive container
        property "Container"            { type = Table,   field = 1, handler = refresh, require = true }

        --- The field
        property "Field"                { type = String,  field = 2, handler = refresh, require = true }

        --- The current value, use handler not set to detect the value change
        property "Value"                { type = valtype, field = 3, handler = "OnNext" }

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        -- Binding the behavior subject to a reactive object's field
        __Arguments__{ Table, String, IObservable/nil }
        function __ctor(self, container, field, observable)
            -- init without observable
            super(self)

            rawset(self, 1, container)
            rawset(self, 2, field)
            refresh(self)

            -- binding later
            self.Observable             = observable
        end
    end)
end)