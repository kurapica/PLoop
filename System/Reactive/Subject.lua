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

        export { Observable, Observer, Dictionary, next = next, type = type, pairs = pairs }

        FIELD_NEW_SUBSCRIBE     = "__Subject_New_Subscribe"

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
            if self.Observers[observer] then return observer end
            local hasobs                = next(self.Observers)

            Observable.From(observer.OnUnsubscribe):Subscribe(function()
                self.Observers[observer]= nil
                if not next(self.Observers) then self:Unsubscribe() end
            end)

            self:Resubscribe()
            if self[FIELD_NEW_SUBSCRIBE] then
                if self[FIELD_NEW_SUBSCRIBE] == true then
                    self[FIELD_NEW_SUBSCRIBE] = {}
                end

                self[FIELD_NEW_SUBSCRIBE][observer] = true
            else
                self.Observers[observer]    = true
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

                self.Observers.Keys:Each(self.OnNextCore, ...)

                if type(self[FIELD_NEW_SUBSCRIBE]) == "table" then
                    for observer in pairs(self[FIELD_NEW_SUBSCRIBE]) do
                        self.Observers[observer] = true
                    end
                end
                self[FIELD_NEW_SUBSCRIBE] = false
            end
        end

        --- Notifies the observer that the provider has experienced an error condition
        function OnError(self, exception) return not self.IsUnsubscribed and self.Observers.Keys:Each(self.OnErrorCore, exception) end

        --- Notifies the observer that the provider has finished sending push-based notifications
        function OnCompleted(self) return not self.IsUnsubscribed and self.Observers.Keys:Each(self.OnCompletedCore) end

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        __Arguments__{ IObservable, Callable/nil, Callable/nil, Callable/nil }
        function __ctor(self, observable, onNext, onError, onCompleted)
            self.Observable     = observable
            self.OnNextCore     = onNext
            self.OnErrorCore    = onError
            self.OnCompletedCore= onCompleted
        end

        __Arguments__{ Callable/nil, Callable/nil, Callable/nil }
        function __ctor(self, onNext, onError, onCompleted)
            self.OnNextCore     = onNext
            self.OnErrorCore    = onError
            self.OnCompletedCore= onCompleted
        end
    end)

    --- Only emits the last value (and only the last value) emitted by the source Observable,
    -- and only after that source Observable completes
    __Sealed__() class "AsyncSubject" (function(_ENV)
        inherit "Subject"

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- The last value from the source observable
        property "LastValue" { }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        --- Provides the observer with new data
        function OnNext(self, ...)
            if not self.IsUnsubscribed then
                self.LastValue = ...
            end
        end

        --- Notifies the observer that the provider has finished sending push-based notifications
        function OnCompleted(self)
            if self.LastValue ~= nil then
                super.OnNext(self, self.LastValue)
            end
            super.OnCompleted(self)
        end
    end)

    --- Emitting the item most recently emitted by the source Observable (or a seed/default value
    -- if none has yet been emitted) and then continues to emit any other items emitted later by the source Observable(
    __Sealed__() class "BehaviorSubject" (function(_ENV)
        inherit "Subject"

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- The last value from the source observable
        property "LastValue" { }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        function Subscribe(self, ...)
            local observer      = super.Subscribe(self, ...)
            if self.LastValue ~= nil then observer:OnNext(self.LastValue) end
        end

        --- Provides the observer with new data
        function OnNext(self, ...)
            self.LastValue      = ...
            super.OnNext(self, ...)
        end

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        __Arguments__{ IObservable, Any/nil }
        function __ctor(self, observable, default)
            self.LastValue      = default
            super(self, observable)
        end

        __Arguments__{ Any/nil }
        function __ctor(self, default)
            self.LastValue      = default
            super(self)
        end
    end)

    --- Emits to an observer only those items that are emitted by the source Observable(s) subsequent to the time of the subscription
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

        export { Queue }

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- The last values from the source observable
        property "Queue"      { set = false, default = function() return Queue() end }

        --- The max length of the buff size
        property "QueueSize"  { type = Number, default = math.huge }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        function Subscribe(self, ...)
            local observer      = super.Subscribe(self, ...)
            if #self.Queue > 0 then
                for _, v in self.Queue:GetIterator() do
                    observer:OnNext(v)
                end
            end
        end

        --- Provides the observer with new data
        function OnNext(self, item)
            self.Queue:Enqueue(item)
            if #self.Queue > self.QueueSize then self.Queue:Dequeue(#self.Queue - self.QueueSize) end
            super.OnNext(self, item)
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