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

__Test__() function ctor()
    class "User" (function(_ENV)
        local created   = {}

        field { name = "anonymous" }

        function __new(self, tbl)
            if type(tbl) == "table" and tbl.name then
                return tbl, true
            end
        end

        function __ctor(self, name)
            if name then self.name = name end
            created[self.name] = self
        end

        function __exist(_, name)
            return created[name]
        end
    end)

    ann = { name = "Ann" }
    obj = User(ann)
    Assert.Equal(ann, obj)
    Assert.Equal(obj, User("Ann"))
    Assert.Equal("anonymous", User().name)
end

__Test__() function order()
    interface "IName" (function(self)
        __Abstract__() function SetName(self) end

        __Abstract__() function GetName(self) end

        -- initializer
        function __init(self) Assert.Step("IName Init") end

        -- destructor
        function __dtor(self) Assert.Step("IName Dispose") end
    end)

    interface "IAge" (function(self)
        __Abstract__() function SetAge(self) end

        __Abstract__() function GetAge(self) end

        -- initializer
        function __init(self) Assert.Step("IAge Init") end

        -- destructor
        function __dtor(self) Assert.Step("IAge Dispose") end
    end)

    class "Person" (function(_ENV)
        extend "IName" "IAge"

        function __ctor(self) Assert.Step("Person Init") end

        function __dtor(self) Assert.Step("Person Dispose") end
    end)

    class "Student" (function(_ENV)
        inherit "Person"

        function __ctor(self) super(self) Assert.Step("Student Init") end

        function __dtor(self) Assert.Step("Student Dispose") end
    end)

    o = Student()
    o:Dispose()

    Assert.Same(Assert.GetSteps(), {
        "Person Init", "Student Init", "IName Init", "IAge Init",
        "IAge Dispose", "IName Dispose", "Student Dispose", "Person Dispose"
    })
end

__Test__() function metamethod()
    class "Range" (function(_ENV)
        function __new(_, min, max)
            return { min = min, max = max }, true
        end

        function __tostring(self)
            return "[" .. self.min .. "," .. self.max .. "]"
        end

        function __add(self, tar)
            return Range(math.min(self.min, tar.min), math.max(self.max, tar.max))
        end
    end)

    Assert.Equal(tostring(Range(1, 3) + Range(2, 4)), "[1,4]")
end

__Test__() function method()
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

__Test__() function multiver()
    class "MA" (function(_ENV)
        function Test(self)
            Assert.Step("Old")
        end
    end)

    local obj       = MA()

    class "MA" (function(_ENV)
        function Test(self)
            Assert.Step("New")
        end
    end)

    obj:Test()

    Assert.Same({ "Old" }, Assert.GetSteps())
end

__Test__() function appendmethod()
    class "AP" {}

    local obj       = AP()

    function AP:Test()
        Assert.Step("Test AP")
    end

    obj:Test()

    Assert.Same({ "Test AP" }, Assert.GetSteps())
end

__Test__() function inheritance()
    class "HA" (function(_ENV)
        __Final__() function __ctor(self, ...)
            Assert.Step("MA Ctor")
            Class.GetNormalMetaMethod(Class.GetObjectClass(self), "__ctor")(self, ...)
        end

        __Final__() function Test(self, ...)
            Assert.Step("MA Test")
            Class.GetNormalMethod(Class.GetObjectClass(self), "Test")(self, ...)
        end
    end)

    class "HB" (function(_ENV)
        inherit "HA"

        function __ctor(self, ...)
            Assert.Step("MB Ctor")
        end

        function Test(self, ...)
            Assert.Step("MB Test")
        end
    end)

    class "HC" { HB }

    local obj       = HC()

    Assert.Equal(obj.Test, HA.Test)

    obj:Test()

    Assert.Same(Assert.GetSteps(), {
        "MA Ctor", "MB Ctor", "MA Test", "MB Test"
    })
end

