-- Author      : Kurapica
-- Create Date : 2012/08/10
-- ChangeLog   :

_ENV = Module "System.IFIterator" "1.0.1"

namespace "System"

__Doc__[[The IFIterator interface provide Each, EachK method to help itertor object's element]]
interface "IFIterator" (function(_ENV)

	local function SetObjectProperty(self, prop, value)
		self[prop] = value
	end

	------------------------------------------------------
	-- Method
	------------------------------------------------------
	__Doc__[[
		<desc>return the itertor function, itertor object, first key to help traverse elements</desc>
		<param name="key">the init key</param>
		<return>itertor</return>
		<return>self</return>
		<return>firstkey</return>
	]]
	__Optional__()
	function Next(self, key)
		return next, self, key and self[key] ~= nil and key or nil
	end

	__Doc__[[
		<desc>Traverse the object's elements to perform operation</desc>
		<format>fisrtkey, method[, ...]</format>
		<format>firstkey, propertyName, propertyValue</format>
		<param name="firstkey">the start index</param>
		<param name="method">function or method name to operation</param>
		<param name="propertyName">property to be set</param>
		<param name="propertyValue">property value</param>
	]]
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

	__Doc__[[
		<desc>Traverse the object's all elements to perform operation</desc>
		<format>method[, ...]</format>
		<format>propertyName, propertyValue</format>
		<param name="method">function or method name to operation</param>
		<param name="propertyName">property to be set</param>
		<param name="propertyValue">property value</param>
	]]
	function Each(self, oper, ...)
		return EachK(self, nil, oper, ...)
	end
end)
