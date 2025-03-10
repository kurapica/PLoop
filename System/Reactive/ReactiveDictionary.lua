
--===========================================================================--
--                                                                           --
--                    System.Reactive.ReactiveDictionary                     --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2024/12/26                                               --
-- Update Date  :   2025/02/22                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)

    export                              {
        rawset                          = rawset,
        rawget                          = rawege,

        Subject, Reactive,
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

    --- Represents the reactive dictionary value
    __Sealed__()
    __Arguments__{ (-IKeyValueDict + DictStructType)/nil }
    class"System.Reactive.ReactiveDictionary" (function(_ENV, dictType)
        extend "IReactive" "IKeyValueDict"

        export                          {
            rawset                      = rawset,
            rawget                      = rawget,
            pcall                       = pcall,
            error                       = error,
            yield                       = coroutine.yield,
            pairs                       = pairs,
            isobjecttype                = Class.IsObjectType,

            Subject, RawTable
        }

        -- get the key value type
        local ktype, vtype              = Any, Any
        if dictType then
            if Struct.Validate(dictType) then
                ktype, vtype            = Struct.GetDictionaryKey(dictType) or Any, Struct.GetDictionaryValue(dictType) or Any
            else
                ktype, vtype            = Interface.GetTemplateParameters(dictType)
                ktype                   = ktype and Any
                vtype                   = vtype and Any
            end
        end

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        --- Get iterators
        __Iterator__()
        function GetIterator(self)
            local raw                   = self.Value
            if not raw then return end

            -- iter
            local yield                 = yield
            for k, v in (raw.GetIterator or pairs)(raw) do
                yield(k, v)
            end
        end

        --- Map the items to other type datas, use collection operation instead of observable
        Map                             = IKeyValueDict.Map

        --- Used to filter the items with a check function
        Filter                          = IKeyValueDict.Filter

        --- Subscribe the observers
        function Subscribe(self, ...)                
            local subject               = rawget(self, Subject)
            if not subject then
                subject                 = Subject()
                rawset(self, Subject, subject)
                subject.Observable      = self.Value and getObjectSubject(self.Value) or nil
            end

            -- subscribe
            local ok, sub, obs          = pcall(subject.Subscribe, subject, ...)
            if not ok then error(sub, 2) end

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
                local subject           = rawget(self, Subject)
                if not subject then return end
                subject.Observable      = value and getObjectSubject(value) or nil
                subject:OnNext(nil)
            end,
            type                        = dictType and (dictType + ReactiveDictionary[dictType]) or RawTable,
            throwable                   = true,
        }

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        -- Generate reactive value with reactive value
        __Arguments__{ dictType and ReactiveDictionary[dictType] or ReactiveDictionary }
        function __ctor(self, val)
            self.Value                  = val.Value
        end

        -- Generate reactive value with init data
        __Arguments__{ dictType and dictType or RawTable/nil }
        function __ctor(self, val)
            self.Value                  = val or {}
        end

        -------------------------------------------------------------------
        --                        de-constructor                         --
        -------------------------------------------------------------------
        function __dtor(self)
            local subject               = rawget(self, Subject)
            return subject and subject:Dispose()
        end

        -----------------------------------------------------------------------
        --                            meta-method                            --
        -----------------------------------------------------------------------
        function __index(self, key)
            local raw                   = rawget(self, RawTable)
            if raw then return raw[key] end
        end

        if ktype ~= Any or vtype ~= Any then 
            error                       = throw
            __Arguments__{ ktype, vtype/nil, Number/nil }:Throwable()
        end
        function __newindex(self, key, value, stack)
            local raw                   = rawget(self, RawTable)
            if not raw then error("The raw object is not specified", (stack or 1) + 1) end

            if raw[key] == value then return end
            raw[key]                    = value
            return getObjectSubject(raw):OnNext(key, value)
        end
    end)
end)