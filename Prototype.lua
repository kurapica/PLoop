--===========================================================================--
-- Copyright (c) 2011-2021 WangXH <kurapica125@outlook.com>                  --
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
--               Prototype Lua Object-Oriented Program System                --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2017/04/02                                               --
-- Update Date  :   2022/04/24                                               --
-- Version      :   1.8.1                                                    --
--===========================================================================--

-------------------------------------------------------------------------------
--                                preparation                                --
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                      environment preparation                      --
    -----------------------------------------------------------------------
    local cerror, cformat               = error, string.format
    local cdebug                        = type(debug) == "table" and debug or nil -- Check the debug lib
    local _PLoopEnv                     = setmetatable(
        {
            _G                          = _G,
            LUA_VERSION                 = tonumber(_VERSION and _VERSION:match("[%d%.]+")) or 5.1,

            -- Weak Mode
            WEAK_KEY                    = { __mode = "k", __metatable = false },
            WEAK_VALUE                  = { __mode = "v", __metatable = false },
            WEAK_ALL                    = { __mode = "kv",__metatable = false },

            -- Iterator
            ipairs                      = ipairs(_G),
            pairs                       = pairs (_G),
            next                        = next,
            select                      = select,

            -- String
            strformat                   = string.format,
            strfind                     = string.find,
            strsub                      = string.sub,
            strgsub                     = string.gsub,
            strupper                    = string.upper,
            strlower                    = string.lower,
            strmatch                    = string.match,
            strgmatch                   = string.gmatch,

            -- Table
            tblconcat                   = table.concat,
            tinsert                     = table.insert,
            tremove                     = table.remove,
            unpack                      = table.unpack or unpack,
            setmetatable                = setmetatable,
            getmetatable                = getmetatable,
            rawset                      = rawset,
            rawget                      = rawget,

            -- Type
            type                        = type,
            tonumber                    = tonumber,
            tostring                    = tostring,

            -- Math
            abs                         = math.abs,
            floor                       = math.floor,
            mlog                        = math.log,
            mpow                        = math.pow,

            -- Safe
            pcall                       = pcall,
            error                       = error,
            print                       = print,
            newproxy                    = newproxy or false,

            -- In lua 5.2, the loadstring is deprecated
            loadstring                  = loadstring or load,
            loadfile                    = loadfile,

            -- Debug lib
            debug                       = cdebug or false,
            debuginfo                   = cdebug and cdebug.getinfo    or false,
            getupvalue                  = cdebug and cdebug.getupvalue or false,
            getlocal                    = cdebug and cdebug.getlocal   or false,
            traceback                   = cdebug and cdebug.traceback  or false,
            setfenv                     = setfenv or cdebug and cdebug.setfenv or false,
            getfenv                     = getfenv or cdebug and cdebug.getfenv or false,
            collectgarbage              = collectgarbage,

            -- Share API
            fakefunc                    = function() end,

            -- Placeholder
            namespace                   = false,
        }, {
            __index                     = function(self, k)
                -- For System namespaces access only, the keyword are already saved
                local value             = self.environment.GetValue(self, k, 2)
                if value then return value end
                cerror(cformat("Global variable %q can't be found", k), 2)
            end,
            __metatable                 = true,
        }
    )
    _PLoopEnv._PLoopEnv                 = _PLoopEnv
    if setfenv then setfenv(1, _PLoopEnv) else _ENV = _PLoopEnv end

    -----------------------------------------------------------------------
    -- The table contains several settings can be modified based on the
    -- target platform and frameworks. It must be provided before loading
    -- the PLoop, and the table and its fields are all optional.
    --
    -- @table PLOOP_PLATFORM_SETTINGS
    -----------------------------------------------------------------------
    PLOOP_PLATFORM_SETTINGS             = (function(default)
        local settings                  = _G.PLOOP_PLATFORM_SETTINGS
        if type(settings) == "table" then
            _G.PLOOP_PLATFORM_SETTINGS  = nil

            for k, v in pairs, default do
                local r                 = settings[k]
                if type(r) == type(v) then
                    default[k]          = r
                end
            end
        end
        return default
    end) {
        --- Whether the attribute system use warning instead of error for
        -- invalid attribute target type.
        -- Default false
        ATTR_USE_WARN_INSTEAD_ERROR         = false,

        --- Whether the environmet allow global variable be nil, if false,
        -- things like ture(spell error) could trigger error.
        -- Default true
        ENV_ALLOW_GLOBAL_VAR_BE_NIL         = true,

        --- The filter function used to validation the new declared global
        -- variables with key and value, if the function return non-false
        -- value, that means the assignment is not legal(if we write the
        -- code `idx = 1` in a function, we normally missed the `local`),
        -- so the assignment should be canceled or warned, you also can use
        -- the filter to record the global assignments
        GLOBAL_VARIABLE_FILTER              = fakefunc,

        --- Whether use warning instead of the error, if use warning, the
        -- assignment will still be processed
        GLOBAL_VARIABLE_FILTER_USE_WARN     = false,

        --- Whether pass the callline of the global assignment to the filter
        GLOBAL_VARIABLE_FILTER_GET_CALLLINE = false,

        --- Whether allow old style of type definitions like :
        --      class "A"
        --          -- xxx
        --      endclass "A"
        --
        -- Default false
        TYPE_DEFINITION_WITH_OLD_STYLE      = false,

        --- Whether the type validation should be disabled. The value should be
        -- false during development, toggling it to true will make the system
        -- ignore the value valiation in several conditions for speed.
        TYPE_VALIDATION_DISABLED            = false,

        --- Whether allow accessing non-existent value from namespace
        -- Default true
        NAMESPACE_NIL_VALUE_ACCESSIBLE      = true,

        --- Whether all old objects keep using new features when their
        -- classes or extend interfaces are re-defined.
        -- Default false
        CLASS_NO_MULTI_VERSION_CLASS        = false,

        --- Whether all interfaces & classes only use the classic format
        -- `super.Method(obj, ...)` to call super's features, don't use new
        -- style like :
        --      super[obj].Name = "Ann"
        --      super[obj].OnNameChanged = super[obj].OnNameChanged + print
        --      super[obj]:Greet("King")
        -- Default false
        CLASS_NO_SUPER_OBJECT_STYLE         = false,

        --- Whether all interfaces has anonymous class, so it can be used
        -- to generate object
        -- Default false
        INTERFACE_ALL_ANONYMOUS_CLASS       = false,

        --- Whether all class objects can't save value to fields directly,
        -- So only init fields, properties, events can be set during runtime.
        -- Default false
        OBJECT_NO_RAWSEST                   = false,

        --- Whether all class objects can't fetch nil value from it, combine it
        -- with @OBJ_NO_RAWSEST will force a strict mode for development.
        -- Default false
        OBJECT_NO_NIL_ACCESS                = false,

        --- Whether save the creation places (source and line) for all objects
        -- Default false
        OBJECT_DEBUG_SOURCE                 = false,

        --- The Log level used in the Prototype core part.
        --          1 : Trace
        --          2 : Debug
        --          3 : Info
        --          4 : Warn
        --          5 : Error
        --          6 : Fatal
        -- Default 3(Info)
        CORE_LOG_LEVEL                      = 3,

        --- The core log handler works like :
        --      function CORE_LOG_HANDLER(message, loglevel)
        --          -- message  : the log message
        --          -- loglevel : the log message's level
        --      end
        -- Default print
        CORE_LOG_HANDLER                    = print,

        --- Whether the system is used in a platform where multi os threads
        -- share one lua-state, so the access conflict can't be ignore.
        -- Default false
        MULTI_OS_THREAD                     = false,

        --- Whether the system is used in a platform where multi os threads
        -- share one lua-state, and the lua_lock and lua_unlock apis are
        -- applied, so PLoop don't need to care about the thread conflict.
        -- Default false
        MULTI_OS_THREAD_LUA_LOCK_APPLIED    = false,

        --- Whether the system send warning messages when the system is used
        -- in a platform where multi os threads share one lua-state, and
        -- global variables are saved not to the environment but an inner
        -- cache, it'd solve the thread conflict, but the environment need
        -- fetch them by __index meta-call, so it's better to declare local
        -- variables to hold them for best access speed.
        -- Default true
        MULTI_OS_THREAD_ENV_AUTO_CACHE_WARN = true,

        --- Whether the system use tables for the types of namespace, class and
        -- others, and save the type's meta data in themselves. Normally it's
        -- not recommended.
        --
        -- When the @MULTI_OS_THREAD is true, to avoid the thread conflict, the
        -- system would use a clone-replace mechanism for inner storage, it'd
        -- leave many tables to be collected during the definition time.
        -- Default false
        UNSAFE_MODE                         = false,

        --- Whether try to save the stack data into the exception object, so
        -- we can have more details about the exception.
        -- Default true
        EXCEPTION_SAVE_STACK_DATA           = true,

        --- Whether alwasy try to save local variables and upvalues for exception
        -- Default false
        EXCEPTION_SAVE_VARIABLES            = false,

        --- The max pool size of the thread pool
        -- Default 40
        THREAD_POOL_MAX_SIZE                = 40,

        --- Whether enable the context features, so features like the default thread pool will
        -- be deactived and switch to the context thread pool if possible
        -- Default false
        ENABLE_CONTEXT_FEATURES             = false,

        --- Whether enable thread lock features like __Lock__
        -- Default false
        ENABLE_THREAD_LOCK                  = false,

        --- Whehther active safe thread iterator so it will stop for dead coroutine
        -- On some platforms like Openresty call a dead wrap won't raise error but
        -- return the error message 'cannot resume dead coroutine'
        THREAD_SAFE_ITERATOR                = false,

        --- Use the Dispose as the __gc, only works for Lua 5.3 and above
        -- Default true
        USE_DISPOSE_AS_META_GC              = true,

        --- Use `this` keywords for all object methods
        -- Default false
        USE_THIS_FOR_OBJECT_METHODS         = false,

        --- Whether use fake entity for data entity cache system, to avoid cache penetration
        DATA_CACHE_USE_FAKE_ENTITY          = true,

        --- The time out of the fake entities(second)
        DATA_CACHE_FAKE_ENTITY_TIMEOUT      = 3600,

        --- Whether only use the custom bit operation by PLoop
        USE_CUSTOM_BIT_IMPLEMENTATION       = false,

        --- Whether save the argument definitions as attachment for __Arguments__
        ENABLE_ARGUMENTS_ATTACHMENT         = false,

        --- Whether save the return definitions as attachment for __Return__
        ENABLE_RETURN_ATTACHMENT            = false,
    }

    -- Special constraint
    if PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD then
        PLOOP_PLATFORM_SETTINGS.CLASS_NO_MULTI_VERSION_CLASS = false
    end

    -----------------------------------------------------------------------
    --                               share                               --
    -----------------------------------------------------------------------
    strtrim                             = function (s)    return s and strgsub(s, "^%s*(.-)%s*$", "%1") or "" end
    readonly                            = function (self) error(strformat("The %s can't be written", tostring(self)), 2) end
    writeonly                           = function (self) error(strformat("The %s can't be read",    tostring(self)), 2) end
    wipe                                = function (t)    for k in pairs, t do t[k] = nil end return t end
    getfield                            = function (self, key) return self[key] end
    safeget                             = function (self, key) local ok, ret = pcall(getfield, self, key) if ok then return ret end end
    loadinittable                       = function (obj, initTable) for name, value in pairs, initTable do obj[name] = value end end
    getprototypemethod                  = function (target, method) local func = safeget(getmetatable(target), method) return type(func) == "function" and func or nil end
    getobjectvalue                      = function (target, method, useobjectmethod, ...) local func = useobjectmethod and safeget(target, method) or safeget(getmetatable(target), method) if type(func) == "function" then return func(target, ...) end end
    uinsert                             = function (self, val) for _, v in ipairs, self, 0 do if v == val then return end end tinsert(self, val) end
    disposeObj                          = function (obj) obj:Dispose() end
    newindex                            = (function() local k return function(init) if init then k = type(init) == "number" and init or 1 else k = k + 1 end return k end end)()
    newflags                            = (function() local k return function(init) if init then k = type(init) == "number" and init or 1 else k = k * 2 end return k end end)()
    parseindex                          = (function() local map = { "1st", "2nd", "3rd" } return function(idx) return map[idx] or (idx .. "th") end end)()

    --- new type events
    enumdefined                         = fakefunc
    structdefined                       = fakefunc
    classdefined                        = fakefunc
    interfacedefined                    = fakefunc

    -----------------------------------------------------------------------
    --                              storage                              --
    -----------------------------------------------------------------------
    newstorage                          = PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD and function() return {} end or function(weak) return setmetatable({}, weak) end
    savestorage                         = PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD and function(self, key, value)
        local new
        if value == nil then
            if self[key] == nil then return self end
            new                         = {}
        else
            if self[key] ~= nil then self[key] = value return self end
            new                         = { [key] = value }
        end
        for k, v in pairs, self do if k ~= key then new[k] = v end end
        return new
    end or function(self, key, value) self[key] = value return self end

    -----------------------------------------------------------------------
    --                               debug                               --
    -----------------------------------------------------------------------
    getcallline                         = not debuginfo and fakefunc or function (stack)
        local info                      = debuginfo((stack or 2) + 1, "lS")
        if info then
            return "@" .. (info.short_src or "unknown") .. ":" .. (info.currentline or "?")
        end
    end
    parsestack                          = function (stack) return tonumber(stack) or 1 end

    -----------------------------------------------------------------------
    --                               clone                               --
    -----------------------------------------------------------------------
    deepClone                           = function (src, tar, override, cache)
        if cache then cache[src]        = tar end

        for k, v in pairs, src do
            if override or tar[k] == nil then
                if cache and cache[v] then
                    tar[k]              = cache[v]
                elseif type(v) == "table" then
                    local cls           = getmetatable(v)
                    if cls == nil then
                        tar[k]          = deepClone(v, {}, override, cache)
                    else
                        local c         = getprototypemethod(cls, "Clone")
                        c               = c and c(v, cls) or v
                        if cache then cache[v] = c end
                        tar[k]          = c
                    end
                else
                    tar[k]              = v
                end
            elseif type(v) == "table" and type(tar[k]) == "table" and getmetatable(v) == nil and getmetatable(tar[k]) == nil then
                deepClone(v, tar[k], override, cache)
            end
        end
        return tar
    end

    tblclone                            = function (src, tar, deep, override, safe)
        if src then
            if deep then
                local cache             = safe and _Cache()
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

    clone                               = function (src, deep, safe)
        if type(src) == "table" then
            local cls                   = getmetatable(src)
            if cls == nil then
                return tblclone(src, {}, deep, true, safe)
            else
                local clone             = getprototypemethod(cls, "Clone")
                return clone and clone(src, cls) or src
            end
        else
            return src
        end
    end

    -----------------------------------------------------------------------
    --                          loading snippet                          --
    -----------------------------------------------------------------------
    if LUA_VERSION > 5.1 then
        loadsnippet                     = function (chunk, source, env)
            Debug("[core][loadsnippet] ==> %s ....", source or "anonymous")
            Trace(chunk)
            Trace("[core][loadsnippet] <== %s", source or "anonymous")
            return loadstring(chunk, source, nil, env or _G)
        end
    else
        loadsnippet                     = function (chunk, source, env)
            Debug("[core][loadsnippet] ==> %s ....", source or "anonymous")
            Trace(chunk)
            Trace("[core][loadsnippet] <== %s", source or "anonymous")
            local v, err                = loadstring(chunk, source)
            if v then setfenv(v, env or _G) end
            return v, err
        end
    end

    -----------------------------------------------------------------------
    --                         flags management                          --
    -----------------------------------------------------------------------
    if not PLOOP_PLATFORM_SETTINGS.USE_CUSTOM_BIT_IMPLEMENTATION and ((LUA_VERSION == 5.2 and type(_G.bit32) == "table") or (LUA_VERSION == 5.1 and type(_G.bit) == "table")) then
        lshift                          = _G.bit32 and _G.bit32.lshift  or _G.bit.lshift
        rshift                          = _G.bit32 and _G.bit32.rshift  or _G.bit.rshift
        band                            = _G.bit32 and _G.bit32.band    or _G.bit.band
        bnot                            = _G.bit32 and _G.bit32.bnot    or _G.bit.bnot
        bor                             = _G.bit32 and _G.bit32.bor     or _G.bit.bor
        bxor                            = _G.bit32 and _G.bit32.bxor    or _G.bit.bxor

        validateflags                   = function (x, n) return band(x, n or 0) > 0 end
        turnonflags                     = function (x, n) return bor(x, n or 0) end
        turnoffflags                    = function (x, n) return band(bnot(x), n or 0) end
    else
        -- Create the custom bit lib, for simple, don't check whether the number is integer
        -- Although the Lua5.3 provide the bitwise, but 64 bit could cause some bugs
        local MOD                       = 2^32
        local MODMAX                    = MOD - 1
        local xorcache                  = { [0]={[0]=0,[1]=1}, [1]={[0]=1,[1]=0} }

        for i = 0, 15 do
            xorcache[i]                 = xorcache[i] or {}

            for j = 0, 15 do
                if not xorcache[i][j] then
                    local a, b          = i, j
                    local res,p         = 0,1
                    while a ~= 0 and b ~= 0 do
                      local am, bm      = a % 2, b % 2
                      res               = res + xorcache[am][bm] * p
                      a                 = (a - am) / 2
                      b                 = (b - bm) / 2
                      p                 = p * 2
                    end
                    xorcache[i][j]      = res + (a + b) * p
                end
            end
        end

        local bit_bxor                  = function (a, b)
                                            local res,p = 0,1
                                            while a ~= 0 and b ~= 0 do
                                                local am, bm = a % 16, b % 16
                                                res = res + xorcache[am][bm] * p
                                                a   = (a - am) / 16
                                                b   = (b - bm) / 16
                                                p   = p * 16
                                            end
                                            res = res + (a + b) * p
                                            return res
                                        end

        local tobit                     = function(x) x = x % MOD return x >= 0x80000000 and (x - MOD) or x end
        local bit_bnot                  = function(a) return MODMAX - a end
        local bit_band                  = function(a, b) return ((a+b) - bit_bxor(a,b))/2 end
        local bit_bor                   = function(a, b) return MODMAX - bit_band(MODMAX - a, MODMAX - b) end
        local bit_rshift, bit_lshift
        bit_rshift                      = function(a, d) return d < 0 and bit_lshift(a, -d) or floor(a % MOD / 2^d) end
        bit_lshift                      = function(a, d) return d < 0 and bit_rshift(a, -d) or (a * 2^d) % MOD end

        lshift                          = function(a, d) if not(a and d) then error("Usage: lshift(a, b) - the a and b be provided", 2) end return tobit(bit_lshift(a % MOD, d % 32)) end
        rshift                          = function(a, d) if not(a and d) then error("Usage: rshift(a, b) - the a and b be provided", 2) end return tobit(bit_rshift(a % MOD, d % 32)) end
        band                            = function(a, b) if not(a and b) then error("Usage: band(a, b) - the a and b be provided", 2)   end return tobit(bit_band(a % MOD, b % MOD)) end
        bnot                            = function(a)    if not a        then error("Usage: bnot(a) - the a provided", 2)               end return tobit(bit_bnot(a % MOD)) end
        bor                             = function(a, b) if not(a and b) then error("Usage: bor(a, b) - the a and b be provided", 2)    end return tobit(bit_bor(a % MOD, b % MOD)) end
        bxor                            = function(a, b) if not(a and b) then error("Usage: bxor(a, b) - the a and b be provided", 2)   end return tobit(bit_bxor(a % MOD, b % MOD)) end

        validateflags                   = function (x, n) if not n or x > n then return false end n = n % (2 * x) return (n - n % x) == x end
        turnonflags                     = function (x, n) return validateflags(x, n) and n or (x + (n or 0)) end
        turnoffflags                    = function (x, n) return validateflags(x, n) and (n - x) or n end
    end

    function inttoreal(int)
        if int == 0 then return 0 end

        local b1, b2                    = rshift(int, 16), band(int, 2^16-1)
        local intSign, intSignRest, intExponent, intExponentRest
        local faDigit

        intSign                         = rshift(b1, 15)
        intSignRest                     = band(b1, 32767)

        intExponent                     = rshift(intSignRest, 7)
        intExponentRest                 = band(intSignRest, 127)

        faDigit                         = floor((intExponentRest * 65536 + b2) / 8388608 * 10^8 + 0.5) / 10^8

        return mpow(-1, intSign) * mpow(2, intExponent - 127) * (faDigit + 1)
    end

    function realtoint(real)
        if real == 0 then return 0 end

        local intSign, intSignRest, intExponent, intExponentRest
        local faDigit

        intSign                         = real < 0 and 1 or 0
        real                            = abs(real)

        intExponent                     = floor(mlog(real) / mlog(2))

        faDigit                         = real / mpow(2, intExponent) - 1
        intExponent                     = intExponent + 127

        faDigit                         = floor( faDigit * 8388608 + 0.5 )
        intExponentRest                 = rshift(faDigit, 16)

        intSignRest                     = lshift(intExponent, 7) + intExponentRest

        local b1                        = lshift(intSign, 15) + intSignRest
        local b2                        = band(faDigit, 65535)
        local int                       = lshift(b1, 16) + b2

        return int < 0 and (2^32 + int) or int
    end

    -----------------------------------------------------------------------
    --                             newproxy                              --
    -----------------------------------------------------------------------
    newproxy                            = not PLOOP_PLATFORM_SETTINGS.UNSAFE_MODE and newproxy or (function ()
        local falseMeta                 = { __metatable = false }
        local proxymap                  = newstorage(WEAK_ALL)

        return function (prototype)
            if prototype == true then
                local meta              = {}
                prototype               = setmetatable({}, meta)
                proxymap[prototype]     = meta
                return prototype
            elseif proxymap[prototype] then
                return setmetatable({}, proxymap[prototype])
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
            local getinfo               = debug.getinfo
            local getupvalue            = debug.getupvalue
            local upvaluejoin           = debug.upvaluejoin
            local getlocal              = debug.getlocal

            setfenv                     = function (f, t)
                f = type(f) == 'function' and f or getinfo(f + 1, 'f').func
                local up, name          = 0
                repeat
                    up                  = up + 1
                    name                = getupvalue(f, up)
                until name == '_ENV' or name == nil
                if name then upvaluejoin(f, up, function() return t end, 1) end
            end

            getfenv                     = function (f)
                local cf, up, name, val = type(f) == 'function' and f or getinfo(f + 1, 'f').func, 0
                repeat
                    up                  = up + 1
                    name, val           = getupvalue(cf, up)
                until name == '_ENV' or name == nil
                if val then return val end

                if type(f) == "number" then
                    f, up               = f + 1, 0
                    repeat
                        up              = up + 1
                        name, val       = getlocal(f, up)
                    until name == '_ENV' or name == nil
                    if val then return val end
                end
            end
        else
            getfenv                     = fakefunc
            setfenv                     = fakefunc
        end
    end
    safesetfenv                         = fakefunc

    -----------------------------------------------------------------------
    --                            main cache                             --
    -----------------------------------------------------------------------
    _Cache                              = setmetatable({}, {
        __call                          = PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD and function(self, tbl) return tbl and wipe(tbl) or {} end
                                        or function(self, tbl) if tbl then return tinsert(self, wipe(tbl)) else return tremove(self) or {} end end,
        }
    )

    -----------------------------------------------------------------------
    --                                log                                --
    -----------------------------------------------------------------------
    local generateLogger                = function (prefix, loglvl)
        local handler                   = PLOOP_PLATFORM_SETTINGS.CORE_LOG_HANDLER
        return PLOOP_PLATFORM_SETTINGS.CORE_LOG_LEVEL > loglvl and fakefunc or
            function(msg, stack, ...)
                if type(stack) == "number" then
                    msg                 = prefix .. strformat(msg, ...) .. (getcallline(stack + 1) or "")
                elseif stack then
                    msg                 = prefix .. strformat(msg, stack, ...)
                else
                    msg                 = prefix .. msg
                end
                return handler(msg, loglvl)
            end
    end

    Trace                               = generateLogger("[PLoop:Trace]", 1)
    Debug                               = generateLogger("[PLoop:Debug]", 2)
    Info                                = generateLogger("[PLoop: Info]", 3)
    Warn                                = generateLogger("[PLoop: Warn]", 4)
    Error                               = generateLogger("[PLoop:Error]", 5)
    Fatal                               = generateLogger("[PLoop:Fatal]", 6)

    -----------------------------------------------------------------------
    --                          keyword helper                           --
    -----------------------------------------------------------------------
    local NIL_HOLDER                    = fakefunc     -- no means
    local IMP_HOLDER                    = parsestack

    local parseParams                   = function (keyword, ptype, ...)
        local visitor                   = keyword and environment.GetKeywordVisitor(keyword)
        local env, target, definition, flag, stack

        for i = 1, select('#', ...) do
            local v                     = select(i, ...)
            local t                     = type(v)

            if t == "boolean" then
                if flag == nil then flag = v end
            elseif t == "number" then
                stack                   = stack or v
            elseif t == "function" then
                definition              = definition or v
            elseif t == "string" then
                v                       = strtrim(v)
                if strfind(v, "^%S+$") then
                    target              = target or v
                else
                    definition          = definition or v
                end
            elseif t == "userdata" then
                if ptype and ptype.Validate(v) then
                    target              = target or v
                end
            elseif t == "table" then
                if getmetatable(v) ~= nil then
                    if ptype and ptype.Validate(v) then
                        target          = target or v
                    else
                        env             = env or v
                    end
                elseif v == _G then
                    env                 = env or v
                else
                    definition          = definition or v
                end
            end
        end

        -- Default
        stack                           = stack or 1
        env                             = env or visitor or getfenv(stack + 3) or _G

        return visitor, env, target, definition, flag, stack
    end

    -- Used for features like property, event, member and namespace
    getFeatureParams                    = function (keyword, ftype, ...)
        local  visitor, env, target, definition, flag, stack = parseParams(keyword, ftype, ...)
        return visitor, env, target, definition, flag, stack
    end

    -- Used for types like enum, struct, class and interface : class([env,][name,][definition,][keepenv,][stack])
    getTypeParams                       = function (nType, ptype, ...)
        local  visitor, env, target, definition, flag, stack = parseParams(nType, nType, ...)

        if target then
            if type(target) == "string" then
                local path              = target
                local full              = path:find("[^%P_]+")
                local root              = full and ROOT_NAMESPACE or namespace.GetNamespaceForNext() or environment.GetNamespace(visitor or env)
                target                  = namespace.GetNamespace(root, path)
                if target then
                    if not nType.Validate(target) then
                        target          = nil
                    end
                else
                    target              = prototype.NewProxy(ptype)
                    namespace.SaveNamespace(root, path, target, stack + 2)
                end

                if target then
                    if visitor then rawset(visitor, namespace.GetNamespaceName(target, true), target) end
                    if env and env ~= visitor then rawset(env, namespace.GetNamespaceName(target, true), target) end
                end
            end
        else
            -- Anonymous
            target                      = prototype.NewProxy(ptype)
            namespace.SaveAnonymousNamespace(target)
        end

        return visitor, env, target, definition, flag, stack
    end

    parseDefinition                     = function (definition, env, stack)
        if type(definition) == "string" then
            local def, msg              = loadsnippet("return function(_ENV) " .. definition .. " end", nil, env)
            if def then
                def, msg                = pcall(def)
                if def then
                    definition          = msg
                else
                    error(msg, (stack or 1) + 1)
                end
            else
                error(msg, (stack or 1) + 1)
            end
        end
        return definition
    end

    parseNamespace                      = function (name, visitor, env)
        if type(name) == "string" and not strfind(name, "[^%P_]+") then
            name                        = strtrim(name)
            name                        = visitor and visitor[name] or env and env[name]
        end
        return name and namespace.Validate(name)
    end

    saveTemplateImplement               = function (implement, params, target, i)
        i                               = i or 1
        if i > #params then
            return savestorage(implement, IMP_HOLDER, target)
        else
            local param                 = params[i]
            if param == nil then param  = NIL_HOLDER end
            return savestorage(implement, param, saveTemplateImplement(implement[param] or {}, params, target, i + 1))
        end
    end

    getTemplateImplement                = function (implement, params)
        for i = 1, #params do
            if not implement then return end
            local param                 = params[i]
            if param == nil then param = NIL_HOLDER end
            implement                   = implement[param]
        end

        return implement and implement[IMP_HOLDER]
    end
end

-------------------------------------------------------------------------------
-- The prototypes are types of other types(like classes), for a class "A",
-- A is its object's type and the class is A's prototype.
--
-- The prototypes are simple userdata generated like:
--
--      proxy           = prototype {
--          __index     = function(self, key) return rawget(self, "__" .. key) end,
--          __newindex  = function(self, key, value) rawset(self, "__" .. key, value) end,
--      }
--
--      obj             = prototype.NewObject(proxy)
--      obj.Name        = "Test"
--      print(obj.Name, obj.__Name)
--
-- The prototypes are normally userdata created by newproxy if the newproxy API
-- existed, otherwise a fake newproxy will be used and they will be tables.
--
-- All meta-table settings will be copied to the result's meta-table, and there
-- are two fields whose default value is provided by the prototype system :
--      * __metatable : if nil, the prototype itself would be used.
--      * __tostring  : if its value is string, it'll be converted to a function
--              that return the value.
--
-- The prototype system also support a simple inheritance system like :
--
--      cproxy          = prototype (proxy, {
--          __call      = function(self, ...) end,
--      })
--
-- The new prototype's meta-table will copy meta-settings from its super except
-- the __metatable.
--
-- The complete definition syntaxes are
--
--      val = prototype ([super,]definiton[,nodeepclone][,stack])
--
-- The params :
--      * super         : prototype, the super prototype whose meta-settings
--              would be copied to the new one.
--
--      * definition    : table, the prototype's meta-settings.
--
--      * nodeepclone   : boolean, the __index maybe a table, normally, it's
--              content would be deep cloned to the prototype's meta-settings,
--              if true, the __index table will be used directly, so you may
--              modify it after the prototype's definition.
--
--      * stack         : number, the stack level used to raise errors.
--
-- @prototype   prototype
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                         private constants                         --
    -----------------------------------------------------------------------
    FLD_PROTOTYPE_META                  = "__PLOOP_PROTOTYPE_META"

    -----------------------------------------------------------------------
    --                          private storage                          --
    -----------------------------------------------------------------------
    local _Prototype                    = PLOOP_PLATFORM_SETTINGS.UNSAFE_MODE and setmetatable({}, { __index = function(_, p) return type(p) == "table" and rawget(p, FLD_PROTOTYPE_META) or nil end }) or newstorage(WEAK_ALL)

    -----------------------------------------------------------------------
    --                          private helpers                          --
    -----------------------------------------------------------------------
    local savePrototype                 = PLOOP_PLATFORM_SETTINGS.UNSAFE_MODE and function(p, meta) rawset(p, FLD_PROTOTYPE_META, meta) end or function(p, meta) _Prototype = savestorage(_Prototype, p, meta) end

    local newPrototype                  = function (meta, super, nodeepclone, stack)
        local name
        local prototype                 = newproxy(true)
        local p                         = getmetatable(prototype)

        savePrototype(prototype, p)

        -- Default
        if meta                         then tblclone(meta, p,  not nodeepclone, true) end
        if p.__metatable     == nil     then p.__metatable      = prototype end
        if type(p.__tostring)== "string"then name, p.__tostring = p.__tostring, nil end
        if p.__tostring      == nil     then p.__tostring       = name and function() return name end end

        -- Inherit
        if super                        then tblclone(_Prototype[super], p, true, false) end

        Debug("[prototype] %s created", (stack or 1) + 1, name or "anonymous")

        return prototype
    end

    -----------------------------------------------------------------------
    --                             prototype                             --
    -----------------------------------------------------------------------
    prototype                           = newPrototype {
        __tostring                      = "prototype",
        __index                         = {
            --- Get the methods of the prototype
            -- @static
            -- @method  GetMethods
            -- @owner   prototype
            -- @param   prototype                   the target prototype
            -- @return  iter:function               the iterator
            -- @return  prototype                   the prototype itself
            -- @usage   for name, func in prototype.GetMethods(class) do print(name) end
            ["GetMethods"]              = function(self)
                local methods           = _Prototype[self] and _Prototype[self].__index
                if methods and type(methods) == "table" then
                    return function(self, n)
                        local k, v      = next(methods, n)
                        while k and type(v) ~= "function" do k, v = next(methods, k) end
                        return k, v
                    end, self
                else
                    return fakefunc, self
                end
            end;

            --- Create a proxy with the prototype's meta-table
            -- @static
            -- @method  NewProxy
            -- @owner   prototype
            -- @param   prototype                   the target prototype
            -- @return  proxy:userdata              the proxy of the same meta-table
            -- @usage   clsA = prototype.NewProxy(class)
            ["NewProxy"]                = newproxy;

            --- Create a table(object) with the prototype's meta-table
            -- @static
            -- @method  NewObject
            -- @owner   prototype
            -- @format  (prototype, [object])
            -- @param   prototype                   the target prototype
            -- @param   object:table                the raw-table used to be set the prototype's metatable
            -- @return  object:table                the table with the prototype's meta-table
            ["NewObject"]               = function(self, tbl) return setmetatable(type(tbl) == "table" and tbl or {}, _Prototype[self]) end;

            --- Whether the value is an object(proxy) of the prototype(has the same meta-table),
            -- only works for the prototype that use itself as the __metatable.
            -- @static
            -- @method  ValidateValue
            -- @owner   prototype
            -- @format  (prototype, value[, onlyvalid])
            -- @param   prototype                   the target prototype
            -- @param   value:(table|userdata)      the value to be validated
            -- @param   onlyvalid:boolean           if true use true instead of the error message
            -- @return  value                       the value if it's a value of the prototype, otherwise nil
            -- @return  error                       the error message if the value is not valid
            ["ValidateValue"]           = function(self, val, onlyvalid)
                if getmetatable(val)    == self then return val end
                return nil, onlyvalid   or ("the %s is not a valid value of [prototype]" .. tostring(self))
            end;

            --- Whether the value is a prototype
            -- @static
            -- @method  Validate
            -- @owner   prototype
            -- @param   prototype                   the prototype to be validated
            -- @return  result:boolean              true if the prototype is valid
            ["Validate"]                = function(self) return _Prototype[self] and self or nil end;
        },
        __newindex                      = readonly,
        __call                          = function (self, ...)
            local meta, super, nodeepclone, stack

            for i = 1, select("#", ...) do
                local value             = select(i, ...)
                local vtype             = type(value)

                if vtype == "boolean" then
                    nodeepclone         = value
                elseif vtype == "number" then
                    stack               = value
                elseif vtype == "table" then
                    if getmetatable(value) == nil then
                        meta            = value
                    elseif _Prototype[value] then
                        super           = value
                    end
                elseif vtype == "userdata" and _Prototype[value] then
                    super               = value
                end
            end

            local prototype             = newPrototype(meta, super, nodeepclone, (stack or 1) + 1)
            return prototype
        end,
    }
end

-------------------------------------------------------------------------------
-- The attributes are used to bind informations to features, or used to modify
-- those features directly.
--
-- The attributes should provide attribute usages.
--
-- The attribute usages are fixed name fields, methods or properties of the
-- attribute:
--
--      * InitDefinition    A method used to modify the target's definition or
--                      init the target before it load its definition, and its
--                      return value will be used as the new definition for the
--                      target if existed.
--          * Parameters :
--              * attribute     the attribute
--              * target        the target like class, method and etc
--              * targettype    the target type, that's a flag value registered
--                      by types. @see attribute.RegisterTargetType
--              * definition    the definition of the target.
--              * owner         the target's owner, it the target is a method,
--                      the owner may be a class or interface that contains it.
--              * name          the target's name, like method name.
--          * Returns :
--              * (definiton)   the return value will be used as the target's
--                      new definition.
--
--      * ApplyAttribute    A method used to apply the attribute to the target.
--                      the method would be called after the definition of the
--                      target. The target still can be modified.
--          * Parameters :
--              * attribute     the attribute
--              * target        the target like class, method and etc
--              * targettype    the target type, that's a flag value registered
--                      by the target type. @see attribute.RegisterTargetType
--              * manager       the definition manager of the target, normally
--                      the definition environment of the target, it's a little
--                      dangerous to use the definition environment directly,
--                      but very useful.
--              * owner         the target's owner, it the target is a method,
--                      the owner may be a class or interface that contains it.
--              * name          the target's name, like method name.
--
--      * AttachAttribute   A method used to generate attachment to the target
--                      such as runtime document, map to database's tables and
--                      etc. The method would be called after the definition of
--                      the target. The target can't be modified.
--          * Parameters :
--              * attribute     the attribute
--              * target        the target like class, method and etc
--              * targettype    the target type, that's a flag value registered
--                      by the target type. @see attribute.RegisterTargetType
--              * owner         the target's owner, it the target is a method,
--                      the owner may be a class or interface that contains it.
--              * name          the target's name, like method name.
--          * Returns :
--              * (attach)      the return value will be used as attachment of
--                      the attribute's type for the target.
--
--      * AttributeTarget   Default 0 (all types). The flags that represents
--              the type of the target like class, method and other features.
--
--      * Inheritable       Default false. Whether the attribute is inheritable
--              , @see attribute.ApplyAttributes
--
--      * Overridable       Default true. Whether the attribute's saved data is
--              overridable.
--
--      * Priority          Default 0. The attribute's priority, the bigger the
--              first to be applied.
--
--      * SubLevel          Default 0. The priority's sublevel, for attributes
--              with same priority, the bigger sublevel the first be applied.
--
--
-- To fetch the attribute usages from an attribute, take the *ApplyAttribute*
-- as an example, the system will first use `attr["ApplyAttribute"]` to fetch
-- the value, since the system don't care how it's provided, field, property,
-- __index all works.
--
-- If the attribute don't provide attribute usage, the default value will be
-- used.
--
-- Although the attribute system is designed without the type requirement, it's
-- better to define them by creating classes extend @see System.IAttribute
--
-- To use the attribute system on a target within its definition, here is list
-- of actions:
--
--   1. Save attributes to the target.         @see attribute.SaveAttributes
--   2. Inherit super attributes to the target.@see attribute.InheritAttributes
--   3. Modify the definition of the target.   @see attribute.InitDefinition
--   4. Change the target if needed.           @see attribute.ToggleTarget
--   5. Apply the definition on the target.
--   6. Apply the attributes on the target.    @see attribute.ApplyAttributes
--   7. Finish the definition of the target.
--   8. Attach attributes datas to the target. @see attribute.AttachAttributes
--
-- The step 2 can be processed after step 3 since we can't know the target's
-- super before it's definition, but in that case, the inherited attributes
-- can't modify the target's definition.
--
-- The step 2, 3, 4, 6 are all optional.
--
-- @prototype   attribute
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                          public constants                         --
    -----------------------------------------------------------------------
    -- ATTRIBUTE TARGETS
    ATTRTAR_ALL                         = 0

    -----------------------------------------------------------------------
    --                          private storage                          --
    -----------------------------------------------------------------------
    -- Attribute Data
    local _AttrTargetTypes              = { [ATTRTAR_ALL] = "All" }

    -- Attribute Target Data
    local _AttrTargetData               = newstorage(WEAK_KEY)
    local _AttrOwnerSubData             = newstorage(WEAK_KEY)
    local _AttrTargetInrt               = newstorage(WEAK_KEY)

    -- Temporary Cache
    local _RegisteredAttrs              = {}
    local _RegisteredAttrsStack         = {}
    local _TargetAttrs                  = newstorage(WEAK_KEY)

    -----------------------------------------------------------------------
    --                          private helpers                          --
    -----------------------------------------------------------------------
    local _UseWarnInstreadErr           = PLOOP_PLATFORM_SETTINGS.ATTR_USE_WARN_INSTEAD_ERROR

    local getAttributeData              = function (attrType, target, owner)
        local adata
        if owner then
            adata                       = _AttrOwnerSubData[attrType]
            adata                       = adata and adata[owner]
        else
            adata                       = _AttrTargetData[attrType]
        end
        if adata then return adata[target] end
    end

    local getAttributeUsage             = function (attr)
        local attrData                  = _AttrTargetData[attribute]
        return attrData and attrData[getmetatable(attr)]
    end

    local getAttrUsageField             = function (obj, field, default, chkType)
        local val                       = obj and safeget(obj, field)
        if val ~= nil and (not chkType or type(val) == chkType) then return val end
        return default
    end

    local getAttributeInfo              = function (attr, field, default, chkType, attrusage)
        local val                       = getAttrUsageField(attr, field, nil, chkType)
        if val == nil then  val         = getAttrUsageField(attrusage or getAttributeUsage(attr), field, nil, chkType) end
        if val ~= nil then return val end
        return default
    end

    local addAttribute                  = function (list, attr, noSameType)
        for _, v in ipairs, list, 0 do
            if v == attr then return end
            if noSameType and getmetatable(v) == getmetatable(attr) then return end
        end

        local idx                       = 1
        local priority                  = getAttributeInfo(attr, "Priority", 0, "number")
        local sublevel                  = getAttributeInfo(attr, "SubLevel", 0, "number")

        while list[idx] do
            local patr                  = list[idx]
            local pprty                 = getAttributeInfo(patr, "Priority", 0, "number")
            local psubl                 = getAttributeInfo(patr, "SubLevel", 0, "number")

            if priority > pprty or (priority == pprty and sublevel > psubl) then break end
            idx                         = idx + 1
        end

        tinsert(list, idx, attr)
    end

    local saveAttributeData             = function (attrType, target, data, owner)
        if owner and (not namespace or namespace.Validate(owner)) then
            _AttrOwnerSubData           = savestorage(_AttrOwnerSubData, attrType, savestorage(_AttrOwnerSubData[attrType] or newstorage(WEAK_KEY), owner, savestorage(_AttrOwnerSubData[attrType] and _AttrOwnerSubData[attrType][owner] or newstorage(WEAK_KEY), target, data)))
        else
            _AttrTargetData             = savestorage(_AttrTargetData, attrType, savestorage(_AttrTargetData[attrType] or newstorage(WEAK_KEY), target, data))
        end
    end

    local function independentCall(back, ...)
        environment.RestoreKeywordAccess(back)
        _RegisteredAttrs                = tremove(_RegisteredAttrsStack) or _Cache()
        return ...
    end

    -----------------------------------------------------------------------
    --                             prototype                             --
    -----------------------------------------------------------------------
    attribute                           = prototype {
        __tostring                      = "attribute",
        __index                         = {
            --- Apply the registered attributes to the target before the definition finished
            -- @static
            -- @method  ApplyAttributes
            -- @owner   attribute
            -- @format  (target, targettype, manager, [owner], [name][, stack])
            -- @param   target                      the target, maybe class, method, object and etc
            -- @param   targettype                  the flag value of the target's type
            -- @param   manager                     the definition manager of the target
            -- @param   owner                       the target's owner, like the class for a method
            -- @param   name                        the target's name if it has owner
            -- @param   stack                       the stack level
            ["ApplyAttributes"]         = function(target, targettype, manager, owner, name, stack)
                local tarAttrs          = _TargetAttrs[target]
                if not tarAttrs then return end

                stack                   = parsestack(stack) + 1

                -- Apply the attribute to the target
                Debug("[attribute][ApplyAttributes] ==> [%s]%s", _AttrTargetTypes[targettype] or "Unknown", owner and ("[" .. tostring(owner) .. "]" .. name) or tostring(target))

                for i, attr in ipairs, tarAttrs, 0 do
                    local ausage        = getAttributeUsage(attr)
                    local apply         = getAttributeInfo (attr, "ApplyAttribute", nil, "function", ausage)

                    -- Apply attribute before the definition
                    if apply then
                        Trace("Call %s.ApplyAttribute", tostring(attr))
                        apply(attr, target, targettype, manager, owner, name, stack)
                    end
                end

                Trace("[attribute][ApplyAttributes] <== [%s]%s", _AttrTargetTypes[targettype] or "Unknown", owner and ("[" .. tostring(owner) .. "]" .. name) or tostring(target))
            end;

            --- Attach the registered attributes data to the target after the definition finished
            -- @static
            -- @method  AttachAttributes
            -- @owner   attribute
            -- @format  (target, targettype, [owner], [name][, stack])
            -- @param   target                      the target, maybe class, method, object and etc
            -- @param   targettype                  the flag value of the target's type
            -- @param   owner                       the target's owner, like the class for a method
            -- @param   name                        the target's name if it has owner
            -- @param   stack                       the stack level
            ["AttachAttributes"]        = function(target, targettype, owner, name, stack)
                local tarAttrs          = _TargetAttrs[target]
                if not tarAttrs then return else _TargetAttrs[target] = nil end

                local extInhrt          = _AttrTargetInrt[target] and tblclone(_AttrTargetInrt[target], _Cache())
                local newInhrt          = false
                stack                   = parsestack(stack) + 1

                -- Apply the attribute to the target
                Debug("[attribute][AttachAttributes] ==> [%s]%s", _AttrTargetTypes[targettype] or "Unknown", owner and ("[" .. tostring(owner) .. "]" .. name) or tostring(target))

                for i, attr in ipairs, tarAttrs, 0 do
                    local aType         = getmetatable(attr)
                    local ausage        = getAttributeUsage(attr)
                    local attach        = getAttributeInfo (attr, "AttachAttribute",nil,    "function", ausage)
                    local ovrd          = getAttributeInfo (attr, "Overridable",    true,   nil,        ausage)
                    local inhr          = getAttributeInfo (attr, "Inheritable",    false,  nil,        ausage)

                    -- Try attach the attribute
                    if attach and (ovrd or getAttributeData(aType, target, owner) == nil) then
                        Trace("Call %s.AttachAttribute", tostring(attr))

                        local ret       = attach(attr, target, targettype, owner, name, stack)
                        if ret ~= nil then saveAttributeData(aType, target, ret, owner) end
                    end

                    if inhr then
                        Trace("Save inheritable attribute %s", tostring(attr))

                        extInhrt        = extInhrt or _Cache()
                        extInhrt[aType] = attr
                        newInhrt        = true
                    end
                end

                Trace("[attribute][AttachAttributes] <== [%s]%s", _AttrTargetTypes[targettype] or "Unknown", owner and ("[" .. tostring(owner) .. "]" .. name) or tostring(target))

                _Cache(tarAttrs)

                -- Save
                if newInhrt then
                    _AttrTargetInrt     = savestorage(_AttrTargetInrt, target, extInhrt)
                elseif extInhrt then
                    _Cache(extInhrt)
                end
            end;

            --- Get the attached attribute data of the target
            -- @static
            -- @method  GetAttachedData
            -- @owner   attribute
            -- @format  attributeType, target[, owner]
            -- @param   attributeType               the attribute type
            -- @param   target                      the target
            -- @param   owner                       the target's owner
            -- @return  any                         the attached data
            ["GetAttachedData"]         = function(aType, target, owner) return clone(getAttributeData(aType, target, owner), true, true) end;

            --- Whether the target of attached data of the attribute type
            -- @static
            -- @method  HasAttachedData
            -- @owner   attribute
            -- @format  attributeType, target[, owner]
            -- @param   attributeType               the attribute type
            -- @param   target                      the target
            -- @param   owner                       the target's owner
            -- @return  boolean                     true if have attached data
            ["HasAttachedData"]         = function(aType, target, owner) return getAttributeData(aType, target, owner) ~= nil end;

            --- Get all targets have attached data of the attribute
            -- @static
            -- @method  GetAttributeTargets
            -- @owner   attribute
            -- @param   attributeType               the attribute type
            -- @return  iter:function               the iterator
            -- @return  attributeType               the attribute type
            ["GetAttributeTargets"]     = function(aType)
                local adata             = _AttrTargetData[aType]
                if adata then
                    return function(self, n) return (next(adata, n)) end, aType
                else
                    return fakefunc, aType
                end
            end;

            --- Get all target's owners that have attached data of the attribute
            -- @static
            -- @method  GetAttributeTargetOwners
            -- @owner   attribute
            -- @param   attributeType               the attribute type
            -- @return  iter:function               the iterator
            -- @return  attributeType               the attribute type
            ["GetAttributeTargetOwners"]= function(aType)
                local adata             = _AttrOwnerSubData[aType]
                if adata then
                    return function(self, n) return (next(adata, n)) end, aType
                else
                    return fakefunc, aType
                end
            end;

            --- Whether there are registered attributes
            -- @static
            -- @method  HaveRegisteredAttributes
            -- @owner   attribute
            -- @return  hasattr:boolean             true if have registered attributes
            ["HaveRegisteredAttributes"]= function() return #_RegisteredAttrs > 0 end;

            --- Call a definition function within a standalone attribute system
            -- so it won't use the registered attributes that belong to others.
            -- Normally used in attribute's ApplyAttribute or AttachAttribute
            -- that need create new features with attributes.
            -- @static
            -- @method  IndependentCall
            -- @owner   attribute
            -- @format  definition[, stack]
            -- @param   definition                  the function to be processed
            -- @param   ...                         the parameters
            ["IndependentCall"]         = function(definition, ...)
                tinsert(_RegisteredAttrsStack, _RegisteredAttrs)
                _RegisteredAttrs        = _Cache()
                return independentCall(environment.BackupKeywordAccess(), pcall(definition, ...))
            end;

            --- Register the super's inheritable attributes to the target, must be called after
            -- the @attribute.SaveAttributes and before the @attribute.AttachAttributes
            -- @static
            -- @method  Inherit
            -- @owner   attribute
            -- @format  (target, targettype, ...)
            -- @param   target                      the target, maybe class, method, object and etc
            -- @param   targettype                  the flag value of the target's type
            -- @param   ...                         the target's super that used for attribute inheritance
            ["InheritAttributes"]       = function(target, targettype, ...)
                local cnt               = select("#", ...)
                if cnt == 0 then return end

                -- Apply the attribute to the target
                Debug("[attribute][InheritAttributes] ==> [%s]%s", _AttrTargetTypes[targettype] or "Unknown", tostring(target))

                local tarAttrs          = _TargetAttrs[target]

                -- Check inheritance
                for i = 1, select("#", ...) do
                    local super         = select(i, ...)
                    if super and _AttrTargetInrt[super] then
                        for _, sattr in pairs, _AttrTargetInrt[super] do
                            local aTar  = getAttributeInfo(sattr, "AttributeTarget", ATTRTAR_ALL, "number")

                            if aTar == ATTRTAR_ALL or validateflags(targettype, aTar) then
                                Trace("Inherit attribute %s", tostring(sattr))
                                tarAttrs= tarAttrs or _Cache()
                                addAttribute(tarAttrs, sattr, true)
                            end
                        end
                    end
                end

                Trace("[attribute][InheritAttributes] <== [%s]%s", _AttrTargetTypes[targettype] or "Unknown", tostring(target))

                _TargetAttrs[target]    = tarAttrs
            end;

            --- Use the registered attributes to init the target's definition
            -- @static
            -- @method  InitDefinition
            -- @owner   attribute
            -- @format  (target, targettype, definition, [owner], [name][, stack])
            -- @param   target                      the target, maybe class, method, object and etc
            -- @param   targettype                  the flag value of the target's type
            -- @param   definition                  the definition of the target
            -- @param   owner                       the target's owner, like the class for a method
            -- @param   name                        the target's name if it has owner
            -- @param   stack                       the stack level
            -- @return  definition                  the target's new definition, nil means no change, false means cancel the target's definition, it may be done by the attribute, these may not be supported by the target type
            ["InitDefinition"]          = function(target, targettype, definition, owner, name, stack)
                local tarAttrs          = _TargetAttrs[target]
                if not tarAttrs then return definition end

                stack                   = parsestack(stack) + 1

                -- Apply the attribute to the target
                Debug("[attribute][InitDefinition] ==> [%s]%s", _AttrTargetTypes[targettype] or "Unknown", owner and ("[" .. tostring(owner) .. "]" .. name) or tostring(target))

                for i, attr in ipairs, tarAttrs, 0 do
                    local ausage        = getAttributeUsage(attr)
                    local apply         = getAttributeInfo (attr, "InitDefinition", nil, "function", ausage)

                    -- Apply attribute before the definition
                    if apply then
                        Trace("Call %s.InitDefinition", tostring(attr))

                        local ret       = apply(attr, target, targettype, definition, owner, name, stack)
                        if ret ~= nil then definition = ret end
                    end
                end

                Trace("[attribute][InitDefinition] <== [%s]%s", _AttrTargetTypes[targettype] or "Unknown", owner and ("[" .. tostring(owner) .. "]" .. name) or tostring(target))

                return definition
            end;

            --- Register the attribute to be used by the next feature
            -- @static
            -- @method  Register
            -- @owner   attribute
            -- @format  attr[, unique][, stack]
            -- @param   attr                        the attribute to be registered
            -- @param   unique                      whether don't register the attribute if there is another attribute with the same type
            -- @param   stack                       the stack level
            ["Register"]                = function(attr, unique, stack)
                if type(attr)~= "table" and type(attr) ~= "userdata" then error("Usage : attribute.Register(attr[, unique][, stack]) - the attr is not valid", parsestack(stack) + 1) end
                Debug("[attribute][Register] %s", tostring(attr))
                return addAttribute(_RegisteredAttrs, attr, unique)
            end;

            --- Register attribute target type
            -- @static
            -- @method  RegisterTargetType
            -- @owner   attribute
            -- @param   name:string                 the target type's name
            -- @return  flag:number                 the target type's flag value
            ["RegisterTargetType"]      = function(name)
                local i                 = 1
                while _AttrTargetTypes[i] do i = i * 2 end
                _AttrTargetTypes[i]     = name
                Debug("[attribute][RegisterTargetType] %q = %d", name, i)
                return i
            end;

            --- Release the registered attribute of the target
            -- @static
            -- @method  RegisterTargetType
            -- @owner   attribute
            -- @param   target                      the target, maybe class, method, object and etc
            ["ReleaseTargetAttributes"] = function(target)
                local tarAttrs          = _TargetAttrs[target]
                if not tarAttrs then return else _TargetAttrs[target] = nil end
            end;

            --- Save the current registered attributes to the target
            -- @static
            -- @method  SaveAttributes
            -- @owner   attribute
            -- @format  (target, targettype[, stack])
            -- @param   target                      the target
            -- @param   targettype                  the target type
            -- @param   stack                       the stack level
            ["SaveAttributes"]          = function(target, targettype, stack)
                if #_RegisteredAttrs   == 0 then return end

                local regAttrs          = _RegisteredAttrs
                _RegisteredAttrs        = _Cache()

                Debug("[attribute][SaveAttributes] ==> [%s]%s", _AttrTargetTypes[targettype] or "Unknown", tostring(target))

                for i = #regAttrs, 1, -1 do
                    local attr          = regAttrs[i]
                    local aTar          = getAttributeInfo(attr, "AttributeTarget", ATTRTAR_ALL, "number")

                    if aTar ~= ATTRTAR_ALL and not validateflags(targettype, aTar) then
                        if _UseWarnInstreadErr then
                            Warn("The attribute %s can't be applied to the [%s]%s", tostring(attr), _AttrTargetTypes[targettype] or "Unknown", tostring(target))
                            tremove(regAttrs, i)
                        else
                            _Cache(regAttrs)
                            error(strformat("The attribute %s can't be applied to the [%s]%s", tostring(attr), _AttrTargetTypes[targettype] or "Unknown", tostring(target)), parsestack(stack) + 1)
                        end
                    end
                end

                Debug("[attribute][SaveAttributes] <== [%s]%s", _AttrTargetTypes[targettype] or "Unknown", tostring(target))

                _TargetAttrs[target]    = regAttrs
            end;

            --- Toggle the target, save the old target's attributes to the new one
            -- @static
            -- @method  ToggleTarget
            -- @owner   attribute
            -- @format  (old, new)
            -- @param   old                         the old target
            -- @param   new                         the new target
            ["ToggleTarget"]            = function(old, new)
                local tarAttrs          = _TargetAttrs[old]
                if tarAttrs and new and new ~= old then
                    _TargetAttrs[old]   = nil
                    _TargetAttrs[new]   = tarAttrs
                end
            end;

            --- Un-register an attribute
            -- @static
            -- @method  Unregister
            -- @owner   attribute
            -- @param   attr                        the attribute to be un-registered
            ["Unregister"]              = function(attr)
                for i, v in ipairs, _RegisteredAttrs, 0 do
                    if v == attr then
                        Debug("[attribute][Unregister] %s", tostring(attr))
                        return tremove(_RegisteredAttrs, i)
                    end
                end
            end;
        },
        __newindex                      = readonly,
    }
end

-------------------------------------------------------------------------------
-- The environment is designed to be private and standalone for codes(Module)
-- or type building(class and etc). It provide features like keyword accessing,
-- namespace management, get/set management and etc.
--
--      -- Module is an environment type for codes works like _G
--      _ENV = Module "Test" "v1.0.0"
--
--      -- Declare the namespace for the module
--      namespace "NS.Test"
--
--      -- Import other namespaces to the module
--      import "System.Threading"
--
--      -- By using the get/set management we can use attributes for features
--      -- like functions.
--      __Async__()
--      function DoThreadTask()
--      end
--
--      -- The function with _ENV will be called within a private environment
--      -- where the class A's definition will be processed. The class A also
--      -- will be saved to the namespace NS.Test since its defined in the Test
--      -- Module.
--      class "A" (function(_ENV)
--          -- So the Score's path should be NS.Test.A.Score since it's defined
--          -- in the class A's definition environment whose namespace is the
--          -- class A.
--          enum "Score" { "A", "B", "C", "D" }
--      end)
--
-- @prototype   environment
-- @usage       -- The environment also can be used to call a function within a
--              -- private environment
--              environment(function(_ENV)
--                  import "System.Threading"
--
--                  __Async__()
--                  function DoTask()
--                  end
--              end)
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                         attribute targets                         --
    -----------------------------------------------------------------------
    ATTRTAR_FUNCTION                    = attribute.RegisterTargetType("Function")

    -----------------------------------------------------------------------
    --                         private constants                         --
    -----------------------------------------------------------------------
    -- Environment Special Field
    ENV_NS_OWNER                        = "__PLOOP_ENV_OWNNS"
    ENV_NS_IMPORTS                      = "__PLOOP_ENV_IMPNS"
    ENV_BASE_ENV                        = "__PLOOP_ENV_BSENV"
    ENV_GLOBAL_CACHE                    = "__PLOOP_ENV_GLBCA"
    ENV_DEFINE_MODE                     = "__PLOOP_ENV_DEFINEMODE"

    -----------------------------------------------------------------------
    --                          private storage                          --
    -----------------------------------------------------------------------
    -- Registered Keywords
    local _CTXKeywords                  = {}        -- Keywords for environment type
    local _CTXRTKeywords                = {}        -- Runtime keywords for environment type
    local _GlobalKeywords               = {}        -- Global keywords
    local _RuntimeKeywords              = {}        -- Runtime keywords
    local _GlobalNS                     = {}        -- Global namespaces

    -- Keyword visitor
    local _KeyVisitor                               -- The environment that access the next keyword
    local _AccessKey                                -- The next keyword

    -----------------------------------------------------------------------
    --                          private helpers                          --
    -----------------------------------------------------------------------
    local exportToEnv                   = function(env, name, value, stack)
        local tname                     = type(name)
        stack                           = stack + 1

        if tname == "number" then
            tname                       = type(value)

            if tname == "string" then
                rawset(env, value, environment.GetValue(env, value, stack) or nil)
            elseif namespace.Validate(value) then
                rawset(env, namespace.GetNamespaceName(value, true), value)
            end
        elseif tname == "string" then
            if value ~= nil then
                rawset(env, name, value)
            else
                rawset(env, name, environment.GetValue(env, name, stack) or nil)
            end
        elseif namespace.Validate(name) then
            rawset(env, namespace.GetNamespaceName(name, true), name)
        end
    end

    -----------------------------------------------------------------------
    --                             prototype                             --
    -----------------------------------------------------------------------
    environment                         = prototype {
        __tostring                      = "environment",
        __index                         = {
            --- Apply the environment to the function or stack
            -- @static
            -- @method  Apply
            -- @owner   environment
            -- @format  (env, func)
            -- @format  (env, [stack])
            -- @param   env                         the environment
            -- @param   func:function               the target function
            -- @param   stack:number                the target stack level
            ["Apply"]                   = function(env, func, ...)
                -- Module "Test" (function(_ENV) ... end)
                if type(func)  == "function" then
                    setfenv(func, env)
                    environment.SetDefinitionMode(env, true)
                    func(env, ...)
                    environment.SetDefinitionMode(env, false)
                    return env
                end

                if func == nil or type(func) == "number" then
                    setfenv((func or 1) + 1, env)
                    return env
                end

                error("Usage: environment.Apply(env[, stack]) - the stack should be number or nil", 2)
            end;

            --- Back up the accessed keyword and visitor, should only be used by the system
            -- @static
            -- @method  BackupKeywordAccess
            -- @owner   environment
            -- @return  table
            ["BackupKeywordAccess"]     = function()
                if _AccessKey and _KeyVisitor then
                    return { key = _AccessKey, visitor = _KeyVisitor }
                end
            end;

            --- Export variables by name or a list of names, those variables are
            -- fetched from the namespaces or base environment
            -- @static
            -- @method  ExportVariables
            -- @owner   environment
            -- @format  (env, name[, stack])
            -- @format  (env, namelist[, stack])
            -- @param   env                         the environment
            -- @param   name                        the variable name or namespace
            -- @param   namelist                    the list or variable names
            -- @param   stack                       the stack level
            ["ExportVariables"]         = function(env, name, stack)
                stack                   = parsestack(stack) + 1
                if type(name)  == "table" and getmetatable(name) == nil then
                    for k, v in pairs, name do
                        exportToEnv(env, k, v, stack)
                    end
                else
                    exportToEnv(env, name, nil, stack)
                end
            end;

            --- Get the namespace from the environment
            -- @static
            -- @method  GetNamespace
            -- @owner   environment
            -- @param   env:table                   the environment
            -- @return  ns                          the namespace of the environment
            ["GetNamespace"]            = function(env)
                env = env or getfenv(2)
                return namespace.Validate(type(env) == "table" and rawget(env, ENV_NS_OWNER))
            end;

            --- Get the parent environment from the environment
            -- @static
            -- @method  GetParent
            -- @owner   environment
            -- @param   env:table                   the environment
            -- @return  parentEnv                   the parent of the environment
            ["GetParent"]               = function(env)
                return type(env) == "table" and rawget(env, ENV_BASE_ENV) or nil
            end;

            --- Get the value from the environment based on its namespace and
            -- parent settings(normally be used in __newindex for environment),
            -- the keywords also must be fetched through it.
            -- @static
            -- @method  GetValue
            -- @owner   environment
            -- @format  (env, name[, stack])
            -- @param   env:table                   the environment
            -- @param   name                        the key of the value
            -- @param   stack                       the stack level
            -- @return  value                       the value of the name in the environment
            ["GetValue"]                = (function()
                local head              = _Cache()
                local body              = _Cache()
                local upval             = _Cache()
                local apis              = _Cache()

                -- Check the keywords
                tinsert(head, "_GlobalKeywords")
                tinsert(upval, _GlobalKeywords)

                tinsert(head, "_RuntimeKeywords")
                tinsert(upval, _RuntimeKeywords)

                tinsert(head, "_CTXKeywords")
                tinsert(upval, _CTXKeywords)

                tinsert(head, "_CTXRTKeywords")
                tinsert(upval, _CTXRTKeywords)

                tinsert(head, "_GlobalNS")
                tinsert(upval, _GlobalNS)

                tinsert(head, "regKeyVisitor")
                tinsert(upval, function(env, keyword) _KeyVisitor, _AccessKey = env, keyword return keyword end)

                uinsert(apis, "type")
                uinsert(apis, "rawget")

                if not PLOOP_PLATFORM_SETTINGS.NAMESPACE_NIL_VALUE_ACCESSIBLE then uinsert(apis, "safeget") end

                tinsert(body, "")
                tinsert(body, "")
                tinsert(body, [[
                    local getenvvalue
                    getenvvalue         = function(env, name, isparent)
                        local value
                ]])

                -- Check keywords
                uinsert(apis, "getmetatable")
                tinsert(body, [[
                    if not isparent then
                        value           = _RuntimeKeywords[name]
                        if value then return value end

                        local keys      = _CTXRTKeywords[getmetatable(env)]
                        value           = keys and keys[name]
                        if value then return value end
                ]])

                if PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD and not PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD_LUA_LOCK_APPLIED then
                    -- Don't cache global variables in the environment to avoid conflict
                    -- The cache should be full-hit during runtime after several operations
                    tinsert(body, [[
                        else
                            value       = rawget(env, "]] .. ENV_GLOBAL_CACHE .. [[")
                            if type(value) == "table" then
                                value   = rawget(value, name)
                                if value ~= nil then return value end
                            else
                                value   = nil
                            end
                    ]])
                end

                tinsert(body, [[
                    end
                ]])

                -- Check current namespace
                tinsert(body, [[
                    local nvalid        = namespace.Validate
                    local nsname        = namespace.GetNamespaceName
                    local ns            = nvalid(rawget(env, "]] .. ENV_NS_OWNER .. [["))
                    if ns then
                        if name == nsname(ns, true) then return ns end
                        value           = ]] .. (PLOOP_PLATFORM_SETTINGS.NAMESPACE_NIL_VALUE_ACCESSIBLE and "ns[name]" or "safeget(ns, name)") .. [[
                        if value ~= nil then return value end
                    end
                ]])

                -- Check imported namespaces
                uinsert(apis, "ipairs")
                tinsert(body, [[
                    local imp           = rawget(env, "]] .. ENV_NS_IMPORTS .. [[")
                    if type(imp) == "table" then
                        for _, sns in ipairs, imp, 0 do
                            sns         = nvalid(sns)
                            if sns then
                                if name == nsname(sns, true) then return sns end
                                value   = ]] .. (PLOOP_PLATFORM_SETTINGS.NAMESPACE_NIL_VALUE_ACCESSIBLE and "sns[name]" or "safeget(sns, name)") .. [[
                                if value ~= nil then return value end
                            end
                        end
                    end
                ]])

                -- Check base environment
                uinsert(apis, "_G")
                tinsert(body, [[
                    local parent        = rawget(env, "]] .. ENV_BASE_ENV .. [[")
                    if type(parent) == "table" and parent ~= _G then
                        value = rawget(parent, name)
                        if value == nil then
                            value       = getenvvalue(parent, name, true)
                        end
                    end
                ]])

                tinsert(body, [[
                        return value
                    end

                    return function(env, name, stack)
                        if type(name) == "string" then
                            local value
                ]])

                if PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD and not PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD_LUA_LOCK_APPLIED then
                    -- Don't cache global variables in the environment to avoid conflict
                    -- The cache should be full-hit during runtime after several operations
                    tinsert(body, [[
                        value           = env["]] .. ENV_GLOBAL_CACHE .. [["][name]
                        if value ~= nil then return value end
                    ]])
                end

                -- Check keywords
                uinsert(apis, "getmetatable")
                tinsert(body, [[
                    value               = _GlobalKeywords[name]
                    if value then return regKeyVisitor(env, value) end

                    local keys          = _CTXKeywords[getmetatable(env)]
                    value               = keys and keys[name]
                    if value then return regKeyVisitor(env, value) end
                ]])

                tinsert(body, [[
                    value               = getenvvalue(env, name)
                ]])

                -- Check global namespaces & root namespaces & _G
                tinsert(body, [[
                    if value == nil then
                        value           = namespace.GetNamespace(name)

                        if value == nil then
                            local nvalid= namespace.Validate
                            local nsname= namespace.GetNamespaceName
                            for _, sns in ipairs, _GlobalNS, 0 do
                                if name == nsname(sns, true) then return sns end
                                value   = ]] .. (PLOOP_PLATFORM_SETTINGS.NAMESPACE_NIL_VALUE_ACCESSIBLE and "sns[name]" or "safeget(sns, name)") .. [[
                                if value ~= nil then break end
                            end
                        end
                    end

                    if value == nil then value = rawget(_G, name) end
                ]])

                if not PLOOP_PLATFORM_SETTINGS.ENV_ALLOW_GLOBAL_VAR_BE_NIL then
                    uinsert(apis, "error")
                    uinsert(apis, "strformat")
                    tinsert(body, [[
                        if value == nil then error(strformat("The global variable %q can't be nil", name), (stack or 1) + 1) end
                    ]])
                end

                -- Auto-Cache
                tinsert(body, [[
                    if value ~= nil and not rawget(env, "]] .. ENV_DEFINE_MODE .. [[") then
                ]])

                if PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD and not PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD_LUA_LOCK_APPLIED then
                    uinsert(apis, "savestorage")
                    tinsert(body, [[env["]] .. ENV_GLOBAL_CACHE .. [["] = savestorage(env["]] .. ENV_GLOBAL_CACHE .. [["], name, value)]])
                    if PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD_ENV_AUTO_CACHE_WARN then
                        uinsert(apis, "Warn")
                        uinsert(apis, "tostring")
                        tinsert(body, [[Warn("The [%s] is auto saved to %s, need use 'export{ %q }'", (stack or 1) + 1, name, tostring(env), name)]])
                    end
                else
                    uinsert(apis, "rawset")
                    tinsert(body, [[rawset(env, name, value)]])
                end

                tinsert(body, [[
                            end
                            return value
                        end
                    end
                ]])

                if #head > 0 then
                    body[1]             = "local " .. tblconcat(head, ",") .. "= ..."
                end
                if #apis > 0 then
                    local declare       = tblconcat(apis, ", ")
                    body[2]             = strformat("local %s = %s", declare, declare)
                end

                local func              = loadsnippet(tblconcat(body, "\n"), "environment.GetValue", _PLoopEnv)(unpack(upval))
                _Cache(head) _Cache(body) _Cache(upval) _Cache(apis)

                return func
            end)();

            --- Get the environment that visit the given keyword. The visitor
            -- use @environment.GetValue to access the keywords, so the system
            -- know where the keyword is called, this method is normally called
            -- by the keywords.
            -- @static
            -- @method  GetKeywordVisitor
            -- @owner   environment
            -- @param   keyword                     the keyword
            -- @return  visitor                     the keyword visitor(environment)
            ["GetKeywordVisitor"]       = function(keyword)
                local visitor
                if _AccessKey == keyword then visitor = _KeyVisitor end
                _KeyVisitor             = nil
                _AccessKey              = nil
                return visitor
            end;

            --- Import namespace to environment
            -- @static
            -- @method  ImportNamespace
            -- @owner   environment
            -- @format  (env, ns[, stack])
            -- @param   env                         the environment
            -- @param   ns                          the namespace, it can be the namespace itself or its name path
            -- @param   stack                       the stack level
            ["ImportNamespace"]         = function(env, ns, stack)
                ns                      = namespace.Validate(ns)
                if type(env) ~= "table" then error("Usage: environment.ImportNamespace(env, namespace) - the env must be a table", parsestack(stack) + 1) end
                if not ns then error("Usage: environment.ImportNamespace(env, namespace) - The namespace is not provided", parsestack(stack) + 1) end

                local imports           = rawget(env, ENV_NS_IMPORTS)
                if not imports then imports = newstorage(WEAK_VALUE) rawset(env, ENV_NS_IMPORTS, imports) end
                for _, v in ipairs, imports, 0 do if v == ns then return end end
                tinsert(imports, ns)
            end;

            --- Initialize the environment
            -- @static
            -- @method  Initialize
            -- @owner   environment
            -- @param   env                         the environment
            ["Initialize"]              = PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD and not PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD_LUA_LOCK_APPLIED and function(env)
                if type(env) == "table" and type(rawget(env, ENV_GLOBAL_CACHE)) ~= "table" then rawset(env, ENV_GLOBAL_CACHE, {}) end
            end or fakefunc;

            --- Register a namespace as global namespace, so it can be accessed
            -- by all environments
            -- @static
            -- @method  RegisterGlobalNamespace
            -- @param   namespace                   the target namespace
            ["RegisterGlobalNamespace"] = function(ns)
                local ns                = namespace.Validate(ns)
                if ns then
                    for _, v in ipairs, _GlobalNS, 0 do if v == ns then return end end
                    tinsert(_GlobalNS, ns)
                end
            end;

            --- Register a context keyword, like property must be used in the
            -- definition of a class or interface.
            -- @static
            -- @method  RegisterContextKeyword
            -- @owner   environment
            -- @format  (ctxType, [key, ]keyword)
            -- @param   ctxType                     the context environment's type
            -- @param   key:string                  the keyword's name, it'd be applied if the keyword is a function
            -- @param   keyword                     the keyword entity
            -- @format  (ctxType, keywords)
            -- @param   keywords:table              a collection of the keywords like : { import = import , class, struct }
            ["RegisterContextKeyword"]  = function(ctxType, key, keyword)
                if not ctxType or (type(ctxType) ~= "table" and type(ctxType) ~= "userdata") then
                    error("Usage: environment.RegisterContextKeyword(ctxType, key[, keyword]) - the ctxType isn't valid", 2)
                end
                _CTXKeywords[ctxType]   = _CTXKeywords[ctxType] or {}
                local keywords          = _CTXKeywords[ctxType]

                if type(key) == "table" and getmetatable(key) == nil then
                    for k, v in pairs, key do
                        if type(k) ~= "string"   then k = tostring(v) end
                        if not keywords[k] and v then keywords[k] = v end
                    end
                else
                    if type(key) ~= "string" then key, keyword= tostring(key), key end
                    if key and not keywords[key] and keyword then keywords[key] = keyword end
                end
            end;

            --- Register a runtime context keyword, like this used for contructors
            -- @static
            -- @method  RegisterRuntimeContextKeyword
            -- @owner   environment
            -- @format  (ctxType, [key, ]keyword)
            -- @param   ctxType                     the context environment's type
            -- @param   key:string                  the keyword's name, it'd be applied if the keyword is a function
            -- @param   keyword                     the keyword entity
            -- @format  (ctxType, keywords)
            -- @param   keywords:table              a collection of the keywords like : { import = import , class, struct }
            ["RegisterRuntimeContextKeyword"] = function(ctxType, key, keyword)
                if not ctxType or (type(ctxType) ~= "table" and type(ctxType) ~= "userdata") then
                    error("Usage: environment.RegisterRuntimeContextKeyword(ctxType, key[, keyword]) - the ctxType isn't valid", 2)
                end
                _CTXRTKeywords[ctxType] = _CTXRTKeywords[ctxType] or {}
                local keywords          = _CTXRTKeywords[ctxType]

                if type(key) == "table" and getmetatable(key) == nil then
                    for k, v in pairs, key do
                        if type(k) ~= "string"   then k = tostring(v) end
                        if not keywords[k] and v then keywords[k] = v end
                    end
                else
                    if type(key) ~= "string" then key, keyword= tostring(key), key end
                    if key and not keywords[key] and keyword then keywords[key] = keyword end
                end
            end;

            --- Register a global keyword
            -- @static
            -- @method  RegisterGlobalKeyword
            -- @owner   environment
            -- @format  ([key, ]keyword)
            -- @param   key:string                  the keyword's name, it'd be applied if the keyword is a function
            -- @param   keyword                     the keyword entity
            -- @format  (keywords)
            -- @param   keywords:table              a collection of the keywords like : { import = import , class, struct }
            ["RegisterGlobalKeyword"]   = function(key, keyword)
                local keywords          = _GlobalKeywords

                if type(key) == "table" and getmetatable(key) == nil then
                    for k, v in pairs, key do
                        if type(k) ~= "string" then k = tostring(v) end
                        if not keywords[k] and v then keywords[k] = v end
                    end
                else
                    if type(key) ~= "string" then key, keyword = tostring(key), key end
                    if key and not keywords[key] and keyword then keywords[key] = keyword end
                end
            end;

            --- Register runtime keyword that won't register its caller like 'with', 'throw'.
            -- so it won't cause conflict with global and context keywords
            -- @static
            -- @method  RegisterRuntimeKeyword
            -- @owner   environment
            -- @format  ([key, ]keyword)
            -- @param   key:string                  the keyword's name, it'd be applied if the keyword is a function
            -- @param   keyword                     the keyword entity
            -- @format  (keywords)
            -- @param   keywords:table              a collection of the keywords like : { with = with }
            ["RegisterRuntimeKeyword"]  = function(key, keyword)
                local keywords          = _RuntimeKeywords

                if type(key) == "table" and getmetatable(key) == nil then
                    for k, v in pairs, key do
                        if type(k) ~= "string" then k = tostring(v) end
                        if not keywords[k] and v then keywords[k] = v end
                    end
                else
                    if type(key) ~= "string" then key, keyword = tostring(key), key end
                    if key and not keywords[key] and keyword then keywords[key] = keyword end
                end
            end;

            --- Restore the accessed keyword and visitor, should only be used by the system
            -- @static
            -- @method  RestoreKeywordAccess
            -- @owner   environment
            -- @param   table
            ["RestoreKeywordAccess"]    = function(back)
                if type(back)  == "table" then
                    _AccessKey          = back.key
                    _KeyVisitor         = back.visitor
                end
            end;

            --- Save the value to the environment, useful to save attributes for functions
            -- @static
            -- @method  SaveValue
            -- @owner   environment
            -- @format  (env, name, value[, stack])
            -- @param   env                         the environment
            -- @param   name                        the key
            -- @param   value                       the value
            -- @param   stack                       the stack level
            ["SaveValue"]               = (function()
                local head              = _Cache()
                local body              = _Cache()
                local upval             = _Cache()
                local apis              = _Cache()

                tinsert(body, "")
                tinsert(body, "")

                uinsert(apis, "type")
                uinsert(apis, "parsestack")
                uinsert(apis, "rawset")

                tinsert(body, [[
                    return function(env, key, value, stack)
                        stack           = parsestack(stack) + 1
                ]])

                if PLOOP_PLATFORM_SETTINGS.GLOBAL_VARIABLE_FILTER ~= fakefunc then
                    tinsert(head, "filter")
                    tinsert(upval, PLOOP_PLATFORM_SETTINGS.GLOBAL_VARIABLE_FILTER)

                    if PLOOP_PLATFORM_SETTINGS.GLOBAL_VARIABLE_FILTER_GET_CALLLINE then
                        tinsert(apis, "getcallline")
                        tinsert(body, [[
                            local result = filter(key, value, getcallline(stack))
                        ]])
                    else
                        tinsert(body, [[
                            local result = filter(key, value)
                        ]])
                    end

                    tinsert(body, [[
                        if result then
                    ]])

                    uinsert(apis, "tostring")
                    if PLOOP_PLATFORM_SETTINGS.GLOBAL_VARIABLE_FILTER_USE_WARN then
                        uinsert(apis, "Warn")
                        tinsert(body, [[
                            if type(result) == "string" then
                                Warn(result, stack)
                            else
                                Warn("There is an illegal assignment for %q", stack, tostring(key))
                            end
                        ]])
                    else
                        uinsert(apis, "strformat")
                        uinsert(apis, "error")
                        tinsert(body, [[
                            if type(result) == "string" then
                                error(result, stack)
                            else
                                error(strformat("There is an illegal assignment for %q", tostring(key)), stack)
                            end
                        ]])
                    end

                    tinsert(body, [[
                        end
                    ]])
                end

                tinsert(body, [[
                        if type(key)   == "string" and type(value) == "function" and attribute.HaveRegisteredAttributes() then
                            attribute.SaveAttributes(value, ATTRTAR_FUNCTION, stack)
                            local final = attribute.InitDefinition(value, ATTRTAR_FUNCTION, value, env, key, stack)
                            if final ~= value then
                                attribute.ToggleTarget(value, final)
                                value   = final
                            end
                            attribute.ApplyAttributes (value, ATTRTAR_FUNCTION, nil, env, key, stack)
                            attribute.AttachAttributes(value, ATTRTAR_FUNCTION, env, key, stack)
                        end
                        return rawset(env, key, value)
                    end
                ]])

                if #head > 0 then
                    body[1]             = "local " .. tblconcat(head, ",") .. "= ..."
                end
                if #apis > 0 then
                    local declare       = tblconcat(apis, ", ")
                    body[2]             = strformat("local %s = %s", declare, declare)
                end

                local func              = loadsnippet(tblconcat(body, "\n"), "environment.SaveValue", _PLoopEnv)(unpack(upval))
                _Cache(head) _Cache(body) _Cache(upval) _Cache(apis)

                return func
            end)();

            --- Turn on/off the definition mode for an environment, the value won't be auto-cached
            -- to the environment in definition mode
            -- @param   env                         the environment
            -- @param   mode:boolean                whether turn on the definition mode
            ["SetDefinitionMode"]       = function(env, mode, stack)
                if type(env) ~= "table" then error("Usage: environment.SetDefinitionMode(env, mode) - the env must be a table", parsestack(stack) + 1) end
                rawset(env, ENV_DEFINE_MODE, mode and true or nil)
            end;

            --- Set the namespace to the environment
            -- @static
            -- @method  SetNamespace
            -- @owner   environment
            -- @format  (env, ns[, stack])
            -- @param   env                         the environment
            -- @param   ns                          the namespace, it can be the namespace itself or its name path
            -- @param   stack                       the stack level
            ["SetNamespace"]            = function(env, ns, stack)
                if type(env) ~= "table" then error("Usage: environment.SetNamespace(env, namespace) - the env must be a table", parsestack(stack) + 1) end
                rawset(env, ENV_NS_OWNER, namespace.Validate(ns))
            end;

            --- Set the parent environment to the environment
            -- @static
            -- @method  SetParent
            -- @owner   environment
            -- @format  (env, base[, stack])
            -- @param   env                         the environment
            -- @param   base                        the base environment
            -- @param   stack                       the stack level
            ["SetParent"]               = function(env, base, stack)
                if type(env) ~= "table" then error("Usage: environment.SetParent(env, [parentenv]) - the env must be a table", parsestack(stack) + 1) end
                if base and type(base) ~= "table" then error("Usage: environment.SetParent(env, [parentenv]) - the parentenv must be a table", parsestack(stack) + 1) end
                rawset(env, ENV_BASE_ENV, base or nil)
            end;
        },
        __newindex                      = readonly,
    }

    tenvironment                        = prototype {
        __index                         = environment.GetValue,
        __newindex                      = environment.SaveValue,
        __call                          = environment.Apply,
    }

    -----------------------------------------------------------------------
    --                             keywords                              --
    -----------------------------------------------------------------------
    -----------------------------------------------------------------------
    -- import namespace to current environment
    --
    -- @keyword     import
    -- @usage       import "System.Threading"
    -----------------------------------------------------------------------
    import                              = function (...)
        local visitor, env, name, _, flag, stack  = getFeatureParams(import, namespace, ...)

        name                            = namespace.Validate(name)
        if not env  then error("Usage: import(namespace) - The system can't figure out the environment", stack + 1) end
        if not name then error("Usage: import(namespace) - The namespace is not provided", stack + 1) end

        if visitor then
            return environment.ImportNamespace(visitor, name)
        else
            return namespace.ExportNamespace(env, name, flag)
        end
    end

    -----------------------------------------------------------------------
    -- export variables to current environment
    --
    -- @keyword     export
    -- @usage       export { "print", log = "math.log", System.Delegate }
    -----------------------------------------------------------------------
    export                              = function (...)
        local visitor, env, name, definition, flag, stack  = getFeatureParams(export, namespace, ...)

        if not visitor  then error("Usage: export(name|namelist) - The system can't figure out the environment", stack + 1) end

        environment.ExportVariables(visitor, name or definition)
    end
end

-------------------------------------------------------------------------------
-- The namespaces are used to organize feature types. Same name features can be
-- saved in different namespaces so there won't be any conflict. Environment
-- can have a root namespace so all features defined in it will be saved to the
-- root namespace, also it can import several other namespaces, features that
-- defined in them can be used in the environment directly.
--
-- @prototype   namespace
-- @usage       -- Normally should be used within private code environment
--              environment(function(_ENV)
--                  namespace "NS.Test"
--
--                  class "A" {}  -- NS.Test.A
--              end)
--
--              -- Also you can use a pure namespace like using environment
--              NS.Test (function(_ENV)
--                  class "A" {}  -- NS.Test.A
--              end)
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                         attribute targets                         --
    -----------------------------------------------------------------------
    ATTRTAR_NAMESPACE                   = attribute.RegisterTargetType("Namespace")

    -----------------------------------------------------------------------
    --                         private constants                         --
    -----------------------------------------------------------------------
    FLD_NS_SUBNS                        = "__PLOOP_NS_SUBNS"
    FLD_NS_NAME                         = "__PLOOP_NS_NAME"

    -----------------------------------------------------------------------
    --                          private storage                          --
    -----------------------------------------------------------------------
    local _NSTree                       = PLOOP_PLATFORM_SETTINGS.UNSAFE_MODE and setmetatable({}, {__index = function(_, ns) if type(ns) == "table" then return rawget(ns, FLD_NS_SUBNS) end end}) or newstorage(WEAK_KEY)
    local _NSName                       = PLOOP_PLATFORM_SETTINGS.UNSAFE_MODE and setmetatable({}, {__index = function(_, ns) if type(ns) == "table" then return rawget(ns, FLD_NS_NAME)  end end}) or newstorage(WEAK_KEY)
    local _NextNSForType

    -----------------------------------------------------------------------
    --                          private helpers                          --
    -----------------------------------------------------------------------
    local getNamespace                  = function(root, path)
        if type(root)  == "string" then
            root, path                  = ROOT_NAMESPACE, root
        elseif root    == nil then
            root                        = ROOT_NAMESPACE
        end

        if _NSName[root] ~= nil and type(path) == "string" then
            path                        = strgsub(path, "%s+", "")
            local iter                  = strgmatch(path, "[%P_]+")
            local subname               = iter()

            while subname do
                local nodes             = _NSTree[root]
                root                    = nodes and nodes[subname]
                if not root then return end

                local nxt               = iter()
                if not nxt  then return root end

                subname                 = nxt
            end
        end
    end

    local getValidatedNS                = function(target)
        if type(target) == "string" then return getNamespace(target) end
        return _NSName[target] ~= nil and target or nil
    end

    local saveSubNamespace              = PLOOP_PLATFORM_SETTINGS.UNSAFE_MODE
                                            and function(root, name, subns) rawset(root, FLD_NS_SUBNS, savestorage(rawget(root, FLD_NS_SUBNS) or {}, name, subns)) end
                                            or  function(root, name, subns) _NSTree = savestorage(_NSTree, root, savestorage(_NSTree[root] or {}, name, subns)) end

    local saveNamespaceName             = PLOOP_PLATFORM_SETTINGS.UNSAFE_MODE
                                            and function(ns, name) rawset(ns, FLD_NS_NAME, name) rawset(ns, FLD_NS_SUBNS, false) end
                                            or  function(ns, name) _NSName = savestorage(_NSName, ns, name) end

    -----------------------------------------------------------------------
    --                             prototype                             --
    -----------------------------------------------------------------------
    namespace                           = prototype {
        __tostring                      = "namespace",
        __index                         = {
            --- Export a namespace and its children to an environment
            -- @static
            -- @method  ExportNamespace
            -- @owner   namespace
            -- @format  (env, ns[, override][, stack])
            -- @param   env                         the environment
            -- @param   ns                          the namespace
            -- @param   override                    whether override the existed value in the environment, Default false
            -- @param   stack                       the stack level
            ["ExportNamespace"]         = function(env, ns, override, stack)
                if type(env)   ~= "table" then error("Usage: namespace.ExportNamespace(env, namespace[, override]) - the env must be a table", parsestack(stack) + 1) end
                ns                      = getValidatedNS(ns)
                if not ns then error("Usage: namespace.ExportNamespace(env, namespace[, override]) - The namespace is not provided", parsestack(stack) + 1) end

                local nsname            = _NSName[ns]
                if nsname then
                    nsname              = strmatch(nsname, "[%P_]+$")
                    if override or rawget(env, nsname) == nil then rawset(env, nsname, ns) end
                end

                local nodes             = _NSTree[ns]
                if nodes then
                    for name, sns in pairs, nodes do
                        if override or rawget(env, name) == nil then rawset(env, name, sns) end
                    end
                end
            end;

            --- Get the namespace by path
            -- @static
            -- @method  GetNamespace
            -- @owner   namespace
            -- @format  ([root, ]path)
            -- @param   root                        the root namespace
            -- @param   path:string                 the namespace path
            -- @return  ns                          the namespace
            ["GetNamespace"]            = getNamespace;

            --- Get the sub-namespaces
            -- @static
            -- @method  GetNamespaces
            -- @owner   namespace
            -- @param   root                        the root namespace
            -- @return  iter:function               the iterator
            -- @return  root                        the root namespace
            ["GetNamespaces"]           = function(target)
                local tree              = _NSTree[target]
                if tree then
                    return function(self, n) return next(tree, n) end, target
                else
                    return fakefunc, target
                end
            end;

            --- Get the namespace's path
            -- @static
            -- @method  GetNamespaceName
            -- @owner   namespace
            -- @format  (ns[, lastOnly])
            -- @param   ns                          the namespace
            -- @parma   lastOnly                    whether only the last name of the namespace's path
            -- @return  string                      the path of the namespace or the name of it if lastOnly is true
            ["GetNamespaceName"]        = function(ns, onlyLast)
                local name              = _NSName[ns]
                return name and (onlyLast and strmatch(name, "[%P_]+$") or name) or "Anonymous"
            end;

            --- Get the namespace for next generated type
            -- @static
            -- @method  GetNamespaceForNext
            -- @owner   namespace
            -- @return  namesapce                   the namespace for next generated type
            ["GetNamespaceForNext"]     = function()
                local ns                = _NextNSForType
                _NextNSForType          = nil
                return ns
            end;

            --- Whether the target is anonymous namespace
            -- @static
            -- @method  IsAnonymousNamespace
            -- @owner   namespace
            -- param    ns                          the target namespace
            -- @return  boolean                     true if the target is anonymous namespace
            ["IsAnonymousNamespace"]    = function(ns)
                return _NSName[ns] == false
            end;

            --- Save feature to the namespace
            -- @static
            -- @method  SaveNamespace
            -- @owner   namespace
            -- @format  ([root, ]path, feature[, stack])
            -- @param   root                        the root namespace
            -- @param   path:string                 the path of the feature
            -- @param   feature                     the feature, must be table or userdata
            -- @param   stack                       the stack level
            -- @return  feature                     the feature itself
            ["SaveNamespace"]           = function(root, path, feature, stack)
                if type(root)  == "string" then
                    root, path, feature, stack = ROOT_NAMESPACE, root, path, feature
                elseif root    == nil then
                    root                = ROOT_NAMESPACE
                else
                    root                = getValidatedNS(root)
                end

                stack                   = parsestack(stack) + 1

                if root == nil then
                    error("Usage: namespace.SaveNamespace([root, ]path, feature[, stack]) - the root must be namespace", stack)
                end
                if type(path)  ~= "string" or strtrim(path) == "" then
                    error("Usage: namespace.SaveNamespace([root, ]path, feature[, stack]) - the path must be string", stack)
                else
                    path                = strgsub(path, "%s+", "")
                end
                if type(feature) ~= "table" and type(feature) ~= "userdata" then
                    error("Usage: namespace.SaveNamespace([root, ]path, feature[, stack]) - the feature should be userdata or table", stack)
                end

                if _NSName[feature] ~= nil then
                    local epath         = _Cache()
                    if _NSName[root] then tinsert(epath, _NSName[root]) end
                    path:gsub("[%P_]+", function(name) tinsert(epath, name) end)
                    if tblconcat(epath, ".") == _NSName[feature] then
                        return feature
                    else
                        error("Usage: namespace.SaveNamespace([root, ]path, feature[, stack]) - already registered as " .. (_NSName[feature] or "Anonymous"), stack)
                    end
                end

                local iter              = strgmatch(path, "[%P_]+")
                local subname           = iter()

                while subname do
                    local nodes         = _NSTree[root]
                    local subns         = nodes and nodes[subname]
                    local nxt           = iter()

                    if not nxt then
                        if subns then
                            if subns == feature then return feature end
                            error("Usage: namespace.SaveNamespace([root, ]path, feature[, stack]) - the namespace path has already be used by others", stack)
                        else
                            saveNamespaceName(feature, _NSName[root] and (_NSName[root] .. "." .. subname) or subname)
                            saveSubNamespace(root, subname, feature)
                        end
                    elseif not subns then
                        subns           = prototype.NewProxy(tnamespace)

                        saveNamespaceName(subns, _NSName[root] and (_NSName[root] .. "." .. subname) or subname)
                        saveSubNamespace(root, subname, subns)
                    end

                    root, subname       = subns, nxt
                end

                return feature
            end;

            --- Save anonymous namespace, anonymous namespace also can be used
            -- as new root of another namespace tree.
            -- @static
            -- @method  SaveAnonymousNamespace
            -- @owner   namespace
            -- @param   feature                     the feature, must be table or userdata
            -- @param   stack                       the stack level
            ["SaveAnonymousNamespace"]  = function(feature, stack)
                stack                   = parsestack(stack) + 1
                if type(feature) ~= "table" and type(feature) ~= "userdata" then
                    error("Usage: namespace.SaveAnonymousNamespace(feature[, stack]) - the feature should be userdata or table", stack)
                end
                if _NSName[feature] then
                    error("Usage: namespace.SaveAnonymousNamespace(feature[, stack]) - the feature already registered as " .. _NSName[feature], stack)
                end
                saveNamespaceName(feature, false)
            end;

            --- Set the namespace for next generated type
            -- @static
            -- @method  GetNamespaceForNext
            -- @owner   namespace
            -- @param   namesapce                   the namespace for next generated type
            -- @param   stack                       the stack level
            ["SetNamespaceForNext"]     = function(name, stack)
                local ns                = namespace.Validate(name)
                if not ns and type(name) == "string" then
                    ns                  = prototype.NewProxy(tnamespace)
                    namespace.SaveNamespace(name, ns, parsestack(stack) + 1)
                end
                _NextNSForType          = ns
            end;

            --- Whether the target is a namespace
            -- @static
            -- @method  Validate
            -- @owner   namespace
            -- @param   target                      the query feature
            -- @return  target                      nil if not namespace
            ["Validate"]                = getValidatedNS;
        },
        __newindex                      = readonly,
        __call                          = function(self, ...)
            local visitor, env, target, _, flag, stack = getFeatureParams(namespace, namespace, ...)
            stack                       = stack + 1

            if not env then error("Usage: namespace([env, ]path[, noset][, stack]) - the system can't figure out the environment", stack) end

            if target ~= nil then
                if type(target) == "string" then
                    local ns            = getNamespace(target)
                    if not ns then
                        ns              = prototype.NewProxy(tnamespace)
                        attribute.SaveAttributes(ns, ATTRTAR_NAMESPACE, stack)
                        namespace.SaveNamespace(target, ns, stack)
                        attribute.AttachAttributes(ns, ATTRTAR_NAMESPACE, nil, nil, stack)
                    end
                    target              = ns
                else
                    target              = namespace.Validate(target)
                end

                if not target then error("Usage: namespace([env, ]path[, noset][, stack]) - the system can't figure out the namespace", stack) end
            end

            if not flag then
                if visitor then
                    environment.SetNamespace(visitor, target)
                elseif env and env ~= visitor then
                    environment.SetNamespace(env, target)
                    namespace.ExportNamespace(env, target)
                end
            end

            return target
        end,
    }

    -- default type for namespace
    tnamespace                          = prototype {
        __index                         = PLOOP_PLATFORM_SETTINGS.NAMESPACE_NIL_VALUE_ACCESSIBLE and namespace.GetNamespace or function(self, key)
            local value                 = getNamespace(self, key)
            if value ~= nil then return value end
            error(strformat("The %s.%s is not existed", namespace.GetNamespaceName(self), tostring(key)), 2)
        end,
        __newindex                      = readonly,
        __tostring                      = namespace.GetNamespaceName,
        __metatable                     = namespace,
        __concat                        = function (a, b) return tostring(a) .. tostring(b) end,
        __call                          = function(self, definition)
            if(definition and type(definition) ~= "function") then error(strformat("Usage: namespace %q (function(_ENV) end)", tostring(self)), 2) end

            local env                   = prototype.NewObject(tenvironment)
            environment.Initialize(env)
            environment.SetNamespace(env, self)
            if definition then
                return env(definition)
            else
                return env
            end
        end,
    }

    -----------------------------------------------------------------------
    --                            Initialize                             --
    -----------------------------------------------------------------------
    ROOT_NAMESPACE                      = prototype.NewProxy(tnamespace)
    namespace.SaveAnonymousNamespace(ROOT_NAMESPACE)
end

-------------------------------------------------------------------------------
-- The structures are types for basic and complex organized datas and also the
-- data contracts for value validation. There are three struct types:
--
--  i. Custom    The basic data types like number, string and more advanced
--          types like nature number. Take the Number as an example:
--
--                  struct "Number" (function(_ENV)
--                      function Number(value)
--                          return type(value) ~= "number" and "the %s must be number, got " .. type(value)
--                      end
--                  end)
--
--                  v = Number(true)  -- Error : the value must be number, got boolean
--
--              Unlike the enumeration, the structure's definition is a little
--          complex, the definition body is a function with _ENV as its first
--          parameter, the pattern is designed to make sure the PLoop works
--          with Lua 5.1 and all above versions. The code in the body function
--          will be processed in a private context used to define the struct.
--
--              The function with the struct's name is the validator, also you
--          can use `__valid` instead of the struct's name(There are anonymous
--          structs). The validator would be called with the target value, if
--          the return value is non-false, that means the target value can't
--          pass the validation, normally the return value should be an error
--          message, the `%s` in the message'll be replaced by words based on
--          where it's used, if the return value is true, the system would
--          generte an error message for it.
--
--              If the struct has only the validator, it's an immutable struct
--          that won't modify the validated value. We also need mutable struct
--          like Boolean :
--
--                  struct "Boolean" (function(_ENV)
--                      function __init(value)
--                          return value and true or fale
--                      end
--                  end)
--
--                  print(Boolean(1))  -- true
--
--              The function named `__init` is the initializer, it's used to
--          modify the target value, if the return value is non-nil, it'll be
--          used as the new value of the target.
--
--              The struct can have one base struct so it will inherit the base
--          struct's validator and initializer, the base struct's validator and
--          initializer should be called before the struct's own:
--
--                  struct "Integer" (function(_ENV)
--                      __base = Number
--
--                      local floor = math.floor
--
--                      function Integer(value)
--                          return floor(value) ~= value and "the %s must be integer"
--                      end
--                  end)
--
--                  v = Integer(true)  -- Error : the value must be number, got boolean
--                  v = Integer(1.23)  -- Error : the value must be integer
--
--
-- ii. Member   The member structure represent tables with fixed fields of
--          certain types. Take an example to start:
--
--                  struct "Location" (function(_ENV)
--                      x = Number
--                      y = Number
--                  end)
--
--                  loc = Location{ x = "x" }    -- Error: Usage: Location(x, y) - x must be number
--                  loc = Location(100, 20)
--                  print(loc.x, loc.y)         -- 100  20
--
--              The member sturt can also be used as value constructor(and only
--          the member struct can be used as constructor), the argument order
--          is the same order as the declaration of it members.
--
--              The `x = Number` is the simplest way to declare a member to the
--          struct, but there are other details to be filled in, here is the
--          formal version:
--
--                  struct "Location" (function(_ENV)
--                      member "x" { Type = Number, Require = true }
--                      member "y" { Type = Number, Default = 0    }
--                  end)
--
--                  loc = Location{}            -- Error: Usage: Location(x, y) - x can't be nil
--                  loc = Location(100)
--                  print(loc.x, loc.y)         -- 100  0
--
--              The member is a keyword can only be used in the definition body
--          of a struct, it need a member name and a table contains several
--          settings(the field is case ignored) for the member:
--                  * Type      - The member's type, it could be any enum, struct,
--                      class or interface, also could be 3rd party types that
--                      follow rules(the type's prototype must provide a method
--                      named ValidateValue).
--                  * Require   - Whether the member can't be nil.
--                  * Default   - The default value of the member.
--
--              The member struct also support the validator and initializer :
--
--                  struct "MinMax" (function(_ENV)
--                      member "min" { Type = Number, Require = true }
--                      member "max" { Type = Number, Require = true }
--
--                      function MinMax(val)
--                          return val.min > val.max and "%s.min can't be greater than %s.max"
--                      end
--                  end)
--
--                  v = MinMax(100, 20) -- Error: Usage: MinMax(min, max) - min can't be greater than max
--
--              Since the member struct's value are tables, we also can define
--          struct methods that would be saved to those values:
--
--                  struct "Location" (function(_ENV)
--                      member "x" { Type = Number, Require = true }
--                      member "y" { Type = Number, Default = 0    }
--
--                      function GetRange(val)
--                          return math.sqrt(val.x^2 + val.y^2)
--                      end
--                  end)
--
--                  print(Location(3, 4):GetRange()) -- 5
--
--              We can also declare static methods that can only be used by the
--          struct itself(also for the custom struct):
--
--                  struct "Location" (function(_ENV)
--                      member "x" { Type = Number, Require = true }
--                      member "y" { Type = Number, Default = 0    }
--
--                      __Static__()
--                      function GetRange(val)
--                          return math.sqrt(val.x^2 + val.y^2)
--                      end
--                  end)
--
--                  print(Location.GetRange{x = 3, y = 4}) -- 5
--
--              The `__Static__` is an attribute, it's used here to declare the
--          next defined method is a static one.
--
--              In the example, we declare the default value of the member in
--          the member's definition, but we also can provide the default value
--          in the custom struct like :
--
--                  struct "Number" (function(_ENV)
--                      __default = 0
--
--                      function Number(value)
--                          return type(value) ~= "number" and "%s must be number"
--                      end
--                  end)
--
--                  struct "Location" (function(_ENV)
--                      x = Number
--                      y = Number
--                  end)
--
--                  loc = Location()
--                  print(loc.x, loc.y)         -- 0    0
--
--              The member struct can also have base struct, it will inherit
--          members, non-static methods, validator and initializer, but it's
--          not recommended.
--
--iii. Array    The array structure represent tables that contains a list of
--          same type items. Here is an example to declare an array:
--
--                  struct "Locations" (function(_ENV)
--                      __array = Location
--                  end)
--
--                  v = Locations{ {x = true} } -- Usage: Locations(...) - [1].x must be number
--
--              The array structure also support methods, static methods, base
--          struct, validator and initializer.
--
-- iv. Dict     The dictionary structure represent tables that contains a specific
--          type keys and specific type value pairs.
--
--                  struct "NameAge" (function(_ENV)
--                      __key   = String
--                      __value = Number
--                  end)
--
--                  v = NameAge{ ann = 2, ben = 3 }
--
--
-- To simplify the definition of the struct, table can be used instead of the
-- function as the definition body.
--
--                  -- Custom struct
--                  struct "Number" {
--                      __default = 0,  -- The default value
--                      -- the function with number index would be used as validator
--                      function (val) return type(val) ~= "number" end,
--                      -- Or you can clearly declare it
--                      __valid = function (val) return type(val) ~= "number" end,
--                  }
--
--                  struct "Boolean" {
--                      __init = function(val) return val and true or false end,
--                  }
--
--                  -- Member struct
--                  struct "Location" {
--                      -- Like use the member keyword, just with a name field
--                      { Name = "x", Type = Number, Require = true },
--                      { Name = "y", Type = Number, Require = true },
--
--                      -- Define methods
--                      GetRange = function(val) return math.sqrt(val.x^2 + val.y^2) end,
--                  }
--
--                  -- Array struct
--                  -- A valid type with number index, also can use the __array as the key
--                  struct "Locations" { Location }
--
--                  -- Dict struct
--                  struct "NameAge" { [String] = Number }
--
--
-- If a data type's prototype can provide `ValidateValue(type, value)` method,
-- it'd be marked as a value type, the value type can be used in many places,
-- like the member's type, the array's element type, and class's property type.
--
-- The prototype has provided four value type's prototype: enum, struct, class
-- and interface.
--
--
-- iv. Let's return the first struct **Number**, the error message is generated
-- during runtime, and in PLoop there are many scenarios we only care whether
-- the value match the struct type, so we only need validation, not the error
-- message(the overload system use this technique to choose function).
--
-- The validator can receive 2nd parameter which indicated whether the system
-- only care if the value is valid:
--
--                  struct "Number" (function(_ENV)
--                      function Number(value, onlyvalid)
--                          if type(value) ~= "number" then return onlyvalid or "the %s must be number, got " .. type(value) end
--                      end
--                  end)
--
--                  print(struct.ValidateValue(Number, "test", true))   -- nil, true
--                  print(struct.ValidateValue(Number, "test", false))  -- nil, the %s must be number, got string
--
--
-- v. If your value could be two or more types, you can combine those types like :
--
--                  -- nil, the %s must be value of System.Number | System.String
--                  print(Struct.ValidateValue(Number + String, {}, false))
--
-- You can combine types like enums, structs, interfaces and classes.
--
--
-- vi. If you need the value to be a struct who is a sub type of another struct,
-- (the struct is a sub type of itself), you can create is like `- Number` :
--
--                  struct "Integer" { __base = Number, function(val) return math.floor(val) ~= val end }
--                  print(Struct.ValidateValue( - Number, Integer, false))  -- Integer
--
-- You also can use the `-` operation on interface or class.
--
-- @prototype   struct
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                         attribute targets                         --
    -----------------------------------------------------------------------
    ATTRTAR_STRUCT                      = attribute.RegisterTargetType("Struct")
    ATTRTAR_MEMBER                      = attribute.RegisterTargetType("Member")
    ATTRTAR_METHOD                      = attribute.RegisterTargetType("Method")

    -----------------------------------------------------------------------
    --                          public constants                         --
    -----------------------------------------------------------------------
    STRUCT_TYPE_MEMBER                  = "MEMBER"
    STRUCT_TYPE_ARRAY                   = "ARRAY"
    STRUCT_TYPE_CUSTOM                  = "CUSTOM"
    STRUCT_TYPE_DICT                    = "DICTIONARY"

    -----------------------------------------------------------------------
    --                         private constants                         --
    -----------------------------------------------------------------------
    -- FEATURE MODIFIER
    MOD_SEALED_STRUCT                   = newflags(true)    -- SEALED
    MOD_IMMUTABLE_STRUCT                = newflags()        -- IMMUTABLE
    MOD_TEMPLATE_STRUCT                 = newflags()        -- AS TEMPLATE
    MOD_ALLOWOBJ_STRUCT                 = newflags()        -- ALLOW OBJECT PASS VALIDATION

    -- FIELD INDEX
    FLD_STRUCT_MOD                      = -newindex(1)      -- FIELD MODIFIER
    FLD_STRUCT_KEYTYPE                  = -newindex()       -- FIELD DICT  KEY TYPE
    FLD_STRUCT_VALTYPE                  = -newindex()       -- FIELD DICT  VAL TYPE
    FLD_STRUCT_KEYVALID                 = -newindex()       -- FIELD DICT  KEY VALIDATOR
    FLD_STRUCT_VALVALID                 = -newindex()       -- FIELD IDCT  VAL VALIDATOR
    FLD_STRUCT_TYPEMETHOD               = -newindex()       -- FIELD OBJECT METHODS
    FLD_STRUCT_DEFAULT                  = -newindex()       -- FEILD DEFAULT
    FLD_STRUCT_BASE                     = -newindex()       -- FIELD BASE STRUCT
    FLD_STRUCT_VALID                    = -newindex()       -- FIELD VALIDATOR
    FLD_STRUCT_CTOR                     = -newindex()       -- FIELD CONSTRUCTOR
    FLD_STRUCT_NAME                     = -newindex()       -- FEILD STRUCT NAME
    FLD_STRUCT_ERRMSG                   = -newindex()       -- FIELD ERROR MESSAGE
    FLD_STRUCT_VALIDCACHE               = -newindex()       -- FIELD VALIDATOR CACHE
    FLD_STRUCT_TEMPPRM                  = -newindex()       -- FIELD TEMPLATE PARAMS
    FLD_STRUCT_TEMPDEF                  = -newindex()       -- FIELD TEMPLATE DEFINITION
    FLD_STRUCT_TEMPIMP                  = -newindex()       -- FIELD TEMPLATE IMPLEMENTATION
    FLD_STRUCT_TEMPENV                  = -newindex()       -- FIELD TEMPLATE ENVIRONMENT
    FLD_STRUCT_MAINTYPE                 = -newindex()       -- FIELD MAIN TYPE
    FLD_STRUCT_COMBTYPE1                = -newindex()       -- FIELD COMBO TYPE
    FLD_STRUCT_COMBTYPE2                = -newindex()       -- FIELD COMBO TYPE

    FLD_STRUCT_ARRAY                    =  0                -- FIELD ARRAY ELEMENT
    FLD_STRUCT_MEMBERSTART              =  1                -- FIELD START INDEX OF MEMBER
    FLD_STRUCT_ARRVALID                 =  2                -- FIELD ARRAY ELEMENT VALIDATOR
    FLD_STRUCT_VALIDSTART               =  10000            -- FIELD START INDEX OF VALIDATOR
    FLD_STRUCT_INITSTART                =  20000            -- FIELD START INDEX OF INITIALIZE

    -- MEMBER FIELD INDEX
    FLD_MEMBER_REQUIRE                  =  newindex(0)      -- MEMBER FIELD REQUIRED
    FLD_MEMBER_OBJ                      =  newindex()       -- MEMBER FIELD OBJECT
    FLD_MEMBER_NAME                     =  newindex()       -- MEMBER FIELD NAME
    FLD_MEMBER_TYPE                     =  newindex()       -- MEMBER FIELD TYPE
    FLD_MEMBER_VALID                    =  newindex()       -- MEMBER FIELD TYPE VALIDATOR
    FLD_MEMBER_DEFAULT                  =  newindex()       -- MEMBER FIELD DEFAULT
    FLD_MEMBER_DEFTFACTORY              =  newindex()       -- MEMBER FIELD AS DEFAULT FACTORY

    -- TYPE FLAGS
    FLG_CUSTOM_STRUCT                   = newflags(true)    -- CUSTOM STRUCT FLAG
    FLG_MEMBER_STRUCT                   = newflags()        -- MEMBER STRUCT FLAG
    FLG_ARRAY_STRUCT                    = newflags()        -- ARRAY  STRUCT FLAG
    FLG_DICT_STRUCT                     = newflags()        -- DICT   STRUCT FLAG
    FLG_STRUCT_SINGLE_VLD               = newflags()        -- SINGLE VALID  FLAG
    FLG_STRUCT_MULTI_VLD                = newflags()        -- MULTI  VALID  FLAG
    FLG_STRUCT_SINGLE_INIT              = newflags()        -- SINGLE INIT   FLAG
    FLG_STRUCT_MULTI_INIT               = newflags()        -- MULTI  INIT   FLAG
    FLG_STRUCT_OBJ_METHOD               = newflags()        -- OBJECT METHOD FLAG
    FLG_STRUCT_VALIDCACHE               = newflags()        -- VALID  CACHE  FLAG
    FLG_STRUCT_MULTI_REQ                = newflags()        -- MULTI  FIELD  REQUIRE FLAG
    FLG_STRUCT_FIRST_TYPE               = newflags()        -- FIRST  MEMBER TYPE    FLAG
    FLG_STRUCT_IMMUTABLE                = newflags()        -- IMMUTABLE     FLAG
    FLG_STRUCT_ALLOW_OBJ                = newflags()        -- ALLOW  OBjECT FLAG
    FLG_STRUCT_VALID_KEY                = newflags()        -- KEY    VALID  FLAG
    FLG_STRUCT_VALID_VAL                = newflags()        -- VALUE  VALID  FLAG
    FLG_STRUCT_IMTBL_KEY                = newflags()        -- IMMUTBL KEY   LFAG

    STRUCT_KEYWORD_ARRAY                = "__array"
    STRUCT_KEYWORD_BASE                 = "__base"
    STRUCT_KEYWORD_DFLT                 = "__default"
    STRUCT_KEYWORD_INIT                 = "__init"
    STRUCT_KEYWORD_VALD                 = "__valid"
    STRUCT_KEYWORD_KEY                  = "__key"
    STRUCT_KEYWORD_VAL                  = "__value"

    -- UNSAFE MODE FIELDS
    FLD_STRUCT_META                     = "__PLOOP_STRUCT_META"
    FLD_MEMBER_META                     = "__PLOOP_STRUCT_MEMBER_META"

    -----------------------------------------------------------------------
    --                          private storage                          --
    -----------------------------------------------------------------------
    local _StructInfo                   = PLOOP_PLATFORM_SETTINGS.UNSAFE_MODE
                                            and setmetatable({}, { __index = function(_, s) return type(s) == "table" and rawget(s, FLD_STRUCT_META) or nil end})
                                            or  newstorage(WEAK_KEY)
    local _MemberInfo                   = PLOOP_PLATFORM_SETTINGS.UNSAFE_MODE
                                            and setmetatable({}, { __index = function(_, s) return type(s) == "table" and rawget(s, FLD_MEMBER_META) or nil end})
                                            or  newstorage(WEAK_KEY)
    local _DependenceMap                = newstorage(WEAK_KEY)

    -- TYPE BUILDING
    local _StructBuilderInfo            = newstorage(WEAK_KEY)
    local _StructBuilderInDefine        = newstorage(WEAK_KEY)

    local _StructValidMap               = {}
    local _StructCtorMap                = {}

    -- Temp
    local _MemberAccessOwner
    local _MemberAccessName

    local _ValidTypeCombine             = newstorage(WEAK_KEY)
    local _UnmSubTypeMap                = newstorage(WEAK_ALL)
    local _AnonyArrayType               = newstorage(WEAK_ALL)
    local _AnonyHashType                = newstorage(WEAK_ALL)

    -----------------------------------------------------------------------
    --                          private helpers                          --
    -----------------------------------------------------------------------
    local getStructTargetInfo           = function (target)
        local info                      = _StructBuilderInfo[target]
        if info then return info, true else return _StructInfo[target], false end
    end

    local tryConvertToStruct, tryConvertToMember

    tryConvertToStruct                  = function(table)
        local temp                      = _Cache()

        for key, value in pairs, table do
            local tkey                  = type(key)
            local tval                  = type(value)

            temp[key]                   = value

            if tkey == "string" and not tonumber(key) then
                if key == STRUCT_KEYWORD_DFLT then
                    -- Pass
                elseif tval == "function" then
                    -- No method allowed
                    if key ~= STRUCT_KEYWORD_INIT and key ~= STRUCT_KEYWORD_VALD then
                        _Cache(temp)
                        return
                    end
                elseif getprototypemethod(value, "ValidateValue") then
                    -- Pass
                elseif tval == "table" then
                    -- Check if the value can be convert to a struct type
                    local tval
                    if key == STRUCT_KEYWORD_ARRAY  then
                        tval            = tryConvertToStruct(value)
                    else
                        tval            = tryConvertToMember(value, key)
                    end
                    if not tval then    _Cache(temp) return end
                    temp[key]           = tval
                else
                    _Cache(temp)
                    return
                end
            elseif tkey == "number" then
                if tval == "table" and getmetatable(value) == nil then
                    local vtype         = tryConvertToMember(value)
                    if not vtype then   _Cache(temp) return end
                    temp[key]           = vtype
                end
            elseif getprototypemethod(key,   "ValidateValue") then
                if getprototypemethod(value, "ValidateValue") then
                    -- pass
                elseif tval == "table" then
                    local vtype         = tryConvertToStruct(value)
                    if not vtype then   _Cache(temp) return end
                    temp[key]           = vtype
                else
                    _Cache(temp)
                    return
                end
            else
                _Cache(temp)
                return
            end
        end

        local ok, structType            = attribute.IndependentCall(function(temp) local type = struct(temp) return type end, temp)
        _Cache(temp)

        return ok and structType or nil
    end

    tryConvertToMember                  = function (table, name)
        local typeKey, nameKey

        -- Check fields
        for key, value in pairs, table do
            if type(key) == "string" then

                local lkey              = strlower(key)

                if lkey == "type" then
                    typeKey             = key
                elseif lkey == "name" and type(value) == "string" then
                    nameKey             = key
                end
            end
        end

        if typeKey and (name or nameKey) then
            local value                 = table[typeKey]
            -- Check the type value
            if getprototypemethod(value, "ValidateValue") then
                -- Use the table directly
                return table
            elseif type(value) == "table" then
                local vtype             = tryConvertToStruct(value)
                if vtype then
                    table[typeKey]      = vtype
                    return table
                end
            end
        end

        return tryConvertToStruct(table)
    end

    local setStructBuilderValue         = function (self, key, value, stack, notenvset)
        local owner                     = environment.GetNamespace(self)
        if not (owner and _StructBuilderInDefine[self]) then return end

        local tkey                      = type(key)
        local tval                      = type(value)

        stack                           = stack + 1

        -- Add to struct feature
        if tkey == "string" and not tonumber(key) then
            if key == STRUCT_KEYWORD_DFLT then
                struct.SetDefault(owner, value, stack)
                return true
            elseif tval == "function" then
                if key == STRUCT_KEYWORD_INIT then
                    struct.SetInitializer(owner, value, stack)
                    return true
                elseif key == STRUCT_KEYWORD_VALD or key == namespace.GetNamespaceName(owner, true) then
                    struct.SetValidator(owner, value, stack)
                    return true
                else
                    struct.AddMethod(owner, key, value, stack)
                    return true
                end
            elseif getprototypemethod(value, "ValidateValue") then
                if key == STRUCT_KEYWORD_ARRAY then
                    struct.SetArrayElement(owner, value, stack)
                    return true
                elseif key == STRUCT_KEYWORD_BASE then
                    struct.SetBaseStruct(owner, value, stack)
                elseif key == STRUCT_KEYWORD_KEY then
                    struct.SetDictionaryKey(owner, value, stack)
                elseif key == STRUCT_KEYWORD_VAL then
                    struct.SetDictionaryValue(owner, value, stack)
                else
                    struct.AddMember(owner, key, { type = value }, stack)
                end
                return true
            elseif tval == "table" and notenvset then
                -- Check if the value can be convert to a struct type
                if key == STRUCT_KEYWORD_ARRAY then
                    local vtype         = tryConvertToStruct(value)
                    if vtype then
                        struct.SetArrayElement(owner, vtype, stack)
                        return true
                    end
                end

                local vtype             = tryConvertToMember(value, key)
                struct.AddMember(owner, key, vtype and getmetatable(vtype) == nil and vtype or { type = vtype } or value, stack)
                return true
            end
        elseif tkey == "number" then
            if tval == "function" then
                struct.SetValidator(owner, value, stack)
                return true
            elseif getprototypemethod(value, "ValidateValue") then
                struct.SetArrayElement(owner, value, stack)
                return true
            elseif tval == "table" then
                local vtype             = tryConvertToMember(value)

                if vtype and getprototypemethod(vtype, "ValidateValue") then
                    struct.SetArrayElement(owner, vtype, stack)
                else
                    struct.AddMember(owner, vtype or value, stack)
                end

                return true
            else
                struct.SetDefault(owner, value, stack)
                return true
            end
        elseif getprototypemethod(key, "ValidateValue") then
            if not getprototypemethod(value, "ValidateValue") then
                if tval == "table" then
                    value               = tryConvertToStruct(value)
                    if not value then return false end
                else
                    return false
                end
            end

            struct.SetDictionaryKey(owner, key, stack)
            struct.SetDictionaryValue(owner, value, stack)
            return true
        end
    end

    -- Check struct inner states
    local chkStructContent
        chkStructContent                = function (target, filter, cache)
        local info                      = getStructTargetInfo(target)
        cache[target]                   = true
        if not info then return end

        if info[FLD_STRUCT_ARRAY] then
            local array                 = info[FLD_STRUCT_ARRAY]
            return not cache[array] and struct.Validate(array) and (filter(array) or chkStructContent(array, filter, cache))
        elseif info[FLD_STRUCT_MEMBERSTART] then
            for _, m in ipairs, info, FLD_STRUCT_MEMBERSTART - 1 do
                m                       = m[FLD_MEMBER_TYPE]
                if not cache[m] and struct.Validate(m) and (filter(m) or chkStructContent(m, filter, cache)) then
                    return true
                end
            end
        else
            if info[FLD_STRUCT_KEYTYPE] then
                local key               = info[FLD_STRUCT_KEYTYPE]
                if not cache[key] and struct.Validate(key) and (filter(key) or chkStructContent(key, filter, cache)) then
                    return true
                end
            end
            if info[FLD_STRUCT_VALTYPE] then
                local val               = info[FLD_STRUCT_VALTYPE]
                if not cache[val] and struct.Validate(val) and (filter(val) or chkStructContent(val, filter, cache)) then
                    return true
                end
            end
        end
    end

    local chkStructContents             = function (target, filter, incself)
        local cache                     = _Cache()
        if incself and filter(target) then return true end
        local ret                       = chkStructContent(target, filter, cache)
        _Cache(cache)
        return ret
    end

    local isNotSealedStruct             = function (target)
        local info, def                 = getStructTargetInfo(target)
        return info and (def or not validateflags(MOD_SEALED_STRUCT, info[FLD_STRUCT_MOD]))
    end

    local checkStructDependence         = function (target, chkType)
        if chkType and target ~= chkType then
            if chkStructContents(chkType, isNotSealedStruct, true) then
                _DependenceMap[chkType]         = _DependenceMap[chkType] or newstorage(WEAK_KEY)
                _DependenceMap[chkType][target] = true
            elseif chkType and _DependenceMap[chkType] then
                _DependenceMap[chkType][target] = nil
                if not next(_DependenceMap[chkType]) then _DependenceMap[chkType] = nil end
            end
        end
    end

    local updateStructDependence        = function (target, info)
        info                            = info or getStructTargetInfo(target)

        if info[FLD_STRUCT_ARRAY] then
            checkStructDependence(target, info[FLD_STRUCT_ARRAY])
        elseif info[FLD_STRUCT_MEMBERSTART] then
            for _, m in ipairs, info, FLD_STRUCT_MEMBERSTART - 1 do
                checkStructDependence(target, m[FLD_MEMBER_TYPE])
            end
        else
            if info[FLD_STRUCT_KEYTYPE] then
                checkStructDependence(target, info[FLD_STRUCT_KEYTYPE])
            end
            if info[FLD_STRUCT_VALTYPE] then
                checkStructDependence(target, info[FLD_STRUCT_VALTYPE])
            end
        end
    end

    -- Immutable
    local checkStructImmutable          = function (info)
        if info[FLD_STRUCT_INITSTART]   then return false end
        if info[FLD_STRUCT_TYPEMETHOD]  then for k, v in pairs, info[FLD_STRUCT_TYPEMETHOD] do if v then return false end end end

        local arrtype                   = info[FLD_STRUCT_ARRAY]
        if arrtype then
            return getobjectvalue(arrtype, "IsImmutable") or false
        elseif info[FLD_STRUCT_MEMBERSTART] then
            for _, m in ipairs, info, FLD_STRUCT_MEMBERSTART - 1 do
                if not getobjectvalue(m[FLD_MEMBER_TYPE], "IsImmutable") then return false end
            end
        else
            if info[FLD_STRUCT_KEYTYPE] and not getobjectvalue(info[FLD_STRUCT_KEYTYPE], "IsImmutable") then return false end
            if info[FLD_STRUCT_VALTYPE] and not getobjectvalue(info[FLD_STRUCT_VALTYPE], "IsImmutable") then return false end
        end
        return true
    end

    local updateStructImmutable         = function (target, info)
        info = info or getStructTargetInfo(target)
        if checkStructImmutable(info) then
            info[FLD_STRUCT_MOD]        = turnonflags(MOD_IMMUTABLE_STRUCT, info[FLD_STRUCT_MOD])
        else
            info[FLD_STRUCT_MOD]        = turnoffflags(MOD_IMMUTABLE_STRUCT, info[FLD_STRUCT_MOD])
        end
    end

    -- Cache required
    local checkRepeatStructType         = function (target, info)
        if info then
            local filter                = function(chkType) return chkType == target end

            if info[FLD_STRUCT_ARRAY] then
                local array             = info[FLD_STRUCT_ARRAY]
                return array == target or (struct.Validate(array) and chkStructContents(array, filter))
            elseif info[FLD_STRUCT_MEMBERSTART] then
                for _, m in ipairs, info, FLD_STRUCT_MEMBERSTART - 1 do
                    m                   = m[FLD_MEMBER_TYPE]
                    if m == target or (struct.Validate(m) and chkStructContents(m, filter)) then
                        return true
                    end
                end
            else
                local key               = info[FLD_STRUCT_KEYTYPE]
                if key and key == target or (struct.Validate(key) and chkStructContents(key, filter)) then return true end
                local val               = info[FLD_STRUCT_VALTYPE]
                if val and val == target or (struct.Validate(val) and chkStructContents(val, filter)) then return true end
            end
        end

        return false
    end

    -- Validator
    local genStructValidator            = function (info)
        local token                     = 0
        local upval                     = _Cache()

        if info[FLD_STRUCT_VALIDCACHE] then
            token                       = turnonflags(FLG_STRUCT_VALIDCACHE, token)
        end

        if info[FLD_STRUCT_MEMBERSTART] then
            token                       = turnonflags(FLG_MEMBER_STRUCT, token)
            local i                     = FLD_STRUCT_MEMBERSTART
            while info[i + 1] do i = i + 1 end
            tinsert(upval, i)

            if validateflags(MOD_ALLOWOBJ_STRUCT, info[FLD_STRUCT_MOD]) then
                token                   = turnonflags(FLG_STRUCT_ALLOW_OBJ, token)
            end
        elseif info[FLD_STRUCT_ARRAY] then
            token                       = turnonflags(FLG_ARRAY_STRUCT, token)
            token                       = turnonflags(FLG_STRUCT_ALLOW_OBJ, token) -- Always allow the object as array
        elseif info[FLD_STRUCT_KEYTYPE] or info[FLD_STRUCT_VALTYPE] then
            token                       = turnonflags(FLG_DICT_STRUCT, token)
            token                       = turnonflags(FLG_STRUCT_ALLOW_OBJ, token) -- Always allow the object as dict

            if info[FLD_STRUCT_KEYTYPE] then
                token                   = turnonflags(FLG_STRUCT_VALID_KEY, token)

                if getobjectvalue(info[FLD_STRUCT_KEYTYPE], "IsImmutable") then
                    token               = turnonflags(FLG_STRUCT_IMTBL_KEY, token)
                end
            end

            if info[FLD_STRUCT_VALTYPE] then
                token                   = turnonflags(FLG_STRUCT_VALID_VAL, token)
            end
        else
            token                       = turnonflags(FLG_CUSTOM_STRUCT, token)
        end

        if info[FLD_STRUCT_VALIDSTART] then
            if info[FLD_STRUCT_VALIDSTART + 1] then
                local i                 = FLD_STRUCT_VALIDSTART + 2
                while info[i] do i = i + 1 end
                token                   = turnonflags(FLG_STRUCT_MULTI_VLD, token)
                tinsert(upval, i - 1)
            else
                token                   = turnonflags(FLG_STRUCT_SINGLE_VLD, token)
                tinsert(upval, info[FLD_STRUCT_VALIDSTART])
            end
        end

        if info[FLD_STRUCT_INITSTART] then
            if info[FLD_STRUCT_INITSTART + 1] then
                local i                 = FLD_STRUCT_INITSTART + 2
                while info[i] do i      = i + 1 end
                token                   = turnonflags(FLG_STRUCT_MULTI_INIT, token)
                tinsert(upval, i - 1)
            else
                token                   = turnonflags(FLG_STRUCT_SINGLE_INIT, token)
                tinsert(upval, info[FLD_STRUCT_INITSTART])
            end
        end

        if info[FLD_STRUCT_TYPEMETHOD] then
            for k, v in pairs, info[FLD_STRUCT_TYPEMETHOD] do
                if v then
                    token               = turnonflags(FLG_STRUCT_OBJ_METHOD, token)
                    break
                end
            end
        end

        -- Build the validator generator
        if not _StructValidMap[token] then
            local head                  = _Cache()
            local body                  = _Cache()
            local apis                  = _Cache()

            tinsert(body, "")                       -- remain for shareable variables
            tinsert(body, "return function(%s)")    -- remain for special variables
            tinsert(body, [[return function(info, value, onlyValid, cache)]])

            if validateflags(FLG_MEMBER_STRUCT, token) or validateflags(FLG_ARRAY_STRUCT, token) or validateflags(FLG_DICT_STRUCT, token) then
                uinsert(apis, "strformat")
                uinsert(apis, "type")
                uinsert(apis, "strgsub")
                uinsert(apis, "tostring")

                tinsert(body, [[
                    if type(value) ~= "table" then return nil, onlyValid or "the %s must be a table" end
                ]])

                if not validateflags(FLG_STRUCT_ALLOW_OBJ, token) then
                    uinsert(apis, "getmetatable")
                    tinsert(body, [[
                        if getmetatable(value) ~= nil then return nil, onlyValid or "the %s must be raw table without meta-table" end
                    ]])
                end

                if validateflags(FLG_STRUCT_VALIDCACHE, token) then
                    uinsert(apis, "_Cache")
                    tinsert(body, [[
                        -- Cache to block recursive validation
                        local vcache    = cache[info]
                        if not vcache then
                            vcache      = _Cache()
                            cache[info] = vcache
                        elseif vcache[value] then
                            return value
                        end
                        vcache[value]   = true
                    ]])
                end
            end

            if validateflags(FLG_MEMBER_STRUCT, token) then
                uinsert(apis, "clone")

                tinsert(head, "count")
                tinsert(body, [[
                    if onlyValid then
                        for i = ]] .. FLD_STRUCT_MEMBERSTART .. [[, count do
                            local mem   = info[i]
                            local name  = mem[]] .. FLD_MEMBER_NAME .. [[]
                            local vtype = mem[]] .. FLD_MEMBER_TYPE ..[[]
                            local val   = value[name]
                            local msg

                            if val == nil then
                                if mem[]] .. FLD_MEMBER_REQUIRE .. [[] then
                                    return nil, true
                                end
                            elseif vtype then
                                val, msg= mem[]] .. FLD_MEMBER_VALID .. [[](vtype, val, true, cache)
                                if msg then return nil, true end
                            end
                        end
                    else
                        for i = ]] .. FLD_STRUCT_MEMBERSTART .. [[, count do
                            local mem   = info[i]
                            local name  = mem[]] .. FLD_MEMBER_NAME .. [[]
                            local vtype = mem[]] .. FLD_MEMBER_TYPE ..[[]
                            local val   = value[name]
                            local msg

                            if val == nil then
                                if mem[]] .. FLD_MEMBER_REQUIRE .. [[] then
                                    return nil, strformat("the %s.%s can't be nil", "%s", name)
                                end

                                if mem[]] .. FLD_MEMBER_DEFTFACTORY .. [[] then
                                    val = mem[]] .. FLD_MEMBER_DEFAULT .. [[](value)
                                else
                                    val = clone(mem[]] .. FLD_MEMBER_DEFAULT .. [[], true)
                                end
                            elseif vtype then
                                val, msg= mem[]] .. FLD_MEMBER_VALID .. [[](vtype, val, false, cache)
                                if msg then return nil, type(msg) == "string" and strgsub(msg, "%%s", "%%s" .. "." .. name) or strformat("the %s.%s must be [%s]", "%s", name, tostring(vtype)) end
                            end

                            value[name] = val
                        end
                    end
                ]])
            elseif validateflags(FLG_ARRAY_STRUCT, token) then
                uinsert(apis, "ipairs")

                tinsert(body, [[
                    local array         = info[]] .. FLD_STRUCT_ARRAY .. [[]
                    local avalid        = info[]] .. FLD_STRUCT_ARRVALID .. [[]
                    if onlyValid then
                        for i, v in ipairs, value, 0 do
                            local ret, msg  = avalid(array, v, true, cache)
                            if msg then return nil, true end
                        end
                    else
                        for i, v in ipairs, value, 0 do
                            local ret, msg = avalid(array, v, false, cache)
                            if msg then return nil, type(msg) == "string" and strgsub(msg, "%%s", "%%s[" .. i .. "]") or strformat("the %s[%s] must be [%s]", "%s", i, tostring(array)) end
                            value[i]    = ret
                        end
                    end
                ]])
            elseif validateflags(FLG_DICT_STRUCT, token) then
                uinsert(apis, "pairs")

                if validateflags(FLG_STRUCT_VALID_KEY, token) then
                    tinsert(body, [[
                        local ktype     = info[]] .. FLD_STRUCT_KEYTYPE .. [[]
                        local kvald     = info[]] .. FLD_STRUCT_KEYVALID.. [[]
                    ]])
                end

                if validateflags(FLG_STRUCT_VALID_VAL, token) then
                    tinsert(body, [[
                        local vtype     = info[]] .. FLD_STRUCT_VALTYPE .. [[]
                        local vvald     = info[]] .. FLD_STRUCT_VALVALID.. [[]
                    ]])
                end

                tinsert(body, [[
                    local ret, msg
                    if onlyValid then
                        for k, v in pairs, value do
                ]])

                if validateflags(FLG_STRUCT_VALID_KEY, token) then
                    tinsert(body, [[
                        ret, msg        = kvald(ktype, k, true, cache)
                        if msg then return nil, true end
                    ]])
                end

                if validateflags(FLG_STRUCT_VALID_VAL, token) then
                    tinsert(body, [[
                        ret, msg        = vvald(vtype, v, true, cache)
                        if msg then return nil, true end
                    ]])
                end

                tinsert(body, [[
                        end
                    else
                ]])

                if validateflags(FLG_STRUCT_VALID_KEY, token) and not validateflags(FLG_STRUCT_IMTBL_KEY, token) then
                    uinsert(apis, "_Cache")
                    tinsert(body, [[
                        local nkeymap   = _Cache()
                    ]])
                end

                tinsert(body, [[
                        for k, v in pairs, value do
                ]])

                if validateflags(FLG_STRUCT_VALID_KEY, token) then
                    tinsert(body, [[
                        ret, msg        = kvald(ktype, k, false, cache)
                        if msg then return nil, type(msg) == "string" and strgsub(msg, "%%s", "[key in %%s]") or strformat("the [key in %s] must be [%s]", "%s", tostring(ktype)) end
                    ]])

                    if not validateflags(FLG_STRUCT_IMTBL_KEY, token) then
                        tinsert(body, [[
                            if k ~= ret then nkeymap[k] = ret end
                        ]])
                    end
                end

                if validateflags(FLG_STRUCT_VALID_VAL, token) then
                    tinsert(body, [[
                        ret, msg        = vvald(vtype, v, false, cache)
                        if msg then return nil, type(msg) == "string" and strgsub(msg, "%%s", "[value in %%s]") or strformat("the [value in %s] must be [%s]", "%s", tostring(vtype)) end
                        value[k] = ret
                    ]])
                end

                if validateflags(FLG_STRUCT_VALID_KEY, token) and not validateflags(FLG_STRUCT_IMTBL_KEY, token) then
                    tinsert(body, [[
                        for k, nk in pairs, nkeymap do
                            local v     = value[k]
                            value[k]    = nil
                            value[nk]   = v
                        end
                        _Cache(nkeymap)
                    ]])
                end

                tinsert(body, [[
                        end
                    end
                ]])
            end

            if validateflags(FLG_STRUCT_SINGLE_VLD, token) or validateflags(FLG_STRUCT_MULTI_VLD, token) then
                uinsert(apis, "type")
                uinsert(apis, "strformat")

                if validateflags(FLG_STRUCT_SINGLE_VLD, token) then
                    tinsert(head, "svalid")
                    tinsert(body, [[
                        local msg       = svalid(value, onlyValid)
                        if msg then return nil, onlyValid or type(msg) == "string" and msg or strformat("the %s must be [%s]", "%s", info[]] .. FLD_STRUCT_NAME .. [[]) end
                    ]])
                elseif validateflags(FLG_STRUCT_MULTI_VLD, token) then
                    tinsert(head, "mvalid")
                    tinsert(body, [[
                        for i = ]] .. FLD_STRUCT_VALIDSTART .. [[, mvalid do
                            local msg   = info[i](value, onlyValid)
                            if msg then return nil, onlyValid or type(msg) == "string" and msg or strformat("the %s must be [%s]", "%s", info[]] .. FLD_STRUCT_NAME .. [[]) end
                        end
                    ]])
                end
            end

            if validateflags(FLG_STRUCT_SINGLE_INIT, token) or validateflags(FLG_STRUCT_MULTI_INIT, token) or validateflags(FLG_STRUCT_OBJ_METHOD, token) then
                tinsert(body, [[if onlyValid then return value end]])
            end

            if validateflags(FLG_STRUCT_SINGLE_INIT, token) or validateflags(FLG_STRUCT_MULTI_INIT, token) then
                if validateflags(FLG_STRUCT_SINGLE_INIT, token) then
                    tinsert(head, "sinit")
                    tinsert(body, [[
                        local ret       = sinit(value)
                    ]])

                    if validateflags(FLG_CUSTOM_STRUCT, token) then
                        tinsert(body, [[if ret ~= nil then value = ret end]])
                    end
                else
                    tinsert(head, "minit")
                    tinsert(body, [[
                        for i = ]] .. FLD_STRUCT_INITSTART .. [[, minit do
                            local ret   = info[i](value)
                        ]])
                    if validateflags(FLG_CUSTOM_STRUCT, token) then
                        tinsert(body, [[if ret ~= nil then value = ret end]])
                    end
                    tinsert(body, [[end]])
                end
            end

            if validateflags(FLG_STRUCT_OBJ_METHOD, token) then
                if validateflags(FLG_CUSTOM_STRUCT, token) then
                    uinsert(apis, "type")
                    tinsert(body, [[if type(value) == "table" then]])
                end
                uinsert(apis, "pairs")
                tinsert(body, [[
                    for k, v in pairs, info[]] .. FLD_STRUCT_TYPEMETHOD .. [[] do
                        if v and value[k] == nil then value[k] = v end
                    end
                ]])

                if validateflags(FLG_CUSTOM_STRUCT, token) then
                    tinsert(body, [[end]])
                end
            end

            tinsert(body, [[
                    return value
                end
            ]])

            tinsert(body, [[end]])

            if #apis > 0 then
                local declare           = tblconcat(apis, ", ")
                body[1]                 = strformat("local %s = %s", declare, declare)
            end

            body[2]                     = strformat(body[2], #head > 0 and tblconcat(head, ", ") or "")

            _StructValidMap[token]      = loadsnippet(tblconcat(body, "\n"), "Struct_Validate_" .. token, _PLoopEnv)()

            if #head == 0 then
                _StructValidMap[token]  = _StructValidMap[token]()
            end

            _Cache(head)
            _Cache(body)
            _Cache(apis)
        end

        if #upval > 0 then
            info[FLD_STRUCT_VALID]      = _StructValidMap[token](unpack(upval))
        else
            info[FLD_STRUCT_VALID]      = _StructValidMap[token]
        end

        _Cache(upval)
    end

    -- Ctor
    local genStructConstructor          = function (info)
        local token                     = 0
        local upval                     = _Cache()

        if info[FLD_STRUCT_VALIDCACHE] then
            token                       = turnonflags(FLG_STRUCT_VALIDCACHE, token)
        end

        if info[FLD_STRUCT_MEMBERSTART] then
            token                       = turnonflags(FLG_MEMBER_STRUCT, token)
            local i                     = FLD_STRUCT_MEMBERSTART + 1
            local r                     = false
            while info[i] do
                if not r and info[i][FLD_MEMBER_REQUIRE] then r = true end
                i                       = i + 1
            end
            tinsert(upval, i - 1)
            if r then
                token                   = turnonflags(FLG_STRUCT_MULTI_REQ, token)
            else
                local ftype             = info[FLD_STRUCT_MEMBERSTART][FLD_MEMBER_TYPE]
                if ftype then
                    token               = turnonflags(FLG_STRUCT_FIRST_TYPE, token)
                    tinsert(upval, ftype)
                    tinsert(upval, info[FLD_STRUCT_MEMBERSTART][FLD_MEMBER_VALID])
                    tinsert(upval, getobjectvalue(ftype, "IsImmutable") or false)
                end
            end

            if validateflags(MOD_ALLOWOBJ_STRUCT, info[FLD_STRUCT_MOD]) then
                token                   = turnonflags(FLG_STRUCT_ALLOW_OBJ, token)
            end
        elseif info[FLD_STRUCT_ARRAY] then
            token                       = turnonflags(FLG_ARRAY_STRUCT, token)
            token                       = turnonflags(FLG_STRUCT_ALLOW_OBJ, token)
        elseif info[FLD_STRUCT_KEYTYPE] or info[FLD_STRUCT_VALTYPE] then
            token                       = turnonflags(FLG_DICT_STRUCT, token)
            token                       = turnonflags(FLG_STRUCT_ALLOW_OBJ, token)
        else
            token                       = turnonflags(FLG_CUSTOM_STRUCT, token)
        end

        if validateflags(MOD_IMMUTABLE_STRUCT, info[FLD_STRUCT_MOD]) then
            token                       = turnonflags(FLG_STRUCT_IMMUTABLE, token)
        end

        -- Build the validator generator
        if not _StructCtorMap[token] then
            local head                  = _Cache()
            local body                  = _Cache()
            local apis                  = _Cache()

            tinsert(body, "")                       -- remain for shareable variables
            tinsert(body, "return function(%s)")    -- remain for special variables

            uinsert(apis, "error")
            uinsert(apis, "strgsub")

            if validateflags(FLG_MEMBER_STRUCT, token) then
                uinsert(apis, "select")
                uinsert(apis, "type")

                tinsert(body, [[
                    return function(info, first, ...)
                        local ivalid    = info[]].. FLD_STRUCT_VALID .. [[]
                        local ret, msg
                ]])

                if validateflags(FLG_STRUCT_ALLOW_OBJ, token) then
                    tinsert(body, [[
                        if select("#", ...) == 0 and type(first) == "table" then
                    ]])
                else
                    uinsert(apis, "getmetatable")
                    tinsert(body, [[
                        if select("#", ...) == 0 and type(first) == "table" and getmetatable(first) == nil then
                    ]])
                end

                tinsert(head, "count")
                if not validateflags(FLG_STRUCT_MULTI_REQ, token) then
                    -- So, it may be the first member
                    if validateflags(FLG_STRUCT_FIRST_TYPE, token) then
                        tinsert(head, "ftype")
                        tinsert(head, "fvalid")
                        tinsert(head, "fimtbl")
                        tinsert(body, [[
                            local _, fmatch = fvalid(ftype, first, true) fmatch = not fmatch
                        ]])
                    else
                        tinsert(body, [[local fmatch, fimtbl = true, true]])
                    end
                else
                    tinsert(body, [[local fmatch, fimtbl = false, false]])
                end

                if validateflags(FLG_STRUCT_VALIDCACHE, token) then
                    tinsert(body, [[
                        local cache     = _Cache()
                        ret, msg        = ivalid(info, first, fmatch and not fimtbl, cache)
                        for k, v in pairs, cache do cache[k] = nil _Cache(v) end _Cache(cache)
                    ]])
                else
                    tinsert(body, [[ret, msg = ivalid(info, first, fmatch and not fimtbl)]])
                end

                tinsert(body, [[if not msg then]])

                if not validateflags(FLG_STRUCT_IMMUTABLE, token) then
                    tinsert(body, [[if fmatch and not fimtbl then]])

                    if validateflags(FLG_STRUCT_VALIDCACHE, token) then
                        tinsert(body, [[
                            local cache = _Cache()
                            ret, msg    = ivalid(info, first, false, cache)
                            for k, v in pairs, cache do cache[k] = nil _Cache(v) end _Cache(cache)
                        ]])
                    else
                        tinsert(body, [[ret, msg = ivalid(info, first, false)]])
                    end

                    tinsert(body, [[end]])
                end

                tinsert(body, [[
                            return ret
                        elseif not fmatch then
                            error(info[]] .. FLD_STRUCT_ERRMSG .. [[] .. (type(msg) == "string" and strgsub(msg, "%%s%.?", "") or "the value is not valid"), 3)
                        end
                    end
                ]])
            else
                tinsert(body, [[
                    return function(info, ret)
                        local ivalid    = info[]].. FLD_STRUCT_VALID .. [[]
                        local msg
                ]])
            end

            if validateflags(FLG_MEMBER_STRUCT, token) then
                tinsert(body, [[
                    ret                 = {}
                    local j             = 1
                    ret[ info[]] .. FLD_STRUCT_MEMBERSTART .. [[][]] .. FLD_MEMBER_NAME .. [[] ] = first
                    for i = ]] .. (FLD_STRUCT_MEMBERSTART + 1) .. [[, count do
                        ret[ info[i][]] .. FLD_MEMBER_NAME .. [[] ] = (select(j, ...))
                        j               = j + 1
                    end
                ]])
            end

            if validateflags(FLG_STRUCT_VALIDCACHE, token) then
                uinsert(apis, "_Cache")
                uinsert(apis, "pairs")
                tinsert(body, [[
                    local cache         = _Cache()
                    ret, msg            = ivalid(info, ret, false, cache)
                    for k, v in pairs, cache do cache[k] = nil _Cache(v) end _Cache(cache)
                ]])
            else
                tinsert(body, [[
                    ret, msg            = ivalid(info, ret, false)
                ]])
            end

            tinsert(body, [[if not msg then return ret end]])

            if validateflags(FLG_MEMBER_STRUCT, token) or validateflags(FLG_ARRAY_STRUCT, token) then
                uinsert(apis, "type")
                tinsert(body, [[
                    error(info[]] .. FLD_STRUCT_ERRMSG .. [[] .. (type(msg) == "string" and strgsub(msg, "%%s%.?", "") or "the value is not valid"), 3)
                ]])
            else
                tinsert(body, [[
                    error(strgsub(msg, "%%s", "value"), 3)
                ]])
            end

            tinsert(body, [[end]])
            tinsert(body, [[end]])

            if #apis > 0 then
                local declare           = tblconcat(apis, ", ")
                body[1]                 = strformat("local %s = %s", declare, declare)
            end

            body[2]                     = strformat(body[2], #head > 0 and tblconcat(head, ", ") or "")

            _StructCtorMap[token]       = loadsnippet(tblconcat(body, "\n"), "Struct_Ctor_" .. token, _PLoopEnv)()

            if #head == 0 then
                _StructCtorMap[token]   = _StructCtorMap[token]()
            end

            _Cache(head)
            _Cache(body)
            _Cache(apis)
        end

        if #upval > 0 then
            info[FLD_STRUCT_CTOR]       = _StructCtorMap[token](unpack(upval))
        else
            info[FLD_STRUCT_CTOR]       = _StructCtorMap[token]
        end

        _Cache(upval)
    end

    -- Refresh Depends
    local updateStructDepends
        updateStructDepends             = function (target, cache)
        local map                       = _DependenceMap[target]

        if map then
            _DependenceMap[target]      = nil

            for t in pairs, map do
                if not cache[t] then
                    cache[t]            = true

                    local info, def     = getStructTargetInfo(t)
                    if not def then
                        info[FLD_STRUCT_VALIDCACHE] = checkRepeatStructType(t, info)

                        updateStructDependence(t, info)
                        updateStructImmutable (t, info)

                        genStructValidator  (info)
                        genStructConstructor(info)

                        updateStructDepends (t, cache)

                        structdefined(t)
                    end
                end
            end

            _Cache(map)
        end
    end

    local initStructInfo                = function (target)
        return {
            [FLD_STRUCT_MOD ]           = 0,
            [FLD_STRUCT_NAME]           = tostring(target),
        }
    end

    -- Save Meta
    local saveStructMeta                = PLOOP_PLATFORM_SETTINGS.UNSAFE_MODE and function (s, meta) rawset(s, FLD_STRUCT_META, meta) end or function (s, meta) _StructInfo = savestorage(_StructInfo, s, meta) end
    local saveMemberMeta                = PLOOP_PLATFORM_SETTINGS.UNSAFE_MODE and function (m, meta) rawset(m, FLD_MEMBER_META, meta) end or function (m, meta) _MemberInfo = savestorage(_MemberInfo, m, meta) end

    -- Get template implementation
    local getStructImplement            = function(self, key, stack)
        local info                      = _StructInfo[self]
        if info[FLD_STRUCT_TEMPDEF] then
            local implements            = info[FLD_STRUCT_TEMPIMP]
            if type(key) ~= "table" or getmetatable(key) ~= nil then
                key                     = { key }
            end

            local implement             = getTemplateImplement(implements, key)
            if implement then return implement end

            local ok, err               = attribute.IndependentCall(function()
                implement               = struct {}
                local bder              = struct (info[FLD_STRUCT_TEMPENV], implement, true)
                struct.SetSealed(implement)
                local tmp               = getStructTargetInfo(implement)
                tmp[FLD_STRUCT_TEMPPRM] = key
                tmp[FLD_STRUCT_TEMPIMP] = self
                attribute.InheritAttributes(implement, ATTRTAR_STRUCT, self)
                bder(info[FLD_STRUCT_TEMPDEF])
            end)

            if not ok then
                if type(err) == "string" then
                    error(err, 0)
                else
                    error(tostring(err), parsestack(stack) + 1)
                end
            end

            info[FLD_STRUCT_TEMPIMP]    = saveTemplateImplement(implements, key, implement)

            return implement
        end

        error("the " .. tostring(self) .. " can't be used as template", parsestack(stack) + 1)
    end

    -----------------------------------------------------------------------
    --                             prototype                             --
    -----------------------------------------------------------------------
    struct                              = prototype {
        __tostring                      = "struct",
        __index                         = {
            --- Add a member to the structure
            -- @static
            -- @method  AddMember
            -- @owner   struct
            -- @format  (structure[, name], definition[, stack])
            -- @param   structure                   the structure
            -- @param   name                        the member's name
            -- @param   definition                  the member's definition like { type = [Value type], default = [value], require = [boolean], name = [string] }
            -- @param   stack                       the stack level
            ["AddMember"]               = function(target, name, definition, stack)
                local info, def         = getStructTargetInfo(target)

                if type(name)  == "table" then
                    definition, stack, name = name, definition, nil
                    for k, v in pairs, definition do
                        if type(k) == "string" and strlower(k) == "name" and type(v) == "string" and not tonumber(v) then
                            name, definition[k] = v, nil
                            break
                        end
                    end
                end
                stack                   = parsestack(stack) + 1

                if info then
                    if not def then error(strformat("Usage: struct.AddMember(structure[, name], definition[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                    if type(name) ~= "string" then error("Usage: struct.AddMember(structure[, name], definition[, stack]) - The name must be a string", stack) end
                    name                = strtrim(name)
                    if name == "" then error("Usage: struct.AddMember(structure[, name], definition[, stack]) - The name can't be empty", stack) end
                    if type(definition) ~= "table" then error("Usage: struct.AddMember(structure[, name], definition[, stack]) - The definition is missing", stack) end
                    if info[FLD_STRUCT_ARRAY] then error("Usage: struct.AddMember(structure[, name], definition[, stack]) - The structure is an array structure, can't add member", stack) end
                    if info[FLD_STRUCT_KEYTYPE] or info[FLD_STRUCT_VALTYPE] then error("Usage: struct.AddMember(structure[, name], definition[, stack]) - The structure is a dictionary structure, can't add member", stack) end

                    local idx           = FLD_STRUCT_MEMBERSTART
                    while info[idx] do
                        if info[idx][FLD_MEMBER_NAME] == name then
                            error(strformat("Usage: struct.AddMember(structure[, name], definition[, stack]) - There is an existed member with the name : %q", name), stack)
                        end
                        idx             = idx + 1
                    end

                    local mobj          = prototype.NewProxy(member)
                    local minfo         = _Cache()
                    saveMemberMeta(mobj, minfo)
                    minfo[FLD_MEMBER_OBJ]   = mobj
                    minfo[FLD_MEMBER_NAME]  = name

                    -- Save attributes
                    attribute.SaveAttributes(mobj, ATTRTAR_MEMBER, stack)

                    -- Inherit attributes
                    if info[FLD_STRUCT_BASE] then
                        local smem      = struct.GetMember(info[FLD_STRUCT_BASE], name)
                        if smem  then attribute.InheritAttributes(mobj, ATTRTAR_MEMBER, smem) end
                    end

                    -- Init the definition with attributes
                    definition          = attribute.InitDefinition(mobj, ATTRTAR_MEMBER, definition, target, name, stack)

                    -- Parse the definition
                    for k, v in pairs, definition do
                        if type(k) == "string" then
                            k           = strlower(k)

                            if k == "type" then
                                local tpValid = getprototypemethod(v, "ValidateValue")

                                if tpValid then
                                    minfo[FLD_MEMBER_TYPE]  = v
                                    minfo[FLD_MEMBER_VALID] = tpValid
                                else
                                    error("Usage: struct.AddMember(structure[, name], definition[, stack]) - The member's type is not valid", stack)
                                end
                            elseif k == "require" and v then
                                minfo[FLD_MEMBER_REQUIRE]   = true
                            elseif k == "default" then
                                minfo[FLD_MEMBER_DEFAULT]   = v
                            end
                        end
                    end

                    if minfo[FLD_MEMBER_REQUIRE] then
                        minfo[FLD_MEMBER_DEFAULT] = nil
                    elseif minfo[FLD_MEMBER_TYPE] then
                        if minfo[FLD_MEMBER_DEFAULT] ~= nil then
                            local ret, msg = minfo[FLD_MEMBER_VALID](minfo[FLD_MEMBER_TYPE], minfo[FLD_MEMBER_DEFAULT])
                            if not msg then
                                minfo[FLD_MEMBER_DEFAULT]       = ret
                            elseif type(minfo[FLD_MEMBER_DEFAULT]) == "function" then
                                minfo[FLD_MEMBER_DEFTFACTORY]   = true
                            else
                                error("Usage: struct.AddMember(structure[, name], definition[, stack]) - The default value is not valid", stack)
                            end
                        end
                        if minfo[FLD_MEMBER_DEFAULT] == nil then
                            minfo[FLD_MEMBER_DEFAULT] = getobjectvalue(minfo[FLD_MEMBER_TYPE], "GetDefault")
                        end
                    end

                    info[idx]           = minfo
                    attribute.ApplyAttributes (mobj, ATTRTAR_MEMBER, nil, target, name, stack)
                    attribute.AttachAttributes(mobj, ATTRTAR_MEMBER, target, name, stack)
                else
                    error("Usage: struct.AddMember(structure[, name], definition[, stack]) - The structure is not valid", stack)
                end
            end;

            --- Add an object method to the structure
            -- @static
            -- @method  AddMethod
            -- @owner   struct
            -- @format  (structure, name, func[, stack])
            -- @param   structure                   the structure
            -- @param   name                        the method'a name
            -- @param   func                        the method's definition
            -- @param   stack                       the stack level
            ["AddMethod"]               = function(target, name, func, stack)
                local info, def         = getStructTargetInfo(target)
                stack                   = parsestack(stack) + 1

                if info then
                    if not def then error(strformat("Usage: struct.AddMethod(structure, name, func[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                    if type(name) ~= "string" then error("Usage: struct.AddMethod(structure, name, func[, stack]) - The name must be a string", stack) end
                    name                = strtrim(name)
                    if name == "" then error("Usage: Usage: struct.AddMethod(structure, name, func[, stack]) - The name can't be empty", stack) end
                    if type(func) ~= "function" then error("Usage: struct.AddMethod(structure, name, func[, stack]) - The func must be a function", stack) end

                    attribute.SaveAttributes(func, ATTRTAR_METHOD, stack)

                    if info[FLD_STRUCT_BASE] and not info[name] then
                        local sfunc     = struct.GetMethod(info[FLD_STRUCT_BASE], name)
                        if sfunc then attribute.InheritAttributes(func, ATTRTAR_METHOD, sfunc) end
                    end

                    local ret           = attribute.InitDefinition(func, ATTRTAR_METHOD, func, target, name, stack)
                    if ret ~= func then attribute.ToggleTarget(func, ret) func = ret end

                    if info[FLD_STRUCT_TYPEMETHOD] and info[FLD_STRUCT_TYPEMETHOD][name] == false then
                        info[name]      = func
                    else
                        info[FLD_STRUCT_TYPEMETHOD]         = info[FLD_STRUCT_TYPEMETHOD] or {}
                        info[FLD_STRUCT_TYPEMETHOD][name]   = func
                    end

                    attribute.ApplyAttributes (func, ATTRTAR_METHOD, nil, target, name, stack)
                    attribute.AttachAttributes(func, ATTRTAR_METHOD, target, name, stack)
                else
                    error("Usage: struct.AddMethod(structure, name, func[, stack]) - The structure is not valid", stack)
                end
            end;

            --- Begin the structure's definition
            -- @static
            -- @method  BeginDefinition
            -- @owner   struct
            -- @format  (structure[, stack])
            -- @param   structure                   the structure
            -- @param   stack                       the stack level
            ["BeginDefinition"]         = function(target, stack)
                stack                   = parsestack(stack) + 1

                target                  = struct.Validate(target)
                if not target then error("Usage: struct.BeginDefinition(structure[, stack]) - The structure not existed", stack) end

                local info              = _StructInfo[target]

                if info and validateflags(MOD_SEALED_STRUCT, info[FLD_STRUCT_MOD]) then error(strformat("Usage: struct.BeginDefinition(structure[, stack]) - The %s is sealed, can't be re-defined", tostring(target)), stack) end
                -- if _StructBuilderInfo[target] then error(strformat("Usage: struct.BeginDefinition(structure[, stack]) - The %s's definition has already begun", tostring(target)), stack) end

                _StructBuilderInfo      = savestorage(_StructBuilderInfo, target, initStructInfo(target))

                attribute.SaveAttributes(target, ATTRTAR_STRUCT, stack)
            end;

            --- End the structure's definition
            -- @static
            -- @method  EndDefinition
            -- @owner   struct
            -- @format  (structure[, stack])
            -- @param   structure                   the structure
            -- @param   stack                       the stack level
            ["EndDefinition"]           = function(target, stack)
                local ninfo             = _StructBuilderInfo[target]
                if not ninfo then return end

                stack                   = parsestack(stack) + 1

                _StructBuilderInfo      = savestorage(_StructBuilderInfo, target, nil)

                -- Install base struct's features
                if ninfo[FLD_STRUCT_BASE] then
                    -- Check conflict, some should be handled by the author
                    local binfo         = _StructInfo[ninfo[FLD_STRUCT_BASE]]

                    if ninfo[FLD_STRUCT_ARRAY] then             -- Array
                        if binfo[FLD_STRUCT_MEMBERSTART] then
                            error(strformat("Usage: struct.EndDefinition(structure[, stack]) - The %s's base struct can't be a member structure", tostring(target)), stack)
                        elseif binfo[FLD_STRUCT_KEYTYPE] or binfo[FLD_STRUCT_VALTYPE] then
                            error(strformat("Usage: struct.EndDefinition(structure[, stack]) - The %s's base struct can't be a dictionary structure", tostring(target)), stack)
                        end
                    elseif ninfo[FLD_STRUCT_MEMBERSTART] then   -- Member
                        if binfo[FLD_STRUCT_ARRAY] then
                            error(strformat("Usage: struct.EndDefinition(structure[, stack]) - The %s's base struct can't be an array structure", tostring(target)), stack)
                        elseif binfo[FLD_STRUCT_KEYTYPE] or binfo[FLD_STRUCT_VALTYPE] then
                            error(strformat("Usage: struct.EndDefinition(structure[, stack]) - The %s's base struct can't be a dictionary structure", tostring(target)), stack)
                        elseif binfo[FLD_STRUCT_MEMBERSTART] then
                            -- Try to keep the base struct's member order
                            local cache             = _Cache()
                            local idx               = FLD_STRUCT_MEMBERSTART
                            while ninfo[idx] do
                                tinsert(cache, ninfo[idx])
                                idx                 = idx + 1
                            end

                            local memCnt            = #cache

                            idx                     = FLD_STRUCT_MEMBERSTART
                            while binfo[idx] do
                                local name          = binfo[idx][FLD_MEMBER_NAME]
                                ninfo[idx]          = binfo[idx]

                                for k, v in pairs, cache do
                                    if name == v[FLD_MEMBER_NAME] then
                                        ninfo[idx]  = v
                                        cache[k]    = nil
                                        break
                                    end
                                end

                                idx                 = idx + 1
                            end

                            for i = 1, memCnt do
                                if cache[i] then
                                    ninfo[idx]      = cache[i]
                                    idx             = idx + 1
                                end
                            end

                            _Cache(cache)
                        end
                    elseif ninfo[FLD_STRUCT_KEYTYPE] or ninfo[FLD_STRUCT_VALTYPE] then
                        if binfo[FLD_STRUCT_ARRAY] then
                            error(strformat("Usage: struct.EndDefinition(structure[, stack]) - The %s's base struct can't be an array structure", tostring(target)), stack)
                        elseif binfo[FLD_STRUCT_MEMBERSTART] then
                            error(strformat("Usage: struct.EndDefinition(structure[, stack]) - The %s's base struct can't be a member structure", tostring(target)), stack)
                        elseif binfo[FLD_STRUCT_KEYTYPE] or binfo[FLD_STRUCT_VALTYPE] then
                            if not ninfo[FLD_STRUCT_KEYTYPE] then
                                ninfo[FLD_STRUCT_KEYTYPE]   = binfo[FLD_STRUCT_KEYTYPE]
                                ninfo[FLD_STRUCT_KEYVALID]  = binfo[FLD_STRUCT_KEYVALID]
                            end
                            if not ninfo[FLD_STRUCT_VALTYPE] then
                                ninfo[FLD_STRUCT_VALTYPE]   = binfo[FLD_STRUCT_VALTYPE]
                                ninfo[FLD_STRUCT_VALVALID]  = binfo[FLD_STRUCT_VALVALID]
                            end
                        end
                    else                                        -- Custom
                        if binfo[FLD_STRUCT_ARRAY] then
                            ninfo[FLD_STRUCT_ARRAY]         = binfo[FLD_STRUCT_ARRAY]
                            ninfo[FLD_STRUCT_ARRVALID]      = binfo[FLD_STRUCT_ARRVALID]
                        elseif binfo[FLD_STRUCT_KEYTYPE] or binfo[FLD_STRUCT_VALTYPE] then
                            ninfo[FLD_STRUCT_KEYTYPE]       = binfo[FLD_STRUCT_KEYTYPE]
                            ninfo[FLD_STRUCT_KEYVALID]      = binfo[FLD_STRUCT_KEYVALID]
                            ninfo[FLD_STRUCT_VALTYPE]       = binfo[FLD_STRUCT_VALTYPE]
                            ninfo[FLD_STRUCT_VALVALID]      = binfo[FLD_STRUCT_VALVALID]
                        elseif binfo[FLD_STRUCT_MEMBERSTART] then
                            -- Share members
                            local idx                       = FLD_STRUCT_MEMBERSTART
                            while binfo[idx] do
                                ninfo[idx]                  = binfo[idx]
                                idx                         = idx + 1
                            end
                        end
                    end

                    -- Clone the validator and Initializer
                    local nvalid        = ninfo[FLD_STRUCT_VALIDSTART]
                    local ninit         = ninfo[FLD_STRUCT_INITSTART]

                    local idx           = FLD_STRUCT_VALIDSTART
                    while binfo[idx] do
                        ninfo[idx]      = binfo[idx]
                        idx             = idx + 1
                    end
                    ninfo[idx]          = nvalid

                    idx                 = FLD_STRUCT_INITSTART
                    while binfo[idx] do
                        ninfo[idx]      = binfo[idx]
                        idx             = idx + 1
                    end
                    ninfo[idx]          = ninit

                    -- Clone the methods
                    if binfo[FLD_STRUCT_TYPEMETHOD] then
                        nobjmtd         = ninfo[FLD_STRUCT_TYPEMETHOD] or _Cache()

                        for k, v in pairs, binfo[FLD_STRUCT_TYPEMETHOD] do
                            if v and nobjmtd[k] == nil then
                                nobjmtd[k] = v
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
                    local args          = _Cache()
                    local idx           = FLD_STRUCT_MEMBERSTART
                    while ninfo[idx] do
                        tinsert(args, ninfo[idx][FLD_MEMBER_NAME])
                        idx             = idx + 1
                    end
                    ninfo[FLD_STRUCT_ERRMSG] = strformat("Usage: %s(%s) - ", tostring(target), tblconcat(args, ", "))
                    _Cache(args)
                elseif ninfo[FLD_STRUCT_ARRAY] then
                    ninfo[FLD_STRUCT_ERRMSG] = strformat("Usage: %s(...) - ", tostring(target))
                elseif ninfo[FLD_STRUCT_KEYTYPE] or ninfo[FLD_STRUCT_VALTYPE] then
                    ninfo[FLD_STRUCT_ERRMSG] = strformat("Usage: %s{...} - ", tostring(target))
                else
                    ninfo[FLD_STRUCT_ERRMSG] = strformat("[%s]", tostring(target))
                end

                ninfo[FLD_STRUCT_VALIDCACHE] = checkRepeatStructType(target, ninfo)

                updateStructDependence(target, ninfo)
                updateStructImmutable(target, ninfo)

                genStructValidator(ninfo)
                genStructConstructor(ninfo)

                -- Save as new structure's info
                saveStructMeta(target, ninfo)

                -- Check the default value is it's custom struct
                if ninfo[FLD_STRUCT_DEFAULT] ~= nil then
                    local deft          = ninfo[FLD_STRUCT_DEFAULT]
                    ninfo[FLD_STRUCT_DEFAULT] = nil

                    if not (ninfo[FLD_STRUCT_ARRAY] or ninfo[FLD_STRUCT_MEMBERSTART] or ninfo[FLD_STRUCT_KEYTYPE] or ninfo[FLD_STRUCT_VALTYPE]) then
                        local ret, msg  = struct.ValidateValue(target, deft)
                        if not msg then ninfo[FLD_STRUCT_DEFAULT] = ret end
                    end
                end

                attribute.AttachAttributes(target, ATTRTAR_STRUCT, nil, nil, stack)

                -- Refresh structs depended on this
                if _DependenceMap[target] then
                    local cache         = _Cache()
                    cache[target]       = true
                    updateStructDepends(target, cache)
                    _Cache(cache)
                end

                structdefined(target)

                return target
            end;

            --- Get the array structure's element type
            -- @static
            -- @method  GetArrayElement
            -- @owner   struct
            -- @param   structure                   the structure
            -- @return  type                        the array element's type
            ["GetArrayElement"]         = function(target)
                local info              = getStructTargetInfo(target)
                return info and info[FLD_STRUCT_ARRAY]
            end;

            --- Get the structure's base struct type
            -- @static
            -- @method  GetBaseStruct
            -- @owner   struct
            -- @param   structure                   the structure
            -- @return  type                        the base struct
            ["GetBaseStruct"]           = function(target)
                local info              = getStructTargetInfo(target)
                return info and info[FLD_STRUCT_BASE]
            end;

            --- Get the combo types of the target
            -- @static
            -- @method  GetComboTypes
            -- @owner   struct
            -- @param   structure                   the structure
            -- @return  ...                         the combo types
            ["GetComboTypes"]           = function(target)
                local info              = getStructTargetInfo(target)
                if info and info[FLD_STRUCT_COMBTYPE1] then return info[FLD_STRUCT_COMBTYPE1], info[FLD_STRUCT_COMBTYPE2] end
            end;

            --- Get the dictionary key type of the target
            -- @static
            -- @method  GetDictionaryKey
            -- @owner   struct
            -- @param   structure                   the structure
            -- @return  type                        the key type
            ["GetDictionaryKey"]        = function(target)
                local info              = getStructTargetInfo(target)
                return info and info[FLD_STRUCT_KEYTYPE]
            end;

            --- Get the dictionary value type of the target
            -- @static
            -- @method  GetDictionaryValue
            -- @owner   struct
            -- @param   structure                   the structure
            -- @return  type                        the value type
            ["GetDictionaryValue"]      = function(target)
                local info              = getStructTargetInfo(target)
                return info and info[FLD_STRUCT_VALTYPE]
            end;

            --- Get the custom structure's default value
            -- @static
            -- @method  GetDefault
            -- @owner   struct
            -- @param   structure                   the structure
            -- @return  value                       the default value
            ["GetDefault"]              = function(target)
                local info              = getStructTargetInfo(target)
                return info and info[FLD_STRUCT_DEFAULT]
            end;

            --- Get the definition context of the struct
            -- @static
            -- @method  GetDefault
            -- @return  prototype                   the context type
            ["GetDefinitionContext"]    = function() return structbuilder end;

            --- Generate an error message with template and target
            -- @static
            -- @method  GetErrorMessage
            -- @owner   struct
            -- @param   template                    the error message template, normally generated by type validation
            -- @param   target                      the target string, like "value"
            -- @return  string                      the error message
            ["GetErrorMessage"]         = function(template, target)
                target                  = strtrim(tostring(target) or "")
                if target == "" then
                    return (strgsub(template, "%%s%.?", ""))
                else
                    return (strgsub(template, "%%s", target))
                end
            end;

            --- Get the master type of the struct
            -- @static
            -- @method  GetMainType
            -- @owner   struct
            -- @param   structure                   the structure
            -- @return  type                        the main type
            ["GetMainType"]             = function(target)
                local info              = getStructTargetInfo(target)
                return info and info[FLD_STRUCT_MAINTYPE]
            end;

            --- Get the member of the structure with given name
            -- @static
            -- @method  GetMember
            -- @owner   struct
            -- @param   structure                   the structure
            -- @param   name                        the member's name
            -- @return  member                      the member
            ["GetMember"]               = function(target, name)
                local info              = getStructTargetInfo(target)
                if info then
                    for _, m in ipairs, info, FLD_STRUCT_MEMBERSTART - 1 do
                        if m[FLD_MEMBER_NAME] == name then
                            return m[FLD_MEMBER_OBJ]
                        end
                    end
                end
            end;

            --- Get the members of the structure
            -- @static
            -- @method  GetMembers
            -- @owner   struct
            -- @param   structure                   the structure
            -- @return  iter:function               the iterator
            -- @return  structure                   the structure
            ["GetMembers"]              = function(target)
                local info              = getStructTargetInfo(target)
                if info then
                    return function(self, i)
                        i               = i and (i + 1) or FLD_STRUCT_MEMBERSTART
                        if info[i] then
                            return i, info[i][FLD_MEMBER_OBJ]
                        end
                    end, target
                else
                    return fakefunc, target
                end
            end;

            --- Get the method of the structure with given name
            -- @static
            -- @method  GetMethod
            -- @owner   struct
            -- @param   structure                   the structure
            -- @param   name                        the method's name
            -- @rformat method, isstatic
            -- @return  method                      the method
            -- @return  isstatic:boolean            whether the method is static
            ["GetMethod"]               = function(target, name)
                local info, def         = getStructTargetInfo(target)
                if info and type(name) == "string" then
                    local mtd           = info[name]
                    if mtd then return mtd, true end
                    mtd                 = info[FLD_STRUCT_TYPEMETHOD] and info[FLD_STRUCT_TYPEMETHOD][name]
                    if mtd then return mtd, false end
                end
            end;

            --- Get all the methods of the structure
            -- @static
            -- @method  GetMethods
            -- @owner   struct
            -- @param   structure                   the structure
            -- @return  iter:function               the iterator
            -- @return  structure                   the structure
            -- @usage   for name, func, isstatic in struct.GetMethods(System.Drawing.Color) do
            --              print(name)
            --          end
            ["GetMethods"]              = function(target)
                local info              = getStructTargetInfo(target)
                if info then
                    local typm          = info[FLD_STRUCT_TYPEMETHOD]
                    if typm then
                        return function(self, n)
                            local m, v  = next(typm, n)
                            if m then return m, v or info[m], not v end
                        end, target
                    end
                end
                return fakefunc, target
            end;

            --- Get the struct category of the structure
            -- @static
            -- @method  GetStructCategory
            -- @owner   struct
            -- @param   structure                   the structure
            -- @return  string                      the structure's category: CUSTOM|ARRAY|MEMBER
            ["GetStructCategory"]       = function(target)
                local info              = getStructTargetInfo(target)
                if info then
                    if info[FLD_STRUCT_COMBTYPE1] then return STRUCT_TYPE_CUSTOM end
                    if info[FLD_STRUCT_ARRAY] then return STRUCT_TYPE_ARRAY end
                    if info[FLD_STRUCT_MEMBERSTART] then return STRUCT_TYPE_MEMBER end
                    if info[FLD_STRUCT_KEYTYPE] or info[FLD_STRUCT_VALTYPE] then return STRUCT_TYPE_DICT end
                    return STRUCT_TYPE_CUSTOM
                end
            end;

            --- Get template struct
            -- @static
            -- @method  GetTemplate
            -- @owner   struct
            -- @param   structure                   the structure
            -- @return  template                    the template struct, maybe itself
            ["GetTemplate"]             = function(target)
                local info              = getStructTargetInfo(target)
                return info and (info[FLD_STRUCT_TEMPDEF] and target or info[FLD_STRUCT_TEMPIMP])
            end;

            --- Get the template parameters
            -- @static
            -- @method  GetTemplateParameters
            -- @owner   struct
            -- @param   structure                   the structure
            -- @return  ...                         the paramter list
            ["GetTemplateParameters"]   = function(target)
                local info              = getStructTargetInfo(target)
                if info and info[FLD_STRUCT_TEMPPRM] then
                    return unpack(info[FLD_STRUCT_TEMPPRM])
                end
            end;

            --- Whether the struct's value is immutable through the validation, means no object method, no initializer
            -- @static
            -- @method  IsImmutable
            -- @owner   struct
            -- @param   structure                   the structure
            -- @return  boolean                     true if the value should be immutable
            -- @return  boolean                     true if the value should be always immutable
            ["IsImmutable"]             = function(target)
                local info              = getStructTargetInfo(target)
                if info then
                    local flag          = validateflags(MOD_IMMUTABLE_STRUCT, info[FLD_STRUCT_MOD])
                    return flag, flag and validateflags(MOD_SEALED_STRUCT, info[FLD_STRUCT_MOD])
                end
            end;

            --- Whether the structure allow objects instead of raw table
            -- @static
            -- @method  IsObjectAllowed
            -- @owner   struct
            -- @param   structure                   the structure
            -- @return  boolean                     true if the structure allow objects
            ["IsObjectAllowed"]         = function(target)
                local info              = getStructTargetInfo(target)
                return info and (info[FLD_STRUCT_ARRAY] or info[FLD_STRUCT_KEYTYPE] or info[FLD_STRUCT_VALTYPE] or validateflags(MOD_ALLOWOBJ_STRUCT, info[FLD_STRUCT_MOD])) or false
            end;

            --- Whether a structure use the other as its base structure
            -- @static
            -- @method  IsSubType
            -- @owner   struct
            -- @param   structure                   the structure
            -- @param   base                        the base structure
            -- @return  boolean                     true if the structure use the target structure as base
            ["IsSubType"]               = function(target, base)
                if getmetatable(base) == struct then
                    while target do
                        if base == target then return true end
                        local info      = getStructTargetInfo(target)
                        if not info then return false end
                        if base == info[FLD_STRUCT_TEMPIMP] then return true end
                        target          = info[FLD_STRUCT_BASE]
                    end
                end
                return false
            end;

            --- Whether the structure is sealed, can't be re-defined
            -- @static
            -- @method  IsSealed
            -- @owner   struct
            -- @param   structure                   the structure
            -- @return  boolean                     true if the structure is sealed
            ["IsSealed"]                = function(target)
                local info              = getStructTargetInfo(target)
                return info and validateflags(MOD_SEALED_STRUCT, info[FLD_STRUCT_MOD]) or false
            end;

            --- Whether the structure type value may contain self reference
            -- @static
            -- @method  IsSelfReferenced
            -- @owner   struct
            -- @param   structure                   the structure
            -- @return  boolean                     true if the structure type value may contain self reference
            ["IsSelfReferenced"]        = function(target)
                local info              = getStructTargetInfo(target)
                return info and info[FLD_STRUCT_VALIDCACHE] and true or false
            end;

            --- Whether the structure's given name method is static
            -- @static
            -- @method  IsStaticMethod
            -- @owner   struct
            -- @param   structure                   the structure
            -- @param   name                        the method's name
            -- @return  boolean                     true if the method is static
            ["IsStaticMethod"]          = function(target, name)
                local info              = getStructTargetInfo(target)
                return info and type(name) == "string" and info[FLD_STRUCT_TYPEMETHOD] and info[FLD_STRUCT_TYPEMETHOD][name] == false or false
            end;

            --- Set the structure's array element type
            -- @static
            -- @method  SetArrayElement
            -- @owner   struct
            -- @format  (structure, elementType[, stack])
            -- @param   structure                   the structure
            -- @param   elementType                 the element's type
            -- @param   stack                       the stack level
            ["SetArrayElement"]         = function(target, eleType, stack)
                local info, def         = getStructTargetInfo(target)
                stack                   = parsestack(stack) + 1

                if info then
                    if not def then error(strformat("Usage: struct.SetArrayElement(structure, eleType[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                    if info[FLD_STRUCT_KEYTYPE] or info[FLD_STRUCT_VALTYPE] then error("Usage: struct.SetArrayElement(structure, eleType[, stack]) - The structure has dictionary settings, can't set array element", stack) end
                    if info[FLD_STRUCT_MEMBERSTART] then error("Usage: struct.SetArrayElement(structure, eleType[, stack]) - The structure has member settings, can't set array element", stack) end

                    local tpValid       = getprototypemethod(eleType, "ValidateValue")
                    if not tpValid then error("Usage: struct.SetArrayElement(structure, eleType[, stack]) - The element type is not valid", stack) end

                    info[FLD_STRUCT_ARRAY]      = eleType
                    info[FLD_STRUCT_ARRVALID]   = tpValid
                else
                    error("Usage: struct.SetArrayElement(structure, eleType[, stack]) - The structure is not valid", stack)
                end
            end;

            --- Set the dictionary key type
            -- @static
            -- @method  SetDictionaryKey
            -- @owner   struct
            -- @format  (structure, keyType[, stack])
            -- @param   structure                   the structure
            -- @param   keyType                     the key type
            -- @param   stack                       the stack level
            ["SetDictionaryKey"]        = function(target, keyType, stack)
                local info, def         = getStructTargetInfo(target)
                stack                   = parsestack(stack) + 1

                if info then
                    if not def then error(strformat("Usage: struct.SetDictionaryKey(structure, keyType[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                    if info[FLD_STRUCT_ARRAY] then error("Usage: struct.SetDictionaryKey(structure, keyType[, stack]) - The structure has array settings, can't set the key type", stack) end
                    if info[FLD_STRUCT_MEMBERSTART] then error("Usage: struct.SetDictionaryKey(structure, keyType[, stack]) - The structure has member settings, can't set the key type", stack) end

                    local tpValid       = getprototypemethod(keyType, "ValidateValue")
                    if not tpValid then error("Usage: struct.SetDictionaryKey(structure, keyType[, stack]) - The key type is not valid", stack) end

                    info[FLD_STRUCT_KEYTYPE]    = keyType
                    info[FLD_STRUCT_KEYVALID]   = tpValid
                else
                    error("Usage: struct.SetDictionaryKey(structure, keyType[, stack]) - The structure is not valid", stack)
                end
            end;

            --- Set the dictionary value type
            -- @static
            -- @method  SetDictionaryValue
            -- @owner   struct
            -- @format  (structure, valType[, stack])
            -- @param   structure                   the structure
            -- @param   keyType                     the key type
            -- @param   stack                       the stack level
            ["SetDictionaryValue"]      = function(target, valType, stack)
                local info, def         = getStructTargetInfo(target)
                stack                   = parsestack(stack) + 1

                if info then
                    if not def then error(strformat("Usage: struct.SetDictionaryValue(structure, valType[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                    if info[FLD_STRUCT_ARRAY] then error("Usage: struct.SetDictionaryValue(structure, valType[, stack]) - The structure has array settings, can't set the value type", stack) end
                    if info[FLD_STRUCT_MEMBERSTART] then error("Usage: struct.SetDictionaryValue(structure, valType[, stack]) - The structure has member settings, can't set the value type", stack) end

                    local tpValid       = getprototypemethod(valType, "ValidateValue")
                    if not tpValid then error("Usage: struct.SetDictionaryValue(structure, valType[, stack]) - The value type is not valid", stack) end

                    info[FLD_STRUCT_VALTYPE]    = valType
                    info[FLD_STRUCT_VALVALID]   = tpValid
                else
                    error("Usage: struct.SetDictionaryValue(structure, valType[, stack]) - The structure is not valid", stack)
                end
            end;

            --- Set the structure so it allow objects pass its validation
            -- @static
            -- @method  SetObjectAllowed
            -- @owner   struct
            -- @format  (structure[, stack])
            -- @param   structure                   the structure
            -- @param   stack                       the stack level
            ["SetObjectAllowed"]        = function(target, stack)
                local info              = getStructTargetInfo(target)
                stack                   = parsestack(stack) + 1

                if info then
                    if not validateflags(MOD_ALLOWOBJ_STRUCT, info[FLD_STRUCT_MOD]) then
                        info[FLD_STRUCT_MOD] = turnonflags(MOD_ALLOWOBJ_STRUCT, info[FLD_STRUCT_MOD])
                    end
                else
                    error("Usage: struct.SetObjectAllowed(structure[, stack]) - The structure is not valid", stack)
                end
            end;

            --- Set the structure's base structure
            -- @static
            -- @method  SetBaseStruct
            -- @owner   struct
            -- @format  (structure, base[, stack])
            -- @param   structure                   the structure
            -- @param   base                        the base structure
            -- @param   stack                       the stack level
            ["SetBaseStruct"]           = function(target, base, stack)
                local info, def         = getStructTargetInfo(target)
                stack                   = parsestack(stack) + 1

                if info then
                    if not def then error(strformat("Usage: struct.SetBaseStruct(structure, base) - The %s's definition is finished", tostring(target)), stack) end
                    if not struct.Validate(base) then error("Usage: struct.SetBaseStruct(structure, base) - The base must be a structure", stack) end
                    info[FLD_STRUCT_BASE] = base
                    attribute.InheritAttributes(target, ATTRTAR_STRUCT, base)
                else
                    error("Usage: struct.SetBaseStruct(structure, base[, stack]) - The structure is not valid", stack)
                end
            end;

            --- Set the structure's default value, only for custom struct type
            -- @static
            -- @method  SetDefault
            -- @owner   struct
            -- @format  (structure, default[, stack])
            -- @param   structure                   the structure
            -- @param   default                     the default value
            -- @param   stack                       the stack level
            ["SetDefault"]              = function(target, default, stack)
                local info, def         = getStructTargetInfo(target)
                stack                   = parsestack(stack) + 1

                if info then
                    if not def then error(strformat("Usage: struct.SetDefault(structure, default[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                    info[FLD_STRUCT_DEFAULT] = default
                else
                    error("Usage: struct.SetDefault(structure, default[, stack]) - The structure is not valid", stack)
                end
            end;

            --- Set the structure's validator
            -- @static
            -- @method  SetValidator
            -- @owner   struct
            -- @format  (structure, func[, stack])
            -- @param   structure                   the structure
            -- @param   func                        the validator
            -- @param   stack                       the stack level
            ["SetValidator"]            = function(target, func, stack)
                local info, def         = getStructTargetInfo(target)
                stack                   = parsestack(stack) + 1

                if info then
                    if not def then error(strformat("Usage: struct.SetValidator(structure, validator[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                    if type(func) ~= "function" then error("Usage: struct.SetValidator(structure, validator) - The validator must be a function", stack) end
                    info[FLD_STRUCT_VALIDSTART] = func
                else
                    error("Usage: struct.SetValidator(structure, validator[, stack]) - The structure is not valid", stack)
                end
            end;

            --- Set the structure's initializer
            -- @static
            -- @method  SetInitializer
            -- @owner   struct
            -- @format  (structure, func[, stack])
            -- @param   structure                   the structure
            -- @param   func                        the initializer
            -- @param   stack                       the stack level
            ["SetInitializer"]          = function(target, func, stack)
                local info, def         = getStructTargetInfo(target)
                stack                   = parsestack(stack) + 1

                if info then
                    if not def then error(strformat("Usage: struct.SetInitializer(structure, initializer[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                    if type(func) ~= "function" then error("Usage: struct.SetInitializer(structure, initializer) - The initializer must be a function", stack) end
                    info[FLD_STRUCT_INITSTART] = func
                else
                    error("Usage: struct.SetInitializer(structure, initializer[, stack]) - The structure is not valid", stack)
                end
            end;

            --- Seal the structure
            -- @static
            -- @method  SetSealed
            -- @owner   struct
            -- @format  (structure[, stack])
            -- @param   structure                   the structure
            -- @param   stack                       the stack level
            ["SetSealed"]               = function(target, stack)
                local info              = getStructTargetInfo(target)
                stack                   = parsestack(stack) + 1

                if info then
                    if not validateflags(MOD_SEALED_STRUCT, info[FLD_STRUCT_MOD]) then
                        info[FLD_STRUCT_MOD] = turnonflags(MOD_SEALED_STRUCT, info[FLD_STRUCT_MOD])
                    end
                else
                    error("Usage: struct.SetSealed(structure[, stack]) - The structure is not valid", stack)
                end
            end;

            --- Mark a structure's method as static
            -- @static
            -- @method  SetStaticMethod
            -- @owner   struct
            -- @format  (structure, name[, stack])
            -- @param   structure                   the structure
            -- @param   name                        the method's name
            -- @param   stack                       the stack level
            ["SetStaticMethod"]         = function(target, name, stack)
                local info, def         = getStructTargetInfo(target)
                stack                   = parsestack(stack) + 1

                if info then
                    if type(name) ~= "string" then error("Usage: struct.SetStaticMethod(structure, name) - the name must be a string", stack) end
                    name                = strtrim(name)
                    if name == "" then error("Usage: Usage: struct.SetStaticMethod(structure, name) - The name can't be empty", stack) end
                    if not def then error(strformat("Usage: struct.SetStaticMethod(structure, name) - The %s's definition is finished", tostring(target)), stack) end

                    if info[name] == nil then
                        info[FLD_STRUCT_TYPEMETHOD] = info[FLD_STRUCT_TYPEMETHOD] or {}
                        info[name]      = info[FLD_STRUCT_TYPEMETHOD][name]
                        info[FLD_STRUCT_TYPEMETHOD][name] = false
                    end
                else
                    error("Usage: struct.SetStaticMethod(structure, name[, stack]) - The structure is not valid", stack)
                end
            end;

            --- Mark the structure as a template struct
            -- @static
            -- @method  SetAsTemplate
            -- @owner   struct
            -- @format  (structure, params[, stack])
            -- @param   target                      the structure
            -- @param   params                      the parameters for the template
            -- @param   stack                       the stack level
            ["SetAsTemplate"]           = function(target, params, stack)
                local info, def         = getStructTargetInfo(target)
                stack                   = parsestack(stack) + 1

                if info then
                    if not def then error(strformat("Usage: struct.SetAsTemplate(structure, params[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                    info[FLD_STRUCT_MOD]    = turnonflags(MOD_TEMPLATE_STRUCT, info[FLD_STRUCT_MOD])
                    info[FLD_STRUCT_MOD]    = turnonflags(MOD_SEALED_STRUCT,   info[FLD_STRUCT_MOD])

                    info[FLD_STRUCT_TEMPPRM]= type(params) == "table" and getmetatable(params) == nil and params or { params }
                    info[FLD_STRUCT_TEMPIMP]= saveTemplateImplement({}, info[FLD_STRUCT_TEMPPRM], target)
                else
                    error("Usage: struct.SetAsTemplate(structure, params[, stack]) - The structure is not valid", stack)
                end
            end;

            --- Validate the value with a structure
            -- @static
            -- @method  ValidateValue
            -- @owner   struct
            -- @format  (structure, value[, onlyValid])
            -- @param   structure                   the structure
            -- @param   value                       the value used to validate
            -- @param   onlyValid                   Only validate the value, no value modifiy(The initializer and object methods won't be applied)
            -- @rfomat  (value[, message])
            -- @return  value                       the validated value
            -- @return  message                     the error message if the validation is failed
            ["ValidateValue"]           = function(target, value, onlyValid, cache)
                local info              = _StructInfo[target]
                if info then
                    if not cache and info[FLD_STRUCT_VALIDCACHE] then
                        cache           = _Cache()
                        local ret, msg  = info[FLD_STRUCT_VALID](info, value, onlyValid, cache)
                        for k, v in pairs, cache do cache[k] = nil _Cache(v) end _Cache(cache)
                        return ret, msg
                    else
                        return info[FLD_STRUCT_VALID](info, value, onlyValid, cache)
                    end
                else
                    error("Usage: struct.ValidateValue(structure, value[, onlyValid]) - The structure is not valid", 2)
                end
            end;

            -- Whether the value is a struct type
            -- @static
            -- @method  Validate
            -- @owner   struct
            -- @param   value                       the value used to validate
            -- @return  value                       return the value if it's a struct type, otherwise nil will be return
            ["Validate"]                = function(target)
                return getStructTargetInfo(target) and target or nil
            end;
        },
        __newindex                      = readonly,
        __call                          = function(self, ...)
            -- For simple, only re-use anonymous type generated with one table and one key-value pairs
            local _arrayType
            local _hashKeyType, _hashValType

            if select("#", ...) == 1 then
                local definition        = ...
                if type(definition) == "table" then
                    -- Check if only contains one pair
                    local k, v          = next(definition)

                    if k and v and next(definition, k) == nil then
                        if type(k) == "number" then
                            if getprototypemethod(v, "ValidateValue") then
                                _arrayType  = v
                                local stype = _AnonyArrayType[v]
                                if stype then
                                    -- Clear the keyword accessor
                                    environment.GetKeywordVisitor(struct)
                                    return stype
                                end
                            end
                        else
                            if getprototypemethod(k, "ValidateValue") and getprototypemethod(v, "ValidateValue") then
                                _hashKeyType, _hashValType = k, v
                                local stype = _AnonyHashType[k]
                                stype       = stype and stype[v]
                                if stype then
                                    -- Clear the keyword accessor
                                    environment.GetKeywordVisitor(struct)
                                    return stype
                                end
                            end
                        end
                    end
                end
            end

            local visitor, env, target, definition, keepenv, stack  = getTypeParams(struct, tstruct, ...)
            if not target then error("Usage: struct([env, ][name, ][definition, ][keepenv, ][stack]) - the struct type can't be created", stack) end

            if not _StructInfo[target] then
                saveStructMeta(target, initStructInfo(target))
            end

            stack                       = stack + 1

            struct.BeginDefinition(target, stack)

            Debug("[struct] %s created", stack, tostring(target))

            local builder               = prototype.NewObject(structbuilder)
            environment.Initialize  (builder)
            environment.SetNamespace(builder, target)
            environment.SetParent   (builder, env)
            environment.SetDefinitionMode(builder, true)

            -- Seal the anonymous type directly
            if _arrayType or _hashKeyType then
                struct.SetSealed(target, stack)

                if _arrayType then
                    _AnonyArrayType     = savestorage(_AnonyArrayType, _arrayType, target)
                else
                    _AnonyHashType      = savestorage(_AnonyHashType, _hashKeyType, savestorage(_AnonyHashType[_hashKeyType] or {}, _hashValType, target))
                end
            end

            _StructBuilderInDefine      = savestorage(_StructBuilderInDefine, builder, true)

            if definition then
                builder(definition, stack)
                return target
            else
                if not keepenv then safesetfenv(stack, builder) end
                return builder
            end
        end,
    }

    validatetype                        = prototype (tnamespace, {
        __add                           = function(a, b)
            local comb                  = _ValidTypeCombine[a] and _ValidTypeCombine[a][b] or _ValidTypeCombine[b] and _ValidTypeCombine[b][a]
            if comb then return comb end

            local valida                = getprototypemethod(a, "ValidateValue")
            local validb                = getprototypemethod(b, "ValidateValue")

            if not valida or not validb then
                error("the both value of the addition must be validation type", 2)
            end

            local strt                  =  prototype.NewProxy(tstruct)
            namespace.SaveAnonymousNamespace(strt)
            saveStructMeta(strt, initStructInfo(strt))
            struct.BeginDefinition(strt, 2)

            local info                  = _StructBuilderInfo[strt]

            info[FLD_STRUCT_COMBTYPE1]  = a
            info[FLD_STRUCT_COMBTYPE2]  = b

            local msg                   = "the %s must be value of " .. tostring(strt)

            struct.SetValidator(strt, function (val, onlyvalid)
                local _, err            = valida(a, val, true)
                if not err then return end
                _, err                  = validb(b, val, true)
                if not err then return end
                return onlyvalid or msg
            end, 2)

            local _, isalimtbla         = getobjectvalue(a, "IsImmutable")
            local _, isalimtblb         = getobjectvalue(b, "IsImmutable")

            if not (isalimtbla and isalimtblb) then
                struct.SetInitializer(strt, function(val)
                    local ret, err      = valida(a, val)
                    if not err then return ret end
                    ret, err            = validb(b, val)
                    if not err then return ret end
                end, 2)
            end

            struct.SetSealed(strt, 2)
            struct.EndDefinition(strt, 2)

            _ValidTypeCombine           = savestorage(_ValidTypeCombine, a, savestorage(_ValidTypeCombine[a] or {}, b, strt))

            return strt
        end,
        __unm                           = function(self)
            local issubtype             = getprototypemethod(self, "IsSubType")
            if not issubtype then
                error("the type's prototype don't support 'IsSubType' check")
            end

            if _UnmSubTypeMap[self] then return _UnmSubTypeMap[self] end

            local msg                   = "the %s must be a sub type of " .. tostring(self)
            local strt                  =  prototype.NewProxy(tstruct)
            namespace.SaveAnonymousNamespace(strt)
            saveStructMeta(strt, initStructInfo(strt))
            struct.BeginDefinition(strt, 2)

            local info                  = _StructBuilderInfo[strt]

            info[FLD_STRUCT_MAINTYPE]   = self

            struct.SetValidator(strt, function (val, onlyvalid)
                return not issubtype(val, self) and (onlyvalid or msg) or nil
            end, 2)

            struct.SetSealed(strt, 2)
            struct.EndDefinition(strt, 2)

            _UnmSubTypeMap              = savestorage(_UnmSubTypeMap, self, strt)

            return strt
        end,
        __div                           = function(self, default)
            local valid                 = getprototypemethod(self, "ValidateValue")

            if not valid then
                error(("The %s is not a validation type"):format(tostring(self)), 2)
            end

            if default ~= nil then
                local ret, msg          = valid(self, default)
                if not msg then
                    default             = ret
                else
                    error(struct.GetErrorMessage(msg, "default in (type/default)"), 2)
                end
            end

            return Variable.Optional(self, default)
        end,
        __mul                           = function(self, mincount)
            local valid                 = getprototypemethod(self, "ValidateValue")

            if not valid then
                error(("The %s is not a validation type"):format(tostring(self)), 2)
            end

            if mincount ~= nil and (type(mincount) ~= "number" or mincount < 0) then
                error("The mincount in (type * mincount) must a nature number", 2)
            end

            return Variable.Rest(self, mincount)
        end,
    })

    tstruct                             = prototype (validatetype, {
        __index                         = PLOOP_PLATFORM_SETTINGS.NAMESPACE_NIL_VALUE_ACCESSIBLE and function(self, key)
            if type(key) == "string" then
                local info              = _StructBuilderInfo[self] or _StructInfo[self]
                return info and (info[key] or info[FLD_STRUCT_TYPEMETHOD] and info[FLD_STRUCT_TYPEMETHOD][key]) or namespace.GetNamespace(self, key)
            else
                local value             = getStructImplement(self, key, 2)
                return value
            end
        end or function(self, key)
            if type(key) == "string" then
                local info              = _StructBuilderInfo[self] or _StructInfo[self]
                local value             = info and (info[key] or info[FLD_STRUCT_TYPEMETHOD] and info[FLD_STRUCT_TYPEMETHOD][key]) or namespace.GetNamespace(self, key)
                if value ~= nil then return value end
                error(strformat("The %s.%s is not existed", namespace.GetNamespaceName(self), key), 2)
            else
                local value             = getStructImplement(self, key, 2)
                return value
            end
        end,
        __tostring                      = function(self)
            local info                  = _StructBuilderInfo[self] or _StructInfo[self]
            if info then
                if info[FLD_STRUCT_COMBTYPE1] then
                    return tostring(info[FLD_STRUCT_COMBTYPE1]) .. " | " .. tostring(info[FLD_STRUCT_COMBTYPE2])
                elseif info[FLD_STRUCT_MAINTYPE] then
                    return "-" .. namespace.GetNamespaceName(info[FLD_STRUCT_MAINTYPE])
                end
            end

            return namespace.GetNamespaceName(self)
        end,
        __call                          = function(self, ...)
            local info                  = _StructInfo[self]
            local ret                   = info[FLD_STRUCT_CTOR](info, ...)
            return ret
        end,
        __metatable                     = struct,
    })

    structbuilder                       = prototype {
        __tostring                      = function(self)
            local owner                 = environment.GetNamespace(self)
            return"[structbuilder]" .. (owner and tostring(owner) or "anonymous")
        end,
        __index                         = environment.GetValue,
        __newindex                      = function(self, key, value)
            if not setStructBuilderValue(self, key, value, 2) then
                environment.SaveValue(self, key, value, 2)
            end
        end,
        __call                          = function(self, definition, stack)
            stack                       = parsestack(stack) + 1
            if not definition then error("Usage: struct([env, ][name, ][stack]) (definition) - the definition is missing", stack) end

            local owner                 = environment.GetNamespace(self)
            local info                  = _StructBuilderInfo[owner]
            if not (owner and _StructBuilderInDefine[self] and info) then error("The struct's definition is finished", stack) end

            definition                  = attribute.InitDefinition(owner, ATTRTAR_STRUCT, parseDefinition(definition, self, stack), nil, nil, stack)

            if type(definition) == "function" then
                setfenv(definition, self)

                if validateflags(MOD_TEMPLATE_STRUCT, info[FLD_STRUCT_MOD]) then
                    -- Save for template
                    info[FLD_STRUCT_TEMPDEF] = definition
                    info[FLD_STRUCT_TEMPENV] = environment.GetParent(self)

                    local ok, err       = pcall(definition, self, struct.GetTemplateParameters(owner))
                    if not ok and type(err) == "string" then error(err, 0) end
                else
                    definition(self, struct.GetTemplateParameters(owner))
                end
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
                    if type(k) ~= "number" then
                        setStructBuilderValue(self, k, v, stack, true)
                    end
                end
            end

            attribute.ApplyAttributes(owner, ATTRTAR_STRUCT, self, nil, nil, stack)

            environment.SetDefinitionMode(self, false)
            _StructBuilderInDefine      = savestorage(_StructBuilderInDefine, self, nil)
            struct.EndDefinition(owner, stack)

            if getfenv(stack) == self then
                safesetfenv(stack, environment.GetParent(self) or _G)
            end

            return owner
        end,
    }

    -----------------------------------------------------------------------
    --                             keywords                              --
    -----------------------------------------------------------------------

    -----------------------------------------------------------------------
    -- Declare a new member for the structure
    --
    -- @keyword     member
    -- @usage       member "Name" { Type = String, Default = "Anonymous", Require = false }
    -----------------------------------------------------------------------
    member                              = prototype {
        __tostring                      = function(self) local info = _MemberInfo[self] return info and info[FLD_MEMBER_NAME] end,
        __index                         = {
            -- Get the type of the member
            -- @static
            -- @method  GetType
            -- @owner   member
            -- @param   target                      the member
            -- @return  type                        the member's type
            ["GetType"]                 = function(self) local info = _MemberInfo[self] return info and info[FLD_MEMBER_TYPE] end;

            -- Whether the member's value is required
            -- @static
            -- @method  IsRequire
            -- @owner   member
            -- @param   target                      the member
            -- @return  type                        the member's type
            ["IsRequire"]               = function(self) local info = _MemberInfo[self] return info and info[FLD_MEMBER_REQUIRE] or false end;

            -- Get the name of the member
            -- @static
            -- @method  GetName
            -- @owner   member
            -- @param   target                      the member
            -- @return  name                        the member's name
            ["GetName"]                 = function(self) local info = _MemberInfo[self] return info and info[FLD_MEMBER_NAME] end;

            -- Get the default value of the member
            -- @static
            -- @method  GetDefault
            -- @owner   member
            -- @param   target                      the member
            -- @return  default                     the member's default value
            ["GetDefault"]              = function(self) local info = _MemberInfo[self] return info and info[FLD_MEMBER_DEFAULT] end;
        },
        __newindex                      = readonly,
        __call                          = function(self, ...)
            if self == member then
                local visitor, env, name, definition, flag, stack  = getFeatureParams(member, nil, ...)
                local owner             = visitor and environment.GetNamespace(visitor)

                if owner and name then
                    if type(definition) == "table" then
                        _MemberAccessOwner  = nil
                        _MemberAccessName   = nil
                        struct.AddMember(owner, name, definition, stack + 1)
                        return
                    else
                        _MemberAccessOwner = owner
                        _MemberAccessName  = name
                        return self
                    end
                elseif type(definition) == "table" then
                    name                = _MemberAccessName
                    owner               = owner or _MemberAccessOwner

                    _MemberAccessOwner  = nil
                    _MemberAccessName   = nil

                    if owner then
                        if name then
                            struct.AddMember(owner, name, definition, stack + 1)
                        else
                            struct.AddMember(owner, definition, stack + 1)
                        end
                        return
                    end
                end

                error([[Usage: member "name" {...}]], stack + 1)
            end
        end,
    }

    -----------------------------------------------------------------------
    -- Set the array element to the structure
    --
    -- @keyword     array
    -- @usage       array "Object"
    -----------------------------------------------------------------------
    array                               = function (...)
        local visitor, env, name, _, flag, stack  = getFeatureParams(array, namespace, ...)

        name                            = parseNamespace(name, visitor, env)
        if not name then error("Usage: array(type) - The type is not provided", stack + 1) end

        local owner                     = visitor and environment.GetNamespace(visitor)
        if not owner  then error("Usage: array(type) - The system can't figure out the structure", stack + 1) end

        struct.SetArrayElement(owner, name)
    end

    -----------------------------------------------------------------------
    -- End the definition of the structure
    --
    -- @keyword     endstruct
    -- @usage       struct "Number"
    --                  function Number(val)
    --                      return type(val) ~= "number" and "%s must be number"
    --                  end
    --              endstruct "Number"
    -----------------------------------------------------------------------
    endstruct                           = PLOOP_PLATFORM_SETTINGS.TYPE_DEFINITION_WITH_OLD_STYLE and function (...)
        local visitor, env, name, definition, flag, stack  = getFeatureParams(endstruct, nil,  ...)
        local owner                     = visitor and environment.GetNamespace(visitor)

        stack                           = stack + 1

        if not owner or not visitor then error([[Usage: endstruct "name" - can't be used here.]], stack) end
        if namespace.GetNamespaceName(owner, true) ~= name then error(strformat("%s's definition isn't finished", tostring(owner)), stack) end
        if not (_StructBuilderInDefine[visitor] and _StructBuilderInfo[owner]) then error("The struct's definition is finished", stack) end

        attribute.ApplyAttributes(owner, ATTRTAR_STRUCT, visitor, nil, nil, stack)

        environment.SetDefinitionMode(visitor, false)
        _StructBuilderInDefine          = savestorage(_StructBuilderInDefine, visitor, nil)
        struct.EndDefinition(owner, stack)

        local baseEnv                   = environment.GetParent(visitor) or _G

        setfenv(stack, baseEnv)

        return baseEnv
    end or nil
end

-------------------------------------------------------------------------------
-- An enumeration is a data type consisting of a set of named values called
-- elements, The enumerator names are usually identifiers that behave as
-- constants.
--
-- To define an enum within the PLoop, the syntax is
--
--      enum "Name" { -- key-value pairs }
--
-- In the table, for each key-value pair, if the key is string, the key would
-- be used as the element's name and the value is the element's value. If the
-- key is a number and the value is string, the value would be used as both the
-- element's name and value, othwise the key-value pair will be ignored.
--
-- Use enumeration[elementname] to fetch the enum element's value, also can use
-- enumeration(value) to fetch the element name from value. Here is an example :
--
--      enum "Direction" { North = 1, East = 2, South = 3, West = 4 }
--      print(Direction.South) -- 3
--      print(Direction.NoDir) -- nil
--
--      print(Direction(3))    -- South
--
-- @prototype   enum
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                         attribute targets                         --
    -----------------------------------------------------------------------
    ATTRTAR_ENUM                        = attribute.RegisterTargetType("Enum")

    -----------------------------------------------------------------------
    --                         private constants                         --
    -----------------------------------------------------------------------
    -- FEATURE MODIFIER
    MOD_SEALED_ENUM                     = newflags(true)    -- SEALED
    MOD_FLAGS_ENUM                      = newflags()        -- FLAGS
    MOD_NOT_FLAGS                       = newflags()        -- NOT FLAG
    MOD_SHARE_VALUE                     = newflags()        -- ALLOW THE SAME VALUE

    -- FIELD INDEX
    FLD_ENUM_MOD                        = newindex(0)       -- FIELD MODIFIER
    FLD_ENUM_ITEMS                      = newindex()        -- FIELD ENUMERATIONS
    FLD_ENUM_CACHE                      = newindex()        -- FIELD CACHE : VALUE -> NAME
    FLD_ENUM_ERRMSG                     = newindex()        -- FIELD ERROR MESSAGE
    FLD_ENUM_MAXVAL                     = newindex()        -- FIELD MAX VALUE(FOR FLAGS)
    FLD_ENUM_DEFAULT                    = newindex()        -- FIELD DEFAULT

    -- Flags
    FLG_FLAGS_ENUM                      = newflags(true)

    -- UNSAFE FIELD
    FLD_ENUM_META                       = "__PLOOP_ENUM_META"

    -----------------------------------------------------------------------
    --                          private storage                          --
    -----------------------------------------------------------------------
    local _EnumInfo                     = PLOOP_PLATFORM_SETTINGS.UNSAFE_MODE and setmetatable({}, {__index = function(_, e) return type(e) == "table" and rawget(e, FLD_ENUM_META) or nil end}) or newstorage(WEAK_KEY)

    -- BUILD CACHE
    local _EnumBuilderInfo              = newstorage(WEAK_KEY)
    local _EnumValidMap                 = {}

    -----------------------------------------------------------------------
    --                          private helpers                          --
    -----------------------------------------------------------------------
    local getEnumTargetInfo             = function (target) local info = _EnumBuilderInfo[target] if info then return info, true else return _EnumInfo[target], false end end

    local saveEnumMeta                  = PLOOP_PLATFORM_SETTINGS.UNSAFE_MODE and function (e, meta) rawset(e, FLD_ENUM_META, meta) end or function (e, meta) _EnumInfo = savestorage(_EnumInfo, e, meta) end

    local initEnumInfo                  = function (target)
        return {
            [FLD_ENUM_MOD    ]          = 0,
            [FLD_ENUM_ITEMS  ]          = {},
            [FLD_ENUM_CACHE  ]          = {},
            [FLD_ENUM_ERRMSG ]          = "%s must be a value of [" .. tostring(target) .."]",
            [FLD_ENUM_MAXVAL ]          = false,
            [FLD_ENUM_DEFAULT]          = nil,
        }
    end

    -----------------------------------------------------------------------
    --                             prototype                             --
    -----------------------------------------------------------------------
    enum                                = prototype {
        __tostring                      = "enum",
        __index                         = {
            --- Add key-value pair to the enumeration
            -- @static
            -- @method  AddElement
            -- @owner   enum
            -- @format  (enumeration, key, value[, stack])
            -- @param   enumeration                 the enumeration
            -- @param   key                         the element name
            -- @param   value                       the element value
            -- @param   stack                       the stack level
            ["AddElement"]              = function(target, key, value, stack)
                local info, def         = getEnumTargetInfo(target)
                stack                   = parsestack(stack) + 1

                if info then
                    if not def then error(strformat("Usage: enum.AddElement(enumeration, key, value[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                    if type(key) ~= "string" then error("Usage: enum.AddElement(enumeration, key, value[, stack]) - The key must be a string", stack) end

                    if validateflags(MOD_SHARE_VALUE, info[FLD_ENUM_MOD]) then
                        if info[FLD_ENUM_ITEMS][key] ~= nil and info[FLD_ENUM_ITEMS][key] ~= value then
                            error("Usage: enum.AddElement(enumeration, key, value[, stack]) - The key " .. tostring(key) .. " already existed", stack)
                        end
                    else
                        for k, v in pairs, info[FLD_ENUM_ITEMS] do
                            if k == key then
                                if v == value then return end
                                error("Usage: enum.AddElement(enumeration, key, value[, stack]) - The key " .. tostring(key) .. " already existed", stack)
                            elseif v == value then
                                error("Usage: enum.AddElement(enumeration, key, value[, stack]) - The value for key " .. tostring(key) .. " already existed", stack)
                            end
                        end
                    end

                    info[FLD_ENUM_ITEMS][key] = value
                else
                    error("Usage: enum.AddElement(enumeration, key, value[, stack]) - The enumeration is not valid", stack)
                end
            end;

            --- Begin the enumeration's definition
            -- @static
            -- @method  BeginDefinition
            -- @owner   enum
            -- @format  (enumeration[, stack])
            -- @param   enumeration                 the enumeration
            -- @param   stack                       the stack level
            ["BeginDefinition"]         = function(target, stack)
                stack                   = parsestack(stack) + 1
                target                  = enum.Validate(target)
                if not target then error("Usage: enum.BeginDefinition(enumeration[, stack]) - the enumeration not existed", stack) end

                local info              = _EnumInfo[target]

                -- if info and validateflags(MOD_SEALED_ENUM, info[FLD_ENUM_MOD]) then error(strformat("Usage: enum.BeginDefinition(enumeration[, stack]) - The %s is sealed, can't be re-defined", tostring(target)), stack) end
                -- if _EnumBuilderInfo[target] then error(strformat("Usage: enum.BeginDefinition(enumeration[, stack]) - The %s's definition has already begun", tostring(target)), stack) end

                _EnumBuilderInfo        = savestorage(_EnumBuilderInfo, target, info and validateflags(MOD_SEALED_ENUM, info[FLD_ENUM_MOD]) and tblclone(info, {}, true, true) or initEnumInfo(target))

                attribute.SaveAttributes(target, ATTRTAR_ENUM, stack)
            end;

            --- End the enumeration's definition
            -- @static
            -- @method  EndDefinition
            -- @owner   enum
            -- @format  (enumeration[, stack])
            -- @param   enumeration                 the enumeration
            -- @param   stack                       the stack level
            ["EndDefinition"]           = function(target, stack)
                local ninfo             = _EnumBuilderInfo[target]
                if not ninfo then return end

                stack                   = parsestack(stack) + 1

                _EnumBuilderInfo        = savestorage(_EnumBuilderInfo, target, nil)

                local enums             = ninfo[FLD_ENUM_ITEMS]
                local cache             = wipe(ninfo[FLD_ENUM_CACHE])

                for k, v in pairs, enums do cache[v] = k end

                -- Check Flags Enumeration
                if validateflags(MOD_FLAGS_ENUM, ninfo[FLD_ENUM_MOD]) then
                    -- Mark the max value
                    local max           = 1
                    for k, v in pairs, enums do
                        while type(v) == "number" and v >= max do max = max * 2 end
                    end

                    ninfo[FLD_ENUM_MAXVAL]  = max - 1
                else
                    ninfo[FLD_ENUM_MAXVAL]  = false
                    ninfo[FLD_ENUM_MOD]     = turnonflags(MOD_NOT_FLAGS, ninfo[FLD_ENUM_MOD])
                end

                -- Save as new enumeration's info
                saveEnumMeta(target, ninfo)

                -- Check Default
                if ninfo[FLD_ENUM_DEFAULT] ~= nil then
                    ninfo[FLD_ENUM_DEFAULT] = enum.ValidateValue(target, ninfo[FLD_ENUM_DEFAULT]) or enums[ninfo[FLD_ENUM_DEFAULT]]
                end

                attribute.AttachAttributes(target, ATTRTAR_ENUM, nil, nil, stack)

                enumdefined(target)

                return target
            end;

            --- Get the default value from the enumeration
            -- @static
            -- @method  GetDefault
            -- @owner   enum
            -- @param   enumeration                 the enumeration
            -- @return  default                     the default value
            ["GetDefault"]              = function(target)
                local info              = getEnumTargetInfo(target)
                return info and info[FLD_ENUM_DEFAULT]
            end;

            --- Get the elements from the enumeration
            -- @static
            -- @method  GetEnumValues
            -- @owner   enum
            -- @param   enumeration                 the enumeration
            -- @return  iter:function               the iterator
            -- @return  enumeration                 the enumeration
            ["GetEnumValues"]           = function(target)
                local info              = _EnumInfo[target]
                if info then
                    info                = info[FLD_ENUM_ITEMS]
                    return function(self, key) return next(info, key) end, target
                else
                    return fakefunc, target
                end
            end;

            --- Whether the enumeration element values only are flags
            -- @static
            -- @method  IsFlagsEnum
            -- @owner   enum
            -- @param   enumeration                 the enumeration
            -- @return  boolean                     true if the enumeration element values only are flags
            ["IsFlagsEnum"]             = function(target)
                local info              = getEnumTargetInfo(target)
                return info and validateflags(MOD_FLAGS_ENUM, info[FLD_ENUM_MOD]) or false
            end;

            --- Whether the enum's value is immutable through the validation, always true.
            -- @static
            -- @method  IsImmutable
            -- @owner   enum
            -- @param   enumeration                 the enumeration
            -- @return  true
            -- @return  true
            ["IsImmutable"]             = function(target) return true, true end;

            --- Whether the enumeration is sealed, so can't be re-defined
            -- @static
            -- @method  IsSealed
            -- @owner   enum
            -- @param   enumeration                 the enumeration
            -- @return  boolean                     true if the enumeration is sealed
            ["IsSealed"]                = function(target)
                local info              = getEnumTargetInfo(target)
                return info and validateflags(MOD_SEALED_ENUM, info[FLD_ENUM_MOD]) or false
            end;

            -- Whether the enumeration allow multiple enum name share the same value
            -- @static
            -- @member IsValueShareable
            -- @owner   enum
            -- @param   enumeration                 the enumeration
            -- @return  boolean                     true if the enumeration can share the same value
            ["IsValueShareable"]        = function(target)
                local info              = getEnumTargetInfo(target)
                return info and validateflags(MOD_SHARE_VALUE, info[FLD_ENUM_MOD]) or false
            end;

            --- Whether the enumeration is sub-type of others, always false, needed by struct system
            -- @static
            -- @method  IsSubType
            -- @owner   enum
            -- @param   enumeration                 the enumeration
            -- @param   super                       the super type
            -- @return  false
            ["IsSubType"]               = function() return false end;

            --- Parse the element value to element name
            -- @static
            -- @method  Parse
            -- @owner   enum
            -- @param   enumeration                 the enumeration
            -- @param   value                       the value
            -- @rformat (name)                      only if the enumeration is not flags enum
            -- @rformat (iter, enum)                If the enumeration is flags enum, the iterator will be returned
            ["Parse"]                   = function(target, value)
                local info              = _EnumInfo[target]
                if info then
                    local ecache        = info[FLD_ENUM_CACHE]

                    if info[FLD_ENUM_MAXVAL] then
                        if type(value) == "number" and floor(value) == value and value >= 0 and value <= info[FLD_ENUM_MAXVAL] then
                            if value   == 0 then
                                if ecache[0] then
                                    return function(self, key) if not key then return ecache[0], 0 end end, target
                                else
                                    return fakefunc, target
                                end
                            else
                                local ckv = 1
                                return function(self, key)
                                    while ckv <= value and ecache[ckv] do
                                        local v = ckv
                                        ckv = ckv * 2
                                        if validateflags(v, value) then return ecache[v], v end
                                    end
                                end, target
                            end
                        else
                            return fakefunc, target
                        end
                    else
                        return ecache[value]
                    end
                end
            end;

            --- Set the enumeration's default value
            -- @static
            -- @method  SetDefault
            -- @owner   enum
            -- @format  (enumeration, default[, stack])
            -- @param   enumeration                 the enumeration
            -- @param   default                     the default value or name
            -- @param   stack                       the stack level
            ["SetDefault"]              = function(target, default, stack)
                local info, def         = getEnumTargetInfo(target)
                stack                   = parsestack(stack) + 1

                if info then
                    if not def then error(strformat("Usage: enum.SetDefault(enumeration, default[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                    info[FLD_ENUM_DEFAULT] = default
                else
                    error("Usage: enum.SetDefault(enumeration, default[, stack]) - The enumeration is not valid", stack)
                end
            end;

            --- Set the enumeration as flags enum
            -- @static
            -- @method  SetFlagsEnum
            -- @owner   enum
            -- @format  (enumeration[, stack])
            -- @param   enumeration                 the enumeration
            -- @param   stack                       the stack level
            ["SetFlagsEnum"]            = function(target, stack)
                local info, def         = getEnumTargetInfo(target)
                stack                   = parsestack(stack) + 1

                if info then
                    if not validateflags(MOD_FLAGS_ENUM, info[FLD_ENUM_MOD]) then
                        if not def then error(strformat("Usage: enum.SetFlagsEnum(enumeration[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                        if validateflags(MOD_NOT_FLAGS, info[FLD_ENUM_MOD]) then error(strformat("Usage: enum.SetFlagsEnum(enumeration[, stack]) - The %s is defined as non-flags enumeration", tostring(target)), stack) end
                        info[FLD_ENUM_MOD] = turnonflags(MOD_FLAGS_ENUM, info[FLD_ENUM_MOD])
                    end
                else
                    error("Usage: enum.SetFlagsEnum(enumeration[, stack]) - The enumeration is not valid", stack)
                end
            end;

            -- Set the enumeration whether allow multiple enum name share the same value
            -- @static
            -- @member SetValueShareable
            -- @owner   enum
            -- @param   enumeration                 the enumeration
            -- @return  boolean                     true if the enumeration can share the same value
            ["SetValueShareable"]       = function(target, stack)
                local info, def         = getEnumTargetInfo(target)
                stack                   = parsestack(stack) + 1

                if info then
                    if not validateflags(MOD_SHARE_VALUE, info[FLD_ENUM_MOD]) then
                        if not def then error(strformat("Usage: enum.SetFlagsEnum(enumeration[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                        info[FLD_ENUM_MOD] = turnonflags(MOD_SHARE_VALUE, info[FLD_ENUM_MOD])
                    end
                else
                    error("Usage: enum.SetValueShareable(enumeration[, stack]) - The enumeration is not valid", stack)
                end
            end;

            --- Seal the enumeration, so it can't be re-defined
            -- @static
            -- @method  SetSealed
            -- @owner   enum
            -- @format  (enumeration[, stack])
            -- @param   enumeration                 the enumeration
            -- @param   stack                       the stack level
            ["SetSealed"]               = function(target, stack)
                local info              = getEnumTargetInfo(target)

                if info then
                    if not validateflags(MOD_SEALED_ENUM, info[FLD_ENUM_MOD]) then
                        info[FLD_ENUM_MOD] = turnonflags(MOD_SEALED_ENUM, info[FLD_ENUM_MOD])
                    end
                else
                    error("Usage: enum.SetSealed(enumeration[, stack]) - The enumeration is not valid", parsestack(stack) + 1)
                end
            end;

            --- Whether the check value contains the target flag value
            -- @static
            -- @method  ValidateFlags
            -- @owner   enum
            -- @param   target                      the target value only should be 2^n
            -- @param   check                       the check value
            -- @return  boolean                     true if the check value contains the target value
            -- @usage   print(enum.ValidateFlags(4, 7)) -- true : 7 = 1 + 2 + 4
            ["ValidateFlags"]           = PLOOP_PLATFORM_SETTINGS.TYPE_VALIDATION_DISABLED and validateflags or function(target, check, stack)
                if not (type(target) == "number" and floor(target) == target and target > 0) then
                    error("Usage: enum.ValidateFlags(target, check) - the target value must be a positive integer", parsestack(stack) + 1)
                end
                if check ~= nil and not (type(check) == "number" and floor(check) == check) then
                    error("Usage: enum.ValidateFlags(target, check) - the check value must be an integer", parsestack(stack) + 1)
                end
                return validateflags(target, check)
            end;

            --- Whether the value is the enumeration's element's name or value
            -- @static
            -- @method  ValidateValue
            -- @owner   enum
            -- @format  (enumeration, value[, onlyvalid])
            -- @param   enumeration                 the enumeration
            -- @param   value                       the value
            -- @param   onlyvalid                   if true use true instead of the error message
            -- @return  value                       the element value, nil if not pass the validation
            -- @return  errormessage                the error message if not pass
            ["ValidateValue"]           = function(target, value, onlyvalid)
                local info              = _EnumInfo[target]
                if info then
                    if info[FLD_ENUM_CACHE][value] then return value end

                    local maxv          = info[FLD_ENUM_MAXVAL]
                    if maxv and type(value) == "number" and floor(value) == value and value > 0 and value <= maxv then
                        return value
                    end

                    return nil, onlyvalid or info[FLD_ENUM_ERRMSG]
                else
                    error("Usage: enum.ValidateValue(enumeration, value) - The enumeration is not valid", 2)
                end
            end;

            --- Whether the value is an enumeration
            -- @static
            -- @method  Validate
            -- @owner   enum
            -- @param   enumeration                 the enumeration
            -- @return  enumeration                 nil if not pass the validation
            ["Validate"]                = function(target)
                return getEnumTargetInfo(target) and target or nil
            end;
        },
        __newindex                      = readonly,
        __call                          = function(self, ...)
            local visitor, env, target, definition, flag, stack  = getTypeParams(enum, tenum, ...)
            if not target then
                error("Usage: enum([env, ][name, ][definition][, stack]) - the enumeration type can't be created", stack + 1)
            elseif definition ~= nil and type(definition) ~= "table" then
                error("Usage: enum([env, ][name, ][definition][, stack]) - the definition should be a table", stack + 1)
            end

            if not _EnumInfo[target] then
                saveEnumMeta(target, initEnumInfo(target))
            end

            stack                       = stack + 1

            enum.BeginDefinition(target, stack)

            Debug("[enum] %s created", stack, tostring(target))

            local builder               = prototype.NewObject(enumbuilder)
            environment.SetNamespace(builder, target)
            environment.SetParent   (builder, visitor)

            if definition then
                builder(definition, stack)
                return target
            else
                return builder
            end
        end,
    }

    tenum                               = prototype (validatetype, {
        __index                         = PLOOP_PLATFORM_SETTINGS.NAMESPACE_NIL_VALUE_ACCESSIBLE and function(self, key) return _EnumInfo[self][FLD_ENUM_ITEMS][key] end or function(self, key)
            local value                 = _EnumInfo[self][FLD_ENUM_ITEMS][key]
            if value ~= nil then return value end
            error(strformat("The %s.%s is not existed", namespace.GetNamespaceName(self), tostring(key)), 2)
        end,
        __call                          = enum.Parse,
        __metatable                     = enum,
    })

    enumbuilder                         = prototype {
        __index                         = writeonly,
        __newindex                      = readonly,
        __call                          = function(self, definition, stack)
            stack                       = parsestack(stack) + 1
            if type(definition) ~= "table" then error("Usage: enum([env, ][name, ][stack]) {...} - The definition table is missing", stack) end

            local owner                 = environment.GetNamespace(self)
            if not owner then error("The enumeration can't be found", stack) end
            if not _EnumBuilderInfo[owner] then error(strformat("The %s's definition is finished", tostring(owner)), stack) end

            local final                 = attribute.InitDefinition(owner, ATTRTAR_ENUM, definition, nil, nil, stack)

            if type(final) == "table" then
                definition              = final
            end

            for k, v in pairs, definition do
                if type(k) == "string" then
                    enum.AddElement(owner, k, v, stack)
                elseif type(v) == "string" then
                    enum.AddElement(owner, v, v, stack)
                end
            end

            attribute.ApplyAttributes(owner, ATTRTAR_ENUM, self, nil, nil, stack)

            enum.EndDefinition(owner, stack)

            local visitor               = environment.GetParent(self)
            if visitor then environment.ImportNamespace(visitor, owner) end

            return owner
        end,
    }
end

-------------------------------------------------------------------------------
-- The classes are types that abstracted from a group of similar objects. The
-- objects generated by the classes are tables with fixed meta-tables.
--
-- A class can be defined within several parts:
--
-- i. **Method**        The methods are functions that be used by the classes
--          and their objects. Take an example :
--
--              class "Person" (function(_ENV)
--                  function SetName(self, name)
--                      self.name = name
--                  end
--
--                  function GetName(self, name)
--                      return self.name
--                  end
--              end)
--
--              Ann = Person()
--              Ann:SetName("Ann")
--              print("Hello " .. Ann:GetName()) -- Hello Ann
--
-- Like the struct, the definition body of the class _Person_ also should be a
-- function with `_ENV` as its first parameter. In the definition, the global
-- delcared functions will be registered as the class's method. Those functions
-- should use _self_ as the first parameter to receive the objects.
--
-- When the definition is done, the class object's meta-table is auto-generated
-- based on the class's definition layout. For the _Person_ class, it should be
--
--              {
--                  __index = { SetName = function, GetName = function },
--                  __metatable = Person,
--              }
--
-- The class can access the object method directly, and also could have their
-- own method - static method:
--
--              class "Color" (function(_ENV)
--                  __Static__()
--                  function FromRGB(r, g, b)
--                      -- The object construct will be talked later
--                      return Color {r = r, g = g, b = b}
--                  end
--              end)
--
--              c = Color.FromRGB(1, 0, 1)
--              print(c.r, c.g, c.b)
--
-- The static method don't use _self_ as the first parameter since it's used by
-- the class itself not its objects.
--
-- ii. **Meta-data**    The meta-data is a superset of the Lua's meta-method:
--          *  __add        the addition operation:             a + b  -- a is the object, also for the below operations
--          *  __sub        the subtraction operation:          a - b
--          *  __mul        the multiplication operation:       a * b
--          *  __div        the division operation:             a / b
--          *  __mod        the modulo operation:               a % b
--          *  __pow        the exponentiation operation:       a ^ b
--          *  __unm        the negation operation:             - a
--          *  __idiv       the floor division operation:       a // b
--          *  __band       the bitwise AND operation:          a & b
--          *  __bor        the bitwise OR operation:           a | b
--          *  __bxor       the bitwise exclusive OR operation: a~b
--          *  __bnot       the bitwise NOToperation:           ~a
--          *  __shl        the bitwise left shift operation:   a<<b
--          *  __shr        the bitwise right shift operation:  a>>b
--          *  __concat     the concatenation operation:        a..b
--          *  __len        the length operation:               #a
--          *  __eq         the equal operation:                a == b
--          *  __lt         the less than operation:            a < b
--          *  __le         the less equal operation:           a <= b
--          *  __index      The indexing access:                return a[k]
--          *  __newindex   The indexing assignment:            a[k] = v
--          *  __call       The call operation:                 a(...)
--          *  __gc         the garbage-collection
--          *  __tostring   the convert to string operation:    tostring(a)
--          *  __ipairs     the ipairs iterator:                ipairs(a)
--          *  __pairs      the pairs iterator:                 pairs(a)
--          *  __exist      the object existence checker
--          *  __field      the init object fields, must be a table
--          *  __new        the function used to generate the table that'd be converted to an object
--          *  __ctor       the object constructor
--          *  __dtor       the object destructor
--          *  __close      the to-be-closed
--
--  There are several PLoop special meta-data, here are examples :
--
--              class "Person" (function(_ENV)
--                  __ExistPerson = {}
--
--                  -- The Constructor
--                  function __ctor(self, name)
--                      print("Call the Person's constructor with " .. name)
--                      __ExistPerson[name] = self
--                      self.name = name
--                  end
--
--                  -- The existence checker
--                  function __exist(cls, name)
--                      if __ExistPerson[name] then
--                          print("An object existed with " .. name)
--                          return __ExistPerson[name]
--                      end
--                  end
--
--                  -- The destructor
--                  function __dtor(self)
--                      print("Dispose the object " .. self.name)
--                      __ExistPerson[self.name] = nil
--                  end
--              end)
--
--              o = Person("Ann")           -- Call the Person's constructor with Ann
--
--              -- true
--              print(o == Person("Ann"))   -- An object existed with Ann
--
--              o:Dispose()                 -- Dispose the object Ann
--
--              -- false
--              print(o == Person("Ann")) -- Call the Person's constructor with Ann
--
-- Here is the constructor, the destructor and an existence checker. We also
-- can find a non-declared method **Dispose**, all objects generated by classes
-- who have destructor settings will have the **Dispose** method, used to call
-- it's class, super class and the class's extended interface's destructor with
--  order to destruct the object, normally the destructor is used to release
-- the reference of the object, so the Lua can collect them.
--
-- The constructor receive the object and all the parameters, the existence
-- checker receive the class and all the parameters, and if it return a non-false
-- value, the value will be used as the object and return it directly. The
-- destructor only receive the object.
--
-- The `__new` meta is used to generate table that will be used as the object.
-- You can use it to return tables generated by other systems or you can return
-- a well inited table so the object's construction speed will be greatly
-- increased like :
--
--              class "List" (function(_ENV)
--                  function __new(cls, ...)
--                      return { ... }, true
--                  end
--              end)
--
--              v = List(1, 2, 3, 4, 5, 6)
--
-- The `__new` would recieve the class and all parameters and return a table
-- and a boolean value, if the value is true, all parameters will be discarded
-- so won't pass to the constructor. So for the List class, the `__new` meta
-- will eliminate the rehash cost of the object's initialization.
--
-- The `__field` meta is a table, contains several key-value paris to be saved
-- in the object, normally it's used with the **OBJECT_NO_RAWSEST** and the
-- **OBJECT_NO_NIL_ACCESS** options, so authors can only use existing fields to
-- to the jobs, and spell errors can be easily spotted.
--
--              PLOOP_PLATFORM_SETTINGS = { OBJECT_NO_RAWSEST   = true, OBJECT_NO_NIL_ACCESS= true, }
--
--              require "PLoop"
--
--              class "Person" (function(_ENV)
--                  __field     = {
--                      name    = "noname",
--                  }
--
--                  -- Also you can use *field* keyword since `__field` could be error spelled
--                  field {
--                      age     = 0,
--                  }
--              end)
--
--              o = Person()
--              o.name = "Ann"
--              o.age  = 12
--
--              o.nme = "King"  -- Error : The object can't accept field that named "nme"
--              print(o.gae)    -- Error : The object don't have any field that named "gae"
--
-- For the constructor and destructor, there are other formal names: the class
-- name will be used as constructor, and the **Dispose** will be used as the
-- destructor:
--
--              class "Person" (function(_ENV)
--                  -- The Constructor
--                  function Person(self, name)
--                      self.name = name
--                  end
--
--                  -- The destructor
--                  function Dispose(self)
--                  end
--              end)
--
--
-- iii. **Super class** the class can and only can have one super class, the
-- class will inherit the super class's object method, meta-datas and other
-- features(event, property and etc). If the class has override the super's
-- object method, meta-data or other features, the class can use **super**
-- keyword to access the super class's method, meta-data or feature.
--
--              class "A" (function(_ENV)
--                  -- Object method
--                  function Test(self)
--                      print("Call A's method")
--                  end
--
--                  -- Constructor
--                  function A(self)
--                      print("Call A's ctor")
--                  end
--
--                  -- Destructor
--                  function Dispose(self)
--                      print("Dispose A")
--                  end
--
--                  -- Meta-method
--                  function __call(self)
--                      print("Call A Object")
--                  end
--              end)
--
--              class "B" (function(_ENV)
--                  inherit "A"  -- also can use inherit(A)
--
--                  function Test(self)
--                      print("Call super's method ==>")
--                      super[self]:Test()
--                      super.Test(self)
--                      print("Call super's method ==<")
--                  end
--
--                  function B(self)
--                      super(self)
--                      print("Call B's ctor")
--                  end
--
--                  function Dispose(self)
--                      print("Dispose B")
--                  end
--
--                  function __call(self)
--                      print("Call B Object")
--                      super[self]:__call()
--                      super.__call(self)
--                  end
--              end)
--
--              -- Call A's ctor
--              -- Call B's ctor
--              o = B()
--
--              -- Call super's method ==>
--              -- Call A's method
--              -- Call A's method
--              -- Call super's method ==<
--              o:Test()
--
--              -- Call B Object
--              -- Call A Object
--              -- Call A Object
--              o()
--
--              -- Dispose B
--              -- Dispose A
--              o:Dispose()
--
-- From the example, here are some details:
--      * The destructor don't need call super's destructor, they are well
--  controlled by the system, so the class only need to consider itself.
--      * The constructor need call super's constructor manually, we'll learned
--  more about it within the overload system.
--      * For the object method and meta-method, we have two style to call its
--  super, `super.Test(self)` is a simple version, but if the class has multi
--  versions, we must keep using the `super[self]:Test()` code style, because
--  the super can know the object's class version before it fetch the *Test*
--  method. We'll see more about the super call style in the event and property
--  system.
--
-- @prototype   class
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- The interfaces are abstract types of functionality, it also provided the
-- multi-inheritance mechanism to the class. Like the class, it also support
-- object method, static method and meta-datas.
--
-- The class and interface can extend many other interfaces, the **super**
-- keyword also can access the extended interface's object-method and the
-- meta-methods.
--
-- The interface use `__init` instead of the `__ctor` as the interface's
-- initializer. The initializer only receive the object as it's parameter, and
-- don't like the constructor, the initializer can't be accessed by **super**
-- keyword. The method defined with the interface's name will also be used as
-- the initializer.
--
-- If you only want defined methods and features that should be implemented by
-- child interface or class, you can use `__Abstract__` on the method or the
-- feature, those abstract methods and featuers can't be accessed by **super**
-- keyword.
--
-- Let's take an example :
--
--              interface "IName" (function(self)
--                  __Abstract__()
--                  function SetName(self) end
--
--                  __Abstract__()
--                  function GetName(self) end
--
--                  -- initializer
--                  function IName(self) print("IName Init") end
--
--                  -- destructor
--                  function Dispose(self) print("IName Dispose") end
--              end)
--
--              interface "IAge" (function(self)
--                  __Abstract__()
--                  function SetAge(self) end
--
--                  __Abstract__()
--                  function GetAge(self) end
--
--                  -- initializer
--                  function IAge(self) print("IAge Init") end
--
--                  -- destructor
--                  function Dispose(self) print("IAge Dispose") end
--              end)
--
--              class "Person" (function(_ENV)
--                  extend "IName" "IAge"   -- also can use `extend(IName)(IAge)`
--
--                  -- Error: attempt to index global 'super' (a nil value)
--                  -- Since there is no super method(the IName.SetName is abstract),
--                  -- there is no super keyword can be use
--                  function SetName(self, name) super[self]:SetName(name) end
--
--                  function Person(self) print("Person Init") end
--
--                  function Dispose(self) print("Person Dispose") end
--              end)
--
--              -- Person Init
--              -- IName Init
--              -- IAge Init
--              o = Person()
--
--              -- IAge Dispose
--              -- IName Dispose
--              -- Person Dispose
--              o:Dispose()
--
-- From the example, we can see the initializers are called when object is
-- created and already passed the class's constructor. The dispose order is
-- the reverse order of the object creation. So, the class and interface should
-- only care themselves.
--
-- @prototype   interface
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                         attribute targets                         --
    -----------------------------------------------------------------------
    ATTRTAR_INTERFACE                   = attribute.RegisterTargetType("Interface")
    ATTRTAR_CLASS                       = attribute.RegisterTargetType("Class")
    ATTRTAR_METHOD                      = rawget(_PLoopEnv, "ATTRTAR_METHOD") or attribute.RegisterTargetType("Method")
    ATTRTAR_OBJECT                      = attribute.RegisterTargetType("Object")

    -----------------------------------------------------------------------
    --                         private constants                         --
    -----------------------------------------------------------------------
    -- FEATURE MODIFIER
    MOD_SEALED_IC                       = newflags(true)            -- SEALED TYPE
    MOD_FINAL_IC                        = newflags()                -- FINAL TYPE
    MOD_ABSTRACT_CLS                    = newflags()                -- ABSTRACT CLASS
    MOD_SINGLEVER_CLS                   = newflags()                -- SINGLE VERSION CLASS - NO MULTI VERSION
    MOD_ATTRFUNC_OBJ                    = newflags()                -- ENABLE FUNCTION ATTRIBUTE ON OBJECT
    MOD_NORAWSET_OBJ                    = newflags()                -- NO RAW SET FOR OBJECTS
    MOD_NONILVAL_OBJ                    = newflags()                -- NO NIL FIELD ACCESS
    MOD_NOSUPER_OBJ                     = newflags()                -- OLD SUPER ACCESS STYLE
    MOD_ANYMOUS_CLS                     = newflags()                -- HAS ANONYMOUS CLASS
    MOD_ATTROBJ_CLS                     = newflags()                -- CAN APPLY ATTRIBUTES ON OBJECTS
    MOD_TEMPLATE_IC                     = newflags()                -- AS TEMPLATE INTERFACE/CLASS
    MOD_AUTOCACHE_OBJ                   = newflags()                -- OBJECT METHOD AUTO-CACHE
    MOD_RECYCLABLE_OBJ                  = newflags()                -- DO NOT WIPE OBJECT WHEN DISPOSE, SO THEY MAY BE RECYCLABLE

    MOD_INITVAL_CLS                     = (PLOOP_PLATFORM_SETTINGS.CLASS_NO_MULTI_VERSION_CLASS  and MOD_SINGLEVER_CLS or 0) +
                                          (PLOOP_PLATFORM_SETTINGS.CLASS_NO_SUPER_OBJECT_STYLE   and MOD_NOSUPER_OBJ   or 0) +
                                          (PLOOP_PLATFORM_SETTINGS.OBJECT_NO_RAWSEST             and MOD_NORAWSET_OBJ  or 0) +
                                          (PLOOP_PLATFORM_SETTINGS.OBJECT_NO_NIL_ACCESS          and MOD_NONILVAL_OBJ  or 0)

    MOD_INITVAL_IF                      = (PLOOP_PLATFORM_SETTINGS.INTERFACE_ALL_ANONYMOUS_CLASS and MOD_ANYMOUS_CLS   or 0)

    INI_FLD_DEBUGSR                     = PLOOP_PLATFORM_SETTINGS.OBJECT_DEBUG_SOURCE or false

    -- STATIC FIELDS
    FLD_IC_STEXT                        =  1                        -- FIELD EXTEND INTERFACE START INDEX(keep 1 so we can use unpack on it)
    FLD_IC_SUPCLS                       =  newindex(0)              -- FIELD SUPER CLASS
    FLD_IC_MOD                          = -newindex()               -- FIELD MODIFIER
    FLD_IC_INIT                         = -newindex()               -- FIELD INITIALIZER
    FLD_IC_DTOR                         = -newindex()               -- FIELD DESTRUCTOR
    FLD_IC_FIELD                        = -newindex()               -- FIELD INIT FIELDS
    FLD_IC_TYPMTD                       = -newindex()               -- FIELD TYPE METHODS
    FLD_IC_TYPMTM                       = -newindex()               -- FIELD TYPE META-METHODS
    FLD_IC_TYPFTR                       = -newindex()               -- FILED TYPE FEATURES
    FLD_IC_INHRTP                       = -newindex()               -- FIELD INHERITANCE PRIORITY
    FLD_IC_REQCLS                       = -newindex()               -- FIELD REQUIR CLASS FOR INTERFACE
    FLD_IC_SUPER                        = -newindex()               -- FIELD SUPER
    FLD_IC_ANYMSCL                      = -newindex()               -- FIELD ANONYMOUS CLASS FOR INTERFACE
    FLD_IC_DEBUGSR                      = -newindex()               -- FIELD WHETHER DEBUG THE OBJECT SOURCE
    FLD_IC_TEMPPRM                      = -newindex()               -- FIELD TEMPLATE ARGUMENTS
    FLD_IC_TEMPDEF                      = -newindex()               -- FIELD TEMPlATE DEFINITION
    FLD_IC_TEMPIMP                      = -newindex()               -- FIELD TEMPLATE IMPLEMENTATION OR THE BASIC TEMPLATE CLASS
    FLD_IC_TEMPENV                      = -newindex()               -- FIELD TEMPLATE ENVIRONMENT

    -- CACHE FIELDS
    FLD_IC_STAFTR                       = -newindex()               -- FIELD STATIC TYPE FEATURES
    FLD_IC_OBJMTD                       = -newindex()               -- FIELD OBJECT METHODS
    FLD_IC_OBJMTM                       = -newindex()               -- FIELD OBJECT META-METHODS
    FLD_IC_OBJFTR                       = -newindex()               -- FIELD OBJECT FEATURES
    FLD_IC_OBJFLD                       = -newindex()               -- FIELD OBJECT INIT-FIELDS
    FLD_IC_ONEABS                       = -newindex()               -- FIELD ONE ABSTRACT-METHOD INTERFACE
    FLD_IC_SUPINFO                      = -newindex()               -- FIELD INFO CACHE FOR SUPER CLASS & EXTEND INTERFACES
    FLD_IC_SUPMTD                       = -newindex()               -- FIELD SUPER METHOD & META-METHODS
    FLD_IC_SUPFTR                       = -newindex()               -- FIELD SUPER FEATURE

    -- Ctor & Dispose
    FLD_IC_OBCTOR                       = 10000                     -- FIELD THE OBJECT CONSTRUCTOR
    FLD_IC_ENDISP                       = FLD_IC_OBCTOR - 1         -- FIELD ALL EXTEND INTERFACE DISPOSE END INDEX
    FLD_IC_STINIT                       = FLD_IC_OBCTOR + 1         -- FIELD ALL EXTEND INTERFACE INITIALIZER START INDEX

    -- Inheritance priority
    INRT_PRIORITY_FINAL                 =  1
    INRT_PRIORITY_NORMAL                =  0
    INRT_PRIORITY_ABSTRACT              = -1

    -- Flags for object accessing
    FLG_IC_OBJMTD                       = newflags(true)            -- HAS OBJECT METHOD
    FLG_IC_OBJFTR                       = newflags()                -- HAS OBJECT FEATURE
    FLG_IC_IDXFUN                       = newflags()                -- HAS INDEX FUNCTION
    FLG_IC_IDXTBL                       = newflags()                -- HAS INDEX TABLE
    FLG_IC_NEWIDX                       = newflags()                -- HAS NEW INDEX
    FLG_IC_OMDATR                       = newflags()                -- ENABLE OBJECT METHOD ATTRIBUTE
    FLG_IC_NRAWST                       = newflags()                -- ENABLE NO RAW SET
    FLG_IC_NNILVL                       = newflags()                -- NO NIL VALUE ACCESS
    FLG_IC_SUPACC                       = newflags()                -- SUPER OBJECT ACCESS
    FLG_IC_ATCACH                       = newflags()                -- OBJECT METHOD AUTO CACHE

    -- Flags for constructor
    FLG_IC_EXIST                        = newflags(FLG_IC_IDXFUN)   -- HAS __exist
    FLG_IC_NEWOBJ                       = newflags()                -- HAS __new
    FLG_IC_FIELD                        = newflags()                -- HAS __field
    FLG_IC_HSCLIN                       = newflags()                -- HAS CLASS INITIALIZER
    FLG_IC_HSIFIN                       = newflags()                -- NEED CALL INTERFACE'S INITIALIZER
    FLG_IC_OBJATR                       = newflags()                -- OBJECT ATTRIBUTE

    -- Meta Datas
    IC_META_DISPOB                      = "Dispose"
    IC_META_DISPOSED                    = "Disposed"
    IC_META_EXIST                       = "__exist"                 -- Existed objecj check
    IC_META_FIELD                       = "__field"                 -- Init fields
    IC_META_NEW                         = "__new"                   -- New object
    IC_META_CTOR                        = "__ctor"                  -- Constructor
    IC_META_DTOR                        = "__dtor"                  -- Destructor, short for Dispose
    IC_META_INIT                        = "__init"                  -- Initializer

    IC_META_INDEX                       = "__index"
    IC_META_NEWIDX                      = "__newindex"
    IC_META_TABLE                       = "__metatable"
    IC_META_GC                          = "__gc"

    -- Super & This
    IC_KEYWORD_SUPER                    = "super"
    OBJ_SUPER_ACCESS                    = "__PLOOP_SUPER_ACCESS"

    META_KEYS                           = {
        -- inheritable with priority
        __add                           = "__add",                  -- a + b
        __sub                           = "__sub",                  -- a - b
        __mul                           = "__mul",                  -- a * b
        __div                           = "__div",                  -- a / b
        __mod                           = "__mod",                  -- a % b
        __pow                           = "__pow",                  -- a ^ b
        __unm                           = "__unm",                  -- - a
        __idiv                          = "__idiv",                 -- // floor division
        __band                          = "__band",                 -- & bitwise and
        __bor                           = "__bor",                  -- | bitwise or
        __bxor                          = "__bxor",                 -- ~ bitwise exclusive or
        __bnot                          = "__bnot",                 -- ~ bitwise unary not
        __shl                           = "__shl",                  -- << bitwise left shift
        __shr                           = "__shr",                  -- >> bitwise right shift
        __concat                        = "__concat",               -- a..b
        __len                           = "__len",                  -- #a
        __eq                            = "__eq",                   -- a == b
        __lt                            = "__lt",                   -- a < b
        __le                            = "__le",                   -- a <= b
        __index                         = "___index",               -- return a[b]
        __newindex                      = "___newindex",            -- a[b] = v
        __call                          = "__call",                 -- a()
        __gc                            = "__gc",                   -- dispose a
        __tostring                      = "__tostring",             -- tostring(a)
        __ipairs                        = "__ipairs",               -- ipairs(a)
        __pairs                         = "__pairs",                -- pairs(a)

        -- Special meta keys
        [IC_META_EXIST]                 = IC_META_EXIST,
        [IC_META_NEW]                   = IC_META_NEW,
        [IC_META_CTOR]                  = IC_META_CTOR,

        -- Special meta keys & Non-inheritable
        [IC_META_DISPOB]                = FLD_IC_DTOR,
        [IC_META_DTOR]                  = FLD_IC_DTOR,
        [IC_META_FIELD]                 = FLD_IC_FIELD,
        [IC_META_INIT]                  = FLD_IC_INIT,
    }

    -- UNSAFE FIELD
    FLD_IC_META                         = "__PLOOP_IC_META"
    FLD_IC_TYPE                         = "__PLOOP_IC_TYPE"
    FLD_OBJ_SOURCE                      = "__PLOOP_OBJ_SOURCE"
    FLD_EXD_METHOD                      = "__PLOOP_EXD_METHOD"

    -----------------------------------------------------------------------
    --                          private storage                          --
    -----------------------------------------------------------------------
    local _ICInfo                       = PLOOP_PLATFORM_SETTINGS.UNSAFE_MODE and setmetatable({}, {__index = function(_, c) return type(c) == "table" and rawget(c, FLD_IC_META) or nil end}) or newstorage(WEAK_KEY)
    local _SuperMap                     = PLOOP_PLATFORM_SETTINGS.UNSAFE_MODE and setmetatable({}, {__index = function(_, c) return type(c) == "table" and rawget(c, FLD_IC_TYPE) or nil end}) or newstorage(WEAK_ALL)
    local _Parser                       = {}

    -- TYPE BUILDING
    local _ICBuilderInfo                = newstorage(WEAK_KEY)      -- TYPE BUILDER INFO
    local _ICBuilderInDefine            = newstorage(WEAK_KEY)
    local _ICDependsMap                 = {}                        -- CHILDREN MAP

    local _ICIndexMap                   = {}
    local _ICNewIdxMap                  = {}
    local _ClassCtorMap                 = {}

    -----------------------------------------------------------------------
    --                          private helpers                          --
    -----------------------------------------------------------------------
    local getICTargetInfo               = function (target) local info = _ICBuilderInfo[target] if info then return info, true else return _ICInfo[target], false end end

    local saveICInfo                    = PLOOP_PLATFORM_SETTINGS.UNSAFE_MODE
                                        and function(target, info, init) rawset(target, FLD_IC_META, init and info or clone(info)) end
                                        or  function(target, info, init) _ICInfo = savestorage(_ICInfo, target, init and info or clone(info)) end -- keep clone here, the memory can be reduced

    local saveSuperMap                  = PLOOP_PLATFORM_SETTINGS.UNSAFE_MOD
                                        and function(super, target) rawset(super, FLD_IC_TYPE, target) end
                                        or  function(super, target) _SuperMap = savestorage(_SuperMap, super, target) end

    -- Type Generator
    local iterSuperInfo                 = function (info, reverse)
        if reverse then
            if info[FLD_IC_SUPCLS] then
                local scache            = _Cache()
                local scls              = info[FLD_IC_SUPCLS]
                while scls do
                    local sinfo         = _ICInfo[scls]
                    tinsert(scache, sinfo)
                    scls                = sinfo[FLD_IC_SUPCLS]
                end

                local scnt              = #scache - FLD_IC_STEXT + 1
                return function(root, idx)
                    if idx >= FLD_IC_STEXT then
                        return idx - 1, _ICInfo[root[idx]], true
                    elseif scnt + idx > 0 then
                        return idx - 1, scache[scnt + idx], false
                    end
                    _Cache(scache)
                end, info, #info
            else
                return function(root, idx)
                    if idx >= FLD_IC_STEXT then
                        return idx - 1, _ICInfo[root[idx]], true
                    end
                end, info, #info
            end
        else
            return function(root, idx)
                if not tonumber(idx) then
                    local scls          = idx[FLD_IC_SUPCLS]
                    if scls then
                        idx             = _ICInfo[scls]
                        return idx, idx, false
                    end
                    idx                 = FLD_IC_STEXT - 1
                end
                idx                     = idx + 1
                local extif             = root[idx]
                if extif then return idx, _ICInfo[extif], true end
            end, info, info
        end
    end

    local getNormal                     = function (info, name, get, onlysuper)
        if not onlysuper then
            local m                     = get(info, name)
            if m and (info[FLD_IC_INHRTP] and info[FLD_IC_INHRTP][name] or INRT_PRIORITY_NORMAL) == INRT_PRIORITY_NORMAL then
                return m, info
            end
        end

        for _, sinfo in iterSuperInfo(info) do
            local m                     = get(sinfo, name)
            if m and (sinfo[FLD_IC_INHRTP] and sinfo[FLD_IC_INHRTP][name] or INRT_PRIORITY_NORMAL) == INRT_PRIORITY_NORMAL then
                return m, sinfo
            end
        end
    end

    local getSuper                      = function (info, name, get)
        local abstract

        for _, sinfo in iterSuperInfo(info) do
            local m                     = get(sinfo, name)
            if m then
                local priority          = sinfo[FLD_IC_INHRTP] and sinfo[FLD_IC_INHRTP][name] or INRT_PRIORITY_NORMAL
                if priority     == INRT_PRIORITY_NORMAL then
                    return m
                elseif priority == INRT_PRIORITY_ABSTRACT then
                    abstract            = abstract or m
                end
            end
        end

        return abstract
    end

    local getTypeMethod                 = function (info, name) info = info[FLD_IC_TYPMTD] return info and info[name] end
    local getTypeFeature                = function (info, name) info = info[FLD_IC_TYPFTR] return info and info[name] end
    local getTypeMetaMethod             = function (info, name) info = info[FLD_IC_TYPMTM] return info and info[META_KEYS[name]] end

    local getFeatureAccessor            = function (target, ftr, existed, stack)
        if not ftr then return end

        if existed and getobjectvalue(ftr, "IsShareable", true) then
            return existed
        else
            local accessor              = getobjectvalue(ftr, "GetAccessor", true, target) or ftr
            if type(safeget(accessor, "Get")) ~= "function" or type(safeget(accessor, "Set")) ~= "function" then
                error(strformat("the feature named %q is not valid", k), stack + 1)
            end
            return accessor
        end
    end

    local genSuperOrderList
        genSuperOrderList               = function (info, lst, super)
        if info then
            local scls                  = info[FLD_IC_SUPCLS]
            if scls then
                local sinfo             = _ICInfo[scls]
                genSuperOrderList(sinfo, lst, super)
                if super and (sinfo[FLD_IC_SUPFTR] or sinfo[FLD_IC_SUPMTD]) then super[scls] = sinfo end
            end

            for i = #info, FLD_IC_STEXT, -1 do
                local extif             = info[i]
                if not lst[extif] then
                    lst[extif]          = true

                    local sinfo = _ICInfo[extif]
                    genSuperOrderList(sinfo, lst, super)
                    if super and (sinfo[FLD_IC_SUPFTR] or sinfo[FLD_IC_SUPMTD]) then super[extif] = sinfo end
                    tinsert(lst, extif)
                end
            end
        end

        return lst, super
    end

    local genMethodCache                = function (source, target, objpri, inhrtp, super, info)
        for k, v in pairs, source do
            if v then
                local priority          = inhrtp and inhrtp[k] or INRT_PRIORITY_NORMAL

                if super and target[k] then
                    if (objpri[k] or INRT_PRIORITY_NORMAL) == INRT_PRIORITY_NORMAL then
                        super[k]        = target[k]
                    else
                        super[k]        = getNormal(info, k, getTypeMethod, true)
                    end
                end

                if priority >= (objpri[k] or INRT_PRIORITY_ABSTRACT) then
                    objpri[k]           = priority
                    target[k]           = v
                end
            end
        end
    end

    local genMetaMethodCache            = function (source, target, objpri, inhrtp, super, info)
        for k, v in pairs, source do
            if v and META_KEYS[k] ~= nil then
                local priority          = inhrtp and inhrtp[k] or INRT_PRIORITY_NORMAL

                if super and target[k] then
                    if (objpri[k] or INRT_PRIORITY_NORMAL) == INRT_PRIORITY_NORMAL then
                        super[k]        = target[META_KEYS[k]]
                    else
                        super[k]        = getNormal(info, k, getTypeMetaMethod, true)
                    end
                end

                if priority >= (objpri[k] or INRT_PRIORITY_ABSTRACT) then
                    objpri[k]           = priority
                    target[k]           = v
                    local mk            = META_KEYS[k]
                    if mk ~= k then
                        target[mk]      = source[mk]
                    end
                end
            end
        end
    end

    local genFeatureCache               = function (source, target, objpri, inhrtp, super, info, ftrtarget, objfeature, stack)
        stack                           = stack + 1

        for k, v in pairs, source do
            if v and not getobjectvalue(v, "IsStatic", true) then
                local priority          = inhrtp and inhrtp[k] or INRT_PRIORITY_NORMAL

                if super and target[k] then
                    if (objpri[k] or INRT_PRIORITY_NORMAL) == INRT_PRIORITY_NORMAL then
                        super[k]        = target[k]
                    else
                        local sftr, sinfo = getNormal(info, k, getTypeFeature, true)
                        if sftr then
                            super[k]    = getFeatureAccessor(ftrtarget, sftr, sinfo[FLD_IC_OBJFTR] and sinfo[FLD_IC_OBJFTR][k], stack)
                        end
                    end
                end

                if priority >= (objpri[k] or INRT_PRIORITY_ABSTRACT) then
                    objpri[k]           = priority
                    target[k]           = getFeatureAccessor(ftrtarget, v, objfeature and objfeature[k], stack)
                end
            end
        end
    end

    local reOrderExtendIF               = function (info, super)
        -- Re-generate the interface order list
        local lstIF                     = genSuperOrderList(info, _Cache(), super)
        local idxIF                     = FLD_IC_STEXT + #lstIF

        for i, extif in ipairs, lstIF, 0 do
            info[idxIF - i]             = extif
        end
        _Cache(lstIF)

        return super
    end

    local getInitICInfo                 = function (target, isclass)
        local info                      = _ICInfo[target]

        local ninfo                     = {
            -- STATIC FIELDS
            [FLD_IC_SUPCLS]             = info and info[FLD_IC_SUPCLS],
            [FLD_IC_MOD]                = info and info[FLD_IC_MOD] or isclass and MOD_INITVAL_CLS or MOD_INITVAL_IF,
            [FLD_IC_INIT]               = info and info[FLD_IC_INIT],
            [FLD_IC_DTOR]               = info and info[FLD_IC_DTOR],
            [FLD_IC_FIELD]              = info and info[FLD_IC_FIELD]  and tblclone(info[FLD_IC_FIELD],  {}),
            [FLD_IC_TYPMTD]             = info and info[FLD_IC_TYPMTD] and tblclone(info[FLD_IC_TYPMTD], {}) or false,
            [FLD_IC_TYPMTM]             = info and info[FLD_IC_TYPMTM] and tblclone(info[FLD_IC_TYPMTM], {}),
            [FLD_IC_TYPFTR]             = info and info[FLD_IC_TYPFTR] and tblclone(info[FLD_IC_TYPFTR], {}),
            [FLD_IC_INHRTP]             = info and info[FLD_IC_INHRTP] and tblclone(info[FLD_IC_INHRTP], {}),
            [FLD_IC_REQCLS]             = info and info[FLD_IC_REQCLS],
            [FLD_IC_SUPER]              = info and info[FLD_IC_SUPER],
            [FLD_IC_ANYMSCL]            = info and info[FLD_IC_ANYMSCL] or isclass and nil,
            [FLD_IC_DEBUGSR]            = info and info[FLD_IC_DEBUGSR] or isclass and INI_FLD_DEBUGSR or nil,
            [FLD_IC_TEMPPRM]            = info and info[FLD_IC_TEMPPRM],
            [FLD_IC_TEMPDEF]            = info and info[FLD_IC_TEMPDEF],
            [FLD_IC_TEMPIMP]            = info and info[FLD_IC_TEMPIMP],
            [FLD_IC_TEMPENV]            = info and info[FLD_IC_TEMPENV],
            -- CACHE FIELDS
            [FLD_IC_STAFTR]             = info and info[FLD_IC_STAFTR] and tblclone(info[FLD_IC_STAFTR], {}),
            [FLD_IC_OBJFTR]             = info and info[FLD_IC_OBJFTR] and tblclone(info[FLD_IC_OBJFTR], {}),
        }

        if info then
            for i, extif  in ipairs, info, FLD_IC_STEXT - 1 do ninfo[i] = extif end
            for k, method in pairs,  info do if not tonumber(k) then ninfo[k] = method end end
        end

        return ninfo
    end

    local genMetaIndex                  = function (info)
        local token                     = 0
        local upval                     = _Cache()
        local meta                      = info[FLD_IC_OBJMTM]

        if info[FLD_IC_SUPINFO] and not validateflags(MOD_NOSUPER_OBJ, info[FLD_IC_MOD]) then
            token                       = turnonflags(FLG_IC_SUPACC, token)
            tinsert(upval, info[FLD_IC_SUPINFO])
        end

        if info[FLD_IC_OBJMTD] then
            token                       = turnonflags(FLG_IC_OBJMTD, token)
            tinsert(upval, info[FLD_IC_OBJMTD])

            if not validateflags(FLG_IC_SUPACC, token) and validateflags(MOD_AUTOCACHE_OBJ, info[FLD_IC_MOD]) then
                token                   = turnonflags(FLG_IC_ATCACH, token)
                tinsert(upval, rawset)
            end
        end

        if info[FLD_IC_OBJFTR] then
            token                       = turnonflags(FLG_IC_OBJFTR, token)
            tinsert(upval, info[FLD_IC_OBJFTR])
        end

        local data                      = info[FLD_IC_TYPMTM] and info[FLD_IC_TYPMTM][IC_META_INDEX] or meta[META_KEYS[IC_META_INDEX]]
        if data then
            if type(data) == "function" then
                token                   = turnonflags(FLG_IC_IDXFUN, token)
            else
                token                   = turnonflags(FLG_IC_IDXTBL, token)
            end
            tinsert(upval, data)
        end

        if validateflags(MOD_NONILVAL_OBJ, info[FLD_IC_MOD]) then
            token                       = turnonflags(FLG_IC_NNILVL, token)
        end

        -- No __index generated
        if token == 0                                       then meta[IC_META_INDEX] = fakefunc             return _Cache(upval) end
        -- Use the object method cache directly
        if token == FLG_IC_OBJMTD                           then meta[IC_META_INDEX] = info[FLD_IC_OBJMTD]  return _Cache(upval) end
        -- Use the custom __index directly
        if token == FLG_IC_IDXFUN or token == FLG_IC_IDXTBL then meta[IC_META_INDEX] = data                 return _Cache(upval) end

        if not _ICIndexMap[token] then
            local head                  = _Cache()
            local body                  = _Cache()
            local apis                  = _Cache()

            tinsert(body, "")                       -- remain for shareable variables
            tinsert(body, "return function(%s)")    -- remain for special variables
            tinsert(body, [[return function(self, key)]])

            if validateflags(FLG_IC_SUPACC, token) then
                uinsert(apis, "rawget")
                uinsert(apis, "error")
                uinsert(apis, "strformat")
                uinsert(apis, "tostring")
                tinsert(head, "spinfo")
                tinsert(body, [[
                    local sp = rawget(self, "]] .. OBJ_SUPER_ACCESS .. [[")
                    if sp then
                        self["]] .. OBJ_SUPER_ACCESS .. [["] = nil
                        local sinfo     = spinfo[sp]
                        if sinfo then
                            local mtd   = sinfo[]] .. FLD_IC_SUPMTD .. [[]
                            mtd         = mtd and mtd[key]
                            if mtd then return mtd end

                            local ftr   = sinfo[]] .. FLD_IC_SUPFTR .. [[]
                            ftr         = ftr and ftr[key]
                            if ftr then return ftr:Get(self) end
                        end

                        error(strformat("No super method or feature named %q can be found", tostring(key)), 2)
                    end
                ]])
            end

            if validateflags(FLG_IC_OBJMTD, token) then
                tinsert(head, "methods")
                if validateflags(FLG_IC_ATCACH, token) then
                    tinsert(head, "rawset")
                    tinsert(body, [[
                        local mtd       = methods[key]
                        if mtd then rawset(self, key, mtd) return mtd end
                    ]])
                else
                    tinsert(body, [[
                        local mtd       = methods[key]
                        if mtd then return mtd end
                    ]])
                end
            end

            if validateflags(FLG_IC_OBJFTR, token) then
                tinsert(head, "features")
                tinsert(body, [[
                    local ftr           = features[key]
                    if ftr then return ftr:Get(self) end
                ]])
            end

            if validateflags(FLG_IC_IDXFUN, token) then
                tinsert(head, "_index")
                if validateflags(FLG_IC_NNILVL, token) then
                    tinsert(body, [[
                        local val       = _index(self, key, 2)
                        if val ~= nil then return val end
                    ]])
                else
                    tinsert(body, [[
                        local val       = _index(self, key, 2)
                        return val
                    ]])
                end
            elseif validateflags(FLG_IC_IDXTBL, token) then
                tinsert(head, "_index")
                if validateflags(FLG_IC_NNILVL, token) then
                    tinsert(body, [[
                        local val       = _index[key]
                        if val ~= nil then return val end
                    ]])
                else
                    tinsert(body, [[return _index[key] ]])
                end
            end

            if validateflags(FLG_IC_NNILVL, token) then
                uinsert(apis, "error")
                uinsert(apis, "strformat")
                uinsert(apis, "tostring")
                tinsert(body, [[error(strformat("The object don't have any field that named %q", tostring(key)), 2)]])
            end

            tinsert(body, [[end]])
            tinsert(body, [[end]])

            if #apis > 0 then
                local declare           = tblconcat(apis, ", ")
                body[1]                 = strformat("local %s = %s", declare, declare)
            end

            body[2]                     = strformat(body[2], #head > 0 and tblconcat(head, ", ") or "")

            _ICIndexMap[token]          = loadsnippet(tblconcat(body, "\n"), "Class_Index_" .. token, _PLoopEnv)()

            if #head == 0 then
                _ICIndexMap[token]      = _ICIndexMap[token]()
            end

            _Cache(head)
            _Cache(body)
            _Cache(apis)
        end

        if #upval > 0 then
            meta[IC_META_INDEX]         = _ICIndexMap[token](unpack(upval))
        else
            meta[IC_META_INDEX]         = _ICIndexMap[token]
        end

        _Cache(upval)
    end

    local genMetaNewIndex               = function (info)
        local token                     = 0
        local upval                     = _Cache()
        local meta                      = info[FLD_IC_OBJMTM]

        if info[FLD_IC_SUPINFO] and not validateflags(MOD_NOSUPER_OBJ, info[FLD_IC_MOD]) then
            token                       = turnonflags(FLG_IC_SUPACC, token)
            tinsert(upval, info[FLD_IC_SUPINFO])
        end

        if info[FLD_IC_OBJFTR] and next(info[FLD_IC_OBJFTR]) then
            token                       = turnonflags(FLG_IC_OBJFTR, token)
            tinsert(upval, info[FLD_IC_OBJFTR])
        end

        if validateflags(MOD_ATTRFUNC_OBJ, info[FLD_IC_MOD]) then
            token                       = turnonflags(FLG_IC_OMDATR, token)
        end

        local data                      = meta[META_KEYS[IC_META_NEWIDX]]

        if data then
            token                       = turnonflags(FLG_IC_NEWIDX, token)
            tinsert(upval, data)
        elseif validateflags(MOD_NORAWSET_OBJ, info[FLD_IC_MOD]) then
            token                       = turnonflags(FLG_IC_NRAWST, token)

            -- Still can override the object method
            if not validateflags(FLG_IC_OMDATR, token) and info[FLD_IC_OBJMTD] then
                token                   = turnonflags(FLG_IC_OBJMTD, token)
                tinsert(upval, info[FLD_IC_OBJMTD])
            end
        end

        -- No __newindex generated
        if token == 0               then meta[IC_META_NEWIDX] = nil  return _Cache(upval) end
        -- Use the custom __newindex directly
        if token == FLG_IC_NEWIDX   then meta[IC_META_NEWIDX] = data return _Cache(upval) end

        if not _ICNewIdxMap[token] then
            local head                  = _Cache()
            local body                  = _Cache()
            local apis                  = _Cache()

            tinsert(body, "")                       -- remain for shareable variables
            tinsert(body, "return function(%s)")    -- remain for special variables
            tinsert(body, [[return function(self, key, value)]])

            if validateflags(FLG_IC_SUPACC, token) then
                uinsert(apis, "rawget")
                uinsert(apis, "error")
                uinsert(apis, "strformat")
                uinsert(apis, "tostring")
                tinsert(head, "spinfo")
                tinsert(body, [[
                    local sp = rawget(self, "]] .. OBJ_SUPER_ACCESS .. [[")
                    if sp then
                        self["]] .. OBJ_SUPER_ACCESS .. [["] = nil
                        local sinfo     = spinfo[sp]
                        if sinfo then
                            local ftr   = sinfo[]] .. FLD_IC_SUPFTR .. [[]
                            ftr         = ftr and ftr[key]
                            if ftr then ftr:Set(self, value, 2) return end
                        end

                        error(strformat("No super feature named %q can be found", tostring(key)), 2)
                    end
                ]])
            end

            if validateflags(FLG_IC_OBJFTR, token) then
                tinsert(head, "feature")
                tinsert(body, [[
                    local ftr           = feature[key]
                    if ftr then ftr:Set(self, value, 2) return end
                ]])
            end

            if validateflags(FLG_IC_NRAWST, token) and (validateflags(FLG_IC_OMDATR, token) or validateflags(FLG_IC_OBJMTD, token)) then
                tinsert(body, [[
                    local assign        = false
                ]])
            end

            if validateflags(FLG_IC_OMDATR, token) or validateflags(FLG_IC_OBJMTD, token) then
                uinsert(apis, "type")
                tinsert(body, [[
                    if type(value) == "function" then
                ]])

                if validateflags(FLG_IC_OMDATR, token) then
                    uinsert(apis, "attribute")
                    uinsert(apis, "ATTRTAR_FUNCTION")

                    if validateflags(FLG_IC_NRAWST, token) then
                        tinsert(body, [[
                        assign          = true
                        ]])
                    end

                    tinsert(body, [[
                        if attribute.HaveRegisteredAttributes() then
                            attribute.SaveAttributes(value, ATTRTAR_FUNCTION, 2)
                            local ret   = attribute.InitDefinition(value, ATTRTAR_FUNCTION, value, self, key, 2)
                            if value ~= ret then
                                attribute.ToggleTarget(value, ret)
                                value   = ret
                            end
                            attribute.ApplyAttributes (value, ATTRTAR_FUNCTION, nil, self, key, 2)
                            attribute.AttachAttributes(value, ATTRTAR_FUNCTION, self, key, 2)
                        end
                    ]])
                else
                    tinsert(head, "methods")
                    tinsert(body, [[
                        if methods[key] then
                            assign      = true
                        end
                    ]])
                end

                tinsert(body, [[
                    end
                ]])
            end

            if validateflags(FLG_IC_NRAWST, token) and (validateflags(FLG_IC_OMDATR, token) or validateflags(FLG_IC_OBJMTD, token)) then
                tinsert(body, [[
                    if assign then
                ]])
            end

            if not validateflags(FLG_IC_NRAWST, token) or validateflags(FLG_IC_OMDATR, token) or validateflags(FLG_IC_OBJMTD, token) then
                if validateflags(FLG_IC_NEWIDX, token) then
                    tinsert(head, "_newindex")
                    tinsert(body, [[
                        _newindex(self, key, value, 2)
                    ]])
                else
                    uinsert(apis, "rawset")
                    tinsert(body, [[
                        rawset(self, key, value)
                    ]])
                end
            end

            if validateflags(FLG_IC_NRAWST, token) then
                uinsert(apis, "error")
                uinsert(apis, "strformat")
                uinsert(apis, "tostring")
                if validateflags(FLG_IC_OMDATR, token) or validateflags(FLG_IC_OBJMTD, token) then
                    tinsert(body, [[
                    else
                        error(strformat("The object can't accept field that named %q", tostring(key)), 2)
                    end
                    ]])
                else
                    tinsert(body, [[
                    error(strformat("The object can't accept field that named %q", tostring(key)), 2)
                    ]])
                end
            end

            tinsert(body, [[end]])
            tinsert(body, [[end]])

            if #apis > 0 then
                local declare           = tblconcat(apis, ", ")
                body[1]                 = strformat("local %s = %s", declare, declare)
            end

            body[2]                     = strformat(body[2], #head > 0 and tblconcat(head, ", ") or "")

            _ICNewIdxMap[token]         = loadsnippet(tblconcat(body, "\n"), "Class_NewIndex_" .. token, _PLoopEnv)()

            if #head == 0 then
                _ICNewIdxMap[token]     = _ICNewIdxMap[token]()
            end

            _Cache(head)
            _Cache(body)
            _Cache(apis)
        end

        if #upval > 0 then
            meta[IC_META_NEWIDX]        = _ICNewIdxMap[token](unpack(upval))
        else
            meta[IC_META_NEWIDX]        = _ICNewIdxMap[token]
        end

        _Cache(upval)
    end

    local genConstructor                = function (target, info)
        if validateflags(MOD_ABSTRACT_CLS, info[FLD_IC_MOD]) then
            local msg                   = strformat("The %s is abstract, can't be used to create objects", tostring(target))
            info[FLD_IC_OBCTOR] = function() throw(msg) end
            return
        end

        local token                     = 0
        local upval                     = _Cache()
        local meta                      = info[FLD_IC_OBJMTM]

        tinsert(upval, meta)

        if meta[IC_META_EXIST] or meta[IC_META_NEW] then
            tinsert(upval, target)
        end

        if meta[IC_META_EXIST] then
            token                       = turnonflags(FLG_IC_EXIST, token)
            tinsert(upval, meta[IC_META_EXIST])
        end

        if meta[IC_META_NEW] then
            token                       = turnonflags(FLG_IC_NEWOBJ, token)
            tinsert(upval, meta[IC_META_NEW])
        end

        if info[FLD_IC_OBJFLD] then
            token                       = turnonflags(FLG_IC_FIELD, token)
            tinsert(upval, info[FLD_IC_OBJFLD])
        end

        if meta[IC_META_CTOR] then
            token                       = turnonflags(FLG_IC_HSCLIN, token)
            tinsert(upval, meta[IC_META_CTOR])
        end

        if info[FLD_IC_STINIT] then
            token                       = turnonflags(FLG_IC_HSIFIN, token)
            local i                     = FLD_IC_STINIT
            while info[i + 1] do i      = i + 1 end
            tinsert(upval, i)
        end

        if validateflags(MOD_ATTROBJ_CLS, info[FLD_IC_MOD]) then
            token                       = turnonflags(FLG_IC_OBJATR, token)
        end

        if not _ClassCtorMap[token] then
            local head                  = _Cache()
            local body                  = _Cache()
            local apis                  = _Cache()
            local hasctor               = validateflags(FLG_IC_HSCLIN, token)

            uinsert(apis, "setmetatable")

            tinsert(head, "objmeta")

            tinsert(body, "")                       -- remain for shareable variables
            tinsert(body, "return function(%s)")    -- remain for special variables
            if hasctor then
                tinsert(body, [[return function(info, ...)]])
            else
                tinsert(body, [[return function(info, first, ...)]])
            end

            tinsert(body, [[local obj]])

            if validateflags(FLG_IC_EXIST, token) or validateflags(FLG_IC_NEWOBJ, token) then
                tinsert(head, "cls")
            end

            if validateflags(FLG_IC_EXIST, token) then
                tinsert(head, "extobj")
                if hasctor then
                    tinsert(body, [[obj = extobj(cls, ...) if obj ~= nil then return obj end]])
                else
                    tinsert(body, [[obj = extobj(cls, first, ...) if obj ~= nil then return obj end]])
                end
            end

            if validateflags(FLG_IC_NEWOBJ, token) then
                uinsert(apis, "type")
                tinsert(head, "newobj")
                tinsert(body, [[local cutargs]])
                if hasctor then
                    tinsert(body, [[obj, cutargs = newobj(cls, ...)]])
                else
                    tinsert(body, [[obj, cutargs = newobj(cls, first, ...)]])
                end
                tinsert(body, [[if type(obj) ~= "table" then obj, cutargs = nil, false end]])
            end

            if not hasctor then
                uinsert(apis, "select")
                uinsert(apis, "type")
                uinsert(apis, "getmetatable")

                if validateflags(FLG_IC_NEWOBJ, token) then
                    tinsert(body, [[local init = not cutargs and select("#", ...) == 0 and type(first) == "table" and getmetatable(first) == nil and first or nil]])
                else
                    tinsert(body, [[local init = select("#", ...) == 0 and type(first) == "table" and getmetatable(first) == nil and first or nil]])
                end
            end

            if validateflags(FLG_IC_NEWOBJ, token) then
                tinsert(body, [[obj     = obj or {}]])
            else
                tinsert(body, [[obj     = {}]])
            end

            if validateflags(FLG_IC_FIELD, token) then
                uinsert(apis, "tblclone")
                tinsert(head, "fields")
                tinsert(body, [[tblclone(fields, obj, true, false)]])
            end

            if validateflags(FLG_IC_NEWOBJ, token) then
                uinsert(apis, "pcall")
                uinsert(apis, "strformat")
                uinsert(apis, "tostring")
                uinsert(apis, "throw")
                uinsert(apis, "getmetatable")
                tinsert(body, [[if getmetatable(obj) ~= cls and not pcall(setmetatable, obj, objmeta) then throw(strformat("The %s's __new meta-method doesn't provide a valid table as object", tostring(objmeta["__metatable"]))) end]])
            else
                tinsert(body, [[setmetatable(obj, objmeta)]])
            end

            if hasctor then
                tinsert(head, "clinit")
                if validateflags(FLG_IC_NEWOBJ, token) then
                    tinsert(body, [[if cutargs then clinit(obj) else clinit(obj, ...) end]])
                else
                    tinsert(body, [[clinit(obj, ...)]])
                end
            else
                uinsert(apis, "pcall")
                uinsert(apis, "loadinittable")
                uinsert(apis, "strmatch")
                uinsert(apis, "throw")
                tinsert(body, [[if init then local ok, msg = pcall(loadinittable, obj, init) if not ok then throw(strmatch(msg, "%d+:%s*(.-)$") or msg) end end]])
            end

            if validateflags(FLG_IC_OBJATR, token) then
                tinsert(body, [[
                    attribute.SaveAttributes(obj, ATTRTAR_OBJECT)
                    attribute.ApplyAttributes(obj, ATTRTAR_OBJECT)
                ]])
            end

            if validateflags(FLG_IC_HSIFIN, token) then
                tinsert(head, "_max")
                tinsert(body, [[for i = ]] .. FLD_IC_STINIT .. [[, _max do info[i](obj) end]])
            end

            if validateflags(FLG_IC_OBJATR, token) then
                tinsert(body, [[
                    attribute.AttachAttributes(obj, ATTRTAR_OBJECT)
                ]])
            end

            tinsert(body, [[return obj end end]])

            if #apis > 0 then
                local declare           = tblconcat(apis, ", ")
                body[1]                 = strformat("local %s = %s", declare, declare)
            end

            body[2]                     = strformat(body[2], #head > 0 and tblconcat(head, ", ") or "")

            _ClassCtorMap[token]        = loadsnippet(tblconcat(body, "\n"), "Class_Ctor_" .. token, _PLoopEnv)()

            if #head == 0 then
                _ClassCtorMap[token]    = _ClassCtorMap[token]()
            end

            _Cache(head)
            _Cache(body)
            _Cache(apis)
        end

        if #upval > 0 then
            info[FLD_IC_OBCTOR]         = _ClassCtorMap[token](unpack(upval))
        else
            info[FLD_IC_OBCTOR]         = _ClassCtorMap[token]
        end

        _Cache(upval)
    end

    local genTypeCaches                 = function (target, info, stack)
        local isclass                   = class.Validate(target)
        local realCls                   = isclass and not class.IsAbstract(target)
        local objpri                    = _Cache()
        local objmeta                   = _Cache()
        local objftr                    = _Cache()
        local objmtd                    = _Cache()
        local objfld                    = realCls and _Cache()

        -- Re-generate the extended interfaces order list
        local spcache                   = reOrderExtendIF(info, realCls and _Cache())

        stack                           = stack + 1

        -- The init & dispose link for extended interfaces & super classes
        local initIdx                   = FLD_IC_STINIT
        local dispIdx                   = FLD_IC_ENDISP

        if realCls then
            -- Save super class's dtor
            for _, sinfo, isextIF in iterSuperInfo(info, true) do
                if not isextIF and sinfo[FLD_IC_DTOR] then
                    info[dispIdx]       = sinfo[FLD_IC_DTOR]
                    dispIdx             = dispIdx - 1
                end
            end

            -- Save class's dtor
            if info[FLD_IC_DTOR] then
                info[dispIdx]           = info[FLD_IC_DTOR]
                dispIdx                 = dispIdx - 1
            end
        end

        -- Save super to caches
        for _, sinfo, isextIF in iterSuperInfo(info, true) do
            local inhrtp                = sinfo[FLD_IC_INHRTP]

            if sinfo[FLD_IC_TYPMTD] then
                genMethodCache(sinfo[FLD_IC_TYPMTD], objmtd, objpri, inhrtp)
            end

            if sinfo[FLD_IC_TYPMTM] then
                genMetaMethodCache(sinfo[FLD_IC_TYPMTM], objmeta, objpri, inhrtp)
            end

            if sinfo[FLD_IC_TYPFTR] then
                genFeatureCache(sinfo[FLD_IC_TYPFTR], objftr, objpri, inhrtp, nil, nil, target, sinfo[FLD_IC_OBJFTR], stack)
            end

            if realCls then
                -- Save fields
                if sinfo[FLD_IC_FIELD] then
                    tblclone(sinfo[FLD_IC_FIELD], objfld, false, true)
                end

                if isextIF then
                    -- Save initializer
                    if sinfo[FLD_IC_INIT] then
                        info[initIdx]   = sinfo[FLD_IC_INIT]
                        initIdx         = initIdx + 1
                    end

                    -- Save dtor
                    if sinfo[FLD_IC_DTOR] then
                        info[dispIdx]   = sinfo[FLD_IC_DTOR]
                        dispIdx         = dispIdx - 1
                    end
                end
            end
        end

        -- Save self to caches
        local inhrtp                    = info[FLD_IC_INHRTP]
        local super                     = _Cache()

        if info[FLD_IC_TYPMTD] then
            genMethodCache(info[FLD_IC_TYPMTD], objmtd, objpri, inhrtp, super, info)
        end

        if info[FLD_IC_TYPMTM] then
            genMetaMethodCache(info[FLD_IC_TYPMTM], objmeta, objpri, inhrtp, super, info)
        end

        if next(super) then info[FLD_IC_SUPMTD] = super else _Cache(super) end

        if info[FLD_IC_TYPFTR] then
            super                       = _Cache()
            genFeatureCache(info[FLD_IC_TYPFTR], objftr, objpri, inhrtp, super, info, target, info[FLD_IC_OBJFTR], stack)
            if next(super) then info[FLD_IC_SUPFTR] = super else _Cache(super) end

            -- Check static features
            local staftr                = info[FLD_IC_STAFTR] or _Cache()

            for name, ftr in pairs, info[FLD_IC_TYPFTR] do
                if getobjectvalue(ftr, "IsStatic", true) then
                    staftr[name]        = getFeatureAccessor(target, ftr, staftr[name], stack)
                end
            end

            if not next(staftr) then _Cache(staftr) staftr = nil end
            info[FLD_IC_STAFTR]         = staftr
        end

        if realCls and info[FLD_IC_FIELD] then
            tblclone(info[FLD_IC_FIELD], objfld, false, true)
        end

        -- Generate super if needed, include the interface
        if not info[FLD_IC_SUPER] and (info[FLD_IC_SUPFTR] or info[FLD_IC_SUPMTD]) then
            info[FLD_IC_SUPER]          = prototype.NewProxy(isclass and tsuperclass or tsuperinterface)
            saveSuperMap(info[FLD_IC_SUPER], target)
        end

        -- Save caches to fields
        if not isclass then
            -- Check one abstract method
            local absmtd
            for k, v in pairs, objmtd do
                if objpri[k]   == INRT_PRIORITY_ABSTRACT then
                    if absmtd  == nil then
                        absmtd          = k
                    else
                        absmtd          = false
                        break
                    end
                end
            end
            info[FLD_IC_ONEABS]         = absmtd or nil

            _Cache(objpri)
            _Cache(objmeta)
            _Cache(objmtd)
            if not next(objftr) then _Cache(objftr) objftr = nil end

            info[FLD_IC_OBJFTR]         = objftr

            -- Gen anonymous class
            if validateflags(MOD_ANYMOUS_CLS, info[FLD_IC_MOD]) and not info[FLD_IC_ANYMSCL] then
                local aycls             = prototype.NewProxy(tclass)
                local ainfo             = getInitICInfo(aycls, true)

                ainfo[FLD_IC_MOD]       = turnonflags(MOD_SEALED_IC, ainfo[FLD_IC_MOD])
                ainfo[FLD_IC_STEXT]     = target

                -- Register the _ICDependsMap
                _ICDependsMap[target]   = _ICDependsMap[target] or {}
                tinsert(_ICDependsMap[target], aycls)

                -- Save the anonymous class
                saveICInfo(aycls, ainfo)

                info[FLD_IC_ANYMSCL]    = aycls
            end
        else
            if not realCls then
                _Cache(objpri)
                _Cache(objmeta)
                _Cache(objmtd)
                if not next(objftr) then _Cache(objftr) objftr = nil end

                info[FLD_IC_OBJMTM]     = nil
                info[FLD_IC_OBJFTR]     = objftr
                info[FLD_IC_OBJMTD]     = nil
                info[FLD_IC_OBJFLD]     = nil
            else
                -- Set object's prototype
                objmeta[IC_META_TABLE]  = target

                -- Auto-gen dispose for object methods
                local FLD_IC_STDISP     = dispIdx + 1
                if FLD_IC_STDISP <= FLD_IC_ENDISP then
                    objmtd[IC_META_DISPOB]  = validateflags(MOD_RECYCLABLE_OBJ, info[FLD_IC_MOD])
                        and function(self)
                            for i = FLD_IC_STDISP, FLD_IC_ENDISP do info[i](self) end
                        end or function(self)
                            if rawget(self, IC_META_DISPOSED) == true then return end
                            for i = FLD_IC_STDISP, FLD_IC_ENDISP do info[i](self) end
                            rawset(wipe(self), IC_META_DISPOSED, true)
                        end

                    if not objmeta[IC_META_GC] and PLOOP_PLATFORM_SETTINGS.USE_DISPOSE_AS_META_GC then
                        objmeta[IC_META_GC] = objmtd[IC_META_DISPOB]
                    end
                end

                -- Save self super info
                if info[FLD_IC_SUPER] then
                    spcache[target]     = info
                end

                _Cache(objpri)
                if not next(objmtd) then _Cache(objmtd) objmtd = nil end
                if not next(objfld) then _Cache(objfld) objfld = nil end
                if not next(objftr) then _Cache(objftr) objftr = nil end
                if not next(spcache)then _Cache(spcache)spcache= nil end

                info[FLD_IC_SUPINFO]    = spcache
                info[FLD_IC_OBJMTM]     = objmeta
                info[FLD_IC_OBJFTR]     = objftr
                info[FLD_IC_OBJMTD]     = objmtd or false
                info[FLD_IC_OBJFLD]     = objfld

                genMetaIndex(info)
                genMetaNewIndex(info)

                -- Copy the metatable if the class is single version
                if class.IsSingleVersion(target) then
                    local oinfo         = _ICInfo[target]

                    if oinfo and oinfo[FLD_IC_OBJMTM] then
                        info[FLD_IC_OBJMTM] = tblclone(objmeta, oinfo[FLD_IC_OBJMTM], false, true)
                    end
                end
            end
            genConstructor(target, info)
        end
    end

    local reDefineChildren              = function (target, stack)
        if _ICDependsMap[target] then
            for _, child in ipairs, _ICDependsMap[target], 0 do
                if not _ICBuilderInfo[child] then  -- Not in definition mode
                    if interface.Validate(child) then
                        interface.RefreshDefinition(child, stack + 1)
                    else
                        class.RefreshDefinition(child, stack + 1)
                    end
                end
            end
        end
    end

    local saveObjectMethod
        saveObjectMethod                = function (target, name, func, child)
        local info, def                 = getICTargetInfo(target)
        if def then return end

        --if child and info[FLD_IC_TYPMTD] and info[FLD_IC_TYPMTD][name] ~= nil and (info[FLD_IC_TYPMTD][name] == false or not (info[FLD_IC_INHRTP] and info[FLD_IC_INHRTP][name] == INRT_PRIORITY_ABSTRACT)) then return end
        if child and info[FLD_IC_TYPMTD] and info[FLD_IC_TYPMTD][name] and (not (info[FLD_IC_INHRTP] and info[FLD_IC_INHRTP][name] == INRT_PRIORITY_ABSTRACT)) then return end

        if info[FLD_IC_OBJMTD] ~= nil then
            info[FLD_IC_OBJMTD]         = savestorage(info[FLD_IC_OBJMTD] or {}, name, func)
            genMetaIndex(info)
        end

        if _ICDependsMap[target] then
            for _, child in ipairs, _ICDependsMap[target], 0 do
                saveObjectMethod(child, name, func, true)
            end
        end
    end

    -- Shared APIS
    local preDefineCheck                = function (target, name, stack, allowDefined)
        local info, def                 = getICTargetInfo(target)
        stack                           = parsestack(stack)
        if not info then return nil, nil, stack, "the target is not valid" end
        if not allowDefined and not def then return nil, nil, stack, strformat("the %s's definition is finished", tostring(target)) end
        if not name or type(name) ~= "string" then return info, nil, stack, "the name must be a string" end
        name                            = strtrim(name)
        if name == "" then return info, nil, stack, "the name can't be empty" end
        return info, name, stack, nil, def
    end

    local addSuperType                  = function (info, target, supType)
        local isIF                      = interface.Validate(supType)

        -- Clear _ICDependsMap for old extend interfaces
        for i = #info, FLD_IC_STEXT, -1 do
            local extif                 = info[i]

            if interface.IsSubType(supType, extif) then
                for k, v in ipairs, _ICDependsMap[extif], 0 do
                    if v == target then tremove(_ICDependsMap[extif], k) break end
                end
            end

            if isIF then info[i + 1]    = extif end
        end

        if isIF then
            info[FLD_IC_STEXT]          = supType
        else
            info[FLD_IC_SUPCLS]         = supType
        end

        -- Register the _ICDependsMap
        _ICDependsMap[supType]          = _ICDependsMap[supType] or {}
        tinsert(_ICDependsMap[supType], target)

        -- Re-generate the interface order list
        reOrderExtendIF(info)
    end

    local addExtend                     = function (target, extendIF, stack)
        local info, _, stack, msg       = preDefineCheck(target, nil, stack)

        if not info then return msg, stack end
        if not interface.Validate(extendIF) then return "the extendinterface must be an interface", stack end
        if interface.IsFinal(extendIF) then return strformat("the %s is marked as final, can't be extended", tostring(extendIF)), stack end

        -- Check if already extended
        if interface.IsSubType(target, extendIF) then return end

        -- Check the extend interface's require class
        local reqcls                    = interface.GetRequireClass(extendIF)

        if class.Validate(target) then
            if reqcls and not class.IsSubType(target, reqcls) then
                return strformat("the class must be %s's sub-class", tostring(reqcls)), stack
            end
        elseif interface.IsSubType(extendIF, target) then
            return "the extend interface is a sub type of the interface", stack
        elseif reqcls then
            local rcls                  = interface.GetRequireClass(target)

            if rcls then
                if class.IsSubType(reqcls, rcls) then
                    interface.SetRequireClass(target, reqcls, stack + 2)
                elseif not class.IsSubType(rcls, reqcls) then
                    return strformat("the interface's require class must be %s's sub-class", tostring(reqcls)), stack
                end
            else
                interface.SetRequireClass(target, reqcls, stack + 2)
            end
        end

        -- Add the extend interface
        addSuperType(info, target, extendIF)
    end

    local addFields                     = function (target, fields, stack)
        local info, name, stack, msg    = preDefineCheck(target, nil, stack)
        if not info then return msg, stack end
        if type(fields) ~= "table" then return "the fields must be a table", stack end

        info[FLD_IC_FIELD]              = tblclone(fields, info[FLD_IC_FIELD] or _Cache(), true, true)
    end

    local addMethod                     = function (target, name, func, stack)
        local info, name, stack, msg, def = preDefineCheck(target, name, stack, true)

        if msg then return msg, stack end

        if META_KEYS[name] ~= nil then return strformat("the %s can't be used as method name", name), stack end
        if type(func) ~= "function" then return "the func must be a function", stack end

        local typmtd                    = info[FLD_IC_TYPMTD]
        if not def and (
            typmtd and (typmtd[name] or (typmtd[name] == false and info[name]))
            or info[FLD_IC_TYPFTR] and info[FLD_IC_TYPFTR][name]
            or info[FLD_IC_OBJMTD] and info[FLD_IC_OBJMTD][name]
            or info[FLD_IC_OBJFTR] and info[FLD_IC_OBJFTR][name]) then
            return strformat("The %s can't be overridden", name), stack
        end

        stack                           = stack + 2

        attribute.SaveAttributes(func, ATTRTAR_METHOD, stack)

        if not (typmtd and typmtd[name] == false) then
            attribute.InheritAttributes(func, ATTRTAR_METHOD, getSuper(info, name, getTypeMethod))
        end

        local ret                       = attribute.InitDefinition(func, ATTRTAR_METHOD, func, target, name, stack)
        if ret ~= func then attribute.ToggleTarget(func, ret) func = ret end

        attribute.ApplyAttributes (func, ATTRTAR_METHOD, nil, target, name, stack)
        attribute.AttachAttributes(func, ATTRTAR_METHOD, target, name, stack)

        typmtd                          = info[FLD_IC_TYPMTD]    -- Maybe generated after attribtues applied

        if def then
            if typmtd and typmtd[name] == false then
                info[name]              = func
            else
                info[FLD_IC_TYPMTD]     = typmtd or _Cache()
                info[FLD_IC_TYPMTD][name] = func
            end
        elseif typmtd and typmtd[name] == false then
            info[name]                  = func
        else
            info[FLD_IC_TYPMTD]         = savestorage(typmtd or {}, name, func)
            return saveObjectMethod(target, name, func)
        end
    end

    local addMetaData                   = function (target, name, data, stack)
        local info, name, stack, msg    = preDefineCheck(target, name, stack)

        if msg then return msg, stack end

        if not META_KEYS[name] then return "the name is not valid", stack end

        local tdata                     = type(data)

        if name == IC_META_FIELD then
            if tdata ~= "table" then return "the data must be a table", stack end
        elseif name == IC_META_INDEX then
            if tdata ~= "function" and tdata ~= "table" then return "the data must be a function or table", stack end
        elseif tdata ~= "function" then
            return "the data must be a function", stack
        end

        stack                           = stack + 2

        if tdata == "function" then
            attribute.SaveAttributes(data, ATTRTAR_METHOD, stack)

            attribute.InheritAttributes(data, ATTRTAR_METHOD, getSuper(info, name, getTypeMetaMethod))

            local ret                   = attribute.InitDefinition(data, ATTRTAR_METHOD, data, target, name, stack)
            if ret ~= data then attribute.ToggleTarget(data, ret) data = ret end

            attribute.ApplyAttributes (data, ATTRTAR_METHOD, nil, target, name, stack)
            attribute.AttachAttributes(data, ATTRTAR_METHOD, target, name, stack)
        end

        -- Save
        local metaFld                   = META_KEYS[name]

        if type(metaFld) == "string" then
            info[FLD_IC_TYPMTM]         = info[FLD_IC_TYPMTM] or {}
            info[FLD_IC_TYPMTM][name]   = data

            if metaFld ~= name then
                info[FLD_IC_TYPMTM][metaFld] = tdata == "table" and function(_, k) return data[k] end or data
            end
        elseif name == IC_META_FIELD then
            addFields(target, data, stack)
        else
            info[metaFld]               = data
        end
    end

    local addFeature                    = function (target, name, ftr, stack)
        local info, name, stack, msg    = preDefineCheck(target, name, stack)

        if msg then return msg, stack end
        if META_KEYS[name] ~= nil then return strformat("the %s can't be used as feature name", name), stack end

        info[FLD_IC_TYPFTR]             = info[FLD_IC_TYPFTR] or _Cache()
        info[FLD_IC_TYPFTR][name]       = ftr

        if info[FLD_IC_STAFTR] and info[FLD_IC_STAFTR][name] then
            info[FLD_IC_STAFTR][name]   = nil
        elseif info[FLD_IC_OBJFTR] and info[FLD_IC_OBJFTR][name] then
            info[FLD_IC_OBJFTR][name]   = nil
        end
    end

    local setRequireClass               = function (target, cls, stack)
        local info, _, stack, msg       = preDefineCheck(target, nil, stack)

        if not info then return msg, stack end

        if not interface.Validate(target) then return "the target is not valid", stack end
        if not class.Validate(cls) then return "the requireclass must be a class", stack end
        if info[FLD_IC_REQCLS] and not class.IsSubType(cls, info[FLD_IC_REQCLS]) then return strformat("The requireclass must be %s's sub-class", tostring(info[FLD_IC_REQCLS])), stack end

        info[FLD_IC_REQCLS]             = cls
    end

    local setSuperClass                 = function (target, super, stack)
        local info, _, stack, msg       = preDefineCheck(target, nil, stack)

        if not info then return msg, stack end

        if not class.Validate(target) then return "the target is not valid", stack end
        if not class.Validate(super)  then return "the super class must be a class", stack end
        if     class.IsFinal(super)   then return "the super class is marked as final, can't be inherited", stack end

        if info[FLD_IC_SUPCLS] and info[FLD_IC_SUPCLS] ~= super then return strformat("The %s already has a super class", tostring(target)), stack end

        if info[FLD_IC_SUPCLS] then return end

        addSuperType(info, target, super)
    end

    local setObjectSourceDebug          = function (target, stack)
        local info, _, stack, msg       = preDefineCheck(target, nil, stack)
        if not info then return msg, stack end
        if not class.Validate(target) then return "the target is not valid", stack end
        info[FLD_IC_DEBUGSR]            = true
    end

    local setModifiedFlag               = function (tType, target, flag, methodName, stack)
        local info, _, stack, msg       = preDefineCheck(target, nil, stack)

        if not info then error(strformat("Usage: %s.%s(%s[, stack]) - ", tostring(tType), methodName, tostring(tType)) .. msg, stack + 2) end

        info[FLD_IC_MOD]                = turnonflags(flag, info[FLD_IC_MOD])
    end

    local toggleICMode                  = function (target, flag, on, stack)
        local info, _, stack, msg       = preDefineCheck(target, nil, stack)
        if not info then return msg, stack end

        if on then
            info[FLD_IC_MOD]            = turnonflags(flag, info[FLD_IC_MOD])
        else
            info[FLD_IC_MOD]            = turnoffflags(flag, info[FLD_IC_MOD])
        end
    end

    local setStaticMethod               = function (target, name, stack)
        local info, name, stack, msg, def = preDefineCheck(target, name, stack, true)

        if msg then return msg, stack end

        if not def then
            if info[name] then return end
            if not validateflags(MOD_SEALED_IC, info[FLD_IC_MOD]) then return "can't set a static method to an un-sealed " .. tostring(getmetatable(target)) .. " without definition", stack end
            if info[FLD_IC_TYPMTD] and info[FLD_IC_TYPMTD][name] ~= nil then return "can't set an existed object method as static", stack end
        end

        if info[name] == nil then
            info[FLD_IC_TYPMTD]         = info[FLD_IC_TYPMTD] or {}
            info[name]                  = info[FLD_IC_TYPMTD][name]
            info[FLD_IC_TYPMTD][name]   = false
            if info[FLD_IC_INHRTP] and info[FLD_IC_INHRTP][name] then info[FLD_IC_INHRTP][name] = nil end
        end
    end

    local setPriority                   = function (target, name, priority, stack)
        local info, name, stack, msg    = preDefineCheck(target, name, stack)
        if msg then return msg, stack end

        info[FLD_IC_INHRTP]             = info[FLD_IC_INHRTP] or {}
        info[FLD_IC_INHRTP][name]       = priority
    end

    -- Buidler helpers
    local setIFBuilderValue             = function (self, key, value, stack, notenvset)
        local owner                     = environment.GetNamespace(self)
        if not (owner and _ICBuilderInDefine[self]) then return end

        local tkey                      = type(key)
        local tval                      = type(value)

        stack                           = stack + 1

        if tkey == "string" and not tonumber(key) then
            if META_KEYS[key] then
                interface.AddMetaData(owner, key, value, stack)
                return true
            elseif key == namespace.GetNamespaceName(owner, true) then
                interface.SetInitializer(owner, value, stack)
                return true
            elseif tval == "function" then
                interface.AddMethod(owner, key, value, stack)
                return true
            end

            if notenvset then
                for parser in pairs, _Parser do
                    if parser.Parse(owner, key, value, stack) then
                        return true
                    end
                end
            end
        elseif tkey == "number" then
            if tval == "table" or tval == "userdata" then
                if class.Validate(value) then
                    interface.SetRequireClass(owner, value, stack)
                    return true
                elseif interface.Validate(value) then
                    interface.AddExtend(owner, value, stack)
                    return true
                end
            elseif tval == "function" then
                interface.SetInitializer(owner, value, stack)
                return true
            end

            if notenvset then
                for parser in pairs, _Parser do
                    if parser.Parse(owner, key, value, stack) then
                        return true
                    end
                end
            end
        end
    end

    local setClassBuilderValue          = function (self, key, value, stack, notenvset)
        local owner                     = environment.GetNamespace(self)
        if not (owner and _ICBuilderInDefine[self]) then return end

        local tkey                      = type(key)
        local tval                      = type(value)

        stack                           = stack + 1

        if tkey == "string" and not tonumber(key) then
            if META_KEYS[key] then
                class.AddMetaData(owner, key, value, stack)
                return true
            elseif key == namespace.GetNamespaceName(owner, true) then
                class.SetConstructor(owner, value, stack)
                return true
            elseif tval == "function" then
                class.AddMethod(owner, key, value, stack)
                return true
            end

            if notenvset then
                for parser in pairs, _Parser do
                    if parser.Parse(owner, key, value, stack) then
                        return true
                    end
                end
            end
        elseif tkey == "number" then
            if tval == "table" or tval == "userdata" then
                if class.Validate(value) then
                    class.SetSuperClass(owner, value, stack)
                    return true
                elseif interface.Validate(value) then
                    class.AddExtend(owner, value, stack)
                    return true
                end
            elseif tval == "function" then
                class.SetConstructor(owner, value, stack)
                return true
            end

            if notenvset then
                for parser in pairs, _Parser do
                    if parser.Parse(owner, key, value, stack) then
                        return true
                    end
                end
            end
        end
    end

    -- Get template implementation
    local getICImplement                = function(self, key, stack)
        local info                      = _ICInfo[self]
        if info[FLD_IC_TEMPDEF] then
            local implements            = info[FLD_IC_TEMPIMP]
            if type(key) ~= "table" or getmetatable(key) ~= nil then
                key                     = { key }
            end

            local implement             = getTemplateImplement(implements, key)
            if implement then return implement end

            local ok, err               = attribute.IndependentCall(function()
                local ptype             = getmetatable(self)
                implement               = ptype {}
                local bder              = ptype (info[FLD_IC_TEMPENV], implement, true)
                ptype.SetSealed(implement)
                local ninfo             = getICTargetInfo(implement)
                ninfo[FLD_IC_TEMPPRM]   = key
                ninfo[FLD_IC_TEMPIMP]   = self
                attribute.InheritAttributes(implement, ptype == class and ATTRTAR_CLASS or ATTRTAR_INTERFACE, self)
                bder(info[FLD_IC_TEMPDEF])
            end)

            if not ok then
                if type(err) == "string" then
                    error(err, 0)
                else
                    error(tostring(err), parsestack(stack) + 1)
                end
            end

            info[FLD_IC_TEMPIMP]        = saveTemplateImplement(implements, key, implement)

            return implement
        end

        error("the " .. tostring(self) .. " can't be used as template", parsestack(stack) + 1)
    end

    -----------------------------------------------------------------------
    --                             prototype                             --
    -----------------------------------------------------------------------
    interface                           = prototype {
        __tostring                      = "interface",
        __index                         = {
            Get = function(self) return _ICInfo[self] end,
            --- Add an interface to be extended
            -- @static
            -- @method  AddExtend
            -- @owner   interface
            -- @format  (target, extendinterface[, stack])
            -- @param   target                      the target interface
            -- @param   extendinterface             the interface to be extened
            -- @param   stack                       the stack level
            ["AddExtend"]               = function(target, extendinterface, stack)
                local msg, stack        = addExtend(target, extendinterface, stack)
                if msg then error("Usage: interface.AddExtend(target, extendinterface[, stack]) - " .. msg, stack + 1) end
            end;

            --- Add a type feature to the the interface
            -- @static
            -- @method  AddFeature
            -- @owner   interface
            -- @format  (target, name, feature[, stack])
            -- @param   target                      the target interface
            -- @param   name                        the feature's name
            -- @param   feature                     the feature
            -- @param   stack                       the stack level
            ["AddFeature"]              = function(target, name, feature, stack)
                local msg, stack        = addFeature(target, name, feature, stack)
                if msg then error("Usage: interface.AddFeature(target, name, feature[, stack]) - " .. msg, stack + 1) end
            end;

            --- Add init fields to the interface
            -- @static
            -- @method  AddFields
            -- @owner   interface
            -- @format  (target, fields[, stack])
            -- @param   target                      the target interface
            -- @param   fields:table                the init-fields
            -- @param   stack                       the stack level
            ["AddFields"]               = function(target, fields, stack)
                local msg, stack        = addFields(target, fields, stack)
                if msg then error("Usage: interface.AddFields(target, fields[, stack]) - " .. msg, stack + 1) end
            end;

            --- Add a meta data to the interface
            -- @static
            -- @method  AddMetaData
            -- @owner   interface
            -- @format  (target, name, data[, stack])
            -- @param   target                      the target interface
            -- @param   name                        the meta name
            -- @param   data:(function|table)       the meta data
            -- @param   stack                       the stack level
            ["AddMetaData"]             = function(target, name, data, stack)
                local msg, stack        = addMetaData(target, name, data, stack)
                if msg then error("Usage: interface.AddMetaData(target, name, data[, stack]) - " .. msg, stack + 1) end
            end;

            --- Add a method to the interface
            -- @static
            -- @method  AddMethod
            -- @owner   interface
            -- @format  (target, name, func[, stack])
            -- @param   target                      the target interface
            -- @param   name                        the method name
            -- @param   func:function               the method
            -- @param   stack                       the stack level
            ["AddMethod"]               = function(target, name, func, stack)
                local msg, stack        = addMethod(target, name, func, stack)
                if msg then error("Usage: interface.AddMethod(target, name, func[, stack]) - " .. msg, stack + 1) end
            end;

            --- Begin the interface's definition
            -- @static
            -- @method  BeginDefinition
            -- @owner   interface
            -- @format  (target[, stack])
            -- @param   target                      the target interface
            -- @param   stack                       the stack level
            ["BeginDefinition"] = function(target, stack)
                stack                   = parsestack(stack) + 1

                target                  = interface.Validate(target)
                if not target then error("Usage: interface.BeginDefinition(target[, stack]) - the target is not valid", stack) end

                if _ICInfo[target] and validateflags(MOD_SEALED_IC, _ICInfo[target][FLD_IC_MOD]) then error(strformat("Usage: interface.BeginDefinition(target[, stack]) - the %s is sealed, can't be re-defined", tostring(target)), stack) end
                -- if _ICBuilderInfo[target] then error(strformat("Usage: interface.BeginDefinition(target[, stack]) - the %s's definition has already begun", tostring(target)), stack) end

                _ICBuilderInfo          = savestorage(_ICBuilderInfo, target, getInitICInfo(target, false))

                attribute.SaveAttributes(target, ATTRTAR_INTERFACE, stack)
            end;

            --- Finish the interface's definition
            -- @static
            -- @method  EndDefinition
            -- @owner   interface
            -- @format  (target[, stack])
            -- @param   target                      the target interface
            -- @param   stack                       the stack level
            ["EndDefinition"]           = function(target, stack)
                local ninfo             = _ICBuilderInfo[target]
                if not ninfo then return end

                stack                   = parsestack(stack) + 1

                genTypeCaches(target, ninfo, stack)

                -- End interface's definition
                _ICBuilderInfo          = savestorage(_ICBuilderInfo, target, nil)

                -- Save as new interface's info
                saveICInfo(target, ninfo)

                attribute.AttachAttributes(target, ATTRTAR_INTERFACE, nil, nil, stack)

                reDefineChildren(target, stack)

                interfacedefined(target)

                return target
            end;

            --- Refresh the interface's definition
            -- @static
            -- @method  EndDefinition
            -- @owner   interface
            -- @format  (target[, stack])
            -- @param   target                      the target interface
            -- @param   stack                       the stack level
            ["RefreshDefinition"] = function(target, stack)
                stack                   = parsestack(stack) + 1

                target                  = interface.Validate(target)
                if not target then error("Usage: interface.RefreshDefinition(interface[, stack]) - interface not existed", stack) end
                if _ICBuilderInfo[target] then error(strformat("Usage: interface.RefreshDefinition(interface[, stack]) - The %s's definition has already begun", tostring(target)), stack) end

                local ninfo             = getInitICInfo(target, false)

                genTypeCaches(target, ninfo, stack)

                -- Save as new interface's info
                saveICInfo(target, ninfo)

                reDefineChildren(target, stack)

                interfacedefined(target)

                return target
            end;

            --- Get the definition context of the interface
            -- @static
            -- @method  GetDefault
            -- @return  prototype                   the context type
            ["GetDefinitionContext"]    = function() return interfacebuilder end;

            --- Get all the extended interfaces of the target interface
            -- @static
            -- @method  GetExtends
            -- @owner   interface
            -- @param   target                      the target interface
            -- @return  iter:function               the iterator
            -- @return  target                      the target interface
            ["GetExtends"]              = function(target)
                local info              = getICTargetInfo(target)
                if info then
                    local m             = #info
                    local u             = m - FLD_IC_STEXT
                    return function(self, n)
                        if type(n) == "number" and n >= 0 and n <= u then
                            return n + 1, info[m - n]
                        end
                    end, target, 0
                else
                    return fakefunc, target
                end
            end;

            --- Get a type feature of the target interface
            -- @static
            -- @method  GetFeature
            -- @owner   interface
            -- @param   (target, name[, fromobject])
            -- @param   target                      the target interface
            -- @param   name                        the feature's name
            -- @param   fromobject:boolean          get the object feature
            -- @return  feature                     the feature
            ["GetFeature"]              = function(target, name, fromobj)
                local info              = fromobj and _ICInfo[target] or getICTargetInfo(target)
                if info and type(name) == "string" then
                    info                = info[fromobj and FLD_IC_OBJFTR or FLD_IC_TYPFTR]
                    info                = info and info[name]
                    return info and info:GetFeature()
                end
            end;

            --- Get all the features of the target interface
            -- @static
            -- @method  GetFeatures
            -- @owner   interface
            -- @format  (target[, fromobject])
            -- @param   target                      the target interface
            -- @param   fromobject:boolean          get the object features
            -- @return  iter:function               the iterator
            -- @return  target                      the target interface
            ["GetFeatures"]             = function(target, fromobj)
                local info              = fromobj and _ICInfo[target] or getICTargetInfo(target)
                if info then
                    local typftr        = info[fromobj and FLD_IC_OBJFTR or FLD_IC_TYPFTR]
                    if typftr then
                        return function(self, n)
                            local name, ftr = next(typftr, n)
                            if name then return name, ftr:GetFeature() end
                        end, target
                    end
                end
                return fakefunc, target
            end;

            --- Get a method of the target interface
            -- @static
            -- @method  GetMethod
            -- @owner   interface
            -- @format  (target, name[, fromobject])
            -- @param   target                      the target interface
            -- @param   name                        the method's name
            -- @param   fromobject:boolean          get the object method
            -- @rformat method, isstatic
            -- @return  method                      the method
            -- @return  isstatic:boolean            whether the method is static
            ["GetMethod"]               = function(target, name, fromobj)
                local info              = fromobj and _ICInfo[target] or getICTargetInfo(target)
                if info and type(name) == "string" then
                    if not fromobj then
                        local mtd       = info[name]
                        if mtd then return mtd, true end
                    end
                    info                = info[fromobj and FLD_IC_OBJMTD or FLD_IC_TYPMTD]
                    local mtd           = info and info[name]
                    if mtd then return mtd, false end
                end
            end;

            --- Get all the methods of the interface
            -- @static
            -- @method  GetMethods
            -- @owner   interface
            -- @format  (target[, fromobject])
            -- @param   target                      the target interface
            -- @param   fromobject:boolean          get the object methods
            -- @return  iter:function               the iterator
            -- @return  target                      the target interface
            -- @usage   for name, func, isstatic in interface.GetMethods(System.IAttribute) do
            --              print(name)
            --          end
            ["GetMethods"]              = function(target, fromobj)
                local info              = fromobj and _ICInfo[target] or getICTargetInfo(target)
                if info then
                    local typm          = info[fromobj and FLD_IC_OBJMTD or FLD_IC_TYPMTD]
                    if typm then
                        return function(self, n)
                            local m, v  = next(typm, n)
                            if m then return m, v or info[m], not v end
                        end, target
                    end
                end
                return fakefunc, target
            end;

            --- Get a meta-method of the target interface
            -- @static
            -- @method  GetMetaMethod
            -- @owner   interface
            -- @format  (target, name[, fromobject])
            -- @param   target                      the target interface
            -- @param   name                        the meta-method's name
            -- @param   fromobject:boolean          get the object meta-method
            -- @return  function                    the meta-method
            ["GetMetaMethod"]           = function(target, name, fromobj)
                local info              = fromobj and _ICInfo[target] or getICTargetInfo(target)
                local key               = META_KEYS[name]
                if info and key then
                    info                = info[fromobj and FLD_IC_OBJMTM or FLD_IC_TYPMTM]
                    return info and info[key]
                end
            end;

            --- Get all the meta-methods of the interface
            -- @static
            -- @method  GetMetaMethods
            -- @owner   interface
            -- @format  (target[, fromobject])
            -- @param   target                      the target interface
            -- @param   fromobject:boolean          get the object meta-methods
            -- @return  iter:function               the iterator
            -- @return  target                      the target interface
            ["GetMetaMethods"]          = function(target, fromobj)
                local info              = fromobj and _ICInfo[target] or getICTargetInfo(target)
                if info then
                    local typm          = info[fromobj and FLD_IC_OBJMTM or FLD_IC_TYPMTM]
                    if typm then
                        return function(self, n)
                            local m     = next(typm, n)
                            while m and not META_KEYS[m] do m = next(typm, m) end
                            if m then return m, typm[META_KEYS[m]] end
                        end, target
                    end
                end
                return fakefunc, target
            end;

            --- Get the require class of the target interface
            -- @static
            -- @method  GetRequireClass
            -- @owner   interface
            -- @param   target                      the target interface
            -- @return  class                       the require class
            ["GetRequireClass"]         = function(target)
                local info              = getICTargetInfo(target)
                return info and info[FLD_IC_REQCLS]
            end;

            --- Gets the sub types of the interface
            -- @static
            -- @method GetSubTypes
            -- @owner  interface
            -- @param  target                       the target interface
            -- @retur  iterator
            ["GetSubTypes"]             = function(target)
                local map               = _ICDependsMap[target]
                if map then
                    local i             = 0
                    return function()
                        i               = i + 1
                        return map[i]
                    end
                else
                    return fakefunc, target
                end
            end;

            --- Get the super method of the target interface with the given name
            -- @static
            -- @method  GetSuperMethod
            -- @owner   interface
            -- @param   target                      the target interface
            -- @param   name                        the method name
            -- @return  function                    the super method
            ["GetSuperMethod"]          = function(target, name)
                local info              = getICTargetInfo(target)
                return info and getSuper(info, name, getTypeMethod)
            end;

            --- Get the super meta-method of the target interface with the given name
            -- @static
            -- @method  GetSuperMetaMethod
            -- @owner   interface
            -- @param   target                      the target interface
            -- @param   name                        the meta-method name
            -- @return  function                    the super meta-method
            ["GetSuperMetaMethod"] = function(target, name)
                local info              = _ICInfo[target]
                return info and getSuper(info, name, getTypeMetaMethod)
            end;

            --- Get the super feature of the target interface with the given name
            -- @static
            -- @method  GetSuperFeature
            -- @owner   interface
            -- @param   target                      the target interface
            -- @param   name                        the feature name
            -- @return  function                    the super feature
            ["GetSuperFeature"] = function(target, name)
                local info              = _ICInfo[target]
                return info and getSuper(info, name, getTypeFeature)
            end;

            --- Get the super refer of the target interface
            -- @static
            -- @method  GetSuperRefer
            -- @owner   interface
            -- @param   target                      the target interface
            -- @return  super                       the super refer
            ["GetSuperRefer"]           = function(target)
                local info              = getICTargetInfo(target)
                return info and info[FLD_IC_SUPER]
            end;

            --- Get template interface
            -- @static
            -- @method  GetTemplate
            -- @owner   interface
            -- @param   target                      the target interface
            -- @return  template                    the template interface, maybe itself
            ["GetTemplate"]             = function(target)
                local info              = getICTargetInfo(target)
                return info and (info[FLD_IC_TEMPDEF] and target or info[FLD_IC_TEMPIMP])
            end;

            --- Get the template parameters
            -- @static
            -- @method  GetTemplateParameters
            -- @owner   interface
            -- @param   target                      the target interface
            -- @return  ...                         the paramter list
            ["GetTemplateParameters"] = function(target)
                local info              = getICTargetInfo(target)
                if info and info[FLD_IC_TEMPPRM] then
                    return unpack(info[FLD_IC_TEMPPRM])
                end
            end;

            --- Whether the interface has anonymous class
            -- @static
            -- @method  HasAnonymousClass
            -- @owner   interface
            -- @param   target                      the target interface
            -- @return  boolean                     true if the interface has anonymous class
            ["HasAnonymousClass"] = function(target)
                local info              = getICTargetInfo(target)
                return info and validateflags(MOD_ANYMOUS_CLS, info[FLD_IC_MOD]) or false
            end;

            --- Whether the interface's method, meta-method or feature is abstract
            -- @static
            -- @method  IsAbstract
            -- @owner   interface
            -- @param   target                      the target interface
            -- @param   name                        the method, meta-method, feature name
            -- @return  boolean                     true if it abstract
            ["IsAbstract"]              = function(target, name)
                local info              = getICTargetInfo(target)
                return info and info[FLD_IC_INHRTP] and info[FLD_IC_INHRTP][name] == INRT_PRIORITY_ABSTRACT or false
            end;

            --- Whether the interface or its method, meta-method, feature is final
            -- @static
            -- @method  IsFinal
            -- @owner   interface
            -- @format  (target[, name])
            -- @param   target                      the target interface
            -- @param   name                        the method, meta-method, feature name
            -- @return  boolean                     true if is final
            ["IsFinal"]                 = function(target, name)
                local info              = getICTargetInfo(target)
                return info and ((name == nil and validateflags(MOD_FINAL_IC, info[FLD_IC_MOD])) or (name and info[FLD_IC_INHRTP] and info[FLD_IC_INHRTP][name] == INRT_PRIORITY_FINAL)) or false
            end;

            --- The objects are always immutable for type validation
            -- @static
            -- @method  IsImmutable
            -- @owner   interface
            -- @param   target                      the target interface
            -- @return  boolean                     true if the value should be immutable
            -- @return  boolean                     true if the value should be always immutable
            ["IsImmutable"]             = function(target) return true, true end;

            --- Whether the interface is sealed, can't be re-defined
            -- @static
            -- @method  IsSealed
            -- @owner   interface
            -- @param   target                      the target interface
            -- @return  boolean                     true if the interface is sealed
            ["IsSealed"]                = function(target)
                local info              = getICTargetInfo(target)
                return info and validateflags(MOD_SEALED_IC, info[FLD_IC_MOD]) or false
            end;

            --- Whether the interface's given name method is static
            -- @static
            -- @method  IsStaticMethod
            -- @owner   interface
            -- @param   target                      the target interface
            -- @param   name                        the method's name
            -- @return  boolean                     true if the method is static
            ["IsStaticMethod"]          = function(target, name)
                local info              = getICTargetInfo(target)
                return info and type(name) == "string" and info[FLD_IC_TYPMTD] and info[FLD_IC_TYPMTD][name] == false or false
            end;

            --- Whether the target interface is a sub-type of another interface
            -- @static
            -- @method  IsSubType
            -- @owner   interface
            -- @param   target                      the target interface
            -- @param   extendIF                    the extened interface
            -- @return  boolean                     true if the target interface is a sub-type of another interface
            ["IsSubType"]               = function(target, extendIF)
                if getmetatable(extendIF) == interface then
                    if target  == extendIF then return true end
                    local info          = getICTargetInfo(target)
                    if info then
                        if info[FLD_IC_TEMPIMP] == extendIF then return true end

                        for _, extif in ipairs, info, FLD_IC_STEXT - 1 do
                            if extif == extendIF or getICTargetInfo(extif)[FLD_IC_TEMPIMP] == extendIF then
                                return true
                            end
                        end
                    end
                end
                return false
            end;

            --- Register a parser to analyse key-value pair as definition for the class or interface
            -- @static
            -- @method  IsStaticMethod
            -- @owner   interface
            -- @format  parser[, stack]
            -- @param   parser                      the parser
            -- @param   stack                       the stack level
            -- @return  boolean                     true if the key-value pair is accepted as definition
            ["RegisterParser"]          = function(parser, stack)
                stack                   = parsestack(stack) + 1
                if not prototype.Validate(parser)           then error("Usage: interface.RegisterParser(parser[, stack] - the parser should be a prototype", stack) end
                if not getprototypemethod(parser, "Parse")  then error("Usage: interface.RegisterParser(parser[, stack] - the parser must have a 'Parse' method", stack) end
                _Parser                 = savestorage(_Parser, parser, true)
            end;

            --- Set the interface's method, meta-method or feature as abstract
            -- @static
            -- @method  SetAbstract
            -- @owner   interface
            -- @format  (target, name[, stack])
            -- @param   target                      the target interface
            -- @param   name                        the interface's method, meta-method or feature
            -- @param   stack                       the stack level
            ["SetAbstract"]             = function(target, name, stack)
                if type(name)  == "number" then name, stack = nil, name end
                local msg, stack        = setPriority(target, name, INRT_PRIORITY_ABSTRACT, stack)
                if msg then error("Usage: interface.SetAbstract(target, name[, stack]) - " .. msg, stack + 1) end
            end;

            --- Set the interface to have anonymous class
            -- @static
            -- @method  SetAnonymousClass
            -- @owner   interface
            -- @format  (target[, stack])
            -- @param   target                      the target interface
            -- @param   stack                       the stack level
            ["SetAnonymousClass"]       = function(target, stack)
                setModifiedFlag(interface, target, MOD_ANYMOUS_CLS, "SetAnonymousClass", stack)
            end;

            --- Set the interface as final, or its method, meta-method or feature as final
            -- @static
            -- @method  SetFinal
            -- @owner   interface
            -- @format  (target[, stack])
            -- @format  (target, name[, stack])
            -- @param   target                      the target interface
            -- @param   name                        the interface's method, meta-method or feature
            -- @param   stack                       the stack level
            ["SetFinal"]                = function(target, name, stack)
                if type(name)  == "string" then
                    local msg, stack    = setPriority(target, name, INRT_PRIORITY_FINAL, stack)
                    if msg then error("Usage: interface.SetFinal(target, name[, stack]) - " .. msg, stack + 1) end
                else
                    stack               = name
                    setModifiedFlag(interface, target, MOD_FINAL_IC, "SetFinal", stack)
                end
            end;

            --- Set the interface's destructor
            -- @static
            -- @method  SetDestructor
            -- @owner   interface
            -- @format  (target, func[, stack])
            -- @param   target                      the target interface
            -- @param   func:function               the destructor
            -- @param   stack                       the stack level
            ["SetDestructor"]           = function(target, func, stack)
                local msg, stack        = addMetaData(target, IC_META_DTOR, func, stack)
                if msg then error("Usage: interface.SetDestructor(target, func[, stack]) - " .. msg, stack + 1) end
            end;

            --- Set the interface's initializer
            -- @static
            -- @method  SetInitializer
            -- @owner   interface
            -- @format  (target, func[, stack])
            -- @param   target                      the target interface
            -- @param   func:function               the initializer
            -- @param   stack                       the stack level
            ["SetInitializer"]          = function(target, func, stack)
                local msg, stack        = addMetaData(target, IC_META_INIT, func, stack)
                if msg then error("Usage: interface.SetInitializer(target, func[, stack]) - " .. msg, stack + 1) end
            end;

            --- Set the require class to the interface
            -- @static
            -- @method  SetRequireClass
            -- @owner   interface
            -- @format  (target, requireclass[, stack])
            -- @param   target                      the target interface
            -- @param   requireclass                the require class
            -- @param   stack                       the stack level
            ["SetRequireClass"]         = function(target, cls, stack)
                local msg, stack        = setRequireClass(target, cls, stack)
                if msg then error("Usage: interface.SetRequireClass(target, requireclass[, stack]) - " .. msg, stack + 1) end
            end;

            --- Seal the interface
            -- @static
            -- @method  SetSealed
            -- @owner   interface
            -- @format  (target[, stack])
            -- @param   target                      the target interface
            -- @param   stack                       the stack level
            ["SetSealed"]               = function(target, stack)
                setModifiedFlag(interface, target, MOD_SEALED_IC, "SetSealed", stack)
            end;

            --- Mark the interface's method as static
            -- @static
            -- @method  SetStaticMethod
            -- @owner   interface
            -- @format  (target, name[, stack])
            -- @param   target                      the target interface
            -- @param   name                        the method's name
            -- @param   stack                       the stack level
            ["SetStaticMethod"]         = function(target, name, stack)
                local msg, stack        = setStaticMethod(target, name, stack)
                if msg then error("Usage: interface.SetStaticMethod(target, name[, stack]) - " .. msg, stack + 1) end
            end;

            --- Mark the interface as template
            -- @static
            -- @method  SetAsTemplate
            -- @owner   interface
            -- @format  (target, params[, stack])
            -- @param   target                      the target interface
            -- @param   params                      the parameters for the template
            -- @param   stack                       the stack level
            ["SetAsTemplate"]           = function(target, params, stack)
                local info, def         = getICTargetInfo(target)
                stack                   = parsestack(stack) + 1

                if info then
                    if not def then error(strformat("Usage: interface.SetAsTemplate(target, params[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                    info[FLD_IC_MOD]    = turnonflags(MOD_TEMPLATE_IC, info[FLD_IC_MOD])
                    info[FLD_IC_MOD]    = turnonflags(MOD_SEALED_IC,   info[FLD_IC_MOD])

                    info[FLD_IC_TEMPPRM]= type(params) == "table" and getmetatable(params) == nil and params or { params }
                    info[FLD_IC_TEMPIMP]= saveTemplateImplement({}, info[FLD_IC_TEMPPRM], target)
                else
                    error("Usage: interface.SetAsTemplate(target, params[, stack]) - The target is not valid", stack)
                end
            end;

            --- Whether the value is an object whose class extend the interface
            -- @static
            -- @method  ValidateValue
            -- @owner   interface
            -- @format  (target, value[, onlyvalid])
            -- @param   target                      the target interface
            -- @param   value                       the value used to validate
            -- @param   onlyvalid                   if true use true instead of the error message
            -- @return  value                       the validated value, nil if not valid
            -- @return  error                       the error message if the value is not valid
            ["ValidateValue"]           = function(target, value, onlyvalid)
                if class.IsSubType(getmetatable(value), target) then return value end
                return nil, onlyvalid or ("the %s is not an object that extend the [interface]" .. tostring(target))
            end;

            -- Whether the target is an interface
            -- @static
            -- @method  Validate
            -- @owner   interface
            -- @param   target                      the target interface
            -- @return  target                      return the target if it's an interface, otherwise nil
            ["Validate"]                = function(target)
                local info              = getICTargetInfo(target)
                return info and getmetatable(target) == interface and target or nil
            end;
        },
        __newindex                      = readonly,
        __call                          = function(self, ...)
            local visitor, env, target, definition, keepenv, stack = getTypeParams(interface, tinterface, ...)
            if not target then error("Usage: interface([env, ][name, ][definition, ][keepenv, ][stack]) - the interface type can't be created", stack) end

            if not _ICInfo[target] then
                saveICInfo(target, getInitICInfo(target, false), true)
            end

            stack                       = stack + 1

            if interface.IsSealed(target) then
                Debug("[interface] %s extend methods", stack, tostring(target))

                local builder           = prototype.NewObject(extendbuilder)
                environment.Initialize  (builder)
                environment.SetNamespace(builder, target)
                environment.SetParent   (builder, env)
                environment.SetDefinitionMode(builder, true)

                if definition then
                    builder(definition, stack)
                    return target
                else
                    return builder
                end
            else
                interface.BeginDefinition(target, stack)

                Debug("[interface] %s created", stack, tostring(target))

                local builder           = prototype.NewObject(interfacebuilder)
                environment.Initialize  (builder)
                environment.SetNamespace(builder, target)
                environment.SetParent   (builder, env)
                environment.SetDefinitionMode(builder, true)

                _ICBuilderInDefine      = savestorage(_ICBuilderInDefine, builder, true)

                if definition then
                    builder(definition, stack)
                    return target
                else
                    if not keepenv then safesetfenv(stack, builder) end
                    return builder
                end
            end
        end,
    }

    class                               = prototype {
        __tostring                      = "class",
        __index                         = {
            --- Add an interface to be extended
            -- @static
            -- @method  AddExtend
            -- @owner   class
            -- @format  (target, extendinterface[, stack])
            -- @param   target                      the target class
            -- @param   extendinterface             the interface to be extened
            -- @param   stack                       the stack level
            ["AddExtend"]               = function(target, extendinterface, stack)
                local msg, stack        = addExtend(target, extendinterface, stack)
                if msg then error("Usage: class.AddExtend(target, extendinterface[, stack]) - " .. msg, stack + 1) end
            end;

            --- Add a type feature to the the class
            -- @static
            -- @method  AddFeature
            -- @owner   class
            -- @format  (target, name, feature[, stack])
            -- @param   target                      the target class
            -- @param   name                        the feature's name
            -- @param   feature                     the feature
            -- @param   stack                       the stack level
            ["AddFeature"]              = function(target, name, feature, stack)
                local msg, stack        = addFeature(target, name, feature, stack)
                if msg then error("Usage: class.AddFeature(target, name, feature[, stack]) - " .. msg, stack + 1) end
            end;

            --- Add init fields to the class
            -- @static
            -- @method  AddFields
            -- @owner   class
            -- @format  (target, fields[, stack])
            -- @param   target                      the target class
            -- @param   fields:table                the init-fields
            -- @param   stack                       the stack level
            ["AddFields"]               = function(target, fields, stack)
                local msg, stack        = addFields(target, fields, stack)
                if msg then error("Usage: class.AddFields(target, fields[, stack]) - " .. msg, stack + 1) end
            end;

            --- Add a meta data to the class
            -- @static
            -- @method  AddMetaData
            -- @owner   class
            -- @format  (target, name, data[, stack])
            -- @param   target                      the target class
            -- @param   name                        the meta name
            -- @param   data:(function|table)       the meta data
            -- @param   stack                       the stack level
            ["AddMetaData"]             = function(target, name, data, stack)
                local msg, stack        = addMetaData(target, name, data, stack)
                if msg then error("Usage: class.AddMetaData(target, name, data[, stack]) - " .. msg, stack + 1) end
            end;

            --- Add a method to the class
            -- @static
            -- @method  AddMethod
            -- @owner   class
            -- @format  (target, name, func[, stack])
            -- @param   target                      the target class
            -- @param   name                        the method name
            -- @param   func:function               the method
            -- @param   stack                       the stack level
            ["AddMethod"]               = function(target, name, func, stack)
                local msg, stack        = addMethod(target, name, func, stack)
                if msg then error("Usage: class.AddMethod(target, name, func[, stack]) - " .. msg, stack + 1) end
            end;

            --- Attach source place to the object
            -- @static
            -- method   AttachObjectSource
            -- @owner   class
            -- @format  (object[, stack])
            -- @param   object                      the target object
            -- @param   stack                       the stack level
            -- @return  object                      the target object
            ["AttachObjectSource"]      = function(object, stack)
                if type(object) ~= "table" then error("Usage: class.AttachObjectSource(object[, stack]) - the object is not valid", 2) end
                rawset(object, FLD_OBJ_SOURCE, getcallline(parsestack(stack) + 1) or nil)
                return object
            end;

            --- Begin the class's definition
            -- @static
            -- @method  BeginDefinition
            -- @owner   class
            -- @format  (target[, stack])
            -- @param   target                      the target class
            -- @param   stack                       the stack level
            ["BeginDefinition"] = function(target, stack)
                stack                   = parsestack(stack) + 1

                target                  = class.Validate(target)
                if not target then error("Usage: class.BeginDefinition(target[, stack]) - the target is not valid", stack) end

                if _ICInfo[target] and validateflags(MOD_SEALED_IC, _ICInfo[target][FLD_IC_MOD]) then error(strformat("Usage: class.BeginDefinition(target[, stack]) - The %s is sealed, can't be re-defined", tostring(target)), stack) end
                -- if _ICBuilderInfo[target] then error(strformat("Usage: class.BeginDefinition(target[, stack]) - The %s's definition has already begun", tostring(target)), stack) end

                _ICBuilderInfo          = savestorage(_ICBuilderInfo, target, getInitICInfo(target, true))

                attribute.SaveAttributes(target, ATTRTAR_CLASS, stack)
            end;

            --- Get the clone of an object with class
            -- @static
            -- @method  Clone
            -- @owner   class
            -- @param   object                      the object to be cloned
            -- @return  clone                       clone if the class is ICloneable
            ["Clone"]                   = function(object, cls)
                cls                     = class.GetObjectClass(object)
                if cls and class.IsSubType(cls, ICloneable) then
                    return object:Clone()
                end
            end;

            --- Finish the class's definition
            -- @static
            -- @method  EndDefinition
            -- @owner   class
            -- @format  (target[, stack])
            -- @param   target                      the target class
            -- @param   stack                       the stack level
            ["EndDefinition"]           = function(target, stack)
                local ninfo             = _ICBuilderInfo[target]
                if not ninfo then return end

                stack                   = parsestack(stack) + 1

                -- Generate caches and constructor
                genTypeCaches(target, ninfo, stack)

                -- End class's definition
                _ICBuilderInfo          = savestorage(_ICBuilderInfo, target, nil)

                -- Save as new interface's info
                saveICInfo(target, ninfo)

                attribute.AttachAttributes(target, ATTRTAR_CLASS, nil, nil, stack)

                reDefineChildren(target, stack)

                classdefined(target)

                return target
            end;

            --- Get the definition context of the class
            -- @static
            -- @method  GetDefault
            -- @return  prototype                   the context type
            ["GetDefinitionContext"]    = function() return classbuilder end;

            --- Get all the extended interfaces of the target class
            -- @static
            -- @method  GetExtends
            -- @owner   class
            -- @param   target                      the target class
            -- @return  iter:function               the iterator
            -- @return  target                      the target class
            ["GetExtends"]              = interface.GetExtends;

            --- Get a type feature of the target class
            -- @static
            -- @method  GetFeature
            -- @owner   class
            -- @param   (target, name[, fromobject])
            -- @param   target                      the target class
            -- @param   name                        the feature's name
            -- @param   fromobject:boolean          get the object feature
            -- @return  feature                     the feature
            ["GetFeature"]              = interface.GetFeature;

            --- Get all the features of the target class
            -- @static
            -- @method  GetFeatures
            -- @owner   class
            -- @format  (target[, fromobject])
            -- @param   target                      the target class
            -- @param   fromobject:boolean          get the object features
            -- @return  iter:function               the iterator
            -- @return  target                      the target class
            ["GetFeatures"]             = interface.GetFeatures;

            --- Get a method of the target class
            -- @static
            -- @method  GetMethod
            -- @owner   class
            -- @format  (target, name[, fromobject])
            -- @param   target                      the target class
            -- @param   name                        the method's name
            -- @param   fromobject:boolean          get the object method
            -- @rformat method, isstatic
            -- @return  method                      the method
            -- @return  isstatic:boolean            whether the method is static
            ["GetMethod"]               = interface.GetMethod;

            --- Get all the methods of the class
            -- @static
            -- @method  GetMethods
            -- @owner   class
            -- @format  (target[, fromobject])
            -- @param   target                      the target class
            -- @param   fromobject:boolean          get the object methods
            -- @return  iter:function               the iterator
            -- @return  target                      the target class
            ["GetMethods"]              = interface.GetMethods;

            --- Get a meta-method of the target class
            -- @static
            -- @method  GetMetaMethod
            -- @owner   class
            -- @format  (target, name[, fromobject])
            -- @param   target                      the target class
            -- @param   name                        the meta-method's name
            -- @param   fromobject:boolean          get the object meta-method
            -- @return  function                    the meta-method
            ["GetMetaMethod"]           = interface.GetMetaMethod;

            --- Get all the meta-methods of the class
            -- @static
            -- @method  GetMetaMethods
            -- @owner   class
            -- @format  (target[, fromobject])
            -- @param   target                      the target class
            -- @param   fromobject:boolean          get the object meta-methods
            -- @return  iter:function               the iterator
            -- @return  target                      the target class
            ["GetMetaMethods"]          = interface.GetMetaMethods;

            --- Get the normal method of the target class with the given name
            -- @static
            -- @method  GetNormalMethod
            -- @owner   class
            -- @param   target                      the target class
            -- @param   name                        the method name
            -- @return  function                    the normal method
            ["GetNormalMethod"]         = function(target, name)
                local info              = getICTargetInfo(target)
                return info and getNormal(info, name, getTypeMethod)
            end;

            --- Get the normal meta-method of the target class with the given name
            -- @static
            -- @method  GetNormalMetaMethod
            -- @owner   class
            -- @param   target                      the target class
            -- @param   name                        the meta-method name
            -- @return  function                    the normal meta-method
            ["GetNormalMetaMethod"]     = function(target, name)
                local info              = _ICInfo[target]
                return info and getNormal(info, name, getTypeMetaMethod)
            end;

            --- Get the normal feature of the target class with the given name
            -- @static
            -- @method  GetNormalFeature
            -- @owner   class
            -- @param   target                      the target class
            -- @param   name                        the feature name
            -- @return  feature                     the normal feature
            ["GetNormalFeature"]        = function(target, name)
                local info              = _ICInfo[target]
                return info and getNormal(info, name, getTypeFeature)
            end;

            --- Get the object class of the object
            -- @static
            -- @method  GetObjectClass
            -- @owner   class
            -- @param   object                      the object
            -- @return  class                       the object class
            ["GetObjectClass"]          = function(object)
                return class.Validate(getmetatable(object))
            end;

            --- Get the object's creation place
            -- @static
            -- @method  GetObjectSource
            -- @owner   class
            -- @param   object                      the object
            -- @return  source                      where the object is created
            ["GetObjectSource"]         = function(object)
                return type(object) == "table" and rawget(object, FLD_OBJ_SOURCE) or nil
            end;

            --- Gets the sub types of the class
            -- @static
            -- @method GetSubTypes
            -- @owner  class
            -- @param  target                       the target class
            -- @retur  iterator
            ["GetSubTypes"]             = interface.GetSubTypes;

            --- Get the super class of the target class
            -- @static
            -- @method  GetSuperClass
            -- @owner   class
            -- @param   target                      the target class
            -- @return  class                       the super class
            ["GetSuperClass"]           = function(target)
                local info              = getICTargetInfo(target)
                return info and info[FLD_IC_SUPCLS]
            end;

            --- Get the super method of the target class with the given name
            -- @static
            -- @method  GetSuperMethod
            -- @owner   class
            -- @param   target                      the target class
            -- @param   name                        the method name
            -- @return  function                    the super method
            ["GetSuperMethod"]          = interface.GetSuperMethod;

            --- Get the super meta-method of the target class with the given name
            -- @static
            -- @method  GetSuperMetaMethod
            -- @owner   class
            -- @param   target                      the target class
            -- @param   name                        the meta-method name
            -- @return  function                    the super meta-method
            ["GetSuperMetaMethod"]      = interface.GetSuperMetaMethod;

            --- Get the super feature of the target class with the given name
            -- @static
            -- @method  GetSuperFeature
            -- @owner   class
            -- @param   target                      the target class
            -- @param   name                        the feature name
            -- @return  function                    the super feature
            ["GetSuperFeature"]         = interface.GetSuperFeature;

            --- Whether the class use super object access style like `super[obj].Name = "Ann"`
            -- @static
            -- @method  GetSuperObjectStyle
            -- @owner   class
            -- @param   target                      the target class
            -- @return  boolean                     true if the class use super object access style
            ["GetSuperObjectStyle"]     = function(target)
                local info              = getICTargetInfo(target)
                return info and not validateflags(MOD_NOSUPER_OBJ, info[FLD_IC_MOD]) or false
            end;

            --- Get the super refer of the target class
            -- @static
            -- @method  GetSuperRefer
            -- @owner   class
            -- @param   target                      the target class
            -- @return  super                       the super refer
            ["GetSuperRefer"]           = interface.GetSuperRefer;

            --- Get template class
            -- @static
            -- @method  GetTemplate
            -- @owner   class
            -- @param   target                      the target class
            -- @return  template                    the template class, maybe itself
            ["GetTemplate"]             = interface.GetTemplate;

            --- Get the template parameters
            -- @static
            -- @method  GetTemplateParameters
            -- @owner   class
            -- @param   target                      the target class
            -- @return  ...                         the paramter list
            ["GetTemplateParameters"]   = interface.GetTemplateParameters;

            --- Whether the class's method, meta-method or feature is abstract
            -- @static
            -- @method  IsAbstract
            -- @owner   class
            -- @param   target                      the target class
            -- @param   name                        the method, meta-method, feature name
            -- @return  boolean                     true if it abstract
            ["IsAbstract"]              = function(target, name)
                local info              = getICTargetInfo(target)
                return info and ((name == nil and validateflags(MOD_ABSTRACT_CLS, info[FLD_IC_MOD])) or (name and info[FLD_IC_INHRTP] and info[FLD_IC_INHRTP][name] == INRT_PRIORITY_ABSTRACT)) or false
            end;

            --- Whether the class or its method, meta-method, feature is final
            -- @static
            -- @method  IsFinal
            -- @owner   class
            -- @format  (target[, name])
            -- @param   target                      the target class
            -- @param   name                        the method, meta-method, feature name
            -- @return  boolean                     true if is final
            ["IsFinal"]                 = interface.IsFinal;

            --- The objects are always immutable for type validation
            -- @static
            -- @method  IsImmutable
            -- @owner   class
            -- @param   target                      the target class
            -- @return  boolean                     true if the value should be immutable
            -- @return  boolean                     true if the value should be always immutable
            ["IsImmutable"]             = interface.IsImmutable;

            --- Whether the attributes can be applied on the class's objects
            -- @static
            -- @method  IsObjectAttributeEnabled
            -- @owner   class
            -- @param   target                      the target class
            -- @return  boolean                     true if the attributes can be applied on the class's objects
            ["IsObjectAttributeEnabled"]= function(target)
                local info              = getICTargetInfo(target)
                return info and validateflags(MOD_ATTROBJ_CLS, info[FLD_IC_MOD]) or false
            end;

            --- Whether the class object has enabled the attribute for functions will be defined in it
            -- @static
            -- @method  IsObjectFunctionAttributeEnabled
            -- @owner   class
            -- @param   target                      the target class
            -- @return  boolean                     true if the class object enabled the function attribute
            ["IsObjectFunctionAttributeEnabled"] = function(target)
                local info              = getICTargetInfo(target)
                return info and validateflags(MOD_ATTRFUNC_OBJ, info[FLD_IC_MOD]) or false
            end;

            --- Whether the class object is recyclable so the system won't wipe it when dispose it
            -- @static
            -- @method  IsObjectRecyclable
            -- @owner   class
            -- @param   target                      the target class
            -- @return  boolean                     true if the class object is recyclable
            ["IsObjectRecyclable"]      = function(target)
                local info              = getICTargetInfo(target)
                return info and validateflags(MOD_RECYCLABLE_OBJ, info[FLD_IC_MOD]) or false
            end;

            --- Whether the class object'll save its source when created
            -- @static
            -- @method  IsObjectSourceDebug
            -- @owner   class
            -- @param   target                      the target class
            -- @return  boolean                     true if the class object'll save its source when created
            ["IsObjectSourceDebug"]     = function(target)
                local info              = getICTargetInfo(target)
                return info and info[FLD_IC_DEBUGSR] or false
            end;

            --- Whether the object is generated from the target type
            -- @static
            -- @method  IsObjectType
            -- @owner   class
            -- @param   target                      the object
            -- @param   type                        the interface or class
            -- @param   boolean                     true if the object is generated from the target type
            ["IsObjectType"]            = function(target, type)
                local otype             = class.GetObjectClass(target)
                return otype and class.IsSubType(otype, type) or false
            end;

            --- Whether the class object will try to auto cache the object methods
            -- @static
            -- @method  IsMethodAutoCache
            -- @owner   class
            -- @param   target                      the target class
            -- @param   boolean                     true if the class object will try to auto cache the object methods
            ["IsMethodAutoCache"]       = function(target)
                local info              = getICTargetInfo(target)
                return info and validateflags(MOD_AUTOCACHE_OBJ, info[FLD_IC_MOD]) or false
            end;

            --- Whether the class object don't receive any value assignment excpet existed fields
            -- @static
            -- @method  IsRawSetBlocked
            -- @owner   class
            -- @param   target                      the target class
            -- @return  boolean                     true if the class object don't receive any value assignment excpet existed fields
            ["IsNilValueBlocked"]       = function(target)
                local info              = getICTargetInfo(target)
                return info and validateflags(MOD_NONILVAL_OBJ, info[FLD_IC_MOD]) or false
            end;

            --- Whether the class object don't receive any value assignment excpet existed fields
            -- @static
            -- @method  IsRawSetBlocked
            -- @owner   class
            -- @param   target                      the target class
            -- @return  boolean                     true if the class object don't receive any value assignment excpet existed fields
            ["IsRawSetBlocked"]         = function(target)
                local info              = getICTargetInfo(target)
                return info and validateflags(MOD_NORAWSET_OBJ, info[FLD_IC_MOD]) or false
            end;

            --- Whether the class is sealed, can't be re-defined
            -- @static
            -- @method  IsSealed
            -- @owner   class
            -- @param   target                      the target class
            -- @return  boolean                     true if the class is sealed
            ["IsSealed"]                = interface.IsSealed;

            --- Whether the class is a single version class, so old object would receive re-defined class's features
            -- @static
            -- @method  IsSingleVersion
            -- @owner   class
            -- @param   target                      the target class
            -- @return  boolean                     true if the class is a single version class
            ["IsSingleVersion"]         = PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD and function() return false end or function(target)
                local info              = getICTargetInfo(target)
                return info and validateflags(MOD_SINGLEVER_CLS, info[FLD_IC_MOD]) or false
            end;

            --- Whether the class's given name method is static
            -- @static
            -- @method  IsStaticMethod
            -- @owner   class
            -- @param   target                      the target class
            -- @param   name                        the method's name
            -- @return  boolean                     true if the method is static
            ["IsStaticMethod"]          = interface.IsStaticMethod;

            --- Whether the target class is a sub-type of another interface or class
            -- @static
            -- @method  IsSubType
            -- @owner   class
            -- @format  (target, extendIF)
            -- @format  (target, superclass)
            -- @param   target                      the target class
            -- @param   extendIF                    the extened interface
            -- @param   superclass                  the super class
            -- @return  boolean                     true if the target class is a sub-type of another interface or class
            ["IsSubType"]               = function(target, supertype)
                local meta              = getmetatable(supertype)
                if meta        == class then
                    if target  == supertype then return true end

                    local info          = getICTargetInfo(target)
                    while info do
                        if info[FLD_IC_TEMPIMP] == supertype then return true end
                        target          = info[FLD_IC_SUPCLS]
                        if not target then return false end
                        if target == supertype then return true end
                        info            = getICTargetInfo(target)
                    end
                elseif meta    == interface then
                    if target  == supertype then return true end

                    local info          = getICTargetInfo(target)
                    if info then
                        if info[FLD_IC_TEMPIMP] == supertype then return true end
                        for _, extif in ipairs, info, FLD_IC_STEXT - 1 do
                            if extif == supertype or getICTargetInfo(extif)[FLD_IC_TEMPIMP] == supertype then
                                return true
                            end
                        end
                    end
                end
                return false
            end;

            --- Refresh the class's definition
            -- @static
            -- @method  EndDefinition
            -- @owner   class
            -- @format  (target[, stack])
            -- @param   target                      the target class
            -- @param   stack                       the stack level
            ["RefreshDefinition"]       = function(target, stack)
                stack                   = parsestack(stack) + 1

                target                  = class.Validate(target)
                if not target then error("Usage: class.RefreshDefinition(target[, stack]) - the target is not valid", stack) end
                if _ICBuilderInfo[target] then error(strformat("Usage: class.RefreshDefinition(target[, stack]) - The %s's definition has already begun", tostring(target)), stack) end

                local ninfo             = getInitICInfo(target, true)

                -- Generate caches and constructor
                genTypeCaches(target, ninfo, stack)

                -- Save as new interface's info
                saveICInfo(target, ninfo)

                reDefineChildren(target, stack)

                classdefined(target)

                return target
            end;

            --- Register a parser to analyse key-value pair as definition for the class or interface
            -- @static
            -- @method  IsStaticMethod
            -- @owner   class
            -- @format  parser[, stack]
            -- @param   parser                      the parser
            -- @param   stack                       the stack level
            -- @return  boolean                     true if the key-value pair is accepted as definition
            ["RegisterParser"]          = function(parser, stack)
                stack                   = parsestack(stack) + 1
                if not prototype.Validate(parser)           then error("Usage: class.RegisterParser(parser[, stack] - the parser should be a prototype", stack) end
                if not getprototypemethod(parser, "Parse")  then error("Usage: class.RegisterParser(parser[, stack] - the parser must have a 'Parse' method", stack) end
                _Parser                 = savestorage(_Parser, parser, true)
            end;

            --- Set the class as abstract, or its method, meta-method or feature as abstract
            -- @static
            -- @method  SetAbstract
            -- @owner   class
            -- @format  (target[, stack])
            -- @format  (target, name[, stack])
            -- @param   target                      the target class
            -- @param   name                        the class's method, meta-method or feature
            -- @param   stack                       the stack level
            ["SetAbstract"]             = function(target, name, stack)
                if type(name)  == "string" then
                    local msg, stack    = setPriority(target, name, INRT_PRIORITY_ABSTRACT, stack)
                    if msg then error("Usage: class.SetAbstract(target, name[, stack]) - " .. msg, stack + 1) end
                else
                    stack               = name
                    setModifiedFlag(class, target, MOD_ABSTRACT_CLS, "SetAbstract", stack + 1)
                end
            end;

            --- Set the class's constructor
            -- @static
            -- @method  SetConstructor
            -- @owner   class
            -- @format  (target, func[, stack])
            -- @param   target                      the target class
            -- @param   func:function               the constructor
            -- @param   stack                       the stack level
            ["SetConstructor"]          = function(target, func, stack)
                local msg, stack        = addMetaData(target, IC_META_CTOR, func, stack)
                if msg then error("Usage: class.SetConstructor(target, func[, stack]) - " .. msg, stack + 1) end
            end;

            --- Set the class's destructor
            -- @static
            -- @method  SetDestructor
            -- @owner   class
            -- @format  (target, func[, stack])
            -- @param   target                      the target class
            -- @param   func:function               the destructor
            -- @param   stack                       the stack level
            ["SetDestructor"]           = function(target, func, stack)
                local msg, stack        = addMetaData(target, IC_META_DTOR, func, stack)
                if msg then
                    error("Usage: class.SetDestructor(class, func[, stack]) - " .. msg, stack + 1)
                end
            end;

            --- Set the class as final, or its method, meta-method or feature as final
            -- @static
            -- @method  SetFinal
            -- @owner   class
            -- @format  (target[, stack])
            -- @format  (target, name[, stack])
            -- @param   target                      the target class
            -- @param   name                        the class's method, meta-method or feature
            -- @param   stack                       the stack level
            ["SetFinal"]                = function(target, name, stack)
                if type(name)  == "string" then
                    local msg, stack    = setPriority(target, name, INRT_PRIORITY_FINAL, stack)
                    if msg then error("Usage: class.SetFinal(target, name[, stack]) - " .. msg, stack + 1) end
                else
                    stack               = name
                    setModifiedFlag(class, target, MOD_FINAL_IC, "SetFinal", stack)
                end
            end;

            --- Sets the class so it's object will try to auto cache the object methods
            -- @static
            -- @method  SetMethodAutoCache
            -- @owner   class
            -- @format  (target[, stack])
            -- @param   target                      the target class
            -- @param   stack                       the stack level
            ["SetMethodAutoCache"]      = function(target, stack)
                setModifiedFlag(class, target, MOD_AUTOCACHE_OBJ, "SetMethodAutoCache", stack)
            end;

            --- Set the class's object exist checker
            -- @static
            -- @method  SetObjectExistChecker
            -- @owner   class
            -- @format  (target, func[, stack])
            -- @param   target                      the target class
            -- @param   func:function               the object exist checker
            -- @param   stack                       the stack level
            ["SetObjectExistChecker"]   = function(target, func, stack)
                local msg, stack        = addMetaData(target, IC_META_EXIST, func, stack)
                if msg then error("Usage: class.SetObjectExistChecker(target, func[, stack]) - " .. msg, stack + 1) end
            end;

            --- Make the class to enable the attribute for objects
            -- @static
            -- @method  SetObjectAttributeEnabled
            -- @owner   class
            -- @format  (target[, stack])
            -- @param   target                      the target class
            -- @param   stack                       the stack level
            ["SetObjectAttributeEnabled"] = function(target, stack)
                setModifiedFlag(class, target, MOD_ATTROBJ_CLS, "SetObjectAttributeEnabled", stack)
            end;

            --- Make the class objects enable the attribute for functions will be defined in it
            -- @static
            -- @method  SetObjectFunctionAttributeEnabled
            -- @owner   class
            -- @format  (target[, stack])
            -- @param   target                      the target class
            -- @param   stack                       the stack level
            ["SetObjectFunctionAttributeEnabled"] = function(target, stack)
                setModifiedFlag(class, target, MOD_ATTRFUNC_OBJ, "SetObjectFunctionAttributeEnabled", stack)
            end;

            --- Set the class's object generator
            -- @static
            -- @method  SetObjectGenerator
            -- @owner   class
            -- @format  (target, func[, stack])
            -- @param   target                      the target class
            -- @param   func:function               the object generator
            -- @param   stack                       the stack level
            ["SetObjectGenerator"]      = function(target, func, stack)
                local msg, stack        = addMetaData(target, IC_META_NEW, func, stack)
                if msg then error("Usage: class.SetObjectGenerator(target, func[, stack]) - " .. msg, stack + 1) end
            end;

            --- Whether the class object is recyclable so the system won't wipe it when dispose it
            -- @static
            -- @method  IsObjectRecyclable
            -- @owner   class
            -- @owner   class
            -- @format  (target, on[, stack])
            -- @param   target                      the target class
            -- @param   on                          true if the object of the class should be recyclable
            -- @param   stack                       the stack level
            ["SetObjectRecyclable"]     = function(target, on, stack)
                local msg, stack        = toggleICMode(target, MOD_RECYCLABLE_OBJ, on, stack)
                if msg then error("Usage: class.SetObjectRecyclable(target, on, [, stack])  - " .. msg, stack + 1) end
            end;

            --- Make the class object so you can't read value from a non-existed fields
            -- @static
            -- @method  SetNilValueBlocked
            -- @owner   class
            -- @format  (target, on[, stack])
            -- @param   target                      the target class
            -- @param   on                          true if we can't read non-existed fields from the object
            -- @param   stack                       the stack level
            ["SetNilValueBlocked"]      = function(target, on, stack)
                local msg, stack        = toggleICMode(target, MOD_NONILVAL_OBJ, on, stack)
                if msg then error("Usage: class.SetNilValueBlocked(target, on, [, stack])  - " .. msg, stack + 1) end
            end;

            --- Make the class whether use super object access style like `super[obj].Name = "Ann"`
            -- @static
            -- @method  SetSuperObjectStyle
            -- @owner   class
            -- @format  (target, on[, stack])
            -- @param   target                      the target class
            -- @param   on                          true if using the super object access style
            -- @param   stack                       the stack level
            ["SetSuperObjectStyle"]     = function(target, on, stack)
                local msg, stack        = toggleICMode(target, MOD_NOSUPER_OBJ, not on, stack)
                if msg then error("Usage: class.SetSuperObjectStyle(target, on, [, stack])  - " .. msg, stack + 1) end
            end;

            --- Set the class object'll to save its source when created
            -- @static
            -- @method  SetObjectSourceDebug
            -- @owner   class
            -- @format  (target[, stack])
            -- @param   target                      the target class
            -- @param   stack                       the stack level
            ["SetObjectSourceDebug"]    = function(target, stack)
                local msg, stack        = setObjectSourceDebug(target, stack)
                if msg then error("Usage: class.SetObjectSourceDebug(target[, stack])  - " .. msg, stack + 1) end
            end;

            --- Make the class object so we can't assign value to non-existed fields
            -- @static
            -- @method  SetRawSetBlocked
            -- @owner   class
            -- @format  (target[, stack])
            -- @param   target                      the target class
            -- @param   on                          true if we can't assign value to non-existed fields
            -- @param   stack                       the stack level
            ["SetRawSetBlocked"]        = function(target, on, stack)
                local msg, stack        = toggleICMode(target, MOD_NORAWSET_OBJ, on, stack)
                if msg then error("Usage: class.SetRawSetBlocked(target, on, [, stack])  - " .. msg, stack + 1) end
            end;

            --- Seal the class
            -- @static
            -- @method  SetSealed
            -- @owner   class
            -- @format  (target[, stack])
            -- @param   target                      the target class
            -- @param   stack                       the stack level
            ["SetSealed"]               = function(target, stack)
                setModifiedFlag(class, target, MOD_SEALED_IC, "SetSealed", stack)
            end;

            --- Set the class as single version, so old object would receive re-defined class's features
            -- @static
            -- @method  SetSingleVersion
            -- @owner   class
            -- @format  (target[, stack])
            -- @param   target                      the target class
            -- @param   stack                       the stack level
            ["SetSingleVersion"]        = PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD and fakefunc or function(target, stack)
                setModifiedFlag(class, target, MOD_SINGLEVER_CLS, "SetSingleVersion", stack)
            end;

            --- Set the super class to the class
            -- @static
            -- @method  SetRequireClass
            -- @owner   class
            -- @format  (target, superclass[, stack])
            -- @param   target                      the target class
            -- @param   superclass                  the super class
            -- @param   stack                       the stack level
            ["SetSuperClass"]           = function(target, cls, stack)
                local msg, stack        = setSuperClass(target, cls, stack)
                if msg then error("Usage: class.SetSuperClass(target, superclass[, stack])  - " .. msg, stack + 1) end
            end;

            --- Mark the class's method as static
            -- @static
            -- @method  SetStaticMethod
            -- @owner   class
            -- @format  (target, name[, stack])
            -- @param   target                      the target class
            -- @param   name                        the method's name
            -- @param   stack                       the stack level
            ["SetStaticMethod"]         = function(target, name, stack)
                local msg, stack        = setStaticMethod(target, name, stack)
                if msg then error("Usage: class.SetStaticMethod(target, name[, stack]) - " .. msg, stack + 1) end
            end;

            --- Mark the class as template
            -- @static
            -- @method  SetAsTemplate
            -- @owner   class
            -- @format  (target[, stack])
            -- @param   target                      the target class
            -- @param   params                      the parameters for the template
            -- @param   stack                       the stack level
            ["SetAsTemplate"]           = function(target, params, stack)
                local info, def         = getICTargetInfo(target)
                stack                   = parsestack(stack) + 1

                if info then
                    if not def then error(strformat("Usage: class.SetAsTemplate(target, params[, stack]) - The %s's definition is finished", tostring(target)), stack) end
                    info[FLD_IC_MOD]    = turnonflags(MOD_TEMPLATE_IC, info[FLD_IC_MOD])
                    info[FLD_IC_MOD]    = turnonflags(MOD_SEALED_IC,   info[FLD_IC_MOD])

                    info[FLD_IC_TEMPPRM]= type(params) == "table" and getmetatable(params) == nil and params or { params }
                    info[FLD_IC_TEMPIMP]= saveTemplateImplement({}, info[FLD_IC_TEMPPRM], target)
                else
                    error("Usage: class.SetAsTemplate(target, params[, stack]) - The target is not valid", stack)
                end
            end;

            --- Whether the value is an object whose class inherit the target class
            -- @static
            -- @method  ValidateValue
            -- @owner   class
            -- @format  (target, value[, onlyvalid])
            -- @param   target                      the target class
            -- @param   value                       the value used to validate
            -- @param   onlyvalid                   if true use true instead of the error message
            -- @return  value                       the validated value, nil if not valid
            -- @return  error                       the error message if the value is not valid
            ["ValidateValue"]           = function(target, value, onlyvalid)
                if class.IsSubType(getmetatable(value), target) then return value end
                return nil, onlyvalid or ("the %s is not an object of the [class]" .. tostring(target))
            end;

            -- Whether the target is a class
            -- @static
            -- @method  Validate
            -- @owner   class
            -- @param   target                      the target class
            -- @return  target                      return the target if it's a class, otherwise nil
            ["Validate"]                = function(target)
                local info              = getICTargetInfo(target)
                return info and getmetatable(target) == class and target or nil
            end;
        },
        __newindex                      = readonly,
        __call                          = function(self, ...)
            local visitor, env, target, definition, keepenv, stack = getTypeParams(class, tclass, ...)
            if not target then error("Usage: class([env, ][name, ][definition, ][keepenv, ][stack]) - the class type can't be created", stack) end

            if not _ICInfo[target] then
                saveICInfo(target, getInitICInfo(target, true), true)
            end

            stack                       = stack + 1

            if class.IsSealed(target) then
                Debug("[class] %s extend methods", stack, tostring(target))

                local builder           = prototype.NewObject(extendbuilder)
                environment.Initialize  (builder)
                environment.SetNamespace(builder, target)
                environment.SetParent   (builder, env)
                environment.SetDefinitionMode(builder, true)

                if definition then
                    builder(definition, stack)
                    return target
                else
                    return builder
                end
            else
                class.BeginDefinition(target, stack)

                Debug("[class] %s created", stack, tostring(target))

                local builder           = prototype.NewObject(classbuilder)
                environment.Initialize  (builder)
                environment.SetNamespace(builder, target)
                environment.SetParent   (builder, env)
                environment.SetDefinitionMode(builder, true)

                _ICBuilderInDefine      = savestorage(_ICBuilderInDefine, builder, true)

                if definition then
                    builder(definition, stack)
                    return target
                else
                    if not keepenv then safesetfenv(stack, builder) end
                    return builder
                end
            end
        end,
    }

    tinterface                          = prototype (validatetype, {
        __index                         = PLOOP_PLATFORM_SETTINGS.NAMESPACE_NIL_VALUE_ACCESSIBLE and function(self, key)
            if type(key) == "string" then
                -- Access methods
                local info              = _ICBuilderInfo[self] or _ICInfo[self]
                if info then
                    -- Static or object methods
                    local oper          = info[key] or info[FLD_IC_TYPMTD] and info[FLD_IC_TYPMTD][key]
                    if oper then return oper end

                    -- Static features
                    oper                = info[FLD_IC_STAFTR] and info[FLD_IC_STAFTR][key]
                    if oper then return oper:Get(self) end
                end

                -- Access child-namespaces
                return namespace.GetNamespace(self, key)
            else
                local value             = getICImplement(self, key, 2)
                return value
            end
        end or function(self, key)
            if type(key) == "string" then
                -- Access methods
                local info              = _ICBuilderInfo[self] or _ICInfo[self]
                if info then
                    -- Static or object methods
                    local oper          = info[key] or info[FLD_IC_TYPMTD] and info[FLD_IC_TYPMTD][key]
                    if oper then return oper end

                    -- Static features
                    oper                = info[FLD_IC_STAFTR] and info[FLD_IC_STAFTR][key]
                    if oper then return oper:Get(self) end
                end

                -- Access child-namespaces
                local value             = namespace.GetNamespace(self, key)
                if value ~= nil then return value end

                error(strformat("The %s.%s is not existed", namespace.GetNamespaceName(self), key), 2)
            else
                local value             = getICImplement(self, key, 2)
                return value
            end
        end,
        __newindex                      = function(self, key, value)
            if type(key) == "string" then
                local info              = _ICInfo[self]

                if info then
                    -- Static features
                    local oper          = info[FLD_IC_STAFTR] and info[FLD_IC_STAFTR][key]
                    if oper then oper:Set(self, value) return end

                    -- Try add methods
                    if type(value) == "function" then
                        getmetatable(self).AddMethod(self, key, value, 2)
                        return
                    end
                end
            end

            error(strformat("The %s is readonly", tostring(self)), 2)
        end,
        __call                          = function(self, init)
            local info                  = _ICInfo[self]
            local aycls                 = info[FLD_IC_ANYMSCL]
            if not aycls then error(strformat("Usage: the %s doesn't have anonymous class", tostring(self)), 2) end

            if type(init) == "function" then
                local abs               = info[FLD_IC_ONEABS]
                if not abs then error(strformat("Usage: %s([init]) - the interface doesn't have only one abstract method", tostring(self)), 2) end
                init                    = { [abs] = init }
            elseif init and type(init) ~= "table" then
                error(strformat("Usage: %s([init]) - the init can only be a table", tostring(self)), 2)
            end

            return aycls(init)
        end,
        __metatable                     = interface,
    })

    tclass                              = prototype (tinterface, {
        __call                          = function(self, ...)
            local info                  = _ICInfo[self]
            local ok, obj               = pcall(info[FLD_IC_OBCTOR], info, ...)
            if not ok then
                if type(obj)  == "string" then
                    error(obj, 0)
                else
                    error(tostring(obj), 2)
                end
            end
            if info[FLD_IC_DEBUGSR] and rawget(obj, FLD_OBJ_SOURCE) == nil then
                local src               = getcallline(2)
                if src then rawset(obj, FLD_OBJ_SOURCE, src) end
            end
            return obj
        end,
        __metatable                     = class,
    })

    tsuperinterface                     = prototype {
        __tostring                      = function(self) return tostring(_SuperMap[self]) end,
        __index                         = function(self, key)
            local t = type(key)

            if t == "string" then
                local info              = _ICInfo[_SuperMap[self]]
                local f                 = info[FLD_IC_SUPMTD]
                return f and f[key]
            elseif t == "table" then
                rawset(key, OBJ_SUPER_ACCESS, _SuperMap[self])
                return key
            end
        end,
        __newindex                      = readonly,
        __metatable                     = interface,
    }

    tsuperclass                         = prototype (tsuperinterface, {
        __call                          = function(self, obj, ...)
            local cls                   = _SuperMap[self]
            local ocls                  = obj and getmetatable(obj)
            if ocls and class.IsSubType(ocls, cls) then
                local ctor
                if class.GetSuperObjectStyle(ocls) then
                    -- Only this style can work for multi-version classes
                    rawset(obj, OBJ_SUPER_ACCESS, cls)
                    ctor                = safeget(obj, IC_META_CTOR)
                else
                    local info          = _ICInfo[cls][FLD_IC_SUPMTD]
                    ctor                = info and info[IC_META_CTOR]
                end

                if ctor then
                    return ctor(obj, ...)
                else
                    error(strformat("Usage: super(object, ..) - the %s has no super class constructor", tostring(cls)), 2)
                end
            else
                error("Usage: super(object, ..) - the object is not valid", 2)
            end
        end,
        __metatable                     = class,
    })

    interfacebuilder                    = prototype {
        __tostring                      = function(self)
            local owner                 = environment.GetNamespace(self)
            return "[interfacebuilder]" .. (owner and tostring(owner) or "anonymous")
        end,
        __index                         = environment.GetValue,
        __newindex                      = function(self, key, value)
            if not setIFBuilderValue(self, key, value, 2) then
                environment.SaveValue(self, key, value, 2)
            end
        end,
        __call                          = function(self, definition, stack)
            stack                       = parsestack(stack) + 1
            if not definition then error("Usage: interface([env, ][name, ][stack]) (definition) - the definition is missing", stack) end

            local owner                 = environment.GetNamespace(self)
            local info                  = _ICBuilderInfo[owner]
            if not (owner and _ICBuilderInDefine[self] and info) then error("The interface's definition is finished", stack) end

            definition                  = attribute.InitDefinition(owner, ATTRTAR_INTERFACE, parseDefinition(definition, self, stack), nil, nil, stack)
            -- Save template env
            if info[FLD_IC_TEMPDEF] then
                info[FLD_IC_TEMPENV]    = environment.GetParent(self)
            end

            if type(definition) == "function" then
                setfenv(definition, self)

                if validateflags(MOD_TEMPLATE_IC, info[FLD_IC_MOD]) then
                    -- Save for template
                    info[FLD_IC_TEMPDEF]= definition
                    info[FLD_IC_TEMPENV]= environment.GetParent(self)

                    local ok, err       = pcall(definition, self, interface.GetTemplateParameters(owner))
                    if not ok and type(err) == "string" then error(err, 0) end
                else
                    definition(self, interface.GetTemplateParameters(owner))
                end
            else
                -- Index key
                for i, v in ipairs, definition, 0 do
                    setIFBuilderValue(self, i, v, stack, true)
                end

                for k, v in pairs, definition do
                    if type(k) == "string" then
                        setIFBuilderValue(self, k, v, stack, true)
                    end
                end
            end

            attribute.InheritAttributes(owner, ATTRTAR_INTERFACE, unpack(info, FLD_IC_STEXT))
            attribute.ApplyAttributes  (owner, ATTRTAR_INTERFACE, self, nil, nil, stack)

            environment.SetDefinitionMode(self, false)
            _ICBuilderInDefine          = savestorage(_ICBuilderInDefine, self, nil)
            interface.EndDefinition(owner, stack)

            -- Save super refer
            local super                 = interface.GetSuperRefer(owner)
            if super then rawset(self, IC_KEYWORD_SUPER, super) end

            if getfenv(stack)  == self then
                safesetfenv(stack, environment.GetParent(self) or _G)
            end

            return owner
        end,
    }

    classbuilder                        = prototype {
        __tostring                      = function(self)
            local owner                 = environment.GetNamespace(self)
            return "[classbuilder]" .. (owner and tostring(owner) or "anonymous")
        end,
        __index                         = environment.GetValue,
        __newindex                      = function(self, key, value)
            if not setClassBuilderValue(self, key, value, 2) then
                environment.SaveValue(self, key, value, 2)
            end
        end,
        __call                          = function(self, definition, stack)
            stack                       = parsestack(stack) + 1
            if not definition then error("Usage: class([env, ][name, ][stack]) (definition) - the definition is missing", stack) end

            local owner                 = environment.GetNamespace(self)
            local info                  = _ICBuilderInfo[owner]
            if not (owner and _ICBuilderInDefine[self] and info) then error("The class's definition is finished", stack) end

            definition                  = attribute.InitDefinition(owner, ATTRTAR_CLASS, parseDefinition(definition, self, stack), nil, nil, stack)

            -- Save template env
            if info[FLD_IC_TEMPDEF] then
                info[FLD_IC_TEMPENV]    = environment.GetParent(self)
            end

            if type(definition) == "function" then
                setfenv(definition, self)

                if validateflags(MOD_TEMPLATE_IC, info[FLD_IC_MOD]) then
                    -- Save for template
                    info[FLD_IC_TEMPDEF]= definition
                    info[FLD_IC_TEMPENV]= environment.GetParent(self)

                    local ok, err = pcall(definition, self, class.GetTemplateParameters(owner))
                    if not ok and type(err) == "string" then error(err, 0) end
                else
                    definition(self, class.GetTemplateParameters(owner))
                end
            else
                -- Index key
                for i, v in ipairs, definition, 0 do
                    setClassBuilderValue(self, i, v, stack, true)
                end

                for k, v in pairs, definition do
                    if type(k) == "string" then
                        setClassBuilderValue(self, k, v, stack, true)
                    end
                end
            end

            attribute.InheritAttributes(owner, ATTRTAR_CLASS, unpack(info, info[FLD_IC_SUPCLS] and FLD_IC_SUPCLS or FLD_IC_STEXT))
            attribute.ApplyAttributes  (owner, ATTRTAR_CLASS, self, nil, nil, stack)

            environment.SetDefinitionMode(self, false)
            _ICBuilderInDefine          = savestorage(_ICBuilderInDefine, self, nil)
            class.EndDefinition(owner, stack)

            -- Save super refer
            local super                 = class.GetSuperRefer(owner)
            if super then rawset(self, IC_KEYWORD_SUPER, super) end

            if getfenv(stack)  == self then
                safesetfenv(stack, environment.GetParent(self) or _G)
            end

            return owner
        end,
    }

    -- Only works for method extend
    extendbuilder                       = prototype {
        __tostring                      = function(self)
            local owner                 = environment.GetNamespace(self)
            return "[extendbuilder]" .. (owner and tostring(owner) or "anonymous")
        end,
        __index                         = function(self, key)
            local cache                 = rawget(self, FLD_EXD_METHOD)
            local value                 = cache and cache[key] or environment.GetValue(self, key, 2)
            return value
        end,
        __newindex                      = function(self, key, value)
            local owner                 = environment.GetNamespace(self)
            if not owner then return end

            if type(key) == "string" and not tonumber(key) and type(value) == "function" then
                if META_KEYS[key] ~= nil then error(strformat("the %s can't be used as method name", key), 2) end

                local info              = _ICInfo[owner]
                local typmtd            = info[FLD_IC_TYPMTD]

                if typmtd and (typmtd[key] or (typmtd[key] == false and info[key]))
                    or info[FLD_IC_TYPFTR] and info[FLD_IC_TYPFTR][key]
                    or info[FLD_IC_OBJMTD] and info[FLD_IC_OBJMTD][key]
                    or info[FLD_IC_OBJFTR] and info[FLD_IC_OBJFTR][key] then
                    error(strformat("the %s can't be overridden", key), 2)
                end

                if attribute.HaveRegisteredAttributes() then
                    attribute.SaveAttributes(value, ATTRTAR_METHOD, 2)

                    local ret           = attribute.InitDefinition(value, ATTRTAR_METHOD, value, owner, key, 2)
                    if ret ~= value then attribute.ToggleTarget(value, ret) value = ret end

                    attribute.ApplyAttributes (value, ATTRTAR_METHOD, nil, owner, key, 2)
                    attribute.AttachAttributes(value, ATTRTAR_METHOD, owner, key, 2)
                end

                local cache             = rawget(self, FLD_EXD_METHOD)
                if not cache then
                    cache               = {}
                    rawset(self, FLD_EXD_METHOD, cache)
                end
                cache[key]              = value
                return
            end

            environment.SaveValue(self, key, value, 2)
        end,
        __call                          = function(self, definition, stack)
            stack                       = parsestack(stack) + 1

            local owner                 = environment.GetNamespace(self)
            if not owner then error("the environment owner not existed", stack) end

            if not definition then
                if getmetatable(owner) == class then
                    error("Usage: class([env, ][name, ][stack]) (definition) - the definition is missing", stack)
                else
                    error("Usage: interface([env, ][name, ][stack]) (definition) - the definition is missing", stack)
                end
            end

            definition                  = parseDefinition(definition, self, stack)

            if type(definition) == "function" then
                setfenv(definition, self)
                definition(self)
            else
                if getmetatable(owner) == class then
                    error("Usage: class([env, ][name, ][stack]) (definition) - the definition must be a function", stack)
                else
                    error("Usage: interface([env, ][name, ][stack]) (definition) - the definition must be a function", stack)
                end
            end

            environment.SetDefinitionMode(self, false)

            local exdmtds               = rawget(self, FLD_EXD_METHOD)
            if exdmtds then
                for name, func in pairs, exdmtds do
                    interface.AddMethod(owner, name, func, 2)
                end
                rawset(self, FLD_EXD_METHOD, nil)
            end

            return owner
        end,
    }

    -----------------------------------------------------------------------
    --                             keywords                              --
    -----------------------------------------------------------------------

    -----------------------------------------------------------------------
    -- extend an interface to the current class or interface
    --
    -- @keyword     extend
    -- @usage       extend "System.IAttribute"
    -----------------------------------------------------------------------
    extend                              = function (...)
        local visitor, env, name, _, flag, stack        = getFeatureParams(extend, namespace, ...)

        name                            = parseNamespace(name, visitor, env)
        if not name then error("Usage: extend(interface) - The interface is not provided", stack + 1) end

        local owner                     = visitor and environment.GetNamespace(visitor)
        if not owner  then error("Usage: extend(interface) - The system can't figure out the class or interface", stack + 1) end

        interface.AddExtend(owner, name, stack + 1)

        return visitor.extend
    end

    -----------------------------------------------------------------------
    -- Add init fields to the class or interface
    --
    -- @keyword     field
    -- @usage       field { Test = 123, Any = true }
    -----------------------------------------------------------------------
    field                               = function (...)
        local visitor, env, name, definition, flag, stack = getFeatureParams(field, nil, ...)

        if type(definition) ~= "table" then error("Usage: field { key-value pairs } - The field only accept table as definition", stack + 1) end

        local owner                     = visitor and environment.GetNamespace(visitor)

        if owner then
            if class.Validate(owner) then
                class.AddFields(owner, definition, stack + 1)
                return
            elseif interface.Validate(owner) then
                interface.AddFields(owner, definition, stack + 1)
                return
            end
        end

        error("Usage: field { key-value pairs } - The field can't be used here", stack + 1)
    end

    -----------------------------------------------------------------------
    -- inherit a super class to the current class
    --
    -- @keyword     inherit
    -- @usage       inherit "System.Object"
    -----------------------------------------------------------------------
    inherit                             = function (...)
        local visitor, env, name, _, flag, stack        = getFeatureParams(inherit, namespace, ...)

        name                            = parseNamespace(name, visitor, env)
        if not name then error("Usage: inherit(class) - The class is not provided", stack + 1) end

        local owner                     = visitor and environment.GetNamespace(visitor)
        if not owner  then error("Usage: inherit(class) - The system can't figure out the class", stack + 1) end

        class.SetSuperClass(owner, name, stack + 1)
    end

    -----------------------------------------------------------------------
    -- set the require class to the interface
    --
    -- @keyword     require
    -- @usage       require "System.Object"
    -----------------------------------------------------------------------
    require                             = function (...)
        local visitor, env, name, _, flag, stack        = getFeatureParams(require, namespace, ...)

        name                            = parseNamespace(name, visitor, env)
        if not name then error("Usage: require(class) - The class is not provided", stack + 1) end

        local owner                     = visitor and environment.GetNamespace(visitor)
        if not owner  then error("Usage: require(class) - The system can't figure out the interface", stack + 1) end

        interface.SetRequireClass(owner, name, stack + 1)
    end

    -----------------------------------------------------------------------
    -- End the definition of the interface
    --
    -- @keyword     endinterface
    -- @usage       interface "IA"
    --                  function IA(self)
    --                  end
    --              endinterface "IA"
    -----------------------------------------------------------------------
    endinterface                        = PLOOP_PLATFORM_SETTINGS.TYPE_DEFINITION_WITH_OLD_STYLE and function (...)
        local visitor, env, name, definition, flag, stack       = getFeatureParams(endinterface, nil,  ...)
        local owner                     = visitor and environment.GetNamespace(visitor)

        stack                           = stack + 1

        if not owner or not visitor then error([[Usage: endinterface "name" - can't be used here.]], stack) end
        if namespace.GetNamespaceName(owner, true) ~= name then error(strformat("%s's definition isn't finished", tostring(owner)), stack) end

        local info                      = _ICBuilderInfo[owner]
        if not (owner and _ICBuilderInDefine[visitor] and info) then error("The interface's definition is finished", stack) end

        attribute.InheritAttributes(owner, ATTRTAR_INTERFACE, unpack(info, FLD_IC_STEXT))
        attribute.ApplyAttributes  (owner, ATTRTAR_INTERFACE, visitor, nil, nil, stack)

        environment.SetDefinitionMode(visitor, false)
        _ICBuilderInDefine              = savestorage(_ICBuilderInDefine, visitor, nil)
        interface.EndDefinition(owner, stack)

        -- Save super refer
        local super                     = interface.GetSuperRefer(owner)
        if super then rawset(visitor, IC_KEYWORD_SUPER, super) end

        local baseEnv                   = environment.GetParent(visitor) or _G

        setfenv(stack, baseEnv)

        return baseEnv
    end or nil

    -----------------------------------------------------------------------
    -- End the definition of the class
    --
    -- @keyword     endclass
    -- @usage       class "IA"
    --                  function IA(self)
    --                  end
    --              endclass "IA"
    -----------------------------------------------------------------------
    endclass                            = PLOOP_PLATFORM_SETTINGS.TYPE_DEFINITION_WITH_OLD_STYLE and function (...)
        local visitor, env, name, definition, flag, stack       = getFeatureParams(endclass, nil,  ...)
        local owner                     = visitor and environment.GetNamespace(visitor)

        stack                           = stack + 1

        if not owner or not visitor then error([[Usage: endclass "name" - can't be used here.]], stack) end
        if namespace.GetNamespaceName(owner, true) ~= name then error(strformat("%s's definition isn't finished", tostring(owner)), stack) end

        local info                      = _ICBuilderInfo[owner]
        if not (owner and _ICBuilderInDefine[visitor] and info) then error("The class's definition is finished", stack) end

        attribute.InheritAttributes(owner, ATTRTAR_CLASS, unpack(info, info[FLD_IC_SUPCLS] and FLD_IC_SUPCLS or FLD_IC_STEXT))
        attribute.ApplyAttributes  (owner, ATTRTAR_CLASS, visitor, nil, nil, stack)

        environment.SetDefinitionMode(visitor, false)
        _ICBuilderInDefine              = savestorage(_ICBuilderInDefine, visitor, nil)
        class.EndDefinition(owner, stack)

        -- Save super refer
        local super                     = class.GetSuperRefer(owner)
        if super then rawset(visitor, IC_KEYWORD_SUPER, super) end

        local baseEnv                   = environment.GetParent(visitor) or _G

        setfenv(stack, baseEnv)

        return baseEnv
    end or nil
end

-------------------------------------------------------------------------------
-- The events are used to notify the outside that the state of class object has
-- changed. Let's take an example to start :
--
--              class "Person" (function(_ENV)
--                  event "OnNameChanged"
--
--                  field { name = "anonymous" }
--
--                  function SetName(self, name)
--                      if name ~= self.name then
--                          -- Notify the outside
--                          OnNameChanged(self, name, self.name)
--                          self.name = name
--                      end
--                  end
--              end)
--
--              o = Person()
--
--              -- Bind a function as handler to the event
--              function o:OnNameChanged(new, old)
--                  print(("Renamed from %q to %q"):format(old, new))
--              end
--
--              -- Renamed from "anonymous" to "Ann"
--              o:SetName("Ann")
--
-- The event is a feature type of the class and interface, there are two types
-- of the event handler :
--      * the final handler - the previous example has shown how to bind the
--          final handler.
--      * the stackable handler - The stackable handler are normally used in
--          the class's constructor or interface's initializer:
--
--              class "Student" (function(_ENV)
--                  inherit "Person"
--
--                  local function onNameChanged(self, name, old)
--                      print(("Student %s renamed to %s"):format(old, name))
--                  end
--
--                  function Student(self, name)
--                      self:SetName(name)
--                      self.OnNameChanged = self.OnNameChanged + onNameChanged
--                  end
--              end)
--
--              o = Student("Ann")
--
--              function o:OnNameChanged(name)
--                  print("My new name is " .. name)
--              end
--
--              -- Student Ann renamed to Ammy
--              -- My new name is Ammy
--              o:SetName("Ammy")
--
-- The `self.OnNameChanged` is an object generated by **System.Delegate** who
-- has `__add` and `__sub` meta-methods so it can works with the style like
--
--              self.OnNameChanged = self.OnNameChanged + onNameChanged
-- or
--
--              self.OnNameChanged = self.OnNameChanged - onNameChanged
--
-- The stackable handlers are added with orders, so the super class's handler'd
-- be called at first then the class's, then the interface's. The final handler
-- will be called at the last, if any handler `return true`, the call process
-- will be ended.
--
-- In some scenarios, we need to block the object's event, the **Delegate** can
-- set an init function that'd be called before all other handlers, we can use
--
--              self.OnNameChanged:SetInitFunction(function() return true end)
--
-- To block the object's *OnNameChanged* event.
--
-- When using PLoop to wrap objects generated from other system, we may need to
-- bind the PLoop event to other system's event, there is two parts in it :
--      * When the PLoop object's event handlers are changed, we need know when
--  and whether there is any handler for that event, so we can register or
--  un-register in the other system.
--      * When the event of the other system is triggered, we need invoke the
--  PLoop's event.
--
-- Take the *Frame* widget from the *World of Warcraft* as an example, ignore
-- the other details, let's focus on the event two-way binding :
--
--              class "Frame" (function(_ENV)
--                  __EventChangeHandler__(function(delegate, owner, eventname)
--                      -- owner is the frame object
--                      -- eventname is the OnEnter for this case
--                      if delegate:IsEmpty() then
--                          -- No event handler, so un-register the frame's script event
--                          owner:SetScript(eventname, nil)
--                      else
--                          -- Has event handler, so we must regiser the frame's script event
--                          if owner:GetScript(eventname) == nil then
--                              owner:SetScript(eventname, function(self, ...)
--                                  -- Call the delegate directly
--                                  delegate(owner, ...)
--                              end)
--                          end
--                      end
--                  end)
--                  event "OnEnter"
--              end)
--
-- With the `__EventChangeHandler__` attribute, we can bind a function to the
-- target event, so all changes of the event handlers can be checked in the
-- function. Since the event change handler has nothing special with the target
-- event, we can use it on all script events in one system like :
--
--              -- A help class so it can be saved in namespaces
--              class "__WidgetEvent__" (function(_ENV)
--                  local function handler (delegate, owner, eventname)
--                      if delegate:IsEmpty() then
--                          owner:SetScript(eventname, nil)
--                      else
--                          if owner:GetScript(eventname) == nil then
--                              owner:SetScript(eventname, function(self, ...)
--                                  -- Call the delegate directly
--                                  delegate(owner, ...)
--                              end)
--                          end
--                      end
--                  end
--
--                  function __WidgetEvent__(self)
--                      __EventChangeHandler__(handler)
--                  end
--              end)
--
--              class "Frame" (function(_ENV)
--                  __WidgetEvent__()
--                  event "OnEnter"
--
--                  __WidgetEvent__()
--                  event "OnLeave"
--              end)
--
--
-- The event can also be marked as static, so it can be used and only be used by
-- the class or interface :
--
--              class "Person" (function(_ENV)
--                  __Static__()
--                  event "OnPersonCreated"
--
--                  function Person(self, name)
--                      OnPersonCreated(name)
--                  end
--              end)
--
--              function Person.OnPersonCreated(name)
--                  print("Person created " .. name)
--              end
--
--              -- Person created Ann
--              o = Person("Ann")
--
-- When the class or interface has overridden the event, and they need register
-- handler to super event, we can use the super object access style :
--
--              class "Person" (function(_ENV)
--                  property "Name" { event = "OnNameChanged" }
--              end)
--
--              class "Student" (function(_ENV)
--                  inherit "Person"
--
--                  event "OnNameChanged"
--
--                  local function raiseEvent(self, ...)
--                      OnNameChanged(self, ...)
--                  end
--
--                  function Student(self)
--                      super(self)
--
--                      -- Use the super object access style
--                      super[self].OnNameChanged = raiseEvent
--                  end
--              end)
--
--              o = Student()
--
--              function o:OnNameChanged(name)
--                  print("New name is " .. name)
--              end
--
--              -- New name is Test
--              o.Name = "Test"
--
-- @prototype   event
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                         attribute targets                         --
    -----------------------------------------------------------------------
    ATTRTAR_EVENT                       = attribute.RegisterTargetType("Event")

    -----------------------------------------------------------------------
    --                         private constants                         --
    -----------------------------------------------------------------------
    FLD_EVENT_HANDLER                   = newindex(0)
    FLD_EVENT_NAME                      = newindex()
    FLD_EVENT_FIELD                     = newindex()
    FLD_EVENT_OWNER                     = newindex()
    FLD_EVENT_STATIC                    = newindex()
    FLD_EVENT_DELEGATE                  = newindex()

    FLD_EVENT_META                      = "__PLOOP_EVENT_META"
    FLD_EVENT_PREFIX                    = "__PLOOP_EVENT_"

    -----------------------------------------------------------------------
    --                          private storage                          --
    -----------------------------------------------------------------------
    local _EventInfo                    = PLOOP_PLATFORM_SETTINGS.UNSAFE_MODE
                                            and setmetatable({}, {__index = function(_, c) return type(c) == "table" and rawget(c, FLD_EVENT_META) or nil end})
                                            or  newstorage(WEAK_KEY)

    local _EventInDefine                = newstorage(WEAK_KEY)

    -----------------------------------------------------------------------
    --                          private helpers                          --
    -----------------------------------------------------------------------
    local saveEventInfo                 = PLOOP_PLATFORM_SETTINGS.UNSAFE_MODE
                                            and function(target, info) rawset(target, FLD_EVENT_META, info) end
                                            or  function(target, info) _EventInfo = savestorage(_EventInfo, target, info) end

    local genEvent                      = function(owner, name, value, stack)
        local evt                       = prototype.NewProxy(tevent)
        local info                      = {
            [FLD_EVENT_NAME]            = name,
            [FLD_EVENT_FIELD]           = FLD_EVENT_PREFIX .. namespace.GetNamespaceName(owner, true) .. "_" .. name,
            [FLD_EVENT_OWNER]           = owner,
            [FLD_EVENT_STATIC]          = value or nil,
        }

        stack                           = stack + 1

        saveEventInfo(evt, info)

        _EventInDefine                  = savestorage(_EventInDefine, evt, true)

        attribute.SaveAttributes(evt, ATTRTAR_EVENT, stack + 1)

        local super                     = interface.GetSuperFeature(owner, name)
        if super and event.Validate(super) then attribute.InheritAttributes(evt, ATTRTAR_EVENT, super) end
        attribute.ApplyAttributes(evt, ATTRTAR_EVENT, nil, owner, name, stack)

        _EventInDefine                  = savestorage(_EventInDefine, evt, nil)

        -- Convert to static event
        if not value and event.IsStatic(evt) then
            saveEventInfo(evt, nil)
            local new                   = prototype.NewProxy(tsevent)
            attribute.ToggleTarget(evt, new)
            evt                         = new
            saveEventInfo(evt, info)
        end

        attribute.AttachAttributes(evt, ATTRTAR_EVENT, owner, name, stack)

        return evt
    end

    local invokeEvent                   = function(self, obj, ...)
        -- No check, as simple as it could be
        local delegate                  = rawget(obj, _EventInfo[self][FLD_EVENT_FIELD])
        if delegate then return delegate:Invoke(obj, ...) end
    end

    local invokeStaticEvent             = function(self,...)
        local delegate                  = _EventInfo[self][FLD_EVENT_DELEGATE]
        if delegate then return delegate:Invoke(...) end
    end

    -----------------------------------------------------------------------
    --                             prototype                             --
    -----------------------------------------------------------------------
    event                               = prototype {
        __tostring                      = "event",
        __index                         = {
            --- Gets the event's owner
            -- @static
            -- @method  GetOwner
            -- @owner   event
            -- @param   target                      the target event
            -- @return  owner
            ["GetOwner"]                = function(self)
                local info              = _EventInfo[self]
                return info and info[FLD_EVENT_OWNER]
            end;

            --- Gets the event's name
            -- @static
            -- @method  GetName
            -- @owner   event
            -- @param   target                      the target event
            -- @return  name
            ["GetName"]                 = function(self)
                local info              = _EventInfo[self]
                return info and info[FLD_EVENT_NAME]
            end;

            --- Get the event delegate
            -- @static
            -- @method  Get
            -- @owner   event
            -- @param   target                      the target event
            -- @param   object                      the object if the event is not static
            -- @param   nocreation                  true if no need to generate the delegate if not existed
            -- @return  delegate                    the event's delegate
            ["Get"]                     = function(self, obj, nocreation)
                local info              = _EventInfo[self]
                if info then
                    if info[FLD_EVENT_STATIC] then
                        local delegate  = info[FLD_EVENT_DELEGATE]
                        if not delegate and not nocreation then
                            local owner = info[FLD_EVENT_OWNER]
                            local name  = info[FLD_EVENT_NAME]
                            delegate    = Delegate(owner, name)
                            info[FLD_EVENT_DELEGATE]    = delegate

                            if info[FLD_EVENT_HANDLER] then
                                local handler           = info[FLD_EVENT_HANDLER]
                                attribute.IndependentCall(function()
                                    delegate.OnChange   = delegate.OnChange + function(self)
                                        return handler(self, owner, name)
                                    end
                                end)
                            end
                        end
                        return delegate
                    elseif type(obj) == "table" then
                        local delegate                  = rawget(obj, info[FLD_EVENT_FIELD])
                        if not delegate or getmetatable(delegate) ~= Delegate then
                            if nocreation then return end

                            delegate                    = Delegate(obj, info[FLD_EVENT_NAME])
                            rawset(obj, info[FLD_EVENT_FIELD], delegate)

                            if info[FLD_EVENT_HANDLER] then
                                local name              = info[FLD_EVENT_NAME]
                                local handler           = info[FLD_EVENT_HANDLER]
                                attribute.IndependentCall(function()
                                    delegate.OnChange   = delegate.OnChange + function(self)
                                        return handler(self, obj, name)
                                    end
                                end)
                            end
                        end
                        return delegate
                    end
                end
            end;

            --- Get the feature itself
            -- @static
            -- @method  GetFeature()
            -- @owner   event
            -- @param   target                      the target event
            -- @return  event
            ["GetFeature"]              = function(self) return self end;

            --- Get the event change handler
            -- @static
            -- @method  GetEventChangeHandler
            -- @owner   event
            -- @param   target                      the target event
            -- @return  handler                     the event's change handler
            ["GetEventChangeHandler"]   = function(self)
                local info              = _EventInfo[self]
                return info and info[FLD_EVENT_HANDLER] or false
            end;

            --- Whether the event's data is shared, always true
            -- @static
            -- @method  IsShareable
            -- @owner   event
            -- @param   target                      the target event
            -- @return  true
            ["IsShareable"]             = function() return true end;

            --- Whether the event is static
            -- @static
            -- @method  IsStatic
            -- @owner   event
            -- @param   target                      the target event
            -- @return  boolean                     true if the event is static
            ["IsStatic"]                = function(self)
                local info              = _EventInfo[self]
                return info and info[FLD_EVENT_STATIC] or false
            end;

            --- Invoke an event with parameters
            -- @static
            -- @method  Invoke
            -- @owner   event
            -- @format  (target[, object], ...)
            -- @param   target                      the target event
            -- @param   object                      the object if the event is not static
            -- @param   ...                         the parameters
            ["Invoke"]                  = function(self, ...) return self:Invoke(...) end;

            --- Parse a string-boolean pair as the event's definition, the string is the event's name and true marks it as static
            -- @static
            -- @method  Parse
            -- @owner   event
            -- @format  (target, key, value[, stack])
            -- @param   target                      the target class or interface
            -- @param   key                         the key
            -- @param   value                       the value
            -- @param   stack                       the stack level
            -- @return  boolean                     true if key-value pair can be used as the event's definition
            ["Parse"]                   = function(owner, key, value, stack)
                if type(key) == "string" and type(value) == "boolean" and owner and (interface.Validate(owner) or class.Validate(owner)) then
                    stack               = parsestack(stack) + 1
                    local evt           = genEvent(owner, key, value, stack)
                    interface.AddFeature(owner, key, evt, stack)
                    return true
                end
            end;

            --- Set delegate or a final handler to the event's delegate
            -- @static
            -- @method  Set
            -- @owner   event
            -- @format  (target, object, delegate[, stack])
            -- @param   target                      the target event
            -- @param   object                      the object if the event is not static
            -- @param   delegate                    the delegate used to copy or the final handler
            -- @param   stack                       the stack level
            ["Set"]                     = function(self, obj, delegate, stack)
                local info              = _EventInfo[self]
                stack                   = parsestack(stack) + 1
                if not info then error("Usage: event:Set(obj, delegate[, stack]) - the event is not valid", stack) end
                if type(obj) ~= "table" and type(obj) ~= "userdata" then error("Usage: event:Set(obj, delegate[, stack]) - the object is not valid", stack) end

                local odel              = self:Get(obj, true)

                if delegate == nil then
                    if odel then odel:SetFinalFunction(nil) end
                    return
                end

                if type(delegate) == "function" then
                    odel                = odel or self:Get(obj)

                    if attribute.HaveRegisteredAttributes() then
                        local name      = info[FLD_EVENT_NAME]
                        attribute.SaveAttributes(delegate, ATTRTAR_FUNCTION, stack)
                        local ret       = attribute.InitDefinition(delegate, ATTRTAR_FUNCTION, delegate, obj, name, stack)
                        if ret ~= delegate then
                            attribute.ToggleTarget(delegate, ret)
                            delegate    = ret
                        end
                        attribute.ApplyAttributes(delegate, ATTRTAR_FUNCTION, nil, obj, name, stack)
                        attribute.AttachAttributes(delegate, ATTRTAR_FUNCTION, obj, name, stack)
                    end
                    odel:SetFinalFunction(delegate)
                elseif getmetatable(delegate) == Delegate then
                    odel                = odel or self:Get(obj)

                    if delegate ~= odel then
                        delegate:CopyTo(odel)
                    end
                else
                    error("Usage: event:Set(obj, delegate[, stack]) - the delegate can only be function or object of System.Delegate", stack)
                end
            end;

            --- Set the event change handler
            -- @static
            -- @method  SetEventChangeHandler
            -- @owner   event
            -- @format  (target, handler[, stack])
            -- @param   target                      the target event
            -- @param   handler                     the event's change handler
            -- @param   stack                       the stack level
            ["SetEventChangeHandler"]   = function(self, handler, stack)
                stack                   = parsestack(stack) + 1
                if _EventInDefine[self] then
                    if type(handler) ~= "function" then error("Usage: event:SetEventChangeHandler(handler[, stack]) - the handler must be a function", stack) end
                    _EventInfo[self][FLD_EVENT_HANDLER] = handler
                else
                    error("Usage: event:SetEventChangeHandler(handler[, stack]) - the event's definition is finished", stack)
                end
            end;

            --- Set the event as static
            -- @static
            -- @method  SetStatic
            -- @owner   event
            -- @format  (target[, stack])
            -- @param   target                      the target event
            -- @param   stack                       the stack level
            ["SetStatic"]               = function(self, stack)
                if _EventInDefine[self] then
                    _EventInfo[self][FLD_EVENT_STATIC] = true
                else
                    error("Usage: event:SetStatic([stack]) - the event's definition is finished", parsestack(stack) + 1)
                end
            end;

            --- Whether the target is an event
            -- @static
            -- @method  Validate
            -- @owner   event
            -- @param   target                      the target event
            -- @return  target                      return the target if it's an event
            ["Validate"]                = function(self) return _EventInfo[self] and self or nil end;
        },
        __newindex                      = readonly,
        __call                          = function(self, ...)
            local visitor, env, name, definition, flag, stack = getFeatureParams(event, nil, ...)

            stack                       = stack + 1

            if not name or name == "" then error([[Usage: event "name" - the name must be a string]], stack) end

            local owner = visitor and environment.GetNamespace(visitor)

            if owner and (interface.Validate(owner) or class.Validate(owner)) then
                local evt               = genEvent(owner, name, flag or false, stack)

                interface.AddFeature(owner, name, evt, stack)

                -- Save the event proxy to the visitor, so it can be called directly
                rawset(visitor, name, evt)

                return evt
            else
                error([[Usage: event "name" - the event can't be used here.]], stack)
            end
        end,
    }

    tevent                              = prototype {
        __tostring                      = function(self)
            local info                  = _EventInfo[self]
            return "[event]" .. namespace.GetNamespaceName(info[FLD_EVENT_OWNER]) .. "." .. info[FLD_EVENT_NAME]
        end;
        __index                         = {
            ["GetOwner"]                = event.GetOwner;
            ["GetName"]                 = event.GetName;
            ["Get"]                     = event.Get;
            ["GetFeature"]              = event.GetFeature;
            ["GetEventChangeHandler"]   = event.GetEventChangeHandler;
            ["Invoke"]                  = invokeEvent;
            ["IsShareable"]             = event.IsShareable;
            ["IsStatic"]                = event.IsStatic;
            ["Set"]                     = event.Set;
            ["SetEventChangeHandler"]   = event.SetEventChangeHandler;
            ["SetStatic"]               = event.SetStatic;
        },
        __newindex                      = readonly,
        __call                          = invokeEvent,
        __metatable                     = event,
    }

    tsevent                             = prototype (tevent, {
        __index                         = {
            ["Invoke"]                  = invokeStaticEvent;
        },
        __call                          = invokeStaticEvent;
        __metatable                     = event,
    })

    -----------------------------------------------------------------------
    --                            registration                           --
    -----------------------------------------------------------------------
    interface.RegisterParser(event)
end

-------------------------------------------------------------------------------
-- The properties are object states, we can use the table fields to act as the
-- object states, but they lack the value validation, and we also can't track
-- the modification of those fields.
--
-- Like the event, the property is also a feature type of the interface and
-- class. The property system provide many mechanisms like get/set, value type
-- validation, value changed handler, value changed event, default value and
-- default value factory. Let's start with a simple example :
--
--              class "Person" (function(_ENV)
--                  property "Name" { type = String }
--                  property "Age"  { type = Number }
--              end)
--
--              -- If the class has no constructor, we can use the class to create the object based on a table
--              -- the table is called the init-table
--              o = Person{ Name = "Ann", Age = 10 }
--
--              print(o.Name)-- Ann
--              o.Name = 123 -- Error : the Name must be [String]
--
-- The **Person** class has two properties: *Name* and *Age*, the table after
-- `property "Name"` is the definition of the *Name* property, it contains a
-- *type* field that contains the property value's type, so when we assign a
-- number value to the *Name*, the operation is failed.
--
-- Like the **member** of the **struct**, we use table to give the property's
-- definition, the key is case ignored, here is a full list:
--
--      * auto          whether use the auto-binding mechanism for the property
--              see blow example for details.
--
--      * get           the function used to get the property value from the
--              object like `get(obj)`, also you can set **false** to it, so
--              the property can't be read
--
--      * set           the function used to set the property value of the
--              object like `set(obj, value)`, also you can set **false** to
--              it, so the property can't be written
--
--      * getmethod     the string name used to specified the object method to
--              get the value like `obj[getmethod](obj)`
--
--      * setmethod     the string name used to specified the object method to
--              set the value like `obj[setmethod](obj, value)`
--
--      * field         the table field to save the property value, no use if
--              get/set specified, like the *Name* of the **Person**, since
--              there is no get/set or field specified, the system will auto
--              generate a field for it, it's recommended.
--
--      * type          the value's type, if the value is immutable, the type
--              validation can be turn off for release version, just turn on
--              **TYPE_VALIDATION_DISABLED** in the **PLOOP_PLATFORM_SETTINGS**
--
--      * default       the default value
--
--      * event         the event used to handle the property value changes,
--              if it's value is string, an event will be created:
--
--                  class "Person" (function(_ENV)
--                      property "Name" { type = String, event = "OnNameChanged" }
--                  end)
--
--                  o = Person { Name = "Ann" }
--
--                  function o:OnNameChanged(new, old, prop)
--                      print(("[%s] %s -> %s"):format(prop, old, new))
--                  end
--
--                  -- [Name] Ann -> Ammy
--                  o.Name = "Ammy"
--
--      * handler       the function used to handle the property value changes,
--               unlike the event, the handler is used to notify the class or
--              interface itself, normally this is used combine with **field**
--              (or auto-gen field), so the class or interface only need to act
--              based on the value changes :
--
--                  class "Person" (function(_ENV)
--                      property "Name" {
--                          type = String, default = "anonymous",
--                          handler = function(self, new, old, prop) print(("[%s] %s -> %s"):format(prop, old, new)) end
--                      }
--                  end)
--
--                  --[Name] anonymous -> Ann
--                  o = Person { Name = "Ann" }
--
--                  --[Name] Ann -> Ammy
--                  o.Name = "Ammy"
--
--      * static        true if the property is a static property
--
--      * indexer       true if the property is an indexer property
--
--      * throwable     true if the property may throw error in the set method
--
-- If the **auto** auto-binding mechanism is using and the definition don't
-- provide get/set, getmethod/setmethod and field, the system will check the
-- property owner's method(object method if non-static, static method if it
-- is static), if the property name is **name**:
--
--      * The *setname*, *Setname*, *SetName*, *setName* will be scanned, if it
--  existed, the method will be used as the **set** setting
--
--                  class "Person" (function(_ENV)
--                      function SetName(self, name)
--                          print("SetName", name)
--                      end
--
--                      property "Name" { type = String, auto = true }
--                  end)
--
--                  -- SetName  Ann
--                  o = Person { Name = "Ann"}
--
--                  -- SetName  Ammy
--                  o.Name = "Ammy"
--
--      * The *getname*, *Getname*, *Isname*, *isname*, *getName*, *GetName*,
--  *IsName*, *isname* will be scanned, if it exsited, the method will be used
--  as the **get** setting
--
-- When the class or interface has overridden the property, they still can use
-- the super object access style to use the super's property :
--
--                  class "Person" (function(_ENV)
--                      property "Name" { event = "OnNameChanged" }
--                  end)
--
--                  class "Student" (function(_ENV)
--                      inherit "Person"
--
--                      property "Name" {
--                          Set = function(self, name)
--                              -- Use super property to save
--                              super[self].Name = name
--                          end,
--                          Get = function(self)
--                              -- Use super property to fetch
--                              return super[self].Name
--                          end,
--                      }
--                  end)
--
--                  o = Student()
--                  o.Name = "Test"
--                  print(o.Name)   -- Test
--
-- You also can build indexer properties like :
--
--                  class "A" (function( _ENV )
--                      __Indexer__(Integer)  -- The index tyep
--                      property "Items" {
--                          set = function(self, idx, value)
--                              self[idx] = value
--                          end,
--                          get = function(self, idx)
--                              return self[idx]
--                          end,
--                          type = String,    -- The value type
--                      }
--                  end)
--
--                  o = A()
--
--                  o.Items[1] = "Hello"
--
--                  print(o.Items[1])   -- Hello
--
-- The indexer property can only accept set, get, getmethod, setmethod, type
-- and static definitions.
--
-- @prototype   property
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                         attribute targets                         --
    -----------------------------------------------------------------------
    ATTRTAR_PROPERTY                    = attribute.RegisterTargetType("Property")

    -----------------------------------------------------------------------
    --                         private constants                         --
    -----------------------------------------------------------------------
    -- MODIFIER
    MOD_PROP_STATIC                     = newflags(true)

    MOD_PROP_SETCLONE                   = newflags()
    MOD_PROP_SETDEEPCL                  = newflags()
    MOD_PROP_SETRETAIN                  = newflags()
    MOD_PROP_SETWEAK                    = newflags()

    MOD_PROP_GETCLONE                   = newflags()
    MOD_PROP_GETDEEPCL                  = newflags()

    MOD_PROP_AUTOSCAN                   = newflags()
    MOD_PROP_INDEXER                    = newflags()
    MOD_PROP_THROWABLE                  = newflags()
    MOD_PROP_REQUIRE                    = newflags()

    -- PROPERTY FIELDS
    FLD_PROP_MOD                        = newindex(0)
    FLD_PROP_RAWGET                     = newindex()
    FLD_PROP_RAWSET                     = newindex()
    FLD_PROP_NAME                       = newindex()
    FLD_PROP_OWNER                      = newindex()
    FLD_PROP_TYPE                       = newindex()
    FLD_PROP_VALID                      = newindex()
    FLD_PROP_FIELD                      = newindex()
    FLD_PROP_GET                        = newindex()
    FLD_PROP_SET                        = newindex()
    FLD_PROP_GETMETHOD                  = newindex()
    FLD_PROP_SETMETHOD                  = newindex()
    FLD_PROP_DEFAULT                    = newindex()
    FLD_PROP_DEFAULTFUNC                = newindex()
    FLD_PROP_HANDLER                    = newindex()
    FLD_PROP_EVENT                      = newindex()
    FLD_PROP_STATIC                     = newindex()
    FLD_PROP_INDEXERTYP                 = newindex()
    FLD_PROP_INDEXERVLD                 = newindex()
    FLD_PROP_INDEXERGET                 = newindex()
    FLD_PROP_INDEXERSET                 = newindex()
    FLD_PROP_INDEXERFLD                 = newindex()

    -- FLAGS FOR PROPERTY BUILDING
    FLG_PROPGET_DISABLE                 = newflags(true)
    FLG_PROPGET_DEFAULT                 = newflags()
    FLG_PROPGET_DEFTFUNC                = newflags()
    FLG_PROPGET_GET                     = newflags()
    FLG_PROPGET_GETMETHOD               = newflags()
    FLG_PROPGET_FIELD                   = newflags()
    FLG_PROPGET_SETWEAK                 = newflags()
    FLG_PROPGET_SETFALSE                = newflags()
    FLG_PROPGET_CLONE                   = newflags()
    FLG_PROPGET_DEEPCLONE               = newflags()
    FLG_PROPGET_STATIC                  = newflags()
    FLG_PROPGET_INDEXER                 = newflags()
    FLG_PROPGET_INDEXTYP                = newflags()

    FLG_PROPSET_DISABLE                 = newflags(true)
    FLG_PROPSET_TYPE                    = newflags()
    FLG_PROPSET_CLONE                   = newflags()
    FLG_PROPSET_DEEPCLONE               = newflags()
    FLG_PROPSET_SET                     = newflags()
    FLG_PROPSET_SETMETHOD               = newflags()
    FLG_PROPSET_FIELD                   = newflags()
    FLG_PROPSET_DEFAULT                 = newflags()
    FLG_PROPSET_SETWEAK                 = newflags()
    FLG_PROPSET_RETAIN                  = newflags()
    FLG_PROPSET_SIMPDEFT                = newflags()
    FLG_PROPSET_HANDLER                 = newflags()
    FLG_PROPSET_EVENT                   = newflags()
    FLG_PROPSET_STATIC                  = newflags()
    FLG_PROPSET_INDEXER                 = newflags()
    FLG_PROPSET_INDEXTYP                = newflags()
    FLG_PROPSET_THROWABLE               = newflags()
    FLG_PROPSET_REQUIRE                 = newflags()

    FLD_PROP_META                       = "__PLOOP_PROPERTY_META"
    FLD_PROP_OBJ_WEAK                   = "__PLOOP_PROPERTY_WEAK"

    FLD_INDEXER_OBJECT                  = function() end
    FLD_INDEXER_GET                     = function() end
    FLD_INDEXER_SET                     = function() end

    -----------------------------------------------------------------------
    --                          private storage                          --
    -----------------------------------------------------------------------
    local _PropertyInfo                 = PLOOP_PLATFORM_SETTINGS.UNSAFE_MODE
                                            and setmetatable({}, {__index = function(_, c) return type(c) == "table" and rawget(c, FLD_PROP_META) or nil end})
                                            or  newstorage(WEAK_KEY)

    local _PropertyInDefine             = newstorage(WEAK_KEY)

    local _PropGetMap                   = {}
    local _PropSetMap                   = {}

    local _PropGetPrefix                = { "get", "Get", "is", "Is" }
    local _PropSetPrefix                = { "set", "Set" }

    -----------------------------------------------------------------------
    --                          private helpers                          --
    -----------------------------------------------------------------------
    local globalIndexerOwner
    local globalIndexerGet
    local globalIndexerSet
    local globalPropertyIndexer         = not PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD and prototype {
                                            __index         = function(self, idxname)
                                                local val   = globalIndexerGet(globalIndexerOwner, idxname)
                                                return val
                                            end,
                                            __newindex      = function(self, idxname, value) globalIndexerSet(globalIndexerOwner, idxname, value) end,
                                        }

    local savePropertyInfo              = PLOOP_PLATFORM_SETTINGS.UNSAFE_MODE
                                            and function(target, info) rawset(target, FLD_PROP_META, info) end
                                            or  function(target, info) _PropertyInfo = savestorage(_PropertyInfo, target, info) end

    local genProperty                   = function(owner, name, stack)
        local prop                      = prototype.NewProxy(tproperty)
        local info                      = {
            [FLD_PROP_NAME]             = name,
            [FLD_PROP_OWNER]            = owner,
        }

        savePropertyInfo(prop, info)

        _PropertyInDefine               = savestorage(_PropertyInDefine, prop, true)

        attribute.SaveAttributes(prop, ATTRTAR_PROPERTY, stack + 1)

        local super                     = interface.GetSuperFeature(owner, name)
        if super and property.Validate(super) then attribute.InheritAttributes(prop, ATTRTAR_PROPERTY, super) end

        return prop
    end

    local getPropertyIndexer            = PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD and function(get, set, fld, isstaic, owner)
            if isstaic then
                local idxer             = prototype.NewObject(tindexer, { [FLD_INDEXER_OBJECT] = owner, [FLD_INDEXER_GET] = get, [FLD_INDEXER_SET] = set })
                return function(_, self) return idxer end
            else
                return function(_, self)
                    local idxer         = rawget(self, fld)
                    if not idxer then
                        idxer           = prototype.NewObject(tindexer, { [FLD_INDEXER_OBJECT] = self, [FLD_INDEXER_GET] = get, [FLD_INDEXER_SET] = set })
                        rawset(self, fld, idxer)
                    end
                    return idxer
                end
            end
        end or function(get, set)
            return function(_, self)
                globalIndexerOwner      = self
                globalIndexerGet        = get
                globalIndexerSet        = set
                return globalPropertyIndexer
            end
        end

    local genPropertyGet                = function (info)
        local token                     = 0
        local usename                   = false
        local upval                     = _Cache()

        if info[FLD_PROP_GET]  == false or (info[FLD_PROP_GET] == nil and info[FLD_PROP_GETMETHOD] == nil and info[FLD_PROP_FIELD] == nil and info[FLD_PROP_DEFAULTFUNC] == nil and info[FLD_PROP_DEFAULT] == nil) then
            token                       = turnonflags(FLG_PROPGET_DISABLE, token)
            usename                     = true
        else
            if validateflags(MOD_PROP_INDEXER, info[FLD_PROP_MOD]) then
                token                   = turnonflags(FLG_PROPGET_INDEXER, token)

                if info[FLD_PROP_INDEXERVLD] then
                    usename             = true
                    token               = turnonflags(FLG_PROPGET_INDEXTYP, token)
                    tinsert(upval, info[FLD_PROP_INDEXERVLD])
                    tinsert(upval, info[FLD_PROP_INDEXERTYP])
                end
            end

            if info[FLD_PROP_DEFAULTFUNC] then
                token                   = turnonflags(FLG_PROPGET_DEFTFUNC, token)
                tinsert(upval, info[FLD_PROP_DEFAULTFUNC])
                if info[FLD_PROP_SET] == false then
                    token               = turnonflags(FLG_PROPGET_SETFALSE, token)
                else
                    usename             = true
                end
            elseif info[FLD_PROP_DEFAULT] ~= nil then
                token                   = turnonflags(FLG_PROPGET_DEFAULT, token)
                tinsert(upval, info[FLD_PROP_DEFAULT])
            end

            if validateflags(MOD_PROP_SETWEAK, info[FLD_PROP_MOD]) then
                token                   = turnonflags(FLG_PROPGET_SETWEAK, token)
            end

            if validateflags(MOD_PROP_STATIC, info[FLD_PROP_MOD]) then
                token                   = turnonflags(FLG_PROPGET_STATIC, token)
                if validateflags(FLG_PROPGET_SETWEAK, token) then
                    tinsert(upval, info[FLD_PROP_STATIC])
                else
                    tinsert(upval, info)
                end
            end

            if info[FLD_PROP_GET] then
                token                   = turnonflags(FLG_PROPGET_GET, token)
                tinsert(upval, info[FLD_PROP_GET])
            elseif info[FLD_PROP_GETMETHOD] then
                token                   = turnonflags(FLG_PROPGET_GETMETHOD, token)
                tinsert(upval, info[FLD_PROP_GETMETHOD])
            elseif info[FLD_PROP_FIELD] ~= nil then
                token                   = turnonflags(FLG_PROPGET_FIELD, token)
                tinsert(upval, info[FLD_PROP_FIELD])
            end

            if validateflags(MOD_PROP_GETCLONE, info[FLD_PROP_MOD]) then
                token                   = turnonflags(FLG_PROPGET_CLONE, token)
                if validateflags(MOD_PROP_GETDEEPCL, info[FLD_PROP_MOD]) then
                    token               = turnonflags(FLG_PROPGET_DEEPCLONE, token)
                end
            end
        end

        if usename then tinsert(upval, info[FLD_PROP_NAME]) end

        -- Building
        if not _PropGetMap[token] then
            local head                  = _Cache()
            local body                  = _Cache()
            local apis                  = _Cache()

            tinsert(body, "")                       -- remain for shareable variables
            tinsert(body, "return function(%s)")    -- remain for special variables
            if validateflags(FLG_PROPGET_INDEXER, token) then
                tinsert(body, [[return function(self, idxname)]])
            else
                tinsert(body, [[return function(_, self)]])
            end

            if validateflags(FLG_PROPGET_DISABLE, token) then
                uinsert(apis, "error")
                uinsert(apis, "strformat")
                tinsert(body, [[error(strformat("the %s can't be read", name),2)]])
            else
                if validateflags(FLG_PROPGET_INDEXTYP, token) then
                    tinsert(head, "ivalid")
                    tinsert(head, "ivtype")
                    tinsert(body, [[
                        local ret, msg = ivalid(ivtype, idxname)
                        if msg then error(strgsub(type(msg) == "string" and msg or "the %s is not valid", "%%s", name .. "'s key"), 3) end
                        idxname = ret
                    ]])
                end

                if validateflags(FLG_PROPGET_DEFTFUNC, token) then
                    tinsert(head, "defaultFunc")
                elseif validateflags(FLG_PROPGET_DEFAULT, token) then
                    tinsert(head, "default")
                end

                if validateflags(FLG_PROPGET_STATIC, token) then
                    uinsert(apis, "fakefunc")
                    tinsert(head, "storage")
                end

                tinsert(body, [[local value]])

                if validateflags(FLG_PROPGET_GET, token) then
                    tinsert(head, "get")
                    if validateflags(FLG_PROPGET_INDEXER, token) then
                        tinsert(body, [[value = get(self, idxname)]])
                    else
                        tinsert(body, [[value = get(self)]])
                    end
                elseif validateflags(FLG_PROPGET_GETMETHOD, token) then
                    -- won't be static
                    tinsert(head, "getMethod")
                    if validateflags(FLG_PROPGET_INDEXER, token) then
                        tinsert(body, [[value = self[getMethod](self, idxname)]])
                    else
                        tinsert(body, [[value = self[getMethod](self)]])
                    end
                elseif validateflags(FLG_PROPGET_FIELD, token) then
                    tinsert(head, "field")
                    if validateflags(FLG_PROPGET_STATIC, token) then
                        if validateflags(FLG_PROPGET_SETWEAK, token) then
                            tinsert(body, [[value = storage[0] ]])
                        else
                            tinsert(body, [[value = storage[]] .. FLD_PROP_STATIC .. [[] ]])
                        end
                        tinsert(body, [[if value == fakefunc then value = nil end]])
                    else
                        uinsert(apis, "rawget")
                        if validateflags(FLG_PROPGET_SETWEAK, token) then
                            tinsert(body, [[
                                value = rawget(self, "]] .. __PLOOP_PROPERTY_WEAK .. [[")
                                if type(value) == "table" then value = value[field] else value = nil end
                            ]])
                        else
                            tinsert(body, [[value = rawget(self, field)]])
                        end
                    end
                end

                -- Nil Handler
                if validateflags(FLG_PROPGET_DEFTFUNC, token) or validateflags(FLG_PROPGET_DEFAULT, token) then
                    tinsert(body, [[if value == nil then]])

                    if validateflags(FLG_PROPGET_DEFTFUNC, token) then
                        tinsert(body, [[value = defaultFunc(self)]])
                        tinsert(body, [[if value ~= nil then]])

                        if validateflags(FLG_PROPGET_STATIC, token) then
                            if validateflags(FLG_PROPGET_SETFALSE, token) then
                                if validateflags(FLG_PROPGET_SETWEAK, token) then
                                    tinsert(body, [[storage[0] = value]])
                                else
                                    tinsert(body, [[storage[]] .. FLD_PROP_STATIC .. [[] = value]])
                                end
                            else
                                tinsert(body, [[self[name]=value]])
                            end
                        else
                            if validateflags(FLG_PROPGET_SETFALSE, token) then
                                uinsert(apis, "rawset")
                                if validateflags(FLG_PROPGET_SETWEAK, token) then
                                    uinsert(apis, "rawget")
                                    uinsert(apis, "type")
                                    uinsert(apis, "setmetatable")
                                    uinsert(apis, "WEAK_VALUE")
                                    tinsert(body, [[
                                        local container = rawget(self, "]] .. __PLOOP_PROPERTY_WEAK .. [[")
                                        if type(container) ~= "table" then
                                            container   = setmetatable({}, WEAK_VALUE)
                                            rawset(self, "]] .. __PLOOP_PROPERTY_WEAK .. [[", container)
                                        end
                                        container[field] = value
                                    ]])
                                else
                                    tinsert(body, [[rawset(self, field, value)]])
                                end
                            else
                                tinsert(body, [[self[name]=value]])
                            end
                        end

                        tinsert(body, [[end]])
                    elseif validateflags(FLG_PROPGET_DEFAULT, token) then
                        tinsert(body, [[value = default]])
                    end

                    tinsert(body, [[end]])
                end

                -- Clone
                if validateflags(FLG_PROPGET_CLONE, token) then
                    uinsert(apis, "clone")
                    if validateflags(FLG_PROPGET_DEEPCLONE) then
                        tinsert(body, [[value = clone(value, true, true)]])
                    else
                        tinsert(body, [[value = clone(value)]])
                    end
                end

                tinsert(body, [[return value]])
            end
            tinsert(body, [[end]])
            tinsert(body, [[end]])

            if usename then tinsert(head, "name") end

            if #apis > 0 then
                local declare           = tblconcat(apis, ", ")
                body[1]                 = strformat("local %s = %s", declare, declare)
            end

            body[2]                     = strformat(body[2], #head > 0 and tblconcat(head, ", ") or "")

            _PropGetMap[token]          = loadsnippet(tblconcat(body, "\n"), "Property_Get_" .. token, _PLoopEnv)()

            if #head == 0 then
                _PropGetMap[token]      = _PropGetMap[token]()
            end

            _Cache(head) _Cache(body) _Cache(apis)
        end

        if #upval > 0 then
            info[FLD_PROP_RAWGET]       = _PropGetMap[token](unpack(upval))
        else
            info[FLD_PROP_RAWGET]       = _PropGetMap[token]
        end

        if validateflags(MOD_PROP_INDEXER, info[FLD_PROP_MOD]) then
            info[FLD_PROP_INDEXERGET]   = info[FLD_PROP_RAWGET]
            info[FLD_PROP_RAWGET]       = getPropertyIndexer(info[FLD_PROP_INDEXERGET], info[FLD_PROP_INDEXERSET], info[FLD_PROP_INDEXERFLD], validateflags(MOD_PROP_STATIC, info[FLD_PROP_MOD]), info[FLD_PROP_OWNER])
        end

        _Cache(upval)
    end

    local genPropertySet                = function (info)
        local token                     = 0
        local usename                   = false
        local upval                     = _Cache()

        -- Calc the token
        if info[FLD_PROP_SET]  == false or (info[FLD_PROP_SET] == nil and info[FLD_PROP_SETMETHOD] == nil and info[FLD_PROP_FIELD] == nil) then
            token                       = turnonflags(FLG_PROPSET_DISABLE, token)
            usename                     = true
        else
            if validateflags(MOD_PROP_REQUIRE, info[FLD_PROP_MOD]) then
                token                   = turnonflags(FLG_PROPSET_REQUIRE, token)
                usename                 = true
            end

            if validateflags(MOD_PROP_INDEXER, info[FLD_PROP_MOD]) then
                token                   = turnonflags(FLG_PROPSET_INDEXER, token)

                if info[FLD_PROP_INDEXERVLD] then
                    usename             = true
                    token               = turnonflags(FLG_PROPSET_INDEXTYP, token)
                    tinsert(upval, info[FLD_PROP_INDEXERVLD])
                    tinsert(upval, info[FLD_PROP_INDEXERTYP])
                end
            end

            if info[FLD_PROP_TYPE] and not (PLOOP_PLATFORM_SETTINGS.TYPE_VALIDATION_DISABLED and getobjectvalue(info[FLD_PROP_TYPE], "IsImmutable")) then
                token                   = turnonflags(FLG_PROPSET_TYPE, token)
                tinsert(upval, info[FLD_PROP_VALID])
                tinsert(upval, info[FLD_PROP_TYPE])
                usename                 = true
            end

            if validateflags(MOD_PROP_SETCLONE, info[FLD_PROP_MOD]) then
                token                   = turnonflags(FLG_PROPSET_CLONE, token)
                if validateflags(MOD_PROP_SETDEEPCL, info[FLD_PROP_MOD]) then
                    token               = turnonflags(FLG_PROPSET_DEEPCLONE, token)
                end
            end

            if validateflags(MOD_PROP_SETWEAK, info[FLD_PROP_MOD]) then
                token                   = turnonflags(FLG_PROPSET_SETWEAK, token)
            end

            if validateflags(MOD_PROP_STATIC, info[FLD_PROP_MOD]) then
                token                   = turnonflags(FLG_PROPSET_STATIC, token)
                if validateflags(FLG_PROPSET_SETWEAK, token) then
                    tinsert(upval, info[FLD_PROP_STATIC])
                else
                    tinsert(upval, info)
                end
            end

            if info[FLD_PROP_SET] then
                token                   = turnonflags(FLG_PROPSET_SET, token)
                tinsert(upval, info[FLD_PROP_SET])

                if validateflags(MOD_PROP_THROWABLE, info[FLD_PROP_MOD]) then
                    token               = turnonflags(FLG_PROPSET_THROWABLE, token)
                end
            elseif info[FLD_PROP_SETMETHOD] and not validateflags(MOD_PROP_STATIC, info[FLD_PROP_MOD]) then
                token                   = turnonflags(FLG_PROPSET_SETMETHOD, token)
                tinsert(upval, info[FLD_PROP_SETMETHOD])

                if validateflags(MOD_PROP_THROWABLE, info[FLD_PROP_MOD]) then
                    token               = turnonflags(FLG_PROPSET_THROWABLE, token)
                end
            elseif info[FLD_PROP_FIELD] then
                token                   = turnonflags(FLG_PROPSET_FIELD, token)
                tinsert(upval, info[FLD_PROP_FIELD])

                if info[FLD_PROP_DEFAULT] ~= nil then
                    token               = turnonflags(FLG_PROPSET_DEFAULT, token)
                    tinsert(upval, info[FLD_PROP_DEFAULT])

                    if type(info[FLD_PROP_DEFAULT]) ~= "table" then
                        token           = turnonflags(FLG_PROPSET_SIMPDEFT, token)
                    end
                end

                if validateflags(MOD_PROP_SETRETAIN, info[FLD_PROP_MOD]) then
                    token               = turnonflags(FLG_PROPSET_RETAIN, token)
                end

                if info[FLD_PROP_HANDLER] then
                    token               = turnonflags(FLG_PROPSET_HANDLER, token)
                    tinsert(upval, info[FLD_PROP_HANDLER])
                    usename             = true
                end

                if info[FLD_PROP_EVENT] then
                    token               = turnonflags(FLG_PROPSET_EVENT, token)
                    tinsert(upval, info[FLD_PROP_EVENT])
                    usename             = true
                end
            end
        end

        if usename then tinsert(upval, info[FLD_PROP_NAME]) end

        -- Building
        if not _PropSetMap[token] then
            local head                  = _Cache()
            local body                  = _Cache()
            local apis                  = _Cache()

            tinsert(body, "")                       -- remain for shareable variables
            tinsert(body, "return function(%s)")    -- remain for special variables

            if validateflags(FLG_PROPSET_INDEXER, token) then
                tinsert(body, [[return function(self, idxname, value)]])
            else
                tinsert(body, [[return function(_, self, value)]])
            end

            if validateflags(FLG_PROPSET_DISABLE, token) then
                uinsert(apis, "error")
                uinsert(apis, "strformat")
                tinsert(body, [[error(strformat("the %s can't be set", name), 3)]])
            else
                if validateflags(FLG_PROPSET_INDEXTYP, token) then
                    uinsert(apis, "error")
                    uinsert(apis, "strgsub")
                    uinsert(apis, "type")
                    tinsert(head, "ivalid")
                    tinsert(head, "ivtype")
                    tinsert(body, [[
                        local ret, msg = ivalid(ivtype, idxname)
                        if msg then error(strgsub(type(msg) == "string" and msg or "the %s is not valid", "%%s", name .. "'s key"), 3) end
                        idxname = ret
                    ]])
                end

                if validateflags(FLG_PROPSET_REQUIRE, token) then
                    uinsert(apis, "error")
                    uinsert(apis, "strformat")
                    tinsert(body, [[
                        if value == nil then error(strformat("the %s's value can't be nil", name), 3) end
                    ]])
                end

                if validateflags(FLG_PROPSET_TYPE, token) or validateflags(FLG_PROPSET_CLONE, token) then
                    if not validateflags(FLG_PROPSET_REQUIRE, token) then
                        tinsert(body, [[
                            if value ~= nil then
                        ]])
                    end
                    if validateflags(FLG_PROPSET_TYPE, token) then
                        uinsert(apis, "error")
                        uinsert(apis, "type")
                        uinsert(apis, "strgsub")
                        tinsert(head, "valid")
                        tinsert(head, "vtype")

                        if validateflags(FLG_PROPSET_INDEXER, token) then
                            tinsert(body, [[
                                local ret, msg = valid(vtype, value)
                                if msg then error(strgsub(type(msg) == "string" and msg or "the %s is not valid", "%%s", name .. "'s value"), 3) end
                                value = ret
                            ]])
                        else
                            tinsert(body, [[
                                local ret, msg = valid(vtype, value)
                                if msg then error(strgsub(type(msg) == "string" and msg or "the %s is not valid", "%%s", name), 3) end
                                value = ret
                            ]])
                        end
                    end

                    if validateflags(FLG_PROPSET_CLONE, token) then
                        uinsert(apis, "clone")
                        if validateflags(FLG_PROPSET_DEEPCLONE, token) then
                            tinsert(body, [[value = clone(value, true, true)]])
                        else
                            tinsert(body, [[value = clone(value)]])
                        end
                    end

                    if not validateflags(FLG_PROPSET_REQUIRE, token) then
                        tinsert(body, [[
                            end
                        ]])
                    end
                end
                if validateflags(FLG_PROPSET_STATIC, token) then
                    uinsert(apis, "fakefunc")
                    tinsert(head, "storage")
                end

                if validateflags(FLG_PROPSET_THROWABLE, token) then
                    uinsert(apis, "pcall")
                    uinsert(apis, "type")
                    uinsert(apis, "tostring")
                    uinsert(apis, "error")
                end

                if validateflags(FLG_PROPSET_SET, token) then
                    tinsert(head, "set")
                    if validateflags(FLG_PROPSET_INDEXER, token) then
                        if validateflags(FLG_PROPSET_THROWABLE, token) then
                            tinsert(body, [[
                                local ok, err = pcall(set, self, idxname, value)
                                if not ok then
                                    if type(err) == "string" then
                                        error(err, 0)
                                    else
                                        error(tostring(err), 3)
                                    end
                                end
                            ]])
                        else
                            tinsert(body, [[return set(self, idxname, value)]])
                        end
                    else
                        if validateflags(FLG_PROPSET_THROWABLE, token) then
                            tinsert(body, [[
                                local ok, err = pcall(set, self, value)
                                if not ok then
                                    if type(err) == "string" then
                                        error(err, 0)
                                    else
                                        error(tostring(err), 3)
                                    end
                                end
                            ]])
                        else
                            tinsert(body, [[return set(self, value)]])
                        end
                    end
                elseif validateflags(FLG_PROPSET_SETMETHOD, token) then
                    tinsert(head, "setmethod")
                    if validateflags(FLG_PROPSET_INDEXER, token) then
                        if validateflags(FLG_PROPSET_THROWABLE, token) then
                            tinsert(body, [[
                                local ok, err = pcall(self[setmethod], self, idxname, value)
                                if not ok then
                                    if type(err) == "string" then
                                        error(err, 0)
                                    else
                                        error(tostring(err), 3)
                                    end
                                end
                            ]])
                        else
                            tinsert(body, [[return self[setmethod](self, idxname, value)]])
                        end
                    else
                        if validateflags(FLG_PROPSET_THROWABLE, token) then
                            tinsert(body, [[
                                local ok, err = pcall(self[setmethod], self, value)
                                if not ok then
                                    if type(err) == "string" then
                                        error(err, 0)
                                    else
                                        error(tostring(err), 3)
                                    end
                                end
                            ]])
                        else
                            tinsert(body, [[return self[setmethod](self, value)]])
                        end
                    end
                elseif validateflags(FLG_PROPSET_FIELD, token) then
                    tinsert(head, "field")

                    local useold = validateflags(FLG_PROPSET_DEFAULT, token) or validateflags(FLG_PROPSET_RETAIN, token) or validateflags(FLG_PROPSET_HANDLER, token) or validateflags(FLG_PROPSET_EVENT, token)

                    if useold then
                        if validateflags(FLG_PROPSET_STATIC, token) then
                            if validateflags(FLG_PROPSET_SETWEAK, token) then
                                tinsert(body, [[local old = storage[0] ]])
                            else
                                tinsert(body, [[local old = storage[]] .. FLD_PROP_STATIC .. [[] ]])
                            end

                            tinsert(body, [[if old == fakefunc then old = nil end]])
                        else
                            uinsert(apis, "rawset")
                            uinsert(apis, "rawget")
                            if validateflags(FLG_PROPSET_SETWEAK, token) then
                                uinsert(apis, "type")
                                uinsert(apis, "setmetatable")
                                uinsert(apis, "WEAK_VALUE")
                                tinsert(body, [[
                                    local container = rawget(self, "]] .. __PLOOP_PROPERTY_WEAK .. [[")
                                    if type(container) ~= "table" then
                                        container   = setmetatable({}, WEAK_VALUE)
                                        rawset(self, "]] .. __PLOOP_PROPERTY_WEAK .. [[", container)
                                    end
                                    local old = container[field]
                                ]])
                            else
                                tinsert(body, [[local old = rawget(self, field)]])
                            end
                        end

                        if validateflags(FLG_PROPSET_DEFAULT, token) then
                            tinsert(head, "default")
                            tinsert(body, [[if (old == default or old == nil) and (value == nil or value == default) then return end]])
                        end

                        tinsert(body, [[if old == value then return end]])
                    end

                    if validateflags(FLG_PROPSET_STATIC, token) then
                        if validateflags(FLG_PROPSET_SETWEAK, token) then
                            tinsert(body, [[storage[0] = value == nil and fakefunc or value ]])
                        else
                            tinsert(body, [[storage[]] .. FLD_PROP_STATIC .. [[] = value == nil and fakefunc or value ]])
                        end
                    else
                        if validateflags(FLG_PROPSET_SETWEAK, token) then
                            if useold then
                                tinsert(body, [[container[field] = value)]])
                            else
                                tinsert(body, [[
                                    local container = rawget(self, "]] .. __PLOOP_PROPERTY_WEAK .. [[")
                                    if type(container) ~= "table" then
                                        container   = setmetatable({}, WEAK_VALUE)
                                        rawset(self, "]] .. __PLOOP_PROPERTY_WEAK .. [[", container)
                                    end
                                    container[field] = value
                                ]])
                            end
                        else
                            tinsert(body, [[rawset(self, field, value)]])
                        end
                    end

                    if validateflags(FLG_PROPSET_DEFAULT, token) and validateflags(FLG_PROPSET_SIMPDEFT, token) then
                        tinsert(body, [[if old == nil then old = default end]])
                        tinsert(body, [[if value == nil then value = default end]])
                    end

                    if validateflags(FLG_PROPSET_HANDLER, token) then
                        tinsert(head, "handler")
                        tinsert(body, [[handler(self, value, old, name)]])
                    end

                    if validateflags(FLG_PROPSET_EVENT, token) then
                        tinsert(head, "evt")
                        tinsert(body, [[evt(self, value, old, name)]])
                    end

                    if validateflags(FLG_PROPSET_RETAIN, token) then
                        uinsert(apis, "pcall")
                        uinsert(apis, "disposeObj")
                        if validateflags(FLG_PROPSET_DEFAULT, token) then
                            tinsert(body, [[if old and old ~= default then pcall(disposeObj, old) end]])
                        else
                            tinsert(body, [[if old then pcall(disposeObj, old) end]])
                        end
                    end
                end
            end

            tinsert(body, [[end]])
            tinsert(body, [[end]])

            if usename then tinsert(head, "name") end

            if #apis > 0 then
                local declare           = tblconcat(apis, ", ")
                body[1]                 = strformat("local %s = %s", declare, declare)
            end

            body[2]                     = strformat(body[2], #head > 0 and tblconcat(head, ", ") or "")

            _PropSetMap[token]          = loadsnippet(tblconcat(body, "\n"), "Property_Set_" .. token, _PLoopEnv)()

            if #head == 0 then
                _PropSetMap[token]      = _PropSetMap[token]()
            end

            _Cache(head)
            _Cache(body)
            _Cache(apis)
        end

        if #upval > 0 then
            info[FLD_PROP_RAWSET]       = _PropSetMap[token](unpack(upval))
        else
            info[FLD_PROP_RAWSET]       = _PropSetMap[token]
        end

        if validateflags(MOD_PROP_INDEXER, info[FLD_PROP_MOD]) then
            info[FLD_PROP_INDEXERSET]   = info[FLD_PROP_RAWSET]
            local emsg                  = "the " .. info[FLD_PROP_NAME] .. " can't be set"
            info[FLD_PROP_RAWSET]       = function() error(emsg, 3) end
        end

        _Cache(upval)
    end

    -----------------------------------------------------------------------
    --                             prototype                             --
    -----------------------------------------------------------------------
    property                            = prototype {
        __index                         = {
            --- Gets the property's owner
            -- @static
            -- @method  GetOwner
            -- @owner   property
            -- @param   target                      the target property
            -- @return  owner
            ["GetOwner"]                = function(self)
                local info              = _PropertyInfo[self]
                return info and info[FLD_PROP_OWNER]
            end;

            --- Gets the property's name
            -- @static
            -- @method  GetName
            -- @owner   property
            -- @param   target                      the target property
            -- @return  name
            ["GetName"]                 = function(self)
                local info              = _PropertyInfo[self]
                return info and info[FLD_PROP_NAME]
            end;

            --- Get the property accessor, the accessor will be used by object to get/set value instead of the property itself
            -- @static
            -- @method  GetAccessor
            -- @owner   property
            -- @param   target                      the target property
            -- @return  accessor                    A table like { Get = func, Set = func }
            ["GetAccessor"]             = function(self)
                local info              = _PropertyInfo[self]
                if not info then return end

                if not info[FLD_PROP_RAWGET] then
                    local name          = info[FLD_PROP_NAME]
                    local uname         = name:gsub("^%a", strupper)
                    local owner         = info[FLD_PROP_OWNER]
                    local isstatic      = validateflags(MOD_PROP_STATIC, info[FLD_PROP_MOD])

                    -- Check get method
                    if info[FLD_PROP_GETMETHOD] then
                        local mtd, st   = interface.GetMethod(owner, info[FLD_PROP_GETMETHOD])
                        if not mtd and not isstatic then mtd, st = interface.GetSuperMethod(owner, info[FLD_PROP_GETMETHOD]), false end
                        if mtd and isstatic == st then
                            if isstatic then
                                info[FLD_PROP_GETMETHOD]= nil
                                info[FLD_PROP_GET]      = mtd
                            end
                        else
                            Warn("The %s don't have a %smethod named %q for property %q's get method", tostring(owner), isstatic and "static " or "", info[FLD_PROP_GETMETHOD], name)
                            info[FLD_PROP_GETMETHOD]    = nil
                        end
                    end

                    -- Check set method
                    if info[FLD_PROP_SETMETHOD] then
                        local mtd, st   = interface.GetMethod(owner, info[FLD_PROP_SETMETHOD])
                        if not mtd and not isstatic then mtd, st = interface.GetSuperMethod(owner, info[FLD_PROP_SETMETHOD]), false end
                        if mtd and isstatic == st then
                            if isstatic then
                                info[FLD_PROP_SETMETHOD]= nil
                                info[FLD_PROP_SET]      = mtd
                            end
                        else
                            Warn("The %s don't have a %smethod named %q for property %q's set method", tostring(owner), isstatic and "static " or "", info[FLD_PROP_SETMETHOD], name)
                            info[FLD_PROP_SETMETHOD]    = nil
                        end
                    end

                    if not validateflags(MOD_PROP_INDEXER, info[FLD_PROP_MOD]) then
                        -- Auto-gen get (only check GetXXX, getXXX, IsXXX, isXXX for simple)
                        if info[FLD_PROP_GET] == true or (info[FLD_PROP_GET] == nil and info[FLD_PROP_GETMETHOD] == nil and info[FLD_PROP_FIELD] == nil) then
                            info[FLD_PROP_GET]          = nil

                            if validateflags(MOD_PROP_AUTOSCAN, info[FLD_PROP_MOD]) then
                                for _, prefix in ipairs, _PropGetPrefix, 0 do
                                    local mtd, st       = interface.GetMethod(owner, prefix .. name)
                                    if mtd and isstatic == st then
                                        info[FLD_PROP_GET] = mtd
                                        Debug("The %s's property %q use method named %q as get method", tostring(owner), name, prefix .. name)
                                        break
                                    end

                                    if uname ~= name then
                                        mtd, st         = interface.GetMethod(owner, prefix .. uname)
                                        if mtd and isstatic == st then
                                            info[FLD_PROP_GET] = mtd
                                            Debug("The %s's property %q use method named %q as get method", tostring(owner), name, prefix .. uname)
                                            break
                                        end
                                    end
                                end

                                if not info[FLD_PROP_GET] then
                                    Warn("The %s don't have %smethod for property %q's get method", tostring(owner), isstatic and "static " or "", name)
                                end
                            end
                        end

                        -- Auto-gen set (only check SetXXX, setXXX)
                        if info[FLD_PROP_SET] == true or (info[FLD_PROP_SET] == nil and info[FLD_PROP_SETMETHOD] == nil and info[FLD_PROP_FIELD] == nil) then
                            info[FLD_PROP_SET]          = nil

                            if validateflags(MOD_PROP_AUTOSCAN, info[FLD_PROP_MOD]) then
                                for _, prefix in ipairs, _PropSetPrefix, 0 do
                                    local mtd, st       = interface.GetMethod(owner, prefix .. name)
                                    if mtd and isstatic == st then
                                        info[FLD_PROP_SET] = mtd
                                        Debug("The %s's property %q use method named %q as set method", tostring(owner), name, prefix .. name)
                                        break
                                    end

                                    if uname ~= name then
                                        local mtd, st   = interface.GetMethod(owner, prefix .. uname)
                                        if mtd and isstatic == st then
                                            info[FLD_PROP_SET] = mtd
                                            Debug("The %s's property %q use method named %q as set method", tostring(owner), name, prefix .. uname)
                                            break
                                        end
                                    end
                                end

                                if not info[FLD_PROP_SET] then
                                    Warn("The %s don't have %smethod for property %q's set method", tostring(owner), isstatic and "static " or "", name)
                                end
                            end
                        end

                        -- Check the handler
                        if type(info[FLD_PROP_HANDLER]) == "string" then
                            local mtd, st = interface.GetMethod(owner, info[FLD_PROP_HANDLER])
                            if not mtd and not isstatic then mtd, st = interface.GetSuperMethod(owner, info[FLD_PROP_HANDLER]), false end
                            if mtd and isstatic == st then
                                info[FLD_PROP_HANDLER]  = mtd
                            else
                                Warn("The %s don't have a %smethod named %q for property %q's handler", tostring(owner), isstatic and "static " or "", info[FLD_PROP_HANDLER], name)
                                info[FLD_PROP_HANDLER]  = nil
                            end
                        end

                        -- Auto-gen field
                        if (info[FLD_PROP_SET] == nil or (info[FLD_PROP_SET] == false and info[FLD_PROP_DEFAULTFUNC]))
                            and info[FLD_PROP_SETMETHOD] == nil
                            and info[FLD_PROP_GET] == nil and info[FLD_PROP_GETMETHOD] == nil then

                            if info[FLD_PROP_FIELD] == true then info[FLD_PROP_FIELD] = nil end

                            info[FLD_PROP_FIELD]        = info[FLD_PROP_FIELD] or "_" .. namespace.GetNamespaceName(owner, true) .. "_" .. uname
                        end

                        -- Gen static value container
                        if isstatic then
                            -- Use fakefunc as nil object
                            if validateflags(MOD_PROP_SETWEAK, info[FLD_PROP_MOD]) then
                                info[FLD_PROP_STATIC]   = setmetatable({ [0] = fakefunc }, WEAK_VALUE)
                            else
                                info[FLD_PROP_STATIC]   = fakefunc
                            end
                        end
                    end

                    -- Generate the get & set
                    genPropertySet(info)
                    genPropertyGet(info)
                end

                return { Get = info[FLD_PROP_RAWGET], Set = info[FLD_PROP_RAWSET], GetFeature = function() return self end }
            end;

            --- Get the feature itself
            -- @static
            -- @method  GetFeature()
            -- @owner   property
            -- @param   target                      the target property
            -- @return  property
            ["GetFeature"]              = function(self) return self end;

            --- Get the property field if existed
            -- @static
            -- @method  GetField
            -- @owner   property
            -- @param   target                      the target property
            -- @return  string                      the property's field
            ["GetField"]                = function(self)
                local info              = _PropertyInfo[self]
                return info and info[FLD_PROP_FIELD] or nil
            end;

            --- Whether the property should return a clone copy of the value
            -- @static
            -- @method  IsGetClone
            -- @owner   property
            -- @param   target                      the target property
            -- @return  boolean                     true if should return a clone copy of the value
            ["IsGetClone"]              = function(self)
                local info              = _PropertyInfo[self]
                return info and validateflags(MOD_PROP_GETCLONE, info[FLD_PROP_MOD]) or false
            end;

            --- Whether the property should return a deep clone copy of the value
            -- @static
            -- @method  IsGetDeepClone
            -- @owner   property
            -- @param   target                      the target property
            -- @return  boolean                     true if should return a deep clone copy of the value
            ["IsGetDeepClone"]          = function(self)
                local info              = _PropertyInfo[self]
                return info and validateflags(MOD_PROP_GETDEEPCL, info[FLD_PROP_MOD]) or false
            end;

            --- Whether the property is an indexer property, used like `obj.prop[xxx]       = xxx`
            -- @static
            -- @method  IsIndexer
            -- @owner   property
            -- @param   target                      the target property
            -- @return  boolean                     true if the property is an indexer
            ["IsIndexer"]               = function(self)
                local info              = _PropertyInfo[self]
                return info and validateflags(MOD_PROP_INDEXER, info[FLD_PROP_MOD]) or false
            end;

            --- Whether the property is readable
            -- @static
            -- @method  IsReadable
            -- @owner   property
            -- @param   target                      the target property
            -- @return  boolean                     true if the property is readable
            ["IsReadable"]              = function(self)
                local info              = _PropertyInfo[self]
                return info and not (info[FLD_PROP_GET] == false or (info[FLD_PROP_GET] == nil and info[FLD_PROP_GETMETHOD] == nil and info[FLD_PROP_FIELD] == nil and info[FLD_PROP_DEFAULTFUNC] == nil and info[FLD_PROP_DEFAULT] == nil)) or false
            end;

            --- Whether the property should save a clone copy to the value
            -- @static
            -- @method  IsSetClone
            -- @owner   property
            -- @param   target                      the target property
            -- @return  boolean                     true if should save a clone copy to the value
            ["IsSetClone"]              = function(self)
                local info              = _PropertyInfo[self]
                return info and validateflags(MOD_PROP_SETCLONE, info[FLD_PROP_MOD]) or false
            end;

            --- Whether the property should save a deep clone copy to the value
            -- @static
            -- @method  IsSetDeepClone
            -- @owner   property
            -- @param   target                      the target property
            -- @return  boolean                     true if should save a deep clone copy to the value
            ["IsSetDeepClone"]          = function(self)
                local info              = _PropertyInfo[self]
                return info and validateflags(MOD_PROP_SETDEEPCL, info[FLD_PROP_MOD]) or false
            end;

            --- Whether the property should dispose the old value
            -- @static
            -- @method  IsRetainObject
            -- @owner   property
            -- @param   target                      the target property
            -- @return  boolean                     true if should dispose the old value
            ["IsRetainObject"]          = function(self)
                local info              = _PropertyInfo[self]
                return info and validateflags(MOD_PROP_SETRETAIN, info[FLD_PROP_MOD]) or false
            end;

            --- Whether the property data is shareable, always true
            -- @static
            -- @method  IsShareable
            -- @owner   property
            -- @param   target                      the target property
            -- @return  true
            ["IsShareable"]             = function(self) return true end;

            --- Whether the property is static
            -- @static
            -- @method  IsStatic
            -- @owner   property
            -- @param   target                      the target property
            -- @return  boolean                     true if the property is static
            ["IsStatic"]                = function(self)
                local info              = _PropertyInfo[self]
                return info and validateflags(MOD_PROP_STATIC, info[FLD_PROP_MOD]) or false
            end;

            --- Whether the property is throwable
            -- @static
            -- @method  IsThrowable
            -- @owner   property
            -- @param   target                      the target property
            -- @return  boolean                     true if the property is throwable
            ["IsThrowable"]             = function(self)
                local info              = _PropertyInfo[self]
                return info and validateflags(MOD_PROP_THROWABLE, info[FLD_PROP_MOD]) or false
            end;

            --- Whether the property can't take nil value
            -- @static
            -- @method  IsValueRequired
            -- @owner   property
            -- @param   target
            -- @return  boolean                     true if the property's value can't be nil
            ["IsValueRequired"]         = function(self)
                local info              = _PropertyInfo[self]
                return info and validateflags(MOD_PROP_REQUIRE, info[FLD_PROP_MOD]) or false
            end;

            --- Whether the property value should kept in a weak table
            -- @static
            -- @method  IsWeak
            -- @owner   property
            -- @param   target                      the target property
            -- @return  boolean                     true if the property value should kept in a weak table
            ["IsWeak"]                  = function(self)
                local info              = _PropertyInfo[self]
                return info and validateflags(MOD_PROP_SETWEAK, info[FLD_PROP_MOD]) or false
            end;

            --- Whether the property is writable
            -- @static
            -- @method  IsWritable
            -- @owner   property
            -- @param   target                      the target property
            -- @return  boolean                     true if the property is writable
            ["IsWritable"]              = function(self)
                local info              = _PropertyInfo[self]
                return info and not (info[FLD_PROP_SET] == false or (info[FLD_PROP_SET] == nil and info[FLD_PROP_SETMETHOD] == nil and info[FLD_PROP_FIELD] == nil)) or false
            end;

            --- Set the property whether it should return a clone copy of the value
            -- @static
            -- @method  GetClone
            -- @owner   property
            -- @format  (target[, deep[, stack]])
            -- @param   target                      the target property
            -- @param   deep                        true if need deep clone
            -- @param   stack                       the stack level
            ["GetClone"]                = function(self, deep, stack)
                if _PropertyInDefine[self] then
                    local info          = _PropertyInfo[self]
                    info[FLD_PROP_MOD]  = turnonflags(MOD_PROP_GETCLONE, info[FLD_PROP_MOD])
                    if deep then info[FLD_PROP_MOD] = turnonflags(MOD_PROP_GETDEEPCL, info[FLD_PROP_MOD]) end
                else
                    error("Usage: property:GetClone(deep, [stack]) - the property's definition is finished", parsestack(stack) + 1)
                end
            end;

            --- Has Default Value
            -- @static
            -- @method  HasDefault
            -- @owner   property
            -- @param   target                      the target property
            -- @return  bool                        whether the property has default value
            ["HasDefault"]              = function(self)
                local info              = _PropertyInfo[self]
                return info and info[FLD_PROP_DEFAULT] ~= nil or false
            end;

            --- Has Default Value Factory
            -- @static
            -- @method  HasDefaultFactory
            -- @owner   property
            -- @param   target                      the target property
            -- @return  bool                        whether the property has default value factory
            ["HasDefaultFactory"]       = function(self)
                local info              = _PropertyInfo[self]
                return info and info[FLD_PROP_DEFAULTFUNC] ~= nil or false
            end;

            --- Get the property default value
            -- @static
            -- @method  GetType
            -- @owner   property
            -- @param   target                      the target property
            -- @return  default                     the default value
            ["GetDefault"]              = function(self)
                local info              = _PropertyInfo[self]
                if info then return clone(info[FLD_PROP_DEFAULT]) end
            end;

            --- Get the property type
            -- @static
            -- @method  GetType
            -- @owner   property
            -- @param   target                      the target property
            -- @return  type                        the value type
            ["GetType"]                 = function(self)
                local info              = _PropertyInfo[self]
                return info and info[FLD_PROP_TYPE] or nil
            end;

            --- Get the index key type
            -- @static
            -- @method  GetIndexType
            -- @owner   property
            -- @param   target                      the target property
            -- @return  type                        the index key type
            ["GetIndexType"]            = function(self)
                local info              = _PropertyInfo[self]
                return info and info[FLD_PROP_INDEXERTYP] or nil
            end;

            --- Parse a string-[table|type] pair as the property's definition, the string is the property's name and the value should be a table or a valid type
            -- @static
            -- @method  Parse
            -- @owner   property
            -- @format  (target, key, value[, stack])
            -- @param   target                      the target class or interface
            -- @param   key                         the key
            -- @param   value                       the value
            -- @param   stack                       the stack level
            -- @return  boolean                     true if key-value pair can be used as the property's definition
            ["Parse"]                   = function(owner, key, value, stack)
                if type(key)   == "string" and (getprototypemethod(value, "ValidateValue") or (type(value) == "table" and getmetatable(value) == nil)) and owner and (interface.Validate(owner) or class.Validate(owner)) then
                    stack               = parsestack(stack) + 1
                    if getprototypemethod(value, "ValidateValue") then value = { type = value } end
                    local prop          = genProperty(owner, key, stack)
                    prop(value, stack)
                    return true
                end
            end;

            --- Set the property whether it should save a clone copy of the value
            -- @static
            -- @method  SetClone
            -- @owner   property
            -- @format  (target[, deep[, stack]])
            -- @param   target                      the target property
            -- @param   deep                        true if need deep clone
            -- @param   stack                       the stack level
            ["SetClone"]                = function(self, deep, stack)
                if _PropertyInDefine[self] then
                    local info          = _PropertyInfo[self]
                    info[FLD_PROP_MOD]  = turnonflags(MOD_PROP_SETCLONE, info[FLD_PROP_MOD])
                    if deep then info[FLD_PROP_MOD]  = turnonflags(MOD_PROP_SETDEEPCL, info[FLD_PROP_MOD]) end
                else
                    error("Usage: property:SetClone(deep, [stack]) - the property's definition is finished", parsestack(stack) + 1)
                end
            end;

            --- Set the property as an indexer property, used like `obj.prop[xxx] = xxx`, also can set the type of the key
            -- @static
            -- @method  IsIndexer
            -- @owner   property
            -- @format  (target[, type[, stack]])
            -- @param   target                      the target property
            -- @param   stack                       the stack level
            ["SetIndexer"]              = function(self, type, stack)
                if _PropertyInDefine[self] then
                    local tvald         = type and getprototypemethod(type, "ValidateValue")
                    if type and not tvald then
                        error("Usage: property:SetIndexer([type[, stack]]) - the type is not valid", parsestack(stack) + 1)
                    end

                    local info          = _PropertyInfo[self]
                    info[FLD_PROP_MOD]          = turnonflags(MOD_PROP_INDEXER, info[FLD_PROP_MOD])
                    info[FLD_PROP_INDEXERTYP]   = type
                    info[FLD_PROP_INDEXERVLD]   = tvald
                else
                    error("Usage: property:SetIndexer([type[, stack]]) - the property's definition is finished", parsestack(stack) + 1)
                end
            end;

            --- Set the property whether it should dispose the old value
            -- @static
            -- @method  SetRetainObject
            -- @owner   property
            -- @format  (target[, stack]])
            -- @param   target                      the target property
            -- @param   stack                       the stack level
            ["SetRetainObject"]         = function(self, stack)
                if _PropertyInDefine[self] then
                    local info          = _PropertyInfo[self]
                    info[FLD_PROP_MOD]  = turnonflags(MOD_PROP_SETRETAIN, info[FLD_PROP_MOD])
                else
                    error("Usage: property:SetRetainObject([stack]) - the property's definition is finished", parsestack(stack) + 1)
                end
            end;

            --- Mark the property as static
            -- @static
            -- @method  SetStatic
            -- @owner   property
            -- @format  (target[, stack]])
            -- @param   target                      the target property
            -- @param   stack                       the stack level
            ["SetStatic"]               = function(self, stack)
                if _PropertyInDefine[self] then
                    local info          = _PropertyInfo[self]
                    info[FLD_PROP_MOD]  = turnonflags(MOD_PROP_STATIC, info[FLD_PROP_MOD])
                else
                    error("Usage: property:SetStatic([stack]) - the property's definition is finished", parsestack(stack) + 1)
                end
            end;

            --- Mark the property as throwable
            -- @static
            -- @method  SetThrowable
            -- @owner   property
            -- @format  (target[, stack]])
            -- @param   target                      the target property
            -- @param   stack                       the stack level
            ["SetThrowable"]            = function(self)
                if _PropertyInDefine[self] then
                    local info          = _PropertyInfo[self]
                    info[FLD_PROP_MOD]  = turnonflags(MOD_PROP_THROWABLE, info[FLD_PROP_MOD])
                else
                    error("Usage: property:SetThrowable([stack]) - the property's definition is finished", parsestack(stack) + 1)
                end
            end;

            --- Mark the property so it can't take nil value
            -- @static
            -- @method  SetValueRequired
            -- @owner   property
            -- @format  (target[, stack]])
            -- @param   target                      the target property
            -- @param   stack                       the stack level
            ["SetValueRequired"]        = function(self)
                if _PropertyInDefine[self] then
                    local info          = _PropertyInfo[self]
                    info[FLD_PROP_MOD]  = turnonflags(MOD_PROP_REQUIRE, info[FLD_PROP_MOD])
                else
                    error("Usage: property:SetValueRequired([stack]) - the property's definition is finished", parsestack(stack) + 1)
                end
            end;

            --- Mark the property so its value should be kept in a weak table
            -- @static
            -- @method  SetWeak
            -- @owner   property
            -- @format  (target[, stack]])
            -- @param   target                      the target property
            -- @param   stack                       the stack level
            ["SetWeak"]                 = function(self, stack)
                if _PropertyInDefine[self] then
                    local info          = _PropertyInfo[self]
                    info[FLD_PROP_MOD]  = turnonflags(MOD_PROP_SETWEAK, info[FLD_PROP_MOD])
                else
                    error("Usage: property:SetWeak([stack]) - the property's definition is finished", parsestack(stack) + 1)
                end
            end;

            --- Wether the value is a property
            -- @static
            -- @method  Validate
            -- @owner   property
            -- @param   target                      the target property
            -- @param   target                      return the taret is it's a property
            ["Validate"]                = function(self) return _PropertyInfo[self] and self or nil end;
        },
        __call                          = function(self, ...)
            local visitor, env, name, definition, flag, stack = getFeatureParams(property, nil, ...)

            stack                       = stack + 1

            if not name or name == "" then error([[Usage: property "name" { ... } - the name must be a string]], stack) end

            local owner                 = visitor and environment.GetNamespace(visitor)

            if owner and (interface.Validate(owner) or class.Validate(owner)) then
                local prop              = genProperty(owner, name, stack)
                return prop
            else
                error([[Usage: property "name" - the property can't be used here.]], stack)
            end
        end,
    }

    tproperty                           = prototype {
        __tostring                      = function(self)
            local info                  = _PropertyInfo[self]
            return "[property]" .. namespace.GetNamespaceName(info[FLD_PROP_OWNER]) .. "." .. info[FLD_PROP_NAME]
        end;
        __index                         = {
            ["GetOwner"]                = property.GetOwner;
            ["GetName"]                 = property.GetName;
            ["GetAccessor"]             = property.GetAccessor;
            ["GetFeature"]              = property.GetFeature;
            ["GetField"]                = property.GetField;
            ["IsGetClone"]              = property.IsGetClone;
            ["IsGetDeepClone"]          = property.IsGetDeepClone;
            ["IsIndexer"]               = property.IsIndexer;
            ["IsReadable"]              = property.IsReadable;
            ["IsRetainObject"]          = property.IsRetainObject;
            ["IsSetClone"]              = property.IsSetClone;
            ["IsSetDeepClone"]          = property.IsSetDeepClone;
            ["IsShareable"]             = property.IsShareable;
            ["IsStatic"]                = property.IsStatic;
            ["IsValueRequired"]         = property.IsValueRequired;
            ["IsWeak"]                  = property.IsWeak;
            ["IsWritable"]              = property.IsWritable;
            ["GetClone"]                = property.GetClone;
            ["HasDefault"]              = property.HasDefault;
            ["HasDefaultFactory"]       = property.HasDefaultFactory;
            ["GetDefault"]              = property.GetDefault;
            ["GetType"]                 = property.GetType;
            ["SetClone"]                = property.SetClone;
            ["SetIndexer"]              = property.SetIndexer;
            ["SetRetainObject"]         = property.SetRetainObject;
            ["SetStatic"]               = property.SetStatic;
            ["SetValueRequired"]        = property.SetValueRequired;
            ["SetWeak"]                 = property.SetWeak;
        },
        __call                          = function(self, definition, stack)
            stack                       = parsestack(stack) + 1

            if type(definition) ~= "table" then error([[Usage: property "name" { definition } - the definition part must be a table]], stack) end
            if not _PropertyInDefine[self] then error([[Usage: property "name" { definition } - the property's definition is finished]], stack) end

            local info                  = _PropertyInfo[self]
            local owner                 = info[FLD_PROP_OWNER]
            local name                  = info[FLD_PROP_NAME]
            local chkdefunc             = false

            attribute.InitDefinition(self, ATTRTAR_PROPERTY, definition, owner, name, stack)

            -- Parse the definition
            for k, v in pairs, definition do
                if type(k) == "string" then
                    k                   = strlower(k)
                    local tval          = type(v)

                    if k == "auto" then
                        if v then
                            info[FLD_PROP_MOD]          = turnonflags(MOD_PROP_AUTOSCAN, info[FLD_PROP_MOD])
                        end
                    elseif k == "get" then
                        if tval == "function" or tval == "boolean" then
                            info[FLD_PROP_GET]          = v
                        elseif tval == "string" then
                            info[FLD_PROP_GETMETHOD]    = v
                        else
                            error([[Usage: property "name" { get = ... } - the "get" must be function, string or boolean]], stack)
                        end
                    elseif k == "set" then
                        if tval == "function" or tval == "boolean" then
                            info[FLD_PROP_SET]          = v
                        elseif tval == "string" then
                            info[FLD_PROP_SETMETHOD]    = v
                        else
                            error([[Usage: property "name" { set = ... } - the "set" must be function, string or boolean]], stack)
                        end
                    elseif k == "getmethod" then
                        if tval == "string" then
                            info[FLD_PROP_GETMETHOD]    = v
                        else
                            error([[Usage: property "name" { getmethod = ... } - the "get" must be string]], stack)
                        end
                    elseif k == "setmethod" then
                        if tval == "string" then
                            info[FLD_PROP_SETMETHOD]    = v
                        else
                            error([[Usage: property "name" { setmethod = ... } - the "get" must be string]], stack)
                        end
                    elseif k == "field" then
                        if v ~= name then
                            info[FLD_PROP_FIELD]        = v ~= name and v or nil
                        else
                            error([[Usage: property "name" { field = ... } - the field can't be the same with the property name]], stack)
                        end
                    elseif k == "type" then
                        local tpValid                   = getprototypemethod(v, "ValidateValue")
                        if tpValid then
                            info[FLD_PROP_TYPE]         = v
                            info[FLD_PROP_VALID]        = tpValid
                        else
                            error([[Usage: property "name" { type = ... } - the type is not valid]], stack)
                        end
                    elseif k == "default" then
                        if type(v) == "function" then
                            info[FLD_PROP_DEFAULTFUNC]  = v
                            chkdefunc                   = true
                        else
                            info[FLD_PROP_DEFAULT]      = v
                        end
                    elseif k == "factory" then
                        if type(v) == "function" then
                            info[FLD_PROP_DEFAULTFUNC] = v
                        end
                    elseif k == "event" then
                        if tval == "string" or event.Validate(v) then
                            info[FLD_PROP_EVENT]        = v
                        else
                            error([[Usage: property "name" { event = ... } - the event is not valid]], stack)
                        end
                    elseif k == "handler" then
                        if tval == "string" or tval == "function" then
                            info[FLD_PROP_HANDLER]      = v
                        else
                            error([[Usage: property "name" { handler = ... } - the handler must be function or string]], stack)
                        end
                    elseif k == "isstatic" or k == "static" then
                        if v then
                            info[FLD_PROP_MOD]          = turnonflags(MOD_PROP_STATIC, info[FLD_PROP_MOD])
                        end
                    elseif k == "indexer" then
                        if v then
                            info[FLD_PROP_MOD]          = turnonflags(MOD_PROP_INDEXER, info[FLD_PROP_MOD])
                        end
                    elseif k == "throwable" then
                        if v then
                            info[FLD_PROP_MOD]          = turnonflags(MOD_PROP_THROWABLE, info[FLD_PROP_MOD])
                        end
                    elseif k == "require" then
                        if v then
                            info[FLD_PROP_MOD]          = turnonflags(MOD_PROP_REQUIRE, info[FLD_PROP_MOD])
                        end
                    end
                end
            end

            -- Check Default
            if info[FLD_PROP_TYPE] then
                if chkdefunc then
                    local ret, msg                      = info[FLD_PROP_VALID](info[FLD_PROP_TYPE], info[FLD_PROP_DEFAULTFUNC])
                    if not msg then
                        info[FLD_PROP_DEFAULT]          = info[FLD_PROP_DEFAULTFUNC]
                        info[FLD_PROP_DEFAULTFUNC]      = nil
                    end
                end

                if info[FLD_PROP_DEFAULT] ~= nil then
                    local ret, msg  = info[FLD_PROP_VALID](info[FLD_PROP_TYPE], info[FLD_PROP_DEFAULT])
                    if not msg then
                        info[FLD_PROP_DEFAULT]          = ret
                    else
                        error([[Usage: property "name" { type = ...,  default = ... } - the default don't match the type setting]], stack)
                    end
                elseif info[FLD_PROP_DEFAULT] == nil then
                    info[FLD_PROP_DEFAULT]              = getobjectvalue(info[FLD_PROP_TYPE], "GetDefault")
                end
            end

            -- Clear conflict settings
            if info[FLD_PROP_GET] then info[FLD_PROP_GETMETHOD] = nil end
            if info[FLD_PROP_SET] then info[FLD_PROP_SETMETHOD] = nil end

            attribute.ApplyAttributes(self, ATTRTAR_PROPERTY, nil, owner, name, stack)

            _PropertyInDefine                           = savestorage(_PropertyInDefine, self, nil)

            attribute.AttachAttributes(self, ATTRTAR_PROPERTY, owner, name, stack)

            -- Check indexer
            if validateflags(MOD_PROP_INDEXER, info[FLD_PROP_MOD]) then
                if not (info[FLD_PROP_GET] or info[FLD_PROP_GETMETHOD] or info[FLD_PROP_SET] or info[FLD_PROP_SETMETHOD]) then
                    error([[Usage: property "name" { get = ..., set = ...} - the indexer property must have get or set method]], stack)
                end

                if PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD then
                    info[FLD_PROP_INDEXERFLD]           = "_" .. namespace.GetNamespaceName(owner, true) .. "_" .. name .. "_Indexer"

                    -- Other type object may only be used in one thread, but environment is special
                    if interface.IsSubType(owner, IEnvironment) then
                        interface.AddFields(owner, { [info[FLD_PROP_INDEXERFLD]] = false }, stack)
                    end
                end

                info[FLD_PROP_FIELD]                    = nil
                info[FLD_PROP_EVENT]                    = nil
                info[FLD_PROP_HANDLER]                  = nil
                info[FLD_PROP_DEFAULT]                  = nil
                info[FLD_PROP_DEFAULTFUNC]              = nil
            end

            -- Check the event
            if type(info[FLD_PROP_EVENT]) == "string" then
                local ename                             = info[FLD_PROP_EVENT]
                local evt                               = interface.GetFeature(owner, ename)

                if event.Validate(evt) then
                    if evt:IsStatic() == self:IsStatic() then
                        info[FLD_PROP_EVENT]            = evt
                    elseif evt:IsStatic() then
                        error([[Usage: property "name" { event = ... } - the event is static]], stack)
                    else
                        error([[Usage: property "name" { event = ... } - the event is not static]], stack)
                    end
                elseif evt == nil then
                    -- Auto create the event
                    event.Parse(owner, ename, self:IsStatic() or false, stack)
                    info[FLD_PROP_EVENT]                = interface.GetFeature(owner, ename)
                else
                    error([[Usage: property "name" { event = ... } - the event is not valid]], stack)
                end
            end

            interface.AddFeature(owner, name, self, stack)
        end,
        __newindex                      = readonly,
        __metatable                     = property,
    }

    tindexer                            = PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD and prototype {
        __index                         = function(self, idxname)
            local val                   = self[FLD_INDEXER_GET](self[FLD_INDEXER_OBJECT], idxname)
            return val
        end,
        __newindex                      = function(self, idxname, value) self[FLD_INDEXER_SET](self[FLD_INDEXER_OBJECT], idxname, value) end,
    } or nil

    -----------------------------------------------------------------------
    --                            registration                           --
    -----------------------------------------------------------------------
    interface.RegisterParser(property)
end

-------------------------------------------------------------------------------
-- The exception system are used to throw the error with debug datas on will.
--
-- The functions contains the throw-exception action must be called within the
-- *pcall* function, Lua don't allow using table as error message for directly
-- call. A normal scenario is use the throw-exception style in the constructor
-- of the classes.
--
--              class "A" (function(_ENV)
--                  function A(self)
--                      throw("The error will be thrown to where A() is called")
--                  end
--              end)
--
--              A()     -- Error: The error will be thrown to where A() is called
--
-- Now we can diff the calling errors(by throw) and code errors(like `1 = v`)
--
-- @keyword     throw
-------------------------------------------------------------------------------
do
    throw                               = function (exception)
        if type(exception) == "string" or not class.IsSubType(getmetatable(exception), Exception) then
            exception                   = Exception(tostring(exception))
        end

        if exception.StackDataSaved then error(exception) end

        exception.StackDataSaved        = true

        local stack                     = exception.StackLevel + 1

        if traceback then
            exception.StackTrace        = traceback(exception.Message, stack)
        end

        local func

        if debuginfo then
            local info                  = debuginfo(stack, "lSfn")
            if info then
                exception.Source        = (info.short_src or "unknown") .. ":" .. (info.currentline or "?")
                func                    = info.func
                exception.TargetSite    = info.name
            end
        end

        if exception.SaveVariables then
            if getlocal then
                local index             = 1
                local k, v              = getlocal(stack, index)
                if k then
                    local vars          = {}
                    while k do
                        vars[k]         = v

                        index           = index + 1
                        k, v            = getlocal(stack, index)
                    end
                    exception.LocalVariables = vars
                end
            end

            if getupvalue and func then
                local index             = 1
                local k, v              = getupvalue(func, index)
                if k then
                    local vars          = {}
                    while k do
                        vars[k]         = v

                        index           = index + 1
                        k, v            = getupvalue(func, index)
                    end
                    exception.Upvalues  = vars
                end
            end
        end

        error(exception, stack)
    end
end

-------------------------------------------------------------------------------
-- Since the Lua provide the xpcall instead of the try, the system only provide
-- a with keyword for object of System.IAutoClose :
--
--              local ctx = DBContext()
--              local input = FileReader("xxxx")
--
--              with(ctx, input) (function()
--                  -- the operations
--              end, function(err)
--                  -- the exception handler, if ignored then
--                  -- the "error" api would be used
--              end)
--
-- The Open and Close method will be automatically used by the with keyword, so
-- we don't need to worry about those operations.
--
-- @keyword     with
-------------------------------------------------------------------------------
do
    local closeObjectAndRet             = function(object, errhandler, ok, msg, ...)
        pcall(object.Close, object, not ok and msg or nil)

        if not ok then
            if errhandler then
                return errhandler(msg, object)
            else
                error(msg, 0)
            end
            return
        end

        return msg, ...
    end

    local closeObjectsAndRet            = function(objects, errhandler, ok, msg, ...)
        for _, object in ipairs, objects, 0 do
            pcall(object.Close, object, not ok and msg or nil)
        end

        if not ok then
            if errhandler then
                return errhandler(msg, unpack(objects))
            else
                error(msg, 0)
            end
            return
        end

        return msg, ...
    end

    with                                = function(...)
        local n                         = select("#", ...)

        if n == 0 then error("Usage: with(object[, ...]) (operation[, errorhandler]) - the object must existed", 2) end
        for i = 1, n do
            if not class.IsObjectType(select(i, ...), IAutoClose) then
                error("Usage: with(object[, ...]) (operation[, errorhandler]) - the object must be generated from System.IAutoClose", 2)
            end
        end

        if n == 1 then
            local object                = ...
            return function (operation, errhandler)
                if type(operation) ~= "function" then
                    error("Usage: with(object[, ...]) (operation[, errorhandler]) - the operation must be function", 2)
                end
                if errhandler ~= nil and type(errhandler) ~= "function" then
                    error("Usage: with(object[, ...]) (operation[, errorhandler]) - the errhandler need be function", 2)
                end

                local ok, msg           = pcall(object.Open, object)
                if not ok then
                    if errhandler then
                        return errhandler(msg, object)
                    else
                        error(msg, 0)
                    end
                end

                return closeObjectAndRet(object, errhandler, pcall(operation, object))
            end
        else
            local objects               = { ... }
            return function (operation, errhandler)
                if type(operation) ~= "function" then
                    error("Usage: with(object[, ...]) (operation[, errorhandler]) - the operation must be function", 2)
                end
                if errhandler ~= nil and type(errhandler) ~= "function" then
                    error("Usage: with(object[, ...]) (operation[, errorhandler]) - the errhandler need be function", 2)
                end

                local ok, msg

                for i, object in ipairs, objects, 0 do
                    ok, msg             = pcall(object.Open, object)
                    if not ok then
                        for j = i - 1, 1, -1 do
                            pcall(objects[j].Close, objects[j], msg)
                        end
                        if errhandler then
                            return errhandler(msg, object)
                        else
                            error(msg, 0)
                        end
                    end
                end

                return closeObjectsAndRet(objects, errhandler, pcall(operation, unpack(objects)))
            end
        end
    end
end

-------------------------------------------------------------------------------
--                           keyword installation                            --
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                          global keyword                           --
    -----------------------------------------------------------------------
    environment.RegisterGlobalKeyword {
        prototype                       = prototype,
        namespace                       = namespace,
        import                          = import,
        export                          = export,
        enum                            = enum,
        struct                          = struct,
        class                           = class,
        interface                       = interface,
    }

    -----------------------------------------------------------------------
    --                         runtime keyword                           --
    -----------------------------------------------------------------------
    environment.RegisterRuntimeKeyword {
        throw                           = throw,
        with                            = with,
    }

    -----------------------------------------------------------------------
    --                          struct keyword                           --
    -----------------------------------------------------------------------
    environment.RegisterContextKeyword(struct.GetDefinitionContext(), {
        member                          = member,
        array                           = array,
        endstruct                       = rawget(_PLoopEnv, "endstruct"),
    })

    -----------------------------------------------------------------------
    --                         interface keyword                         --
    -----------------------------------------------------------------------
    environment.RegisterContextKeyword(interface.GetDefinitionContext(), {
        require                         = require,
        extend                          = extend,
        field                           = field,
        event                           = event,
        property                        = property,
        endinterface                    = rawget(_PLoopEnv, "endinterface"),
    })

    -----------------------------------------------------------------------
    --                           class keyword                           --
    -----------------------------------------------------------------------
    environment.RegisterContextKeyword(class.GetDefinitionContext(), {
        inherit                         = inherit,
        extend                          = extend,
        field                           = field,
        event                           = event,
        property                        = property,
        endclass                        = rawget(_PLoopEnv, "endclass"),
    })
end

-------------------------------------------------------------------------------
-- The **System** namespace contains fundamental prototypes, attributes, enums,
-- structs, interfaces and classes
--
-- @namespace   System
-------------------------------------------------------------------------------
do
    -----------------------------------------------------------------------
    --                          private storage                          --
    -----------------------------------------------------------------------
    local _LambdaCache                  = newstorage(WEAK_VALUE)

    -----------------------------------------------------------------------
    --                          private helpers                          --
    -----------------------------------------------------------------------
    local getClassMeta                  = class.GetMetaMethod

    local genBasicValidator             = function(tname)
        local msg                       = "the %s must be " .. tname .. ", got "
        local type                      = type
        return function(val, onlyvalid) local tval = type(val) return tval ~= tname and (onlyvalid or msg .. tval) or nil end
    end

    local genTypeValidator              = function(ptype)
        local pname                     = tostring(ptype)
        local msg                       = "the %s must be a" .. (pname:match("^[aeiou]") and "n" or "") .. " " .. pname
        local valid                     = ptype.Validate
        return function(val, onlyvalid) return not valid(val) and (onlyvalid or msg) or nil end
    end

    local getAttributeName              = function(self) return namespace.GetNamespaceName(namespace.Validate(self) and self or getmetatable(self)) end
    local regValue                      = function(self, ...) attribute.Register(prototype.NewObject(self, { ... })) end
    local regSelfOrObject               = function(self, tbl) attribute.Register(type(tbl) == "table" and getmetatable(tbl) == nil and prototype.NewObject(self, tbl) or self) end
    local regSelfOrValue                = function(self, tbl) attribute.Register(type(tbl) == "table" and getmetatable(tbl) == nil and prototype.NewObject(self, tbl) or tbl ~= nil and prototype.NewObject(self, { tbl }) or self) end

    local parseLambda                   = function(value, onlyvalid)
        if _LambdaCache[value] then return end
        if not (type(value) == "string" and strfind(value, "=>")) then return onlyvalid or "the %s must be a string like 'x,y=>x+y'" end

        local param, body               = strmatch(value, "^(.-)=>(.+)$")
        body                            = body and strfind(body, "return") and body or ("return " .. (body or ""))

        local func                      = loadsnippet(strformat("return function(%s) %s end", param, body), value, _G)
        if not func then return onlyvalid or "the %s must be a string like 'x,y => x+y'" end
        func                            = func()

        _LambdaCache                    = savestorage(_LambdaCache, value, func)
    end

    local parseCallable                 = function(value, onlyvalid)
        local stype                     = type(value)
        if stype == "function" then return end
        if stype == "string" then
            return parseLambda(value, true) and (onlyvalid or "the %s isn't callable") or nil
        end
        local meta                      = getmetatable(value)
        if not (meta and getClassMeta(meta, "__call")) then
            return onlyvalid or "the %s isn't callable"
        end
    end

    local serializeData                 = function(data)
        local dtype                     = type(data)

        if dtype == "string" then
            return strformat("%q", data)
        elseif dtype == "number" or dtype == "boolean" then
            return tostring(data)
        else
            return "(inner)"
        end
    end

    serialize                           = function(data, ns)
        if ns then
            if enum.Validate(ns) then
                if enum.IsFlagsEnum(ns) then
                    local cache         = {}
                    for name in ns(data) do
                        tinsert(cache, name)
                    end
                    return tblconcat(cache, " + ")
                else
                    return enum.Parse(ns, data)
                end
            elseif struct.Validate(ns) then
                if struct.GetStructCategory(ns) == StructCategory.CUSTOM then
                    return serializeData(data)
                else
                    return "(inner)"
                end
            else
                return "(inner)"
            end
        end
        return serializeData(data)
    end

    combineToken                        = function(tokens, sep)
        local temp                      = _Cache()
        for i, v in ipairs, tokens, 0 do
            temp[i]                     = strformat("%x", v)
        end
        local ret                       = tblconcat(temp, sep)
        _Cache(temp)
        return ret
    end

    replaceIndex                        = function (code, i) return (code:gsub("_(%a?)i_", function(sp) if sp == "p" then return parseindex(i) end return (sp or "") .. i end)) end

    -----------------------------------------------------------------------
    --                             prototype                             --
    -----------------------------------------------------------------------
    namespace.SaveNamespace("System.Prototype",   prototype (prototype,   { __tostring = namespace.GetNamespaceName }))
    namespace.SaveNamespace("System.Attribute",   prototype (attribute,   { __tostring = namespace.GetNamespaceName }))
    namespace.SaveNamespace("System.Environment", prototype (environment, { __tostring = namespace.GetNamespaceName }))
    namespace.SaveNamespace("System.Namespace",   prototype (namespace,   { __tostring = namespace.GetNamespaceName }))
    namespace.SaveNamespace("System.ValidateType", validatetype)
    namespace.SaveNamespace("System.Struct",      prototype (struct,      { __tostring = namespace.GetNamespaceName }))
    namespace.SaveNamespace("System.Enum",        prototype (enum,        { __tostring = namespace.GetNamespaceName }))
    namespace.SaveNamespace("System.Member",      prototype (member,      { __tostring = namespace.GetNamespaceName }))
    namespace.SaveNamespace("System.Interface",   prototype (interface,   { __tostring = namespace.GetNamespaceName }))
    namespace.SaveNamespace("System.Class",       prototype (class,       { __tostring = namespace.GetNamespaceName }))
    namespace.SaveNamespace("System.Event",       prototype (event,       { __tostring = namespace.GetNamespaceName }))
    namespace.SaveNamespace("System.Property",    prototype (property,    { __tostring = namespace.GetNamespaceName }))
    namespace.SaveNamespace("System.Platform",    prototype { __index = PLOOP_PLATFORM_SETTINGS, __tostring = namespace.GetNamespaceName })

    -----------------------------------------------------------------------
    --                             attribute                             --
    -----------------------------------------------------------------------
    -----------------------------------------------------------------------
    -- Mark a class as abstract, so it can't be used to generate objects,
    -- or mark the object methods, object features(like event, property) as
    -- abstract, so they need(not must) be implemented by child interfaces
    -- or classes
    --
    -- @attribute   System.__Abstract__
    -----------------------------------------------------------------------
    namespace.SaveNamespace("System.__Abstract__",
        prototype {
            __index                     = {
                ["ApplyAttribute"]      = function(self, target, targettype, manager, owner, name, stack)
                    if targettype == ATTRTAR_CLASS then
                        getmetatable(target).SetAbstract(target, parsestack(stack) + 1)
                    elseif class.Validate(owner) or interface.Validate(owner) then
                        getmetatable(owner).SetAbstract(owner, name, parsestack(stack) + 1)
                    end
                end,
                ["AttributeTarget"]     = ATTRTAR_CLASS + ATTRTAR_METHOD + ATTRTAR_EVENT + ATTRTAR_PROPERTY,
            },
            __call                      = regSelfOrObject,
            __newindex                  = readonly,
            __tostring                  = getAttributeName
        }
    )

    -----------------------------------------------------------------------
    -- Mark an interface so it'll auto create an anonymous class that extend
    -- the interface. So the interface can be used like a class to generate
    -- objects. Since the anonymous class don't have any constructor, no
    -- arguments can be accepted by the interface, but you still can pass
    -- a table as the init-table(like the class without constructor).
    --
    -- If the interface has only one abstract object method(include extend),
    -- it also can receive a function as argument to generate an object, the
    -- accepted function will override the abstract method :
    --
    --          import "System"
    --
    --          __AnonymousClass__()
    --          interface "ITask" (function(_ENV)
    --              __Abstract__()
    --              function DoTask(self)
    --              end
    --
    --              function Process(self)
    --                  self:DoTask()
    --              end
    --          end)
    --
    --          o = ITask(function() print("Hello") end)
    --
    --          o:Process()     -- Hello
    --
    -- @attribute   System.__AnonymousClass__
    -----------------------------------------------------------------------
    namespace.SaveNamespace("System.__AnonymousClass__",
        prototype {
            __index                     = {
                ["ApplyAttribute"]      = function(self, target, targettype, manager, owner, name, stack)
                    interface.SetAnonymousClass(target, parsestack(stack) + 1)
                end,
                ["AttributeTarget"]     = ATTRTAR_INTERFACE,
            },
            __call                      = regSelfOrObject,
            __newindex                  = readonly,
            __tostring                  = getAttributeName
        }
    )

    -----------------------------------------------------------------------
    -- Whether the class's objects will auto cache its object method
    --
    -- It also can be used on the method or function so for the same arguments
    -- the same value will be returned(the target function won't be called twice)
    --
    -- @attribute   System.__AutoCache__
    -----------------------------------------------------------------------
    namespace.SaveNamespace("System.__AutoCache__",
        prototype {
            __index                     = {
                ["ApplyAttribute"]      = function(self, target, targettype, manager, owner, name, stack)
                    if targettype == ATTRTAR_CLASS then
                        class.SetMethodAutoCache(target, parsestack(stack) + 1)
                    end
                end,
                ["InitDefinition"]      = not PLOOP_PLATFORM_SETTINGS.MULTI_OS_THREAD and
                    function(self, target, targettype, definition, owner, name, stack)
                        if targettype == ATTRTAR_FUNCTION or targettype == ATTRTAR_METHOD then
                            local root = setmetatable({}, WEAK_KEY)

                            return function(...)
                                local map       = root

                                for i = 1, select("#", ...) do
                                    local v     = select(i, ...)
                                    if v == nil then v = regValue end -- as a token

                                    local n     = map[v]
                                    if not n then
                                        n       = setmetatable({}, WEAK_KEY)
                                        map[v]  = n
                                    end

                                    map         = n
                                end

                                if map[fakefunc] then
                                    return unpack(map[fakefunc])
                                end

                                map[fakefunc]   = { target(...) }

                                return unpack(map[fakefunc])
                            end
                        end
                    end or PLOOP_PLATFORM_SETTINGS.ENABLE_CONTEXT_FEATURES and -- Use Context
                    function(self, target, targettype, definition, owner, name, stack)
                        if targettype == ATTRTAR_FUNCTION or targettype == ATTRTAR_METHOD then
                            local root          = setmetatable({}, WEAK_KEY)

                            return function(...)
                                local ctx       = Context.GetCurrentContext()
                                if not ctx then return target(...) end

                                local map       = ctx[__AutoCache__]
                                if not map then
                                    map         = setmetatable({}, WEAK_KEY)
                                    ctx[__AutoCache__] = map
                                end

                                for i = 1, select("#", ...) do
                                    local v     = select(i, ...)
                                    if v == nil then v = regValue end -- as a token

                                    local n     = map[v]
                                    if not n then
                                        n       = setmetatable({}, WEAK_KEY)
                                        map[v]  = n
                                    end

                                    map         = n
                                end

                                if map[fakefunc] then
                                    return unpack(map[fakefunc])
                                end

                                map[fakefunc]   = { target(...) }

                                return unpack(map[fakefunc])
                            end
                        end
                    end or fakefunc,
                ["AttributeTarget"]     = ATTRTAR_CLASS + ATTRTAR_INTERFACE + ATTRTAR_METHOD + ATTRTAR_FUNCTION,
                ["Priority"]            = -1,  -- Magic but the AttributePriority is defined later
            },
            __call                      = regSelfOrObject,
            __newindex                  = readonly,
            __tostring                  = getAttributeName
        }
    )

    -----------------------------------------------------------------------
    -- Create an index auto-increased enumeration
    --
    -- @attribute   System.__AutoIndex__
    -- @usage       __AutoIndex__ { A = 0, C = 10 }
    --              enum "Test" { "A", "B", "C", "D" }
    --              print(Test.A, Test.B, Test.C, Test.D) -- 0, 1, 10, 11
    -----------------------------------------------------------------------
    namespace.SaveNamespace("System.__AutoIndex__",
        prototype {
            __index                     = {
                ["InitDefinition"]      = function(self, target, targettype, definition, owner, name, stack)
                    local value         = self[1]
                    stack               = parsestack(stack) + 1

                    local newdef        = {}
                    local idx           = 0

                    if value and type(value) ~= "table" then value = nil end

                    for _, name in ipairs, definition, 0 do
                        idx             = value and value[name] or (idx + 1)
                        newdef[name]    = idx
                    end

                    return newdef
                end,
                ["AttributeTarget"]     = ATTRTAR_ENUM,
            },
            __call                      = regValue,
            __newindex                  = readonly,
            __tostring                  = getAttributeName
        }
    )

    -----------------------------------------------------------------------
    -- Create a enum on a based value like 1100, so the list only allow
    -- the enum value between 1 and 99, and the base value will be added to them.
    --
    -- @attribute   System.__BaseIndex__
    -- @usage       __BaseIndex__(1100)
    --              enum "Test" { A = 1, C = 2 } -- The value must in (0, 100)
    --              print(Test.A, Test.C) -- 1101, 1102
    -----------------------------------------------------------------------
    namespace.SaveNamespace("System.__BaseIndex__",
        prototype {
            __index                     = {
                ["InitDefinition"]      = function(self, target, targettype, definition, owner, name, stack)
                    local base          = self[1]
                    base                = base and tonumber(base)
                    base                = base and floor(base)
                    if not base or base < 10 then error("The __BaseIndex__ only won't accept the base value less than 10", stack + 1) end

                    local newdef        = {}
                    local max           = tostring(base):match("0+$")
                    max                 = max and tonumber((max:gsub("0", "9"))) or 0

                    for name, value in pairs, definition do
                        if value < 1 or value > max then
                            error("The " .. name .. " 's value must in [1-" .. max .. "]", stack + 1)
                        end
                        newdef[name]    = base + value
                    end

                    return newdef
                end,
                ["AttributeTarget"]     = ATTRTAR_ENUM,
            },
            __call                      = regValue,
            __newindex                  = readonly,
            __tostring                  = getAttributeName
        }
    )

    -----------------------------------------------------------------------
    -- Set the target struct's base struct, works like
    --
    --          struct "Number" { function (val) return type(val) ~= "number" and "the %s must be number" end }
    --
    --          __Base__(Number)
    --          struct "Integer" { function(val) return math.floor(val) ~= val and "the %s must be integer" end}
    --
    --          print(Integer(true))    -- Error: the value must be number
    --          print(Integer(1.3))     -- Error: the value must be integer
    --
    -- @attribute   System.__Base__
    -----------------------------------------------------------------------
    namespace.SaveNamespace("System.__Base__",
        prototype {
            __index                     = {
                ["ApplyAttribute"]      = function(self, target, targettype, manager, owner, name, stack)
                    struct.SetBaseStruct(target, self[1], parsestack(stack) + 1)
                end,
                ["AttributeTarget"]     = ATTRTAR_STRUCT,
            },
            __call                      = regValue,
            __newindex                  = readonly,
            __tostring                  = getAttributeName
        }
    )

    -----------------------------------------------------------------------
    -- Set a default value to the enum or custom struct
    --
    -- @attribute   System.__Default__
    -----------------------------------------------------------------------
    namespace.SaveNamespace("System.__Default__",
        prototype {
            __index                     = {
                ["InitDefinition"]      = function(self, target, targettype, definition, owner, name, stack)
                    local value         = self[1]
                    if value       ~= nil and targettype == ATTRTAR_MEMBER then
                        definition.default = value
                    end
                end,
                ["ApplyAttribute"]      = function(self, target, targettype, manager, owner, name, stack)
                    local value         = self[1]
                    if value ~= nil then
                        stack           = parsestack(stack) + 1

                        if targettype  == ATTRTAR_ENUM then
                            enum.SetDefault(target, value, stack)
                        elseif targettype == ATTRTAR_STRUCT then
                            struct.SetDefault(target, value, stack)
                        end
                    end
                end,
                ["AttributeTarget"]     = ATTRTAR_ENUM + ATTRTAR_STRUCT + ATTRTAR_MEMBER,
            },
            __call                      = regValue,
            __newindex                  = readonly,
            __tostring                  = getAttributeName
        }
    )

    -----------------------------------------------------------------------
    -- Set a event change handler to the event
    --
    -- @attribute   System.__EventChangeHandler__
    -----------------------------------------------------------------------
    namespace.SaveNamespace("System.__EventChangeHandler__",
        prototype {
            __index                     = {
                ["ApplyAttribute"]      = function(self, target, targettype, manager, owner, name, stack)
                    local value         = self[1]
                    if type(value) == "function" then
                        event.SetEventChangeHandler(target, value, parsestack(stack) + 1)
                    end
                end,
                ["AttributeTarget"]     = ATTRTAR_EVENT,
            },
            __call                      = regValue,
            __newindex                  = readonly,
            __tostring                  = getAttributeName
        }
    )

    -----------------------------------------------------------------------
    -- Mark a class or interface as final, so they can't be inherited or
    -- extended, or mark the object methods, object features as final, so
    -- they have the highest priority to be inherited
    --
    -- @attribute   System.__Final__
    -----------------------------------------------------------------------
    namespace.SaveNamespace("System.__Final__",
        prototype {
            __index                     = {
                ["ApplyAttribute"]      = function(self, target, targettype, manager, owner, name, stack)
                    if targettype  == ATTRTAR_INTERFACE or targettype == ATTRTAR_CLASS then
                        getmetatable(target).SetFinal(target, parsestack(stack) + 1)
                    elseif class.Validate(owner) or interface.Validate(owner) then
                        getmetatable(owner).SetFinal(owner, name, parsestack(stack) + 1)
                    end
                end,
                ["AttributeTarget"]     = ATTRTAR_INTERFACE + ATTRTAR_CLASS + ATTRTAR_METHOD + ATTRTAR_EVENT + ATTRTAR_PROPERTY,
            },
            __call                      = attribute.Register,
            __newindex                  = readonly,
            __tostring                  = namespace.GetNamespaceName
        }
    )

    -----------------------------------------------------------------------
    -- Set the enum as flags enumeration
    --
    -- @attribute   System.__Flags__
    -----------------------------------------------------------------------
    namespace.SaveNamespace("System.__Flags__",
        prototype {
            __index                     = {
                ["InitDefinition"]      = function(self, target, targettype, definition, owner, name, stack)
                    local cache         = _Cache()
                    local valkey        = nil
                    local count         = 0
                    local max           = -1

                    stack               = parsestack(stack) + 1

                    if type(definition) ~= "table" then error("the enum's definition must be a table", stack) end

                    if enum.IsSealed(target) then
                        for name, val in enum.GetEnumValues(target) do
                            cache[val]  = name
                            if type(val) == "number" and val > 0 then
                                local n = mlog(val) / mlog(2)
                                if floor(n) == n then
                                    count   = count + 1
                                    max     = n > max and n or max
                                end
                            end
                        end
                    end

                    -- Scan
                    for k, val in ipairs, definition, 0 do
                        if type(val) == "string" then
                            valkey      = valkey or _Cache()
                            tinsert(valkey, val)
                            count       = count + 1
                        end
                        definition[k]   = nil
                    end

                    for k, val in pairs, definition do
                        if type(k) == "string" then
                            local v     = tonumber(val)

                            if v then
                                v       = floor(v)
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
                                        if cache[v] then
                                            error(strformat("The %s and %s can't be the same value", k, cache[v]), stack)
                                        else
                                            cache[v]    = k
                                            max         = n > max and n or max
                                        end
                                    else
                                        error(strformat("The %s's value is not a valid flags value(2^n)", k), stack)
                                    end
                                else
                                    error(strformat("The %s's value is not a valid flags value(2^n)", k), stack)
                                end
                                definition[k] = v
                            else
                                count   = count + 1
                                definition[k]= -1
                            end
                        else
                            definition[k] = nil
                        end
                    end

                    -- So the definition would be more precisely
                    if max >= count then error("The flags enumeration's value can't be greater than 2^(count - 1)", stack) end

                    -- Auto-gen values
                    local n             = 1
                    if valkey then
                        for _, k in ipairs, valkey, 0 do
                            while cache[n] do n = 2 * n end
                            cache[n]        = k
                            definition[k]   = n
                        end
                        _Cache(valkey)
                    end

                    for k, v in pairs, definition do
                        if v == -1 then
                            while cache[n] do n = 2 * n end
                            cache[n]        = k
                            definition[k]   = n
                        end
                    end

                    _Cache(cache)
                end,
                ["ApplyAttribute"]      = function(self, target, targettype, manager, owner, name, stack)
                    enum.SetFlagsEnum(target, parsestack(stack) + 1)
                end,
                ["AttributeTarget"]     = ATTRTAR_ENUM,
            },
            __call                      = attribute.Register,
            __newindex                  = readonly,
            __tostring                  = namespace.GetNamespaceName
        }
    )

    -----------------------------------------------------------------------
    -- Set the enum as value shareable
    --
    -- @attribute   System.__Shareable__
    -----------------------------------------------------------------------
    namespace.SaveNamespace("System.__Shareable__",
        prototype {
            __index                     = {
                ["InitDefinition"]      = function(self, target, targettype, definition, owner, name, stack)
                    enum.SetValueShareable(target, parsestack(stack) + 1)
                end,
                ["AttributeTarget"]     = ATTRTAR_ENUM,
            },
            __call                      = attribute.Register,
            __newindex                  = readonly,
            __tostring                  = namespace.GetNamespaceName
        }
    )

    -----------------------------------------------------------------------
    -- Modify the property's get process
    --
    -- @attribute   System.__Get__
    -----------------------------------------------------------------------
    namespace.SaveNamespace("System.__Get__",
        prototype {
            __index                     = {
                ["ApplyAttribute"]      = function(self, target, targettype, manager, owner, name, stack)
                    local value         = self[1]
                    if type(value) == "number" then
                        stack           = parsestack(stack) + 1

                        if enum.ValidateFlags(PropertyGet.Clone, value) or enum.ValidateFlags(PropertyGet.DeepClone, value) then
                            property.GetClone(target, enum.ValidateFlags(PropertyGet.DeepClone, value), stack)
                        end
                    end
                end,
                ["AttributeTarget"]     = ATTRTAR_PROPERTY,
            },
            __call                      = regSelfOrValue,
            __newindex                  = readonly,
            __tostring                  = getAttributeName
        }
    )

    -----------------------------------------------------------------------
    -- Set a property as indexer property
    --
    -- @attribute   System.__Indexer__
    -----------------------------------------------------------------------
    namespace.SaveNamespace("System.__Indexer__",
        prototype {
            __index                     = {
                ["ApplyAttribute"]      = function(self, target, targettype, manager, owner, name, stack)
                    property.SetIndexer(target, self[1], parsestack(stack) + 1)
                end,
                ["AttributeTarget"]     = ATTRTAR_PROPERTY,
            },
            __call                      = regSelfOrValue,
            __newindex                  = readonly,
            __tostring                  = getAttributeName
        }
    )

    -----------------------------------------------------------------------
    -- Set the namespace for next generated type
    --
    -- @attribute   System.__Namespace__
    -----------------------------------------------------------------------
    namespace.SaveNamespace("System.__Namespace__",
        prototype {
            __call                      = function(self, value) namespace.SetNamespaceForNext(value) end,
            __index                     = writeonly,
            __newindex                  = readonly,
            __tostring                  = namespace.GetNamespaceName
        }
    )

    -----------------------------------------------------------------------
    -- Make the target struct allow objects to pass its validation
    -----------------------------------------------------------------------
    namespace.SaveNamespace("System.__ObjectAllowed__",
        prototype {
            __index                     = {
                ["ApplyAttribute"]      = function(self, target, targettype, manager, owner, name, stack)
                    struct.SetObjectAllowed(target, parsestack(stack) + 1)
                end,
                ["AttributeTarget"]     = ATTRTAR_STRUCT,
            },
            __call                      = regSelfOrObject,
            __newindex                  = readonly,
            __tostring                  = getAttributeName
        }
    )

    -----------------------------------------------------------------------
    -- Set the class so the attributes can be applied on its objects
    --
    -- @attribute   System.__ObjectAttr__
    -----------------------------------------------------------------------
    namespace.SaveNamespace("System.__ObjectAttr__",
        prototype {
            __index                     = {
                ["ApplyAttribute"]      = function(self, target, targettype, manager, owner, name, stack)
                    if targettype == ATTRTAR_CLASS then
                        class.SetObjectAttributeEnabled(target, parsestack(stack) + 1)
                    end
                end,
                ["AttributeTarget"]     = ATTRTAR_CLASS + ATTRTAR_INTERFACE,
            },
            __call                      = regSelfOrObject,
            __newindex                  = readonly,
            __tostring                  = getAttributeName
        }
    )

    -----------------------------------------------------------------------
    -- Set the class's objects so functions that be assigned on them will
    -- be modified by the attribute system
    --
    -- @attribute   System.__ObjFuncAttr__
    -----------------------------------------------------------------------
    namespace.SaveNamespace("System.__ObjFuncAttr__",
        prototype {
            __index                     = {
                ["ApplyAttribute"]      = function(self, target, targettype, manager, owner, name, stack)
                    if targettype == ATTRTAR_CLASS then
                        class.SetObjectFunctionAttributeEnabled(target, parsestack(stack) + 1)
                    end
                end,
                ["AttributeTarget"]     = ATTRTAR_CLASS + ATTRTAR_INTERFACE,
            },
            __call                      = regSelfOrObject,
            __newindex                  = readonly,
            __tostring                  = getAttributeName
        }
    )

    -----------------------------------------------------------------------
    -- Set the class's objects to save the source where it's created
    --
    -- @attribute   System.__ObjectSource__
    -----------------------------------------------------------------------
    namespace.SaveNamespace("System.__ObjectSource__",
        prototype {
            __index                     = {
                ["ApplyAttribute"]      = function(self, target, targettype, manager, owner, name, stack)
                    if targettype  == ATTRTAR_CLASS then
                        class.SetObjectSourceDebug(target, parsestack(stack) + 1)
                    end
                end,
                ["AttributeTarget"]     = ATTRTAR_CLASS + ATTRTAR_INTERFACE,
                ["Inheritable"]         = false,
            },
            __call                      = regSelfOrObject,
            __newindex                  = readonly,
            __tostring                  = getAttributeName
        }
    )

    -----------------------------------------------------------------------
    -- Set a require class to the target interface
    --
    -- @attribute   System.__Require__
    -----------------------------------------------------------------------
    namespace.SaveNamespace("System.__Require__",
        prototype {
            __index                     = {
                ["ApplyAttribute"]      = function(self, target, targettype, manager, owner, name, stack)
                    interface.SetRequireClass(target, self[1], parsestack(stack) + 1)
                end,
                ["AttributeTarget"]     = ATTRTAR_INTERFACE,
            },
            __call                      = regValue,
            __newindex                  = readonly,
            __tostring                  = getAttributeName
        }
    )

    -----------------------------------------------------------------------
    -- Seal the enum, struct, interface or class, so they can't be re-defined
    --
    -- @attribute   System.__Sealed__
    -----------------------------------------------------------------------
    namespace.SaveNamespace("System.__Sealed__",
        prototype {
            __index                     = {
                ["ApplyAttribute"]      = function(self, target, targettype, manager, owner, name, stack)
                    getmetatable(target).SetSealed(target, parsestack(stack) + 1)
                end,
                ["AttributeTarget"]     = ATTRTAR_ENUM + ATTRTAR_STRUCT + ATTRTAR_INTERFACE + ATTRTAR_CLASS,
            },
            __call                      = regSelfOrObject,
            __newindex                  = readonly,
            __tostring                  = getAttributeName
        }
    )

    -----------------------------------------------------------------------
    -- Modify the property's assignment, works like :
    --
    -- @attribute   System.__Set__
    -----------------------------------------------------------------------
    namespace.SaveNamespace("System.__Set__",
        prototype {
            __index                     = {
                ["ApplyAttribute"]      = function(self, target, targettype, manager, owner, name, stack)
                    local value         = self[1]
                    if type(value) == "number" then
                        stack           = parsestack(stack) + 1

                        if enum.ValidateFlags(PropertySet.Clone, value) or enum.ValidateFlags(PropertySet.DeepClone, value) then
                            property.SetClone(target, enum.ValidateFlags(PropertySet.DeepClone, value), stack)
                        end

                        if enum.ValidateFlags(PropertySet.Retain, value) then
                            property.SetRetainObject(target, stack)
                        end

                        if enum.ValidateFlags(PropertySet.Weak, value) then
                            property.SetWeak(target, stack)
                        end
                    end
                end,
                ["AttributeTarget"]     = ATTRTAR_PROPERTY,
            },
            __call                      = regSelfOrValue,
            __newindex                  = readonly,
            __tostring                  = getAttributeName
        }
    )

    -----------------------------------------------------------------------
    -- Set the class as a single version class, so all old objects of it
    -- will always use the newest definition
    --
    -- @attribute   System.__SingleVer__
    -----------------------------------------------------------------------
    namespace.SaveNamespace("System.__SingleVer__",
        prototype {
            __index                     = {
                ["ApplyAttribute"]      = function(self, target, targettype, manager, owner, name, stack)
                    if targettype == ATTRTAR_CLASS then
                        class.SetSingleVersion(target, parsestack(stack) + 1)
                    end
                end,
                ["AttributeTarget"]     = ATTRTAR_CLASS + ATTRTAR_INTERFACE,
            },
            __call                      = regSelfOrObject,
            __newindex                  = readonly,
            __tostring                  = getAttributeName
        }
    )

    -----------------------------------------------------------------------
    -- Set the object methods or object features as static, so they can only
    -- be used by the struct, interface or class itself
    --
    -- @attribute   System.__Static__
    -----------------------------------------------------------------------
    namespace.SaveNamespace("System.__Static__",
        prototype {
            __index                     = {
                ["InitDefinition"]      = function(self, target, targettype, definition, owner, name, stack)
                    if targettype  == ATTRTAR_METHOD then
                        getmetatable(owner).SetStaticMethod(owner, name, parsestack(stack) + 1)
                    end
                end,
                ["ApplyAttribute"]      = function(self, target, targettype, manager, owner, name, stack)
                    stack               = parsestack(stack) + 1
                    if targettype  == ATTRTAR_EVENT then
                        event.SetStatic(target, stack)
                    elseif targettype == ATTRTAR_PROPERTY then
                        property.SetStatic(target, stack)
                    end
                end,
                ["AttributeTarget"]     = ATTRTAR_METHOD + ATTRTAR_EVENT + ATTRTAR_PROPERTY,
                ["Priority"]            = 9999,     -- Should be applied at the first for method
            },
            __call                      = attribute.Register,
            __newindex                  = readonly,
            __tostring                  = namespace.GetNamespaceName
        }
    )

    -----------------------------------------------------------------------
    -- Set a super class to the target class
    --
    -- @attribute   System.__Super__
    -----------------------------------------------------------------------
    namespace.SaveNamespace("System.__Super__",
        prototype {
            __index                     = {
                ["ApplyAttribute"]      = function(self, target, targettype, manager, owner, name, stack)
                    class.SetSuperClass(target, self[1], parsestack(stack) + 1)
                end,
                ["AttributeTarget"]     = ATTRTAR_CLASS,
            },
            __call                      = regValue,
            __newindex                  = readonly,
            __tostring                  = getAttributeName
        }
    )

    -----------------------------------------------------------------------
    -- Set the property as throwable
    --
    -- @attribute   System.__Throwable__
    -----------------------------------------------------------------------
    namespace.SaveNamespace("System.__Throwable__",
        prototype {
            __index                     = {
                ["ApplyAttribute"]      = function(self, target, targettype, manager, owner, name, stack)
                    stack               = parsestack(stack) + 1
                    if targettype  == ATTRTAR_PROPERTY then
                        property.SetThrowable(target, stack)
                    end
                end,
                ["AttributeTarget"]     = ATTRTAR_PROPERTY,
            },
            __call                      = attribute.Register,
            __newindex                  = readonly,
            __tostring                  = namespace.GetNamespaceName
        }
    )

    -------------------------------------------------------------------------------
    --                               registration                                --
    -------------------------------------------------------------------------------
    environment.RegisterGlobalNamespace("System")

    -----------------------------------------------------------------------
    --                               enums                               --
    -----------------------------------------------------------------------
    --- The attribute targets
    __Sealed__() __Flags__() __Default__(ATTRTAR_ALL)
    enum "System.AttributeTargets"      {
        All                             = ATTRTAR_ALL,
        Function                        = ATTRTAR_FUNCTION,
        Namespace                       = ATTRTAR_NAMESPACE,
        Enum                            = ATTRTAR_ENUM,
        Struct                          = ATTRTAR_STRUCT,
        Member                          = ATTRTAR_MEMBER,
        Method                          = ATTRTAR_METHOD,
        Interface                       = ATTRTAR_INTERFACE,
        Class                           = ATTRTAR_CLASS,
        Object                          = ATTRTAR_OBJECT,
        Event                           = ATTRTAR_EVENT,
        Property                        = ATTRTAR_PROPERTY,
    }

    --- The attribute priority
    __Sealed__() __Default__(0)
    enum "System.AttributePriority"     {
        Highest                         =  2,
        Higher                          =  1,
        Normal                          =  0,
        Lower                           = -1,
        Lowest                          = -2,
    }

    --- the property set settings
    __Sealed__() __Flags__() __Default__(0)
    enum "System.PropertySet"           {
        Assign                          = 0,
        Clone                           = 1,
        DeepClone                       = 2,
        Retain                          = 4,
        Weak                            = 8,
    }

    --- the property get settings
    __Sealed__() __Flags__() __Default__(0)
    enum "System.PropertyGet"           {
        Origin                          = 0,
        Clone                           = 1,
        DeepClone                       = 2,
    }

    --- the struct category
    __Sealed__()
    enum "System.StructCategory"        {
        "MEMBER",
        "ARRAY",
        "CUSTOM",
        "DICTIONARY"
    }

    -----------------------------------------------------------------------
    --                              structs                              --
    -----------------------------------------------------------------------
    --- Represents any value
    __Sealed__()
    struct "System.Any"                 { }

    --- Represents boolean value
    __Sealed__()
    struct "System.Boolean"             { genBasicValidator("boolean")  }

    --- Represents string value
    __Sealed__()
    struct "System.String"              { genBasicValidator("string")   }

    --- Represents array of string
    __Sealed__()
    struct "System.Strings"             { String }

    --- Represents number value
    __Sealed__()
    struct "System.Number"              { genBasicValidator("number")   }

    --- Represents integer value
    __Sealed__()
    struct "System.Integer"             { __base = Number, function(val, onlyvalid) return floor(val) ~= val and (onlyvalid or "the %s must be an integer") or nil end }

    --- Represents natural number value
    __Sealed__()
    struct "System.NaturalNumber"       { __base = Integer, function(val, onlyvalid) return val < 0 and (onlyvalid or "the %s must be a natural number") or nil end }

    --- Represents function value
    __Sealed__()
    struct "System.Function"            { genBasicValidator("function") }

    --- Represents table value
    __Sealed__()
    struct "System.Table"               { genBasicValidator("table")    }

    --- Represents userdata value
    __Sealed__()
    struct "System.Userdata"            { genBasicValidator("userdata") }

    --- Represents thread value
    __Sealed__()
    struct "System.Thread"              { genBasicValidator("thread")   }

    --- Converts any value to boolean
    __Sealed__()
    struct "System.AnyBool"             { false, __init = function(val) return val and true or false end }

    --- Represents non-empty string
    __Sealed__()
    struct "System.NEString"            { __base = String, function(val, onlyvalid) return strtrim(val) == "" and (onlyvalid or "the %s can't be an empty string") or nil end }

    --- Represents table value without meta-table
    __Sealed__()
    struct "System.RawTable"            { __base = Table, function(val, onlyvalid) return getmetatable(val) ~= nil and (onlyvalid or "the %s must have no meta-table") or nil end  }

    --- Represents namespace type
    __Sealed__()
    struct "System.NamespaceType"       { genTypeValidator(namespace)   }

    --- Represents enum type
    __Sealed__()
    struct "System.EnumType"            { genTypeValidator(enum)        }

    --- Represents struct type
    __Sealed__()
    struct "System.StructType"          { genTypeValidator(struct)      }

    --- Represents interface type
    __Sealed__()
    struct "System.InterfaceType"       { genTypeValidator(interface)   }

    --- Represents class type
    __Sealed__()
    struct "System.ClassType"           { genTypeValidator(class)       }

    --- Represent a property
    __Sealed__()
    struct "System.PropertyType"        { genTypeValidator(property)    }

    --- Represents an event
    __Sealed__()
    struct "System.EventType"           { genTypeValidator(event)       }

    --- Represents any validation type
    __Sealed__()
    struct "System.AnyType"             { function(val, onlyvalid) return not getprototypemethod(val, "ValidateValue") and (onlyvalid or "the %s is not a validation type") or nil end }

    --- Represents the object generated from class
    __Sealed__()
    struct "System.Object"              { function(val, onlyvalid) return not class.GetObjectClass(val) and (onlyvalid or "the %s is not an object") or nil end }

    --- Represents lambda value, used to string like 'x, y => x + y' to function
    __Sealed__()
    struct "System.Lambda"              { __init = function(value) return _LambdaCache[value] end, parseLambda }

    --- Represents callable value, like function, lambda, callable object generate by class
    __Sealed__()
    struct "System.Callable"            { __init = function(value) if type(value) == "string" then return _LambdaCache[value] end end, parseCallable }

    --- Represents the variable types for arguments or return values
    __Sealed__()
    struct "System.Variable"            (function(_ENV)
        export {
            getprototypemethod          = getprototypemethod,
            getobjectvalue              = getobjectvalue,
            Any
        }

        --- the variable's name
        member "name"                   { type = NEString }

        --- the variable's type
        member "type"                   { type = AnyType  }

        --- whether the vairable is optional
        member "optional"               { type = Boolean  }

        --- the variable's default value
        member "default"                {}

        --- whether the variable is a varargs
        member "varargs"                { type = Boolean  }

        --- the minimum count of the varargs
        member "mincount"               { type = NaturalNumber, default = 0 }

        --- the validate function auto fetched from the type
        member "validate"               { type = Function }  -- auto generated

        --- whether the variable is immutable(the value won't be changed)
        member "immutable"              { type = Boolean  }  -- auto generated

        -----------------------------------------------------------
        --                     static method                     --
        -----------------------------------------------------------
        --- Return a varargs
        -- @format  ([type][, mincount])
        -- @param   type                            the element's type
        -- @param   mincount                        the minimum count of the varargs
        -- @return  the list variable
        __Static__()
        function Rest(type, mincount)
            return { type = type, mincount = mincount or 0, varargs = true }
        end

        --- Return an optional variable
        -- @format  ([type][, default])
        -- @parma   type                            the variable's type
        -- @param   default                         the default value
        -- @return  the optional variable
        __Static__()
        function Optional(type, default)
            return { type = type, default = default, optional = true }
        end

        -----------------------------------------------------------
        --                       Validator                       --
        -----------------------------------------------------------
        function Variable(var, onlyvalid)
            if var.default ~= nil then
                if var.varargs then return onlyvalid or "the %s is a varargs, can't have default value" end
                if not var.optional then return onlyvalid or "the %s is not optional, can't have default value" end
                if var.type then
                    local ret, msg      = getprototypemethod(var.type, "ValidateValue")(var.type, var.default, true)
                    if msg then return onlyvalid or "the %s.default don't match its type" end
                end
            end
        end

        -----------------------------------------------------------
        --                      Initializer                      --
        -----------------------------------------------------------
        function __init(var)
            if var.type then
                var.validate            = getprototypemethod(var.type, "ValidateValue")
                var.immutable           = getobjectvalue(var.type, "IsImmutable")

                if var.default ~= nil then
                    var.default         = var.validate(var.type, var.default)
                end

                if var.type == Any then
                    var.validate        = nil
                end
            else
                var.validate            = nil
                var.immutable           = true
            end

            if var.optional and var.default ~= nil then
                var.immutable           = false
            end
        end
    end)

    --- Represents variables list
    __Sealed__()
    struct "System.Variables"           {
        __array                         = Variable + AnyType,
        function(vars, onlyvalid)
            local opt                   = false
            local lst                   = false

            for i, var in ipairs, vars, 0 do
                if lst then return onlyvalid or "the list variable must be the last one" end
                if getmetatable(var) == nil then
                    if var.varargs then
                        lst             = true
                    elseif var.optional then
                        opt             = true
                    elseif opt then
                        return onlyvalid or "the non-optional variables must exist before the optional variables"
                    end
                elseif opt then
                    return onlyvalid or "the non-optional variables must exist before the optional variables"
                end
            end
        end,

        __init                          = function(vars)
            for i, var in ipairs, vars, 0 do
                if getmetatable(var) ~= nil then
                    vars[i]             = Variable{ type = var }
                end
            end
        end,
    }

    --- Represents guid
    __Sealed__()
    struct "System.Guid"                (function(_ENV)
        if _G.os and os.time then math.randomseed(os.time()) end

        export {
            random                      = math.random,
            strmatch                    = string.match,
            strformat                   = string.format,
            strgsub                     = string.gsub,
            type                        = type,
        }

        local GUID_TEMPLTE              = [[xx-x-x-x-xxx]]
        local GUID_FORMAT               = "^" .. GUID_TEMPLTE:gsub("x", "%%x%%x%%x%%x"):gsub("%-", "%%-") .. "$"

        local function GenerateGUIDPart(v) return strformat("%04X", random(0xffff)) end

        -----------------------------------------------------------
        --                     static method                     --
        -----------------------------------------------------------
        --- Generate a new guid
        __Static__() function New()
            return (strgsub(GUID_TEMPLTE, "x", GenerateGUIDPart))
        end

        -----------------------------------------------------------
        --                       validator                       --
        -----------------------------------------------------------
        function Guid(value, onlyvalid)
            if type(value) ~= "string" or #value ~= 36 or not strmatch(value, GUID_FORMAT) then
                return onlyvalid or "the %s must be a string like 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX'"
            end
        end
    end)

    -----------------------------------------------------------------------
    --                             interface                             --
    -----------------------------------------------------------------------
    --- Represents the interface of attribute
    __Sealed__() __ObjectSource__{ Inheritable = true }
    interface "System.IAttribute"       (function(_ENV)
        export {
            GetObjectSource             = Class.GetObjectSource,
            tostring                    = tostring,
            getmetatable                = getmetatable,

            Enum, Struct
        }

        -----------------------------------------------------------
        --                       method                        --
        -----------------------------------------------------------
        --- Set the attribute as inheritable
        function AsInheritable(self)
            self.Inheritable            = true
            return self
        end

        --- Set the priority of the attribute
        function WithPriority(self, priority, sublevel)
            self.Priority               = Enum.ValidateValue(AttributePriority, priority)
            self.SubLevel               = Struct.ValidateValue(Number, sublevel)
            return self
        end

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- the attribute target
        __Abstract__()
        property "AttributeTarget"      { type = AttributeTargets        }

        --- whether the attribute is inheritable
        __Abstract__()
        property "Inheritable"          { type = Boolean                 }

        --- whether the attribute is overridable
        __Abstract__()
        property "Overridable"          { type = Boolean, default = true }

        --- the attribute's priority
        __Abstract__()
        property "Priority"             { type = AttributePriority        }

        --- the attribute's sub level of priority
        __Abstract__()
        property "SubLevel"             { type = Number,  default = 0    }

        -----------------------------------------------------------
        --                      initializer                      --
        -----------------------------------------------------------
        IAttribute                      = Attribute.Register

        -----------------------------------------------------------
        --                      meta-method                      --
        -----------------------------------------------------------
        __Abstract__()
        function __tostring(self) return tostring(getmetatable(self)) .. (GetObjectSource(self) or "") end
    end)

    --- Represents the interface to apply changes on the target
    __Sealed__()
    interface "System.IApplyAttribute"  (function(_ENV)
        extend "IAttribute"

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- apply changes on the target
        -- @param   target                      the target
        -- @param   targettype                  the target type
        -- @param   manager                     the definition manager of the target
        -- @param   owner                       the target's owner
        -- @param   name                        the target's name in the owner
        -- @param   stack                       the stack level
        __Abstract__()
        function ApplyAttribute(self, target, targettype, manager, owner, name, stack)
        end
    end)

    --- Represents the interface to attach data on the target
    __Sealed__()
    interface "System.IAttachAttribute" (function(_ENV)
        extend "IAttribute"

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
        __Abstract__()
        function AttachAttribute(self, target, targettype, owner, name, stack)
        end
    end)

    --- Represents the interface to modify the target's definition
    __Sealed__()
    interface "System.IInitAttribute"   (function(_ENV)
        extend "IAttribute"

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- modify the target's definition
        -- @param   target                      the target
        -- @param   targettype                  the target type
        -- @param   definition                  the target's definition
        -- @param   owner                       the target's owner
        -- @param   name                        the target's name in the owner
        -- @param   stack                       the stack level
        -- @return  definition                  the new definition
        __Abstract__()
        function InitDefinition(self, target, targettype, definition, owner, name, stack)
        end
    end)

    --- Set the class's object to be recyclable
    __Sealed__()
    class "System.__Recyclable__"       { IApplyAttribute,
        ApplyAttribute                  = function (self, target, targettype, manager, owner, name, stack)
            if targettype == ATTRTAR_CLASS then
                class.SetObjectRecyclable(target, self[1], stack + 1)
            end
        end,
        AttributeTarget                 = { set = false, default = ATTRTAR_CLASS + ATTRTAR_INTERFACE },
        __new                           = function (_, flag) return { flag == nil and true or flag } end
    }

    --- Set the class's objects so access non-existent fields on them will be denied
    __Sealed__()
    class "System.__NoNilValue__"       { IApplyAttribute,
        ApplyAttribute                  = function (self, target, targettype, manager, owner, name, stack)
            if targettype == ATTRTAR_CLASS then
                class.SetNilValueBlocked(target, self[1], stack + 1)
            end
        end,
        AttributeTarget                 = { set = false, default = ATTRTAR_CLASS + ATTRTAR_INTERFACE },
        __new                           = function (_, flag) return { flag == nil and true or flag } end
    }

    --- Set the class's objects so save value to non-existent fields on them will be denied
    __Sealed__()
    class "System.__NoRawSet__"         { IApplyAttribute,
        ApplyAttribute                  = function (self, target, targettype, manager, owner, name, stack)
            if targettype == ATTRTAR_CLASS then
                class.SetRawSetBlocked(target, self[1], stack + 1)
            end
        end,
        AttributeTarget                 = { set = false, default = ATTRTAR_CLASS + ATTRTAR_INTERFACE },
        __new                           = function (_, flag) return { flag == nil and true or flag } end
    }

    --- Whether the class's objects use the super object access style like `super[self]:Method()`, `super[self].Name = xxx`
    __Sealed__()
    class "System.__SuperObject__"      { IApplyAttribute,
        ApplyAttribute                  = function (self, target, targettype, manager, owner, name, stack)
            if targettype == ATTRTAR_CLASS then
                class.SetSuperObjectStyle(target, self[1], stack + 1)
            end
        end,
        AttributeTarget                 = { set = false, default = ATTRTAR_CLASS + ATTRTAR_INTERFACE },
        __new                           = function (_, flag) return { flag == nil and true or flag } end
    }

    --- Represents the interface to of clone
    __Sealed__()
    interface "System.ICloneable"       (function(_ENV)
        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- return the clone of the object
        -- @return  the clone
        __Abstract__()
        function Clone(self) end
    end)

    --- Represents the interface for code environment
    __Sealed__()
    __ObjectSource__{ Inheritable = true }
    __NoNilValue__(false):AsInheritable()
    __NoRawSet__(false):AsInheritable()
    interface "System.IEnvironment"     (function(_ENV)
        export {
            tostring                    = tostring,
            getmetatable                = getmetatable,
            GetObjectSource             = Class.GetObjectSource,
        }

        -----------------------------------------------------------
        --                      initializer                      --
        -----------------------------------------------------------
        __init                          = Environment.Initialize

        -----------------------------------------------------------
        --                      meta-method                      --
        -----------------------------------------------------------
        __Abstract__() __index          = Environment.GetValue
        __Abstract__() __newindex       = Environment.SaveValue
        __Abstract__() __call           = Environment.Apply
        __Abstract__() __tostring       = function(self) return tostring(getmetatable(self)) .. (GetObjectSource(self) or "") end
    end)

    --- Represents the interface of open/close resources
    __Sealed__()
    interface "System.IAutoClose"       (function(_ENV)
        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        __Abstract__() function Open(self) end
        __Abstract__() function Close(self, error) end

        -----------------------------------------------------------
        --                      meta-method                      --
        -----------------------------------------------------------
        __Abstract__() function __close(self) self:Close() end
    end)

    --- Represents a toolset to provide several compatible apis
    __Sealed__() __Final__()
    interface "System.Toolset"          {
        --- wipe the table
        -- @param   table
        wipe                            = wipe,

        --- safe save the value into storage
        -- @param   table
        -- @param   key
        -- @param   value
        -- @return  table           maybe a new table to avoid re-hash conflict
        safeset                         = savestorage,

        --- clone the value
        -- @param   value
        -- @param   deep:boolean
        -- @param   safe:boolean    only need if there'd be recursive reference in the table
        -- @return  the clone
        clone                           = clone,

        --- Copy the values in the source to the target table
        -- @param   src: the source table
        -- @param   tar: the target table
        -- @param   deep: whether check the deep level tables
        -- @param   override: whether override the values in the target table
        -- @param   safe: whether there could be the same table in teh source
        -- @return  tar
        copy                            = tblclone,

        --- load the snippets
        -- @param   chunk           the code
        -- @param   source          the source name
        -- @param   env             the environment, default _G
        loadsnippet                     = loadsnippet,

        --- load the init table for the object, only be used as constructor
        -- @param   self            the object
        -- @param   init            the init table
        loadinittable                   = function(self, init)
            local ok, msg               = pcall(loadinittable, self, init)
            if not ok then throw(type(msg) == "string" and strmatch(msg, "%d+:%s*(.-)$") or msg) end
        end,

        --- Convert an index number to string
        -- @param   index           the number
        -- @return  string
        parseindex                      = parseindex,

        --- The bit operations
        lshift                          = lshift,
        rshift                          = rshift,
        band                            = band,
        bor                             = bor,
        bnot                            = bnot,
        bxor                            = bxor,

        --- Number conversion
        inttoreal                       = inttoreal,
        realtoint                       = realtoint,

        --- validate flags values
        -- @param   chkvalue        the check value, must be 2^n
        -- @param   targetvalue     the target value
        -- @return  boolean         true if the target value contains the chkvalue
        validateflags                   = validateflags,

        --- add the check value to the target value
        -- @param   chkvalue        the check value, must be 2^n
        -- @param   targetvalue     the target value
        -- @return  targetvalue     the target value contains the check value
        turnonflags                     = turnonflags,

        --- remove the check value to the target value
        -- @param   chkvalue        the check value, must be 2^n
        -- @param   targetvalue     the target value
        -- @return  targetvalue     the target value don't contains the check value
        turnoffflags                    = turnoffflags,

        --- A readonly function used by meta-table
        readonly                        = readonly,

        --- A writeonly function used by metaw-table
        writeonly                       = writeonly,

        --- Trim the string
        trim                            = strtrim,

        --- A fake function that do nothing
        fakefunc                        = fakefunc,

        --- A function used to return an empty table with weak settings
        newtable                        = function(weakKey, weakVal) return weakKey and setmetatable({}, weakVal and WEAK_ALL or WEAK_KEY) or weakVal and setmetatable({}, WEAK_VALUE) or {} end,
    }

    -----------------------------------------------------------------------
    --                              classes                              --
    -----------------------------------------------------------------------
    --- the attribute to build the overload system, also can be used to set
    -- the target struct, class or interface as template
    __Sealed__() __Final__() __NoRawSet__(false) __NoNilValue__(false)
    class "System.__Arguments__"        (function(_ENV)
        extend "IInitAttribute"

        --- Enable the attach attribute
        if Platform.ENABLE_ARGUMENTS_ATTACHMENT then
            extend "IAttachAttribute"
        end

        local _OverloadStorage          = newstorage(WEAK_KEY)
        local _OverloadHistory          = Platform.ENABLE_ARGUMENTS_ATTACHMENT and newstorage(WEAK_KEY) or nil

        export {
            -----------------------------------------------------------
            --                        storage                        --
            -----------------------------------------------------------
            _OverloadMap                = {},
            _ArgValdMap                 = {},

            -----------------------------------------------------------
            --                        constant                       --
            -----------------------------------------------------------
            FLD_VAR_FUNCTN              =  0,
            FLD_VAR_MINARG              = -1,
            FLD_VAR_MAXARG              = -2,
            FLD_VAR_IMMTBL              = -3,
            FLD_VAR_USGMSG              = -4,
            FLD_VAR_VARVLD              = -5,
            FLD_VAR_THRABL              = -6,
            FLD_VAR_NDTHIS              = -7,

            TYPE_VALD_DISD              = Platform.TYPE_VALIDATION_DISABLED,
            ALL_USE_THIS                = Platform.USE_THIS_FOR_OBJECT_METHODS,

            CTOR_METHOD                 = {
                __exist                 = true,
                __new                   = true,
                __ctor                  = true,
            },

            PASS_STACK_METHOD           = {
                __index                 = 1,
                __newindex              = 2,
            },

            PLOOP_THIS_LOCAL            = "_PLoop_Overload_This",

            FLG_FNC_METHOD              = newflags(true),    -- the function is a method
            FLG_FNC_SELFIN              = newflags(),        -- the function has self
            FLG_FNC_THRABL              = newflags(),        -- the target may throw exception
            FLG_FNC_NILLST              = newflags(),        -- the list can be nil

            FLG_TYP_BUILDER             = newflags(true),    -- the target should be a type builder
            FLG_TYP_CONTOR              = newflags(),        -- the constructor
            FLG_TYP_PSTACK              = newflags(),        -- the __index & __newindex that should pass the stack level

            FLG_VAR_ISLIST              = newflags(true),    -- the variable is list
            FLG_VAR_HASTYP              = newflags(),        -- the variable has type
            FLG_VAR_OPTION              = newflags(),        -- the variable is optional
            FLG_VAR_IMMUTE              = newflags(),        -- the variable is immutable

            FLG_OVD_SELFIN              = newflags(true),    -- has self
            FLG_OVD_THROW               = newflags(),        -- the constructor, use throw
            FLG_OVD_THIS                = newflags(),        -- need this keyword
            FLG_OVD_PSTACK              = newflags(),        -- the __index & __newindex that should pass the stack level

            -----------------------------------------------------------
            --                        helpers                        --
            -----------------------------------------------------------
            serialize                   = serialize,
            combineToken                = combineToken,
            replaceIndex                = replaceIndex,
            parsestack                  = parsestack,
            getlocal                    = getlocal,
            tblclone                    = tblclone,
            validate                    = Struct.ValidateValue,
            geterrmsg                   = Struct.GetErrorMessage,
            savestorage                 = savestorage,
            ipairs                      = ipairs,
            tinsert                     = tinsert,
            tremove                     = tremove,
            uinsert                     = uinsert,
            tblconcat                   = tblconcat,
            strformat                   = strformat,
            strsub                      = strsub,
            strgsub                     = strgsub,
            wipe                        = wipe,
            type                        = type,
            getmetatable                = getmetatable,
            tostring                    = tostring,
            loadsnippet                 = loadsnippet,
            _Cache                      = _Cache,
            turnonflags                 = turnonflags,
            validateflags               = validateflags,
            parseindex                  = parseindex,
            fakefunc                    = fakefunc,
            unpack                      = unpack,
            error                       = error,
            select                      = select,
            stackmod                    = (LUA_VERSION == 5.1 and not _G.jit) and 1 or 0,
            chkandret                   = function (stack, ok, msg, ...) if ok then return msg, ... end error(tostring(msg), stackmod + stack) end,
            pcall                       = pcall,
            getfenv                     = getfenv,
            setfenv                     = setfenv,
            throw                       = throw,
        }

        export { Namespace, Enum, Struct, Interface, Class, Variables, Attribute, AttributeTargets, StructCategory, __Arguments__ }

        -- Helpers for this keyword
        if not getlocal then
            -- Should only be used in single os thread platforms
            -- May cause problems when abuse, but we won't get a better solution
            -- since we have no debug.getlocal api
            export{
                wipe                    = wipe,

                overloadstack           = {},

                releaseAndRet           = function(overload, ok, msg, ...)
                    local rover         = tremove(overloadstack)
                    if rover ~= overload then
                        wipe(overloadstack)
                        throw("the overload system's call stack is unavailable")
                    end
                    if ok then return msg, ... end
                    error(msg, 0)
                end,

                addCurrent              = function(overload)
                    tinsert(overloadstack, overload)
                    return overload
                end,
            }
        end

        local getCurrentOverload        = getlocal and function(stack)
            local index                 = 1
            local n, v                  = getlocal(stack, index)

            while stack < 7 do
                while n do
                    if n == PLOOP_THIS_LOCAL then
                        return v
                    end

                    index               = index + 1
                    n, v                = getlocal(stack, index)
                end

                stack                   = stack + 1
                index                   = 1
                n, v                    = getlocal(stack, index)
            end
        end or function()
            return overloadstack[#overloadstack]
        end

        local function buildUsage(vars, owner, name, targettype)
            local usage                 = {}

            if targettype == AttributeTargets.Method then
                if CTOR_METHOD[name] and Class.Validate(owner) then
                    tinsert(usage, strformat("Usage: %s(", tostring(owner)))
                elseif getmetatable(owner).IsStaticMethod(owner, name) then
                    tinsert(usage, strformat("Usage: %s.%s(", tostring(owner), name))
                else
                    tinsert(usage, strformat("Usage: %s:%s(", tostring(owner), name))
                end
            elseif targettype == AttributeTargets.Function then
                tinsert(usage, strformat("Usage: %s(", name))
            else
                if #vars == 1 then
                    tinsert(usage, strformat("Usage: %s[", tostring(owner)))
                else
                    tinsert(usage, strformat("Usage: %s[{", tostring(owner)))
                end
            end

            for i, var in ipairs, vars, 0 do
                if i > 1 then tinsert(usage, ", ") end

                if var.optional or (var.varargs and var.mincount == 0) then tinsert(usage, "[") end

                if var.name or var.varargs then
                    tinsert(usage, var.varargs and ("..." .. (var.mincount > 1 and (" [*" .. var.mincount .. "]") or "")) or var.name)
                    if var.type then
                        tinsert(usage, " as ")
                    end
                end

                if var.type then
                    if Struct.Validate(var.type) and Struct.GetStructCategory(var.type) == StructCategory.ARRAY then
                        tinsert(usage, "{" .. tostring(Struct.GetArrayElement(var.type)) .. ", ...}")
                    else
                        tinsert(usage, tostring(var.type))
                    end
                end

                if var.default ~= nil then
                    tinsert(usage, " = ")
                    tinsert(usage, serialize(var.default, var.type))
                end

                if var.optional or (var.varargs and var.mincount == 0) then tinsert(usage, "]") end
            end

            if targettype == AttributeTargets.Method or targettype == AttributeTargets.Function then
                tinsert(usage, ")")
            else
                if #vars == 1 then
                    tinsert(usage, "]")
                else
                    tinsert(usage, "}]")
                end
            end

            vars[FLD_VAR_USGMSG]        = tblconcat(usage, "")
        end

        local function genArgumentValid(vars, ismulti, owner, name, hasself, isbuilder)
            local len                   = #vars
            if len == 0 and not vars[FLD_VAR_THRABL] then return end

            local tokens                = _Cache()
            local islist                = false
            local isctor                = false
            local passStack             = PASS_STACK_METHOD[name] and (Class.Validate(owner) or Interface.Validate(owner)) and PASS_STACK_METHOD[name] or false

            local token                 = 0

            if ismulti then
                token                   = turnonflags(FLG_FNC_METHOD, token)
            end

            if hasself then
                token                   = turnonflags(FLG_FNC_SELFIN, token)
            end

            if vars[FLD_VAR_THRABL] then
                token                   = turnonflags(FLG_FNC_THRABL, token)
            end

            tokens[1]                   = token

            token                       = 0

            if not ismulti and CTOR_METHOD[name] and (Class.Validate(owner) or Interface.Validate(owner)) then
                isctor                  = true
                token                   = turnonflags(FLG_TYP_CONTOR, token)
            end

            if isbuilder then
                token                   = turnonflags(FLG_TYP_BUILDER, token)
            end

            if passStack then
                token                   = turnonflags(FLG_TYP_PSTACK, token)
            end

            tokens[2]                   = token

            for i = 1, len do
                local var               = vars[i]
                token                   = 0

                if var.varargs then
                    token               = turnonflags(FLG_VAR_ISLIST, token)
                    islist              = true

                    if var.mincount == 0 then
                        tokens[1]       = turnonflags(FLG_FNC_NILLST, tokens[1])
                    end
                end

                if var.validate then
                    token               = turnonflags(FLG_VAR_HASTYP, token)
                end

                if var.optional then
                    token               = turnonflags(FLG_VAR_OPTION, token)
                end

                if var.immutable then
                    token               = turnonflags(FLG_VAR_IMMUTE, token)
                end

                tokens[i + 2]           = token
            end

            token                       = combineToken(tokens)
            _Cache(tokens)

            -- Build the validator generator
            if not _ArgValdMap[token] then
                local head              = _Cache()
                local body              = _Cache()
                local apis              = _Cache()
                local args              = _Cache()
                local tmps              = _Cache()
                local targs             = args

                uinsert(apis, "type")
                uinsert(apis, "strgsub")
                uinsert(apis, "tostring")

                tinsert(body, "")                       -- remain for shareable variables

                for i = 1, len          do args[i] = "v" .. i end

                if not ismulti          then tinsert(tmps, "usage") end
                tinsert(tmps, "func")
                if len > 0              then tinsert(tmps, tblconcat(args, ", ")) end

                tinsert(body, strformat("return function(%s)", tblconcat(tmps, ", ")))
                wipe(tmps)

                for i = 1, len          do args[i] = "a" .. i end
                if islist               then args[len] = nil end
                if passStack            then args[passStack + 1] = "rstack" end  -- no more check
                if hasself              then tinsert(args, 1, "self") end

                args                    = tblconcat(args, ", ") or ""

                local alen              = #args

                if ismulti              then tinsert(tmps, "onlyvalid") end
                if alen > 0             then tinsert(tmps, args) end
                if islist               then tinsert(tmps, "...") end

                tinsert(body, strformat([[return function(%s)]], tblconcat(tmps, ", ")))

                if not ismulti          then uinsert(apis, "error") end

                if isctor               then uinsert(apis, "throw") tinsert(body, [[local error = throw]]) end

                if isbuilder then
                    uinsert(apis, "getfenv")
                    uinsert(apis, "setfenv")
                    uinsert(apis, "throw")

                    tinsert(body, [[local error = throw]])
                    tinsert(body, [[setfenv(func, getfenv(1))]])
                end

                tinsert(body, [[local stack = 2]])

                if passStack then
                    uinsert(apis, "type")
                    tinsert(body, [[if type(rstack) == "number" then stack = rstack + 1 end]])
                end

                tinsert(body, [[local ret, msg, var]])

                for i = 1, islist and (len - 1) or len do
                    local var           = vars[i]
                    tinsert(body, replaceIndex([[var = _vi_]], i))
                    tinsert(body, replaceIndex([[if _ai_ == nil then]], i))

                    if var.optional then
                        tinsert(body, replaceIndex([[_ai_ = var.default]], i))
                    else
                        if ismulti then
                            tinsert(body, [[return onlyvalid]])
                        else
                            tinsert(body, replaceIndex([[error(usage .. " - the _pi_ argument can't be nil", stack)]], i))
                        end
                    end

                    if var.validate then
                        if ismulti then
                            tinsert(body, replaceIndex([[
                                else
                                    ret, msg = var.validate(var.type, _ai_, onlyvalid)
                                    if msg then return onlyvalid end
                                    _ai_ = ret
                                end
                            ]], i))
                        else
                            tinsert(body, replaceIndex([[
                                else
                                    ret, msg = var.validate(var.type, _ai_)
                                    if msg then error(usage .. " - " .. (type(msg) == "string" and strgsub(msg, "%%s", "_pi_ argument") or ("the _pi_ argument must be " .. tostring(var.type))), stack) end
                                    _ai_ = ret
                                end
                            ]], i))
                        end
                    else
                        tinsert(body, [[end]])
                    end
                end

                if not islist then
                    if ismulti then
                        tinsert(body, [[if onlyvalid then return end]])
                    end
                    tinsert(body, strformat([[return func(%s)]], args))
                else
                    tinsert(body, replaceIndex([[var = _vi_]], len))
                    if vars[len].mincount > 0 then tinsert(body, [[local varminct = var.mincount]]) end
                    if vars[len].validate then tinsert(body, [[local varvalid, vartype = var.validate, var.type]]) end
                    if vars[len].immutable then
                        if vars[len].mincount > 0 or vars[len].validate then
                            uinsert(apis, "select")
                            if not ismulti then uinsert(apis, "parseindex") end

                            tinsert(body, [[local vlen = select("#", ...)]])

                            if vars[len].mincount > 0 then
                                if ismulti then
                                    tinsert(body, replaceIndex([[if vlen < varminct then return onlyvalid end]], len))
                                else
                                    tinsert(body, replaceIndex([[if vlen < varminct then error(usage .. " - " .. "the ... must contains at least " .. varminct .. " arguments", stack) end]], len))
                                end
                            end

                            tinsert(body, [[
                                for i = 1, vlen do
                                    local ival = select(i, ...)
                                    if ival == nil then
                            ]])

                            if vars[len].mincount > 0 then
                                if ismulti then
                                    tinsert(body, replaceIndex([[if i <= varminct then return onlyvalid end]], len))
                                else
                                    tinsert(body, replaceIndex([[if i <= varminct then error(usage .. " - " .. ("the " .. parseindex(i - 1 + _i_) .. " argument can't be nil"), stack) end]], len))
                                end
                            end
                            tinsert(body, [[break]])
                            if vars[len].validate then
                                if ismulti then
                                    tinsert(body, replaceIndex([[
                                        else
                                            ret, msg= varvalid(vartype, ival, onlyvalid)
                                            if msg then return onlyvalid end
                                   ]], len))
                                else
                                    tinsert(body, replaceIndex([[
                                        else
                                            ret, msg= varvalid(vartype, ival)
                                            if msg then error(usage .. " - " .. (type(msg) == "string" and strgsub(msg, "%%s", parseindex(i - 1 + _i_) .. " argument") or ("the " .. parseindex(i - 1 + _i_) .. " argument must be " .. tostring(vartype))), stack) end
                                   ]], len))
                                end
                            end
                            tinsert(body, [[
                                    end
                                end
                            ]])
                        end

                        if ismulti then tinsert(body, [[if onlyvalid then return end]]) end
                        if alen == 0 then
                            tinsert(body, [[return func(...)]])
                        else
                            tinsert(body, strformat([[return func(%s, ...)]], args))
                        end
                    else
                        uinsert(apis, "select")
                        uinsert(apis, "unpack")
                        if not ismulti then uinsert(apis, "parseindex") end

                        tinsert(body, [[local vlen = select("#", ...)]])

                        if vars[len].mincount > 0 then
                            if ismulti then
                                tinsert(body, replaceIndex([[if vlen < varminct then return onlyvalid end]], len))
                            else
                                tinsert(body, replaceIndex([[if vlen < varminct then error(usage .. " - " .. "the ... must contains at least " .. varminct .. " arguments", stack) end]], len))
                            end
                        end

                        if ismulti then
                            tinsert(body, replaceIndex(([[
                                if vlen > 0 then
                                    if onlyvalid then
                                        for i = 1, vlen do
                                            local ival = select(i, ...)
                                            if ival == nil then]] .. (vars[len].mincount > 0 and [[
                                                if i <= varminct then return onlyvalid end]] or "") .. [[
                                                break
                                            else
                                                ret, msg= varvalid(vartype, ival, onlyvalid)
                                                if msg then return onlyvalid end
                                            end
                                        end
                                        return
                                    else
                                        local vlst  = { ... }
                                        for i = 1, vlen do
                                            local ival = vlst[i]
                                            if ival == nil then
                                                break
                                            else
                                                vlst[i] = varvalid(vartype, ival)
                                            end
                                        end
                                        ]] .. (alen == 0 and [[return func(unpack(vlst))]] or [[return func(_arg_, unpack(vlst))]]) .. [[
                                    end
                                else
                                    if onlyvalid then return end
                                    return func(_arg_)
                                end
                            ]]):gsub("_arg_", args), len))
                        else
                            tinsert(body, replaceIndex(([[
                                if vlen > 0 then
                                    local vlst  = { ... }
                                    for i = 1, vlen do
                                        local ival = vlst[i]
                                        if ival == nil then]] .. (vars[len].mincount > 0 and [[
                                            if i <= varminct then error(usage .. " - " .. ("the " .. parseindex(i - 1 + _i_) .. " argument can't be nil"), stack) end]] or "") .. [[
                                            break
                                        else
                                            ret, msg= varvalid(vartype, ival)
                                            if msg then error(usage .. " - " .. (type(msg) == "string" and strgsub(msg, "%%s", parseindex(i - 1 + _i_) .. " argument") or ("the " .. parseindex(i + _i_) .. " argument must be " .. tostring(vartype))), stack) end
                                            vlst[i] = ret
                                        end
                                    end
                                    ]] .. (alen == 0 and [[return func(unpack(vlst))]] or [[return func(_arg_, unpack(vlst))]]) .. [[
                                else
                                    return func(_arg_)
                                end
                            ]]):gsub("_arg_", args), len))
                        end
                    end
                end

                tinsert(body, [[
                        end
                    end
                ]])

                if vars[FLD_VAR_THRABL] then
                    uinsert(apis, "chkandret")
                    uinsert(apis, "pcall")
                end

                if #apis > 0 then
                    local declare       = tblconcat(apis, ", ")
                    body[1]             = strformat("local %s = %s", declare, declare)
                end

                if vars[FLD_VAR_THRABL] then
                    _ArgValdMap[token]  = loadsnippet(tblconcat(body, "\n"):gsub("return func(%b())", function(arg) arg = strsub(arg, 2, -2) or "" return "return chkandret(stack, pcall(func" .. (#arg > 0 and (", " .. arg) or "") .. "))" end), "Argument_Validate_" .. token, _ENV)()
                else
                    _ArgValdMap[token]  = loadsnippet(tblconcat(body, "\n"), "Argument_Validate_" .. token, _ENV)()
                end

                _Cache(head) _Cache(body) _Cache(apis) _Cache(tmps) _Cache(targs)
            end

            if ismulti then
                vars[FLD_VAR_VARVLD]    = _ArgValdMap[token](unpack(vars, 0))
            else
                vars[FLD_VAR_VARVLD]    = _ArgValdMap[token](vars[FLD_VAR_USGMSG], unpack(vars, 0))
            end
        end

        local function genOverload(overload, owner, name, hasself, needthis)
            local token                 = 0
            local passStack             = PASS_STACK_METHOD[name] and (Class.Validate(owner) or Interface.Validate(owner)) and PASS_STACK_METHOD[name] or false

            if hasself then
                token                   = turnonflags(FLG_OVD_SELFIN, token)
            end

            if CTOR_METHOD[name] and Class.Validate(owner) then
                token                   = turnonflags(FLG_OVD_THROW, token)
            end

            if needthis then
                token                   = turnonflags(FLG_OVD_THIS, token)
            end

            if passStack then
                token                   = token + FLG_OVD_PSTACK * passStack
            end

            local usages                = { "the calling style must be one of the follow:" }
            for i = 1, #overload do usages[i + 1] = overload[i][FLD_VAR_USGMSG] end
            usages                      = tblconcat(usages, "\n    ")

            -- Build the validator generator
            if not _OverloadMap[token] then
                local body              = _Cache()
                local apis              = _Cache()
                local needthis          = validateflags(FLG_OVD_THIS, token)

                uinsert(apis, "select")
                uinsert(apis, "chkandret")
                uinsert(apis, "pcall")
                if needthis and not getlocal then
                    uinsert(apis, "addCurrent")
                    uinsert(apis, "releaseAndRet")
                end

                tinsert(body, "")                       -- remain for shareable variables

                tinsert(body, "return function(overload, count, usages)")

                if needthis then
                    if hasself then
                        tinsert(body, [[
                            local overloadFunc
                            overloadFunc = function(self, ...)
                        ]])
                    else
                        tinsert(body, [[
                            local overloadFunc
                            overloadFunc = function(...)
                        ]])
                    end
                    if getlocal then
                        tinsert(body, ([[local %s = overloadFunc]]):format(PLOOP_THIS_LOCAL))
                    end
                else
                    if hasself then
                        tinsert(body, [[return function(self, ...)]])
                    else
                        tinsert(body, [[return function(...)]])
                    end
                end

                tinsert(body, [[local stack = 2]])

                if passStack then
                    uinsert(apis, "select")
                    uinsert(apis, "type")
                    tinsert(body, [[
                        local rstack = select(]] .. (passStack + 1) ..[[, ...)
                        if type(rstack) == "number" then stack = rstack + 1 end
                    ]])
                end

                tinsert(body, [[
                    local argcnt = select("#", ...)
                    while argcnt > 0 and select(argcnt, ...) == nil do
                        argcnt   = argcnt - 1
                    end
                    if argcnt == 0 then
                        for i = 1, count do
                            local vars = overload[i]
                            if vars[]] .. FLD_VAR_MINARG .. [[] == 0 then
                                if vars[]] .. FLD_VAR_IMMTBL .. [[] then
                                    if vars[]] .. FLD_VAR_THRABL .. [[] then
                                        return chkandret(stack, pcall(vars[]] .. FLD_VAR_FUNCTN .. [[], ]] .. (hasself and "self, " or "") .. [[...))
                                    else
                                        return ]] .. (needthis and (getlocal and "chkandret(stack, true, " or "releaseAndRet(addCurrent(overloadFunc), pcall(") or "") .. [[ vars[]] .. FLD_VAR_FUNCTN .. (needthis and not getlocal and [[], ]] or [[](]]) .. (hasself and "self, " or "") .. [[...) ]] .. (needthis and ")" or "") .. [[
                                    end
                                else
                                    return ]] .. (needthis and (getlocal and "chkandret(stack, true, " or "releaseAndRet(addCurrent(overloadFunc), pcall(") or "") .. [[ vars[]] .. FLD_VAR_VARVLD .. (needthis and not getlocal and [[], nil, ]] or [[](nil, ]]) .. (hasself and "self, " or "") .. [[...) ]] .. (needthis and ")" or "") .. [[
                                end
                            end
                        end
                    else
                        for i = 1, count do
                            local vars = overload[i]
                            if vars[]] .. FLD_VAR_MINARG .. [[] <= argcnt and argcnt <= vars[]] .. FLD_VAR_MAXARG .. [[] then
                                local valid = vars[]] .. FLD_VAR_VARVLD .. [[]

                                if valid(true, ]] .. (hasself and "self, " or "") .. [[...) == nil then
                                    if vars[]] .. FLD_VAR_IMMTBL .. [[] then
                                        if vars[]] .. FLD_VAR_THRABL .. [[] then
                                            return chkandret(stack, pcall(vars[]] .. FLD_VAR_FUNCTN .. [[], ]] .. (hasself and "self, " or "") .. [[...))
                                        else
                                            return ]] .. (needthis and (getlocal and "chkandret(stack, true, " or "releaseAndRet(addCurrent(overloadFunc), pcall(") or "") .. [[ vars[]] .. FLD_VAR_FUNCTN .. (needthis and not getlocal and [[], ]] or [[](]]) .. (hasself and "self, " or "") .. [[...) ]] .. (needthis and ")" or "") .. [[
                                        end
                                    else
                                        return ]] .. (needthis and (getlocal and "chkandret(stack, true, " or "releaseAndRet(addCurrent(overloadFunc), pcall(") or "") .. (needthis and not getlocal and [[ valid, nil, ]] or [[ valid(nil, ]]) .. (hasself and "self, " or "") .. [[...) ]] .. (needthis and ")" or "") .. [[
                                    end
                                end
                            end
                        end
                    end
                    -- Raise the usages
                ]])
                if validateflags(FLG_OVD_THROW, token) then
                    tinsert(body, [[
                        throw(usages)
                    ]])
                else
                    uinsert(apis, "error")
                    tinsert(body, [[
                       error(usages, stack)
                    ]])
                end

                tinsert(body, [[
                    end
                ]])

                if needthis then
                    tinsert(body, [[
                        return overloadFunc
                    ]])
                end

                tinsert(body, [[
                    end
                ]])

                if #apis > 0 then
                    local declare       = tblconcat(apis, ", ")
                    body[1]             = strformat("local %s = %s", declare, declare)
                end

                _OverloadMap[token]     = loadsnippet(tblconcat(body, "\n"), "Overload_Process_" .. token, _ENV)()

                _Cache(body)
                _Cache(apis)
            end

            return _OverloadMap[token](overload, #overload, usages)
        end

        -----------------------------------------------------------
        --                     static method                     --
        -----------------------------------------------------------
        --- Generate an overload method to handle all rest argument groups
        __Static__() function Rest()
            return Class.AttachObjectSource(__Arguments__{ { varargs = true } }, 2)
        end

        --- Clear the useless cache for sealed types
        __Static__() function ClearOverloads(ttype)
            if not (ttype and getmetatable(ttype).IsSealed(ttype)) then return end
            _OverloadStorage[ttype]     = nil
        end

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- Mark the target function as throwable
        function Throwable(self)
            self.IsThrowable            = true
            return self
        end

        --- Mark the overload must use this keyword
        function UseThis(self)
            self.IsThisUsable           = true
        end

        --- modify the target's definition
        -- @param   target                      the target
        -- @param   targettype                  the target type
        -- @param   definition                  the target's definition
        -- @param   owner                       the target's owner
        -- @param   name                        the target's name in the owner
        -- @param   stack                       the stack level
        -- @return  definition                  the new definition
        function InitDefinition(self, target, targettype, definition, owner, name, stack)
            stack                       = parsestack(stack) + 1

            local passStack             = PASS_STACK_METHOD[name] and (Class.Validate(owner) or Interface.Validate(owner)) and PASS_STACK_METHOD[name] or false

            if type(definition) ~= "function" then
                error("Usage: __Arguments__ can only be used on features with function as definition", stack)
            end

            local len                   = #self

            if len == 0 and (targettype == AttributeTargets.Class or targettype == AttributeTargets.Interface or targettype == AttributeTargets.Struct) then
                error("Usage: __Arguments__ can't be empty to declare template types", stack)
            end

            if passStack and len ~= passStack then
                if len > passStack then
                    error(strformat("Usage: __Arguments__ can only have %d variable settings for %s", passStack, name), stack)
                else
                    error(strformat("Usage: __Arguments__ must have %d variable settings for %s", passStack, name), stack)
                end
            end

            local vars                  = {
                [FLD_VAR_FUNCTN]        = definition,
                [FLD_VAR_MINARG]        = len,
                [FLD_VAR_MAXARG]        = len + (passStack and 1 or 0),
                [FLD_VAR_IMMTBL]        = true,
                [FLD_VAR_USGMSG]        = "",
                [FLD_VAR_VARVLD]        = false,
                [FLD_VAR_THRABL]        = self.IsThrowable and not CTOR_METHOD[name],
                [FLD_VAR_NDTHIS]        = self.IsThisUsable,
            }

            local minargs
            local immutable             = true

            for i = 1, len do
                local var               = self[i]

                if not var then
                    error(strformat("Usage: __Arguments__{...} - the %s type setting is not valid", parseindex(i)), stack)
                end

                vars[i]                 = var

                if var.optional then
                    minargs             = minargs or i - 1
                end

                if var.varargs then
                    if passStack then
                        error(strformat("Usage: __Arguments__ can't have varargs variable for %s", name), stack)
                    end

                    vars[FLD_VAR_MAXARG]= 255

                    if not var.mincount or var.mincount == 0 then
                        minargs         = minargs or i - 1
                    else
                        minargs         = i + var.mincount - 1
                    end
                end

                if not var.immutable then
                    immutable           = false
                end
            end

            vars[FLD_VAR_MINARG]        = minargs or vars[FLD_VAR_MINARG]
            vars[FLD_VAR_IMMTBL]        = immutable

            if targettype == AttributeTargets.Method then
                -- Check the previous one for the overload history
                if _OverloadHistory then
                    local history       = _OverloadHistory[owner] and _OverloadHistory[owner][name]

                    if not history then
                        local previous  = Class.Validate(owner) and CTOR_METHOD[name] and Class.GetMetaMethod(owner, name) or getmetatable(owner).GetMethod(owner, name)
                        if previous then
                            _OverloadHistory[owner]       = _OverloadHistory[owner] or {}
                            _OverloadHistory[owner][name] = { previous }
                        end
                    end
                end

                -- Generate the overloads
                local hasself           = not getmetatable(owner).IsStaticMethod(owner, name)
                buildUsage(vars, owner, name, targettype)

                local overload          = _OverloadStorage[owner] and _OverloadStorage[owner][name]

                if overload then
                    local eidx
                    -- Check if override
                    for i, evars in ipairs, overload, 0 do
                        if #evars == #vars then
                            eidx        = i
                            for j, v in ipairs, evars, 0 do
                                if v.type ~= vars[j].type then
                                    eidx= nil
                                    break
                                end
                            end
                            if eidx then break end
                        end
                    end

                    if eidx then
                        overload[eidx]  = vars
                    else
                        overload[#overload + 1] = vars
                    end
                else
                    overload            = { vars }
                end

                _OverloadStorage[owner] = _OverloadStorage[owner] or {}
                _OverloadStorage[owner][name] = overload

                -- type validation disabled
                if #overload == 1 and TYPE_VALD_DISD and vars[FLD_VAR_IMMTBL] and not vars[FLD_VAR_THRABL] then return end

                -- only one function
                if #overload == 1 then
                    genArgumentValid(vars, false, owner, name, hasself)
                    return vars[FLD_VAR_VARVLD] or nil
                end

                -- we have more function now, re-generate the first's setting
                if #overload == 2 then
                    overload[1][FLD_VAR_VARVLD] = false
                    genArgumentValid(overload[1], true, owner, name, hasself)
                end

                genArgumentValid(vars, true, owner, name, hasself)

                -- check need this
                local needthis          = ALL_USE_THIS

                if not needthis then
                    if CTOR_METHOD[name] and Class.Validate(owner) then
                        needthis        = true
                    else
                        for _, vars in ipairs, overload, 0 do
                            if vars[FLD_VAR_NDTHIS] then
                                needthis= true
                                break
                            end
                        end
                    end
                end

                return genOverload(tblclone(overload, {}), owner, name, hasself, needthis)
            else
                local isbuilder         = targettype ~= AttributeTargets.Function
                if not isbuilder and TYPE_VALD_DISD and vars[FLD_VAR_IMMTBL] and not vars[FLD_VAR_THRABL] then return end

                buildUsage(vars, owner or target, name, targettype)
                genArgumentValid(vars, false, owner, name, isbuilder, isbuilder)

                if targettype == AttributeTargets.Class then
                    Class.SetAsTemplate(target, self.Template, stack)
                elseif targettype == AttributeTargets.Interface then
                    Interface.SetAsTemplate(target, self.Template, stack)
                elseif targettype == AttributeTargets.Struct then
                    Struct.SetAsTemplate(target, self.Template, stack)
                end

                return vars[FLD_VAR_VARVLD] or nil
            end
        end

        if Platform.ENABLE_ARGUMENTS_ATTACHMENT then
            --- attach attribute
            -- @param target                    the target
            -- @param targettype                the target type
            -- @param owner                     the target's owner
            -- @param name                      the target's name in the owner
            -- @param stack                     the stack level
            function AttachAttribute(self, target, targettype, owner, name, stack)
                -- Register the overloads
                if targettype == AttributeTargets.Method and _OverloadHistory[owner] and _OverloadHistory[owner][name] then
                    tinsert(_OverloadHistory[owner][name], target)
                end

                return { unpack(self) }
            end

            --- Gets the overloads of the target type's method
            -- @param target                    the target type like class
            -- @param name                      the method name
            -- @usage
            --    class "A" (function(_ENV)
            --        __Arguments__{ String } __Return__{ Number }
            --        function Test()
            --        end

            --        __Arguments__{ Number } __Return__ { Boolean }
            --        function Test()
            --        end

            --        __Arguments__{ Boolean } __Return__{ String }
            --        function Test()
            --        end
            --    end)
            --
            --    for i, v in __Arguments__.GetOverloads(A, "Test") do
            --        local args = Attribute.GetAttachedData(__Arguments__, v, A)
            --        local ret = Attribute.GetAttachedData(__Return__, v, A)
            --
            --        -- System.Number  A:Test(System.String) 
            --        -- System.Boolean A:Test(System.Number) 
            --        -- System.String  A:Test(System.Boolean) 
            --        print(("%s A:Test(%s) "):format(tostring(ret[1][1].type), tostring(args[1].type)))
            --    end
            __Static__()
            function GetOverloads(target, name)
                local nameMap           = _OverloadHistory[target]
                local history           = nameMap and nameMap[name]

                if history and #history > 0 then
                    return function (_, n)
                        return next(history, n)
                    end
                else
                    local overload      = Class.Validate(target) and CTOR_METHOD[name] and Class.GetMetaMethod(target, name) or getmetatable(target).GetMethod(target, name)

                    if overload then
                        return function(_, n)
                            if n == nil then return 1, overload end
                        end
                    else
                        return fakefunc
                    end
                end
            end
        end

        -----------------------------------------------------------
        --                       property                       --
        -----------------------------------------------------------
        --- the attribute target
        property "AttributeTarget"      { type = AttributeTargets,  default = AttributeTargets.Method + AttributeTargets.Function + AttributeTargets.Class + AttributeTargets.Interface + AttributeTargets.Struct }

        --- the attribute's priority
        property "Priority"             { type = AttributePriority, default = AttributePriority.Lowest }

        --- the attribute's sub level of priority
        property "SubLevel"             { type = Number,            default = -99999 }

        --- whether the target function may throw exceptions instead of error message
        property "IsThrowable"          { type = Boolean }

        --- whether must use the this keyword
        property "IsThisUsable"         { type = Boolean }

        --- The template parameter
        property "Template"             { type = Any }

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        function __new(_, vars, ...)
            if vars ~= nil then
                if select("#", ...) > 0 then
                    vars                = { vars, ... }
                elseif getmetatable(vars) ~= nil then
                    vars                = { vars }
                end

                local ret, msg          = validate(Variables, vars)
                if msg then throw("Usage: __Arguments__{ ... } - " .. geterrmsg(msg, "")) end

                return vars
            else
                return {}
            end
        end

        -----------------------------------------------------------
        --                      meta-method                      --
        -----------------------------------------------------------
        function __call(self, first, ...)
            if select("#", ...) == 0 and type(first) == "table" and getmetatable(first) == nil then
                self.Template           = first
            else
                self.Template           = { first, ... }
            end
            return self
        end

        -----------------------------------------------------------
        --                     keyword: this                     --
        -----------------------------------------------------------
        Environment.RegisterRuntimeContextKeyword(Class.GetDefinitionContext(), {
            this = function(...)
                local ok, ret           = pcall(getCurrentOverload, 4)
                if ok and ret then
                    return ret(...)
                else
                    error("the keyword \"this\" can't be used here", 2)
                end
            end
        })
    end)

    --- The attribtue used to validate the return values
    __Sealed__() __Final__() __NoRawSet__(false) __NoNilValue__(false)
    class "System.__Return__"           (function(_ENV)
        extend "IInitAttribute"

        --- Enable the attach attribute
        if Platform.ENABLE_RETURN_ATTACHMENT then
            extend "IAttachAttribute"
        end

        export {
            -----------------------------------------------------------
            --                        storage                        --
            -----------------------------------------------------------
            _RetValdMap                 = {},

            -----------------------------------------------------------`
            --                        constant                       --
            -----------------------------------------------------------
            TYPE_VALD_DISD              = Platform.TYPE_VALIDATION_DISABLED,

            FLD_VAR_MINARG              = -1,
            FLD_VAR_MAXARG              = -2,
            FLD_VAR_IMMTBL              = -3,
            FLD_VAR_RETMSG              = -4,
            FLD_VAR_VARVLD              = -5,

            FLG_RET_SNGFMT              = newflags(true),    -- single format
            FLG_RET_NILLST              = newflags(),        -- the list can be nil

            FLG_VAR_ISLIST              = newflags(true),    -- the variable is list
            FLG_VAR_HASTYP              = newflags(),        -- the variable has type
            FLG_VAR_OPTION              = newflags(),        -- the variable is optional
            FLG_VAR_IMMUTE              = newflags(),        -- the variable is immutable

            -----------------------------------------------------------
            --                        helpers                        --
            -----------------------------------------------------------
            serialize                   = serialize,
            combineToken                = combineToken,
            replaceIndex                = replaceIndex,
            parsestack                  = parsestack,
            getcallline                 = getcallline,
            tblclone                    = tblclone,
            validate                    = Struct.ValidateValue,
            geterrmsg                   = Struct.GetErrorMessage,
            ipairs                      = ipairs,
            tinsert                     = tinsert,
            tremove                     = tremove,
            uinsert                     = uinsert,
            tblconcat                   = tblconcat,
            strformat                   = strformat,
            strsub                      = strsub,
            strgsub                     = strgsub,
            type                        = type,
            getmetatable                = getmetatable,
            tostring                    = tostring,
            loadsnippet                 = loadsnippet,
            _Cache                      = _Cache,
            turnonflags                 = turnonflags,
            validateflags               = validateflags,
            parseindex                  = parseindex,
            unpack                      = unpack,
            error                       = error,
            select                      = select,
        }

        export { Namespace, Enum, Struct, Interface, Class, Variables, AttributeTargets, StructCategory }

        local function buildReturn(vars)
            local retmsg                = _Cache()

            tinsert(retmsg, "Return: ")

            if vars[1] then
                for i, var in ipairs, vars, 0 do
                    if i > 1 then tinsert(retmsg, ", ") end

                    if var.optional or (var.varargs and var.mincount == 0) then tinsert(retmsg, "[") end

                    if var.name or var.varargs then
                        tinsert(retmsg, var.varargs and ("..." .. (var.mincount > 1 and (" [*" .. var.mincount .. "]") or "")) or var.name)
                        if var.type then
                            tinsert(retmsg, " as ")
                        end
                    end

                    if var.type then
                        if Struct.Validate(var.type) and Struct.GetStructCategory(var.type) == StructCategory.ARRAY then
                            tinsert(retmsg, "{" .. tostring(Struct.GetArrayElement(var.type)) .. ", ...}")
                        else
                            tinsert(retmsg, tostring(var.type))
                        end
                    end

                    if var.default ~= nil then
                        tinsert(retmsg, " = ")
                        tinsert(retmsg, serialize(var.default, var.type))
                    end

                    if var.optional or (var.varargs and var.mincount == 0) then tinsert(retmsg, "]") end
                end
            else
                tinsert(retmsg, "nil")
            end

            vars[FLD_VAR_RETMSG]        = tblconcat(retmsg, "")
            _Cache(retmsg)
        end

        local function genReturnValid(vars, msghead)
            local len                   = #vars
            if len == 0 then return end

            local tokens                = _Cache()
            local islist                = false

            tokens[1]                   = msghead and FLG_RET_SNGFMT or 0

            for i = 1, len do
                local var               = vars[i]
                local token             = 0

                if var.varargs then
                    token               = turnonflags(FLG_VAR_ISLIST, token)
                    islist              = true

                    if var.mincount == 0 then
                        tokens[1]       = turnonflags(FLG_RET_NILLST, tokens[1])
                    end
                end

                if var.validate then
                    token               = turnonflags(FLG_VAR_HASTYP, token)
                end

                if var.optional then
                    token               = turnonflags(FLG_VAR_OPTION, token)
                end

                if var.immutable then
                    token               = turnonflags(FLG_VAR_IMMUTE, token)
                end

                tokens[i + 1]           = token
            end

            local token                 = combineToken(tokens)
            _Cache(tokens)

            -- Build the validator generator
            if not _RetValdMap[token] then
                local head              = _Cache()
                local body              = _Cache()
                local apis              = _Cache()
                local args              = _Cache()
                local tmps              = _Cache()
                local targs             = args

                uinsert(apis, "type")
                uinsert(apis, "strgsub")
                uinsert(apis, "tostring")

                tinsert(body, "")                       -- remain for shareable upvalues

                for i = 1, len          do args[i] = "v" .. i end

                if msghead then
                    tinsert(body, strformat("return function(usage, %s)", tblconcat(args, ", ")))
                else
                    tinsert(body, strformat("return function(%s)", tblconcat(args, ", ")))
                end

                for i = 1, len          do args[i] = "a" .. i end
                if islist then args[len]= nil end

                args                    = tblconcat(args, ", ") or ""

                local alen              = #args

                if msghead              then uinsert(apis, "error") else tinsert(tmps, "onlyvalid") end
                if alen >0              then tinsert(tmps, args)  end
                if islist               then tinsert(tmps, "...") end

                tinsert(body, strformat([[return function(%s)]], tblconcat(tmps, ", ")))

                tinsert(body, [[local ret, msg, var]])

                for i = 1, islist and (len - 1) or len do
                    local var           = vars[i]
                    tinsert(body, replaceIndex([[var = _vi_]], i))
                    tinsert(body, replaceIndex([[if _ai_ == nil then]], i))

                    if var.optional then
                        tinsert(body, replaceIndex([[_ai_ = var.default]], i))
                    else
                        if msghead then
                            tinsert(body, replaceIndex([[error(usage .. " - the _pi_ return value can't be nil", 0)]], i))
                        else
                            tinsert(body, [[return onlyvalid]])
                        end
                    end

                    if var.validate then
                        if msghead  then
                            tinsert(body, replaceIndex([[
                                else
                                    ret, msg = var.validate(var.type, _ai_)
                                    if msg then error(usage .. " - " .. (type(msg) == "string" and strgsub(msg, "%%s", "_pi_ return value") or ("the _pi_ return value must be " .. tostring(var.type))), 0) end
                                    _ai_ = ret
                                end
                            ]], i))
                        else
                            tinsert(body, replaceIndex([[
                                else
                                    ret, msg = var.validate(var.type, _ai_, onlyvalid)
                                    if msg then return onlyvalid end
                                    _ai_ = ret
                                end
                            ]], i))
                        end
                    else
                        tinsert(body, [[end]])
                    end
                end

                if not islist then
                    if not msghead then
                        tinsert(body, [[if onlyvalid then return end]])
                    end
                    tinsert(body, strformat([[return %s]], args))
                else
                    tinsert(body, replaceIndex([[var = _vi_]], len))
                    if vars[len].mincount > 0 then tinsert(body, [[local varminct = var.mincount]]) end
                    if vars[len].validate then tinsert(body, [[local varvalid, vartype = var.validate, var.type]]) end
                    if vars[len].immutable then
                        if vars[len].mincount > 0 or vars[len].validate then
                            uinsert(apis, "select")
                            if msghead then uinsert(apis, "parseindex") end

                            tinsert(body, [[local vlen = select("#", ...)]])

                            if vars[len].mincount > 0 then
                                if msghead then
                                    tinsert(body, replaceIndex([[if vlen < varminct then error(usage .. " - " .. "the ... must contains at least " .. varminct .. " return values", 0) end]], len))
                                else
                                    tinsert(body, replaceIndex([[if vlen < varminct then return onlyvalid end]], len))
                                end
                            end

                            tinsert(body, [[
                                for i = 1, vlen do
                                    local ival = select(i, ...)
                                    if ival == nil then
                            ]])

                            if vars[len].mincount > 0 then
                                if msghead then
                                    tinsert(body, replaceIndex([[if i <= varminct then error(usage .. " - " .. ("the " .. parseindex(i - 1 + _i_) .. " return value can't be nil"), 0) end]], len))
                                else
                                    tinsert(body, replaceIndex([[if i <= varminct then return onlyvalid end]], len))
                                end
                            end
                            tinsert(body, [[break]])
                            if vars[len].validate then
                                if msghead then
                                    tinsert(body, replaceIndex([[
                                        else
                                            ret, msg= varvalid(vartype, ival)
                                            if msg then error(usage .. " - " .. (type(msg) == "string" and strgsub(msg, "%%s", parseindex(i - 1 + _i_) .. " return value") or ("the " .. parseindex(i - 1 + _i_) .. " return value must be " .. tostring(vartype))), 0) end
                                   ]], len))
                                else
                                    tinsert(body, replaceIndex([[
                                        else
                                            ret, msg= varvalid(vartype, ival, onlyvalid)
                                            if msg then return onlyvalid end
                                   ]], len))
                                end
                            end
                            tinsert(body, [[
                                    end
                                end
                            ]])
                        end

                        if not msghead then tinsert(body, [[if onlyvalid then return end]]) end

                        if alen == 0 then
                            tinsert(body, [[return ...]])
                        else
                            tinsert(body, strformat([[return %s, ...]], args))
                        end
                    else
                        uinsert(apis, "select")
                        uinsert(apis, "unpack")
                        if msghead then uinsert(apis, "parseindex") end

                        tinsert(body, [[local vlen = select("#", ...)]])

                        if vars[len].mincount > 0 then
                            if msghead then
                                tinsert(body, replaceIndex([[if vlen < varminct then error(usage .. " - " .. "the ... must contains at least " .. varminct .. " return values", 0) end]], len))
                            else
                                tinsert(body, replaceIndex([[if vlen < varminct then return onlyvalid end]], len))
                            end
                        end

                        if msghead then
                            tinsert(body, replaceIndex(([[
                                if vlen > 0 then
                                    local vlst  = { ... }
                                    for i = 1, vlen do
                                        local ival = vlst[i]
                                        if ival == nil then]] .. (vars[len].mincount > 0 and [[
                                            if i <= varminct then error(usage .. " - " .. ("the " .. parseindex(i - 1 + _i_) .. " return value can't be nil"), 0) end]] or "") .. [[
                                            break
                                        else
                                            ret, msg= varvalid(vartype, ival)
                                            if msg then error(usage .. " - " .. (type(msg) == "string" and strgsub(msg, "%%s", parseindex(i - 1 + _i_) .. " return value") or ("the " .. parseindex(i + _i_) .. " return value must be " .. tostring(vartype))), 0) end
                                            vlst[i] = ret
                                        end
                                    end
                                    ]] .. (alen == 0 and [[return unpack(vlst)]] or [[return _arg_, unpack(vlst)]]) .. [[
                                else
                                    return _arg_
                                end
                            ]]):gsub("_arg_", args), len))
                        else
                            tinsert(body, replaceIndex(([[
                                if vlen > 0 then
                                    if onlyvalid then
                                        for i = 1, vlen do
                                            local ival = select(i, ...)
                                            if ival == nil then]] .. (vars[len].mincount > 0 and [[
                                                if i <= varminct then return onlyvalid end]] or "") .. [[
                                                break
                                            else
                                                ret, msg= varvalid(vartype, ival, onlyvalid)
                                                if msg then return onlyvalid end
                                            end
                                        end
                                        return
                                    else
                                        local vlst  = { ... }
                                        for i = 1, vlen do
                                            local ival = vlst[i]
                                            if ival == nil then
                                                break
                                            else
                                                vlst[i] = varvalid(vartype, ival)
                                            end
                                        end
                                        ]] .. (alen == 0 and [[return unpack(vlst)]] or [[return _arg_, unpack(vlst)]]) .. [[
                                    end
                                else
                                    if onlyvalid then return end
                                    return _arg_
                                end
                            ]]):gsub("_arg_", args), len))
                        end
                    end
                end

                tinsert(body, [[
                        end
                    end
                ]])

                if #apis > 0 then
                    local declare       = tblconcat(apis, ", ")
                    body[1]             = strformat("local %s = %s", declare, declare)
                end

                _RetValdMap[token]      = loadsnippet(tblconcat(body, "\n"), "Return_Validate_" .. token, _ENV)()

                _Cache(head) _Cache(body) _Cache(apis) _Cache(tmps) _Cache(targs)
            end

            if msghead then
                vars[FLD_VAR_VARVLD]        = _RetValdMap[token](msghead .. " " .. vars[FLD_VAR_RETMSG], unpack(vars, 1))
            else
                vars[FLD_VAR_VARVLD]        = _RetValdMap[token](unpack(vars, 1))
            end
        end

        local function genReturns(retsets, msghead)
            local count                     = #retsets

            local usages                    = { msghead .. " should return:" }
            for i = 1, #retsets do usages[i + 1] = retsets[i][FLD_VAR_RETMSG] end
            usages                          = tblconcat(usages, "\n    ")

            return function(...)
                local argcnt                = select("#", ...)
                while argcnt > 0 and select(argcnt, ...) == nil do
                    argcnt                  = argcnt - 1
                end
                if argcnt == 0 then
                    for i = 1, count do
                        local vars          = retsets[i]
                        if vars[FLD_VAR_MINARG] == 0 then
                            if vars[FLD_VAR_IMMTBL] then
                                return ...
                            else
                                return vars[FLD_VAR_VARVLD](nil, ...)
                            end
                        end
                    end
                else
                    for i = 1, count do
                        local vars          = retsets[i]
                        if vars[FLD_VAR_MINARG] <= argcnt and argcnt <= vars[FLD_VAR_MAXARG] then
                            local valid     = vars[FLD_VAR_VARVLD]

                            if valid(true, ...) == nil then
                                if vars[FLD_VAR_IMMTBL] then
                                    return ...
                                else
                                    return valid(nil, ...)
                                end
                            end
                        end
                    end
                end
                -- Raise the usages
                error(usages, 0)
            end
        end

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- modify the target's definition
        -- @param   target                      the target
        -- @param   targettype                  the target type
        -- @param   definition                  the target's definition
        -- @param   owner                       the target's owner
        -- @param   name                        the target's name in the owner
        -- @param   stack                       the stack level
        -- @return  definition                  the new definition
        function InitDefinition(self, target, targettype, definition, owner, name, stack)
            stack                       = parsestack(stack) + 1

            local retsets               = {}
            local isAllImmutable        = true
            local defplace              = getcallline(stack) or ""
            local nomulti               = #self == 1
            local msghead

            if defplace ~= "" then defplace = defplace:sub(2, -1) .. ": " end

            if targettype == AttributeTargets.Method then
                msghead                 = strformat("The %s.%s", tostring(owner), name)
            elseif targettype == AttributeTargets.Function then
                msghead                 = strformat("The %s", name)
            end

            for i, varset in ipairs, self, 0 do
                local len               = #varset

                local vars              = {
                    [FLD_VAR_MINARG]    = len,
                    [FLD_VAR_MAXARG]    = len,
                    [FLD_VAR_IMMTBL]    = true,
                    [FLD_VAR_RETMSG]    = "",
                    [FLD_VAR_VARVLD]    = false,
                }

                retsets[i]              = vars

                local minargs
                local immutable         = true

                for i = 1, len do
                    local var           = varset[i]
                    vars[i]             = var

                    if var.optional then
                        minargs         = minargs or i - 1
                    end

                    if var.varargs then
                        vars[FLD_VAR_MAXARG] = 255

                        if not var.mincount or var.mincount == 0 then
                            minargs     = minargs or i - 1
                        else
                            minargs     = i + var.mincount - 1
                        end
                    end

                    if not var.immutable then
                        immutable       = false
                    end
                end

                vars[FLD_VAR_MINARG]    = minargs or vars[FLD_VAR_MINARG]
                vars[FLD_VAR_IMMTBL]    = immutable

                if not immutable then isAllImmutable = false end
            end

            if TYPE_VALD_DISD and isAllImmutable then return end

            for _, vars in ipairs, retsets, 0 do
                buildReturn(vars)
                if nomulti then
                    genReturnValid(vars, defplace .. msghead)
                else
                    genReturnValid(vars)
                end
            end

            local validrets             = not nomulti and genReturns(retsets, defplace .. msghead) or retsets[1][FLD_VAR_VARVLD]
            if validrets then return function(...) return validrets(definition(...)) end end
        end


        if Platform.ENABLE_RETURN_ATTACHMENT then
            --- attach attribute
            -- @param target                    the target
            -- @param targettype                the target type
            -- @param owner                     the target's owner
            -- @param name                      the target's name in the owner
            -- @param stack                     the stack level
            function AttachAttribute(self, target, targettype, owner, name, stack)
                return { unpack(self) }
            end
        end

        -----------------------------------------------------------
        --                       property                       --
        -----------------------------------------------------------
        --- the attribute target
        property "AttributeTarget"      { type = AttributeTargets,  default = AttributeTargets.Method + AttributeTargets.Function  }

        --- the attribute's priority
        property "Priority"             { type = AttributePriority, default = AttributePriority.Lowest }

        --- the attribute's sub level of priority
        property "SubLevel"             { type = Number,            default = -9999 }

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        function __new(_, vars, ...)
            if vars ~= nil then
                if select("#", ...) > 0 then
                    vars                = { vars, ... }
                elseif getmetatable(vars) ~= nil then
                    vars                = { vars }
                end

                local ret, msg          = validate(Variables, vars)
                if msg then throw("Usage: __Return__{ ... } - " .. geterrmsg(msg, "")) end
            else
                vars                    = {}
            end

            return { vars }, true
        end

        -----------------------------------------------------------
        --                      meta-method                      --
        -----------------------------------------------------------
        function __call(self, vars, ...)
            if vars ~= nil then
                if select("#", ...) > 0 then
                    vars                = { vars, ... }
                elseif getmetatable(vars) ~= nil then
                    vars                = { vars }
                end

                local ret, msg          = validate(Variables, vars)
                if msg then throw("Usage: __Return__{ ... }{...} - " .. geterrmsg(msg, "")) end
            else
                vars                    = {}
            end

            self[#self + 1]             = vars
        end
    end)

    --- Represents containers of several functions as event handlers
    __Sealed__() __Final__() __NoRawSet__(false) __NoNilValue__(false)
    class "System.Delegate"             (function(_ENV)
        event "OnChange"

        -----------------------------------------------------------
        --                        helpers                        --
        -----------------------------------------------------------
        export {
            tinsert                     = tinsert,
            tremove                     = tremove,
            ipairs                      = ipairs,
            ATTRTAR_FUNCTION            = AttributeTargets.Function,

            Attribute
        }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- Copy the handlers to the target delegate
        -- @param   target                      the target delegate
        __Arguments__{ Delegate }
        function CopyTo(self, target)
            local len                   = #self
            for i = -1, len do target[i]= self[i] end
            for i = len + 1, #target    do target[i] = nil end
        end

        --- Invoke the handlers with arguments
        -- @param   ...                         the arguments
        function Invoke(self, ...)
            -- Any func return true means to stop all
            if self[0] and self[0](...) then return end

            -- Call the stacked handlers
            for i = 1, #self do
                local func              = self[i]
                if func and func(...) then return end
            end

            -- Call the final func
            return self[-1] and self[-1](...)
        end

        --- Whether the delegate has no handler
        -- @return  boolean                     true if no handler in the delegate
        function IsEmpty(self)
            for i = -1, #self do
                if self[i] then return false end
            end
            return true
        end

        --- Set the init function to the delegate
        -- @param   init                        the init function
        __Arguments__{ Function/nil }
        function SetInitFunction(self, func)
            func                        = func or false
            if self[0] ~= func then
                self[0]                 = func
                return OnChange(self)
            end
        end

        --- Set the final function to the delegate
        -- @param   final                       the final function
        __Arguments__{ Function/nil }
        function SetFinalFunction(self, func)
            func                        = func or false
            if self[-1] ~= func then
                self[-1]                = func
                return OnChange(self)
            end
        end

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- The delegate's owner
        property "Owner"                { type = Table + Userdata }

        --- The delegate's name
        property "Name"                 { type = String }

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{ Variable("owner", Table + Userdata, true), Variable("name", String, true) }
        function Delegate(self, owner, name)
            self.Owner                  = owner
            self.Name                   = name
        end

        -----------------------------------------------------------
        --                       meta-data                       --
        -----------------------------------------------------------
        field { [-1] = false, [0] = false }

        --- Use to add stackable handler to the delegate
        -- @usage   obj.OnEvent = obj.OnEvent + func
        __Arguments__{ Function }
        function __add(self, func)
            if Attribute.HaveRegisteredAttributes() then
                local owner             = self.Owner
                local name              = self.Name

                Attribute.SaveAttributes(func, ATTRTAR_FUNCTION, 2)
                local ret               = Attribute.InitDefinition(func, ATTRTAR_FUNCTION, func, owner, name, 2)
                if ret ~= func then
                    Attribute.ToggleTarget(func, ret)
                    func                = ret
                end
                Attribute.ApplyAttributes (func, ATTRTAR_FUNCTION, nil, owner, name, 2)
                Attribute.AttachAttributes(func, ATTRTAR_FUNCTION, owner, name, 2)
            end

            local slot

            for i = 1, #self do
                local f                 = self[i]
                if not f then
                    slot                = i
                elseif f == func then
                    return self
                end
            end

            if slot then
                self[slot]              = func
            else
                tinsert(self, func)
            end

            OnChange(self)
            return self
        end

        --- Use to remove stackable handler from the delegate
        -- @usage   obj.OnEvent = obj.OnEvent - func
        __Arguments__{ Function }
        function __sub(self, func)
            for i = 1, #self do
                if self[i] == func then
                    self[i]             = false
                    OnChange(self)
                    break
                end
            end
            return self
        end

        -- Invoke the delegate
        __call                          = Invoke
    end)

    --- Wrap the target function within the given function like pcall
    __Sealed__() __Final__()
    class "System.__Delegate__"         (function(_ENV)
        extend "IInitAttribute"

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- modify the target's definition
        -- @param   target                      the target
        -- @param   targettype                  the target type
        -- @param   definition                  the target's definition
        -- @param   owner                       the target's owner
        -- @param   name                        the target's name in the owner
        -- @param   stack                       the stack level
        -- @return  definition                  the new definition
        function InitDefinition(self, target, targettype, definition, owner, name, stack)
            local wrap          = self[1]
            return function(...) return wrap(target, ...) end
        end

        -----------------------------------------------------------
        --                       property                       --
        -----------------------------------------------------------
        --- the attribute target
        property "AttributeTarget"      { type = AttributeTargets,  default = AttributeTargets.Method + AttributeTargets.Function }

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__ { Function }
        function __new(_, func) return { func } end
    end)

    --- Represents errors that occur during application execution
    __Sealed__()
    class "System.Exception"            (function(_ENV)
        -----------------------------------------------------------
        --                       property                       --
        -----------------------------------------------------------
        --- a message that describes the current exception
        __Abstract__()
        property "Message"              { type = String, default = "There is an exception occurred" }

        --- The error code
        __Abstract__()
        property "Code"                 { type = Number }

        --- a string representation of the immediate frames on the call stack
        __Abstract__()
        property "StackTrace"           { type = String }

        --- the method that throws the current exception
        __Abstract__()
        property "TargetSite"           { type = String }

        --- the source of the exception
        __Abstract__()
        property "Source"               { type = String }

        --- the Exception instance that caused the current exception
        __Abstract__()
        property "InnerException"       { type = Exception }

        --- key/value pairs that provide additional information about the exception
        __Abstract__()
        property "Data"                 { type = Table }

        --- key/value pairs of the local variable
        __Abstract__()
        property "LocalVariables"       { type = Table }

        --- key/value pairs of the upvalues
        __Abstract__()
        property "Upvalues"             { type = Table }

        --- whether the stack data is saved, the system will save the stack data
        -- if the value is false when the exception is thrown out
        __Abstract__()
        property "StackDataSaved"       { type = Boolean,       default = not Platform.EXCEPTION_SAVE_STACK_DATA }

        --- the stack level to be scanned, default 1, where the throw is called
        __Abstract__()
        property "StackLevel"           { type = NaturalNumber, default = 1 }

        --- whether save the local variables and the upvalues for the exception
        __Abstract__()
        property "SaveVariables"        { type = Boolean,       default = Platform.EXCEPTION_SAVE_VARIABLES }

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{ Variable("message", String, true), Variable("code", Number, true), Variable("inner", Exception, true), Variable("savevariables", Boolean, true) }
        function Exception(self, message, code, inner, savevariables)
            self.Message                = message
            self.Code                   = code
            self.InnerException         = inner
            self.SaveVariables          = savevariables
        end

        -----------------------------------------------------------
        --                      meta-method                      --
        -----------------------------------------------------------
        function __tostring(self) return self.Message end
    end)

    --- Represents the tree containers for codes, it's the recommended
    -- environment for coding with PLoop
    __Sealed__()
    class "System.Module"               (function(_ENV)
        extend "IEnvironment"

        export {
            rawget                      = rawget,
            rawset                      = rawset,
            savestorage                 = savestorage,
            type                        = type,
            strgsub                     = strgsub,
            strgmatch                   = strgmatch,
            strmatch                    = strmatch,
            fakefunc                    = fakefunc,
            wipe                        = wipe,
            pairs                       = pairs,
            getmetatable                = getmetatable,
            strtrim                     = strtrim,
            tonumber                    = tonumber,
            error                       = error,
            GetObjectSource             = Class.GetObjectSource,
            tostring                    = tostring,
        }

        export { Environment }

        -----------------------------------------------------------
        --                        storage                        --
        -----------------------------------------------------------
        local _ModuleInfo               = Platform.UNSAFE_MODE and setmetatable({}, { __index = function(_, mdl) return type(mdl) == "table" and rawget(mdl, FLD_MDL_INFO) or nil end }) or {}

        -----------------------------------------------------------
        --                        constant                       --
        -----------------------------------------------------------
        export {
            FLD_MDL_CHILD               = 0,
            FLD_MDL_NAME                = 1,
            FLD_MDL_FULLNAME            = 2,
            FLD_MDL_VER                 = 3,

            FLD_MDL_INFO                = "__PLOOP_MODULE_META",
        }

        -----------------------------------------------------------
        --                        helpers                        --
        -----------------------------------------------------------
        local saveModuleInfo            = Platform.UNSAFE_MODE and function(mdl, info) rawset(mdl, FLD_MDL_INFO, info) end or function(mdl, info) _ModuleInfo = savestorage(_ModuleInfo, mdl, info) end

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- Valiate the version if it's bigger than the current version of the module
        -- @param   version:string                  the new version
        -- @return  boolean                         true if the new version is bigger
        __Arguments__{ String }
        function ValidateVersion(self, version)
            local info                  = _ModuleInfo[self]
            if info then
                local oldver            = info[FLD_MDL_VER]
                if not oldver then return true end

                -- "a 1.0.0" < "b 1.0.0" < "v 1.0.0" < "r 1.0.0" < "r 1.1"
                local oprefix           = strmatch(oldver, "^%D+")
                local nprefix           = strmatch(version, "^%D+")

                if oprefix ~= nprefix then
                    if not oprefix then return true end
                    if not nprefix then return false end
                    return oprefix < nprefix
                end

                local onums             = strmatch(oldver, "%d+[%d%.]*")
                local nnums             = strmatch(version, "%d+[%d%.]*")
                if not onums then return nnums and true or false end
                if not nnums then return false end

                local f1                = strgmatch(onums .. ".", "(.-)%.")
                local f2                = strgmatch(nnums .. ".", "(.-)%.")

                local v1                = f1 and f1()
                local v2                = f2 and f2()

                while true do
                    v1                  = tonumber(v1)
                    v2                  = tonumber(v2)

                    if not v1 then
                        return v2 and true or false
                    elseif not v2 then
                        return false
                    elseif v1 < v2 then
                        return true
                    elseif v1 > v2 then
                        return false
                    end

                    v1                  = f1()
                    v2                  = f2()
                end
            end
            return false
        end

        --- Get all child modules
        -- @param   cache                           whether save the result in cache
        -- @rformat cache                           if save the result in cache
        -- @rformat iterator                        if not save to cache
        function GetModules(self, cache)
            local info                  = _ModuleInfo[self]
            local child                 = info and info[FLD_MDL_CHILD]
            if child then
                if cache then
                    cache               = type(cache) == "table" and wipe(cache) or {}
                    for k, v in pairs, child do cache[k] = v end
                    return cache
                else
                    return function(self, n)
                        return next(child, n)
                    end, self
                end
            end
            if cache then
                return type(cache) == "table" and cache or nil
            else
                return fakefunc, self
            end
        end

        -----------------------------------------------------------
        --                       property                       --
        -----------------------------------------------------------
        --- the module itself
        property "_M"                   { get = function(self) return self end }

        --- the module's parent environment
        property "_Parent"              { get = Environment.GetParent }

        --- the module name
        property "_Name"                { get = function(self) return _ModuleInfo[self][FLD_MDL_NAME] end }

        --- the module full name
        property "_FullName"            { get = function(self) return _ModuleInfo[self][FLD_MDL_FULLNAME] end}

        --- the module version
        property "_Version"             { get = function(self) return _ModuleInfo[self][FLD_MDL_VER] or nil end }

        --- the sub-modules
        __Indexer__()
        property "_Modules"             { get = function(self, name) local child = _ModuleInfo[self][FLD_MDL_CHILD] return child and child[name] end }

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{ Variable("name", NEString), Variable("parent", Module, true) }
        function __exist(cls, path, root)
            root                        = root or cls
            path                        = strgsub(path, "%s+", "")
            local iter                  = strgmatch(path, "[%P_]+")
            local subname               = iter()

            while subname do
                local info              = _ModuleInfo[root]
                if not info then return end
                local child             = info[FLD_MDL_CHILD]
                if not child or not child[subname] then return end
                root                    = child[subname]
                local nxt               = iter()
                if not nxt then return root end
                subname                 = nxt
            end
        end

        function Module(self, path, root)
            local cls                   = getmetatable(self)
            root                        = root or cls
            if not _ModuleInfo[root] then
                saveModuleInfo(root, { [FLD_MDL_CHILD] = false })
            end

            path                        = strgsub(path, "%s+", "")
            local iter                  = strgmatch(path, "[%P_]+")
            local subname               = iter()

            while subname do
                local nxt               = iter()
                if not nxt then break end
                if cls == root then
                    root                = cls(subname)
                else
                    root                = cls(subname, root)
                end
                subname                 = nxt
            end

            _ModuleInfo[root][FLD_MDL_CHILD] = savestorage(_ModuleInfo[root][FLD_MDL_CHILD] or {}, subname, self)

            local fullname              = _ModuleInfo[root][FLD_MDL_FULLNAME]

            saveModuleInfo(self, {
                [FLD_MDL_CHILD]         = false,
                [FLD_MDL_NAME]          = subname,
                [FLD_MDL_FULLNAME]      = (fullname and fullname .. "." or "") .. subname,
                [FLD_MDL_VER]           = false,
            })

            Environment.Initialize(self)

            if root ~= cls then
                Environment.SetParent(self, root)
                Environment.SetNamespace(self, Environment.GetNamespace(root))
            end
        end

        -----------------------------------------------------------
        --                      meta-method                      --
        -----------------------------------------------------------
        --- _ENV = Module "TestCode" "v1.0.0"
        function __call(self, version, stack)
            stack = type(stack) == "number" and stack or 1
            local tver                  = type(version)
            if tver == "string" then
                if self:ValidateVersion(version) then
                    version             = strtrim(version)
                    _ModuleInfo[self][FLD_MDL_VER] = version ~= "" and version or false
                    Environment.Apply(self, stack + 1)
                else
                    error("there is an equal or bigger version existed", stack + 1)
                end
            elseif tver == "function" then
                Environment.Apply(self, version)
            elseif version == nil or tver == "number" then
                Environment.Apply(self, (version or stack) + 1)
            end
            return self
        end

        function __tostring(self)
            return "[" .. tostring(getmetatable(self)) .. "]" .. self._FullName .. (GetObjectSource(self) or "")
        end
    end)

    -----------------------------------------------------------------------
    --                              context                              --
    -----------------------------------------------------------------------
    interface "System.IContext"         {}

    --- Represents the context object used to process the operations in an
    -- os thread, normally used in multi-os thread platforms
    __Sealed__() __NoNilValue__(false):AsInheritable() __NoRawSet__(false):AsInheritable()
    class "System.Context"              (function(_ENV)
        export {
            getlocal                    = getlocal,
            getobjectclass              = Class.GetObjectClass,
            isclass                     = Class.IsSubType,
            isinterface                 = Interface.IsSubType,
            pcall                       = pcall,

            Context, IContext
        }

        local customGetContext          = fakefunc
        local customSaveContext         = fakefunc

        local getStackContext           = getlocal and function(stack)
            local n, v                  = getlocal(stack, 1)

            while true do
                local cls               = getobjectclass(v)
                if cls then
                    if isclass(cls, Context) then
                        return v
                    elseif isinterface(cls, IContext) then
                        return v.Context
                    end
                end

                stack                   = stack + 1
                n, v                    = getlocal(stack, 1)
            end
        end or fakefunc

        local getCurrentContext         = function()
            local context               = customGetContext()
            if context then return context end

            local ok, ret               = pcall(getStackContext, 4)
            return ok and ret or nil
        end

        -----------------------------------------------------------
        --                   static property                     --
        -----------------------------------------------------------
        --- The API used to save the current context
        __Static__() property "SaveCurrentContext" {
            type                        = Function,
            set                         = function(_, func) customSaveContext = func end,
            get                         = function() return customSaveContext end,
            require                     = true,
        }

        --- The API used to get the current context
        __Static__() property "GetCurrentContext" {
            type                        = Function,
            set                         = function(_, func) customGetContext = func end,
            get                         = function() return getCurrentContext end,
            require                     = true,
        }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- Process the operations under the context
        __Abstract__() function Process(self) end

        -----------------------------------------------------------
        --                      initializer                      --
        -----------------------------------------------------------
        __Sealed__()
        local contextSaver              = interface { __init = function(self) return customSaveContext(self) end }
        extend (contextSaver)
    end)

    --- Represents the interface of thread related context, which will
    -- cache all sharable datas in the same os-thread
    __Sealed__()
    interface "System.IContext"         (function(_ENV)
        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        property "Context"              { type = Context }

        -----------------------------------------------------------
        --                      initializer                      --
        -----------------------------------------------------------
        if Platform.ENABLE_CONTEXT_FEATURES then
            export { getcontext         = Context.GetCurrentContext }

            function IContext(self)
                self.Context            = self.Context or getcontext()
            end
        end
    end)

    -----------------------------------------------------------------------
    --                             runtime                              --
    -----------------------------------------------------------------------
    --- Represents the informations of the runtime
    __Final__() __Sealed__() __Abstract__()
    class "System.Runtime"              (function(_ENV)
        export{ Enum, Struct, Class, Interface, __Arguments__ }

        --- Fired when a new type is generated
        __Static__() event "OnTypeDefined"

        _PLoopEnv.enumdefined           = function(target) OnTypeDefined(Enum, target) end
        _PLoopEnv.structdefined         = function(target) __Arguments__.ClearOverloads(target) return OnTypeDefined(Struct, target) end
        _PLoopEnv.interfacedefined      = function(target) __Arguments__.ClearOverloads(target) return OnTypeDefined(Interface, target) end
        _PLoopEnv.classdefined          = function(target) __Arguments__.ClearOverloads(target) return OnTypeDefined(Class, target) end
    end)
end

-------------------------------------------------------------------------------
--                              _G installation                              --
-------------------------------------------------------------------------------
do
    safesetfenv                         = PLOOP_PLATFORM_SETTINGS.TYPE_DEFINITION_WITH_OLD_STYLE and setfenv or fakefunc

    -----------------------------------------------------------------------
    --                            _G keyword                             --
    -----------------------------------------------------------------------
    _G.prototype                        = _G.prototype  or prototype
    _G.namespace                        = _G.namespace  or namespace
    _G.import                           = _G.import     or import
    _G.enum                             = _G.enum       or enum
    _G.struct                           = _G.struct     or struct
    _G.class                            = _G.class      or class
    _G.interface                        = _G.interface  or interface
    _G.Module                           = _G.Module     or Module

    -----------------------------------------------------------------------
    --                             Must Have                             --
    -----------------------------------------------------------------------
    _G.PLoop                            = ROOT_NAMESPACE
end

return ROOT_NAMESPACE