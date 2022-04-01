--===========================================================================--
--                                                                           --
--                   System.Net.Protocol.OPC.ObjectTypes                     --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2021/08/04                                               --
-- Update Date  :   2021/08/04                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Net.OPC"

    --- the base ObjectType and all other ObjectTypes shall either directly or indirectly inherit from it
    __Sealed__() __Node__{ NodeId = 58 }
    class "BaseObjectType"              { Object }

    __Sealed__() __Node__{ NodeId = 77 }
    class "ModellingRuleType"           (function(_ENV)
        inherit "BaseObjectType"

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- the NamingRule of a ModellingRule
        __Node__{ NodeId = 111 }
        property  "NamingRule"          { type = NamingRuleType, require = true }
    end)

    __Sealed__() __Node__{ NodeId = 61 }
    class "FolderType"                  { BaseObjectType }

    __Sealed__() __Node__{ NodeId = 11564 }
    class "OperationLimitsType"         (function(_ENV)
        inherit "FolderType"

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        __Node__{ NodeId = 11565 }
        property "MaxNodesPerRead"                          { type = UInt32 }

        __Node__{ NodeId = 12161 }
        property "MaxNodesPerHistoryReadData"               { type = UInt32 }

        __Node__{ NodeId = 12162 }
        property "MaxNodesPerHistoryReadEvents"             { type = UInt32 }

        __Node__{ NodeId = 11567 }
        property "MaxNodesPerWrite"                         { type = UInt32 }

        __Node__{ NodeId = 12163 }
        property "MaxNodesPerHistoryUpdateData"             { type = UInt32 }

        __Node__{ NodeId = 12164 }
        property "MaxNodesPerHistoryUpdateEvents"           { type = UInt32 }

        __Node__{ NodeId = 11569 }
        property "MaxNodesPerMethodCall"                    { type = UInt32 }

        __Node__{ NodeId = 11570 }
        property "MaxNodesPerBrowse"                        { type = UInt32 }

        __Node__{ NodeId = 11571 }
        property "MaxNodesPerRegisterNodes"                 { type = UInt32 }

        __Node__{ NodeId = 11572 }
        property "MaxNodesPerTranslateBrowsePathsToNodeIds" { type = UInt32 }

        __Node__{ NodeId = 11573 }
        property "MaxNodesPerNodeManagement"                { type = UInt32 }

        __Node__{ NodeId = 11574 }
        property "MaxMonitoredItemsPerCall"                 { type = UInt32 }
    end)

    __Sealed__() __Node__{ NodeId = 15620 }
    class "RoleType"                    (function(_ENV)
        inherit "BaseObjectType"

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        __Node__{ NodeId = 16173 }
        property "Identities"           { type = IdentityMappingRuleTypes, require = true }

        __Node__{ NodeId = 16174 }
        property "Applications"         { type = Strings }

        __Node__{ NodeId = 15410 }
        property "ApplicationsExclude"  { type = Boolean }

        __Node__{ NodeId = 16175 }
        property "Endpoints"            { type = EndpointTypes }

        __Node__{ NodeId = 15411 }
        property "EndpointsExclude"     { type = Boolean }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        __Node__{
            NodeId = 15624,
            InputArguments = {
                { name = "Rule", dataType = IdentityMappingRuleType },
            },
            HasModellingRule = ModellingRule.Optional,
        }
        function AddIdentity(self, rule) end

        __Node__{
            InputArguments = {
                { name = "Rule", dataType = IdentityMappingRuleType },
            },
            HasModellingRule = ModellingRule.Optional,
        }
        function RemoveIdentity(self, rule) end

        __Node__{
            InputArguments = {
                { name = "ApplicationUri", dataType = String },
            },
            HasModellingRule = ModellingRule.Optional,
        }
        function AddApplication(self, applicationUri) end

        __Node__{
            InputArguments = {
                { name = "ApplicationUri", dataType = String },
            },
            HasModellingRule = ModellingRule.Optional,
        }
        function RemoveApplication(self, applicationUri) end

        __Node__{
            InputArguments = {
                { name = "Endpoint", dataType = EndpointType },
            },
            HasModellingRule = ModellingRule.Optional,
        }
        function AddEndpoint(self, endpoint) end

        __Node__{
            InputArguments = {
                { name = "Endpoint", dataType = EndpointType },
            },
            HasModellingRule = ModellingRule.Optional,
        }
        function RemoveEndpoint(self, endpoint) end
    end)

    __Sealed__() __Node__{ NodeId = 15607 }
    class "RoleSetType"                 (function(_ENV)
        inherit "BaseObjectType"

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        __Node__{ HasModellingRule = ModellingRule.OptionalPlaceholder }
        property "RoleName"             { type = RoleType }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        __Node__{
            InputArguments = {
                { name = "RoleName", dataType = String },
                { name = "NamespaceUri", dataType = String },
            },
            OutputArguments = {
                { name = "RoleNodeId", dataType = NodeId },
            },
        }
        function AddRole(self, roleName, namespaceUri)
        end

        __Node__{
            InputArguments = {
                { name = "RoleNodeId", dataType = NodeId },
            },
        }
        function RemoveRole(self, roleNodeId)
        end
    end)

    __Sealed__() __Node__{ NodeId = 2013 }
    class "ServerCapabilitiesType"      (function(_ENV)
        inherit "BaseObjectType"

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        __Node__()
        property "ServerProfileArray"           { type = Strings, require = true }

        __Node__()
        property "LocaleIdArray"                { type = LocaleIds, require = true }

        __Node__()
        property "MinSupportedSampleRate"       { type = Duration, require = true }

        __Node__()
        property "MaxBrowseContinuationPoints"  { type = UInt16, require = true }

        __Node__()
        property "MaxQueryContinuationPoints"   { type = UInt16, require = true }

        __Node__()
        property "MaxHistoryContinuationPoints" { type = UInt16, require = true }

        __Node__()
        property "SoftwareCertificates"         { type = SignedSoftwareCertificates, require = true }

        __Node__()
        property "MaxArrayLength"               { type = UInt32 }

        __Node__()
        property "MaxStringLength"              { type = UInt32 }

        __Node__()
        property "MaxByteStringLength"          { type = UInt32 }

        __Node__()
        property "OperationLimits"              { type = OperationLimitsType }

        __Node__()
        property "ModellingRules"               { type = FolderType, require = true }

        __Node__()
        property "AggregateFunctions"           { type = FolderType, require = true }

        __Node__{ HasModellingRule = ModellingRule.OptionalPlaceholder }
        property "VendorCapability"             { type = ServerVendorCapabilityType }

        __Node__()
        property "RoleSet"                      { type = RoleSetType }
    end)

    --- the capabilities supported by the OPC UA Server
    __Node__{ NodeId = 2004 }
    class "ServerType"                  (function(_ENV)
        inherit "BaseObjectType"

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        __Node__()
        property "ServerArray"          { type = Strings, require = true }

        __Node__()
        property "NamespaceArray"       { type = Strings, require = true }

        __Node__()
        property "UrisVersion"          { type = VersionTime }

        __Node__()
        property "ServerStatus"         { type = ServerStatusDataType, require = true }

        __Node__()
        property "ServiceLevel"         { type = Byte, require = true }

        __Node__()
        property "Auditing"             { type = Boolean, require = true }

        __Node__()
        property "EstimatedReturnTime"  { type = DateTime }

        __Node__()
        property "LocalTime"            { type = TimeZoneDataType }

        __Node__()
        property "ServerCapabilities"   { type = ServerCapabilitiesType, require = true }

        __Node__()

    end)

    __Node__{ NodeId = 61 }
    class "FolderType"                  { BaseObjectType }

    class "DataTypeEncodingType"        {}
end)