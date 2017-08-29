--===========================================================================--
-- Copyright (c) 2011-2017 WangXH <kurapica125@outlook.com>                  --
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
-- @todo : return the root namespace
-- @todo : avoid consume attribute when not needed
-- @todo : no default value of base structs
-- @todo : bind debug info with object's creation
-- @todo : raise error when got nil in definition env
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2017/04/02                                               --
-- Update Date  :   2017/07/17                                               --
-- Version      :   a001                                                     --
--===========================================================================--
newproxy = nil

-------------------------------------------------------------------------------
--                          Environment Preparation                          --
-------------------------------------------------------------------------------
do
    local _G, rawset    = _G, rawset
    local _PLoopEnv     = setmetatable({}, { __index = function(self, k) local v = _G[k] if v == nil then error(("Global variable %q can't be found."):format(k), 2) end rawset(self, k, v) return v end, __metatable = true })
    _PLoopEnv._PLoopEnv = _PLoopEnv
    if setfenv then setfenv(1, _PLoopEnv) else _ENV = _PLoopEnv end

    -- Common features
    ipairs              = ipairs(_PLoopEnv)
    pairs               = pairs (_PLoopEnv)

    strlen              = string.len
    strformat           = string.format
    strfind             = string.find
    strsub              = string.sub
    strbyte             = string.byte
    strchar             = string.char
    strrep              = string.rep
    strgsub             = string.gsub
    strupper            = string.upper
    strlower            = string.lower
    strtrim             = function(s) return s and (s:gsub("^%s*(.-)%s*$", "%1")) or "" end

    wipe                = function(t) for k in pairs, t do t[k] = nil end return t end
    unpack              = table.unpack or unpack
    tblconcat           = table.concat
    tinsert             = table.insert
    tremove             = table.remove
    sort                = table.sort
    floor               = math.floor
    mlog                = math.log
    mabs                = math.abs

    create              = coroutine.create
    resume              = coroutine.resume
    running             = coroutine.running
    status              = coroutine.status
    wrap                = coroutine.wrap
    yield               = coroutine.yield

    setmetatable        = setmetatable
    getmetatable        = getmetatable

    -- In lua 5.2, the loadstring is deprecated
    loadstring          = _G.loadstring or load
    loadfile            = loadfile

    -- Use false as value so we'll rebuild them in the helper section
    newproxy            = _G.newproxy or false
    setfenv             = _G.setfenv or false
    getfenv             = _G.getfenv or false
    pcall               = pcall
end

-------------------------------------------------------------------------------
--                              CONST VARIABLES                              --
-------------------------------------------------------------------------------
do
    LUA_VERSION                     = tonumber(_G._VERSION:match("[%d%.]+")) or 5.1

    WEAK_KEY                        = { __mode = "k"  }
    WEAK_VALUE                      = { __mode = "v"  }
    WEAK_ALL                        = { __mode = "kv" }

    -- ATTRIBUTE TARGETS
    ATTRIBUTE_TARGETS_ALL           = 0
    ATTRIBUTE_TARGETS_ENUM          = 2^0
    ATTRIBUTE_TARGETS_STRUCT        = 2^1
    ATTRIBUTE_TARGETS_INTERFACE     = 2^2
    ATTRIBUTE_TARGETS_CLASS         = 2^3
    ATTRIBUTE_TARGETS_FUNCTION      = 2^4
    ATTRIBUTE_TARGETS_METHOD        = 2^5
    ATTRIBUTE_TARGETS_METAMETHOD    = 2^6
    ATTRIBUTE_TARGETS_CONSTRUCTOR   = 2^7
    ATTRIBUTE_TARGETS_EVENT         = 2^8
    ATTRIBUTE_TARGETS_PROPERTY      = 2^9
    ATTRIBUTE_TARGETS_MEMBER        = 2^10
    ATTRIBUTE_TARGETS_NAMESPACE     = 2^11

    -- ATTRIBUTE APPLY PHASE
    ATTRIBUTE_APPLYPH_BEFOREDEF     = 2^0
    ATTRIBUTE_APPLYPH_AFTERDEF      = 2^1
end

