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
    __Arguments__{ AnyType/nil }:WithRebuild()
    __NoNilValue__(false):AsInheritable()
    __NoRawSet__(false):AsInheritable()
    class "System.Reactive"             (function(_ENV, targetclass)
        extend "IObservable"

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
            gettempparams               = Class.GetTemplateParameters,
            isobjecttype                = Class.IsObjectType,
            geteventdelegate            = Event.Get,
            rawMap                      = not Platform.MULTI_OS_THREAD and Toolset.newtable(true, true) or false,

            -- bind data change event handler when accessed
            bindDataChange              = function(self, k, r)
                if r and geteventdelegate(OnDataChange, self, true) and (isobjecttype(r, Reactive) or isobjecttype(r, ReactiveList)) then
                    r.OnDataChange      = r.OnDataChange + function(_, ...) return OnDataChange(self, k, ...) end
                end
                return r
            end,

            -- handle data change event
            handleDataChangeEvent       = function(_, owner, name, init)
                if not init then return end
                local reactives         = owner[Reactive]
                for k, r in pairs(reactives) do
                    bindDataChange(owner, k, r)
                end
            end,

            -- wrap the table value as default
            makeReactive                = function(self, k, v)
                local r                 = reactive(v, true)
                self[Reactive][k]       = r or false
                return r and bindDataChange(self, k, r)
            end,

            Class, Property, Event, Reactive, ReactiveList, BehaviorSubject, Observable
        }

        -------------------------------------------------------------------
        --                             event                             --
        -------------------------------------------------------------------
        --- Fired when the data changed
        __EventChangeHandler__(handleDataChangeEvent)
        event "OnDataChange"

        -------------------------------------------------------------------
        --                         common method                         --
        -------------------------------------------------------------------
        --- Subscribe the observers
        function Subscribe(self, ...)   return Observable.From(self.OnDataChange):Subscribe(...) end


        -------------------------------------------------------------------
        --                      common constructor                       --
        -------------------------------------------------------------------
        --- bind the reactive and object
        if targetclass and Class.Validate(targetclass) then __Arguments__{ targetclass } else __Arguments__{ RawTable/nil } end
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

        -------------------------------------------------------------------
        --                    common validation type                     --
        -------------------------------------------------------------------
        -- for common class types
        if targetclass and Class.Validate(targetclass) and not Class.IsSubType(targetclass, IKeyValueDict) then
            for _, ftr in Class.GetFeatures(targetclass, true) do
                if Property.Validate(ftr) then

                end
            end

            return

        -- for member struct types
        elseif targetclass and Struct.Validate(targetclass) and Struct.GetStructCategory(targetclass) == "MEMBER" then
            export                      {
                setRawList              = ReactiveList.SetRaw,
            }

            for _, mem in Struct.GetMembers(targetclass) do
                local memtype           = mem:GetType()
                local name              = mem:GetName()
                local rtype             = Reactive.GetReactiveType(memtype)

                if rtype then
                    if Class.IsSubType(rtype, Reactive) then
                        property (name) {
                            type        = memtype,
                            get         = function(self)
                                local r = self[Reactive][name]
                                if not r then
                                    r   = rtype(self[RawTable][name])
                                end
                                return r
                            end,
                            set         = function(self, value)
                                local r = self[Reactive][name]
                                if r then
                                    setRaw(r, value, 2)
                                else
                                    self[RawTable][name] = value
                                end
                            end,
                            require     = mem:IsRequire()
                        }

                    elseif Class.IsSubType(rtype, ReactiveList) then
                        property (name) {
                            type        = memtype,
                            get         = function(self)
                                local r = self[Reactive][name]
                                if not r then
                                    r   = rtype(self[RawTable][name])
                                end
                                return r
                            end,
                            set         = function(self, value)
                                local r = self[Reactive][name]
                                if r then
                                    setRawList(r, value, 2)
                                else
                                    self[RawTable][name] = value
                                end
                            end,
                            require     = mem:IsRequire()
                        }

                    elseif Class.IsSubType(BehaviorSubject) then
                        property (name) {
                            type        = memtype,
                            get         = function(self)

                            end,
                            set         = function(self, value)


                                self[RawTable][name] = value
                                self[Reactive][name]:OnNext(value)
                            end,
                            require     = mem:IsRequire()
                        }
                    end
                end
            end

            return
        end

        ---------------------------------------------------------------
        --                     extend dictionary                     --
        ---------------------------------------------------------------
        extend "IKeyValueDict"

        --- Map the items to other type datas, use collection operation instead of observable
        Map                             = IKeyValueDict.Map

        --- Used to filter the items with a check function
        Filter                          = IKeyValueDict.Filter

        ---------------------------------------------------------------
        --                        meta-method                        --
        ---------------------------------------------------------------
        --- Gets the current value
        function __index(self, key)
            local reactives         = rawget(self, Reactive)
            local r                 = reactives[key]
            if r then return r end

            -- wrap raw
            local value             = rawget(self, RawTable)[key]
            return r == nil and value ~= nil and type(key) == "string" and makeReactive(self, key, value) or value
        end

        --- Send the new value
        if targetclass then
            local keytype, valtype

            -- for Dictionary class
            if Class.Validate(targetclass) then
                keytype, valtype    = gettempparams(targetclass)

            -- for Dictionary struct
            elseif Struct.GetStructCategory(targetclass) == "DICTIONARY" then
                keytype, valtype    = Struct.GetDictionaryKey(targetclass), Struct.GetDictionaryValue(targetclass)
            end
            if (keytype and keytype ~= Any) or (valtype and valtype ~= Any) then
                __Arguments__{ keytype or Any, (valtype or Any)/nil }
            end
        end
        function __newindex(self, key, value)
            -- unpack
            if type(value) == "table" then
                value               = toRaw(value)
            end

            -- check raw
            local raw               = self[RawTable]
            if raw[key] == value    then return end

            -- check the reactive
            local reactives         = rawget(self, Reactive)
            local r                 = reactives[key]
            if r then
                -- BehaviorSubject
                if isobjecttype(r, BehaviorSubject) then
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
            elseif r == false then
                reactives[key]      = nil
            end

            -- raw directly
            raw[key]                = value

            -- make table reactive now, since it may be used in the event handler
            return OnDataChange(self, key, type(key) == "string" and type(value) == "table" and makeReactive(self, key, value) or value)
        end

        -- For dictionary
        if targetclass then
            ---------------------------------------------------------------
            --                          method                           --
            ---------------------------------------------------------------
            --- Gets the iterator
            __Iterator__()
            function GetIterator(self)
                local yield             = yield
                for k, v in self[RawTable]:GetIterator() do
                    if type(k) == "string" then
                        yield(k, self[k])
                    elseif k ~= Reactive then
                        yield(k, v)
                    end
                end
            end

            ---------------------------------------------------------------
            --                        meta-method                        --
            ---------------------------------------------------------------
        -- As container for reactive fields, common usages
        else
            export                      {
                pcall                   = pcall,
                pairs                   = pairs,
                type                    = type,
                error                   = error,
                tostring                = tostring,
                getmetatable            = getmetatable,
                getFeatures             = Class.GetFeatures,
                isProperty              = Property.Validate,
                isWritable              = Property.IsWritable,
                isIndexer               = Property.IsIndexer,
                getObjectClass          = Class.GetObjectClass,
                issubtype               = Class.IsSubType,
                isobjecttype            = Class.IsObjectType,
                isarray                 = Toolset.isarray,
                isvaluetype             = Class.IsValueType,
                gettempparams           = Class.GetTemplateParameters,
                isenum                  = Enum.Validate,
                isstruct                = Struct.Validate,
                isclass                 = Class.Validate,
                isinterface             = Interface.Validate,
                getstructcategory       = Struct.GetStructCategory,
                getarrayelement         = Struct.GetArrayElement,
                istructvalue            = Struct.ValidateValue,

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

                    -- release
                    temp                = nil
                end,

                IObservable, Reactive, ReactiveList, BehaviorSubject, Any, AnyType, RawTable,
                IList, List, IDictionary, Dictionary, Proxy, IIndexedList, IKeyValueDict

            }

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
                if issubtype(cls, BehaviorSubject) then
                    return self.Value

                -- reactive list
                elseif issubtype(cls, ReactiveList) then
                    return ReactiveList.ToRaw(self)

                -- reactive
                elseif issubtype(cls, Reactive) then
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
                if issubtype(cls, BehaviorSubject) then
                    return self:OnNext(value)

                -- reactive list
                elseif issubtype(cls, ReactiveList) then
                    ReactiveList.SetRaw(self, value, (stack or 1) + 1)
                    return

                -- reactive
                elseif issubtype(cls, Reactive) then
                    if value ~= nil and type(value) ~= "table" then
                        error("Usage: Reactive.SetRaw(reactive, value[, stack]) - the value not valid", (stack or 1) + 1)
                    end

                    -- as object proxy
                    local ok, err       = pcall(updateTable, self, value)
                    if not ok then error("Usage: Reactive.SetRaw(reactive, value) - " .. err, (stack or 1) + 1) end
                    return
                end

                -- other
                error("Usage: Reactive.SetRaw(reactive, value[, stack]) - the reactive not valid", (stack or 1) + 1)
            end

            -- Gets the recommend ractive type for the given type
            __Static__()
            __Arguments__{ AnyType, Any/nil }
            function GetReactiveType(recommendtype, value)
                if recommendtype == Any then recommendtype = nil end

                -- validate the value
                if recommendtype and value ~= nil and not getmetatable(recommendtype).ValidateValue(recommendtype, value) then
                    return
                end

                -- get value type
                local valtype           = type(value)
                local metatype
                if valtype == nil then
                    metatype            = recommendtype
                elseif valtype == "table" then
                    metatype            = getmetatable(value) or recommendtype
                elseif valtype == "number" then
                    metatype            = recommendtype or Number
                elseif valtype == "string" then
                    metatype            = recommendtype or String
                elseif valtype == "boolean" then
                    metatype            = recommendtype or Boolean
                else
                    return
                end

                -- get reactive type
                local rtype
                if metatype == nil then
                    rtype               = valtype == "table" and (isarray(value) and ReactiveList or Reactive) or nil

                elseif isenum(metatype) then
                    rtype               = BehaviorSubject[metatype]

                elseif isstruct(metatype) then
                    local cate          = getstructcategory(metatype)

                    if cate == "CUSTOM" then
                        rtype           = BehaviorSubject[metatype]

                    elseif cate == "ARRAY" then
                        local element   = getarrayelement(metatype)
                        rtype           = element and ReactiveList[element] or ReactiveList

                    else
                        rtype           = Reactive[metatype]
                    end

                elseif isclass(metatype) then
                    -- already wrap
                    if issubtype(metatype, Reactive) or issubtype(metatype, ReactiveList) or issubtype(metatype, BehaviorSubject) then
                        rtype           = nil

                    -- wrap the observable
                    elseif issubtype(metatype, IObservable) then
                        rtype           = BehaviorSubject

                    -- if is value type like Date
                    elseif isvaluetype(metatype) then
                        rtype           = BehaviorSubject[metatype]

                    -- wrap list or array to reactive list
                    elseif issubtype(metatype, IList) then
                        -- to complex to cover more list types, only List for now
                        if issubtype(metatype, List) then
                            local ele   = gettempparams(metatype)
                            rtype       = ele and ReactiveList[ele] or ReactiveList
                        end

                    -- wrap dictionary
                    elseif issubtype(metatype, IDictionary) then
                        if issubtype(metatype, IKeyValueDict) then
                            rtype       = Reactive[metatype]
                        end

                    -- common wrap
                    else
                        rtype           = Reactive[metatype]
                    end
                end

                return rtype
            end

            -- Gets the recommend ractive type for the given value
            __Static__()
            __Arguments__{ Any/nil }
            function GetReactiveType(value)
                return GetReactiveType(Any, value)
            end

            ---------------------------------------------------------------
            --                          method                           --
            ---------------------------------------------------------------
            --- Gets the iterator
            __Iterator__()
            function GetIterator(self)
                local yield             = yield
                for k, v in pairs(self[RawTable]) do
                    if type(k) == "string" then
                        yield(k, self[k])
                    elseif k ~= Reactive then
                        yield(k, v)
                    end
                end
            end
        end

        export { toRaw = ToRaw, setRaw = setRaw }
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
                local rtype             = getreactivetype(recommendtype or Any, value)
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