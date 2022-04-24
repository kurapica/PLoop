--===========================================================================--
--                                                                           --
--                           System.IO.FileWriter                            --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2016/07/11                                               --
-- Update Date  :   2018/03/26                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.IO"

    --- Represents a writer that can write a sequential series of characters to files
    __Sealed__()
    class "FileWriter"                  (function(_ENV)
        inherit "System.Text.TextWriter"

        export {
            fopen                       = _G.io and _G.io.open or Toolset.fakefunc
        }

        __Sealed__() __Default__"w"
        enum "FileWriteMode"            {
            Write                       = "w",
            Append                      = "a",
            WritePlus                   = "w+",
            AppendPlus                  = "a+",
            WriteBinary                 = "wb",
            AppendBinary                = "ab",
            WritePlusBinary             = "w+b",
            AppendPlusBinary            = "a+b",
        }

        -- Field
        field                           {
            [0]                         = false,
            [1]                         = false,
            [2]                         = false,
        }

        -- Method
        function Write(self, text) if text ~= nil then self[0]:write(text) end end

        function Flush(self) self[0]:flush() end

        function Open(self)
            self[0] = fopen(self[1], self[2]) or false
            if not self[0] then error("Failed to open the file - " .. self[1], 2) end
        end

        function Close(self) self[0]:close() end

        -- Constructor
        __Arguments__{ String, FileWriteMode/FileWriteMode.Write }
        function __new(_, file, mode)
            return { [1] = file, [2] = mode }, false
        end

        -- Meta-method
        __call = Write
    end)
end)