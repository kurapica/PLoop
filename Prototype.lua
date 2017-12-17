--===========================================================================--
-- Copyright (c) 2011-2018 WangXH <kurapica125@outlook.com>                  --
--                                                                           --
-- Permission is hereby granted, free of charge, to any person               --
-- obtaining a copy of this software and associated Documentation            --
-- files (the "Software"), to deal in the Software without                   --
-- restriction, including without limitation the rights to use,              --
-- copy, modify, merge, publish, distribute, sublicense, and/or sell         --
-- copies of the Software, and to permit persons to whom the                 --
-- Software is furnished to do so, subject to the following                  --
-- conditions:                                                               --
--                                                                           --
-- The above copyright notice and this permission notice shall be            --
-- included in all copies or substantial portions of the Software.           --
--                                                                           --
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,           --
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES           --
-- OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND                  --
-- NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT               --
-- HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,              --
-- WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING              --
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR             --
-- OTHER DEALINGS IN THE SOFTWARE.                                           --
--===========================================================================--

--===========================================================================--
--                                                                           --
--                   Prototype Lua Object-Oriented System                    --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2017/04/02                                               --
-- Update Date  :   2017/12/14                                               --
-- Version      :   1.0.0-alpha.1                                            --
--===========================================================================--

-------------------------------------------------------------------------------
--                                preparation                                --
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                      environment preparation                      --
    -----------------------------------------------------------------------
    local cerror, cformat       = error, string.format
    local _PLoopEnv             = setmetatable(
        {
            _G                  = _G,
            LUA_VERSION         = tonumber(_VERSION and _VERSION:match("[%d%.]+")) or 5.1,

            -- Weak Mode
            WEAK_KEY            = { __mode = "k"  },
            WEAK_VALUE          = { __mode = "v"  },
            WEAK_ALL            = { __mode = "kv" },

            -- Iterator
            ipairs              = ipairs(_G),
            pairs               = pairs (_G),
            next                = next,
            select              = select,

            -- String
            strlen              = string.len,
            strformat           = string.format,
            strfind             = string.find,
            strsub              = string.sub,
            strbyte             = string.byte,
            strchar             = string.char,
            strrep              = string.rep,
            strgsub             = string.gsub,
            strupper            = string.upper,
            strlower            = string.lower,
            strmatch            = string.match,
            strgmatch           = string.gmatch,

            -- Table
            tblconcat           = table.concat,
            tinsert             = table.insert,
            tremove             = table.remove,
            unpack              = table.unpack or unpack,
            sort                = table.sort,
            setmetatable        = setmetatable,
            getmetatable        = getmetatable,
            rawset              = rawset,
            rawget              = rawget,

            -- Type
            type                = type,
            tonumber            = tonumber,
            tostring            = tostring,

            -- Math
            floor               = math.floor,
            mlog                = math.log,
            mabs                = math.abs,

            -- Coroutine
            create              = coroutine.create,
            resume              = coroutine.resume,
            running             = coroutine.running,
            status              = coroutine.status,
            wrap                = coroutine.wrap,
            yield               = coroutine.yield,

            -- Safe
            pcall               = pcall,
            error               = error,
            print               = print,
            newproxy            = newproxy or false,

            -- In lua 5.2, the loadstring is deprecated
            loadstring          = loadstring or load,
            loadfile            = loadfile,

            -- Debug lib
            debug               = debug or false,
            debuginfo           = debug and debug.getinfo or false,
            getupvalue          = debug and debug.getupvalue or false,
            traceback           = debug and debug.traceback or false,
            setfenv             = setfenv or debug and debug.setfenv or false,
            getfenv             = getfenv or debug and debug.getfenv or false,

            -- Share API
            fakefunc            = function() end,
        }, {
            __index             = function(self, k) cerror(cformat("Global variable %q can't be found", k), 2) end,
            __metatable         = true,
        }
    )
    if setfenv then setfenv(1, _PLoopEnv) else _ENV = _PLoopEnv end

    -----------------------------------------------------------------------
    --                         platform settings                         --
    -----------------------------------------------------------------------
    PLOOP_PLATFORM_SETTINGS     = (function(default)
        local settings = _G.PLOOP_PLATFORM_SETTINGS
        if type(settings) == "table" then
            for k, v in pairs, default do
                local r = settings[k]
                if r ~= nil then
                    if type(r) ~= type(v) then
                        Error("The PLOOP_PLATFORM_SETTINGS[%q]'s value must be %s.", k, type(v))
                    else
                        default[k]  = r
                    end
                end
            end
        end
        return default
    end) {
        -- Attribute
        ATTR_USE_WARN_INSTEAD_ERROR         = false,

        -- Environment
        ENV_ALLOW_GLOBAL_VAR_BE_NIL         = false,

        -- Enum
        ENUM_GLOBAL_IGNORE_CASE             = false,

        -- Interface X Class X Object
        CLASS_ALL_SIMPLE_VERSION            = false,
        CLASS_ALL_OLD_SUPER_STYLE           = false,

        -- Log
        CORE_LOG_LEVEL                      = 3,
        CORE_LOG_HANDLER                    = print,

        -- Multi-thread
        MULTI_OS_THREAD                     = false,
        MULTI_OS_THREAD_LUA_LOCK_APPLIED    = false,
        MULTI_OS_LOCK                       = fakefunc,
        MULTI_OS_RELEASE                    = fakefunc,
    }

    -----------------------------------------------------------------------
    --                               share                               --
    -----------------------------------------------------------------------
    strtrim                     = function(s)     return s and strgsub(s, "^%s*(.-)%s*$", "%1") or "" end

    typeconcat                  = function (a, b) return tostring(a) .. tostring(b) end
    wipe                        = function (t)    for k in pairs, t do t[k] = nil end return t end

    readOnly                    = function (self) error(strformat("The %s can't be written", tostring(self)), 2) end
    writeOnly                   = function (self) error(strformat("The %s can't be read", tostring(self)), 2) end

    -----------------------------------------------------------------------
    --                               debug                               --
    -----------------------------------------------------------------------
    getCallLine                 = not debuginfo and fakefunc or function (stack)
        local info = debuginfo((stack or 2) + 1, "lS")
        if info then
            return "@" .. (info.short_src or "unknown") .. ":" .. (info.currentline or "?")
        end
    end

    -----------------------------------------------------------------------
    --                               clone                               --
    -----------------------------------------------------------------------
    deepClone                   = function (src, tar, override, cache)
        if cache then cache[src] = tar end

        for k, v in pairs, src do
            if override or tar[k] == nil then
                if type(v) == "table" and getmetatable(v) == nil then
                    tar[k] = cache and cache[v] or deepClone(v, {}, override, cache)
                else
                    tar[k] = v
                end
            elseif type(v) == "table" and type(tar[k]) == "table" and getmetatable(v) == nil and getmetatable(tar[k]) == nil then
                deepClone(v, tar[k], override, cache)
            end
        end
        return tar
    end

    tblclone                    = function (src, tar, deep, override, safe)
        if src then
            if deep then
                local cache = safe and _Cache()
                deepClone(src, tar, override, cache)   -- no cache for duplicated table
                if safe then _Cache(cache) end
            else
                for k, v in pairs, src do
                    if override or tar[k] == nil then tar[k] = v end
                end
            end
        end
        return tar
    end

    clone                       = function (src, deep, safe)
        if type(src) == "table" and getmetatable(src) == nil then
            return tblclone(src, {}, deep, true, safe)
        else
            return src
        end
    end

    -----------------------------------------------------------------------
    --                          loading snippet                          --
    -----------------------------------------------------------------------
    if LUA_VERSION > 5.1 then
        loadSnippet             = function (chunk, source, env)
            return loadstring(chunk, source, nil, env or _PLoopEnv)
        end
    else
        loadSnippet             = function (chunk, source, env)
            -- print("--------------" .. source .. "-----------")
            -- print(chunk)
            local v, err = loadstring(chunk, source)
            if v then setfenv(v, env or _PLoopEnv) end
            return v, err
        end
    end

    -----------------------------------------------------------------------
    --                         flags management                          --
    -----------------------------------------------------------------------
    if LUA_VERSION >= 5.3 then
        validateFlags           = loadstring [[
            return function(checkValue, targetValue)
                return (checkValue & (targetValue or 0)) > 0
            end
        ]] ()

        turnOnFlags             = loadstring [[
            return function(checkValue, targetValue)
                return checkValue | (targetValue or 0)
            end
        ]] ()

        turnOffFlags            = loadstring [[
            return function(checkValue, targetValue)
                return (~checkValue) & (targetValue or 0)
            end
        ]] ()
    elseif (LUA_VERSION == 5.2 and type(_G.bit32) == "table") or (LUA_VERSION == 5.1 and type(_G.bit) == "table") then
        local band              = _G.bit32 and bit32.band or bit.band
        local bor               = _G.bit32 and bit32.bor  or bit.bor
        local bnot              = _G.bit32 and bit32.bnot or bit.bnot

        validateFlags           = function (checkValue, targetValue)
            return band(checkValue, targetValue or 0) > 0
        end

        turnOnFlags             = function (checkValue, targetValue)
            return bor(checkValue, targetValue or 0)
        end

        turnOffFlags            = function (checkValue, targetValue)
            return band(bnot(checkValue), targetValue or 0)
        end
    else
        validateFlags           = function (checkValue, targetValue)
            if not targetValue or checkValue > targetValue then return false end
            targetValue = targetValue % (2 * checkValue)
            return (targetValue - targetValue % checkValue) == checkValue
        end

        turnOnFlags             = function (checkValue, targetValue)
            if not validateFlags(checkValue, targetValue) then
                return checkValue + (targetValue or 0)
            end
            return targetValue
        end

        turnOffFlags            = function (checkValue, targetValue)
            if validateFlags(checkValue, targetValue) then
                return targetValue - checkValue
            end
            return targetValue
        end
    end

    -----------------------------------------------------------------------
    --                             newproxy                              --
    -----------------------------------------------------------------------
    newproxy                    = newproxy or (function ()
        local falseMeta         = { __metatable = false }
        local _proxymap         = setmetatable({}, WEAK_ALL)

        return function (prototype)
            if prototype == true then
                local meta = {}
                prototype = setmetatable({}, meta)
                _proxymap[prototype] = meta
                return prototype
            elseif _proxymap[prototype] then
                return setmetatable({}, _proxymap[prototype])
            else
                return setmetatable({}, falseMeta)
            end
        end
    end)()

    -----------------------------------------------------------------------
    --                        environment control                        --
    -----------------------------------------------------------------------
    if not setfenv then
        if debug and debug.getinfo and debug.getupvalue and debug.upvaluejoin and debug.getlocal then
            local getinfo       = debug.getinfo
            local getupvalue    = debug.getupvalue
            local upvaluejoin   = debug.upvaluejoin
            local getlocal      = debug.getlocal

            setfenv             = function (f, t)
                f = type(f) == 'function' and f or getinfo(f + 1, 'f').func
                local up, name = 0
                repeat
                    up = up + 1
                    name = getupvalue(f, up)
                until name == '_ENV' or name == nil
                if name then upvaluejoin(f, up, function() return t end, 1) end
            end

            getfenv             = function (f)
                local cf, up, name, val = type(f) == 'function' and f or getinfo(f + 1, 'f').func, 0
                repeat
                    up = up + 1
                    name, val = getupvalue(cf, up)
                until name == '_ENV' or name == nil
                if val then return val end

                if type(f) == "number" then
                    f, up = f + 1, 0
                    repeat
                        up = up + 1
                        name, val = getlocal(f, up)
                    until name == '_ENV' or name == nil
                    if val then return val end
                end
            end
        else
            getfenv             = fakefunc
            setfenv             = fakefunc
        end
    end

    -----------------------------------------------------------------------
    --                            main cache                             --
    -----------------------------------------------------------------------
    _Cache                      = setmetatable({}, {
        __call                  = PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD and
            function(self, tbl) return tbl and wipe(tbl) or {} end
            or
            function(self, tbl) if tbl then return tinsert(self, wipe(tbl)) else return tremove(self) or {} end end,
        }
    )

    -----------------------------------------------------------------------
    --                                log                                --
    -----------------------------------------------------------------------
    local generateLogger        = function (prefix, loglvl)
        local handler = PLOOP_PLATFORM_SETTINGS.CORE_LOG_HANDLER
        return PLOOP_PLATFORM_SETTINGS.CORE_LOG_LEVEL > loglvl and fakefunc or
            function(msg, stack, ...)
                if type(stack) == "number" then
                    msg = prefix .. strformat(msg, ...) .. (getCallLine(stack + 1) or "")
                else
                    msg = prefix .. strformat(msg, stack, ...)
                end
                return handler(msg, loglvl)
            end
    end

    Trace                       = generateLogger("[PLoop:Trace]", 1)
    Debug                       = generateLogger("[PLoop:Debug]", 2)
    Info                        = generateLogger("[PLoop:Info]",  3)
    Warn                        = generateLogger("[PLoop:Warn]",  4)
    Error                       = generateLogger("[PLoop:Error]", 5)
    Fatal                       = generateLogger("[PLoop:Fatal]", 6)
end

