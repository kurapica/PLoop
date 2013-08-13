 -- Author      : Kurapica
-- Create Date : 2013/08/13
-- ChangeLog   :

Module "System.Threading" "Version 1.0.0"

namespace "System"

create = coroutine.create
resume = coroutine.resume
running = coroutine.running
status = coroutine.status
wrap = coroutine.wrap
yield = coroutine.yield

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

		_Threads = _Threads or setmetatable({}, {__mode = "k"})

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
			if _Threads[self] then
				return resume(_Threads[self], ...)
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
				_Threads[self] = co

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
			local co = _Threads[self]
			return co and (status(co) == "running" or status(co) == "normal") or false
		end

		doc [======[
			@name IsSuspended
			@type method
			@desc Whether the thread is suspended
			@return boolean true if the thread is suspended
		]======]
		function IsSuspended(self)
			return _Threads[self] and status(_Threads[self]) == "suspended" or false
		end

		doc [======[
			@name IsDead
			@type method
			@desc Whether the thread is dead
			@return boolean true if the thread is dead
		]======]
		function IsDead(self)
			return (_Threads[self] == nil) or status(_Threads[self]) == "dead" or false
		end

		------------------------------------------------------
		-- Property
		------------------------------------------------------
		property "Status" {
			Get = function(self)
				if _Threads[self] then
					return status(_Threads[self])
				else
					return "dead"
				end
			end,
			Type = ThreadStatus,
		}

		property "Thread" {
			Get = function(self)
				return _Threads[self]
			end,
			Set = function(self, th)
				if type(th) == "function" then
					_Threads[self] = create(th)
				elseif type(th) == "thread" then
					_Threads[self] = th
				else
					_Threads[self] = _Threads[th]
				end
			end,
			Type = System.Function + System.Thread + System.Threading.Thread + nil,
		}

		------------------------------------------------------
		-- Constructor
		------------------------------------------------------
		function Thread(self, func)
			if type(func) == "function" then
				_Threads[self] = create(func)
			elseif type(func) == "thread" then
				_Threads[self] = func
			end
		end

		------------------------------------------------------
		-- __call for class instance
		------------------------------------------------------
		function __call(self, ...)
			return _Threads[self] and resume(_Threads[self], ...)
		end
	endclass "Thread"
endinterface "Threading"