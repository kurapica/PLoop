--===========================================================================--
--                                                                           --
--                             Observer Pattern                              --
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
    --- The subscription that should be returned by Observable's Subscribe
    __Sealed__() __AnonymousClass__()
    interface "System.ISubscription"    (function(_ENV)
        export                          { rawset = rawset, rawget = rawget }

        event "OnUnsubscribe"

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- Whether is unsubscribed
        property "IsUnsubscribed"       { get = function(self) return rawget(self, "Disposed") or false end }

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        -- As sub subscription that will be disposed when the root is disposed
        __Arguments__{ ISubscription/nil }
        function __ctor(self, subscription)
            if not subscription then return end
            rawset(self, "__root",      subscription)
            rawset(self, "__handler",   function() return self:Dispose() end)
            subscription.OnUnsubscribe  = subscription.OnUnsubscribe + self.__handler
        end

        -----------------------------------------------------------------------
        --                          de-constructor                           --
        -----------------------------------------------------------------------
        function __dtor(self)
            if self.IsUnsubscribed then return end

            local root                  = rawget(self, "__root")
            local handler               = rawget(self, "__handler")
            if root and handler and not root.IsUnsubscribed then
                root.OnUnsubscribe      = root.OnUnsubscribe - handler
            end

            OnUnsubscribe(self)
        end
    end)

    --- Defines a provider for push-based notification
    __Sealed__() __AnonymousClass__()
    interface "System.IObservable"      (function(_ENV)
        --- Notifies the provider that an observer is to receive notifications.
        -- should return ISubscription object for unsubscribe.
        __Abstract__() function Subscribe(self, observer, subscription) return subscription, observer end
    end)

    --- Provides a mechanism for receiving push-based notifications
    __Sealed__() __AnonymousClass__()
    interface "System.IObserver"        (function(_ENV)
        -----------------------------------------------------------------------
        --                          abstract method                          --
        -----------------------------------------------------------------------
        --- Provides the observer with new data
        __Abstract__()
        function OnNext(self, ...) end

        --- Notifies the observer that the provider has experienced an error condition
        __Abstract__()
        function OnError(self, exception) end

        --- Notifies the observer that the provider has finished sending push-based notifications
        __Abstract__()
        function OnCompleted(self) end
    end)

    --- Provide the Connect mechanism for observable queues
    __Sealed__()
    interface "System.IConnectableObservable" (function(_ENV)
        extend "IObservable"

        -----------------------------------------------------------------------
        --                          abstract method                          --
        -----------------------------------------------------------------------
        --- Connect the underlying observable queue
        __Abstract__() function Connect(self, ...) end
    end)
end)