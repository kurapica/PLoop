--===========================================================================--
--                                                                           --
--                             System.Threading                              --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2013/08/13                                               --
-- Update Date  :   2020/06/25                                               --
-- Version      :   1.1.2                                                    --
--===========================================================================--
PLoop(function(_ENV)
    __Final__() __Sealed__() __Abstract__()
    class "System.Threading" (function(_ENV)

        -- Use Threading as global
        Environment.RegisterGlobalNamespace("System.Threading")

        --- the thread pool used to generate and recycle coroutines
        __Sealed__() __Final__() __NoRawSet__(false) __NoNilValue__(false)
        class "ThreadPool"              (function(_ENV)
            if Platform.ENABLE_CONTEXT_FEATURES then
                extend "System.IContext"
            end

            export                      {
                create                  = coroutine.create,
                resume                  = coroutine.resume,
                running                 = coroutine.running,
                status                  = coroutine.status,
                wrap                    = coroutine.wrap,
                yield                   = coroutine.yield,

                tinsert                 = table.insert,
                tremove                 = table.remove,

                getmetatable            = getmetatable,
                getlocal                = _G.debug and debug.getlocal or false,

                pcall                   = pcall,
                loadsnippet             = Toolset.loadsnippet,
                safeset                 = Toolset.safeset,
                select                  = select,
                tblconcat               = table.concat,
                strformat               = string.format,

                GetContext              = Context.GetCurrentContext,

                PREPARE_CONFIRM         = Toolset.fakefunc,

                ThreadPool
            }

            -----------------------------------------------------------
            --                        helpers                        --
            -----------------------------------------------------------
            local _PassArgs             = { [0] = function(thread, func) return func(yield(thread)) end }
            local _PassGenCode          = [[return function (thread, func, %s) return func(%s, yield(thread)) end]]

            local function newPass(count)
                local args              = {}

                for i = 1, count do args[i] = "arg" .. i end
                args                    = tblconcat(args, ", ")

                local pass              = loadsnippet(strformat(_PassGenCode, args, args), "Thread_Pass_" .. count, _ENV)()
                _PassArgs               = safeset(_PassArgs, count, pass)

                return pass
            end

            local function returnwithrecycle(pool, thread, asiter, ...)
                -- recyle the thread
                if #pool < pool.PoolSize then tinsert(pool, thread) end

                -- return the value
                yield(...)

                -- make sure the iterator don't resume again
                if asiter then
                    yield()
                    yield()
                end
            end

            local function preparefunc(pool, thread, func, asiter, ...)
                if not func then return end
                local cnt               = select("#", ...)
                returnwithrecycle(pool, thread, asiter, (_PassArgs[cnt] or newPass(cnt))(thread, func, ...))
            end

            local function recyclethread(pool, thread)
                while true do preparefunc(pool, thread, yield(PREPARE_CONFIRM)) end
            end

            local function newrecyclethread(self)
                local thread            = tremove(self)

                -- Check Re-usable
                if thread then
                    for i = 1, 3 do
                        if thread() == PREPARE_CONFIRM then
                            return thread
                        end
                    end
                end

                -- Create the new thread
                thread                  = wrap(recyclethread)
                thread(self, thread)    -- pass the pool and thread to be recycled
                return thread
            end

            -- make sure we can get the thread pool in the func
            local function retresult(...) return ... end

            local function poolthread(pool, func) return retresult(func(yield())) end

            local function newpoolthread(self, func, aswrap)
                if aswrap then
                    local thread        = wrap(poolthread)
                    thread(self, func)
                    return thread
                else
                    local thread        = create(poolthread)
                    resume(thread, self, func)
                    return thread
                end
            end

            local getCurrentPool        = getlocal and function()
                local curr, ismain      = running()
                if not curr or ismain then return end

                local stack             = 5
                local n, v              = getlocal(stack, 1)

                while true do
                    if n == "pool" and getmetatable(v) == ThreadPool then
                        return v
                    end

                    stack               = stack + 1
                    n, v                = getlocal(stack, 1)
                end
            end or Toolset.fakefunc

            -----------------------------------------------------------
            --                        method                         --
            -----------------------------------------------------------
            --- Get the thread or wrap function for the function, this
            -- thread should be processed under the thread pool
            -- @param  func                 the target function
            -- @return wrap                 the wrap function or thread
            __Arguments__{ Function, Boolean/nil }
            GetThread                   = newpoolthread

            --- safe call the function within a coroutine, if the caller is already
            -- in a coroutine, no new coroutine will be used
            __Arguments__{ Function, Any * 0 }
            function SafeThreadCall(self, func, ...)
                local curr, ismain      = running()
                if curr and not ismain then return func(...) end

                local thread            = newrecyclethread(self)
                return thread(func)(...)
            end

            --- call the function with arguments in a recyclable coroutine
            -- @param   func                the target function
            -- @param   ...                 the arguments
            -- @usage   function a(...)
            --              return coroutine.running(), ...
            --          end
            --
            --          print(pool:ThreadCall(a, 1, 2, 3))
            --
            --          -- Oupput
            --          -- thread: 00F95100 1   2   3
            __Arguments__{ Function, Any * 0 }
            function ThreadCall(self, func, ...)
                local thread            = newrecyclethread(self)
                return thread(func)(...)
            end

            --- Run the function as an iterator in a recyclable coroutine
            -- @param   func            the function contains yield instructions
            -- @param   ...             The arguments
            -- @usage   function a(start, endp)
            --              for i = start, endp do
            --                  coroutine.yield(i, "i_"..i)
            --              end
            --          end
            --
            --          for k, v in pool:GetIterator(a), 1, 3 do print(k, v) end
            --
            --          -- Oupput
            --          -- 1       i_1
            --          -- 2       i_2
            --          -- 3       i_3
            --
            --          -- Also can be used as
            --          for k, v in Threading.Iterator(a, 1, 3) do print(k, v) end
            if Platform.THREAD_SAFE_ITERATOR then
                local function safeIteratorCall(msg, ...)
                    if msg == "cannot resume dead coroutine" then return end
                    return msg, ...
                end

                __Arguments__{ Function, Any * 0 }
                function GetIterator(self, func, ...)
                    local thread        = newrecyclethread(self)
                    local wrap          = thread(func, true, ...)

                    return function(...)
                        return safeIteratorCall(wrap(...))
                    end
                end
            else
                __Arguments__{ Function, Any * 0 }
                function GetIterator(self, func, ...)
                    local thread        = newrecyclethread(self)
                    return thread(func, true, ...)
                end
            end

            -----------------------------------------------------------
            --                   static property                     --
            -----------------------------------------------------------
            local DEFAULT_POOL_SIZE     = (Platform.MULTI_OS_THREAD or Platform.ENABLE_CONTEXT_FEATURES) and 0 or nil

            --- the default thread pool, can't be used in multi os thread mode
            __Static__()
            property "Default"          { set = false, default = function() return ThreadPool{ PoolSize = DEFAULT_POOL_SIZE } end }

            --- the current thread pool of the context
            __Static__()
            property "Current"          {
                get                     = Platform.ENABLE_CONTEXT_FEATURES and function()
                    local ok, ret       = pcall(getCurrentPool)
                    if ok and ret then return ret end

                    local context       = GetContext()
                    if context then
                        local cpool     = context[ThreadPool]
                        if not cpool then
                            cpool       = ThreadPool()
                            context[ThreadPool] = cpool
                        end
                        return cpool
                    end

                    return ThreadPool.Default
                end or function()
                    return ThreadPool.Default
                end
            }

            -----------------------------------------------------------
            --                       property                        --
            -----------------------------------------------------------
            --- the max pool size for idle coroutines
            property "PoolSize"         { type = NaturalNumber, default = Platform.THREAD_POOL_MAX_SIZE }
        end)

        --- specify a method or function as asynchronous
        __Sealed__() __Final__()
        class "__Async__"               (function(_ENV)
            extend "IInitAttribute"

            export                      { ThreadPool }

            local wraptarget            = Platform.ENABLE_CONTEXT_FEATURES and function(target)
                return function(...)    return ThreadPool.Current:ThreadCall(target, ...) end
            end or function(target)
                return function(...)    return ThreadPool.Default:ThreadCall(target, ...) end
            end

            local safewrap              = Platform.ENABLE_CONTEXT_FEATURES and function(target)
                return function(...)    return ThreadPool.Current:SafeThreadCall(target, ...) end
            end or function(target)
                return function(...)    return ThreadPool.Default:SafeThreadCall(target, ...) end
            end

            -----------------------------------------------------------
            --                        method                         --
            -----------------------------------------------------------
            --- modify the target's definition
            -- @param   target      the target
            -- @param   targettype  the target type
            -- @param   definition  the target's definition
            -- @param   owner       the target's owner
            -- @param   name        the target's name in the owner
            -- @param   stack       the stack level
            -- @return  definition  the new definition
            function InitDefinition(self, target, targettype, definition, owner, name, stack)
                return self.SafeMode and safewrap(definition) or wraptarget(definition)
            end

            -----------------------------------------------------------
            --                       property                        --
            -----------------------------------------------------------
            --- the attribute target
            property "AttributeTarget"  { type = AttributeTargets,  default = AttributeTargets.Method + AttributeTargets.Function }

            --- the attribute's priority
            property "Priority"         { type = AttributePriority, default = AttributePriority.Lower }

            --- Whether use safe mode
            property "SafeMode"         { type = Boolean }

            -----------------------------------------------------------
            --                      constructor                      --
            -----------------------------------------------------------
            function __ctor(self, safe)
                self.SafeMode           = safe and true or false
            end
        end)

        --- specify a method or function as iterator who use yield to generate values
        __Sealed__() __Final__()
        class "__Iterator__"            (function(_ENV)
            extend "IInitAttribute"

            export                      { ThreadPool }

            local wraptarget            = Platform.ENABLE_CONTEXT_FEATURES and function(target)
                return function(...) return ThreadPool.Current:GetIterator(target, ...) end
            end or function(target)
                return function(...) return ThreadPool.Default:GetIterator(target, ...) end
            end

            -----------------------------------------------------------
            --                        method                         --
            -----------------------------------------------------------
            --- modify the target's definition
            -- @param   target      the target
            -- @param   targettype  the target type
            -- @param   definition  the target's definition
            -- @param   owner       the target's owner
            -- @param   name        the target's name in the owner
            -- @param   stack       the stack level
            -- @return  definition  the new definition
            function InitDefinition(self, target, targettype, definition, owner, name, stack)
                return wraptarget(definition)
            end

            -----------------------------------------------------------
            --                       property                        --
            -----------------------------------------------------------
            --- the attribute target
            property "AttributeTarget"  { type = AttributeTargets,  default = AttributeTargets.Method + AttributeTargets.Function }

            --- the attribute's priority
            property "Priority"         { type = AttributePriority, default = AttributePriority.Lower }
        end)

        -----------------------------------------------------------------------
        --                           static method                           --
        -----------------------------------------------------------------------
        -- Run a function with arguments async
        __Static__() __Async__() __Arguments__{ Function, Any * 0 }
        function RunAsync(func, ...)
            return func(...)
        end

        -- Run a function with arguments as iterator
        __Static__() __Iterator__() __Arguments__{ Function, Any * 0 }
        function RunIterator(func, ...)
            return func(...)
        end
    end)

    ---------------------------------------------------------------
    --                          Toolset                          --
    ---------------------------------------------------------------
    export                              {
        yield                           = coroutine.yield,
        running                         = coroutine.running,
        resume                          = coroutine.resume,
    }

    local function getArgs(_, ...)      return ... end

    --- Keep arguments in a coroutine
    __Async__()
    function Toolset.keepargs(...)
        yield(running())
        return ...
    end

    --- Gets the arguments from a coroutine
    function Toolset.getkeepargs(thread)
        if thread then return getArgs(resume(thread)) end
    end
end)
