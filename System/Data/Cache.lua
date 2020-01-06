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
        --- Try sets the the value with non-exist key to the cache, return true if success
        __Abstract__() function TrySet(self, key, value, expiretime, ignoreclass) end

        --- Sets key-value pair to the cache
        __Abstract__() function Set(self, key, value, expiretime, ignoreclass) end

        --- Sets the expire time for a key
        __Abstract__() function SetExpireTime(self, key, expiretime) end

        --- Gets value for a key
        __Abstract__() function Get(self, key, class) end

        --- Whether the key existed in the cache
        __Abstract__() function Exist(self, key) end

        --- Delete a key from the cache
        __Abstract__() function Delete(self, key) end
    end)
end)