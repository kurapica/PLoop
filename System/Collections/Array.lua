--===========================================================================--
--                                                                           --
--                         System.Collections.Array                          --
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

    --- The array of objects with event control
    -- @usage
    --      class "A" {
    --          -- Property
    --          Name = { Type = String, Event = "OnNameChanged", Default = "Anonymous" };
    --
    --          -- Constructor
    --          A = function(self, name) self.Name = name end;
    --      }
    --
    --     -- The Array is a template class, you can specific the element class
    --      ar = Array[A](A("Ann"), A("Ben"), A("Coco"))
    --
    --      -- You can set event handler to all objects by assign it to the array
    --      function ar:OnNameChanged(new, old)
    --          print( ("%s -> %s"):format(old, new)  )
    --      end
    __ObjFuncAttr__() __Template__( Any ) __SuperObject__(false)
    class "Array" (function(_ENV, eletype)
        inherit (List[eletype])

        -----------------------------------------------------------
        --                        helper                         --
        -----------------------------------------------------------
        local insert            = List.Insert
        local addeventlistener  = function() end


        if Interface.Validate(eletype) or Class.Validate(eletype) then
            export {
                getfeature      = Interface.GetFeature,
                validevent      = Event.Validate,
                rawget          = rawget,
                rawset          = rawset,
                pairs           = pairs,
                ARRAY_EVENT     = "__PLOOP_ARRAY_EVENT"
            }

            export { Event }

            function addeventlistener(self, obj)
                local evts      = rawget(self, ARRAY_EVENT)
                if evts then
                    for k, v in pairs(obj) do
                        obj[k]  = v
                    end
                end
            end
        end

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        __Arguments__{ Integer, eletype }
        function Insert(self, idx, obj)
            insert(self, idx, obj)
            addeventlistener(self, obj)
        end

        __Arguments__{ eletype }
        function Insert(self, obj)
            insert(self, obj)
            addeventlistener(self, obj)
        end

        -----------------------------------------------------------
        --                      constructor                      --
        -----------------------------------------------------------
        __Arguments__{ Variable.Rest(eletype) }
        function __new(cls, ...)
            return {...}, true
        end

        -----------------------------------------------------------
        --                      meta-method                      --
        -----------------------------------------------------------
        if Interface.Validate(eletype) or Class.Validate(eletype) then
            __Arguments__{ String, Callable }
            function __newindex(self, key, value)
                local evt = getfeature(eletype, key)
                if evt and validevent(evt) then
                    local evts  = rawget(self, ARRAY_EVENT) or {}
                    rawset(self, ARRAY_EVENT, evts)
                    evts[key]   = value

                    self:Each(key, value)
                else
                    error("The " .. tostring(eletype) .. " don't have an event named " .. tostring(key), 2)
                end
            end
        else
            function __newindex(self, key)
                error("The " .. tostring(eletype) .. " don't have an event named " .. tostring(key), 2)
            end
        end
    end)
end)