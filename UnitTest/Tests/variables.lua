--===========================================================================--
--                                                                           --
--                          UnitTest For variables                           --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2018/09/26                                               --
-- Update Date  :   2018/09/26                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

UnitTest "PLoop.Variables" "1.0.0"

namespace "UnitTest.VariableCase"

__Test__() function usage()
    --------------- __Arguments__ ---------------
	__Arguments__{ Number }
	function test1() end

	__Arguments__{ Number/100 }
	function test2(code) return code end

	__Arguments__{ String, Number * 0 }
	function test3()
	end

	__Arguments__{ }:Throwable()
	function test4()
		throw("Something error")
	end

	Assert.Find("variables.lua:39: Usage: test1(System.Number) - the 1st argument must be number, got boolean",
		Assert.Error(
			function()
				test1(true)
			end
		)
	)

	Assert.Equal(100, test2())

	Assert.Find("variables.lua:49: Usage: test3(System.String, [... as System.Number]) - the 4th argument must be number, got boolean",
		Assert.Error(
			function()
				test3("hi", 1, 2, true)
			end
		)
	)

	Assert.Find("variables.lua:57: Something error",
		Assert.Error(
			function()
				test4()
			end
		)
	)

	local collect

	local function gather(...)
		collect = { ... }
	end

	class "A" (function(_ENV)
		__Arguments__{ String, Number }
		function SetInfo(self, ...)
			gather("all", ...)
		end

		__Arguments__{ String }
		function SetInfo(self, name)
			gather("name", name)
		end

		__Arguments__{ Number }
		function SetInfo(self, age)
			gather("age", age)
		end
	end)

	local obj = A()
	obj:SetInfo("hi", 123)
	Assert.Same({ "all", "hi", 123 }, collect)
	obj:SetInfo("hi")
	Assert.Same({ "name", "hi" }, collect)
	obj:SetInfo(123)
	Assert.Same({ "age", 123 }, collect)

	collect = {}

	gather = function(msg)
		collect[#collect + 1] = msg
	end

	class "Person" (function(_ENV)
		__Arguments__{ String }
		function __exist(self, name)
			gather("[exist]The name is " .. name)
		end

		__Arguments__{ NaturalNumber }
		function __exist(self, age)
			gather("[exist]The age is " .. age)
		end

		__Arguments__{ String, NaturalNumber }
		function __exist(self, name, age)
			this(self, name)
			this(self, age)
		end

		__Arguments__{ String }
		function __new(self, name)
			gather("[new]The name is " .. name)
		end

		__Arguments__{ NaturalNumber }
		function __new(self, age)
			gather("[new]The age is " .. age)
		end

		__Arguments__{ String, NaturalNumber }
		function __new(self, name, age)
			this(self, name)
			this(self, age)
		end

		__Arguments__{ String }
		function Person(self, name)
			gather("[ctor]The name is " .. name)
		end

		__Arguments__{ NaturalNumber }
		function Person(self, age)
			gather("[ctor]The age is " .. age)
		end

		__Arguments__{ String, NaturalNumber }
		function Person(self, name, age)
			this(self, name)
			this(self, age)
		end

		__Arguments__{ String, Number }
		function __newindex(self) end

		__Arguments__{ Number }
		function __index(self) end
	end)

	obj = Person("Ann", 12)

	Assert.Same({
		"[exist]The name is Ann",
		"[exist]The age is 12",
		"[new]The name is Ann",
		"[new]The age is 12",
		"[ctor]The name is Ann",
		"[ctor]The age is 12",
	}, collect)

	Assert.Find("variables.lua:169: the calling style must be one of the follow",
		Assert.Error(
			function()
				local obj = Person(true)
			end
		)
	)

	Assert.Find("variables.lua:177: Usage: UnitTest.VariableCase.Person:__index(System.Number) - the 1st argument must be number, got string",
		Assert.Error(
			function()
				local v = obj.name
			end
		)
	)

	Assert.Find("variables.lua:185: Usage: UnitTest.VariableCase.Person:__newindex(System.String, System.Number) - the 2nd argument must be number, got string",
		Assert.Error(
			function()
				obj.name = "hi"
			end
		)
	)

    --------------- __Return__ ---------------
    __Return__{ String }
    function test5() end

    __Return__{ Number/20 }
    function test6() end

	Assert.Find("variables.lua:192: The test5 Return: System.String - the 1st return value can't be nil",
		Assert.Error(
			function()
				local v = test5()
			end
		)
	)

	Assert.Equal(20, test6())

    ------- __Arguments__ & __Return__--------
    __Arguments__{ Number * 2 } __Return__{ NaturalNumber }
    function max(m, ...)
    	for i = 1, select("#", ...) do
    		local v = select(i, ...)
    		if m < v then m = v end
    	end
    	return m
    end

    Assert.Equal(10, max(1, 2, 3, 10))

	Assert.Find("variables.lua:222: Usage: max(... [*2] as System.Number) - the 3rd argument must be number, got boolean",
		Assert.Error(
			function()
				local v = max(1, 2, true, 4)
			end
		)
	)

	Assert.Find("variables.lua:209: The max Return: System.NaturalNumber - the 1st return value must be a natural number",
		Assert.Error(
			function()
				local v = max(-100, -90, -10)
			end
		)
	)
end