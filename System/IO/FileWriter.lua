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
    class "FileWriter" (function(_ENV)
        inherit "TextWriter"

        export { fopen          = _G.io.open }

        __Sealed__() __Default__"w"
        enum "FileWriteMode" {
            Write               = "w",
            Append              = "a",
            WritePlus           = "w+",
            AppendPlus          = "a+",
            WriteBinary         = "wb",
            AppendBinary        = "ab",
            WritePlusBinary     = "w+b",
            AppendPlusBinary    = "a+b",
        }

        -- Field
        field { __file          = false }

        -- Method
        function Write(self, text)
            if text ~= nil then self.__file:write(text) end
        end

        function Flush(self)
            self.__file:flush()
        end

        function Close(self)
            self.__file:close()
        end

        -- Constructor
        __Arguments__{ Userdata }
        function FileWriter(self, file, mode)
            if tostring(file):match("^file") then
                self.__file = file
            else
                throw("Usage: System.IO.FileWriter(file) - no file can be written")
            end
        end

        __Arguments__{ String, Variable.Optional(FileWriteMode, FileWriteMode.Write) }
        function FileWriter(self, file, mode)
            self.__file = fopen(file, mode) or false

            if not self.__file then
                throw("Usage: System.IO.FileWriter(path[, mode]) - open file failed")
            end
        end

        -- Meta-method
        __call = Write
    end)
end)