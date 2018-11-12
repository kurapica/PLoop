--===========================================================================--
--                                                                           --
--                        System.Data.DataEntityCache                        --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2018/11/08                                               --
-- Update Date  :   2018/11/08                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    --- The basic cache interface
    __Arguments__{ -System.Data.IDataEntity }
    __Sealed__() class "System.Data.DataEntityCache" (function(_ENV, clsEntity)
        extend "System.IAutoClose"

        export { "tostring", "ipairs", "tonumber", "select", List }

        local clsContext        = Namespace.GetNamespace(Namespace.GetNamespaceName(clsEntity):match("^(.*)%.[%P_]+$"))
        local CACHE_KEY         = "DataEntityCache:" .. clsEntity .. ":"

        local set               = Attribute.GetAttachedData(System.Data.__DataTable__, clsEntity)
        if not set.indexes then error("The " .. clsEntity .. " has no data table index settings") end

        local props             = {}

        for name, ftr in Class.GetFeatures(clsEntity) do
            if Property.Validate(ftr) and not Property.IsStatic(ftr) then
                local dfield    = Attribute.GetAttachedData(System.Data.__DataField__, ftr, clsEntity)
                if dfield and not dfield.foreign then
                    props[dfield.name] = name
                end
            end
        end

        local primaryflds       = {}

        for _, index in ipairs(set.indexes) do
            if index.primary then
                for _, fld in ipairs(index.fields) do
                    primaryflds[#primaryflds + 1] = { name = props[fld], type = Class.GetFeature(clsEntity, props[fld]):GetType(), require = true }
                end
                break
            end
        end

        if #primaryflds == 0 then error("The " .. clsEntity .. " has no data table primary index settings") end

        local QueryData         = struct (Toolset.clone(primaryflds, true))
        local KeyCollection     = set.collection
        props                   = nil

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- The data context
        __Abstract__() property "DataContext"   { type = clsContext, default = function(self) return clsContext() end }

        --- The cache object
        __Abstract__() property "Cache"         { type = System.Data.ICache }

        --- The time out seconds
        __Abstract__() property "Timeout"       { type = NaturalNumber }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        __Abstract__() function Open(self) self.Cache:Open() end
        __Abstract__() function Close(self, error) self.Cache:Close() end

        if #primaryflds == 1 then
            local QueryKey      = primaryflds[1].name

            --- Get the entity object with the index key
            __Arguments__{ primaryflds[1].type }
            function GetEntity(self, id)
                local key       = CACHE_KEY .. tostring(id)
                local entity    = self.Cache:Get(key)

                if entity == nil then
                    with(self.DataContext)(function(ctx)
                        entity  = ctx[KeyCollection]:Query{ [QueryKey] = id }:First()

                        if entity then
                            self.Cache:Set(key, entity, self.Timeout)
                        end
                    end)
                end

                return entity
            end

            __Arguments__{ QueryData }
            function GetEntity(self, query)
                local key       = CACHE_KEY .. tostring(query[QueryKey])
                local entity    = self.Cache:Get(key)

                if entity == nil then
                    with(self.DataContext)(function(ctx)
                        entity  = ctx[KeyCollection]:Query(query):First()

                        if entity then
                            self.Cache:Set(key, entity, self.Timeout)
                        end
                    end)
                end

                return entity
            end

            --- Set the entity to the cache
            __Arguments__{ clsEntity }
            function SaveEntity(self, entity)
                local key       = CACHE_KEY .. tostring(entity[QueryKey])
                self.Cache:Set(key, entity, self.Timeout)
            end

            --- Delete the entity from the cache
            __Arguments__{ clsEntity }
            function DeleteEntity(self, entity)
                local key       = CACHE_KEY .. tostring(entity[QueryKey])
                self.Cache:Delete(key)
            end
        else
            local pattern       = List(#primaryflds)
            local args          = {}
            for i, v in ipairs(primaryflds) do args[i] = v.type end

            --- Get the entity object with the index key
            __Arguments__(args) arg = nil
            function GetEntity(self, ...)
                local id        = List(...):Map(tostring):Join("^")

                local key       = CACHE_KEY .. id
                local entity    = self.Cache:Get(key)

                if entity == nil then
                    local query = {}
                    for i, v in ipairs(primaryflds) do query[v.name] = select(i, ...) end

                    with(self.DataContext)(function(ctx)
                        entity  = ctx[KeyCollection]:Query(query):First()

                        if entity then
                            self.Cache:Set(key, entity, self.Timeout)
                        end
                    end)
                end

                return entity
            end

            __Arguments__{ QueryData }
            function GetEntity(self, query)
                local id        = pattern:Map(function(v) return tostring(query[primaryflds[v].name]) end):Join("^")

                local key       = CACHE_KEY .. id
                local entity    = self.Cache:Get(key)

                if entity == nil then
                    with(self.DataContext)(function(ctx)
                        entity  = ctx[KeyCollection]:Query(query):First()

                        if entity then
                            self.Cache:Set(key, entity, self.Timeout)
                        end
                    end)
                end

                return entity
            end

            --- Set the entity to the cache
            __Arguments__{ clsEntity }
            function SaveEntity(self, entity)
                local id        = pattern:Map(function(v) return tostring(query[primaryflds[v].name]) end):Join("^")
                local key       = CACHE_KEY .. id
                self.Cache:Set(key, entity, self.Timeout)
            end

            --- Delete the entity from the cache
            __Arguments__{ clsEntity }
            function DeleteEntity(self, entity)
                local id        = pattern:Map(function(v) return tostring(query[primaryflds[v].name]) end):Join("^")
                local key       = CACHE_KEY .. id
                self.Cache:Delete(key)
            end
        end
    end)
end)