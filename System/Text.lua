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
    export { "type", "error", "ipairs", tconcat = table.concat, istype = Class.IsObjectType, Prototype, Namespace, Toolset, Iterable }

    __Sealed__() __Final__() interface "System.Text" {}

    namespace "System.Text"

    -----------------------------------------------------------------------
    --                             Encoding                              --
    -----------------------------------------------------------------------
    local encoder
    local newEncoder            = function (name, settings)
        if type(settings) ~= "table" or type(settings.decode) ~= "function" or type(settings.encode) ~= "function" then
            error("Usage: System.Text.Encoding \"name\" { decode = Function, encode = Function }", 3)
        end

        local encode            = settings.encode
        local decode            = settings.decode

        if not name:find(".", 1, true) then name = "System.Text." .. name end

        if Namespace.GetNamespace(name) then error("The " .. name .. " is already existed", 3) end

        local decodes           = function(str, startp)
            startp              = startp or 1
            local code, len     = decode(str, startp)
            if code then return startp + (len or 1), code end
        end

        return Namespace.SaveNamespace(name, Prototype {
            __index             = {
                -- Encode a unicode code point
                Encode          = encode,

                -- Decode a char based on  the index, default 1
                Decode          = decode,

                -- Decode a text
                Decodes         = function (str, startp) return decodes, str, startp end,

                -- Encode unicode code points
                Encodes         = function (codes, arg1, arg2)
                    local ty    = type(codes)
                    if ty      == "function" then
                        -- pass
                    elseif ty  == "table" then
                        if istype(codes, Iterable) then
                            codes, arg1, arg2 = codes:GetIterator()
                        else
                            codes, arg1, arg2 = ipairs(codes)
                        end
                    else
                        return
                    end

                    local cache = {}
                    local i     = 1
                    local ec    = encode

                    for _, code in codes, arg1, arg2 do
                        cache[i]= ec(code)
                        i       = i + 1
                    end

                    return tconcat(cache)
                end
            },
            __newindex          = Toolset.readonly,
            __tostring          = Namespace.GetNamespaceName,
            __metatable         = encoder,
        })
    end

    encoder                     = Prototype (ValidateType, {
        __index                 = {
            ["IsImmutable"]     = function() return true, true end;
            ["ValidateValue"]   = function(_, value) return getmetatable(value) == encoder and value ~= encoder and value end;
            ["Validate"]        = function(value)    return getmetatable(value) == encoder and value ~= encoder and value end;
        },
        __newindex              = Toolset.readonly,
        __call                  = function(self, name)
            if type(name) ~= "string" then error("Usage: System.Text.Encoding \"name\" { decode = Function, encode = Function }", 2) end
            return function(settings)
                local coder     = newEncoder(name, settings)
                return coder
            end
        end,
        __tostring              = Namespace.GetNamespaceName,
    })

    --- Represents a character encoding
    Namespace.SaveNamespace("System.Text.Encoding", encoder)

    --- Represents the ASCII encoding
    System.Text.Encoding "ASCIIEncoding" {
        encode                  = string.char,
        decode                  = string.byte,
    }

    -----------------------------------------------------------------------
    --                          Reader & Writer                          --
    -----------------------------------------------------------------------
    --- Represents a writer that can write a sequential series of characters
    __Sealed__()
    class "TextWriter" (function (_ENV)
        extend "IAutoClose"

        --- Gets the character encoding in which the output is written.
        __Abstract__() property "Encoding" { type = System.Text.Encoding }

        --- Gets or sets the line terminator string used by the current TextWriter.
        __Abstract__() property "NewLine" { type = String, default = "\n" }

        --- Clears all buffers for the current writer and causes any buffered data to be written to the underlying device.
        __Abstract__() function Flush(self) end

        --- Writes the data to the text string or stream.
        __Abstract__() function Write(self, data) end

        --- Writes the data(could be nil) followed by a line terminator to the text string or stream.
        __Abstract__() function WriteLine(self, data) if data then self:Write(data) end self:Write(self.NewLine) end
    end)

    --- Represents a reader that can read a sequential series of characters
    __Sealed__()
    class "TextReader" (function (_ENV)
        extend "IAutoClose"

        --- Gets the character encoding in which the input is read.
        __Abstract__() property "Encoding" { type = System.Text.Encoding }

        --- Gets or Sets the operation position
        __Abstract__() property "Position" { type = Number }

        --- Reads the next character from the text reader and advances the character position by one character.
        __Abstract__() function Read(self) end

        --- Reads a line of characters from the text reader and returns the data as a string.
        __Abstract__() function ReadLine(self) end

        --- Return the ReadLine method and self for a generic for
        function ReadLines(self) return self.ReadLine, self end

        --- Reads a specified maximum number of characters from the current text reader and writes the data to a buffer, beginning at the specified index.
        __Abstract__() function ReadBlock(self, count, index) end

        --- Reads all characters from the current position to the end of the text reader and returns them as one string.
        __Abstract__() function ReadToEnd(self) end
    end)
end)
