--=============================
-- System.Collections.ListStreamWorker
--
-- Author : Kurapica
-- Create Date : 2016/02/04
--=============================
_ENV = Module "System.Collections.ListStreamWorker" "1.0.0"

namespace "System.Collections"

import "System.Threading"

__Final__() __Sealed__()
class "ListStreamWorker" (function (_ENV)
	extend "IList"

	-- Keep idle workers for re-usage
	IdleWorkers = {}

	---------------------------
	-- Method
	---------------------------
	function GetIterator(self)
		local targetList = self.TargetList
		local targetIter = self.TargetIter
		local targetObj = self.TargetObj
		local targetIdx = self.TargetIndex

		local map = self.MapAction
		local filter = self.FilterAction
		local rangeStart = self.RangeStart
		local rangeStop = self.RangeStop
		local rangeStep = self.RangeStep

		-- Clear self and put self into IdleWorkers
		self.TargetList = nil
		self.TargetIter = nil
		self.TargetObj = nil
		self.TargetIndex = nil

		self.MapAction = nil
		self.FilterAction = nil
		self.RangeStart = nil
		self.RangeStop = nil
		self.RangeStep = nil

		if #IdleWorkers < 10 then tinsert(IdleWorkers, self) end

		-- Generate the iterator
		local dowork
		local iter
		local targetCls = targetList and Reflector.GetObjectClass(targetList)

		-- Generate the do-work
		if filter then
			-- Check Function
			if map then
				dowork = function(idx, item) if filter(item) then yield(idx, map(item), item) end end
			else
				dowork = function(idx, item) if filter(item) then yield(idx, item) end end
			end
		else
			-- No filter
			if map then
				dowork = function(idx, item) yield(idx, map(item), item) end
			else
				dowork = function(idx, item) yield(idx, item) end
			end
		end

		-- Generate the for iterator
		if not rangeStart then
			if targetList then
				iter = function() for idx, item in targetList:GetIterator() do dowork(idx, item) end end
			else
				iter = function() for idx, item in targetIter, targetObj, targetIdx do dowork(idx, item) end end
			end
		else
			local lstCount

			-- If the targetCls is ICountable, we can deal with negative position
			if targetCls and Reflector.IsExtendedInterface(targetCls, ICountable) then lstCount = targetList.Count end

			if lstCount then
				if rangeStart < 0 then rangeStart = lstCount + rangeStart + 1 end
				if rangeStop < 0 then rangeStop = lstCount + rangeStop + 1 end
			else
				if rangeStop == -1 then rangeStop = math.huge end
				if rangeStart < 0 or rangeStop < 0 then error(("%s can't handle negative index"):format(tostring(targetCls)), 2) end
			end

			if targetCls and Reflector.IsExtendedInterface(targetCls, IIndexedList) then
				-- The targetList should be used like targetList[index]
				iter = function ()
					for i = rangeStart, rangeStop, rangeStep do
						local item = targetList[i]
						if item == nil then return end
						dowork(i, item)
					end
				end
			else
				if lstCount then
					if rangeStart > rangeStop then rangeStart, rangeStop, rangeStep = rangeStop, rangeStart, - rangeStep end
					if rangeStart < 1 then rangeStart = 1 end
					if rangeStart > lstCount then rangeStep = -1 end -- no items would be scaned
				else
					if rangeStart > rangeStop then rangeStart, rangeStop, rangeStep = rangeStop, rangeStart, - rangeStep end
				end

				-- So we should run an iterator over the targetList to fetch datas, like link list
				if targetList then
					targetIter, targetObj, targetIdx = targetList:GetIterator()
				end

				iter = function()
					if rangeStep < 1 then return end

					local idx = 1
					local stepCnt = rangeStep
					local item

					while idx < rangeStart do
						targetIdx, item = targetIter(targetObj, targetIdx)
						if item == nil then return end
						idx = idx + 1
					end

					while idx <= rangeStop do
						targetIdx, item = targetIter(targetObj, targetIdx)
						if item == nil then return end

						if stepCnt == rangeStep then
							stepCnt = 0
							dowork(idx, item)
						end

						stepCnt = stepCnt + 1
						idx = idx + 1
					end
				end
			end
		end

		return Threading.Iterator(iter)
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

	__Doc__[[Used to select items with ranged index]]
	__Arguments__{ Argument(Integer, true, 1), Argument(Integer, true, -1), Argument(Integer, true, 1) }
	function Range(self, start, stop, step) self.RangeStart, self.RangeStop, self.RangeStep = start, stop, step return self end

	---------------------------
	-- Final Method
	---------------------------
	__Doc__[[Convert the selected items to a list]]
	__Arguments__{ Argument(IListClass, true) }
	function ToList(self, cls) return cls(self) end

	__Doc__[[Combine the items to get a result]]
	__Arguments__{ Callable, Argument(Any, true) }
	function Reduce(self, func, init)
		local iter = self:GetIterator()
		if init == nil then init = select(2, iter()) end
		for _, item in iter do init = func(item, init) end
		return init
	end

	__Doc__[[Call the function for each element or set property's value for each element]]
	__Arguments__{ Callable }
	function Each(self, func) for _, obj in self:GetIterator() do func(obj) end end

	----------------------------
	-- Constructor
	----------------------------
	__Arguments__{ System.Callable, Argument(Any, true), Argument(Any, true) }
	function ListStreamWorker(self, iter, obj, idx)
		self.TargetIter = iter
		self.TargetObj = obj
		self.TargetIndex = idx
	end

	__Arguments__{ IList } function ListStreamWorker(self, list) self.TargetList = list end

	----------------------------
	-- Meta-method
	----------------------------
	__Arguments__{ System.Callable, Argument(Any, true), Argument(Any, true) }
	function __exist(iter, obj, idx)
		local worker = tremove(IdleWorkers)
		if worker then
			worker.TargetIter = iter
			worker.TargetObj = obj
			worker.TargetIndex = idx
		end
		return worker
	end

	__Arguments__{ IList } function __exist(list)
		local worker = tremove(IdleWorkers)
		if worker then worker.TargetList = list end
		return worker
	end

	__call = GetIterator
end)

----------------------------
-- Install to IList
----------------------------

---------------------------
-- Queue Method
---------------------------
__Doc__[[Map the items to other type datas]]
__Arguments__{ Callable }
function IList:Map(func) return ListStreamWorker(self):Map(func) end

__Doc__[[Used to filter the items with a check function]]
__Arguments__{ Callable }
function IList:Filter(func) return ListStreamWorker(self):Filter(func) end

__Doc__[[Used to select items with ranged index]]
__Arguments__{ Argument(Integer, true, 1), Argument(Integer, true, -1), Argument(Integer, true, 1) }
function IList:Range(start, stop, step) return ListStreamWorker(self):Range(start, stop, step) end

---------------------------
-- Final Method
---------------------------
__Doc__[[Convert the selected items to a list]]
__Arguments__{ Argument(IListClass, true) }
function IList:ToList(cls) return ListStreamWorker(self):ToList(cls) end

__Doc__[[Combine the items to get a result]]
__Arguments__{ Callable, Argument(Any, true) }
function IList:Reduce(func, init) return ListStreamWorker(self):Reduce(func, init) end

__Doc__[[Call the function for each element or set property's value for each element]]
__Arguments__{ Callable }
function IList:Each(func) return ListStreamWorker(self):Each(func) end
