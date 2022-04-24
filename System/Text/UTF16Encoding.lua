--===========================================================================--
--                                                                           --
--                         System.Text.UTF16Encoding                         --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2015/06/24                                               --
-- Update Date  :   2018/03/16                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Text"

    -----------------------------------------------------------------------
    --                              prepare                              --
    -----------------------------------------------------------------------
    export {
        strbyte                         = string.byte,
        strchar                         = string.char,
        tinsert                         = table.insert,
        tconcat                         = table.concat,
        floor                           = math.floor,
        LUA_VERSION                     = tonumber(_G._VERSION:match("[%d%.]+")) or 5.1,
        loadsnippet                     = Toolset.loadsnippet,
        error                           = error,

        band                            = Toolset.band,
        lshift                          = Toolset.lshift,
        rshift                          = Toolset.rshift,

        -- Declare here
        decodeLE                        = false,
        encodeLE                        = false,
        decodeBE                        = false,
        encodeBE                        = false,
    }

    function decodeLE(str, startp)
        startp                          = startp or 1

        local sbyte, obyte              = strbyte(str, startp, startp + 1)
        if not obyte or not sbyte then return nil end

        if obyte <= 0xD7 or obyte >= 0xE0 then
            -- two bytes
            return lshift(obyte, 8) + sbyte, 2
        elseif obyte >= 0xD8 and obyte <= 0xDB then
            -- four byte
            local fbyte, tbyte          = strbyte(str, startp + 2, startp + 3)
            if not tbyte or not fbyte then return nil end

            if tbyte >= 0xDC and tbyte <= 0xDF then
                return lshift((lshift((obyte - 0xD8), 8) + sbyte), 10) + (lshift((tbyte - 0xDC), 8) + fbyte) + 0x10000, 4
            else
                return nil
            end
        else
            return nil
        end
    end

    function encodeLE(code)
        if code >= 0 then
            -- 2
            if code <= 0xD7FF or (code >= 0xE000 and code <= 0xFFFF) then
                return strchar(
                    band(code, 0xff),
                    rshift(code, 8)
                )
            end

            -- 4 surrogate pairs
            if code >= 0x10000 and code <= 0x10FFFF then
                code                    = code - 0x10000
                local high              = rshift(code, 10)
                local low               = band(code, 0x3ff)
                return strchar(
                    band(high, 0xff),
                    0xD8 + rshift(high, 8),
                    band(low, 0xff),
                    0xDC + rshift(low, 8)
                )
            end
        end

        error(("%s is not a valid unicode."):format(code), 2)
    end

    function decodeBE(str, startp)
        startp                          = startp or 1

        local obyte, sbyte              = strbyte(str, startp, startp + 1)
        if not obyte or not sbyte then return nil end

        if obyte <= 0xD7 or obyte >= 0xE0 then
            -- two bytes
            return lshift(obyte, 8) + sbyte, 2
        elseif obyte >= 0xD8 and obyte <= 0xDB then
            -- four byte
            local tbyte, fbyte          = strbyte(str, startp + 2, startp + 3)
            if not tbyte or not fbyte then return nil end

            if tbyte >= 0xDC and tbyte <= 0xDF then
                return lshift((lshift((obyte - 0xD8), 8) + sbyte), 10) + (lshift((tbyte - 0xDC), 8) + fbyte) + 0x10000, 4
            else
                return nil
            end
        else
            return nil
        end
    end

    function encodeBE(code)
        if code >= 0 then
            -- 2
            if code <= 0xD7FF or (code >= 0xE000 and code <= 0xFFFF) then
                return strchar(
                    rshift(code, 8),
                    band(code, 0xff)
                )
            end

            -- 4 surrogate pairs
            if code >= 0x10000 and code <= 0x10FFFF then
                code                    = code - 0x10000
                local high              = rshift(code, 10)
                local low               = band(code, 0x3ff)
                return strchar(
                    0xD8 + rshift(high, 8),
                    band(high, 0xff),
                    0xDC + rshift(low, 8),
                    band(low, 0xff)
                )
            end
        end

        error(("%s is not a valid unicode."):format(code), 2)
    end

   --- Represents the utf-16 encoding with little-endian.
    System.Text.Encoding "UTF16EncodingLE" {
        encode                          = encodeLE,
        decode                          = decodeLE,
    }

   --- Represents the utf-16 encoding with big-endian.
    System.Text.Encoding "UTF16EncodingBE" {
        encode                          = encodeBE,
        decode                          = decodeBE,
    }
end)
