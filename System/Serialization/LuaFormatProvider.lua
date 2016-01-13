-- Author      : Kurapica
-- Create Date : 2015/09/14
-- ChangeLog   :

_ENV = Module "System.Serialization.LuaFormatProvider" "1.0.0"

namespace "System.Serialization"

__Doc__ [[Serialization format provider for common lua data]]
class "LuaFormatProvider" (function(_ENV)
	inherit "FormatProvider"

	__Arguments__{ Any }
	function Serialize(self, data)
		return data
	end

	__Doc__[[Deserialize the data to common lua data.]]
	__Arguments__{ Any }
	function Deserialize(self, data)
		return data
	end
end)