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

        export                          {
            getValue                    = Environment.GetValue,
            saveValue                   = Environment.SaveValue,
            isObjectType                = Class.IsObjectType,
            getObjectClass              = Class.GetObjectClass,
            setParent                   = Environment.SetParent,
            rawset                      = rawset,
            rawget                      = rawget,
            pcall                       = pcall,
            setfenv                     = _G.setfenv or Toolset.fakefunc,

            Watch, Reactive, BehaviorSubject, Observer, Exception
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
                    local observable    = reactive(key)
                    if observable then
                        local observer  = rawget(self, Observer)

                        if isObjectType(observable, Reactive) then
                            local proxy = ReactiveProxy(observer, observable)
                            rawset(self, key, proxy)
                            return proxy
                        end

                        proxy[key]      = true

                        observable:Subscribe(observer)
                    end
                end
                return reactive[key]
            end

            function __newindex(self, key, value)
                error("The reactive data is readonly", 2)
            end
        end)

        __Sealed__()
        class "WatchSubject"            (function(_ENV)
            inherit "BehaviorSubject"

            export                      {
                rawset                  = rawset,
                rawget                  = rawget,
                WatchSubject, Watch, Observer
            }

            -------------------------------------------------------------------
            --                          constructor                          --
            -------------------------------------------------------------------
            function __ctor(self, watch)
                super(self)
                rawset(self, Watch, watch)
            end

            function __dtor(self)
                rawget(rawget(self, Watch), Observer):Unsubscribe()
            end
        end)

        __Sealed__()
        class "WatchEnvironment"        (function(_ENV)
            extend "IEnvironment"

            export                      {
                getValue                = Environment.GetValue,
                saveValue               = Environment.SaveValue,
                isObjectType            = Class.IsObjectType,
                getObjectClass          = Class.GetObjectClass,
                rawset                  = rawset,
                rawget                  = rawget,
                pcall                   = pcall,
                setfenv                 = _G.setfenv or Toolset.fakefunc,
            }

            -------------------------------------------------------------------
            --                          constructor                          --
            -------------------------------------------------------------------
            __ctor                      = Environment.SetParent

            -------------------------------------------------------------------
            --                          meta method                          --
            -------------------------------------------------------------------
            function __index(self, key)
                local watches               = rawget(self, Watch)
                if watches and watches[key] then return watches[key]:GetValue() end

                local value                 = getValue(self, key)
                if value then
                    if isObjectType(value, Reactive) then
                        value               = ReactiveProxy(rawget(self, Observer), value)
                        rawset(self, key, value)
                    elseif isObjectType(value, BehaviorSubject) then
                        if not watches then
                            watches         = {}
                            rawset(self, Watch, watches)
                        end
                        watches[key]        = value
                        value:Subscribe(rawget(self, Observer))
                        rawset(self, key, nil)
                        return value:GetValue()
                    end
                end
                return value
            end
        end)

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        __Arguments__{ Function, Table/nil, Table/nil }
        function __ctor(self, func, env, reactives)
            local watchEnv              = WatchEN

            -- parent
            setParent(self, env)

            -- subject chain
            local subject               = WatchSubject(self)
            local processing            = false
            local observer              = Observer(function()
                if processing then return end
                processing              = true
                local ok, err           = onNext(subject, pcall(func, self))
                processing              = false
                if ok == false then subject:OnError(Exception(err)) end
            end)
            rawset(self, Observer, observer)
            rawset(self, WatchSubject, subject)

            -- apply and call
            setfenv(func, self)
            return observer:OnNext()
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