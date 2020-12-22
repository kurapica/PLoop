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

    --- The attribute used to wrap a function or property that return operator to be an Observable, so could be re-used
    __Sealed__() class "__Observable__" (function(_ENV)
        extend "IInitAttribute"

        export {
            _PropertyMap        = Toolset.newtable(true),

            Defer               = Observable.Defer,
            pairs               = pairs,
            error               = error,
            type                = type,
            rawget              = rawget,
            rawset              = rawset,
            strlower            = string.lower,
            safeset             = Toolset.safeset,

            AttributeTargets, Class, Property, Event, __Observable__
        }

        local _StaticSubjects   = Toolset.newtable(true)

        local function processPropertySet(prop, obj, ...)
            if prop:IsStatic() then
                subject         = _StaticSubjects[prop]
            else
                subject         = rawget(obj, __Observable__)
                subject         = subject and subject[prop]
            end

            if subject then subject:OnNext(...) end
        end

        -----------------------------------------------------------
        --                     extend method                     --
        -----------------------------------------------------------
        __Static__()
        function Observable.FromProperty(self, prop)
            if type(prop) == "string" then
                if Class.Validate(self) then
                    prop        = Class.GetFeature(self, prop)
                    if not Property.IsStatic(prop) then return end
                else
                    local cls   = Class.GetObjectClass(self)
                    prop        = cls and Class.GetFeature(cls, prop, true)
                end
            elseif prop == nil then
                prop            = self
                if not (Property.Validate(prop) and Property.IsStatic(prop)) then return end
            end

            if prop and _PropertyMap[prop] then
                if Property.IsStatic(prop) then
                    local subject   = _StaticSubjects[prop]
                    if not subject then
                        subject     = Subject()
                        _StaticSubjects = safeset(_StaticSubjects, prop, subject)
                    end
                    return subject
                else
                    local obs       = rawget(self, __Observable__)
                    if not obs then
                        obs         = {}
                        rawset(self, __Observable__, obs)
                    end

                    local subject   = obs[prop]
                    if not subject then
                        subject     = Subject()
                        obs[prop]   = subject
                    end

                    return subject
                end
            end
        end

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        function InitDefinition(self, target, targettype, definition, owner, name, stack)
            if targettype == AttributeTargets.Property then
                local set, handler

                for k, v in pairs(definition) do
                    if type(k) == "string" then
                        local lk    = strlower(k)

                        if lk == "auto" then
                            error("The property " .. name .. " can't be used as observable", stack + 1)
                        elseif lk  == "set" then
                            if v  == false then error("The property " .. name .. " can't be used as observable", stack + 1) end
                            set     = k
                        elseif lk  == "setmethod" then
                            set     = set or k
                        elseif lk  == "handler" then
                            handler = k
                        end
                    end
                end

                if set then
                    -- Replace the set
                    local oset      = definition[set]
                    if type(oset) == "function" then
                        definition[set] = function(obj, ...)
                            oset(obj, ...)

                            return processPropertySet(target, obj, ...)
                        end
                    elseif type(oset) == "string" then
                        definition[set] = function(obj, ...)
                            local func  = obj[oset]
                            if type(func) == "function" then func(obj, ...) end

                            return processPropertySet(target, obj, ...)
                        end
                    end
                end

                -- Replace the handler
                local ohandler      = definition[handler]
                if type(ohandler) == "function" then
                    definition[handler] = function(obj, new, old, prop)
                        ohandler(obj, new, old, prop)

                        return processPropertySet(target, obj, new)
                    end
                elseif type(ohandler) == "string" then
                    definition[handler] = function(obj, new, old, prop)
                        local func      = obj[ohandler]
                        if type(func) == "function" then func(obj, new, old, prop) end

                        return processPropertySet(target, obj, new)
                    end
                else
                    definition.handler  = function(obj, new, old, prop)
                        return processPropertySet(target, obj, new)
                    end
                end

                _PropertyMap[target]    = true
            else
                return function(...) return Defer(target, ...) end
            end
        end

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- the attribute target
        property "AttributeTarget"  { type = AttributeTargets,  default = AttributeTargets.Method + AttributeTargets.Function + AttributeTargets.Property }

        property "Priority"         { type = AttributePriority, default = AttributePriority.Lower }

        property "SubLevel"         { type = Number, default = -9999 }
    end)
end)