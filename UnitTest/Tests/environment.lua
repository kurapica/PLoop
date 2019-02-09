--===========================================================================--
--                                                                           --
--                         UnitTest For Environment                          --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2018/09/26                                               --
-- Update Date  :   2018/09/26                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

_ENV = UnitTest "PLoop.Environment" "1.0.0"

__Test__() function isolate()
    Test            = 233
    PLoop(function(_ENV)
        Test        = 123
    end)

    Assert.Equal(233, Test)
end

__Test__() function globalaccess()
    Assert.Equal(_G.print, print)
    Assert.NotNil(List)
    Assert.Equal(List, System.Collections.List)
    if not Platform.MULTI_OS_THREAD then
        Assert.NotNil(rawget(_M, "List"))
    end
end

__Test__() function exportvalue()
    export "print"
    export { "math", "pairs", List }
    export { ipairs = ipairs }
    export {
        "select",
        abs = math.abs,
        Dictionary,
    }

    Assert.Equal(_G.select, rawget(_ENV, "select"))
end

__Test__() function importns()
    Assert.Nil(StringFormatProvider)

    import "System.Serialization"

    Assert.NotNil(StringFormatProvider)
end