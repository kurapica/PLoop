--===========================================================================--
--                                                                           --
--                          Attribute for Validator                          --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2018/04/04                                               --
-- Update Date  :   2018/04/04                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Web"

    import "System.Configuration"

    --- the login & authority validator
    __Sealed__() class "__Login__" (function(_ENV)
        extend "IInitAttribute"

        export {
            UrlEncode           = UrlEncode,
            HttpMethod_GET      = HttpMethod.GET,
            IsObjectType        = Class.IsObjectType,

            AttributeTargets, __Login__, Application
        }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        function InitDefinition(self, target, targettype, definition, owner, name, stack)
            local authority, apath = self[1], self[2]

            if targettype == AttributeTargets.Function then
                if authority then
                    return function(context, ...)
                        local session = context.Session
                        local settings= context.Application[__Login__]
                        if session.Items[settings and settings.Key or __Login__.DefaultKey] ~= nil then
                            if (settings and settings.AuthorityChecker or __Login__.DefaultAuthorityChecker)(authority, context) then
                                return definition(context, ...)
                            elseif apath then
                                return context.Response.Redirect(apath)
                            end
                        end
                        if context.Request.HttpMethod == HttpMethod_GET then
                            context.Response:Redirect((settings and settings.LoginPage or __Login__.DefaultLoginPage) .. "?" .. (settings and settings.PathKey or __Login__.DefaultPathKey) .. "=" .. UrlEncode(context.Request.RawUrl))
                        else
                            context.Response:Redirect(settings and settings.LoginPage or __Login__.DefaultLoginPage)
                        end
                    end
                else
                    return function(context, ...)
                        local session = context.Session
                        local settings= context.Application[__Login__]
                        if session.Items[settings and settings.Key or __Login__.DefaultKey] ~= nil then
                            return definition(context, ...)
                        end
                        if context.Request.HttpMethod == HttpMethod_GET then
                            context.Response:Redirect((settings and settings.LoginPage or __Login__.DefaultLoginPage) .. "?" .. (settings and settings.PathKey or __Login__.DefaultPathKey) .. "=" .. UrlEncode(context.Request.RawUrl))
                        else
                            context.Response:Redirect(settings and settings.LoginPage or __Login__.DefaultLoginPage)
                        end
                    end
                end
            else
                if authority then
                    return function(self, context, ...)
                        local session = context.Session
                        local settings= context.Application[__Login__]
                        if session.Items[settings and settings.Key or __Login__.DefaultKey] ~= nil then
                            if (settings and settings.AuthorityChecker or __Login__.DefaultAuthorityChecker)(authority, session) then
                                return definition(self, context, ...)
                            elseif apath then
                                return context.Response.Redirect(apath)
                            end
                        end
                        if context.Request.HttpMethod == HttpMethod_GET then
                            context.Response:Redirect((settings and settings.LoginPage or __Login__.DefaultLoginPage) .. "?" .. (settings and settings.PathKey or __Login__.DefaultPathKey) .. "=" .. UrlEncode(context.Request.RawUrl))
                        else
                            context.Response:Redirect(settings and settings.LoginPage or __Login__.DefaultLoginPage)
                        end
                    end
                else
                    return function(self, context, ...)
                        local session = context.Session
                        local settings= context.Application[__Login__]
                        if session.Items[settings and settings.Key or __Login__.DefaultKey] ~= nil then
                            return definition(self, context, ...)
                        end
                        if context.Request.HttpMethod == HttpMethod_GET then
                            context.Response:Redirect((settings and settings.LoginPage or __Login__.DefaultLoginPage) .. "?" .. (settings and settings.PathKey or __Login__.DefaultPathKey) .. "=" .. UrlEncode(context.Request.RawUrl))
                        else
                            context.Response:Redirect(settings and settings.LoginPage or __Login__.DefaultLoginPage)
                        end
                    end
                end
            end
        end

        -----------------------------------------------------------
        --                    static property                    --
        -----------------------------------------------------------
        --- the key in the session items for checking
        __Static__() property "DefaultKey"                      { type = String, default = "userid" }

        --- the login path
        __Static__() property "DefaultLoginPage"                { type = String }

        --- the key to send the request path to the login page
        __Static__() property "DefaultPathKey"                  { type = String, default = "path"}

        --- the authority checker
        __Static__() property "DefaultAuthorityChecker"         { type = Function, default = function() return true end }

        --- the key in the session items for checking
        __Static__() __Indexer__() property "Key"               { type = String,
            set = function(self, app, value)
                if IsObjectType(app, Application) then
                    app                 = app._Application

                    local settings      = app[__Login__] or {}
                    settings.Key        = value

                    app[__Login__]      = settings
                end
            end,
        }

        --- the login path
        __Static__() __Indexer__() property "LoginPage"         { type = String,
            set = function(self, app, value)
                if IsObjectType(app, Application) then
                    app                 = app._Application

                    local settings      = app[__Login__] or {}
                    settings.LoginPage  = value

                    app[__Login__]      = settings
                end
            end,
        }

        --- the key to send the request path to the login page
        __Static__() __Indexer__() property "PathKey"           { type = String,
            set = function(self, app, value)
                if IsObjectType(app, Application) then
                    app                 = app._Application

                    local settings      = app[__Login__] or {}
                    settings.PathKey    = value

                    app[__Login__]      = settings
                end
            end,
        }

        --- the authority checker
        __Static__() __Indexer__() property "AuthorityChecker"  { type = Function,
            set = function(self, app, value)
                if IsObjectType(app, Application) then
                    app                 = app._Application

                    local settings      = app[__Login__] or {}
                    settings.AuthorityChecker = value

                    app[__Login__]      = settings
                end
            end,
        }

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- the attribute target
        property "AttributeTarget"  { set = false, default = AttributeTargets.Function + AttributeTargets.Method }

        --- the attribute's priority
        property "Priority"         { set = false, default = AttributePriority.Lowest }

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{ Any, String/nil }
        function __new(_, authority, url)
            return { authority, url }
        end

        __Arguments__{}
        function __new()
            return {}
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
            IsSubStruct         = Struct.IsSubType,
            IsStruct            = Struct.Validate,
            IsEnum              = Enum.Validate,
            GetEnumValues       = Enum.GetEnumValues,
            ValidateStructValue = Struct.ValidateValue,
            ValidateEnumValue   = Enum.ValidateValue,

            strmatch            = string.match,
            tonumber            = tonumber,
            pairs               = pairs,
            type                = type,
            strgsub             = string.gsub,
            strtrim             = function (s) return s and strgsub(s, "^%s*(.-)%s*$", "%1") or "" end,

            MEMBER              = StructCategory.MEMBER,
            ARRAY               = StructCategory.ARRAY,
            CUSTOM              = StructCategory.CUSTOM,
            Debug               = Logger.Default[Logger.LogLevel.Debug],

            HttpMethod_GET      = HttpMethod.GET,

            __Form__, Attribute, AttributeTargets, JsonFormatProvider, Serialization.StringFormatProvider, Number
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
                value           = Deserialize(JsonFormatProvider(), value)
            end

            if type(value) ~= "table" or value[1] == nil then
                return nil, config.require and __Form__.RequireMessage or nil
            else
                local errs
                local avalid    = config.elementconfig

                for i = 1, #value do
                    local val, err = avalid:validate(value[i])
                    value[i]    = val
                    if err then
                        errs    = errs or {}
                        errs[i] = err
                    end
                end

                return value, errs
            end
        end

        local function validateMemberValue(config, value)
            if type(value) == "string" then
                value               = Deserialize(JsonFormatProvider(), value)
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

        local function parseType(vtype, require)
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
                        return { elementconfig = parseType(GetArrayElement(vtype)), validate = validateArrayValue, require = require }
                    elseif category == MEMBER then
                        local memconfigs    = {}

                        for _, mem in GetMembers(vtype) do
                            memconfigs[mem:GetName()] = parseType(mem:GetType(), mem:IsRequire())
                        end

                        return { memberconfigs = memconfigs, validate = validateMemberValue, require = require }
                    end
                end
            end
            return { validate = validateNotypeValue, require = require }
        end

        local function validateForm(query, config)
            local form          = {}
            local errors

            -- Init
            for key, val in pairs(query) do
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

            -- validate
            return config:validate(form)
        end

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        function InitDefinition(self, target, targettype, definition, owner, name, stack)
            if GetStructCategory(self[1]) ~= MEMBER then return end

            local config    = parseType(self[1])

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
        __Static__() property "RequireMessage" { type = String, default = "the %s can't be nil" }

        --- the message for number errors
        __Static__() property "NumberMessage"  { type = String, default = "the %s must be number" }

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- the attribute target
        property "AttributeTarget"  { set = false, default = AttributeTargets.Function + AttributeTargets.Method }

        --- the attribute's priority
        property "Priority"         { set = false, default = AttributePriority.Lower }

        --- the attribute's priority sub level
        property "SubLevel"         { set = false, default = - 200 }

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
    end)

    -----------------------------------------------------------------------
    --                          config section                           --
    -----------------------------------------------------------------------
    export { __Login__, "pairs" }

    local configMap         = {
        Key                 = String,
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