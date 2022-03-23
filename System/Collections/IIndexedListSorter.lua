--===========================================================================--
--                                                                           --
--                   System.Collections.IIndexedListSorter                   --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2016/02/04                                               --
-- Update Date  :   2018/03/16                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Collections"

    export                              {
        ceil                            = math.ceil,
        floor                           = math.floor,
        log                             = math.log,
        random                          = math.random,
        tinsert                         = table.insert,
        tremove                         = table.remove,
        tsort                           = table.sort,
        pcall                           = pcall,
        assert                          = assert,
    }

    local function formatParams(self, start, stop)
        local count                     = self.Count or #self
        if start < 0    then start      = count + start + 1 end
        if stop < 0     then stop       = count + stop + 1 end
        if start > stop then start,stop = stop, start end
        if start < 1    then start      = 1 end
        if self[stop] == nil then stop  = count end

        return start, stop, count
    end

    -- For quick sort
    local function partition(self, low, high, compare)
        local rnd                       = low + random(high - low)
        self[rnd], self[high]           = self[high], self[rnd]

        local i                         = low
        local pivot                     = self[high]
        for j = low, high - 1 do
            if not compare(pivot, self[j]) then
                self[i], self[j]        = self[j], self[i]
                i                       = i + 1
            end
        end
        self[i], self[high]             = self[high], self[i]
        return i
    end

    local function quickSort(self, low, high, compare)
        if low < high then
            local p                     = partition(self, low, high, compare)
            quickSort(self, low, p - 1, compare)
            quickSort(self, p + 1, high, compare)
        end
    end

    -- For heap sort
    local function shiftDown(self, base, start, stop, compare)
        local left                      = (start - base + 1) * 2 + base - 1
        local right                     = left + 1

        while left <= stop do
            local root                  = start

            if compare(self[root], self[left]) then root = left end
            if right <= stop and compare(self[root], self[right]) then root = right end
            if root == start then return end

            self[start], self[root]     = self[root], self[start]
            start                       = root

            left                        = (start - base + 1) * 2 + base - 1
            right                       = left + 1
        end
    end

    -- For merge sort
    local function mergeResult(self, start, mid, stop, compare, cache)
        -- Shrink the merge range
        local right                     = mid + 1
        local rval                      = self[right]
        local lval                      = self[mid]

        while start <= mid and not compare(rval, self[start]) do start = start + 1 end
        while stop  > mid  and not compare(self[stop], lval)  do stop  = stop - 1 end

        if start > mid or stop <= mid then return end

        -- Merge
        local MIN_GALLOP                = 7

        if mid - start <= stop - mid - 1 then
            -- merge to left
            local left                  = 1
            for i = start, mid do cache[left] = self[i] left = left + 1 end
            left                        = 1
            local leftStop              = mid - start + 1

            local ok, err               = pcall(function ()
                local lval              = cache[left]
                local rval              = self[right]
                local gallopMode        = false
                local leftWin           = 0
                local rightWin          = 0

                while left <= leftStop and right <= stop do
                    if gallopMode then
                        if compare(rval, lval) then
                            local k     = 1
                            local pos   = right + 2^k - 1
                            while pos <= stop and compare(self[pos], lval) do
                                k       = k + 1
                                pos     = right + 2^k - 1
                            end
                            pos         = right + 2^(k - 1)
                            k           = right
                            while right < pos do
                                self[start] = self[right]
                                start   = start + 1
                                right   = right + 1
                            end
                            while right <= stop do
                                rval    = self[right]
                                if compare(rval, lval) then
                                    self[start] = rval
                                    start = start + 1
                                    right = right + 1
                                else
                                    break
                                end
                            end
                            if right - k + 1 < MIN_GALLOP then gallopMode = false end
                            self[start] = lval
                            start       = start + 1
                            left        = left + 1
                            lval        = cache[left]
                            rval        = self[right]
                        else
                            local k     = 1
                            local pos   = left + 2^k - 1
                            while pos <= leftStop and not compare(rval, cache[pos]) do
                                k       = k + 1
                                pos     = left + 2^k - 1
                            end
                            pos         = left + 2^(k - 1)
                            k           = left
                            while left < pos do
                                self[start] = cache[left]
                                start   = start + 1
                                left    = left + 1
                            end
                            while left <= leftStop do
                                lval    = cache[left]
                                if not compare(rval, lval) then
                                    self[start] = lval
                                    start = start + 1
                                    left = left + 1
                                else
                                    break
                                end
                            end
                            if left - k + 1 < MIN_GALLOP then gallopMode = false end
                            self[start] = rval
                            start       = start + 1
                            right       = right + 1
                            lval        = cache[left]
                            rval        = self[right]
                        end
                    else
                        if compare(rval, lval) then
                            rightWin    = rightWin + 1
                            leftWin     = 0
                            self[start] = rval
                            start       = start + 1
                            right       = right + 1
                            rval        = self[right]
                        else
                            leftWin     = leftWin + 1
                            rightWin    = 0
                            self[start] = lval
                            start       = start + 1
                            left        = left + 1
                            lval        = cache[left]
                        end

                        if rightWin >= MIN_GALLOP or leftWin >= MIN_GALLOP then
                            gallopMode  = true
                            leftWin     = 0
                            rightWin    = 0
                        end
                    end
                end
            end)

            for i = left, leftStop do
                self[start]             = cache[i]
                start                   = start + 1
            end

            assert(ok, err)
        else
            -- merge to right
            right                       = 1
            for i = stop, mid + 1, -1 do cache[right] = self[i] right = right + 1 end
            right                       = 1
            local rightStop             = stop - mid
            local left                  = mid

            local ok, err               = pcall(function ()
                local lval              = self[left]
                local rval              = cache[right]
                local gallopMode        = false
                local leftWin           = 0
                local rightWin          = 0

                while left >= start and right <= rightStop do
                    if gallopMode then
                        if compare(rval, lval) then
                            local k     = 1
                            local pos   = left - (2^k - 1)
                            while pos >= start and compare(rval, self[pos]) do
                                k       = k + 1
                                pos     = left - (2^k - 1)
                            end
                            pos         = left - 2^(k - 1)
                            k           = left
                            while left > pos do
                                self[stop] = self[left]
                                stop    = stop - 1
                                left    = left - 1
                            end
                            while left >= start do
                                lval    = self[left]
                                if compare(rval, lval) then
                                    self[stop] = lval
                                    stop= stop - 1
                                    left= left - 1
                                else
                                    break
                                end
                            end
                            if k - left + 1 < MIN_GALLOP then gallopMode = false end
                            self[stop]  = rval
                            stop        = stop - 1
                            right       = right + 1
                            lval        = self[left]
                            rval        = cache[right]
                        else
                            local k     = 1
                            local pos   = right + 2^k - 1
                            while pos <= rightStop and not compare(cache[pos], lval) do
                                k       = k + 1
                                pos     = right + 2^k - 1
                            end
                            pos         = right + 2^(k - 1)
                            while right < pos do
                                self[stop] = cache[right]
                                stop    = stop - 1
                                right   = right + 1
                            end
                            while right <= rightStop do
                                rval    = cache[right]
                                if not compare(rval, lval) then
                                    self[stop] = rval
                                    stop  = stop - 1
                                    right = right + 1
                                else
                                    break
                                end
                            end
                            if right - k + 1 < MIN_GALLOP then gallopMode = false end
                            self[stop] = lval
                            stop        = stop - 1
                            left        = left - 1
                            lval        = self[left]
                            rval        = cache[right]
                        end
                    else
                        if compare(rval, lval) then
                            leftWin     = leftWin + 1
                            rightWin    = 0
                            self[stop]  = lval
                            stop        = stop - 1
                            left        = left - 1
                            lval        = self[left]
                        else
                            rightWin    = rightWin + 1
                            leftWin     = 0
                            self[stop]  = rval
                            stop        = stop - 1
                            right       = right + 1
                            rval        = cache[right]
                        end

                        if rightWin >= MIN_GALLOP or leftWin >= MIN_GALLOP then
                            gallopMode  = true
                            leftWin     = 0
                            rightWin    = 0
                        end
                    end
                end
            end)

            for i = right, rightStop do
                self[stop]              = cache[i]
                stop                    = stop - 1
            end

            assert(ok, err)
        end
    end

    local function mergeSort(self, start, stop, compare, cache, minRun)
        if start < stop then
            if stop - start + 1 <= minRun then return self:InsertionSort(compare, start, stop) end
            local mid                   = floor((start + stop) / 2)
            mergeSort(self, start, mid, compare, cache, minRun)
            mergeSort(self, mid + 1, stop, compare, cache, minRun)
            mergeResult(self, start, mid, stop, compare, cache)
        end
    end

    -----------------------------------------------------------
    --                     extend method                     --
    -----------------------------------------------------------
    --- Reverse the indexed list
    __Arguments__{ Integer/1, Integer/-1 }
    function IIndexedList:Reverse(start, stop)
        start, stop                     = formatParams(self, start, stop)

        local i                         = start
        local j                         = stop

        while i < j do
            self[i], self[j]            = self[j], self[i]

            i                           = i + 1
            j                           = j - 1
        end

        return self
    end

    --- Apply insertion sort on the indexed list
    __Arguments__{ Callable/"x,y=>x<y", Integer/1, Integer/-1 }
    function IIndexedList:InsertionSort(compare, start, stop)
        start, stop                     = formatParams(self, start, stop)

        for i = start + 1, stop do
            local j                     = i - 1
            local val                   = self[i]
            while j >= start and compare(val, self[j]) do
                self[j + 1]             = self[j]
                j                       = j - 1
            end
            self[j + 1]                 = val
        end
        return self
    end

    --- Apply bubble sort on the indexed list
    __Arguments__{ Callable/"x,y=>x<y", Integer/1, Integer/-1 }
    function IIndexedList:BubbleSort(compare, start, stop)
        start, stop                     = formatParams(self, start, stop)

        local swaped                    = true
        local i, j

        while stop > start and swaped do
            swaped                      = false

            i                           = start
            j                           = stop

            while i < stop do
                if compare(self[i+1], self[i]) then
                    self[i], self[i+1]  = self[i+1], self[i]
                    swaped              = true
                end

                if compare(self[j], self[j - 1]) then
                    self[j], self[j - 1]= self[j - 1], self[j]
                    swaped              = true
                end

                j                       = j - 1
                i                       = i + 1
            end

            -- Reduce the Check range
            start                       = start  + 1
            stop                        = stop - 1
        end
        return self
    end

    --- Apply selection sort on the indexed list
    __Arguments__{ Callable/"x,y=>x<y", Integer/1, Integer/-1 }
    function IIndexedList:SelectionSort(compare, start, stop)
        start, stop                     = formatParams(self, start, stop)

        for i = start, stop - 1 do
            local min                   = i
            for j = i + 1, stop do
                if compare(self[j], self[min]) then
                    min                 = j
                end
            end
            self[i], self[min]          = self[min], self[i]
        end
        return self
    end

    --- Apply comb sort on the indexed list
    __Arguments__{ Callable/"x,y=>x<y", Integer/1, Integer/-1 }
    function IIndexedList:CombSort(compare, start, stop)
        start, stop                     = formatParams(self, start, stop)

        local gap                       = stop - start + 1
        local shrink                    = 1.3
        local swaped                    = true

        repeat
            gap                         = floor(gap / shrink)
            if gap < 1 then gap         = 1 end

            local i                     = start
            local j                     = i + gap
            swaped                      = false

            while j <= stop do
                if compare(self[j], self[i]) then
                    self[j], self[i]    = self[i], self[j]
                    swaped              = true
                end
                i                       = i + 1
                j                       = j + 1
            end
        until gap == 1 and not swaped

        return self
    end

    --- Apply merge sort on the indexed list
    __Arguments__{ Callable/"x,y=>x<y", Integer/1, Integer/-1 }
    function IIndexedList:MergeSort(compare, start, stop)
        start, stop                     = formatParams(self, start, stop)

        local count                     = stop - start + 1
        local minRun                    = ceil(count / 2^(floor( log(count) / log(2) ) - 5))

        mergeSort(self, start, stop, compare, {}, minRun)
        return self
    end

    --- Apply quick sort on the indexed list
    __Arguments__{ Callable/"x,y=>x<y", Integer/1, Integer/-1 }
    function IIndexedList:QuickSort(compare, start, stop)
        start, stop                     = formatParams(self, start, stop)

        quickSort(self, start, stop, compare)
        return self
    end

    --- Apply heap sort on the indexed list
    __Arguments__{ Callable/"x,y=>x<y", Integer/1, Integer/-1 }
    function IIndexedList:HeapSort(compare, start, stop)
        start, stop                     = formatParams(self, start, stop)

        for n = floor((stop - start + 1) / 2), 1, -1 do
            shiftDown(self, start, start - 1 + n, stop, compare)
        end

        for n = stop, start + 1, -1 do
            self[n], self[start]        = self[start], self[n]
            shiftDown(self, start, start, n - 1, compare)
        end

        return self
    end

    --- Apply timsort on the indexed list
    __Arguments__{ Callable/"x,y=>x<y", Integer/1, Integer/-1 }
    function IIndexedList:TimSort(compare, start, stop)
        start, stop                     = formatParams(self, start, stop)

        local count                     = stop - start + 1
        if count == 0 then return end

        -- Calc minrun
        local minRun                    = ceil(count / 2^(floor( log(count) / log(2) ) - 5))

        -- Use insertion sort on less element list
        if count <= minRun then return self:InsertionSort(compare, start, stop) end

        -- Run stack
        local runStack                  = {}
        local runLenStack               = {}
        local stackHeight               = 0
        local mergeTemp                 = {}

        -- Scan the list
        local i                         = start + 1
        local ascending                 = nil
        local descending                = nil
        local val                       = self[start]

        local mergeStack

        local validateStack             = function()
            if stackHeight >= 3 and runLenStack[stackHeight - 2] <= runLenStack[stackHeight - 1] + runLenStack[stackHeight] then
                if runLenStack[stackHeight - 2] < runLenStack[stackHeight] then
                    return mergeStack(stackHeight - 2, stackHeight - 1)
                else
                    return mergeStack(stackHeight - 1, stackHeight)
                end
            end
            if stackHeight >= 2 and runLenStack[stackHeight - 1] <= runLenStack[stackHeight] then
                return mergeStack(stackHeight - 1, stackHeight)
            end
        end

        mergeStack                      = function(i, j)
            mergeResult(self, runStack[i], runStack[j] - 1, runStack[j] + runLenStack[j] - 1, compare, mergeTemp)
            runLenStack[i]              = runLenStack[i] + runLenStack[j]
            tremove(runStack, j)
            tremove(runLenStack, j)
            stackHeight                 = stackHeight - 1

            return validateStack()
        end

        local pushStack                 = function (runStart, runEnd, desc)
            if runEnd - runStart + 1 < minRun and runEnd < stop then
                runEnd                  = runStart + minRun - 1
                if runEnd > stop then
                    runEnd              = stop
                end
                desc                    = true
            end
            if desc then self:InsertionSort(compare, runStart, runEnd) end
            tinsert(runStack, runStart)
            tinsert(runLenStack, runEnd - runStart + 1)
            stackHeight                 = stackHeight + 1

            validateStack()

            return runEnd + 1
        end

        while i <= stop do
            if compare(self[i], val) then
                if ascending then
                    i                   = pushStack(ascending, i - 1)
                    ascending           = nil
                elseif not descending then
                    descending          = i - 1
                end
            else
                if descending then
                    i                   = pushStack(descending, i - 1, true)
                    descending          = nil
                elseif not ascending then
                    ascending           = i - 1
                end
            end

            val                         = self[i]
            i                           = i + 1
        end

        if ascending        then pushStack(ascending, stop)
        elseif descending   then pushStack(descending, stop, true)
        elseif runStack[stackHeight] + runLenStack[stackHeight] - 1 < stop then pushStack(stop, stop) end

        while stackHeight > 1 do mergeStack(stackHeight - 1, stackHeight) end

        return self
    end

    --- Apply default sort on the indexed list
    __Arguments__{ Callable/"x,y=>x<y", Integer/1, Integer/-1 }
    function IIndexedList:Sort(func, start, stop)
        if start == 1 and (stop == -1 or stop == self.Count) then tsort(self, func) return self end
        return self:TimSort(func, start, stop)
    end
end)
