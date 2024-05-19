--===========================================================================--
--                                                                           --
--                       System.Reactive.ReactiveField                        --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2023/10/25                                               --
-- Update Date  :   2024/05/09                                               --
-- Version      :   2.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    --- Represents the field in reactive objects
    __Sealed__()
    __Arguments__{ AnyType/nil }
    class"System.Reactive.ReactiveField"(function(_ENV, valtype)
        inherit "Subject"

        export {
            max                         = math.max,
            select                      = select,
            rawget                      = rawget,
            unpack                      = _G.unpack or table.unpack,
            subscribe                   = Subject.Subscribe,
            onnext                      = Subject.OnNext,
            onerror                     = Subject.OnError,
            isobjecttype                = Class.IsObjectType,
            geterrormessage             = Struct.GetErrorMessage,
            getvalue                    = function(self)
                if isobjecttype(self, ReactiveField) then
                    return self[1]
                else
                    return self
                end
            end,

            ReactiveField, RawTable
        }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        --- Subscribe the observer
        function Subscribe(self, ...)
            local subscription, observer= subscribe(self, ...)
            local length                = self[0]
            if length > 0 then
                observer:OnNext (unpack(self, 1, length))
            elseif length < 0 then
                observer:OnError(unpack(self, 1,-length))
            end
            return subscription, observer
        end

        --- Provides the observer with new data
        if valtype then
            if Platform.TYPE_VALIDATION_DISABLED and getmetatable(valtype).IsImmutable(valtype) then
                function OnNext(self, val)
                    self[0]             = 1
                    self[1]             = val
                    return onnext(self, val)
                end

            else
                local valid             = getmetatable(valtype).ValidateValue
                function OnNext(self, val)
                    local ret, msg      = valid(valtype, val)
                    if msg then return onerror(self, geterrormessage(msg, "value")) end
                    self[0]             = 1
                    self[1]             = ret
                    return onnext(self, ret)
                end
            end
        else
            function OnNext(self, ...)
                local length            = max(1, select("#", ...))
                self[0]                 = length

                if length <= 2 then
                    self[1], self[2]    = ...
                else
                    for i = 1, length, 2 do
                        self[i], self[i+1]  = select(i, ...)
                    end
                end
                return onnext(self, ...)
            end
        end

        -- Send the error message
        function OnError(self, ...)
            local length                = max(1, select("#", ...))
            self[0]                     =-length

            if length <= 2 then
                self[1], self[2]        = ...
            else
                for i = 1, length, 2 do
                    self[i], self[i+1]  = select(i, ...)
                end
            end
            return onerror(self, ...)
        end

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        --- Whether always connect the observable
        property "KeepAlive"            { type = Boolean, default = true }

        --- The current value, use handler not set to detect the value change
        property "Value"                { type = valtype, field = 1, handler = "OnNext" }

        -----------------------------------------------------------------------
        --                            constructor                            --
        -----------------------------------------------------------------------
        -- Binding the behavior subject to a reactive object's field
        __Arguments__{ Reactive, String }
        function __ctor(self, react, field)
            super(self)

            local raw                   = rawget(react, RawTable)

            self[0]                     = 1
            self[1]                     = raw and raw[field]

            subscribe(self, function(value)
                local raw               = rawget(react, RawTable)
                if raw then raw[field]  = value end
            end)
        end

        -- Generate behavior subject based on other observable
        __Arguments__{ IObservable }
        function __ctor(self, observable)
            super(self, observable)

            self[0]                     = 0
        end

        -- Binding the behavior subject to a container's field
        __Arguments__{ Table, String }
        function __ctor(self, container, field)
            super(self)

            self[0]                     = 1
            self[1]                     = container[field]

            subscribe(self, function(value)
                container[field]        = value
            end)
        end

        -- Generate behavior subject with init data
        if valtype then
            __Arguments__{ valtype/nil }
        else
            __Arguments__{ Any * 0 }
        end
        function __ctor(self, ...)
            super(self)

            local length                = max(1, select("#", ...))
            self[0]                     = length
            for i = 1, length, 2 do
                self[i], self[i + 1]    = select(i, ...)
            end
        end

        -----------------------------------------------------------------------
        --                            meta-method                            --
        -----------------------------------------------------------------------
        function __tostring(self)       return tostring(self.Value) end

        -- the addition operation
        function __add(a, b)            return getvalue(a) + getvalue(b) end

        -- the subtraction operation
        function __sub(a, b)            return getvalue(a) - getvalue(b) end

        -- the multiplication operation
        function __mul(a, b)            return getvalue(a) * getvalue(b) end

        -- the division operation
        function __div(a, b)            return getvalue(a) / getvalue(b) end

        -- the modulo operation
        function __mod(a, b)            return getvalue(a) % getvalue(b) end

        -- the exponentiation operation
        function __pow(a, b)            return getvalue(a) ^ getvalue(b) end

        -- the negation operation
        function __unm(a)               return - getvalue(a) end

        -- the concatenation operation
        function __concat(a, b)         return getvalue(a) .. getvalue(b) end

        -- the length operation, those won't works in 5.1
        function __len(a)               return #getvalue(a) end

        -- the equal operation
        function __eq(a, b)             return getvalue(a) == getvalue(b) end

        -- the less than operation
        function __lt(a, b)             return getvalue(a) < getvalue(b) end

        -- the less equal operation
        function __le(a, b)             return getvalue(a) <= getvalue(b) end

        if _G._VERSION and tonumber(_G._VERSION:match("[%d%.]+$")) * 10 >= 53 then
            Toolset.loadsnippet([[
                -- the floor division operation
                function __idiv(a, b)           return getvalue(a) // getvalue(b) end

                -- the bitwise AND operation
                function __band(a, b)           return getvalue(a) & getvalue(b) end

                -- the bitwise OR operation
                function __bor(a, b)            return getvalue(a) | getvalue(b) end

                -- the bitwise exclusive OR operation
                function __bxor(a, b)           return getvalue(a) ~ getvalue(b) end

                -- the bitwise NOToperation
                function __bnot(a)              return ~getvalue(a) end

                -- the bitwise left shift operation
                function __shl(a, b)            return getvalue(a) << getvalue(b) end

                -- the bitwise right shift operation
                function __shr(a, b)            return getvalue(a) >> getvalue(b) end
            ]], "ReactiveField_Patch_53", _ENV)()
        end
    end)
end)