--===========================================================================--
--                                                                           --
--                             System.Threading                              --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2013/08/13                                               --
-- Update Date  :   2018/03/16                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--
PLoop(function(_ENV)
    namespace "System.Threading"

    Environment.RegisterGlobalNamespace("System.Threading")

    --- the thread pool used to generate and recycle coroutines
    __Sealed__() __Final__()
    class "ThreadPool" (function(_ENV)
        export {
            create              = coroutine.create,
            resume              = coroutine.resume,
            running             = coroutine.running,
            status              = coroutine.status,
            wrap                = coroutine.wrap,
            yield               = coroutine.yield,

            tinsert             = table.insert,
            tremove             = table.remove,

            getmetatable        = getmetatable,
            getlocal            = _G.debug and debug.getlocal or false,

            pcall               = pcall,
            loadsnippet         = Toolset.loadsnippet,
            safeset             = Toolset.safeset,
            select              = select,
            tblconcat           = table.concat,
            strformat           = string.format,
        }

        export { ThreadPool, Platform }

        -----------------------------------------------------------
        --                        helpers                        --
        -----------------------------------------------------------
        local _PassArgs         = { [0] = function(thread, func) return func(yield(thread)) end }
        local _PassGenCode      = [[
            return function (thread, func, %s)
                return func(%s, yield(thread))
            end
        ]]

        local function newPass(count)
            local args          = {}

            for i = 1, count do args[i] = "arg" .. i end
            args    = tblconcat(args, ", ")

            local pass = loadsnippet(strformat(_PassGenCode, args, args), "Thread_Pass_" .. count, currentenv())()

            _PassArgs  = safeset(_PassArgs, count, pass)

            return pass
        end

        local function returnwithrecycle(pool, thread, ...)
            if #pool < pool.PoolSize then
                tinsert(pool, thread)       -- recyle the thread
            end
            yield(...)                      -- return the value
        end

        local function preparefunc(pool, thread, func, ...)
            local cnt = select("#", ...)
            returnwithrecycle(pool, thread, (_PassArgs[cnt] or newPass(cnt))(thread, func, ...))
        end

        local function recyclethread(pool, thread)
            while true do
                preparefunc(pool, thread, yield())
            end
        end

        local function newthread(self)
            local thread        = tremove(self)

            if thread then
                thread()            -- resume to prepare
                return thread
            end

            thread              = wrap(recyclethread)
            thread(self, thread)    -- pass the pool and thread to be recycled
            return thread
        end

        local getCurrentPool    = getlocal and function()
            if running() == nil then return end

            local stack         = 5
            local n, v          = getlocal(stack, 1)

            while true do
                if n == "pool" and getmetatable(v) == ThreadPool then
                    return v
                end

                stack           = stack + 1
                n, v            = getlocal(stack, 1)
            end
        end or function() end

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- get a recycle coroutine wrap for given function, when
        -- the function job is done, the wrap will be send back to
        -- the pool
        -- @param  func                 the target function
        -- @return wrap                 the wrap function
        -- @usage   local v = pool:GetThreadWrap(function(cnt) for i = 1, cnt do Task.Sleep(1) print(i) end end)
        --          v(10) -- print 1 - 10 for each second
        __Arguments__{ Function }
        function GetThread(self, func)
            local thread        = newthread(self)
            return thread(func)
        end

        --- call the function with arguments as coroutine
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
        __Arguments__{ Function, Variable.Rest() }
        function ThreadCall(self, func, ...)
            local thread        = newthread(self)
            return thread(func)(...)
        end

        --- Used to make iterator from functions
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
        __Arguments__{ Function, Variable.Rest() }
        function GetIterator(self, func, ...)
            local thread        = newthread(self)
            return thread(func, ...)
        end

        -----------------------------------------------------------
        --                   static property                     --
        -----------------------------------------------------------
        --- the default thread pool, can't be used in multi os thread mode
        __Static__()
        property "Default" { set = false, default = function() return ThreadPool{ PoolSize = Platform.MULTI_OS_THREAD and 0 or nil } end }

        --- the current thread pool
        __Static__()
        property "Current" {
            get = function()
                local ok, ret = pcall(getCurrentPool)
                return ok and ret or nil
            end
        }

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- the max pool size for idle coroutines
        property "PoolSize" { type = NaturalNumber, default = Platform.THREAD_POOL_MAX_SIZE }
    end)

    --- represent a task type used to simplify the work of writing asynchronous code
    __Sealed__() __Final__()
    class "Task" (function(_ENV)
    end)

    --- specify a method or function as asynchronous
    __Sealed__() __Final__()
    class "__Async__" (function(_ENV)
        extend "IInitAttribute"

        export { ThreadPool, Context }

        local wraptarget = Platform.MULTI_OS_THREAD and function(target)
            return function(...)
                local cpool         = ThreadPool.Current
                if cpool then return cpool:ThreadCall(target, ...) end

                local context       = Context.Current
                if context then
                    cpool           = context[ThreadPool]
                    if not cpool then
                        cpool        = ThreadPool()
                        context[ThreadPool] = cpool
                    end
                    return cpool:ThreadCall(target, ...)
                end
                return ThreadPool.Default:ThreadCall(target, ...)
            end
        end or function(target)
            return function(...)
                return ThreadPool.Default:ThreadCall(target, ...)
            end
        end

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- modify the target's definition
        -- @param   target                      the target
        -- @param   targettype                  the target type
        -- @param   definition                  the target's definition
        -- @param   owner                       the target's owner
        -- @param   name                        the target's name in the owner
        -- @param   stack                       the stack level
        -- @return  definition                  the new definition
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

    --- specify a method or function as iterator who use yield to generate values
    __Sealed__() __Final__()
    class "__Iterator__" (function(_ENV)
        extend "IInitAttribute"

        export { ThreadPool, Context }

        local wraptarget = Platform.MULTI_OS_THREAD and function(target)
            return function(...)
                local cpool         = ThreadPool.Current
                if cpool then return cpool:GetIterator(target, ...) end

                local context       = Context.Current
                if context then
                    cpool           = context[ThreadPool]
                    if not cpool then
                        cpool       = ThreadPool()
                        context[ThreadPool] = cpool
                    end
                    return cpool:GetIterator(target, ...)
                end
                return ThreadPool.Default:GetIterator(target, ...)
            end
        end or function(target)
            return function(...)
                return ThreadPool.Default:GetIterator(target, ...)
            end
        end

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- modify the target's definition
        -- @param   target                      the target
        -- @param   targettype                  the target type
        -- @param   definition                  the target's definition
        -- @param   owner                       the target's owner
        -- @param   name                        the target's name in the owner
        -- @param   stack                       the stack level
        -- @return  definition                  the new definition
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
end)
