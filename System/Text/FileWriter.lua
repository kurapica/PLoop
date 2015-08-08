-- Author      : Kurapica
-- Create Date : 2015/07/22
-- ChangeLog   :

Module "System.Text.FileWriter" "1.0.0"

namespace "System.Text"

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
	property "File" { Type = Userdata + nil }

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
	__Arguments__{ Userdata + String, FileWriteMode + nil }
	function FileWriter(self, file, mode)
		if type(file) == "userdata" and tostring(file):match("^file") then
			self.File = file
		elseif type(file) == "string" then
			self.File = fopen(file, mode)
		end

		assert(self.File , "No file can be written.")
	end
end)