--===========================================================================--
--                                                                           --
--                         System.IO.OperationSystem                         --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2018/03/26                                               --
-- Update Date  :   2018/03/26                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.IO"

    --- Repesents the operations system types
    __Sealed__() __Flags__()
    enum "OperationSystemType" { Unknown = 0, "Windows", "MacOS", "Linux" }

    --- Represents the operation system
    __Abstract__() __Final__() __Sealed__()
    class "OperationSystem" (function(_ENV)
        local OS_TYPE

        export {
            popen                   = _G.io.popen,
            ftyle                   = _G.io.type,
            loadsnippet             = Toolset.loadsnippet,
        }

        export { OperationSystemType }

        -----------------------------------------------------------
        --                    static property                    --
        -----------------------------------------------------------
        --- The current Operation system
        __Static__() property "Current" {
            get = function()
                if OS_TYPE then return OS_TYPE end

                -- Check for windows
                local f = popen("echo %OS%", "r")
                if f then
                    local ct = f:lines()()
                    if ct and ct:match("^%w+") then
                        OS_TYPE = OperationSystemType.Windows
                        return OS_TYPE
                    end
                end

                -- Check for unix
                f = popen("export PATH='/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/X11/bin'\nuname", "r")
                if f then
                    local ct = f:lines()()
                    f:close()
                    if ct then ct = ct:match("^%w+") end

                    OS_TYPE = ct == "Darwin" and OperationSystemType.MacOS
                        or ct == "Linux" and OperationSystemType.Linux
                        or OperationSystemType.Unknown
                end

                return OS_TYPE
            end,
        }
    end)

    --- Provide informations based on the os
    __Final__() __Sealed__()
    class "__PipeRead__" (function(_ENV)
        extend "IInitAttribute"

        export {
            popen                   = _G.io.popen,
            ftype                   = _G.io.type,
            loadsnippet             = Toolset.loadsnippet,

            Enum, OperationSystem,

            _PipeFunc = [[
                local popen, ftype, definition, command, result = ...
                return function (%s)
                    local f = popen(%s, "r")
                    if ftype(f) == "file" then
                        --f:flush()
                        local ct = f:read("*all")
                        f:close()
                        if ct then
                            return definition(%s)
                        else
                            return definition(%s)
                        end
                    end
                end
            ]],
        }
        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- modify the target's definition
        -- @param   target                      the target
        -- @param   targettype                  the target type
        -- @param   definition                  the target's definition
        -- @param   owner                       the target's owner
        -- @param   name                        the target's name in the owner
        -- @param   stack                       the stack level
        -- @return  definition                  the new definition
        function InitDefinition(self, target, targettype, definition, owner, name, stack)
            if self.OperationSystem and not Enum.ValidateFlags(OperationSystem.Current, self.OperationSystem) then return end
            if not (self.CommandFormat or self.CommandProvider) then return end

            local args = ""
            if self.ArgumetCount > 0 then
                args = "arg1"
                for i = 2, self.ArgumetCount do args = args .. ", arg" .. i end
            end

            local commandCode = self.CommandFormat and "command:format(" .. args .. ")" or self.CommandProvider and "command(" .. args .. ")"
            local resultCode = self.ResultFormat and "ct:match(result)" or self.ResultProvider and "result(ct)" or "ct"
            if args ~= "" then resultCode = args .. ", " .. resultCode end

            return loadsnippet(_PipeFunc:format(args, commandCode, resultCode, args)) (popen, ftype, definition, self.CommandFormat or self.CommandProvider, self.ResultFormat or self.ResultProvider)
        end

        -----------------------------------------------------------
        --                       property                       --
        -----------------------------------------------------------
        --- the attribute target
        property "AttributeTarget"  { set = false, default = AttributeTargets.Method }

        --- The type of the operation system
        property "OperationSystem"  { type = OperationSystemType }

        --- The command format
        property "CommandFormat"    { type = String }

        --- The result capture format
        property "ResultFormat"     { type = String }

        --- The provider to generate the command
        property "CommandProvider"  { type = Function }

        --- The provider to generate the result
        property "ResultProvider"   { type = Function }

        --- The method's argumet numbers, default 1
        property "ArgumetCount"     { type = NaturalNumber, Default = 1 }

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{}
        function __PipeRead__() end

        __Arguments__{ Callable, Callable, OperationSystemType, NaturalNumber/1 }
        function __PipeRead__(self, commandProvider, resultProvider, ostype, argCount)
            self.CommandProvider    = commandProvider
            self.ResultProvider     = resultProvider
            self.OperationSystem    = ostype
            self.ArgumetCount       = argCount
        end

        __Arguments__{ Callable, String, OperationSystemType, NaturalNumber/1 }
        function __PipeRead__(self, commandProvider, resultFormat, ostype, argCount)
            self.CommandProvider    = commandProvider
            self.ResultFormat       = resultFormat
            self.OperationSystem    = ostype
            self.ArgumetCount       = argCount
        end

        __Arguments__{ String, Callable, OperationSystemType, NaturalNumber/1 }
        function __PipeRead__(self, commandFormat, resultProvider, ostype, argCount)
            self.CommandFormat      = commandFormat
            self.ResultProvider     = resultProvider
            self.OperationSystem    = ostype
            self.ArgumetCount       = argCount
        end

        __Arguments__{ String, String, OperationSystemType, NaturalNumber/1 }
        function __PipeRead__(self, commandFormat, resultFormat, ostype, argCount)
            self.CommandFormat      = commandFormat
            self.ResultFormat       = resultFormat
            self.OperationSystem    = ostype
            self.ArgumetCount       = argCount
        end
    end)
end)