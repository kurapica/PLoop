--===========================================================================--
--                                                                           --
--                        System.Reactive.Observable                         --
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

    -- Declare before definition
    class "__Observable__" {}

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

    __Sealed__() class "Observable" (function(_ENV)
        extend "System.IObservable"

        export {
            Observer, Observable, IObservable, List, __Observable__,

            tostring            = tostring,
            select              = select,
            unpack              = unpack,
            pcall               = pcall,
            rawset              = rawset,
            loadsnippet         = Toolset.loadsnippet,
            IsObjectType        = Class.IsObjectType,
            Exception           = System.Exception,
            RunAsync            = Threading.RunAsync,

            getProperty         = Class.GetFeature,
            getObjectClass      = Class.GetObjectClass,
        }

        -----------------------------------------------------------------------
        --               static methods - Creating Observables               --
        -----------------------------------------------------------------------
        --- Creates a new Observable
        __Static__() __Arguments__{ Callable }
        function Create(subscribe)
            return Observable(subscribe)
        end

        --- Creates a new objservable with initstate, condition checker, iterate and a result selector
        __Static__() __Arguments__{ Any, Callable, Callable, Callable/nil}
        function Generate(init, condition, iterate, resultselector)
            return Observable(function(observer)
                local value     = init
                if resultselector then
                    while value ~= nil and condition(value) do
                        observer:OnNext(resultselector(value))
                        if observer.IsUnsubscribed then return end
                        value   = iterate(value)
                    end
                else
                    while value ~= nil and condition(value) do
                        observer:OnNext(value)
                        if observer.IsUnsubscribed then return end
                        value   = iterate(value)
                    end
                end
                observer:OnCompleted()
            end)
        end

        --- Returns an Observable that just provide one value
        local _JustAutoGen      = setmetatable({
            [0]                 = function() return Observable(function(observer) observer:OnCompleted() end) end
        }, {
            __index             = function(self, count)
                local args      = List(count):Map("i=>'arg' .. i"):Join(",")
                local func      = loadsnippet([[
                    return function(]] .. args .. [[)
                        return Observable(function(observer)
                            observer:OnNext(]] .. args .. [[)
                            observer:OnCompleted()
                        end)
                    end
                ]], "Just_Gen_" .. count, _ENV)()
                rawset(self, count, func)
                return func
            end
            }
        )
        __Static__() function Just(...)
            return _JustAutoGen[select("#", ...)](...)
        end
        __Static__() Return     = Just

        --- Returns and Observable that immediately completes without producing a value
        __Static__() function Empty()
            return Observable(function(observer)
                observer:OnCompleted()
            end)
        end

        --- Returns an Observable that never produces values and never completes
        __Static__() function Never()
            return Observable(function() end)
        end

        --- Returns an Observable that immediately produces an error
        __Static__() function Throw(exception)
            if not (exception and IsObjectType(exception, Exception)) then
                exception       = Exception(exception and tostring(exception) or "Unknown error")
            end
            return Observable(function(observer) return observer:OnError(exception) end)
        end

        --- Creates the Observable only when the observer subscribes
        local _DeferAutoGen     = setmetatable({}, {
            __index             = function(self, count)
                local args      = List(count):Map("i=>'arg' .. i"):Join(",")
                local func      = loadsnippet([[
                    return function(ctor, ]] .. args .. [[)
                        return Observable(function(observer)
                            local obs   = ctor(]] .. args .. [[)
                            if not IsObjectType(obs, IObservable) then
                                observer:OnError(Exception("The defer function doesn't provide valid observable"))
                            else
                                return obs:Subscribe(observer)
                            end
                        end)
                    end
                ]], "Defer_Gen_" .. count, _ENV)()
                rawset(self, count, func)
                return func
            end
            }
        )
        __Static__() __Arguments__{ Callable, Any * 0 }
        function Defer(ctor, ...)
            return _DeferAutoGen[select("#", ...)](ctor, ...)
        end

        --- Converts collection objects into Observables
        __Static__() __Arguments__{ Iterable }
        function From(iter)
            return Observable(function(observer)
                for key, value in iter:GetIterator() do
                    if observer.IsUnsubscribed then return end
                    if value == nil then value, key = key, nil end
                    observer:OnNext(value, key)
                end
                observer:OnCompleted()
            end)
        end

        --- Converts event delegate objects into Observables
        __Static__() __Arguments__{ Delegate }
        function From(delegate)
            return Observable(function(observer)
                local handler   = function(...) observer:OnNext(...) end
                delegate        = delegate + handler
                observer.OnUnsubscribe = observer.OnUnsubscribe + function()
                    delegate    = delegate - handler
                end
            end)
        end

        --- Converts tables into Observables
        __Static__() __Arguments__{ Table, Callable/nil }
        function From(table, iter)
            return Observable(function(observer)
                for key, value in (iter or pairs)(table) do
                    if observer.IsUnsubscribed then return end
                    if value == nil then value, key = key, nil end
                    observer:OnNext(value, key)
                end
                observer:OnCompleted()
            end)
        end

        --- Create a subject based on observable property
        __Static__() __Arguments__{ PropertyType }
        function From(prop)
            return __Observable__.GetPropertyObservable(prop, nil, true)
        end

        __Arguments__{ InterfaceType + ClassType, String }
        __Static__() function From(class, name)
            local prop          = getProperty(class, name)
            return prop and __Observable__.GetPropertyObservable(prop, nil, true)
        end

        __Static__() __Arguments__{ Table, String }
        function From(self, name)
            local cls           = getObjectClass(self)
            local prop          = cls and getProperty(cls, name, true)

            return prop and __Observable__.GetPropertyObservable(prop, self, true)
        end

        --- Creates an Observable that emits a particular range of sequential integers
        __Static__() __Arguments__{ Number, Number, Number/nil }
        function Range(start, stop, step)
            return Observable(function(observer)
                for i = start, stop, step or 1 do
                    if observer.IsUnsubscribed then return end
                    observer:OnNext(i)
                end
                observer:OnCompleted()
            end)
        end

        --- Creates an Observable that emits a particular item multiple times
        local _RepeatGen        = setmetatable({}, {
            __index             = function(self, count)
                local args      = List(count):Map("i=>'arg' .. i"):Join(",")
                local func      = loadsnippet([[
                    return function(count, ]] .. args .. [[)
                        return Observable(function(observer)
                            local i = 0

                            while i < count do
                                if observer.IsUnsubscribed then return end
                                observer:OnNext(]] .. args .. [[)
                                i   = i + 1
                            end
                            observer:OnCompleted()
                        end)
                    end
                ]], "Repeat_Gen_" .. count, _ENV)()
                rawset(self, count, func)
                return func
            end
            }
        )
        __Static__() __Arguments__{ Number, Any * 1 }
        function Repeat(count, ...)
            return _RepeatGen[select("#", ...)](count, ...)
        end

        --- Creates an Observable that emits the return value of a function-like directive
        local _StartGen         = setmetatable({
            [0]                 = function(func)
                return Observable(function(observer)
                    RunAsync(function()
                        observer:OnNext(func())
                        observer:OnCompleted()
                    end)
                end)
            end
        }, {
            __index             = function(self, count)
                local args      = List(count):Map("i=>'arg' .. i"):Join(",")
                local func      = loadsnippet([[
                    return function(func, ]] .. args .. [[)
                        return Observable(function(observer)
                            RunAsync(function()
                                observer:OnNext(func(]] .. args .. [[))
                                observer:OnCompleted()
                            end)
                        end)
                    end
                ]], "Start_Gen_" .. count, _ENV)()
                rawset(self, count, func)
                return func
            end
            }
        )
        __Static__() __Arguments__{ Callable, Any * 0 }
        function Start(func, ...)
            return _StartGen[select("#", ...)](func, ...)
        end

        -----------------------------------------------------------------------
        --                          abstract method                          --
        -----------------------------------------------------------------------
        __Abstract__() function SubscribeCore(observer) end

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        local function subscribe(self, observer)
            self.SubscribeCore(observer)
            return observer
        end

        __Arguments__{ IObserver }
        Subscribe               = subscribe

        __Arguments__{ Callable/nil, Callable/nil, Callable/nil }
        function Subscribe(self, onNext, onError, onCompleted)
            return subscribe(self, Observer(onNext, onError, onCompleted))
        end

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        __Arguments__{ Callable }
        function __ctor(self, subscribe)
            self.SubscribeCore  = subscribe
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

            AttributeTargets, Class, Property, Event, __Observable__, Subject
        }

        local _StaticSubjects   = Toolset.newtable(true)

        local function getSubject(prop, obj, withCreation)
            local subject

            if prop:IsStatic() then
                subject         = _StaticSubjects[prop]

                if not subject and withCreation then
                    subject     = Subject()
                    _StaticSubjects = safeset(_StaticSubjects, prop, subject)
                end
            else
                local container = obj and rawget(obj, __Observable__)
                subject         = container and container[prop]

                if not subject and obj and withCreation then
                    subject     = Subject()

                    if not container then
                        container = {}
                        rawset(obj, __Observable__, container)
                    end

                    container[prop] = subject
                end
            end

            return subject
        end

        -----------------------------------------------------------
        --                    static  method                     --
        -----------------------------------------------------------
        __Static__() function IsObservableProperty(prop)
            return _PropertyMap[prop] or false
        end

        __Static__()
        function GetPropertyObservable(prop, obj)
            return _PropertyMap[prop] and getSubject(prop, obj, true) or nil
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

                            local subject = getSubject(target, obj)
                            if subject then subject:OnNext(...) end
                        end
                    elseif type(oset) == "string" then
                        definition[set] = function(obj, ...)
                            local func  = obj[oset]
                            if type(func) == "function" then func(obj, ...) end

                            local subject = getSubject(target, obj)
                            if subject then subject:OnNext(...) end
                        end
                    end
                end

                -- Replace the handler
                local ohandler      = definition[handler]
                if type(ohandler) == "function" then
                    definition[handler] = function(obj, new, old, prop)
                        ohandler(obj, new, old, prop)

                        local subject = getSubject(target, obj)
                        if subject then subject:OnNext(new) end
                    end
                elseif type(ohandler) == "string" then
                    definition[handler] = function(obj, new, old, prop)
                        local func      = obj[ohandler]
                        if type(func) == "function" then func(obj, new, old, prop) end

                        local subject = getSubject(target, obj)
                        if subject then subject:OnNext(new) end
                    end
                else
                    definition.handler  = function(obj, new, old, prop)
                        local subject = getSubject(target, obj)
                        if subject then subject:OnNext(new) end
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