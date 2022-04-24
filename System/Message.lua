--===========================================================================--
--                                                                           --
--                              System Message                               --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2020/09/01                                               --
-- Update Date  :   2020/09/01                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Message"


    --- The interface that represents the publish–subscribe messaging pattern
    __Sealed__()
    interface "IPublisher"              (function(_ENV)
        extend "System.IAutoClose"

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        --- Subscribe a message filter, topic-based, return true if successful, otherwise false and error code is needed
        __Abstract__()
        function SubscribeTopic(self, filter) return true end

        --- Unsubscribe a message filter, topic-based, return true if successful, otherwise false and error code is needed
        __Abstract__()
        function UnsubscribeTopic(self, filter) return true end

        --- Publish the msssage, it'd give a topic if it's topic-based message
        __Abstract__()
        function PublishMessage(self, topic, message) return true end

        --- Receive and return the published message
        __Abstract__()
        function ReceiveMessage(self) end
    end)

    --- A simple Message Publisher that provides the default implementation, only for testing
    __Sealed__()
    class "MessagePublisher"            (function(_ENV)
        extend "IPublisher"

        export { "next", "pairs", Queue }

        local _Publisher                = Toolset.newtable(true)

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- The topic filters
        property "TopicFilters"         { set = false, default = Toolset.newtable }

        --- The received message queue
        property "ReceivedMessageQueue" { set = false, default = function() return Queue() end }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        --- Subscribe a message filter, topic-based, return true if successful, otherwise false and error code is needed
        function SubscribeTopic(self, filter)
            self.TopicFilters[filter]   = true
            _Publisher[self]            = true

            return true
        end

        --- Unsubscribe a message filter, topic-based, return true if successful, otherwise false and error code is needed
        function UnsubscribeTopic(self, filter)
            self.TopicFilters[filter]   = nil

            if not next(self.TopicFilters) then
                _Publisher[self]        = nil
            end

            return true
        end

        --- Publish the msssage, it'd give a topic if it's topic-based message
        function PublishMessage(self, topic, message, ...)
            for publisher in pairs(_Publisher) do
                for filter in pairs(publisher.TopicFilters) do
                    if topic:match(filter) then
                        publisher.ReceivedMessageQueue:Enqueue(topic, message)
                        break
                    end
                end
            end
        end

        --- Receive and return the published message
        function ReceiveMessage(self)
            return self.ReceivedMessageQueue:Dequeue(2)
        end

        --- Close the publisher
        function Close(self)
            _Publisher[self]            = nil
        end
    end)
end)
