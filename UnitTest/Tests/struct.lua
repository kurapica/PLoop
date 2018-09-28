--===========================================================================--
--                                                                           --
--                            UnitTest For Struct                            --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2018/09/26                                               --
-- Update Date  :   2018/09/26                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

UnitTest "PLoop.Struct" "1.0.0"

__Test__() function usage()
	namespace "UnitTest.StructCase"

	Assert.Find("struct.lua:23: the value must be number, got boolean",
		Assert.Error(
			function()
				local v = Number(true)
			end
		)
	)

	struct "Pos" (function(_ENV)
		member "x" { type = Number, require = true }
		y = Number
		member "z" { type = Number, default = 0 }
	end)

	local v = Pos(1)

	Assert.Equal(1, v.x)
	Assert.Nil(v.y)
	Assert.Equal(0, v.z)

	Assert.Find("struct.lua:43: Usage: UnitTest.StructCase.Pos(x, y, z) - the x can't be nil",
		Assert.Error(
			function()
				local v = Pos()
			end
		)
	)

	Assert.Find("struct.lua:51: Usage: UnitTest.StructCase.Pos(x, y, z) - the y must be number, got boolean",
		Assert.Error(
			function()
				local v = Pos{ x = 2, y = true }
			end
		)
	)

	struct "PosArray" { Pos }

	local v = PosArray{ { x = 1 }, { x = 2, z = 3 } }

	Assert.Equal(0, v[1].z)
	Assert.Equal(1, v[1].x)
	Assert.Nil(v[1].y)
	Assert.Equal(2, v[2].x)
	Assert.Equal(3, v[2].z)

	Assert.Find("struct.lua:69: Usage: UnitTest.StructCase.PosArray(...) - the [2].x can't be nil",
		Assert.Error(
			function()
				local v = PosArray{ { x = 1 }, { y = 3 } }
			end
		)
	)
end