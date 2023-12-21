--===========================================================================--
--                                                                           --
--                              System.Reactive                              --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2023/04/20                                               --
-- Update Date  :   2023/12/18                                               --
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
    __Sealed__() __Arguments__{ ClassType/nil }:WithRebuild()
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

            Class, Property, Event, Reactive
        }

        -- For dictionary
        if targetclass and Class.IsSubType(targetclass, IKeyValueDict) then
            extend "IKeyValueDict"

            export                      {
                updateDict              = Dictionary.Update,
                getValue                = function(r)
                    if isObjectType(r, BehaviorSubject) then
                        return r:GetValue()
                    else
                        return r
                    end
                end
            }

            -----------------------------------------------------------
            --                        method                         --
            -----------------------------------------------------------
            --- Gets the iterator
            __Iterator__()
            function GetIterator(self)
                for k, v in self[Class]:GetIterator() do
                    yield(k, v)
                end
            end

            --- Update the dictionary
            function Update(self, ...)
                -- For simple
                local update            = self[Class].Update
                local ok, err           = pcall(type(update) == "function" and update or updateDict, self, ...)
                if not ok then error(err, 2) end
            end

            -------------------------------------------------------------------
            --                          constructor                          --
            -------------------------------------------------------------------
            --- bind the reactive and object
            __Arguments__{ IKeyValueDict }
            function __ctor(self, init)
                rawset(init, Reactive, self)
                rawset(self, Reactive, {})  -- Reactives
                rawset(self, Class, init)
            end

            --- use the wrap for objects
            function __exist(_, init)
                return isObjectType(init, Reactive) and init or rawget(init, Reactive)
            end

            -------------------------------------------------------------------
            --                          meta-method                          --
            -------------------------------------------------------------------
            --- Gets the current value
            function __index(self, key)
                local r                 = self[Reactive][key]
                if r then
                    return getValue(r)
                else
                    local value         = self[Class][key]
                    -- wrap if the value is table
                    if r == nil and type(value) == "table" and type(key) == "string" and key ~= "" then
                        r               = reactive(value, true)
                        if r then
                            return getValue(r)
                        else
                            -- don't try wrap again
                            self[Reactive][key] = false
                        end
                    end
                    return value
                end
            end

            --- Send the new value
            function __newindex(self, key, value)
                local r                 = self[Reactive][key]
                if r then
                    -- BehaviorSubject
                    if isObjectType(r, BehaviorSubject) then
                        self[Class][key] = value
                        r:OnNext(value)
                        return

                    -- only accept raw table value
                    elseif type(value) == "table" and getmetatable(value) == nil then
                        SetRaw(r, value, 2)
                        return

                    -- not valid
                    else
                        error("The reactive field " .. tostring(key) .. " is a reactive table, only accept table value", 2)
                    end

                --- non reactivable
                elseif r == false then
                    -- allow override
                    self[Reactive][key] = nil
                end

                -- raw directly
                self[Class][key]        = value
            end

        -- As object proxy and make all property observable
        elseif targetclass then
            local checkRet              = Platform.ENABLE_TAIL_CALL_OPTIMIZATIONS
                                        and function(ok, ...) if not ok then error(..., 2) end return ... end
                                        or  function(ok, ...) if not ok then error(..., 3) end return ... end
            local getObject             = function(value) return type(value) == "table" and rawget(value, Class) or value end

            for name, ev in Class.GetFeatures(targetclass, true) do
                -------------------------------------------------------------------
                --                             event                             --
                -------------------------------------------------------------------
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

                -------------------------------------------------------------------
                --                           property                            --
                -------------------------------------------------------------------
                elseif Property.Validate(prop) then
                    if Property.IsIndexer(prop) then
                        if Property.IsWritable(prop) then __Observable__() end
                        __Indexer__(Property.GetIndexType(prop))
                        property (name) {
                            type        = Property.GetType(prop),
                            get         = Property.IsReadable(prop) and function(self, idx) return rawget(self, Class)[name][idx] end,
                            set         = Property.IsWritable(prop) and function(self, idx, value) rawget(self, Class)[name][idx] = value end,
                        }
                    else
                        if Property.IsWritable(prop) then __Observable__() end
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

        -- As container for reactive fields, common usages
        else
            export                      {
                pcall                   = pcall,
                getmetatable            = getmetatable,
                isSubType               = Class.IsSubType,
                getFeatures             = Class.GetFeatures,
                isProperty              = Property.Validate,
                isWritable              = Property.IsWritable,
                isIndexer               = Property.IsIndexer,

                Reactive, ReactiveList, BehaviorSubject, RawTable
            }

            -------------------------------------------------------------------
            --                         static method                         --
            -------------------------------------------------------------------
            --- Gets the current raw value of the reactive object
            __Static__()
            function ToRaw(self)
                -- For values
                if type(self)~= "table" then return self end

                -- For raw table
                local cls               = getmetatable(self)
                if cls == nil then return self end

                -- For other types
                if not isSubType(cls, Reactive)         then
                    if isSubType(cls, BehaviorSubject)  then return self.Value end
                    if isSubType(cls, ReactiveList)     then return ReactiveList.ToRaw(self) end
                    return self
                end

                -- As object proxy
                local object            = rawget(self, Class)
                if object then return object end

                -- To raw
                local raw               = {}

                for k, v in pairs(self) do
                    if k ~= Reactive    then
                        -- For non-reactive fields
                        raw[k]          = v
                    else
                        -- For reactive fields
                        for name, react in pairs(v) do
                            raw[name]   = ToRaw(react)
                        end
                    end
                end

                return raw
            end

            --- Sets a raw table value to the reactive object
            __Static__()
            function SetRaw(self, value, stack)
                local cls               = getmetatable(self)
                if type(self) ~= "table" or not cls then error("Usage: Reactive.SetRaw(reactive, value[, stack]) - the reactive is not valid", (stack or 1) + 1) end

                -- Behavior Subject
                if isSubType(cls, BehaviorSubject) then
                    return self:OnNext(value)

                -- Reactive List
                elseif isSubType(cls, ReactiveList) then
                    ReactiveList.SetRaw(self, value, (stack or 1) + 1)
                    return

                -- Reactive
                elseif isSubType(cls, Reactive) then
                    if value ~= nil and type(value) ~= "table" then
                        error("Usage: Reactive.SetRaw(reactive, value[, stack]) - the value is not valid", (stack or 1) + 1)
                    end

                    -- As object proxy
                    local object        = rawget(self, Class)
                    if object then
                        for name, prop in getFeatures(getmetatable(self), true) do
                            if isProperty(prop) and isWritable(prop) and not isIndexer(prop) then
                                local ok, er= pcall(function(s, k, v) s[k] = v end, self, name, value[name])
                                if not ok then
                                    error("Usage: Reactive.SetRaw(reactive, value) - " .. er, (stack or 1) + 1)
                                end
                            end
                        end
                        return
                    end

                    -- As reactive table
                    local fields        = rawget(self, Reactive)
                    for k in pairs(fields) do
                        self[k]         = value[k]
                    end

                    -- Clear
                    for k in pairs(self) do
                        if k ~= Reactive and value[k] == nil then
                            rawset(self, k, nil)
                        end
                    end

                    -- Update
                    for k, v in pairs(value) do
                        if not fields[k] then
                            self[k]     = v
                        end
                    end
                    return
                end

                error("Usage: Reactive.SetRaw(reactive, value) - the reactive is not valid", (stack or 1) + 1)
            end

            --- Gets the observable for the field
            __Static__()
            function From(self, key, create)
                -- For class
                if rawget(self, Class) then return Observable.From(self, key) end

                -- For reactive fields
                local reactives         = rawget(self, Reactive)
                local subject           = reactives and reactives[key]
                if subject or not reactives then return subject end

                -- For raw table fields
                local raw               = rawget(self, RawTable)
                if raw then
                    local r             = raw[key] ~= nil and reactive(raw[key], true) or create and BehaviorSubject() or nil
                    if r then
                        reactives[key]  = r
                    end
                    return r
                end
            end

            -------------------------------------------------------------------
            --                          constructor                          --
            -------------------------------------------------------------------
            __Arguments__{ RawTable/nil }
            function __ctor(self, init)
                local reactives         = {}

                if init then
                    for k, v in pairs(init) do
                        if type(k) == "string" and k ~= "" and type(v) == "table" then
                            local r     = reactive(v, true)
                            if r then
                                reactives[k] = r
                            end
                        else
                            -- access directly
                            rawset(self, k, v)
                        end
                    end

                    rawset(init, Reactive, self)
                end

                rawset(self, Reactive, reactives)
                rawset(self, RawTable, init or {})
            end

            __Arguments__{ RawTable/nil }
            function __exist(_, init)
                return init and init[Reactive]
            end

            -------------------------------------------------------------------
            --                          meta-method                          --
            -------------------------------------------------------------------
            --- Gets the current value
            function __index(self, key)
                local r                 = self[Reactive][key]
                if r then
                    if isObjectType(r, BehaviorSubject) then
                        return r:GetValue()
                    else
                        return r
                    end
                else
                    return self[RawTable][key]
                end
            end

            --- Send the new value
            function __newindex(self, key, value)
                local r                 = self[Reactive][key]

                if r then
                    -- BehaviorSubject
                    if isObjectType(r, BehaviorSubject) then
                        self[RawTable][key] = value
                        r:OnNext(value)
                        return

                    -- Only accept raw table value
                    elseif type(value) == "table" and getmetatable(value) == nil then
                        SetRaw(r, value, 2)
                        return

                    -- Not valid
                    else
                        error("The reactive field " .. tostring(key) .. " is a reactive table, only accept table value", 2)
                    end
                end

                -- Raw directly
                local raw               = self[RawTable]
                if type(key) == "string" and key ~= "" and value ~= nil and type(value) == "table" then
                    r                   = reactive(value, true)
                    if r then self[Reactive][key] = r end
                end
                raw[key]                = value
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
                local cls               = Class.GetObjectClass(value)

                if cls then
                    -- already wrap
                    if isSubType(cls, Reactive) or isSubType(cls, ReactiveList) or isSubType(cls, BehaviorSubject) then
                        return value

                    -- wrap the observable or value as behavior subject
                    elseif isSubType(cls, IObservable) or isValueType(cls) then
                        return BehaviorSubject(value)

                    -- wrap list or array to reactive list
                    elseif isSubType(cls, IList) then
                        if isSubType(cls,  IIndexedList) then
                            return ReactiveList[List](value)
                        elseif not silent then
                            error("Usage: reactive(data[, silent]) - the data of " .. tostring(cls) .. " is not supported", 2)
                        end
                        return

                    -- wrap dictionary
                    elseif isSubType(cls, IDictionary) then
                        if isSubType(cls,  IKeyValueDict) then
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