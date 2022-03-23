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
-- Version      :   1.0.0                                                    --
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
    struct "ServiceDescriptor"  (function(_ENV)
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

    --- Represents the interface of the service collection which should return a service provider to solve the class dependency
    interface "IServiceCollection" {}

    --- Represents the interface of the service provider
    __Sealed__()
    interface "IServiceProvider" (function(_ENV)
        --- Gets the service object of the specified type
        __Abstract__() __Arguments__{ AnyType }:AsInheritable()
        function GetService(self, type)

        end
    end)

    --- Represents the interface of the service scope
    __Sealed__() __AnonymousClass__()
    interface "IServiceScope" (function(_ENV)
        extend "IAutoClose" "IContext"

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        function Open(self)
        end

        function Close(self, error)
        end

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        property "ServiceProvider "     { type = IServiceProvider }
    end)

    --- Represents the interface of the service collection which should return a service provider to solve the class dependency
    __Sealed__() __AnonymousClass__()
    interface "IServiceCollection" (function(_ENV)

        export { Class, Attribute, __Arguments__ }

        export {
            getmetatable                = getmetatable,
            throw                       = throw,
        }

        field {
            _Services                   = {}
        }

        --- Add a service descriptor to the collection
        local function add(self, descriptor)
            self._Services[descriptor.serviceType] = descriptor
        end

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
        function BuildServiceProvider(self)
        end

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------

        --- Add a singleton service type
        __Arguments__{ ClassType }:Throwable()
        function AddSingleton(self, type)
            if not checkOverloads(type) then
                throw("Usage: IServiceProvider:AddSingleton(type) - the system can't figure out the arguments of the type's constructor")
            end

            return add(self,    {
                serviceType             = type,
                lifetime                = ServiceLifetime.Singleton,
                implementationType      = type,
            })
        end

        --- Add a singleton service instance
        __Arguments__{ Any }:Throwable()
        function AddSingleton(self, object)
            local serviceType           = Class.GetObjectClass(object)

            if not serviceType then
                throw("Usage: IServiceProvider:AddSingleton(object) - the object must be generated from a service type")
            end

            return add(self, {
                serviceType             = serviceType,
                lifetime                = ServiceLifetime.Singleton,
                implementationInstance  = object,
            })
        end

        __Arguments__{ InterfaceType + ClassType, ClassType }:Throwable()
        function AddSingleton(self, serviceType, type)
            if not checkOverloads(type) then
                throw("Usage: IServiceProvider:AddSingleton(type) - the system can't figure out the arguments of the type's constructor")
            end

            if not Class.IsSubType(type, serviceType) then
                throw("Usage: IServiceProvider:AddSingleton(serviceType, type) - the type must be a sub type of the service type")
            end

            return add(self, {
                serviceType             = serviceType,
                lifetime                = ServiceLifetime.Singleton,
                implementationType      = type,
            })
        end

        --- Add a singleton service generator for the target service type
        __Arguments__{ InterfaceType + ClassType + StructType, Callable }
        function AddSingleton(self, serviceType, generator)
            return add(self, {
                serviceType             = serviceType,
                lifetime                = ServiceLifetime.Singleton,
                implementationFactory   = generator,
            })
        end

        --- Add a singleton service object for the target service type
        __Arguments__{ InterfaceType + ClassType + StructType, Any }:Throwable()
        function AddSingleton(self, serviceType, value)
            if getmetatable(serviceType).ValidateValue(serviceType, value) == nil then
                throw("Usage: IServiceProvider:AddSingleton(serviceType, value) - the value must be generated from the service type")
            end

            return add(self, {
                serviceType             = serviceType,
                lifetime                = ServiceLifetime.Singleton,
                implementationInstance  = value,
            })
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

            return add(self, {
                serviceType             = serviceType,
                lifetime                = ServiceLifetime.Scoped,
                implementationType      = type,
            })
        end

        --- Add a scoped service generator for the target service type
        __Arguments__{ InterfaceType + ClassType, Callable }
        function AddScoped(self, serviceType, generator)
            return add(self, {
                serviceType             = serviceType,
                lifetime                = ServiceLifetime.Scoped,
                implementationFactory   = generator,
            })
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

            return add(self, {
                serviceType             = serviceType,
                lifetime                = ServiceLifetime.Transient,
                implementationType      = type,
            })
        end

        --- Add a transient service generator for the target service type
        __Arguments__{ InterfaceType + ClassType, Callable }
        function AddTransient(self, serviceType, generator)
            return add(self, {
                serviceType             = serviceType,
                lifetime                = ServiceLifetime.Transient,
                implementationFactory   = generator,
            })
        end
    end)
end)