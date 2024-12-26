
--===========================================================================--
--                                                                           --
--                    System.Reactive.ReactiveDictionary                     --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2024/12/26                                               --
-- Update Date  :   2024/12/26                                               --
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

    -- push data
    local onObjectNext                  = function(obj, ...) return obj and getObjectSubject(obj):OnNext(...) end
    local onObjectError                 = function(obj, ex)  return obj and getObjectSubject(obj):OnError(ex) end
    local onObjectCompleted             = function(obj)      return obj and getObjectSubject(obj):OnCompleted() end

    --- Represents the reactive dictionary value
    __Sealed__()
    __Arguments__{ AnyType/Any, AnyType/Any }
    class"System.Reactive.ReactiveDictionary" (function(_ENV, ktype, vtype)
        extend "IObservable" "IReactive" "IKeyValueDict"

        export                          {
            rawset                      = rawset,
            rawget                      = rawget,
            pcall                       = pcall,
            error                       = error,
            yield                       = coroutine.yield,

            issubtype                   = Class.IsSubType,
            isvaluetype                 = Class.IsValueType,
            gettempparams               = Class.GetTemplateParameters,
            isclass                     = Class.Validate,
            getsuperclass               = Class.GetSuperClass,
            isstruct                    = Struct.Validate,
            isstructtype                = Struct.IsSubType,
            getstructcategory           = Struct.GetStructCategory,
            getarrayelement             = Struct.GetArrayElement,
            getdictionarykey            = Struct.GetDictionaryKey,
            getdictionaryval            = Struct.GetDictionaryValue,
            isarray                     = Toolset.isarray,

            IKeyValueDict, Subject, RawTable
        }

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
            if not ok then error("Usage: reactiveDictionary:Subscribe(IObserver[, Subscription]) - the argument not valid", 2) end

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
                subject.Observable      = value and getObjectSubject(value) or nil       
            end,
            type                        = valtype or RawTable
        }

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        -- Generate reactive value with init data
        __Arguments__{ Table/nil }
        function __ctor(self, val)
            super(self)
            self[1]                     = val
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
        end

        function __newindex(self, key, value)
        end
    end)
end)