--===========================================================================--
--                                                                           --
--                                 System.IO                                 --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2016/01/24                                               --
-- Update Date  :   2018/03/16                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    --- supports for input and output
    namespace "System.IO"

    --- Represents a writer that can write a sequential series of characters
    __Abstract__() __Sealed__()
    class "TextWriter" (function (_ENV)
        --- Gets the character encoding in which the output is written.
        __Abstract__() property "Encoding" { type = System.Text.Encoding }

        --- Gets or sets the line terminator string used by the current TextWriter.
        __Abstract__() property "NewLine" { type = String, default = "\n" }

        --- Closes the current writer and releases any system resources associated with the writer.
        __Abstract__() function Close(self) end

        --- Clears all buffers for the current writer and causes any buffered data to be written to the underlying device.
        __Abstract__() function Flush(self) end

        --- Writes the data to the text string or stream.
        __Abstract__() function Write(self, data) end

        --- Writes the data(could be nil) followed by a line terminator to the text string or stream.
        __Abstract__() function WriteLine(self, data) end
    end)

    --- Represents a reader that can read a sequential series of characters
    __Abstract__()  __Sealed__()
    class "TextReader" (function (_ENV)
        --- Gets the character encoding in which the input is read.
        __Abstract__() property "Encoding" { type = System.Text.Encoding }

        --- Closes the current reader and releases any system resources associated with the reader.
        __Abstract__() function Close(self) end

        --- Reads the next character from the text reader and advances the character position by one character.
        __Abstract__() function Read(self) end

        --- Reads a line of characters from the text reader and returns the data as a string.
        __Abstract__() function ReadLine(self) end

        --- Reads a specified maximum number of characters from the current text reader and writes the data to a buffer, beginning at the specified index.
        __Abstract__() function ReadBlock(self, indx, count) end

        --- Reads all characters from the current position to the end of the text reader and returns them as one string.
        __Abstract__() function ReadToEnd(self) end
    end)
end)
