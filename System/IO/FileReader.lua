--===========================================================================--
--                                                                           --
--                           System.IO.FileReader                            --
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
    class "FileReader" (function(_ENV)
        inherit "TextReader"

        export {
            fopen               = io.open,
            floor               = math.floor,
        }

        --- the file read mode
        __Sealed__() __Default__("r")
        enum "FileReadMode" {
            Read                = "r",
            ReadBinary          = "rb",
        }

        -- Field
        field { __file          = false }

        --- Gets or sets the file position. negative number means start from the end of the file.
        property "Position" { Type = Number,
            Get = function(self)
                return self.__file:seek()
            end,
            Set = function(self, pos)
                pos = floor(pos)
                if pos < 0 then
                    return self.__file:seek("end", pos)
                else
                    return self.__file:seek("set", pos)
                end
            end,
        }

        -- Method
        function Read(self) return self.__file:read(1) end

        function ReadLine(self) return self.__file:read("*l") end

        function ReadToEnd(self) return self.__file:read("*a") end

        function ReadBlock(self, index, count)
            self.__file:seek("set", index)
            return self.__file:read(count)
        end

        function Close(self) return self.__file:close() end

        -- Constructor
        __Arguments__{ Userdata }
        function FileReader(self, file)
            if tostring(file):match("^file") then
                self.__file = file
            else
                throw("Usage: System.IO.FileReader(file) - no file can be read")
            end
        end

        __Arguments__{ String, FileReadMode/FileReadMode.Read }
        function FileReader(self, file, mode)
            self.__file = fopen(file, mode) or false

            if not self.__file then
                throw("Usage: System.IO.FileReader(path[, mode]) - open file failed")
            end
        end
    end)
end)