--===========================================================================--
--                                                                           --
--                            UnitTest For Struct                            --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2018/09/26                                               --
-- Update Date  :   2019/02/09                                               --
-- Version      :   1.1.0                                                    --
--===========================================================================--

_ENV = UnitTest "PLoop.Struct" "1.1.0"

namespace "UnitTest.StructCase"

__Test__() function custom()
    Assert.Find("struct.lua:23: the value must be number, got boolean",
        Assert.Error(
            function()
                local v = Number(true)
            end
        )
    )

    struct "Color"  { __base = Number, __init = function(val) return math.max(0, math.min(val, 1)) end }

    Assert.Find("struct.lua:33: the value must be number, got boolean",
        Assert.Error(
            function()
                local v = Color(true)
            end
        )
    )

    Assert.Equal(1, Color(10))
    Assert.True(Struct.IsSubType(Color, Number))
end

__Test__() function member()
    struct "Pos" (function(_ENV)
        member "x" { type = Number, require = true }
        y = Number
        member "z" { type = Number, default = 0 }
    end)

    local v = Pos(1)

    Assert.Equal(1, v.x)
    Assert.Nil(v.y)
    Assert.Equal(0, v.z)

    Assert.Find("struct.lua:58: Usage: UnitTest.StructCase.Pos(x, y, z) - the x can't be nil",
        Assert.Error(
            function()
                local v = Pos()
            end
        )
    )

    Assert.Find("struct.lua:66: Usage: UnitTest.StructCase.Pos(x, y, z) - the y must be number, got boolean",
        Assert.Error(
            function()
                local v = Pos{ x = 2, y = true }
            end
        )
    )
end

__Test__() function array()
    struct "PosArray" { Pos }

    local v = PosArray{ { x = 1 }, { x = 2, z = 3 } }

    Assert.Equal(0, v[1].z)
    Assert.Equal(1, v[1].x)
    Assert.Nil(v[1].y)
    Assert.Equal(2, v[2].x)
    Assert.Equal(3, v[2].z)

    Assert.Find("struct.lua:86: Usage: UnitTest.StructCase.PosArray(...) - the [2].x can't be nil",
        Assert.Error(
            function()
                local v = PosArray{ { x = 1 }, { y = 3 } }
            end
        )
    )
end

__Test__() function combtype()
    Assert.Find("struct.lua:96: the value must be value of System.Number | System.String",
        Assert.Error(
            function()
                local v = (Number + String)(true)
            end
        )
    )

    Assert.Equal(Color, (-Number)(Color))
end

__Test__() function template()
    __Arguments__{ Number, Number }(1, 4)
    struct "FixString" (function(_ENV, min, max)
        __base = String

        function __valid(val)
            return (#val > max or #val < min) and "the %s length must between [" .. min .. "," .. max .. "]"
        end
    end)

    V1_3 = FixString[{1, 3}]

    Assert.Equal(V1_3, FixString[{1, 3}])
    Assert.Equal(FixString, Struct.GetTemplate(V1_3))
    Assert.Same({ 1, 3 }, { Struct.GetTemplateParameters(V1_3) })

    Assert.Find("struct.lua:123: the value length must between [1,3]",
        Assert.Error(
            function()
                local v = V1_3("Hello")
            end
        )
    )

    Assert.Find("struct.lua:131: the value length must between [1,4]",
        Assert.Error(
            function()
                local v = FixString("Hello")
            end
        )
    )
end

__Test__() function dict()
    struct "IDName" { [Number] = String }

    Assert.Find("struct.lua:143: the [key in value] must be number, got string",
        Assert.Error(
            function()
                local v = IDName{ [100] = "Ann", Ben = 2 }
            end
        )
    )
end