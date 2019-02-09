--===========================================================================--
--                                                                           --
--                          UnitTest For Attribute                           --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2019/02/08                                               --
-- Update Date  :   2019/02/08                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

_ENV = UnitTest "PLoop.Attribute" "1.0.0"

__Test__() function install()
    local module    = prototype {
        __newindex  = function(self, key, value)
            if type(value) == "function" and Attribute.HaveRegisteredAttributes() then
                Attribute.SaveAttributes(value, AttributeTargets.Function)

                -- Init the definition of the target, the definition is the function itself
                local newdef = Attribute.InitDefinition(value, AttributeTargets.Function, value, self, key)

                if newdef ~= value then
                    Attribute.ToggleTarget(value, newdef)
                    value = newdef
                end

                -- Apply the definition, for function just save it
                rawset(self, key, value)

                -- keep the manager nil, normally it only used by the class, interface and etc
                Attribute.ApplyAttributes(value, AttributeTargets.Function, nil, self, key)

                -- finish the call of the attribute system
                Attribute.AttachAttributes(value, AttributeTargets.Function, self, key)
            end
        end,
    }

    local obj       = prototype.NewObject(module)

    -- We can use the attribute to run the function as an iterator
    __Iterator__()
    function obj:GetIter(n)
        for i = 1, n do coroutine.yield(i) end
    end

    -- All works fine now
    for i in obj:GetIter(10) do Assert.Step(i) end

    Assert.Same(List(10), List(Assert.GetSteps()))
end

__Test__() function initattr()
    local __SafeCall__ = class (function(_ENV)
        extend "IInitAttribute"

        local function checkret(ok, ...)
            if ok then return ... end
        end

        function InitDefinition(self, target, targettype, definition, owner, name, stack)
            return function(...)
                return checkret(pcall(definition, ...))
            end
        end

        property "AttributeTarget" { default = AttributeTargets.Function + AttributeTargets.Method }
    end)

    __SafeCall__()
    function test1()
        return 1, 2, 3
    end

    __SafeCall__()
    function test2(i, j)
        return i/j
    end

    Assert.Nil(test2())
    Assert.Same({ 1, 2, 3 }, { test1() })
end

__Test__() function applyattr()
    local __Name__  = class (function(_ENV)
        extend "IApplyAttribute"

        function ApplyAttribute(self, target, targettype, manager, owner, name, stack)
            if manager then
                Environment.Apply(manager, function(_ENV)
                    property "Name" { type = String }
                end)
            end
        end

        property "AttributeTarget" { default = AttributeTargets.Interface + AttributeTargets.Class }
    end)

    __Name__()
    local A         = class {}

    Assert.Find("attribute.lua:109: the Name must be string, got number",
        Assert.Error(
            function()
                A().Name = 123
            end
        )
    )
end

__Test__() function attachattr()
    local __DataTable__ = class (function(_ENV)
        extend "IAttachAttribute"

        function AttachAttribute(self, target, targettype, owner, name, stack)
            return self.DataTable
        end

        property "AttributeTarget" { default = AttributeTargets.Class }

        property "DataTable" { type = String }
    end)

    __DataTable__{ DataTable = "Persons" }
    local Person    = class {}

    Assert.Equal("Persons", Attribute.GetAttachedData(__DataTable__, Person))
end