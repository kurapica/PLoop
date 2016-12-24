--========================================================--
--                System.Collections.ObjectArray          --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2016/10/25                              --
--========================================================--

--========================================================--
_ENV = Module     "System.Collections.ObjectArray"   "1.0.0"
--========================================================--

namespace "System.Collections"

__Doc__[[
    <desc>The object array with event control</desc>
    <usage>
        class "A" {
            -- Property
            Name = { Type = String, Event = "OnNameChanged", Default = "Anonymous" };

            -- Constructor
            A = function(self, name) self.Name = name end;
        }

        -- The array won't check the object's Type for simple using
        ar = ObjectArray(A, A("Ann"), A("Ben"), A("Coco"))

        -- You can set event handler to all objects by assign it to the array
        function ar:OnNameChanged(new, old)
            print( ("%s -> %s"):format(old, new)  )
        end
    </usage>
]]
__SimpleClass__() __Sealed__() __ObjMethodAttr__()
class "ObjectArray" (function(_ENV)
    inherit "List"

    _ArrayTypeMap   = setmetatable({}, {__mode="k"})
    _ArrayEventMap  = setmetatable({}, {__mode="k"})

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    local GetValidatedValue = System.Reflector.GetValidatedValue
    local HasEvent          = System.Reflector.HasEvent

    local function checkNewObj(self, obj)
        if self.ObjectType then
            local obj = GetValidatedValue(self.ObjectType, obj)
            if obj == nil then
                error("ObjectArray:Insert([index, ]object) - object should be type of " .. tostring(self.ObjectType), 3)
            end
            if _ArrayEventMap[self] then
                for k, v in pairs(_ArrayEventMap[self]) do
                    obj[k] = v
                end
            end
        end
        return obj
    end

    ----------------------------------------------
    ------------------- Method -------------------
    ----------------------------------------------
    __Arguments__{ Integer, Any }
    function Insert(self, idx, obj)
        return Super.Insert(self, idx, checkNewObj(self, obj))
    end

    __Arguments__{ Any }
    function Insert(self, obj)
        return Super.Insert(self, checkNewObj(self, obj))
    end

    ----------------------------------------------
    ------------------ Property ------------------
    ----------------------------------------------
    __Doc__[[The object type of the array, it'll remove unvalid items when changed.]]
    property "ObjectType" {
        Type = AnyType,
        Set  = function(self, otype)
            if otype then
                for i = self.Count, 1, -1 do
                    local val = GetValidatedValue(otype, self[i])

                    if val == nil then
                        self:RemoveByIndex(i)
                    else
                        self[i] = val
                    end
                end
            end
            _ArrayTypeMap[self] = otype
        end,
        Get  = function(self)
            return _ArrayTypeMap[self]
        end,
    }


    ----------------------------------------------
    ------------------ Dispose -------------------
    ----------------------------------------------
    function Dispose(self)
        _ArrayTypeMap[self]  = nil
        _ArrayEventMap[self] = nil
    end

    ----------------------------------------------
    ----------------- Constructor ----------------
    ----------------------------------------------
    __Arguments__{ AnyType, Argument{ Type = Any, IsList = true, Nilable = true} }
    function ObjectArray(self, otype, ...)
        Super(self, ...)

        self.ObjectType = otype
    end

    ----------------------------------------------
    ----------------- Meta-method ----------------
    ----------------------------------------------
    __Arguments__{ String, Callable }
    function __newindex(self, key, value)
        if self.ObjectType and HasEvent(self.ObjectType, key) then
            _ArrayEventMap[self] = _ArrayEventMap[self] or {}
            _ArrayEventMap[self][key] = value

            self:Each(key, value)
        else
            error("The object array's type don't have an event named " .. key, 2)
        end
    end
end)