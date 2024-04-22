--===========================================================================--
--                                                                           --
--                              System.Reactive                              --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2023/04/20                                               --
-- Update Date  :   2024/04/01                                               --
-- Version      :   2.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    -----------------------------------------------------------------------
    --                       Static Implementation                       --
    -----------------------------------------------------------------------
    class "System.Reactive"             (function(_ENV)
        -------------------------------------------------------------------
        --                          declaration                          --
        -------------------------------------------------------------------
        class "__Observable__"          {}
        class "BehaviorSubject"         {}
        class "ReactiveList"            {}
        class "Observable"              {}
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
            isarray                     = Toolset.isarray,
            isvaluetype                 = Class.IsValueType,
            isobjecttype                = Class.IsObjectType,
            gettempparams               = Class.GetTemplateParameters,
            isenum                      = Enum.Validate,
            isstruct                    = Struct.Validate,
            isclass                     = Class.Validate,
            isinterface                 = Interface.Validate,
            getstructcategory           = Struct.GetStructCategory,
            getarrayelement             = Struct.GetArrayElement,
            clone                       = Toolset.clone,

            updateTable                 = function(self, value)
                local raw               = rawget(self, Class) or rawget(self, RawTable)
                if not raw then return end

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

            setBehaviorValue            = function(self, value) self.Value = value end,

            IObservable, IList, IDictionary, IIndexedList, IKeyValueDict, ISubscription,
            Any, Number, String, Boolean, AnyType, RawTable, Reactive, List, Subscription,
            Watch.ReactiveProxy, Watch.ReactiveListProxy
        }

        -------------------------------------------------------------------
        --                         static method                         --
        -------------------------------------------------------------------
        --- Gets the current raw value of the reactive object
        __Static__()
        function ToRaw(self, withClone)
            -- for values
            if type(self) ~= "table" then return self end

            -- for raw table
            local cls                   = getmetatable(self)
            if cls == nil then return self end

            -- behavior subject
            if issubtype(cls, BehaviorSubject) then
                return self:GetValue()

            -- reactive proxy
            elseif issubtype(cls, ReactiveProxy) then
                -- use static method to add the deep watch
                self                    = ReactiveProxy.ToRaw(self)
                return withClone and clone(rawget(self, RawTable), true, true) or rawget(self, RawTable)

            -- reactive list proxy
            elseif issubtype(cls, ReactiveListProxy) then
                self                    = ReactiveListProxy.ToRaw(self)
                return withClone and clone(ReactiveList.ToRaw(self), true, true) or ReactiveList.ToRaw(self)

            -- reactive list
            elseif issubtype(cls, ReactiveList) then
                return withClone and clone(ReactiveList.ToRaw(self), true, true) or ReactiveList.ToRaw(self)

            -- reactive
            elseif issubtype(cls, Reactive) then
                return withClone and clone(rawget(self, RawTable), true, true) or rawget(self, RawTable)
            end

            -- observable not allowed
            return not issubtype(cls, IObservable) and self or nil
        end

        --- Sets a raw table value to the reactive object
        __Static__()
        function SetRaw(self, value, stack)
            local error                 = stack == true and throw or error
            local cls                   = getmetatable(self)
            if not cls then error("Usage: Reactive.SetRaw(reactive, value[, stack]) - the reactive not valid", (stack or 1) + 1) end

            -- behavior subject
            if issubtype(cls, BehaviorSubject) then
                if isobjecttype(value, IObservable) then
                    self.Observable     = value
                    return
                else
                    self.Observable     = nil
                    local ok, err       = pcall(setBehaviorValue, self, value)
                    if not ok then error("Usage: Reactive.SetRaw(reactive, value[, stack]) - " .. tostring(err):match("%d+:%s*(.-)$"), (stack or 1) + 1) end
                    return
                end

            -- reactive list proxy
            elseif issubtype(cls, ReactiveListProxy) then
                self                    = ReactiveListProxy.ToRaw(self, true)
                cls                     = ReactiveList

            -- reative proxy
            elseif issubtype(cls, ReactiveProxy) then
                self                    = ReactiveProxy.ToRaw(self, true)
                cls                     = Reactive
            end

            -- reactive list
            if issubtype(cls, ReactiveList) then
                ReactiveList.SetRaw(self, value, stack ~= true and ((stack or 1) + 1) or stack)
                return

            -- reactive
            elseif issubtype(cls, Reactive) then
                -- too complex to handle the observable objects assignment, use raw directly
                value                   = toraw(value, true)
                if value ~= nil and type(value) ~= "table" then
                    error("Usage: Reactive.SetRaw(reactive, value[, stack]) - the value not valid", (stack or 1) + 1)
                end

                -- as object proxy
                local ok, err           = pcall(updateTable, self, value)
                if not ok then error("Usage: Reactive.SetRaw(reactive, value) - " .. err, (stack or 1) + 1) end
                return
            end

            -- other
            error("Usage: Reactive.SetRaw(reactive, value[, stack]) - the reactive not valid", (stack or 1) + 1)
        end

        -- Gets the recommend ractive type for the given type
        __Static__()
        __Arguments__{ Any/nil, AnyType/nil }
        function GetReactiveType(value, recommendtype)
            -- validate the value
            if recommendtype and value ~= nil and not getmetatable(recommendtype).ValidateValue(recommendtype, value) then return end

            -- get value type
            local valtype               = type(value)
            local metatype
            if value == nil then
                metatype                = recommendtype
            elseif valtype == "table" then
                metatype                = getmetatable(value) or recommendtype
            elseif valtype == "number" then
                metatype                = recommendtype or Number
            elseif valtype == "string" then
                metatype                = recommendtype or String
            elseif valtype == "boolean" then
                metatype                = recommendtype or Boolean
            else
                return
            end

            -- get reactive type
            local rtype
            if metatype == nil then
                rtype                   = valtype == "table" and (isarray(value) and ReactiveList or Reactive) or nil

            elseif metatype == Any then
                rtype                   = BehaviorSubject

            elseif isenum(metatype) then
                rtype                   = BehaviorSubject[metatype]

            elseif isstruct(metatype) then
                local cate              = getstructcategory(metatype)

                if cate == "CUSTOM" then
                    rtype               = BehaviorSubject[metatype]

                elseif cate == "ARRAY" then
                    local element       = getarrayelement(metatype)
                    rtype               = element and ReactiveList[element] or ReactiveList

                else
                    rtype               = Reactive[metatype]
                end

            elseif isclass(metatype) then
                -- already wrap
                if issubtype(metatype, Reactive) or issubtype(metatype, ReactiveList) or issubtype(metatype, BehaviorSubject) then
                    rtype               = nil

                -- wrap the observable
                elseif issubtype(metatype, IObservable) then
                    rtype               = BehaviorSubject

                -- if is value type like Date
                elseif isvaluetype(metatype) then
                    rtype               = BehaviorSubject[metatype]

                -- wrap list or array to reactive list
                elseif issubtype(metatype, IList) then
                    -- to complex to cover more list types, only List for now
                    if issubtype(metatype, List) then
                        local ele       = gettempparams(metatype)
                        rtype           = ele and ReactiveList[ele] or ReactiveList
                    end

                -- wrap dictionary
                elseif issubtype(metatype, IDictionary) then
                    if issubtype(metatype, IKeyValueDict) then
                        rtype           = Reactive[metatype]
                    end

                -- common wrap
                else
                    rtype               = Reactive[metatype]
                end
            end

            return rtype
        end

        export                          {
            toraw                       = ToRaw
        }
    end)

    -----------------------------------------------------------------------
    --                          Implementation                           --
    -----------------------------------------------------------------------
    --- The proxy used to access reactive table field datas
    __Sealed__()
    __Arguments__{ AnyType/nil }:WithRebuild()
    __NoNilValue__(false):AsInheritable()
    __NoRawSet__(false):AsInheritable()
    class "System.Reactive"             (function(_ENV, targetclass)
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
            gettempparams               = Class.GetTemplateParameters,
            isobjecttype                = Class.IsObjectType,
            geteventdelegate            = Event.Get,
            rawMap                      = not Platform.MULTI_OS_THREAD and Toolset.newtable(true, true) or false,
            toraw                       = Reactive.ToRaw,
            setraw                      = Reactive.SetRaw,
            setrawlist                  = ReactiveList.SetRaw,

            -- bind data change event handler when accessed
            bindDataChange              = function(self, k, r)
                if r and geteventdelegate(OnDataChange, self, true) then
                    if isobjecttype(r, Reactive) or isobjecttype(r, ReactiveList) then
                        r.OnDataChange  = r.OnDataChange + function(_, ...) return OnDataChange(self, k, ...) end
                    else
                        r:Subscribe(function(val) return OnDataChange(self, k, val) end)
                    end
                end
                return r
            end,

            -- wrap the table value as default
            makeReactive                = function(self, k, v, type, behaviorType)
                if not (type or behaviorType) then
                    local rtype         = Reactive.GetReactiveType(v)
                    if issubtype(rtype, BehaviorSubject) then
                        behaviorType    = rtype
                    end
                end

                local r                 = behaviorType and behaviorType(self[RawTable], k) or reactive(v, true, type)
                self[Reactive][k]       = r or false
                return r and bindDataChange(self, k, r)
            end,

            Class, Property, Event, Reactive, ReactiveList, BehaviorSubject, Observable
        }

        -------------------------------------------------------------------
        --                             event                             --
        -------------------------------------------------------------------
        --- Fired when the data changed
        __EventChangeHandler__(function(_, owner, _, init)
            if not init then return end
            for k, r in pairs(owner[Reactive]) do bindDataChange(owner, k, r) end
        end)
        event "OnDataChange"

        -------------------------------------------------------------------
        --                   non-dict class/interface                    --
        -------------------------------------------------------------------
        if targetclass and (Class.Validate(targetclass) or Interface.Validate(targetclass)) and not Interface.IsSubType(targetclass, IKeyValueDict) then
            properties                  = {}

            for _, ftr in Class.GetFeatures(targetclass, true) do
                -- only allow read/write non-indexer properties
                if Property.Validate(ftr) and ftr:IsWritable() and ftr:IsReadable() and not ftr:IsIndexer() then
                    local pname         = ftr:GetName()
                    local ptype         = ftr:GetType() or Any
                    local rtype         = Reactive.GetReactiveType(nil, ptype)

                    -- only allow reacive types
                    if rtype then
                        properties[pname] = true

                        property(pname) {
                            -- gets the reactive
                            get         = Class.IsSubType(rtype, BehaviorSubject)
                            and function(self)
                                return self[Reactive][pname] or makeReactive(self, pname, nil, nil, rtype)
                            end
                            or function(self)
                                local r = self[Reactive][pname]
                                if r    then return r end
                                local d = self[RawTable][pname]
                                return d and makeReactive(self, pname, d, ptype)
                            end,

                            -- sets the value
                            set         = Class.IsSubType(rtype, BehaviorSubject)
                            and function(self, value)
                                -- allow binding observable like watch to the property
                                local s = self[pname]
                                if value and isobjecttype(value, IObservable) then
                                    s.Observable = value
                                else
                                    s.Observable = nil
                                    return s:OnNext(value)
                                end
                            end
                            or Class.IsSubType(rtype, ReactiveList)
                            and function(self, value)
                                -- too complex to hanlde the value as reactive object
                                local r = self[Reactive][pname]
                                if r    then return setrawlist(r, value, true) end
                                value   = toraw(value, true)
                                self[RawTable][pname] = value
                                return OnDataChange(self, pname, makeReactive(self, pname, value, ptype))
                            end
                            or function(self, value)
                                local r = self[Reactive][pname]
                                if r    then return setraw(r, value, true) end
                                value   = toraw(value, true)
                                self[RawTable][pname] = value
                                return OnDataChange(self, pname, makeReactive(self, pname, value, ptype))
                            end,
                            type        = Class.IsSubType(rtype, BehaviorSubject) and (ptype + IObservable) or (ptype + rtype),
                            throwable   = true,
                        }

                    -- for non-reactive
                    else
                        property (pname) {
                            get         = function(self) return self[RawTable][pname] end,
                            set         = function(self, value) self[RawTable][pname] = value end,
                            type        = ptype
                        }
                    end
                elseif Property.Validate(ftr) then
                    if Property.IsIndexer(ftr) then
                        __Indexer__(Property.GetIndexType(ftr))
                        property (pname) {
                            get         = Property.IsReadable(ftr) and function(self, idx) return self[RawTable][pname][idx] end,
                            set         = Property.IsWritable(ftr) and function(self, idx, value) self[RawTable][pname][idx] = value end,
                            type        = Property.GetType(ftr),
                        }
                    else
                        property (pname) {
                            get         = Property.IsReadable(ftr) and function(self) return self[RawTable][pname] end,
                            set         = Property.IsWritable(ftr) and function(self, value) self[RawTable][pname] = value end,
                            type        = Property.GetType(ftr),
                        }
                    end
                end
            end

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

        -------------------------------------------------------------------
        --                         member struct                         --
        -------------------------------------------------------------------
        elseif targetclass and Struct.Validate(targetclass) and Struct.GetStructCategory(targetclass) == "MEMBER" then
            properties                  = {}

            for _, mem in Struct.GetMembers(targetclass) do
                local mtype             = mem:GetType()
                local mname             = mem:GetName()
                local rtype             = Reactive.GetReactiveType(nil, mtype)

                if rtype then
                    properties[mname]   = true
                    property (mname)    {
                        -- gets the reactive
                        get             = Class.IsSubType(rtype, BehaviorSubject)
                        and function(self)
                            return self[Reactive][mname] or makeReactive(self, mname, nil, nil, rtype)
                        end
                        or function(self)
                            local r     = self[Reactive][mname]
                            if r    then return r end
                            local d     = self[RawTable][mname]
                            return d and makeReactive(self, mname, d, mtype)
                        end,

                        -- sets the value
                        set             = Class.IsSubType(rtype, BehaviorSubject)
                        and function(self, value)
                            -- allow binding observable like watch to the property
                            local s     = self[mname]
                            if value and isobjecttype(value, IObservable) then
                                s.Observable = value
                            else
                                s.Observable = nil
                                return s:OnNext(value)
                            end
                        end
                        or Class.IsSubType(rtype, ReactiveList)
                        and function(self, value)
                            local r     = self[Reactive][mname]
                            if r        then return setrawlist(r, value, true) end
                            value       = toraw(value, true)
                            self[RawTable][mname] = value
                            return OnDataChange(self, mname, makeReactive(self, mname, value, mtype))
                        end
                        or function(self, value)
                            local r     = self[Reactive][mname]
                            if r        then return setraw(r, value, 2) end
                            value       = toraw(value, true)
                            self[RawTable][mname] = value
                            return OnDataChange(self, mname, makeReactive(self, mname, value, mtype))
                        end,
                        type            = Class.IsSubType(rtype, BehaviorSubject) and (mtype + IObservable) or (mtype + rtype),
                        throwable       = true,
                    }

                -- for non-reactive
                else
                    property (mname)    {
                        get             = function(self) return self[RawTable][mname] end,
                        set             = function(self, value) self[RawTable][mname] = value end,
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

        --- Map the items to other type datas, use collection operation instead of observable
        Map                             = IKeyValueDict.Map

        --- Used to filter the items with a check function
        Filter                          = IKeyValueDict.Filter

        -------------------------------------------------------------------
        --                          constructor                          --
        -------------------------------------------------------------------
        --- bind the reactive and object
        if targetclass then
            __Arguments__{ targetclass }
        else
            __Arguments__{ RawTable/nil }
        end
        function __ctor(self, init)
            rawset(self, Reactive, {})
            rawset(self, RawTable, init or {})

            -- avoid to set value in raw dict object if possible
            if init then
                if rawMap then
                    rawMap[init]        = self
                else
                    rawset(init, Reactive, self)
                end
            end
        end

        --- use the wrap for objects
        function __exist(_, init)
            if not init then return end
            if rawMap then return rawMap[init] end
            return isobjecttype(init, Reactive) and init or rawget(init, Reactive)
        end

        ---------------------------------------------------------------
        --                        meta-method                        --
        ---------------------------------------------------------------
        --- Gets the current value
        function __index(self, key)
            local reactives             = rawget(self, Reactive)
            local r                     = reactives[key]
            if r then return r end

            -- wrap raw
            local value                 = rawget(self, RawTable)[key]
            return r == nil and value ~= nil and type(key) == "string" and makeReactive(self, key, value) or value
        end

        --- Send the new value
        if targetclass then
            local keytype, valtype

            -- for Dictionary class
            if Class.Validate(targetclass) and Interface.IsSubType(targetclass, IKeyValueDict) then
                keytype, valtype        = gettempparams(targetclass)

            -- for Dictionary struct
            elseif Struct.GetStructCategory(targetclass) == "DICTIONARY" then
                keytype, valtype        = Struct.GetDictionaryKey(targetclass), Struct.GetDictionaryValue(targetclass)
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
                r                       = makeReactive(self, key, nil, nil, isobjecttype(vtype, BehaviorSubject) and vtype or BehaviorSubject)
                r.Observable            = value
            else
                value                   = toraw(value, true)
                raw[key]                = value
                r                       = makeReactive(self, key, value)
                return r and OnDataChange(self, key, not isobjecttype(r, BehaviorSubject) and r or value)
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

        Reactive, ReactiveList, BehaviorSubject, Any, Attribute
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
                if cls and (issubtype(cls, Reactive) or issubtype(cls, ReactiveList) or issubtype(cls, BehaviorSubject)) then return value end

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