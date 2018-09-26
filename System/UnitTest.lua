--===========================================================================--
--                                                                           --
--                              System.UnitTest                              --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2018/09/23                                               --
-- Update Date  :   2018/09/23                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    --- the unit test framework
    __Final__() __Sealed__() class "System.UnitTest" (function(_ENV)
        inherit "Module"

        export {
            pcall               = pcall,
            ipairs              = ipairs,
            type                = type,
            isObjectType        = Class.IsObjectType,
            Info                = Logger.Default[Logger.LogLevel.Info],
            Warn                = Logger.Default[Logger.LogLevel.Warn],
            Error               = Logger.Default[Logger.LogLevel.Error],

            List, UnitTest,
        }

        --- the test state
        __Sealed__() enum "TestState" {
            Succeed             = 1,
            Failed              = 2,
            Error               = 3,
        }

        --- the test case
        __Sealed__() struct "TestCase" {
            { name = "owner",   type = UnitTest,    require = true },
            { name = "name",    type = String,      require = true },
            { name = "func",    type = Function,    require = true },
            { name = "desc",    type = String },
            { name = "state",   type = TestState,   default = Succeed },
            { name = "message", type = String },
        }

        __Sealed__() class "TestFailureException" { Exception }

        --- A set of assert methods
        __Final__() __Sealed__() interface "Assert" (function(_ENV)
            export {
                type            = type,
                tostring        = tostring,
                error           = error,
                Info            = Info,
                Warn            = Warn,
                Error           = Error,

                TestState, TestFailureException
            }

            -----------------------------------------------------------
            --                        method                         --
            -----------------------------------------------------------
            --- Checks whether the two values are equal(only primitive)
            __Static__() function Equal(expected, actual)
                if expected ~= actual then throw(TestFailureException("Expected " .. tostring(expected) .. ", got " .. tostring(actual))) end
            end

            --- Checks that the condition is false
            __Static__() function False(condition)
                if condition then throw(TestFailureException("Expected false condition")) end
            end

            --- Checks that the value isn't nil
            __Static__() function NotNil(val)
                if val == nil then throw(TestFailureException("Expected not nil value")) end
            end

            --- Checks that the value is nil
            __Static__() function Nil(val)
                if val ~= nil then throw(TestFailureException("Expected nil value")) end
            end

            --- Checks that the condition is true
            __Static__() function True(condition)
                if not condition then throw(TestFailureException("Expected true condition")) end
            end

            --- Checks that the two values are the same
            __Static__() function Same(expected, actual)
                local te, ta = type(expected), type(actual)

                if te ~= ta then throw(TestFailureException("Expected the same value")) end

                if te == "table" then

                else
                    if expected ~= actual then throw(TestFailureException("Expected the same value")) end
                end
            end

            --- Fail the test with message
            __Static__() function Fail(message) throw(TestFailureException(message or "Fail")) end
        end)

        --- Used to mark a method as test case
        __Final__() __Sealed__() class "__Test__" (function(_ENV)
            extend "IAttachAttribute"

            export {
                isObjectType    = Class.IsObjectType,

                UnitTest,
            }

            function AttachAttribute(self, target, targettype, owner, name, stack)
                if isObjectType(owner, UnitTest) then
                    owner.TestCases:Insert {
                        owner= owner,
                        name = name,
                        func = target,
                        desc = self[1],
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
                tcase.state     = TestState.Succeed
                tcase.message   = nil

                BeforeCase(self, tcase)

                local ok, msg   = pcall(tcase.func)

                if not ok and tcase.state == TestState.Succeed then
                    if type(msg) == "string" then
                        Warn("[UnitTest]%s.%s Error%s%s", tcase.owner._FullName, tcase.name, msg and " - " or "", msg or "")

                        tcase.state = TestState.Error
                        tcase.message = msg
                    elseif isObjectType(msg, TestFailureException) then
                        Warn("[UnitTest]%s.%s Failed - %s", tcase.owner._FullName, tcase.name, msg.Message)

                        tcase.state   = TestState.Failed
                        tcase.message = msg.Message
                    end
                end

                AfterCase(self, tcase)

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
        property "TestCases"       { set = false, default = function() return List[TestCase]() end }

        --- whether has child unit test modules
        property "HasSubUnitTests" { set = false, field = "_UnitTest_HasSubUnitTests" }

        --- the child unit test modules
        property "SubUnitTests"    { set = false, default = function(self) self._UnitTest_HasSubUnitTests = true return List[UnitTest]() end }

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

    _G.UnitTest = _G.UnitTest or UnitTest
end)