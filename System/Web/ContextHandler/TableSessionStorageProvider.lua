--===========================================================================--
--                                                                           --
--                  System.Web.TableSessionStorageProvider                   --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2016/03/15                                               --
-- Update Date  :   2018/04/02                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    --- A test session storage provider
    __Sealed__() class "System.Web.TableSessionStorageProvider" (function (_ENV)
        extend "ISessionStorageProvider"

        export {
            ostime              = os.time,
            pairs               = pairs,
        }

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

        function CreateItems(self, id, timeout)
            self:ClearTimeoutItems()
            self.Storage[id] = {}
            self.Timeout[id] = timeout
            return self.Storage[id]
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

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        function ClearTimeoutItems(self)
            local storage   = self.Storage
            local timeouts  = self.Timeout
            local now       = ostime()
            for id in pairs(storage) do
                if timeouts[id] and timeouts[id].Time < now then
                    storage[id] = nil
                    timeouts[id] = nil
                end
            end
        end

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        __Arguments__{ Application/nil, Table/nil, Table/nil }
        function __ctor(self, app, storage, timeout)
            self.Application = app
            rawset(self, "Storage", storage or {})
            rawset(self, "Timeout", timeout or {})
        end
    end)
end)