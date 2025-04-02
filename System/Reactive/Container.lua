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
        safeset                         = Toolset.safeset,
        getreactivetype                 = System.Reactive.GetReactiveType,
        issubtype                       = Class.IsSubType,
        isobjecttype                    = Class.IsObjectType,
        safesetvalue                    = Toolset.safesetvalue,

        Reactive, ReactiveValue, IReactive, IObservable
    }

    local containerMap                  = {}

    --- The container prototype
    container                           = Prototype (ValidateType, {
        __index                         = {
            ["IsImmutable"]             = function() return true, true end;
            ["ValidateValue"]           = function(_, value) return getmetatable(value) == container and value ~= container and value end;
            ["Validate"]                = function(value)    return getmetatable(value) == container and value ~= container and value end;
        },
        __newindex                      = Toolset.readonly,
        __call                          = function(self, name)
            if type(name) == "string" then
                if not name:find(".", 1, true)  then name = "System.Reactive.Container." .. name end
                if Namespace.GetNamespace(name) then error("Usage: System.Reactive.Container \"name\" - the name already used", 2) end

                local object            = Prototype.NewObject(gcontainer)
                containerMap            = safeset(containerMap, object, {})
                return Namespace.SaveNamespace(name, object)
            elseif type(name) == "table" then
                local object            = Prototype.NewObject(tcontainer)
                rawset(object, container, {})
                return object(name)
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
            return (rawget(self, container) or containerMap[self])[key]
        end,
        __newindex                      = function(self, key, value, stack)
            if type(key) ~= "string" then error("The field can only be string", (stack or 1) + 1) end
            local raw                   = rawget(self, container) or containerMap[self]
            local react                 = raw[key]
            if react then
                if isobjecttype(react, IReactive) then
                    local ok, err       = safesetvalue(react, "Value", value)
                    if not ok then error(err:gsub("Value", key), (stack or 1) + 1) end
                else
                    error("The " .. key .. " is readonly", (stack or 1) + 1)
                end
            else
                rawset(raw, key, isobjecttype(value, IObservable) and value or reactive(value))
            end
        end,
        __call                          = function(self, init)
            if type(init) == "table" then
                for k, v in pairs(init) do
                    if type(k) == "string" then
                        local ok, err   = safesetvalue(self, k, v)
                        if not ok then error(err, 2) end
                    end
                end
            end
            return self
        end,
    }

    --- The global observable container can be used to store reactive values
    gcontainer                          = Prototype (tcontainer, {
        __metatable                     = container,
        __tostring                      = Namespace.GetNamespaceName
    })

    -- Save to the namespace
    Namespace.SaveNamespace("System.Reactive.Container", container)
end)