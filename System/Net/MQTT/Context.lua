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
        "DISCONNECTED",
        "CONNECTING",
        "CONNECTED",
        "CLOSED",           -- Server Side Only
    }

    --- Represents the MQTT client object used to connect to the server or the
    -- client that returned by the server's Accept method
    __Sealed__() class "Client" (function(_ENV)
        inherit "System.Context"
        extend "System.IAutoClose"

        export {
            MQTT.ProtocolLevel, MQTT.PacketType, MQTT.ConnectReturnCode, MQTT.QosLevel, MQTT.SubAckReturnCode, MQTT.PropertyIdentifier, MQTT.ReasonCode,
            MQTT.ConnectPacket, MQTT.ConnackPacket, MQTT.PublishPacket, MQTT.AckPacket, MQTT.SubscribePacket, MQTT.SubAckPacket, MQTT.MQTTException,

            MQTT.ConnectWill, System.Context.Session,

            Net.TimeoutException, ClientState, Protocol.MQTT, Guid, Date,

            isObjectType        = Class.IsObjectType,
            valEnumValue        = Enum.ValidateValue,
            pcall               = pcall,
            error               = error,
            ipairs              = ipairs,
            type                = type,
            min                 = math.min,
            floor               = math.floor,
            yield               = coroutine.yield,
        }

        -- Only use this for test or client side only
        local SocketType        = System.Net.Socket

        -----------------------------------------------------------------------
        --                               event                               --
        -----------------------------------------------------------------------
        --- Fired when a message packet is received
        event "OnMessageReceived"

        -----------------------------------------------------------------------
        --                        abstract property                          --
        -----------------------------------------------------------------------
        --- The Message Publisher
        __Abstract__()
        property "MessagePublisher" { type = System.Net.MQTT.IMQTTPublisher }

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- The server side session
        property "Session"          { type = Session, default = function(self) return Session(self) end }

        --- Whether the client is server side
        property "IsServerSide"     { type = Boolean, default = true }

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

        --- Whether auto send the ping to the server to keep connection, not works for the server side client
        property "KeepConnection"   { type = Boolean, default = true }

        --- The maximum qos level can be subscribed
        property "MaximumQosLevel"  { type = QosLevel, default = QosLevel.EXACTLY_ONCE }

        --- Whether auto yield during the process
        property "AutoYield"        { type = Boolean, default = false }

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

        --- The will message
        property "WillMessage"      { type = ConnectWill }

        --- The last active time that received the packet
        property "LastActiveTime"   { type = Date }

        --- The subscribed topics and requested qos levels, used both for server side and client side
        property "TopicFilters"     { set = false, default = function() return {} end }

        --- The subscription topic filters
        property "SubscribeTopicFilters"    { set = false, default = function() return {} end }

        --- The unsubscribe topic filters
        property "UnsubscribeTopicFilters"  { set = false, default = function() return {} end }

        -----------------------------------------------------------------------
        --                         abstract method                           --
        -----------------------------------------------------------------------
        --- Valiate the connection or auth packet for authentication, should return the ConnectReturnCode as result
        __Abstract__() function Authenticate(self, packet) end

        -----------------------------------------------------------------------
        --                           Common Method                           --
        -----------------------------------------------------------------------
        --- Start process the packet data until the client is closed
        -- This method could be overridden to add features like yield and etc
        -- it's also very simple to create custom processing method
        function Process(self)
            while self.State ~= ClientState.CLOSED do
                if self.IsServerSide and self.MessagePublisher then
                    -- Check the published message
                    local topic, message, qos = self.MessagePublisher:ReceiveMessage()

                    if topic and message then
                        self:Publish(topic, message, qos)
                    end
                end

                local ptype, packet = self:ParsePacket()

                if ptype then
                    self:ProcessPacket(ptype, packet)
                end

                if self.AutoYield then yield(ptype or false, packet) end
            end
        end

        --- Parse the MQTT Packet from the incoming message and return the packet type and packet data if existed.
        -- The method will return false if timeout.
        --
        -- the server may close the client if the keep alive timeout or the client will send pingreq to keep connection
        -- automatically in this method
        function ParsePacket(self)
            if self.State == ClientState.CLOSED then return end

            local ok, ptype, packet
            if self.ReceiveTimeout and self.ReceiveTimeout > 0 then
                ok, ptype, packet   = pcall(MQTT.ParsePacket, self.Socket, self.ProtocolLevel)
            else
                ok, ptype, packet   = true, MQTT.ParsePacket(self.Socket, self.ProtocolLevel)
            end

            if ok then
                self.LastActiveTime = Date.Now

                if ptype == PacketType.PUBACK or ptype == PacketType.PUBCOMP then
                    -- Release the published packet
                    self.PublishPackets[packet.packetID] = nil
                end

                return ptype, packet
            elseif not isObjectType(ptype, TimeoutException) then
                error(ptype)
            elseif self.IsServerSide then
                -- Close the client if pass the time out
                if self.LastActiveTime and ( Date.Now.Time >= self.LastActiveTime.Time + self.KeepAlive ) then
                    self:CloseClient()
                    return -- keep return nil here to stop the iterator if existed
                end
            elseif self.KeepConnection and self.LastActiveTime and ( Date.Now.Time + self.ReceiveTimeout * 2 >= self.LastActiveTime.Time + self.KeepAlive ) then
                -- Auto ping to keep connection
                self:PingReq()
            end

            -- return false so the iterator may continue
            return false
        end

        -- Process the packet with default behaviors, this is the default for the automatically processing
        function ProcessPacket(self, ptype, packet)
            if ptype == PacketType.CONNECT then
                -- CLIENT -> SERVER
                self.ProtocolLevel  = packet.level

                -- Will Message
                self.WillMessage    = packet.will

                -- Handle the session part
                self.ClientID       = packet.selfID
                self.CleanSession   = packet.cleanStart or packet.cleanSession
                self.KeepAlive      = packet.keepAlive and floor(packet.keepAlive * 1.5) or nil

                self.Session.SessionID    = self.clientID

                if self.CleanSession then
                    self.Session.RawItems = {}
                    self.Session.Canceled = true        -- Don't save at last
                else
                    self.Session:LoadSessionItems()     -- Load the session items
                end

                -- Authenticate and Ack with the code
                local ok, ret       = self:Authenticate()
                if ok == false then
                    if not (type(ret) == "number" and valEnumValue(ConnectReturnCode, ret)) then
                        ret         = ConnectReturnCode.AUTHORIZE_FAILED
                    end
                elseif type(ok) == "number" and valEnumValue(ConnectReturnCode, ok) then
                    ret             = ok
                else
                    ret             = ConnectReturnCode.ACCEPTED
                end

                self:ConnectAck(ret)

            elseif ptype == PacketType.PUBLISH then
                -- Publish the message
                if self.IsServerSide and self.MessagePublisher then
                    -- Only the server side client should use the message publisher
                    self.MessagePublisher:PublishMessage(packet.topicName, packet.payload, packet.qos, packet.retainFlag)
                end

                -- Send out the message for other operations
                -- We need several methods to send out the message packets
                OnMessageReceived(self, packet.topicName, packet.payload)

                -- Send the ack based on the qos
                if packet.qos == QosLevel.AT_LEAST_ONCE then
                    self:PubAck(packet.packetID)
                elseif packet.qos == QosLevel.EXACTLY_ONCE then
                    self:PubRec(packet.packetID)
                end

            elseif ptype == PacketType.PUBACK then
                -- already handled
            elseif ptype == PacketType.PUBREC then
                self:PubRel(packet.packetID)

            elseif ptype == PacketType.PUBREL then
                self:PubComp(packet.packetID)

            elseif ptype == PacketType.PUBCOMP then
                -- already handled
            elseif ptype == PacketType.SUBSCRIBE then
                -- Subscribe the topic filter
                local returnCodes   = {}
                local publisher     = self.MessagePublisher

                for i, filter in ipairs(packet.topicFilters) do
                    returnCodes[i]  = publisher and publisher:SubscribeTopic(filter.topicFilter, min(self.MaximumQosLevel, filter.requestedQoS or QosLevel.AT_MOST_ONCE)) or SubAckReturnCode.FAILURE
                    self.TopicFilters[filter.topicFilter] = returnCodes[i]
                end

                self:SubAck(packet.packetID, returnCodes)

            elseif ptype == PacketType.SUBACK then
                -- Check the subscription result
                local filters               =  self.SubscribeTopicFilters[packet.packetID]
                self.SubscribeTopicFilters[packet.packetID] = nil

                if filters then
                    for i, filter in ipairs(filters) do
                        self.TopicFilters[filter.topicFilter] = packet.returnCodes[i]
                    end
                end

            elseif ptype == PacketType.UNSUBSCRIBE then
                -- Subscribe the topic filter
                local returnCodes   = {}
                local publisher     = self.MessagePublisher

                for i, filter in ipairs(packet.topicFilters) do
                    self.TopicFilters[filter.topicFilter] = nil
                    returnCodes[i]  = publish and publisher:UnsubscribeTopic(filter.topicFilter) or ReasonCode.UNSPECIFIED_ERROR
                end

                self:UnsubAck(packet.packetID, returnCodes)

            elseif ptype == PacketType.UNSUBACK then
                -- Check the unsubscribe request
                local filters               =  self.UnsubscribeTopicFilters[packet.packetID]
                self.UnsubscribeTopicFilters[packet.packetID] = nil

                if filters then
                    for i, filter in ipairs(filters) do
                        self.TopicFilters[filter.topicFilter] = nil
                    end
                end

            elseif ptype == PacketType.PINGREQ then
                -- Send the PINGRESP back
                self:PingResp()

            elseif ptype == PacketType.DISCONNECT then
                -- Manually remove the will message
                self.WillMessage  = nil
                self:CloseClient()

            elseif ptype == PacketType.AUTH then
                -- Not supported here
            end
        end

        --- Gets a new packet id
        function GetNewPacketId(self)
            local packetid      = self.LastPacketID + 1
            if packetid >= 2^15 - 1 then packetid = 1 end

            self.LastPacketID   = packetid
            return packetid
        end

        --- Open the message publisher on the server side client, do nothing for the client side
        function Open(self)
            if self.IsServerSide and self.MessagePublisher then
                self.MessagePublisher:Open()
            end
        end

        --- Close the message publisher on the server side client and close the socket
        function Close(self)
            if self.IsServerSide and self.MessagePublisher then
                self.MessagePublisher:Close()
            end
            self.Socket:Close()
        end

        -----------------------------------------------------------------------
        --                        Client Side Method                         --
        -----------------------------------------------------------------------
        --- Connect to the MQTT server, return true if successful connected
        __Arguments__{ ConnectWill/nil, PropertySet/nil }
        function Connect(self, will, properties)
            -- Reset teh state before connecting
            if self.State == ClientState.CLOSED and not self.IsServerSide then
                self.State      = ClientState.DISCONNECTED
            end

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

                self.Socket:Send(MQTT.MakePacket(PacketType.CONNECT, packet, self.ProtocolLevel))

                local ptype, packet = self:ParsePacket()

                if ptype == PacketType.CONNACK and packet.returnCode == ReasonCode.SUCCESS then
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
            if self.State == ClientState.CLOSED then return end

            if self.State == ClientState.CONNECTED then
                local packet    = {}

                if self.ProtocolLevel == ProtocolLevel.V5_0 then
                    packet.reasonCode = reason or ReasonCode.SUCCESS
                    packet.properties = properties
                end

                self.Socket:Send(MQTT.MakePacket(PacketType.DISCONNECT, packet, self.ProtocolLevel))
            end

            self.State          = ClientState.CLOSED
            self.Socket:Close()
        end

        --- Send subscribe message to the server
        __Arguments__{ NEString, QosLevel/nil, PropertySet/nil, TopicFilterOption/nil }
        function Subscribe(self, filter, qos, properties, options)
            if self.State ~= ClientState.CONNECTED then return end

            local packet        = {
                packetID        = self:GetNewPacketId(),
                properties      = properties,
                topicFilters    = {
                    { topicFilter = filter, requestedQoS = qos or QosLevel.EXACTLY_ONCE, options = options }
                }
            }

            -- Keep tracking the packet id with the filters
            self.SubscribeTopicFilters[packet.packetID] = packet.topicFilters
            self.Socket:Send(MQTT.MakePacket(PacketType.SUBSCRIBE, packet, self.ProtocolLevel))
        end

        __Arguments__{ TopicFilters, PropertySet/nil }
        function Subscribe(self, topicFilters, properties)
            if self.State ~= ClientState.CONNECTED then return end

            local packet        = {
                packetID        = self:GetNewPacketId(),
                properties      = properties,
                topicFilters    = topicFilters,
            }

            self.SubscribeTopicFilters[packet.packetID] = packet.topicFilters
            self.Socket:Send(MQTT.MakePacket(PacketType.SUBSCRIBE, packet, self.ProtocolLevel))
        end

        --- Send Unsubscribe message to the server
        __Arguments__{ NEString, PropertySet/nil }
        function Unsubscribe(self, filter, properties)
            if self.State ~= ClientState.CONNECTED then return end

            local packet        = {
                packetID        = self:GetNewPacketId(),
                properties      = properties,
                topicFilters    = {
                    { topicFilter = filter }
                }
            }

            -- Keep tracking the packet id with the filters
            self.UnsubscribeTopicFilters[packet.packetID] = packet.topicFilters
            self.Socket:Send(MQTT.MakePacket(PacketType.UNSUBSCRIBE, packet, self.ProtocolLevel))
        end

        __Arguments__{ TopicFilters, PropertySet/nil }
        function Unsubscribe(self, topicFilters, properties)
            if self.State ~= ClientState.CONNECTED then return end

            local packet        = {
                packetID        = self:GetNewPacketId(),
                properties      = properties,
                topicFilters    = topicFilters,
            }

            self.UnsubscribeTopicFilters[packet.packetID] = packet.topicFilters
            self.Socket:Send(MQTT.MakePacket(PacketType.UNSUBSCRIBE, packet, self.ProtocolLevel))
        end

        --- Send ping to the server
        function PingReq(self)
            if self.State ~= ClientState.CONNECTED then return end

            self.Socket:Send(MQTT.MakePacket(PacketType.PINGREQ, {}, self.ProtocolLevel))
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

            self.Socket:Send(MQTT.MakePacket(PacketType.CONNACK, packet, self.ProtocolLevel))

            if packet.returnCode == ConnectReturnCode.ACCEPTED then
                self.State      = ClientState.CONNECTED
            else
                -- Close the server side client
                self.State      = ClientState.CLOSED
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

            self.Socket:Send(MQTT.MakePacket(PacketType.SUBACK, packet, self.ProtocolLevel))
        end

        --- Send the subscribe ack message to the client
        __Arguments__{ Number, struct { SubAckReturnCode }, PropertySet/nil }
        function SubAck(self, packetid, returncodes, properties)
            if self.State ~= ClientState.CONNECTED then return end

            local packet        = {
                packetID        = packetid,
                properties      = properties,
                returnCodes     = returncodes,
            }

            self.Socket:Send(MQTT.MakePacket(PacketType.SUBACK, packet, self.ProtocolLevel))
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

            self.Socket:Send(MQTT.MakePacket(PacketType.UNSUBACK, packet, self.ProtocolLevel))
        end

        __Arguments__{ Number, struct { ReasonCode }, PropertySet/nil }
        function UnsubAck(self, packetid, returncodes, properties)
            if self.State ~= ClientState.CONNECTED then return end

            local packet        = {
                packetID        = packetid,
                properties      = properties,
                returnCodes     = returncodes
            }

            self.Socket:Send(MQTT.MakePacket(PacketType.UNSUBACK, packet, self.ProtocolLevel))
        end

        --- Send ping to the client as the response to the pingreq packet
        function PingResp(self)
            if self.State ~= ClientState.CONNECTED then return end

            self.Socket:Send(MQTT.MakePacket(PacketType.PINGRESP, {}, self.ProtocolLevel))
        end

        --- Close the Server side client
        function CloseClient(self)
            if self.State == ClientState.CLOSED or not self.IsServerSide then return end

            -- Check the will message
            local will          = self.WillMessage
            if will and self.MessagePublisher then
                -- Publish the will message
                self.MessagePublisher:PublishMessage(will.topic, will.message or will.payload, will.qos, will.retain)
            end

            self.State          = ClientState.CLOSED
            self.Socket:Close()

            -- Save the session
            if not self.CleanSession then
                self.Session:SaveSessionItems()
            end
        end

        -----------------------------------------------------------------------
        --                    Server & Client Side Method                    --
        -----------------------------------------------------------------------
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
                -- Should keep until ack
                local pid       = self:GetNewPacketId()
                packet.packetID = pid
                self.PublishPackets[pid] = packet
            end

            self.Socket:Send(MQTT.MakePacket(PacketType.PUBLISH, packet, self.ProtocolLevel))
        end

        --- Re-publish the message to the server or client
        __Arguments__{ Number }
        function RePublish(self, packetid)
            if self.State ~= ClientState.CONNECTED then return end

            local packet        = self.PublishPackets[packetid]
            if not packet then return end

            packet.dupFlag      = true
            self.Socket:Send(MQTT.MakePacket(PacketType.PUBLISH, packet, self.ProtocolLevel))
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

            self.Socket:Send(MQTT.MakePacket(PacketType.PUBACK, packet, self.ProtocolLevel))
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

            self.Socket:Send(MQTT.MakePacket(PacketType.PUBREC, packet, self.ProtocolLevel))
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

            self.Socket:Send(MQTT.MakePacket(PacketType.PUBREL, packet, self.ProtocolLevel))
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

            self.Socket:Send(MQTT.MakePacket(PacketType.PUBCOMP, packet, self.ProtocolLevel))
        end

        --- Send the extended authentication exchange data between the client and the server
        __Arguments__{ ReasonCode/nil, PropertySet/nil }
        function Auth(self, reasonCode, properties)
            if self.State ~= ClientState.CONNECTED then return end

            local packet        = {
                reasonCode      = reasonCode or ReasonCode.SUCCESS,
                properties      = properties,
            }

            self.Socket:Send(MQTT.MakePacket(PacketType.AUTH, packet, self.ProtocolLevel))
        end
    end)

    --- Represents the MQTT server object used to listen and serve the clients
    -- The MQTT server may have many implementations based on the platform
    -- This is only an example based on the Socket
    __Sealed__() class "Server" (function(_ENV)
        extend "IAutoClose"

        export {
            MQTT.ProtocolLevel, MQTT.PacketType, MQTT.ConnectReturnCode, MQTT.QosLevel, MQTT.SubAckReturnCode, MQTT.PropertyIdentifier, MQTT.ReasonCode,
            MQTT.ConnectPacket, MQTT.ConnackPacket, MQTT.PublishPacket, MQTT.AckPacket, MQTT.SubscribePacket, MQTT.SubAckPacket, MQTT.MQTTException,

            Net.TimeoutException, ClientState, Protocol.MQTT, Guid, Client, MQTT.MQTTPublisher,

            isObjectType        = Class.IsObjectType,
            pcall               = pcall,
            error               = error,
        }

        local SocketType        = System.Net.Socket

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- The socket object used to accept connections
        property "Socket"                   { type = ISocket, default = SocketType and function(self) return SocketType() end }

        --- The server address to be bind
        property "Address"                  { type = String, default = "*" }

        --- The server port to be bind
        property "Port"                     { type = NaturalNumber, default = 1883 }

        --- The number of client connections that can be queued
        property "Backlog"                  { type = NaturalNumber }

        --- Gets or sets a value that specifies the amount of time after which a synchronous Accept call will time out
        property "AcceptTimeout"            { type = NaturalNumber }

        --- Gets or sets a value that specifies the amount of time after which a synchronous Receive call will time out to the accepted client
        property "ReceiveTimeout"           { type = NaturalNumber }

        --- Gets or sets a value that specifies the amount of time after which a synchronous Send call will time out to the accepted client
        property "SendTimeout"              { type = NaturalNumber }

        --- The Session Storage Provider for the server side client, with a default session provider only for testing purposes
        property "SessionStorageProvider"   { type = System.Context.ISessionStorageProvider, default = function(self) return TableSessionStorageProvider() end }

        --- The MQTT Message Publisher type to be used for the server side client
        property "MessagePublisherType"     { type = - System.Net.MQTT.IMQTTPublisher, default = System.Net.MQTT.MQTTPublisher }

        -----------------------------------------------------------------------
        --                         abstract method                           --
        -----------------------------------------------------------------------
        --- Valiate the connection or auth packet for authentication, should return the ConnectReturnCode as result or true/false  and with a return code if failed
        __Abstract__() function Authenticate(self, packet) end

        --- Return a new message publisher to the client
        __Abstract__() function NewMessagePublisher(self) return MQTTPublisher() end

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
            self.Socket:Close()
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

            return Client       {
                Socket          = client,
                Server          = self,
                IsServerSide    = true,
                ReceiveTimeout  = self.ReceiveTimeout,
                SendTimeout     = self.SendTimeout,
                SessionStorageProvider = self.SessionStorageProvider,

                -- Override then method
                Authenticate    = self.Authenticate,

                -- The message publisher
                MessagePublisher= self.MessagePublisherType and self.MessagePublisherType(),
            }
        end
    end)
end)