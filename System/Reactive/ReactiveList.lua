--===========================================================================--
--                                                                           --
--                       System.Reactive.ReactiveList                        --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2023/10/25                                               --
-- Update Date  :   2023/10/25                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Reactive"

    --- Provide reactive feature for list or array
    __Sealed__() __Arguments__{ -IIndexedList/nil }:WithRebuild()
    class "ReactiveList"                (function(_ENV, targetclass)
        extend "IIndexedList"

        export                          {
            rawset                      = rawset,
            rawget                      = rawget,
            ipairs                      = ipairs,
            error                       = error,
            yield                       = coroutine.yield,
            tinsert                     = table.insert,
            tremove                     = table.remove,
            isObjectType                = Class.IsObjectType,

            ReactiveList, Observable, Observer, Reactive, Watch, ICountable, Subject
        }

        if targetclass then
            local elementType           = List{Class.GetTemplateParameters(targetclass)}:First(Namespace.Validate)
            if elementType == Any then  elementType = nil end

            -------------------------------------------------------------------
            --                           property                            --
            -------------------------------------------------------------------
            --- The item count
            property "Count"            { get = function(self) return self[ReactiveList].Count end }

            --- The list item change subject
            property "Subject"          { set = false, default = function() return Subject() end }

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
            if elementType then __Arguments__{ elementType } end
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
            __Arguments__{ targetclass }
            function __ctor(self, list)
                rawset(self, ReactiveList, list)
            end

            -------------------------------------------------------------------
            --                          meta-method                          --
            -------------------------------------------------------------------
            function __index(self, index)
                print("Get", index)
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
            property "Count"                {
                get                         = function(self)
                    local list              = self[ReactiveList]
                    return isObjectType(list, ICountable) and list.Count or #list
                end
            }

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