--===========================================================================--
--                                                                           --
--                  System.Xml                                               --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2021/07/21                                               --
-- Update Date  :   2021/07/21                                               --
-- Version      :   0.1.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Xml"

    import "System.Text"

    __Sealed__()
    enum "XmlNodeType"          {
        None                    = 0,
        Element                 = 1, -- A xml element
        Attribute               = 2, -- An attribute
        Text                    = 3, -- The text content of a node
        CDATA                   = 4, -- A CDATA section
        EntityReference         = 5, -- An eneity reference
        Entity                  = 6, -- An eneity declaration
        ProcessingInstruction   = 7, -- A processing instruction
        Comment                 = 8, -- A comment
        Document                = 9, -- A xml document
        DocumentType            = 10,-- The document type declaration
        DocumentFragment        = 11,-- A document fragment
        Notation                = 12,-- A notation in the document type declaration
        Whitespace              = 13,-- White space between markup
        SignificantWhitespace   = 14,-- White space between markup in a mixed content model or white space within the xml:space="preserve" scope.
        EndElement              = 15,-- An end element tag
        EndEntity               = 16,-- The end of the entity replacement
        XmlDeclaration          = 17,-- The XML declaration
    }

    -----------------------------------------------------------------------
    --                              Helpers                              --
    -----------------------------------------------------------------------
    do
        export {
            BYTE_LESSTHAN       = 0x3c,    -- <
            BYTE_GRAVE_ACCENT   = 0x60,    -- `
            BYTE_LEFTBRACKET    = 0x5b,    -- [
            BYTE_EXCLAMATION    = 0x21,    -- !
            BYTE_SEMICOLON      = 0x3b,    -- ;
            BYTE_PERCENT        = 0x25,    -- %
            BYTE_ASTERISK       = 0x2a,    -- *
            BYTE_LEFTPAREN      = 0x28,    -- (
            BYTE_NUMBER_SIGN    = 0x23,    -- #
            BYTE_DOLLAR_SIGN    = 0x24,    -- $
            BYTE_SLASH          = 0x2f,    -- /
            BYTE_RIGHTBRACKET   = 0x5d,    -- ]
            BYTE_COLON          = 0x3a,    -- :
            BYTE_PLUS           = 0x2b,    -- +
            BYTE_UNDERLINE      = 0x5f,    -- _
            BYTE_COMMA          = 0x2c,    -- ,
            BYTE_MINUS          = 0x2d,    -- -
            BYTE_AT_SIGN        = 0x40,    -- @
            BYTE_LF             = 0xa,     -- \n

            BYTE_RIGHTPAREN     = 0x29,    -- )
            BYTE_GREATERTHAN    = 0x3e,    -- >
            BYTE_AMP            = 0x26,    -- &
            BYTE_VERTICAL       = 0x7c,    -- |
            BYTE_CARET          = 0x5e,    -- ^
            BYTE_QUESTION       = 0x3f,    -- ?
            BYTE_RIGHTWING      = 0x7d,    -- }
            BYTE_TAB            = 0x9,     -- \t
            BYTE_CR             = 0xd,     -- \r

            BYTE_LEFTWING       = 0x7b,    -- {
            BYTE_TILDE          = 0x7e,    -- ~
            BYTE_SINGLE_QUOTE   = 0x27,    -- '
            BYTE_SPACE          = 0x20,
            BYTE_BACKSLASH      = 0x5c,    -- \
            BYTE_DOUBLE_QUOTE   = 0x22,    -- "
            BYTE_EQUALS         = 0x3d,    -- =
            BYTE_PERIOD         = 0x2e,    -- .
        }

        SPACE_BYTE              = {
            [BYTE_SPACE]        = true,
            [BYTE_TAB]          = true,
            [BYTE_CR]           = true,
            [BYTE_LF]           = true
        }

        PUBCHAR_BYTE            = {
            [BYTE_SPACE]        = true,
            [BYTE_CR]           = true,
            [BYTE_LF]           = true,
            [BYTE_MINUS]        = true,
            [BYTE_SINGLE_QUOTE] = true,
            [BYTE_LEFTPAREN]    = true,
            [BYTE_RIGHTPAREN]   = true,
            [BYTE_PLUS]         = true,
            [BYTE_COMMA]        = true,
            [BYTE_PERIOD]       = true,
            [BYTE_SLASH]        = true,
            [BYTE_COLON]        = true,
            [BYTE_EQUALS]       = true,
            [BYTE_QUESTION]     = true,
            [BYTE_SEMICOLON]    = true,
            [BYTE_EXCLAMATION]  = true,
            [BYTE_ASTERISK]     = true,
            [BYTE_NUMBER_SIGN]  = true,
            [BYTE_AT_SIGN]      = true,
            [BYTE_DOLLAR_SIGN]  = true,
            [BYTE_UNDERLINE]    = true,
            [BYTE_PERCENT]      = true,
        }

        -- document ::=      prolog element Misc*

        -- Char     ::=      #x9 | #xA | #xD | [#x20-#xD7FF] | [#xE000-#xFFFD] | [#x10000-#x10FFFF]
        function isChar(code)
            -- #x9 | #xA | #xD | [#x20-#xD7FF] | [#xE000-#xFFFD] | [#x10000-#x10FFFF]
            if code < 0x20 then
                return code == 0x9 or code == 0xA or code == 0xD
            elseif code <= 0xD7FF then
                return true
            elseif code < 0xE000 then
                return false
            elseif code <= 0xFFFD then
                return true
            elseif code < 0x10000 then
                return false
            elseif code <= 0x10FFFF then
                return true
            else
                return false
            end
        end

        -- S       ::=      (#x20 | #x9 | #xD | #xA)+
        function isWhiteSpace(code)
            return code == 0x20 or code == 0x9 or code == 0xA or code == 0xD
        end

        -- PubidChar::=      #x20 | #xD | #xA | [a-zA-Z0-9] | [-'()+,./:=?;!*#@$_%]
        function isPubidChar(code)

        end

        -- NameStartChar::= ":" | [A-Z] | "_" | [a-z] | [#xC0-#xD6] | [#xD8-#xF6] | [#xF8-#x2FF] | [#x370-#x37D] | [#x37F-#x1FFF] | [#x200C-#x200D] | [#x2070-#x218F] | [#x2C00-#x2FEF] | [#x3001-#xD7FF] | [#xF900-#xFDCF] | [#xFDF0-#xFFFD] | [#x10000-#xEFFFF]
        -- NameChar     ::= NameStartChar | "-" | "." | [0-9] | #xB7 | [#x0300-#x036F] | [#x203F-#x2040]
        function isNameChar(code, start)
            if code < 0x30 then
                return not start and (
                        code == 0x2D or     -- -
                        code == 0x2E        -- .
                    )

            elseif code <= 0x39 then         -- [0-9]
                return not start

            elseif code < 0x41 then
                return code == 0x3A         -- :

            elseif code <= 0x5A then        -- A-Z
                return true

            elseif code < 0x61 then
                return code == 0x5F         -- _

            elseif code <= 0x7A then        -- a-z
                return true

            elseif code < 0xC0 then
                return not start and (
                        code == 0xB7        -- #xB7
                    )

            elseif code <= 0xD6 then        -- [#xC0-#xD6]
                return true

            elseif code < 0xD8 then
                    return false

            elseif code <= 0xF6 then        -- [#xD8-#xF6]
                return true

            elseif code < 0xF8 then
                return false

            elseif code <= 0x2FF then       -- [#xF8-#x2FF]
                return true

            elseif code < 0x300 then
                return false

            elseif code <= 0x36F then       -- [#x0300-#x036F]
                return not start

            elseif code < 0x370 then
                return false

            elseif code <= 0x37D then       -- [#x370-#x37D]
                return true

            elseif code < 0x37F then
                return false

            elseif code <= 0x1FFF then      -- [#x37F-#x1FFF]
                return true

            elseif code < 0x200C then
                return false

            elseif code <= 0x200D then      -- [#x200C-#x200D]
                return true

            elseif code < 0x203F then
                return false

            elseif code <= 0x2040 then      -- [#x203F-#x2040]
                return not start

            elseif code < 0x2070 then
                return false

            elseif code <= 0x218F then      -- [#x2070-#x218F]
                return true

            elseif code < 0x2C00 then
                return false

            elseif code <= 0x2FEF then      -- [#x2C00-#x2FEF]
                return true

            elseif code < 0x3001 then
                return false

            elseif code <= 0xD7FF then      -- [#x3001-#xD7FF]
                return true

            elseif code < 0xF900 then
                return false

            elseif code <= 0xFDCF then      -- [#xF900-#xFDCF]
                return true

            elseif code < 0xFDF0 then
                return false

            elseif code <= 0xFFFD then      -- [#xFDF0-#xFFFD]
                return true

            elseif code < 0x10000 then
                return false

            elseif code <= 0xEFFFF then     -- [#x10000-#xEFFFF]
                return true

            else
                return false

            end
        end
    end

    -----------------------------------------------------------------------
    --                             Exception                             --
    -----------------------------------------------------------------------
    __Sealed__()
    class "XmlException"        { Exception, Message = { type = String, default = "The xml is not valid" } }

    -----------------------------------------------------------------------
    --                               Class                               --
    -----------------------------------------------------------------------
    __Sealed__()
    class "XmlReader"           (function(_ENV)
        export {
            StringReader, EncodingException,

            throw               = throw,
            strbyte             = string.byte,
            UTF8Decodes         = UTF8Encoding.Decodes,
            UTF16LEDecodes      = UTF16EncodingLE.Decodes,
            UTF16BEDecodes      = UTF16EncodingBE.Decodes,
        }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        __Iterator__()
        function Read(self)
            -- Check the encoding
            local reader        = self[0]
            local head          = reader:ReadBlock(3)
            if not head or head == "" or #head < 2 then throw(XmlException()) end

            local f, s, t       = strbyte(head, 1, 3)
            local pos           = 0
            local decodes

            reader.Position     = 0

            if f == 0xEF and s == 0xBB and t == 0xBF then
                -- BOM Check
                reader.Position = 3
                decodes         = UTF8Decodes(reader)
            elseif f == 0 and s == 0 then
                throw(EncodingException())
            elseif first > 0 and second > 0 then
                decodes         = UTF8Decodes(reader)
            elseif first == 0 then
                decodes         = UTF16BEDecodes(reader)
            else
                decodes         = UTF16LEDecodes(reader)
            end


        end


        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{ TextReader }
        function __new(self, reader)
            return { [0]        = reader }, true
        end

        __Arguments__{ String }
        function __new(self, str)
            return { [0]        = StringReader(str) }, true
        end
    end)

    -- Pre-declaration
    class "XmlNode"             {}
    class "XmlDocument"         { XmlNode }
    class "XmlElement"          { XmlNode }

    --- Represents a single node in the XML document
    __Sealed__()
    class "XmlNode"             (function(_ENV)
        --- Gets the attributes of this node
        property "Attributes"   { type = Table, default = Toolset.newtable }

        --- Gets the child elments
        property "ChildNodes"   { type = List, default = function(self) return List() end }

        --- Gets a value indicating whether this node has any child nodes
        property "HasChildNodes"{ type = Boolean }

        --- Gets or sets the concatenated values of the node and all its child nodes
        property "InnerText"    { type = String }

        --- Gets or sets the markup representing only the child nodes of this node
        property "InnerXml"     { type = String }

        --- Gets the local name of the node, when overridden in a derived class
        property "LocalName"    { type = String }

        --- Gets the qualified name of the node
        property "Name"         { type = String }

        --- Gets the namespace URI of this node
        property "NamespaceURI" { type = String }

        --- Gets the type of the current node
        property "NodeType"     { type = XmlNodeType }

        --- Gets the markup containing this node and all its child nodes
        property "OuterXml"     { type = String }

        --- Gets the XmlDocument to which the current node belongs
        property "OwnerDocument"{ type = XmlDocument }

        --- Gets the parent node of this node
        property "ParentNode"   { type = XmlNode }

        --- Gets or sets the namespace prefix of this node
        property "Prefix"       { type = String }
    end)

    --- Represents a xml element
    __Sealed__()
    class "XmlElement"          (function(_ENV)

        -- <Person><name>Martin</name><age>33</age></Person>
        -- <prefix:localname xmlns:prefix='namespace URI'/>
        -- <pre:Person xmlns:pre='urn:example-org:People' ><pre:name>Martin</pre:name><pre:age>33</pre:age></pre:Person>
        -- <Person xmlns='urn:example-org:People' ><name>Martin</name><age>33</age></Person>
        -- Attributes: name='value'   name="value"
        -- Unprefixed attributes are not in any namespace even if a default namespace declaration is in scope

        -- Processing instructions: <?target data?>

        -- <!-- comment text --> The character sequence -- may not appear inside a comment.
        -- Other markup characters such as less than, greater than, and ampersand (&),
        -- may appear inside comments but are not treated as markup. Thus, entity references that appear inside comments are not expanded.

        -- Whitespace
        --  Prohibited character literals: &lt; < &amp; & &gt; > &apos; ' &quot; "

        -- <![CDATA[ text content possibly containing literal < or & characters ]]>

        -- <?xml version='1.0' encoding='character encoding' standalone='yes|no'?>
        -- The order of these attributes within an XML declaration is fixed.

        -- Character references: &#DecimalUnicodeValue; &#xHexadecimalUnicodeValue;
        -- Character references can only be used for attribute and element content

    end)

    --- The class represents a xml document
    __Sealed__()
    class "XmlDocument"         (function(_ENV)


        --- The root XmlElement for the document
        property "DocumentElement" { type = XmlElement, default = function(self) return XmlElement(self) end }
    end)

    --- Represents the document type declaration
    __Sealed__()
    class "XmlDocumentType"     (function(_ENV)
        inherit "XmlNode"

        --  <!DOCTYPE name [
        --      <!-- insert declarations here -->
        -- ]>
        -- <!DOCTYPE name PUBLIC "publicId" "systemId">
        -- <!DOCTYPE name SYSTEM "systemId">
        -- A system identifier is a URI that identifies the location of the resource
        -- a public identifier is a location-independent identifier


        -- ELEMENT      <!ELEMENT name content-model*>
        --              ANY         Any child is allowed within the element.
        --              EMPTY       No children are allowed within the element.
        --              (#PCDATA)   Only text is allowed within the element.
        --              (child1,child2,...) Only the specified children in the order given are allowed within the element
        --              (child1|child2|...) Only one of the specified children is allowed within the element.
        --      Occurrence modifiers
        --                          No modifier means the child or child group must appear exactly once at the specified location (except in a choice content model)
        --                  *       Annotated child or child group may appear zero or more times at the specified location.
        --                  +       Annotated child or child group may appear one or more times at the specified location.
        --                  ?       Annotated child or child group may appear zero or one time at the specified location
        --              <!ELEMENT name (fname, (mi|mname)?, lname)?>

        -- ATTLIST      <!ATTLIST eName aName1 aType default
        --                              aName2 aType default ...>
        --      Attribute types
        --              CDATA       Arbitrary character data
        --              ID          A name that is unique within the document
        --              IDREF       A reference to an ID value in the document
        --              IDREFS      A space-delimited list of IDREF values
        --              ENTITY      The name of an unparsed entity declared in the DTD
        --              ENTITIES    A space-delimited list of ENTITY values
        --              NMTOKEN     A valid XML name (see Chapter 1)
        --              NMTOKENS    A space-delimited list of NMTOKEN values
        --      Default declarations
        --              "value"     Default value for attribute
        --              #REQUIRED   Attribute is required on the given element
        --              #IMPLIED    Attribute is optional on the given element
        --              #FIXED "value"  Attribute always has the specified fixed value
        --      Attribute enumerations
        --              <!ATTLIST eName aName (token1 | token2 | token3 | ...)>
        --              <!ATTLIST eName aName NOTATION (token1 | token2 | token3 | ...)>

        --          <!-- emp.dtd -->
        --          <!ELEMENT employee (address)>
        --          <!-- NMTOKEN enumeration -->
        --          <!ATTLIST employee title (president|vice-pres|secretary|sales) #REQUIRED>
        --          <!ELEMENT address (#PCDATA)>
        --          <!-- NOTATION enumeration -->
        --          <!ATTLIST address format NOTATION (cs|lf) "cs">
        --          <!NOTATION cs PUBLIC "urn:addresses:comma-separated">
        --          <!NOTATION lf PUBLIC "urn:addresses:line-breaks">

        -- ENTITY       <!ENTITY ... >
        -- A given entity is either general or parameter, internal or external, and parsed or unparsed
        --          General     Entity may only be referenced in an XML document (not the DTD)
        --          Parameter   Entity may only be referenced in a DTD (not the XML document)
        --
        --          Internal    Entity value defined inline
        --          External    Entity value contained in an external resource
        --
        --          Parsed      Entity value parsed by a processor as XML/DTD content
        --          Unparsed    Entity value not parsed by XML processor, must be general and external
        --
        --              <!ENTITY [%] name extID|"value" parsed|(NDATA nname)>
        --      Distinct entity types
        --          <!ENTITY % name "value"> Internal parameter
        --          <!ENTITY % name SYSTEM "systemId"> External parameter
        --          <!ENTITY name "value"> Internal general
        --          <!ENTITY name SYSTEM "systemId"> External parsed general
        --          <!ENTITY name SYSTEM "systemId" NDATA nname> Unparsed
        --
        --      Entity references
        --          &name;      General
        --          %name;      Parameter
        --          Name is used as the value of an attribute of type ENTITY or ENTITIES (see Section 2.4)  Unparsed

        -- NOTATION     Notation declarations associate a name with a type identifier, which can be either a public or a system identifier.
        --          <!NOTATION name PUBLIC "publicId">

        -- INCLUDE and IGNORE   Combine withe the ENTITY to switch the declaration
        --          <![INCLUDE[...]]>
        --          <![IGNORE[...]]>
    end)

    --- XPath defines a tree model against which all expressions are evaluated
    __Sealed__()
    class "XPath"               (function(_ENV)
        --- XPath expressions are evaluated against a document’s logical tree structure to identify a set of nodes

        -- location path:       /invoice/item/price : node-set
        -- Data types:          node-sets | booleans | numbers | strings
        --      Node string-value:
        --          Root        Concatenation of all descendant text nodes not innerXML, just concat text nodes
        --          Element     Concatenation of all descendant text nodes
        --          Attribute   Normalized attribute value
        --          Text        Character data
        --          Processing  instruction Character data following the processing instruction target
        --          Comment     Character data within comment delimiters
        --          Namespace   Namespace URI
        --      XPath expressions and operators(with priority):
        --          Location paths          /, //, |
        --          Boolean expressions     or, and
        --          Equality expressions    =, !=
        --          Relational expressions  <=, <, >=, >
        --          Numerical expressions   +, –, div, mod, *, – (unary)
        --      context node-set    the current set of nodes that has been identified up to a given point in the expression
        --      context node        the current node being processed
        --      Location path expressions
        --          /step/step/step/... | step/step/...
        --      Location steps
        --          axis::node-test[predicate1][predicate2][...]
        --          child::item[1]/child::sku[.>100][1]/child::text()
        --      Axis descriptions
        --          self                Identifies the context node
        --          child               Default axis. Identifies the children of the context node
        --          parent              Identifies the parent of the context node.
        --          descendant          Identifies the descendants of the context node(child, child of child)
        --          descendant-or-self  Identifies the context node and the descendant axis
        --          ancestor            Identifies the ancestors of the context node
        --          ancestor-or-self    Identifies the context node and the ancestor axis
        --          following           Identifies all nodes that are after the context node in document order
        --          following-sibling   Identifies the siblings of the context node from the following axis
        --          preceding           Identifies all nodes that are before the context node in document order
        --          preceding-sibling   Identifies the siblings of the context node from the preceding axis
        --          attribute           Identifies the attributes of the context node.
        --          namespace           Identifies the namespace nodes of the context node
        --      Node test by name
        --      Node test by type
        --          text()                          Identifies text nodes.
        --          comment()                       Identifies comment nodes.
        --          processing-instruction(target?) Identifies processing instruction nodes that match the (optionally) specified target string.
        --          node()                          Identifies all nodes in an axis regardless of type.
        --      Predicate
        --          Predicates are placed inside square brackets [...] at the end of a location step
        --          Operators:                  or, and, =, !=
        --
        --       Location path abbreviations
        --          child::                     omitted
        --          attribute::                 @
        --          self::node()                .
        --          parent::node()              ..
        --          /descendant-orself::node()/ //
        --          [position()=number]         [number]
    end)
end)