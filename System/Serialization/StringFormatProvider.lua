--===========================================================================--
--                                                                           --
--                 System.Serialization.StringFormatProvider                 --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2015/09/14                                               --
-- Update Date  :   2019/09/21                                               --
-- Version      :   1.1.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Serialization"

    export {
        pairs                           = pairs,
        type                            = type,
        tostring                        = tostring,
        next                            = next,
        select                          = select,
        getmetatable                    = getmetatable,
        floor                           = math.floor,
        tinsert                         = table.insert,
        tblconcat                       = table.concat,
        strformat                       = string.format,
        safeset                         = Toolset.safeset,
        loadsnippet                     = Toolset.loadsnippet,
        validnamespace                  = Namespace.Validate,
        isValidValue                    = Struct.ValidateValue,
        isanonymous                     = Namespace.IsAnonymousNamespace,
        Serialize                       = Serialization.Serialize,
        Deserialize                     = Serialization.Deserialize,
        getClass                        = Class.GetObjectClass,
        getMetaMethod                   = Class.GetMetaMethod,
        isArray                         = Serialization.IsArrayData,

        Serialization.Serializable, Serialization.SerializableType, List, Toolset, Serialization
    }

    -----------------------------------------------------------------------
    --                              prepare                              --
    -----------------------------------------------------------------------
    function SerializeSimpleData(data)
        local dtType                    = type(data)

        if dtType == "string" then
            return strformat("%q", data)
        elseif dtType == "number" or dtType == "boolean" then
            return tostring(data)
        elseif validnamespace(data) and not isanonymous(data) then
            return strformat("%q", tostring(data))
        end
    end

    function SerializeDataWithWriteNoIndent(data, write, objectTypeIgnored)
        write("{")

        local isarray                   = isArray(data)
        local field                     = Serialization.ObjectTypeField
        local val                       = data[field]
        if val then
            data[field]                 = nil

            if not objectTypeIgnored and not isanonymous(val) then
                if next(data) then
                    write(strformat("%s=%q,", field, tostring(val)))
                else
                    write(strformat("%s=%q",  field, tostring(val)))
                end
            end
        end

        if isarray then
            local count                 = #data

            local v                     = data[0]
            if v ~= nil then
                if type(v) == "table" then
                    write("[0]=")
                    SerializeDataWithWriteNoIndent(v, write, objectTypeIgnored)
                    if count > 0 then write(",") end
                else
                    if count > 0 then
                        write(strformat("[0]=%s,", SerializeSimpleData(v)))
                    else
                        write(strformat("[0]=%s", SerializeSimpleData(v)))
                    end
                end
            end

            for i = 1, count do
                local v                 = data[i]
                if type(v) == "table" and getmetatable(v) == nil then
                    SerializeDataWithWriteNoIndent(v, write, objectTypeIgnored)
                    if i < count then write(",") end
                else
                    if i < count then
                        write(strformat("%s,", SerializeSimpleData(v)))
                    else
                        write(strformat("%s", SerializeSimpleData(v)))
                    end
                end
            end
        else
            local k, v                  = next(data)
            local nk, nv

            while k do
                nk, nv                  = next(data, k)

                if type(v) == "table" then
                    write(strformat("[%s]=", SerializeSimpleData(k)))
                    SerializeDataWithWriteNoIndent(v, write, objectTypeIgnored)
                    if nk then write(",") end
                else
                    if nk then
                        write(strformat("[%s]=%s,", SerializeSimpleData(k), SerializeSimpleData(v)))
                    else
                        write(strformat("[%s]=%s", SerializeSimpleData(k), SerializeSimpleData(v)))
                    end
                end

                k, v                    = nk, nv
            end
        end

        write("}")
    end

    function SerializeDataWithWrite(data, write, indentChar, preIndentChar, lineBreak, objectTypeIgnored)
        write("{" .. lineBreak)

        local subIndentChar             = preIndentChar .. indentChar

        local isarray                   = isArray(data)
        local field                     = Serialization.ObjectTypeField
        local val                       = data[field]
        if val then
            data[field]                 = nil

            if not objectTypeIgnored and not isanonymous(val) then
                if next(data) then
                    write(strformat("%s%s = %q,%s", subIndentChar, field, tostring(val), lineBreak))
                else
                    write(strformat("%s%s = %q%s", subIndentChar, field, tostring(val), lineBreak))
                end
            end
        end

        if isarray then
            local subIndentChar         = preIndentChar .. indentChar
            local count                 = #data

            local v                     = data[0]
            if v ~= nil then
                if type(v) == "table" then
                    write(strformat("%s[0] = ", subIndentChar))
                    SerializeDataWithWrite(v, write, indentChar, subIndentChar, lineBreak, objectTypeIgnored)
                    if count > 0 then
                        write("," .. lineBreak)
                    else
                        write(lineBreak)
                    end
                else
                    if count > 0 then
                        write(strformat("%s[0] = %s,%s", subIndentChar, SerializeSimpleData(v), lineBreak))
                    else
                        write(strformat("%s[0] = %s%s", subIndentChar, SerializeSimpleData(v), lineBreak))
                    end
                end
            end

            for i = 1, count do
                local v                 = data[i]
                if type(v) == "table" and getmetatable(v) == nil then
                    write(subIndentChar)
                    SerializeDataWithWrite(v, write, indentChar, subIndentChar, lineBreak, objectTypeIgnored)
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
        else
            local k, v                  = next(data)
            local nk, nv

            while k do
                nk, nv                  = next(data, k)

                if type(v) == "table" then
                    write(strformat("%s[%s] = ", subIndentChar, SerializeSimpleData(k)))
                    SerializeDataWithWrite(v, write, indentChar, subIndentChar, lineBreak, objectTypeIgnored)
                    if nk then
                        write("," .. lineBreak)
                    else
                        write(lineBreak)
                    end
                else
                    if nk then
                        write(strformat("%s[%s] = %s,%s", subIndentChar, SerializeSimpleData(k), SerializeSimpleData(v), lineBreak))
                    else
                        write(strformat("%s[%s] = %s%s", subIndentChar, SerializeSimpleData(k), SerializeSimpleData(v), lineBreak))
                    end
                end

                k, v                    = nk, nv
            end
        end

        write(preIndentChar .. "}")
    end

    function SerializeDataWithWriterNoIndent(data, write, object, objectTypeIgnored)
        write(object, "{")

        local isarray                   = isArray(data)
        local field                     = Serialization.ObjectTypeField
        local val                       = data[field]
        if val then
            data[field]                 = nil

            if not objectTypeIgnored and not isanonymous(val) then
                if next(data) then
                    write(object, strformat("%s=%q,", field, tostring(val)))
                else
                    write(object, strformat("%s=%q",  field, tostring(val)))
                end
            end
        end

        if isarray then
            local count                 = #data

            local v                     = data[0]
            if v ~= nil then
                if type(v) == "table" then
                    write(object, "[0]=")
                    SerializeDataWithWriterNoIndent(v, write, object, objectTypeIgnored)
                    if count > 0 then write(object, ",") end
                else
                    if count > 0 then
                        write(object, strformat("[0]=%s,", SerializeSimpleData(v)))
                    else
                        write(object, strformat("[0]=%s", SerializeSimpleData(v)))
                    end
                end
            end

            for i = 1, count do
                local v                 = data[i]
                if type(v) == "table" and getmetatable(v) == nil then
                    SerializeDataWithWriterNoIndent(v, write, object, objectTypeIgnored)
                    if i < count then write(object, ",") end
                else
                    if i < count then
                        write(object, strformat("%s,", SerializeSimpleData(v)))
                    else
                        write(object, strformat("%s", SerializeSimpleData(v)))
                    end
                end
            end
        else
            local k, v                  = next(data)
            local nk, nv

            while k do
                nk, nv                  = next(data, k)

                if type(v) == "table" then
                    write(object, strformat("[%s]=", SerializeSimpleData(k)))
                    SerializeDataWithWriterNoIndent(v, write, object, objectTypeIgnored)
                    if nk then write(object, ",") end
                else
                    if nk then
                        write(object, strformat("[%s]=%s,", SerializeSimpleData(k), SerializeSimpleData(v)))
                    else
                        write(object, strformat("[%s]=%s", SerializeSimpleData(k), SerializeSimpleData(v)))
                    end
                end

                k, v                    = nk, nv
            end
        end

        write(object, "}")
    end

    function SerializeDataWithWriter(data, write, object, indentChar, preIndentChar, lineBreak, objectTypeIgnored)
        write(object, "{" .. lineBreak)

        local subIndentChar             = preIndentChar .. indentChar

        local isarray                   = isArray(data)
        local field                     = Serialization.ObjectTypeField
        local val                       = data[field]
        if val then
            data[field]                 = nil

            if not objectTypeIgnored and not isanonymous(val) then
                if next(data) then
                    write(object, strformat("%s%s = %q,%s", subIndentChar, field, tostring(val), lineBreak))
                else
                    write(object, strformat("%s%s = %q%s",  subIndentChar, field, tostring(val), lineBreak))
                end
            end
        end

        if isarray then
            local subIndentChar         = preIndentChar .. indentChar
            local count                 = #data

            local v                     = data[0]
            if v ~= nil then
                if type(v) == "table" then
                    write(object, strformat("%s[0] = ", subIndentChar))
                    SerializeDataWithWriter(v, write, object, indentChar, subIndentChar, lineBreak, objectTypeIgnored)
                    if count > 0 then
                        write(object, "," .. lineBreak)
                    else
                        write(object, lineBreak)
                    end
                else
                    if count > 0 then
                        write(object, strformat("%s[0] = %s,%s", subIndentChar, SerializeSimpleData(v), lineBreak))
                    else
                        write(object, strformat("%s[0] = %s%s", subIndentChar, SerializeSimpleData(v), lineBreak))
                    end
                end
            end

            for i = 1, count do
                local v                 = data[i]
                if type(v) == "table" and getmetatable(v) == nil then
                    write(object, subIndentChar)
                    SerializeDataWithWriter(v, write, object, indentChar, subIndentChar, lineBreak, objectTypeIgnored)
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
        else
            local k, v                  = next(data)
            local nk, nv

            while k do
                nk, nv                  = next(data, k)

                if type(v) == "table" then
                    write(object, strformat("%s[%s] = ", subIndentChar, SerializeSimpleData(k)))
                    SerializeDataWithWriter(v, write, object, indentChar, subIndentChar, lineBreak, objectTypeIgnored)
                    if nk then
                        write(object, "," .. lineBreak)
                    else
                        write(object, lineBreak)
                    end
                else
                    if nk then
                        write(object, strformat("%s[%s] = %s,%s", subIndentChar, SerializeSimpleData(k), SerializeSimpleData(v), lineBreak))
                    else
                        write(object, strformat("%s[%s] = %s%s", subIndentChar, SerializeSimpleData(k), SerializeSimpleData(v), lineBreak))
                    end
                end

                k, v                    = nk, nv
            end
        end

        write(object, preIndentChar .. "}")
    end

    --- Serialization format provider for string
    __Final__() __Sealed__() __NoRawSet__(false) __NoNilValue__(false)
    class "StringFormatProvider" (function(_ENV)
        inherit "FormatProvider"

        export {
            tinsert                         = tinsert,
            tblconcat                       = tblconcat,
            loadsnippet                     = Toolset.loadsnippet,
            strbyte                         = string.byte,
            strsub                          = string.sub,
            strtrim                         = Toolset.trim,
            type                            = type,
            pcall                           = pcall,
            SerializeDataWithWriter         = SerializeDataWithWriter,
            SerializeDataWithWriterNoIndent = SerializeDataWithWriterNoIndent,
            SerializeDataWithWrite          = SerializeDataWithWrite,
            SerializeDataWithWriteNoIndent  = SerializeDataWithWriteNoIndent,
            SerializeSimpleData             = SerializeSimpleData,

            List,
        }

        local function loadData(str)
            if strbyte(str, 1) == 0xEF and strbyte(str, 2) == 0xBB and strbyte(str, 3) == 0xBF then
                str                     = strsub(str, 4, -1)
            end

            -- the date format 2021-12-12 can be load as expression, should be check standalone
            if str:match("^%s*%d+[%-/]%d+") then return str end

            local func                  = loadsnippet("return " .. str)
            if func then
                local ok, val           = pcall(func)
                if ok and val ~= nil then return val end
            end

            return str
        end

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- Whether using indented format, default false
        property "Indent"               { type = Boolean }

        --- The line break, default '\n'
        property "LineBreak"            { type = String, Default = "\n" }

        --- The char used as the indented character, default '\t'
        property "IndentChar"           { type = String, Default = "\t" }

        --- Whether ignore the object's type for serialization
        property "ObjectTypeIgnored"    { type = Boolean, default = false }

        -----------------------------------------------------------------------
        --                              Method                               --
        -----------------------------------------------------------------------
        __Arguments__{ Any }
        function Serialize(self, data)
            if type(data) == "table" then
                local cache             = {}

                if self.Indent then
                    SerializeDataWithWriter(data, tinsert, cache, self.IndentChar, "", self.LineBreak, self.ObjectTypeIgnored)
                else
                    SerializeDataWithWriterNoIndent(data, tinsert, cache, self.ObjectTypeIgnored)
                end

                local ret               = tblconcat(cache)

                return ret
            else
                return SerializeSimpleData(data)
            end
        end

        __Arguments__{ Any, Function }
        function Serialize(self, data, write)
            if type(data) == "table" then
                if self.Indent then
                    SerializeDataWithWrite(data, write, self.IndentChar, "", self.LineBreak, self.ObjectTypeIgnored)
                else
                    SerializeDataWithWriteNoIndent(data, write, self.ObjectTypeIgnored)
                end
            else
                write(SerializeSimpleData(data))
            end
        end

        __Arguments__{ Any, System.Text.TextWriter }
        function Serialize(self, data, writer)
            if type(data) == "table" then
                if self.Indent then
                    SerializeDataWithWriter(data, writer.Write, writer, self.IndentChar, "", self.LineBreak, self.ObjectTypeIgnored)
                else
                    SerializeDataWithWriterNoIndent(data, writer.Write, writer, self.ObjectTypeIgnored)
                end
            else
                writer:Write(SerializeSimpleData(data))
            end
            writer:Flush()
        end

        --- Deserialize the data to common lua data.
        __Arguments__{ System.Text.TextReader }
        function Deserialize(self, reader)
            local data                  = reader:ReadToEnd()
            return data and loadData(data)
        end

        __Arguments__{ Function }
        function Deserialize(self, read)
            local data                  = List(read):Join()
            return data and loadData(data)
        end

        __Arguments__{ Number + String }
        function Deserialize(self, data)
            return loadData(data)
        end
    end)

    --- Convert the data to string
    __Static__()
    function Toolset.tostring(data, dtype, pretty)
        if data == nil then return "nil" end
        if type(data) ~= "table" then return tostring(data) end

        -- Check __tostring
        local cls                       = getClass(data)
        if cls and getMetaMethod(cls, "__tostring", true) then
            return tostring(data)
        end

        if dtype then
            if isValidValue(SerializableType, dtype) then
                return Serialize(StringFormatProvider{ Indent = pretty or false, ObjectTypeIgnored = true }, data, dtype)
            end
        elseif isValidValue(Serializable, data) then
            return Serialize(StringFormatProvider{ Indent = pretty or false, ObjectTypeIgnored = true }, data)
        else
            return tostring(data)
        end
    end

    --- Convert the string to data
    __Static__()
    function Toolset.parsestring(string, type)
        return Deserialize(StringFormatProvider(), string, type)
    end

    local _ToStringAllHandler           = {}

    --- Convert multiple data to string
    __Static__()
    function Toolset.tostringall(...)
        local count                     = select("#", ...)
        if count == 0 then return end

        local handler                   = _ToStringAllHandler[count]
        if not handler then
            handler                     = loadsnippet(
                [[
                    local conv  = ...
                    return function(]] .. List(count, "i=>'arg' .. i"):Join(",") .. [[)
                        return ]] .. List(count, "i=>'conv(arg' .. i .. ')'"):Join(",") .. [[
                    end
                ]]
            )(Toolset.tostring)

            _ToStringAllHandler         = safeset(_ToStringAllHandler, count, handler)
        end

        return handler(...)
    end
end)
