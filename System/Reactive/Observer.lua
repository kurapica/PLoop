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
    class "Subscription"                (function(_ENV)
        extend "System.ISubscription"

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        -- As sub subscription that will be disposed when the root is disposed
        __Arguments__{ ISubscription/nil }
        function __ctor(self, subscription)
            if not subscription then return end
            subscription.OnUnsubscribe  = subscription.OnUnsubscribe + function() return self:Dispose() end
        end
    end)

    __Sealed__()
    class "Observer"                    (function(_ENV)
        extend "System.IObserver"

        export {
            fakefunc                    = Toolset.fakefunc
        }

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        -- The subscription will be used by the observer
        property "Subscription"         { type = ISubscription, default = function() return Subscription() end }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        --- Provides the observer with new data
        function OnNext(self, ...)
            return self.__onNext(...)
        end

        --- Notifies the observer that the provider has experienced an error condition
        function OnError(self, ...)
            return self.__onError(...)
        end

        --- Notifies the observer that the provider has finished sending push-based notifications
        function OnCompleted(self)
            self.Subscription:Dispose()
            return self.__onComp()
        end

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        __Arguments__{ Callable/nil, Callable/nil, Callable/nil }
        function __ctor(self, onNext, onError, onCompleted)
            self.__onNext               = onNext or fakefunc
            self.__onError              = onError or fakefunc
            self.__onComp               = onCompleted or fakefunc
        end

        -----------------------------------------------------------------------
        --                          de-constructor                           --
        -----------------------------------------------------------------------
        function __dtor(self)
            self.Subscription:Dispose()
        end
    end)

    -- Declare first
    class "Observable"                  (function(_ENV)
        extend "System.IObservable"

        export { Observer, Subscription }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        local function subscribe(self, observer, subscription)
            subscription                = subscription or Subscription()
            self.__subscribe(observer, subscription)
            return subscription, observer
        end

        __Arguments__{ IObserver, ISubscription/nil }
        Subscribe                       = subscribe

        __Arguments__{ Callable/nil, Callable/nil, Callable/nil }
        function Subscribe(self, onNext, onError, onCompleted)
            local observer              = Observer(onNext, onError, onCompleted)
            return subscribe(self, observer, observer.Subscription)
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