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

__Test__() function creation()
    local proxy     = prototype {
        __index     = function(self, key) return rawget(self, "__" .. key) end,
        __newindex  = function(self, key, value) rawset(self, "__" .. key, value) end,
        __tostring  = "myproxy"
    }

    local obj       = prototype.NewObject(proxy)
    obj.Name        = "Test"

    Assert.Equal("Test", obj.__Name)
    Assert.Equal("Test", obj.Name)
    Assert.Equal("myproxy", tostring(proxy))

    Assert.True(Prototype.Validate(proxy))
    Assert.False(Prototype.Validate(obj))
    Assert.True(Prototype.ValidateValue(proxy, obj))
end

__Test__() function inheritance()
    local proxy     = prototype {
        __index     = function(self, key) return rawget(self, "__" .. key) end,
        __newindex  = function(self, key, value) rawset(self, "__" .. key, value) end,
    }

    local cproxy    = prototype (proxy, { __call = function(self) return("Hi " .. self.Name) end })

    local obj       = prototype.NewObject(cproxy)
    obj.Name        = "Test"

    Assert.Equal("Test", obj.__Name)
    Assert.Equal("Hi Test", obj())
end

__Test__() function method()
    local person    = prototype {
        __index     = {
            setName = function(self, name) self[0] = name end,
            getName = function(self) return self[0] end,
        }
    }

    local student   = prototype (person, {
        __index     = {
            setScore= function(self, score) self[1] = score end,
            getScore= function(self) return self[1] end,
        }
    })

    local obj       = prototype.NewObject(student)

    obj:setName("Ann")
    obj:setScore(90)

    Assert.Equal(90, obj[1])
    Assert.Equal("Ann", obj[0])

    Assert.Equal("Ann", obj:getName())
end

__Test__() function controllableIndex()
    local indextbl  = { a = 1, b = 2 }

    local person    = prototype ({ __index = indextbl }, true)

    indextbl.c      = 3

    local obj       = prototype.NewObject(person)

    Assert.Equal(3, obj.c)
end