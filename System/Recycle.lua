-- Author      : Kurapica
-- Create Date : 2012/08/31
-- ChangeLog   :

_ENV = Module "System.Recycle" "1.0.0"

namespace "System"

__Doc__[[
	Recycle object is used as an object factory and manager.
	Recycle's constructor receive a class as it's first argument, the class would be used to generate new object to be recycle.
	The other arugments for the constructor is passed to the class's constructor as init arugments, and if one argument is string and containts '%d', the '%d' will be converted to the factory index.The factory index in alwasy increased by 1 when a new object is created.
	After the recycle object is created as recycleObject, can use 'recycleObject()' to get an un-used object, and use 'recycleObject(object)' to put no-use object back for another query.
]]
class "Recycle" (function(_ENV)
	------------------------------------------------------
	-- Event
	------------------------------------------------------
	__Doc__[[
		<desc>Fired when an no-used object is put in</desc>
		<param name="object">no-used object</param>
	]]
	event "OnPush"

	__Doc__[[
		<desc>Fired when an un-used object is send out</desc>
		<param name="object">send-out object</param>
	]]
	event "OnPop"

	__Doc__[[
		<desc>Fired when a new object is created</desc>
		<param name="object">the new object</param>
	]]
	event "OnInit"

	local function parseArgs(self)
		if not self.Arguments then return end

		local index = (self.Index or 0) + 1
		self.Index = index

		self.__NowArgs = self.__NowArgs or {}

		for i, arg in ipairs(self.Arguments) do
			if type(arg) == "string" and arg:find("%%d") then
				arg = arg:format(index)
			end

			self.__NowArgs[i] = arg
		end

		return unpack(self.__NowArgs)
	end

	------------------------------------------------------
	-- Method
	------------------------------------------------------
	__Doc__[[
		<desc>Push object in recycle bin</desc>
		<param name="object">the object that put in</param>
	]]
	function Push(self, obj)
		if obj then
			-- Won't check obj because using cache means want quick-using.
			tinsert(self, obj)

			return OnPush(self, obj)
		end
	end

	__Doc__[[
		<desc>Pop object from recycle bin</desc>
		<return name="object">the object that pop out</return>
	]]
	function Pop(self)
		-- give out item
		if #self > 0 then
			local ret = tremove(self, #self)

			OnPop(self, ret)

			return ret
		end

		-- create new
		if not self.Type then
			local ret = {}

			OnPop(self, ret)

			return ret
		else
			local obj = self.Type(parseArgs(self))

			OnInit(self, obj)

			OnPop(self, obj)

			return obj
		end
	end

	------------------------------------------------------
	-- Property
	------------------------------------------------------

	------------------------------------------------------
	-- Constructor
	------------------------------------------------------
	__Doc__ [[
		<param name="class" type="class">the class used to generate objects</param>
		<param name="...">the arguments that transform to the class's constructor</param>
	]]
    function Recycle(self, cls, ...)
		if type(cls) == "string" then cls = Reflector.GetNameSpaceForName(cls) end

		if cls and (Reflector.IsClass(cls) or Reflector.IsStruct(cls)) then
			self.Type = cls
			self.Arguments = select('#', ...) > 0 and {...}
		end
    end

	------------------------------------------------------
	-- __call
	------------------------------------------------------
	function __call(self, obj)
		if obj then
			return Push(self, obj)
		else
			return Pop(self)
		end
	end
end)