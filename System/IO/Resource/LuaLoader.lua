--=============================
-- System.IO.LuaLoader
--
-- Author : Kurapica
-- Create Date : 2016/01/28
--=============================
_ENV = Module "System.IO.Resource.LuaLoader" "1.0.0"

namespace "System.IO.Resource"

__ResourceLoader__"lua"
__Unique__() __Sealed__()
class "LuaLoader" (function (_ENV)
	extend "IResourceLoader"

	function Load(self, path)
		local name = Path.GetFileNameWithoutSuffix(path):lower()

		local types = Reflector.LoadLuaFile(path)

		if types then
			for ty in pairs(types) do
				local tname = Reflector.GetNameSpaceName(ty)
				if tname:lower() == name then
					return ty
				end
			end
		end
	end
end)