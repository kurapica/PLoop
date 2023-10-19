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
        export { rawget }

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- Whether is unsubscribed
        property "IsUnsubscribed"       { get = function(self) rawget(self, "Disposed") end }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        --- The method used for unsubscribe
        __Abstract__() function Unsubscribe(self) end

        -----------------------------------------------------------------------
        --                          de-constructor                           --
        -----------------------------------------------------------------------
        function __dtor(self)
            return self:Unsubscribe()
        end
    end)

    --- Defines a provider for push-based notification
    __Sealed__() __AnonymousClass__()
    interface "System.IObservable"      (function(_ENV)
        export { ISubscription }

        --- Notifies the provider that an observer is to receive notifications.
        -- should return ISubscription object for unsubscribe.
        __Abstract__() function Subscribe(self, onNext, onError, onCompleted) return ISubscription() end
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