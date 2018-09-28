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

UnitTest "PLoop.Environment" "1.0.0"

__Test__() function usage()
	local method

	PLoop(function(_ENV)
		local func = print

		Assert.Equal(func, print)
		Assert.Nil(rawget(_ENV, "print"))

		method = function()
			local v = print
			if Platform.MULTI_OS_THREAD then
				Assert.Nil(rawget(_ENV, "print"))
			else
				Assert.Equal(func, rawget(_ENV, "print"))
			end
		end
	end)

	method()
end