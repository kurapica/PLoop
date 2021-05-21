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
    namespace "System.Net"

    --- Specifies the protocols that the Socket class supports, for simple only two protocol type now.
    __Sealed__()
    enum "ProtocolType" {
        TCP                     = 6,    -- Transmission Control Protocol
        UDP                     = 17,   -- User Datagram Protocol
    }

    --- Defines constants that are used by the Shutdown method
    __Sealed__()
    enum "SocketShutdown" {
        RECEIVE                 = 0,    -- Disables a Socket for receiving
        SEND                    = 1,    -- Disables a Socket for sending
        BOTH                    = 2,    -- Disables a Socket for both sending and receiving
    }


    --- Define the common Exception types
    __Sealed__()
    class "TimeoutException"    { Exception, Message = { type = String, default = "The operation has timed out" } }

    __Sealed__()
    class "SocketException"     { Exception }

    __Sealed__()
    class "ProtocolException"   { SocketException, Message = { type = String, default = "The protocol is unsupported" } }

    __Sealed__()
    struct "LingerOption"       {
        { name = "Enabled",    type = Boolean, require = true }, -- whether to linger after the Socket is closed
        { name = "LingerTime", type = Number,  require = true }, -- the amount of time to remain connected after calling the Close() method if data remains to be sent.
    }

    --- The socket interface
    __Sealed__()
    interface "ISocket" (function(_ENV)
        export { "throw", ProtocolException }

        local function throwProtocolException()
            throw(ProtocolException())
        end

        ---------------------------------------------------
        --                   property                    --
        ---------------------------------------------------
        --- Gets or sets a value that specifies the amount of time after which a synchronous Accept call will time out(in seconds)
        __Abstract__() property "AcceptTimeout"     { type = Number }

        --- Gets or sets a value that specifies the amount of time after which a synchronous Receive call will time out(in seconds)
        __Abstract__() property "ReceiveTimeout"    { type = Number }

        --- Gets or sets a value that specifies the amount of time after which a synchronous Send call will time out(in seconds)
        __Abstract__() property "SendTimeout"       { type = Number }

        --- Gets or sets a value that specifies the amount of time after which a synchronous Connect call will time out(in seconds)
        __Abstract__() property "ConnectTimeout"    { type = Number }

        --- Gets or sets a Boolean value that specifies whether the Socket can send or receive broadcast packets
        __Abstract__() property "EnableBroadcast"   { type = Boolean, set = throwProtocolException }

        --- Gets a value that indicates whether a Socket is connected to a remote host as of the last Send or Receive operation.
        __Abstract__() property "Connected"         { type = Boolean }

        --- Gets or sets a value that specifies whether the Socket will delay closing a socket in an attempt to send all pending data.
        __Abstract__() property "LingerState"       { type = LingerOption, set = throwProtocolException  }

        --- Gets or sets a Boolean value that specifies whether the stream Socket is using the Nagle algorithm.
        __Abstract__() property "NoDelay"           { type = Boolean, set = throwProtocolException  }

        --- Gets the protocol type of the Socket.
        __Abstract__() property "ProtocolType"      { type = ProtocolType }

        ---------------------------------------------------
        --                    method                     --
        ---------------------------------------------------
        --- Creates a new Socket for a newly created connection
        __Abstract__() Accept           = throwProtocolException

        --- Associates a Socket with a local endpoint
        __Abstract__() Bind             = throwProtocolException

        --- Places a Socket in a listening state
        __Abstract__() Listen           = throwProtocolException

        --- Establishes a connection to a remote host
        __Abstract__() Connect          = throwProtocolException

        --- Receives data from a bound Socket
        __Abstract__() Receive          = throwProtocolException

        --- Receives data from an endpoint
        __Abstract__() ReceiveFrom      = throwProtocolException

        --- Sends data to a connected Socket
        __Abstract__() Send             = throwProtocolException

        --- Sends data to the specified endpoint.
        __Abstract__() SendTo           = throwProtocolException

        --- Disables sends and receives on a Socket
        __Abstract__() Shutdown         = throwProtocolException

        --- Closes the socket connection and allows reuse of the socket.
        __Abstract__() Disconnect       = throwProtocolException

        --- Closes the Socket connection and releases all associated resources
        __Abstract__() Close            = throwProtocolException
    end)

    -----------------------------------------------------------------------------------
    --- The protocol based on the Scoket
    -- The protocols are special prototypes, to be created like
    --
    -- System.Net.Protocol "MQTT" { make = function() end, parse = function() end }
    --
    -- So we have System.Net.Protocol.MQTT represents a socket protocol.
    -- The prototype will provide two methods : MakePacket(make), ParsePacket(parse)
    -----------------------------------------------------------------------------------
    local protocol
    local newProtocol           = function (name, settings)
        if type(settings) ~= "table" or type(settings.parse) ~= "function" or type(settings.make) ~= "function" then
            error("Usage: System.Net.Protocol \"name\" { parse = Function, make = Function }", 3)
        end

        if not name:find(".", 1, true) then name = "System.Net.Protocol." .. name end

        if Namespace.GetNamespace(name) then error("The " .. name .. " is already existed", 3) end

        return Namespace.SaveNamespace(name, Prototype {
            __index             = {
                -- Make the packet data based on the input
                MakePacket      = settings.make,

                -- Parse the packet data from the socket
                ParsePacket     = settings.parse,
            },
            __newindex          = Toolset.readonly,
            __tostring          = Namespace.GetNamespaceName,
            __metatable         = protocol,
        })
    end

    local getNamespace          = Namespace.GetNamespace

    local protocolMethods       = {
        ["IsImmutable"]         = function() return true, true end;
        ["ValidateValue"]       = function(_, value) return getmetatable(value) == protocol and value ~= protocol and value end;
        ["Validate"]            = function(value)    return getmetatable(value) == protocol and value ~= protocol and value end;
    }

    protocol                    = Prototype (ValidateType, {
        __index                 = function(self, key) return protocolMethods[key] or getNamespace(self, key) end,
        __newindex              = Toolset.readonly,
        __call          = function(self, name)
            if type(name) ~= "string" then error("Usage: System.Net.Protocol \"name\" { parse = Function, make = Function }", 2) end
            return function(settings)
                local protl     = newProtocol(name, settings)
                return protl
            end
        end,
        __tostring              = Namespace.GetNamespaceName,
    })

    --- Represents the protocol
    Namespace.SaveNamespace("System.Net.Protocol", protocol)
end)
