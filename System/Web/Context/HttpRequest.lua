--===========================================================================--
--                                                                           --
--                          System.Web.HttpRequest                           --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2015/05/26                                               --
-- Update Date  :   2020/02/19                                               --
-- Version      :   1.1.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    --- the http request prototype
    __Sealed__()
    class "System.Web.HttpRequest" (function (_ENV)
        local function defcache() return {} end

        --- Get the collection of the http headers
        __Abstract__() property "Headers"               { default = defcache }

        --- Specifies the length, in bytes, of content sent by the client
        __Abstract__() property "ContentLength"         { default = function(self) return self.Headers["content-length"] end }

        --- Gets the MIME content type of the incoming request
        __Abstract__() property "ContentType"           { default = function(self) return self.Headers["content-type"] end }

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

        --- The accept mime type of the query
        __Abstract__() property "Accept"                { default = function(self) return self.Headers["accept"] end }

        --- The http context
        __Final__()    property "Context"               { type = System.Web.HttpContext }

        --- Whether the request is handled
        __Final__()    property "Handled"               { Type = Boolean, default = false }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- Whether the request accept html as result
        function IsHtmlAccepted(self)
            local accept        = self.Accept
            return accept and accept:match("text/html") and true or false
        end

        --- Whether the request accept text as result
        function IsTextAccepted(self)
            local accept        = self.Accept
            return accept and accept:match("text/plain") and true or false
        end

        --- Whether the request accept json as result
        function IsJsonAccepted(self)
            local accept        = self.Accept
            return accept and accept:match("application/json") and true or false
        end

        --- Whether the request accept javascript as result
        function IsScriptAccepted(self)
            local accept        = self.Accept
            return accept and (accept:match("text/[%w-]+script") or accept:match("application/[%w%-]+script")) and true or false
        end

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{ System.Web.HttpContext }
        function __ctor(self, context)
            self.Context = context
        end
    end)
end)