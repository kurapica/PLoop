--========================================================--
--                System.Threading                        --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2013/08/13                              --
--========================================================--

--========================================================--
_ENV = Module     "System.Threading"                 "1.1.0"
--========================================================--

namespace "System"

__Doc__[[Used for threading control]]
__Final__() __Sealed__()
interface "Threading" (function(_ENV)
    ------------------------------------------------------
    -- Thread Pool
    ------------------------------------------------------
    THREAD_POOL_MAX = 100

    THREAD_PROC_INIT = 1
    THREAD_PROC_CALLFUNC = 2
    THREAD_PROC_RECYCLING = 3

    THREAD_POOL = {}
    THREAD_STATUS = setmetatable({}, {__mode="k"})
    THREAD_ARG_PROC = setmetatable({}, {
        __index = function(self, cnt)
            local body = {}
            local args = ""
            if cnt > 0 then
                for i = 1, cnt do body[i] = "arg" .. i end
                args = tblconcat(body, ",")
                wipe(body)
                tinsert(body, "local yield = ...")
                tinsert(body, ("return function(iter,func,%s)"):format(args))
                tinsert(body, ("return func(%s,yield(iter))"):format(args))
            else
                tinsert(body, "local yield = ...")
                tinsert(body, "return function(iter,func)")
                tinsert(body, "return func(yield(iter))")
            end

            tinsert(body, "end")

            body = tblconcat(body, "\n")

            self[cnt] = loadstring(body)(yield)

            return self[cnt]
        end
    })

    local function reCycleAndRet(iter, ...)
        if #THREAD_POOL < THREAD_POOL_MAX then
            tinsert(THREAD_POOL, iter)
            THREAD_STATUS[iter] = THREAD_PROC_RECYCLING
        else
            THREAD_STATUS[iter] = nil
        end
        yield(...)
    end

    local function callIterFunc(iter, func, ...)
        local cnt = select("#", ...)
        THREAD_STATUS[iter] = THREAD_PROC_CALLFUNC
        reCycleAndRet(iter, THREAD_ARG_PROC[cnt](iter, func, ...))
    end

    local function newIterator()
        local iter = tremove(THREAD_POOL)

        while iter do
            if THREAD_STATUS[iter] == THREAD_PROC_RECYCLING then
                iter()
            end
            if THREAD_STATUS[iter] == THREAD_PROC_INIT then
                return iter
            end

            iter = tremove(THREAD_POOL)
        end

        local iter = wrap(
            function( iter )
                while true do
                    THREAD_STATUS[iter] = THREAD_PROC_INIT
                    callIterFunc(iter, yield())
                end
            end
        )

        iter(iter)

        return iter
    end

    ------------------------------------------------------
    -- Static Methods
    ------------------------------------------------------
    __Doc__[[
        <desc>Used to make call function as thread</desc>
        <param name="func" type="function">the function contains yield instructions</param>
        <param name="...">The arguments</param>
        <usage>
            function a(...)
                return coroutine.running(), ...
            end

            print(Threading.ThreadCall(a, 1, 2, 3))

            -- Oupput
            -- thread: 00F95100 1   2   3
        </usage>
    ]]
    __Arguments__{ Function, { IsList = true, Nilable = true } }
    function ThreadCall(func, ...)
        local iter = newIterator()
        return iter(func)(...)
    end

    __Doc__[[
        <desc>Used to make iterator from functions</desc>
        <param name="func" type="function">the function contains yield instructions</param>
        <param name="...">The arguments</param>
        <usage>
            function a(start, endp)
                for i = start, endp do
                    coroutine.yield(i, "i_"..i)
                end
            end

            for k, v in Threading.Iterator(a), 1, 3 do print(k, v) end

            -- Oupput
            -- 1       i_1
            -- 2       i_2
            -- 3       i_3

            -- Also can be used as
            for k, v in Threading.Iterator(a, 1, 3) do print(k, v) end
        </usage>
    ]]
    __Arguments__{ Function, { IsList = true, Nilable = true } }
    function Iterator(func, ...)
        local iter = newIterator()
        return iter(func, ...)
    end

    ------------------------------------------------------
    -- Sub-Features
    ------------------------------------------------------
    __AttributeUsage__{AttributeTarget = AttributeTargets.Event + AttributeTargets.Method + AttributeTargets.ObjectMethod, RunOnce = true}
    __Sealed__() __Unique__()
    class "__Thread__" (function(_ENV)
        extend "IAttribute"

        function __Thread__(self)
            local del = __Delegate__(ThreadCall)
            del.Priorty = AttributePriorty.Lower
        end
    end)

    __AttributeUsage__{AttributeTarget = AttributeTargets.Event + AttributeTargets.Method + AttributeTargets.ObjectMethod, RunOnce = true}
    __Sealed__() __Unique__()
    class "__Iterator__" (function(_ENV)
        extend "IAttribute"

        function __Iterator__(self)
            local del = __Delegate__(Iterator)
            del.Priorty = AttributePriorty.Lower
        end
    end)
end)

------------------------------------------------------
-- Global settings
------------------------------------------------------
_G.tpairs = _G.tpairs or Threading.Iterator