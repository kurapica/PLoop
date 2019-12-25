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
            getcontext          = Context.GetContextFromStack,
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
        export {
            _SafeByte = {
                [strbyte('-')]  = true,
                [strbyte('_')]  = true,
                [strbyte('.')]  = true,
                [strbyte('!')]  = true,
                [strbyte('*')]  = true,
                [strbyte('\'')] = true,
                [strbyte('(')]  = true,
                [strbyte(')')]  = true,
            },

            _Space = strbyte(' '),

            _EncodeMap = {
                [strbyte('<')]  = "&lt;",
                [strbyte('>')]  = "&gt;",
                [strbyte('"')]  = "&quot;",
                [strbyte('\'')] = "&#39;",
                [strbyte('&')]  = "&amp;",
            },

            _EntityMap = {
                ["quot"]        = strchar(0x22),
                ["amp"]         = strchar(0x26),
                ["apos"]        = strchar(0x27),
                ["lt"]          = strchar(0x3c),
                ["gt"]          = strchar(0x3e),
                ["nbsp"]        = strchar(0xa0),
                ["iexcl"]       = strchar(0xa1),
                ["cent"]        = strchar(0xa2),
                ["pound"]       = strchar(0xa3),
                ["curren"]      = strchar(0xa4),
                ["yen"]         = strchar(0xa5),
                ["brvbar"]      = strchar(0xa6),
                ["sect"]        = strchar(0xa7),
                ["uml"]         = strchar(0xa8),
                ["copy"]        = strchar(0xa9),
                ["ordf"]        = strchar(0xaa),
                ["laquo"]       = strchar(0xab),
                ["not"]         = strchar(0xac),
                ["shy"]         = strchar(0xad),
                ["reg"]         = strchar(0xae),
                ["macr"]        = strchar(0xaf),
                ["deg"]         = strchar(0xb0),
                ["plusmn"]      = strchar(0xb1),
                ["sup2"]        = strchar(0xb2),
                ["sup3"]        = strchar(0xb3),
                ["acute"]       = strchar(0xb4),
                ["micro"]       = strchar(0xb5),
                ["para"]        = strchar(0xb6),
                ["middot"]      = strchar(0xb7),
                ["cedil"]       = strchar(0xb8),
                ["sup1"]        = strchar(0xb9),
                ["ordm"]        = strchar(0xba),
                ["raquo"]       = strchar(0xbb),
                ["frac14"]      = strchar(0xbc),
                ["frac12"]      = strchar(0xbd),
                ["frac34"]      = strchar(0xbe),
                ["iquest"]      = strchar(0xbf),
                ["Agrave"]      = strchar(0xc0),
                ["Aacute"]      = strchar(0xc1),
                ["Acirc"]       = strchar(0xc2),
                ["Atilde"]      = strchar(0xc3),
                ["Auml"]        = strchar(0xc4),
                ["Aring"]       = strchar(0xc5),
                ["AElig"]       = strchar(0xc6),
                ["Ccedil"]      = strchar(0xc7),
                ["Egrave"]      = strchar(0xc8),
                ["Eacute"]      = strchar(0xc9),
                ["Ecirc"]       = strchar(0xca),
                ["Euml"]        = strchar(0xcb),
                ["Igrave"]      = strchar(0xcc),
                ["Iacute"]      = strchar(0xcd),
                ["Icirc"]       = strchar(0xce),
                ["Iuml"]        = strchar(0xcf),
                ["ETH"]         = strchar(0xd0),
                ["Ntilde"]      = strchar(0xd1),
                ["Ograve"]      = strchar(0xd2),
                ["Oacute"]      = strchar(0xd3),
                ["Ocirc"]       = strchar(0xd4),
                ["Otilde"]      = strchar(0xd5),
                ["Ouml"]        = strchar(0xd6),
                ["times"]       = strchar(0xd7),
                ["Oslash"]      = strchar(0xd8),
                ["Ugrave"]      = strchar(0xd9),
                ["Uacute"]      = strchar(0xda),
                ["Ucirc"]       = strchar(0xdb),
                ["Uuml"]        = strchar(0xdc),
                ["Yacute"]      = strchar(0xdd),
                ["THORN"]       = strchar(0xde),
                ["szlig"]       = strchar(0xdf),
                ["agrave"]      = strchar(0xe0),
                ["aacute"]      = strchar(0xe1),
                ["acirc"]       = strchar(0xe2),
                ["atilde"]      = strchar(0xe3),
                ["auml"]        = strchar(0xe4),
                ["aring"]       = strchar(0xe5),
                ["aelig"]       = strchar(0xe6),
                ["ccedil"]      = strchar(0xe7),
                ["egrave"]      = strchar(0xe8),
                ["eacute"]      = strchar(0xe9),
                ["ecirc"]       = strchar(0xea),
                ["euml"]        = strchar(0xeb),
                ["igrave"]      = strchar(0xec),
                ["iacute"]      = strchar(0xed),
                ["icirc"]       = strchar(0xee),
                ["iuml"]        = strchar(0xef),
                ["eth"]         = strchar(0xf0),
                ["ntilde"]      = strchar(0xf1),
                ["ograve"]      = strchar(0xf2),
                ["oacute"]      = strchar(0xf3),
                ["ocirc"]       = strchar(0xf4),
                ["otilde"]      = strchar(0xf5),
                ["ouml"]        = strchar(0xf6),
                ["divide"]      = strchar(0xf7),
                ["oslash"]      = strchar(0xf8),
                ["ugrave"]      = strchar(0xf9),
                ["uacute"]      = strchar(0xfa),
                ["ucirc"]       = strchar(0xfb),
                ["uuml"]        = strchar(0xfc),
                ["yacute"]      = strchar(0xfd),
                ["thorn"]       = strchar(0xfe),
                ["yuml"]        = strchar(0xff),
                ["OElig"]       = strchar(0x01, 0x52),
                ["oelig"]       = strchar(0x01, 0x53),
                ["Scaron"]      = strchar(0x01, 0x60),
                ["scaron"]      = strchar(0x01, 0x61),
                ["Yuml"]        = strchar(0x01, 0x78),
                ["fnof"]        = strchar(0x01, 0x92),
                ["circ"]        = strchar(0x02, 0xc6),
                ["tilde"]       = strchar(0x02, 0xdc),
                ["Alpha"]       = strchar(0x03, 0x91),
                ["Beta"]        = strchar(0x03, 0x92),
                ["Gamma"]       = strchar(0x03, 0x93),
                ["Delta"]       = strchar(0x03, 0x94),
                ["Epsilon"]     = strchar(0x03, 0x95),
                ["Zeta"]        = strchar(0x03, 0x96),
                ["Eta"]         = strchar(0x03, 0x97),
                ["Theta"]       = strchar(0x03, 0x98),
                ["Iota"]        = strchar(0x03, 0x99),
                ["Kappa"]       = strchar(0x03, 0x9a),
                ["Lambda"]      = strchar(0x03, 0x9b),
                ["Mu"]          = strchar(0x03, 0x9c),
                ["Nu"]          = strchar(0x03, 0x9d),
                ["Xi"]          = strchar(0x03, 0x9e),
                ["Omicron"]     = strchar(0x03, 0x9f),
                ["Pi"]          = strchar(0x03, 0xa0),
                ["Rho"]         = strchar(0x03, 0xa1),
                ["Sigma"]       = strchar(0x03, 0xa3),
                ["Tau"]         = strchar(0x03, 0xa4),
                ["Upsilon"]     = strchar(0x03, 0xa5),
                ["Phi"]         = strchar(0x03, 0xa6),
                ["Chi"]         = strchar(0x03, 0xa7),
                ["Psi"]         = strchar(0x03, 0xa8),
                ["Omega"]       = strchar(0x03, 0xa9),
                ["alpha"]       = strchar(0x03, 0xb1),
                ["beta"]        = strchar(0x03, 0xb2),
                ["gamma"]       = strchar(0x03, 0xb3),
                ["delta"]       = strchar(0x03, 0xb4),
                ["epsilon"]     = strchar(0x03, 0xb5),
                ["zeta"]        = strchar(0x03, 0xb6),
                ["eta"]         = strchar(0x03, 0xb7),
                ["theta"]       = strchar(0x03, 0xb8),
                ["iota"]        = strchar(0x03, 0xb9),
                ["kappa"]       = strchar(0x03, 0xba),
                ["lambda"]      = strchar(0x03, 0xbb),
                ["mu"]          = strchar(0x03, 0xbc),
                ["nu"]          = strchar(0x03, 0xbd),
                ["xi"]          = strchar(0x03, 0xbe),
                ["omicron"]     = strchar(0x03, 0xbf),
                ["pi"]          = strchar(0x03, 0xc0),
                ["rho"]         = strchar(0x03, 0xc1),
                ["sigmaf"]      = strchar(0x03, 0xc2),
                ["sigma"]       = strchar(0x03, 0xc3),
                ["tau"]         = strchar(0x03, 0xc4),
                ["upsilon"]     = strchar(0x03, 0xc5),
                ["phi"]         = strchar(0x03, 0xc6),
                ["chi"]         = strchar(0x03, 0xc7),
                ["psi"]         = strchar(0x03, 0xc8),
                ["omega"]       = strchar(0x03, 0xc9),
                ["thetasym"]    = strchar(0x03, 0xd1),
                ["upsih"]       = strchar(0x03, 0xd2),
                ["piv"]         = strchar(0x03, 0xd6),
                ["ensp"]        = strchar(0x20, 0x02),
                ["emsp"]        = strchar(0x20, 0x03),
                ["thinsp"]      = strchar(0x20, 0x09),
                ["zwnj"]        = strchar(0x20, 0x0c),
                ["zwj"]         = strchar(0x20, 0x0d),
                ["lrm"]         = strchar(0x20, 0x0e),
                ["rlm"]         = strchar(0x20, 0x0f),
                ["ndash"]       = strchar(0x20, 0x13),
                ["mdash"]       = strchar(0x20, 0x14),
                ["lsquo"]       = strchar(0x20, 0x18),
                ["rsquo"]       = strchar(0x20, 0x19),
                ["sbquo"]       = strchar(0x20, 0x1a),
                ["ldquo"]       = strchar(0x20, 0x1c),
                ["rdquo"]       = strchar(0x20, 0x1d),
                ["bdquo"]       = strchar(0x20, 0x1e),
                ["dagger"]      = strchar(0x20, 0x20),
                ["Dagger"]      = strchar(0x20, 0x21),
                ["bull"]        = strchar(0x20, 0x22),
                ["hellip"]      = strchar(0x20, 0x26),
                ["permil"]      = strchar(0x20, 0x30),
                ["prime"]       = strchar(0x20, 0x32),
                ["Prime"]       = strchar(0x20, 0x33),
                ["lsaquo"]      = strchar(0x20, 0x39),
                ["rsaquo"]      = strchar(0x20, 0x3a),
                ["oline"]       = strchar(0x20, 0x3e),
                ["frasl"]       = strchar(0x20, 0x44),
                ["euro"]        = strchar(0x20, 0xac),
                ["image"]       = strchar(0x21, 0x11),
                ["weierp"]      = strchar(0x21, 0x18),
                ["real"]        = strchar(0x21, 0x1c),
                ["trade"]       = strchar(0x21, 0x22),
                ["alefsym"]     = strchar(0x21, 0x35),
                ["larr"]        = strchar(0x21, 0x90),
                ["uarr"]        = strchar(0x21, 0x91),
                ["rarr"]        = strchar(0x21, 0x92),
                ["darr"]        = strchar(0x21, 0x93),
                ["harr"]        = strchar(0x21, 0x94),
                ["crarr"]       = strchar(0x21, 0xb5),
                ["lArr"]        = strchar(0x21, 0xd0),
                ["uArr"]        = strchar(0x21, 0xd1),
                ["rArr"]        = strchar(0x21, 0xd2),
                ["dArr"]        = strchar(0x21, 0xd3),
                ["hArr"]        = strchar(0x21, 0xd4),
                ["forall"]      = strchar(0x22, 0x00),
                ["part"]        = strchar(0x22, 0x02),
                ["exist"]       = strchar(0x22, 0x03),
                ["empty"]       = strchar(0x22, 0x05),
                ["nabla"]       = strchar(0x22, 0x07),
                ["isin"]        = strchar(0x22, 0x08),
                ["notin"]       = strchar(0x22, 0x09),
                ["ni"]          = strchar(0x22, 0x0b),
                ["prod"]        = strchar(0x22, 0x0f),
                ["sum"]         = strchar(0x22, 0x11),
                ["minus"]       = strchar(0x22, 0x12),
                ["lowast"]      = strchar(0x22, 0x17),
                ["radic"]       = strchar(0x22, 0x1a),
                ["prop"]        = strchar(0x22, 0x1d),
                ["infin"]       = strchar(0x22, 0x1e),
                ["ang"]         = strchar(0x22, 0x20),
                ["and"]         = strchar(0x22, 0x27),
                ["or"]          = strchar(0x22, 0x28),
                ["cap"]         = strchar(0x22, 0x29),
                ["cup"]         = strchar(0x22, 0x2a),
                ["int"]         = strchar(0x22, 0x2b),
                ["there4"]      = strchar(0x22, 0x34),
                ["sim"]         = strchar(0x22, 0x3c),
                ["cong"]        = strchar(0x22, 0x45),
                ["asymp"]       = strchar(0x22, 0x48),
                ["ne"]          = strchar(0x22, 0x60),
                ["equiv"]       = strchar(0x22, 0x61),
                ["le"]          = strchar(0x22, 0x64),
                ["ge"]          = strchar(0x22, 0x65),
                ["sub"]         = strchar(0x22, 0x82),
                ["sup"]         = strchar(0x22, 0x83),
                ["nsub"]        = strchar(0x22, 0x84),
                ["sube"]        = strchar(0x22, 0x86),
                ["supe"]        = strchar(0x22, 0x87),
                ["oplus"]       = strchar(0x22, 0x95),
                ["otimes"]      = strchar(0x22, 0x97),
                ["perp"]        = strchar(0x22, 0xa5),
                ["sdot"]        = strchar(0x22, 0xc5),
                ["lceil"]       = strchar(0x23, 0x08),
                ["rceil"]       = strchar(0x23, 0x09),
                ["lfloor"]      = strchar(0x23, 0x0a),
                ["rfloor"]      = strchar(0x23, 0x0b),
                ["lang"]        = strchar(0x23, 0x29),
                ["rang"]        = strchar(0x23, 0x2a),
                ["loz"]         = strchar(0x25, 0xca),
                ["spades"]      = strchar(0x26, 0x60),
                ["clubs"]       = strchar(0x26, 0x63),
                ["hearts"]      = strchar(0x26, 0x65),
                ["diams"]       = strchar(0x26, 0x66),
            },
        }

        local function encodeChar(c)
            local byte = strbyte(c)
            if byte == _Space then return '+' end
            if not _SafeByte[byte] then return strformat("%%%X", byte) end
        end

        local function decodeVal(v)
            v = tonumber(v, 16)
            if v then return strchar(v) end
        end

        --- Set string value for special data value
        __Arguments__{ Any, String }
        __Static__() function SetValueString(value, str)
            SPECIAL_MAP[value] = str
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
        __Arguments__{ String, System.Text.Encoding/nil }
        __Static__() function HtmlEncode(text, encode)
            local iter, tar, idx= (encode or UTF8Encoding).Decodes(text)
            local byte
            local prev          = idx or 1

            idx, byte           = iter(tar, idx)

            -- Check whether need encode
            while idx do
                if _EncodeMap[byte] then break end
                if byte >= 160 and byte < 256 then break end
                if byte >= 0x10000 then break end
                prev            = idx
                idx, byte       = iter(tar, idx)
            end

            -- There is no need to convert
            if not idx then return text end

            local cache         = {}
            local cnt           = 0
            local start         = 1

            while idx do
                if _EncodeMap[byte] or (byte >= 160 and byte < 256) or byte >= 0x10000 then
                    if prev > start then
                        cnt = cnt + 1
                        cache[cnt]  = strsub(text, start, prev - 1)
                        start       = prev
                    end
                    cnt         = cnt + 1
                    cache[cnt]  = _EncodeMap[byte] or "&#" .. byte .. ";"
                    start       = idx
                end

                prev            = idx
                idx, byte       = iter(tar, idx)
            end

            if prev > start then
                cnt             = cnt + 1
                cache[cnt]      = strsub(text, start, prev - 1)
                start           = prev
            end

            return tblconcat(cache, "", 1, cnt)
        end

        --- Decodes a string that has been encoded to eliminate invalid HTML characters.
        __Arguments__{ String, System.Text.Encoding/nil, Boolean/nil }
        __Static__() function HtmlDecode(text, encode, discard)
            encode              = (encode or UTF8Encoding).Encode
            return (strgsub(text, "&(#?)([xX]?)([^&]+);", function(isNumber, isHex, entity)
                isNumber        = isNumber and #isNumber > 0
                if not isNumber then
                    if isHex then entity = isHex .. entity end
                else
                    isHex = isHex and #isHex > 0
                end

                -- entity
                if not isNumber then
                    local rs    = _EntityMap[entity]

                    if discard then
                        if #rs > 1 or strbyte(rs) >= 0x80 then
                            return ""
                        end
                    end

                    return rs
                else
                    -- code
                    if isHex then
                        entity = tonumber(entity, 16)
                    else
                        entity = tonumber(entity)
                    end

                    if discard and entity >= 0x80 then return "" end

                    return entity and encode(entity)
                end
            end))
        end

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
