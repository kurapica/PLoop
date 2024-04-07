--===========================================================================--
--                                                                           --
--                       System.Reactive.ReactiveList                        --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2023/10/25                                               --
-- Update Date  :   2024/01/19                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Reactive"

    --- Provide reactive feature for list or array
    __Sealed__()
    __Arguments__{ AnyType/nil }
    class "ReactiveList"                (function(_ENV, elementtype)
        extend "IObservable" "IIndexedList"

        export                          {
            type                        = type,
            rawset                      = rawset,
            rawget                      = rawget,
            ipairs                      = ipairs,
            error                       = error,
            pcall                       = pcall,
            select                      = select,
            unpack                      = _G.unpack or table.unpack,
            min                         = math.min,
            max                         = math.max,
            keepargs                    = Toolset.keepargs,
            getkeepargs                 = Toolset.getkeepargs,
            tinsert                     = table.insert,
            tremove                     = table.remove,
            newtable                    = Toolset.newtable,
            isObjectType                = Class.IsObjectType,
            getEventDelegate            = Event.Get,
            isReactable                 = Reactive.IsReactable,
            toRawValue                  = Reactive.ToRaw,

            -- bind data change
            bindDataChange              = function (self, r)
                if r and getEventDelegate(OnDataChange, self, true) and (isObjectType(r, Reactive) or isObjectType(r, ReactiveList)) then
                    r.OnDataChange      = r.OnDataChange + function(_, ...)
                        local raw       = self[ReactiveList]
                        local reactives = self[Reactive]

                        -- index cache to boost, will be reset when element index changed
                        local cache     = rawget(self, IList)
                        if not cache then
                            cache       = newtable(true)
                            rawset(self, IList, cache)
                        end

                        if cache[r] then return OnDataChange(self, cache[r], ...) end

                        for i = 1, raw.Count or #raw do
                            if reactives[raw[i]] == r then
                                cache[r]= i
                                return OnDataChange(self, i, ...)
                            end
                        end
                    end
                end
                return r
            end,

            -- handle data change event handler
            handleDataChangeEvent       = function (_, owner, name, init)
                if not init then return end
                for v in pairs(owner[Reactive]) do
                    bindDataChange(owner, v)
                end
            end,

            -- wrap the table value as default
            makeReactive                = function (self, v)
                local r                 = reactive(v, true)
                self[Reactive][v]       = r or false
                return r and bindDataChange(self, r)
            end,

            -- fire the element data changes
            fireElementChange           = function(self, ...)
                rawset(self, IList, nil)
                return OnDataChange(self, ...)
            end,

            -- list reactive map
            rawMap                      = not Platform.MULTI_OS_THREAD and Toolset.newtable(true, true) or false,

            -- import types
            ReactiveList, Observable, Observer, Reactive, Watch, Subject, IList
        }

        -------------------------------------------------------------------
        --                             event                             --
        -------------------------------------------------------------------
        --- Fired when any element data changed
        __EventChangeHandler__(handleDataChangeEvent)
        event "OnDataChange"

        -------------------------------------------------------------------
        --                           property                            --
        -------------------------------------------------------------------
        --- The item count
        property "Count"            { get = function(self) local list = self[ReactiveList] return list.Count or #list end }

        -------------------------------------------------------------------
        --                            method                             --
        -------------------------------------------------------------------
        --- Subscribe the observers
        function Subscribe(self, ...)
            return Observable.From(self.OnDataChange):Subscribe(...)
        end

        --- Gets the iterator
        function GetIterator(self)
            return function (self,  index)
                index                   = (index or 0) + 1
                local value             = self[index]
                if value ~= nil then return index, value end
            end, self, 0
        end

        --- Map the items to other datas, use collection operation instead of observable
        Map                             = IList.Map

        --- Used to filter the items with a check function
        Filter                          = IList.Filter

        --- Used to select items with ranged index
        Range                           = IList.Range

        --- Push
        if elementtype then __Arguments__{ elementtype } end
        function Push(self, item)
            item                        = toRawValue(item)
            if item == nil then return end
            local raw                   = self[ReactiveList]
            local insert                = raw.Insert or tinsert
            insert(raw, item)
            return fireElementChange(self) or self.Count
        end

        --- Pop
        function Pop(self)
            local raw                   = self[ReactiveList]
            local remove                = raw.RemoveByIndex or tremove
            local item                  = remove(raw)
            if item == nil then return end
            self[Reactive][item]        = nil
            return fireElementChange(self) or item
        end

        --- Shift
        function Shift(self)
            local raw                   = self[ReactiveList]
            local remove                = raw.RemoveByIndex or tremove
            local item                  = remove(raw, 1)
            if item == nil then return end
            self[Reactive][item]        = nil
            return fireElementChange(self) or item
        end

        --- Unshift
        if elementtype then __Arguments__{ elementtype } end
        function Unshift(self, item)
            item                        = toRawValue(item)
            if item == nil then return end
            local raw                   = self[ReactiveList]
            local insert                = raw.Insert or tinsert
            insert(raw, 1, item)
            return fireElementChange(self) or self.Count
        end

        --- Splice
        __Arguments__{ Integer, NaturalNumber/nil, (lsttype or Any) * 0 }
        function Splice(self, index, count, ...)
            local raw                   = self[ReactiveList]
            local reactives             = self[Reactive]
            local insert                = raw.Insert or tinsert
            local remove                = raw.RemoveByIndex or tremove

            local total                 = raw.Count or #raw
            index                       = index <= 0 and max(index + total + 1, 1) or min(index, total + 1)
            local last                  = count and min(index + count - 1, total) or total
            local addcnt                = select("#", ...)
            local th

            if index <= last then
                th                      = keepargs(unpack(raw, index, last))

                if addcnt > 0 then
                    -- replace
                    for i = 1, min(addcnt, last - index + 1) do
                        raw[index+i-1]  = toRawValue(select(i, ...))
                    end

                    -- remove
                    for i = last, index + addcnt, -1 do
                        reactives[remove(raw, i)] = nil
                    end

                    -- add
                    for i = last - index + 2, addcnt do
                        raw:Insert(index + i - 1, toRawValue(select(i, ...)))
                    end
                else
                    for i = last, index, -1 do
                        reactives[remove(raw, i)] = nil
                    end
                end
            else
                for i = 1, addcnt do
                    raw:Insert(index + i - 1, toRawValue(select(i, ...)))
                end
            end

            if index <= last or addcnt > 0 then fireElementChange(self) end
            if th then return getkeepargs(th) end
        end

        --- Insert an item to the list
        __Arguments__{ Integer, elementtype or Any }
        function Insert(self, index, item)
            item                        = toRawValue(item)
            if item == nil then return end
            local raw                   = self[ReactiveList]
            local total                 = raw.Count or #raw
            local insert                = raw.Insert or tinsert
            index                       = index < 0 and max(index + total + 1, 1) or min(index, total + 1)
            if index == total + 1 then
                raw[index]              = item
            else
                insert(raw, index, item)
            end
            return fireElementChange(self) or self.Count
        end

        __Arguments__{ elementtype or Any }
        function Insert(self, item)
            item                        = toRawValue(item)
            if item == nil then return end
            local raw                   = self[ReactiveList]
            raw[(raw.Count or #raw) + 1]= item
            return fireElementChange(self) or self.Count
        end

        --- Whether an item existed in the list
        function Contains(self, item)   return self:IndexOf(item) and true or false end

        --- Get the index of the item if it existed in the list
        function IndexOf(self, item)
            local raw                   = self[ReactiveList]
            local reactives             = self[Reactive]

            for i, v in (raw.GetIterator or ipairs)(raw) do
                if v == item or reactives[v] == item then return i end
            end
        end

        --- Remove an item
        function Remove(self, item)
            if item == nil then
                return self:RemoveByIndex()
            else
                local i                 = self:IndexOf(item)
                return i and self:RemoveByIndex(i)
            end
        end

        --- Remove an item from the tail or the given index
        function RemoveByIndex(self, index)
            local raw                   = self[ReactiveList]
            local total                 = raw.Count or #raw
            index                       = not index and total or index < 0 and max(index + total + 1, 1) or min(index, total)
            local item
            if index == total then
                item                    = raw[index]
                raw[index]              = nil
            else
                local remove            = raw.RemoveByIndex or tremove
                item                    = remove(raw, index)
            end
            return item ~= nil and fireElementChange(self) or item
        end

        --- Clear the list
        function Clear(self)
            local raw                   = self[ReactiveList]
            local total                 = raw.Count or #raw
            if total == 0 then return end

            if raw.Clear then
                raw:Clear()
            else
                for i = total, 1, -1 do
                    raw[i]              = nil
                end
            end
            rawset(self, Reactive, newtable(true, true))
            return fireElementChange(self)
        end

        -------------------------------------------------------------------
        --                          constructor                          --
        -------------------------------------------------------------------
        function __ctor(self, list)
            local reactives             = newtable(true, true)
            rawset(self, ReactiveList,  list)
            rawset(self, Reactive, reactives)

            if rawMap then
                rawMap[list]            = self
            else
                rawset(list, ReactiveList, self)
            end
        end

        function __exist(_, list)
            if type(list) ~= "table" then return end
            if rawMap then return rawMap[list] end
            return isObjectType(list, ReactiveList) and list or rawget(list, ReactiveList)
        end

        -------------------------------------------------------------------
        --                          meta-method                          --
        -------------------------------------------------------------------
        function __index(self, index)
            local raw                   = rawget(self, ReactiveList)
            local value                 = raw[index]
            if type(value) == "table" then
                local r                 = rawget(self, Reactive)[value]
                if r ~= nil then return r or value end
                return makeReactive(self, value) or value
            end
            return value
        end

        function __newindex(self, index, value)
            -- Convert to raw value
            if type(value) == "table" then
                value                   = toRawValue(value)
            end

            local raw                   = self[ReactiveList]
            local oldval                = raw[index]
            if oldval == nil then error("Usage: reactiveList[index] = value - the index is out of range", 2) end
            if oldval == value then return end

            local reactives             = self[Reactive]
            if reactives[oldval] then
                Reactive.SetRaw(reactives[oldval], value, 2)
                return
            end

            -- set directly
            raw[index]                  = value
            return fireElementChange(self, index, value)
        end

        function __len(self)            return self.Count end

        -------------------------------------------------------------------
        --                         static method                         --
        -------------------------------------------------------------------
        if not elementtype then
            export                      {
                max                     = math.max,
                error                   = error,
                pcall                   = pcall,
            }

            --- Gets the current raw value of the reactive object
            __Static__()
            function ToRaw(self)
                return isObjectType(self, ReactiveList) and rawget(self, ReactiveList) or toRawValue(self)
            end

            --- Sets a raw table value to the reactive object
            __Static__()
            function SetRaw(self, value, stack)
                if not isObjectType(self, ReactiveList) then
                    error("Usage: ReactiveList.SetRaw(reactiveList, value[, stack]) - the reactive list not valid", (stack or 1) + 1)
                end

                if type(value) ~= "table" then
                    error("Usage: ReactiveList.SetRaw(reactiveList, value[, stack]) - the value not valid", (stack or 1) + 1)
                end

                return self:Splice(1, self.Count, unpack(value))
            end
        end
    end)
end)