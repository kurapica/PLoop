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
    namespace "System"

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

    --- Represents the interface of the service provider
    __Sealed__()
    interface "IServiceProvider" (function(_ENV)
        --- Gets the service object of the specified type
        __Abstract__() __Arguments__{ AnyType }:AsInheritable()
        function GetService(self, type)
        end
    end)

    --- Represents the interface of the service collection which should return a service provider to solve the class dependency
    __Sealed__() __AnonymousClass__()
    interface "IServiceCollection" (function(_ENV)

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
        --- Add a singleton service type for the target service type
        __Arguments__{ AnyType, AnyType }
        function AddSingleton(serviceType, type)
            
        end

        --- Add a singleton service generator for the target service type
        __Arguments__{ AnyType, Callable }
        function AddSingleton(serviceType, generator)            
        end

        --- Add a singleton service object for the target service type
        __Arguments__{ AnyType, Any }:Throwable()
        function AddSingleton(serviceType, value)
        end

        --- Add a scoped service type for the target service type
        __Arguments__{ AnyType, AnyType }
        function AddScoped(serviceType, type)
        end

        --- Add a scoped service generator for the target service type
        __Arguments__{ AnyType, Callable }:Throwable()
        function AddScoped(serviceType, generator)
        end

        --- Add a transient service type for the target service type
        __Arguments__{ AnyType, AnyType }
        function AddTransient(serviceType, type)
        end

        --- Add a transient service generator for the target service type
        __Arguments__{ AnyType, Callable }:Throwable()
        function AddTransient(serviceType, generator)
        end
    end)
end)