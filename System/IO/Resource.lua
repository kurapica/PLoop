--===========================================================================--
--                                                                           --
--                            System.IO.Resource                             --
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
    namespace "System.IO"

    local _ResourceLoader       = {}

    export {
        strfind                 = string.find,
        strlower                = string.lower,
        safeset                 = Toolset.safeset,
        saveloader              = function(suffix, loader) _ResourceLoader = safeset(_ResourceLoader, suffix, loader) end,
        getloader               = function(_, suffix) suffix = strlower(suffix) if not strfind(suffix, "^%.") then suffix = "." .. suffix end return _ResourceLoader[suffix] end,
    }


    --- The interface for the file loaders
    __Sealed__()
    interface "IResourceLoader" (function (_ENV)
        -----------------------------------------------------------
        --                         method                        --
        -----------------------------------------------------------
        --- Load the target resource from file or text reader
        -- @format  path
        -- @format  reader
        -- @param   path            the file path
        -- @param   reader          the text reader of the file
        __Abstract__() function Load(self, path) end

        -----------------------------------------------------------
        --                       property                       --
        -----------------------------------------------------------
        --- the loader of suffix
        __Static__() __Indexer__()
        property "Loader" { get = getloader }
    end)

    --- The resource loader for specific suffix files to generate type features or others.
    __Final__() __Sealed__()
    class "__ResourceLoader__" (function (_ENV)
        extend "IAttachAttribute"

        export { 
            getloader           = getloader,
            saveloader          = saveloader, 
            tinsert             = table.insert, 
            select              = select, 
            ipairs              = ipairs, 
            strlower            = string.lower,
            strfind             = string.find,
            strformat           = string.format,

            Class, IResourceLoader,
        }

        -----------------------------------------------------------
        --                         method                        --
        -----------------------------------------------------------
        function AttachAttribute(self, target, targettype, owner, name, stack)
            if not Class.IsSubType(target, IResourceLoader) then
                error("the class must extend System.IO.IResourceLoader", stack + 1)
            end

            for _, v in ipairs(self) do
                v   = strlower(v)
                if not strfind(suffix, "^%.") then
                    suffix = "." .. suffix
                end
                local loader = getloader(_, suffix)
                if loader then
                    error(strformat("the suffix %q has been registered by %s", suffix, loader), stack + 1)
                else
                    saveloader(suffix, target)
                end
            end
        end

        -----------------------------------------------------------
        --                       property                       --
        -----------------------------------------------------------
        --- the attribute target
        property "AttributeTarget"  { set = false, default = AttributeTargets.Class }

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{ Variable.Rest(NEString) }
        function __new(_, ...)
            return { ... }, true
        end

        -----------------------------------------------------------
        --                      meta-method                      --
        -----------------------------------------------------------
        __Abstract__{ NEString }
        function __call(self, ...)
            for i = 1, select("#", ...) do
                tinsert(self, (select(i, ...)))
            end
        end
    end)

    __Final__() __Sealed__() __Abstract__()
    class "Resource" (function (_ENV)
        _ResourcePathMap = setmetatable({}, { __index= function(self, p) return FileLoadInfo(p) end })
        _ResourceMapInfo = setmetatable({}, { __mode = "kv" })

        local preparePath

        if pcall(_G.require, [[PLoop.System.IO.casesensitivetest]]) then
            preparePath = function(path) return path:lower() end
        else
            preparePath = function(path) return path end
        end

        ----------------------------------
        -- FileLoadInfo
        ----------------------------------
        FileLoadInfo = struct {
            Path = NEString,

            __init = function(self)
                self.ReloadWhenModified = Resource.ReloadWhenModified
                _ResourcePathMap[self.Path] = self
            end,
        }

        function FileLoadInfo:AddRelatedPath(info)
            self.RequireFileInfo = self.RequireFileInfo or {}
            self.RequireFileInfo[info] = true

            info.NoticeFileInfo = self.NoticeFileInfo or {}
            info.NoticeFileInfo[self] = true
        end

        function FileLoadInfo:CheckReload()
            local requireReload = self.RequireReLoad

            Trace("[System.IO.Resource][CheckReload] %s - %s", self.Path, tostring(requireReload))

            -- Check the file
            if not requireReload then
                local path = self.Path

                if not self.Resource then
                    if File.Exist(path) then
                        Trace("[System.IO.Resource][CheckReload] Reload because File existed")
                        requireReload = true
                    end
                else
                    local lastWriteTime = Resource.GetLastWriteTime(path)

                    if not lastWriteTime then
                        if not File.Exist(path) then
                            Trace("[System.IO.Resource][CheckReload] Reload because File not existed")
                            requireReload = true
                        else
                            Trace("[System.IO.Resource][CheckReload] Can't get changed status of the file")
                        end
                    elseif lastWriteTime ~= self.LastWriteTime then
                        Trace("[System.IO.Resource][CheckReload] Reload because File changed at %s", lastWriteTime)
                        requireReload = true
                    else
                        Trace("[System.IO.Resource][CheckReload]%s == %s", lastWriteTime, self.LastWriteTime)
                    end
                end
            end

            -- Check the required files
            if not requireReload and self.RequireFileInfo then
                for info in pairs(self.RequireFileInfo) do info:Load() end
            end

            Trace("[System.IO.Resource][CheckReload] Result %s", tostring(requireReload or self.RequireReLoad))

            -- the RequireReLoad maybe changed by required files
            return requireReload or self.RequireReLoad
        end

        function FileLoadInfo:LoadFile()
            local path = self.Path
            local suffix = Path.GetSuffix(path)
            local loader = suffix and __ResourceLoader__.GetResourceLoader(suffix:lower())
            local res
            if loader then
                res = loader():Load(path) or false
                if res and self.ReloadWhenModified then self.LastWriteTime = Resource.GetLastWriteTime(path) end
                Debug("[System.IO.Resource][Generate] %s [For] %s", tostring(res), path)
            end

            self.RequireReLoad = false

            if res then
                _ResourcePathMap[path] = self
            elseif _ResourcePathMap[path] then
                if not self.NoticeFileInfo then
                    _ResourcePathMap[path] = nil
                end
            end

            return res
        end

        function FileLoadInfo:Load()
            local res = self.Resource

            if res ~= nil and self.ReloadWhenModified and self:CheckReload() then
                if res and not Reflector.GetSuperNameSpace(res) and self.RequireFileInfo then
                    -- Mark the same resource must be reloaded
                    for info in pairs(self.RequireFileInfo) do if info.Resource == res then info.RequireReLoad = true end end
                end

                self.RequireReLoad = false
                res = nil
            end

            if not res then
                res = self:LoadFile()
                if res ~= self.Resource then
                    -- Notice the other files
                    if self.NoticeFileInfo and Resource.ReloadWhenModified then
                        for info in pairs(self.NoticeFileInfo) do
                            if info.Resource and not Reflector.GetSuperNameSpace(info.Resource) then
                                info.RequireReLoad = true
                            end
                        end
                    end
                    if res then _ResourceMapInfo[res] = self end
                    self.Resource = res
                end
            end

            return res
        end

        ----------------------------------
        -- Static Property
        ----------------------------------
        __Static__()
        property "ReloadWhenModified" { Type = Boolean }

        __Static__()
        property "GetLastWriteTime" { Type = Callable }

        ----------------------------------
        -- Static Method
        ----------------------------------
        --- Load the target resource files
        __Static__()
        function LoadResource(path)
            if type(path) ~= "string" then return end
            return _ResourcePathMap[preparePath(path)]:Load()
            --[[local ok, res = pcall(FileLoadInfo.Load, FileLoadInfo(path))

            if ok then return res end

            Error("[System.IO.Resource][Load Fail] %s - %s", path, res)--]]
        end

        --- Get the resource's path
        __Static__()
        function GetResourcePath(res) return _ResourceMapInfo[res] and _ResourceMapInfo[res].Path end

        --- Add the related path for reload checking
        __Static__()
        __Arguments__{ NEString, NEString }
        function AddRelatedPath(path, related)
            local info = rawget(_ResourcePathMap, preparePath(path))
            if info then
                info:AddRelatedPath(_ResourcePathMap[preparePath(related)])
            end
        end

        --- Mark the path reload when modified
        __Static__()
        __Arguments__{ NEString }
        function SetReloadRequired(path)
            _ResourcePathMap[preparePath(path)].ReloadWhenModified = true
        end
    end)

    -- Bind the default func
    Resource.GetLastWriteTime = File.GetLastWriteTime
end)