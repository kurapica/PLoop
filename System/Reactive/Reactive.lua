--===========================================================================--
--                                                                           --
--                              System.Reactive                              --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2023/04/20                                               --
-- Update Date  :   2024/09/20                                               --
-- Version      :   2.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    -----------------------------------------------------------------------
    --                       static implementation                       --
    -----------------------------------------------------------------------
    class "System.Reactive"             (function(_ENV)
        -------------------------------------------------------------------
        --                          declaration                          --
        -------------------------------------------------------------------
        --- Represents the reactive values
        __Sealed__()
        interface "IReactive"           (function(_ENV)
            --- Gets/Sets the raw value
            __Abstract__()
            property "Value"            { type = Any }
        end)

        class "__Observable__"          {}
        class "Observable"              {}
        class "ReactiveValue"           {}
        class "ReactiveField"           {}
        class "ReactiveList"            {}
        class "Subject"                 {}

        -------------------------------------------------------------------
        --                            export                             --
        -------------------------------------------------------------------
        export                          {
            type                        = type,
            getmetatable                = getmetatable,
            issubtype                   = Class.IsSubType,
            isvaluetype                 = Class.IsValueType,
            getobjectclass              = Class.GetObjectClass,
            gettempparams               = Class.GetTemplateParameters,
            isclass                     = Class.Validate,
            getsuperclass               = Class.GetSuperClass,
            isenum                      = Enum.Validate,
            isstruct                    = Struct.Validate,
            getstructcategory           = Struct.GetStructCategory,
            getarrayelement             = Struct.GetArrayElement,
            isarray                     = Toolset.isarray,

            IList, IDictionary, IKeyValueDict, IObservable,
            Any, Number, String, Boolean, List, Reactive,
        }

        -------------------------------------------------------------------
        --                         static method                         --
        -------------------------------------------------------------------
        --- Gets the recommend reactive type for the given value or type
        -- @param value                 the value to be check
        -- @param valuetype             the value type
        -- @param asfield               use ReactiveField instead of ReactiveValue
        __Static__()
        __Arguments__{ Any/nil, AnyType/nil, Boolean/nil }
        function GetReactiveType(value, valuetype, asfield)
            -- validate the value with the value type
            if valuetype and value ~= nil and not getmetatable(valuetype).ValidateValue(valuetype, value, true) then valuetype = nil end

            -- get value type
            local valtype               = type(value)
            local metatype
            if value == nil then
                metatype                = valuetype
            elseif valtype == "table" then
                metatype                = getobjectclass(value) or valuetype
            elseif valtype == "number" then
                metatype                = valuetype or Number
            elseif valtype == "string" then
                metatype                = valuetype or String
            elseif valtype == "boolean" then
                metatype                = valuetype or Boolean
            else
                return
            end

            -- get reactive type
            if metatype == nil then
                return valtype == "table" and (isarray(value) and ReactiveList or Reactive) or nil

            elseif metatype == Any then
                return asfield and ReactiveField or ReactiveValue

            elseif isenum(metatype) then
                return asfield and ReactiveField[metatype] or ReactiveValue[metatype]

            elseif isstruct(metatype) then
                local cate              = getstructcategory(metatype)

                if cate == "CUSTOM" then
                    return asfield and ReactiveField[metatype] or ReactiveValue[metatype]

                elseif cate == "ARRAY" then
                    local element       = getarrayelement(metatype)
                    return element and ReactiveList[element] or ReactiveList

                -- member or dict
                else
                    return Reactive[metatype]
                end

            elseif isclass(metatype) then
                -- already reactive
                if issubtype(metatype, IReactive) then
                    return nil

                -- observable as value queue
                elseif issubtype(metatype, IObservable) then
                    return ReactiveValue

                -- if is value type like Date
                elseif isvaluetype(metatype) then
                    return asfield and ReactiveField[metatype] or ReactiveValue[metatype]

                -- wrap list or array to reactive list
                elseif issubtype(metatype, IList) then
                    -- to complex to cover more list types, only List for now
                    if issubtype(metatype, List) then
                        local ele       = gettempparams(metatype)
                        return ele and ReactiveList[ele] or ReactiveList
                    end

                -- wrap dictionary
                elseif issubtype(metatype, IDictionary) then
                    -- only key-value dict support
                    if issubtype(metatype, IKeyValueDict) then
                        return Reactive[metatype]
                    end

                -- common class
                else
                    return Reactive[metatype]
                end
            end
        end
    end)

    -----------------------------------------------------------------------
    --                              Keyword                              --
    -----------------------------------------------------------------------
    Environment.RegisterGlobalNamespace("System.Reactive")

    export                              {
        type                            = type,
        getmetatable                    = getmetatable,
        error                           = error,
        pcall                           = pcall,
        rawget                          = rawget,
        rawset                          = rawset,
        isclass                         = Class.Validate,
        issubtype                       = Class.IsSubType,
        getobjectclass                  = Class.GetObjectClass,
        getreactivetype                 = System.Reactive.GetReactiveType,
        istructvalue                    = Struct.ValidateValue,

        Reactive, ReactiveList, ReactiveField, Any, Attribute, AnyType, Subject, IReactive
    }

    Environment.RegisterRuntimeKeyword  {
        --- Wrap the target value to a Reactive(for table or object), ReactiveList(for list) or BehaviorSubjcet(for value)
        reactive                        = Prototype {
            __index                     = function(self, rtype, stack)
                if type(rtype) == "table" and getmetatable(rtype) == nil then
                    local ok, stype     = Attribute.IndependentCall(function(temp) local type = struct(temp) return type end, rtype)
                    if not ok then error(stype, (stack or 1) + 1) end
                    rtype               = stype
                end
                if not istructvalue(AnyType, rtype) then error("Usage: reactive[type](data[, silent]) - the type is not a validation type", (stack or 1) + 1) end
                return function(value, silent) local result = self(value, silent, rtype, (stack or 1) + 1) return result end
            end,
            __call                      = function(self, value, silent, recommendtype, stack)
                -- default
                if value == nil and recommendtype == nil then return Reactive() end

                -- return reactive objects directly
                local cls               = value and getobjectclass(value) or nil
                if cls and (issubtype(cls, Reactive) or issubtype(cls, ReactiveList) or issubtype(cls, ReactiveField)) then return value end

                if value == nil and isclass(recommendtype) then
                    if not silent then
                        error("Usage: reactive[type](object[, silent]) - the data object is not provided", (stack or 1) + 1)
                    end
                    return
                end

                -- gets the reactive type
                local rtype             = getreactivetype(value, recommendtype)
                if rtype == nil then
                    if not silent then
                        error("Usage: reactive[type](data[, silent]) - the data or type is not supported", (stack or 1) + 1)
                    end
                    return
                end

                return rtype(value)
            end
        }
    }

    -----------------------------------------------------------------------
    --                              utility                              --
    -----------------------------------------------------------------------
    -- the reactive map
    local objectSubjectMap              = Toolset.newtable(true)
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
    local onObjectNext                  = function(obj, ...) return getObjectSubject(obj):OnNext(...) end
    local onObjectError                 = function(obj, ex)  return getObjectSubject(obj):OnError(ex) end
    local onObjectCompleted             = function(obj)      return getObjectSubject(obj):OnCompleted() end

    -- switch object value
    local switchObject                  = function(self, new)
        local subject                   = rawget(self, Subject)
        if not subject then return end
        subject.Observable              = new and getObjectSubject(new) or nil
    end

    -- subscribe the children
    local subscribeReactive             = function(self, k, r)
        local subject                   = rawget(self, Subject)
        if r and subject and not rawget(subject, r) then
            rawset(subject, r, (r:Subscribe(
                function(...) return onObjectNext( rawget(self, RawTable), k, ...) end,
                function(ex)  return onObjectError(rawget(self, RawTable), ex) end)
            ))
        end
        return r
    end

    -- release the children
    local releaseReactive               = function(self, r)
        local subject                   = rawget(self, Subject)
        if r and subject and rawget(subject, r) then
            subject[r]:Dispose()
            rawset(subject, r, nil)
        end
    end

    -- release all subscriptions
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
    local makeReactive                  = function(self, k, v, type, rtype)
        rtype                           = rtype or getreactivetype(v, type, true)
        local r                         = rtype and (issubtype(rtype, ReactiveField) and rtype(self, k) or rtype(v))
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

    -----------------------------------------------------------------------
    --                          implementation                           --
    -----------------------------------------------------------------------
    --- The references used to access reactive table/class field/property datas
    __Sealed__()
    __Arguments__{ AnyType/nil }:WithRebuild()
    __NoNilValue__(false):AsInheritable()
    __NoRawSet__(false):AsInheritable()
    class "System.Reactive.ObjectProxy" (function(_ENV, targettype)
        extend "IObservable" "IKeyValueDict" "IReactive"

        export                          {
            type                        = type,
            pairs                       = pairs,
            error                       = error,
            tostring                    = tostring,
            rawget                      = rawget,
            rawset                      = rawset,
            pcall                       = pcall,
            yield                       = coroutine.yield,
            getmetatable                = getmetatable,
            isobjecttype                = Class.IsObjectType,
            issubtype                   = Class.IsSubType,
            properties                  = false,
            setvalue                    = Toolset.setvalue,

            Class, Property, Event, Reactive, ReactiveList, ReactiveField, ReactiveValue, Observable, Subscription, IReactive, IObservable
        }

        -------------------------------------------------------------------
        --                   non-dict class/interface                    --
        -------------------------------------------------------------------
        -- for common types
        if targettype and (Class.Validate(targettype) or Interface.Validate(targettype)) and not Interface.IsSubType(targettype, IKeyValueDict) then
            properties                  = {}

            -- simple parse value
            local simpleparse           = function (val) return type(val) == "table" and rawget(val, RawTable) or val end

            -- Binding object methods
            for name, func, isstatic in Class.GetMethods(targettype, true) do
                if not isstatic then
                    _ENV[name]          = function(self, ...) local raw = rawget(self, RawTable) if raw then return func(raw, ...) end end
                end
            end

            -- Binding meta-methods
            for name, func in Class.GetMetaMethods(targettype, true) do
                -- dispose
                if name == "__gc" then
                    _ENV.__dtor         = function(self) local raw = rawget(self, RawTable) return raw and raw:Dispose() end

                -- single argument
                elseif name == "__unm" or name == "__len" or name == "__tostring" then
                    _ENV[name]          = function(self) local raw = rawget(self, RawTable) return raw and func(raw) end

                -- __call
                elseif name == "__call" or name == "__ipairs" or name == "__pairs" then
                    _ENV[name]          = function(self, ...) local raw = rawget(self, RawTable) if raw then return func(raw, ...) end end

                -- others
                elseif name ~= "__index" and name ~= "__newindex" and name ~= "__ctor" and name ~= "__init" and name ~= "__new" and name ~= "__exist" then
                    _ENV[name]          = function(a, b) return func(simpleparse(a), simpleparse(b)) end
                end
            end

            -- Binding object features
            for name, ftr in Class.GetFeatures(targettype, true) do
                -- gather reactive properties
                if Property.Validate(ftr) and ftr:IsWritable() and ftr:IsReadable() and not ftr:IsIndexer() and Reactive.GetReactiveType(nil, ftr:GetType() or Any, true) then
                    properties[name]    = ftr:GetType() or Any

                -- un-reactive properties
                elseif Property.Validate(ftr) then
                    if Property.IsIndexer(ftr) then
                        __Indexer__(Property.GetIndexType(ftr))
                        property (name) {
                            get         = Property.IsReadable(ftr) and function(self, idx) local raw = rawget(self, RawTable) return raw and raw[name][idx] end,
                            set         = Property.IsWritable(ftr) and function(self, idx, value) local raw = rawget(self, Ratable) if raw then raw[name][idx] = value end end,
                            type        = Property.GetType(ftr),
                        }
                    else
                        property (name) {
                            get         = Property.IsReadable(ftr) and function(self) local raw = rawget(self, RawTable) return raw and raw[name] end,
                            set         = Property.IsWritable(ftr) and function(self, value) local raw = rawget(self, Ratable) if raw then raw[name] = value end end,
                            type        = Property.GetType(ftr),
                        }
                    end

                -- event proxy
                elseif Event.Validate(ftr) then
                    __EventChangeHandler__(function(delegate, owner, name, init)
                        if not init then return end
                        owner[RawTable][name] = owner[RawTable][name] + function(_, ...) delegate(owner, ...) end
                    end)
                    event (ftr:GetName())
                end
            end

        -------------------------------------------------------------------
        --                         member struct                         --
        -------------------------------------------------------------------
        elseif targettype and Struct.Validate(targettype) and Struct.GetStructCategory(targettype) == "MEMBER" then
            properties                  = {}

            for name, mem in Struct.GetMembers(targettype) do
                local mtype             = mem:GetType()

                if Reactive.GetReactiveType(nil, mtype, true) then
                    properties[name]    = mtype

                -- for non-reactive
                else
                    property (name)     {
                        get             = function(self) return self[RawTable][name] end,
                        set             = function(self, value) self[RawTable][name] = value end,
                        type            = mtype
                    }
                end
            end
        end

        -------------------------------------------------------------------
        --                           auto-gen                            --
        -------------------------------------------------------------------
        if properties then
            -- already used
            if properties["Value"] then properties.Value = nil end

            for name, ptype in pairs(properties) do
                local rtype             = Reactive.GetReactiveType(nil, ptype, true)

                property (name)         {
                    -- gets the reactive value
                    get                 = Class.IsSubType(rtype, ReactiveField)
                    and function(self)
                        return self[Reactive][name] or makeReactive(self, name, nil, ptype, rtype)
                    end
                    or function(self)
                        local r         = self[Reactive][name]
                        if r then return r end
                        local d         = self[RawTable][name]
                        return d and makeReactive(self, name, d, ptype, rtype)
                    end,

                    -- sets the value
                    set                 = Class.IsSubType(rtype, ReactiveField)
                    and function(self, value)
                        local r         = self[Reactive][name] or makeReactive(self, name, nil, ptype, rtype)
                        if isobjecttype(value, IReactive) then
                            value       = value.Value
                        end

                        local ok, err   = pcall(setvalue, r, "Value", value)
                        return ok or throw(format(name, err))
                    end
                    or  function(self, value)
                        local r         = self[Reactive][name]

                        if r then
                            -- same
                            if r == value or r.Value == value then return end

                            -- clear
                            self[Reactive][name]= nil
                            releaseReactive(self, r)
                        end

                        -- create or use
                        if value then
                            if isobjecttype(value, IReactive) then
                                self[RawTable][name]= value.Value
                                self[Reactive][name]= value
                                r       = subscribeReactive(self, name, value)
                            else
                                self[RawTable][name]= value
                                r       = makeReactive(self, name, value, ptype, rtype)
                            end
                        end

                        -- notify
                        local sub   = rawget(self, Subject)
                        return sub and sub:OnNext(name, r)
                    end,
                    type                = ptype + rtype,
                    throwable           = true,
                }
            end

            __Iterator__()
            function GetIterator(self)
                local yield             = yield

                for k in pairs(properties) do
                    yield(k, self[k])
                end

                local raw               = self[RawTable]
                for k, v in (raw.GetIterator or pairs)(raw) do
                    if not properties[k] and type(k) == "string" then
                        yield(k, self[k])
                    end
                end
            end
        else
            __Iterator__()
            function GetIterator(self)
                local yield             = yield
                local raw               = self[RawTable]
                for k, v in (raw.GetIterator or pairs)(raw) do
                    if type(k) == "string" then
                        yield(k, self[k])
                    end
                end
            end
        end

        -------------------------------------------------------------------
        --                            method                             --
        -------------------------------------------------------------------
        --- Subscribe the observers
        Subscribe                       = subscribe

        --- Map the items to other type datas, use collection operation instead of observable
        Map                             = IKeyValueDict.Map

        --- Used to filter the items with a check function
        Filter                          = IKeyValueDict.Filter

        -------------------------------------------------------------------
        --                           property                            --
        -------------------------------------------------------------------
        --- Gets/Sets the raw value
        property "Value"                {
            get                         = function(self) return self[RawTable] end,
            set                         = function(self, value)
                if isobjecttype(value, IReactive) then
                    value               = value.Value
                end

                -- update
                local temp              = {}
                for k in self:GetIterator() do
                    temp[k]             = true
                    self[k]             = value[k]
                end

                -- add
                for name in (value.GetIterator or pairs)(value) do
                    if not temp[name] then
                        self[name]      = value[name]
                    end
                end

                -- release
                temp                    = nil
            end,
            type                        = targettype + Reactive[targettype]
        }

        -------------------------------------------------------------------
        --                          constructor                          --
        -------------------------------------------------------------------
        __Arguments__{ targettype or RawTable/nil }
        function __ctor(self, init)
            rawset(self, Reactive, {})          -- sub-reactives
            rawset(self, RawTable, init or {})  -- raw
            if init then setReactiveMap(init, self) end
        end

        __Arguments__{ targettype or RawTable/nil }
        function __exist(_, init)
            return init and getReactiveMap(init) or nil
        end

        -------------------------------------------------------------------
        --                        de-constructor                         --
        -------------------------------------------------------------------4
        function __dtor(self)
            releaseAllSub()

            for k, v in pairs(self[Reactive]) do
                -- only reactive fields will be disposed with the parent
                if v and isobjecttype(v, ReactiveField) then v:Dispose() end
            end

            return clearReactiveMap(self)
        end

        -------------------------------------------------------------------
        --                          meta-method                          --
        -------------------------------------------------------------------
        --- Gets the current value
        function __index(self, key)
            local reactives             = rawget(self, Reactive)
            local r                     = reactives[key]
            if r then return r end

            -- wrap raw
            local value                 = rawget(self, RawTable)[key]
            return r == nil and value ~= nil and type(key) == "string" and makeReactive(self, key, value) or value
        end

        --- Set the new value
        if targettype then
            local keytype, valtype

            -- for Dictionary class
            if Class.Validate(targettype) and Interface.IsSubType(targettype, IKeyValueDict) then
                keytype, valtype        = Class.GetTemplateParameters(targettype)

            -- for Dictionary struct
            elseif Struct.GetStructCategory(targettype) == "DICTIONARY" then
                keytype, valtype        = Struct.GetDictionaryKey(targettype), Struct.GetDictionaryValue(targettype)
            end

            -- Check Platform settings
            if Platform.TYPE_VALIDATION_DISABLED then
                if keytype and keytype ~= Any and getmetatable(keytype).IsImmutable(keytype) then keytype = nil end
                if valtype and valtype ~= Any and getmetatable(valtype).IsImmutable(valtype) then valtype = nil end
            end

            if (keytype and keytype ~= Any) or (valtype and valtype ~= Any) then
                __Arguments__{ keytype or Any, (valtype or Any)/nil }
            end
        end
        function __newindex(self, key, value)
            -- non-scalar value will be saved in self directly
            local tkey                  = type(key)
            if tkey ~= "string" and tkey ~= "number" and tkey ~= "boolean" then return rawset(self, key, value) end

            -- replace with the value
            if isobjecttype(value, IReactive) then
                value                   = value.Value
            elseif isobjecttype(value, IObservable) then
                error("The " .. key .. " can't accept observable value", 2)
            end

            -- check the reactive
            local reactives             = self[Reactive]
            local r                     = reactives[key]
            if r then
                local ok, err           = pcall(setvalue, r, "Value", value)
                if not ok then error(format(key, err), 2) end
                return
            elseif r == false then
                reactives[key]          = nil
            end

            -- check raw
            local raw                   = self[RawTable]
            if raw[key] == value then return end

            -- raw directly
            raw[key]                    = value
            r                           = makeReactive(self, key, value)
            local sub                   = rawget(self, Subject)
            return sub and sub:OnNext(key, r)
        end
    end)

    --- The references used to access reactive table/class field/property datas
    __Sealed__()
    __Arguments__{ AnyType/nil }:WithRebuild()
    __NoNilValue__(false):AsInheritable()
    __NoRawSet__(false):AsInheritable()
    class "System.Reactive"             (function(_ENV, targettype)
        extend "IObservable" "IKeyValueDict" "IReactive"

        export                          {
            type                        = type,
            pairs                       = pairs,
            error                       = error,
            tostring                    = tostring,
            rawget                      = rawget,
            rawset                      = rawset,
            pcall                       = pcall,
            yield                       = coroutine.yield,
            getmetatable                = getmetatable,
            isobjecttype                = Class.IsObjectType,
            issubtype                   = Class.IsSubType,
            properties                  = false,
            setvalue                    = Toolset.setvalue,

            Class, Property, Event, Reactive, ReactiveList, ReactiveField, ReactiveValue, Observable, Subscription, IReactive, IObservable
        }

        -------------------------------------------------------------------
        --                   non-dict class/interface                    --
        -------------------------------------------------------------------
        -- for common types
        if targettype and (Class.Validate(targettype) or Interface.Validate(targettype)) and not Interface.IsSubType(targettype, IKeyValueDict) then
            properties                  = {}

            -- simple parse value
            local simpleparse           = function (val) return type(val) == "table" and rawget(val, RawTable) or val end

            -- Binding object methods
            for name, func, isstatic in Class.GetMethods(targettype, true) do
                if not isstatic then
                    _ENV[name]          = function(self, ...) local raw = rawget(self, RawTable) if raw then return func(raw, ...) end end
                end
            end

            -- Binding meta-methods
            for name, func in Class.GetMetaMethods(targettype, true) do
                -- dispose
                if name == "__gc" then
                    _ENV.__dtor         = function(self) local raw = rawget(self, RawTable) return raw and raw:Dispose() end

                -- single argument
                elseif name == "__unm" or name == "__len" or name == "__tostring" then
                    _ENV[name]          = function(self) local raw = rawget(self, RawTable) return raw and func(raw) end

                -- __call
                elseif name == "__call" or name == "__ipairs" or name == "__pairs" then
                    _ENV[name]          = function(self, ...) local raw = rawget(self, RawTable) if raw then return func(raw, ...) end end

                -- others
                elseif name ~= "__index" and name ~= "__newindex" and name ~= "__ctor" and name ~= "__init" and name ~= "__new" and name ~= "__exist" then
                    _ENV[name]          = function(a, b) return func(simpleparse(a), simpleparse(b)) end
                end
            end

            -- Binding object features
            for name, ftr in Class.GetFeatures(targettype, true) do
                -- gather reactive properties
                if Property.Validate(ftr) and ftr:IsWritable() and ftr:IsReadable() and not ftr:IsIndexer() and Reactive.GetReactiveType(nil, ftr:GetType() or Any, true) then
                    properties[name]    = ftr:GetType() or Any

                -- un-reactive properties
                elseif Property.Validate(ftr) then
                    if Property.IsIndexer(ftr) then
                        __Indexer__(Property.GetIndexType(ftr))
                        property (name) {
                            get         = Property.IsReadable(ftr) and function(self, idx) local raw = rawget(self, RawTable) return raw and raw[name][idx] end,
                            set         = Property.IsWritable(ftr) and function(self, idx, value) local raw = rawget(self, Ratable) if raw then raw[name][idx] = value end end,
                            type        = Property.GetType(ftr),
                        }
                    else
                        property (name) {
                            get         = Property.IsReadable(ftr) and function(self) local raw = rawget(self, RawTable) return raw and raw[name] end,
                            set         = Property.IsWritable(ftr) and function(self, value) local raw = rawget(self, Ratable) if raw then raw[name] = value end end,
                            type        = Property.GetType(ftr),
                        }
                    end

                -- event proxy
                elseif Event.Validate(ftr) then
                    __EventChangeHandler__(function(delegate, owner, name, init)
                        if not init then return end
                        owner[RawTable][name] = owner[RawTable][name] + function(_, ...) delegate(owner, ...) end
                    end)
                    event (ftr:GetName())
                end
            end

        -------------------------------------------------------------------
        --                         member struct                         --
        -------------------------------------------------------------------
        elseif targettype and Struct.Validate(targettype) and Struct.GetStructCategory(targettype) == "MEMBER" then
            properties                  = {}

            for name, mem in Struct.GetMembers(targettype) do
                local mtype             = mem:GetType()

                if Reactive.GetReactiveType(nil, mtype, true) then
                    properties[name]    = mtype

                -- for non-reactive
                else
                    property (name)     {
                        get             = function(self) return self[RawTable][name] end,
                        set             = function(self, value) self[RawTable][name] = value end,
                        type            = mtype
                    }
                end
            end
        end

        -------------------------------------------------------------------
        --                           auto-gen                            --
        -------------------------------------------------------------------
        if properties then
            -- already used
            if properties["Value"] then properties.Value = nil end

            for name, ptype in pairs(properties) do
                local rtype             = Reactive.GetReactiveType(nil, ptype, true)

                property (name)         {
                    -- gets the reactive value
                    get                 = Class.IsSubType(rtype, ReactiveField)
                    and function(self)
                        return self[Reactive][name] or makeReactive(self, name, nil, ptype, rtype)
                    end
                    or function(self)
                        local r         = self[Reactive][name]
                        if r then return r end
                        local d         = self[RawTable][name]
                        return d and makeReactive(self, name, d, ptype, rtype)
                    end,

                    -- sets the value
                    set                 = Class.IsSubType(rtype, ReactiveField)
                    and function(self, value)
                        local r         = self[Reactive][name] or makeReactive(self, name, nil, ptype, rtype)
                        if isobjecttype(value, IReactive) then
                            value       = value.Value
                        end

                        local ok, err   = pcall(setvalue, r, "Value", value)
                        return ok or throw(format(name, err))
                    end
                    or  function(self, value)
                        local r         = self[Reactive][name]

                        if r then
                            -- same
                            if r == value or r.Value == value then return end

                            -- clear
                            self[Reactive][name]= nil
                            releaseReactive(self, r)
                        end

                        -- create or use
                        if value then
                            if isobjecttype(value, IReactive) then
                                self[RawTable][name]= value.Value
                                self[Reactive][name]= value
                                r       = subscribeReactive(self, name, value)
                            else
                                self[RawTable][name]= value
                                r       = makeReactive(self, name, value, ptype, rtype)
                            end
                        end

                        -- notify
                        local sub   = rawget(self, Subject)
                        return sub and sub:OnNext(name, r)
                    end,
                    type                = ptype + rtype,
                    throwable           = true,
                }
            end

            __Iterator__()
            function GetIterator(self)
                local yield             = yield

                for k in pairs(properties) do
                    yield(k, self[k])
                end

                local raw               = self[RawTable]
                for k, v in (raw.GetIterator or pairs)(raw) do
                    if not properties[k] and type(k) == "string" then
                        yield(k, self[k])
                    end
                end
            end
        else
            __Iterator__()
            function GetIterator(self)
                local yield             = yield
                local raw               = self[RawTable]
                for k, v in (raw.GetIterator or pairs)(raw) do
                    if type(k) == "string" then
                        yield(k, self[k])
                    end
                end
            end
        end

        -------------------------------------------------------------------
        --                            method                             --
        -------------------------------------------------------------------
        --- Subscribe the observers
        Subscribe                       = subscribe

        --- Map the items to other type datas, use collection operation instead of observable
        Map                             = IKeyValueDict.Map

        --- Used to filter the items with a check function
        Filter                          = IKeyValueDict.Filter

        -------------------------------------------------------------------
        --                           property                            --
        -------------------------------------------------------------------
        --- Gets/Sets the raw value
        property "Value"                {
            get                         = function(self) return self[RawTable] end,
            set                         = function(self, value)
                if isobjecttype(value, IReactive) then
                    value               = value.Value
                end

                -- update
                local temp              = {}
                for k in self:GetIterator() do
                    temp[k]             = true
                    self[k]             = value[k]
                end

                -- add
                for name in (value.GetIterator or pairs)(value) do
                    if not temp[name] then
                        self[name]      = value[name]
                    end
                end

                -- release
                temp                    = nil
            end,
            type                        = targettype + Reactive[targettype]
        }

        -------------------------------------------------------------------
        --                          constructor                          --
        -------------------------------------------------------------------
        __Arguments__{ targettype or RawTable/nil }
        function __ctor(self, init)
            rawset(self, Reactive, {})          -- sub-reactives
            rawset(self, RawTable, init or {})  -- raw
            if init then setReactiveMap(init, self) end
        end

        __Arguments__{ targettype or RawTable/nil }
        function __exist(_, init)
            return init and getReactiveMap(init) or nil
        end

        -------------------------------------------------------------------
        --                        de-constructor                         --
        -------------------------------------------------------------------4
        function __dtor(self)
            releaseAllSub()

            for k, v in pairs(self[Reactive]) do
                -- only reactive fields will be disposed with the parent
                if v and isobjecttype(v, ReactiveField) then v:Dispose() end
            end

            return clearReactiveMap(self)
        end

        -------------------------------------------------------------------
        --                          meta-method                          --
        -------------------------------------------------------------------
        --- Gets the current value
        function __index(self, key)
            local reactives             = rawget(self, Reactive)
            local r                     = reactives[key]
            if r then return r end

            -- wrap raw
            local value                 = rawget(self, RawTable)[key]
            return r == nil and value ~= nil and type(key) == "string" and makeReactive(self, key, value) or value
        end

        --- Set the new value
        if targettype then
            local keytype, valtype

            -- for Dictionary class
            if Class.Validate(targettype) and Interface.IsSubType(targettype, IKeyValueDict) then
                keytype, valtype        = Class.GetTemplateParameters(targettype)

            -- for Dictionary struct
            elseif Struct.GetStructCategory(targettype) == "DICTIONARY" then
                keytype, valtype        = Struct.GetDictionaryKey(targettype), Struct.GetDictionaryValue(targettype)
            end

            -- Check Platform settings
            if Platform.TYPE_VALIDATION_DISABLED then
                if keytype and keytype ~= Any and getmetatable(keytype).IsImmutable(keytype) then keytype = nil end
                if valtype and valtype ~= Any and getmetatable(valtype).IsImmutable(valtype) then valtype = nil end
            end

            if (keytype and keytype ~= Any) or (valtype and valtype ~= Any) then
                __Arguments__{ keytype or Any, (valtype or Any)/nil }
            end
        end
        function __newindex(self, key, value)
            -- non-scalar value will be saved in self directly
            local tkey                  = type(key)
            if tkey ~= "string" and tkey ~= "number" and tkey ~= "boolean" then return rawset(self, key, value) end

            -- replace with the value
            if isobjecttype(value, IReactive) then
                value                   = value.Value
            elseif isobjecttype(value, IObservable) then
                error("The " .. key .. " can't accept observable value", 2)
            end

            -- check the reactive
            local reactives             = self[Reactive]
            local r                     = reactives[key]
            if r then
                local ok, err           = pcall(setvalue, r, "Value", value)
                if not ok then error(format(key, err), 2) end
                return
            elseif r == false then
                reactives[key]          = nil
            end

            -- check raw
            local raw                   = self[RawTable]
            if raw[key] == value then return end

            -- raw directly
            raw[key]                    = value
            r                           = makeReactive(self, key, value)
            local sub                   = rawget(self, Subject)
            return sub and sub:OnNext(key, r)
        end
    end)
end)