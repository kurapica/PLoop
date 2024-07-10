--===========================================================================--
--                                                                           --
--                           System.Threading.Task                           --
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

    --- The task represents asynchronous jobs
    __Sealed__()
    class "Task"                        (function(_ENV)
        extend "System.IContext"

        export                          {
            select                      = select
        }

        -----------------------------------------------------------
        --                     static method                     --
        -----------------------------------------------------------
        if Platform.ENABLE_CONTEXT_FEATURES then
            __Static__() __Arguments__{ Function, Any * 0 }
            function Run(func, ...)

            end
        else

        end


        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        __Arguments__{ Function, Any * 0 }
        function ContinueWith(self, func, ...)
        end

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{ Function, Any * 0 }
        function __new(_, func, ...)
            return { select("#", ...) + 2, task, ... }
        end
    end)
end)