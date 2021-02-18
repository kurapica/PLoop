--===========================================================================--
--                                                                           --
--                              System.IO.Gzip                               --
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

    __Final__() __Sealed__() interface "System.IO.Gzip" (function(_ENV)

        export {
            yield               = coroutine.yield,
            strbyte             = string.byte,
            strchar             = string.char,
            min                 = math.min,
            max                 = math.max,
            floor               = math.floor,
            ceil                = math.ceil,
            unpack              = unpack or table.unpack,
            band                = Toolset.band,
            bor                 = Toolset.bor,
            bnot                = Toolset.bnot,
            bxor                = Toolset.bxor,
            lshift              = Toolset.lshift,
            rshift              = Toolset.rshift,
            type                = type,
            error               = error,
            pcall               = pcall,
            tconcat             = table.concat,
            istype              = Class.IsObjectType,
            CRC32               = System.Text.CRC32,
            GetFileNameWithoutSuffix = System.IO.Path.GetFileNameWithoutSuffix,

            System.IO.FileReader, System.IO.FileWriter, System.Text.TextReader,
            System.Text.Deflate,
        }

        __Static__()
        function Unzip(reader, targetdir)
            local filename

            if type(reader) == "string" then
                filename        = GetFileNameWithoutSuffix(reader)
                reader          = FileReader(reader, "rb")
            elseif not istype(reader, TextReader) then
                error("Usage: System.IO.Gzip(source[, targetdir]) - the source must be a file name or System.Text.TextReader", 2)
            end

            local ok, err       = pcall(reader.Open, reader)
            if not ok then
                error("Usage: System.IO.Gzip(source[, targetdir]) - the source file can't be open", 2)
            end

            local header        = reader:ReadBlock(10)
            if not (header and #header == 10) then
                error("Usage: System.IO.Gzip(source[, targetdir]) - the source file can't be unzipped", 2)
            end

            local id1, id2, cm, flg = header:byte(1, 4)
            if id1 ~= 31 or id2 ~= 139 then
                error("Usage: System.IO.Gzip(source[, targetdir]) - invalid gzip header", 2)
            end

            if cm ~= 8 then
                error("Usage: System.IO.Gzip(source[, targetdir]) - only support delfate format", 2)
            end

            local ftext         = band(1, flg)
            local fhcrc         = band(2, flg)
            local fextra        = band(4, flg)
            local fname         = band(8, flg)
            local fcomment      = band(16, flg)

            if fextra ~= 0 then
                -- Skip the extra
                local xlen      = reader:ReadBlock(2)
                if not xlen or #xlen ~= 2 then
                    error("Usage: System.IO.Gzip(source[, targetdir]) - failed to fetch the extra field length", 2)
                end
                local b1, b2    = xlen:byte(1, 2)
                if not reader:ReadBlock(b2 * 256 + b1) then
                    error("Usage: System.IO.Gzip(source[, targetdir]) - failed to fetch the extra field", 2)
                end
            end

            if fname ~= 0 then
                local name      = {}
                local b         = reader:Read()
                local i         = 1
                while b and b ~= 0 do
                    name[i]     = b
                    i           = i + 1

                    b           = reader:Read()
                end

                if not b then
                    error("Usage: System.IO.Gzip(source[, targetdir]) - no zero-terminated byte for the file name", 2)
                end

                if i > 1 then
                    filename    = tconcat(name)
                end
            end

            if fcomment ~= 0 then
                -- skip the comment
                local b         = reader:Read()
                while b and b ~= 0 do
                    b           = reader:Read()
                end

                if not b then
                    error("Usage: System.IO.Gzip(source[, targetdir]) - no zero-terminated byte for the file comment", 2)
                end
            end

            if fhcrc ~= 0 then
                local crc       = reader:ReadBlock(2)
                if not crc then
                    error("Usage: System.IO.Gzip(source[, targetdir]) - failed to fetch the crc16", 2)
                end
                -- @todo: rare to be used, skip it for now
            end

            local crc           = 0

            for text, msg in Deflate.Decodes(reader) do
                if not msg then
                    crc         = CRC32(text, crc)
                    --@todo: Add text writer
                    print(text)
                else
                    pcall(reader.Close, reader)
                    error("Usage: System.IO.Gzip(source[, targetdir]) - " .. msg, 2)
                end
            end

            -- Check the CRC
            local crcpart       = reader:ReadBlock(4) or ""
            local c1,c2,c3,c4   = crcpart:byte(1, 4)
            if not (c1 and c2 and c3 and c4 and (c1 + 256 * (c2 + 256 * (c3 + 256 * c4))) == crc) then
                error("Usage: System.IO.Gzip(source[, targetdir]) - CRC32 verification failed", 2)
            end

            pcall(reader.Close, reader)
        end
    end)
end)