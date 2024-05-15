--===========================================================================--
--                                                                           --
--                          System.Reactive.Subject                          --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2019/12/01                                               --
-- Update Date  :   2024/05/09                                               --
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

            -- the core subscribe
            subscribe                   = function (self, observer, subscription)
                -- Check existed subscription
                local obs               = self.__observers
                local exist             = obs[observer]
                if exist then
                    if exist ~= subscription and not exist.IsUnsubscribed then exist:Dispose() end
                    obs[observer]       = subscription
                    return subscription, observer
                end
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
        function OnError(self, ...)
            self.__newsubject           = self.__newsubject or true

            local obs                   = self.__observers
            local becold                = false
            for ob, sub in pairs(obs) do
                if not sub.IsUnsubscribed then
                    ob:OnError(...)
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

        --- Notifies the observer that the provider has finished sending push-based notifications
        function OnCompleted(self)
            local obs                   = self.__observers
            self.__observers            = newtable(false, true)
            for ob, sub in pairs(obs) do
                if not sub.IsUnsubscribed then
                    ob:OnCompleted()
                end
            end

            if not (self.KeepAlive or next(self.__observers)) then
                self.Subscription       = nil
            end
        end

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        __Arguments__{ IObservable/nil }
        function __ctor(self, observable)
            self.__newsubject           = false
            self.__observers            = newtable(false, true)
            self.Observable             = observable
        end

        -----------------------------------------------------------------------
        --                          de-constructor                           --
        -----------------------------------------------------------------------
        function __dtor(self)
            self.Observable             = nil
        end
    end)

    --- Only emits the last value (and only the last value) emitted by the source Observable,
    -- and only after that source Observable completes
    __Sealed__()
    class "AsyncSubject"                (function(_ENV)
        inherit "Subject"

        export { max = math.max, select = select, unpack = _G.unpack or table.unpack, onnext = Subject.OnNext, oncompleted= Subject.OnCompleted }

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
            if self[0] > 0 then onnext(self, unpack(self, 1, self[0])) end
            return oncompleted(self)
        end
    end)

    --- Emitting the item most recently emitted by the source Observable (or a seed/default value
    -- if none has yet been emitted) and then continues to emit any other items emitted later by the source Observable
    __Sealed__()
    __Arguments__{ AnyType/nil }
    class "BehaviorSubject"             (function(_ENV, valtype)
        inherit "Subject"

        export {
            max                         = math.max,
            select                      = select,
            rawget                      = rawget,
            unpack                      = _G.unpack or table.unpack,
            subscribe                   = Subject.Subscribe,
            onnext                      = Subject.OnNext,
            onerror                     = Subject.OnError,
            isobjecttype                = Class.IsObjectType,
            geterrormessage             = Struct.GetErrorMessage,
            getvalue                    = function(self)
                if isobjecttype(self, BehaviorSubject) then
                    return self[1]
                else
                    return self
                end
            end,
            hanldercontainer            = function(self)
                local container         = self.__container
                local field             = self.__field
                if container and field then
                    self.Value          = container[field]
                else
                    self.Value          = nil
                end
            end

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

                    local container     = rawget(self, "__container")
                    if container then
                        container[self.__field] = val
                    end

                    return onnext(self, val)
                end

            else
                local valid             = getmetatable(valtype).ValidateValue
                function OnNext(self, val)
                    local ret, msg      = valid(valtype, val)
                    if msg then return onerror(self, geterrormessage(msg, "value")) end

                    self[0]             = 1
                    self[1]             = ret

                    local container     = rawget(self, "__container")
                    if container then
                        container[self.__field] = ret
                    end

                    return onnext(self, ret)
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

                local container         = rawget(self, "__container")
                if container then
                    container[self.__field] = self[1]
                end

                return onnext(self, ...)
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
            return onerror(self, ...)
        end

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- Whether always connect the observable
        property "KeepAlive"            { type = Boolean, default = true }

        --- The current value, use handler not set to detect the value change
        property "Value"                { type = valtype, field = 1, handler = function(self, new) return self:OnNext(new) end }

        --- The container of the value
        property "Container"            { type = Table, field = "__container", handler = hanldercontainer }

        --- The field of the value
        property "Field"                { type = String, field = "__field", handler = hanldercontainer }

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
            super(self)
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
        function __add(a, b)            return getvalue(a) + getvalue(b) end

        -- the subtraction operation
        function __sub(a, b)            return getvalue(a) - getvalue(b) end

        -- the multiplication operation
        function __mul(a, b)            return getvalue(a) * getvalue(b) end

        -- the division operation
        function __div(a, b)            return getvalue(a) / getvalue(b) end

        -- the modulo operation
        function __mod(a, b)            return getvalue(a) % getvalue(b) end

        -- the exponentiation operation
        function __pow(a, b)            return getvalue(a) ^ getvalue(b) end

        -- the negation operation
        function __unm(a)               return - getvalue(a) end

        -- the concatenation operation
        function __concat(a, b)         return getvalue(a) .. getvalue(b) end

        -- the length operation, those won't works in 5.1
        function __len(a)               return #getvalue(a) end

        -- the equal operation
        function __eq(a, b)             return getvalue(a) == getvalue(b) end

        -- the less than operation
        function __lt(a, b)             return getvalue(a) < getvalue(b) end

        -- the less equal operation
        function __le(a, b)             return getvalue(a) <= getvalue(b) end

        if _G._VERSION and tonumber(_G._VERSION:match("[%d%.]+$")) * 10 >= 53 then
            Toolset.loadsnippet([[
                -- the floor division operation
                function __idiv(a, b)           return getvalue(a) // getvalue(b) end

                -- the bitwise AND operation
                function __band(a, b)           return getvalue(a) & getvalue(b) end

                -- the bitwise OR operation
                function __bor(a, b)            return getvalue(a) | getvalue(b) end

                -- the bitwise exclusive OR operation
                function __bxor(a, b)           return getvalue(a) ~ getvalue(b) end

                -- the bitwise NOToperation
                function __bnot(a)              return ~getvalue(a) end

                -- the bitwise left shift operation
                function __shl(a, b)            return getvalue(a) << getvalue(b) end

                -- the bitwise right shift operation
                function __shr(a, b)            return getvalue(a) >> getvalue(b) end
            ]], "BehaviorSubject_Patch_53", _ENV)()
        end
    end)

    --- Emits to an observers only when connect to the observable source
    __Sealed__()
    class "PublishSubject"              (function(_ENV)
        inherit "Subject"
        extend "IConnectableObservable"

        export { Subject, Subscription }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        function Connect(self)
            self.__pubsub               = self.__pubsub or self.__pubobs:Subscribe(self, Subscription())
            return self
        end

        --- Make a Connectable Observable behave like an ordinary Observable
        function RefCount(self)
            return Subject(self.__pubobs)
        end

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        __Arguments__{ IObservable }
        function __ctor(self, observable)
            self.__pubobs               = observable
            self.__pubsub               = false
            super(self)
        end

        -----------------------------------------------------------------------
        --                          de-constructor                           --
        -----------------------------------------------------------------------
        function __dtor(self)
            return self.__pubsub and self.__pubsub:Dispose()
        end
    end)

    --- Emits to any observer all of the items that were emitted by the source Observable(s), regardless of when the observer subscribes
    __Sealed__()
    class "ReplaySubject"               (function(_ENV)
        inherit "Subject"

        export { Queue, select = select, onnext = Subject.OnNext, subscribe = Subject.Subscribe }

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- The replay item count
        property "QueueCount"           { type = Number, default = 0 }

        --- The last values from the source observable
        property "Queue"                { set = false,   default = function() return Queue() end }

        --- The max length of the buff size
        property "QueueSize"            { type = Number, default = math.huge }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        function Subscribe(self, ...)
            local subscription, observer= subscribe(self, ...)
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
            return onnext(self, ...)
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