--===========================================================================--
--                                                                           --
--                           System.Reactive.Watch                           --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2023/04/20                                               --
-- Update Date  :   2025/03/04                                               --
-- Version      :   2.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Reactive"

    --- Provide automatically subscription based on the function
    __Sealed__()
    class "Watch"                       (function(_ENV)
        inherit "BehaviorSubject"

        export                          {
            rawset                      = rawset,
            rawget                      = rawget,
            pcall                       = pcall,
            pairs                       = pairs,
            select                      = select,
            setfenv                     = _G.setfenv or _G.debug and _G.debug.setfenv or Toolset.fakefunc,
            getmetatable                = getmetatable,
            getobjectclass              = Class.GetObjectClass,
            issubtype                   = Class.IsSubType,
            isobjecttype                = Class.IsObjectType,

            -- check the access value if observable
            makeReactiveProxy           = function (observer, value, parent)
                local cls               = value and getobjectclass(value)
                if not cls then return end

                -- deep watch check
                if observer and parent and rawget(parent, Subscription) then
                    observer            = nil
                end

                -- Subscribe for reactive field
                if issubtype(cls, IReactive) then
                    if issubtype(cls, Reactive) then
                        return ReactiveProxy(observer, value, parent)
                    elseif issubtype(cls, ReactiveList) then
                        return ReactiveListProxy(observer, value, parent)
                    elseif issubtype(cls, ReactiveDictionary) then
                        return ReactiveDictionaryProxy(observer, value, parent)
                    else
                        return value, true
                    end
                elseif issubtype(cls, IObservable) then
                    return ReactiveValue(value), true
                end
            end,

            -- add reactive proxy
            addProxy                    = function(self, key, proxy)
                local proxyes           = rawget(self, ReactiveProxy)
                if not proxyes then
                    proxyes             = {}
                    rawset(self, ReactiveProxy, proxyes)

                    local react         = rawget(self, Reactive)
                    proxyes[0]          = react:Subscribe(function(key, ...)
                        local p         = proxyes[key]
                        if p and select("#", ...) < 2 then
                            local n     = react[key]
                            if n == rawget(p, Reactive) then return end
                            if n then
                                replaceProxy(p, n)
                            else
                                p:Dispose()
                                proxyes[key] = nil
                            end

                            -- Notify
                            local ob    = rawget(self, Observer)
                            local par   = rawget(self, IObservable)
                            while not ob and par do
                                -- already deep watch
                                if rawget(par, Subscription) then return end

                                ob      = rawget(par, Observer)
                                par     = rawget(par, IObservable)
                            end
                            if ob then return ob:OnNext() end
                        end
                    end)
                end
                proxyes[key]            = proxy
                return proxy
            end,

            -- add value watch
            addWatch                    = function(self, key, observable)
                local watches           = rawget(self, Watch)
                if not watches then
                    watches             = {}
                    rawset(self, Watch, watches)
                end

                -- already watched
                if watches[key] ~= nil  then return observable end

                -- subscribe
                local observer          = rawget(self, Observer)
                watches[key]            = not rawget(self, Subscription) and observer and observable:Subscribe(observer, Subscription(observer.Subscription)) or false
                return observable
            end,

            -- replace
            replaceProxy                = function(self, react)
                local observer          = rawget(self, Observer)
                rawset(self, Reactive, react)

                -- replace field watches
                local watches           = rawget(self, Watch)
                if watches then
                    for k, v in pairs(watches) do
                        if v then
                            v:Dispose()

                            local f     = react[k]
                            if isobjecttype(f, ReactiveField) then
                                watches[k] = observer and f:Subscribe(observer, Subscription(observer.Subscription)) or false
                            else
                                watches[k] = nil
                            end
                        end
                    end
                end

                -- replace deep watch subscription
                local subscription      = rawget(self, Subscription)
                if subscription then
                    subscription:Dispose()
                    rawset(self, Subscription, observer and react:Subscribe(observer, Subscription(observer.Subscription)) or nil)
                end

                -- replace child proxyes
                local proxyes           = rawget(self, ReactiveProxy)
                if proxyes then
                    if proxyes[0] then proxyes[0]:Dispose() end

                    for name, proxy in pairs(proxyes) do
                        local f         = react[name]

                        if f and (
                            (isobjecttype(f, Reactive) and isobjecttype(proxy, ReactiveProxy)) or
                            (isobjecttype(f, ReactiveList) and isobjecttype(proxy, ReactiveListProxy)) or
                            (isobjecttype(f, ReactiveDictionary) and isobjecttype(proxy, ReactiveDictionaryProxy))
                            ) then
                            replaceProxy(proxy, f)
                        else
                            proxy:Dispose()
                            proxyes[name] = nil
                        end
                    end

                    proxyes[0]          = react:Subscribe(function(key, ...)
                        local p         = proxyes[key]
                        if p and select("#", ...) < 2 then
                            local n     = react[key]
                            if n == rawget(p, Reactive) then return end
                            if n then
                                replaceProxy(p, n)
                            else
                                p:Dispose()
                                proxyes[key] = nil
                            end

                            -- Notify
                            local ob    = rawget(self, Observer)
                            local par   = rawget(self, IObservable)
                            while not ob and par do
                                -- already deep watch
                                if rawget(par, Subscription) then return end

                                ob      = rawget(par, Observer)
                                par     = rawget(par, IObservable)
                            end
                            if ob then return ob:OnNext() end
                        end
                    end)
                end
            end,

            -- use deep watch
            addDeepWatch                = function(self, observable)
                local observer          = rawget(self, Observer)
                if observer and rawget(self, Subscription) == nil then
                    rawset(self, Subscription, observable:Subscribe(observer, Subscription(observer.Subscription)))
                    return releaseSubWatches(self)
                end
            end,

            -- release child subscription
            releaseSubWatches           = function (self, observer)
                -- already mark writable
                if rawget(self, Observer) == false then return end

                -- dispose value watches
                local watches           = rawget(self, Watch)
                if watches then
                    for k, v in pairs(watches) do
                        if v then
                            watches[k]  = false
                            v:Dispose()
                        end
                    end
                end

                -- dispose child proxy watches
                local proxyes           = rawget(self, ReactiveProxy)
                if proxyes then
                    for _, proxy in pairs(proxyes) do
                        -- disable child subscribe
                        rawset(proxy, Observer, observer)
                        sub             = rawget(proxy, Subscription)
                        if sub then
                            rawset(proxy, Subscription, nil)
                            sub:Dispose()
                        end
                        releaseSubWatches(proxy, observer)
                    end
                end
            end,

            -- release deep watch
            releaseDeepWatch            = function(self)
                local observer          = rawget(self, Observer)

                -- enable watch
                rawset(self, Watch, nil)

                -- enable child proxy watches
                local proxyes           = rawget(self, ReactiveProxy)
                if proxyes then
                    for _, proxy in pairs(proxyes) do
                        -- not writable
                        if rawget(proxy, Observer) ~= false then
                            -- enable child watch
                            rawset(proxy, Observer, observer)
                            releaseDeepWatch(proxy)
                        end
                    end
                end
            end,

            -- write, remove watch & disable deep watch
            makeWritable                = function(self, name)
                -- already writable
                local observer          = rawget(self, Observer)
                if observer == false then return end

                -- release deep watch
                local parent            = self
                if not observer or rawget(parent, Subscription) then
                    -- deep watch need find the deep watch node to release
                    while parent and not rawget(parent, Observer) do
                        parent          = rawget(self, IObservable)
                    end

                    -- release deep watch
                    releaseDeepWatch(parent)
                    observer            = rawget(self, Observer)
                end

                -- block the deep watch to the root node
                parent                  = self
                while parent do
                    local subscription  = rawget(parent, Subscription)
                    if subscription == false then break end

                    -- disable deep watch
                    if subscription then subscription:Dispose() end
                    rawset(parent, Subscription, false)

                    parent              = rawget(parent, IObservable)
                end

                -- mark field writable
                if name then
                    local watches       = rawget(self, Watch)
                    if not watches then
                        watches         = {}
                        rawset(self, Watch, watches)
                    end
                    if watches[name] then
                        watches[name]:Dispose()
                    end
                    watches[name]       = false

                -- mark whole proxy writable
                else
                    rawset(self, Observer, false)
                    releaseSubWatches(self, false)
                end
            end,

            disposeWatches              = function(self)
                -- dispose value watches
                local watches           = rawget(self, Watch)
                if watches then
                    for k, v in pairs(watches) do
                        if v then v:Dispose() end
                    end
                    rawset(self, Watch, nil)
                end

                -- release deep watch subscription
                local subscription      = rawget(self, Subscription)
                if subscription then
                    subscription:Dispose()
                    rawset(self, Subscription, nil)
                end

                -- dispose child proxyes
                local proxyes           = rawget(self, ReactiveProxy)
                if proxyes then
                    if proxyes[0] then proxyes[0]:Dispose() end
                    for name, proxy in pairs(proxyes) do
                        proxy:Dispose()
                    end
                    rawset(self, ReactiveProxy, nil)
                end
            end,

            IObservable, Watch, TaskScheduler, Observer, Exception, Subscription,
            Reactive, ReactiveList, ReactiveDictionary, ReactiveValue, ReactiveField
        }

        -----------------------------------------------------------------------
        --                            inner type                             --
        -----------------------------------------------------------------------
        --- The proxy used in watch environment for reactive list
        __Sealed__()
        class "ReactiveListProxy"       (function(_ENV)
            extend "IIndexedList"

            export                      {
                rawset                  = rawset,
                rawget                  = rawget,
                type                    = type,
                isobjecttype            = Class.IsObjectType,
                yield                   = coroutine.yield,
                setvalue                = Toolset.setvalue,
                stackmod                = Platform.ENABLE_TAIL_CALL_OPTIMIZATIONS and 0 or 1,

                unwrap                  = function(value)
                    if isobjecttype(value, IReactive) then
                        return value.Value
                    else
                        return value
                    end
                end,

                unwrapAll               = function(value, ...)
                    if select("#", ...) == 0 then return end
                    if isobjecttype(value, IReactive) then
                        return value.Value, unwrapAll(...)
                    else
                        return value, unwrapAll(...)
                    end
                end,

                handleReturn            = function(ok, ...)
                    if not ok then error((...), stackmod + 2) end
                    return unwrapAll(...)
                end,

                addDeepWatch            = addDeepWatch,
                makeWritable            = makeWritable,

                Observer, Reactive, ReactiveList, ReactiveListProxy, IReactive
            }

            -------------------------------------------------------------------
            --                           property                            --
            -------------------------------------------------------------------
            --- The item count
            property "Count"                { get = function(self) return rawget(self, Reactive).Count end }

            -----------------------------------------------------------------------
            --                              method                               --
            -----------------------------------------------------------------------
            --- Gets the iterator
            __Iterator__()
            function GetIterator(self)
                local list                  = rawget(self, Reactive)
                for i, v in list:GetIterator() do
                    if isobjecttype(v, IReactive) then
                        yield(i, v.Value)
                    else
                        yield(i, v)
                    end
                end
            end

            --- Push
            function Push(self, ...)
                makeWritable(self)
                local react                 = rawget(self, Reactive)
                local ok, err               = pcall(react.Push, react, ...)
                if not ok then error(err, 2) end
                return err
            end

            --- Pop
            function Pop(self)
                makeWritable(self)
                return unwrap(rawget(self, Reactive):Pop())
            end

            --- Shift
            function Shift(self)
                makeWritable(self)
                return unwrap(rawget(self, Reactive):Shift())
            end

            --- Unshift
            function Unshift(self, ...)
                makeWritable(self)
                local react                 = rawget(self, Reactive)
                local ok, err               = pcall(react.Unshift, react, ...)
                if not ok then error(err, 2) end
                return err
            end

            --- Splice
            function Splice(self, ...)
                makeWritable(self)
                local react                 = rawget(self, Reactive)
                return handleReturn(pcall(react.Splice, react, ...))
            end

            --- Insert an item to the list
            function Insert(self, ...)
                makeWritable(self)
                local react                 = rawget(self, Reactive)
                local ok, err               = pcall(react.Insert, react, ...)
                if not ok then error(err, 2) end
                return err
            end

            --- Whether an item existed in the list
            function Contains(self, item)   return rawget(self, Reactive):IndexOf(item) and true or false end

            --- Get the index of the item if it existed in the list
            function IndexOf(self, item)    return rawget(self, Reactive):IndexOf(item) end

            --- Remove an item
            function Remove(self, ...)
                makeWritable(self)
                return unwrap(rawget(self, Reactive):Remove(...))
            end

            --- Remove an item from the tail or the given index
            function RemoveByIndex(self, ...)
                makeWritable(self)
                return unwrap(rawget(self, Reactive):RemoveByIndex(...))
            end

            --- Clear the list
            function Clear(self)
                makeWritable(self)
                return unwrap(rawget(self, Reactive):Clear())
            end

            -------------------------------------------------------------------
            --                          constructor                          --
            -------------------------------------------------------------------
            function __ctor(self, observer, react, parent)
                rawset(self, Observer, observer)
                rawset(self, Reactive, react)
                rawset(self, IObservable, parent)
                addDeepWatch(self, react)
            end

            __dtor                          = disposeWatches

            -------------------------------------------------------------------
            --                          meta method                          --
            -------------------------------------------------------------------
            function __index(self, index)
                if type(index) == "number" then
                    return unwrap(rawget(self, Reactive)[index])
                end
            end

            function __newindex(self, index, value, stack)
                makeWritable(self)
                local ok, err               = pcall(setvalue, rawget(self, Reactive), index, value)
                if not ok then error(err, (stack or 1) + 1) end
            end

            function __len(self)        return rawget(self, Reactive).Count end
        end)

        --- The proxy used in watch environment for reactive dictionary
        __Sealed__()
        class "ReactiveDictionaryProxy" (function(_ENV)
            extend "IKeyValueDict"

            export                      {
                rawset                  = rawset,
                rawget                  = rawget,
                pcall                   = pcall,
                error                   = error,
                setvalue                = Toolset.setvalue,

                addDeepWatch            = addDeepWatch,
                makeWritable            = makeWritable,

                Reactive
            }

            -----------------------------------------------------------------------
            --                              method                               --
            -----------------------------------------------------------------------
            --- Get iterators
            function GetIterator(self)
                return rawget(self, Reactive):GetIterator()
            end

            -----------------------------------------------------------------------
            --                            constructor                            --
            -----------------------------------------------------------------------
            function __ctor(self, observer, react, parent)
                rawset(self, Observer, observer)
                rawset(self, Reactive, react)
                rawset(self, IObservable, parent)
                addDeepWatch(self, react)
            end

            __dtor                      = disposeWatches

            -----------------------------------------------------------------------
            --                            meta-method                            --
            -----------------------------------------------------------------------
            function __index(self, key)
                return rawget(self, Reactive)[key]
            end

            function __newindex(self, key, value, stack)
                makeWritable(self)
                local ok, err           = pcall(setvalue, rawget(self, Reactive), key, value)
                if not ok then error(err, (stack or 1) + 1) end
            end
        end)

        --- The proxy used in watch environment for reactives
        __Sealed__()
        class "ReactiveProxy"           (function(_ENV)
            export                      {
                rawset                  = rawset,
                rawget                  = rawget,
                type                    = type,
                pcall                   = pcall,
                pairs                   = pairs,
                setvalue                = Toolset.setvalue,
                isobjecttype            = Class.IsObjectType,

                makeReactiveProxy       = makeReactiveProxy,
                addProxy                = addProxy,
                addWatch                = addWatch,
                addDeepWatch            = addDeepWatch,
                makeWritable            = makeWritable,

                IObservable, Observer, Watch, Reactive, ReactiveProxy
            }

            -------------------------------------------------------------------
            --                          constructor                          --
            -------------------------------------------------------------------
            function __ctor(self, observer, react, parent)
                rawset(self, Observer, observer)
                rawset(self, Reactive, react)
                rawset(self, IObservable, parent)
            end

            -------------------------------------------------------------------
            --                          meta method                          --
            -------------------------------------------------------------------
            function __index(self, key)
                if type(key) ~= "string" then return end

                -- get child proxyes
                local proxyes           = rawget(self, ReactiveProxy)
                local subject           = proxyes and proxyes[key]
                if subject then return subject end

                -- check value proxy
                local react             = rawget(self, Reactive)
                local watches           = rawget(self, Watch)
                if watches and watches[key] ~= nil then return react[key].Value end

                -- get from the source
                local value             = react[key]
                if value ~= nil then
                    -- method access - deep watch require
                    if type(value) == "function" then
                        local func      = function(_, ...) return value(react, ...) end
                        rawset(self, key, func)
                        addDeepWatch(self, react)
                        return func

                    -- make reactive
                    else
                        local r, isv    = makeReactiveProxy(rawget(self, Observer), value, self)
                        if r then
                            if isv then
                                return addWatch(self, key, r).Value
                            else
                                return addProxy(self, key, r)
                            end
                        end
                    end
                end
                return value
            end

            function __newindex(self, key, value, stack)
                if type(key) ~= "string" then rawset(self, key, value) end

                local react             = rawget(self, Reactive)
                local proxyes           = rawget(self, ReactiveProxy)
                local proxy             = proxyes and proxyes[key]
                local watches           = rawget(self, Watch)
                local watch             = watches and watches[key]

                -- make writable
                if proxy then
                    makeWritable(proxy)
                elseif watch then
                    makeWritable(self, key)
                end

                -- assignment
                local ok, err           = pcall(setvalue, react, key, value)
                if not ok then error(err, (stack or 1) + 1) end

                -- add proxy or watch
                if proxy == nil and watch == nil and rawget(self, Observer) then
                    local value         = react[key]
                    if value ~= nil then
                        local r, isv    = makeReactiveProxy(rawget(self, Observer), value, self)
                        if r then
                            if isv then
                                return makeWritable(addWatch(self, key, r))
                            else
                                return makeWritable(addProxy(self, key, r))
                            end
                        end
                    end
                end
            end

            __dtor                      = disposeWatches
        end)

        --- The watch environment to provide reactive value access
        __Sealed__()
        class "WatchEnvironment"        (function(_ENV)
            extend "IEnvironment"

            export                      {
                getValue                = Environment.GetValue,
                rawset                  = rawset,
                rawget                  = rawget,
                pairs                   = pairs,
                error                   = error,
                type                    = type,
                pcall                   = pcall,
                getmetatable            = getmetatable,
                isobjecttype            = Class.IsObjectType,
                makeReactiveProxy       = makeReactiveProxy,

                -- check the access value if observable
                parseValue              = function (self, key, value)
                    local observer      = rawget(self, Observer)
                    local proxy, isvalue= makeReactiveProxy(observer, value)

                    if proxy then
                        if isvalue then
                            local map   = rawget(self, Watch)
                            if not map then
                                map     = {}
                                rawset(self, Watch, map)
                            end
                            map[key]    = proxy
                            proxy:Subscribe(observer, observer.Subscription)
                            rawset(self, key, nil)
                            return proxy.Value
                        else
                            -- override
                            rawset(self, key, proxy)
                            return proxy
                        end
                    end

                    return value
                end,

                ReactiveProxy, ReactiveListProxy, Observer, Reactive, ReactiveList
            }

            -------------------------------------------------------------------
            --                         static method                         --
            -------------------------------------------------------------------
            --- Install global variables can't be fetched from environment
            __Static__()
            function Install(self, reactives)
                for k, v in pairs(reactives) do
                    if type(k) == "string" then
                        parseValue(self, k, v)
                    end
                end
            end

            -------------------------------------------------------------------
            --                          constructor                          --
            -------------------------------------------------------------------
            __ctor                      = Environment.SetParent

            -------------------------------------------------------------------
            --                          meta method                          --
            -------------------------------------------------------------------
            function __index(self, key)
                if type(key) ~= "string" then return nil end

                local map               = rawget(self, Watch)
                if map and map[key] then return map[key].Value end

                -- gets from the base env
                return parseValue(self, key, getValue(self, key))
            end
        end)

        --- The watch environment to provide reactive value access
        __Sealed__()
        class "RawEnvironment"          (function(_ENV)
            extend "IEnvironment"

            export                      {
                getValue                = Environment.GetValue,
                rawset                  = rawset,
                rawget                  = rawget,
                pairs                   = pairs,
                type                    = type,
                isobjecttype            = Class.IsObjectType,

                -- check the access value if observable
                parseValue              = function (self, key, value)
                    if isobjecttype(value, IReactive) then
                        local map       = rawget(self, Watch)
                        if not map then
                            map         = {}
                            rawset(self, Watch, map)
                        end
                        map[key]        = value
                        return value.Value
                    elseif isobjecttype(value, IObservable) then
                        value           = ReactiveValue(value)
                        rawset(value, RawEnvironment, self)
                        local map       = rawget(self, Watch)
                        if not map then
                            map         = {}
                            rawset(self, Watch, map)
                        end
                        map[key]        = value
                        return value.Value
                    else
                        rawset(self, key, value)
                        return value
                    end
                end,

                Watch, IReactive, IObservable, ReactiveValue, RawEnvironment
            }

            -------------------------------------------------------------------
            --                         static method                         --
            -------------------------------------------------------------------
            --- Install global variables can't be fetched from environment
            __Static__()
            function Install(self, reactives)
                for k, v in pairs(reactives) do
                    if type(k) == "string" then
                        parseValue(self, k, v)
                    end
                end
            end

            -------------------------------------------------------------------
            --                          constructor                          --
            -------------------------------------------------------------------
            __ctor                      = Environment.SetParent

            -------------------------------------------------------------------
            --                          destructor                           --
            -------------------------------------------------------------------
            function __dtor(self)
                local map               = rawget(self, Watch)
                if map then
                    for k, v in pairs(map) do
                        if rawget(v, RawEnvironment) == self then
                            v:Dispose()
                        end
                    end
                end
            end

            -------------------------------------------------------------------
            --                          meta method                          --
            -------------------------------------------------------------------
            function __index(self, key)
                if type(key) ~= "string" then return nil end

                local map               = rawget(self, Watch)
                if map and map[key] then return map[key].Value end

                -- gets from the base env
                return parseValue(self, key, getValue(self, key))
            end
        end)

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        __Arguments__{ Function, Table/nil, Table/nil }
        function __ctor(self, func, env, reactives )
            super(self)

            local watchObj
            -- check the given reactive
            if reactives and getmetatable(reactives) then
                if isobjecttype(reactives, IReactive) then
                    watchObj            = reactives
                elseif isobjecttype(reactives, IObservable) then
                    watchObj            = ReactiveValue(reactives)
                end
            end

            -- build the watch environment
            local watchEnv, observer
            local processing            = false
            local function onNext(res, ...)
                processing              = false
                if res then return self:OnNext(...) end
                return res, ...
            end

            if watchObj then
                watchEnv                = RawEnvironment(env)
                observer                = Observer(function()
                    if processing then return end
                    processing          = true
                    return TaskScheduler.Default:QueueTask(function()
                        local ok, err   = onNext(pcall(func, watchEnv, watchObj.Value))
                        if ok == false then self:OnError(Exception(err)) end
                    end)
                end)
                processing              = true
                watchObj:Subscribe(observer, observer.Subscription)
                processing              = false
            else
                watchEnv                = WatchEnvironment(env)
                observer                = Observer(function()
                    if processing then return end
                    processing          = true
                    return TaskScheduler.Default:QueueTask(function()
                        local ok, err   = onNext(pcall(func, watchEnv, watchObj))
                        if ok == false then self:OnError(Exception(err)) end
                    end)
                end)

            end

            -- apply and call for subscription
            rawset(self,     Observer, observer)
            rawset(watchEnv, Observer, observer)

            -- install the reactives
            if not watchObj and reactives and getmetatable(reactives) == nil then
                WatchEnvironment.Install(watchEnv, reactives)
            end

            setfenv(func, watchEnv)
            return observer:OnNext()
        end

        -----------------------------------------------------------------------
        --                          de-constructor                           --
        -----------------------------------------------------------------------
        function __dtor(self) return rawget(self, Observer):Dispose() end
    end)

    --- The watch keyword
    do
        export {
            type                        = type,
            error                       = error,
            pairs                       = pairs,
            rawset                      = rawset,
            getKeywordVisitor           = Environment.GetKeywordVisitor,
            isobjecttype                = Class.IsObjectType,
            getmetatable                = getmetatable,
            _G                          = _G,

            IObservable, Watch.RawEnvironment, Watch.WatchEnvironment, Environment
        }

        function watch(reactives, func, env)
            if type(reactives) == "function" then
                func, env, reactives    = reactives, func, nil
            end

            if type(func) ~= "function" then
                error("Usage: watch([reactives, ]func[, environment]) - The func must be a function", 2)
            end

            if reactives and (type(reactives) ~= "table" or getmetatable(reactives) ~= nil and not isobjecttype(reactives, IObservable)) then
                error("Usage: watch([reactives, ]func[, environment]) - The reactives must be a table contains key-values or an observable", 2)
            end

            local visitor               = getKeywordVisitor(watch)
            if isobjecttype(visitor, RawEnvironment) or isobjecttype(visitor, WatchEnvironment) then
                error("Usage: watch([reactives, ]func[, environment]) - watch can't be used inside another watch", 2)
            end

            if type(env) == "table" and env ~= visitor and env ~= _G then
                visitor                 = Environment(env, visitor)
            end

            return Watch(func, visitor, reactives)
        end

        Environment.RegisterGlobalKeyword { watch = watch }
    end
end)