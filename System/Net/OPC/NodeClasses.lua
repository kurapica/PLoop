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
    class "Node"                        (function(_ENV)
        export                          {
            __Node__, AddressSpace, Enum, Struct, Interface, Class, Namespace,
            StructCategory, Property, Environment, Event, XList, Union, UInt32,
            QualifiedName, LocalizedText, LocaleIdEnum, Any, Node, ModellingRuleType,
            PropertyType, NodeId, NamespaceIndex, NodeInfo,

            type                        = type,
            pairs                       = pairs,
            getmetatable                = getmetatable,
            rawset                      = rawset,
            rawget                      = rawget,
            tonumber                    = tonumber,
            tostring                    = tostring,
            pcall                       = pcall,
            throw                       = throw,
            fakefunc                    = Toolset.fakefunc,
            loadinittable               = Toolset.loadinittable,
            safeset                     = Toolset.safeset,
            validateValue               = Struct.ValidateValue,
            getFeature                  = Class.GetFeature,
            isProperty                  = Property.Validate,
        }

        local nodeAttrs                 = XDictionary(Enum.GetEnumValues(AttributeId)):ToTable()

        -- For cache to reduce the cost
        local _NormalCtor               = Toolset.newtable(true)

        local function getNormalCtor(cls)
            local ctor                  = _NormalCtor[cls]

            if ctor == nil then
                ctor                    = Class.GetNormalMetaMethod(cls, "__ctor") or false
                _NormalCtor             = safeset(_NormalCtor, cls, ctor)
            end

            return ctor
        end

        Runtime.OnTypeDefined           = Runtime.OnTypeDefined + function(ptype, cls)
            -- Clear the normal constructor cache
            if ptype == Class and Class.IsSubType(cls, Node) and _NormalCtor[cls] then
                _NormalCtor             = safeset(_NormalCtor, cls, nil)
            end
        end

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- Update the node version
        __Abstract__()
        function UpdateNodeVersion(self)
            self.NodeVersion            = tostring((self.NodeVersion and tonumber(self.NodeVersion) or 0) + 1)
        end

        -----------------------------------------------------------
        --                       attribute                       --
        -----------------------------------------------------------
        --- The persisted identifier
        __Abstract__()
        property "NodeId"               { type = NodeId,        require = true }

        --- The NodeClass of node
        __Abstract__()
        property "NodeClass"            { type = NodeClass,     require = true, default = NodeClass.Unspecified }

        --- A non-localised readable name contains a namespace and a string
        __Abstract__()
        property "BrowseName"           { type = QualifiedName, require = true }

        --- The localised name of the node
        __Abstract__()
        property "DisplayName"          { type = LocalizedText, require = true }

        --- The localised description text
        __Abstract__()
        property "Description"          { type = LocalizedText }

        --- The possibilities of a client to write the attributes of node
        __Abstract__()
        property "WriteMask"            { type = AttributeWriteMask }

        --- The write mask that taking user access rights into accunt
        __Abstract__()
        property "UserWriteMask"        { type = AttributeWriteMask }

        --- The permissions that apply to a Node for all Roles
        __Abstract__()
        property "RolePermissions"      { type = struct { RolePermissionType } }

        --- The permissions that apply to a Node for all Roles granted to current Session
        __Abstract__()
        property "UserRolePermissions"  { type = struct { RolePermissionType } }

        --- The AccessRestrictions apply to a Node
        __Abstract__()
        property "AccessRestrictions"   { type = AccessRestrictionsType }

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        __Observable__() __Node__{ NodeId = 3068 }
        property "NodeVersion"          { type = String }

        --- The node target
        property "Target"               { type = Any }

        --- The AddressSpace
        property "AddressSpace"         { type = AddressSpace }

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Final__() __Arguments__{ AddressSpace, Any, NodeInfo/nil }
        function __ctor(self, addressSpace, target, init)
            local cls                   = getmetatable(self)
            local base                  = __Node__.GetNodeInfo(target)

            --- Register the nodes to the AddressSpace
            self.AddressSpace           = addressSpace
            self.Target                 = target

            if type(init) == "table" and getmetatable(init) == nil then
                if not base then
                    base                = init
                else
                    for k, v in pairs(init) do
                        base[k]         = v
                    end
                end
            end

            if not (base and base.NodeId) then throw("The NodeId of the Node must be specified") end

            -- Generate NodeInfo based on the target
            if Namespace.Validate(target) then
                base.BrowseName         = base.BrowseName  or QualifiedName(base.NodeId.namespaceIndex, Namespace.GetNamespaceName(target, true))
                base.DisplayName        = base.DisplayName or LocalizedText(LocaleIdEnum.en, base.BrowseName.name)

                if Enum.Validate(target) then
                    -- Use UInt32 for OptionSet, Enum for Enumeration
                    base.SubtypeOf      = base.SubtypeOf or Enum.IsFlagsEnum(target) and UInt32 or Enum
                elseif Struct.Validate(target) then
                    local stype         = Struct.GetStructCategory(target)

                    if stype == StructCategory.CUSTOM then
                        if target ~= Any then   -- Any is used to represent the BaseDataType
                            -- Use Union as the base type of the combo types like `Int32 + Double`
                            base.SubtypeOf = base.SubtypeOf or Struct.GetBaseStruct(target) or Struct.GetComboTypes(target) and Union or Struct
                        end
                    elseif stype == StructCategory.MEMBER then
                        -- Array also consider as scalar value in OPC
                        base.SubtypeOf  = base.SubtypeOf or Struct
                    elseif stype == StructCategory.ARRAY or stype == StructCategory.DICTIONARY then
                        throw("The dictionary struct type is unsupported")
                    end

                    -- @todo: Inherit the super type's attribute
                elseif Class.Validate(target) then
                    if not base.SubtypeOf then
                        local superCls  = Class.GetSuperClass(target)
                        if __Node__.HasNodeInfo(superCls) then
                            base.SubtypeOf = superCls
                        end
                    end

                    -- @todo: Inherit the super type's attribute
                end
            end

            -- Convert the HasModellingRule
            if base.HasModellingRule then
                -- @todo
                base.HasModellingRule   = self.AddressSpace.ModellingRules[base.HasModellingRule]
            end

            -- Load init table as default
            if base then
                local refs, hasProperty

                for k, v in pairs(base) do
                    if not nodeAttrs[k] then
                        --- Check if it's for node property
                        local prop      = getFeature(getmetatable(obj), k, true)
                        if prop and isProperty(prop) and __Node__.HasNodeInfo(prop) then
                            -- could be used to generate the HasProperty if NodeId existed


                        end

                        refs            = refs or {}
                        refs[k]         = v
                        base[k]         = nil
                    end
                end

                local ok, err           = pcall(loadinittable, self, base)
                if not ok then throw(err) end

                if refs then
                    ok, err             = pcall(loadinittable, self, refs)
                    if not ok then throw(err) end
                end
            end

            --- Register the nodes to the AddressSpace
            addressSpace:RegisterNode(self)

            local ctor                  = getNormalCtor(cls)
            if ctor then ctor(self) end
        end

        __Final__() __Arguments__{ NodeInfo }
        function __ctor(self, init)
            this(self, self, init)
        end

        __Final__() __Arguments__{ Any, NodeInfo/nil }
        function __ctor(self, target, init)
            local cls                   = getmetatable(self)
            local addressSpace          = Environment.GetKeywordVisitor(cls)
            if not addressSpace then
                -- Try get the addressSpace from references
                if init then
                    for k, v in pairs(init) do
                        if not nodeAttrs[k] then
                            if __Node__.GetReferenceType(k) then
                                if Class.IsObjectType(v, AddressSpace) then
                                    addressSpace = v
                                    break
                                elseif Class.IsObjectType(v, Node) then
                                    addressSpace = v.AddressSpace
                                    break
                                end
                            end
                        end
                    end
                end

                if not addressSpace then throw("The Node can only be created in AddressSpace") end
            end

            this(self, addressSpace, target, init)
        end

        __Final__() __Arguments__{ AddressSpace, Any, NodeInfo/nil }
        function __exist(cls, addressSpace, target, init)
            return addressSpace:GetNode(target)
        end

        __Final__() __Arguments__{ NodeInfo }
        function __exist(cls, info) end

        __Final__() __Arguments__{ Any, NodeInfo/nil }
        function __exist(cls, target, info)
            local accessor              = Environment.BackupKeywordAccess()
            if accessor and accessor.key == cls then
                return accessor.visitor:GetNode(target)
            end
        end

        function __dtor(self)
            -- Well, make sure no node version udapted
            self.UpdateNodeVersion      = fakefunc
            self.AddressSpace:RemoveNode(self)
        end

        -----------------------------------------------------------
        --                      meta-method                      --
        -----------------------------------------------------------
        --- The access to References
        function __index(self, key)
            -- Return the reference targets by XList
            local reference             = self.AddressSpace.References[key]
            if reference then return XList(reference:GetTargets(self)) end
        end

        function __newindex(self, key, value)
            --- Bind new references
            local reference             = self.AddressSpace.References[key]

            if reference then
                -- Check if the value is an array
                if type(value) == "table" and getmetatable(value) == nil and #value > 0 then
                    for i = 1, #value do
                        local ok, err   = pcall(reference.AddReference, reference, self, value[i])
                        if not ok then error(err, 2) end
                    end
                else
                    local ok, err       = pcall(reference.AddReference, reference, self, value)
                    if not ok then error(err, 2) end
                end
            else
                rawset(self, key, value)
            end
        end
    end)

    --- The ReferenceType NodeClass, its object will be used to generate the References
    __Sealed__()
    class "ReferenceType"               (function(_ENV)
        inherit "Node"

        -----------------------------------------------------------
        --                       attribute                       --
        -----------------------------------------------------------
        --- The NodeClass of node
        __Abstract__()
        property "NodeClass"            { type = NodeClass, require = true, default = NodeClass.ReferenceType }

        --- Whether the ReferenceType is abstract
        __Abstract__()
        property "IsAbstract"           { type = Boolean,   require = true, default = true }

        --- Whether the meaning of the ReferenceType is the same as seen from both the SourceNode and the TargetNode
        __Abstract__()
        property "Symmetric"            { type = Boolean,   require = true, default = true }

        --- The meaning of the ReferenceType as seen from the TargetNode
        __Abstract__()
        property "InverseName"          { type = LocalizedText }
    end)

    --- The view node represents a subset of the Nodes in the AddressSpace, it use the
    -- AddressSpace as the target
    __Sealed__()
    class "View"                        (function(_ENV)
        inherit "Node"

        -----------------------------------------------------------
        --                       attribute                       --
        -----------------------------------------------------------
        --- The NodeClass of node
        __Abstract__()
        property "NodeClass"            { type = NodeClass, require = true, default = NodeClass.View }

        --- Whether the References in the context of the View has no loops
        __Abstract__()
        property "ContainsNoLoops"      { type = Boolean, require = true, default = false }

        --- indicate if the Node can be used to subscribe to Events or to read / write historic Events
        __Abstract__()
        property "EventNotifier"        { type = EventNotifierType, require = true, default = 0 }

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- the view version
        __Node__{ NodeId = 12170 }
        property "ViewVersion"          { type = NaturalNumber, default = 1 }
    end)

    --- Methods define callable functions
    __Sealed__()
    class "Method"                      (function(_ENV)
        inherit "Node"

        -----------------------------------------------------------
        --                       attribute                       --
        -----------------------------------------------------------
        --- The NodeClass of node
        __Abstract__()
        property "NodeClass"            { type = NodeClass, require = true, default = NodeClass.Method }

        --- if the Method is currently executable
        __Abstract__()
        property "Executable"           { type = Boolean, require = true, default = true }

        ---  if the Method is currently executable taking user access rights into account
        __Abstract__()
        property "UserExecutable"       { type = Boolean, require = true, default = true }

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- The owner of the method
        property "Owner"                { type = Any }

        --- specify the arguments that shall be used by a client when calling the Method
        __Node__ { NodeId = 3072 }
        property "InputArguments"       { type = Arguments }

        --- specifies the result returned from the Method call
        __Node__ { NodeId = 3073 }
        property "OutputArguments"      { type = Arguments }
    end)

    --- Objects are used to represent systems, system components, real-world objects and software objects
    __Sealed__()
    class "Object"                      (function(_ENV)
        inherit "Node"

        export { __Node__, BaseObjectType, getmetatable = getmetatable }

        -----------------------------------------------------------
        --                       attribute                       --
        -----------------------------------------------------------
        --- The NodeClass of node
        __Abstract__()
        property "NodeClass"            { type = NodeClass, require = true, default = NodeClass.Object }

        --- indicate if the Node can be used to subscribe to Events or to read / write historic Events
        __Abstract__()
        property "EventNotifier"        { type = EventNotifierType, require = true, default = 0 }

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- an image that can be used by Clients when displaying the Node
        __Node__{ NodeId = 3067 }
        property "Icon"                 { type = Image }

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        function __ctor(self)
            -- References
            local cls                   = getmetatable(self.Target)

            --- Use BaseObjectType if the object class can't be used
            if not __Node__.HasNodeInfo(cls) then
                cls                     = BaseObjectType
            end

            self.HasTypeDefinition      = cls
        end
    end)

    --- ObjectTypes provide definitions for Objects
    __Sealed__()
    class "ObjectType"                  (function(_ENV)
        inherit "Node"

        export                          { Class, Struct, StructCategory, Property, Variable, PropertyType, Method, BaseObjectType, __Node__ }

        -----------------------------------------------------------
        --                       attribute                       --
        -----------------------------------------------------------
        --- The NodeClass of node
        __Abstract__()
        property "NodeClass"            { type = NodeClass, require = true, default = NodeClass.ObjectType }

        --- Whether the ReferenceType is abstract
        __Abstract__()
        property "IsAbstract"           { type = Boolean,   require = true, default = function(self) return Class.IsAbstract(self.Target) or false end }

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- an image that can be used by Clients when displaying the Node
        __Node__{ NodeId = 3067 }
        property "Icon"                 { type = Image }

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        function __ctor(self)
            -- @todo: later
            --[[ Generate the HasProperty, HasComponent References
            for name, prop in Class.GetFeatures(self.Target) do
                base.NodeId     = base.NodeId      or NodeId(node.NodeId.NamespaceIndex, node.NodeId.identifier .. "[" .. target:GetName() .. "]")
                base.BrowseName = base.BrowseName  or QualifiedName(base.NodeId.namespaceIndex, target:GetNode())
                base.DisplayName= base.DisplayName or LocalizedText(LocaleIdEnum.en, base.BrowseName.name)


                if Property.Validate(prop) and __Node__.HasNodeInfo(prop) then
                    local ptype = prop:GetType()
                    local rank  = 0

                    while ptype and Struct.Validate(ptype) and Struct.GetStructCategory(ptype) == StructCategory.ARRAY do
                        rank    = rank + 1
                        ptype   = Struct.GetArrayElement(ptype)
                    end

                    local refType

                    if ptype and (self.AddressSpace:GetNode(ptype) or __Node__.HasNodeInfo(ptype)) then
                        -- Check which reference should be used
                        if Struct.Validate(ptype) then

                        elseif Class.Validate(ptype) then
                            refType = "HasComponent"
                        end
                    end
                end
            end--]]
        end
    end)

    --- Variables are used to represent values which may be simple or complex
    __Sealed__()
    class "Variable"                    (function(_ENV)
        inherit "Node"

        -----------------------------------------------------------
        --                       attribute                       --
        -----------------------------------------------------------
        --- The NodeClass of node
        __Abstract__()
        property "NodeClass"            { type = NodeClass, require = true, default = NodeClass.Variable }

        --- The most recent value of the Variable that the Server has
        __Abstract__() __Observable__()
        property "Value"                {}

        --- NodeId of the DataType definition for the Value Attribute
        __Abstract__()
        property "DataType"             { type = NodeDataType, require = true, handler = function(self) self:UpdateNodeVersion() end }

        --- indicates whether the Value Attribute of the Variable is an array and how many dimensions the array has
        -- -3 : ScalarOrOneDimension    - The value can be a scalar or a one dimensional array
        -- -2 : Any                     - The value can be a scalar or an array with any number of dimensions
        -- -1 : Scalar                  - The value is not an array
        --  0 : OneOrMoreDimensions     - The value is an array with one or more dimensions
        --  1 : OneDimension            - The value is an array with one dimension
        -- >1 :                         - the Value is an array with the specified number of dimensions
        __Abstract__()
        property "ValueRank"            { type = Int32, require = true, default = -1 }

        --- the maximum supported length of each dimension
        __Abstract__()
        property "ArrayDimensions"      { type = struct { UInt32 } }

        --- indicate how the Value of a Variable can be accessed
        __Abstract__()
        property "AccessLevel"          { type = AccessLevelType, require = true, default = AccessLevelType.CurrentRead + AccessLevelType.CurrentWrite }

        ---  indicate how the Value of a Variable can be accessed (read/write) and if it contains current or historic data taking user access rights into account
        __Abstract__()
        property "UserAccessLevel"      { type = AccessLevelType, require = true, default = AccessLevelType.CurrentRead + AccessLevelType.CurrentWrite }

        --- indicates how “current” the Value of the Variable will be kept. It specifies (in milliseconds) how fast the Server can reasonably sample the value for changes
        -- A MinimumSamplingInterval of 0 indicates that the Server is to monitor the item continuously. A MinimumSamplingInterval of -1 means indeterminate.
        __Abstract__()
        property "MinimumSamplingInterval" { type = Duration, default = -1 }

        --- whether the Server is actively collecting data for the history of the Variable
        __Abstract__()
        property "Historizing"          { type = Boolean, require = true, default = false }

        --- indicate how the Value of a Variable can be accessed (read/write), if it contains current and/or historic data and its atomicity
        __Abstract__()
        property "AccessLevelEx"        { type = AccessLevelExType }

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- a structure containing the Offset and the DaylightSavingInOffset flag. The Offset specifies the time difference (in minutes) between the SourceTimestamp (UTC)
        -- associated with the value and the time at the location in which the value was obtained
        __Node__{ NodeId = 3069 }
        property "LocalTime"            { type = TimeZoneDataType }

        --- specifies if a null value is allowed for the Value Attribute of the DataVariable
        __Node__{ NodeId = 3070 }
        property "AllowNulls"           { type = Boolean }

        --- It is used for DataVariables with a finite set of LocalizedTexts associated with its value
        __Node__{ NodeId = 11433 }
        property "ValueAsText"          { type = LocalizedText }

        --- The maximum number of bytes supported by the DataVariable
        __Node__{ NodeId = 11498 }
        property "MaxStringLength"      { type = UInt32 }

        --- The maximum number of Unicode characters supported by the DataVariable
        __Node__{ NodeId = 15002 }
        property "MaxCharacters"        { type = UInt32 }

        --- the maximum number of bytes supported by the DataVariable
        __Node__{ NodeId = 12908 }
        property "MaxByteStringLength"  { type = UInt32 }

        --- the maximum length of an array supported by the DataVariable
        __Node__{ NodeId = 11512 }
        property "MaxArrayLength"       { type = UInt32 }

        --- the engineering units for the value of the DataVariable
        __Node__{ NodeId = 11513 }
        property "EngineeringUnits"     { type = EUInformation }
    end)

    --- VariableTypes are used to provide type definitions for Variables
    __Sealed__()
    class "VariableType"                (function(_ENV)
        inherit "Node"

        export { Class }

        -----------------------------------------------------------
        --                       attribute                       --
        -----------------------------------------------------------
        --- The NodeClass of node
        __Abstract__()
        property "NodeClass"            { type = NodeClass, require = true, default = NodeClass.VariableType }

        --- The default Value for instances of this type
        __Abstract__()
        property "Value"                {}

        --- NodeId of the data type definition for instances of this type
        __Abstract__()
        property "DataType"             { type = NodeDataType, require = true }

        --- indicates whether the Value Attribute of the Variable is an array and how many dimensions the array has
        -- -3 : ScalarOrOneDimension    - The value can be a scalar or a one dimensional array
        -- -2 : Any                     - The value can be a scalar or an array with any number of dimensions
        -- -1 : Scalar                  - The value is not an array
        --  0 : OneOrMoreDimensions     - The value is an array with one or more dimensions
        --  1 : OneDimension            - The value is an array with one dimension
        -- >1 :                         - the Value is an array with the specified number of dimensions
        __Abstract__()
        property "ValueRank"            { type = Int32, require = true, default = -1 }

        --- the maximum supported length of each dimension
        __Abstract__()
        property "ArrayDimensions"      { type = struct { UInt32 } }

        --- Whether this is an abstract VariableType
        __Abstract__()
        property "IsAbstract"           { type = Boolean, require = true, default = function(self) return Class.IsAbstract(self.Target) or false end }
    end)

    --- the syntax of a Variable Value
    __Sealed__()
    class "DataType"                    (function(_ENV)
        inherit "Node"

        export                          { XDictionary, XList, List, Enum, Struct, LocaleIdEnum, StructCategory, Union, StructureType, Namespace, NodeDataType, NodeId }

        -----------------------------------------------------------
        --                       attribute                       --
        -----------------------------------------------------------
        --- The NodeClass of node
        __Abstract__()
        property "NodeClass"            { type = NodeClass, require = true, default = NodeClass.DataType }

        --- if it is an abstract DataType
        __Abstract__()
        property "IsAbstract"           { type = Boolean, require = true, default = false }

        --- the meta data and encoding information for custom DataTypes
        __Abstract__()
        property "DataTypeDefinition"   { type = DataTypeDefinition }

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- Each entry of the array of LocalizedText in this Property represents the human-readable representation of an enumerated value
        __Node__{ NodeId = 11432 }
        property "EnumStrings"          { type = LocalizedTexts, require = true }

        --- Each entry of the array of EnumValueType in this Property represents one enumeration value with its integer notation
        __Node__{ NodeId = 3071 }
        property "EnumValues"           { type = EnumValueTypes, require = true }

        --- an array of LocalizedText containing the human-readable representation for each bit
        __Node__{ NodeId = 12745 }
        property "OptionSetValues"      { type = LocalizedTexts, require = true }

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        -- AutoGen the type definitions
        function __ctor(self)
            local target                = self.Target

            if Enum.Validate(target) then
                local dict              = XDictionary(Enum.GetEnumValues(target)):ToDict()
                local fields            = dict.Keys:ToList():Sort(function(a, b) return dict[a] < dict[b] end)

                -- No zero allowed for OptionSet DataTypes
                if Enum.IsFlagsEnum(target) and target[fields[1]] == 0 then fields:RemoveByIndex(1) end

                self.DataTypeDefinition = fields:Map(function(fld) return { name = fld } end):ToTable()

                if not Enum.IsFlagsEnum(target) and not self.EnumStrings then
                    self.EnumValues     = fields:Map(function(fld) return { value = target[fld], displayName = LocalizedText(LocaleIdEnum.en, fld) } end):ToTable()
                end

            elseif Struct.Validate(target) then
                if self.DataTypeDefinition then return end

                local stype             = Struct.GetStructCategory(target)

                if stype == StructCategory.CUSTOM then
                    -- Use Union as the base type of the combo types like `Int32 + Double`
                    if target ~= Union and Struct.GetComboTypes(target) then
                        self.DataTypeDefinition = {
                            baseDataType        = Union,
                            structureType       = StructureType.Union,
                            fields              = List{ Struct.GetComboTypes(target) }:Map(function(ftype)
                                                    local rank      = 0

                                                    while Struct.Validate(ftype) and Struct.GetStructCategory(ftype) == StructCategory.ARRAY do
                                                        rank        = rank + 1
                                                        ftype       = Struct.GetArrayElement(ftype)
                                                    end

                                                    return {
                                                        name        = Namespace.GetNamespaceName(ftype, true),
                                                        dataType    = ftype == NodeDataType and NodeId or ftype,
                                                        valueRank   = rank == 0 and -1 or rank,

                                                        -- PLoop doesn't have limit, so just keep zero for now
                                                        arrayDimensions = rank > 0 and List(rank, 0):ToTable() or nil,
                                                        maxStringLength = 0,
                                                    }
                                                end):ToTable()
                        }
                    end

                elseif stype == StructCategory.MEMBER then
                    -- Array also consider as scalar value in OPC
                    local hasOptional           = false
                    local fields                = XList(Struct.GetMembers(target)):Map(function(member)
                                                    if not member:IsRequire() then hasOptional = true end

                                                    local mtype     = member:GetType()
                                                    local rank      = 0

                                                    while Struct.Validate(mtype) and Struct.GetStructCategory(mtype) == StructCategory.ARRAY do
                                                        rank        = rank + 1
                                                        mtype       = Struct.GetArrayElement(mtype)
                                                    end

                                                    return {
                                                        name        = member:GetName(),
                                                        dataType    = mtype == NodeDataType and NodeId or mtype,
                                                        valueRank   = rank == 0 and -1 or rank,
                                                        isOptional  = not member:IsRequire(),

                                                        -- PLoop doesn't have limit, so just keep zero for now
                                                        arrayDimensions = rank > 0 and List(rank, 0):ToTable() or nil,
                                                        maxStringLength = 0,
                                                    }
                                                end):ToTable()


                    self.DataTypeDefinition     = {
                        defaultEncodingId       = nil,  -- @todo: encoding
                        baseDataType            = Struct,
                        structureType           = hasOptional and StructureType.StructureWithOptionalFields or StructureType.Structure,
                        fields                  = fields,
                    }


                elseif stype == StructCategory.ARRAY or stype == StructCategory.DICTIONARY then
                    throw("The target is not a valid data type")
                end
            else
                throw("The target is not a valid data type")
            end
        end
    end)
end)