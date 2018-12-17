--===========================================================================--
--                                                                           --
--                         System.Collections.Proxy                          --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2016/02/28                                               --
-- Update Date  :   2018/05/12                                               --
-- Version      :   1.1.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    import "System.Serialization"

    --- The safe dictionary, it'll create the object as proxy to the real table
    __Sealed__() __Serializable__() __Arguments__{ AnyType, AnyType }( Any, Any )
    __NoNilValue__(false):AsInheritable() __NoRawSet__(false):AsInheritable()
    class "System.Collections.Proxy" (function (_ENV, keytype, valtype)
        extend "IDictionary" "ISerializable"

        export {
            ipairs              = ipairs,
            pairs               = pairs,
            GetErrorMessage     = Struct.GetErrorMessage,
            yield               = coroutine.yield,

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
            local key   = info:GetValue(1, List[keytype])
            local val   = info:GetValue(2, List[valtype])

            return this(_, key, val)
        end

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        function GetIterator(self)
            return pairs(self[0])
        end

        --- Update the dictionary
        if keytype == Any and valtype == Any then
            __Arguments__{ RawTable }
            function Update(self, dict)
                for k, v in pairs(dict) do self[0][k] = v end
                return self
            end

            __Arguments__{ IDictionary }
            function Update(self, dict)
                for k, v in dict:GetIterator() do self[0][k] = v end
                return self
            end

            __Arguments__{ Callable, System.Any/nil, System.Any/nil }
            function Update(self, iter, obj, idx)
                for k, v in iter, obj, idx do self[0][k] = v end
                return self
            end
        elseif keytype == Any and valtype ~= Any then
            __Arguments__{ RawTable }
            function Update(self, dict)
                for k, v in pairs(dict) do
                    local ret, msg      = vvalid(valtype, v, true)
                    if not msg then
                        self[0][k]      = v
                    end
                end
                return self
            end

            __Arguments__{ IDictionary }
            function Update(self, dict)
                for k, v in dict:GetIterator() do
                    local ret, msg      = vvalid(valtype, v, true)
                    if not msg then
                        self[0][k]      = v
                    end
                end
                return self
            end

            __Arguments__{ Callable, System.Any/nil, System.Any/nil }
            function Update(self, iter, obj, idx)
                for k, v in iter, obj, idx do
                    local ret, msg      = vvalid(valtype, v, true)
                    if not msg then
                        self[0][k]      = v
                    end
                end
                return self
            end
        elseif keytype ~= Any and valtype == Any then
            __Arguments__{ RawTable }
            function Update(self, dict)
                for k, v in pairs(dict) do
                    local ret, msg      = kvalid(keytype, k, true)
                    if not msg then
                        self[0][k]      = v
                    end
                end
                return self
            end

            __Arguments__{ IDictionary }
            function Update(self, dict)
                for k, v in dict:GetIterator() do
                    local ret, msg      = kvalid(keytype, k, true)
                    if not msg then
                        self[0][k]      = v
                    end
                end
                return self
            end

            __Arguments__{ Callable, System.Any/nil, System.Any/nil }
            function Update(self, iter, obj, idx)
                for k, v in iter, obj, idx do
                    local ret, msg      = kvalid(keytype, k, true)
                    if not msg then
                        self[0][k]      = v
                    end
                end
                return self
            end
        else
            __Arguments__{ RawTable }
            function Update(self, dict)
                for k, v in pairs(dict) do
                    local ret, msg      = kvalid(keytype, k, true)
                    if not msg then
                        ret, msg        = vvalid(valtype, v, true)
                        if not msg then
                            self[0][k]  = v
                        end
                    end
                end
                return self
            end

            __Arguments__{ IDictionary }
            function Update(self, dict)
                for k, v in dict:GetIterator() do
                    local ret, msg      = kvalid(keytype, k, true)
                    if not msg then
                        ret, msg        = vvalid(valtype, v, true)
                        if not msg then
                            self[0][k]  = v
                        end
                    end
                end
                return self
            end

            __Arguments__{ Callable, System.Any/nil, System.Any/nil }
            function Update(self, iter, obj, idx)
                for k, v in iter, obj, idx do
                    local ret, msg      = kvalid(keytype, k, true)
                    if not msg then
                        ret, msg        = vvalid(valtype, v, true)
                        if not msg then
                            self[0][k]  = v
                        end
                    end
                end
                return self
            end
        end

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- Gets or sets the value associated with the specified key
        __Indexer__(keytype ~= Any and keytype or nil)
        property "Item" {
            get         = function(self, key)
                return self[0][key]
            end,
            set         = function(self, key, value)
                self[0][key] = value
            end,
            type        = valtype ~= Any and valtype or nil,
        }

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{ }
        function __new() return { [0] = {} } end

        __Arguments__{ RawTable }
        function __new(_, dict) return { [0] = dict }, true end

        __Arguments__{ RawTable + IList, RawTable + IList }
        function __new(_, lstKey, lstValue)
            local dict  = {}
            local iter, o, idx, value = (lstValue.GetIterator or ipairs)(lstValue)
            for _, key in (lstValue.GetIterator or ipairs)(lstKey) do
                idx, value = iter(o, idx)
                if idx then
                    dict[key] = value
                else
                    break
                end
            end
            return { [0] = dict }, true
        end

        __Arguments__{ IDictionary }
        function __new(_, dict)
            local dict  = {}
            for key, value in dict:GetIterator() do
                dict[key] = value
            end
            return { [0] = dict }, true
        end

        __Arguments__{ Callable, Any/nil, Any/nil }
        function __new(_, iter, obj, idx)
            local dict  = {}
            for key, value in iter, obj, idx do
                dict[key] = value
            end
            return { [0] = dict }, true
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
        end
        function __newindex(self, key, val)
            self[0][key]= val
        end

        function __index(self, key)
            return self[0][key]
        end
    end)
end)
