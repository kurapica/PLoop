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
        inherit "IIndexedList"

        export                          {
            floor                       = math.floor
        }

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        property "Count"                { get = function(self) return floor((stop - start) / step) + 1 end }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        function GetIterator(self)
            local start, stop, step     = self.start, self.stop, self.step
            return function(self, index)
                index                   = index or 1
                local value             = start + index * step
                if value <= stop then return index + 1, value end
            end, self, 0
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
            if index > 0 then
                local value             = self.start + (index - 1) * self.step
                if value <= self.stop then return value end
            end
        end

        function __newindex(self, index, value, stack)
            error("The range is readonly", (stack or 1) + 1)
        end

        -- Range(1, 10) + Range(8, 12) = Range(1, 12)
        __Arguments__{ Range }
        function __add(self, other)
        end

        -- Range(1, 12) - Range(1, 4) = Range(5, 12)
        __Arguments__{ Range }
        function __sub(self, other)
        end

        -- Range(1, 10) .. Range(8, 12) = Range(1, 12)
        __Arguments__{ Range }
        function __concat(self, other)

        end
    end)
end)