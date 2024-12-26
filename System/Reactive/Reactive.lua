--===========================================================================--
--                                                                           --
--                              System.Reactive                              --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2023/04/20                                               --
-- Update Date  :   2024/12/04                                               --
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
        class "ReactiveDictionary"      {}
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
            isstructtype                = Struct.IsSubType,
            getstructcategory           = Struct.GetStructCategory,
            getarrayelement             = Struct.GetArrayElement,
            getdictionarykey            = Struct.GetDictionaryKey,
            getdictionaryval            = Struct.GetDictionaryValue,
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

                elseif cate == "DICTIONARY" then                    
                    return ReactiveDictionary[{ getdictionarykey(targettype) or Any, getdictionaryval(targettype) or Any }]

                elseif cate == "MEMBER" then
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
                        local k, v      = gettempparams(metatype)
                        return ReactiveDictionary[{ k or Any, v or Any }]
                    end

                -- common class
                else
                    return Reactive[metatype]
                end
            end
        end
    end)

    -----------------------------------------------------------------------
    --                              keyword                              --
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
        isobjecttype                    = Class.IsObjectType,
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

    -- subscribe the children
    local subscribeReactive             = function(self, k, r)
        local subject                   = rawget(self, Subject)
        if r and subject and not rawget(subject, r) then
            rawset(subject, r, (r:Subscribe(
                function(...) return onObjectNext (self.Value, k, ...) end,
                function(ex)  return onObjectError(self.Value, ex) end)
            ))
        end
        return r
    end

    -- release the children
    local releaseReactive               = function(self, r)
        local subject                   = rawget(self, Subject)
        local subscription              = r and subject and rawget(subject, r)
        if subscription then
            rawset(subject, r, nil)
            return subscription:Dispose()
        end
    end

    -- wrap the table value as default
    local makeReactive                  = function(self, k, v, type, rtype)
        rtype                           = rtype or getreactivetype(v, type, true)
        local r                         = rtype and (issubtype(rtype, ReactiveField) and rtype(self.Value, k) or rtype(v))
        self[Reactive][k]               = r or false
        return r and subscribeReactive(self, k, r)
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
    class "System.Reactive"             (function(_ENV, targettype)
        extend "IObservable" "IReactive"

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
            getobjectclass              = Class.GetObjectClass,
            gettempparams               = Class.GetTemplateParameters,
            properties                  = false,
            setvalue                    = Toolset.setvalue,
            fakefunc                    = Toolset.fakefunc,

            Reactive, ReactiveField, IReactive, IObservable
        }

        -- switch object value
        local switchObject

        -------------------------------------------------------------------
        --                   non-dict class/interface                    --
        -------------------------------------------------------------------
        -- for common types
        if targettype and (Class.Validate(targettype) or Interface.Validate(targettype)) and not Interface.IsSubType(targettype, IKeyValueDict) then
            properties                  = {}

            -- simple parse value
            local simpleparse           = function (val) if isobjecttype(val, IReactive) then return val.Value else return val end end

            -- Binding object methods
            for name, func, isstatic in Class.GetMethods(targettype, true) do
                if not isstatic then
                    _ENV[name]          = function(self, ...)   local raw = self.Value if raw then return func(raw, ...) end end
                end
            end

            -- Binding meta-methods
            for name, func in Class.GetMetaMethods(targettype, true) do
                -- dispose
                if name == "__gc" then
                    _ENV.__dtor         = function(self)        local raw = self.Value if raw then return raw:Dispose() end end

                -- single argument
                elseif name == "__unm" or name == "__len" or name == "__tostring" then
                    _ENV[name]          = function(self)        local raw = self.Value if raw then return func(raw) end end

                -- __call
                elseif name == "__call" then
                    _ENV[name]          = function(self, ...)   local raw = self.Value if raw then return func(raw, ...) end end

                elseif name == "__ipairs" or name == "__pairs" then
                    _ENV[name]          = function(self, ...)   local raw = self.Value if raw then return func(raw, ...) else return fakefunc, self end end

                -- others
                elseif name ~= "__index" and name ~= "__newindex" and name ~= "__ctor" and name ~= "__init" and name ~= "__new" and name ~= "__exist" then
                    _ENV[name]          = function(a, b)        return func(simpleparse(a), simpleparse(b)) end
                end
            end

            -- Binding object features
            for name, ftr in Class.GetFeatures(targettype, true) do
                -- now only support properties
                if Property.Validate(ftr) then
                    -- gather reactive properties
                    if ftr:IsWritable() and ftr:IsReadable() and not ftr:IsIndexer() and Reactive.GetReactiveType(nil, ftr:GetType() or Any, true) then
                        properties[name]= ftr:GetType() or Any

                    -- un-reactive properties
                    else
                        if ftr:IsIndexer() then
                            __Indexer__(ftr:GetIndexType())
                            property (name) {
                                get     = ftr:IsReadable() and function(self, i)    local raw = self.Value if raw then return raw[name][i] end end,
                                set     = ftr:IsWritable() and function(self, i, v) local raw = self.Value if raw then raw[name][i] = v    end end,
                                type    = ftr:GetType(),
                            }
                        else
                            property (name) {
                                get     = ftr:IsReadable() and function(self)       local raw = self.Value if raw then return raw[name]    end end,
                                set     = ftr:IsWritable() and function(self, v)    local raw = self.Value if raw then raw[name] = v       end end,
                                type    = ftr:GetType(),
                            }
                        end
                    end
                end
            end

            -- switch value
            switchObject                = function (self, new, clear)
                -- switch for reactive fields
                local reactives         = self[Reactive]
                local subject           = rawget(self, Subject)

                -- for properties
                for k in pairs(properties) do
                    local r             = reactives[k]

                    if clear and r then
                        if isobjecttype(r, ReactiveField) then
                            -- update
                            r.Container = new
                        else
                            -- release
                            releaseReactive(self, r)
                            reactives[k]= nil

                            r           = new and self[k]
                        end
                    elseif subject then
                        -- generate & subscribe
                        if r then
                            subscribeReactive(self, k, r)
                        else
                            r           = new and self[k]
                        end
                    end
                end

                -- subscribe
                if not subject then return end
                subject.Observable      = new and getObjectSubject(new) or nil
                if clear then return subject:OnNext(nil) end
            end

        -------------------------------------------------------------------
        --                  dict class/interface/struct                  --
        -------------------------------------------------------------------
        elseif targettype and (Interface.IsSubType(targettype, IKeyValueDict) or Struct.GetStructCategory(targettype) == "DICTIONARY") then
            

        -------------------------------------------------------------------
        --                         member struct                         --
        -------------------------------------------------------------------
        elseif targettype and Struct.Validate(targettype) and Struct.GetStructCategory(targettype) == "MEMBER" then
            properties                  = {}

            -- Binding object methods
            for name, func, isstatic in Struct.GetMethods(targettype, true) do
                if not isstatic then
                    _ENV[name]          = function(self, ...) local raw = self.Value if raw then return func(raw, ...) end end
                end
            end

            for name, mem in Struct.GetMembers(targettype) do
                local mtype             = mem:GetType()

                if Reactive.GetReactiveType(nil, mtype, true) then
                    properties[name]    = mtype

                -- for non-reactive
                else
                    property (name)     {
                        get             = function(self)    local raw = self.Value if raw then return raw[name] end end,
                        set             = function(self, v) local raw = self.Value if raw then raw[name] = v    end end,
                        type            = mtype
                    }
                end
            end

            -- switch value
            switchObject                = function (self, new, clear)
                -- switch for reactive fields
                local reactives         = self[Reactive]
                local subject           = rawget(self, Subject)

                -- for properties
                for k in pairs(properties) do
                    local r             = reactives[k]

                    if clear and r then
                        if isobjecttype(r, ReactiveField) then
                            -- update
                            r.Container = new
                        else
                            -- release
                            releaseReactive(self, r)
                            reactives[k]= nil

                            r           = new and self[k]
                        end
                    elseif subject then
                        -- generate & subscribe
                        if r then
                            subscribeReactive(self, k, r)
                        else
                            r           = new and self[k]
                        end
                    end
                end

                -- clear
                if clear then
                    for k, r in pairs(reactives) do
                        if not properties[k] then
                            if r then 
                                releaseReactive(self, r) 
                                if isobjecttype(r, ReactiveField) then
                                    r:Dispose()
                                end
                            end
                            reactives[k]= nil
                        end
                    end
                end

                -- subscribe other fields
                if new then
                    for k, v in pairs(new) do
                        if not properties[k] and type(k) == "string" then
                            local r     = reactives[k]
                            if r then
                                subscribeReactive(self, k, r)
                            else
                                r       = self[k]
                            end
                        end
                    end
                end

                -- subscribe
                if not subject then return end
                subject.Observable      = new and getObjectSubject(new) or nil
                if clear then return subject:OnNext(nil) end
            end

        -------------------------------------------------------------------
        --                            default                            --
        -------------------------------------------------------------------
        elseif not targettype then
            -- switch value
            switchObject                = function (self, new, clear)
                -- switch for reactive fields
                local reactives         = self[Reactive]
                local subject           = rawget(self, Subject)

                -- clear
                if clear then
                    for k, r in pairs(reactives) do
                        if r then 
                            releaseReactive(self, r) 
                            if isobjecttype(r, ReactiveField) then
                                r:Dispose()
                            end
                        end
                        reactives[k]    = nil
                    end
                end

                -- subscribe other fields
                if new then
                    for k, v in pairs(new) do
                        if not properties[k] and type(k) == "string" then
                            local r     = reactives[k]
                            if r then
                                subscribeReactive(self, k, r)
                            else
                                r       = self[k]
                            end
                        end
                    end
                end

                -- subscribe
                if not subject then return end
                subject.Observable      = new and getObjectSubject(new) or nil
                if clear then return subject:OnNext(nil) end
            end
        end

        -------------------------------------------------------------------
        --                           auto-gen                            --
        -------------------------------------------------------------------
        if properties then
            -- No Value property allowed
            if properties["Value"]      then properties.Value = nil end

            -- Generate the reactive properties
            for name, ptype in pairs(properties) do
                local rtype             = Reactive.GetReactiveType(nil, ptype, true)

                if Class.IsSubType(rtype, ReactiveField) then
                    property (name)     {
                        -- gets the reactive value
                        get             = function(self) return self[Reactive][name] or makeReactive(self, name, nil, ptype, rtype) end,

                        -- sets the value
                        set             = function(self, value)
                            local r     = self[Reactive][name] or makeReactive(self, name, nil, ptype, rtype)
                            local type  = value and getobjectclass(value)

                            -- take reactive value
                            if type and issubtype(type, IReactive) then
                                value   = value.Value

                            -- subscribe the observable
                            elseif type and issubtype(type, IObservable) then
                                r.Observable = value
                                return
                            end

                            r.Observable= nil

                            local ok, e = pcall(setvalue, r, "Value", value)
                            return ok or throw(format(name, e))
                        end,
                        type            = ptype + rtype + IObservable,
                        throwable       = true,
                    }
                else
                    property (name)     {
                        -- gets the reactive value
                        get             = function(self)
                            local r     = self[Reactive][name]
                            if r then return r end

                            -- Check if existed
                            local raw   = self.Value
                            local d     = raw and raw[name]
                            return d and makeReactive(self, name, d, ptype, rtype)
                        end,

                        -- sets the value
                        set             = function(self, value)
                            local r     = self[Reactive][name]
                            if isobjecttype(value, IReactive) then
                                value   = value.Value
                            end

                            if r then
                                -- compare
                                if r.Value == value then return end

                                -- clear
                                self[Reactive][name] = nil
                                releaseReactive(self, r)
                            end

                            -- new
                            local raw   = self.Value
                            if not raw then throw("the raw object is not specified") end

                            raw[name]   = value
                            if value then
                                r       = makeReactive(self, name, value, ptype, rtype)
                            else
                                r       =  nil
                            end

                            -- only send it in this node
                            local sub   = rawget(self, Subject)
                            return sub and sub:OnNext(name, r)
                        end,
                        type            = ptype + rtype,
                        throwable       = true,
                    }
                end
            end
        end

        -------------------------------------------------------------------
        --                            method                             --
        -------------------------------------------------------------------
        --- Subscribe the observers
        function Subscribe(self, ...)                
            local subject               = rawget(self, Subject)
            if not subject then
                subject                 = Subject()
                rawset(self, Subject, subject)

                -- for children
                switchObject(self, self.Value, false)
            end

            -- subscribe
            local ok, sub, obs          = pcall(subject.Subscribe, subject, ...)
            if not ok then error("Usage: reactive:Subscribe(IObserver[, Subscription]) - the argument not valid", 2) end

            return sub, obs
        end

        -------------------------------------------------------------------
        --                           property                            --
        -------------------------------------------------------------------
        --- Gets/Sets the raw value
        property "Value"                {
            field                       = RawTable,
            set                         = function(self, value)
                if value and isobjecttype(value, IReactive) then
                    value               = value.Value
                end
                local old               = rawget(self, RawTable)
                if value == old then return end

                rawset(self, RawTable, value)
                return switchObject(self, value, true)
            end,
            type                        = targettype and targettype ~= Any and (targettype + Reactive[targettype]) or RawTable
        }

        -------------------------------------------------------------------
        --                          constructor                          --
        -------------------------------------------------------------------
        __Arguments__{ targettype or (RawTable/nil) }
        function __ctor(self, init)
            rawset(self, Reactive, {})          -- sub-reactives
            rawset(self, RawTable, init or {})  -- raw
        end

        -------------------------------------------------------------------
        --                        de-constructor                         --
        -------------------------------------------------------------------
        function __dtor(self)
            local subject               = rawget(self, Subject)

            for k, v in pairs(self[Reactive]) do
                if v then
                    local subscription  = subject and rawget(subject, v)
                    if subscription then
                        rawset(subject, v, nil)
                        subscription:Dispose()
                    end

                    -- only reactive fields will be disposed with the parent
                    if isobjecttype(v, ReactiveField) then v:Dispose() end
                end
            end

            return subject and subject:Dispose()
        end

        -------------------------------------------------------------------
        --                          meta-method                          --
        -------------------------------------------------------------------
        if properties then
            -- objects may have its private fields, block those access
            function __newindex(self, key, value, stack)
                error("The " .. key .. " can't be written", (stack or 1) + 1)
            end
        else
            --- Gets the current value
            function __index(self, key, stack)
                local reactives         = rawget(self, Reactive)
                local r                 = reactives[key]
                if r                        then return r end

                -- make field reactive
                local raw               = rawget(self, RawTable)
                if not reactives        then error("The reactive is disposed", (stack or 1) + 1) end
                if not raw              then error("The raw is not specified", (stack or 1) + 1) end
                local value             = raw[key]
                return r == nil and value ~= nil and type(key) == "string" and makeReactive(self, key, value) or value
            end

            --- Set the new value
            if targettype then
                local keytype, valtype

                -- for Dictionary class
                if Class.Validate(targettype) and Interface.IsSubType(targettype, IKeyValueDict) then
                    keytype, valtype    = Class.GetTemplateParameters(targettype)

                -- for Dictionary struct
                elseif Struct.GetStructCategory(targettype) == "DICTIONARY" then
                    keytype, valtype    = Struct.GetDictionaryKey(targettype), Struct.GetDictionaryValue(targettype)
                end

                -- Check Platform settings
                if Platform.TYPE_VALIDATION_DISABLED then
                    if keytype and keytype ~= Any and getmetatable(keytype).IsImmutable(keytype) then keytype = nil end
                    if valtype and valtype ~= Any and getmetatable(valtype).IsImmutable(valtype) then valtype = nil end
                end

                if (keytype and keytype ~= Any) or (valtype and valtype ~= Any) then
                    __Arguments__{ keytype or Any, (valtype or Any)/nil, Integer/nil }
                end
            end
            function __newindex(self, key, value, stack)
                -- non-string value will be saved in self directly
                if type(key)~= "string" then return rawset(self, key, value) end
                stack                   = (stack or 1) + 1

                local reactives         = rawget(self, Reactive)
                local raw               = rawget(self, RawTable)
                if not reactives        then error("The reactive is disposed", stack) end
                if not raw              then error("The raw object is not specified", stack) end

                local r                 = reactives[key]

                -- object value checker
                if type(value) == "table" then
                    -- replace with the value
                    if isobjecttype(value, IReactive) then
                        value           = value.Value

                    -- check the reactive
                    elseif isobjecttype(value, IObservable) then
                        -- check exists
                        if r then
                            if isobjecttype(r, ReactiveField) then
                                r.Observable= value
                            else
                                error("The " .. key .. " can't accept observable value", stack)
                            end

                        -- create
                        else
                            if raw[key] == nil then
                                -- type unknown
                                r       = makeReactive(self, key, nil, Any, ReactiveField)
                            else
                                r       = makeReactive(self, key, raw[key])

                                if not isobjecttype(r, ReactiveField) then
                                    error("The " .. key .. " can't accept observable value", stack)
                                end
                            end

                            r.Observable= value
                        end
                        return
                    end
                end

                -- Compare
                if raw[key] == value    then return end

                -- raw value
                if value ~= nil then
                    if r == nil and raw[key] ~= nil then
                        r               = makeReactive(self, key, raw[key])
                    end

                    if r ~= nil then
                        if isobjecttype(r, ReactiveField) then
                            local ok, e = pcall(setvalue, r, "Value", value)
                            if not ok   then error(format(key, e), stack) end
                        else
                            -- clear
                            reactives[key]  = nil
                            releaseReactive(self, r)

                            -- new
                            raw[key]    = value
                            r           = makeReactive(self, key, value, ptype, rtype)

                            -- only send it in this node
                            local sub   = rawget(self, Subject)
                            return sub and sub:OnNext(key, r)
                        end
                    else
                        -- Generate
                        raw[key] = value
                        r               = makeReactive(self, key, value)

                        local sub       = rawget(self, Subject)
                        return sub and sub:OnNext(key, r)
                    end

                -- clear
                else
                    if r ~= nil then
                        if isobjecttype(r, ReactiveField) then
                            local ok, e = pcall(setvalue, r, "Value", nil)
                            if not ok   then error(format(key, e), stack) end
                        else
                            -- release the reactive object
                            raw[key]    = nil
                            reactives[key] = nil
                            releaseReactive(self, r)

                            local sub   = rawget(self, Subject)
                            return sub and sub:OnNext(key, nil)
                        end
                    end
                end
            end
        end
    end)
end)