__Test__() function event()
    class "EA" (function(_ENV)
        __EventChangeHandler__(function(delegate, owner, name)
            Assert.Step("Change " .. name)
        end)
        event "OnTest"

        __Static__() event "OnObjectCreated"

        function Fire(self, ...) OnTest(self, ...) end

        function __ctor(self)
            OnObjectCreated(self)
        end
    end)

    EA.OnObjectCreated = function(obj) Assert.Step("Created") end

    local obj       = EA()

    Assert.Same(Assert.GetSteps(), { "Created" })
    Assert.ResetSteps()

    function obj:OnTest() Assert.Step("Final") end

    obj.OnTest      = obj.OnTest + function(self) Assert.Step("Stack") end

    obj:Fire()
    Assert.Same(Assert.GetSteps(), { "Change OnTest", "Change OnTest", "Stack", "Final" })
    Assert.ResetSteps()

    local blockhandler = function(self) Assert.Step("Block") return true end

    obj.OnTest      = obj.OnTest + blockhandler

    obj:Fire()
    Assert.Same(Assert.GetSteps(), { "Change OnTest", "Stack", "Block" })
    Assert.ResetSteps()

    obj.OnTest:SetInitFunction(function(self) Assert.Step("Init") return true end)

    obj:Fire()
    Assert.Same(Assert.GetSteps(), { "Change OnTest", "Init" })
    Assert.ResetSteps()

    obj.OnTest:SetInitFunction(nil)
    obj.OnTest      = obj.OnTest - blockhandler

    obj:Fire()
    Assert.Same(Assert.GetSteps(), { "Change OnTest", "Change OnTest", "Stack", "Final" })
end

__Test__() function property()
    class "Char" (function(_ENV)
        enum "Class" { "Warrior", "Mage", "Thief" }

        field { __name = "anonymous" }

        function getAge(self)
            return self.__age or 0
        end

        function setAge(self, age)
            self.__age = age
        end

        function setClass(self, cls)
            self.__cls = cls
        end

        function getClass(self)
            return self.__cls or Char.DefaultClass
        end

        __Static__() property "DefaultClass" { type = Class, default = Class.Warrior }

        property "Name" {
            get = function(self) return self.__name end,
            set = function(self, name) self.__name = name end,
        }

        property "Age" { get = "getAge", set = "setAge" }

        property "Class" { type = Class, auto = true }

        property "Level" { type = NaturalNumber, default = 1, handler = function(self, lvl) Assert.Step("Level " .. lvl) end, event = "OnLevelUp" }

        property "GUID" { type = Guid, default = function(self) return Guid.New() end }

        __Indexer__(NEString) property "Data" {
            get = function(self, key) return self["__" .. key] end,
            set = function(self, key, val) self["__" .. key] = val end,
        }

        __Set__(PropertySet.Clone + PropertySet.Retain)
        __Get__(PropertySet.Clone)
        property "Cache" { type = Table }
    end)

    class "NPC" (function(_ENV)
        inherit "Char"

        property "Level" { get = function(self) return super[self].Level end, set = function(self, lvl) Assert.Step("NPC Level " .. lvl) super[self].Level = lvl end }
    end)

    local obj = NPC()

    Assert.Equal(0, obj.Age)
    Assert.Equal(Char.Class.Warrior, obj.Class)
    Char.DefaultClass = Char.Class.Thief
    Assert.Equal(Char.Class.Thief, obj.Class)

    obj.Name = "Ann"
    Assert.Equal("Ann", obj.__name)
    Assert.Equal("Ann", obj.Data.name)
    Assert.Equal(36, #obj.GUID)

    obj.OnLevelUp = function(self, lvl) Assert.Step("Levelup " .. lvl) end
    obj.Level= 10

    Assert.Same(Assert.GetSteps(), { "NPC Level 10", "Level 10", "Levelup 10" })

    local cache = { 100 }
    obj.Cache = cache
    cache[1] = 200
    Assert.Equal(100, obj.Cache[1])

    Assert.Find("class.lua:341: the Data's key must be string, got number",
        Assert.Error(
            function()
                obj.Data[1] = 100
            end
        )
    )
end

__Test__() function template()
    __Arguments__ { AnyType }
    class "Array" (function(_ENV, eletype)
        __Arguments__{ eletype * 0 }
        function __new(cls, ...)
            return { ... }, true
        end
    end)

    class "NumberArray" { Array[Number] }

    __Arguments__ { AnyType } (AnyType)
    class "Queue" (function(_ENV, eletype)
        inherit (Array[eletype])
    end)

    Assert.Find("class.lua:366: Usage: Anonymous([... as System.Number]) - the 4th argument must be number, got string",
        Assert.Error(
            function()
                local o = NumberArray(1, 2, 3, "hi", 5)
            end
        )
    )

    Assert.Find("class.lua:374: the 3rd must be string, got number",
        Assert.Error(
            function()
                local o = Queue[String]("hi", "1", 2)
            end
        )
    )
end