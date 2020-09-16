--===========================================================================--
--                                                                           --
--                         System.Net.Protocol.MQTT                          --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2020/08/11                                               --
-- Update Date  :   2020/08/11                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Net.MQTT"

    import "System.Net"

    export {
        List, Exception, XDictionary, System.Text.UTF8Encoding, ISocket,

        isObjectType            = Class.IsObjectType,

        lshift                  = Toolset.lshift,
        rshift                  = Toolset.rshift,
        band                    = Toolset.band,
        bor                     = Toolset.bor,
        bnot                    = Toolset.bnot,
        bxor                    = Toolset.bxor,

        strbyte                 = string.byte,
        strchar                 = string.char,
        tinsert                 = table.insert,
        tconcat                 = table.concat,
        unpack                  = unpack or table.unpack,
        type                    = type,
        ipairs                  = ipairs,
        pairs                   = pairs,
        tblconcat               = table.concat,

        throw                   = throw,

        MAX_VAR_LENGTH          = 2^28 - 1,
    }

    --- The MQTT Exception
    __Sealed__()
    class "MQTTException" { Exception }

    --- The MQTT Protocol Level
    __Sealed__()
    enum "ProtocolLevel" {
        V3_1                    = 3,
        V3_1_1                  = 4,
        V5_0                    = 5,
    }

    --- The MQTT Packet Control Type
    __Sealed__()
    enum "PacketType" {
        FORBIDDEN               = 0,   -- UNEXPECTED
        CONNECT                 = 1,   -- CLIENT ->Server
        CONNACK                 = 2,   -- CLIENT<- Server
        PUBLISH                 = 3,   -- CLIENT<->Server
        PUBACK                  = 4,   -- CLIENT<->Server
        PUBREC                  = 5,   -- CLIENT<->Server
        PUBREL                  = 6,   -- CLIENT<->Server
        PUBCOMP                 = 7,   -- CLIENT<->Server
        SUBSCRIBE               = 8,   -- CLIENT ->Server
        SUBACK                  = 9,   -- CLIENT<- Server
        UNSUBSCRIBE             = 10,  -- CLIENT ->Server
        UNSUBACK                = 11,  -- CLIENT<- Server
        PINGREQ                 = 12,  -- CLIENT ->Server
        PINGRESP                = 13,  -- CLIENT<- Server
        DISCONNECT              = 14,  -- CLIENT ->Server
        AUTH                    = 15,  -- CLIENT<->Server For MQTT v5.0
    }

    --- The Connection Return Code
    __Sealed__()
    enum "ConnectReturnCode" {
        ACCEPTED                = 0, -- Connection accepted

        -- For MQTT v3.1.1
        VERSION_NOT_SUPPORTED   = 1, -- The Server does not support the level of the MQTT protocol requested by the Client
        IDENTIFIER_REJECTED     = 2, -- The Client identifier is correct UTF-8 but not allowed by the Server
        SERVER_UNAVAILABLE      = 3, -- The Network Connection has been made but the MQTT service is unavailable
        USER_PASSWORD_MALFORMED = 4, -- The data in the user name or password is malformed
        AUTHORIZE_FAILED        = 5, -- The Client is not authorized to connect

        -- For MQTT V5.0
        UNSPECIFIED_ERROR       = 128 ,       -- The Server does not wish to reveal the reason for the failure, or none of the other Reason Codes apply.
        MALFORMED_PACKET        = 129 ,       -- Data within the CONNECT packet could not be correctly parsed.
        PROTOCOL_ERROR          = 130 ,       -- Data in the CONNECT packet does not conform to this specification.
        IMPLEMENTATION_SPECIFIC_ERROR = 131 , -- The CONNECT is valid but is not accepted by this Server.
        UNSUPPORTED_PROTOCOL_VERSION = 132 ,  -- The Server does not support the version of the MQTT protocol requested by the Client.
        CLIENT_IDENTIFIER_NOT_VALID = 133 ,   -- The Client Identifier is a valid string but is not allowed by the Server.
        BAD_USER_NAME_OR_PASSWORD   = 134 ,   -- The Server does not accept the User Name or Password specified by the Client
        NOT_AUTHORIZED          = 135 ,       -- The Client is not authorized to connect.
        SERVER_UNAVAILABLE      = 136 ,       -- The MQTT Server is not available.
        SERVER_BUSY             = 137 ,       -- The Server is busy. Try again later.
        BANNED                  = 138 ,       -- This Client has been banned by administrative action. Contact the server administrator.
        BAD_AUTHENTICATION_METHOD = 140 ,     -- The authentication method is not supported or does not match the authentication method currently in use.
        TOPIC_NAME_INVALID      = 144 ,       -- The Will Topic Name is not malformed, but is not accepted by this Server.
        PACKET_TOO_LARGE        = 149 ,       -- The CONNECT packet exceeded the maximum permissible size.
        QUOTA_EXCEEDED          = 151 ,       -- An implementation or administrative imposed limit has been exceeded.
        PAYLOAD_FORMAT_INVALID  = 153 ,       -- The Will Payload does not match the specified Payload Format Indicator.
        RETAIN_NOT_SUPPORTED    = 154 ,       -- The Server does not support retained messages, and Will Retain was set to 1.
        QOS_NOT_SUPPORTED       = 155 ,       -- The Server does not support the QoS set in Will QoS.
        USE_ANOTHER_SERVER      = 156 ,       -- The Client should temporarily use another server.
        SERVER_MOVED            = 157 ,       -- The Client should permanently use another server.
        CONNECTION_RATE_EXCEEDED= 159 ,       -- The connection rate limit has been exceeded.
    }

    --- The QoS level
    __Sealed__()
    enum "QosLevel" {
        AT_MOST_ONCE            = 0,
        AT_LEAST_ONCE           = 1,
        EXACTLY_ONCE            = 2,
    }

    --- The SubAck Return Code
    __Sealed__()
    enum "SubAckReturnCode" {
        MAX_QOS_0               = 0,                    -- The subscription is accepted and the maximum QoS sent will be QoS 0. This might be a lower QoS than was requested
        MAX_QOS_1               = 1,                    -- The subscription is accepted and the maximum QoS sent will be QoS 1. This might be a lower QoS than was requested.
        MAX_QOS_2               = 2,                    -- The subscription is accepted and any received QoS will be sent to this subscription.
        FAILURE                 = 128,                  -- The subscription is not accepted and the Server either does not wish to reveal the reason or none of the other Reason Codes apply.
        IMPLEMENTATION_SPECIFIC_ERROR = 131,            -- The SUBSCRIBE is valid but the Server does not accept it.
        NOT_AUTHORIZED          = 135,                  -- The Client is not authorized to make this subscription.
        TOPIC_FILTER_INVALID    = 143,                  -- The Topic Filter is correctly formed but is not allowed for this Client.
        PACKET_IDENTIFIER_IN_USE= 145,                  -- The specified Packet Identifier is already in use.
        QUOTA_EXCEEDED          = 151,                  -- An implementation or administrative imposed limit has been exceeded.
        SHARED_SUBSCRIPTIONS_NOT_SUPPORTED  = 158,      -- The Server does not support Shared Subscriptions for this Client.
        SUBSCRIPTION_IDENTIFIERS_NOT_SUPPORTED  = 161,  -- The Server does not support Subscription Identifiers; the subscription is not accepted.
        WILDCARD_SUBSCRIPTIONS_NOT_SUPPORTED    = 162,  -- The Server does not support Wildcard Subscriptions; the subscription is not accepted.
    }

    --- The Property Identifier
    __Sealed__()
    enum "PropertyIdentifier" {
        PAYLOAD_FORMAT_INDICATOR= 1,            -- Byte                 [PUBLISH, Will Properties]
        MESSAGE_EXPIRY_INTERVAL = 2,            -- Four Byte Integer    [PUBLISH, Will Properties]
        CONTENT_TYPE            = 3,            -- UTF-8 Encoded String [PUBLISH, Will Properties]
        RESPONSE_TOPIC          = 8,            -- UTF-8 Encoded String [PUBLISH, Will Properties]
        CORRELATION_DATA        = 9,            -- Binary Data          [PUBLISH, Will Properties]
        SUBSCRIPTION_IDENTIFIER = 11,           -- Variable Byte Integer[PUBLISH, SUBSCRIBE]
        SESSION_EXPIRY_INTERVAL = 17,           -- Four Byte Integer    [CONNECT, CONNACK, DISCONNECT]
        ASSIGNED_CLIENT_IDENTIFIER = 18,        -- UTF-8 Encoded String [CONNACK]
        SERVER_KEEP_ALIVE       = 19,           -- Two Byte Integer     [CONNACK]
        AUTHENTICATION_METHOD   = 21,           -- UTF-8 Encoded String [CONNECT, CONNACK, AUTH]
        AUTHENTICATION_DATA     = 22,           -- Binary Data          [CONNECT, CONNACK, AUTH]
        REQUEST_PROBLEM_INFORMATION = 23,       -- Byte                 [CONNECT]
        WILL_DELAY_INTERVAL     = 24,           -- Four Byte Integer    [Will Properties]
        REQUEST_RESPONSE_INFORMATION = 25,      -- Byte                 [CONNECT]
        RESPONSE_INFORMATION    = 26,           -- UTF-8 Encoded String [CONNECT]
        SERVER_REFERENCE        = 28,           -- UTF-8 Encoded String [CONNACK, DISCONNECT]
        REASON_STRING           = 31,           -- UTF-8 Encoded String [CONNACK, PUBACK, PUBREC, PUBREL, PUBCOMP, SUBACK, UNSUBACK, DISCONNECT, AUTH]
        RECEIVE_MAXIMUM         = 33,           -- Two Byte Integer     [CONNECT, CONNACK]
        TOPIC_ALIAS_MAXIMUM     = 34,           -- Two Byte Integer     [CONNECT, CONNACK]
        TOPIC_ALIAS             = 35,           -- Two Byte Integer     [PUBLISH]
        MAXIMUM_QOS             = 36,           -- Byte                 [CONNACK]
        RETAIN_AVAILABLE        = 37,           -- Byte                 [CONNACK]
        USER_PROPERTY           = 38,           -- UTF-8 String Pair    [CONNECT, CONNACK, PUBLISH, Will Properties, PUBACK, PUBREC, PUBREL, PUBCOMP, SUBSCRIBE, SUBACK, UNSUBSCRIBE, UNSUBACK, DISCONNECT, AUTH]
        MAXIMUM_PACKET_SIZE     = 39,           -- Four Byte Integer    [CONNECT, CONNACK]
        WILDCARD_SUBSCRIPTION_AVAILABLE = 40,   -- Byte                 [CONNACK]
        SUBSCRIPTION_IDENTIFIER_AVAILABLE = 41, -- Byte                 [CONNACK]
        SHARED_SUBSCRIPTION_AVAILABLE = 42,     -- Byte                 [CONNACK]
    }

    -- The Reason code
    __Sealed__() __Shareable__()
    enum "ReasonCode" {
        SUCCESS                 = 0,                    -- CONNACK, PUBACK, PUBREC, PUBREL, PUBCOMP, UNSUBACK, AUTH
        NORMAL_DISCONNECTION    = 0,                    -- DISCONNECT
        GRANTED_QOS_0           = 0,                    -- SUBACK
        GRANTED_QOS_1           = 1,                    -- SUBACK
        GRANTED_QOS_2           = 2,                    -- SUBACK
        DISCONNECT_WITH_WILL_MESSAGE = 4,               -- DISCONNECT
        NO_MATCHING_SUBSCRIBERS = 16,                   -- PUBACK, PUBREC
        NO_SUBSCRIPTION_EXISTED = 17,                   -- UNSUBACK
        CONTINUE_AUTHENTICATION = 24,                   -- AUTH
        RE_AUTHENTICATE         = 25,                   -- AUTH
        UNSPECIFIED_ERROR       = 128,                  -- CONNACK, PUBACK, PUBREC, SUBACK, UNSUBACK, DISCONNECT
        MALFORMED_PACKET        = 129,                  -- CONNACK, DISCONNECT
        PROTOCOL_ERROR          = 130,                  -- CONNACK, DISCONNECT
        IMPLEMENTATION_SPECIFIC_ERROR= 131,             -- CONNACK, PUBACK, PUBREC, SUBACK, UNSUBACK, DISCONNECT
        UNSUPPORTED_PROTOCOL_VERSION = 132,             -- CONNACK
        CLIENT_IDENTIFIER_NOT_VALID  = 133,             -- CONNACK
        BAD_USER_NAME_OR_PASSWORD    = 134,             -- CONNACK
        NOT_AUTHORIZED          = 135,                  -- CONNACK, PUBACK, PUBREC, SUBACK, UNSUBACK, DISCONNECT
        SERVER_UNAVAILABLE      = 136,                  -- CONNACK
        SERVER_BUSY             = 137,                  -- CONNACK, DISCONNECT
        BANNED                  = 138,                  -- CONNACK
        SERVER_SHUTTING_DOWN    = 139,                  -- DISCONNECT
        BAD_AUTHENTICATION_METHOD = 140,                -- CONNACK, DISCONNECT
        KEEP_ALIVE_TIMEOUT      = 141,                  -- DISCONNECT
        SESSION_TAKEN_OVER      = 142,                  -- DISCONNECT
        TOPIC_FILTER_INVALID    = 143,                  -- SUBACK, UNSUBACK, DISCONNECT
        TOPIC_NAME_INVALID      = 144,                  -- CONNACK, PUBACK, PUBREC, DISCONNECT
        PACKET_IDENTIFIER_IN_USE= 145,                  -- PUBACK, PUBREC, SUBACK, UNSUBACK
        PACKET_IDENTIFIER_NOT_FOUND = 146,              -- PUBREL, PUBCOMP
        RECEIVE_MAXIMUM_EXCEEDED    = 147,              -- DISCONNECT
        TOPIC_ALIAS_INVALID     = 148,                  -- DISCONNECT
        PACKET_TOO_LARGE        = 149,                  -- CONNACK, DISCONNECT
        MESSAGE_RATE_TOO_HIGH   = 150,                  -- DISCONNECT
        QUOTA_EXCEEDED          = 151,                  -- CONNACK, PUBACK, PUBREC, SUBACK, DISCONNECT
        ADMINISTRATIVE_ACTION   = 152,                  -- DISCONNECT
        PAYLOAD_FORMAT_INVALID  = 153,                  -- CONNACK, PUBACK, PUBREC, DISCONNECT
        RETAIN_NOT_SUPPORTED    = 154,                  -- CONNACK, DISCONNECT
        QOS_NOT_SUPPORTED       = 155,                  -- CONNACK, DISCONNECT
        USE_ANOTHER_SERVER      = 156,                  -- CONNACK, DISCONNECT
        SERVER_MOVED            = 157,                  -- CONNACK, DISCONNECT
        SHARED_SUBSCRIPTIONS_NOT_SUPPORTED  = 158,      -- SUBACK, DISCONNECT
        CONNECTION_RATE_EXCEEDED= 159,                  -- CONNACK, DISCONNECT
        MAXIMUM_CONNECT_TIME    = 160,                  -- DISCONNECT
        SUBSCRIPTION_IDENTIFIERS_NOT_SUPPORTED  = 161,  -- SUBACK, DISCONNECT
        WILDCARD_SUBSCRIPTIONS_NOT_SUPPORTED    = 162,  -- SUBACK, DISCONNECT
    }

    -- The PUBACK Reason Code
    PubAckReasonCode = {
        [ReasonCode.SUCCESS                 ] = true,
        [ReasonCode.NO_MATCHING_SUBSCRIBERS ] = true,
        [ReasonCode.UNSPECIFIED_ERROR       ] = true,
        [ReasonCode.IMPLEMENTATION_SPECIFIC_ERROR] = true,
        [ReasonCode.NOT_AUTHORIZED          ] = true,
        [ReasonCode.TOPIC_NAME_INVALID      ] = true,
        [ReasonCode.PACKET_IDENTIFIER_IN_USE] = true,
        [ReasonCode.QUOTA_EXCEEDED          ] = true,
        [ReasonCode.PAYLOAD_FORMAT_INVALID  ] = true,
    }

    -- The PUBREL Reason Code
    PubRelReasonCode = {
        [ReasonCode.SUCCESS                 ] = true,
        [ReasonCode.PACKET_IDENTIFIER_NOT_FOUND] = true,
    }

    -- The UNSUBACK Reason Code
    UnsubAckReasonCode = {
        [ReasonCode.SUCCESS ]               = true,
        [ReasonCode.NO_SUBSCRIPTION_EXISTED]= true,
        [ReasonCode.UNSPECIFIED_ERROR]      = true,
        [ReasonCode.IMPLEMENTATION_SPECIFIC_ERROR] = true,
        [ReasonCode.NOT_AUTHORIZED]         = true,
        [ReasonCode.TOPIC_FILTER_INVALID]   = true,
        [ReasonCode.PACKET_IDENTIFIER_IN_USE] = true,
    }

    -- The Authentication Reason Code
    AuthReasonCode = {
        [ReasonCode.SUCCESS] = true,
        [ReasonCode.CONTINUE_AUTHENTICATION] = true,
        [ReasonCode.RE_AUTHENTICATE] = true,
    }

    -- The property collection
    __Sealed__()
    struct "PropertySet" {
        [PropertyIdentifier] = String + Number + struct{ String + Number } + struct { [String] = String }
    }

    --- The Connect will packet
    __Sealed__()
    struct "ConnectWill" {
        { name = "qos",     type = Number },
        { name = "retain",  type = Boolean },
        { name = "topic",   type = String },
        { name = "message", type = String },
        { name = "payload", type = String },

        { name = "properties", type = PropertySet },
    }

    --- The MQTT CONNECT Packet
    __Sealed__()
    struct "ConnectPacket" {
        { name = "level",        type = Number },
        { name = "cleanSession", type = Boolean },      -- MQTT v3.1.1
        { name = "cleanStart",   type = Boolean },      -- MQTT v5.0
        { name = "keepAlive",    type = Number },
        { name = "will",         type = ConnectWill },
        { name = "properties",   type = PropertySet },

        -- Payload
        { name = "clientID",     type = String },
        { name = "userName",     type = String },
        { name = "password",     type = String },
    }

    --- The MQTT CONNACK Packet
    __Sealed__()
    struct "ConnackPacket" {
        { name = "sessionPresent", type = Boolean },
        { name = "returnCode",   type = ConnectReturnCode },
        { name = "properties",   type = PropertySet },
    }

    --- The MQTT PUBLISH Packet
    __Sealed__()
    struct "PublishPacket" {
        { name = "dupFlag",      type = Boolean },
        { name = "qos",          type = QosLevel },
        { name = "retainFlag",   type = Boolean },
        { name = "topicName",    type = String },
        { name = "packetID",     type = Number },
        { name = "payload",      type = String },
        { name = "properties",   type = PropertySet },
    }

    --- The MQTT ACK Packet
    __Sealed__()
    struct "AckPacket" {
        { name = "packetID",     type = Number },
        { name = "reasonCode",   type = ReasonCode },
        { name = "properties",   type = PropertySet },
    }

    __Sealed__()
    struct "TopicFilterOption" {
        { name = "retain", type = Number },
        { name = "rap",    type = Boolean }, -- Retain as Published
        { name = "nolocal",type = Boolean },
        { name = "qos",    type = Number },
    }

    __Sealed__()
    struct "TopicFilter" {
        { name = "topicFilter",  type = String, require = true },
        { name = "requestedQoS", type = Number },
        { name = "options", type = TopicFilterOption },
    }

    __Sealed__()
    struct "TopicFilters" { TopicFilter }

    --- The SUBSCRIBE Packet
    __Sealed__()
    struct "SubscribePacket" {
        { name = "packetID",     type = Number },
        { name = "properties",   type = PropertySet },
        { name = "topicFilters", type = TopicFilters },
    }

    --- The SUBACK Packet
    __Sealed__()
    struct "SubAckPacket" {
        { name = "packetID",     type = Number },
        { name = "properties",   type = PropertySet },
        { name = "returnCodes",  type = struct { SubAckReturnCode } },
    }

    ---------------------------------------------------
    --                    Helper                     --
    ---------------------------------------------------
    PROPERTY_SINGLE_BYTE        = 1
    PROPERTY_TWO_BYTE           = 2
    PROPERTY_FOUR_BYTE          = 3
    PROPERTY_UTF8_STRING        = 4
    PROPERTY_BINARY_DATA        = 5
    PROPERTY_VAR_BYTE           = 6
    PROPERTY_STRING_PAIR        = 7

    PROPERTY_SINGLE_DATA        = 1
    PROPERTY_ARRAY_DATA         = 2
    PROPERTY_HASH_DATA          = 3

    PROPERTY_ID_MAP             = {
        [PropertyIdentifier.PAYLOAD_FORMAT_INDICATOR         ] = PROPERTY_SINGLE_BYTE,
        [PropertyIdentifier.MESSAGE_EXPIRY_INTERVAL          ] = PROPERTY_FOUR_BYTE,
        [PropertyIdentifier.CONTENT_TYPE                     ] = PROPERTY_UTF8_STRING,
        [PropertyIdentifier.RESPONSE_TOPIC                   ] = PROPERTY_UTF8_STRING,
        [PropertyIdentifier.CORRELATION_DATA                 ] = PROPERTY_BINARY_DATA,
        [PropertyIdentifier.SUBSCRIPTION_IDENTIFIER          ] = PROPERTY_VAR_BYTE,
        [PropertyIdentifier.SESSION_EXPIRY_INTERVAL          ] = PROPERTY_FOUR_BYTE,
        [PropertyIdentifier.ASSIGNED_CLIENT_IDENTIFIER       ] = PROPERTY_UTF8_STRING,
        [PropertyIdentifier.SERVER_KEEP_ALIVE                ] = PROPERTY_TWO_BYTE,
        [PropertyIdentifier.AUTHENTICATION_METHOD            ] = PROPERTY_UTF8_STRING,
        [PropertyIdentifier.AUTHENTICATION_DATA              ] = PROPERTY_BINARY_DATA,
        [PropertyIdentifier.REQUEST_PROBLEM_INFORMATION      ] = PROPERTY_SINGLE_BYTE,
        [PropertyIdentifier.WILL_DELAY_INTERVAL              ] = PROPERTY_FOUR_BYTE,
        [PropertyIdentifier.REQUEST_RESPONSE_INFORMATION     ] = PROPERTY_SINGLE_BYTE,
        [PropertyIdentifier.RESPONSE_INFORMATION             ] = PROPERTY_UTF8_STRING,
        [PropertyIdentifier.SERVER_REFERENCE                 ] = PROPERTY_UTF8_STRING,
        [PropertyIdentifier.REASON_STRING                    ] = PROPERTY_UTF8_STRING,
        [PropertyIdentifier.RECEIVE_MAXIMUM                  ] = PROPERTY_TWO_BYTE,
        [PropertyIdentifier.TOPIC_ALIAS_MAXIMUM              ] = PROPERTY_TWO_BYTE,
        [PropertyIdentifier.TOPIC_ALIAS                      ] = PROPERTY_TWO_BYTE,
        [PropertyIdentifier.MAXIMUM_QOS                      ] = PROPERTY_SINGLE_BYTE,
        [PropertyIdentifier.RETAIN_AVAILABLE                 ] = PROPERTY_SINGLE_BYTE,
        [PropertyIdentifier.USER_PROPERTY                    ] = PROPERTY_STRING_PAIR,
        [PropertyIdentifier.MAXIMUM_PACKET_SIZE              ] = PROPERTY_FOUR_BYTE,
        [PropertyIdentifier.WILDCARD_SUBSCRIPTION_AVAILABLE  ] = PROPERTY_SINGLE_BYTE,
        [PropertyIdentifier.SUBSCRIPTION_IDENTIFIER_AVAILABLE] = PROPERTY_SINGLE_BYTE,
        [PropertyIdentifier.SHARED_SUBSCRIPTION_AVAILABLE    ] = PROPERTY_SINGLE_BYTE,
    }

    PROPERTY_ID_VALID           = {
        [PropertyIdentifier.PAYLOAD_FORMAT_INDICATOR         ] = function(val)
            if val ~= 0 and val ~= 1 then
                throw(MQTTException("The payload format indicator data is malformed", ReasonCode.PROTOCOL_ERROR))
            end
            return val
        end,
        [PropertyIdentifier.MESSAGE_EXPIRY_INTERVAL          ] = nil,
        [PropertyIdentifier.CONTENT_TYPE                     ] = nil,
        [PropertyIdentifier.RESPONSE_TOPIC                   ] = nil,
        [PropertyIdentifier.CORRELATION_DATA                 ] = nil,
        [PropertyIdentifier.SUBSCRIPTION_IDENTIFIER          ] = function(val)
            if val == 0 then
                throw(MQTTException("The subscription identifier data is malformed", ReasonCode.PROTOCOL_ERROR))
            end
            return val
        end,
        [PropertyIdentifier.SESSION_EXPIRY_INTERVAL          ] = nil,
        [PropertyIdentifier.ASSIGNED_CLIENT_IDENTIFIER       ] = nil,
        [PropertyIdentifier.SERVER_KEEP_ALIVE                ] = nil,
        [PropertyIdentifier.AUTHENTICATION_METHOD            ] = nil,
        [PropertyIdentifier.AUTHENTICATION_DATA              ] = nil,
        [PropertyIdentifier.REQUEST_PROBLEM_INFORMATION      ] = function(val)
            if val ~= 0 and val ~= 1 then
                throw(MQTTException("The request problem information data is malformed", ReasonCode.PROTOCOL_ERROR))
            end
            return val
        end,
        [PropertyIdentifier.WILL_DELAY_INTERVAL              ] = nil,
        [PropertyIdentifier.REQUEST_RESPONSE_INFORMATION     ] = function(val)
            if val ~= 0 and val ~= 1 then
                throw(MQTTException("The request response information data is malformed", ReasonCode.PROTOCOL_ERROR))
            end
            return val
        end,
        [PropertyIdentifier.RESPONSE_INFORMATION             ] = nil,
        [PropertyIdentifier.SERVER_REFERENCE                 ] = nil,
        [PropertyIdentifier.REASON_STRING                    ] = nil,
        [PropertyIdentifier.RECEIVE_MAXIMUM                  ] = function(val)
            if val == 0 then
                throw(MQTTException("The receive maximum data is malformed", ReasonCode.PROTOCOL_ERROR))
            end
            return val
        end,
        [PropertyIdentifier.TOPIC_ALIAS_MAXIMUM              ] = nil,
        [PropertyIdentifier.TOPIC_ALIAS                      ] = function(val)
            if val == 0 then
                throw(MQTTException("The topic alias data is malformed", ReasonCode.PROTOCOL_ERROR))
            end
            return val
        end,
        [PropertyIdentifier.MAXIMUM_QOS                      ] = function(val)
            if val ~= 0 and val ~= 1 then
                throw(MQTTException("The maximum QoS data is malformed", ReasonCode.PROTOCOL_ERROR))
            end
            return val
        end,
        [PropertyIdentifier.RETAIN_AVAILABLE                 ] = function(val)
            if val ~= 0 and val ~= 1 then
                throw(MQTTException("The retain available data is malformed", ReasonCode.PROTOCOL_ERROR))
            end
            return val
        end,
        [PropertyIdentifier.USER_PROPERTY                    ] = nil,
        [PropertyIdentifier.MAXIMUM_PACKET_SIZE              ] = function(val)
            if val == 0 then
                throw(MQTTException("The maximum packet size data is malformed", ReasonCode.PROTOCOL_ERROR))
            end
            return val
        end,
        [PropertyIdentifier.WILDCARD_SUBSCRIPTION_AVAILABLE  ] = function(val)
            if val ~= 0 and val ~= 1 then
                throw(MQTTException("The wildcard subscription available data is malformed", ReasonCode.PROTOCOL_ERROR))
            end
            return val
        end,
        [PropertyIdentifier.SUBSCRIPTION_IDENTIFIER_AVAILABLE] = function(val)
            if val ~= 0 and val ~= 1 then
                throw(MQTTException("The subscription identifier available data is malformed", ReasonCode.PROTOCOL_ERROR))
            end
            return val
        end,
        [PropertyIdentifier.SHARED_SUBSCRIPTION_AVAILABLE    ] = function(val)
            if val ~= 0 and val ~= 1 then
                throw(MQTTException("The shared subscription available data is malformed", ReasonCode.PROTOCOL_ERROR))
            end
            return val
        end,
    }

    PROPERTY_ID_TYPE             = {
        [PropertyIdentifier.PAYLOAD_FORMAT_INDICATOR         ] = PROPERTY_SINGLE_DATA,
        [PropertyIdentifier.MESSAGE_EXPIRY_INTERVAL          ] = PROPERTY_SINGLE_DATA,
        [PropertyIdentifier.CONTENT_TYPE                     ] = PROPERTY_SINGLE_DATA,
        [PropertyIdentifier.RESPONSE_TOPIC                   ] = PROPERTY_SINGLE_DATA,
        [PropertyIdentifier.CORRELATION_DATA                 ] = PROPERTY_SINGLE_DATA,
        [PropertyIdentifier.SUBSCRIPTION_IDENTIFIER          ] = PROPERTY_ARRAY_DATA,
        [PropertyIdentifier.SESSION_EXPIRY_INTERVAL          ] = PROPERTY_SINGLE_DATA,
        [PropertyIdentifier.ASSIGNED_CLIENT_IDENTIFIER       ] = PROPERTY_SINGLE_DATA,
        [PropertyIdentifier.SERVER_KEEP_ALIVE                ] = PROPERTY_SINGLE_DATA,
        [PropertyIdentifier.AUTHENTICATION_METHOD            ] = PROPERTY_SINGLE_DATA,
        [PropertyIdentifier.AUTHENTICATION_DATA              ] = PROPERTY_SINGLE_DATA,
        [PropertyIdentifier.REQUEST_PROBLEM_INFORMATION      ] = PROPERTY_SINGLE_DATA,
        [PropertyIdentifier.WILL_DELAY_INTERVAL              ] = PROPERTY_SINGLE_DATA,
        [PropertyIdentifier.REQUEST_RESPONSE_INFORMATION     ] = PROPERTY_SINGLE_DATA,
        [PropertyIdentifier.RESPONSE_INFORMATION             ] = PROPERTY_SINGLE_DATA,
        [PropertyIdentifier.SERVER_REFERENCE                 ] = PROPERTY_SINGLE_DATA,
        [PropertyIdentifier.REASON_STRING                    ] = PROPERTY_SINGLE_DATA,
        [PropertyIdentifier.RECEIVE_MAXIMUM                  ] = PROPERTY_SINGLE_DATA,
        [PropertyIdentifier.TOPIC_ALIAS_MAXIMUM              ] = PROPERTY_SINGLE_DATA,
        [PropertyIdentifier.TOPIC_ALIAS                      ] = PROPERTY_SINGLE_DATA,
        [PropertyIdentifier.MAXIMUM_QOS                      ] = PROPERTY_SINGLE_DATA,
        [PropertyIdentifier.RETAIN_AVAILABLE                 ] = PROPERTY_SINGLE_DATA,
        [PropertyIdentifier.USER_PROPERTY                    ] = PROPERTY_HASH_DATA,
        [PropertyIdentifier.MAXIMUM_PACKET_SIZE              ] = PROPERTY_SINGLE_DATA,
        [PropertyIdentifier.WILDCARD_SUBSCRIPTION_AVAILABLE  ] = PROPERTY_SINGLE_DATA,
        [PropertyIdentifier.SUBSCRIPTION_IDENTIFIER_AVAILABLE] = PROPERTY_SINGLE_DATA,
        [PropertyIdentifier.SHARED_SUBSCRIPTION_AVAILABLE    ] = PROPERTY_SINGLE_DATA,
    }

    -- Gets the single byte from data
    function parseByte(data, offset)
        return strbyte(data, offset), offset + 1
    end

    -- Get the length prefix from data
    function parseUInt16(data, offset)
        local msb, lsb          = strbyte(data, offset, offset + 1)
        if msb and lsb then
            return msb * 0x100 + lsb, offset + 2
        end
    end

    --- Get the variable length from data
    function parseVarLength(data, offset)
        local mult              = 1
        local length            = 0

        repeat
            local byte          = strbyte(data, offset)
            if not byte then return end

            length              = length + band(byte, 127) * mult
            if length > MAX_VAR_LENGTH then return end

            mult                = mult * 128
            offset              = offset + 1
        until band(byte, 128) == 0

        return length, offset
    end

    -- Get the variable length in the fixed header
    function parseSocketVarLength(socket)
        local mult              = 1
        local length            = 0

        repeat
            local byte          = socket:Receive(1)
            if not byte then return end

            byte                = strbyte(byte)

            length              = length + band(byte, 127) * mult
            if length > MAX_VAR_LENGTH then return end

            mult                = mult * 128
        until band(byte, 128) == 0

        return length
    end

    -- Get the binary data
    function parseBinaryData(data, offset)
        local length, offset    = parseUInt16(data, offset)
        if not length then return end

        data                    = data:sub(offset, offset + length - 1)
        if #data ~= length then return end
        return data, offset + length
    end

    --- Get the UTF8 String
    function parseUTF8String(data, offset)
        local data, offset      = parseBinaryData(data, offset)
        if not data then return end

        for _, code in UTF8Encoding.Decodes(data) do
            if code == 0 or (code >= 0x1 and code <= 0x1f) or (code >= 0x7f and code <= 0x9f) then
                return
            end
        end

        return data, offset
    end

    --- Get property identifier and content
    function parseProperties(data, offset)
        local length, offset    = parseVarLength(data, offset)

        if not length then
            throw(MQTTException("The property length is malformed", ReasonCode.MALFORMED_PACKET))
        end

        local nxtoffset         = offset +  length

        local temp              = {}
        local id, key, val
        while offset < nxtoffset do
            -- For now, the id is only one-byte, but we need handle it as var byte length
            id, offset          = parseVarLength(data, offset)
            if not id then
                throw(MQTTException("The property identifier is malformed", ReasonCode.MALFORMED_PACKET))
            end

            local ptype         = PROPERTY_ID_TYPE[id]
            local valid         = PROPERTY_ID_VALID[id]

            if temp[id] and ptype == PROPERTY_SINGLE_DATA then
                throw(MQTTException("The " .. PropertyIdentifier(id):gsub("_", " "):lower() .. " can't have multiple data", ReasonCode.PROTOCOL_ERROR))
            end

            local parse         = PROPERTY_ID_MAP[id]
            if not parse then
                throw(MQTTException("The property identifier is not supported", ReasonCode.MALFORMED_PACKET))
            end

            if ptype == PROPERTY_HASH_DATA then
                key, val, offset= PROPERTY_PARSE[parse](data, offset)

                if not (key and val) then
                    throw(MQTTException("The " .. PropertyIdentifier(id):gsub("_", " "):lower() .. " data is malformed", ReasonCode.MALFORMED_PACKET))
                elseif valid then
                    key, val    = valid(key, val)
                end

                temp[id]        = temp[id] or {}
                temp[id][key]   = val
            elseif ptype == PROPERTY_ARRAY_DATA then
                val, offset     = PROPERTY_PARSE[parse](data, offset)

                if not val then
                    throw(MQTTException("The " .. PropertyIdentifier(id):gsub("_", " "):lower() .. " data is malformed", ReasonCode.MALFORMED_PACKET))
                elseif valid then
                    val         = valid(val)
                end

                temp[id]        = temp[id] or {}
                tinsert(temp[id], val)
            else
                val, offset     = PROPERTY_PARSE[parse](data, offset)

                if not val then
                    throw(MQTTException("The " .. PropertyIdentifier(id):gsub("_", " "):lower() .. " data is malformed", ReasonCode.MALFORMED_PACKET))
                elseif valid then
                    val         = valid(val)
                end

                temp[id]        = val
            end
        end

        if offset ~= nxtoffset then
            throw(MQTTException("The property data is malformed", ReasonCode.MALFORMED_PACKET))
        end

        return temp, nxtoffset
    end

    --- Generate the packet
    function makeByte(cache, data)
        tinsert(cache, strchar(data))
        return 1
    end

    function makeUInt16(cache, length)
        local msb, lsb          = rshift(length, 8), band(length, 0xff)
        local offset            = #cache
        cache[offset + 1]       = strchar(msb)
        cache[offset + 2]       = strchar(lsb)
        return 2
    end

    function makeUInt32(cache, data)
        local b1                = rshift(data, 24)
        local b2                = band(rshift(data, 16), 0xff)
        local b3                = band(rshift(data, 8), 0xff)
        local b4                = band(data, 0xff)

        local offset            = #cache
        cache[offset + 1]       = strchar(b1)
        cache[offset + 2]       = strchar(b2)
        cache[offset + 3]       = strchar(b3)
        cache[offset + 4]       = strchar(b4)

        return 4
    end

    -- Also works for the UTF-8 string
    function makeBinaryData(cache, data)
        local length            = #data

        local msb, lsb          = rshift(length, 8), band(length, 0xff)
        local offset            = #cache
        cache[offset + 1]       = strchar(msb)
        cache[offset + 2]       = strchar(lsb)
        cache[offset + 3]       = data

        return 2 + length
    end

    makeUTF8String = makeBinaryData

    function makeVarLength(cache, length)
        local result

        if not length and type(cache) == "number" then
            length              = cache
            cache               = nil
            result              = ""
        end

        if length < 0 or length > MAX_VAR_LENGTH then
            throw(MQTTException("value is invalid for encoding as variable length field: "..tostring(length), ReasonCode.MALFORMED_PACKET))
        end

        local offset            = cache and #cache
        local i                 = 0
        repeat
            local byte          = length % 128
            length              = rshift(length, 7)
            if length > 0 then
                byte            = bor(byte, 128)
            end
            i                   = i + 1
            if cache then
                cache[offset+i] = strchar(byte)
            else
                result          = result .. strchar(byte)
            end
        until length <= 0
        if cache then
            return i
        else
            return result, i
        end
    end

    function makeProperties(cache, data)
        if not type(data) == "table" then return 0 end

        -- Keep the property id in order
        local keys              = XDictionary(data).Keys:ToList():Sort()
        if #keys == 0 then return 0 end

        local lengidx           = #cache + 1
        local total             = 0
        local lencnt

        cache[lengidx]          = ""    -- wait for the real value

        for _, id in keys:GetIterator() do
            local ptype         = PROPERTY_ID_TYPE[id]
            local make          = PROPERTY_ID_MAP[id]

            if make then
                make            = PROPERTY_MAKE[make]

                -- just skip the malformed property id for now
                if ptype == PROPERTY_SINGLE_DATA then
                    total       = total + makeVarLength(cache, id)
                    total       = total + make(cache, data[id])
                elseif ptype == PROPERTY_ARRAY_DATA then
                    local temp  = data[id]
                    if type(temp) == "table" and #temp > 0 then
                        for _, val in ipairs(temp) do
                            total = total + makeVarLength(cache, id)
                            total = total + make(cache, val)
                        end
                    end
                elseif ptype == PROPERTY_HASH_DATA then
                    local temp  = data[id]
                    if type(temp) == "table" then
                        for key, val in pairs(temp) do
                            total = total + makeVarLength(cache, id)
                            total = total + make(cache, key, val)
                        end
                    end
                end
            end
        end

        cache[lengidx], lencnt  = makeVarLength(total)

        return total + lencnt
    end

    -- For Mutli packet type
    function parsePubAckAndEtc(data, flag, level)
        local packet            = AckPacket()
        local offset            = 1

        packet.packetID, offset = parseUInt16(data, offset)
        if not packet.packetID then
            throw(MQTTException("The packet identifier can't be found", ReasonCode.MALFORMED_PACKET))
        end

        if level == ProtocolLevel.V5_0 then
            -- Reason Code
            packet.reasonCode, offset = parseByte(data, offset)
            if not packet.reasonCode then
                packet.reasonCode = 0 -- Success
            else
                if not PubAckReasonCode[packet.reasonCode] then
                    throw(MQTTException("The reason code is malformed", ReasonCode.PROTOCOL_ERROR))
                end

                -- PubAck Properties
                if #data >= 4 then
                    packet.properties, offset = parseProperties(data, offset)
                end
            end
        end

        return packet
    end

    function parsePubRelAndEtc(data, flag, level)
        local packet            = AckPacket()
        local offset            = 1

        packet.packetID, offset = parseUInt16(data, offset)
        if not packet.packetID then
            throw(MQTTException("The packet identifier can't be found", ReasonCode.MALFORMED_PACKET))
        end

        if level == ProtocolLevel.V5_0 then
            -- Reason Code
            packet.reasonCode, offset = parseByte(data, offset)
            if not packet.reasonCode then
                packet.reasonCode = 0 -- Success
            else
                if not PubRelReasonCode[packet.reasonCode] then
                    throw(MQTTException("The reason code is malformed", ReasonCode.PROTOCOL_ERROR))
                end

                -- PubAck Properties
                if #data >= 4 then
                    packet.properties, offset = parseProperties(data, offset)
                end
            end
        end

        return packet
    end

    function makePubAckAndEtc(packet, level, cache)
        local total             = 0

        -- Packet Identifier
        if not packet.packetID then
            throw(MQTTException("The packet identifier is required", ReasonCode.MALFORMED_PACKET))
        end
        total                   = total + makeUInt16(cache, packet.packetID)

        if level == ProtocolLevel.V5_0 and (packet.reasonCode or packet.properties) then
            -- Reason Code
            total               = total + makeByte(cache, packet.reasonCode or 0)
            total               = total + makeProperties(cache, packet.properties)
        end

        return total
    end

    PROPERTY_PARSE              = {
        [PROPERTY_SINGLE_BYTE ] = parseByte,
        [PROPERTY_TWO_BYTE    ] = parseUInt16,
        [PROPERTY_FOUR_BYTE   ] = function(data, offset)
            local b1, b2, b3, b4= strbyte(data, offset, offset + 3)
            if b1 and b2 and b3 and b4 then
                return b1 * 0x1000000 + b2 * 0x10000 + b3 * 0x100 + b4, offset + 4
            end
        end,
        [PROPERTY_UTF8_STRING ] = parseUTF8String,
        [PROPERTY_BINARY_DATA ] = parseBinaryData,
        [PROPERTY_VAR_BYTE    ] = parseVarLength,
        [PROPERTY_STRING_PAIR ] = function(data, offset)
            local key, val
            key, offset         = parseUTF8String(data, offset)
            if not key then return end

            return key, parseUTF8String(data, offset)
        end,
    }

    PROPERTY_MAKE               = {
        [PROPERTY_SINGLE_BYTE ] = makeByte,
        [PROPERTY_TWO_BYTE    ] = makeUInt16,
        [PROPERTY_FOUR_BYTE   ] = makeUInt32,
        [PROPERTY_UTF8_STRING ] = makeUTF8String,
        [PROPERTY_BINARY_DATA ] = makeBinaryData,
        [PROPERTY_VAR_BYTE    ] = makeVarLength,
        [PROPERTY_STRING_PAIR ] = function(cache, key, val)
            return makeBinaryData(cache, key) + makeBinaryData(cache, val)
        end,
    }

    PACKET_PARSE_MAP            = {
        [PacketType.CONNECT]    = function(data, flag)
            local offset        = 1
            local protocol, cflags

            --- Variable Header
            -- Protocol Name
            protocol, offset    = parseUTF8String(data, offset)
            if protocol ~= "MQIsdp" and protocol ~= "MQTT" then
                throw(MQTTException("The protocol is not supported", ReasonCode.PROTOCOL_ERROR))
            end

            --- The Packet Entity
            local packet        = ConnectPacket()

            -- Protocol Level
            packet.level, offset = parseByte(data, offset)
            if not (packet.level and ProtocolLevel(packet.level)) then
                throw(MQTTException("The protocol level is not supported", ReasonCode.UNSUPPORTED_PROTOCOL_VERSION))
            end

            -- Connect Flags
            cflags, offset      = parseByte(data, offset)
            if not cflags or band(cflags, 1) == 1 then
                throw(MQTTException("The reserved data in connect flags is malformed", ReasonCode.MALFORMED_PACKET))
            end

            -- Will
            if band(cflags, 4)  == 4 then
                packet.will     = {
                    qos         = rshift(band(cflags, 24), 3),
                    retain      = band(cflags, 32)  == 32,
                }

                if packet.will.qos > 2 then
                    throw(MQTTException("The will QoS is malformed", ReasonCode.MALFORMED_PACKET))
                end
            end

            -- Keep Alive
            packet.keepAlive, offset = parseUInt16(data, offset)

            if packet.level == ProtocolLevel.V5_0 then -- MQTT 5.0 Only
                packet.cleanStart = band(cflags, 2)   == 2

                -- CONNECT Properties
                packet.properties, offset = parseProperties(data, offset)
            else
                packet.cleanSession = band(cflags, 2)   == 2
            end

            --- Payload
            -- Client Identifier
            packet.clientID, offset = parseUTF8String(data, offset)
            if not packet.clientID then
                throw(MQTTException("The client identifier is malformed", ReasonCode.MALFORMED_PACKET))
            end

            if packet.will then
                -- Will Property
                if packet.level == ProtocolLevel.V5_0 then
                    packet.will.properties, offset   = parseProperties(data, offset)
                end

                -- Will Topic
                packet.will.topic, offset  = parseUTF8String(data, offset)
                if not packet.will.topic then
                    throw(MQTTException("The will topic data don't match the length", ReasonCode.MALFORMED_PACKET))
                end

                -- Will Message|Payload
                if packet.level == ProtocolLevel.V5_0 then
                    packet.will.payload, offset = (packet.will.properties[PropertyIdentifier.PAYLOAD_FORMAT_INDICATOR] == 1 and parseUTF8String or parseBinaryData)(data, offset)
                    if not packet.will.payload then
                        throw(MQTTException("The will payload is malformed", ReasonCode.MALFORMED_PACKET))
                    end
                else
                    packet.will.message, offset = parseBinaryData(data, offset)
                    if not packet.will.message then
                        throw(MQTTException("The will message is malformed", ReasonCode.MALFORMED_PACKET))
                    end
                end
            end

            -- User Name
            if band(cflags, 128) == 128 then
                packet.userName, offset = parseUTF8String(data, offset)
                if not packet.userName then
                    throw(MQTTException("The user name is malformed", ReasonCode.MALFORMED_PACKET))
                end
            end

            -- Password
            if band(cflags, 64) == 64 then
                packet.password, offset = parseBinaryData(data, offset)
                if not packet.password then
                    throw(MQTTException("The password is malformed", ReasonCode.MALFORMED_PACKET))
                end
            end

            return packet
        end,
        [PacketType.CONNACK]    = function(data, flag, level)
            local offset        = 1
            local ack

            -- Connect Acknowledge Flags
            ack, offset         = parseByte(data, offset)

            if not ack then
                throw(MQTTException("The connack packet is malformed", ReasonCode.MALFORMED_PACKET))
            end

            local packet        = ConnackPacket()
            packet.sessionPresent = band(ack, 1) == 1

            -- Reason Code
            packet.returnCode, offset = parseByte(data, offset)
            if not (packet.returnCode and ConnectReturnCode(packet.returnCode)) then
                throw(MQTTException("The connack return code is malformed", ReasonCode.MALFORMED_PACKET))
            elseif level == ProtocolLevel.V5_0 then
                if packet.returnCode > 0 and packet.returnCode < 128 then
                    throw(MQTTException("The connack return code is malformed", ReasonCode.MALFORMED_PACKET))
                end
            elseif packet.returnCode > 5 then
                throw(MQTTException("The connack return code is malformed", ReasonCode.MALFORMED_PACKET))
            end

            -- CONNACK Properties
            if level == ProtocolLevel.V5_0 then
                packet.properties, offset = parseProperties(data, offset)
            end

            return packet
        end,
        [PacketType.PUBLISH]    = function(data, flag, level)
            local packet        = PublishPacket()

            packet.dupFlag      = band(flag, 8) == 8        -- byte 4
            packet.qos          = rshift(band(flag, 6), 1)  -- byte 3-2
            packet.retainFlag   = band(flag, 1) == 1        -- byte 1

            if packet.qos == 3 then
                throw(MQTTException("The publish QoS is malformed", ReasonCode.MALFORMED_PACKET))
            end

            local offset        = 1

            -- Topic name
            packet.topicName, offset = parseUTF8String(data, offset)
            if not packet.topicName then
                throw(MQTTException("The topic name in publish packet is malformed", ReasonCode.MALFORMED_PACKET))
            end

            -- Packet Identifier
            if packet.qos > 0 then
                packet.packetID, offset = parseUInt16(data, offset)
                if not packet.packetID then
                    throw(MQTTException("The packet identifier in publish packet is malformed", ReasonCode.MALFORMED_PACKET))
                end
            end

            -- Publish Properties
            if level == ProtocolLevel.V5_0 then
                packet.properties, offset = parseProperties(data, offset)
            end

            -- Payload
            packet.payload      = data:sub(offset, -1)

            return packet
        end,
        [PacketType.PUBACK]     = parsePubAckAndEtc,
        [PacketType.PUBREC]     = parsePubAckAndEtc,
        [PacketType.PUBREL]     = function(data, flag, level)
            if flag ~= 2 then
                throw(MQTTException("The PUBREL flag is malformed", ReasonCode.MALFORMED_PACKET))
            end

            return parsePubRelAndEtc(data, flag, level)
        end,
        [PacketType.PUBCOMP]    = parsePubRelAndEtc,
        [PacketType.SUBSCRIBE]  = function(data, flag, level)
            if flag ~= 2 then
                throw(MQTTException("The subscribe flag is malformed", ReasonCode.MALFORMED_PACKET))
            end

            local packet        = SubscribePacket()
            local count         = #data
            local offset        = 1

            packet.packetID, offset = parseUInt16(data, 1)

            if not packet.packetID then
                throw(MQTTException("The packet identifier can't be found", ReasonCode.MALFORMED_PACKET))
            end

            if level == ProtocolLevel.V5_0 then
                -- SUBSCRIBE Properties
                packet.properties, offset = parseProperties(data, offset)
            end

            -- Topic Filters
            packet.topicFilters = {}

            local packetIdx     = 0

            while offset < count do
                local filter    = {}

                filter.topicFilter, offset = parseUTF8String(data, offset)
                if not filter.topicFilter then
                    throw(MQTTException("The topic filter data is malformed", ReasonCode.MALFORMED_PACKET))
                end

                if level == ProtocolLevel.V5_0 then
                    local options   = parseByte(data, offset)
                    if not options then
                        throw(MQTTException("The subscription options is malformed", ReasonCode.MALFORMED_PACKET))
                    end

                    packet.options  = {}

                    -- Maximum QoS
                    packet.options.qos = band(options, 3)

                    if packet.options.qos == 3 then
                        throw(MQTTException("The maximum QoS level in subscription options is malformed", ReasonCode.PROTOCOL_ERROR))
                    end

                    -- No Local
                    packet.options.nolocal = band(options, 4) == 4

                    -- Retain as Published
                    packet.options.rap     = band(options, 8) == 8

                    -- Retain Handling
                    packet.options.retain = rshift(band(options, 48), 4)
                    if packet.options.retain == 3 then
                        throw(MQTTException("The retain handling in subscription options is malformed", ReasonCode.PROTOCOL_ERROR))
                    end

                    -- reserved
                    if rshift(options, 6) ~= 0 then
                        throw(MQTTException("The reserved bytes in subscription options is malformed", ReasonCode.PROTOCOL_ERROR))
                    end
                else
                    filter.requestedQoS, offset = parseByte(data, offset)
                    if not filter.requestedQoS or filter.requestedQoS > 2 then
                        throw(MQTTException("The topic filter's requested QoS level is malformed", ReasonCode.MALFORMED_PACKET))
                    end
                end

                packetIdx       = packetIdx + 1
                packet.topicFilters[packetIdx] = filter
            end

            if packetIdx == 0 then
                throw(MQTTException("The topic filters request at least one filter", ReasonCode.MALFORMED_PACKET))
            end

            return packet
        end,
        [PacketType.SUBACK]     = function(data, flag, level)
            local packet        = SubAckPacket()
            local offset        = 1

            packet.packetID, offset = parseUInt16(data, offset)

            if not packet.packetID then
                throw(MQTTException("The packet identifier can't be found", ReasonCode.MALFORMED_PACKET))
            end

            if level == ProtocolLevel.V5_0 then
                -- SUBACK Properties
                packet.properties, offset = parseProperties(data, offset)
            end

            -- Payload - SubAck Return Code
            packet.returnCodes  = {}
            local rcidx         = 0

            local byte          = strbyte(data, offset)
            while byte do
                if SubAckReturnCode(byte) then
                    rcidx       = rcidx + 1
                    packet.returnCodes[rcidx] = byte
                else
                    throw(MQTTException("The sub ack return code is malformed", ReasonCode.MALFORMED_PACKET))
                end

                offset          = offset + 1
                byte            = strbyte(data, offset)
            end

            return packet
        end,
        [PacketType.UNSUBSCRIBE]= function(data, flag, level)
            if flag ~= 2 then
                throw(MQTTException("The unsubscribe flag is malformed", ReasonCode.MALFORMED_PACKET))
            end

            local packet        = SubscribePacket()
            local count         = #data
            local offset        = 1

            packet.packetID, offset = parseUInt16(data, offset)

            if not packet.packetID then
                throw(MQTTException("The packet identifier can't be found", ReasonCode.MALFORMED_PACKET))
            end

            if level == ProtocolLevel.V5_0 then
                packet.properties, offset = parseProperties(data, offset)
            end

            -- Topic Filters
            packet.topicFilters = {}

            local packetIdx     = 0

            while offset < count do
                local filter    = {}
                filter.topicFilter, offset = parseUTF8String(data, offset)
                if not filter.topicFilter then
                    throw(MQTTException("The topic filter data is malformed", ReasonCode.MALFORMED_PACKET))
                end

                packetIdx       = packetIdx + 1
                packet.topicFilters[packetIdx] = filter
            end

            if packetIdx == 0 then
                throw(MQTTException("The topic filters request at least one filter", ReasonCode.MALFORMED_PACKET))
            end

            return packet
        end,
        [PacketType.UNSUBACK]   = function(data, flag, level)
            local packet        = SubAckPacket()
            local offset        = 1

            packet.packetID, offset = parseUInt16(data, offset)
            if not packet.packetID then
                throw(MQTTException("The packet identifier can't be found", ReasonCode.MALFORMED_PACKET))
            end

            if level == ProtocolLevel.V5_0 then
                packet.properties, offset = parseProperties(data, offset)

                -- Payload - Return Code
                packet.returnCodes  = {}
                local rcidx         = 0

                local byte          = strbyte(data, offset)
                while byte do
                    if UnsubAckReasonCode[byte] then
                        rcidx       = rcidx + 1
                        packet.returnCodes[rcidx] = byte
                    else
                        throw(MQTTException("The sub ack return code is malformed", ReasonCode.MALFORMED_PACKET))
                    end

                    offset          = offset + 1
                    byte            = strbyte(data, offset)
                end
            end

            return packet
        end,
        [PacketType.PINGREQ]    = function(data, flag, level)
            return {}
        end,
        [PacketType.PINGRESP]   = function(data, flag, level)
            return {}
        end,
        [PacketType.DISCONNECT] = function(data, flag, level)
            if level == ProtocolLevel.V5_0 then
                local offset    = 1
                local packet    = AckPacket()

                packet.reasonCode, offset = parseByte(data, offset)
                if not packet.reasonCode then
                    packet.reasonCode = ReasonCode.SUCCESS
                elseif #data > offset then
                    packet.properties, offset = parseProperties(data, offset)
                end
            else
                return {}
            end
        end,
        [PacketType.AUTH]       = function(data, flag, level)
            if level == ProtocolLevel.V5_0 then
                if flag ~= 0 then
                    throw(MQTTException("The flag in auth packet is malformed", ReasonCode.MALFORMED_PACKET))
                end

                local offset    = 1
                local packet    = AckPacket()

                packet.reasonCode, offset = parseByte(data, offset)
                if not packet.reasonCode then
                    packet.reasonCode = ReasonCode.SUCCESS
                else
                    if not AuthReasonCode[packet.reasonCode] then
                        throw(MQTTException("The authentication reason code is malformed", ReasonCode.MALFORMED_PACKET))
                    end

                    if #data > offset then
                        packet.properties, offset = parseProperties(data, offset)
                    end
                end

                return packet
            else
                throw(MQTTException("The auth packet type can't be used in MQTT v3.1.1", ReasonCode.PROTOCOL_ERROR))
            end
        end
    }

    PACKET_MAKE_MAP             = {
        [PacketType.CONNECT]    = function(packet, level, cache)
            local total         = 0

            -- Protocol Name
            if level == ProtocolLevel.V3_1 or packet.level == ProtocolLevel.V3_1 then
                total           = total + makeUTF8String(cache, "MQIsdp")
            else
                total           = total + makeUTF8String(cache, "MQTT")
            end

            -- Protocol Level
            total               = total + makeByte(cache, packet.level or ProtocolLevel.V3_1_1)

            -- Connect Flags
            local cflags        = 0
            if packet.cleanSession or packet.cleanStart then cflags = bor(cflags, 2)   end
            if packet.password then cflags = bor(cflags, 64)  end
            if packet.userName then cflags = bor(cflags, 128) end

            if packet.will then
                cflags          = bor(cflags, 4)
                if packet.will.qos    then cflags = bor(cflags, lshift(packet.will.qos, 3)) end
                if packet.will.retain then cflags = bor(cflags, 32)  end
            end

            total               = total + makeByte(cache, cflags)

            -- Keep Alive
            total               = total + makeUInt16(cache, packet.keepAlive or 0)

            if packet.level == ProtocolLevel.V5_0 then -- MQTT 5.0 Only
                -- CONNECT Properties
                total           = total + makeProperties(cache, packet.properties)
            end

            --- Payload
            -- Client Identifier
            if not packet.clientID then
                throw(MQTTException("The client identifier data is required", ReasonCode.MALFORMED_PACKET))
            end
            total               = total + makeUTF8String(cache, packet.clientID)

            if packet.will then
                -- Will Property
                if packet.level == ProtocolLevel.V5_0 then
                    total       = total + makeProperties(cache, packet.will.properties)
                end

                -- Will Topic
                total           = total + makeUTF8String(cache, packet.will.topic or "")

                -- Will Message|Payload
                if packet.level == ProtocolLevel.V5_0 then
                    total       = total + (packet.will.properties and packet.will.properties[PropertyIdentifier.PAYLOAD_FORMAT_INDICATOR] == 1 and makeUTF8String or makeBinaryData)(cache, packet.will.payload or "")
                else
                    total       = total + makeBinaryData(cache, packet.will.message)
                end
            end

            -- User Name
            if packet.userName then
                total           = total + makeUTF8String(cache, packet.userName)
            end

            -- Password
            if packet.password then
                total           = total + makeUTF8String(cache, packet.password)
            end

            return total
        end,
        [PacketType.CONNACK]    = function(packet, level, cache)
            local total         = 0

            -- Connect Acknowledge Flags
            total               = total + makeByte(cache, packet.sessionPresent and 1 or 0)

            -- Reason Code
            total               = total + makeByte(cache, packet.returnCode or ConnectReturnCode.ACCEPTED)

            -- CONNACK Properties
            if level == ProtocolLevel.V5_0 then
                total           = total + makeProperties(cache, packet.properties)
            end

            return total
        end,
        [PacketType.PUBLISH]    = function(packet, level, cache)
            local total         = 0

            local flags         = 0

            if packet.dupFlag    then flags = bor(flags, 8) end
            if packet.qos        then flags = bor(flags, lshift(packet.qos, 1)) end
            if packet.retainFlag then flags = bor(flags, 1) end

            -- Topic name
            total               = total + makeUTF8String(cache, packet.topicName or "")

            -- Packet Identifier
            if packet.qos > 0 then
                if not packet.packetID then
                    throw(MQTTException("The packet identifier is required", ReasonCode.MALFORMED_PACKET))
                end
                total           = total + makeUInt16(cache, packet.packetID)
            end

            -- Publish Properties
            if level == ProtocolLevel.V5_0 then
                total           = total + makeProperties(cache, packet.properties)
            end

            -- Payload
            tinsert(cache, packet.payload or "")
            total               = total + (packet.payload and #packet.payload or 0)

            return total, flags
        end,
        [PacketType.PUBACK]     = makePubAckAndEtc,
        [PacketType.PUBREC]     = makePubAckAndEtc,
        [PacketType.PUBREL]     = function(packet, level, cache)
            return makePubAckAndEtc(packet, level, cache), 2
        end,
        [PacketType.PUBCOMP]    = makePubAckAndEtc,
        [PacketType.SUBSCRIBE]  = function(packet, level, cache)
            local total         = 0

            -- Packet Identifier
            if not packet.packetID then
                throw(MQTTException("The packet identifier is required", ReasonCode.MALFORMED_PACKET))
            end
            total               = total + makeUInt16(cache, packet.packetID)

            if level == ProtocolLevel.V5_0 then
                -- SUBSCRIBE Properties
                total           = total + makeProperties(cache, packet.properties)
            end

            -- Topic Filters
            if type(packet.topicFilters) ~= "table" or #packet.topicFilters == 0 then
                throw(MQTTException("The topic filters request at least one filter", ReasonCode.MALFORMED_PACKET))
            end

            for _, filter in ipairs(packet.topicFilters) do
                if not filter.topicFilter then
                    throw(MQTTException("The topic filter data is malformed", ReasonCode.MALFORMED_PACKET))
                end

                total           = total + makeUTF8String(cache, filter.topicFilter)

                if level == ProtocolLevel.V5_0 then
                    local options   = 0

                    if type(packet.options) == "table" then
                        -- Maximum QoS
                        options     = bor(options, packet.options.qos or 0)

                        -- No Local
                        if packet.options.nolocal then options = bor(options, 4) end

                        -- Retain as Published
                        if packet.options.rap then options = bor(options, 8) end

                        -- Retain Handling
                        options     = bor(options, lshift(packet.options.retain or 0, 4))
                    end

                    total       = total + makeByte(cache, options)
                else
                    -- Requested QoS Level
                    total       = total + makeByte(cache, filter.requestedQoS or 0)
                end
            end

            return total, 2
        end,
        [PacketType.SUBACK]     = function(packet, level, cache)
            local total         = 0

            if not packet.packetID then
                throw(MQTTException("The packet identifier is required", ReasonCode.MALFORMED_PACKET))
            end
            total               = total + makeUInt16(cache, packet.packetID)

            if level == ProtocolLevel.V5_0 then
                -- SUBACK Properties
                total           = total + makeProperties(cache, packet.properties)
            end

            -- Payload - SubAck Return Code
            if packet.returnCodes then
                for _, code in ipairs(packet.returnCodes) do
                    total       = total + makeByte(cache, code)
                end
            end

            return total
        end,
        [PacketType.UNSUBSCRIBE]= function(packet, level, cache)
            local total         = 0

            if not packet.packetID then
                throw(MQTTException("The packet identifier is required", ReasonCode.MALFORMED_PACKET))
            end
            total               = total + makeUInt16(cache, packet.packetID)

            if level == ProtocolLevel.V5_0 then
                total           = total + makeProperties(cache, packet.properties)
            end

            -- Topic Filters
            if type(packet.topicFilters) ~= "table" or #packet.topicFilters == 0 then
                throw(MQTTException("The topic filters request at least one filter", ReasonCode.MALFORMED_PACKET))
            end

            for _, filter in ipairs(packet.topicFilters) do
                if not filter.topicFilter then
                    throw(MQTTException("The topic filter data is malformed", ReasonCode.MALFORMED_PACKET))
                end

                total           = total + makeUTF8String(cache, filter.topicFilter)
            end

            return total, 2
        end,
        [PacketType.UNSUBACK]   = function(packet, level, cache)
            local total         = 0

            if not packet.packetID then
                throw(MQTTException("The packet identifier is required", ReasonCode.MALFORMED_PACKET))
            end
            total               = total + makeUInt16(cache, packet.packetID)

            if level == ProtocolLevel.V5_0 then
                total           = total + makeProperties(cache, packet.properties)

                -- Payload - Return Code
                if type(packet.returnCodes) == "table" then
                    for _, code in ipairs(packet.returnCodes) do
                        total   = total + makeByte(cache, code)
                    end
                end
            end

            return total
        end,
        [PacketType.PINGREQ]    = function(packet, level, cache)
            return 0
        end,
        [PacketType.PINGRESP]   = function(packet, level, cache)
            return 0
        end,
        [PacketType.DISCONNECT] = function(packet, level, cache)
            if level == ProtocolLevel.V5_0 then
                local total     = 0

                if packet.reasonCode or packet.properties then
                    total       = total + makeByte(cache, packet.reasonCode or ReasonCode.SUCCESS)
                    total       = total + makeProperties(cache, packet.properties)
                end

                return total
            else
                return 0
            end
        end,
        [PacketType.AUTH]       = function(packet, level, cache)
            if level == ProtocolLevel.V5_0 then
                local total     = 0

                if packet.reasonCode or packet.properties then
                    total       = total + makeByte(cache, packet.reasonCode or ReasonCode.SUCCESS)
                    total       = total + makeProperties(cache, packet.properties)
                end

                return total
            else
                throw(MQTTException("The auth packet type can't be used in MQTT v3.1.1", ReasonCode.PROTOCOL_ERROR))
            end
        end
    }

    ---------------------------------------------------
    --        The MQTT Protocol v3.1.1 & v5.0        --
    ---------------------------------------------------
    System.Net.Protocol "MQTT" {
        make                    = function(ptype, packet, level)
            local map           = PACKET_MAKE_MAP[ptype]
            if not map then return nil end

            local cache         = { "" }

            local count, flags  = map(packet, level, cache)
            cache[1]            = strchar(lshift(ptype, 4) + band(flags or 0, 0xf)) .. makeVarLength(count)

            return tconcat(cache)
        end,
        parse                   =  function(socket, level)
            if type(socket) == "string" then
                -- Parse the Fixed Header
                local control       = strbyte(socket)
                if not control then return end -- timeout

                -- MQTT Control Packet type
                local ptype         = rshift(control, 4)
                local flags         = band(control, 0xF)

                local vlength, offset = parseVarLength(socket, 2)
                if not vlength then
                    throw(MQTTException("The variable length field data is malformed"), ReasonCode.MALFORMED_PACKET)
                end

                if #socket < offset + vlength - 1 then
                    throw(MQTTException("The packet data is malformed"), ReasonCode.MALFORMED_PACKET)
                end

                local map           = PACKET_PARSE_MAP[ptype]
                if not map then
                    throw(MQTTException("The packet control type is not malformed"), ReasonCode.MALFORMED_PACKET)
                end

                return ptype, map(vlength == 0 and "" or socket:sub(offset, offset + vlength -1), flags, level)
            else
                if not isObjectType(socket, ISocket) then
                    throw(MQTTException("The protocol can't read data from the given object"), ReasonCode.MALFORMED_PACKET)
                end

                -- Parse the Fixed Header
                local control       = socket:Receive(1)
                if not control then return end -- timeout

                control             = strbyte(control)

                -- MQTT Control Packet type
                local ptype         = rshift(control, 4)
                local flags         = band(control, 0xF)

                local vlength       = parseSocketVarLength(socket)
                if not vlength then
                    throw(MQTTException("The variable length field data is malformed"), ReasonCode.MALFORMED_PACKET)
                end

                local map           = PACKET_PARSE_MAP[ptype]
                if not map then
                    throw(MQTTException("The packet control type is not malformed"), ReasonCode.MALFORMED_PACKET)
                end

                return ptype, map(vlength == 0 and "" or socket:Receive(vlength), flags, level)
            end
        end
    }
end)