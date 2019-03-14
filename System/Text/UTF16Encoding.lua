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
        strbyte                 = string.byte,
        strchar                 = string.char,
        tinsert                 = table.insert,
        tconcat                 = table.concat,
        floor                   = math.floor,
        LUA_VERSION             = tonumber(_G._VERSION:match("[%d%.]+")) or 5.1,
        loadsnippet             = Toolset.loadsnippet,
        error                   = error,

        -- Declare here
        decodeLE                = false,
        encodeLE                = false,
        decodeBE                = false,
        encodeBE                = false,
    }

    -- Default
    function decodeLE(str, startp)
        startp                  = startp or 1

        local sbyte, obyte      = strbyte(str, startp, startp + 1)
        if not obyte or not sbyte then return nil end

        if obyte <= 0xD7 or obyte >= 0xE0 then
            -- two bytes
            return obyte * 0x100 + sbyte, 2
        elseif obyte >= 0xD8 and obyte <= 0xDB then
            -- four byte
            local fbyte, tbyte  = strbyte(str, startp + 2, startp + 3)
            if not tbyte or not fbyte then return nil end

            if tbyte >= 0xDC and tbyte <= 0xDF then
                return ((obyte - 0xD8) * 0x100 + sbyte) * 0x400 + ((tbyte - 0xDC) * 0x100 + fbyte) + 0x10000, 4
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
                    code % 0x100,
                    floor(code / 0x100)
                )
            end

            -- 4 surrogate pairs
            if code >= 0x10000 and code <= 0x10FFFF then
                code            = code - 0x10000
                local high      = floor(code / 0x400)
                local low       = code % 0x400
                return strchar(
                    high % 0x100,
                    0xD8 + floor(high / 0x100),
                    low % 0x100,
                    0xDC + floor(low / 0x100)
                )
            end
        end

        error(("%s is not a valid unicode."):format(code), 2)
    end

    function decodeBE(str, startp)
        startp                  = startp or 1

        local obyte, sbyte      = strbyte(str, startp, startp + 1)
        if not obyte or not sbyte then return nil end

        if obyte <= 0xD7 or obyte >= 0xE0 then
            -- two bytes
            return obyte * 0x100 + sbyte, 2
        elseif obyte >= 0xD8 and obyte <= 0xDB then
            -- four byte
            local tbyte, fbyte  = strbyte(str, startp + 2, startp + 3)
            if not tbyte or not fbyte then return nil end

            if tbyte >= 0xDC and tbyte <= 0xDF then
                return ((obyte - 0xD8) * 0x100 + sbyte) * 0x400 + ((tbyte - 0xDC) * 0x100 + fbyte) + 0x10000, 4
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
                    floor(code / 0x100),
                    code % 0x100
                )
            end

            -- 4 surrogate pairs
            if code >= 0x10000 and code <= 0x10FFFF then
                code            = code - 0x10000
                local high      = floor(code / 0x400)
                local low       = code % 0x400
                return strchar(
                    0xD8 + floor(high / 0x100),
                    high % 0x100,
                    0xDC + floor(low / 0x100),
                    low % 0x100
                )
            end
        end

        error(("%s is not a valid unicode."):format(code), 2)
    end

    -- Lua 5.3 - bitwise oper
    if LUA_VERSION >= 5.3 then
        -- Use load since 5.1 & 5.2 can't read the bitwise oper
        decodeLE, encodeLE, decodeBE, encodeBE = loadsnippet([[
            return function (str, startp)
                startp              = startp or 1

                local sbyte, obyte  = strbyte(str, startp, startp + 1)
                if not obyte or not sbyte then return nil end

                if obyte <= 0xD7 or obyte >= 0xE0 then
                    -- two bytes
                    return (obyte << 8) + sbyte, 2
                elseif obyte >= 0xD8 and obyte <= 0xDB then
                    -- four byte
                    local fbyte, tbyte = strbyte(str, startp + 2, startp + 3)
                    if not tbyte or not fbyte then return nil end

                    if tbyte >= 0xDC and tbyte <= 0xDF then
                        return ((((obyte - 0xD8) << 8) + sbyte) << 10) + (((tbyte - 0xDC) << 8) + fbyte) + 0x10000, 4
                    else
                        return nil
                    end
                else
                    return nil
                end
            end,

            function (code)
                if code >= 0 then
                    -- 2
                    if code <= 0xD7FF or (code >= 0xE000 and code <= 0xFFFF) then
                        return strchar(
                            code & 0xff,
                            code >> 8
                        )
                    end

                    -- 4 surrogate pairs
                    if code >= 0x10000 and code <= 0x10FFFF then
                        code        = code - 0x10000
                        local high  = code >> 10
                        local low   = code & 0x3ff
                        return strchar(
                            high & 0xff,
                            0xD8 + high >> 8,
                            low & 0xff,
                            0xDC + low >> 8
                        )
                    end
                end

                error(("%s is not a valid unicode."):format(code), 2)
            end,

            function (str, startp)
                startp              = startp or 1

                local obyte, sbyte  = strbyte(str, startp, startp + 1)
                if not obyte or not sbyte then return nil end

                if obyte <= 0xD7 or obyte >= 0xE0 then
                    -- two bytes
                    return (obyte << 8) + sbyte, 2
                elseif obyte >= 0xD8 and obyte <= 0xDB then
                    -- four byte
                    local tbyte, fbyte = strbyte(str, startp + 2, startp + 3)
                    if not tbyte or not fbyte then return nil end

                    if tbyte >= 0xDC and tbyte <= 0xDF then
                        return ((((obyte - 0xD8) << 8) + sbyte) << 10) + (((tbyte - 0xDC) << 8) + fbyte) + 0x10000, 4
                    else
                        return nil
                    end
                else
                    return nil
                end
            end,

            function (code)
                if code >= 0 then
                    -- 2
                    if code <= 0xD7FF or (code >= 0xE000 and code <= 0xFFFF) then
                        return strchar(
                            code >> 8,
                            code & 0xff
                        )
                    end

                    -- 4 surrogate pairs
                    if code >= 0x10000 and code <= 0x10FFFF then
                        code        = code - 0x10000
                        local high  = code >> 10
                        local low   = code & 0x3ff
                        return strchar(
                            0xD8 + high >> 8,
                            high & 0xff,
                            0xDC + low >> 8,
                            low & 0xff
                        )
                    end
                end

                error(("%s is not a valid unicode."):format(code), 2)
            end
        ]], "UTF16_ENCODE_DECODE", _ENV)()
    end

    -- Lua 5.2 - bit32 lib or luajit bit lib
    if (LUA_VERSION == 5.2 and type(_G.bit32) == "table") or (LUA_VERSION == 5.1 and type(_G.bit) == "table") then
        export {
            band                = _G.bit32 and bit32.band or bit.band,
            lshift              = _G.bit32 and bit32.lshift or bit.lshift,
            rshift              = _G.bit32 and bit32.rshift or bit.rshift,
        }

        function decodeLE(str, startp)
            startp              = startp or 1

            local sbyte, obyte  = strbyte(str, startp, startp + 1)
            if not obyte or not sbyte then return nil end

            if obyte <= 0xD7 or obyte >= 0xE0 then
                -- two bytes
                return lshift(obyte, 8) + sbyte, 2
            elseif obyte >= 0xD8 and obyte <= 0xDB then
                -- four byte
                local fbyte, tbyte = strbyte(str, startp + 2, startp + 3)
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
                    code        = code - 0x10000
                    local high  = rshift(code, 10)
                    local low   = band(code, 0x3ff)
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
            startp              = startp or 1

            local obyte, sbyte  = strbyte(str, startp, startp + 1)
            if not obyte or not sbyte then return nil end

            if obyte <= 0xD7 or obyte >= 0xE0 then
                -- two bytes
                return lshift(obyte, 8) + sbyte, 2
            elseif obyte >= 0xD8 and obyte <= 0xDB then
                -- four byte
                local tbyte, fbyte = strbyte(str, startp + 2, startp + 3)
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
                    code        = code - 0x10000
                    local high  = rshift(code, 10)
                    local low   = band(code, 0x3ff)
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
    end

   --- Represents the utf-16 encoding with little-endian.
    System.Text.Encoding "UTF16EncodingLE" {
        encode                  = encodeLE,
        decode                  = decodeLE,
    }

   --- Represents the utf-16 encoding with big-endian.
    System.Text.Encoding "UTF16EncodingBE" {
        encode                  = encodeBE,
        decode                  = decodeBE,
    }
end)
