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
    class "FileReader"                  (function(_ENV)
        inherit "System.Text.TextReader"

        export                          {
            fopen                       = _G.io and _G.io.open or Toolset.fakefunc,
            floor                       = math.floor,
            error                       = error,
        }

        --- the file read mode
        __Sealed__() __Default__("r")
        enum "FileReadMode"             {
            Read                        = "r",
            ReadBinary                  = "rb",
        }

        -- Field
        field                           {
            [0]                         = false,
            [1]                         = false,
            [2]                         = false,
        }

        --- Gets or sets the file position. negative number means start from the end of the file.
        property "Position"             { Type = Number,
            Get = function(self) return self[0]:seek() end,
            Set = function(self, pos)
                pos                     = floor(pos)
                if pos < 0 then
                    return self[0]:seek("end", pos)
                else
                    return self[0]:seek("set", pos)
                end
            end,
        }

        -- Method
        function Read(self)      return self[0]:read(1) end

        function ReadLine(self)  return self[0]:read("*l") end

        function ReadToEnd(self) return self[0]:read("*a") end

        function ReadBlock(self, count, index)
            if index then self[0]:seek("set", index) end
            return self[0]:read(count)
        end

        function Open(self)
            self[0]                     = fopen(self[1], self[2]) or false
            if not self[0] then error("Failed to open the file - " .. self[1], 2) end
        end

        function Close(self) return self[0]:close() end

        -- Constructor
        __Arguments__{ String, FileReadMode/FileReadMode.Read }
        function __new(_, file, mode)
            return { [1] = file, [2] = mode }, false
        end
    end)
end)