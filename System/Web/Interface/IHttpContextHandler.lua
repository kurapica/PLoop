--===========================================================================--
--                                                                           --
--                      System.Web.IHttpContextHandler                       --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2015/06/08                                               --
-- Update Date  :   2018/03/15                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Web"

    --- Represents the classes that can access Context by property
    __Sealed__()
    interface "IHttpContext" (function(_ENV)
        --- the http context
        __Abstract__() property "Context" { type = HttpContext }
    end)

    --- the http context handler
    __Sealed__() __AnonymousClass__()
    interface "IHttpContextHandler" (function(_ENV)
        --- the http context process phase
        __Flags__() __Sealed__()
        enum "ProcessPhase" { "Init", "Head", "Body", "Final" }

        --- the http context handler's priority
        __Sealed__() __Default__(0)
        enum "HandlerPriority" {
            Highest                 =  2,
            Higher                  =  1,
            Normal                  =  0,
            Lower                   = -1,
            Lowest                  = -2,
        }

        export {
            ipairs                  = ipairs(_G),
            tinsert                 = table.insert,
            tremove                 = table.remove,
            error                   = error,
            pcall                   = pcall,
            validateflags           = Enum.ValidateFlags,
            InitPhase               = ProcessPhase.Init,
            HeadPhase               = ProcessPhase.Head,
            BodyPhase               = ProcessPhase.Body,
            FinlPhase               = ProcessPhase.Final,

            getContext              = Context.GetContextFromStack,

            IHttpContextHandler, HTTP_STATUS,
        }

        local _InitGlobalHandlers   = {}
        local _HeadGlobalHandlers   = {}
        local _BodyGlobalHandlers   = {}
        local _FinlGlobalHandlers   = {}

        local function addHandler(lst, handler)
            local priority = handler.Priority

            for i, v in ipairs, lst, 0 do
                if v == handler then return end

                if priority > v.Priority then
                    tinsert(lst, i, handler)
                    return lst
                end
            end

            tinsert(lst, handler)
            return lst
        end

        local function removeHandler(lst, handler)
            for i, v in ipairs, lst, 0 do
                if v == handler then return tremove(lst, i) end
            end
        end

        local function registerGlobalHandler(handler)
            local phase = handler.ProcessPhase
            if handler.Application then
                local ghandlers = handler.Application[IHttpContextHandler] or {}

                if validateflags(InitPhase, phase) then ghandlers[InitPhase] = addHandler(ghandlers[InitPhase] or {}, handler) end
                if validateflags(HeadPhase, phase) then ghandlers[HeadPhase] = addHandler(ghandlers[HeadPhase] or {}, handler) end
                if validateflags(BodyPhase, phase) then ghandlers[BodyPhase] = addHandler(ghandlers[BodyPhase] or {}, handler) end
                if validateflags(FinlPhase, phase) then ghandlers[FinlPhase] = addHandler(ghandlers[FinlPhase] or {}, handler) end

                handler.Application[IHttpContextHandler] = ghandlers
            else
                if validateflags(InitPhase, phase) then addHandler(_InitGlobalHandlers, handler) end
                if validateflags(HeadPhase, phase) then addHandler(_HeadGlobalHandlers, handler) end
                if validateflags(BodyPhase, phase) then addHandler(_BodyGlobalHandlers, handler) end
                if validateflags(FinlPhase, phase) then addHandler(_FinlGlobalHandlers, handler) end
            end
        end

        local function unregisterGlobalHandler(handler)
            if handler.Application then
                local ghandlers = handler.Application[IHttpContextHandler]
                if ghandlers then
                    if ghandlers[InitPhase] then removeHandler(ghandlers[InitPhase], handler) end
                    if ghandlers[HeadPhase] then removeHandler(ghandlers[HeadPhase], handler) end
                    if ghandlers[BodyPhase] then removeHandler(ghandlers[BodyPhase], handler) end
                    if ghandlers[FinlPhase] then removeHandler(ghandlers[FinlPhase], handler) end
                end
            else
                removeHandler(_InitGlobalHandlers, handler)
                removeHandler(_HeadGlobalHandlers, handler)
                removeHandler(_BodyGlobalHandlers, handler)
                removeHandler(_FinlGlobalHandlers, handler)
            end
        end

        local function processHttpRequest(context)
            local request       = context.Request
            local response      = context.Response
            local apphandler    = context.Application[IHttpContextHandler]

            -- Prepare the temp context handler container
            local handlers      = {}
            context[IHttpContextHandler] = handlers

            response.StatusCode = HTTP_STATUS.OK

            context.ProcessPhase= InitPhase

            -- Init - Global
            for i = 1, #_InitGlobalHandlers do
                local handler   = _InitGlobalHandlers[i]
                if not request.Handled or not handler.IsRequestHandler then
                    handler:Process(context, InitPhase)
                end
            end

            -- Init - Application(router register path handler)
            local initapp       = apphandler and apphandler[InitPhase]
            if initapp then
                for i = 1, #initapp do
                    local handler   = initapp[i]
                    if not request.Handled or not handler.IsRequestHandler then
                        handler:Process(context, InitPhase)
                    end
                end
            end

            context.ProcessPhase= HeadPhase

            -- Head - Temp
            for i = 1, #handlers do
                local handler   = handlers[i]
                if validateflags(HeadPhase, handler.ProcessPhase) then
                    handler:Process(context, HeadPhase)
                end
            end

            if not request.Handled and response.StatusCode == HTTP_STATUS.OK then
                -- 404
                response.StatusCode = HTTP_STATUS.NOT_FOUND
            end

            -- Head - Application
            local headapp       = apphandler and apphandler[HeadPhase]
            if headapp then
                for i = 1, #headapp do
                    headapp[i]:Process(context, HeadPhase)
                end
            end

            -- Head - Global
            for i = 1, #_HeadGlobalHandlers do
                _HeadGlobalHandlers[i]:Process(context, HeadPhase)
            end

            context.ProcessPhase= BodyPhase

            -- Call server's redirect method
            if response.RequestRedirected then
                response:ServerRedirect()
            else
                -- send the headers
                response:SendHeaders()

                -- Body - Temp
                if response.StatusCode == HTTP_STATUS.OK then
                    for i = 1, #handlers do
                        local handler   = handlers[i]
                        if validateflags(BodyPhase, handler.ProcessPhase) then
                            handler:Process(context, BodyPhase)
                        end
                    end
                end

                -- Body - Application
                local bodyapp       = apphandler and apphandler[BodyPhase]
                if bodyapp then
                    for i = 1, #bodyapp do
                        bodyapp[i]:Process(context, BodyPhase)
                    end
                end

                -- Body - Global
                for i = 1, #_BodyGlobalHandlers do
                    _BodyGlobalHandlers[i]:Process(context, BodyPhase)
                end

                -- close the response
                response:Close()
            end

            context.ProcessPhase= FinlPhase

            -- Final - Temp
            for i = 1, #handlers do
                local handler   = handlers[i]
                if validateflags(FinlPhase, handler.ProcessPhase) then
                    handler:Process(context, FinlPhase)
                end
            end

            -- Final - Application
            local finlapp       = apphandler and apphandler[FinlPhase]
            if finlapp then
                for i = 1, #finlapp do
                    finlapp[i]:Process(context, FinlPhase)
                end
            end

            -- Final - Global
            for i = 1, #_FinlGlobalHandlers do
                _FinlGlobalHandlers[i]:Process(context, FinlPhase)
            end
        end

        -----------------------------------------------------------
        --                     static method                     --
        -----------------------------------------------------------
        --- Process the http request for a http context
        __Static__() function ProcessHttpRequest(context)
            local ok, err = pcall(processHttpRequest, context)
            if not ok then
                if context.IsInnerRequest then error(err, 0) end

                local handler = context.Application._ErrorHandler or Web.ErrorHandler
                handler(err, 0, context)
            end
        end

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- Register self to current context process phases
        function RegisterToContext(self, context)
            if self.AsGlobalHandler then return end

            context = context or getContext()
            if context and context[IHttpContextHandler] then
                addHandler(context[IHttpContextHandler], self)
            end
        end

        --- Process the http request
        __Abstract__() function Process(self, context, phase) end

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- The handler would check whether the request is handled, only for init process phase, if the request is handled and the IsRequestHandler is true, the handler won't be use.
        __Abstract__() property "IsRequestHandler" { type = Boolean, default = false }

        --- The handler's process phase
        __Abstract__() property "ProcessPhase"     { type = ProcessPhase, default = ProcessPhase.Head + ProcessPhase.Body }

        --- the handler's priority
        __Abstract__() property "Priority"          { type = HandlerPriority }

        --- Whether the context handler is used as global handler.
        __Abstract__() property "AsGlobalHandler"   { type = Boolean, default = false }

        --- The target web application of the global handler
        __Final__()    property "Application"       { type = Application, handler = function(self, app) if app and app._Application ~= app then self.Application = app._Application end end }

        -----------------------------------------------------------
        --                        dispose                        --
        -----------------------------------------------------------
        function Dispose(self)
            if self.AsGlobalHandler then return unregisterGlobalHandler(self) end
        end

        -----------------------------------------------------------
        --                      initializer                      --
        -----------------------------------------------------------
        function __init(self)
            if self.AsGlobalHandler then return registerGlobalHandler(self) end
        end
    end)
end)
