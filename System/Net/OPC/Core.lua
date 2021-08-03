--===========================================================================--
--                                                                           --
--                         System.Net.Protocol.OPC                           --
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

    export { validateValue = Struct.ValidateValue, Guid, "type" }

    ---------------------------------------------------
    --                Pre-Definition                 --
    ---------------------------------------------------
    class "AddressSpace"        {}
    class "Node"                {}
    enum "NodeClass"            {}

    _G.AddressSpace             = AddressSpace

    ---------------------------------------------------
    --                   Attribute                   --
    ---------------------------------------------------
    --- The reserved namespace index
    __Sealed__()
    enum "NamespaceIndex"       {
        OPC_UA_URI              = 0,    -- http://opcfoundation.org/UA/
        LOCAL_SERVER            = 1,
    }

    --- The basic locale id
    __Sealed__()
    enum "LocaleIdEnum"         {
        enUS                    = "en-US",
        zhCN                    = "zh-CN",
    }

    --- the type of the NodeId
    __Sealed__()
    enum "IdType"               {
        NUMERIC                 = 0,    -- Numeric value
        STRING                  = 1,    -- String value, case sensitive
        GUID                    = 2,    -- Globally Unique Identifier
        OPAQUE                  = 3,    -- Namespace specific format, identifiers that are free-format byte strings that might or might not be human interpretable
    }

    --- The node identifier structure, will be re-defined later
    struct "NodeId"             {
        { name = "namespaceIndex", type = Number, require = true },  -- The index for a namespace URI
        { name = "identifier",     type = Any,    require = true },  -- The identifier for a Node in the AddressSpace of an OPC UA Server
        { name = "identifierType", type = IdType },                  -- The format and data type of the identifier

        __init                  = function (self)
            if self.identifierType then return end

            local tid           = type(self.identifier)
            self.identifierType = tid == "number" and IdType.NUMERIC
                                or tid == "string" and (validateValue(Guid, self.identifier) and IdType.GUID or IdType.STRING)
                                or IdType.OPAQUE
        end
    }

    struct "QualifiedName"      {
        { name = "namespaceIndex", type = Number, require = true },  -- Index that identifies the namespace that defines the name
        { name = "name",           type = String, require = true },  -- The text portion of the QualifiedName, 512 characters
    }

    --- The node information, full version will be defined later
    struct "NodeInfo"             {
        --- The persisted identifier
        { name = "NodeId",      type = NodeId, require = true },

        --- A non-localised readable name contains a namespace and a string
        { name = "BrowseName",  type = QualifiedName },

        --- Whether the ReferenceType is abstract
        { name = "IsAbstract",  type = Boolean },

        --- The super type of the node
        { name = "SubtypeOf",   type = Any },
    }

    --- The Node Info of the target
    __Sealed__() class "__Node__" (function(_ENV)
        extend "IAttachAttribute"

        export {
            __Node__, IdType, Struct, Guid, NodeClass,
            safeset             = Toolset.safeset,
            clone               = Toolset.clone,
            throw               = throw,
            type                = type,
            error               = error,
            isClass             = Class.Validate,
            isAbstract          = Class.IsAbstract,
            getSuperClass       = Class.GetSuperClass,
            band                = Toolset.band,
            getNamespaceName    = Namespace.GetNamespaceName,
        }

        -- Inner cache
        local _NodeInfo         = Toolset.newtable(true)
        local _IdTargets        = {}
        local _RefTypes         = {}
        local _InvRefTypes      = {}

        -----------------------------------------------------------
        --                     static method                     --
        -----------------------------------------------------------
        --- Registers a target with NodeId
        __Static__() __Arguments__{ Any, NodeInfo }:Throwable()
        function RegisterNode(target, info)
            local nodeId        = info.NodeId
            if _IdTargets[nodeId.namespaceIndex] and _IdTargets[nodeId.namespaceIndex][nodeId.identifier] then throw("The NodeId is already used") end

            -- Check the Node Class
            if not info.NodeClass then
                if isClass(target) then
                    local scls  = getSuperClass(target)
                    local sinfo = scls and _NodeInfo[scls]
                    info.NodeClass = sinfo and sinfo.NodeClass
                end
            end

            if info.NodeClass and band(info.NodeClass, NodeClass.ReferenceType) == NodeClass.ReferenceType then
                local name      = info.BrowseName and info.BrowseName.name or getNamespaceName(target, true)
                if not name or _RefTypes[name] then throw("The ReferenceType must have unique BrowseName") end

                _RefTypes       = safeset(_RefTypes, name, target)

                if info.Symmetric or info.InverseName then
                    name        = info.Symmetric and name or info.InverseName.text
                    if not name or _InvRefTypes[name] then throw("The InverseName must be provided and unique") end

                    _InvRefTypes= safeset(_InvRefTypes, name, target)
                end
            end

            _NodeInfo           = safeset(_NodeInfo,  target, clone(info, true))
            _IdTargets          = safeset(_IdTargets, nodeId.namespaceIndex, safeset(_IdTargets[nodeId.namespaceIndex] or {}, nodeId.identifier, target))

            return true
        end

        --- Gets the NodeId of a target
        __Static__() function GetNodeInfo(target, name)
            if name then
                return _NodeInfo[target] and clone(_NodeInfo[target][name], true)
            else
                return clone(_NodeInfo[target], true)
            end
        end

        --- Gets the target by NodeId
        __Static__() __Arguments__{ NaturalNumber, Any }
        function GetTarget(namespaceIndex, identifier)
            return _IdTargets[namespaceIndex] and _IdTargets[namespaceIndex][identifier]
        end

        __Static__() __Arguments__{ NodeId }
        function GetTarget(nodeId)
            local nodes         = _IdTargets[nodeId.namespaceIndex]
            return nodes and nodes[nodeId.identifier]
        end

        --- Gets the Reference by name with IsInverse flag
        __Static__() function GetReferenceType(name)
            local target        = _RefTypes[name]
            if target then return target end

            target              = _InvRefTypes[name]
            if target then return target, true end
        end

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- attach data on the target
        function AttachAttribute(self, target, targettype, owner, name, stack)
            local ok, err       = pcall(__Node__.RegisterNode, target, self[1])
            if not ok then
                error(tostring(err), stack + 1)
            end
        end

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- the attribute target
        property "AttributeTarget"  { set = false, default = AttributeTargets.All }

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{ NodeInfo }
        function __new(_, info)
            return { info }, true
        end
    end)

    --- The node class declaration, so those classed will be registered as
    -- the keyword of the AddressSpace, and create nodes based on them will
    -- register the nodes to AddressSpace
    __Sealed__()
    class "__NodeClass__"       (function(_ENV)
        extend "IAttachAttribute"

        export { Environment, Namespace, AddressSpace }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- Register the node class as keyword to the AddressSpace
        function AttachAttribute(self, target, targettype, owner, name, stack)
            Environment.RegisterContextKeyword(AddressSpace, Namespace.GetNamespaceName(target, true), target)
        end

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- the attribute target
        property "AttributeTarget"  { set = false, default = AttributeTargets.Class }
    end)


    ---------------------------------------------------
    --                 AddressSpace                  --
    ---------------------------------------------------
    --- The AddressSpace Module to contains the Nodes
    __Sealed__()
    class "AddressSpace"        (function(_ENV)
        inherit "Module"

        export{
            throw               = throw,
            safeset             = Toolset.safeset,
            importNamespace     = Environment.ImportNamespace,
        }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- Register Nodes, should only be used by Node object during creation
        function RegisterNode(self, node)
            local _Nodes        = self.__Nodes
            local nodeId        = node.NodeId
            local namespaceIndex= nodeId.namespaceIndex
            local identifier    = nodeId.identifier

            if _Nodes[namespaceIndex] and _Nodes[namespaceIndex][identifier] then throw("The NodeId of the Node must be unique") end

            self.__Nodes        = safeset(_Nodes, namespaceIndex, safeset(_Nodes[namespaceIndex] or {}, identifier, node))
            self.__Targets      = safeset(self.__Targets, node.Target, node)
        end

        --- Gets a nodes by node Id
        __Arguments__{ NaturalNumber, Any }
        function GetNode(self, namespaceIndex, identifier)
            local _Nodes        = self.__Nodes
            return _Nodes[namespaceIndex] and _Nodes[namespaceIndex][identifier]
        end

        __Arguments__{ NodeId }
        function GetNode(self, nodeId)
            local _Nodes        = self._Nodes[nodeId.namespaceIndex]
            return _Nodes and _Nodes[nodeId.identifier]
        end

        __Arguments__{ Any }
        function GetNode(self, target)
            return self.__Targets[target]
        end

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        function __ctor(self, ...)
            super(self, ...)

            self.__Nodes        = {}
            self.__Targets      = {}

            importNamespace(self, "System.Net.OPC")
        end
    end)
end)