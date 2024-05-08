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

    --- The default subscription can be created based on root subscription
    __Sealed__()
    class "Subscription"                 { System.ISubscription }

    --- The default observer
    __Sealed__()
    class "Observer"                    (function(_ENV)
        extend "System.IObserver"

        export                          {
            rawset                      = rawset,
            rawget                      = rawget,
            fakefunc                    = Toolset.fakefunc,

            Subscription
        }

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        -- The subscription will be used by the observer
        property "Subscription"         {
            type                        = ISubscription,
            field                       = "__subscription",
            default                     = function(self)
                local sub               = Subscription()
                -- make sure a new subscription will be created if the observer is reused
                sub.OnUnsubscribe       = sub.OnUnsubscribe + function() rawset(self, "__subscription", nil) end
                return sub
            end
        }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        --- Provides the observer with new data
        function OnNext(self, ...)      return self.__onNext(...) end

        --- Notifies the observer that the provider has experienced an error condition
        function OnError(self, ...)     return self.__onError(...)end

        --- Notifies the observer that the provider has finished sending push-based notifications
        function OnCompleted(self)
            local subscription          = rawget(self, "__subscription")
            return subscription and subscription:Dispose() or self.__onComp()
        end

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        __Arguments__{ Callable/nil, Callable/nil, Callable/nil, ISubscription/nil }
        function __ctor(self, onNext, onError, onCompleted, subscription)
            rawset(self, "__onNext",    onNext      or fakefunc)
            rawset(self, "__onError",   onError     or fakefunc)
            rawset(self, "__onComp",    onCompleted or fakefunc)
            if subscription then
                self.Subscription       = Subscription(subscription)
            end
        end

        -----------------------------------------------------------------------
        --                          de-constructor                           --
        -----------------------------------------------------------------------
        function __dtor(self)
            local subscription          = rawget(self, "__subscription")
            return subscription and subscription:Dispose()
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
                subscription            = subscription or isObjectType(observer, Observer) and observer.Subscription or Subscription()
                self.__subscribe(observer, subscription)
                return subscription, observer
            end,

            Observer, Subscription
        }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        --- Subscribe the observer with subscription
        __Arguments__{ IObserver, ISubscription/nil }
        Subscribe                       = subscribe

        __Arguments__{ Callable/nil, Callable/nil, Callable/nil, ISubscription/nil }
        function Subscribe(self, onNext, onError, onCompleted, subscription)
            local observer              = Observer(onNext, onError, onCompleted, subscription)
            return subscribe(self, observer, observer.Subscription)
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