--===========================================================================--
--                                                                           --
--                      System.Threading.TaskScheduler                       --
--                                                                           --
--===========================================================================--


--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2024/07/10                                               --
-- Update Date  :   2024/07/10                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--
PLoop(function(_ENV)
    namespace "System.Threading"

    --- THe task scheduler system used to process the tasks
    __Sealed__()
    class "TaskScheduler"               (function(_ENV)

        export                          {
            type                        = type,
            resume                      = coroutine.resume,

            ThreadPool
        }

        -----------------------------------------------------------
        --                    static property                    --
        -----------------------------------------------------------
        --- The default task scheduler
        __Static__()
        property "Default"              { type = TaskScheduler, default = function() return TaskScheduler() end }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- Queue a task(function|thread) to the scheduler
        __Abstract__()
        function QueueTask(self, task, ...) return self:ExecuteTask(task, ...) end

        --- Try dequeue a task
        __Abstract__()
        function TryDequeue(self, task) return true end

        __Abstract__()
        function ExecuteTask(self, task, ...)
            local t                     = type(task)

            if t == "function" then
                return ThreadPool.Current:ThreadCall(task, ...)
            elseif t == "thread" then
                return resume(task, ...)
            end
        end
    end)
end)