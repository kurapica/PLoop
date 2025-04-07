--===========================================================================--
--                                                                           --
--                  System.Web.Xml                                           --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2020/07/29                                               --
-- Update Date  :   2020/07/29                                               --
-- Version      :   0.1.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Web.Xml"

    export {
        pcall                   = pcall,
        error                   = error,
        type                    = type,
        pairs                   = pairs,
        ipairs                  = ipairs,
        tostring                = tostring,
        tonumber                = tonumber,
        getmetatable            = getmetatable,
        next                    = next,
        floor                   = math.floor,
        mhuge                   = math.huge,
        BIG_NUMBER              = 10^12,
        tinsert                 = table.insert,
        tremove                 = table.remove,
        tblconcat               = table.concat,
        strbyte                 = string.byte,
        strchar                 = string.char,
        strsub                  = string.sub,
        strformat               = string.format,
        strtrim                 = Toolset.trim,
        isstruct                = Struct.Validate,
        getstructcategory       = Struct.GetStructCategory,
        isListType              = Class.IsSubType,
        isnamespace             = Namespace.Validate,
        Serialize               = Serialization.Serialize,
        Deserialize             = Serialization.Deserialize,
        isObjectType            = Class.IsObjectType,

        LUA_VERSION             = tonumber(_G._VERSION:match("[%d%.]+")) or 5.1,
        Serialization, List, IIndexedList,

        EncodeData              = UTF8Encoding.Encode,

        UTF8Decode              = UTF8Encoding.Decode,
        UTF16LEDecode           = UTF16EncodingLE.Decode,
        UTF16BEDecode           = UTF16EncodingBE.Decode,
    }

    BYTE_LESSTHAN               = 0x3c    -- <
    BYTE_GRAVE_ACCENT           = 0x60    -- `
    BYTE_LEFTBRACKET            = 0x5b    -- [
    BYTE_EXCLAMATION            = 0x21    -- !
    BYTE_SEMICOLON              = 0x3b    -- ;
    BYTE_PERCENT                = 0x25    -- %
    BYTE_ASTERISK               = 0x2a    -- *
    BYTE_LEFTPAREN              = 0x28    -- (
    BYTE_NUMBER_SIGN            = 0x23    -- #
    BYTE_DOLLAR_SIGN            = 0x24    -- $
    BYTE_SLASH                  = 0x2f    -- /
    BYTE_RIGHTBRACKET           = 0x5d    -- ]
    BYTE_COLON                  = 0x3a    -- :
    BYTE_PLUS                   = 0x2b    -- +
    BYTE_UNDERLINE              = 0x5f    -- _
    BYTE_COMMA                  = 0x2c    -- ,
    BYTE_MINUS                  = 0x2d    -- -
    BYTE_AT_SIGN                = 0x40    -- @
    BYTE_LF                     = 0xa     -- \n

    BYTE_RIGHTPAREN             = 0x29    -- )
    BYTE_GREATERTHAN            = 0x3e    -- >
    BYTE_AMP                    = 0x26    -- &
    BYTE_VERTICAL               = 0x7c    -- |
    BYTE_CARET                  = 0x5e    -- ^
    BYTE_QUESTION               = 0x3f    -- ?
    BYTE_RIGHTWING              = 0x7d    -- }
    BYTE_TAB                    = 0x9     -- \t
    BYTE_CR                     = 0xd     -- \r

    BYTE_LEFTWING               = 0x7b    -- {
    BYTE_TILDE                  = 0x7e    -- ~
    BYTE_SINGLE_QUOTE           = 0x27    -- '
    BYTE_SPACE                  = 0x20
    BYTE_BACKSLASH              = 0x5c    -- \
    BYTE_DOUBLE_QUOTE           = 0x22    -- "
    BYTE_EQUALS                 = 0x3d    -- =
    BYTE_PERIOD                 = 0x2e    -- .
    BYTE_QUESTION               = 0x3f    -- ?

    SPACE_BYTE                  = {
        [BYTE_SPACE]            = true,
        [BYTE_TAB]              = true,
        [BYTE_CR]               = true,
        [BYTE_LF]               = true
    }

    PUBCHAR_BYTE                = {
        [BYTE_SPACE]            = true,
        [BYTE_CR]               = true,
        [BYTE_LF]               = true,
        [BYTE_MINUS]            = true,
        [BYTE_SINGLE_QUOTE]     = true,
        [BYTE_LEFTPAREN]        = true,
        [BYTE_RIGHTPAREN]       = true,
        [BYTE_PLUS]             = true,
        [BYTE_COMMA]            = true,
        [BYTE_PERIOD]           = true,
        [BYTE_SLASH]            = true,
        [BYTE_COLON]            = true,
        [BYTE_EQUALS]           = true,
        [BYTE_QUESTION]         = true,
        [BYTE_SEMICOLON]        = true,
        [BYTE_EXCLAMATION]      = true,
        [BYTE_ASTERISK]         = true,
        [BYTE_NUMBER_SIGN]      = true,
        [BYTE_AT_SIGN]          = true,
        [BYTE_DOLLAR_SIGN]      = true,
        [BYTE_UNDERLINE]        = true,
        [BYTE_PERCENT]          = true,
    }

    function isChar(code)
        -- #x9 | #xA | #xD | [#x20-#xD7FF] | [#xE000-#xFFFD] | [#x10000-#x10FFFF]
        if not code then return false end
        if code == 0x9 or code == 0xA or code == 0xD then return true end

        if code < 0x20 then
            return false
        elseif code >= 0x20    and code <= 0xD7FF then
            return true
        elseif code < 0xE000 then
            return false
        elseif code >= 0xE000  and code <= 0xFFFD then
            return true
        elseif code < 0x10000 then
            return false
        elseif code >= 0x10000 and code <= 0x10FFFF then
            return true
        else
            return false
        end
    end

    function isPubChar(code)
        -- #x20 | #xD | #xA | [a-zA-Z0-9] | [-'()+,./:=?;!*#@$_%]
        if not code then return false end
        if PUBCHAR_BYTE[code] then return true end

        if code < 0x30 then
            return false
        elseif code >= 0x30 and code <= 0x39 then       -- [0-9]
            return true
        elseif code < 0x41 then
            return false
        elseif code >= 0x41 and code <= 0x5A then       -- A-Z
            return true
        elseif code < 0x61 then
            return false
        elseif code >= 0x61 and code <= 0x7A then       -- a-z
            return true
        else
            return false
        end
    end

    function isNameChar(code, start)
        -- NameStartChar    ::= ":" | [A-Z] | "_" | [a-z] | [#xC0-#xD6] | [#xD8-#xF6] | [#xF8-#x2FF] | [#x370-#x37D] | [#x37F-#x1FFF] | [#x200C-#x200D] | [#x2070-#x218F] | [#x2C00-#x2FEF] | [#x3001-#xD7FF] | [#xF900-#xFDCF] | [#xFDF0-#xFFFD] | [#x10000-#xEFFFF]
        -- NameChar         ::= NameStartChar | "-" | "." | [0-9] | #xB7 | [#x0300-#x036F] | [#x203F-#x2040]
        -- Name             ::= NameStartChar (NameChar)*

        local isStartChar   = false

        if code == 0x3A or code == 0x5F then            -- : | _
            isStartChar     = true
        elseif code < 0x41 then
            -- pass
        elseif code >= 0x41 and code <= 0x5A then       -- A-Z
            isStartChar     = true
        elseif code < 0x61 then
            -- pass
        elseif code >= 0x61 and code <= 0x7A then       -- a-z
            isStartChar     = true
        elseif code < 0xC0 then
            -- pass
        elseif code >= 0xC0 and code <= 0xD6 then       -- [#xC0-#xD6]
            isStartChar     = true
        elseif code < 0xD8 then
                -- pass
        elseif code >= 0xD8 and code <= 0xF6 then       -- [#xD8-#xF6]
            isStartChar     = true
        elseif code < 0xF8 then
            -- pass
        elseif code >= 0xF8 and code <= 0x2FF then      -- [#xF8-#x2FF]
            isStartChar     = true
        elseif code < 0x370 then
            -- pass
        elseif code >= 0x370 and code <= 0x37D then     -- [#x370-#x37D]
            isStartChar     = true
        elseif code < 0x37F then
            -- pass
        elseif code >= 0x37F and code <= 0x1FFF then    -- [#x37F-#x1FFF]
            isStartChar     = true
        elseif code < 0x200C then
            -- pass
        elseif code >= 0x200C and code <= 0x200D then   -- [#x200C-#x200D]
            isStartChar     = true
        elseif code < 0x2070 then
            -- pass
        elseif code >= 0x2070 and code <= 0x218F then   -- [#x2070-#x218F]
            isStartChar     = true
        elseif code < 0x2C00 then
            -- pass
        elseif code >= 0x2C00 and code <= 0x2FEF then   -- [#x2C00-#x2FEF]
            isStartChar     = true
        elseif code < 0x3001 then
            -- pass
        elseif code >= 0x3001 and code <= 0xD7FF then   -- [#x3001-#xD7FF]
            isStartChar     = true
        elseif code < 0xF900 then
            -- pass
        elseif code >= 0xF900 and code <= 0xFDCF then   -- [#xF900-#xFDCF]
            isStartChar     = true
        elseif code < 0xFDF0 then
            -- pass
        elseif code >= 0xFDF0 and code <= 0xFFFD then   -- [#xFDF0-#xFFFD]
            isStartChar     = true
        elseif code < 0x10000 then
            -- pass
        elseif code >= 0x10000 and code <= 0xEFFFF then -- [#x10000-#xEFFFF]
            isStartChar     = true
        end

        if start or isStartChar then return isStartChar end

        if code == 0x2d or code == 0x2e or code == 0xB7 then    -- - | .
            return true
        elseif code < 0x30 then
            return false
        elseif code >= 0x30 and code <= 0x39 then       -- [0-9]
            return true
        elseif code < 0x0300 then
            return false
        elseif code >= x0300 and code <= 0x036F then    -- [#x0300-#x036F]
            return true
        elseif code < 0x203F then
            return false
        elseif code >= 0x203F and code <= 0x2040 then   -- [#x203F-#x2040]
            return true
        else
            return false
        end
    end

    function getSystemLiteral(xml, decode, start)
        --  ('"' [^"]* '"') | ("'" [^']* "'")
        local code, len         = decode(xml, start)
        if code == 0x27 or code == 0x22 then
            local token         = code
            local temp          = decode ~= UTF8Decode and List()
            local count         = 0

            start               = start + len
            code, len           = decode(xml, start)
            local sp            = start

            while code and code ~= token do
                count           = count + 1
                temp[count]     = code

                start           = start + len
                code, len       = decode(xml, start)
            end

            if code then
                return temp and temp:Map(EncodeData):Join() or xml:sub(sp, start - 1), start + len
            else
                return nil, start, "The system literal at position " .. sp .. " isn't closed"
            end
        end

        return nil, start
    end

    function getPublicLiteral(xml, decode, start)
        -- '"' PubidChar* '"' | "'" (PubidChar - "'")* "'"
        local code, len         = decode(xml, start)
        if code == 0x27 or code == 0x22 then
            local token         = code

            local temp          = decode ~= UTF8Decode and List()
            local count         = 0

            start               = start + len
            code, len           = decode(xml, start)
            local sp            = start

            while code and code ~= token and isPubChar(code) do
                count           = count + 1
                temp[count]     = code

                start           = start + len
                code, len       = decode(xml, start)
            end

            if code then
                return temp and temp:Map(EncodeData):Join() or xml:sub(sp, start - 1), start + len
            else
                return nil, start, "The public literal at position " .. sp .. " isn't closed"
            end
        end

        return nil, start
    end

    function getName(xml, decode, start)
        local sp                = start
        local code, len         = decode(xml, start)
        if isNameChar(code, true) then
            local temp          = decode ~= UTF8Decode and List()
            local count         = 1

            if temp then
                temp[1]         = code
            end

            start               = start + len
            code, len           = decode(xml, start)

            while isNameChar(code) do
                count           = count + 1
                if temp then
                    temp[count] = code
                end

                start           = start + len
                code, len       = decode(xml, start)
            end

            return temp and temp:Map(EncodeData):Join() or xml:sub(sp, start - 1), start
        end

        return nil, start
    end

    function processDTD(node, xml, decode, start)
        -- Only the document has DTD
        if not isObjectType(node, XmlDocument) then return start end

        -- Just get the entity definition, no xml validation in the first version
        local stack             = 1
        local code, len         = decode(xml, start)

        -- Skip white space
        while SPACE_BYTE[code] do
            start               = start + len
            code, len           = decode(xml, start)
        end

        code, start             = getName(xml, decode, start)
        if code then
            -- Try parse the entities

        end

        while code do
            if code == 0x3c then
                stack           = stack + 1
            elseif code == 0x3e then
                stack           = stack - 1
            end

            start               = start + len
            if stack == 0 then break end
            code, len           = decode(xml, start)
        end

        return code and start
    end

    function processXml(node, xml, decode, start)
        local code, len         = decode(xml, start)

        -- Skip white space
        while SPACE_BYTE[code] do
            start               = start + len
            code, len           = decode(xml, start)
        end

        local tagstart          = start

        -- Use number directly for performance
        if code ~= 0x3c then return nil, "The '<'' can't be found at the position " .. start end

        -- Check the next code to determine how to handle it
        start                   = start + len
        code, len               = decode(xml, start)

        if code == 0x3f then            -- <? TextDecl & Processing Instructions
            -- For now, just skip, only build the DOM
            while code do
                start           = start + len
                code, len       = decode(xml, start)

                if code == 0x3f then
                    start       = start + len
                    code, len   = decode(xml, start)

                    if code == 0x3e then
                        -- ?>
                        return processXml(node, xml, decode, start + len)
                    end
                end
            end

            -- No match, failure
            return nil, "The <? started at position " .. tagstart .. " has no close tag"
        elseif code == 0x21 then
            -- <!
            start               = start + len
            code, len           = decode(xml, start)

            if code == 0x2d then        -- <!-- Comment
                start           = start + len
                code, len       = decode(xml, start)

                if code ~= 0x2d then
                    return nil, "The '-' is required at the position " .. start .. " to mark a comment"
                end

                start           = start + len
                code, len       = decode(xml, start)

                if code == 0x2d or not isChar(code) then
                    return nil, "The char at the position " .. start .. " is not valid"
                end

                local miuslen   = 0

                while code do
                    start       = start + len
                    code, len   = decode(xml, start)

                    if code == 0x2d then
                        miuslen = miuslen + 1
                    else
                        if code == 0x3e then
                            -- -->
                            if miuslen > 2 then
                                return nil, "The '--->' at the position " .. start .. " is not valid"
                            elseif miuslen == 2 then
                                -- Skip the comment
                                return processXml(node, xml, decode, start + len)
                            end
                        end

                        miuslen = 0
                    end
                end

                return nil, "The comment start at position " .. tagstart .. " isn't closed."
            elseif code == 0x5b then    -- <![CDATA[  ]]>
                start           = start + len
                local sp        = start
                code, start     = getName(xml, decode, start)

                if code ~= "CDATA" then
                    return nil, "The 'CDATA' is required at position " .. sp
                end

                code, len       = decode(xml, start)
                if code ~= 0x5b then
                    return nil, "The '[' is required at position " .. start
                end

                sp              = start + len

                local rscnt     = 0
                local temp      = decode ~= UTF8Decode and List()
                local i         = 0

                while code do
                    start       = start + len
                    code, len = decode(xml, start)

                    i           = i + 1
                    if temp then
                        temp[i] = code
                    end

                    if code == 0x5d then
                        -- ]
                        rscnt = rscnt + 1
                    elseif code == 0x3e and rscnt >= 2 then
                        -- ]]>
                        if temp then
                            for i = 1, 3 do
                                temp:RemoveByIndex()
                            end
                        end

                        local content = XmlNode()
                        content.Text  = temp and temp:Map(EncodeData):Join() or xml:sub(sp, start - 3)
                        node:AddNode(content)

                        return processXml(node, xml, decode, start + len)
                    else
                        rscnt = 0
                    end
                end

                return nil, "The CDATA section at position " .. tagstart .. " isn't closed."
            else
                -- Document Type Definition
                start           = start + len
                local sp        = start
                code, start     = getName(xml, decode, start)

                if code ~= "DOCTYPE" then
                    return nil, "The 'DOCTYPE' is required at position " .. sp
                end

                start           = processDTD(node, xml, decode, start)
                if not start then
                    return nil, "The DOCTYPE start at position " .. tagstart .. " isn't closed.'"
                end

                return processXml(node, xml, decode, start)
            end
        else

        end
    end

    function processXmlDocument(document, xml)
        -- Check the first bytes to know the encoding
        local first, second     = strbyte(xml, 1, 2)
        local decode

        if (first == 0 and second == 0) then
            return nil, "Can't determine the xml's encoding."
        end

        if (not first or first > 0) and (not second or second > 0) then
            decode              = UTF8Decode
        elseif first == 0 then
            decode              = UTF16BEDecode
        elseif first == 0xFF and second == 0xFE then
            decode              = UTF16LEDecode
        else
            return nil, "The PLoop don't support the xml's encoding."
        end

        local start, err        = processXml(document, xml, decode, start)
        if not start and err then return nil, err end

        return document
    end

    class "XmlDocument" {}

    --- Represents a single node in the XML document
    class "XmlNode" (function(_ENV)
        extend "Iterable"

        export { Dictionary, XmlNodeList = List[XmlNode] }

        -----------------------------------------------------------
        --                       Property                        --
        -----------------------------------------------------------
        --- Gets an XmlAttributeCollection containing the attributes of this node.
        property "Attributes"   { set = false, default = function(self) return Dictionary() end }

        --- Gets the base URI of the current node.
        property "BaseURI"      { type = String }

        --- Gets all the child nodes of the node.
        property "ChildNodes"   { set = false, default = function(self) return XmlNodeList() end }

        --- Gets a value indicating whether this node has any child nodes.
        property "HasChildNodes"{ type = Boolean }

        --- Gets or sets the text of this node.
        property "Text"         { type = String }

        --- Gets a value indicating whether the node is read-only.
        property "IsReadOnly"   { type = Boolean }

        --- Gets the first child element with the specified name(include the namespace uri).
        __Indexer__()
        property "Item"         { get  = function(self, key) end }

        --- Gets the qualified name of the node, when overridden in a derived class.
        property "Name"         { type = String }

        --- Gets the namespace URI of this node.
        property "NamespaceURI" { type = String }

        --- Gets the node immediately following this node.
        property "NextSibling"  { type = XmlNode }

        --- Gets the type of the current node, when overridden in a derived class.
        property "NodeType"     { type = String }

        --- Gets the markup containing this node and all its child nodes.
        property "OuterXml"     { type = String }

        --- Gets the XmlDocument to which this node belongs.
        property "OwnerDocument"{ type = XmlDocument }

        --- Gets the parent of this node (for nodes that can have parents).
        property "ParentNode"   { type = XmlNode }

        --- Gets or sets the namespace prefix of this node.
        property "Prefix"       { type = String }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- Add Child node
        __Arguments__{ XmlNode }
        function AddNode(self, node)
            self.HasChildNodes  = true
            if not self.ChildNodes:Contains(node) then
                self.ChildNodes:Insert(node)

                node.ParentNode = self
                node.OwnerDocument = self.OwnerDocument
            end
        end

        --- Remove Child node
        __Arguments__{ XmlNode }
        function RemoveNode(self, node)
            if self.ChildNodes:Remove(node) then
                if #self.ChildNodes == 0 then
                    self.HasChildNodes = false
                end

                node.ParentNode = nil
                node.OwnerDocument = nil
            end
        end

        --- Clear All child nodes
        function ClearNodes(self)
            if self.HasChildNodes then
                self.HasChildNodes = false

                for _, node in self.ChildNodes:GetIterator() do
                    node.ParentNode = nil
                    node.OwnerDocument = nil
                end

                self.ChildNodes:Clear()
            end
        end
    end)

    --- Represents the XML Document
    class "XmlDocument" (function(_ENV)
        inherit "XmlNode"

        export "Dictionary"

        -----------------------------------------------------------
        --                       Property                        --
        -----------------------------------------------------------
        --- Gets the XmlDocument to which this node belongs.
        property "OwnerDocument"{ get = function(self) return self end }

        --- The entity decalred in the DTD
        property "Entities"     { set = false, default = function(self) return Dictionary() end }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- Load the text or stream data to the Xml document
        function Load(stream)

        end
    end)
end)