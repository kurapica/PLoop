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

    namespace "System.Net"

    --- The socket implementation based on LuaSocket
    __Sealed__() class "Socket" (function(_ENV)
        extend "ISocket"

        export { "throw", Socket, SocketShutdown, TimeoutException }

        ---------------------------------------------------
        --                    method                     --
        ---------------------------------------------------
        --- Creates a new Socket for a newly created connection
        __Arguments__{}:Throwable()
        function Accept(self)
            self[0]:settimeout(self.AcceptTimeout)

            local ret, err      = self[0]:accept()
            if err == "timeout" then throw(TimeoutException()) end
            if not ret then throw(SocketException(err)) end

            return Socket(ret)
        end

        --- Associates a Socket with a local endpoint
        __Arguments__{ NEString/"*", NaturalNumber/0 }:Throwable()
        function Bind(self, address, port)
            local ret, err      = self[0]:bind(address, port)
            if not ret then throw(SocketException(err)) end
        end

        --- Places a Socket in a listening state
        __Arguments__{ NaturalNumber/nil }:Throwable()
        function Listen(self, backlog)
            local ret, err      = self[0]:listen(backlog)
            if not ret then throw(SocketException(err)) end
        end

        --- Establishes a connection to a remote host
        __Arguments__{ NEString, NaturalNumber }:Throwable()
        function Connect(self, address, port)
            self[0]:settimeout(self.ConnectTimeout)

            local ret, err      = self[0]:connect(address, port)
            if err == "timeout" then throw(TimeoutException()) end
            if not ret then throw(SocketException(err)) end
            return true
        end

        --- Closes the Socket connection and releases all associated resources
        function Close(self)
            self[0]:close()
        end

        --- Receives data from a bound Socket
        __Arguments__.Rest():Throwable()
        function Receive(self, ...)
            self[0]:settimeout(self.ReceiveTimeout)
            local ret, err     = self[0]:receive(...)
            if not ret then
                if err == "timeout" then throw(TimeoutException()) end
                throw(SocketException(err))
            end

            return ret
        end

        --- Sends data to a connected Socket
        function Send(self, ...)
            self[0]:settimeout(self.SendTimeout)

            return self[0]:send(...)
        end

        --- Disables sends and receives on a Socket
        __Arguments__{ SocketShutdown }:Throwable()
        function Shutdown(self, socketShutdown)
            local ret, err

            if socketShutdown == SocketShutdown.RECEIVE then
                ret, err        = self[0]:shutdown("receive")
            elseif socketShutdown == SocketShutdown.SEND then
                ret, err        = self[0]:shutdown("send")
            else
                ret, err        = self[0]:shutdown("both")
            end

            if not ret then throw(SocketException(err)) end
            return true
        end

        -- Sleep for several seconds
        __Arguments__{ Number }
        function Sleep(self, time)
            socket.sleep(time)
        end

        ---------------------------------------------------
        --                  constructor                  --
        ---------------------------------------------------
        __Arguments__{}
        function __ctor(self)
            local tcp, err      = socket.tcp()
            if not tcp then throw(SocketException(err)) end

            self[0]             = tcp
        end

        __Arguments__{ Userdata }
        function __ctor(self, sock)
            self[0]             = sock
        end
    end)
end)