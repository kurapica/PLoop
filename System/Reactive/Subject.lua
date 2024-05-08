--===========================================================================--
--                                                                           --
--                          System.Reactive.Subject                          --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2019/12/01                                               --
-- Update Date  :   2023/10/20                                               --
-- Version      :   2.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Reactive"

    --- A bridge or proxy that acts both as an observer and as an Observable
    __Sealed__()
    __NoNilValue__(false):AsInheritable()
    __NoRawSet__(false):AsInheritable()
    class "Subject"                     (function(_ENV)
        extend "System.IObservable" "System.IObserver"

        export                          {
            next                        = next,
            type                        = type,
            pairs                       = pairs,
            newtable                    = Toolset.newtable,
            isObjectType                = Class.IsObjectType,

            -- the core subscribe
            subscribe                   = function (self, observer, subscription)
                -- Check existed subscription
                local obs               = self.__observers
                if obs[observer] and not obs[observer].IsUnsubscribed then return obs[observer], observer end
                local iscold            = not (self.KeepAlive or next(obs))

                subscription            = subscription or observer.Subscription

                -- Subscribe the subject
                if self.__newsubject then
                    if self.__newsubject == true then
                        self.__newsubject = {}
                    end

                    self.__newsubject[observer] = subscription
                else
                    obs[observer]       = subscription
                end

                -- Start the subscription if cold
                if iscold and self.Observable then
                    self.Subscription   = self.Observable:Subscribe(self, Subscription())
                end

                return subscription, observer
            end,

            Observer, Dictionary, Subscription
        }

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- Whether always connect the observable
        __Abstract__()
        property "KeepAlive"            { type = Boolean }

        --- The observable that the subject subscribed
        property "Observable"           {
            type                        = IObservable,
            field                       = "__observable",
            handler                     = function(self, new, old)
                self.Subscription       = new and (self.KeepAlive or next(self.__observers)) and new:Subscribe(self, Subscription()) or nil
            end
        }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        --- Notifies the provider that an observer is to receive notifications.
        __Arguments__{ IObserver, Subscription/nil }
        Subscribe                       = subscribe

        __Arguments__{ Callable/nil, Callable/nil, Callable/nil, Subscription/nil }
        function Subscribe(self, onNext, onError, onCompleted, subscription)
            return subscribe(self, Observer(onNext, onError, onCompleted, subscription))
        end

        --- Provides the observer with new data
        function OnNext(self, ...)
            self.__newsubject           = self.__newsubject or true

            local obs                   = self.__observers
            local becold                = false
            for ob, sub in pairs(obs) do
                if not sub.IsUnsubscribed then
                    ob:OnNext(...)
                else
                    obs[ob]             = nil
                    becold              = true
                end
            end

            -- Register the new observers
            local newSubs               = self.__newsubject
            self.__newsubject           = false
            if newSubs and newSubs ~= true then
                for ob, sub in pairs(newSubs) do
                    if not sub.IsUnsubscribed then
                        obs[ob]         = sub
                    end
                end
            end

            -- be cold
            if becold and not (self.KeepAlive or next(obs)) then
                self.Subscription       = nil
            end
        end

        --- Notifies the observer that the provider has experienced an error condition
        function OnError(self, exception)
            local obs                   = self.__observers
            local becold                = false
            for ob, sub in pairs(obs) do
                if not sub.IsUnsubscribed then
                    ob:OnError(exception)
                else
                    obs[ob]             = nil
                    becold              = true
                end
            end

            -- be cold
            if becold and not (self.KeepAlive or next(obs)) then
                self.Subscription       = nil
            end
        end

        --- Notifies the observer that the provider has finished sending push-based notifications
        function OnCompleted(self)
            local obs                   = self.__observers
            self.__observers            = newtable(false, true)
            for ob, sub in pairs(obs) do
                if not sub.IsUnsubscribed then
                    ob:OnCompleted()
                end
            end

            if not self.KeepAlive then
                self.Subscription       = nil
            end
        end

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        __Arguments__{ IObservable/nil }
        function __ctor(self, observable)
            self.Observable             = observable
            self.__newsubject           = false
            self.__observers            = newtable(false, true)
        end

        -----------------------------------------------------------------------
        --                          de-constructor                           --
        -----------------------------------------------------------------------
        function __dtor(self)
            self.Observable             = nil
            self.__observers            = nil
        end
    end)

    --- Only emits the last value (and only the last value) emitted by the source Observable,
    -- and only after that source Observable completes
    __Sealed__()
    class "AsyncSubject"                (function(_ENV)
        inherit "Subject"

        export { max = math.max, select = select, unpack = _G.unpack or table.unpack }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        --- Provides the observer with new data
        function OnNext(self, ...)
            local length                = max(1, select("#", ...))
            self[0]                     = length
            if length <= 2 then
                self[1], self[2]        = ...
            else
                for i = 1, length, 2 do
                    self[i], self[i+1]  = select(i, ...)
                end
            end
        end

        --- Notifies the observer that the provider has finished sending push-based notifications
        function OnCompleted(self)
            if self[0] > 0 then super.OnNext(self, unpack(self, 1, self[0])) end
            super.OnCompleted(self)
        end
    end)

    --- Emitting the item most recently emitted by the source Observable (or a seed/default value
    -- if none has yet been emitted) and then continues to emit any other items emitted later by the source Observable
    __Sealed__()
    __Arguments__{ AnyType/nil }
    class "BehaviorSubject"             (function(_ENV, valtype)
        inherit "Subject"

        export {
            select                      = select,
            max                         = math.max,
            rawget                      = rawget,
            unpack                      = _G.unpack or table.unpack,
            onNext                      = Subject.OnNext,
            subscribe                   = Subject.Subscribe,
            onError                     = Subject.OnError,
            isObjectType                = Class.IsObjectType,
            geterrormessage             = Struct.GetErrorMessage,
            getValue                    = function(self)
                if isObjectType(self, BehaviorSubject) then
                    return (unpack(self, 1, self[0]))
                else
                    return self
                end
            end,

            BehaviorSubject
        }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        --- Subscribe the observer
        function Subscribe(self, ...)
            local subscription, observer= subscribe(self, ...)
            local length                = self[0]
            if length > 0 then
                observer:OnNext (unpack(self, 1, length))
            elseif length < 0 then
                observer:OnError(unpack(self, 1,-length))
            end
            return subscription, observer
        end

        --- Provides the observer with new data
        if valtype then
            if Platform.TYPE_VALIDATION_DISABLED and getmetatable(valtype).IsImmutable(valtype) then
                function OnNext(self, val)
                    self[0]             = 1
                    self[1]             = val

                    if rawget(self, "__container") then
                        self.__container[self.__field] = val
                    end

                    return onNext(self, val)
                end

            else
                local valid             = getmetatable(valtype).ValidateValue
                function OnNext(self, val)
                    local ret, msg      = valid(valtype, val)
                    if msg then return onError(self, geterrormessage(msg, "value")) end

                    self[0]             = 1
                    self[1]             = ret

                    if rawget(self, "__container") then
                        self.__container[self.__field] = ret
                    end

                    return onNext(self, ret)
                end
            end
        else
            function OnNext(self, ...)
                local length            = max(1, select("#", ...))
                self[0]                 = length

                if length <= 2 then
                    self[1], self[2]    = ...
                else
                    for i = 1, length, 2 do
                        self[i], self[i+1]  = select(i, ...)
                    end
                end

                if rawget(self, "__container") then
                    self.__container[self.__field] = self[1]
                end

                return onNext(self, ...)
            end
        end

        -- Send the error message
        function OnError(self, ...)
            local length                = max(1, select("#", ...))
            self[0]                     =-length

            if length <= 2 then
                self[1], self[2]        = ...
            else
                for i = 1, length, 2 do
                    self[i], self[i+1]  = select(i, ...)
                end
            end
            return onError(self, ...)
        end

        --- Gets the current value
        function GetValue(self)         return self[1] end

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- Whether always connect the observable
        property "KeepAlive"            { type = Boolean, default = true }

        --- The current value
        property "Value"                { get = GetValue, set = OnNext, type = valtype }

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        -- Generate behavior subject based on other observable
        __Arguments__{ IObservable }
        function __ctor(self, observable)
            self[0]                     = 0
            super(self, observable)
        end

        -- Binding the behavior subject to a container's field
        __Arguments__{ Table, String }
        function __ctor(self, container, field)
            self[0]                     = 1
            self[1]                     = container[field]
            self.__container            = container
            self.__field                = field
        end

        -- Generate behavior subject with init data
        if valtype then
            __Arguments__{ valtype/nil }
        else
            __Arguments__{ Any * 0 }
        end
        function __ctor(self, ...)
            local length                = max(1, select("#", ...))
            self[0]                     = length
            for i = 1, length, 2 do
                self[i], self[i + 1]    = select(i, ...)
            end

            super(self)
        end

        -----------------------------------------------------------------------
        --                            meta-method                            --
        -----------------------------------------------------------------------
        function __tostring(self)       return tostring(self.Value) end

        -- the addition operation
        function __add(a, b)            return getValue(a) + getValue(b) end

        -- the subtraction operation
        function __sub(a, b)            return getValue(a) - getValue(b) end

        -- the multiplication operation
        function __mul(a, b)            return getValue(a) * getValue(b) end

        -- the division operation
        function __div(a, b)            return getValue(a) / getValue(b) end

        -- the modulo operation
        function __mod(a, b)            return getValue(a) % getValue(b) end

        -- the exponentiation operation
        function __pow(a, b)            return getValue(a) ^ getValue(b) end

        -- the negation operation
        function __unm(a)               return - getValue(a) end

        -- the concatenation operation
        function __concat(a, b)         return getValue(a) .. getValue(b) end

        -- the length operation, those won't works in 5.1
        function __len(a)               return #getValue(a) end

        -- the equal operation
        function __eq(a, b)             return getValue(a) == getValue(b) end

        -- the less than operation
        function __lt(a, b)             return getValue(a) < getValue(b) end

        -- the less equal operation
        function __le(a, b)             return getValue(a) <= getValue(b) end

        if _G._VERSION and tonumber(_G._VERSION:match("[%d%.]+$")) * 10 >= 53 then
            Toolset.loadsnippet([[
                -- the floor division operation
                function __idiv(a, b)           return getValue(a) // getValue(b) end

                -- the bitwise AND operation
                function __band(a, b)           return getValue(a) & getValue(b) end

                -- the bitwise OR operation
                function __bor(a, b)            return getValue(a) | getValue(b) end

                -- the bitwise exclusive OR operation
                function __bxor(a, b)           return getValue(a) ~ getValue(b) end

                -- the bitwise NOToperation
                function __bnot(a)              return ~getValue(a) end

                -- the bitwise left shift operation
                function __shl(a, b)            return getValue(a) << getValue(b) end

                -- the bitwise right shift operation
                function __shr(a, b)            return getValue(a) >> getValue(b) end
            ]], "BehaviorSubject_Patch_53", _ENV)()
        end
    end)

    --- Emits to an observers only when connect to the observable source
    __Sealed__()
    class "PublishSubject"              (function(_ENV)
        inherit "Subject"
        extend "IConnectableObservable"

        export { Observable, Subject, Subscription }

        field {
            __publicsubscription        = false
        }

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        property "PublishObservable"    { type = IObservable }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        function Connect(self)
            if self.__publicsubscription then return end
            self.__publicsubscription   = Subscription()
            self.PublishObservable:Subscribe(self, self.__publicsubscription)
            return self
        end

        --- Make a Connectable Observable behave like an ordinary Observable
        function RefCount(self)
            return Subject(self.PublishObservable)
        end

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        __Arguments__{ IObservable }
        function __ctor(self, observable)
            self.PublishObservable      = observable
            super(self)
        end

        -----------------------------------------------------------------------
        --                          de-constructor                           --
        -----------------------------------------------------------------------
        function __dtor(self)
            return self.__publicsubscription and self.__publicsubscription:Dispose()
        end
    end)

    --- Emits to any observer all of the items that were emitted by the source Observable(s), regardless of when the observer subscribes
    __Sealed__()
    class "ReplaySubject"               (function(_ENV)
        inherit "Subject"

        export { Queue, select = select, onNext = Subject.OnNext }

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- The replay item count
        property "QueueCount"           { type = Number, default = 0 }

        --- The last values from the source observable
        property "Queue"                { set = false, default = function() return Queue() end }

        --- The max length of the buff size
        property "QueueSize"            { type = Number, default = math.huge }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        function Subscribe(self, ...)
            local subscription, observer= super.Subscribe(self, ...)
            if self.Queue:Peek() then
                local queue             = self.Queue
                local index             = 1

                local count             = queue:Peek(index, 1)
                while count and not subscription.IsUnsubscribed do
                    observer:OnNext(queue:Peek(index + 1, count))
                    index               = index + 1 + count
                    count               = queue:Peek(index, 1)
                end
            end
            return subscription, observer
        end

        --- Provides the observer with new data
        function OnNext(self, ...)
            self.Queue:Enqueue(select("#", ...), ...)
            if self.QueueCount + 1 > self.QueueSize then
                self.Queue:Dequeue(self.Queue:Dequeue())
            else
                self.QueueCount         = self.QueueCount + 1
            end
            return onNext(self, ...)
        end

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        __Arguments__{ IObservable, Number/nil }
        function __ctor(self, observable, max)
            self.QueueSize              = max
            super(self, observable)
        end

        __Arguments__{ Number/nil }
        function __ctor(self, max)
            self.QueueSize              = max
            super(self)
        end
    end)
end)