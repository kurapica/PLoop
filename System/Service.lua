--===========================================================================--
--                                                                           --
--                      Service & Dependency Injection                       --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2022/03/11                                               --
-- Update Date  :   2022/03/11                                               --
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
    __Sealed__()
    interface "IServiceCollection" (function(_ENV)
        extend "Iterable"

        __Abstract__() __Return__{ IServiceProvider }:AsInheritable()
        function BuildServiceProvider(self)
        end
    end)
end)