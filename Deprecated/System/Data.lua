--========================================================--
--                System.Data                             --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2014/10/13                              --
--========================================================--

--========================================================--
_ENV = Module     "System.Data"                      "1.0.0"
--========================================================--

import "System"

namespace "System.Data"

__Doc__[[The interface of data providers]]
interface "IFDataProvider"
    ------------------------------------------------------
    -- Method
    ------------------------------------------------------
    function Save(self, obj) end
    function Load(self, obj) end
endinterface "IFDataProvider"

__Doc__[[The interface of the data table.]]
interface "IFDataTable" (function(_ENV)

    _IFDataTableInfo = setmetatable({}, {__mode="k"})

    ------------------------------------------------------
    -- Method
    ------------------------------------------------------
    function Save(self, provider)
        provider = provider or _IFDataTableInfo[getmetatable(self)]
        return provider and provider:Save(self)
    end

    function Load(self, provider)
        provider = provider or _IFDataTableInfo[getmetatable(self)]
        return provider and provider:Load(self)
    end

    ------------------------------------------------------
    -- Initialize
    ------------------------------------------------------
    function IFDataTable(self)
        local cls = getmetatable(self)

        if _IFDataTableInfo[cls] == nil then
            for _, attr in ipairs{  IAttribute:GetClassAttribute(cls) } do
                if Reflector.ObjectIsInterface(attr, IFDataProvider) then
                    _IFDataTableInfo[cls] = attr
                    break
                end
            end
            _IFDataTableInfo[cls] = _IFDataTableInfo[cls] or false
        end

        return self:Load()
    end
end)

