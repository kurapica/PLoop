--===========================================================================--
--                                                                           --
--                             System.Web.Route                              --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2015/10/14                                               --
-- Update Date  :   2018/04/02                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Web"

    --- The route would convert the request url to a relative path of the handler's file
    __Sealed__() __NoRawSet__(false) __NoNilValue__(false)
    class "Route" (function (_ENV)

        export {
            strlower            = string.lower,
            strupper            = string.upper,
            strgsub             = string.gsub,
            strtrim             = function (s) return s and strgsub(s, "^%s*(.-)%s*$", "%1") or "" end,
            Debug               = Logger.Default[Logger.LogLevel.Debug],

            IO.Path,
        }

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        __Arguments__{ String, IHttpContextHandler, HttpMethod/HttpMethod.ALL, Boolean/true }
        function __new(self, url, contextHandler, httpMethod, caseIgnored)
            Debug("[System.Web.Route] Add context handler for %s", url)
            return {
                UrlPattern     = url,
                RouteHandler   = false,
                ContextHandler = contextHandler,
                HandlerClass   = false,
                HttpMethod     = httpMethod,
                CaseIgnored    = caseIgnored,
            }, true
        end

        __Arguments__{ String, Callable, HttpMethod/HttpMethod.ALL, Boolean/true }
        function __new(self, url, routeHandler, httpMethod, caseIgnored)
            Debug("[System.Web.Route] Add route converter for %s", url)
            return {
                UrlPattern     = url,
                RouteHandler   = routeHandler,
                ContextHandler = false,
                HandlerClass   = false,
                HttpMethod     = httpMethod,
                CaseIgnored    = caseIgnored,
            }, true
        end

        __Arguments__{ String, -IHttpContextHandler, HttpMethod/HttpMethod.ALL, Boolean/true }
        function __new(self, url, handlerClass, httpMethod, caseIgnored)
            Debug("[System.Web.Route] Add context handler class for %s", url)
            return {
                UrlPattern     = url,
                RouteHandler   = false,
                ContextHandler = false,
                HandlerClass   = handlerClass,
                HttpMethod     = httpMethod,
                CaseIgnored    = caseIgnored,
            }, true
        end

        function __ctor(self)
            local pattern = self.UrlPattern

            if pattern:match(pattern) == pattern and not pattern:find("%b{}") and not pattern:find("[%*%+%-%?]") then
                self.MatchUrlPattern = pattern
                self.IsStaticPattern = true
                return
            end

            self.IsStaticPattern = false

            local suffix = Path.GetSuffix(pattern)

            if suffix then
                pattern = pattern:sub(1, - #suffix - 1)
                suffix = "%." .. suffix:lower():sub(2, -1):gsub("%a", function(w) return ("[%s%s]"):format(strlower(w), strupper(w)) end)
            end

            -- Replace {Controller?} to string pattern like
            -- /{controller}/{action?}/{id?|%d*} -> ^/(%w+)/?(%w*)/?(%d*)$
            -- Route("/{controller}/{action?}/{id}", [[r,c,a,i=>"/controller/"..c.."Controller.lua", {Action=a or "Index",Id=i}]])
            local optional = false

            pattern = pattern:gsub("(%b{})(.?)", function(set, sep)
                if not optional and set:find("?", 1, true) then optional = true end
                set = set:match("|(.*)}") or optional and "%w*" or "%w+"
                if not set:find("%b()") then set = "(" .. set .. ")" end
                sep = strtrim(sep)
                if strtrim(sep) ~= "" then sep = sep .. "?" end
                return set .. sep
            end)

            if suffix then pattern = pattern..suffix end

            -- Only match the whole path
            if pattern:find("^", 1, true) ~= 1 then pattern = "^" .. pattern end
            if not pattern:find("$", -1, true) then pattern = pattern .. "$" end

            self.MatchUrlPattern = pattern
        end
    end)

    --- the route manager
    __Sealed__() __Final__()
    class "RouteManager" (function(_ENV)
        extend "IHttpContextHandler"

        local _GlobalRouteManager

        export {
            GetResource             = GetResource,
            tinsert                 = table.insert,
            strlower                = string.lower,
            strfind                 = string.find,
            isclass                 = Class.Validate,
            issubtype               = Class.IsSubType,
            validateFlags           = Enum.ValidateFlags,
            HttpMethod_ALL          = HttpMethod.ALL,
            HttpMethod_GET          = HttpMethod.GET,
            type                    = type,
            getmetatable            = getmetatable,
            safeset                 = Toolset.safeset,

            IHttpContextHandler, HttpMethod, RouteManager
        }

        local function getHandler(context, contextHandler, ...)
            local handler

            if type(contextHandler) == "string" then
                contextHandler = GetResource(contextHandler, context)
            end

            if isclass(contextHandler) then
                if issubtype(contextHandler, IHttpContextHandler) then
                    handler = contextHandler(...)
                end
            elseif issubtype(getmetatable(contextHandler), IHttpContextHandler) then
                handler = contextHandler
            end

            return handler
        end

        local function chkMatch(routes, context, httpMethod, start, stop, ...)
            if start then
                local route = routes[httpMethod] or routes[HttpMethod_ALL]
                if route then
                    return route.ContextHandler or route.HandlerClass and route.HandlerClass(...) or getHandler(context, route.RouteHandler(context.Request, ...))
                end
            end
        end

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- Register the route to the route manager
        function RegisterRoute(self, route)
            if route.IsStaticPattern then
                local path = route.CaseIgnored and route.MatchUrlPattern:lower() or route.MatchUrlPattern
                if route.HttpMethod == HttpMethod_ALL then
                    self.StaticRoute    = safeset(self.StaticRoute, path, safeset(self.StaticRoute[path] or {}, HttpMethod_ALL, route))
                else
                    for _, method in HttpMethod(route.HttpMethod) do
                        self.StaticRoute= safeset(self.StaticRoute, path, safeset(self.StaticRoute[path] or {}, method, route))
                    end
                end
            else
                local path = route.MatchUrlPattern
                local new  = not (self.PATTERNROUTE[path] or self.patternroute[path])

                if route.CaseIgnored then
                    if route.HttpMethod == HttpMethod_ALL then
                        self.patternroute    = safeset(self.patternroute, path, safeset(self.patternroute[path] or {}, HttpMethod_ALL, route))
                    else
                        for _, method in HttpMethod(route.HttpMethod) do
                            self.patternroute= safeset(self.patternroute, path, safeset(self.patternroute[path] or {}, method, route))
                        end
                    end
                else
                    if route.HttpMethod == HttpMethod_ALL then
                        self.PATTERNROUTE    = safeset(self.PATTERNROUTE, path, safeset(self.PATTERNROUTE[path] or {}, HttpMethod_ALL, route))
                    else
                        for _, method in HttpMethod(route.HttpMethod) do
                            self.PATTERNROUTE= safeset(self.PATTERNROUTE, path, safeset(self.PATTERNROUTE[path] or {}, method, route))
                        end
                    end
                end

                if new then
                    self.PatternCount   = self.PatternCount + 1
                    self.PatternList    = safeset(self.PatternList, self.PatternCount, path)
                end
            end
        end

        --- Get the context handler from the url
        function GetContextHandlerFromUrl(self, context, url, httpMethod)
            local httpMethod    = httpMethod or HttpMethod_GET
            local lowurl        = strlower(url)

            local sroute        = self.StaticRoute
            local route         = sroute[lowurl] or sroute[url]
            route               = route and (route[httpMethod] or route[HttpMethod_ALL])

            if route then
                local handler   = route.ContextHandler or route.HandlerClass and route.HandlerClass() or getHandler(context, route.RouteHandler(context.Request))
                if handler then return handler end
            end

            local plist         = self.PatternList
            local proute        = self.patternroute
            local PROUTE        = self.PATTERNROUTE
            for i = 1, self.PatternCount do
                local path      = plist[i]
                local handler   = proute[path] and chkMatch(proute[path], context, httpMethod, strfind(lowurl, path)) or
                                  PROUTE[path] and chkMatch(PROUTE[path], context, httpMethod, strfind(url, path))
                if handler then return handler end
            end
        end

        --- Process the http request
        function Process(self, context)
            local request = context.Request
            local handler = self:GetContextHandlerFromUrl(context, request.Url, request.HttpMethod)

            if handler then
                request.Handled         = true
                handler.AsGlobalHandler = false
                handler:RegisterToContext(context)
            end
        end

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- The handler would check whether the request is handled, only for init process phase, if the request is handled and the IsRequestHandler is true, the handler won't be use.
        property "IsRequestHandler" { set = false, default = true }

        --- The handler's process phase
        property "ProcessPhase"     { set = false, default = IHttpContextHandler.ProcessPhase.Init }

        --- Whether the context handler is used as global handler.
        property "AsGlobalHandler"  { set = false, default = true }

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{ Application/nil }
        function __exist(_, app)
            if app then
                return app[RouteManager]
            else
                return _GlobalRouteManager
            end
        end

        function __new(_, app)
            return {
                StaticRoute          = {},
                PatternList          = {},
                PATTERNROUTE         = {},
                patternroute         = {},
                PatternCount         = 0,
            }
        end

        __Arguments__{ Application/nil }
        function __ctor(self, app)
            if app then
                self.Application    = app
                app[RouteManager]   = self
            else
                _GlobalRouteManager = self
            end
        end
    end)

    __Sealed__() class "__Route__" (function(_ENV)
        extend "IAttachAttribute"

        export { safeset = Toolset.safeset, issubtype = Class.IsSubType, getmetatable = getmetatable }
        export { IHttpContextHandler, AttributeTargets, Class, IHttpContextHandler, Route, RouteManager, Application }

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
            if owner and issubtype(getmetatable(owner), Application) then
                owner   = owner._Application
            else
                owner   = nil
            end

            RouteManager(owner):RegisterRoute(Route(self[1], target, self[2], self[3]))
        end

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- the attribute target
        property "AttributeTarget"  { set = false, default = AttributeTargets.Function }

        --- the attribute's priority
        property "Priority"         { set = false, default = AttributePriority.Lowest }

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{ String, HttpMethod/HttpMethod.ALL, Boolean/true }
        function __new(_, ...) return { ... }, true end
    end)
end)