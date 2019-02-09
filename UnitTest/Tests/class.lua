--===========================================================================--
--                                                                           --
--                            UnitTest For Class                             --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2018/09/26                                               --
-- Update Date  :   2019/02/09                                               --
-- Version      :   1.1.0                                                    --
--===========================================================================--

_ENV = UnitTest "PLoop.Class" "1.1.0"

namespace "UnitTest.ClassCase"



__Test__() function usage()
	interface "IA" (function(_ENV)
		__Static__() function ifMethodB(self) end
		__Abstract__() function objMethodA(self) end
		__Final__() function objMethodB(self) end
		function objMethodC(self) end
	end)

	class "A" (function(_ENV)
		function objMethodB(self) end
		function objMethodC(self) end
	end)

	class "C" { IA, A }

	Assert.Nil(C.ifMethodB)
	Assert.Nil(C.objMethodB)

	local obj = C()
	Assert.Equal(IA.objMethodB, obj.objMethodB)
	Assert.Equal(A.objMethodC, obj.objMethodC)
end
