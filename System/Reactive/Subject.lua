--===========================================================================--
--                                                                           --
--                          System.Reactive.Subject                          --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2019/12/01                                               --
-- Update Date  :   2019/12/01                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Reactive"

    --- A bridge or proxy that acts both as an observer and as an Observable
    __Sealed__()
    __NoNilValue__(false):AsInheritable()
    __NoRawSet__(false):AsInheritable()
    class "Subject"                     (function(_ENV)
        extend "System.IObservable" "System.IObserver"

        export { Observer, Dictionary, ISubscription, next = next, type = type, pairs = pairs }

        local function onNextDefault(self, ...) return self:OnNext(...) end
        local function onErrorDefault(self, e)  return self:OnError(e) end
        local function onCompletedDefault(self) return self:OnCompleted() end

        field {
            __newsubject                = false, -- The new subject cache
            __observable                = false, -- The data source
            __subscription              = false, -- The subscription to the __observable
            __observers                 = {},    -- The observers
            __onNext                    = onNextDefault,
            __onError                   = onErrorDefault,
            __onComp                    = onCompletedDefault,
        }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        local function subscribe(self, observer)
            -- Check existed subscription
            local obs                   = self.__observers
            if obs[observer] and not obs[observer].IsUnsubscribed then
                return obs[observer], observer
            end

            -- Create the subscription
            local subscription          = ISubscription(function()
                -- un-subscribe
                obs[observer]           = nil

                -- Remove the register
                if self.__newsubject and self.__newsubject ~= true and self.__newsubject[observer] then
                    self.__newsubject[observer] = nil

                -- With no observers, there is no need to keep subscription
                elseif self.__subscription and not next(obs) then
                    self.__subscription:Dispose()
                    self.__subscription = false
                end
            end)

            -- Subscribe the subject
            if self.__newsubject then
                if self.__newsubject == true then
                    self.__newsubject   = {}
                end

                self.__newsubject[observer] = subscription
            else
                obs[observer]           = subscription
            end

            -- Start the subscription if needed
            if not self.__subscription and self.__observable then
                self.__subscription     = self.__observable:Subscribe(self)
            end

            return subscription, observer
        end

        --- Notifies the provider that an observer is to receive notifications.
        __Arguments__{ IObserver }
        Subscribe                       = subscribe

        __Arguments__{ Callable/nil, Callable/nil, Callable/nil }
        function Subscribe(self, onNext, onError, onCompleted)
            return subscribe(self, Observer(onNext, onError, onCompleted))
        end

        --- Provides the observer with new data
        function OnNext(self, ...)
            self.__newsubject           = self.__newsubject or true

            local onNext                = self.__onNext
            for ob, sub in pairs(self.__observers) do
                if not sub.IsUnsubscribed then
                    onNext(ob, ...)
                end
            end

            -- Register the new observers
            local newSubs               = self.__newsubject
            if newSubs and type(newSubs)== "table" then
                for ob, sub in pairs(newSubs) do
                    self.__observers[ob]= sub
                end
            end
            self.__newsubject           = false
        end

        --- Notifies the observer that the provider has experienced an error condition
        function OnError(self, exception)
            local onError               = self.__onError
            for ob, sub in pairs(self.__observers) do
                if not sub.IsUnsubscribed then
                    onError(ob, exception)
                    sub:Dispose()
                end
            end
        end

        --- Notifies the observer that the provider has finished sending push-based notifications
        function OnCompleted(self)
            local onComp                = self.__onComp
            for ob, sub in pairs(self.__observers) do
                if not sub.IsUnsubscribed then
                    onComp(ob, exception)
                    sub:Dispose()
                end
            end
        end

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        __Arguments__{ IObservable, Callable/nil, Callable/nil, Callable/nil }
        function __ctor(self, observable, onNext, onError, onCompleted)
            self.__observable           = observable
            self.__onNext               = onNext or onNextDefault
            self.__onError              = onError or onErrorDefault
            self.__onComp               = onCompleted or onCompletedDefault
        end

        __Arguments__{ Callable/nil, Callable/nil, Callable/nil }
        function __ctor(self, onNext, onError, onCompleted)
            self.__onNext               = onNext or onNextDefault
            self.__onError              = onError or onErrorDefault
            self.__onComp               = onCompleted or onCompletedDefault
        end
    end)

    --- Only emits the last value (and only the last value) emitted by the source Observable,
    -- and only after that source Observable completes
    __Sealed__()
    class "AsyncSubject"                (function(_ENV)
        inherit "Subject"

        export { select = select, unpack = _G.unpack or table.unpack }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        --- Provides the observer with new data
        function OnNext(self, ...)
            self[0]                     = select("#", ...)
            for i = 1, self[0] do
                self[i]                 = select(i, ...)
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
    class "BehaviorSubject"             (function(_ENV)
        inherit "Subject"

        export { select = select, max = math.max, unpack = _G.unpack or table.unpack, onNext = Subject.OnNext, subscribe = Subject.Subscribe, onError = Subject.OnError }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        function Subscribe(self, ...)
            local subscription, observer= subscribe(self, ...)
            local length                = self[0]
            if length > 0 then
                observer:OnNext(unpack(self, 1, length))
            elseif length < 0 then
                observer:OnError(unpack(self, 1, -length))
            end
            return subscription, observer
        end

        --- Provides the observer with new data
        function OnNext(self, ...)
            local length                = max(1, select("#", ...))
            self[0]                     = length

            if length == 1 then
                self[1]                 = ...
            elseif length <= 3 then
                self[1],self[2],self[3] = ...
            else
                for i = 1, length do
                    self[i]             = select(i, ...)
                end
            end

            return onNext(self, ...)
        end

        function OnError(self, ...)
            local length                = max(1, select("#", ...))
            self[0]                     = - length

            if length == 1 then
                self[1]                 = ...
            elseif length <= 3 then
                self[1],self[2],self[3] = ...
            else
                for i = 1, length do
                    self[i]             = select(i, ...)
                end
            end
            return onError(self, ...)
        end

        --- Gets the current value
        function GetValue(self)
            return unpack(self, 1, self[0])
        end

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- The current value
        property "Value"                { get = GetValue, set = OnNext }

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        __Arguments__{ IObservable, Any * 0 }
        function __ctor(self, observable, ...)
            self[0]                     = select("#", ...)
            for i = 1, self[0] do
                self[i]                 = select(i, ...)
            end

            super(self, observable)
        end

        __Arguments__{ Any * 0 }
        function __ctor(self, ...)
            self[0]                     = select("#", ...)
            for i = 1, self[0] do
                self[i]                 = select(i, ...)
            end

            super(self)
        end
    end)

    --- Emits to an observers only when connect to the observable source
    __Sealed__()
    class "PublishSubject"              (function(_ENV)
        inherit "Subject"
        extend "IConnectableObservable"

        export { Observable, Subject }

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        property "PublishObservable"    { type = IObservable }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        function Connect(self)
            self.PublishObservable:Subscribe(self)
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
                while count do
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