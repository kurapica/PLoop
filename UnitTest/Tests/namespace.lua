--===========================================================================--
--                                                                           --
--                          UnitTest For Namespace                           --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2018/09/26                                               --
-- Update Date  :   2018/09/26                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

UnitTest "PLoop.Namespace" "1.0.0"

__Test__() function usage()
	PLoop(function(_ENV)
		namespace "UnitTest.NamespaceCase"

		class "A" (function(_ENV)
			class "C" {}
		end)

		local B = class {}

		Assert.Equal("UnitTest.NamespaceCase.A", tostring(A))
		Assert.Equal("Anonymous", tostring(B))
		Assert.Equal("UnitTest.NamespaceCase.A.C", tostring(A.C))
	end)

	PLoop(function(_ENV)
		Assert.Nil(A)

		import "UnitTest.NamespaceCase"

		Assert.NotNil(A)
		Assert.Nil(B)
		Assert.NotNil(A.C)
	end)

	PLoop.UnitTest.NamespaceCase(function(_ENV)
		class "D" {}

		Assert.Equal("UnitTest.NamespaceCase.D", tostring(D))
	end)
end