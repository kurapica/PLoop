--===========================================================================--
--                                                                           --
--                              System.Context                               --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2020/08/18                                               --
-- Update Date  :   2020/08/27                                               --
-- Version      :   1.0.2                                                    --
--===========================================================================--

PLoop(function(_ENV)
    --- Represents the session to be used in the Context
    __Sealed__() class "System.Context.Session" (function(_ENV)
        --- Gets or sets the session items
        __Indexer__()
        __Abstract__() property "Items"         {
            set = function(self, key, value)
                if self.RawItems[key]  ~= value then
                    self.ItemsChanged   = true
                    self.RawItems[key]  = value
                end
            end,
            get = function(self, key)
                return self.RawItems[key]
            end,
        }

        --- Gets the unique identifier for the session
        __Abstract__() property "SessionID"     { type = Any }

        --- The raw item table to be used for serialization
        __Abstract__() property "RawItems"      { default = function(self) self.IsNewSession = true return {} end }

        --- Gets or sets the date time, allowed the next request access the session
        __Set__ (PropertySet.Clone)
        __Abstract__() property "Timeout"       { type = Date, handler = function(self) self.TimeoutChanged = true end }

        --- Whether the time out is changed
        __Abstract__() property "TimeoutChanged"{ type = Boolean }

        --- Whether the current session is canceled
        __Abstract__() property "Canceled"      { type = Boolean }

        --- Gets a value indicating whether the session was newly created
        __Abstract__() property "IsNewSession"  { type = Boolean }

        --- Whether the session items has changed
        __Abstract__() property "ItemsChanged"  { type = Boolean }

        --- Whether the session is temporary
        __Abstract__() property "IsTemporary"   { type = Boolean }

        --- The context
        __Abstract__() property "Context"       { type = Context }

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        --- Get or generate the session for a http context
        __Arguments__{ System.Context/nil }
        function __ctor(self, context)
            self.Context        = context
        end
    end)
end)