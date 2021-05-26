--===========================================================================--
--                                                                           --
--                           UnitTest For Context                            --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2021/05/25                                               --
-- Update Date  :   2021/05/25                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

_ENV = UnitTest "PLoop.Context" "1.0.0"

namespace "UnitTest.ContextCase"

import "System.Context"

__Test__() function session()

    local TestContext           = class (function(_ENV)
        inherit "Context"
        local provider          = TableSessionStorageProvider()

        property "Session"      { default = function(self) return Session(self, provider) end }
    end)

    local ctx                   = TestContext()
    local id                    = Guid.New()

    ctx.Session.SessionID       = id
    ctx.Session.Items.User      = 123

    ctx.Session:SaveSessionItems()

    ctx                         = TestContext()

    ctx.Session.SessionID       = id

    Assert.Equal(123, ctx.Session.Items.User)

    ctx = TestContext()
    ctx.Session.SessionID       = Guid.New()
    Assert.Nil(ctx.Session.Items.User)
end