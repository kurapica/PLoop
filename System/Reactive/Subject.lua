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

    --- A bridge or proxy that acts as observer and observable
    __Sealed__()
    __AutoCache__{ Inheritable = true }
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
                -- check subscription
                subscription            = subscription or observer.Subscription
                if subscription.IsUnsubscribed then return subscription, observer end

                -- check existed subscription
                local obs               = self.Observers
                local exist             = obs[observer]
                if exist then
                    obs[observer]       = subscription
                    if exist ~= subscription and not exist.IsUnsubscribed then exist:Dispose() end
                    return subscription, observer
                end

                local iscold            = not (self.KeepAlive or next(obs))

                -- subscribe the subject
                local newobs            = self.__newobs
                if newobs then
                    if newobs == true then
                        newobs          = {}
                        self.__newobs   = newobs
                    end

                    newobs[observer]    = subscription
                else
                    obs[observer]       = subscription
                end

                -- start the subscription if cold
                if iscold and self.Observable then
                    self.Subscription   = self.Observable:Subscribe(self, self.Subscription)
                end

                return subscription, observer
            end,

            Observer
        }

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- Whether always connect the observable
        __Abstract__()
        property "KeepAlive"            { type = Boolean }

        --- Whether queue task when publish
        __Abstract__()
        property "UseTaskQueue"         { type = Boolean }

        --- The observable that the subject subscribed
        __Abstract__()
        property "Observable"           {
            type                        = IObservable,
            handler                     = function(self, new, old)
                self.Subscription       = new and (self.KeepAlive or next(self.Observers)) and new:Subscribe(self, Subscription()) or nil
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
            self.__newobs               = self.__newobs or true

            local obs                   = self.Observers
            local becold                = false
            local scheduler             = self.UseTaskQueue and TaskScheduler.Default

            if scheduler then
                for ob, sub in pairs(obs) do
                    if not sub.IsUnsubscribed then
                        scheduler:QueueTask(ob.OnNext, ob, ...)
                    else
                        obs[ob]         = nil
                        becold          = true
                    end
                end
            else
                for ob, sub in pairs(obs) do
                    if not sub.IsUnsubscribed then
                        ob:OnNext(...)
                    else
                        obs[ob]         = nil
                        becold          = true
                    end
                end
            end

            -- Register the new observers
            local newobs                = self.__newobs
            self.__newobs               = false
            if newobs and newobs ~= true then
                for ob, sub in pairs(newobs) do
                    if not sub.IsUnsubscribed then
                        becold          = false
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
            self.__newobs           = self.__newobs or true

            local obs                   = self.Observers
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
            local newsub                = self.__newobs
            self.__newobs               = false
            if newsub and newsub ~= true then
                for ob, sub in pairs(newsub) do
                    if not sub.IsUnsubscribed then
                        becold          = false
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
            local obs                   = self.Observers
            self.Observers              = newtable(false, true)
            for ob, sub in pairs(obs) do
                if not sub.IsUnsubscribed then
                    ob:OnCompleted()
                end
            end

            if not (self.KeepAlive or next(self.Observers)) then
                self.Subscription       = nil
            end
        end

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        __Arguments__{ IObservable/nil }
        function __ctor(self, observable)
            self.__newobs               = false
            self.Observers              = newtable(false, true)
            self.Observable             = observable
        end

        -----------------------------------------------------------------------
        --                          de-constructor                           --
        -----------------------------------------------------------------------
        function __dtor(self)
            self.Observable             = nil
            self.Observers              = nil
        end
    end)

    --- Only emits the last value (and only the last value) emitted by the source Observable,
    -- and only after that source Observable completes
    __Sealed__()
    class "AsyncSubject"                (function(_ENV)
        inherit "Subject"

        export                          {
            max                         = math.max,
            select                      = select,
            unpack                      = _G.unpack or table.unpack,
            onnext                      = Subject.OnNext,
            oncompleted                 = Subject.OnCompleted
        }

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
    class "BehaviorSubject"             (function(_ENV)
        inherit "Subject"

        export                          {
            max                         = math.max,
            select                      = select,
            unpack                      = _G.unpack or table.unpack,
            subscribe                   = Subject.Subscribe,
            onnext                      = Subject.OnNext,
            onerror                     = Subject.OnError,
            pcall                       = pcall,
            error                       = error,
        }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        --- Subscribe the observer
        function Subscribe(self, ...)
            local ok, sub, observer     = pcall(subscribe, self, ...)
            if not ok then error(sub, 2) end
            local length                = self[0] or 0
            if length > 0 then
                observer:OnNext (unpack(self, 1, length))
            elseif length < 0 then
                observer:OnError(self[1])
            end
            return sub, observer
        end

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
            return onnext(self, ...)
        end

        -- Send the error message
        function OnError(self, ex)
            self[0]                     = -1
            self[1]                     = ex
            return onerror(self, ex)
        end

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- Whether always connect the observable
        property "KeepAlive"            { type = Boolean, default = true }

        -- Generate behavior subject based on other observable
        __Arguments__{ IObservable }
        function __ctor(self, observable)
            self[0]                     = 0
            super(self, observable)
        end

        -- Generate behavior subject with init data
        __Arguments__{ Any * 0 }
        function __ctor(self, ...)
            local length                = max(1, select("#", ...))
            self[0]                     = length
            for i = 1, length, 2 do
                self[i], self[i + 1]    = select(i, ...)
            end
            super(self)
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

        export                          {
            select                      = select,
            onnext                      = Subject.OnNext,
            subscribe                   = Subject.Subscribe,
            pcall                       = pcall,
            error                       = error,

            Queue
        }

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
            local ok, sub, observer     = pcall(subscribe, self, ...)
            if not ok then error(sub, 2) end
            if self.Queue:Peek() then
                local queue             = self.Queue
                local index             = 1

                local count             = queue:Peek(index, 1)
                while count and not sub.IsUnsubscribed do
                    observer:OnNext(queue:Peek(index + 1, count))
                    index               = index + 1 + count
                    count               = queue:Peek(index, 1)
                end
            end
            return sub, observer
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