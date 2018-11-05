--===========================================================================--
--                                                                           --
--                          System.Web.HttpContext                           --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2015/05/26                                               --
-- Update Date  :   2018/03/15                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Web"

    --- the http context
    __Sealed__()
    __NoNilValue__(false):AsInheritable()
    __NoRawSet__  (false):AsInheritable()
    class "HttpContext" (function (_ENV)
        inherit "Context"

        export {
            ProcessHttpRequest  = IHttpContextHandler.ProcessHttpRequest,
            getmetatable        = getmetatable,
            issubtype           = Class.IsSubType,
            ispathrooted        = IO.Path.IsPathRooted,
            combinepath         = IO.Path.CombinePath,

            Date, HttpSession, ISessionIDManager, ISessionStorageProvider,
            HttpContext, HttpRequest, HttpResponse, HttpMethod
        }

        -----------------------------------------------------------
        --                  Inner Http Request                   --
        -----------------------------------------------------------
        --- Inner http request
        __Sealed__()
        class "InnerRequest" { HttpRequest,
            --- Get the raw reqeust
            RawRequest          = HttpRequest,

            ContentLength       = { set = false, default = function(self) return self.RawRequest.ContentLength end },
            ContentType         = { set = false, default = function(self) return self.RawRequest.ContentType end },
            Cookies             = { set = false, default = function(self) return self.RawRequest.Cookies end },
            IsSecureConnection  = { set = false, default = function(self) return self.RawRequest.IsSecureConnection end },
            RawUrl              = { set = false, default = function(self) return self.RawRequest.RawUrl end },
        }

        --- Inner http response
        __Sealed__()
        class "InnerResponse" { HttpResponse,
            RawResponse         = HttpResponse,

            Cookies             = { set = false, default = function(self) return self.RawResponse.Cookies end },
            Write               = { set = false, default = function(self) return self.RawResponse.Write end },
        }

        --- Inner http context
        __Sealed__() __NoNilValue__(false) __NoRawSet__(false)
        class "InnerContext" { HttpContext,
            --- This an inner request
            IsInnerRequest      = { set = false, default = true },

            --- Get the raw context
            RawContext          = HttpContext,

            Session             = { set = false, default = function(self) return self.RawContext.Session end },

            --- Save the json data with type for inner request
            SaveJsonData        = function(self, data, type) self[InnerContext]  = { data, type } end,

            Process             = function(self)
                ProcessHttpRequest(self)

                -- So we don't need to serialize and deserialize the json data
                local json = self[InnerContext]
                if json then return json[1], json[2] end
            end,
        }

        -----------------------------------------------------------
        --                   abstract property                   --
        -----------------------------------------------------------
        --- The http request
        __Abstract__()  property "Request"  { type = HttpRequest }

        --- The http response
        __Abstract__()  property "Response" { type = HttpResponse }

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- The http session
        __Final__() property "Session"      { set = false, field = "__Session", default = HttpSession.GetSession }

        --- The raw session if existed
        __Final__() property "RawSession"   { set = false, field = "__Session" }

        --- The current process phase
        __Final__() property "ProcessPhase" { type = IHttpContextHandler.ProcessPhase }

        --- The current web application
        __Final__() property "Application"  { type = Application }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- Process the http request
        Process = ProcessHttpRequest

        --- Process an inner request
        -- @format  (url[, method[, params]])
        -- @param   url             the inner request url
        -- @param   params          the request querystring or form table
        -- @param   method          the request method
        __Arguments__{ NEString, Table/nil, HttpMethod/HttpMethod.GET}
        function ProcessInnerRequest(self, url, params, method)
            local rawreq    = self.Request

            local ctx       = InnerContext(self.Application)
            ctx.RawContext  = self

            local request   = InnerRequest(ctx)
            request.RawRequest  = rawreq
            request.Root        = rawreq.Root
            request.Url         = url
            request.HttpMethod  = method

            if params then
                if method == HttpMethod.GET then
                    request.QueryString = params
                else
                    request.Form        = params
                end
            end

            ctx.Request     = request
            ctx.Response    = InnerResponse (ctx)
            ctx.Response.RawResponse = self.Response

            return ctx:Process()
        end

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{ Application }
        function __ctor(self, app)
            self.Application = app
        end
    end)
end)