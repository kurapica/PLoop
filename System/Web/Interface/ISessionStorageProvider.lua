--===========================================================================--
--                                                                           --
--                    System.Web.ISessionStorageProvider                     --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2016/03/14                                               --
-- Update Date  :   2018/03/15                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    --- Represents the interface of sessio1n storage provider
    __Sealed__() interface "System.Web.ISessionStorageProvider" (function (_ENV)
        extend "IHttpContextHandler"

        export { ISessionStorageProvider }

        -----------------------------------------------------------------------
        --                         inherit property                          --
        -----------------------------------------------------------------------
        property "ProcessPhase"         { set = false, default = IHttpContextHandler.ProcessPhase.Head }
        property "AsGlobalHandler"      { set = false, default = true }

        -----------------------------------------------------------------------
        --                          static property                          --
        -----------------------------------------------------------------------
        -- the unique storage provider
        __Static__() property "Default" { type = ISessionStorageProvider, handler = function(self, new, old) if old then old:Dispose() end end }

        -----------------------------------------------------------------------
        --                          inherit method                           --
        -----------------------------------------------------------------------
        function Process(self, context)
            local session = context.Session
            if session then
                if session.Canceled then
                    return self:RemoveItems(session.SessionID)
                else
                    return self:SetItems(session.SessionID, session.Items, session.Timeout)
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

        --- Create new seesion item with timeout
        __Abstract__() function CreateItems(self, id, timeout) end

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
                ISessionStorageProvider.Default     = self
            end
        end
    end)
end)
