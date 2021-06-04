--===========================================================================--
--                                                                           --
--                       System.Collections.Dictionary                       --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2016/02/28                                               --
-- Update Date  :   2020/07/06                                               --
-- Version      :   1.1.6                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Collections"

    import "System.Serialization"

    -- Helpers
    export { yield = coroutine.yield, ipairs = ipairs }

    __Iterator__() iterforpair  = function (lstKey, lstValue)
        local yield = yield
        local iter, o, idx, value = (lstValue.GetIterator or ipairs)(lstValue)
        for _, key in (lstValue.GetIterator or ipairs)(lstKey) do
            idx, value = iter(o, idx)
            if idx then yield(key, value) else break end
        end
    end

    --- Represents the key-value pairs collections
    interface "IDictionary" { Iterable }

    --- The un-safe dictionary, it'll use the table as the object directly to gain
    -- the best performance, it's safe when no method name, property name will be
    -- used as keys.
    __Sealed__() __Serializable__() __Arguments__{ AnyType, AnyType }( Any, Any )
    __NoNilValue__(false):AsInheritable() __NoRawSet__(false):AsInheritable()
    class "Dictionary" (function (_ENV, keytype, valtype)
        extend "IDictionary" "ISerializable"

        export {
            ipairs              = ipairs,
            pairs               = pairs,
            GetErrorMessage     = Struct.GetErrorMessage,
            tostring            = tostring,

            List[keytype], List[valtype]
        }

        if keytype ~= Any then
            export { kvalid     = getmetatable(keytype).ValidateValue, rawset = rawset }
        end

        if valtype ~= Any then
            export { vvalid     = getmetatable(valtype).ValidateValue, rawset = rawset }
        end

        -----------------------------------------------------------
        --                     serialization                     --
        -----------------------------------------------------------
        function Serialize(self, info)
            local key   = {}
            local val   = {}
            local idx   = 1
            for k, v in self:GetIterator() do
                key[idx]= k
                val[idx]= v
                idx     = idx + 1
            end

            info:SetValue(1, List[keytype](key))
            info:SetValue(2, List[valtype](val))
        end

        __Arguments__{ SerializationInfo }
        function __new(_, info)
            local key     = info:GetValue(1, List[keytype])
            local val     = info:GetValue(2, List[valtype])

            return this(_, key, val)
        end

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        GetIterator     = pairs

        if keytype == Any and valtype == Any then
            --- Update the dictionary
            __Arguments__{ RawTable }
            function Update(self, dict)
                for k, v in pairs(dict) do self[k] = v end
                return self
            end

            __Arguments__{ IDictionary }
            function Update(self, dict)
                for k, v in dict:GetIterator() do self[k] = v end
                return self
            end

            __Arguments__{ Callable, System.Any/nil, System.Any/nil }
            function Update(self, iter, obj, idx)
                for k, v in iter, obj, idx do self[k] = v end
                return self
            end
        elseif keytype == Any and valtype ~= Any then
            __Arguments__{ RawTable }
            function Update(self, dict)
                for k, v in pairs(dict) do
                    local ret, msg  = vvalid(valtype, v, true)
                    if not msg then
                        self[k]     = v
                    end
                end
                return self
            end

            __Arguments__{ IDictionary }
            function Update(self, dict)
                for k, v in dict:GetIterator() do
                    local ret, msg  = vvalid(valtype, v, true)
                    if not msg then
                        self[k]     = v
                    end
                end
                return self
            end

            __Arguments__{ Callable, System.Any/nil, System.Any/nil }
            function Update(self, iter, obj, idx)
                for k, v in iter, obj, idx do
                    local ret, msg  = vvalid(valtype, v, true)
                    if not msg then
                        self[k]     = v
                    end
                end
                return self
            end
        elseif keytype ~= Any and valtype == Any then
            __Arguments__{ RawTable }
            function Update(self, dict)
                for k, v in pairs(dict) do
                    local ret, msg  = kvalid(keytype, k, true)
                    if not msg then
                        self[k]     = v
                    end
                end
                return self
            end

            __Arguments__{ IDictionary }
            function Update(self, dict)
                for k, v in dict:GetIterator() do
                    local ret, msg  = kvalid(keytype, k, true)
                    if not msg then
                        self[k]     = v
                    end
                end
                return self
            end

            __Arguments__{ Callable, System.Any/nil, System.Any/nil }
            function Update(self, iter, obj, idx)
                for k, v in iter, obj, idx do
                    local ret, msg  = kvalid(keytype, k, true)
                    if not msg then
                        self[k]     = v
                    end
                end
                return self
            end
        else
            __Arguments__{ RawTable }
            function Update(self, dict)
                for k, v in pairs(dict) do
                    local ret, msg  = kvalid(keytype, k, true)
                    if not msg then
                        ret, msg    = vvalid(valtype, v, true)
                        if not msg then
                            self[k] = v
                        end
                    end
                end
                return self
            end

            __Arguments__{ IDictionary }
            function Update(self, dict)
                for k, v in dict:GetIterator() do
                    local ret, msg  = kvalid(keytype, k, true)
                    if not msg then
                        ret, msg    = vvalid(valtype, v, true)
                        if not msg then
                            self[k] = v
                        end
                    end
                end
                return self
            end

            __Arguments__{ Callable, System.Any/nil, System.Any/nil }
            function Update(self, iter, obj, idx)
                for k, v in iter, obj, idx do
                    local ret, msg  = kvalid(keytype, k, true)
                    if not msg then
                        ret, msg    = vvalid(valtype, v, true)
                        if not msg then
                            self[k] = v
                        end
                    end
                end
                return self
            end
        end

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{ }
        function __new() return {} end

        __Arguments__{ RawTable }
        function __new(_, dict) return dict, true end

        __Arguments__{ RawTable + IList, RawTable + IList }
        function __new(_, lstKey, lstValue)
            local dict  = {}
            local iter, o, idx, value = (lstValue.GetIterator or ipairs)(lstValue)
            for _, key in (lstKey.GetIterator or ipairs)(lstKey) do
                idx, value = iter(o, idx)
                if idx then
                    dict[key] = value
                else
                    break
                end
            end
            return dict, true
        end

        __Arguments__{ RawTable + IList, Any }
        function __new(_, lstKey, value)
            local dict  = {}
            for _, key in (lstKey.GetIterator or ipairs)(lstKey) do
                dict[key] = value
            end
            return dict, true
        end

        __Arguments__{ IDictionary }
        function __new(_, obj)
            local dict  = {}
            for key, value in obj:GetIterator() do
                dict[key] = value
            end
            return dict, true
        end

        __Arguments__{ Callable, Any/nil, Any/nil }
        function __new(_, iter, obj, idx)
            local dict  = {}
            for key, value in iter, obj, idx do
                dict[key] = value
            end
            return dict, true
        end

        if keytype ~= Any and valtype ~= Any then
            function __ctor(self)
                local msg
                for k, v in self:GetIterator() do
                    k, msg = kvalid(keytype, k)
                    if msg then throw(GetErrorMessage(msg, "field")) end

                    v, msg = vvalid(valtype, v)
                    if msg then throw(GetErrorMessage(msg, "value")) end
                    self[k]= v
                end
            end
        elseif keytype ~= Any then
            function __ctor(self)
                local msg
                for k, v in self:GetIterator() do
                    k, msg = kvalid(keytype, k)
                    if msg then throw(GetErrorMessage(msg, "field")) end
                end
            end
        elseif valtype ~= Any then
            function __ctor(self)
                local msg
                for k, v in self:GetIterator() do
                    v, msg = vvalid(valtype, v)
                    if msg then throw(GetErrorMessage(msg, "value")) end
                    self[k]= v
                end
            end
        end

        -----------------------------------------------------------
        --                      meta-method                      --
        -----------------------------------------------------------
        if keytype ~= Any or valtype ~= Any then
            __Arguments__{ keytype, valtype }
            __newindex = rawset
        end
    end)

    --- The dynamic dictionary
    __Sealed__() __NoRawSet__(true)
    class "XDictionary" (function(_ENV)
        extend "IDictionary"
        export { iterforpair = iterforpair, pairs = pairs }

        XDICT_TYPE_ITER         = 1
        XDICT_TYPE_DICT         = 2
        XDICT_TYPE_PAIR         = 3

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        function GetIterator(self)
            local type          = self[1]

            if type == XDICT_TYPE_ITER then
                return self[2], self[3], self[4]
            elseif type == XDICT_TYPE_DICT then
                return self[2]:GetIterator()
            elseif type == XDICT_TYPE_PAIR then
                return iterforpair(self[2], self[3])
            end
        end

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{ RawTable }
        function __new(_, dict) return { XDICT_TYPE_ITER, pairs(dict) }, true end

        __Arguments__{ RawTable + IList, RawTable + IList }
        function __new(_, lstKey, lstValue) return { XDICT_TYPE_PAIR, lstKey, lstValue }, true end

        __Arguments__{ IDictionary }
        function __new(_, dict) return { XDICT_TYPE_DICT, dict }, true end

        __Arguments__{ Callable, Any/nil, Any/nil }
        function __new(_, iter, obj, idx) return { XDICT_TYPE_ITER, iter, obj, idx }, true end
    end)

    --- the dictionary stream worker, used to provide stream filter, map and
    -- etc operations on a dictionary without creating any temp caches
    __Final__() __Sealed__() __SuperObject__(false)
    __NoRawSet__(false) __NoNilValue__(false)
    class "DictionaryStreamWorker" (function (_ENV)
        extend "IDictionary"

        export {
            DictionaryStreamWorker,

            type                = type,
            yield               = coroutine.yield,
            tinsert             = table.insert,
            tremove             = table.remove,
        }

        -----------------------------------------------------------
        --                        helpers                        --
        -----------------------------------------------------------
        local getIdleworkers
        local rycIdleworkers

        if Platform.MULTI_OS_THREAD then
            getIdleworkers      = Toolset.fakefunc
            rycIdleworkers      = Toolset.fakefunc
        else
            -- Keep idle workers for re-usage
            local idleworkers   = {}
            getIdleworkers      = function() return tremove(idleworkers) end
            rycIdleworkers      = function(worker) tinsert(idleworkers, worker) end
        end

        -----------------------------------------------------------
        --                       constant                        --
        -----------------------------------------------------------
        export {
            FLD_TARGETDICT      = 0,
            FLD_MAPACTITON      = 1,
            FLD_FILTERACTN      = 2,
        }
        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        __Iterator__()
        function GetIterator(self)
            local targetDict    = self[FLD_TARGETDICT]
            local map           = self[FLD_MAPACTITON]
            local filter        = self[FLD_FILTERACTN]

            -- Clear self and put self into recycle
            self[FLD_TARGETDICT] = nil
            self[FLD_MAPACTITON] = nil
            self[FLD_FILTERACTN] = nil

            rycIdleworkers(self)

            -- Generate the iterator
            local dowork

            -- Generate the do-work
            if filter then
                -- Check Function
                if map then
                    for key, value in targetDict:GetIterator() do
                        if filter(key, value) then
                            value = map(key, value)
                            if value ~= nil then
                                yield(key, value)
                            end
                        end
                    end
                else
                    for key, value in targetDict:GetIterator() do
                        if filter(key, value) then yield(key, value) end
                    end
                end
            else
                -- No filter
                if map then
                    for key, value in targetDict:GetIterator() do
                        value   = map(key, value)
                        if value ~= nil then
                            yield(key, value)
                        end
                    end
                else
                    for key, value in targetDict:GetIterator() do
                        yield(key, value)
                    end
                end
            end
        end

        -----------------------------------------------------------
        --                     Queue method                      --
        -----------------------------------------------------------
        --- Map the items to other type datas
        __Arguments__{ Callable }
        function Map(self, func)
            if self[FLD_MAPACTITON] then return DictionaryStreamWorker(self):Map(func) end
            self[FLD_MAPACTITON] = func
            return self
        end

        --- Used to filter the items with a check function
        __Arguments__{ Callable }
        function Filter(self, func)
            if self[FLD_FILTERACTN] or self[FLD_MAPACTITON] then return DictionaryStreamWorker(self):Filter(func) end
            self[FLD_FILTERACTN] = func
            return self
        end

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{ IDictionary }
        function __ctor(self, dict)
            self[FLD_TARGETDICT] = dict
        end

        -----------------------------------------------------------
        --                      meta-method                      --
        -----------------------------------------------------------
        __Arguments__{ IDictionary }
        function __exist(_, dict)
            local worker = getIdleworkers()
            if worker then worker[FLD_TARGETDICT] = dict end
            return worker
        end
    end)

    __Sealed__()
    interface "IDictionary" (function (_ENV)
        export {
            yield               = coroutine.yield,
        }

        export { DictionaryStreamWorker, ListStreamWorker, XDictionary }

        -----------------------------------------------------------
        --                     Queue method                      --
        -----------------------------------------------------------
        --- Map the items to other type datas
        __Arguments__{ Callable }
        function Map(self, func) return DictionaryStreamWorker(self):Map(func) end

        --- Used to filter the items with a check function
        __Arguments__{ Callable }
        function Filter(self, func) return DictionaryStreamWorker(self):Filter(func) end

        -----------------------------------------------------------
        --                     Final method                      --
        -----------------------------------------------------------
        --- Convert the selected items to a raw hash table
        function ToTable(self)
            local result        = {}
            for key, value in self:GetIterator() do result[key] = value end
            return result
        end

        --- Convert the selected items to a dictionary
        __Arguments__{ -IDictionary/Dictionary }
        function ToDict(self, cls) return cls(self) end

        --- Save the link operations into a xdictionary so we can use it as a new start for link operations
        function ToXDict(self) return XDictionary(self) end

        --- Combine the key-value pairs to get a result
        __Arguments__{ Callable, Any/nil }
        function Reduce(self, func, init)
            for key, value in self:GetIterator() do init = func(key, value, init) end
            return init
        end

        --- Call the function for each element or set property's value for each element
        __Arguments__{ Callable, Any * 0 }
        function Each(self, func, ...) for key, value in self:GetIterator() do func(key, value, ...) end end

        --- get the keys
        __Iterator__()
        function GetKeys(self)
            local index = 0
            for key in self:GetIterator() do
                index = index + 1
                yield(index, key)
            end
        end

        -- get the values
        __Iterator__()
        function GetValues(self)
            local index = 0
            for _, value in self:GetIterator() do
                index = index + 1
                yield(index, value)
            end
        end

        -----------------------------------------------------------
        --                     list property                     --
        -----------------------------------------------------------
        --- Get a list stream worker of the dictionary's keys
        property "Keys" {
            Get = function (self)
                return ListStreamWorker( self:GetKeys() )
            end
        }

        --- Get a list stream worker of the dictionary's values
        property "Values" {
            Get = function (self)
                return ListStreamWorker( self:GetValues() )
            end
        }
    end)
end)
