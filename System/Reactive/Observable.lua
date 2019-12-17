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

    __Async__() function ProcessTask(func, ...)
        return func(...)
    end

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
            ProcessTask         = ProcessTask,
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
        __Static__() __Arguments__{ Any, Callable, Callable, Callable/"...=>..." }
        function Generate(init, condition, iterate, resultselector)
            return Observable(function(observer)
                local value     = init
                while condition(value) do
                    observer:OnNext(resultselector(value))
                    if observer.IsUnsubscribed then return end
                    value       = iterate(value)
                end
                observer:OnCompleted()
            end)
        end

        --- Returns an Observable that just provide one value
        __Static__() function Just(value)
            return Observable(function(observer)
                observer:OnNext(value)
                observer:OnCompleted()
            end)
        end
        __Static__() Return = Just

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
            if not Class.IsObjectType(exception, Exception) then
                exception       = Exception(tostring(exception) or "Unknown error")
            end
            return Observable(function(observer) return observer:OnError(exception) end)
        end

        --- Creates the Observable only when the observer subscribes
        __Static__() __Arguments__{ Callable }
        function Defer(ctor)
            return Observable(function(observer)
                local observable= ctor()
                if not IsObjectType(observable, IObservable) then
                    observable:OnError(Exception("The defer function doesn't provide valid observable"))
                else
                    return observable:Subscribe(observer)
                end
            end)
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
        __Static__() __Arguments__{ Table, Callable/pairs }
        function From(table, iter)
            return Observable(function(observer)
                for key, value in iter(table) do
                    if observer.IsUnsubscribed then return end
                    if value == nil then value, key = key, nil end
                    observer:OnNext(value, key)
                end
                observer:OnCompleted()
            end)
        end

        --- Creates an Observable that emits a particular range of sequential integers
        __Static__() __Arguments__{ Integer, Integer }
        function Range(start, length)
            return Observable(function(observer)
                for i = start, start + length - 1 do
                    if observer.IsUnsubscribed then return end
                    observer:OnNext(i)
                end
                observer:OnCompleted()
            end)
        end

        --- Creates an Observable that emits a particular item multiple times
        __Static__() __Arguments__{ Any, Number }
        function Repeat(value, count)
            return Observable(function(observer)
                local i         = 0

                while i < count do
                    if observer.IsUnsubscribed then return end
                    observer:OnNext(value)
                    i           = i + 1
                end
                observer:OnCompleted()
            end)
        end

        --- Creates an Observable that emits the return value of a function-like directive
        __Static__() __Arguments__{ Callable, Any * 0 }
        function Start(func, ...)
            local a1, a2, a3, a4
            local args
            if select("#", ...) > 4 then
                args            = { ... }
            else
                a1, a2, a3, a4  = ...
            end
            return Observable(function(observer)
                ProcessTask(function()
                    if args then
                        observer:OnNext(func(unpack(args)))
                    else
                        observer:OnNext(func(a1, a2, a3, a4))
                    end
                    observer:OnCompleted()
                end)
            end)
        end

        -----------------------------------------------------------------------
        --                          abstract method                          --
        -----------------------------------------------------------------------
        __Abstract__() function SubscribeCore(observer) end

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        local function subscribe(self, observer)
            local ok, ret       = pcall(self.SubscribeCore, observer)
            if not ok then
                if not IsObjectType(ret, Exception) then
                    observer:OnError(Exception(tostring(ret)))
                else
                    observer:OnError(ret)
                end
            end
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
end)