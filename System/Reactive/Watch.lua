--===========================================================================--
--                                                                           --
--                           System.Reactive.Watch                           --
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
            setfenv                     = _G.setfenv or _G.debug and _G.debug.setfenv or Toolset.fakefunc,
            getobjectclass              = Class.GetObjectClass,
            issubtype                   = Class.IsSubType,

            -- check the access value if observable
            makeReactiveProxy           = function (observer, value, parent)
                local cls               = value and getobjectclass(value)
                if not (cls and issubtype(cls, IObservable)) then return end

                -- deep watch check
                if observer and parent and rawget(parent, Subscription) then
                    observer            = nil
                end

                -- Subscribe for reactive field
                if issubtype(cls, Reactive) then
                    return ReactiveProxy(observer, value, parent)

                -- Subscribe the list
                elseif issubtype(cls, ReactiveList) then
                    return ReactiveListProxy(observer, value, parent)

                -- Add proxy to acess the real value
                elseif issubtype(cls, BehaviorSubject) then
                    return value, true

                -- convert the observable to behavior subject
                elseif not parent then
                    return BehaviorSubject(value), true
                end
            end,

            -- add reactive proxy
            addProxy                    = function(self, key, proxy)
                local proxyes           = rawget(self, ReactiveProxy)
                if not proxyes then
                    proxyes             = {}
                    rawset(self, ReactiveProxy, proxyes)
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

            -- release deep watch
            releaseDeepWatch            = function(self)
                local observer          = rawget(self, Observer)

                -- release watches
                rawset(self, Watch, nil)

                -- dispose child proxy watches
                local proxyes           = rawget(self, ReactiveProxy)
                if proxyes then
                    for _, proxy in pairs(proxyes) do
                        if rawget(proxy, Observer) ~= false then
                            -- enable subscribe
                            rawset(proxy, Observer, observer)
                            releaseDeepWatch(proxy)
                        end
                    end
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
                subscription            = rawget(self, Subscription)
                if subscription then
                    subscription:Dispose()
                    rawset(self, Subscription, nil)
                end

                -- dispose child proxyes
                local proxyes           = rawget(self, ReactiveProxy)
                if proxyes then
                    for name, proxy in pairs(proxyes) do
                        proxy:Dispose()
                    end
                    rawset(self, ReactiveProxy, nil)
                end
            end,

            IObservable, Watch,
            Observer, Exception, BehaviorSubject, Reactive, ReactiveList, Subscription
        }

        -----------------------------------------------------------------------
        --                            inner type                             --
        -----------------------------------------------------------------------
        --- The proxy used in watch environment for reactives
        __Sealed__()
        class "ReactiveProxy"           (function(_ENV)
            export                      {
                rawset                  = rawset,
                rawget                  = rawget,
                type                    = type,
                makeReactiveProxy       = makeReactiveProxy,
                addDeepWatch            = addDeepWatch,
                releaseDeepWatch        = releaseDeepWatch,
                addWatch                = addWatch,
                addProxy                = addProxy,
                makeWritable            = makeWritable,
                setraw                  = Reactive.SetRaw,
                isobjecttype            = Class.IsObjectType,
                setvalue                = function(self, key, value) self[key] = value end,

                IObservable, Observer, Reactive, ReactiveProxy, Watch
            }

            -------------------------------------------------------------------
            --                         static method                         --
            -------------------------------------------------------------------
            __Static__()
            function GetReactive(self, setraw)
                if not isobjecttype(self, ReactiveProxy) then return self end
                local react             = rawget(self, Reactive)
                if setraw then
                    releaseDeepWatch(self)
                else
                    addDeepWatch(self, react)
                end
                return react
            end

            -------------------------------------------------------------------
            --                          constructor                          --
            -------------------------------------------------------------------
            function __ctor(self, observer, react, parent)
                rawset(self, IObservable, parent)
                rawset(self, Observer, observer)
                rawset(self, Reactive, react)
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

                -- check behaviour subjects
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

            function __newindex(self, key, value)
                if type(key) ~= "string" then rawset(self, key, value) end

                -- assign to proxy
                local proxyes           = rawget(self, ReactiveProxy)
                local proxy             = proxyes and proxyes[key]
                if proxy then
                    makeWritable(proxy)
                    setraw(rawget(proxy, Reactive), value, 2)
                    return
                end

                -- assign to value
                local react             = rawget(self, Reactive)
                local watches           = rawget(self, Watch)
                local watch             = watches and watches[key]
                if watch then makeWritable(self, key) end

                -- assignment
                local ok, err           = pcall(setvalue, react, key, value)
                if not ok then error(err, 2) end

                -- add proxy
                if watch == nil and rawget(self, Observer) then
                    local value         = react[key]
                    if value ~= nil then
                        local r, isv    = makeReactiveProxy(rawget(self, Observer), value, self)
                        if r then
                            if isv then
                                return makeWritable(self, key)
                            else
                                return makeWritable(addProxy(self, key, r))
                            end
                        end
                    end
                end
            end

            __dtor                      = disposeWatches
        end)

        --- The proxy used in watch environment for reactive list
        __Sealed__()
        class "ReactiveListProxy"       (function(_ENV)
            extend "IIndexedList"

            export                      {
                rawset                  = rawset,
                rawget                  = rawget,
                type                    = type,
                isObjectType            = Class.IsObjectType,
                yield                   = coroutine.yield,
                makeReactiveProxy       = makeReactiveProxy,
                addDeepWatch            = addDeepWatch,
                releaseDeepWatch        = releaseDeepWatch,
                newtable                = Toolset.newtable,

                Observer, Reactive, ReactiveList, ReactiveListProxy
            }

            local function parseValue(self, value)
                if type(value) == "table" then
                    local proxy         = rawget(self, ReactiveProxy)
                    local react, isval  = proxy[value]
                    if react ~= nil then return react or value end

                    react, isval        = makeReactiveProxy(rawget(self, Observer), value)
                    proxy[value]        = react or false
                    return react or value
                else
                    return value
                end
            end


            -------------------------------------------------------------------
            --                         static method                         --
            -------------------------------------------------------------------
            __Static__()
            function GetReactive(self, setraw)
                if not isobjecttype(self, ReactiveListProxy) then return self end
                local react             = rawget(self, ReactiveList)
                if setraw then
                    releaseDeepWatch(self)
                else
                    addDeepWatch(self, react)
                end
                return react
            end

            -------------------------------------------------------------------
            --                           property                            --
            -------------------------------------------------------------------
            --- The item count
            property "Count"                { get = function(self) return rawget(self, ReactiveList).Count end }

            -----------------------------------------------------------------------
            --                              method                               --
            -----------------------------------------------------------------------
            --- Gets the iterator
            __Iterator__()
            function GetIterator(self)
                local list                  = rawget(self, ReactiveList)
                for i, v in list:GetIterator() do
                    yield(i, parseValue(self, v))
                end
            end

            --- Whether an item existed in the list
            function Contains(self, item)   return rawget(self, ReactiveList):Contains(item) end

            --- Get the index of the item if it existed in the list
            function IndexOf(self, item)    return rawget(self, ReactiveList):IndexOf(item) end

            -------------------------------------------------------------------
            --                          constructor                          --
            -------------------------------------------------------------------
            function __ctor(self, observer, react)
                rawset(self, Observer, observer)
                rawset(self, ReactiveList, react)
                rawset(self, ReactiveListProxy, newtable(true))
                addDeepWatch(self, react)
            end

            -------------------------------------------------------------------
            --                          meta method                          --
            -------------------------------------------------------------------
            function __index(self, key)
                return type(key) == "number" and parseValue(self, rawget(self, ReactiveList)[key])
            end

            function __newindex(self, key, value)
                error("The reactive proxy is readonly", 2)
            end

            function __len(self)        return rawget(self, ReactiveList).Count end

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

                BehaviorSubject, ReactiveProxy, ReactiveListProxy, Observer, Reactive, ReactiveList
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

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        __Arguments__{ Function, Table/nil, Table/nil }
        function __ctor(self, func, env, reactives )
            super(self)

            -- gets the func environment
            local watchEnv              = WatchEnvironment(env)
            local watchObj, isValueObj

            -- observer
            local processing            = false

            local function onNext(res, ...)
                processing              = false
                if res then return self:OnNext(...) end
                return res, ...
            end

            local observer              = Observer(function(...)
                if processing then return end
                processing              = true
                local ok, err
                if isValueObj then
                    ok, err             = onNext(pcall(func, watchEnv, watchObj.Value))
                else
                    ok, err             = onNext(pcall(func, watchEnv, watchObj))
                end
                if ok == false then self:OnError(Exception(err)) end
            end)
            rawset(self,     Observer, observer)
            rawset(watchEnv, Observer, observer)

            -- install the reactives
            if reactives then
                if getmetatable(reactives) == nil then
                    WatchEnvironment.Install(watchEnv, reactives)
                else
                    watchObj, isValueObj= makeReactiveProxy(observer, reactives)
                    if isValueObj then
                        watchObj:Subscribe(observer, observer.Subscription)
                    end
                end
            end

            -- apply and call for subscription
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
            getKeywordVisitor           = Environment.GetKeywordVisitor,
            isObjectType                = Class.IsObjectType,
            getmetatable                = getmetatable,

            IObservable
        }

        function watch(reactives, func)
            if type(reactives) == "function" then
                func, reactives         = reactives, nil
            end

            if type(func) ~= "function" then
                error("Usage: watch([reactives, ]func) - The func must be a function", 2)
            end

            if reactives and (type(reactives) ~= "table" or getmetatable(reactives) ~= nil and not isObjectType(reactives, IObservable)) then
                error("Usage: watch([reactives, ]func) - The reactives must be a table or observable", 2)
            end

            return Watch(func, getKeywordVisitor(watch), reactives)
        end

        Environment.RegisterGlobalKeyword { watch = watch }
    end
end)