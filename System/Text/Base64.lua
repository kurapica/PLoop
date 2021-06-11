--===========================================================================--
--                                                                           --
--                            System.Text.Base64                             --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2021/01/24                                               --
-- Update Date  :   2021/01/24                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    -----------------------------------------------------------------------
    --                              prepare                              --
    -----------------------------------------------------------------------
    export {
        strbyte                 = string.byte,
        strchar                 = string.char,
        band                    = Toolset.band,
        bor                     = Toolset.bor,
        rshift                  = Toolset.rshift,
        yield                   = coroutine.yield,
        encodeMap               = List(("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"):gmatch(".")),

        List, System.Text.UTF8Encoding
    }

    export {
        decodeMap               = Dictionary(encodeMap:Map(strbyte), XList(#encodeMap):Map("i=>i-1"))
    }

    encodeMap[0]                = encodeMap[1]
    encodeMap:RemoveByIndex(1)

    -----------------------------------------------------------------------
    --                              Base64                               --
    -----------------------------------------------------------------------
    System.Text.Encoder "Base64" {
        encode                  = function (text, noret)
            local total         = 0
            local length        = #text
            local i             = 1

            while i <= length do
                if not noret and total > 0 and total % 76 == 0 then yield("\n") end

                local f, s, t   = strbyte(text, i, i + 2)
                local cache     = f * 0x10000 + (s or 0) * 0x100 + (t or 0)

                yield(encodeMap[rshift(cache, 18)])
                yield(encodeMap[rshift(band(cache, 0x3FFFF), 12)])

                if s then
                    yield(encodeMap[rshift(band(cache, 0xFFF), 6)])

                    if t then
                        yield(encodeMap[band(cache, 0x3F)])
                        total   = total + 4
                    else
                        yield("=")
                    end
                else
                    yield("==")
                end

                i               = i + 3
            end
        end,
        decode                  = function (text, encode)
            local cache         = 0
            local clen          = 0

            for _, byte in (encode or UTF8Encoding).Decodes(text) do
                local code      = decodeMap[byte]
                if code then
                    if clen == 0 then
                        clen    = 6
                        cache   = code
                    else
                        clen    = clen + 6
                        cache   = cache * 0x40 + code

                        if clen >= 8 then
                            clen= clen - 8

                            yield(strchar(rshift(cache, clen)))
                            cache = band(cache, 2^clen - 1)
                        end
                    end
                end
            end
        end,
    }
end)