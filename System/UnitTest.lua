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

        local crtTestResult

        export {
            pcall               = pcall,
            ipairs              = ipairs,
            Info                = Logger.Default[Logger.LogLevel.Info],
            Warn                = Logger.Default[Logger.LogLevel.Warn],
            Error               = Logger.Default[Logger.LogLevel.Error],

            List, UnitTest,
        }

        --- A set of assert methods
        __Final__() __Sealed__() interface "Assert" (function(_ENV)
            export {
                tostring        = tostring,
                Info            = Info,
                Warn            = Warn,
                Error           = Error,
            }

            local function addFailure(message)
                if not crtTestResult then return end
                if not (crtTestResult.CurrentTest and crtTestResult.CurrentCase) then return end

                crtTestResult.CurrentState = false

                Warn("[UnitTest]%s[%s] Failed%s%s", crtTestResult.CurrentTest._FullName, crtTestResult.CurrentCase, message and " - " or "", message or "")

                crtTestResult.Failures[crtTestResult.CurrentTest._FullName .. "[" .. crtTestResult.CurrentCase .. "]"] = message or true
            end

            -----------------------------------------------------------
            --                        method                         --
            -----------------------------------------------------------
            --- Checks whether the two values are equal
            __Static__() function Equal(expected, actual)
                if expected ~= actual then addFailure("Expected " .. tostring(expected) .. ", got " .. tostring(actual)) end
            end

            --- Checks that the condition is false
            __Static__() function False(condition)
                if condition then addFailure("Expected false condition") end
            end

            --- Checks that the value isn't nil
            __Static__() function NotNil(val)
                if val == nil then addFailure("Expected not nil value") end
            end

            --- Checks that the value is nil
            __Static__() function Nil(val)
                if val ~= nil then addFailure("Expected nil value") end
            end

            --- Checks that the condition is true
            __Static__() function True(condition)
                if not condition then addFailure("Expected true condition") end
            end

            --- Fail the test with message
            __Static__() function Fail(message)
                addFailure(message)
            end
        end)

        --- A TestResult collects the results of executing a test case
        __Final__() __Sealed__() class "TestResult" (function(_ENV)
            export { Dictionary }

            -----------------------------------------------------------
            --                       property                        --
            -----------------------------------------------------------
            --- the error list
            __Indexer__(String)
            property "Errors"   {
                type    = String + Boolean,
                get     = function(self, test) return self[2][test] end,
                set     = function(self, test, val) self[2][test] = val end,
            }

            --- the failure list
            __Indexer__(String)
            property "Failures" {
                type    = String + Boolean,
                get     = function(self, test) return self[3][test] end,
                set     = function(self, test, val) self[3][test] = val end,
            }

            --- the current test model
            property "CurrentTest" { type = UnitTest, handler = function(self) self.CurrentState = true end }

            --- the current test case
            property "CurrentCase" { type = String, handler = function(self) self.CurrentState = true end }

            --- the current test case's state
            property "CurrentState"{ type = Boolean }

            -----------------------------------------------------------
            --                      constructor                      --
            -----------------------------------------------------------
            function __new() return { [1] = Dictionary(), [2] = Dictionary(), [3] = Dictionary() }, true end
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
                    owner._TestCases:Insert(name)
                else
                    error("__Test__ can only be applyed to objects of System.UnitTest", stack + 1)
                end
            end

            ----------------------------------------------
            --                 Property                 --
            ----------------------------------------------
            property "AttributeTarget"  { default = AttributeTargets.Function }
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
        __Arguments__{ TestResult/nil }
        function Run(self, result)
            result                  = result or TestResult()
            crtTestResult           = result

            crtTestResult.CurrentTest = self

            OnInit(self)

            for _, tcase in self._TestCases:GetIterator() do
                crtTestResult.CurrentCase = tcase

                BeforeCase(self, tcase)

                local ok, msg = pcall(self[tcase], result)

                AfterCase(self, tcase)

                if crtTestResult.CurrentState then
                    Info("[UnitTest]%s[%s] PASS", crtTestResult.CurrentTest._FullName, crtTestResult.CurrentCase)
                end
            end

            if self._HasSubUnitTests then
                for _, utest in self._SubUnitTests:GetIterator() do
                    utest:Run(result)
                end
            end

            OnFinal(self)

            return result
        end

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- the test cases
        property "_TestCases"       { set = false, default = function() return List() end }

        --- whether has child unit test modules
        property "_HasSubUnitTests" { set = false, field = "_UnitTest_HasSubUnitTests" }

        --- the child unit test modules
        property "_SubUnitTests"    { set = false, default = function(self) self._UnitTest_HasSubUnitTests = true return List() end }

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        function __ctor(self, ...)
            super(self, ...)

            if self._Parent then
                self._Parent._SubUnitTests:Insert(self)
            end

            self.export{ UnitTest, Assert, __Test__ }
        end
    end)

    _G.UnitTest = _G.UnitTest or UnitTest
end)