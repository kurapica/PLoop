--===========================================================================--
--                                                                           --
--                       System.Net.Protocol.Reference                       --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2020/05/28                                               --
-- Update Date  :   2020/07/29                                               --
-- Version      :   0.0.1                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Net.OPC"

    __Sealed__() __Abstract__() __Node__{ NodeId = 31, Symmetric = true }
    class "References"                  (function(_ENV)
        export {
            __Node__, Class, Node, NodeId,

            getNodeInfo                 = __Node__.GetNodeInfo,
            isObjectType                = Class.IsObjectType,
            getNamespaceName            = Namespace.GetNamespaceName,
            getmetatable                = getmetatable,
            pairs,
            type                        = type,
            validateValue               = Struct.ValidateValue,
            error                       = error,
            safeset                     = Toolset.safeset,
            yield                       = coroutine.yield,
        }

        local function getTargetNode(self, target)
            if validateValue(NodeId, target) then
                return target
            elseif isObjectType(target, Node) then
                return target.NodeId
            else
                local node              = self.AddressSpace:GetNode(target)
                return node and node.NodeId or getNodeInfo(target, "NodeId")
            end
        end

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- The AddressSpace
        property "AddressSpace"         { type = AddressSpace }

        --- Whether this is inverse
        property "IsInverse"            { type = Boolean }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- Check if the source and target can be referenced
        __Abstract__()
        function IsReferenceable(self, source, target)
            return true
        end

        --- Add a reference between source node or target node
        function AddReference(self, source, target, nobid)
            print("AddReference", getmetatable(self), source, target)

            source                      = getTargetNode(self, source)
            target                      = getTargetNode(self, target)

            if not (source and target) then error("Usage: References:AddReference(target, source) - the target and source must be Node, NodeId or which has Node Infomations", 2) end
            if not self:IsReferenceable(source, target) then error("Usage: References:AddReference(target, source) - the source and target can't be referenced by the reference type", 2) end

            local sourceid              = source.namespaceIndex .. "_" .. source.identifier
            local targetid              = target.namespaceIndex .. "_" .. target.identifier

            self.References             = safeset(self.References, sourceid, safeset(self.References[sourceid] or {}, targetid, true))

            if nobid then return end

            local cls                   = getmetatable(self)

            if self.IsInverse then
                return self.AddressSpace.References[getNamespaceName(cls, true)]:AddReference(target, source, true)
            elseif getNodeInfo(cls, "Symmetric") then
                return self:AddReference(target, source, true)
            else
                local inverse           = getNodeInfo(cls, "InverseName")
                return inverse and self.AddressSpace.References[inverse.text]:AddReference(target, source, true)
            end
        end

        --- Remove a reference between source node or target node
        function RemoveReference(self, source, target, nobid)
            source                      = getTargetNode(self, source)
            target                      = getTargetNode(self, target)

            if not (source and target) then error("Usage: References:RemoveReference(target, source) - the target and source must be Node, NodeId or which has Node Infomations", 2) end

            local sourceid              = source.namespaceIndex .. "_" .. source.identifier
            local targetid              = target.namespaceIndex .. "_" .. target.identifier

            if not (self.References[sourceid] and self.References[sourceid][targetid]) then return end

            self.References             = safeset(self.References, sourceid, safeset(self.References[sourceid] or {}, targetid, nil))

            if nobid then return end

            local cls                   = getmetatable(self)

            if self.IsInverse then
                return self.AddressSpace.References[getNamespaceName(cls, true)]:RemoveReference(target, source, true)
            elseif getNodeInfo(cls, "Symmetric") then
                return self:RemoveReference(target, source, true)
            else
                local inverse           = getNodeInfo(cls, "InverseName")
                return inverse and self.AddressSpace.References[inverse.text]:RemoveReference(target, source, true)
            end
        end

        --- Remove all references from the source
        function RemoveReferences(self, source)
            source                      = getTargetNode(self, source)
            if not source then error("Usage: References:GetTargets(source) - the source must be Node, NodeId or which has Node Infomations", 2) end

            source                      = source.namespaceIndex .. "_" .. source.identifier

            local targets               = self.References[source]
            if targets then
                self.References         = safeset(self.References, source, nil)

                local cls               = getmetatable(self)

                if self.IsInverse then
                    self                = self.AddressSpace.References[getNamespaceName(cls, true)]
                elseif getNodeInfo(cls, "Symmetric") then
                    self                = self
                else
                    local inverse       = getNodeInfo(cls, "InverseName")
                    if not inverse then return end
                    self                = self.AddressSpace.References[inverse.text]
                end

                for target in pairs(targets) do
                    if self.References[target] and self.References[target][source] then
                        self.References[target] = safeset(self.References[target], source, nil)
                    end
                end
            end
        end

        --- Get target nodes from source node
        __Iterator__()
        function GetTargets(self, source)
            source                      = getTargetNode(self, source)
            if not source then error("Usage: References:GetTargets(source) - the source must be Node, NodeId or which has Node Infomations", 2) end

            source                      = source.namespaceIndex .. "_" .. source.identifier

            local targets               = self.References[source]
            if targets then
                local i                 = 0
                for node in pairs(targets) do
                    i                   = i + 1

                    local index, id     = node:match("^(%d+)_(.*)$")
                    yield(i, NodeId(tonumber(index), tonumber(id) or id))
                end
            end
        end

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{ AddressSpace, Boolean/nil }
        function __ctor(self, addressSpace, isInverse)
            self.AddressSpace           = addressSpace
            self.IsInverse              = isInverse

            self.References             = {}
        end
    end)

    __Sealed__() __Abstract__() __Node__{ NodeId = 32, Symmetric = true }
    class "NonHierarchicalReferences"   { References }

    __Sealed__() __Abstract__() __Node__{ NodeId = 33, Symmetric = false }
    class "HierarchicalReferences"      { References }

    __Sealed__() __Node__{ NodeId = 23469, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.en, "HasAlias") }
    class "AliasFor"                    { NonHierarchicalReferences }

    __Sealed__() __Node__{ NodeId = 51, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.en, "ToTransition") }
    class "FromState"                   { NonHierarchicalReferences }

    __Sealed__() __Node__{ NodeId = 41, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.en, "GeneratedBy") }
    class "GeneratesEvent"              { NonHierarchicalReferences }

    __Sealed__() __Node__{ NodeId = 53, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.en, "MayBeCausedBy") }
    class "HasCause"                    { NonHierarchicalReferences }

    __Sealed__() __Node__{ NodeId = 9006, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.en, "IsConditionOf") }
    class "HasCondition"                { NonHierarchicalReferences }

    __Sealed__() __Node__{ NodeId = 39, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.en, "DescriptionOf") }
    class "HasDescription"              { NonHierarchicalReferences }

    __Sealed__() __Node__{ NodeId = 17597, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.en, "DictionaryEntryOf") }
    class "HasDictionaryEntry"          { NonHierarchicalReferences }

    __Sealed__() __Node__{ NodeId = 54, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.en, "MayBeEffectedBy") }
    class "HasEffect"                   { NonHierarchicalReferences }

    __Sealed__() __Node__{ NodeId = 38, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.en, "EncodingOf") }
    class "HasEncoding"                 { NonHierarchicalReferences }

    __Sealed__() __Node__{ NodeId = 9005, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.en, "IsFalseSubStateOf") }
    class "HasFalseSubState"            { NonHierarchicalReferences }

    __Sealed__() __Node__{ NodeId = 17603, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.en, "InterfaceOf") }
    class "HasInterface"                { NonHierarchicalReferences }

    __Sealed__() __Node__{ NodeId = 37, Symmetric = false } --, InverseName = LocalizedText(LocaleIdEnum.en, "ModellingRuleOf") }
    class "HasModellingRule"            { NonHierarchicalReferences }

    __Sealed__() __Node__{ NodeId = 117, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.en, "SubStateMachineOf") }
    class "HasSubStateMachine"          { NonHierarchicalReferences }

    __Sealed__() __Node__{ NodeId = 9004, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.en, "IsTrueSubStateOf") }
    class "HasTrueSubState"             { NonHierarchicalReferences }

    __Sealed__() __Node__{ NodeId = 40, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.en, "TypeDefinitionOf") }
    class "HasTypeDefinition"           { NonHierarchicalReferences }

    __Sealed__() __Node__{ NodeId = 52, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.en, "FromTransition") }
    class "ToState"                     { NonHierarchicalReferences }

    __Sealed__() __Node__{ NodeId = 14936, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.en, "WriterToDataSet") }
    class "DataSetToWriter"             { HierarchicalReferences }

    __Sealed__() __Abstract__() __Node__{ NodeId = 34, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.en, "ChildOf") }
    class "HasChild"                    { HierarchicalReferences }

    __Sealed__() __Node__{ NodeId = 36, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.en, "EventSourceOf") }
    class "HasEventSource"              { HierarchicalReferences }

    __Sealed__() __Node__{ NodeId = 35, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.en, "OrganizedBy") }
    class "Organizes"                   { HierarchicalReferences }

    __Sealed__() __Node__{ NodeId = 45, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.en, "SubtypeOf") }
    class "HasSubtype"                  { HasChild }

    __Sealed__() __Abstract__() __Node__{ NodeId = 44, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.en, "AggregatedBy") }
    class "Aggregates"                  { HasChild }

    __Sealed__() __Node__{ NodeId = 47, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.en, "ComponentOf") }
    class "HasComponent"                { Aggregates }

    __Sealed__() __Node__{ NodeId = 56, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.en, "HistoricalConfigurationOf") }
    class "HasHistoricalConfiguration"  { Aggregates }

    __Sealed__() __Node__{ NodeId = 46, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.en, "PropertyOf") }
    class "HasProperty"                 { Aggregates }

    __Sealed__() __Node__{ NodeId = 16362, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.en, "MemberOfAlarmGroup") }
    class "AlarmGroupMember"            { Organizes }

    __Sealed__() __Node__{ NodeId = 3065, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.en, "AlwaysGeneratedBy") }
    class "AlwaysGeneratesEvent"        { GeneratesEvent }

    __Sealed__() __Node__{ NodeId = 17604, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.en, "AddInOf") }
    class "HasAddIn"                    { HasComponent }

    __Sealed__() __Node__{ NodeId = 16361, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.en, "IsAlarmSuppressionGroupOf") }
    class "HasAlarmSuppressionGroup"    { HasComponent }

    __Sealed__() __Node__{ NodeId = 129, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.en, "ArgumentDescriptionOf") }
    class "HasArgumentDescription"      { HasComponent }

    __Sealed__() __Node__{ NodeId = 15297, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.en, "IsReaderInGroup") }
    class "HasDataSetReader"            { HasComponent }

    __Sealed__() __Node__{ NodeId = 15296, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.en, "IsWriterInGroup") }
    class "HasDataSetWriter"            { HasComponent }

    __Sealed__() __Node__{ NodeId = 15112, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.en, "GuardOf") }
    class "HasGuard"                    { HasComponent }

    __Sealed__() __Node__{ NodeId = 49, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.en, "OrderedComponentOf") }
    class "HasOrderedComponent"         { HasComponent }

    __Sealed__() __Node__{ NodeId = 14476, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.en, "PubSubConnectionOf") }
    class "HasPubSubConnection"         { HasComponent }

    __Sealed__() __Node__{ NodeId = 18805, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.en, "IsReaderGroupOf") }
    class "HasReaderGroup"              { HasComponent }

    __Sealed__() __Node__{ NodeId = 18804, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.en, "IsWriterGroupOf") }
    class "HasWriterGroup"              { HasComponent }

    __Sealed__() __Node__{ NodeId = 17276, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.en, "MayBeDisabledBy") }
    class "HasEffectDisable"            { HasEffect }

    __Sealed__() __Node__{ NodeId = 17983, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.en, "MayBeEnabledBy") }
    class "HasEffectEnable"             { HasEffect }

    __Sealed__() __Node__{ NodeId = 17984, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.en, "MayBeSuppressedBy") }
    class "HasEffectSuppressed"         { HasEffect }

    __Sealed__() __Node__{ NodeId = 17985, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.en, "MayBeUnsuppressedBy") }
    class "HasEffectUnsuppressed"       { HasEffect }

    __Sealed__() __Node__{ NodeId = 48, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.en, "NotifierOf") }
    class "HasNotifier"                 { HasEventSource }

    __Sealed__() __Node__{ NodeId = 131, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.en, "OptionalInputArgumentDescriptionOf") }
    class "HasOptionalInputArgumentDescription" { HasArgumentDescription }
end)