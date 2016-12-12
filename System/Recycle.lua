--========================================================--
--                System.Recycle                          --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2015/07/22                              --
--========================================================--

--========================================================--
_ENV = Module     "System.Recycle"                   "1.1.0"
--========================================================--

namespace "System"

__Doc__[[
    Recycle is used as an object factory and recycle manager.

    Recycle's constructor receive a class or struct as it's first argument, the class|struct would be used to generate a new object for recycling.
    The other arugments for the constructor is passed to the class|struct's constructor as init arugments, and if one argument is string and containts '%d', the '%d' will be converted to the factory index.The factory index in alwasy increased by 1 when a new object is created.

    After the recycle object is created as 'recycleObject', you can use 'recycleObject()' to get an un-used object, and use 'recycleObject(object)' to put no-use object back for another query.

        ry = Recycle( class { print }, "Name%d" )

        -- table: 00FA96B0  Name1
        o = ry()
        -- table: 00F4B730  Name2
        o = ry()

    Also you can give the recycle object a "New" method used to generate the new object if the creation of the recycled object is too complex like :

        -- The class would print all arguments when its object created
        ry = Recycle( class { print } )

        function ry:New()
            -- Add a count for it
            self.Cnt = (self.Cnt or 0) + 1
            return self.Type(self.Cnt)
        end

        -- Only one object would be created
        o = ry()
        ry(o)
        o = ry()
]]
__Sealed__()
class "Recycle" (function(_ENV)
    ------------------------------------------------------
    -- Event
    ------------------------------------------------------
    __Doc__[[
        <desc>Fired when an no-used object is put in</desc>
        <param name="object">no-used object</param>
    ]]
    event "OnPush"

    __Doc__[[
        <desc>Fired when an un-used object is send out</desc>
        <param name="object">send-out object</param>
    ]]
    event "OnPop"

    __Doc__[[
        <desc>Fired when a new object is created</desc>
        <param name="object">the new object</param>
    ]]
    event "OnInit"

    local function parseArgs(self)
        if not self.Arguments then return end

        local index = (self.Index or 0) + 1
        self.Index = index

        self.__NowArgs = self.__NowArgs or {}

        for i, arg in ipairs(self.Arguments) do
            if type(arg) == "string" and arg:find("%%d") then
                arg = arg:format(index)
            end

            self.__NowArgs[i] = arg
        end

        return unpack(self.__NowArgs)
    end

    ------------------------------------------------------
    -- Method
    ------------------------------------------------------
    __Doc__[[ Create a new recycled object, should be overwrited.]]
    function New(self)
        if not self.Type then
            return {}
        else
            return self.Type(parseArgs(self))
        end
    end

    __Doc__[[
        <desc>Push object in recycle bin</desc>
        <param name="object">the object that put in</param>
    ]]
    function Push(self, obj)
        if obj then
            -- Won't check obj because using cache means want quick-using.
            tinsert(self, obj)

            return OnPush(self, obj)
        end
    end

    __Doc__[[
        <desc>Pop object from recycle bin</desc>
        <return name="object">the object that pop out</return>
    ]]
    function Pop(self)
        local ret = tremove(self)

        if not ret then
            ret = self:New()
            OnInit(self, ret)
        end

        OnPop(self, ret)

        return ret
    end

    ------------------------------------------------------
    -- Property
    ------------------------------------------------------
    __Doc__[[The recycled object's type]]
    property "Type" { Type = Struct + Class }

    ------------------------------------------------------
    -- Constructor
    ------------------------------------------------------
    __Doc__ [[
        <param name="class" type="class">the class used to generate objects</param>
        <param name="...">the arguments that transform to the class's constructor</param>
    ]]
    __Arguments__{ Struct + Class, { IsList = true, Nilable = true } }
    function Recycle(self, cls, ...)
        if type(cls) == "string" then cls = Reflector.GetNameSpaceForName(cls) end

        if cls and (Reflector.IsClass(cls) or Reflector.IsStruct(cls)) then
            self.Type = cls
            self.Arguments = select('#', ...) > 0 and {...}
        end
    end

    ------------------------------------------------------
    -- __call
    ------------------------------------------------------
    function __call(self, obj)
        if obj then
            return Push(self, obj)
        else
            return Pop(self)
        end
    end
end)