--===========================================================================--
--                                                                           --
--                              System.Reactive                              --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2023/04/20                                               --
-- Update Date  :   2023/11/14                                               --
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
        if targetclass and Class.IsSubType(targetclass, Dictionary) then
            extend "IDictionary"

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
                local ok, err           = pcall(self[Class].Update, self, ...)
                if not ok then error(err, 2) end
            end

            -------------------------------------------------------------------
            --                          constructor                          --
            -------------------------------------------------------------------
            -- bind the reactive and object
            __Arguments__{ IDictionary }
            function __ctor(self, init)
                rawset(self, Class, init)
                rawset(self, Reactive, {})  -- Subjects
                rawset(init, Reactive, self)
            end

            -- use the wrap for objects
            function __exist(_, init)
                return init and rawget(init, Reactive)
            end

            -------------------------------------------------------------------
            --                          meta-method                          --
            -------------------------------------------------------------------
            --- Gets the current value
            function __index(self, key)
                local subject           = rawget(self, Reactive)[key]
                if subject then
                    if isObjectType(subject, BehaviorSubject) then
                        -- the current value
                        return subject:GetValue()
                    else
                        -- inner reactive
                        return subject
                    end
                end
            end

            --- Send the new value
            function __newindex(self, key, value)
                local fields            = rawget(self, Reactive)

                -- Send the value
                local subject           = fields[key]
                if subject then
                    -- BehaviorSubject
                    if isObjectType(subject, BehaviorSubject) then
                        return subject:OnNext(value)

                    -- Only accept raw table value
                    elseif type(value) == "table" and getmetatable(value) == nil then
                        if isObjectType(subject, ReactiveList) then
                            -- Reactive List
                            ReactiveList.SetRaw(subject, value, 2)
                        else
                            -- Reactive
                            SetRaw(subject, value, 2)
                        end
                        return

                    -- Not valid
                    else
                        error("The reactive field " .. tostring(key) .. " is a reactive table, only accept table value", 2)
                    end
                end

                -- New reactive - hash key only
                if type(key) == "string" and key ~= "" and value ~= nil and type(value) ~= "function" then
                    local r             = reactive(value, true)
                    if r then
                        fields[key]     = r
                        return
                    end
                end
                rawset(self, key, value)
            end

        -- As object proxy and make all property observable
        elseif targetclass then
            local checkRet              = Platform.ENABLE_TAIL_CALL_OPTIMIZATIONS
                                        and function(ok, ...) if not ok then error(..., 2) end return ... end
                                        or  function(ok, ...) if not ok then error(..., 3) end return ... end
            local getObject             = function(value) return type(value) == "table" and rawget(value, Class) or value end

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

            local function setObjectProp(self, name, value)
                self[name]              = value
            end

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
                    local object            = rawget(self, Class)
                    if object then
                        for name, prop in getFeatures(getmetatable(self), true) do
                            if isProperty(prop) and isWritable(prop) and not isIndexer(prop) then
                                local ok, er= pcall(setObjectProp, self, name, value[name])
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
            function From(self, key)
                -- For class
                if rawget(self, Class) then return Observable.From(self, key) end

                -- For table
                local subject           = rawget(self, Reactive)[key]
                return subject and isObjectType(subject, BehaviorSubject) and subject or nil
            end

            -------------------------------------------------------------------
            --                          constructor                          --
            -------------------------------------------------------------------
            __Arguments__{ RawTable/nil }
            function __ctor(self, init)
                local reactives         = {}
                local raw               = {}

                if init then
                    for k, v in pairs(init) do
                        local vtype     = type(v)
                        if type(k) == "string" and k ~= "" and vtype ~= "function" and vtype ~= "userdata" then
                            if vtype == "table" then
                                local r = reactive(v, true)
                                if r then
                                    reactives[k] = r
                                else
                                    rawset(self, k, v) -- not reactivable
                                end
                            else
                                -- only make value reactive when require
                                raw[k]  = v
                            end
                        else
                            rawset(self, k, v)
                        end
                    end
                end

                rawset(self, Reactive, reactives)
                rawset(self, RawTable, raw)
            end

            -------------------------------------------------------------------
            --                          meta-method                          --
            -------------------------------------------------------------------
            --- Gets the current value
            function __index(self, key)
                -- Gets the raw value directly
                local value             = self[RawTable][key]
                if value ~= nil then return value end

                -- Gets the reactives
                value                   = self[Reactive][key]
                if value then
                    if isObjectType(value, BehaviorSubject) then
                        -- Gets the current value
                        return value:GetValue()
                    else
                        -- The sub-reactive
                        return value
                    end
                end
            end

            --- Send the new value
            function __newindex(self, key, value)
                local r                 = self[Reactive][key]

                if r then
                    -- BehaviorSubject
                    if isObjectType(r, BehaviorSubject) then
                        r:OnNext(value)
                        self[RawTable][key] = value
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
                if raw[key] ~=  nil then
                    raw[key]            = value

                -- Check by type
                elseif type(key) == "string" and key ~= "" and value ~= nil and type(value) ~= "function" then
                    local r             = reactive(value, true)
                    if r then
                        fields[key]     = r
                        return
                    end
                end
                rawset(self, key, value)




                local fields            = rawget(self, Reactive)

                -- Send the value
                local subject           = fields[key]
                if subject then
                    -- BehaviorSubject
                    if isObjectType(subject, BehaviorSubject) then
                        return subject:OnNext(value)

                    -- Only accept raw table value
                    elseif type(value) == "table" and getmetatable(value) == nil then
                        if isObjectType(subject, ReactiveList) then
                            -- Reactive List
                            ReactiveList.SetRaw(subject, value, 2)
                        else
                            -- Reactive
                            SetRaw(subject, value, 2)
                        end
                        return

                    -- Not valid
                    else
                        error("The reactive field " .. tostring(key) .. " is a reactive table, only accept table value", 2)
                    end
                end

                -- New reactive - hash key only
                if type(key) == "string" and key ~= "" and value ~= nil and type(value) ~= "function" then
                    local r             = reactive(value, true)
                    if r then
                        fields[key]     = r
                        return
                    end
                end
                rawset(self, key, value)
            end
        end
    end)

    -----------------------------------------------------------------------
    --                              Keyword                              --
    -----------------------------------------------------------------------
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
        IList, List, IDictionary, Dictionary
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
                        if isSubType(cls, List) then
                            return ReactiveList[List](value)
                        elseif not silent then
                            error("Usage: reactive(data[, silent]) - the data of " .. tostring(cls) .. " is not supported", 2)
                        end
                        return
                    end

                    -- wrap dictionary
                    elseif isSubType(cls, IDictionary) then
                        if isSubType(cls, Dictionary) then
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