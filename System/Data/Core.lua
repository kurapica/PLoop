--===========================================================================--
--                                                                           --
--                             System.Data.Core                              --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2018/09/07                                               --
-- Update Date  :   2018/09/07                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    __Sealed__() __Final__()
    interface "System.Data"             (function(_ENV)
        export { safeset                = Toolset.safeset }

        -----------------------------------------------------------
        --                         types                         --
        -----------------------------------------------------------
        __Sealed__()
        enum "ConnectionState" {
            Closed                      = 0,
            Open                        = 1,
            Connecting                  = 2,
            Executing                   = 3,
            Fetching                    = 4,
        }

        __Sealed__()
        struct "DBNull"                 { function(val) return val ~= DBNull end }

        -----------------------------------------------------------
        --                        methods                        --
        -----------------------------------------------------------
        local NULL_VALUE                = { [DBNull] = true }

        --- Add Empty value for ParseString
        __Static__()
        function AddNullValue(value)
            if value == nil then return end
            NULL_VALUE                  = safeset(NULL_VALUE, value, true)
        end

        --- Parse the value so special null value can be changed to nil
        __Static__()
        function ParseValue(value)
            if value == nil or NULL_VALUE[value] then return nil end
            return value
        end
    end)
end)