-- Author      : Kurapica
-- Create Date : 2012/02/08
-- ChangeLog   :
--               2012/05/06 Push, Pop, Shift, Unshift added
--               2012/07/31 Struct supported
--               2012/09/18 Contain method added

Module "System.Array" "1.0.0"

namespace "System"

class "Array"
	extend "IFIterator"

	doc [======[
		@name Array
		@type class
		@desc Array object is used to control a group objects with same class, event handlers can be assign to all objects with one definition.
		@param class|struct the array's element's type
	]======]

	------------------------------------------------------
	-- Event
	------------------------------------------------------

	------------------------------------------------------
	-- Local functions
	------------------------------------------------------
	MAX_STACK = 100

	_ArrayInfo = _ArrayInfo or setmetatable({}, {__mode = "k",})

	local function defaultComp(t1, t2)
		return t1 < t2
	end

	local function bubble_sort(self, start, last, comp)
		start = start or 1
		last = last or #self
		comp = comp or defaultComp

		local chk = true
		local j

		if last > #self then last = #self end

		while last > start and chk do
			chk = false

			for i = start, last - 1 do
				if comp(self[i+1], self[i]) then
					self[i], self[i+1] = self[i+1], self[i]
					chk = true
				end

				j = last - (i - start)

				if comp(self[j], self[j - 1]) then
					self[j], self[j - 1] = self[j - 1], self[j]
					chk = true
				end
			end

			start = start  + 1
			last = last - 1
		end
	end

	local function buildLoserTree(tmp, loserTree, start, comp, pos)
		if pos >= start then
			return pos - start
		end

		local left = buildLoserTree(tmp, loserTree, start, comp, 2 * pos)
		local right = buildLoserTree(tmp, loserTree, start, comp, 2 * pos + 1)

		if comp(tmp[left * MAX_STACK + 1], tmp[right * MAX_STACK + 1]) then
			loserTree[pos] = right
			return left
		else
			loserTree[pos] = left
			return right
		end
	end

	local function adjustLoserTree(tmp, loserTree, grpPos, comp, pos, minGrp)
		if pos == 0 then return minGrp end

		local parentGrp = loserTree[pos]

		if grpPos[minGrp] > MAX_STACK then
			loserTree[pos] = minGrp
			return adjustLoserTree(tmp, loserTree, grpPos, comp, floor(pos/2), parentGrp)
		elseif grpPos[parentGrp] > MAX_STACK then
			return adjustLoserTree(tmp, loserTree, grpPos, comp, floor(pos/2), minGrp)
		elseif comp(tmp[minGrp * MAX_STACK + grpPos[minGrp]], tmp[parentGrp * MAX_STACK + grpPos[parentGrp]]) then
			return adjustLoserTree(tmp, loserTree, grpPos, comp, floor(pos/2), minGrp)
		else
			loserTree[pos] = minGrp
			return adjustLoserTree(tmp, loserTree, grpPos, comp, floor(pos/2), parentGrp)
		end
	end


	------------------------------------------------------
	-- Method
	------------------------------------------------------
	doc [======[
		@name Sort
		@type method
		@desc Sort array
		@format [compfunc]
		@param compfunc compare function with two args (v1, v2), true if the v1 < v2
		@return nil
	]======]
	function Sort(self, comp)
		if type(comp) ~= "function" then comp = defaultComp end

		if #self <= MAX_STACK then
			return bubble_sort(self, 1, #self, comp)
		end

		local tmp = {}
		local len = #self

		for i = 1, len do
			tinsert(tmp, self[i])
		end

		local grp = 0

		while grp * MAX_STACK < len do
			bubble_sort(tmp, grp * MAX_STACK + 1, (grp + 1) * MAX_STACK, comp)
			grp = grp + 1
		end

		-- Build Loser Tree
		local loserTree = {}
		local grpPos = {}
		local minGrp = nil

		-- Init parent node
		for i = 1, grp - 1 do
			loserTree[i] = -1
		end

		-- Init leaf node
		for i = 0, grp - 1 do
			loserTree[grp + i] = i
			grpPos[i] = 1
		end

		-- Init Loser Tree
		minGrp = buildLoserTree(tmp, loserTree, grp, comp, 1)

		-- Sort
		local index = 1

		while index <= len do
			-- set data
			self[index] = tmp[minGrp * MAX_STACK + grpPos[minGrp]]
			grpPos[minGrp] = grpPos[minGrp] + 1

			if minGrp == (grp - 1) and (minGrp * MAX_STACK + grpPos[minGrp] > len) then
				grpPos[minGrp] = MAX_STACK + 1
			end

			index = index + 1

			-- get new min group
			minGrp = adjustLoserTree(tmp, loserTree, grpPos, comp, floor((grp + minGrp)/2), minGrp)
		end
	end

	doc [======[
		@name Insert
		@type method
		@desc Insert object into the array
		@format [index, ]object
		@param index
		@param object
		@return nil
	]======]
	function Insert(self, ...)
		if select('#', ...) == 2 then
			local index, value = ...

			if type(index) ~= "number" then
				error("Usage: Array:Insert([index], value) - index must be a number.", 2)
			end

			if value == nil then
				error("Usage: Array:Insert([index], value) - value must not be nil.", 2)
			end

			if index < 1 then
				error("Usage: Array:Insert([index], value) - index must be greater than 0.", 2)
			end

			if index > #self + 1 then index = #self + 1 end

			for i, obj in ipairs(self) do
				if obj == value then
					return i
				end
			end

			if _ArrayInfo[self] and _ArrayInfo[self].IsClass and _ArrayInfo[self].Type then
				if Reflector.ObjectIsClass(value, _ArrayInfo[self].Type) then
					for _, sc in ipairs(Reflector.GetEvents(_ArrayInfo[self].Type)) do
						if _ArrayInfo[self]["_ArrayActive_" .. sc] then
							Reflector.ActiveThread(value, sc)
						end
						if _ArrayInfo[self]["_ArrayBlock_" .. sc] then
							Reflector.BlockEvent(value, sc)
						end

						if _ArrayInfo[self][sc] then
							value[sc] = _ArrayInfo[self][sc]
						end
					end
				else
					error(("Usage: Array:Insert([index], value) - value must be %s."):format(Reflector.GetFullName(_ArrayInfo[self].Type)), 2)
				end
			elseif _ArrayInfo[self] and _ArrayInfo[self].IsStruct and _ArrayInfo[self].Type then
				value = Reflector.Validate(_ArrayInfo[self].Type, value, "value", "Usage: Array:Insert([index], value) - ")
			end

			tinsert(self, index, value)

			return index
		elseif select('#', ...) == 1 then
			local value = ...

			if _ArrayInfo[self] and _ArrayInfo[self].IsClass and _ArrayInfo[self].Type then
				if Reflector.ObjectIsClass(value, _ArrayInfo[self].Type) then
					for _, sc in ipairs(Reflector.GetEvents(_ArrayInfo[self].Type)) do
						if _ArrayInfo[self]["_ArrayActive_" .. sc] then
							Reflector.ActiveThread(value, sc)
						end
						if _ArrayInfo[self]["_ArrayBlock_" .. sc] then
							Reflector.BlockEvent(value, sc)
						end

						if _ArrayInfo[self][sc] then
							value[sc] = _ArrayInfo[self][sc]
						end
					end
				else
					error(("Usage: Array:Insert([index], value) - value must be %s."):format(Reflector.GetFullName(_ArrayInfo[self].Type)), 2)
				end
			elseif _ArrayInfo[self] and _ArrayInfo[self].IsStruct and _ArrayInfo[self].Type then
				value = Reflector.Validate(_ArrayInfo[self].Type, value, "value", "Usage: Array:Insert([index], value) - ")
			end

			tinsert(self, value)

			return #self
		else
			error("Usage: Array:Insert([index], value)", 2)
		end
	end

	doc [======[
		@name Remove
		@type method
		@desc Remove object from array
		@param index|object
		@return object
	]======]
	function Remove(self, index)
		if type(index) ~= "number" then
			for i, ob in ipairs(self) do
				if ob == index then
					index = i
				end
			end

			if type(index) ~= "number" then
				error("Usage: Array:Remove(index) - index must be a number.", 2)
			end
		end

		if not self[index] then
			return
		end

		local value = self[index]

		if _ArrayInfo[self] and _ArrayInfo[self].IsClass and _ArrayInfo[self].Type and Reflector.ObjectIsClass(value, _ArrayInfo[self].Type) then
			for _, sc in ipairs(Reflector.GetEvents(_ArrayInfo[self].Type)) do
				if _ArrayInfo[self]["_ArrayActive_" .. sc] then
					Reflector.InactiveThread(value, sc)
				end
				if _ArrayInfo[self]["_ArrayBlock_" .. sc] then
					Reflector.UnBlockEvent(value, sc)
				end

				if _ArrayInfo[self][sc] then
					value[sc] = nil
				end
			end
		end

		return tremove(self, index)
	end

	doc [======[
		@name HasEvent
		@type method
		@desc Check if the event type is supported by the array's element type
		@param event string, the event's name
		@return boolean true if the array's element's type has the event
	]======]
	function HasEvent(self, key)
		return type(key) == "string" and _ArrayInfo[self] and _ArrayInfo[self].IsClass and Reflector.HasEvent(_ArrayInfo[self].Type, key)
	end

	doc [======[
		@name ActiveThread
		@type method
		@desc Active the thread mode for special event
		@format event[, ...]
		@param event the event name
		@param ... other event's name list
		@return nil
	]======]
	function ActiveThread(self, ...)
		if _ArrayInfo[self] and _ArrayInfo[self].IsClass then
			local cls = _ArrayInfo[self].Type
			local name

			if cls then
				for i = 1, select('#', ...) do
					name = select(i, ...)

					if Reflector.HasEvent(cls, name) then
						_ArrayInfo[self]["_ArrayActive_" .. name] = true

						for _, obj in ipairs(self) do
							if Reflector.ObjectIsClass(obj, cls) then
								Reflector.ActiveThread(obj, name)
							end
						end
					end
				end
			end
		end
	end

	doc [======[
		@name IsThreadActivated
		@type method
		@desc Check if the thread mode is actived for the event
		@param event the event's name
		@return boolean true if the event is in thread mode
	]======]
	function IsThreadActivated(self, sc)
		return type(sc) == "string" and _ArrayInfo[self] and _ArrayInfo[self].IsClass and _ArrayInfo[self]["_ArrayActive_" .. sc] or false
	end

	doc [======[
		@name InactiveThread
		@type method
		@desc Turn off the thread mode for the scipts
		@format event[, ...]
		@param event the event's name
		@param ... other event's name list
		@return nil
	]======]
	function InactiveThread(self, ...)
		if _ArrayInfo[self] and _ArrayInfo[self].IsClass then
			local cls = _ArrayInfo[self].Type
			local name

			if cls then
				for i = 1, select('#', ...) do
					name = select(i, ...)

					if Reflector.HasEvent(cls, name) then
						_ArrayInfo[self]["_ArrayActive_" .. name] = nil

						for _, obj in ipairs(self) do
							if Reflector.ObjectIsClass(obj, cls) then
								Reflector.InactiveThread(obj, name)
							end
						end
					end
				end
			end
		end
	end

	doc [======[
		@name BlockEvent
		@type method
		@desc Block some event for the object
		@format event[, ...]
		@param event the event's name
		@param ... other event's name list
		@return nil
	]======]
	function BlockEvent(self, ...)
		if _ArrayInfo[self] and _ArrayInfo[self].IsClass then
			local cls = _ArrayInfo[self].Type
			local name

			if cls then
				for i = 1, select('#', ...) do
					name = select(i, ...)

					if Reflector.HasEvent(cls, name) then
						_ArrayInfo[self]["_ArrayBlock_" .. name] = true

						for _, obj in ipairs(self) do
							if Reflector.ObjectIsClass(obj, cls) then
								Reflector.BlockEvent(obj, name)
							end
						end
					end
				end
			end
		end
	end

	doc [======[
		@name IsEventBlocked
		@type method
		@desc Check if the event is blocked for the object
		@param event the event's name
		@return boolean true if th event is blocked
	]======]
	function IsEventBlocked(self, sc)
		return type(sc) == "string" and _ArrayInfo[self] and _ArrayInfo[self].IsClass and _ArrayInfo[self]["_ArrayBlock_" .. sc] or false
	end

	doc [======[
		@name UnBlockEvent
		@type method
		@desc Un-Block some events for the object
		@format event[, ...]
		@param event the event's name
		@param ... other event's name list
		@return nil
	]======]
	function UnBlockEvent(self, ...)
		if _ArrayInfo[self] and _ArrayInfo[self].IsClass then
			local cls = _ArrayInfo[self].Type
			local name

			if cls then
				for i = 1, select('#', ...) do
					name = select(i, ...)

					if Reflector.HasEvent(cls, name) then
						_ArrayInfo[self]["_ArrayBlock_" .. name] = nil

						for _, obj in ipairs(self) do
							if Reflector.ObjectIsClass(obj, cls) then
								Reflector.UnBlockEvent(obj, name)
							end
						end
					end
				end
			end
		end
	end

	doc [======[
		@name Push
		@type method
		@desc add object into Array's end
		@format object[, ...]
		@param object
		@param ... other objects
		@return nil
	]======]
	function Push(self, ...)
		for i = 1, select('#', ...) do
			self:Insert(select(i, ...))
		end
	end

	doc [======[
		@name Pop
		@type method
		@desc Remove and return the Array's last object
		@return object
	]======]
	function Pop(self)
		local value = self[#self]

		if value then
			self:Remove(#self)

			return value
		end
	end

	doc [======[
		@name Unshift
		@type method
		@desc Add value into the Array's first position
		@format object[, ...]
		@param object
		@param ... other objects
		@return nil
	]======]
	function Unshift(self, ...)
		for i = select('#', ...), 1, -1 do
			self:Insert(1, select(i, ...))
		end
	end

	doc [======[
		@name Shift
		@type method
		@desc Remove and return the Array's first element
		@return object
	]======]
	function Shift(self)
		local value = self[1]

		if value then
			self:Remove(1)

			return value
		end
	end

	doc [======[
		@name Next
		@type method
		@desc Get the next element, used for IFIterator operation
		@param key
		@return iterator
		@return array
		@return nextkey
	]======]
	function Next(self, key)
		return ipairs(self), self, tonumber(key) or 0
	end

	doc [======[
		@name Contain
		@type method
		@desc Check if the array contains the object
		@param object
		@return boolean true if the array contains the object
	]======]
	function Contain(self, item)
		if type(item) then
			for i, ob in ipairs(self) do
				if ob == item then
					return true
				end
			end
			return false
		end
	end

	------------------------------------------------------
	-- Property
	------------------------------------------------------
	property "Count" {
		Get = function(self)
			return #self
		end,
	}

	property "Type" {
		Get = function(self)
			return _ArrayInfo[self] and _ArrayInfo[self].Type
		end,
	}

	------------------------------------------------------
	-- Constructor
	------------------------------------------------------
	function Array(self, cls)
		if type(cls) == "string" then
			cls = Reflector.ForName(cls)
		end

		if cls and Reflector.IsClass(cls) then
			_ArrayInfo[self] = {
				Type = cls,
				IsClass = true,
			}
		elseif cls and Reflector.IsStruct(cls) then
			_ArrayInfo[self] = {
				Type = cls,
				IsStruct = true,
			}
		end
	end

	------------------------------------------------------
	-- Exist checking
	------------------------------------------------------

	------------------------------------------------------
	-- __index for class instance
	------------------------------------------------------
	function __index(self, key)
		if type(key) == "string" and _ArrayInfo[self] and _ArrayInfo[self].IsClass and Reflector.HasEvent(_ArrayInfo[self].Type, key) then
			return _ArrayInfo[self]["_ArrayEvent_"..key]
		end
	end

	------------------------------------------------------
	-- __newindex for class instance
	------------------------------------------------------
	function __newindex(self, key, value)
		if type(key) == "string" and _ArrayInfo[self] and _ArrayInfo[self].IsClass and Reflector.HasEvent(_ArrayInfo[self].Type, key) then
			if value == nil or type(value) == "function" then
				_ArrayInfo[self]["_ArrayEvent_"..key] = value

				_ArrayInfo[self][key] = value and function(obj, ...)
					for i = 1, #self do
						if rawget(self, i) == obj then
							return value(self, i, ...)
						end
					end
				end

				for _, obj in ipairs(self) do
					if Reflector.ObjectIsClass(obj, _ArrayInfo[self].Type) then
						obj[key] = _ArrayInfo[self][key]
					end
				end
			else
				error(("The %s is the event name of this Array's elements, it's value must be nil or a function."):format(key), 2)
			end
		elseif type(key) == "number" then
			error("Use Array:Insert(index, obj) | Array:Remove(index) to modify this array.", 2)
		end

		return rawset(self, key, value)
	end

	------------------------------------------------------
	-- __call for class instance
	------------------------------------------------------
endclass "Array"