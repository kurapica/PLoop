--===========================================================================--
--                                                                           --
--                       System.Reactive.ReactiveList                        --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2023/10/25                                               --
-- Update Date  :   2024/12/24                                               --
-- Version      :   2.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    -----------------------------------------------------------------------
    --                              utility                              --
    -----------------------------------------------------------------------
    export                              {
        rawset                          = rawset,
        rawget                          = rawget,
        newtable                        = Toolset.newtable,
        isobjecttype                    = Class.IsObjectType,
        issubtype                       = Class.IsSubType,
        getreactivetype                 = System.Reactive.GetReactiveType,

        ReactiveValue, Subject, Reactive, IList
    }

    -- the reactive map
    local objectSubjectMap              = not Platform.MULTI_OS_THREAD and Toolset.newtable(true) or nil
    local getObjectSubject              = Platform.MULTI_OS_THREAD
        and function(obj)
            local subject               = rawget(obj, Reactive)
            if not subject then
                subject                 = Subject()
                rawset(obj, Reactive, subject)
            end
            return subject
        end
        or  function(obj)
            local subject               = objectSubjectMap[obj]
            if not subject then
                subject                 = Subject()
                objectSubjectMap[obj]   = subject
            end
            return subject
        end

    -- push data
    local onObjectNext                  = function(obj, ...) return obj and getObjectSubject(obj):OnNext(...) end
    local onObjectError                 = function(obj, ex)  return obj and getObjectSubject(obj):OnError(ex) end
    local onObjectCompleted             = function(obj)      return obj and getObjectSubject(obj):OnCompleted() end

    -- Subscribe the children
    local subscribeReactive             = function(self, r)
        local subject                   = rawget(self, Subject)

        -- no need to support scalar reactive value
        if r and subject and not rawget(subject, r) and not isobjecttype(r, ReactiveValue) then
            rawset(subject, r, (r:Subscribe(function(...)
                local raw               = self[RawTable]
                local reactives         = self[Reactive]
                if not raw then return end

                -- index cache to boost, will be reset when element index changed
                local cache             = rawget(self, IList)
                if not cache then
                    cache               = newtable(true)
                    rawset(self, IList, cache)
                end

                local index             = cache[r]
                if index then return onObjectNext(raw, cache[r], ...) end
                if index == false then return end

                for i = 1, raw.Count or #raw do
                    local v             = raw[i]
                    if v ~= nil and reactives[v] == r then
                        cache[r]        = i
                        return onObjectNext(raw, i, ...)
                    end
                end
                cache[r]                = false
            end, function(ex) return onObjectError(rawget(self, RawTable), ex) end)))
        end
        return r
    end

    -- Release the children
    local releaseReactive               = function(self, r)
        local subject                   = rawget(self, Subject)
        local subscription              = r and subject and rawget(subject, r)
        if subscription then
            rawset(subject, r, nil)
            return subscription:Dispose()
        end
    end

    -- wrap the table value as default
    local makeReactive                  = function(self, v)
        local rtype                     = getreactivetype(v)
        local r                         = rtype and not issubtype(rtype, ReactiveValue) and rtype(v) or nil
        self[Reactive][v]               = r or false
        return r and subscribeReactive(self, r)
    end

    -- switch object value
    local switchObject                  = function(self, new)
        if rawget(self, RawTable) == new then return end
        local reactives                 = self[Reactive]

        -- clear
        rawset(self, IList, nil)
        for _, r in pairs(reactives) do
            if r then releaseReactive(self, r) end
        end
        self[Reactive]                  = newtable(true)

        -- lazy subscribe
        local subject                   = rawget(self, Subject)
        if not subject then return end

        -- reset
        subject.Observable              = nil
        if not new then return end

        -- make reactives
        for _, v in (new.GetIterator or ipairs)(new) do
            makeReactive(self, v)
        end

        subject.Observable              = getObjectSubject(new)
    end

    local getSubject                    = function(self)
        local subject                   = rawget(self, Subject)
        if not subject then
            local raw                   = rawget(self, RawTable)
            subject                     = Subject()
            subject.Observable          = raw and getObjectSubject(raw) or nil
            rawset(self, Subject, subject)

            -- init
            for k, r in pairs(self[Reactive]) do subscribeReactive(self, r) end
        end
        return subject
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
        return onObjectNext(rawget(self, RawTable), ...)
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
            pairs                       = pairs,
            error                       = error,
            getmetatable                = getmetatable,
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
            getobjectclass              = Class.GetObjectClass,
            gettempparams               = Class.GetTemplateParameters,
            splice                      = List.Splice,

            -- import types
            RawTable, Reactive, IList, Subject
        }

        if elementtype then
            export                      {
                valid                   = getmetatable(elementtype).ValidateValue,
                geterrormessage         = Struct.GetErrorMessage,
                parseindex              = Toolset.parseindex,
            }

            local reactivetype          = GetReactiveType(elementtype)
            validatetype                = reactivetype and (elementtype + reactivetype) or elementtype
        end

        -------------------------------------------------------------------
        --                           property                            --
        -------------------------------------------------------------------
        --- The item count
        property "Count"                { get = function(self) local list = self[RawTable] return list and (list.Count or #list) or 0 end }

        --- Gets/Sets the raw value
        property "Value"                {
            field                       = RawTable,
            set                         = elementtype and function(self, value)
                if value and isobjecttype(value, IReactive) then
                    value               = value.Value
                end
                if value == rawget(self, RawTable) then return end

                -- Check with element type
                if value then
                    local cls           = getobjectclass(value)
                    if cls then
                        local eletype   = gettempparams(cls)
                        if eletype and not getmetatable(elementtype).IsSubType(eletype, elementtype) then
                            throw("The element type of the value doesn't match the reactive object")
                        end
                    end
                end

                -- switch object
                rawset(self, RawTable, value)
                switchObject(self, value)

                -- notify
                local subject           = rawget(self, Subject)
                return subject and subject:OnNext(nil)

            end or function(self, value)
                if value and isobjecttype(value, IReactive) then
                    value               = value.Value
                end
                if value == rawget(self, RawTable) then return end

                -- switch object
                rawset(self, RawTable, value)
                switchObject(self, value)

                -- notify
                local subject           = rawget(self, Subject)
                return subject and subject:OnNext(nil)
            end,
            type                        = RawTable + IIndexedList,
            throwable                   = elementtype and true or nil,
        }

        -------------------------------------------------------------------
        --                            method                             --
        -------------------------------------------------------------------
        --- Subscribe the observers
        function Subscribe(self, ...)
            local subject               = rawget(self, Subject)
            if not subject then
                subject                 = Subject()
                rawset(self, Subject, subject)

                -- init
                for k, r in pairs(self[Reactive]) do subscribeReactive(self, k, r) end
            end

            -- subscribe
            local ok, sub, observer     = pcall(subject.Subscribe(subject, ...))
            if not ok then error("Usage: reactiveList:Subscribe(IObserver[, Subscription]) - the argument not valid", 2) end

            return sub, observer
        end

        --- Gets the iterator
        function GetIterator(self)
            return function(self, index)
                index                   = (index or 0) + 1
                local value             = self[index]
                if value ~= nil then return index, value end
            end, self, nil
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
                local th                = keepargs(splice(self[RawTable], index, count, function()
                    local item
                    idx, item           = iter(obj, idx)
                    while idx ~= nil do
                        if item == nil  then item = idx end
                        if isobjecttype(item, IReactive) then item = item.Value end

                        local ret, msg  = valid(elementtype, item, true)
                        if not msg then     return idx, ret end

                        idx, item       = iter(obj, idx)
                    end
                end))

                if th then
                    fireElementChange(self)
                    return getkeepargs(th)
                end
            end
        else
            function Splice(self, index, count, iter, obj, idx)
                local th                = keepargs(splice(self[RawTable], index, count, function()
                    local item
                    idx, item           = iter(obj, idx)
                    while idx ~= nil do
                        if item == nil  then item = idx end
                        if isobjecttype(item, IReactive) then item = item.Value end
                        return idx, item
                    end
                end))

                if th then
                    fireElementChange(self)
                    return getkeepargs(th)
                end
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

        --- Insert an item to the list
        __Arguments__{ Integer, elementtype and validatetype or Any }
        function Insert(self, index, item)
            if item and isobjecttype(item, IReactive) then item = item.Value end
            if item == nil then return end
            local raw                   = self[RawTable]
            local total                 = raw.Count or #raw
            local insert                = raw.Insert or tinsert
            index                       = index < 0 and max(index + total + 1, 1) or min(index, total + 1)
            insert(raw, index, item)
            return fireElementChange(self) or self.Count
        end

        __Arguments__{ elementtype and validatetype  or Any }
        function Insert(self, item)
            if item and isobjecttype(item, IReactive) then item = item.Value end
            if item == nil then return end
            local raw                   = self[RawTable]
            local insert                = raw.Insert or tinsert
            insert(raw, item)
            return fireElementChange(self) or self.Count
        end

        --- Whether an item existed in the list
        function Contains(self, item)   return self:IndexOf(item) and true or false end

        --- Get the index of the item if it existed in the list
        function IndexOf(self, item)
            if item == nil then return end
            if isobjecttype(item, IReactive) then item = item.Value end

            local raw                   = self[RawTable]
            for i, v in (raw.GetIterator or ipairs)(raw) do
                if v == item then return i end
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
            if index ~= nil and type(index) ~= "number" then return end
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
            rawset(self, Reactive, newtable(true))
            return fireElementChange(self)
        end

        -------------------------------------------------------------------
        --                          constructor                          --
        -------------------------------------------------------------------
        function __ctor(self, list)
            rawset(self, RawTable, type(list) == "table" and list or {})
            rawset(self, Reactive, newtable(true))
            if list then setReactiveMap(list, self) end
        end

        function __exist(_, list)
            return type(list) == "table" and getReactiveMap(list) or nil
        end

        -------------------------------------------------------------------
        --                        de-constructor                         --
        -------------------------------------------------------------------4
        function __dtor(self)
            local subject               = rawget(self, Subject)
            if subject then
                for k, r in pairs(self[Reactive]) do
                    local subscription  = r and rawget(subject, r)
                    if subscription then
                        subscription:Dispose()
                        rawset(subject, r, nil)
                    end
                end
            end

            for k, v in pairs(self[Reactive]) do
                -- only reactive fields will be disposed with the parent
                if v and isobjecttype(v, IReactive) then v:Dispose() end
            end

            return clearReactiveMap(self)
        end

        -------------------------------------------------------------------
        --                          meta-method                          --
        -------------------------------------------------------------------
        function __index(self, index)
            if type(index) ~= "number" then return end

            local raw                   = rawget(self, RawTable)
            local value                 = raw[index]
            if value and type(value) == "table" then
                local r                 = rawget(self, Reactive)[value]
                if r ~= nil then return r or value end
                return makeReactive(self, value) or value
            end
            return value
        end

        function __newindex(self, index, value)
            if type(index) ~= "number" then
                error("Usage: reactiveList[index] = value - the index is must be number", 2)
            end

            -- Convert to raw value
            if value and isobjecttype(value, IReactive) then
                value                   = value.Value
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