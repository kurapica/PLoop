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
            getmetatable                = getmetatable,
            isObjectType                = Class.IsObjectType,

            Class, Property, Event, Reactive, Property
        }

        local setObjectProp             = function(self, key, value) self[key] = value end

        if targetclass then
            local checkRet              = Platform.ENABLE_TAIL_CALL_OPTIMIZATIONS
            and function(ok, ...)
                if not ok then error(..., 2) end
                return ...
            end or function(ok, ...)
                if not ok then error(..., 3) end
                return ...
            end
            -------------------------------------------------------------------
            --                             event                             --
            -------------------------------------------------------------------
            for name, ev in Class.GetFeatures(targetclass, true) do
                if Event.Validate(ev) then
                    __EventChangeHandler__(function(delegate, owner, name)
                        local obj       = rawget(owner, Class)
                        delegate[Reactive] = delegate[Reactive] or function(self, ...) return delegate(owner, ...) end
                        if not delegate:IsEmpty() then
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
                if Property.Validate(prop) and Property.IsWritable(prop) then
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
                _ENV[name]              = function(self, ...) return checkRet(pcall(method, rawget(self, Class), ...) end
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
        else
            -------------------------------------------------------------------
            --                          constructor                          --
            -------------------------------------------------------------------
            __Arguments__{ Table/nil }
            function __ctor(self, init)
                local fields            = {}
                rawset(self, Reactive, fields)
                if not init then return end

                -- As init table, hash table only
                for k, v in pairs(init) do
                    if type(k) == "string" and k ~= "" and type(v) ~= "function" then
                        fields[k]       = reactive(v)
                    else
                        rawset(self, k, v)
                    end
                end
            end

            -------------------------------------------------------------------
            --                          meta method                          --
            -------------------------------------------------------------------
            --- Gets the current value
            function __index(self, key)
                local subject           =  rawget(self, Reactive)[key]
                if subject then
                    if isObjectType(subject, BehaviorSubject) then
                        return subject:GetValue()
                    else
                        -- inner reactive
                        return subject
                    end
                end

                -- Check the proxy class
                local object                = rawget(self, Class)
                if object then return object[key] end
            end

            --- Send the new value
            function __newindex(self, key, value)
                local fields                = rawget(self, Reactive)
                local object                = rawget(self, Class)

                -- Set the object is exist
                if object then
                    local ok, err           = pcall(setObjectProp, object, key, value)
                    if not ok then error(err, 2) end
                    return
                end

                -- Send the value
                local subject               = fields[key]
                if subject then
                    -- BehaviorSubject
                    if isObjectType(subject, BehaviorSubject) then
                        return subject:OnNext(value)

                    -- Reactive
                    elseif type(value) == "table" and getmetatable(value) == nil then
                        local sfields       = rawget(subject, Reactive)
                        for sname in pairs(sfields) do
                            subject[sname]  = value[sname]
                        end

                        for k, v in pairs(value) do
                            if not sfields[k] and type(k) == "string" and k ~= "" and v ~= nil and type(v) ~= "function" then
                                sfields[k]  = reactive(v)
                            end
                        end

                        return

                    -- Not valid
                    else
                        error("The reactive field " .. tostring(key) .. " is a reactive table, only accept table value", 2)
                    end
                end

                -- New reactive - hash key only
                if type(key) == "string" and key ~= "" and value ~= nil and type(value) ~= "function" then
                    fields[key]             = reactive(value)
                    return
                end

                error("The reactive field " .. tostring(key) .. " can't be defined", 2)
            end

            --- Gets the subject
            function __call(self, key)
                local subject               =  rawget(self, Reactive)[key]
                if subject ~= nil then
                    return isObjectType(subject, BehaviorSubject) and subject or nil
                else
                    local fields            = rawget(self, Reactive)

                    -- New reactive used for subscribe
                    if type(key) == "string" and key ~= ""  then
                        fields[key]         = reactive(nil)
                        return fields[key]
                    end
                end
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

        IObservable, Reactive, ReactiveList, BehaviorSubject, List
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
                    elseif isSubType(cls, List) then
                        return ReactiveList(value)

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