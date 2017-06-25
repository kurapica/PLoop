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
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2017/04/02                                               --
-- Update Date  :   2017/04/04                                               --
-- Version      :   a001                                                     --
--===========================================================================--
newproxy = nil

-------------------------------------------------------------------------------
--                          Environment Preparation                          --
-------------------------------------------------------------------------------
do
    local _G, rawset    = _G, rawset
    local _PLoopEnv     = setmetatable({}, { __index = function(self, k) local v = _G[k] rawset(self, k, v) return v end, __metatable = true })
    _PLoopEnv._PLoopEnv = _PLoopEnv
    if setfenv then setfenv(1, _PLoopEnv) else _ENV = _PLoopEnv end

    -- Common features
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
    wipe                = function(t) for k in pairs(t) do t[k] = nil end return t end

    tblconcat           = table.concat
    tinsert             = table.insert
    tremove             = table.remove
    sort                = table.sort
    floor               = math.floor
    mlog                = math.log

    create              = coroutine.create
    resume              = coroutine.resume
    running             = coroutine.running
    status              = coroutine.status
    wrap                = coroutine.wrap
    yield               = coroutine.yield

    setmetatable        = setmetatable
    getmetatable        = getmetatable

    -- In lua 5.2, the loadstring is deprecated
    loadstring          = loadstring or load
    loadfile            = loadfile

    -- Use false as value so we'll rebuild them in the helper section
    newproxy            = newproxy or false
    setfenv             = setfenv or false
    getfenv             = getfenv or false
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
    ATTRIBUTE_TARGETS_OBJECTMETHOD  = 2^4
    ATTRIBUTE_TARGETS_METHOD        = 2^5
    ATTRIBUTE_TARGETS_CONSTRUCTOR   = 2^6
    ATTRIBUTE_TARGETS_EVENT         = 2^7
    ATTRIBUTE_TARGETS_PROPERTY      = 2^8
    ATTRIBUTE_TARGETS_MEMBER        = 2^9
    ATTRIBUTE_TARGETS_NAMESPACE     = 2^10

    -- ATTRIBUTE APPLY PHASE
    ATTRIBUTE_APPLYPH_BEFOREDEF     = 2^0
    ATTRIBUTE_APPLYPH_AFTERDEEF     = 2^1
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
        for k, v in pairs(src) do
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
                for k, v in pairs(src) do
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
        for k, v in pairs(t1) do if not checkEqual(v, t2[k], cache) then return false end end
        for k, v in pairs(t2) do if t1[k] == nil then return false end end

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
    elseif (LUA_VERSION == 5.2 and type(bit32) == "table") or (LUA_VERSION == 5.1 and type(bit) == "table") then
        local band  = bit32 and bit32.band or bit.band
        local bor   = bit32 and bit32.bor  or bit.bor
        local bnot  = bit32 and bit32.bnot or bit.bnot

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
--      Whether the attribute is iheritable.                                 --
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
--      The attribute's priorty, the bigger the first to be  applied.        --
--                                                                           --
-- * SubLevel                                                                --
--      The priorty's sublevel, for attributes with same priorty, the bigger --
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
        for _, v in ipairs(list) do
            if v == attr then return end
            if noSameType and getmetatable(v) == getmetatable(attr) then return end
        end

        local idx       = 1
        local priorty   = getAttributeInfo(attr, "Priorty", 0, "number")
        local sublevel  = getAttributeInfo(attr, "SubLevel", 0, "number")

        while list[idx] do
            local patr  = list[idx]
            local pprty = getAttributeInfo(patr, "Priorty", 0, "number")
            local psubl = getAttributeInfo(patr, "SubLevel", 0, "number")

            if priorty > pprty or (priorty == pprty and sublevel > psubl) then break end
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
                        for _, sattr in pairs(_InrtInfo[super]) do
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
                for i, attr in ipairs(tarAttrs) do
                    local aType = getmetatable(attr)
                    local aPhse = getAttributeInfo(attr, "ApplyPhase", ATTRIBUTE_APPLYPH_BEFOREDEF, "number")
                    local apply = getAttributeInfo(attr, "ApplyAttribute", nil, "function")
                    local ovrd  = getAttributeInfo(attr, "Overridable", true)
                    local inhr  = getAttributeInfo(attr, "Inheritable", false)

                    -- Save for next phase
                    if validateFlags(ATTRIBUTE_APPLYPH_AFTERDEEF, aPhse) then tinsert(finAttrs, attr) end

                    -- Apply attribute before the definition
                    if validateFlags(ATTRIBUTE_APPLYPH_BEFOREDEF, aPhse) and
                        ovrd or (extAttrs[aType] == nil and extInhrt[aType] == nil) then

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
                for i, attr in ipairs(finAttrs) do
                    local aType = getmetatable(attr)
                    local apply = getAttributeInfo(attr, "ApplyAttribute", nil, "function")
                    local ovrd  = getAttributeInfo(attr, "Overridable", true)
                    local inhr  = getAttributeInfo(attr, "Inheritable", false)

                    if ovrd or (extAttrs[aType] == nil and extInhrt[aType] == nil) then
                        if apply then
                            local ret = apply(attr, applyTarget, targetType, owner, name, ATTRIBUTE_APPLYPH_AFTERDEEF)

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

            ["ConsumeAttributes"] = function(target, targetType)
                if _IgnrTars[target] then _IgnrTars[target] = nil return end

                local preAttrs  = _PreAttrs()
                local tarAttrs  = _Cache()

                -- Apply the attribute to the target
                for i, attr in ipairs(preAttrs) do
                    local aTar  = getAttributeInfo(attr, "AttributeTarget", ATTRIBUTE_TARGETS_ALL, "number")

                    if aTar ~= ATTRIBUTE_TARGETS_ALL and not validateFlags(targetType, aTar) then
                        attribute.Clear() _Cache(tarAttrs)
                        error(("The %s can't be applied to the feature."):format(tostring(getmetatable(attr))))
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
                _IgnrTars[target] = true
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
            end,

            -- Un-register attribute
            ["Unregister"]      = function(attr)
                local pres      = _PreAttrs()
                for i, v in ipairs(pres) do
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
                return _BDIDef[builder]
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
                    for k, v in pairs(key) do
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
                    for _, ns in ipairs(_NSImp[env]) do
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
                for _, v in ipairs(imports) do if v == ns then return end end
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
                    attribute.ConsumeAttributes(ns, ATTRIBUTE_TARGETS_NAMESPACE)
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

    -- FEATURE MODIFIER
    local MD_SEAL   = 2^0   -- SEALED
    local MD_FLAG   = 2^1   -- FLAGS
    local MD_IGCS   = 2^2   -- CASE IGNORED

    -- FIELD INDEX
    local FD_MOD    = 0     -- FIELD MODIFIER
    local FD_ENUMS  = 1     -- FIELD ENUMERATIONS
    local FD_CACHE  = 2     -- FIELD CACHE : VALUE -> NAME
    local FD_EMSG   = 3     -- FIELD ERROR MESSAGE
    local FD_DEFT   = 4     -- FIELD DEFAULT
    local FD_MAXV   = 5     -- FIELD MAX VALUE(FOR FLAGS)

    -- GLOBAL CASE IGNORED
    local GL_IGCS   = false

    local function getTargetInfo(target)
        local info = _BDInfo[target]
        if info then return info, true else return _EnumInfo[target], false end
    end

    enum            = Prototype.NewPrototype {
        __index     = {
            ["BeginDefinition"] = function(target, stack)
                stack = type(stack) == "number" and stack or 2

                target          = enum.Validate(target)
                if not target then error("Usage: enum.BeginDefinition(enumeration[, stack]) - enumeration not existed", stack) end

                local info      = _EnumInfo[target]

                if info and validateFlags(MD_SEAL, info[FD_MOD]) then
                    error(("The %s is sealed, can't be re-defined."):format(tostring(target)), stack)
                end

                local ninfo     = _Cache()

                ninfo[FD_MOD]   = info and info[FD_MOD] or 0
                ninfo[FD_ENUMS] = _Cache()
                ninfo[FD_CACHE] = _Cache()
                ninfo[FD_EMSG]  = "%s must be a value of [" .. tostring(target) .."]."
                ninfo[FD_DEFT]  = info and info[FD_DEFT]

                _BDInfo[target] = ninfo

                attribute.ConsumeAttributes(target, ATTRIBUTE_TARGETS_ENUM)
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
                    for k, v in pairs(enums) do
                        v       = tonumber(v)

                        if v then
                            if v == 0 then
                                if cache[0] then
                                    error(("The %s and %s can't be the same value."):format(k, cache[0]), stack)
                                else
                                    cache[0] = k
                                end
                            elseif v > 0 then
                                count = count + 1

                                local n = mlog(v) / mlog(2)
                                if floor(n) == n then
                                    if cache[2^n] then
                                        error(("The %s and %s can't be the same value."):format(k, cache[n]), stack)
                                    else
                                        cache[2^n] = k

                                        if n > max then max = n end
                                    end
                                else
                                    error(("The %s's value is not a valid flags value(2^n)."):format(k), stack)
                                end
                            else
                                error(("The %s's value is not a valid flags value(2^n)."):format(k), stack)
                            end
                        else
                            count = count + 1

                            enums[k] = -1
                        end
                    end

                    -- So the definition would be more precisely
                    if max >= count then error("The flags enumeration's value can't be greater than 2^(count - 1).", stack) end

                    -- Auto-gen values
                    local n     = 0
                    for k, v in pairs(enums) do
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

                    for k, v in pairs(enums) do
                        cache[v] = k
                    end
                end

                -- Check Default
                if ninfo[FD_DEFT] ~= nil then
                    local default   = ninfo[FD_DEFT]
                    ninfo[FD_DEFT]  = nil

                    if ninfo[FD_CACHE][default] then
                        ninfo[FD_DEFT] = default
                    elseif type(default) == "string" and ninfo[FD_ENUMS][strupper(default)] then
                        ninfo[FD_DEFT] = ninfo[FD_ENUMS][strupper(default)]
                    elseif validateFlags(MD_FLAG, ninfo[FD_MOD]) and type(default) == "number" and floor(default) == default and
                        ((default == 0 and ninfo[FD_CACHE][0]) or (default > 0 and default <= ninfo[FD_MAXV])) then
                        ninfo[FD_DEFT] = default
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
                    info        = info[FD_ENUMS]
                    if cache then
                        return tblclone(info[FD_ENUMS], type(cache) == "table" and wipe(cache) or _Cache())
                    else
                        return function(self, key) return next(info, key) end, target
                    end
                end
            end;

            ["IsCaseIgnored"]   = function(target)
                if target == enum then
                    return GL_IGCS
                else
                    local info  = getTargetInfo(target)
                    return info and validateFlags(MD_IGCS, info[FD_MOD]) or false
                end
            end;

            ["IsFlagsEnum"]     = function(target)
                local info      = getTargetInfo(target)
                return info and validateFlags(MD_FLAG, info[FD_MOD]) or false
            end;

            ["IsSealed"]        = function(target)
                local info      = getTargetInfo(target)
                return info and validateFlags(MD_SEAL, info[FD_MOD]) or false
            end;

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
                                elseif value == 0 then
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
                            return function() end, target
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
                    if not def then error(("The %s's definition is finished, can't set default value."):format(tostring(target)), stack) end
                    info[FD_DEFT] = default
                else
                    error("Usage: enum.SetDefault(enumeration, default[, stack]) - The enumeration type is missing.", stack)
                end
            end;

            ["SetEnumValue"]    = function(target, key, value, stack)
                local info, def = getTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    if not def then error(("The %s's definition is finished, can't set enumeration values."):format(tostring(target)), stack) end
                    if type(key) ~= "string" then error("Usage: enum.SetEnumValue(enumeration, key, value[, stack]) - The key must be a string.", stack) end

                    for k, v in pairs(info[FD_ENUMS]) do
                        if v == value then
                            error("Usage: enum.SetEnumValue(enumeration, key, value[, stack]) - The value already existed.", stack)
                        end
                    end

                    info[FD_ENUMS][strupper(key)] = value
                else
                    error("Usage: enum.SetEnumValue(enumeration, key, value[, stack]) - The enumeration type is missing.", stack)
                end
            end;

            ["SetCaseIgnored"]  = function(target, stack)
                if target == enum then GL_IGCS = true return end

                local info, def = getTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    if not validateFlags(MD_IGCS, info[FD_MOD]) then
                        if not def then error(("The %s's definition is finished, can't change to case ignored."):format(tostring(target)), stack) end
                        info[FD_MOD] = turnOnFlags(MD_IGCS, info[FD_MOD])
                    end
                else
                    error("Usage: enum.SetCaseIgnored(enumeration[, stack]) - The enumeration type is missing.", stack)
                end
            end;

            ["SetFlagsEnum"]    = function(target, stack)
                local info, def = getTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    if not validateFlags(MD_FLAG, info[FD_MOD]) then
                        if not def then error(("The %s's definition is finished, can't change to flags enumeration."):format(tostring(target)), stack) end
                        info[FD_MOD] = turnOnFlags(MD_FLAG, info[FD_MOD])
                    end
                else
                    error("Usage: enum.SetFlagsEnum(enumeration[, stack]) - The enumeration type is missing.", stack)
                end
            end;

            ["SetSealed"]       = function(target, stack)
                local info      = getTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    info[FD_MOD] = turnOnFlags(MD_SEAL, info[FD_MOD])
                else
                    error("Usage: enum.SetSealed(enumeration[, stack]) - The enumeration type is missing.", stack)
                end
            end;

            ["ValidateValue"]   = function(target, value)
                local info  = _EnumInfo[target]
                if info then
                    if info[FD_CACHE][value] then return value end
                    local vtype = type(value)
                    if vtype == "string" then
                        if GL_IGCS or info[FD_MOD] >= MD_IGCS then value = strupper(value) end
                        value = info[FD_ENUMS][value]
                        return value, value == nil and info[FD_EMSG] or nil
                    elseif info[FD_MAXV] and vtype == "number" and floor(value) == value and value >= 0 and value <= info[FD_MAXV] then
                        if value == 0 then if info[FD_CACHE][0] then return 0 end return nil, info[FD_EMSG] end
                        return value
                    end
                    return nil, info[FD_EMSG]
                else
                    error("Usage: enum.ValidateValue(enumeration, value) - The enumeration type is missing.", 2)
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

            for k, v in pairs(definition) do
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
    local MD_SEAL   = 2^0   -- SEALED

    -- FIELD INDEX
    local FD_MOD    = -1        -- FIELD MODIFIER
    local FD_OBJMTD = -2        -- FIELD OBJECT METHODS
    local FD_DEFT   = -3        -- FEILD DEFAULT
    local FD_BASE   = -4        -- FIELD BASE STRUCT
    local FD_VALID  = -5        -- FIELD VALIDATION
    local FD_CTOR   = -6        -- FIELD CONSTRUCTOR
    local FD_EMSG   = -7        -- FIELD ERROR MESSAGE
    local FD_VCACHE = -8        -- FIELD VALIDATION CACHE

    local FD_ARRAY  =  0        -- FIELD ARRAY ELEMENT
    local FD_ARRVLD =  2        -- FIELD ARRAY ELEMENT VALIDATION
    local FD_STMEM  =  1        -- FIELD START INDEX OF MEMBER
    local FD_STVLD  =  10000    -- FIELD START INDEX OF VALIDATION
    local FD_STINI  =  20000    -- FIELD START INDEX OF INITIALIZE

    -- MEMBER FIELD INDEX
    local MFD_NAME  =  1        -- MEMBER FIELD NAME
    local MFD_TYPE  =  2        -- MEMBER FIELD TYPE
    local MFD_VALD  =  3        -- MEMBER FIELD TYPE VALIDATION
    local MFD_DEFT  =  4        -- MEMBER FIELD DEFAULT
    local MFD_ASFT  =  5        -- MEMBER FIELD AS DEFAULT FACTORY
    local MFD_REQ   =  0        -- MEMBER FIELD REQUIRE

    local FL_CUSTOM = 2^0
    local FL_MEMBER = 2^1
    local FL_ARRAY  = 2^2
    local FL_SVALID = 2^3
    local FL_MVALID = 2^4
    local FL_SINIT  = 2^5
    local FL_MINIT  = 2^6
    local FL_METHOD = 2^7
    local FL_VCACHE = 2^8
    local FL_MLFDRQ = 2^9
    local FL_FSTTYP = 2^10

    local MTD_INIT  = "__init"
    local MTD_BASE  = "__base"

    local getValueFromBuidler = typebuilder.GetValueFromBuidler

    local function getTargetInfo(target)
        local info  = _BDInfo[target]
        if info then return info, true else return _StrtInfo[target], false end
    end

    local function getBuilderValue(self, name)
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

        if info[FD_OBJMTD] and next(info[FD_OBJMTD]) then
            token   = turnOnFlags(FL_METHOD, token)
            tinsert(upval, info[FD_OBJMTD])
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
                        for i, v in ipairs(value) do
                            local ret, msg  = avalid(array, v, true, cache)
                            if msg then return nil, true end
                        end
                    else
                        for i, v in ipairs(value) do
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
                    if msg then return nil, onlyValid or type(msg) == "string" and msg or ("%s must be [%s]."):format("%s", info[]] .. FD_EMSG .. [[]) end
                ]])
            elseif validateFlags(FL_MVALID, token) then
                tinsert(header, "mvalid")
                tinsert(body, [[
                    for i = ]] .. FD_STVLD .. [[, mvalid do
                        local msg = info[i](value)
                        if msg then return nil, onlyValid or type(msg) == "string" and msg or ("%s must be [%s]."):format("%s", info[]] .. FD_EMSG .. [[]) end
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

            if validateFlags(FL_METHOD, token) then
                tinsert(header, "methods")
                if validateFlags(FL_CUSTOM, token) then
                    tinsert(body, [[if type(value) == "table" then]])
                end

                tinsert(body, [[
                    for k, v in pairs(methods) do
                        if value[k] == nil then value[k] = v end
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
                        for k, v in pairs(cache) do cache[k] = nil _Cache(v) end _Cache(cache)
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
                        for k, v in pairs(cache) do cache[k] = nil _Cache(v) end _Cache(cache)
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
                    for k, v in pairs(cache) do cache[k] = nil _Cache(v) end _Cache(cache)
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
                    for k, v in pairs(definition) do
                        if type(k) == "string" and strlower(k) == "name" and type(v) == "string" and not tonumber(v) then
                            name, definition[k] = v, nil
                            break
                        end
                    end
                end
                stack = type(stack) == "number" and stack or 2

                if info then
                    if not def then error(("The %s's definition is finished, can't add member."):format(tostring(target)), stack) end
                    if type(name) ~= "string" then error("Usage: struct.AddMember(structure[, name], definition[, stack]) - The name must be a string.", stack) end
                    name = strtrim(name)
                    if name == "" then error("Usage: struct.AddMember(structure[, name], definition[, stack]) - The name can't be empty.", stack) end
                    if type(definition) ~= "table" then error("Usage: struct.AddMember(structure[, name], definition[, stack]) - The definition is missing.", stack) end
                    if info[FD_ARRAY] then error("Usage: struct.AddMember(structure[, name], definition[, stack]) - The structure is an array structure, can't add member.", stack) end

                    local idx = FD_STMEM
                    while info[idx] do
                        if info[idx][MFD_NAME] == name then
                            error(("There is a member with the name : %q."):format(name), stack)
                        end
                        idx = idx + 1
                    end

                    local minfo = _Cache()
                    minfo[MFD_NAME] = name

                    attribute.ConsumeAttributes(minfo, ATTRIBUTE_TARGETS_MEMBER)

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

                    for k, v in pairs(definition) do
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
                    error("Usage: struct.AddMember(structure[, name], definition[, stack]) - The structure type is missing.", stack)
                end
            end;

            ["AddMethod"]       = function(target, name, func, stack)
                local info, def = getTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    if type(name) ~= "string" then error("Usage: struct.AddMethod(structure, name, func[, stack]) - the name must be a string.", stack) end
                    name = strtrim(name)
                    if name == "" then error("Usage: Usage: struct.AddMethod(structure, name, func[, stack]) - The name can't be empty.", stack) end
                    if type(func) ~= "function" then error("Usage: struct.AddMethod(structure, name, func[, stack]) - the func must be a function.", stack) end

                    if not def and info[name] then
                        error(("The %s's definition is finished, the method can't be override."):format(tostring(target)), stack)
                    end

                    attribute.ConsumeAttributes(func, ATTRIBUTE_TARGETS_METHOD)

                    local sfunc

                    if info[FD_BASE] then
                        if not struct.IsStaticMethod(info[FD_BASE], name) then
                            sfunc = struct.GetMethod(info[FD_BASE], name)
                        end
                    end

                    func = attribute.ApplyAttributes(func, ATTRIBUTE_TARGETS_METHOD, nil, target, name, sfunc)

                    local isStatic = info[name] and not info[FD_OBJMTD][name]
                    local hasMethod= info[FD_OBJMTD] and next(info[FD_OBJMTD])

                    info[name]  = func

                    if not isStatic then
                        info[FD_OBJMTD] = info[FD_OBJMTD] or _Cache()
                        info[FD_OBJMTD][name] = func
                    end

                    attribute.ApplyAfterDefine(func, ATTRIBUTE_TARGETS_METHOD, nil, target, name)

                    if not def and not hasMethod then
                        -- Need re-generate validator and ctor
                        generateValidator(info)
                        generateConstructor(info)
                    end
                else
                    error("Usage: struct.AddMethod(structure, name, func[, stack]) - The structure type is missing.", stack)
                end
            end;

            ["BeginDefinition"] = function(target, stack)
                stack = type(stack) == "number" and stack or 2

                target          = struct.Validate(target)
                if not target then error("Usage: struct.BeginDefinition(structure[, stack]) - structure not existed", stack) end

                local info      = _StrtInfo[target]

                if info and validateFlags(MD_SEAL, info[FD_MOD]) then
                    error(("Usage: the %s is sealed, can't be re-defined."):format(tostring(target)), stack)
                end

                local ninfo     = _Cache()

                ninfo[FD_MOD]   = info and info[FD_MOD]

                _BDInfo[target] = ninfo

                attribute.ConsumeAttributes(target, ATTRIBUTE_TARGETS_STRUCT)
            end;

            ["EndDefinition"]   = function(target, stack)
                local ninfo     = _BDInfo[target]
                if not ninfo then return end

                stack = type(stack) == "number" and stack or 2
                _BDInfo[target] = nil

                attribute.ApplyAttributes(target, ATTRIBUTE_TARGETS_STRUCT, nil, nil, nil, ninfo[FD_BASE])

                -- Install base struct's features
                if ninfo[FD_BASE] then
                    -- Check conflict, some should be handled by the author
                    local binfo     = _StrtInfo[ninfo[FD_BASE]]

                    if ninfo[FD_ARRAY] then     -- Array
                        if not binfo[FD_ARRAY] then
                            error(("The %s's base struct isn't an array structure."):format(tostring(target)), stack)
                        end
                    elseif ninfo[FD_STMEM] then -- Member
                        if binfo[FD_ARRAY] then
                            error(("The %s's base struct can't be an array structure."):format(tostring(target)), stack)
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

                                for k, v in pairs(cache) do
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
                    if binfo[FD_OBJMTD] then
                        ninfo[FD_OBJMTD] = tblclone(binfo[FD_OBJMTD], ninfo[FD_OBJMTD] or _Cache())
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
                    ninfo[FD_EMSG]  = tostring(target)
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
                local info      = getTargetInfo(target)
                return info and type(name) == "string" and info[name]
            end;

            ["GetMethods"]      = function(target, cache)
                local info      = getTargetInfo(target)
                if info then
                    local objM  = info[FD_OBJMTD]
                    if cache then
                        cache   = type(cache) == "table" and wipe(cache) or _Cache()

                        for k, v in pairs(info) do
                            if type(k) == "string" then
                                cache[k] = not objM[k]
                            end
                        end

                        return cache
                    else
                        return function(self, name)
                            local name = next(info, name)
                            while name and type(name) ~= "string" do name = next(info, name) end
                            if name then return name, not objM[name] end
                        end, target
                    end
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

            ["IsSealed"]        = function(target)
                local info      = getTargetInfo(target)
                return info and validateFlags(MD_SEAL, info[FD_MOD]) or false
            end;

            ["IsStaticMethod"]  = function(target, name)
                local info      = getTargetInfo(target)
                return info and type(name) == "string" and info[name] and not info[FD_OBJMTD][name]
            end;

            ["SetArrayElement"] = function(target, eleType, stack)
                local info, def = getTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    if not def then error(("The %s's definition is finished, can't set array element."):format(tostring(target)), stack) end

                    if info[FD_STMEM] then error("Usage: struct.SetArrayElement(structure, eleType[, stack]) - The structure has member settings, can't set array element.", stack) end

                    local tpValid   = getValidate(eleType)
                    if not tpValid then error("Usage: struct.SetArrayElement(structure, eleType[, stack]) - The element type is not valid.", stack) end

                    info[FD_ARRAY]  = eleType
                    info[FD_ARRVLD] = tpValid
                else
                    error("Usage: struct.SetArrayElement(structure, eleType[, stack]) - The structure type is missing.", stack)
                end
            end;

            ["SetDefault"]      = function(target, default, stack)
                local info, def = getTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    if not def then error(("The %s's definition is finished, can't set default value."):format(tostring(target)), stack) end
                    info[FD_DEFT] = default
                else
                    error("Usage: struct.SetDefault(structure, default[, stack]) - The structure type is missing.", stack)
                end
            end;

            ["SetValidator"]    = function(target, func, stack)
                local info, def = getTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    if not def then error(("The %s's definition is finished, can't set validator."):format(tostring(target)), stack) end
                    if type(func) ~= "function" then error("Usage: struct.SetValidator(structure, validator) - The validator must be a function.", stack) end
                    info[FD_STVLD] = func
                else
                    error("Usage: struct.SetValidator(structure, validator[, stack]) - The structure type is missing.", stack)
                end
            end;

            ["SetInitializer"]  = function(target, func, stack)
                local info, def = getTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    if not def then error(("The %s's definition is finished, can't set initializer."):format(tostring(target)), stack) end
                    if type(func) ~= "function" then error("Usage: struct.SetInitializer(structure, initializer) - The initializer must be a function.", stack) end
                    info[FD_STINI] = func
                else
                    error("Usage: struct.SetInitializer(structure, initializer[, stack]) - The structure type is missing.", stack)
                end
            end;

            ["SetSealed"]       = function(target, stack)
                local info      = getTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    info[FD_MOD] = turnOnFlags(MD_SEAL, info[FD_MOD])
                else
                    error("Usage: struct.SetSealed(structure[, stack]) - The structure type is missing.", stack)
                end
            end;

            ["SetStaticMethod"] = function(target, name, stack)
                local info, def = getTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    if type(name) ~= "string" then error("Usage: struct.SetStaticMethod(structure, name) - the name must be a string.", stack) end
                    name = strtrim(name)
                    if name == "" then error("Usage: Usage: struct.SetStaticMethod(structure, name) - The name can't be empty.", stack) end
                    if not def then error(("The %s's definition is finished, can't set static method."):format(tostring(target)), stack) end
                    if not info[name] then error(("The %s has no method named %q."):format(tostring(target), name), stack) end

                    info[FD_OBJMTD][name] = nil
                else
                    error("Usage: struct.SetStaticMethod(structure, name[, stack]) - The structure type is missing.", stack)
                end
            end;

            ["SetBaseStruct"]   = function(target, base, stack)
                local info, def = getTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    if not def then error(("The %s's definition is finished, can't set the base structure."):format(tostring(target)), stack) end
                    if not struct.Validate(base) then error("Usage: struct.SetBaseStruct(structure, base) - The base must be a structure.", stack) end
                    info[FD_BASE] = base
                else
                    error("Usage: struct.SetBaseStruct(structure, base[, stack]) - The structure type is missing.", stack)
                end
            end;

            ["ValidateValue"]   = function(target, value, onlyValid, cache)
                local info  = _StrtInfo[target]
                if info then
                    if not cache and info[FD_VCACHE] then
                        cache = _Cache()
                        local ret, msg = info[FD_VALID](info, value, onlyValid, cache)
                        for k, v in pairs(cache) do cache[k] = nil _Cache(v) end _Cache(cache)
                        return ret, msg
                    else
                        return info[FD_VALID](info, value, onlyValid, cache)
                    end
                else
                    error("Usage: struct.ValidateValue(structure, value[, onlyValid]) - The structure type is missing.", 2)
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
            if not target then error("Usage: struct([env, ][name, ][definition][, stack]) - the struct type can't be created.", stack) end

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
                -- Access methods
                local info  = _StrtInfo[self]
                local val   = info and info[name]

                if val then return val end

                -- Access child-namespaces
                return namespace.GetNameSpace(self, name)
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
                for i, v in ipairs(definition) do
                    setBuilderOwnerValue(owner, i, v, stack)
                end

                for k, v in pairs(definition) do
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
    local _IFInfo   = setmetatable({}, WEAK_KEY)
    local _CLInfo   = setmetatable({}, WEAK_KEY)
    local _BDInfo   = Prototype.NewObject(threadCache)

    local _IFFtrs   = {}
    local _CLFtrs   = {}

    -- FEATURE MODIFIER
    local MD_SEAL   = 2^0
    local MD_FINAL  = 2^1
    local MD_STATIC = 2^2
    local MD_ABSCLS = 2^3
    local MD_ATPROP = 2^4
    local MD_REQ    = 2^5

    local FD_MOD    = 0         -- FIELD MODIFIER
    local FD_SUPER  = 1         -- FIELD SUPER CLASS
    local FD_EXTDS  = 2         -- FIELD EXTENDS INTERFACES
    local FD_OBJMTD = 3         -- FIELD OBJECT METHODS
    local FD_TPFTR  = 4         -- FIELD TYPE FEATURES(Props, Events)
    local FD_OBJFTR = 5         -- FIELD OBJECT TYPE FEATURES

    local function getTargetInfo(target)
        local info  = _BDInfo[target]
        if info then return info, true else return _IFInfo[target] or _CLInfo[target], false end
    end

    local function getSuperMethod(info, name)

    end

    interface       = Prototype.NewPrototype {
        __index     = {
            ["AddMethod"]       = function(target, name, func, stack)
                local info, def = getTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    local tartp = getmetatable(target)
                    if type(name) ~= "string" then error(("Usage: %s.AddMethod(%s, name, func[, stack]) - the name must be a string."):format(tostring(tartp), tostring(tartp)), stack) end
                    name = strtrim(name)
                    if name == "" then error(("Usage: Usage: %s.AddMethod(%s, name, func[, stack]) - The name can't be empty."):format(tostring(tartp), tostring(tartp)), stack) end
                    if type(func) ~= "function" then error(("Usage: %s.AddMethod(%s, name, func[, stack]) - the func must be a function."):format(tostring(tartp), tostring(tartp)), stack) end

                    if not def and info[name] then
                        error(("The %s's definition is finished, the method can't be override."):format(tostring(target)), stack)
                    end

                    attribute.ConsumeAttributes(func, ATTRIBUTE_TARGETS_METHOD)
                    func = attribute.ApplyAttributes(func, ATTRIBUTE_TARGETS_METHOD, nil, target, name)

                    local isStatic = info[name] and not info[FD_OBJMTD][name]

                    info[name]  = func

                    if not isStatic then
                        info[FD_OBJMTD] = info[FD_OBJMTD] or _Cache()
                        info[FD_OBJMTD][name] = func
                    end

                    attribute.ApplyAfterDefine(func, ATTRIBUTE_TARGETS_METHOD, nil, target, name)

                    if not def then
                        -- Need re-generate validator and ctor
                    end
                else
                    error("Usage: class|interface.AddMethod(type, name, func[, stack]) - The type is missing.", stack)
                end
            end;

            ["AddTypeFeature"]  = function(target, ftype, name, definition, stack)
                local info, def = getTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    local tartp = getmetatable(target)
                    if not def then error(("The %s's definition is finished, can't add new type feature."):format(tostring(target)), stack) end
                    if not (tartp == interface and _IFFtrs or _CLFtrs)[ftype] then error(("Usage: %s.AddTypeFeature(%s, featuretype, name[, definition][, stack]) - The featuretype is not valid."):format(tostring(tartp), tostring(tartp)), stack) end
                    if type(name) ~= "string" then error(("Usage: %s.AddTypeFeature(%s, featuretype, name[, definition][, stack]) - The name must be a string."):format(tostring(tartp), tostring(tartp)), stack) end
                    name = strtrim(name)
                    if name == "" then error(("Usage: %s.AddTypeFeature(%s, featuretype, name[, definition][, stack]) - The name can't be empty."):format(tostring(tartp), tostring(tartp)), stack) end
                    if info[FD_TPFTR] and info[FD_TPFTR][name] and getmetatable(info[FD_TPFTR][name]) ~= ftype then error(("Usage: %s.AddTypeFeature(%s, featuretype, name[, definition][, stack]) - The name is used by other features."):format(tostring(tartp), tostring(tartp)), stack) end

                    info[FD_TPFTR] = info[FD_TPFTR] or _Cache()

                    info[FD_TPFTR][name] = ftype:New(name, definition, stack + 1)
                else
                    error("Usage: class|interface.AddTypeFeature(type, featuretype, name[, definition][, stack]) - The type is missing.", stack)
                end
            end;

            ["BeginDefinition"] = function(target, stack)
                stack = type(stack) == "number" and stack or 2

                target          = interface.Validate(target)
                if not target then error("Usage: interface.BeginDefinition(interface[, stack]) - interface not existed", stack) end

                local info      = _IFInfo[target]

                if info and validateFlags(MD_SEAL, info[FD_MOD]) then
                    error(("Usage: the %s is sealed, can't be re-defined."):format(tostring(target)), stack)
                end

                local ninfo     = tblclone(info, _Cache(), true)

                _BDInfo[target] = ninfo

                attribute.ConsumeAttributes(target, ATTRIBUTE_TARGETS_INTERFACE)
            end;

            ["EndDefinition"]   = function(target, stack)
                local ninfo     = _BDInfo[target]
                if not ninfo then return end

                stack = type(stack) == "number" and stack or 2
                _BDInfo[target] = nil

                -- Save as new interface's info
                _IFInfo[target]   = ninfo

                attribute.ApplyAfterDefine(target, ATTRIBUTE_TARGETS_INTERFACE)

                return target
            end;

            ["GetMethod"]       = function(target, name)
                local info      = getTargetInfo(target)
                return info and type(name) == "string" and info[name]
            end;

            ["GetMethods"]      = function(target, cache)
                local info      = getTargetInfo(target)
                if info then
                    local objM  = info[FD_OBJMTD]
                    if cache then
                        cache   = type(cache) == "table" and wipe(cache) or _Cache()

                        for k, v in pairs(info) do
                            if type(k) == "string" then
                                cache[k] = not objM[k]
                            end
                        end

                        return cache
                    else
                        return function(self, name)
                            local name = next(info, name)
                            while name and type(name) ~= "string" do name = next(info, name) end
                            if name then return name, not objM[name] end
                        end, target
                    end
                end
            end;

            ["IsSealed"]        = function(target)
                local info      = getTargetInfo(target)
                return info and validateFlags(MD_SEAL, info[FD_MOD]) or false
            end;

            ["IsStaticMethod"]  = function(target, name)
                local info      = getTargetInfo(target)
                return info and type(name) == "string" and info[name] and not info[FD_OBJMTD][name]
            end;

            ["SetSealed"]       = function(target, stack)
                local info      = getTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    info[FD_MOD] = turnOnFlags(MD_SEAL, info[FD_MOD])
                else
                    error("Usage: struct.SetSealed(structure[, stack]) - The structure type is missing.", stack)
                end
            end;

            ["SetStaticMethod"] = function(target, name, stack)
                local info, def = getTargetInfo(target)
                stack = type(stack) == "number" and stack or 2

                if info then
                    if type(name) ~= "string" then error("Usage: struct.SetStaticMethod(structure, name) - the name must be a string.", stack) end
                    name = strtrim(name)
                    if name == "" then error("Usage: Usage: struct.SetStaticMethod(structure, name) - The name can't be empty.", stack) end
                    if not def then error(("The %s's definition is finished, can't set static method."):format(tostring(target)), stack) end
                    if not info[name] then error(("The %s has no method named %q."):format(tostring(target), name), stack) end

                    info[FD_OBJMTD][name] = nil
                else
                    error("Usage: struct.SetStaticMethod(structure, name[, stack]) - The structure type is missing.", stack)
                end
            end;

        },
        __newindex  = readOnly,
        __concat    = typeconcat,
        __tostring  = function() return "interface" end,
        __call      = function(self, ...)
            local env, target, definition, keepenv, stack = typebuilder.GetNewTypeParams(interface, tinterface, ...)
            if not target then error("Usage: struct([env, ][name, ][definition][, stack]) - the struct type can't be created.", stack) end

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

    tinterface      = Prototype.NewPrototype(tnamespace, {
        __index     = function(self, name)
            if type(name) == "string" then
                -- Access methods
                local info  = _IFInfo[self]
                local val   = info and info[name]

                if val then return val end

                -- Access child-namespaces
                return namespace.GetNameSpace(self, name)
            end
        end,
        __call      = function(self, ...)
            local info  = _IFInfo[self]
            local ret   = info[FD_CTOR](info, ...)
            return ret
        end,
        __metatable = struct,
    })

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
                -- Index key first
                for i, v in ipairs(definition) do
                    setBuilderOwnerValue(owner, i, v, stack)
                end

                for k, v in pairs(definition) do
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

    class           = Prototype.NewPrototype( interface, {
        __index     = {

        },
        __concat    = typeconcat,
        __tostring  = function() return "class" end,
        __call      = function(self, ...)
            local env, target, definition, keepenv, stack = typebuilder.GetNewTypeParams(class, tclass, ...)
            if not target then error("Usage: struct([env, ][name, ][definition][, stack]) - the struct type can't be created.", stack) end

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
    })

    tclass          = Prototype.NewPrototype( tinterface, {

    })

    classbuilder    = Prototype.NewPrototype( interfacebuilder, {

    })

    typefeature     = Prototype.NewPrototype {
        __index     = {
            ["Register"]        = function(self, type)
                if type then
                    if type == class then
                        if not _CLFtrs[self] then tinsert(_CLFtrs, self) _CLFtrs[self] = true end
                    elseif type == interface then
                        if not _IFFtrs[self] then tinsert(_IFFtrs, self) _IFFtrs[self] = true end
                    end
                else
                    if not _CLFtrs[self] then tinsert(_CLFtrs, self) _CLFtrs[self] = true end
                    if not _IFFtrs[self] then tinsert(_IFFtrs, self) _IFFtrs[self] = true end
                end
            end;

            ["New"]             = function(self, name, definition, stack)
            end;
        },
        __newindex  = readOnly
    }
end

-------------------------------------------------------------------------------
--                                   event                                   --
-------------------------------------------------------------------------------
do
    -- Key feature : event "Name"
    event        = Prototype.NewPrototype (typefeature, {
        __call      = function(self, ...)
            if self == event then
                local env, name, _, stack, owner, builder = typebuilder.GetNewFeatureParams(property, ...)
                if not owner or not builder then error([[Usage: event "name" - can't be used here.]], stack) end
                if type(name) ~= "string" then error([[Usage: event "name" - the name must be a string.]], stack) end
                name = strtrim(name)
                if name == "" then error([[Usage: event "name" - the name can't be an empty string.]], stack) end

                if definition then
                    if type(definition) ~= "table" then error([[Usage: property ("name", {...}) - the definition must be a table.]], stack) end
                    getmetatable(owner).AddTypeFeature(owner, name, definition, stack + 1)
                else
                    return Prototype.NewObject(property, { name = name, owner = owner })
                end
            end
        end;
    })

    -- Register to class & interface
    event:Register()
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
                    getmetatable(owner).AddTypeFeature(owner, name, definition, stack + 1)
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

                getmetatable(owner).AddTypeFeature(owner, name, definition, stack + 1)
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

