--===========================================================================--
--                                                                           --
--                            System.Text.Deflate                            --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2021/02/04                                               --
-- Update Date  :   2021/02/04                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)

    export {
        yield                   = coroutine.yield,
        strbyte                 = string.byte,
        strchar                 = string.char,
        min                     = math.min,
        max                     = math.max,
        floor                   = math.floor,
        ceil                    = math.ceil,
        unpack                  = unpack or table.unpack,
        band                    = Toolset.band,
        bor                     = Toolset.bor,
        bnot                    = Toolset.bnot,
        bxor                    = Toolset.bxor,
        lshift                  = Toolset.lshift,
        rshift                  = Toolset.rshift,

        BAND_LENGTH             = List(19, 'i=>2^i - 1'),
        MAGIC_HUFFMAN_ORDER     = { 16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15 },
    }

    -----------------------------------------------------------------------
    --             RFC 1951 - DEFLATE Compressed Data Format             --
    -----------------------------------------------------------------------
    local FIXED_LIT_HTREE
    local FIXED_DIST_HTREE

    __AutoCache__()
    bitStreamReader             = class {
        __new                   = function(_, reader)
            local buff          = reader:ReadBlock(4096)

            return {
                reader          = reader,

                buff            = buff or false,
                length          = buff and #buff or 0,

                cursor          = 0,
                byte            = 0,
                remain          = 0,
            }, true
        end,

        --- Get the bits by the length, don't move the cursor
        Peek                    = function(self, length)
            length              = length or 1

            while self.remain < length do
                if self.cursor > self.length then
                    self.buff   = self.reader:ReadBlock(4096) or false
                    self.length = self.buff and #self.buff or 0
                    self.cursor = 0
                end

                if not self.buff then return self.byte end

                self.cursor     = self.cursor + 1
                self.byte       = self.byte + lshift(self.buff:byte(self.cursor), self.remain)
                self.remain     = self.remain + 8
            end

            return band(self.byte, BAND_LENGTH[length] or (lshift(1, length) - 1))
        end,

        --- Get the bits by the length, also move the cursor
        Get                     = function(self, length)
            local bits          = self:Peek(length)
            if bits then self:Skip(length) end
            return bits
        end,

        --- Skip the bit length
        Skip                    = function(self, length)
            if not length then
                -- Skip the remain bits in the byte
                if self.remain == 8 then return end
                self.byte       = 0
                self.remain     = 0
                return
            end

            if self.remain < length then return end

            self.remain         = self.remain - length
            self.byte           = rshift(self.byte, length)
        end,

        --- Close the reader and reset the reader's Position
        Close                   = function(self)
            self.reader.Position= self.reader.Position - self.length + self.cursor
        end,
    }

    __AutoCache__()
    bitStreamWriter             = class {
        __new                   = function()
            return {
                main            = {},
                size            = 0,
                byte            = 0,
                bytelen         = 0,
            }, true
        end,

        --- Write the byte
        Write                   = function(self, byte, len)
            if self.size >= 32768 then self:Flush() end

            self.byte           = self.byte + lshift(byte, self.bytelen)
            self.bytelen        = self.bytelen + len

            while self.bytelen >= 8 do
                self.size       = self.size + 1
                self.main[self.size] = band(self.byte, 0xff)
                self.byte       = rshift(self.byte, 8)
                self.bytelen    = self.bytelen - 8
            end
        end,

        FillByte                = function(self)
            if self.bytelen > 0 then
                self.size       = self.size + 1
                self.main[self.size] = self.byte
            end

            self.byte           = 0
            self.bytelen        = 0
        end,

        --- Close the writer
        Close                   = function(self)
            self:FillByte()

            return self:Flush()
        end,

        Flush                   = function(self)
            local size          = self.size
            if size == 0 then return end
            local index         = 0

            while index < size do
                local last      = min(size, index + 2048)
                yield(strchar(unpack(self.main, index + 1, last)))
                index           = last
            end

            self.main           = {}
            self.size           = 0
        end,
    }

    __AutoCache__()
    byteStreamWriter            = class {
        __new                   = function()
            return {
                main            = {},
                prev            = false,
                psize           = 0,
                size            = 0,
            }, true
        end,

        --- Write the byte
        Write                   = function(self, byte)
            if self.size >= 32768 then self:Flush() end

            self.size           = self.size + 1
            self.main[self.size]= byte
        end,

        --- Get the bytes from the cache
        Copy                    = function(self, length, distance)
            local main          = self.main
            local size          = self.size

            if size < distance then
                local pdis      = distance - size
                if not (self.psize >= pdis) then return false end

                local prev      = self.prev
                local psize     = self.psize
                local index     = psize - pdis + 1

                for i = index, min(psize, index + length - 1) do
                    size        = size + 1
                    main[size]  = prev[i]
                end

                distance        = size
                length          = max(0, length - pdis)
            end

            local index         = size - distance + 1

            for i = 1, length do
                size            = size + 1
                main[size]      = main[index]
                index           = index + 1
            end

            self.size           = size

            return true
        end,

        Flush                   = function(self)
            local size          = self.size
            local index         = 0
            if size == 0 then return end

            while index < size do
                local last      = min(size, index + 2048)
                yield(strchar(unpack(self.main, index + 1, last)))
                index           = last
            end

            self.prev           = self.main
            self.main           = {}
            self.psize          = size
            self.size           = 0
        end,
    }

    __AutoCache__()
    huffTableTree               = class {
        __new                   = function(_, depths)
            -- From 0 ~ xx
            local mbyte         = #depths
            local max_bits      = 0
            local bl_count      = {}

            for i = 0, mbyte do
                local d         = depths[i]
                if d > max_bits then max_bits = d end
                bl_count[d]     = (bl_count[d] or 0) + 1
            end

            bl_count[0]         = 0 -- Clear

            local code          = 0
            local next_code     = {}

            for i = 1, max_bits do
                code            = lshift( (code + (bl_count[i - 1] or 0)), 1 )
                next_code[i]    = code
            end

            local max_code      = 2^max_bits - 1

            local codes         = {}
            local map           = {}

            for i = 0, mbyte do
                local d         = depths[i]
                if d > 0 then
                    code        = next_code[d]
                    next_code[d]= next_code[d] + 1

                    codes[i]    = code

                    -- Map code -> byte
                    local mcode = 0
                    for j = 1, d do
                        mcode   = mcode + lshift(band(1, rshift(code, j - 1)), d - j)
                    end

                    for j = mcode, max_code, 2^d do
                        map[j]  = i
                    end
                end
            end

            return {
                depths          = depths,
                codes           = codes,
                map             = map,
                nbits           = max_bits,
            }, true
        end,
        ParseByte               = function(self, reader)
            local sbyte         = reader.byte
            local bits          = reader:Peek(self.nbits)
            local byte          = self.map[bits]
            if byte then
                reader:Skip(self.depths[byte])
                return byte
            end
        end,
    }

    uncompression               = function(writer, reader, litHtree, distHtree)
        repeat
            local byte          = litHtree:ParseByte(reader)
            if not byte then return end

            if byte < 256 then
                -- Literal
                writer:Write(byte)
            elseif byte == 256 then
                -- End of block
                return true
            elseif byte > 256 then
                -- <Length, Distance>
                local length    = 3
                local distance  = 1

                if byte < 265 then
                    length      = length + byte - 257
                elseif byte < 285 then
                    local extra = rshift(byte - 261, 2)
                    length      = length + lshift(band(byte - 261, 3) + 4, extra)
                    extra       = reader:Get(extra)
                    if not extra then return end
                    length      = length + extra
                else
                    length      = 258
                end

                local dbyte     = distHtree:ParseByte(reader)
                if not dbyte then return end

                if dbyte < 4 then
                    distance    = distance + dbyte
                else
                    local extra = rshift(dbyte - 2, 1)
                    distance    = distance + lshift(band(dbyte, 1) + 2, extra)

                    extra       = reader:Get(extra)
                    if not extra then return end

                    distance    = distance + extra
                end

                if not writer:Copy(length, distance) then return end
            end
        until not byte
    end

    initFixedHuffmanCodes       = function()
        if not FIXED_LIT_HTREE then
            -- Init the fixed huffman code tree
            local depths        = {}

            for i = 0,   143    do depths[i] = 8 end
            for i = 144, 255    do depths[i] = 9 end
            for i = 256, 279    do depths[i] = 7 end
            for i = 280, 287    do depths[i] = 8 end

            FIXED_LIT_HTREE     = huffTableTree(depths)
        end

        if not FIXED_DIST_HTREE then
            local depths        = {}

            for i = 0, 31       do depths[i] = 5 end

            FIXED_DIST_HTREE    = huffTableTree(depths)
        end
    end

    __Sealed__() enum "System.Text.DeflateMode" {
        "NoCompression",
        "FixedHuffmanCodes",
        "DynamicHuffmanCodes",
        "Reserved",
    }

    --- System.Text.Encoder.Deflate
    System.Text.Encoder "Deflate" {
        encode                  = function(reader, mode)
            if mode == DeflateMode.NoCompression then
                local text      = reader:ReadBlock(32768)
                while text do
                    local len   = #text
                    local nxt   = len == 32768 and reader:ReadBlock(32768)
                    local writer= bitStreamWriter()

                    writer:Write(nxt and 0 or 1, 1) -- BFINAL
                    writer:Write(0, 2)              -- BTYPE
                    writer:FillByte()
                    writer:Write(len, 16)           -- LEN
                    writer:Write(band(bnot(len), 65535), 16) -- NLEN
                    writer:Close()

                    yield(text)

                    text        = nxt
                end
            elseif mode == DeflateMode.FixedHuffmanCodes then
                initFixedHuffmanCodes()


            else
                -- DeflateMode.DynamicHuffmanCodes
            end
        end,
        decode                  = function(reader)
            local moreBlocks    = true
            local streamReader  = bitStreamReader(reader)
            local streamWriter  = byteStreamWriter()

            while moreBlocks do
                local bfinal    = streamReader:Get(1)
                local btype     = streamReader:Get(2)
                if not (bfinal and btype) then return "", "The BFINAL and BTYPE can't be fetched" end

                moreBlocks      = bfinal == 0

                if btype == 0 then
                    -- No compression
                    streamReader:Skip() -- Skip the remain bits

                    local len   = streamReader:Get(16)
                    local nlen  = streamReader:Get(16)
                    if not (len and nlen and bxor(len, nlen) == 65535) then
                        return "", "The LEN and NLEN not existed or doesn't match"
                    end
                    streamReader:Close()

                    local total = 0

                    while total < len do
                        local b = reader:ReadBlock(min(4096, len - total))
                        if not b then break end

                        local l = #b

                        for i = 1, l do streamWriter:Write(strbyte(b, i)) end

                        total   = total + l
                    end

                    if total < len then
                        return "", "The uncompressed block length not match"
                    end
                elseif btype == 1 then
                    -- Compressed with fixed Huffman codes
                    initFixedHuffmanCodes()

                    if not uncompression(streamWriter, streamReader, FIXED_LIT_HTREE, FIXED_DIST_HTREE) then
                        return "", "The input data can't be decompressed"
                    end
                elseif btype == 2 then
                    -- Compressed with dynamic Huffman codes
                    local hlit  = streamReader:Get(5) -- # of Literal/Length codes - 257
                    local hdist = streamReader:Get(5) -- # of Distance codes - 1
                    local hclen = streamReader:Get(4) -- # of Code Length codes - 4
                    if not (hlit and hdist and hclen) then return "", "The input data can't be decompressed" end

                    local depths= { [0] = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
                    for i = 1, hclen + 4 do
                        local c = streamReader:Get(3)
                        if not c then return "", "The input data can't be decompressed" end
                        depths[MAGIC_HUFFMAN_ORDER[i]] = c
                    end

                    -- The Huffman tree for Length
                    local lHTree= huffTableTree(depths)

                    depths      = {}

                    hlit        = hlit  + 257
                    hdist       = hdist + 1

                    local idx   = 1
                    local ext
                    while idx <= hlit + hdist do
                        local c = lHTree:ParseByte(streamReader)
                        if not c then return "", "The input data can't be decompressed" end

                        if c < 16 then
                            -- Represent code lengths of 0 - 15
                            depths[idx] = c
                            idx = idx + 1
                        elseif c == 16 then
                            -- Copy the previous code length 3 - 6 times. (2 bits of length)
                            ext = streamReader:Get(2)
                            if not ext then return "", "The input data can't be decompressed" end

                            c   = depths[idx - 1]
                            if not c then return "", "The input data can't be decompressed" end

                            for i = 1, 3 + ext do
                                depths[idx] = c
                                idx         = idx + 1
                            end
                        elseif c == 17 then
                            -- Repeat a code length of 0 for 3 - 10 times. (3 bits of length)
                            ext = streamReader:Get(3)
                            if not ext then return "", "The input data can't be decompressed" end

                            c   = 0

                            for i = 1, 3 + ext do
                                depths[idx] = c
                                idx         = idx + 1
                            end
                        elseif c == 18 then
                            -- Repeat a code length of 0 for 11 - 138 times. (7 bits of length)
                            ext = streamReader:Get(7)
                            if not ext then return "", "The input data can't be decompressed" end

                            c   = 0

                            for i = 1, 11 + ext do
                                depths[idx] = c
                                idx         = idx + 1
                            end
                        else
                            return "", "The input data can't be decompressed"
                        end
                    end

                    local ldep  = {}
                    for i = 1, hlit do
                        ldep[i - 1] = depths[i]
                    end

                    local ddep  = {}
                    local base  = hlit + 1
                    for i = base, #depths do
                        ddep[i - base] = depths[i]
                    end

                    if not uncompression(streamWriter, streamReader, huffTableTree(ldep), huffTableTree(ddep)) then
                        return "", "The input data can't be decompressed"
                    end
                else
                    -- Reserved
                    return "", "The compressed type is reserved"
                end
            end

            streamReader:Close()

            -- Clear the buff
            streamWriter:Flush()
        end,
        strategy                = System.Text.TextReaderStrategy.READER,
    }
end)