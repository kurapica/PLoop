--===========================================================================--
--                                                                           --
--                         System.Reactive.Operator                          --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2019/12/04                                               --
-- Update Date  :   2020/11/23                                               --
-- Version      :   1.0.1                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Reactive"

    --- The basic observable sequence operator
    __Sealed__()
    class "Operator"                    (function(_ENV)
        extend "System.IObservable" "System.IObserver"

        export { Observable, Observer, Operator }

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- The observable that provides the items
        property "Observable"           { type = IObservable }

        --- The observer that will consume the items
        property "Observer"             { type = IObserver }

        --- The operator that controls the refer observable sequence
        property "RefOperator"          { type = Operator }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        local function subscribe(self, observer)
            -- Normally the Operator can't be re-used
            if self.IsUnsubscribed then return end

            self.Observer               = observer

            local onUnsubscribe
            onUnsubscribe               = function()
                observer.OnUnsubscribe  = observer.OnUnsubscribe - onUnsubscribe
                self:Unsubscribe()
            end
            observer.OnUnsubscribe      = observer.OnUnsubscribe + onUnsubscribe

            self.Observable:Subscribe(self)
            if self.RefOperator then self.RefOperator:Subscribe(observer) end

            return observer
        end

        --- Notifies the provider that an observer is to receive notifications.
        __Arguments__{ IObserver }
        Subscribe                       = subscribe

        __Arguments__{ Callable/nil, Callable/nil, Callable/nil }
        function Subscribe(self, onNext, onError, onCompleted)
            return subscribe(self, Observer(onNext, onError, onCompleted))
        end

        function OnNextCore(self, ...)  return self:OnNext(...) end
        function OnErrorCore(self, e)   return self:OnError(e) end
        function OnCompletedCore(self)  return self:OnCompleted() end

        --- Provides the observer with new data
        function OnNext(self, ...)      return not self.IsUnsubscribed and self.OnNextCore(self.Observer, ...) end

        --- Notifies the observer that the provider has experienced an error condition
        function OnError(self,exception)return not self.IsUnsubscribed and self.OnErrorCore(self.Observer, exception) end

        --- Notifies the observer that the provider has finished sending push-based notifications
        function OnCompleted(self)      return not self.IsUnsubscribed and self.OnCompletedCore(self.Observer) end

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        __Arguments__{ IObservable, Callable/nil, Callable/nil, Callable/nil, Operator/nil }
        function __ctor(self, observable, onNext, onError, onCompleted, refOperator)
            self.Observable             = observable
            self.OnNextCore             = onNext
            self.OnErrorCore            = onError
            self.OnCompletedCore        = onCompleted
            self.RefOperator            = refOperator
        end
    end)

    -- Method Extension
    interface (IObservable) (function(_ENV)
        export {
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
            strformat                   = string.format,
            loadsnippet                 = Toolset.loadsnippet,
            tostringall                 = Toolset.tostringall,
            otime                       = _G.os and (os.clock or os.time) or false,
            unpack                      = _G.unpack or table.unpack,
            isObjectType                = Class.IsObjectType,
            running                     = coroutine.running,
            yield                       = coroutine.yield,
            resume                      = coroutine.resume,
            status                      = coroutine.status,

            Info                        = Logger.Default[Logger.LogLevel.Info],

            RunWithLock                 = ILockManager.RunWithLock,

            LOCK_KEY                    = "PLOOP_RX_%s",

            Operator, IObservable, Observer, Observable, Threading, Guid, Exception, Dictionary, Queue, List,
            PublishSubject, ReplaySubject, Subject
        }

        local function safeNext(observer, flag, item, ...)
            if flag and item ~= nil then
                return observer:OnNext(item, ...)
            else
                return observer:OnError(Exception(item or "No value returned"))
            end
        end

        -----------------------------------------------------------------------
        --                               Tool                                --
        -----------------------------------------------------------------------
        --- Dump the sequence
        __Arguments__{ NEString/"Dump" }
        function Dump(self, name)
            self:Subscribe(function(...)
                Info("%s-->%s", name, List{ tostringall(...) }:Join(", "))
            end, function(ex)
                Info("%s failed-->%s", name, tostring(ex))
            end, function()
                Info("%s completed", name)
            end)
        end

        --- Process all elements as they arrived, works like the Subscribe, but will block the current coroutine
        __Arguments__{ Callable, Callable/nil, Callable/nil }
        function ForEach(self, onNext, onError, onCompleted)
            local curr, main            = running()
            if not curr or main then return self:Subscribe(onNext, onError, onCompleted) end

            local finished

            self:Subscribe(onNext, function(ex)
                finished                = true
                if onError then onError(ex) end
                return resume(curr)
            end, function()
                finished                = true
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

                    self:Subscribe(function(...)
                        queue(select("#", ...), ...)
                        if status(curr) == "suspended" then
                            resume(curr, queue:Dequeue(queue:Dequeue()))
                        end
                    end, function(ex)
                        finished        = ex
                        if status(curr) == "suspended" then
                            resume(curr, nil, ex)
                        end
                    end, function()
                        finished        = true
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
        function AsObservable(self)
            return Observable(function(observer) return self:Subscribe(observer) end)
        end

        --- Invokes actions with side effecting behavior for each element in the observable sequence
        __Observable__()
        __Arguments__{ Callable, Callable/nil, Callable/nil }
        function Do(self, onNext, onError, onCompleted)
            return Operator(self, function(observer, ...)
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
            return Operator(self, nil, function(observer, ex)
                local ok, ret           = pcall(onError, ex)
                if not (ok and isObjectType(ret, IObservable)) then
                    observer:OnError(ex)
                else
                    return ret:Subscribe(observer)
                end
            end)
        end

        --- Process operations when the sequence is completed, error or unsubscribed
        __Observable__()
        __Arguments__{ Callable }
        function Finally(self, finally)
            local oper                  = Operator(self)
            oper.OnUnsubscribe          = oper.OnUnsubscribe + finally
            return oper
        end

        --- Start the next observable sequence when the sequence is failed or completed
        __Observable__()
        __Arguments__{ IObservable }
        function OnErrorResumeNext(self, observable)
            local resume                = function(observer) observable:Subscribe(observer) end
            return Operator(self, nil, resume, resume)
        end

        --- Retry the sequence if failed
        __Observable__()
        __Arguments__{ NaturalNumber/nil }
        function Retry(self, count)
            count                       = count or huge
            local times                 = 0
            return Operator(self, nil, function(observer, ex)
                times                   = times + 1

                if times > count then
                    observer:OnError(ex)
                end
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
                return Operator(self, function(observer, ...)
                    if condition(...) then return observer:OnNext(...) end
                end)
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
                    observer:OnNext(...)
                else
                    observer:OnCompleted()
                end
            end)
        end

        --- Take all values that match the prefix elements
        local _MatchPrefixGen           = setmetatable({}, {
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
            }
        )
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
            return Operator(self, predicate and (
                safe and function(observer, ...)
                    local ok, ret       = pcall(predicate, ...)
                    if not ok then return observer:OnError(Exception(ret)) end

                    if ret then
                        observer:OnNext(true)
                        observer:OnCompleted()
                    end
                end or function(observer, ...)
                    if predicate(...) then
                        observer:OnNext(true)
                        observer:OnCompleted()
                    end
                end) or function(observer, ...)
                    observer:OnNext(true)
                    observer:OnCompleted()
                end,
                nil, function(observer)
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
        local _ContainsGen              = setmetatable({}, {
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
            }
        )
        __Observable__()
        __Arguments__{ System.Any * 1 }
        function Contains(self, ...)
            return _ContainsGen[select("#", ...)](self, ...)
        end

        --- Returns a sequence with single default value if the target observable sequence doesn't contains any item
        local _DefaultGen               = setmetatable({}, {
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
            }
        )
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
                    return observer:OnError(Exception("The sequence doesn't provide any elements"))
                else
                    return observer:OnCompleted()
                end
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
                    return observer:OnCompleted()
                end

                for i = 1, fcount do
                    if not compare(fqueue:Dequeue(), squeue:Dequeue()) then
                        observer:OnNext(false)
                        return observer:OnCompleted()
                    end
                end
            end

            local complete              = function(observer)
                if iscomp then
                    while not observer.IsUnsubscribed and squeue:Peek() and fqueue:Peek() do
                        compareQueue(observer)
                    end

                    if not observer.IsUnsubscribed then
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

            return Operator(self,
                function(observer, ...)
                    fqueue(select("#", ...), ...)
                    return squeue:Peek() and compareQueue(observer)
                end, nil, complete,
                -- The other sequence
                Operator(other,
                    function(observer, ...)
                        squeue(select("#", ...), ...)
                        return fqueue:Peek() and compareQueue(observer)
                    end, nil, complete
                )
            )
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

            return Operator(self,
                function(observer, ...)
                    local ok,ret        = pcall(selector, ...)
                    if not (ok and isObjectType(ret, IObservable)) then
                        local ex        = Exception(ret or "The key selector doesn't return an observable sequence")
                        for key in pairs(childobs) do
                            key:Unsubscribe()
                        end
                        return observer:OnError(ex)
                    end

                    local obs
                    obs                 = Observer(function(...)
                        observer:OnNext(...)
                    end, function(ex)
                        for key in pairs(childobs) do
                            key:Unsubscribe()
                        end
                        observer:OnError(ex)
                    end, function()
                        childobs[obs]   = nil
                        if not next(childobs) and iscompleted then
                            observer:OnCompleted()
                        end
                    end)
                    childobs[obs]       = true
                    ret:Subscribe(obs)
                end,
                function(observer, ex)
                    for key in pairs(childobs) do
                        key:Unsubscribe()
                    end
                    observer:OnError(ex)
                end,
                function(observer)
                    iscompleted         = true
                    if not next(childobs) then observer:OnCompleted() end
                end
            )
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
            if select("#", ...) == 1 then
                local observable        = ...
                return Operator(self, nil, nil, function(observer) observable:Subscribe(observer) end)
            else
                local queue             = Queue{ ... }

                local oper
                oper                    = Operator(self, nil, nil, function(observer)
                    local nxt           = queue:Dequeue()
                    if nxt then
                        return nxt:Subscribe(oper)
                    else
                        observer:OnCompleted()
                    end
                end)
                return oper
            end
        end

        --- Repeats the observable sequence indefinitely and sequentially
        __Observable__()
        __Arguments__{ NaturalNumber/nil }
        function Repeat(self, count)
            count                       = count or huge
            local times                 = 0
            local oper
            oper                        = Operator(self, nil, nil, function(observer)
                times                   = times + 1
                if times < count then
                    return self:Subscribe(oper)
                else
                    observer:OnCompleted()
                end
            end)
            return oper
        end

        --- Prefix values to a sequence
        __Observable__()
        __Arguments__{ IObservable }
        function StartWith(self, observable)
            return Operator(observable, nil, nil, function(observer)
                return self:Subscribe(observer)
            end)
        end

        __Observable__()
        __Arguments__{ System.Any * 2 }
        function StartWith(self, ...)
            return Operator(Observable.From(List{ ... }), nil, nil, function(observer)
                return self:Subscribe(observer)
            end)
        end

        __Observable__()
        __Arguments__{ System.Any }
        function StartWith(self, val)
            return Operator(Observable.Just(val), nil, nil, function(observer)
                return self:Subscribe(observer)
            end)
        end

        --- Return values from the sequence that is first to produce values, and ignore the other sequences
        __Observable__()
        __Static__() __Arguments__{ IObservable * 2 }
        function Observable.Amb(...)
            local observables           = { ... }
            local choosed
            local subjects              = {}
            local rcompleted

            return Operator(Observable.Range(1, #observables),
                function(observer, index)
                    if choosed then return end
                    local subject
                    subject             = Subject(observables[index], function(nobserver, ...)
                            if choosed == subject then
                                nobserver:OnNext(...)
                            elseif not choosed then
                                choosed = subject
                                for o in pairs(subjects) do
                                    if o ~= subject then o:Unsubscribe() end
                                end
                                nobserver:OnNext(...)
                            else
                                subject:Unsubscribe()
                            end
                        end, function(nobserver, ex)
                            if choosed == subject then
                                nobserver:OnError(ex)
                            elseif not choosed then
                                subjects[subject] = nil
                                if rcompleted and not next(subjects) then
                                    nobserver:OnError(ex)
                                end
                            end
                        end, function(nobserver)
                            if choosed == subject then
                                nobserver:OnCompleted()
                            elseif not choosed then
                                subjects[subject] = nil
                                if rcompleted and not next(subjects) then
                                    nobserver:OnCompleted()
                                end
                            end
                        end
                    )

                    subjects[subject]   = true
                    subject:Subscribe(observer)
                end,
                function(observer, ex)
                    rcompleted          = true
                    if not next(subjects) then
                        observer:OnError(ex)
                    end
                end,
                function(observer)
                    rcompleted          = true
                    if not next(subjects) then
                        observer:OnCompleted()
                    end
                end
            )
        end
        Amb                             = Observable.Amb

        --- Merge multi sequence, their results will be merged as the result sequence
        __Observable__()
        __Static__() __Arguments__{ IObservable * 2 }
        function Observable.Merge(...)
            local observables           = { ... }
            local subjects              = {}
            local rcompleted

            return Operator(Observable.Range(1, #observables),
                function(observer, index)
                    local subject
                    subject             = Subject(observables[index], nil, nil, function(nobserver)
                            subjects[subject] = nil
                            if rcompleted and not next(subjects) then
                                nobserver:OnCompleted()
                            end
                        end
                    )

                    subjects[subject]   = true
                    subject:Subscribe(observer)
                end,
                function(observer, ex)
                    rcompleted          = true
                    if not next(subjects) then
                        observer:OnError(ex)
                    end
                end,
                function(observer)
                    rcompleted          = true
                    if not next(subjects) then
                        observer:OnCompleted()
                    end
                end
            )
        end
        Merge                           = Observable.Merge

        --- Switch will subscribe to the outer sequence and as each inner sequence is
        -- yielded it will subscribe to the new inner sequence and dispose of the subscription to the previous inner sequence
        __Observable__()
        __Static__() __Arguments__{ IObservable * 2 }
        function Observable.Switch(...)
            local observables           = { ... }
            local choosed               = 0
            local subjects              = {}
            local rcompleted

            return Operator(Observable.Range(1, #observables),
                function(observer, index)
                    local subject
                    subject             = Subject(observables[index], function(nobserver, ...)
                            if choosed == index then
                                nobserver:OnNext(...)
                            elseif choosed < index then
                                if choosed > 0 then
                                    subjects[choosed]:Unsubscribe()
                                    subjects[choosed] = nil
                                end
                                choosed = index
                                nobserver:OnNext(...)
                            else
                                subjects[index] = nil
                                subject:Unsubscribe()
                            end
                        end, function(nobserver, ex)
                            if index >= choosed then
                                for k, v in pairs(subjects) do
                                    v:Unsubscribe()
                                end
                                nobserver:OnError(ex)
                            end
                        end, function(nobserver)
                            subjects[index] = nil
                            if rcompleted and not next(subjects) then
                                nobserver:OnCompleted()
                            end
                        end
                    )

                    subjects[index]     = subject
                    subject:Subscribe(observer)
                end,
                function(observer, ex)
                    rcompleted          = true
                    if not next(subjects) then
                        observer:OnError(ex)
                    end
                end,
                function(observer)
                    rcompleted          = true
                    if not next(subjects) then
                        observer:OnCompleted()
                    end
                end
            )
        end
        Switch                          = Observable.Switch

        --- The CombineLatest extension method allows you to take the most recent value from two sequences, and with a given
        --- function transform those into a value for the result sequence
        __Arguments__{ IObservable, Callable/nil }
        function CombineLatest(self, secseq, resultSelector)
            return Observable(function(observer)
                local cache             = {}
                local start, stop
                local completed

                local complete          = function(observer)
                    if completed then
                        observer:OnCompleted()
                    else
                        completed       = true
                    end
                end

                local process           = resultSelector and function(observer)
                    if start and stop then
                        safeNext(observer, pcall(resultSelector, unpack(cache, start, stop)))
                    end
                end or function(observer)
                    if start and stop then
                        observer:OnNext(unpack(cache, start, stop))
                    end
                end

                Subject(self, function(observer, ...)
                    local count         = select("#", ...)
                    start               = 1

                    for i = 0, count - 1 do
                        start           = start - 1
                        cache[start]    = select(count - i, ...)
                    end

                    return process(observer)
                end, nil, complete):Subscribe(observer)

                Subject(secseq, function(observer, ...)
                    local count         = select("#", ...)
                    stop                = count
                    for i = 1, count do
                        cache[i]        = select(i, ...)
                    end
                    return process(observer)
                end, nil, complete):Subscribe(observer)
            end)
        end

        --- the Zip method brings together two sequences of values as pairs
        __Arguments__{ IObservable, Callable/nil }
        function Zip(self, secseq, resultSelector)
            return Observable(function(observer)
                local queuea            = Queue()
                local queueb            = Queue()
                local completed

                local complete          = function(observer)
                    if completed then
                        observer:OnCompleted()
                    else
                        completed       = true
                    end
                end

                Subject(self, function(observer, ...)
                    local count         = select("#", ...)
                    local second        = queueb:Dequeue()
                    if second == nil then
                        queuea:Enqueue(count, ...)
                    else
                        if count == 1 then
                            local a1    = ...
                            if resultSelector then
                                safeNext(observer, pcall(resultSelector, a1, queueb:Dequeue(second)))
                            else
                                observer:OnNext(a1, queueb:Dequeue(second))
                            end
                        elseif count == 2 then
                            local a1, a2= ...
                            if resultSelector then
                                safeNext(observer, pcall(resultSelector, a1, a2, queueb:Dequeue(second)))
                            else
                                observer:OnNext(a1, a2, queueb:Dequeue(second))
                            end
                        elseif count == 3 then
                            local a1, a2, a3 = ...
                            if resultSelector then
                                safeNext(observer, pcall(resultSelector, a1, a2, a3, queueb:Dequeue(second)))
                            else
                                observer:OnNext(a1, a2, a3, queueb:Dequeue(second))
                            end
                        else
                            local q     = Queue():Enqueue(...):Enqueue(queueb:Dequeue(second))
                            if resultSelector then
                                safeNext(observer, pcall(resultSelector, q:Dequeue(q.Count)))
                            else
                                observer:OnNext(q:Dequeue(q.Count))
                            end
                        end
                    end
                end, nil, complete):Subscribe(observer)

                Subject(secseq, function(observer, ...)
                    local count         = select("#", ...)
                    local first         = queuea:Dequeue()
                    if first == nil then
                        queueb:Enqueue(count, ...)
                    else
                        if first == 1 then
                            local a1    = queuea:Dequeue(first)
                            if resultSelector then
                                safeNext(observer, pcall(resultSelector, a1, ...))
                            else
                                observer:OnNext(a1, ...)
                            end
                        elseif first == 2 then
                            local a1, a2= queuea:Dequeue(first)
                            if resultSelector then
                                safeNext(observer, pcall(resultSelector, a1, a2, ...))
                            else
                                observer:OnNext(a1, a2, ...)
                            end
                        elseif first == 3 then
                            local a1, a2, a3 = queuea:Dequeue(first)
                            if resultSelector then
                                safeNext(observer, pcall(resultSelector, a1, a2, a3, ...))
                            else
                                observer:OnNext(a1, a2, a3, ...)
                            end
                        else
                            local q     = Queue():Enqueue(queuea:Dequeue(first)):Enqueue(...)
                            if resultSelector then
                                safeNext(observer, pcall(resultSelector, q:Dequeue(q.Count)))
                            else
                                observer:OnNext(q:Dequeue(q.Count))
                            end
                        end
                    end
                end, nil, complete):Subscribe(observer)
            end)
        end

        --- combine items emitted by two Observables whenever an item from one
        -- Observable is emitted during a time window defined according to an
        -- item emitted by the other Observable
        __Observable__()
        __Arguments__{ IObservable, Callable, Callable, Callable/nil }
        function Join(self, right, leftDurationSelector, rightDurationSelector, resultSelector)
            local leftwindows           = List()
            local rightwindows          = List()

            return Operator(self, function(observer, ...)
                    local count         = select("#", ...)

                    -- join the right window
                    if #rightwindows > 0 then
                        if count == 1 then
                            local a1    = ...
                            for _, rwin in rightwindows:GetIterator() do
                                if resultSelector then
                                    observer:OnNext(resultSelector(a1, unpack(rwin)))
                                else
                                    observer:OnNext(a1, unpack(rwin))
                                end
                            end
                        elseif count == 2 then
                            local a1, a2= ...
                            for _, rwin in rightwindows:GetIterator() do
                                if resultSelector then
                                    observer:OnNext(resultSelector(a1, a2, unpack(rwin)))
                                else
                                    observer:OnNext(a1, a2, unpack(rwin))
                                end
                            end
                        elseif count == 3 then
                            local a1, a2, a3 = ...
                            for _, rwin in rightwindows:GetIterator() do
                                if resultSelector then
                                    observer:OnNext(resultSelector(a1, a2, a3, unpack(rwin)))
                                else
                                    observer:OnNext(a1, a2, a3, unpack(rwin))
                                end
                            end
                        else
                            for _, rwin in rightwindows:GetIterator() do
                                local queue = Queue{ ... }:Enqueue(unpack(rwin))
                                if resultSelector then
                                    observer:OnNext(resultSelector(queue:Dequeue(queue.Count)))
                                else
                                    observer:OnNext(queue:Dequeue(queue.Count))
                                end
                            end
                        end
                    end

                    -- Open window
                    local ok, selector  = pcall(leftDurationSelector, ...)
                    if not ok then return observer:OnError(Exception(selector)) end
                    if not isObjectType(selector, IObservable) then return observer:OnError(Exception("The selector doesn't return a valid value")) end

                    local window

                    local close         = function()
                        window:Unsubscribe()
                        leftwindows:Remove(window)
                    end

                    window              = Observer(close, close, close)

                    for i = 1, count do
                        window[i]       = select(i, ...)
                    end

                    leftwindows:Insert(window)
                    selector:Subscribe(window)
                end, function(observer, ex)
                    leftwindows:Each("Unsubscribe")
                    rightwindows:Each("Unsubscribe")
                    observer:OnError(ex)
                end, function(observer)
                    leftwindows:Each("Unsubscribe")
                    rightwindows:Each("Unsubscribe")
                    observer:OnCompleted()
                end, Operator(right, function(observer, ...)
                    local count         = select("#", ...)

                    -- join the right window
                    if #leftwindows > 0 then
                        for _, lwin in leftwindows:GetIterator() do
                            local lcnt  = #lwin
                            if lcnt == 1 then
                                local a1= lwin[1]
                                if resultSelector then
                                    observer:OnNext(resultSelector(a1, ...))
                                else
                                    observer:OnNext(a1, ...)
                                end
                            elseif lcnt == 2 then
                                local a1, a2 = lwin[1], lwin[2]
                                if resultSelector then
                                    observer:OnNext(resultSelector(a1, a2, ...))
                                else
                                    observer:OnNext(a1, a2, ...)
                                end
                            elseif lcnt == 3 then
                                local a1, a2, a3 = lwin[1], lwin[2], lwin[3]
                                if resultSelector then
                                    observer:OnNext(resultSelector(a1, a2, a3, ...))
                                else
                                    observer:OnNext(a1, a2, a3, ...)
                                end
                            else
                                local queue = Queue{ unpack(lwin) }:Enqueue(...)
                                if resultSelector then
                                    observer:OnNext(resultSelector(queue:Dequeue(queue.Count)))
                                else
                                    observer:OnNext(queue:Dequeue(queue.Count))
                                end
                            end
                        end
                    end

                    -- Open window
                    local ok, selector  = pcall(rightDurationSelector, ...)
                    if not ok then return observer:OnError(Exception(selector)) end
                    if not isObjectType(selector, IObservable) then return observer:OnError(Exception("The selector doesn't return a valid value")) end

                    local window

                    local close         = function()
                        window:Unsubscribe()
                        rightwindows:Remove(window)
                    end

                    window              = Observer(close, close, close)

                    for i = 1, count do
                        window[i]       = select(i, ...)
                    end

                    rightwindows:Insert(window)
                    selector:Subscribe(window)
                end, function(observer, ex)
                    leftwindows:Each("Unsubscribe")
                    rightwindows:Each("Unsubscribe")
                    observer:OnError(ex)
                end, function(observer)
                    leftwindows:Each("Unsubscribe")
                    rightwindows:Each("Unsubscribe")
                    observer:OnCompleted()
                end)
            )
        end

        -----------------------------------------------------------------------
        --                               Plan                                --
        -----------------------------------------------------------------------
        local Pattern                   = class {}
        local Plan                      = class {}

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
            return Observable(function(observer)
                local sequences         = plan[1]
                local selector          = plan[2]
                local total             = #sequences
                local queues            = List(total, function() return Queue() end)
                local count             = 0
                local completed         = 0

                local process           = selector and function(index)
                    count               = count + 1

                    if count == total then
                        local rs        = Queue()

                        queues:Each(function(queue)
                            rs:Enqueue(queue:Dequeue(queue:Dequeue()))
                            if queue:Peek() == nil then count = count - 1 end
                        end)

                        safeNext(observer, pcall(selector, rs:Dequeue(rs.Count)))
                    end
                end or function(index)
                    count               = count + 1

                    if count == total then
                        local rs        = Queue()

                        queues:Each(function(queue)
                            rs:Enqueue(queue:Dequeue(queue:Dequeue()))
                            if queue:Peek() == nil then count = count - 1 end
                        end)

                        observer:OnNext(rs:Dequeue(rs.Count))
                    end
                end

                for i = 1, total do
                    local j             = i
                    Subject(sequences[i], function(_, ...)
                        local isnew     = queues[j]:Peek() == nil
                        queues[j]:Enqueue(select("#", ...), ...)
                        if isnew then return process(j) end
                    end, nil, function()
                        completed       = completed + 1
                        if completed == total then
                            observer:OnCompleted()
                        end
                    end):Subscribe(observer)
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

            local onError               = function(observer, ex)
                if currsub then currsub:OnError(ex) end
                observer:OnError(ex)
            end

            return Operator(self, function(observer, ...)
                    if not currsub then
                        currsub         = Subject()
                        observer:OnNext(currsub)
                    end

                    currsub:OnNext(...)
                end, onError, function(observer)
                    if currsub then currsub:OnCompleted() end
                    observer:OnCompleted()
                end, Operator(sampler,
                    function(observer, ...)
                        if currsub then currsub:OnCompleted() end

                        currsub         = Subject()
                        observer:OnNext(currsub)
                    end,
                    onError,
                    function(observer) end
                )
            )
        end

        --- Returns a new Observable that produces its most recent value every time
        -- the specified observable produces a value
        __Observable__()
        __Arguments__{ IObservable }
        function Sample(self, sampler)
            local queue                 = Queue()
            local completed

            return Operator(self, function(observer, ...)
                    queue:Clear()
                    queue:Enqueue(...)
                end, nil, function(observer)
                    if completed then observer:OnCompleted() end
                    completed           = true
                end,
                Operator(sampler, function(observer, ...)
                    local count         = queue.Count
                    if count > 0 then
                        observer:OnNext(queue:Dequeue(count))
                    end
                end, nil, function(observer)
                    local count         = queue.Count
                    if count > 0 then
                        observer:OnNext(queue:Dequeue(count))
                    end
                    if completed then observer:OnCompleted() end
                    completed           = true
                end)
            )
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
        function Publish(self)
            return PublishSubject(self)
        end

        __Arguments__{ NaturalNumber/nil }
        function Replay(self, size)
            return ReplaySubject(self, size)
        end

        __Arguments__{ -Subject/Subject, System.Any * 0 }
        function ToSubject(self, subject, ...)
            return subject(self, ...)
        end
    end)
end)