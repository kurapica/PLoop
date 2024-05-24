--===========================================================================--
--                                                                           --
--                              System.Reactive                              --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2023/04/20                                               --
-- Update Date  :   2024/05/09                                               --
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
        class "__Observable__"          {}
        class "Observable"              {}
        class "ReactiveValue"           {}
        class "ReactiveField"           {}
        class "ReactiveList"            {}
        class "Watch"                   (function(_ENV)
            class "ReactiveProxy"       {}
            class "ReactiveListProxy"   {}
        end)

        -------------------------------------------------------------------
        --                            export                             --
        -------------------------------------------------------------------
        export                          {
            pcall                       = pcall,
            pairs                       = pairs,
            type                        = type,
            error                       = error,
            tostring                    = tostring,
            getmetatable                = getmetatable,
            issubtype                   = Class.IsSubType,
            isvaluetype                 = Class.IsValueType,
            isobjecttype                = Class.IsObjectType,
            getobjectclass              = Class.GetObjectClass,
            gettempparams               = Class.GetTemplateParameters,
            isclass                     = Class.Validate,
            getsuperclass               = Class.GetSuperClass,
            isinterface                 = Interface.Validate,
            isenum                      = Enum.Validate,
            isstruct                    = Struct.Validate,
            getstructcategory           = Struct.GetStructCategory,
            getarrayelement             = Struct.GetArrayElement,
            clone                       = Toolset.clone,
            setvalue                    = Toolset.setvalue,
            isarray                     = Toolset.isarray,

            updateTable                 = function(self, value)
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

            raise                       = function(err, stack)
                error("Usage: Reactive.SetRaw(reactive, value[, stack]) - " .. tostring(err), stack + 1)
            end,

            IList, IIndexedList, IDictionary, IKeyValueDict, IObservable,
            Any, Number, String, Boolean, RawTable, List, Reactive,
            Watch.ReactiveProxy, Watch.ReactiveListProxy
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
            local rtype
            if metatype == nil then
                rtype                   = valtype == "table" and (isarray(value) and ReactiveList or Reactive) or nil

            elseif metatype == Any then
                rtype                   = asfield and ReactiveField or ReactiveValue

            elseif isenum(metatype) then
                rtype                   = asfield and ReactiveField[metatype] or ReactiveValue[metatype]

            elseif isstruct(metatype) then
                local cate              = getstructcategory(metatype)

                if cate == "CUSTOM" then
                    rtype               = asfield and ReactiveField[metatype] or ReactiveValue[metatype]

                elseif cate == "ARRAY" then
                    local element       = getarrayelement(metatype)
                    rtype               = element and ReactiveList[element] or ReactiveList

                -- member or dict
                else
                    rtype               = Reactive[metatype]
                end

            elseif isclass(metatype) then
                -- already reactive
                if  issubtype(metatype, Reactive) or
                    issubtype(metatype, ReactiveList) or
                    issubtype(metatype, ReactiveField) or
                    issubtype(metatype, ReactiveValue) or
                    issubtype(metatype, ReactiveProxy) or
                    issubtype(metatype, ReactiveListProxy) then
                    rtype               = nil

                -- observable as value queue
                elseif issubtype(metatype, IObservable) then
                    rtype               = ReactiveValue

                -- if is value type like Date
                elseif isvaluetype(metatype) then
                    rtype               = asfield and ReactiveField[metatype] or ReactiveValue[metatype]

                -- wrap list or array to reactive list
                elseif issubtype(metatype, IList) then
                    -- to complex to cover more list types, only List for now
                    if issubtype(metatype, List) then
                        local ele       = gettempparams(metatype)
                        rtype           = ele and ReactiveList[ele] or ReactiveList
                    end

                -- wrap dictionary
                elseif issubtype(metatype, IDictionary) then
                    -- only key-value dict support
                    if issubtype(metatype, IKeyValueDict) then
                        rtype           = Reactive[metatype]
                    end

                -- common class
                else
                    rtype               = Reactive[metatype]
                end
            end

            return rtype
        end
    end)

    -----------------------------------------------------------------------
    --                          implementation                           --
    -----------------------------------------------------------------------
    --- The proxy used to access reactive table/class field/property datas
    __Sealed__()
    __Arguments__{ AnyType/nil }:WithRebuild()
    __NoNilValue__(false):AsInheritable()
    __NoRawSet__(false):AsInheritable()
    class "System.Reactive"             (function(_ENV, targettype)
        extend "IObservable" "IKeyValueDict"

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
            getdelegate                 = Event.Get,
            clone                       = Toolset.clone,
            toraw                       = Reactive.ToRaw,
            setraw                      = Reactive.SetRaw,
            setrawlist                  = ReactiveList.SetRaw,

            -- bind data change event handler when accessed
            binddatachange              = function(self, k, r)
                if r and getdelegate(OnDataChange, self, true) then
                    if isobjecttype(r, Reactive) or isobjecttype(r, ReactiveList) then
                        r.OnDataChange  = r.OnDataChange + function(_, ...) return OnDataChange(self, k, ...) end
                    else
                        -- Reactive Field or Reactive Value
                        local sub       = rawget(self, Subscription)
                        if not sub then
                            sub         = Subscription()
                            rawset(self, Subscription, sub)
                        end
                        r:Subscribe(function(val) return OnDataChange(self, k, val) end, nil, nil, sub)
                    end
                end
                return r
            end,

            -- wrap the table value as default
            makereactive                = function(self, k, v, type, rtype)
                rtype                   = rtype or Reactive.GetReactiveType(v, type, true)
                local r                 = rtype and (issubtype(rtype, ReactiveField) and rtype(self, k) or rtype(v))
                self[Reactive][k]       = r or false
                return r and binddatachange(self, k, r)
            end,

            Class, Property, Event, Reactive, ReactiveList, ReactiveField, ReactiveValue, Observable, Subscription
        }

        -------------------------------------------------------------------
        --                             event                             --
        -------------------------------------------------------------------
        --- Fired when the data changed
        __EventChangeHandler__(function(_, owner, _, init)
            if not init then return end
            for k, r in pairs(owner[Reactive]) do binddatachange(owner, k, r) end
        end)
        event "OnDataChange"

        -------------------------------------------------------------------
        --                   non-dict class/interface                    --
        -------------------------------------------------------------------
        if targettype and (Class.Validate(targettype) or Interface.Validate(targettype)) and not Interface.IsSubType(targettype, IKeyValueDict) then
            properties                  = {}

            -- simple parse value, use local so it'll be removed when no use
            local function simpleparse(val)
                return type(val) == "table" and rawget(val, RawTable) or val
            end

            -- handle the function call
            local function handlecall(self, ...)
                -- refresh reactive object data
                local reactives         = self[Reactive]
                for name in pairs(properties) do
                    local r             = reactives[name]
                    if r then r:Refresh() end
                end
                return ...
            end

            -- wrap the target function
            local wrapmethod            = function(name, func)
                -- __Async__
                local original, safe    = __Async__.GetOriginal(func)
                if original then
                    __Async__(safe)

                -- __Iterator__
                else
                    original            = __Iterator__.GetOriginal(func)
                    if original then
                        __Iterator__()

                    -- Normal
                    else
                        original        = func
                    end
                end

                _ENV[name]              = function(self, ...)
                    local raw           = rawget(self, RawTable)
                    if not raw then return end
                    return handlecall(self, original(raw, ...))
                end
            end

            -- Binding object methods
            for name, func, isstatic in Class.GetMethods(targettype, true) do
                if not isstatic then    wrapmethod(name, func) end
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
                    wrapmethod(name, func)

                -- others
                elseif name ~= "__index" and name ~= "__newindex" and name ~= "__ctor" and name ~= "__init" and name ~= "__new" and name ~= "__exist" then
                    _ENV[name]          = function(a, b) return func(simpleparse(a), simpleparse(b)) end
                end
            end

            -- Binding object features
            for _, ftr in Class.GetFeatures(targettype, true) do
                -- read/write non-indexer properties
                if Property.Validate(ftr) and ftr:IsWritable() and ftr:IsReadable() and not ftr:IsIndexer() then
                    local name          = ftr:GetName()
                    local ptype         = ftr:GetType() or Any
                    local rtype         = Reactive.GetReactiveType(nil, ptype, true)

                    if rtype then
                        properties[name]= rtype

                        -- define the reactive property as proxy
                        property (name) {
                            get         = function(self) return self[Reactive][name] or makereactive(self, name, self[RawTable] and self[RawTable][name], nil, rtype) end,
                            set         = function(self, value) return self[name]:SetRaw(value) end,
                        }

                    -- for non-reactive
                    else
                        property (name) {
                            get         = function(self) local raw = rawget(self, RawTable) return raw and raw[name] end,
                            set         = function(self, value) local raw = rawget(self, Ratable) if raw then raw[name] = value end end,
                            type        = ptype
                        }
                    end
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

            -- implementation
            __Iterator__()
            function GetIterator(self)
                local yield                 = yield

                for k in pairs(properties) do
                    yield(k, self[k])
                end

                for k, v in pairs(self[Reactive]) do
                    if not properties[k] then
                        yield(k, v)
                    end
                end
            end

            -- clear
            wrapmethod                  = nil

        -------------------------------------------------------------------
        --                         member struct                         --
        -------------------------------------------------------------------
        elseif targettype and Struct.Validate(targettype) and Struct.GetStructCategory(targettype) == "MEMBER" then
            properties                  = {}

            for _, mem in Struct.GetMembers(targettype) do
                local name              = mem:GetName()
                local mtype             = mem:GetType()
                local rtype             = Reactive.GetReactiveType(nil, mtype)

                if rtype then
                    properties[name]   = true
                    property (name)    {
                        -- gets the reactive
                        get             = Class.IsSubType(rtype, ReactiveField)
                        and function(self)
                            return self[Reactive][name] or makereactive(self, name, nil, nil, rtype)
                        end
                        or function(self)
                            local r     = self[Reactive][name]
                            if r    then return r end
                            local d     = self[RawTable][name]
                            return d and makereactive(self, name, d, mtype)
                        end,

                        -- sets the value
                        set             = Class.IsSubType(rtype, ReactiveField)
                        and function(self, value)
                            -- allow binding observable like watch to the property
                            local s     = self[name]
                            if value and isobjecttype(value, IObservable) then
                                s.Observable = value
                            else
                                s.Observable = nil
                                return s:OnNext(value)
                            end
                        end
                        or Class.IsSubType(rtype, ReactiveList)
                        and function(self, value)
                            local r     = self[Reactive][name]
                            if r        then return setrawlist(r, value, true) end
                            value       = toraw(value, true)
                            self[RawTable][name] = value
                            return OnDataChange(self, name, makereactive(self, name, value, mtype))
                        end
                        or function(self, value)
                            local r     = self[Reactive][name]
                            if r        then return setraw(r, value, 2) end
                            value       = toraw(value, true)
                            self[RawTable][name] = value
                            return OnDataChange(self, name, makereactive(self, name, value, mtype))
                        end,
                        type            = Class.IsSubType(rtype, ReactiveField) and (mtype + IObservable) or (mtype + rtype),
                        throwable       = true,
                    }

                -- for non-reactive
                else
                    property (name)    {
                        get             = function(self) return self[RawTable][name] end,
                        set             = function(self, value) self[RawTable][name] = value end,
                        type            = mtype
                    }
                end
            end

            __Iterator__()
            function GetIterator(self)
                local yield                 = yield

                for k in pairs(properties) do
                    yield(k, self[k])
                end

                for k, v in pairs(self[RawTable]) do
                    if not properties[k] and type(k) == "string" then
                        yield(k, self[k])
                    end
                end
            end

        -------------------------------------------------------------------
        --                             dict                              --
        -------------------------------------------------------------------
        else
            __Iterator__()
            function GetIterator(self)
                local yield                 = yield
                local raw                   = self[RawTable]
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
        function Subscribe(self, ...)   return Observable.From(self.OnDataChange):Subscribe(...) end

        --- Gets the raw value
        function GetRaw(self)           return rawget(self, RawTable) end

        --- Map the items to other type datas, use collection operation instead of observable
        Map                             = IKeyValueDict.Map

        --- Used to filter the items with a check function
        Filter                          = IKeyValueDict.Filter

        -------------------------------------------------------------------
        --                          constructor                          --
        -------------------------------------------------------------------
        __Arguments__{ (targettype or RawTable)/nil }
        function __ctor(self, init)
            rawset(self, Reactive, {})
            rawset(self, RawTable, init)
        end

        -------------------------------------------------------------------
        --                        de-constructor                         --
        -------------------------------------------------------------------4
        function __dtor(self)
            local reactives             = rawget(self, Reactive)
            local subscription          = rawget(self, Subscription)
            if subscription then subscription:Dispose() end

            for k, v in pairs(reactives) do
                if v then v:Dispose() end
            end
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
            return r == nil and value ~= nil and type(key) == "string" and makereactive(self, key, value) or value
        end

        --- Send the new value
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
            -- not work for non-string key
            if type(key) ~= "string" then
                rawset(self, key, value)
                return
            end

            -- check raw
            local raw                   = self[RawTable]
            if raw[key] == value then return end

            -- check the reactive
            local reactives             = self[Reactive]
            local r                     = reactives[key]
            if r then
                setraw(r, value, 2)
                return
            elseif r == false then
                reactives[key]          = nil
            end

            -- raw directly
            if isobjecttype(value, IObservable) then
                local vtype             = getmetatable(value)
                r                       = makereactive(self, key, nil, nil, isobjecttype(vtype, ReactiveField) and vtype or ReactiveField)
                r.Observable            = value
            else
                value                   = toraw(value, true)
                raw[key]                = value
                r                       = makereactive(self, key, value)
                return r and OnDataChange(self, key, not isobjecttype(r, ReactiveField) and r or value)
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
        isclass                         = Class.Validate,
        issubtype                       = Class.IsSubType,
        getobjectclass                  = Class.GetObjectClass,
        getreactivetype                 = System.Reactive.GetReactiveType,
        istructvalue                    = Struct.ValidateValue,

        Reactive, ReactiveList, ReactiveField, Any, Attribute, AnyType
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
end)