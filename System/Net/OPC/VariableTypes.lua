 --===========================================================================--
--                                                                           --
--                   System.Net.Protocol.OPC.VariableTypes                   --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2021/08/06                                               --
-- Update Date  :   2021/08/06                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Net.OPC"

    __Sealed__() __Node__{ NodeId = 62 }
    class "BaseVariableType"            { Variable }

    __Node__() __Node__{ NodeId = 68, ValueRank = -2 }
    class "PropertyType"                (function(_ENV)
        inherit "BaseVariableType"

        ---------------------------------------------------
        --                   property                    --
        ---------------------------------------------------
        --- The owner of the property
        property "Owner"                { type = Any }
    end)

    __Sealed__() __Node__{ NodeId = 63, ValueRank = -2, DataType = Any }
    class "BaseDataVariableType"        { BaseVariableType }

    __Sealed__() __Node__{ NodeId = 2138, ValueRank = -1, DataType = ServerStatusDataType }
    class "ServerStatusType"            { BaseDataVariableType }

    __Sealed__() __Abstract__() __Node__{ NodeId = 2137, ValueRank = -1, DataType = Any }
    class "ServerVendorCapabilityType"  { BaseDataVariableType }
end)