--===========================================================================--
--                                                                           --
--                         System.Reactive.Observer                          --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2019/12/01                                               --
-- Update Date  :   2023/10/19                                               --
-- Version      :   2.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Reactive"

    Environment.RegisterGlobalNamespace("System.Reactive")

    __Sealed__()
    class "Observer"                    (function(_ENV)
        extend "System.IObserver"

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        __Arguments__{ Callable/nil, Callable/nil, Callable/nil }
        function __ctor(self, onNext, onError, onCompleted)
            self.OnNext                 = onNext
            self.OnError                = onError
            self.OnCompleted            = onCompleted
        end
    end)

    -- Declare first
    class "Observable"                  (function(_ENV)
        extend "System.IObservable"

        export { Observer, ISubscription }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        local function subscribe(self, observer)
            local subscription          = ISubscription()
            self.__subscribe(observer, subscription)
            return subscription, observer
        end

        __Arguments__{ IObserver }
        Subscribe                       = subscribe

        __Arguments__{ Callable/nil, Callable/nil, Callable/nil }
        function Subscribe(self, onNext, onError, onCompleted)
            return subscribe(self, Observer(onNext, onError, onCompleted))
        end

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        __Arguments__{ Callable }
        function __ctor(self, subscribe)
            self.__subscribe            = subscribe
        end
    end)
end)