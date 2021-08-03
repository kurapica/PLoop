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

    --- The Base NodeClass
    __Sealed__()  __NodeClass__{ Inheritable = true }
    class "Node"                (function(_ENV)
        export {
            __Node__, AddressSpace, Enum, Struct, Interface, Class, Namespace,
            QualifiedName, LocalizedText, LocaleIdEnum, StructCategory,

            type                = type,
            pairs               = pairs,
            getmetatable        = getmetatable,
            rawset              = rawset,
            rawget              = rawget,
            tonumber            = tonumber,
            tostring            = tostring,
            pcall               = pcall,
            throw               = throw,
            loadinittable       = Toolset.loadinittable,
            safeset             = Toolset.safeset,
            getNormalMetaMethod = Class.GetNormalMetaMethod,
            isSubType           = Class.IsSubType,
            getKeywordVisitor   = Environment.GetKeywordVisitor,
            backupKeywordAccess = Environment.BackupKeywordAccess,

            ListReferences      = List[References],
        }

        -- For cache to reduce the cost
        local _NormalCtor       = Toolset.newtable(true)

        local function getNormalCtor(cls)
            local ctor          = _NormalCtor[cls]

            if ctor == nil then
                ctor            = getNormalMetaMethod(cls, "__ctor") or false
                _NormalCtor     = safeset(_NormalCtor, cls, ctor)
            end

            return ctor
        end

        Runtime.OnTypeDefined   = Runtime.OnTypeDefined + function(ptype, cls)
            -- Clear the normal constructor cache
            if ptype == Class and isSubType(cls, Node) and _NormalCtor[cls] then
                _NormalCtor     = safeset(_NormalCtor, cls, nil)
            end
        end

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- Update the node version
        __Abstract__()
        function UpdateNodeVersion(self)
            self.NodeVersion    = tostring((self.NodeVersion and tonumber(self.NodeVersion) or 0) + 1)
        end

        -----------------------------------------------------------
        --                       attribute                       --
        -----------------------------------------------------------
        --- The persisted identifier
        property "NodeId"               { type = NodeId,        require = true }

        --- The NodeClass of node
        __Abstract__()
        property "NodeClass"            { type = NodeClass,     require = true, default = NodeClass.Unspecified }

        --- A non-localised readable name contains a namespace and a string
        property "BrowseName"           { type = QualifiedName, require = true }

        --- The localised name of the node
        property "DisplayName"          { type = LocalizedText, require = true }

        --- The localised description text
        property "Description"          { type = LocalizedText }

        --- The possibilities of a client to write the attributes of node
        property "WriteMask"            { type = AttributeWriteMask }

        --- The write mask that taking user access rights into accunt
        property "UserWriteMask"        { type = AttributeWriteMask }

        --- The permissions that apply to a Node for all Roles
        property "RolePermissions"      { type = struct { RolePermissionType } }

        --- The permissions that apply to a Node for all Roles granted to current Session
        property "UserRolePermissions"  { type = struct { RolePermissionType } }

        --- The AccessRestrictions apply to a Node
        property "AccessRestrictions"   { type = AccessRestrictionsType }

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        __Observable__()
        property "NodeVersion"          { type = String }

        --- The node target
        property "Target"               { type = Any }

        --- The Reference collections
        property "References"           { type = ListReferences, default = function() return ListReferences() end }

        --- The AddressSpace
        property "AddressSpace"         { type = AddressSpace }

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Final__() __Arguments__{ Any, NodeInfo/nil }
        function __ctor(self, target, init)
            local cls           = getmetatable(self)
            local base          = __Node__.GetNodeInfo(target)

            --- Register the nodes to the AddressSpace
            local addressSpace  = getKeywordVisitor(cls)
            if not addressSpace then throw("The Node can only be created in AddressSpace") end
            self.AddressSpace   = addressSpace
            self.Target         = target

            if type(init) == "table" and getmetatable(init) == nil then
                if not base then
                    base        = init
                else
                    for k, v in pairs(init) do
                        base[k] = v
                    end
                end
            end

            if not (base and base.NodeId) then throw("The NodeId of the Node must be specified") end

            -- Generate NodeInfo based on the target
            if Namespace.Validate(target) then
                if not base.BrowseName then
                    base.BrowseName     = QualifiedName(base.NodeId.namespaceIndex, Namespace.GetNamespaceName(target, true))
                end

                if not base.DisplayName then
                    base.DisplayName    = LocalizedText(LocaleIdEnum.enUS, base.BrowseName.name)
                end

                if Enum.Validate(target) then
                    base.SubtypeOf      = base.SubtypeOf or Enum
                elseif Struct.Validate(target) then
                    local stype         = Struct.GetStructCategory(target)

                    if stype == StructCategory.CUSTOM then
                        base.SubtypeOf  = base.SubtypeOf or Struct.GetBaseStruct(target)
                    elseif stype == StructCategory.MEMBER then
                        base.SubtypeOf  = base.SubtypeOf or Struct
                    elseif stype == StructCategory.ARRAY then
                    elseif stype == StructCategory.DICTIONARY then
                    end
                elseif Class.Validate(target) then
                    base.SubtypeOf      = base.SubtypeOf or Class.GetSuperClass(target)
                end
            end

            -- Load init table as default
            if base then
                local ok, err   = pcall(loadinittable, self, base)
                if not ok then throw(err) end
            end

            local ctor          = getNormalCtor(cls)
            if ctor then ctor(self) end

            --- Register the nodes to the AddressSpace
            addressSpace:RegisterNode(self)
        end

        __Final__() function __exist(cls, target)
            local accessor      = backupKeywordAccess()
            if accessor and accessor.key == cls then
                return accessor.visitor:GetNode(target)
            end
        end

        -----------------------------------------------------------
        --                      meta-method                      --
        -----------------------------------------------------------
        --- The access to References
        function __index(self, key)
            local refType, isInverse    = __Node__.GetReferenceType(key)
            if refType then
                for _, ref in self.References:GetIterator() do
                    if getmetatable(ref) == refType and (not isInverse == not ref.IsInverse) then
                        return ref
                    end
                end

                local ref               = refType(isInverse)
                if ref:SetSource(self) then
                    self.References:Insert(ref)
                    return ref
                end
            end
        end

        function __newindex(self, key, value)
            local refType, isInverse    = __Node__.GetReferenceType(key)
            if refType then
                local tref
                for _, ref in self.References:GetIterator() do
                    if getmetatable(ref) == refType and (not isInverse == not ref.IsInverse) then
                        tref            = ref
                        break
                    end
                end

                if not tref then
                    tref                = refType(isInverse)
                    if tref:SetSource(self) then
                        self.References:Insert(tref)
                    else
                        tref            = nil
                    end
                end

                if tref then return tref:AddTarget(value) end
            end

            error("The Node only accept Reference target", 2)
        end
    end)

    --- The ReferenceType NodeClass, its object will be used to generate the References
    __Sealed__()
    class "ReferenceType"       (function(_ENV)
        inherit "Node"

        -----------------------------------------------------------
        --                       attribute                       --
        -----------------------------------------------------------
        --- The NodeClass of node
        property "NodeClass"    { type = NodeClass, require = true, default = NodeClass.ReferenceType }

        --- Whether the ReferenceType is abstract
        __Abstract__()
        property "IsAbstract"   { type = Boolean,   require = true, default = true }

        --- Whether the meaning of the ReferenceType is the same as seen from both the SourceNode and the TargetNode
        __Abstract__()
        property "Symmetric"    { type = Boolean,   require = true, default = true }

        --- The meaning of the ReferenceType as seen from the TargetNode
        __Abstract__()
        property "InverseName"  { type = LocalizedText }

    end)
end)