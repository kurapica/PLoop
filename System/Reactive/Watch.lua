--===========================================================================--
--                                                                           --
--                           System.Reactive.Watch                           --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2023/04/20                                               --
-- Update Date  :   2023/10/20                                               --
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
            setfenv                     = _G.setfenv or _G.debug and _G.debug.setfenv or Toolset.fakefunc,

            Observer, Exception, List, Boolean
        }

        local function onNext(subject, res, ...)
            if res then return subject:OnNext(...) end
            return res, ...
        end

        -----------------------------------------------------------------------
        --                            inner type                             --
        -----------------------------------------------------------------------
        --- The proxy used in watch environment for reactives
        __Sealed__()
        class "ReactiveProxy"           (function(_ENV)
            export                      {
                rawset                  = rawset,
                rawget                  = rawget,
                isObjectType            = Class.IsObjectType,

                Observer, Reactive, ReactiveProxy
            }

            -------------------------------------------------------------------
            --                          constructor                          --
            -------------------------------------------------------------------
            function __ctor(self, observer, react)
                rawset(self, Observer, observer)
                rawset(self, Reactive, react)
                rawset(self, ReactiveProxy, {})
            end

            -------------------------------------------------------------------
            --                          meta method                          --
            -------------------------------------------------------------------
            function __index(self, key)
                local react             = rawget(self, Reactive)
                local proxy             = rawget(self, ReactiveProxy)

                if not proxy[key] then
                    local observer      = rawget(self, Observer)
                    local observable    = react(key)
                    if observable then
                        proxy[key]      = true
                        observable:Subscribe(observer, observer.Subscription)
                    else
                        observable      = react[key]
                        if observable and isObjectType(observable, Reactive) then
                            local proxy = ReactiveProxy(observer, observable)
                            rawset(self, key, proxy)
                            return proxy
                        end
                    end
                end

                return react[key]
            end

            function __newindex(self, key, value)
                error("The reactive data is readonly", 2)
            end
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

                Observer, Reactive, ReactiveList, ReactiveListProxy, Toolset, Watch
            }

            local function parseValue(self, value)
                if type(value) == "table" then
                    local proxy         = rawget(self, ReactiveProxy)
                    local react         = proxy[value]
                    if react ~= nil then return react or value end

                    react               = reactive(value, false)
                    local observer      = rawget(self, Observer)

                    -- Subscribe for reactive field
                    if isObjectType(react, Reactive) then
                        react           = ReactiveProxy(observer, react)
                        rawset(proxy, value, react)
                        return react

                    -- Subscribe the list
                    elseif isObjectType(react, ReactiveList) then
                        react           = ReactiveListProxy(observer, react)
                        rawset(proxy, value, react)
                        react:Subscribe(observer, observer.Subscription)
                        return react

                    -- Add proxy to acess the real value
                    elseif isObjectType(react, BehaviorSubject) then
                        rawset(proxy, value, false)
                        return react
                    end
                else
                    return value
                end
            end

            -----------------------------------------------------------------------
            --                              method                               --
            -----------------------------------------------------------------------
            --- Gets the iterator
            __Iterator__()
            function GetIterator(self)
                local list                  = rawget(self, ReactiveList)
                for i, v in (list.GetIterator or ipairs)(list) do
                    yield(i, parseValue(self, v))
                end
            end

            --- Whether an item existed in the list
            function Contains(self, item)   for i, chk in self:GetIterator() do if chk == item then return true end end return false end

            --- Get the index of the item if it existed in the list
            function IndexOf(self, item)    for i, chk in self:GetIterator() do if chk == item then return i end end end

            -----------------------------------------------------------------------
            --                           extend method                           --
            -----------------------------------------------------------------------
            for key, method, isstatic in Class.GetMethods(IList) do
                if not isstatic then
                    _ENV[key]           = method
                end
            end

            -------------------------------------------------------------------
            --                          constructor                          --
            -------------------------------------------------------------------
            function __ctor(self, observer, react)
                rawset(self, Observer, observer)
                rawset(self, ReactiveList, react)
                rawset(self, ReactiveProxy, Toolset.newtable(true))
                react:Subscribe(observer, observer.Subscription)
            end

            -------------------------------------------------------------------
            --                          meta method                          --
            -------------------------------------------------------------------
            function __index(self, key)
                return parseValue(self, rawget(self, ReactiveList)[key])
            end

            function __newindex(self, key, value)
                error("The reactive data is readonly", 2)
            end
        end)

        __Sealed__()
        class "WatchEnvironment"        (function(_ENV)
            extend "IEnvironment"

            export                      {
                getValue                = Environment.GetValue,
                isObjectType            = Class.IsObjectType,
                getObjectClass          = Class.GetObjectClass,
                rawset                  = rawset,
                rawget                  = rawget,
                pairs                   = pairs,
                error                   = error,
                type                    = type,
                pcall                   = pcall,
                getmetatable            = getmetatable,

                Environment, ReactiveProxy, Observer, Reactive, ReactiveList
            }

            local function parseValue(self, key, value)
                if not value then return value end

                if type(value) == "table" and getmetatable(value) ~= nil then
                    -- use reactive to wrap the value for simple
                    local react         = reactive(value, true)
                    local observer      = rawget(self, Observer)

                    -- Subscribe for reactive field
                    if isObjectType(react, Reactive) then
                        value           = ReactiveProxy(observer, react)
                        rawset(self, key, value)

                    -- Subscribe the list
                    elseif isObjectType(react, ReactiveList) then
                        if observer.DeepWatch then
                            value       = ReactiveListProxy(observer, react)
                            rawset(self, key, value)
                        else
                            rawset(self, key, react)
                            react:Subscribe(observer, observer.Subscription)
                            return react
                        end

                    -- Add proxy to acess the real value
                    elseif isObjectType(react, BehaviorSubject) then
                        local watches   = rawget(self, Watch)
                        if not watches then
                            watches     = {}
                            rawset(self, Watch, watches)
                        end
                        watches[key]    = react
                        react:Subscribe(observer, observer.Subscription)
                        rawset(self, key, nil)
                        return react:GetValue()
                    end
                end

                return value
            end

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

                local watches           = rawget(self, Watch)
                if watches and watches[key] then return watches[key]:GetValue() end

                -- gets from the base env
                return parseValue(self, key, getValue(self, key))
            end
        end)

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        __Arguments__{ Function, Table/nil, Table/nil, Boolean/nil }
        function __ctor(self, func, env, reactives, deep)
            super(self)

            -- gets the func environment
            local watchEnv              = WatchEnvironment(env)

            -- subject chain
            local processing            = false
            local observer              = Observer(function()
                if processing  then return end
                processing              = true
                local ok, err           = onNext(self, pcall(func, watchEnv))
                processing              = false
                if ok == false then self:OnError(Exception(err)) end
            end)
            rawset(self, Observer, observer)
            rawset(watchEnv, Observer, observer)
            observer.DeepWatch          = deep or false

            -- install the reactives
            if reactives then
                WatchEnvironment.Install(watchEnv, reactives)
            end

            -- apply and call for subscription
            setfenv(func, watchEnv)
            return observer:OnNext()
        end

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

            BehaviorSubject
        }

        function watch(reactives, func, deep)
            if type(reactives) == "function" then
                func, deep, reactives         = reactives, func, nil
            end

            if type(func) ~= "function" then
                error("Usage: watch([reactives, ]func) - The func must be a function", 2)
            end

            if reactives and type(reactives) ~= "table" then
                error("Usage: watch([reactives, ]func) - The reactives must be a table", 2)
            end

            return Watch(func, getKeywordVisitor(watch), reactives, deep and true or false)
        end

        Environment.RegisterGlobalKeyword { watch = watch }
    end
end)