--===========================================================================--
--                                                                           --
--                     System.Net.MQTT.MessagePublisher                      --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2020/09/09                                               --
-- Update Date  :   2020/12/03                                               --
-- Version      :   1.1.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Net.MQTT"

    local strtrim               = Toolset.trim

    local function parseToLuaPattern(pattern)
        pattern                 = strtrim(pattern)
        -- The pattern can't be empty and not started with $
        if pattern == "" or pattern:match("^%$") then return end

        return "^" .. pattern:gsub("(.?)%+(.?)", function(a, b)
            if a and a ~= "/" or b and b ~= "/" then
                return a .. "%+" .. b
            else
                return a .. "[^/]*" .. b
            end
        end):gsub("(.?)#$", function(a)
            if not a or a == "/" then
                return a .. ".*"
            end
        end) .. "$"
    end

    --- The message publisher for MQTT protocol
    __Sealed__() interface "IMQTTPublisher" (function(_ENV)
        extend "System.Message.IPublisher"

        export {
            QosLevel, SubAckReturnCode, ReasonCode, Queue,

            pairs               = pairs,
            next                = next,
            min                 = math.min,
            tonumber            = tonumber,
            getmetatable        = getmetatable,
            strtrim             = Toolset.trim,
            wipe                = Toolset.wipe,
            yield               = coroutine.yield,
            rawset              = rawset,

            GetNormalMethod     = Class.GetNormalMethod,
        }

        -----------------------------------------------------------
        --                         event                         --
        -----------------------------------------------------------
        --- Fired when the publisher has topic subscribed
        -- @param topic         the subscribed topic
        -- @param init          whether this is the first topic subscribed
        event "OnTopicSubscribed"

        --- Fired when the publisher has topic unsubscribed
        -- @param topic         the unsubscribed topic
        -- @param last          whether this is the last topic unsubscribed
        event "OnTopicUnsubscribed"


        -----------------------------------------------------------
        --                   abstract property                   --
        -----------------------------------------------------------
        --- The timeout protection for receiving message operations(in seconds)
        __Abstract__() property "Timeout" { type = Number }


        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- When the publisher has topics subscribed
        property "TopicSubscribed"      { type = Boolean }


        -----------------------------------------------------------
        --                   abstract  method                    --
        -----------------------------------------------------------
        --- Save the retain message for a topic
        __Abstract__() function SaveRetainMessage(self, topic, message) end

        --- Delete the retain message from a topic
        __Abstract__() function DeleteRetainMessage(self, topic) end

        --- Return an iterator to get all retain messages for a topic's filter and lua pattern
        __Abstract__() __Iterator__() function GetRetainMessages(self, filter, luaPattern) end

        --- Subscribe a message filter, topic-based, return true if successful, otherwise false and error code is needed
        __Final__() __Arguments__{ NEString, QosLevel/nil }
        function SubscribeTopic(self, filter, qos)
            filter              = strtrim(filter)
            if filter == "" then return SubAckReturnCode.TOPIC_FILTER_INVALID end

            local topicFilters  = self.__TopicFilters

            qos                 = qos or QosLevel.AT_MOST_ONCE
            if topicFilters[filter] then
                topicFilters[filter].qos = qos
                return qos
            end

            local pattern       = parseToLuaPattern(filter)
            if not pattern then return SubAckReturnCode.TOPIC_FILTER_INVALID end

            if self:__SubscribeTopic(filter) then
                local init          = not self.TopicSubscribed

                topicFilters[filter]= { pattern = pattern, qos = qos }
                self.__NewTopicFilters[filter]= true

                self.TopicSubscribed= true
                OnTopicSubscribed(self, filter, init)

                return qos
            else
                return SubAckReturnCode.FAILURE
            end
        end

        --- Unsubscribe a message filter, topic-based, return true if successful, otherwise false and error code is needed
        __Final__() __Arguments__{ NEString/nil }
        function UnsubscribeTopic(self, filter)
            if filter and not self.__TopicFilters[filter] then return ReasonCode.NO_SUBSCRIPTION_EXISTED end

            if self:__UnsubscribeTopic(filter) then
                if filter then
                    self.__TopicFilters[filter]     = nil
                    self.__NewTopicFilters[filter]  = nil
                else
                    wipe(self.__TopicFilters)
                    wipe(self.__NewTopicFilters)
                end

                local last              = next(self.__TopicFilters) == nil
                self.TopicSubscribed    = not last
                OnTopicUnsubscribed(self, filter, last)

                return ReasonCode.SUCCESS
            else
                return ReasonCode.UNSPECIFIED_ERROR
            end
        end

        --- Publish the msssage, it'd give a topic if it's topic-based message
        __Final__() __Arguments__{ NEString, String/nil, QosLevel/nil, Boolean/nil }
        function PublishMessage(self, topic, message, qos, retain)
            if not message or message == "" then
                -- Clear the retain message
                if retain then self:DeleteRetainMessage(topic) end
            else
                qos             = qos or QosLevel.AT_MOST_ONCE
                message         = message .. "^" .. qos

                -- Publish the message
                self:__PublishMessage(topic, message)

                -- Save the retain message to topic
                if retain then self:SaveRetainMessage(topic, message) end
            end
        end

        --- Try Receive and return the published message, return nil if timeout
        __Final__() function ReceiveMessage(self)
            local newTopicFilter= self.__NewTopicFilters
            local topicFilters  = self.__TopicFilters
            local retainMsgQueue= self.__RetainMsgQueue

            -- Fetch the retain message for new subscribed topics
            if next(newTopicFilter) then
                local topics    = {}

                for filter in pairs(newTopicFilter) do
                    local set   = topicFilters[filter]
                    local p     = set.pattern
                    local mqos  = set.qos

                    for topic, message in self:GetRetainMessages(filter, p) do
                        if not topics[topic] then
                            local msg, qos      = message:match("(.*)^(%d+)$")
                            qos                 = qos and tonumber(qos)
                            if msg and qos then
                                topics[topic]   = true
                                retainMsgQueue:Enqueue(topic, msg, min(qos, mqos))
                            end
                        end
                    end
                end

                -- Clear the filters
                wipe(newTopicFilter)
            end

            -- Return the retain messages first
            if retainMsgQueue.Count > 0 then return retainMsgQueue:Dequeue(3) end

            -- Gets the published message
            local topic, message= self:__ReceiveMessage()
            if topic and message then
                local msg, qos  = message:match("(.*)^(%d+)$")
                qos             = qos and tonumber(qos)
                if not (msg and qos) then return end

                -- try match the topic filter
                for _, filter in pairs(topicFilters) do
                    if topic:match(filter.pattern) then
                        return topic, msg, min(qos, filter.qos)
                    end
                end
            end
        end

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- Gets an iterator to return the topic filter, qos and lua pattern
        __Iterator__() function GetTopicFilters(self)
            for filter, set in pairs(self.__TopicFilters) do
                yield(filter, set.qos, set.pattern)
            end
        end

        -----------------------------------------------------------
        --                      initializer                      --
        -----------------------------------------------------------
        function __init(self)
            local cls               = getmetatable(self)

            -- Useful private variables
            rawset(self, "__TopicFilters",     {})
            rawset(self, "__NewTopicFilters",  {})
            rawset(self, "__RetainMsgQueue",   Queue())

            -- The normal method defined by the object's class
            rawset(self, "__SubscribeTopic",   GetNormalMethod(cls, "SubscribeTopic"))
            rawset(self, "__UnsubscribeTopic", GetNormalMethod(cls, "UnsubscribeTopic"))
            rawset(self, "__PublishMessage",   GetNormalMethod(cls, "PublishMessage"))
            rawset(self, "__ReceiveMessage",   GetNormalMethod(cls, "ReceiveMessage"))
        end
    end)

    --- A dummy MQTT Message publisher with no operations, so the client
    -- should handle the topic subscribe by itself
    __Sealed__() class "DummyMQTTPublisher" (function(_ENV)
       extend "IMQTTPublisher"

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        --- Subscribe a message filter, topic-based, return true if successful, otherwise false and error code is needed
        function SubscribeTopic(self, filter) return true end

        --- Unsubscribe a message filter, topic-based, return true if successful, otherwise false and error code is needed
        function UnsubscribeTopic(self, filter) return true end

        --- Publish the msssage, it'd give a topic if it's topic-based message
        function PublishMessage(self, topic, message) return true end

        --- Receive and return the published message
        function ReceiveMessage(self) end
    end)

    --- The simple MQTT Message publisher could be used in single os thread platform
    __Sealed__() class "MQTTPublisher" (function(_ENV)
        inherit "System.Message.MessagePublisher"
        extend "IMQTTPublisher"

        export {
            QosLevel, Queue,

            pairs               = pairs,
            next                = next,
            tonumber            = tonumber,
            yield               = coroutine.yield,
        }

        local _RetainMessages   = {}

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- Save the retain message for a topic
        function SaveRetainMessage(self, topic, message)
            _RetainMessages[topic] = message
        end

        --- Delete the retain message from a topic
        function DeleteRetainMessage(self, topic)
            _RetainMessages[topic] = nil
        end

        --- Return an iterator to get all retain messages for based on a topic filter
        __Iterator__() function GetRetainMessages(self, filter, pattern)
            for topic, message in pairs(_RetainMessages) do
                if not pattern or topic:match(pattern) then
                    yield(topic, message)
                end
            end
        end
    end)
end)