--===========================================================================--
--                                                                           --
--                              System.Recycle                               --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2015/07/22                                               --
-- Update Date  :   2018/03/15                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System"

    --- Recycle is used as an object factory and recycle manager.
    --
    -- Recycle's constructor receive a class or struct as it's first argument,
    -- the class|struct would be used to generate a new object for recycling.
    -- The other arugments for the constructor is passed to the class|struct's
    -- constructor as init arugments, if one argument is string and containts
    -- '%d', the '%d' will be converted to the factory index.The factory index
    -- in alwasy increased by 1 when a new object is created.
    --
    -- After the recycle object is created as 'recycleObject', you can use
    -- 'recycleObject()' to get an object, and use 'recycleObject(object)'
    -- to put the object back for another query.
    --
    --     ry = Recycle( class { print }, "Name%d" )
    --     -- table: 00FA96B0  Name1
    --     o = ry()
    --     -- table: 00F4B730  Name2
    --     o = ry()
    --
    -- Also you can give the recycle object a "New" method used to generate the
    -- new object if the creation of the recycled object is too complex like :
    --
    --     -- The class would print all arguments when its object created
    --     ry = Recycle( class { print } )
    --
    --     function ry:New()
    --         -- Add a count for it
    --         self.Cnt = (self.Cnt or 0) + 1
    --         return self.Type(self.Cnt)
    --     end
    --
    __Sealed__() __NoRawSet__(false) __NoNilValue__(false)
    class "Recycle"                     (function(_ENV)
        export                          {
            type                        = type,
            ipairs                      = ipairs,
            unpack                      = table.unpack or unpack,
            tinsert                     = table.insert,
            tremove                     = table.remove,
            strfind                     = string.find,
            strformat                   = string.format,
        }

        -----------------------------------------------------------
        --                        helper                         --
        -----------------------------------------------------------
        local function parseArgs(self, ...)
            local index                 = (self.__index or 0) + 1
            self.__index                = index

            local cache                 = self.__args or {}

            for i, arg in ipairs(self.__arguments) do
                if type(arg) == "string" and strfind(arg, "%%d") then
                    arg                 = strformat(arg, index)
                end

                cache[i]                = arg
            end

            self.__args                 = cache

            return unpack(cache)
        end

        -----------------------------------------------------------
        --                         event                         --
        -----------------------------------------------------------
        --- Fired when an no-used object is put in
        -- @param   object
        event "OnPush"

        --- Fired when an un-used object is send out
        -- @param   object
        event "OnPop"

        --- Fired when a new object is created
        -- @param   object
        event "OnInit"

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        --- Create a new recycled object, should be overwrited
        function New(self)
            if not self.Type then
                return {}
            elseif self.__arguments then
                if self.__needparse then
                    return self.Type(parseArgs(self))
                else
                    return self.Type(unpack(self.__arguments))
                end
            else
                return self.Type()
            end
        end

        --- Push object into the recycle bin
        -- @param   object              the object that put in
        function Push(self, obj)
            if obj then
                for i, v in ipairs(self) do if v == obj then return end end
                -- Won't check obj because using cache means want quick-using.
                tinsert(self, obj)

                return OnPush(self, obj)
            end
        end

        --- Pop object from recycle bin
        -- @return  object              the object that pop out
        function Pop(self)
            local ret                   = tremove(self)

            if not ret then
                ret                     = self:New()
                OnInit(self, ret)
            end

            OnPop(self, ret)

            return ret
        end

        -----------------------------------------------------------
        --                       property                        --
        -----------------------------------------------------------
        --- The recycled object's type
        property "Type"                 { Type = StructType + ClassType }

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{ Variable("type", StructType + ClassType, true), Any * 0 }
        function Recycle(self, cls, ...)
            if cls then
                self.Type               = cls
                self.__arguments        = select('#', ...) > 0 and {...} or false
                if self.__arguments then
                    self.__needparse    = false
                    for _, arg in ipairs(self.__arguments) do
                        if type(arg) == "string" and arg:find("%%d") then
                            self.__needparse = true
                            break
                        end
                    end
                end
            end
        end

        -----------------------------------------------------------
        --                      meta-method                      --
        -----------------------------------------------------------
        function __call(self, obj) if obj then return self:Push(obj) else return self:Pop() end end
    end)
end)
