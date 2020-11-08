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

    __Sealed__() class "Observable" (function(_ENV)
        extend "System.IObservable"

        export {
            Observer, Observable, IObservable,

            tostring            = tostring,
            select              = select,
            unpack              = unpack,
            pcall               = pcall,
            IsObjectType        = Class.IsObjectType,
            Exception           = System.Exception,
            RunAsync            = Threading.RunAsync,
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
        __Static__() function Just(...)
            local count         = select("#", ...)

            local self
            self                = Observable(function(observer)
                if count > 0 then observer:OnNext(unpack(self)) end
                observer:OnCompleted()
            end)

            for i = 1, count do
                self[i]         = select(i, ...)
            end

            return self
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
        __Static__() __Arguments__{ Callable, Any * 0 }
        function Defer(ctor, ...)
            local self

            self                = Observable(function(observer)
                local obs       = ctor(unpack(self))
                if not IsObjectType(obs, IObservable) then
                    obs:OnError(Exception("The defer function doesn't provide valid observable"))
                else
                    return obs:Subscribe(observer)
                end
            end)

            for i = 1, select("#", ...) do
                self[i]         = select(i, ...)
            end

            return self
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
        __Static__() __Arguments__{ Number, Any * 1 }
        function Repeat(count, ...)
            local self
            self                = Observable(function(observer)
                local i         = 0

                while i < count do
                    if observer.IsUnsubscribed then return end
                    observer:OnNext(unpack(self))
                    i           = i + 1
                end
                observer:OnCompleted()
            end)

            for i = 1, select("#", ...) do
                self[i]         = select(i, ...)
            end

            return self
        end

        --- Creates an Observable that emits the return value of a function-like directive
        __Static__() __Arguments__{ Callable, Any * 0 }
        function Start(func, ...)
            local self
            self                = Observable(function(observer)
                RunAsync(function()
                    observer:OnNext(func(unpack(self)))
                    observer:OnCompleted()
                end)
            end)

            for i = 1, select("#", ...) do
                self[i]         = select(i, ...)
            end

            return self
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

    --- The attribute used to wrap a function that return operator to be an Observable, so could be re-used
    __Sealed__() class "__Observable__" (function(_ENV)
        extend "IInitAttribute"

        local Defer             = Observable.Defer

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        function InitDefinition(self, target, targettype, definition, owner, name, stack)
            return function(...) return Defer(target, ...) end
        end

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- the attribute target
        property "AttributeTarget"  { type = AttributeTargets,  default = AttributeTargets.Method + AttributeTargets.Function }

        --- the attribute's priority
        property "Priority"         { type = AttributePriority, default = AttributePriority.Lowest }
    end)
end)