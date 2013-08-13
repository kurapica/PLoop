-- Author      : Kurapica
-- Create Date : 2012/08/10
-- ChangeLog   :

Module "System.IFIterator" "1.0.0"

namespace "System"

interface "IFIterator"

	doc [======[
		@name IFIterator
		@type interface
		@desc The IFiterator interface provide objrect Each, EachK method to help itertor object's element.
		@overridable Next method return itertor, itertor object, first key to help traverse elements
	]======]

	local function SetObjectProperty(self, prop, value)
		self[prop] = value
	end

	------------------------------------------------------
	-- Method
	------------------------------------------------------
	doc [======[
		@name Next
		@type method
		@desc return the itertor function, itertor object, first key to help traverse elements
		@param key
		@return itertor
		@return self
		@return firstkey
	]======]
	function Next(self, key)
		return next, self, key and self[key] ~= nil and key or nil
	end

	doc [======[
		@name EachK
		@type method
		@desc Traverse the object's elements to perform operation
		@format fisrtkey, method[, ...]
		@format firstkey, propertyName, propertyValue
		@param firstkey the start index
		@param method function or method name to operation
		@param propertyName property to be set
		@param propertyValue property value
		@return nil
	]======]
	function EachK(self, key, oper, ...)
		if not oper then return end

		local chk, ret

		if type(oper) == "function" then
			-- Using direct
			for _, item in self:Next(key) do
				chk, ret = pcall(oper, item, ...)
				if not chk then
					errorhandler(ret)
				end
			end
		elseif type(oper) == "string" then
			for _, item in self:Next(key) do
				if type(item) == "table" then
					local cls = Object.GetClass(item)

					if cls then
						if type(rawget(item, oper)) == "function" or (rawget(item, oper) == nil and type(cls[oper]) == "function") then
							-- Check method first
							chk, ret = pcall(item[oper], item, ...)
							if not chk then
								errorhandler(ret)
							end
						else
							chk, ret = pcall(SetObjectProperty, item, oper, ...)
							if not chk then
								errorhandler(ret)
							end
						end
					else
						if type(item[oper]) == "function" then
							-- Check method first
							chk, ret = pcall(item[oper], item, ...)
							if not chk then
								errorhandler(ret)
							end
						else
							chk, ret = pcall(SetObjectProperty, item, oper, ...)
							if not chk then
								errorhandler(ret)
							end
						end
					end
				end
			end
		end
	end

	doc [======[
		@name EachK
		@type method
		@desc Traverse the object's all elements to perform operation
		@format method[, ...]
		@format propertyName, propertyValue
		@param method function or method name to operation
		@param propertyName property to be set
		@param propertyValue property value
		@return nil
	]======]
	function Each(self, oper, ...)
		return EachK(self, nil, oper, ...)
	end
endinterface "IFIterator"
