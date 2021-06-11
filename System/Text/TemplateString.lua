--===========================================================================--
--                                                                           --
--                        System.Text.TemplateString                         --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2020/10/03                                               --
-- Update Date  :   2020/10/03                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Text"

    --- The template string render type
    __Sealed__() __AutoIndex__()
    enum "TemplateStringRenderType" {
        "RecordLine",
        "StaticText",
        "NewLine",
        "LuaCode",
        "Expression",
    }

    --- Represents the template string loader, used to analyze the template string
    -- to generate the template string operations, so the template string will be
    -- converted to a class that can be used to generate the result string based on
    -- the data.
    __Sealed__() interface "ITemplateStringLoader" (function(_ENV)
        extend "Iterable"

        export {
            yield               = coroutine.yield,
            RCT_RecordLine      = TemplateStringRenderType.RecordLine,
            RCT_StaticText      = TemplateStringRenderType.StaticText,
            RCT_NewLine         = TemplateStringRenderType.NewLine,
        }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        __Iterator__()
        function GetIterator(self, reader) return self:ParseLines(reader) end

        --- Parse the lines and yield all content with type
        __Abstract__() function ParseLines(self, reader)
            for line in reader:ReadLines() do
                line            = line:gsub("%s+$", "")
                yield(RCT_RecordLine, line)
                yield(RCT_StaticText, line)
                yield(RCT_NewLine)
            end
        end
    end)

    --- The default implementation or the template string loader
    __Sealed__() class "DefaultTemplateStringLoader" (function(_ENV)
        extend "ITemplateStringLoader"

        --[=============================[
            Rules

            I. Full-Line :
                Using :
                    @> lua code
                    @ keyword + other lua code
                Example :
                    @local x = math.random(100)
                    @if x > 50
                    <p> Above 50 </p>
                    @else
                    <p> Below 50 </p>
                    @end

            II. In-Line :
                Using :
                    @expression
                Example :
                    @x
                    @(x+y:%3d)
                    @"test"
                    @[[test]]
                    @self.Data[1].Name:lower()

        --]=============================]

        export {
            yield               = coroutine.yield,
            loadstring          = _G.loadstring or _G.load,
            safeset             = Toolset.safeset,

            RCT_RecordLine      = TemplateStringRenderType.RecordLine,
            RCT_StaticText      = TemplateStringRenderType.StaticText,
            RCT_NewLine         = TemplateStringRenderType.NewLine,
            RCT_LuaCode         = TemplateStringRenderType.LuaCode,
            RCT_Expression      = TemplateStringRenderType.Expression,

            _LuaKeyWords        = {
                ["break"]       = true,
                ["do"]          = true,
                ["else"]        = true,
                ["for"]         = true,
                ["if"]          = true,
                ["elseif"]      = true,
                ["return"]      = true,
                ["repeat"]      = true,
                ["while"]       = true,
                ["until"]       = true,
                ["end"]         = true,
                ["function"]    = true,
                ["local"]       = true,
            },
        }

        local _PrefixMap        = {
            ["("]               = false,
            ["["]               = false,
            ["{"]               = false,
            ["'"]               = false,
            ['"']               = false,
            ["+"]               = false,
            ["-"]               = false,
            ["\\"]              = System.Text.XmlEntity.Encode,
        }

        -------------------------------
        -- Helper
        -------------------------------
        -- Get expression from the line
        local function parseExpression(line, startp)
            local parseCnt
            local code          = ""

            local parsePrintTemp= function(word) code = code .. word return "" end

            -- Find the start
            startp              = line:find("%S", startp)
            if not startp then return end

            -- Check the prefix
            local prest, prend  = line:find("^%p", startp)
            local prefix
            if prest and prend then
                prefix          = line:sub(prest, prend)
                if not _PrefixMap[prefix] then
                    prefix      = nil
                else
                    startp      = line:find("%S", prend + 1)
                    if not startp then return end
                end
            end

            -- Check the expression
            line                = line:sub(startp)

            if line:find("^%(") then
                -- Just take the expression inside the brackets
                line            = line:gsub("^%b()", parsePrintTemp)
            elseif line:find("^[+-]?%s*[%d%.]") then
                -- First word is a number
                if line:find("^[+-]?%s*0[xX]") then
                    -- Hex [+-]?0x[0-9a-fA-F]*
                    line        = line:gsub("^[+-]?%s*0x[0-9a-fA-F]*", parsePrintTemp)
                elseif line:find("^[+-]?%s*%d") then
                    -- [+-]?%d+%.?%d*[eE]?%-?%d*
                    line        = line:gsub("^([+-]?%s*%d+%.?%d*)([eE]?)(%-?%d*)", function(start, e, tail)
                        if #e > 0 then
                            code= code .. start .. e .. tail
                        else
                            code= code .. start
                        end
                    end)
                else
                    -- [+-]?%.%d*[eE]?%-?%d*
                    line = line:gsub("^([+-]?%s*%.%d*)([eE]?)(%-?%d*)", function(start, e, tail)
                        if #e > 0 then
                            code = code .. start .. e .. tail
                        else
                            code = code .. start
                        end
                    end)
                end
            elseif line:find("^'") then
                -- The word is a string
                line            = line:gsub("^%b''", parsePrintTemp)
            elseif line:find('^"') then
                -- The word is a string
                line            = line:gsub('^%b""', parsePrintTemp)
            elseif line:find("^%[=*%[") then
                -- The word is a string
                line            = line:gsub("^%b[]", parsePrintTemp)
            elseif line:find("^[%w_]") then
                -- variable first
                line            = line:gsub("^([%w_]+)%s*", parsePrintTemp)

                -- parse the remain expression
                while line ~= "" do
                    local head = line:sub(1, 1)
                    parseCnt    = 0

                    if head == "." or head == ":" then
                        line, parseCnt = line:gsub("^([%.:][_%a][%w_]*)%s*", parsePrintTemp)
                    elseif head == "{" then
                        line, parseCnt = line:gsub("^(%b{})%s*", parsePrintTemp)
                    elseif head == "(" then
                        line, parseCnt = line:gsub("^(%b())%s*", parsePrintTemp)
                    elseif head == "[" then
                        line, parseCnt = line:gsub("^(%b[])%s*", parsePrintTemp)
                    end

                    if parseCnt == 0 then break end
                end
            end

            if code ~= "" then
                -- Check format
                local prev, fmt = code:match("^%((.+):(%%[^%(]+)%)$")
                local rcode     = prev and ("(" .. prev .. ")") or code

                if loadstring("return " .. rcode) then
                    return rcode, startp + #code - 1, fmt, prefix
                end
            end
        end

        local function parsePageLine(reader, line)
            local cnt

            -- Full Line
            --- @-- comment
            -- No multi-line comment supported,
            -- since <!-- --> can also be used without @
            if line:find("^%s*@%s*%-%-.*$") then return end

            --- @> full line
            line, cnt           = line:gsub("^%s*@>(.*)$", "%1")
            if cnt > 0 then
                yield(RCT_LuaCode, line)
                return
            end

            --- @ keyword
            if _LuaKeyWords[line:match("^%s*@%s*(%w+)")] then
                line            = line:gsub("^%s*@%s*(%w+)(.*)$", "%1%2")
                yield(RCT_LuaCode, line)
                return
            end

            --- Lua block
            if line:find("^%s*@%s*{$") then
                local prevSpace = line:match("^%s*")

                line            = reader:ReadLine()
                while line do
                    yield(RCT_RecordLine, line)
                    line        = line:gsub("%s+$", "")

                    if line:find("^%s*}$") and line:match("^%s*") == prevSpace then
                        break
                    else
                        yield(RCT_LuaCode, line)
                    end

                    line = reader:ReadLine()
                end

                if not line then error("'@{' must be ended with '}'.") end

                return
            end

            -- Inline
            local startp        = 1
            local pos           = line:find("@", 1, true)

            while pos do
                local chr       = line:match("%S", pos + 1)

                if chr == "@" then
                    -- Skip next @
                    pos         = line:find("@", pos + 1, true)
                else
                    -- expression
                    local exp, endp, format, prefix = parseExpression(line, pos + 1)

                    if exp then
                        --- The previous text should be output directly
                        local prev  = line:sub(startp, pos - 1)
                        if prev and prev ~= "" then
                            prev    = prev:gsub("@@", "@")
                            yield(RCT_StaticText, prev)
                        end
                        startp  = pos

                        -- Expression
                        yield(RCT_Expression, exp, format, prefix and _PrefixMap[prefix])

                        -- Continue
                        startp  = endp + 1
                        pos     = endp
                    end
                end

                pos             = line:find("@", pos + 1, true)
            end

            local last          = line:sub(startp)
            if last and last ~= "" then
                last            = last:gsub("@@", "@")
                yield(RCT_StaticText, last)
            end
            yield(RCT_NewLine)
        end

        -----------------------------------------------------------------------
        --                          static property                          --
        -----------------------------------------------------------------------
        --- The prefix to function map like `\=>Encode`, so the `@\test => Encode(test)`
        __Indexer__(struct { __base = NEString,
            function (val, onlyvalid)
                if not val:match("^%p$") then
                    return onlyvalid or "%s must all be punctuation"
                end
            end
        }) __Static__()
        property "Prefix" {
            type                = Callable,
            set                 = function(self, prefix, map)
                if _PrefixMap[prefix] == nil then
                    _PrefixMap  = safeset(_PrefixMap, prefix, map)
                end
            end,
        }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        function ParseLines(self, reader)
            local line          = reader:ReadLine()

            while line do
                line            = line:gsub("%s+$", "")
                yield(RCT_RecordLine, line)

                if line ~= "" then
                    parsePageLine(reader, line)
                end

                line            = reader:ReadLine()
            end
        end
    end)

    __Sealed__() __Final__()
    class "TemplateString" (function (_ENV)
        export {
            with                = with,

            loadstring          = _G.loadstring or _G.load,
            loadsnippet         = Toolset.loadsnippet,
            pcall               = pcall,
            error               = error,
            assert              = assert,
            tonumber            = tonumber,
            tostring            = tostring,
            random              = math.random,
            strlower            = string.lower,
            strformat           = string.format,
            strfind             = string.find,
            strsub              = string.sub,
            strgsub             = string.gsub,
            tblconcat           = table.concat,
            tinsert             = table.insert,
            tremove             = table.remove,
            setmetatable        = setmetatable,
            safeset             = Toolset.safeset,
            _PL_tostring        = Toolset.tostring or tostring,
            setfenv             = _G.setfenv or _G.debug and debug.setfenv or Toolset.fakefunc,

            META_ITEMS          = { __index = _G },

            RCT_RecordLine      = TemplateStringRenderType.RecordLine,
            RCT_StaticText      = TemplateStringRenderType.StaticText,
            RCT_NewLine         = TemplateStringRenderType.NewLine,
            RCT_LuaCode         = TemplateStringRenderType.LuaCode,
            RCT_Expression      = TemplateStringRenderType.Expression,

            StringReader, StringWriter, DefaultTemplateStringLoader, TextWriter,
        }

        --- Convert the error to the real position
        local function raiseError(self, err)
            err                 = tostring(err)
            local line, msg     = err:match("%b[]:(%d+):(.-)$")
            line                = tonumber(line)
            if line and self.CodeLineMap[line] then
                err             = ("template string:%d: %s"):format(self.CodeLineMap[line], msg)
            end
            error(err, 0)
        end

        local function prepareGenerator(self, items)
            for k, v in pairs(self.APIs) do
                items[k]        = v
            end

            setmetatable(items, META_ITEMS)

            local func, err     = pcall(self.Generator)
            if not func then
                raiseError(self, err)
            else
                func            = err
            end

            setfenv(func, items)

            return func
        end

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- The template string
        property "TemplateString"   { type = String }

        --- The code line map
        property "CodeLineMap"      { set = false, default = Toolset.newtable }

        --- The apis could be used in the template string
        property "APIs"             { set = false, default = function() return { _PL_tostring = function(val) return val == nil and "" or _PL_tostring(val) end } end }

        --- The function used to return the generator of the result
        property "Generator"        { }

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        __Arguments__{ NEString, -ITemplateStringLoader/nil }
        function __ctor(self, template, loader)
            with(StringReader(template))(function(reader)
                reader.DiscardIndents       = true

                self.TemplateString         = template

                local recordCount           = 0
                local definition            = { "return function(_ENV, writer)" }
                local engine                = (loader or DefaultTemplateStringLoader)()
                local apis                  = self.APIs
                local temp                  = {}

                local wNewLine              = [[writer:WriteLine()]]
                local wStaticText           = [[writer:Write(%q)]]
                local wExpression           = [[writer:Write(_PL_tostring(%s))]]
                local wWrapExp              = [[writer:Write(%s(_PL_tostring(%s)))]]
                local wFmtExpression        = [[writer:Write((%q):format(_PL_tostring(%s)))]]
                local wFmtWrapExp           = [[writer:Write(%s((%q):format(_PL_tostring(%s))))]]

                local sourceCount           = 1
                local defineCount           = 1
                local lineMap               = self.CodeLineMap
                local pushcode              = function (line)
                    defineCount             = defineCount + 1
                    definition[defineCount] = line

                    sourceCount             = sourceCount + 1
                    lineMap[sourceCount]    = recordCount
                end

                for ty, ct, fmt, wrap in engine:GetIterator(reader) do
                    if ty == RCT_RecordLine then
                        recordCount         = recordCount + 1
                    elseif ty == RCT_LuaCode then
                        pushcode(ct)
                    elseif ty == RCT_StaticText then
                        if ct ~= "" then
                            pushcode(wStaticText:format(ct))
                        end
                    elseif ty == RCT_NewLine then
                        pushcode(wNewLine)
                    elseif ty == RCT_Expression then
                        if fmt then
                            if wrap then
                                if not temp[wrap] then
                                    local name  = "_PL_" .. strformat("%04X", random(0xffff))
                                    while apis[name] do
                                        name    = "_PL_" .. strformat("%04X", random(0xffff))
                                    end
                                    temp[wrap]  = name
                                    apis[name]  = wrap
                                end

                                pushcode(wFmtWrapExp:format(temp[wrap], fmt, ct))
                            else
                                pushcode(wFmtExpression:format(fmt, ct))
                            end
                        else
                            if wrap then
                                if not temp[wrap] then
                                    local name  = "_PL_" .. strformat("%04X", random(0xffff))
                                    while apis[name] do
                                        name    = "_PL_" .. strformat("%04X", random(0xffff))
                                    end
                                    temp[wrap]  = name
                                    apis[name]  = wrap
                                end

                                pushcode(wWrapExp:format(temp[wrap], ct))
                            else
                                pushcode(wExpression:format(ct))
                            end
                        end
                    end
                end

                tinsert(definition, "end")

                definition                  = tblconcat(definition, "\n")

                local ok, err               = loadsnippet(definition, "template")

                if not ok then
                    raiseError(self, err)
                end

                self.Generator              = ok
            end)
        end

        -----------------------------------------------------------------------
        --                            meta-method                            --
        -----------------------------------------------------------------------
        __Arguments__{ RawTable/nil }
        function __call(self, items)
            items               = items or {}
            local func          = prepareGenerator(self, items)
            return with(StringWriter())(function(writer)
                func(items, writer)

                return writer
            end, function(err)
                raiseError(self, err)
            end).Result
        end

        __Arguments__{ TextWriter, RawTable/nil }
        function __call(self, writer, items)
            items               = items or {}
            local func          = prepareGenerator(self, items)
            with(writer)(function(writer)
                func(items, writer)

                return writer
            end, function(err)
                raiseError(self, err)
            end)
        end

        __Arguments__{ Callable, RawTable/nil }
        function __call(self, write, items)
            items               = items or {}
            local func          = prepareGenerator(self, items)
            with(TextWriter{ Write = function(self, ...) return write(...) end })(function(writer)
                func(items, writer)
            end, function(err)
                raiseError(self, err)
            end)
        end
    end)
end)