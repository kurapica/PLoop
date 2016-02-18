--=============================
-- System.Collections.DictionaryStreamWorker
--
-- Author : Kurapica
-- Create Date : 2016/02/04
--=============================
_ENV = Module "System.Collections.DictionaryStreamWorker" "1.0.0"

namespace "System.Collections"

import "System.Threading"

__Final__() __Sealed__()
class "DictionaryStreamWorker" (function (_ENV)
	extend "IDictionary"

	-- Keep idle workers for re-usage
	IdleWorkers = {}

	---------------------------
	-- Method
	---------------------------
	function GetIterator(self)
		local targetDict = self.TargetDict
		local map = self.MapAction
		local filter = self.FilterAction

		-- Clear self and put self into IdleWorkers
		self.TargetDict = nil
		self.MapAction = nil
		self.FilterAction = nil

		if #IdleWorkers < 10 then tinsert(IdleWorkers, self) end

		-- Generate the iterator
		local dowork

		-- Generate the do-work
		if filter then
			-- Check Function
			if map then
				dowork = function(key, value) if filter(key, value) then yield(key, map(key, value)) end end
			else
				dowork = function(key, value) if filter(key, value) then yield(key, value) end end
			end
		else
			-- No filter
			if map then
				dowork = function(key, value) yield(key, map(key, value)) end
			else
				dowork = function(key, value) yield(key, value) end
			end
		end

		-- Generate the for iterator
		return Threading.Iterator(function() for key, value in targetDict:GetIterator() do dowork(key, value) end end)
	end

	---------------------------
	-- Queue Method
	---------------------------
	__Doc__[[Map the items to other type datas]]
	__Arguments__{ Callable }
	function Map(self, func) self.MapAction = func return self end

	__Doc__[[Used to filter the items with a check function]]
	__Arguments__{ Callable }
	function Filter(self, func) self.FilterAction = func return self end

	---------------------------
	-- Final Method
	---------------------------
	__Doc__[[Get the ListStreamWorker of keys]]
	function Keys(self)
		local iter = self:GetIterator()

		return ListStreamWorker( Threading.Iterator(function()
			local index = 0
			for key in iter do
				index = index + 1
				yield(index, key)
			end
		end) )
	end

	__Doc__[[Get the ListStreamWorker of values]]
	function Values(self)
		local iter = self:GetIterator()

		return ListStreamWorker( Threading.Iterator(function()
			local index = 0
			for _, value in iter do
				index = index + 1
				yield(index, value)
			end
		end) )
	end

	__Doc__[[Combine the key-value pairs to get a result]]
	__Arguments__{ Callable, Argument(Any, true) }
	function Reduce(self, func, init)
		local iter = self:GetIterator()
		for key, value in iter do init = func(key, value, init) end
		return init
	end

	__Doc__[[Call the function for each element or set property's value for each element]]
	__Arguments__{ Callable }
	function Each(self, func) for key, value in self:GetIterator() do func(key, value) end end

	----------------------------
	-- Constructor
	----------------------------
	__Arguments__{ IDictionary } function DictionaryStreamWorker(self, dict) self.TargetDict = dict end

	----------------------------
	-- Meta-method
	----------------------------
	__Arguments__{ IDictionary } function __exist(dict)
		local worker = tremove(IdleWorkers)
		if worker then worker.TargetDict = dict end
		return worker
	end

	__call = GetIterator
end)

----------------------------
-- Install to IDictionary
----------------------------

---------------------------
-- Queue Method
---------------------------
__Doc__[[Map the items to other type datas]]
__Arguments__{ Callable }
function IDictionary:Map(func) return DictionaryStreamWorker(self):Map(func) end

__Doc__[[Used to filter the items with a check function]]
__Arguments__{ Callable }
function IDictionary:Filter(func) return DictionaryStreamWorker(self):Filter(func) end

---------------------------
-- Final Method
---------------------------
__Doc__[[Get the ListStreamWorker of keys]]
function IDictionary:Keys() return DictionaryStreamWorker(self):Keys() end

__Doc__[[Get the ListStreamWorker of values]]
function IDictionary:Values() return DictionaryStreamWorker(self):Values() end

__Doc__[[Combine the key-value pairs to get a result]]
__Arguments__{ Callable, Argument(Any, true) }
function IDictionary:Reduce(func, init) return DictionaryStreamWorker(self):Reduce(func, init) end

__Doc__[[Call the function for each element or set property's value for each element]]
__Arguments__{ Callable }
function IDictionary:Each(func) return DictionaryStreamWorker(self):Each(func) end
