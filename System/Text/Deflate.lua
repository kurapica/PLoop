--===========================================================================--
--                                                                           --
--                            System.Text.Deflate                            --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2021/02/04                                               --
-- Update Date  :   2021/05/25                                               --
-- Version      :   1.0.1                                                    --
--===========================================================================--

PLoop(function(_ENV)

    export {
        yield                   = coroutine.yield,
        strbyte                 = string.byte,
        strchar                 = string.char,
        pairs                   = pairs,
        ipairs                  = ipairs,
        min                     = math.min,
        max                     = math.max,
        floor                   = math.floor,
        ceil                    = math.ceil,
        log                     = math.log,
        unpack                  = _G.unpack or table.unpack,
        band                    = Toolset.band,
        bor                     = Toolset.bor,
        bnot                    = Toolset.bnot,
        bxor                    = Toolset.bxor,
        lshift                  = Toolset.lshift,
        rshift                  = Toolset.rshift,
        tinsert                 = table.insert,
        tremove                 = table.remove,

        LAZY_MATCH_LIMIT        = 8,

        BAND_LENGTH             = List(19, 'i=>2^i - 1'),
        MAGIC_HUFFMAN_ORDER     = { 16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15 },
    }

    -----------------------------------------------------------------------
    --             RFC 1951 - DEFLATE Compressed Data Format             --
    -----------------------------------------------------------------------
    local FIXED_LIT_HTREE
    local FIXED_DIST_HTREE

    __Sealed__() __AutoCache__()
    BitStreamReader             = class {
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
                if self.cursor >= self.length then
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

    __Sealed__() __AutoCache__()
    BitStreamWriter             = class {
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
            if self.size >= 1024 then self:Flush() end

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

    __Sealed__() __AutoCache__()
    ByteStreamWriter            = class {
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

    __Sealed__() __AutoCache__()
    HuffTableTree               = class {
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

                    -- Map code -> byte
                    local mcode = 0
                    for j = 1, d do
                        mcode   = mcode + lshift(band(1, rshift(code, j - 1)), d - j)
                    end
                    codes[i]    = mcode

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
        ToByte                  = function(self, byte)
            return self.codes[byte], self.depths[byte]
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

            FIXED_LIT_HTREE     = HuffTableTree(depths)
        end

        if not FIXED_DIST_HTREE then
            local depths        = {}

            for i = 0, 31       do depths[i] = 5 end

            FIXED_DIST_HTREE    = HuffTableTree(depths)
        end
    end

    calcHuffmanDepths           = function(freqitems, mbyte, maxLevel)
        local root
        local count             = 0
        local depths            = {}

        local insertLink        = function(node)
            local parent        = root
            local upper
            local freq          = node.freq

            while parent and parent.freq <= freq do
                upper           = parent
                parent          = parent.next
            end

            node.next           = parent

            if upper then
                upper.next      = node
            else
                root            = node
            end
        end

        local convertToLevel
        convertToLevel          = function(node, level)
            -- Normally enough
            if maxLevel and maxLevel < level then level = maxLevel end

            if node.left then
                convertToLevel(node.left,  level + 1)
                if node.right then convertToLevel(node.right, level + 1) end
            else
                -- Leaf node
                depths[node.byte] = level
            end
        end

        -- build a link list based on the freq
        for i = 0, mbyte do
            depths[i]           = 0

            local freq          = freqitems[i]
            if freq and freq > 0 then
                insertLink{ byte = i, freq = freq }
                count               = count + 1
            end
        end

        if count == 0 then
            return depths
        elseif count == 1 then
            depths[root.byte]   = 1
            return depths
        end

        -- Build the huffman tree
        for i = 1, max(1, count - 1) do
            local a             = root
            local b             = root.next

            a.next              = nil
            if b then
                root            = b and b.next
                b.next          = nil
            end

            insertLink{ freq = a.freq + (b and b.freq or 0), left = a, right = b }
        end

        -- Calc the depths of the byte
        convertToLevel(root, 0)

        return depths
    end

    __Sealed__() enum "System.Text.DeflateMode" {
        "NoCompression",
        "FixedHuffmanCodes",
        "DynamicHuffmanCodes",
    }

    --- System.Text.Encoder.Deflate
    System.Text.Encoder "Deflate" {
        encode                  = function(reader, mode)
            if mode == DeflateMode.NoCompression then
                local text      = reader:ReadBlock(32768)
                while text do
                    local len   = #text
                    local nxt   = len == 32768 and reader:ReadBlock(32768)
                    local writer= BitStreamWriter()

                    writer:Write(nxt and 0 or 1, 1) -- BFINAL
                    writer:Write(0, 2)              -- BTYPE
                    writer:FillByte()
                    writer:Write(len, 16)           -- LEN
                    writer:Write(band(bnot(len), 65535), 16) -- NLEN
                    writer:Close()

                    yield(text)

                    text        = nxt
                end
            else
                local buff      = reader:ReadBlock(16384)
                local length    = #buff
                local writer    = BitStreamWriter()
                local prev      = false
                local nxt       = false
                local matchlst  = {}
                local base      = 0
                local cpcursor  = nil
                local cplen     = 0
                local cpdist    = 0
                local widx      = 0

                if not buff then return end

                local b1, b2, b3= buff:byte(1, 3)
                local cursor    = 3

                local readByte  = function(index, move)
                    if not index then
                        cursor  = cursor + 1
                        index   = cursor
                        move    = true
                    elseif move then
                        cursor  = index
                    end

                    local offset= index - base

                    if offset <= 0 then
                        return prev and prev:byte(16384 + offset) or nil
                    elseif offset > length and length == 16384 then
                        nxt     = nxt or reader:ReadBlock(16384) or false
                        offset  = offset - length

                        if move then
                            prev            = buff
                            buff            = nxt
                            nxt             = false
                            length          = buff and #buff or 0

                            if buff then
                                -- Clear matchlst that out of the window
                                for k, v in pairs(matchlst) do
                                    local l = #v
                                    local b = 0
                                    for i = 1, l do
                                        if v[i] > base then
                                            b = i
                                            break
                                        end
                                    end

                                    if b == 0 then
                                        for i = l, 1, -1 do
                                            v[i]        = nil
                                        end
                                    elseif b > 1 then
                                        for j = b, l do
                                            v[j - b + 1]= v[j]
                                        end

                                        for j = l - b + 2, l do
                                            v[j]        = nil
                                        end
                                    end
                                end

                                base        = base + 16384

                                return buff:byte(offset)
                            end
                        else
                            return nxt and nxt:byte(offset) or nil
                        end
                    else
                        return buff and buff:byte(offset) or nil
                    end
                end

                local litHtree, distHtree
                local sendPair, sendRaw, sendBlock

                if mode == DeflateMode.FixedHuffmanCodes or mode == true then
                    initFixedHuffmanCodes()

                    litHtree    = FIXED_LIT_HTREE
                    distHtree   = FIXED_DIST_HTREE

                    sendPair    = function(length, distance)
                        -- <Length, Distance>
                        if length < 11 then
                            writer:Write(litHtree:ToByte(254 + length))
                        elseif length < 258 then
                            local e = ceil(log(2 + rshift(length - 11, 3)) / log(2))
                            local b = 261 + lshift(e, 2) + rshift(length - 3, e) - 4
                            local d = length - 3 - lshift(band(b - 261, 3) + 4, e)

                            writer:Write(litHtree:ToByte(b))
                            writer:Write(d, e)
                        else
                            writer:Write(litHtree:ToByte(285))
                        end

                        if distance < 5 then
                            writer:Write(distHtree:ToByte(distance - 1))
                        else
                            local e = ceil(log(2 + rshift(distance - 5, 2)) / log(2))
                            local b = rshift(distance - 1, e) + lshift(e, 1)
                            local d = distance - 1 - lshift(band(b, 1) + 2, e)

                            writer:Write(distHtree:ToByte(b))
                            writer:Write(d, e)
                        end
                    end

                    sendRaw     = function(index)
                        if index == true then
                            -- End
                            widx    = widx + 1
                            local b = readByte(widx)
                            while b do
                                writer:Write(litHtree:ToByte(b))
                                widx= widx + 1
                                b   = readByte(widx)
                            end
                        else
                            for i = widx + 1, index do
                                writer:Write(litHtree:ToByte(readByte(i)))
                            end
                            widx    = index
                        end
                    end

                    writer:Write(1, 1)
                    writer:Write(1, 2)
                else
                    local bidx  = 0
                    local block = {}
                    local litefr= { [256] = 1 }
                    local distfr= {}

                    sendPair    = function(length, distance)
                        -- <Length, Distance>
                        if length < 11 then
                            local b     = 254 + length
                            litefr[b]   = (litefr[b] or 0) + 1

                            bidx        = bidx + 1
                            block[bidx] = b
                        elseif length < 258 then
                            local e     = ceil(log(2 + rshift(length - 11, 3)) / log(2))
                            local b     = 261 + lshift(e, 2) + rshift(length - 3, e) - 4
                            local d     = length - 3 - lshift(band(b - 261, 3) + 4, e)

                            litefr[b]   = (litefr[b] or 0) + 1
                            bidx        = bidx + 1
                            block[bidx] = b

                            bidx        = bidx + 1
                            block[bidx] = d
                            bidx        = bidx + 1
                            block[bidx] = e
                        else
                            local b     = 285
                            litefr[b]   = (litefr[b] or 0) + 1

                            bidx        = bidx + 1
                            block[bidx] = b
                        end

                        if distance < 5 then
                            local b     = distance - 1
                            distfr[b]   = (distfr[b] or 0) + 1

                            bidx        = bidx + 1
                            block[bidx] = b
                        else
                            local e     = ceil(log(2 + rshift(distance - 5, 2)) / log(2))
                            local b     = rshift(distance - 1, e) + lshift(e, 1)
                            local d     = distance - 1 - lshift(band(b, 1) + 2, e)

                            distfr[b]   = (distfr[b] or 0) + 1
                            bidx        = bidx + 1
                            block[bidx] = b

                            bidx        = bidx + 1
                            block[bidx] = d
                            bidx        = bidx + 1
                            block[bidx] = e
                        end
                    end

                    sendRaw     = function(index)
                        if index == true then
                            -- End
                            widx            = widx + 1
                            local b         = readByte(widx)
                            while b do
                                litefr[b]   = (litefr[b] or 0) + 1

                                bidx        = bidx + 1
                                block[bidx] = b

                                widx        = widx + 1
                                b           = readByte(widx)
                            end
                        else
                            for i = widx + 1, index do
                                local b     = readByte(i)
                                litefr[b]   = (litefr[b] or 0) + 1

                                bidx        = bidx + 1
                                block[bidx] = b
                            end
                            widx            = index
                        end
                    end

                    sendBlock   = function(final)
                        writer:Write(final and 1 or 0, 1)
                        writer:Write(2, 2)
                        writer:Write(286 - 257, 5) -- HLIT
                        writer:Write(30 - 1,    5) -- HDIST

                        -- Calc the depths
                        local liteDepths= calcHuffmanDepths(litefr, 285)
                        local distDepths= calcHuffmanDepths(distfr, 29)

                        local depths    = {}

                        local prev      = liteDepths[0]
                        local same      = 1
                        local lenbuff   = {}
                        local lenidx    = 0

                        local sendLength= function()
                            if prev then
                                if prev > 0 then
                                    while same >= 4 do
                                        same        = same - 1
                                        local len   = min(same, 6)

                                        lenidx      = lenidx + 1
                                        lenbuff[lenidx] = prev
                                        depths[prev]= (depths[prev] or 0) + 1

                                        lenidx      = lenidx + 1
                                        lenbuff[lenidx] = 16
                                        depths[16]  = (depths[16] or 0) + 1

                                        lenidx      = lenidx + 1
                                        lenbuff[lenidx] = len - 3

                                        same        = same - len
                                    end

                                    for i = 1, same do
                                        lenidx      = lenidx + 1
                                        lenbuff[lenidx] = prev
                                        depths[prev]= (depths[prev] or 0) + 1
                                    end
                                else
                                    while same >= 3 do
                                        local len   = min(same, 138)
                                        if len >= 11 then
                                            lenidx  = lenidx + 1
                                            lenbuff[lenidx] = 18
                                            depths[18] = (depths[18] or 0) + 1

                                            lenidx  = lenidx + 1
                                            lenbuff[lenidx] = len - 11
                                        else
                                            lenidx  = lenidx + 1
                                            lenbuff[lenidx] = 17
                                            depths[17] = (depths[17] or 0) + 1

                                            lenidx  = lenidx + 1
                                            lenbuff[lenidx] = len - 3
                                        end

                                        same        = same - len
                                    end

                                    for i = 1, same do
                                        lenidx      = lenidx + 1
                                        lenbuff[lenidx] = 0
                                        depths[0]   = (depths[0] or 0) + 1
                                    end
                                end

                                prev    = nil
                                same    = 0
                            end
                        end

                        for i = 1, 285 do
                            local v     = liteDepths[i]
                            if v == prev then
                                same    = same + 1
                            else
                                sendLength()

                                prev    = v
                                same    = 1
                            end
                        end
                        sendLength()

                        prev            = distDepths[0]
                        same            = 1
                        for i = 1, 29 do
                            local v     = distDepths[i]
                            if v == prev then
                                same    = same + 1
                            else
                                sendLength()

                                prev    = v
                                same    = 1
                            end
                        end
                        sendLength()

                        -- The Huffman tree for Length - max level no more than 3 byte
                        local depDepths = calcHuffmanDepths(depths, 18, 7)
                        local lHTree    = HuffTableTree(depDepths)

                        local hclen     = 19
                        while depDepths[MAGIC_HUFFMAN_ORDER[hclen]] == 0 do
                            hclen       = hclen - 1
                        end
                        writer:Write(hclen - 4, 4) -- HCLEN

                        for i = 1, hclen do
                            writer:Write(depDepths[MAGIC_HUFFMAN_ORDER[i]], 3)
                        end

                        local i = 1
                        while i <= lenidx do
                            local v     = lenbuff[i]
                            writer:Write(lHTree:ToByte(v))

                            if v == 16 then
                                writer:Write(lenbuff[i + 1], 2)
                                i       = i + 2
                            elseif v == 17 then
                                writer:Write(lenbuff[i + 1], 3)
                                i       = i + 2
                            elseif v == 18 then
                                writer:Write(lenbuff[i + 1], 7)
                                i       = i + 2
                            else
                                i       = i + 1
                            end
                        end

                        -- Compress the block data
                        i               = 1
                        litHtree        = HuffTableTree(liteDepths)
                        distHtree       = HuffTableTree(distDepths)

                        while i <= bidx do
                            local v     = block[i]

                            if v < 256 then
                                -- Literal
                                writer:Write(litHtree:ToByte(v))
                                i       = i + 1
                            elseif v > 256 then
                                -- <Length, Distance>
                                writer:Write(litHtree:ToByte(v))

                                -- Length Extra
                                if v >= 265 and v < 285 then
                                    writer:Write(block[i+1], block[i+2])
                                    i   = i + 3
                                else
                                    i   = i + 1
                                end

                                -- Distance
                                v       = block[i]
                                writer:Write(distHtree:ToByte(v))

                                if v >= 4 then
                                    writer:Write(block[i+1], block[i+2])
                                    i   = i + 3
                                else
                                    i   = i + 1
                                end
                            end
                        end

                        -- End of Block
                        writer:Write(litHtree:ToByte(256))

                        bidx    = 0
                        block   = {}
                        litefr  = {}
                        distfr  = {}
                    end
                end

                while b3 do
                    -- Check th matchlist
                    local bytes     = b1 + 256 * (b2 + 256 * b3)
                    local match     = matchlst[bytes]

                    if match then
                        local maxcur, maxlen = 0, 0
                        local midx  = #match

                        for i = midx, 1, -1 do
                            local c = match[i] + 2
                            if c < cursor then
                                local l = 0
                                local a, b

                                repeat
                                    l   = l + 1
                                    b   = readByte(cursor + l)

                                    if c + l > base then
                                        a   = strbyte(buff, c + l - base)
                                    else
                                        a   = strbyte(prev, c + l - (base - 16384))
                                    end
                                until a ~= b or l == 256

                                l       = l + 2 -- (3 - 1)

                                if l > maxlen then
                                    maxcur  = match[i]
                                    maxlen  = l
                                end
                            end
                        end

                        if midx == 0 or match[midx] < cursor - 2 then
                            match[midx + 1] = cursor - 2
                        end

                        if maxlen >= LAZY_MATCH_LIMIT then
                            -- No lazy match
                            sendRaw(cursor - 3)
                            sendPair(maxlen, cursor - 2 - maxcur)
                            widx            = cursor - 3 + maxlen

                            b1, b2, b3      = readByte(widx + 1, true), readByte(widx + 2, true), readByte(widx + 3, true)
                            cpcursor        = nil
                        elseif cpcursor then
                            -- Check lazy match
                            if maxlen > cplen then
                                sendRaw(cursor - 3)

                                cpcursor    = cursor - 2
                                cplen       = maxlen
                                cpdist      = cpcursor - maxcur
                                b1, b2, b3  = b2, b3, readByte()
                            else
                                sendRaw(cpcursor - 1)
                                sendPair(cplen, cpdist)
                                widx        = cpcursor + cplen - 1

                                b1, b2, b3  = readByte(widx + 1, true), readByte(widx + 2, true), readByte(widx + 3, true)
                                cpcursor    = nil
                            end
                        elseif maxlen > 0 then
                            -- Wait for lazy match
                            cpcursor        = cursor - 2
                            cplen           = maxlen
                            cpdist          = cpcursor - maxcur
                            b1, b2, b3      = b2, b3, readByte()
                        else
                            b1, b2, b3      = b2, b3, readByte()
                        end
                    else
                        match               = { cursor - 2 }
                        matchlst[bytes]     = match

                        if cpcursor then
                            -- No lazy match
                            sendRaw(cpcursor - 1)
                            sendPair(cplen, cpdist)
                            widx            = cpcursor + cplen - 1

                            b1, b2, b3      = readByte(widx + 1, true), readByte(widx + 2, true), readByte(widx + 3, true)
                            cpcursor        = nil
                        else
                            sendRaw(cursor - 2)
                            b1, b2, b3      = b2, b3, readByte()
                        end
                    end
                end

                -- Finish the rest
                if cpcursor then
                    sendRaw(cpcursor - 1)
                    sendPair(cplen, cpdist)
                    widx        = cpcursor + cplen - 1
                end
                sendRaw(true)

                -- Send the block
                if mode == DeflateMode.FixedHuffmanCodes or mode == true then
                    writer:Write(litHtree:ToByte(256)) -- End of Block
                else
                    sendBlock(true)
                end

                writer:Close()
            end
        end,
        decode                  = function(reader)
            local moreBlocks    = true
            local streamReader  = BitStreamReader(reader)
            local streamWriter  = ByteStreamWriter()

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
                    local lHTree= HuffTableTree(depths)

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

                    if not uncompression(streamWriter, streamReader, HuffTableTree(ldep), HuffTableTree(ddep)) then
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