--===========================================================================--
--                                                                           --
--                         System.Text.StringWriter                          --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2018/07/25                                               --
-- Update Date  :   2018/07/25                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    --- Represents a writer that can write a sequential series of characters to files
    __Sealed__()
    class "System.Text.StringWriter" (function(_ENV)
        inherit "System.Text.TextWriter"

        export {
            tconcat             = table.concat,
            wipe                = Toolset.wipe,
        }

        field {
            temp                = false,
            count               = 0,
        }

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- the final result
        property "Result"       { set = false, field = 0 }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        __Arguments__{ String }
        function Write(self, text)
            local cnt       = self.count + 1
            self.count      = cnt
            self.temp[cnt]  = text
        end

        function Open(self)
            self.temp           = {}
            self.count          = 0
        end

        function Close(self)
            self[0]             = tconcat(self.temp)
            self.temp           = false
            self.count          = 0
        end
    end)
end)