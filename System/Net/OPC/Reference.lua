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

    __Sealed__() __Abstract__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 31), NodeClass = NodeClass.ReferenceType, Symmetric = true }
    class "References" (function(_ENV)
        extend "IIndexedList"

        export {
            Node, NodeId, __Node__, AddressSpace,

            isObjectType        = Class.IsObjectType,
            getmetatable        = getmetatable,
            type                = type,
            validateValue       = Struct.ValidateValue,
            error               = error,
            tremove             = table.remove,
        }

        local function getTargetNode(self, target)
            if getmetatable(target) == nil and validateValue(NodeId, target) then
                local node      = self.Source.AddressSpace:GetNode(target)
                if node then
                    return node
                else
                    return target, true
                end
            elseif isObjectType(target, Node) then
                return target
            else
                local node      = self.Source.AddressSpace:GetNode(target)
                if node then
                    return node
                else
                    return __Node__.GetNodeInfo(target, "NodeId"), true
                end
            end
        end

        -----------------------------------------------------------
        --                        method                         --4
        -----------------------------------------------------------
        --- Whether the node can be used as the source
        __Abstract__()
        function IsSourceNodeAllowed(self, node)
            return true
        end

        --- Whether the node can be used as the target
        __Abstract__()
        function IsTargetNodeAllowed(self, node)
            return true
        end

        --- Binding the Source, return false if can't use the target as the source
        __Arguments__{ Node }
        function SetSource(self, source)
            if self.IsInverse and not self:IsTargetNodeAllowed(source.Target) then
                return false
            elseif not self.IsInverse and not self:IsSourceNodeAllowed(source.Target) then
                return false
            end

            self.Source         = source
            return true
        end

        --- Add target, the target can be real target, NodeId or Node
        -- the target will be converted to the NodeId or Node,  the Reference
        -- only keep the NodeId for the target
        function AddTarget(self, target, noBid)
            local tNode, isId   = getTargetNode(self, target)

            if tNode then
                if self.IsInverse and not self:IsSourceNodeAllowed(tNode.Target) then
                    return false
                elseif not self.IsInverse and not self:IsTargetNodeAllowed(tNode.Target) then
                    return false
                end

                local nodeId    = tNode.NodeId
                if isId then
                    for i, node in self:GetIterator() do
                        if isObjectType(node, Node) then
                            node=  node.NodeId
                        end

                        if tNode.namespaceIndex == node.namespaceIndex and tNode.identifier == node.identifier then
                            return true
                        end
                    end
                else
                    for i, node in self:GetIterator() do
                        if tNode == node then return true end
                    end
                end

                self[#self + 1] = tNode
                self.Source:UpdateNodeVersion()

                if noBid or isId or (not self.IsInverse and not (self.Symmetric or self.InverseName)) then return true end

                -- Create the bidirectional references
                local refType   = getmetatable(self)
                local isInverse = not self.IsInverse

                local tref
                for _, ref in tNode.References:GetIterator() do
                    if getmetatable(ref) == refType and (not isInverse == not ref.IsInverse) then
                        tref    = ref
                        break
                    end
                end

                if not tref then
                    tref        = refType(isInverse)
                    if tref:SetSource(tNode) then
                        tNode.References:Insert(tref)
                    else
                        tref    = nil
                    end
                end

                if tref then
                    return tref:AddTarget(self.Source, true)
                end
            else
                return false
            end
        end

        --- Remove target node
        function RemoveTarget(self, target, noBid)
            local tNode, isId   = getTargetNode(self, target)

            if tNode then
                if isId then
                    for i, node in self:GetIterator() do
                        if isObjectType(node, Node) then
                            node=  node.NodeId
                        end

                        if tNode.namespaceIndex == node.namespaceIndex and tNode.identifier == node.identifier then
                            tremove(self, i)
                            self.Source:UpdateNodeVersion()
                            break
                        end
                    end
                else
                    for i, node in self:GetIterator() do
                        if tNode == node then
                            tremove(self, i)
                            self.Source:UpdateNodeVersion()
                            break
                        end
                    end
                end

                if noBid or isId then return end

                -- Create the bidirectional references
                local refType   = getmetatable(self)
                local isInverse = not self.IsInverse

                local tref
                for _, ref in tNode.References:GetIterator() do
                    if getmetatable(ref) == refType and (not isInverse == not ref.IsInverse) then
                        tref    = ref
                        break
                    end
                end

                if tref then return tref:RemoveTarget(self.Source, true) end

            end
        end

        GetIterator             = ipairs

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- The source node
        property "Source"       { type = Node, field = 0 }

        --- Whether the reference is inverse
        property "IsInverse"    { type = Boolean, field = -1, default = false }

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{ Boolean/nil }
        function __new(_, isInverse)
            return { [-1] = isInverse or nil }, true
        end
    end)

    __Sealed__() __Abstract__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 32), NodeClass = NodeClass.ReferenceType, Symmetric = true }
    class "NonHierarchicalReferences" { References }

    __Sealed__() __Abstract__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 33), NodeClass = NodeClass.ReferenceType, Symmetric = false }
    class "HierarchicalReferences"  { References }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 23469), NodeClass = NodeClass.ReferenceType, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.enUS, "HasAlias") }
    class "AliasFor"                { NonHierarchicalReferences }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 51), NodeClass = NodeClass.ReferenceType, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.enUS, "ToTransition") }
    class "FromState"               { NonHierarchicalReferences }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 41), NodeClass = NodeClass.ReferenceType, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.enUS, "GeneratedBy") }
    class "GeneratesEvent"          { NonHierarchicalReferences }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 53), NodeClass = NodeClass.ReferenceType, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.enUS, "MayBeCausedBy") }
    class "HasCause"                { NonHierarchicalReferences }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 9006), NodeClass = NodeClass.ReferenceType, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.enUS, "IsConditionOf") }
    class "HasCondition"            { NonHierarchicalReferences }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 39), NodeClass = NodeClass.ReferenceType, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.enUS, "DescriptionOf") }
    class "HasDescription"          { NonHierarchicalReferences }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 17597), NodeClass = NodeClass.ReferenceType, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.enUS, "DictionaryEntryOf") }
    class "HasDictionaryEntry"      { NonHierarchicalReferences }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 54), NodeClass = NodeClass.ReferenceType, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.enUS, "MayBeEffectedBy") }
    class "HasEffect"               { NonHierarchicalReferences }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 38), NodeClass = NodeClass.ReferenceType, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.enUS, "EncodingOf") }
    class "HasEncoding"             { NonHierarchicalReferences }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 9005), NodeClass = NodeClass.ReferenceType, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.enUS, "IsFalseSubStateOf") }
    class "HasFalseSubState"        { NonHierarchicalReferences }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 17603), NodeClass = NodeClass.ReferenceType, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.enUS, "InterfaceOf") }
    class "HasInterface"            { NonHierarchicalReferences }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 37), NodeClass = NodeClass.ReferenceType, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.enUS, "ModellingRuleOf") }
    class "HasModellingRule"        { NonHierarchicalReferences }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 117), NodeClass = NodeClass.ReferenceType, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.enUS, "SubStateMachineOf") }
    class "HasSubStateMachine"      { NonHierarchicalReferences }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 9004), NodeClass = NodeClass.ReferenceType, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.enUS, "IsTrueSubStateOf") }
    class "HasTrueSubState"         { NonHierarchicalReferences }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 40), NodeClass = NodeClass.ReferenceType, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.enUS, "TypeDefinitionOf") }
    class "HasTypeDefinition"       { NonHierarchicalReferences }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 52), NodeClass = NodeClass.ReferenceType, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.enUS, "FromTransition") }
    class "ToState"                 { NonHierarchicalReferences }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 14936), NodeClass = NodeClass.ReferenceType, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.enUS, "WriterToDataSet") }
    class "DataSetToWriter"         { HierarchicalReferences }

    __Sealed__() __Abstract__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 34), NodeClass = NodeClass.ReferenceType, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.enUS, "ChildOf") }
    class "HasChild"                { HierarchicalReferences }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 36), NodeClass = NodeClass.ReferenceType, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.enUS, "EventSourceOf") }
    class "HasEventSource"          { HierarchicalReferences }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 35), NodeClass = NodeClass.ReferenceType, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.enUS, "OrganizedBy") }
    class "Organizes"               { HierarchicalReferences }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 45), NodeClass = NodeClass.ReferenceType, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.enUS, "SubtypeOf") }
    class "HasSubtype"              { HasChild }

    __Sealed__() __Abstract__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 44), NodeClass = NodeClass.ReferenceType, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.enUS, "AggregatedBy") }
    class "Aggregates"              { HasChild }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 47), NodeClass = NodeClass.ReferenceType, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.enUS, "ComponentOf") }
    class "HasComponent"            { Aggregates }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 56), NodeClass = NodeClass.ReferenceType, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.enUS, "HistoricalConfigurationOf") }
    class "HasHistoricalConfiguration" { Aggregates }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 46), NodeClass = NodeClass.ReferenceType, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.enUS, "PropertyOf") }
    class "HasProperty"             { Aggregates }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 16362), NodeClass = NodeClass.ReferenceType, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.enUS, "MemberOfAlarmGroup") }
    class "AlarmGroupMember"        { Organizes }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 3065), NodeClass = NodeClass.ReferenceType, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.enUS, "AlwaysGeneratedBy") }
    class "AlwaysGeneratesEvent"    { GeneratesEvent }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 17604), NodeClass = NodeClass.ReferenceType, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.enUS, "AddInOf") }
    class "HasAddIn"                { HasComponent }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 16361), NodeClass = NodeClass.ReferenceType, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.enUS, "IsAlarmSuppressionGroupOf") }
    class "HasAlarmSuppressionGroup"{ HasComponent }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 129), NodeClass = NodeClass.ReferenceType, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.enUS, "ArgumentDescriptionOf") }
    class "HasArgumentDescription"  { HasComponent }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 15297), NodeClass = NodeClass.ReferenceType, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.enUS, "IsReaderInGroup") }
    class "HasDataSetReader"        { HasComponent }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 15296), NodeClass = NodeClass.ReferenceType, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.enUS, "IsWriterInGroup") }
    class "HasDataSetWriter"        { HasComponent }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 15112), NodeClass = NodeClass.ReferenceType, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.enUS, "GuardOf") }
    class "HasGuard"                { HasComponent }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 49), NodeClass = NodeClass.ReferenceType, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.enUS, "OrderedComponentOf") }
    class "HasOrderedComponent"     { HasComponent }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 14476), NodeClass = NodeClass.ReferenceType, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.enUS, "PubSubConnectionOf") }
    class "HasPubSubConnection"     { HasComponent }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 18805), NodeClass = NodeClass.ReferenceType, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.enUS, "IsReaderGroupOf") }
    class "HasReaderGroup"          { HasComponent }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 18804), NodeClass = NodeClass.ReferenceType, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.enUS, "IsWriterGroupOf") }
    class "HasWriterGroup"          { HasComponent }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 17276), NodeClass = NodeClass.ReferenceType, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.enUS, "MayBeDisabledBy") }
    class "HasEffectDisable"        { HasEffect }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 17983), NodeClass = NodeClass.ReferenceType, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.enUS, "MayBeEnabledBy") }
    class "HasEffectEnable"         { HasEffect }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 17984), NodeClass = NodeClass.ReferenceType, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.enUS, "MayBeSuppressedBy") }
    class "HasEffectSuppressed"     { HasEffect }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 17985), NodeClass = NodeClass.ReferenceType, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.enUS, "MayBeUnsuppressedBy") }
    class "HasEffectUnsuppressed"   { HasEffect }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 48), NodeClass = NodeClass.ReferenceType, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.enUS, "NotifierOf") }
    class "HasNotifier"             { HasEventSource }

    __Sealed__() __Node__{ NodeId = NodeId(NamespaceIndex.OPC_UA_URI, 131), NodeClass = NodeClass.ReferenceType, Symmetric = false, InverseName = LocalizedText(LocaleIdEnum.enUS, "OptionalInputArgumentDescriptionOf") }
    class "HasOptionalInputArgumentDescription" { HasArgumentDescription }
end)