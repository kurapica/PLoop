-- Author      : Kurapica
-- Create Date : 2012/08/31
-- ChangeLog   :

Module "System.Recycle" "Version 1.0.0"

namespace "System"

class "Recycle"
	inherit "Object"

	_RecycleInfo = _RecycleInfo or setmetatable({}, {__mode = "k",})

	doc [======[
		@name Recycle
		@type class
		@param class the class used to generate objects
		@param ... the arguments that transform to the class's constructor
		@desc
				Recycle object is used as an object factory and manager.
		<br><br>Recycle's constructor receive a class as it's first argument, the class would be used to generate new object to be recycle.
		<br><br>The other arugments for the constructor is passed to the class's constructor as init arugments, and if one argument is string and containts '%d', the '%d' will be converted to the factory index.The factory index in alwasy increased by 1 when a new object is created.
		<br><br>After the recycle object is created as recycleObject, can use 'recycleObject()' to get an un-used object, and use 'recycleObject(object)' to put no-use object back for another query.
		<br>
	]======]

	------------------------------------------------------
	-- Event
	------------------------------------------------------
	doc [======[
		@name OnPush
		@type event
		@desc Fired when an no-used object is put in
		@param object no-used object
	]======]
	event "OnPush"

	doc [======[
		@name OnPop
		@type event
		@desc Fired when an un-used object is send out
		@param object send-out object
	]======]
	event "OnPop"

	doc [======[
		@name OnInit
		@type event
		@desc Fired when a new object is created
		@param object the new object
	]======]
	event "OnInit"

	_Args = {}
	local function parseArgs(self)
		if not _RecycleInfo[self] or not _RecycleInfo[self].Args then
			return
		end

		local index = _RecycleInfo[self].Index or 1
		_RecycleInfo[self].Index = index + 1

		wipe(_Args)

		for _, arg in ipairs(_RecycleInfo[self].Args) do
			if type(arg) == "string" and arg:find("%%d") then
				arg = arg:format(index)
			end

			tinsert(_Args, arg)
		end

		return unpack(_Args)
	end

	------------------------------------------------------
	-- Method
	------------------------------------------------------
	doc [======[
		@name Push
		@type method
		@desc Push object in recycle bin
		@param object
		@return nil
	]======]
	function Push(self, obj)
		if obj then
			-- Won't check obj because using cache means want quick-using.
			tinsert(self, obj)
			if _RecycleInfo[self] then
				return self:Fire("OnPush", obj)
			end
		end
	end

	doc [======[
		@name Pop
		@type method
		@desc Pop object from recycle bin
		@return object
	]======]
	function Pop(self)
		-- give out item
		if #self > 0 then
			if _RecycleInfo[self] then
				self:Fire("OnPop", self[#self])
			end
			return tremove(self, #self)
		end

		-- create new
		if not _RecycleInfo[self] then
			return {}
		else
			local obj = _RecycleInfo[self].Type(parseArgs(self))

			self:Fire("OnInit", obj)

			self:Fire("OnPop", obj)

			return obj
		end
	end

	------------------------------------------------------
	-- Property
	------------------------------------------------------

	------------------------------------------------------
	-- Constructor
	------------------------------------------------------
    function Recycle(self, cls, ...)
		if type(cls) == "string" then
			cls = Reflector.ForName(cls)
		end

		if cls and Reflector.IsClass(cls) then
			_RecycleInfo[self] = {
				Type = cls,
				Args = select('#', ...) > 0 and {...},
			}
		elseif cls and Reflector.IsStruct(cls) then
			_RecycleInfo[self] = {
				Type = cls,
				Args = select('#', ...) > 0 and {...},
			}
		end
    end

	------------------------------------------------------
	-- __call
	------------------------------------------------------
	function __call(self, obj)
		if obj then
			Push(self, obj)
		else
			return Pop(self)
		end
	end
endclass "Recycle"