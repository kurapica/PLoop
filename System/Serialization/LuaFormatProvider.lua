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

        export { "type", "pairs", Serialization }

        local function removeObjType(data, fld)
            data[fld]           = nil
            for k, v in pairs(data) do
                if type(v) == "table" then
                    removeObjType(data, fld)
                end
            end
        end

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- Whether ignore the object's type for serialization
        property "ObjectTypeIgnored" { type = Boolean, default = false }

        -----------------------------------------------------------------------
        --                              Method                               --
        -----------------------------------------------------------------------
        function Serialize(self, data)
            if self.ObjectTypeIgnored and type(data) == "table" then
                removeObjType(data, Serialization.ObjectTypeField)
            end
            return data
        end

        function Deserialize(self, data)
            return data
        end
    end)
end)