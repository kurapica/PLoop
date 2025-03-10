--===========================================================================--
--                                                                           --
--                         System.Reactive.Observer                          --
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

    --- The default observer
    __Sealed__()
    class "Observer"                    (function(_ENV)
        extend "System.IObserver"

        export                          { Subscription }

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        __Arguments__{ Callable/nil, Callable/nil, Callable/nil, Subscription/nil }
        function __ctor(self, onNext, onError, onCompleted, subscription)
            self.OnNext                 = onNext and function (self, ...) return onNext(...) end
            self.OnError                = onError and function (self, ex) return onError(ex) end
            self.OnCompleted            = onCompleted and function (self) self.Subscription = nil return onCompleted() end
            self.Subscription           = subscription and Subscription(subscription)
        end
    end)

    -- The observable implementation
    class "Observable"                  (function(_ENV)
        extend "System.IObservable"

        export                          {
            -- the core subscribe
            subscribe                   = function (self, observer, subscription)
                subscription            = subscription or observer.Subscription
                if not subscription.IsUnsubscribed then self[1](observer, subscription) end
                return subscription, observer
            end,

            Observer
        }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        --- Subscribe the observer with subscription
        __Arguments__{ IObserver, Subscription/nil }
        Subscribe                       = subscribe

        __Arguments__{ Callable/nil, Callable/nil, Callable/nil, Subscription/nil }
        Subscribe                       = function (self, onNext, onError, onCompleted, subscription)
            return subscribe(self, Observer(onNext, onError, onCompleted, subscription))
        end

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        __Arguments__{ Callable }
        function __new(_, subscribe)    return { subscribe }, true end
    end)
end)