--===========================================================================--
--                                                                           --
--                             System.Data.Cache                             --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2018/09/07                                               --
-- Update Date  :   2018/09/07                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    --- The basic cache interface
    __Sealed__() interface "System.Data.ICache" (function(_ENV)
        extend "System.IAutoClose"

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- Set key-value pair to the cache
        __Abstract__() function Set(self, key, value, expiretime) end

        --- Set the expire time for a key
        __Abstract__() function SetExpireTime(self, key, expiretime) end

        --- Get value for a key
        __Abstract__() function Get(self, key) end

        --- Whether the key existed in the cache
        __Abstract__() function Exist(self, key) end

        --- Delete a key from the cache
        __Abstract__() function Delete(self, key) end
    end)
end)