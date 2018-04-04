--===========================================================================--
--                                                                           --
--                          System.Collections.List                          --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2016/02/28                                               --
-- Update Date  :   2018/03/16                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Collections"

    --- Represents the list collections that only elements has meanings
    interface "IList" { Iterable }

    --- Represents countable list collections
    __Sealed__()
    interface "ICountable" { IList,
        --- Get the count of items in the object
        __Abstract__(),
        Count = { set = false, get = function (self) return #self end },
    }

    --- Represents the indexed list collections that can use obj[idx] to access the its elements
    __Sealed__()
    interface "IIndexedList" { ICountable }

    --- The default indexed list
    __Sealed__()
    class "List" (function (_ENV)
        extend "IIndexedList"

        export { type = type }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        GetIterator = ipairs

        --- Insert an item to the list
        Insert      = table.insert

        --- Whether an item existed in the list
        function Contains(self, item) for i, chk in self:GetIterator() do if chk == item then return true end end return false end

        --- Get the index of the item if it existed in the list
        function IndexOf(self, item) for i, chk in self:GetIterator() do if chk == item then return i end end end

        --- Remove an item
        function Remove(self, item) local i = self:IndexOf(item) if i then return self:RemoveByIndex(i) end end

        --- Remove an item from the tail or the given index
        RemoveByIndex = table.remove

        --- Clear the list
        function Clear(self) for i = self.Count, 1, -1 do self[i] = nil end end

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{ RawTable }
        function __new(_, lst) return lst, true end

        __Arguments__{ IList }
        function __new(_, lst)
            local i     = 1
            local obj   = {}
            for idx, item in lst:GetIterator() do
                obj[i]  = item
                i       = i + 1
            end
            return obj, true
        end

        __Arguments__{ Callable, Variable.Optional(), Variable.Optional() }
        function __new(_, iter, obj, idx)
            local i     = 1
            local lst   = {}
            for key, item in iter, obj, idx do
                if item ~= nil then
                    lst[i]  = item
                    i   = i + 1
                else
                    lst[i]  = key
                    i   = i + 1
                end
            end
            return lst, true
        end

        __Arguments__{ NaturalNumber, Callable }
        function __new(_, count, initValue)
            local i     = 1
            local obj   = {}
            for i = 1, count do
                obj[i]  = initValue(i)
                i       = i + 1
            end
            return obj, true
        end

        __Arguments__{ NaturalNumber, Variable.Optional() }
        function __new(_, count, initValue)
            local obj   = {}
            if initValue ~= nil then
                for i = 1, count do
                    obj[i]  = initValue
                end
            else
                for i = 1, count do
                    obj[i]  = i
                end
            end
            return obj, true
        end

        __Arguments__.Rest()
        function __new(_, ...)
            return { ... }, true
        end

        -----------------------------------------------------------
        --                      meta-method                      --
        -----------------------------------------------------------
        function __index(self, idx)
            if type(idx) ~= "number" or idx >= 0 then return end
            local cnt = self.Count

            idx = cnt + idx + 1
            if idx >= 1 and idx <= cnt then
                return self[idx]
            else
                return nil
            end
        end
    end)

    --- the list stream worker, used to provide stream filter, map and etc
    -- operations on a list without creating any temp caches
    __Final__() __Sealed__() __NoSuperObject__()
    class "ListStreamWorker" (function (_ENV)
        extend "IList"

        export {
            type                = type,
            yield               = coroutine.yield,
            MATH_HUGE           = math.huge,
            tinsert             = table.insert,
            tremove             = table.remove,
            getobjectclass      = Class.GetObjectClass,
            issubtype           = Class.IsSubType,
        }

        -----------------------------------------------------------
        --                        helpers                        --
        -----------------------------------------------------------
        local getIdleworkers
        local rycIdleworkers

        if Platform.MULTI_OS_THREAD then
            export { Context }

            getIdleworkers      = function()
                local context   = Context.Current
                return context and context[ListStreamWorker]
            end

            rycIdleworkers      = function(worker)
                local context   = Context.Current
                if context then context[ListStreamWorker] = worker end
            end
        else
            -- Keep idle workers for re-usage
            idleworkers         = {}
            getIdleworkers      = function() return tremove(idleworkers) end
            rycIdleworkers      = function(worker) tinsert(idleworkers, worker) end
        end

        -----------------------------------------------------------
        --                       constant                        --
        -----------------------------------------------------------
        FLD_STREAM_TARGETLIST   = 0
        FLD_STREAM_TARGETITER   = 1
        FLD_STREAM_ITEROBJECT   = 2
        FLD_STREAM_ITERINDEX    = 3

        FLD_STREAM_MAPACTITON   = 4
        FLD_STREAM_FILTERACTN   = 5
        FLD_STREAM_RANGESTART   = 6
        FLD_STREAM_RANGESTOP    = 7
        FLD_STREAM_RANGESTEP    = 8

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        __Iterator__()
        function GetIterator(self)
            local targetList    = self[FLD_STREAM_TARGETLIST]
            local targetIter    = self[FLD_STREAM_TARGETITER]
            local targetObj     = self[FLD_STREAM_ITEROBJECT]
            local targetIdx     = self[FLD_STREAM_ITERINDEX]

            local map           = self[FLD_STREAM_MAPACTITON]
            local filter        = self[FLD_STREAM_FILTERACTN]
            local rangeStart    = self[FLD_STREAM_RANGESTART]
            local rangeStop     = self[FLD_STREAM_RANGESTOP]
            local rangeStep     = self[FLD_STREAM_RANGESTEP]

            -- Clear self and put self into idleworkers
            self[FLD_STREAM_TARGETLIST] = nil
            self[FLD_STREAM_TARGETITER] = nil
            self[FLD_STREAM_ITEROBJECT] = nil
            self[FLD_STREAM_ITERINDEX]  = nil

            self[FLD_STREAM_MAPACTITON] = nil
            self[FLD_STREAM_FILTERACTN] = nil
            self[FLD_STREAM_RANGESTART] = nil
            self[FLD_STREAM_RANGESTOP]  = nil
            self[FLD_STREAM_RANGESTEP]  = nil

            rycIdleworkers(self)

            -- So we should run an iterator over the targetList to fetch datas, like link list
            if targetList then
                targetIter, targetObj, targetIdx = targetList:GetIterator()
            end

            local _, stop

            -- Process the iterator
            if not rangeStart then
                rangeStart  = 1
                rangeStop   = MATH_HUGE
                rangeStep   = 1
            else
                local lstCount
                local targetCls = getobjectclass(targetList)

                -- If the targetCls is ICountable, we can deal with negative position
                if targetCls and issubtype(targetCls, ICountable) then lstCount = targetList.Count end

                if lstCount then
                    if rangeStart < 0 then rangeStart = lstCount + rangeStart + 1 end
                    if rangeStop  < 0 then rangeStop  = lstCount + rangeStop + 1 end
                else
                    if rangeStop == -1 then rangeStop = MATH_HUGE end
                    if rangeStart < 0 or rangeStop < 0 then return end
                end

                if targetCls and issubtype(targetCls, IIndexedList) then
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

        -----------------------------------------------------------
        --                     Queue method                      --
        -----------------------------------------------------------
        --- Map the items to other datas
        __Arguments__{ Callable }
        function Map(self, func)
            self[FLD_STREAM_MAPACTITON] = func
            return self
        end

        __Arguments__{ String }
        function Map(self, feature)
            self[FLD_STREAM_MAPACTITON] = function(item)
                if type(item) == "table" then
                    return item[feature]
                end
            end
            return self
        end

        __Arguments__{ Callable }
        function Filter(self, func)
            self[FLD_STREAM_FILTERACTN] = func
            return self
        end

        --- Used to filter the items with a check function
        __Arguments__{ String, Variable.Optional() }
        function Filter(self, feature, value)
            self[FLD_STREAM_FILTERACTN] = value ~= nil and function(item)
                if type(item) == "table" then
                    return item[feature] == value
                else
                    return false
                end
            end or function(item)
                if type(item) == "table" then
                    return item[feature] and true or false
                else
                    return false
                end
            end
            return self
        end

        --- Used to select items with ranged index
        __Arguments__{ Variable.Optional(Integer, 1), Variable.Optional(Integer, -1), Variable.Optional(Integer, 1) }
        function Range(self, start, stop, step)
            self[FLD_STREAM_RANGESTART], self[FLD_STREAM_RANGESTOP], self[FLD_STREAM_RANGESTEP] = start, stop, step
            return self
        end

        -----------------------------------------------------------
        --                      Constructor                      --
        -----------------------------------------------------------
        __Arguments__{ IList }
        function ListStreamWorker(self, list)
            self[FLD_STREAM_TARGETLIST] = list
        end

        __Arguments__{ Callable, Variable.Optional(), Variable.Optional() }
        function ListStreamWorker(self, iter, obj, idx)
            self[FLD_STREAM_TARGETITER] = iter
            self[FLD_STREAM_ITEROBJECT] = obj
            self[FLD_STREAM_ITERINDEX] = idx
        end

        -----------------------------------------------------------
        --                      meta method                      --
        -----------------------------------------------------------
        __Arguments__{ IList }
        function __exist(_, list)
            local worker = getIdleworkers()
            if worker then worker[FLD_STREAM_TARGETLIST] = list end
            return worker
        end

        __Arguments__{ Callable, Variable.Optional(), Variable.Optional() }
        function __exist(_, iter, obj, idx)
            local worker = getIdleworkers()
            if worker then
                worker[FLD_STREAM_TARGETITER] = iter
                worker[FLD_STREAM_ITEROBJECT] = obj
                worker[FLD_STREAM_ITERINDEX]  = idx
            end
            return worker
        end

        export{ ListStreamWorker, IIndexedList, ICountable }
    end)

    __Sealed__()
    interface "IList" (function (_ENV)

        export {
            type                = type,
            rawget              = rawget,
            getobjectclass      = Class.GetObjectClass,
        }

        export { ListStreamWorker }

        -----------------------------------------------------------
        --                     Queue method                      --
        -----------------------------------------------------------
        --- Map the items to other type datas
        __Arguments__{ Callable }
        function Map(self, func) return ListStreamWorker(self):Map(func) end

        __Arguments__{ String }
        function Map(self, feature) return ListStreamWorker(self):Map(feature) end

        --- Used to filter the items with a check function
        __Arguments__{ Callable }
        function Filter(self, func) return ListStreamWorker(self):Filter(func) end

        __Arguments__{ String, Variable.Optional() }
        function Filter(self, feature, value) return ListStreamWorker(self):Filter(feature, value) end

        --- Used to select items with ranged index
        __Arguments__{ Variable.Optional(Integer, 1), Variable.Optional(Integer, -1), Variable.Optional(Integer, 1) }
        function Range(self, start, stop, step) return ListStreamWorker(self):Range(start, stop, step) end

        -----------------------------------------------------------
        --                     Final method                      --
        -----------------------------------------------------------
        --- Convert the selected items to a list
        __Arguments__{ Variable.Optional(-IList, List) }
        function ToList(self, cls) return cls(self) end

        --- Combine the items to get a result
        __Arguments__{ Callable, Variable.Optional() }
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

        --- Call the function for each element or set property's value for each element
        __Arguments__{ Callable, Variable.Rest() }
        function Each(self, func, ...)
            for _, obj in self:GetIterator() do
                func(obj, ...)
            end
        end

        __Arguments__{ String, Variable.Rest() }
        function Each(self, feature, ...)
            local cls, cmethod

            for _, obj in self:GetIterator() do
                if type(obj) == "table" then
                    if getobjectclass(obj) ~= cls then
                        cls = getobjectclass(obj)
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

        --- Check if any element meet the requirement of the target function
        __Arguments__{ Callable, Variable.Rest() }
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

        --- Check if all elements meet the requirement of the target function
        __Arguments__{ Callable, Variable.Rest() }
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

        --- Get the first element of the list
        __Arguments__{ Callable, Variable.Rest() }
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

        --- Get the first element of the list, if not existed use the default as result
        __Arguments__{ Variable("default"), Callable, Variable.Rest() }
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

        __Arguments__{ Variable("default") }
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
end)