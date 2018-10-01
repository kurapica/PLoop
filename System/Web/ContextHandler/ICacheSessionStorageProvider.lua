--===========================================================================--
--                                                                           --
--                  System.Web.ICacheSessionStorageProvider                  --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2018/09/14                                               --
-- Update Date  :   2018/09/14                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    --- A test session storage provider
    __Sealed__() class "System.Web.ICacheSessionStorageProvider" (function (_ENV)
        extend "ISessionStorageProvider"

        export { with = with }

        -----------------------------------------------------------------------
        --                          abstract method                          --
        -----------------------------------------------------------------------
        __Abstract__() __Return__{ ICache }:AsInheritable()
        function GetCacheObject(self) end

        -----------------------------------------------------------------------
        --                          inherit method                           --
        -----------------------------------------------------------------------

        --- Whether the session ID existed in the storage.
        function Contains(self, id)
            return (with(self:GetCacheObject())(function(cache)
                return cache:Exist(id)
            end)) or false
        end

        --- Get session item
        function GetItems(self, id)
            return (with(self:GetCacheObject())(function(cache)
                return cache:Get(id)
            end))
        end

        --- Remove session item
        function RemoveItems(self, id)
            with(self:GetCacheObject())(function(cache)
                return cache:Delete(id)
            end)
        end

        --- Update the item with current session data
        function SetItems(self, id, item, timeout)
            with(self:GetCacheObject())(function(cache)
                return cache:Set(id, item, timeout)
            end)
        end

        --- Update the item's timeout
        function ResetItems(self, id, timeout)
            with(self:GetCacheObject())(function(cache)
                return cache:SetExpireTime(id, timeout)
            end)
        end
    end)
end)