--===========================================================================--
--                                                                           --
--                              System.Reactive                              --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2023/04/20                                               --
-- Update Date  :   2025/02/22                                               --
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
            extend "IObservable"

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
            next                        = next,
            getmetatable                = getmetatable,
            issubtype                   = Class.IsSubType,
            isvaluetype                 = Class.IsValueType,
            isvaluestruct               = Struct.IsValueType,
            getobjectclass              = Class.GetObjectClass,
            gettempparams               = Class.GetTemplateParameters,
            isclass                     = Class.Validate,
            getsuperclass               = Class.GetSuperClass,
            isenum                      = Enum.Validate,
            isstruct                    = Struct.Validate,
            isstructtype                = Struct.IsSubType,
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
                return valtype == "table" and (next(value) ~= nil and isarray(value) and ReactiveList or Reactive) or nil

            elseif metatype == Any then
                return asfield and ReactiveField or ReactiveValue

            elseif isenum(metatype) then
                return asfield and ReactiveField[metatype] or ReactiveValue[metatype]

            elseif isstruct(metatype) then
                if isvaluestruct(metatype) then
                    return asfield and ReactiveField[metatype] or ReactiveValue[metatype]
                end

                local cate              = getstructcategory(metatype)

                if cate == "CUSTOM" then
                    return asfield and ReactiveField[metatype] or ReactiveValue[metatype]

                elseif cate == "ARRAY" then
                    local element       = getarrayelement(metatype)
                    return element and ReactiveList[element] or ReactiveList

                elseif cate == "DICTIONARY" then                    
                    return ReactiveDictionary[metatype]

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
                        return ReactiveDictionary[metatype]
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
                if value == nil then
                    if recommendtype == nil then return Reactive() end
                    if not silent then  error("Usage: reactive[type](object[, silent]) - the data object is not provided", (stack or 1) + 1) end
                    return
                end

                -- return reactive object clone
                if isobjecttype(value, IReactive) then return isobjecttype(value, ReactiveField) and value or value.Value and getobjectclass(value)(value.Value) or value end

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
                function(ex)  return onObjectError(self.Value, ex) end
            )))
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
        extend "IReactive"

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
            safesetvalue                = Toolset.safesetvalue,
            fakefunc                    = Toolset.fakefunc,
            applyfuncattr               = Toolset.applyfuncattr,
            properties                  = targettype and {} or nil,
            switchObject                = targettype and function (self, new, clear)
                -- switch for reactive fields
                local reactives         = rawget(self, Reactive)
                if not reactives then return end
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
            end or nil,

            Reactive, ReactiveField, IReactive, IObservable, Subject
        }

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

            rawset(self, RawTable, nil)
            rawset(self, Reactive, nil)
            return subject and subject:Dispose()
        end

        -------------------------------------------------------------------
        --                  reactive container(Default)                  --
        -------------------------------------------------------------------
        if not targettype then
            export                      {
                subscribeReactiveSimple = function(self, k, r)
                    local subject       = rawget(self, Subject)
                    if r and subject and not rawget(subject, r) then
                        rawset(subject, r, (r:Subscribe(
                            function(...) return subject:OnNext(k, ...) end,
                            function(ex)  return subject:OnError(ex) end
                        )))
                    end
                end
            }


            -------------------------------------------------------------------
            --                            method                             --
            -------------------------------------------------------------------
            --- Subscribe the observers
            function Subscribe(self, ...)
                -- lazy loading
                local subject           = rawget(self, Subject)
                if not subject then
                    subject             = Subject()
                    rawset(self, Subject, subject)

                    for k, v in pairs(self[Reactive]) do
                        subscribeReactiveSimple(self, k, v)
                    end
                end

                -- subscribe
                local ok, sub, obs      = pcall(subject.Subscribe, subject, ...)
                if not ok then error("Usage: reactive:Subscribe(IObserver[, Subscription]) - the argument not valid", 2) end
                return sub, obs
            end

            -------------------------------------------------------------------
            --                           property                            --
            -------------------------------------------------------------------
            --- Gets the raw value
            property "Value"            {
                get                     = function(self)
                    local ret           = {}
                    for k, v in pairs(self[Reactive]) do
                        if isobjecttype(v, IReactive) then
                            ret[k]      = v.Value
                        end
                    end
                    return ret
                end
            }

            -------------------------------------------------------------------
            --                          constructor                          --
            -------------------------------------------------------------------
            function __ctor(self, init)
                rawset(self, Reactive, {})

                if type(init) == "table" then
                    for k, v in pairs(init) do
                        -- init value
                        if type(k) == "string" then
                            local ok, err       = safesetvalue(self, k, v)
                            if not ok then throw("The " .. k .. "'s value is not supported") end
                        end
                    end
                end
            end

            -------------------------------------------------------------------
            --                          meta-method                          --
            -------------------------------------------------------------------
            -- Gets the current value
            function __index(self, key, stack)
                return self[Reactive][key]
            end

            -- Set the new value
            function __newindex(self, key, value, stack)
                if type(key) ~= "string" then error("The key can only be string", (stack or 1) + 1) end

                local reacts            = self[Reactive]
                local react             = reacts[key]
                if react then
                    if isobjecttype(react, IReactive) then
                        if isobjecttype(value, IReactive) then
                            value       = value.Value
                        elseif isobjecttype(value, IObservable) then
                            if isobjecttype(react, ReactiveValue) then
                                react.Observable = value
                                return
                            else
                                error("The " .. key .. " is readonly", (stack or 1) + 1)
                            end
                        end

                        local ok, err   = safesetvalue(react, "Value", value)
                        if not ok then error(err:gsub("Value", key), (stack or 1) + 1) end
                    else
                        error("The " .. key .. " is readonly", (stack or 1) + 1)
                    end

                elseif type(value) == "function" then
                    rawset(self, key, applyfuncattr(self, key, value, (stack or 1) + 1))

                elseif isobjecttype(value, IObservable) then
                    rawset(reacts, key, value)
                    subscribeReactiveSimple(self, key, value)

                else
                    react               = reactive(value)
                    if not react then error("The " .. key .. "'s value is not supported", (stack or 1) + 1) end
                    rawset(reacts, key, react)
                    subscribeReactiveSimple(self, key, react)
                end
            end
        end

        -------------------------------------------------------------------
        --                   non-dict class/interface                    --
        -------------------------------------------------------------------
        -- for common types
        if Class.Validate(targettype) or Interface.Validate(targettype) then
            properties                  = {}

            -- simple parse value
            export {
                simpleparse             = function (val) if isobjecttype(val, IReactive) then return val.Value else return val end end
            }

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


        -------------------------------------------------------------------
        --                         member struct                         --
        -------------------------------------------------------------------
        elseif Struct.Validate(targettype) and Struct.GetStructCategory(targettype) == "MEMBER" then
            properties                  = {}

            -- Binding object methods
            for name, func, isstatic in Struct.GetMethods(targettype, true) do
                if not isstatic then
                    _ENV[name]          = function(self, ...) local raw = self.Value if raw then return func(raw, ...) end end
                end
            end

            for _, mem in Struct.GetMembers(targettype) do
                local mtype             = mem:GetType()
                local name              = mem:GetName()

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

        -------------------------------------------------------------------
        --                            default                            --
        -------------------------------------------------------------------
        else
            throw("the " .. tostring(targettype) .. " can't be used as Reactive template parameter")
        end

        -------------------------------------------------------------------
        --                           auto-gen                            --
        -------------------------------------------------------------------
        do
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

                            local ok, e = safesetvalue(r, "Value", value)
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
        __Arguments__{ targettype }
        function __ctor(self, init)
            rawset(self, Reactive, {})
            rawset(self, RawTable, init)
        end

        -------------------------------------------------------------------
        --                          meta-method                          --
        -------------------------------------------------------------------
        -- objects may have its private fields, block those access
        function __newindex(self, key, value, stack)
            error("The " .. key .. " can't be written", (stack or 1) + 1)
        end
    end)
end)