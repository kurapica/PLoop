--========================================================--
--                System.Collections.List                 --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2016/02/28                              --
--========================================================--

--========================================================--
_ENV = Module     "System.Collections.List"          "1.0.1"
--========================================================--

namespace "System.Collections"

import "System.Threading"

-----------------------
-- Interface
-----------------------
-- Interface for List
__Doc__[[Provide basic support for list collection]]
interface "IList" { Iterable }

__Doc__[[The object should provide a Countable]]
__Sealed__()
interface "ICountable" (function (_ENV)
    -- Since Lua 5.1 don't support __len on table, use Count property instead.
    __Doc__[[Get the count of items in the object]]
    __Require__() property "Count" { Set = false, Get = function (self) return #self end }
end)

__Doc__[[The list must be an indexed list that the system can use obj[idx] to access the datas]]
__Sealed__()
interface "IIndexedList" { IList, ICountable }

-----------------------
-- List
-----------------------
__Sealed__() __SimpleClass__()
class "List" (function (_ENV)
    extend "IIndexedList"

    -----------------------
    -- Method
    -----------------------
    GetIterator = ipairs

    __Doc__[[Insert an item to the list]]
    Insert = tinsert

    __Doc__[[Whether an item existed in the list]]
    function Contains(self, item) for i, chk in self:GetIterator() do if chk == item then return true end end return false end

    __Doc__[[Get the index of the item if it existed in the list]]
    function IndexOf(self, item) for i, chk in self:GetIterator() do if chk == item then return i end end end

    __Doc__[[Remove an item]]
    function Remove(self, item) local i = self:IndexOf(item) if i then return self:RemoveByIndex(i) end end

    __Doc__[[Remove an item from the tail or the given index]]
    RemoveByIndex = tremove

    __Doc__[[Clear the list]]
    function Clear(self) for i = self.Count, 1, -1 do self[i] = nil end end

    -----------------------
    -- Constructor
    -----------------------
    __Arguments__{ }
    function List(self) end

    __Arguments__{ IList }
    function List(self, lst)
        local ins = self.Insert
        for idx, item in lst:GetIterator() do
            ins(self, item)
        end
    end

    __Arguments__{ Callable, Argument(Any, true), Argument(Any, true) }
    function List(self, iter, obj, idx)
        local ins = self.Insert
        for key, item in iter, obj, idx do
            if item ~= nil then
                ins(self, item)
            else
                ins(self, key)
            end
        end
    end

    __Arguments__{ NaturalNumber, Callable }
    function List(self, count, initValue)
        local ins = self.Insert
        for i = 1, count do
            ins(self, initValue(i))
        end
    end

    __Arguments__{ NaturalNumber, Argument(Any, true) }
    function List(self, count, initValue)
        local ins = self.Insert
        if initValue ~= nil then
            for i = 1, count do ins(self, initValue) end
        else
            for i = 1, count do ins(self, i) end
        end
    end

    __Arguments__{ { Type = Any, IsList = true } }
    function List(self, ...)
        local ins = self.Insert
        for i = 1, select("#", ...) do
            ins(self, (select(i, ...)))
        end
    end

    -----------------------
    -- Meta-method
    -----------------------
    __Arguments__{ NegtiveInteger }
    function __index(self, idx)
        local cnt = self.Count

        idx = cnt + idx + 1
        if idx >= 1 and idx <= cnt then
            return self[idx]
        else
            return nil
        end
    end

    __Arguments__{ Any }
    function __index(self, idx)
        return nil
    end
end)

-----------------------
-- ListStreamWorker
-----------------------
__Final__() __Sealed__()
class "ListStreamWorker" (function (_ENV)
    extend "IList"

    -- Keep idle workers for re-usage
    IdleWorkers = {}

    ---------------------------
    -- Method
    ---------------------------
    __Iterator__()
    function GetIterator(self)
        local targetList    = self.TargetList
        local targetIter    = self.TargetIter
        local targetObj     = self.TargetObj
        local targetIdx     = self.TargetIndex

        local map           = self.MapAction
        local filter        = self.FilterAction
        local rangeStart    = self.RangeStart
        local rangeStop     = self.RangeStop
        local rangeStep     = self.RangeStep

        -- Clear self and put self into IdleWorkers
        self.TargetList     = nil
        self.TargetIter     = nil
        self.TargetObj      = nil
        self.TargetIndex    = nil

        self.MapAction      = nil
        self.FilterAction   = nil
        self.RangeStart     = nil
        self.RangeStop      = nil
        self.RangeStep      = nil

        if #IdleWorkers < 10 then tinsert(IdleWorkers, self) end

        -- So we should run an iterator over the targetList to fetch datas, like link list
        if targetList then
            targetIter, targetObj, targetIdx = targetList:GetIterator()
        end

        local _, stop

        -- Generate the iterator
        if not rangeStart then
            rangeStart  = 1
            rangeStop   = math.huge
            rangeStep   = 1
        else
            local lstCount
            local targetCls = targetList and Reflector.GetObjectClass(targetList)

            -- If the targetCls is ICountable, we can deal with negative position
            if targetCls and Reflector.IsExtendedInterface(targetCls, ICountable) then lstCount = targetList.Count end

            if lstCount then
                if rangeStart < 0 then rangeStart = lstCount + rangeStart + 1 end
                if rangeStop  < 0 then rangeStop  = lstCount + rangeStop + 1 end
            else
                if rangeStop == -1 then rangeStop = math.huge end
                if rangeStart < 0 or rangeStop < 0 then error(("%s can't handle negative index"):format(tostring(targetCls)), 2) end
            end

            if targetCls and Reflector.IsExtendedInterface(targetCls, IIndexedList) then
                -- The targetList should be used like targetList[index]
                if rangeStep == 0 or
                    (rangeStart > rangeStop and rangeStep > 0) or
                    (rangeStart < rangeStop and rangeStep < 0) then
                    return
                end

                if map then
                    if filter then
                        for i = rangeStart, rangeStop, rangeStep do
                            local item = targetList[i]
                            if item == nil then return end
                            if filter(item) then
                                _, _, stop = yield(i, map(item), item)
                                if stop then return end
                            end
                        end
                    else
                        for i = rangeStart, rangeStop, rangeStep do
                            local item = targetList[i]
                            if item == nil then return end
                            _, _, stop = yield(i, map(item), item)
                            if stop then return end
                        end
                    end
                else
                    if filter then
                        for i = rangeStart, rangeStop, rangeStep do
                            local item = targetList[i]
                            if item == nil then return end
                            if filter(item) then
                                _, _, stop = yield(i, item)
                                if stop then return end
                            end
                        end
                    else
                        for i = rangeStart, rangeStop, rangeStep do
                            local item = targetList[i]
                            if item == nil then return end
                            _, _, stop = yield(i, item)
                            if stop then return end
                        end
                    end
                end
                return
            else
                if lstCount then
                    if rangeStart > rangeStop then rangeStart, rangeStop, rangeStep = rangeStop, rangeStart, - rangeStep end
                    if rangeStart < 1 then rangeStart = 1 end
                    if rangeStart > lstCount then rangeStep = -1 end -- no items would be scaned
                else
                    if rangeStart > rangeStop then rangeStart, rangeStop, rangeStep = rangeStop, rangeStart, - rangeStep end
                end

            end
        end

        if rangeStep < 1 then return end

        local idx = 1
        local stepCnt = rangeStep
        local item

        while idx < rangeStart do
            targetIdx, item = targetIter(targetObj, targetIdx)
            if item == nil then return end
            idx = idx + 1
        end

        if map then
            if filter then
                while idx <= rangeStop do
                    targetIdx, item = targetIter(targetObj, targetIdx)
                    if item == nil then return end

                    if stepCnt == rangeStep then
                        stepCnt = 0
                        if filter(item) then
                            _, _, stop = yield(targetIdx, map(item), item)
                            if stop then return end
                        end
                    end

                    stepCnt = stepCnt + 1
                    idx = idx + 1
                end
            else
                while idx <= rangeStop do
                    targetIdx, item = targetIter(targetObj, targetIdx)
                    if item == nil then return end

                    if stepCnt == rangeStep then
                        stepCnt = 0
                        _, _, stop = yield(targetIdx, map(item), item)
                        if stop then return end
                    end

                    stepCnt = stepCnt + 1
                    idx = idx + 1
                end
            end
        else
            if filter then
                while idx <= rangeStop do
                    targetIdx, item = targetIter(targetObj, targetIdx)
                    if item == nil then return end

                    if stepCnt == rangeStep then
                        stepCnt = 0
                        if filter(item) then
                            _, _, stop = yield(targetIdx, item)
                            if stop then return end
                        end
                    end

                    stepCnt = stepCnt + 1
                    idx = idx + 1
                end
            else
                while idx <= rangeStop do
                    targetIdx, item = targetIter(targetObj, targetIdx)
                    if item == nil then return end

                    if stepCnt == rangeStep then
                        stepCnt = 0
                        _, _, stop = yield(targetIdx, item)
                        if stop then return end
                    end

                    stepCnt = stepCnt + 1
                    idx = idx + 1
                end
            end
        end
    end

    ---------------------------
    -- Queue Method
    ---------------------------
    __Arguments__{ Callable }
    function Map(self, func)
        self.MapAction = func
        return self
    end

    __Doc__[[Map the items to other type datas]]
    __Arguments__{ String }
    function Map(self, feature)
        self.MapAction = function(item)
            if type(item) == "table" then
                local val = item[feature]
                if type(val) == "function" then return val(item) end
                return val
            else
                return item
            end
        end
        return self
    end

    __Arguments__{ Callable }
    function Filter(self, func)
        self.FilterAction = func
        return self
    end

    __Doc__[[Used to filter the items with a check function]]
    __Arguments__{ String, Argument(Any, true) }
    function Filter(self, feature, value)
        self.FilterAction = function(item)
            if type(item) == "table" then
                local val = item[feature]
                if type(val) == "function" then val = val(item) end
                if value ~= nil then return val == value end
                return val and true or false
            else
                return false
            end
        end
        return self
    end

    __Doc__[[Used to select items with ranged index]]
    __Arguments__{ Argument(Integer, true, 1), Argument(Integer, true, -1), Argument(Integer, true, 1) }
    function Range(self, start, stop, step)
        self.RangeStart, self.RangeStop, self.RangeStep = start, stop, step
        return self
    end

    ----------------------------
    -- Constructor
    ----------------------------
    __Arguments__{ IList }
    function ListStreamWorker(self, list)
        self.TargetList = list
    end

    __Arguments__{ Callable, Argument(Any, true), Argument(Any, true) }
    function ListStreamWorker(self, iter, obj, idx)
        self.TargetIter = iter
        self.TargetObj = obj
        self.TargetIndex = idx
    end

    ----------------------------
    -- Meta-method
    ----------------------------
    __Static__() __Arguments__{ IList }
    function GetWorker(list)
        local worker = tremove(IdleWorkers)
        if worker then worker.TargetList = list end
        return worker or ListStreamWorker(list)
    end

    __Static__() __Arguments__{ Callable, Argument(Any, true), Argument(Any, true) }
    function GetWorker(iter, obj, idx)
        local worker = tremove(IdleWorkers)
        if worker then
            worker.TargetIter = iter
            worker.TargetObj = obj
            worker.TargetIndex = idx
        end
        return worker or ListStreamWorker(iter, obj, idx)
    end
end)

----------------------------
-- Install to IList
----------------------------
__Sealed__()
interface "IList" (function (_ENV)
    ---------------------------
    -- Queue Method
    ---------------------------
    __Doc__[[Map the items to other type datas]]
    __Arguments__{ Callable }
    function Map(self, func) return ListStreamWorker.GetWorker(self):Map(func) end

    __Arguments__{ String }
    function Map(self, feature) return ListStreamWorker.GetWorker(self):Map(feature) end

    __Doc__[[Used to filter the items with a check function]]
    __Arguments__{ Callable }
    function Filter(self, func) return ListStreamWorker.GetWorker(self):Filter(func) end

    __Arguments__{ String, Argument(Any, true) }
    function Filter(self, feature, value) return ListStreamWorker.GetWorker(self):Filter(feature, value) end

    __Doc__[[Used to select items with ranged index]]
    __Arguments__{ Argument(Integer, true, 1), Argument(Integer, true, -1), Argument(Integer, true, 1) }
    function Range(self, start, stop, step) return ListStreamWorker.GetWorker(self):Range(start, stop, step) end

    ---------------------------
    -- Final Method
    ---------------------------
    __Doc__[[Convert the selected items to a list]]
    __Arguments__{ Argument(-IList, true, List) }
    function ToList(self, cls) return cls(self) end

    __Doc__[[Combine the items to get a result]]
    __Arguments__{ Callable, Argument(Any, true) }
    function Reduce(self, func, init)
        for _, obj in self:GetIterator() do
            if init == nil then
                init = obj
            else
                init = func(obj, init)
            end
        end
        return init
    end

    __Doc__[[Call the function for each element or set property's value for each element]]
    __Arguments__{ Callable, Argument(Any, true, nil, nil, true) }
    function Each(self, func, ...)
        for _, obj in self:GetIterator() do
            func(obj, ...)
        end
    end

    __Arguments__{ String, Argument(Any, true, nil, nil, true) }
    function Each(self, feature, ...)
        local getObjectClass = Reflector.GetObjectClass
        local cls, cmethod

        for _, obj in self:GetIterator() do
            if type(obj) == "table" then
                if getObjectClass(obj) ~= cls then
                    cls = getObjectClass(obj)
                    cmethod = nil
                    if cls then
                        local ret = cls[feature]
                        if type(ret) == "function" then cmethod = ret end
                    end
                end

                local method = rawget(obj, feature) or cmethod

                if type(method) == "function" then
                    method(obj, ...)
                else
                    obj[feature] = ...
                end
            end
        end
    end

    __Doc__[[Check if any element meet the requirement of the target function]]
    __Arguments__{ Callable, Argument(Any, true, nil, nil, true) }
    function Any(self, chk, ...)
        local iter, obj, idx, val = self:GetIterator()
        idx, val = iter(obj, idx)
        while idx do
            if chk(val, ...) then
                -- Pass true to end iter if it support
                iter(obj, idx, true)
                return true
            end
            idx, val = iter(obj, idx)
        end
        return false
    end

    __Doc__[[Check if all elements meet the requirement of the target function]]
    __Arguments__{ Callable, Argument(System.Any, true, nil, nil, true) }
    function All(self, chk, ...)
        local iter, obj, idx, val = self:GetIterator()
        idx, val = iter(obj, idx)
        while idx do
            if not chk(val, ...) then
                -- Pass true to end iter if it support
                iter(obj, idx, true)
                return false
            end
            idx, val = iter(obj, idx)
        end
        return true
    end

    __Doc__[[Get the first element of the list]]
    __Arguments__{ Callable, Argument(System.Any, true, nil, nil, true) }
    function First(self, chk, ...)
        local iter, obj, idx, val = self:GetIterator()
        idx, val = iter(obj, idx)
        while idx do
            if chk(val, ...) then
                -- Pass true to end iter if it support
                iter(obj, idx, true)
                return val
            end
            idx, val = iter(obj, idx)
        end
    end

    __Arguments__ {}
    function First(self)
        local iter, obj, idx, val = self:GetIterator()
        idx, val = iter(obj, idx)
        while idx do
            iter(obj, idx, true)
            return val
        end
        return false
    end

    __Doc__[[Get the first element of the list, if not existed use the default as result]]
    __Arguments__{ System.Any, Callable, Argument(System.Any, true, nil, nil, true) }
    function FirstOrDefault(self, default, chk, ...)
        local iter, obj, idx, val = self:GetIterator()
        idx, val = iter(obj, idx)
        while idx do
            if chk(val, ...) then
                -- Pass true to end iter if it support
                iter(obj, idx, true)
                return val
            end
            idx, val = iter(obj, idx)
        end
        return default
    end

    __Arguments__{ System.Any }
    function FirstOrDefault(self, default)
        local iter, obj, idx, val = self:GetIterator()
        idx, val = iter(obj, idx)
        while idx do
            iter(obj, idx, true)
            return val
        end
        return default
    end
end)