--===========================================================================--
--                                                                           --
--                           System.Web.HttpCookie                           --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2016/03/11                                               --
-- Update Date  :   2019/07/25                                               --
-- Version      :   1.1.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    export {
        tostring                = tostring,
        rawset                  = rawset,
    }

    --- the http cookie
    __Final__() __Sealed__()
    class "System.Web.HttpCookie" (function (_ENV)
        export {
            tinsert             = table.insert,
            tblconcat           = table.concat,
            type                = type,
            pairs               = pairs,
        }

        __Sealed__() enum "SameSiteValue" {
            Strict              = Strict,
            Lax                 = Lax,
        }

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- Gets or sets the domain to associate the cookie with
        property "Domain"   { type = String }

        --- Gets or sets the expiration date and time for the cookie
        __Set__(PropertySet.Clone)
        property "Expires"  { type = Date }

        --- Gets or sets the max age for the cookie
        property "MaxAge"   { type = Number }

        --- Gets a value indicating whether a cookie has subkeys
        property "HasKeys"  { type = Boolean }

        --- Gets or sets a value that specifies whether a cookie is accessible by client-side script
        property "HttpOnly" { type = Boolean }

        --- Gets or sets whether the cookie should be restricted to a first-party or same-site context
        property "SameSite" { type = SameSiteValue }

        --- Gets or sets the name of a cookie
        property "Name"     { type = String }

        --- Gets or sets the virtual path to transmit with the current cookie
        property "Path"     { type = String, default = "/" }

        --- Gets or sets a value indicating whether to transmit the cookie using Secure Sockets Layer (SSL)--that is, over HTTPS only
        property "Secure"   { type = Boolean }

        --- Gets or sets an individual cookie value
        property "Value"    { type = String }

        --- Gets a collection of key/value pairs that are contained within a single cookie object
        property "Values"   { type = Table, default = function(self) self.HasKeys = true return {} end }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        --- Convert the cookie to string
        function ToString(self)
            if self.Value == nil then return "" end

            local cache = {}

            tinsert(cache, self.Name .. "=" .. self.Value)
            if self.HasKeys then
                for k, v in pairs(self.Values) do
                    if type(k) == "string" and type(v) == "string" then
                        tinsert(cache, k .. "=" .. v)
                    end
                end
            end
            if self.Expires  then tinsert(cache, "Expires=" .. self.Expires:ToUTCString("%a, %d-%b-%y %X GMT")) end
            if self.MaxAge   then tinsert(cache, "Max-Age=" .. self.MaxAge)   end
            if self.Domain   then tinsert(cache, "Domain="  .. self.Domain)   end
            if self.Path     then tinsert(cache, "Path="    .. self.Path)     end
            if self.SameSite then tinsert(cache, "SameSite=".. self.SameSite) end
            if self.Secure   then tinsert(cache, "Secure")   end
            if self.HttpOnly then tinsert(cache, "HttpOnly") end

            return tblconcat(cache, ";")
        end

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        __Arguments__{ String }
        function HttpCookie(self, name) self.Name = name end

        __Arguments__{ String, String }
        function HttpCookie(self, name, value) self.Name, self.Value = name, value end

        __Arguments__{ String, String, Number }
        function HttpCookie(self, name, value, maxAge) self.Name, self.Value, self.MaxAge = name, value, maxAge end

        __Arguments__{ String, String, Date }
        function HttpCookie(self, name, value, expires) self.Name, self.Value, self.Expires = name, value, expires end

        -----------------------------------------------------------------------
        --                            meta-method                            --
        -----------------------------------------------------------------------
        __tostring = ToString
    end)

    --- the http cookies
    __Final__() __Sealed__()
    class "System.Web.HttpCookies" {
        -----------------------------------------------------------------------
        --                            meta-method                            --
        -----------------------------------------------------------------------
        __index = function (self, key)
            key = tostring(key)
            if key then
                local cookie = HttpCookie(key)
                rawset(self, key, cookie)
                return cookie
            end
        end
    }
end)