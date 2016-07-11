-- Author      : Kurapica
-- Create Date : 2016/07/11
-- ChangeLog   :

_ENV = Module "System.IO.FileReader" "1.0.0"

namespace "System.IO"

fopen = io.open
floor = floor or math.floor

__Doc__ [[Represents a writer that can write a sequential series of characters to files]]
class "FileReader" (function(_ENV)
	inherit "TextReader"

	-- Property
	property "File" { Type = Userdata }

	__Doc__ [[Gets or sets the file position. negative number means start from the end of the file.]]
	property "Position" { Type = Number,
		Get = function(self)
			return self.File:seek()
		end,
		Set = function(self, pos)
			pos = floor(pos)
			if pos < 0 then
				return self.File:seek("end", pos)
			else
				return self.File:seek("set", pos)
			end
		end,
	}

	-- Method
	function Read(self) return self.File:read(1) end

	function ReadLine(self) return self.File:read("*l") end

	function ReadToEnd(self) return self.File:read("*a") end

	function ReadBlock(self, index, count)
		self.File:seek("set", index)
		return self.File:read(count)
	end

	function Close(self) return self.File:close() end

	-- Constructor
	__Arguments__{ Userdata }
	function FileReader(self, file)
		if tostring(file):match("^file") then
			self.File = file
		end

		assert(self.File , "No file can be read.")
	end

	__Arguments__{ String }
	function FileReader(self, file)
		self.File = fopen(file, mode)

		assert(self.File , "No file can be read.")
	end
end)