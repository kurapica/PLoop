--===========================================================================--
--                                                                           --
--                            System.Net.Socket                              --
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
    -- An implementation of the ISocket based on the
    -- [LuaSocket](http://w3.impa.br/~diego/software/luasocket/tcp.html)
    local ok, socket            = pcall(require, "socket")
    if not socket then return end

    --- The socket implementation based on LuaSocket
    __Sealed__() class "System.Net.Socket" (function(_ENV)
        extend "System.Net.ISocket"

        import "System.Net"

        export { "throw", "type", "error", Socket, SocketShutdown, TimeoutException, SocketException, ProtocolType, LingerOption, fakefunc = Toolset.fakefunc }

        ---------------------------------------------------
        --                   property                    --
        ---------------------------------------------------
        --- Gets or sets a Boolean value that specifies whether the Socket can send or receive broadcast packets
        property "EnableBroadcast"  { type = Boolean, handler = function(self, value) self[0]:setoption("broadcast", value) end }

        --- Gets or sets a value that specifies whether the Socket will delay closing a socket in an attempt to send all pending data.
        property "LingerState"      { type = LingerOption, handler = function(self, state) self[0]:setoption("linger", state and { on = state.Enabled, timeout = state.LingerTime } or { on = false, timeout = 0 }) end }

        --- Gets or sets a Boolean value that specifies whether the stream Socket is using the Nagle algorithm.
        property "NoDelay"          { type = Boolean, handler = function(self, value) self[0]:setoption("tcp-nodelay", value) end }

        --- Gets or sets a Boolean value that indicates that outgoing messages should bypass the standard routing facilities
        property "EnableDontRoute"  { type = Boolean, handler = function(self, value) self[0]:setoption("dontroute", value) end }

        --- Gets or sets a Boolean value to enables the periodic transmission of messages on a connected socket.
        property "KeepAlive"        { type = Boolean, handler = function(self, value) self[0]:setoption("keepalive", value) end }

        --- Gets or sets a Boolean value to indicates that the rules used in validating addresses supplied in a call to bind should allow reuse of local addresses
        property "EnableReUseAddr"  { type = Boolean, handler = function(self, value) self[0]:setoption("reuseaddr", value) end }

        ---------------------------------------------------
        --                    method                     --
        ---------------------------------------------------
        --- Creates a new Socket for a newly created connection
        function Accept(self)
            if self.ProtocolType ~= ProtocolType.TCP then throw(ProtocolException()) end

            self[0]:settimeout(self.AcceptTimeout)

            local ret, err      = self[0]:accept()
            if err == "timeout" then throw(TimeoutException()) end
            if not ret          then throw(SocketException(err)) end

            local client        = Socket(ret)
            client.Connected    = true
            return client
        end

        --- Associates a Socket with a local endpoint
        __Arguments__{ NEString/"*", NaturalNumber/0 }
        function Bind(self, address, port)
            if self.ProtocolType == ProtocolType.TCP then
                local ret, err  = self[0]:bind(address, port)
                if not ret      then throw(SocketException(err)) end
            elseif self.ProtocolType == ProtocolType.UDP then
                local ret, err  = self[0]:setsockname(address, port)
                if not ret      then throw(SocketException(err)) end
            else
                throw(ProtocolException())
            end
        end

        --- Places a Socket in a listening state
        __Arguments__{ NaturalNumber/nil }
        function Listen(self, backlog)
            if self.ProtocolType == ProtocolType.TCP then
                local ret, err  = self[0]:listen(backlog)
                if not ret      then throw(SocketException(err)) end
            elseif self.ProtocolType.ProtocolType.UDP then
                -- Do nothing
            else
                throw(ProtocolException())
            end
        end

        --- Establishes a connection to a remote host
        __Arguments__{ NEString, NaturalNumber }
        function Connect(self, address, port)
            if self.Connected   then return false end

            if self.ProtocolType == ProtocolType.TCP then
                self[0]:settimeout(self.ConnectTimeout)

                local ret, err  = self[0]:connect(address, port)
                if err == "timeout" then throw(TimeoutException()) end
                if not ret      then throw(SocketException(err)) end

                self.Connected  = true
                return true
            elseif self.ProtocolType == ProtocolType.UDP then
                local ret, err  = self[0]:setpeername(address, port)
                if not ret      then throw(SocketException(err)) end

                self.Connected  = true
                return true
            else
                throw(ProtocolException())
            end
        end

        --- Receives data from a bound Socket
        function Receive(self, ...)
            self[0]:settimeout(self.ReceiveTimeout)
            local ret, err     = self[0]:receive(...)
            if not ret then
                if err == "timeout" then throw(TimeoutException()) end
                throw(SocketException(err))
            end

            return ret
        end

        --- Receives data from an endpoint
        function ReceiveFrom(self, ...)
            if self.ProtocolType ~= ProtocolType.UDP then throw(ProtocolException()) end

            self[0]:settimeout(self.ReceiveTimeout)
            local ret, ip, port = self[0]:receivefrom(...)
            if not ret then
                if ip=="timeout"then throw(TimeoutException()) end
                if ip           then throw(SocketException(ip)) end
            end

            return ret, ip, port
        end

        --- Sends data to a connected Socket
        function Send(self, ...)
            if self.ProtocolType == ProtocolType.TCP then
                self[0]:settimeout(self.SendTimeout)

                local r, e, s   = self[0]:send(...)
                if not r then
                    if e == "timeout" then
                        return s
                    else
                        throw(SocketException(e))
                    end
                end
                return r
            elseif self.ProtocolType == ProtocolType.UDP then
                local ret, err  = self[0]:send(...)
                if not ret      then throw(SocketException(err)) end
            else
                throw(ProtocolException())
            end
        end

        --- Sends data to the specified endpoint.
        function SendTo(self, ...)
            if self.ProtocolType ~= ProtocolType.UDP then throw(ProtocolException()) end

            local ret, err      = self[0]:sendto(...)
            if not ret          then throw(SocketException(err)) end
        end

        --- Disables sends and receives on a Socket
        __Arguments__{ SocketShutdown }
        function Shutdown(self, socketShutdown)
            local ret, err      = self[0]:shutdown(socketShutdown == SocketShutdown.RECEIVE and "receive"
                                                or socketShutdown == SocketShutdown.SEND and "send"
                                                or "both")

            if not ret          then throw(SocketException(err)) end
            return true
        end

        --- Closes the socket connection and allows reuse of the socket.
        function Disconnect(self)
            if not self.Connected then return end

            if self.ProtocolType == ProtocolType.UDP then
                local ret, err  = self[0]:setpeername("*")
                if not ret      then throw(SocketException(err)) end
                self.Connected  = false
            elseif self.ProtocolType == ProtocolType.TCP then
                self[0]:close()
                self.Connected  = false
            end
        end

        --- Closes the Socket connection and releases all associated resources
        function Close(self)
            if not self.Connected then return end

            self[0]:close()
            self.Connected      = false
        end

        -- Sleep for several seconds
        __Arguments__{ Number }
        function Sleep(self, time)
            socket.sleep(time)
        end

        ---------------------------------------------------
        --                 static method                 --
        ---------------------------------------------------
        --- Determines the status of one or more sockets.
        __Static__()
        Select                  = socket.select

        ---------------------------------------------------
        --                  constructor                  --
        ---------------------------------------------------
        __Arguments__{ ProtocolType/nil }
        function __ctor(self, ptype)
            ptype               = ptype or ProtocolType.TCP

            self.ProtocolType   = ptype

            local tcp, err      = (ptype == ProtocolType.TCP and socket.tcp or ptype == ProtocolType.UDP and socket.udp or fakefunc)()
            if not tcp then throw(SocketException(err or "The protocol type is unsupported")) end

            self[0]             = tcp
        end

        __Arguments__{ Userdata }
        function __ctor(self, sock)
            self[0]             = sock
            local class         = sock.class

            if type(class) == "string" then
                if class:match("^tcp") then
                    self.ProtocolType = ProtocolType.TCP
                elseif class:match("^udp") then
                    self.ProtocolType = ProtocolType.UDP
                else
                    throw(SocketException("The protocol type is unsupported"))
                end
            end
        end
    end)
end)