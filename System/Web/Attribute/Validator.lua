--===========================================================================--
--                                                                           --
--                          Attribute for Validator                          --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2018/04/04                                               --
-- Update Date  :   2021/07/13                                               --
-- Version      :   1.4.1                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Web"

    import "System.Configuration"

    --- the login & authority validator
    __Sealed__() __NoNilValue__(false) class "__Login__" (function(_ENV)
        extend "IInitAttribute"

        export {
            unpack              = unpack,
            UrlEncode           = UrlEncode,
            HttpMethod_GET      = HttpMethod.GET,
            IsObjectType        = Class.IsObjectType,

            AttributeTargets, __Login__, Application
        }

        local function redirect(context, path, settings)
            local request       = context.Request
            if request:IsHtmlAccepted() then
                path            = path or settings and settings.LoginPage or __Login__.DefaultLoginPage

                if path then
                    if request.HttpMethod == HttpMethod_GET then
                        local k = settings and settings.PathKey or __Login__.DefaultPathKey
                        if k and k ~= "" then
                            path= path .. "?" .. k .. "=" .. UrlEncode(request.RawUrl)
                        end
                    end
                    return context.Response:Redirect(path)
                else
                    context.Response.StatusCode = HTTP_STATUS.DENIED
                end
            else
                context.Response.StatusCode = HTTP_STATUS.DENIED
            end
        end

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        function InitDefinition(self, target, targettype, definition, owner, name, stack)
            local authority     = self[1]

            if targettype == AttributeTargets.Function then
                if authority then
                    return function(context, ...)
                        local settings      = context.Application[__Login__]
                        local result, path
                        if (settings and settings.LoginChecker or __Login__.DefaultLoginChecker)(context) then
                            result, path    = (settings and settings.AuthorityChecker or __Login__.DefaultAuthorityChecker)(context, unpack(authority))

                            if result then return definition(context, ...) end
                        end

                        return redirect(context, path, settings)
                    end
                else
                    return function(context, ...)
                        local settings  = context.Application[__Login__]
                        if (settings and settings.LoginChecker or __Login__.DefaultLoginChecker)(context) then
                            return definition(context, ...)
                        end

                        return redirect(context, nil, settings)
                    end
                end
            else
                if authority then
                    return function(self, context, ...)
                        local settings      = context.Application[__Login__]
                        local result, path
                        if (settings and settings.LoginChecker or __Login__.DefaultLoginChecker)(context) then
                            result, path    = (settings and settings.AuthorityChecker or __Login__.DefaultAuthorityChecker)(context, unpack(authority))

                            if result then return definition(self, context, ...) end
                        end

                        return redirect(context, path, settings)
                    end
                else
                    return function(self, context, ...)
                        local settings  = context.Application[__Login__]
                        if (settings and settings.LoginChecker or __Login__.DefaultLoginChecker)(context) then
                            return definition(self, context, ...)
                        end

                        return redirect(context, nil, settings)
                    end
                end
            end
        end

        -----------------------------------------------------------
        --                    static property                    --
        -----------------------------------------------------------
        --- the default key in the session items for checking
        __Static__() property "DefaultKey"              { type = String, default = "user" }

        --- the default login checker, so the user can do their own login check logic
        __Static__() property "DefaultLoginChecker"     {
            type                    = Function,
            default                 = function(context)
                local settings      = context.Application[__Login__]
                return context.Session.Items[settings and settings.Key or __Login__.DefaultKey] ~= nil
            end,
        }

        --- the default login path
        __Static__() property "DefaultLoginPage"        { type = String }

        --- the default key to send the request path to the login page
        __Static__() property "DefaultPathKey"          { type = String, default = "path"}

        --- the default authority checker
        __Static__() property "DefaultAuthorityChecker" { type = Function, default = function() return true end }

        --- the key in the session items for checking
        __Indexer__(Application)
        __Static__() property "Key"                     {
            type                    = String,
            set = function(self, app, value)
                app                 = app._Application

                local settings      = app[__Login__] or {}
                settings.Key        = value

                app[__Login__]      = settings
            end,
        }

        --- the login checker
        __Indexer__(Application)
        __Static__() property "LoginChecker"            {
            type                    = Function,
            set                     = function(self, app, value)
                app                 = app._Application

                local settings      = app[__Login__] or {}
                settings.LoginChecker = value

                app[__Login__]      = settings
            end,
        }

        --- the login path
        __Indexer__(Application)
        __Static__() property "LoginPage"               {
            type                    = String,
            set                     = function(self, app, value)
                app                 = app._Application

                local settings      = app[__Login__] or {}
                settings.LoginPage  = value

                app[__Login__]      = settings
            end,
        }

        --- the key to send the request path to the login page
        __Indexer__(Application)
        __Static__() property "PathKey"                 {
            type                    = String,
            set                     = function(self, app, value)
                app                 = app._Application

                local settings      = app[__Login__] or {}
                settings.PathKey    = value

                app[__Login__]      = settings
            end,
        }

        --- the authority checker
        __Indexer__(Application)
        __Static__() property "AuthorityChecker"        {
            type                    = Function,
            set                     = function(self, app, value)
                app                 = app._Application

                local settings      = app[__Login__] or {}
                settings.AuthorityChecker = value

                app[__Login__]      = settings
            end,
        }

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- the attribute target
        property "AttributeTarget"  { set = false, default = AttributeTargets.Function + AttributeTargets.Method }

        --- the attribute priority
        property "Priority"         { set = false, default = AttributePriority.Lower }

        -- the attribute priority sub level
        property "SubLevel"         { set = false, default = - 2000 }

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        function __new(_, val, ...)
            if val then
                return { { val, ... } }, true
            else
                return {}, true
            end
        end
    end)

    --- the form validator
    __Sealed__() class "__Form__" (function(_ENV)
        extend "IInitAttribute"

        export {
            Serialize           = Serialization.Serialize,
            Deserialize         = Serialization.Deserialize,
            GetStructCategory   = Struct.GetStructCategory,
            GetMembers          = Struct.GetMembers,
            GetArrayElement     = Struct.GetArrayElement,
            GetDictionaryKey    = Struct.GetDictionaryKey,
            GetDictionaryValue  = Struct.GetDictionaryValue,
            IsSubStruct         = Struct.IsSubType,
            IsStruct            = Struct.Validate,
            IsEnum              = Enum.Validate,
            GetEnumValues       = Enum.GetEnumValues,
            ValidateStructValue = Struct.ValidateValue,
            ValidateEnumValue   = Enum.ValidateValue,

            strmatch            = string.match,
            select              = select,
            tonumber            = tonumber,
            pairs               = pairs,
            type                = type,
            next                = next,
            pcall               = pcall,
            strgsub             = string.gsub,
            strtrim             = function (s) return s and strgsub(s, "^%s*(.-)%s*$", "%1") or "" end,

            MEMBER              = StructCategory.MEMBER,
            ARRAY               = StructCategory.ARRAY,
            CUSTOM              = StructCategory.CUSTOM,
            DICTIONARY          = StructCategory.DICTIONARY,
            Debug               = Logger.Default[Logger.LogLevel.Debug],

            stringProvider      = Serialization.StringFormatProvider(),

            HttpMethod_GET      = HttpMethod.GET,

            __Form__, Attribute, AttributeTargets, JsonFormatProvider, Number, Date,
        }

        local function validateNotypeValue(config, value)
            if type(value) == "string" then value = strtrim(value) end
            if value == "" then value = nil end

            if value == nil and config.require then return nil, __Form__.RequireMessage end
            return value
        end

        local function validateEnumValue(config, value)
            if type(value) == "string" then value = strtrim(value) end
            if value == "" then value = nil end

            if value == nil then
                return nil, config.require and __Form__.RequireMessage or nil
            else
                if config.number then
                    local num   = tonumber(value)
                    if not num then return value, __Form__.NumberMessage end
                    value       = num
                end

                local ret, err  = ValidateEnumValue(config.type, value)
                if err then return value, true end
                return ret
            end
        end

        local function validateDateValue(config, value)
            if type(value) == "string" then value = strtrim(value) end
            if value == "" then value = nil end

            if value == nil then
                return nil, config.require and __Form__.RequireMessage or nil
            else
                local number    = tonumber(value)
                local ok, val   = pcall(Deserialize, stringProvider, number or value, Date, number and "NUMBER" or "STRING")
                if not ok then return value, __Form__.DateMessage end
                return val
            end
        end

        local function validateCustomValue(config, value)
            if type(value) == "string" then value = strtrim(value) end
            if value == "" then value = nil end

            if value == nil then
                return nil, config.require and __Form__.RequireMessage or nil
            else
                if config.number then
                    local num   = tonumber(value)
                    if not num then return value, __Form__.NumberMessage end
                    value       = num
                end

                local ret, err  = ValidateStructValue(config.type, value)
                if err then return value, err end
                return ret
            end
        end

        local function validateArrayValue(config, value)
            if type(value) == "string" then
                local ok, val   = pcall(Deserialize, JsonFormatProvider(), value)
                if ok then value= val end
            end

            if type(value) ~= "table" then
                if value == nil then
                    return nil, config.require and __Form__.RequireMessage or nil
                end

                -- Could be one element
                local errs
                local val, err  = config.elementconfig:validate(value)
                value           = { val }
                if err then
                    errs        = {}
                    errs[1]     = err
                end

                return value, errs
            elseif value[1] == nil and next(value) ~= nil then
                local errs
                local val, err  = config.elementconfig:validate(value)
                value           = { val }
                if err then
                    errs        = {}
                    errs[1]     = err
                end

                return value, errs
            else
                local errs
                local avalid    = config.elementconfig

                -- The array may have some empty holes
                for i, v in pairs(value) do
                    if type(i) == "number" then
                        local val, err = avalid:validate(v)
                        value[i]= val
                        if err then
                            errs    = errs or {}
                            errs[i] = err
                        end
                    end
                end

                return value, errs
            end
        end

        local function validateMemberValue(config, value)
            if type(value) == "string" then
                local ok, val   = pcall(Deserialize, JsonFormatProvider(), value)
                if ok then value= val end
            end

            if type(value) ~= "table" then
                return nil, config.require and __Form__.RequireMessage or nil
            else
                local errs
                for name, config in pairs(config.memberconfigs) do
                    local val, err  = config:validate(value[name])
                    value[name]     = val
                    if err then
                        errs        = errs or {}
                        errs[name]  = err
                    end
                end
                return value, errs
            end
        end

        local function validateDictValue(config, value)
            if type(value) == "string" then
                local ok, val   = pcall(Deserialize, JsonFormatProvider(), value)
                if ok then value= val end
            end

            if type(value) ~= "table" then
                if value == nil then
                    return nil, config.require and __Form__.RequireMessage or nil
                else
                    return value, __Form__.TabelMessage
                end
            else
                local errs
                local kvalid    = config.keyconfig
                local vvalid    = config.valconfig

                for k, v in pairs(value) do
                    local _, err= kvalid:validate(k)
                    if err then
                        errs    = errs or {}
                        errs[k] = err
                    else
                        local val, err = vvalid:validate(v)
                        if err then
                            errs    = errs or {}
                            errs[k] = err
                        else
                            value[k]= val
                        end
                    end
                end

                return value, errs
            end
        end

        local function parseType(vtype, require, stack)
            if vtype then
                if IsEnum(vtype) then
                    for k, v in GetEnumValues(vtype) do
                        -- simple check, normally should be number
                        return { type = vtype, validate = validateEnumValue, number = type(v) == "number", require = require }
                    end
                elseif IsStruct(vtype) then
                    local category  = GetStructCategory(vtype)

                    if category == CUSTOM then
                        return { type = vtype, validate = validateCustomValue, number = IsSubStruct(vtype, Number), require = require }
                    elseif category == ARRAY then
                        return { elementconfig = parseType(GetArrayElement(vtype), nil, stack + 1), validate = validateArrayValue, require = require }
                    elseif category == MEMBER then
                        local memconfigs    = {}

                        for _, mem in GetMembers(vtype) do
                            memconfigs[mem:GetName()] = parseType(mem:GetType(), mem:IsRequire(), stack + 1)
                        end

                        return { memberconfigs = memconfigs, validate = validateMemberValue, require = require }
                    elseif category == DICTIONARY then
                        return { keyconfig = parseType(GetDictionaryKey(vtype), nil, stack + 1), valconfig = parseType(GetDictionaryValue(vtype), nil, stack + 1), validate = validateDictValue, require = require  }
                    end
                elseif vtype == Date then
                    return { type = Date, validate = validateDateValue, require = require }
                else
                    error("The " .. vtype .. " is not supported for form validation")
                end
            end
            return { validate = validateNotypeValue, require = require }
        end

        local function validateForm(query, config)
            local form          = {}
            local errors

            -- Init
            for key, val in pairs(query) do
                if type(val) == "string" then
                    val         = val:gsub("^%s*(.-)%s*$", "%1")
                    if val == "" then val = nil end
                end

                if val ~= nil then
                    local prev
                    local ct        = form

                    for p in key:gmatch("%P+") do
                        p           = tonumber(p) or p

                        if prev then
                            ct[prev]= type(ct[prev]) == "table" and ct[prev] or {}
                            ct      = ct[prev]
                            prev    = p
                        else
                            prev    = p
                        end
                    end

                    if prev then
                        ct[prev]    = val
                    end
                end
            end

            -- validate
            return config:validate(form)
        end

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        function InitDefinition(self, target, targettype, definition, owner, name, stack)
            if self[1] and GetStructCategory(self[1]) ~= MEMBER then error("The form validation type isn't valid", stack + 1) end

            local config    = parseType(self[1], nil, stack + 1)

            if targettype == AttributeTargets.Function then
                return function(context)
                    local request = context.Request
                    return definition(context, validateForm(request.HttpMethod == HttpMethod_GET and request.QueryString or request.Form, config))
                end
            else
                return function(self, context)
                    local request = context.Request
                    return definition(self, context, validateForm(request.HttpMethod == HttpMethod_GET and request.QueryString or request.Form, config))
                end
            end
        end

        -----------------------------------------------------------
        --                    static property                    --
        -----------------------------------------------------------
        --- the message for require items
        __Static__() property "RequireMessage"  { type = String, default = "the %s can't be nil" }

        --- the message for number errors
        __Static__() property "NumberMessage"   { type = String, default = "the %s must be number" }

        --- The message for table errors
        __Static__() property "TableMessage"    { type = String, default = "the %s must be a table" }

        --- The message for Date errors
        __Static__() property "DateMessage"     { type = String, default = "the %s must be a valid date value"}

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- the attribute target
        property "AttributeTarget"  { set = false, default = AttributeTargets.Function + AttributeTargets.Method }

        --- the attribute priority
        property "Priority"         { set = false, default = AttributePriority.Lower }

        --- the attribute priority sub level
        property "SubLevel"         { set = false, default = - 1000 }

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{ StructType }
        function __new(_, type)
            return { type }, true
        end

        __Arguments__{ RawTable }
        function __new(_, type)
            Attribute.IndependentCall(function()
                type = struct(type)
            end)
            return { type }, true
        end

        __Arguments__{}
        function __new(_)
            return {}, true
        end
    end)

    -- the inner request validator
    __Sealed__() class "__InnerRequest__" (function(_ENV)
        extend "IInitAttribute"

        export { NOT_FOUND = HTTP_STATUS.NOT_FOUND, AttributeTargets }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        function InitDefinition(self, target, targettype, definition, owner, name, stack)
            if targettype == AttributeTargets.Function then
                return function(context, ...)
                    if not context.IsInnerRequest then
                        context.Response.StatusCode = NOT_FOUND
                        return
                    end

                    return definition(context, ...)
                end
            else
                return function(self, context, ...)
                    if not context.IsInnerRequest then
                        context.Response.StatusCode = NOT_FOUND
                        return
                    end

                    return definition(self, context, ...)
                end
            end
        end

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- the attribute target
        property "AttributeTarget"  { set = false, default = AttributeTargets.Function + AttributeTargets.Method }

        --- the attribute priority
        property "Priority"         { set = false, default = AttributePriority.Lower }

        -- the attribute priority sub level
        property "SubLevel"         { set = false, default = - 3000 }
    end)

    -----------------------------------------------------------------------
    --                          config section                           --
    -----------------------------------------------------------------------
    export { __Login__, "pairs" }

    local configMap         = {
        Key                 = String,
        LoginChecker        = Function,
        LoginPage           = String,
        PathKey             = String,
        AuthorityChecker    = Function,
    }

    __ConfigSection__(Web.ConfigSection.Validator.Login, configMap)
    function applyWebConfig(config)
        for k, v in pairs(config) do
            if configMap[k] then
                __Login__["Default"..k] = v
            end
        end
    end

    __ConfigSection__(Application.ConfigSection.Validator.Login, configMap)
    function applyAppConfig(config, app)
        for k, v in pairs(config) do
            if configMap[k] then
                __Login__[k][app] = v
            end
        end
    end
end)