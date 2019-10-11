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

    local encoder
    local newEncoder            = function (name, settings)
        if type(settings) ~= "table" or type(settings.decode) ~= "function" or type(settings.encode) ~= "function" then
            error("Usage: System.Text.Encoding \"name\" { decode = Function, encode = function }", 3)
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
            if type(name) ~= "string" then error("Usage: System.Text.Encoding \"name\" { decode = Function, encode = function }", 2) end
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
end)
