--===========================================================================--
--                                                                           --
--                       System.Reactive.ReactiveList                        --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2023/10/25                                               --
-- Update Date  :   2023/10/25                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Reactive"

    --- Provide reactive feature for list or array
    __Sealed__()
    class "ReactiveList"                (function(_ENV)
        inherit "Subject"
        extend "IIndexedList"

        export                          {
            rawset                      = rawset,
            rawget                      = rawget,
            ipairs                      = ipairs,
            yield                       = coroutine.yield,
            tinsert                     = table.insert,
            tremove                     = table.removed,

            ReactiveList, Observable, Observer, Reactive, Watch
        }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- Gets the iterator
        __Iterator__()
        function GetIterator(self)
            local list                  = rawget(self, ReactiveList)
            for i, v in (list.GetIterator or ipairs)(list) do
                yield(i, v)
            end
        end

        --- Insert the item
        __Arguments__{ Any }
        function Insert(self, item)

        end

        __Arguments__{ NaturalNumber, Any }
        function Insert(self, index, item)

        end

        --- Whether an item existed in the list
        function Contains(self, item) for i, chk in self:GetIterator() do if chk == item then return true end end return false end

        --- Get the index of the item if it existed in the list
        function IndexOf(self, item) for i, chk in self:GetIterator() do if chk == item then return i end end end

        --- Remove an item
        function Remove(self, item) local i = self:IndexOf(item) if i then return self:RemoveByIndex(i) end end

        --- Remove an item from the tail or the given index
        RemoveByIndex                   = table.remove

        --- Clear the list
        function Clear(self)
            for i = self.Count, 1, -1 do self[i] = nil end
            return self
        end

        --- Extend the list
        __Arguments__{ RawTable }
        function Extend(self, lst)
            local ins               = self.Insert
            for _, item in ipairs(lst) do ins(self, item) end
            return self
        end

        __Arguments__{ IList }
        function Extend(self, lst)
            local ins               = self.Insert
            for _, item in lst:GetIterator() do ins(self, item) end
            return self
        end

        __Arguments__{ Callable, System.Any/nil, System.Any/nil }
        function Extend(self, iter, obj, idx)
            local ins               = self.Insert
            for key, item in iter, obj, idx do
                if item == nil then item = key end
                ins(self, item)
            end
            return self
        end

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        __Arguments__{ List + RawTable }
        function __ctor(self, list)
            rawset(self, ReactiveList, list)
        end

        -----------------------------------------------------------------------
        --                            meta-method                            --
        -----------------------------------------------------------------------
        function __index(self, index)

        end

        function __newindex(self, index, value)
        end
    end)
end)