--===========================================================================--
--                                                                           --
--                       Attribute for ContextHandlers                       --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2018/04/04                                               --
-- Update Date  :   2018/04/04                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Web"

    --- The context handler wrapper for text
    __Sealed__() __NoRawSet__(false) __NoNilValue__(false)
    class "__Text__" (function(_ENV)
        extend "IAttachAttribute"  "IInitAttribute"

        export {
            unpack              = unpack,
            issubtype           = Class.IsSubType,
            HEAD_PHASE          = IHttpContextHandler.ProcessPhase.Head,
            Error               = Logger.Default[Logger.LogLevel.Error],

            IHttpContextHandler, __Route__, AttributeTargets, __Text__, HTTP_STATUS, Controller
        }

        class "TextContextHandler" { IHttpContextHandler,
            Process = function(self, context, phase)
                if phase == HEAD_PHASE then
                    if self[3] then
                        local iter, obj, idx = self[2](context)
                        if iter then
                            context.Response.ContentType = "text/plain"
                            context[__Text__] = { iter, obj, idx }
                        elseif context.Response.StatusCode == HTTP_STATUS.OK then
                            Error("The function %q failed to return an iterator", self[1])
                            context.Response.StatusCode = HTTP_STATUS.SERVER_ERROR
                        end
                    else
                        local content = self[2](context)
                        if content then
                            context.Response.ContentType = "text/plain"
                            context[__Text__] = content
                        elseif context.Response.StatusCode == HTTP_STATUS.OK then
                            Error("The function %q failed to return a text value", self[1])
                            context.Response.StatusCode = HTTP_STATUS.SERVER_ERROR
                        end
                    end
                else
                    local write     = context.Response.Write
                    local content   = context[__Text__]
                    if content then
                        if self[3] then
                            for idx, text in unpack(content) do
                                write(text or idx)
                            end
                        else
                            write(content)
                        end
                    end
                end
            end,
            __new   = function(_, name, target, async)
                return { name, target, async }
            end,
        }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- attach data on the target
        -- @param   target                      the target
        -- @param   targettype                  the target type
        -- @param   owner                       the target's owner
        -- @param   name                        the target's name in the owner
        -- @param   stack                       the stack level
        -- @return  data                        the attribute data to be attached
        function AttachAttribute(self, target, targettype, owner, name, stack)
            if targettype == AttributeTargets.Function then
                __Route__.RegisterContextHandler(target, TextContextHandler(name, target, self.Async or false))
            end
        end

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
                return function (self, ...)
                    return self:Text(definition(self, ...))
                end
            end
        end

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- the attribute target
        property "AttributeTarget"  { set = false, default = AttributeTargets.Function + AttributeTargets.Method }
        property "Priority"         { set = false, default = AttributePriority.Lower }
        property "SubLevel"         { set = false, default = - 100 }

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{ Variable("async", Boolean, true, false) }
        function __ctor(self, async)
            self.Async = async
        end
    end)

    --- The context handler wrapper for json
    __Sealed__() __NoRawSet__(false) __NoNilValue__(false)
    class "__Json__" (function(_ENV)
        extend "IAttachAttribute" "IInitAttribute"

        export {
            serialize           = Serialization.Serialize,
            HEAD_PHASE          = IHttpContextHandler.ProcessPhase.Head,
            issubtype           = Class.IsSubType,
            Error               = Logger.Default[Logger.LogLevel.Error],

            IHttpContextHandler, __Route__, JsonFormatProvider, Controller,
            AttributeTargets, __Json__, HTTP_STATUS,
        }

        class "JsonContextHandler" { IHttpContextHandler,
            Process = function(self, context, phase)
                if phase == HEAD_PHASE then
                    local data, type    = self[2](context)

                    if data then
                        context.Response.ContentType = "application/json"
                        if context.IsInnerRequest and context.RawContext.ProcessPhase == HEAD_PHASE then
                            context:SaveJsonData(data, type)
                        else
                            context[__Json__] = { data, type }
                        end
                    elseif context.Response.StatusCode == HTTP_STATUS.OK then
                        Error("The function %q failed to return a json data", self[1])
                        context.Response.StatusCode = HTTP_STATUS.SERVER_ERROR
                    end
                else
                    local content       = context[__Json__]
                    if content then
                        if content[2] then
                            serialize(JsonFormatProvider(), content[1], content[2], context.Response.Write)
                        else
                            serialize(JsonFormatProvider(), content[1], context.Response.Write)
                        end
                    end
                end
            end,
            __new   = function(_, name, target)
                return { name, target }
            end,
        }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- attach data on the target
        -- @param   target                      the target
        -- @param   targettype                  the target type
        -- @param   owner                       the target's owner
        -- @param   name                        the target's name in the owner
        -- @param   stack                       the stack level
        -- @return  data                        the attribute data to be attached
        function AttachAttribute(self, target, targettype, owner, name, stack)
            if targettype == AttributeTargets.Function then
                __Route__.RegisterContextHandler(target, JsonContextHandler(name, target))
            end
        end

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
                return function (self, ...)
                    return self:Json(definition(self, ...))
                end
            end
        end

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- the attribute target
        property "AttributeTarget"  { set = false, default = AttributeTargets.Function + AttributeTargets.Method }
        property "Priority"         { set = false, default = AttributePriority.Lower }
        property "SubLevel"         { set = false, default = - 100 }
    end)

    __Sealed__() __NoRawSet__(false) __NoNilValue__(false)
    class "__View__" (function(_ENV)
        extend "IAttachAttribute"  "IInitAttribute"

        export {
            type                = type,
            HEAD_PHASE          = IHttpContextHandler.ProcessPhase.Head,
            isclass             = Class.Validate,
            issubtype           = Class.IsSubType,
            GetResource         = GetResource,
            loadresource        = IO.Resource.IResourceLoader.LoadResource,
            Error               = Logger.Default[Logger.LogLevel.Error],

            IHttpContextHandler, __Route__, Controller, IHttpOutput, IO.StringReader,
            AttributeTargets, __View__, HTTP_STATUS, Web
        }

        class "ViewContextHandler" { IHttpContextHandler,
            Process = function(self, context, phase)
                if phase == HEAD_PHASE then
                    local path, data

                    if self[3] then
                        path        = self[3]
                        data        = self[2](context)
                    else
                        path, data  = self[2](context)
                        if type(path) ~= "string" then
                            path    = nil
                        end
                    end

                    if data and path then
                        if self[4] then
                            context[__View__] = { self[4], data }
                            context.Response.ContentType = "text/html"
                        else
                            local cls   = path and GetResource(path, context)

                            if cls and issubtype(cls, IHttpOutput) then
                                context[__View__] = { cls, data }
                                context.Response.ContentType = "text/html"
                            else
                                Error("%s - the view page file can't be found.", self[3])
                                context.Response.StatusCode = HTTP_STATUS.SERVER_ERROR
                            end
                        end
                    elseif context.Response.StatusCode == HTTP_STATUS.OK then
                        if path then
                            Error("The function %q failed to return a view data", self[1])
                        else
                            Error("The function %q failed to return a view path", self[1])
                        end
                        context.Response.StatusCode = HTTP_STATUS.SERVER_ERROR
                    end
                else
                    local content   = context[__View__]
                    if content then
                        local view = content[1](content[2])

                        view.Context = context
                        view:OnLoad(context)

                        return view:SafeRender(context.Response.Write, "")
                    end
                end
            end,
            __new   = function(_, name, target, path, viewcls)
                return { name, target, path, viewcls }
            end,
        }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- attach data on the target
        -- @param   target                      the target
        -- @param   targettype                  the target type
        -- @param   owner                       the target's owner
        -- @param   name                        the target's name in the owner
        -- @param   stack                       the stack level
        -- @return  data                        the attribute data to be attached
        function AttachAttribute(self, target, targettype, owner, name, stack)
            if targettype == AttributeTargets.Function then
                local viewcls
                if self.Content then
                    if not self.Path then
                        error("the view path must be specified.", stack + 1)
                    end

                    viewcls = loadresource(self.Path, StringReader(self.Content))
                    if not (viewcls and issubtype(viewcls, IHttpOutput)) then
                        error("the context can't be parsed as view.", stack + 1)
                    end
                end

                __Route__.RegisterContextHandler(target, ViewContextHandler(name, target, self.Path or false, viewcls or false))
            end
        end

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

                    local viewcls = loadresource(self.Path, StringReader(self.Content))
                    if viewcls and issubtype(viewcls, IHttpOutput) then
                        return function(self, ...)
                            return self:View(viewcls, definition(self, ...))
                        end
                    else
                        error("the context can't be parsed as view.", stack + 1)
                    end
                else
                    local path = self.Path
                    if path then
                        return function (self, ...)
                            return self:View(path, definition(self, ...))
                        end
                    else
                        return function (self, ...)
                            return self:View(definition(self, ...))
                        end
                    end
                end
            end
        end

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- the attribute target
        property "AttributeTarget"  { set = false, default = AttributeTargets.Function + AttributeTargets.Method }
        property "Priority"         { set = false, default = AttributePriority.Lower }
        property "SubLevel"         { set = false, default = - 100 }

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
        extend "IAttachAttribute"  "IInitAttribute"

        export {
            unpack              = unpack,
            issubtype           = Class.IsSubType,
            HEAD_PHASE          = IHttpContextHandler.ProcessPhase.Head,
            Error               = Logger.Default[Logger.LogLevel.Error],

            IHttpContextHandler, __Route__, AttributeTargets, __Text__, HTTP_STATUS, Controller
        }

        class "RedirectContextHandler" { IHttpContextHandler,
            Process = function(self, context, phase)
                if phase == HEAD_PHASE then
                    local path, raw = self[1](context)
                    if path then
                        context.Response:Redirect(path, nil, raw)
                    else
                        context.Response.StatusCode = HTTP_STATUS.NOT_FOUND
                    end
                end
            end,
            __new   = function(_, target)
                return { target }
            end,
        }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- attach data on the target
        -- @param   target                      the target
        -- @param   targettype                  the target type
        -- @param   owner                       the target's owner
        -- @param   name                        the target's name in the owner
        -- @param   stack                       the stack level
        -- @return  data                        the attribute data to be attached
        function AttachAttribute(self, target, targettype, owner, name, stack)
            if targettype == AttributeTargets.Function then
                __Route__.RegisterContextHandler(target, RedirectContextHandler(target))
            end
        end

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
                return function (self, ...)
                    return self:Redirect(definition(self, ...))
                end
            end
        end

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- the attribute target
        property "AttributeTarget"  { set = false, default = AttributeTargets.Function + AttributeTargets.Method }
        property "Priority"         { set = false, default = AttributePriority.Lower }
        property "SubLevel"         { set = false, default = - 100 }
    end)
end)