--===========================================================================--
--                                                                           --
--                         System.Reactive.Operator                          --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2019/12/04                                               --
-- Update Date  :   2024/05/09                                               --
-- Version      :   2.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Reactive"

    --- The basic observable sequence operator
    __Sealed__()
    class "Operator"                    (function(_ENV)
        extend "System.IObservable" "System.IObserver"

        export                          {
            dftnext                     = function(self, ...) return self.Observer:OnNext(...) end,
            dfterror                    = function(self, ex) return self.Observer:OnError(ex) end,
            dftcomp                     = function(self) return self.Observer:OnCompleted() end,

            -- the core subscribe
            subscribe                   = function (self, observer, subscription)
                -- The operator can't be re-used
                if self.Observer then
                    if self.Observer == observer then
                        return self.Subscription, observer
                    else
                        throw "The operator can't be subscribed by multi observers"
                    end
                end
                self.Observer           = observer

                -- handle the subscription
                subscription            = subscription or observer.Subscription
                if subscription.IsUnsubscribed then return subscription, observer end
                subscription            = self:HandleSubscription(subscription, observer) or subscription

                -- Keep using the same subscription
                self.Subscription       = subscription
                self.Observable:Subscribe(self, subscription)
                return subscription, observer
            end,

            Observer
        }

        -----------------------------------------------------------------------
        --                         abstract method                           --
        -----------------------------------------------------------------------
        --- Used to handle the subscription, can be used to replace the original one
        __Abstract__()
        HandleSubscription              = function (self, subscription, observer) return subscription end

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        --- Notifies the provider that an observer is to receive notifications.
        __Arguments__{ IObserver, Subscription/nil }:Throwable()
        Subscribe                       = subscribe

        __Arguments__{ Callable/nil, Callable/nil, Callable/nil, Subscription/nil }:Throwable()
        Subscribe                       = function (self, onNext, onError, onCompleted, subscription)
            return subscribe(self, Observer(onNext, onError, onCompleted, subscription))
        end

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- The observable
        __Set__(PropertySet.Weak)
        property "Observable"           { type = IObservable }

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        __Arguments__{ IObservable, Callable/nil, Callable/nil, Callable/nil }
        function __ctor(self, observable, onNext, onError, onCompleted)
            self.OnNext                 = onNext and function(self, ...) return onNext(self.Observer, ...) end or dftnext
            self.OnError                = onError and function(self, ex) return onError(self.Observer, ex) end or dfterror
            self.OnCompleted            = onCompleted and function(self) return onCompleted(self.Observer) end or dftcomp

            self.Observable             = observable
            self.Observer               = false
        end
    end)

    -- Method Extension
    interface (IObservable)             (function(_ENV)
        export                          {
            max                         = math.max,
            min                         = math.min,
            huge                        = math.huge,
            floor                       = math.floor,
            type                        = type,
            tostring                    = tostring,
            tonumber                    = tonumber,
            tinsert                     = table.insert,
            pcall                       = pcall,
            next                        = next,
            select                      = select,
            pairs                       = pairs,
            ipairs                      = ipairs,
            strformat                   = string.format,
            loadsnippet                 = Toolset.loadsnippet,
            tostringall                 = Toolset.tostringall,
            combinearray                = Toolset.combinearray,
            otime                       = _G.os and (os.clock or os.time) or false,
            unpack                      = _G.unpack or table.unpack,
            isobjecttype                = Class.IsObjectType,
            running                     = coroutine.running,
            yield                       = coroutine.yield,
            resume                      = coroutine.resume,
            status                      = coroutine.status,
            safeNext                    = function (observer, flag, item, ...)
                if flag and item ~= nil then
                    return observer:OnNext(item, ...)
                else
                    return observer:OnError(Exception(item or "No value returned"))
                end
            end,

            Info                        = Logger.Default[Logger.LogLevel.Info],

            Operator, IObservable, Observer, Observable, Subscription,
            Threading, Guid, Exception, Dictionary, Queue, List,
            PublishSubject, ReplaySubject, Subject
        }

        -----------------------------------------------------------------------
        --                               Tool                                --
        -----------------------------------------------------------------------
        --- Dump the sequence
        __Arguments__{ NEString/"Dump" }
        function Dump(self, name)
            return self:Subscribe(
                function(...) return Info("%s-->%s",        name, List{ tostringall(...) }:Join(", ")) end,
                function(ex)  return Info("%s failed-->%s", name, tostring(ex)) end,
                function()    return Info("%s completed",   name) end)
        end

        --- Process all elements as they arrived, works like the Subscribe, but will block the current coroutine
        __Arguments__{ Callable, Callable/nil, Callable/nil }
        function ForEach(self, onNext, onError, onCompleted)
            local curr, main            = running()
            if not curr or main then    return self:Subscribe(onNext, onError, onCompleted) end

            local finished

            self:Subscribe(onNext,
                function(ex)
                    finished            = true
                    if onError then onError(ex) end
                    return resume(curr)
                end,
                function()
                    finished            = true
                    if onCompleted then onCompleted() end
                    return resume(curr)
                end)

            if not finished then return yield() end
        end

        --- Convert the observable sequence to an iterator, must be used in a coroutine
        function ToIterator(self)
            local curr, main            = running()
            if not curr or main then error("Usage: ToIterator(self) - must be processed in a coroutine", 2) end
            local inited, finished
            local queue                 = Queue()

            return function()
                if not inited then
                    inited              = true

                    self:Subscribe(
                        function(...)
                            queue(select("#", ...), ...)
                            if status(curr) == "suspended" then
                                resume(curr, queue:Dequeue(queue:Dequeue()))
                            end
                        end,
                        function(ex)
                            finished    = ex
                            if status(curr) == "suspended" then
                                resume(curr, nil, ex)
                            end
                        end,
                        function()
                            finished    = true
                            if status(curr) == "suspended" then
                                resume(curr)
                            end
                        end)
                end

                local count             = queue:Dequeue()
                if count ~= nil then
                    return queue:Dequeue(count)
                elseif finished then
                    return nil, finished ~= true and finished or nil
                else
                    return yield()
                end
            end
        end

        --- Encapsulate the sequence as a new observable sequence, so the outside can't
        -- access the real sequece directly
        function AsObservable(self)     return Observable(function(...) return self:Subscribe(...) end) end

        --- Invokes actions with side effecting behavior for each element in the observable sequence
        __Observable__()
        __Arguments__{ Callable, Callable/nil, Callable/nil }
        function Do(self, onNext, onError, onCompleted)
            return Operator(self,
                function(observer, ...)
                    onNext(...)
                    return observer:OnNext(...)
                end,
                onError and function(observer, ex)
                    onError(ex)
                    return observer:OnError(ex)
                end,
                onCompleted and function(observer)
                    onCompleted()
                    return observer:OnCompleted()
                end)
        end

        --- Catch the exception and replace with another sequence if provided
        __Observable__()
        __Arguments__{ Callable }
        function Catch(self, onError)
            local subscription, replace
            local oper                  = Operator(self, nil, function(observer, ex)
                local ok, ret           = pcall(onError, ex)
                if not (ok and isobjecttype(ret, IObservable)) then
                    return observer:OnError(ex)
                else
                    if replace then replace:Dispose() replace = nil end
                    return ret:Subscribe(observer, subscription)
                end
            end)

            -- Hack the subscribe replace the subscription
            oper.HandleSubscription     = function(self, ...)
                subscription            = ...
                replace                 = Subscription(subscription)
                return replace
            end
            return oper
        end

        --- Process operations when the sequence is completed, error or unsubscribed
        __Observable__()
        __Arguments__{ Callable }
        function Finally(self, finally)
            local oper                  = Operator(self)
            local callFinally           = function()
                if finally then
                    local _finally      = finally
                    finally             = nil
                    return _finally()
                end
            end
            oper.HandleSubscription     = function(self, sub)
                sub.OnUnsubscribe       = sub.OnUnsubscribe + callFinally
            end
            return oper
        end

        --- Start the next observable sequence when the sequence is failed or completed
        __Observable__()
        __Arguments__{ IObservable }
        function OnErrorResumeNext(self, observable)
            local subscription, replace
            local resume                = function(observer)
                if replace then replace:Dispose() end
                return observable:Subscribe(observer, subscription)
            end
            local oper                  = Operator(self, nil, resume, resume)

            -- Hack the subscribe replace the subscription
            oper.HandleSubscription     = function(self, ...)
                subscription            = ...
                replace                 = Subscription(subscription)
                return replace
            end
            return oper
        end

        --- Retry the sequence if failed
        __Observable__()
        __Arguments__{ NaturalNumber/nil }
        function Retry(self, count)
            count                       = count or huge
            local times                 = 0
            return Operator(self, nil, function(observer, ex)
                times                   = times + 1
                return times > count and observer:OnError(ex)
            end)
        end

        -----------------------------------------------------------------------
        --                              Filter                               --
        -----------------------------------------------------------------------
        --- Applying a filter to a sequence
        __Observable__()
        __Arguments__{ Callable, Boolean/nil }
        function Where(self, condition, safe)
            if safe then
                return Operator(self, function(observer, ...)
                    local ok, ret       = pcall(condition, ...)
                    if not ok then return observer:OnError(Exception(ret)) end
                    if ret then return observer:OnNext(...) end
                end)
            else
                return Operator(self, function(observer, ...) return condition(...) and observer:OnNext(...) end)
            end
        end
        Filter                          = Where -- Alias

        --- Applying a filter that only allow distinct items
        __Arguments__{ Callable/nil, Boolean/nil }
        __Observable__()
        function Distinct(self, selector, safe)
            local cache                 = {}
            if selector then
                if safe then
                    return Operator(self, function(observer, ...)
                        local ok, ret   = pcall(selector, ...)
                        if not (ok and ret ~= nil) then return observer:OnError(Exception(ret or "There is no value can be used for distinct")) end

                        if ret ~= nil and not cache[ret] then
                            cache[ret]  = true
                            return observer:OnNext(...)
                        end
                    end)
                else
                    return Operator(self, function(observer, ...)
                        local ret       = selector(...)

                        if ret ~= nil and not cache[ret] then
                            cache[ret]  = true
                            return observer:OnNext(...)
                        end
                    end)
                end
            else
                return Operator(self, function(observer, ret, ...)
                    if ret ~= nil and not cache[ret] then
                        cache[ret]      = true
                        return observer:OnNext(ret, ...)
                    end
                end)
            end
        end

        --- Applying a filter that only value diff from the previous can pass
        __Observable__()
        __Arguments__{ Callable/nil, Boolean/nil }
        function DistinctUntilChanged(self, selector, safe)
            local previous
            if selector then
                if safe then
                    return Operator(self, function(observer, ...)
                        local ok, ret   = pcall(selector, ...)
                        if not (ok and ret ~= nil) then return observer:OnError(Exception(ret or "There is no value can be used for distinct")) end

                        if ret ~= nil and ret ~= previous then
                            previous    = ret
                            return observer:OnNext(...)
                        end
                    end)
                else
                    return Operator(self, function(observer, ...)
                        local ret       = selector(...)

                        if ret ~= nil and ret ~= previous then
                            previous    = ret
                            return observer:OnNext(...)
                        end
                    end)
                end
            else
                return Operator(self, function(observer, ret, ...)
                    if ret ~= nil and ret ~= previous then
                        previous        = ret
                        return observer:OnNext(ret, ...)
                    end
                end)
            end
        end

        --- Ignored all elements, only receive complete or error notifications
        __Observable__()
        function IgnoreElements(self)
            return self:Where("=>false")
        end

        --- Skip the given count elements
        __Observable__()
        __Arguments__{ Number }
        function Skip(self, count)
            return self:Where(function() count = count - 1 return count < 0 end)
        end

        --- Only take the elements of the given count
        __Observable__()
        __Arguments__{ Number }
        function Take(self, count)
            return Operator(self, function(observer, ...)
                if count > 0 then
                    count               = count - 1
                    observer:OnNext(...)

                    if count <= 0 then
                        observer:OnCompleted()
                    end
                else
                    observer:OnCompleted()
                end
            end)
        end

        --- filter out all values until a value fails the predicate, then the remaining sequence can be returned
        __Observable__()
        __Arguments__{ Callable }
        function SkipWhile(self, condition)
            local take                  = false
            return self:Where(function(...) take = take or not condition(...) return take end)
        end

        --- return all values while the predicate passes, and when the first value fails the sequence will complete
        __Observable__()
        __Arguments__{ Callable, Boolean/nil }
        function TakeWhile(self, condition, safe)
            if safe then
                return Operator(self, function(observer, ...)
                    local ok, ret       = pcall(condition, ...)
                    if not ok then return observer:OnError(Exception(ret)) end

                    if ret then
                        observer:OnNext(...)
                    else
                        observer:OnCompleted()
                    end
                end)
            else
                return Operator(self, function(observer, ...)
                    if condition(...) then
                        observer:OnNext(...)
                    else
                        observer:OnCompleted()
                    end
                end)
            end
        end

        --- Skip the last elements of the given count
        __Observable__()
        __Arguments__{ Number }
        function SkipLast(self, last)
            local count                 = 0
            local queue                 = Queue()

            return Operator(self, function(observer, ...)
                count                   = count + 1
                queue:Enqueue(select("#", ...), ...)

                if count > last then
                    observer:OnNext(queue:Dequeue(queue:Dequeue()))
                end
            end)
        end

        --- Take the last elements of the given count
        __Observable__()
        __Arguments__{ Number }
        function TakeLast(self, last)
            local queue                 = Queue()
            local count                 = 0

            return Operator(self, function(observer, ...)
                count                   = count + 1
                queue:Enqueue(select("#", ...), ...)

                if count > last then
                    queue:Dequeue(queue:Dequeue())
                end
            end, nil, function(observer)
                local count             = queue:Dequeue()
                while count do
                    observer:OnNext(queue:Dequeue(count))
                    count               = queue:Dequeue()
                end
                observer:OnCompleted()
            end)
        end

        --- Skip all values until any value is produced by a secondary observable sequence
        __Observable__()
        __Arguments__{ IObservable }
        function SkipUntil(self, other)
            local flag                  = false
            other:Take(1):Subscribe(function() flag = true end)
            return self:Where(function() return flag end)
        end

        --- Take all values until any value is produced by a secondary observable sequence
        __Observable__()
        __Arguments__{ IObservable }
        function TakeUntil(self, other)
            local flag                  = true
            other:Take(1):Subscribe(function() flag = false end)
            return Operator(self, function(observer, ...)
                if flag then
                    return observer:OnNext(...)
                else
                    return observer:OnCompleted()
                end
            end)
        end

        --- Take all values that match the prefix elements
        _MatchPrefixGen                 = setmetatable({}, {
            __index                     = function(self, count)
                local func              = loadsnippet([[
                    return function(self, ]] .. List(count):Map("i=>'arg' .. i"):Join(",") .. [[)
                        return Operator(self, function(observer, ]] .. List(count):Map("i=>'brg' .. i"):Join(",") .. [[, ...)
                            if ]] .. List(count):Map("i=>'arg'..i..' == brg' .. i"):Join(" and ")  .. [[ then
                                return observer:OnNext(]] .. List(count):Map("i=>'brg' .. i"):Join(",") .. [[, ...)
                            end
                        end)
                    end
                ]], "MatchPrefix_Gen_" .. count, _ENV)()
                rawset(self, count, func)
                return func
            end
        })
        __Observable__()
        __Arguments__{ System.Any * 1 }
        function MatchPrefix(self, ...)
            return _MatchPrefixGen[select("#", ...)](self, ...)
        end

        -----------------------------------------------------------------------
        --                            Inspection                             --
        -----------------------------------------------------------------------
        --- Returns a single value sequence indicate whether the target observable sequence contains any value or value meet the predicate
        __Observable__()
        __Arguments__{ Callable/nil, Boolean/nil }
        function Any(self, predicate, safe)
            return Operator(self,
                predicate and (safe and
                    function(observer, ...)
                        local ok, ret       = pcall(predicate, ...)
                        if not ok then return observer:OnError(Exception(ret)) end

                        if ret then
                            observer:OnNext(true)
                            observer:OnCompleted()
                        end
                    end or
                    function(observer, ...)
                        if predicate(...) then
                            observer:OnNext(true)
                            observer:OnCompleted()
                        end
                    end
                ) or
                function(observer, ...)
                    observer:OnNext(true)
                    observer:OnCompleted()
                end,
                nil,
                function(observer)
                    observer:OnNext(false)
                    observer:OnCompleted()
                end
            )
        end

        --- Returns a single value sequence indicate whether the target observable sequence's all values meet the predicate
        __Observable__()
        __Arguments__{ Callable, Boolean/nil }
        function All(self, predicate, safe)
            return Operator(self, safe and function(observer, ...)
                local ok, ret           = pcall(predicate, ...)
                if not ok then return observer:OnError(Exception(ret)) end

                if not ret then
                    observer:OnNext(false)
                    observer:OnCompleted()
                end
            end or function(observer, ...)
                if not predicate(...) then
                    observer:OnNext(false)
                    observer:OnCompleted()
                end
            end, nil, function(observer)
                observer:OnNext(true)
                observer:OnCompleted()
            end)
        end

        --- Returns a single value sequence indicate whether the target observable sequence contains a specific value
        _ContainsGen                    = setmetatable({}, {
            __index                     = function(self, count)
                local func              = loadsnippet([[
                    return function(self, ]] .. List(count):Map("i=>'arg' .. i"):Join(",") .. [[)
                        return self:Any(function(]] .. List(count):Map("i=>'brg' .. i"):Join(",") .. [[)
                            return ]] .. List(count):Map("i=>'arg'..i..' == brg' .. i"):Join(" and ")  .. [[
                        end)
                    end
                ]], "Contains_Gen_" .. count, _ENV)()
                rawset(self, count, func)
                return func
            end
        })
        __Observable__()
        __Arguments__{ System.Any * 1 }
        function Contains(self, ...)
            return _ContainsGen[select("#", ...)](self, ...)
        end

        --- Returns a sequence with single default value if the target observable sequence doesn't contains any item
        _DefaultGen                     = setmetatable({}, {
            __index                     = function(self, count)
                local func              = loadsnippet([[
                    return function(self, ]] .. List(count):Map("i=>'arg' .. i"):Join(",") .. [[)
                        local e = false
                        return Operator(self, function(observer, ...)
                            e   = true
                            observer:OnNext(...)
                        end, nil, function(observer)
                            if not e then
                                observer:OnNext(]] .. List(count):Map("i=>'arg' .. i"):Join(",") .. [[)
                            end
                            observer:OnCompleted()
                        end)
                    end
                ]], "Default_Gen_" .. count, _ENV)()
                rawset(self, count, func)
                return func
            end
        })
        __Observable__()
        __Arguments__{ System.Any * 1 }
        function Default(self, ...)
            return _DefaultGen[select("#", ...)](self, ...)
        end

        --- Raise exception if the sequence don't provide any elements
        __Observable__()
        function NotEmpty(self)
            local hasElements           = false
            return Operator(self, function(observer, ...)
                hasElements             = true
                return observer:OnNext(...)
            end, nil, function(observer)
                if not hasElements then
                    observer:OnError(Exception("The sequence doesn't provide any elements"))
                end
                return observer:OnCompleted()
            end)
        end

        --- Returns a sequence with the value at the given index(0-base) of the target observable sequence
        __Observable__()
        __Arguments__{ NaturalNumber }
        function ElementAt(self, index)
            index                       = floor(index)
            return Operator(self, function(observer, ...)
                if index == 0 then
                    observer:OnNext(...)
                    observer:OnCompleted()
                else
                    index               = index - 1
                end
            end)
        end

        --- Compares two observable sequences whether those sequences has the same values in the same order and that the sequences are the same length
        __Observable__()
        __Arguments__{ IObservable, Callable/"x,y=>x==y" }
        function SequenceEqual(self, other, compare)
            local fqueue                = Queue()
            local squeue                = Queue()
            local iscomp

            local compareQueue          = function(observer)
                local fcount            = fqueue:Dequeue()
                local scount            = squeue:Dequeue()

                if fcount ~= scount then
                    observer:OnNext(false)
                    return observer:OnCompleted() and false
                end

                for i = 1, fcount do
                    if not compare(fqueue:Dequeue(), squeue:Dequeue()) then
                        observer:OnNext(false)
                        return observer:OnCompleted() and false
                    end
                end
                return true
            end

            local complete              = function(observer)
                if iscomp then
                    local flag          = true
                    while flag and squeue:Peek() and fqueue:Peek() do
                        flag            = compareQueue(observer)
                    end

                    if flag then
                        if squeue:Peek() or fqueue:Peek() then
                            observer:OnNext(false)
                        else
                            observer:OnNext(true)
                        end
                        return observer:OnCompleted()
                    end
                else
                    iscomp              = true
                end
            end

            local otherOper             = Operator(other,
                function(observer, ...)
                    squeue(select("#", ...), ...)
                    return fqueue:Peek() and compareQueue(observer)
                end, nil, complete
            )

            local oper                  = Operator(self,
                function(observer, ...)
                    fqueue(select("#", ...), ...)
                    return squeue:Peek() and compareQueue(observer)
                end, nil, complete
            )

            -- Subscribe the other observable
            oper.HandleSubscription     = function(self, subscription, observer)
                otherOper:Subscribe(observer, subscription)
            end

            return oper
        end

        -----------------------------------------------------------------------
        --                            Aggregation                            --
        -----------------------------------------------------------------------
        --- Returns a sequence with a single value generated from the source sequence
        __Observable__()
        __Arguments__{ Callable, System.Any/nil, Boolean/nil }
        function Aggregate(self, accumulator, seed, safe)
            return Operator(self, safe and function(observer, ...)
                if seed == nil then
                    seed                = ...
                else
                    local ok, ret = pcall(accumulator, seed, ...)
                    if not ok then observer:OnError(Exception(ret)) end
                    seed                = ret
                end
            end or function(observer, ...)
                if seed == nil then
                    seed                = ...
                else
                    seed                = accumulator(seed, ...)
                end
            end, nil, function(observer)
                if seed ~= nil then observer:OnNext(seed) end
                observer:OnCompleted()
            end)
        end

        --- Returns a sequence with a single value being the count of the values in the source sequence
        __Observable__()
        function Count(self)
            return self:Aggregate(function(seed, item) return seed + 1 end, 0)
        end

        --- Returns a sequence with a single value being the min value of the source sequence
        __Observable__()
        __Arguments__{ Callable/"x,y=>x<y" }
        function Min(self, compare)
            return self:Aggregate(function(seed, item) if compare(item, seed) then return item else return seed end end)
        end

        --- Returns a sequence with a single value being the max value of the source sequence
        __Observable__()
        __Arguments__{ Callable/"x,y=>x<y" }
        function Max(self, compare)
            return self:Aggregate(function(seed, item) if compare(item, seed) then return seed else return item end end)
        end

        --- Returns a sequence with a single value being the sum value of the source sequence
        __Observable__()
        function Sum(self)
            return self:Aggregate(function(seed, item) return seed + tonumber(item) end, 0)
        end

        --- Returns a sequence with a single value being the average value of the source sequence
        __Observable__()
        function Average(self)
            return self:Aggregate(function(seed, item) seed[1], seed[2] = seed[1] + tonumber(item), seed[2] + 1 return seed end, { 0, 0 })
                :Map(function(seed) if seed[2] > 0 then return seed[1]/seed[2] end end)
        end

        --- Returns a sequence with a single value being the first value of the source sequence
        __Observable__()
        __Arguments__{ Callable/nil, Boolean/nil }
        function First(self, predicate, safe)
            return Operator(self, predicate and (safe and function(observer, ...)
                local ok, ret           = pcall(predicate, ...)
                if not ok then return observer:OnError(Exception(ret)) end

                if ret then
                    observer:OnNext(...)
                    observer:OnCompleted()
                end
            end or function(observer, ...)
                if predicate(...) then
                    observer:OnNext(...)
                    observer:OnCompleted()
                end
            end) or function(observer, ...)
                observer:OnNext(...)
                observer:OnCompleted()
            end)
        end

        --- Returns a sequence with a single value being the last value of the source sequence
        __Observable__()
        __Arguments__{ Callable/nil, Boolean/nil }
        function Last(self, predicate, safe)
            local last                  = {}

            return Operator(self, predicate and (safe and function(observer, ...)
                local ok, ret           = pcall(predicate, ...)
                if not ok then return observer:OnError(Exception(ret)) end

                if ret then
                    last[0]             = select("#", ...)
                    for i = 1, last[0] do last[i] = select(i, ...) end
                end
            end or function(observer, ...)
                if predicate(...) then
                    last[0]             = select("#", ...)
                    for i = 1, last[0] do last[i] = select(i, ...) end
                end
            end) or function(observer, ...)
                last[0]                 = select("#", ...)
                for i = 1, last[0] do last[i] = select(i, ...) end
            end, nil, function(observer)
                if last[0] then observer:OnNext(unpack(last, 1, last[0])) end
                observer:OnCompleted()
            end)
        end

        --- Returns a sequence with calculated values from the source sequence,
        -- if emits the seed, the first value will be used as the seed
        __Observable__()
        __Arguments__{ Callable, System.Any/nil, Boolean/nil }
        function Scan(self, accumulator, seed, safe)
            return Operator(self, safe and function(observer, ...)
                if seed == nil then
                    seed                = ...
                else
                    local ok, ret       = pcall(accumulator, seed, ...)
                    if not ok then observer:OnError(Exception(ret)) end
                    seed                = ret
                    observer:OnNext(seed)
                end
            end or function(observer, ...)
                if seed == nil then
                    seed                = ...
                else
                    seed                = accumulator(seed, ...)
                    observer:OnNext(seed)
                end
            end)
        end

        -----------------------------------------------------------------------
        --                           Partitioning                            --
        -----------------------------------------------------------------------
        --- Returns a sequence with groups generated by the source sequence
        __Observable__()
        __Arguments__{ Callable, Boolean/nil }
        function GroupBy(self, selector, safe)
            local groups                = Dictionary()

            return Operator(self, safe and function(observer, ...)
                    local ok, key       = pcall(selector, ...)
                    if not (ok and key ~= nil) then
                        local ex        = Exception(key or "The key selector doesn't return a value")
                        groups.Values:Each("OnError", ex)
                        return observer:OnError(ex)
                    end

                    if key ~= nil then
                        local group     = groups[key]
                        if not group then
                            group       = Subject()
                            group.Key   = key
                            groups[key] = group
                            observer:OnNext(group)
                        end
                    end

                    group:OnNext(...)
                end or function(observer, ...)
                    local key           = selector(...)
                    if key ~= nil then
                        local group     = groups[key]
                        if not group then
                            group       = Subject()
                            group.Key   = key
                            groups[key] = group
                            observer:OnNext(group)
                        end

                        group:OnNext(...)
                    end
                end,
                function(observer, exception)
                    groups.Values:Each("OnError", exception)
                    observer:OnError(exception)
                end,
                function(observer)
                    groups.Values:Each("OnCompleted")
                    observer:OnCompleted()
                end
            )
        end

        --- Returns an observable sequence containing a list of zero or more elements that have a minimum key value
        __Observable__()
        __Arguments__{ Callable, Callable/"x,y=>x<y" }
        function MinBy(self, selector, compare)
            local result                = List()
            local minkey
            return Operator(self:GroupBy(selector), function(observer, group)
                local key               = group.Key
                if minkey == nil or compare(key, minkey) then
                    minkey              = key
                    result:Clear()
                end

                group:Subscribe(function(...)
                    if minkey == key then
                        if select("#", ...) > 1 then
                            result:Insert({...})
                        else
                            result:Insert(...)
                        end
                    end
                end)
            end, nil, function(observer)
                observer:OnNext(result)
                observer:OnCompleted()
            end)
        end

        --- Returns an observable sequence containing a list of zero or more elements that have a maximum key value
        __Observable__()
        __Arguments__{ Callable, Callable/"x,y=>x<y" }
        function MaxBy(self, selector, compare)
            local result                = List()
            local maxkey
            return Operator(self:GroupBy(selector), function(observer, group)
                local key               = group.Key
                if maxkey == nil or compare(maxkey, key) then
                    maxkey              = key
                    result:Clear()
                end

                group:Subscribe(function(...)
                    if maxkey == key then
                        if select("#", ...) > 1 then
                            result:Insert({...})
                        else
                            result:Insert(...)
                        end
                    end
                end)
            end, nil, function(observer)
                observer:OnNext(result)
                observer:OnCompleted()
            end)
        end

        -----------------------------------------------------------------------
        --                          Transformation                           --
        -----------------------------------------------------------------------
        --- Returns an observable sequence with elements converted from the the
        -- source sequence
        __Observable__()
        __Arguments__{ Callable, Boolean/nil }
        function Select(self, selector, safe)
            return Operator(self, safe and function(observer, ...)
                return safeNext(observer, pcall(selector, ...))
            end or function(observer, ...)
                return observer:OnNext(selector(...))
            end)
        end
        Map                             = Select

        --- Convert the source sequence's elements into several observable
        -- sequence, then combined those child sequence to produce a final sequence
        __Observable__()
        __Arguments__{ Callable }
        function SelectMany(self, selector)
            local childobs              = {}
            local iscompleted
            local subscription

            local oper                  = Operator(self,
                function(observer, ...)
                    local ok, ret       = pcall(selector, ...)
                    if not (ok and isobjecttype(ret, IObservable)) then
                        return observer:OnError(Exception(ret or "The key selector doesn't return an observable sequence"))
                    end

                    local obs
                    obs           =  Observer(function(...)
                        observer:OnNext(...)
                    end, function(ex)
                        observer:OnError(ex)
                    end, function()
                        childobs[obs] = nil
                        if not next(childobs) and iscompleted then
                            observer:OnCompleted()
                        end
                    end)
                    childobs[obs]       = true
                    ret:Subscribe(obs, subscription)
                end,
                nil,
                function(observer)
                    iscompleted         = true
                    if not next(childobs) then
                        observer:OnCompleted()
                    end
                end
            )

            -- Hack the subscribe replace the subscription
            oper.HandleSubscription     = function(self, ...)
                subscription            = ...
            end
            return oper
        end
        FlatMap                         = SelectMany

        __Observable__()
        __Arguments__{ NEString, Boolean/nil }
        function Format(self, fmt, safe)
            return Operator(self, safe and function(observer, ...)
                return safeNext(observer, pcall(strformat, fmt, ...))
            end or function(observer, ...)
                local ok, res           = pcall(strformat, fmt, ...)
                return ok and observer:OnNext(res)
            end)
        end

        -----------------------------------------------------------------------
        --                             Combining                             --
        -----------------------------------------------------------------------
        --- Concatenates two or more observable sequences. Returns an observable
        -- sequence that contains the elements of the first sequence, followed by
        -- those of the second the sequence
        __Observable__()
        __Arguments__{ IObservable * 1 }
        function Concat(self, ...)
            local oper, subscription
            if select("#", ...) == 1 then
                local observable        = ...
                oper                    = Operator(self, nil, nil, function(observer) observable:Subscribe(observer, subscription) end)
            else
                local queue             = Queue{ ... }
                oper                    = Operator(self, nil, nil, function(observer)
                    local nxt           = queue:Dequeue()
                    if nxt then
                        return nxt:Subscribe(oper, subscription)
                    else
                        observer:OnCompleted()
                    end
                end)
            end

            oper.HandleSubscription     = function(self, ...) subscription = ... end
            return oper
        end

        --- Repeats the observable sequence indefinitely and sequentially
        __Observable__()
        __Arguments__{ NaturalNumber/nil }
        function Repeat(self, count)
            count                       = count or huge
            local times                 = 0
            local oper, subscription
            oper                        = Operator(self, nil, nil, function(observer)
                times                   = times + 1
                if times < count then
                    return self:Subscribe(oper, subscription)
                else
                    observer:OnCompleted()
                end
            end)
            oper.HandleSubscription     = function(self, ...) subscription = ... end
            return oper
        end

        --- Prefix values to a sequence
        __Observable__()
        __Arguments__{ IObservable }
        function StartWith(self, observable)
            local oper, subscription
            oper                        = Operator(observable, nil, nil, function(observer) return self:Subscribe(observer, subscription) end)
            oper.HandleSubscription     = function(self, ...) subscription = ... end
            return oper
        end

        __Observable__()
        __Arguments__{ System.Any }
        function StartWith(self, val)
            local oper, subscription
            oper                        = Operator(Observable.Just(val), nil, nil, function(observer) return self:Subscribe(observer, subscription) end)
            oper.HandleSubscription     = function(self, ...) subscription = ... end
            return oper
        end

        __Observable__()
        __Arguments__{ System.Any * 2 }
        function StartWith(self, ...)
            local oper, subscription
            oper                        = Operator(Observable.From(List{ ... }), nil, nil, function(observer) return self:Subscribe(observer, subscription) end)
            oper.HandleSubscription     = function(self, ...) subscription = ... end
            return oper
        end

        --- Return values from the sequence that is first to produce values, and ignore the other sequences
        __Observable__()
        __Static__() __Arguments__{ IObservable * 2 }
        function Observable.Amb(...)
            local observables           = { ... }
            return Observable(function(observer, subscription)
                local choosed
                local obslist           = {}
                local completed         = 0
                for i, observable in ipairs(observables) do
                    if choosed then break end

                    local subobs        = Observer(function(...)
                        if not choosed then
                            choosed     = i
                            for j = 1, #obslist do
                                if j ~= i then
                                    obslist[j].Subscription:Dispose()
                                end
                            end
                        end
                        return choosed == i and observer:OnNext(...)
                    end, function(ex)
                        return choosed == i and observer:OnError(ex)
                    end, function()
                        completed       = completed + 1
                        return (choosed == i or completed == #obslist) and observer:OnCompleted()
                    end, subscription)
                    obslist[#obslist+1] = subobs
                    observable:Subscribe(subobs, subobs.Subscription)
                end
            end)
        end

        --- Merge multi sequence, their results will be merged as the result sequence
        __Observable__()
        __Static__() __Arguments__{ IObservable * 2 }
        function Observable.Merge(...)
            local observables           = { ... }
            return Observable(function(observer, subscription)
                local completed         = 0
                for i, observable in ipairs(observables) do
                    local subobs        = Observer(function(...)
                        return observer:OnNext(...)
                    end, function(ex)
                        return observer:OnError(ex)
                    end, function()
                        completed       = completed + 1
                        return completed == #observables and observer:OnCompleted()
                    end, subscription)
                    observable:Subscribe(subobs, subobs.Subscription)
                end
            end)
        end
        Merge                           = Observable.Merge

        --- Switch will subscribe to the outer sequence and as each inner sequence is
        -- yielded it will subscribe to the new inner sequence and dispose of the subscription to the previous inner sequence
        __Observable__()
        __Static__() __Arguments__{ IObservable * 2 }
        function Observable.Switch(...)
            local observables           = { ... }
            return Observable(function(observer, subscription)
                local removed           = 0
                local current           = 0
                local obslist           = {}
                local completed         = 0
                for i, observable in ipairs(observables) do
                    local subobs        = Observer(function(...)
                        if i > current then
                            current     = i
                            while removed + 1 < current do
                                removed = removed + 1
                                obslist[removed].Subscription:Dispose()
                            end
                        end
                        return current == i and observer:OnNext(...)
                    end, function(ex)
                        return current == i and observer:OnError(ex)
                    end, function()
                        completed       = completed + 1
                        return (current == i or completed == #obslist) and observer:OnCompleted()
                    end, subscription)
                    obslist[#obslist+1] = subobs
                    observable:Subscribe(subobs, subobs.Subscription)
                end
            end)
        end
        Switch                          = Observable.Switch

        --- The CombineLatest extension method allows you to take the most recent value from two sequences, and with a given
        --- function transform those into a value for the result sequence
        __Arguments__{ IObservable, Callable/nil }
        function CombineLatest(self, other, resultSelector)
            return Observable(function(observer, subscription)
                local cache             = {}
                local start, stop

                local complete          = function() return observer:OnCompleted() end

                local process           = resultSelector
                    and function() return start and stop and safeNext(observer, pcall(resultSelector, unpack(cache, start, stop))) end
                    or  function() return start and stop and observer:OnNext(unpack(cache, start, stop)) end

                -- Observer to self
                local left              = Observer(function(...)
                    local count         = select("#", ...)
                    start               = 1

                    for i = 0, count - 1 do
                        start           = start - 1
                        cache[start]    = select(count - i, ...)
                    end

                    return process()
                end, nil, complete)
                left.Subscription       = subscription

                -- Observer to other
                local right             = Observer(function(...)
                    local count         = select("#", ...)
                    stop                = count
                    for i = 1, count do
                        cache[i]        = select(i, ...)
                    end
                    return process()
                end, nil, complete)
                right.Subscription       = subscription

                self:Subscribe(left, subscription)
                other:Subscribe(right, subscription)
            end)
        end

        --- Combine the parameters
        combineRightQueueParams         = setmetatable(
            {
                [0]                     = function(queue, count) return queue:Dequeue(count) end
            },
            {
                __index = function(self, count)
                    local args          = XList(count):Map("i=>'arg'..i"):Join(",")
                    local func          = loadsnippet([[
                        return function(queue, count, ]] .. args .. [[)
                            return ]] .. args .. [[, queue:Dequeue(count)
                        end
                    ]], "Combine_RightQueue_" .. count, _ENV)()
                    rawset(self, count, func)
                    return func
                end
            }
        )
        combineLeftQueueParams          = setmetatable(
            {
                [0]                     = function(queue, count) return queue:Dequeue(count) end
            },
            {
                __index = function(self, count)
                    local args          = XList(count):Map("i=>'arg'..i"):Join(",")
                    local func          = loadsnippet([[
                        return function(queue, ...)
                            local ]] .. args .. [[ = queue:Dequeue(]] .. count ..[[)
                            return ]] .. args .. [[, ...
                        end
                    ]], "Combine_LeftQueue_" .. count, _ENV)()
                    rawset(self, count, func)
                    return func
                end
            }
        )

        --- the Zip method brings together two sequences of values as pairs
        __Arguments__{ IObservable, Callable/nil }
        function Zip(self, other, resultSelector)
            return Observable(function(observer, subscription)
                local queuea            = Queue()
                local queueb            = Queue()
                local complete          = function() return observer:OnCompleted() end

                -- Observer to self
                local left              = Observer(function(...)
                    local count         = select("#", ...)
                    local second        = queueb:Dequeue()
                    if second == nil then
                        queuea:Enqueue(count, ...)
                    else
                        local func      = combineRightQueueParams[count]
                        if resultSelector then
                            safeNext(observer, pcall(resultSelector, func(queueb, second, ...)))
                        else
                            observer:OnNext(func(queueb, second, ...))
                        end
                    end
                end, nil, complete)
                left.Subscription       = subscription

                -- Observer to other
                local right             = Observer(function(...)
                    local count         = select("#", ...)
                    local first         = queuea:Dequeue()
                    if first == nil then
                        queueb:Enqueue(count, ...)
                    else
                        local func      = combineLeftQueueParams[first]
                        if resultSelector then
                            safeNext(observer, pcall(resultSelector, func(queuea, ...)))
                        else
                            observer:OnNext(func(queuea, ...))
                        end
                    end
                end, nil, complete)
                right.Subscription       = subscription

                self:Subscribe(left, subscription)
                other:Subscribe(right, subscription)
            end)
        end

        --- combine items emitted by two Observables whenever an item from one
        -- Observable is emitted during a time window defined according to an
        -- item emitted by the other Observable
        __Observable__()
        __Arguments__{ IObservable, Callable, Callable, Callable/nil }
        function Join(self, right, leftDurationSelector, rightDurationSelector, resultSelector)
            return Observable(function(observer, subscription)
                local lefthead, lefttail
                local righthead, righttail
                local canComplete       = false
                local onError           = function(ex) return observer:OnError(ex) end
                local onCompleted       = function()
                    if canComplete then
                        return observer:OnCompleted()
                    else
                        canComplete     = true
                    end
                end

                local join              = function(newLeft, newRight)
                    newLeft             = newLeft or lefthead

                    while newLeft do
                        local right     = newRight or righthead

                        while right do
                            if resultSelector then
                                observer:OnNext(resultSelector(combinearray(newLeft, right)))
                            else
                                observer:OnNext(combinearray(newLeft, right))
                            end

                            right       = right.NextWin
                        end

                        newLeft         = newLeft.NextWin
                    end
                end

                local leftObs           = Observer(function(...)
                        -- Open window
                        local ok, selector = pcall(leftDurationSelector, ...)
                        if not ok then  return onError(Exception(selector)) end
                        if not isobjecttype(selector, IObservable) then return onError(Exception("The selector doesn't return a valid value")) end

                        local window
                        local closeWin  = function()
                            if window.PrevWin then
                                window.PrevWin.NextWin = window.NextWin
                            else
                                lefthead = window.NextWin
                            end
                            if lefttail == window then
                                lefttail = window.PrevWin
                            end
                            window.PrevWin = nil
                            window.NextWin = nil
                            return window.Subscription:Dispose()
                        end
                        window          = Observer(closeWin, onError, closeWin, subscription)

                        -- Keep the data
                        local count     = select("#", ...)
                        if count <= 2 then
                            window[1], window[2] = ...
                        else
                            for i = 1, count do
                                window[i] = select(i, ...)
                            end
                        end

                        -- Link the window
                        if lefttail then
                            window.PrevWin  = lefttail
                            lefttail.NextWin= window
                            lefttail    = window
                        else
                            lefthead    = window
                            lefttail    = window
                        end

                        -- Subscribe the duration observable
                        selector:Subscribe(window, window.Subscription)
                        return join(window)
                    end,
                    onError,
                    onCompleted)
                leftObs.Subscription    = subscription

                local rightObs          = Observer(function(...)
                        -- Open window
                        local ok, selector = pcall(rightDurationSelector, ...)
                        if not ok then  return onError(Exception(selector)) end
                        if not isobjecttype(selector, IObservable) then return onError(Exception("The selector doesn't return a valid value")) end

                        local window
                        local closeWin  = function()
                            if window.PrevWin then
                                window.PrevWin.NextWin = window.NextWin
                            else
                                righthead = window.NextWin
                            end
                            if righttail == window then
                                righttail = window.PrevWin
                            end
                            window.PrevWin = nil
                            window.NextWin = nil
                            return window.Subscription:Dispose()
                        end
                        window          = Observer(closeWin, onError, closeWin, subscription)

                        -- Keep the data
                        local count     = select("#", ...)
                        if count <= 2 then
                            window[1], window[2] = ...
                        else
                            for i = 1, count do
                                window[i] = select(i, ...)
                            end
                        end

                        -- Link the window
                        if righttail then
                            window.PrevWin   = righttail
                            righttail.NextWin= window
                            righttail   = window
                        else
                            righthead   = window
                            righttail   = window
                        end

                        -- Subscribe the duration observable
                        selector:Subscribe(window, window.Subscription)
                        return join(nil, window)
                    end,
                    onError,
                    onCompleted)
                rightObs.Subscription   = subscription

                -- Start
                self:Subscribe(leftObs, subscription)
                right:Subscribe(rightObs, subscription)
            end)
        end

        -----------------------------------------------------------------------
        --                               Plan                                --
        -----------------------------------------------------------------------
        Pattern                         = __Sealed__() class "Pattern" {}
        Plan                            = __Sealed__() class "Plan"    {}

        __Arguments__{ IObservable * 1 }
        function And(self, ...)
            return Pattern{ self, ... }
        end

        __Arguments__{ IObservable * 1 }
        function Pattern:And(...)
            for i = 1, select("#", ...) do
                tinsert(self, (select(i, ...)))
            end
            return self
        end

        __Arguments__{ Callable/nil }
        function Pattern:Then(resultSelector)
            return Plan{ self, resultSelector or false }
        end

        -- @todo: Multi-os thread support
        __Static__() __Arguments__{ Plan }
        function Observable.When(plan)
            return Observable(function(observer, subscription)
                local sequences         = plan[1]
                local selector          = plan[2]
                local total             = #sequences
                local queues            = List(total, function() return Queue() end)
                local onError           = function(ex) return observer:OnError(ex) end
                local count             = 0
                local completed         = 0

                local process           = function(index)
                    count               = count + 1

                    if count == total then
                        local rs        = Queue()

                        queues:Each(function(queue)
                            rs:Enqueue(queue:Dequeue(queue:Dequeue()))
                            if queue:Peek() == nil then count = count - 1 end
                        end)

                        if selector then
                            safeNext(observer, pcall(selector, rs:Dequeue(rs.Count)))
                        else
                            observer:OnNext(rs:Dequeue(rs.Count))
                        end
                    end
                end

                -- Subscribe the sequences
                for i = 1, total do
                    sequences[i]:Subscribe(Observer(
                        function(...)
                            local isnew = queues[i]:Peek() == nil
                            queues[i]:Enqueue(select("#", ...), ...)
                            if isnew then return process(j) end
                        end,
                        onError,
                        function()
                            completed   = completed + 1
                            return (completed == total or queues[i]:Peek() == nil) and observer:OnCompleted()
                        end
                    ), subscription)
                end
            end)
        end

        -----------------------------------------------------------------------
        --                           Time-shifted                            --
        -----------------------------------------------------------------------
        --- The Buffer operator allows you to store away a range of values and then
        -- re-publish them as a list once the buffer is full
        __Observable__()
        __Arguments__{ NaturalNumber, NaturalNumber/nil }
        function Buffer(self, total, skip)
            local queue                 = Queue()
            skip                        = skip or total
            local skipcnt               = 0

            return Operator(self, function(observer, ...)
                queue:Enqueue(...)

                local qcnt              = queue.Count

                while qcnt > 0 do
                    if skipcnt > 0 then
                        local dcnt      = qcnt < skipcnt and qcnt or skipcnt
                        queue:Dequeue(dcnt)
                        skipcnt         = skipcnt - dcnt
                        qcnt            = qcnt - dcnt
                    end

                    if qcnt >= total then
                        observer:OnNext(List{ queue:Peek(total) })

                        if qcnt >= skip then
                            queue:Dequeue(skip)
                            qcnt        = qcnt - skip
                        else
                            queue:Dequeue(qcnt)
                            skipcnt     = skip - qcnt
                            qcnt        = 0
                        end
                    else
                        break
                    end
                end
            end, nil, function(observer)
                local qcnt              = queue.Count
                if qcnt > skipcnt then
                    if skipcnt > 0 then queue:Dequeue(skipcnt) end
                    observer:OnNext(List{ queue:Dequeue(qcnt - skipcnt) })
                end
                observer:OnCompleted()
            end)
        end

        --- periodically subdivide items from an Observable into Observable windows
        -- and emit these windows rather than emitting the items one at a time
        __Observable__()
        __Arguments__{ NaturalNumber, NaturalNumber/nil }
        function Window(self, total, skip)
            skip                        = skip or total

            local queue                 = Queue()
            local skipcnt               = 0
            local sendcnt               = 0
            local currsub
            local curroff               = 1
            local queuecnt              = 0

            return Operator(self, function(observer, ...)
                queue:Enqueue(select("#", ...), ...)
                queuecnt                = queuecnt + 1

                if skipcnt > 0 then
                    local dcnt          = queuecnt < skipcnt and queuecnt or skipcnt
                    for i = 1, dcnt do
                        queue:Dequeue(queue:Dequeue())
                    end
                    skipcnt             = skipcnt - dcnt
                    queuecnt            = queuecnt - dcnt

                    if queuecnt == 0 then return end
                end

                if sendcnt == 0 then
                    if currsub then currsub:OnCompleted() end

                    currsub             = Subject()
                    observer:OnNext(currsub)
                end

                while sendcnt < total do
                    local length        = queue:Peek(curroff, 1)
                    if not length then return end

                    sendcnt             = sendcnt + 1
                    currsub:OnNext(queue:Peek(curroff + 1, length))
                    curroff             = curroff + 1 + length
                end

                skipcnt                 = skip
                sendcnt                 = 0
                curroff                 = 1
            end, function(observer, ex)
                if currsub then currsub:OnError(ex) end
                observer:OnError(ex)
            end, function(observer)
                if currsub then currsub:OnCompleted() end
                observer:OnCompleted()
            end)
        end

        __Observable__()
        __Arguments__{ IObservable }
        function Window(self, sampler)
            local currsub

            local oper                  = Operator(self,
                function(observer, ...)
                    if not currsub then
                        currsub         = Subject()
                        observer:OnNext(currsub)
                    end

                    currsub:OnNext(...)
                end,
                function(observer, ex)
                    return currsub and currsub:OnError(ex) or observer:OnError(ex)
                end,
                function(observer)
                    if currsub then currsub:OnCompleted() end
                    observer:OnCompleted()
                end
            )

            local operSampler           = Operator(sampler,
                function(observer, ...)
                    if currsub then currsub:OnCompleted() end

                    currsub             = Subject()
                    observer:OnNext(currsub)
                end,
                onError,
                function(observer) end
            )

            -- Start other sampler observable
            oper.HandleSubscription     = function(self, subscription, observer)
                operSampler:Subscribe(observer, subscription)
            end

            return oper
        end

        --- Returns a new Observable that produces its most recent value every time
        -- the specified observable produces a value
        __Observable__()
        __Arguments__{ IObservable }
        function Sample(self, sampler)
            local queue                 = Queue()
            local completed

            local oper                  = Operator(self, function(observer, ...)
                    queue:Clear()
                    queue:Enqueue(...)
                end, nil, function(observer)
                    if completed then observer:OnCompleted() end
                    completed           = true
                end
            )

            local operSampler           = Operator(sampler, function(observer, ...)
                local count             = queue.Count
                if count > 0 then
                    observer:OnNext(queue:Dequeue(count))
                end
            end, nil, function(observer)
                local count             = queue.Count
                if count > 0 then
                    observer:OnNext(queue:Dequeue(count))
                end
                if completed then observer:OnCompleted() end
                completed               = true
            end)

            -- Start other sampler observable
            oper.HandleSubscription     = function(self, subscription, observer)
                operSampler:Subscribe(observer, subscription)
            end

            return oper
        end

        --- Ignores values from an observable sequence which are followed by another value before dueTime
        if otime then
            __Observable__()
            __Arguments__{ Number }
            function Throttle(self, dueTime)
                local lasttime          = 0

                return Operator(self, function(observer, ...)
                    local curr          = otime()
                    if curr - lasttime > dueTime then
                        lasttime        = curr
                        observer:OnNext(...)
                    end
                end)
            end
            Debounce                    = Throttle
        end

        -----------------------------------------------------------------------
        --                        Publish and Connect                        --
        -----------------------------------------------------------------------
        --- Convert an ordinary Observable into a connectable Observable
        function Publish(self)
            return PublishSubject(self)
        end

        --- Ensure that all observers see the same sequence of emitted items, even if they subscribe after the Observable has begun emitting items
        __Arguments__{ NaturalNumber/nil }
        function Replay(self, size)
            return ReplaySubject(self, size)
        end

        --- Convert to a subject
        __Arguments__{ -Subject/Subject, System.Any * 0 }
        function ToSubject(self, subjecttype, ...)
            return subjecttype(self, ...)
        end
    end)
end)