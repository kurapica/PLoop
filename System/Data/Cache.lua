--===========================================================================--
--                                                                           --
--                             System.Data.Cache                             --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2018/09/07                                               --
-- Update Date  :   2020/05/19                                               --
-- Version      :   2.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Data"

    --- The basic cache interface for key-value storage
    __Sealed__()
    interface "ICache" (function(_ENV)
        extend "System.IAutoClose"

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- Try sets the the value with non-exist key to the cache, return true if success
        __Abstract__()
        function TrySet(self, key, value, expiretime) end

        --- Sets key-value pair to the cache
        __Abstract__()
        function Set(self, key, value, expiretime) end

        --- Increase the value by 1 or given increment, return the final result
        __Abstract__()
        function Incr(self, key, increment) end

        --- Decrease the value by 1 or given decrement, return the final result
        __Abstract__()
        function Decr(self, key, decrement) end

        --- Sets the expire time for a key
        __Abstract__()
        function SetExpireTime(self, key, expiretime) end

        --- Gets value for a key
        __Abstract__()
        function Get(self, key, class) end

        --- Whether the key existed in the cache
        __Abstract__()
        function Exist(self, key) end

        --- Delete a key from the cache
        __Abstract__()
        function Delete(self, key) end
    end)

    --- The cache interface for hash-field-value storage
    __Sealed__()
    interface "IHashCache"              (function(_ENV)
        extend "System.IAutoClose"

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- Sets the expire time for the hash key
        __Abstract__()
        function SetExpireTime(self, hash, expiretime) end

        --- Whether the hash key existed in the cache
        __Abstract__()
        function Exist(self, hash) end

        --- Delete a hash key from the cache
        __Abstract__()
        function Delete(self, hash) end

        --- Try sets the hash field value if not existed, return true if success
        __Abstract__()
        function HTrySet(self, hash, field, value) end

        --- Sets the hash field value to the cache
        __Abstract__()
        function HSet(self, hash, field, value) end

        --- Gets the hash field value
        __Abstract__()
        function HGet(self, hash, field, class) end

        --- Increase the field value by 1 or given increment, return the final result
        __Abstract__()
        function HIncr(self, hash, field, increment) end

        --- Decrease the field value by 1 or given decrement, return the final result
        __Abstract__()
        function HDecr(self, hash, field, decrement) end

        --- Whether the field existed in the hash cache
        __Abstract__()
        function HExist(self, hash, field) end

        --- Delete a field from the hash cache
        __Abstract__()
        function HDelete(self, hash, field) end

        --- Return an iterator to fetch all field-value pairs in the hash cache
        __Abstract__() __Iterator__()
        function HPairs(self, hash, type) end
    end)

    --- The cache interface for list-index-value cache storage
    __Sealed__()
    interface "IListCache" (function(_ENV)
        --- Sets the expire time for the list
        __Abstract__()
        function SetExpireTime(self, list, expiretime) end

        --- Whether the list existed in the cache
        __Abstract__()
        function Exist(self, list) end

        --- Delete a list from the cache
        __Abstract__()
        function Delete(self, list) end

        --- Insert elements at the head of the list
        __Abstract__()
        function LPush(self, list, ...) end

        --- Try insert elements at the head of the list when the list existed
        __Abstract__()
        function TryLPush(self, list, ...) end

        --- Insert elements at the tail of the list
        __Abstract__()
        function RPush(self, list, ...) end

        --- Try insert elements at the tail of the list when the list existed
        __Abstract__()
        function TryRPush(self, list, ...) end

        --- Pop and return the elements from the head of the list with the given count or just the head element
        __Abstract__()
        function LPop(self, list, count, type) end

        --- Pop and return the elements from the tail of the list with the given count or just the tail element
        __Abstract__()
        function RPop(self, list, count, type) end

        --- Sets the value to the list with the given index
        __Abstract__()
        function LSet(self, list, index, value) end

        --- Gets the element from the list with the given index
        __Abstract__()
        function LItem(self, list, index, type) end

        --- Return an iterator to get elements from the list with the given start index(1-base) and the count(default 1)
        __Abstract__() __Iterator__()
        function LPairs(self, list, start, count, type) end

        --- Gets the list length
        __Abstract__()
        function LLength(self, list) end
    end)

    --- The cache interface for the set cache storage where all elements are unique saved
    __Sealed__()
    interface "ISetCache"               (function(_ENV)
        --- Sets the expire time for the set
        __Abstract__()
        function SetExpireTime(self, set, expiretime) end

        --- Whether the set existed in the cache
        __Abstract__()
        function Exist(self, set) end

        --- Delete a set from the cache
        __Abstract__()
        function Delete(self, set) end

        --- Add an element to the set
        __Abstract__()
        function SAdd(self, set, element) end

        --- Remove an element from the set
        __Abstract__()
        function SRemove(self, set, element) end

        --- Whether the element is in the set
        __Abstract__()
        function SExist(self, set, element) end

        --- returns an iterator to get all the elements from the set
        __Abstract__() __Iterator__()
        function SPairs(self, set, type) end
    end)

    --- The cache interface for the sorted set cache storage, where all elements are saved with score values as order
    __Sealed__()
    interface "ISortSetCache"           (function(_ENV)
        --- Sets the expire time for the sorted set
        __Abstract__()
        function SetExpireTime(self, zset, expiretime) end

        --- Whether the sorted set existed in the cache
        __Abstract__()
        function Exist(self, zset) end

        --- Delete a sorted set from the cache
        __Abstract__()
        function Delete(self, zset) end

        --- Gets the elements count from the sorted set
        __Abstract__()
        function ZCount(self, zset) end

        --- Add an element to the sorted set with score
        __Abstract__()
        function ZAdd(self, zset, element, score) end

        --- Remove an element from the sorted set
        __Abstract__()
        function ZRemove(self, zset, element) end

        --- Remove elements from the sorted set by the score
        __Abstract__()
        function ZRemoveByScore(self, zset, min, max) end

        --- Remove elements from the sorted set by the rank
        __Abstract__()
        function ZRemoveByRank(self, zset, start, count) end

        --- Increase an element's score in the sorted set
        __Abstract__()
        function ZIncr(self, zset, element, increment) end

        --- Decrease an element's score in the sorted set
        __Abstract__()
        function ZDecr(self, zset, element, decrement) end

        --- Gets the index of a given element in the sorted set
        __Abstract__()
        function ZRank(self, zset, element) end

        --- Gets the rev-index of the given element in the sorted set(from largest to smallest)
        __Abstract__()
        function ZRevRank(self, zset, element) end

        --- Gets the score of a given element in the sorted set
        __Abstract__()
        function ZScore(self, zset, element) end

        --- Return an iterator to get elements from the given start and count by order(from smallest to largest)
        __Abstract__() __Iterator__()
        function ZPairs(self, zset, start, count, type) end

        --- Return an iterator to get elements from the given start and count by order(from largest to smallest)
        __Abstract__() __Iterator__()
        function ZPairsDesc(self, zset, start, count, type) end

        --- Return an iterator to get elements with scores from the given start and count by order(from smallest to largest)
        __Abstract__() __Iterator__()
        function ZSPairs(self, zset, start, count, type) end

        --- Return an iterator to get elements with scores from the given start and count by order(from largest to smallest)
        __Abstract__() __Iterator__()
        function ZSPairsDesc(self, zset, start, count, type) end
    end)

    __Sealed__()
    interface "System.Context.ICacheSessionStorageProvider" (function (_ENV)
        extend "System.Context.ISessionStorageProvider"

        export { with = with }


        -----------------------------------------------------------------------
        --                         abstract property                         --
        -----------------------------------------------------------------------
        --- The prefix that appends to the session id
        __Abstract__()
        property "Prefix"               { type = String }

        -----------------------------------------------------------------------
        --                          abstract method                          --
        -----------------------------------------------------------------------
        --- Used to return a new cache object
        __Abstract__()
        function GetCache(self) end

        -----------------------------------------------------------------------
        --                          inherit method                           --
        -----------------------------------------------------------------------
        --- Whether the session ID existed in the storage.
        function Contains(self, id)
            id                          = self.Prefix and (self.Prefix .. id) or id
            return (with(self:GetCache())(function(cache) return cache:Exist(id) end)) or false
        end

        --- Get session item
        function GetItems(self, id)
            id                          = self.Prefix and (self.Prefix .. id) or id
            return with(self:GetCache())(function(cache) return cache:Get(id) end)
        end

        --- Remove session item
        function RemoveItems(self, id)
            id                          = self.Prefix and (self.Prefix .. id) or id
            return with(self:GetCache())(function(cache) return cache:Delete(id) end)
        end

        --- Update the item with current session data
        function SetItems(self, id, item, timeout)
            id                          = self.Prefix and (self.Prefix .. id) or id
           return  with(self:GetCache())(function(cache) return cache:Set(id, item, timeout) end)
        end

        --- Update the item's timeout
        function ResetItems(self, id, timeout)
            id                          = self.Prefix and (self.Prefix .. id) or id
            return with(self:GetCache())(function(cache) return cache:SetExpireTime(id, timeout) end)
        end

        --- Try sets the item with an un-existed key, return true if success
        function TrySetItems(self, id, item, timeout)
            id                          = self.Prefix and (self.Prefix .. id) or id
            return with(self:GetCache())(function(cache) return cache:TrySet(id, item, timeout) end)
        end
    end)
end)