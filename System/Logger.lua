--===========================================================================--
--                                                                           --
--                               System.Logger                               --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2011/02/28                                               --
-- Update Date  :   2018/03/15                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--
PLoop(function(_ENV)
    namespace "System"

    --- Logger is used to keep and distribute log message.
    -- Logger object can use 'logObject(logLevel, logMessage, ...)' for short to send out log messages.
    __Sealed__()
    class "Logger" (function(_ENV)

        export {
            type                = type,
            error               = error,
            select              = select,
            pairs               = pairs,
            strformat           = string.format,
            tblconcat           = table.concat,
        }

        export { Logger }

        --- Represents the log levels
        __Sealed__() __AutoIndex__()
        enum "LogLevel" { "Trace", "Debug", "Info", "Warn", "Error", "Fatal" }

        local date              = _G.os and os.date or _G.date

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- log out message for log level
        -- @format  (logLevel, message[, ...])
        -- @param   logLevel                the message's log level, if lower than object.LogLevel, the message will be discarded
        -- @param   message                 the send out message, can be a formatted string
        -- @param   ...                     the list values to be included into the formatted string
        __Arguments__{ LogLevel, String, Variable.Rest(String) }
        function Log(self, logLvl, msg, ...)
            if logLvl >= self.LogLevel then
                -- Prefix and TimeStamp
                local tfmt      = self.TimeFormat
                self[1]         = tfmt and date and date(tfmt) or ""
                self[2]         = self.__Prefix[logLvl] or ""
                self[3]         = select("#", ...) > 0 and strformat(msg, ...) or msg

                msg             = tblconcat(self)

                -- Send message to handlers
                for handler, lvl in pairs(self.__Handler) do
                    if lvl == true or lvl == logLvl then
                        pcall(handler, msg)
                    end
                end
            end
        end

        --- Add a log handler, when Logger object send out log messages, the handler will receive the message as it's first argument
        -- @format  (handler[, loglvl])
        -- @param   handler                 the log handler
        -- @param   loglvl                  the handler only receive this level's message if setted, or receive all level's message if keep nil
        __Arguments__{ Callable, Variable.Optional(LogLevel) }
        function AddHandler(self, handler, loglevel)
            if not self.__Handler[handler] then
                self.__Handler[handler] = loglevel or true
            end
        end

        --- Remove a log handler
        -- @param   handler                 the log handler to be removed
        __Arguments__{ Callable }
        function RemoveHandler(self, handler)
            if self.__Handler[handler] then
                self.__Handler[handler] = nil
            end
        end

        --- Set a prefix for a log level, thre prefix will be added to the message when the message is with the same log level
        -- @param   logLeve                 the log level
        -- @param   prefix                  the prefix string
        -- @param   createMethod            if true, will return a function to be called as Log function
        -- @usage   Info = object:SetPrefix(LogLevel.Info, "[Info]", true)
        --
        --          -- Then you can use Info function to output log message with Info log level
        --          Info("This is a test message") -- log out '[Info]This is a test message'
        __Arguments__{ LogLevel, Variable.Optional(String), Variable.Optional(Boolean) }
        function SetPrefix(self, loglvl, prefix, createMethod)
            self.__Prefix[loglvl] = prefix

            -- Register
            if createMethod then
                return function(msg, ...) if loglvl >= self.LogLevel then return self(loglvl, msg, ...) end end
            end
        end

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- the log level
        property "LogLevel"     { type = LogLevel }

        --- if the timeformat is setted, the log message will add a timestamp at the header
        property "TimeFormat"   { type = TimeFormat, default = "[%c]" }

        --- The system default logger
        __Static__()
        property "Default"      { set = false, default = function() return Logger() end }

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        function __new() return { __Handler = {}, __Prefix  = {} } end

        -----------------------------------------------------------
        --                      meta-method                      --
        -----------------------------------------------------------
        __call = Log
    end)

    -----------------------------------------------------------
    --                  the default logger                   --
    -----------------------------------------------------------
    Logger.Default:SetPrefix(Logger.LogLevel.Trace, "[Trace]")
    Logger.Default:SetPrefix(Logger.LogLevel.Debug, "[Debug]")
    Logger.Default:SetPrefix(Logger.LogLevel.Info,  "[Info]")
    Logger.Default:SetPrefix(Logger.LogLevel.Warn,  "[Warn]")
    Logger.Default:SetPrefix(Logger.LogLevel.Error, "[Error]")
    Logger.Default:SetPrefix(Logger.LogLevel.Fatal, "[Fatal]")

    Logger.Default.LogLevel = Logger.LogLevel.Info
end)