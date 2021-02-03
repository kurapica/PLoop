--===========================================================================--
--                                                                           --
--                            PLoop Web FrameWork                            --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2015/04/19                                               --
-- Update Date  :   2019/04/01                                               --
-- Version      :   1.1.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    import "System.Configuration"

    --- The web namespace
    __Final__() __Sealed__() __Abstract__()
    class "System.Web" (function(_ENV)

        Environment.RegisterGlobalNamespace("System.Web")

        import "System.Text"
        import "System.IO"

        export {
            type                = type,
            strbyte             = string.byte,
            strchar             = string.char,
            strsub              = string.sub,
            strgsub             = string.gsub,
            strformat           = string.format,
            tonumber            = tonumber,
            tostring            = tostring,
            tblconcat           = table.concat,
            getmetatable        = getmetatable,
            ispathrooted        = IO.Path.IsPathRooted,
            combinepath         = IO.Path.CombinePath,
            getdirectory        = IO.Path.GetDirectory,
            getcontext          = Context.GetCurrentContext,
            getresourcepath     = IO.Resource.IResourceManager.GetResourcePath,
            loadresource        = IO.Resource.IResourceManager.LoadResource,
            IsObjectType        = Class.IsObjectType,

            System.Text.UTF8Encoding, IO.Resource.IResourceManager, Web
        }

        local SPECIAL_MAP       = { [System.Data.DBNull] = "" }

        -- Need be declared first
        class "HttpContext" {}

        -----------------------------------------------------------------------
        --                               types                               --
        -----------------------------------------------------------------------
        --- The web application
        __Sealed__() _G.Application = class "Application" (function(_ENV)
            inherit "Module"

            export {
                GetParent       = Environment.GetParent,
                GetErrorMessage = Struct.GetErrorMessage,
                rawset          = rawset,
                IsPathRooted    = IO.Path.IsPathRooted,

                Application
            }

            -----------------------------------------------------------------------
            --                          static property                          --
            -----------------------------------------------------------------------
            --- The application config
            __Static__() property "ConfigSection" { set = false, default = Configuration.ConfigSection() }

            -----------------------------------------------------------------------
            --                              method                               --
            -----------------------------------------------------------------------
            function Url2Path(self, url)
                local root = self._Root
                local len  = #root
                if len > 0 and url:sub(1, len) == root then
                    return url:sub(len + 1)
                else
                    return url
                end
            end

            function Path2Url(self, path)
                if IsPathRooted(path) then
                    return self._Root .. path
                else
                    return path
                end
            end

            -----------------------------------------------------------------------
            --                             property                              --
            -----------------------------------------------------------------------
            --- The root of the application
            property "_Application" {
                get             = function(self)
                    local p     = GetParent(self)
                    while p do
                        self, p = p, GetParent(p)
                    end
                    return self
                end
            }

            --- The application config
            property "_Config" {
                type            = Table, throwable = true,
                set             = function(self, config)
                    if config then
                        local ret, msg = Application.ConfigSection:ParseConfig(config, self)
                        if msg then throw(GetErrorMessage(msg, "_Config")) end
                    end
                end,
            }

            --- The application root
            property "_Root" { type = String, default = "", handler = function(self, val) if val then val = val:lower() if val:match("[/\\]$") then self._Root = val:sub(1, -2) end end end }

            --- The application error handler
            property "_ErrorHandler" { type = Function }
        end)

        --- the http methods
        __Flags__() __Sealed__() __Default__"GET"
        enum "HttpMethod" {
            ALL                 = 0,
            "OPTIONS",
            "GET",
            "HEAD",
            "POST",
            "PUT",
            "DELETE",
            "TRACE",
            "CONNECT",
        }

        --- the http status
        __Sealed__() __Default__ "OK"
        enum "HTTP_STATUS" {
            CONTINUE            = 100,  --The request can be continued.
            SWITCH_PROTOCOLS    = 101,  --The server has switched protocols in an upgrade header.
            OK                  = 200,  --The request completed successfully.
            CREATED             = 201,  --The request has been fulfilled and resulted in the creation of a new resource.
            ACCEPTED            = 202,  --The request has been accepted for processing, but the processing has not been completed.
            PARTIAL             = 203,  --The returned meta information in the entity-header is not the definitive set available from the originating server.
            NO_CONTENT          = 204,  --The server has fulfilled the request, but there is no new information to send back.
            RESET_CONTENT       = 205,  --The request has been completed, and the client program should reset the document view that caused the request to be sent to allow the user to easily initiate another input action.
            PARTIAL_CONTENT     = 206,  --The server has fulfilled the partial GET request for the resource.
            WEBDAV_MULTI_STATUS = 207,  --This indicates multiple status codes for a single response. The response body contains Extensible Markup Language (XML) that describes the status codes. For more information, see HTTP Extensions for Distributed Authoring.
            AMBIGUOUS           = 300,  --The requested resource is available at one or more locations.
            MOVED               = 301,  --The requested resource has been assigned to a new permanent Uniform Resource Identifier (URI), and any future references to this resource should be done using one of the returned URIs.
            REDIRECT            = 302,  --The requested resource resides temporarily under a different URI.
            REDIRECT_METHOD     = 303,  --The response to the request can be found under a different URI and should be retrieved using a GET HTTP verb on that resource.
            NOT_MODIFIED        = 304,  --The requested resource has not been modified.
            USE_PROXY           = 305,  --The requested resource must be accessed through the proxy given by the location field.
            REDIRECT_KEEP_VERB  = 307,  --The redirected request keeps the same HTTP verb. HTTP/1.1 behavior.
            BAD_REQUEST         = 400,  --The request could not be processed by the server due to invalid syntax.
            DENIED              = 401,  --The requested resource requires user authentication.
            PAYMENT_REQ         = 402,  --Not implemented in the HTTP protocol.
            FORBIDDEN           = 403,  --The server understood the request, but cannot fulfill it.
            NOT_FOUND           = 404,  --The server has not found anything that matches the requested URI.
            BAD_METHOD          = 405,  --The HTTP verb used is not allowed.
            NONE_ACCEPTABLE     = 406,  --No responses acceptable to the client were found.
            PROXY_AUTH_REQ      = 407,  --Proxy authentication required.
            REQUEST_TIMEOUT     = 408,  --The server timed out waiting for the request.
            CONFLICT            = 409,  --The request could not be completed due to a conflict with the current state of the resource. The user should resubmit with more information.
            GONE                = 410,  --The requested resource is no longer available at the server, and no forwarding address is known.
            LENGTH_REQUIRED     = 411,  --The server cannot accept the request without a defined content length.
            PRECOND_FAILED      = 412,  --The precondition given in one or more of the request header fields evaluated to false when it was tested on the server.
            REQUEST_TOO_LARGE   = 413,  --The server cannot process the request because the request entity is larger than the server is able to process.
            URI_TOO_LONG        = 414,  --The server cannot service the request because the request URI is longer than the server can interpret.
            UNSUPPORTED_MEDIA   = 415,  --The server cannot service the request because the entity of the request is in a format not supported by the requested resource for the requested method.
            RETRY_WITH          = 449,  --The request should be retried after doing the appropriate action.
            SERVER_ERROR        = 500,  --The server encountered an unexpected condition that prevented it from fulfilling the request.
            NOT_SUPPORTED       = 501,  --The server does not support the functionality required to fulfill the request.
            BAD_GATEWAY         = 502,  --The server, while acting as a gateway or proxy, received an invalid response from the upstream server it accessed in attempting to fulfill the request.
            SERVICE_UNAVAIL     = 503,  --The service is temporarily overloaded.
            GATEWAY_TIMEOUT     = 504,  --The request was timed out waiting for a gateway.
            VERSION_NOT_SUP     = 505,  --The server does not support the HTTP protocol version that was used in the request message.
        }

        -----------------------------------------------------------------------
        --                          static property                          --
        -----------------------------------------------------------------------
        --- Whether working under debug mode, if true the files would be reload when modified.
        __Static__() property "DebugMode"       { type = Boolean, handler = function(self, val) IResourceManager.ReloadWhenModified = val end }

        __Static__() property "ConfigSection"   { set = false, default = Configuration.ConfigSection() }

        __Static__() property "Config"          {
            type                = Table, throwable = true,
            set                 = function(self, config)
                if config then
                    local ret, msg  = self.ConfigSection:ParseConfig(config)
                    if msg then throw(GetErrorMessage(msg, "System.Web.Config")) end
                end
            end,
        }

        __Static__() property "ErrorHandler"    { type = Function, default = error }

        -----------------------------------------------------------------------
        --                           static method                           --
        -----------------------------------------------------------------------
        local _SafeByte         = {
            [strbyte('-')]      = true,
            [strbyte('_')]      = true,
            [strbyte('.')]      = true,
            [strbyte('!')]      = true,
            [strbyte('*')]      = true,
            [strbyte('\'')]     = true,
            [strbyte('(')]      = true,
            [strbyte(')')]      = true,
        }

        local _Space            = strbyte(' ')

        local function encodeChar(c)
            local byte          = strbyte(c)
            if byte == _Space then return '+' end
            if not _SafeByte[byte] then return strformat("%%%X", byte) end
        end

        local function decodeVal(v)
            v                   = tonumber(v, 16)
            if v then return strchar(v) end
        end

        --- Set string value for special data value
        __Arguments__{ Any, String }
        __Static__() function SetValueString(value, str)
            SPECIAL_MAP[value]  = str
        end

        --- Encodes a URL string
        __Arguments__{ String }
        __Static__() function UrlEncode(text)
            return (strgsub(text, "[^%w]", encodeChar))
        end

        --- Converts a URL string into a decoded string
        __Arguments__{ String }
        __Static__() function UrlDecode(text)
            return (strgsub(strgsub(text, "%%(%w%w)", decodeVal), "+", " "))
        end

        --- Parse the value to string so special null value can be changed to empty string
        __Static__() function ParseString(val, otype)
            return val == nil and "" or SPECIAL_MAP[val] or type(val) ~= "table" and tostring(val) or Web.Json(val, otype)
        end

        --- Encodes a string to be displayed in a browser
        __Static__() HtmlEncode = System.Text.XmlEntity.Encode

        --- Decodes a string that has been encoded to eliminate invalid HTML characters.
        __Static__() HtmlDecode = System.Text.XmlEntity.Decode

        --- Get the physical path
        __Arguments__{ String, Context/nil }
        __Static__() function GetPhysicalPath(url, context)
            context = context or getcontext()
            if context and ispathrooted(url) then
                return combinepath(context.Request.Root, url)
            end
        end

        --- Get the physical path of the relative
        __Arguments__{ String, String }
        __Static__() function GetRelativePath(root, url)
            return combinepath(getdirectory(root), url)
        end

        --- Get resource from the target path
        __Arguments__{ String, Context/nil }
        __Static__() function GetResource(url, context)
            context = context or getcontext()
            return context and ispathrooted(url) and loadresource(combinepath(context.Request.Root, url), context.Application)
        end

        --- Get the relative resource from the target path
        __Arguments__{ Any, String, Context/nil }
        __Static__() function GetRelativeResource(obj, url, context)
            if not ispathrooted(url) then
                url = combinepath(getdirectory(getresourcepath(getmetatable(obj))), url)
            else
                context = context or getcontext()
                if not context then return end
                url = combinepath(context.Request.Root, url)
            end
            return loadresource(url, context and context.Application)
        end
    end)

    -----------------------------------------------------------------------
    --                          config section                           --
    -----------------------------------------------------------------------
    export { Web, Logger }

    __ConfigSection__(Web.ConfigSection, {
        Debug                   = Boolean,
        LogLevel                = Logger.LogLevel,
        LogHandler              = Callable,
        ErrorHandler            = Function,
    })
    function setWebConfig(config)
        Web.DebugMode           = config.Debug      or false
        Logger.Default.LogLevel = config.LogLevel   or Logger.LogLevel.Info
        if config.LogHandler then Logger.Default:AddHandler(config.LogHandler) end
        if config.ErrorHandler then Web.ErrorHandler = config.ErrorHandler end
    end

    __ConfigSection__(Application.ConfigSection, {
        Root                    = String,
        ErrorHandler            = Function,
    })
    function setAppConfig(config, app)
        app._Root = config.Root
        if config.ErrorHandler then app._ErrorHandler = config.ErrorHandler end
    end
end)
