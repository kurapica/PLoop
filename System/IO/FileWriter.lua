-- Author      : Kurapica
-- Create Date : 2016/07/11
-- ChangeLog   :

_ENV = Module "System.IO.FileWriter" "1.0.0"

namespace "System.IO"

fopen = io.open

__Doc__ [[Represents a writer that can write a sequential series of characters to files]]
class "FileWriter" (function(_ENV)
	inherit "TextWriter"

	__Default__"w"
	enum "FileWriteMode" {
		Write = "w",
		Append = "a",
		WritePlus = "w+",
		AppendPlus = "a+",
		WriteBinary = "wb",
		AppendBinary = "ab",
		WritePlusBinary = "w+b",
		AppendPlusBinary = "a+b",
	}

	-- Property
	property "File" { Type = Userdata }

	-- Method
	function Write(self, text)
		if text ~= nil then self.File:write(text) end
	end

	function Flush(self)
		self.File:flush()
	end

	function Close(self)
		self.File:close()
	end

	-- Constructor
	__Arguments__{ Userdata }
	function FileWriter(self, file, mode)
		if tostring(file):match("^file") then
			self.File = file
		end

		assert(self.File , "No file can be written.")
	end

	__Arguments__{ String, Argument(FileWriteMode, true) }
	function FileWriter(self, file, mode)
		self.File = fopen(file, mode)

		assert(self.File , "No file can be written.")
	end

	-- Meta-method
	__call = Write
end)