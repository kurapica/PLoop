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

    export {
        List, Exception, System.Text.UTF8Encoding,

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

        throw                   = throw,

        MAX_VAR_LENGTH          = 2^28 - 1,
    }

    --- The MQTT Exception
    __Sealed__()
    class "MQTTException" { Exception }

    --- The MQTT Version
    __Sealed__()
    enum "MQTTVersion" {
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
        MAX_QOS_0               = 0,
        MAX_QOS_1               = 1,
        MAX_QOS_2               = 2,
        FAILURE                 = 0x80,
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
    __Sealed__()
    property "ReasonCode" {
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

    --- The MQTT CONNECT Packet
    __Sealed__()
    struct "ConnectPacket" {
        { name = "version",      type = Number },
        { name = "cleanSession", type = Boolean },      -- MQTT v3.1.1
        { name = "cleanStart",   type = Boolean },      -- MQTT v5.0
        { name = "keepAlive",    type = Number },

        { name = "will",         type = struct {
                { name = "qos",     type = Number },
                { name = "retain",  type = Boolean },
                { name = "topic",   type = String },
                { name = "message", type = String },
                { name = "payload", type = String },

                { name = "properties", type = struct { [PropertyIdentifier] = Any } },
            }
        }

        { name = "properties",   type = struct { [PropertyIdentifier] = Any } },

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
        { name = "properties",   type = struct { [PropertyIdentifier] = Any } },
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
        { name = "properties",   type = struct { [PropertyIdentifier] = Any } },
    }

    --- The MQTT PUBACK Packet
    struct "PubAckPacket" {
        { name = "packetID",     type = Number },
        { name = "reasonCode",   type = ReasonCode },
        { name = "properties",   type = struct { [PropertyIdentifier] = Any } },
    }

    --- The SUBSCRIBE Packet
    __Sealed__()
    struct "SubscribePacket" {
        { name = "packetID",     type = Number },
        { name = "topicFilters", type = struct {
                struct {
                    { name = "topicFilter",  type = String },
                    { name = "requestedQoS", type = Number },
                }
            }
        }
    }

    --- The SUBACK Packet
    __Sealed__()
    struct "SubAckPacket" {
        { name = "packetID",     type = Number },
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
        [PropertyIdentifier.SUBSCRIPTION_IDENTIFIER          ] = nil,
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
        end,,
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
    function parseLength(data, offset)
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
        local length, offset    = parseLength(data, offset)
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

    function makeLength(length)
        local msb, lsb          = rshift(length, 8), band(length, 0xff)
        return strchar(msb), strchar(lsb)
    end

    function makeVarLength(length)
        if length < 0 or length > MAX_VAR_LENGTH then
            throw(MQTTException("value is invalid for encoding as variable length field: "..tostring(length), ReasonCode.MALFORMED_PACKET))
        end

        local bytes             = {}
        local i                 = 1
        repeat
            local byte          = length % 128
            length              = rshift(length, 7)
            if length > 0 then
                byte            = bor(byte, 128)
            end
            bytes[i]            = byte
            i                   = i + 1
        until length <= 0
        return strchar(unpack(bytes))
    end

    PROPERTY_PARSE              = {
        [PROPERTY_SINGLE_BYTE ] = parseByte,
        [PROPERTY_TWO_BYTE    ] = parseLength,
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

    }

    PACKET_PARSE_MAP            = {
        [PacketType.CONNECT]    = function(data, flag)
            local offset        = 1
            local protocol, cflags

            --- Variable Header
            -- Protocol Name
            protocol, offset    = parseBinaryData(data, offset)
            if protocol ~= "MQTT" then
                throw(MQTTException("The protocol is not supported", ReasonCode.PROTOCOL_ERROR))
            end

            --- The Packet Entity
            local packet        = ConnectPacket()

            -- Protocol Level
            packet.version, offset = parseByte(data, offset)
            if packet.version ~= MQTTVersion.V3_1_1 and packet.version ~= MQTTVersion.V5_0 then
                throw(MQTTException("The protocol version is not supported", ReasonCode.UNSUPPORTED_PROTOCOL_VERSION))
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
            packet.keepAlive, offset = parseLength(data, offset)

            -- CONNECT Properties
            if packet.version == MQTTVersion.V5_0 then -- MQTT 5.0 Only
                packet.cleanStart = band(cflags, 2)   == 2

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
                if packet.version == MQTTVersion.V5_0 then
                    packet.will.properties, offset   = parseProperties(data, offset)
                end

                -- Will Topic
                packet.will.topic, offset  = parseUTF8String(data, offset)
                if not packet.will.topic then
                    throw(MQTTException("The will topic data don't match the length", ReasonCode.MALFORMED_PACKET))
                end

                -- Will Message|Payload
                if packet.version == MQTTVersion.V5_0 then
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
        [PacketType.CONNACK]    = function(data, flag, version)
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
            elseif version == MQTTVersion.V5_0 then
                if packet.returnCode > 0 and packet.returnCode < 128 then
                    throw(MQTTException("The connack return code is malformed", ReasonCode.MALFORMED_PACKET))
                end
            elseif packet.returnCode > 5 then
                throw(MQTTException("The connack return code is malformed", ReasonCode.MALFORMED_PACKET))
            end

            -- CONNACK Properties
            if version == MQTTVersion.V5_0 then
                packet.properties, offset = parseProperties(data, offset)
            end

            return packet
        end,
        [PacketType.PUBLISH]    = function(data, flag, version)
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
                packet.packetID, offset = parseLength(data, offset)
                if not packet.packetID then
                    throw(MQTTException("The packet identifier in publish packet is malformed", ReasonCode.MALFORMED_PACKET))
                end
            end

            -- Publish Properties
            if version == MQTTVersion.V5_0 then
                packet.properties, offset = parseProperties(data, offset)
            end

            -- Payload
            packet.payload      = data:sub(offset, -1)

            return packet
        end,
        [PacketType.PUBACK]     = function(data, flag)
            local packet        = PubAckPacket()

            packet.packetID     = parseLength(data, 1)
            if not packet.packetID then
                throw(MQTTException("The packet identifier can't be found", ReasonCode.MALFORMED_PACKET))
            end

            return packet
        end,
        [PacketType.PUBREC]     = function(data, flag)
            local packet        = PubAckPacket()

            packet.packetID     = parseLength(data, 1)
            if not packet.packetID then
                throw(MQTTException("The packet identifier can't be found", ReasonCode.MALFORMED_PACKET))
            end

            return packet
        end,
        [PacketType.PUBREL]     = function(data, flag)
            if flag ~= 2 then
                throw(MQTTException("The pubrel flag is malformed", ReasonCode.MALFORMED_PACKET))
            end

            local packet        = PubAckPacket()

            packet.packetID     = parseLength(data, 1)
            if not packet.packetID then
                throw(MQTTException("The packet identifier can't be found", ReasonCode.MALFORMED_PACKET))
            end

            return packet
        end,
        [PacketType.PUBCOMP]    = function(data, flag)
            local packet        = PubAckPacket()

            packet.packetID     = parseLength(data, 1)
            if not packet.packetID then
                throw(MQTTException("The packet identifier can't be found", ReasonCode.MALFORMED_PACKET))
            end

            return packet
        end,
        [PacketType.SUBSCRIBE]  = function(data, flag)
            if flag ~= 2 then
                throw(MQTTException("The subscribe flag is malformed", ReasonCode.MALFORMED_PACKET))
            end

            local packet        = SubscribePacket()
            local count         = #data
            local offset, length

            packet.packetID, offset = parseLength(data, 1)

            if not packet.packetID then
                throw(MQTTException("The packet identifier can't be found", ReasonCode.MALFORMED_PACKET))
            end

            -- Topic Filters
            packet.topicFilters = {}

            local packetIdx     = 0

            while offset < count do
                length, offset  = parseLength(data, offset)

                if not length then
                    throw(MQTTException("The topic filter length can't be found", ReasonCode.MALFORMED_PACKET))
                end

                local filter    = {}
                filter.topicFilter = data:sub(offset, offset + length - 1)
                if not (filter.topicFilter and #filter.topicFilter == length) then
                    throw(MQTTException("The topic filter don't match the length", ReasonCode.MALFORMED_PACKET))
                end
                offset          = offset + length

                filter.requestedQoS = strbyte(data, offset)
                if not filter.requestedQoS or filter.requestedQoS > 2 then
                    throw(MQTTException("The topic filter's requested QoS level is malformed", ReasonCode.MALFORMED_PACKET))
                end
                offset          = offset + 1

                packetIdx       = packetIdx + 1
                packet.topicFilters[packetIdx] = filter
            end

            if packetIdx == 0 then
                throw(MQTTException("The topic filters request at least one filter", ReasonCode.MALFORMED_PACKET))
            end

            return packet
        end,
        [PacketType.SUBACK]     = function(data, flag)
            local packet        = SubAckPacket()
            local offset, length

            packet.packetID, offset = parseLength(data, 1)

            if not packet.packetID then
                throw(MQTTException("The packet identifier can't be found", ReasonCode.MALFORMED_PACKET))
            end

            -- Payload - SubAck Return Code
            packet.returnCodes  = {}
            local rcidx         = 0

            local byte          = strbyte(data, offset)
            while byte do
                if (byte >= 0 and byte <= 2) or byte == 0x80 then
                    rcidx       = rcidx + 1
                    packet.returnCodes[rcidx] = byte
                else
                    throw(MQTTException("The sub ack return code is malformed", ReasonCode.MALFORMED_PACKET))
                end

                offset          = offset + 1
                byte            = strbyte(data, offset)
            end

            return packetIdx
        end,
        [PacketType.UNSUBSCRIBE]= function(data, flag)
            if flag ~= 2 then
                throw(MQTTException("The unsubscribe flag is malformed", ReasonCode.MALFORMED_PACKET))
            end

            local packet        = SubscribePacket()
            local count         = #data
            local offset, length

            packet.packetID, offset = parseLength(data, 1)

            if not packet.packetID then
                throw(MQTTException("The packet identifier can't be found", ReasonCode.MALFORMED_PACKET))
            end

            -- Topic Filters
            packet.topicFilters = {}

            local packetIdx     = 0

            while offset < count do
                length, offset  = parseLength(data, offset)

                if not length then
                    throw(MQTTException("The topic filter length can't be found", ReasonCode.MALFORMED_PACKET))
                end

                local filter    = {}
                filter.topicFilter = data:sub(offset, offset + length - 1)
                if not (filter.topicFilter and #filter.topicFilter == length) then
                    throw(MQTTException("The topic filter don't match the length", ReasonCode.MALFORMED_PACKET))
                end
                offset          = offset + length

                packetIdx       = packetIdx + 1
                packet.topicFilters[packetIdx] = filter
            end

            if packetIdx == 0 then
                throw(MQTTException("The topic filters request at least one filter", ReasonCode.MALFORMED_PACKET))
            end

            return packet
        end,
        [PacketType.UNSUBACK]   = function(data, flag)
            local packet        = PubAckPacket()

            packet.packetID     = parseLength(data, 1)
            if not packet.packetID then
                throw(MQTTException("The packet identifier can't be found", ReasonCode.MALFORMED_PACKET))
            end

            return packet
        end,
        [PacketType.PINGREQ]    = function(data, flag)
            return {}
        end,
        [PacketType.PINGRESP]   = function(data, flag)
            return {}
        end,
        [PacketType.DISCONNECT] = function(data, flag)
            return {}
        end,
    }

    PACKET_MAKE_MAP             = {
        [PacketType.CONNECT]    = function(packet)
            -- Protocol Name
            local chars         = { strchar(0), strchar(4), "M", "Q", "T", "T" }

            -- Protocol Level
            chars[7]            = packet.version or 4 -- default 3.1.1

            -- Connect Flags
            local cflags        = 0
            if packet.cleanSession or packet.cleanStart then cflags = bor(cflags, 2)   end
            if packet.password     then cflags = bor(cflags, 64)  end
            if packet.userName     then cflags = bor(cflags, 128) end

            if packet.will then
                cflags          = bor(cflags, 4)
                if packet.will.qos    then cflags = bor(cflags, lshift(packet.will.qos, 3)) end
                if packet.will.retain then cflags = bor(cflags, 32)  end
            end

            chars[8]            = strchar(cflags)

            -- Keep Alive
            local msb, lsb      = makeLength(packet.keepAlive or 0)
            chars[9]            = msb
            chars[10]           = lsb

            --- Payload
            local offset        = 11
            local length

            -- Client Identifier
            if not packet.clientID then
                throw(MQTTException("The client identifier data is required", ReasonCode.MALFORMED_PACKET))
            end
            length              = #packet.clientID
            msb, lsb            = makeLength(length)
            chars[offset]       = msb
            chars[offset + 1]   = lsb
            chars[offset + 2]   = packet.clientID
            offset              = offset + 3

            if packet.will then
                -- Will Topic
                length              = packet.will.topic and #packet.will.topic or 0
                msb, lsb            = makeLength(length)
                chars[offset]       = msb
                chars[offset + 1]   = lsb
                chars[offset + 2]   = packet.will.topic or ""
                offset              = offset + 3

                -- Will Message
                length              = packet.will.message and #packet.will.message or 0
                msb, lsb            = makeLength(length)
                chars[offset]       = msb
                chars[offset + 1]   = lsb
                chars[offset + 2]   = packet.will.message or ""
                offset              = offset + 3
            end

            -- User Name
            if packet.userName then
                length              = packet.userName and #packet.userName or 0
                msb, lsb            = makeLength(length)
                chars[offset]       = msb
                chars[offset + 1]   = lsb
                chars[offset + 2]   = packet.userName or ""
                offset              = offset + 3
            end

            -- Password
            if packet.password then
                length              = packet.password and #packet.password or 0
                msb, lsb            = makeLength(length)
                chars[offset]       = msb
                chars[offset + 1]   = lsb
                chars[offset + 2]   = packet.password or ""
                offset              = offset + 3
            end

            return tconcat(chars)
        end,
        [PacketType.CONNACK]    = function(packet)
            return strchar(packet.sessionPresent and 1 or 0, packet.returnCode)
        end,
        [PacketType.PUBLISH]    = function(packet)
            local flags         = 0

            if packet.dupFlag    then flags = bor(flags, 8) end
            if packet.qos        then flags = bor(flags, lshift(packet.qos, 1)) end
            if packet.retainFlag then flags = bor(flags, 1) end

            local chars         = {}

            -- Topic name
            if not packet.topicName then
                throw(MQTTException("The topic name is required", ReasonCode.MALFORMED_PACKET))
            end
            local length        = #packet.topicName
            chars[1], chars[2]  = makeLength(length)
            chars[3]            = packet.topicName

            local offset        = 4

            -- Packet Identifier
            if packet.qos > 0 then
                if not packet.packetID then
                    throw(MQTTException("The packet identifier is required", ReasonCode.MALFORMED_PACKET))
                end

                local msb, lsb  = makeLength(packet.packetID)
                chars[offset]   = msb
                chars[offset+1] = lsb
                offset          = offset + 2
            end

            -- Payload
            chars[offset]       = packet.payload

            return tconcat(chars), flags
        end,
        [PacketType.PUBACK]     = function(packet)
            if not packet.packetID then
                throw(MQTTException("The packet identifier is required", ReasonCode.MALFORMED_PACKET))
            end

            return strchar(makeLength(packet.packetID))
        end,
        [PacketType.PUBREC]     = function(packet)
            if not packet.packetID then
                throw(MQTTException("The packet identifier is required", ReasonCode.MALFORMED_PACKET))
            end

            return strchar(makeLength(packet.packetID))
        end,
        [PacketType.PUBREL]     = function(packet)
            if not packet.packetID then
                throw(MQTTException("The packet identifier is required", ReasonCode.MALFORMED_PACKET))
            end

            return strchar(makeLength(packet.packetID)), 2
        end,
        [PacketType.PUBCOMP]    = function(packet)
            if not packet.packetID then
                throw(MQTTException("The packet identifier is required", ReasonCode.MALFORMED_PACKET))
            end

            return strchar(makeLength(packet.packetID))
        end,
        [PacketType.SUBSCRIBE]  = function(packet)
            if not packet.packetID then
                throw(MQTTException("The packet identifier is required", ReasonCode.MALFORMED_PACKET))
            elseif not (packet.topicFilters and #packet.topicFilters > 0) then
                throw(MQTTException("The topic filters are required", ReasonCode.MALFORMED_PACKET))
            end

            local chars         = { makeLength(packet.packetID) }
            local offset        = 3
            local length, msb, lsb

            for _, filter in ipairs(packet.topicFilters) do
                if not filter.topicFilter then
                    throw(MQTTException("The topic filter is required", ReasonCode.MALFORMED_PACKET))
                end
                length          = #filter.topicFilter
                msb, lsb        = makeLength(length)
                chars[offset]   = msb
                chars[offset+1] = lsb
                chars[offset+2] = filter.topicFilter
                chars[offset+3] = strchar(filter.requestedQoS or 0)
                offset          = offset + 4
            end

            return tconcat(chars), 2
        end,
        [PacketType.SUBACK]     = function(packet)
            if not packet.packetID then
                throw(MQTTException("The packet identifier is required", ReasonCode.MALFORMED_PACKET))
            elseif not (packet.returnCodes and #packet.returnCodes > 0) then
                throw(MQTTException("The return codes are required", ReasonCode.MALFORMED_PACKET))
            end

            local chars         = { makeLength(packet.packetID) }
            chars[3]            = strchar(unpack(packet.returnCodes))

            return tconcat(chars)
        end,
        [PacketType.UNSUBSCRIBE]= function(packet)
            if not packet.packetID then
                throw(MQTTException("The packet identifier is required", ReasonCode.MALFORMED_PACKET))
            elseif not (packet.topicFilters and #packet.topicFilters > 0) then
                throw(MQTTException("The topic filters are required", ReasonCode.MALFORMED_PACKET))
            end

            local chars         = { makeLength(packet.packetID) }
            local offset        = 3
            local length, msb, lsb

            for _, filter in ipairs(packet.topicFilters) do
                if not filter.topicFilter then
                    throw(MQTTException("The topic filter is required", ReasonCode.MALFORMED_PACKET))
                end
                length          = #filter.topicFilter
                msb, lsb        = makeLength(length)
                chars[offset]   = msb
                chars[offset+1] = lsb
                chars[offset+2] = filter.topicFilter
                offset          = offset + 3
            end

            return tconcat(chars), 2
        end,
        [PacketType.UNSUBACK]   = function(packet)
            if not packet.packetID then
                throw(MQTTException("The packet identifier is required", ReasonCode.MALFORMED_PACKET))
            end

            return strchar(makeLength(packet.packetID))
        end,
        [PacketType.PINGREQ]    = function(packet)
            return ""
        end,
        [PacketType.PINGRESP]   = function(packet)
            return ""
        end,
        [PacketType.DISCONNECT] = function(packet)
            return ""
        end,
    }

    ---------------------------------------------------
    --        The MQTT Protocol v3.1.1 & v5.0        --
    ---------------------------------------------------
    Protocol "MQTT" {
        make                    = function(ptype, packet, version)
            local map           = PACKET_MAKE_MAP[ptype]
            if not map then return nil end

            local data, flags   = map(packet, version)
            local control       = lshift(ptype, 4) + band(flags or 0, 0xf)

            return strchar(control) .. makeVarLength(#data) .. data
        end,
        parse                   =  function(socket, version)
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

            return ptype, map(vlength == 0 and "" or socket:Receive(vlength), flags, version)
        end
    }
end)