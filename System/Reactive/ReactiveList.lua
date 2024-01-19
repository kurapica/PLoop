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
            ARRARY_INDEX                = "__rlarrindex",

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
            rawMap                      = not Platform.MULTI_OS_THREAD and Toolset.newtable(true, true) or false,

            -- return value if r is behavior subject
            getValue                    = function(r) if isObjectType(r, BehaviorSubject) then return r:GetValue() else return r end end,

            -- bind data change
            bindDataChange              = function (self, k, r)
                if rawget(self, OnDataChange) and (isObjectType(r, Reactive) or isObjectType(r, ReactiveList)) then
                    r.OnDataChange      = r.OnDataChange + function(_, ...) return OnDataChange(self, r[ARRARY_INDEX], ...) end
                end
                return r
            end,

            -- handle data change event handler
            handleDataChangeEvent       = function (_, owner, name)
                if not rawget(owner, OnDataChange) then
                    rawset(owner, OnDataChange, true)

                    local reactives     = owner[Reactive]
                    for k, r in pairs(reactives) do
                        bindDataChange(owner, k, r)
                    end
                end
            end,

            -- gets the index value or wrapper
            getIndexValue               = function(self, index)
                local raw               = self[ReactiveList]
                local value             = raw[index]
                if value == nil then    return end

                local reactives         = self[Reactive]
                local r                 = reactives[value]
                if r then return getValue(r) end

                if r == nil and type(value) == "table" then
                    r                   = reactive(value, true)
                    if r then
                        r[ARRARY_INDEX] = index -- init the array index
                        reactives[value]= bindDataChange(self, r)
                        return getValue(r)
                    else
                        reactives[value]= false
                    end
                end
                return value
            end,

            ReactiveList, Observable, Observer, Reactive, Watch, Subject
        }

        -------------------------------------------------------------------
        --                             event                             --
        -------------------------------------------------------------------
        --- Fired when an element added/removed
        event "OnElementChange"

        --- Fired when any element data changed
        __EventChangeHandler__(handleDataChangeEvent)
        event "OnDataChange"

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
            --- Gets the iterator
            function GetIterator(self)
                return function (self,  index)
                    index               = (index or 0) + 1
                    local value         = self[ReactiveList][index]
                    if value ~= nil then return index, value end
                end, self, 0
            end

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

            -------------------------------------------------------------------
            --                          constructor                          --
            -------------------------------------------------------------------
            __Arguments__{ List }
            function __ctor(self, list)
                rawset(self, ReactiveList, list)
                rawset(self, Reactive, newtable(true, true)) -- reactive map

                if rawMap then
                    rawMap[list]        = self
                else
                    rawset(list, ReactiveList, self)
                end
            end

            function __exist(_, list)
                if rawMap then return rawMap[list] end
                return isObjectType(list, ReactiveList) and list or rawget(list, ReactiveList)
            end

            -------------------------------------------------------------------
            --                          meta-method                          --
            -------------------------------------------------------------------
            function __index(self, index)
                return rawget(self, ReactiveList)[index]
            end

            function __newindex(self, index, value)
                if type(index) ~= "number" then error("Usage: reactiveList[index] = value - the index must be natural integer", 2) end
                local list              = rawget(self, ReactiveList)
                if list[index] == value then return end

                -- Validate with list element type
                if value ~= nil then
                    local eleType       = getTemplateParameters(getmetatable(list))
                    if eleType then
                        local ret, msg  = getmetatable(eleType).ValidateValue(eleType, value, true)
                        if msg then error(getErrorMessage(msg, "value"), 2) end
                    end
                end
                list[index]             = value
                OnElementChange(self)
            end

            function __len(self)
                return self[ReactiveList].Count
            end

        -- For IIndexedList
        elseif Class.IsSubType(targetclass, IIndexedList) then

        -- For raw array
        else
            -------------------------------------------------------------------
            --                         static method                         --
            -------------------------------------------------------------------
            --- Gets the current raw value of the reactive object
            __Static__()
            function ToRaw(self)

            end

            --- Sets a raw table value to the reactive object
            __Static__()
            function SetRaw(self, value, stack)

            end

            -------------------------------------------------------------------
            --                           property                            --
            -------------------------------------------------------------------
            --- The item count
            property "Count"                { get = function(self) return #self[ReactiveList] end }

            --- The list item change subject
            property "Subject"              { set = false, default = function() return Subject() end }

            -------------------------------------------------------------------
            --                            method                             --
            -------------------------------------------------------------------
            --- Gets the iterator
            function GetIterator(self)
                local list                  = self[ReactiveList]
                local count                 = self.Count
                return function(self, index)
                    index                   = (index or 0) + 1
                    if index > count then return end
                    return index, list[index]
                end, self, 0
            end

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

            -------------------------------------------------------------------
            --                          constructor                          --
            -------------------------------------------------------------------
            __Arguments__{ RawTable }
            function __ctor(self, list)
                rawset(self, ReactiveList, list)

                if rawMap then
                    rawMap[init]            = self
                else
                    rawset(init, ReactiveList, self)
                end
            end

            function __exist(_, list)
                if rawMap then return rawMap[init] end
                return isObjectType(list, ReactiveList) and list or rawget(list, ReactiveList)
            end

            -------------------------------------------------------------------
            --                          meta-method                          --
            -------------------------------------------------------------------
            function __index(self, index)
                local list                  = rawget(self, ReactiveList)
                return list[index]
            end

            __Arguments__{ NaturalNumber, Any }
            function __newindex(self, index, value)
                if type(index) ~= "number" then error("Usage: reactiveList[index] = value - the index must be natural integer", 2) end

                local list                  = rawget(self, ReactiveList)
                list[index]                 = value
                self:OnNext(index, value)
            end

            function __len(self)
                return self.Count
            end
        end
    end)
end)