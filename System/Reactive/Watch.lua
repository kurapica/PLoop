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
        extend "IEnvironment"

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
                        proxy[key]      = true

                        local observer  = rawget(self, Observer)
                        observable:Subscribe(observer)
                    end
                end
                return reactive[key]
            end

            function __newindex(self, key, value)
                error("The reactive data is readonly", 2)
            end
        end)

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        __Arguments__{ Function, Table/nil }
        function __ctor(self, func, env)
            -- parent
            setParent(self, env)

            -- subject chain
            local subject               = BehaviorSubject()
            local processing            = false
            local observer              = Observer(function()
                if processing then return end
                processing              = true
                local ok, err           = onNext(subject, pcall(func, self))
                processing              = false
                if ok == false then subject:OnError(Exception(err)) end
            end)
            rawset(self, Observer, observer)
            rawset(self, BehaviorSubject, subject)

            -- apply and call
            setfenv(func, self)
            return observer:OnNext()
        end

        -----------------------------------------------------------------------
        --                            meta method                            --
        -----------------------------------------------------------------------
        function __index(self, key)
            local value                 = getValue(self, key)
            if value and isObjectType(value, Reactive) then
                value                   = ReactiveProxy(rawget(self, Observer), value)
                rawset(self, key, value)
            end
            return value
        end

        -- Call the function and return the observable result
        function __call(self)
            return rawget(self, BehaviorSubject)
        end
    end)

    --- The watch keyword
    do
        export {
            type                        = type,
            error                       = error,

            getKeywordVisitor           = Environment.GetKeywordVisitor,
            apply                       = Environment.Apply,
        }

        function watch(func)
            if type(func) ~= "function" then error("Usage: watch(func) - The func must be provided as a function") end
            return Watch(func, getKeywordVisitor(watch))()
        end

        Environment.RegisterGlobalKeyword{
            watch                       = watch
        }
    end
end)