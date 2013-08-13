-- Author      : Kurapica
-- Create Date : 2011/02/28
-- ChangeLog   :
--				2011/03/17	the msg can be formatted string.

Module "System.Logger" "1.0.0"

namespace "System"

class "Logger"
	inherit "Object"

	doc [======[
		@name Logger
		@type class
		@param name the Logger's name, must be an unique string
		@desc Logger is used to keep and distribute log message.
		<br><br>Logger object can use 'logObject(logLevel, logMessage, ...)' for short to send out log messages.
		<br><br>Logger object also cache the log messages, like use 'logObject[1]' to get the lateset message, 'logObject[2]' to get the previous message, Logger object will cache messages for a count equal to it's MaxLog property value, the MaxLog default value is 1, always can be change.
		<br>
	]======]

	_Logger = _Logger or {}
	_Info = _Info or setmetatable({}, {__mode = "k"})

	------------------------------------------------------
	-- Event
	------------------------------------------------------

	------------------------------------------------------
	-- Method
	------------------------------------------------------
	doc [======[
		@name Log
		@type method
		@desc log out message for log level
		@format logLevel, message[, ...]
		@param logLevel the message's log level, if lower than object.LogLevel, the message will be discarded
		@param message the send out message, can be a formatted string
		@param ... a list values to be included into the formatted string
		@return nil
	]======]
	function Log(self, logLvl, msg, ...)
		if type(logLvl) ~= "number" then
			error(("Usage Logger:Log(logLvl, msg, ...) : logLvl - number expected, got %s."):format(type(logLvl)), 2)
		end

		if type(msg) ~= "string" then
			error(("Usage Logger:Log(logLvl, msg, ...) : msg - string expected, got %s."):format(type(msg)), 2)
		end

		if logLvl >= self.LogLevel then
			-- Prefix and TimeStamp
			local prefix = self.TimeFormat and date(self.TimeFormat)

			if not prefix or type(prefix) ~= "string" then
				prefix = ""
			end

			if prefix ~= "" and not strmatch(prefix, "^%[.*%]$") then
				prefix = "["..prefix.."]"
			end

			prefix = prefix..(_Info[self].Prefix[logLvl] or "")

			if select('#', ...) > 0 then
				msg = msg:format(...)
			end

			msg = prefix..msg

			-- Save message to pool
			local pool = _Info[self].Pool
			pool[pool.EndLog] = msg
			pool.EndLog = pool.EndLog + 1

			-- Remove old message
			while pool.EndLog - pool.StartLog - 1 > self.MaxLog do
				pool.StartLog = pool.StartLog + 1
				pool[pool.StartLog] = nil
			end

			-- Send message to handlers
			local chk, err

			for handler, lvl in pairs(_Info[self].Handler) do
				if lvl == true or lvl == logLvl then
					chk, err = pcall(handler, msg)
					if not chk then
						errorhandler(err)
					end
				end
			end
		end
	end

	doc [======[
		@name AddHandler
		@type method
		@desc Add a log handler, when Logger object send out log messages, the handler will receive the message as it's first argument
		@format handler[, logLevel]
		@param handler function, the log handler
		@param logLevel the handler only receive this level's message if setted, or receive all level's message if keep nil
		@return nil
	]======]
	function AddHandler(self, handler, loglevel)
		if type(handler) == "function" then
			if not _Info[self].Handler[handler] then
				_Info[self].Handler[handler] = loglevel and tonumber(loglevel) or true
			end
		else
			error(("Usage : Logger:AddHandler(handler) : 'handler' - function expected, got %s."):format(type(handler)), 2)
		end
	end

	doc [======[
		@name RemoveHandler
		@type method
		@desc Remove a log handler
		@param handler function, the handler need be removed
		@return nil
	]======]
	function RemoveHandler(self, handler)
		if type(handler) == "function" then
			if _Info[self].Handler[handler] then
				_Info[self].Handler[handler] = nil
			end
		else
			error(("Usage : Logger:RemoveHandler(handler) : 'handler' - function expected, got %s."):format(type(handler)), 2)
		end
	end

	------------------------------------
	--- Set a prefix for a log level, the prefix will be added to the message when the message is that log level.
	-- @name Logger:SetPrefix
	-- @class function
	-- @param logLevel the log message's level
	-- @param prefix the prefix string
	-- @param [method] method name
	-- @return nil
	-- @usage Logger:SetPrefix(1, "[DEBUG]") -- this would print the message out to the ChatFrame
	------------------------------------
	doc [======[
		@name SetPrefix
		@type method
		@desc Set a prefix for a log level, thre prefix will be added to the message when the message is with the same log level
		@param logLevel, prefix[, methodname]
		@param logLevel the log level
		@param prefix string, the prefix string
		@param methodname string, if not nil, will place a function with the methodname to be called as Log function
		@return nil
		@usage object:SetPrefix(2, "[Info]", "Info")
		<br><br>-- Then you can use Info function to output log message with 2 log level
		<br><br>Info("This is a test message") -- log out '[Info]This is a test message'
	]======]
	function SetPrefix(self, loglvl, prefix, method)
		if type(prefix) == "string" then
			if not prefix:match("%W+$") then
				prefix = prefix.." "
			end
		else
			prefix = nil
		end
		_Info[self].Prefix[loglvl] = prefix

		-- Register
		if type(method) == "string" then
			local fenv = getfenv(2)

			if not fenv[method] then
				fenv[method] = function(msg)
					return self:Log(loglvl, msg)
				end
			end
		end
	end

	------------------------------------------------------
	-- Property
	------------------------------------------------------
	property "LogLevel" {
		Set = function(self, lvl)
			if lvl < 0 then lvl = 0 end

			_Info[self].LogLevel = floor(lvl)
		end,
		Get = function(self)
			return _Info[self].LogLevel or 0
		end,
		Type = Number,
	}

	property "MaxLog" {
		Set = function(self, maxv)
			if maxv < 1 then maxv = 1 end

			maxv = floor(maxv)

			_Info[self].MaxLog = maxv

			local pool = _Info[self].Pool

			while pool.EndLog - pool.StartLog - 1 > maxv do
				pool.StartLog = pool.StartLog + 1
				pool[pool.StartLog] = nil
			end
		end,
		Get = function(self)
			return _Info[self].MaxLog or 1
		end,
		Type = Number,
	}

	doc [======[
		@name TimeFormat
		@type property
		@desc if the timeformat is setted, the log message will add a timestamp at the header
		<br>Time Format:
		<br>    %a abbreviated weekday name (e.g., Wed)
		<br>    %A full weekday name (e.g., Wednesday)
		<br>    %b abbreviated month name (e.g., Sep)
		<br>    %B full month name (e.g., September)
		<br>    %c date and time (e.g., 09/16/98 23:48:10)
		<br>    %d day of the month (16) [01-31]
		<br>    %H hour, using a 24-hour clock (23) [00-23]
		<br>    %I hour, using a 12-hour clock (11) [01-12]
		<br>    %M minute (48) [00-59]
		<br>    %m month (09) [01-12]
		<br>    %p either "am" or "pm" (pm)
		<br>    %S second (10) [00-61]
		<br>    %w weekday (3) [0-6 = Sunday-Saturday]
		<br>    %x date (e.g., 09/16/98)
		<br>    %X time (e.g., 23:48:10)
		<br>    %Y full year (1998)
		<br>    %y two-digit year (98) [00-99]
	]======]
	property "TimeFormat" {
		Set = function(self, timeFormat)
			if timeFormat and type(timeFormat) == "string" and timeFormat ~= "*t" then
				_Info[self].TimeFormat = timeFormat
			else
				_Info[self].TimeFormat = nil
			end
		end,
		Get = function(self)
			return _Info[self].TimeFormat
		end,
		Type = String + nil,
	}

	------------------------------------------------------
	-- Dispose
	------------------------------------------------------
	function Dispose(self)
		_Logger[_Info[self].Name] = nil
		_Info[self] = nil
	end

	------------------------------------------------------
	-- Constructor
	------------------------------------------------------
	function Logger(self, name)
		if type(name) ~= "string" then
			error(("Usage : Logger(name) : 'name' - string expected, got %s."):format(type(name)), 2)
		end

		name = name:match("[_%w]+")

		if not name or name == "" then return end

		_Logger[name] = self

		_Info[self] = {
			Owner = self,
			Name = name,
			Pool = {["StartLog"] = 0, ["EndLog"] = 1},
			Handler = {},
			Prefix = {},
		}
	end

	------------------------------------------------------
	-- Exist checking
	------------------------------------------------------
	function __exist(name)
		if type(name) ~= "string" then
			return
		end

		name = name:match("[_%w]+")

		return name and _Logger[name]
	end

	------------------------------------------------------
	-- __index for class instance
	------------------------------------------------------
	function __index(self, key)
		if type(key) == "number" and key >= 1 then
			key = floor(key)

			return _Info[self].Pool[_Info[self].Pool.EndLog - key]
		end
	end

	------------------------------------------------------
	-- __newindex for class instance
	------------------------------------------------------
	function __newindex(self, key, value)
		-- nothing to do
		error("a logger is readonly.", 2)
	end

	------------------------------------------------------
	-- __len for class instance
	------------------------------------------------------
	function __len(self)
		return _Info[self].Pool.EndLog - _Info[self].Pool.StartLog - 1
	end

	------------------------------------------------------
	-- __call for class instance
	------------------------------------------------------
	function __call(self, loglvl, msg, ...)
		return self:Log(loglvl, msg, ...)
	end
endclass "Logger"
