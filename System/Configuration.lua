--===========================================================================--
--                                                                           --
--                           System.Configuration                            --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2018/05/11                                               --
-- Update Date  :   2018/05/11                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
	namespace "System.Configuration"

	--- The config section used as a container for configurations
	__Sealed__() class "ConfigSection" (function(_ENV)
		export { "pairs", Enum, Struct, Interface, Class, Any }

		field {
			__Fields 	= {},
			__Sections 	= {},
		}

        -----------------------------------------------------------
        --                        method                         --
        -----------------------------------------------------------
		--- Add field with struct type
		__Arguments__{ String, StructType/Any, Callable/nil }
		function AddField(self, name, type, handler)
			local valid
			if type ~= Any then
				if Enum.Validate(type) then
					valid = Enum.ValidateValue
				elseif Struct.Validate(type) then
					valid = Struct.ValidateValue
				elseif Interface.Validate(type) then
					valid = Interface.ValidateValue
				elseif Class.Validate(type) then
					valid = Class.ValidateValue
				end
			end
			self.__Fields[name] 	= { [0] = valid, type, handler }
			self.__Sections[name] 	= nil
		end

		--- Add section
		__Arguments__{ String, ConfigSection, Callable/nil }
		function AddSection(self, name, section, handler)
			self.__Sections[name] 	= { section, handler }
			self.__Fields[name] 	= nil
		end

		__Arguments__{ Table, Any * 0 }
		function ParseConfig(self, config, ...)
			local msg

			for name, val in pairs(config) do
				local fldset 		= self.__Fields[name]
				if fldset then
					if fldset[0] then
						val, msg 	= fldset[0](fldset[1], val)
						if msg then return nil, msg:gsub("%%s", "%%s" .. "." .. name) end
						config[name]= val
					end
					if fldset[2] then
						fldset[2](name, val, ...)
					end
				end

				local secset 		= self.__Sections[name]
				if secset then
					val, msg 		= secset[1]:ParseConfig(val)
					if msg then return nil, msg:gsub("%%s", "%%s" .. "." .. name) end
					config[name] 	= val
					if secset[2] then
						secset[2](name, val, ...)
					end
				end
			end

			return config
		end
	end)
end)
