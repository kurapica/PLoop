-- Author      : Kurapica
-- Create Date : 2016/02/07
-- ChangeLog   :

_ENV = Module "System.Expression" "0.1.0"

namespace "System"

__Final__() __Sealed__()
interface "Expression" (function (_ENV)

	-----------------------------------
	-- Lambda & new Callable
	-----------------------------------
	-- A simple lambda generator
	_LambdaCache = {}

	__Doc__[[Used to get anonymous functions based on lambda expression]]
	__Sealed__()
	struct "Lambda" {
		function (value)
			assert(type(value) == "string" and value:find("=>"), "%s must be a string like 'x,y=>x+y'")
			local func = _LambdaCache[value]
			if not func then
				local param, body = value:match("^(.-)=>(.+)$")
				local args
				if param then for arg in param:gmatch("[_%w]+") do args = (args and args .. "," or "") .. arg end end
				if args then
					func = loadstring(("local %s = ... return %s"):format(args, body or ""))
					if not func then
						func = loadstring(("local %s = ... %s"):format(args, body or ""))
					end
				else
					func = loadstring("return " .. (body or ""))
					if not func then
						func = loadstring(body or "")
					end
				end
			end
			assert(func, "%s must be a string like 'x,y=>x+y'")
			return func
		end
	}

	__Doc__[[The value must be callable or a lambda expression]]
	__Sealed__()
	struct "Callable" {
		function (value)
			if type(value) == "string" then return Lambda(value) end
			assert(Reflector.IsCallable(value), "%s isn't callable.")
		end
	}
end)
