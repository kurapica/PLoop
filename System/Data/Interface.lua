--===========================================================================--
--                                                                           --
--                                System.Data                                --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2018/06/02                                               --
-- Update Date  :   2018/06/02                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    __Sealed__() __Final__()
    interface "System.Data" (function(_ENV)
        export { safeset        = Toolset.safeset }

        local NULL_VALUE        = {}

        --- Add Empty value for ParseString
        __Arguments__{ Any }
        __Static__() function AddNullValue(value)
            NULL_VALUE          = safeset(NULL_VALUE, value, true)
        end

        --- Parse the value so special null value can be changed to nil
        __Static__() function ParseValue(val)
            if val == nil or NULL_VALUE[val] then return nil end
            return val
        end
    end)

    namespace (Data)

    export {
        tinsert             = table.insert,
        safeset             = Toolset.safeset,
        pairs               = pairs,
        ipairs              = ipairs,
        type                = type,

        Attribute, Namespace, Class, Property
    }

    -----------------------------------------------------------
    --                        helper                         --
    -----------------------------------------------------------
    local _DataTableSchema  = {}
    local _DataTableFldCnt  = {}

    function isUniqueIndex(entityCls, fields)
        local schema        = _DataTableSchema[entityCls]
        if schema.indexes then
            if type(fields) == "table" then
                local count = 0
                for k in pairs(fields) do count = count + 1 end

                for _, index in ipairs(schema.indexes) do
                    if index.unique and #index.fields == count then
                        local match = true
                        for i, fld in ipairs(index.fields) do
                            if not fields[fld] then match = false break end
                        end
                        if match then return true end
                    end
                end
            else
                for _, index in ipairs(schema.indexes) do
                    if index.unique and #index.fields == 1 and index.fields[1] == fields then
                        return true
                    end
                end
            end
        end

        return false
    end

    function saveDataTableSchema(entityCls, set)
        local schema        = {
            name            = set.name,
            collection      = set.collection,
            indexes         = set.indexes,
            map             = {},
            primary         = nil,
            autokey         = nil,
            unique          = {},
            foreign         = {},
            converter       = {},
        }

        if schema.indexes then
            for _, index in ipairs(schema.indexes) do
                if index.primary then
                    schema.primary = index.fields
                    if #schema.primary == 1 then
                        schema.primary = schema.primary[1]
                    end
                end
            end
        end

        _DataTableSchema    = safeset(_DataTableSchema, entityCls, schema)
    end

    function saveDataFieldSchema(entityCls, name, set)
        local schema        = _DataTableSchema[entityCls]

        if set.foreign then
            schema.foreign[name]    = set.foreign.map
            local keycount  = 0
            local key
            for k, v in pairs(set.foreign.map) do
                schema.map[k]       = schema.map[k] or name
                keycount            = keycount + 1
                key                 = k
            end
            if keycount == 1 and set.unique then
                schema.unique[key]  = true
            end
        else
            schema.map[set.name]    = name

            if set.autoincr and schema.primary == set.name then
                schema.autokey      = true
            end

            if set.unique then
                schema.unique[set.name] = true
            end

            if set.converter then
                schema.converter[set.name] = {
                    set.converter,
                    set.format or set.converter.format,
                }
            end
        end
    end

    function getDataTableSchema(entityCls)
        return _DataTableSchema[entityCls]
    end

    function getDataTableCollection(entityCls)
        return _DataTableSchema[entityCls].collection
    end

    function getDataFieldProperty(entityCls, field)
        return _DataTableSchema[entityCls].map[field]
    end

    function getDataTableFieldCount(entityCls)
        local count      = _DataTableFldCnt[entityCls] or 1
        _DataTableFldCnt = safeset(_DataTableFldCnt, entityCls, count + 1)
        return count
    end

    function clearDataTableFieldCount(entityCls)
        _DataTableFldCnt = safeset(_DataTableFldCnt, entityCls, nil)
    end

    -----------------------------------------------------------
    --                         types                         --
    -----------------------------------------------------------
    --- The DBNull
    __Sealed__() struct "DBNull" { function(val) return val ~= DBNull end }
    Data.AddNullValue(DBNull)

    --- The current state of the dbconnection
    __Sealed__() enum "ConnectionState" {
        Closed                  = 0,
        Open                    = 1,
        Connecting              = 2,
        Executing               = 3,
        Fetching                = 4,
    }

    __Sealed__() enum "TransactionIsolation" {
        REPEATABLE_READ         = 0,
        READ_UNCOMMITTED        = 1,
        READ_COMMITTED          = 2,
        SERIALIZABLE            = 3,
    }

    __Sealed__() enum "EntityStatus" {
        NEW                     = 0,
        UNMODIFIED              = 1,
        MODIFIED                = 2,
        DELETED                 = 3,
    }

    __Sealed__() struct "QueryOrder" {
        { name = "name",   type = String, require = true },
        { name = "desc",   type = Boolean },
    }

    __Sealed__() struct "QueryOrders" {
        String + QueryOrder,

        __init                  = function(self)
            for i, order in ipairs(self) do
                if type(order) == "string" then
                    self[i]     = { name = order }
                end
            end
        end,
    }

    class "DataCollection" {}

    __Sealed__() interface "ISqlBuilder" (function(_ENV)
        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- Sets the select fields
        -- @param fields    a list of the field or the string that contains the fields
        -- @return self
        __Abstract__() function Select(self, fields) return self end

        --- Lock the query rows
        -- @return self
        __Abstract__() function Lock(self) return self end

        --- Sets the updating field-value map
        -- @param map       a map for field to value
        -- @return self
        __Abstract__() function Update(self, map) return self end

        --- Sets to delete data
        -- @return self
        __Abstract__() function Delete(self) return self end

        --- Insert the data
        -- @return self
        __Abstract__() function Insert(self, map) return self end

        --- Set the data table name
        -- @param name      the data table name
        -- @param alias     the alias name
        -- @return self
        __Abstract__() function From(self, name, alias) return self end

        --- Set the conditions
        -- @param condition the query condition
        -- @return self
        __Abstract__() function Where(self, condition) return self end

        --- Set the order by
        -- @param name      the data field name
        -- @param desc      whether use desc order
        -- @return self
        __Abstract__() function OrderBy(self, field, desc) return self end

        --- Generate the final sql
        -- @return sql
        __Abstract__() function ToSql(self) end
    end)

    --- Represents the connection to a data base
    __Sealed__() interface "IDbConnection" (function(_ENV)
        extend "IAutoClose"

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- The connection state
        __Abstract__() property "State"      { type = ConnectionState, default = ConnectionState.Closed }

        --- The query builder class
        __Abstract__() property "SqlBuilder" { type = -ISqlBuilder }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- Get a new database transaction.
        __Abstract__() function NewTransaction(self, isolation) end

        --- Sends the query sql and return the result
        __Abstract__() function Query(self, sql, ...) end

        --- Sends the insert sql to the database and return the auto-increased id
        __Abstract__() function Insert(self, sql, ...) end

        --- Sends the update sql to the database
        __Abstract__() function Update(self, sql, ...) end

        --- Sends the delete sql to the database
        __Abstract__() function Delete(self, sql, ...) end

        --- Execute the insert sql and return the result
        __Abstract__() function Execute(self, sql, ...) end
    end)

    --- Represents a transaction to be performed at a data source
    __Sealed__() interface "IDbTransaction" (function(_ENV)
        extend "IAutoClose"

        export { "getmetatable" }

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- The Connection object to associate with the transaction
        __Abstract__() property "Connection"        { type = IDbConnection }

        --- The transaction isolation level
        __Abstract__() property "Isolation"         { type = TransactionIsolation, default = TransactionIsolation.REPEATABLE_READ }

        --- Whether the transaction is open
        __Final__()    property "IsTransactionOpen" { type = Boolean }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        __Final__() function Open(self)
            self:Begin()
        end

        __Final__() function Close(self, err)
            if err then
                self:Rollback()
            else
                self:Commit()
            end
        end

        --- Begin the transaction
        __Final__() function Begin(self)
            if not self.IsTransactionOpen then
                getmetatable(self).Begin(self)
                self.IsTransactionOpen = true
            end
        end

        --- Commits the database transaction
        __Final__() function Commit(self)
            if self.IsTransactionOpen then
                getmetatable(self).Commit(self)
                self.IsTransactionOpen = false
            end
        end

        --- Rolls back a transaction from a pending state
        __Final__() function Rollback(self)
            if self.IsTransactionOpen then
                getmetatable(self).Rollback(self)
                self.IsTransactionOpen = false
            end
        end
    end)

    --- Represents the context for a group of DataSets
    __Sealed__() interface "IDataContext" (function (_ENV)
        extend "IAutoClose"

        export { List, "pairs", "next", "pcall", "error", "getmetatable", "tonumber", tinsert = table.insert }

        FLD_CHANGED_ENTITY      = 1
        FLD_CURRENT_TRANST      = 2

        field {
            [FLD_CHANGED_ENTITY]= {},           -- the change entities
            [FLD_CURRENT_TRANST]= false,        -- the current transaction
        }

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- The Connection object to associate with the transaction
        property "Connection"       { type = IDbConnection, field = 0 }

        --- Get a new transaction to process the updatings
        property "Transaction"      {
            get = function(self)
                local trans     = self[FLD_CURRENT_TRANST]
                if not (trans and trans.IsTransactionOpen) then
                    trans       = self.Connection:NewTransaction()
                    self[FLD_CURRENT_TRANST] = trans
                end
                return trans
            end
        }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        function Open(self)
            self.Connection:Open()
        end

        function Close(self)
            self.Connection:Close()
        end

        --- Add changed entity
        function AddChangedEntity(self, entity)
            tinsert(self[FLD_CHANGED_ENTITY], entity)
        end

        --- Save the data changes in the context
        function SaveChanges(self, stack)
            if self[FLD_CHANGED_ENTITY][1] == nil then return end
            stack           = (tonumber(stack) or 1) + 1

            for _, entity in ipairs(self[FLD_CHANGED_ENTITY]) do
                entity:SaveChange(stack)
            end

            self[FLD_CHANGED_ENTITY] = {}
        end

        --- Sends the query sql and return the result
        function Query(self, ...)
            local rs = self.Connection:Query(...)
            if rs then
                if getmetatable(rs) == nil then
                    return List(rs)
                else
                    return rs
                end
            else
                return List()
            end
        end

        --- Execute the insert sql and return the result
        function Execute(self, ...)
            return self.Connection:Execute(...)
        end
    end)

    --- Represents the data entity
    __Sealed__() interface "IDataEntity" (function (_ENV)

        export {
            getDataTableSchema  = getDataTableSchema,
            getDataTableCol     = getDataTableCollection,
            getmetatable        = getmetatable,
            pairs               = pairs,
            ipairs              = ipairs,
            parseValue          = Data.ParseValue,
            tonumber            = tonumber,
            type                = type,

            EntityStatus, DBNull
        }

        export {
            STATUS_NEW          = EntityStatus.NEW,
            STATUS_UNMODIFIED   = EntityStatus.UNMODIFIED,
            STATUS_MODIFIED     = EntityStatus.MODIFIED,
            STATUS_DELETED      = EntityStatus.DELETED,
        }

        FIELD_DATA              = 0 -- entity data
        FIELD_FORUPDATE         = 1 -- lock for update
        FIELD_STATUS            = 2 -- entity status
        FIELD_CONTEXT           = 3 -- data context
        FIELD_MODIFIED          = 4 -- modified field
        FIELD_REQUIRE           = 5 -- requirement field

        field {
            [FIELD_DATA]        = false,
            [FIELD_FORUPDATE]   = false,
            [FIELD_STATUS]      = STATUS_UNMODIFIED,
            [FIELD_CONTEXT]     = false,
            [FIELD_MODIFIED]    = false,
            [FIELD_REQUIRE]     = false,
        }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- Gets the entity's data context
        -- @return  context         the data context
        function GetDataContext(self)
            return self[FIELD_CONTEXT] or nil
        end

        --- Sets the entity's data context
        -- @param   context         the data context
        __Arguments__{ IDataContext }
        function SetDataContext(self, context)
            if not self[FIELD_CONTEXT] then
                self[FIELD_CONTEXT] = context
            else
                error("Usage: IDataEntity:SetDataContext(context) - the data entity already has data context", 2)
            end
        end

        --- Gets the entity's status
        -- @return status
        function GetEntityStatus(self)
            return self[FIELD_STATUS]
        end

        --- Sets the entity's status
        __Arguments__{ EntityStatus/STATUS_UNMODIFIED }
        function SetEntityStatus(self, status)
            if self[FIELD_STATUS] ~= status then
                self[FIELD_STATUS] = status

                if status == STATUS_UNMODIFIED then
                    self[FIELD_MODIFIED] = false
                else
                    local ctx   = self[FIELD_CONTEXT]
                    if ctx then ctx:AddChangedEntity(self) end
                end
            end
        end

        function SetLockForUpdate(self)
            self[FIELD_FORUPDATE] = true
        end

        --- Add a modified property
        function AddModifiedField(self, fld)
            local status        = self[FIELD_STATUS]

            if status == STATUS_UNMODIFIED or status == STATUS_MODIFIED then
                self[FIELD_MODIFIED]        = self[FIELD_MODIFIED] or {}
                self[FIELD_MODIFIED][fld]   = true

                if status == STATUS_UNMODIFIED then
                    self:SetEntityStatus(STATUS_MODIFIED)
                end
            end
        end

        --- Add a requirement entity
        __Arguments__{ IDataEntity }
        function AddRequireEntity(self, entity)
            self[FIELD_REQUIRE] = self[FIELD_REQUIRE] or {}
            self[FIELD_REQUIRE][entity] = true
        end

        --- Gets the modified fields
        function SaveChange(self, stack)
            local ctx           = self[FIELD_CONTEXT]
            local status        = self[FIELD_STATUS]
            if not ctx or status== STATUS_UNMODIFIED then return end
            stack               = (tonumber(stack) or 1) + 1

            local reqs          = self[FIELD_REQUIRE]

            if reqs then
                for entity in pairs(reqs) do
                    if entity[FIELD_STATUS] ~= STATUS_UNMODIFIED then
                        entity:SaveChange(stack)
                    end
                end
            end

            local entityCls         = getmetatable(self)
            local schema            = getDataTableSchema(entityCls)
            local flddata           = self[FIELD_DATA]

            if status == STATUS_NEW then
                local rs            = ctx.Connection:Insert(ctx.Connection:SqlBuilder():From(schema.name):Insert(flddata):ToSql())
                if schema.autokey and rs then
                    flddata[schema.primary] = rs
                end
            else
                local where         = {}
                local primary       = schema.primary

                if type(primary) == "table" then
                    for _, pkey in ipairs(primary) do
                        local val   = parseValue(flddata[pkey])
                        if val == nil then
                            error(("Usage: %s:SaveChange() - the entity don't have valid value of primary key"):format(tostring(entityCls)), stack)
                        end
                        where[pkey] = val
                    end
                else
                    local val       = parseValue(flddata[primary])
                    if val == nil then
                        error(("Usage: %s:SaveChange() - the entity don't have valid value of primary key"):format(tostring(entityCls)), stack)
                    end
                    where[primary]  = val
                end

                if status == STATUS_DELETED then
                    ctx[getDataTableCol(entityCls)]:Delete(self)
                    ctx:Execute(ctx.Connection:SqlBuilder():From(schema.name):Where(where):Delete():ToSql())
                elseif status == STATUS_MODIFIED and self[FIELD_FORUPDATE] then
                    local update    = {}

                    if not self[FIELD_MODIFIED] then
                        error(("Usage: %s:SaveChange() - the entity failed to track the modified fields"):format(tostring(entityCls)), stack)
                    end

                    for name in pairs(self[FIELD_MODIFIED]) do
                        local val   = parseValue(flddata[name])
                        if val == nil then val = DBNull end
                        update[name]= val
                    end

                    ctx:Execute(ctx.Connection:SqlBuilder():From(schema.name):Where(where):Update(update):ToSql())
                end
            end

            self:SetEntityStatus(STATUS_UNMODIFIED)
        end

        __Arguments__{ Table }
        function SetEntityData(self, data)
            self[FIELD_DATA]    = data
            self[FIELD_STATUS]  = STATUS_UNMODIFIED
            self[FIELD_MODIFIED]= false
        end

        function Delete(self)
            if self[FIELD_STATUS] ~= STATUS_NEW then
                self:SetEntityStatus(STATUS_DELETED)
            else
                self[FIELD_CONTEXT] = nil
            end
        end
    end)

    --- The attribute used to bind data table field to the property
    __Sealed__() class "__DataField__" (function(_ENV)
        extend "IAttachAttribute" "IInitAttribute"

        export {
            Class, Struct, IDataEntity, EntityStatus, Property, Date, AnyType,
            "getDataTableSchema", "getDataFieldProperty", "getDataTableFieldCount", "saveDataFieldSchema", "isUniqueIndex"
        }

        local FIELD_DATA        = 0

        local next              = next
        local error             = error
        local tonumber          = tonumber
        local rawget            = rawget
        local rawset            = rawset
        local pairs             = pairs
        local ipairs            = ipairs
        local getDataTableCol   = getDataTableCollection
        local type              = type
        local safeset           = Toolset.safeset
        local strlower          = string.lower
        local parseValue        = Data.ParseValue
        local __NonSerialized__ = System.Serialization.__NonSerialized__

        local TYPE_CONVERTER    = {
            [Boolean]           = {
                fromvalue       = function(value)
                    return tonumber(value) == 1 or false
                end,
                tovalue         = function(object)
                    return object and 1 or 0
                end,
            },
            [Date]              = {
                fromvalue       = function(value, format)
                    return Date.Parse(value, format)
                end,
                tovalue         = function(value, format)
                    return value:ToString(format)
                end,
            }
        }

        __Sealed__() struct "TypeConverter" {
            { name = "fromvalue", type = Function, require = true },
            { name = "tovalue",   type = Function, require = true },
            { name = "format",    type = Any }
        }

        __Sealed__() struct "PrimaryLink" {
            { name = "name",    type = String, require = true },
            { name = "order",   type = String + QueryOrders },

            __init              = function(self)
                if type(self.order) == "string" then
                    self.order= { { name = self.order } }
                end
            end,
        }

        __Sealed__() struct "ForeignMap" {
            { name = "map",     type = Table, require = true },
            { name = "link",    type = String + PrimaryLink },

            __init              = function(self)
                if type(self.link) == "string" then
                    self.link = { name = self.link }
                end
            end,
        }

        __Sealed__() struct "FieldSetting" {
            { name = "name",        type = String },
            { name = "type",        type = String },
            { name = "unique",      type = Boolean },
            { name = "autoincr",    type = Boolean },
            { name = "notnull",     type = Boolean },
            { name = "foreign",     type = ForeignMap },
            { name = "converter",   type = TypeConverter },
            { name = "format",      type = Any },
            { name = "fieldindex",  type = NaturalNumber },
        }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- attach data on the target
        -- @param   target                      the target
        -- @param   targettype                  the target type
        -- @param   owner                       the target's owner
        -- @param   name                        the target's name in the owner
        -- @param   stack                       the stack level
        -- @return  data                        the attribute data to be attached
        function AttachAttribute(self, target, targettype, owner, name, stack)
            if Class.Validate(owner) then return self[0] end
        end

        --- modify the target's definition
        -- @param   target                      the target
        -- @param   targettype                  the target type
        -- @param   definition                  the target's definition
        -- @param   owner                       the target's owner
        -- @param   name                        the target's name in the owner
        -- @param   stack                       the stack level
        -- @return  definition                  the new definition
        function InitDefinition(self, target, targettype, definition, owner, name, stack)
            if Class.Validate(owner) then
                local set           = self[0]
                if not set.name  then set.name = name end
                set.fieldindex      = getDataTableFieldCount(owner)

                saveDataFieldSchema(owner, name, set)

                local ptype
                for k, v in pairs(definition) do if strlower(k) == "type" then ptype = v break end end

                if set.foreign then
                    if not Class.Validate(ptype) then
                        error("The foreign data field's property must use the primary table's class as type", stack + 1)
                    end

                    local map       = set.foreign.map
                    local keycount  = 0
                    local pmap      = {}

                    for k, v in pairs(map) do
                        keycount    = keycount + 1
                        pmap[v]     = k
                    end

                    local fkey, mkey
                    if map then fkey, mkey = next(map) end

                    if keycount == 0 then
                        error("Usage: __DataField__{ foreign={ map = {fkey = mkey} }} - invalid key map", stack + 1)
                    end

                    local schema    = getDataTableSchema(ptype)
                    local isunique  = keycount == 1 and schema.unique[mkey] or isUniqueIndex(ptype, pmap)
                    local foreignfld= "_Foreign_" .. Namespace.GetNamespaceName(ptype, true) .. "_" .. name
                    local mainfld   = "_Main_" .. Namespace.GetNamespaceName(owner, true) .. "_" .. name

                    if not isunique then
                        error("Usage: __DataField__{ foreign={ map = {fkey = mkey} }} - invalid key map", stack + 1)
                    end

                    if keycount == 1 then
                        -- Single unique key
                        local tprop         = schema.map[mkey]
                        local ntnull        = set.notnull
                        local fromvalue, valformat

                        if schema.converter[mkey] then
                            fromvalue       = schema.converter[mkey][1].fromvalue
                            valformat       = schema.converter[mkey][2]
                        end

                        definition.type     = ptype
                        definition.get      = function(self)
                            local entity    = rawget(self, foreignfld)
                            if entity then return entity end

                            local context   = self:GetDataContext()
                            if context then
                                local data  = self[FIELD_DATA]
                                if data then
                                    local val   = parseValue(data[fkey])
                                    if val == nil then return end
                                    if fromvalue then val = fromvalue(val, valformat) end
                                    if val == nil then return end

                                    entity  = context[getDataTableCol(ptype)]:Query{ [tprop] = val }:First()
                                    if entity then
                                        rawset(self, foreignfld, entity)
                                        self:AddRequireEntity(entity)
                                        return entity
                                    end
                                end
                            end
                        end
                        definition.set      = function(self, new)
                            local context   = self:GetDataContext()
                            if not context then throw("The entity don't have a data context") end

                            local data      = self[FIELD_DATA]
                            if not data then data = {} self[FIELD_DATA] = data end

                            local value     = data[fkey]

                            if new == nil then
                                if ntnull then throw("The foreign entity can't be nil") end
                                if parseValue(value) == nil then return end
                                data[fkey]  = nil

                                self:AddModifiedField(fkey)
                            else
                                if new:GetDataContext() ~= context then
                                    throw("The reference entity must existed in the same data context")
                                end

                                local mdata = new[FIELD_DATA] or nil
                                local mval  = mdata and mdata[mkey]

                                if parseValue(mval) == nil then
                                    throw("the reference entity can't provide the field value")
                                end

                                if value == mval then return end
                                data[fkey]  = mval

                                self:AddModifiedField(fkey)
                                self:AddRequireEntity(new)
                            end

                            rawset(self, foreignfld, new)
                        end
                    else
                        -- Multi-unique keys
                        local propmap       = {}
                        local converter     = {}

                        for fkey, mkey in pairs(map) do
                            local prop      = schema.map[mkey]
                            propmap[prop]   = fkey
                            converter[prop] = schema.converter[mkey]
                        end

                        local ntnull        = set.notnull

                        definition.type     = ptype
                        definition.get      = function(self)
                            local entity    = rawget(self, foreignfld)
                            if entity then return entity end

                            local context   = self:GetDataContext()
                            if context then
                                local data  = self[FIELD_DATA]
                                if data then
                                    local query     = {}

                                    for prop, fld in pairs(propmap) do
                                        local val   = parseValue(data[fld])
                                        if val == nil then return end
                                        local conv  = converter[prop]
                                        if conv then
                                            val     = conv[1].fromvalue(val, conv[2])
                                        end
                                        if val == nil then return end
                                        query[prop] = val
                                    end

                                    entity = context[getDataTableCol(ptype)]:Query(query):First()
                                    if entity then
                                        rawset(self, foreignfld, entity)
                                        self:AddRequireEntity(entity)
                                        return entity
                                    end
                                end
                            end
                        end
                        definition.set      = function(self, new)
                            local context   = self:GetDataContext()
                            if not context then
                                throw("The entity don't have a data context")
                            end

                            local data      = self[FIELD_DATA]
                            if not data then data = {} self[FIELD_DATA] = data end

                            if new == nil then
                                if ntnull then throw("The foreign entity can't be nil") end

                                for fkey, mkey in pairs(map) do
                                    if parseValue(data[fkey]) == nil then return end
                                    data[fkey]   = nil
                                    self:AddModifiedField(fkey)
                                end
                            else
                                if new:GetDataContext() ~= context then
                                    throw("The reference entity must existed in the same data context")
                                end

                                local mdata     = new[FIELD_DATA]
                                if not mdata then
                                    throw("the reference entity can't provide the field value")
                                end

                                for fkey, mkey in pairs(map) do
                                    local nval  = mdata[mkey]
                                    local val   = data[fkey]

                                    if parseValue(nval) == nil then
                                        throw("the reference entity can't provide the field value")
                                    end

                                    if nval ~= val then
                                        data[fkey] = nval
                                        self:AddModifiedField(fld)
                                    end
                                end

                                self:AddRequireEntity(new)
                            end

                            rawset(self, foreignfld, new)
                        end
                    end

                    -- Install ref property to target class
                    if set.foreign.link then
                        local link      = set.foreign.link
                        local pset      = function(self, val)
                            if val ~= nil then error("The value can only be nil to reset the reference", 2) end
                            rawset(set, mainfld, nil)
                        end

                        local pget      = set.unique and function(self)
                            local entity    = rawget(self, mainfld)
                            if entity then return entity end

                            local context   = self:GetDataContext()
                            if context then
                                entity      = context[getDataTableCol(owner)]:Query{ [name] = self }:First()
                                rawset(self, mainfld, entity)
                                return entity
                            end
                        end or function(self)
                            local collection= rawget(self, mainfld)
                            if collection then return collection end

                            local context   = self:GetDataContext()
                            if context then
                                collection  = context[getDataTableCol(owner)]:Query({ [name] = self }, link.order)
                                rawset(self, mainfld, collection)
                                return collection
                            end
                        end

                        if ptype == owner then
                            __NonSerialized__()
                            Property.Parse(owner, link.name, { set = pset, get = pget })
                        else
                            class (ptype, function(_ENV)
                                __NonSerialized__()
                                property(link.name) { set = pset, get = pget }
                            end)
                        end
                    end
                else
                    local fld           = set.name
                    local schema        = getDataTableSchema(owner)
                    local converter     = set.converter or TYPE_CONVERTER[ptype]
                    local isprimary = schema.primary == fld

                    if type(schema.primary) == "table" then
                        for i, v in ipairs(schema.primary) do if v == fld then isprimary = true break end end
                    end

                    if converter then
                        set.converter   = converter
                        local fromvalue = converter.fromvalue
                        local tovalue   = converter.tovalue
                        local format    = set.format or converter.format
                        local objfld    = "_Object_" .. Namespace.GetNamespaceName(owner, true) .. "_" .. name

                        definition.get  = function(self)
                            local val   = rawget(self, objfld)
                            if val ~= nil then return val end

                            val         = self[FIELD_DATA] or nil
                            if val == nil then return end
                            val         = parseValue(val[fld])
                            if val == nil then return end

                            val     = fromvalue(val, format)
                            rawset(self, objfld, val)

                            return val
                        end

                        if isprimary then
                            definition.set  = function(self, object)
                                local value = rawget(self, objfld)
                                if value ~= nil and value == object then return end

                                local data  = self[FIELD_DATA]
                                if not data then data = {} self[FIELD_DATA] = data end
                                local oval  = parseValue(data[fld])

                                if object == nil then
                                    value   = nil
                                else
                                    value   = tovalue(object, format)
                                end

                                if value ~= oval and oval ~= nil then
                                    throw("The primary key can't be changed")
                                end
                                data[fld]   = value
                                self:AddModifiedField(fld)
                                rawset(self, objfld, object)
                            end
                        else
                            local ntnull    = set.notnull

                            definition.set  = function(self, object)
                                local value = rawget(self, objfld)
                                if value ~= nil and value == object then return end

                                local data  = self[FIELD_DATA]
                                if not data then data = {} self[FIELD_DATA] = data end
                                local oval  = parseValue(data[fld])

                                if object == nil then
                                    value   = nil
                                else
                                    value   = tovalue(object, format)
                                end

                                if value == oval then return end
                                if value == nil and ntnull then
                                    throw("The value can't be nil")
                                end

                                data[fld]   = value
                                self:AddModifiedField(fld)
                                rawset(self, objfld, object)
                            end
                        end
                    else
                        definition.get  = function(self) self = self[FIELD_DATA] or nil return self and parseValue(self[fld]) end

                        if isprimary then
                            definition.set  = function(self, value)
                                local data  = self[FIELD_DATA]
                                if not data then data = {} self[FIELD_DATA] = data end
                                local oval  = parseValue(data[fld])
                                if value ~= oval and oval ~= nil then
                                    throw("The primary key can't be changed")
                                end
                                data[fld]   = value
                                self:AddModifiedField(fld)
                            end
                        else
                            local ntnull    = set.notnull

                            definition.set  = function(self, value)
                                local data  = self[FIELD_DATA]
                                if not data then data = {} self[FIELD_DATA] = data end
                                local oval  = parseValue(data[fld])

                                if value == oval then return end
                                if value == nil and ntnull then
                                    throw("The value can't be nil")
                                end

                                data[fld]   = value
                                self:AddModifiedField(fld)
                            end
                        end
                    end
                end

                definition.throwable= true
            end
        end

        -----------------------------------------------------------
        --                    static property                    --
        -----------------------------------------------------------
        --- the default type converter
        __Static__() __Indexer__()
        property "Converter" {
            get     = function(self, datatype)
                return TYPE_CONVERTER[datatype]
            end,
            set     = function(self, datatype, converter)
                if Struct.ValidateValue(AnyType, datatype) and converter then
                    TYPE_CONVERTER = safeset(TYPE_CONVERTER, datatype, converter)
                end
            end,
            type    = TypeConverter,
        }

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- the attribute target
        property "AttributeTarget"  { set = false, default = AttributeTargets.Property }

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{  }
        function __new(_)
            return { [0] = {} }, true
        end

        __Arguments__{ String }
        function __new(_, name)
            return { [0] = { name = name } }, true
        end

        __Arguments__{ FieldSetting }
        function __new(_, set)
            return { [0] = set }, true
        end

        function __ctor(self)
            if self[0].foreign then
                __NonSerialized__()
            end
        end
    end)

    --- The attribute used to bind data table to the class
    __Sealed__() class "__DataTable__" (function(_ENV)
        extend "IAttachAttribute" "IApplyAttribute" "IInitAttribute"

        export { Namespace, Class, Environment, IDataContext, DataCollection, System.Serialization.__Serializable__, "saveDataTableSchema", "clearDataTableFieldCount" }

        __Sealed__() struct "DataTableIndex" {
            { name = "name",        type = String },
            { name = "unique",      type = Boolean },
            { name = "fulltext",    type = Boolean },
            { name = "primary",     type = Boolean },
            { name = "fields",      type = struct { String } },

            __init = function(val)
                if val.primary then val.unique = true end
            end
        }

        __Sealed__() struct "DataTableSetting" {
            { name = "name",        type = String },
            { name = "indexes",     type = struct { DataTableIndex } },
            { name = "collection",  type = String },
            { name = "engine",      type = String },
        }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- attach data on the target
        -- @param   target                      the target
        -- @param   targettype                  the target type
        -- @param   owner                       the target's owner
        -- @param   name                        the target's name in the owner
        -- @param   stack                       the stack level
        -- @return  data                        the attribute data to be attached
        function AttachAttribute(self, target, targettype, owner, name, stack)
            clearDataTableFieldCount(target)
            return self[0]
        end

        --- apply changes on the target
        -- @param   target                      the target
        -- @param   targettype                  the target type
        -- @param   manager                     the definition manager of the target
        -- @param   owner                       the target's owner
        -- @param   name                        the target's name in the owner
        -- @param   stack                       the stack level
        function ApplyAttribute(self, target, targettype, manager, owner, name, stack)
            Environment.Apply(manager, function(_ENV)
                extend (System.Data.IDataEntity)

                -----------------------------------------------------------
                --                      constructor                      --
                -----------------------------------------------------------
                __Arguments__{ IDataContext/nil, Table/nil }
                function __ctor(self, ctx, tbl)
                    if ctx then self:SetDataContext(ctx) end
                    if tbl then self:SetEntityData(tbl) end
                end
            end)
        end

        --- modify the target's definition
        -- @param   target                      the target
        -- @param   targettype                  the target type
        -- @param   definition                  the target's definition
        -- @param   owner                       the target's owner
        -- @param   name                        the target's name in the owner
        -- @param   stack                       the stack level
        -- @return  definition                  the new definition
        function InitDefinition(self, target, targettype, definition, owner, name, stack)
            local set       = self[0]
            set.name        = set.name or Namespace.GetNamespaceName(target, true)
            set.collection  = set.collection or (Namespace.GetNamespaceName(target, true) .. "s")
            saveDataTableSchema(target, set)
        end

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- the attribute target
        property "AttributeTarget"  { set = false, default = AttributeTargets.Class }

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{  }
        function __new(_)
            return { [0] = {} }, true
        end

        __Arguments__{ String }
        function __new(_, name)
            return { [0] = { name = name } }, true
        end

        __Arguments__{ DataTableSetting }
        function __new(_, set)
            return { [0] = set }, true
        end

        function __ctor(self)
            __Serializable__()
        end
    end)

    --- The attribute used to describe the data context
    __Sealed__() class "__DataContext__" (function(_ENV)
        extend "IApplyAttribute"

        export { Namespace, Class, Attribute, Environment, IDataContext, IDataEntity, __DataTable__, DataCollection, "next" }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- apply changes on the target
        -- @param   target                      the target
        -- @param   targettype                  the target type
        -- @param   manager                     the definition manager of the target
        -- @param   owner                       the target's owner
        -- @param   name                        the target's name in the owner
        -- @param   stack                       the stack level
        function ApplyAttribute(self, target, targettype, manager, owner, name, stack)
            Environment.Apply(manager, function(_ENV)
                extend (System.Data.IDataContext)
            end)

            for name, entityCls in Namespace.GetNamespaces(target) do
                if Class.Validate(entityCls) and Class.IsSubType(entityCls, IDataEntity) then
                    local set       = Attribute.GetAttachedData(__DataTable__, entityCls)
                    if set then
                        local name  = set.collection
                        local cls   = DataCollection[entityCls]

                        Environment.Apply(manager, function(_ENV)
                            property (name) {
                                set         = false,
                                default     = function(self) return cls(self) end,
                            }
                        end)
                    end
                end
            end
        end

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- the attribute target
        property "AttributeTarget"  { set = false, default = AttributeTargets.Class }
    end)

    __Sealed__() __Arguments__{ -IDataEntity }
    class "DataCollection" (function(_ENV, Entity)

        if Entity == IDataEntity then return end

        export {
            ipairs              = ipairs,
            pairs               = pairs,
            error               = error,
            strformat           = string.format,
            tostring            = tostring,

            Class, Property, Any, EntityStatus, List
        }

        -----------------------------------------------------------
        --                        helper                         --
        -----------------------------------------------------------
        local FIELD_DATA        = 0

        local clsname           = Namespace.GetNamespaceName(Entity, true)
        local schema            = getDataTableSchema(Entity)
        local tabelname         = schema.name
        local map               = schema.map
        local primary           = schema.primary
        local foreign           = schema.foreign
        local converter         = schema.converter
        local fields            = Dictionary(map).Keys:ToList()

        local props             = {}
        local fldmembers        = {}

        for fld, prop in pairs(map) do
            if not fldmembers[prop] then
                fldmembers[prop]= Class.GetFeature(Entity, prop):GetType() or Any

                if not foreign[prop] then
                    props[prop] = fld
                end
            end
        end

        QueryData               = struct(fldmembers)
        fldmembers              = nil

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        __Arguments__{ QueryData, QueryOrders/nil }
        function Query(self, query, orders)
            local fquery        = {}

            for name, val in pairs(query) do
                local fld       = props[name]

                if fld then
                    if converter[fld] then
                        val     = converter[1].tovalue(val, converter[2])
                        if val == nil then
                            error(strformat("The %q isn't valid", name), 2)
                        end
                    end
                    fquery[fld] = val
                elseif foreign[name] then
                    local data  = val[FIELD_DATA]

                    if not data then
                        error(strformat("The %q isn't valid", name), 2)
                    end

                    for fkey, mkey in pairs(foreign[name]) do
                        local fval  = data[mkey]
                        if fval == nil then
                            error(strformat("The %q isn't valid", name), 2)
                        end
                        fquery[fkey]= fval
                    end
                else
                    error(strformat("The %s don't have field property named %q", clsname, name), 2)
                end
            end

            local ctx           = self[0]
            local builder       = ctx.Connection:SqlBuilder():From(tabelname):Select(fields):Where(fquery)

            if orders then
                for _, order in ipairs(orders) do
                    builder:OrderBy(order.name, order.desc)
                end
            end

            local sql           = builder:ToSql()

            if sql then
                local rs        = ctx:Query(sql)

                if rs then
                    for i, data in ipairs(rs) do
                        rs[i]   = Entity(ctx, data)
                    end

                    return rs
                end
            end

            return List()
        end

        __Arguments__{ QueryData, QueryOrders/nil }
        function Lock(self, query, orders)
            local fquery        = {}

            for name, val in pairs(query) do
                local fld       = props[name]

                if fld then
                    if converter[fld] then
                        val     = converter[1].tovalue(val, converter[2])
                        if val == nil then
                            error(strformat("The %q isn't valid", name), 2)
                        end
                    end
                    fquery[fld] = val
                elseif foreign[name] then
                    local data  = val[FIELD_DATA]

                    if not data then
                        error(strformat("The %q isn't valid", name), 2)
                    end

                    for fkey, mkey in pairs(foreign[name]) do
                        local fval  = data[mkey]
                        if fval == nil then
                            error(strformat("The %q isn't valid", name), 2)
                        end
                        fquery[fkey]= fval
                    end
                else
                    error(strformat("The %s don't have field property named %q", clsname, name), 2)
                end
            end

            local ctx           = self[0]
            local builder       = ctx.Connection:SqlBuilder():From(tabelname):Select(fields):Where(fquery):Lock()

            if orders then
                for _, order in ipairs(orders) do
                    builder:OrderBy(order.name, order.desc)
                end
            end

            local sql           = builder:ToSql()

            if sql then
                local rs        = ctx:Query(sql)

                if rs then
                    for i, data in ipairs(rs) do
                        rs[i]   = Entity(ctx, data)
                        rs[i]:SetLockForUpdate()
                    end

                    return rs
                end
            end

            return List()
        end

        __Arguments__{ NEString, Any * 0 }
        function Query(self, sql, ...)
            local ctx           = self[0]
            --local sql           = ctx.Connection:SqlBuilder():From(tabelname):Select(fields):Where(where, ...):ToSql()

            if ctx then
                local rs        = ctx:Query(sql, ...)

                if rs then
                    for i, data in ipairs(rs) do
                        rs[i]   = Entity(ctx, data)
                    end

                    return rs
                end
            end

            return List()
        end

        --- Get the data context of the data collection
        function GetDataContext(self)
            return self[0]
        end

        --- Add a data entity to the collection
        __Arguments__{ QueryData }
        function Add(self, data)
            local entity    = Entity(self[0])
            entity:SetEntityStatus(EntityStatus.NEW)
            for k, v in pairs(data) do
                entity[k]   = v
            end
            return entity
        end

        function Delete(self, entity)
            entity:Delete()
        end

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{ IDataContext }
        function __new(cls, context)
            return { [0] = context }, true
        end
    end)
end)