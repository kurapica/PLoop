--===========================================================================--
--                                                                           --
--                         System.Reactive.Container                         --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2025/04/01                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    -----------------------------------------------------------------------
    --                    Global Observable Container                    --
    --                                                                   --
    -- Declare observable containers as namespaces to be used everywhere --
    -----------------------------------------------------------------------
    export                              {
        getmetatable                    = getmetatable,
        type                            = type,
        pcall                           = pcall,
        error                           = error,
        rawset                          = rawset,
        rawget                          = rawget,
        pairs                           = pairs,
        getfenv                         = _G.getfenv and _G.getfenv or _G.debug and _G.debug.getfenv or Toolset.fakefunc,
        safeset                         = Toolset.safeset,
        getreactivetype                 = System.Reactive.GetReactiveType,
        issubtype                       = Class.IsSubType,
        isobjecttype                    = Class.IsObjectType,
        safesetvalue                    = Toolset.safesetvalue,
        getkeywordvisitor               = Environment.GetKeywordVisitor,
        getenvnamespace                 = Environment.GetNamespace,
        getnamespace                    = Namespace.GetNamespace,
        getnamespacename                = Namespace.GetNamespaceName,
        isanonymousnamespace            = Namespace.IsAnonymousNamespace,

        ATTRTAR_FUNCTION                = AttributeTargets.Function,

        Reactive, ReactiveValue, IReactive, IObservable, Attribute
    }

    local containerMap                  = {}

    local initContainer                 = function(self, init)
        local map                       = containerMap[self] or self[container]

        if type(init) == "table" then
            for k, v in pairs(init) do
                -- init value
                if type(k) == "string" then
                    local ok, err       = safesetvalue(self, k, v)
                    if not ok then error("The " .. k .. "'s value is not supported", 2) end

                -- reactive factory
                elseif type(k) == "number" and type(v) == "function" then
                    map[0]              = v
                end
            end
        end
        return self
    end

    --- The container prototype
    container                           = Prototype (ValidateType, {
        __index                         = {
            ["IsImmutable"]             = function() return true, true end;
            ["ValidateValue"]           = function(_, value) return getmetatable(value) == container and value ~= container and value end;
            ["Validate"]                = function(value)    return getmetatable(value) == container and value ~= container and value end;
        },
        __newindex                      = Toolset.readonly,
        __call                          = function(self, name)
            local visitor               = getkeywordvisitor(container) or getfenv(2)

            if type(name) == "string" then
                if not name:find(".", 1, true)  then
                    local ns            = visitor and getenvnamespace(visitor)
                    if ns and not isanonymousnamespace(ns) then
                        name            = getnamespacename(ns) .. "." .. name
                    else
                        name            = "System.Reactive.Container." .. name
                    end
                end
                if getnamespace(name) then error("The " .. name .. " already used", 2) end

                local object            = Prototype.NewProxy(gcontainer)
                containerMap            = safeset(containerMap, object, {})
                Namespace.SaveNamespace(name, object)

                local last              = getnamespacename(object, true)
                if visitor and rawget(visitor, last) == nil then
                    rawset(visitor, last, object)
                end
                return function(init) return initContainer(object, init) end

            -- private container with init
            elseif type(name) == "table" then
                local object            = Prototype.NewObject(tcontainer)
                rawset(object, container, {})
                return initContainer(object, name)

            -- private container
            else
                local object            = Prototype.NewObject(tcontainer)
                rawset(object, container, {})
                return object
            end
        end,
        __tostring                      = Namespace.GetNamespaceName,
    })

    --- The private observable container can be used to store reactive values
    tcontainer                          = Prototype {
        __metatable                     = container,
        __index                         = function(self, key)
            local map                   = containerMap[self] or self[container]
            local ret                   = map[key]
            if ret ~= nil or not map[0] then return ret end

            ret                         = map[0](key)
            if ret ==  nil then return end

            -- cache
            if type(key) == "string" and isobjecttype(ret, IObservable) then
                rawset(map, key, ret)
            end
            return ret
        end,
        __newindex                      = function(self, key, value, stack)
            if type(key) ~= "string" then error("The field can only be string", (stack or 1) + 1) end
            local map                   = containerMap[self] or self[container]
            local react                 = map[key]
            if react then
                if isobjecttype(react, IReactive) then
                    local ok, err       = safesetvalue(react, "Value", value)
                    if not ok then error(err:gsub("Value", key), (stack or 1) + 1) end
                else
                    error("The " .. key .. " is readonly", (stack or 1) + 1)
                end

            elseif type(value) == "function" then
                if Attribute.HaveRegisteredAttributes() then
                    Attribute.SaveAttributes(value, ATTRTAR_FUNCTION, stack)
                    local final = Attribute.InitDefinition(value, ATTRTAR_FUNCTION, value, self, key, stack)
                    if final ~= value then
                        Attribute.ToggleTarget(value, final)
                        value   = final
                    end
                    Attribute.ApplyAttributes (value, ATTRTAR_FUNCTION, nil, self, key, stack)
                    Attribute.AttachAttributes(value, ATTRTAR_FUNCTION, self, key, stack)
                end
                rawset(map, key, value)

            elseif isobjecttype(value, IObservable) then
                rawset(map, key, value)

            else
                react                   = reactive(value, true)
                if not react then error("The " .. key .. "'s value is not supported", (stack or 1) + 1) end
                rawset(map, key, react)
            end
        end,
    }

    --- The global observable container can be used to store reactive values
    gcontainer                          = Prototype (tcontainer, {
        __metatable                     = container,
        __tostring                      = Namespace.GetNamespaceName
    })

    -- Save to the namespace
    Namespace.SaveNamespace("System.Reactive.Container", container)

    -- Add a keyword for any Lua version
    Environment.RegisterGlobalKeyword({ reactive_container = container })
end)