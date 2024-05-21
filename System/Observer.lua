--===========================================================================--
--                                                                           --
--                             Observer Pattern                              --
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
    --- The subscription that used to track the observer's subscription
    __Sealed__() __Final__()
    class "System.Subscription"         (function(_ENV)
        export                          { rawset = rawset, rawget = rawget }

        --- Fired when un-subscribed
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
        __Arguments__{ Subscription/nil }
        function __ctor(self, root)
            if not root then return end
            if root.IsUnsubscribed then throw("Usage: Subscription([root]) - The root is already unsubscribed") end

            local handler               = function() return self:Dispose() end
            rawset(self, "__root",      root)
            rawset(self, "__handler",   handler)
            root.OnUnsubscribe          = root.OnUnsubscribe + handler
        end

        -----------------------------------------------------------------------
        --                          de-constructor                           --
        -----------------------------------------------------------------------
        function __dtor(self)
            if self.IsUnsubscribed then return end

            local root                  = rawget(self, "__root")
            if root and not root.IsUnsubscribed then
                local handler           = rawget(self, "__handler")
                if handler then
                    root.OnUnsubscribe  = root.OnUnsubscribe - handler
                end
            end

            return OnUnsubscribe(self)
        end
    end)

    --- Defines a provider for push-based notification
    __Sealed__() __AnonymousClass__()
    interface "System.IObservable"      (function(_ENV)
        --- Notifies the provider that an observer is to receive notifications.
        -- should return Subscription object for unsubscribe.
        __Abstract__() function Subscribe(self, observer, subscription) return subscription, observer end
    end)

    --- Provides a mechanism for receiving push-based notifications
    __Sealed__() __AnonymousClass__()
    interface "System.IObserver"        (function(_ENV)
        export                          { rawset = rawset, rawget = rawget, Subscription }

        -----------------------------------------------------------------------
        --                          abstract method                          --
        -----------------------------------------------------------------------
        --- Provides the observer with new data
        __Abstract__()
        OnNext                          = Toolset.fakefunc

        --- Notifies the observer that the provider has experienced an error condition
        __Abstract__()
        OnError                         = Toolset.fakefunc

        --- Notifies the observer that the provider has finished sending push-based notifications
        __Abstract__()
        OnCompleted                     = function (self) self.Subscription = nil end

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        -- The subscription will be used by the observer
        property "Subscription"         {
            type                        = Subscription,
            field                       = "__subscr",
            default                     = function(self) return Subscription() end,
            handler                     = function(self, new, old)
                if new and not new.IsUnsubscribed then
                    new.OnUnsubscribe   = new.OnUnsubscribe + function() return rawget(self, "__subscr") == new and rawset(self, "__subscr", nil) end
                else
                    rawset(self, "__subscr", nil)
                end
                return old and not old.IsUnsubscribed and old:Dispose()
            end
        }

        -----------------------------------------------------------------------
        --                          de-constructor                           --
        -----------------------------------------------------------------------
        function __dtor(self)
            self.Subscription           = nil
        end
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