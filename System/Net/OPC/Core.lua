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
    class "AddressSpace"                {}
    class "Node"                        {}
    class "ReferenceType"               {}
    class "View"                        {}
    class "Object"                      {}
    class "ObjectType"                  {}
    class "Variable"                    {}
    class "VariableType"                {}
    class "Method"                      {}
    class "DataType"                    {}

    class "References"                  {}
    class "PropertyType"                {}
    class "BaseObjectType"              {}
    class "ModellingRuleType"           {}

    class "HasProperty"                 {}
    class "HasComponent"                {}

    enum "NodeClass"                    {}

    _G.AddressSpace                     = AddressSpace

    ---------------------------------------------------
    --                   Attribute                   --
    ---------------------------------------------------
    --- The reserved namespace index
    __Sealed__()
    enum "NamespaceIndex"               {
        OPC_UA_URI                      = 0,    -- http://opcfoundation.org/UA/
        LOCAL_SERVER                    = 1,
    }

    --- The basic locale id
    __Sealed__()
    enum "LocaleIdEnum"                 {
        en                              = "en",                -- English
        zh                              = "zh",                -- Chinese
        enUS                            = "en-US",             -- American English
        esES                            = "es-ES",             -- Spanish (European)
        esMX                            = "es-MX",             -- Spanish (Latin American)
        itIT                            = "it-IT",             -- Italian (Italy)
        deDE                            = "de-DE",             -- German
        frFR                            = "fr-FR",             -- French
        koKR                            = "ko-KR",             -- Korean
        ptBR                            = "pt-BR",             -- Portuguese (Brazil)
        ruRU                            = "ru-RU",             -- Russian
        zhCN                            = "zh-CHS",            -- Chinese (simplified; mainland China)
        zhTW                            = "zh-CHT",            -- Chinese (traditional; Taiwan)
    }

    --- the type of the NodeId
    __Sealed__()
    enum "IdType"                       {
        NUMERIC                         = 0,    -- Numeric value
        STRING                          = 1,    -- String value, case sensitive
        GUID                            = 2,    -- Globally Unique Identifier
        OPAQUE                          = 3,    -- Namespace specific format, identifiers that are free-format byte strings that might or might not be human interpretable
    }

    --- The Modelling Rule
    __Sealed__()
    enum "NamingRuleType"               {
        Mandatory                       = 1, -- The BrowseName must appear in all instances of the type.
        Optional                        = 2, -- The BrowseName may appear in an instance of the type.
        Constraint                      = 3, -- The modelling rule defines a constraint and the BrowseName is not used in an instance of the type.
    }

    __Sealed__()
    enum "ModellingRule"                {
        "Mandatory",
        "Optional",
        "ExposesItsArray",
        "OptionalPlaceholder",
        "MandatoryPlaceholder",
    }

    --- The node attribtues
    __Sealed__()
    enum "AttributeId"                  {
        "NodeId",
        "NodeClass",
        "BrowseName",
        "DisplayName",
        "Description",
        "WriteMask",
        "UserWriteMask",
        "RolePermissions",
        "UserRolePermissions",
        "AccessRestrictions",
        "IsAbstract",
        "Symmetric",
        "InverseName",
        "ContainsNoLoops",
        "EventNotifier",
        "Value",
        "DataType",
        "ValueRank",
        "ArrayDimensions",
        "AccessLevel",
        "UserAccessLevel",
        "MinimumSamplingInterval",
        "Historizing",
        "Executable",
        "UserExecutable",
        "DataTypeDefinition",
        "AccessLevelEx",
    }

    --- The node identifier structure, will be re-defined later
    struct "NodeId"                     {
        { name = "namespaceIndex", type = Number, require = true },  -- The index for a namespace URI
        { name = "identifier",     type = Any,    require = true },  -- The identifier for a Node in the AddressSpace of an OPC UA Server
        { name = "identifierType", type = IdType },                  -- The format and data type of the identifier

        __init                          = function (self)
            if self.identifierType then return end

            local tid                   = type(self.identifier)
            self.identifierType         = tid == "number" and IdType.NUMERIC
                                        or tid == "string" and (validateValue(Guid, self.identifier) and IdType.GUID or IdType.STRING)
                                        or IdType.OPAQUE
        end
    }

    struct "QualifiedName"              {
        { name = "namespaceIndex", type = Number, require = true },  -- Index that identifies the namespace that defines the name
        { name = "name",           type = String, require = true },  -- The text portion of the QualifiedName, 512 characters
    }

    --- The localizaed text, pre-definition
    struct "LocalizedText"              {
        { name = "locale", type = LocaleId, require = true },  -- The identifier for the locale (e.g. "en-US")
        { name = "text",   type = String,   require = true },
    }

    --- The node information, full version will be defined later
    struct "NodeInfo"                   {
        --- The persisted identifier
        { name = "NodeId",      type = NodeId + NaturalNumber },

        --- A non-localised readable name contains a namespace and a string
        { name = "BrowseName",  type = QualifiedName + String },

        --- The localised name of the node
        { name = "DisplayName", type = LocalizedText + String },

        --- The localised description text
        { name = "Description", type = LocalizedText + String },

        --- Whether the ReferenceType is abstract
        { name = "IsAbstract",  type = Boolean },

        --- Use ModellingRule instead of the real node
        { name = "HasModellingRule", type = ModellingRule },

        --- The super type of the node
        { name = "SubtypeOf",   type = Any },

        __init                          = function(self)
            if type(self.NodeId) == "number" then
                self.NodeId             = NodeId(NamespaceIndex.OPC_UA_URI, self.NodeId)
            end

            if type(self.BrowseName) == "string" then
                self.BrowseName         = QualifiedName(NamespaceIndex.OPC_UA_URI, self.BrowseName)
            end

            if type(self.DisplayName) == "string" then
                self.DisplayName        = LocalizedText(LocaleIdEnum.en, self.DisplayName)
            end

            if type(self.Description) == "string" then
                self.Description        = LocalizedText(LocaleIdEnum.en, self.Description)
            end
        end
    }

    --- The Node Info of the target
    __Sealed__()
    class "__Node__"                    (function(_ENV)
        extend "IAttachAttribute"

        export {
            __Node__, IdType, Struct, Guid, NodeClass, __Arguments__, __Return__, AnyType, Attribute, References,

            safeset                     = Toolset.safeset,
            clone                       = Toolset.clone,
            throw                       = throw,
            type                        = type,
            ipairs                      = ipairs,
            error                       = error,
            isClass                     = Class.Validate,
            isSubType                   = Class.IsSubType,
            isAbstract                  = Class.IsAbstract,
            getSuperClass               = Class.GetSuperClass,
            band                        = Toolset.band,
            getNamespaceName            = Namespace.GetNamespaceName,
            Variable                    = System.Variable,
            isStruct                    = Struct.Validate,
            getStructCategory           = Struct.GetStructCategory,
            validate                    = Struct.ValidateValue,
            isProperty                  = Property.Validate,
        }

        -- Inner cache
        local _NodeInfo                 = Toolset.newtable(true)
        local _IdTargets                = {}
        local _RefTypes                 = {}
        local _InvRefTypes              = {}
        local _AnyDimTypes              = {}

        local function getAnyDimTypes(dtype)
            local atype                 = _AnyDimTypes[dtype]
            if not atype then
                -- Just a simple declaration
                atype                   = struct(_ENV, getNamespaceName(dtype, true) .. "s") { }

                __Sealed__()
                struct(atype)   { dtype + atype }

                _AnyDimTypes            = safeset(_AnyDimTypes, dtype, atype)
            end

            return atype
        end

        -----------------------------------------------------------
        --                     static method                     --
        -----------------------------------------------------------
        --- Registers a target with NodeId
        __Static__() __Arguments__{ Any, NodeInfo }:Throwable()
        function RegisterNode(target, info)
            local nodeId                = info.NodeId

            if nodeId then
                local etarget           = _IdTargets[nodeId.namespaceIndex] and _IdTargets[nodeId.namespaceIndex][nodeId.identifier]
                if etarget then
                    -- The OPC UA could share properties but the PLoop can't, so they'll share the same node info
                    if isProperty(target) and isProperty(etarget) and target:GetName() == etarget:GetName() and target:GetType() == etarget:GetType() then
                        _NodeInfo       = safeset(_NodeInfo, target, _NodeInfo[etarget])
                    else
                        throw("The NodeId is already used")
                    end
                else
                    if info.NodeClass and band(info.NodeClass, NodeClass.ReferenceType) == NodeClass.ReferenceType or isSubType(target, References) then
                        local name      = info.BrowseName and info.BrowseName.name or getNamespaceName(target, true)
                        if not name or _RefTypes[name] then throw("The ReferenceType must have unique BrowseName") end

                        _RefTypes       = safeset(_RefTypes, name, target)

                        if info.Symmetric or info.InverseName then
                            name        = info.Symmetric and name or info.InverseName.text
                            if not name or _InvRefTypes[name] then throw("The InverseName must be provided and unique") end

                            _InvRefTypes= safeset(_InvRefTypes, name, target)
                        end
                    end
                    _IdTargets          = safeset(_IdTargets, nodeId.namespaceIndex, safeset(_IdTargets[nodeId.namespaceIndex] or {}, nodeId.identifier, target))
                end
            end

            _NodeInfo                   = safeset(_NodeInfo,  target, clone(info, true))

            return true
        end

        --- Whether the target has node info
        __Static__()
        function HasNodeInfo(target, name)
            if name then
                return _NodeInfo[target] and _NodeInfo[target][name] and true or false
            else
                return _NodeInfo[target] and true or false
            end
        end

        --- Gets the NodeId of a target
        __Static__()
        function GetNodeInfo(target, name)
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
            local nodes                 = _IdTargets[nodeId.namespaceIndex]
            return nodes and nodes[nodeId.identifier]
        end

        --- Gets the Reference by name with IsInverse flag
        __Static__()
        function GetReferenceType(name)
            local target                = _RefTypes[name]
            if target then return target end

            target                      = _InvRefTypes[name]
            if target then return target, true end
        end

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- attach data on the target
        function AttachAttribute(self, target, targettype, owner, name, stack)
            if targettype ~= AttributeTargets.Function then
                local ok, err           = pcall(__Node__.RegisterNode, target, self[1])
                if not ok then error(tostring(err), stack + 1) end
            else
                -- For object method
                -- @todo: later
            end
        end

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- the attribute target
        property "AttributeTarget"      { set = false, default = AttributeTargets.Class + AttributeTargets.Struct + AttributeTargets.Enum + AttributeTargets.Method + AttributeTargets.Property + AttributeTargets.Event + AttributeTargets.Function }

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{ NodeInfo/nil }
        function __new(_, info)
            info                        = info or {}

            if info.InputArguments then
                local args              = {}

                for i, arg in ipairs(info.InputArguments) do
                    local rank          = arg.valueRank or -1
                    local dtype         = __Node__.GetTarget(arg.dataType) or Any

                    if not validate(AnyType, dtype) then
                        throw("The input argument must use valdiation type as dataType.")
                    end

                    if rank == -3 then
                        -- ScalarOrOneDimension
                        Attribute.IndependentCall(function()
                            args[i]     = dtype + struct { dtype }
                        end)
                    elseif rank == -2 then
                        -- A scalar or an array with any number of dimensions
                        Attribute.IndependentCall(function()
                            args[i]     = dtype + getAnyDimTypes(dtype)
                        end)
                    elseif rank == -1 then
                        -- Scalar
                        args[i]         = dtype
                    elseif rank == 0 then
                        -- OneOrMoreDimensions
                        Attribute.IndependentCall(function()
                            args[i]     = getAnyDimTypes(dtype)
                        end)
                    else
                        -- The specified number of dimensions
                        Attribute.IndependentCall(function()
                            for i = 1, rank do
                                dtype   = struct { dtype }
                            end

                            -- OneDimensiong
                            args[i]     = dtype
                        end)
                    end
                end

                __Arguments__(args)
            end

            if info.OutputArguments then
                local args              = {}

                for i, arg in ipairs(info.InputArguments) do
                    local rank          = arg.valueRank or -1
                    local dtype         = __Node__.GetTarget(arg.dataType) or Any

                    if not validate(AnyType, dtype) then
                        throw("The input argument must use valdiation type as dataType.")
                    end

                    if rank == -3 then
                        -- ScalarOrOneDimension
                        Attribute.IndependentCall(function()
                            args[i]     = dtype + struct { dtype }
                        end)
                    elseif rank == -2 then
                        -- A scalar or an array with any number of dimensions
                        Attribute.IndependentCall(function()
                            args[i]     = dtype + getAnyDimTypes(dtype)
                        end)
                    elseif rank == -1 then
                        -- Scalar
                        args[i]         = dtype
                    elseif rank == 0 then
                        -- OneOrMoreDimensions
                        Attribute.IndependentCall(function()
                            args[i]     = getAnyDimTypes(dtype)
                        end)
                    else
                        -- The specified number of dimensions
                        Attribute.IndependentCall(function()
                            for i = 1, rank do
                                dtype   = struct { dtype }
                            end

                            -- OneDimension
                            args[i]     = dtype
                        end)
                    end
                end

                __Return__(args)
            end

            return { info }, true
        end
    end)

    --- The node class declaration, so those classed will be registered as the keyword
    -- of the AddressSpace, and create nodes based on them will register the nodes to
    -- AddressSpace
    __Sealed__()
    class "__NodeClass__"               (function(_ENV)
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
        property "AttributeTarget"      { set = false, default = AttributeTargets.Class }
    end)

    ---------------------------------------------------
    --                 AddressSpace                  --
    ---------------------------------------------------
    --- The AddressSpace Module to contains the Nodes, the AddressSpace are also used as
    -- the View, its sub-moduels can be used as view node's entity(not view NodeClass)
    __Sealed__()
    class "AddressSpace"                (function(_ENV)
        inherit "Module"

        export{
            Node, ReferenceType, View, Object, ObjectType, VariableType, Variable, Method, DataType, NamespaceIndex, LocaleIdEnum,
            NodeId, QualifiedName, __Node__, Environment, NodeClass, References, PropertyType, ModellingRuleType, NamingRuleType,

            throw                       = throw,
            type                        = type,
            pairs                       = pairs,
            tonumber                    = tonumber,
            safeset                     = Toolset.safeset,
            importNamespace             = Environment.ImportNamespace,
            isClass                     = Class.Validate,
            isEnum                      = Enum.Validate,
            isStruct                    = Struct.Validate,
            isProp                      = Property.Validate,
            isEvent                     = Event.Validate,
            isSubType                   = Class.IsSubType,
            isObjectType                = Class.IsObjectType,
            isAbstract                  = Class.IsAbstract,
        }

        local function createNode(self, target, base)
            local nodeInfo              = __Node__.GetNodeInfo(target)

            if not nodeInfo then
                if base then
                    nodeInfo            = base
                else
                    return
                end
            elseif base then
                for k, v in pairs(base) do
                    nodeInfo[k]         = v
                end
            end

            local nodeCls               = nodeInfo.NodeClass

            local nodeType              =  nodeCls == NodeClass.Object and Object
                                        or nodeCls == NodeClass.Variable and Variable
                                        or nodeCls == NodeClass.Method and Method
                                        or nodeCls == NodeClass.ObjectType and ObjectType
                                        or nodeCls == NodeClass.VariableType and VariableType
                                        or nodeCls == NodeClass.ReferenceType and ReferenceType
                                        or nodeCls == NodeClass.DataType and DataType
                                        -- or nodeCls == NodeClass.View and View

            if isClass(target) then
                if isSubType(target, References) then
                    nodeType            = ReferenceType
                else
                    nodeType            = ObjectType
                end
            elseif isEnum(target) or isStruct(target) then
                nodeType                = DataType
            elseif isObjectType(target, PropertyType) then
                nodeType                = PropertyType
            elseif isClass(getmetatable(target)) then
                nodeType                = Object
            end

            if not nodeType then return end

            return nodeType(self, target, nodeInfo)
        end

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- Register Nodes, should only be used by Node object during creation
        function RegisterNode(self, node)
            local addressSpace          = self.AddressSpace

            local _Nodes                = addressSpace.__Nodes
            local nodeId                = node.NodeId
            if not nodeId then throw("The NodeId of the Node must be provided") end

            local namespaceIndex        = nodeId.namespaceIndex
            local identifier            = nodeId.identifier

            if _Nodes[namespaceIndex] and _Nodes[namespaceIndex][identifier] then throw("The NodeId of the Node must be unique") end

            addressSpace.__Nodes        = safeset(_Nodes, namespaceIndex, safeset(_Nodes[namespaceIndex] or {}, identifier, node))
            addressSpace.__Targets      = safeset(addressSpace.__Targets, node.Target, node)

            if self.View then
                self.View.ViewVersion   = self.View.ViewVersion + 1
            end
        end

        --- RemoveNode
         __Arguments__{ Node }
        function RemoveNode(self, node)
            local addressSpace          = self.AddressSpace

            local _Nodes                = addressSpace.__Nodes
            local nodeId                = node.NodeId
            local namespaceIndex        = nodeId.namespaceIndex
            local identifier            = nodeId.identifier

            if not (_Nodes[namespaceIndex] and _Nodes[namespaceIndex][identifier]) then return end

            addressSpace.__Nodes        = safeset(_Nodes, namespaceIndex, safeset(_Nodes[namespaceIndex], identifier, nil))
            addressSpace.__Targets      = safeset(addressSpace.__Targets, node.Target, nil)

            self.View.ViewVersion       = self.View.ViewVersion + 1

            -- Release all references
            for name, reference in pairs(addressSpace.__References) do
                reference:RemoveReferences(node)
            end
        end

        --- Gets a nodes by node Id
        __Arguments__{ NaturalNumber, Any, (Boolean + NodeInfo)/nil }
        function GetNode(self, namespaceIndex, identifier, create)
            local _Nodes                = self.AddressSpace.__Nodes
            local node                  = _Nodes[namespaceIndex] and _Nodes[namespaceIndex][identifier]

            if node or not create then return node end

            local target                = __Node__.GetTarget(namespaceIndex, identifier)
            return target and createNode(self, target, type(create) == "table" and create or nil)
        end

        __Arguments__{ NodeId, (Boolean + NodeInfo)/nil }
        function GetNode(self, nodeId, create)
            local _Nodes                = self.AddressSpace.__Nodes[nodeId.namespaceIndex]
            local node                  = _Nodes and _Nodes[nodeId.identifier]

            if node or not create then return node end

            local target                = __Node__.GetTarget(nodeId)
            return target and createNode(self, target, type(create) == "table" and create or nil)
        end

        __Arguments__{ Any, (Boolean + NodeInfo)/nil }
        function GetNode(self, target, create)
            local node                  = self.AddressSpace.__Targets[target]
            if node or not create then return node end

            return createNode(self, target, type(create) == "table" and create or nil)
        end

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- The view node
        property "View"                 { type = View }

        --- The address space, also the root module
        property "AddressSpace"         { set = false, default = function(self) return self._Parent and self._Parent.AddressSpace or self end }

        --- The References Register
        __Indexer__(String)
        property "References"           {
            get                         = function(self, name)
                self                    = self.AddressSpace

                local refs              = self.__References
                local refType, isInverse= __Node__.GetReferenceType(name)
                if refType and not isAbstract(refType) then
                    local ref           = refs[name]

                    if not ref then
                        ref             = refType(self, isInverse)
                        self.__References = safeset(refs, name, ref)
                    end

                    return ref
                end
            end,
        }

        --- The ModellingRuleType Node Accessor
        __Indexer__(ModellingRule)
        property "ModellingRules"       { get = function(self, rule) return self.AddressSpace.__ModellingRules[rule] end }

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        function __ctor(self, ...)
            super(self, ...)

            if not self._Parent then
                self.__Nodes            = {}
                self.__Targets          = {}
                self.__References       = {}

                importNamespace(self, "System.Net.OPC")
            end

            self.View                   = View(self, self, {
                NodeId                  = NodeId(NamespaceIndex.LOCAL_SERVER, "System.Net.OPC.View:" .. self._FullName),
                BrowseName              = QualifiedName(NamespaceIndex.LOCAL_SERVER, self._FullName),
            })

            -- Basic ModellingRuleType
            if not self._Parent then
                self.__ModellingRules   = {
                    [ModellingRule.Mandatory]           = ModellingRuleType(self, {
                        NodeId                          = NodeId(NamespaceIndex.OPC_UA_URI, 78),
                        BrowseName                      = QualifiedName(NamespaceIndex.OPC_UA_URI, "Mandatory"),
                        DisplayName                     = LocalizedText(LocaleIdEnum.en, "Mandatory"),
                        NamingRule                      = NamingRuleType.Mandatory,

                        HasProperty                     = NodeId(NamespaceIndex.OPC_UA_URI, 112),
                    }),
                    [ModellingRule.Optional]            = ModellingRuleType(self, {
                        NodeId                          = NodeId(NamespaceIndex.OPC_UA_URI, 80),
                        BrowseName                      = QualifiedName(NamespaceIndex.OPC_UA_URI, "Optional"),
                        DisplayName                     = LocalizedText(LocaleIdEnum.en, "Optional"),
                        NamingRule                      = NamingRuleType.Optional,

                        HasProperty                     = NodeId(NamespaceIndex.OPC_UA_URI, 113),
                    }),
                    [ModellingRule.ExposesItsArray]     = ModellingRuleType(self, {
                        NodeId                          = NodeId(NamespaceIndex.OPC_UA_URI, 83),
                        BrowseName                      = QualifiedName(NamespaceIndex.OPC_UA_URI, "ExposesItsArray"),
                        DisplayName                     = LocalizedText(LocaleIdEnum.en, "ExposesItsArray"),
                        NamingRule                      = NamingRuleType.Constraint,

                        HasProperty                     = NodeId(NamespaceIndex.OPC_UA_URI, 114),
                    }),
                    [ModellingRule.OptionalPlaceholder] = ModellingRuleType(self, {
                        NodeId                          = NodeId(NamespaceIndex.OPC_UA_URI, 11508),
                        BrowseName                      = QualifiedName(NamespaceIndex.OPC_UA_URI, "OptionalPlaceholder"),
                        DisplayName                     = LocalizedText(LocaleIdEnum.en, "OptionalPlaceholder"),
                        NamingRule                      = NamingRuleType.Constraint,

                        HasProperty                     = NodeId(NamespaceIndex.OPC_UA_URI, 11509),
                    }),
                    [ModellingRule.MandatoryPlaceholder]= ModellingRuleType(self, {
                        NodeId                          = NodeId(NamespaceIndex.OPC_UA_URI, 11510),
                        BrowseName                      = QualifiedName(NamespaceIndex.OPC_UA_URI, "MandatoryPlaceholder"),
                        DisplayName                     = LocalizedText(LocaleIdEnum.en, "MandatoryPlaceholder"),
                        NamingRule                      = NamingRuleType.Constraint,

                        HasProperty                     = NodeId(NamespaceIndex.OPC_UA_URI, 11511),
                    }),
                }
            end
        end
    end)
end)