__AttributeUsage__{ AttributeTarget = AttributeTargets.Class + AttributeTargets.Struct }
class "__DataTable__" (function(_ENV)
    extend "IAttribute"
    extend "IFDataProvider"

    local function CheckExisted(tbl, value)
        for _, v in ipairs(tbl) do if v == value then return true end end
    end

    _INDEX_FORMAT = "[%s]%s"

    local function GenerateKey(value, part)
        local v = value[part]
        if type(v) == "number" or (type(v) == "string" and strtrim(v) ~= "") then
            return _INDEX_FORMAT:format(part, tostring(v))
        end
    end

    local function GetKey(keys, value)
        if not keys then return end
        local cnt = #keys
        if cnt == 1 then
            return GenerateKey(value, keys[1])
        elseif cnt == 2 then
            local v1 = GenerateKey(value, keys[1])
            local v2 = GenerateKey(value, keys[2])
            return v1 and v2 and v1 .. "|" .. v2
        else
            local key = {}
            for _, prop in ipairs(keys) do
                local v = GenerateKey(value, prop)
                if not v then return end
                tinsert(key, v)
            end
            return tblconcat(key, "|")
        end
    end

    local function GetData(self, value, create)
        local key = GetKey(self.MainKeys, value)
        local key2 = GetKey(self.IndexKeys, value)

        local dt = key and self.Source[key] or key2 and self.Index[key2]

        -- Scan for data
        if not dt and key2 then
            for k, v in pairs(self.Source) do
                local isEqual = true
                for _, index in ipairs(self.IndexKeys) do
                    if v[index] ~= value[index] then isEqual = false break end
                end
                if isEqual then
                    dt = v
                    self.Index[key2] = dt
                    break
                end
            end
        end

        if not dt and create then
            dt = {}
            if key then self.Source[key] = dt end
            if key2 then self.Index[key2] = dt end
        end

        return dt
    end

    -------------------------------------------
    -- Property
    -------------------------------------------
    __Doc__[[The data table's name]]
    property "Name" { Type = String }

    __Doc__[[The database]]
    property "Source" { Type = Table }

    __Doc__[[Whether all properties will be used as data field]]
    property "IncludeAll" { Type = Boolean, Default = true }

    __Doc__[[The main keys of the data table]]
    property "MainKeys" { Type = Table }

    __Doc__[[The index keys of the data table]]
    property "IndexKeys" { Type = Table }

    -------------------------------------------
    -- Method
    -------------------------------------------
    function ApplyAttribute(self, target, targetType, owner, name)
        if not self.Name then self.Name = Reflector.GetNameSpaceName(target) end
        if not self.Source then
            self.Source = {}
        else
            self.Source[self.Name] = self.Source[self.Name] or {}
            self.Source = self.Source[self.Name]
        end
        self.Owner = target
        self.Index = {}

        -- Scan fields
        self.FieldMap = {}
        self.FieldDefault = {}
        self.MainKeys = self.MainKeys or {}

        if targetType == AttributeTargets.Class then
            -- Scan fields
            for prop in Reflector.GetAllProperties(target) do
                local ty = Reflector.GetPropertyType(target, prop)
                if ty and #ty == 1 and Reflector.GetStructType(ty[1]) == "CUSTOM" and Reflector.IsPropertyReadable(target, prop) and Reflector.IsPropertyWritable(target, prop) then
                    local field = __DataField__:GetPropertyAttribute(target, prop)
                    if field or self.IncludeAll then
                        self.FieldMap[prop] = field and field.Name or prop
                        self.FieldDefault[prop] = Reflector.GetDefaultValue(target, prop)
                    end
                    if field then
                        if field.IsMainKey then
                            if not CheckExisted(self.MainKeys, prop) then tinsert(self.MainKeys, prop) end
                        elseif field.IsIndexKey then
                            self.IndexKeys = self.IndexKeys or {}
                            if not CheckExisted(self.MainKeys, prop) and not CheckExisted(self.IndexKeys, prop) then tinsert(self.IndexKeys, prop) end
                        end
                    end
                end
            end

            -- Validate main keys
            for i = #self.MainKeys, 1, -1 do
                if not self.FieldMap[self.MainKeys[i]] then
                    tremove(self.MainKeys, i)
                end
            end
            if self.IndexKeys then
                for i = #self.IndexKeys, 1, -1 do
                    if not self.FieldMap[self.IndexKeys[i]] then
                        tremove(self.IndexKeys, i)
                    end
                end
            end

            if #self.MainKeys == 0 then
                if self.IndexKeys and #self.IndexKeys > 0 then
                    self.MainKeys = self.IndexKeys
                else
                    for _, prop in ipairs(props) do
                        if self.FieldMap[prop] then
                            local ty = Reflector.GetPropertyType(target, prop)
                            if ty and not ty.AllowNil then
                                tinsert(self.MainKeys, prop)
                            end
                        end
                    end
                end
            end

            -- Re-define
            class (target) { IFDataTable, _FetchData = function (query) return self:FetchData(query) end }
        elseif Reflector.GetStructType(target) == "MEMBER" then
            local members = Reflector.GetStructMembers(target)

            for _, member in ipairs(members) do
                local ty = Reflector.GetStructMember(target, member)
                if ty and #ty == 1 and Reflector.GetStructType(ty[1]) == "CUSTOM" then
                    local field = __DataField__:GetMemberAttribute(target, member)
                    if field or self.IncludeAll then
                        self.FieldMap[member] = field and field.Name or member
                        self.FieldDefault[member] = Reflector.GetDefaultValue(target, member)
                    end
                    if field then
                        if field.IsMainKey then
                            if not CheckExisted(self.MainKeys, member) then tinsert(self.MainKeys, member) end
                        elseif field.IsIndexKey then
                            self.IndexKeys = self.IndexKeys or {}
                            if not CheckExisted(self.MainKeys, member) and not CheckExisted(self.IndexKeys, member) then tinsert(self.IndexKeys, member) end
                        end
                    end
                end
            end

            -- Validate main keys
            for i = #self.MainKeys, 1, -1 do
                if not self.FieldMap[self.MainKeys[i]] then
                    tremove(self.MainKeys, i)
                end
            end
            if self.IndexKeys then
                for i = #self.IndexKeys, 1, -1 do
                    if not self.FieldMap[self.IndexKeys[i]] then
                        tremove(self.IndexKeys, i)
                    end
                end
            end

            if #self.MainKeys == 0 then
                if self.IndexKeys and #self.IndexKeys > 0 then
                    self.MainKeys = self.IndexKeys
                else
                    for _, member in ipairs(members) do
                        if self.FieldMap[member] then
                            local ty = Reflector.GetStructMember(target, member)
                            if ty and not ty.AllowNil then
                                tinsert(self.MainKeys, member)
                            end
                        end
                    end
                end
            end

            -- Re-define
            target.Load = function (obj) return self:Load(obj) end
            target.Save = function (obj) return self:Save(obj) end
            target._FetchData = function (query) return self:FetchData(query) end
            target[Reflector.GetNameSpaceName(target)] = target.Load
        end
    end

    function Save(self, obj)
        if self then
            local dt = GetData(self, obj, true)
            if dt then
                for prop, field in pairs(self.FieldMap) do
                    local value = obj[prop]
                    if value ~= self.FieldDefault[prop] then
                        dt[field] = value
                    else
                        dt[field] = nil
                    end
                end
            end
        end
    end

    function Load(self, obj)
        if self then
            local dt = GetData(self, obj)

            if dt then
                for prop, field in pairs(self.FieldMap) do
                    local value = dt[field]
                    if value == nil then value = self.FieldDefault[prop] end
                    obj[prop] = value
                end
            end
        end
    end

    function FetchData(self, query)
        local scanAll = true

        if type(query) == "table" and next(query) then
            for k in pairs(query) do
                if self.FieldMap[k] then scanAll = false break end
            end
        end

        local ret = {}
        for _, data in pairs(self.Source) do
            local match = true
            if not scanAll then
                for k, v in pairs(query) do
                    if data[k] ~= v then
                        match = false break
                    end
                end
            end

            if match then
                local new = {}
                for _, k in ipairs(self.MainKeys) do new[k] = data[k] end
                tinsert(ret, self.Owner(new))
            end
        end
        return ret
    end

    -------------------------------------------
    -- Constructor
    -------------------------------------------
    __Arguments__{ String }
    function __DataTable__(self, name)
        Super(self)
        self.Name = name
    end

    function __call(self, value)
        if type(value) == "table" then
            if self.MainKeys then
                self.IndexKeys = value
            else
                self.MainKeys = value
            end
        elseif type(value) == "string" then
            if not self.MainKeys or #self.MainKeys == 0 then
                self.MainKeys = value
            elseif not self.IndexKeys or #self.IndexKeys == 0 then
                self.IndexKeys = value
            end
        end
        return self
    end
end)

__AttributeUsage__{ AttributeTarget = AttributeTargets.Property + AttributeTargets.Member }
class "__DataField__" (function(_ENV)
    extend "IAttribute"

    -------------------------------------------
    -- Property
    -------------------------------------------
    __Doc__[[The data field]]
    property "Name" { Type = String }

    __Doc__[[Whether the field is the main key]]
    property "IsMainKey" { Type = Boolean }

    __Doc__[[Whether the field is the index key]]
    property "IsIndexKey" { Type = Boolean }

    -------------------------------------------
    -- Method
    -------------------------------------------
    function ApplyAttribute(self, target, targetType, owner, name)
        if not self.Name then self.Name = name end
    end

    -------------------------------------------
    -- Constructor
    -------------------------------------------
    __Arguments__{ String }
    function __DataField__(self, name)
        Super(self)
        self.Name = name
    end
end)
