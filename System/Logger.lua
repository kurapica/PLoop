-- Author      : Kurapica
-- Create Date : 2011/02/28
-- ChangeLog   :
--				2011/03/17 the msg can be formatted string.
--				2014/03/01 improve the log method

_ENV = Module "System.Logger" "1.0.1"

namespace "System"

__Sealed__()
enum "LogLevel" {
	Trace = 1,
	Debug = 2,
	Info = 3,
	Warn = 4,
	Error = 5,
	Fatal = 6,
}

__Doc__[[
	Logger is used to keep and distribute log message.
	Logger object can use 'logObject(logLevel, logMessage, ...)' for short to send out log messages.
	Logger object also cache the log messages, like use 'logObject[1]' to get the lateset message, 'logObject[2]' to get the previous message, Logger object will cache messages for a count equal to it's MaxLog property value, the MaxLog default value is 1, always can be change.
]]
__Sealed__()
class "Logger" (function(_ENV)
	_Logger = {}

	------------------------------------------------------
	-- Method
	------------------------------------------------------
	__Doc__[[
		<desc>log out message for log level</desc>
		<param name="logLevel">the message's log level, if lower than object.LogLevel, the message will be discarded</param>
		<param name="message">the send out message, can be a formatted string</param>
		<param name="..." optional="true">a list values to be included into the formatted string</param>
	]]
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

			prefix = prefix..(self.Prefix[logLvl] or "")

			if select('#', ...) > 0 then
				msg = msg:format(...)
			end

			msg = prefix..msg

			-- Send message to handlers
			local chk, err

			for handler, lvl in pairs(self.Handler) do
				if lvl == true or lvl == logLvl then
					chk, err = pcall(handler, msg)
					if not chk then
						errorhandler(err)
					end
				end
			end
		end
	end

	__Doc__[[
		<desc>Add a log handler, when Logger object send out log messages, the handler will receive the message as it's first argument</desc>
		<param name="handler" type="function">the log handler</param>
		<param name="logLevel" optional="true">the handler only receive this level's message if setted, or receive all level's message if keep nil</param>
		<return type="nil"></return>
	]]
	__Arguments__{ Callable, Argument(LogLevel, true) }
	function AddHandler(self, handler, loglevel)
		if type(handler) == "function" then
			if not self.Handler[handler] then
				self.Handler[handler] = loglevel and tonumber(loglevel) or true
			end
		else
			error(("Usage : Logger:AddHandler(handler) : 'handler' - function expected, got %s."):format(type(handler)), 2)
		end
	end

	__Doc__[[
		<desc>Remove a log handler</desc>
		<param name="handler" type="function">function, the handler need be removed</param>
	]]
	__Arguments__{ Callable }
	function RemoveHandler(self, handler)
		if type(handler) == "function" then
			if self.Handler[handler] then
				self.Handler[handler] = nil
			end
		else
			error(("Usage : Logger:RemoveHandler(handler) : 'handler' - function expected, got %s."):format(type(handler)), 2)
		end
	end

	__Doc__[[
		<desc>Set a prefix for a log level, thre prefix will be added to the message when the message is with the same log level</desc>
		<param name="logLevel" type="number">the log level</param>
		<param name="prefix" type="string">the prefix string</param>
		<param name="createMethod" optional="true" type="boolean">if true, will return a function to be called as Log function</param>
		<usage>
			Info = object:SetPrefix(2, "[Info]", true)

			-- Then you can use Info function to output log message with 2 log level
			Info("This is a test message") -- log out '[Info]This is a test message'
		</usage>
	]]
	__Arguments__{ LogLevel, Argument(String, true), Argument(Boolean, true) }
	function SetPrefix(self, loglvl, prefix, createMethod)
		if type(prefix) == "string" then
			if not prefix:match("%W+$") then
				prefix = prefix.." "
			end
		else
			prefix = nil
		end
		self.Prefix[loglvl] = prefix

		-- Register
		if createMethod then
			return function(msg, ...)
				if loglvl >= self.LogLevel then
					return self:Log(loglvl, msg, ...)
				end
			end
		end
	end

	------------------------------------------------------
	-- Property
	------------------------------------------------------
	__Doc__[[the log level]]
	property "LogLevel" { Type = LogLevel }

	__Doc__[[
		if the timeformat is setted, the log message will add a timestamp at the header

		Time Format:
		    %a abbreviated weekday name (e.g., Wed)
		    %A full weekday name (e.g., Wednesday)
		    %b abbreviated month name (e.g., Sep)
		    %B full month name (e.g., September)
		    %c date and time (e.g., 09/16/98 23:48:10)
		    %d day of the month (16) [01-31]
		    %H hour, using a 24-hour clock (23) [00-23]
		    %I hour, using a 12-hour clock (11) [01-12]
		    %M minute (48) [00-59]
		    %m month (09) [01-12]
		    %p either "am" or "pm" (pm)
		    %S second (10) [00-61]
		    %w weekday (3) [0-6 = Sunday-Saturday]
		    %x date (e.g., 09/16/98)
		    %X time (e.g., 23:48:10)
		    %Y full year (1998)
		    %y two-digit year (98) [00-99]
	]]
	property "TimeFormat" { Type = String }

	__Doc__[[The system logger]]
	__Static__()
	property "DefaultLogger" { Set = false, Default = function() return Logger("System.Default.Logger") end }

	------------------------------------------------------
	-- Dispose
	------------------------------------------------------
	function Dispose(self)
		_Logger[self.Name] = nil
	end

	------------------------------------------------------
	-- Constructor
	------------------------------------------------------
	__Arguments__{ String }
	function Logger(self, name)
		_Logger[name] = self

		self.Name = name
		self.Handler = {}
		self.Prefix = {}
	end

	------------------------------------------------------
	-- Exist checking
	------------------------------------------------------
	__Arguments__{ String }
	function __exist(name)
		return _Logger[name]
	end

	------------------------------------------------------
	-- __call for class instance
	------------------------------------------------------
	function __call(self, loglvl, msg, ...)
		return self:Log(loglvl, msg, ...)
	end
end)

------------------------------------------------------
-- Set the default logger
------------------------------------------------------
Logger.DefaultLogger.TimeFormat = "%X"

_Parent.Trace = Logger.DefaultLogger:SetPrefix(LogLevel.Trace, "[Trace]", true)
_Parent.Debug = Logger.DefaultLogger:SetPrefix(LogLevel.Debug, "[Debug]", true)
_Parent.Info = Logger.DefaultLogger:SetPrefix(LogLevel.Info, "[Info]", true)
_Parent.Warn = Logger.DefaultLogger:SetPrefix(LogLevel.Warn, "[Warn]", true)
_Parent.Error = Logger.DefaultLogger:SetPrefix(LogLevel.Error, "[Error]", true)
_Parent.Fatal = Logger.DefaultLogger:SetPrefix(LogLevel.Fatal, "[Fatal]", true)

Logger.DefaultLogger.LogLevel = LogLevel.Info