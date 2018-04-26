--===========================================================================--
--                                                                           --
--                    System.IO.Resource.IResourceManager                    --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2018/04/01                                               --
-- Update Date  :   2018/04/01                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    --- Represents the interface of resource manager
    __AnonymousClass__()
    __Sealed__() interface "System.IO.Resource.IResourceManager" (function(_ENV)

        export {
            tostring            = tostring,
            rawget              = rawget,
            safeset             = Toolset.safeset,
            pairs               = pairs,

            Trace               = Logger.Default[Logger.LogLevel.Trace],
            Debug               = Logger.Default[Logger.LogLevel.Debug],
            existfile           = IO.File.Exist,
            loadresource        = IO.Resource.IResourceLoader.LoadResource,
            isanonymous         = Namespace.IsAnonymousNamespace,

            IResourceManager,
        }

        local _ResourcePathMap  = {}
        local _ResourceMapInfo  = {}

        local preparepath       = pcall(_G.require, [[PLoop.System.IO.Resource.casesensitivetest]]) and string.lower or function(path) return path end

        -----------------------------------------------------------------------
        --                           LoadFileInfo                            --
        -----------------------------------------------------------------------
        --- the loaded resource info
        __NoRawSet__(false) __NoNilValue__(false)
        local LoadFileInfo      = class {
            AddRelatedPath      = function (self, info)
                if self.reloadWhenModified then
                    self.relativeFiles  = self.relativeFiles or {}
                    self.relativeFiles[info] = true

                    info.notifyFileInfo = safeset(info.notifyFileInfo or {}, self, true)
                    info.notifyFileInfo = info.notifyFileInfo or {}
                    info.notifyFileInfo[self] = true
                end
            end;

            CheckReload         = function (self)
                local path          = self.resourcePath
                local requireReload = self.requireReLoad

                Trace("[System.IO.Resource][CheckReload] %s - %s", path, tostring(requireReload))

                -- Check the file
                if not requireReload then
                    if not self.resource then
                        if existfile(path) then
                            Trace("[System.IO.Resource][CheckReload] Reload because File existed")
                            requireReload = true
                        end
                    else
                        local lastWriteTime = IResourceManager.Manager.GetLastWriteTime(path)

                        if not lastWriteTime then
                            if not existfile(path) then
                                Trace("[System.IO.Resource][CheckReload] Reload because File not existed")
                                requireReload = true
                            else
                                Trace("[System.IO.Resource][CheckReload] Can't get changed status of the file")
                            end
                        elseif lastWriteTime ~= self.lastWriteTime then
                            Trace("[System.IO.Resource][CheckReload] Reload because File changed at %s", lastWriteTime)
                            requireReload = true
                        else
                            Trace("[System.IO.Resource][CheckReload] no file modified")
                        end
                    end
                end

                -- Check the required files
                if not requireReload and self.relativeFiles then
                    for info in pairs(self.relativeFiles) do info:Load() end
                end

                Trace("[System.IO.Resource][CheckReload] Result %s", tostring(requireReload or self.requireReLoad))

                -- the requireReLoad maybe changed by required files
                return requireReload or self.requireReLoad
            end;

            LoadFile            = function (self)
                local path      = self.resourcePath
                local ok, res
                if self.resource then
                    res         = loadresource(path, nil, true)
                    if not res then
                        res     = self.resource
                    else
                        Debug("[System.IO.Resource][ReGenerate] %s [For] %s", tostring(res), path)
                        if res then self.lastWriteTime = IResourceManager.Manager.GetLastWriteTime(path) end
                    end
                else
                    res         = loadresource(path)
                    Debug("[System.IO.Resource][Generate] %s [For] %s", tostring(res), path)
                    if res then self.lastWriteTime = IResourceManager.Manager.GetLastWriteTime(path) end
                end

                self.requireReLoad = false
                return res
            end;

            Load                = function (self)
                local res       = self.resource

                if res ~= nil and self.reloadWhenModified and self:CheckReload() then
                    self.requireReLoad = false
                    res         = nil
                end

                if not res then
                    res = self:LoadFile()
                    if res ~= self.resource then
                        -- notify the other files
                        if self.resource and self.notifyFileInfo then
                            for info in pairs(self.notifyFileInfo) do
                                if info.resource then
                                    info.requireReLoad = true
                                end
                            end
                        end
                        if res then _ResourceMapInfo = safeset(_ResourceMapInfo, res, self) end
                        self.resource = res
                    end
                end

                return res
            end;

            __new               = function (_, path)
                return {
                    resource        = false,
                    resourcePath    = path,
                    relativeFiles   = false,
                    notifyFileInfo  = false,
                    requireReLoad   = false,
                    lastWriteTime   = false,
                    reloadWhenModified = IResourceManager.ReloadWhenModified,
                }, true
            end;

            __ctor              = function (self)
                _ResourcePathMap    = safeset(_ResourcePathMap, self.resourcePath, self)
            end;
        }

        -----------------------------------------------------------------------
        --                          static property                          --
        -----------------------------------------------------------------------
        --- the unique resource manager
        __Static__() property "Manager"             { type = IResourceManager, handler = function(self, new, old) if old then old:Dispose() end end, default = function() return IResourceManager() end }

        --- whether reload the file when modified
        __Static__() property "ReloadWhenModified"  { type = Boolean }

        -----------------------------------------------------------------------
        --                           static method                           --
        -----------------------------------------------------------------------
        --- Load the resource
        -- @param   context         the http context
        -- @param   path            the resource path
        -- @param   current         the request current path if the resource path is relative
        __Static__() function LoadResource(path)
            path                = preparepath(path)
            local info          = _ResourcePathMap[path] or LoadFileInfo(path)
            return info:Load()
        end

        --- Get the resource's path
        -- @param   resource            the resource
        -- @return  path                the resource's file path
        __Static__() function GetResourcePath(res)
            return _ResourceMapInfo[res] and _ResourceMapInfo[res].resourcePath
        end

        --- Add a related path to the resource path for reload checking
        -- @param   path                the resource path
        -- @param   relative            the relative path
        __Static__() function AddRelatedPath(path, relative)
            path                = preparepath(path)
            relative            = preparepath(relative)
            local info          = _ResourcePathMap[path] or LoadFileInfo(path)
            local rela          = _ResourcePathMap[relative] or LoadFileInfo(relative)
            info:AddRelatedPath(rela)
        end

        --- Mark the path reload when modified
        __Static__() function SetReloadWhenModified(path)
            path                = preparepath(path)
            local info          = _ResourcePathMap[path] or LoadFileInfo(path)
            info.reloadWhenModified = true
        end

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        --- Get the resource last modified time
        __Abstract__() GetLastWriteTime = IO.File.GetLastWriteTime

        -----------------------------------------------------------------------
        --                           initializer                            --
        -----------------------------------------------------------------------
        function __init(self)
            IResourceManager.Manager = self
        end
    end)
end)