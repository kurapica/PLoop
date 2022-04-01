--===========================================================================--
--                                                                           --
--                   System.Net.Protocol.OPC.EventTypes                      --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2021/08/11                                               --
-- Update Date  :   2021/08/1                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Net.OPC"


    --- BaseEventType
    __Sealed__() __Abstract__() __Node__{ NodeId = 2041 }
    class "BaseEventType"                           { BaseObjectType }

    __Sealed__() __Abstract__() __Node__{ NodeId = 2130 }
    class "SystemEventType"                         { BaseEventType }

    __Sealed__() __Abstract__() __Node__{ NodeId = 11436 }
    class "ProgressEventType"                       { BaseEventType }

    __Sealed__() __Abstract__() __Node__{ NodeId = 2052 }
    class "AuditEventType"                          { BaseEventType }

    __Sealed__() __Abstract__() __Node__{ NodeId = 2058 }
    class "AuditSecurityEventType"                  { AuditEventType }

    __Sealed__() __Abstract__() __Node__{ NodeId = 2059 }
    class "AuditChannelEventType"                   { AuditEventType }

    __Sealed__() __Abstract__() __Node__{ NodeId = 2060 }
    class "AuditOpenSecureChannelEventType"         { AuditChannelEventType }

    __Sealed__() __Abstract__() __Node__{ NodeId = 2069 }
    class "AuditSessionEventType"                   { AuditSecurityEventType }

    __Sealed__() __Abstract__() __Node__{ NodeId = 2071 }
    class "AuditCreateSessionEventType"             { AuditSessionEventType }

    __Sealed__() __Abstract__() __Node__{ NodeId = 2748 }
    class "AuditUrlMismatchEventType"               { AuditCreateSessionEventType }

    __Sealed__() __Abstract__() __Node__{ NodeId = 2075 }
    class "AuditActivateSessionEventType"           { AuditSessionEventType }

    __Sealed__() __Abstract__() __Node__{ NodeId = 2078 }
    class "AuditCancelEventType"                    { AuditSessionEventType }

    __Sealed__() __Abstract__() __Node__{ NodeId = 2080 }
    class "AuditCertificateEventType"               { AuditSecurityEventType }

    __Sealed__() __Abstract__() __Node__{ NodeId = 2082 }
    class "AuditCertificateDataMismatchEventType"   { AuditCertificateEventType }

    __Sealed__() __Abstract__() __Node__{ NodeId = 2085 }
    class "AuditCertificateExpiredEventType"        { AuditCertificateEventType }

    __Sealed__() __Abstract__() __Node__{ NodeId = 2086 }
    class "AuditCertificateInvalidEventType"        { AuditCertificateEventType }

    __Sealed__() __Abstract__() __Node__{ NodeId = 2087 }
    class "AuditCertificateUntrustedEventType"      { AuditCertificateEventType }

    __Sealed__() __Abstract__() __Node__{ NodeId = 2088 }
    class "AuditCertificateRevokedEventType"        {   AuditCertificateEventType }

    __Sealed__() __Abstract__() __Node__{ NodeId = 2089 }
    class "AuditCertificateMismatchEventType"       { AuditCertificateEventType }

    __Sealed__() __Abstract__() __Node__{ NodeId = 2090 }
    class "AuditNodeManagementEventType"            { AuditEventType }

    __Sealed__() __Abstract__() __Node__{ NodeId = 2091 }
    class "AuditAddNodesEventType"                  { AuditNodeManagementEventType }

    __Sealed__() __Abstract__() __Node__{ NodeId = 2093 }
    class "AuditDeleteNodesEventType"               { AuditNodeManagementEventType }

    __Sealed__() __Abstract__() __Node__{ NodeId = 2095 }
    class "AuditAddReferencesEventType"             { AuditNodeManagementEventType }

    __Sealed__() __Abstract__() __Node__{ NodeId = 2097 }
    class "AuditDeleteReferencesEventType"          { AuditNodeManagementEventType }

    __Sealed__() __Abstract__() __Node__{ NodeId = 2099 }
    class "AuditUpdateEventType"                    { AuditEventType }

    __Sealed__() __Abstract__() __Node__{ NodeId = 2100 }
    class "AuditWriteUpdateEventType"               { AuditUpdateEventType }

    __Sealed__() __Abstract__() __Node__{ NodeId = 2104 }
    class "AuditHistoryUpdateEventType"             { AuditUpdateEventType }

    __Sealed__() __Abstract__() __Node__{ NodeId = 2127 }
    class "AuditUpdateMethodEventType"              { AuditEventType }

    __Sealed__() __Abstract__() __Node__{ NodeId = 2131 }
    class "DeviceFailureEventType"                  { SystemEventType }

    __Sealed__() __Abstract__() __Node__{ NodeId = 11446 }
    class "SystemStatusChangeEventType"             { SystemEventType }

    __Sealed__() __Abstract__() __Node__{ NodeId = 2132 }
    class "BaseModelChangeEventType"                { BaseEventType }

    __Sealed__() __Abstract__() __Node__{ NodeId = 2133 }
    class "GeneralModelChangeEventType"             { BaseModelChangeEventType }

    __Sealed__() __Abstract__() __Node__{ NodeId = 2738 }
    class "SemanticChangeEventType"                 { BaseEventType }
end)