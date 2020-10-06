--===========================================================================--
--                                                                           --
--                         System.Text.StringReader                          --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2018/04/19                                               --
-- Update Date  :   2018/04/19                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    --- Represents a writer that can write a sequential series of characters to files
    __Sealed__()
    class "System.Text.StringReader" (function(_ENV)
        inherit "System.Text.TextReader"

        export {
            strsub              = string.sub,
            strfind             = string.find,
            strmatch            = string.match,
            floor               = math.floor,
            max                 = math.max,
        }

        -- Field
        field {
            __content           = "",
            __seekpos           = 1,
            __length            = 0,
            __skipindent        = -1,
        }

        --- Gets or sets the position. negative number means start from the end of the file.
        property "Position" {
            Type = Number,
            Get = function(self)
                return self.__seekpos
            end,
            Set = function(self, pos)
                pos = floor(pos)
                if pos < 0 then
                    self.__seekpos = max(1, self.__length + pos + 1)
                else
                    self.__seekpos = max(1, pos)
                end
            end,
        }

        --- Whether discard the indent at the head of the each line
        property "DiscardIndents" { type = Boolean, default = false }

        -- Method
        function Read(self)
            self.__skipindent   = false -- only skip indent when keeping read line

            local pos           = self.__seekpos
            if pos <= self.__length then
                self.__seekpos  = pos + 1
                return strsub(self.__content, pos, pos)
            end
        end

        function ReadLine(self)
            local pos               = self.__seekpos
            if pos <= self.__length then
                local nxtl, endl    = strfind(self.__content, "\r?\n", pos)
                local line
                if nxtl then
                    self.__seekpos  = endl + 1
                    line            = strsub(self.__content, pos, nxtl - 1)
                else
                    self.__seekpos  = self.__length + 1
                    line            = strsub(self.__content, pos)
                end
                if self.__skipindent == -1 then
                    self.__skipindent = self.DiscardIndents and strmatch(line, "^%s+") or false
                end

                if self.__skipindent then
                    if line:find(self.__skipindent, 1, true) then
                        line        = line:sub(#self.__skipindent + 1)
                    end
                end

                return line
            end
        end

        function ReadToEnd(self)
            self.__skipindent   = false -- only skip indent when keeping read line

            local pos           = self.__seekpos
            if pos <= self.__length then
                self.__seekpos      = self.__length + 1
                return strsub(self.__content, pos)
            end
        end

        function ReadBlock(self, count, index)
            self.__skipindent   = false -- only skip indent when keeping read line

            if index then self.Position = index end

            local pos           = self.__seekpos
            if pos <= self.__length then
                self.__seekpos  = pos + count
                return strsub(self.__content, pos, pos + count - 1)
            end
        end

        -- Constructor
        __Arguments__{ String }
        function StringReader(self, str)
            self.__content      = str
            self.__length       = #str
        end
    end)
end)