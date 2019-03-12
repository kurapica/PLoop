--===========================================================================--
--                                                                           --
--                           System.Configuration                            --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2018/05/11                                               --
-- Update Date  :   2019/03/12                                               --
-- Version      :   1.0.1                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Configuration"

    --- The config sections are used as containers for configurations.
    --
    -- the configurations are pairs of name and type that'd be registered
    -- in anywhere with or without special handlers, so we can parse the
    -- configurations in one place for the whole system.
    __Sealed__() __NoNilValue__(true) __NoRawSet__(true)
    class "ConfigSection" (function(_ENV)
        export { "pairs", "type", "getmetatable", yield = coroutine.yield, Enum, Struct, Interface, Class, Any, ConfigSection, List }

        -----------------------------------------------------------
        --                         event                         --
        -----------------------------------------------------------
        --- When the config is parsed by the config section
        event "OnParse"

        --- When the config is parsed by the config section's field
        event "OnFieldParse"

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- Parse the config settings with arguments to be distributed
        __Arguments__{ Table, Any * 0 }
        function ParseConfig(self, config, ...)
            local msg
            local fields    = self.__Fields
            local sections  = self.__Sections

            for _, name in self.__Order:GetIterator() do
                local val   = config[name]

                if val ~= nil then
                    local fldtype       = fields[name]
                    if fldtype then
                        val, msg        = getmetatable(fldtype).ValidateValue(fldtype, val)

                        if msg then return nil, msg:gsub("%%s", "%%s" .. "." .. name) end
                        config[name]    = val

                        OnFieldParse(self, name, val, ...)
                    end

                    local subsect       = sections[name]
                    if subsect then
                        val, msg        = subsect:ParseConfig(val, ...)
                        if msg then return nil, msg:gsub("%%s", "%%s" .. "." .. name) end
                        config[name]    = val
                    end
                end
            end

            OnParse(self, config, ...)

            return config
        end

        --- Gets all fields with orders
        __Iterator__() function GetFields(self)
            local fields        = self.__Fields
            for _, name in self.__Order:GetIterator() do
                local type      = fields[name]
                if type then yield(name, type) end
            end
        end

        --- Gets all sections with orders
        __Iterator__() function GetSections(self)
            local sections      = self.__Sections
            for _, name in self.__Order:GetIterator() do
                local sect      = sections[name]
                if sect then yield(name, sect) end
            end
        end

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- The fields of the config section
        __Indexer__() property "Field" { type = EnumType + StructType,
            set     = function(self, name, type)
                if not self.__Order:Contains(name) then self.__Order:Insert(name) end

                self.__Fields[name]     = type or Any
                self.__Sections[name]   = nil
            end,
            get     = function(self, name)
                return self.__Fields[name]
            end,
        }

        --- The sub-sections of the config section
        __Indexer__() property "Section" { type = ConfigSection,
            set     = function(self, name, sect)
                if not self.__Order:Contains(name) then self.__Order:Insert(name) end

                self.__Sections[name]   = sect
                self.__Fields[name]     = nil
            end,
            get     = function(self, name)
                local secset            = self.__Sections[name]
                if not secset and not self.__Fields[name] then
                    if not self.__Order:Contains(name) then self.__Order:Insert(name) end

                    secset              = ConfigSection()
                    self.__Sections[name] = secset
                end
                return secset
            end,
        }

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        function __new(_)
            return {
                __Order     = List(),
                __Fields    = {},
                __Sections  = {},
            }
        end

        -----------------------------------------------------------
        --                      meta-method                      --
        -----------------------------------------------------------
        function __index(self, key)
            if type(key) ~= "string" then return end
            local val = self.__Fields[key]
            return val or self.Section[key]
        end
    end)

    --- The binder for the config section and handler
    -- @usage :
    --      __ConfigSection__( System.Web.ConfigSection.Html.Render, { nolinebreak = Boolean, noindent = Boolean  } )
    --      function HtmlRenderConfig(config, ...)
    --          print(config.nolinebreak)
    --      end
    --
    --      __ConfigSection__( System.Web.ConfigSection.Controller, "jsonprovider", -FormatProvider)
    --      function JsonProviderConfig(field, value, ...)
    --          print("The new json provider is " .. value)
    --      end
    __Sealed__() class "__ConfigSection__" (function(_ENV)
        extend "IAttachAttribute"

        export {
            pairs               = pairs,
            type                = type,
            strformat           = string.format,
            isenum              = Enum.Validate,
            isstruct            = Struct.Validate,
        }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- attach data on the target
        -- @param   target                      the target
        -- @param   targettype                  the target type
        -- @param   owner                       the target's owner
        -- @param   name                        the target's name in the owner
        -- @param   stack                       the stack level
        -- @return  data                        the attribute data to be attached
        function AttachAttribute(self, target, targettype, owner, name, stack)
            if self[3] then
                local section = self[1]
                local fldname = self[2]
                section.Field[fldname] = self[3]

                section.OnFieldParse = section.OnFieldParse + function(self, fld, val, ...)
                    if fld == fldname then
                        return target(fld, val, ...)
                    end
                end
            else
                local section = self[1]
                if self[2] then
                    for k, v in pairs(self[2]) do
                        if type(k) == "string" and (isenum(v) or isstruct(v)) then
                            section.Field[k] = v
                        else
                            error("The field's type can only be enum or struct", stack + 1)
                        end
                    end
                end
                section.OnParse = section.OnParse + function(self, ...) return target(...) end
            end
        end

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- the attribute target
        property "AttributeTarget"  { set = false, default = AttributeTargets.Function }

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{ ConfigSection, Table/nil }
        function __new(_, section, fields)
            return { section, fields, false }, true
        end

        __Arguments__{ ConfigSection, NEString, (EnumType + StructType)/Any }
        function __new(_, section, name, type)
            return { section, name, type }, true
        end
    end)
end)
