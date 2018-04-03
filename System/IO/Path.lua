--===========================================================================--
--                                                                           --
--                              System.IO.Path                               --
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
    class "Path" (function (_ENV)

        export {
            strfind             = string.find,
            strmatch            = string.match,
            strsub              = string.sub,
            strgsub             = string.gsub,
            select              = select,
        }

        --- Get the current operation path
        __PipeRead__ ("echo %%cd%%", "[^\n]+", OperationSystemType.Windows, 0)
        __PipeRead__ ("pwd", "[^\n]+", OperationSystemType.MacOS + OperationSystemType.Linux, 0)
        __Static__()
        function GetCurrentPath(result) return result end

        --- Whether the path contains the root path
        __Static__()
        function IsPathRooted(path) return (strfind(path, "^[\\/]") or strfind(path, "^%a:[\\/]")) and true or false end

        --- Get the root of the path
        __Static__()
        function GetPathRoot(path) return (strmatch(path, "^[\\/]") or strmatch(path, "^%a:[\\/]")) end

        --- Get the directory of the path, if the path is a root, empty string would be returned.
        __Static__()
        function GetDirectory(path) return strgsub(strsub(path, 1, -2), "[^\\/]*$", "") end

        --- Combine the paths
        __Static__()
        function CombinePath(...)
            local path
            local dirSep
            local up
            for i = 1, select('#', ...) do
                local part = select(i, ...)
                if not path then
                    local root = GetPathRoot(part)
                    if root then
                        path = part
                        if #root == 1 then dirSep = root else dirSep = strsub(root, -1) end
                    end
                else
                    -- Check . & ..
                    part, up = strgsub(part, "^%.%.[\\/]", "")
                    while up > 0 do
                        local updir = GetDirectory(path)
                        if updir and #updir > 0 then path = updir end

                        part, up = strgsub(part, "^%.%.[\\/]", "")
                    end

                    repeat part, up = strgsub(part, "^%.[\\/]", "") until up == 0

                    local prevSep, nxtSep = strfind(path, "[\\/]$"), strfind(part, "^[[\\/]")
                    if prevSep and nxtSep then
                        path = path .. strsub(part, 2)
                    elseif prevSep or nxtSep then
                        path = path .. part
                    else
                        path = path .. dirSep .. part
                    end
                end
            end
            return path
        end

        --- Get the suffix of the path, include the '.'
        __Static__()
        function GetSuffix(path) return strmatch(path, "%.[^%.]*$") end

        --- Get the file name
        __Static__()
        function GetFileName(path) return strmatch(path, "[^\\/]*$") end

        --- Get the file name without the suffix
        __Static__()
        function GetFileNameWithoutSuffix(path) return (strgsub(GetFileName(path), "%.[^%.]*$", "")) end

        export {
            GetFileName         = Path.GetFileName,
            GetDirectory        = Path.GetDirectory,
            GetPathRoot         = Path.GetPathRoot,
        }
    end)
end)
