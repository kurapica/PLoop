-- Author      : Kurapica
-- Create Date : 2016/01/24
-- ChangeLog   :

_ENV = Module "System.IO" "0.1.0"

namespace "System"

_PipeFunc = [[
local popen, ftype, target, command, result = ...
return function (%s)
	local f = popen(%s, "r")
	if ftype(f) == "file" then
		local ct = f:read("*all")
		f:close()
		if ct then
			return target(%s)
		else
			return target(%s)
		end
	end
end
]]

__Doc__ [[The System.IO namespaces contain types that support input and output.]]
__Final__() __Sealed__()
interface "IO" (function (_ENV)

	local popen = io.popen
	local ftype = io.type
	local OS_TYPE

	__Flags__()
	enum "OSType" { "Unknown", "Windows", "MacOS", "Linux" }

	__Doc__ [[The pipe read attribute used to provide informations based on the os.]]
	__AttributeUsage__{AttributeTarget = AttributeTargets.Method, RunOnce = true, AllowMultiple = true }
	__Final__() __Sealed__()
	class "__PipeRead__" (function (_ENV)
		extend "IAttribute"

		----------------------------------
		-- Property
		----------------------------------
		__Doc__ [[The type of the operation system]]
		property "OS" { Type = OSType }

		__Doc__ [[The command format]]
		property "CommandFormat" { Type = String }

		__Doc__ [[The result capture format]]
		property "ResultFormat" { Type = String }

		__Doc__ [[The provider to generate the command]]
		property "CommandProvider" { Type = Function }

		__Doc__ [[The provider to generate the result]]
		property "ResultProvider" { Type = Function }

		__Doc__[[The method's argumet numbers, default 1]]
		property "ArgCount" { Type = NaturalNumber, Default = 1 }

		----------------------------------
		-- ApplyAttribute
		----------------------------------
		function ApplyAttribute(self, target, targetType, owner, name)
			if self.OS and not Reflector.ValidateFlags(GetOperationSystem(), self.OS) then return end
			if not (self.CommandFormat or self.CommandProvider) then return end

			local args = ""
			if self.ArgCount > 0 then
				args = "arg1"
				for i = 2, self.ArgCount do args = args .. ", arg" .. i end
			end

			local commandCode = self.CommandFormat and "command:format(" .. args .. ")" or self.CommandProvider and "command(" .. args .. ")"
			local resultCode = self.ResultFormat and "ct:match(result)" or self.ResultProvider and "result(ct)" or "ct"
			if args ~= "" then resultCode = args .. ", " .. resultCode end

			return assert(loadstring(_PipeFunc:format(args, commandCode, resultCode, args))) (popen, ftype, target, self.CommandFormat or self.CommandProvider, self.ResultFormat or self.ResultProvider)
		end

		----------------------------------
		-- Constructor
		----------------------------------
		__Arguments__{ String, String, OSType, Argument(NaturalNumber, true, 1) }
		function __PipeRead__(self, commandFormat, resultFormat, ostype, argCount)
			self.CommandFormat = commandFormat
			self.ResultFormat = resultFormat
			self.OS = ostype
			self.ArgCount = argCount
		end

		__Arguments__{ String, Function, OSType, Argument(NaturalNumber, true, 1) }
		function __PipeRead__(self, commandFormat, resultProvider, ostype, argCount)
			self.CommandFormat = commandFormat
			self.ResultProvider = resultProvider
			self.OS = ostype
			self.ArgCount = argCount
		end

		__Arguments__{ Function, String, OSType, Argument(NaturalNumber, true, 1) }
		function __PipeRead__(self, commandProvider, resultFormat, ostype, argCount)
			self.CommandProvider = commandProvider
			self.ResultFormat = resultFormat
			self.OS = ostype
			self.ArgCount = argCount
		end

		__Arguments__{ Function, Function, OSType, Argument(NaturalNumber, true, 1) }
		function __PipeRead__(self, commandProvider, resultProvider, ostype, argCount)
			self.CommandProvider = commandProvider
			self.ResultProvider = resultProvider
			self.OS = ostype
			self.ArgCount = argCount
		end

		__Arguments__{}
		function __PipeRead__() end
	end)

	----------------------------------
	-- Static Method
	----------------------------------
	__Doc__[[Get the operation system]]
	function GetOperationSystem()
		if OS_TYPE then return OS_TYPE end

		local f = popen("echo %OS%", "r")
		local ct = f and f:read("*all"):match("^%w+")
		if f then f:close() end
		if ct then
			OS_TYPE = OSType.Windows
		else
			f = popen("export PATH='/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/X11/bin'\nuname", "r")
			if f then
				ct = f:read("*all")
				f:close()
				if ct then ct = ct:match("^%w+") end
			end
			OS_TYPE = ct == "Darwin" and OSType.MacOS
				or ct == "Linux" and OSType.Linux
				or OSType.Unknown
		end
		Debug("[System.IO][GetOperationSystem] %s", OSType(OS_TYPE))
		return OS_TYPE
	end
end)