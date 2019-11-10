--===========================================================================--
--                                                                           --
--                      System.Web.GuidSessionIDManager                      --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2016/03/15                                               --
-- Update Date  :   2018/04/02                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    --- the default sesion id manager(auto guid generator)
    __Sealed__() class "System.Web.GuidSessionIDManager" (function (_ENV)
        extend "ISessionIDManager"

        export { validate = Struct.ValidateValue, HttpCookie.SameSiteValue }
        export { Guid, Date }

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- The cookie name that to be saved into cookies
        property "CookieName" { Type = String, Default = "_SessionID" }

        -----------------------------------------------------------------------
        --                          inherit method                           --
        -----------------------------------------------------------------------
        function GetSessionID(self, context)
            return context.Request.Cookies[self.CookieName]
        end

        function CreateSessionID(self, context)
            return Guid.New()
        end

        function RemoveSessionID(self, context)
            local cookie        = context.Response.Cookies[self.CookieName]
            if not cookie.Value then cookie.Value = "none" end
            cookie.Expires      = Date.Now:AddMinutes(-1)
        end

        function SaveSessionID(self, context, session)
            local cookie        = context.Response.Cookies[self.CookieName]
            cookie.Value        = session.SessionID
            cookie.HttpOnly     = true
            cookie.SameSite     = SameSiteValue.Lax
            cookie.Expires      = not session.IsTemporary and (session.Timeout or Date.Now:AddMinutes(self.TimeoutMinutes)) or nil
        end

        function ValidateSessionID(self, id)
            return validate(Guid, id) and true or false
        end
    end)
end)