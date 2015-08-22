-- Author      : Kurapica
-- Create Date : 2014/10/05
-- ChangeLog   :

Module "System.Text" "0.1.0"

namespace "System.Text"

__Doc__[[Represents a character encoding.]]
__Abstract__() class "Encoding" (function(_ENV)
	__Doc__[[The name of the encoding]]
	__Static__()
	property "EncodingName" { Set = false, Default = "Encoding" }
end)

__Doc__[[Represents a writer that can write a sequential series of characters]]
__Abstract__() class "TextWriter" (function (_ENV)
	__Doc__[[Gets the character encoding in which the output is written.]]
	property "Encoding" { Type = Encoding }

	__Doc__[[Gets or sets the line terminator string used by the current TextWriter.]]
	property "NewLine" { Type = String, Default = "\n" }

	__Doc__[[Closes the current writer and releases any system resources associated with the writer.]]
	function Close(self) end

	__Doc__[[Clears all buffers for the current writer and causes any buffered data to be written to the underlying device.]]
	function Flush(self) end

	__Doc__[[Writes the data to the text string or stream.]]
	function Write(self, data) end

	__Doc__[[Writes the data(could be nil) followed by a line terminator to the text string or stream.]]
	function WriteLine(self, data) end
end)

__Doc__[[Represents a reader that can read a sequential series of characters]]
__Abstract__() class "TextReader" (function (_ENV)
	__Doc__[[Gets the character encoding in which the input is read.]]
	property "Encoding" { Type = Encoding }

	__Doc__[[Closes the current reader and releases any system resources associated with the reader.]]
	function Close(self) end

	__Doc__[[Reads the next character from the text reader and advances the character position by one character.]]
	function Read(self) end

	__Doc__[[Reads a line of characters from the text reader and returns the data as a string.]]
	function ReadLine(self) end

	__Doc__[[Reads a specified maximum number of characters from the current text reader and writes the data to a buffer, beginning at the specified index.]]
	function ReadBlock(self, indx, count) end

	__Doc__[[Reads all characters from the current position to the end of the text reader and returns them as one string.]]
	function ReadToEnd(self) end
end)