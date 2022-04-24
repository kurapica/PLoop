--===========================================================================--
--                                                                           --
--                          System.Net.MQTT.Context                          --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2020/08/18                                               --
-- Update Date  :   2020/12/03                                               --
-- Version      :   1.0.1                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Net.MQTT"

    import "System.Net"

    --- The client state
    -- CLOSED is server side only
    __Sealed__() __AutoIndex__()
    enum "ClientState"                  { "DISCONNECTED", "CONNECTING", "CONNECTED", "CLOSED" }

    --- Represents the MQTT client object used to connect to the server or the
    -- client that returned by the server's Accept method
    __Sealed__()
    class "Client"                      (function(_ENV)
        inherit "System.Context"
        extend "System.IAutoClose"

        export                          {
            MQTT.ProtocolLevel, MQTT.PacketType, MQTT.ConnectReturnCode,
            MQTT.QosLevel, MQTT.SubAckReturnCode, MQTT.PropertyIdentifier,
            MQTT.ReasonCode, MQTT.ConnectPacket, MQTT.ConnackPacket,
            MQTT.PublishPacket, MQTT.AckPacket, MQTT.SubscribePacket,
            MQTT.SubAckPacket, MQTT.MQTTException, MQTT.ConnectWill,

            System.Context.Session, Net.TimeoutException, ClientState,
            Protocol.MQTT, Guid, Date, Queue,

            MAX_PACKET_ID               = 2^15 - 1,

            isObjectType                = Class.IsObjectType,
            valEnumValue                = Enum.ValidateValue,
            pcall                       = pcall,
            error                       = error,
            ipairs                      = ipairs,
            type                        = type,
            unpack                      = unpack or table.unpack,
            min                         = math.min,
            floor                       = math.floor,
            yield                       = coroutine.yield,

            Trace                       = Logger.Default[Logger.LogLevel.Trace],
        }

        -- Only use this for test or client side only
        local SocketType                = System.Net.Socket

        -----------------------------------------------------------------------
        --                               event                               --
        -----------------------------------------------------------------------
        --- Fired when the client has topic subscribed
        -- @param topic         the subscribed topic
        -- @param qos           the QoS of the topic
        event "OnTopicSubscribed"

        --- Fired when the client has topic unsubscribed
        -- @param topic         the unsubscribed topic
        event "OnTopicUnsubscribed"

        --- Fired when a message is received
        event "OnMessageReceived"

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- The server side session
        __Abstract__()
        property "Session"              { type = Session, default = function(self) return Session(self) end }

        --- The Message Publisher
        __Abstract__()
        property "MessagePublisher"     { type = System.Net.MQTT.IMQTTPublisher, handler = function(self, publisher) if publisher then publisher.Timeout = self.MessageReceiveTimeout end end }

        --- Whether the client is server side
        __Abstract__()
        property "IsServerSide"         { type = Boolean, default = false }

        --- The server address to be connected
        __Abstract__()
        property "Address"              { type = String, default = "127.0.0.1" }

        --- The server port to be connected
        __Abstract__()
        property "Port"                 { type = NaturalNumber, default = 1883 }

        --- The socket object
        __Abstract__()
        property "Socket"               { type = ISocket, default = SocketType and function(self) return SocketType() end }

        --- Gets or sets a value that specifies the amount of time after which a synchronous Receive call will time out
        __Abstract__()
        property "ReceiveTimeout"       { type = Number, handler = function(self, timeout) if self.Socket then self.Socket.ReceiveTimeout = timeout end end }

        --- Gets or sets a value that specifies the amount of time after which a synchronous Send call will time out
        __Abstract__()
        property "SendTimeout"          { type = Number, handler = function(self, timeout) if self.Socket then self.Socket.SendTimeout = timeout end end }

        --- Gets or sets a value that specifies the amount of time after which a synchronous Connect call will time out
        __Abstract__()
        property "ConnectTimeout"       { type = Number, handler = function(self, timeout) if self.Socket then self.Socket.ConnectTimeout = timeout end end }

        --- Gets or sets a value that specifies the amount of time for the message published after which a synchronous Receive call will time out
        __Abstract__()
        property "MessageReceiveTimeout"{ type = Number, handler = function(self, timeout) if self.MessagePublisher then self.MessagePublisher.Timeout = timeout end end }

        --- Whether auto send the ping to the server to keep connection, not works for the server side client
        __Abstract__()
        property "KeepConnection"       { type = Boolean, default = true }

        --- The maximum qos level can be subscribed
        __Abstract__()
        property "MaximumQosLevel"      { type = QosLevel, default = QosLevel.EXACTLY_ONCE }

        --- The client state
        __Abstract__()
        property "State"                { type = ClientState, default = ClientState.DISCONNECTED }

        --- The MQTT Protocol Level
        __Abstract__()
        property "ProtocolLevel"        { type = ProtocolLevel, default = ProtocolLevel.V3_1_1 }

        --- The keep alive time(in sec), default 1 min
        __Abstract__()
        property "KeepAlive"            { type = Number,  default = 60 }

        --- The clean session flag
        __Abstract__()
        property "CleanSession"         { type = Boolean, default = false }

        --- The client ID
        __Abstract__()
        property "ClientID"             { type = String,  default = function() return Guid.New():gsub("-", ""):sub(23) end }

        --- The user name
        __Abstract__()
        property "UserName"             { type = String }

        --- The password
        __Abstract__()
        property "Password"             { type = String }

        --- The last used packet ID
        __Abstract__()
        property "LastPacketID"         { type = Number, default = 0 }

        --- The will message
        __Abstract__()
        property "WillMessage"          { type = ConnectWill }

        --- The last active time that received the packet
        property "LastActiveTime"       { type = Date }

        --- The publiced packet, keep until the ack is received
        property "PublishPackets"       { set = false, default = Toolset.newtable }

        --- The subscribed topics and requested qos levels, used both for server side and client side
        property "TopicFilters"         { set = false, default = Toolset.newtable }

        --- The subscription topic filters
        property "SubscribeTopicFilters"{ set = false, default = Toolset.newtable }

        --- The unsubscribe topic filters
        property "UnsubscribeTopicFilters" { set = false, default = Toolset.newtable }

        -----------------------------------------------------------------------
        --                         abstract method                           --
        -----------------------------------------------------------------------
        --- Valiate the connection or auth packet for authentication, should return the ConnectReturnCode as result
        __Abstract__()
        function Authenticate(self, packet) end

        -----------------------------------------------------------------------
        --                           Common Method                           --
        -----------------------------------------------------------------------
        --- Start process the packet data until the client is closed
        -- This method could be overridden to add features like yield and etc
        -- it's also very simple to create custom processing method
        __Abstract__()
        function Process(self)
            while self.State ~= ClientState.CLOSED do
                if self.IsServerSide and self.MessagePublisher then
                    -- Check the published message
                    local topic, message, qos = self.MessagePublisher:ReceiveMessage()

                    if topic and message then
                        self:Publish(topic, message, qos)
                    end
                end

                local ptype, packet     = self:ParsePacket()

                if ptype then
                    self:ProcessPacket(ptype, packet)
                end
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
                ok, ptype, packet       = pcall(MQTT.ParsePacket, self.Socket, self.ProtocolLevel)
            else
                ok, ptype, packet       = true, MQTT.ParsePacket(self.Socket, self.ProtocolLevel)
            end

            if ok then
                Trace("[MQTT][CLIENT]%s [RECEIVE][%s] %s", self.ClientID, PacketType(ptype), packet)

                self.LastActiveTime     = Date.Now

                if ptype == PacketType.PUBACK or ptype == PacketType.PUBCOMP then
                    -- Release the published packet
                    self.PublishPackets[packet.packetID] = nil
                end

                return ptype, packet
            elseif not isObjectType(ptype, TimeoutException) then
                error(ptype)
            elseif self.IsServerSide then
                -- Close the client if pass the time out
                -- Trace("[MQTT][Timeout] [Now] %d [KeepAlive] %d", Date.Now.Time - self.LastActiveTime.Time, self.KeepAlive)
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
                self.ProtocolLevel      = packet.level

                -- Will Message
                self.WillMessage        = packet.will

                -- Handle the session part
                self.ClientID           = packet.clientID
                self.CleanSession       = packet.cleanStart or packet.cleanSession
                self.KeepAlive          = packet.keepAlive and floor(packet.keepAlive * 1.5) or 0

                self.Session.SessionID  = self.ClientID

                if self.CleanSession then
                    self.Session.RawItems = {}
                    self.Session.Canceled = true        -- Don't save at last
                else
                    self.Session:LoadSessionItems()     -- Load the session items
                end

                -- Authenticate and Ack with the code
                local ok, ret           = self:Authenticate(packet)
                if ok == false then
                    if not (type(ret) == "number" and valEnumValue(ConnectReturnCode, ret)) then
                        ret             = ConnectReturnCode.AUTHORIZE_FAILED
                    end
                elseif type(ok) == "number" and valEnumValue(ConnectReturnCode, ok) then
                    ret                 = ok
                else
                    ret                 = ConnectReturnCode.ACCEPTED
                end

                self:ConnectAck(ret)

            elseif ptype == PacketType.PUBLISH then
                -- Publish the message
                if self.IsServerSide and self.MessagePublisher then
                    -- Only the server side client should use the message publisher
                    self.MessagePublisher:PublishMessage(packet.topicName, packet.payload, packet.qos, packet.retainFlag)
                end

                -- Send out the client message
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
                local returnCodes       = {}
                local publisher         = self.MessagePublisher
                local subscribed        = Queue()

                for i, filter in ipairs(packet.topicFilters) do
                    local qos           = min(self.MaximumQosLevel, filter.requestedQoS or QosLevel.AT_MOST_ONCE)
                    returnCodes[i]      = publisher and publisher:SubscribeTopic(filter.topicFilter, qos) or SubAckReturnCode.FAILURE
                    self.TopicFilters[filter.topicFilter] = returnCodes[i]

                    if returnCodes[i] <= SubAckReturnCode.MAX_QOS_2 then
                        subscribed:Enqueue(filter.topicFilter, qos)
                    end
                end

                self:SubAck(packet.packetID, returnCodes)

                while subscribed.Count > 0 do
                    OnTopicSubscribed(self, subscribed:Dequeue(2))
                end

            elseif ptype == PacketType.SUBACK then
                -- Check the subscription result
                local filters           =  self.SubscribeTopicFilters[packet.packetID]
                self.SubscribeTopicFilters[packet.packetID] = nil

                if filters then
                    for i, filter in ipairs(filters) do
                        self.TopicFilters[filter.topicFilter] = packet.returnCodes[i]
                    end
                end

            elseif ptype == PacketType.UNSUBSCRIBE then
                -- Subscribe the topic filter
                local returnCodes       = {}
                local publisher         = self.MessagePublisher
                local unsubscribed      = Queue()

                for i, filter in ipairs(packet.topicFilters) do
                    self.TopicFilters[filter.topicFilter] = nil
                    returnCodes[i]      = publish and publisher:UnsubscribeTopic(filter.topicFilter) or ReasonCode.UNSPECIFIED_ERROR

                    if returnCodes[i] == ReasonCode.SUCCESS then
                        unsubscribed:Enqueue(filter.topicFilter)
                    end
                end

                self:UnsubAck(packet.packetID, returnCodes)

                local filter            = unsubscribed:Dequeue()
                while filter do
                    OnTopicUnsubscribed(self, filter)
                    filter              = unsubscribed:Dequeue()
                end

            elseif ptype == PacketType.UNSUBACK then
                -- Check the unsubscribe request
                local filters           =  self.UnsubscribeTopicFilters[packet.packetID]
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
                self.WillMessage        = nil
                self:CloseClient()

            elseif ptype == PacketType.AUTH then
                -- Not supported here
            end
        end

        -- Send the packet to the client
        function SendPacket(self, ptype, packet)
            Trace("[MQTT][CLIENT]%s [SEND][%s] - %s", self.ClientID, PacketType(ptype), packet)
            self.Socket:Send(MQTT.MakePacket(ptype, packet, self.ProtocolLevel))
        end

        --- Gets a new packet id
        function GetNewPacketId(self)
            local packetid              = self.LastPacketID + 1
            if packetid >= MAX_PACKET_ID then packetid = 1 end

            self.LastPacketID           = packetid
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
                self.State              = ClientState.DISCONNECTED
            end

            if self.State == ClientState.DISCONNECTED then
                -- Init the socket with timeout
                self.Socket.ConnectTimeout  = self.ConnectTimeout
                self.Socket.ReceiveTimeout  = self.ReceiveTimeout
                self.Socket.SendTimeout     = self.SendTimeout

                self.Socket:Connect(self.Address, self.Port)
                self.State              = ClientState.CONNECTING
            end

            if self.State == ClientState.CONNECTING then
                local packet            = {
                    level               = self.ProtocolLevel,
                    keepAlive           = self.KeepAlive,
                    clientID            = self.ClientID,
                    userName            = self.UserName,
                    password            = self.Password,
                    will                = will,
                }

                if self.ProtocolLevel == ProtocolLevel.V5_0 then
                    packet.cleanStart   = self.CleanSession
                    packet.properties   = properties
                else
                    packet.cleanSession = self.CleanSession
                end

                self:SendPacket(PacketType.CONNECT, packet)

                local ptype, packet     = self:ParsePacket()

                if ptype == PacketType.CONNACK and packet.returnCode == ReasonCode.SUCCESS then
                    self.State          = ClientState.CONNECTED
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
                local packet            = {}

                if self.ProtocolLevel  == ProtocolLevel.V5_0 then
                    packet.reasonCode   = reason or ReasonCode.SUCCESS
                    packet.properties   = properties
                end

                self:SendPacket(PacketType.DISCONNECT, packet)
            end

            self.State                  = ClientState.CLOSED
            self.Socket:Close()
        end

        --- Send subscribe message to the server
        __Arguments__{ NEString, QosLevel/nil, PropertySet/nil, TopicFilterOption/nil }
        function Subscribe(self, filter, qos, properties, options)
            if self.State ~= ClientState.CONNECTED then return end

            local packet                = {
                packetID                = self:GetNewPacketId(),
                properties              = properties,
                topicFilters            = {
                    { topicFilter = filter, requestedQoS = qos or QosLevel.EXACTLY_ONCE, options = options }
                }
            }

            -- Keep tracking the packet id with the filters
            self.SubscribeTopicFilters[packet.packetID] = packet.topicFilters

            self:SendPacket(PacketType.SUBSCRIBE, packet)
        end

        __Arguments__{ TopicFilters, PropertySet/nil }
        function Subscribe(self, topicFilters, properties)
            if self.State ~= ClientState.CONNECTED then return end

            local packet                = {
                packetID                = self:GetNewPacketId(),
                properties              = properties,
                topicFilters            = topicFilters,
            }

            self.SubscribeTopicFilters[packet.packetID] = packet.topicFilters

            self:SendPacket(PacketType.SUBSCRIBE, packet)
        end

        --- Send Unsubscribe message to the server
        __Arguments__{ NEString, PropertySet/nil }
        function Unsubscribe(self, filter, properties)
            if self.State ~= ClientState.CONNECTED then return end

            local packet                = {
                packetID                = self:GetNewPacketId(),
                properties              = properties,
                topicFilters            = {
                    { topicFilter       = filter }
                }
            }

            -- Keep tracking the packet id with the filters
            self.UnsubscribeTopicFilters[packet.packetID] = packet.topicFilters

            self:SendPacket(PacketType.UNSUBSCRIBE, packet)
        end

        __Arguments__{ TopicFilters, PropertySet/nil }
        function Unsubscribe(self, topicFilters, properties)
            if self.State ~= ClientState.CONNECTED then return end

            local packet                = {
                packetID                = self:GetNewPacketId(),
                properties              = properties,
                topicFilters            = topicFilters,
            }

            self.UnsubscribeTopicFilters[packet.packetID] = packet.topicFilters

            self:SendPacket(PacketType.UNSUBSCRIBE, packet)
        end

        --- Send ping to the server
        function PingReq(self)
            if self.State ~= ClientState.CONNECTED then return end

            self:SendPacket(PacketType.PINGREQ, {})
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

            local packet                = {}
            local session               = self.Context and self.Context.Session

            packet.sessionPresent       = session and not session.IsNewSession or false
            packet.returnCode           = returnCode or ConnectReturnCode.ACCEPTED
            packet.properties           = properties

            self:SendPacket(PacketType.CONNACK, packet)

            if packet.returnCode == ConnectReturnCode.ACCEPTED then
                self.State              = ClientState.CONNECTED
                self.LastActiveTime     = Date.Now
            else
                -- Close the server side client
                self.State              = ClientState.CLOSED
                self.Socket:Close()
            end
        end

        --- Send the subscribe ack message to the client
        __Arguments__{ Number, SubAckReturnCode/nil, PropertySet/nil }
        function SubAck(self, packetid, returncode, properties)
            if self.State ~= ClientState.CONNECTED then return end

            local packet                = {
                packetID                = packetid,
                properties              = properties,
                returnCodes             = { returncode or SubAckReturnCode.MAX_QOS_2 }
            }

            self:SendPacket(PacketType.SUBACK, packet)
        end

        --- Send the subscribe ack message to the client
        __Arguments__{ Number, struct { SubAckReturnCode }, PropertySet/nil }
        function SubAck(self, packetid, returncodes, properties)
            if self.State ~= ClientState.CONNECTED then return end

            local packet                = {
                packetID                = packetid,
                properties              = properties,
                returnCodes             = returncodes,
            }

            self:SendPacket(PacketType.SUBACK, packet)
        end

        --- Send the unsubscribe ack message to the client
        __Arguments__{ Number, ReasonCode/nil, PropertySet/nil }
        function UnsubAck(self, packetid, returncode, properties)
            if self.State ~= ClientState.CONNECTED then return end

            local packet                = {
                packetID                = packetid,
                properties              = properties,
                returnCodes             = { returncode or ReasonCode.SUCCESS }
            }

            self:SendPacket(PacketType.UNSUBACK, packet)
        end

        __Arguments__{ Number, struct { ReasonCode }, PropertySet/nil }
        function UnsubAck(self, packetid, returncodes, properties)
            if self.State ~= ClientState.CONNECTED then return end

            local packet                = {
                packetID                = packetid,
                properties              = properties,
                returnCodes             = returncodes
            }

            self:SendPacket(PacketType.UNSUBACK, packet)
        end

        --- Send ping to the client as the response to the pingreq packet
        function PingResp(self)
            if self.State ~= ClientState.CONNECTED then return end

            self:SendPacket(PacketType.PINGRESP, {})
        end

        --- Close the Server side client
        function CloseClient(self)
            if self.State == ClientState.CLOSED or not self.IsServerSide then return end

            -- Check the will message
            local will                  = self.WillMessage
            if will and self.MessagePublisher then
                -- Publish the will message
                self.MessagePublisher:PublishMessage(will.topic, will.message or will.payload, will.qos, will.retain)
            end

            Trace("[MQTT][CLIENT]%s [CLOSE]", self.ClientID)

            self.State                  = ClientState.CLOSED
            self.Socket:Close()

            -- Save the session
            if not self.CleanSession then
                self.Session:SaveSessionItems()
            end
        end

        -----------------------------------------------------------------------
        --                    Server & Client Side Method                    --
        -----------------------------------------------------------------------
        --- Publish the message to the server or client, and return the packet id
        __Arguments__{ NEString, NEString, QosLevel/nil, Boolean/nil, PropertySet/nil }
        function Publish(self, topic, payload, qos, retain, properties)
            if self.State ~= ClientState.CONNECTED then return end

            local packet                = {
                topicName               = topic,
                payload                 = payload,
                properties              = properties,
                qos                     = qos or QosLevel.AT_MOST_ONCE,
                retainFlag              = retain or false,
                dupFlag                 = false,
            }

            if packet.qos > QosLevel.AT_MOST_ONCE then
                -- Should keep until ack
                local pid               = self:GetNewPacketId()
                packet.packetID         = pid
                self.PublishPackets[pid]= packet
            end

            self:SendPacket(PacketType.PUBLISH, packet)

            return packet.packetID
        end

        --- Check if the packet haven't receive the ACK
        function IsPacketAcked(self, packetid)
            return packetid and self.PublishPackets[packetid] == nil
        end

        --- Re-publish the message to the server or client
        __Arguments__{ Number }
        function RePublish(self, packetid)
            if self.State ~= ClientState.CONNECTED then return end

            local packet                = self.PublishPackets[packetid]
            if not packet then return end

            packet.dupFlag              = true

            self:SendPacket(PacketType.PUBLISH, packet)
        end

        --- Send the Publish Ack message to the server or client, should only be used on publish packet with QoS level 1
        __Arguments__{ Number, ReasonCode/nil, PropertySet/nil}
        function PubAck(self, packetid, reasonCode, properties)
            if self.State ~= ClientState.CONNECTED then return end

            local packet                = {
                packetID                = packetid,
                reasonCode              = reasonCode or ReasonCode.SUCCESS,
                properties              = properties,
            }

            self:SendPacket(PacketType.PUBACK, packet)
        end

        --- Send the Publish receive message to the server or client, should only be used on public packet with QoS level 2
        __Arguments__{ Number, ReasonCode/nil, PropertySet/nil}
        function PubRec(self, packetid, reasonCode, properties)
            if self.State ~= ClientState.CONNECTED then return end

            local packet                = {
                packetID                = packetid,
                reasonCode              = reasonCode or ReasonCode.SUCCESS,
                properties              = properties,
            }

            self:SendPacket(PacketType.PUBREC, packet)
        end

        --- Send the Publish Release message to the server or client, should only be used on public packet with QoS level 2
        __Arguments__{ Number, ReasonCode/nil, PropertySet/nil}
        function PubRel(self, packetid, reasonCode, properties)
            if self.State ~= ClientState.CONNECTED then return end

            local packet                = {
                packetID                = packetid,
                reasonCode              = reasonCode or ReasonCode.SUCCESS,
                properties              = properties,
            }

            self:SendPacket(PacketType.PUBREL, packet)
        end

        --- Send the Publish Release message to the server or client, should only be used on public packet with QoS level 2
        __Arguments__{ Number, ReasonCode/nil, PropertySet/nil}
        function PubComp(self, packetid, reasonCode, properties)
            if self.State ~= ClientState.CONNECTED then return end

            local packet                = {
                packetID                = packetid,
                reasonCode              = reasonCode or ReasonCode.SUCCESS,
                properties              = properties,
            }

            self:SendPacket(PacketType.PUBCOMP, packet)
        end

        --- Send the extended authentication exchange data between the client and the server
        __Arguments__{ ReasonCode/nil, PropertySet/nil }
        function Auth(self, reasonCode, properties)
            if self.State ~= ClientState.CONNECTED then return end

            local packet                = {
                reasonCode              = reasonCode or ReasonCode.SUCCESS,
                properties              = properties,
            }

            self:SendPacket(PacketType.AUTH, packet)
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

            isObjectType                = Class.IsObjectType,
            pcall                       = pcall,
            error                       = error,
        }

        local SocketType                = System.Net.Socket

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- The socket object used to accept connections
        property "Socket"               { type = ISocket, default = SocketType and function(self) return SocketType() end }

        --- The server address to be bind
        property "Address"              { type = String, default = "*" }

        --- The server port to be bind
        property "Port"                 { type = NaturalNumber, default = 1883 }

        --- The number of client connections that can be queued
        property "Backlog"              { type = NaturalNumber }

        --- Gets or sets a value that specifies the amount of time after which a synchronous Accept call will time out
        property "AcceptTimeout"        { type = NaturalNumber }

        --- Gets or sets a value that specifies the amount of time after which a synchronous Receive call will time out to the accepted client
        property "ReceiveTimeout"       { type = NaturalNumber }

        --- Gets or sets a value that specifies the amount of time after which a synchronous Send call will time out to the accepted client
        property "SendTimeout"          { type = NaturalNumber }

        --- The Session Storage Provider for the server side client, with a default session provider only for testing purposes
        property "SessionStorageProvider"   { type = System.Context.ISessionStorageProvider, default = function(self) return System.Context.TableSessionStorageProvider() end }

        --- The MQTT Message Publisher type to be used for the server side client
        property "MessagePublisherType"     { type = - System.Net.MQTT.IMQTTPublisher, default = System.Net.MQTT.MQTTPublisher }

        -----------------------------------------------------------------------
        --                         abstract method                           --
        -----------------------------------------------------------------------
        --- Valiate the connection or auth packet for authentication, should return the ConnectReturnCode as result or true/false and with a return code if failed
        __Abstract__()
        function Authenticate(self, packet) end

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
            self.Socket.AcceptTimeout   = self.AcceptTimeout

            local ok, client            = true

            if self.AcceptTimeout and self.AcceptTimeout > 0 then
                ok, client              = pcall(self.Socket.Accept, self.Socket)
            else
                client                  = self.Socket:Accept()
            end

            if not ok then
                if not isObjectType(client, TimeoutException) then
                    error(client)
                end
                return
            end

            local client                = Client {
                Socket                  = client,
                IsServerSide            = true,
                ReceiveTimeout          = self.ReceiveTimeout,
                SendTimeout             = self.SendTimeout,

                -- Override the method
                Authenticate            = self.Authenticate,

                -- The message publisher
                MessagePublisher        = self.MessagePublisherType and self.MessagePublisherType(),
            }

            client.Session.SessionStorageProvider = self.SessionStorageProvider

            return client
        end
    end)
end)