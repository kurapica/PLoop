--===========================================================================--
--                                                                           --
--                    System.IO.ResourceLoader.LuaLoader                     --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2016/01/28                                               --
-- Update Date  :   2018/03/16                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    __Sealed__() System.IO.__ResourceLoader__"lua"
    class "System.IO.ResourceLoader.LuaLoader" (function (_ENV)
        inherit (System.IO.ResourceLoader)

        export {
            pairs               = pairs,
            strlower            = string.lower,
            getfilename         = System.IO.Path.GetFileNameWithoutSuffix,
            getname             = Namespace.GetNamespaceName,
            require             = _G.require,
            loadfile            = _G.loadfile,
            Error               = Logger.Default[Logger.LogLevel.Error],

            Runtime,
        }

        function Load(self, path)
            local name = strlower(getfilename(path))

            local type

            local ontypedefined     = function(ftype, target)
                if strlower(getname(target, true)) == name then
                    type = target
                end
            end

            Runtime.OnTypeDefined   = Runtime.OnTypeDefined + ontypedefined

            local func, msg         = loadfile(path)

            if func then
                local ok, ret       = pcall(func)
                if not ok then Error(ret) end
            else
                Error(msg)
            end

            Runtime.OnTypeDefined   = Runtime.OnTypeDefined - ontypedefined

            return type
        end
    end)
end)