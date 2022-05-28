--===========================================================================--
--                                                                           --
--                                System.Text                                --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2014/10/05                                               --
-- Update Date  :   2019/10/11                                               --
-- Version      :   1.0.2                                                    --
--===========================================================================--

PLoop(function(_ENV)
    export {
        type                            = type,
        error                           = error,
        ipairs                          = ipairs,
        max                             = math.max,
        yield                           = coroutine.yield,
        tconcat                         = table.concat,
        istype                          = Class.IsObjectType,
        validateValue                   = Struct.ValidateValue,
        RunIterator                     = Threading.RunIterator,

        DEFAULT_BLOCK                   = 32768,

        Prototype, Namespace, Toolset, Iterable
    }

    __Sealed__() __Final__()
    interface "System.Text" {}

    namespace "System.Text"

    __Sealed__()
    class "EncodingException"           { Exception, Message = { type = String, default = "The encoding isn't supported" } }

    __Sealed__() __AutoIndex__()
    enum "TextReaderStrategy"           { "CHAR", "LINE", "ALL", "BLOCK", "READER" }

    __Sealed__()
    struct "EncodingDefinition"         {
        { name  = "encode",     type    = Function,             require = true },
        { name  = "decode",     type    = Function,             require = true },
        { name  = "strategy",   type    = TextReaderStrategy,   default = TextReaderStrategy.LINE },
        { name  = "block",      type    = NaturalNumber },
    }

    __Iterator__()
    function iterReader(reader, strategy, block)
        if strategy == TextReaderStrategy.CHAR then
            local index                 = reader.Position + 1
            local chr                   = reader:Read(1)
            while chr do
                yield(index, chr)

                chr                     = reader:Read(1)
                index                   = index + 1
            end
        elseif strategy == TextReaderStrategy.ALL then
            yield(reader.Position + 1, reader:ReadToEnd())
        elseif strategy == TextReaderStrategy.BLOCK then
            block                       = block or DEFAULT_BLOCK
            local index                 = reader.Position + 1
            local text                  = reader:Read(block)
            while text do
                yield(index, text)

                index                   = reader.Position + 1
                text                    = reader:Read(block)
            end
        else
            -- Read Line, As Default
            local base                  = reader.Position + 1
            local line                  = reader:ReadLine()
            if not line then return end

            yield(base, line)

            while true do
                base                    = reader.Position
                line                    = reader:ReadLine()
                if not line then return end

                yield(base, "\n")
                yield(base + 1, line)
            end
        end
    end

    -----------------------------------------------------------------------
    --                             Encoding                              --
    -----------------------------------------------------------------------
    __Iterator__()
    function IterReaderDecoding(decode, reader, strategy, block)
        for i, str in iterReader(reader, strategy, block) do
            local base                  = i - 1
            local idx                   = 1
            local lcnt                  = #str

            while idx <= lcnt do
                local code, len         = decode(str, idx)
                if not code then return end

                yield(base + idx, code)
                idx                     = idx + (len or 1)
            end
        end
    end

    __Iterator__()
    function IterEncoding(encode, iter, arg1, arg2)
        local i                         = 1
        for idx, code in iter, arg1, arg2 do
            yield(i, encode(code or idx))
            i                           = i + 1
        end
    end

    local encoding
    local newEncoding                   = function (name, settings)
        local encode                    = settings.encode
        local decode                    = settings.decode
        local strategy                  = settings.strategy
        local block                     = settings.block

        if not name:find(".", 1, true)  then name = "System.Text." .. name end
        if Namespace.GetNamespace(name) then error("The " .. name .. " is already existed", 3) end

        local decodes                   = function(str, startp)
            startp                      = startp or 1
            local code, len             = decode(str, startp)
            if code then return startp + (len or 1), code end
        end

        return Namespace.SaveNamespace(name, Prototype {
            __index                     = {
                -- Encode a unicode code point
                Encode                  = encode,

                -- Decode a char based on  the index, default 1
                Decode                  = decode,

                -- Return an iterator to decode the target string or text reader
                Decodes                 = function (str, startp)
                    if type(str) == "string" then
                        return decodes, str, startp
                    elseif istype(str, TextReader) then
                        return IterReaderDecoding(decode, str, strategy, block)
                    else
                        error("Usage: " .. name .. ".Decodes(string|System.Text.TextReader[, start])", 2)
                    end
                end,

                -- Return an iterator to encode unicode code points from another iterator or list
                Encodes                 = function (codes, arg1, arg2)
                    local ty            = type(codes)
                    if ty == "function" then
                        -- pass
                    elseif ty  == "table" then
                        if istype(codes, Iterable) then
                            codes, arg1, arg2 = codes:GetIterator()
                        else
                            codes, arg1, arg2 = ipairs(codes)
                        end
                    else
                        error("Usage: " .. name .. ".Encodes(table|iterator, ...)", 2)
                    end

                    return IterEncoding(encode, codes, arg1, arg2)
                end
            },
            __newindex                  = Toolset.readonly,
            __tostring                  = Namespace.GetNamespaceName,
            __metatable                 = encoding,
        })
    end

    encoding                            = Prototype (ValidateType, {
        __index                         = {
            ["IsImmutable"]             = function() return true, true end;
            ["ValidateValue"]           = function(_, value) return getmetatable(value) == encoding and value ~= encoding and value end;
            ["Validate"]                = function(value)    return getmetatable(value) == encoding and value ~= encoding and value end;
        },
        __newindex                      = Toolset.readonly,
        __call                          = function(self, name)
            if type(name) ~= "string" then error("Usage: System.Text.Encoding \"name\" { decode = Function, encode = Function[, strategy = TextReaderStrategy] }", 2) end
            return function(settings)
                local ret, err          = validateValue(EncodingDefinition, settings, true)
                if not ret or err then error("Usage: System.Text.Encoding \"name\" { decode = Function, encode = Function[, strategy = TextReaderStrategy] }", 2) end

                local coder             = newEncoding(name, ret)
                return coder
            end
        end,
        __tostring                      = Namespace.GetNamespaceName,
    })

    --- Represents a character encoding
    Namespace.SaveNamespace("System.Text.Encoding", encoding)

    --- Represents the ASCII encoding
    System.Text.Encoding "ASCIIEncoding" {
        encode                          = string.char,
        decode                          = string.byte,
        strategy                        = TextReaderStrategy.CHAR,
    }

    -----------------------------------------------------------------------
    --                         Encoder & Decoder                         --
    -----------------------------------------------------------------------
    __Iterator__()
    function IterReaderEncoder(encode, reader, strategy, block, ...)
        for i, str in iterReader(reader, strategy, block) do
            for res in RunIterator(encode, str, ...) do
                yield(res)
            end
        end
    end

    local encoder
    local newEncoder                    = function (name, settings)
        local encode                    = settings.encode
        local decode                    = settings.decode
        local strategy                  = settings.strategy
        local block                     = settings.block

        if not name:find(".", 1, true)  then name = "System.Text." .. name end
        if Namespace.GetNamespace(name) then error("The " .. name .. " is already existed", 3) end

        local usageDecode               = "Usage: " .. name .. ".Decode([TextWriter,] String + TextReader, ...)"
        local usageEncode               = "Usage: " .. name .. ".Encode([TextWriter,] String + TextReader, ...)"

        return Namespace.SaveNamespace(name, Prototype {
            __index                     = {
                -- Decode string or string from a reader to an iterator
                Decodes                 = strategy == TextReaderStrategy.READER and function(reader, arg1, arg2, ...)
                    local treader       = type(reader)
                    if treader == "string" then
                        reader          = StringReader(reader)
                    elseif treader == "function" then
                        return RunIterator(decode, IteratorReader(reader, arg1, arg2), ...)
                    end
                    if istype(reader, TextReader) then
                        return RunIterator(decode, reader, arg1, arg2, ...)
                    else
                        error("Usage: " .. name .. ".Decodes(string|System.Text.TextReader)", 2)
                    end
                end or function(str, arg1, arg2, ...)
                    local tstr          = type(str)
                    if tstr == "string" then
                        return RunIterator(decode, str, arg1, arg2, ...)
                    elseif tstr == "function" then
                        return IterReaderEncoder(decode, IteratorReader(str, arg1, arg2), strategy, block, ...)
                    elseif istype(str, TextReader) then
                        return IterReaderEncoder(decode, str, strategy, block, arg1, arg2, ...)
                    else
                        error("Usage: " .. name .. ".Decodes(string|System.Text.TextReader)", 2)
                    end
                end,

                -- Encode string or string from a reader to an iterator
                Encodes                 = strategy == TextReaderStrategy.READER and function(reader, arg1, arg2, ...)
                    local treader       = type(reader)
                    if treader == "string" then
                        reader          = StringReader(reader)
                    elseif treader == "function" then
                        return RunIterator(encode, IteratorReader(reader, arg1, arg2), ...)
                    end
                    if istype(reader, TextReader) then
                        return RunIterator(encode, reader, arg1, arg2, ...)
                    else
                        error("Usage: " .. name .. ".Encodes(string|System.Text.TextReader)", 2)
                    end
                end or function(str, arg1, arg2, ...)
                    local tstr          = type(str)
                    if tstr == "string" then
                        return RunIterator(encode, str, arg1, arg2, ...)
                    elseif tstr == "function" then
                        return IterReaderEncoder(encode, IteratorReader(str, arg1, arg2), strategy, block, ...)
                    elseif istype(str, TextReader) then
                        return IterReaderEncoder(encode, str, strategy, block, arg1, arg2, ...)
                    else
                        error("Usage: " .. name .. ".Encodes(string|System.Text.TextReader)", 2)
                    end
                end,

                -- Decode string or string from a reader
                Decode                  = strategy == TextReaderStrategy.READER and function(reader, arg1, arg2, ...)
                    local treader       = type(reader)
                    local isIter        = false
                    if treader == "string" then
                        reader          = StringReader(reader)
                    elseif treader == "function" then
                        isIter          = true
                        reader          = IteratorReader(reader, arg1, arg2)
                    end
                    if istype(reader, TextReader) then
                        local w         = StringWriter()
                        w:Open()

                        if isIter then
                            for res in RunIterator(decode, reader, ...) do
                                w:Write(res)
                            end
                        else
                            for res in RunIterator(decode, reader, arg1, arg2, ...) do
                                w:Write(res)
                            end
                        end

                        w:Close()
                        return w:ToString()
                    else
                        error("Usage: " .. name .. ".Decode(string|System.Text.TextReader)", 2)
                    end
                end or function (str, arg1, arg2, ...)
                    local tstr          = type(str)
                    if tstr == "string" then
                        local w         = StringWriter()
                        w:Open()

                        for res in RunIterator(decode, str, arg1, arg2, ...) do
                            w:Write(res)
                        end

                        w:Close()
                        return w:ToString()
                    elseif tstr == "function" then
                        local w         = StringWriter()
                        w:Open()

                        for res in IterReaderEncoder(decode, IteratorReader(str, arg1, arg2), strategy, block, ...) do
                            w:Write(res)
                        end

                        w:Close()
                        return w:ToString()
                    elseif istype(str, TextReader) then
                        local w         = StringWriter()
                        w:Open()

                        for res in IterReaderEncoder(decode, str, strategy, block, arg1, arg2, ...) do
                            w:Write(res)
                        end

                        w:Close()
                        return w:ToString()
                    else
                        error("Usage: " .. name .. ".Decode(string|System.Text.TextReader)", 2)
                    end
                end,

                -- Encode string or string from a reader
                Encode                  = strategy == TextReaderStrategy.READER and function(reader, arg1, arg2, ...)
                    local treader       = type(reader)
                    local isIter        = false
                    if treader == "string" then
                        reader          = StringReader(reader)
                    elseif treader == "function" then
                        isIter          = true
                        reader          = IteratorReader(reader, arg1, arg2)
                    end
                    if istype(reader, TextReader) then
                        local w         = StringWriter()
                        w:Open()

                        if isIter then
                            for res in RunIterator(encode, reader, ...) do
                                w:Write(res)
                            end
                        else
                            for res in RunIterator(encode, reader, arg1, arg2, ...) do
                                w:Write(res)
                            end
                        end

                        w:Close()
                        return w:ToString()
                    else
                        error("Usage: " .. name .. ".Encode(string|System.Text.TextReader)", 2)
                    end
                end or function (str, arg1, arg2, ...)
                    local tstr          = type(str)
                    if tstr == "string" then
                        local w         = StringWriter()
                        w:Open()

                        for res in RunIterator(encode, str, arg1, arg2, ...) do
                            w:Write(res)
                        end

                        w:Close()
                        return w:ToString()
                    elseif tstr == "function" then
                        local w         = StringWriter()
                        w:Open()

                        for res in IterReaderEncoder(encode, IteratorReader(str, arg1, arg2), strategy, block, ...) do
                            w:Write(res)
                        end

                        w:Close()
                        return w:ToString()
                    elseif istype(str, TextReader) then
                        local w         = StringWriter()
                        w:Open()

                        for res in IterReaderEncoder(encode, str, strategy, block, arg1, arg2, ...) do
                            w:Write(res)
                        end

                        w:Close()
                        return w:ToString()
                    else
                        error("Usage: " .. name .. ".Encode(string|System.Text.TextReader)", 2)
                    end
                end,
            },
            __newindex                  = Toolset.readonly,
            __tostring                  = Namespace.GetNamespaceName,
            __metatable                 = encoder,
        })
    end

    encoder                             = Prototype (ValidateType, {
        __index                         = {
            ["IsImmutable"]             = function() return true, true end;
            ["ValidateValue"]           = function(_, value) return getmetatable(value) == encoder and value ~= encoder and value end;
            ["Validate"]                = function(value)    return getmetatable(value) == encoder and value ~= encoder and value end;
        },
        __newindex                      = Toolset.readonly,
        __call                          = function(self, name)
            if type(name) ~= "string" then error("Usage: System.Text.Encoder \"name\" { decode = Function, encode = Function[, strategy = TextReaderStrategy] }", 2) end
            return function(settings)
                local ret, err          = validateValue(EncodingDefinition, settings, true)
                if not ret or err then error("Usage: System.Text.Encoder \"name\" { decode = Function, encode = Function[, strategy = TextReaderStrategy] }", 2) end

                local coder             = newEncoder(name, ret)
                return coder
            end
        end,
        __tostring                      = Namespace.GetNamespaceName,
    })

    --- Represents a character encoder
    Namespace.SaveNamespace("System.Text.Encoder", encoder)

    -----------------------------------------------------------------------
    --                          Reader & Writer                          --
    -----------------------------------------------------------------------
    --- Represents a writer that can write a sequential series of characters
    __Sealed__()
    class "TextWriter"                  (function (_ENV)
        extend "IAutoClose"

        --- Gets the character encoding in which the output is written.
        __Abstract__()
        property "Encoding"             { type = System.Text.Encoding }

        --- Gets or sets the line terminator string used by the current TextWriter.
        __Abstract__()
        property "NewLine"              { type = String, default = "\n" }

        --- Clears all buffers for the current writer and causes any buffered data to be written to the underlying device.
        __Abstract__()
        function Flush(self) end

        --- Writes the data to the text string or stream.
        __Abstract__()
        function Write(self, data) end

        --- Writes the data(could be nil) followed by a line terminator to the text string or stream.
        __Abstract__()
        function WriteLine(self, data) if data then self:Write(data) end self:Write(self.NewLine) end
    end)

    --- Represents a reader that can read a sequential series of characters
    __Sealed__()
    class "TextReader"                  (function (_ENV)
        extend "IAutoClose"

        --- Gets the character encoding in which the input is read.
        __Abstract__()
        property "Encoding"             { type = System.Text.Encoding }

        --- Gets or Sets the operation position
        __Abstract__()
        property "Position"             { type = Number }

        --- Reads the next character from the text reader and advances the character position by one character.
        __Abstract__()
        function Read(self) end

        --- Reads a line of characters from the text reader and returns the data as a string.
        __Abstract__()
        function ReadLine(self) end

        --- Return the ReadLine method and self for a generic for
        function ReadLines(self) return self.ReadLine, self end

        --- Reads a specified maximum number of characters from the current text reader and writes the data to a buffer, beginning at the specified index.
        __Abstract__()
        function ReadBlock(self, count, index) end

        --- Reads all characters from the current position to the end of the text reader and returns them as one string.
        __Abstract__()
        function ReadToEnd(self) end
    end)

    -----------------------------------------------------------------------
    --                      String Reader & Writer                       --
    -----------------------------------------------------------------------
    --- Represents a text writer that can write a sequential series of characters to string
    __Sealed__()
    class "StringWriter"                (function(_ENV)
        inherit "TextWriter"

        export                          {
            tconcat                     = table.concat,
            wipe                        = Toolset.wipe,
        }

        field                           {
            temp                        = false,
            count                       = 0,
        }

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- the final result
        property "Result"               { set = false, field = 0 }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        __Arguments__{ String }
        function Write(self, text)
            local cnt                   = self.count + 1
            self.count                  = cnt
            self.temp[cnt]              = text
        end

        function Open(self)
            self.temp                   = {}
            self.count                  = 0
        end

        function Close(self)
            self[0]                     = tconcat(self.temp)
            self.temp                   = false
            self.count                  = 0
        end

        function ToString(self)
            return self.Result
        end

        -----------------------------------------------------------
        --                      meta-method                      --
        -----------------------------------------------------------
        function __tostring(self)
            return self.Result
        end
    end)

    --- Represents a text reader that can read a sequential series of characters from string
    __Sealed__()
    class "StringReader"                (function(_ENV)
        inherit "TextReader"

        export {
            strsub                      = string.sub,
            strfind                     = string.find,
            strmatch                    = string.match,
            floor                       = math.floor,
            min                         = math.min,
            max                         = math.max,
        }

        --- Gets or sets the position. negative number means start from the end of the file.
        property "Position"             {
            type = Number,
            field                       = "__seekpos",
            set                         = function(self, pos)
                pos                     = floor(pos)
                if pos < 0 then
                    self.__seekpos      = min(max(0, self.__length + pos), self.__length)
                else
                    self.__seekpos      = min(pos, self.__length)
                end
            end,
        }

        --- Whether discard the indent at the head of the each line
        property "DiscardIndents"       { type = Boolean, default = false }

        -- Method
        function Read(self)
            self.__skipindent           = false -- only skip indent when keeping read line

            local pos                   = self.__seekpos + 1
            if pos <= self.__length then
                self.__seekpos          = pos
                return strsub(self.__content, pos, pos)
            end
        end

        function ReadLine(self)
            local pos                   = self.__seekpos + 1
            if pos <= self.__length then
                local nxtl, endl        = strfind(self.__content, "\n", pos)
                local line
                if nxtl then
                    self.__seekpos      = endl
                    line                = strsub(self.__content, pos, nxtl - 1)
                else
                    self.__seekpos      = self.__length
                    line                = strsub(self.__content, pos)
                end
                if self.__skipindent == -1 then
                    self.__skipindent   = self.DiscardIndents and strmatch(line, "^%s+") or false
                end

                if self.__skipindent then
                    if line:find(self.__skipindent, 1, true) then
                        line            = line:sub(#self.__skipindent + 1)
                    end
                end

                return line
            end
        end

        function ReadToEnd(self)
            self.__skipindent           = false -- only skip indent when keeping read line

            local pos                   = self.__seekpos + 1
            if pos <= self.__length then
                self.__seekpos          = self.__length
                return strsub(self.__content, pos)
            end
        end

        function ReadBlock(self, count, index)
            self.__skipindent           = false -- only skip indent when keeping read line

            if index then self.Position = index end

            local pos                   = self.__seekpos + 1
            if pos <= self.__length then
                self.__seekpos          = min(self.__length, pos + count - 1)
                return strsub(self.__content, pos, self.__seekpos)
            end
        end

        -- Constructor
        __Arguments__{ String }
        function __new(_, str)
            return {
                __content               = str,
                __length                = #str,
                __seekpos               = 0,
                __skipindent            = -1,
            }, true
        end
    end)

    -----------------------------------------------------------------------
    --                          Iterator Reader                          --
    -----------------------------------------------------------------------
    --- Represents a text reader that can read a sequential series of characters from iterator
    __Sealed__()
    class "IteratorReader"              (function(_ENV)
        inherit "TextReader"

        export {
            strsub                      = string.sub,
            strfind                     = string.find,
            strmatch                    = string.match,
            tblconcat                   = table.concat,
            floor                       = math.floor,
            min                         = math.min,
            max                         = math.max,
            type                        = type,
            error                       = error,
        }

        local function getNextPos(self)
            local pos                   = self.__startpos + 1
            local text                  = self[self.__currindex]

            while not text or pos > #text do
                if self.__currindex < #self then
                    self.__currindex    = self.__currindex + 1
                    text                = self[self.__currindex]
                else
                    local k, v          = self.__iter(self.__target, self.__index)
                    v                   = v or k
                    if type(v) ~= "string" then return end
                    self.__index        = k
                    text                = v
                    self.__currindex    = self.__currindex + 1
                    self[self.__currindex] = text
                end

                self.__startpos         = 0
                pos                     = 1
            end

            return text, pos
        end

        --- Gets the position
        property "Position"             {
            type = Number,
            field                       = "__seekpos",
            set                         = function(self, index)
                if index < self.__seekpos then
                    if index < 0 then
                        index           = 0
                    end

                    local offset        = self.__seekpos - index
                    self.__seekpos      = index

                    local currindex     = self.__currindex
                    while currindex > 0 do
                        if self.__startpos >= offset then
                            self.__startpos = self.__startpos - offset
                            return
                        else
                            offset      = offset - self.__startpos
                            currindex   = currindex - 1
                            self.__currindex = currindex
                            self.__startpos  = currindex > 0 and #self[currindex] or 0
                        end
                    end
                elseif index > self.__seekpos then
                    return self:ReadBlock(index - self.__seekpos)
                end
            end,
        }

        -- Method
        function Read(self)
            local text, pos             = getNextPos(self)
            if not text then return end

            self.__seekpos              = self.__seekpos + 1
            self.__startpos             = pos
            return strsub(text, pos, pos)
        end

        function ReadLine(self)
            local text, pos             = getNextPos(self)
            if not text then return end

            local nxtl                  = strfind(text, "\n", pos)
            if nxtl then
                self.__seekpos          = self.__seekpos + nxtl - pos + 1
                self.__startpos         = nxtl
                return strsub(text, pos, nxtl - 1)
            else
                line                    = strsub(text, pos)
                self.__seekpos          = self.__seekpos + #line
                self.__startpos         = #text
                return strsub(text, pos)
            end
        end

        function ReadToEnd(self)
            local text, pos             = getNextPos(self)
            if not text then return end

            local temp                  = {}
            local index                 = 1
            while text do
                local block             = pos == 1 and text or strsub(text, pos)
                temp[index]             = block
                self.__seekpos          = self.__seekpos + #block
                self.__startpos         = #text

                index                   = index + 1
                text, pos               = getNextPos(self)
            end
            return tblconcat(temp)
        end

        function ReadBlock(self, count, index)
            if index then self.Position = index end

            local text, pos             = getNextPos(self)
            if not text then return end

            local temp                  = {}
            local index                 = 1
            while text do
                local len               = #text
                local stop              = pos + count - 1

                if len >= stop then
                    temp[index]         = strsub(text, pos, stop)
                    self.__seekpos      = self.__seekpos + count
                    self.__startpos     = stop
                    break
                else
                    self.__startpos     = len
                    len                 = len - pos + 1
                    temp[index]         = pos == 1 and text or strsub(text, pos)
                    self.__seekpos      = self.__seekpos + len
                    count               = count - len
                end

                index                   = index + 1
                text, pos               = getNextPos(self)
            end
            return tblconcat(temp)
        end

        -- Constructor
        __Arguments__{ Function, Any/nil, Any/nil }
        function __new(_, iter, target, index)
            return {
                __iter                  = iter,
                __target                = target,
                __index                 = index,
                __seekpos               = 0,
                __currindex             = 0,
                __startpos              = 0,
            }, true
        end
    end)
end)
