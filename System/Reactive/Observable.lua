--===========================================================================--
--                                                                           --
--                        System.Reactive.Observable                         --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2019/12/01                                               --
-- Update Date  :   2019/12/01                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Reactive"

    --- The attribute used to wrap a function or property that return operator to be an Observable, so could be re-used
    __Sealed__()
    class "__Observable__"              (function(_ENV)
        extend "IInitAttribute"

        export {
            _PropertyMap                = Toolset.newtable(true),

            pairs                       = pairs,
            error                       = error,
            type                        = type,
            rawget                      = rawget,
            rawset                      = rawset,
            strlower                    = string.lower,
            safeset                     = Toolset.safeset,
            isSubType                   = Class.IsSubType,

            AttributeTargets, Class, Property, Event, __Observable__, Observable, BehaviorSubject
        }

        local _StaticSubjects           = Toolset.newtable(true)

        local function getSubject(prop, obj, withCreation)
            local subject

            if prop:IsStatic() then
                subject                 = _StaticSubjects[prop]

                if not subject and withCreation then
                    local stype         = _PropertyMap[prop] or BehaviorSubject
                    subject             = stype()

                    -- Special settings for the Behavior Subjects
                    if isSubType(stype, BehaviorSubject) and prop:IsReadable() and not prop:IsIndexer() then
                        subject:OnNext(prop:GetOwner()[prop:GetName()])
                    end

                    _StaticSubjects     = safeset(_StaticSubjects, prop, subject)
                end
            else
                local container         = obj and rawget(obj, __Observable__)
                subject                 = container and container[prop]

                if not subject and obj and withCreation then
                    local stype         = _PropertyMap[prop] or BehaviorSubject
                    subject             = stype()

                    if not container then
                        container       = {}
                        rawset(obj, __Observable__, container)
                    end

                    container[prop]     = subject

                    -- Special settings for the Behavior Subjects
                    if isSubType(stype, BehaviorSubject) and prop:IsReadable() and not prop:IsIndexer() then
                        subject:OnNext(obj[prop:GetName()])
                    end
                end
            end

            return subject
        end

        -----------------------------------------------------------
        --                    static  method                     --
        -----------------------------------------------------------
        __Static__() function IsObservableProperty(prop)
            return _PropertyMap[prop] ~= nil
        end

        __Static__()
        function GetPropertyObservable(prop, obj)
            return _PropertyMap[prop] ~= nil and getSubject(prop, obj, true) or nil
        end

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        function InitDefinition(self, target, targettype, definition, owner, name, stack)
            if targettype == AttributeTargets.Property then
                local set, handler

                for k, v in pairs(definition) do
                    if type(k) == "string" then
                        local lk        = strlower(k)

                        if lk == "auto" then
                            error("The property " .. name .. " can't be used as observable", stack + 1)
                        elseif lk  == "set" then
                            if v  == false then error("The property " .. name .. " can't be used as observable", stack + 1) end
                            set         = k
                        elseif lk  == "setmethod" then
                            set         = set or k
                        elseif lk  == "handler" then
                            handler     = k
                        end
                    end
                end

                if set then
                    -- Replace the set
                    local oset          = definition[set]
                    if type(oset) == "function" then
                        definition[set] = function(obj, ...)
                            oset(obj, ...)

                            local subject = getSubject(target, obj)
                            if subject then subject:OnNext(...) end
                        end
                    elseif type(oset) == "string" then
                        definition[set] = function(obj, ...)
                            local func  = obj[oset]
                            if type(func) == "function" then func(obj, ...) end

                            local subject = getSubject(target, obj)
                            if subject then subject:OnNext(...) end
                        end
                    end
                end

                -- Replace the handler
                local ohandler          = definition[handler]
                if type(ohandler) == "function" then
                    definition[handler] = function(obj, new, old, prop)
                        ohandler(obj, new, old, prop)

                        local subject   = getSubject(target, obj)
                        if subject then subject:OnNext(new) end
                    end
                elseif type(ohandler) == "string" then
                    definition[handler] = function(obj, new, old, prop)
                        local func      = obj[ohandler]
                        if type(func) == "function" then func(obj, new, old, prop) end

                        local subject   = getSubject(target, obj)
                        if subject then subject:OnNext(new) end
                    end
                else
                    definition.handler  = function(obj, new, old, prop)
                        local subject   = getSubject(target, obj)
                        if subject then subject:OnNext(new) end
                    end
                end

                _PropertyMap[target]    = self.SubjectType or false
            else
                return function(...) return Observable.Defer(target, ...) end
            end
        end

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- the attribute target
        property "AttributeTarget"      { type = AttributeTargets,  default = AttributeTargets.Method + AttributeTargets.Function + AttributeTargets.Property }

        property "Priority"             { type = AttributePriority, default = AttributePriority.Lower }

        property "SubLevel"             { type = Number, default = -9999 }

        property "SubjectType"          { type = -Subject }

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{ -Subject/nil }
        function __ctor(self, type)
            self.SubjectType            = type
        end
    end)

    __Sealed__()
    class "Observable"                  (function(_ENV)
        export {
            Observer, Observable, IObservable, Subject, List, __Observable__,

            tostring                    = tostring,
            select                      = select,
            unpack                      = _G.unpack or table.unpack,
            pcall                       = pcall,
            rawset                      = rawset,
            loadsnippet                 = Toolset.loadsnippet,
            IsObjectType                = Class.IsObjectType,
            Exception                   = System.Exception,
            RunAsync                    = Threading.RunAsync,

            getProperty                 = Class.GetFeature,
            getObjectClass              = Class.GetObjectClass,
        }

        -----------------------------------------------------------------------
        --               static methods - Creating Observables               --
        -----------------------------------------------------------------------
        --- Creates a new Observable
        __Static__() __Arguments__{ Callable }
        function Create(subscribe)
            return Observable(subscribe)
        end

        --- Creates a new objservable with initstate, condition checker, iterate and a result selector
        __Static__() __Arguments__{ Any, Callable, Callable, Callable/nil}
        function Generate(init, condition, iterate, resultselector)
            return Observable(function(observer, token)
                local value             = init
                if resultselector then
                    while value ~= nil and condition(value) do
                        observer:OnNext(resultselector(value))
                        if token:IsCancelled() then return end
                        value           = iterate(value)
                    end
                else
                    while value ~= nil and condition(value) do
                        observer:OnNext(value)
                        if token:IsCancelled() then return end
                        value           = iterate(value)
                    end
                end
                observer:OnCompleted()
            end)
        end

        --- Returns an Observable that just provide one value
        local _JustAutoGen              = setmetatable({
            [0]                         = function() return Observable(function(observer) observer:OnCompleted() end) end
        }, {
            __index                     = function(self, count)
                local args              = List(count):Map("i=>'arg' .. i"):Join(",")
                local func              = loadsnippet([[
                    return function(]] .. args .. [[)
                        return Observable(function(observer)
                            observer:OnNext(]] .. args .. [[)
                            observer:OnCompleted()
                        end)
                    end
                ]], "Just_Gen_" .. count, _ENV)()
                rawset(self, count, func)
                return func
            end
            }
        )
        __Static__()
        function Just(...)
            return _JustAutoGen[select("#", ...)](...)
        end
        __Static__() Return             = Just

        --- Returns and Observable that immediately completes without producing a value
        __Static__()
        function Empty()
            return Observable(function(observer)
                observer:OnCompleted()
            end)
        end

        --- Returns an Observable that never produces values and never completes
        __Static__()
        function Never()
            return Observable(function() end)
        end

        --- Returns an Observable that immediately produces an error
        __Static__()
        function Throw(exception)
            if not (exception and IsObjectType(exception, Exception)) then
                exception               = Exception(exception and tostring(exception) or "Unknown error")
            end
            return Observable(function(observer) return observer:OnError(exception) end)
        end

        --- Creates the Observable only when the observer subscribes
        local _DeferAutoGen             = setmetatable({
            [0]                         = function(ctor)
                return Observable(function(observer)
                    local obs           = ctor()
                    if not IsObjectType(obs, IObservable) then
                        observer:OnError(Exception("The defer function doesn't provide valid observable"))
                    else
                        return obs:Subscribe(observer)
                    end
                end)
            end,
        }, {
            __index                     = function(self, count)
                local args              = List(count):Map("i=>'arg' .. i"):Join(",")
                local func              = loadsnippet([[
                    return function(ctor, ]] .. args .. [[)
                        return Observable(function(observer)
                            local obs   = ctor(]] .. args .. [[)
                            if not IsObjectType(obs, IObservable) then
                                observer:OnError(Exception("The defer function doesn't provide valid observable"))
                            else
                                return obs:Subscribe(observer)
                            end
                        end)
                    end
                ]], "Defer_Gen_" .. count, _ENV)()
                rawset(self, count, func)
                return func
            end
            }
        )
        __Static__() __Arguments__{ Callable, Any * 0 }
        function Defer(ctor, ...)
            return _DeferAutoGen[select("#", ...)](ctor, ...)
        end

        --- Converts collection objects into Observables
        __Static__() __Arguments__{ Iterable }
        function From(iter)
            return Observable(function(observer, token)
                for key, value in iter:GetIterator() do
                    if token:IsCancelled() then return end
                    if value == nil then value, key = key, nil end
                    observer:OnNext(value, key)
                end
                observer:OnCompleted()
            end)
        end

        --- Converts event delegate objects into Observables
        __Static__() __Arguments__{ Delegate }
        function From(delegate)
            local subject               = delegate[Observable]
            if not subject then
                subject                 = Subject()
                delegate                = delegate + function(...) return subject:OnNext(...) end
                delegate[Observable]    = subject
            end
            return subject
        end

        --- Converts tables into Observables
        __Static__() __Arguments__{ Table, Callable/nil }
        function From(table, iter)
            return Observable(function(observer, token)
                for key, value in (iter or pairs)(table) do
                    if token:IsCancelled() then return end
                    if value == nil then value, key = key, nil end
                    observer:OnNext(value, key)
                end
                observer:OnCompleted()
            end)
        end

        --- Create a subject based on observable property
        __Static__() __Arguments__{ PropertyType }
        function From(prop)
            return __Observable__.GetPropertyObservable(prop, nil, true)
        end

        __Arguments__{ InterfaceType + ClassType, String }
        __Static__() function From(class, name)
            local prop                  = getProperty(class, name)
            return prop and __Observable__.GetPropertyObservable(prop, nil, true)
        end

        __Static__() __Arguments__{ Table, String }
        function From(self, name)
            local cls                   = getObjectClass(self)
            local prop                  = cls and getProperty(cls, name, true)

            return prop and __Observable__.GetPropertyObservable(prop, self, true)
        end

        --- Creates an Observable that emits a particular range of sequential integers
        __Static__() __Arguments__{ Number, Number, Number/nil }
        function Range(start, stop, step)
            return Observable(function(observer, token)
                for i = start, stop, step or 1 do
                    if token:IsCancelled() then return end
                    observer:OnNext(i)
                end
                observer:OnCompleted()
            end)
        end

        --- Creates an Observable that emits a particular item multiple times
        local _RepeatGen                = setmetatable({}, {
            __index                     = function(self, count)
                local args              = List(count):Map("i=>'arg' .. i"):Join(",")
                local func              = loadsnippet([[
                    return function(count, ]] .. args .. [[)
                        return Observable(function(observer, token)
                            local i     = 0

                            while i < count do
                                if token:IsCancelled() then return end
                                observer:OnNext(]] .. args .. [[)
                                i       = i + 1
                            end
                            observer:OnCompleted()
                        end)
                    end
                ]], "Repeat_Gen_" .. count, _ENV)()
                rawset(self, count, func)
                return func
            end
            }
        )
        __Static__() __Arguments__{ Number, Any * 1 }
        function Repeat(count, ...)
            return _RepeatGen[select("#", ...)](count, ...)
        end

        --- Creates an Observable that emits the return value of a function-like directive
        local _StartGen                 = setmetatable({
            [0]                         = function(func)
                return Observable(function(observer)
                    RunAsync(function()
                        observer:OnNext(func())
                        observer:OnCompleted()
                    end)
                end)
            end
        }, {
            __index                     = function(self, count)
                local args              = List(count):Map("i=>'arg' .. i"):Join(",")
                local func              = loadsnippet([[
                    return function(func, ]] .. args .. [[)
                        return Observable(function(observer)
                            RunAsync(function()
                                observer:OnNext(func(]] .. args .. [[))
                                observer:OnCompleted()
                            end)
                        end)
                    end
                ]], "Start_Gen_" .. count, _ENV)()
                rawset(self, count, func)
                return func
            end
            }
        )
        __Static__() __Arguments__{ Callable, Any * 0 }
        function Start(func, ...)
            return _StartGen[select("#", ...)](func, ...)
        end
    end)
end)