--===========================================================================--
--                                                                           --
--                                System.Net                                 --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2020/08/09                                               --
-- Update Date  :   2020/08/09                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    --- The web namespace
    __Final__() __Sealed__()
    interface "System.Net" (function(_ENV)
        --- Defines constants that are used by the Shutdown method
        __Sealed__()
        enum "SocketShutdown" {
            RECEIVE             = 0,    -- Disables a Socket for receiving
            SEND                = 1,    -- Disables a Socket for sending
            BOTH                = 2,    -- Disables a Socket for both sending and receiving
        }

        --- Define the common Exception types
        __Sealed__()
        class "TimeoutException" { Exception, Message = { type = String, default = "The operation has timed-out" } }

        __Sealed__()
        class "SocketException" { Exception }

        --- The socket interface
        __Sealed__()
        interface "ISocket" (function(_ENV)
            ---------------------------------------------------
            --                   property                    --
            ---------------------------------------------------
            --- Gets or sets a value that specifies the amount of time after which a synchronous Accept call will time out
            __Abstract__() property "AcceptTimeout"     { type = Integer }

            --- Gets or sets a value that specifies the amount of time after which a synchronous Receive call will time out
            __Abstract__() property "ReceiveTimeout"    { type = Integer }

            --- Gets or sets a value that specifies the amount of time after which a synchronous Send call will time out
            __Abstract__() property "SendTimeout"       { type = Integer }

            --- Gets or sets a value that specifies the amount of time after which a synchronous Connect call will time out
            __Abstract__() property "ConnectTimeout"    { type = Integer }

            ---------------------------------------------------
            --                    method                     --
            ---------------------------------------------------
            --- Creates a new Socket for a newly created connection
            __Abstract__() function Accept(self) end

            --- Associates a Socket with a local endpoint
            __Abstract__() function Bind(self, address, port) end

            --- Places a Socket in a listening state
            __Abstract__() function Listen(self, backlog) end

            --- Establishes a connection to a remote host
            __Abstract__() function Connect(self, address, port) end

            --- Closes the Socket connection and releases all associated resources
            __Abstract__() function Close(self) end

            --- Receives data from a bound Socket
            __Abstract__() function Receive(self) end

            --- Sends data to a connected Socket
            __Abstract__() function Send(self, data) end

            --- Disables sends and receives on a Socket
            __Abstract__() function Shutdown(self, socketShutdown) end
        end)

        -----------------------------------------------------------------------------------
        --- The protocol to be used by the Socket object
        -- The protocols are special prototypes, to be created like
        --
        -- System.Net.Protocol "MQTT" { make = function() end, parse = function() end }
        --
        -- So we have System.Net.Protocol.MQTT represents a socket protocol.
        -- The prototype will provide two methods : MakePacket(make), ParsePacket(parse)
        -----------------------------------------------------------------------------------
        local protocol
        local newProtocol       = function (name, settings)
            if type(settings) ~= "table" or type(settings.parse) ~= "function" or type(settings.make) ~= "function" then
                error("Usage: System.Net.Protocol \"name\" { parse = Function, make = Function }", 3)
            end

            if not name:find(".", 1, true) then name = "System.Net.Protocol." .. name end

            if Namespace.GetNamespace(name) then error("The " .. name .. " is already existed", 3) end

            return Namespace.SaveNamespace(name, Prototype {
                __index         = {
                    -- Make the packet data based on the input
                    MakePacket  = settings.make,

                    -- Parse the packet data from the socket
                    ParsePacket = settings.parse,
                },
                __newindex      = Toolset.readonly,
                __tostring      = Namespace.GetNamespaceName,
                __metatable     = protocol,
            })
        end

        local getNamespace      = Namespace.GetNamespace

        local protocolMethods   = {
            ["IsImmutable"]     = function() return true, true end;
            ["ValidateValue"]   = function(_, value) return getmetatable(value) == protocol and value ~= protocol and value end;
            ["Validate"]        = function(value)    return getmetatable(value) == protocol and value ~= protocol and value end;
        }

        protocol                = Prototype (ValidateType, {
            __index             = function(self, key) return protocolMethods[key] or getNamespace(self, key) end,
            __newindex          = Toolset.readonly,
            __call          = function(self, name)
                if type(name) ~= "string" then error("Usage: System.Net.Protocol \"name\" { parse = Function, make = Function }", 2) end
                return function(settings)
                    local coder = newProtocol(name, settings)
                    return coder
                end
            end,
            __tostring          = Namespace.GetNamespaceName,
        })

        --- Represents the protocol
        Namespace.SaveNamespace("System.Net.Protocol", protocol)
    end)
end)
