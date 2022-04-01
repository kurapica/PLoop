--===========================================================================--
--                                                                           --
--                   System.Net.Protocol.OPC.Services                        --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2021/08/12                                               --
-- Update Date  :   2021/08/12                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Net.OPC"

    class "Server"                      (function(_ENV)
        property "NamespaceArray"       {
            default                     = {
                [0]                     = "http://opcfoundation.org/UA/",
            }
        }
    end)

    __Sealed__()
    class "Service"                     (function(_ENV)

    end)

    class "DiscoveryService"            { Service }

    class "SecureChannelService"        { Service }

    class "SessionService"              { Service }

    class "NodeManagementService"       { Service }

    class "ViewService"                 { Service }

    class "QueryService"                { Service }

    class "AttributeService"            { Service }

    class "CallService"                 { Service }

    class "MonitoredItemService"        { Service }

    class "SubscriptionService"         { Service }

    class "RequestResponseService"      { Service }

    --- a set of related Services
    __Sealed__()
    class "ServiceSet"                  (function(_ENV)
    end)

    --- defines Services that allow a Client to discover the Endpoints implemented by a Server and to read the security configuration for each of those Endpoints
    class "DiscoveryServiceSet"         { ServiceSet }

    --- defines Services that allow a Client to establish a communication channel to ensure the Confidentiality and Integrity of Messages exchanged with the Server
    class "SecureChannelServiceSet"     { ServiceSet }

    --- defines Services that allow the Client to authenticate the user on whose behalf it is acting and to manage Sessions
    class "SessionServiceSet"           { ServiceSet }

    --- defines Services that allow the Client to add, modify and delete Nodes in the AddressSpace
    class "NodeManagementServiceSet"    { ServiceSet }

    --- defines Services that allow Clients to browse through the AddressSpace or subsets of the AddressSpace called Views.
    -- The Query Service Set allows Clients to get a subset of data from the AddressSpace or the View
    class "ViewServiceSet"              { ServiceSet }

    --- defines Services that allow Clients to read and write Attributes of Nodes, including their historical values
    class "AttributeServiceSet"         { ServiceSet }

    --- defines Services that allow Clients to call methods
    class "MethodServiceSet"            { ServiceSet }

    --- defines Services that allow Clients to create, modify, and delete MonitoredItems used to monitor Attributes for value changes and Objects for Events
    class "MonitoredItemServiceSet"     { ServiceSet }

    --- defines Services that allow Clients to create, modify and delete Subscriptions
    class "SubscriptionServiceSet"      { ServiceSet }
end)