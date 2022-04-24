--===========================================================================--
--                                                                           --
--                            System Scalar Type                             --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2021/12/26                                               --
-- Update Date  :   2021/12/26                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
	namespace "System"

    --- SByte
    __Sealed__() struct "SByte"         { __base = Integer, function(val, onlyvalid) return (val > 127 or val < -128) and (onlyvalid or "the %s must be an 8 bytes integer") or nil end }

    --- Byte
    __Sealed__() struct "Byte"          { __base = Integer, function(val, onlyvalid) return (val < 0 or val >= 2^8) and (onlyvalid or "the %s must be an 8 bytes unsigned integer") or nil end }

    --- Int16
    __Sealed__() struct "Int16"         { __base = Integer, function(val, onlyvalid) return (val > 32767 or val < -32768) and (onlyvalid or "the %s must be an 16 bytes integer") or nil end }

    --- UInt16
    __Sealed__() struct "UInt16"        { __base = Integer, function(val, onlyvalid) return (val < 0 or val >= 2^16) and (onlyvalid or "the %s must be an 16 bytes unsigned integer") or nil end }

    --- Int32
    __Sealed__() struct "Int32"         { __base = Integer, function(val, onlyvalid) return (val > 2147483647 or val < -2147483648) and (onlyvalid or "the %s must be an 32 bytes integer") or nil end }

    --- UInt32
    __Sealed__() struct "UInt32"        { __base = Integer, function(val, onlyvalid) return (val < 0 or val >= 2^32) and (onlyvalid or "the %s must be an 32 bytes unsigned integer") or nil end }

    --- Int64, no limit check
    __Sealed__() struct "Int64"         { __base = Integer }

    --- UInt64, no limit check
    __Sealed__() struct "UInt64"        { __base = NaturalNumber }

    --- Float, no check
    __Sealed__() struct "Float"         { __base = Number }

    --- Double, no check
    __Sealed__() struct "Double"        { __base = Number }

    --- Decimal, no check
    __Sealed__() __Arguments__{ Number, Number }
    struct "Decimal"                    (function(_ENV, integral, fractional) __base = Number end)

    --- Represents the positive number
    __Sealed__()
    struct "PositiveNumber"             { __base = Number, function(val, onlyvalid) return val <= 0 and (onlyvalid or "the %s must be a positive number") or nil end }

    --- Represents the negative number
    __Sealed__()
    struct "NegativeNumber"             { __base = Number, function(val, onlyvalid) return val >= 0 and (onlyvalid or "the %s must be a negative number") or nil end }

    --- Represents negative integer value
    __Sealed__()
    struct "NegativeInteger"            { __base = Integer, function(val, onlyvalid) return val >= 0 and (onlyvalid or "the %s must be a negative integer") or nil end }
end)