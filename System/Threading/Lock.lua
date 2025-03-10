--===========================================================================--
--                                                                           --
--                           System.Threading Lock                           --
--                                                                           --
--===========================================================================--


--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2013/08/13                                               --
-- Update Date  :   2020/06/25                                               --
-- Version      :   1.1.2                                                    --
--===========================================================================--
PLoop(function(_ENV)
	namespace "System.Threading"

    --- represent an interface for lock manager
    __Sealed__() __AnonymousClass__()
    interface "ILockManager"        (function(_ENV)

        export                      {
            GetContext              = Context.GetCurrentContext,
            fakeobj                 = {},
            error                   = error,
            tostring                = tostring,
            pcall                   = pcall,

            ILockManager,
        }

        local function releaseLock(manager, context, key, obj, result, ...)
            if context and context[ILockManager] then
                context[ILockManager][key] = nil
            end

            local ok, err           = manager:Release(obj, key)

            if not result then error(..., 0) end

            if not ok then
                return error("Usage: ILockManager:Release(lockobj, key) - Release key failed:" .. tostring(err))
            end

            return ...
        end

        -----------------------------------------------------------------------
        --                          static property                          --
        -----------------------------------------------------------------------
        --- the unique lock manager
        __Static__()
        property "Manager"          { type = ILockManager, handler = function(self, new, old) if old then old:Dispose() end end, default = function() return ILockManager() end }

        -----------------------------------------------------------------------
        --                           static method                           --
        -----------------------------------------------------------------------
        --- Lock with a key and process the target function
        -- @param   key             the lock key
        -- @param   func            the function
        -- @param   ...             the function arguments
        __Static__()
        function RunWithLock(key, func, ...)
            local context           = GetContext()
            if context and context[ILockManager] and context[ILockManager][key] then
                -- Already locked, continue job
                return func(...)
            end

            local manager           = ILockManager.Manager

            -- lock the key
            local lockObj, err      = manager:Lock(key)
            if not lockObj then
                return error("Usage: ILockManager:Lock(key) - Lock key failed:" .. tostring(err))
            end

            if context then
                context[ILockManager] = context[ILockManager] or {}
                context[ILockManager][key] = true
            end

            return releaseLock(manager, context, key, lockObj, pcall(func, ...))
        end

        --- Try lock with a key and process the target function
        -- @param   key             the lock key
        -- @param   func            the function
        -- @param   ...             the function arguments
        __Static__()
        function TryRunWithLock(key, func, ...)
            local context           = GetContext()
            if context and context[ILockManager] and context[ILockManager][key] then
                -- Already locked, continue job
                return func(...)
            end

            local manager           = ILockManager.Manager

            -- lock the key
            local lockObj, err      = manager:TryLock(key)
            if not lockObj then return end

            if context then
                context[ILockManager] = context[ILockManager] or {}
                context[ILockManager][key] = true
            end

            return releaseLock(manager, context, key, lockObj, pcall(func, ...))
        end

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        --- Lock with a key and return a lock object to release
        -- @param   key             the lock key
        -- @return  object          the lock object
        -- @return  error           the error message if failed
        __Abstract__()
        function Lock(self, key)
            return fakeobj
        end

        --- Try lock with a key and return a lock object to release
        -- @param   key             the lock key
        -- @return  object          the lock object
        -- @return  message         the error message if failed
        __Abstract__()
        function TryLock(self, key)
            return fakeobj
        end

        --- Release the lock object
        -- @param   object          the lock object
        -- @param   key             the lock key
        -- @return  bool            true if released
        -- @return  message         the error message if failed
        __Abstract__()
        function Release(self, obj, key)
            return true
        end

        -----------------------------------------------------------------------
        --                           initializer                            --
        -----------------------------------------------------------------------
        function __init(self)
            ILockManager.Manager    = self
        end
    end)

    --- specify a method or function to run with a lock key
    __Sealed__() __Final__()
    class "__Lock__"                (function(_ENV)
        extend "IInitAttribute"

        export { RunWithLock        = ILockManager.RunWithLock }

        local wraptarget            = Platform.ENABLE_THREAD_LOCK and function(target, key) return function(...) return RunWithLock(key, target, ...) end end or Toolset.fakefunc

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- modify the target's definition
        -- @param   target          the target
        -- @param   targettype      the target type
        -- @param   definition      the target's definition
        -- @param   owner           the target's owner
        -- @param   name            the target's name in the owner
        -- @param   stack           the stack level
        -- @return  definition      the new definition
        function InitDefinition(self, target, targettype, definition, owner, name, stack)
            return wraptarget(definition, self[1])
        end

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- the attribute target
        property "AttributeTarget"  { type = AttributeTargets,  default = AttributeTargets.Method + AttributeTargets.Function }

        --- the attribute's priority
        property "Priority"         { type = AttributePriority, default = AttributePriority.Lower }

        -----------------------------------------------------------
        --                     constructor                       --
        -----------------------------------------------------------
        __Arguments__{ Any }
        function __new(_, key)
            return { key }
        end
    end)

    --- specify a method or function to run with a lock key
    __Sealed__() __Final__()
    class "__TryLock__"             (function(_ENV)
        extend "IInitAttribute"

        export { TryRunWithLock     = ILockManager.TryRunWithLock }

        local wraptarget            = Platform.ENABLE_THREAD_LOCK and function(target, key) return function(...) return TryRunWithLock(key, target, ...) end end or Toolset.fakefunc

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- modify the target's definition
        -- @param   target          the target
        -- @param   targettype      the target type
        -- @param   definition      the target's definition
        -- @param   owner           the target's owner
        -- @param   name            the target's name in the owner
        -- @param   stack           the stack level
        -- @return  definition      the new definition
        function InitDefinition(self, target, targettype, definition, owner, name, stack)
            return wraptarget(definition, self[1])
        end

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- the attribute target
        property "AttributeTarget"  { type = AttributeTargets,  default = AttributeTargets.Method + AttributeTargets.Function }

        --- the attribute's priority
        property "Priority"         { type = AttributePriority, default = AttributePriority.Lower }

        -----------------------------------------------------------
        --                     constructor                       --
        -----------------------------------------------------------
        __Arguments__{ Any }
        function __new(_, key)
            return { key }
        end
    end)
end)