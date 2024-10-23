--===========================================================================--
--                                                                           --
--                       System.Reactive.ReactiveList                        --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2023/10/25                                               --
-- Update Date  :   2024/09/20                                               --
-- Version      :   2.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    -----------------------------------------------------------------------
    --                              Utility                              --
    -----------------------------------------------------------------------
    export                              {
        rawset                          = rawset,
        rawget                          = rawget,
        newtable                        = Toolset.newtable,
        isobjecttype                    = Class.IsObjectType,
        issubtype                       = Class.IsSubType,
        getreactivetype                 = System.Reactive.GetReactiveType,

        ReactiveValue
    }

    -- the reactive map
    local reactiveMap                   = newtable(true, true)
    local getReactiveMap                = Platform.MULTI_OS_THREAD and function(obj) return rawget(obj, IReactive) end or function(obj) return reactiveMap[obj]  end
    local setReactiveMap                = Platform.MULTI_OS_THREAD and function(obj, r) rawset(obj, IReactive, r)  end or function(obj, r) reactiveMap[obj] = r  end
    local clearReactiveMap              = Platform.MULTI_OS_THREAD and function(r) rawset(r.Value, IReactive, nil) end or function(r) reactiveMap[r.Value] = nil end

    -- Subscribe the children
    local subscribeReactive             = function(self, k, r)
        local subject                   = rawget(self, Subject)
        -- no need to support scalar value
        if r and subject and not rawget(subject, r) and not isobjecttype(r, ReactiveValue) then
            rawset(subject, r, (r:Subscribe(function(...)
                local raw               = self[RawTable]
                local reactives         = self[Reactive]

                -- index cache to boost, will be reset when element index changed
                local cache             = rawget(self, IList)
                if not cache then
                    cache               = newtable(true)
                    rawset(self, IList, cache)
                end

                if cache[r] then return subject:OnNext(cache[r], ...) end

                for i = 1, raw.Count or #raw do
                    if reactives[raw[i]] == r then
                        cache[r]        = i
                        return subject:OnNext(i, ...)
                    end
                end
            end, function(ex) return subject:OnError(ex) end)))
        end
        return r
    end

    -- Release the children
    local releaseReactive               = function(self, r)
        local subject                   = rawget(self, Subject)
        if r and subject and rawget(subject, r) then
            subject[r]:Dispose()
            rawset(subject, r, nil)
        end
    end

    -- Release all subscriptions
    local releaseAllSub                 = function(self)
        local subject                   = rawget(self, Subject)
        if subject then
            for k, r in pairs(self[Reactive]) do
                local subscription      = r and rawget(subject, r)
                if subscription then
                    subscription:Dispose()
                    rawset(subject, r, nil)
                end
            end
        end
    end

    -- wrap the table value as default
    local makeReactive                  = function(self, v)
        local rtype                     = getreactivetype(v)
        local r                         = rtype and not issubtype(rtype, ReactiveValue) and rtype(v)
        self[Reactive][k]               = r or false
        return r and subscribeReactive(self, k, r)
    end

    -- subscribe
    local subscribe                     = function(self, ...)
        local subject                   = rawget(self, Subject)
        if not subject then
            subject                     = Subject()
            rawset(self, Subject, subject)

            -- init
            for k, r in pairs(self[Reactive]) do subscribeReactive(self, k, r) end
        end

        -- subscribe
        local ok, subscription, observer= pcall(subject.Subscribe(subject, ...))
        if not ok then error("Usage: reactive:Subscribe(IObserver[, Subscription]) - the argument not valid", 2) end

        return subscription, observer
    end

    local format                        = function(name, err)
        if type(err) == "string" then
            return err:gsub("^.*:%d+:%s*", ""):gsub("^the (%w+)", "the " .. name .. ".%1")
        else
            err.Message = err.Message:gsub("^.*:%d+:%s*", ""):gsub("^the (%w+)", "the " .. name .. ".%1")
            return err
        end
    end

    -- fire the element data changes
    local fireElementChange             = function(self, ...)
        rawset(self, IList, nil)
        local subject                   = rawget(self, Subject)
        return subject and subject:OnNext(...)
    end

    --- Provide reactive feature for list or array
    __Sealed__()
    __Arguments__{ AnyType/nil }
    __NoNilValue__(false):AsInheritable()
    __NoRawSet__(false):AsInheritable()
    class "System.Reactive.ReactiveList"(function(_ENV, elementtype)
        extend "IObservable" "IIndexedList" "IReactive"

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
            isobjecttype                = Class.IsObjectType,
            getreactivetype             = System.Reactive.GetReactiveType,

            -- import types
            RawTable, Observable, Observer, Reactive, Watch, Subject, IList
        }

        if elementtype then
            export                      {
                validatetype            = getreactivetype(elementtype) and (elementtype + getreactivetype(elementtype)) or elementtype,
                valid                   = getmetatable(elementtype).ValidateValue,
                geterrormessage         = Struct.GetErrorMessage,
                parseindex              = Toolset.parseindex,
            }
        end

        -------------------------------------------------------------------
        --                           property                            --
        -------------------------------------------------------------------
        --- The item count
        property "Count"                { get = function(self) local list = self[RawTable] return list.Count or #list end }

        --- Gets/Sets the raw value
        property "Value"                {
            get                         = function(self) return self[RawTable] end,
            set                         = function(self, value)
                if isobjecttype(value, IReactive) then
                    value               = value.Value
                end
                return self:Splice(1, self.Count, value)
            end,
            type                        = RawTable + IList, -- @TODO: more excatly type combination
        }

        -------------------------------------------------------------------
        --                            method                             --
        -------------------------------------------------------------------
        --- Subscribe the observers
        Subscribe                       = subscribe

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
        if elementtype then __Arguments__{ validatetype } end
        function Push(self, item)
            if item and isobjecttype(item, IReactive) then
                item                    = item.Value
            end
            if item == nil then return end
            local raw                   = self[RawTable]
            local insert                = raw.Insert or tinsert
            insert(raw, item)
            return fireElementChange(self) or self.Count
        end

        --- Pop
        function Pop(self)
            local raw                   = self[RawTable]
            local remove                = raw.RemoveByIndex or tremove
            local item                  = remove(raw)
            if item == nil then return end
            self[Reactive][item]        = nil
            return fireElementChange(self) or item
        end

        --- Shift
        function Shift(self)
            local raw                   = self[RawTable]
            local remove                = raw.RemoveByIndex or tremove
            local item                  = remove(raw, 1)
            if item == nil then return end
            self[Reactive][item]        = nil
            return fireElementChange(self) or item
        end

        --- Unshift
        if elementtype then __Arguments__{ validatetype } end
        function Unshift(self, item)
            if item and isobjecttype(item, IReactive) then
                item                    = item.Value
            end
            if item == nil then return end
            local raw                   = self[RawTable]
            local insert                = raw.Insert or tinsert
            insert(raw, 1, item)
            return fireElementChange(self) or self.Count
        end

        --- Splice
        __Arguments__{ Integer, Integer, Callable, Any/nil, Any/nil }
        if elementtype then
            function Splice(self, index, count, iter, obj, idx)
                local total             = self.Count
                index                   = index <= 0 and max(index + total + 1, 1) or min(index, total + 1)
                local last              = count <  0 and max(count + total + 1, index - 1) or min(index + count - 1, total)
                local th

                if index <= last then
                    th                  = keepargs(unpack(self, index, last))

                    local i             = 0
                    local ridx          = last - index
                    for key, item in iter, obj, idx do
                        if item == nil  then item = key end
                        if isobjecttype(item, IReactive) then item = item.Value end

                        local ret, msg  = valid(lsttype, item, true)
                        if not msg then
                            -- replace
                            if i <= ridx then
                                self[index + i] = item

                                if i == ridx then
                                    -- remove
                                    for j = last, index + ridx + 1, -1 do
                                        self:RemoveByIndex(j)
                                    end
                                end
                            else
                                self:Insert(index + i, item)
                            end
                            i           = i + 1
                        end
                    end

                    if i <= ridx then
                        -- remove
                        for j = last, index + i, -1 do
                            self:RemoveByIndex(j)
                        end
                    end
                else
                    local i             = 0
                    for key, item in iter, obj, idx do
                        if item == nil  then item = key end
                        local ret, msg  = valid(lsttype, item, true)
                        if not msg then
                            self:Insert(index + i, item)
                            i           = i + 1
                        end
                    end
                end

                if th then                  return getkeepargs(th) end
            end
        else
            function Splice(self, index, count, iter, obj, idx)
                local total             = self.Count
                index                   = index <= 0 and max(index + total + 1, 1) or min(index, total + 1)
                local last              = count <  0 and max(count + total + 1, index - 1) or min(index + count - 1, total)
                local th

                if index <= last then
                    th                  = keepargs(unpack(self, index, last))

                    local i             = 0
                    local ridx          = last - index
                    for key, item in iter, obj, idx do
                        if item == nil  then item = key end
                        if isobjecttype(item, IReactive) then item = item.Value end

                        -- replace
                        if i <= ridx then
                            self[index + i] = item

                            if i == ridx then
                                -- remove
                                for j = last, index + ridx + 1, -1 do
                                    self:RemoveByIndex(j)
                                end
                            end
                        else
                            self:Insert(index + i, item)
                        end
                        i               = i + 1
                    end

                    if i <= ridx then
                        -- remove
                        for j = last, index + i, -1 do
                            self:RemoveByIndex(j)
                        end
                    end
                else
                    local i             = 0
                    for key, item in iter, obj, idx do
                        if item == nil then item = key end
                        self:Insert(index + i, item)
                        i               = i + 1
                    end
                end

                if th then                  return getkeepargs(th) end
            end
        end

        --- Splice
        __Arguments__{ Integer, Integer, RawTable }
        function Splice(self, index, count, raw)
            return Splice(index, count, ipairs(raw))
        end

        --- Spice
        __Arguments__{ Integer, Integer, IList }
        function Splice(self, index, count, list)
            return Splice(self, index, count, list:GetIterator())
        end

        --- Splice
        __Arguments__{ Integer, Integer, (lsttype or Any) * 0 }
        function Splice(self, index, count, ...)
            return Splice(self, index, count, ipairs{...})
        end



        --- Splice
        __Arguments__{ Integer, NaturalNumber/nil, (lsttype or Any) * 0 }
        function Splice(self, index, count, ...)
            local raw                   = self[RawTable]
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
                        raw[index+i-1]  = toraw(select(i, ...))
                    end

                    -- remove
                    for i = last, index + addcnt, -1 do
                        reactives[remove(raw, i)] = nil
                    end

                    -- add
                    for i = last - index + 2, addcnt do
                        raw:Insert(index + i - 1, toraw(select(i, ...)))
                    end
                else
                    for i = last, index, -1 do
                        reactives[remove(raw, i)] = nil
                    end
                end
            else
                for i = 1, addcnt do
                    raw:Insert(index + i - 1, toraw(select(i, ...)))
                end
            end

            if index <= last or addcnt > 0 then fireElementChange(self) end
            if th then return getkeepargs(th) end
        end

        --- Splice
        __Arguments__{ Integer, NaturalNumber/nil, Callable, System.Any/nil, System.Any/nil }
        function Splice(self, index, count, ...)
            local raw                   = self[RawTable]
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
                        raw[index+i-1]  = toraw(select(i, ...))
                    end

                    -- remove
                    for i = last, index + addcnt, -1 do
                        reactives[remove(raw, i)] = nil
                    end

                    -- add
                    for i = last - index + 2, addcnt do
                        raw:Insert(index + i - 1, toraw(select(i, ...)))
                    end
                else
                    for i = last, index, -1 do
                        reactives[remove(raw, i)] = nil
                    end
                end
            else
                for i = 1, addcnt do
                    raw:Insert(index + i - 1, toraw(select(i, ...)))
                end
            end

            if index <= last or addcnt > 0 then fireElementChange(self) end
            if th then return getkeepargs(th) end
        end

        --- Insert an item to the list
        __Arguments__{ Integer, elementtype or Any }
        function Insert(self, index, item)
            item                        = toraw(item)
            if item == nil then return end
            local raw                   = self[RawTable]
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
            item                        = toraw(item)
            if item == nil then return end
            local raw                   = self[RawTable]
            raw[(raw.Count or #raw) + 1]= item
            return fireElementChange(self) or self.Count
        end

        --- Whether an item existed in the list
        function Contains(self, item)   return self:IndexOf(item) and true or false end

        --- Get the index of the item if it existed in the list
        function IndexOf(self, item)
            local raw                   = self[RawTable]
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
            local raw                   = self[RawTable]
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
            local raw                   = self[RawTable]
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
            rawset(self, RawTable,  list)
            rawset(self, Reactive, reactives)
        end

        -------------------------------------------------------------------
        --                          meta-method                          --
        -------------------------------------------------------------------
        function __index(self, index)
            if type(index) ~= "number" then return end

            local raw                   = rawget(self, RawTable)
            local value                 = raw[index]
            if type(value) == "table" then
                local r                 = rawget(self, Reactive)[value]
                if r ~= nil then return r or value end
                return makeReactive(self, value) or value
            end
            return value
        end

        function __newindex(self, index, value)
            if type(index) ~= "number" then return end

            -- Convert to raw value
            if type(value) == "table" then
                value                   = toraw(value)
            end

            local raw                   = self[RawTable]
            local oldval                = raw[index]
            if oldval == value then return end

            -- keep list
            if oldval == nil and index ~= self.Count + 1 then
                error("Usage: reactiveList[index] = value - the index is out of range", 2)
            end

            if value == nil then
                if index ~= self.Count then
                    error("Usage: reactiveList[index] = nil - must use RemoveByIndex instead of assign directly", 2)
                end
                return self:Pop()
            end

            if oldval and self[Reactive][oldval] then
                setraw(self[Reactive][oldval], value, 2)
                return
            end

            -- set directly
            raw[index]                  = value
            return fireElementChange(self, index, value)
        end

        function __len(self)            return self.Count end
    end)
end)