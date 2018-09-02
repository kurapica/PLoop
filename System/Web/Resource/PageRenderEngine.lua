--===========================================================================--
--                                                                           --
--                        System.Web.PageRenderEngine                        --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2016/04/10                                               --
-- Update Date  :   2018/04/02                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    --[=============================[
        Rules

        I. WebPart :
            Define :
                @ name {
                    output content
                }
            Using :
                @ { name default description }

        II. Helper :
            Define :
                @ name (params) {
                    output content
                }
            Using :
                @ { name (params) }

        III. Lua-Block :
            Define :
                @ {
                    lua code
                }
            Example :
                @ {
                    function OnLoad(self)
                        self.PageTitle = "Test"
                    end
                }

        IV. Full-Line :
            Using :
                @> lua code
                @ keyword + other lua code
            Example :
                @> local x = math.random(100)
                @if x > 50
                <p> Above 50 </p>
                @else
                <p> Below 50 </p>
                @end

        V. In-Line :
            Using :
                @ expression   -- use HtmlEncode if page directive set 'encode=true'
                @< expression  -- with HtmlEncode
            Example :
                @x
                @(x+y)
                @"test"
                @[[test]]
                @self.Data[1].Name:lower()
                @< (x+y)        -- With HtmlEncode
                @\self.Title    -- With HtmlEncode

        VI. Embed-Page :
            Using :
                @[path (params) default description]
                    * in-line code can be used in path
                    * params are used to create the object of the target path
            Example :
                @[url get web part from other pages]
                @[share/login (self.Data) default messages]
                @[share/login default messages]
                @[/static/@type/@geturl('jquery.1.4.1') (self.Data) default message]
                @["/data/@root/@type/@geturl()" (self.Data, self.AnotherData) Default message]

        VII.Inner-Request :
            Using :
                @[~path (param, httpmethod)]
                    * in-line code can be used in path
                    * params will be used as querystring or form based on the http method
            Example :
                @[~/tag/list ({id=1})]
    --]=============================]

    export {
        yield               = coroutine.yield,
        loadstring          = _G.loadstring or load,
        RCT_RecordLine      = RenderContentType.RecordLine,
        RCT_StaticText      = RenderContentType.StaticText,
        RCT_NewLine         = RenderContentType.NewLine,
        RCT_LuaCode         = RenderContentType.LuaCode,
        RCT_Expression      = RenderContentType.Expression,
        RCT_EncodeExpression= RenderContentType.EncodeExpression,
        RCT_MixMethodStart  = RenderContentType.MixMethodStart,
        RCT_MixMethodEnd    = RenderContentType.MixMethodEnd,
        RCT_CallMixMethod   = RenderContentType.CallMixMethod,
        RCT_RenderOther     = RenderContentType.RenderOther,
        RCT_InnerRequest    = RenderContentType.InnerRequest,

        _LuaKeyWords        = {
            ["break"]       = true,
            ["do"]          = true,
            ["else"]        = true,
            ["for"]         = true,
            ["if"]          = true,
            ["elseif"]      = true,
            ["return"]      = true,
            -- ["then"]     = true,
            ["repeat"]      = true,
            ["while"]       = true,
            ["until"]       = true,
            ["end"]         = true,
            ["function"]    = true,
            ["local"]       = true,
            -- ["in"]       = true,
        },

        -- Declare global variables
        parseLuaBlock       = false,
        parseMixedMethod    = false,
        parsePageLine       = false,
        parseAllExp         = false,
        parseExpression     = false,
    }

    -------------------------------
    -- Helper
    -------------------------------
    --[======================[
        Lua-Block

        @{
            -- global lua code block
        }
    --]======================]
    function parseLuaBlock(reader)
        for line in reader:ReadLines() do
            line = line:gsub("%s+$", "")
            yield(RCT_RecordLine, line)
            if line == "}" then return end

            yield(RCT_LuaCode, line)
        end
        error("'@{' must be ended with '}'.")
    end

    --[======================[
        WebPart or Helper

        @ name {
            -- Mixed content
        }

        @name(params){
            -- html helpler block
        }
    --]======================]
    function parseMixedMethod(reader, name, param)
        local prev

        yield(RCT_MixMethodStart, "Render_" .. name, param)

        for line in reader:ReadLines() do
            line = line:gsub("%s+$", "")
            yield(RCT_RecordLine, line)
            if line == "}" then yield(RCT_MixMethodEnd) return end
            if not prev then prev = "^" .. (line:match("^%s+") or "") end

            parsePageLine(reader, line:gsub(prev, ""), prev)
        end

        error(("'@%s%s{' must be ended with '}'."):format(name, param or ''))
    end

    --[======================[
        In-Line

        @-- Comment
        @self.Data
        @<self.Data
        @\self.Data
        @(self.Data)
        @>x = x + 123
        @if some then
        @{webpart}
        @{htmlhelper(params)}
        @{super:webpart}
        @{super:htmlhelper(params)}
        @[url]
    --]======================]
    function parsePageLine(reader, line, preSpH)
        local cnt

        -- Full Line
        --- @-- comment
        -- No multi-line comment supported,
        -- since <!-- --> can also be used without @
        if line:find("^%s*@%s*%-%-.*$") then return end

        --- @> full line
        line, cnt = line:gsub("^%s*@>(.*)$", "%1")
        if cnt > 0 then
            yield(RCT_LuaCode, line)
            return
        end

        --- @ keyword
        if _LuaKeyWords[line:match("^%s*@%s*(%w+)")] then
            line = line:gsub("^%s*@%s*(%w+)(.*)$", "%1%2")
            yield(RCT_LuaCode, line)
            return
        end

        --- Lua block
        if line:find("^%s*@%s*{$") then
            local prevSpace = line:match("^%s*")

            line = reader:ReadLine()
            while line do
                yield(RCT_RecordLine, line)
                line = line:gsub("%s+$", "")
                if preSpH then line = line:gsub(preSpH, "") end

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
        local startp = 1
        local pos = line:find("@", 1, true)

        while pos do
            local chr = line:match("%S", pos + 1)

            if chr == "@" then
                -- Skip next @
                pos = line:find("@", pos + 1, true)
            elseif chr == "{" or (chr == "[" and not line:find("^%s*%[=*%[", pos + 1) ) then
                --- The previous text should be output directly
                local prev = line:sub(startp, pos - 1)
                if prev and prev ~= "" then
                    prev = prev:gsub("@@", "@")
                    yield(RCT_StaticText, prev)
                end
                startp = pos

                local pstart, pend = line:find(chr == "{" and "^%s*(%b{})" or chr == "[" and "^%s*(%b[])", pos + 1)

                -- Syntax failure, no need to continue parse
                if not pstart then break end

                local def = line:sub(pstart + 1, pend - 1)
                if chr == "{" then
                    local issupercall = def:find("^super:") and true or false
                    if issupercall then def = def:sub(7, -1) end

                    local helper, params = def:match("^%s*([_%w]+)%s*(%b())")
                    if helper and params then
                        -- Html helper
                        yield(RCT_CallMixMethod, "Render_" .. helper, params, nil, issupercall)
                    else
                        -- Web part
                        local part, default = def:match("^%s*([_%w]+)%s*(.-)%s*$")

                        -- Syntax failure
                        if not part then break end

                        yield(RCT_CallMixMethod, "Render_" .. part, nil, default or "", issupercall)
                    end
                elseif chr == "[" then
                    -- Check if it's an inner request
                    local _, isinner = def:find("^%s*~")
                    if isinner then def = def:sub(isinner + 1) end

                    -- Embed page
                    local url, params, default
                    local quote = def:match("^%s*(['\"])")

                    -- Get url
                    if quote == "'" or quote == '"' then
                        if quote == "'" then
                            def = def:gsub("^%s*(%b'')%s*", function(p) url = p:sub(2, -2) return '' end)
                        else
                            def = def:gsub("^%s*(%b\"\")%s*", function(p) url = p:sub(2, -2) return '' end)
                        end
                    else
                        url = ""

                        local function parseUrlTemp(word) url = url .. word return "" end

                        def = def:gsub("^%s*([^%s(]*)", parseUrlTemp)

                        repeat
                            local head = def:sub(1, 1)

                            if head ~= "(" then break end

                            def = def:gsub("^%b()[^%s(]*", parseUrlTemp)
                        until #def == 0
                    end

                    -- Get params & default
                    def = def:gsub("^%s*(%b())%s*", function(p) params = p return '' end)
                    default = def:gsub("^%s*(.-)%s*$", "%1")

                    -- Convert the url with inline code
                    url = parseAllExp(url):gsub("@@", "@")

                    if #default > 0 then
                        default = parseAllExp(default):gsub("@@", "@")
                    end

                    if isinner then
                        yield(RCT_InnerRequest, url, params)
                    else
                        yield(RCT_RenderOther, url, params, default)
                    end
                end

                -- Continue
                startp = pend + 1
                pos = pend
            else
                -- expression
                local exp, endp, encode = parseExpression(line, pos + 1)

                if exp then
                    --- The previous text should be output directly
                    local prev = line:sub(startp, pos - 1)
                    if prev and prev ~= "" then
                        prev = prev:gsub("@@", "@")
                        yield(RCT_StaticText, prev)
                    end
                    startp = pos

                    -- Expression
                    if encode then
                        yield(RCT_EncodeExpression, exp)
                    else
                        yield(RCT_Expression, exp)
                    end

                    -- Continue
                    startp = endp + 1
                    pos = endp
                end
            end

            pos = line:find("@", pos + 1, true)
        end

        local last = line:sub(startp)
        if last and last ~= "" then
            last = last:gsub("@@", "@")
            yield(RCT_StaticText, last)
        end
        yield(RCT_NewLine)
    end

    -- Convert expressions
    function parseAllExp(line)
        local startp = 1
        local pos = line:find("@", 1, true)
        local result = ""

        while pos do
            local prev = line:sub(startp, pos - 1)
            if prev and prev ~= "" then
                prev = prev:gsub("@@", "@")

                if result ~= "" then
                    result = result .. (" .. %q"):format(prev)
                else
                    result = ("%q"):format(prev)
                end
            end
            startp = pos

            local exp, endp = parseExpression(line, pos + 1)

            if exp then
                if result ~= "" then
                    result = result .. (" .. tostring(%s)"):format(exp)
                else
                    result = ("tostring(%s)"):format(exp)
                end

                -- Continue
                startp = endp + 1
                pos = endp
            else
                -- To skip @@
                pos = pos + 1
            end

            pos = line:find("@", pos + 1, true)
        end

        local last = line:sub(startp)
        if last and last ~= "" then
            last = last:gsub("@@", "@")

            if result ~= "" then
                result = result .. (" .. %q"):format(last)
            else
                result = ("%q"):format(last)
            end
        end

        return result
    end

    -- Get expression from the line
    function parseExpression(line, startp)
        local parseCnt
        local code = ""
        local encode = false

        local function parsePrintTemp(word) code = code .. word return "" end

        -- Find the start
        startp = line:find("%S", startp)

        -- parse fail
        if not startp then return end

        local fchar = line:sub(startp, startp)
        if fchar == "<" or fchar == "\\" then
            encode = true
            startp = line:find("%S", startp + 1)

            if not startp then return end
        end

        line = line:sub(startp)

        if line:find("^%(") then
            -- Just take the expression inside the brackets
            line = line:gsub("^%b()", parsePrintTemp)
        elseif line:find("^[+-]?%s*[%d%.]") then
            -- First word is a number
            if line:find("^[+-]?%s*0[xX]") then
                -- Hex [+-]?0x[0-9a-fA-F]*
                line = line:gsub("^[+-]?%s*0x[0-9a-fA-F]*", parsePrintTemp)
            elseif line:find("^[+-]?%s*%d") then
                -- [+-]?%d+%.?%d*[eE]?%-?%d*
                line = line:gsub("^([+-]?%s*%d+%.?%d*)([eE]?)(%-?%d*)", function(start, e, tail)
                    if #e > 0 then
                        code = code .. start .. e .. tail
                    else
                        code = code .. start
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
            line = line:gsub("^%b''", parsePrintTemp)
        elseif line:find('^"') then
            -- The word is a string
            line = line:gsub('^%b""', parsePrintTemp)
        elseif line:find("^%[=*%[") then
            -- The word is a string
            line = line:gsub("^%b[]", parsePrintTemp)
        elseif line:find("^[%w_]") then
            -- variable first
            line = line:gsub("^([%w_]+)%s*", parsePrintTemp)

            -- parse the remain expression
            while line ~= "" do
                local head = line:sub(1, 1)
                parseCnt = 0

                if head == "." or head == ":" then
                    line, parseCnt = line:gsub("^([%.:][_%a][%w_]+)%s*", parsePrintTemp)
                --elseif head == "'" then
                --    line, parseCnt = line:gsub("^(%b'')%s*", parsePrintTemp)
                --elseif head == "\"" then
                --    line, parseCnt = line:gsub("^(%b\"\")%s*", parsePrintTemp)
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
            if loadstring("return " .. code) then
                return code, startp + #code - 1, encode
            end
        end
    end

    --- The common Lua page render engine
    __Sealed__() class "System.Web.PageRenderEngine" { IRenderEngine,
        AutoEncode      = { type = Boolean },
        TargetPath      = { type = String  },

        Init            = function (self, loader, config)
            self.AutoEncode = config.encode
            self.TargetPath = loader.Path
        end,

        ParseLines      = function (self, reader)
            local line  = reader:ReadLine()

            local RENDER_WAIT   = 0
            local RENDER_PROCESS= 1
            local RENDER_FINISH = 2

            local renderPhase   = RENDER_WAIT

            while line do
                line = line:gsub("%s+$", "")
                yield(RCT_RecordLine, line)

                if line ~= "" then
                    if line:find("^@%s*{$") then
                        if renderPhase == RENDER_PROCESS then
                            renderPhase = RENDER_FINISH
                            yield(RCT_MixMethodEnd)
                        end

                        -- III. Lua-Block
                        parseLuaBlock(reader)
                    elseif line:find("^@%s*[_%w]+%s*%b()%s*{$") then
                        if renderPhase == RENDER_PROCESS then
                            renderPhase = RENDER_FINISH
                            yield(RCT_MixMethodEnd)
                        end

                        -- parse helper
                        parseMixedMethod(reader, line:match("^@%s*([_%w]+)%s*(%b())%s*{$"))
                    elseif line:find("^@%s*[_%w]+%s*{$") then
                        if renderPhase == RENDER_PROCESS then
                            renderPhase = RENDER_FINISH
                            yield(RCT_MixMethodEnd)
                        end

                        -- parse web part
                        parseMixedMethod(reader, line:match("^@%s*([_%w]+)%s*{$"))
                    elseif renderPhase ~= RENDER_FINISH then
                        if renderPhase == RENDER_WAIT then
                            yield(RCT_MixMethodStart, "Render")
                            renderPhase = RENDER_PROCESS
                        end

                        -- Render part
                        parsePageLine(reader, line)
                    end
                end

                line = reader:ReadLine()
            end

            if renderPhase == RENDER_PROCESS then
                renderPhase = RENDER_FINISH
                yield(RCT_MixMethodEnd)
            end
        end,
    }
end)