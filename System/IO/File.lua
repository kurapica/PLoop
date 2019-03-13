###--===========================================================================--
--                                                                           --
--                              System.IO.File                               --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2016/01/28                                               --
-- Update Date  :   2018/03/26                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.IO"

    __Final__() __Sealed__() __Abstract__()
    class "File" (function (_ENV)
        export {
            fopen               = _G.io.open,
            strmatch            = string.match,
            strformat           = string.format,
            strgsub             = string.gsub,
            Error               = Logger.Default[Logger.LogLevel.Error],
        }

        local function formatMacTime(result)
            if result then
                local month, day, time, year = strmatch(result, "(%w+)%s+(%d+)%s+(%d+:%d+:%d+)%s+(%d+)")
                if month then
                    return ("%s-%s-%s %s"):format(year, month, day, time)
                end
            end
        end

        --- Get the file's creation time
        __PipeRead__ (function(path) return strformat("dir /t:c \"%s\"", strgsub(path, "/", "\\")) end, "%d+/%d+/%d+%s+[%d:]+", OperationSystemType.Windows)
        __PipeRead__ ("export PATH='/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/X11/bin'\nls -l -T -U \"%s\"", formatMacTime, OperationSystemType.MacOS)
        __PipeRead__ ("ls --full-time \"%s\"", "%d+-%d+-%d+%s+[%d:]+", OperationSystemType.Linux)
        __Static__()
        function GetCreationTime(path, result)
            if not result then Error("[System.IO.File][GetCreationTime][Fail] %s - %s", path, result or "nil") end
            return result
        end

        --- Get the file's last modified time
        __PipeRead__ (function(path) return strformat("forfiles /p \"%s\" /M \"%s\" /C \"cmd /c echo @fdate @ftime\"", strmatch(strgsub(path, "/", "\\"), "^(.+)[\\/](.-)$")) end, "[^\n]+", OperationSystemType.Windows)
        __PipeRead__ ("export PATH='/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/X11/bin'\nls -l -T \"%s\"", formatMacTime, OperationSystemType.MacOS)
        __PipeRead__ ("ls --full-time \"%s\"", "%d+-%d+-%d+%s+[%d:]+", OperationSystemType.Linux)
        __Static__()
        function GetLastWriteTime(path, result)
            if not result then Error("[System.IO.File][GetLastWriteTime][Fail] %s - %s", path, result or "nil") end
            return result
        end

        --- Get the file's last access time
        __PipeRead__ (function(path) return strformat("dir /t:a \"%s\"", strgsub(path, "/", "\\")) end, "%d+/%d+/%d+%s+[%d:]+", OperationSystemType.Windows)
        __PipeRead__ ("export PATH='/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/X11/bin'\nls -l -T -u \"%s\"", formatMacTime, OperationSystemType.MacOS)
        __PipeRead__ ("ls --full-time -u \"%s\"", "%d+-%d+-%d+%s+[%d:]+", OperationSystemType.Linux)
        __Static__()
        function GetLastAccessTime(path, result)
            if not result then Error("[System.IO.File][GetLastAccessTime][Fail] %s - %s", path, result or "nil") end
            return result
        end

        --- Whether the file is existed
        __Static__()
        function Exist(path) local f = fopen(path, "r") if f then f:close() return true end return false end

        --- Delete the file
        __PipeRead__ (function(path) return strformat("export PATH='/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/X11/bin'\nrm -f \"%s\"", path) end, "", OperationSystemType.MacOS + OperationSystemType.Linux)
        __PipeRead__ (function(path) return strformat("del /f \"%s\"", path) end, "", OperationSystemType.Windows)
        __Static__()
        function Delete(path)
        end
    end)
end)