--===========================================================================--
--                                                                           --
--                  System.Serialization.LuaFormatProvider                   --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2015/09/14                                               --
-- Update Date  :   2018/03/16                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Serialization"

    --- Serialization format provider for common lua data
    class "LuaFormatProvider" (function(_ENV)
        inherit "FormatProvider"

        function Serialize(self, data)
            return data
        end

        function Deserialize(self, data)
            return data
        end
    end)
end)