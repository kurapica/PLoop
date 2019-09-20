--===========================================================================--
--                                                                           --
--                            System.IO.Directory                            --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2018/03/29                                               --
-- Update Date  :   2019/09/20                                               --
-- Version      :   1.1.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.IO"

    __Final__() __Sealed__() __Abstract__()
    class "Directory" (function (_ENV)

        export {
            strfind             = string.find,
            strmatch            = string.match,
            strgmatch           = string.gmatch,
            strsub              = string.sub,
            strgsub             = string.gsub,
            strformat           = string.format,
            select              = select,
            yield               = coroutine.yield,
        }

        if OperationSystem.Current == OperationSystemType.Windows then
            --- Get sub-directories
            __PipeRead__("dir /A:D /b \"%s\"", ".*", OperationSystemType.Windows)
            __Iterator__()
            __Static__()
            function GetDirectories(path, result)
                if result then
                    for word in strgmatch(result, "[^\n]+") do
                        yield(word)
                    end
                end
            end

            --- Get files
            __PipeRead__("dir /A:-D /b \"%s\"", ".*", OperationSystemType.Windows)
            __Iterator__()
            __Static__()
            function GetFiles(path, result)
                if result then
                    for word in strgmatch(result, "[^\n]+") do
                        yield(word)
                    end
                end
            end
        else
            --- Get sub-directories
            __PipeRead__("ls --file-type \"%s\"", ".*", OperationSystemType.Linux)
            __PipeRead__("export PATH='/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/X11/bin'\nls --file-type \"%s\"", ".*", OperationSystemType.MacOS)
            __Iterator__()
            __Static__()
            function GetDirectories(path, result)
                if result then
                    for word in strgmatch(result, "%S+") do
                        if strsub(word, -1) == "/" then
                            yield(strsub(word, 1, -2))
                        end
                    end
                end
            end

            --- Get files
            __PipeRead__("ls --file-type \"%s\"", ".*", OperationSystemType.Linux)
            __PipeRead__("export PATH='/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/X11/bin'\nls --file-type \"%s\"", ".*", OperationSystemType.MacOS)
            __Iterator__()
            __Static__()
            function GetFiles(path, result)
                if result then
                    for word in strgmatch(result, "%S+") do
                        if not strsub(word, -1) == "/" then
                            yield(word)
                        end
                    end
                end
            end
        end

        --- Whether the target directory existed
        __PipeRead__ ("IF EXIST \"%s\" (echo exist) ELSE (echo missing)", "exist", OperationSystemType.Windows)
        __PipeRead__ ("[ -d \"%s\" ] && echo \"exist\" || echo \"missing\"", "exist", OperationSystemType.MacOS + OperationSystemType.Linux)
        __Static__()
        function Exist(dir, result)
            return result == "exist"
        end

        --- Create directory if not existed
        __PipeRead__ (function(dir) return strformat("export PATH='/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/X11/bin'\n[ ! -d \"%s\" ] && mkdir -p \"%s\"", dir, dir) end, "", OperationSystemType.MacOS + OperationSystemType.Linux)
        __PipeRead__ (function(dir) return strformat("IF NOT EXIST \"%s\" (mkdir \"%s\")", dir, dir) end, "", OperationSystemType.Windows)
        __Static__()
        function Create(dir)
        end

        --- Delete the directory
        __PipeRead__ (function(dir) if dir:match("^%s*/%s*$") then return end return strformat("export PATH='/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/X11/bin'\nrm -rf \"%s\"", dir) end, "", OperationSystemType.MacOS + OperationSystemType.Linux)
        __PipeRead__ (function(dir) return strformat("rd /q /s \"%s\"", dir) end, "", OperationSystemType.Windows)
        __Static__()
        function Delete(dir)
        end
    end)
end)
