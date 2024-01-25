--===========================================================================--
--                                                                           --
--                              System.Reactive                              --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2023/04/20                                               --
-- Update Date  :   2024/01/19                                               --
-- Version      :   2.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    -----------------------------------------------------------------------
    --                            Declaration                            --
    -----------------------------------------------------------------------
    class "System.Reactive"                 {}
    class "System.Reactive__Observable__"   {}
    class "System.Reactive.BehaviorSubject" {}
    class "System.Reactive.ReactiveList"    {}

    -----------------------------------------------------------------------
    --                          Implementation                           --
    -----------------------------------------------------------------------
    --- The proxy used to access reactive table field datas
    __Sealed__()
    __Arguments__{ ClassType/nil }:WithRebuild()
    __NoNilValue__(false):AsInheritable()
    __NoRawSet__(false):AsInheritable()
    class "System.Reactive"             (function(_ENV, targetclass)

        export                          {
            type                        = type,
            pairs                       = pairs,
            error                       = error,
            tostring                    = tostring,
            rawget                      = rawget,
            rawset                      = rawset,
            next                        = next,
            pcall                       = pcall,
            yield                       = coroutine.yield,
            getmetatable                = getmetatable,
            isObjectType                = Class.IsObjectType,
            getEventDelegate            = Event.Get,

            -- return value if r is behavior subject
            getValue                    = function(r) if isObjectType(r, BehaviorSubject) then return r:GetValue() else return r end end,

            -- bind data change event handler when accessed
            bindDataChange              = (not targetclass or Class.IsSubType(targetclass, IKeyValueDict)) and function(self, k, r)
                if r and getEventDelegate(OnDataChange, self, true) and (isObjectType(r, Reactive) or isObjectType(r, ReactiveList)) then
                    r.OnDataChange      = r.OnDataChange + function(_, ...) return OnDataChange(self, k, ...) end
                end
                return r
            end or nil,

            -- handle data change event
            handleDataChangeEvent       = (not targetclass or Class.IsSubType(targetclass, IKeyValueDict)) and function(_, owner, name, init)
                if not init then return end
                local reactives         = owner[Reactive]
                for k, r in pairs(reactives) do
                    bindDataChange(owner, k, r)
                end
            end or nil,

            -- wrap the table value as default
            makeReactive                = (not targetclass or Class.IsSubType(targetclass, IKeyValueDict)) and function(self, k, v)
                local r                 = reactive(v, true)
                return r and bindDataChange(self, k, r)
            end or nil,

            Class, Property, Event, Reactive, ReactiveList, BehaviorSubject
        }

        -- For dictionary
        if targetclass and Class.IsSubType(targetclass, IKeyValueDict) then
            extend "IKeyValueDict"

            export                      {
                objMap                  = not Platform.MULTI_OS_THREAD and Toolset.newtable(true, true) or false,
                updateDict              = Dictionary.Update,
            }

            ---------------------------------------------------------------
            --                           event                           --
            ---------------------------------------------------------------
            --- Fired when the data changed
            __EventChangeHandler__(handleDataChangeEvent)
            event "OnDataChange"

            ---------------------------------------------------------------
            --                          method                           --
            ---------------------------------------------------------------
            --- Gets the iterator
            __Iterator__()
            function GetIterator(self)
                local yield             = yield
                local raw               = self[Class]

                -- for raw
                for k in raw:GetIterator() do
                    if type(k) == "string" then
                        yield(k, self[k])
                    end
                end

                -- for reactive with nil value
                for k, v in pairs(self[Reactive]) do
                    if raw[k] == nil then
                        yield(k, getValue(v))
                    end
                end
            end

            --- Update the dictionary
            function Update(self, ...)
                -- For simple
                local update            = self[Class].Update
                local ok, err           = pcall(type(update) == "function" and update or updateDict, self, ...)
                if not ok then error(err, 2) end
            end

            ---------------------------------------------------------------
            --                        constructor                        --
            ---------------------------------------------------------------
            --- bind the reactive and object
            __Arguments__{ IKeyValueDict }
            function __ctor(self, init)
                local reactives         = {}
                rawset(self, Reactive, reactives)
                rawset(self, Class,  init)

                -- make table value reactive, since they may be reactived in other places
                for k, v in init:GetIterator() do
                    if type(k) == "string" and type(v) == "table" then
                        reactives[k]    = makeReactive(self, k, v)
                    end
                end

                -- try avoid to set value in raw dict object is possible
                if objMap then
                    objMap[init]        = self
                else
                    rawset(init, Reactive, self)
                end
            end

            --- use the wrap for objects
            function __exist(_, init)
                if objMap then return objMap[init] end
                return isObjectType(init, Reactive) and init or rawget(init, Reactive)
            end

            ---------------------------------------------------------------
            --                        meta-method                        --
            ---------------------------------------------------------------
            --- Gets the current value
            function __index(self, key)
                local r                 = rawget(self, Reactive)[key]
                if r then return getValue(r) end
                return rawget(self, Class)[key] -- access raw directly
            end

            --- Send the new value
            function __newindex(self, key, value)
                -- check raw
                local raw               = self[Class]
                if raw[key] == value then return end

                -- check reactive
                local reactives         = self[Reactive]
                local r                 = reactives[key]
                if r then
                    -- BehaviorSubject
                    if isObjectType(r, BehaviorSubject) then
                        raw[key]        = value
                        r:OnNext(value)
                        return OnDataChange(self, key, value)

                    -- only accept raw table value
                    elseif type(value) == "table" and getmetatable(value) == nil then
                        SetRaw(r, value, 2)
                        return

                    -- not valid
                    else
                        error("The reactive field " .. tostring(key) .. " is a reactive table, only accept table value", 2)
                    end
                end

                -- raw directly
                raw[key]                = value

                -- make table reactive
                if type(key) == "string" and type(value) == "table" then
                    local r             = makeReactive(self, key, value)
                    if r then
                        reactives[key]  = r
                        value           = r
                    end
                end

                return OnDataChange(self, key, value)
            end

        -- As object proxy and make all property observable
        elseif targetclass then
            export                      {
                checkRet                = Platform.ENABLE_TAIL_CALL_OPTIMIZATIONS
                                        and function(ok, ...) if not ok then error(..., 2) end return ... end
                                        or  function(ok, ...) if not ok then error(..., 3) end return ... end,
                getObject               = function(value) return type(value) == "table" and rawget(value, Class) or value end,
            }

            ---------------------------------------------------------------
            --                           event                           --
            ---------------------------------------------------------------
            --- Fired when the data changed
            event "OnDataChange"

            for name, ftr in Class.GetFeatures(targetclass, true) do
                -----------------------------------------------------------
                --                         event                         --
                -----------------------------------------------------------
                if Event.Validate(ftr) then
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

                -----------------------------------------------------------
                --                       property                        --
                -----------------------------------------------------------
                elseif Property.Validate(ftr) then
                    if Property.IsIndexer(ftr) then
                        if Property.IsWritable(ftr) then __Observable__() end
                        __Indexer__(Property.GetIndexType(ftr))
                        property (name) {
                            type        = Property.GetType(ftr),
                            get         = Property.IsReadable(ftr) and function(self, idx) return rawget(self, Class)[name][idx] end,
                            set         = Property.IsWritable(ftr) and function(self, idx, value) rawget(self, Class)[name][idx] = value return OnDataChange(self, name, idx, value) end,
                        }
                    else
                        if Property.IsWritable(ftr) then __Observable__() end
                        property (name) {
                            type        = Property.GetType(ftr),
                            get         = Property.IsReadable(ftr) and function(self) return rawget(self, Class)[name] end,
                            set         = Property.IsWritable(ftr) and function(self, value) rawget(self, Class)[name] = value return OnDataChange(self, name, value) end,
                        }
                    end
                end
            end

            ---------------------------------------------------------------
            --                          method                           --
            ---------------------------------------------------------------
            for name, method in Class.GetMethods(targetclass, true) do
                _ENV[name]              = function(self, ...) return checkRet(pcall(method, rawget(self, Class), ...)) end
            end

            ---------------------------------------------------------------
            --                        constructor                        --
            ---------------------------------------------------------------
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

            ---------------------------------------------------------------
            --                        meta-method                        --
            ---------------------------------------------------------------
            for name, method in Class.GetMetaMethods(targetclass, true) do
                if name == "__gc" then
                    __dtor              = function(self) return rawget(self, Class):Dispose() end
                else
                    _ENV[name]          = function(self, other, ...) return method(getObject(self), getObject(other), ...) end
                end
            end

        -- As container for reactive fields, common usages
        else
            -- Provide the dictionary features
            extend "IKeyValueDict"

            export                      {
                pcall                   = pcall,
                pairs                   = pairs,
                getmetatable            = getmetatable,
                isSubType               = Class.IsSubType,
                getFeatures             = Class.GetFeatures,
                isProperty              = Property.Validate,
                isWritable              = Property.IsWritable,
                isIndexer               = Property.IsIndexer,
                rawMap                  = not Platform.MULTI_OS_THREAD and Toolset.newtable(true, true) or false,

                updateByClass           = function(self, value)
                    for name, prop in getFeatures(getmetatable(self), true) do
                        if isProperty(prop) and isWritable(prop) and not isIndexer(prop) then
                            self[name]  = value[name]
                        end
                    end
                end,

                updateTable             = function(self, value)
                    local raw           = rawget(self, Class) or rawget(self, RawTable)
                    if not raw then return end

                    -- update
                    local temp          = {}
                    for k in self:GetIterator() do
                        temp[k]         = true
                        self[k]         = value[k]
                    end

                    -- add
                    for name in pairs(value) do
                        if not temp[name] then
                            self[name]  = value[name]
                        end
                    end
                end,

                Reactive, ReactiveList, BehaviorSubject, RawTable, Observable
            }

            ---------------------------------------------------------------
            --                           event                           --
            ---------------------------------------------------------------
            --- Fired when the data changed
            __EventChangeHandler__(handleDataChangeEvent)
            event "OnDataChange"

            ---------------------------------------------------------------
            --                       static method                       --
            ---------------------------------------------------------------
            --- Gets the current raw value of the reactive object
            __Static__()
            function ToRaw(self)
                -- for values
                if type(self) ~= "table" then return self end

                -- for raw table
                local cls               = getmetatable(self)
                if cls == nil then return self end

                -- behavior subject
                if isSubType(cls, BehaviorSubject) then
                    return self.Value

                -- reactive list
                elseif isSubType(cls, ReactiveList) then
                    return ReactiveList.ToRaw(self)

                -- reactive
                elseif isSubType(cls, Reactive) then
                    return rawget(self, Class) or rawget(self, RawTable)
                end

                -- other
                return self
            end

            --- Sets a raw table value to the reactive object
            __Static__()
            function SetRaw(self, value, stack)
                local cls               = getmetatable(self)
                if type(self) ~= "table" or not cls then error("Usage: Reactive.SetRaw(reactive, value[, stack]) - the reactive not valid", (stack or 1) + 1) end

                -- behavior subject
                if isSubType(cls, BehaviorSubject) then
                    return self:OnNext(value)

                -- reactive list
                elseif isSubType(cls, ReactiveList) then
                    ReactiveList.SetRaw(self, value, (stack or 1) + 1)
                    return

                -- reactive
                elseif isSubType(cls, Reactive) then
                    if value ~= nil and type(value) ~= "table" then
                        error("Usage: Reactive.SetRaw(reactive, value[, stack]) - the value not valid", (stack or 1) + 1)
                    end

                    -- as object proxy
                    local ok, err       = pcall(rawget(self, Class) and not rawget(self, Reactive) and updateByClass or updateTable, self, value)
                    if not ok then error("Usage: Reactive.SetRaw(reactive, value) - " .. err, (stack or 1) + 1) end
                    return
                end

                -- other
                error("Usage: Reactive.SetRaw(reactive, value[, stack]) - the reactive not valid", (stack or 1) + 1)
            end

            --- Gets the observable for the field
            __Static__()
            function From(self, key, create)
                -- for the whole object
                if not key and (isObjectType(self, Reactive) or isObjectType(self, ReactiveList)) then
                    return Observable.From(self.OnDataChange)
                end

                -- for index value from the reactive list
                if isObjectType(self, ReactiveList) then
                    return ReactiveList.From(self, key, create)
                end

                -- for reactive object
                local reactives         = rawget(self, Reactive)

                -- for class
                if not reactives then return Observable.From(self, key) end

                -- already wrap
                local r                 = reactives[key]
                if r then return r end

                -- for raw table or dictionary
                local raw               = rawget(self, RawTable) or rawget(self, Class)
                if raw and type(key) == "string" then
                    local value         = raw[key]
                    r                   = (value ~= nil or create) and makeReactive(self, key, value) or nil
                    reactives[key]      = r
                    return r
                end
            end

            ---------------------------------------------------------------
            --                          method                           --
            ---------------------------------------------------------------
            --- Gets the iterator
            __Iterator__()
            function GetIterator(self)
                local yield             = yield
                local raw               = self[RawTable]

                -- raw first
                for k in pairs(raw) do
                    if type(k) == "string" then
                        yield(k, self[k])
                    end
                end

                -- rest reactives
                for k, v in pairs(self[Reactive]) do
                    if raw[k] == nil then
                        yield(k, getValue(v))
                    end
                end
            end

            ---------------------------------------------------------------
            --                        constructor                        --
            ---------------------------------------------------------------
            __Arguments__{ RawTable/nil }
            function __ctor(self, init)
                local reactives         = {}
                rawset(self, Reactive, reactives)
                rawset(self, RawTable, init or {})

                if init then
                    -- wrap all child table
                    for k, v in pairs(init) do
                        if type(k) == "string" and type(v) == "table" then
                            reactives[k]= makeReactive(self, k, v)
                        end
                    end

                    -- record the map
                    if rawMap then
                        rawMap[init]    = self
                    else
                        rawset(init, Reactive, self)
                    end
                end
            end

            __Arguments__{ RawTable/nil }
            function __exist(_, init)
                if not init then return end
                return rawMap and rawMap[init] or init[Reactive]
            end

            ---------------------------------------------------------------
            --                        meta-method                        --
            ---------------------------------------------------------------
            --- Gets the current value
            function __index(self, key)
                local reactives         = rawget(self, Reactive)
                local r                 = reactives[key]
                if r then return getValue(r) end
                return rawget(self, RawTable)[key]
            end

            --- Send the new value
            function __newindex(self, key, value)
                -- check raw
                local raw               = self[RawTable]
                if raw[key] == value then return end

                -- check the reactive
                local reactives         = rawget(self, Reactive)
                local r                 = reactives[key]
                if r then
                    -- BehaviorSubject
                    if isObjectType(r, BehaviorSubject) then
                        -- update
                        raw[key]        = value
                        r:OnNext(value)
                        return OnDataChange(self, key, value)

                    -- only accept raw table value
                    elseif type(value) == "table" and getmetatable(value) == nil then
                        SetRaw(r, value, 2)
                        return

                    -- not valid
                    else
                        error("The reactive field " .. tostring(key) .. " is a reactive table, only accept table value", 2)
                    end
                end

                -- raw directly
                raw[key]                = value

                -- make table reactive
                if type(key) == "string" and type(value) == "table" then
                    local r             = makeReactive(self, key, value)
                    if r then
                        reactives[key]  = r
                        value           = r
                    end
                end

                return OnDataChange(self, key, value)
            end
        end
    end)

    -----------------------------------------------------------------------
    --                              Keyword                              --
    -----------------------------------------------------------------------
    Environment.RegisterGlobalNamespace("System.Reactive")

    export                              {
        type                            = type,
        pcall                           = pcall,
        error                           = error,
        tostring                        = tostring,
        getmetatable                    = getmetatable,
        getObjectClass                  = Class.GetObjectClass,
        isSubType                       = Class.IsSubType,
        isObjectType                    = Class.IsObjectType,
        isarray                         = Toolset.isarray,
        isValueType                     = Class.IsValueType,

        IObservable, Reactive, ReactiveList, BehaviorSubject,
        IList, List, IDictionary, Dictionary, IIndexedList, IKeyValueDict
    }

    Environment.RegisterRuntimeKeyword  {
        --- Wrap the target value to a Reactive(for table or object), ReactiveList(for list) or BehaviorSubjcet(for value)
        reactive                        = function(value, silent)
            if value == nil then        return Reactive() end

            -- Check the value
            local tval                  = type(value)
            if tval == "table" then
                local cls               = getObjectClass(value)

                if cls then
                    -- already wrap
                    if isSubType(cls, Reactive) or isSubType(cls, ReactiveList) or isSubType(cls, BehaviorSubject) then
                        return value

                    -- wrap the observable or value as behavior subject
                    elseif isSubType(cls, IObservable) or isValueType(cls) then
                        return BehaviorSubject(value)

                    -- wrap list or array to reactive list
                    elseif isSubType(cls, IList) then
                        if isSubType(cls, List) then
                            return ReactiveList[List](value)
                        elseif isSubType(cls, IIndexedList) then
                            return ReactiveList[cls](value)
                        elseif not silent then
                            error("Usage: reactive(data[, silent]) - the data of " .. tostring(cls) .. " is not supported", 2)
                        end
                        return

                    -- wrap dictionary
                    elseif isSubType(cls, IDictionary) then
                        if isSubType(cls, IKeyValueDict) then
                            return Reactive[Dictionary](value)
                        elseif not silent then
                            error("Usage: reactive(data[, silent]) - the data of " .. tostring(cls) .. " is not supported", 2)
                        end
                        return

                    -- common wrap
                    else
                        return Reactive[cls](value)
                    end
                end

                -- wrap array to reactive list
                if isarray(value) then
                    return ReactiveList(value)

                -- wrap the table to Reactive
                else
                    return Reactive(value)
                end

            -- wrap scalar value to behavior subject
            elseif tval == "number" or tval == "string" or tval == "boolean" then
                return BehaviorSubject(value)

            -- wrap function to a behavior subject that subscribe an observable generated from the function
            elseif tval == "function" then
                return BehaviorSubject(Observable(value))
            end

            -- throw error if not silent
            if not silent then
                error("Usage: reactive(data[, silent]) - the data can't be converted to a reactive object", 2)
            end
        end
    }
end)