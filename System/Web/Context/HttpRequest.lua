--===========================================================================--
--                                                                           --
--                          System.Web.HttpRequest                           --
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
    --- the http request prototype
    __Sealed__()
    class "System.Web.HttpRequest" (function (_ENV)
        local function defcache() return {} end

        --- Specifies the length, in bytes, of content sent by the client
        __Abstract__() property "ContentLength"         { }

        --- Gets the MIME content type of the incoming request
        __Abstract__() property "ContentType"           { }

        --- Gets a collection of cookies sent by the client
        __Abstract__() property "Cookies"               { default = defcache }

        --- Gets a collection of form variables
        __Abstract__() property "Form"                  { default = defcache }

        --- Gets the HTTP data transfer method (such as GET, POST, or HEAD) used by the client
        __Abstract__() property "HttpMethod"            { }

        --- Gets a value indicating whether the HTTP connection uses secure sockets (that is, HTTPS)
        __Abstract__() property "IsSecureConnection"    { }

        --- Gets the collection of HTTP query string variables
        __Abstract__() property "QueryString"           { default = defcache }

        --- Gets the raw URL of the current request
        __Abstract__() property "RawUrl"                { }

        --- Get the root path of the query document
        __Abstract__() property "Root"                  { }

        --- Gets information about the URL of the current request
        __Abstract__() property "Url"                   { default = function(self) return self.Context.Application:Url2Path(self.RawUrl:match("^[^?#]+")) end }

        --- The http context
        __Final__()    property "Context"               { type = System.Web.HttpContext }

        --- Whether the request is handled
        __Final__()    property "Handled"               { Type = Boolean, default = false }

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{ System.Web.HttpContext }
        function __ctor(self, context)
            self.Context = context
        end
    end)
end)