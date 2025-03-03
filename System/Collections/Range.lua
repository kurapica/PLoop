--===========================================================================--
--                                                                           --
--                         System.Collections.Range                          --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2018/03/20                                               --
-- Update Date  :   2018/03/20                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Collections"

    import "System.Serialization"

    --- The range by steps
    __Sealed__()
    class "Range"                       (function(_ENV)
        extend "IIndexedList"

        export                          {
            floor                       = math.floor,
            min                         = math.min,
            max                         = math.max,
            yield                       = coroutine.yield,
            tostring                    = tostring,

            -- combine and sort ranges
            sortRanges                  = function(a)
                local changed           = true

                -- sort
                while changed do
                    changed             = false
                    local current       = a
                    while current do
                        local next      = current.next
                        if not next then break end

                        -- remove useless next range
                        if next.start > next.stop then
                            current.next= next.next
                            changed     = true

                        -- replace the useless range
                        elseif current.start > current.stop then
                            current.start, current.stop, current.next = next.start, next.stop, next.next
                            changed     = true

                        -- swap
                        else
                            if current.start > next.start then
                                current.start, current.stop, next.start, next.stop = next.start, next.stop, current.start, current.stop
                                changed = true
                            end

                            current     = next
                        end
                    end
                end

                -- combine
                do
                    local current       = a
                    while current do
                        local next      = current.next
                        if not next then break end

                        -- Combine
                        if current.stop >= next.start then
                            current.stop= next.stop
                            current.next= next.next
                        else
                            current     = next
                        end
                    end
                end

                return a
            end,

            -- a X b
            intersection                = function(a, b)
                local range             = Range(max(a.start, b.start), min(a.stop, b.stop), a.step)
                local current           = range
                if a.next then
                    current.next        = intersection(a.next, b)
                    while current.next do current = current.next end
                end
                if b.next then
                    current.next        = intersection(a, b.next)
                    while current.next do current = current.next end
                end
                if a.next and b.next then
                    current.next        = intersection(a.next, b.next)
                end
                return sortRanges(range)
            end,

            -- a + b
            union                       = function(a, b)
                local range             = Range(a.start, a.stop, a.step)
                local current           = range
                a                       = a.next
                while a do
                    current.next        = Range(a.start, a.stop, a.step)
                    current             = current.next
                    a                   = a.next
                end
                while b do
                    current.next        = Range(b.start, b.stop, b.step)
                    current             = current.next
                    b                   = b.next
                end

                return sortRanges(range)
            end,

            -- a - b
            complement                  = function(a, b)
                local range
                if a.start < b.start then
                    range               = Range(a.start, min(a.stop, b.start - a.step))
                else

                end
            end
        }

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        property "Count"                {
            get                         = function(self)
                local start, stop, step = self.start, self.stop, self.step
                return (stop > start and (floor((stop - start) / step) + 1) or 0) + (self.next and self.next.Count or 0)
            end
        }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        __Iterator__()
        function GetIterator(self)
            local index                 = 0
            for i = self.start, self.stop, self.step do
                index                   = index + 1
                yield(index, i)
            end

            if self.next then
                for i, v in self.next:GetIterator() do
                    yield(index + i, v)
                end
            end
        end

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{ Integer, Integer, Integer/1 }
        function __new(_, start, stop, step)
            return { start = start, stop = stop, step = step }
        end

        -----------------------------------------------------------
        --                      meta-method                      --
        -----------------------------------------------------------
        function __index(self, index)
            if type(index) == "number" and index > 0 then
                local value             = self.start + (index - 1) * self.step
                if value <= self.stop then return value end
            end
        end

        function __newindex(self, index, value, stack)
            if index ~= "next" then error("The range is readonly", (stack or 1) + 1) end
            rawset(self, index, value)
        end

        -- Range(1, 10) X Range(8, 12) = Range(8, 10)
        __Arguments__{ Range }:Throwable()
        function __mul(self, other)
            if self.step ~= other.step or self.start % self.step ~= other.start % other.step then
                throw("Usage: RangeA * RangeB - those ranges must have the same step and module value")
            end
            return intersection(self, other)
        end

        -- Range(1, 10) + Range(8, 12) = Range(1, 12)
        __Arguments__{ Range }:Throwable()
        function __add(self, other)
            if self.step ~= other.step or self.start % self.step ~= other.start % other.step then
                throw("Usage: RangeA + RangeB - those ranges must have the same step and module value")
            end
            return union(self, other)
        end

        -- Range(1, 12) - Range(1, 4) = Range(5, 12)
        __Arguments__{ Range }:Throwable()
        function __sub(self, other)
            if self.step ~= other.step or self.start % self.step ~= other.start % other.step then
                throw("Usage: RangeA - RangeB - those ranges must have the same step and module value")
            end
            return complement(self, other)
        end

        -- Range(1, 10) .. Range(8, 12) = Range(1, 12)
        __Arguments__{ Range }:Throwable()
        function __concat(self, other)
            if self.step ~= other.step or self.start % self.step ~= other.start % other.step then
                throw("Usage: RangeA .. RangeB - those ranges must have the same step and module value")
            end
            return union(self, other)
        end

        function __tostring(self)
            return self.next and ("[%d, %d, %d] .. %s"):format(self.start, self.stop, self.step, tostring(self.next))
                or ("[%d, %d, %d]"):format(self.start, self.stop, self.step)
        end
    end)
end)