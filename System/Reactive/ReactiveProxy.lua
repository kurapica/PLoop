--===========================================================================--
--                                                                           --
--                       System.Reactive.ReactiveProxy                       --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2023/04/20                                               --
-- Update Date  :   2024/04/01                                               --
-- Version      :   2.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)

    --- The proxy used to make object reactive, maybe include later
    __Sealed__()
    __Arguments__{ ClassType }:WithRebuild()
    __NoNilValue__(false):AsInheritable()
    __NoRawSet__(false):AsInheritable()
    class "System.Reactive.ReactiveProxy"	(function(_ENV, targetclass)
        extend "IObservable"

        export                      	{
            toRaw                   	= Reactive.ToRaw,
            checkRet                	= Platform.ENABLE_TAIL_CALL_OPTIMIZATIONS
                                    	and function(ok, ...) if not ok then error(..., 2) end return ... end
                                    	or  function(ok, ...) if not ok then error(..., 3) end return ... end,

            getObject               	= function(value) return type(value) == "table" and rawget(value, Class) or value end,

            handleEventChange       	= function(delegate, owner, name, init)
                if not init then return end
                local obj           	= rawget(owner, Class)
                obj[name]           	= obj[name] + function(self, ...) return delegate(owner, ...) end
            end,
        }

        ---------------------------------------------------------------
        --                           event                           --
        ---------------------------------------------------------------
        --- fired when the data changed
        event "OnDataChange"

        -- auto property/event generate
        for name, ftr in Class.GetFeatures(targetclass, true) do
            -----------------------------------------------------------
            --                         event                         --
            -----------------------------------------------------------
            if Event.Validate(ftr) then
                __EventChangeHandler__(handleEventChange)
                event(name)

            -----------------------------------------------------------
            --                       property                        --
            -----------------------------------------------------------
            elseif Property.Validate(ftr) then
                if Property.IsIndexer(ftr) then
                    if Property.IsWritable(ftr) then __Observable__() end
                    __Indexer__(Property.GetIndexType(ftr))
                    property (name) {
                        type        = Property.GetType(ftr),
                        get         = Property.IsReadable(ftr) and function(self, idx) return rawget(self, Class)[name][idx] end,
                        set         = Property.IsWritable(ftr) and function(self, idx, value)
                            value   = toRaw(value)
                            rawget(self, Class)[name][idx] = value
                            return OnDataChange(self, name, idx, value)
                        end,
                    }
                else
                    if Property.IsWritable(ftr) then __Observable__() end
                    property (name) {
                        type        = Property.GetType(ftr),
                        get         = Property.IsReadable(ftr) and function(self) return rawget(self, Class)[name] end,
                        set         = Property.IsWritable(ftr) and function(self, value)
                            value   = toRaw(value)
                            rawget(self, Class)[name] = value
                            return OnDataChange(self, name, value)
                        end,
                    }
                end
            end
        end

        ---------------------------------------------------------------
        --                          method                           --
        ---------------------------------------------------------------
        for name, method in Class.GetMethods(targetclass, true) do
            _ENV[name]              	= function(self, ...) return checkRet(pcall(method, rawget(self, Class), ...)) end
        end

        ---------------------------------------------------------------
        --                        constructor                        --
        ---------------------------------------------------------------
        -- bind the reactive and object
        __Arguments__{ targetclass }
        function __ctor(self, init)
            rawset(self, Class, init)
            rawset(init, Reactive, self)
        end

        -- use the wrap for objects
        function __exist(_, init)
            return init and rawget(init, Reactive)
        end

        ---------------------------------------------------------------
        --                        meta-method                        --
        ---------------------------------------------------------------
        for name, method in Class.GetMetaMethods(targetclass, true) do
            if name == "__gc" then
                __dtor              	= function(self) return rawget(self, Class):Dispose() end
            else
                _ENV[name]          	= function(self, other, ...) return method(getObject(self), getObject(other), ...) end
            end
        end
    end)
end)