--===========================================================================--
--                                                                           --
--                          System.Collections.List                          --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2016/02/28                                               --
-- Update Date  :   2020/07/06                                               --
-- Version      :   1.2.4                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Collections"

    import "System.Serialization"

    -- Helpers
    export { yield = coroutine.yield }

    __Iterator__() iterforstep  = function (start, stop, step) local yield = yield for i = start, stop, step do yield(i, i) end end
    __Iterator__() iterforlist  = function (iter, tar, idx)    local yield = yield for k, v in iter, tar, idx do yield(k, v == nil and k or v) end end

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
    __Sealed__() __Serializable__() __Arguments__{ AnyType }( Any )
    __NoNilValue__(false):AsInheritable() __NoRawSet__(false):AsInheritable()
    class "List" (function (_ENV, lsttype)
        extend "IIndexedList" "ISerializable"

        export { type = type, ipairs = ipairs }

        lsttype = lsttype ~= Any and lsttype or nil

        if lsttype then
            export {
                valid           = getmetatable(lsttype).ValidateValue,
                GetErrorMessage = Struct.GetErrorMessage,
                parseindex      = Toolset.parseindex,
            }
        end

        -----------------------------------------------------------
        --                     serialization                     --
        -----------------------------------------------------------
        function Serialize(self, info)
            for i, v in self:GetIterator() do
                info:SetValue(i, v, lsttype)
            end
        end

        __Arguments__{ SerializationInfo }
        function __new(_, info)
            local i = 1
            local v = info:GetValue(i, lsttype)
            local self  = {}
            while v ~= nil do
                self[i] = v
                i   = i + 1
                v   = info:GetValue(i, lsttype)
            end
            return self, true
        end

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        GetIterator = ipairs

        --- Insert an item to the list
        if lsttype then
            __Arguments__{ Integer, lsttype }
            Insert  = table.insert

            __Arguments__{ lsttype }
            Insert  = table.insert
        else
            Insert  = table.insert
        end

        --- Whether an item existed in the list
        function Contains(self, item) for i, chk in self:GetIterator() do if chk == item then return true end end return false end

        --- Get the index of the item if it existed in the list
        function IndexOf(self, item) for i, chk in self:GetIterator() do if chk == item then return i end end end

        --- Remove an item
        function Remove(self, item) local i = self:IndexOf(item) if i then return self:RemoveByIndex(i) end end

        --- Remove an item from the tail or the given index
        RemoveByIndex = table.remove

        --- Clear the list
        function Clear(self)
            for i = self.Count, 1, -1 do self[i] = nil end
            return self
        end

        --- Extend the list
        if lsttype then
            __Arguments__{ RawTable }
            function Extend(self, lst)
                local ins   = self.Insert
                for _, item in ipairs(lst) do
                    local ret, msg = valid(lsttype, item, true)
                    if not msg then ins(self, item) end
                end
                return self
            end

            __Arguments__{ IList }
            function Extend(self, lst)
                local ins   = self.Insert
                for _, item in lst:GetIterator() do
                    local ret, msg = valid(lsttype, item, true)
                    if not msg then ins(self, item) end
                end
                return self
            end

            __Arguments__{ Callable, System.Any/nil, System.Any/nil }
            function Extend(self, iter, obj, idx)
                local ins   = self.Insert
                for _, item in iter, obj, idx do
                    local ret, msg = valid(lsttype, item, true)
                    if not msg then ins(self, item) end
                end
                return self
            end
        else
            __Arguments__{ RawTable }
            function Extend(self, lst)
                local ins   = self.Insert
                for _, item in ipairs(lst) do ins(self, item) end
                return self
            end

            __Arguments__{ IList }
            function Extend(self, lst)
                local ins   = self.Insert
                for _, item in lst:GetIterator() do ins(self, item) end
                return self
            end

            __Arguments__{ Callable, System.Any/nil, System.Any/nil }
            function Extend(self, iter, obj, idx)
                local ins   = self.Insert
                for _, item in iter, obj, idx do ins(self, item) end
                return self
            end
        end

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

        __Arguments__{ Callable, System.Any/nil, System.Any/nil }
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
            local obj   = {}
            for i = 1, count do
                obj[i]  = initValue(i)
            end
            return obj, true
        end

        __Arguments__{ NaturalNumber, System.Any/nil }
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

        if lsttype then
            function __ctor(self)
                local msg
                for k, v in self:GetIterator() do
                    v, msg = valid(lsttype, v)
                    if msg then throw(GetErrorMessage(msg, parseindex(k))) end
                    self[k]= v
                end
            end
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

    --- The dynamic list
    __Sealed__() __NoRawSet__(true)
    class "XList" (function(_ENV)
        extend "IList"
        export { ipairs = ipairs, type = type, iterforstep = iterforstep, iterforlist = iterforlist }

        XLIST_TYPE_STEP         = 1
        XLIST_TYPE_ITER         = 2
        XLIST_TYPE_LIST         = 3

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        function GetIterator(self)
            local type          = self[1]

            if type == XLIST_TYPE_STEP then
                return iterforstep(self[2], self[3], self[4])
            elseif type == XLIST_TYPE_ITER then
                return iterforlist(self[2], self[3], self[4])
            else
                return self[2]:GetIterator()
            end
        end

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{
            Variable("start", NaturalNumber),
            Variable("stop", NaturalNumber),
            Variable("step", Integer, true, 1)
        }
        function __new(_, ...) return { XLIST_TYPE_STEP, ... }, true end

        __Arguments__{
            Variable("stop", NaturalNumber),
        }
        function __new(_, stop) return { XLIST_TYPE_STEP, 1, stop, 1 }, true end

        __Arguments__{ IList }
        function __new(_, lst) return { XLIST_TYPE_LIST, lst }, true end

        __Arguments__{ RawTable }
        function __new(_, lst) return { XLIST_TYPE_ITER, ipairs(lst) }, true end

        __Arguments__{ Callable, System.Any/nil, System.Any/nil }
        function __new(_, iter, obj, idx) return { XLIST_TYPE_ITER, iter, obj, idx }, true end
    end)

    --- the list stream worker, used to provide stream filter, map and etc
    -- operations on a list without creating any temp caches
    __Final__() __Sealed__() __SuperObject__(false)
    __NoRawSet__(false) __NoNilValue__(false)
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

            ListStreamWorker, IIndexedList, ICountable
        }

        -----------------------------------------------------------
        --                        helpers                        --
        -----------------------------------------------------------
        local getIdleworkers
        local rycIdleworkers

        if Platform.MULTI_OS_THREAD then
            export { Context }

            getIdleworkers      = function()
                -- Disable the recycle in multi os thread
                -- local context   = Context.Current
                -- return context and context[ListStreamWorker]
            end

            rycIdleworkers      = function(worker)
                -- local context   = Context.Current
                -- if context then context[ListStreamWorker] = worker end
            end
        else
            -- Keep idle workers for re-usage
            export { idleworkers= {} }
            getIdleworkers      = function() return tremove(idleworkers) end
            rycIdleworkers      = function(worker) tinsert(idleworkers, worker) end
        end

        -----------------------------------------------------------
        --                       constant                        --
        -----------------------------------------------------------
        export {
            FLD_TARGETLIST      = 0,
            FLD_TARGETITER      = 1,
            FLD_ITEROBJECT      = 2,
            FLD_ITERINDEX       = 3,

            FLD_MAPACTITON      = 4,
            FLD_FILTERACTN      = 5,
            FLD_RANGESTART      = 6,
            FLD_RANGESTOP       = 7,
            FLD_RANGESTEP       = 8,
        }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        __Iterator__()
        function GetIterator(self)
            local targetList    = self[FLD_TARGETLIST]
            local targetIter    = self[FLD_TARGETITER]
            local targetObj     = self[FLD_ITEROBJECT]
            local targetIdx     = self[FLD_ITERINDEX]

            local map           = self[FLD_MAPACTITON]
            local filter        = self[FLD_FILTERACTN]
            local rangeStart    = self[FLD_RANGESTART]
            local rangeStop     = self[FLD_RANGESTOP]
            local rangeStep     = self[FLD_RANGESTEP]

            -- Clear self and put self into idleworkers
            self[FLD_TARGETLIST] = nil
            self[FLD_TARGETITER] = nil
            self[FLD_ITEROBJECT] = nil
            self[FLD_ITERINDEX]  = nil

            self[FLD_MAPACTITON] = nil
            self[FLD_FILTERACTN] = nil
            self[FLD_RANGESTART] = nil
            self[FLD_RANGESTOP]  = nil
            self[FLD_RANGESTEP]  = nil

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
            if self[FLD_MAPACTITON] then return ListStreamWorker(self):Map(func) end
            self[FLD_MAPACTITON] = func
            return self
        end

        __Arguments__{ String }
        function Map(self, feature)
            if self[FLD_MAPACTITON] then return ListStreamWorker(self):Map(feature) end
            self[FLD_MAPACTITON] = function(item)
                if type(item) == "table" then
                    return item[feature]
                end
            end
            return self
        end

        __Arguments__{ Callable }
        function Filter(self, func)
            if self[FLD_FILTERACTN] or self[FLD_MAPACTITON] then return ListStreamWorker(self):Filter(func) end
            self[FLD_FILTERACTN] = func
            return self
        end

        --- Used to filter the items with a check function
        __Arguments__{ String, System.Any/nil }
        function Filter(self, feature, value)
            if self[FLD_FILTERACTN] or self[FLD_MAPACTITON] then return ListStreamWorker(self):Filter(feature, value) end
            self[FLD_FILTERACTN] = value ~= nil and function(item)
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
        __Arguments__{ Integer/1, Integer/-1, Integer/1 }
        function Range(self, start, stop, step)
            if self[FLD_RANGESTART] or self[FLD_FILTERACTN] then return ListStreamWorker(self):Range(start, stop, step) end
            self[FLD_RANGESTART], self[FLD_RANGESTOP], self[FLD_RANGESTEP] = start, stop, step
            return self
        end

        -----------------------------------------------------------
        --                      Constructor                      --
        -----------------------------------------------------------
        __Arguments__{ IList }
        function __ctor(self, list)
            self[FLD_TARGETLIST] = list
        end

        __Arguments__{ Callable, System.Any/nil, System.Any/nil }
        function __ctor(self, iter, obj, idx)
            self[FLD_TARGETITER] = iter
            self[FLD_ITEROBJECT] = obj
            self[FLD_ITERINDEX] = idx
        end

        -----------------------------------------------------------
        --                      meta method                      --
        -----------------------------------------------------------
        __Arguments__{ IList }
        function __exist(_, list)
            local worker = getIdleworkers()
            if worker then worker[FLD_TARGETLIST] = list end
            return worker
        end

        __Arguments__{ Callable, System.Any/nil, System.Any/nil }
        function __exist(_, iter, obj, idx)
            local worker = getIdleworkers()
            if worker then
                worker[FLD_TARGETITER] = iter
                worker[FLD_ITEROBJECT] = obj
                worker[FLD_ITERINDEX]  = idx
            end
            return worker
        end
    end)

    __Sealed__()
    interface "IList" (function (_ENV)

        export {
            type                = type,
            rawget              = rawget,
            getobjectclass      = Class.GetObjectClass,
            isObjectType        = Class.IsObjectType,
            tblconcat           = table.concat,
            tonumber            = tonumber,
        }

        export { ListStreamWorker, IIndexedList, XList }

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

        __Arguments__{ String, System.Any/nil }
        function Filter(self, feature, value) return ListStreamWorker(self):Filter(feature, value) end

        --- Used to select items with ranged index
        __Arguments__{ Integer/1, Integer/-1, Integer/1 }
        function Range(self, start, stop, step) return ListStreamWorker(self):Range(start, stop, step) end

        -----------------------------------------------------------
        --                     Final method                      --
        -----------------------------------------------------------
        --- Convert the selected items to a list
        __Arguments__{ -IList/List }
        function ToList(self, cls) return cls(self) end

        --- Save the link operations into a xlist so we can use it as a new start for link operations
        function ToXList(self) return XList(self) end

        --- Combine the items to get a result
        __Arguments__{ Callable, System.Any/nil }
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
        __Arguments__{ Callable, System.Any * 0 }
        function Each(self, func, ...)
            for _, obj in self:GetIterator() do
                func(obj, ...)
            end
        end

        __Arguments__{ String, System.Any * 0 }
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
        __Arguments__{ Callable, System.Any * 0 }
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
        __Arguments__{ Callable, System.Any * 0 }
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
        __Arguments__{ Callable, System.Any * 0 }
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
        end

        --- Get the last element of the list
        __Arguments__{ Callable, System.Any * 0 }
        function Last(self, chk, ...)
            local last

            for _, val in self:GetIterator() do
                if chk(val, ...) then
                    last = val
                end
            end

            return last
        end

        __Arguments__{}
        function Last(self)
            if isObjectType(self, IIndexedList) then return self[self.Count] end

            local last

            for _, val in self:GetIterator() do
                last = val
            end

            return last
        end

        --- Get the concatenation of the List
        __Arguments__{ String/nil }
        function Join(self, sep)
            return tblconcat(isObjectType(self, IIndexedList) and self or self:ToList(), sep)
        end

        --- Get the sum of the list
        function Sum(self)
            local sum = 0
            for _, val in self:GetIterator() do sum = sum + (tonumber(val) or 0) end
            return sum
        end
    end)
end)