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

    --- The default observer
    __Sealed__()
    class "Observer"                    (function(_ENV)
        extend "System.IObserver"

        export                          {
            rawset                      = rawset,
            rawget                      = rawget,

            Subscription
        }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        --- Provides the observer with new data
        function OnNext(self, ...)
            local on                    = self.__onNext
            return on and on(...)
        end

        --- Notifies the observer that the provider has experienced an error condition
        function OnError(self, ...)
            local on                    = self.__onError
            return on and on(...)
        end

        --- Notifies the observer that the provider has finished sending push-based notifications
        function OnCompleted(self)
            self.Subscription           = nil
            local on                    = self.__onComp
            return on and on()
        end

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        __Arguments__{ Callable/nil, Callable/nil, Callable/nil, Subscription/nil }
        function __ctor(self, onNext, onError, onCompleted, subscription)
            rawset(self, "__onNext",    onNext      or false)
            rawset(self, "__onError",   onError     or false)
            rawset(self, "__onComp",    onCompleted or false)
            if subscription then
                self.Subscription       = Subscription(subscription)
            end
        end
    end)

    -- The observable implementation
    class "Observable"                  (function(_ENV)
        extend "System.IObservable"

        export                          {
            rawset                      = rawset,
            isObjectType                = Class.IsObjectType,

            -- the core subscribe
            subscribe                   = function (self, observer, subscription)
                subscription            = subscription or observer.Subscription
                self.__subscribe(observer, subscription)
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
        function Subscribe(self, onNext, onError, onCompleted, subscription)
            return subscribe(self, Observer(onNext, onError, onCompleted, subscription))
        end

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        __Arguments__{ Callable }
        function __ctor(self, subscribe)
            rawset(self, "__subscribe", subscribe)
        end
    end)
end)