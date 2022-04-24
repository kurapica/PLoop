--===========================================================================--
--                                                                           --
--                        System.IO.Resource.LuaLoader                        --
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
    namespace "System.IO.Resource"

    __Sealed__() __ResourceLoader__"lua"
    class "LuaLoader"                   (function (_ENV)
        extend "IResourceLoader"

        export {
            pairs                       = pairs,
            strlower                    = string.lower,
            getfilename                 = System.IO.Path.GetFileNameWithoutSuffix,
            getname                     = Namespace.GetNamespaceName,
            require                     = _G.require,
            loadfile                    = _G.loadfile,
            setfenv                     = _G.setfenv or false,
            loadsnippet                 = Toolset.loadsnippet,
            pcall                       = pcall,
            error                       = error,

            Runtime,
        }

        function Load(self, path, reader, env)
            local name                  = strlower(getfilename(path))

            local type

            local ontypedefined         = function(ftype, target)
                if strlower(getname(target, true)) == name then
                    type                = target
                end
            end

            Runtime.OnTypeDefined       = Runtime.OnTypeDefined + ontypedefined

            local func, msg

            if reader then
                func, msg               = loadsnippet(reader:ReadToEnd(), path, env)
                if func then
                    func, msg           = pcall(func)
                end
            else
                func, msg               = loadfile(path, nil, env)
                if func then
                    if setfenv and env then setfenv(func, env) end
                    func, msg           = pcall(func)
                end
            end

            Runtime.OnTypeDefined       = Runtime.OnTypeDefined - ontypedefined

            if not func then error(msg, 0) end

            return type
        end
    end)
end)