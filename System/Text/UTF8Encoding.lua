--===========================================================================--
--                                                                           --
--                         System.Text.UTF8Encoding                          --
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
        REPLACE_CHARACTER               = "\0xFFFD",

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
    }

    function decode(str, startp)
        startp                          = startp or 1

        local byte                      = strbyte(str, startp)
        if not byte then return nil end

        if byte < 0x80 then
            -- 1-byte
            return byte, 1
        elseif byte < 0xC2 then
            -- Error
            return byte + 0xDC00, 1
        elseif byte < 0xE0 then
            -- 2-byte
            local sbyte                 = strbyte(str, startp + 1)
            if not sbyte or band(sbyte, 0xC0) ~= 0x80 then
                -- Error
                return byte + 0xDC00, 1
            end
            return lshift(byte, 6) + sbyte - 0x3080, 2
        elseif byte < 0xF0 then
            -- 3-byte
            local sbyte, tbyte  = strbyte(str, startp + 1, startp + 2)
            if not (sbyte and tbyte) or band(sbyte, 0xC0) ~= 0x80 or (byte == 0xE0 and sbyte < 0xA0) or band(tbyte, 0xC0) ~= 0x80 then
                -- Error
                return byte + 0xDC00, 1
            end
            return lshift(byte, 12) + lshift(sbyte, 6) + tbyte - 0xE2080, 3
        elseif byte < 0xF5 then
            -- 4-byte
            local sbyte, tbyte, fbyte = strbyte(str, startp + 1, startp + 3)
            if not (sbyte and tbyte and fbyte) or band(sbyte, 0xC0) ~= 0x80 or (byte == 0xF0 and sbyte < 0x90) or (byte == 0xF4 and sbyte >= 0x90) or band(tbyte, 0xC0) ~= 0x80 or band(fbyte, 0xC0) ~= 0x80 then
                -- Error
                return byte + 0xDC00, 1
            end
            return lshift(byte, 18) + lshift(sbyte, 12) + lshift(tbyte, 6) + fbyte - 0x3C82080, 4
        else
            return byte + 0xDC00, 1
        end
    end

    function encode(code)
        if code >= 0 then
            -- 1
            if code <= 0x7F then return strchar( code ) end

            -- 2
            if code <= 0x7FF then
                return strchar(
                    rshift(code, 6) + 0xC0,
                    band(code, 0x3F) + 0x80
                )
            end

            -- 3
            if code <= 0xFFFF then
                return strchar(
                    rshift(code, 12) + 0xE0,
                    band(rshift(code, 6), 0x3F) + 0x80,
                    band(code, 0x3F) + 0x80
                )
            end

            -- 4
            if code <= 0x1FFFFF then
                return strchar(
                    rshift(code, 18) + 0xF0,
                    band(rshift(code, 12), 0x3F) + 0x80,
                    band(rshift(code, 6), 0x3F) + 0x80,
                    band(code, 0x3F) + 0x80
                )
            end
        end

        error(("%s is not a valid code_point."):format(code), 2)
    end

    --[[
    7   U+0000      U+007F      1   0xxxxxxx
    11  U+0080      U+07FF      2   110xxxxx    10xxxxxx
    16  U+0800      U+FFFF      3   1110xxxx    10xxxxxx    10xxxxxx
    21  U+10000     U+1FFFFF    4   11110xxx    10xxxxxx    10xxxxxx    10xxxxxx
    26  U+200000    U+3FFFFFF   5   111110xx    10xxxxxx    10xxxxxx    10xxxxxx    10xxxxxx
    31  U+4000000   U+7FFFFFFF  6   1111110x    10xxxxxx    10xxxxxx    10xxxxxx    10xxxxxx    10xxxxxx
    ]]
    --- Represents the utf-8 encoding.
    System.Text.Encoding "UTF8Encoding" {
        encode                          = encode,
        decode                          = decode,
    }
end)