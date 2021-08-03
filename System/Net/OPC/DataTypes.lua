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

    export { validateValue = Struct.ValidateValue, Guid }

    ---------------------------------------------------
    --                 BaseDataType                  --
    ---------------------------------------------------
    --- BaseDataType <-> Any
    __Node__.RegisterNode(Any, { NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 24), BrowseName = QualifiedName(NamespaceIndex.OPC_UA_URI, "BaseDataType"), IsAbstract = true })

    --- Boolean
    __Node__.RegisterNode(Boolean, { NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 1), SubtypeOf = Any })

    --- Number
    __Node__.RegisterNode(Number, { NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 26), IsAbstract = true, SubtypeOf = Any })

    --- Enumeration
    __Node__.RegisterNode(Enum, { NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 29), BrowseName = QualifiedName(NamespaceIndex.OPC_UA_URI, "Enumeration"), IsAbstract = true, SubtypeOf = Any })

    --- Structure
    __Node__.RegisterNode(Struct, { NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 22), BrowseName = QualifiedName(NamespaceIndex.OPC_UA_URI, "Structure"), IsAbstract = true, SubtypeOf = Any })

    --- String
    __Node__.RegisterNode(String, { NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 12), SubtypeOf = Any })

    --- DateTime
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 13), SubTypeOf = Any }
    struct "DateTime" { __base = NaturalNumber }

    --- UtcTime
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 294) }
    struct "UtcTime" { __base = DateTime }

    --- Guid
    __Node__.RegisterNode(Guid, { NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 14), SubtypeOf = Any })

    --- ByteString
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 15), SubTypeOf = Any }
    struct "ByteString" { __base = String }

    --- XmlElement @todo: be replaced by real xml element
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 16), SubTypeOf = Any }
    struct "XmlElement" {}

    ---------------------------------------------------
    --                  Enumeration                  --
    ---------------------------------------------------
    ---- the type of the NodeId
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 256) }
    enum "IdType"               {}

    --- the naming rule type
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 120) }
    enum "NamingRuleType"   {
        Mandatory               = 1, -- The BrowseName must appear in all instances of the type.
        Optional                = 2, -- The BrowseName may appear in an instance of the type.
        Constraint              = 3, -- The modelling rule defines a constraint and the BrowseName is not used in an instance of the type.
    }

    --- The node classes
    __Sealed__() __Flags__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 257) }
    enum "NodeClass"            {
        Unspecified             = 0,
        "Object",
        "Variable",
        "Method",
        "ObjectType",
        "VariableType",
        "ReferenceType",
        "DataType",
        "View",
    }

    --- The attribute write flags
    __Sealed__() __Flags__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 347) }
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
    __Sealed__() __Flags__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 94) }
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
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 315) }
    enum "SecurityTokenRequestType" {
        Issue                   = 0,
        Renew                   = 1,
    }

    --- The Message Security Mode
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 302) }
    enum "MessageSecurityMode"  {
        Invalid                 = 0,
        None                    = 1,
        Sign                    = 2,
        SignAndEncrypt          = 3,
    }

    --- The Redundancy Support
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 851) }
    enum "RedundancySupport"    {
        None                    = 0,
        Cold                    = 1,
        Warm                    = 2,
        Hot                     = 3,
        Transparent             = 4,
        HotAndMirrored          = 5,
    }

    --- The Server State
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 852) }
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
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 307) }
    enum "ApplicationType"      {
        Server                  = 0,
        Client                  = 1,
        ClientAndServer         = 2,
        DiscoveryServer         = 3,
    }

    --- The Structure Type
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 98) }
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

    ---------------------------------------------------
    --               Custom Structure                --
    ---------------------------------------------------
    -- Integer
    __Node__.RegisterNode(Integer, { NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 27), IsAbstract = true })

    --- UInteger
    __Node__.RegisterNode(NaturalNumber, { NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 28), BrowseName = QualifiedName(NamespaceIndex.OPC_UA_URI, "UInteger"), IsAbstract = true, SubtypeOf = Number })

    --- Float
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 10) }
    struct "Float"              { __base = Number }

    --- Double
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 11) }
    struct "Double"             { __base = Number }

    --- Decimal
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 50) }
    struct "Decimal"            { __base = Number }

    --- Duration
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 290) }
    struct "Duration"           { __base = Double }

    --- SByte
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 2) }
    struct "SByte"              { __base = Integer, function(val, onlyvalid) return (val > 127 or val < -128) and (onlyvalid or "the %s must be an 8 bytes integer") or nil end }

    --- Int16
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 4) }
    struct "Int16"              { __base = Integer, function(val, onlyvalid) return (val > 32767 or val < -32768) and (onlyvalid or "the %s must be an 16 bytes integer") or nil end }

    --- Int32
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 6) }
    struct "Int32"              { __base = Integer, function(val, onlyvalid) return (val > 2147483647 or val < -2147483648) and (onlyvalid or "the %s must be an 32 bytes integer") or nil end }

    --- Int64
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 8) }
    struct "Int64"              { __base = Integer }

    --- Byte
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 3) }
    struct "Byte"               { __base = NaturalNumber, function(val, onlyvalid) return val >= 2^8 and (onlyvalid or "the %s must be an 8 bytes unsigned integer") or nil end }

    --- UInt16
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 5) }
    struct "UInt16"             { __base = NaturalNumber, function(val, onlyvalid) return val >= 2^16 and (onlyvalid or "the %s must be an 16 bytes unsigned integer") or nil end }

    --- UInt32
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 7) }
    struct "UInt32"             { __base = NaturalNumber, function(val, onlyvalid) return val >= 2^32 and (onlyvalid or "the %s must be an 32 bytes unsigned integer") or nil end }

    --- UInt64
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 9) }
    struct "UInt64"             { __base = NaturalNumber }

    --- BitFieldMaskDataType
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 11737) }
    struct "BitFieldMaskDataType" { __base = UInt64 }

    --- Index
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 17588) }
    struct "Index"              { __base = UInt32 }

    --- StatusCode
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 19), SubTypeOf = Any }
    struct "StatusCode"         { __base = UInt32 }

    --- Image
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 30), IsAbstract = true }
    struct "Image"              { __base = ByteString }

    --- ImageBMP
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 2000) }
    struct "ImageBMP"           { __base = Image }

    --- ImageGIF
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 2001) }
    struct "ImageGIF"           { __base = Image }

    --- ImageJPG
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 2002) }
    struct "ImageJPG"           { __base = Image }

    --- ImagePNG
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 2003) }
    struct "ImagePNG"           { __base = Image }

    --- AudioDataType
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 16307) }
    struct "AudioDataType"      { __base = ByteString }

    --- LocaleId
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 295) }
    struct "LocaleId"           { __base = String }

    --- NumericRange
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 291) }
    struct "NumericRange"       { __base = String }

    --- NormalizedString
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 12877) }
    struct "NormalizedString"   { __base = String }

    --- DecimalString
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 12878) }
    struct "DecimalString"      { __base = String }

    --- DurationString
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 12879) }
    struct "DurationString"     { __base = String }

    --- TimeString
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 12880) }
    struct "TimeString"         { __base = String }

    --- DateString
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 12881) }
    struct "DateString"         { __base = String }

    ---------------------------------------------------
    --               Member Structure                --
    ---------------------------------------------------
    --- The node identifier structure
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 17), SubTypeOf = Any }
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
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 18), SubTypeOf = Any }
    struct "ExpandedNodeId"     {
        { name = "serverIndex",    type = Index,    require = true },  -- The index that identifies the Server that contains the TargetNode, 0 means local server
        { name = "namespaceUri",   type = String },                    -- The URI of the namespace
        { name = "namespaceIndex", type = Index,    require = true },  -- The index for a namespace URI, should be 0 if the namespaceUri is specified
        { name = "identifierType", type = IdType,   require = true },  -- The format and data type of the identifier
        { name = "identifier",     type = Any,      require = true },  -- The identifier for a Node in the AddressSpace of an OPC UA Server
    }

    --- A qualified name
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 20), SubTypeOf = Any }
    struct "QualifiedName"      {
        { name = "namespaceIndex", type = UInt16, require = true },  -- Index that identifies the namespace that defines the name
        { name = "name",           type = String, require = true },  -- The text portion of the QualifiedName, 512 characters
    }

    --- The localizaed text
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 21), SubTypeOf = Any }
    struct "LocalizedText"      {
        { name = "locale", type = LocaleId, require = true },  -- The identifier for the locale (e.g. "en-US")
        { name = "text",   type = String,   require = true },
    }

    --- The Data Value
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 23), SubTypeOf = Any }
    struct "DataValue"          {
        { name = "value",             type = Any },                         -- The data value. If the StatusCode indicates an error then the value is to be ignored and the Server shall set it to null.
        { name = "statusCode",        type = StatusCode, require = true },  -- The StatusCode that defines with the Server’s ability to access/provide the value.
        { name = "sourceTimestamp",   type = UtcTime },         -- The source timestamp for the value.
        { name = "sourcePicoSeconds", type = NaturalNumber },   -- Specifies the number of 10 picoseconds (1,0 e-11 seconds) intervals which shall be added to the sourceTimestamp.
        { name = "serverTimestamp",   type = UtcTime },         --  The Server timestamp for the value.
        { name = "serverPicoSeconds", type = NaturalNumber },   -- Specifies the number of 10 picoseconds (1,0 e-11 seconds) intervals which shall be added to the serverTimestamp.
    }

    --- The Diagnostic Info - Vendor-specific diagnostic information.
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 25), SubTypeOf = Any }
    struct "DiagnosticInfo"     {
        { name = "namespaceUri",   type = Int32  },             -- The symbolicId is defined within the context of a namespace, -1 indicates that no string is specified
        { name = "symbolicId",     type = Int32  },             -- The symbolicId shall be used to identify a vendor-specific error or condition; typically the result of some Server internal operation
        { name = "locale",         type = Int32  },             -- The locale part of the vendor-specific localized text describing the symbolic id.
        { name = "localizedText",  type = Int32  },             -- A vendor-specific localized text string describes the symbolic id. The maximum length of this text string is 256 characters.
        { name = "additionalInfo", type = String },             -- Vendor-specific diagnostic information.
        { name = "innerStatusCode",type = StatusCode },         -- The StatusCode from the inner operation.
        { name = "innerDiagnosticInfo", type = DiagnosticInfo },-- The diagnostic info associated with the inner StatusCode.
    }

    ---------------------------------------------------
    --               OPC Structure                   --
    ---------------------------------------------------
    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 296) }
    struct "Argument"           {
        { name = "name",            type = String },
        { name = "dataType",        type = NodeId },
        { name = "valueRank",       type = Int32 },
        { name = "arrayDimensions", type = struct { UInt32 } },
        { name = "description",     type = LocalizedText },
    }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 316), IsAbstract = true }
    struct "UserIdentityToken"  {
        { name = "policyId",        type = String },
    }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 376) }
    struct "AddNodesItem"       {
        { name = "parentNodeId",    type = ExpandedNodeId },
        { name = "referenceTypeId", type = NodeId },
        { name = "requestedNewNodeId",  type = ExpandedNodeId },
        { name = "browseName",      type = QualifiedName },
        { name = "nodeClass",       type = NodeClass },
        { name = "nodeAttributes",  type = Any },
        { name = "typeDefinition",  type = ExpandedNodeId },
    }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 379) }
    struct "AddReferencesItem"  {
        { name = "sourceNodeId",    type = NodeId },
        { name = "referenceTypeId", type = NodeId },
        { name = "isForward",       type = Boolean },
        { name = "targetServerUri", type = String },
        { name = "targetNodeId",    type = ExpandedNodeId },
        { name = "targetNodeClass", type = NodeClass },
    }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 382) }
    struct "DeleteNodesItem"    {
        { name = "nodeId",          type = NodeId },
        { name = "deleteTargetReferences",  type = Boolean },
    }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 385) }
    struct "DeleteReferencesItem" {
        { name = "sourceNodeId",    type = NodeId },
        { name = "referenceTypeId", type = NodeId },
        { name = "isForward",       type = Boolean },
        { name = "targetNodeId",    type = ExpandedNodeId },
        { name = "deleteBidirectional", type = Boolean },
    }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 308) }
    struct "ApplicationDescription" {
        { name = "applicationUri",  type = String },
        { name = "productUri",      type = String },
        { name = "applicationName", type = LocalizedText },
        { name = "applicationType", type = ApplicationType },
        { name = "gatewayServerUri",type = String },
        { name = "discoveryProfileUri", type = String },
        { name = "discoveryUrls",   type = struct { String } },
    }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 338) }
    struct "BuildInfo"          {
        { name = "productUri",      type = String },
        { name = "manufacturerName",type = String },
        { name = "productName",     type = String },
        { name = "softwareVersion", type = String },
        { name = "buildNumber",     type = String },
        { name = "buildDate",       type = UtcTime },
    }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 853) }
    struct "RedundantServerDataType" {
        { name = "serverId",        type = String },
        { name = "serviceLevel",    type = Byte },
        { name = "serverState",     type = ServerState },
    }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 856) }
    struct "SamplingIntervalDiagnosticsDataType" {
        { name = "samplingInterval",            type = Duration },
        { name = "monitoredItemCount",          type = UInt32 },
        { name = "maxMonitoredItemCount",       type = UInt32 },
        { name = "disabledMonitoredItemCount",  type = UInt32 },
    }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 859) }
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

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 862) }
    struct "ServerStatusDataType" {
        { name = "startTime",                   type = UtcTime },
        { name = "currentTime",                 type = UtcTime },
        { name = "state",                       type = ServerState },
        { name = "buildInfo",                   type = BuildInfo },
        { name = "secondsTillShutdown",         type = UInt32 },
        { name = "shutdownReason",              type = LocalizedText },
    }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 871) }
    struct "ServiceCounterDataType" {
        { name = "totalCount",                  type = UInt32 },
        { name = "errorCount",                  type = UInt32 },
    }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 865) }
    struct "SessionDiagnosticsDataType" {
        { name = "sessionId",                   type = NodeId },
        { name = "sessionName",                 type = String },
        { name = "clientDescription",           type = ApplicationDescription },
        { name = "serverUri",                   type = String },
        { name = "endpointUrl",                 type = String },
        { name = "localeIds",                   type = struct { LocaleId } },
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

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 868) }
    struct "SessionSecurityDiagnosticsDataType" {
        { name = "sessionId",                   type = NodeId },
        { name = "clientUserIdOfSession",       type = String },
        { name = "clientUserIdHistory",         type = struct { String } },
        { name = "authenticationMechanism",     type = String },
        { name = "encoding",                    type = String },
        { name = "transportProtocol",           type = String },
        { name = "securityMode",                type = MessageSecurityMode },
        { name = "securityPolicyUri",           type = String },
        { name = "clientCertificate",           type = ByteString },
    }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 299) }
    struct "StatusResult"       {
        { name = "statusCode",                  type = StatusCode },
        { name = "diagnosticInfo",              type = DiagnosticInfo },
    }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 874) }
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

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 877) }
    struct "ModelChangeStructureDataType" {
        { name = "affected",                    type = NodeId },
        { name = "affectedType",                type = NodeId },
        { name = "verb",                        type = Byte },
    }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 897) }
    struct "SemanticChangeStructureDataType" {
        { name = "affected",                    type = NodeId },
        { name = "affectedType",                type = NodeId },
    }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 344) }
    struct "SignedSoftwareCertificate" {
        { name = "certificateData",             type = ByteString },
        { name = "signature",                   type = ByteString },
    }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 8912) }
    struct "TimeZoneDataType"   {
        { name = "offset",                      type = Int16 },
        { name = "daylightSavingInOffset",      type = Boolean },
    }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 7594) }
    struct "EnumValueType"      {
        { name = "value",                       type = Int64 },
        { name = "displayName",                 type = LocalizedText },
        { name = "description",                 type = LocalizedText },
    }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 12755), IsAbstract = true }
    struct "OptionSet"          {
        { name = "value",                       type = ByteString },
        { name = "validBits",                   type = ByteString },
    }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 12756), IsAbstract = true, SubTypeOf = Struct }
    struct "Union"              {}

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 101) }
    struct "StructureField"     {
        { name = "name",                        type = String },
        { name = "description",                 type = LocalizedText },
        { name = "dataType",                    type = NodeId },
        { name = "valueRank",                   type = Int32 },
        { name = "arrayDimensions",             type = struct { UInt32 } },
        { name = "maxStringLength",             type = UInt32 },
        { name = "isOptional",                  type = Boolean },
    }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 97), IsAbstract = true, SubTypeOf = Struct }
    struct "DataTypeDefinition" {}

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 99), SubTypeOf = DataTypeDefinition }
    struct "StructureDefinition"{
        { name = "defaultEncodingId",           type = NodeId },
        { name = "baseDataType",                type = NodeId },
        { name = "structureType",               type = StructureType },
        { name = "fields",                      type = struct { StructureField } },
    }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 102), SubTypeOf = EnumValueType }
    struct "EnumField"          {
        { name = "name",                        type = String },
    }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 100), SubTypeOf = DataTypeDefinition }
    struct "EnumDefinition"     {
        { name = "fields",                      type = struct { EnumField } },
    }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 96) }
    struct "RolePermissionType" {
        { name = "roleId",      type = NodeId,          require = true },
        { name = "permissions", type = PermissionType,  require = true },
    }

    --- The Node Information Structure Re-definition
    __Sealed__()
    struct "NodeInfo"             {
        --- The persisted identifier
        { name = "NodeId",              type = NodeId, require = true },

        --- The NodeClass of node
        { name = "NodeClass",           type = NodeClass },

        --- A non-localised readable name contains a namespace and a string
        { name = "BrowseName",          type = QualifiedName },

        --- The localised name of the node
        { name = "DisplayName",         type = LocalizedText },

        --- The localised description text
        { name = "Description",         type = LocalizedText },

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

        { name = "ContainsNoLoops",     type = Any },
        { name = "EventNotifier",       type = Any },
        { name = "Value",               type = Any },
        { name = "DataType",            type = Any },
        { name = "ValueRank",           type = Any },
        { name = "ArrayDimensions",     type = Any },
        { name = "AccessLevel",         type = Any },
        { name = "UserAccessLevel",     type = Any },
        { name = "MinimumSamplingInterval", type = Any },
        { name = "Historizing",         type = Any },
        { name = "Executable",          type = Any },
        { name = "UserExecutable",      type = Any },
        { name = "DataTypeDefinition",  type = Any },
        { name = "AccessLevelEx",       type = Any },

        --- The super type of the node, all reference inverse name can be used
        { name = "SubtypeOf",           type = Any },
    }
end)