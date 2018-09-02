--===========================================================================--
--                                                                           --
--                          System.Web.HttpSession                           --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2016/03/11                                               --
-- Update Date  :   2018/03/15                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    import "System.Serialization"

    --- the http session
    __Sealed__() __Serializable__() __Final__()
    class "System.Web.HttpSession" (function (_ENV)

        export { rawset = rawset }
        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------

        --- Gets the unique identifier for the session
        property "SessionID"    { type = String, set = false, field = "__SessionID" }

        --- Gets a value indicating whether the session was created with the current request
        property "IsNewSession" { type = Boolean }

        --- Gets a value storage table
        property "Items"        { type = Table, set = false, field = "__Items", default = function(self) return {} end }

        --- Gets and sets the date time, allowed the next request access the session
        __Set__ (PropertySet.Clone)
        property "Timeout"      { type = Date }

        --- Whether the current session is canceled
        property "Canceled"     { type = Boolean }

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        __Arguments__{ String, Table/nil, Date/nil }
        function HttpSession(self, id, item, timeout)
            rawset(self, "__SessionID", id)
            rawset(self, "__Items", item)
            self.Timeout = timeout
        end
    end)
end)