-------------------------------------------------------------------------------
-- The prototypes are types of other types(like classes), for a class "A",
-- A is its object's type and the class is A's prototype.
--
-- The prototypes are simply defined based on the lua's meta-table, as an example:
--
--      proxy = prototype "proxy" {
--          __index = function(self, key) return rawget(self, "__" .. key) end,
--          __newindex = function(self, key, value) rawset(self, "__" .. key, value) end,
--      }
--
-- The prototype's creation'll return an userdata created by newproxy as the result if the newproxy API existed,
-- otherwise, a fake newproxy system will be used and the result would be a table instead of the userdata.
--
-- All meta-settings will be copied to the result's meta-table, with several default settings:
--      * __metatable : if nil, the prototype itself would be used.
--      * __tostring  : if nil, the prototype's name would be used, if false, __tostring will be set to nil.
--
-- It's also support a simple inheritance system like :
--
--      cproxy = prototype "cproxy" (proxy, {
--          __call = function(self, ...) end,
--      })
--
-- The new prototype's meta-table will copy meta-settings from it's super prototype (except the __metatable and __tostring).
--
-- The complete definition syntaxes are
--
--      val = prototype (["name",][superprototype,][definiton][,nodeepclone][,stack])
--      val = prototype "name" ([superprototype,][definiton][,nodeepclone][,stack])
--
-- The params :
--      * name            : string, the prototype's name, if ommit, must have superprototype or definiton to
--                          define an anonymous prototype.
--      * superprototype  : prototype, the super prototype whose meta-settings would be copied to the new one.
--      * definition      : table, the prototype's meta-settings.
--      * nodeepclone     : boolean, the __index maybe a table, normally, it's content would be deep cloned to
--                          the prototype's meta-settings, if true, the __index table will be used directly, so
--                          you may modify it after the prototype's definition.
--      * stack           : number, the stack level used to raise errors.
--
-- @prototype prototype
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                         private variables                         --
    -----------------------------------------------------------------------
    local _Prototype            = setmetatable({}, WEAK_ALL)

    -----------------------------------------------------------------------
    --                              Helpers                              --
    -----------------------------------------------------------------------
    local newPrototypeName      = nil

    local parsePrototypeArgs    = function(...)
        local name, meta, super, nodeepclone, stack

        for i = 1, select("#", ...) do
            local value         = select(i, ...)
            local vtype         = type(value)

            if vtype == "boolean" then
                nodeepclone     = value
            elseif vtype == "number" then
                stack           = value
            elseif vtype == "string" and strtrim(value) ~= "" then
                name            = strtrim(value)
            elseif vtype == "table" then
                if getmetatable(value) == nil then
                    meta        = value
                elseif _Prototype[value] then
                    super       = value
                end
            end
        end

        return name, meta, super, nodeepclone or false, stack or 1
    end

    local newPrototype          = function (...)
        local name, meta, super, nodeepclone, stack = parsePrototypeArgs(...)

        name                    = name or newPrototypeName
        newPrototypeName        = nil

        local prototype         = newproxy(true)
        local pmeta             = getmetatable(prototype)
        _Prototype[prototype]   = pmeta

        -- Default
        if meta                         then tblclone(meta, pmeta, not nodeepclone, true) end
        if pmeta.__metatable   == nil   then pmeta.__metatable  = prototype end
        if pmeta.__tostring    == nil   then pmeta.__tostring   = name and function() return name end end

        -- Inherit
        if super                        then tblclone(_Prototype[super], pmeta, true, false) end

        -- Clear
        if pmeta.__tostring    == false then pmeta.__tostring   = nil end

        Trace("The [prototype] %s is created", (stack or 1) + 1, name)

        return prototype
    end

    -----------------------------------------------------------------------
    --                             prototype                             --
    -----------------------------------------------------------------------
    prototype                   = newPrototype ("prototype", {
        __index                 = {
            --- Get the methods or return an iterator to get the methods of the prototype
            -- @owner prototype
            -- @method GetMethods
            -- @param cache optional
            -- @return
            ["GetMethods"]      = function(self, cache)
                local meta      = _Prototype[self]
                if meta and type(meta.__index) == "table" then
                    local methods = meta.__index
                    if cache then
                        cache   = type(cache) == "table" and wipe(cache) or {}
                        for k, v in pairs, methods do if type(v) == "function" then cache[k] = v end end
                        return cache
                    else
                        return function(self, n)
                            local k, v = next(methods, n)
                            while k and type(v) ~= "function" do k, v = next(methods, k) end
                            return k, v
                        end, self
                    end
                elseif cache then
                    return type(cache) == "table" and cache or nil
                else
                    return fakefunc, self
                end
            end,

            --- Create a proxy with the prototype's meta-table
            -- @owner prototype
            -- @method NewProxy
            -- @return the proxy of the same meta-table
            ["NewProxy"]        = newproxy,

            --- Create a table(object) with the prototype's meta-table
            -- @owner prototype
            -- @method NewObject
            -- @param table optional, the table used to be set the meta-table
            -- @return the table with the meta-table settings
            ["NewObject"]       = function(self, tbl) return setmetatable(type(tbl) == "table" and tbl or {}, _Prototype[self]) end,

            --- Whether the value is a object of the prototype(has the same meta-table)
            -- @owner prototype
            -- @method ValidateValue
            -- @param value the value to be validated
            -- @return true if the value is generated from the prototype
            ["ValidateValue"]   = function(self, val) return getmetatable(val) == self end,

            --- Whether the value is a prototype
            -- @owner prototype
            -- @static-method Validate
            -- @param value the value to be validated
            -- @return true if the value is a prototype
            ["Validate"]        = function(self) return _Prototype[self] and self or nil end,
        },
        __newindex              = readOnly,
        __call                  = function(...)
            local name, meta, super, nodeepclone, stack = parsePrototypeArgs(...)

            if meta or super then
                local prototype = newPrototype(name, meta, super, nodeepclone, stack + 1)
                return prototype
            elseif name then
                newPrototypeName= name
                return newPrototype
            else
                error([["Usage: prototype "name" { meta-settings }]], 2)
            end
        end,
    })
end

-------------------------------------------------------------------------------
--                                 attribute                                 --
--                                                                           --
-- The attributes are used to bind informations to the features, or used to  --
-- modify those features directly(like wrap a function).                     --
--                                                                           --
-- An attribute or its type's attribute usage should contains several fields,--
-- The type's attribute usage would be used as default value.                --
--                                                                           --
-- * AttributeTarget                                                         --
--      The flags that represents the types of the target features.          --
--                                                                           --
-- * Inheritable                                                             --
--      Whether the attribute is inheritable.                                --
--                                                                           --
-- * ApplyPhase                                                              --
--      The apply phase of the attribute:                                    --
--          1 - Before the definition of the feature                         --
--          2 - After the definition of the feature                          --
--          3 - (= 1 + 2) in both phase.                                     --
--                                                                           --
-- * Overridable                                                             --
--      Whether the attribute's saved data is overridable.                   --
--                                                                           --
-- * ApplyAttribute                                                          --
--      The method used to apply the attribute to the target feature.        --
--                                                                           --
-- * Priority                                                                --
--      The attribute's priority, the bigger the first to be  applied.       --
--                                                                           --
-- * SubLevel                                                                --
--      The priority's sublevel, for attributes with same priority, the      --
--  bigger sublevel the first be applied.                                    --
--                                                                           --
-- * Final                                                                   --
--      Special for attribute usage, attribute usage can't be overridden if  --
--  true.                                                                    --
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                          public constants                         --
    -----------------------------------------------------------------------
    -- ATTRIBUTE TARGETS
    ATTRIBUTE_TARGETS_ALL       = 0

    -- ATTRIBUTE APPLY PHASE
    ATTRIBUTE_APPLYPH_BEFOREDEF = 2^0
    ATTRIBUTE_APPLYPH_AFTERDEF  = 2^1

    -----------------------------------------------------------------------
    --                         private variables                         --
    -----------------------------------------------------------------------
    -- Attribute Data
    local _AttrTargetTypes      = { [ATTRIBUTE_TARGETS_ALL] = "All" }
    local _AttrUseNameApply     = {}

    -- Attribute Target Data
    local _AttrTargetData       = setmetatable({}, WEAK_KEY)
    local _AttrTargetInrt       = setmetatable({}, WEAK_KEY)

    -- Temporary Cache (Single thread for definition at the same time, so no need to care the conflict)
    local _RegisteredAttrs      = {}
    local _TargetAttrs          = setmetatable({}, WEAK_KEY)
    local _AfterDefineAttrs     = setmetatable({}, WEAK_KEY)

    -----------------------------------------------------------------------
    --                              Helpers                              --
    -----------------------------------------------------------------------
    local _SuspendNextConsume   = false
    local _UseWarnInstreadErr   = PLOOP_PLATFORM_SETTINGS.ATTR_USE_WARN_INSTEAD_ERROR

    local getAttributeUsage     = function (attr)
        local info  = _AttrTargetData[getmetatable(attr)]
        return info and info[attribute]
    end

    local getAttrUsageField     = function (obj, field, default, chkType)
        local val   = obj and obj[field]
        if val ~= nil and (not chkType or type(val) == chkType) then return val end
        return default
    end

    local getAttributeInfo      = function (attr, field, default, chkType, attrusage)
        local val   = getAttrUsageField(attr, field, nil, chkType)
        if val == nil then val = getAttrUsageField(attrusage or getAttributeUsage(attr), field, nil, chkType) end
        if val ~= nil then return val end
        return default
    end

    local addAttribtue          = function (list, attr, noSameType)
        for _, v in ipairs, list, 0 do
            if v == attr then return end
            if noSameType and getmetatable(v) == getmetatable(attr) then return end
        end

        local idx       = 1
        local priority  = getAttributeInfo(attr, "Priority", 0, "number")
        local sublevel  = getAttributeInfo(attr, "SubLevel", 0, "number")

        while list[idx] do
            local patr  = list[idx]
            local pprty = getAttributeInfo(patr, "Priority", 0, "number")
            local psubl = getAttributeInfo(patr, "SubLevel", 0, "number")

            if priority > pprty or (priority == pprty and sublevel > psubl) then break end
            idx = idx + 1
        end

        tinsert(list, idx, attr)
    end

    -----------------------------------------------------------------------
    --                             attribute                             --
    -----------------------------------------------------------------------
    attribute                   = prototype "attribute" {
        __index                 = {
            -- Apply the registered attributes to the feature
            -- @target          - the target feature
            -- @targetType      - the target's type
            -- @definition      - the target's definition, so it can be modified
            -- @owner           - the target's owner
            -- @name            - the target's name
            -- @...             - the target's super features, used for inheritance
            -- return
            --
            ["ApplyAttributes"] = function(target, targetType, definition, owner, name, ...)
                local tarAttrs  = _TargetAttrs[target]
                if tarAttrs then _TargetAttrs[target] = nil end

                -- Check inheritance
                for i = 1, select("#", ...) do
                    local super = select(i, ...)
                    if super and _AttrTargetInrt[super] then
                        for _, sattr in pairs, _AttrTargetInrt[super] do
                            local aTar = getAttributeInfo(sattr, "AttributeTarget", ATTRIBUTE_TARGETS_ALL, "number")

                            if aTar == ATTRIBUTE_TARGETS_ALL or validateFlags(targetType, aTar) then
                                tarAttrs    = tarAttrs or _Cache()
                                addAttribtue(tarAttrs, sattr, true)
                            end
                        end
                    end
                end

                if not tarAttrs then return target end

                local extAttrs  = _AttrTargetData[target] and tblclone(_AttrTargetData[target], _Cache())
                local extInhrt  = _AttrTargetInrt[target] and tblclone(_AttrTargetInrt[target], _Cache())
                local finAttrs
                local isMethod  = type(target) == "function"
                local newAttrs  = false
                local newInhrt  = false
                local applyTar  = (_AttrUseNameApply[targetType] and (name or tostring(target))) or target

                -- Apply the attribute to the target
                Trace("Starting apply pre-attribtues on [%s]%s", _AttrTargetTypes[targetType] or "Unknown", owner and (tostring(owner) .. "'s " .. name) or tostring(target))

                for i, attr in ipairs, tarAttrs, 0 do
                    local aType = getmetatable(attr)
                    local ausage= getAttributeUsage(attr)
                    local aPhse = getAttributeInfo(attr, "ApplyPhase",      ATTRIBUTE_APPLYPH_BEFOREDEF,    "number",   ausage)
                    local apply = getAttributeInfo(attr, "ApplyAttribute",  nil,                            "function", ausage)
                    local ovrd  = getAttributeInfo(attr, "Overridable",     true,                           nil,        ausage)
                    local inhr  = getAttributeInfo(attr, "Inheritable",     false,                          nil,        ausage)

                    -- Save for next phase
                    if validateFlags(ATTRIBUTE_APPLYPH_AFTERDEF, aPhse) then
                        finAttrs= finAttrs or _Cache()
                        tinsert(finAttrs, attr)
                    end

                    -- Apply attribute before the definition
                    if validateFlags(ATTRIBUTE_APPLYPH_BEFOREDEF, aPhse) and
                        (ovrd or ((extAttrs == nil or extAttrs[aType] == nil) and (extInhrt == nil or extInhrt[aType] == nil))) then
                        if apply then
                            Trace("Apply attribute %s", tostring(attr))

                            local ret = apply(attr, applyTar, targetType, definition, owner, name, ATTRIBUTE_APPLYPH_BEFOREDEF)

                            if ret ~= nil then
                                if isMethod and type(ret) == "function" then
                                    applyTar        = ret
                                else
                                    extAttrs        = extAttrs or _Cache()
                                    extAttrs[aType] = ret
                                    newAttrs        = true
                                end
                            end
                        end

                        if inhr then
                            Trace("Save inherited attribute %s", tostring(attr))

                            extInhrt        = extInhrt or _Cache()
                            extInhrt[aType] = attr
                            newInhrt        = true
                        end
                    end
                end

                Trace("Finished apply pre-attribtues on [%s]%s", _AttrTargetTypes[targetType] or "Unknown", owner and (tostring(owner) .. "'s " .. name) or tostring(target))

                _Cache(tarAttrs)

                if isMethod then target = applyTar end

                -- Save the after definition attributes
                if finAttrs then _AfterDefineAttrs[target] = finAttrs end

                -- Save attribute save datas
                if newAttrs then _AttrTargetData[target] = extAttrs elseif extAttrs then _Cache(extAttrs) end
                if newInhrt then _AttrTargetInrt[target] = extInhrt elseif extInhrt then _Cache(extInhrt) end

                return target
            end;

            -- Apply the after-definition attributes to the feature
            -- @target          - the target feature
            -- @targetType      - the target's type
            -- @owner           - the target's owner(may be itself)
            -- @name            - the target's name
            ["ApplyAfterDefine"]= function(target, targetType, owner, name)
                local finAttrs  = _AfterDefineAttrs[target]
                if not finAttrs then return else _AfterDefineAttrs[target] = nil end

                local extAttrs  = _AttrTargetData[target] and tblclone(_AttrTargetData[target], _Cache())
                local extInhrt  = _AttrTargetInrt[target] and tblclone(_AttrTargetInrt[target], _Cache())
                local newAttrs  = false
                local newInhrt  = false
                local applyTar  = (_AttrUseNameApply[targetType] and (name or tostring(target))) or target

                -- Apply the attribute to the target
                Trace("Starting apply post-attribtues on [%s]%s", _AttrTargetTypes[targetType] or "Unknown", owner and (tostring(owner) .. "'s " .. name) or tostring(target))

                for i, attr in ipairs, finAttrs, 0 do
                    local aType = getmetatable(attr)
                    local ausage= getAttributeUsage(attr)
                    local apply = getAttributeInfo(attr, "ApplyAttribute",  nil,    "function", ausage)
                    local ovrd  = getAttributeInfo(attr, "Overridable",     true,   nil,        ausage)
                    local inhr  = getAttributeInfo(attr, "Inheritable",     false,  nil,        ausage)

                    if ovrd or ((extAttrs == nil or extAttrs[aType] == nil) and (extInhrt == nil or extInhrt[aType] == nil)) then
                        if apply then
                            Trace("Apply attribute %s", tostring(attr))

                            local ret = apply(attr, applyTar, targetType, nil, owner, name, ATTRIBUTE_APPLYPH_AFTERDEF)

                            if ret ~= nil and type(ret) ~= "function" then
                                extAttrs        = extAttrs or _Cache()
                                extAttrs[aType] = ret
                                newAttrs        = true
                            end
                        end

                        if inhr then
                            Trace("Save inherited attribute %s", tostring(attr))

                            extInhrt        = extInhrt or _Cache()
                            extInhrt[aType] = attr
                            newInhrt        = true
                        end
                    end
                end

                Trace("Finished apply post-attribtues on [%s]%s", _AttrTargetTypes[targetType] or "Unknown", owner and (tostring(owner) .. "'s " .. name) or tostring(target))

                _Cache(finAttrs)

                -- Save attribute save datas
                if newAttrs then _AttrTargetData[target] = extAttrs elseif extAttrs then _Cache(extAttrs) end
                if newInhrt then _AttrTargetInrt[target] = extInhrt elseif extInhrt then _Cache(extInhrt) end
            end;

            -- Clear all registered attributes
            ["Clear"]           = function()
                if #_RegisteredAttrs > 0 then
                    Trace("Registerd attributes are cleared", 2)
                    wipe(_RegisteredAttrs)
                end
            end;

            ["ConsumeAttributes"] = function(target, targetType, owner, name, stack)
                if _SuspendNextConsume then _SuspendNextConsume = false return end
                if #_RegisteredAttrs  == 0 then return end

                local tarAttrs  = _RegisteredAttrs
                _RegisteredAttrs= _Cache()

                Trace("Starting consume attribtues on [%s]%s", _AttrTargetTypes[targetType] or "Unknown", owner and (tostring(owner) .. "'s " .. name) or tostring(target))

                for i = #tarAttrs, 1, -1 do
                    local attr  = tarAttrs[i]
                    local aTar  = getAttributeInfo(attr, "AttributeTarget", ATTRIBUTE_TARGETS_ALL, "number")

                    if aTar ~= ATTRIBUTE_TARGETS_ALL and not validateFlags(targetType, aTar) then
                        if _UseWarnInstreadErr then
                            Warn("The attribute %s can't be applied to the [%s]%s", tostring(attr), _AttrTargetTypes[targetType] or "Unknown", owner and (tostring(owner) .. "'s " .. name) or tostring(target))
                            tremove(tarAttrs, i)
                        else
                            _Cache(tarAttrs)
                            error(strformat("The attribute %s can't be applied to the [%s]%s", tostring(attr), _AttrTargetTypes[targetType] or "Unknown", owner and (tostring(owner) .. "'s " .. name) or tostring(target)), stack)
                        end
                    end
                end

                Trace("Finished consume attribtues on [%s]%s", _AttrTargetTypes[targetType] or "Unknown", owner and (tostring(owner) .. "'s " .. name) or tostring(target))

                _TargetAttrs[target] = tarAttrs
            end;

            -- Get saved attribute data
            -- @target          - the target feature
            -- @attributeType   - the attribute's type
            ["GetAttributeData"]= function(target, aType)
                local info      = _AttrTargetData[target]
                return info and clone(info[aType], true, true)
            end;

            -- Register the attribute to be used by the next feature
            -- @attr        - The attribute to register.
            -- @noSameType  - Don't register the attribute if there is another attribute with the same type
            ["Register"]        = function(attr, noSameType)
                local attr      = attribute.ValidateValue(attr)
                if not attr then error("Usage : attribute.Register(attr) - the attr is not valid", 2) end
                Trace("New attribute %q is registered", tostring(attr))
                return addAttribtue(_RegisteredAttrs, attr, noSameType)
            end;

            -- Register an attribute type with usage information
            ["RegisterAttributeType"] = function(aType, usage)
                if _AttrTargetData[aType] and _AttrTargetData[aType][attribute] and _AttrTargetData[aType][attribute].Final then return end

                local extAttrs  = tblclone(_AttrTargetData[aType], _Cache())
                local attrusage = _Cache()

                Trace("New attribute type %q is registered", tostring(aType))

                -- Default usage data for attributes
                attrusage.AttributeTarget   = getAttrUsageField(usage, "AttributeTarget",ATTRIBUTE_TARGETS_ALL,      "number")
                attrusage.Inheritable       = getAttrUsageField(usage, "Inheritable",    false)
                attrusage.ApplyPhase        = getAttrUsageField(usage, "ApplyPhase",     ATTRIBUTE_APPLYPH_BEFOREDEF,"number")
                attrusage.Overridable       = getAttrUsageField(usage, "Overridable",    true)
                attrusage.ApplyAttribute    = getAttrUsageField(usage, "ApplyAttribute", nil,                        "function")
                attrusage.Priority          = getAttrUsageField(usage, "Priority",       0,                          "number")
                attrusage.SubLevel          = getAttrUsageField(usage, "SubLevel",       0,                          "number")

                -- A special data for attribute usage, so the attribute usage won't be overridden
                attrusage.Final             = getAttrUsageField(usage, "Final", false)

                extAttrs[attribute]         = attrusage
                _AttrTargetData[aType]      = extAttrs
            end;

            -- Register attribute type with name
            ["RegisterTargetType"]  = function(name, useNameAsApplyTarget)
                local i             = 2^0
                while _AttrTargetTypes[i] do i = i * 2 end
                _AttrTargetTypes[i] = name
                _AttrUseNameApply[i]= useNameAsApplyTarget and true or nil
                Trace("New attribute target type %q is registered", name)
                return i
            end;

            ["SuspendNextConsume"]  = function()
                _SuspendNextConsume = true
            end;

            -- Un-register attribute
            ["Unregister"]      = function(attr)
                for i, v in ipairs, _RegisteredAttrs, 0 do
                    if v == attr then
                        Trace("Attribtue %q is unregistered", tostring(attr))
                        return tremove(_RegisteredAttrs, i)
                    end
                end
            end;

            -- Validate whether the target is an attribute
            ["ValidateValue"]   = function(attr)
                return getAttributeUsage(attr) and attr or nil
            end;

            -- Validate whether the target is an attribute type
            ["Validate"]        = function(attrtype)
                local info      = _AttrTargetData[attrtype]
                return info and info[attribute] and attrtype or nil
            end;
        },
        __newindex              = readOnly,
    }
end

-------------------------------------------------------------------------------
--                                environment                                --
--                                                                           --
-- The environment is designed to be private environments for codes or type  --
-- building.                                                                 --
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                         attribute targets                         --
    -----------------------------------------------------------------------
    ATTRIBUTE_TARGETS_FUNCTION  = attribute.RegisterTargetType("Function")

    -----------------------------------------------------------------------
    --                         private variables                         --
    -----------------------------------------------------------------------
    -- Registered Keywords
    local _ENVKeys              = {}    -- Keywords for environment type
    local _GlobalKeys           = {}    -- Global keywords

    -- Keyword visitor
    local _KeyVisitor                   -- The environment that access the next keyword
    local _AccessKey                    -- The next keyword

    -- Environment Special Field
    local ENV_NS_OWNER          = "__PLOOP_ENV_OWNNS"
    local ENV_NS_IMPORTS        = "__PLOOP_ENV_IMPNS"
    local ENV_BASE_ENV          = "__PLOOP_ENV_BSENV"

    local ENV_ALLOW_NIL_GLBVAR  = PLOOP_PLATFORM_SETTINGS.ENV_ALLOW_GLOBAL_VAR_BE_NIL

    -- Share Helpers
    local saferawset            = PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD and not PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD_LUA_LOCK_APPLIED
        and function(self, key, value, stack)
            Error("Environment's auto-cache is disabled, you need use local for the %q variable", (stack or 1) + 1, key)
            rawset(self, key, value)    -- Block next error message, may cause lua error
        end or rawset

    local saferawget            = function (self, key) return self[key] end     -- Just a joke

    local parseParams           = function (keyword, ...)
        local env, target, definition, flag, stack
        local keyvisitor    = keyword and environment.GetKeywordVisitor(keyword)

        for i = 1, select('#', ...) do
            local v = select(i, ...)
            local t = type(v)

            if t == "boolean" then
                if flag == nil then flag = v end
            elseif t == "number" then
                stack = stack or v
            elseif t == "function" then
                definition = definition or v
            elseif t == "string" then
                v   = strtrim(v)
                if strfind(v, "^%S+$") then
                    target = target or v
                else
                    definition = definition or v
                end
            elseif t == "userdata" then
                if namespace.Validate(v) then
                    target = target or v
                end
            elseif t == "table" then
                if namespace.Validate(v) then
                    target = target or v
                else
                    -- Check if it's environment or the definition, well it's a little complex
                    if getmetatable(v) ~= nil or v == _G then
                        env = env or v
                    elseif not env then
                        if target then
                            -- env should be given before the target
                            definition = definition or v
                        else
                            -- We should check later
                            env = env or v
                        end
                    else
                        definition = definition or v
                    end
                end
            end
        end

        stack = stack or 2

        if not definition and env and not target and (getmetatable(env) == nil and env ~= _G) then
            -- Anonymous
            definition, env = env, nil
        end

        env = env or getfenv(stack + 2) or keyvisitor or _G

        if type(definition) == "string" then
            local def, msg  = loadSnippet("return function(_ENV)\n" .. definition .. "\nend", nil, env)
            if def then
                def, msg    = pcall(def)
                if def then
                    definition = msg
                else
                    error(msg, stack + 2)
                end
            else
                error(msg, stack + 2)
            end
        end

        return env, target, definition, flag, stack, keyvisitor
    end

    GetDefinitionParams         = function (self, ...)
        local _, _, definition, _, stack = parseParams(nil, self, ...)
        return definition, stack
    end

    -- Used for features like property, event, member and namespace
    GetFeatureParams            = function (ftype, ...)
        local env, name, definition, flag, stack, keyvisitor = parseParams(ftype, ...)
        return env, name, definition, flag, stack, keyvisitor
    end

    -- Used for types like enum, struct, class and interface : class([env,][name,][definition,][keepenv,][stack])
    GetTypeParams               = function (nType, prototype, ...)
        local env, target, definition, flag, stack, visitor = parseParams(nType, ...)

        if target then
            if type(target) == "string" then
                target = namespace.GenerateNameSpace(environment.GetNameSpace(visitor or env), target, prototype)
                if visitor then rawset(visitor, namespace.GetNameSpaceName(target, true), target) end
                if env and env ~= visitor then rawset(env, namespace.GetNameSpaceName(target, true), target) end
            else
                target = nType.Validate(target)
            end
        else
            target = namespace.GenerateNameSpace(nil, nil, prototype)
        end

        return env, target, definition, flag, stack, visitor
    end

    -- Prototypes
    environment                 = prototype "environment" {
        __index                 = {
            ["GetNameSpace"]    = function(env)
                return namespace.Validate(type(env) == "table" and rawget(env, ENV_NS_OWNER))
            end;

            ["GetParent"]       = function(env)
                return type(env) == "table" and rawget(env, ENV_BASE_ENV) or nil
            end;

            -- Get value for env, also auto-cache the value to env if auto-cache is true
            ["GetValue"]        = function(env, name, autocache, stack)
                local value
                if type(name) == "string" and type(env) == "table" then
                    -- Check Global Keywords
                    value           = _GlobalKeys[name]

                    -- Check environment special keywords
                    if not value then
                        local keys  = _ENVKeys[getmetatable(env)]
                        value       = keys and keys[name]
                    end

                    if value then
                        -- Register the keyword visitor
                        _KeyVisitor = env
                        _AccessKey  = value
                    else
                        -- Check current namespace
                        local ns    = namespace.Validate(rawget(env, ENV_NS_OWNER))
                        if ns then
                            value   = name == namespace.GetNameSpaceName(ns, true) and ns or ns[name]
                        end

                        -- Check imported namespaces
                        if value == nil then
                            local imp   = rawget(env, ENV_NS_IMPORTS)
                            if type(imp) == "table" then
                                for _, sns in ipairs, imp, 0 do
                                    sns = namespace.Validate(sns)
                                    if sns then
                                        value   = name == namespace.GetNameSpaceName(sns, true) and sns or sns[name]
                                        if value ~= nil then break end
                                    end
                                end
                            end
                        end

                        -- Check root namespaces
                        if value == nil then
                            value   = namespace.GetNameSpace(name)
                        end

                        -- Check parent
                        if value == nil then
                            local parent    = rawget(env, ENV_BASE_ENV)
                            if type(parent) == "table" then
                                if ENV_ALLOW_NIL_GLBVAR then
                                    value   = parent[name]
                                else
                                    local ok, ret = pcall(saferawget, parent, name)
                                    if not ok or ret == nil then error(("The global variable %q can't be nil."):format(name), (stack or 1) + 1) end
                                    value   = ret
                                end
                            end
                        end

                        -- Auto-Cache
                        if value ~= nil and autocache then
                            Trace("The %s is auto saving for %s", 3, name, tostring(env))
                            saferawset(env, name, value, (stack or 1) + 1)
                        end
                    end
                end
                return value
            end;

            ["GetKeywordVisitor"] = function(keyword)
                local visitor
                if _AccessKey == keyword then visitor = _KeyVisitor end
                _KeyVisitor     = nil
                _AccessKey      = nil
                return visitor
            end;

            -- Import namespace to env
            ["ImportNameSpace"] = function(env, ns)
                ns = namespace.Validate(ns)
                if type(env) ~= "table" then error("Usage: environment.ImportNameSpace(env, namespace) - the env must be a table", 2) end
                if not ns then error("Usage: environment.ImportNameSpace(env, namespace) - The namespace is not provided", 2) end

                local imports   = rawget(env, ENV_NS_IMPORTS)
                if not imports then imports = setmetatable({}, WEAK_VALUE) rawset(env, ENV_NS_IMPORTS, imports) end
                for _, v in ipairs, imports, 0 do if v == ns then return end end
                tinsert(imports, ns)
            end;

            ["RegisterGlobalKeyword"] = function(key, keyword)
                local keywords      = _GlobalKeys

                if type(key) == "table" and getmetatable(key) == nil then
                    for k, v in pairs, key do
                        if type(k) ~= "string" then k = tostring(v) end
                        if not keywords[k] and v then keywords[k] = v end
                    end
                else
                    if type(key) ~= "string" then key, keyword= tostring(key), key end
                    if key and not keywords[key] and keyword then keywords[key] = keyword end
                end
            end;

            ["RegisterContextKeyword"] = function(envtype, key, keyword)
                if not envtype or (type(envtype) ~= "table" and type(envtype) ~= "userdata") then error("Usage: environment.RegisterContextKeyword(envtype, key[, keyword]) - the envtype isn't valid", 2) end
                _ENVKeys[envtype]   = _ENVKeys[envtype] or {}
                local keywords      = _ENVKeys[envtype]

                if type(key) == "table" and getmetatable(key) == nil then
                    for k, v in pairs, key do
                        if type(k) ~= "string" then k = tostring(v) end
                        if not keywords[k] and v then keywords[k] = v end
                    end
                else
                    if type(key) ~= "string" then key, keyword= tostring(key), key end
                    if key and not keywords[key] and keyword then keywords[key] = keyword end
                end
            end;

            ["SetNameSpace"]    = function(env, ns)
                if type(env) ~= "table" then error("Usage: environment.SetNameSpace(env, namespace) - the env must be a table", 2) end
                rawset(env, ENV_NS_OWNER, namespace.Validate(ns))
            end;

            ["SetParent"]       = function(env, base)
                if type(env) ~= "table" then error("Usage: environment.SetParent(env, [parentenv]) - the env must be a table", 2) end
                if base and type(base) ~= "table" then error("Usage: environment.SetParent(env, [parentenv]) - the parentenv must be a table", 2) end
                rawset(env, ENV_BASE_ENV, base or nil)
            end;
        },
        __newindex              = readOnly,
    }

    -- Key feature : import "System"
    import                      = function (...)
        local env, name, _, flag, stack, visitor = GetFeatureParams(import, ...)

        name = namespace.Validate(name)
        if not env  then error("Usage: import(namespace) - The system can't figure out the environment", stack) end
        if not name then error("Usage: import(namespace) - The namespace is not provided", stack) end

        if visitor then
            environment.ImportNameSpace(visitor, name)
        else
            namespace.ExportNameSpace(env, name, flag)
        end
    end

    -- Simple environment
    tenvironment                = prototype "tenvironment" {
        __index                 = environment.GetValue,
        __tostring              = false, -- Environment's value maybe used as lock key, so keep __tostring nil
    }
end

-------------------------------------------------------------------------------
--                                 namespace                                 --
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                         attribute targets                         --
    -----------------------------------------------------------------------
    ATTRIBUTE_TARGETS_NAMESPACE = attribute.RegisterTargetType("Namespace")

    -----------------------------------------------------------------------
    --                         private variables                         --
    -----------------------------------------------------------------------
    local _NSTree               = setmetatable({}, WEAK_KEY)
    local _NSName               = setmetatable({}, WEAK_KEY)

    -- Shortcut
    local Validate
    local GetNameSpace

    -- Prototype
    namespace                   = prototype "namespace" {
        __index     = {
            -- Export a namespace and its children to an environment
            ["ExportNameSpace"] = function(env, ns, override)
                ns  = Validate(ns)
                if type(env) ~= "table" then error("Usage: namespace.ExportNameSpace(env, namespace[, override]) - the env must be a table", 2) end
                if not ns then error("Usage: namespace.ExportNameSpace(env, namespace[, override]) - The namespace is not provided", 2) end

                local nsname    = _NSName[ns]
                if nsname then
                    nsname      = strmatch(nsname, "[^%s%.]+$")
                    if override or rawget(env, nsname) == nil then rawset(env, nsname, ns) end
                end

                if _NSTree[ns] then
                    for name, sns in pairs, _NSTree[ns] do
                        if override or rawget(env, name) == nil then rawset(env, name, sns) end
                    end
                end
            end;

            -- Generate namespace by access name(if it is nil, anonymous namespace could be created)
            ["GenerateNameSpace"] = function(parent, name, prototype)
                if type(parent) == "string" then name, prototype, parent = parent, name, nil end
                prototype = prototype and prototype.Validate(prototype) or tnamespace

                if type(name) == "string" then
                    if parent ~= nil then
                        parent = Validate(parent)
                        if not parent then error("Usage: namespace.GenerateNameSpace([parent, ][name[, prototype]]) - parent must be a namespace", 2) end
                        if not _NSName[parent] then error("Usage: namespace.GenerateNameSpace([parent, ][name[, prototype]]) - parent can't be anonymous", 2) end
                    else
                        parent = ROOT_NAMESPACE
                    end

                    local ns    = parent
                    local iter  = strgmatch(name, "[^%s%.]+")
                    local sn    = iter()

                    while sn do
                        _NSTree[ns] = _NSTree[ns] or {}

                        local sns = _NSTree[ns][sn]
                        local nxt = iter()

                        if not sns then
                            sns = _NSTree[ns][sn]

                            if not sns then
                                sns = prototype.NewProxy(nxt and tnamespace or prototype)
                                _NSName[sns] = _NSName[ns] and _NSName[ns] .. "." .. sn or sn
                                _NSTree[ns][sn] = sns
                            end
                        end

                        ns, sn = sns, nxt
                    end

                    if ns ~= parent then return ns end
                    error("Usage: namespace.GenerateNameSpace([parent, ][name[, prototype]]) - name must be a string like 'System.Collections.List'", 2)
                elseif name == nil then
                    local ns = prototype.NewProxy(prototype)
                    _NSName[ns] = false
                    return ns
                else
                    error("Usage: namespace.GenerateNameSpace([parent, ][name[, prototype]]) - name must be a string or nil", 2)
                end
            end;

            -- Get the namespace by name
            ["GetNameSpace"]    = function(parent, name)
                if type(parent) == "string" then
                    name, parent = parent, nil
                elseif type(name)   ~= "string" then
                    error("Usage: namespace.GetNameSpace([parent, ]name) - name must be a string", 2)
                end
                if parent ~= nil then
                    parent = Validate(parent)
                    if not parent then error("Usage: namespace.GetNameSpace([parent, ]name) - parent must be a namespace", 2) end
                    if not _NSName[parent] then error("Usage: namespace.GetNameSpace([parent, ]name) - parent can't be anonymous", 2) end
                else
                    parent = ROOT_NAMESPACE
                end
                local ns = parent
                for sn in strgmatch(name, "[^%s%.]+") do
                    ns = _NSTree[ns] and _NSTree[ns][sn]
                    if not ns then return nil end
                end
                return ns ~= parent and ns or nil
            end;

            -- Get the namespace's name
            ["GetNameSpaceName"]= function(ns, last)
                local name = _NSName[Validate(ns)]
                if name ~= nil then return name and (last and strmatch(name, "[^%s%.]+$") or name) or "Anonymous" end
            end;

            ["IsResourceType"]  = function(ns)
                ns = Validate(ns)
                return ns and getmetatable(ns) ~= namespace or false
            end;

            -- Validate whether the arg is a namespace
            ["Validate"]        = function(ns)
                if type(ns) == "string" then ns = GetNameSpace(ns) end
                return _NSName[ns] ~= nil and ns or nil
            end;
        },
        __newindex              = readOnly,
        __call                  = function(self, ...)
            local env, name, _, flag, stack, visitor = GetFeatureParams(namespace, ...)

            if not env and not visitor then error("Usage: namespace([env, ][name[, stack]]) - the system can't figure out the environment", stack) end

            if name ~= nil then
                if type(name) == "string" then
                    name = namespace.GenerateNameSpace(name)
                else
                    name = namespace.Validate(name)
                end

                if not name then error("Usage: namespace([env, ][name[, stack]]) - the system can't figure out the namespace", stack) end

                attribute.ConsumeAttributes(name, ATTRIBUTE_TARGETS_NAMESPACE, nil, nil, stack + 1)
                attribute.ApplyAttributes  (name, ATTRIBUTE_TARGETS_NAMESPACE)
                attribute.ApplyAfterDefine (name, ATTRIBUTE_TARGETS_NAMESPACE)
            end

            environment.SetNameSpace(env, name)
            return name
        end,
    }

    -- Shortcut Assignment
    Validate                    = namespace.Validate
    GetNameSpace                = namespace.GetNameSpace

    -- default type for namespace
    tnamespace                  = prototype "tnamespace" {
        __index                 = GetNameSpace,
        __newindex              = readOnly,
        __tostring              = namespace.GetNameSpaceName,
        __metatable             = namespace,
    }

    -- Init the root namespace, anonymous namespace can be be collected as garbage
    ROOT_NAMESPACE              = namespace.GenerateNameSpace()
end

-------------------------------------------------------------------------------
--                                enumeration                                --
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                         attribute targets                         --
    -----------------------------------------------------------------------
    ATTRIBUTE_TARGETS_ENUM      = attribute.RegisterTargetType("Enum")

    -----------------------------------------------------------------------
    --                         private variables                         --
    -----------------------------------------------------------------------
    local _EnumInfo             = setmetatable({}, WEAK_KEY)
    local _EnumBuilderInfo      = setmetatable({}, WEAK_KEY)

    local _EnumValidMap         = {}

    -- FEATURE MODIFIER
    local MOD_SEALED_ENUM       = 2^0   -- SEALED
    local MOD_FLAGS_ENUM        = 2^1   -- FLAGS
    local MOD_NOT_FLAGS         = 2^2   -- NOT FLAG
    local MOD_CASE_IGNORED      = 2^3   -- CASE IGNORED

    local MOD_ENUM_INIT         = PLOOP_PLATFORM_SETTINGS.ENUM_GLOBAL_IGNORE_CASE and MOD_CASE_IGNORED or 0

    -- FIELD INDEX
    local FLD_ENUM_MOD          = 0     -- FIELD MODIFIER
    local FLD_ENUM_ITEMS        = 1     -- FIELD ENUMERATIONS
    local FLD_ENUM_CACHE        = 2     -- FIELD CACHE : VALUE -> NAME
    local FLD_ENUM_ERRMSG       = 3     -- FIELD ERROR MESSAGE
    local FLD_ENUM_VALID        = 4     -- FIELD VALIDATOR
    local FLD_ENUM_MAXVAL       = 5     -- FIELD MAX VALUE(FOR FLAGS)
    local FLD_ENUM_DEFAULT      = 6     -- FIELD DEFAULT

    -- Flags
    local FLG_FLAGS_ENUM        = 2^0
    local FLG_CASE_IGNORED      = 2^1

    local getEnumTargetInfo     = function (target)
        local info  = _EnumBuilderInfo[target]
        if info then return info, true else return _EnumInfo[target], false end
    end

    local genEnumValidator      = function (info)
        local token = 0

        if validateFlags(MOD_CASE_IGNORED, info[FLD_ENUM_MOD]) then
            token   = turnOnFlags(FLG_CASE_IGNORED, token)
        end

        if validateFlags(MOD_FLAGS_ENUM, info[FLD_ENUM_MOD]) then
            token   = turnOnFlags(FLG_FLAGS_ENUM, token)
        end

        if not _EnumValidMap[token] then
            local body      = _Cache()

            tinsert(body, "")   -- Remain for closure values
            tinsert(body, [[
                return function(info, value)
                local cache = info[]] .. FLD_ENUM_CACHE .. [[]
            ]])

            tinsert(body, [[if cache[value] then return value end]])

            tinsert(body, [[local vtype = type(value)]])

            tinsert(body, [[if vtype == "string" then]])

            if validateFlags(FLG_CASE_IGNORED, token) then
                tinsert(body, [[value = strupper(value)]])
            end

            tinsert(body, [[
                value = info[]] .. FLD_ENUM_ITEMS .. [[][value]
                return value, value == nil and info[]] .. FLD_ENUM_ERRMSG .. [[] or nil
            ]])

            if validateFlags(FLG_FLAGS_ENUM, token) then
                tinsert(body, [[
                    elseif vtype == "number" then
                        if value == 0 then
                            if cache[0] then return 0 end
                        elseif floor(value) == value and value > 0 and value <= info[]] .. FLD_ENUM_MAXVAL .. [[] then
                            return value
                        end
                ]])
            end

            tinsert(body, [[
                end
                return nil, info[]] .. FLD_ENUM_ERRMSG .. [[]
            ]])

            tinsert(body, [[end]])

            _EnumValidMap[token] = loadSnippet(tblconcat(body, "\n"), "Enum_Validate_" .. token)()

            _Cache(body)
        end

        info[FLD_ENUM_VALID] = _EnumValidMap[token]
    end

    enum                        = prototype "enum" {
        __index                 = {
            ["BeginDefinition"] = function(target, stack)
                stack   = type(stack) == "number" and stack or 2

                target  = enum.Validate(target)
                if not target then error("Usage: enum.BeginDefinition(enumeration[, stack]) - the enumeration not existed", stack) end

                local info      = _EnumInfo[target]

                -- if info and validateFlags(MOD_SEALED_ENUM, info[FLD_ENUM_MOD]) then error(strformat("Usage: enum.BeginDefinition(enumeration[, stack]) - The %s is sealed, can't be re-defined", tostring(target)), stack) end
                if _EnumBuilderInfo[target] then error(strformat("Usage: enum.BeginDefinition(enumeration[, stack]) - The %s's definition has already begun", tostring(target)), stack) end

                _EnumBuilderInfo[target]  = info and validateFlags(MOD_SEALED_ENUM, info[FLD_ENUM_MOD]) and tblclone(info, {}, true, true) or {
                    [FLD_ENUM_MOD]        = MOD_ENUM_INIT,
                    [FLD_ENUM_ITEMS]      = {},
                    [FLD_ENUM_CACHE]      = {},
                    [FLD_ENUM_ERRMSG]     = "%s must be a value of [" .. tostring(target) .."]",
                    [FLD_ENUM_VALID]      = false,
                    [FLD_ENUM_MAXVAL]     = false,
                    [FLD_ENUM_DEFAULT]    = nil,
                }

                attribute.ConsumeAttributes(target, ATTRIBUTE_TARGETS_ENUM, nil, nil, stack + 1)
            end;

            ["EndDefinition"]   = function(target, stack)
                local ninfo     = _EnumBuilderInfo[target]
                if not ninfo then return end

                stack = type(stack) == "number" and stack or 2

                -- If don't use the enumbuilder
                attribute.ApplyAttributes(target, ATTRIBUTE_TARGETS_ENUM)

                _EnumBuilderInfo[target] = nil

                -- Check Flags Enumeration
                if validateFlags(MOD_FLAGS_ENUM, ninfo[FLD_ENUM_MOD]) then
                    local enums = ninfo[FLD_ENUM_ITEMS]
                    local cache = wipe(ninfo[FLD_ENUM_CACHE])
                    local count = 0
                    local max   = 0

                    -- Scan
                    for k, v in pairs, enums do
                        v       = tonumber(v)

                        if v then
                            if v == 0 then
                                if cache[0] then
                                    error(strformat("The %s and %s can't be the same value", k, cache[0]), stack)
                                else
                                    cache[0] = k
                                end
                            elseif v > 0 then
                                count   = count + 1

                                local n = mlog(v) / mlog(2)
                                if floor(n) == n then
                                    if cache[2^n] then
                                        error(strformat("The %s and %s can't be the same value", k, cache[2^n]), stack)
                                    else
                                        cache[2^n]  = k
                                        max         = n > max and n or max
                                    end
                                else
                                    error(strformat("The %s's value is not a valid flags value(2^n)", k), stack)
                                end
                            else
                                error(strformat("The %s's value is not a valid flags value(2^n)", k), stack)
                            end
                        else
                            count       = count + 1
                            enums[k]    = -1
                        end
                    end

                    -- So the definition would be more precisely
                    if max >= count then error("The flags enumeration's value can't be greater than 2^(count - 1)", stack) end

                    -- Auto-gen values
                    local n     = 0
                    for k, v in pairs, enums do
                        if v == -1 then
                            while cache[2^n] do n = n + 1 end
                            cache[2^n]  = k
                            enums[k]    = 2^n
                        end
                    end

                    -- Mark the max value
                    ninfo[FLD_ENUM_MAXVAL] = 2^count - 1
                else
                    local enums = ninfo[FLD_ENUM_ITEMS]
                    local cache = ninfo[FLD_ENUM_CACHE]

                    ninfo[FLD_ENUM_MOD] = turnOnFlags(MOD_NOT_FLAGS, ninfo[FLD_ENUM_MOD])

                    for k, v in pairs, enums do
                        cache[v] = k
                    end
                end

                genEnumValidator(ninfo)

                -- Check Default
                if ninfo[FLD_ENUM_DEFAULT] ~= nil then
                    ninfo[FLD_ENUM_DEFAULT]  = ninfo[FLD_ENUM_VALID](ninfo, ninfo[FLD_ENUM_DEFAULT])
                    if ninfo[FLD_ENUM_DEFAULT] == nil then
                        error(ninfo[FLD_ENUM_ERRMSG]:format("The default"), stack)
                    end
                end

                -- Save as new enumeration's info
                _EnumInfo[target] = ninfo

                attribute.ApplyAfterDefine(target, ATTRIBUTE_TARGETS_ENUM)

                return target
            end;

            ["GetDefault"]      = function(target)
                local info      = getEnumTargetInfo(target)
                return info and info[FLD_ENUM_DEFAULT]
            end;

            ["GetEnumValues"]   = function(target, cache)
                local info      = _EnumInfo[target]
                if info then
                    if cache then
                        return tblclone(info[FLD_ENUM_ITEMS], type(cache) == "table" and wipe(cache) or {})
                    else
                        info    = info[FLD_ENUM_ITEMS]
                        return function(self, key) return next(info, key) end, target
                    end
                end
            end;

            ["IsCaseIgnored"]   = function(target)
                local info      = getEnumTargetInfo(target)
                return info and validateFlags(MOD_CASE_IGNORED, info[FLD_ENUM_MOD]) or false
            end;

            ["IsFlagsEnum"]     = function(target)
                local info      = getEnumTargetInfo(target)
                return info and validateFlags(MOD_FLAGS_ENUM, info[FLD_ENUM_MOD]) or false
            end;

            ["IsSealed"]        = function(target)
                local info      = getEnumTargetInfo(target)
                return info and validateFlags(MOD_SEALED_ENUM, info[FLD_ENUM_MOD]) or false
            end;

            ["IsSubType"]       = function() return false end;

            -- Parse the value to enumeration name
            ["Parse"]           = function(target, value, cache)
                local info      = _EnumInfo[target]
                if info then
                    local ecache= info[FLD_ENUM_CACHE]

                    if info[FLD_ENUM_MAXVAL] then
                        if cache then
                            local ret = type(cache) == "table" and wipe(cache) or {}

                            if type(value) == "number" and floor(value) == value and value >= 0 and value <= info[FLD_ENUM_MAXVAL] then
                                if value > 0 then
                                    local ckv = 1

                                    while ckv <= value and ecache[ckv] do
                                        if validateFlags(ckv, value) then ret[ecache[ckv]] = ckv end
                                        ckv = ckv * 2
                                    end
                                elseif value == 0 and ecache[0] then
                                    ret[ecache[0]] = 0
                                end
                            end

                            return ret
                        elseif type(value) == "number" and floor(value) == value and value >= 0 and value <= info[FLD_ENUM_MAXVAL] then
                            if value == 0 then
                                return function(self, key) if not key then return ecache[0], 0 end end, target
                            else
                                local ckv = 1
                                return function(self, key)
                                    while ckv <= value and ecache[ckv] do
                                        local v = ckv
                                        ckv = ckv * 2
                                        if validateFlags(v, value) then return ecache[v], v end
                                    end
                                end
                            end
                        else
                            return fakefunc, target
                        end
                    else
                        return ecache[value]
                    end
                end
            end;

            ["SetDefault"]      = function(target, default, stack)
                local info, def = getEnumTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    if not def then error(strformat("Usage: enum.SetDefault(enumeration, default[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                    info[FLD_ENUM_DEFAULT] = default
                else
                    error("Usage: enum.SetDefault(enumeration, default[, stack]) - The enumeration is not valid", stack)
                end
            end;

            ["SetEnumValue"]    = function(target, key, value, stack)
                local info, def = getEnumTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    if not def then error(strformat("Usage: enum.SetEnumValue(enumeration, key, value[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                    if type(key) ~= "string" then error("Usage: enum.SetEnumValue(enumeration, key, value[, stack]) - The key must be a string", stack) end

                    for k, v in pairs, info[FLD_ENUM_ITEMS] do
                        if strupper(k) == strupper(key) then
                            if (validateFlags(MOD_CASE_IGNORED, info[FLD_ENUM_MOD]) and strupper(key) or key) == k and v == value then return end
                            error("Usage: enum.SetEnumValue(enumeration, key, value[, stack]) - The key already existed", stack)
                        elseif v == value then
                            error("Usage: enum.SetEnumValue(enumeration, key, value[, stack]) - The value already existed", stack)
                        end
                    end

                    info[FLD_ENUM_ITEMS][validateFlags(MOD_CASE_IGNORED, info[FLD_ENUM_MOD]) and strupper(key) or key] = value
                else
                    error("Usage: enum.SetEnumValue(enumeration, key, value[, stack]) - The enumeration is not valid", stack)
                end
            end;

            ["SetCaseIgnored"]  = function(target, stack)
                local info, def = getEnumTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    if not validateFlags(MOD_CASE_IGNORED, info[FLD_ENUM_MOD]) then
                        if not def then error(strformat("Usage: enum.SetCaseIgnored(enumeration[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                        info[FLD_ENUM_MOD] = turnOnFlags(MOD_CASE_IGNORED, info[FLD_ENUM_MOD])

                        local enums     = info[FLD_ENUM_ITEMS]
                        local nenums    = _Cache()
                        for k, v in pairs, enums do nenums[strupper(k)] = v end
                        info[FLD_ENUM_ITEMS]  = nenums
                        _Cache(enums)
                    end
                else
                    error("Usage: enum.SetCaseIgnored(enumeration[, stack]) - The enumeration is not valid", stack)
                end
            end;

            ["SetFlagsEnum"]    = function(target, stack)
                local info, def = getEnumTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    if not validateFlags(MOD_FLAGS_ENUM, info[FLD_ENUM_MOD]) then
                        if not def then error(strformat("Usage: enum.SetFlagsEnum(enumeration[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                        if validateFlags(MOD_NOT_FLAGS, info[FLD_ENUM_MOD]) then error(strformat("Usage: enum.SetFlagsEnum(enumeration[, stack]) - The %s is defined as non-flags enumeration", tostring(target)), stack) end
                        info[FLD_ENUM_MOD] = turnOnFlags(MOD_FLAGS_ENUM, info[FLD_ENUM_MOD])
                    end
                else
                    error("Usage: enum.SetFlagsEnum(enumeration[, stack]) - The enumeration is not valid", stack)
                end
            end;

            ["SetSealed"]       = function(target, stack)
                local info      = getEnumTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    if not validateFlags(MOD_SEALED_ENUM, info[FLD_ENUM_MOD]) then
                        info[FLD_ENUM_MOD] = turnOnFlags(MOD_SEALED_ENUM, info[FLD_ENUM_MOD])
                    end
                else
                    error("Usage: enum.SetSealed(enumeration[, stack]) - The enumeration is not valid", stack)
                end
            end;

            ["ValidateFlags"]   = validateFlags;

            ["ValidateValue"]   = function(target, value)
                local info      = _EnumInfo[target]
                if info then
                    return info[FLD_ENUM_VALID](info, value)
                else
                    error("Usage: enum.ValidateValue(enumeration, value) - The enumeration is not valid", 2)
                end
            end;

            -- Validate whether the value is an enum type
            ["Validate"]        = function(target)
                return getmetatable(target) == enum and target or nil
            end;
        },
        __newindex              = readOnly,
        __call                  = function(self, ...)
            local env, target, definition, flag, stack, visitor = GetTypeParams(enum, tenum, ...)
            if not target then
                error("Usage: enum([env, ][name, ][definition][, stack]) - the enumeration type can't be created", stack)
            elseif definition ~= nil and type(definition) ~= "table" then
                error("Usage: enum([env, ][name, ][definition][, stack]) - the definition should be a table", stack)
            end

            enum.BeginDefinition(target, stack + 1)

            local builder = prototype.NewObject(enumbuilder)
            environment.SetNameSpace(builder, target)

            if definition then
                builder(definition, stack + 1)
                return target
            else
                return builder
            end
        end,
    }

    tenum                       = prototype "tenum" (tnamespace, {
        __index                 = enum.ValidateValue,
        __call                  = enum.Parse,
        __metatable             = enum,
    })

    enumbuilder                 = prototype "enumbuilder" {
        __index                 = writeOnly,
        __newindex              = readOnly,
        __call                  = function(self, ...)
            local definition, stack = GetDefinitionParams(self, ...)
            if type(definition) ~= "table" then error("Usage: enum([env, ][name, ][stack]) {...} - The definition table is missing", stack) end

            local owner = environment.GetNameSpace(self)
            if not owner then error("The enumeration can't be found", stack) end
            if not _EnumBuilderInfo[owner] then error(strformat("The %s's definition is finished", tostring(owner)), stack) end

            attribute.ApplyAttributes(owner, ATTRIBUTE_TARGETS_ENUM, definition)

            stack   = stack + 1

            for k, v in pairs, definition do
                if type(k) == "string" then
                    enum.SetEnumValue(owner, k, v, stack)
                elseif type(v) == "string" then
                    enum.SetEnumValue(owner, v, v, stack)
                end
            end

            enum.EndDefinition(owner, stack)
            return owner
        end,
    }
end

-------------------------------------------------------------------------------
--                                 structure                                 --
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                         attribute targets                         --
    -----------------------------------------------------------------------
    ATTRIBUTE_TARGETS_STRUCT    = attribute.RegisterTargetType("Struct")
    ATTRIBUTE_TARGETS_METHOD    = attribute.RegisterTargetType("Method")
    ATTRIBUTE_TARGETS_MEMBER    = attribute.RegisterTargetType("Member", true)

    -----------------------------------------------------------------------
    --                          public constants                         --
    -----------------------------------------------------------------------
    STRUCT_TYPE_MEMBER          = "MEMBER"
    STRUCT_TYPE_ARRAY           = "ARRAY"
    STRUCT_TYPE_CUSTOM          = "CUSTOM"

    -----------------------------------------------------------------------
    --                         private variables                         --
    -----------------------------------------------------------------------
    local _StrtInfo             = setmetatable({}, WEAK_KEY)
    local _DependenceMap        = setmetatable({}, WEAK_KEY)
    local _StructBuilderInfo    = setmetatable({}, WEAK_KEY)
    local _StructBuilderInDefine= setmetatable({}, WEAK_KEY)

    local _StructValidMap       = {}
    local _StructCtorMap        = {}

    -- FEATURE MODIFIER
    local MOD_SEALED_STRUCT     = 2^0       -- SEALED

    -- FIELD INDEX
    local FLD_STRUCT_MOD        = -1        -- FIELD MODIFIER
    local FLD_STRUCT_TYPEMETHOD = -2        -- FIELD OBJECT METHODS
    local FLD_STRUCT_DEFAULT    = -3        -- FEILD DEFAULT
    local FLD_STRUCT_BASE       = -4        -- FIELD BASE STRUCT
    local FLD_STRUCT_VALID      = -5        -- FIELD VALIDATOR
    local FLD_STRUCT_CTOR       = -6        -- FIELD CONSTRUCTOR
    local FLD_STRUCT_NAME       = -7        -- FEILD STRUCT NAME
    local FLD_STRUCT_ERRMSG     = -8        -- FIELD ERROR MESSAGE
    local FLD_STRUCT_VALIDCACHE = -9        -- FIELD VALIDATOR CACHE

    local FLD_STRUCT_ARRAY      =  0        -- FIELD ARRAY ELEMENT
    local FLD_STRUCT_ARRVALID   =  2        -- FIELD ARRAY ELEMENT VALIDATOR
    local FLD_STRUCT_MEMBERSTART=  1        -- FIELD START INDEX OF MEMBER
    local FLD_STRUCT_VALIDSTART =  10000    -- FIELD START INDEX OF VALIDATOR
    local FLD_STRUCT_INITSTART  =  20000    -- FIELD START INDEX OF INITIALIZE

    -- MEMBER FIELD INDEX
    local FLD_MEMBER_NAME       =  1        -- MEMBER FIELD NAME
    local FLD_MEMBER_TYPE       =  2        -- MEMBER FIELD TYPE
    local FLD_MEMBER_VALID      =  3        -- MEMBER FIELD TYPE VALIDATOR
    local FLD_MEMBER_DEFAULT    =  4        -- MEMBER FIELD DEFAULT
    local FLD_MEMBER_DEFTFACTORY=  5        -- MEMBER FIELD AS DEFAULT FACTORY
    local FLD_MEMBER_REQUIRE    =  0        -- MEMBER FIELD REQUIRED

    -- TYPE FLAGS
    local FLG_CUSTOM_STRUCT     = 2^0       -- CUSTOM STRUCT FLAG
    local FLG_MEMBER_STRUCT     = 2^1       -- MEMBER STRUCT FLAG
    local FLG_ARRAY_STRUCT      = 2^2       -- ARRAY  STRUCT FLAG
    local FLG_STRUCT_SINGLE_VLD = 2^3       -- SINGLE VALID  FLAG
    local FLG_STRUCT_MULTI_VLD  = 2^4       -- MULTI  VALID  FLAG
    local FLG_STRUCT_SINGLE_INIT= 2^5       -- SINGLE INIT   FLAG
    local FLG_STRUCT_MULTI_INIT = 2^6       -- MULTI  INIT   FLAG
    local FLG_STRUCT_OBJ_METHOD = 2^7       -- OBJECT METHOD FLAG
    local FLG_STRUCT_VALIDCACHE = 2^8       -- VALID  CACHE  FLAG
    local FLG_STRUCT_MULTI_REQ  = 2^9       -- MULTI  FIELD  REQUIRE FLAG
    local FLG_STRUCT_FIRST_TYPE = 2^10      -- FIRST  MEMBER TYPE    FLAG

    local STRUCT_KEYWORD_INIT   = "__init"
    local STRUCT_KEYWORD_BASE   = "__base"

    local STRUCT_BUILDER_NEWMTD = "__PLOOP_BD_NEWMTD"

    local getEnumTargetInfo     = function (target)
        local info  = _StructBuilderInfo[target]
        if info then return info, true else return _StrtInfo[target], false end
    end

    local setStructBuilderValue = function (self, key, value, stack, notnewindex)
        local owner = environment.GetNameSpace(self)
        if not (owner and _StructBuilderInDefine[self]) then error("The structure's definition is finished", stack) end

        local tkey  = type(key)
        local tval  = type(value)

        stack       = stack + 1

        if tkey == "string" and not tonumber(key) then
            if tval == "function" then
                if key == STRUCT_KEYWORD_INIT then
                    struct.SetInitializer(owner, value, stack)
                    return true
                elseif key == namespace.GetNameSpaceName(owner, true) then
                    struct.SetValidator(owner, value, stack)
                    return true
                else
                    struct.AddMethod(owner, key, value, stack)
                    if not notnewindex then
                        -- Those functions should be saved to the builder when the definition is finished
                        local newMethod = rawget(self, STRUCT_BUILDER_NEWMTD)
                        if not newMethod then
                            newMethod   = {}
                            rawset(self, STRUCT_BUILDER_NEWMTD, newMethod)
                        end
                        newMethod[key]  = true
                    end
                    return true
                end
            elseif namespace.IsResourceType(value) then
                if key == STRUCT_KEYWORD_BASE then
                    struct.SetBaseStruct(owner, value, stack)
                else
                    struct.AddMember(owner, key, { Type = value }, stack)
                end
                return true
            elseif tval == "table" and notnewindex then
                struct.AddMember(owner, key, value, stack)
                return true
            end
        elseif tkey == "number" then
            if tval == "function" then
                struct.SetValidator(owner, value, stack)
            elseif namespace.IsResourceType(value) then
                struct.SetArrayElement(owner, value, stack)
            elseif tval == "table" then
                struct.AddMember(owner, value, stack)
            else
                struct.SetDefault(owner, value, stack)
            end
            return true
        end
    end

    -- Update dependence
    local notAllSealedStruct    = function (target)
        if target and struct.Validate(target) then
            local info, def = getEnumTargetInfo(target)

            if def or not validateFlags(MOD_SEALED_STRUCT, info[FLD_STRUCT_MOD]) then
                return true
            end

            if info[FLD_STRUCT_ARRAY] then
                return notAllSealedStruct(info[FLD_STRUCT_ARRAY])
            elseif info[FLD_STRUCT_MEMBERSTART] then
                for _, m in ipairs, info, FLD_STRUCT_MEMBERSTART - 1 do
                    if notAllSealedStruct(m) then
                        return true
                    end
                end
            end
        end
    end

    local checkStructDependence = function (target, chkType)
        if target ~= chkType then
            if notAllSealedStruct(chkType) then
                _DependenceMap[chkType]         = _DependenceMap[chkType] or setmetatable({}, WEAK_KEY)
                _DependenceMap[chkType][target] = true
            elseif chkType and _DependenceMap[chkType] then
                _DependenceMap[chkType][target] = nil
                if not next(_DependenceMap[chkType]) then _DependenceMap[chkType] = nil end
            end
        end
    end

    local updateStructDependence= function (target, info)
        info = info or getEnumTargetInfo(target)

        if info[FLD_STRUCT_ARRAY] then
            checkStructDependence(target, info[FLD_STRUCT_ARRAY])
        elseif info[FLD_STRUCT_MEMBERSTART] then
            for _, m in ipairs, info, FLD_STRUCT_MEMBERSTART - 1 do
                checkStructDependence(target, m)
            end
        end
    end

    -- Cache required
    local checkRepeatStructType = function (target, info)
        if info[FLD_STRUCT_ARRAY] then
            if info[FLD_STRUCT_ARRAY] == target then return true end
            return checkRepeatStructType(target, getEnumTargetInfo(info[FLD_STRUCT_ARRAY]))
        elseif info[FLD_STRUCT_MEMBERSTART] then
            for _, m in ipairs, info, FLD_STRUCT_MEMBERSTART - 1 do
                if m == target or checkRepeatStructType(target, getEnumTargetInfo(m)) then
                    return true
                end
            end
        end

        return false
    end

    -- Validator
    local genStructValidator    = function (info)
        local token = 0
        local upval = _Cache()

        if info[FLD_STRUCT_VALIDCACHE] then
            token = turnOnFlags(FLG_STRUCT_VALIDCACHE, token)
        end

        if info[FLD_STRUCT_MEMBERSTART] then
            token   = turnOnFlags(FLG_MEMBER_STRUCT, token)
            local i = FLD_STRUCT_MEMBERSTART
            while info[i + 1] do i = i + 1 end
            tinsert(upval, i)
        elseif info[FLD_STRUCT_ARRAY] then
            token   = turnOnFlags(FLG_ARRAY_STRUCT, token)
        else
            token   = turnOnFlags(FLG_CUSTOM_STRUCT, token)
        end

        if info[FLD_STRUCT_VALIDSTART] then
            if info[FLD_STRUCT_VALIDSTART + 1] then
                local i = FLD_STRUCT_VALIDSTART + 2
                while info[i] do i = i + 1 end
                token = turnOnFlags(FLG_STRUCT_MULTI_VLD, token)
                tinsert(upval, i - 1)
            else
                token = turnOnFlags(FLG_STRUCT_SINGLE_VLD, token)
            end
        end

        if info[FLD_STRUCT_INITSTART] then
            if info[FLD_STRUCT_INITSTART + 1] then
                local i = FLD_STRUCT_INITSTART + 2
                while info[i] do i = i + 1 end
                token = turnOnFlags(FLG_STRUCT_MULTI_INIT, token)
                tinsert(upval, i - 1)
            else
                token = turnOnFlags(FLG_STRUCT_SINGLE_INIT, token)
            end
        end

        if info[FLD_STRUCT_TYPEMETHOD] then
            for k, v in pairs, info[FLD_STRUCT_TYPEMETHOD] do
                if v then
                    token   = turnOnFlags(FLG_STRUCT_OBJ_METHOD, token)
                    break
                end
            end
        end

        -- Build the validator generator
        if not _StructValidMap[token] then
            local header    = _Cache()
            local body      = _Cache()

            tinsert(body, "")   -- Remain for closure values
            tinsert(body, [[return function(info, value, onlyValid, cache)]])

            if validateFlags(FLG_MEMBER_STRUCT, token) or validateFlags(FLG_ARRAY_STRUCT, token) then
                tinsert(body, [[
                    if type(value)         ~= "table" then return nil, onlyValid or "%s must be a table." end
                    if getmetatable(value) ~= nil     then return nil, onlyValid or "%s must be a table without meta-table." end
                ]])

                if validateFlags(FLG_STRUCT_VALIDCACHE, token) then
                    tinsert(body, [[
                        -- Cache to block recursive validation
                        local vcache = cache[info]
                        if not vcache then
                            vcache = _Cache()
                            cache[info] = vcache
                        elseif vcache[value] then
                            return value
                        end
                        vcache[value]= true
                    ]])
                end
            end

            if validateFlags(FLG_MEMBER_STRUCT, token) then
                tinsert(header, "count")
                tinsert(body, [[
                    if onlyValid then
                        for i = ]] .. FLD_STRUCT_MEMBERSTART .. [[, count do
                            local mem  = info[i]
                            local name = mem[]] .. FLD_MEMBER_NAME .. [[]
                            local vtype= mem[]] .. FLD_MEMBER_TYPE ..[[]
                            local val  = value[name]
                            local msg

                            if val == nil then
                                if mem[]] .. FLD_MEMBER_REQUIRE .. [[] then
                                    return nil, true
                                end
                            elseif vtype then
                                val, msg = mem[]] .. FLD_MEMBER_VALID .. [[](vtype, val, true, cache)
                                if msg then return nil, true end
                            end
                        end
                    else
                        for i = ]] .. FLD_STRUCT_MEMBERSTART .. [[, count do
                            local mem  = info[i]
                            local name = mem[]] .. FLD_MEMBER_NAME .. [[]
                            local vtype= mem[]] .. FLD_MEMBER_TYPE ..[[]
                            local val  = value[name]
                            local msg

                            if val == nil then
                                if mem[]] .. FLD_MEMBER_REQUIRE .. [[] then
                                    return nil, strformat("%s.%s can't be nil", "%s", name)
                                end

                                if mem[]] .. FLD_MEMBER_DEFTFACTORY .. [[] then
                                    val= mem[]] .. FLD_MEMBER_DEFAULT .. [[](value)
                                else
                                    val= clone(mem[]] .. FLD_MEMBER_DEFAULT .. [[], true)
                                end
                            elseif vtype then
                                val, msg = mem[]] .. FLD_MEMBER_VALID .. [[](vtype, val, false, cache)
                                if msg then return nil, type(msg) == "string" and strgsub(msg, "%%s", "%%s" .. "." .. name) or strformat("%s.%s must be [%s]", "%s", name, tostring(vtype)) end
                            end

                            value[name] = val
                        end
                    end
                ]])
            elseif validateFlags(FLG_ARRAY_STRUCT, token) then
                tinsert(body, [[
                    local array = info[]] .. FLD_STRUCT_ARRAY .. [[]
                    local avalid= info[]] .. FLD_STRUCT_ARRVALID .. [[]
                    if onlyValid then
                        for i, v in ipairs, value, 0 do
                            local ret, msg  = avalid(array, v, true, cache)
                            if msg then return nil, true end
                        end
                    else
                        for i, v in ipairs, value, 0 do
                            local ret, msg  = avalid(array, v, false, cache)
                            if msg then return nil, type(msg) == "string" and strgsub(msg, "%%s", "%%s[" .. i .. "]") or strformat("%s[%s] must be [%s]", "%s", i, tostring(array)) end
                            value[i] = ret
                        end
                    end
                ]])
            end

            if validateFlags(FLG_STRUCT_SINGLE_VLD, token) then
                tinsert(body, [[
                    local msg = info[]] .. FLD_STRUCT_VALIDSTART .. [[](value)
                    if msg then return nil, onlyValid or type(msg) == "string" and msg or strformat("%s must be [%s]", "%s", info[]] .. FLD_STRUCT_NAME .. [[]) end
                ]])
            elseif validateFlags(FLG_STRUCT_MULTI_VLD, token) then
                tinsert(header, "mvalid")
                tinsert(body, [[
                    for i = ]] .. FLD_STRUCT_VALIDSTART .. [[, mvalid do
                        local msg = info[i](value)
                        if msg then return nil, onlyValid or type(msg) == "string" and msg or strformat("%s must be [%s]", "%s", info[]] .. FLD_STRUCT_NAME .. [[]) end
                    end
                ]])
            end

            if validateFlags(FLG_STRUCT_SINGLE_INIT, token) or validateFlags(FLG_STRUCT_MULTI_INIT, token) then
                tinsert(body, [[if onlyValid then return value end]])

                if validateFlags(FLG_STRUCT_SINGLE_INIT, token) then
                    tinsert(body, [[
                        local ret = info[]] .. FLD_STRUCT_INITSTART .. [[](value)
                    ]])

                    if validateFlags(FLG_CUSTOM_STRUCT, token) then
                        tinsert(body, [[if ret ~= nil then value = ret end]])
                    end
                else
                    tinsert(header, "minit")
                    tinsert(body, [[
                        for i = ]] .. FLD_STRUCT_INITSTART .. [[, minit do
                            local ret = info[i](value)
                        ]])
                    if validateFlags(FLG_CUSTOM_STRUCT, token) then
                        tinsert(body, [[if ret ~= nil then value = ret end]])
                    end
                    tinsert(body, [[end]])
                end
            end

            if validateFlags(FLG_STRUCT_OBJ_METHOD, token) then
                if validateFlags(FLG_CUSTOM_STRUCT, token) then
                    tinsert(body, [[if type(value) == "table" then]])
                end

                tinsert(body, [[
                    for k, v in pairs, info[]] .. FLD_STRUCT_TYPEMETHOD .. [[] do
                        if v and value[k] == nil then value[k] = v end
                    end
                ]])

                if validateFlags(FLG_CUSTOM_STRUCT, token) then
                    tinsert(body, [[end]])
                end
            end

            tinsert(body, [[
                    return value
                end
            ]])

            if #header > 0 then
                body[1] = "local " .. tblconcat(header, ",") .. "= ..."
            end

            _StructValidMap[token] = loadSnippet(tblconcat(body, "\n"), "Struct_Validate_" .. token)

            if #header == 0 then
                _StructValidMap[token] = _StructValidMap[token]()
            end

            _Cache(header)
            _Cache(body)
        end

        if #upval > 0 then
            info[FLD_STRUCT_VALID] = _StructValidMap[token](unpack(upval))
        else
            info[FLD_STRUCT_VALID] = _StructValidMap[token]
        end

        _Cache(upval)
    end

    -- Ctor
    local genStructConstructor  = function (info)
        local token = 0
        local upval = _Cache()

        if info[FLD_STRUCT_VALIDCACHE] then
            token   = turnOnFlags(FLG_STRUCT_VALIDCACHE, token)
        end

        if info[FLD_STRUCT_MEMBERSTART] then
            token   = turnOnFlags(FLG_MEMBER_STRUCT, token)
            local i = FLD_STRUCT_MEMBERSTART + 1
            local r = false
            while info[i] do
                if not r and info[i][FLD_MEMBER_REQUIRE] then r = true end
                i = i + 1
            end
            tinsert(upval, i - 1)
            if r then
                token = turnOnFlags(FLG_STRUCT_MULTI_REQ, token)
            elseif info[FLD_STRUCT_MEMBERSTART][FLD_MEMBER_TYPE] then
                token = turnOnFlags(FLG_STRUCT_FIRST_TYPE, token)
                tinsert(upval, info[FLD_STRUCT_MEMBERSTART][FLD_MEMBER_TYPE])
                tinsert(upval, info[FLD_STRUCT_MEMBERSTART][FLD_MEMBER_VALID])
            end
        elseif info[FLD_STRUCT_ARRAY] then
            token   = turnOnFlags(FLG_ARRAY_STRUCT, token)
        else
            token   = turnOnFlags(FLG_CUSTOM_STRUCT, token)
        end

        -- Build the validator generator
        if not _StructCtorMap[token] then
            local header    = _Cache()
            local body      = _Cache()

            tinsert(body, "")

            if validateFlags(FLG_MEMBER_STRUCT, token) or validateFlags(FLG_ARRAY_STRUCT, token) then
                tinsert(body, [[
                    return function(info, first, ...)
                        local ivalid = info[]].. FLD_STRUCT_VALID .. [[]
                        local ret, msg
                        if select("#", ...) == 0 and type(first) == "table" and getmetatable(first) == nil then
                ]])

                if validateFlags(FLG_MEMBER_STRUCT, token) then
                    tinsert(header, "count")
                    if not validateFlags(FLG_STRUCT_MULTI_REQ, token) then
                        -- So, it may be the first member
                        if validateFlags(FLG_STRUCT_FIRST_TYPE, token) then
                            tinsert(header, "ftype")
                            tinsert(header, "fvalid")
                            tinsert(body, [[
                                local _, fmatch = fvalid(ftype, first, true) fmatch = not fmatch
                            ]])
                        else
                            tinsert(body, [[
                                local fmatch = true
                            ]])
                        end
                    else
                        tinsert(body, [[local fmatch = false]])
                    end
                elseif validateFlags(FLG_ARRAY_STRUCT, token) then
                    tinsert(body, [[
                        local _, fmatch = info[]] .. FLD_STRUCT_ARRVALID .. [[](info[]] .. FLD_STRUCT_ARRAY .. [[], first, true) fmatch = not fmatch
                    ]])
                end

                if validateFlags(FLG_STRUCT_VALIDCACHE, token) then
                    tinsert(body, [[
                        local cache = _Cache()
                        ret, msg    = ivalid(info, first, fmatch, cache)
                        for k, v in pairs, cache do cache[k] = nil _Cache(v) end _Cache(cache)
                    ]])
                else
                    tinsert(body, [[ret, msg = ivalid(info, first, fmatch)]])
                end

                tinsert(body, [[
                        if not msg then
                            if fmatch then
                ]])

                if validateFlags(FLG_STRUCT_VALIDCACHE, token) then
                    tinsert(body, [[
                        local cache = _Cache()
                        ret, msg = ivalid(info, first, false, cache)
                        for k, v in pairs, cache do cache[k] = nil _Cache(v) end _Cache(cache)
                    ]])
                else
                    tinsert(body, [[ret, msg = ivalid(info, first, false)]])
                end

                tinsert(body, [[
                            end
                            return ret
                        elseif not fmatch then
                            error(info[]] .. FLD_STRUCT_ERRMSG .. [[] .. (type(msg) == "string" and strgsub(msg, "%%s%.?", "") or "the value is not valid."), 3)
                        end
                    end
                ]])
            else
                tinsert(body, [[
                    return function(info, first)
                        local ivalid = info[]].. FLD_STRUCT_VALID .. [[]
                        local ret, msg
                ]])
            end

            if validateFlags(FLG_MEMBER_STRUCT, token) then
                tinsert(body, [[
                    ret = {}
                    local j = 1
                    ret[ info[]] .. FLD_STRUCT_MEMBERSTART .. [[][]] .. FLD_MEMBER_NAME .. [[] ] = first
                    for i = ]] .. (FLD_STRUCT_MEMBERSTART + 1) .. [[, count do
                        ret[ info[i][]] .. FLD_MEMBER_NAME .. [[] ] = (select(j, ...))
                        j = j + 1
                    end
                ]])
            elseif validateFlags(FLG_ARRAY_STRUCT, token) then
                tinsert(body, [[
                    ret = { first, ... }
                ]])
            else
                tinsert(body, [[ret = first]])
            end

            if validateFlags(FLG_STRUCT_VALIDCACHE, token) then
                tinsert(body, [[
                    local cache = _Cache()
                    ret, msg = ivalid(info, ret, false, cache)
                    for k, v in pairs, cache do cache[k] = nil _Cache(v) end _Cache(cache)
                ]])
            else
                tinsert(body, [[
                    ret, msg = ivalid(info, ret, false)
                ]])
            end

            tinsert(body, [[if not msg then return ret end]])

            if validateFlags(FLG_MEMBER_STRUCT, token) or validateFlags(FLG_ARRAY_STRUCT, token) then
                tinsert(body, [[
                    error(info[]] .. FLD_STRUCT_ERRMSG .. [[] .. (type(msg) == "string" and strgsub(msg, "%%s%.?", "") or "the value is not valid."), 3)
                ]])
            else
                tinsert(body, [[
                    error(strgsub(msg, "%%s", "the value"), 3)
                ]])
            end

            tinsert(body, [[end]])

            if #header > 0 then
                body[1] = "local " .. tblconcat(header, ",") .. "= ..."
            end

            _StructCtorMap[token] = loadSnippet(tblconcat(body, "\n"), "Struct_Ctor_" .. token)

            if #header == 0 then
                _StructCtorMap[token] = _StructCtorMap[token]()
            end

            _Cache(header)
            _Cache(vbody)
        end

        if #upval > 0 then
            info[FLD_STRUCT_CTOR] = _StructCtorMap[token](unpack(upval))
        else
            info[FLD_STRUCT_CTOR] = _StructCtorMap[token]
        end

        _Cache(upval)
    end

    -- Refresh Depends
    local updateStructDepends   = function (target, cache)
        local map = _DependenceMap[target]

        if map then
            _DependenceMap[target] = nil

            for t in pairs, map do
                if not cache[t] then
                    cache[t] = true

                    local info, def = getEnumTargetInfo(t)
                    if not def then
                        updateStructDependence(t, info)

                        local nVcache = checkRepeatStructType(t, info)

                        if nVcache ~= info[FLD_STRUCT_VALIDCACHE] then
                            info[FLD_STRUCT_VALIDCACHE] = nVcache

                            genStructValidator(info)
                            genStructConstructor(info)
                        end

                        updateStructDepends(t, cache)
                    end
                end
            end

            _Cache(map)
        end
    end

    struct                      = prototype "struct" {
        __index                 = {
            ["AddMember"]       = function(target, name, definition, stack)
                local info, def = getEnumTargetInfo(target)

                if type(name) == "table" then
                    definition, stack, name = name, definition, nil
                    for k, v in pairs, definition do
                        if type(k) == "string" and strlower(k) == "name" and type(v) == "string" and not tonumber(v) then
                            name, definition[k] = v, nil
                            break
                        end
                    end
                end
                stack = type(stack) == "number" and stack or 2

                if info then
                    if not def then error(strformat("Usage: struct.AddMember(structure[, name], definition[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                    if type(name) ~= "string" then error("Usage: struct.AddMember(structure[, name], definition[, stack]) - The name must be a string", stack) end
                    name = strtrim(name)
                    if name == "" then error("Usage: struct.AddMember(structure[, name], definition[, stack]) - The name can't be empty", stack) end
                    if type(definition) ~= "table" then error("Usage: struct.AddMember(structure[, name], definition[, stack]) - The definition is missing", stack) end
                    if info[FLD_STRUCT_ARRAY] then error("Usage: struct.AddMember(structure[, name], definition[, stack]) - The structure is an array structure, can't add member", stack) end

                    local idx = FLD_STRUCT_MEMBERSTART
                    while info[idx] do
                        if info[idx][FLD_MEMBER_NAME] == name then
                            error(strformat("Usage: struct.AddMember(structure[, name], definition[, stack]) - There is a existed member with the name : %q", name), stack)
                        end
                        idx = idx + 1
                    end

                    local minfo = _Cache()
                    minfo[FLD_MEMBER_NAME] = name

                    attribute.ConsumeAttributes(minfo, ATTRIBUTE_TARGETS_MEMBER, target, name, stack + 1)

                    local smem  = nil

                    if info[FLD_STRUCT_BASE] and _StrtInfo[info[FLD_STRUCT_BASE]] then
                        local sinfo = _StrtInfo[info[FLD_STRUCT_BASE]]
                        local si    = FLD_STRUCT_MEMBERSTART
                        while sinfo[si] do
                            if sinfo[i][FLD_MEMBER_NAME] == name then
                                smem = sinfo[i][FLD_MEMBER_NAME]
                                break
                            end
                        end
                    end

                    attribute.ApplyAttributes(minfo, ATTRIBUTE_TARGETS_MEMBER, definition, target, name, smem)

                    for k, v in pairs, definition do
                        if type(k) == "string" then
                            k = strlower(k)

                            if k == "type" then
                                local tpValid = namespace.IsResourceType(v) and getmetatable(v).ValidateValue

                                if tpValid then
                                    minfo[FLD_MEMBER_TYPE] = v
                                    minfo[FLD_MEMBER_VALID] = tpValid
                                else
                                    error("Usage: struct.AddMember(structure[, name], definition[, stack]) - The member's type is not valid", stack)
                                end
                            elseif k == "require" and v then
                                minfo[FLD_MEMBER_REQUIRE]  = true
                            elseif k == "default" then
                                minfo[FLD_MEMBER_DEFAULT] = v
                            end
                        end
                    end

                    if minfo[FLD_MEMBER_REQUIRE] then
                        minfo[FLD_MEMBER_DEFAULT] = nil
                    elseif minfo[FLD_MEMBER_TYPE] then
                        if minfo[FLD_MEMBER_DEFAULT] ~= nil then
                            local valid, msg = minfo[FLD_MEMBER_VALID](minfo[FLD_MEMBER_TYPE], minfo[FLD_MEMBER_DEFAULT])
                            if valid ~= nil then
                                minfo[FLD_MEMBER_DEFAULT] = valid
                            elseif type(minfo[FLD_MEMBER_DEFAULT]) == "function" then
                                minfo[FLD_MEMBER_DEFTFACTORY] = true
                            else
                                error("Usage: struct.AddMember(structure[, name], definition[, stack]) - The default value is not valid", stack)
                            end
                        end
                        if minfo[FLD_MEMBER_DEFAULT] == nil then
                            minfo[FLD_MEMBER_DEFAULT] = getmetatable(minfo[FLD_MEMBER_TYPE]).GetDefault(minfo[FLD_MEMBER_TYPE])
                        end
                    end

                    info[idx] = minfo

                    attribute.ApplyAfterDefine(minfo, ATTRIBUTE_TARGETS_MEMBER, target, name)
                else
                    error("Usage: struct.AddMember(structure[, name], definition[, stack]) - The structure is not valid", stack)
                end
            end;

            ["AddMethod"]       = function(target, name, func, stack)
                local info, def = getEnumTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    if type(name) ~= "string" then error("Usage: struct.AddMethod(structure, name, func[, stack]) - The name must be a string", stack) end
                    name = strtrim(name)
                    if name == "" then error("Usage: Usage: struct.AddMethod(structure, name, func[, stack]) - The name can't be empty", stack) end
                    if type(func) ~= "function" then error("Usage: struct.AddMethod(structure, name, func[, stack]) - The func must be a function", stack) end

                    if not def and struct.GetMethod(target, name) then
                        error(strformat("Usage: struct.AddMethod(structure, name, func[, stack]) - The %s's definition is finished, the method can't be overridden", tostring(target)), stack)
                    end

                    attribute.ConsumeAttributes(func, ATTRIBUTE_TARGETS_METHOD, target, name, stack + 1)

                    local sfunc

                    if info[FLD_STRUCT_BASE] and not info[name] then
                        if not struct.IsStaticMethod(info[FLD_STRUCT_BASE], name) then
                            sfunc = struct.GetMethod(info[FLD_STRUCT_BASE], name)
                        end
                    end

                    func = attribute.ApplyAttributes(func, ATTRIBUTE_TARGETS_METHOD, nil, target, name, sfunc)

                    local hasMethod= false
                    if not def and info[FLD_STRUCT_TYPEMETHOD] then for k, v in pairs, info[FLD_STRUCT_TYPEMETHOD] do if v then hasMethod = true break end end end

                    if not info[name] then
                        info[FLD_STRUCT_TYPEMETHOD] = info[FLD_STRUCT_TYPEMETHOD] or _Cache()
                        info[FLD_STRUCT_TYPEMETHOD][name] = func
                    else
                        info[name]  = func
                    end

                    attribute.ApplyAfterDefine(func, ATTRIBUTE_TARGETS_METHOD, target, name)

                    if not def and not hasMethod then
                        -- Need re-generate validator
                        genStructValidator(info)
                    end
                else
                    error("Usage: struct.AddMethod(structure, name, func[, stack]) - The structure is not valid", stack)
                end
            end;

            ["BeginDefinition"] = function(target, stack)
                stack = type(stack) == "number" and stack or 2

                target          = struct.Validate(target)
                if not target then error("Usage: struct.BeginDefinition(structure[, stack]) - The structure not existed", stack) end

                local info      = _StrtInfo[target]

                if info and validateFlags(MOD_SEALED_STRUCT, info[FLD_STRUCT_MOD]) then error(strformat("Usage: struct.BeginDefinition(structure[, stack]) - The %s is sealed, can't be re-defined", tostring(target)), stack) end
                if _StructBuilderInfo[target] then error(strformat("Usage: struct.BeginDefinition(structure[, stack]) - The %s's definition has already begun", tostring(target)), stack) end

                _StructBuilderInfo[target] = {
                    [FLD_STRUCT_MOD ]   = 0,
                    [FLD_STRUCT_NAME]   = tostring(target),
                }

                attribute.ConsumeAttributes(target, ATTRIBUTE_TARGETS_STRUCT, nil, nil, stack + 1)
            end;

            ["EndDefinition"]   = function(target, stack)
                local ninfo     = _StructBuilderInfo[target]
                if not ninfo then return end

                stack = type(stack) == "number" and stack or 2

                attribute.ApplyAttributes(target, ATTRIBUTE_TARGETS_STRUCT, nil, nil, nil, ninfo[FLD_STRUCT_BASE])

                _StructBuilderInfo[target] = nil

                -- Install base struct's features
                if ninfo[FLD_STRUCT_BASE] then
                    -- Check conflict, some should be handled by the author
                    local binfo     = _StrtInfo[ninfo[FLD_STRUCT_BASE]]

                    if ninfo[FLD_STRUCT_ARRAY] then     -- Array
                        if not binfo[FLD_STRUCT_ARRAY] then
                            error(strformat("Usage: struct.EndDefinition(structure[, stack]) - The %s's base struct isn't an array structure", tostring(target)), stack)
                        end
                    elseif ninfo[FLD_STRUCT_MEMBERSTART] then -- Member
                        if binfo[FLD_STRUCT_ARRAY] then
                            error(strformat("Usage: struct.EndDefinition(structure[, stack]) - The %s's base struct can't be an array structure", tostring(target)), stack)
                        elseif binfo[FLD_STRUCT_MEMBERSTART] then
                            -- Try to keep the base struct's member order
                            local cache     = _Cache()
                            local idx       = FLD_STRUCT_MEMBERSTART
                            while ninfo[idx] do
                                tinsert(cache, ninfo[idx])
                                idx         = idx + 1
                            end

                            local memCnt    = #cache

                            idx             = FLD_STRUCT_MEMBERSTART
                            while binfo[idx] do
                                local name  = binfo[idx][FLD_MEMBER_NAME]
                                ninfo[idx]  = binfo[idx]

                                for k, v in pairs, cache do
                                    if name == v[FLD_MEMBER_NAME] then
                                        ninfo[idx]  = v
                                        cache[k]    = nil
                                        break
                                    end
                                end

                                idx         = idx + 1
                            end

                            for i = 1, memCnt do
                                if cache[i] then
                                    ninfo[idx]      = cache[i]
                                    idx             = idx + 1
                                end
                            end

                            _Cache(cache)
                        end
                    else                        -- Custom
                        if binfo[FLD_STRUCT_ARRAY] then
                            ninfo[FLD_STRUCT_ARRAY] = binfo[FLD_STRUCT_ARRAY]
                            ninfo[FLD_STRUCT_ARRVALID]= binfo[FLD_STRUCT_ARRVALID]
                        elseif binfo[FLD_STRUCT_MEMBERSTART] then
                            -- Share members
                            local idx = FLD_STRUCT_MEMBERSTART
                            while binfo[idx] do
                                ninfo[idx]  = binfo[idx]
                                idx         = idx + 1
                            end
                        end
                    end

                    -- Clone the validator and Initializer
                    local nvalid    = ninfo[FLD_STRUCT_VALIDSTART]
                    local ninit     = ninfo[FLD_STRUCT_INITSTART]

                    local idx       = FLD_STRUCT_VALIDSTART
                    while binfo[idx] do
                        ninfo[idx]  = binfo[idx]
                        idx         = idx + 1
                    end
                    ninfo[idx]      = nvalid

                    idx             = FLD_STRUCT_INITSTART
                    while binfo[idx] do
                        ninfo[idx]  = binfo[idx]
                        idx         = idx + 1
                    end
                    ninfo[idx]      = ninit

                    -- Clone the methods
                    if binfo[FLD_STRUCT_TYPEMETHOD] then
                        nobjmtd     = ninfo[FLD_STRUCT_TYPEMETHOD] or _Cache()

                        for k, v in pairs, binfo[FLD_STRUCT_TYPEMETHOD] do
                            if v and nobjmtd[k] == nil then
                                nobjmtd[k]  = v
                            end
                        end

                        if next(nobjmtd) then
                            ninfo[FLD_STRUCT_TYPEMETHOD] = nobjmtd
                        else
                            ninfo[FLD_STRUCT_TYPEMETHOD] = nil
                            _Cache(nobjmtd)
                        end
                    end
                end

                -- Generate error message
                if ninfo[FLD_STRUCT_MEMBERSTART] then
                    local args      = _Cache()
                    local idx       = FLD_STRUCT_MEMBERSTART
                    while ninfo[idx] do
                        tinsert(args, ninfo[idx][FLD_MEMBER_NAME])
                        idx         = idx + 1
                    end
                    ninfo[FLD_STRUCT_ERRMSG]  = strformat("Usage: %s(%s) - ", tostring(target), tblconcat(args, ", "))
                    _Cache(args)
                elseif ninfo[FLD_STRUCT_ARRAY] then
                    ninfo[FLD_STRUCT_ERRMSG]  = strformat("Usage: %s(...) - ", tostring(target))
                else
                    ninfo[FLD_STRUCT_ERRMSG]  = strformat("[%s]", tostring(target))
                end

                ninfo[FLD_STRUCT_VALIDCACHE]    = checkRepeatStructType(target, ninfo)

                updateStructDependence(target, ninfo)

                genStructValidator(ninfo)
                genStructConstructor(ninfo)

                -- Check the default value is it's custom struct
                if ninfo[FLD_STRUCT_DEFAULT] ~= nil then
                    local deft      = ninfo[FLD_STRUCT_DEFAULT]
                    ninfo[FLD_STRUCT_DEFAULT]  = nil

                    if not ninfo[FLD_STRUCT_ARRAY] and not ninfo[FLD_STRUCT_MEMBERSTART] then
                        local ret, msg = struct.ValidateValue(target, deft)
                        if not msg then ninfo[FLD_STRUCT_DEFAULT] = ret end
                    end
                end

                -- Save as new structure's info
                _StrtInfo[target]   = ninfo

                attribute.ApplyAfterDefine(target, ATTRIBUTE_TARGETS_STRUCT)

                -- Refresh structs depended on this
                if _DependenceMap[target] then
                    local cache = _Cache()
                    cache[target] = true
                    updateStructDepends(target, cache)
                    _Cache(cache)
                end

                return target
            end;

            ["GetArrayElement"] = function(target)
                local info      = getEnumTargetInfo(target)
                return info and info[FLD_STRUCT_ARRAY]
            end;

            ["GetBaseStruct"]   = function(target)
                local info      = getEnumTargetInfo(target)
                return info and info[FLD_STRUCT_BASE]
            end;

            ["GetDefault"]      = function(target)
                local info      = getEnumTargetInfo(target)
                return info and info[FLD_STRUCT_DEFAULT]
            end;

            ["GetMember"]       = function(target, name)
                local info      = getEnumTargetInfo(target)
                if info then
                    local idx   = FLD_STRUCT_MEMBERSTART
                    local minfo = info[idx]
                    while minfo do
                        if idx == name or minfo[FLD_MEMBER_NAME] == name then
                            return minfo[FLD_MEMBER_TYPE], minfo[FLD_MEMBER_DEFAULT], minfo[FLD_MEMBER_REQUIRE]
                        end
                        idx     = idx + 1
                        minfo   = info[idx]
                    end
                end
            end;

            ["GetMembers"]      = function(target, cache)
                local info      = getEnumTargetInfo(target)
                if info then
                    if cache then
                        cache   = type(cache) == "table" and wipe(cache) or {}
                        local i = FLD_STRUCT_MEMBERSTART
                        local m = info[i]
                        while m do
                            tinsert(cache, m[FLD_MEMBER_NAME])
                            i   = i + 1
                            m   = info[i]
                        end
                        return cache
                    else
                        return function(self, i)
                            i   = i and (i + 1) or FLD_STRUCT_MEMBERSTART
                            if info[i] then
                                return i, info[i][FLD_MEMBER_NAME]
                            end
                        end, target
                    end
                end
                if cache then
                    return type(cache) == "table" and cache or nil
                else
                    return fakefunc, target
                end
            end;

            ["GetMethod"]       = function(target, name)
                local info, def = getEnumTargetInfo(target)
                return info and type(name) == "string" and (info[name] or info[FLD_STRUCT_TYPEMETHOD] and info[FLD_STRUCT_TYPEMETHOD][name]) or nil
            end;

            ["GetObjectMethod"] = function(target, name)
                local info      = getEnumTargetInfo(target)
                return info and type(name) == "string" and info[FLD_STRUCT_TYPEMETHOD] and info[FLD_STRUCT_TYPEMETHOD][name] or nil
            end;

            ["GetStaticMethod"] = function(target, name)
                local info      = getEnumTargetInfo(target)
                return info and type(name) == "string" and info[name] or nil
            end;

            ["GetMethods"]      = function(target, cache)
                local info      = getEnumTargetInfo(target)
                if info then
                    local objm  = info[FLD_STRUCT_TYPEMETHOD]
                    if cache then
                        cache   = type(cache) == "table" and wipe(cache) or {}
                        if objm then for k, v in pairs, objm do cache[k] = v or info[k] end end
                        return cache
                    elseif objm then
                        return function(self, n)
                            local m, v = next(objm, n)
                            if m then return m, v or info[m] end
                        end, target
                    end
                end
                if cache then
                    return type(cache) == "table" and cache or nil
                else
                    return fakefunc, target
                end
            end;

            ["GetObjectMethods"]= function(target, cache)
                local info      = getEnumTargetInfo(target)
                if info then
                    local objm  = info[FLD_STRUCT_TYPEMETHOD]
                    if cache then
                        cache   = type(cache) == "table" and wipe(cache) or {}
                        for k, v in pairs, objm do if v then cache[k] = v end end
                        return cache
                    elseif objm then
                        return function(self, n)
                            local m, v = next(objm, n)
                            while m and not v do m, v = next(objm, m) end
                            return m, v
                        end, target
                    end
                end
                if cache then
                    return type(cache) == "table" and cache or nil
                else
                    return fakefunc, target
                end
            end;

            ["GetStaticMethods"]= function(target, cache)
                local info      = getEnumTargetInfo(target)
                if info then
                    local objm  = info[FLD_STRUCT_TYPEMETHOD]
                    if cache then
                        cache   = type(cache) == "table" and wipe(cache) or {}
                        for k, v in pairs, objm do if not v then cache[k] = info[k] end end
                        return cache
                    elseif objm then
                        return function(self, n)
                            local m, v = next(objm, n)
                            while m and v do m, v = next(objm, m) end
                            if m then return m, info[m] end
                        end, target
                    end
                end
                if cache then
                    return type(cache) == "table" and cache or nil
                else
                    return fakefunc, target
                end
            end;

            ["GetStructType"]   = function(target)
                local info      = getEnumTargetInfo(target)
                if info then
                    if info[FLD_STRUCT_ARRAY] then return STRUCT_TYPE_ARRAY end
                    if info[FLD_STRUCT_MEMBERSTART] then return STRUCT_TYPE_MEMBER end
                    return STRUCT_TYPE_CUSTOM
                end
            end;

            ["IsSubType"]       = function(target, base)
                if struct.Validate(base) then
                    while target do
                        if target == base then return true end
                        local i = getEnumTargetInfo(target)
                        target  = i and i[FLD_STRUCT_BASE]
                    end
                end
                return false
            end;

            ["IsSealed"]        = function(target)
                local info      = getEnumTargetInfo(target)
                return info and validateFlags(MOD_SEALED_STRUCT, info[FLD_STRUCT_MOD]) or false
            end;

            ["IsStaticMethod"]  = function(target, name)
                local info      = getEnumTargetInfo(target)
                return info and type(name) == "string" and info[name] and true or false
            end;

            ["SetArrayElement"] = function(target, eleType, stack)
                local info, def = getEnumTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    if not def then error(strformat("Usage: struct.SetArrayElement(structure, eleType[, stack]) - The %s's definition is finished", tostring(target)), stack) end

                    if info[FLD_STRUCT_MEMBERSTART] then error("Usage: struct.SetArrayElement(structure, eleType[, stack]) - The structure has member settings, can't set array element", stack) end

                    local tpValid   = namespace.IsResourceType(eleType) and getmetatable(eleType).ValidateValue
                    if not tpValid then error("Usage: struct.SetArrayElement(structure, eleType[, stack]) - The element type is not valid", stack) end

                    info[FLD_STRUCT_ARRAY]  = eleType
                    info[FLD_STRUCT_ARRVALID] = tpValid
                else
                    error("Usage: struct.SetArrayElement(structure, eleType[, stack]) - The structure is not valid", stack)
                end
            end;

            ["SetBaseStruct"]   = function(target, base, stack)
                local info, def = getEnumTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    if not def then error(strformat("Usage: struct.SetBaseStruct(structure, base) - The %s's definition is finished", tostring(target)), stack) end
                    if not struct.Validate(base) then error("Usage: struct.SetBaseStruct(structure, base) - The base must be a structure", stack) end
                    info[FLD_STRUCT_BASE] = base
                else
                    error("Usage: struct.SetBaseStruct(structure, base[, stack]) - The structure is not valid", stack)
                end
            end;

            ["SetDefault"]      = function(target, default, stack)
                local info, def = getEnumTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    if not def then error(strformat("Usage: struct.SetDefault(structure, default[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                    info[FLD_STRUCT_DEFAULT] = default
                else
                    error("Usage: struct.SetDefault(structure, default[, stack]) - The structure is not valid", stack)
                end
            end;

            ["SetValidator"]    = function(target, func, stack)
                local info, def = getEnumTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    if not def then error(strformat("Usage: struct.SetValidator(structure, validator[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                    if type(func) ~= "function" then error("Usage: struct.SetValidator(structure, validator) - The validator must be a function", stack) end
                    info[FLD_STRUCT_VALIDSTART] = func
                else
                    error("Usage: struct.SetValidator(structure, validator[, stack]) - The structure is not valid", stack)
                end
            end;

            ["SetInitializer"]  = function(target, func, stack)
                local info, def = getEnumTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    if not def then error(strformat("Usage: struct.SetInitializer(structure, initializer[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                    if type(func) ~= "function" then error("Usage: struct.SetInitializer(structure, initializer) - The initializer must be a function", stack) end
                    info[FLD_STRUCT_INITSTART] = func
                else
                    error("Usage: struct.SetInitializer(structure, initializer[, stack]) - The structure is not valid", stack)
                end
            end;

            ["SetSealed"]       = function(target, stack)
                local info      = getEnumTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    if not validateFlags(MOD_SEALED_STRUCT, info[FLD_STRUCT_MOD]) then
                        info[FLD_STRUCT_MOD] = turnOnFlags(MOD_SEALED_STRUCT, info[FLD_STRUCT_MOD])
                    end
                else
                    error("Usage: struct.SetSealed(structure[, stack]) - The structure is not valid", stack)
                end
            end;

            ["SetStaticMethod"] = function(target, name, stack)
                local info, def = getEnumTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    if type(name) ~= "string" then error("Usage: struct.SetStaticMethod(structure, name) - the name must be a string", stack) end
                    name = strtrim(name)
                    if name == "" then error("Usage: Usage: struct.SetStaticMethod(structure, name) - The name can't be empty", stack) end
                    if not def then error(strformat("Usage: struct.SetStaticMethod(structure, name) - The %s's definition is finished", tostring(target)), stack) end
                    if not (info[FLD_STRUCT_TYPEMETHOD] and info[FLD_STRUCT_TYPEMETHOD][name] ~= nil) then error(strformat("Usage: struct.SetStaticMethod(structure, name) - The %s has no method named %q", tostring(target), name), stack) end

                    if info[name] == nil then
                        info[name] = info[FLD_STRUCT_TYPEMETHOD][name]
                        info[FLD_STRUCT_TYPEMETHOD][name] = false
                    end
                else
                    error("Usage: struct.SetStaticMethod(structure, name[, stack]) - The structure is not valid", stack)
                end
            end;

            ["ValidateValue"]   = function(target, value, onlyValid, cache)
                local info  = _StrtInfo[target]
                if info then
                    if not cache and info[FLD_STRUCT_VALIDCACHE] then
                        cache = _Cache()
                        local ret, msg = info[FLD_STRUCT_VALID](info, value, onlyValid, cache)
                        for k, v in pairs, cache do cache[k] = nil _Cache(v) end _Cache(cache)
                        return ret, msg
                    else
                        return info[FLD_STRUCT_VALID](info, value, onlyValid, cache)
                    end
                else
                    error("Usage: struct.ValidateValue(structure, value[, onlyValid]) - The structure is not valid", 2)
                end
            end;

            -- Validate whether the value is a struct type
            ["Validate"]        = function(target)
                return getmetatable(target) == struct and target or nil
            end;
        },
        __newindex              = readOnly,
        __call                  = function(self, ...)
            local env, target, definition, keepenv, stack, visitor = GetTypeParams(struct, tstruct, ...)
            if not target then error("Usage: struct([env, ][name, ][definition, ][keepenv, ][stack]) - the struct type can't be created", stack) end

            struct.BeginDefinition(target, stack + 1)

            local tarenv = prototype.NewObject(structbuilder)
            environment.SetNameSpace(tarenv, target)
            environment.SetParent(tarenv, env)
            environment.ToggleDefineMode(tarenv, true)

            _StructBuilderInDefine[tarenv] = true

            if definition then
                tarenv(definition, stack + 1)
                return target
            else
                if not keepenv then setfenv(stack, tarenv) end
                return tarenv
            end
        end,
    }

    tstruct                     = prototype "tstruct" (tnamespace, {
        __index                 = function(self, name)
            if type(name) == "string" then
                local info  = _StrtInfo[self]
                return info and (info[name] or info[FLD_STRUCT_TYPEMETHOD] and info[FLD_STRUCT_TYPEMETHOD][name]) or namespace.GetNameSpace(self, name)
            end
        end,
        __newindex              = function(self, key, value)
            if type(key) == "string" and type(value) == "function" then
                struct.AddMethod(self, key, value, 3)
                return
            end
            error("The struct type is readonly", 2)
        end,
        __call                  = function(self, ...)
            local info  = _StrtInfo[self]
            local ret   = info[FLD_STRUCT_CTOR](info, ...)
            return ret
        end,
        __metatable             = struct,
    })

    structbuilder               = prototype "structbuilder" {
        __index                 = function(self, key)
            local newMethod     = rawget(self, STRUCT_BUILDER_NEWMTD)
            return newMethod and newMethod[key] and struct.GetMethod(environment.GetNameSpace(self), key) or environment.GetValue(self, key)
        end,
        __newindex              = function(self, key, value)
            if not setStructBuilderValue(self, key, value, 3) then
                return rawset(self, key, value)
            end
        end,
        __call                  = function(self, ...)
            local definition, stack = GetDefinitionParams(self, ...)
            if not definition then error("Usage: struct([env, ][name, ][stack]) (definition) - the definition is missing", stack) end

            local owner = environment.GetNameSpace(self)
            if not (owner and _StructBuilderInDefine[self] and _StructBuilderInfo[owner]) then error("The struct's definition is finished", stack) end

            stack = stack + 1

            if type(definition) == "function" then
                definition(self)
            else
                -- Check base struct first
                if definition[STRUCT_KEYWORD_BASE] ~= nil then
                    setStructBuilderValue(self, STRUCT_KEYWORD_BASE, definition[STRUCT_KEYWORD_BASE], stack, true)
                    definition[STRUCT_KEYWORD_BASE] = nil
                end

                -- Index key
                for i, v in ipairs, definition, 0 do
                    setStructBuilderValue(self, i, v, stack, true)
                end

                for k, v in pairs, definition do
                    if type(k) == "string" then
                        setStructBuilderValue(self, k, v, stack, true)
                    end
                end
            end

            struct.EndDefinition(owner, stack)

            _StructBuilderInDefine[self]    = nil
            environment.ToggleDefineMode(self, false)

            local newMethod     = rawget(self, STRUCT_BUILDER_NEWMTD)
            if newMethod then
                for k in pairs(newMethod) do
                    rawset(self, k, struct.GetMethod(owner, k))
                end
                rawset(self, STRUCT_BUILDER_NEWMTD, nil)
            end

            setfenv(stack - 1, environment.GetParent(self) or _G)

            return owner
        end,
    }

    -- Key feature : member "Name" { Type = String, Default = "Anonymous", Require = false}
    member                      = prototype "member" {
        __index                 = writeOnly,
        __newindex              = readOnly,
        __call                  = function(self, ...)
            if self == member then
                local env, name, definition, flag, stack, keyvisitor = GetFeatureParams(member, ...)
                local owner = keyvisitor and environment.GetNameSpace(keyvisitor)
                if not owner or not keyvisitor then error([[Usage: member "name" {...} - can't be used here.]], stack) end
                if type(name) ~= "string" then error([[Usage: member "name" {...} - the name must be a string.]], stack) end
                name = strtrim(name)
                if name == "" then error([[Usage: member "name" {...} - the name can't be an empty string.]], stack) end

                if definition then
                    if type(definition) ~= "table" then error([[Usage: member ("name", {...}) - the definition must be a table.]], stack) end
                    struct.AddMember(owner, name, definition, stack + 1)
                else
                    return prototype.NewObject(member, { name = name, owner = owner })
                end
            else
                local owner, name       = self.owner, self.name
                local definition, stack = GetDefinitionParams(self, ...)

                if type(name) ~= "string" then error([[Usage: member "name" {...} - the name must be a string.]], stack) end
                name = strtrim(name)
                if name == "" then error([[Usage: member "name" {...} - the name can't be an empty string.]], stack) end
                if type(definition) ~= "table" then error([[Usage: member ("name", {...}) - the definition must be a table.]], stack) end

                struct.AddMember(owner, name, definition, stack + 1)
            end
        end,
    }

    -- Key feature : endstruct "Number"
    endstruct                   = function (...)
        local env, name, definition, flag, stack, keyvisitor = GetFeatureParams(endstruct, ...)
        local owner = keyvisitor and environment.GetNameSpace(keyvisitor)

        if not owner or not keyvisitor then error([[Usage: endstruct "name" - can't be used here.]], stack) end
        if namespace.GetNameSpaceName(owner, true) ~= name then error(strformat("%s's definition isn't finished", tostring(owner)), stack) end

        struct.EndDefinition(owner, stack + 1)

        _StructBuilderInDefine[keyvisitor]  = nil
        environment.ToggleDefineMode(keyvisitor, false)

        local newMethod     = rawget(keyvisitor, STRUCT_BUILDER_NEWMTD)
        if newMethod then
            for k in pairs(newMethod) do
                rawset(keyvisitor, k, struct.GetMethod(owner, k))
            end
            rawset(keyvisitor, STRUCT_BUILDER_NEWMTD, nil)
        end

        local baseEnv       = environment.GetParent(keyvisitor) or _G

        setfenv(stack, baseEnv)

        return baseEnv
    end
end

-------------------------------------------------------------------------------
--                             interface & class                             --
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                         attribute targets                         --
    -----------------------------------------------------------------------
    ATTRIBUTE_TARGETS_INTERFACE = attribute.RegisterTargetType("Interface")
    ATTRIBUTE_TARGETS_CLASS     = attribute.RegisterTargetType("Class")
    ATTRIBUTE_TARGETS_METHOD    = attribute.RegisterTargetType("Method")
    ATTRIBUTE_TARGETS_METAMETHOD= attribute.RegisterTargetType("Metamethod")
    ATTRIBUTE_TARGETS_CTOR      = attribute.RegisterTargetType("Constructor")

    -----------------------------------------------------------------------
    --                         private variables                         --
    -----------------------------------------------------------------------
    local _ICInfo   = setmetatable({}, WEAK_KEY)        -- INTERFACE & CLASS INFO
    local _BDInfo   = setmetatable({}, WEAK_KEY)        -- TYPE BUILDER INFO
    local _CLDInfo  = {}                                -- CHILDREN MAP
    local _ThisMap  = setmetatable({}, WEAK_ALL)        -- THIS  -> CLASS
    local _SuperMap = setmetatable({}, WEAK_ALL)        -- SUPER -> CLASS | INTERFACE

    local _IndexMap = {}
    local _NewIdxMap= {}
    local _CtorMap  = {}

    local _InDef    = setmetatable({}, WEAK_KEY)

    -- FEATURE MODIFIER
    local MD_SEAL   = 2^0           -- SEALED TYPE
    local MD_FINAL  = 2^1           -- FINAL TYPE
    local MD_ABSCLS = 2^2           -- ABSTRACT CLASS
    local MD_ATCACHE= 2^3           -- AUTO CACHE CLASS
    local MD_OBJMDAT= 2^4           -- ENABLE OBJECT METHOD ATTRIBUTE
    local MD_NRAWSET= 2^5           -- NO RAW SET FOR OBJECTS
    local MD_ASSPCLS= 2^6           -- AS A SIMPLE CLASS
    local MD_SIMPVER= 2^7           -- SIMPLE VERSION CLASS - NO VERSION CONTROL
    local MD_ODSUPER= 2^8           -- OLD SUPER STYLE
    local MD_THDSAFE= 2^9           --  @todo: THREAD SAFE, can't be all controlled by the system

    local MD_INITVAL= (function()
        local v
        if PLOOP_PLATFORM_SETTINGS.CLASS_ALL_SIMPLE_VERSION then
            v = turnOnFlags(0, MD_SIMPVER)
        end
        if PLOOP_PLATFORM_SETTINGS.CLASS_ALL_OLD_SUPER_STYLE then
            return turnOnFlags(v or 0, MD_ODSUPER)
        end
    end)()

    -- FIELDS
    local FD_MOD    = -1            -- FIELD MODIFIER
    local FD_SUPCLS =  0            -- FIELD SUPER CLASS
    local FD_STEXT  =  1            -- FIELD EXTEND INTERFACE START INDEX(keep 1 so we can use unpack on it)
    local FD_INIT   = -2            -- FIELD INITIALIZER
    local FD_DISPOSE= -3            -- FIELD DISPOSE
    local FD_TYPFTR = -4            -- FILED TYPE FEATURES
    local FD_TYPMTD = -5            -- FIELD TYPE METHODS
    local FD_TYPMTM = -6            -- FIELD TYPE META-METHODS
    local FD_INHRTP = -7            -- FIELD INHERITANCE PRIORITY
    local FD_STAFTR = -8            -- FIELD STATIC TYPE FEATURES
    local FD_OBJFTR = -9            -- FIELD OBJECT FEATURES
    local FD_OBJMTD =-10            -- FIELD OBJECT METHODS
    local FD_OBJMTM =-11            -- FIELD OBJECT META-METHODS
    local FD_REQCLS =-12            -- FIELD REQUIR CLASS FOR INTERFACE
    local FD_ONEVRM =-13            -- FIELD WHETHER ONE VIRTUAL-METHOD INTERFACE
    local FD_ANYMSCL=-14            -- FIELD ANONYMOUS CLASS FOR INTERFACE
    local FD_SIMPCLS=-15            -- FIELD CLASS IS A SIMPLE CLASS
    local FD_SUPINFO=-16            -- FIELD INFO CACHE FOR SUPER CLASS & EXTEND INTERFACES
    local FD_SUPCACH=-17            -- FIELD SUPER CACHE
    local FD_NEWFTR =-18            -- FIELD TYPE NEW FEATURES

    -- Ctor & Dispose
    local FD_CTOR   = 10^4          -- FIELD THE CONSTRUCTOR
    local FD_CLINIT = FD_CTOR + 1   -- FEILD THE CLASS INITIALIZER
    local FD_ENDISP = FD_CTOR - 1   -- FIELD ALL EXTEND INTERFACE DISPOSE END INDEX
    local FD_STINIT = FD_CLINIT + 1 -- FIELD ALL EXTEND INTERFACE INITIALIZER START INDEX

    -- Inheritance priority
    local IP_FINAL  =  1
    local IP_NORMAL =  0
    local IP_VIRTUAL= -1

    -- Flags for object accessing
    local FL_OBJMTD = 2^0           -- HAS OBJECT METHOD
    local FL_OBJFTR = 2^1           -- HAS OBJECT FEATURE
    local FL_ATCACH = 2^2           -- IS  AUTO CACHE
    local FL_IDXFUN = 2^3           -- HAS INDEX FUNCTION
    local FL_IDXTBL = 2^4           -- HAS INDEX TABLE
    local FL_NEWIDX = 2^5           -- HAS NEW INDEX
    local FL_OBJATR = 2^6           -- ENABLE OBJECT METHOD ATTRIBUTE
    local FL_NRAWST = 2^7           -- ENABLE NO RAW SET
    local FL_SUPACC = 2^8           -- HAS SUPER METHOD OR FEATURE
    local FL_TDSAFE = 2^9           -- THREAD SAFE

    -- Flags for constructor
    local FL_EXTOBJ = 2^2           -- HAS __exist
    local FL_NEWOBJ = 2^3           -- HAS __new
    local FL_SIMCLS = 2^4           -- SIMPLE CLASS
    local FL_ASSIMP = 2^5           -- AS SIMPLE CLASS
    local FL_HSCLIN = 2^6           -- HAS CLASS INITIALIZER
    local FL_HASIFS = 2^7           -- NEED CALL INTERFACE'S INITIALIZER

    -- Meta-Methods
    local MTD_EXIST = "__exist"
    local MTD_NEW   = "__new"
    local MTD_INDEX = "__index"
    local MTD_NEWIDX= "__newindex"
    local MTD_META  = "__metatable"

    -- Dispose Method
    local MTD_DISPOB= "Dispose"

    -- Super & This
    local AL_SUPER  = "Super"
    local AL_THIS   = "This"
    local SP_ACCESS = "__PLOOP_SUPER_ACCESS"

    -- Type Builder
    local BFD_NMTD  = "__PLOOP_BD_NEWMTD"

    local META_KEYS = {
        __add       = "__add",      -- a + b
        __sub       = "__sub",      -- a - b
        __mul       = "__mul",      -- a * b
        __div       = "__div",      -- a / b
        __mod       = "__mod",      -- a % b
        __pow       = "__pow",      -- a ^ b
        __unm       = "__unm",      -- - a
        __idiv      = "__idiv",     -- // floor division
        __band      = "__band",     -- & bitwise and
        __bor       = "__bor",      -- | bitwise or
        __bxor      = "__bxor",     -- ~ bitwise exclusive or
        __bnot      = "__bnot",     -- ~ bitwise unary not
        __shl       = "__shl",      -- << bitwise left shift
        __shr       = "__shr",      -- >> bitwise right shift
        __concat    = "__concat",   -- a..b
        __len       = "__len",      -- #a
        __eq        = "__eq",       -- a == b
        __lt        = "__lt",       -- a < b
        __le        = "__le",       -- a <= b
        __index     = "___index",   -- return a[b]
        __newindex  = "___newindex",-- a[b] = v
        __call      = "__call",     -- a()
        __gc        = "__gc",       -- dispose a
        __tostring  = "__tostring", -- tostring(a)
        __ipairs    = "__ipairs",   -- ipairs(a)
        __pairs     = "__pairs",    -- pairs(a)

        -- Ploop only meta-methods
        __exist     = "__exist",    -- return object if existed
        __new       = "__new",      -- return a raw table as the object
    }

    -- Helpers
    local function getTargetInfo(target)
        local info  = _BDInfo[target]
        if info then return info, true else return _ICInfo[target], false end
    end

    local function getSuperInfo(info, target)
        return info[FD_SUPINFO] and info[FD_SUPINFO][target] or _BDInfo[target] or _ICInfo[target]
    end

    local function getSuperInfoIter(info, reverse)
        if reverse then
            if info[FD_SUPCLS] then
                local scache    = _Cache()
                local scls      = info[FD_SUPCLS]
                while scls do
                    tinsert(scache, scls)
                    scls        = getSuperInfo(info, scls)[FD_SUPCLS]
                end

                local scnt      = #scache - FD_STEXT + 1
                return function(root, idx)
                    if idx >= FD_STEXT then
                        local extif = root[idx]
                        return idx - 1, getSuperInfo(info, extif), extif
                    elseif scnt + idx > 0 then
                        local scls  = scache[scnt + idx]
                        return idx - 1, getSuperInfo(info, scls), scls
                    end
                    _Cache(scache)
                end, info, #info
            else
                return function(root, idx)
                    if idx >= FD_STEXT then
                        local extif = root[idx]
                        return idx - 1, getSuperInfo(info, extif), extif
                    end
                end, info, #info
            end
        else
            return function(root, idx)
                if type(idx) == "table" then
                    local scls  = idx[FD_SUPCLS]
                    if scls then
                        idx     = getSuperInfo(info, scls)
                        return idx, idx, scls
                    end
                    idx         = FD_STEXT - 1
                end
                idx             = idx + 1
                local extif     = root[idx]
                if extif then return idx, getSuperInfo(info, extif), extif end
            end, info, info
        end
    end

    local function getSuperOnPriority(info, name, get)
        local minpriority, norpriority
        for _, sinfo in getSuperInfoIter(info) do
            local m = get(sinfo, name)
            if m then
                local priority = sinfo[FD_INHRTP] and sinfo[FD_INHRTP][name] or IP_NORMAL
                if priority == IP_FINAL   then return m, IP_FINAL end
                if priority == IP_VIRTUAL then
                    minpriority = minpriority or m
                else
                    norpriority = norpriority or m
                end
            end
        end
        if norpriority then
            return norpriority, IP_NORMAL
        elseif minpriority then
            return minpriority, IP_VIRTUAL
        end
    end

    local function getTypeMethod(info, name)
        return info[FD_TYPMTD] and info[FD_TYPMTD][name]
    end

    local function getTypeFeature(info, name)
        return info[FD_TYPFTR] and info[FD_TYPFTR][name]
    end

    local function getTypeMetaMethod(info, name)
        return info[FD_TYPMTM] and info[FD_TYPMTM][META_KEYS[name]]
    end

    local function getSuperMethod(info, name)
        return getSuperOnPriority(info, name, getTypeMethod)
    end

    local function getSuperFeature(info, name, ftype)
        local feature, priority = getSuperOnPriority(info, name, getTypeFeature)
        return feature and (not ftype and feature or ftype.Validate(feature)) or nil, priority
    end

    local function getSuperMetaMethod(info, name)
        return getSuperOnPriority(info, name, getTypeMetaMethod)
    end

    -- Type Building
    local function generateSuperInfo(info, lst, cache)
        if info then
            local scls      = info[FD_SUPCLS]
            if scls then
                local sinfo = getTargetInfo(scls)
                generateSuperInfo(sinfo, lst, cache)
                if cache then cache[scls] = sinfo end
            end

            for i = #info, FD_STEXT, -1 do
                local extif = info[i]
                if not lst[extif] then
                    lst[extif]  = true

                    local sinfo = getTargetInfo(extif)
                    generateSuperInfo(sinfo, lst, cache)
                    if cache then cache[extif] = sinfo end
                    tinsert(lst, extif)
                end
            end
        end

        return lst, cache
    end

    local function generateCacheOnPriority(source, target, objpri, inhrtp, super)
        for k, v in pairs, source do
            if v then
                local priority  = inhrtp and inhrtp[k] or IP_NORMAL
                if priority >= (objpri[k] or IP_VIRTUAL) then
                    if super and target[k] and not super[k] then
                        super[k]= target[k]
                    end

                    objpri[k]   = priority
                    target[k]   = v
                end
            end
        end
    end

    local function generateMetaIndex(info)
        local token = 0
        local upval = _Cache()
        local meta  = info[FD_OBJMTM]

        if validateFlags(MD_ATCACHE, info[FD_MOD]) then
            token   = turnOnFlags(FL_ATCACH, token)
        end

        if info[FD_OBJFTR] and next(info[FD_OBJFTR]) then
            token   = turnOnFlags(FL_OBJFTR, token)
            tinsert(upval, info[FD_OBJFTR])
        end

        if info[FD_OBJMTD] and next(info[FD_OBJMTD]) then
            token   = turnOnFlags(FL_OBJMTD, token)
            tinsert(upval, info[FD_OBJMTD])
        end

        if meta[MTD_INDEX] then
            if type(meta[MTD_INDEX]) == "function" then
                token = turnOnFlags(FL_IDXFUN, token)
            else
                token = turnOnFlags(FL_IDXTBL, token)
            end
            tinsert(upval, meta[MTD_INDEX])
        end

        -- No __index generated
        if token == 0                               then meta[MTD_INDEX] = nil      return _Cache(upval) end
        -- Use the object method cache directly
        if token == FL_OBJMTD                       then meta[MTD_INDEX] = objmtd   return _Cache(upval) end
        -- Use the custom __index directly
        if token == FL_IDXFUN or token == FL_IDXTBL then                            return _Cache(upval) end

        if not _IndexMap[token] then
            local header    = _Cache()
            local body      = _Cache()

            tinsert(body, "")   -- Remain for closure values
            tinsert(body, [[return function(self, key)]])

            if validateFlags(FL_OBJFTR, token) then
                tinsert(header, "features")
                tinsert(body, [[
                    local ftr = features[key]
                    if ftr then return ftr:Get(self) end
                ]])
            end

            if validateFlags(FL_OBJMTD, token) then
                tinsert(header, "methods")
                tinsert(body, [[
                    local mtd = methods[key]
                    if mtd then
                ]])
                if validateFlags(FL_ATCACH, token) then
                    tinsert(body, [[rawset(self, key, mtd)]])
                end
                tinsert(body, [[
                        return mtd
                    end
                ]])
            end


            if validateFlags(FL_IDXFUN, token) then
                tinsert(header, "_index")
                tinsert(body, [[return _index(self, key)]])
            elseif validateFlags(FL_IDXTBL, token) then
                tinsert(header, "_index")
                tinsert(body, [[return _index[key] ]])
            end

            tinsert(body, [[end]])

            if #header > 0 then
                body[1] = "local " .. tblconcat(header, ",") .. "= ..."
            end

            _IndexMap[token] = loadSnippet(tblconcat(body, "\n"), "Class_Index_" .. token)

            _Cache(header)
            _Cache(body)
        end

        meta[MTD_INDEX] = _IndexMap[token](unpack(upval))
        _Cache(upval)
    end

    local function generateMetaNewIndex(info)
        local token = 0
        local upval = _Cache()
        local meta  = info[FD_OBJMTM]

        if validateFlags(MD_OBJMDAT, info[FD_MOD]) then
            token   = turnOnFlags(FL_OBJATR, token)
        end

        if validateFlags(MD_NRAWSET, info[FD_MOD]) then
            token   = turnOnFlags(FL_NRAWST, token)
        end

        if info[FD_OBJFTR] and next(info[FD_OBJFTR]) then
            token   = turnOnFlags(FL_OBJFTR, token)
            tinsert(upval, info[FD_OBJFTR])
        end

        if meta[MTD_NEWIDX] then
            token   = turnOnFlags(FL_NEWIDX, token)
            tinsert(upval, meta[MTD_NEWIDX])
        end

        -- No __newindex generated
        if token == 0         then meta[MTD_NEWIDX] = nil   return _Cache(upval) end
        -- Use the custom __newindex directly
        if token == FL_NEWIDX then                          return _Cache(upval) end

        if not _NewIdxMap[token] then
            local header    = _Cache()
            local body      = _Cache()

            tinsert(body, "")   -- Remain for closure values
            tinsert(body, [[return function(self, key, value)]])

            if validateFlags(FL_OBJFTR, token) then
                tinsert(header, "feature")
                tinsert(body, [[
                    local ftr = feature[key]
                    if ftr then ftr:Set(self, value, 3) return end
                ]])
            end

            if validateFlags(FL_NEWIDX, token) or not validateFlags(FL_NRAWST, token) then
                if validateFlags(FL_OBJATR, token) then
                    tinsert(body, [[
                        if type(value) == "function" then
                            attribute.ConsumeAttributes(value, ATTRIBUTE_TARGETS_FUNCTION, self, name, 3)
                            value = attribute.ApplyAttributes(value, ATTRIBUTE_TARGETS_FUNCTION, nil, self, name)
                        end
                    ]])
                end

                if validateFlags(FL_NEWIDX, token) then
                    tinsert(header, "_newindex")
                    tinsert(body, [[_newindex(self, key, value)]])
                else
                    tinsert(body, [[rawset(self, key, value)]])
                end

                if validateFlags(FL_OBJATR, token) then
                    tinsert(body, [[)
                        if type(value) == "function" then
                            attribute.ApplyAfterDefine(value, ATTRIBUTE_TARGETS_FUNCTION, self, name)
                        end
                    ]])
                end
            else
                tinsert(body, [[error("The object is readonly", 2)]])
            end

            tinsert(body, [[end]])

            if #header > 0 then
                body[1] = "local " .. tblconcat(header, ",") .. "= ..."
            end

            _NewIdxMap[token] = loadSnippet(tblconcat(body, "\n"), "Class_NewIndex_" .. token)

            _Cache(header)
            _Cache(body)
        end

        meta[MTD_NEWIDX] = _NewIdxMap[token](unpack(upval))
        _Cache(upval)
    end

    local function loadInitTable(obj, initTable)
        for name, value in pairs(initTable) do obj[name] = value end
    end

    local function generateConstructor(target, info)
        local token = 0
        local upval = _Cache()
        local meta  = info[FD_OBJMTM]

        if validateFlags(MD_ABSCLS, info[FD_MOD]) then
            local msg = strformat("The %s is abstract, can't be used to create objects", tostring(target))
            info[FD_CTOR] = function() error(msg, 3) end
            return _Cache(upval)
        end

        tinsert(upval, info)
        tinsert(upval, meta)
        tinsert(upval, target)

        if meta[MTD_EXIST] then
            token   = turnOnFlags(FL_EXTOBJ, token)
            tinsert(upval, meta[MTD_EXIST])
        end

        if meta[MTD_NEW] then
            token   = turnOnFlags(FL_NEWOBJ, token)
            tinsert(upval, meta[MTD_NEW])
        end

        if info[FD_SIMPCLS] then
            token   = turnOnFlags(FL_SIMCLS, token)
        elseif validateFlags(MD_ASSPCLS, info[FD_MOD]) then
            token   = turnOnFlags(FL_ASSIMP, token)

            if info[FD_OBJFTR] and next(info[FD_OBJFTR]) then
                token   = turnOnFlags(FL_OBJFTR, token)
                tinsert(upval, info[FD_OBJFTR])
            end
        end

        if info[FD_CLINIT] then
            token   = turnOnFlags(FL_HSCLIN, token)
            tinsert(upval, info[FD_CLINIT])
        else
            tinsert(upval, loadInitTable)
        end

        if info[FD_STINIT] then
            token   = turnOnFlags(FL_HASIFS, token)
            local i = FD_STINIT
            while info[i + 1] do i = i + 1 end
            tinsert(upval, i)
        end

        if not _CtorMap[token] then
            local header    = _Cache()
            local body      = _Cache()

            tinsert(header, "_info")
            tinsert(header, "_meta")
            tinsert(header, "_class")

            tinsert(body, "")   -- Remain for closure values
            tinsert(body, [[return function(...)]])

            tinsert(body, [[local obj]])

            if validateFlags(FL_EXTOBJ, token) then
                tinsert(header, "_exist")

                tinsert(body, [[
                    obj = _exist(...)
                    if obj then
                        local cls = getmetatable(obj)
                        if cls == _class or class.IsSubType(cls, _class) then
                            return obj
                        end
                    end
                ]])
            end

            if validateFlags(FL_NEWOBJ, token) then
                tinsert(header, "_new")

                tinsert(body, [[
                    obj = _new(...)
                    if type(obj) == "table" then
                        local ok, ret = pcall(setmetatable, obj, _meta)
                        if not ok then error(strformat("The %s's __new meta-method doesn't provide a valid table as object", tostring(_class)), 3) end
                    else
                        obj = nil
                    end
                ]])
            end

            if validateFlags(FL_SIMCLS, token) or validateFlags(FL_ASSIMP, token) or not validateFlags(FL_HSCLIN, token) then
                tinsert(body, [[
                    local init = nil
                    if select("#", ...) == 1 then
                        init = select(1, ...)
                        if type(init) == "table" and getmetatable(init) == nil then
                            if not obj then
                ]])

                if validateFlags(FL_SIMCLS, token) then
                    tinsert(body, [[obj = setmetatable(init, _meta) init = false]])
                elseif validateFlags(FL_ASSIMP, token) then
                    tinsert(body, [[local noconflict = true]])

                    if validateFlags(FL_OBJFTR, token) then
                        tinsert(header, "_ftr")
                        tinsert(body, [[
                            for k in pairs, _ftr do
                                if init[k] ~= nil then
                                    noconflict = false break
                                end
                            end
                        ]])
                    end

                    tinsert(body, [[if noconflict then obj = setmetatable(init, _meta) init = false end]])
                end

                tinsert(body, [[
                            end
                        else
                            init = nil
                        end
                    end
                ]])
            end

            tinsert(body, [[obj = obj or setmetatable({}, _meta)]])

            if validateFlags(FL_HSCLIN, token) then
                tinsert(header, "_ctor")

                if validateFlags(FL_SIMCLS, token) or validateFlags(FL_ASSIMP, token) then
                    tinsert(body, [[
                        if init == false then
                            _ctor(obj)
                        else
                            _ctor(obj, ...)
                        end
                    ]])
                else
                    tinsert(body, [[_ctor(obj, ...)]])
                end
            else
                tinsert(header, "_loadInitTable")

                tinsert(body, [[
                    if init then
                        local ok, msg = pcall(_loadInitTable, obj, init)
                        if not ok then error(strmatch(msg, "%d+:%s*(.-)$") or msg, 3) end
                    end
                ]])
            end

            if validateFlags(FL_HASIFS, token) then
                tinsert(header, "_max")

                tinsert(body, [[
                    for i = ]] .. FD_STINIT .. [[, _max do
                        _info[i](obj)
                    end
                ]])
            end

            tinsert(body, [[
                    return obj
                end
            ]])

            if #header > 0 then
                body[1] = "local " .. tblconcat(header, ",") .. "= ..."
            end

            _CtorMap[token] = loadSnippet(tblconcat(body, "\n"), "Class_Ctor_" .. token)

            _Cache(header)
            _Cache(body)
        end

        info[FD_CTOR] = _CtorMap[token](unpack(upval))
        _Cache(upval)
    end

    local function generateTypeCaches(target, info)
        local objpri    = _Cache()
        local objmeta   = _Cache()
        local objftr    = _Cache()
        local objmtd    = _Cache()
        local super     = _Cache()

        for _, sinfo in getSuperInfoIter(info, true) do
            local inhrtp= sinfo[FD_INHRTP]

            if sinfo[FD_TYPMTM] then
                generateCacheOnPriority(sinfo[FD_TYPMTM], objmeta, objpri, inhrtp)
            end

            if sinfo[FD_TYPFTR] then
                generateCacheOnPriority(sinfo[FD_TYPFTR], objftr, objpri, inhrtp)
            end

            if sinfo[FD_TYPMTD] then
                generateCacheOnPriority(sinfo[FD_TYPMTD], objmtd, objpri, inhrtp)
            end
        end

        local inhrtp    = info[FD_INHRTP]
        if info[FD_TYPMTM] then
            generateCacheOnPriority(info[FD_TYPMTM], objmeta, objpri, inhrtp, super)
        end

        if info[FD_TYPFTR] then
            generateCacheOnPriority(info[FD_TYPFTR], objftr, objpri, inhrtp, super)
        end

        if info[FD_TYPMTD] then
           generateCacheOnPriority(info[FD_TYPMTD], objmtd, objpri, inhrtp, super)
        end

        if interface.Validate(target) then
            -- Check one virtual method
            local onevtm
            for k, v in pairs, objmtd do
                if objpri[k] == IP_VIRTUAL then
                    if not onevtm then
                        onevtm  = k
                    else
                        onevtm  = false
                        break
                    end
                end
            end
            info[FD_ONEVRM] = onevtm or nil
        else
            if not validateFlags(MD_ABSCLS, info[FD_MOD]) then
                objmeta[MTD_META]   = target

                info[FD_OBJMTM]     = objmeta
                info[FD_OBJFTR]     = objftr
                info[FD_OBJMTD]     = objmtd

                generateMetaIndex(info)
                generateMetaNewIndex(info)
            end
            generateConstructor(target, info)
        end

        if next(super) then
            info[FD_SUPCACH]    = super
        else
            _Cache(super)
        end
    end

    local function endDefinitionForNewFeatures(target, stack)
        local info = getTargetInfo(target)

        if info[FD_NEWFTR] then
            info[FD_TYPFTR] = info[FD_TYPFTR] or _Cache()

            for name, ftr in pairs, info[FD_NEWFTR] do
                getmetatable(ftr).EndDefinition(ftr, target, name, stack + 1)
            end

            _Cache(info[FD_NEWFTR])
            info[FD_NEWFTR] = nil
        end
    end

    -- Shared APIS
    local function checkInfoWithName(tType, target, name, allowDefined)
        local info, def = getTargetInfo(target)
        if not info then return nil, nil, strformat("The %s is not valid", tostring(tType)) end
        if not allowDefined and not def then return nil, nil, strformat("The %s's definition is finished", tostring(target)) end
        if not name or type(name) ~= "string" then return info, nil, "The name must be a string." end
        name = strtrim(name)
        if name == "" then return info, nil, "The name can't be empty." end
        return info, name, nil, def
    end

    local function reDefineChildren(target, stack)
        if _CLDInfo[target] then
            for _, child in ipairs, _CLDInfo[target], 0 do
                if not _BDInfo[child] then  -- Not in defintion mode
                    if interface.Validate(child) then
                        interface.RefreshDefinition(child, stack + 1)
                    else
                        class.RefreshDefinition(child, stack + 1)
                    end
                end
            end
        end
    end

    local function beginDefinition(target, stack)
        if not _BDInfo[0] then
            Lock(interface)
            _BDInfo[0] = target
            return true
        end
        return false
    end

    local function endDefinition(target, stack, noChildUpdate)
        -- Update children
        if not noChildUpdate then reDefineChildren(target, stack + 1) end

        if _BDInfo[0] == target then
            _BDInfo[0] = nil
            Release(interface)
        end
    end

    local function addSuperType(info, target, supType)
        local isIF          = interface.Validate(supType)

        -- Clear _CLDInfo for old extend interfaces
        for i = #info, FD_STEXT, -1 do
            local extif     = info[i]

            if interface.IsSubType(supType, extif) then
                for k, v in ipairs, _CLDInfo[extif], 0 do
                    if v == target then tremove(_CLDInfo[extif], k) break end
                end
            end

            if isIF then info[i + 1] = extif end
        end

        if isIF then
            info[FD_STEXT]  = supType
        else
            info[FD_SUPCLS] = supType
        end

        -- Register the _CLDInfo
        _CLDInfo[supType]   = _CLDInfo[supType] or {}
        tinsert(_CLDInfo[supType], target)

        -- Re-generate the interface order list
        local lstIF         = generateSuperInfo(info, _Cache())
        local idxIF         = FD_STEXT + #lstIF

        for i, extif in ipairs, lstIF, 0 do
            info[idxIF - i] = extif
        end
        _Cache(lstIF)
    end

    local function addExtend(tType, target, extendIF, stack)
        local info, _, msg  = checkInfoWithName(tType, target)
        stack = (type(stack) == "number" and stack or 2) + 1

        if not info then error(strformat("Usage: %s.AddExtend(%s, extendinterface[, stack]) - ", tostring(tType), tostring(tType)) .. msg, stack) end

        if not interface.Validate(extendIF) then error(strformat("Usage: %s.AddExtend(%s, extendinterface[, stack]) - the extendinterface must be an interface", tostring(tType), tostring(tType)), stack) end
        if interface.IsFinal(extendIF) then error(strformat("Usage: %s.AddExtend(%s, extendinterface[, stack]) - The %s is marked as final, can't be extended", tostring(tType), tostring(tType), tostring(extendIF)), stack) end

        -- Check if already extended
        if interface.IsSubType(target, extendIF) then return end

        -- Check the extend interface's require class
        local reqcls = interface.GetRequireClass(extendIF)

        if class.Validate(target) then
            if reqcls and not class.IsSubType(target, reqcls) then
                error(strformat("Usage: class.AddExtend(class, extendinterface[, stack]) - The class must be %s's sub-class", tostring(reqcls)), stack)
            end
        elseif interface.IsSubType(extendIF, target) then
            error("Usage: interface.AddExtend(interface, extendinterface[, stack]) - The extendinterface is a sub type of the interface", stack)
        elseif reqcls then
            local rcls = interface.GetRequireClass(target)

            if rcls then
                if class.IsSubType(reqcls, rcls) then
                    interface.SetRequireClass(target, reqcls, stack + 1)
                elseif not class.IsSubType(rcls, reqcls) then
                    error(strformat("Usage: interface.AddExtend(interface, extendinterface[, stack]) - The interface's require class must be %s's sub-class", tostring(reqcls)), stack)
                end
            else
                interface.SetRequireClass(target, reqcls, stack + 1)
            end
        end

        -- Add the extend interface
        addSuperType(info, target, extendIF)
    end

    local function addFeature(tType, target, ftype, name, definition, stack)
        local info, name, msg  = checkInfoWithName(tType, target, name)
        stack = (type(stack) == "number" and stack or 2) + 1

        if msg then error(strformat("Usage: %s.AddFeature(%s, featureType, name[, definition][, stack]) - ", tostring(tType), tostring(tType)) .. msg, stack) end

        if not prototype.Validate(ftype) then error(strformat("Usage: %s.AddFeature(%s, featureType, name[, definition][, stack]) - the featureType is not valid", tostring(tType), tostring(tType)), stack) end
        if META_KEYS[name] or name == MTD_DISPOB then error(strformat("Usage: Usage: %s.AddFeature(%s, featureType, name[, definition][, stack]) - The %s can't be used as feature name", tostring(tType), tostring(tType), name), stack) end

        local f = ftype.BeginDefinition(target, name, definition, getSuperFeature(info, name, ftype), stack + 1)

        if f then
            if info[FD_TYPFTR] and info[FD_TYPFTR][name] ~= nil then
                if getmetatable(info[FD_TYPFTR][name] or info[FD_STAFTR][name]) ~= ftype then
                    error(strformat("Usage: %s.AddFeature(%s, featureType, name[, definition][, stack]) - the %q existed as other feature type", tostring(tType), tostring(tType), name), stack)
                end
                if info[FD_TYPFTR][name] == false then
                    ftype.SetStatic(f, stack + 1)
                    info[FD_STAFTR][name] = f
                else
                    info[FD_TYPFTR][name] = f
                end
            else
                info[FD_TYPFTR]         = info[FD_TYPFTR] or _Cache()
                info[FD_TYPFTR][name]   = f
            end

            info[FD_NEWFTR]         = info[FD_NEWFTR] or _Cache()
            info[FD_NEWFTR][name]   = f
        else
            error(strformat("Usage: Usage: %s.AddFeature(%s, featureType, name[, definition][, stack]) - The feature's creation failed", tostring(tType), tostring(tType)), stack)
        end
    end

    local function addMethod(tType, target, name, func, stack)
        local info, name, msg, def  = checkInfoWithName(tType, target, name, true)
        stack = (type(stack) == "number" and stack or 2) + 1

        if msg then error(strformat("Usage: %s.AddMethod(%s, name, func[, stack]) - ", tostring(tType), tostring(tType)) .. msg, stack) end

        if META_KEYS[name] or name == MTD_DISPOB then error(strformat("Usage: Usage: %s.AddMethod(%s, name, func[, stack]) - The %s can't be used as method name", tostring(tType), tostring(tType), name), stack) end
        if type(func) ~= "function" then error(strformat("Usage: %s.AddMethod(%s, name, func[, stack]) - the func must be a function", tostring(tType), tostring(tType)), stack) end

        -- Consume before type's re-definition
        attribute.ConsumeAttributes(func, ATTRIBUTE_TARGETS_METHOD, target, name, stack + 1)

        if not def then
            -- This means a simple but required re-definition
            tType.BeginDefinition(target, stack + 1)
            info    = getTargetInfo(target)
        end

        local nStatic   = not info[name]

        func = attribute.ApplyAttributes(func, ATTRIBUTE_TARGETS_METHOD, nil, target, name, nStatic and getSuperMethod(info, name) or nil)

        if nStatic then
            info[FD_TYPMTD] = info[FD_TYPMTD] or _Cache()
            info[FD_TYPMTD][name] = func
        else
            info[name]      = func
        end

        attribute.ApplyAfterDefine(func, ATTRIBUTE_TARGETS_METHOD, target, name)

        if not def then
            tType.EndDefinition(target, stack + 1)
        end
    end

    local function addMetaMethod(tType, target, name, func, stack)
        local info, name, msg  = checkInfoWithName(tType, target, name)
        stack = (type(stack) == "number" and stack or 2) + 1

        if msg then error(strformat("Usage: %s.AddMetaMethod(%s, name, func[, stack]) - ", tostring(tType), tostring(tType)) .. msg, stack) end

        if not META_KEYS[name] then error(strformat("Usage: Usage: %s.AddMetaMethod(%s, name, func[, stack]) - The name isn't a valid meta-method name", tostring(tType), tostring(tType)), stack) end

        local tfunc = type(func)

        if name ~= MTD_INDEX and tfunc ~= "function" then error(strformat("Usage: %s.AddMetaMethod(%s, name, func[, stack]) - the func must be a function", tostring(tType), tostring(tType)), stack) end
        if name == MTD_INDEX and tfunc ~= "function" and tfunc ~= "table" then error(strformat("Usage: %s.AddMetaMethod(%s, name, func[, stack]) - the func must be a function or table for '__index'", tostring(tType), tostring(tType)), stack) end

        if tfunc == "function" then
            attribute.ConsumeAttributes(func, ATTRIBUTE_TARGETS_METAMETHOD, target, name, stack + 1)
            func = attribute.ApplyAttributes(func, ATTRIBUTE_TARGETS_METAMETHOD, nil, target, name)
        end

        info[FD_TYPMTM]                     = info[FD_TYPMTM] or _Cache()
        info[FD_TYPMTM][name]               = func
        if name ~= META_KEYS[name] then
            info[FD_TYPMTM][META_KEYS[name]]= func
        end

        if tfunc == "table" then
            info[FD_TYPMTM][META_KEYS[name]]= function(self, key) return func[key] end
        elseif tfunc == "function" then
            attribute.ApplyAfterDefine(func, ATTRIBUTE_TARGETS_METAMETHOD, target, name)
        end
    end

    local function setDispose(tType, target, func, stack)
        local info, _, msg  = checkInfoWithName(tType, target)
        stack = (type(stack) == "number" and stack or 2) + 1

        if not info then error(strformat("Usage: %s.SetDispose(%s, func[, stack]) - ", tostring(tType), tostring(tType)) .. msg, stack) end

        if type(func) ~= "function" then error(strformat("Usage: %s.SetDispose(%s, func[, stack]) - the func must be a function", tostring(tType), tostring(tType)), stack) end

        info[FD_DISPOSE] = func
    end

    local function setModifiedFlag(tType, target, flag, methodName, stack)
        local info, _, msg  = checkInfoWithName(tType, target)
        stack = (type(stack) == "number" and stack or 2) + 1

        if not info then error(strformat("Usage: %s.%s(%s[, stack]) - ", tostring(tType), methodName, tostring(tType)) .. msg, stack) end

        if not validateFlags(flag, info[FD_MOD]) then
            info[FD_MOD] = turnOnFlags(flag, info[FD_MOD])
        end
    end

    local function setStaticFeature(tType, target, name, stack)
        local info, name, msg   = checkInfoWithName(tType, target, name)
        stack = (type(stack) == "number" and stack or 2) + 1

        if msg then error(strformat("Usage: %s.SetStaticFeature(%s, name[, stack]) - ", tostring(tType), tostring(tType)) .. msg, stack) end

        if not (info[FD_NEWFTR] and info[FD_NEWFTR][name]) then
            if info[FD_OBJFTR] and info[FD_OBJFTR][name] ~= nil then
                error(strformat("Usage: %s.SetStaticFeature(%s, name[, stack]) - The %s's %q's definition is finished, can't set as static", tostring(tType), tostring(tType), tostring(target), name), stack)
            else
                error(strformat("Usage: %s.SetStaticFeature(%s, name[, stack]) - The %s has no feature named %q", tostring(tType), tostring(tType), tostring(target), name), stack)
            end
        end

        local feature   = info[FD_NEWFTR][name]
        local ftype     = getmetatable(feature)
        if ftype.SetStatic(feature, stack + 1) then
            info[FD_STAFTR] = info[FD_STAFTR] or _Cache()
            info[FD_STAFTR][name] = feature
            info[FD_OBJFTR][name] = false
        else
            error(strformat("Usage: %s.SetStaticFeature(%s, name[, stack]) - The %s's feature %q can't be set as static", tostring(tType), tostring(tType), tostring(target), name), stack)
        end
    end

    local function setStaticMethod(tType, target, name, stack)
        local info, name, msg  = checkInfoWithName(tType, target, name)
        stack = (type(stack) == "number" and stack or 2) + 1

        if msg then error(strformat("Usage: %s.SetStaticMethod(%s, name[, stack]) - ", tostring(tType), tostring(tType)) .. msg, stack) end

        if not (info[FD_TYPMTD] and info[FD_TYPMTD][name] ~= nil) then error(strformat("Usage: %s.SetStaticMethod(%s, name[, stack]) - The %s has no method named %q", tostring(tType), tostring(tType), tostring(target), name), stack) end

        if info[name] == nil then
            info[name] = info[FD_TYPMTD][name]
            info[FD_TYPMTD][name] = false
            if info[FD_INHRTP] and info[FD_INHRTP][name] then info[FD_INHRTP] = nil end
        end
    end

    local function setPriorityFeature(tType, target, name, methodName, priority, stack)
        local info, name, msg  = checkInfoWithName(tType, target, name)
        stack = (type(stack) == "number" and stack or 2) + 1

        if msg then error(strformat("Usage: %s.%s(%s, name[, stack]) - ", tostring(tType), methodName, tostring(tType)) .. msg, stack) end

        if not (info[FD_NEWFTR] and info[FD_NEWFTR][name]) then
            if info[FD_OBJFTR] and info[FD_OBJFTR][name] ~= nil then
                error(strformat("Usage: %s.%s(%s, name[, stack]) - The %s's %q's definition is finished, can't change its priority", tostring(tType), methodName, tostring(tType), tostring(target), name), stack)
            else
                error(strformat("Usage: %s.%s(%s, name[, stack]) - The %s has no feature named %q", tostring(tType), methodName, tostring(tType), tostring(target), name), stack)
            end
        end

        info[FD_INHRTP] = info[FD_INHRTP] or _Cache()
        info[FD_INHRTP][name] = priority
    end

    local function setPriorityMethod(tType, target, name, methodName, priority, stack)
        local info, name, msg  = checkInfoWithName(tType, target, name)
        stack = (type(stack) == "number" and stack or 2) + 1

        if msg then error(strformat("Usage: %s.%s(%s, name[, stack]) - ", tostring(tType), methodName, tostring(tType)) .. msg, stack) end

        if not (info[FD_TYPMTD] and info[FD_TYPMTD][name]) then
            if info[FD_TYPMTD] and info[FD_TYPMTD][name] == false then
                error(strformat("Usage: %s.%s(%s, name[, stack]) - The %s's %q is static, can't change its priority", tostring(tType), methodName, tostring(tType), tostring(target), name), stack)
            else
                error(strformat("Usage: %s.%s(%s, name[, stack]) - The %s has no method named %q", tostring(tType), methodName, tostring(tType), tostring(target), name), stack)
            end
        end

        info[FD_INHRTP] = info[FD_INHRTP] or _Cache()
        info[FD_INHRTP][name] = priority
    end

    local function setPriorityMetaMethod(tType, target, name, methodName, priority, stack)
        local info, name, msg  = checkInfoWithName(tType, target, name)
        stack = (type(stack) == "number" and stack or 2) + 1

        if msg then error(strformat("Usage: %s.%s(%s, name[, stack]) - ", tostring(tType), methodName, tostring(tType)) .. msg, stack) end

        if not (info[FD_TYPMTM] and info[FD_TYPMTM][name]) then
            error(strformat("Usage: %s.%s(%s, name[, stack]) - The %s has no meta-method named %q", tostring(tType), methodName, tostring(tType), tostring(target), name), stack)
        end

        info[FD_INHRTP] = info[FD_INHRTP] or _Cache()
        info[FD_INHRTP][name] = priority
    end

    -- Buidler helpers
    local function getIfBuilderValue(self, name)
        -- Access methods
        local info = getTargetInfo(environment.GetNameSpace(self))
        if info and info[name] then return info[name], true end
        return environment.GetValue(self, name)
    end

    local function getClsBuilderValue(self, name)
        -- Access methods
        local info = getTargetInfo(environment.GetNameSpace(self))
        if info and info[name] then return info[name], true end
        return environment.GetValue(self, name)
    end

    local function setBuilderOwnerValue(owner, key, value, stack, notnewindex)
        local tkey  = type(key)
        local tval  = type(value)

        stack       = stack + 1

        if tkey == "string" and not tonumber(key) then
            if tval == "function" then
                if key == MTD_INIT then
                    struct.SetInitializer(owner, value, stack)
                    return true
                elseif key == namespace.GetNameSpaceName(owner, true) then
                    struct.SetValidator(owner, value, stack)
                    return true
                else
                    struct.AddMethod(owner, key, value, stack)
                    return true
                end
            elseif namespace.IsResourceType(value) then
                if key == MTD_BASE then
                    struct.SetBaseStruct(owner, value, stack)
                else
                    struct.AddMember(owner, key, { Type = value }, stack)
                end
                return true
            elseif tval == "table" and notnewindex then
                struct.AddMember(owner, key, value, stack)
                return true
            end
        elseif tkey == "number" then
            if tval == "function" then
                struct.SetValidator(owner, value, stack)
            elseif namespace.IsResourceType(value) then
                struct.SetArrayElement(owner, value, stack)
            elseif tval == "table" then
                struct.AddMember(owner, value, stack)
            else
                struct.SetDefault(owner, value, stack)
            end
            return true
        end
    end

    interface       = prototype "interface" {
        __index     = {
            ["AddExtend"]       = function(target, extendinterface, stack)
                addExtend(interface, target, extendinterface, stack)
            end;

            ["AddFeature"]      = function(target, ftype, name, definition, stack)
                addFeature(interface, target, ftype, name, definition, stack)
            end;

            ["AddMetaMethod"]   = function(target, name, func, stack)
                addMetaMethod(interface, target, name, func, stack)
            end;

            ["AddMethod"]       = function(target, name, func, stack)
                addMethod(interface, target, name, func, stack)
            end;

            ["BeginDefinition"] = function(target, stack)
                stack = type(stack) == "number" and stack or 2

                target          = interface.Validate(target)
                if not target then error("Usage: interface.BeginDefinition(interface[, stack]) - interface not existed", stack) end

                if _ICInfo[target] and validateFlags(MD_SEAL, _ICInfo[target][FD_MOD]) then error(strformat("Usage: interface.BeginDefinition(interface[, stack]) - The %s is sealed, can't be re-defined", tostring(target)), stack) end
                if _BDInfo[target] then error(strformat("Usage: interface.BeginDefinition(interface[, stack]) - The %s's definition has already begun", tostring(target)), stack) end

                -- Only one thread can be allowed to define class or interface
                beginDefinition(target, stack + 1)

                local ninfo     = tblclone(_ICInfo[target], { [FD_SUPCACH] = false }, true)

                ninfo[FD_SUPCACH] = nil

                _BDInfo[target] = ninfo

                attribute.ConsumeAttributes(target, ATTRIBUTE_TARGETS_INTERFACE, nil, nil, stack + 1)
            end;

            ["EndDefinition"]   = function(target, stack)
                local ninfo     = _BDInfo[target]
                if not ninfo then return end

                stack = type(stack) == "number" and stack or 2

                attribute.ApplyAttributes(target, ATTRIBUTE_TARGETS_INTERFACE, nil, nil, nil, unpack(ninfo, FD_STEXT))

                -- End new type feature's definition
                endDefinitionForNewFeatures(target, stack + 1)

                -- Re-generate the extended interfaces order list
                local lst       = generateSuperInfo(ninfo, _Cache())
                local idxIF     = FD_STEXT + #lst

                for i, extif in ipairs, lst, 0 do
                    ninfo[idxIF - i]= extif
                end

                _Cache(lst)

                generateTypeCaches(target, ninfo)

                -- End interface's definition
                _BDInfo[target] = nil

                -- Save as new interface's info
                _ICInfo[target] = ninfo

                attribute.ApplyAfterDefine(target, ATTRIBUTE_TARGETS_INTERFACE)

                -- Release the lock, so other threads can be used to define interface or class
                endDefinition(target, stack + 1)

                return target
            end;

            ["RefreshDefinition"] = function(target, stack)
                stack = type(stack) == "number" and stack or 2

                target          = interface.Validate(target)
                if not target then error("Usage: interface.RefreshDefinition(interface[, stack]) - interface not existed", stack) end
                if _BDInfo[target] then error(strformat("Usage: interface.RefreshDefinition(interface[, stack]) - The %s's definition has already begun", tostring(target)), stack) end

                -- Only one thread can be allowed to define class or interface
                beginDefinition(target, stack + 1)

                local ninfo     = tblclone(_ICInfo[target], { [FD_SUPCACH] = false }, true)

                ninfo[FD_SUPCACH] = nil

                -- Re-generate the extended interfaces order list
                local lst       = generateSuperInfo(ninfo, _Cache())
                local idxIF     = FD_STEXT + #lst

                for i, extif in ipairs, lst, 0 do
                    ninfo[idxIF - i]= extif
                end

                _Cache(lst)

                generateTypeCaches(target, ninfo)

                -- Save as new interface's info
                _ICInfo[target] = ninfo

                -- Release the lock, so other threads can be used to define interface or class
                endDefinition(target, stack + 1)

                return target
            end;

            ["GetDefault"]      = fakefunc;

            ["GetExtends"]      = function(target, cache)
                local info      = getTargetInfo(target)
                if info then
                    if cache then
                        cache   = type(cache) == "table" and wipe(cache) or {}
                        for i   = #info, FD_STEXT, -1 do tinsert(cache, info[i]) end
                        return cache
                    else
                        local m = #info
                        local u = m - FD_STEXT
                        return function(self, n)
                            if type(n) == "number" and n >= 0 and n <= u then
                                local v = info[m - n]
                                if v then return n + 1, v end
                            end
                        end, target, 0
                    end
                elseif not cache then
                    return fakefunc, target, 0
                end
            end;

            ["GetFeature"]      = function(target, name)
                local info, def = getTargetInfo(target)
                if info and type(name) == "string" then
                    local featr = info[FD_TYPFTR] and info[FD_TYPFTR][name]
                    if featr == false then featr = info[FD_STAFTR][name] end
                    return featr and getmetatable(featr).GetFeature(featr)
                end
            end;

            ["GetObjectFeature"]= function(target, name)
                local info, def = getTargetInfo(target)
                if info and type(name) == "string" then
                    local featr = info[FD_TYPFTR] and info[FD_TYPFTR][name]
                    return featr and getmetatable(featr).GetFeature(featr)
                end
            end;

            ["GetStaticFeature"]= function(target, name)
                local info, def = getTargetInfo(target)
                if info and type(name) == "string" then
                    local featr = info[FD_STAFTR] and info[FD_STAFTR][name]
                    return featr and getmetatable(featr).GetFeature(featr)
                end
            end;

            ["GetFeatures"]     = function(target, cache)
                local info      = getTargetInfo(target)
                if info then
                    if cache then
                        cache   = type(cache) == "table" and wipe(cache) or {}

                        if info[FD_TYPFTR] then
                            for k, v in pairs, info[FD_TYPFTR] do
                                v = v or info[FD_STAFTR][k]
                                cache[k] = getmetatable(v).GetFeature(v)
                            end
                        end

                        return cache
                    elseif infop[FD_TYPFTR] then
                        local tf = info[FD_TYPFTR]
                        local sf = info[FD_STAFTR]
                        return function(self, n)
                            local n, v  = next(tf, n)
                            if n then
                                v       = v or sf[n]
                                return n, getmetatable(v).GetFeature(v)
                            end
                        end, target
                    end
                end
                if cache then
                    return type(cache) == "table" and cache or nil
                else
                    return fakefunc, target
                end
            end;

            ["GetObjectFeatures"]= function(target, cache)
                local info      = getTargetInfo(target)
                if info then
                    if cache then
                        cache   = type(cache) == "table" and wipe(cache) or {}

                        if info[FD_TYPFTR] then
                            for k, v in pairs, info[FD_TYPFTR] do
                                if v then
                                    cache[k] = getmetatable(v).GetFeature(v)
                                end
                            end
                        end

                        return cache
                    elseif info[FD_TYPFTR] then
                        local tf = info[FD_TYPFTR]
                        return function(self, n)
                            local n, v  = next(tf, n)
                            while n and v == false do n, v = next(tf, n) end
                            if v then
                                return n, getmetatable(v).GetFeature(v)
                            end
                        end, target
                    end
                end
                if cache then
                    return type(cache) == "table" and cache or nil
                else
                    return fakefunc, target
                end
            end;

            ["GetStaticFeatures"]= function(target, cache)
                local info      = getTargetInfo(target)
                if info then
                    if cache then
                        cache   = type(cache) == "table" and wipe(cache) or {}

                        if def and info[FD_NEWFTR] then for k, v in pairs, info[FD_NEWFTR] do if getmetatable(v).IsStatic(v) then cache[k] = getmetatable(v).GetFeature(v) end end end
                        if info[FD_STAFTR] then for k, v in pairs, info[FD_STAFTR] do if not cache[k] then cache[k] = getmetatable(v).GetFeature(v) end end end

                        return cache
                    else
                        local nf = def and info[FD_NEWFTR]
                        local sf = info[FD_STAFTR]
                        local bnf= nf
                        return function(self, n)
                            local v
                            if nf then
                                n, v    = next(nf, n)
                                while n and not getmetatable(v).IsStatic(v) do n, v = next(nf, n) end
                                if v then return n, getmetatable(v).GetFeature(v) end
                                nf, n   = nil
                            end
                            if sf then
                                n, v    = next(sf, n)
                                while n and bnf and bnf[n] do n, v = next(sf, n) end
                                if v then return n, getmetatable(v).GetFeature(v) end
                            end
                        end, target
                    end
                end
                if cache then
                    return type(cache) == "table" and cache or nil
                else
                    return fakefunc, target
                end
            end;

            ["GetMethod"]       = function(target, name)
                local info, def = getTargetInfo(target)
                return info and type(name) == "string" and info[name] or nil
            end;

            ["GetObjectMethod"] = function(target, name)
                local info      = getTargetInfo(target)
                local method    = info and type(name) == "string" and info[name]
                return method and info[FD_TYPMTD] and info[FD_TYPMTD][name] and method or nil
            end;

            ["GetStaticMethod"] = function(target, name)
                local info      = getTargetInfo(target)
                local method    = info and type(name) == "string" and info[name]
                return method and not (info[FD_TYPMTD] and info[FD_TYPMTD][name]) and method or nil
            end;

            ["GetMethods"]      = function(target, cache)
                local info      = getTargetInfo(target)
                if info then
                    if cache then
                        cache   = type(cache) == "table" and wipe(cache) or {}
                        for k, v in pairs, info do if type(k) == "string" then cache[k] = v end end
                        return cache
                    else
                        return function(self, n)
                            local v
                            n, v    = next(info, n)
                            while n and type(n) ~= "string" do n, v = next(info, n) end
                            if v then return n, v end
                        end, target
                    end
                end
                if cache then
                    return type(cache) == "table" and cache or nil
                else
                    return fakefunc, target
                end
            end;

            ["GetObjectMethods"]= function(target, cache)
                local info      = getTargetInfo(target)
                if info then
                    local obm   = info[FD_TYPMTD]
                    if cache then
                        cache   = type(cache) == "table" and wipe(cache) or {}
                        if obm then for k, v in pairs, info do if obm[k] then cache[k] = v end end end
                        return cache
                    elseif obm then
                        return function(self, n)
                            local v
                            n, v    = next(info, n)
                            while n and not obm[n] do n, v = next(info, n) end
                            if v then return n, v end
                        end, target
                    end
                end
                if cache then
                    return type(cache) == "table" and cache or nil
                else
                    return fakefunc, target
                end
            end;

            ["GetStaticMethods"]= function(target, cache)
                local info      = getTargetInfo(target)
                if info then
                    local obm   = info[FD_TYPMTD]
                    if cache then
                        cache   = type(cache) == "table" and wipe(cache) or {}
                        for k, v in pairs, info do if type(k) == "string" and not (obm and obm[k]) then cache[k] = v end end
                        return cache
                    else
                        return function(self, n)
                            local v
                            n, v    = next(info, n)
                            while n and (type(n) ~= "string" or obm and obm[n]) do n, v = next(info, n) end
                            if v then return n, v end
                        end, target
                    end
                end
                if cache then
                    return type(cache) == "table" and cache or nil
                else
                    return fakefunc, target
                end
            end;

            ["GetRequireClass"] = function(target)
                local info      = getTargetInfo(target)
                return info and info[FD_REQCLS]
            end;

            ["IsSubType"]       = function(target, extendIF)
                if target == extendIF then return true end
                local info = getTargetInfo(target)
                if info then for _, extif in ipairs, info, FD_STEXT - 1 do if extif == extendIF then return true end end end
                return false
            end;

            ["IsFinal"]         = function(target)
                local info      = getTargetInfo(target)
                return info and validateFlags(MD_FINAL, info[FD_MOD]) or false
            end;

            ["IsSealed"]        = function(target)
                local info      = getTargetInfo(target)
                return info and validateFlags(MD_SEAL, info[FD_MOD]) or false
            end;

            ["IsRequireFeature"]= function(target, name)
                local info      = getTargetInfo(target)
                local feature   = info and (info[FD_NEWFTR] and info[FD_NEWFTR][name] or info[FD_TYPFTR] and info[FD_TYPFTR][name])
                return feature and getmetatable(feature).IsRequire(feature) or false
            end;

            ["IsRequireMethod"] = function(target, name)
                local info      = getTargetInfo(target)
                return info and type(name) == "string" and info[name] and info[FD_TYPMTD] and info[FD_TYPMTD][name] == true or false
            end;

            ["IsRequireMetaMethod"] = function(target, name)
                local info      = getTargetInfo(target)
                return info and type(name) == "string" and info[FD_TYPMTM] and info[FD_TYPMTM][name] == true or false
            end;

            ["IsStaticFeature"] = function(target, name)
                local info      = getTargetInfo(target)
                local feature   = info and (info[FD_NEWFTR] and info[FD_NEWFTR][name] or info[FD_TYPFTR] and info[FD_TYPFTR][name])
                return feature and getmetatable(feature).IsStatic(feature) or false
            end;

            ["IsStaticMethod"]  = function(target, name)
                local info      = getTargetInfo(target)
                return info and type(name) == "string" and info[name] and not (info[FD_TYPMTD] and info[FD_TYPMTD][name]) and true or false
            end;

            ["SetFinal"]        = function(target, stack)
                setModifiedFlag(interface, target, MD_FINAL, "SetFinal", stack)
            end;

            ["SetDispose"]      = function(target, func, stack)
                setDispose(interface, target, func, stack)
            end;

            ["SetInitializer"]  = function(target, func, stack)
                local info, def = getTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    if not def then error(strformat("Usage: interface.SetInitializer(interface, initializer[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                    if type(func) ~= "function" then error("Usage: interface.SetInitializer(interface, initializer) - The initializer must be a function", stack) end
                    info[FD_INIT] = func
                else
                    error("Usage: interface.SetInitializer(interface, initializer[, stack]) - The interface is not valid", stack)
                end
            end;

            ["SetRequireClass"] = function(target, cls, stack)
                stack = type(stack) == "number" and stack or 2

                if not interface.Validate(target) then error("Usage: interface.SetRequireClass(interface, requireclass[, stack]) - the interface is not valid", stack) end

                local info, def = getTargetInfo(target)

                if info then
                    if not class.Validate(cls) then error("Usage: interface.SetRequireClass(interface, requireclass[, stack]) - the requireclass must be a class", stack) end
                    if not def then error(strformat("Usage: interface.SetRequireClass(interface, requireclass[, stack]) - The %s' definition is finished", tostring(target)), stack) end
                    if info[FD_REQCLS] and not class.IsSubType(cls, info[FD_REQCLS]) then error(strformat("Usage: interface.SetRequireClass(interface, requireclass[, stack]) - The requireclass must be %s's sub-class", tostring(info[FD_REQCLS])), stack) end

                    info[FD_REQCLS] = cls
                else
                    error("Usage: interface.SetRequireClass(interface, requireclass[, stack]) - The interface is not valid", stack)
                end
            end;

            ["SetRequireFeature"]= function(target, name)
                local info, def = getTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    if type(name) ~= "string" then error("Usage: interface.SetRequireFeature(interface, name[, stack]) - the name must be a string", stack) end
                    name = strtrim(name)
                    if name == "" then error("Usage: interface.SetRequireFeature(interface, name[, stack]) - The name can't be empty", stack) end
                    if not def then error(strformat("Usage: interface.SetRequireFeature(interface, name[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                    if not (info[FD_NEWFTR] and info[FD_NEWFTR][name]) then
                        if info[FD_STAFTR] and info[FD_STAFTR][name] or info[FD_OBJFTR] and info[FD_OBJFTR][name] then
                            error(strformat("Usage: interface.SetRequireFeature(interface, name[, stack]) - The %s's %q's definition is finished, can't set as require", tostring(target), name), stack)
                        else
                            error(strformat("Usage: interface.SetRequireFeature(interface, name[, stack]) - The %s has no feature named %q", tostring(target), name), stack)
                        end
                    end

                    local feature = info[FD_NEWFTR][name]
                    getmetatable(feature).SetRequire(feature, stack + 1)
                else
                    error("Usage: interface.SetRequireFeature(interface, name[, stack]) - The interface is not valid", stack)
                end
            end;

            ["SetRequireMethod"]= function(target, name, stack)
                local info, def = getTargetInfo(target)
                stack = (type(stack) == "number" and stack or 2) + 1

                if info then
                    if type(name) ~= "string" then error("Usage: interface.SetRequireMethod(interface, name[, stack]) - the name must be a string", stack) end
                    name = strtrim(name)
                    if name == "" then error("Usage: interface.SetRequireMethod(interface, name[, stack]) - The name can't be empty", stack) end
                    if not def then error(strformat("Usage: interface.SetRequireMethod(interface, name[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                    if not info[name] then error(strformat("Usage: interface.SetRequireMethod(interface, name[, stack]) - The %s has no method named %q", tostring(target), name), stack) end
                    if not (info[FD_TYPMTD] and info[FD_TYPMTD][name]) then error(strformat("Usage: interface.SetRequireMethod(interface, name[, stack]) - The %q is a static method", name), stack) end

                    info[FD_TYPMTD][name] = true
                else
                    error("Usage: interface.SetRequireMethod(interface, name[, stack]) - The interface is not valid", stack)
                end
            end;

            ["SetRequireMetaMethod"] = function(target, name, stack)
                local info, def = getTargetInfo(target)
                stack = (type(stack) == "number" and stack or 2) + 1

                if info then
                    if type(name) ~= "string" then error("Usage: interface.SetRequireMetaMethod(interface, name[, stack]) - the name must be a string", stack) end
                    name = strtrim(name)
                    if name == "" then error("Usage: interface.SetRequireMetaMethod(interface, name[, stack]) - The name can't be empty", stack) end
                    if not def then error(strformat("Usage: interface.SetRequireMetaMethod(interface, name[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                    if not info[name] then error(strformat("Usage: interface.SetRequireMetaMethod(interface, name[, stack]) - The %s has no method named %q", tostring(target), name), stack) end
                    if not (info[FD_TYPMTD] and info[FD_TYPMTD][name]) then error(strformat("Usage: interface.SetRequireMetaMethod(interface, name[, stack]) - The %q is a static method", name), stack) end

                else
                    error("Usage: interface.SetRequireMetaMethod(interface, name[, stack]) - The interface is not valid", stack)
                end
            end;

            ["SetSealed"]       = function(target, stack)
                setModifiedFlag(interface, target, MD_SEAL, "SetSealed", stack)
            end;

            ["SetStaticFeature"]= function(target, name, stack)
                setStaticFeature(interface, target, name, stack)
            end;

            ["SetStaticMethod"] = function(target, name, stack)
                setStaticMethod(interface, target, name, stack)
            end;

            ["ValidateValue"]   = function(extendIF, value)
                local cls       = getmetatable(value)
                local info      = cls and getTargetInfo(cls)
                if info then return info[FD_SUPINFO] and info[FD_SUPINFO][extendIF] and true or false end
                return false
            end;

            ["Validate"]        = function(target)
                return getmetatable(target) == interface and getTargetInfo(target) and target or nil
            end;
        },
        __newindex  = readOnly,
        __call      = function(self, ...)
            local env, target, definition, keepenv, stack = GetTypeParams(interface, tinterface, ...)
            if not target then error("Usage: interface([env, ][name, ][definition, ][keepenv, ][, stack]) - the interface type can't be created", stack) end

            interface.BeginDefinition(target, stack + 1)

            local tarenv = prototype.NewObject(interfacebuilder)
            environment.SetNameSpace(tarenv, target)
            environment.SetParent(env)

            if definition then
                tarenv(definition, stack + 1)
                return target
            else
                if not keepenv then setfenv(stack, tarenv) end
                return tarenv
            end
        end,
    }

    class           = prototype "calss" {
        __index     = {
            ["AddExtend"]       = function(target, extendinterface, stack)
                addExtend(class, target, extendinterface, stack)
            end;

            ["AddFeature"]      = function(target, ftype, name, definition, stack)
                addFeature(class, target, ftype, name, definition, stack)
            end;

            ["AddMetaMethod"]   = function(target, name, func, stack)
                addMetaMethod(class, target, name, func, stack)
            end;

            ["AddMethod"]       = function(target, name, func, stack)
                addMethod(class, target, name, func, stack)
            end;

            ["BeginDefinition"] = function(target, stack)
                stack = type(stack) == "number" and stack or 2

                target          = interface.Validate(target)
                if not target then error("Usage: class.BeginDefinition(class[, stack]) - class not existed", stack) end

                local info      = _ICInfo[target]

                if info and validateFlags(MD_SEAL, info[FD_MOD]) then error(strformat("Usage: class.BeginDefinition(class[, stack]) - The %s is sealed, can't be re-defined", tostring(target)), stack) end
                if _BDInfo[target] then error(strformat("Usage: class.BeginDefinition(class[, stack]) - The %s's definition has already begun", tostring(target)), stack) end

                -- Only one thread can be allowed to define class or interface
                beginDefinition(target, stack + 1)

                local ninfo     = _Cache()

                ninfo[FD_SUPCACH]   = false
                ninfo[FD_SUPINFO]   = false
                ninfo[FD_OBJMTD]    = false
                ninfo[FD_OBJFTR]    = false
                ninfo[FD_OBJMTM]    = false
                tblclone(info, ninfo, true)
                ninfo[FD_SUPINFO]   = nil
                ninfo[FD_SUPCACH]   = nil
                ninfo[FD_OBJMTD]    = nil
                ninfo[FD_OBJFTR]    = nil
                ninfo[FD_OBJMTM]    = nil

                _BDInfo[target] = ninfo

                attribute.ConsumeAttributes(target, ATTRIBUTE_TARGETS_CLASS, nil, nil, stack + 1)
            end;

            ["EndDefinition"]   = function(target, stack)
                local ninfo     = _BDInfo[target]
                if not ninfo then return end

                stack = type(stack) == "number" and stack or 2

                attribute.ApplyAttributes(target, ATTRIBUTE_TARGETS_CLASS, nil, nil, nil, unpack(ninfo, ninfo[FD_SUPCLS] and FD_SUPCLS or FD_STEXT))

                -- End new type feature's definition
                endDefinitionForNewFeatures(target, stack + 1)

                -- The init & dispose link for extended interfaces & super classes
                local initIdx   = FD_STINIT
                local dispIdx   = FD_ENDISP

                if validateFlags(MD_ABSCLS, ninfo[FD_MOD]) then
                    local lst   = generateSuperInfo(ninfo, _Cache())
                    local idxIF = FD_STEXT + #lst

                    for i, extif in ipairs, lst, 0 do
                        ninfo[idxIF - i]= extif
                    end

                    _Cache(lst)

                    ninfo[FD_SIMPCLS]   = nil
                    ninfo[FD_SUPINFO]   = nil
                    ninfo[FD_CTOR ]   = nil
                    ninfo[FD_CLINIT ]   = nil

                    if ninfo[FD_TYPMTD] then ninfo[FD_TYPMTD][MTD_DISPOB] = nil end
                else
                    -- Interface Order List, Super info cache
                    local lst, spc  = generateSuperInfo(ninfo, _Cache(), _Cache())

                    -- New meta table
                    local meta      = _Cache()
                    local rlCtor    = nil
                    local idxIF     = FD_STEXT + #lst

                    -- Save Dispose for super classes
                    for _, sinfo in ipairs, spc, 0 do
                        if sinfo[FD_DISPOSE] then
                            ninfo[dispIdx]  = sinfo[FD_DISPOSE]
                            dispIdx         = dispIdx - 1
                        end
                    end

                    -- Save class's dispose
                    if ninfo[FD_DISPOSE] then
                        ninfo[dispIdx]  = ninfo[FD_DISPOSE]
                        dispIdx         = dispIdx - 1
                    end

                    -- Save Initializer & Dispose for extended interfaces
                    for i, extif in ipairs, lst, 0 do
                        ninfo[idxIF - i]= extif

                        local sinfo     = spc[extif]
                        saveFeatureFromSuper(ninfo, sinfo, meta)

                        if sinfo[FD_INIT] then
                            ninfo[initIdx]  = sinfo[FD_INIT]
                            initIdx         = initIdx + 1
                        end

                        if sinfo[FD_DISPOSE] then
                            ninfo[dispIdx]  = sinfo[FD_DISPOSE]
                            dispIdx         = dispIdx - 1
                        end
                    end

                    _Cache(lst)

                    -- Save features from super classes
                    for i, sinfo in ipairs, spc, 0 do
                        rlCtor  = sinfo[FD_INIT] or rlCtor
                        saveFeatureFromSuper(ninfo, sinfo, meta)
                    end

                    -- Clear super classes info
                    if not next(spc) then _Cache(spc) spc = nil end

                    -- Saving informations
                    tblclone(ninfo[FD_TYPMTM], meta, false, true)
                    ninfo[FD_CLINIT]    = ninfo[FD_INIT] or rlCtor
                    ninfo[FD_SIMPCLS]   = not (ninfo[FD_CLINIT] or ninfo[FD_OBJFTR]) or nil
                    ninfo[FD_SUPINFO]   = spc
                    if ninfo[FD_OBJFTR] and not next(ninfo[FD_OBJFTR]) then _Cache(ninfo[FD_OBJFTR]) ninfo[FD_OBJFTR]= nil end

                    -- Always have a dispose method
                    local FD_STDISP     = dispIdx + 1
                    ninfo[FD_TYPMTD]    = ninfo[FD_TYPMTD] or _Cache()
                    ninfo[FD_TYPMTD][MTD_DISPOB] = function(self)
                        for i = FD_STDISP, FD_ENDISP do ninfo[i](self) end
                        rawset(wipe(self), "Disposed", true)
                    end

                    generateMetaIndex   (ninfo, meta)
                    generateMetaNewIndex(ninfo, meta)
                    meta[MTD_META]    = target

                    generateConstructor(ninfo, meta)
                end

                -- Clear non-used init & dispose
                while ninfo[initIdx] do ninfo[initIdx] = nil initIdx = initIdx + 1 end
                while ninfo[dispIdx] do ninfo[dispIdx] = nil dispIdx = dispIdx - 1 end

                -- Finish the definition
                _BDInfo[target] = nil

                -- Save as new class's info
                _ICInfo[target]   = ninfo

                -- Release the lock to allow other threads continue to define class or interface
                endDefinition(target, stack + 1)

                attribute.ApplyAfterDefine(target, ATTRIBUTE_TARGETS_CLASS)

                return target
            end;

            ["GetDefault"]      = fakefunc;

            ["GetExtends"]      = interface.GetExtends;

            ["GetFeature"]      = interface.GetFeature;

            ["GetObjectFeature"]= interface.GetObjectFeature;

            ["GetStaticFeature"]= interface.GetStaticFeature;

            ["GetFeatures"]     = interface.GetFeatures;

            ["GetObjectFeatures"] = interface.GetObjectFeatures;

            ["GetStaticFeatures"] = interface.GetStaticFeatures;

            ["GetMethod"]       = interface.GetMethod;

            ["GetObjectMethod"] = interface.GetObjectMethod;

            ["GetStaticMethod"] = interface.GetStaticMethod;

            ["GetMethods"]      = interface.GetMethods;

            ["GetObjectMethods"]= interface.GetObjectMethods;

            ["GetStaticMethods"]= interface.GetStaticMethods;

            ["GetSuperClass"]   = function(target)
                local info      = getTargetInfo(target)
                return info and info[FD_SUPCLS]
            end;

            ["IsSubType"]       = function(target, supertype)
                if target == supertype then return true end
                local info = getTargetInfo(target)
                if info then
                    local sinfo = info[FD_SUPINFO]
                    if sinfo then return sinfo[supertype] and true or false end

                    if class.Validate(supertype) then
                        while info and info[FD_SUPCLS] ~= supertype do
                            info= getTargetInfo(info[FD_SUPCLS])
                        end
                        if info then return true end
                    else
                        for _, extif in ipairs, info, FD_STEXT - 1 do if extif == supertype then return true end end
                    end
                end
                return false
            end;

            ["IsAbstract"]      = function(target)
                local info      = getTargetInfo(target)
                return info and validateFlags(MD_ABSCLS, info[FD_MOD]) or false
            end;

            ["IsAutoCache"]     = function(target)
                local info      = getTargetInfo(target)
                return info and validateFlags(MD_ATCACHE, info[FD_MOD]) or false
            end;

            ["IsFinal"]         = interface.IsFinal;

            ["IsObjMethodAttrEnabled"] = function(target)
                local info      = getTargetInfo(target)
                return info and validateFlags(MD_OBJMDAT, info[FD_MOD]) or false
            end;

            ["IsOldSuperStyleClass"] = function(target)
                local info      = getTargetInfo(target)
                return info and validateFlags(MD_ODSUPER, info[FD_MOD]) or false
            end;

            ["IsRawSetBlocked"] = function(target)
                local info      = getTargetInfo(target)
                return info and validateFlags(MD_NRAWSET, info[FD_MOD]) or false
            end;

            ["IsSealed"]        = interface.IsSealed;

            ["IsSimpleClass"]   = function(target)
                local info      = getAttributeInfo(target)
                return info and (info[FD_SIMPCLS] or validateFlags(MD_ASSPCLS, info[FD_MOD])) or false
            end;

            ["IsSimpleVersion"] = function(target)
                local info      = getTargetInfo(target)
                return info and validateFlags(MD_SIMPVER, info[FD_MOD]) or false
            end;

            ["IsStaticFeature"] = interface.IsStaticFeature;

            ["IsStaticMethod"]  = interface.IsStaticMethod;

            ["IsThreadSafe"]    = function(target)
                local info      = getTargetInfo(target)
                return info and validateFlags(MD_THDSAFE, info[FD_MOD]) or false
            end;

            ["SetAbstract"]     = function(target, stack)
                setModifiedFlag(class, target, MD_ABSCLS, "SetAbstract", stack)
            end;

            ["SetAutoCache"]    = function(target, stack)
                setModifiedFlag(class, target, MD_ATCACHE, "SetAutoCache", stack)
            end;

            ["SetAsSimpleClass"]= function(target, stack)
                setModifiedFlag(class, target, MD_ASSPCLS, "SetAsSimpleClass", stack)
            end;

            ["SetConstructor"]  = function(target, func, stack)
                local info, def = getTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    if not def then error(strformat("Usage: class.SetConstructor(class, constructor[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                    if type(func) ~= "function" then error("Usage: class.SetConstructor(class, constructor) - The constructor must be a function", stack) end

                    attribute.ConsumeAttributes(func, ATTRIBUTE_TARGETS_CTOR, target, name, stack + 1)
                    func = attribute.ApplyAttributes(func, ATTRIBUTE_TARGETS_CTOR, nil, target, name)

                    info[FD_INIT] = func

                    attribute.ApplyAfterDefine(func, ATTRIBUTE_TARGETS_CTOR, target, name)
                else
                    error("Usage: class.SetConstructor(class, constructor[, stack]) - The class is not valid", stack)
                end
            end;

            ["SetDispose"]      = function(target, func, stack)
                setDispose(class, target, func, stack)
            end;

            ["SetFinal"]        = function(target, stack)
                setModifiedFlag(class, target, MD_FINAL, "SetFinal", stack)
            end;

            ["SetObjMethodAttrEnabled"] = function(target, stack)
                setModifiedFlag(class, target, MD_OBJMDAT, "SetObjMethodAttrEnabled", stack)
            end;

            ["SetOldSuperStyle"]= function(target, stack)
                setModifiedFlag(class, target, MD_ODSUPER, "SetOldSuperStyle", stack)
            end;

            ["SetRawSetBlocked"]= function(target, stack)
                setModifiedFlag(class, target, MD_NRAWSET, "SetRawSetBlocked", stack)
            end;

            ["SetSealed"]       = function(target, stack)
                setModifiedFlag(class, target, MD_SEAL, "SetSealed", stack)
            end;

            ["SetSimpleVersion"]= function(target, stack)
                setModifiedFlag(class, target, MD_SIMPVER, "SetSimpleVersion", stack)
            end;

            ["SetSuperClass"]   = function(target, cls, stack)
                stack = type(stack) == "number" and stack or 2

                if not class.Validate(target) then error("Usage: class.SetSuperClass(class, superclass[, stack]) - the class is not valid", stack) end

                local info, def = getTargetInfo(target)

                if info then
                    if not class.Validate(cls) then error("Usage: class.SetSuperClass(class, superclass[, stack]) - the superclass must be a class", stack) end
                    if not def then error(strformat("Usage: class.SetSuperClass(class, superclass[, stack]) - The %s' definition is finished", tostring(target)), stack) end
                    if info[FD_SUPCLS] and info[FD_SUPCLS] ~= cls then error(strformat("Usage: class.SetSuperClass(class, superclass[, stack]) - The %s already has a super class", tostring(target)), stack) end

                    if info[FD_SUPCLS] then return end

                    addSuperType(info, target, cls)
                else
                    error("Usage: class.SetSuperClass(class, superclass[, stack]) - The class is not valid", stack)
                end
            end;

            ["SetStaticFeature"]= function(target, name, stack)
                setStaticFeature(class, target, name, stack)
            end;

            ["SetStaticMethod"] = function(target, name, stack)
                setStaticMethod(class, target, name, stack)
            end;

            ["SetThreadSafe"]   = function(target, stack)
                setModifiedFlag(class, target, MD_THDSAFE, "SetThreadSafe", stack)
            end;

            ["ValidateValue"]   = function(cls, value)
                local ocls      = getmetatable(value)
                if not ocls     then return false end
                if ocls == cls  then return true end
                local info      = getTargetInfo(ocls)
                return info and info[FD_SUPINFO] and info[FD_SUPINFO][cls] and true or false
            end;

            ["Validate"]        = function(target)
                return getmetatable(target) == class and getTargetInfo(target) and target or nil
            end;
        },
        __newindex  = readOnly,
        __call      = function(self, ...)
            local env, target, definition, keepenv, stack = GetTypeParams(class, tclass, ...)
            if not target then error("Usage: class([env, ][name, ][definition, ][keepenv, ][, stack]) - the class type can't be created", stack) end

            class.BeginDefinition(target, stack + 1)

            local tarenv = prototype.NewObject(classbuilder)
            environment.SetNameSpace(tarenv, target)
            environment.SetParent(env)

            if definition then
                tarenv(definition, stack + 1)
                return target
            else
                if not keepenv then setfenv(stack, tarenv) end
                return tarenv
            end
        end,
    }

    tinterface      = prototype "tinterface" (tnamespace, {
        __index     = function(self, key)
            if type(key) == "string" then
                -- Access methods
                local info  = _ICInfo[self]
                if info then
                    -- Meta-methods
                    local oper  = META_KEYS[key]
                    if oper then return info[FD_TYPMTM] and info[FD_TYPMTM][oper] or nil end

                    -- Static or object methods
                    oper  = info[key]
                    if oper then return oper end

                    -- Static features
                    oper  = info[FD_STAFTR] and info[FD_STAFTR][key]
                    if oper then return oper:Get(self) end
                end

                -- Access child-namespaces
                return namespace.GetNameSpace(self, key)
            end
        end,
        __newindex  = function(self, key, value)
            if type(key) == "string" then
                local info  = _ICInfo[self]

                if info then
                    -- Static features
                    local oper  = info[FD_STAFTR] and info[FD_STAFTR][key]
                    if oper then oper:Set(self, value) return end

                    -- Try add methods
                    if type(value) == "function" then
                        interface.AddMethod(self, key, value, 3)
                        return
                    end
                end
            end

            error(strformat("The %s is readonly", tostring(self)), 2)
        end,
        __call      = function(self, init)
            local info  = _ICInfo[self]
            if type(init) == "string" then
                local ret, msg = struct.ValidateValue(Lambda, init)
                if msg then error(strformat("Usage: %s(init) - ", tostring(self)) .. (type(msg) == "string" and strgsub(msg, "%%s%.?", "init") or "the init is not valid."), 2) end
                init    = ret
            end

            if type(init) == "function" then
                if not info[FD_ONEVRM] then error(strformat("Usage: %s(init) - the interface isn't an one method required interface", tostring(self)), 2) end
                init    = { [info[FD_ONEVRM]] = init }
            end

            if init and type(init) ~= "table" then error(strformat("Usage: %s(init) - the init can only be lambda expression, function or table", tostring(self)), 2) end

            local aycls = info[FD_ANYMSCL]

            if not aycls then
                local r = getUniqueReqMethod(info)
                for k in pairs, r do r[k] = fakefunc end
                r[1]    = self
                aycls   = class(r, true)
                info[FD_ANYMSCL] = aycls
            end

            return aycls(init)
        end,
        __metatable = interface,
    })

    tclass          = prototype "tclass" (tinterface, {
        __newindex  = function(self, key, value)
            if type(key) == "string" then
                local info  = _ICInfo[self]

                if info then
                    -- Static features
                    local oper  = info[FD_STAFTR] and info[FD_STAFTR][key]
                    if oper then oper:Set(self, value) return end

                    -- Try add methods
                    if type(value) == "function" then
                        class.AddMethod(self, key, value, 3)
                        return
                    end
                end
            end

            error(strformat("The %s is readonly", tostring(self)), 2)
        end,
        __call      = function(self, ...)
            local info  = _ICInfo[self]
            local obj   = info[FD_CTOR](...)
            return obj
        end,
        __metatable = class,
    })

    tSuperInterface = prototype "tSuperInterface" {
        __index     = function(self, key)
            local t = type(key)

            if t == "string" then
                local obj = _SuperObj[self]
                if obj then
                    _SuperObj[self] = nil
                    local info  = getTargetInfo(getmetatable(obj))
                    if not info then error("Usage: Super[obj].Method(obj, [...]) - Can't figure out the obj's class", 2) end
                    return getSuperMethod(info, key, _SuperMap[self])
                else
                    local info  = _ICInfo[_SuperMap[self]]
                    if not info then error("Usage: Super.Method(obj, [...]) - Can't figure out the type that the super represent", 2) end
                    local f     = info[FD_SUPCACH][key]
                    if not f then
                        if META_KEYS[key] then
                            f   = getSuperMetaMethod(info, key)
                        else
                            f   = getSuperMethod(info, key) or getSuperFeature(info, key)
                        end
                        info[FD_SUPCACH][key] = f
                    end
                    if type(f) ~= "function" then error(strformat("No method named %q can be find in Super", key), 2) end
                    return f
                end
            elseif t == "table" then
                _SuperObj[self] = key
                return self
            end
        end,
        __newindex  = function(self, key, value)
            if type(key) == "string" then
                local obj = _SuperObj[self]
                if not obj then error("Usage: Super[obj].PropA = value", 2) end
                _SuperObj[self] = nil
            end
        end,
        __metatable = interface,
    }

    tSuperClass     = prototype "tSuperClass" (tSuperInterface, {
        __call      = function(self, obj, ...)

        end,
        __metatable = class,
    })

    tThisClass      = prototype "tThisClass" {
        __call      = function(self, obj, ...)

        end,
        __metatable = class,
    }

    interfacebuilder= prototype "interfacebuilder" {
        __index     = function(self, key)
            local val, cache = getBuilderValue(self, key)

            -- Access methods
            local info  = getTargetInfo(environment.GetNameSpace(self))
            local m     = info and (info[name] or info[FD_TYPMTD] and info[FD_TYPMTD][name])
            if m then return m, true end
            return environment.GetValue(self, name)
            if val ~= nil and cache and not _BDInfo[environment.GetNameSpace(self)] then
                rawset(self, key, val)
            end
            return val
        end,
        __newindex  = function(self, key, value)
            local owner = environment.GetNameSpace(self)
            if _BDInfo[owner] then
                if setBuilderOwnerValue(owner, key, value, 3) then
                    return
                end
            end
            return rawset(self, key, value)
        end,
        __call      = function(self, ...)
            local definition, stack = GetDefinitionParams(self, ...)
            if not definition then error("Usage: struct([env, ][name, ][stack]) (definition) - the definition is missing", stack) end

            local owner = environment.GetNameSpace(self)
            if not owner then error("The struct's definition is finished", stack) end

            stack = stack + 1

            if type(definition) == "function" then
                definition(self)
            else
                -- Index key first
                for i, v in ipairs, definition, 0 do
                    setBuilderOwnerValue(owner, i, v, stack)
                end

                for k, v in pairs, definition do
                    if type(k) == "string" then
                        setBuilderOwnerValue(owner, k, v, stack, true)
                    end
                end
            end

            setfenv(stack - 1, environment.GetParent(self) or _G)
            struct.EndDefinition(owner, stack)

            return owner
        end,
    }

    classbuilder    = prototype "classbuilder" ( interfacebuilder, {

    })

    typefeature     = prototype "typefeature" {
        __index     = {
            ["New"]             = function(owner, name, definition, stack)
            end;
            ["Validate"]        = function(feature)
            end;
            ["ApplyAttributes"] = function(feature, owner, name, ...)
            end;
        },
        __newindex  = readOnly
    }
end

-------------------------------------------------------------------------------
--                                   event                                   --
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                         attribute targets                         --
    -----------------------------------------------------------------------
    ATTRIBUTE_TARGETS_EVENT     = attribute.RegisterTargetType("Event", true)

    -----------------------------------------------------------------------
    --                         private variables                         --
    -----------------------------------------------------------------------
    local _EvtInfo  = setmetatable({}, WEAK_KEY)

    local FD_NAME   = 0
    local FD_OWNER  = 1
    local FD_STATIC = 2
    local FD_INDEF  = 3

    -- Key feature : event "Name"
    event           = prototype "event" (typefeature, {
        __index     = {
            ["BeginDefinition"] = function(owner, name, definition, super, stack)
                local evt       = prototype "name" (tevent)
                _EvtInfo[evt]   = setmetatable({ [FD_NAME] = name, [FD_OWNER] = owner, [FD_INDEF] = true }, WEAK_KEY)

                attribute.ConsumeAttributes(evt, ATTRIBUTE_TARGETS_EVENT, owner, name, stack + 1)
                attribute.ApplyAttributes  (evt, ATTRIBUTE_TARGETS_EVENT, nil, owner, name, super)

                return evt
            end;

            ["EndDefinition"]   = function(feature, owner, name)
                attribute.ApplyAfterDefine (feature, ATTRIBUTE_TARGETS_EVENT, owner, name)

                local info      = _EvtInfo[feature]
                if info then info[FD_INDEF] = nil end
            end;

            ["GetFeature"]      = function(feature) return feature end;

            ["Invoke"]          = function(feature, obj, ...)
                local info      = _EvtInfo[feature]
                local handler   = info and info[obj]
                if handler then

                end
            end;

            ["IsStatic"]        = function(feature)
                local info      = _EvtInfo[feature]
                return info and info[FD_STATIC] or false
            end;

            ["SetStatic"]       = function(feature, stack)
                stack           = type(stack) == "number" and stack or 2
                local info      = _EvtInfo[feature]
                if info then
                    if info[FD_INDEF] then
                        info[FD_STATIC] = true
                    elseif not info[FD_STATIC] then
                        error("Usage: event.SetStatic(event[, stack]) - The event's definition is finished", stack)
                    end
                else
                    error("Usage: event.SetStatic(event[, stack]) - The event object is not valid", stack)
                end
            end;

            ["Validate"]        = function(feature)
                return _EvtInfo[feature] and feature or nil
            end;
        },
        __call      = function(self, ...)
            if self == event then
                local env, name, definition, flag, stack, owner, tarenv = GetFeatureParams(event, ...)
                if not owner or not tarenv then error([[Usage: event "name" - can't be used here.]], stack) end
                if type(name) ~= "string" then error([[Usage: event "name" - the name must be a string.]], stack) end
                name = strtrim(name)
                if name == "" then error([[Usage: event "name" - the name can't be an empty string.]], stack) end

                getmetatable(owner).AddFeature(owner, event, name, definition, stack + 1)
            else
                error([[Usage: event "name" - can only be used by event command.]], stack)
            end
        end;
    })

    tevent          = prototype "tevent" {
        __call      = event.Invoke,
    }
end

-------------------------------------------------------------------------------
--                                 property                                  --
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                         attribute targets                         --
    -----------------------------------------------------------------------
    ATTRIBUTE_TARGETS_PROPERTY  = attribute.RegisterTargetType("Property", true)

    -----------------------------------------------------------------------
    --                         private variables                         --
    -----------------------------------------------------------------------

    -----------------------------------------------------------------------
    --                             property                              --
    -----------------------------------------------------------------------
    -- Key feature : property "Name" { Type = String, Default = "Anonymous" }
    property        = prototype "property" {
        __index     = {
            ["New"]             = function(self, owner, name)

            end;

            ["GetFeature"]      = function(feature) return nil end;
        },
        __call      = function(self, ...)
            if self == property then
                local env, name, definition, flag, stack, owner, tarenv = GetFeatureParams(property, ...)
                if not owner or not tarenv then error([[Usage: property "name" {...} - can't be used here.]], stack) end
                if type(name) ~= "string" then error([[Usage: property "name" {...} - the name must be a string.]], stack) end
                name = strtrim(name)
                if name == "" then error([[Usage: property "name" {...} - the name can't be an empty string.]], stack) end

                if definition then
                    if type(definition) ~= "table" then error([[Usage: property ("name", {...}) - the definition must be a table.]], stack) end
                    getmetatable(owner).AddFeature(owner, property, name, definition, stack + 1)
                else
                    return prototype.NewObject(property, { name = name, owner = owner })
                end
            else
                local owner, name       = self.owner, self.name
                local definition, stack = GetDefinitionParams(self, ...)

                if type(name) ~= "string" then error([[Usage: property "name" {...} - the name must be a string.]], stack) end
                name = strtrim(name)
                if name == "" then error([[Usage: property "name" {...} - the name can't be an empty string.]], stack) end
                if type(definition) ~= "table" then error([[Usage: property ("name", {...}) - the definition must be a table.]], stack) end

                getmetatable(owner).AddFeature(owner, property, name, definition, stack + 1)
            end
        end,
    }

    tproperty       = prototype "tproperty" { __metatable = property }
end

-------------------------------------------------------------------------------
--                           Feature Installation                            --
-------------------------------------------------------------------------------
do
    environment.RegisterContextKeyword(structbuilder, {
        import          = import,
        member          = member,
        endstruct       = endstruct,
        enum            = enum,
        struct          = struct,
        class           = class,
        interface       = interface,
    })

    environment.RegisterContextKeyword(interfacebuilder, {
        import          = import,
        --extend          = extend,
        event           = event,
        property        = property,
        --endinterface    = endinterface,
        enum            = enum,
        struct          = struct,
        class           = class,
        interface       = interface,
    })

    environment.RegisterContextKeyword(classbuilder, {
        import          = import,
        --inherit         = inherit,
        --extend          = extend,
        event           = event,
        property        = property,
        --endclass        = endclass,
        enum            = enum,
        struct          = struct,
        class           = class,
        interface       = interface,
    })

    _G.PLoop = prototype "PLoop" {
        __index = {
            namespace   = namespace,
            enum        = enum,
            import      = import,
            environment = environment,
        }
    }

    _G.namespace        = namespace
    _G.enum             = enum
    _G.import           = import
    _G.struct           = struct
end

return ROOT_NAMESPACE