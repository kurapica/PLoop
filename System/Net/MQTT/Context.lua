--===========================================================================--
--                                                                           --
--                     System.Net.Protocol.MQTT.Context                      --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2020/08/18                                               --
-- Update Date  :   2020/08/18                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Net.MQTT"

    import "System.Net"

    --- The client state
    __Sealed__() __AutoIndex__()
    enum "ClientState" {
        "CONNECTING",
        "CONNECTED",
        "DISCONNECTING",
        "DISCONNECTED",
    }

    class "Server" {}

    --- Represents the MQTT client object used to connect to the server or the
    -- client that returned by the server's Accept method
    __Sealed__() class "Client" (function(_ENV)
        inherit "System.Context"

        export {
            MQTT.ProtocolLevel, MQTT.PacketType, MQTT.ConnectReturnCode, MQTT.QosLevel, MQTT.SubAckReturnCode, MQTT.PropertyIdentifier, MQTT.ReasonCode,
            MQTT.ConnectPacket, MQTT.ConnackPacket, MQTT.PublishPacket, MQTT.AckPacket, MQTT.SubscribePacket, MQTT.SubAckPacket, MQTT.MQTTException,

            TimeoutException, ClientState, Protocol.MQTT, Guid, Client, Context.Session,

            isObjectType        = Class.IsObjectType,
            pcall               = pcall,
            error               = error,
        }

        -- Only use this for test or client side only
        local SocketType        = System.Net.Socket

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- The client session, server side only
        property "Session"          { type = Session, default = function(self) return Session(self) end }

        --- The server address to be connected
        property "Address"          { type = String, default = "127.0.0.1" }

        --- The server port to be connected
        property "Port"             { type = NaturalNumber, default = 1883 }

        --- The socket object
        property "Socket"           { type = ISocket, default = SocketType and function(self) return SocketType() end }

        --- Gets or sets a value that specifies the amount of time after which a synchronous Receive call will time out
        property "ReceiveTimeout"   { type = Integer, handler = function(self, timeout) if self.Socket then self.Socket.ReceiveTimeout = timeout end end }

        --- Gets or sets a value that specifies the amount of time after which a synchronous Send call will time out
        property "SendTimeout"      { type = Integer, handler = function(self, timeout) if self.Socket then self.Socket.SendTimeout = timeout end end }

        --- Gets or sets a value that specifies the amount of time after which a synchronous Connect call will time out
        property "ConnectTimeout"   { type = Integer, handler = function(self, timeout) if self.Socket then self.Socket.ConnectTimeout = timeout end end }

        --- The client state
        property "State"            { type = ClientState, default = ClientState.DISCONNECTED }

        --- The MQTT Protocol Level
        property "ProtocolLevel"    { type = ProtocolLevel, default = ProtocolLevel.V3_1_1 }

        --- The keep alive time(in sec), default 1 min
        property "KeepAlive"        { type = Number, default = 60 }

        --- The clean session flag
        property "CleanSession"     { type = Boolean, default = false }

        --- The client ID
        property "ClientID"         { type = String, default = Guid.New():gsub("-", ""):sub(23) }

        --- The user name
        property "UserName"         { type = String }

        --- The password
        property "Password"         { type = String }

        --- The publiced packet, keep until the ack is received
        property "PublishPackets"   { set = false, default = function(self) return {} end }

        --- The last used packet ID
        property "LastPacketID"     { type = Number, default = 0 }

        -----------------------------------------------------------------------
        --                        Client Side Method                         --
        -----------------------------------------------------------------------
        --- Connect to the MQTT server, return true if successful connected
        __Arguments__{ ConnectWill/nil, PropertySet/nil }
        function Connect(self, will, properties)
            if self.State == ClientState.DISCONNECTED then
                -- Init the socket with timeout
                self.Socket.ConnectTimeout  = self.ConnectTimeout
                self.Socket.ReceiveTimeout  = self.ReceiveTimeout
                self.Socket.SendTimeout     = self.SendTimeout

                self.Socket:Connect(self.Address, self.Port)
                self.State      = ClientState.CONNECTING
            end

            if self.State == ClientState.CONNECTING then
                local packet    = {
                    version     = self.ProtocolLevel,
                    keepAlive   = self.KeepAlive,
                    clientID    = self.ClientID,
                    userName    = self.UserName,
                    password    = self.Password,
                    will        = will,
                }

                if self.ProtocolLevel == ProtocolLevel.V5_0 then
                    packet.cleanStart   = self.CleanSession
                    packet.properties   = properties
                else
                    packet.cleanSession = self.CleanSession
                end

                self.Socket:Send(MQTT.MakePacket(PacketType.CONNECT, packet))

                local ptype, packet     = Protocol.MQTT.ParsePacket(self.Socket)

                if ptype == PacketType.CONNACK then
                    self.State  = ClientState.CONNECTED
                    return true
                else
                    self:DisConnect()
                end
            end

            return false
        end

        --- DisConnect to the server
        __Arguments__{ ReasonCode/nil, PropertySet/nil }
        function DisConnect(self, reason, properties)
            if self.State == ClientState.DISCONNECTED or self.State == ClientState.DISCONNECTING then return end

            self.State          = ClientState.DISCONNECTING

            local packet        = {}

            if self.ProtocolLevel == ProtocolLevel.V5_0 then
                packet.reasonCode = reason or ReasonCode.SUCCESS
                packet.properties = properties
            end

            self.Socket:Send(MQTT.MakePacket(PacketType.DISCONNECT, packet))
            self.Socket:Close()

            self.State          = ClientState.DISCONNECTED
        end

        --- Send subscribe message to the server
        __Arguments__{ NEString, QosLevel/nil, PropertySet/nil, TopicFilterOption/nil }
        function Subscribe(self, filter, qos, properties, options)
            if self.State ~= ClientState.CONNECTED then return end

            local packet        = {
                packetID        = self:GetPacketId(),
                properties      = properties,
                topicFilters    = {
                    { topicFilter = filter, requestedQoS = qos or QosLevel.EXACTLY_ONCE, options = options }
                }
            }

            self.Socket:Send(MQTT.MakePacket(PacketType.SUBSCRIBE, packet))
        end

        --- Send Unsubscribe message to the server
        __Arguments__{ NEString, PropertySet/nil }
        function Unsubscribe(self, filter, properties, options)
            if self.State ~= ClientState.CONNECTED then return end

            local packet        = {
                packetID        = self:GetPacketId(),
                properties      = properties,
                topicFilters    = {
                    { topicFilter = filter }
                }
            }

            self.Socket:Send(MQTT.MakePacket(PacketType.UNSUBSCRIBE, packet))
        end

        --- Send ping to the server
        function PingReq(self)
            if self.State ~= ClientState.CONNECTED then return end

            self.Socket:Send(MQTT.MakePacket(PacketType.PINGREQ, {}))
        end

        -----------------------------------------------------------------------
        --                        Server Side Method                         --
        -----------------------------------------------------------------------
        --- Send the connect ack to the client
        __Arguments__{ ConnectReturnCode/nil, PropertySet/nil }
        function ConnectAck(self, returnCode, properties)
            -- Return if already send the connect ack
            if self.State ~= ClientState.DISCONNECTED then return end

            self.Socket.ConnectTimeout  = self.ConnectTimeout
            self.Socket.ReceiveTimeout  = self.ReceiveTimeout
            self.Socket.SendTimeout     = self.SendTimeout

            local packet        = {}
            local session       = self.Context and self.Context.Session

            packet.sessionPresent = session and not session.IsNewSession or false
            packet.returnCode   = returnCode or ConnectReturnCode.ACCEPTED
            packet.properties   = properties

            self.Socket:Send(MQTT.MakePacket(PacketType.CONNACK, packet))

            if packet.returnCode == ConnectReturnCode.ACCEPTED then
                self.State      = ClientState.CONNECTED
            else
                -- Close the server side client
                self.Socket:Close()
            end
        end

        --- Send the subscribe ack message to the client
        __Arguments__{ Number, SubAckReturnCode/nil, PropertySet/nil }
        function SubAck(self, packetid, returncode, properties)
            if self.State ~= ClientState.CONNECTED then return end

            local packet        = {
                packetID        = packetid,
                properties      = properties,
                returnCodes     = { returncode or SubAckReturnCode.MAX_QOS_2 }
            }

            self.Socket:Send(MQTT.MakePacket(PacketType.SUBACK, packet))
        end

        --- Send the unsubscribe ack message to the client
        __Arguments__{ Number, ReasonCode/nil, PropertySet/nil }
        function UnsubAck(self, packetid, returncode, properties)
            if self.State ~= ClientState.CONNECTED then return end

            local packet        = {
                packetID        = packetid,
                properties      = properties,
                returnCodes     = { returncode or ReasonCode.SUCCESS }
            }

            self.Socket:Send(MQTT.MakePacket(PacketType.UNSUBACK, packet))
        end

        --- Send ping to the client as the response to the pingreq packet
        function PingResp(self)
            if self.State ~= ClientState.CONNECTED then return end

            self.Socket:Send(MQTT.MakePacket(PacketType.PINGRESP, {}))
        end

        -----------------------------------------------------------------------
        --                    Server & Client Side Method                    --
        -----------------------------------------------------------------------
        --- Start receive the packet data until the client is closed, the packet
        -- can be handled within the OnPacketReceived event
        function Process(self)
            local ok, ptype, packet

            if self.ReceiveTimeout and self.ReceiveTimeout > 0 then
                ok, ptype, packet = pcall(MQTT.ParsePacket, self.Socket)
            else
                ok, ptype, packet = true, MQTT.ParsePacket(self.Socket)
            end
            if not ok then
                if not isObjectType(ptype, TimeoutException) then
                    error(ptype)
                end
            else
                if ptype == PacketType.PUBACK then
                    -- Clear the published packet
                    self.PublishPackets[packet.packetID] = nil
                elseif ptype == PacketType.CONNECT then
                    -- Get the client ID into the session id
                    self.Session.SessionID = packet.clientID
                end

                return ptype, packet
            end
        end

        --- Gets a new packet id
        function GetPacketId(self)
            local packetid      = self.LastPacketID + 1
            if packetid >= 2^15 - 1 then packetid = 1 end
            self.LastPacketID   = packetid
            return packetid
        end

        --- Publish the message to the server or client
        __Arguments__{ NEString, NEString, QosLevel/nil, Boolean/nil, PropertySet/nil }
        function Publish(self, topic, payload, qos, retain, properties)
            if self.State ~= ClientState.CONNECTED then return end

            local packet        = {
                topicName       = topic,
                payload         = payload,
                properties      = properties,
                qos             = qos or QosLevel.AT_MOST_ONCE,
                retainFlag      = retain or false,
                dupFlag         = false,
            }

            if packet.qos > QosLevel.AT_MOST_ONCE then
                local pid       = self:GetPacketId()
                packet.packetID = pid
                self.PublishPackets[pid] = packet
            end

            self.Socket:Send(MQTT.MakePacket(PacketType.PUBLISH, packet))
        end

        --- Re-publish the message to the server or client
        __Arguments__{ Number }
        function RePublish(self, packetid)
            if self.State ~= ClientState.CONNECTED then return end

            local packet        = self.PublishPackets[packetid]
            if not packet then return end

            packet.dupFlag      = true
            self.Socket:Send(MQTT.MakePacket(PacketType.PUBLISH, packet))
        end

        --- Send the Publish Ack message to the server or client, should only be used on publish packet with QoS level 1
        __Arguments__{ Number, ReasonCode/nil, PropertySet/nil}
        function PubAck(self, packetid, reasoncode, properties)
            if self.State ~= ClientState.CONNECTED then return end

            local packet        = {
                packetID        = packetid,
                reasonCode      = reasonCode or ReasonCode.SUCCESS,
                properties      = properties,
            }

            self.Socket:Send(MQTT.MakePacket(PacketType.PUBACK, packet))
        end

        --- Send the Publish receive message to the server or client, should only be used on public packet with QoS level 2
        __Arguments__{ Number, ReasonCode/nil, PropertySet/nil}
        function PubRec(self, packetid, reasoncode, properties)
            if self.State ~= ClientState.CONNECTED then return end

            local packet        = {
                packetID        = packetid,
                reasonCode      = reasonCode or ReasonCode.SUCCESS,
                properties      = properties,
            }

            self.Socket:Send(MQTT.MakePacket(PacketType.PUBREC, packet))
        end

        --- Send the Publish Release message to the server or client, should only be used on public packet with QoS level 2
        __Arguments__{ Number, ReasonCode/nil, PropertySet/nil}
        function PubRel(self, packetid, reasoncode, properties)
            if self.State ~= ClientState.CONNECTED then return end

            local packet        = {
                packetID        = packetid,
                reasonCode      = reasonCode or ReasonCode.SUCCESS,
                properties      = properties,
            }

            self.Socket:Send(MQTT.MakePacket(PacketType.PUBREL, packet))
        end

        --- Send the Publish Release message to the server or client, should only be used on public packet with QoS level 2
        __Arguments__{ Number, ReasonCode/nil, PropertySet/nil}
        function PubComp(self, packetid, reasoncode, properties)
            if self.State ~= ClientState.CONNECTED then return end

            local packet        = {
                packetID        = packetid,
                reasonCode      = reasonCode or ReasonCode.SUCCESS,
                properties      = properties,
            }

            self.Socket:Send(MQTT.MakePacket(PacketType.PUBCOMP, packet))
        end

        --- Send the extended authentication exchange data between the client and the server
        __Arguments__{ ReasonCode/nil, PropertySet/nil }
        function Auth(self, reasonCode, properties)
            if self.State ~= ClientState.CONNECTED then return end

            local packet        = {
                reasonCode      = reasonCode or ReasonCode.SUCCESS,
                properties      = properties,
            }

            self.Socket:Send(MQTT.MakePacket(PacketType.AUTH, packet))
        end

        --- Close the connection
        function Close(self)
            return self.Socket:Close()
        end
    end)

    --- Represents the MQTT server object used to listen and serve the clients
    -- The MQTT server may have many implementations based on the platform, this
    -- is only a sample class
    __Sealed__() class "Server" (function(_ENV)
        extend "IAutoClose"

        export { Context, Client, ClientState }

        local SocketType        = System.Net.Socket

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- The socket object used to accept connections
        property "Socket"           { type = ISocket, default = SocketType and function(self) return SocketType() end }

        --- The server address to be bind
        property "Address"          { type = String, default = "*" }

        --- The server port to be bind
        property "Port"             { type = NaturalNumber, default = 1883 }

        --- The number of client connections that can be queued
        property "Backlog"          { type = NaturalNumber }

        --- Gets or sets a value that specifies the amount of time after which a synchronous Accept call will time out
        property "AcceptTimeout"    { type = Integer }

        --- Gets or sets a value that specifies the amount of time after which a synchronous Receive call will time out
        property "ReceiveTimeout"   { type = Integer }

        --- Gets or sets a value that specifies the amount of time after which a synchronous Send call will time out
        property "SendTimeout"      { type = Integer }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        --- Open the server
        function Open(self)
            self.Socket:Bind(self.Address, self.Port)
            self.Socket:Listen(self.Backlog)
        end

        --- Close the server
        function Close(self)
            self.Socket:Shutdown()
        end

        --- Try get the client from the socket object, maybe nil if time out
        function GetClient(self)
            self.Socket.AcceptTimeout = self.AcceptTimeout

            local ok, client    = true

            if self.AcceptTimeout and self.AcceptTimeout > 0 then
                ok, client      = pcall(self.Socket.Accept, self.Socket)
            else
                client          = self.Socket:Accept()
            end

            if not ok then
                if not isObjectType(client, TimeoutException) then
                    error(client)
                end
                return
            end

            return Client {
                Socket          = client,
                Context         = context,
                ReceiveTimeout  = self.ReceiveTimeout,
                SendTimeout     = self.SendTimeout,
            }
        end
    end)
end)