-------------------------------------------------------------------------------
--                                  Helper                                   --
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                     Cache Manager For Threads                     --
    -----------------------------------------------------------------------
    _Cache      = setmetatable({}, {
        __mode  = "k",
        __index = function(self, thd)
            self[thd] = setmetatable({}, WEAK_VALUE)
            return rawget(self, thd)
        end,
        __call  = function(self, tbl)
            if tbl then
                return tinsert(self[running() or 0], wipe(tbl))
            else
                return tremove(self[running() or 0]) or {}
            end
        end,
    })

    -----------------------------------------------------------------------
    --                               Clone                               --
    -----------------------------------------------------------------------
    local function deepClone(cache, src, tar, override)
        cache[src] = tar
        for k, v in pairs, src do
            if override or tar[k] == nil then
                if type(v) == "table" and getmetatable(v) == nil then
                    tar[k] = cache[v] or deepClone(cache, v, {}, override)
                else
                    tar[k] = v
                end
            elseif type(v) == "table" and type(tar[k]) == "table" and getmetatable(v) == nil and getmetatable(tar[k]) == nil then
                deepClone(cache, v, tar[k], override)
            end
        end
        return tar
    end

    function tblclone(src, tar, deep, override)
        if src then
            if deep then
                local cache = _Cache()
                deepClone(cache, src, tar, override)
                _Cache(cache)
            else
                for k, v in pairs, src do
                    if override or tar[k] == nil then tar[k] = v end
                end
            end
        end
        return tar
    end

    function clone(src, deep)
        if type(src) == "table" and getmetatable(src) == nil then
            return tblclone(src, {}, deep)
        else
            return src
        end
    end

    -----------------------------------------------------------------------
    --                               Equal                               --
    -----------------------------------------------------------------------
    local function checkEqual(t1, t2, cache)
        if t1 == t2 then return true end
        if type(t1) ~= "table" or type(t2) ~= "table" then return false end

        if cache[t1] == t2 then return true end

        -- They should handle the __eq by themselves, no more checking
        if getmetatable(t1) ~= nil or getmetatable(t2) ~= nil then return false end

        -- Check fields
        for k, v in pairs, t1 do if not checkEqual(v, t2[k], cache) then return false end end
        for k, v in pairs, t2 do if t1[k] == nil then return false end end

        cache[t1] = t2

        return true
    end

    function isEqual(t1, t2)
        if t1 == t2 then return true end
        if type(t1) ~= "table" or type(t2) ~= "table" then return false end

        local cache = _Cache()
        local result= checkEqual(t1, t2, cache)
        _Cache(cache)
        return result
    end

    -----------------------------------------------------------------------
    --                          Loading Snippet                          --
    -----------------------------------------------------------------------
    if LUA_VERSION > 5.1 then
        function loadSnippet(chunk, source, env)
            return loadstring(chunk, source, nil, env or _PLoopEnv)
        end
    else
        function loadSnippet(chunk, source, env)
            -- print("--------------" .. source .. "-----------")
            -- print(chunk)
            local v, err = loadstring(chunk, source)
            if v then setfenv(v, env or _PLoopEnv) else print("Loading error", err) end
            return v, err
        end
    end

    -----------------------------------------------------------------------
    --                         Flags Management                          --
    -----------------------------------------------------------------------
    if LUA_VERSION >= 5.3 then
        validateFlags = loadstring [[
            return function(checkValue, targetValue)
                return (checkValue & (targetValue or 0)) > 0
            end
        ]] ()

        turnOnFlags = loadstring [[
            return function(checkValue, targetValue)
                return checkValue | (targetValue or 0)
            end
        ]] ()

        turnOffFlags = loadstring [[
            return function(checkValue, targetValue)
                return (~checkValue) & (targetValue or 0)
            end
        ]] ()
    elseif (LUA_VERSION == 5.2 and type(_G.bit32) == "table") or (LUA_VERSION == 5.1 and type(_G.bit) == "table") then
        local band  = _G.bit32 and bit32.band or bit.band
        local bor   = _G.bit32 and bit32.bor  or bit.bor
        local bnot  = _G.bit32 and bit32.bnot or bit.bnot

        function validateFlags(checkValue, targetValue)
            return band(checkValue, targetValue or 0) > 0
        end

        function turnOnFlags(checkValue, targetValue)
            return bor(checkValue, targetValue or 0)
        end

        function turnOffFlags(checkValue, targetValue)
            return band(bnot(checkValue), targetValue or 0)
        end
    else
        function validateFlags(checkValue, targetValue)
            if not targetValue or checkValue > targetValue then return false end
            targetValue = targetValue % (2 * checkValue)
            return (targetValue - targetValue % checkValue) == checkValue
        end

        function turnOnFlags(checkValue, targetValue)
            if not validateFlags(checkValue, targetValue) then
                return checkValue + (targetValue or 0)
            end
            return targetValue
        end

        function turnOffFlags(checkValue, targetValue)
            if validateFlags(checkValue, targetValue) then
                return targetValue - checkValue
            end
            return targetValue
        end
    end

    -----------------------------------------------------------------------
    --                             newproxy                              --
    -----------------------------------------------------------------------
    newproxy = newproxy or (function ()
        local falseMeta = { __metatable = false }
        local _proxymap = setmetatable({}, WEAK_ALL)

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

    readOnly = function() error("This is readonly", 2) end

    typeconcat  = function(a, b) return tostring(a) .. tostring(b) end

    -----------------------------------------------------------------------
    --                        Environment Control                        --
    -----------------------------------------------------------------------
    if not setfenv then
        if not debug and require then pcall(require, "debug") end
        if debug and debug.getinfo and debug.getupvalue and debug.upvaluejoin and debug.getlocal then
            local getinfo       = debug.getinfo
            local getupvalue    = debug.getupvalue
            local upvaluejoin   = debug.upvaluejoin
            local getlocal      = debug.getlocal

            function setfenv(f, t)
                f = type(f) == 'function' and f or getinfo(f + 1, 'f').func
                local up, name = 0
                repeat
                    up = up + 1
                    name = getupvalue(f, up)
                until name == '_ENV' or name == nil
                if name then upvaluejoin(f, up, function() return t end, 1) end
            end

            function getfenv(f)
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
            getfenv = function () end
            setfenv = function () end
        end
    end

    -----------------------------------------------------------------------
    --                        Get Info For Types                         --
    -----------------------------------------------------------------------
    function getDefaultValue(ns)
        local meta = getmetatable(ns)
        if meta == enum or meta == struct then
            return meta.GetDefault(ns)
        end
    end

    function getValidate(ns)
        if namespace.IsFeatureType(ns) then
            return getmetatable(ns).ValidateValue
        end
    end

    function fakefunc() end
end

-------------------------------------------------------------------------------
--                             Prototype System                              --
--                                                                           --
--  In the prototype system, there are two type features defined by it :     --
--                                                                           --
--  * userdata as prototype with Inheritable meta-table settings             --
--  * table as object with same meta-table setting from the prototype        --
--                                                                           --
--  I can't say the userdata is the class, the object is the class object.   --
--  They are designed to serve different purposes under several conditions.  --
--                                                                           --
-------------------------------------------------------------------------------
do
    local _Prototype = setmetatable({}, WEAK_ALL)

    local function newPrototype(super, meta)
        if not _Prototype[super] then meta, super = super, nil end
        if type(meta) ~= "table" then meta        = nil        end

        local prototype       = newproxy(true)
        local pmeta           = getmetatable(prototype)
        _Prototype[prototype] = pmeta

        if meta then tblclone(meta, pmeta, true, true) end
        if pmeta.__metatable == nil then pmeta.__metatable = prototype end
        if super then tblclone(_Prototype[super], pmeta, true, false) end

        return prototype
    end

    -- Root Prototype
    Prototype = newPrototype {
        __index     = {
            ["NewPrototype"] = newPrototype,
            ["NewProxy"]     = newproxy,
            ["NewObject"]    = function(prototype, tbl) return setmetatable(tbl or {}, _Prototype[prototype]) end,
            ["Validate"]     = function(prototype) return _Prototype[prototype] and prototype or nil end,
        },
        __newindex  = readOnly,
    }
end

-------------------------------------------------------------------------------
--                              Tool Prototype                               --
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                         Cache For Threads                         --
    -----------------------------------------------------------------------
    local function getCache(self, readonly)
        local th    = running() or 0
        local cache = rawget(self, th)
        if not cache and not readonly then
            cache = setmetatable({}, WEAK_KEY)
            rawset(self, th, cache)
        end
        return cache
    end

    threadCache = Prototype:NewPrototype {
        __mode      = "k",
        __index     = function(self, key) local c = getCache(self, true) return c and c[key] end,
        __newindex  = function(self, key, value) getCache(self)[key] = value end,
        __call      = getCache,
    }
end

-------------------------------------------------------------------------------
--                               Platform APIs                               --
--                                                                           --
-- There are APIS like lock & release that would be provided by the platform.--
-- Here are some fake or default functions that should be replaced.          --
-------------------------------------------------------------------------------
do
    _PlatFormAPI    = {
        ---------------------------------------------------------------------
        --                         Thread Lock(Fake)                       --
        --                                                                 --
        -- The pure lua run all coroutine in one thread, so normally there --
        -- is no need to lock & release.                                   --
        --                                                                 --
        -- But in some conditions like a web service, there would be many  --
        -- OS threads running, so we need true lock & release.             --
        ---------------------------------------------------------------------
        lock        = function(lockObj, timeout, expiration) return true end;
        release     = function(lockObj) return true end;
    }

    local lockCache = Prototype.NewObject(threadCache)

    function Lock(lockObj, timeout, expiration)
        if lockObj == nil then error("Usage : Lock(lockObj[, timeout[, expiration]]) - the lock object can't be nil.", 2) end

        local cache     = lockCache()
        if cache[lockObj] then error("Usage : Lock(lockObj[, timeout[, expiration]]) - The lock object is used", 2) end
        local apis      = _PlatFormAPI
        cache[lockObj]  = apis

        return apis.lock(lockObj, timeout, expiration)
    end

    function Release(lockObj)
        if lockObj == nil then error("Usage : Release(lockObj) - lockObj can't be nil.", 2) end

        local cache     = lockCache()
        local apis      = cache[lockObj]
        cache[lockObj]  = nil
        if apis then
            return apis.release(lockObj)
        end
    end
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
--      The apply phase of the attribute: 1 - Before the definition of the   --
--  feature, 2 - After the definition of the feature, 3 - in both phase.     --
--                                                                           --
-- * Overridable                                                             --
--      Whether the attribute's saved data is overridable.                   --
--                                                                           --
-- * ApplyAttribute                                                          --
--      The method used to apply the attribute to the target feature.        --
--                                                                           --
-- * Priorty                                                                 --
--      The attribute's priority, the bigger the first to be  applied.        --
--                                                                           --
-- * SubLevel                                                                --
--      The priority's sublevel, for attributes with same priority, the bigger --
--  sublevel the first be applied.                                           --
--                                                                           --
-------------------------------------------------------------------------------
do
    -- Save Data for features
    local _AttrInfo = setmetatable({}, WEAK_KEY)
    local _InrtInfo = setmetatable({}, WEAK_KEY)

    -- Temporary Cache
    local _PreAttrs = Prototype.NewObject(threadCache)
    local _TarAttrs = Prototype.NewObject(threadCache)
    local _FinAttrs = Prototype.NewObject(threadCache)
    local _IgnrTars = Prototype.NewObject(threadCache)

    local function getAttributeUsage(attr)
        local info  = _AttrInfo[getmetatable(attr)]
        return info and info[attribute]
    end

    local function getField(obj, field, default, chkType)
        local val   = obj and obj[field]
        if val ~= nil and (not chkType or type(val) == chkType) then return val end
        return default
    end

    local function getAttributeInfo(attr, field, default, chkType)
        local val   = getField(attr, field, nil, chkType)
        if val == nil then val = getField(getAttributeUsage(attr), field, nil, chkType) end
        if val ~= nil then return val end
        return default
    end

    local function addAttribtue(list, attr, noSameType)
        for _, v in ipairs, list, 0 do
            if v == attr then return end
            if noSameType and getmetatable(v) == getmetatable(attr) then return end
        end

        local idx       = 1
        local priority  = getAttributeInfo(attr, "Priorty", 0, "number")
        local sublevel  = getAttributeInfo(attr, "SubLevel", 0, "number")

        while list[idx] do
            local patr  = list[idx]
            local pprty = getAttributeInfo(patr, "Priorty", 0, "number")
            local psubl = getAttributeInfo(patr, "SubLevel", 0, "number")

            if priority > pprty or (priority == pprty and sublevel > psubl) then break end
            idx = idx + 1
        end

        tinsert(list, idx, attr)
    end

    attribute       = Prototype.NewPrototype {
        __index     = {
            -- Apply the registered attributes to the feature
            -- @target          - the target feature
            -- @targetType      - the target's type
            -- @applyTarget     - the apply target, use the target if nil
            -- @owner           - the target's owner
            -- @name            - the target's name
            -- @...             - the target's super features, used for inheritance
            ["ApplyAttributes"] = function(target, targetType, applyTarget, owner, name, ...)
                local tarAttrs  = _TarAttrs[target]
                if tarAttrs then
                    _TarAttrs[target] = nil
                else
                    tarAttrs    = _Cache()
                end

                local extAttrs  = tblclone(_AttrInfo[target], _Cache())
                local extInhrt  = tblclone(_InrtInfo[target], _Cache())

                applyTarget     = applyTarget or target

                -- Check inheritance
                for i = 1, select("#", ...) do
                    local super = select(i, ...)
                    if super and _InrtInfo[super] then
                        for _, sattr in pairs, _InrtInfo[super] do
                            -- No same type attribute allowed
                            local aTar = getAttributeInfo(sattr, "AttributeTarget", ATTRIBUTE_TARGETS_ALL, "number")

                            if aTar == ATTRIBUTE_TARGETS_ALL or validateFlags(targetType, aTar) then
                                addAttribtue(tarAttrs, sattr, true)
                            end
                        end
                    end
                end

                local finAttrs  = _Cache()
                local isMethod  = type(target) == "function"
                local newAttrs  = false
                local newInhrt  = false

                -- Apply the attribute to the target
                for i, attr in ipairs, tarAttrs, 0 do
                    local aType = getmetatable(attr)
                    local aPhse = getAttributeInfo(attr, "ApplyPhase", ATTRIBUTE_APPLYPH_BEFOREDEF, "number")
                    local apply = getAttributeInfo(attr, "ApplyAttribute", nil, "function")
                    local ovrd  = getAttributeInfo(attr, "Overridable", true)
                    local inhr  = getAttributeInfo(attr, "Inheritable", false)

                    -- Save for next phase
                    if validateFlags(ATTRIBUTE_APPLYPH_AFTERDEF, aPhse) then tinsert(finAttrs, attr) end

                    -- Apply attribute before the definition
                    if validateFlags(ATTRIBUTE_APPLYPH_BEFOREDEF, aPhse) and (ovrd or (extAttrs[aType] == nil and extInhrt[aType] == nil)) then
                        if apply then
                            local ret = apply(attr, applyTarget, targetType, owner, name, ATTRIBUTE_APPLYPH_BEFOREDEF)

                            if ret ~= nil then
                                if isMethod and type(ret) == "function" then
                                    applyTarget = ret
                                else
                                    extAttrs[aType] = ret
                                    newAttrs        = true
                                end
                            end
                        end

                        if inhr then
                            extInhrt[aType] = attr
                            newInhrt        = true
                        end
                    end
                end

                _Cache(tarAttrs)

                -- Save the after definition attributes
                if next(finAttrs) then _FinAttrs[target] = finAttrs else _Cache(finAttrs) end

                -- Save attribute save datas
                if newAttrs then _AttrInfo[target] = extAttrs else _Cache(extAttrs) end
                if newInhrt then _InrtInfo[target] = extInhrt else _Cache(extInhrt) end

                return isMethod and applyTarget or target
            end;

            -- Apply the after-definition attributes to the feature
            -- @target          - the target feature
            -- @targetType      - the target's type
            -- @applyTarget     - the apply target, use the target if nil
            -- @owner           - the target's owner(may be itself)
            -- @name            - the target's name
            ["ApplyAfterDefine"]= function(target, targetType, applyTarget, owner, name)
                local finAttrs  = _FinAttrs[target]
                if not finAttrs then return else _FinAttrs[target] = nil end

                local extAttrs  = tblclone(_AttrInfo[target], _Cache())
                local extInhrt  = tblclone(_InrtInfo[target], _Cache())
                local newAttrs  = false
                local newInhrt  = false

                applyTarget     = applyTarget or target

                -- Apply the attribute to the target
                for i, attr in ipairs, finAttrs, 0 do
                    local aType = getmetatable(attr)
                    local apply = getAttributeInfo(attr, "ApplyAttribute", nil, "function")
                    local ovrd  = getAttributeInfo(attr, "Overridable", true)
                    local inhr  = getAttributeInfo(attr, "Inheritable", false)

                    if ovrd or (extAttrs[aType] == nil and extInhrt[aType] == nil) then
                        if apply then
                            local ret = apply(attr, applyTarget, targetType, owner, name, ATTRIBUTE_APPLYPH_AFTERDEF)

                            if ret ~= nil and type(ret) ~= "function" then
                                extAttrs[aType] = ret
                                newAttrs        = true
                            end
                        end

                        if inhr then
                            extInhrt[aType] = attr
                            newInhrt        = true
                        end
                    end
                end

                _Cache(finAttrs)

                -- Save attribute save datas
                if newAttrs then _AttrInfo[target] = extAttrs else _Cache(extAttrs) end
                if newInhrt then _InrtInfo[target] = extInhrt else _Cache(extInhrt) end
            end;

            -- Clear all registered attributes
            ["Clear"]           = function()
                wipe(_PreAttrs())
            end;

            ["ConsumeAttributes"] = function(target, targetType, stack)
                if _IgnrTars[target] then _IgnrTars[target] = nil return end
                if _IgnrTars[0]      then return end

                local preAttrs  = _PreAttrs()
                local tarAttrs  = _Cache()

                -- Apply the attribute to the target
                for i, attr in ipairs, preAttrs, 0 do
                    local aTar  = getAttributeInfo(attr, "AttributeTarget", ATTRIBUTE_TARGETS_ALL, "number")

                    if aTar ~= ATTRIBUTE_TARGETS_ALL and not validateFlags(targetType, aTar) then
                        attribute.Clear() _Cache(tarAttrs)
                        error(("The %s can't be applied to the feature."):format(tostring(getmetatable(attr))), stack)
                    end

                    tinsert(tarAttrs, attr)
                end

                wipe(preAttrs)

                -- Save the after definition attributes
                if next(tarAttrs) then _TarAttrs[target] = tarAttrs else _Cache(tarAttrs) end
            end;

            -- Get saved attribute data
            -- @target          - the target feature
            -- @attributeType   - the attribute's type
            ["GetAttributeData"]= function(target, aType)
                local info      = _AttrInfo[target]
                return info and clone(info[aType], true)
            end;

            ["IgnoreTarget"]    = function(target)
                if target and target ~= 0 then
                    _IgnrTars[target] = true
                end
            end;

            -- Register the attribute to be used by the next feature
            -- @attr        - The attribute to register.
            -- @noSameType  - Don't register the attribute if there is another attribute with the same type
            ["Register"]        = function(attr, noSameType)
                local attr      = attribute.Validate(attr)
                if not attr then error("Usage : attribute.Register(attr) - attr is not a valid attribute.", 2) end

                return addAttribtue(_PreAttrs(), attr, noSameType)
            end;

            -- Register an attribute type with usage information
            ["RegisterType"]    = function(aType, usage)
                if _AttrInfo[aType] and _AttrInfo[aType][attribute] and _AttrInfo[aType][attribute].Final then return end

                local extAttrs  = tblclone(_AttrInfo[aType], _Cache())
                local attrusage = _Cache()

                -- Default usage data for attributes
                attrusage.AttributeTarget   = getField(usage, "AttributeTarget", ATTRIBUTE_TARGETS_ALL, "number")
                attrusage.Inheritable       = getField(usage, "Inheritable", false)
                attrusage.ApplyPhase        = getField(usage, "ApplyPhase", ATTRIBUTE_APPLYPH_BEFOREDEF, "number")
                attrusage.Overridable       = getField(usage, "Overridable", true)
                attrusage.ApplyAttribute    = getField(usage, "ApplyAttribute", nil, "function")
                attrusage.Priorty           = getField(usage, "Priorty",  0, "number")
                attrusage.SubLevel          = getField(usage, "SubLevel", 0, "number")

                -- A special data for attribute usage, so the attribute usage won't be overridden
                attrusage.Final             = getField(usage, "Final", false)

                extAttrs[attribute]         = attrusage
                _AttrInfo[aType]            = extAttrs
            end;

            ["ResumeConsume"]   = function()
                _IgnrTars[0]    = false
            end;

            ["SuspendConsume"]  = function()
                _IgnrTars[0]    = true
            end;

            -- Un-register attribute
            ["Unregister"]      = function(attr)
                local pres      = _PreAttrs()
                for i, v in ipairs, pres, 0 do
                    if v == attr then
                        return tremove(pres, i)
                    end
                end
            end;

            -- Validate whether the target is an attribute
            ["Validate"]        = function(attr)
                return getAttributeUsage(attr) and attr or nil
            end;
        },
        __newindex  = readOnly,
    }
end

-------------------------------------------------------------------------------
--                                typebuilder                                --
-------------------------------------------------------------------------------
do
    local _BDKeys   = {}                                -- Builder Type info
    local _BDOwner  = setmetatable({}, WEAK_ALL)        -- Builder -> Owner
    local _BDEnv    = setmetatable({}, WEAK_KEY)        -- Builder -> Base environment
    local _BDIDef   = setmetatable({}, WEAK_KEY)        -- Builder -> In definition mode
    local _TPInfo   = Prototype.NewObject(threadCache)   -- Type   -> Builder(As environment)

    typebuilder  = Prototype.NewPrototype {
        __index     = {
            ["EndDefinition"]       = function(builder, stack)
                _BDIDef[builder]    = nil

                if stack and _BDEnv[builder] then setfenv(stack, _BDEnv[builder]) end

                return _BDOwner[builder]
            end;

            ["GetBuilderParams"]    = function(builder, ...)
                local definition, stack

                for i = 1, select('#', ...) do
                    local v = select(i, ...)
                    local t = type(v)

                    if t == "number" then
                        stack = stack or v
                    elseif t == "string" or t == "table" or t == "function" then
                        definition  = definition or v
                    end
                end

                stack = stack or 2

                if type(definition) == "string" then
                    local def, msg  = loadSnippet("return function(_ENV)\n" .. definition .. "\nend", nil, _BDEnv[builder] or _G)
                    if def then
                        def, msg    = pcall(def)
                        if def then
                            definition = msg
                        else
                            error(msg, stack + 1)
                        end
                    else
                        error(msg, stack + 1)
                    end
                end

                return definition, stack
            end;

            -- Used for features like property, event, member and namespace
            ["GetNewFeatureParams"] = function(ftype, ...)
                local env, name, definition, stack
                local builder       = _TPInfo[ftype]
                local owner         = builder and _BDOwner[builder]

                if builder then _TPInfo[ftype] = nil end

                for i = 1, select('#', ...) do
                    local v = select(i, ...)
                    local t = type(v)

                    if t == "number" then
                        stack = stack or v
                    elseif t == "string" then
                        name = name or v
                    elseif t == "table" then
                        if getmetatable(v) ~= nil or v == _G then
                            env = env or v
                        elseif not env then
                            if name then
                                definition = definition or v
                            else
                                env = env or v
                            end
                        else
                            definition = definition or v
                        end
                    end
                end

                stack = stack or 2

                env = env or getfenv(stack + 1) or builder or _G

                return env, name, definition, stack, owner, builder
            end;

            -- Used for types like enum, struct, class and interface : class([env,][name,][definition,][keepenv,][stack])
            ["GetNewTypeParams"]    = function(nType, prototype, ...)
                local env, target, definition, keepenv, stack
                local builder       = _TPInfo[nType]
                local owner         = builder and _BDOwner[builder]

                if builder then _TPInfo[nType] = nil end

                for i = 1, select('#', ...) do
                    local v = select(i, ...)
                    local t = type(v)

                    if t == "boolean" then
                        if keepenv == nil then keepenv = v end
                    elseif t == "number" then
                        stack = stack or v
                    elseif t == "function" then
                        definition = definition or v
                    elseif t == "string" then
                        if v:find("^[%w_%.]+$") then
                            target = target or v
                        else
                            definition = definition or v
                        end
                    elseif t == "userdata" then
                        if nType.Validate(v) then
                            target = target or v
                        end
                    elseif t == "table" then
                        if nType.Validate(v) then
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

                if not definition and env and not target then
                    -- Anonymous
                    definition, env = env, nil
                end

                env = env or getfenv(stack + 1) or builder or _G

                if type(definition) == "string" then
                    local def, msg  = loadSnippet("return function(_ENV)\n" .. definition .. "\nend", nil, env)
                    if def then
                        def, msg    = pcall(def)
                        if def then
                            definition = msg
                        else
                            error(msg, stack + 1)
                        end
                    else
                        error(msg, stack + 1)
                    end
                end

                -- Get or build the target
                if target then
                    if type(target) == "string" then
                        target = namespace.GenerateNameSpace(namespace.GetNameSpaceFromEnv(env), target, prototype)
                        rawset(env, namespace.GetNameSpaceName(target, true), target)
                    else
                        target = namespace.Validate(target)
                    end
                else
                    target = namespace.GenerateNameSpace(nil, nil, prototype)
                end

                return env, target, definition, keepenv or false, stack, owner, builder
            end;

            ["GetBuilderEnv"]       = function(builder)
                return _BDEnv[builder]
            end;

            ["GetBuilderOwner"]     = function(builder)
                return _BDOwner[builder]
            end;

            -- Get value for builder(__newindex) : value, cacheable
            ["GetValueFromBuidler"] = function(builder, name)
                if type(name) == "string" then
                    -- Get key features
                    local info      = _BDKeys[getmetatable(builder)]
                    local value     = info and info[name]
                    if value then
                        _TPInfo[value] = builder   -- so it'd be used as optional environment
                        return value, false
                    end

                    -- Get Namespace
                    value           = namespace.GetImportedFeature(builder, name)
                    if value then return value, true end
                end

                -- Get value from base environment
                return (_BDEnv[builder] or _G)[name], true
            end;

            ["InDefineMode"]        = function(builder)
                return _BDIDef[builder] and true or false
            end;

            ["NewBuilder"]          = function(btype, owner, env)
                local builder       = Prototype.Validate(btype) and Prototype.NewObject(btype) or btype

                _BDOwner[builder]   = owner
                if owner then
                    _BDIDef[builder]= true
                    namespace.SetNameSpaceToEnv(builder, owner)
                end

                _BDEnv[builder]     = env

                return builder
            end;

            ["RegisterKeyWord"]     = function(btype, key, keyword)
                _BDKeys[btype]      = _BDKeys[btype] or _Cache()
                if type(key) == "table" and getmetatable(key) == nil then
                    for k, v in pairs, key do
                        if type(k) == "string" and not _BDKeys[btype][k] and (type(v) == "function" or type(v) == "userdata" or type(v) == "table") then
                            _BDKeys[btype][k] = v
                        end
                    end
                else
                    if type(key) == "string" and not _BDKeys[btype][key] and (type(keyword) == "function" or type(keyword) == "userdata" or type(keyword) == "table") then
                        _BDKeys[btype][key] = keyword
                    end
                end
            end;
        },
        __newindex  = readOnly,
    }
end

-------------------------------------------------------------------------------
--                                 namespace                                 --
-------------------------------------------------------------------------------
do
    local _NSTree   = setmetatable({}, WEAK_KEY)
    local _NSName   = setmetatable({}, WEAK_KEY)
    local _NSMap    = setmetatable({}, WEAK_ALL)
    local _NSImp    = setmetatable({}, WEAK_KEY)

    local function getFeatureFromNS(ns, name)
        local nsname = _NSName[ns]
        if nsname ~= nil then
            if nsname and nsname:match("[_%w]+$") == name then return ns end
            return ns[name]
        end
    end

    namespace       = Prototype.NewPrototype {
        __index     = {
            -- Export a namespace and its children to an environment
            ["ExportNameSpaceToEnv"]= function(env, ns)
                ns = namespace.Validate(ns)
                if type(env) ~= "table" then error("Usage: namespace.ExportNameSpaceToEnv(env, namespace) - env must be a table.", 2) end
                if not ns then error("Usage: namespace.ExportNameSpaceToEnv(env, namespace) - The namespace is not provided.", 2) end

                local nsname = _NSName[ns]
                if nsname then
                    nsname = nsname:match("[_%w]+$")
                    if env[nsname] == nil then env[nsname] = ns end
                end

                if _NSTree[ns] then tblclone(_NSTree[ns], env) end
            end;

            -- Generate namespace by access name(if it is nil, anonymous namespace could be created)
            ["GenerateNameSpace"]   = function(parent, name, prototype)
                if type(parent) == "string" then name, prototype, parent = parent, name, nil end
                prototype = Prototype.Validate(prototype) or tnamespace

                if type(name) == "string" then
                    if parent ~= nil then
                        parent = namespace.Validate(parent)
                        if not parent then error("Usage: namespace.GenerateNameSpace([parent, ][name[, prototype]]) - parent must be a namespace.", 2) end
                        if not _NSName[parent] then error("Usage: namespace.GenerateNameSpace([parent, ][name[, prototype]]) - parent can't be anonymous.", 2) end
                    else
                        parent = ROOT_NAMESPACE
                    end

                    local ns    = parent
                    local iter  = name:gmatch("[_%w]+")
                    local sn    = iter()

                    while sn do
                        _NSTree[ns] = _NSTree[ns] or {}

                        local sns = _NSTree[ns][sn]
                        local nxt = iter()

                        if not sns then
                            Lock(ns)
                            sns = _NSTree[ns][sn]

                            if not sns then
                                sns = Prototype.NewProxy(nxt and tnamespace or prototype)
                                _NSName[sns] = _NSName[ns] and _NSName[ns] .. "." .. sn or sn
                                _NSTree[ns][sn] = sns
                            end

                            Release(ns)
                        end

                        ns, sn = sns, nxt
                    end

                    if ns ~= parent then return ns end
                    error("Usage: namespace.GenerateNameSpace([parent, ][name[, prototype]]) - name must be a string like 'System.Collections.List'.", 2)
                elseif name == nil then
                    local ns = Prototype.NewProxy(prototype)
                    _NSName[ns] = false
                    return ns
                else
                    error("Usage: namespace.GenerateNameSpace([parent, ][name[, prototype]]) - name must be a string or nil.", 2)
                end
            end;

            -- Get the namespace by name
            ["GetNameSpace"]        = function(parent, name)
                if type(parent) == "string" then name, parent = parent, nil end
                if type(name)   ~= "string" then error("Usage: namespace.GetNameSpace([parent, ]name) - name must be a string.", 2) end
                if parent ~= nil then
                    parent = namespace.Validate(parent)
                    if not parent then error("Usage: namespace.GetNameSpace([parent, ]name) - parent must be a namespace.", 2) end
                    if not _NSName[parent] then error("Usage: namespace.GetNameSpace([parent, ]name) - parent can't be anonymous.", 2) end
                else
                    parent = ROOT_NAMESPACE
                end
                local ns = parent
                for sn in name:gmatch("[_%w]+") do
                    ns = _NSTree[ns] and _NSTree[ns][sn]
                    if not ns then return nil end
                end
                return ns ~= parent and ns or nil
            end;

            -- Get the namespace from the environment
            ["GetNameSpaceFromEnv"] = function(env) return _NSMap[env] end;

            -- Get the namespace's name
            ["GetNameSpaceName"]    = function(ns, last)
                local name = _NSName[namespace.Validate(ns)]
                if name ~= nil then
                    return name and (last and name:match("[_%w]+$") or name) or "Anonymous"
                end
            end;

            -- Fetch feature for the environment based on env's namespace or imported namespace
            ["GetImportedFeature"]= function(env, name)
                if type(name) ~= "string" then return end

                local ns = _NSMap[env]
                if ns then
                    ns = getFeatureFromNS(ns, name)
                    if ns ~= nil then return ns end
                end

                if _NSImp[env] then
                    for _, ns in ipairs, _NSImp[env], 0 do
                        ns = getFeatureFromNS(ns, name)
                        if ns ~= nil then return ns end
                    end
                end

                -- Check root namespace
                return _NSTree[ROOT_NAMESPACE][name]
            end;

            -- Import namespace to env
            ["ImportNameSpaceToEnv"]= function(env, ns)
                ns = namespace.Validate(ns)
                if type(env) ~= "table" then error("Usage: namespace.ImportNameSpaceToEnv(env, namespace) - env must be a table.", 2) end
                if not ns then error("Usage: namespace.ImportNameSpaceToEnv(env, namespace) - The namespace is not provided.", 2) end

                local imports = _NSImp[env]
                if not imports then imports = setmetatable({}, WEAK_VALUE) _NSImp[env] = imports end
                for _, v in ipairs, imports, 0 do if v == ns then return end end
                tinsert(imports, ns)
            end;

            ["IsFeatureType"]       = function(ns)
                ns = namespace.Validate(ns)
                return ns and getmetatable(ns) ~= namespace or false
            end;

            -- Set the namespace to the environment
            ["SetNameSpaceToEnv"]   = function(env, ns)
                if type(env) ~= "table" then error("Usage: namespace.SetNameSpaceToEnv(env, namespace) - env must be a table.", 2) end
                _NSMap[env] = namespace.Validate(ns)
            end;

            -- Validate whether the arg is a namespace
            ["Validate"]            = function(ns)
                if type(ns) == "string" then ns = namespace.GetNameSpace(ns) end
                return _NSName[ns] ~= nil and ns or nil
            end;
        },
        __concat    = typeconcat,
        __tostring  = function() return "namespace" end,
        __newindex  = readOnly,
        __call      = function(self, ...)
            local env, name, _, stack = typebuilder.GetNewFeatureParams(namespace, ...)

            if not env  then error("Usage: namespace([env, ]name[, stack] - the system can't figure out the environment.", stack) end
            if not name then error("Usage: namespace([env, ]name[, stack] - name must be a string.", stack) end

            local ns = namespace.GetNameSpace(name)
            if not ns then
                -- Only apply attribute to new namespace
                ns = namespace.GenerateNameSpace(name)
                if ns then
                    attribute.ConsumeAttributes(ns, ATTRIBUTE_TARGETS_NAMESPACE, stack + 1)
                    attribute.ApplyAttributes  (ns, ATTRIBUTE_TARGETS_NAMESPACE)
                    attribute.ApplyAfterDefine (ns, ATTRIBUTE_TARGETS_NAMESPACE)
                end
            end

            return namespace.SetNameSpaceToEnv(env, ns)
        end,
    }

    tnamespace      = Prototype.NewPrototype {
        __index     = namespace.GetNameSpace,
        __newindex  = readOnly,
        __concat    = typeconcat,
        __tostring  = namespace.GetNameSpaceName,
        __metatable = namespace,
    }

    -- Init the root namespace, anonymous namespace can be be collected as garbage
    ROOT_NAMESPACE  = namespace.GenerateNameSpace()

    -- Key feature : import "System"
    import          = function (...)
        local env, name, _, stack, _, isbuilder = typebuilder.GetNewFeatureParams(import, ...)

        name = namespace.Validate(name)
        if not env then error("Usage: import(namespace) - The system can't figure out the environment.", stack) end
        if not name then error("Usage: import(namespace) - The namespace is not provided.", stack) end

        if isbuilder then
            namespace.ImportNameSpaceToEnv(env, name)
        else
            namespace.ExportNameSpaceToEnv(env, name)
        end
    end

    -- Set the namespace as System
    namespace (_PLoopEnv, "System")
end

-------------------------------------------------------------------------------
--                                enumeration                                --
-------------------------------------------------------------------------------
do
    local _EnumInfo = setmetatable({}, WEAK_KEY)
    local _BDInfo   = Prototype.NewObject(threadCache)

    local _ValidMap = {}

    -- FEATURE MODIFIER
    local MD_SEAL   = 2^0   -- SEALED
    local MD_FLAG   = 2^1   -- FLAGS
    local MD_IGCS   = 2^2   -- CASE IGNORED

    -- FIELD INDEX
    local FD_MOD    = 0     -- FIELD MODIFIER
    local FD_ENUMS  = 1     -- FIELD ENUMERATIONS
    local FD_CACHE  = 2     -- FIELD CACHE : VALUE -> NAME
    local FD_EMSG   = 3     -- FIELD ERROR MESSAGE
    local FD_VALID  = 4     -- FIELD VALIDATOR
    local FD_MAXV   = 5     -- FIELD MAX VALUE(FOR FLAGS)
    local FD_DEFT   = 6     -- FIELD DEFAULT

    -- Flags
    local FL_FLAG   = 2^0
    local FL_IGCS   = 2^1

    local function getTargetInfo(target)
        local info  = _BDInfo[target]
        if info then return info, true else return _EnumInfo[target], false end
    end

    local function generateValidator(info)
        local token = 0
        local upval = _Cache()

        tinsert(upval, info[FD_ENUMS])
        tinsert(upval, info[FD_CACHE])
        tinsert(upval, info[FD_EMSG])

        if validateFlags(MD_IGCS, info[FD_MOD]) then
            token   = turnOnFlags(FL_IGCS, token)
        end

        if validateFlags(MD_FLAG, info[FD_MOD]) then
            token   = turnOnFlags(FL_FLAG, token)
            tinsert(upval, info[FD_MAXV])
        end

        if not _ValidMap[token] then
            local header    = _Cache()
            local body      = _Cache()

            tinsert(header, "enums")
            tinsert(header, "cache")
            tinsert(header, "emsg")

            tinsert(body, "")   -- Remain for closure values
            tinsert(body, [[return function(value)]])

            tinsert(body, [[if cache[value] then return value end]])

            tinsert(body, [[local vtype = type(value)]])

            tinsert(body, [[if vtype == "string" then]])

            if validateFlags(FL_IGCS, token) then
                tinsert(body, [[value = strupper(value)]])
            end

            tinsert(body, [[
                value = enums[value]
                return value, value == nil and emsg or nil
            ]])

            if validateFlags(FL_FLAG, token) then
                tinsert(header, "maxv")
                tinsert(body, [[
                    elseif vtype == "number" then
                        if value == 0 then
                            if cache[0] then return 0 end
                        elseif floor(value) == value and value > 0 and value <= maxv then
                            return value
                        end
                ]])
            end

            tinsert(body, [[
                end
                return nil, emsg
            ]])

            tinsert(body, [[end]])

            if #header > 0 then
                body[1] = "local " .. tblconcat(header, ",") .. "= ..."
            end

            _ValidMap[token] = loadSnippet(tblconcat(body, "\n"), "Enum_Validate_" .. token)

            _Cache(header)
            _Cache(body)
        end

        info[FD_VALID] = _ValidMap[token](unpack(upval))

        _Cache(upval)
    end

    enum            = Prototype.NewPrototype {
        __index     = {
            ["BeginDefinition"] = function(target, stack)
                stack = type(stack) == "number" and stack or 2

                target          = enum.Validate(target)
                if not target then error("Usage: enum.BeginDefinition(enumeration[, stack]) - enumeration not existed", stack) end

                local info      = _EnumInfo[target]

                if info and validateFlags(MD_SEAL, info[FD_MOD]) then error(("Usage: enum.BeginDefinition(enumeration[, stack]) - The %s is sealed, can't be re-defined."):format(tostring(target)), stack) end
                if _BDInfo[target] then error(("Usage: enum.BeginDefinition(enumeration[, stack]) - The %s's definition has already begun."):format(tostring(target)), stack) end

                _BDInfo[target] = {
                    [FD_MOD  ]  = 0,
                    [FD_ENUMS]  = {},
                    [FD_CACHE]  = {},
                    [FD_EMSG ]  = "%s must be a value of [" .. tostring(target) .."].",
                    [FD_VALID]  = false,
                    [FD_MAXV ]  = false,
                    [FD_DEFT ]  = nil,
                }

                attribute.ConsumeAttributes(target, ATTRIBUTE_TARGETS_ENUM, stack + 1)
            end;

            ["EndDefinition"]   = function(target, stack)
                local ninfo     = _BDInfo[target]
                if not ninfo then return end

                stack = type(stack) == "number" and stack or 2

                _BDInfo[target] = nil

                -- Check Flags Enumeration
                if validateFlags(MD_FLAG, ninfo[FD_MOD]) then
                    local enums = ninfo[FD_ENUMS]
                    local cache = ninfo[FD_CACHE]
                    local count = 0
                    local max   = 0

                    -- Scan
                    for k, v in pairs, enums do
                        v       = tonumber(v)

                        if v then
                            if v == 0 then
                                if cache[0] then
                                    error(("The %s and %s can't be the same value."):format(k, cache[0]), stack)
                                else
                                    cache[0]        = k
                                end
                            elseif v > 0 then
                                count   = count + 1

                                local n = mlog(v) / mlog(2)
                                if floor(n) == n then
                                    if cache[2^n] then
                                        error(("The %s and %s can't be the same value."):format(k, cache[2^n]), stack)
                                    else
                                        cache[2^n]  = k
                                        max         = n > max and n or max
                                    end
                                else
                                    error(("The %s's value is not a valid flags value(2^n)."):format(k), stack)
                                end
                            else
                                error(("The %s's value is not a valid flags value(2^n)."):format(k), stack)
                            end
                        else
                            count       = count + 1
                            enums[k]    = -1
                        end
                    end

                    -- So the definition would be more precisely
                    if max >= count then error("The flags enumeration's value can't be greater than 2^(count - 1).", stack) end

                    -- Auto-gen values
                    local n     = 0
                    for k, v in pairs, enums do
                        if v == -1 then
                            while cache[2^n] do n = n + 1 end
                            cache[2^n] = k
                            enums[k]   = 2^n
                        end
                    end

                    -- Mark the max value
                    ninfo[FD_MAXV] = 2^count - 1
                else
                    local enums = ninfo[FD_ENUMS]
                    local cache = ninfo[FD_CACHE]

                    for k, v in pairs, enums do
                        cache[v] = k
                    end
                end

                generateValidator(ninfo)

                -- Check Default
                if ninfo[FD_DEFT] ~= nil then
                    ninfo[FD_DEFT]  = ninfo[FD_VALID](ninfo[FD_DEFT])
                    if ninfo[FD_DEFT] == il then
                        error(ninfo[FD_EMSG]:format("The default"), stack)
                    end
                end

                -- Save as new enumeration's info
                _EnumInfo[target] = ninfo

                attribute.ApplyAfterDefine(target, ATTRIBUTE_TARGETS_ENUM)

                return target
            end;

            ["GetDefault"]      = function(target)
                local info      = getTargetInfo(target)
                return info and info[FD_DEFT]
            end;

            ["GetEnumValues"]   = function(target, cache)
                local info      = _EnumInfo[target]
                if info then
                    if cache then
                        return tblclone(info[FD_ENUMS], type(cache) == "table" and wipe(cache) or _Cache())
                    else
                        info    = info[FD_ENUMS]
                        return function(self, key) return next(info, key) end, target
                    end
                end
            end;

            ["IsCaseIgnored"]   = function(target)
                local info  = getTargetInfo(target)
                return info and validateFlags(MD_IGCS, info[FD_MOD]) or false
            end;

            ["IsFlagsEnum"]     = function(target)
                local info      = getTargetInfo(target)
                return info and validateFlags(MD_FLAG, info[FD_MOD]) or false
            end;

            ["IsSealed"]        = function(target)
                local info      = getTargetInfo(target)
                return info and validateFlags(MD_SEAL, info[FD_MOD]) or false
            end;

            ["IsSubType"]       = function() return false end;

            -- Parse the value to enumeration name
            ["Parse"]           = function(target, value, cache)
                local info      = _EnumInfo[target]
                if info then
                    local ecache= info[FD_CACHE]

                    if info[FD_MAXV] then
                        if cache then
                            local ret = type(cache) == "table" and wipe(cache) or _Cache()

                            if type(value) == "number" and floor(value) == value and value >= 0 and value <= info[FD_MAXV] then
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
                        elseif type(value) == "number" and floor(value) == value and value >= 0 and value <= info[FD_MAXV] then
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
                local info, def = getTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    if not def then error(("Usage: enum.SetDefault(enumeration, default[, stack]) - The %s's definition is finished."):format(tostring(target)), stack) end
                    info[FD_DEFT] = default
                else
                    error("Usage: enum.SetDefault(enumeration, default[, stack]) - The enumeration is not valid.", stack)
                end
            end;

            ["SetEnumValue"]    = function(target, key, value, stack)
                local info, def = getTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    if not def then error(("Usage: enum.SetEnumValue(enumeration, key, value[, stack]) - The %s's definition is finished."):format(tostring(target)), stack) end
                    if type(key) ~= "string" then error("Usage: enum.SetEnumValue(enumeration, key, value[, stack]) - The key must be a string.", stack) end

                    for k, v in pairs, info[FD_ENUMS] do
                        if v == value then
                            error("Usage: enum.SetEnumValue(enumeration, key, value[, stack]) - The value already existed.", stack)
                        end
                    end

                    if validateFlags(MD_IGCS, info[FD_MOD]) then
                        info[FD_ENUMS][strupper(key)] = value
                    else
                        info[FD_ENUMS][key] = value
                    end
                else
                    error("Usage: enum.SetEnumValue(enumeration, key, value[, stack]) - The enumeration is not valid.", stack)
                end
            end;

            ["SetCaseIgnored"]  = function(target, stack)
                local info, def = getTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    if not validateFlags(MD_IGCS, info[FD_MOD]) then
                        if not def then error(("Usage: enum.SetCaseIgnored(enumeration[, stack]) - The %s's definition is finished."):format(tostring(target)), stack) end
                        info[FD_MOD]    = turnOnFlags(MD_IGCS, info[FD_MOD])

                        local enums     = info[FD_ENUMS]
                        local nenums    = _Cache()
                        for k, v in pairs, enums do nenums[strupper(k)] = v end
                        info[FD_ENUMS]  = nenums
                        _Cache(enums)
                    end
                else
                    error("Usage: enum.SetCaseIgnored(enumeration[, stack]) - The enumeration is not valid.", stack)
                end
            end;

            ["SetFlagsEnum"]    = function(target, stack)
                local info, def = getTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    if not validateFlags(MD_FLAG, info[FD_MOD]) then
                        if not def then error(("Usage: enum.SetFlagsEnum(enumeration[, stack]) - The %s's definition is finished."):format(tostring(target)), stack) end
                        info[FD_MOD] = turnOnFlags(MD_FLAG, info[FD_MOD])
                    end
                else
                    error("Usage: enum.SetFlagsEnum(enumeration[, stack]) - The enumeration is not valid.", stack)
                end
            end;

            ["SetSealed"]       = function(target, stack)
                local info      = getTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    if not validateFlags(MD_SEAL, info[FD_MOD]) then
                        info[FD_MOD] = turnOnFlags(MD_SEAL, info[FD_MOD])
                    end
                else
                    error("Usage: enum.SetSealed(enumeration[, stack]) - The enumeration is not valid.", stack)
                end
            end;

            ["ValidateValue"]   = function(target, value)
                local info  = _EnumInfo[target]
                if info then
                    return info[FD_VALID](value)
                else
                    error("Usage: enum.ValidateValue(enumeration, value) - The enumeration is not valid.", 2)
                end
            end;

            -- Validate whether the value is an enum type
            ["Validate"]        = function(target)
                return getmetatable(target) == enum and target or nil
            end;
        },
        __concat    = typeconcat,
        __tostring  = function() return "enum" end,
        __newindex  = readOnly,
        __call      = function(self, ...)
            local env, target, definition, keepenv, stack = typebuilder.GetNewTypeParams(enum, tenum, ...)
            if not target then
                error("Usage: enum([env, ][name, ][definition][, stack]) - the enum type can't be created.", stack)
            elseif definition ~= nil and type(definition) ~= "table" then
                error("Usage: enum([env, ][name, ][definition][, stack]) - the definition should be a table.", stack)
            end

            enum.BeginDefinition(target, stack + 1)

            local builder = typebuilder.NewBuilder(enumbuilder, target)

            if definition then
                builder(definition, stack + 1)
                return target
            else
                return builder
            end
        end,
    }

    tenum           = Prototype.NewPrototype(tnamespace, {
        __index     = enum.ValidateValue,
        __call      = enum.Parse,
        __metatable = enum,
    })

    enumbuilder     = Prototype.NewPrototype {
        __newindex  = readOnly,
        __call      = function(self, ...)
            local definition, stack = typebuilder.GetBuilderParams(self, ...)
            if type(definition) ~= "table" then error("Usage: enum([env, ][name, ][stack]) {...} - The definition table is missing.", stack) end

            local owner = typebuilder.GetBuilderOwner(self)
            if not owner or not typebuilder.InDefineMode(self) then error("The enum builder is expired.", stack) end

            attribute.ApplyAttributes(owner, ATTRIBUTE_TARGETS_ENUM, definition)

            stack   = stack + 1

            for k, v in pairs, definition do
                if type(k) == "string" then
                    enum.SetEnumValue(owner, k, v, stack)
                elseif type(v) == "string" then
                    enum.SetEnumValue(owner, v, v, stack)
                end
            end

            typebuilder.EndDefinition(self)
            enum.EndDefinition(owner, stack)
            return owner
        end,
    }
end

-------------------------------------------------------------------------------
--                                 structure                                 --
-------------------------------------------------------------------------------
do
    local _StrtInfo = setmetatable({}, WEAK_KEY)
    local _BDInfo   = Prototype.NewObject(threadCache)

    local _ValidMap = {}
    local _CtorMap  = {}

    -- FEATURE MODIFIER
    local MD_SEAL   = 2^0       -- SEALED

    -- FIELD INDEX
    local FD_MOD    = -1        -- FIELD MODIFIER
    local FD_TYPMTD = -2        -- FIELD OBJECT METHODS
    local FD_DEFT   = -3        -- FEILD DEFAULT
    local FD_BASE   = -4        -- FIELD BASE STRUCT
    local FD_VALID  = -5        -- FIELD VALIDATOR
    local FD_CTOR   = -6        -- FIELD CONSTRUCTOR
    local FD_NAME   = -7        -- FEILD OWNER NAME
    local FD_EMSG   = -8        -- FIELD ERROR MESSAGE
    local FD_VCACHE = -9        -- FIELD VALIDATOR CACHE

    local FD_ARRAY  =  0        -- FIELD ARRAY ELEMENT
    local FD_ARRVLD =  2        -- FIELD ARRAY ELEMENT VALIDATOR
    local FD_STMEM  =  1        -- FIELD START INDEX OF MEMBER
    local FD_STVLD  =  10000    -- FIELD START INDEX OF VALIDATOR
    local FD_STINI  =  20000    -- FIELD START INDEX OF INITIALIZE

    -- MEMBER FIELD INDEX
    local MFD_NAME  =  1        -- MEMBER FIELD NAME
    local MFD_TYPE  =  2        -- MEMBER FIELD TYPE
    local MFD_VALD  =  3        -- MEMBER FIELD TYPE VALIDATOR
    local MFD_DEFT  =  4        -- MEMBER FIELD DEFAULT
    local MFD_ASFT  =  5        -- MEMBER FIELD AS DEFAULT FACTORY
    local MFD_REQ   =  0        -- MEMBER FIELD REQUIRE

    -- TYPE FLAGS
    local FL_CUSTOM = 2^0       -- CUSTOM STRUCT FLAG
    local FL_MEMBER = 2^1       -- MEMBER STRUCT FLAG
    local FL_ARRAY  = 2^2       -- ARRAY  STRUCT FLAG
    local FL_SVALID = 2^3       -- SINGLE VALID  FLAG
    local FL_MVALID = 2^4       -- MULTI  VALID  FLAG
    local FL_SINIT  = 2^5       -- SINGLE INIT   FLAG
    local FL_MINIT  = 2^6       -- MULTI  INIT   FLAG
    local FL_OBJMTD = 2^7       -- OBJECT METHOD FLAG
    local FL_VCACHE = 2^8       -- VALID  CACHE  FLAG
    local FL_MLFDRQ = 2^9       -- MULTI  FIELD  REQUIRE FLAG
    local FL_FSTTYP = 2^10      -- FIRST  MEMBER TYPE    FLAG

    local MTD_INIT  = "__init"
    local MTD_BASE  = "__base"

    local getValueFromBuidler   = typebuilder.GetValueFromBuidler
    local getNameSpace          = namespace.GetNameSpace

    local function getTargetInfo(target)
        local info  = _BDInfo[target]
        if info then return info, true else return _StrtInfo[target], false end
    end

    local function getBuilderValue(self, name)
        -- Access methods
        local info  = getTargetInfo(typebuilder.GetBuilderOwner(self))
        local m     = info and (info[name] or info[FD_TYPMTD] and info[FD_TYPMTD][name])
        if m then return m, true end
        return getValueFromBuidler(self, name)
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
            elseif namespace.IsFeatureType(value) then
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
            elseif namespace.IsFeatureType(value) then
                struct.SetArrayElement(owner, value, stack)
            elseif tval == "table" then
                struct.AddMember(owner, value, stack)
            else
                struct.SetDefault(owner, value, stack)
            end
            return true
        end
    end

    local function generateValidator(info)
        local token = 0
        local upval = _Cache()

        info[FD_VCACHE] = nil

        if info[FD_STMEM] then
            token   = turnOnFlags(FL_MEMBER, token)
            local i = FD_STMEM
            local c = false

            while info[i] do
                if not c then
                    local mtype = info[i][MFD_TYPE]
                    if mtype and struct.Validate(mtype) and not (struct.IsSealed(mtype) and not _BDInfo[mtype] and struct.GetStructType(mtype) == StructType.CUSTOM) then
                        c = true
                    end
                end
                i   = i + 1
            end
            if c then
                token = turnOnFlags(FL_VCACHE, token)
                info[FD_VCACHE] = true
            end
            tinsert(upval, i - 1)
        elseif info[FD_ARRAY] then
            token   = turnOnFlags(FL_ARRAY, token)
            tinsert(upval, info[FD_ARRAY])
            tinsert(upval, info[FD_ARRVLD])

            local atype = info[FD_ARRAY]
            if struct.Validate(atype) and not (struct.IsSealed(atype) and not _BDInfo[atype] and struct.GetStructType(atype) == StructType.CUSTOM) then
                token   = turnOnFlags(FL_VCACHE, token)
                info[FD_VCACHE] = true
            end
        else
            token   = turnOnFlags(FL_CUSTOM, token)
        end

        if info[FD_STVLD] then
            if info[FD_STVLD + 1] then
                local i = FD_STVLD + 2
                while info[i] do i = i + 1 end
                token = turnOnFlags(FL_MVALID, token)
                tinsert(upval, i - 1)
            else
                token = turnOnFlags(FL_SVALID, token)
                tinsert(upval, info[FD_STVLD])
            end
        end

        if info[FD_STINI] then
            if info[FD_STINI + 1] then
                local i = FD_STINI + 2
                while info[i] do i = i + 1 end
                token = turnOnFlags(FL_MINIT, token)
                tinsert(upval, i - 1)
            else
                token = turnOnFlags(FL_SINIT, token)
                tinsert(upval, info[FD_STINI])
            end
        end

        if info[FD_TYPMTD] then
            for k, v in pairs, info[FD_TYPMTD] do
                if v then
                    token   = turnOnFlags(FL_OBJMTD, token)
                    tinsert(upval, info[FD_TYPMTD])
                    break
                end
            end
        end

        -- Build the validator generator
        if not _ValidMap[token] then
            local header    = _Cache()
            local body      = _Cache()

            tinsert(body, "")   -- Remain for closure values
            tinsert(body, [[return function(info, value, onlyValid, cache)]])

            if validateFlags(FL_MEMBER, token) or validateFlags(FL_ARRAY, token) then
                tinsert(body, [[
                    if type(value)         ~= "table" then return nil, onlyValid or "%s must be a table." end
                    if getmetatable(value) ~= nil     then return nil, onlyValid or "%s must be a table without meta-table." end
                ]])

                if validateFlags(FL_VCACHE, token) then
                    tinsert(body, [[
                        -- Cache to block recursive validation
                        local vcache = cache[info] or _Cache()
                        cache[info]  = vcache
                        if vcache[value] then return value end
                        vcache[value]= true
                    ]])
                end
            end

            if validateFlags(FL_MEMBER, token) then
                tinsert(header, "count")
                tinsert(body, [[
                    if onlyValid then
                        for i = ]] .. FD_STMEM .. [[, count do
                            local mem  = info[i]
                            local name = mem[]] .. MFD_NAME .. [[]
                            local vtype= mem[]] .. MFD_TYPE ..[[]
                            local val  = value[name]
                            local msg

                            if val == nil then
                                if mem[]] .. MFD_REQ .. [[] then
                                    return nil, true
                                end
                            elseif vtype then
                                val, msg = mem[]] .. MFD_VALD .. [[](vtype, val, true, cache)
                                if msg then return nil, true end
                            end
                        end
                    else
                        for i = ]] .. FD_STMEM .. [[, count do
                            local mem  = info[i]
                            local name = mem[]] .. MFD_NAME .. [[]
                            local vtype= mem[]] .. MFD_TYPE ..[[]
                            local val  = value[name]
                            local msg

                            if val == nil then
                                if mem[]] .. MFD_REQ .. [[] then
                                    return nil, ("%s.%s can't be nil."):format("%s", name)
                                end

                                if mem[]] .. MFD_ASFT .. [[] then
                                    val= mem[]] .. MFD_DEFT .. [[](value)
                                else
                                    val= clone(mem[]] .. MFD_DEFT .. [[], true)
                                end
                            elseif vtype then
                                val, msg = mem[]] .. MFD_VALD .. [[](vtype, val, false, cache)
                                if msg then return nil, type(msg) == "string" and msg:gsub("%%s", "%%s" .. "." .. name) or ("%s.%s must be [%s]."):format("%s", name, tostring(vtype)) end
                            end

                            value[name] = val
                        end
                    end
                ]])
            elseif validateFlags(FL_ARRAY, token) then
                tinsert(header, "array")
                tinsert(header, "avalid")
                tinsert(body, [[
                    if onlyValid then
                        for i, v in ipairs, value, 0 do
                            local ret, msg  = avalid(array, v, true, cache)
                            if msg then return nil, true end
                        end
                    else
                        for i, v in ipairs, value, 0 do
                            local ret, msg  = avalid(array, v, false, cache)
                            if msg then return nil, type(msg) == "string" and msg:gsub("%%s", "%%s[" .. i .. "]") or ("%s[%s] must be [%s]."):format("%s", i, tostring(array)) end
                            value[i] = ret
                        end
                    end
                ]])
            end

            if validateFlags(FL_SVALID, token) then
                tinsert(header, "svalid")
                tinsert(body, [[
                    local msg = svalid(value)
                    if msg then return nil, onlyValid or type(msg) == "string" and msg or ("%s must be [%s]."):format("%s", info[]] .. FD_NAME .. [[]) end
                ]])
            elseif validateFlags(FL_MVALID, token) then
                tinsert(header, "mvalid")
                tinsert(body, [[
                    for i = ]] .. FD_STVLD .. [[, mvalid do
                        local msg = info[i](value)
                        if msg then return nil, onlyValid or type(msg) == "string" and msg or ("%s must be [%s]."):format("%s", info[]] .. FD_NAME .. [[]) end
                    end
                ]])
            end

            if validateFlags(FL_SINIT, token) or validateFlags(FL_MINIT, token) then
                tinsert(body, [[if onlyValid then return value end]])

                if validateFlags(FL_SINIT, token) then
                    tinsert(header, "sinit")
                    tinsert(body, [[
                        local ret = sinit(value)
                    ]])

                    if validateFlags(FL_CUSTOM, token) then
                        tinsert(body, [[if ret ~= nil then value = ret end]])
                    end
                else
                    tinsert(header, "minit")
                    tinsert(body, [[
                        for i = ]] .. FD_STINI .. [[, minit do
                            local ret = info[i](value)
                        ]])
                    if validateFlags(FL_CUSTOM, token) then
                        tinsert(body, [[if ret ~= nil then value = ret end]])
                    end
                    tinsert(body, [[end]])
                end
            end

            if validateFlags(FL_OBJMTD, token) then
                tinsert(header, "methods")
                if validateFlags(FL_CUSTOM, token) then
                    tinsert(body, [[if type(value) == "table" then]])
                end

                tinsert(body, [[
                    for k, v in pairs, methods do
                        if v and value[k] == nil then value[k] = v end
                    end
                ]])

                if validateFlags(FL_CUSTOM, token) then
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

            _ValidMap[token] = loadSnippet(tblconcat(body, "\n"), "Struct_Validate_" .. token)

            _Cache(header)
            _Cache(body)
        end

        info[FD_VALID] = _ValidMap[token](unpack(upval))

        _Cache(upval)
    end

    local function generateConstructor(info)
        local token = 0
        local upval = _Cache()

        if info[FD_VCACHE] then
            token   = turnOnFlags(FL_VCACHE, token)
        end

        if info[FD_STMEM] then
            token   = turnOnFlags(FL_MEMBER, token)
            local i = FD_STMEM + 1
            local r = false
            while info[i] do
                if not r and info[i][MFD_REQ] then r = true end
                i = i + 1
            end
            tinsert(upval, i - 1)
            if r then
                token = turnOnFlags(FL_MLFDRQ, token)
            elseif info[FD_STMEM][MFD_TYPE] then
                token = turnOnFlags(FL_FSTTYP, token)
                tinsert(upval, info[FD_STMEM][MFD_TYPE])
                tinsert(upval, info[FD_STMEM][MFD_VALD])
            end
        elseif info[FD_ARRAY] then
            token   = turnOnFlags(FL_ARRAY, token)
            tinsert(upval, info[FD_ARRAY])
            tinsert(upval, info[FD_ARRVLD])
        else
            token   = turnOnFlags(FL_CUSTOM, token)
        end

        tinsert(upval, info[FD_VALID])

        -- Build the validator generator
        if not _CtorMap[token] then
            local header    = _Cache()
            local body      = _Cache()

            tinsert(body, "")

            if validateFlags(FL_MEMBER, token) or validateFlags(FL_ARRAY, token) then
                tinsert(body, [[
                    return function(info, first, ...)
                        local ret, msg
                        if select("#", ...) == 0 and type(first) == "table" and getmetatable(first) == nil then
                ]])

                if validateFlags(FL_MEMBER, token) then
                    tinsert(header, "count")
                    if not validateFlags(FL_MLFDRQ, token) then
                        -- So, it may be the first member
                        if validateFlags(FL_FSTTYP, token) then
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
                elseif validateFlags(FL_ARRAY, token) then
                    tinsert(header, "array")
                    tinsert(header, "avalid")
                    tinsert(body, [[
                        local _, fmatch = avalid(array, first, true) fmatch = not fmatch
                    ]])
                end

                tinsert(header, "ivalid")

                if validateFlags(FL_VCACHE, token) then
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

                if validateFlags(FL_VCACHE, token) then
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
                            error(info[]] .. FD_EMSG .. [[] .. (type(msg) == "string" and msg:gsub("%%s%.?", "") or "the value is not valid."), 3)
                        end
                    end
                ]])
            else
                tinsert(header, "ivalid")

                tinsert(body, [[
                    return function(info, first)
                        local ret, msg
                ]])
            end

            if validateFlags(FL_MEMBER, token) then
                tinsert(body, [[
                    ret = {}
                    local j = 1
                    ret[ info[]] .. FD_STMEM .. [[][]] .. MFD_NAME .. [[] ] = first
                    for i = ]] .. (FD_STMEM + 1) .. [[, count do
                        ret[ info[i][]] .. MFD_NAME .. [[] ] = (select(j, ...))
                        j = j + 1
                    end
                ]])
            elseif validateFlags(FL_ARRAY, token) then
                tinsert(body, [[
                    ret = { first, ... }
                ]])
            else
                tinsert(body, [[ret = first]])
            end

            if validateFlags(FL_VCACHE, token) then
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

            if validateFlags(FL_MEMBER, token) or validateFlags(FL_ARRAY, token) then
                tinsert(body, [[
                    error(info[]] .. FD_EMSG .. [[] .. (type(msg) == "string" and msg:gsub("%%s%.?", "") or "the value is not valid."), 3)
                ]])
            else
                tinsert(body, [[
                    error(msg:gsub("%%s", "the value"), 3)
                ]])
            end

            tinsert(body, [[end]])

            if #header > 0 then
                body[1] = "local " .. tblconcat(header, ",") .. "= ..."
            end

            _CtorMap[token] = loadSnippet(tblconcat(body, "\n"), "Struct_Ctor_" .. token)

            _Cache(header)
            _Cache(vbody)
        end

        info[FD_CTOR] = _CtorMap[token](unpack(upval))

        _Cache(upval)
    end

    -- [ENUM] System.StructType
    enum (_PLoopEnv, "StructType", { "MEMBER", "ARRAY", "CUSTOM" })
    enum.SetSealed(StructType)

    struct          = Prototype.NewPrototype {
        __index     = {
            ["AddMember"]       = function(target, name, definition, stack)
                local info, def = getTargetInfo(target)

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
                    if not def then error(("Usage: struct.AddMember(structure[, name], definition[, stack]) - The %s's definition is finished."):format(tostring(target)), stack) end
                    if type(name) ~= "string" then error("Usage: struct.AddMember(structure[, name], definition[, stack]) - The name must be a string.", stack) end
                    name = strtrim(name)
                    if name == "" then error("Usage: struct.AddMember(structure[, name], definition[, stack]) - The name can't be empty.", stack) end
                    if type(definition) ~= "table" then error("Usage: struct.AddMember(structure[, name], definition[, stack]) - The definition is missing.", stack) end
                    if info[FD_ARRAY] then error("Usage: struct.AddMember(structure[, name], definition[, stack]) - The structure is an array structure, can't add member.", stack) end

                    local idx = FD_STMEM
                    while info[idx] do
                        if info[idx][MFD_NAME] == name then
                            error(("Usage: struct.AddMember(structure[, name], definition[, stack]) - There is a existed member with the name : %q."):format(name), stack)
                        end
                        idx = idx + 1
                    end

                    local minfo = _Cache()
                    minfo[MFD_NAME] = name

                    attribute.ConsumeAttributes(minfo, ATTRIBUTE_TARGETS_MEMBER, stack + 1)

                    local smem  = nil

                    if info[FD_BASE] and _StrtInfo[info[FD_BASE]] then
                        local sinfo = _StrtInfo[info[FD_BASE]]
                        local si    = FD_STMEM
                        while sinfo[si] do
                            if sinfo[i][MFD_NAME] == name then
                                smem = sinfo[i][MFD_NAME]
                                break
                            end
                        end
                    end

                    attribute.ApplyAttributes  (minfo, ATTRIBUTE_TARGETS_MEMBER, definition, target, name, smem)

                    for k, v in pairs, definition do
                        if type(k) == "string" then
                            k = strlower(k)

                            if k == "type" then
                                local tpValid = getValidate(v)

                                if tpValid then
                                    minfo[MFD_TYPE] = v
                                    minfo[MFD_VALD] = tpValid
                                else
                                    error("Usage: struct.AddMember(structure[, name], definition[, stack]) - The member's type is not valid.", stack)
                                end
                            elseif k == "require" and v then
                                minfo[MFD_REQ]  = true
                            elseif k == "default" then
                                minfo[MFD_DEFT] = v
                            end
                        end
                    end

                    if minfo[MFD_REQ] then
                        minfo[MFD_DEFT] = nil
                    elseif minfo[MFD_TYPE] then
                        if minfo[MFD_DEFT] ~= nil then
                            local valid, msg = minfo[MFD_VALD](minfo[MFD_TYPE], minfo[MFD_DEFT])
                            if valid ~= nil then
                                minfo[MFD_DEFT] = valid
                            elseif type(minfo[MFD_DEFT]) == "function" then
                                minfo[MFD_ASFT] = true
                            else
                                error("Usage: struct.AddMember(structure[, name], definition[, stack]) - The default value is not valid.", stack)
                            end
                        end
                        if minfo[MFD_DEFT] == nil then
                            minfo[MFD_DEFT] = getDefaultValue(minfo[MFD_TYPE])
                        end
                    end

                    info[idx] = minfo

                    attribute.ApplyAfterDefine(minfo, ATTRIBUTE_TARGETS_MEMBER, definition, target, name)
                else
                    error("Usage: struct.AddMember(structure[, name], definition[, stack]) - The structure is not valid.", stack)
                end
            end;

            ["AddMethod"]       = function(target, name, func, stack)
                local info, def = getTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    if type(name) ~= "string" then error("Usage: struct.AddMethod(structure, name, func[, stack]) - The name must be a string.", stack) end
                    name = strtrim(name)
                    if name == "" then error("Usage: Usage: struct.AddMethod(structure, name, func[, stack]) - The name can't be empty.", stack) end
                    if type(func) ~= "function" then error("Usage: struct.AddMethod(structure, name, func[, stack]) - The func must be a function.", stack) end

                    if not def and struct.GetMethod(target, name) then
                        error(("Usage: struct.AddMethod(structure, name, func[, stack]) - The %s's definition is finished, the method can't be overridden."):format(tostring(target)), stack)
                    end

                    attribute.ConsumeAttributes(func, ATTRIBUTE_TARGETS_METHOD, stack + 1)

                    local sfunc

                    if info[FD_BASE] and not info[name] then
                        if not struct.IsStaticMethod(info[FD_BASE], name) then
                            sfunc = struct.GetMethod(info[FD_BASE], name)
                        end
                    end

                    func = attribute.ApplyAttributes(func, ATTRIBUTE_TARGETS_METHOD, nil, target, name, sfunc)

                    local hasMethod= false
                    if not def and info[FD_TYPMTD] then for k, v in pairs, info[FD_TYPMTD] do if v then hasMethod = true break end end end

                    if not info[name] then
                        info[FD_TYPMTD] = info[FD_TYPMTD] or _Cache()
                        info[FD_TYPMTD][name] = func
                    else
                        info[name]  = func
                    end

                    attribute.ApplyAfterDefine(func, ATTRIBUTE_TARGETS_METHOD, nil, target, name)

                    if not def and not hasMethod then
                        -- Need re-generate validator
                        generateValidator(info)
                    end
                else
                    error("Usage: struct.AddMethod(structure, name, func[, stack]) - The structure is not valid.", stack)
                end
            end;

            ["BeginDefinition"] = function(target, stack)
                stack = type(stack) == "number" and stack or 2

                target          = struct.Validate(target)
                if not target then error("Usage: struct.BeginDefinition(structure[, stack]) - The structure not existed", stack) end

                local info      = _StrtInfo[target]

                if info and validateFlags(MD_SEAL, info[FD_MOD]) then error(("Usage: struct.BeginDefinition(structure[, stack]) - The %s is sealed, can't be re-defined."):format(tostring(target)), stack) end
                if _BDInfo[target] then error(("Usage: struct.BeginDefinition(structure[, stack]) - The %s's definition has already begun."):format(tostring(target)), stack) end

                _BDInfo[target] = {
                    [FD_MOD ]   = 0,
                    [FD_NAME]   = tostring(target),
                }

                attribute.ConsumeAttributes(target, ATTRIBUTE_TARGETS_STRUCT, stack + 1)
            end;

            ["EndDefinition"]   = function(target, stack)
                local ninfo     = _BDInfo[target]
                if not ninfo then return end

                stack = type(stack) == "number" and stack or 2

                attribute.ApplyAttributes(target, ATTRIBUTE_TARGETS_STRUCT, nil, nil, nil, ninfo[FD_BASE])

                _BDInfo[target] = nil

                -- Install base struct's features
                if ninfo[FD_BASE] then
                    -- Check conflict, some should be handled by the author
                    local binfo     = _StrtInfo[ninfo[FD_BASE]]

                    if ninfo[FD_ARRAY] then     -- Array
                        if not binfo[FD_ARRAY] then
                            error(("Usage: struct.EndDefinition(structure[, stack]) - The %s's base struct isn't an array structure."):format(tostring(target)), stack)
                        end
                    elseif ninfo[FD_STMEM] then -- Member
                        if binfo[FD_ARRAY] then
                            error(("Usage: struct.EndDefinition(structure[, stack]) - The %s's base struct can't be an array structure."):format(tostring(target)), stack)
                        elseif binfo[FD_STMEM] then
                            -- Try to keep the base struct's member order
                            local cache     = _Cache()
                            local idx       = FD_STMEM
                            while ninfo[idx] do
                                tinsert(cache, ninfo[idx])
                                idx         = idx + 1
                            end

                            local memCnt    = #cache

                            idx             = FD_STMEM
                            while binfo[idx] do
                                local name  = binfo[idx][MFD_NAME]
                                ninfo[idx]  = binfo[idx]

                                for k, v in pairs, cache do
                                    if name == v[MFD_NAME] then
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
                        if binfo[FD_ARRAY] then
                            ninfo[FD_ARRAY] = binfo[FD_ARRAY]
                            ninfo[FD_ARRVLD]= binfo[FD_ARRVLD]
                        elseif binfo[FD_STMEM] then
                            -- Share members
                            local idx = FD_STMEM
                            while binfo[idx] do
                                ninfo[idx]  = binfo[idx]
                                idx         = idx + 1
                            end
                        end
                    end

                    -- Clone the validator and Initializer
                    local nvalid    = ninfo[FD_STVLD]
                    local ninit     = ninfo[FD_STINI]

                    local idx       = FD_STVLD
                    while binfo[idx] do
                        ninfo[idx]  = binfo[idx]
                        idx         = idx + 1
                    end
                    ninfo[idx]      = nvalid

                    idx             = FD_STINI
                    while binfo[idx] do
                        ninfo[idx]  = binfo[idx]
                        idx         = idx + 1
                    end
                    ninfo[idx]      = ninit

                    -- Clone the methods
                    if binfo[FD_TYPMTD] then
                        nobjmtd     = ninfo[FD_TYPMTD] or _Cache()

                        for k, v in pairs, binfo[FD_TYPMTD] do
                            if v and nobjmtd[k] == nil then
                                nobjmtd[k]  = v
                            end
                        end

                        if next(nobjmtd) then
                            ninfo[FD_TYPMTD] = nobjmtd
                        else
                            ninfo[FD_TYPMTD] = nil
                            _Cache(nobjmtd)
                        end
                    end
                end

                -- Generate error message
                if ninfo[FD_STMEM] then
                    local args      = _Cache()
                    local idx       = FD_STMEM
                    while ninfo[idx] do
                        tinsert(args, ninfo[idx][MFD_NAME])
                        idx         = idx + 1
                    end
                    ninfo[FD_EMSG]  = ("Usage: %s(%s) - "):format(tostring(target), tblconcat(args, ", "))
                    _Cache(args)
                elseif ninfo[FD_ARRAY] then
                    ninfo[FD_EMSG]  = ("Usage: %s(...) - "):format(tostring(target))
                else
                    ninfo[FD_EMSG]  = ("[%s]"):format(tostring(target))
                end

                generateValidator(ninfo)
                generateConstructor(ninfo)

                -- Check the default value is it's custom struct
                if ninfo[FD_DEFT] ~= nil then
                    local deft      = ninfo[FD_DEFT]
                    ninfo[FD_DEFT]  = nil

                    if not ninfo[FD_ARRAY] and not ninfo[FD_STMEM] then
                        local ret, msg = struct.ValidateValue(target, deft)
                        if not msg then ninfo[FD_DEFT] = ret end
                    end
                end

                -- Save as new structure's info
                _StrtInfo[target]   = ninfo

                attribute.ApplyAfterDefine(target, ATTRIBUTE_TARGETS_STRUCT)

                return target
            end;

            ["GetArrayElement"] = function(target)
                local info      = getTargetInfo(target)
                return info and info[FD_ARRAY]
            end;

            ["GetBaseStruct"]   = function(target)
                local info      = getTargetInfo(target)
                return info and info[FD_BASE]
            end;

            ["GetDefault"]      = function(target)
                local info      = getTargetInfo(target)
                return info and info[FD_DEFT]
            end;

            ["GetMember"]       = function(target, name)
                local info      = getTargetInfo(target)
                if info then
                    local idx   = FD_STMEM
                    local minfo = info[idx]
                    while minfo do
                        if idx == name or minfo[MFD_NAME] == name then
                            return minfo[MFD_TYPE], minfo[MFD_DEFT], minfo[MFD_REQ]
                        end
                        idx     = idx + 1
                        minfo   = info[idx]
                    end
                end
            end;

            ["GetMembers"]      = function(target, cache)
                local info      = getTargetInfo(target)
                if info then
                    if cache then
                        cache   = type(cache) == "table" and wipe(cache) or _Cache()
                        local i = FD_STMEM
                        local m = info[i]
                        while m do
                            tinsert(cache, m[MFD_NAME])
                            i   = i + 1
                            m   = info[i]
                        end
                        return cache
                    else
                        return function(self, i)
                            i   = i and (i + 1) or FD_STMEM
                            if info[i] then
                                return i, info[i][MFD_NAME]
                            end
                        end, target
                    end
                end
            end;

            ["GetMethod"]       = function(target, name)
                local info, def = getTargetInfo(target)
                return info and type(name) == "string" and (info[name] or info[FD_TYPMTD] and info[FD_TYPMTD][name]) or nil
            end;

            ["GetObjectMethod"] = function(target, name)
                local info      = getTargetInfo(target)
                return info and type(name) == "string" and info[FD_TYPMTD] and info[FD_TYPMTD][name] or nil
            end;

            ["GetStaticMethod"] = function(target, name)
                local info      = getTargetInfo(target)
                return info and type(name) == "string" and info[name] or nil
            end;

            ["GetMethods"]      = function(target, cache)
                local info      = getTargetInfo(target)
                if info then
                    local objm  = info[FD_TYPMTD]
                    if cache then
                        cache   = type(cache) == "table" and wipe(cache) or _Cache()
                        if objm then for k, v in pairs, objm do cache[k] = v or info[k] end end
                        return cache
                    elseif objm then
                        return function(self, n)
                            local m, v = next(objm, n)
                            if m then return m, v or info[m] end
                        end, target
                    else
                        return fakefunc, target
                    end
                elseif not cache then
                    return fakefunc, target
                end
            end;

            ["GetObjectMethods"]= function(target, cache)
                local info      = getTargetInfo(target)
                if info then
                    local objm  = info[FD_TYPMTD]
                    if cache then
                        cache   = type(cache) == "table" and wipe(cache) or _Cache()
                        for k, v in pairs, objm do if v then cache[k] = v end end
                        return cache
                    elseif objm then
                        return function(self, n)
                            local m, v = next(objm, n)
                            while m and not v do m, v = next(objm, m) end
                            return m, v
                        end, target
                    else
                        return fakefunc, target
                    end
                elseif not cache then
                    return fakefunc, target
                end
            end;

            ["GetStaticMethods"]= function(target, cache)
                local info      = getTargetInfo(target)
                if info then
                    local objm  = info[FD_TYPMTD]
                    if cache then
                        cache   = type(cache) == "table" and wipe(cache) or _Cache()
                        for k, v in pairs, objm do if not v then cache[k] = info[k] end end
                        return cache
                    elseif objm then
                        return function(self, n)
                            local m, v = next(objm, n)
                            while m and v do m, v = next(objm, m) end
                            if m then return m, info[m] end
                        end, target
                    else
                        return fakefunc, target
                    end
                elseif not cache then
                    return fakefunc, target
                end
            end;

            ["GetStructType"]   = function(target)
                local info      = getTargetInfo(target)
                if info then
                    if info[FD_ARRAY] then return StructType.ARRAY end
                    if info[FD_STMEM] then return StructType.MEMBER end
                    return StructType.CUSTOM
                end
            end;

            ["IsSubType"]       = function(target, base)
                if struct.Validate(base) then
                    while target do
                        if target == base then return true end
                        local i = getTargetInfo(target)
                        target  = i and i[FD_BASE]
                    end
                end
                return false
            end;

            ["IsSealed"]        = function(target)
                local info      = getTargetInfo(target)
                return info and validateFlags(MD_SEAL, info[FD_MOD]) or false
            end;

            ["IsStaticMethod"]  = function(target, name)
                local info      = getTargetInfo(target)
                return info and type(name) == "string" and info[name] and true or false
            end;

            ["SetArrayElement"] = function(target, eleType, stack)
                local info, def = getTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    if not def then error(("Usage: struct.SetArrayElement(structure, eleType[, stack]) - The %s's definition is finished."):format(tostring(target)), stack) end

                    if info[FD_STMEM] then error("Usage: struct.SetArrayElement(structure, eleType[, stack]) - The structure has member settings, can't set array element.", stack) end

                    local tpValid   = getValidate(eleType)
                    if not tpValid then error("Usage: struct.SetArrayElement(structure, eleType[, stack]) - The element type is not valid.", stack) end

                    info[FD_ARRAY]  = eleType
                    info[FD_ARRVLD] = tpValid
                else
                    error("Usage: struct.SetArrayElement(structure, eleType[, stack]) - The structure is not valid.", stack)
                end
            end;

            ["SetBaseStruct"]   = function(target, base, stack)
                local info, def = getTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    if not def then error(("Usage: struct.SetBaseStruct(structure, base) - The %s's definition is finished."):format(tostring(target)), stack) end
                    if not struct.Validate(base) then error("Usage: struct.SetBaseStruct(structure, base) - The base must be a structure.", stack) end
                    info[FD_BASE] = base
                else
                    error("Usage: struct.SetBaseStruct(structure, base[, stack]) - The structure is not valid.", stack)
                end
            end;

            ["SetDefault"]      = function(target, default, stack)
                local info, def = getTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    if not def then error(("Usage: struct.SetDefault(structure, default[, stack]) - The %s's definition is finished."):format(tostring(target)), stack) end
                    info[FD_DEFT] = default
                else
                    error("Usage: struct.SetDefault(structure, default[, stack]) - The structure is not valid.", stack)
                end
            end;

            ["SetValidator"]    = function(target, func, stack)
                local info, def = getTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    if not def then error(("Usage: struct.SetValidator(structure, validator[, stack]) - The %s's definition is finished."):format(tostring(target)), stack) end
                    if type(func) ~= "function" then error("Usage: struct.SetValidator(structure, validator) - The validator must be a function.", stack) end
                    info[FD_STVLD] = func
                else
                    error("Usage: struct.SetValidator(structure, validator[, stack]) - The structure is not valid.", stack)
                end
            end;

            ["SetInitializer"]  = function(target, func, stack)
                local info, def = getTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    if not def then error(("Usage: struct.SetInitializer(structure, initializer[, stack]) - The %s's definition is finished."):format(tostring(target)), stack) end
                    if type(func) ~= "function" then error("Usage: struct.SetInitializer(structure, initializer) - The initializer must be a function.", stack) end
                    info[FD_STINI] = func
                else
                    error("Usage: struct.SetInitializer(structure, initializer[, stack]) - The structure is not valid.", stack)
                end
            end;

            ["SetSealed"]       = function(target, stack)
                local info      = getTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    if not validateFlags(MD_SEAL, info[FD_MOD]) then
                        info[FD_MOD] = turnOnFlags(MD_SEAL, info[FD_MOD])
                    end
                else
                    error("Usage: struct.SetSealed(structure[, stack]) - The structure is not valid.", stack)
                end
            end;

            ["SetStaticMethod"] = function(target, name, stack)
                local info, def = getTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    if type(name) ~= "string" then error("Usage: struct.SetStaticMethod(structure, name) - the name must be a string.", stack) end
                    name = strtrim(name)
                    if name == "" then error("Usage: Usage: struct.SetStaticMethod(structure, name) - The name can't be empty.", stack) end
                    if not def then error(("Usage: struct.SetStaticMethod(structure, name) - The %s's definition is finished."):format(tostring(target)), stack) end
                    if not (info[FD_TYPMTD] and info[FD_TYPMTD][name] ~= nil) then error(("Usage: struct.SetStaticMethod(structure, name) - The %s has no method named %q."):format(tostring(target), name), stack) end

                    if info[name] == nil then
                        info[name] = info[FD_TYPMTD][name]
                        info[FD_TYPMTD][name] = false
                    end
                else
                    error("Usage: struct.SetStaticMethod(structure, name[, stack]) - The structure is not valid.", stack)
                end
            end;

            ["ValidateValue"]   = function(target, value, onlyValid, cache)
                local info  = _StrtInfo[target]
                if info then
                    if not cache and info[FD_VCACHE] then
                        cache = _Cache()
                        local ret, msg = info[FD_VALID](info, value, onlyValid, cache)
                        for k, v in pairs, cache do cache[k] = nil _Cache(v) end _Cache(cache)
                        return ret, msg
                    else
                        return info[FD_VALID](info, value, onlyValid, cache)
                    end
                else
                    error("Usage: struct.ValidateValue(structure, value[, onlyValid]) - The structure is not valid.", 2)
                end
            end;

            -- Validate whether the value is a struct type
            ["Validate"]        = function(target)
                return getmetatable(target) == struct and target or nil
            end;
        },
        __newindex  = readOnly,
        __concat    = typeconcat,
        __tostring  = function() return "struct" end,
        __call      = function(self, ...)
            local env, target, definition, keepenv, stack = typebuilder.GetNewTypeParams(struct, tstruct, ...)
            if not target then error("Usage: struct([env, ][name, ][definition, ][keepenv, ][stack]) - the struct type can't be created.", stack) end

            struct.BeginDefinition(target, stack + 1)

            local builder = typebuilder.NewBuilder(structbuilder, target, env)

            if definition then
                builder(definition, stack + 1)
                return target
            else
                if not keepenv then setfenv(stack, builder) end
                return builder
            end
        end,
    }

    tstruct         = Prototype.NewPrototype(tnamespace, {
        __index     = function(self, name)
            if type(name) == "string" then
                local info  = _StrtInfo[self]
                return info and (info[name] or info[FD_TYPMTD] and info[FD_TYPMTD][name]) or getNameSpace(self, name)
            end
        end,
        __newindex  = function(self, key, value)
            if type(key) == "string" and type(value) == "function" then
                struct.AddMethod(self, key, value, 3)
                return
            end
            error("The struct type is readonly.", 2)
        end,
        __call      = function(self, ...)
            local info  = _StrtInfo[self]
            local ret   = info[FD_CTOR](info, ...)
            return ret
        end,
        __metatable = struct,
    })

    structbuilder   = Prototype.NewPrototype {
        __index     = function(self, key)
            local val, cache = getBuilderValue(self, key)
            if val ~= nil and cache and not typebuilder.InDefineMode(self) then
                rawset(self, key, val)
            end
            return val
        end,
        __newindex  = function(self, key, value)
            if typebuilder.InDefineMode(self) then
                if setBuilderOwnerValue(typebuilder.GetBuilderOwner(self), key, value, 3) then
                    return
                end
            end
            return rawset(self, key, value)
        end,
        __call      = function(self, ...)
            local definition, stack = typebuilder.GetBuilderParams(self, ...)
            if not definition then error("Usage: struct([env, ][name, ][stack]) (definition) - the definition is missing.", stack) end

            local owner = typebuilder.GetBuilderOwner(self)
            if not owner then error("The struct builder is expired.", stack) end

            stack = stack + 1

            if type(definition) == "function" then
                setfenv(definition, self)
                definition(self)
            else
                -- Check base struct first
                if definition[MTD_BASE] ~= nil then
                    setBuilderOwnerValue(owner, MTD_BASE, definition[MTD_BASE], stack)
                    definition[MTD_BASE] = nil
                end

                -- Index key
                for i, v in ipairs, definition, 0 do
                    setBuilderOwnerValue(owner, i, v, stack)
                end

                for k, v in pairs, definition do
                    if type(k) == "string" then
                        setBuilderOwnerValue(owner, k, v, stack, true)
                    end
                end
            end

            typebuilder.EndDefinition(self, stack)
            struct.EndDefinition(owner, stack)

            return owner
        end,
    }

    -- Key feature : member "Name" { Type = String, Default = "Anonymous", Require = false}
    member          = Prototype.NewPrototype {
        __call      = function(self, ...)
            if self == member then
                local env, name, definition, stack, owner, builder = typebuilder.GetNewFeatureParams(member, ...)
                if not owner or not builder then error([[Usage: member "name" {...} - can't be used here.]], stack) end
                if type(name) ~= "string" then error([[Usage: member "name" {...} - the name must be a string.]], stack) end
                name = strtrim(name)
                if name == "" then error([[Usage: member "name" {...} - the name can't be an empty string.]], stack) end

                if definition then
                    if type(definition) ~= "table" then error([[Usage: member ("name", {...}) - the definition must be a table.]], stack) end
                    struct.AddMember(owner, name, definition, stack + 1)
                else
                    return Prototype.NewObject(member, { name = name, owner = owner })
                end
            else
                local owner, name       = self.owner, self.name
                local definition, stack = typebuilder.GetBuilderParams(self, ...)

                if type(name) ~= "string" then error([[Usage: member "name" {...} - the name must be a string.]], stack) end
                name = strtrim(name)
                if name == "" then error([[Usage: member "name" {...} - the name can't be an empty string.]], stack) end
                if type(definition) ~= "table" then error([[Usage: member ("name", {...}) - the definition must be a table.]], stack) end

                struct.AddMember(owner, name, definition, stack + 1)
            end
        end;
    };

    -- Key feature : endstruct "Number"
    endstruct       = function (...)
        local env, name, definition, stack, owner, builder = typebuilder.GetNewFeatureParams(endstruct, ...)

        if not owner or not builder then error([[Usage: endstruct "name" - can't be used here.]], stack) end
        if namespace.GetNameSpaceName(owner, true) ~= name then error(("%s's definition isn't finished."):format(tostring(owner)), stack) end

        stack = stack + 1

        typebuilder.EndDefinition(builder, stack)
        struct.EndDefinition(owner, stack)

        return typebuilder.GetBuilderEnv(builder)
    end
end

-------------------------------------------------------------------------------
--                             interface & class                             --
-------------------------------------------------------------------------------
do
    local _ICInfo   = setmetatable({}, WEAK_KEY)        -- INTERFACE & CLASS INFO
    local _CLDInfo  = {}                                -- CHILDREN MAP
    local _ThisMap  = setmetatable({}, WEAK_ALL)        -- THIS FOR CLASS
    local _SuperMap = setmetatable({}, WEAK_ALL)        -- SUPER FOR CLASS & INTERFACE
    local _ObjMap   = setmetatable({}, WEAK_KEY)        -- OBJECT -> CLASS INFO MAP
    local _BDInfo   = Prototype.NewObject(threadCache)  -- TYPE BUILDER INFO
    local _SuperObj = Prototype.NewObject(threadCache)  -- SUPER OBJECT CACHE

    local getValueFromBuidler   = typebuilder.GetValueFromBuidler
    local getNameSpace          = namespace.GetNameSpace

    local _IndexMap = {}
    local _NewIdxMap= {}
    local _CtorMap  = {}

    -- FEATURE MODIFIER
    local MD_SEAL   = 2^0           -- SEALED TYPE
    local MD_FINAL  = 2^1           -- FINAL TYPE
    local MD_ABSCLS = 2^2           -- ABSTRACT CLASS
    local MD_ATCACHE= 2^3           -- AUTO CACHE CLASS
    local MD_OBJMDAT= 2^4           -- ENABLE OBJECT METHOD ATTRIBUTE
    local MD_NRAWSET= 2^5           -- NO RAW SET FOR OBJECTS
    local MD_ASSPCLS= 2^6           -- AS A SIMPLE CLASS
    local MD_KPOBJUP= 2^7           -- KEEP UPDATING OBJECT WITH NEW FEATURES

    -- FIELDS
    local FD_MOD    = -1            -- FIELD MODIFIER
    local FD_SUPCLS =  0            -- FIELD SUPER CLASS
    local FD_STEXT  =  1            -- FIELD EXTEND INTERFACE START INDEX(so we can use unpack on it)
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
    local FD_ALTHIS =-18            -- FIELD ALIAS THIS (CONSTRUCTOR)
    local FD_ALSUPER=-19            -- FIELD ALIAS SUPER (CONSTRUCTOR, METHODS FROM SUPER CLASS & EXTENDED INTERFACES)
    local FD_NEWFTR =-20            -- FIELD TYPE NEW FEATURES

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

    -- Flags for constructor
    local FL_EXTOBJ = 2^2           -- HAS __exist
    local FL_NEWOBJ = 2^3           -- HAS __new
    local FL_SIMCLS = 2^4           -- SIMPLE CLASS
    local FL_ASSIMP = 2^5           -- AS SIMPLE CLASS
    local FL_HSCLIN = 2^6           -- HAS CLASS INITIALIZER
    local FL_HASIFS = 2^7           -- NEED CALL INTERFACE'S INITIALIZER
    local FL_MAPOBJ = 2^8           -- MAP THE OBJECT TO INFO

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

    local function getSuperInfos(info, reverse)
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

    local function getSuperOnPriorty(info, name, get)
        local minpriority, norpriority
        for _, sinfo in getSuperInfos(info) do
            local m     = get(sinfo, name)
            if m then
                local priority = sinfo[FD_INHRTP] and sinfo[FD_INHRTP][name] or IP_NORMAL
                if priority == IP_FINAL   then return m end
                if priority == IP_VIRTUAL then
                    minpriority = minpriority or m
                else
                    norpriority = norpriority or m
                end
            end
        end
        return norpriority or minpriority
    end

    local function getSuperMethod(info, name)
        return getSuperOnPriorty(info, name, function(sinfo, name) return sinfo[FD_TYPMTD] and sinfo[FD_TYPMTD][name] end)
    end

    local function getSuperFeature(info, name, ftype)
        local feature   = getSuperOnPriorty(info, name, function(sinfo, name) return sinfo[FD_TYPFTR] and sinfo[FD_TYPFTR][name] end)
        return feature and (not ftype and feature or ftype.Validate(feature)) or nil
    end

    local function getSuperMetaMethod(info, name)
        return getSuperOnPriorty(info, name, function(sinfo, name) return sinfo[FD_TYPMTM] and sinfo[FD_TYPMTM][META_KEYS[name]] end)
    end

    -- Finish Type Building
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

    local function generateCacheOnPriorty(source, target, objpri, inhrtp, super)
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
                            attribute.ConsumeAttributes(value, ATTRIBUTE_TARGETS_FUNCTION, 3)
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
                            attribute.ApplyAfterDefine(value, ATTRIBUTE_TARGETS_FUNCTION, nil, self, name)
                        end
                    ]])
                end
            else
                tinsert(body, [[error("The object is readonly.", 2)]])
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
            local msg = ("The %s is abstract, can't be used to create objects."):format(tostring(target))
            info[FD_CTOR] = function() error(msg, 3) end
            return _Cache(upval)
        end

        tinsert(upval, info)
        tinsert(upval, meta)
        tinsert(upval, target)

        if not validateFlags(MD_KPOBJUP, info[FD_MOD]) then
            token   = turnOnFlags(FL_MAPOBJ, token)
            tinsert(upval, _ObjMap)
        end

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

            if info[FD_OBJMTD] and next(info[FD_OBJMTD]) then
                token   = turnOnFlags(FL_OBJMTD, token)
                tinsert(upval, info[FD_OBJMTD])
            end

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

            if validateFlags(FL_MAPOBJ, token) then
                tinsert(header, "_ObjMap")
            end

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
                        if not ok then error(("The %s's __new meta-method doesn't provide a valid table as object."):format(tostring(_class)), 3) end
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

                    if validateFlags(FL_OBJMTD, token) then
                        tinsert(header, "_mtd")
                        tinsert(body, [[
                            for k in pairs, _mtd do
                                local tk = type(init[k])
                                if tk and tk ~= "function" then
                                    noconflict = false break
                                end
                            end
                        ]])
                    end

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
                        if not ok then error(msg:match("%d+:%s*(.-)$") or msg, 3) end
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

            if validateFlags(FL_MAPOBJ, token) then
                tinsert(body, [[_ObjMap[obj] = _info]])
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

        for _, sinfo in getSuperInfos(info, true) do
            local inhrtp= sinfo[FD_INHRTP]

            if sinfo[FD_TYPMTM] then
                generateCacheOnPriorty(sinfo[FD_TYPMTM], objmeta, objpri, inhrtp)
            end

            if sinfo[FD_TYPFTR] then
                generateCacheOnPriorty(sinfo[FD_TYPFTR], objftr, objpri, inhrtp)
            end

            if sinfo[FD_TYPMTD] then
                generateCacheOnPriorty(sinfo[FD_TYPMTD], objmtd, objpri, inhrtp)
            end
        end

        local inhrtp    = info[FD_INHRTP]
        if info[FD_TYPMTM] then
            generateCacheOnPriorty(info[FD_TYPMTM], objmeta, objpri, inhrtp, super)
        end

        if info[FD_TYPFTR] then
            generateCacheOnPriorty(info[FD_TYPFTR], objftr, objpri, inhrtp, super)
        end

        if info[FD_TYPMTD] then
           generateCacheOnPriorty(info[FD_TYPMTD], objmtd, objpri, inhrtp, super)
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

    -- Shared APIS
    local function checkInfoWithName(tType, target, name, allowDefined)
        local info, def = getTargetInfo(target)
        if not info then return nil, nil, ("The %s is not valid."):format(tostring(tType)) end
        if not allowDefined and not def then return info, nil, ("The %s's definition is finished."):format(tostring(target)) end
        if type(name) ~= "string" then return info, nil, "The name must be a string." end
        name = strtrim(name)
        if name == "" then return info, nil, "The name can't be empty." end
        return info, name, nil, def
    end

    local function reDefineChildren(target, stack)
        local children  = _CLDInfo[target]
        if children then
            for _, child in ipairs, children, 0 do
                if not _BDInfo[child] then  -- Not in defintion mode
                    if interface.Validate(child) then
                        attribute.SuspendConsume()
                        interface.BeginDefinition(child, stack + 1)
                        attribute.ResumeConsume()
                        interface.EndDefinition(child, stack + 1)
                    else
                        attribute.SuspendConsume()
                        class.BeginDefinition(child, stack + 1)
                        attribute.ResumeConsume()
                        class.EndDefinition(child, stack + 1)
                    end
                end
            end
        end
    end

    local function dispatchNewMethod(target, name, func)
        local children  = _CLDInfo[target]
        if children then
            for _, child in ipairs, children, 0 do
                local cinfo = getTargetInfo(child)

                if (cinfo[FD_TYPMTD] == nil or cinfo[FD_TYPMTD][name] == nil) and getSuperMethod(cinfo, name) == func then
                    if cinfo[FD_OBJMTD] then cinfo[FD_OBJMTD][name] = func
                    dispatchNewMethod(child, name, func)
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

        if not info then error(("Usage: %s.AddExtend(%s, extendinterface[, stack]) - "):format(tostring(tType), tostring(tType)) .. msg, stack) end

        if not interface.Validate(extendIF) then error(("Usage: %s.AddExtend(%s, extendinterface[, stack]) - the extendinterface must be an interface."):format(tostring(tType), tostring(tType)), stack) end
        if interface.IsFinal(extendIF) then error(("Usage: %s.AddExtend(%s, extendinterface[, stack]) - The %s is marked as final, can't be extended."):format(tostring(tType), tostring(tType), tostring(extendIF)), stack) end

        -- Check if already extended
        if interface.IsSubType(target, extendIF) then return end

        -- Check the extend interface's require class
        local reqcls = interface.GetRequireClass(extendIF)

        if class.Validate(target) then
            if reqcls and not class.IsSubType(target, reqcls) then
                error(("Usage: class.AddExtend(class, extendinterface[, stack]) - The class must be %s's sub-class."):format(tostring(reqcls)), stack)
            end
        elseif interface.IsSubType(extendIF, target) then
            error("Usage: interface.AddExtend(interface, extendinterface[, stack]) - The extendinterface is a sub type of the interface.", stack)
        elseif reqcls then
            local rcls = interface.GetRequireClass(target)

            if rcls then
                if class.IsSubType(reqcls, rcls) then
                    interface.SetRequireClass(target, reqcls, stack + 1)
                elseif not class.IsSubType(rcls, reqcls) then
                    error(("Usage: interface.AddExtend(interface, extendinterface[, stack]) - The interface's require class must be %s's sub-class."):format(tostring(reqcls)), stack)
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

        if msg then error(("Usage: %s.AddFeature(%s, featureType, name[, definition][, stack]) - "):format(tostring(tType), tostring(tType)) .. msg, stack) end

        if not Prototype.Validate(ftype) then error(("Usage: %s.AddFeature(%s, featureType, name[, definition][, stack]) - the featureType is not valid."):format(tostring(tType), tostring(tType)), stack) end
        if META_KEYS[name] or name == MTD_DISPOB then error(("Usage: Usage: %s.AddFeature(%s, featureType, name[, definition][, stack]) - The %s can't be used as feature name."):format(tostring(tType), tostring(tType), name), stack) end

        local f = ftype.BeginDefinition(target, name, definition, getSuperFeature(info, name, ftype), stack + 1)

        if f then
            info[FD_TYPFTR]         = info[FD_TYPFTR] or _Cache()
            info[FD_TYPFTR][name]   = f

            info[FD_NEWFTR]         = info[FD_NEWFTR] or _Cache()
            info[FD_NEWFTR][name]   = true
        else
            error(("Usage: Usage: %s.AddFeature(%s, featureType, name[, definition][, stack]) - The feature's creation failed."):format(tostring(tType), tostring(tType)), stack)
        end
    end

    local function addMethod(tType, target, name, func, stack)
        local info, name, msg, def  = checkInfoWithName(tType, target, name, true)
        stack = (type(stack) == "number" and stack or 2) + 1

        if msg then error(("Usage: %s.AddMethod(%s, name, func[, stack]) - "):format(tostring(tType), tostring(tType)) .. msg, stack) end

        if META_KEYS[name] or name == MTD_DISPOB then error(("Usage: Usage: %s.AddMethod(%s, name, func[, stack]) - The %s can't be used as method name."):format(tostring(tType), tostring(tType), name), stack) end
        if type(func) ~= "function" then error(("Usage: %s.AddMethod(%s, name, func[, stack]) - the func must be a function."):format(tostring(tType), tostring(tType)), stack) end

        if not def then
            if info[FD_TYPMTD] and info[FD_TYPMTD][name] ~= nil or info[FD_OBJMTD] and info[FD_OBJMTD][name] then
                error(("Usage: %s.AddMethod(%s, name, func[, stack]) - The %s's definition is finished, a method already existed with the name %q."):format(tostring(tType), tostring(tType), tostring(target), name), stack)
            elseif info[FD_TYPFTR] and info[FD_TYPFTR][name] ~= nil or info[FD_OBJFTR] and info[FD_OBJFTR][name] then
                error(("Usage: %s.AddMethod(%s, name, func[, stack]) - The %s's definition is finished, a feature already existed with the name %q."):format(tostring(tType), tostring(tType), tostring(target), name), stack)
            end

            beginDefinition(target, stack + 1)

            if info[FD_TYPMTD] and info[FD_TYPMTD][name] ~= nil or info[FD_OBJMTD] and info[FD_OBJMTD][name] or info[FD_TYPFTR] and info[FD_TYPFTR][name] ~= nil or info[FD_OBJFTR] and info[FD_OBJFTR][name] then
                endDefinition(target, stack + 1, true)
                return
            end
        end

        local nStatic   = not info[name]

        attribute.ConsumeAttributes(func, ATTRIBUTE_TARGETS_METHOD, stack + 1)
        func = attribute.ApplyAttributes(func, ATTRIBUTE_TARGETS_METHOD, nil, target, name, nStatic and getSuperMethod(info, name) or nil)

        if nStatic then
            info[FD_TYPMTD] = info[FD_TYPMTD] or _Cache()
            info[FD_TYPMTD][name] = func
        else
            info[name]      = func
        end

        attribute.ApplyAfterDefine(func, ATTRIBUTE_TARGETS_METHOD, nil, target, name)

        if not def then
            if info[FD_OBJMTD] then info[FD_OBJMTD][name] = func end
            dispatchNewMethod(target, name, func)
            endDefinition(target, stack + 1, true)
        end
    end

    local function addMetaMethod(tType, target, name, func, stack)
        stack = (type(stack) == "number" and stack or 2) + 1

        local info, def = getTargetInfo(target)

        if info then
            if type(name) ~= "string" then error(("Usage: %s.AddMetaMethod(%s, name, func[, stack]) - the name must be a string."):format(tostring(tType), tostring(tType)), stack) end
            name = strtrim(name)
            if name == "" then error(("Usage: Usage: %s.AddMetaMethod(%s, name, func[, stack]) - The name can't be empty."):format(tostring(tType), tostring(tType)), stack) end
            if not META_KEYS[name] then error(("Usage: Usage: %s.AddMetaMethod(%s, name, func[, stack]) - The name isn't a valid meta-method name."):format(tostring(tType), tostring(tType)), stack) end

            local tfunc = type(func)

            if name ~= MTD_INDEX and tfunc ~= "function" then error(("Usage: %s.AddMetaMethod(%s, name, func[, stack]) - the func must be a function."):format(tostring(tType), tostring(tType)), stack) end
            if name == MTD_INDEX and tfunc ~= "function" and tfunc ~= "table" then error(("Usage: %s.AddMetaMethod(%s, name, func[, stack]) - the func must be a function or table for '__index'."):format(tostring(tType), tostring(tType)), stack) end
            if not def then error(("Usage: %s.AddMetaMethod(%s, name, func[, stack]) - The %s's definition is finished."):format(tostring(tType), tostring(tType), tostring(target)), stack) end

            if tfunc == "function" then
                attribute.ConsumeAttributes(func, ATTRIBUTE_TARGETS_METAMETHOD, stack + 1)
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
                attribute.ApplyAfterDefine(func, ATTRIBUTE_TARGETS_METAMETHOD, nil, target, name)
            end
        else
            error(("Usage: %s.AddMetaMethod(%s, name, func[, stack]) - The is not valid."):format(tostring(tType), tostring(tType)), stack)
        end
    end

    local function setDispose(tType, target, func, stack)
        local info, def = getTargetInfo(target)
        stack = (type(stack) == "number" and stack or 2) + 1

        if info then
            if type(func) ~= "function" then error(("Usage: %s.SetDispose(%s, func[, stack]) - the func must be a function."):format(tostring(tType), tostring(tType)), stack) end
            if not def then error(("Usage: %s.SetDispose(%s, func[, stack]) - The %s's definition is finished."):format(tostring(tType), tostring(tType), tostring(target)), stack) end

            info[FD_DISPOSE] = func
        else
            error(("Usage: %s.SetDispose(%s, func[, stack]) - The %s is not valid."):format(tostring(tType), tostring(tType), tostring(tType)), stack)
        end
    end

    local function setModifiedFlag(tType, target, flag, methodName, stack)
        local info, def = getTargetInfo(target)
        stack = (type(stack) == "number" and stack or 2) + 1

        if info then
            if not def then error(("Usage: %s.%s(%s[, stack]) - The %s's definition is finished."):format(tostring(tType), methodName, tostring(tType), tostring(target)), stack) end
            if not validateFlags(flag, info[FD_MOD]) then
                info[FD_MOD] = turnOnFlags(flag, info[FD_MOD])
            end
        else
            error(("Usage: %s.%s(%s[, stack]) - The %s is not valid."):format(tostring(tType), methodName, tostring(tType), tostring(tType)), stack)
        end
    end

    local function setStaticFeature(tType, target, name, stack)
        local info, def = getTargetInfo(target)
        stack = (type(stack) == "number" and stack or 2) + 1

        if info then
            if type(name) ~= "string" then error(("Usage: %s.SetStaticFeature(%s, name[, stack]) - the name must be a string."):format(tostring(tType), tostring(tType)), stack) end
            name = strtrim(name)
            if name == "" then error(("Usage: %s.SetStaticFeature(%s, name[, stack]) - The name can't be empty."):format(tostring(tType), tostring(tType)), stack) end
            if not def then error(("Usage: %s.SetStaticFeature(%s, name[, stack]) - The %s's definition is finished."):format(tostring(tType), tostring(tType), tostring(target)), stack) end
            if not (info[FD_NEWFTR] and info[FD_NEWFTR][name]) then
                if info[FD_STAFTR] and info[FD_STAFTR][name] or info[FD_OBJFTR] and info[FD_OBJFTR][name] then
                    error(("Usage: %s.SetStaticFeature(%s, name[, stack]) - The %s's %q's definition is finished, can't set as static."):format(tostring(tType), tostring(tType), tostring(target), name), stack)
                else
                    error(("Usage: %s.SetStaticFeature(%s, name[, stack]) - The %s has no feature named %q."):format(tostring(tType), tostring(tType), tostring(target), name), stack)
                end
            end

            local feature = info[FD_NEWFTR][name]
            getmetatable(feature).SetStatic(feature, stack + 1)
        else
            error(("Usage: %s.SetStaticFeature(%s, name[, stack]) - The %s is not valid."):format(tostring(tType), tostring(tType), tostring(tType)), stack)
        end
    end

    local function setStaticMethod(tType, target, name, stack)
        local info, def = getTargetInfo(target)
        stack = (type(stack) == "number" and stack or 2) + 1

        if info then
            if type(name) ~= "string" then error(("Usage: %s.SetStaticMethod(%s, name[, stack]) - the name must be a string."):format(tostring(tType), tostring(tType)), stack) end
            name = strtrim(name)
            if name == "" then error(("Usage: %s.SetStaticMethod(%s, name[, stack]) - The name can't be empty."):format(tostring(tType), tostring(tType)), stack) end
            if not def then error(("Usage: %s.SetStaticMethod(%s, name[, stack]) - The %s's definition is finished."):format(tostring(tType), tostring(tType), tostring(target)), stack) end
            if not (info[FD_TYPMTD] and info[FD_TYPMTD][name] ~= nil) then error(("Usage: %s.SetStaticMethod(%s, name[, stack]) - The %s has no method named %q."):format(tostring(tType), tostring(tType), tostring(target), name), stack) end
            if info[FD_TYPMTD][name] == true then error(("Usage: %s.SetStaticMethod(%s, name[, stack]) - The %q is a require method."):format(tostring(tType), tostring(tType), name), stack) end

            if info[name] == nil then
                info[name] = info[FD_TYPMTD][name]
                info[FD_TYPMTD][name] = false
            end
        else
            error(("Usage: %s.SetStaticMethod(%s, name[, stack]) - The %s is not valid."):format(tostring(tType), tostring(tType), tostring(tType)), stack)
        end
    end

    local function setVirtualMethod(tType, target, name, stack)
        local info, def = getTargetInfo(target)
        stack = (type(stack) == "number" and stack or 2) + 1

        if info then
            if type(name) ~= "string" then error(("Usage: %s.SetVirtualMethod(%s, name[, stack]) - the name must be a string."):format(tostring(tType), tostring(tType)), stack) end
            name = strtrim(name)
            if name == "" then error(("Usage: %s.SetVirtualMethod(%s, name[, stack]) - The name can't be empty."):format(tostring(tType), tostring(tType)), stack) end
            if not def then error(("Usage: %s.SetVirtualMethod(%s, name[, stack]) - The %s's definition is finished."):format(tostring(tType), tostring(tType), tostring(target)), stack) end
            if not (info[FD_TYPMTD] and info[FD_TYPMTD][name] ~= nil) then error(("Usage: %s.SetVirtualMethod(%s, name[, stack]) - The %s has no method named %q."):format(tostring(tType), tostring(tType), tostring(target), name), stack) end
            if info[FD_TYPMTD][name] == true then error(("Usage: %s.SetVirtualMethod(%s, name[, stack]) - The %q is a require method."):format(tostring(tType), tostring(tType), name), stack) end

            if info[name] == nil then
                info[name] = info[FD_TYPMTD][name]
                info[FD_TYPMTD][name] = false
            end
        else
            error(("Usage: %s.SetVirtualMethod(%s, name[, stack]) - The %s is not valid."):format(tostring(tType), tostring(tType), tostring(tType)), stack)
        end
    end

    local function setVirtualFeature(tType, target, name, stack)
    end

    local function setVirtualMetaMethod(tType, target, name, stack)
    end

    -- Buidler helpers
    local function dispatchNewFeatures(target, stack)
        local info = getTargetInfo(target)

        if info[FD_NEWFTR] then
            info[FD_TYPFTR] = info[FD_TYPFTR] or _Cache()

            for name, ftr in pairs, info[FD_NEWFTR] do
                local ftype = getmetatable(ftr)
                ftype.EndDefinition(ftr, target, name, stack + 1)

                info[FD_TYPFTR][name]       = ftr

                if ftype.IsStatic(ftr) then
                    info[FD_STAFTR]         = info[FD_STAFTR] or _Cache()
                    info[FD_STAFTR][name]   = ftr
                else
                    info[FD_OBJFTR]         = info[FD_OBJFTR] or _Cache()
                    info[FD_OBJFTR][name]   = ftr
                end
            end

            _Cache(info[FD_NEWFTR])
            info[FD_NEWFTR] = nil
        end
    end

    local function getIfBuilderValue(self, name)
        -- Access methods
        local info = getTargetInfo(typebuilder.GetBuilderOwner(self))
        if info and info[name] then return info[name], true end
        return getValueFromBuidler(self, name)
    end

    local function getClsBuilderValue(self, name)
        -- Access methods
        local info = getTargetInfo(typebuilder.GetBuilderOwner(self))
        if info and info[name] then return info[name], true end
        return getValueFromBuidler(self, name)
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
            elseif namespace.IsFeatureType(value) then
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
            elseif namespace.IsFeatureType(value) then
                struct.SetArrayElement(owner, value, stack)
            elseif tval == "table" then
                struct.AddMember(owner, value, stack)
            else
                struct.SetDefault(owner, value, stack)
            end
            return true
        end
    end

    interface       = Prototype.NewPrototype {
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

                local info      = _ICInfo[target]
                if info and validateFlags(MD_SEAL, info[FD_MOD]) then error(("Usage: interface.BeginDefinition(interface[, stack]) - The %s is sealed, can't be re-defined."):format(tostring(target)), stack) end
                if _BDInfo[target] then error(("Usage: interface.BeginDefinition(interface[, stack]) - The %s's definition has already begun."):format(tostring(target)), stack) end

                -- Only one thread can be allowed to define class or interface
                beginDefinition(target, stack + 1)

                local ninfo     = _Cache()

                ninfo[FD_SUPCACH] = false
                ninfo[FD_OBJFTR]  = false
                ninfo[FD_OBJMTD]  = false
                ninfo[FD_OBJMTM]  = false
                tblclone(info, ninfo, true)
                ninfo[FD_SUPCACH] = nil
                ninfo[FD_OBJFTR]  = nil
                ninfo[FD_OBJMTD]  = nil
                ninfo[FD_OBJMTM]  = nil

                _BDInfo[target] = ninfo

                attribute.ConsumeAttributes(target, ATTRIBUTE_TARGETS_INTERFACE, stack + 1)
            end;

            ["EndDefinition"]   = function(target, stack)
                local ninfo     = _BDInfo[target]
                if not ninfo then return end

                stack = type(stack) == "number" and stack or 2

                attribute.ApplyAttributes(target, ATTRIBUTE_TARGETS_INTERFACE, nil, nil, nil, unpack(ninfo, FD_STEXT))

                -- End new type feature's definition
                dispatchNewFeatures(target, stack + 1)

                -- Re-generate the extended interfaces order list
                local lst, spc  = generateSuperInfo(ninfo, _Cache())
                local idxIF     = FD_STEXT + #lst

                for i, extif in ipairs, lst, 0 do
                    ninfo[idxIF - i]= extif
                end

                _Cache(lst)

                -- Check require methods and features
                -- Generate the super cache



                local onlyreq       = nil
                for k, v in pairs, getUniqueReqMethod(ninfo) do if onlyreq then onlyreq = nil break else onlyreq = k end end
                ninfo[FD_ONEVRM]    = onlyreq

                -- End interface's definition
                _BDInfo[target]     = nil

                -- Save as new interface's info
                _ICInfo[target]     = ninfo

                -- Release the lock, so other threads can be used to define interface or class
                endDefinition(target, stack + 1)

                attribute.ApplyAfterDefine(target, ATTRIBUTE_TARGETS_INTERFACE)

                return target
            end;

            ["GetExtends"]      = function(target, cache)
                local info      = getTargetInfo(target)
                if info then
                    if cache then
                        cache   = type(cache) == "table" and wipe(cache) or _Cache()
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
                    local featr = def and info[FD_NEWFTR] and info[FD_NEWFTR][name] or info[FD_TYPFTR] and info[FD_TYPFTR][name]
                    return featr and getmetatable(featr).GetFeature(featr)
                end
            end;

            ["GetObjectFeature"]= function(target, name)
                local info, def = getTargetInfo(target)
                if info and type(name) == "string" then
                    local featr = def and info[FD_NEWFTR] and info[FD_NEWFTR][name] or info[FD_TYPFTR] and info[FD_TYPFTR][name]
                    if featr then
                        local t = getmetatable(featr)
                        if not t.IsStatic(featr) then return t.GetFeature(featr) end
                    end
                end
            end;

            ["GetStaticFeature"]= function(target, name)
                local info, def = getTargetInfo(target)
                if info and type(name) == "string" then
                    local featr = def and info[FD_NEWFTR] and info[FD_NEWFTR][name] or info[FD_TYPFTR] and info[FD_TYPFTR][name]
                    if featr then
                        local t = getmetatable(featr)
                        if t.IsStatic(featr) then return t.GetFeature(featr) end
                    end
                end
            end;

            ["GetFeatures"]     = function(target, cache)
                local info      = getTargetInfo(target)
                if info then
                    if cache then
                        cache   = type(cache) == "table" and wipe(cache) or _Cache()

                        if def and info[FD_NEWFTR] then for k, v in pairs, info[FD_NEWFTR] do cache[k] = getmetatable(v).GetFeature(v) end end
                        if info[FD_TYPFTR] then for k, v in pairs, info[FD_TYPFTR] do if not cache[k] then cache[k] = getmetatable(v).GetFeature(v) end end end

                        return cache
                    else
                        local nf = def and info[FD_NEWFTR]
                        local tf = info[FD_TYPFTR]
                        local bnf= nf
                        return function(self, n)
                            local v
                            if nf then
                                n, v    = next(nf, n)
                                if v then return n, getmetatable(v).GetFeature(v) end
                                nf, n   = nil
                            end
                            if tf then
                                n, v    = next(tf, n)
                                while n and bnf and bnf[n] do n, v = next(tf, n) end
                                if v then return n, getmetatable(v).GetFeature(v) end
                            end
                        end, target
                    end
                elseif not cache then
                    return fakefunc, target
                end
            end;

            ["GetObjectFeatures"]= function(target, cache)
                local info      = getTargetInfo(target)
                if info then
                    if cache then
                        cache   = type(cache) == "table" and wipe(cache) or _Cache()

                        if def and info[FD_NEWFTR] then for k, v in pairs, info[FD_NEWFTR] do if not getmetatable(v).IsStatic(v) then cache[k] = getmetatable(v).GetFeature(v) end end end
                        if info[FD_TYPFTR] then for k, v in pairs, info[FD_TYPFTR] do if not cache[k] and not getmetatable(v).IsStatic(v) then cache[k] = getmetatable(v).GetFeature(v) end end end

                        return cache
                    else
                        local nf = def and info[FD_NEWFTR]
                        local tf = info[FD_TYPFTR]
                        local bnf= nf
                        return function(self, n)
                            local v
                            if nf then
                                n, v    = next(nf, n)
                                while n and getmetatable(v).IsStatic(v) do n, v = next(nf, n) end
                                if v then return n, getmetatable(v).GetFeature(v) end
                                nf, n   = nil
                            end
                            if tf then
                                n, v    = next(tf, n)
                                while n and (bnf and bnf[n] or getmetatable(v).IsStatic(v)) do n, v = next(tf, n) end
                                if v then return n, getmetatable(v).GetFeature(v) end
                            end
                        end, target
                    end
                elseif not cache then
                    return fakefunc, target
                end
            end;

            ["GetStaticFeatures"]= function(target, cache)
                local info      = getTargetInfo(target)
                if info then
                    if cache then
                        cache   = type(cache) == "table" and wipe(cache) or _Cache()

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
                elseif not cache then
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
                        cache   = type(cache) == "table" and wipe(cache) or _Cache()
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
                elseif not cache then
                    return fakefunc, target
                end
            end;

            ["GetObjectMethods"]= function(target, cache)
                local info      = getTargetInfo(target)
                if info then
                    local obm   = info[FD_TYPMTD]
                    if cache then
                        cache   = type(cache) == "table" and wipe(cache) or _Cache()
                        if obm then for k, v in pairs, info do if obm[k] then cache[k] = v end end end
                        return cache
                    elseif obm then
                        return function(self, n)
                            local v
                            n, v    = next(info, n)
                            while n and not obm[n] do n, v = next(info, n) end
                            if v then return n, v end
                        end, target
                    else
                        return fakefunc, target
                    end
                elseif not cache then
                    return fakefunc, target
                end
            end;

            ["GetStaticMethods"]= function(target, cache)
                local info      = getTargetInfo(target)
                if info then
                    local obm   = info[FD_TYPMTD]
                    if cache then
                        cache   = type(cache) == "table" and wipe(cache) or _Cache()
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
                elseif not cache then
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
                    if not def then error(("Usage: interface.SetInitializer(interface, initializer[, stack]) - The %s's definition is finished."):format(tostring(target)), stack) end
                    if type(func) ~= "function" then error("Usage: interface.SetInitializer(interface, initializer) - The initializer must be a function.", stack) end
                    info[FD_INIT] = func
                else
                    error("Usage: interface.SetInitializer(interface, initializer[, stack]) - The interface is not valid.", stack)
                end
            end;

            ["SetRequireClass"] = function(target, cls, stack)
                stack = type(stack) == "number" and stack or 2

                if not interface.Validate(target) then error("Usage: interface.SetRequireClass(interface, requireclass[, stack]) - the interface is not valid.", stack) end

                local info, def = getTargetInfo(target)

                if info then
                    if not class.Validate(cls) then error("Usage: interface.SetRequireClass(interface, requireclass[, stack]) - the requireclass must be a class.", stack) end
                    if not def then error(("Usage: interface.SetRequireClass(interface, requireclass[, stack]) - The %s' definition is finished."):format(tostring(target)), stack) end
                    if info[FD_REQCLS] and not class.IsSubType(cls, info[FD_REQCLS]) then error(("Usage: interface.SetRequireClass(interface, requireclass[, stack]) - The requireclass must be %s's sub-class."):format(tostring(info[FD_REQCLS])), stack) end

                    info[FD_REQCLS] = cls
                else
                    error("Usage: interface.SetRequireClass(interface, requireclass[, stack]) - The interface is not valid.", stack)
                end
            end;

            ["SetRequireFeature"]= function(target, name)
                local info, def = getTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    if type(name) ~= "string" then error("Usage: interface.SetRequireFeature(interface, name[, stack]) - the name must be a string.", stack) end
                    name = strtrim(name)
                    if name == "" then error("Usage: interface.SetRequireFeature(interface, name[, stack]) - The name can't be empty.", stack) end
                    if not def then error(("Usage: interface.SetRequireFeature(interface, name[, stack]) - The %s's definition is finished."):format(tostring(target)), stack) end
                    if not (info[FD_NEWFTR] and info[FD_NEWFTR][name]) then
                        if info[FD_STAFTR] and info[FD_STAFTR][name] or info[FD_OBJFTR] and info[FD_OBJFTR][name] then
                            error(("Usage: interface.SetRequireFeature(interface, name[, stack]) - The %s's %q's definition is finished, can't set as require."):format(tostring(target), name), stack)
                        else
                            error(("Usage: interface.SetRequireFeature(interface, name[, stack]) - The %s has no feature named %q."):format(tostring(target), name), stack)
                        end
                    end

                    local feature = info[FD_NEWFTR][name]
                    getmetatable(feature).SetRequire(feature, stack + 1)
                else
                    error("Usage: interface.SetRequireFeature(interface, name[, stack]) - The interface is not valid.", stack)
                end
            end;

            ["SetRequireMethod"]= function(target, name, stack)
                local info, def = getTargetInfo(target)
                stack = (type(stack) == "number" and stack or 2) + 1

                if info then
                    if type(name) ~= "string" then error("Usage: interface.SetRequireMethod(interface, name[, stack]) - the name must be a string.", stack) end
                    name = strtrim(name)
                    if name == "" then error("Usage: interface.SetRequireMethod(interface, name[, stack]) - The name can't be empty.", stack) end
                    if not def then error(("Usage: interface.SetRequireMethod(interface, name[, stack]) - The %s's definition is finished."):format(tostring(target)), stack) end
                    if not info[name] then error(("Usage: interface.SetRequireMethod(interface, name[, stack]) - The %s has no method named %q."):format(tostring(target), name), stack) end
                    if not (info[FD_TYPMTD] and info[FD_TYPMTD][name]) then error(("Usage: interface.SetRequireMethod(interface, name[, stack]) - The %q is a static method."):format(name), stack) end

                    info[FD_TYPMTD][name] = true
                else
                    error("Usage: interface.SetRequireMethod(interface, name[, stack]) - The interface is not valid.", stack)
                end
            end;

            ["SetRequireMetaMethod"] = function(target, name, stack)
                local info, def = getTargetInfo(target)
                stack = (type(stack) == "number" and stack or 2) + 1

                if info then
                    if type(name) ~= "string" then error("Usage: interface.SetRequireMetaMethod(interface, name[, stack]) - the name must be a string.", stack) end
                    name = strtrim(name)
                    if name == "" then error("Usage: interface.SetRequireMetaMethod(interface, name[, stack]) - The name can't be empty.", stack) end
                    if not def then error(("Usage: interface.SetRequireMetaMethod(interface, name[, stack]) - The %s's definition is finished."):format(tostring(target)), stack) end
                    if not info[name] then error(("Usage: interface.SetRequireMetaMethod(interface, name[, stack]) - The %s has no method named %q."):format(tostring(target), name), stack) end
                    if not (info[FD_TYPMTD] and info[FD_TYPMTD][name]) then error(("Usage: interface.SetRequireMetaMethod(interface, name[, stack]) - The %q is a static method."):format(name), stack) end

                else
                    error("Usage: interface.SetRequireMetaMethod(interface, name[, stack]) - The interface is not valid.", stack)
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
        __concat    = typeconcat,
        __tostring  = function() return "interface" end,
        __call      = function(self, ...)
            local env, target, definition, keepenv, stack = typebuilder.GetNewTypeParams(interface, tinterface, ...)
            if not target then error("Usage: interface([env, ][name, ][definition, ][keepenv, ][, stack]) - the interface type can't be created.", stack) end

            interface.BeginDefinition(target, stack + 1)

            local builder = typebuilder.NewBuilder(interfacebuilder, target, env)

            if definition then
                builder(definition, stack + 1)
                return target
            else
                if not keepenv then setfenv(stack, builder) end
                return builder
            end
        end,
    }

    class           = Prototype.NewPrototype {
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

                if info and validateFlags(MD_SEAL, info[FD_MOD]) then error(("Usage: class.BeginDefinition(class[, stack]) - The %s is sealed, can't be re-defined."):format(tostring(target)), stack) end
                if _BDInfo[target] then error(("Usage: class.BeginDefinition(class[, stack]) - The %s's definition has already begun."):format(tostring(target)), stack) end

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

                attribute.ConsumeAttributes(target, ATTRIBUTE_TARGETS_CLASS, stack + 1)
            end;

            ["EndDefinition"]   = function(target, stack)
                local ninfo     = _BDInfo[target]
                if not ninfo then return end

                stack = type(stack) == "number" and stack or 2

                attribute.ApplyAttributes(target, ATTRIBUTE_TARGETS_CLASS, nil, nil, nil, unpack(ninfo, ninfo[FD_SUPCLS] and FD_SUPCLS or FD_STEXT))

                -- End new type feature's definition
                dispatchNewFeatures(target, stack + 1)

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

            ["IsObjectKeepUpdating"] = function(target)
                local info      = getTargetInfo(target)
                return info and validateFlags(MD_KPOBJUP, info[FD_MOD]) or false
            end;

            ["IsObjMethodAttrEnabled"] = function(target)
                local info      = getTargetInfo(target)
                return info and validateFlags(MD_OBJMDAT, info[FD_MOD]) or false
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

            ["IsStaticFeature"] = interface.IsStaticFeature;

            ["IsStaticMethod"]  = interface.IsStaticMethod;

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
                    if not def then error(("Usage: class.SetConstructor(class, constructor[, stack]) - The %s's definition is finished."):format(tostring(target)), stack) end
                    if type(func) ~= "function" then error("Usage: class.SetConstructor(class, constructor) - The constructor must be a function.", stack) end

                    attribute.ConsumeAttributes(func, ATTRIBUTE_TARGETS_CONSTRUCTOR, stack + 1)
                    func = attribute.ApplyAttributes(func, ATTRIBUTE_TARGETS_CONSTRUCTOR, nil, target, name)

                    info[FD_INIT] = func

                    attribute.ApplyAfterDefine(func, ATTRIBUTE_TARGETS_CONSTRUCTOR, nil, target, name)
                else
                    error("Usage: class.SetConstructor(class, constructor[, stack]) - The class is not valid.", stack)
                end
            end;

            ["SetDispose"]      = function(target, func, stack)
                setDispose(class, target, func, stack)
            end;

            ["SetFinal"]        = function(target, stack)
                setModifiedFlag(class, target, MD_FINAL, "SetFinal", stack)
            end;

            ["SetObjectKeepUpdating"] = function(target, stack)
                setModifiedFlag(class, target, MD_KPOBJUP, "SetObjectKeepUpdating", stack)
            end;

            ["SetObjMethodAttrEnabled"] = function(target, stack)
                setModifiedFlag(class, target, MD_OBJMDAT, "SetObjMethodAttrEnabled", stack)
            end;

            ["SetRawSetBlocked"]= function(target, stack)
                setModifiedFlag(class, target, MD_NRAWSET, "SetRawSetBlocked", stack)
            end;

            ["SetSealed"]       = function(target, stack)
                setModifiedFlag(class, target, MD_SEAL, "SetSealed", stack)
            end;

            ["SetSuperClass"]   = function(target, cls, stack)
                stack = type(stack) == "number" and stack or 2

                if not class.Validate(target) then error("Usage: class.SetSuperClass(class, superclass[, stack]) - the class is not valid.", stack) end

                local info, def = getTargetInfo(target)

                if info then
                    if not class.Validate(cls) then error("Usage: class.SetSuperClass(class, superclass[, stack]) - the superclass must be a class.", stack) end
                    if not def then error(("Usage: class.SetSuperClass(class, superclass[, stack]) - The %s' definition is finished."):format(tostring(target)), stack) end
                    if info[FD_SUPCLS] and info[FD_SUPCLS] ~= cls then error(("Usage: class.SetSuperClass(class, superclass[, stack]) - The %s already has a super class."):format(tostring(target)), stack) end

                    if info[FD_SUPCLS] then return end

                    addSuperType(info, target, cls)
                else
                    error("Usage: class.SetSuperClass(class, superclass[, stack]) - The class is not valid.", stack)
                end
            end;

            ["SetStaticFeature"]= function(target, name, stack)
                setStaticFeature(class, target, name, stack)
            end;

            ["SetStaticMethod"] = function(target, name, stack)
                setStaticMethod(class, target, name, stack)
            end;

            ["ValidateValue"]   = function(cls, value)
                local ocls      = getmetatable(value)
                if not ocls     then return false end
                if ocls == cls  then return true end
                local info      = _ObjMap[value] or getTargetInfo(ocls)
                return info and info[FD_SUPINFO] and info[FD_SUPINFO][cls] and true or false
            end;

            ["Validate"]        = function(target)
                return getmetatable(target) == class and getTargetInfo(target) and target or nil
            end;
        },
        __newindex  = readOnly,
        __concat    = typeconcat,
        __tostring  = function() return "class" end,
        __call      = function(self, ...)
            local env, target, definition, keepenv, stack = typebuilder.GetNewTypeParams(class, tclass, ...)
            if not target then error("Usage: class([env, ][name, ][definition, ][keepenv, ][, stack]) - the class type can't be created.", stack) end

            class.BeginDefinition(target, stack + 1)

            local builder = typebuilder.NewBuilder(classbuilder, target, env)

            if definition then
                builder(definition, stack + 1)
                return target
            else
                if not keepenv then setfenv(stack, builder) end
                return builder
            end
        end,
    }

    tinterface      = Prototype.NewPrototype(tnamespace, {
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
                return getNameSpace(self, key)
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

            error(("The %s is readonly."):format(tostring(self)), 2)
        end,
        __call      = function(self, init)
            local info  = _ICInfo[self]
            if type(init) == "string" then
                local ret, msg = struct.ValidateValue(Lambda, init)
                if msg then error(("Usage: %s(init) - "):format(tostring(self)) .. (type(msg) == "string" and msg:gsub("%%s%.?", "init") or "the init is not valid."), 2) end
                init    = ret
            end

            if type(init) == "function" then
                if not info[FD_ONEVRM] then error(("Usage: %s(init) - the interface isn't an one method required interface."):format(tostring(self)), 2) end
                init    = { [info[FD_ONEVRM]] = init }
            end

            if init and type(init) ~= "table" then error(("Usage: %s(init) - the init can only be lambda expression, function or table."):format(tostring(self)), 2) end

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

    tclass          = Prototype.NewPrototype(tinterface, {
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

            error(("The %s is readonly."):format(tostring(self)), 2)
        end,
        __call      = function(self, ...)
            local info  = _ICInfo[self]
            local obj   = info[FD_CTOR](...)
            return obj
        end,
        __metatable = class,
    })

    tSuperInterface = Prototype.NewPrototype {
        __index     = function(self, key)
            local t = type(key)

            if t == "string" then
                local obj = _SuperObj[self]
                if obj then
                    _SuperObj[self] = nil
                    local info  = _ObjMap[obj] or getTargetInfo(getmetatable(obj))
                    if not info then error("Usage: Super[obj].Method(obj, [...]) - Can't figure out the obj's class.", 2) end
                    return getSuperMethod(info, key, _SuperMap[self])
                else
                    local info  = _ICInfo[_SuperMap[self]]
                    if not info then error("Usage: Super.Method(obj, [...]) - Can't figure out the type that the super represent.", 2) end
                    local f     = info[FD_SUPCACH][key]
                    if not f then
                        if META_KEYS[key] then
                            f   = getSuperMetaMethod(info, key)
                        else
                            f   = getSuperMethod(info, key) or getSuperFeature(info, key)
                        end
                        info[FD_SUPCACH][key] = f
                    end
                    if type(f) ~= "function" then error(("No method named %q can be find in Super."):format(key), 2) end
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

    tSuperClass     = Prototype.NewPrototype (tSuperInterface, {
        __call      = function(self, obj, ...)

        end,
        __metatable = class,
    })

    tThisClass      = Prototype.NewPrototype {
        __call      = function(self, obj, ...)

        end,
        __metatable = class,
    }

    interfacebuilder= Prototype.NewPrototype {
        __index     = function(self, key)
            local val, cache = getBuilderValue(self, key)
            if val ~= nil and cache and not typebuilder.InDefineMode(self) then
                rawset(self, key, val)
            end
            return val
        end,
        __newindex  = function(self, key, value)
            if typebuilder.InDefineMode(self) then
                if setBuilderOwnerValue(typebuilder.GetBuilderOwner(self), key, value, 3) then                     return
                end
            end
            return rawset(self, key, value)
        end,
        __call      = function(self, ...)
            local definition, stack = typebuilder.GetBuilderParams(self, ...)
            if not definition then error("Usage: struct([env, ][name, ][stack]) (definition) - the definition is missing.", stack) end

            local owner = typebuilder.GetBuilderOwner(self)
            if not owner then error("The struct builder is expired.", stack) end

            stack = stack + 1

            if type(definition) == "function" then
                setfenv(definition, self)
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

            typebuilder.EndDefinition(self, stack)
            struct.EndDefinition(owner, stack)

            return owner
        end,
    }

    classbuilder    = Prototype.NewPrototype( interfacebuilder, {

    })

    typefeature     = Prototype.NewPrototype {
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
    local _EvtInfo  = setmetatable({}, WEAK_KEY)

    local FD_NAME   = 0
    local FD_OWNER  = 1
    local FD_STATIC = 2
    local FD_INDEF  = 3

    -- Key feature : event "Name"
    event           = Prototype.NewPrototype (typefeature, {
        __index     = {
            ["BeginDefinition"] = function(owner, name, definition, super, stack)
                local evt       = Prototype.NewPrototype(tevent)
                _EvtInfo[evt]   = setmetatable({ [FD_NAME] = name, [FD_OWNER] = owner, [FD_INDEF] = true }, WEAK_KEY)

                attribute.ConsumeAttributes(evt, ATTRIBUTE_TARGETS_EVENT, stack + 1)
                attribute.ApplyAttributes  (evt, ATTRIBUTE_TARGETS_EVENT, nil, owner, name, super)

                return evt
            end;

            ["EndDefinition"]   = function(feature, owner, name)
                attribute.ApplyAfterDefine (feature, ATTRIBUTE_TARGETS_EVENT, nil, owner, name)

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
                        error("Usage: event.SetStatic(event[, stack]) - The event's definition is finished.", stack)
                    end
                else
                    error("Usage: event.SetStatic(event[, stack]) - The event object is not valid.", stack)
                end
            end;

            ["Validate"]        = function(feature)
                return _EvtInfo[feature] and feature or nil
            end;
        },
        __call      = function(self, ...)
            if self == event then
                local env, name, definition, stack, owner, builder = typebuilder.GetNewFeatureParams(event, ...)
                if not owner or not builder then error([[Usage: event "name" - can't be used here.]], stack) end
                if type(name) ~= "string" then error([[Usage: event "name" - the name must be a string.]], stack) end
                name = strtrim(name)
                if name == "" then error([[Usage: event "name" - the name can't be an empty string.]], stack) end

                getmetatable(owner).AddFeature(owner, event, name, definition, stack + 1)
            else
                error([[Usage: event "name" - can only be used by event command.]], stack)
            end
        end;
    })

    tevent          = Prototype.NewPrototype {
        __call      = event.Invoke,
    }
end

-------------------------------------------------------------------------------
--                                 property                                  --
-------------------------------------------------------------------------------
do
    -- Key feature : property "Name" { Type = String, Default = "Anonymous" }
    property        = Prototype.NewPrototype {
        __index     = {
            ["New"]             = function(self, owner, name)

            end;

            ["GetFeature"]      = function(feature) return nil end;
        },
        __call      = function(self, ...)
            if self == property then
                local env, name, definition, stack, owner, builder = typebuilder.GetNewFeatureParams(property, ...)
                if not owner or not builder then error([[Usage: property "name" {...} - can't be used here.]], stack) end
                if type(name) ~= "string" then error([[Usage: property "name" {...} - the name must be a string.]], stack) end
                name = strtrim(name)
                if name == "" then error([[Usage: property "name" {...} - the name can't be an empty string.]], stack) end

                if definition then
                    if type(definition) ~= "table" then error([[Usage: property ("name", {...}) - the definition must be a table.]], stack) end
                    getmetatable(owner).AddFeature(owner, property, name, definition, stack + 1)
                else
                    return Prototype.NewObject(property, { name = name, owner = owner })
                end
            else
                local owner, name       = self.owner, self.name
                local definition, stack = typebuilder.GetBuilderParams(self, ...)

                if type(name) ~= "string" then error([[Usage: property "name" {...} - the name must be a string.]], stack) end
                name = strtrim(name)
                if name == "" then error([[Usage: property "name" {...} - the name can't be an empty string.]], stack) end
                if type(definition) ~= "table" then error([[Usage: property ("name", {...}) - the definition must be a table.]], stack) end

                getmetatable(owner).AddFeature(owner, property, name, definition, stack + 1)
            end
        end,
    }

    tproperty       = Prototype.NewPrototype { __metatable = property }
end

-------------------------------------------------------------------------------
--                           Feature Installation                            --
-------------------------------------------------------------------------------
do
    typebuilder.RegisterKeyWord(structbuilder, {
        import          = import,
        member          = member,
        endstruct       = endstruct,
        enum            = enum,
        struct          = struct,
        class           = class,
        interface       = interface,
    })

    typebuilder.RegisterKeyWord(interfacebuilder, {
        import          = import,
        extend          = extend,
        event           = event,
        property        = property,
        endinterface    = endinterface,
        enum            = enum,
        struct          = struct,
        class           = class,
        interface       = interface,
    })

    typebuilder.RegisterKeyWord(classbuilder, {
        import          = import,
        inherit         = inherit,
        extend          = extend,
        event           = event,
        property        = property,
        endclass        = endclass,
        enum            = enum,
        struct          = struct,
        class           = class,
        interface       = interface,
    })

    _G.PLoop = Prototype.NewPrototype {
        __index = {
            namespace   = namespace,
            enum        = enum,
            import      = import,
            typebuilder = typebuilder,
        }
    }

    _G.namespace        = namespace
    _G.enum             = enum
    _G.import           = import
    _G.struct           = struct
end

return ROOT_NAMESPACE