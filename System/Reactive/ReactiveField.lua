--===========================================================================--
--                                                                           --
--                       System.Reactive.ReactiveField                        --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2024/05/22                                               --
-- Update Date  :   2025/02/22                                               --
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
            pcall                       = pcall,
            error                       = error,
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
            local raw                   = self[1]
            local value
            if raw then
                value                   = raw[self[2]]
            else
                value                   = nil
            end
            if rawget(self, 3) == value then return end

            rawset(self, 3, value)
            return onnext(self, value)
        end

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        --- Subscribe the observer
        function Subscribe(self, ...)
            local ok, sub, observer     = pcall(subscribe, self, ...)
            if not ok then error(sub, 2) end
            observer:OnNext(self[3])
            return sub, observer
        end

        --- Provides the observer with new data
        if not valtype or Platform.TYPE_VALIDATION_DISABLED and getmetatable(valtype).IsImmutable(valtype) then
            function OnNext(self, val)
                local raw               = self[1]
                if not raw then return end

                -- save
                self[3]                 = val
                raw[self[2]]            = val
                return onnext(self, val)
            end
        else
            local valid                 = getmetatable(valtype).ValidateValue
            function OnNext(self, val)
                local raw               = self[1]
                if not raw then return end

                local ret, msg          = valid(valtype, val)
                if msg then return onerror(self, geterrormessage(msg, "value")) end

                -- save
                self[3]                 = ret
                raw[self[2]]            = ret
                return onnext(self, ret)
            end
        end

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- Whether always connect the observable
        property "KeepAlive"            { type = Boolean, default = true }

        --- The reactive container
        property "Container"            { type = Table,   field = 1, handler = refresh }

        --- The field
        property "Field"                { type = String,  field = 2, set = false }

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