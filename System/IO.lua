-- Author      : Kurapica
-- Create Date : 2016/01/24
-- ChangeLog   :

_ENV = Module "System.IO" "0.1.0"

namespace "System"

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

		----------------------------------
		-- ApplyAttribute
		----------------------------------
		function ApplyAttribute(self, target)
			if self.OS and not Reflector.ValidateFlags(GetOperationSystem(), self.OS) then return end

			local commandFormat = self.CommandFormat
			local commandProvider = self.CommandProvider
			local resultFormat = self.ResultFormat
			local resultProvider = self.ResultProvider

			if commandFormat then
				if resultFormat then
					return function (...)
						local f = popen(commandFormat:format(...), "r")
						if ftype(f) == "file" then
							local rt = f:read("*all")
							f:close()
							return target(rt:match(resultFormat), ...)
						end
					end
				elseif resultProvider then
					return function (...)
						local f = popen(commandFormat:format(...), "r")
						if ftype(f) == "file" then
							local rt = f:read("*all")
							f:close()
							return target(resultProvider(rt), ...)
						end
					end
				else
					return function (...)
						local f = popen(commandFormat:format(...), "r")
						if ftype(f) == "file" then
							local rt = f:read("*all")
							f:close()
							return target(rt, ...)
						end
					end
				end
			elseif commandProvider then
				if resultFormat then
					return function (...)
						local f = popen(commandProvider(...), "r")
						if ftype(f) == "file" then
							local rt = f:read("*all")
							f:close()
							return target(rt:match(resultFormat), ...)
						end
					end
				elseif resultProvider then
					return function (...)
						local f = popen(commandProvider(...), "r")
						if ftype(f) == "file" then
							local rt = f:read("*all")
							f:close()
							return target(resultProvider(rt), ...)
						end
					end
				else
					return function (...)
						local f = popen(commandProvider(...), "r")
						if ftype(f) == "file" then
							local rt = f:read("*all")
							f:close()
							return target(rt, ...)
						end
					end
				end
			end
		end

		----------------------------------
		-- Constructor
		----------------------------------
		__Arguments__{ String, String, Argument(OSType, true) }
		function __PipeRead__(self, commandFormat, resultFormat, ostype)
			self.CommandFormat = commandFormat
			self.ResultFormat = resultFormat
			self.OS = ostype
		end

		__Arguments__{ String, Function, Argument(OSType, true) }
		function __PipeRead__(self, commandFormat, resultProvider, ostype)
			self.CommandFormat = commandFormat
			self.ResultProvider = resultProvider
			self.OS = ostype
		end

		__Arguments__{ Function, String, Argument(OSType, true) }
		function __PipeRead__(self, commandProvider, resultFormat, ostype)
			self.CommandProvider = commandProvider
			self.ResultFormat = resultFormat
			self.OS = ostype
		end

		__Arguments__{ Function, Function, Argument(OSType, true) }
		function __PipeRead__(self, commandProvider, resultProvider, ostype)
			self.CommandProvider = commandProvider
			self.ResultProvider = resultProvider
			self.OS = ostype
		end

		__Arguments__{}
		function __PipeRead__() end
	end)

	----------------------------------
	-- Static Method
	----------------------------------
	__Doc__[[Get the operation system]]
	function GetOperationSystem(result)
		if OS_TYPE then return OS_TYPE end

		local f = popen("echo %OS%", "r")
		local ct = f:read("*all"):match("^%w+")
		f:close()
		if ct then
			OS_TYPE = OSType.Windows
		else
			f = popen("export PATH=/usr/bin\nuname", "r")
			ct = f:read("*all"):match("^%w+")
			f:close()
			OS_TYPE = ct == "Darwin" and OSType.MacOS
				or ct == "Linux" and OSType.Linux
				or OSType.Unknown
		end
		return OS_TYPE
	end
end)