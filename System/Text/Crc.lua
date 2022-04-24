--===========================================================================--
--                                                                           --
--                              System.Text.Crc                              --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2021/02/16                                               --
-- Update Date  :   2021/02/16                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    export {
        strbyte                         = string.byte,
        strchar                         = string.char,
        band                            = Toolset.band,
        bor                             = Toolset.bor,
        bnot                            = Toolset.bnot,
        bxor                            = Toolset.bxor,
        lshift                          = Toolset.lshift,
        rshift                          = Toolset.rshift,

        crc32_table                     = {},
    }

    do
        for i = 0, 255 do
            local crc                   = i
            for j = 1, 8 do crc = bxor(rshift(crc, 1), band(0xEDB88320, bnot(band(crc,1)-1))) end
            crc32_table[i]              = crc
        end
    end

    __Static__() __Arguments__{ String, Number/nil }
    function System.Text.CRC32(text, crc)
        crc                             = bnot(crc or 0)
        for i = 1, #text do crc = bxor(crc32_table[bxor(text:byte(i), band(crc, 0xff))], rshift(crc,8)) end
        crc                             = bnot(crc)
        return crc < 0 and (crc + 4294967296) or crc
    end
end)