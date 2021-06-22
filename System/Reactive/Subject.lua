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
    __Sealed__() class "Subject" (function(_ENV)
        extend "System.IObservable" "System.IObserver"

        export { Observer, Dictionary, next = next, type = type, pairs = pairs }

        FIELD_NEW_SUBSCRIBE     = "__Subject_New"

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- The obervable that provides the items
        property "Observable"   { type = IObservable }

        --- The observer that will consume the items
        property "Observers"    { set = false, default = function() return Dictionary() end }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        local function subscribe(self, observer)
            local obs           = self.Observers
            if obs[observer] then return observer end
            local hasobs        = next(obs)

            -- Bind the Unsubscribe event
            local onUnsubscribe
            onUnsubscribe       = function()
                observer.OnUnsubscribe = observer.OnUnsubscribe - onUnsubscribe

                obs[observer]   = nil
                if self.Observable and not next(obs) then self:Unsubscribe() end
            end
            observer.OnUnsubscribe = observer.OnUnsubscribe + onUnsubscribe

            -- Subscribe the subject
            self:Resubscribe()
            if self[FIELD_NEW_SUBSCRIBE] then
                if self[FIELD_NEW_SUBSCRIBE] == true then
                    self[FIELD_NEW_SUBSCRIBE] = {}
                end

                self[FIELD_NEW_SUBSCRIBE][observer] = true
            else
                obs[observer]   = true
            end
            if self.Observable and not hasobs then self.Observable:Subscribe(self) end

            return observer
        end

        --- Notifies the provider that an observer is to receive notifications.
        __Arguments__{ IObserver }
        Subscribe               = subscribe

        __Arguments__{ Callable/nil, Callable/nil, Callable/nil }
        function Subscribe(self, onNext, onError, onCompleted)
            return subscribe(self, Observer(onNext, onError, onCompleted))
        end

        function OnNextCore(self, ...) return self:OnNext(...) end
        function OnErrorCore(self, e)  return self:OnError(e) end
        function OnCompletedCore(self) return self:OnCompleted() end

        --- Provides the observer with new data
        function OnNext(self, ...)
            if not self.IsUnsubscribed then
                self[FIELD_NEW_SUBSCRIBE] = self[FIELD_NEW_SUBSCRIBE] or true

                local onNext    = self.OnNextCore
                for k in self.Observers:GetIterator() do
                    onNext(k, ...)
                end

                local newSubs   = self[FIELD_NEW_SUBSCRIBE]
                if newSubs and type(newSubs) == "table" then
                    for observer in pairs(newSubs) do
                        self.Observers[observer] = true
                    end
                end
                self[FIELD_NEW_SUBSCRIBE] = false
            end
        end

        --- Notifies the observer that the provider has experienced an error condition
        function OnError(self, exception)
            if self.IsUnsubscribed then return end

            local onError       = self.OnErrorCore
            for k in self.Observers:GetIterator() do
                onError(k, exception)
            end
        end

        --- Notifies the observer that the provider has finished sending push-based notifications
        function OnCompleted(self)
            if self.IsUnsubscribed then return end

            local onComp        = self.OnCompletedCore
            for k in self.Observers:GetIterator() do
                onComp(k)
            end
        end

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        __Arguments__{ IObservable, Callable/nil, Callable/nil, Callable/nil }
        function __ctor(self, observable, onNext, onError, onCompleted)
            self[FIELD_NEW_SUBSCRIBE] = false

            self.Observable     = observable
            self.OnNextCore     = onNext
            self.OnErrorCore    = onError
            self.OnCompletedCore= onCompleted
        end

        __Arguments__{ Callable/nil, Callable/nil, Callable/nil }
        function __ctor(self, onNext, onError, onCompleted)
            self[FIELD_NEW_SUBSCRIBE] = false

            self.OnNextCore     = onNext
            self.OnErrorCore    = onError
            self.OnCompletedCore= onCompleted
        end
    end)

    --- Only emits the last value (and only the last value) emitted by the source Observable,
    -- and only after that source Observable completes
    __Sealed__() class "AsyncSubject" (function(_ENV)
        inherit "Subject"

        export { select = select, unpack = _G.unpack or table.unpack }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        --- Provides the observer with new data
        function OnNext(self, ...)
            if not self.IsUnsubscribed then
                self[0]         = select("#", ...)
                for i = 1, self[0] do
                    self[i]     = select(i, ...)
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
    __Sealed__() class "BehaviorSubject" (function(_ENV)
        inherit "Subject"

        export { select = select, max = math.max, unpack = _G.unpack or table.unpack, onNext = Subject.OnNext }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        function Subscribe(self, ...)
            local observer      = super.Subscribe(self, ...)
            if self[0] > 0 then observer:OnNext(unpack(self, 1, self[0])) end
        end

        --- Provides the observer with new data
        function OnNext(self, ...)
            self[0]             = max(1, select("#", ...))
            for i = 1, self[0] do
                self[i]         = select(i, ...)
            end

            onNext(self, ...)
        end

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        __Arguments__{ IObservable, Any * nil }
        function __ctor(self, observable, ...)
            self[0]             = select("#", ...)
            for i = 1, self[0] do
                self[i]         = select(i, ...)
            end

            super(self, observable)
        end

        __Arguments__{ Any * nil }
        function __ctor(self, ...)
            self[0]             = select("#", ...)
            for i = 1, self[0] do
                self[i]         = select(i, ...)
            end

            super(self)
        end
    end)

    --- Emits to an observers only when connect to the observable source
    __Sealed__() class "PublishSubject" (function(_ENV)
        inherit "Subject" extend "IConnectableObservable"

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

        function RefCount(self)
            return Subject(self.PublishObservable)
        end

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        __Arguments__{ IObservable }
        function __ctor(self, observable)
            self.PublishObservable = observable
        end
    end)

    --- Emits to any observer all of the items that were emitted by the source Observable(s), regardless of when the observer subscribes
    __Sealed__() class "ReplaySubject" (function(_ENV)
        inherit "Subject"

        export { Queue, select = select }

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- The replay item count
        property "QueueCount"   { type = Number, default = 0 }

        --- The last values from the source observable
        property "Queue"        { set = false, default = function() return Queue() end }

        --- The max length of the buff size
        property "QueueSize"    { type = Number, default = math.huge }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        function Subscribe(self, ...)
            local observer      = super.Subscribe(self, ...)
            if self.Queue:Peek() then
                local queue     = self.Queue
                local index     = 1

                local count     = queue:Peek(index, 1)
                while count do
                    observer:OnNext(queue:Peek(index + 1, count))
                    index       = index + 1 + count
                    count       = queue:Peek(index, 1)
                end
            end
        end

        --- Provides the observer with new data
        function OnNext(self, ...)
            self.Queue:Enqueue(select("#", ...), ...)
            if self.QueueCount + 1 > self.QueueSize then
                self.Queue:Dequeue(self.Queue:Dequeue())
            else
                self.QueueCount = self.QueueCount + 1
            end
            super.OnNext(self, ...)
        end

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        __Arguments__{ IObservable, Number/nil }
        function __ctor(self, observable, max)
            self.QueueSize      = max
            super(self, observable)
        end

        __Arguments__{ Number/nil }
        function __ctor(self, max)
            self.QueueSize      = max
            super(self)
        end
    end)
end)