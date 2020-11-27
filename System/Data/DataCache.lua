--===========================================================================--
--                                                                           --
--                           System.Data.DataCache                           --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2018/11/08                                               --
-- Update Date  :   2020/08/29                                               --
-- Version      :   1.4.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Data"

    local PLOOP_CACHE_KEY_PREFIX= "PLDC:"

    --- The interface for bridges between the data context and the cache server
    __Sealed__() interface "IDataCache" (function(_ENV)
        extend "IAutoClose"

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- The data context
        __Abstract__() property "DataContext"   { type = IDataContext }

        --- The cache object
        __Abstract__() property "Cache"         { type = ICache }

        --- The time out seconds
        __Abstract__() property "Timeout"       { type = NaturalNumber }

        --- The timeout for fake entities
        __Abstract__() property "FakeTimeout"   { type = NaturalNumber, default = Platform.DATA_CACHE_FAKE_ENTITY_TIMEOUT }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- Get the object from the cache or the data base
        __Abstract__() function Get(self, ...) end

        --- Save the object to the cache
        __Abstract__() function Save(self, object) end

        --- Delete the object from the cache
        __Abstract__() function Delete(self, object) end
    end)

    --- The bindings between the data entity and the data cache
    __Arguments__{ -IDataEntity, -ICache, NaturalNumber/nil }
    __Sealed__() class "DataEntityCache" (function(_ENV, clsEntity, clsCache, defaultTimeout)
        extend "IDataCache"

        export { "tostring", "ipairs", "pairs", "tonumber", "select", "error", with = with, List, unpack = unpack or table.unpack, loadsnippet = Toolset.loadsnippet, clone = Toolset.clone }

        local clsContext        = Namespace.GetNamespace(Namespace.GetNamespaceName(clsEntity):match("^(.*)%.[%P_]+$"))
        local CACHE_KEY         = PLOOP_CACHE_KEY_PREFIX .. clsEntity .. ":"

        local set               = Attribute.GetAttachedData(__DataTable__, clsEntity)
        if not set.indexes then error("The " .. clsEntity .. " has no data table index settings") end

        local props             = {}

        for name, ftr in Class.GetFeatures(clsEntity) do
            if Property.Validate(ftr) and not Property.IsStatic(ftr) then
                local dfield    = Attribute.GetAttachedData(__DataField__, ftr, clsEntity)
                if dfield and not dfield.foreign then
                    props[dfield.name] = name
                end
            end
        end

        local primaryflds       = List()
        local primarymap        = {}

        for _, index in ipairs(set.indexes) do
            if index.primary then
                for i, fld in ipairs(index.fields) do
                    fld         = props[fld]
                    primarymap[fld] = i
                    primaryflds[i]  = { name = fld, type = Class.GetFeature(clsEntity, fld):GetType() or Any, require = true }
                end
                break
            end
        end

        if #primaryflds == 0 then error("The " .. clsEntity .. " has no data table primary index settings") end

        -- Check the unique indexes
        local uniques
        local uniqueflds

        for idx, index in ipairs(set.indexes) do
            if index.unique then
                local u         = {}
                local p         = 0

                for i, fld in ipairs(index.fields) do
                    fld         = props[fld]
                    u[i]        = fld

                    if primarymap[fld] then
                        p       = p + 1
                    end
                end

                -- Skip the unique index that contains full primary fields
                if p ~= #primaryflds then
                    uniques     = uniques or {}
                    uniques[idx]= u

                    uniqueflds  = uniqueflds or primaryflds:Map(function(item) item = clone(item) item.require = nil return item end):ToList()

                    for i, fld in ipairs(u) do
                        if not primarymap[fld] and not uniqueflds[fld] then
                            uniqueflds[fld] = true
                            uniqueflds:Insert{ name = fld, type = Class.GetFeature(clsEntity, fld):GetType() or Any }
                        end
                    end
                end
            end
        end

        local KeyCollection     = set.collection
        props                   = nil

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- The data context
        property "DataContext"   { type = clsContext }

        --- The cache object
        property "Cache"         { type = clsCache }

        --- The time out seconds
        property "Timeout"       { type = NaturalNumber, default = defaultTimeout }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        function Open(self)
            self.DataContext    = clsContext()
            self.Cache          = clsCache()

            self.DataContext:Open()
            self.Cache:Open()
        end

        function Close(self, error)
            self.DataContext:Close()
            self.Cache:Close()
        end

        -----------------------------------------------------------
        --                    auto gen method                    --
        -----------------------------------------------------------
        local args              = List(#primaryflds, "i=>'arg' .. i"):Join(", ")
        local entityKey         = '"' .. CACHE_KEY .. '" .. ' .. List(#primaryflds, "i=>'tostring(arg' .. i .. ')'"):Join(" .. '^' .. ")
        local queryMap          = List(#primaryflds, function(i) return primaryflds[i].name .. " = " .. "arg" .. i end):Join(", ")
        local argMap            = List(#primaryflds, function(i) return "arg" .. i end):Join(", ") .. " = " .. List(#primaryflds, function(i) return "query." .. primaryflds[i].name end):Join(", ")
        local indexKeys         = List{ '"' .. CACHE_KEY .. '" .. ' .. List(#primaryflds, function(i) return "tostring(entity." .. primaryflds[i].name .. ")" end):Join(" .. '^' .. ") }
        local indexCond         = List{ "if " .. List(#primaryflds, function(i) return "entity." .. primaryflds[i].name .. " ~= nil" end):Join(" and ") .. " then " }

        if uniques then
            for idx, unique in pairs(uniques) do
                indexKeys:Insert( '"' .. CACHE_KEY .. idx  .. ':" .. ' .. List(#unique, function(i) return "tostring(entity." .. unique[i] .. ")" end):Join(" .. '^' .. ") )
                indexCond:Insert("if " .. List(#unique, function(i) return "entity." .. unique[i] .. " ~= nil" end):Join(" and ") .. " then ")
            end
        end

        local autoGenCode       = [[
            local primaryflds, clsEntity, clsContext, clsCache, QueryData  = ...

            local function saveEntity(self, cache, entity)
                cache:Set(]] .. indexKeys[1] .. [[, entity, self.Timeout)
                ]] .. (
                    uniques and (
                        "local key =" .. List(#primaryflds, function(i) return "tostring(entity." .. primaryflds[i].name .. ")" end):Join(" .. '^' .. ") .. "\n"..
                        List(#indexKeys - 1, function(i) return indexCond[i + 1] .. "cache:Set(" .. indexKeys[i + 1] .. ", key, self.Timeout) end" end):Join("\n")
                    ) or ""
                ) .. [[
            end

            local function refreshTimeout(self, cache, entity)
                ]] .. List(#indexKeys, function(i) return indexCond[i] .. "cache:SetExpireTime(" .. indexKeys[i] .. ", self.Timeout) end" end):Join("\n") .. [[
            end

            local function removeEntity(self, cache, entity)
                ]] .. List(#indexKeys, function(i) return indexCond[i] .. "cache:Delete(" .. indexKeys[i] .. ") end" end):Join("\n") .. [[
            end

            local function getKey(self, entity)
                ]] .. indexCond[1] .. [[return ]] .. indexKeys[1] .. [[, true end
                ]] .. (
                    uniques and (
                        XDictionary(uniques).Keys:Map(function(idx)
                            local unique = uniques[idx]
                            return "if " .. List(#unique, function(i) return "entity." .. unique[i] .. " ~= nil" end):Join(" and ") .. " then return " .. '"' .. CACHE_KEY .. idx  .. ':" .. ' .. List(#unique, function(i) return "tostring(entity." .. unique[i] .. ")" end):Join(" .. '^' .. ") .. ", false end" end)
                        :Join("\n")
                    ) or ""
                ) .. [[
            end

            --- Get the entity object with the index key
            __Arguments__{ unpack( primaryflds:Map("v=>{ name = v.name, type = v.type }"):ToList() ) }
            function Get(self, ]] .. args .. [[)
                local key       = ]] .. entityKey .. [[
                local entity

                if self.Cache then
                    entity      = self.Cache:Get(key, clsEntity)

                    if entity == nil then
                        entity  = self.DataContext.]] .. KeyCollection .. [[:Query{]] .. queryMap .. [[ }:First()
                        if entity then
                            saveEntity(self, self.Cache, entity)
                        ]] .. (Platform.DATA_CACHE_USE_FAKE_ENTITY and [[
                        else
                            self.Cache:Set(key, false, self.FakeTimeout)
                        ]] or "") .. [[
                        end
                    elseif entity then
                        if self.Timeout then
                            refreshTimeout(self, self.Cache, entity)
                        end
                    else
                        self.Cache:SetExpireTime(key, self.FakeTimeout)
                    end
                else
                    with(clsCache())(function(cache)
                        entity  = cache:Get(key, clsEntity)
                        if entity == nil then
                            with(clsContext())(function(ctx)
                                entity = ctx.]] .. KeyCollection .. [[:Query{]] .. queryMap .. [[ }:First()
                            end)

                            if entity then
                                saveEntity(self, cache, entity)
                            ]] .. (Platform.DATA_CACHE_USE_FAKE_ENTITY and [[
                            else
                                cache:Set(key, false, self.FakeTimeout)
                            ]] or "") .. [[
                            end
                        elseif entity then
                            if self.Timeout then
                                refreshTimeout(self, cache, entity)
                            end
                        else
                            cache:SetExpireTime(key, self.FakeTimeout)
                        end
                    end)
                end

                return entity or nil
            end

            __Arguments__{ QueryData }:Throwable()
            function Get(self, query)
                local key, main = getKey(self, query)
                if not key then throw("The primary key or unique keys are needed in the query data", 2) end
                local entity
                local fkey      = key

                if self.Cache then
                    if not main then
                        local v = self.Cache:Get(key)
                        if v == false then return end -- fake entity
                        key     = v and ("]] .. CACHE_KEY .. [[" .. v) or nil
                    end

                    entity      = key and self.Cache:Get(key, clsEntity)

                    if entity == nil then
                        entity  = self.DataContext.]] .. KeyCollection .. [[:Query(query):First()
                        if entity then
                            saveEntity(self, self.Cache, entity)
                        ]] .. (Platform.DATA_CACHE_USE_FAKE_ENTITY and [[
                        else
                            self.Cache:Set(fkey, false, self.FakeTimeout)
                        ]] or "") .. [[
                        end
                    elseif entity then
                        if self.Timeout then
                            refreshTimeout(self, self.Cache, entity)
                        end
                    else
                        self.Cache:SetExpireTime(fkey, self.FakeTimeout)
                    end
                else
                    with(clsCache())(function(cache)
                        if not main then
                            local v = cache:Get(key)
                            if v == false then return end -- fake entity
                            key = v and ("]] .. CACHE_KEY .. [[" .. v) or nil
                        end

                        entity  = key and cache:Get(key, clsEntity)
                        if entity == nil then
                            with(clsContext())(function(ctx)
                                entity = ctx.]] .. KeyCollection .. [[:Query(query):First()
                            end)

                            if entity then
                                saveEntity(self, cache, entity)
                            ]] .. (Platform.DATA_CACHE_USE_FAKE_ENTITY and [[
                            else
                                cache:Set(fkey, false, self.FakeTimeout)
                            ]] or "") .. [[
                            end
                        elseif entity then
                            if self.Timeout then
                                refreshTimeout(self, cache, entity)
                            end
                        else
                            cache:SetExpireTime(fkey, self.FakeTimeout)
                        end
                    end)
                end

                return entity or nil
            end

            --- Set the entity to the cache
            __Arguments__{ clsEntity }
            function Save(self, entity)
                if self.Cache then
                    saveEntity(self, self.Cache, entity)
                else
                    with(clsCache())(function(cache)
                        saveEntity(self, cache, entity)
                    end)
                end
            end

            --- Delete the entity from the cache
            __Arguments__{ clsEntity }
            function Delete(self, entity)
                if self.Cache then
                    removeEntity(self, self.Cache, entity)
                else
                    with(clsCache())(function(cache)
                        removeEntity(self, cache, entity)
                    end)
                end
            end

            __Arguments__{ unpack( primaryflds:Map("v=>{ name = v.name, type = v.type }"):ToList() ) }
            function Delete(self, ]] .. args .. [[)
                local key       = ]] .. entityKey .. [[

                if self.Cache then
                    self.Cache:Delete(key)
                else
                    with(clsCache())(function(cache)
                        cache:Delete(key)
                    end)
                end
            end
        ]]

        loadsnippet(autoGenCode, "DataEntityCache-" .. clsEntity, _ENV)(primaryflds, clsEntity, clsContext, clsCache, struct { unpack((uniqueflds or primaryflds):Map(Toolset.clone):ToList()) })
    end)

    --- The bindings between the data object and the data cache
    __Arguments__{ -IDataObject, -ICache, NaturalNumber/nil }
    __Sealed__() class "DataObjectCache" (function(_ENV, clsDataObject, clsCache, defaultTimeout)
        extend "IDataCache"

        export { "tostring", "ipairs", "tonumber", "select", List, with = with, unpack = unpack or table.unpack, loadsnippet = Toolset.loadsnippet }

        local clsContext        = Namespace.GetNamespace(Namespace.GetNamespaceName(clsDataObject):match("^(.*)%.[%P_]+$"))
        local CACHE_KEY         = PLOOP_CACHE_KEY_PREFIX .. clsDataObject .. ":"

        local set               = Attribute.GetAttachedData(__DataObject__, clsDataObject)
        if not set.index then error("The " .. clsDataObject .. " has no data object index settings") end

        local primaryflds       = List()

        for i, index in ipairs(set.index) do
            primaryflds[i]      = { name = index, type = Class.GetFeature(clsDataObject, index):GetType() or Any, require = true }
        end

        if #primaryflds == 0 then error("The " .. clsDataObject .. " has no data table index settings") end

        local KeyCollection     = set.collection

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- The data context
        property "DataContext"   { type = clsContext }

        --- The cache object
        property "Cache"         { type = clsCache }

        --- The time out seconds
        property "Timeout"       { type = NaturalNumber, default = defaultTimeout }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        function Open(self)
            self.DataContext    = clsContext()
            self.Cache          = clsCache()

            self.DataContext:Open()
            self.Cache:Open()
        end

        function Close(self, error)
            self.DataContext:Close()
            self.Cache:Close()
        end

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        local args              = List(#primaryflds, "i=>'arg' .. i"):Join(", ")
        local entityKey         = '"' .. CACHE_KEY .. '" .. ' .. List(#primaryflds, "i=>'tostring(arg' .. i .. ')'"):Join(" .. '^' .. ")
        local queryMap          = List(#primaryflds, function(i) return primaryflds[i].name .. " = " .. "arg" .. i end):Join(", ")
        local argMap            = List(#primaryflds, function(i) return "arg" .. i end):Join(", ") .. " = " .. List(#primaryflds, function(i) return "query." .. primaryflds[i].name end):Join(", ")

        local autoGenCode       = [[
            local primaryflds, clsDataObject, clsContext, clsCache, QueryData  = ...

            --- Get the entity object with the index key
            __Arguments__{ unpack( primaryflds:Map("v=>{ name = v.name, type = v.type }"):ToList() ) }
            function Get(self, ]] .. args .. [[)
                local key       = ]] .. entityKey .. [[
                local entity

                if self.Cache then
                    entity      = self.Cache:Get(key, clsDataObject)

                    if entity == nil then
                        entity  = self.DataContext.]] .. KeyCollection .. [[:Query(]] .. args .. [[)
                        if entity then
                            self.Cache:Set(key, entity, self.Timeout)
                        ]] .. (Platform.DATA_CACHE_USE_FAKE_ENTITY and [[
                        else
                            self.Cache:Set(key, false, self.FakeTimeout)
                        ]] or "") .. [[
                        end
                    elseif entity then
                        if self.Timeout then
                            self.Cache:SetExpireTime(key, self.Timeout)
                        end
                    else
                        self.Cache:SetExpireTime(key, self.FakeTimeout)
                    end
                else
                    with(clsCache())(function(cache)
                        entity  = cache:Get(key, clsDataObject)

                        if entity == nil then
                            with(clsContext())(function(ctx)
                                entity  = ctx.]] .. KeyCollection .. [[:Query(]] .. args .. [[)
                            end)
                            if entity then
                                cache:Set(key, entity, self.Timeout)
                            ]] .. (Platform.DATA_CACHE_USE_FAKE_ENTITY and [[
                            else
                                cache:Set(key, false, self.FakeTimeout)
                            ]] or "") .. [[
                            end
                        elseif entity then
                            if self.Timeout then
                                cache:SetExpireTime(key, self.Timeout)
                            end
                        else
                            cache:SetExpireTime(key, self.FakeTimeout)
                        end
                    end)
                end

                return entity or nil
            end

            __Arguments__{ QueryData }
            function Get(self, query)
                local ]] .. argMap .. [[
                local key       = ]] .. entityKey .. [[
                local entity

                if self.Cache then
                    entity      = self.Cache:Get(key, clsDataObject)

                    if entity == nil then
                        entity  = self.DataContext.]] .. KeyCollection .. [[:Query(]] .. args .. [[)
                        if entity then
                            self.Cache:Set(key, entity, self.Timeout)
                        ]] .. (Platform.DATA_CACHE_USE_FAKE_ENTITY and [[
                        else
                            self.Cache:Set(key, false, self.FakeTimeout)
                        ]] or "") .. [[
                        end
                    elseif entity then
                        if self.Timeout then
                            self.Cache:SetExpireTime(key, self.Timeout)
                        end
                    else
                        self.Cache:SetExpireTime(key, self.FakeTimeout)
                    end
                else
                    with(clsCache())(function(cache)
                        entity  = cache:Get(key, clsDataObject)

                        if entity == nil then
                            with(clsContext())(function(ctx)
                                entity  = ctx.]] .. KeyCollection .. [[:Query(]] .. args .. [[)
                            end)
                            if entity then
                                cache:Set(key, entity, self.Timeout)
                            ]] .. (Platform.DATA_CACHE_USE_FAKE_ENTITY and [[
                            else
                                cache:Set(key, false, self.FakeTimeout)
                            ]] or "") .. [[
                            end
                        elseif entity then
                            if self.Timeout then
                                cache:SetExpireTime(key, self.Timeout)
                            end
                        else
                            cache:SetExpireTime(key, self.FakeTimeout)
                        end
                    end)
                end

                return entity or nil
            end

            --- Set the entity to the cache
            __Arguments__{ clsDataObject }
            function Save(self, query)
                local ]] .. argMap .. [[
                local key       = ]] .. entityKey .. [[

                if self.Cache then
                    self.Cache:Set(key, query, self.Timeout)
                else
                    with(clsCache())(function(cache)
                        cache:Set(key, query, self.Timeout)
                    end)
                end
            end

            --- Delete the entity from the cache
            __Arguments__{ clsDataObject }
            function Delete(self, query)
                local ]] .. argMap .. [[
                local key       = ]] .. entityKey .. [[

                if self.Cache then
                    self.Cache:Delete(key)
                else
                    with(clsCache())(function(cache)
                        cache:Delete(key)
                    end)
                end
            end

            __Arguments__{ unpack( primaryflds:Map("v=>{ name = v.name, type = v.type }"):ToList() ) }
            function Delete(self, ]] .. args .. [[)
                local key       = ]] .. entityKey .. [[

                if self.Cache then
                    self.Cache:Delete(key)
                else
                    with(clsCache())(function(cache)
                        cache:Delete(key)
                    end)
                end
            end

            __Arguments__{ QueryData }
            function Delete(self, query)
                local ]] .. argMap .. [[
                local key       = ]] .. entityKey .. [[

                if self.Cache then
                    self.Cache:Delete(key)
                else
                    with(clsCache())(function(cache)
                        cache:Delete(key)
                    end)
                end
            end
        ]]

        loadsnippet(autoGenCode, "DataObjectCache-" .. clsDataObject, _ENV)(primaryflds, clsDataObject, clsContext, clsCache, struct { unpack(primaryflds:Map(Toolset.clone):ToList()) })
    end)

    --- The attribute used to bind the cache settings to the data entity or data object class
    __Sealed__() class "__DataCacheEnable__" (function(_ENV)
        extend "IAttachAttribute"

        export {
            __DataField__, __DataTable__, __DataObject__, IDataEntity, IDataObject, Namespace,

            ipairs              = ipairs,
            pairs               = pairs,
            type                = type,
            unpack              = unpack or table.unpack,
            clone               = Toolset.clone,
            error               = error,
            getFeature          = Class.GetFeature,
            getFeatures         = Class.GetFeatures,

            isProperty          = Property.Validate,
            isStaticProp        = Property.IsStatic,
            isSubType           = Class.IsSubType,
            getAttachedData     = Attribute.GetAttachedData,
            getNamespaceName    = Namespace.GetNamespaceName,
            getNamespace        = Namespace.GetNamespace,
        }

        local function isDataField(cls, prop)
            local feature       = getFeature(cls, prop)
            return feature and isProperty(feature) and getAttachedData(__DataField__, feature, cls) and true or false
        end

        local function isPropertyField(cls, prop)
            local feature       = getFeature(cls, prop)
            return feature and isProperty(feature) or false
        end

        local function getRootNamespace(cls)
            return getNamespace(Namespace.GetNamespaceName(cls):match("^(.*)%.[%P_]+$"))
        end

        struct "DataCacheSettings" {
            name                = String,
            depends             = struct  { [(-IDataEntity) + String] = struct { [String] = String } },
            timeout             = NaturalNumber,
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
            local settings      = self[1] or {}

            if not settings.name then
                settings.name   = getNamespaceName(target, true) .. "Cache"
            end

            local root          = getRootNamespace(target)

            if settings.depends then
                local depends   = {}

                for depcls, map in pairs(settings.depends) do
                    if type(depcls) == "string" then
                        local cl= getNamespace(root, depcls)
                        if not isSubType(cl, IDataEntity) then
                            error("The " .. depcls .. " is not a data entity class can be used as dependency", stack + 1)
                        end
                        depends[cl]     = map
                    else
                        depends[depcls] = map
                    end
                end

                settings.depends= depends
            end

            if isSubType(target, IDataEntity) then
                local set       = getAttachedData(__DataTable__, target)
                if not set.indexes then error("The " .. target .. " has no data table index settings", stack + 1) end

                local props     = {}

                for name, ftr in getFeatures(target) do
                    if isProperty(ftr) and not isStaticProp(ftr) then
                        local dfield    = getAttachedData(__DataField__, ftr, target)
                        if dfield and not dfield.foreign then
                            props[dfield.name] = name
                        end
                    end
                end

                local primary   = {}

                for _, index in ipairs(set.indexes) do
                    if index.primary then
                        for i, fld in ipairs(index.fields) do
                            fld         = props[fld]
                            primary[fld]= i
                            primary[i]  = fld
                        end
                        break
                    end
                end


                if #primary == 0 then error("The " .. target .. " has no data table primary index settings", stack + 1) end

                -- Check depends
                if settings.depends then
                    error("The " .. target .. " is a data entity, can't have depends", stack + 1)
                end

                settings.primary= { unpack(primary) }
                return settings
            elseif isSubType(target, IDataObject) then
                local set       = getAttachedData(__DataObject__, target)
                local primary   = set.index

                for i, index in ipairs(primary) do
                    primary[index] = i
                end

                -- Check depends
                if settings.depends then
                    for depcls, map in pairs(settings.depends) do
                        local count     = 0
                        local convertor = {}

                        if getRootNamespace(depcls) ~= root then
                            error(("The %s isn't in the same data context of %s"):format(tostring(depcls), tostring(target)), stack + 1)
                        end

                        for dprop, sprop in pairs(map) do
                            if not isDataField(depcls, dprop) then
                                error(("The %s isn't a data field property of the %s"):format(dprop, tostring(depcls)), stack + 1)
                            end
                            if not primary[sprop] then
                                error(("The %s isn't an index data field property of the %s"):format(sprop, tostring(target)), stack + 1)
                            end

                            convertor[primary[sprop]] = dprop

                            count = count + 1
                        end

                        if count ~= #primary then
                            error(("The mapping of the %s don't match all parimay field of the %s"):format(tostring(depcls), tostring(target)), stack + 1)
                        end

                        settings.depends[depcls] = convertor
                    end
                else
                    error(("The %s must have depend class settings"):format(tostring(target)), stack + 1)
                end

                return settings
            end
        end

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- the attribute target
        property "AttributeTarget"  { set = false, default = AttributeTargets.Class }

        --- the attribute's priority
        property "Priority"         { type = AttributePriority, default = AttributePriority.Lowest }

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{  DataCacheSettings/nil  }
        function __new(self, settings)
            return { settings }, true
        end
    end)

    --- The attribute used to bind cache to data context
    __Sealed__() class "__DataContextCache__" (function(_ENV)
        extend "IAttachAttribute" "IApplyAttribute"

        export { Namespace, Environment, Class, List, DataEntityCache, DataObjectCache, EntityStatus, IDataEntity, IDataObject, __DataCacheEnable__, rawset = rawset, GetObjectClass = getmetatable, pairs = pairs, ipairs = ipairs, unpack = unpack or table.unpack, safeset = Toolset.safeset, loadsnippet = Toolset.loadsnippet, getAttachedData = Attribute.GetAttachedData }

        local _EntityDepends    = {}

        local _PrimaryMap       = setmetatable({}, {
            __index             = function(self, count)
                local func, msg = loadsnippet([[
                    return function(map, entity)
                        return ]] .. List(count, "i=>'entity[map[' .. i .. ']]'"):Join(", ") .. [[
                    end
                ]], "DataContextCache_Map_" .. count, _ENV)()

                rawset(self, count, func)
                return func
            end
        })

        local _SaveEntityPrimary= setmetatable({}, {
            __index             = function(self, count)
                local args      = List(count, "i=>'arg' .. i"):Join(", ")
                local func, msg = loadsnippet([[
                    return function(cache, ]] .. args .. [[)
                        local len = #cache
                        for i = 1, len, ]] .. count .. [[ do
                            if ]] .. List(count, "i=>'cache[i + ' .. (i-1) .. '] == arg' .. i"):Join(" and ")  .. [[ then return end
                        end
                        ]] .. List(count, "i=>'cache[len + ' .. i .. ']'"):Join(", ") .. [[ = ]] .. args .. [[
                    end
                ]], "DataContextCache_Primary_" .. count, _ENV)()

                rawset(self, count, func)
                return func
            end
        })

        local function onEntitySaved(self, entities)
            local map           = {}

            local objCache      = {}

            for entity, status in pairs(entities) do
                local cls                   = GetObjectClass(entity)
                local depends               = _EntityDepends[cls]

                if depends then
                    for target, convertor in pairs(depends) do
                        if target == cls then
                            local cachecls  = convertor[0]
                            local object    = objCache[cachecls] or cachecls()
                            objCache[cachecls] = object

                            -- Clear self with primary and unique index, so we must pass the entity
                            object:Delete(entity)
                        else
                            local count         = #convertor
                            local cache         = map[convertor]
                            if not cache then
                                cache           = {}
                                map[convertor]  = cache
                            end
                            _SaveEntityPrimary[count](cache, _PrimaryMap[count](convertor, entity))
                        end
                    end
                end
            end

            for convertor, cache in pairs(map) do
                local count     = #convertor
                local cls       = convertor[0]
                local object    = objCache[cls] or cls()
                objCache[cls]   = object

                for i = 1, #cache, count do
                    object:Delete(unpack(cache, i, i + count - 1))
                end
            end
        end

        --- The interface used to listen the data entity saved event on data context objects
        __Sealed__()
        local IDataContextCacheEnabled = interface "IDataContextCacheEnabled" {
            function(self) self.OnEntitySaved = self.OnEntitySaved + onEntitySaved end
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
            local context           = Namespace.GetNamespaceName(target)

            local _Classes          = {}

            for _, entityCls in Namespace.GetNamespaces(target) do
                local isEntityCls   = Class.IsSubType(entityCls, IDataEntity)

                if Class.Validate(entityCls) and (isEntityCls or Class.IsSubType(entityCls, IDataObject)) then
                    _Classes[entityCls]     = isEntityCls
                end
            end

            for entityCls, isEntityCls in pairs(_Classes) do
                local settings  = getAttachedData(__DataCacheEnable__, entityCls)

                if settings then
                    --- Define the cache class
                    local Cache = class (context .. "." .. settings.name) { (isEntityCls and DataEntityCache or DataObjectCache)[{ entityCls, self.CacheClass, settings.timeout or self.CacheTimeout }] }

                    -- Build the depend map
                    if settings.depends then
                        for depcls, convertor in pairs(settings.depends) do
                            convertor[0]    = Cache
                            _EntityDepends  = safeset(_EntityDepends, depcls, safeset(_EntityDepends[depcls] or {}, entityCls, convertor))
                        end
                    end

                    if isEntityCls then
                        local primary       = settings.primary
                        primary[0]          = Cache
                        _EntityDepends      = safeset(_EntityDepends, entityCls, safeset(_EntityDepends[entityCls] or {}, entityCls, primary))
                    end
                end
            end
        end

        --- apply changes on the target
        -- @param   target                      the target
        -- @param   targettype                  the target type
        -- @param   manager                     the definition manager of the target
        -- @param   owner                       the target's owner
        -- @param   name                        the target's name in the owner
        -- @param   stack                       the stack level
        function ApplyAttribute(self, target, targettype, manager, owner, name, stack)
            Class.AddExtend(target, IDataContextCacheEnabled)
        end

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- the attribute target
        property "AttributeTarget"  { set = false, default = AttributeTargets.Class }

        --- the attribute's priority
        property "Priority"         { type = AttributePriority, default = AttributePriority.Lowest }

        --- the target cache class
        property "CacheClass"       { type = - ICache }

        --- the time out
        property "CacheTimeout"     { type = NaturalNumber }

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{ -ICache, NaturalNumber/nil }
        function __ctor(self, cachecls, timeout)
            self.CacheClass     = cachecls
            self.CacheTimeout   = timeout
        end
    end)
end)