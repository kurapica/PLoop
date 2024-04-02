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
    __Arguments__{ AnyType/nil }:WithRebuild()
    class "ReactiveList"                (function(_ENV, elementtype)
        extend "IIndexedList" "IObservable"

        export                          {
            type                        = type,
            rawset                      = rawset,
            rawget                      = rawget,
            ipairs                      = ipairs,
            error                       = error,
            pcall                       = pcall,
            select                      = select,
            unpack                      = _G.unpack or table.unpack,
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
                        -- index the data @todo add cache to boost
                        local raw       = self[ReactiveList]
                        local reactives = self[Reactive]

                        for i = 1, self.Count do
                            if reactives[raw[i]] == r then
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
                for _, v in owner:GetIterator() do
                    bindDataChange(owner, v)
                end
            end,

            -- wrap the table value as default
            makeReactive                = function (self, v)
                local r                 = reactive(v, true)
                return r and bindDataChange(self, r)
            end,

            -- list reactive map
            rawMap                      = not Platform.MULTI_OS_THREAD and Toolset.newtable(true, true) or false,

            -- import types
            ReactiveList, Observable, Observer, Reactive, Watch, Subject
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
        --- Gets the iterator
        function GetIterator(self)
            return function (self,  index)
                index                   = (index or 0) + 1
                local value             = self[index]
                if value ~= nil then return index, value end
            end, self, 0
        end

        --- Subscribe the observers
        function Subscribe(self, ...)
            return Observable.From(self.OnDataChange):Subscribe(...)
        end

        --- Push
        if elementtype then __Arguments__{ elementtype } end
        function Push(self, item)
            self:Insert(item)
            return self.Count
        end

        --- Pop
        function Pop(self)
            return self:Remove()
        end

        --- Shift
        function Shift(self)
            return self:RemoveByIndex(1)
        end

        --- Unshift
        if elementtype then __Arguments__{ elementtype } end
        function Unshift(self, item)
            self:Insert(1, item)
            return self.Count
        end

        --- Splice
        __Arguments__{ Number, Number/nil, (elementtype or Any) * 0 }
        function Splice(self, index, count, ...)
            local raw                   = self[ReactiveList]
            local total                 = raw.Count or #raw
            local last                  = count and (index + count - 1) or total
            local addcnt                = select("#", ...)
            local th
            local changed               = false

            -- @TODO boost with replace
            if index <= last then
                local removeByIndex     = raw.RemoveByIndex or tremove
                th                      = keepargs(unpack(self, index, last))
                changed                 = true
                for i = last, index, -1 do removeByIndex(raw, i) end
            end

            local insert                = raw.Insert or tinsert
            local reactives             = self[Reactive]
            for i = 1, addcnt do
                changed                 = true

                local value             = toRawValue((select(i, ...)))
                insert(raw, index + i - 1, value)
                if isReactable(value, true) then
                    reactives[value]    = makeReactive(self, value)
                end
            end

            -- full list change
            if changed then OnDataChange(self) end

            if th then                  return getkeepargs(th) end
        end

        --- Insert an item to the list
        __Arguments__{ Number, elementtype or Any }
        function Insert(self, index, item)
            local raw                   = self[ReactiveList]
            local reactives             = self[Reactive]
            local insert                = raw.Insert or tinsert

            item                        = toRawValue(item)
            insert(raw, index, item)
            if isReactable(item, true) then
                local r                 = makeReactive(self, item)
                if r then
                    reactives[item]     = r
                    item                = r
                end
            end

            if index == (raw.Count or #raw) then
                return OnDataChange(self, index, item)
            else
                -- full list change
                return OnDataChange(self)
            end
        end

        __Arguments__{ elementtype or Any }
        function Insert(self, item)
            local raw                   = self[ReactiveList]
            local reactives             = self[Reactive]
            local insert                = raw.Insert or tinsert

            item                        = toRawValue(item)
            insert(raw, item)
            if isReactable(item, true) then
                local r                 = makeReactive(self, item)
                if r then
                    reactives[item]     = r
                    item                = r
                end
            end

            return OnDataChange(self, raw.Count or #raw, item)
        end

        --- Whether an item existed in the list
        function Contains(self, item) return self:IndexOf(item) and true or false end

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
                local i = self:IndexOf(item)
                return i and self:RemoveByIndex(i)
            end
        end

        --- Remove an item from the tail or the given index
        function RemoveByIndex(self, index)
            local raw                   = self[ReactiveList]
            local count                 = raw.Count or #raw
            if count > 0 and (not index or index > 0 and index <= count) then
                local item              = (raw.RemoveByIndex or tremove)(self, index)
                OnDataChange(self)
                return item
            end
        end

        --- Clear the list
        function Clear(self)
            local raw                   = self[ReactiveList]
            if (raw.Count or #raw) == 0 then return end

            if raw.Clear then
                raw:Clear()
            else
                for i = #raw, 1, -1 do
                    raw[i]              = nil
                end
            end

            OnDataChange(self)
            return self
        end

        -------------------------------------------------------------------
        --                          constructor                          --
        -------------------------------------------------------------------
        function __ctor(self, list)
            local reactives             = newtable(true, true)
            rawset(self, ReactiveList,  list)
            rawset(self, Reactive, reactives)

            -- wrap table values directly
            for i, v in (list.GetIterator or ipairs)(list) do
                if isReactable(v, true) then
                    reactives[v]        = makeReactive(self, v)
                end
            end

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
            return type(value) == "table" and rawget(self, Reactive)[value] or value
        end

        function __newindex(self, index, value)
            -- Convert to raw value
            if type(value) == "table" then
                value                   = toRawValue(value)
            end

            local raw                   = self[ReactiveList]
            local oldval                = raw[index]
            if oldval == value then return end

            local reactives             = self[Reactive]
            if reactives[oldval] then
                Reactive.SetRaw(reactives[oldval], value, 2)
                return
            end

            -- set directly
            raw[index]                  = value

            if isReactable(value, true) then
                local r                 = makeReactive(self, value)
                if r then
                    reactives[value]    = r
                    value               = r
                end
            end

            return OnDataChange(self, index, value)
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
                return isObjectType(self, ReactiveList) and rawget(self, ReactiveList) or self
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