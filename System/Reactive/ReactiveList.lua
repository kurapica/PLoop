--===========================================================================--
--                                                                           --
--                       System.Reactive.ReactiveList                        --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2023/10/25                                               --
-- Update Date  :   2025/03/04                                               --
-- Version      :   2.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    -----------------------------------------------------------------------
    --                              utility                              --
    -----------------------------------------------------------------------
    export                              {
        rawset                          = rawset,
        rawget                          = rawget,
        ipairs                          = ipairs,
        select                          = select,
        tinsert                         = table.insert,
        tremove                         = table.remove,
        type                            = type,
        newtable                        = Toolset.newtable,
        getobjectclass                  = Class.GetObjectClass,
        isobjecttype                    = Class.IsObjectType,
        issubtype                       = Class.IsSubType,
        getreactivetype                 = System.Reactive.GetReactiveType,

        ReactiveValue, Subject, Reactive, IList
    }

    -----------------------------------------------------------------------
    --                           array subject                           --
    -----------------------------------------------------------------------
    local function insertElement(subject, i, v)
        if type(v) == "table" then
            local cache                 = subject.Cache
            local r                     = cache[v]
            if r ~= nil then
                if r then
                    local indexes       = r[subject]
                    if type(indexes) == "table" then
                        for j = 1, #indexes do if indexes[j] == i then return end end
                        -- keep track indexes
                        tinsert(indexes, i)
                    elseif indexes ~= i then
                        r[subject]      = { indexes, i }
                    end
                end
            else
                local rtype             = getreactivetype(v, rawget(subject, "ElementType"))
                if rtype and not issubtype(rtype, ReactiveValue) then
                    r                   = rtype(v)
                    rawset(r, subject, i)
                    rawset(subject, r, (r:Subscribe(
                        function(...)
                            local i     = r[subject]
                            if type(i) == "table" then
                                -- @TODO: reduce the creations, maybe a backup plan
                                -- but normally there is no need to store the same object in the array
                                return subject:OnNext(List(ipairs(r[subject])), ...)
                            else
                                return subject:OnNext(i, ...)
                            end
                        end,
                        function(ex)  return subject:OnError(ex) end
                    )))
                else
                    r                   = false
                end

                cache[v]                = r
            end
            return r or v
        end
        return v
    end

    local function removeElement(subject, i, v)
        local cache                     = subject.Cache
        local r                         = cache[v]
        if r then
            local indexes               = r[subject]
            local clear                 = type(indexes) ~= "table"
            if not clear then
                for j = #indexes, 1, -1 do
                    if indexes[j] == i then
                        tremove(indexes, j)
                        break
                    end
                end
                local remain            = #indexes
                clear                   = remain == 0
                if remain == 1 then
                    r[subject]          = indexes[1]
                end
            elseif indexes ~= i then
                return
            end

            -- release
            if clear then
                cache[v]                = nil
                r[subject]              = nil
                local subscription      = rawget(subject, r)
                if subscription then
                    subscription:Dispose()
                    rawset(subject, r, nil)
                end
            end
        end
    end

    local function moveElement(subject, i, oi, v)
        if i == oi  then return end
        if i == nil then return removeElement(subject, oi, v) end
        if oi== nil then return insertElement(subject, i, v)  end

        local cache                     = subject.Cache
        local r                         = cache[v]
        if r then
            local indexes               = r[subject]
            if type(indexes) == "table" then
                for j = 1, #indexes do
                    if indexes[j] == i then
                        return removeElement(subject, oi, v)
                    end
                end
                for j = #indexes, 1, -1 do
                    if indexes[j] == oi then
                        indexes[j]      = i
                        break
                    end
                end
            else
                r[subject]              = i
            end
        end
    end

    local function clearElements(subject)
        local cache                     = subject.Cache
        for v, r in pairs(cache) do
            if r then
                cache[v]                = nil
                r[subject]              = nil
                local subscription      = rawget(subject, r)
                if subscription then
                    subscription:Dispose()
                    rawset(subject, r, nil)
                end
            end
        end
    end

    local function initObjectSubject(obj, elementtype)
        local subject                   = Subject()
        local cache                     = newtable(true)
        rawset(subject, "Cache", cache)
        rawset(subject, "ElementType", elementtype)

        -- init elements
        for i, v in (obj.GetIterator or ipairs)(obj) do
            insertElement(subject, i, v)
        end
        return subject
    end

    local objectSubjectMap              = not Platform.MULTI_OS_THREAD and Toolset.newtable(true) or nil
    local getObjectSubject              = Platform.MULTI_OS_THREAD
        and function(obj, elementtype)
            local subject               = rawget(obj, Reactive)
            if not subject then
                subject                 = initObjectSubject(obj, elementtype)
                rawset(obj, Reactive, subject)
            end
            return subject
        end
        or  function(obj, elementtype)
            local subject               = objectSubjectMap[obj]
            if not subject then
                subject                 = initObjectSubject(obj, elementtype)
                objectSubjectMap[obj]   = subject
            end
            return subject
        end


    -- access element
    local getElement                    = function(obj, index)
        if not (obj and index) then return end
        local value                     = obj[index]
        return value and type(value) == "table" and getObjectSubject(obj).Cache[value] or value
    end
    
    local format                        = function(name, err)
        if type(err) == "string" then
            return err:gsub("^.*:%d+:%s*", ""):gsub("^the (%w+)", "the " .. name .. ".%1")
        else
            err.Message = err.Message:gsub("^.*:%d+:%s*", ""):gsub("^the (%w+)", "the " .. name .. ".%1")
            return err
        end
    end

    -----------------------------------------------------------------------
    --                          implementation                           --
    -----------------------------------------------------------------------
    --- Provide reactive feature for list or array
    __Sealed__()
    __Arguments__{ AnyType/Any }
    __NoNilValue__(false):AsInheritable()
    __NoRawSet__(false):AsInheritable()
    class "System.Reactive.ReactiveList"(function(_ENV, elementtype)
        extend "IIndexedList" "IReactive"

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
            yield                       = coroutine.yield,
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
            setvalue                    = Toolset.setvalue,
            isvaluetype                 = false,
            RangeType                   = System.Collections.Range,
            AnyType                     = System.Any,

            -- splice helper
            handleSpliceResult          = function (raw, initcnt, index, count, ...)
                local removecnt         = select("#", ...)
                local currcnt           = raw.Count or #raw
                local subject           = getObjectSubject(raw)
                for i = index, index + removecnt - 1 do
                    removeElement(subject, i, (select(i, ...)))
                end
                for i = index, index + currcnt - initcnt + removecnt - 1 do
                    insertElement(subject, i, raw[i])
                end
                local diff              = currcnt - initcnt
                if diff ~= 0 then
                    for i = index + currcnt - initcnt + removecnt, currcnt do
                        moveElement(subject, i, i + diff, raw[i])
                    end
                    subject:OnNext(RangeType(index, max(initcnt, currcnt)))
                else
                    subject:OnNext(RangeType(index, index + count - 1))
                end
                return ...
            end,

            -- import types
            RawTable, Reactive, IList, Subject, IReactive
        }

        if elementtype ~= AnyType then
            export                      {
                valid                   = getmetatable(elementtype).ValidateValue,
                geterrormessage         = Struct.GetErrorMessage,
                parseindex              = Toolset.parseindex,
            }

            local reactivetype          = Reactive.GetReactiveType(elementtype)
            if not reactivetype or Class.IsSubType(reactivetype, ReactiveValue) then
                isvaluetype             = true
            end
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
            set                         = elementtype ~= AnyType and function(self, value)
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
                local subject           = rawget(self, Subject)
                if subject then
                    subject.Observable  = value and getObjectSubject(value, elementtype) or nil
                    return subject:OnNext(nil)
                end

            end or function(self, value)
                if value and isobjecttype(value, IReactive) then
                    value               = value.Value
                end
                if value == rawget(self, RawTable) then return end

                -- switch object
                rawset(self, RawTable, value)
                local subject           = rawget(self, Subject)
                if subject then
                    subject.Observable  = value and getObjectSubject(value) or nil
                    return subject:OnNext(nil)
                end
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
                local raw               = rawget(self, RawTable)
                subject                 = Subject()
                subject.Observable      = raw and getObjectSubject(raw, elementtype) or nil
                rawset(self, Subject, subject)
            end

            -- subscribe
            local ok, sub, observer     = pcall(subject.Subscribe, subject, ...)
            if not ok then error(sub, 2) end
            return sub, observer
        end

        --- Gets the iterator
        function GetIterator(self)
            return function(self, index)
                index                   = (index or 1) + 1
                local value             = getElement(rawget(self, RawTable), index)
                if value ~= nil then return index, value end
            end, self, 0
        end

        -- use collection operation instead of observable
        for k, v in Interface.GetMethods(IList) do
            _ENV[k]                     = v
        end

        --- Push
        if elementtype ~= AnyType then __Arguments__{ validatetype } end
        function Push(self, item)
            if type(item) == "table" and isobjecttype(item, IReactive) then
                item                    = item.Value
            end
            if item == nil then return end
            local raw                   = rawget(self, RawTable)
            if not raw then return end

            -- insert
            local insert                = raw.Insert or tinsert
            insert(raw, item)

            -- publish
            local count                 = raw.Count or #raw
            local subject               = getObjectSubject(raw)
            subject:OnNext(count, insertElement(subject, count, item))
            return count
        end

        --- Pop
        function Pop(self)
            local raw                   = rawget(self, RawTable)
            if not raw then return end

            local count                 = raw.Count or #raw
            local remove                = raw.RemoveByIndex or tremove
            local item                  = remove(raw)
            if item == nil then return end

            -- publish
            local subject               = getObjectSubject(raw)
            removeElement(subject, count, item)
            subject:OnNext(count, nil)
            return item
        end

        --- Shift
        function Shift(self)
            local raw                   = rawget(self, RawTable)
            if not raw then return end

            local remove                = raw.RemoveByIndex or tremove
            local item                  = remove(raw, 1)
            if item == nil then return end

            -- publish
            local count                 = raw.Count or #raw
            local subject               = getObjectSubject(raw)
            removeElement(subject, 1, item)
            for i = 1, count do
                moveElement(subject, i, i + 1, raw[i])
            end
            -- index changes use Range object
            subject:OnNext(RangeType(1, count + 1))
            return item
        end

        --- Unshift
        if elementtype ~= AnyType then __Arguments__{ validatetype } end
        function Unshift(self, item)
            if item and isobjecttype(item, IReactive) then
                item                    = item.Value
            end
            if item == nil then return end
            local raw                   = rawget(self, RawTable)
            if not raw then return end
            
            local insert                = raw.Insert or tinsert
            insert(raw, 1, item)

            -- publish
            local count                 = raw.Count or #raw
            local subject               = getObjectSubject(raw)
            insertElement(subject, 1, item)
            for i = 2, count do
                moveElement(subject, i, i - 1, raw[i])
            end
            subject:OnNext(RangeType(1, count))
            return count
        end

        --- Splice
        __Arguments__{ Integer, Integer, Callable, AnyType/nil, AnyType/nil }
        if elementtype ~= AnyType then
            function Splice(self, index, count, iter, obj, idx)
                local raw               = rawget(self, RawTable)
                if not raw then return end

                local initcnt           = raw.Count or #raw
                local th                = keepargs(splice(raw, index, count, function()
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

                return handleSpliceResult(raw, initcnt, index, count, getkeepargs(th))
            end
        else
            function Splice(self, index, count, iter, obj, idx)
                local raw               = rawget(self, RawTable)
                if not raw then return end

                local initcnt           = raw.Count or #raw
                local th                = keepargs(splice(raw, index, count, function()
                    local item
                    idx, item           = iter(obj, idx)
                    while idx ~= nil do
                        if item == nil  then item = idx end
                        if isobjecttype(item, IReactive) then item = item.Value end
                        return idx, item
                    end
                end))

                return handleSpliceResult(raw, initcnt, index, count, getkeepargs(th))
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
        __Arguments__{ Integer, Integer, (lsttype or AnyType) * 0 }
        function Splice(self, index, count, ...)
            return Splice(self, index, count, ipairs{...})
        end

        --- Insert an item to the list
        __Arguments__{ Integer, elementtype and validatetype or AnyType }
        function Insert(self, index, item)
            if item and isobjecttype(item, IReactive) then item = item.Value end
            if item == nil then return end
            local raw                   = rawget(self, RawTable)
            if not raw then return end

            local total                 = raw.Count or #raw
            local insert                = raw.Insert or tinsert
            index                       = index < 0 and max(index + total + 1, 1) or min(index, total + 1)
            insert(raw, index, item)

            -- publish
            local count                 = raw.Count or #raw
            local subject               = getObjectSubject(raw)
            insertElement(subject, index, item)
            for i = index + 1, count do
                moveElement(subject, i, i - 1, raw[i])
            end
            subject:OnNext(RangeType(index, count))
            return count
        end

        __Arguments__{ elementtype and validatetype  or AnyType }
        function Insert(self, item)
            if item and isobjecttype(item, IReactive) then item = item.Value end
            if item == nil then return end
            local raw                   = rawget(self, RawTable)
            if not raw then return end

            local insert                = raw.Insert or tinsert
            insert(raw, item)

            -- publish
            local count                 = raw.Count or #raw
            local subject               = getObjectSubject(raw)
            subject:OnNext(count, insertElement(subject, count, item))
            return count
        end

        --- Whether an item existed in the list
        function Contains(self, item)   return self:IndexOf(item) and true or false end

        --- Get the index of the item if it existed in the list
        function IndexOf(self, item)
            local raw                   = rawget(self, RawTable)
            if not raw then return end

            if item == nil then return end
            if isobjecttype(item, IReactive) then item = item.Value end

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
            local raw                   = rawget(self, RawTable)
            if not raw then return end

            local total                 = raw.Count or #raw
            index                       = not index and total or index < 0 and max(index + total + 1, 1) or min(index, total)
            local item
            if index == total then
                item                    = raw[index]
                raw[index]              = nil
            elseif index < total then
                local remove            = raw.RemoveByIndex or tremove
                item                    = remove(raw, index)
            else
                return
            end

            -- publish
            local subject               = getObjectSubject(raw)
            removeElement(subject, index, item)
            for i = index, total - 1 do
                moveElement(subject, index, index + 1, raw[index])
            end
            subject:OnNext(RangeType(index, total))
            return item
        end

        --- Clear the list
        function Clear(self)
            local raw                   = rawget(self, RawTable)
            if not raw then return end
            local total                 = raw.Count or #raw
            if total == 0 then return end

            if raw.Clear then
                raw:Clear()
            else
                for i = total, 1, -1 do
                    raw[i]              = nil
                end
            end

            local subject               = getObjectSubject(raw)
            clearElements(subject)
            return subject:OnNext(RangeType(1, total))
        end

        -------------------------------------------------------------------
        --                          constructor                          --
        -------------------------------------------------------------------
        function __ctor(self, list)
            list                        = type(list) == "table" and list or {}
            rawset(self, RawTable, list)
            getObjectSubject(list, elementtype)
        end

        -------------------------------------------------------------------
        --                        de-constructor                         --
        -------------------------------------------------------------------
        function __dtor(self)
            local subject               = rawget(self, Subject)
            if subject then subject:Dispose() end
        end

        -------------------------------------------------------------------
        --                          meta-method                          --
        -------------------------------------------------------------------
        function __index(self, index)
            if type(index) ~= "number" then return end
            return getElement(rawget(self, RawTable), index)
        end

        function __newindex(self, index, value, stack)
            if type(index) ~= "number" then
                error("Usage: reactiveList[index] = value - the index is must be number", (stack or 1) + 1)
            end

            -- Convert to raw value
            if value and isobjecttype(value, IReactive) then
                value                   = value.Value
            end

            local raw                   = rawget(self, RawTable)
            local oldval                = raw[index]
            if oldval == value then return end

            -- keep list
            if oldval == nil and index ~= self.Count + 1 then
                error("Usage: reactiveList[index] = value - the index is out of range", (stack or 1) + 1)
            end

            if value == nil then
                if index ~= self.Count then
                    error("Usage: reactiveList[index] = nil - must use RemoveByIndex instead of assign directly", (stack or 1) + 1)
                end
                return self:Pop()
            end

            -- set directly
            raw[index]                  = value
            local subject               = getObjectSubject(raw)
            removeElement(subject, index, oldval)
            return subject:OnNext(index, insertElement(subject, index, value))
        end

        function __len(self)            return self.Count end
    end)
end)