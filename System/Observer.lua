--===========================================================================--
--                                                                           --
--                             Observer Pattern                              --
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
    --- Defines a provider for push-based notification
    __Sealed__() __AnonymousClass__()
    interface "System.IObservable" (function(_ENV)
        export {
            pcall               = pcall,
            tostring            = tostring,
            Error               = Logger.Default[Logger.LogLevel.Error],
        }

        local function safeCall(func)
            return function(...)
                local ok, ret   = pcall(func, ...)
                if not ok then Error(tostring(ret)) end
            end
        end

        --- Notifies the provider that an observer is to receive notifications.
        __Abstract__() function Subscribe(self, onNext, onError, onCompleted) end

        -- Safe subscribe the handlers
        __Arguments__{ Callable, Callable/nil, Callable/nil }
        function SafeSubscribe(self, onNext, onError, onCompleted)
            return self:Subscribe(safeCall(onNext), onError, onCompleted)
        end
    end)

    --- Provides a mechanism for receiving push-based notifications
    __Sealed__() __AnonymousClass__()
    interface "System.IObserver" (function(_ENV)
        -----------------------------------------------------------------------
        --                               event                               --
        -----------------------------------------------------------------------
        event "OnUnsubscribe"

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- Whether the Subscriber is unsubscribed
        property "IsUnsubscribed" { type = Boolean, default = false, handler = function(self, val) if val then return OnUnsubscribe(self) end end }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        --- Indicate that the subscriber is no longer interested in any of the Observables it is currently subscribed to
        function Unsubscribe(self) self.IsUnsubscribed = true end

        --- Indicate the subscriber should restart the subscribe, this is a dangerous action since the previous observable
        -- may haven't check the IsUnsubscribed flag to stop the subscription, the observable should check the OnUnsubscribe
        function Resubscribe(self) self.IsUnsubscribed = false end

        -----------------------------------------------------------------------
        --                          abstract method                          --
        -----------------------------------------------------------------------
        --- Provides the observer with new data
        __Abstract__() function OnNext(self, ...) end

        --- Notifies the observer that the provider has experienced an error condition
        __Abstract__() function OnError(self, exception) end

        --- Notifies the observer that the provider has finished sending push-based notifications
        __Abstract__() function OnCompleted(self) end
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