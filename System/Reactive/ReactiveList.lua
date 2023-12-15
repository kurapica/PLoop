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

        -------------------------------------------------------------------
        --                             event                             --
        -------------------------------------------------------------------
        event "OnElementChanged"

        -- For all list
        if targetclass == List then
            export                      {
                getmetatable            = getmetatable,
                getTemplateParameters   = Class.GetTemplateParameters,
                getErrorMessage         = Struct.GetErrorMessage,
            }

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
                local list              = self[ReactiveList]
                local count             = list.Count
                return function (self,  index)
                    index               = (index or 0) + 1
                    if index > count then return end
                    return index, list[index]
                end, self, 0
            end

            --- Insert the item
            function Insert(self, ...)
                local list              = self[ReactiveList]
                local ok, err           = pcall(list.Insert, list, ...)
                if not ok then error(err, 2) end
                return OnElementChanged(self)
            end

            --- Whether an item existed in the list
            function Contains(self, item)return self[ReactiveList]:Contains(item) end

            --- Get the index of the item if it existed in the list
            function IndexOf(self, item) return self[ReactiveList]:IndexOf(item)  end

            --- Remove an item
            function Remove(self, item)
                local item              = self[ReactiveList]:Remove(item)
                if item ~= nil then
                    OnElementChanged(self)
                    return item
                end
            end

            --- Remove an item from the tail or the given index
            function RemoveByIndex(self, index)
                local item              = self[ReactiveList]:RemoveByIndex(item)
                if item ~= nil then
                    OnElementChanged(self)
                    return item
                end
            end

            --- Clear the list
            function Clear(self)
                local list              = self[ReactiveList]
                local count             = list.Count
                if count > 0 then
                    list:Clear()
                    return OnElementChanged(self)
                end
            end

            --- Extend the list
            function Extend(self, ...)
                local list              = self[ReactiveList]
                local count             = list.Count
                local ok, err           = pcall(list.Extend, list, ...)
                if not ok then error(err, 2) end
                return list.Count > count and OnElementChanged(self)
            end

            -------------------------------------------------------------------
            --                          constructor                          --
            -------------------------------------------------------------------
            __Arguments__{ List }
            function __ctor(self, list)
                rawset(self, ReactiveList, list)
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
                OnElementChanged(self)
            end

            function __len(self)
                return self.Count
            end

        -- Other IIndexedList classes
        elseif targetclass then
            local checkRet              = Platform.ENABLE_TAIL_CALL_OPTIMIZATIONS
                                        and function(ok, ...) if not ok then error(..., 2) end return ... end
                                        or  function(ok, ...) if not ok then error(..., 3) end return ... end
            local getObject             = function(value) return value and type(value) == "table" and rawget(value, ReactiveList) or value end

            -------------------------------------------------------------------
            --                             event                             --
            -------------------------------------------------------------------
            for name, ev in Class.GetFeatures(targetclass, true) do
                if Event.Validate(ev) then
                    __EventChangeHandler__(function(delegate, owner, name)
                        local obj       = rawget(owner, Class)
                        if not rawget(delegate, Reactive) then
                            rawset(delegate, Reactive, function(self, ...) return delegate(owner, ...) end)
                        end
                        if delegate:IsEmpty() then
                            obj[name]   = obj[name] - delegate[Reactive]
                        else
                            obj[name]   = obj[name] + delegate[Reactive]
                        end
                    end)
                    event(name)
                end
            end

            -------------------------------------------------------------------
            --                           property                            --
            -------------------------------------------------------------------
            for name, prop in Class.GetFeatures(targetclass, true) do
                if Property.Validate(prop) then
                    if Property.IsIndexer(prop) then
                        __Indexer__(Property.GetIndexType(prop))
                        property (name) {
                            type        = Property.GetType(prop),
                            get         = Property.IsReadable(prop) and function(self, idx) return rawget(self, Class)[name][idx] end,
                            set         = Property.IsWritable(prop) and function(self, idx, value) rawget(self, Class)[name][idx] = value end,
                        }
                    else
                        property (name) {
                            type        = Property.GetType(prop),
                            get         = Property.IsReadable(prop) and function(self) return rawget(self, Class)[name] end,
                            set         = Property.IsWritable(prop) and function(self, value) rawget(self, Class)[name] = value end,
                        }
                    end
                end
            end

            -------------------------------------------------------------------
            --                            method                             --
            -------------------------------------------------------------------
            for name, method in Class.GetMethods(targetclass, true) do
                _ENV[name]              = function(self, ...) return checkRet(pcall(method, rawget(self, Class), ...)) end
            end

            -------------------------------------------------------------------
            --                          constructor                          --
            -------------------------------------------------------------------
            -- bind the reactive and object
            __Arguments__{ targetclass }
            function __ctor(self, init)
                rawset(self, Class, init)
                rawset(init, Reactive, self)
            end

            -- use the wrap for objects
            function __exist(_, init)
                return init and rawget(init, Reactive)
            end

            -------------------------------------------------------------------
            --                          meta-method                          --
            -------------------------------------------------------------------
            for name, method in Class.GetMetaMethods(targetclass, true) do
                if name == "__gc" then
                    __dtor              = function(self) return rawget(self, Class):Dispose() end
                else
                    _ENV[name]          = function(self, other, ...) return method(getObject(self), getObject(other), ...) end
                end
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