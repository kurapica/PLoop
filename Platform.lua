--===========================================================================--
--                                                                           --
--                        Prototype Platform Settings                        --
--                                                                           --
--===========================================================================--

PLOOP_PLATFORM_SETTINGS = PLOOP_PLATFORM_SETTINGS or {
    -- ==Attribute==
    -- Whether the attribute system use warning instead of error for invalid attribtue target type.
    ATTR_USE_WARN_INSTEAD_ERROR = false,

    -- ==Environment==
    -- Whether the environmet allow global variable be nil, if false, things like ture(spell error)
    -- could be notified, but it require more usage of pcall and error.
    ENV_ALLOW_GLOBAL_VAR_BE_NIL = true,

    -- ==Enum==
    -- Whether all enumerations are case ignored.
    ENUM_GLOBAL_IGNORE_CASE     = false,

    -- ==Struct==

    -- ==Interface X Class X Object==
    -- Whether all old objects keep using new features when their classes or extend interfaces are re-defined.
    CLASS_ALL_SIMPLE_VERSION    = false,

    -- Whether all interfaces & classes only use Super.Method(obj, ...) to call super's features, don't use new
    -- style like :
    --              Super[obj].Name = "Ann"
    --              Super[obj].OnNameChanged = Super[obj].OnNameChanged + print
    --              Super[obj]:Greet("King")
    CLASS_ALL_OLD_SUPER_STYLE   = false,

    -- ==Log==
    -- The Log level used in the Prototype core part.
    --          1 : Trace
    --          2 : Debug
    --          3 : Info
    --          4 : Warn
    --          5 : Error
    --          6 : Fatal
    CORE_LOG_LEVEL      = 3,

    --  The core log handler, default print.
    --      function CORE_LOG_HANDLER(message, loglevel)
    --          -- message  : the log message
    --          -- loglevel : the log message's level
    --      end
    CORE_LOG_HANDLER    = print,

    -- ==Multi-thread==
    -- Whether the system is used in a platform where multi os threads share one lua-state,
    -- so the access conflict can't be ignore.
    MULTI_OS_THREAD     = false,

    -- The API provided by platform so PLoop can use it to void access conflict, only work ,
    -- when MULTI_OS_THREAD is true.
    --      function MULTI_OS_LOCK(key[, expiration[, timeout]])
    --          -- key          : The lock's key, normally special object
    --          -- expiration   : The expiration time of the lock
    --          -- timeout      : The waiting time of the lock, if 0 then it
    --                              won't wait to get the lock.
    --          return result, errormsg
    --          -- result       : false or nil if failed, true or other value
    --                              means success, the result would be used
    --                              in release.
    --          -- errormsg     : the error message if lock failed.
    --      end
    MULTI_OS_LOCK       = nil,

    -- The API provided by platform used to release the lock, only work when MULTI_OS_THREAD is true.                              --
    --      function MULTI_OS_RELEASE(key, lockresult)
    --          -- key          : The lock's key
    --          -- lockresult   : The result of the lock
    --          return result, errormsg
    --          -- result       : false or nil if failed, other success.
    --          -- errormsg     : The error message if release failed.
    --      end
    MULTI_OS_RELEASE    = nil,
}