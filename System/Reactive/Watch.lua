--===========================================================================--
--                                                                           --
--                           System.Reactive.Watch                           --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2023/04/20                                               --
-- Update Date  :   2023/04/20                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Reactive"

    --- Provide automatically subscription based on the function
    __Sealed__()
    class "Watch"                       (function(_ENV)
        extend "IEnvironment"

        export {
            getValue                    = Environment.GetValue,
            saveValue                   = Environment.SaveValue,
            isObjectType                = Class.IsObjectType,
            getObjectClass              = Class.GetObjectClass
        }

        local proxyes                   = Toolset.newtable(true, true)

        local function getValueProxy(object)
            local objcls                = getObjectClass(object)
            if not objcls or objcls == WatchProxy then return object end
            return proxyes[object] or WatchProxy(object)
        end

        -----------------------------------------------------------------------
        --                            inner Type                             --
        -----------------------------------------------------------------------
        --- The proxy used to wrap the object access
        class "WatchProxy"              (function(_ENV)
            local proxyMap              = Toolset.newtable(true)

            -------------------------------------------------------------------
            --                          constructor                          --
            -------------------------------------------------------------------
            __Arguments__{ Table }
            function __ctor(self, object)
                proxyes[object]         = self
                proxyMap[self]          = object

                local objcls            = Class.GetObjectClass(object)
                if objcls and not classInfo[objcls] then
                    local oprops        = {}

                    for name, prop in Class.GetFeatures(objcls, true) do
                        if Propety.Validate(prop) and __Observable__.IsObservableProperty(prop) then
                            oprops[name]= prop
                        end
                    end
                end
            end

            -------------------------------------------------------------------
            --                          meta method                          --
            -------------------------------------------------------------------
            function __index(self, key)
                local object            = proxyMap[self]
                local objcls            = getObjectClass(object)
                if not objcls then

                end
            end

            function __newindex(self, key, value)

            end
        end)


        -----------------------------------------------------------------------
        --                            meta method                            --
        -----------------------------------------------------------------------
        function __index(self, key)
            local value                 = getValue(self, key)
            if type(value) == "table" then
                value                   = getValueProxy(value)
                rawset(self, key, value)
            end
            return value
        end
    end)
end)