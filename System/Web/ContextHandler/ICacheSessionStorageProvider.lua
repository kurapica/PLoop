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

        -----------------------------------------------------------------------
        --                          inherit method                           --
        -----------------------------------------------------------------------
        function Contains(self, id)
            return self.Storage[id] and true or false
        end

        function GetItems(self, id)
            local item = self.Storage[id]
            if item then
                local timeout = self.Timeout[id]
                if timeout and timeout.Time < ostime() then
                    self:RemoveItem(id)
                else
                    return item
                end
            end
        end

        function RemoveItems(self, id)
            self.Storage[id] = nil
            self.Timeout[id] = nil
        end

        function SetItems(self, id, item, timeout)
            self.Storage[id] = item
            if timeout then
                self.Timeout[id] = timeout
            end
        end

        function ResetItems(self, id, timeout)
            if timeout and self.Storage[id] then
                self.Timeout[id] = timeout
            end
        end
    end)
end)