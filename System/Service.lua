--===========================================================================--
--                                                                           --
--                      Service & Dependency Injection                       --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2022/03/11                                               --
-- Update Date  :   2022/03/16                                               --
-- Version      :   0.9.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    -- Only enable the DependencyInjection when enable the ENABLE_ARGUMENTS_ATTACHMENT
    if not Platform.ENABLE_ARGUMENTS_ATTACHMENT then return end

    namespace "System.DependencyInjection"

    -----------------------------------------------------------------------
    --                                     --
    -----------------------------------------------------------------------
    --- The lifetime of the service
    __Sealed__()
    enum "ServiceLifetime"              {
        Singleton                       = 0, -- Specifies that a single instance of the service will be created
        Scoped                          = 1, -- Specifies that a new instance of the service will be created for each scope
        Transient                       = 2, -- Specifies that a new instance of the service will be created every time it is requested
    }

    --- Describes a service with its service type, implementation, and lifetime
    __Sealed__()
    struct "ServiceDescriptor"          (function(_ENV)

        -- The service type
        member "serviceType"            { type = InterfaceType + ClassType + StructType, require = true }

        -- The lifetime of the service
        member "lifetime"               { type = ServiceLifetime, require = true }

        -- The implementation factory to generate the instances
        member "implementationFactory"  { type = Callable }

        -- The singleton instance of the service
        member "implementationInstance" { type = Any }

        -- The service type used to generate the instances
        member "implementationType"     { type = ClassType }

        -- the validation
        function __valid(value, onlyvalid)
            if value.implementationFactory  == nil and
                value.implementationInstance== nil and
                value.implementationType    == nil then
                return onlyvalid or "The %s's implementation must be provided"
            end
        end
    end)

    --- Represents the interface of the service provider
    __Sealed__()
    interface "IServiceProvider"        (function(_ENV)
        extend "IAutoClose"

        -----------------------------------------------------------
        --                    abstract method                    --
        -----------------------------------------------------------
        --- Gets the service object of the specified type
        __Abstract__()
        function GetService(self, type) end

        --- Create a new service scope
        __Abstract__()
        function CreateScope(self)      end
    end)

    --- Represents the interface of the service scope
    __Sealed__()
    interface "IServiceScope"           (function(_ENV)
        extend "IAutoClose"

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        __Abstract__()
        property "ServiceProvider "     { type = IServiceProvider }
    end)

    --- Represents the interface of the service collection which should return a service provider to solve the class dependency
    __Sealed__()
    interface "IServiceCollection"      (function(_ENV)

        export                          {
            getmetatable                = getmetatable,
            throw                       = throw,

            Class, Attribute, __Arguments__
        }


        local function checkOverloads(classType)
            for k, v in __Arguments__.GetOverloads(classType, "__ctor") do
                if Attribute.HasAttachedData(__Arguments__, v, classType) then
                    return true
                end
            end

            return false
        end

        -----------------------------------------------------------
        --                    abstract method                    --
        -----------------------------------------------------------
        --- Generate the service provider
        __Abstract__() __Return__{ IServiceProvider }:AsInheritable()
        function BuildServiceProvider(self) end

        --- Add the descriptor to the collection
        __Abstract__() __Arguments__{ ServiceDescriptor }:AsInheritable()
        function Add(self, descriptor)  end

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- Add a singleton service type
        __Arguments__{ ClassType }:Throwable()
        function AddSingleton(self, type)
            if not checkOverloads(type) then
                throw("Usage: IServiceProvider:AddSingleton(type) - the system can't figure out the arguments of the type's constructor")
            end

            return self:Add{
                serviceType             = type,
                lifetime                = ServiceLifetime.Singleton,
                implementationType      = type,
            }
        end

        --- Add a singleton service instance
        __Arguments__{ Any }:Throwable()
        function AddSingleton(self, object)
            local serviceType           = Class.GetObjectClass(object)

            if not serviceType then
                throw("Usage: IServiceProvider:AddSingleton(object) - the object must be generated from a service type")
            end

            return self:Add{
                serviceType             = serviceType,
                lifetime                = ServiceLifetime.Singleton,
                implementationInstance  = object,
            }
        end

        __Arguments__{ InterfaceType + ClassType, ClassType }:Throwable()
        function AddSingleton(self, serviceType, type)
            if not checkOverloads(type) then
                throw("Usage: IServiceProvider:AddSingleton(type) - the system can't figure out the arguments of the type's constructor")
            end

            if not Class.IsSubType(type, serviceType) then
                throw("Usage: IServiceProvider:AddSingleton(serviceType, type) - the type must be a sub type of the service type")
            end

            return self:Add{
                serviceType             = serviceType,
                lifetime                = ServiceLifetime.Singleton,
                implementationType      = type,
            }
        end

        --- Add a singleton service generator for the target service type
        __Arguments__{ InterfaceType + ClassType + StructType, Callable }
        function AddSingleton(self, serviceType, generator)
            return self:Add{
                serviceType             = serviceType,
                lifetime                = ServiceLifetime.Singleton,
                implementationFactory   = generator,
            }
        end

        --- Add a singleton service object for the target service type
        __Arguments__{ InterfaceType + ClassType + StructType, Any }:Throwable()
        function AddSingleton(self, serviceType, value)
            if getmetatable(serviceType).ValidateValue(serviceType, value) == nil then
                throw("Usage: IServiceProvider:AddSingleton(serviceType, value) - the value must match the service type")
            end

            return self:Add{
                serviceType             = serviceType,
                lifetime                = ServiceLifetime.Singleton,
                implementationInstance  = value,
            }
        end

        --- Add a scoped service type for the target service type
        __Arguments__{ InterfaceType + ClassType, ClassType }:Throwable()
        function AddScoped(self, serviceType, type)
            if not checkOverloads(type) then
                throw("Usage: IServiceProvider:AddScoped(type) - the system can't figure out the arguments of the type's constructor")
            end

            if not Class.IsSubType(type, serviceType) then
                throw("Usage: IServiceProvider:AddScoped(serviceType, type) - the type must be a sub type of the service type")
            end

            return self:Add{
                serviceType             = serviceType,
                lifetime                = ServiceLifetime.Scoped,
                implementationType      = type,
            }
        end

        --- Add a scoped service generator for the target service type
        __Arguments__{ InterfaceType + ClassType, Callable }
        function AddScoped(self, serviceType, generator)
            return self:Add{
                serviceType             = serviceType,
                lifetime                = ServiceLifetime.Scoped,
                implementationFactory   = generator,
            }
        end

        --- Add a transient service type for the target service type
        __Arguments__{ InterfaceType + ClassType, ClassType }:Throwable()
        function AddTransient(self, serviceType, type)
            if not checkOverloads(type) then
                throw("Usage: IServiceProvider:AddTransient(type) - the system can't figure out the arguments of the type's constructor")
            end

            if not Class.IsSubType(type, serviceType) then
                throw("Usage: IServiceProvider:AddTransient(serviceType, type) - the type must be a sub type of the service type")
            end

            return self:Add{
                serviceType             = serviceType,
                lifetime                = ServiceLifetime.Transient,
                implementationType      = type,
            }
        end

        --- Add a transient service generator for the target service type
        __Arguments__{ InterfaceType + ClassType, Callable }
        function AddTransient(self, serviceType, generator)
            return self:Add{
                serviceType             = serviceType,
                lifetime                = ServiceLifetime.Transient,
                implementationFactory   = generator,
            }
        end
    end)

    ---------------------------------------------------------------
    -- Implementation
    ---------------------------------------------------------------
    -- Declare first
    class "ServiceCollection"           {}
    class "ServiceProvider"             {}

    --- The default service scope
    __Sealed__()
    class "ServiceScope"                (function(_ENV)
        extend "IServiceScope"

        export                          {
            ServiceProvider
        }

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- The root service provider
        property "RootServiceProvider"  { type = IServiceProvider }

        --- The service provider
        property "ServiceProvider"      { set  = false, default = function(self) return ServiceProvider(self) end }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        function Close(self)
            self.ServiceProvider:Close()
        end

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{ ServiceProvider }
        function __ctor(self, serviceProvider)
            self.RootServiceProvider    = serviceProvider
        end
    end)

    --- The default service provider
    __Sealed__()
    class "ServiceProvider"             (function(_ENV)
        extend "IServiceProvider" "IAutoClose"

        export                          {
            ipairs                      = ipairs,
            unpack                      = _G.unpack or table.unpack,
            tinsert                     = table.insert,
            tremove                     = table.remove,
            pcall                       = pcall,

            Class, Struct, Interface, IAutoClose, __Arguments__, Attribute, List,
            ServiceLifetime, ServiceScope, IServiceProvider
        }

        field                           {
            __Descriptors               = {},
            __Instances                 = {}
        }

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- The service scope
        property "Scope"                { type = ServiceScope }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- Gets the service object of the specified type
        function GetService(self, type)
            local descMap               = self.__Descriptors
            local instances             = self.__Instances

            local descriptor            = descMap and descMap[type]
            if not descriptor then return end

            local instance              = descriptor.implementationInstance
            if instance then return instance end

            if Struct.Validate(type) then
                -- Only instance or factory allowed for the struct type
                return descriptor.implementationFactory()
            end

            -- Check generated instances
            instance                    = instances[type]
            if instance then return instance end

            -- Generate the instance from factory
            if descriptor.implementationFactory then
                instance                = descriptor.implementationFactory()
            else
                -- Check implementation type
                local impType           = descriptor.implementationType
                if not impType then return end

                -- Check how to create the instance
                for _, overload in __Arguments__.GetOverloads(impType, "__ctor") do
                    local args          = Attribute.GetAttachedData(__Arguments__, overload, impType)

                    if args then
                        if #args == 0 then
                            instance    = impType()
                            break
                        else
                            local full  = true
                            local cnt   = #args

                            for i = 1, #args do
                                local a = args[i]
                                local b = a.type and self:GetService(a.type) or a.default
                                if b ~= nil or a.optional then
                                    args[i] = b
                                else
                                    full= false
                                    break
                                end
                            end

                            if full then
                                instance= impType(unpack(args, 1, cnt))
                                break
                            end
                        end
                    end
                end
            end

            -- Check the lifetime
            if instance then
                if descriptor.lifetime == ServiceLifetime.Singleton then
                    descriptor.implementationInstance = instance
                elseif descriptor.lifetime == ServiceLifetime.Scoped then
                    instances[type]     = instance
                end
            end

            return instance
        end

        --- Create a new service scope
        function CreateScope(self)
            return ServiceScope(self)
        end

        --- Close the service provider
        function Close(self)
            for type, descriptor in pairs(self.__Descriptors) do
                while descriptor do
                    local instance      = descriptor.implementationInstance

                    if instance and Class.IsSubType(Class.GetObjectClass(instance), IAutoClose) then
                        local ok, msg   = pcall(instance.Close, instance)

                    end

                    descriptor          = descriptor.prev
                end
            end
        end

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        --- Construct the root service provider
        __Arguments__{ ServiceCollection }
        function __ctor(self, collection)
            local descMap               = self.__Descriptors

            for i, descriptor in ipairs(collection.Descriptors) do
                if descMap[descriptor.serviceType] then
                    descriptor.prev     = descMap[descriptor.serviceType]
                end
                descMap[descriptor.serviceType] = descriptor
            end

            -- Register self
            descMap[IServiceProvider]   = {
                serviceType             = IServiceProvider,
                lifetime                = ServiceLifetime.Singleton,
                implementationInstance  = self,
            }
        end

        --- Construct the scope service provider
        __Arguments__{ ServiceScope }
        function __ctor(self, scope)
            self.ServiceScope           = scope
            self.__Descriptors          = scope.RootServiceProvider.__Descriptors
        end
    end)

    --- The default service collection
    __Sealed__()
    class "ServiceCollection"           (function(_ENV)
        extend "IServiceCollection"

        export                          {
            tinsert                     = table.insert,

            ServiceProvider, List
        }

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- The service descriptors
        property "Descriptors"          { type = List[ServiceDescriptor], default = function() return List[ServiceDescriptor]() end }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- Generate the service provider
        function BuildServiceProvider(self)
            local provider              = ServiceProvider(self)
            self.Descriptors            = nil
            return provider
        end

        --- Add the descriptor to the collection
        function Add(self, descriptor)
            self.Descriptors:Insert(descriptor)
        end
    end)
end)