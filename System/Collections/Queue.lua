--===========================================================================--
--                                                                           --
--                         System.Collections.Queue                          --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2019/12/08                                               --
-- Update Date  :   2019/12/08                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Collections"

    import "System.Serialization"

    --- Represents a first-in, first-out collection of objects.
    __Sealed__() __Serializable__() __Arguments__{ AnyType }( Any )
    __NoNilValue__(false):AsInheritable() __NoRawSet__(false):AsInheritable()
    class "Queue" (function(_ENV, lsttype)
       extend "ICountable" "ISerializable"

        export { type = type, ipairs = ipairs, yield = coroutine.yield, select = select, unpack = _G.unpack or table.unpack, min = math.min }

        lsttype = lsttype ~= Any and lsttype or nil

        if lsttype then
            export {
                valid           = getmetatable(lsttype).ValidateValue,
                GetErrorMessage = Struct.GetErrorMessage,
                parseindex      = Toolset.parseindex,
            }
        end

        local FIELD_FRONT       = -1
        local FIELD_REAR        = -2
        local FIELD_CLEAR       = -3

        -----------------------------------------------------------
        --                     serialization                     --
        -----------------------------------------------------------
        function Serialize(self, info)
            for i, v in self:GetIterator() do
                info:SetValue(i, v, lsttype)
            end
        end

        __Arguments__{ SerializationInfo }
        function __new(_, info)
            local i             = 1
            local v             = info:GetValue(i, lsttype)
            local self          = { [FIELD_FRONT] = 0 }
            while v ~= nil do
                self[i]         = v
                i               = i + 1
                v               = info:GetValue(i, lsttype)
            end

            self[FIELD_REAR]    = i - 1

            return self, true
        end

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- Get the count of items in the object
        property "Count" { set = false, get = function (self) return self[FIELD_REAR] - self[FIELD_FRONT] end }

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- Returns an iterator that iterates through the Queue
        __Iterator__()
        function GetIterator(self)
            local start         = self[FIELD_FRONT]
            local stop          = self[FIELD_REAR]

            for i = 1, stop - start do
                yield(i, self[i + start])
            end
        end

        --- Whether an item existed in the Queue
        function Contains(self, item)
            for i = self[FIELD_FRONT] + 1, self[FIELD_REAR] do
                if self[i] == item then return true end
            end
            return false
        end

        --- Adds an object to the end of the Queue
        if lsttype then __Arguments__{ lsttype * 1 } end
        function Enqueue(self, ...)
            if self[FIELD_CLEAR] then
                for i = self[FIELD_CLEAR], self[FIELD_FRONT] do
                    self[i]     = nil
                end

                self[FIELD_CLEAR] = nil
            end

            local count         = select("#", ...)
            local start         = self[FIELD_REAR]

            for i = 1, count do
                self[start + i] = select(i, ...)
            end

            self[FIELD_REAR]    = start + count

            return self
        end

        --- Removes and returns the object at the beginning of the Queue
        function Dequeue(self, count)
            count               = min(count and type(count) == "number" and count or 1, self[FIELD_REAR] - self[FIELD_FRONT])
            if count < 1 then return end

            local start         = self[FIELD_FRONT] + 1
            self[FIELD_CLEAR]   = self[FIELD_CLEAR] or start
            self[FIELD_FRONT]   = start + count - 1

            return unpack(self, start, self[FIELD_FRONT])
        end

        --- Clear the queue
        function Clear(self)
            for i = self[FIELD_CLEAR] or (self[FIELD_FRONT] + 1), self[FIELD_REAR] do
                self[i]         = nil
            end
            self[FIELD_FRONT]   = 0
            self[FIELD_REAR]    = 0
            self[FIELD_CLEAR]   = nil
        end

        --- Returns the object at the beginning of the Queue without removing it
        __Arguments__{ NaturalNumber/nil }
        function Peek(self, count)
            count               = min(count and type(count) == "number" and count or 1, self[FIELD_REAR] - self[FIELD_FRONT])
            if count < 1 then return end

            local start         = self[FIELD_FRONT]
            return unpack(self, start + 1, start + count)
        end

        __Arguments__{ NaturalNumber, NaturalNumber }
        function Peek(self, start, count)
            start               = self[FIELD_FRONT] + start - 1
            count               = min(count, self[FIELD_REAR] - start)
            return unpack(self, start + 1, start + count)
        end

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{ RawTable }
        function __new(_, lst)
            lst[FIELD_FRONT]    = 0
            lst[FIELD_REAR]     = #lst
            return lst, true
        end

        __Arguments__{ IList }
        function __new(_, lst)
            local i             = 0
            local obj           = { [FIELD_FRONT] = 0 }
            for idx, item in lst:GetIterator() do
                i               = i + 1
                obj[i]          = item
            end
            obj[FIELD_REAR]     = i
            return obj, true
        end

        __Arguments__{ Callable, System.Any/nil, System.Any/nil }
        function __new(_, iter, obj, idx)
            local i             = 0
            local lst           = { [FIELD_FRONT] = 0 }
            for key, item in iter, obj, idx do
                i               = i + 1
                if item ~= nil then
                    lst[i]      = item
                else
                    lst[i]      = key
                end
            end
            obj[FIELD_REAR]     = i
            return lst, true
        end

        __Arguments__{ NaturalNumber, Callable }
        function __new(_, count, initValue)
            local obj           = { [FIELD_FRONT] = 0 }
            for i = 1, count do
                obj[i]          = initValue(i)
            end
            obj[FIELD_REAR]     = count
            return obj, true
        end

        __Arguments__{ NaturalNumber, System.Any/nil }
        function __new(_, count, initValue)
            local obj           = { [FIELD_FRONT] = 0 }
            if initValue ~= nil then
                for i = 1, count do
                    obj[i]      = initValue
                end
            else
                for i = 1, count do
                    obj[i]      = i
                end
            end
            obj[FIELD_REAR]     = count
            return obj, true
        end

        __Arguments__{ Any * 0 }
        function __new(_, ...)
            local obj           = { ... }
            obj[FIELD_FRONT]    = 0
            obj[FIELD_REAR]     = #obj
            return obj, true
        end

        if lsttype then
            function __ctor(self)
                local msg
                for k, v in self:GetIterator() do
                    v, msg = valid(lsttype, v)
                    if msg then throw(GetErrorMessage(msg, parseindex(k))) end
                    self[k]= v
                end
            end
        end

        -----------------------------------------------------------
        --                      meta-method                      --
        -----------------------------------------------------------
        if lsttype then __Arguments__{ lsttype * 0 } end
        function __call(self, item, ...)
            if item ~= nil then
                return self:Enqueue(item, ...)
            else
                return self:Dequeue()
            end
        end

        function __len(self)
            return self[FIELD_REAR] - self[FIELD_FRONT]
        end
    end)
end)