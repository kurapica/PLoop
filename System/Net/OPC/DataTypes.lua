--===========================================================================--
--                                                                           --
--                     System.Net.Protocol.OPC.DataTypes                     --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2021/07/30                                               --
-- Update Date  :   2021/07/30                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Net.OPC"

    export { type = type, validateValue = Struct.ValidateValue, isObjectType = Class.IsObjectType, hasNodeInfo = __Node__.HasNodeInfo, getNodeInfo = __Node__.GetNodeInfo, Guid, Node }

    ---------------------------------------------------
    --                 BaseDataType                  --
    ---------------------------------------------------
    --- Boolean
    __Node__.RegisterNode(Boolean,      { NodeId = 1, SubtypeOf = Any })

    --- SByte
    __Node__.RegisterNode(SByte,        { NodeId = 2 })

    --- Byte
    __Node__.RegisterNode(Byte,         { NodeId = 3} )

    --- Int16
    __Node__.RegisterNode(Int16,        { NodeId = 4 })

    -- UInt16
    __Node__.RegisterNode(UInt16,       { NodeId = 5 })

    --- Int32
    __Node__.RegisterNode(Int32,        { NodeId = 6 })

    --- UInt32
    __Node__.RegisterNode(UInt32,       { NodeId = 7 })

    --- Int64
    __Node__.RegisterNode(Int64,        { NodeId = 8 })

    --- UInt64
    __Node__.RegisterNode(UInt64,       { NodeId = 9 })

    --- Float
    __Node__.RegisterNode(Float,        { NodeId = 10 })

    --- Double
    __Node__.RegisterNode(Double,       { NodeId = 11 })

    --- Decimal
    __Node__.RegisterNode(Decimal,      { NodeId = 50 })

    --- String
    __Node__.RegisterNode(String,       { NodeId = 12, SubtypeOf = Any })

    --- BaseDataType <-> Any
    __Node__.RegisterNode(Any,          { NodeId = 24, BrowseName = "basedataType", IsAbstract = true })

    --- Number
    __Node__.RegisterNode(Number,       { NodeId = 26, IsAbstract = true, SubtypeOf = Any })

    --- Enumeration
    __Node__.RegisterNode(Enum,         { NodeId = 29, BrowseName = "enumeratIon", IsAbstract = true, SubtypeOf = Any })

    --- Structure
    __Node__.RegisterNode(Struct,       { NodeId = 22, BrowseName = "structurE", IsAbstract = true, SubtypeOf = Any })

    -- Integer
    __Node__.RegisterNode(Integer,      { NodeId = 27, IsAbstract = true })

    --- UInteger
    __Node__.RegisterNode(NaturalNumber,{ NodeId = 28, BrowseName = "uinteger", IsAbstract = true, SubtypeOf = Number })

    --- DateTime
    __Sealed__() __Node__{ NodeId = 13, SubTypeOf = Any }
    struct "DateTime"           { __base = NaturalNumber }

    --- UtcTime
    __Sealed__() __Node__{ NodeId = 294 }
    struct "UtcTime"            { __base = DateTime }

    --- Guid
    __Node__.RegisterNode(Guid, { NodeId = 14, SubtypeOf = Any })

    --- ByteString
    __Sealed__() __Node__{ NodeId = 15, SubTypeOf = Any }
    struct "ByteString"         { __base = String }

    --- XmlElement @todo: be replaced by real xml element
    __Sealed__() __Node__{ NodeId = 16, SubTypeOf = Any }
    struct "XmlElement"         {}

    --- Duration - an interval of time in milliseconds (fractions can be used to define sub-millisecond values)
    __Sealed__() __Node__{ NodeId = 290 }
    struct "Duration"           { __base = Double }

    --- IntegerId
    __Sealed__() __Node__{ NodeId = 288 }
    struct "IntegerId"          { __base = UInt32 }

    --- VersionTime
    __Sealed__() __Node__{ NodeId = 20998 }
    struct "VersionTime"        { __base = UInt32 }

    ---------------------------------------------------
    --                  Enumeration                  --
    ---------------------------------------------------
    ---- the type of the NodeId, already defined in the Core
    __Sealed__() __Node__{ NodeId = 256 }
    enum "IdType"               {}

    --- the naming rule type
    __Sealed__() __Node__{ NodeId = 120 }
    enum "NamingRuleType"       {}

    --- The node classes
    __Sealed__() __Node__{ NodeId = 257, SubtypeOf = Enum }
    enum "NodeClass"            {
        Unspecified             = 0,
        Object                  = 1,
        Variable                = 2,
        Method                  = 4,
        ObjectType              = 8,
        VariableType            = 16,
        ReferenceType           = 32,
        DataType                = 64,
        View                    = 128,
    }

    --- The attribute write flags
    __Sealed__() __Flags__() __Node__{ NodeId = 347 }
    enum "AttributeWriteMask"   {
        "AccessLevel",
        "ArrayDimensions",
        "BrowseName",
        "ContainsNoLoops",
        "DataType",
        "Description",
        "DisplayName",
        "EventNotifier",
        "Executable",
        "Historizing",
        "InverseName",
        "IsAbstract",
        "MinimumSamplingInterval",
        "NodeClass",
        "NodeId",
        "Symmetric",
        "UserAccessLevel",
        "UserExecutable",
        "UserWriteMask",
        "ValueRank",
        "WriteMask",
        "ValueForVariableType",
        "DataTypeDefinition",
        "RolePermissions",
        "AccessRestrictions",
        "AccessLevelEx",
    }

    --- The Permission type
    __Sealed__() __Flags__() __Node__{ NodeId = 94 }
    enum "PermissionType"       {
        "Browse",
        "ReadRolePermissions",
        "WriteAttribute",
        "WriteRolePermissions",
        "WriteHistorizing",
        "Read",
        "Write",
        "ReadHistory",
        "InsertHistory",
        "ModifyHistory",
        "DeleteHistory",
        "ReceiveEvents",
        "Call",
        "AddReference",
        "RemoveReference",
        "DeleteNode",
        "AddNode",
    }

    --- The Security Token Request Type
    __Sealed__() __Node__{ NodeId = 315 }
    enum "SecurityTokenRequestType" {
        Issue                   = 0,
        Renew                   = 1,
    }

    --- The Message Security Mode
    __Sealed__() __Node__{ NodeId = 302 }
    enum "MessageSecurityMode"  {
        Invalid                 = 0,
        None                    = 1,
        Sign                    = 2,
        SignAndEncrypt          = 3,
    }

    --- The Redundancy Support
    __Sealed__() __Node__{ NodeId = 851 }
    enum "RedundancySupport"    {
        None                    = 0,
        Cold                    = 1,
        Warm                    = 2,
        Hot                     = 3,
        Transparent             = 4,
        HotAndMirrored          = 5,
    }

    --- The Server State
    __Sealed__() __Node__{ NodeId = 852 }
    enum "ServerState"          {
        Running                 = 0,
        Failed                  = 1,
        NoConfiguration         = 2,
        Suspended               = 3,
        Shutdown                = 4,
        Test                    = 5,
        CommunicationFault      = 6,
        Unknown                 = 7,
    }

    --- The Application Type
    __Sealed__() __Node__{ NodeId = 307 }
    enum "ApplicationType"      {
        Server                  = 0,
        Client                  = 1,
        ClientAndServer         = 2,
        DiscoveryServer         = 3,
    }

    --- The Structure Type
    __Sealed__() __Node__{ NodeId = 98 }
    enum "StructureType"        {
        Structure                   = 0,
        StructureWithOptionalFields = 1,
        Union                       = 2,
    }

    --- The Access Restrictions Type
    __Sealed__() __Flags__()
    enum "AccessRestrictionsType" {
        "SigningRequired",      -- The Client can only access the Node when using a SecureChannel which digitally signs all messages.
        "EncryptionRequired",   -- The Client can only access the Node when using a SecureChannel which encrypts all messages.
        "SessionRequired",      -- The Client cannot access the Node when using SessionlessInvoke Service invocation.
    }

    --- The EventNotifier Type
    __Sealed__() __Flags__() __Node__{ NodeId = 15033, SubtypeOf = Byte }
    enum "EventNotifierType"    {
        None                    = 0,
        "SubscribeToEvents",
        "Reserved",
        "HistoryRead",
        "HistoryWrite",
    }

    --- The Access Level Type
    __Sealed__() __Flags__() __Node__{ NodeId = 15031, SubtypeOf = Byte }
    enum "AccessLevelType"      {
        "CurrentRead",
        "CurrentWrite",
        "HistoryRead",
        "HistoryWrite",
        "SemanticChange",
        "StatusWrite",
        "TimestampWrite",
    }

    --- The Access Level ExType
    __Sealed__() __Flags__() __Node__{ NodeId = 15406, SubtypeOf = UInt32 }
    enum "AccessLevelExType"    {
        "CurrentRead",
        "CurrentWrite",
        "HistoryRead",
        "HistoryWrite",
        "SemanticChange",
        "StatusWrite",
        "TimestampWrite",
        "NonatomicRead",
        "NonatomicWrite",
        "WriteFullArrayOnly",
        "NoSubDataTypes",
    }

    --- The Diagnostics Level
    __Sealed__() __Node__{ NodeId = 19723 }
    enum "DiagnosticsLevel"     {
        Basic                   = 0,
        Advanced                = 1,
        Info                    = 2,
        Log                     = 3,
        Debug                   = 4,
    }

    --- The User Token Type
    __Sealed__() __Node__{ NodeId = 303 }
    enum "UserTokenType"        {
        Anonymous               = 0,
        UserName                = 1,
        Certificate             = 2,
        IssuedToken             = 3,
    }

    --- The Identity Criteria Type
    __Sealed__() __Node__{ NodeId = 15632 }
    enum "IdentityCriteriaType" {
        UserName                = 1,
        Thumbprint              = 2,
        Role                    = 3,
        GroupId                 = 4,
        Anonymous               = 5,
        AuthenticatedUser       = 6,
    }

    ---------------------------------------------------
    --               Custom Structure                --
    ---------------------------------------------------
    --- BitFieldMaskDataType
    __Sealed__() __Node__{ NodeId = 11737 }
    struct "BitFieldMaskDataType" { __base = UInt64 }

    --- Index
    __Sealed__() __Node__{ NodeId = 17588 }
    struct "Index"              { __base = UInt32 }

    --- StatusCode
    __Sealed__() __Node__{ NodeId = 19, SubTypeOf = Any }
    struct "StatusCode"         { __base = UInt32 }

    __Sealed__()
    struct "StatusCodes"        { StatusCode }

    --- Image
    __Sealed__() __Node__{ NodeId = 30, IsAbstract = true }
    struct "Image"              { __base = ByteString }

    --- ImageBMP
    __Sealed__() __Node__{ NodeId = 2000 }
    struct "ImageBMP"           { __base = Image }

    --- ImageGIF
    __Sealed__() __Node__{ NodeId = 2001 }
    struct "ImageGIF"           { __base = Image }

    --- ImageJPG
    __Sealed__() __Node__{ NodeId = 2002 }
    struct "ImageJPG"           { __base = Image }

    --- ImagePNG
    __Sealed__() __Node__{ NodeId = 2003 }
    struct "ImagePNG"           { __base = Image }

    --- AudioDataType
    __Sealed__() __Node__{ NodeId = 16307 }
    struct "AudioDataType"      { __base = ByteString }

    --- LocaleId
    __Sealed__() __Node__{ NodeId = 295 }
    struct "LocaleId"           { __base = String }

    __Sealed__()
    struct "LocaleIds"          { LocaleId }

    --- NumericRange
    __Sealed__() __Node__{ NodeId = 291 }
    struct "NumericRange"       { __base = String }

    --- NormalizedString
    __Sealed__() __Node__{ NodeId = 12877 }
    struct "NormalizedString"   { __base = String }

    --- DecimalString
    __Sealed__() __Node__{ NodeId = 12878 }
    struct "DecimalString"      { __base = String }

    --- DurationString - P[n]Y[n]M[n]DT[n]H[n]M[n]S or P[n]W
    __Sealed__() __Node__{ NodeId = 12879 }
    struct "DurationString"     { __base = String }

    --- TimeString
    __Sealed__() __Node__{ NodeId = 12880 }
    struct "TimeString"         { __base = String }

    --- DateString
    __Sealed__() __Node__{ NodeId = 12881 }
    struct "DateString"         { __base = String }

    ---------------------------------------------------
    --               Member Structure                --
    ---------------------------------------------------
    --- The node identifier structure
    __Sealed__() __Node__{ NodeId = 17, SubTypeOf = Any }
    struct "NodeId"             {
        { name = "namespaceIndex", type = UInt16, require = true },  -- The index for a namespace URI
        { name = "identifier",     type = Any,    require = true },  -- The identifier for a Node in the AddressSpace of an OPC UA Server
        { name = "identifierType", type = IdType },                  -- The format and data type of the identifier

        __init                  = function (self)
            self.identifierType = self.identifierType or type(self.identifier) == "number" and IdType.NUMERIC
                or type(self.identifier) == "string" and (validateValue(Guid, self.identifier) and IdType.GUID or IdType.STRING)
                or IdType.OPAQUE
        end
    }

    --- The Expanded NodeId
    __Sealed__() __Node__{ NodeId = 18, SubTypeOf = Any }
    struct "ExpandedNodeId"     {
        { name = "serverIndex",    type = Index,    require = true },  -- The index that identifies the Server that contains the TargetNode, 0 means local server
        { name = "namespaceUri",   type = String },                    -- The URI of the namespace
        { name = "namespaceIndex", type = Index,    require = true },  -- The index for a namespace URI, should be 0 if the namespaceUri is specified
        { name = "identifierType", type = IdType,   require = true },  -- The format and data type of the identifier
        { name = "identifier",     type = Any,      require = true },  -- The identifier for a Node in the AddressSpace of an OPC UA Server
    }

    --- A qualified name
    __Sealed__() __Node__{ NodeId = 20, SubTypeOf = Any }
    struct "QualifiedName"      {
        { name = "namespaceIndex", type = UInt16, require = true },  -- Index that identifies the namespace that defines the name
        { name = "name",           type = String, require = true },  -- The text portion of the QualifiedName, 512 characters
    }

    --- The localizaed text
    __Sealed__() __Node__{ NodeId = 21, SubTypeOf = Any }
    struct "LocalizedText"      {
        { name = "locale", type = LocaleId, require = true },  -- The identifier for the locale (e.g. "en-US")
        { name = "text",   type = String,   require = true },
    }

    __Sealed__()
    struct "LocalizedTexts"     { LocalizedText }

    --- The Data Value
    __Sealed__() __Node__{ NodeId = 23, SubTypeOf = Any }
    struct "DataValue"          {
        { name = "value",             type = Any },                         -- The data value. If the StatusCode indicates an error then the value is to be ignored and the Server shall set it to null.
        { name = "statusCode",        type = StatusCode, require = true },  -- The StatusCode that defines with the Server’s ability to access/provide the value.
        { name = "sourceTimestamp",   type = UtcTime },         -- The source timestamp for the value.
        { name = "sourcePicoSeconds", type = NaturalNumber },   -- Specifies the number of 10 picoseconds (1,0 e-11 seconds) intervals which shall be added to the sourceTimestamp.
        { name = "serverTimestamp",   type = UtcTime },         --  The Server timestamp for the value.
        { name = "serverPicoSeconds", type = NaturalNumber },   -- Specifies the number of 10 picoseconds (1,0 e-11 seconds) intervals which shall be added to the serverTimestamp.
    }

    --- The Diagnostic Info - Vendor-specific diagnostic information.
    __Sealed__() __Node__{ NodeId = 25, SubTypeOf = Any }
    struct "DiagnosticInfo"     {
        { name = "namespaceUri",   type = Int32  },             -- The symbolicId is defined within the context of a namespace, -1 indicates that no string is specified
        { name = "symbolicId",     type = Int32  },             -- The symbolicId shall be used to identify a vendor-specific error or condition; typically the result of some Server internal operation
        { name = "locale",         type = Int32  },             -- The locale part of the vendor-specific localized text describing the symbolic id.
        { name = "localizedText",  type = Int32  },             -- A vendor-specific localized text string describes the symbolic id. The maximum length of this text string is 256 characters.
        { name = "additionalInfo", type = String },             -- Vendor-specific diagnostic information.
        { name = "innerStatusCode",type = StatusCode },         -- The StatusCode from the inner operation.
        { name = "innerDiagnosticInfo", type = DiagnosticInfo },-- The diagnostic info associated with the inner StatusCode.
    }

    __Sealed__()
    struct "DiagnosticInfos"    { DiagnosticInfo }

    --- The type used to convert target, node and nodeId to nodeId for data types
    __Sealed__()
    struct "NodeDataType"       {
        __valid                 = function(self, onlyvalid)
            if hasNodeInfo(self, "NodeId") or validateValue(NodeId, self) or isObjectType(self, Node) then return end
            return onlyvalid or "%s must be OPC node or nodeId or target type with node configs"
        end,
        __init                  = function(self)
            if hasNodeInfo(self) then
                return getNodeInfo(self, "NodeId")
            elseif validateValue(NodeId, self) then
                return self
            elseif isObjectType(self, Node) then
                return self.NodeId
            end
        end
    }

    ---------------------------------------------------
    --               OPC Structure                   --
    ---------------------------------------------------
    __Sealed__() __Node__{ NodeId = 388, SubTypeOf = NodeId }
    struct "SessionAuthenticationToken" { __base = NodeId }


    __Sealed__() __Node__{ NodeId = 296 }
    struct "Argument"           {
        { name = "name",            type = String, require = true },
        { name = "dataType",        type = NodeDataType, require = true },
        { name = "valueRank",       type = Int32, default = -1 },
        { name = "arrayDimensions", type = struct { UInt32 } },
        { name = "description",     type = LocalizedText },
    }

    __Sealed__()
    struct "Arguments"          { Argument }

    --- Common parameters for all requests submitted on a Session
    __Sealed__() __Node__{ NodeId = 389 }
    struct "RequestHeader"      {
        { name = "authenticationToken", type = SessionAuthenticationToken },
        { name = "timestamp",           type = UtcTime },
        { name = "requestHandle",       type = IntegerId },
        { name = "returnDiagnostics",   type = UInt32 },
        { name = "auditEntryId",        type = String },
        { name = "timeoutHint",         type = UInt32 },
        { name = "additionalHeader",    type = Any },
    }

    --- Common parameters for all responses
    __Sealed__() __Node__{ NodeId = 392}
    struct "ResponseHeader"     {
        { name = "timestamp",           type = UtcTime },
        { name = "requestHandle",       type = IntegerId },
        { name = "serviceResult",       type = StatusCode },
        { name = "serviceDiagnostics",  type = DiagnosticInfo },
        { name = "stringTable",         type = Strings },
        { name = "additionalHeader",    type = Any }
    }

    __Sealed__() __Node__{ NodeId = 316, IsAbstract = true }
    struct "UserIdentityToken"  {
        { name = "policyId",        type = String },
    }

    __Sealed__() __Node__{ NodeId = 376 }
    struct "AddNodesItem"       {
        { name = "parentNodeId",    type = ExpandedNodeId },
        { name = "referenceTypeId", type = NodeId },
        { name = "requestedNewNodeId",  type = ExpandedNodeId },
        { name = "browseName",      type = QualifiedName },
        { name = "nodeClass",       type = NodeClass },
        { name = "nodeAttributes",  type = Any },
        { name = "typeDefinition",  type = ExpandedNodeId },
    }

    __Sealed__() __Node__{ NodeId = 379 }
    struct "AddReferencesItem"  {
        { name = "sourceNodeId",    type = NodeId },
        { name = "referenceTypeId", type = NodeId },
        { name = "isForward",       type = Boolean },
        { name = "targetServerUri", type = String },
        { name = "targetNodeId",    type = ExpandedNodeId },
        { name = "targetNodeClass", type = NodeClass },
    }

    __Sealed__() __Node__{ NodeId = 382 }
    struct "DeleteNodesItem"    {
        { name = "nodeId",          type = NodeId },
        { name = "deleteTargetReferences",  type = Boolean },
    }

    __Sealed__() __Node__{ NodeId = 385 }
    struct "DeleteReferencesItem" {
        { name = "sourceNodeId",    type = NodeId },
        { name = "referenceTypeId", type = NodeId },
        { name = "isForward",       type = Boolean },
        { name = "targetNodeId",    type = ExpandedNodeId },
        { name = "deleteBidirectional", type = Boolean },
    }

    __Sealed__() __Node__{ NodeId = 308 }
    struct "ApplicationDescription" {
        { name = "applicationUri",  type = String },
        { name = "productUri",      type = String },
        { name = "applicationName", type = LocalizedText },
        { name = "applicationType", type = ApplicationType },
        { name = "gatewayServerUri",type = String },
        { name = "discoveryProfileUri", type = String },
        { name = "discoveryUrls",   type = Strings },
    }

    __Sealed__()
    struct "ApplicationDescriptions" { ApplicationDescription }

    __Sealed__() __Node__{ NodeId = 338 }
    struct "BuildInfo"          {
        { name = "productUri",      type = String },
        { name = "manufacturerName",type = String },
        { name = "productName",     type = String },
        { name = "softwareVersion", type = String },
        { name = "buildNumber",     type = String },
        { name = "buildDate",       type = UtcTime },
    }

    __Sealed__() __Node__{ NodeId = 853 }
    struct "RedundantServerDataType" {
        { name = "serverId",        type = String },
        { name = "serviceLevel",    type = Byte },
        { name = "serverState",     type = ServerState },
    }

    __Sealed__() __Node__{ NodeId = 856 }
    struct "SamplingIntervalDiagnosticsDataType" {
        { name = "samplingInterval",            type = Duration },
        { name = "monitoredItemCount",          type = UInt32 },
        { name = "maxMonitoredItemCount",       type = UInt32 },
        { name = "disabledMonitoredItemCount",  type = UInt32 },
    }

    __Sealed__() __Node__{ NodeId = 859 }
    struct "ServerDiagnosticsSummaryDataType" {
        { name = "serverViewCount",             type = UInt32 },
        { name = "currentSessionCount",         type = UInt32 },
        { name = "cumulatedSessionCount",       type = UInt32 },
        { name = "securityRejectedSessionCount",type = UInt32 },
        { name = "rejectedSessionCount",        type = UInt32 },
        { name = "sessionTimeoutCount",         type = UInt32 },
        { name = "sessionAbortCount",           type = UInt32 },
        { name = "currentSubscriptionCount",    type = UInt32 },
        { name = "cumulatedSubscriptionCount",  type = UInt32 },
        { name = "publishingIntervalCount",     type = UInt32 },
        { name = "securityRejectedRequestsCount", type = UInt32 },
        { name = "rejectedRequestsCount",       type = UInt32 },
    }

    __Sealed__() __Node__{ NodeId = 862 }
    struct "ServerStatusDataType" {
        { name = "startTime",                   type = UtcTime },
        { name = "currentTime",                 type = UtcTime },
        { name = "state",                       type = ServerState },
        { name = "buildInfo",                   type = BuildInfo },
        { name = "secondsTillShutdown",         type = UInt32 },
        { name = "shutdownReason",              type = LocalizedText },
    }

    __Sealed__() __Node__{ NodeId = 871 }
    struct "ServiceCounterDataType" {
        { name = "totalCount",                  type = UInt32 },
        { name = "errorCount",                  type = UInt32 },
    }

    __Sealed__() __Node__{ NodeId = 865 }
    struct "SessionDiagnosticsDataType" {
        { name = "sessionId",                   type = NodeId },
        { name = "sessionName",                 type = String },
        { name = "clientDescription",           type = ApplicationDescription },
        { name = "serverUri",                   type = String },
        { name = "endpointUrl",                 type = String },
        { name = "localeIds",                   type = LocaleIds },
        { name = "actualSessionTimeout",        type = Duration },
        { name = "maxResponseMessageSize",      type = UInt32 },
        { name = "clientConnectionTime",        type = UtcTime },
        { name = "clientLastContactTime",       type = UtcTime },
        { name = "currentSubscriptionsCount",   type = UInt32 },
        { name = "currentMonitoredItemsCount",  type = UInt32 },
        { name = "currentPublishRequestsInQueue", type = UInt32 },
        { name = "totalRequestCount",           type = ServiceCounterDataType },
        { name = "unauthorizedRequestCount",    type = UInt32 },
        { name = "readCount",                   type = ServiceCounterDataType },
        { name = "historyReadCount",            type = ServiceCounterDataType },
        { name = "writeCount",                  type = ServiceCounterDataType },
        { name = "historyUpdateCount",          type = ServiceCounterDataType },
        { name = "callCount",                   type = ServiceCounterDataType },
        { name = "createMonitoredItemsCount",   type = ServiceCounterDataType },
        { name = "modifyMonitoredItemsCount",   type = ServiceCounterDataType },
        { name = "setMonitoringModeCount",      type = ServiceCounterDataType },
        { name = "setTriggeringCount",          type = ServiceCounterDataType },
        { name = "deleteMonitoredItemsCount",   type = ServiceCounterDataType },
        { name = "createSubscriptionCount",     type = ServiceCounterDataType },
        { name = "modifySubscriptionCount",     type = ServiceCounterDataType },
        { name = "setPublishingModeCount",      type = ServiceCounterDataType },
        { name = "publishCount",                type = ServiceCounterDataType },
        { name = "republishCount",              type = ServiceCounterDataType },
        { name = "transferSubscriptionsCount",  type = ServiceCounterDataType },
        { name = "deleteSubscriptionsCount",    type = ServiceCounterDataType },
        { name = "addNodesCount",               type = ServiceCounterDataType },
        { name = "addReferencesCount",          type = ServiceCounterDataType },
        { name = "deleteNodesCount",            type = ServiceCounterDataType },
        { name = "deleteReferencesCount",       type = ServiceCounterDataType },
        { name = "browseCount",                 type = ServiceCounterDataType },
        { name = "browseNextCount",             type = ServiceCounterDataType },
        { name = "translateBrowsePathsToNodeIdsCount",  type = ServiceCounterDataType },
        { name = "queryFirstCount",             type = ServiceCounterDataType },
        { name = "queryNextCount",              type = ServiceCounterDataType },
        { name = "registerNodesCount",          type = ServiceCounterDataType },
        { name = "unregisterNodesCount",        type = ServiceCounterDataType },
    }

    __Sealed__() __Node__{ NodeId = 868 }
    struct "SessionSecurityDiagnosticsDataType" {
        { name = "sessionId",                   type = NodeId },
        { name = "clientUserIdOfSession",       type = String },
        { name = "clientUserIdHistory",         type = Strings },
        { name = "authenticationMechanism",     type = String },
        { name = "encoding",                    type = String },
        { name = "transportProtocol",           type = String },
        { name = "securityMode",                type = MessageSecurityMode },
        { name = "securityPolicyUri",           type = String },
        { name = "clientCertificate",           type = ByteString },
    }

    __Sealed__() __Node__{ NodeId = 299 }
    struct "StatusResult"       {
        { name = "statusCode",                  type = StatusCode },
        { name = "diagnosticInfo",              type = DiagnosticInfo },
    }

    __Sealed__() __Node__{ NodeId = 874 }
    struct "SubscriptionDiagnosticsDataType" {
        { name = "sessionId",                   type = NodeId },
        { name = "subscriptionId",              type = UInt32 },
        { name = "priority",                    type = Byte },
        { name = "publishingInterval",          type = Duration },
        { name = "maxKeepAliveCount",           type = UInt32 },
        { name = "maxLifetimeCount",            type = UInt32 },
        { name = "maxNotificationsPerPublish",  type = UInt32 },
        { name = "publishingEnabled",           type = Boolean },
        { name = "modifyCount",                 type = UInt32 },
        { name = "enableCount",                 type = UInt32 },
        { name = "disableCount",                type = UInt32 },
        { name = "republishRequestCount",       type = UInt32 },
        { name = "republishMessageRequestCount",type = UInt32 },
        { name = "republishMessageCount",       type = UInt32 },
        { name = "transferRequestCount",        type = UInt32 },
        { name = "transferredToAltClientCount", type = UInt32 },
        { name = "transferredToSameClientCount",type = UInt32 },
        { name = "publishRequestCount",         type = UInt32 },
        { name = "dataChangeNotificationsCount",type = UInt32 },
        { name = "eventNotificationsCount",     type = UInt32 },
        { name = "notificationsCount",          type = UInt32 },
        { name = "latePublishRequestCount",     type = UInt32 },
        { name = "currentKeepAliveCount",       type = UInt32 },
        { name = "currentLifetimeCount",        type = UInt32 },
        { name = "unacknowledgedMessageCount",  type = UInt32 },
        { name = "discardedMessageCount",       type = UInt32 },
        { name = "monitoredItemCount",          type = UInt32 },
        { name = "disabledMonitoredItemCount",  type = UInt32 },
        { name = "monitoringQueueOverflowCount",type = UInt32 },
        { name = "nextSequenceNumber",          type = UInt32 },
        { name = "eventQueueOverFlowCount",     type = UInt32 },
    }

    __Sealed__() __Node__{ NodeId = 877 }
    struct "ModelChangeStructureDataType" {
        { name = "affected",                    type = NodeId },
        { name = "affectedType",                type = NodeDataType },
        { name = "verb",                        type = Byte },
    }

    __Sealed__() __Node__{ NodeId = 897 }
    struct "SemanticChangeStructureDataType" {
        { name = "affected",                    type = NodeId },
        { name = "affectedType",                type = NodeDataType },
    }

    __Sealed__() __Node__{ NodeId = 344 }
    struct "SignedSoftwareCertificate" {
        { name = "certificateData",             type = ByteString },
        { name = "signature",                   type = ByteString },
    }

    __Sealed__()
    struct "SignedSoftwareCertificates" { SignedSoftwareCertificate }

    __Sealed__() __Node__{ NodeId = 8912 }
    struct "TimeZoneDataType"   {
        { name = "offset",                      type = Int16 },     -- The offset in minutes from UtcTime
        { name = "daylightSavingInOffset",      type = Boolean },   -- daylight saving time (DST) is in effect and offset includes the DST correction if true
    }

    __Sealed__() __Node__{ NodeId = 7594 }
    struct "EnumValueType"      {
        { name = "value",                       type = Int64 },         -- The Integer representation of an Enumeration
        { name = "displayName",                 type = LocalizedText }, -- A human-readable representation of the Value of the Enumeration
        { name = "description",                 type = LocalizedText }, -- A localized description of the enumeration value
    }

    __Sealed__()
    struct "EnumValueTypes"     { EnumValueType }

    __Sealed__() __Node__{ NodeId = 12755, IsAbstract = true }
    struct "OptionSet"          {
        { name = "value",                       type = ByteString },
        { name = "validBits",                   type = ByteString },
    }

    __Sealed__() __Node__{ NodeId = 12756, IsAbstract = true, SubTypeOf = Struct }
    struct "Union"              {}

    __Sealed__() __Node__{ NodeId = 101 }
    struct "StructureField"     {
        { name = "name",                        type = String },            -- A name for the field that is unique within the StructureDefinition
        { name = "description",                 type = LocalizedText },     -- A localized description of the field
        { name = "dataType",                    type = NodeDataType },      -- The NodeId of the DataType for the field
        { name = "valueRank",                   type = Int32 },             -- The value rank for the field
        { name = "arrayDimensions",             type = struct { UInt32 } }, -- the maximum supported length of each dimension
        { name = "maxStringLength",             type = UInt32 },            -- the maximum supported length
        { name = "isOptional",                  type = Boolean },           -- if a data type field in a Structure is optional
    }

    struct "DataTypeDefinition" {}

    __Sealed__() __Node__{ NodeId = 99, SubTypeOf = DataTypeDefinition }
    struct "StructureDefinition"{
        { name = "defaultEncodingId",           type = NodeId },
        { name = "baseDataType",                type = NodeDataType },
        { name = "structureType",               type = StructureType },
        { name = "fields",                      type = struct { StructureField } },
    }

    __Sealed__() __Node__{ NodeId = 102, SubTypeOf = EnumValueType }
    struct "EnumField"          {
        { name = "name",                        type = String },
    }

    __Sealed__() __Node__{ NodeId = 100, SubTypeOf = DataTypeDefinition }
    struct "EnumDefinition"     {
        { name = "fields", type = struct { EnumField } },
    }

    __Sealed__() __Node__{ NodeId = 97, IsAbstract = true, SubTypeOf = Struct }
    struct "DataTypeDefinition" { __base = StructureDefinition + EnumDefinition }

    __Sealed__() __Node__{ NodeId = 96 }
    struct "RolePermissionType" {
        { name = "roleId",      type = NodeId,          require = true },
        { name = "permissions", type = PermissionType,  require = true },
    }

    __Sealed__() __Node__{ NodeId = 887 }
    struct "EUInformation"      {
        { name = "namespaceUri",type = String,          require = true },
        { name = "unitId",      type = Int32,           require = true },
        { name = "displayName", type = LocalizedText,   require = true },
        { name = "description", type = LocalizedText },
    }

    __Sealed__() __Node__{ NodeId = 311, SubtypeOf = ByteString }
    struct "ApplicationInstanceCertificate" {
        { name = "version",             type = String },            -- An identifier for the version of the Certificate encoding.
        { name = "serialNumber",        type = ByteString },        -- A unique identifier for the Certificate assigned by the Issuer.
        { name = "signatureAlgorithm",  type = String },            -- The algorithm used to sign the Certificate.The syntax of this field depends on the Certificate encoding.
        { name = "signature",           type = ByteString },        -- The signature created by the Issuer.
        { name = "issuer",              type = Any },               -- A name that identifies the Issuer Certificate used to create the signature.
        { name = "validFrom",           type = UtcTime },           -- When the Certificate becomes valid.
        { name = "validTo",             type = UtcTime },           -- When the Certificate expires.
        { name = "subject",             type = Any },               -- A name that identifies the application instance that the Certificate describes. This field shall contain the productName and the name of the organization responsible for the application instance.
        { name = "applicationUri",      type = String },            -- The applicationUri specified in the ApplicationDescription. The ApplicationDescription is described in 7.1.
        { name = "hostnames",           type = Strings },           -- The name of the machine where the application instance runs. A machine may have multiple names if is accessible via multiple networks. The hostname may be a numeric network address or a descriptive name. Server   Certificates   shall have at least one hostname defined.
        { name = "publicKey",           type = ByteString },        -- The public key associated with the Certificate.
        { name = "keyUsage",            type = Strings },           -- Specifies how the Certificate key may be used.
    }

    __Sealed__() __Node__{ NodeId = 304 }
    struct "UserTokenPolicy "   {
        { name = "policyId",            type = String },
        { name = "tokenType",           type = UserTokenType },
        { name = "issuedTokenType",     type = String },
        { name = "issuerEndpointUrl",   type = String },
        { name = "securityPolicyUri",   type = String },
    }

    __Sealed__() __Node__{ NodeId = 12189 }
    struct "ServerOnNetwork"    {
        { name = "recordId",            type = UInt32 },
        { name = "serverName",          type = String },
        { name = "discoveryUrl",        type = String },
        { name = "serverCapabilities",  type = Strings },
    }

    __Sealed__()
    struct "ServerOnNetworks"   { ServerOnNetwork }

    __Sealed__() __Node__{ NodeId = 312 }
    struct "EndpointDescription"{
        { name = "endpointUrl",         type = String },
        { name = "server",              type = ApplicationDescription },
        { name = "serverCertificate",   type = ApplicationInstanceCertificate },
        { name = "securityMode",        type = MessageSecurityMode },
        { name = "securityPolicyUri",   type = String },
        { name = "userIdentityTokens",  type = struct { UserTokenPolicy } },
        { name = "transportProfileUri", type = String },
        { name = "securityLevel",       type = Byte },
    }

    __Sealed__()
    struct "EndpointDescriptions"{ EndpointDescription }

    __Sealed__() __Node__{ NodeId = 432 }
    struct "RegisteredServer"   {
        { name = "serverUri",           type = String },
        { name = "productUri",          type = String },
        { name = "serverNames",         type = struct{ LocalizedText } },
        { name = "serverType",          type = ApplicationType },
        { name = "gatewayServerUri",    type = String },
        { name = "discoveryUrls",       type = Strings },
        { name = "semaphoreFilePath",   type = String },
        { name = "isOnline",            type = Boolean },
    }

    __Sealed__() __Node__{ NodeId = 15634 }
    struct "IdentityMappingRuleType" {
        { name = "criteriaType",    type = IdentityCriteriaType },
        { name = "criteria",        type = String },
    }

    __Sealed__()
    struct "IdentityMappingRuleTypes" { IdentityMappingRuleType }

    __Sealed__() __Node__{ NodeId = 15528 }
    struct "EndpointType"       {
        { name = "endpointUrl",         type = String },
        { name = "securityMode",        type = MessageSecurityMode },
        { name = "securityPolicyUri",   type = String },
        { name = "transportProfileUri", type = String },
    }

    __Sealed__()
    struct "EndpointTypes"      { EndpointType }

    --- The Node Information Structure Re-definition
    __Sealed__()
    struct "NodeInfo"           {
        --- The persisted identifier
        { name = "NodeId",              type = NodeId + NaturalNumber },

        --- The NodeClass of node
        { name = "NodeClass",           type = NodeClass },

        --- A non-localised readable name contains a namespace and a string
        { name = "BrowseName",          type = QualifiedName + String },

        --- The localised name of the node
        { name = "DisplayName",         type = LocalizedText + String },

        --- The localised description text
        { name = "Description",         type = LocalizedText + String },

        --- The possibilities of a client to write the attributes of node
        { name = "WriteMask",           type = AttributeWriteMask },

        --- The write mask that taking user access rights into accunt
        { name = "UserWriteMask",       type = AttributeWriteMask },

        --- The permissions that apply to a Node for all Roles
        { name = "RolePermissions",     type = struct { RolePermissionType } },

        --- The permissions that apply to a Node for all Roles granted to current Session
        { name = "UserRolePermissions", type = struct { RolePermissionType } },

        --- The AccessRestrictions apply to a Node
        { name = "AccessRestrictions",  type = AccessRestrictionsType },

        --- Whether the ReferenceType is abstract
        { name = "IsAbstract",          type = Boolean },

        --- Whether the meaning of the ReferenceType is the same as seen from both the SourceNode and the TargetNode
        { name = "Symmetric",           type = Boolean },

        --- The meaning of the ReferenceType as seen from the TargetNode
        { name = "InverseName",         type = LocalizedText },

        { name = "ContainsNoLoops",     type = Boolean },
        { name = "EventNotifier",       type = NaturalNumber },
        { name = "Value",               type = Any },
        { name = "DataType",            type = NodeDataType },
        { name = "ValueRank",           type = Int32 },
        { name = "ArrayDimensions",     type = struct { UInt32 } },
        { name = "AccessLevel",         type = AccessLevelType },
        { name = "UserAccessLevel",     type = AccessLevelType },
        { name = "MinimumSamplingInterval", type = Duration },
        { name = "Historizing",         type = Boolean },
        { name = "Executable",          type = Boolean },
        { name = "UserExecutable",      type = Boolean },
        { name = "DataTypeDefinition",  type = DataTypeDefinition },
        { name = "AccessLevelEx",       type = AccessLevelExType },

        --- Use ModellingRule instead of the real node
        { name = "HasModellingRule",    type = ModellingRule },

        --- The super type of the node, all reference inverse name can be used
        { name = "SubtypeOf",           type = Any },

        --- The input arguments for the Method
        { name = "InputArguments",      type = Arguments },

        --- The output arguments for the Method
        { name = "OutputArguments",     type = Arguments },

        __init                  = function(self)
            if type(self.NodeId) == "number" then
                self.NodeId     = NodeId(NamespaceIndex.OPC_UA_URI, self.NodeId)
            end

            if type(self.BrowseName) == "string" then
                self.BrowseName = QualifiedName(NamespaceIndex.OPC_UA_URI, self.BrowseName)
            end

            if type(self.DisplayName) == "string" then
                self.DisplayName= LocalizedText(LocaleIdEnum.en, self.DisplayName)
            end

            if type(self.Description) == "string" then
                self.Description= LocalizedText(LocaleIdEnum.en, self.Description)
            end
        end
    }
end)