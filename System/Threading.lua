 -- Author      : Kurapica
-- Create Date : 2013/08/13
-- ChangeLog   :

_ENV = Module "System.Threading" "1.0.2"

namespace "System"

__Doc__[[Used for threading control]]
__Final__()
interface "Threading" (function(_ENV)

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

	__Doc__[[
		<desc>Used to make iterator from functions</desc>
		<param name="func" type="function">the function contains yield instructions</param>
		<usage>
			function a(start, endp)
				for i = start, endp do
				    yield(i, "i_"..i)
				end
			end

			for k, v in Threading.Iterator(a), 1, 3 do print(k, v) end

			-- Oupput
			-- 1       i_1
			-- 2       i_2
			-- 3       i_3
		</usage>
	]]
	function Iterator(func)
		return Reflector.ThreadCall(function()
			local th = ITER_POOL()

			return func( th:Yield( th ) )
		end)
	end

	------------------------------------------------------
	-- System.Threading.Thread
	------------------------------------------------------
	__Doc__[[
		Thread object is used to control lua coroutines.
		Thread object can be created with a default function that will be convert to coroutine, also can create a empty Thread object.
		Thread object can use 'Thread' property to receive function, coroutine, other Thread object as it's	control coroutine.
		Thread object can use 'Resume' method to resume coroutine like 'obj:Resume(arg1, arg2, arg3)'. Also can use 'obj(arg1, arg2, arg3)' for short.
		In the Thread object's controling function, can use the System.Threading's method to control the coroutine.
	]]
	class "Thread" (function(_ENV)

		_MainThread = running()

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
					error(value, 2)
				else
					error(..., 2)
				end
			end
		end

		------------------------------------------------------
		-- Event
		------------------------------------------------------

		------------------------------------------------------
		-- Method
		------------------------------------------------------
		__Doc__[[
			<desc>Resume the thread</desc>
			<param name="...">any arguments passed to the thread</param>
			<return name="..."> any return values from the thread</return>
		]]
		function Resume(self, ...)
			if running() ~= _MainThread then
				self.Thread = running()
				return ...
			elseif self.Thread then
				return chkValue( self, resume(self.Thread, ...) )
			end
		end

		__Doc__[[
			<desc>Yield the thread</desc>
			<param name="...">return arguments</param>
		]]
		function Yield(self, ...)
			local co = running()

			if co ~= _MainThread then
				self.Thread = co

				return yield(...)
			end
		end

		__Doc__[[
			<desc>Whether the thread is running</desc>
			<return type="boolean">true if the thread is running</return>
		]]
		function IsRunning(self)
			local co = self.Thread
			return co and (status(co) == "running" or status(co) == "normal") or false
		end

		__Doc__[[
			<desc>Whether the thread is suspended</desc>
			<return type="boolean">true if the thread is suspended</return>
		]]
		function IsSuspended(self)
			return self.Thread and status(self.Thread) == "suspended" or false
		end

		__Doc__[[
			<desc>Whether the thread is dead</desc>
			<return type="boolean">true if the thread is dead</return>
		]]
		function IsDead(self)
			return not self.Thread or status(self.Thread) == "dead" or false
		end

		------------------------------------------------------
		-- Property
		------------------------------------------------------
		__Doc__[[Get the thread's status]]
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

		__Doc__[[Get the thread object's coroutine or set a new function/coroutine to it]]
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
		}

		------------------------------------------------------
		-- Constructor
		------------------------------------------------------
		__Doc__[[
			<param name="func" type="function|thread" optional="true">The init function or thread</param>
		]]
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
	end)
end)

------------------------------------------------------
-- Global settings
------------------------------------------------------
_G.tpairs = _G.tpairs or Threading.Iterator
