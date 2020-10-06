--===========================================================================--
--                                                                           --
--                     System.Net.MQTT.MessagePublisher                      --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2020/09/09                                               --
-- Update Date  :   2020/09/09                                               --
-- Version      :   1.0.0                                                    --
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

            GetNormalMethod     = Class.GetNormalMethod,
        }

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- The registered topic filters
        property "TopicFilters"         { set = false, default = Toolset.newtable }

        --- The new registered topic filters used to get the retawin messages
        property "NewTopicFilters"      { set = false, default = Toolset.newtable }

        --- The retain message quque
        property "RetainMessageQuque"   { set = false, default = function() return Queue() end }

        -----------------------------------------------------------
        --                   abstract  method                    --
        -----------------------------------------------------------
        --- Save the retain message for a topic
        __Abstract__() function SaveRetainMessage(self, topic, message) end

        --- Delete the retain message from a topic
        __Abstract__() function DeleteRetainMessage(self, topic) end

        --- Return an iterator to get all retain messages for based on a topic filter
        __Abstract__() __Iterator__() function GetRetainMessages(self, filter) end

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- Subscribe a message filter, topic-based, return true if successful, otherwise false and error code is needed
        __Final__() __Arguments__{ NEString, QosLevel/nil }
        function SubscribeTopic(self, filter, qos)
            filter              = strtrim(filter)
            if filter == "" then return SubAckReturnCode.TOPIC_FILTER_INVALID end

            qos                 = qos or QosLevel.AT_MOST_ONCE
            if self.TopicFilters[filter] then
                self.TopicFilters[filter] = qos
                return qos
            end

            local pattern       = parseToLuaPattern(filter)
            if not pattern then return SubAckReturnCode.TOPIC_FILTER_INVALID end

            if GetNormalMethod(getmetatable(self), "SubscribeTopic")(self, filter) then
                self.TopicFilters[filter]   = { pattern = pattern, qos = qos }
                self.NewTopicFilters[filter]= true

                return qos
            else
                return SubAckReturnCode.FAILURE
            end
        end

        --- Unsubscribe a message filter, topic-based, return true if successful, otherwise false and error code is needed
        __Final__() __Arguments__{ NEString/nil }
        function UnsubscribeTopic(self, filter)
            if filter and not self.TopicFilters[filter] then return ReasonCode.NO_SUBSCRIPTION_EXISTED end

            if GetNormalMethod(getmetatable(self), "UnsubscribeTopic")(self, filter) then
                self.TopicFilters[filter]   = nil
                self.NewTopicFilters[filter]= nil

                return ReasonCode.SUCCESS
            else
                return ReasonCode.UNSPECIFIED_ERROR
            end
        end

        --- Publish the msssage, it'd give a topic if it's topic-based message
        __Final__() __Arguments__{ NEString, String/nil, QosLevel/nil, Boolean/nil }
        function PublishMessage(self, topic, message, qos, retain)
            message             = message or ""
            qos                 = qos or QosLevel.AT_MOST_ONCE

            -- Publish the message
            GetNormalMethod(getmetatable(self), "PublishMessage")(self, topic, message .. "^" .. qos)

            -- Save/Remove the retain message to topic
            if retain then
                if message == "" then
                    self:DeleteRetainMessage(topic)
                else
                    self:SaveRetainMessage(topic, message .. "^" .. qos)
                end
            end
        end

        --- Try Receive and return the published message, return nil if timeout
        __Final__() function ReceiveMessage(self)
            -- Fetch the retain message for new subscribed topics
            if next(self.NewTopicFilters) then
                local topics    = {}

                for filter in pairs(self.NewTopicFilters) do
                    local p     = self.TopicFilters[filter].pattern
                    local mqos  = self.TopicFilters[filter].qos

                    for topic, message in self:GetRetainMessages(filter) do
                        local msg, qos = message:match("(.*)^(%d+)$")
                        qos     = qos and tonumber(qos)

                        if not topics[topic] and msg and qos and topic:match(p) then
                            topics[topic] = true
                            self.RetainMessageQuque:Enqueue(topic, msg, min(qos, mqos))
                        end
                    end
                end

                -- Clear the filters
                wipe(self.NewTopicFilters)
            end

            -- Return the retain messages first
            if self.RetainMessageQuque.Count > 0 then
                return self.RetainMessageQuque:Dequeue(3)
            end

            local topic, message= GetNormalMethod(getmetatable(self), "ReceiveMessage")(self)
            if topic and message then
                local msg, qos  = message:match("(.*)^(%d+)$")
                qos             = qos and tonumber(qos)
                if not (msg and qos) then return end

                -- try match the topic filter
                for _, filter in pairs(self.TopicFilters) do
                    if topic:match(filter.pattern) then
                        return topic, msg, min(qos, filter.qos)
                    end
                end
            end
        end
    end)

    -- The simple MQTT Message publisher could be used in single os thread platform
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
        __Iterator__() function GetRetainMessages(self, filter)
            filter                  = filter and parseToLuaPattern(filter)
            for topic, message in pairs(_RetainMessages) do
                if not filter or topic:match(filter) then
                    yield(topic, message)
                end
            end
        end
    end)
end)