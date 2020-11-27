--===========================================================================--
--                                                                           --
--                         System.Web.IOutputLoader                          --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2016/04/11                                               --
-- Update Date  :   2020/06/04                                               --
-- Version      :   1.2.1                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Web"

    import "System.Configuration"

    --- Represents the render config of pages
    __Sealed__() class "RenderConfig" (function (_ENV)

        export { pairs = pairs, IRenderEngine }

        __Sealed__() struct "ConfigType" {
            { name = "master",      type = String  },
            { name = "helper",      type = String  },
            { name = "reload",      type = Boolean },
            { name = "encode",      type = Boolean },
            { name = "noindent",    type = Boolean },
            { name = "nolinebreak", type = Boolean },
            { name = "linebreak",   type = String },
            { name = "engine",      type = -IRenderEngine },
            { name = "asinterface", type = Boolean },
            { name = "export",      type = Table },
            { name = "comment",     type = String },
        }

        local function getdefault(self, name)
            local value = self.appconfig and self.appconfig[name]
            if value == nil then
                value   = self.webconfig and self.webconfig[name]
            end
            return value
        end

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- The default config of web
        property "webconfig"    { type = RenderConfig }

        --- The default config of web application
        property "appconfig"    { type = RenderConfig }

        --- The master (super class page) of the page
        property "master"       { type = String, default = function(self) return getdefault(self, "master") end }

        --- The helper (extend interface page) of the page
        property "helper"       { type = String, default = function(self) return getdefault(self, "helper") end }

        --- The code file
        property "code"         { type = String }

        --- Whether reload the file when modified in non-debug mode
        property "reload"       { type = Boolean, default = function(self) return getdefault(self, "reload") end }

        --- Whether auto encode the output with HtmlEncode(only for expressions)
        property "encode"       { type = Boolean, default = function(self) return getdefault(self, "encode") end }

        --- Whether discard the indent of the output.
        property "noindent"     { type = Boolean, default = function(self) return getdefault(self, "noindent") end }

        --- Whether discard the line breaks of the output.
        property "nolinebreak"  { type = Boolean, default = function(self) return getdefault(self, "nolinebreak") end }

        --- The line break chars.
        property "linebreak"    { type = String, default = function(self) return getdefault(self, "linebreak") end }

        --- The render engine of the output page.
        property "engine"       { type = -IRenderEngine, default = function(self) return getdefault(self, "engine") end }

        --- The target resource's type
        property "asinterface"  { type = Boolean, default = function(self) return getdefault(self, "asinterface") end }

        --- The export variables so can be used directly, only support key-value pairs
        property "export"       { type = Table }

        --- The comment pattern to be used as debug information
        property "comment"      { type = String, default = function(self) return getdefault(self, "comment") end }

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        __Arguments__{ RenderConfig/nil, RenderConfig/nil }
        function __ctor(self, webconfig, appconfig)
            self.webconfig      = webconfig
            self.appconfig      = appconfig
        end

        -----------------------------------------------------------------------
        --                            meta-method                            --
        -----------------------------------------------------------------------
        __Arguments__ { ConfigType }
        function __call(self, tbl)
            for k, v in pairs(tbl) do self[k] = v end
            return self
        end
    end)

    --- The page render attribute
    __Sealed__() __NoRawSet__(false) __NoNilValue__(false)
    class "__PageRender__" (function(_ENV)
        extend "IApplyAttribute" "IAttachAttribute"

        export {
            type                = type,
            IsObjectType        = Class.IsObjectType,
            ApplyEnv            = Environment.Apply,

            RenderConfig, Application, Web
        }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        function ApplyAttribute(self, target, targettype, manager, owner, name, stack)
            local base          = self.Base
            local webconfig     = RenderConfig(base and base.WebRenderConfig)

            if self.RenderConfig then webconfig(self.RenderConfig) end

            local getappconfig  = function(self, app)
                local configs   = app[RenderConfig]
                return configs and configs[self] or base and base.AppRenderConfig[app]
            end

            ApplyEnv(manager, function(_ENV)
                __Static__() property "WebRenderConfig" { set = false, default = webconfig }
                __Static__() __Indexer__(Application) property "AppRenderConfig" { set = false, get = getappconfig }
            end)
        end

        function AttachAttribute(self, target, targettype, owner, name, stack)
            local cname         = self.ConfigName
            local base          = self.Base
            local section       = Web.ConfigSection.View

            section.Field[cname]= RenderConfig.ConfigType
            section.OnFieldParse= section.OnFieldParse + function(self, fld, val)
                if fld == cname then
                    target.WebRenderConfig(val)
                end
            end

            section             = Application.ConfigSection.View

            section.Field[cname]= RenderConfig.ConfigType
            section.OnFieldParse= section.OnFieldParse + function(self, fld, val, app)
                if fld == cname and IsObjectType(app, Application) then
                    local configs       = app[RenderConfig] or {}
                    configs[target]     = RenderConfig(nil, base and base.AppRenderConfig[app])(val)
                    app[RenderConfig]   = configs
                end
            end
        end

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        property "AttributeTarget"  { set = false, default = AttributeTargets.Class + AttributeTargets.Interface }

        --- The config name
        property "ConfigName"       { type = String }

        --- The base loader
        property "Base"             { type = -IOutputLoader }

        --- The default render config
        property "RenderConfig"     { type = RenderConfig.ConfigType }

        -----------------------------------------------------------------------
        --                           constructor                             --
        -----------------------------------------------------------------------
        __Arguments__{ NEString, -IOutputLoader/nil, RenderConfig.ConfigType/nil }
        function __ctor(self, name, base, config)
            self.ConfigName     = name
            self.Base           = base
            self.RenderConfig   = config
        end
    end)

    --- Represents the interface of the context output loader
    __Sealed__() __PageRender__"Default"
    interface "IOutputLoader" (function (_ENV)
        extend (IO.Resource.IResourceLoader)

        local CODE_LINE_MAP = {}

        export {
            CURRENT_ROOT        = IO.Path.GetCurrentPath():lower(),

            with                = with,

            loadstring          = _G.loadstring or load,
            loadsnippet         = Toolset.loadsnippet,
            pcall               = pcall,
            error               = error,
            assert              = assert,
            tonumber            = tonumber,
            strlower            = string.lower,
            strfind             = string.find,
            strsub              = string.sub,
            strgsub             = string.gsub,
            fopen               = io.open,
            tinsert             = table.insert,
            tblconcat           = table.concat,
            tremove             = table.remove,
            safeset             = Toolset.safeset,
            isclass             = Class.Validate,
            isinterface         = Interface.Validate,
            getobjectclass      = Class.GetObjectClass,
            addrelatedpath      = IO.Resource.IResourceManager.AddRelatedPath,
            loadresource        = IO.Resource.IResourceManager.LoadResource,
            setreload           = IO.Resource.IResourceManager.SetReloadWhenModified,
            Trace               = Logger.Default[Logger.LogLevel.Trace],

            RCT_RecordLine      = RenderContentType.RecordLine,
            RCT_StaticText      = RenderContentType.StaticText,
            RCT_NewLine         = RenderContentType.NewLine,
            RCT_LuaCode         = RenderContentType.LuaCode,
            RCT_Expression      = RenderContentType.Expression,
            RCT_EncodeExpression= RenderContentType.EncodeExpression,
            RCT_MixMethodStart  = RenderContentType.MixMethodStart,
            RCT_MixMethodEnd    = RenderContentType.MixMethodEnd,
            RCT_CallMixMethod   = RenderContentType.CallMixMethod,
            RCT_RenderOther     = RenderContentType.RenderOther,
            RCT_InnerRequest    = RenderContentType.InnerRequest,

            IsObjectType        = Class.IsObjectType,
            GetPhysicalPath     = GetPhysicalPath,
            GetRelativePath     = GetRelativePath,
            CombinePath         = IO.Path.CombinePath,
            GetFileName         = IO.Path.GetFileName,
            getContext          = Context.GetCurrentContext,
            getnamespace        = Environment.GetNamespace,
            ApplyEnv            = Environment.Apply,
            _G                  = _G,

            saveDefinition      = function(path, definition, linebreak)
                local writer    = FileWriter(path)
                with(writer)(function()
                    writer:Write(definition:gsub("\\\n", "\\n"))
                    writer:Flush()
                end)
            end,

            RenderConfig, Class, Interface, IO.Path, IHttpOutput, IO.FileReader, IO.FileWriter,
            __Namespace__, IOutputLoader, Application, IRenderEngine, Web
        }

        class "__Export__" { IApplyAttribute,
            ApplyAttribute      = function(self, target, targettype, manager, owner, name, stack)
                if self[1] then
                    local config    = self[1]
                    local exports   = { config.export }

                    local appconfig = config.appconfig

                    while appconfig do
                        if appconfig.export then tinsert(exports, appconfig.export) end
                        appconfig   = appconfig.appconfig
                    end

                    local webconfig = config.webconfig

                    while webconfig do
                        if webconfig.export then tinsert(exports, webconfig.export) end
                        webconfig   = webconfig.webconfig
                    end

                    if exports[1] then
                        ApplyEnv(manager, function(_ENV)
                            for i = #exports, 1, -1 do
                                export(exports[i])
                            end

                            exports = nil
                        end)
                    end
                end
            end,
            AttributeTarget     = { set = false, default = AttributeTargets.Class + AttributeTargets.Interface },
            __new               = function(_, config) return { config }, true end,
        }

        -----------------------------------------------------------------------
        --                         static property                           --
        -----------------------------------------------------------------------
        --- The default config for the page's loading
        __Static__() property "WebRenderConfig" { Set = false, default = RenderConfig() }

        --- The temporary folder to save the generated code for pages
        __Static__() __Indexer__() property "TemporaryFolder" { type = String,
            set                 = function(self, app, path)
                if IsObjectType(app, Application) then
                    local set   = app[IOutputLoader] or {}
                    set.TemporaryFolder     = path
                    app[IOutputLoader]      = set
                end
            end,
            get                 = function(self, app, idx)
                if IsObjectType(app, Application) then
                    local set   = app[IOutputLoader]
                    if set then return set.TemporaryFolder end
                end
            end,
        }

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- The resource's path.
        __Abstract__() property "Path"              { type = String }

        --- The resource's target.
        __Abstract__() property "Target"            { type = AnyType }

        -----------------------------------------------------------------------
        --                           static method                           --
        -----------------------------------------------------------------------
        --- Convert the error to the real position
        __Static__() function RaiseError(err)
            local path, line, msg = err:match("%[string (%b\"\")%]:(%d+):(.-)$")
            if path then
                path        = path:sub(2, -2)
                local map   = CODE_LINE_MAP[path]
                if map then
                    line    = map[tonumber(line)]
                    if line then
                        err = ("%s:%d: %s"):format(path, line, msg)
                    end
                end
            end
            error(err, 0)
        end

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        --- load the related resource
        function LoadRelatedResource(self, path, env)
            path = GetPhysicalPath(path) or GetRelativePath(self.Path, path)
            addrelatedpath(self.Path, path)
            return loadresource(path, env)
        end

        --- load the file to output handler
        function Load(self, path, reader, env)
            Trace("[System.Web.IOutputLoader] Loading %s", path)

            reader              = reader or FileReader(path)

            with(reader)(function()
                self.Path       = path

                local ctx       = getContext()
                local loadercls = getobjectclass(self)

                if not env or not IsObjectType(env, Application) then
                    env         = ctx and ctx.Application or nil
                end

                -- The file's first line would be a configuration
                -- It can be a comment for that file so it won't cause any problems
                -- Like : <!-- { master="/share/global.master" } -->
                local config        = reader:ReadLine()
                local recordCount   = 0
                config = config and config:match("%b{}")

                if config then
                    config = config:gsub("%w+%s*=", strlower)

                    local retF = loadstring("return " .. config)
                    if retF then
                        local ok
                        ok, config = pcall(retF)
                        if not ok then config = nil end
                    else
                        config = nil
                    end
                end

                -- Generate the target
                local target
                local definition    = { IHttpOutput }

                local webconfig     = loadercls.WebRenderConfig
                local appconfig     = env and loadercls.AppRenderConfig[env]

                -- Generate the config object with default settings
                if not config then
                    reader.Position = 0
                    config = RenderConfig(webconfig, appconfig)
                else
                    recordCount     = 1
                    config = RenderConfig(webconfig, appconfig)(config)
                end

                -- reload
                if config.reload then setreload(path) end

                -- master
                if config.master and not config.asinterface then
                    local master = self:LoadRelatedResource(config.master, env)
                    assert(isclass(master), "The master page don't existed - " .. config.master)

                    tinsert(definition, master)
                end

                -- helper
                if config.helper then
                    for helper in config.helper:gmatch("[^%s,]+") do
                        local helper = self:LoadRelatedResource(helper, env)
                        assert(isinterface(helper), "The html helper don't existed - " .. config.helper)

                        tinsert(definition, helper)
                    end
                end

                -- code
                if config.code and not config.asinterface then
                    local code = self:LoadRelatedResource(config.code, env)
                    assert(isclass(code), "The code file don't existed - " .. config.code)

                    target = code
                end

                -- Generate the target
                if not target then
                    target = strlower(path)
                    if strfind(target, CURRENT_ROOT) then
                        target = strsub(target, #CURRENT_ROOT + 1)
                    end

                    target = strgsub(target, "[%p%s]", "_")

                    local ns  = env and getnamespace(env)
                    if ns then __Namespace__( ns ) end
                end

                if not config.asinterface then
                    target = Class(_G, target, definition)
                else
                    target = Interface(_G, target, definition)
                end

                self.Target = target
                definition  = nil

                -- Build the render engine
                local engine=  (config.engine or IRenderEngine)()

                -- Generate the definition
                engine:Init(self, config)

                local commentBeginPattern   = Web.DebugMode and config.comment and ([[_PL_write(%q)]]):format(config.comment:format("Generate Begin@" .. path .. " - %s: %d"))
                local commentEndPattern     = Web.DebugMode and config.comment and ([[_PL_write(%q)]]):format(config.comment:format("Generate End@" .. path .. " - %s: %d"))
                local previousMethodName
                local newLine               = true
                local wIndent               = [[_PL_write(_PL_indent)]]
                local wNewLine              = ([[_PL_write(%q)]]):format(config.linebreak or "\n")
                local wStaticText           = [[_PL_write(%q)]]
                local wExpression           = [[_PL_write(tostring(%s))]]
                local wEncodeExp            = [[_PL_write(_PL_HtmlEncode(tostring(%s)))]]
                local wIndentReg            = [[^_PL_write%("(.-)"%)$]]
                local wDefMethod            = [[function %s(self, _PL_write, _PL_indent%s) _PL_indent = _PL_indent or ""]]
                local wCallMethodIndent     = [[self:%s(_PL_write, _PL_indent.."%s"%s)]]
                local wCallMethodNoIndent   = [[self:%s(_PL_write, ""%s)]]
                local wCallMethodIFExisted  = [[if self.%s then]]

                local wCallSMethodIndent    = [[super[self]:%s(_PL_write, _PL_indent.."%s"%s)]]
                local wCallSMethodNoIndent  = [[super[self]:%s(_PL_write, ""%s)]]
                local wCallSMethodIFExisted = [[if super.%s then]]

                local wRenderOtherIndent    = [[self:RenderAnother(%s, _PL_write, _PL_indent.."%s", %s%s)]]
                local wRenderOtherNoIndent  = [[self:RenderAnother(%s, _PL_write, "", %s%s)]]
                local wInnerRequest         = [[_PL_write(tostring(select(2, self.Context:ProcessInnerRequest(%s%s))))]]

                definition = {"local _PL_HtmlEncode, tostring, select = System.Web.HtmlEncode, System.Web.ParseString, select"}

                local noindent              = config.noindent
                local linebreak             = not config.nolinebreak
                local sourceCount           = 1
                local defineCount           = 1
                --local recordLine          = {}
                local lineMap               = {}
                local pushcode              = function (line)
                    defineCount             = defineCount + 1
                    definition[defineCount] = line

                    sourceCount             = sourceCount + 1
                    lineMap[sourceCount]    = recordCount

                    if line == wNewLine then
                        sourceCount         = sourceCount + 1
                        lineMap[sourceCount]= recordCount
                    end
                end
                local removecode            = function ()
                    if definition[defineCount] == wNewLine then
                        lineMap[sourceCount]= nil
                        sourceCount         = sourceCount - 1
                    end
                    lineMap[sourceCount]    = nil
                    sourceCount             = sourceCount - 1

                    definition[defineCount] = nil
                    defineCount             = defineCount - 1
                end

                for ty, ct, params, default, issupercall in engine:GetIterator(reader) do
                    if params then
                        if params:find("%b()") then params = params:match("%b()"):sub(2, -2) end
                        if params:find("%S+") then
                            params = "," .. params
                        else
                            params = ""
                        end
                    else
                        params = ""
                    end

                    if default == "" then default = nil end

                    if ty == RCT_RecordLine then
                        recordCount         = recordCount + 1
                        --recordLine[recordCount] = ct
                    elseif ty == RCT_MixMethodStart then
                        -- ct - method name
                        pushcode(wDefMethod:format(ct, params))
                        if commentBeginPattern then
                            previousMethodName = ct
                            if linebreak then pushcode(wNewLine) if not noindent then pushcode(wIndent) end end
                            pushcode(commentBeginPattern:format(ct, recordCount))
                            if linebreak then pushcode(wNewLine) end
                        end
                    elseif ty == RCT_MixMethodEnd then
                        if definition[defineCount] == wNewLine then removecode() end
                        if commentEndPattern then
                            if linebreak then pushcode(wNewLine) if not noindent then pushcode(wIndent) end end
                            pushcode(commentEndPattern:format(previousMethodName or "Anonymous", recordCount))
                            if linebreak then pushcode(wNewLine) end
                        end
                        pushcode("end")
                    elseif ty == RCT_LuaCode then
                        pushcode(ct)
                    elseif ty == RCT_StaticText then
                        if noindent then ct = ct:gsub("^%s+", "") end
                        if ct ~= "" then
                            if newLine then
                                newLine = false
                                if not noindent then pushcode(wIndent) end
                            end
                            pushcode(wStaticText:format(ct))
                        end
                    elseif ty == RCT_NewLine then
                        if linebreak then pushcode(wNewLine) end
                        newLine = true
                    elseif ty == RCT_Expression then
                        if config.encode then
                            pushcode(wEncodeExp:format(ct))
                        else
                            pushcode(wExpression:format(ct))
                        end
                    elseif ty == RCT_EncodeExpression then
                        pushcode(wEncodeExp:format(ct))
                    elseif ty == RCT_RenderOther then
                        if noindent then
                            pushcode(wRenderOtherNoIndent:format(ct, default or "''", params))
                        else
                            -- Check previous tab&space as indent
                            local cnt = #definition
                            if cnt > 1 and definition[cnt - 1] == wIndent and definition[cnt]:find(wIndentReg) then
                                local newIndent = definition[cnt]
                                local indent = newIndent:match(wIndentReg)
                                -- Check if the indent is all space
                                if indent:gsub("%s", ""):gsub([[\9]], ""):gsub([[\32]], "") == "" then
                                    removecode() removecode()
                                    pushcode(wRenderOtherIndent:format(ct, indent, default or "''", params))
                                else
                                    pushcode(wRenderOtherIndent:format(ct, "", default or "''", params))
                                end
                            else
                                pushcode(wRenderOtherIndent:format(ct, "", default or "''", params))
                            end
                        end
                    elseif ty == RCT_InnerRequest then
                        pushcode(wInnerRequest:format(ct, params))
                    elseif ty == RCT_CallMixMethod then
                        if noindent then
                            pushcode((issupercall and wCallSMethodIFExisted or wCallMethodIFExisted):format(ct))
                            pushcode((issupercall and wCallSMethodNoIndent or wCallMethodNoIndent):format(ct, params))
                            if default ~= nil then
                                pushcode([[else]])
                                pushcode(wStaticText:format(default))
                            end
                            pushcode([[end]])
                        else
                            -- Check previous tab&space as indent
                            local cnt = #definition
                            if cnt > 1 and definition[cnt - 1] == wIndent and definition[cnt]:find(wIndentReg) then
                                local newIndent = definition[cnt]
                                local indent = newIndent:match(wIndentReg)
                                -- Check if the indent is all space
                                if indent:gsub("%s", ""):gsub([[\9]], ""):gsub([[\32]], "") == "" then
                                    removecode() removecode()
                                    pushcode((issupercall and wCallSMethodIFExisted or wCallMethodIFExisted):format(ct))
                                    pushcode((issupercall and wCallSMethodIndent or wCallMethodIndent):format(ct, indent, params))
                                    if default ~= nil then
                                        pushcode([[else]])
                                        pushcode(wIndent)
                                        pushcode(newIndent)
                                        pushcode(wStaticText:format(default))
                                    end
                                    pushcode([[end]])
                                else
                                    pushcode((issupercall and wCallSMethodIFExisted or wCallMethodIFExisted):format(ct))
                                    pushcode((issupercall and wCallSMethodIndent or wCallMethodIndent):format(ct, "", params))
                                    if default ~= nil then
                                        pushcode([[else]])
                                        pushcode(wStaticText:format(default))
                                    end
                                    pushcode([[end]])
                                end
                            else
                                pushcode((issupercall and wCallSMethodIFExisted or wCallMethodIFExisted):format(ct))
                                pushcode((issupercall and wCallSMethodIndent or wCallMethodIndent):format(ct, "", params))
                                if default ~= nil then
                                    pushcode([[else]])
                                    pushcode(wStaticText:format(default))
                                end
                                pushcode([[end]])
                            end
                        end
                    end
                end

                reader:Close()

                definition = tblconcat(definition, "\n")

                if config.nolinebreak then
                    definition = definition:gsub(([[_PL_write%%(%q%%)]]):format(config.linebreak or "\n"), "")
                end

                local tempdir   = env and IOutputLoader.TemporaryFolder[env]

                if tempdir then
                    -- Save for debug
                    tempdir     = GetPhysicalPath(tempdir)
                    if tempdir then
                        pcall(saveDefinition, CombinePath(tempdir, GetFileName(path) .. ".lua"), definition, config.linebreak or "\n")
                    end
                end

                -- Re-define the target
                local ok, err = pcall(function()
                    local def, msg  = loadsnippet("return function(_ENV) " .. definition .. " end", path, env)
                    if def then
                        def, msg    = pcall(def)
                        if def then
                            definition = msg
                        else
                            error(msg, 0)
                        end
                    else
                        error(msg, 0)
                    end

                    -- global export
                    __Export__(config)

                    if isclass(target) then
                        target = Class(_G, target, definition)
                    else
                        target = Interface(_G, target, definition)
                    end
                end)

                if not ok then
                    -- Find the real source
                    local line, msg  = err:match("%b[]:(%d+):(.-)$")
                    line        = tonumber(line)
                    if line and lineMap[line] then
                        err     = ("%s:%d: %s"):format(path, lineMap[line], msg)
                    end
                    error(err, 0)
                end

                CODE_LINE_MAP   = safeset(CODE_LINE_MAP, path, lineMap)
            end)

            return self.Target
        end
    end)

    -----------------------------------------------------------------------
    --                          config section                           --
    -----------------------------------------------------------------------
    export {
        IsObjectType            = Class.IsObjectType,
        IOutputLoader, Application
    }

    __ConfigSection__(Application.ConfigSection.View, "Temporary", String)
    function setTemporaryPath(fld, val, app)
        if IsObjectType(app, Application) then
            IOutputLoader.TemporaryFolder[app] = val
        end
    end
end)