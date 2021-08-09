--===========================================================================--
--                                                                           --
--                       Attribute for ContextHandlers                       --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2018/04/04                                               --
-- Update Date  :   2020/06/29                                               --
-- Version      :   1.4.3                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Web"

    --- The context handler wrapper for text
    __Sealed__() __NoRawSet__(false) __NoNilValue__(false)
    class "__Text__" (function(_ENV)
        extend "IInitAttribute"

        export {
            type                = type,
            unpack              = unpack,
            issubtype           = Class.IsSubType,
            parseString         = ParseString,
            HEAD_PHASE          = IHttpContextHandler.ProcessPhase.Head,
            Error               = Logger.Default[Logger.LogLevel.Error],

            IHttpContextHandler, AttributeTargets, __Text__, HTTP_STATUS, Controller
        }

        local processHandler    = function(self, context, phase)
            local response      = context.Response
            if response.RequestRedirected or response.StatusCode ~= HTTP_STATUS.OK then return end

            if phase == HEAD_PHASE then
                local iter, obj, idx    = self[2](context)
                if response.RequestRedirected or response.StatusCode ~= HTTP_STATUS.OK then return end

                local tyrs              = iter and type(iter)

                if tyrs == "string" then
                    response.ContentType= "text/plain"
                    context[__Text__]   = parseString(iter)
                elseif tyrs == "function" then
                    response.ContentType= "text/plain"
                    local m
                    idx, m              = iter(obj, idx) -- We could handle features like cookies before send text
                    context[__Text__]   = { iter, obj, idx, m or idx }
                elseif tyrs == "table" then
                    response.ContentType= "text/plain"
                    context[__Text__]   = parseString(iter, obj)
                else
                    Error("The function %q failed to return any value can be output as text", self[1])
                    response.StatusCode = HTTP_STATUS.SERVER_ERROR
                end
            else
                local write     = response.Write
                local content   = context[__Text__]
                if content then
                    if type(content) == "table" then
                        if content[4] then
                            write(parseString(content[4]))

                            for idx, text in unpack(content, 1, 3) do
                                write(parseString(text or idx))
                            end
                        end
                    else
                        write(parseString(content))
                    end
                end
            end
        end

        TextContextHandler      = class { IHttpContextHandler,
            Process = processHandler,
            __call  = processHandler,
            __new   = function(_, name, target ) return { name, target }, true end,
        }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- modify the target's definition
        -- @param   target                      the target
        -- @param   targettype                  the target type
        -- @param   definition                  the target's definition
        -- @param   owner                       the target's owner
        -- @param   name                        the target's name in the owner
        -- @param   stack                       the stack level
        -- @return  definition                  the new definition
        function InitDefinition(self, target, targettype, definition, owner, name, stack)
            if targettype == AttributeTargets.Method and issubtype(owner, Controller) then
                return function (self, ...) return self:Text(definition(self, ...)) end
            elseif targettype == AttributeTargets.Function then
                return TextContextHandler(name, definition)
            end
        end

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- the attribute target
        property "AttributeTarget"  { set = false, default = AttributeTargets.Function + AttributeTargets.Method }
        property "Priority"         { set = false, default = AttributePriority.Lowest }
    end)

    --- The context handler wrapper for json
    __Sealed__() __NoRawSet__(false) __NoNilValue__(false)
    class "__Json__" (function(_ENV)
        extend "IInitAttribute"

        export {
            serialize           = Serialization.Serialize,
            HEAD_PHASE          = IHttpContextHandler.ProcessPhase.Head,
            issubtype           = Class.IsSubType,
            type                = type,
            Error               = Logger.Default[Logger.LogLevel.Error],

            IHttpContextHandler, Serialization.JsonFormatProvider, Controller, AttributeTargets, __Json__, HTTP_STATUS,
        }

        local processHandler    = function(self, context, phase)
            local response      = context.Response
            if response.RequestRedirected or response.StatusCode ~= HTTP_STATUS.OK then return end

            if phase == HEAD_PHASE then
                local data,dtype= self[2](context)
                if response.RequestRedirected or response.StatusCode ~= HTTP_STATUS.OK then return end

                if data then
                    response.ContentType    = "application/json"
                    if context.IsInnerRequest then -- and context.RawContext.ProcessPhase == HEAD_PHASE then
                        context:SaveJsonData(data, dtype)
                    else
                        context[__Json__]   = { data, dtype }
                    end
                else
                    Error("The function %q failed to return a json data", self[1])
                    response.StatusCode     = HTTP_STATUS.SERVER_ERROR
                end
            else
                local content   = context[__Json__]
                if content then
                    if type(content[1]) == "table" then
                        if content[2] then
                            serialize(JsonFormatProvider(), content[1], content[2], response.Write)
                        else
                            serialize(JsonFormatProvider(), content[1], response.Write)
                        end
                    elseif type(content[1]) == "string" then
                        response.Write(content[1])
                    end
                end
            end
        end

        JsonContextHandler      = class { IHttpContextHandler,
            Process = processHandler,
            __call  = processHandler,
            __new   = function(_, name, target) return { name, target }, true end,
        }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- modify the target's definition
        -- @param   target                      the target
        -- @param   targettype                  the target type
        -- @param   definition                  the target's definition
        -- @param   owner                       the target's owner
        -- @param   name                        the target's name in the owner
        -- @param   stack                       the stack level
        -- @return  definition                  the new definition
        function InitDefinition(self, target, targettype, definition, owner, name, stack)
            if targettype == AttributeTargets.Method and issubtype(owner, Controller) then
                return function (self, ...) return self:Json(definition(self, ...)) end
            elseif targettype == AttributeTargets.Function then
                return JsonContextHandler(name, definition)
            end
        end

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- the attribute target
        property "AttributeTarget"  { set = false, default = AttributeTargets.Function + AttributeTargets.Method }
        property "Priority"         { set = false, default = AttributePriority.Lowest }
    end)

    __Sealed__() __NoRawSet__(false) __NoNilValue__(false)
    class "__View__" (function(_ENV)
        extend "IInitAttribute"

        export {
            type                = type,
            HEAD_PHASE          = IHttpContextHandler.ProcessPhase.Head,
            isclass             = Class.Validate,
            issubtype           = Class.IsSubType,
            GetResource         = GetResource,
            loadresource        = IO.Resource.IResourceLoader.LoadResource,
            Error               = Logger.Default[Logger.LogLevel.Error],

            IHttpContextHandler, Controller, IHttpOutput, Text.StringReader, AttributeTargets, __View__, HTTP_STATUS, Web
        }

        local processView       = function(self, default, path, data)
            if self.IsFinished then return end

            local typath        = type(path)
            if typath == "table" then
                path, data      = default, path
            elseif typath ~= "string" then
                path, data      = default
            end

            if not path then return self:ServerError() end
            if data and type(data) ~= "table" then data = nil end

            return self:View(path, data)
        end

        local processHandler    = function(self, context, phase)
            local response      = context.Response
            if response.RequestRedirected or response.StatusCode ~= HTTP_STATUS.OK then return end

            if phase == HEAD_PHASE then
                local path, data= self[2](context)
                if response.RequestRedirected or response.StatusCode ~= HTTP_STATUS.OK then return end

                local typath    = type(path)
                if typath == "table" then
                    path, data  = self[3], path
                elseif typath ~= "string" then
                    path, data  = self[3], nil
                end

                if type(data) ~= "table" then
                    data        = nil
                end

                if path then
                    if self[4] and path == self[3] then
                        context[__View__]       = { self[4], data }
                        response.ContentType    = "text/html"
                    else
                        local cls               = path and GetResource(path, context)

                        if cls and issubtype(cls, IHttpOutput) then
                            context[__View__]   = { cls, data }
                            response.ContentType= "text/html"
                        else
                            Error("%s - the view page file can't be found.", self[3])
                            response.StatusCode = HTTP_STATUS.SERVER_ERROR
                        end
                    end
                else
                    Error("The function %q failed to return a view path", self[1])
                    response.StatusCode = HTTP_STATUS.SERVER_ERROR
                end
            else
                local content   = context[__View__]
                if content then
                    local view  = content[1](content[2])

                    view.Context= context
                    view:OnLoad(context)

                    return view:SafeRender(response.Write, "")
                end
            end
        end

        ViewContextHandler      = class { IHttpContextHandler,
            Process = processHandler,
            __call  = processHandler,
            __new   = function(_, name, target, path, viewcls) return { name, target, path, viewcls }, true end,
        }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- modify the target's definition
        -- @param   target                      the target
        -- @param   targettype                  the target type
        -- @param   definition                  the target's definition
        -- @param   owner                       the target's owner
        -- @param   name                        the target's name in the owner
        -- @param   stack                       the stack level
        -- @return  definition                  the new definition
        function InitDefinition(self, target, targettype, definition, owner, name, stack)
            if targettype == AttributeTargets.Method and issubtype(owner, Controller) then
                if self.Content then
                    if not self.Path then
                        error("the view path must be specified.", stack + 1)
                    end

                    local viewcls
                    local viewpath  = self.Path
                    local viewcont  = self.Content
                    return function(self, ...)
                        if viewcls ==  nil then
                            viewcls = loadresource(viewpath, StringReader(viewcont), self.Context.Application) or false
                            if not viewcls then
                                Error("The context for path - %q can't be parsed as view", viewpath)
                                return self:ServerError()
                            end
                        end

                        return processView(self, viewcls, definition(self, ...))
                    end
                else
                    local dpath = self.Path
                    if dpath then
                        return function (self, ...)
                            return processView(self, dpath, definition(self, ...))
                        end
                    else
                        return function (self, ...)
                            return processView(self, nil, definition(self, ...))
                        end
                    end
                end
            elseif targettype == AttributeTargets.Function then
                local viewcls
                if self.Content then
                    if not self.Path then
                        error("the view path must be specified.", stack + 1)
                    end

                    viewcls = loadresource(self.Path, StringReader(self.Content), owner)
                    if not (viewcls and issubtype(viewcls, IHttpOutput)) then
                        error("the context can't be parsed as view.", stack + 1)
                    end
                end

                return ViewContextHandler(name, definition, self.Path or false, viewcls or false)
            end
        end

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- the attribute target
        property "AttributeTarget"  { set = false, default = AttributeTargets.Function + AttributeTargets.Method }
        property "Priority"         { set = false, default = AttributePriority.Lowest }

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{ NEString/nil, NEString/nil }
        function __ctor(self, path, content)
            self.Path       = path
            self.Content    = content
        end

        -----------------------------------------------------------
        --                      meta-method                      --
        -----------------------------------------------------------
        __Arguments__{ NEString }
        function __call(self, content)
            self.Content    = content
        end
    end)

    --- The context handler wrapper for file
    __Sealed__() __NoRawSet__(false) __NoNilValue__(false)
    class "__File__" (function(_ENV)
        extend "IInitAttribute"

        export {
            type                = type,
            unpack              = unpack,
            issubtype           = Class.IsSubType,
            parseString         = ParseString,
            HEAD_PHASE          = IHttpContextHandler.ProcessPhase.Head,
            Error               = Logger.Default[Logger.LogLevel.Error],

            IHttpContextHandler, AttributeTargets, __File__, HTTP_STATUS, Controller, Date, Guid
        }

        local getFileName       = function(self)
            return self[3] and Date.Now:ToString(self[3]) or self[4] or Guid.New():gsub("%-", "") .. ".txt"
        end

        local processHandler    = function(self, context, phase)
            local response      = context.Response
            if response.RequestRedirected or response.StatusCode ~= HTTP_STATUS.OK then return end

            if phase == HEAD_PHASE then
                local name, iter, obj, idx = self[2](context)
                if response.RequestRedirected or response.StatusCode ~= HTTP_STATUS.OK then return end

                local tname     = type(name)

                if tname == "string" then
                    if iter then
                        tname   = type(iter)

                        if tname == "string" then
                            response.ContentType= "text/plain"
                            response.Header["Content-Disposition"] = "attachment;filename=" .. name
                            context[__File__]   = iter
                        elseif tname == "function" then
                            response.ContentType= "text/plain"
                            response.Header["Content-Disposition"] = "attachment;filename=" .. name
                            context[__File__]   = { iter, obj, idx }
                        elseif tname == "table" then
                            response.ContentType= "text/plain"
                            response.Header["Content-Disposition"] = "attachment;filename=" .. name
                            context[__File__]   = parseString(iter)
                        else
                            Error("The function %q failed to return any value can be output as file", self[1])
                            response.StatusCode = HTTP_STATUS.SERVER_ERROR
                        end
                    else
                        response.ContentType= "text/plain"
                        response.Header["Content-Disposition"] = "attachment;filename=" .. getFileName(self)
                        context[__File__]   = name
                    end
                elseif tname == "function" then
                    response.ContentType= "text/plain"

                    local fname

                    -- Check if use the first return value as the file name
                    if self[3] or self[4] then
                        fname           = getFileName(self)
                    else
                        local k, v      = name(iter, obj)
                        fname           = v or k

                        if type(fname) ~= "string" then
                            Error("The function %q failed to return a file name", self[1])
                            response.StatusCode = HTTP_STATUS.SERVER_ERROR
                            return
                        end

                        obj             = k
                    end

                    response.Header["Content-Disposition"] = "attachment;filename=" .. fname
                    context[__File__]   = { name, iter, obj }
                elseif tname == "table" then
                    response.ContentType= "text/plain"
                    response.Header["Content-Disposition"] = "attachment;filename=" .. getFileName(self)
                    context[__File__]   = parseString(name)
                else
                    Error("The function %q failed to return any value can be output as file", self[1])
                    response.StatusCode = HTTP_STATUS.SERVER_ERROR
                end
            else
                local write     = response.Write
                local content   = context[__File__]
                if content then
                    if type(content) == "table" then
                        for idx, text in unpack(content) do
                            write(parseString(text or idx))
                        end
                    else
                        write(parseString(content))
                    end
                end
            end
        end

        local processFile       = function(self, default, name, iter, obj, idx)
            local tname         = type(name)

            if tname == "string" then
                if iter then
                    tname       = type(iter)

                    if tname == "string" then
                        self:File(name, iter)
                    elseif tname == "function" then
                        self:File(name, iter, obj, idx)
                    elseif tname == "table" then
                        self:File(name, parseString(iter))
                    else
                        self:ServerError()
                    end
                else
                    self:File(default, parseString(name))
                end
            elseif tname == "function" then
                if not default then
                    local k, v  = name(iter, obj)
                    default       = v or k

                    if type(default) ~= "string" then
                        return self:ServerError()
                    end

                    obj         = k
                end

                self:File(default, name, iter, obj)
            elseif tname == "table" then
                self:File(default, parseString(name))
            else
                self:ServerError()
            end
        end

        FileContextHandler      = class { IHttpContextHandler,
            Process = processHandler,
            __call  = processHandler,
            __new   = function(_, name, target, timeformat, filename ) return { name, target, timeformat, filename }, true end,
        }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- modify the target's definition
        -- @param   target                      the target
        -- @param   targettype                  the target type
        -- @param   definition                  the target's definition
        -- @param   owner                       the target's owner
        -- @param   name                        the target's name in the owner
        -- @param   stack                       the stack level
        -- @return  definition                  the new definition
        function InitDefinition(self, target, targettype, definition, owner, name, stack)
            if targettype == AttributeTargets.Method and issubtype(owner, Controller) then
                if self.TimeFormat then
                    local tfmt  = self.TimeFormat
                    return function (self, ...)
                        return processFile(self, Date.Now:ToString(tfmt), definition(self, ...))
                    end
                elseif self.FileName then
                    local name  = self.FileName
                    return function (self, ...)
                        return processFile(self, name, definition(self, ...))
                    end
                else
                    return function (self, ...)
                        return processFile(self, nil, definition(self, ...))
                    end
                end
            elseif targettype == AttributeTargets.Function then
                return FileContextHandler(name, definition, self.TimeFormat, self.FileName)
            end
        end

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- the attribute target
        property "AttributeTarget"  { set = false, default = AttributeTargets.Function + AttributeTargets.Method }
        property "Priority"         { set = false, default = AttributePriority.Lowest }

        -- The time format to generate the file name
        property "TimeFormat"       { type = TimeFormat }

        -- The file name
        property "FileName"         { type = String }

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{ TimeFormat }
        function __ctor(self, format)
            self.TimeFormat     = format
        end

        __Arguments__{ String/nil }
        function __ctor(self, name)
            self.FileName       = name
        end
    end)

    --- The contents handler wrapper for file view
    __Sealed__() __NoRawSet__(false) __NoNilValue__(false)
    class "__FileView__" (function(_ENV)
        extend "IInitAttribute"

        export {
            type                = type,
            HEAD_PHASE          = IHttpContextHandler.ProcessPhase.Head,
            isclass             = Class.Validate,
            issubtype           = Class.IsSubType,
            GetResource         = GetResource,
            loadresource        = IO.Resource.IResourceLoader.LoadResource,
            Error               = Logger.Default[Logger.LogLevel.Error],

            IHttpContextHandler, Controller, IHttpOutput, Text.StringReader, AttributeTargets, __View__, HTTP_STATUS, Web, Date, Guid
        }

        local processFileView   = function(self, default, dfname, path, name, data)
            if self.IsFinished then return end

            if path and name and data then
                -- pass
            elseif path and name then
                if type(name) == "table" then
                    path, name, data = nil, path, name
                end
            elseif path then
                if type(path) == "table" then
                    path, name, data = nil, nil, path
                elseif type(path) == "string" then
                    path, name, data = nil, path, nil
                end
            end

            path                = path and type(path) == "string" and path or default
            name                = name and type(name) == "string" and name or dfname
            data                = data and type(data) == "table"  and data or nil

            if not path then return self:ServerError() end

            return self:FileView(path, name, data)
        end

        local processHandler    = function(self, context, phase)
            local response      = context.Response
            if response.RequestRedirected or response.StatusCode ~= HTTP_STATUS.OK then return end

            if phase == HEAD_PHASE then
                local path, name, data = self[2](context)
                if response.RequestRedirected or response.StatusCode ~= HTTP_STATUS.OK then return end

                if path and name and data then
                    -- pass
                elseif path and name then
                    if type(name) == "table" then
                        path, name, data = nil, path, name
                    end
                elseif path then
                    if type(path) == "table" then
                        path, name, data = nil, nil, path
                    elseif type(path) == "string" then
                        path, name, data = nil, path, nil
                    end
                end

                path                = path and type(path) == "string" and path or self[3]
                name                = name and type(name) == "string" and name or self[5] and Date.Now:ToString(self[5]) or self[6] or Guid.New():gsub("%-", "") .. ".txt"
                data                = data and type(data) == "table"  and data or nil

                if path then
                    if self[4] and path == self[3] then
                        context[__View__]       = { self[4], data }
                        response.ContentType    = "text/plain"
                        response.Header["Content-Disposition"] = "attachment;filename=" .. name
                    else
                        local cls               = path and GetResource(path, context)

                        if cls and issubtype(cls, IHttpOutput) then
                            context[__View__]   = { cls, data }
                            response.ContentType= "text/plain"
                            response.Header["Content-Disposition"] = "attachment;filename=" .. name
                        else
                            Error("%s - the view page file can't be found.", self[3])
                            response.StatusCode = HTTP_STATUS.SERVER_ERROR
                        end
                    end
                else
                    Error("The function %q failed to return a view path", self[1])
                    response.StatusCode = HTTP_STATUS.SERVER_ERROR
                end
            else
                local content   = context[__View__]
                if content then
                    local view  = content[1](content[2])

                    view.Context= context
                    view:OnLoad(context)

                    return view:SafeRender(response.Write, "")
                end
            end
        end

        FileViewContextHandler  = class { IHttpContextHandler,
            Process = processHandler,
            __call  = processHandler,
            __new   = function(_, name, target, path, viewcls, tfmt, fname) return { name, target, path, viewcls, tfmt, fname }, true end,
        }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- modify the target's definition
        -- @param   target                      the target
        -- @param   targettype                  the target type
        -- @param   definition                  the target's definition
        -- @param   owner                       the target's owner
        -- @param   name                        the target's name in the owner
        -- @param   stack                       the stack level
        -- @return  definition                  the new definition
        function InitDefinition(self, target, targettype, definition, owner, name, stack)
            if targettype == AttributeTargets.Method and issubtype(owner, Controller) then
                local tfmt          = self.TimeFormat
                local fname         = self.FileName

                if self.Content then
                    if not self.Path then
                        error("the view path must be specified.", stack + 1)
                    end

                    local viewcls
                    local viewpath  = self.Path
                    local viewcont  = self.Content
                    return function(self, ...)
                        if viewcls ==  nil then
                            viewcls = loadresource(viewpath, StringReader(viewcont), self.Context.Application) or false
                            if not viewcls then
                                Error("The context for path - %q can't be parsed as view", viewpath)
                                return self:ServerError()
                            end
                        end

                        if tfmt then
                            return processFileView(self, viewcls, Date.Now:ToString(tfmt), definition(self, ...))
                        else
                            return processFileView(self, viewcls, fname, definition(self, ...))
                        end
                    end
                else
                    local dpath     = self.Path
                    return function (self, ...)
                        if tfmt then
                            return processFileView(self, dpath, Date.Now:ToString(tfmt), definition(self, ...))
                        else
                            return processFileView(self, dpath, fname, definition(self, ...))
                        end
                    end
                end
            elseif targettype == AttributeTargets.Function then
                local viewcls
                if self.Content then
                    if not self.Path then
                        error("the view path must be specified.", stack + 1)
                    end

                    viewcls = loadresource(self.Path, StringReader(self.Content), owner)
                    if not (viewcls and issubtype(viewcls, IHttpOutput)) then
                        error("the context can't be parsed as view.", stack + 1)
                    end
                end

                return FileViewContextHandler(name, definition, self.Path or false, viewcls or false, self.TimeFormat, self.FileName)
            end
        end

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        -- the attribute target
        property "AttributeTarget"  { set = false, default = AttributeTargets.Function + AttributeTargets.Method }
        property "Priority"         { set = false, default = AttributePriority.Lowest }

        -- The time format to generate the file name
        property "TimeFormat"       { type = TimeFormat }

        -- The file name
        property "FileName"         { type = String }

        -- The view path
        property "Path"             { type = String }

        -- The view content
        property "Content"          { type = String }

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{ String/nil, TimeFormat/nil, String/nil }
        function __ctor(self, path, format, content)
            self.Path           = path
            self.TimeFormat     = format
            self.Content        = content
        end

        __Arguments__{ String/nil, String/nil, String/nil  }
        function __ctor(self, path, name, content)
            self.Path           = path
            self.FileName       = name
            self.Content        = content
        end

        __Arguments__{ TimeFormat }
        function __call(self, str)
            self.TimeFormat     = str
        end

        __Arguments__{ String }
        function __call(self, str)
            self.Content        = str
        end
    end)

    __Sealed__() __NoRawSet__(false) __NoNilValue__(false)
    class "__Switch__" (function(_ENV)
        extend "IInitAttribute"

        export {
            serialize           = Serialization.Serialize,
            type                = type,
            HEAD_PHASE          = IHttpContextHandler.ProcessPhase.Head,
            isclass             = Class.Validate,
            issubtype           = Class.IsSubType,
            GetResource         = GetResource,
            loadresource        = IO.Resource.IResourceLoader.LoadResource,
            Error               = Logger.Default[Logger.LogLevel.Error],
            Json                = Toolset.json,

            SWITCH_CASE_VIEW    = 1,
            SWITCH_CASE_JSON    = 2,
            SWITCH_CASE_TEXT    = 3,

            Serialization.JsonFormatProvider, IHttpContextHandler, Controller, IHttpOutput, Text.StringReader, AttributeTargets, __Switch__, HTTP_STATUS, Web
        }

        local processView       = function(self, default, path, data)
            if self.IsFinished then return end

            local typath        = type(path)
            if typath == "table" then
                path, data      = default, path
            elseif typath ~= "string" then
                path, data      = default
            end

            if data and type(data) ~= "table" then data = nil end

            return self:AutoSwitch(path, data)
        end

        local processHandler    = function(self, context, phase)
            local response      = context.Response
            if response.RequestRedirected or response.StatusCode ~= HTTP_STATUS.OK then return end

            if phase == HEAD_PHASE then
                local path, data= self[2](context)
                if response.RequestRedirected or response.StatusCode ~= HTTP_STATUS.OK then return end

                local typath    = type(path)
                if typath == "table" then
                    path, data  = self[3], path
                elseif typath ~= "string" then
                    path, data  = self[3], nil
                end

                if type(data) ~= "table" then
                    data        = nil
                end

                local request   = context.Request

                if request:IsHtmlAccepted() then
                    if path then
                        if self[4] and path == self[3] then
                            context[__Switch__]     = { SWITCH_CASE_VIEW, self[4], data }
                            response.ContentType    = "text/html"
                        else
                            local cls               = path and GetResource(path, context)

                            if cls and issubtype(cls, IHttpOutput) then
                                context[__Switch__] = { SWITCH_CASE_VIEW, cls, data }
                                response.ContentType= "text/html"
                            else
                                Error("%s - the view page file can't be found.", self[3])
                                response.StatusCode = HTTP_STATUS.SERVER_ERROR
                            end
                        end
                    else
                        Error("The function %q failed to return a view path", self[1])
                        response.StatusCode         = HTTP_STATUS.SERVER_ERROR
                    end
                elseif request:IsJsonAccepted() then
                    if data then
                        response.ContentType        = "application/json"
                        if context.IsInnerRequest then
                            context:SaveJsonData(data)
                        else
                            context[__Switch__]     = { SWITCH_CASE_JSON, data }
                        end
                    else
                        Error("The function %q failed to return a json data", self[1])
                        response.StatusCode         = HTTP_STATUS.SERVER_ERROR
                    end
                elseif request:IsTextAccepted() then
                    if data then
                        response.ContentType        = "text/plain"
                        context[__Switch__]         = { SWITCH_CASE_TEXT, data }
                    else
                        Error("The function %q failed to return a value as text", self[1])
                        response.StatusCode         = HTTP_STATUS.SERVER_ERROR
                    end
                else
                    response.StatusCode             = HTTP_STATUS.NONE_ACCEPTABLE
                end
            else
                local content                       = context[__Switch__]
                if content then
                    if content[1] == SWITCH_CASE_VIEW then
                        local view                  = content[2](content[3])

                        view.Context                = context
                        view:OnLoad(context)

                        return view:SafeRender(response.Write, "")
                    else
                        serialize(JsonFormatProvider(), content[2], response.Write)
                    end
                end
            end
        end

        SwitchContextHandler      = class { IHttpContextHandler,
            Process = processHandler,
            __call  = processHandler,
            __new   = function(_, name, target, path, viewcls) return { name, target, path, viewcls }, true end,
        }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- modify the target's definition
        -- @param   target                      the target
        -- @param   targettype                  the target type
        -- @param   definition                  the target's definition
        -- @param   owner                       the target's owner
        -- @param   name                        the target's name in the owner
        -- @param   stack                       the stack level
        -- @return  definition                  the new definition
        function InitDefinition(self, target, targettype, definition, owner, name, stack)
            if targettype == AttributeTargets.Method and issubtype(owner, Controller) then
                if self.Content then
                    if not self.Path then
                        error("the view path must be specified.", stack + 1)
                    end

                    local viewcls
                    local viewpath  = self.Path
                    local viewcont  = self.Content
                    return function(self, ...)
                        if viewcls ==  nil then
                            viewcls = loadresource(viewpath, StringReader(viewcont), self.Context.Application) or false
                            if not viewcls then
                                Error("The context for path - %q can't be parsed as view", viewpath)
                                return self:ServerError()
                            end
                        end

                        return processView(self, viewcls, definition(self, ...))
                    end
                else
                    local dpath = self.Path
                    if dpath then
                        return function (self, ...)
                            return processView(self, dpath, definition(self, ...))
                        end
                    else
                        return function (self, ...)
                            return processView(self, nil, definition(self, ...))
                        end
                    end
                end
            elseif targettype == AttributeTargets.Function then
                local viewcls
                if self.Content then
                    if not self.Path then
                        error("the view path must be specified.", stack + 1)
                    end

                    viewcls = loadresource(self.Path, StringReader(self.Content), owner)
                    if not (viewcls and issubtype(viewcls, IHttpOutput)) then
                        error("the context can't be parsed as view.", stack + 1)
                    end
                end

                return SwitchContextHandler(name, definition, self.Path or false, viewcls or false)
            end
        end

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- the attribute target
        property "AttributeTarget"  { set = false, default = AttributeTargets.Function + AttributeTargets.Method }
        property "Priority"         { set = false, default = AttributePriority.Lowest }

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{ NEString/nil, NEString/nil }
        function __ctor(self, path, content)
            self.Path       = path
            self.Content    = content
        end

        -----------------------------------------------------------
        --                      meta-method                      --
        -----------------------------------------------------------
        __Arguments__{ NEString }
        function __call(self, content)
            self.Content    = content
        end
    end)

    __Sealed__() __NoRawSet__(false) __NoNilValue__(false)
    class "__Redirect__" (function(_ENV)
        extend "IInitAttribute"

        export {
            unpack              = unpack,
            issubtype           = Class.IsSubType,
            HEAD_PHASE          = IHttpContextHandler.ProcessPhase.Head,
            Error               = Logger.Default[Logger.LogLevel.Error],

            IHttpContextHandler, AttributeTargets, __Text__, HTTP_STATUS, Controller
        }

        local processHandler    = function(self, context, phase)
            local response      = context.Response
            if response.RequestRedirected then return end

            if phase == HEAD_PHASE then
                local path, raw = self[1](context)
                if path then
                    response:Redirect(path, nil, raw)
                elseif self[2] then
                    response:Redirect(self[2], nil, self[3])
                else
                    response.StatusCode = HTTP_STATUS.NOT_FOUND
                end
            end
        end

        RedirectContextHandler  = class { IHttpContextHandler,
            Process = processHandler,
            __call  = processHandler,
            __new   = function(_, target, path, raw) return { target, path, raw }, true end,
        }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- modify the target's definition
        -- @param   target                      the target
        -- @param   targettype                  the target type
        -- @param   definition                  the target's definition
        -- @param   owner                       the target's owner
        -- @param   name                        the target's name in the owner
        -- @param   stack                       the stack level
        -- @return  definition                  the new definition
        function InitDefinition(self, target, targettype, definition, owner, name, stack)
            if targettype == AttributeTargets.Method and issubtype(owner, Controller) then
                if self.Path then
                    local opath, oraw       = self.Path, self.Raw
                    return function(self, ...)
                        local path, raw     = definition(self, ...)
                        if path then
                            return self:Redirect(path, raw)
                        else
                            return self:Redirect(opath, oraw)
                        end
                    end
                else
                    return function (self, ...) return self:Redirect(definition(self, ...)) end
                end
            elseif targettype == AttributeTargets.Function then
                return RedirectContextHandler(definition, self.Path, self.Raw)
            end
        end

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- the attribute target
        property "AttributeTarget"  { set = false, default = AttributeTargets.Function + AttributeTargets.Method }
        property "Priority"         { set = false, default = AttributePriority.Lowest }

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{ NEString/nil, Boolean/nil }
        function __ctor(self, path, raw)
            self.Path       = path
            self.Raw        = raw
        end
    end)
end)