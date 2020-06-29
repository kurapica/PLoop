--===========================================================================--
--                                                                           --
--                      System.Web.Controller                      --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2015/06/10                                               --
-- Update Date  :   2020/06/29                                               --
-- Version      :   1.3.2                                                    --
--===========================================================================--

PLoop(function(_ENV)
    export {
        getmetatable            = getmetatable,
        strlower                = string.lower,
        safeset                 = Toolset.safeset,

        Enum, HttpMethod,

        -- Declare global variables
        saveActionMap           = false,
        getActionMap            = false,
    }

    local _HttpMethodMap        = {}

    function saveActionMap(owner, name, action, method)
        local map               = _HttpMethodMap[owner]
        if not map then
            map                 = {}
            _HttpMethodMap      = safeset(_HttpMethodMap, owner, map)
        end

        action                  = strlower(action)

        -- Record it
        map[action]             = map[action] or {}

        if method == HttpMethod.ALL then
            map[action][0]      = name
        else
            for _, v in Enum.Parse(HttpMethod, method) do
                map[action][v]  = name
            end
        end
    end

    function getActionMap(self, context)
        local map = _HttpMethodMap[getmetatable(self)]

        if map then
            map = self.Action and map[strlower(self.Action)]
            if map then
                return map[context.Request.HttpMethod] or map[0]
            end
        end
    end

    --- the web controller
    __Sealed__()
    __NoNilValue__(false):AsInheritable()
    __NoRawSet__  (false):AsInheritable()
    class "System.Web.Controller" (function (_ENV)
        extend (System.Web.IHttpContextHandler)
        extend (System.Web.IHttpContext)

        export {
            type                = type,
            GetRelativeResource = GetRelativeResource,
            serialize           = Serialization.Serialize,
            tostring            = tostring,
            getmetatable        = getmetatable,
            isclass             = Class.Validate,
            issubtype           = Class.IsSubType,
            ispathrooted        = IO.Path.IsPathRooted,
            getActionMap        = getActionMap,
            parseString         = ParseString,
            HEAD_PHASE          = IHttpContextHandler.ProcessPhase.Head,
            Error               = Logger.Default[Logger.LogLevel.Error],

            yield               = coroutine.yield,
            status              = coroutine.status,
            resume              = coroutine.resume,
            error               = error,

            JsonFormatProvider, IHttpOutput, HTTP_STATUS, IHttpContextHandler.ProcessPhase,
            Controller, ThreadPool, Guid
        }

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- The handler's action
        property "Action"       { type = String }

        --- The handler's process phase
        property "ProcessPhase" { type = ProcessPhase, default = ProcessPhase.Head + ProcessPhase.Body + ProcessPhase.Final }

        --- Whether the controller has finished the output
        property "IsFinished"   { type = Boolean, default = false }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        --- Send the text as response
        -- @format  (text)
        -- @format  (iterator, obj, index)
        -- @param   text            the response text
        -- @param   iterator        the iterator used to return text
        -- @param   obj             the iterator object
        -- @param   index           the iterator index
        function Text(self, text, obj, idx)
            local res           = self.Context.Response
            if self.IsFinished or res.RequestRedirected or res.StatusCode ~= HTTP_STATUS.OK then return end
            self.IsFinished     = true

            local write         = res.Write
            res.ContentType     = "text/plain"

            if type(text) == "function" then
                local m
                idx, m          = text(obj, idx)
                m               = m or idx

                yield() -- finish head sending

                if m then
                    write(parseString(m))

                    for i, m in text, obj, idx do
                        write(parseString(m or i))
                    end
                end
            else
                yield() -- finish head sending

                write(parseString(text))
            end

            yield() -- finish body sending
        end

        --- Render a page with data as response
        -- @param   path            the response page path
        -- @param   ...             the data that passed to the view
        function View(self, path, ...)
            local res           = self.Context.Response
            if self.IsFinished or res.RequestRedirected or res.StatusCode ~= HTTP_STATUS.OK then return end
            self.IsFinished     = true

            local context       = self.Context
            local cls           = type(path) == "string" and GetRelativeResource(self, path, context) or path

            if isclass(cls) and issubtype(cls, IHttpOutput) then
                res.ContentType = "text/html"

                yield()

                local view      = cls(...)

                view.Context    = context
                view:OnLoad(context)

                view:SafeRender(res.Write, "")

                yield()
            else
                Error("%s - the view page file can't be found.", tostring(path))
                res.StatusCode  = HTTP_STATUS.NOT_FOUND
            end
        end

        --- Send the json data as response
        -- @param   json            the response json
        -- @param   type            the object type to be serialized
        function Json(self, object, oType)
            local res           = self.Context.Response
            if self.IsFinished or res.RequestRedirected or res.StatusCode ~= HTTP_STATUS.OK then return end
            self.IsFinished     = true

            local context       = self.Context
            if context.IsInnerRequest then --and context.RawContext.ProcessPhase == HEAD_PHASE then
                context:SaveJsonData(object, oType)
            else
                res.ContentType = "application/json"

                yield()

                if oType then
                    serialize(JsonFormatProvider(), object, oType, res.Write)
                else
                    serialize(JsonFormatProvider(), object, res.Write)
                end

                yield()
            end
        end

        --- Auto choose the response type based on the query accept data type
        -- @param   path            the response page path
        -- @param   data            the data that passed to the view or to be serialized as json
        function AutoSwitch(self, path, data)
            local req           = self.Context.Request
            local res           = self.Context.Response
            if self.IsFinished or res.RequestRedirected or res.StatusCode ~= HTTP_STATUS.OK then return end
            self.IsFinished     = true

            if not data then
                res.StatusCode  = HTTP_STATUS.SERVER_ERROR
                return
            end

            if req:IsHtmlAccepted() then
                local context   = self.Context
                local cls       = type(path) == "string" and GetRelativeResource(self, path, context) or path

                if isclass(cls) and issubtype(cls, IHttpOutput) then
                    local view  = cls(data)

                    res.ContentType = "text/html"

                    view.Context= context
                    view:OnLoad(context)

                    yield()

                    view:SafeRender(res.Write, "")

                    yield()
                else
                    Error("%s - the view page file can't be found.", tostring(path))
                    res.StatusCode = HTTP_STATUS.NOT_FOUND
                end
            elseif req:IsJsonAccepted() then
                res.ContentType     = "application/json"

                yield() -- finish head sending

                serialize(JsonFormatProvider(), data, res.Write)

                yield() -- finish body sending
            elseif req:IsTextAccepted() then
                res.ContentType     = "text/plain"

                yield() -- finish head sending

                serialize(JsonFormatProvider(), data, res.Write)

                yield() -- finish body sending
            else
                res.StatusCode  = HTTP_STATUS.NONE_ACCEPTABLE
            end
        end

        --- Send the data as file
        function File(self, name, text, obj, idx)
            local res           = self.Context.Response
            if self.IsFinished or res.RequestRedirected or res.StatusCode ~= HTTP_STATUS.OK then return end
            self.IsFinished     = true

            local write         = res.Write

            -- A default name
            if type(name) ~= "string" then
                name            = Guid.New():gsub("%-", "") .. ".txt"
            end

            res.ContentType     = "text/plain"
            res.Header["Content-Disposition"] = "attachment;filename=" .. name

            yield()

            if type(text) == "function" then
                for i, m in text, obj, idx do
                    write(parseString(m or i))
                end
            else
                write(parseString(text))
            end

            yield() -- finish body sending
        end

        --- Send the view as file
        -- @param   path            the response page path or view class
        -- @param   name            the name of the file
        -- @param   ...             the data that passed to the view
        function FileView(self, path, name, ...)
            local res           = self.Context.Response
            if self.IsFinished or res.RequestRedirected or res.StatusCode ~= HTTP_STATUS.OK then return end
            self.IsFinished     = true

            local context       = self.Context
            local cls           = type(path) == "string" and GetRelativeResource(self, path, context) or path

            if isclass(cls) and issubtype(cls, IHttpOutput) then
                -- A default name
                if type(name) ~= "string" then
                    name        = Guid.New():gsub("%-", "") .. ".txt"
                end

                res.ContentType = "text/plain"
                res.Header["Content-Disposition"] = "attachment;filename=" .. name

                yield()

                local view      = cls(...)

                view.Context    = context
                view:OnLoad(context)

                view:SafeRender(res.Write, "")

                yield()
            else
                Error("%s - the view page file can't be found.", tostring(path))
                res.StatusCode  = HTTP_STATUS.NOT_FOUND
            end
        end

        --- Redirect to another url
        -- @param   url            the redirected url
        function Redirect(self, path, raw)
            local res           = self.Context.Response
            if self.IsFinished or res.RequestRedirected then return end
            self.IsFinished     = true

            if path ~= "" then
                if not (path:match("^%s*%a+:") or ispathrooted(path)) then
                    Error("Only absolute path supported for Controller's Redirect.")
                    res.StatusCode = HTTP_STATUS.NOT_FOUND
                    return
                end
                res:Redirect(path, nil, raw)
            end
        end

        --- Missing
        function NotFound(self)
            if self.IsFinished then return end
            self.IsFinished     = true
            self.Context.Response.StatusCode = HTTP_STATUS.NOT_FOUND
        end

        --- Forbidden
        function Forbidden(self)
            if self.IsFinished then return end
            self.IsFinished     = true
            self.Context.Response.StatusCode = HTTP_STATUS.FORBIDDEN
        end

        --- Server Error
        function ServerError(self)
            if self.IsFinished then return end
            self.IsFinished     = true
            self.Context.Response.StatusCode = HTTP_STATUS.SERVER_ERROR
        end

        -----------------------------------------------------------------------
        --                          inherit method                           --
        -----------------------------------------------------------------------
        function Process(self, context, phase)
            if phase == HEAD_PHASE then
                local action = getActionMap(self, context)
                if action then
                    self.Context = context
                    local thread = ThreadPool.Current:GetThread(self[action])
                    local ok, err= resume(thread, self, context)
                    if not ok then error(err, 0) end
                    context[Controller] = thread
                else
                    context.Response.StatusCode = HTTP_STATUS.NOT_FOUND
                end
            else -- For Body & Final Phase
                local thread = context[Controller]
                if thread and status(thread) == "suspended" then
                    local ok, err= resume(thread, self, context)
                    if not ok then error(err, 0) end
                end
            end
        end
    end)

    --- the attribute to bind action to the controller
    __Sealed__() class "System.Web.__Action__" (function(_ENV)
        extend "IAttachAttribute"

        export {
            issubtype           = Class.IsSubType,
            saveActionMap       = saveActionMap,
        }
        export { Controller }

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        property "Method" { type = HttpMethod, default = HttpMethod.ALL }
        property "Action" { type = String }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        function AttachAttribute(self, target, targettype, owner, name, stack)
            local method = self.Method
            local action = self.Action or name

            if not issubtype(owner, Controller) then return end

            saveActionMap(owner, name, self.Action or name, self.Method)
        end

        __Arguments__{ String, HttpMethod/HttpMethod.ALL }
        function __Action__(self, action, method)
            self.Action = action
            self.Method = method
        end

        __Arguments__{ HttpMethod/HttpMethod.ALL }
        function __Action__(self, method)
            self.Method = method
        end
    end)
end)