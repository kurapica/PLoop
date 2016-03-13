--=============================
-- System.IO.File
--
-- Author : Kurapica
-- Create Date : 2016/01/28
--=============================
_ENV = Module "System.IO.File" "1.0.0"

namespace "System.IO"

fopen = io.open

__Final__() __Sealed__() __Abstract__()
class "File" (function (_ENV)
	local function formatMacTime(result)
		if result then
			local month, day, time, year = result:match("(%w+)%s+(%d+)%s+(%d+:%d+:%d+)%s+(%d+)")
			if month then
				return ("%s-%s-%s %s"):format(year, month, day, time)
			end
		end
	end

	__Doc__[[Get the file's creation time]]
	__PipeRead__ (function(path) return strformat("dir /t:c \"%s\"", path:gsub("/", "\\")) end, "%d+/%d+/%d+%s+[%d:]+", OSType.Windows)
	__PipeRead__ ("export PATH='/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/X11/bin'\nls -l -T -U \"%s\"", formatMacTime, OSType.MacOS)
	__PipeRead__ ("ls --full-time \"%s\"", "%d+-%d+-%d+%s+[%d:]+", OSType.Linux)
	function GetCreationTime(path, result)
		if not result then Error("[System.IO.File][GetCreationTime][Fail] %s - %s", path, result or "nil") end
		return result
	end

	__Doc__[[Get the file's last modified time]]
	__PipeRead__ (function(path) return strformat("forfiles /p \"%s\" /M \"%s\" /C \"cmd /c echo @fdate @ftime\"", path:gsub("/", "\\"):match("^(.+)[\\/](.-)$")) end, "[^\n]+", OSType.Windows)
	__PipeRead__ ("export PATH='/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/X11/bin'\nls -l -T \"%s\"", formatMacTime, OSType.MacOS)
	__PipeRead__ ("ls --full-time \"%s\"", "%d+-%d+-%d+%s+[%d:]+", OSType.Linux)
	function GetLastWriteTime(path, result)
		if not result then Error("[System.IO.File][GetLastWriteTime][Fail] %s - %s", path, result or "nil") end
		return result
	end

	__Doc__[[Get the file's last access time]]
	__PipeRead__ (function(path) return strformat("dir /t:a \"%s\"", path:gsub("/", "\\")) end, "%d+/%d+/%d+%s+[%d:]+", OSType.Windows)
	__PipeRead__ ("export PATH='/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/X11/bin'\nls -l -T -u \"%s\"", formatMacTime, OSType.MacOS)
	__PipeRead__ ("ls --full-time -u \"%s\"", "%d+-%d+-%d+%s+[%d:]+", OSType.Linux)
	function GetLastAccessTime(path, result)
		if not result then Error("[System.IO.File][GetLastAccessTime][Fail] %s - %s", path, result or "nil") end
		return result
	end

	__Doc__[[Whether the file is existed]]
	function Exist(path) local f = fopen(path, "r") if f then f:close() return true end return false  end
end)