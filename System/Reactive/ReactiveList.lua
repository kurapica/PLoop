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
    __Arguments__{ -IIndexedList/nil }:WithRebuild()
    class "ReactiveList"                (function(_ENV, targetclass)
        extend "IIndexedList"

        export                          {
            type                        = type,
            rawset                      = rawset,
            rawget                      = rawget,
            ipairs                      = ipairs,
            error                       = error,
            pcall                       = pcall,
            yield                       = coroutine.yield,
            tinsert                     = table.insert,
            tremove                     = table.remove,
            newtable                    = Toolset.newtable,
            isObjectType                = Class.IsObjectType,
            getEventDelegate            = Event.Get,

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

                for k, v in owner:GetIterator() do
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

        -------------------------------------------------------------------
        --                          constructor                          --
        -------------------------------------------------------------------
        __Arguments__{ targetclass and Class.IsSubType(targetclass, List) and List or targetclass or RawTable }
        function __ctor(self, list)
            local reactives             = newtable(true, true)
            rawset(self, ReactiveList, list)
            rawset(self, Reactive, reactives)

            -- wrap table values directly
            for i, v in (list.GetIterator or ipairs)(list) do
                if type(v) == "table" then
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
            local raw                   = self[ReactiveList]
            local oldval                = raw[index]
            if oldval == value then return end

            local reactives             = self[Reactive]

            if type(oldval) == "table" then
                Reactive.SetRaw(reactives[oldval], value, 2)
                return
            end

            -- set directly
            raw[index]                  = value

            if type(value) == "table" then
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
        --                           template                            --
        -------------------------------------------------------------------
        -- For all classes based on List
        if Class.IsSubType(targetclass, List) then

            ---------------------------------------------------------------
            --                         property                          --
            ---------------------------------------------------------------
            --- The item count
            property "Count"            { get = function(self) return self[ReactiveList].Count end }

            ---------------------------------------------------------------
            --                          method                           --
            ---------------------------------------------------------------
            --- Insert the item
            function Insert(self, ...)
                local list              = self[ReactiveList]
                local count             = list.Count
                local ok, err           = pcall(list.Insert, list, ...)
                if not ok then error(err, 2) end
                return OnElementChange(self)
            end

            --- Whether an item existed in the list
            function Contains(self,item)return self[ReactiveList]:Contains(item) end

            --- Get the index of the item if it existed in the list
            function IndexOf(self, item)return self[ReactiveList]:IndexOf(item)  end

            --- Remove an item
            function Remove(self, item)
                local item              = self[ReactiveList]:Remove(item)
                if item ~= nil then
                    OnElementChange(self)
                    return item
                end
            end

            --- Remove an item from the tail or the given index
            function RemoveByIndex(self, index)
                local item              = self[ReactiveList]:RemoveByIndex(item)
                if item ~= nil then
                    OnElementChange(self)
                    return item
                end
            end

            --- Clear the list
            function Clear(self)
                local list              = self[ReactiveList]
                local count             = list.Count
                if count > 0 then
                    list:Clear()
                    return OnElementChange(self)
                end
            end

            --- Extend the list
            function Extend(self, ...)
                local list              = self[ReactiveList]
                local count             = list.Count
                local ok, err           = pcall(list.Extend, list, ...)
                if not ok then error(err, 2) end
                return list.Count > count and OnElementChange(self)
            end

        -- For IIndexedList
        elseif Class.IsSubType(targetclass, IIndexedList) then

        -- For raw array
        else
            export                      {
                max                     = math.max,
                error                   = error,
                pcall                   = pcall,
            }

            -------------------------------------------------------------------
            --                         static method                         --
            -------------------------------------------------------------------
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

                local ok, err           = pcall(function()
                    for i = 1, max(self.Count, #value) do
                        self[i]         = value[i]
                    end
                end)
                if not ok then
                    error("Usage: ReactiveList.SetRaw(reactiveList, value[, stack]) - " .. err, (stack or 1) + 1)
                end
            end

            __Static__()
            function From(self)
                return isObjectType(self, ReactiveList) and Observable.From(self.OnDataChange) or nil
            end

            -------------------------------------------------------------------
            --                           property                            --
            -------------------------------------------------------------------
            --- The item count
            property "Count"                { get = function(self) return #self[ReactiveList] end }

            -------------------------------------------------------------------
            --                            method                             --
            -------------------------------------------------------------------
            --- Insert the item
            __Arguments__{ Any }:Throwable()
            function Insert(self, item)
                local list                  = self[ReactiveList]
                local ins                   = list.Insert
                if ins then
                    local ok, err           = pcall(ins, list, item)
                    if not ok then throw(err) end
                else
                    tinsert(list, item)
                end
                return self.Subject:OnNext(self.Count, item)
            end

            __Arguments__{ NaturalNumber, Any }
            function Insert(self, index, item)
                local list                  = self[ReactiveList]
                local ins                   = list.Insert
                if ins then
                    local ok, err           = pcall(ins, list, index, item)
                    if not ok then throw(err) end
                else
                    tinsert(list, item)
                end
                return self.Subject:OnNext(index, item)
            end

            --- Whether an item existed in the list
            function Contains(self, item)   for i, chk in self:GetIterator() do if chk == item then return true end end return false end

            --- Get the index of the item if it existed in the list
            function IndexOf(self, item)    for i, chk in self:GetIterator() do if chk == item then return i end end end

            --- Remove an item
            function Remove(self, item)
                local list                  = self[ReactiveList]
                local remove                = list.Remove -- For List
                if remove then
                    item                    = remove(list, item)
                else
                    if item == nil then
                        item                = tremove(list)
                    else
                        local i             = self:IndexOf(item)
                        return i and self:RemoveByIndex(i)
                    end
                end
                if item then
                    self.Subject:OnNext(self.Count + 1)
                end
                return item
            end

            --- Remove an item from the tail or the given index
            function RemoveByIndex(self, index)
                local list                  = rawget(self, ReactiveList)
                local item                  = (list.RemoveByIndex or tremove)(list, index)
                self.Subject:OnNext(index)
                return item
            end

            --- Clear the list
            function Clear(self)
                local list                  = rawget(self, ReactiveList)
                for i = #list, 1, -1        do list[i] = nil end
                return self.Subject:OnNext(0)
            end

            --- Extend the list
            __Arguments__{ RawTable }
            function Extend(self, lst)
                local list                  = rawget(self, ReactiveList)
                local ins                   = list.Insert or tinsert
                for _, item in ipairs(lst)  do ins(list, item) end
                self.Subject:OnNext(#list, list[#list])
                return self
            end

            __Arguments__{ IList }
            function Extend(self, lst)
                local list                  = rawget(self, ReactiveList)
                local ins                   = list.Insert or tinsert
                for _, item in lst:GetIterator() do ins(list, item) end
                self.Subject:OnNext(#list, list[#list])
                return self
            end

            __Arguments__{ Callable, System.Any/nil, System.Any/nil }
            function Extend(self, iter, obj, idx)
                local list                  = rawget(self, ReactiveList)
                local ins                   = list.Insert or tinsert
                for key, item in iter, obj, idx do
                    if item == nil then item = key end
                    ins(list, item)
                end
                self.Subject:OnNext(#list, list[#list])
                return self
            end
        end

    end)
end)