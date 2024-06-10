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
                local container         = self[1]
                container               = container and container:ToRaw()
                if container then
                    local field         = self[2]
                    if field then
                        container[field]= val
                    end
                end

                return onnext(self, val)
            end
        else
            local valid                 = getmetatable(valtype).ValidateValue
            function OnNext(self, val)
                local ret, msg          = valid(valtype, val)
                if msg then return onerror(self, geterrormessage(msg, "value")) end
                self[3]                 = ret

                -- save to the container
                local container         = self[1]
                container               = container and container:ToRaw()
                if container then
                    local field         = self[2]
                    if field then
                        container[field]= ret
                    end
                end

                return onnext(self, ret)
            end
        end

        --- Sets the raw value
        __Arguments__{ IObservable }
        function SetRaw(self, observable)
            self.Observable             = observable
        end

        __Arguments__{ (valtype or Any)/nil }
        function SetRaw(self, value)
            self.Observable             = nil
            self.Value                  = value
        end

        --- Gets the raw value
        function ToRaw(self)            return self[3] end

        --- Update the value by the container's field
        function Refresh(self)
            local container             = self[1]
            local field                 = self[2]
            container                   = container and container:ToRaw()
            if container and field then
                if self.Observable then
                    raw[field]          = self[3]
                else
                    local value         = raw[field]
                    if self[3] == value then return end

                    self[3]             = value
                    return onnext(self, value)
                end

            -- otherwise
            elseif self[3] ~= nil and not self.Observable then
                self[3]                 = nil
                return onnext(self, nil)
            end
        end

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- Whether always connect the observable
        property "KeepAlive"            { type = Boolean,  default = true }

        --- The reactive container
        property "Container"            { type = Reactive, field = 1, handler = "Refresh" }

        --- The field
        property "Field"                { type = String,   field = 2, handler = "Refresh" }

        --- The current value, use handler not set to detect the value change
        property "Value"                { type = valtype,  field = 3, handler = "OnNext" }

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        -- Binding the behavior subject to a reactive object's field
        __Arguments__{ Reactive, String }
        function __ctor(self, react, field)
            self[1]                     = react
            self[2]                     = field
            super(self)
            self:Refresh()
        end

        __Arguments__{ Reactive, String, IObservable }
        function __ctor(self, react, field, observable)
            self[1]                     = react
            self[2]                     = field
            super(self, observable)
        end
    end)
end)