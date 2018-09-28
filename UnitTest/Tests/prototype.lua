--===========================================================================--
--                                                                           --
--                          UnitTest For Prototype                           --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2018/09/26                                               --
-- Update Date  :   2018/09/26                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

UnitTest "PLoop.PrototypeCase" "1.0.0"

__Test__() function usage()
	local proxy = prototype {
	    __index = function(self, key) return rawget(self, "__" .. key) end,
	    __newindex = function(self, key, value)
	        rawset(self, "__" .. key, value)
	    end,
	}

	obj = prototype.NewObject(proxy)
	obj.Name = "Test"

	Assert.Equal("Test", obj.__Name)
	Assert.Equal("Test", obj.Name)
end