--===========================================================================--
--                                                                           --
--                        System.Reactive.Observable                         --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2019/12/01                                               --
-- Update Date  :   2024/05/09                                               --
-- Version      :   2.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Reactive"

    --- The attribute used to wrap a function or property that return operator to be an Observable
    __Sealed__()
    class "__Observable__"              (function(_ENV)
        extend "IInitAttribute"

        export                          {
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
        --- Whether the property is observable
        __Static__()
        function IsObservableProperty(prop)
            return _PropertyMap[prop] ~= nil
        end

        --- Gets the observable from the property
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

    -- Extend the Observable
    __Sealed__()
    class "Observable"                  (function(_ENV)
        export                          {
            tostring                    = tostring,
            select                      = select,
            unpack                      = _G.unpack or table.unpack,
            pcall                       = pcall,
            rawset                      = rawset,
            rawget                      = rawget,
            loadsnippet                 = Toolset.loadsnippet,
            fakefunc                    = Toolset.fakefunc,
            isobjecttype                = Class.IsObjectType,
            Exception                   = System.Exception,
            runasync                    = Threading.RunAsync,

            getproperty                 = Class.GetFeature,
            getobjectclass              = Class.GetObjectClass,
            onnextiterkey               = function(observer, k, ...) if k == nil then return end observer:OnNext(k, ...) return k end,
            onasyncnext                 = function(observer, subscription, ...) return not subscription.IsUnsubscribed and observer:OnNext(...) end,

            Observer, Observable, IObservable, Subscription, Subject, List, __Observable__,
        }

        -----------------------------------------------------------------------
        --               static methods - Creating Observables               --
        -----------------------------------------------------------------------
        --- Creates a new Observable
        __Static__() __Arguments__{ Callable }
        function Create(subscribe)      return Observable(subscribe) end

        --- Creates a new observable with initstate, condition checker, iterate and a result selector
        __Static__() __Arguments__{ Any, Callable, Callable, Callable/nil}
        function Generate(init, condition, iterate, resultselector)
            return Observable(function(observer, subscription)
                local value             = init
                if resultselector then
                    while value ~= nil and condition(value) do
                        if subscription.IsUnsubscribed then return end
                        observer:OnNext(resultselector(value))
                        value           = iterate(value)
                    end
                else
                    while value ~= nil and condition(value) do
                        if subscription.IsUnsubscribed then return end
                        observer:OnNext(value)
                        value           = iterate(value)
                    end
                end
                return not subscription.IsUnsubscribed and observer:OnCompleted()
            end)
        end

        --- Returns an Observable that just provide one value
        _JustAutoGen                    = setmetatable({},
        {
            __index                     = function(self, count)
                local args              = count == 0 and "" or List(count):Map("i=>'arg' .. i"):Join(",")
                local func              = loadsnippet([[
                    return function(]] .. args .. [[)
                        return Observable(function(observer, subscription)
                            if subscription.IsUnsubscribed then return end
                            observer:OnNext(]] .. (count == 0 and "nil" or args) .. [[)
                            return not subscription.IsUnsubscribed and observer:OnCompleted()
                        end)
                    end
                ]], "Just_Gen_" .. count, _ENV)()
                rawset(self, count, func)
                return func
            end
        })
        __Static__()
        function Just(...)              return _JustAutoGen[select("#", ...)](...) end
        __Static__() Return             = Just

        --- Returns and Observable that immediately completes without producing a value
        __Static__()
        function Empty()                return Observable(function(observer, subscription) return not subscription.IsUnsubscribed and observer:OnCompleted() end) end

        --- Returns an Observable that never produces values and never completes
        __Static__()
        function Never()                return Observable(fakefunc) end

        --- Returns an Observable that immediately produces an error
        __Static__()
        function Throw(exception)
            if not (exception and isobjecttype(exception, Exception)) then
                exception               = Exception(exception and tostring(exception) or "Unknown error")
            end
            return Observable(function(observer, subscription) return not subscription.IsUnsubscribed and observer:OnError(exception) end)
        end

        --- Creates the Observable only when the observer subscribes
        _DeferAutoGen                   = setmetatable({}, {
            __index                     = function(self, count)
                local args              = count == 0 and "" or List(count):Map("i=>'arg' .. i"):Join(",")
                local func              = loadsnippet([[
                    return function(ctor]] .. (count == 0 and "" or (", " .. args)) .. [[)
                        return Observable(function(observer, subscription)
                            local obs   = ctor(]] .. args .. [[)
                            if not isobjecttype(obs, IObservable) then
                                observer:OnError(Exception("The defer function doesn't provide valid observable"))
                            elseif not subscription.IsUnsubscribed then
                                return obs:Subscribe(observer, subscription)
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
        function Defer(ctor, ...)       return _DeferAutoGen[select("#", ...)](ctor, ...) end

        --- Converts list objects into Observables
        __Static__() __Arguments__{ IList }
        function From(list)
            return Observable(function(observer, subscription)
                for key, value in list:GetIterator() do
                    if subscription.IsUnsubscribed then return end
                    if value == nil then value, key = key, nil end
                    observer:OnNext(value, key)
                end
                return not subscription.IsUnsubscribed and observer:OnCompleted()
            end)
        end

        --- Converts dictionary objects into Observables
        __Static__() __Arguments__{ IDictionary }
        function From(dict)
            return Observable(function(observer, subscription)
                for key, value in dict:GetIterator() do
                    if subscription.IsUnsubscribed then return end
                    observer:OnNext(key, value)
                end
                return not subscription.IsUnsubscribed and observer:OnCompleted()
            end)
        end

        --- Converts collection objects into Observables
        __Static__() __Arguments__{ Iterable }
        function From(iter)
            return Observable(function(observer, subscription)
                local f, t, k           = iter:GetIterator()
                repeat
                    if subscription.IsUnsubscribed then return end
                    k                   = onnextiterkey(observer, f(t, k))
                until k == nil
                return not subscription.IsUnsubscribed and observer:OnCompleted()
            end)
        end

        --- Converts event delegate objects into Observables
        __Static__() __Arguments__{ Delegate }
        function From(delegate)
            local subject               =  rawget(delegate, Observable)
            if not subject then
                subject                 = Subject()
                delegate                = delegate + function(...) return subject:OnNext(...) end
                rawset(delegate, Observable, subject)
            end
            return subject
        end

        --- Creates an Observable that emits the return value of a function-like directive
        __Static__() __Arguments__{ Callable, Any/nil, Any/nil }
        function From(func, t, k)
            return Observable(function(observer, subscription)
                repeat
                    if subscription.IsUnsubscribed then return end
                    k                   = onnextiterkey(observer, func(t, k))
                until k == nil
                return not subscription.IsUnsubscribed and observer:OnCompleted()
            end)
        end

        --- Converts tables into Observables
        __Static__() __Arguments__{ Table, Callable/nil }
        function From(table, iter)
            return Observable(function(observer, subscription)
                for key, value in (iter or pairs)(table) do
                    if subscription.IsUnsubscribed then return end
                    if value == nil then value, key = key, nil end
                    observer:OnNext(value, key)
                end
                return not subscription.IsUnsubscribed and observer:OnCompleted()
            end)
        end

        --- Create a subject based on observable property
        __Static__() __Arguments__{ PropertyType }
        function From(prop)             return __Observable__.GetPropertyObservable(prop, nil, true) end

        __Arguments__{ InterfaceType + ClassType, String }
        __Static__() function From(class, name)
            local prop                  = getproperty(class, name)
            return prop and __Observable__.GetPropertyObservable(prop, nil, true)
        end

        __Static__() __Arguments__{ Table, String }
        function From(self, name)
            local cls                   = getobjectclass(self)
            local prop                  = cls and getproperty(cls, name, true)
            return prop and __Observable__.GetPropertyObservable(prop, self, true)
        end

        --- Creates an Observable that emits a particular range of sequential integers
        __Static__() __Arguments__{ Number, Number, Number/nil }
        function Range(start, stop, step)
            return Observable(function(observer, subscription)
                for i = start, stop, step or 1 do
                    if subscription.IsUnsubscribed then return end
                    observer:OnNext(i)
                end
                return not subscription.IsUnsubscribed and observer:OnCompleted()
            end)
        end

        --- Creates an Observable that emits a particular item multiple times
        _RepeatGen                      = setmetatable({}, {
            __index                     = function(self, count)
                local args              = List(count):Map("i=>'arg' .. i"):Join(",")
                local func              = loadsnippet([[
                    return function(count, ]] .. args .. [[)
                        return Observable(function(observer, subscription)
                            local i     = 0
                            while i < count do
                                if subscription.IsUnsubscribed then return end
                                observer:OnNext(]] .. args .. [[)
                                i       = i + 1
                            end
                            return not subscription.IsUnsubscribed and observer:OnCompleted()
                        end)
                    end
                ]], "Repeat_Gen_" .. count, _ENV)()
                rawset(self, count, func)
                return func
            end
            }
        )
        __Static__() __Arguments__{ Number, Any * 1 }
        function Repeat(count, ...)     return _RepeatGen[select("#", ...)](count, ...) end

        --- Creates an Observable that emits the return value of a function-like directive
        _StartGen                       = setmetatable({}, {
            __index                     = function(self, count)
                local args              = count == 0 and "" or List(count):Map("i=>'arg' .. i"):Join(",")
                local func              = loadsnippet([[
                    return function(func]] .. (count == 0 and "" or (", " .. args)) .. [[)
                        return Observable(function(observer, subscription)
                            runasync(function()
                                onasyncnext(observer, subscription, func(]] .. args .. [[))
                                return not subscription.IsUnsubscribed and observer:OnCompleted()
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
        function Start(func, ...)       return _StartGen[select("#", ...)](func, ...) end
    end)
end)