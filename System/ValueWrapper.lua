--===========================================================================--
--                                                                           --
--                           System Value Wrapper                            --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2024/05/22                                               --
-- Update Date  :   2024/05/22                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
	--- Represents the value wrappers that share the same meta-methods so they can be used together
	__Sealed__()
	interface "System.IValueWrapper" 	(function(_ENV)

        export {
            isobjecttype                = Class.IsObjectType,
            getvalue                    = function(self)
                if isobjecttype(self, IValueWrapper) then
                    return self.Value
                else
                    return self
                end
            end,

            IValueWrapper
        }

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- The wrapped value
        __Abstract__()
        property "Value" 				{ type = Any }

        -----------------------------------------------------------------------
        --                            meta-method                            --
        -----------------------------------------------------------------------
        function __tostring(self)       return tostring(self.Value) end

        -- the addition operation
        function __add(a, b)            return getvalue(a) + getvalue(b) end

        -- the subtraction operation
        function __sub(a, b)            return getvalue(a) - getvalue(b) end

        -- the multiplication operation
        function __mul(a, b)            return getvalue(a) * getvalue(b) end

        -- the division operation
        function __div(a, b)            return getvalue(a) / getvalue(b) end

        -- the modulo operation
        function __mod(a, b)            return getvalue(a) % getvalue(b) end

        -- the exponentiation operation
        function __pow(a, b)            return getvalue(a) ^ getvalue(b) end

        -- the negation operation
        function __unm(a)               return -getvalue(a) end

        -- the concatenation operation
        function __concat(a, b)         return getvalue(a) .. getvalue(b) end

        -- the length operation, those won't works in 5.1
        function __len(a)               return #getvalue(a) end

        -- the equal operation
        function __eq(a, b)             return getvalue(a) == getvalue(b) end

        -- the less than operation
        function __lt(a, b)             return getvalue(a) < getvalue(b) end

        -- the less equal operation
        function __le(a, b)             return getvalue(a) <= getvalue(b) end

        if _G._VERSION and tonumber(_G._VERSION:match("[%d%.]+$")) * 10 >= 53 then
            Toolset.loadsnippet([[
                -- the floor division operation
                function __idiv(a, b)           return getvalue(a) // getvalue(b) end

                -- the bitwise AND operation
                function __band(a, b)           return getvalue(a) & getvalue(b) end

                -- the bitwise OR operation
                function __bor(a, b)            return getvalue(a) | getvalue(b) end

                -- the bitwise exclusive OR operation
                function __bxor(a, b)           return getvalue(a) ~ getvalue(b) end

                -- the bitwise NOToperation
                function __bnot(a)              return ~getvalue(a) end

                -- the bitwise left shift operation
                function __shl(a, b)            return getvalue(a) << getvalue(b) end

                -- the bitwise right shift operation
                function __shr(a, b)            return getvalue(a) >> getvalue(b) end
            ]], "IValueWrapper_Patch_53", _ENV)()
        end
	end)
end)