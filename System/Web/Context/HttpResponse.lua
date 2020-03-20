--===========================================================================--
--                                                                           --
--                          System.Web.HttpResponse                          --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2015/05/26                                               --
-- Update Date  :   2020/03/20                                               --
-- Version      :   1.1.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    --- the http response prototype
    __Sealed__()
    class "System.Web.HttpResponse" (function (_ENV)
        export {
            Context, HttpCookies,
            ispathrooted        = IO.Path.IsPathRooted,
            combinepath         = IO.Path.CombinePath,
            getdirectory        = IO.Path.GetDirectory,
            UrlEncode           = UrlEncode,
        }

        --- The http context
        __Final__() property "Context"              { type = System.Web.HttpContext }

        --- Set the http response header
        __Indexer__ ()
        __Abstract__() property "Header"            { set = function(self, key, value) end }

        --- Gets or sets the HTTP MIME type of the output stream.
        __Abstract__() property "ContentType"       { set = function(self, value) self.Header["Content-Type"] = value end }

        --- Gets or sets the value of the Http Location header.
        __Abstract__() property "RedirectLocation"  { set = function(self, value) self.Header.Location = value end }

        --- Whether the request is been redirected.
        __Abstract__() property "RequestRedirected" { type = Boolean }

        --- Gets or sets the response write function or callable writer.
        __Abstract__() property "Write"             { type = Callable }

        --- Gets or sets the HTTP status code of the output returned to the client.
        __Abstract__() property "StatusCode"        { type = HTTP_STATUS }

        --- Gets a collection of cookies sent to the client.
        __Abstract__() property "Cookies"           { set = false, default = function(self) return HttpCookies() end }

        --- Send the response headers
        __Abstract__() function SendHeaders(self) end

        --- Finish the response, used to close resources such like output wirter
        __Abstract__() function Close(self) end

        --- Redirects the client to a new URL.
        __Arguments__{ String, HTTP_STATUS/HTTP_STATUS.REDIRECT, Boolean/false }
        function Redirect(self, url, code, raw)
            if not url:match("^%s*%a+:") then
                -- Check the url
                if not ispathrooted(url) then
                    url = combinepath(getdirectory(self.Context.Request.Url), url)
                end

                if not raw then
                    url = self.Context.Application:Path2Url(url)
                end
            end

            self.StatusCode         = code
            self.RedirectLocation   = url
            self.RequestRedirected  = true
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
