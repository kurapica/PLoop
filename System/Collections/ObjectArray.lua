--========================================================--
--                System.Collections.ObjectArray          --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2016/10/25                              --
--========================================================--

--========================================================--
_ENV = Module     "System.Collections.ObjectArray"   "0.0.1"
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

        -- The arguments are the object and other event arguments
        function ar:OnNameChanged(obj, new, old)
            print( ("%s -> %s"):format(old, new)  )
        end
    </usage>
]]
__SimpleClass__() __Sealed__()
class "ObjectArray" (function(_ENV)
    inherit "List"

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    local GetValidatedValue = System.Reflector.GetValidatedValue


    ----------------------------------------------
    -------------------- Event -------------------
    ----------------------------------------------


    ----------------------------------------------
    ------------------- Method -------------------
    ----------------------------------------------


    ----------------------------------------------
    ------------------ Property ------------------
    ----------------------------------------------
    __Doc__[[The object type of the array, it'll remove unvalid items when changed.]]
    __Handler__(function(self, otype)
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
    end)
    property "ObjectType" { Type = AnyType }


    ----------------------------------------------
    ------------------ Dispose -------------------
    ----------------------------------------------
    function Dispose(self)
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
        print(key, value)
    end

    __Arguments__{ PositiveInteger, Any }
    function __newindex(self, key, value)
        print(key, value)
    end
end)