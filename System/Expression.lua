-- Author      : Kurapica
-- Create Date : 2016/02/07
-- ChangeLog   :

_ENV = Module "System.Expression" "0.1.0"

namespace "System"

__Final__() __Sealed__()
interface "Expression" (function (_ENV)

	-- A simple lambda generator
	_LambdaCache = {}

	__Doc__[[Used to get anonymous functions based on lambda expression]]
	__Sealed__()
	struct "Lambda" {
		function (value)
			assert(type(value) == "string", "%s must be a string like 'x,y=>x+y'")
			local func = _LambdaCache[value]
			if not func then
				local param, body = value:match("^(.-)=>(.+)$")
				assert(param and body, "%s must be a string like 'x=>x^2'")
				local args
				for arg in param:gmatch("[_%w]+") do args = (args and args .. "," or "") .. arg end
				if not body:find(";") and not body:find("return") then body = "return " .. body end
				if args then
					func = loadstring(("local %s = ... %s"):format(args, body))
				else
					func = loadstring(body)
				end
			end
			assert(func, "%s must be a string like 'x,y=>x+y'")
			return func
		end
	}
end)
