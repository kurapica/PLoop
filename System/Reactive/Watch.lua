--===========================================================================--
--                                                                           --
--                           System.Reactive.Watch                           --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2023/04/20                                               --
-- Update Date  :   2023/04/20                                               --
-- Version      :   1.0.0                                                    --
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

            Observer, Exception
        }

        local function onNext(subject, res, ...)
            if res then return subject:OnNext(...) end
            return res, ...
        end

        -----------------------------------------------------------------------
        --                            inner type                             --
        -----------------------------------------------------------------------
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
            function __ctor(self, observer, reactive)
                rawset(self, Observer, observer)
                rawset(self, Reactive, reactive)
                rawset(self, ReactiveProxy, {})
            end

            -------------------------------------------------------------------
            --                          meta method                          --
            -------------------------------------------------------------------
            function __index(self, key)
                local reactive          = rawget(self, Reactive)
                local proxy             = rawget(self, ReactiveProxy)

                if not proxy[key] then
                    local observer      = rawget(self, Observer)
                    local observable    = reactive(key)
                    if observable then
                        proxy[key]      = true
                        observable:Subscribe(observer)
                    else
                        observable      = reactive[key]
                        if observable and isObjectType(observable, Reactive) then
                            local proxy = ReactiveProxy(observer, observable)
                            rawset(self, key, proxy)
                            return proxy
                        end
                    end
                end

                return reactive[key]
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

                Environment, ReactiveProxy, Observer
            }

            local function parseValue(self, key, value)
                if not value then return value end

                if type(value) == "table" then
                    -- use reactive to wrap the value for simple
                    local react         = reactive(value, true)

                    if isObjectType(react, Reactive) then
                        value           = ReactiveProxy(rawget(self, Observer), react)
                        rawset(self, key, value)
                    elseif isObjectType(react, BehaviorSubject) then
                        local watches   = rawget(self, Watch)
                        if not watches then
                            watches     = {}
                            rawset(self, Watch, watches)
                        end
                        watches[key]    = react
                        react:Subscribe(rawget(self, Observer))
                        rawset(self, key, nil)
                        return react:GetValue()
                    end
                end

                return value
            end

            -------------------------------------------------------------------
            --                         static method                         --
            -------------------------------------------------------------------
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
        __Arguments__{ Function, Table/nil, Table/nil }
        function __ctor(self, func, env, reactives)
            super(self)

            -- gets the func environment
            local watchEnv              = WatchEnvironment(env)

            -- subject chain
            local processing            = false
            local observer              = Observer(function()
                if processing then return end
                processing              = true
                local ok, err           = onNext(self, pcall(func, watchEnv))
                processing              = false
                if ok == false then self:OnError(Exception(err)) end
            end)
            rawset(self, Observer, observer)
            rawset(watchEnv, Observer, observer)

            -- install the reactives
            if reactives then
                WatchEnvironment.Install(watchEnv, reactives)
            end

            -- apply and call
            setfenv(func, watchEnv)
            return observer:OnNext()
        end

        -- dispose
        function __dtor(self)
            rawget(self, Observer):Unsubscribe()
        end
    end)

    --- The watch keyword
    do
        export {
            type                        = type,
            error                       = error,
            getKeywordVisitor           = Environment.GetKeywordVisitor,

            BehaviorSubject
        }

        function watch(reactives, func)
            if type(reactives) == "function" then
                func, reactives         = reactives
            end

            if type(func) ~= "function" then
                error("Usage: watch([reactives, ]func) - The func must be a function", 2)
            end

            if reactives and type(reactives) ~= "table" then
                error("Usage: watch([reactives, ]func) - The reactives must be a table", 2)
            end

            return Watch(func, getKeywordVisitor(watch), reactives)
        end

        Environment.RegisterGlobalKeyword { watch = watch }
    end
end)