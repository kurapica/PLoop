 -- Author      : Kurapica
-- Create Date : 2013/08/13
-- ChangeLog   :

Module "System.Threading" "1.0.2"

namespace "System"

interface "Threading"

	doc [======[
		@name Threading
		@type interface
		@desc Used for threading control
	]======]

	enum "ThreadStatus" {
		"running",
		"suspended",
		"normal",
		"dead",
	}

	ITER_POOL_SIZE = 100

	ITER_CACHE = setmetatable({}, { __mode = "k" })
	ITER_POOL = setmetatable({}, {
		__call = function(self, value)
			if value then
				if #self < ITER_POOL_SIZE then
					tinsert(self, value)
					value.Thread = nil
				else
					ITER_CACHE[value] = nil
				end
			else
				value = tremove(self) or Thread()

				if not ITER_CACHE[value] then
					ITER_CACHE[value] = true
				end

				return value
			end
		end,
	})

	------------------------------------------------------
	-- System.Threading.Iterator
	--
	-- Example :
	--
	-- function a(start, endp)
	--   for i = start, endp do
	--     yield(i, "i_"..i)
	--   end
	-- end
	--
	-- for k, v in Threading.Iterator(a, 1, 3) do print(k, v) end
	--
	-- 1       i_1
	-- 2       i_2
	-- 3       i_3
	--
	------------------------------------------------------
	function Iterator(func)
		return Reflector.ThreadCall(function()
			local th = ITER_POOL()

			return func( th:Yield( th ) )
		end)
	end

	------------------------------------------------------
	-- System.Threading.Thread
	------------------------------------------------------
	class "Thread"

		doc [======[
			@name Thread
			@type class
			@format [function]
			@param function the function to be convert to thread
			@desc
					Thread object is used to control lua coroutines.
			<br><br>Thread object can be created with a default function that will be convert to coroutine, also can create a empty Thread object.
			<br><br>Thread object can use 'Thread' property to receive function, coroutine, other Thread object as it's	control coroutine.
			<br><br>Thread object can use 'Resume' method to resume coroutine like 'obj:Resume(arg1, arg2, arg3)'. Also can use 'obj(arg1, arg2, arg3)' for short.
			<br><br>In the Thread object's controling function, can use the System.Threading's method to control the coroutine.
			<br>
		]======]

		local function chkValue(self, flag, ...)
			if flag then
				if ITER_CACHE[self] and select('#', ...) == 0 then
					ITER_POOL(self)
				end
				return ...
			else
				if ITER_CACHE[self]  then
					ITER_POOL(self)
				end

				local value = ...

				if value then
					value = value:match(":%d+:%s*(.-)$") or value

					error(value, 3)
				else
					error(..., 3)
				end
			end
		end

		------------------------------------------------------
		-- Event
		------------------------------------------------------

		------------------------------------------------------
		-- Method
		------------------------------------------------------
		doc [======[
			@name Resume
			@type method
			@desc Resume the thread
			@param ... resume arguments
			@return ... return values from thread
		]======]
		function Resume(self, ...)
			if running() then
				self.Thread = running()
				return ...
			elseif self.Thread then
				return chkValue( self, resume(self.Thread, ...) )
			end
		end

		doc [======[
			@name Yield
			@type method
			@desc Yield the thread
			@param ... return arguments
		]======]
		function Yield(self, ...)
			local co = running()

			if co then
				self.Thread = co

				return yield(...)
			end
		end

		doc [======[
			@name IsRunning
			@type method
			@desc Whether the thread is running
			@return boolean true if the thread is running
		]======]
		function IsRunning(self)
			local co = self.Thread
			return co and (status(co) == "running" or status(co) == "normal") or false
		end

		doc [======[
			@name IsSuspended
			@type method
			@desc Whether the thread is suspended
			@return boolean true if the thread is suspended
		]======]
		function IsSuspended(self)
			return self.Thread and status(self.Thread) == "suspended" or false
		end

		doc [======[
			@name IsDead
			@type method
			@desc Whether the thread is dead
			@return boolean true if the thread is dead
		]======]
		function IsDead(self)
			return not self.Thread or status(self.Thread) == "dead" or false
		end

		------------------------------------------------------
		-- Property
		------------------------------------------------------
		property "Status" {
			Get = function(self)
				if self.Thread then
					return status(self.Thread)
				else
					return "dead"
				end
			end,
			Type = ThreadStatus,
		}

		property "Thread" {
			Field = "__Thread",
			Set = function(self, th)
				if type(th) == "function" then
					self.__Thread = create(th)
				elseif type(th) == "thread" then
					self.__Thread = th
				elseif th then
					self.__Thread = th.Thread
				else
					self.__Thread = nil
				end
			end,
			Type = System.Function + System.Thread + System.Threading.Thread + nil,
		}

		------------------------------------------------------
		-- Constructor
		------------------------------------------------------
		function Thread(self, func)
			if type(func) == "function" then
				self.Thread = create(func)
			elseif type(func) == "thread" then
				self.Thread = func
			end
		end

		------------------------------------------------------
		-- __call for class instance
		------------------------------------------------------
		function __call(self, ...)
			return Resume(self, ...)
		end
	endclass "Thread"
endinterface "Threading"

------------------------------------------------------
-- Global settings
------------------------------------------------------
_G.tpairs = _G.tpairs or Threading.Iterator
