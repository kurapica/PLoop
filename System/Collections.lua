-- Author      : Kurapica
-- Create Date : 2016/01/24
-- ChangeLog   :

_ENV = Module "System.Collections" "1.0.0"

namespace "System.Collections"

-----------------------
-- Interface
-----------------------
__Doc__[[Provide basic support for collection]]
__Sealed__()
interface "Iterable" (function (_ENV)
	__Doc__[[Return the iterator, maybe with obj and start index]]
	__Require__() function GetIterator(self) end
end)