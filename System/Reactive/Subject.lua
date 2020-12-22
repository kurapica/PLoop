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

    --- Only emits the last value (and only the last value) emitted by the source Observable,
    -- and only after that source Observable completes
    __Sealed__() class "AsyncSubject" (function(_ENV)
        inherit "Subject"

        export { select = select, unpack = unpack or table.unpack }

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

        export { select = select, unpack = unpack or table.unpack }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        function Subscribe(self, ...)
            local observer      = super.Subscribe(self, ...)
            if self[0] > 0 then observer:OnNext(unpack(self, 1, self[0])) end
        end

        --- Provides the observer with new data
        function OnNext(self, ...)
            self[0]             = select("#", ...)
            for i = 1, self[0] do
                self[i]         = select(i, ...)
            end
            super.OnNext(self, ...)
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

    --- A subject used to generate single literal value and provide the `__concat` meta-method
    -- so it can be used like `"ID: " .. subject`
    __Sealed__() class "LiteralSubject" (function(_ENV)
        inherit "Subject"

        export{ strformat = string.format, tostring = tostring, type = type, isObjectType = Class.IsObjectType, IObservable, Observable, LiteralSubject }

        local function concat(a, b)
            return tostring(a) .. tostring(b)
        end

        __Arguments__{ NEString }
        function Format(self, fmt)
            return LiteralSubject(self:Map(function(val) return val and strformat(fmt, tostring(val)) or "" end))
        end

        -----------------------------------------------------------------------
        --                            meta-method                            --
        -----------------------------------------------------------------------
        function __concat(prev, tail)
            if not isObjectType(prev, IObservable) then
                prev            = Observable.Just(tostring(prev))
            elseif not isObjectType(tail, IObservable) then
                tail            = Observable.Just(tostring(tail))
            end

            return LiteralSubject(prev:CombineLatest(tail, concat))
        end
    end)
end)