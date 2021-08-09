--===========================================================================--
--                                                                           --
--                          System.Web.HttpContext                           --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2015/05/26                                               --
-- Update Date  :   2020/05/17                                               --
-- Version      :   2.1.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    --- the http context
    __Sealed__()
    __NoNilValue__(false):AsInheritable()
    __NoRawSet__  (false):AsInheritable()
    class "System.Web.HttpContext" (function (_ENV)
        inherit "System.Context"

        import "System.Web"

        export {
            ProcessHttpRequest  = IHttpContextHandler.ProcessHttpRequest,
            getmetatable        = getmetatable,
            issubtype           = Class.IsSubType,
            ispathrooted        = IO.Path.IsPathRooted,
            combinepath         = IO.Path.CombinePath,
            HttpMethod_GET      = HttpMethod.GET,

            Date, HttpSession, HttpContext, HttpRequest, HttpResponse, HttpMethod
        }

        -----------------------------------------------------------
        --                  Inner Http Request                   --
        -----------------------------------------------------------
        --- Inner http request
        __Sealed__()
        class "InnerRequest" { HttpRequest,
            --- Get the raw reqeust
            RawRequest          = HttpRequest,

            Headers             = { set = false, default = function(self) return self.RawRequest.Headers end},
            Accept              = { set = false, default = function(self) return self.RawRequest.Accept end },
            ContentLength       = { set = false, default = function(self) return self.RawRequest.ContentLength end },
            ContentType         = { set = false, default = function(self) return self.RawRequest.ContentType end },
            Cookies             = { set = false, default = function(self) return self.RawRequest.Cookies end },
            IsSecureConnection  = { set = false, default = function(self) return self.RawRequest.IsSecureConnection end },
            RawUrl              = { set = false, default = function(self) return self.RawRequest.RawUrl end },
            QueryString         = { type= Table, default = function(self) return self.RawRequest.QueryString end },
            Form                = { type= Table, default = function(self) return self.RawRequest.Form end },
        }

        --- Inner http response
        __Sealed__()
        class "InnerResponse" { HttpResponse,
            RawResponse         = HttpResponse,

            Cookies             = { set = false, default = function(self) return self.RawResponse.Cookies end },
            Write               = { set = false, default = function(self) return self.RawResponse.Write end },
        }

        --- Inner http context
        __Final__() __Sealed__() __NoNilValue__(false) __NoRawSet__(false)
        class "InnerContext" (function(_ENV)
            inherit "HttpContext"

            export {
                ProcessHttpRequest = IHttpContextHandler.ProcessHttpRequest,
                serialize          = Serialization.Serialize,

                InnerContext, Serialization.JsonFormatProvider
            }

            -----------------------------------------------------------
            --                       property                        --
            -----------------------------------------------------------
            --- Send the response directly
            property "ResponseDirectly" { type = Boolean }

            --- This an inner request
            property "IsInnerRequest"   { set = false, default = true }

            --- Get the raw context
            property "RawContext"       { type = HttpContext }

            --- Proxy session
            property "Session"          { set = false, default = function(self) return self.RawContext.Session end }

            -----------------------------------------------------------
            --                        method                         --
            -----------------------------------------------------------
            --- Save the json data with type for inner request
            function SaveJsonData(self, data, type) self[InnerContext]  = { data, type } end

            function Process(self)
                ProcessHttpRequest(self)

                -- So we don't need to serialize and deserialize the json data
                if self.ResponseDirectly then
                    local res   = self.Response.RawResponse
                    local json  = self[InnerContext]

                    if json then
                        res.StatusCode  = self.Response.StatusCode
                        res.ContentType = "application/json"
                        res:SendHeaders()

                        serialize(JsonFormatProvider(), json, res.Write)
                    elseif self.Response.RequestRedirected then
                        res.StatusCode       = self.Response.StatusCode
                        res.RedirectLocation = self.Response.RedirectLocation
                        res:SendHeaders()
                    else
                        res.StatusCode  = self.Response.StatusCode
                        res:SendHeaders()
                    end
                else
                    local json = self[InnerContext]
                    if json then
                        return self.Response.StatusCode, json[1], json[2]
                    elseif self.Response.RequestRedirected then
                        return self.Response.StatusCode, self.Response.RedirectLocation
                    else
                        return self.Response.StatusCode
                    end
                end
            end
        end)

        -----------------------------------------------------------
        --                   abstract property                   --
        -----------------------------------------------------------
        --- The http request
        __Abstract__()  property "Request"  { type = HttpRequest }

        --- The http response
        __Abstract__()  property "Response" { type = HttpResponse }

        --- The http session type
        __Abstract__()  property "SessionType"  { type = -HttpSession, default = HttpSession }

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- The http session
        property "Session"      { set = false, default = function(self) return self.SessionType(self) end }

        --- The current process phase
        property "ProcessPhase" { type = IHttpContextHandler.ProcessPhase }

        --- The current web application
        property "Application"  { type = Application }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- Process the http request
        Process                 = ProcessHttpRequest

        --- Process an inner request
        -- @format  (url[, method[, params]])
        -- @param   url             the inner request url
        -- @param   params          the request querystring or form table
        -- @param   method          the request method
        -- @param   directly        whether send the result to the client directly
        __Arguments__{ NEString, Table/nil, HttpMethod/nil, Boolean/nil}
        function ProcessInnerRequest(self, url, params, method, directly)
            local rawreq        = self.Request

            local ctx           = InnerContext(self.Application)
            ctx.RawContext      = self
            ctx.ResponseDirectly= directly

            local request       = InnerRequest(ctx)
            request.RawRequest  = rawreq
            request.Root        = rawreq.Root
            request.Url         = url

            if params then
                method          = method or HttpMethod_GET
                if method == HttpMethod_GET then
                    request.QueryString = params
                else
                    request.Form        = params
                end
            else
                method          = method or rawreq.HttpMethod
            end

            request.HttpMethod  = method

            ctx.Request         = request
            ctx.Response        = InnerResponse (ctx)
            ctx.Response.RawResponse = self.Response

            return ctx:Process()
        end

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{ Application }
        function __ctor(self, app)
            self.Application    = app
        end
    end)
end)