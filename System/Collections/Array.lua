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

    import "System.Serialization"

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
    __ObjFuncAttr__() __SuperObject__(false) __Serializable__()
    __NoRawSet__(false) __NoNilValue__(false) __Arguments__{ AnyType }( Any )
    class "Array" (function(_ENV, eletype)
        inherit (List[eletype])

        -----------------------------------------------------------
        --                        helper                         --
        -----------------------------------------------------------
        local addeventlistener  = function() end

        export {
            parseindex      = Toolset.parseindex,
            getErrorMessage = Struct.GetErrorMessage,
        }

        if Interface.Validate(eletype) or Class.Validate(eletype) then
            export {
                getfeature      = Interface.GetFeature,
                validevent      = Event.Validate,
                rawget          = rawget,
                rawset          = rawset,
                pairs           = pairs,
                tinsert         = table.insert,
                ARRAY_EVENT     = "__PLOOP_ARRAY_EVENT",
            }

            export { Event }

            function addeventlistener(self, obj)
                local evts      = rawget(self, ARRAY_EVENT)
                if evts then
                    for k, v in pairs(evts) do
                        obj[k]  = v
                    end
                end
            end
        end

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
        if Interface.Validate(eletype) or Class.Validate(eletype) then
            __Arguments__{ Integer, eletype }
            function Insert(self, idx, obj)
                tinsert(self, idx, obj)
                addeventlistener(self, obj)
            end

            __Arguments__{ eletype }
            function Insert(self, obj)
                tinsert(self, obj)
                addeventlistener(self, obj)
            end
        end

        -----------------------------------------------------------
        --                      meta-method                      --
        -----------------------------------------------------------
        if Interface.Validate(eletype) or Class.Validate(eletype) then
            __Arguments__{ String, Callable }
            function __newindex(self, key, value)
                local evt       = getfeature(eletype, key)
                if evt and validevent(evt) then
                    local evts  = rawget(self, ARRAY_EVENT) or {}
                    rawset(self, ARRAY_EVENT, evts)
                    evts[key]   = value

                    self:Each(key, value)
                else
                    error("The " .. tostring(eletype) .. " don't have an event named " .. tostring(key), 2)
                end
            end

            __Arguments__{ Number, eletype }
            __newindex          = rawset
        else
            __Arguments__{ String, Callable }
            function __newindex(self, key)
                error("The " .. tostring(eletype) .. " don't have an event named " .. tostring(key), 2)
            end

            __Arguments__{ Number, eletype }
            __newindex          = rawset
        end
    end)
end)