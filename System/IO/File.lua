--===========================================================================--
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
            fopen               = _G.io and _G.io.open or Toolset.fakefunc,
            strmatch            = string.match,
            strformat           = string.format,
            strgsub             = string.gsub,
            type                = type,
            error               = error,
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

        __Static__()
        function Copy(source, target, force)
            if type(source) ~= "string" then error("Usage: Path.Copy(source, target) - the source must be a string", 2) end
            if type(target) ~= "string" then error("Usage: Path.Copy(source, target) - the target must be a string", 2) end

            if not force then
                local f         = fopen(target, "r")
                if f then f:close() error("Usage: Path.Copy(source, target) - the target already existed", 2) end
            end

            source              = fopen(source, "rb")
            if not source then error("Usage: Path.Copy(source, target) - the source file can't be open", 2) end

            target              = fopen(target, "wb")
            if not target then error("Usage: Path.Copy(source, target) - the target file is not valid", 2) end

            local line          = source:read(100)
            while line do
                target:write(line)
                if #line == 100 then
                    line        = source:read(100)
                else
                    break
                end
            end

            source:close()
            target:close()
        end

        __PipeRead__ (function(source, target) return strformat("export PATH='/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/X11/bin'\nmv \"%s\" \"%s\"", source, target) end, "", OperationSystemType.MacOS + OperationSystemType.Linux, 2)
        __PipeRead__ (function(source, target) return strformat("move /Y \"%s\" \"%s\"", source:gsub("/", "\\"), target:gsub("/", "\\")) end, "", OperationSystemType.Windows, 2)
        __Static__()
        function Move(source, target)
        end
    end)
end)