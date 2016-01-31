--=============================
-- System.IO.LuaLoader
--
-- Author : Kurapica
-- Create Date : 2016/01/28
--=============================
_ENV = Module "System.IO.Resource.LuaLoader" "1.0.0"

namespace "System.IO.Resource"

setfenv = setfenv or function() end

-- Fake Load Environment
do
	_envMeta = {__index = function (self, key)
		local val = _G[key]
		if val ~= nil then
			rawset(self, key, val)
		end
		return val
	end}

	fakeForName = function (_ENV, target, rclass, rinterface, rModule)
		class = function(name)
			if name:lower() == target then __LuaLoader_Target = name end
			local ret = rclass(name, nil, 3)
			return ret
		end

		interface = function(name)
			if name:lower() == target then __LuaLoader_Target = name end
			local ret = rinterface(name, nil, 3)
			return ret
		end

		Module = function (name)
			__LuaLoader_Module = rModule(name)
			return __LuaLoader_Module
		end
	end

	fakeForTarget = function (_ENV, target, tarName, rclass, rinterface, rModule)
		class = function(name)
			if name == tarName then
				local ret = rclass(target, nil, 3)
				return ret
			else
				local ret = rclass(name, nil, 3)
				return ret
			end
		end

		interface = function(name)
			if name == tarName then
				local ret = rinterface(target, nil, 3)
				return ret
			else
				local ret = rinterface(name, nil, 3)
				return ret
			end
		end

		Module = function (name)
			__LuaLoader_Module = rModule(name)
			__LuaLoader_Module[tarName] = target
			return __LuaLoader_Module
		end
	end

	getLoadEnv = function (target)
		local env = setmetatable({}, _envMeta)

		-- Install fake keywords
		if type(target) == "string" then
			setfenv(fakeForName, env)

			fakeForName(env, target, _G.class, _G.interface, _G.Module)

			setfenv(fakeForName, _M)
		else
			local tarName = Reflector.GetNameSpaceName(target)

			setfenv(fakeForTarget, env)

			fakeForTarget(env, target, tarName, _G.class, _G.interface, _G.Module)

			setfenv(fakeForTarget, _M)
		end

		return env
	end
end

__ResourceLoader__"lua"
__Unique__() __Sealed__()
class "LuaLoader" (function (_ENV)
	extend "IResourceLoader"

	function Load(self, path, target)
		local name = target or Path.GetFileNameWithoutSuffix(path):lower()

		local env = getLoadEnv(name)

		local f, err = loadfile(path, nil, env)

		if f then
			setfenv(f, env)

			-- @todo Check
			assert( pcall( f ) )

			-- Get the target
			if not target then
				if env.__LuaLoader_Target then
					if env.__LuaLoader_Module then
						target = rawget(env.__LuaLoader_Module, env.__LuaLoader_Target)

						if not (Reflector.IsClass(target) or Reflector.IsInterface(target)) then
							target = nil
						end
					end

					if not target then
						target = rawget(env, env.__LuaLoader_Target)

						if not (Reflector.IsClass(target) or Reflector.IsInterface(target)) then
							target = nil
						end
					end
				elseif env.__LuaLoader_Module then
					for k, v in pairs(env.__LuaLoader_Module) do
						if type(k) == "string" and k:lower() == name and (Reflector.IsClass(v) or Reflector.IsInterface(v)) then
							target = v
							break
						end
					end
				end
			end

			return target
		elseif not err:match("No such file or directory") then
			error(err)
		end
	end
end)