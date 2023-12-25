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
            getValue                    = function(r) if isObjectType(r, BehaviorSubject) then return r:GetValue() else return r end end,

            Class, Property, Event, Reactive, BehaviorSubject
        }

        -- For dictionary
        if targetclass and Class.IsSubType(targetclass, IKeyValueDict) then
            extend "IKeyValueDict"

            export                      {
                updateDict              = Dictionary.Update,
            }

            -----------------------------------------------------------
            --                        method                         --
            -----------------------------------------------------------
            --- Gets the iterator
            __Iterator__()
            function GetIterator(self)
                local yield             = yield
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
                rawset(self, Reactive, {})  -- reactives
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
                local reactives         = rawget(self, Reactive)
                local r                 = reactives[key]
                if r then
                    return getValue(r)
                else
                    local value         = rawget(self, Class)[key]
                    -- wrap if the value is table
                    if r == nil and type(value) == "table" and type(key) == "string" and key ~= "" then
                        r               = reactive(value, true)
                        if r then
                            reactives[key] = r
                            return getValue(r)
                        else
                            -- don't try wrap again
                            reactives[key] = false
                        end
                    end
                    return value
                end
            end

            --- Send the new value
            function __newindex(self, key, value)
                local reactives         = rawget(self, Reactive)
                local r                 = reactives[key]
                if r then
                    -- BehaviorSubject
                    if isObjectType(r, BehaviorSubject) then
                        self[Class][key]= value
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
                    reactives[key]      = nil
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

            for name, ftr in Class.GetFeatures(targetclass, true) do
                -------------------------------------------------------------------
                --                             event                             --
                -------------------------------------------------------------------
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

                -------------------------------------------------------------------
                --                           property                            --
                -------------------------------------------------------------------
                elseif Property.Validate(ftr) then
                    if Property.IsIndexer(ftr) then
                        if Property.IsWritable(ftr) then __Observable__() end
                        __Indexer__(Property.GetIndexType(ftr))
                        property (name) {
                            type        = Property.GetType(ftr),
                            get         = Property.IsReadable(ftr) and function(self, idx) return rawget(self, Class)[name][idx] end,
                            set         = Property.IsWritable(ftr) and function(self, idx, value) rawget(self, Class)[name][idx] = value end,
                        }
                    else
                        if Property.IsWritable(ftr) then __Observable__() end
                        property (name) {
                            type        = Property.GetType(ftr),
                            get         = Property.IsReadable(ftr) and function(self) return rawget(self, Class)[name] end,
                            set         = Property.IsWritable(ftr) and function(self, value) rawget(self, Class)[name] = value end,
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
                    for name in (raw.GetIterator or pairs)(raw) do
                        temp[name]      = true
                        self[name]      = value[name]
                    end

                    -- clear
                    local reactives     = rawget(self, Reactive)
                    if reactives then
                        for name in pairs(reactives) do
                            if not temp[name] then
                                temp[name]  = true
                                self[name]  = nil
                            end
                        end
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

            -------------------------------------------------------------------
            --                         static method                         --
            -------------------------------------------------------------------
            --- Gets the current raw value of the reactive object
            __Static__()
            function ToRaw(self)
                -- for values
                if type(self)~= "table" then return self end

                -- for raw table
                local cls               = getmetatable(self)
                if cls == nil then return self end

                -- for other types
                if not isSubType(cls, Reactive)         then
                    if isSubType(cls, BehaviorSubject)  then return self.Value end
                    if isSubType(cls, ReactiveList)     then return ReactiveList.ToRaw(self) end
                    return self
                end

                return rawget(self, Class) or rawget(self, RawTable)
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

                    -- as object proxy
                    local ok, err       = pcall(rawget(self, Class) and not rawget(self, Reactive) and updateByClass or updateTable, self, value)
                    if not ok then
                        error("Usage: Reactive.SetRaw(reactive, value) - " .. er, (stack or 1) + 1)
                    end
                    return
                end

                error("Usage: Reactive.SetRaw(reactive, value[, stack]) - the reactive is not valid", (stack or 1) + 1)
            end

            --- Gets the observable for the field
            __Static__()
            function From(self, key, create)
                local reactives         = rawget(self, Reactive)

                -- for class
                if not reactives then   return Observable.From(self, key) end

                -- already wrap
                local r                 = reactives[key]
                if r then return r end

                -- for raw table or dictionary
                local raw               = rawget(self, RawTable) or rawget(self, Class)
                if raw then
                    r                   = raw[key] ~= nil and reactive(raw[key], true) or create and BehaviorSubject() or nil
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
                if init then
                    rawset(init, Reactive, self)
                end
                rawset(self, Reactive, {})
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
                local reactives         = rawget(self, Reactive)
                local r                 = reactives[key]
                if r then
                    return getValue(r)
                else
                    local value         = rawget(self, RawTable)[key]
                    -- wrap if the value is table
                    if r == nil and type(value) == "table" and type(key) == "string" and key ~= "" then
                        r               = reactive(value, true)
                        if r then
                            reactives[key] = r
                            return getValue(r)
                        else
                            -- don't try wrap again
                            reactives[key] = false
                        end
                    end
                    return value
                end
            end

            --- Send the new value
            function __newindex(self, key, value)
                local reactives         = rawget(self, Reactive)
                local r                 = reactives[key]
                if r then
                    -- BehaviorSubject
                    if isObjectType(r, BehaviorSubject) then
                        self[RawTable][key] = value
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
                    reactives[key]      = nil
                end

                -- raw directly
                self[RawTable][key]     = value
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