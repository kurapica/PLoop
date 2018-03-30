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
            rawset              = rawset,
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
        __Arguments__{ LogLevel, String, Variable.Rest() }
        function Log(self, logLvl, msg, ...)
            if logLvl >= self.LogLevel then
                -- Prefix and TimeStamp
                local tfmt      = self.TimeFormat
                msg             = (tfmt and date and date(tfmt) or "") ..
                                    (self.__Prefix[logLvl] or "") ..
                                    (select("#", ...) > 0 and strformat(msg, ...) or msg)

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
        -- @param   logLevel                the log level
        -- @param   prefix                  the prefix string
        __Arguments__{ LogLevel, Variable.Optional(String) }
        function SetPrefix(self, loglvl, prefix)
            self.__Prefix[loglvl] = prefix
            return self[loglvl]
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

        --- get a function for special log level to send the messages
        __Arguments__{ LogLevel }
        function __index(self, loglvl)
            local func = function(msg, ...) if loglvl >= self.LogLevel then return self(loglvl, msg, ...) end end
            rawset(self, loglvl, func)
            return func
        end
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