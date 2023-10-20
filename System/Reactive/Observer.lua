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

        export {
            fakefunc                    = Toolset.fakefunc
        }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        --- Provides the observer with new data
        function OnNext(self, ...)      return self.__onNext(...) end

        --- Notifies the observer that the provider has experienced an error condition
        function OnError(self, ...)     return self.__onError(...) end

        --- Notifies the observer that the provider has finished sending push-based notifications
        function OnCompleted(self)      return self.__onComp() end

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        __Arguments__{ Callable/nil, Callable/nil, Callable/nil }
        function __ctor(self, onNext, onError, onCompleted)
            self.__onNext               = onNext or fakefunc
            self.__onError              = onError or fakefunc
            self.__onComp               = onCompleted or fakefunc
        end
    end)

    -- Declare first
    class "Observable"                  (function(_ENV)
        extend "System.IObservable"

        export { Observer, ISubscription }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        local function subscribe(self, observer, subscription)
            subscription                = subscription or ISubscription()
            self.__subscribe(observer, subscription)
            return subscription, observer
        end

        __Arguments__{ IObserver, ISubscription/nil }
        Subscribe                       = subscribe

        __Arguments__{ Callable/nil, Callable/nil, Callable/nil, ISubscription/nil }
        function Subscribe(self, onNext, onError, onCompleted, subscription)
            return subscribe(self, Observer(onNext, onError, onCompleted), subscription)
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