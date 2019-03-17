--===========================================================================--
--                                                                           --
--                          System.Web.HttpSession                           --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2016/03/11                                               --
-- Update Date  :   2018/03/15                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    --- Represents the interface of session id manager
    __Sealed__() interface "System.Web.ISessionIDManager" (function (_ENV)
        extend "IHttpContextHandler"

        export { ISessionIDManager }

        -----------------------------------------------------------------------
        --                         inherit property                          --
        -----------------------------------------------------------------------
        property "ProcessPhase"         { set = false, default = IHttpContextHandler.ProcessPhase.Head }
        property "AsGlobalHandler"      { set = false, default = true }

        -----------------------------------------------------------------------
        --                          static property                          --
        -----------------------------------------------------------------------
        -- the unique id manager
        __Static__() property "Default" { type = ISessionIDManager, handler = function(self, new, old) if old then old:Dispose() end end }

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- The minute count before session time out.
        property "TimeoutMinutes"       { type = NaturalNumber, default = 30 }

        --- Whether update the time out of the session when accessed
        property "KeepAlive"            { type = Boolean }

        -----------------------------------------------------------------------
        --                          inherit method                           --
        -----------------------------------------------------------------------
        function Process(self, context)
            local session = context.RawSession
            if session then
                if session.Canceled then
                    return self:RemoveSessionID(context)
                elseif session.IsNewSession or session.TimeoutChanged then
                    return self:SaveSessionID(context, session)
                end
            end
        end

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        --- Gets the session identifier from the context of the current HTTP request.
        __Abstract__() function GetSessionID(self, context) end

        --- Creates a unique session identifier.
        __Abstract__() function CreateSessionID(self, context) end

        --- Deletes the session identifier in the current HTTP response.
        __Abstract__() function RemoveSessionID(self, context) end

        --- Saves a newly created session identifier to the HTTP response.
        __Abstract__() function SaveSessionID(self, context, session) end

        --- Validate the session id
        __Abstract__() function ValidateSessionID(self, id) end

        -----------------------------------------------------------------------
        --                           initializer                            --
        -----------------------------------------------------------------------
        function __init(self)
            if self.Application then
                self.Application[ISessionIDManager] = self
            else
                ISessionIDManager.Default = self
            end
        end
    end)

    --- Represents the interface of sessio1n storage provider
    __Sealed__() interface "System.Web.ISessionStorageProvider" (function (_ENV)
        extend "IHttpContextHandler"

        export { ISessionStorageProvider }

        -----------------------------------------------------------------------
        --                         inherit property                          --
        -----------------------------------------------------------------------
        property "ProcessPhase"         { set = false, default = IHttpContextHandler.ProcessPhase.Head }
        property "AsGlobalHandler"      { set = false, default = true }
        property "Priority"             { set = false, default = IHttpContextHandler.HandlerPriority.Lower }

        -----------------------------------------------------------------------
        --                          static property                          --
        -----------------------------------------------------------------------
        -- the unique storage provider
        __Static__() property "Default" { type = ISessionStorageProvider, handler = function(self, new, old) if old then old:Dispose() end end }

        -----------------------------------------------------------------------
        --                          inherit method                           --
        -----------------------------------------------------------------------
        function Process(self, context)
            local session = context.RawSession
            if session then
                if session.Canceled then
                    return self:RemoveItems(session.SessionID)
                elseif session.IsNewSession or session.ItemsChanged then
                    return self:SetItems(session.SessionID, session.RawItems, session.Timeout)
                elseif session.TimeoutChanged then
                    return self:ResetItems(session.SessionID, session.Timeout)
                end
            end
        end

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        --- Whether the session ID existed in the storage.
        __Abstract__() function Contains(self, id) end

        --- Get session item
        __Abstract__() function GetItems(self, id) end

        --- Remove session item
        __Abstract__() function RemoveItems(self, id) end

        --- Update the item with current session data
        __Abstract__() function SetItems(self, id, item, timeout) end

        --- Update the item's timeout
        __Abstract__() function ResetItems(self, id, timeout) end

        -----------------------------------------------------------------------
        --                           initializer                            --
        -----------------------------------------------------------------------
        function __init(self)
            if self.Application then
                self.Application[ISessionStorageProvider] = self
            else
                ISessionStorageProvider.Default = self
            end
        end
    end)

    --- the http session
    __Sealed__() class "System.Web.HttpSession" (function (_ENV)

        export { System.Web.ISessionIDManager, System.Web.ISessionStorageProvider, System.Date, "rawset" }

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- Gets a value storage table
        __Indexer__()
        __Final__() property "Items"            {
            set = function(self, key, value)
                if self.RawItems[key] ~= value then
                    self.ItemsChanged = true
                    self.RawItems[key] = value
                end
            end,
            get = function(self, key)
                return self.RawItems[key]
            end,
        }

        --- Gets the unique identifier for the session
        __Final__() property "SessionID"        { field = 1, set = false }

        --- The raw item table
        __Final__() property "RawItems"         { field = 2, set = false, default = function(self) return {} end }

        --- Gets or sets the date time, allowed the next request access the session
        __Set__ (PropertySet.Clone)
        __Final__() property "Timeout"          { field = 3, type = Date, handler = function(self) self.TimeoutChanged = true end }

        --- Whether the time out is changed
        __Final__() property "TimeoutChanged"   { field = 4, type = Boolean }

        --- Whether the current session is canceled
        __Final__() property "Canceled"         { field = 5, type = Boolean }

        --- Gets a value indicating whether the session was created with the current request or its timeout is changed
        __Final__() property "IsNewSession"     { field = 6, type = Boolean }

        --- Whether the session items changed
        __Final__() property "ItemsChanged"     { field = 7, type = Boolean }

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        --- Get or generate the session for a http context
        __Arguments__{ System.Web.HttpContext }
        function __ctor(self, context)
            -- Build Session
            local manager   = context.Application[ISessionIDManager]       or ISessionIDManager.Default
            local provider  = context.Application[ISessionStorageProvider] or ISessionStorageProvider.Default

            if not manager  then throw("No SessionIDManager Installed")       end
            if not provider then throw("No SessionStorageProvider Installed") end

            local id        = manager:GetSessionID(context)
            local item      = id and provider:GetItems(id)

            if item then
                rawset(self, 1, id)
                rawset(self, 2, item)

                if manager.KeepAlive then
                    self.Timeout = Date.Now:AddMinutes(manager.TimeoutMinutes)
                end
            else
                id, item    = nil
                while not id or provider:Contains(id) do
                    id      = manager:CreateSessionID(context)
                end

                rawset(self, 1, id)

                self.IsNewSession = true
                self.Timeout = Date.Now:AddMinutes(manager.TimeoutMinutes)
            end
        end
    end)
end)
