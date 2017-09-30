--========================================================--
--                System.Collections.Dictionary           --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2016/02/28                              --
--========================================================--

--========================================================--
_ENV = Module     "System.Collections.Dictionary"    "1.1.1"
--========================================================--

namespace "System.Collections"

import "System.Threading"

-----------------------
-- Interface
-----------------------
-- Interface for Dictionay
__Doc__[[Provide basic support for collection of key-value pairs]]
interface "IDictionary" { Iterable }

-----------------------
-- Dictionary
-----------------------
__Sealed__() __SimpleClass__()
class "Dictionary" (function (_ENV)
    extend "IDictionary"

    -----------------------
    -- Method
    -----------------------
    GetIterator = pairs

    -----------------------
    -- Constructor
    -----------------------
    __Arguments__{ }
    function Dictionary(self) end

    __Arguments__{ RawTable, RawTable }
    function Dictionary(self, lstKey, lstValue)
        local iter, o, idx, value = ipairs(lstValue)
        for _, key in ipairs(lstKey) do
            idx, value = iter(o, idx)
            if idx then
                rawset(self, key, value)
            else
                break
            end
        end
    end

    __Arguments__{ IDictionary }
    function Dictionary(self, dict)
        for key, value in lst:GetIterator() do
            rawset(self, key, value)
        end
    end

    __Arguments__{ IList, IList }
    function Dictionary(self, lstKey, lstValue)
        local iter, o, idx, value = lstValue:GetIterator()
        for _, key in lstKey:GetIterator() do
            idx, value = iter(o, idx)
            if idx then
                rawset(self, key, value)
            else
                break
            end
        end
    end

    __Arguments__{ Callable, Argument(Any, true), Argument(Any, true) }
    function Dictionary(self, iter, obj, idx)
        for key, value in iter, obj, idx do
            rawset(self, key, value)
        end
    end
end)

-----------------------
-- DictionaryStreamWorker
-----------------------
__Final__() __Sealed__()
class "DictionaryStreamWorker" (function (_ENV)
    extend "IDictionary"

    -- Keep idle workers for re-usage
    IdleWorkers = {}

    ---------------------------
    -- Method
    ---------------------------
    function GetIterator(self)
        local targetDict = self.TargetDict
        local map = self.MapAction
        local filter = self.FilterAction

        -- Clear self and put self into IdleWorkers
        self.TargetDict = nil
        self.MapAction = nil
        self.FilterAction = nil

        if #IdleWorkers < 10 then tinsert(IdleWorkers, self) end

        -- Generate the iterator
        local dowork

        -- Generate the do-work
        if filter then
            -- Check Function
            if map then
                dowork = function(key, value) if filter(key, value) then yield(key, map(key, value)) end end
            else
                dowork = function(key, value) if filter(key, value) then yield(key, value) end end
            end
        else
            -- No filter
            if map then
                dowork = function(key, value) yield(key, map(key, value)) end
            else
                dowork = function(key, value) yield(key, value) end
            end
        end

        -- Generate the for iterator
        return Threading.Iterator(function() for key, value in targetDict:GetIterator() do dowork(key, value) end end)
    end

    ---------------------------
    -- Queue Method
    ---------------------------
    __Doc__[[Map the items to other type datas]]
    __Arguments__{ Callable }
    function Map(self, func) self.MapAction = func return self end

    __Doc__[[Used to filter the items with a check function]]
    __Arguments__{ Callable }
    function Filter(self, func) self.FilterAction = func return self end

    ----------------------------
    -- Constructor
    ----------------------------
    __Arguments__{ IDictionary }
    function DictionaryStreamWorker(self, dict)
        self.TargetDict = dict
    end

    ----------------------------
    -- Meta-method
    ----------------------------
    __Arguments__{ IDictionary }
    function __exist(dict)
        local worker = tremove(IdleWorkers)
        if worker then worker.TargetDict = dict end
        return worker
    end
end)

----------------------------
-- Install to IDictionary
----------------------------
__Sealed__()
interface "IDictionary" (function (_ENV)
    ---------------------------
    -- Queue Method
    ---------------------------
    __Doc__[[Map the items to other type datas]]
    __Arguments__{ Callable }
    function Map(self, func) return DictionaryStreamWorker(self):Map(func) end

    __Doc__[[Used to filter the items with a check function]]
    __Arguments__{ Callable }
    function Filter(self, func) return DictionaryStreamWorker(self):Filter(func) end

    ---------------------------
    -- Final Method
    ---------------------------
    __Doc__[[Combine the key-value pairs to get a result]]
    __Arguments__{ Callable, Argument(Any, true) }
    function Reduce(self, func, init)
        for key, value in self:GetIterator() do init = func(key, value, init) end
        return init
    end

    __Doc__[[Call the function for each element or set property's value for each element]]
    __Arguments__{ Callable, Argument(Any, true, nil, nil, true)  }
    function Each(self, func, ...) for key, value in self:GetIterator() do func(key, value, ...) end end

    ---------------------------
    -- List - Property
    ---------------------------
    __Doc__[[Get a list stream worker of the dictionary's keys]]
    property "Keys" {
        Get = function (self)
            return ListStreamWorker.GetWorker( Threading.Iterator(function()
                local index = 0
                for key in self:GetIterator() do
                    index = index + 1
                    yield(index, key)
                end
            end) )
        end
    }

    __Doc__[[Get a list stream worker of the dictionary's values]]
    property "Values" {
        Get = function (self)
            return ListStreamWorker.GetWorker( Threading.Iterator(function()
                local index = 0
                for _, value in self:GetIterator() do
                    index = index + 1
                    yield(index, value)
                end
            end) )
        end
    }
end)
