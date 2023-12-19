--===========================================================================--
--                                                                           --
--                              System.UnitTest                              --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2018/09/23                                               --
-- Update Date  :   2019/02/08                                               --
-- Version      :   1.0.1                                                    --
--===========================================================================--

PLoop(function(_ENV)
    --- the unit test framework
    __Final__() __Sealed__()
    class "System.UnitTest"             (function(_ENV)
        inherit "Module"

        -- Use UnitTest as global
        Environment.RegisterGlobalNamespace(UnitTest)

        export                          {
            pcall                       = pcall,
            ipairs                      = ipairs,
            type                        = type,
            isObjectType                = Class.IsObjectType,
            Info                        = Logger.Default[Logger.LogLevel.Info],
            Warn                        = Logger.Default[Logger.LogLevel.Warn],
            Error                       = Logger.Default[Logger.LogLevel.Error],

            List, UnitTest,
        }

        --- the test state
        __Sealed__()
        enum "TestState"                {
            Succeed                     = 1,
            Failed                      = 2,
            Error                       = 3,
        }

        --- the test case
        __Sealed__() struct "TestCase"  {
            { name = "owner",   type    = UnitTest, require = true },
            { name = "name",    type    = String,   require = true },
            { name = "func",    type    = Function, require = true },
            { name = "desc",    type    = String },
            { name = "state",   type    = TestState,default = Succeed },
            { name = "message", type    = String },
        }

        __Sealed__()
        class "TestFailureException"    (function(_ENV)
            inherit "Exception"

            function __ctor(self, ...)
                super(self, ...)
                self.StackLevel         = 2
            end
        end)

        --- A set of assert methods
        __Final__() __Sealed__()
        interface "Assert"              (function(_ENV)
            export                      {
                type                    = type,
                getmetatable            = getmetatable,
                strformat               = string.format,
                tostring                = tostring,
                error                   = error,
                pairs                   = pairs,
                pcall                   = pcall,
                clone                   = Toolset.clone,
                wipe                    = Toolset.wipe,
                tinsert                 = table.insert,

                TestState, TestFailureException
            }

            local function checkSame(expected, actual, include)
                if expected == actual then return true end

                if type(expected) == "table" and type(actual) == "table" and getmetatable(expected) == getmetatable(actual) then
                    for k, v in pairs(expected) do
                        if not checkSame(v, actual[k]) then return false end
                    end

                    if not include then
                        for k in pairs(actual) do
                            if expected[k] == nil then return false end
                        end
                    end

                    return true
                end
                return false
            end

            local STEPS                 = {}

            -----------------------------------------------------------
            --                        method                         --
            -----------------------------------------------------------
            --- Checks whether the two values are equal(only primitive)
            __Static__()
            function Equal(expected, actual)
                if expected ~= actual then throw(TestFailureException("Expected " .. tostring(expected) .. ", got " .. tostring(actual))) end
            end

            --- Checks that the condition is false
            __Static__()
            function False(condition)
                if condition then throw(TestFailureException("Expected false condition")) end
            end

            --- Checks that the value isn't nil
            __Static__()
            function NotNil(val)
                if val == nil then throw(TestFailureException("Expected not nil value")) end
            end

            --- Checks that the value is nil
            __Static__()
            function Nil(val)
                if val ~= nil then throw(TestFailureException("Expected nil value")) end
            end

            --- Checks that the condition is true
            __Static__()
            function True(condition)
                if not condition then throw(TestFailureException("Expected true condition")) end
            end

            --- Checks that the two values are the same
            __Static__()
            function Same(expected, actual)
                if not checkSame(expected, actual) then throw(TestFailureException("Expected the same value")) end
            end

            --- Checks that the actual contains all elements of the expected
            __Static__()
            function Include(expected, actual)
                if not checkSame(expected, actual, true) then throw(TestFailureException("Should contain the expected elements")) end
            end

            --- Checks that the function should raise an error, the error message will be returned
            __Static__()
            function Error(func, ...)
                local ok, msg           = pcall(func, ...)
                if not ok then return msg end
                throw(TestFailureException("Should raise an error"))
            end

            --- Checks that the message should match the pattern
            __Static__()
            function Match(pattern, msg)
                if not tostring(msg):match(pattern) then
                    throw(TestFailureException("Should match " .. strformat("%q", pattern) .. ", got " .. strformat("%q", tostring(msg or "nil"))))
                end
            end

            --- Checks that the message should contains the pattern as plain text
            __Static__()
            function Find(pattern, msg)
                if not tostring(msg):find(pattern, 1, true) then
                    throw(TestFailureException("Should find " .. strformat("%q", pattern) .. ", got " .. strformat("%q", tostring(msg or "nil"))))
                end
            end

            --- Fail the test with message
            __Static__()
            function Fail(message)
                throw(TestFailureException(message or "Fail"))
            end

            --- Record the debug step
            __Static__()
            function Step(val)
                if val == nil then val  = #STEPS + 1 end
                tinsert(STEPS, val)
            end

            --- Gets the debug steps
            __Static__()
            function GetSteps()
                return clone(STEPS)
            end

            --- Reset the steps
            __Static__()
            function ResetSteps()
                wipe(STEPS)
            end
        end)

        --- Used to mark a method as test case
        __Final__() __Sealed__()
        class "__Test__"                (function(_ENV)
            extend "IAttachAttribute"

            export                      {
                rawget                  = rawget,
                isObjectType            = Class.IsObjectType,

                UnitTest,
            }

            function AttachAttribute(self, target, targettype, owner, name, stack)
                if isObjectType(owner, UnitTest) then
                    owner.TestCases:Insert {
                        owner= owner,
                        name = name,
                        func = target,
                        desc = rawget(self, 1),
                    }
                else
                    error("__Test__ can only be applyed to objects of System.UnitTest", stack + 1)
                end
            end

            ----------------------------------------------
            --                 Property                 --
            ----------------------------------------------
            property "AttributeTarget"  { default = AttributeTargets.Function }

            ----------------------------------------------
            --               constructor                --
            ----------------------------------------------
            __Arguments__{ NEString/nil }
            function __new(_, msg) return { msg }, true end
        end)

        -----------------------------------------------------------
        --                         event                         --
        -----------------------------------------------------------
        --- Fired before the processed of all test cases
        event "OnInit"

        --- Fired when all test cases processed
        event "OnFinal"

        --- Fired before a test case started
        event "BeforeCase"

        --- Fired when a test case processed
        event "AfterCase"

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- Process the current unit test module and its sub-modules
        function Run(self, onlyself)

            OnInit(self)

            for _, tcase in self.TestCases:GetIterator() do
                tcase.state             = TestState.Succeed
                tcase.message           = nil

                BeforeCase(self, tcase)

                local ok, msg           = pcall(tcase.func)

                if not ok and tcase.state == TestState.Succeed then
                    if isObjectType(msg, TestFailureException) then
                        local message   = msg.Message .. (msg.Source and ("@" .. msg.Source) or "")
                        Warn("[UnitTest]%s.%s Failed - %s", tcase.owner._FullName, tcase.name, message)

                        tcase.state     = TestState.Failed
                        tcase.message   = message

                    elseif type(msg) == "string" or isObjectType(msg, Exception) then
                        Warn("[UnitTest]%s.%s Error%s%s", tcase.owner._FullName, tcase.name, msg and " - " or "", tostring(msg) or "")

                        tcase.state     = TestState.Error
                        tcase.message   = tostring(msg)
                    end
                end

                AfterCase(self, tcase)

                Assert.ResetSteps()

                if tcase.state == TestState.Succeed then
                    Info("[UnitTest]%s.%s PASS", tcase.owner._FullName, tcase.name)
                end
            end

            if not onlyself and self.HasSubUnitTests then
                for _, utest in self.SubUnitTests:GetIterator() do
                    utest:Run()
                end
            end

            OnFinal(self)
        end

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- the test cases
        property "TestCases"            { set = false, default = function() return List[TestCase]() end }

        --- whether has child unit test modules
        property "HasSubUnitTests"      { set = false, field = "_UnitTest_HasSubUnitTests" }

        --- the child unit test modules
        property "SubUnitTests"         { set = false, default = function(self) self._UnitTest_HasSubUnitTests = true return List[UnitTest]() end }

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        function __ctor(self, ...)
            super(self, ...)

            if self._Parent then
                self._Parent.SubUnitTests:Insert(self)
            end

            self.export{ UnitTest, Assert, __Test__ }
        end
    end)

    _G.UnitTest                         = _G.UnitTest or UnitTest
end)