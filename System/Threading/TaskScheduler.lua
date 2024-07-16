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
-- Version      :   0.0.1                                                    --
--===========================================================================--
PLoop(function(_ENV)
    namespace "System.Threading"

    --- THe task scheduler system used to process the tasks
    __Sealed__() __Abstract__()
    class "TaskScheduler"               (function(_ENV)

        -----------------------------------------------------------
        --                    static property                    --
        -----------------------------------------------------------
        --- The default task scheduler
        __Static__()
        property "Default"              { type = TaskScheduler }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- Schedule the task
        __Abstract__() __Arguments__{ Thread }
        function Schedule(self, task)   end
    end)
end)