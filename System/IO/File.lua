--=============================
-- System.IO.File
--
-- Author : Kurapica
-- Create Date : 2016/01/28
--=============================
_ENV = Module "System.IO.File" "1.0.0"

namespace "System.IO"

__Final__() __Sealed__() __Abstract__()
class "File" (function (_ENV)
	local function formatMacTime(result)
		local month, day, time, year = result:match("(%d+)%s+(%d+)%s+(%d+:%d+:%d+)%s+(%d+)")
		return ("%d-%d-%d %s"):format(year, month, day, time)
	end

	__Doc__[[Get the file's creation time]]
	__PipeRead__ ("dir /t:c \"%s\"", "%d+/%d+/%d+%s+[%d:]+", OSType.Windows)
	__PipeRead__ ("ls -l -T -U \"%s\"", formatMacTime, OSType.MacOS)
	__PipeRead__ ("ls --full-time \"%s\"", "%d+-%d+-%d+%s+[%d:]+", OSType.Linux)
	function GetCreationTime(result, path) return result end

	__Doc__[[Get the file's last modified time]]
	__PipeRead__ (function(path) return strformat("forfiles /p \"%s\" /M \"%s\" /C \"cmd /c echo @fdate @ftime\"", path:match("^(.+)[\\/](.-)$")) end, "[^\n]+", OSType.Windows)
	__PipeRead__ ("ls -l -T \"%s\"", formatMacTime, OSType.MacOS)
	__PipeRead__ ("ls --full-time \"%s\"", "%d+-%d+-%d+%s+[%d:]+", OSType.Linux)
	function GetLastWriteTime(result, path) return result end

	__Doc__[[Get the file's last access time]]
	__PipeRead__ ("dir /t:a \"%s\"", "%d+/%d+/%d+%s+[%d:]+", OSType.Windows)
	__PipeRead__ ("ls -l -T -u \"%s\"", formatMacTime, OSType.MacOS)
	__PipeRead__ ("ls --full-time -u \"%s\"", "%d+-%d+-%d+%s+[%d:]+", OSType.Linux)
	function GetLastAccessTime(result, path) return result end
end)