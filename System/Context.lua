--===========================================================================--
--                                                                           --
--                              System.Context                               --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2020/08/18                                               --
-- Update Date  :   2020/08/27                                               --
-- Version      :   1.0.2                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Context"

    --- Represents the session item storage provider, normally a single object works for all sessions
    __Sealed__()
    interface "ISessionStorageProvider" (function(_ENV)

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- Whether update the time out of the session when accessed
        __Abstract__()
        property "KeepAlive"            { type = Boolean }

        --- The minute count before session time out, this will be used if the session's timeout is not set
        __Abstract__()
        property "TimeoutMinutes"       { type = Number, default = 30 }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        --- Whether the session ID existed in the storage.
        __Abstract__()
        function Contains(self, id) end

        --- Get session item
        __Abstract__()
        function GetItems(self, id) end

        --- Remove session item
        __Abstract__()
        function RemoveItems(self, id) end

        --- Try sets the item with an un-existed key, return true if success, this should be a mutex operation
        __Abstract__()
        function TrySetItems(self, id, time, timeout) end

        --- Update the item with current session data
        __Abstract__()
        function SetItems(self, id, item, timeout) end

        --- Update the item's timeout
        __Abstract__()
        function ResetItems(self, id, timeout) end
    end)

    --- Represents the session to be used in the Context
    __Sealed__()
    class "Session"                     (function(_ENV)

        export { Date }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        --- Save the session items
        function SaveSessionItems(self)
            local provider              = self.SessionStorageProvider
            local sessionID             = self.SessionID
            if not (provider and sessionID) then return end

            if self.Canceled then
                -- Clear the session items
                return provider:RemoveItems(sessionID)
            elseif self.IsNewSession or self.ItemsChanged then
                -- Set teh session items
                return provider:SetItems(sessionID, self.RawItems, self.Timeout or Date.Now:AddMinutes(provider.TimeoutMinutes))
            elseif self.TimeoutChanged then
                -- Reset the timeout with the settings
                return provider:ResetItems(sessionID, self.Timeout)
            elseif provider.KeepAlive then
                -- Keep the session alive
                return provider:ResetItems(sessionID, Date.Now:AddMinutes(provider.TimeoutMinutes))
            end
        end

        --- Load the Session Items
        function LoadSessionItems(self)
            local items
            if self.SessionID and self.SessionStorageProvider then
                -- Load the session items
                items                   = self.SessionStorageProvider:GetItems(self.SessionID)
            end

            self.IsNewSession           = not items
            items                       = items or {}

            self.RawItems               = items
            return items
        end

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- Gets the unique identifier for the session
        __Abstract__()
        property "SessionID"            { type = Any, handler = function(self) self.RawItems, self.IsNewSession, self.ItemsChanged = nil, false, false end }

        --- The context
        __Abstract__()
        property "Context"              { type = Context }

        --- The Session Storage Provider, this should be provided by the session class
        __Abstract__()
        property"SessionStorageProvider"{ type = ISessionStorageProvider }

        --- Gets or sets the session items
        __Indexer__()
        __Abstract__()
        property "Items"                {
            set                         = function(self, key, value)
                if self.RawItems[key]  ~= value then
                    self.ItemsChanged   = true
                    self.RawItems[key]  = value
                end
            end,
            get                         = function(self, key) return self.RawItems[key] end,
        }

        --- The raw item table to be used for serialization
        __Abstract__()
        property "RawItems"             { default = LoadSessionItems }

        --- Gets or sets the date time, allowed the next request access the session
        __Set__(PropertySet.Clone)
        __Abstract__()
        property "Timeout"              { type = Date, handler = function(self) self.TimeoutChanged = true end }

        --- Whether the time out is changed
        __Abstract__()
        property "TimeoutChanged"       { type = Boolean, default = false }

        --- Whether the current session is canceled
        __Abstract__()
        property "Canceled"             { type = Boolean, default = false }

        --- Gets a value indicating whether the session was newly created
        __Abstract__()
        property "IsNewSession"         { type = Boolean, default = false }

        --- Whether the session items has changed
        __Abstract__()
        property "ItemsChanged"         { type = Boolean, default = false }

        -----------------------------------------------------------------------
        --                           constructor                             --
        -----------------------------------------------------------------------
        __Abstract__() __Arguments__{ Context/nil, ISessionStorageProvider/nil }
        function __ctor(self, context, provider)
            self.Context                = context
            self.SessionStorageProvider = provider
        end
    end)

    --- A test session storage provider based on the Lua table
    __Sealed__()
    class "TableSessionStorageProvider" (function (_ENV)
        extend "ISessionStorageProvider"

        export                          {
            ostime                      = _G.os and os.time or _G.time,
            pairs                       = pairs,
        }

        -----------------------------------------------------------------------
        --                          inherit method                           --
        -----------------------------------------------------------------------
        function Contains(self, id)
            return self.Storage[id] and true or false
        end

        function GetItems(self, id)
            local item                  = self.Storage[id]
            if item then
                local timeout           = self.Timeout[id]
                if timeout and timeout.Time < ostime() then
                    self:RemoveItem(id)
                else
                    return item
                end
            end
        end

        function RemoveItems(self, id)
            self.Storage[id]            = nil
            self.Timeout[id]            = nil
        end

        function SetItems(self, id, item, timeout)
            self.Storage[id]            = item
            if timeout then
                self.Timeout[id]        = timeout
            end
        end

        function ResetItems(self, id, timeout)
            if timeout and self.Storage[id] then
                self.Timeout[id]        = timeout
            end
        end

        function TrySetItems(self, id, time, timeout)
            if self.Storage[id] ~= nil then return false end
            self:SetItems(id, time, timeout)
            return true
        end

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        property "Storage"              { type = Table, default = Toolset.newtable }
        property "Timeout"              { type = Table, default = Toolset.newtable }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        function ClearTimeoutItems(self)
            local storage               = self.Storage
            local timeouts              = self.Timeout
            local now                   = ostime()
            for id in pairs(storage) do
                if timeouts[id] and timeouts[id].Time < now then
                    storage[id]         = nil
                    timeouts[id]        = nil
                end
            end
        end
    end)
end)