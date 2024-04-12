--===========================================================================--
--                                                                           --
--                           System.Reactive.Watch                           --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2023/04/20                                               --
-- Update Date  :   2024/04/12                                               --
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
            makeReactiveProxy           = function (observer, value)
                local cls               = value and getobjectclass(value)
                if not (cls and issubtype(cls, IObservable)) then return end

                -- Subscribe for reactive field
                if issubtype(cls, Reactive) then
                    return ReactiveProxy(observer, value)

                -- Subscribe the list
                elseif issubtype(cls, ReactiveList) then
                    return ReactiveListProxy(observer, value)

                -- Add proxy to acess the real value
                else
                    -- convert the observable to behavior subject
                    return issubtype(cls, BehaviorSubject) and value or BehaviorSubject(value), true
                end
            end,

            -- use deep watch
            addDeepWatch                = function(self, observable)
                local observer          = rawget(self, Observer)
                if observer and not rawget(self, Subscription) then
                    rawset(self, Observer, nil)
                    rawset(self, Subscription, observable:Subscribe(observer, Subscription(observer.Subscription)))
                    return releaseSubWatches(self)
                end
            end,

            -- add value watch
            addWatch                    = function(self, observable)
                local observer          = rawget(self, Observer)
                if observer and not rawget(self, Subscription) then
                    local subscription  = rawget(self, ISubscription)
                    if not subscription then
                        subscription    = Subscription(observer.Subscription)
                        rawset(self, ISubscription, subscription)
                    end

                    return observable:Subscribe(observer, subscription)
                end
            end,

            -- release child subscription
            releaseSubWatches           = function (self)
                -- dispose value watches
                local sub               = rawget(self, ISubscription)
                if sub then
                    rawset(self, ISubscription, nil)
                    sub:Dispose()
                end

                -- dispose child proxy watches
                for k, v in pairs(self) do
                    local cls           = type(k) == "string" and getobjectclass(v)
                    if cls and (issubtype(cls, ReactiveProxy) or issubtype(cls, ReactiveList)) then
                        rawset(v, Observer, nil)
                        sub             = rawget(v, Subscription)
                        if sub then
                            rawset(v, Subscription, nil)
                            sub:Dispose()
                        end
                        releaseSubWatches(v)
                    end
                end
            end,

            disposeWatches              = function(self)
                -- release subscription for sub values
                local subscription      = rawget(self, ISubscription)
                if subscription then subscription:Dispose() end

                -- release deep watch subscription
                subscription            = rawget(self, Subscription)
                return subscription and subscription:Dispose()
            end,

            IObservable, ISubscription,
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
                addWatch                = addWatch,

                Observer, Reactive, Watch
            }

            -------------------------------------------------------------------
            --                          constructor                          --
            -------------------------------------------------------------------
            function __ctor(self, observer, react)
                rawset(self, Observer, observer)
                rawset(self, Reactive, react)
            end

            -------------------------------------------------------------------
            --                          meta method                          --
            -------------------------------------------------------------------
            function __index(self, key)
                if type(key) ~= "string" then return end

                -- check behaviour subjects
                local watches           = rawget(self, Watch)
                local subject           = watches and watches[key]
                if subject then return subject:GetValue() end

                -- get from the source
                local react             = rawget(self, Reactive)
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
                        local r, isv    = makeReactiveProxy(rawget(self, Observer), value)
                        if r then
                            if isv then
                                if not watches then
                                    watches = {}
                                    rawset(self, Watch, watches)
                                end
                                watches[key]= r
                                addWatch(self, r)
                                return r:GetValue()
                            else
                                -- access directly
                                rawset(self, key, r)
                            end
                            return r
                        end
                    end
                end
                return value
            end

            function __newindex(self, key, value)
                error("The reactive proxy is readonly", 2)
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
                addWatch                = addWatch,
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

            __dtor                      = disposeWatches
        end)

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
                            return proxy:GetValue()
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
                if map and map[key] then return map[key]:GetValue() end

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

            local function onNext(self, res, ...)
                processing              = false
                if res then return self:OnNext(...) end
                return res, ...
            end

            local observer              = Observer(function()
                if processing then return end
                processing              = true
                local ok, err
                if isValueObj then
                    ok, err             = onNext(self, pcall(func, watchEnv, watchObj:GetValue()))
                else
                    ok, err             = onNext(self, pcall(func, watchEnv, watchObj))
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

        function __len(self)            return rawget(self, ReactiveList).Count end

        -----------------------------------------------------------------------
        --                          de-constructor                           --
        -----------------------------------------------------------------------
        function __dtor(self) return self:OnCompleted() or rawget(self, Observer):Dispose() end
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