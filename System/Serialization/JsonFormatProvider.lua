--===========================================================================--
--                                                                           --
--                  System.Serialization.JsonFormatProvider                  --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2015/05/26                                               --
-- Update Date  :   2021/08/09                                               --
-- Version      :   1.0.4                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Serialization"

    import "System.Text"

    export {
        pcall                           = pcall,
        error                           = error,
        type                            = type,
        pairs                           = pairs,
        ipairs                          = ipairs,
        tostring                        = tostring,
        tonumber                        = tonumber,
        getmetatable                    = getmetatable,
        next                            = next,
        floor                           = math.floor,
        mhuge                           = math.huge,
        BIG_NUMBER                      = 10^12,
        tinsert                         = table.insert,
        tremove                         = table.remove,
        tblconcat                       = table.concat,
        strbyte                         = string.byte,
        strchar                         = string.char,
        strsub                          = string.sub,
        strformat                       = string.format,
        strtrim                         = Toolset.trim,
        isnamespace                     = Namespace.Validate,
        Serialize                       = Serialization.Serialize,
        Deserialize                     = Serialization.Deserialize,

        LUA_VERSION                     = tonumber(_G._VERSION:match("[%d%.]+")) or 5.1,
        Serialization, List,

        -- Declare the global variables
        isArrayData                     = Serialization.IsArrayData,

        isArray                         = false,
        SerializeSimpleData             = false,
        SerializeDataWithWriteNoIndent  = false,
        SerializeDataWithWrite          = false,
        SerializeDataWithWriterNoIndent = false,
        SerializeDataWithWriter         = false,
    }

    -----------------------------------
    -- Serialize
    -----------------------------------
    do
        function isArray(data)
            local res                   = isArrayData(data)
            data[Serialization.ObjectTypeField] = nil
            return res
        end

        function SerializeSimpleData(data)
            if data == nil then return "null" end

            local dtType                = type(data)

            if dtType == "string" then
                -- For simple condition
                return strformat("%q", data)
            elseif dtType == "number" then
                -- Number
                if data ~= data then
                    -- nan(0/0)
                    return "null"
                elseif data >= mhuge then
                    return "1e+999"
                elseif data <= -mhuge then
                    return "-1e+999"
                else
                    return tostring(data)
                end
            elseif dtType == "boolean" then
                return tostring(data)
            elseif isnamespace(data) then
                return strformat("%q", tostring(data))
            end
        end

        function SerializeDataWithWriteNoIndent(data, write)
            if isArray(data) then
                write("[")

                local count             = #data

                for i = 1, count do
                    local v             = data[i]
                    if type(v) == "table" and getmetatable(v) == nil then
                        SerializeDataWithWriteNoIndent(v, write)
                        if i < count then write(",") end
                    else
                        if i < count then
                            write(strformat("%s,", SerializeSimpleData(v)))
                        else
                            write(strformat("%s", SerializeSimpleData(v)))
                        end
                    end
                end

                write("]")
            else
                write("{")

                local k, v              = next(data)
                local nk, nv

                while k do
                    nk, nv              = next(data, k)

                    if type(v) == "table" and getmetatable(v) == nil then
                        write(strformat("%q:", k))
                        SerializeDataWithWriteNoIndent(v, write)
                        if nk then write(",") end
                    else
                        if nk then
                            write(strformat("%q:%s,", k, SerializeSimpleData(v)))
                        else
                            write(strformat("%q:%s", k, SerializeSimpleData(v)))
                        end
                    end

                    k, v                = nk, nv
                end

                write("}")
            end
        end

        function SerializeDataWithWrite(data, write, indentChar, preIndentChar, lineBreak)
            if isArray(data) then
                write("[" .. lineBreak)

                local subIndentChar     = preIndentChar .. indentChar
                local count             = #data

                for i = 1, count do
                    local v             = data[i]
                    if type(v) == "table" and getmetatable(v) == nil then
                        write(subIndentChar)
                        SerializeDataWithWrite(v, write, indentChar, subIndentChar, lineBreak)
                        if i < count then
                            write("," .. lineBreak)
                        else
                            write(lineBreak)
                        end
                    else
                        if i < count then
                            write(strformat("%s%s,%s", subIndentChar, SerializeSimpleData(v), lineBreak))
                        else
                            write(strformat("%s%s%s", subIndentChar, SerializeSimpleData(v), lineBreak))
                        end
                    end
                end

                write(preIndentChar .. "]")
            else
                write("{" .. lineBreak)

                local k, v              = next(data)
                local nk, nv
                local subIndentChar     = preIndentChar .. indentChar

                while k do
                    nk, nv              = next(data, k)

                    if type(v) == "table" and getmetatable(v) == nil then
                        write(strformat("%s%q : ", subIndentChar, k))
                        SerializeDataWithWrite(v, write, indentChar, subIndentChar, lineBreak)
                        if nk then
                            write("," .. lineBreak)
                        else
                            write(lineBreak)
                        end
                    else
                        if nk then
                            write(strformat("%s%q : %s,%s", subIndentChar, k, SerializeSimpleData(v), lineBreak))
                        else
                            write(strformat("%s%q : %s%s", subIndentChar, k, SerializeSimpleData(v), lineBreak))
                        end
                    end

                    k, v                = nk, nv
                end

                write(preIndentChar .. "}")
            end
        end

        function SerializeDataWithWriterNoIndent(data, write, object)
            if isArray(data) then
                write(object, "[")

                local count             = #data

                for i = 1, count do
                    local v             = data[i]
                    if type(v) == "table" and getmetatable(v) == nil then
                        SerializeDataWithWriterNoIndent(v, write, object)
                        if i < count then write(object, ",") end
                    else
                        if i < count then
                            write(object, strformat("%s,", SerializeSimpleData(v)))
                        else
                            write(object, strformat("%s", SerializeSimpleData(v)))
                        end
                    end
                end

                write(object, "]")
            else
                write(object, "{")

                local k, v              = next(data)
                local nk, nv

                while k do
                    nk, nv              = next(data, k)

                    if type(v) == "table" and getmetatable(v) == nil then
                        write(object, strformat("%q:", k))
                        SerializeDataWithWriterNoIndent(v, write, object)
                        if nk then write(object, ",") end
                    else
                        if nk then
                            write(object, strformat("%q:%s,", k, SerializeSimpleData(v)))
                        else
                            write(object, strformat("%q:%s", k, SerializeSimpleData(v)))
                        end
                    end

                    k, v                = nk, nv
                end

                write(object, "}")
            end
        end

        function SerializeDataWithWriter(data, write, object, indentChar, preIndentChar, lineBreak)
            if isArray(data) then
                write(object, "[" .. lineBreak)

                local subIndentChar     = preIndentChar .. indentChar
                local count             = #data

                for i = 1, count do
                    local v             = data[i]
                    if type(v) == "table" and getmetatable(v) == nil then
                        write(object, subIndentChar)
                        SerializeDataWithWriter(v, write, object, indentChar, subIndentChar, lineBreak)
                        if i < count then
                            write(object, "," .. lineBreak)
                        else
                            write(object, lineBreak)
                        end
                    else
                        if i < count then
                            write(object, strformat("%s%s,%s", subIndentChar, SerializeSimpleData(v), lineBreak))
                        else
                            write(object, strformat("%s%s%s", subIndentChar, SerializeSimpleData(v), lineBreak))
                        end
                    end
                end

                write(object, preIndentChar .. "]")
            else
                write(object, "{" .. lineBreak)

                local k, v              = next(data)
                local nk, nv
                local subIndentChar     = preIndentChar .. indentChar

                while k do
                    nk, nv              = next(data, k)

                    if type(v) == "table" and getmetatable(v) == nil then
                        write(object, strformat("%s%q : ", subIndentChar, k))
                        SerializeDataWithWriter(v, write, object, indentChar, subIndentChar, lineBreak)
                        if nk then
                            write(object, "," .. lineBreak)
                        else
                            write(object, lineBreak)
                        end
                    else
                        if nk then
                            write(object, strformat("%s%q : %s,%s", subIndentChar, k, SerializeSimpleData(v), lineBreak))
                        else
                            write(object, strformat("%s%q : %s%s", subIndentChar, k, SerializeSimpleData(v), lineBreak))
                        end
                    end

                    k, v                = nk, nv
                end

                write(object, preIndentChar .. "}")
            end
        end
    end

    -----------------------------------
    -- Deserialize
    -----------------------------------
    do
        -- Use UTF-8 as the output encode
        export {
            EncodeData                  = UTF8Encoding.Encode,
            UTF16LEDecodes              = UTF16EncodingLE.Decodes,
            UTF16BEDecodes              = UTF16EncodingBE.Decodes,

            _ESCAPE_CHAR                = {
                [ 0x22 ]                = strchar( 0x22 ), -- " quotation mark
                [ 0x5C ]                = strchar( 0x5C ), -- \ reverse solidus
                [ 0x2F ]                = strchar( 0x2F ), -- / solidus
                [ 0x62 ]                = strchar( 0x08 ), -- b backspace
                [ 0x66 ]                = strchar( 0x0C ), -- f form feed
                [ 0x6E ]                = strchar( 0x0A ), -- n line feed
                [ 0x72 ]                = strchar( 0x0D ), -- r carriage return
                [ 0x74 ]                = strchar( 0x09 ), -- t tab
            },

            _NumberCode                 = {
                [0x65]                  = true,
                [0x45]                  = true,
                [0x2b]                  = true,
                [0x2d]                  = true,
                [0x2e]                  = true,
                [0x30]                  = true,
                [0x31]                  = true,
                [0x32]                  = true,
                [0x33]                  = true,
                [0x34]                  = true,
                [0x35]                  = true,
                [0x36]                  = true,
                [0x37]                  = true,
                [0x38]                  = true,
                [0x39]                  = true,
            },

            ERR_MSG_NOTFINISHED         = "Unfinished json data.",
            ERR_MSG_UNEXPECTED          = "Unexpected char found at %d of the json.",
            ERR_MSG_NOT_NUMBER          = "%q is not a valid number at %d of the json.",
            ERR_MSG_TRUE                = "true is expected at %d of the json.",
            ERR_MSG_FALSE               = "false is expected at %d of the json.",
            ERR_MSG_NULL                = "null is expected at %d of the json.",

            ERR_MSG_CLOSE_ARR           = "']' is expected to close the array started at %d of the json.",
            ERR_MSG_EXPECT_VALUE        = "A value is expected at %d of the json.",
            ERR_MSG_EXPECT_COMMA        = "',' is expected at %d of the json.",

            ERR_MSG_CLOSE_OBJ           = "'}' is expected to close the object started at %d of the json.",
            ERR_MSG_END                 = "object is not well closed at %d of the json.",
            ERR_MSG_EXPECT_KEY          = "A string name is expected at %d of the json.",
            ERR_MSG_EXPECT_COLON        = "':' is expected at %d of the json.",
            ERR_MSG_STRING_POS          = "The string value can't be used at %d of the json.",
            ERR_MSG_VALUE_POS           = "The value can't be used at %d of the json.",

            ERR_MSG_ESCAPE_CHAR         = "Unexpected escape char at %d of the json.",

            ERR_MSG_CLOSE_STR           = "'\"' is expected to close the string started at %d of the json.",
        }

        ------------------------------
        -- Load Json For Any Encoding
        ------------------------------
        function LoadJsonObject(self, iter, json, nxtp, code, jsonIndex)
            local obj                   = {}
            local startIndex, token, prevToken, key, value
            local pos                   = jsonIndex

            -- 0 : DEFAULT - "key" -> 1
            -- 1 : KEY - ":" -> 2
            -- 2 : SEP - 123 -> 3
            -- 3 : VALUE - , -> 0
            prevToken                   = 0

            startIndex, token, nxtp, value, jsonIndex = LoadJsonData(self, iter, json, nxtp, jsonIndex)

            while token do
                if token == 4 then
                    if value == 0x7d then
                        if not(prevToken == 0 or prevToken == 3) then error(ERR_MSG_END:format(startIndex)) end
                        return 2, nxtp, obj, jsonIndex
                    elseif value == 0x3a then
                        if prevToken ~= 1 then error(ERR_MSG_EXPECT_KEY:format(startIndex)) end
                        prevToken       = 2
                    elseif value == 0x2c then
                        if prevToken ~= 3 then error(ERR_MSG_EXPECT_VALUE:format(startIndex)) end
                        prevToken       = 0
                    else
                        error(ERR_MSG_UNEXPECTED:format(startIndex))
                    end
                elseif token == 3 then
                    if prevToken == 0 then
                        prevToken       = 1
                        key             = value
                    elseif prevToken == 2 then
                        prevToken       = 3
                        obj[key]        = value
                    else
                        error(ERR_MSG_STRING_POS:format(startIndex))
                    end
                elseif token == 2 then
                    if prevToken ~= 2 then error(ERR_MSG_EXPECT_COLON:format(startIndex)) end
                    prevToken           = 3
                    obj[key]            = value
                end

                startIndex, token, nxtp, value, jsonIndex = LoadJsonData(self, iter, json, nxtp, jsonIndex)
            end

            error(ERR_MSG_CLOSE_OBJ:format(pos))
        end

        function LoadJsonArray(self, iter, json, nxtp, code, jsonIndex)
            local arr                   = {}
            local startIndex, token, prevToken, value
            local pos                   = jsonIndex

            -- 0 : DEFAULT - 123 -> 1
            -- 1 : VALUE - , -> 0
            prevToken                   = 0

            startIndex, token, nxtp, value, jsonIndex = LoadJsonData(self, iter, json, nxtp, jsonIndex)

            while token do
                if token == 4 then
                    if value == 0x5d then
                        return 2, nxtp, arr, jsonIndex
                    elseif value == 0x2c then
                        if prevToken ~= 1 then error(ERR_MSG_EXPECT_VALUE:format(startIndex)) end
                        prevToken       = 0
                    else
                        error(ERR_MSG_UNEXPECTED:format(startIndex))
                    end
                elseif token == 3 or token == 2 then
                    if prevToken ~= 0 then error(ERR_MSG_EXPECT_COMMA:format(startIndex)) end
                    prevToken           = 1
                    if value ~= nil then tinsert(arr, value) end
                else
                    error(ERR_MSG_UNEXPECTED:format(startIndex))
                end

                startIndex, token, nxtp, value, jsonIndex = LoadJsonData(self, iter, json, nxtp, jsonIndex)
            end

            error(ERR_MSG_CLOSE_ARR:format(pos))
        end

        function LoadJsonString(self, iter, json, nxtp, code, jsonIndex)
            local cache                 = self()
            local pos                   = jsonIndex

            nxtp, code                  = iter(json, nxtp)
            jsonIndex                   = jsonIndex + 1

            while code do
                if code == 0x22 then
                    local ret           = tblconcat(cache)
                    self(cache)
                    return 3, nxtp, ret, jsonIndex
                elseif code == 0x5c then
                    nxtp, code          = iter(json, nxtp)
                    jsonIndex           = jsonIndex + 1

                    local chr           = _ESCAPE_CHAR[code]
                    if chr then
                        tinsert(cache, chr)
                    elseif code == 0x75 then
                        -- Unicode codepoint
                        local high      = ""
                        local savep     = nxtp
                        local savei     = jsonIndex

                        for i = 1, 4 do
                            nxtp, code  = iter(json, nxtp)
                            jsonIndex   = jsonIndex + 1

                            high        = high .. EncodeData(code)
                        end

                        local codePoint = tonumber(high, 16)
                        if codePoint then
                            if codePoint >= 0xD800 and codePoint <= 0xDBFF then
                                nxtp, code  = iter(json, nxtp)
                                jsonIndex   = jsonIndex + 1
                                savep       = nxtp
                                savei       = jsonIndex

                                if code == 0x5c then
                                    nxtp, code          = iter(json, nxtp)
                                    jsonIndex           = jsonIndex + 1

                                    if code == 0x75 then
                                        local low       = ""

                                        for i = 1, 4 do
                                            nxtp, code  = iter(json, nxtp)
                                            jsonIndex   = jsonIndex + 1

                                            low         = low .. EncodeData(code)
                                        end

                                        local lowCp     = tonumber(low, 16)
                                        if lowCp and lowCp >= 0xDC00 and lowCp <= 0xDFFF then
                                            codePoint   = 0x2400 + (codePoint - 0xD800) * 0x400 + lowCp

                                            tinsert(cache, EncodeData(codePoint))
                                        else
                                            tinsert(cache, "\\u")
                                            tinsert(cache, high)

                                            nxtp        = savep
                                            jsonIndex   = savei
                                        end
                                    else
                                        tinsert(cache, "\\u")
                                        tinsert(cache, high)

                                        nxtp            = savep
                                        jsonIndex       = savei
                                    end
                                else
                                    tinsert(cache, "\\u")
                                    tinsert(cache, high)

                                    -- roll back
                                    nxtp                = savep
                                    jsonIndex           = savei
                                end
                            else
                                tinsert(cache, EncodeData(codePoint))
                            end
                        else
                            tinsert(cache, "\\u")
                            nxtp        = savep
                            jsonIndex   = savei
                        end
                    else
                        tinsert(cache, "\\")
                        tinsert(cache, EncodeData(code))
                    end
                else
                    tinsert(cache, EncodeData(code))
                end

                nxtp, code              = iter(json, nxtp)
                jsonIndex               = jsonIndex + 1
            end

            error(ERR_MSG_CLOSE_STR:format(pos))
        end

        function LoadJsonNumber(self, iter, json, nxtp, code, jsonIndex)
            local cache                 = self()
            local prev                  = nxtp
            local pos                   = jsonIndex

            while _NumberCode[code] do
                tinsert(cache, EncodeData(code))

                prev                    = nxtp
                nxtp, code              = iter(json, nxtp)
                jsonIndex               = jsonIndex + 1
            end

            local content               = tblconcat(cache)
            self(cache)
            local ret                   = tonumber(content)
            if not ret then error(ERR_MSG_NOT_NUMBER:format(content, pos)) end
            if ret >= BIG_NUMBER or ret <= - BIG_NUMBER then ret = content end
            return 2, prev, ret, jsonIndex
        end

        function LoadJsonBoolean(self, iter, json, nxtp, code, jsonIndex)
            local pos                   = jsonIndex

            if code == 0x74 then
                -- true
                nxtp, code              = iter(json, nxtp)
                jsonIndex               = jsonIndex + 1
                if code ~= 0x72 then error(ERR_MSG_TRUE:format(pos)) end

                nxtp, code              = iter(json, nxtp)
                jsonIndex               = jsonIndex + 1
                if code ~= 0x75 then error(ERR_MSG_TRUE:format(pos)) end

                nxtp, code              = iter(json, nxtp)
                jsonIndex               = jsonIndex + 1
                if code ~= 0x65 then error(ERR_MSG_TRUE:format(pos)) end

                return 2, nxtp, true, jsonIndex
            elseif code == 0x66 then
                -- false
                nxtp, code              = iter(json, nxtp)
                jsonIndex               = jsonIndex + 1
                if code ~= 0x61 then error(ERR_MSG_FALSE:format(pos)) end

                nxtp, code              = iter(json, nxtp)
                jsonIndex               = jsonIndex + 1
                if code ~= 0x6c then error(ERR_MSG_FALSE:format(pos)) end

                nxtp, code              = iter(json, nxtp)
                jsonIndex               = jsonIndex + 1
                if code ~= 0x73 then error(ERR_MSG_FALSE:format(pos)) end

                nxtp, code              = iter(json, nxtp)
                jsonIndex               = jsonIndex + 1
                if code ~= 0x65 then error(ERR_MSG_FALSE:format(pos)) end

                return 2, nxtp, false, jsonIndex
            elseif code == 0x6e then
                -- null
                nxtp, code              = iter(json, nxtp)
                jsonIndex               = jsonIndex + 1
                if code ~= 0x75 then error(ERR_MSG_NULL:format(pos)) end

                nxtp, code              = iter(json, nxtp)
                jsonIndex               = jsonIndex + 1
                if code ~= 0x6c then error(ERR_MSG_NULL:format(pos)) end

                nxtp, code              = iter(json, nxtp)
                jsonIndex               = jsonIndex + 1
                if code ~= 0x6c then error(ERR_MSG_NULL:format(pos)) end

                return 2, nxtp, nil, jsonIndex
            end

            error(ERR_MSG_UNEXPECTED:format(pos))
        end

        export {
            _TokenMap                   = {
                [0x20]                  = 1,
                [0x09]                  = 1,
                [0x0a]                  = 1,
                [0x0d]                  = 1,

                [0x2c]                  = 4,
                [0x3a]                  = 4,
                [0x5d]                  = 4,
                [0x7d]                  = 4,

                [0x74]                  = LoadJsonBoolean,
                [0x66]                  = LoadJsonBoolean,
                [0x6e]                  = LoadJsonBoolean,

                [0x22]                  = LoadJsonString,

                [0x7b]                  = LoadJsonObject,

                [0x5b]                  = LoadJsonArray,

                [0x2d]                  = LoadJsonNumber,
                [0x30]                  = LoadJsonNumber,
                [0x31]                  = LoadJsonNumber,
                [0x32]                  = LoadJsonNumber,
                [0x33]                  = LoadJsonNumber,
                [0x34]                  = LoadJsonNumber,
                [0x35]                  = LoadJsonNumber,
                [0x36]                  = LoadJsonNumber,
                [0x37]                  = LoadJsonNumber,
                [0x38]                  = LoadJsonNumber,
                [0x39]                  = LoadJsonNumber,
            }
        }

        function LoadJsonData(self, iter, json, nxtp, jsonIndex)
            local code

            nxtp, code                  = iter(json, nxtp)
            jsonIndex                   = jsonIndex + 1

            while true do
                local token             = _TokenMap[code]

                if not token then error(ERR_MSG_UNEXPECTED:format(jsonIndex)) end

                if token == 1 then
                    nxtp, code          = iter(json, nxtp)
                    jsonIndex           = jsonIndex + 1
                elseif token == 4 then
                    return jsonIndex, token, nxtp, code, jsonIndex
                else
                    return jsonIndex, token(self, iter, json, nxtp, code, jsonIndex)
                end
            end
        end

        ------------------------------
        -- Load Json For UTF-8
        ------------------------------
        do  -- DecodeUTF8
            function DecodeUTF8(json, nxtp)
                local byte              = strbyte(json, nxtp)
                if not byte then return nil end

                if byte < 0xC2 then
                    -- 1-byte or Error
                    return 1, byte
                elseif byte < 0xE0 then
                    -- 2-byte
                    local sbyte = strbyte(json, nxtp + 1)
                    if not sbyte or floor(sbyte / 0x40) ~= 2 then
                        -- Error
                        return 1, byte
                    end
                    return 2, byte
                elseif byte < 0xF0 then
                    -- 3-byte
                    local sbyte, tbyte = strbyte(json, nxtp + 1, nxtp + 2)
                    if not (sbyte and tbyte) or floor(sbyte / 0x40) ~= 2 or (byte == 0xE0 and sbyte < 0xA0) or floor(tbyte / 0x40) ~= 2 then
                        -- Error
                        return 1, byte
                    end
                    return 3, byte
                elseif byte < 0xF5 then
                    -- 4-byte
                    local sbyte, tbyte, fbyte = strbyte(json, nxtp + 1, nxtp + 3)
                    if not (sbyte and tbyte and fbyte) or floor(sbyte / 0x40) ~= 2 or (byte == 0xF0 and sbyte < 0x90) or (byte == 0xF4 and sbyte >= 0x90) or floor(tbyte / 0x40) ~= 2 or floor(fbyte / 0x40) ~= 2 then
                        -- Error
                        return 1, byte
                    end

                    return 4, byte
                else
                    -- Error
                    return 1, byte
                end
            end

            -- Lua 5.3 - bitwise oper
            if LUA_VERSION >= 5.3 then
                -- Use load since 5.1 & 5.2 can't read the bitwise oper
                DecodeUTF8              = load[[
                    local strbyte   = ...
                    return function (json, nxtp)
                        local byte  = strbyte(json, nxtp)
                        if not byte then return nil end

                        if byte < 0x80 then
                            -- 1-byte
                            return 1, byte
                        elseif byte < 0xC2 then
                            -- Error
                            return 1, byte
                        elseif byte < 0xE0 then
                            -- 2-byte
                            local sbyte = strbyte(json, nxtp + 1)
                            if (sbyte & 0xC0) ~= 0x80 then
                                -- Error
                                return 1, byte
                            end
                            return 2, byte
                        elseif byte < 0xF0 then
                            -- 3-byte
                            local sbyte, tbyte = strbyte(json, nxtp + 1, nxtp + 2)
                            if (sbyte & 0xC0) ~= 0x80 or (byte == 0xE0 and sbyte < 0xA0) or (tbyte & 0xC0) ~= 0x80 then
                                -- Error
                                return 1, byte
                            end
                            return 3, byte
                        elseif byte < 0xF5 then
                            -- 4-byte
                            local sbyte, tbyte, fbyte = strbyte(json, nxtp + 1, nxtp + 3)
                            if (sbyte & 0xC0) ~= 0x80 or (byte == 0xF0 and sbyte < 0x90) or (byte == 0xF4 and sbyte >= 0x90) or (tbyte & 0xC0) ~= 0x80 or (fbyte & 0xC0) ~= 0x80 then
                                -- Error
                                return 1, byte
                            end
                            return 4, byte
                        else
                            return 1, byte
                        end
                    end
                ]](strbyte)
            elseif (LUA_VERSION == 5.2 and type(_G.bit32) == "table") or (LUA_VERSION == 5.1 and type(_G.bit) == "table") then
                local band              = _G.bit32 and bit32.band   or bit.band
                local lshift            = _G.bit32 and bit32.lshift or bit.lshift
                local rshift            = _G.bit32 and bit32.rshift or bit.rshift

                function DecodeUTF8(json, nxtp)
                    local byte          = strbyte(json, nxtp)
                    if not byte then return nil end

                    if byte < 0x80 then
                        -- 1-byte
                        return 1, byte
                    elseif byte < 0xC2 then
                        -- Error
                        return 1, byte
                    elseif byte < 0xE0 then
                        -- 2-byte
                        local sbyte     = strbyte(json, nxtp + 1)
                        if not sbyte or band(sbyte, 0xC0) ~= 0x80 then
                            -- Error
                            return 1, byte
                        end
                        return 2, byte
                    elseif byte < 0xF0 then
                        -- 3-byte
                        local sbyte, tbyte = strbyte(json, nxtp + 1, nxtp + 2)
                        if not(sbyte and tbyte) or band(sbyte, 0xC0) ~= 0x80 or (byte == 0xE0 and sbyte < 0xA0) or band(tbyte, 0xC0) ~= 0x80 then
                            -- Error
                            return 1, byte
                        end
                        return 3, byte
                    elseif byte < 0xF5 then
                        -- 4-byte
                        local sbyte, tbyte, fbyte = strbyte(json, nxtp + 1, nxtp + 3)
                        if not(sbyte and tbyte and fbyte) or band(sbyte, 0xC0) ~= 0x80 or (byte == 0xF0 and sbyte < 0x90) or (byte == 0xF4 and sbyte >= 0x90) or band(tbyte, 0xC0) ~= 0x80 or band(fbyte, 0xC0) ~= 0x80 then
                            -- Error
                            return 1, byte
                        end
                        return 4, byte
                    else
                        return 1, byte
                    end
                end
            end
        end

        function LoadJsonObjectUTF8(self, json, nxtp, code, jsonIndex)
            local obj                   = {}
            local startIndex, token, prevToken, key, value
            local pos                   = jsonIndex

            -- 0 : DEFAULT - "key" -> 1
            -- 1 : KEY - ":" -> 2
            -- 2 : SEP - 123 -> 3
            -- 3 : VALUE - , -> 0
            prevToken                   = 0

            startIndex, token, nxtp, value, jsonIndex = LoadJsonDataUTF8(self, json, nxtp, jsonIndex)

            while token do
                if token == 4 then
                    if value == 0x7d then
                        if not(prevToken == 0 or prevToken == 3) then error(ERR_MSG_END:format(startIndex)) end
                        return 2, nxtp, obj, jsonIndex
                    elseif value == 0x3a then
                        if prevToken ~= 1 then error(ERR_MSG_EXPECT_KEY:format(startIndex)) end
                        prevToken       = 2
                    elseif value == 0x2c then
                        if prevToken ~= 3 then error(ERR_MSG_EXPECT_VALUE:format(startIndex)) end
                        prevToken       = 0
                    else
                        error(ERR_MSG_UNEXPECTED:format(startIndex))
                    end
                elseif token == 3 then
                    if prevToken == 0 then
                        prevToken       = 1
                        key             = value
                    elseif prevToken == 2 then
                        prevToken       = 3
                        obj[key]        = value
                    else
                        error(ERR_MSG_STRING_POS:format(startIndex))
                    end
                elseif token == 2 then
                    if prevToken ~= 2 then error(ERR_MSG_EXPECT_COLON:format(startIndex)) end
                    prevToken           = 3
                    obj[key]            = value
                end

                startIndex, token, nxtp, value, jsonIndex = LoadJsonDataUTF8(self, json, nxtp, jsonIndex)
            end

            error(ERR_MSG_CLOSE_OBJ:format(pos))
        end

        function LoadJsonArrayUTF8(self, json, nxtp, code, jsonIndex)
            local arr                   = {}
            local startIndex, token, prevToken, value
            local pos                   = jsonIndex

            -- 0 : DEFAULT - 123 -> 1
            -- 1 : VALUE - , -> 0
            prevToken                   = 0

            startIndex, token, nxtp, value, jsonIndex = LoadJsonDataUTF8(self, json, nxtp, jsonIndex)

            while token do
                if token == 4 then
                    if value == 0x5d then
                        return 2, nxtp, arr, jsonIndex
                    elseif value == 0x2c then
                        if prevToken ~= 1 then error(ERR_MSG_EXPECT_VALUE:format(startIndex)) end
                        prevToken       = 0
                    else
                        error(ERR_MSG_UNEXPECTED:format(startIndex))
                    end
                elseif token == 3 or token == 2 then
                    if prevToken ~= 0 then error(ERR_MSG_EXPECT_COMMA:format(startIndex)) end
                    prevToken           = 1
                    if value ~= nil then tinsert(arr, value) end
                else
                    error(ERR_MSG_UNEXPECTED:format(startIndex))
                end

                startIndex, token, nxtp, value, jsonIndex = LoadJsonDataUTF8(self, json, nxtp, jsonIndex)
            end

            error(ERR_MSG_CLOSE_ARR:format(pos))
        end

        function LoadJsonStringUTF8(self, json, nxtp, code, jsonIndex)
            local cache
            local step
            local pos                   = jsonIndex
            local startp                = nxtp

            step, code                  = DecodeUTF8(json, nxtp)
            nxtp                        = nxtp + step
            jsonIndex                   = jsonIndex + 1

            while code do
                if step > 1 then
                    -- pass
                elseif code == 0x22 then
                    if cache then
                        tinsert(cache, strsub(json, startp, nxtp - 2))

                        local ret       = tblconcat(cache)
                        self(cache)
                        return 3, nxtp, ret, jsonIndex
                    else
                        return 3, nxtp, strsub(json, startp, nxtp - 2), jsonIndex
                    end
                elseif code == 0x5c then
                    cache               = cache or self()
                    tinsert(cache, strsub(json, startp, nxtp - 2))

                    step, code          = DecodeUTF8(json, nxtp)

                    local chr           = _ESCAPE_CHAR[code]
                    if chr then
                        nxtp            = nxtp + step
                        jsonIndex       = jsonIndex + 1

                        tinsert(cache, chr)
                        startp          = nxtp
                    elseif code == 0x75 then
                        -- Unicode codepoint
                        local high      = strsub(json, nxtp + 1, nxtp + 4)

                        local codePoint = #high == 4 and tonumber(high, 16)
                        if codePoint then
                            nxtp        = nxtp + 5
                            jsonIndex   = jsonIndex + 5

                            if codePoint >= 0xD800 and codePoint <= 0xDBFF then
                                step, code          = DecodeUTF8(json, nxtp)

                                if code == 0x5c then
                                    step, code      = DecodeUTF8(json, nxtp + 1)

                                    if code == 0x75 then
                                        local low   = strsub(json, nxtp + 2, nxtp + 5)

                                        local lowCp = #low == 4 and tonumber(low, 16)
                                        if lowCp and lowCp >= 0xDC00 and lowCp <= 0xDFFF then
                                            codePoint   = 0x2400 + (codePoint - 0xD800) * 0x400 + lowCp

                                            nxtp        = nxtp + 6
                                            jsonIndex   = jsonIndex + 6

                                            tinsert(cache, EncodeData(codePoint))
                                            startp      = nxtp
                                        else
                                            tinsert(cache, "\\u")
                                            tinsert(cache, high)

                                            startp      = nxtp
                                        end
                                    else
                                        tinsert(cache, "\\u")
                                        tinsert(cache, high)

                                        startp      = nxtp
                                    end
                                else
                                    tinsert(cache, "\\u")
                                    tinsert(cache, high)

                                    startp          = nxtp
                                end
                            else
                                tinsert(cache, EncodeData(codePoint))
                                startp  = nxtp
                            end
                        else
                            nxtp        = nxtp + step
                            jsonIndex   = jsonIndex + 1

                            tinsert(cache, "\\u")
                            startp      = nxtp
                        end
                    else
                        tinsert(cache, "\\")
                        startp          = nxtp
                    end
                end

                step, code              = DecodeUTF8(json, nxtp)
                nxtp                    = nxtp + step
                jsonIndex               = jsonIndex + 1
            end

            error(ERR_MSG_CLOSE_STR:format(pos))
        end

        function LoadJsonNumberUTF8(self, json, nxtp, code, jsonIndex)
            local pos                   = jsonIndex
            local startp                = nxtp - 1

            while _NumberCode[code] do
                code                    = strbyte(json, nxtp)
                nxtp                    = nxtp + 1
                jsonIndex               = jsonIndex + 1
            end

            nxtp                        = nxtp - 1
            jsonIndex                   = jsonIndex - 1

            local ct                    = strsub(json, startp, nxtp - 1)
            local ret                   = tonumber(ct)
            if not ret then error(ERR_MSG_NOT_NUMBER:format(ct, pos)) end
            if ret >= BIG_NUMBER or ret <= - BIG_NUMBER then ret = ct end
            return 2, nxtp, ret, jsonIndex
        end

        function LoadJsonBooleanUTF8(self, json, nxtp, code, jsonIndex)
            if code == 0x74 then
                -- true
                if strsub(json, nxtp, nxtp + 2) == "rue" then
                    return 2, nxtp + 3, true, jsonIndex + 3
                else
                    error(ERR_MSG_TRUE:format(jsonIndex))
                end
            elseif code == 0x66 then
                -- false
                if strsub(json, nxtp, nxtp + 3) == "alse" then
                    return 2, nxtp + 4, false, jsonIndex + 4
                else
                    error(ERR_MSG_FALSE:format(jsonIndex))
                end
            elseif code == 0x6e then
                -- null
                if strsub(json, nxtp, nxtp + 2) == "ull" then
                    return 2, nxtp + 3, nil, jsonIndex + 3
                else
                    error(ERR_MSG_NULL:format(jsonIndex))
                end
            end

            error(ERR_MSG_UNEXPECTED:format(jsonIndex))
        end

        export {
            _TokenMapUTF8               = {
                [0x20]                  = 1,
                [0x09]                  = 1,
                [0x0a]                  = 1,
                [0x0d]                  = 1,

                [0x2c]                  = 4,
                [0x3a]                  = 4,
                [0x5d]                  = 4,
                [0x7d]                  = 4,

                [0x74]                  = LoadJsonBooleanUTF8,
                [0x66]                  = LoadJsonBooleanUTF8,
                [0x6e]                  = LoadJsonBooleanUTF8,

                [0x22]                  = LoadJsonStringUTF8,

                [0x7b]                  = LoadJsonObjectUTF8,

                [0x5b]                  = LoadJsonArrayUTF8,

                [0x2d]                  = LoadJsonNumberUTF8,
                [0x30]                  = LoadJsonNumberUTF8,
                [0x31]                  = LoadJsonNumberUTF8,
                [0x32]                  = LoadJsonNumberUTF8,
                [0x33]                  = LoadJsonNumberUTF8,
                [0x34]                  = LoadJsonNumberUTF8,
                [0x35]                  = LoadJsonNumberUTF8,
                [0x36]                  = LoadJsonNumberUTF8,
                [0x37]                  = LoadJsonNumberUTF8,
                [0x38]                  = LoadJsonNumberUTF8,
                [0x39]                  = LoadJsonNumberUTF8,
            }
        }

        function LoadJsonDataUTF8(self, json, nxtp, jsonIndex)
            local code

            code                        = strbyte(json, nxtp)
            nxtp                        = nxtp + 1

            while true do
                local token             = _TokenMapUTF8[code]

                if not token then error(ERR_MSG_UNEXPECTED:format(jsonIndex)) end
                jsonIndex               = jsonIndex + 1

                if token == 1 then
                    code                = strbyte(json, nxtp)
                    nxtp                = nxtp + 1
                elseif token == 4 then
                    return jsonIndex, token, nxtp, code, jsonIndex
                else
                    return jsonIndex, token(self, json, nxtp, code, jsonIndex)
                end
            end
        end

        ------------------------------
        -- Load Json
        ------------------------------
        function LoadJson(self, json)
            -- Check the first bytes to know the encoding
            local first, second         = strbyte(json, 1, 2)
            local decode

            if (first == 0 and second == 0) then
                error("Can't determine the json's encoding.")
            end

            if (not first or first > 0) and (not second or second > 0) then
                -- Speed up for UTF-8
                local ok, msg, token, _, obj = pcall(LoadJsonDataUTF8, self, json, 1, 0)

                if not ok then
                    msg                 = strtrim(msg:match(":%d+:%s*(.-)$") or msg)
                    error(msg, 2)
                end

                return obj
            elseif first == 0 then
                decode                  = UTF16BEDecodes
            else
                decode                  = UTF16LEDecodes
            end

            local iter, tar, startp     = decode(json)
            local ok, msg, token, _, obj= pcall(LoadJsonData, self, iter, tar, startp, 0)

            if not ok then
                msg                     = strtrim(msg:match(":%d+:%s*(.-)$") or msg)
                error(msg, 2)
            end

            return obj
        end
    end

    --- Serialization format provider for json data
    __Final__() __Sealed__() __NoRawSet__(false) __NoNilValue__(false)
    class "JsonFormatProvider"          (function(_ENV)
        inherit "FormatProvider"

        export                          {
            tinsert                     = table.insert,
            tremove                     = table.remove,
            tblconcat                   = table.concat,
            wipe                        = Toolset.wipe,
            type                        = type,
            getmetatable                = getmetatable,
            SerializeDataWithWriter         = SerializeDataWithWriter,
            SerializeDataWithWriterNoIndent = SerializeDataWithWriterNoIndent,
            SerializeSimpleData             = SerializeSimpleData,
            SerializeDataWithWrite          = SerializeDataWithWrite,
            SerializeDataWithWriteNoIndent  = SerializeDataWithWriteNoIndent,
        }

        -----------------------------------
        -- Property
        -----------------------------------
        --- Whether using indented format, default false
        property "Indent"               { type = Boolean, default = false }

        --- The line break, default '\n'
        property "LineBreak"            { type = String, default = "\n" }

        --- The char used as the indented character, default '\t'
        property "IndentChar"           { type = String, default = "\t" }

        -----------------------------------
        -- Method
        -----------------------------------
        __Arguments__{ Any }
        function Serialize(self, data)
            if type(data) == "table" and getmetatable(data) == nil then
                local cache             = self()

                if self.Indent then
                    SerializeDataWithWriter(data, tinsert, cache, self.IndentChar, "", self.LineBreak)
                else
                    SerializeDataWithWriterNoIndent(data, tinsert, cache)
                end

                local ret               = tblconcat(cache)

                self(cache)

                return ret
            else
                return SerializeSimpleData(data)
            end
        end

        __Arguments__{ Any, Function }
        function Serialize(self, data, write)
            if type(data) == "table" and getmetatable(data) == nil then
                if self.Indent then
                    SerializeDataWithWrite(data, write, self.IndentChar, "", self.LineBreak)
                else
                    SerializeDataWithWriteNoIndent(data, write)
                end
            else
                write(SerializeSimpleData(data))
            end
        end

        __Arguments__{ Any, System.Text.TextWriter }
        function Serialize(self, data, writer)
            if type(data) == "table" and getmetatable(data) == nil then
                if self.Indent then
                    SerializeDataWithWriter(data, writer.Write, writer, self.IndentChar, "", self.LineBreak)
                else
                    SerializeDataWithWriterNoIndent(data, writer.Write, writer)
                end
            else
                writer:Write(SerializeSimpleData(data))
            end
            writer:Flush()
        end

        --- Deserialize the data to common lua data.
        __Arguments__{ String }
        Deserialize                     = LoadJson

        __Arguments__{ System.Text.TextReader }
        function Deserialize(self, reader)
            local data                  = reader:ReadToEnd()
            if data then return LoadJson(self, data) end
        end

        __Arguments__{ Function }
        function Deserialize(self, read)
            local data                  = List(read):Join()
            if data then return LoadJson(self, data) end
        end

        -----------------------------------------------------------------------
        --                            meta-method                            --
        -----------------------------------------------------------------------
        function __call(self, key)
            if key then tinsert(self, wipe(key)) else return tremove(self) or {} end
        end
    end)

    __Static__()
    function Toolset.json(data, type)
        if type then
            return Serialize(JsonFormatProvider(), data, type)
        else
            return Serialize(JsonFormatProvider(), data)
        end
    end

    __Static__()
    function Toolset.parsejson(string, type)
        if type then
            return Deserialize(JsonFormatProvider(), string, type)
        else
            return Deserialize(JsonFormatProvider(), string)
        end
    end
end)
