--===========================================================================--
--                                                                           --
--                       System.Web.ISessionIDManager                        --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2016/02/17                                               --
-- Update Date  :   2018/03/15                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    --- Represents the interface of session id manager
    __Sealed__() interface "System.Web.ISessionIDManager" (function (_ENV)
        extend "IHttpContextHandler"

        export { ISessionIDManager }

        -----------------------------------------------------------------------
        --                         inherit property                          --
        -----------------------------------------------------------------------
        property "ProcessPhase"         { set = false, default = IHttpContextHandler.ProcessPhase.Head }
        property "AsGlobalHandler"      { set = false, default = true }

        -----------------------------------------------------------------------
        --                          static property                          --
        -----------------------------------------------------------------------
        -- the unique id manager
        __Static__() property "Default" { type = ISessionIDManager, handler = function(self, new, old) if old then old:Dispose() end end }

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- The minute count before session time out.
        property "TimeOutMinutes"       { type = NaturalNumber, default = 30 }

        -----------------------------------------------------------------------
        --                          inherit method                           --
        -----------------------------------------------------------------------
        function Process(self, context)
            local session = context.Session
            if session then
                if session.Canceled then
                    return self:RemoveSessionID(context)
                else
                    return self:SaveSessionID(context, session)
                end
            end
        end

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        --- Gets the session identifier from the context of the current HTTP request.
        __Abstract__() function GetSessionID(self, context) end

        --- Creates a unique session identifier.
        __Abstract__() function CreateSessionID(self, context) end

        --- Deletes the session identifier in the current HTTP response.
        __Abstract__() function RemoveSessionID(self, context) end

        --- Saves a newly created session identifier to the HTTP response.
        __Abstract__() function SaveSessionID(self, context, session) end

        --- Validate the session id
        __Abstract__() function ValidateSessionID(self, id) end

        -----------------------------------------------------------------------
        --                           initializer                            --
        -----------------------------------------------------------------------
        function __init(self)
            if self.Application then
                self.Application[ISessionIDManager] = self
            else
                ISessionIDManager.Default = self
            end
        end
    end)
end)
