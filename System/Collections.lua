--===========================================================================--
--                                                                           --
--                            System.Collections                             --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2014/10/13                                               --
-- Update Date  :   2018/03/15                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
	namespace "System.Collections"

    Environment.RegisterGlobalNamespace("System.Collections")

	--- Represents the interface of collections
	__Sealed__()
	interface "Iterable" (function (_ENV)
	    --- Return the iterator, maybe with obj and start index
	    __Abstract__() function GetIterator(self) end
	end)
end)