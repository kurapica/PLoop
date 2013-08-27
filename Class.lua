--[[
Copyright (c) 2011 WangXH <kurapica.igas@gmail.com>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
--]]

-- Class System
-- Author: kurapica.igas@gmail.com
-- Create Date : 2011/02/01
-- ChangeLog   :
--               2011/04/14	System.Reflector added.
--               2011/05/11 Event handlers can run as thread.
--               2011/05/30 System.Reflector.GetParts added.
--               2011/06/24 Property definition ignore case
--               2011/07/04 Struct no longer need Constructor and Validate function
--               2011/07/08 System.Reflector.IsAbstractClass(cls) added
--               2011/07/12 System.Reflector.ParseEnum(enm, value) added
--               2011/07/27 Enum's validation method changed.
--               2011/10/26 Error report update for __index & __newindex
--               2011/10/30 System.Reflector.ConvertClass(obj, cls) added
--               2011/10/31 System.Reflector.InactiveThread added
--               2012/04/10 System.Reflector.IsNameSpace(obj) added
--               2012/05/01 System.Reflector.Validate(type, value) added
--               2012/05/06 System.Reflector.Validate(type, value, name, prefix) mod
--               2012/05/07 System.Reflector.BuildType removed
--               2012/05/14 Type add sub & unm metamethodes
--               2012/05/21 Keyword 'Super' is added to the class environment
--               2012/06/27 Interface system added
--               2012/06/28 Interface can access it's methodes
--               2012/06/29 System.Reflector Update for Interface
--               2012/06/30 BlockEvent, IsEventBlocked, UnBlockEvent added to Reflector
--               2012/07/01 Interface can extend from multi-interface
--               2012/07/08 IFDispose added to support interface disposing
--               2012/07/09 Using cache to keep interface list for class object creation
--               2012/07/26 Fix a stack overflow problem
--               2012/07/31 Improve struct system
--               2012/08/14 Struct namespace object now has Validate method.
--               2012/08/14 Class & Struct env now can access base namespace directly.
--               2012/08/14 Reduce Struct Validate method cost.
--               2012/08/19 Don't block error when create object.
--               2012/08/30 IFDispoe removed, Class system will use Dispose as a system method,
--                          Interface's Dispose will be called first when object call like obj:Dispose(),
--                          then the class's own Dispose will be called,
--                          Class.Dispose will access the class' own Dispose method, not system one.
--               2012/09/07 Fix can't extend interface that defined in the class
--               2012/09/20 class without constructor now will use Super class's constructor.
--                          System.Reflector change to Interface.
--               2012/10/08 Object Method, Property, Event can't start with '_'.
--               2012/10/13 partclass keyword added to support part class definition.
--               2012/11/07 Interface constructor invoking mechanism improved.
--               2012/11/11 Disposing objects when Object created failded.
--               2012/11/14 Fix interface constructor systfem.
--               2012/11/16 Extend interface order system added.
--               2012/12/08 Re-order inherit & extend tree.
--               2012/12/23 Class Constructor system modified.
--               2012/12/24 Dispose system modified.
--               2012/12/25 Doc system added.Interface system improved.
--               2013/01/25 object.Disposed is set to true after calling object:Dispose() as a mark
--               2013/04/07 Lower the memory usage
--               2013/06/24 IGAS:Install([env]) added, used to add keywords into current environment
--               2013/06/26 keyword script -> event
--               2013/08/05 Remove version check, seal the definition environment
--               2013/08/12 System.Module is added to create an environment for oop system
--               2013/08/27 System.Object's method ThreadCall will use the running thread instead of create new one

------------------------------------------------------------------------
-- Class system is used to provide a object-oriented system in lua.
-- With this system, you can created a class like
--
-- namespace "System"				-- define the namespace
--
-- class "MyClass"						-- declare starting to define the class
--		inherit "Object"					-- declare the class is inherited from System.Object
--
--		event "OnNameChanged"	-- declare the class have an event named "OnNameChanged"
--
--		function Print(self)				-- the global functions will be treated as the class's methodes, self means the object
--			print(self._Name)
--		end
--
--		property "Name" {				-- declare the class have a property named "Name"
--			Get = function(self)		-- the get method for property "Name"
--				return self._Name
--			end,
--			Set = function(self, value)	-- the set method for property "Name"
--				self._Name = value
--				self:OnNameChanged(value)	-- fire the "OnNameChanged" event to trigger it's handler functions.
--			end,
--			Type = String,				-- the property "Name"'s type, so when you assign a value to Name, it should be checked.
--		}
--
--		function MyClass(self, name)	-- the function with same name of the class is treated as the Constructor of the class
--			self._Name = name			-- use self to init
--		end
--	endclass "MyClass"					-- declare the definition of the class is over.
--
--	Using MyClass:
--
--	myObj = MyClass("Test")
--
--	myObj:Print()						-- print out : Test
--
--	function myObj:OnNameChanged(name)	-- define the event handler for 'OnNameChanged'
--		print("The Name is changed to "..name)
--	end
--
--	myObj.Name = "Hello"			-- print out : The Name is changed to Hello
------------------------------------------------------------------------

------------------------------------------------------
-- Object oriented program syntax system environment
------------------------------------------------------
do
	-- Local Environment
	setfenv(1, setmetatable({}, {
		__index = function(self,  key)
			if type(key) == "string" and key ~= "_G" and key:find("^_") then
				return
			end

			if _G[key] then
				rawset(self, key, _G[key])
				return rawget(self, key)
			end
		end,

		__metatable = true,
	}))

	-- Common features
	strtrim = strtrim or function(s)
	  return s and (s:gsub("^%s*(.-)%s*$", "%1")) or ""
	end

	wipe = wipe or function(t)
		for k in pairs(t) do
			t[k] = nil
		end
	end

	tinsert = tinsert or table.insert
	tremove = tremove or table.remove
	unpack = unpack
	pcall = pcall
	sort = sort or table.sort

	geterrorhandler = geterrorhandler or function()
		return print
	end

	errorhandler = errorhandler or function(err)
		return pcall(geterrorhandler(), err)
	end
end

------------------------------------------------------
-- Constant Definition
------------------------------------------------------
do
	LUA_OOP_VERSION = 73

	TYPE_CLASS = "Class"
	TYPE_ENUM = "Enum"
	TYPE_STRUCT = "Struct"
	TYPE_INTERFACE = "Interface"

	TYPE_NAMESPACE = "NameSpace"
	TYPE_TYPE = "TYPE"

	-- Disposing method name
	DISPOSE_METHOD = "Dispose"

	-- Namespace field
	NAMESPACE_FIELD = "__LOOP_NameSpace"
end

------------------------------------------------------
-- NameSpace
------------------------------------------------------
do
	_NameSpace = _NameSpace or newproxy(true)

	_NSInfo = _NSInfo or setmetatable({}, {
		__index = function(self, key)
			if not IsNameSpace(key) then
				return
			end

			self[key] = {
				Owner = key,
			}

			return rawget(self, key)
		end,
	})

	-- metatable for class
	_MetaNS = _MetaNS or getmetatable(_NameSpace)
	do
		_MetaNS.__call = function(self, ...)
			local info = _NSInfo[self]

			if info.Type == TYPE_CLASS then
				-- Create Class object
				return Class2Obj(self, ...)
			elseif info.Type == TYPE_STRUCT then
				-- Create Struct
				return Struct2Obj(self, ...)
			end

			error(("%s can't be used as a constructor."):format(tostring(self)), 2)
		end

		_MetaNS.__index = function(self, key)
			local info = _NSInfo[self]

			if info.Type == TYPE_STRUCT then
				if key == "Validate" then
					if not info.Validate then
						BuildStructVFalidate(self)
					end
					return info.Validate
				else
					return info.SubNS and info.SubNS[key]
				end
			elseif info.Type == TYPE_CLASS then
				if info.SubNS and info.SubNS[key] then
					return info.SubNS[key]
				elseif _KeyMeta[key] ~= nil then
					if _KeyMeta[key] then
						return info.MetaTable[key]
					else
						return info.MetaTable["_"..key]
					end
				else
					return info.Cache4Method[key]
				end
			elseif info.Type == TYPE_ENUM then
				return type(key) == "string" and info.Enum[key:upper()] or error(("%s is not an enumeration value of %s."):format(tostring(key), tostring(self)), 2)
			elseif info.Type == TYPE_INTERFACE then
				if info.SubNS and info.SubNS[key] then
					return info.SubNS[key]
				else
					return info.Cache4Method[key]
				end
			else
				return info.SubNS and info.SubNS[key]
			end
		end

		_MetaNS.__newindex = function(self, key, value)
			error(("can't set value for %s, it's readonly."):format(tostring(self)), 2)
		end

		_MetaNS.__add = function(v1, v2)
			local ok, _type1, _type2

			ok, _type1 = pcall(BuildType, v1)
			if not ok then
				_type1 = strtrim(_type1:match(":%d+:(.*)$") or _type1)
				error(_type1, 2)
			end

			ok, _type2 = pcall(BuildType, v2)
			if not ok then
				_type2 = strtrim(_type2:match(":%d+:(.*)$") or _type2)
				error(_type2, 2)
			end

			return _type1 + _type2
		end

		_MetaNS.__sub = function(v1, v2)
			local ok, _type1, _type2

			ok, _type1 = pcall(BuildType, v1)
			if not ok then
				_type1 = strtrim(_type1:match(":%d+:(.*)$") or _type1)
				error(_type1, 2)
			end

			ok, _type2 = pcall(BuildType, v2, nil, true)
			if not ok then
				_type2 = strtrim(_type2:match(":%d+:(.*)$") or _type2)
				error(_type2, 2)
			end

			return _type1 + _type2
		end

		_MetaNS.__unm = function(v1)
			local ok, _type1

			ok, _type1 = pcall(BuildType, v1, nil, true)
			if not ok then
				_type1 = strtrim(_type1:match(":%d+:(.*)$") or _type1)
				error(_type1, 2)
			end

			return _type1
		end

		_MetaNS.__tostring = function(self)
			return GetFullName4NS(self)
		end

		_MetaNS.__metatable = TYPE_NAMESPACE
	end

	-- IsNameSpace
	function IsNameSpace(ns)
		return ns and type(ns) == "userdata" and getmetatable(ns) == TYPE_NAMESPACE or false
	end

	-- BuildNameSpace
	function BuildNameSpace(ns, namelist)
		if type(namelist) ~= "string" or (ns ~= nil and not IsNameSpace(ns)) then
			return
		end

		if namelist:find("%.%s*%.") then
			error("the namespace 's name can't have empty string between dots.", 2)
		end

		local cls = ns
		local info = cls and _NSInfo[cls]
		local parent = cls

		for name in namelist:gmatch("[^%.]+") do
			name = name:match("[_%w]+")

			if not name or name == "" then
				error("the namespace's name must be composed with number, string or '_'.", 2)
			end

			if not info then
				cls = newproxy(_NameSpace)
			elseif info.Type == nil or info.Type == TYPE_CLASS or info.Type == TYPE_STRUCT or info.Type == TYPE_INTERFACE then
				info.SubNS = info.SubNS or {}
				info.SubNS[name] = info.SubNS[name] or newproxy(_NameSpace)

				cls = info.SubNS[name]
			else
				error(("can't add item to a %s."):format(tostring(info.Type)), 2)
			end

			info = _NSInfo[cls]
			info.Name = name
			if not info.NameSpace and parent ~= _NameSpace then
				info.NameSpace = parent
			end
			parent = cls
		end

		if cls == ns then
			return
		end

		return cls
	end

	-- GetNameSpace
	function GetNameSpace(ns, namelist)
		if type(namelist) ~= "string" or not IsNameSpace(ns) then
			return
		end

		if namelist:find("%.%s*%.") then
			error("the namespace 's name can't have empty string between dots.", 2)
		end

		local cls = ns

		for name in namelist:gmatch("[^%.]+") do
			name = name:match("[_%w]+")

			if not name or name == "" then
				error("the namespace's name must be composed with number, string or '_'.", 2)
			end

			cls = cls[name]
			if not cls then
				return
			end
		end

		if cls == ns then
			return
		end

		return cls
	end

	-- GetDefaultNameSpace
	function GetDefaultNameSpace()
		return _NameSpace
	end

	-- SetNameSpace
	function SetNameSpace4Env(env, name)
		if type(env) ~= "table" then
			return
		end

		if type(name) == "string" then
			local ns = BuildNameSpace(GetDefaultNameSpace(), name)

			if ns then
				rawset(env, NAMESPACE_FIELD, ns)
			else
				rawset(env, NAMESPACE_FIELD, nil)
			end
		elseif IsNameSpace(name) then
			rawset(env, NAMESPACE_FIELD, name)
		else
			rawset(env, NAMESPACE_FIELD, nil)
		end
	end

	-- GetEnvNameSpace
	function GetNameSpace4Env(env, rawOnly)
		local ns = type(env) == "table" and ((rawOnly and rawget(env, NAMESPACE_FIELD)) or (not rawOnly and env[NAMESPACE_FIELD]))

		if IsNameSpace(ns) then return ns end
	end

	-- GetFullName4NS
	function GetFullName4NS(ns)
		local info = _NSInfo[ns]

		if info then
			local name = info.Name

			while info and info.NameSpace do
				info = _NSInfo[info.NameSpace]

				if info then
					name = info.Name.."."..name
				end
			end

			return name
		end
	end

	------------------------------------
	--- Set the default namespace for the current environment, the class defined in this environment will be stored in this namespace
	-- @name namespace
	-- @class function
	-- @param name the namespace's name list, using "." to split.
	-- @usage namespace "Widget"
	------------------------------------
	function namespace(name)
		if name ~= nil and type(name) ~= "string" and not IsNameSpace(name) then
			error([[Usage: namespace "namespace"]], 2)
		end

		local fenv = getfenv(2)

		SetNameSpace4Env(fenv, name)
	end
end

------------------------------------------------------
-- Type
------------------------------------------------------
do
	_Meta4Type = _Meta4Type or {}
	do
		_Meta4Type.__add = function(v1, v2)
			local ok, _type1, _type2

			ok, _type1 = pcall(BuildType, v1)
			if not ok then
				_type1 = strtrim(_type1:match(":%d+:(.*)$") or _type1)
				error(_type1, 2)
			end

			ok, _type2 = pcall(BuildType, v2)
			if not ok then
				_type2 = strtrim(_type2:match(":%d+:(.*)$") or _type2)
				error(_type2, 2)
			end

			if _type1 and _type2 then
				local _type = setmetatable({}, _Meta4Type)

				_type.AllowNil = _type1.AllowNil or _type2.AllowNil

				local tmp = {}

				for _, ns in ipairs(_type1) do
					tinsert(_type, ns)
					tmp[ns] = true
				end
				for _, ns in ipairs(_type2) do
					if not tmp[ns] then
						tinsert(_type, ns)
					end
				end

				wipe(tmp)

				local index = -1
				local pos = -1

				while _type1[index] do
					tmp[_type1[index]] = true
					_type[pos] = _type1[index]
					pos = pos -1
					index = index - 1
				end

				index = -1

				while _type2[index] do
					if not tmp[_type2[index]] then
						_type[pos] = _type2[index]
						pos = pos -1
					end
					index = index - 1
				end

				tmp = nil

				return _type
			else
				return _type1 or _type2
			end
		end

		_Meta4Type.__sub = function(v1, v2)
			if IsNameSpace(v2) then
				local ok, _type2

				ok, _type2 = pcall(BuildType, v2, nil, true)
				if not ok then
					_type2 = strtrim(_type2:match(":%d+:(.*)$") or _type2)
					error(_type2, 2)
				end

				return v1 + _type2
			elseif v2 == nil then
				return v1
			else
				error("The operation '-' must be used with class or struct.", 2)
			end
		end

		_Meta4Type.__unm = function(v1)
			error("Can't use unary '-' before a type", 2)
		end

		_Meta4Type.__index = {
			-- value = Type:Validate(value)
			Validate = function(self, value)
				if value == nil and self.AllowNil then
					return value
				end

				local flag, msg, info, new

				local index = -1

                local types = ""

				while self[index] do
					info = _NSInfo[self[index]]

                    new = nil

                    if not info then
                        -- skip
					elseif info.Type == TYPE_CLASS then
						if value and rawget(_NSInfo, value) and _NSInfo[value].Type == TYPE_CLASS and IsChildClass(self[index], value) then
							return value
						end

						new = ("%s must be or must be subclass of [class]%s."):format("%s", tostring(self[index]))
					elseif info.Type == TYPE_INTERFACE then
						if value and rawget(_NSInfo, value) and _NSInfo[value].Type == TYPE_CLASS and IsExtend(self[index], value) then
							return value
						end

						new = ("%s must be extended from [interface]%s."):format("%s", tostring(self[index]))
                    elseif info.Type then
                        if value == info.Owner then
                            return value
                        else
                            types = types .. tostring(info.Owner) .. ", "
                        end
					end

					if new and not msg then
						if self.Name and self.Name ~= "" then
							if new:find("%%s([_%w]+)") then
								msg = new:gsub("%%s", "%%s"..self.Name..".")
							else
								msg = new:gsub("%%s", "%%s"..self.Name)
							end
						else
							msg = new
						end
					end

					index = index - 1
				end

                if types:len() >= 3 and not msg then
                    new = ("%s must be the type in ()."):format("%s", types:sub(1, -3))

                    if self.Name and self.Name ~= "" then
                        if new:find("%%s([_%w]+)") then
                            msg = new:gsub("%%s", "%%s"..self.Name..".")
                        else
                            msg = new:gsub("%%s", "%%s"..self.Name)
                        end
                    else
                        msg = new
                    end
                end

				for _, ns in ipairs(self) do
					info = _NSInfo[ns]

					new = nil

					if not info then
						-- do nothing
					elseif info.Type == TYPE_CLASS then
						-- Check if the value is an instance of this class
						if type(value) == "table" and getmetatable(value) and IsChildClass(ns, getmetatable(value)) then
							return value
						end

						new = ("%s must be an instance of [class]%s."):format("%s", tostring(ns))
					elseif info.Type == TYPE_INTERFACE then
						-- Check if the value is an instance of this interface
						if type(value) == "table" and getmetatable(value) and IsExtend(ns, getmetatable(value)) then
							return value
						end

						new = ("%s must be an instance extended from [interface]%s."):format("%s", tostring(ns))
					elseif info.Type == TYPE_ENUM then
						-- Check if the value is an enumeration value of this enum
						if type(value) == "string" and info.Enum[value:upper()] then
							return info.Enum[value:upper()]
						end

						for _, v in pairs(info.Enum) do
							if value == v then
								return v
							end
						end

						new = ("%s must be a value of [enum]%s ( %s )."):format("%s", tostring(ns), GetShortEnumInfo(ns))
					elseif info.Type == TYPE_STRUCT then
						-- Check if the value is an enumeration value of this structure
						flag, new = pcall(ValidateStruct, ns, value)

						if flag then
							return new
						end

						new = strtrim(new:match(":%d+:(.*)$") or new)
					end

					if new and not msg then
						if self.Name and self.Name ~= "" then
							if new:find("%%s([_%w]+)") then
								msg = new:gsub("%%s", "%%s"..self.Name..".")
							else
								msg = new:gsub("%%s", "%%s"..self.Name)
							end
						else
							msg = new
						end
					end
				end

				if msg and self.AllowNil and not msg:match("%(Optional%)$") then
					msg = msg .. "(Optional)"
				end

				assert(not msg, msg)

				return value
			end,

			-- newType = type:Copy()
			Copy = function(self)
				local _type = setmetatable({}, _Meta4Type)

				for i, v in pairs(self) do
					_type[i] = v
				end

				return _type
			end,

			-- boolean = type:Is(nil)
			-- boolean = type:Is(System.String)
			Is = function(self, ns, onlyClass)
				local fenv = getfenv(2)

				if ns == nil then
					return self.AllowNil or false
				end

				if IsNameSpace(ns) then
					if not onlyClass then
						for _, v in ipairs(self) do
							if v == ns then
								return true
							end
						end
					else
						local index = -1

						while self[index] do
							if self[index] == ns then
								return true
							end
							index = index - 1
						end
					end
				end

				return false
			end,
		}

		_Meta4Type.__metatable = TYPE_TYPE
	end

	function IsType(tbl)
		return type(tbl) == "table" and getmetatable(tbl) == TYPE_TYPE or false
	end

	function BuildType(ns, name, onlyClass)
		local allowNil = false

		if ns == nil then
			allowNil = true
		elseif IsType(ns) then
			if name then
				ns.Name = name
			end
			return ns
		end

		if ns == nil or IsNameSpace(ns) then
			local _type = setmetatable({}, _Meta4Type)

			_type.AllowNil = allowNil or nil

			if ns then
				if onlyClass then
					_type[-1] = ns
				else
					_type[1] = ns
				end
			end

			if name then
				_type.Name = name
			end
			return _type
		else
			error("The type must be nil, struct, enum or class.")
		end
	end
end

------------------------------------------------------
-- Documentation
------------------------------------------------------
do
	_EnableDocument = _EnableDocument == nil and true or _EnableDocument
	_MetaDoc = _MetaDoc or {}
	do
		_MetaDoc.__index = function(self,  key)
			if type(key) ~= "string" or key:match("^_") then return end

			local value, sinfo

			-- Check SuperClass
			local info = rawget(self, "__OwnerInfo")

			if key == "class-" .. info.Name or key == "interface-" .. info.Name or key == "default-" .. info.Name then
				return
			end

			if info.SuperClass then
				sinfo = _NSInfo[info.SuperClass]

				sinfo.Documentation = sinfo.Documentation or setmetatable({__OwnerInfo=sinfo}, _MetaDoc)

				value = sinfo.Documentation[key]
				if value then
					rawset(self, key, value)
					return value
				end
			end

			-- Check Interface
			if info.ExtendInterface then
				for _, IF in ipairs(info.ExtendInterface) do
					sinfo = _NSInfo[IF]

					sinfo.Documentation = sinfo.Documentation or setmetatable({__OwnerInfo=sinfo}, _MetaDoc)

					value = sinfo.Documentation[key]
					if value then
						rawset(self, key, value)
						return value
					end
				end
			end
		end
	end

	------------------------------------
	--- Registe documents
	-- @name document
	-- @class function
	-- @param string the document
	-- @usage document [[
	--	@name IFModule
	--	@type interface
	--	@desc Common methods for class addon and interface
	-- ]]
	------------------------------------
	function document(documentation)
		if not _EnableDocument or type(documentation) ~= "string" then return end

		local env = getfenv(2)
		local info = _IFEnv2Info[env] or _ClsEnv2Info[env]

		if not info then return end

		documentation = documentation:gsub("\n", ""):gsub("\r", ""):gsub("%s+@", "@")

		local name = documentation:match("@name%s+([^@%s]+)")
		local doctype = documentation:match("@type%s(%w+)") or "default"

		if name then
			info.Documentation = info.Documentation or setmetatable({__OwnerInfo=info}, _MetaDoc)
			info.Documentation[doctype .. "-" .. name] = documentation
		end
	end

	function HasDocumentPart(ns, doctype, name)
		if type(ns) == "string" then
			ns = GetNameSpace(GetDefaultNameSpace(), ns)
		end
		local info = rawget(_NSInfo, ns)

		doctype = type(doctype) == "string" and doctype or "default"

		if info and type(name) == "string" then
			info.Documentation = info.Documentation or setmetatable({__OwnerInfo=info}, _MetaDoc)

			if info.Documentation[doctype .. "-" .. name] then
				return true
			end
		end
	end

	function GetDocumentPart(ns, doctype, name, part)
		if type(ns) == "string" then
			ns = GetNameSpace(GetDefaultNameSpace(), ns)
		end
		local info = rawget(_NSInfo, ns)

		doctype = type(doctype) == "string" and doctype or "default"

		if info and type(name) == "string" then
			info.Documentation = info.Documentation or setmetatable({__OwnerInfo=info}, _MetaDoc)

			local value = info.Documentation[doctype .. "-" .. name]

			if value then
				if type(part) == "string" then
					if part == "param" or part == "return" or part == "need" or part == "overridable" then
						if value:match("@" .. part .. "%s+([^@%s]+)%s*([^@]*)") then
							return value:gmatch("@" .. part .. "%s+([^@%s]+)%s*([^@]*)")
						end
					else
						if value:match("@" .. part .. "%s+([^@]*)") then
							return value:gmatch("@" .. part .. "%s+([^@]*)")
						end
					end
				else
					if value:match("@(%w+)%s+([^@]*)") then
						return value:gmatch("@(%w+)%s+([^@]*)")
					end
				end
			end
		end

		return
	end

	function EnableDocument(enabled)
		_EnableDocument = enabled and true or false
	end

	function IsDocumentEnabled()
		return _EnableDocument or false
	end
end

------------------------------------------------------
-- Interface
------------------------------------------------------
do
	_IFEnv2Info = _IFEnv2Info or setmetatable({}, {__mode = "kv",})

	_KeyWord4IFEnv = _KeyWord4IFEnv or {}

	-- metatable for interface's env
	_MetaIFEnv = _MetaIFEnv or {}
	do
		_MetaIFEnv.__index = function(self, key)
			local info = _IFEnv2Info[self]

			-- Check owner
			if key == info.Name then
				return info.Owner
			end

			-- Check keywords
			if _KeyWord4IFEnv[key] then
				return _KeyWord4IFEnv[key]
			end

			-- Check namespace
			if info.NameSpace then
				if key == _NSInfo[info.NameSpace].Name then
					rawset(self, key, info.NameSpace)
					return rawget(self, key)
				elseif info.NameSpace[key] then
					rawset(self, key, info.NameSpace[key])
					return rawget(self, key)
				end
			end

			-- Check imports
			if info.Import4Env then
				for _, ns in ipairs(info.Import4Env) do
					if key == _NSInfo[ns].Name then
						rawset(self, key, ns)
						return rawget(self, key)
					elseif ns[key] then
						rawset(self, key, ns[key])
						return rawget(self, key)
					end
				end
			end

			-- Check base namespace
			if GetNameSpace(GetDefaultNameSpace(), key) then
				rawset(self, key, GetNameSpace(GetDefaultNameSpace(), key))
				return rawget(self, key)
			end

			-- Check Base
			if info.BaseEnv then
				local value = info.BaseEnv[key]

				if type(value) == "userdata" or type(value) == "table" or type(value) == "function" then
					rawset(self, key, value)
				end

				return value
			end
		end

		_MetaIFEnv.__newindex = function(self, key, value)
			local info = _IFEnv2Info[self]

			if _KeyWord4IFEnv[key] then
				error(("'%s' is a keyword."):format(key), 2)
			end

			if key == info.Name then
				if type(value) == "function" then
					rawset(info, "Constructor", value)
					return
				else
					error(("'%s' must be a function as constructor."):format(key), 2)
				end
			end

			if key == DISPOSE_METHOD then
				if type(value) == "function" then
					rawset(info, DISPOSE_METHOD, value)
					return
				else
					error(("'%s' must be a function as dispose method."):format(DISPOSE_METHOD), 2)
				end
			end

			if type(key) == "string" and type(value) == "function" then
				info.Method[key] = true
				-- keep function in env, just register the method
			end

			rawset(self, key, value)
		end
	end

	do
		_BaseEvents = _BaseEvents or {
			OnEventHandlerChanged = true,
		}

		function CloneWithoutOverride(dest, src)
			for key, value in pairs(src) do
				if dest[key] == nil then
					dest[key] = value
				end
			end
		end

		function CloneWithoutOverride4Method(dest, src, method, isinterface)
			if method then
				for key in pairs(method) do
					if dest[key] == nil and type(key) == "string" and type(src[key]) == "function" then
						dest[key] = src[key]
					end
				end
			else
				for key, value in pairs(src) do
					if type(key) == "string" and type(value) == "function" and (not isinterface or not key:match("^_")) then
						if dest[key] == nil then
							dest[key] = value
						end
					end
				end
			end
		end

		function CloneInterfaceCache(dest, src, cache)
			if not src then return end
			for _, IF in ipairs(src) do
				if not cache[IF] then
					cache[IF] = true
					tinsert(dest, IF)
				end
			end
		end

		function RefreshCache(ns)
			local info = _NSInfo[ns]

			-- Cache4Interface
			local cache = {}
			wipe(info.Cache4Interface)
			-- superclass interface
			if info.SuperClass then
				CloneInterfaceCache(info.Cache4Interface, _NSInfo[info.SuperClass].Cache4Interface, cache)
			end
			-- extend interface
			for _, IF in ipairs(info.ExtendInterface) do
				CloneInterfaceCache(info.Cache4Interface, _NSInfo[IF].Cache4Interface, cache)
			end
			-- self interface
			CloneInterfaceCache(info.Cache4Interface, info.ExtendInterface, cache)
			wipe(cache)

			-- Cache4Event
			wipe(info.Cache4Event)
			--- BaseEvents
			CloneWithoutOverride(info.Cache4Event, _BaseEvents)
			--- self event
			CloneWithoutOverride(info.Cache4Event, info.Event)
			--- superclass event
			if info.SuperClass then
				CloneWithoutOverride(info.Cache4Event, _NSInfo[info.SuperClass].Cache4Event)
			end
			--- extend event
			for _, IF in ipairs(info.ExtendInterface) do
				CloneWithoutOverride(info.Cache4Event, _NSInfo[IF].Cache4Event)
			end

			-- Cache4Property
			wipe(info.Cache4Property)
			--- self property
			CloneWithoutOverride(info.Cache4Property, info.Property)
			--- superclass property
			if info.SuperClass then
				CloneWithoutOverride(info.Cache4Property, _NSInfo[info.SuperClass].Cache4Property)
			end
			--- extend property
			for _, IF in ipairs(info.ExtendInterface) do
				CloneWithoutOverride(info.Cache4Property, _NSInfo[IF].Cache4Property)
			end

			-- Cache4Method
			wipe(info.Cache4Method)
			--- self method
			CloneWithoutOverride4Method(info.Cache4Method, info.ClassEnv or info.InterfaceEnv, info.Method)
			--- superclass method
			if info.SuperClass then
				CloneWithoutOverride4Method(info.Cache4Method, _NSInfo[info.SuperClass].Cache4Method)
			end
			--- extend method
			for _, IF in ipairs(info.ExtendInterface) do
				CloneWithoutOverride4Method(info.Cache4Method, _NSInfo[IF].Cache4Method, nil, true)
			end

			-- Clear branch
			if info.ChildClass then
				for subcls in pairs(info.ChildClass) do
					RefreshCache(subcls)
				end
			elseif info.ExtendClass then
				for subcls in pairs(info.ExtendClass) do
					RefreshCache(subcls)
				end
			end
		end
	end

	function IsExtend(IF, cls)
		if not IF or not cls or not _NSInfo[IF] or _NSInfo[IF].Type ~= TYPE_INTERFACE or not _NSInfo[cls] then
			return false
		end

		if IF == cls then return true end

		if _NSInfo[cls].Cache4Interface then
			for _, pIF in ipairs(_NSInfo[cls].Cache4Interface) do
				if pIF == IF then
					return true
				end
			end
		end

		return false
	end

	function BuildInterface(name, asPart)
		if type(name) ~= "string" or not name:match("^[_%w]+$") then
			if asPart then
				error([[Usage: partinterface "interfacename"]], 2)
			else
				error([[Usage: interface "interfacename"]], 2)
			end
		end
		local fenv = getfenv(3)
		local ns = GetNameSpace4Env(fenv)

		-- Create interface or get it
		local IF

		if ns then
			IF = BuildNameSpace(ns, name)

			if _NSInfo[IF] then
				if _NSInfo[IF].Type and _NSInfo[IF].Type ~= TYPE_INTERFACE then
					error(("%s is existed as %s, not interface."):format(name, tostring(_NSInfo[IF].Type)), 2)
				end

				if _NSInfo[IF].BaseEnv and _NSInfo[IF].BaseEnv ~= fenv then
					error(("%s is defined in another environment, can't be defined here."):format(name), 2)
				end
			end
		else
			IF = fenv[name]

			if not(_NSInfo[IF] and _NSInfo[IF].BaseEnv == fenv and _NSInfo[IF].NameSpace == nil and _NSInfo[IF].Type == TYPE_INTERFACE) then
				IF = BuildNameSpace(nil, name)
			end
		end

		if not IF then
			error("no interface is created.", 2)
		end

		-- save interface to the environment
		rawset(fenv, name, IF)

		-- Build interface
		info = _NSInfo[IF]
		info.Type = TYPE_INTERFACE
		info.NameSpace = ns
		info.BaseEnv = info.BaseEnv or fenv
		info.Event = info.Event or {}
		info.Property = info.Property or {}
		info.Method = info.Method or {}

		info.InterfaceEnv = info.InterfaceEnv or setmetatable({}, _MetaIFEnv)
		_IFEnv2Info[info.InterfaceEnv] = info

		-- Clear
		if not asPart then
			info.Constructor = nil
			wipe(info.Property)
			wipe(info.Event)
			wipe(info.Method)
			for i, v in pairs(info.InterfaceEnv) do
				if type(v) == "function" then
					info.InterfaceEnv[i] = nil
				end
			end
		end

		-- Set namespace
		SetNameSpace4Env(info.InterfaceEnv, IF)

		-- Cache
		info.Cache4Event = info.Cache4Event or {}
		info.Cache4Property = info.Cache4Property or {}
		info.Cache4Method = info.Cache4Method or {}
		info.Cache4Interface = info.Cache4Interface or {}

		-- ExtendInterface
		info.ExtendInterface = info.ExtendInterface or {}

		if not asPart then
			for _, pIF in ipairs(info.ExtendInterface) do
				if _NSInfo[pIF].ExtendClass then
					_NSInfo[pIF].ExtendClass[info.Owner] = nil
				end
			end
			wipe(info.ExtendInterface)
		end

		-- Import
		info.Import4Env = info.Import4Env or {}

		if not asPart then
			wipe(info.Import4Env)
		end

		-- Clear dispose method
		if not asPart then
			info[DISPOSE_METHOD] = nil
		end

		-- Set the environment to interface's environment
		setfenv(3, info.InterfaceEnv)
	end

	------------------------------------
	--- Create interface in currect environment's namespace or default namespace
	-- @name interface
	-- @class function
	-- @param name the interface's name
	-- @usage interface "IFSocket"
	------------------------------------
	function interface(name)
		BuildInterface(name)
	end

	function partinterface(name)
		BuildInterface(name, true)
	end

	------------------------------------
	--- Set the current interface' extended interface
	-- @name extend
	-- @class function
	-- @param name the namespace's name list, using "." to split.
	-- @usage extend "System.IFSocket"
	------------------------------------
	function extend_IF(name)
		if name and type(name) ~= "string" and not IsNameSpace(name) then
			error([[Usage: extend "namespace.interfacename"]], 2)
		end

		if type(name) == "string" and name:find("%.%s*%.") then
			error("the namespace 's name can't have empty string between dots.", 2)
		end

		local env = getfenv(2)

		if rawget(_IFEnv2Info, env) == nil then
			error("can't using extend here.", 2)
		end

		local info = _IFEnv2Info[env]

		local IF

		if type(name) == "string" then
			IF = GetNameSpace(info.NameSpace, name) or env[name]

			if not IF then
				for subname in name:gmatch("[^%.]+") do
					subname = subname:match("[_%w]+")

					if not subname or subname == "" then
						error("the namespace's name must be composed with number, string or '_'.", 2)
					end

					if not IF then
						IF = info.BaseEnv[subname]
					else
						IF = IF[subname]
					end

					if not IsNameSpace(IF) then
						error(("no interface is found with the name : %s"):format(name), 2)
					end
				end
			end
		else
			IF = name
		end

		local IFInfo = _NSInfo[IF]

		if not IFInfo or IFInfo.Type ~= TYPE_INTERFACE then
			error("Usage: extend (interface) : 'interface' - interface expected", 2)
		end

		if IsExtend(info.Owner, IF) then
			error(("%s is extended from %s, can't be used here."):format(tostring(IF), tostring(info.Owner)), 2)
		end

		IFInfo.ExtendClass = IFInfo.ExtendClass or {}
		IFInfo.ExtendClass[info.Owner] = true

		info.ExtendInterface = info.ExtendInterface or {}

		-- Check if IF is already extend by extend tree
		for _, pIF in ipairs(info.ExtendInterface) do
			if IsExtend(IF, pIF) then
				return extend_IF
			end
		end

		-- Clear
		for i = #(info.ExtendInterface), 1, -1 do
			if IsExtend(info.ExtendInterface[i], IF) then
				tremove(info.ExtendInterface, i)
			end
		end

		tinsert(info.ExtendInterface, IF)

		return extend_IF
	end

	------------------------------------
	--- import classes from the given name's namespace to the current environment
	-- @name import
	-- @class function
	-- @param name the namespace's name list, using "." to split.
	-- @usage import "System.Widget"
	------------------------------------
	function import_IF(name)
		if type(name) ~= "string" and not IsNameSpace(name) then
			error([[Usage: import "namespaceA.namespaceB"]], 2)
		end

		if type(name) == "string" and name:find("%.%s*%.") then
			error("the namespace 's name can't have empty string between dots.", 2)
		end

		local env = getfenv(2)

		local info = _IFEnv2Info[env]

		if not info then
			error("can't use import here.", 2)
		end

		local ns

		if type(name) == "string" then
			ns = GetNameSpace(GetDefaultNameSpace(), name)
		elseif IsNameSpace(name) then
			ns = name
		end

		if not ns then
			error(("no namespace is found with name : %s"):format(name), 2)
		end

		info.Import4Env = info.Import4Env or {}

		for _, v in ipairs(info.Import4Env) do
			if v == ns then
				return
			end
		end

		tinsert(info.Import4Env, ns)
	end

	------------------------------------
	--- Add or remove an event for current interface
	-- @name event
	-- @class function
	-- @param name the name of the event
	-- @usage event "OnClick"
	------------------------------------
	function event_IF(name)
		if type(name) ~= "string" or name:find("^_") then
			error([[Usage: event "eventName"]], 2)
		end

		local env = getfenv(2)

		local info = _IFEnv2Info[env]

		if not info then
			error("can't use event here.", 2)
		end

		info.Event[name] = true
	end

	local function SetProperty2IF(info, name, set)
		local tempProperty = {}

		if type(set) ~= "table" then
			error([=[Usage: property "propertyName" {
				Get = function(self)
					-- return the property's value
				end,
				Set = function(self, value)
					-- Set the property's value
				end,
				Type = Type1 [+ Type2 [+ nil]],	-- set the property's type
			}]=], 2)
		end

		for i, v in pairs(set) do
			if type(i) == "string" then
				if i:lower() == "get" then
					tempProperty.Get = v
				elseif i:lower() == "set" then
					tempProperty.Set = v
				elseif i:lower() == "type" then
					tempProperty.Type = v
				end
			end
		end

		local prop = info.Property[name] or {}
		info.Property[name] = prop

		wipe(prop)

		prop.Name = name
		prop.Get = type(tempProperty.Get) == "function" and tempProperty.Get
		prop.Set = type(tempProperty.Set) == "function" and tempProperty.Set

		if tempProperty.Type then
			local ok, _type = pcall(BuildType, tempProperty.Type, name)
			if ok then
				prop.Type = _type
			else
				_type = strtrim(_type:match(":%d+:(.*)$") or _type)

				wipe(tempProperty)

				error(_type, 3)
			end
		end

		wipe(tempProperty)
	end

	------------------------------------
	--- set a propert to the current interface
	-- @name property
	-- @class function
	-- @param name the name of the property
	-- @usage property "Title" {
	--		Get = function(self)
	--			-- return the property's value
	--		end,
	--		Set = function(self, value)
	--			-- Set the property's value
	--		end,
	--		Type = "XXXX",	-- set the property's type
	--}
	------------------------------------
	function property_IF(name)
		if type(name) ~= "string" or strtrim(name:match("[_%w]+")) == "" then
			error([=[Usage: property "propertyName" {
				Get = function(self)
					-- return the property's value
				end,
				Set = function(self, value)
					-- Set the property's value
				end,
				Type = Type1 [+ Type2 [+ nil]],	-- set the property's type
			}]=], 2)
		end

		name = name:match("[_%w]+")

		local env = getfenv(2)

		local info = _IFEnv2Info[env]

		if not info then
			error("can't use property here.", 2)
		end

		return function(set)
			return SetProperty2IF(info, name, set)
		end
	end

	------------------------------------
	--- End the interface's definition and restore the environment
	-- @name class
	-- @class function
	-- @param name the name of the interface
	-- @usage endinterface "IFSocket"
	------------------------------------
	function endinterface(name)
		if type(name) ~= "string" or name:find("%.") then
			error([[Usage: endinterface "interfacename"]], 2)
		end

		local env = getfenv(2)

		local info = _IFEnv2Info[env]

		if info.Name == name then
			setfenv(2, info.BaseEnv)
			RefreshCache(info.Owner)
			return
		else
			error(("%s is not closed."):format(info.Name), 2)
		end
	end

	_KeyWord4IFEnv.interface = interface
	_KeyWord4IFEnv.partinterface = partinterface
	_KeyWord4IFEnv.extend = extend_IF
	_KeyWord4IFEnv.import = import_IF
	_KeyWord4IFEnv.event = event_IF
	_KeyWord4IFEnv.property = property_IF
	_KeyWord4IFEnv.endinterface = endinterface

	_KeyWord4IFEnv.doc = document
end

------------------------------------------------------
-- Class
------------------------------------------------------
do
	_SuperIndex = "Super"

	_ClsEnv2Info = _ClsEnv2Info or setmetatable({}, {__mode = "kv",})

	_KeyWord4ClsEnv = _KeyWord4ClsEnv or {}

	_KeyMeta = {
		__add = true,		-- a + b
		__sub = true,		-- a - b
		__mul = true,		-- a * b
		__div = true,		-- a / b
		__mod = true,		-- a % b
		__pow = true,		-- a ^ b
		__unm = true,		-- - a
		__concat = true,	-- a..b
		__len = true,		-- #a
		__eq = true,		-- a == b
		__lt = true,		-- a < b
		__le = true,		-- a <= b
		__index = false,	-- return a[b]
		__newindex = false,	-- a[b] = v
		__call = true,		-- a()
		__gc = false,		-- dispose a
		__tostring = true,	-- tostring(a)
		__exist = true,		-- ClassName(...)	-- return object if existed
	}

	--------------------------------------------------
	-- Init & Dispose System
	--------------------------------------------------
	do
		function InitObjectWithClass(cls, obj, ...)
			local  info = _NSInfo[cls]

			if info.SuperClass then
				InitObjectWithClass(info.SuperClass, obj, ...)
			end

			if type(info.Constructor) == "function" then
				info.Constructor(obj, ...)
			end
		end

		function InitObjectWithInterface(cls, obj)
			local ok, msg, info

			for _, IF in ipairs(_NSInfo[cls].Cache4Interface) do
				info = _NSInfo[IF]
				if info.Constructor then
					ok, msg = pcall(info.Constructor, obj)

					if not ok then
						errorhandler(msg)
					end
				end
			end
		end

		------------------------------------
		--- Dispose this object
		-- @name DisposeObject
		-- @class function
		------------------------------------
		function DisposeObject(self)
			local objCls = getmetatable(self)
			local IF, info, disfunc

			info = objCls and rawget(_NSInfo, objCls)

			if not info then return end

			for i = #(info.Cache4Interface), 1, -1 do
				IF = info.Cache4Interface[i]
				disfunc = _NSInfo[IF][DISPOSE_METHOD]

				if disfunc then
					pcall(disfunc, self)
				end
			end

			-- Call Class Dispose
			while objCls and _NSInfo[objCls] do
				disfunc = _NSInfo[objCls][DISPOSE_METHOD]

				if disfunc then
					pcall(disfunc, self)
				end

				objCls = _NSInfo[objCls].SuperClass
			end

			-- Clear the table
			-- setmetatable(self, nil)

			wipe(self)

			rawset(self, "Disposed", true)
		end
	end

	-- metatable for class's env
	_MetaClsEnv = _MetaClsEnv or {}
	do
		_MetaClsEnv.__index = function(self, key)
			local info = _ClsEnv2Info[self]

			-- Check owner
			if key == info.Name then
				return info.Owner
			end

			if key == _SuperIndex then
				return info.SuperClass or error("No super class for this class.", 2)
			end

			-- Check keywords
			if _KeyWord4ClsEnv[key] then
				return _KeyWord4ClsEnv[key]
			end

			-- Check namespace
			if info.NameSpace then
				if key == _NSInfo[info.NameSpace].Name then
					rawset(self, key, info.NameSpace)
					return rawget(self, key)
				elseif info.NameSpace[key] then
					rawset(self, key, info.NameSpace[key])
					return rawget(self, key)
				end
			end

			-- Check imports
			if info.Import4Env then
				for _, ns in ipairs(info.Import4Env) do
					if key == _NSInfo[ns].Name then
						rawset(self, key, ns)
						return rawget(self, key)
					elseif ns[key] then
						rawset(self, key, ns[key])
						return rawget(self, key)
					end
				end
			end

			-- Check base namespace
			if GetNameSpace(GetDefaultNameSpace(), key) then
				rawset(self, key, GetNameSpace(GetDefaultNameSpace(), key))
				return rawget(self, key)
			end

			-- Check Base
			if info.BaseEnv then
				local value = info.BaseEnv[key]

				if type(value) == "userdata" or type(value) == "table" or type(value) == "function" then
					rawset(self, key, value)
				end

				return value
			end
		end

		_MetaClsEnv.__newindex = function(self, key, value)
			local info = _ClsEnv2Info[self]

			if _KeyWord4ClsEnv[key] or key == _SuperIndex then
				error(("'%s' is a keyword."):format(key), 2)
			end

			if key == info.Name then
				if type(value) == "function" then
					rawset(info, "Constructor", value)
					return
				else
					error(("'%s' must be a function as constructor."):format(key), 2)
				end
			end

			if key == DISPOSE_METHOD then
				if type(value) == "function" then
					rawset(info, DISPOSE_METHOD, value)
					return
				else
					error(("'%s' must be a function as dispose method."):format(DISPOSE_METHOD), 2)
				end
			end

			if _KeyMeta[key] ~= nil then
				if type(value) == "function" then
					local rMeta = _KeyMeta[key] and key or "_"..key
					SetMetaFunc(rMeta, info.ChildClass, info.MetaTable[rMeta], value)
					info.MetaTable[rMeta] = value
					return
				else
					error(("'%s' must be a function."):format(key), 2)
				end
			end

			if type(key) == "string" and type(value) == "function" then
				info.Method[key] = true
				-- Keep function body in env
			end

			rawset(self, key, value)
		end
	end

	-- metatable for EventHandler
	_MetaEventHandler = _MetaEventHandler or {}
	do
		_MetaEventHandler.__index = {
			Add = function(self, func)
				if type(func) ~= "function" then
					error("Usage: obj.OnXXXX:Add(func)", 2)
				end

				for _, f in ipairs(self) do
					if f == func then
						return self
					end
				end

				tinsert(self, func)

				if self._Owner and self._Name then
					CallEventWithoutCreate(self._Owner, "OnEventHandlerChanged", self._Name)
				end

				return self
			end,
			Remove = function(self, func)
				local flag = false

				if type(func) ~= "function" then
					error("Usage: obj.OnXXXX:Remove(func)", 2)
				end

				for i, f in ipairs(self) do
					if f == func then
						tremove(self, i)
						flag = true
						break
					end
				end

				if flag and self._Owner and self._Name then
					CallEventWithoutCreate(self._Owner, "OnEventHandlerChanged", self._Name)
				end

				return self
			end,
			Clear = function(self)
				local flag = false

				for i = #self, 0, -1 do
					if not flag and self[i] then
						flag = true
					end
					tremove(self, i)
				end

				if flag and self._Owner and self._Name then
					CallEventWithoutCreate(self._Owner, "OnEventHandlerChanged", self._Name)
				end

				return self
			end,
			IsEmpty = function(self)
				return #self == 0 and self[0] == nil
			end,
		}

		_MetaEventHandler.__add = function(self, func)
			if type(func) ~= "function" then
				error("Usage: obj.OnXXXX = obj.OnXXXX + func", 2)
			end

			for _, f in ipairs(self) do
				if f == func then
					return self
				end
			end

			tinsert(self, func)

			if self._Owner and self._Name then
				CallEventWithoutCreate(self._Owner, "OnEventHandlerChanged", self._Name)
			end

			return self
		end

		_MetaEventHandler.__sub = function(self, func)
			local flag = false

			if type(func) ~= "function" then
				error("Usage: obj.OnXXXX = obj.OnXXXX - func", 2)
			end

			for i, f in ipairs(self) do
				if f == func then
					tremove(self, i)
					flag = true
					break
				end
			end

			if flag and self._Owner and self._Name then
				CallEventWithoutCreate(self._Owner, "OnEventHandlerChanged", self._Name)
			end

			return self
		end

		local create = coroutine.create
		local resume = coroutine.resume
		local status = coroutine.status

		_MetaEventHandler.__call = function(self, obj, ...)
			if not obj then
				error("Usage: obj:OnXXXX(...).", 2)
			end

			if self._Blocked then
				return
			end

			local chk = false
			local ret = false

			for i = 1, #self do
				if self._ThreadActivated then
					local thread = create(self[i])
					chk, ret = resume(thread, obj, ...)
					if status(thread) ~= "dead" then
						-- not stop when the thread not dead
						ret = nil
					end
				else
					chk, ret = pcall(self[i], obj, ...)
				end
				if not chk then
					return errorhandler(ret)
				end

				if not rawget(obj, "__Events") then
					-- means it's disposed
					ret = true
				end
				if ret then
					break
				end
			end

			if not ret and self[0] then
				if self._ThreadActivated then
					chk, ret = resume(create(self[0]), obj, ...)
				else
					chk, ret = pcall(self[0], obj, ...)
				end
				if not chk then
					return errorhandler(ret)
				end
			end
		end
	end

	_MetaEvents = _MetaEvents or {}
	do
		_MetaEvents.__index = function(self, key)
			-- Check Event
			local cls = self._Owner and getmetatable(self._Owner)

			if _NSInfo[cls].Cache4Event[key] == nil then
				return
			end

			-- Add Event Handler
			rawset(self, key, setmetatable({_Owner = self._Owner, _Name = key}, _MetaEventHandler))
			return rawget(self, key)
		end

		_MetaEvents.__newindex = function(self, key, value)
		end
	end

	function IsChildClass(cls, child)
		if not cls or not child or not _NSInfo[cls] or _NSInfo[cls].Type ~= TYPE_CLASS or not _NSInfo[child] or _NSInfo[child].Type ~= TYPE_CLASS then
			return false
		end

		if cls == child then
			return true
		end

		local info = _NSInfo[child]

		while info and info.SuperClass and info.SuperClass ~= cls do
			info = _NSInfo[info.SuperClass]
		end

		if info and info.SuperClass == cls then
			return true
		end

		return false
	end

	function SetMetaFunc(meta, sub, pre, now)
		if sub and pre ~= now then
			for cls in pairs(sub) do
				local info = _NSInfo[cls]

				if info.MetaTable[meta] == pre then
					info.MetaTable[meta] = now

					SetMetaFunc(meta, info.ChildClass, pre, now)
				end
			end
		end
	end

	function CheckProperty(prop, value)
		if prop and prop.Type then
			local ok, ret = pcall(prop.Type.Validate, prop.Type, value)

			if not ok then
				ret = strtrim(ret:match(":%d+:(.*)$") or ret)

				if ret:find("%%s") then
					ret = ret:gsub("%%s[_%w]*", prop.Name)
				end

				error(ret, 3)
			end

			return ret
		end

		return value
	end

	function CallEventWithoutCreate(self, eventName, ...)
		if rawget(self, "__Events") and rawget(self.__Events, eventName) then
			return self[eventName](self, ...)
		end
	end

	function Class2Obj(cls, ...)
		local info = _NSInfo[cls]
		local obj

		if not info then return end

		-- Check if this class has __exist so no need to create again.
		if type(info.MetaTable.__exist) == "function" then
			obj = info.MetaTable.__exist(...)

			if type(obj) == "table" then
				if getmetatable(obj) == cls then
					return obj
				else
					error(("There is an existed object as type '%s'."):format(Reflector.GetName(Reflector.GetObjectClass(obj)) or ""), 2)
				end
			end
		end

		-- Create new object
		obj = setmetatable({}, info.MetaTable)
		InitObjectWithClass(cls, obj, ...)

		InitObjectWithInterface(cls, obj)

		return obj
	end

	function BuildClass(name, asPart)
		if type(name) ~= "string" or not name:match("^[_%w]+$") then
			if asPart then
				error([[Usage: partclass "classname"]], 3)
			else
				error([[Usage: class "classname"]], 3)
			end
		end
		local fenv = getfenv(3)
		local ns = GetNameSpace4Env(fenv)

		-- Create class or get it
		local cls

		if ns then
			cls = BuildNameSpace(ns, name)

			if _NSInfo[cls] then
				if _NSInfo[cls].Type and _NSInfo[cls].Type ~= TYPE_CLASS then
					error(("%s is existed as %s, not class."):format(name, tostring(_NSInfo[cls].Type)), 3)
				end

				-- @todo, will class can be changed in other environment?
				if _NSInfo[cls].BaseEnv and _NSInfo[cls].BaseEnv ~= fenv then
					error(("%s is defined in another environment, can't be defined here."):format(name), 3)
				end
			end
		else
			cls = fenv[name]

			if not(_NSInfo[cls] and _NSInfo[cls].BaseEnv == fenv and _NSInfo[cls].NameSpace == nil and _NSInfo[cls].Type == TYPE_CLASS) then
				cls = BuildNameSpace(nil, name)
			end
		end

		if not cls then
			error("no class is created.", 3)
		end

		-- save class to the environment
		rawset(fenv, name, cls)

		-- Build class
		info = _NSInfo[cls]
		info.Type = TYPE_CLASS
		info.NameSpace = ns
		info.BaseEnv = info.BaseEnv or fenv
		info.Event = info.Event or {}
		info.Property = info.Property or {}
		info.Method = info.Method or {}

		info.ClassEnv = info.ClassEnv or setmetatable({}, _MetaClsEnv)
		_ClsEnv2Info[info.ClassEnv] = info

		-- Clear
		if not asPart then
			info.Constructor = nil
			wipe(info.Property)
			wipe(info.Event)
			wipe(info.Method)
			for i, v in pairs(info.ClassEnv) do
				if type(v) == "function" then
					info.ClassEnv[i] = nil
				end
			end
		end

		-- Set namespace
		SetNameSpace4Env(info.ClassEnv, cls)

		-- Cache
		info.Cache4Event = info.Cache4Event or {}
		info.Cache4Property = info.Cache4Property or {}
		info.Cache4Method = info.Cache4Method or {}
		info.Cache4Interface = info.Cache4Interface or {}

		-- SuperClass
		if not asPart then
			local prevInfo = info.SuperClass and _NSInfo[info.SuperClass]

			if prevInfo and prevInfo.ChildClass then
				prevInfo.ChildClass[info.Owner] = nil
			end

			info.SuperClass = nil
		end

		-- ExtendInterface
		info.ExtendInterface = info.ExtendInterface or {}

		if not asPart then
			for _, IF in ipairs(info.ExtendInterface) do
				if _NSInfo[IF].ExtendClass then
					_NSInfo[IF].ExtendClass[info.Owner] = nil
				end
			end
			wipe(info.ExtendInterface)
		end

		-- Import
		info.Import4Env = info.Import4Env or {}

		if not asPart then
			wipe(info.Import4Env)
		end

		-- Clear dispose method
		if not asPart then
			info[DISPOSE_METHOD] = nil
		end

		-- MetaTable
		info.MetaTable = info.MetaTable or {}
		do
			local MetaTable = info.MetaTable
			local rMeta

			-- Clear
			if not asPart then
				for meta, flag in pairs(_KeyMeta) do
					rMeta = flag and meta or "_"..meta
					SetMetaFunc(rMeta, info.ChildClass, MetaTable[rMeta], nil)
					MetaTable[rMeta] = nil
				end
			end

			local ClassEnv = info.ClassEnv
			local Cache4Event = info.Cache4Event
			local Cache4Property = info.Cache4Property
			local Cache4Method = info.Cache4Method
			local ClassName = info.Name

			MetaTable.__class = cls

			MetaTable.__metatable = cls

			MetaTable.__index = MetaTable.__index or function(self, key)
				if type(key) == "string" and not key:find("^__") then
					-- Property Get
					if Cache4Property[key] then
						if Cache4Property[key]["Get"] then
							return Cache4Property[key]["Get"](self)
						else
							error(("%s is write-only."):format(tostring(key)),2)
						end
					end

					-- Dispose Method
					if key == DISPOSE_METHOD then
						return DisposeObject
					end

					-- Method Get
					if not key:find("^_") and Cache4Method[key] then
						return Cache4Method[key]
					end

					-- Events
					if Cache4Event[key] ~= nil then
						if type(rawget(self, "__Events")) ~= "table" or getmetatable(self.__Events) ~= _MetaEvents then
							rawset(self, "__Events", setmetatable({_Owner = self}, _MetaEvents))
						end

						return self.__Events[key]
					end
				end

				-- Custom index metametods
				local ___index = rawget(MetaTable, "___index")
				if ___index then
					if type(___index) == "table" then
						return ___index[key]
					elseif type(___index) == "function" then
						return ___index(self, key)
					end
				end
			end

			MetaTable.__newindex = MetaTable.__newindex or function(self, key, value)
				if type(key) == "string" and not key:find("^__") then
					-- Property Set
					if Cache4Property[key] then
						if Cache4Property[key]["Set"] then
							return Cache4Property[key]["Set"](self, CheckProperty(Cache4Property[key], value))
						else
							error(("%s is read-only."):format(tostring(key)),2)
						end
					end

					-- Events
					if Cache4Event[key] ~= nil then
						if type(rawget(self, "__Events")) ~= "table" or getmetatable(self.__Events) ~= _MetaEvents then
							rawset(self, "__Events", setmetatable({_Owner = self}, _MetaEvents))
						end

						if value == nil or type(value) == "function" then
							if Cache4Event[key] then
								if self.__Events[key][0] ~= value then
									rawset(self.__Events[key], 0, value)
									CallEventWithoutCreate(self, "OnEventHandlerChanged", key)
								end
							else
								error(("%s is not supported for class '%s'."):format(tostring(key), ClassName), 2)
							end
						elseif type(value) == "table" and getmetatable(value) == _MetaEventHandler then
							if value == self.__Events[key] then
								return
							end

							for i = #self.__Events[key], 0, -1 do
								tremove(self.__Events[key], i)
							end

							for i =0, #value do
								self.__Events[key][i] = value[i]
							end

							CallEventWithoutCreate(self, "OnEventHandlerChanged", key)
						else
							error("can't set this value to a scipt handler.", 2)
						end

						return
					end
				end

				-- Custom newindex metametods
				local ___newindex = rawget(MetaTable, "___newindex")
				if type(___newindex) == "function" then
					return ___newindex(self, key, value)
				end

				rawset(self,key,value)			-- Other key can be set as usual
			end
		end

		-- Set the environment to class's environment
		setfenv(3, info.ClassEnv)
	end

	------------------------------------
	--- Create class in currect environment's namespace or default namespace
	-- @name class
	-- @class function
	-- @param name the class's name
	-- @usage class "Form"
	------------------------------------
	function class(name)
		BuildClass(name)
	end

	------------------------------------
	--- Part class definition
	-- @name partclass
	-- @type function
	-- @param name the class's name
	-- @usage partclass "Form"
	------------------------------------
	function partclass(name)
		BuildClass(name, true)
	end

	------------------------------------
	--- Set the current class' super class
	-- @name inherit
	-- @class function
	-- @param name the namespace's name list, using "." to split.
	-- @usage inherit "System.Widget.Frame"
	------------------------------------
	function inherit_Cls(name)
		if name and type(name) ~= "string" and not IsNameSpace(name) then
			error([[Usage: inherit "namespace.classname"]], 2)
		end

		if type(name) == "string" and name:find("%.%s*%.") then
			error("the namespace 's name can't have empty string between dots.", 2)
		end

		local env = getfenv(2)

		if rawget(_ClsEnv2Info, env) == nil then
			error("can't using inherit here.", 2)
		end

		local info = _ClsEnv2Info[env]

		local prevInfo = info.SuperClass and _NSInfo[info.SuperClass]

		if prevInfo and prevInfo.ChildClass then
			prevInfo.ChildClass[info.Owner] = nil
		end

		info.SuperClass = nil

		local superCls

		if type(name) == "string" then
			superCls = GetNameSpace(info.NameSpace, name) or env[name]

			if not superCls then
				for subname in name:gmatch("[^%.]+") do
					subname = subname:match("[_%w]+")

					if not subname or subname == "" then
						error("the namespace's name must be composed with number, string or '_'.", 2)
					end

					if not superCls then
						-- superCls = info.BaseEnv[subname]
						superCls = env[subname]
					else
						superCls = superCls[subname]
					end

					if not IsNameSpace(superCls) then
						error(("no class is found with the name : %s"):format(name), 2)
					end
				end
			end
		else
			superCls = name
		end

		local superInfo = _NSInfo[superCls]

		if not superInfo or superInfo.Type ~= TYPE_CLASS then
			error("Usage: inherit (class) : 'class' - class expected", 2)
		end

		if IsChildClass(info.Owner, superCls) then
			error(("%s is inherited from %s, can't be used as super class."):format(tostring(superCls), tostring(info.Owner)), 2)
		end

		superInfo.ChildClass = superInfo.ChildClass or {}
		superInfo.ChildClass[info.Owner] = true
		info.SuperClass = superCls

		-- Copy Metatable
		local rMeta
		for meta, flag in pairs(_KeyMeta) do
			rMeta = flag and meta or "_"..meta

			if info.MetaTable[rMeta] == nil and superInfo.MetaTable[rMeta] then
				SetMetaFunc(rMeta, info.ChildClass, nil, superInfo.MetaTable[rMeta])
				info.MetaTable[rMeta] = superInfo.MetaTable[rMeta]
			end
		end
	end

	------------------------------------
	--- Set the current class' extended interface
	-- @name extend
	-- @class function
	-- @param name the namespace's name list, using "." to split.
	-- @usage extend "System.IFSocket"
	------------------------------------
	function extend_Cls(name)
		if name and type(name) ~= "string" and not IsNameSpace(name) then
			error([[Usage: extend "namespace.interfacename"]], 2)
		end

		if type(name) == "string" and name:find("%.%s*%.") then
			error("the namespace 's name can't have empty string between dots.", 2)
		end

		local env = getfenv(2)

		if rawget(_ClsEnv2Info, env) == nil then
			error("can't using extend here.", 2)
		end

		local info = _ClsEnv2Info[env]

		local IF

		if type(name) == "string" then
			IF = GetNameSpace(info.NameSpace, name) or env[name]

			if not IF then
				for subname in name:gmatch("[^%.]+") do
					subname = subname:match("[_%w]+")

					if not subname or subname == "" then
						error("the namespace's name must be composed with number, string or '_'.", 2)
					end

					if not IF then
						IF = info.BaseEnv[subname]
					else
						IF = IF[subname]
					end

					if not IsNameSpace(IF) then
						error(("no interface is found with the name : %s"):format(name), 2)
					end
				end
			end
		else
			IF = name
		end

		local IFInfo = _NSInfo[IF]

		if not IFInfo or IFInfo.Type ~= TYPE_INTERFACE then
			error("Usage: extend (interface) : 'interface' - interface expected", 2)
		end

		IFInfo.ExtendClass = IFInfo.ExtendClass or {}
		IFInfo.ExtendClass[info.Owner] = true

		info.ExtendInterface = info.ExtendInterface or {}

		-- Check if IF is already extend by extend tree
		for _, pIF in ipairs(info.ExtendInterface) do
			if IsExtend(IF, pIF) then
				return extend_Cls
			end
		end

		for i = #(info.ExtendInterface), 1, -1 do
			if IsExtend(info.ExtendInterface[i], IF) then
				tremove(info.ExtendInterface, i)
			end
		end

		tinsert(info.ExtendInterface, IF)

		return extend_Cls
	end

	------------------------------------
	--- import classes from the given name's namespace to the current environment
	-- @name import
	-- @class function
	-- @param name the namespace's name list, using "." to split.
	-- @usage import "System.Widget"
	------------------------------------
	function import_Cls(name)
		if type(name) ~= "string" and not IsNameSpace(name) then
			error([[Usage: import "namespaceA.namespaceB"]], 2)
		end

		if type(name) == "string" and name:find("%.%s*%.") then
			error("the namespace 's name can't have empty string between dots.", 2)
		end

		local env = getfenv(2)

		local info = _ClsEnv2Info[env]

		if not info then
			error("can't use import here.", 2)
		end

		local ns

		if type(name) == "string" then
			ns = GetNameSpace(GetDefaultNameSpace(), name)
		elseif IsNameSpace(name) then
			ns = name
		end

		if not ns then
			error(("no namespace is found with name : %s"):format(name), 2)
		end

		info.Import4Env = info.Import4Env or {}

		for _, v in ipairs(info.Import4Env) do
			if v == ns then
				return
			end
		end

		tinsert(info.Import4Env, ns)
	end

	------------------------------------
	--- Add or remove an event for current class
	-- @name event
	-- @class function
	-- @param name the name of the event, if started with "-" means to remove this event
	-- @usage event "OnClick"
	-- @usage event "-OnClick"
	------------------------------------
	function event_Cls(name)
		if type(name) ~= "string" or name:find("^_") then
			error([[Usage: event "[-]eventName"]], 2)
		end

		local env = getfenv(2)

		local info = _ClsEnv2Info[env]

		if not info then
			error("can't use event here.", 2)
		end

		local flag

		name, flag = name:gsub("^-", "")

		info.Event[name] = (flag == 0)
	end

	local function SetProperty2Cls(info, name, set)
		local tempProperty = {}

		if type(set) ~= "table" then
			error([=[Usage: property "propertyName" {
				Get = function(self)
					-- return the property's value
				end,
				Set = function(self, value)
					-- Set the property's value
				end,
				Type = Type1 [+ Type2 [+ nil]],	-- set the property's type
			}]=], 2)
		end

		for i, v in pairs(set) do
			if type(i) == "string" then
				if i:lower() == "get" then
					tempProperty.Get = v
				elseif i:lower() == "set" then
					tempProperty.Set = v
				elseif i:lower() == "type" then
					tempProperty.Type = v
				end
			end
		end

		local prop = info.Property[name] or {}
		info.Property[name] = prop

		wipe(prop)

		prop.Name = name
		prop.Get = type(tempProperty.Get) == "function" and tempProperty.Get
		prop.Set = type(tempProperty.Set) == "function" and tempProperty.Set

		if tempProperty.Type then
			local ok, _type = pcall(BuildType, tempProperty.Type, name)
			if ok then
				prop.Type = _type
			else
				_type = strtrim(_type:match(":%d+:(.*)$") or _type)

				wipe(tempProperty)

				error(_type, 3)
			end
		end

		wipe(tempProperty)
	end

	------------------------------------
	--- set a propert to the current class
	-- @name property
	-- @class function
	-- @param name the name of the property
	-- @usage property "Title" {
	--		Get = function(self)
	--			-- return the property's value
	--		end,
	--		Set = function(self, value)
	--			-- Set the property's value
	--		end,
	--		Type = "XXXX",	-- set the property's type
	--}
	------------------------------------
	function property_Cls(name)
		if type(name) ~= "string" or strtrim(name:match("[_%w]+")) == "" then
			error([=[Usage: property "propertyName" {
				Get = function(self)
					-- return the property's value
				end,
				Set = function(self, value)
					-- Set the property's value
				end,
				Type = Type1 [+ Type2 [+ nil]],	-- set the property's type
			}]=], 2)
		end

		name = name:match("[_%w]+")

		local env = getfenv(2)

		local info = _ClsEnv2Info[env]

		if not info then
			error("can't use property here.", 2)
		end

		return function(set)
			return SetProperty2Cls(info, name, set)
		end
	end

	------------------------------------
	--- End the class's definition and restore the environment
	-- @name class
	-- @class function
	-- @param name the name of the class
	-- @usage endclass "Form"
	------------------------------------
	function endclass(name)
		if type(name) ~= "string" or name:find("%.") then
			error([[Usage: endclass "classname"]], 2)
		end

		local env = getfenv(2)

		local info = _ClsEnv2Info[env]

		if info.Name == name then
			setfenv(2, info.BaseEnv)
			RefreshCache(info.Owner)
			return
		else
			error(("%s is not closed."):format(info.Name), 2)
		end
	end

	_KeyWord4ClsEnv.partclass = partclass
	_KeyWord4ClsEnv.class = class
	_KeyWord4ClsEnv.inherit = inherit_Cls
	_KeyWord4ClsEnv.extend = extend_Cls
	_KeyWord4ClsEnv.import = import_Cls
	_KeyWord4ClsEnv.event = event_Cls
	_KeyWord4ClsEnv.property = property_Cls
	_KeyWord4ClsEnv.endclass = endclass

	_KeyWord4ClsEnv.doc = document
end

------------------------------------------------------
-- Enum
------------------------------------------------------
do
	function BuildEnum(info, set)
		if type(set) ~= "table" then
			error([[Usage: enum "enumName" {
				"enumValue1",
				"enumValue2",
			}]], 2)
		end

		info.Enum = info.Enum or {}

		wipe(info.Enum)

		for i, v in pairs(set) do
			if type(i) == "string" then
				info.Enum[i:upper()] = v
			elseif type(v) == "string" then
				info.Enum[v:upper()] = v
			end
		end
	end

	function GetShortEnumInfo(cls)
		if _NSInfo[cls] then
			local str

			for n in pairs(_NSInfo[cls].Enum) do
				if str and #str > 30 then
					str = str .. " | ..."
					break
				end

				str = str and (str .. " | " .. n) or n
			end

			return str or ""
		end

		return ""
	end

	------------------------------------
	--- create a enumeration
	-- @name enum
	-- @class function
	-- @param name the name of the enum
	-- @usage enum "ButtonState" {
	--		"PUSHED",
	--		"NORMAL",
	--}
	------------------------------------
	function enum(name)
		if type(name) ~= "string" or not name:match("^[_%w]+$") then
			error([[Usage: enum "enumName" {
				"enumValue1",
				"enumValue2",
			}]], 2)
		end

		local fenv = getfenv(2)
		local ns = GetNameSpace4Env(fenv)

		-- Create class or get it
		local enm

		if ns then
			enm = BuildNameSpace(ns, name)

			if _NSInfo[cls] then
				if _NSInfo[cls].Type and _NSInfo[cls].Type ~= TYPE_ENUM then
					error(("%s is existed as %s, not enumeration."):format(name, tostring(_NSInfo[cls].Type)), 2)
				end
			end
		else
			enm = fenv[name]

			if not(_NSInfo[enm] and _NSInfo[enm].Type == TYPE_ENUM) then
				enm = BuildNameSpace(nil, name)
			end
		end

		if not enm then
			error("no enumeration is created.", 2)
		end

		-- save class to the environment
		rawset(fenv, name, enm)

		-- Build enm
		local info = _NSInfo[enm]
		info.Type = TYPE_ENUM
		info.NameSpace = ns

		return function(set)
			return BuildEnum(info, set)
		end
	end
end

------------------------------------------------------
-- Struct
------------------------------------------------------
do
	_StructEnv2Info = _StructEnv2Info or setmetatable({}, {__mode = "kv",})

	_KeyWord4StrtEnv = _KeyWord4StrtEnv or {}

	_STRUCT_TYPE_MEMBER = "MEMBER"
	_STRUCT_TYPE_ARRAY = "ARRAY"
	_STRUCT_TYPE_CUSTOM = "CUSTOM"

	-- metatable for class's env
	_MetaStrtEnv = _MetaStrtEnv or {}
	do
		_MetaStrtEnv.__index = function(self, key)
			local info = _StructEnv2Info[self]

			-- Check owner
			if key == info.Name then
				return info.Owner
			end

			if key == "Validate" then
				return info.UserValidate
			end

			-- Check keywords
			if _KeyWord4StrtEnv[key] then
				return _KeyWord4StrtEnv[key]
			end

			-- Check namespace
			if info.NameSpace then
				if key == _NSInfo[info.NameSpace].Name then
					rawset(self, key, info.NameSpace)
					return rawget(self, key)
				elseif info.NameSpace[key] then
					rawset(self, key, info.NameSpace[key])
					return rawget(self, key)
				end
			end

			-- Check imports
			if info.Import4Env then
				for _, ns in ipairs(info.Import4Env) do
					if key == _NSInfo[ns].Name then
						rawset(self, key, ns)
						return rawget(self, key)
					elseif ns[key] then
						rawset(self, key, ns[key])
						return rawget(self, key)
					end
				end
			end

			-- Check base namespace
			if GetNameSpace(GetDefaultNameSpace(), key) then
				rawset(self, key, GetNameSpace(GetDefaultNameSpace(), key))
				return rawget(self, key)
			end

			-- Check Base
			if info.BaseEnv then
				local value = info.BaseEnv[key]

				if type(value) == "userdata" or type(value) == "table" or type(value) == "function" then
					rawset(self, key, value)
				end

				return value
			end
		end

		_MetaStrtEnv.__newindex = function(self, key, value)
			local info = _StructEnv2Info[self]

			if _KeyWord4StrtEnv[key] then
				error(("the '%s' is a keyword."):format(key), 2)
			end

			if key == info.Name then
				-- error(("the '%s' is the struct name, can't be used."):format(key), 2)
				if type(value) == "function" then
					rawset(info, "Constructor", value)
					return
				else
					error(("the '%s' must be a function as constructor."):format(key), 2)
				end
			end

			if key == "Validate" then
				if value == nil or type(value) == "function" then
					info.UserValidate = value
					return
				else
					error(("the '%s' must be a function used for validation."):format(key), 2)
				end
			end

			if type(key) == "string" and (value == nil or IsType(value) or IsNameSpace(value)) then
				local ok, ret = pcall(BuildType, value, key)

				if ok then
					rawset(self, key, ret)

					if info.SubType == _STRUCT_TYPE_MEMBER then
						info.Members = info.Members or {}
						tinsert(info.Members, key)
					elseif info.SubType == _STRUCT_TYPE_ARRAY then
						info.ArrayElement = ret
					end

					return
				else
					ret = strtrim(ret:match(":%d+:(.*)$") or ret)
					error(ret, 2)
				end
			end

			rawset(self, key, value)
		end
	end

	function ValidateStruct(strt, value)
		local info = _NSInfo[strt]

		if info.SubType == _STRUCT_TYPE_MEMBER and info.Members and #info.Members > 0 then
			assert(type(value) == "table", ("%s must be a table, got %s."):format("%s", type(value)))

			for _, n in ipairs(info.Members) do
				value[n] = info.StructEnv[n]:Validate(value[n])
			end
		end

		if info.SubType == _STRUCT_TYPE_ARRAY and info.ArrayElement then
			assert(type(value) == "table", ("%s must be a table, got %s."):format("%s", type(value)))

			local flag, ret

			for i, v in ipairs(value) do
				flag, ret = pcall(info.ArrayElement.Validate, info.ArrayElement, v)

				if flag then
					value[i] = ret
				else
					ret = strtrim(ret:match(":%d+:(.*)$") or ret)

					if ret:find("%%s([_%w]+)") then
						ret = ret:gsub("%%s([_%w]+)", "%%s["..i.."]")
					end

					assert(false, ret)
				end
			end
		end

		if type(info.UserValidate) == "function" then
			value = info.UserValidate(value)
		end

		return value
	end

	function Struct2Obj(strt, ...)
		local info = _NSInfo[strt]

		if type(info.Constructor) == "function" then
			local ok, ret = pcall(info.Constructor, ...)
			if ok then
				return ret
			else
				ret = strtrim(ret:match(":%d+:(.*)$") or ret)

				error(ret, 3)
			end
		end

		if info.SubType == _STRUCT_TYPE_MEMBER and info.Members and #info.Members > 0 then
			local ret = {}

			for i, n in ipairs(info.Members) do
				ret[n] = select(i, ...)
			end

			local ok, value = pcall(ValidateStruct, strt, ret)

			if ok then
				return value
			else
				value = strtrim(value:match(":%d+:(.*)$") or value)
				value = value:gsub("%%s%.", ""):gsub("%%s", "")

				local args = ""
				for i, n in ipairs(info.Members) do
					if info.StructEnv[n]:Is(nil) and not args:find("%[") then
						n = "["..n
					end
					if i == 1 then
						args = n
					else
						args = args..", "..n
					end
				end
				if args:find("%[") then
					args = args.."]"
				end
				error(("Usage : %s(%s) - %s"):format(tostring(strt), args, value), 3)
			end
		end

		if info.SubType == _STRUCT_TYPE_ARRAY and info.ArrayElement then
			local ret = {}

			for i = 1, select('#', ...) do
				ret[i] = select(i, ...)
			end

			local ok, value = pcall(ValidateStruct, strt, ret)

			if ok then
				return value
			else
				value = strtrim(value:match(":%d+:(.*)$") or value)
				value = value:gsub("%%s%.", ""):gsub("%%s", "")

				error(("Usage : %s(...) - %s"):format(tostring(strt), value), 3)
			end
		end

		error(("struct '%s' is abstract."):format(tostring(strt)), 3)
	end

	function BuildStructVFalidate(strt)
		local info = _NSInfo[strt]

		info.Validate = function ( value )
			local ok, ret = pcall(ValidateStruct, strt, value)

			if not ok then
				ret = strtrim(ret:match(":%d+:(.*)$") or ret)

				ret = ret:gsub("%%s", "[".. info.Name .."]")

				error(ret, 2)
			end

			return ret
		end
	end

	------------------------------------
	--- create a structure
	-- @name struct
	-- @class function
	-- @param name the name of the enum
	-- @usage struct "Point"
	--    x = System.Number
	--    y = System.Number
	-- endstruct "Point"
	------------------------------------
	function struct(name)
		if type(name) ~= "string" or not name:match("^[_%w]+$") then
			error([[Usage: struct "structname"]], 2)
		end
		local fenv = getfenv(2)
		local ns = GetNameSpace4Env(fenv)

		-- Create class or get it
		local strt

		if ns then
			strt = BuildNameSpace(ns, name)

			if _NSInfo[strt] then
				if _NSInfo[strt].Type and _NSInfo[strt].Type ~= TYPE_STRUCT then
					error(("%s is existed as %s, not struct."):format(name, tostring(_NSInfo[strt].Type)), 2)
				end

				if _NSInfo[strt].BaseEnv and _NSInfo[strt].BaseEnv ~= fenv then
					error(("%s is defined in another environment, can't be defined here."):format(name), 2)
				end
			end
		else
			strt = fenv[name]

			if not(_NSInfo[strt] and _NSInfo[strt].BaseEnv == fenv and _NSInfo[strt].NameSpace == nil and _NSInfo[strt].Type == TYPE_STRUCT) then
				strt = BuildNameSpace(nil, name)
			end
		end

		if not strt then
			error("no struct is created.", 2)
		end

		-- save class to the environment
		rawset(fenv, name, strt)

		-- Build class
		info = _NSInfo[strt]
		info.Type = TYPE_STRUCT
		info.NameSpace = ns
		info.BaseEnv = info.BaseEnv or fenv
		info.Members = nil
		info.ArrayElement = nil
		info.UserValidate = nil
		info.Validate = nil
		info.SubType = _STRUCT_TYPE_MEMBER

		info.StructEnv = info.StructEnv or setmetatable({}, _MetaStrtEnv)
		_StructEnv2Info[info.StructEnv] = info

		-- Clear
		info.Constructor = nil

		wipe(info.StructEnv)

		-- Set namespace
		SetNameSpace4Env(info.StructEnv, strt)

		-- Set the environment to class's environment
		setfenv(2, info.StructEnv)
	end

	------------------------------------
	--- import classes from the given name's namespace to the current environment
	-- @name import
	-- @class function
	-- @param name the namespace's name list, using "." to split.
	-- @usage import "System.Widget"
	------------------------------------
	function import_STRT(name)
		if type(name) ~= "string" and not IsNameSpace(name) then
			error([[Usage: import "namespaceA.namespaceB"]], 2)
		end

		if type(name) == "string" and name:find("%.%s*%.") then
			error("the namespace 's name can't have empty string between dots.", 2)
		end

		local env = getfenv(2)

		local info = _StructEnv2Info[env]

		if not info then
			error("can't use import here.", 2)
		end

		local ns

		if type(name) == "string" then
			ns = GetNameSpace(GetDefaultNameSpace(), name)
		elseif IsNameSpace(name) then
			ns = name
		end

		if not ns then
			error(("no namespace is found with name : %s"):format(name), 2)
		end

		info.Import4Env = info.Import4Env or {}

		for _, v in ipairs(info.Import4Env) do
			if v == ns then
				return
			end
		end

		tinsert(info.Import4Env, ns)
	end

	function structtype(name)
		if type(name) ~= "string" then
			error([[Usage: structtype "Member"|"Array"|"Custom"]], 2)
		end

		local env = getfenv(2)

		local info = _StructEnv2Info[env]

		if not info then
			error("can't use structtype here.", 2)
		end

		name = name:upper()

		if name == "MEMBER" then
			-- use member list, default type
			info.SubType = _STRUCT_TYPE_MEMBER
			info.ArrayElement = nil
		elseif name == "ARRAY" then
			-- user array list
			info.SubType = _STRUCT_TYPE_ARRAY
			info.Members = nil
		else
			-- else all custom
			info.SubType = _STRUCT_TYPE_CUSTOM
			info.Members = nil
			info.ArrayElement = nil
		end
	end

	------------------------------------
	--- End the class's definition and restore the environment
	-- @name class
	-- @class function
	-- @param name the name of the class
	-- @usage endclass "Form"
	------------------------------------
	function endstruct(name)
		if type(name) ~= "string" or name:find("%.") then
			error([[Usage: endstruct "structname"]], 2)
		end

		local env = getfenv(2)

		while rawget(_StructEnv2Info, env) do
			local info = _StructEnv2Info[env]

			if info.Name == name then
				setfenv(2, info.BaseEnv)
				return
			end

			env = info.BaseEnv
		end

		error(("no struct is found with name: %s"):format(name), 2)
	end

	_KeyWord4StrtEnv.struct = struct
	_KeyWord4StrtEnv.import = import_STRT
	_KeyWord4StrtEnv.structtype = structtype
	_KeyWord4StrtEnv.endstruct = endstruct
end

------------------------------------------------------
-- System Namespace
------------------------------------------------------
do
	namespace "System"

	------------------------------------------------------
	-- Base structs
	------------------------------------------------------
	struct "Boolean"
		function Validate(value)
			return value and true or false
		end
	endstruct "Boolean"

	struct "String"
		function Validate(value)
			if type(value) ~= "string" then
				error(("%s must be a string, got %s."):format("%s", type(value)))
			end
			return value
		end
	endstruct "String"

	struct "Number"
		function Validate(value)
			if type(value) ~= "number" then
				error(("%s must be a number, got %s."):format("%s", type(value)))
			end
			return value
		end
	endstruct "Number"

	struct "Function"
		function Validate(value)
			if type(value) ~= "function" then
				error(("%s must be a function, got %s."):format("%s", type(value)))
			end
			return value
		end
	endstruct "Function"

	struct "Table"
		function Validate(value)
			if type(value) ~= "table" then
				error(("%s must be a table, got %s."):format("%s", type(value)))
			end
			return value
		end
	endstruct "Table"

	struct "Userdata"
		function Validate(value)
			if type(value) ~= "userdata" then
				error(("%s must be a userdata, got %s."):format("%s", type(value)))
			end
			return value
		end
	endstruct "Userdata"

	struct "Thread"
		function Validate(value)
			if type(value) ~= "thread" then
				error(("%s must be a thread, got %s."):format("%s", type(value)))
			end
			return value
		end
	endstruct "Thread"

	struct "Any"
		function Validate(value)
			return value
		end
	endstruct "Any"

	------------------------------------------------------
	-- System.Reflector
	------------------------------------------------------
	interface "Reflector"

		doc [======[
			@name Reflector
			@type interface
			@desc This interface contains much methodes to get the running object-oriented system's informations.
		]======]

		_NSInfo = _NSInfo

		TYPE_CLASS = TYPE_CLASS
		TYPE_STRUCT = TYPE_STRUCT
		TYPE_ENUM = TYPE_ENUM
		TYPE_INTERFACE = TYPE_INTERFACE

		_STRUCT_TYPE_MEMBER = _STRUCT_TYPE_MEMBER
		_STRUCT_TYPE_ARRAY = _STRUCT_TYPE_ARRAY
		_STRUCT_TYPE_CUSTOM = _STRUCT_TYPE_CUSTOM

		local sort = table.sort

		doc [======[
			@name FireObjectEvent
			@type method
			@desc Fire an object's event, to trigger the object's event handlers
			@param object the object
			@param event the event name
			@param ... the event's arguments
			@return nil
		]======]
		function FireObjectEvent(self, sc, ...)
			if not GetObjectClass(self) then
				error("Usage : Reflector.FireObjectEvent(object, event[, ...]) : 'object' - object expected.")
			end

			if type(sc) ~= "string" then
				error(("Usage : Reflector.FireObjectEvent(object, event [, args, ...]) : 'event' - string expected, got %s."):format(type(sc)), 2)
			end

			if rawget(self, "__Events") and rawget(self.__Events, sc) then
				return rawget(self.__Events, sc)(self, ...)
			end
		end

		doc [======[
			@name GetCurrentNameSpace
			@type method
			@desc Get the namespace used by the environment
			@param env table
			@param rawOnly boolean, rawget data from the env if true
			@return namespace
		]======]
		function GetCurrentNameSpace(env, rawOnly)
			env = type(env) == "table" and env or getfenv(2)

			return GetNameSpace4Env(env, rawOnly)
		end

		doc [======[
			@name SetCurrentNameSpace
			@type method
			@desc set the namespace used by the environment
			@param ns the namespace that set for the environment
			@param env table
			@return nil
		]======]
		function SetCurrentNameSpace(ns, env)
			env = type(env) == "table" and env or getfenv(2)

			return SetNameSpace4Env(env, ns)
		end

		doc [======[
			@name ForName
			@type method
			@desc Get the namespace for the name
			@param name the namespace's name, split by "."
			@return namespace the namespace
			@usage System.Reflector.ForName("System")
		]======]
		function ForName(name)
			return GetNameSpace(GetDefaultNameSpace(), name)
		end

		doc [======[
			@name GetType
			@type method
			@desc Get the class|enum|struct|interface for the namespace
			@param name the namespace
			@return type
			@usage System.Reflector.GetType("System.Object")
		]======]
		function GetType(ns)
			if type(ns) == "string" then ns = ForName(ns) end

			return ns and rawget(_NSInfo, ns) and _NSInfo[ns].Type
		end

		doc [======[
			@name GetName
			@type method
			@desc Get the name for the namespace
			@param namespace the namespace to query
			@return name
			@usage System.Reflector.GetName(System.Object)
		]======]
		function GetName(ns)
			if type(ns) == "string" then ns = ForName(ns) end

			return ns and rawget(_NSInfo, ns) and _NSInfo[ns].Name
		end

		doc [======[
			@name GetFullName
			@type method
			@desc Get the full name for the namespace
			@param namespace the namespace to query
			@return fullname
			@usage System.Reflector.GetFullName(System.Object)
		]======]
		function GetFullName(ns)
			if type(ns) == "string" then ns = ForName(ns) end

			return GetFullName4NS(ns)
		end

		doc [======[
			@name GetSuperClass
			@type method
			@desc Get the superclass for the class
			@param class the class object to query
			@return superclass
			@usage System.Reflector.GetSuperClass(System.Object)
		]======]
		function GetSuperClass(ns)
			if type(ns) == "string" then ns = ForName(ns) end

			return ns and rawget(_NSInfo, ns) and _NSInfo[ns].SuperClass
		end

		doc [======[
			@name IsNameSpace
			@type method
			@desc Check if the object is a NameSpace
			@param object the object to query
			@return boolean true if the object is a NameSpace
			@usage System.Reflector.IsNameSpace(System.Object)
		]======]
		function IsNameSpace(ns)
			if type(ns) == "string" then ns = ForName(ns) end

			return ns and rawget(_NSInfo, ns) and true or false
		end

		doc [======[
			@name IsClass
			@type method
			@desc Check if the namespace is a class
			@param object
			@return boolean true if the object is a class
			@usage System.Reflector.IsClass(System.Object)
		]======]
		function IsClass(ns)
			if type(ns) == "string" then ns = ForName(ns) end

			return ns and rawget(_NSInfo, ns) and _NSInfo[ns].Type == TYPE_CLASS or false
		end

		doc [======[
			@name IsStruct
			@type method
			@desc Check if the namespace is a struct
			@param object
			@return boolean true if the object is a struct
			@usage System.Reflector.IsStruct(System.Object)
		]======]
		function IsStruct(ns)
			if type(ns) == "string" then ns = ForName(ns) end

			return ns and rawget(_NSInfo, ns) and _NSInfo[ns].Type == TYPE_STRUCT or false
		end

		doc [======[
			@name IsEnum
			@type method
			@desc Check if the namespace is an enum
			@param object
			@return boolean true if the object is a enum
			@usage System.Reflector.IsEnum(System.Object)
		]======]
		function IsEnum(ns)
			if type(ns) == "string" then ns = ForName(ns) end

			return ns and rawget(_NSInfo, ns) and _NSInfo[ns].Type == TYPE_ENUM or false
		end

		doc [======[
			@name IsInterface
			@type method
			@desc Check if the namespace is an interface
			@param object
			@return boolean true if the object is an Interface
			@usage System.Reflector.IsInterface(System.IFSocket)
		]======]
		function IsInterface(ns)
			if type(ns) == "string" then ns = ForName(ns) end

			return ns and rawget(_NSInfo, ns) and _NSInfo[ns].Type == TYPE_INTERFACE or false
		end

		doc [======[
			@name GetSubNamespace
			@type method
			@desc Get the sub namespace of the namespace
			@param namespace
			@return table the sub-namespace list
			@usage System.Reflector.GetSubNamespace(System)
		]======]
		function GetSubNamespace(ns)
			if type(ns) == "string" then ns = ForName(ns) end

			local info = ns and _NSInfo[ns]

			if info and info.SubNS then
				local ret = {}

				for key in pairs(info.SubNS) do
					tinsert(ret, key)
				end

				sort(ret)

				return ret
			end
		end

		doc [======[
			@name GetExtendInterfaces
			@type method
			@desc Get the extend interfaces of the class
			@param class
			@return table the extend interface list
			@usage System.Reflector.GetExtendInterfaces(System.Object)
		]======]
		function GetExtendInterfaces(cls)
			if type(cls) == "string" then cls = ForName(cls) end

			local info = cls and _NSInfo[cls]

			if info.ExtendInterface then
				local ret = {}

				for _, IF in ipairs(info.ExtendInterface) do
					tinsert(ret, IF)
				end

				return ret
			end
		end

		doc [======[
			@name GetAllExtendInterfaces
			@type method
			@desc Get all the extend interfaces of the class
			@param class
			@return table the full extend interface list in the inheritance tree
			@usage System.Reflector.GetAllExtendInterfaces(System.Object)
		]======]
		function GetAllExtendInterfaces(cls)
			if type(cls) == "string" then cls = ForName(cls) end

			local info = cls and _NSInfo[cls]

			if info.Cache4Interface then
				local ret = {}

				for _, IF in ipairs(info.Cache4Interface) do
					tinsert(ret, IF)
				end

				return ret
			end
		end

		doc [======[
			@name GetChildClasses
			@type method
			@desc Get the child classes of the class
			@param class
			@return table the child class list
			@usage System.Reflector.GetChildClasses(System.Object)
		]======]
		function GetChildClasses(cls)
			if type(cls) == "string" then cls = ForName(cls) end

			local info = cls and _NSInfo[cls]

			if info.Type == TYPE_CLASS and info.ChildClass then
				local ret = {}

				for subCls in pairs(info.ChildClass) do
					tinsert(ret, subCls)
				end

				return ret
			end
		end

		doc [======[
			@name GetEvents
			@type method
			@desc Get the events of the class
			@format class|interface[, noSuper]
			@param class|interface the class or interface to query
			@param noSuper no super event handlers
			@return table the event handler list
			@usage System.Reflector.GetEvents(System.Object)
		]======]
		function GetEvents(ns, noSuper)
			if type(ns) == "string" then ns = ForName(ns) end

			local info = ns and _NSInfo[ns]

			if info and (info.Type == TYPE_CLASS or info.Type == TYPE_INTERFACE) then
				local ret = {}

				for i, v in pairs(noSuper and info.Event or info.Cache4Event) do
					if v then
						tinsert(ret, i)
					end
				end

				sort(ret)

				return ret
			end
		end

		doc [======[
			@name GetProperties
			@type method
			@desc Get the properties of the class
			@format class|interface[, noSuper]
			@param class|interface the class or interface to query
			@param noSuper no super properties
			@return table the property list
			@usage System.Reflector.GetProperties(System.Object)
		]======]
		function GetProperties(ns, noSuper)
			if type(ns) == "string" then ns = ForName(ns) end

			local info = ns and _NSInfo[ns]

			if info and (info.Type == TYPE_CLASS or info.Type == TYPE_INTERFACE) then
				local ret = {}

				for i, v in pairs(noSuper and info.Property or info.Cache4Property) do
					if v then
						tinsert(ret, i)
					end
				end

				sort(ret)

				return ret
			end
		end

		doc [======[
			@name GetMethods
			@type method
			@desc Get the methods of the class
			@format class|interface[, noSuper]
			@param class|interface the class or interface to query
			@param noSuper no super methodes
			@return table the method list
			@usage System.Reflector.GetMethods(System.Object)
		]======]
		function GetMethods(ns, noSuper)
			if type(ns) == "string" then ns = ForName(ns) end

			local info = ns and _NSInfo[ns]

			if info and (info.Type == TYPE_CLASS or info.Type == TYPE_INTERFACE) then
				local ret = {}

				for i, v in pairs(noSuper and info.Method or info.Cache4Method) do
					if v then
						tinsert(ret, i)
					end
				end

				sort(ret)

				return ret
			end
		end

		doc [======[
			@name GetPropertyType
			@type method
			@desc Get the property type of the class
			@param class|interface
			@param propName the property name
			@return type the property type
			@usage System.Reflector.GetPropertyType(System.Object, "Name")
		]======]
		function GetPropertyType(ns, propName)
			if type(ns) == "string" then ns = ForName(ns) end

			local info = ns and _NSInfo[ns]

			if info and (info.Type == TYPE_CLASS or info.Type == TYPE_INTERFACE) and info.Cache4Property[propName] then
				local ty = info.Cache4Property[propName].Type

				return ty and ty:Copy()
			end
		end

		doc [======[
			@name HasProperty
			@type method
			@desc whether the property is existed
			@param class|interface
			@param propName
			@return boolean true if the class|interface has the property
			@usage System.Reflector.HasProperty(System.Object, "Name")
		]======]
		function HasProperty(ns, propName)
			if type(ns) == "string" then ns = ForName(ns) end

			local info = ns and _NSInfo[ns]

			if info and (info.Type == TYPE_CLASS or info.Type == TYPE_INTERFACE) and info.Cache4Property[propName] then
				return true
			end

			return false
		end

		doc [======[
			@name IsPropertyReadable
			@type method
			@desc whether the property is readable
			@param class|interface
			@param propName
			@return boolean true if the property is readable
			@usage System.Reflector.IsPropertyReadable(System.Object, "Name")
		]======]
		function IsPropertyReadable(ns, propName)
			if type(ns) == "string" then ns = ForName(ns) end

			local info = ns and _NSInfo[ns]

			if info and (info.Type == TYPE_CLASS or info.Type == TYPE_INTERFACE) and info.Cache4Property[propName] then
				return type(info.Cache4Property[propName].Get) == "function"
			end
		end

		doc [======[
			@name IsPropertyWritable
			@type method
			@desc whether the property is writable
			@param class|interface
			@param propName
			@return boolean true if the property is writable
			@usage System.Reflector.IsPropertyWritable(System.Object, "Name")
		]======]
		function IsPropertyWritable(ns, propName)
			if type(ns) == "string" then ns = ForName(ns) end

			local info = ns and _NSInfo[ns]

			if info and (info.Type == TYPE_CLASS or info.Type == TYPE_INTERFACE) and info.Cache4Property[propName] then
				return type(info.Cache4Property[propName].Set) == "function"
			end
		end

		doc [======[
			@name GetEnums
			@type method
			@desc Get the enums of the enum
			@param enum
			@return table the enum index list
			@usage System.Reflector.GetEnums(System.SampleEnum)
		]======]
		function GetEnums(ns)
			if type(ns) == "string" then ns = ForName(ns) end

			local info = ns and _NSInfo[ns]

			if info and info.Type == TYPE_ENUM then
				local tmp = {}

				for i in pairs(info.Enum) do
					tinsert(tmp, i)
				end

				sort(tmp)

				return tmp
			end
		end

		doc [======[
			@name ParseEnum
			@type method
			@desc Get the enum index of the enum value
			@param enum
			@param value
			@return index
			@usage System.Reflector.ParseEnum(System.SampleEnum, 1)
		]======]
		function ParseEnum(ns, value)
			if type(ns) == "string" then ns = ForName(ns) end

			if ns and _NSInfo[ns] and _NSInfo[ns].Type == TYPE_ENUM and _NSInfo[ns].Enum then
				for n, v in pairs(_NSInfo[ns].Enum) do
					if v == value then
						return n
					end
				end
			end
		end

		doc [======[
			@name HasEvent
			@type method
			@desc Check if the class|interface has that event
			@param class|interface
			@param event the event handler name
			@return true if the class|interface has the event
			@usage System.Reflector.HasEvent(Addon, "OnEvent")
		]======]
		function HasEvent(cls, sc)
			if type(cls) == "string" then cls = ForName(cls) end

			local info = _NSInfo[cls]

			if info and (info.Type == TYPE_CLASS or info.Type == TYPE_INTERFACE) then
				return info.Cache4Event[sc] or false
			end
		end

		doc [======[
			@name GetStructType
			@type method
			@desc Get the type of the struct
			@param struct
			@return string
		]======]
		function GetStructType(ns)
			if type(ns) == "string" then ns = ForName(ns) end

			local info = ns and rawget(_NSInfo, ns)

			if info and info.Type == TYPE_STRUCT then
				return info.SubType
			end
		end

		doc [======[
			@name GetStructArrayElement
			@type method
			@desc Get the array element type of the struct
			@param ns
			@return type the array element's type
		]======]
		function GetStructArrayElement(ns)
			if type(ns) == "string" then ns = ForName(ns) end

			local info = ns and rawget(_NSInfo, ns)

			if info and info.Type == TYPE_STRUCT and info.SubType == _STRUCT_TYPE_ARRAY then
				return info.ArrayElement
			end
		end

		doc [======[
			@name GetStructParts
			@type method
			@desc Get the parts of the struct
			@param struct
			@return table struct part name list
			@usage System.Reflector.GetStructParts(Position)
		]======]
		function GetStructParts(ns)
			if type(ns) == "string" then ns = ForName(ns) end

			local info = ns and rawget(_NSInfo, ns)

			if info and info.Type == TYPE_STRUCT and info.Members and #info.Members > 0 then
				local tmp = {}

				for _, part in ipairs(info.Members) do
					tinsert(tmp, part)
				end

				return tmp
			end
		end

		doc [======[
			@name GetStructPart
			@type method
			@desc Get the part's type of the struct
			@param struct
			@param part the part's name
			@return type the part's type
			@usage System.Reflector.GetStructPart(Position, "x")
		]======]
		function GetStructPart(ns, part)
			if type(ns) == "string" then ns = ForName(ns) end

			local info = ns and rawget(_NSInfo, ns)

			if info and info.Type == TYPE_STRUCT and info.Members and #info.Members > 0  then
				for _, p in ipairs(info.Members) do
					if p == part and IsType(info.StructEnv[p]) then
						return info.StructEnv[p]:Copy()
					end
				end
			end
		end

		doc [======[
			@name IsSuperClass
			@type method
			@desc Check if this first arg is a child class of the next arg
			@param childclass
			@param superclass
			@return boolean true if the supeclass is the childclass's super class
			@usage System.Reflector.IsSuperClass(UIObject, Object)
		]======]
		function IsSuperClass(child, super)
			if type(child) == "string" then child = ForName(child) end
			if type(super) == "string" then super = ForName(super) end

			return IsClass(child) and IsClass(super) and IsChildClass(super, child)
		end

		doc [======[
			@name IsExtendedInterface
			@type method
			@desc Check if the class is extended from the interface
			@param class|interface
			@param interface
			@return boolean true if the first arg is extend from the second
			@usage System.Reflector.IsExtendedInterface(UIObject, IFSocket)
		]======]
		function IsExtendedInterface(cls, IF)
			if type(cls) == "string" then cls = ForName(cls) end
			if type(IF) == "string" then IF = ForName(IF) end

			return IsExtend(IF, cls)
		end

		doc [======[
			@name GetObjectClass
			@type method
			@desc Get the class type of this object
			@param object
			@return class the object's class
			@usage System.Reflector.GetObjectClass(obj)
		]======]
		function GetObjectClass(obj)
			return type(obj) == "table" and getmetatable(obj)
		end

		doc [======[
			@name ObjectIsClass
			@type method
			@desc Check if this object is an instance of the class
			@param object
			@param class
			@return true if the object is an instance of the class or it's child class
			@usage System.Reflector.ObjectIsClass(obj, Object)
		]======]
		function ObjectIsClass(obj, cls)
			if type(cls) == "string" then cls = ForName(cls) end
			return (obj and cls and IsChildClass(cls, GetObjectClass(obj))) or false
		end

		doc [======[
			@name ObjectIsInterface
			@type method
			@desc Check if this object is an instance of the interface
			@param object
			@param interface
			@return true if the object's class is extended from the interface
			@usage System.Reflector.ObjectIsInterface(obj, IFSocket)
		]======]
		function ObjectIsInterface(obj, IF)
			if type(IF) == "string" then IF = ForName(IF) end
			return (obj and IF and IsExtend(IF, GetObjectClass(obj))) or false
		end

		doc [======[
			@name ActiveThread
			@type method
			@desc Active thread mode for special events.
			@param object
			@param ... event handler name list
			@return nil
			@usage System.Reflector.ActiveThread(obj, "OnClick", "OnEnter")
		]======]
		function ActiveThread(obj, ...)
			local cls = GetObjectClass(obj)
			local name

			if cls then
				for i = 1, select('#', ...) do
					name = select(i, ...)

					if HasEvent(cls, name) then
						obj[name]._ThreadActivated = true
					end
				end
			end
		end

		doc [======[
			@name IsThreadActivated
			@type method
			@desc Whether the thread mode is activated for special events.
			@param obect
			@param event
			@return boolean true if the object has active thread mode for the given event.
			@usage System.Reflector.IsThreadActivated(obj, "OnClick")
		]======]
		function IsThreadActivated(obj, sc)
			local cls = GetObjectClass(obj)
			local name

			if cls and HasEvent(cls, sc) then
				return obj[sc]._ThreadActivated or false
			end

			return false
		end

		doc [======[
			@name InactiveThread
			@type method
			@desc Inactive thread mode for special events.
			@param object
			@param ... event name list
			@return nil
			@usage System.Reflector.InactiveThread(obj, "OnClick", "OnEnter")
		]======]
		function InactiveThread(obj, ...)
			local cls = GetObjectClass(obj)
			local name

			if cls then
				for i = 1, select('#', ...) do
					name = select(i, ...)

					if HasEvent(cls, name) then
						obj[name]._ThreadActivated = nil
					end
				end
			end
		end

		doc [======[
			@name BlockEvent
			@type method
			@desc Block event for object
			@param object
			@param ... the event handler name list
			@return nil
			@usage System.Reflector.BlockEvent(obj, "OnClick", "OnEnter")
		]======]
		function BlockEvent(obj, ...)
			local cls = GetObjectClass(obj)
			local name

			if cls then
				for i = 1, select('#', ...) do
					name = select(i, ...)

					if HasEvent(cls, name) then
						obj[name]._Blocked = true
					end
				end
			end
		end

		doc [======[
			@name IsEventBlocked
			@type method
			@desc Whether the event is blocked for object
			@param object
			@param event
			@return boolean true if the event is blocked
			@usage System.Reflector.IsEventBlocked(obj, "OnClick")
		]======]
		function IsEventBlocked(obj, sc)
			local cls = GetObjectClass(obj)
			local name

			if cls and HasEvent(cls, sc) then
				return obj[sc]._Blocked or false
			end

			return false
		end

		doc [======[
			@name UnBlockEvent
			@type method
			@desc Un-Block event for object
			@param object
			@param ... event handler name list
			@return nil
			@usage System.Reflector.UnBlockEvent(obj, "OnClick", "OnEnter")
		]======]
		function UnBlockEvent(obj, ...)
			local cls = GetObjectClass(obj)
			local name

			if cls then
				for i = 1, select('#', ...) do
					name = select(i, ...)

					if HasEvent(cls, name) then
						obj[name]._Blocked = nil
					end
				end
			end
		end

		-- Recycle the test type object
		_Validate_Type = setmetatable({}, {
			__call = function(self, key)
				if key then
					if type(key) == "table" and self[key] then
						key.AllowNil = nil
						key[1] = nil
						key.Name = nil

						tinsert(self, key)
					end
				else
					if #self > 0 then
						return tremove(self, #self)
					else
						local ret = BuildType(nil)

						-- Mark it as recycle table
						self[ret] = true

						return ret
					end
				end
			end,
		})

		doc [======[
			@name Validate
			@type method
			@desc Validating the value to the given type.
			@format type, value, name[, prefix[, stacklevel]]
			@param type such like Object+String+nil
			@param value the test value
			@param name the parameter's name
			@param prefix the prefix string
			@param stacklevel set if not in the main function call, only work when prefix is setted
			@return nil
			@usage System.Reflector.Validate(System.String+nil, "Test")
		]======]
		function Validate(types, value, name, prefix, stacklevel)
			stacklevel = type(stacklevel) == "number" and stacklevel > 0 and stacklevel or 0

			stacklevel = math.floor(stacklevel)

			if type(name) ~= "string" then name = "value" end

			if types == nil then
				return value
			end

			if IsNameSpace(types) then
				local vtype = _Validate_Type()

				vtype.AllowNil = nil
				vtype[1] = types
				vtype.Name = name

				types = vtype
			end

			local ok, _type = pcall(BuildType, types, name)

			if ok then
				if _type then
					ok, value = pcall(_type.Validate, _type, value)

					-- Recycle
					_Validate_Type(types)

					if not ok then
						value = strtrim(value:match(":%d+:(.*)$") or value)

						if value:find("%%s") then
							value = value:gsub("%%s[_%w]*", name)
						end

						if type(prefix) == "string" then
							error(prefix .. value, 3 + stacklevel)
						else
							error(value, 2)
						end
					end
				else
					-- Recycle
					_Validate_Type(types)
				end

				return value
			else
				-- Recycle
				_Validate_Type(types)

				error("Usage : System.Reflector.Validate(type, value[, name[, prefix]]) : type - must be nil, enum, struct or class.", 2)
			end

			return value
		end

		doc [======[
			@name EnableDocumentSystem
			@type method
			@desc Enable or disbale the document system, only effect later created document
			@param enabled true to enable the document system
			@return nil
			@usage System.Reflector.EnableDocumentSystem(true)
		]======]
		function EnableDocumentSystem(enabled)
			EnableDocument(enabled)
		end

		doc [======[
			@name IsDocumentSystemEnabled
			@type method
			@desc Whether the document system is enabled
			@return boolean
		]======]
		function IsDocumentSystemEnabled()
			return IsDocumentEnabled()
		end

		doc [======[
			@name GetDocument
			@type method
			@desc Get the document settings
			@format namespace, docType, name[, part]
			@param namespace
			@param doctype such as "property"
			@param name the query name
			@param part the part name
			@return Iterator the iterator to get detail
			@usage
				for part, value in System.Reflector.GetDocument(System.Object, "method", "GetClass")
			<br>	do print(part, value)
			<br>end
		]======]
		function GetDocument(ns, doctype, name, part)
			return GetDocumentPart(ns, doctype, name, part)
		end

		doc [======[
			@name HasDocument
			@type method
			@desc Check if has the document
			@param namespace
			@param doctype
			@param name
			@return true if the document is present
		]======]
		function HasDocument(ns, doctype, name)
			return HasDocumentPart(ns, doctype, name)
		end

		doc [======[
			@name Help
			@type method
			@desc Get the document detail
			@format class|interface[, event|property|method, name]
			@format class|interface, name
			@format enum|struct
			@param class|interface|enum|struct
			@param event|property|method
			@param name the name to query
			@return string the detail information
		]======]
		function Help(ns, doctype, name)
			if type(ns) == "string" then ns = ForName(ns) end

			if ns and rawget(_NSInfo, ns) then
				local info = _NSInfo[ns]

				if info.Type == TYPE_ENUM then
					-- Enum
					local result = "[Enum] " .. GetFullName(ns) .. " :"
					local value
					for _, enums in ipairs(GetEnums(ns)) do
						value = ns[enums]

						if type(value) == "string" then
							value = ("%q"):format(value)
						else
							value = tostring(value)
						end

						result = result .. "\n    " .. enums .. " = " .. value
					end
					return result
				elseif info.Type == TYPE_STRUCT then
					-- Struct
					local result = "[Struct] " .. GetFullName(ns) .. " :"

					-- SubNameSpace
					if info.SubNS and next(info.SubNS) then
						result = result .. "\n  Sub NameSpace :"
						for _, sns in ipairs(GetSubNamespace(ns)) do
							result = result .. "\n    " .. sns
						end
					end

					if info.SubType == _STRUCT_TYPE_MEMBER then
						-- Part
						local parttype, typestring
						local parts = GetStructParts(ns)

						if parts and next(parts) then
							result = result .. "\n  Member:"

							for _, name in ipairs(parts) do
								parttype = GetStructPart(ns, name)

								typestring = ""

								for _, tns in ipairs(parttype) do
									typestring = typestring .. " + " .. GetFullName(tns)
								end

								-- NameSpace
								local index = -1
								while parttype[index] do
									typestring = typestring .. " - " .. GetFullName(parttype[index])

									index = index - 1
								end

								-- Allow nil
								if parttype.AllowNil then
									typestring = typestring .. " + nil"
								end

								if typestring:sub(1, 2) == " +" then
									typestring = typestring:sub(3, -1)
								end

								result = result .. "\n    " .. name .. " =" .. typestring
							end
						else
							result = result .. "\n  Basic Element"
						end
					elseif info.SubType == _STRUCT_TYPE_ARRAY then
						local parttype = info.ArrayElement
						local typestring = ""

						if parttype then
							for _, tns in ipairs(parttype) do
								typestring = typestring .. " + " .. GetFullName(tns)
							end

							-- NameSpace
							local index = -1
							while parttype[index] do
								typestring = typestring .. " - " .. GetFullName(parttype[index])

								index = index - 1
							end

							-- Allow nil
							if parttype.AllowNil then
								typestring = typestring .. " + nil"
							end

							if typestring:sub(1, 2) == " +" then
								typestring = typestring:sub(3, -1)
							end

							result = result .. "\n  Element :\n    Type =" .. typestring
						end
					end
					return result
				elseif info.Type == TYPE_INTERFACE or info.Type == TYPE_CLASS then
					-- Interface & Class
					if type(doctype) ~= "string" then
						local result
						local desc

						if info.Type == TYPE_INTERFACE then
							result = "[Interface] " .. GetFullName(ns) .. " :"

							if HasDocumentPart(ns, "interface", GetName(ns)) then
								desc = GetDocumentPart(ns, "interface", GetName(ns), "desc")
							elseif HasDocumentPart(ns, "default", GetName(ns)) then
								desc = GetDocumentPart(ns, "default", GetName(ns), "desc")
							end
						else
							result = "[Class] " .. GetFullName(ns) .. " :"

							if HasDocumentPart(ns, "class", GetName(ns)) then
								desc = GetDocumentPart(ns, "class", GetName(ns), "desc")
							elseif HasDocumentPart(ns, "default", GetName(ns)) then
								desc = GetDocumentPart(ns, "default", GetName(ns), "desc")
							end
						end

						-- Desc
						desc = desc and desc()
						if desc then
							result = result .. "\n  Description :\n    " .. desc:gsub("<br>", "\n    ")
						end

						-- Inherit
						if info.SuperClass then
							result = result .. "\n  Super Class :\n    " .. GetFullName(info.SuperClass)
						end

						-- Extend
						if info.ExtendInterface and next(info.ExtendInterface) then
							result = result .. "\n  Extend Interface :"
							for _, IF in ipairs(info.ExtendInterface) do
								result = result .. "\n    " .. GetFullName(IF)
							end
						end

						-- SubNameSpace
						if info.SubNS and next(info.SubNS) then
							result = result .. "\n  Sub NameSpace :"
							for _, sns in ipairs(GetSubNamespace(ns)) do
								result = result .. "\n    " .. sns
							end
						end

						-- Event
						if next(info.Event) then
							result = result .. "\n  Event :"
							for sc in pairs(info.Event) do
								result = result .. "\n    " .. sc
							end
						end

						-- Property
						if next(info.Property) then
							result = result .. "\n  Property :"
							for prop in pairs(info.Property) do
								result = result .. "\n    " .. prop
							end
						end

						-- Method
						if next(info.Method) then
							result = result .. "\n  Method :"
							for method in pairs(info.Method) do
								result = result .. "\n    " .. method
							end
						end

						-- Need
						if info.Type == TYPE_INTERFACE then
							desc = GetDocumentPart(ns, "interface", GetName(ns), "need")

							if desc then
								result = result .. "\n  Need :"

								for need, info in desc do
									if info and info:len() > 0 then
										result = result .. "\n    " .. need .. " - " .. info
									else
										result = result .. "\n    " .. need
									end
								end
							end
						end

						-- Constructor
						local isFormat = false

						if info.Type == TYPE_CLASS then
							while ns do
								isFormat = true

								if HasDocumentPart(ns, "class", GetName(ns)) then
									desc = GetDocumentPart(ns, "class", GetName(ns), "format")
									if not desc then
										desc = GetDocumentPart(ns, "class", GetName(ns), "param")
										isFormat = false
									end
								elseif HasDocumentPart(ns, "default", GetName(ns)) then
									desc = GetDocumentPart(ns, "default", GetName(ns), "desc")
									if not desc then
										desc = GetDocumentPart(ns, "default", GetName(ns), "param")
										isFormat = false
									end
								end

								if desc then
									-- Constructor
									result = result .. "\n  Constructor :"
									if isFormat then
										for fmt in desc do
											result = result .. "\n    " .. GetName(ns) .. "(" .. fmt .. ")"
										end
									else
										result = result .. "\n    " .. GetName(ns) .. "("

										local isFirst = true

										for param in desc do
											if isFirst then
												isFirst = false
												result = result .. param
											else
												result = result .. ", " .. param
											end
										end

										result = result .. ")"
									end

									-- Params
									desc = GetDocumentPart(ns, "class", GetName(ns), "param") or GetDocumentPart(ns, "default", GetName(ns), "param")
									if desc then
										result = result .. "\n  Parameter :"
										for param, info in desc do
											if info and info:len() > 0 then
												result = result .. "\n    " .. param .. " - " .. info
											else
												result = result .. "\n    " .. param
											end
										end
									end

									break
								end

								ns = GetSuperClass(ns)
							end
						end

						return result
					else
						local result
						local querytype

						if info.Type == TYPE_INTERFACE then
							result = "[Interface] " .. GetFullName(ns) .. " - "
						else
							result = "[Class] " .. GetFullName(ns) .. " - "
						end

						if type(name) ~= "string" then
							doctype, name = nil, doctype
						end

						querytype = doctype

						if not querytype then
							if HasEvent(ns, name) then
								querytype = "event"
							elseif HasProperty(ns, name) then
								querytype = "property"
							elseif type(ns[name]) == "function" then
								querytype = "method"
							else
								return
							end
						end

						doctype = querytype or "default"

						if doctype:match("^%a") then
							result = result .. "[" .. doctype:match("^%a"):upper() .. doctype:sub(2, -1) .. "] " .. name .. " :"
						else
							result = result .. "[" .. doctype .. "] " .. name .. " :"
						end

						local hasDocument = HasDocumentPart(ns, doctype, name)

						-- Desc
						local desc = hasDocument and GetDocumentPart(ns, doctype, name, "desc")
						desc = desc and desc()
						if desc then
							result = result .. "\n  Description :\n    " .. desc:gsub("<br>", "\n    ")
						end

						if querytype == "event" then
							-- Format
							desc = hasDocument and GetDocumentPart(ns, doctype, name, "format")
							if desc then
								result = result .. "\n  Format :"
								for fmt in desc do
									result = result .. "\n    " .. "function object:" .. name .. "(" .. fmt .. ")\n        -- Handle the event\n    end"
								end
							else
								result = result .. "\n  Format :\n    function object:" .. name .. "("

								desc = hasDocument and GetDocumentPart(ns, doctype, name, "param")

								if desc then
									local isFirst = true

									for param in desc do
										if isFirst then
											isFirst = false
											result = result .. param
										else
											result = result .. ", " .. param
										end
									end
								end

								result = result .. ")\n        -- Handle the event\n    end"
							end

							-- Params
							desc = hasDocument and GetDocumentPart(ns, doctype, name, "param")
							if desc then
								result = result .. "\n  Parameter :"
								for param, info in desc do
									if info and info:len() > 0 then
										result = result .. "\n    " .. param .. " - " .. info
									else
										result = result .. "\n    " .. param
									end
								end
							end
						elseif querytype == "property" then
							local types = GetPropertyType(ns, name)

							if types then
								local parttype = types
								local typestring = ""

								for _, tns in ipairs(parttype) do
									typestring = typestring .. " + " .. GetFullName(tns)
								end

								-- NameSpace
								local index = -1
								while parttype[index] do
									typestring = typestring .. " - " .. GetFullName(parttype[index])

									index = index - 1
								end

								-- Allow nil
								if parttype.AllowNil then
									typestring = typestring .. " + nil"
								end

								if typestring:sub(1, 2) == " +" then
									typestring = typestring:sub(3, -1)
								end

								result = result .. "\n  Type :\n    " .. typestring
							end

							-- Readonly
							result = result .. "\n  Readable :\n    " .. tostring(IsPropertyReadable(ns, name))

							-- Writable
							result = result .. "\n  Writable :\n    " .. tostring(IsPropertyWritable(ns, name))
						elseif querytype == "method" then
							local isGlobal = false

							if info.Type == TYPE_INTERFACE then
								if name:match("^_") then
									isGlobal = true
								else
									desc = hasDocument and GetDocumentPart(ns, doctype, name, "method")
									if desc and desc() == "interface" then
										isGlobal = true
									end
								end
							end

							-- Format
							desc = hasDocument and GetDocumentPart(ns, doctype, name, "format")
							result = result .. "\n  Format :"
							if desc then
								for fmt in desc do
									if isGlobal then
										result = result .. "\n    " .. GetName(ns) .. "." .. name .. "(" .. fmt .. ")"
									else
										result = result .. "\n    object:" .. name .. "(" .. fmt .. ")"
									end
								end
							else
								if isGlobal then
									result = result .. "\n    " .. GetName(ns) .. "." .. name .. "("
								else
									result = result .. "\n    object:" .. name .. "("
								end

								desc = hasDocument and GetDocumentPart(ns, doctype, name, "param")

								if desc then
									local isFirst = true

									for param in desc do
										if isFirst then
											isFirst = false
											result = result .. param
										else
											result = result .. ", " .. param
										end
									end
								end

								result = result .. ")"
							end

							-- Params
							desc = hasDocument and GetDocumentPart(ns, doctype, name, "param")
							if desc then
								result = result .. "\n  Parameter :"
								for param, info in desc do
									if info and info:len() > 0 then
										result = result .. "\n    " .. param .. " - " .. info
									else
										result = result .. "\n    " .. param
									end
								end
							end

							-- ReturnFormat
							desc = hasDocument and GetDocumentPart(ns, doctype, name, "returnformat")
							if desc then
								result = result .. "\n  Return Format :"
								for fmt in desc do
									result = result .. "\n    " .. fmt
								end
							end

							-- Returns
							desc = hasDocument and GetDocumentPart(ns, doctype, name, "return")
							if desc then
								result = result .. "\n  Return :"
								for ret, info in desc do
									if info and info:len() > 0 then
										result = result .. "\n    " .. ret .. " - " .. info
									else
										result = result .. "\n    " .. ret
									end
								end
							end
						else
							-- skip
						end

						-- Usage
						desc = hasDocument and GetDocumentPart(ns, doctype, name, "usage")
						if desc then
							result = result .. "\n  Usage :"
							for usage in desc do
								result = result .. "\n    " .. usage:gsub("<br>", "\n    ")
							end
						end

						return result
					end
				else
					local result = "[NameSpace] " .. GetFullName(ns) .. " :"
					local desc

					if HasDocumentPart(ns, "namespace", GetName(ns)) then
						desc = GetDocumentPart(ns, "namespace", GetName(ns), "desc")
					elseif HasDocumentPart(ns, "default", GetName(ns)) then
						desc = GetDocumentPart(ns, "default", GetName(ns), "desc")
					end

					-- Desc
					desc = desc and desc()
					if desc then
						result = result .. "\n  Description :\n    " .. desc
					end

					-- SubNameSpace
					if info.SubNS and next(info.SubNS) then
						result = result .. "\n  Sub NameSpace :"
						for _, sns in ipairs(GetSubNamespace(ns)) do
							result = result .. "\n    " .. sns
						end
					end

					return result
				end
			end
		end
	endinterface "Reflector"

	------------------------------------------------------
	-- System.Object
	------------------------------------------------------
	class "Object"

		doc [======[
			@name Object
			@type class
			@desc The root class of other classes. Object class contains several methodes for common use.
		]======]

		local create = coroutine.create
		local resume = coroutine.resume
		local status = coroutine.status
		local running = coroutine.running

		------------------------------------------------------
		-- Method
		------------------------------------------------------
		doc [======[
			@name HasEvent
			@type method
			@desc Check if the event type is supported by the object
			@param name the event's name
			@return boolean true if the object has that event type
		]======]
		function HasEvent(self, name)
			if type(name) ~= "string" then
				error(("Usage : object:HasEvent(name) : 'name' - string expected, got %s."):format(type(name)), 2)
			end
			return Reflector.HasEvent(Reflector.GetObjectClass(self), name) or false
		end

		doc [======[
			@name GetClass
			@type method
			@desc Get the class type of the object
			@return class the object's class
		]======]
		function GetClass(self)
			return Reflector.GetObjectClass(self)
		end

		doc [======[
			@name IsClass
			@type method
			@desc Check if the object is an instance of the class
			@param class
			@return boolean true if the object is an instance of the class
		]======]
		function IsClass(self, cls)
			return Reflector.ObjectIsClass(self, cls)
		end

		doc [======[
			@name IsInterface
			@type method
			@desc Check if the object is extend from the interface
			@param interface
			@return boolean true if the object is extend from the interface
		]======]
		function IsInterface(self, IF)
			return Reflector.ObjectIsInterface(self, IF)
		end

		doc [======[
			@name Fire
			@type method
			@desc Fire an object's event, to trigger the object's event handlers
			@param event the event name
			@param ... the event's arguments
			@return nil
		]======]
		function Fire(self, sc, ...)
			if type(sc) ~= "string" then
				error(("Usage : Object:Fire(event [, args, ...]) : 'event' - string expected, got %s."):format(type(sc)), 2)
			end

			if rawget(self, "__Events") and rawget(self.__Events, sc) then
				return rawget(self.__Events, sc)(self, ...)
			end
		end

		doc [======[
			@name ActiveThread
			@type method
			@desc Active the thread mode for special events
			@format event[, ...]
			@param event the event name
			@param ... other event's name list
			@return nil
		]======]
		function ActiveThread(self, ...)
			return Reflector.ActiveThread(self, ...)
		end

		doc [======[
			@name IsThreadActivated
			@type method
			@desc Check if the thread mode is actived for the event
			@param event the event's name
			@return boolean true if the event is in thread mode
		]======]
		function IsThreadActivated(self, sc)
			return Reflector.IsThreadActivated(self, sc)
		end

		doc [======[
			@name InactiveThread
			@type method
			@desc Turn off the thread mode for the events
			@format event[, ...]
			@param event the event's name
			@param ... other event's name list
			@return nil
		]======]
		function InactiveThread(self, ...)
			return Reflector.InactiveThread(self, ...)
		end

		doc [======[
			@name BlockEvent
			@type method
			@desc Block some events for the object
			@format event[, ...]
			@param event the event's name
			@param ... other event's name list
			@return nil
		]======]
		function BlockEvent(self, ...)
			return Reflector.BlockEvent(self, ...)
		end

		doc [======[
			@name IsEventBlocked
			@type method
			@desc Check if the event is blocked for the object
			@param event the event's name
			@return boolean true if th event is blocked
		]======]
		function IsEventBlocked(self, sc)
			return Reflector.IsEventBlocked(self, sc)
		end

		doc [======[
			@name UnBlockEvent
			@type method
			@desc Un-Block some events for the object
			@format event[, ...]
			@param event the event's name
			@param ... other event's name list
			@return nil
		]======]
		function UnBlockEvent(self, ...)
			return Reflector.UnBlockEvent(self, ...)
		end

		doc [======[
			@name ThreadCall
			@type method
			@desc Call method or function as a thread
			@param methodname|function
			@param ... the arguments
			@return nil
		]======]
		function ThreadCall(self, method, ...)
			if type(method) == "string" then
				method = self[method]
			end

			if type(method) == "function" then
				if not running() then
					return resume(create(method), self, ...)
				else
					return method(self, ...)
				end
			end
		end
	endclass "Object"

	------------------------------------------------------
	-- System.Module
	------------------------------------------------------
	class "Module"
		inherit "Object"

		doc [======[
			@name Module
			@type class
			@desc Used to create an hierarchical environment with class system settings, like : Module "Root.ModuleA" "v72"
		]======]

		_Module = _Module or {}
		_ModuleInfo = _ModuleInfo or setmetatable({}, {__mode = "k"})

		_ModuleEnv = _ModuleEnv or {}

		_ModuleEnv.partclass = partclass
		_ModuleEnv.class = class
		_ModuleEnv.enum = enum
		_ModuleEnv.namespace = namespace
		_ModuleEnv.struct = struct
		_ModuleEnv.partinterface = partinterface
		_ModuleEnv.interface = interface
		_ModuleEnv.import = function(name)
			local ns = name

			if type(name) == "string" then
				ns = Reflector.ForName(name)

				if not ns then
					error(("no namespace is found with name : %s"):format(name), 2)
				end
			end

			if not Reflector.IsNameSpace(ns) then
				error([[Usage: import "namespaceA.namespaceB"]], 2)
			end

			local env = getfenv(2)

			local info = _ModuleInfo[env]

			if not info then
				error("can't use import here.", 2)
			end

			info.Import = info.Import or {}

			for _, v in ipairs(info.Import) do
				if v == ns then
					return
				end
			end

			tinsert(info.Import, ns)
		end

		------------------------------------------------------
		-- Event
		------------------------------------------------------
		doc [======[
			@name OnDispose
			@type event
			@desc Fired when the module is disposed
		]======]
		event "OnDispose"

		------------------------------------------------------
		-- Method
		------------------------------------------------------
		doc [======[
			@name ValidateVersion
			@type method
			@desc Return true if the version is greater than the current version of the module
			@param version
			@return boolean true if the version is a validated version
		]======]
		function ValidateVersion(self, version)
			local info = _ModuleInfo[self]

			if not info then
				error("The module is disposed", 2)
			end

			-- Check version
			if type(version) == "number" then
				version = tostring(version)
			elseif type(version) == "string" then
				version = strtrim(version)

				if version == "" then version = nil end
			end

			if type(version) == "string" then
				local number = version:match("^.-(%d+[%d%.]*).-$")

				if number then
					number = number:match("^(.-)[%.]*$")

					if info.Version then
						local onumber = info.Version:match("^.-(%d+[%d%.]*).-$")

						if onumber then
							onumber = onumber:match("^(.-)[%.]*$")

							local f1 = onumber:gmatch("%d+")
							local f2 = number:gmatch("%d+")

							local v1 = f1 and f1()
							local v2 = f2 and f2()

							local pass = false

							while true do
								v1 = tonumber(v1)
								v2 = tonumber(v2)

								if not v1 then
									if v2 then pass = true end
									break
								elseif not v2 then
									break
								elseif v1 < v2 then
									pass = true
									break
								elseif v1 > v2 then
									break
								end

								v1 = f1 and f1()
								v2 = f2 and f2()
							end

							-- Clear
							while f1 and f1() do end
							while f2 and f2() do end

							-- Check falg
							if pass then
								return true
							end
						else
							return true
						end
					else
						return true
					end
				end
			end

			return false
		end

		doc [======[
			@name GetModule
			@type method
			@desc Get the child-module with the name
			@param name string, the child-module's name
			@return System.Module the child-module
		]======]
		function GetModule(self, name)
			if type(name) ~= "string" or strtrim(name) == "" then
				return
			end

			local mdl = self

			for sub in name:gmatch("[_%w]+") do
				mdl =  _ModuleInfo[mdl] and _ModuleInfo[mdl].Modules and _ModuleInfo[mdl].Modules[sub]

				if not mdl then return end
			end

			if mdl == self then return end

			return mdl
		end

		doc [======[
			@name GetModules
			@type method
			@desc Get all child-modules of the module
			@return table the list of the the child-modules
		]======]
		function GetModules(self)
			if _ModuleInfo[self] and _ModuleInfo[self].Modules then
				local lst = {}

				for _, mdl in pairs(_ModuleInfo[self].Modules) do
					tinsert(lst, mdl)
				end

				return lst
			end
		end

		------------------------------------------------------
		-- Property
		------------------------------------------------------
		doc [======[
			@name _M
			@type property
			@desc The module itself
		]======]
		property "_M" {
			Get = function(self)
				return self
			end,
		}

		doc [======[
			@name _Name
			@type property
			@desc The module's name
		]======]
		property "_Name" {
			Get = function(self)
				return _ModuleInfo[self].Name
			end,
		}

		doc [======[
			@name _Parent
			@type property
			@desc The module's parent module
		]======]
		property "_Parent" {
			Get = function(self)
				return _ModuleInfo[self].Parent
			end,
		}

		doc [======[
			@name _Version
			@type property
			@desc The module's version
		]======]
		property "_Version" {
			Get = function(self)
				return _ModuleInfo[self].Version
			end,
		}

		------------------------------------------------------
		-- Dispose
		------------------------------------------------------
		function Dispose(self)
			local info = _ModuleInfo[self]

			if info then
				-- Clear child modules
				if info.Modules then
					for name, mdl in pairs(info.Modules) do
						mdl:Dispose()
					end

					wipe(info.Modules)

					info.Modules = nil
				end

				-- Fire the event
				self:Fire("OnDispose")

				-- Clear from parent
				if info.Name then
					if info.Parent then
						if _ModuleInfo[info.Parent] and _ModuleInfo[info.Parent].Modules then
							_ModuleInfo[info.Parent].Modules[info.Name] = nil
						end
					else
						_Module[info.Name] = nil
					end
				end

				-- Remove info
				_ModuleInfo[self] = nil
			end
		end

		------------------------------------------------------
		-- Constructor
		------------------------------------------------------
	    function Module(self, parent, name)
			local prevName

			-- Check args
			name = type(parent) == "string" and parent or name

			if not Reflector.ObjectIsClass(parent, Module) then
				parent = nil
			end

			-- Check and create parent modules
			if type(name) == "string" then
				for sub in name:gmatch("[_%w]+") do
					if not prevName then
						prevName = sub
					else
						parent = Module(parent, prevName)

						prevName = sub
					end
				end
			end

			-- Save the module's information
	    	if prevName then
	    		if parent then
	    			_ModuleInfo[parent].Modules = _ModuleInfo[parent].Modules or {}
	    			_ModuleInfo[parent].Modules[prevName] = self
	    		else
	    			_Module[prevName] = self
	    		end
	    	else
	    		parent = nil
	    	end

	    	_ModuleInfo[self] = {
		    	Owner = self,
		    	Name = prevName,
		    	Parent = parent,
		    }
	    end

		------------------------------------------------------
		-- metamethod
		------------------------------------------------------
		function __exist(parent, name)
			local mdl = nil

			-- Check args
			if Reflector.ObjectIsClass(parent, Module) then
				mdl = parent
			end

			name = type(parent) == "string" and parent or name

			if type(name) == "string" then
				for sub in name:gmatch("[_%w]+") do
					if not mdl then
						mdl = _Module[sub]
					elseif _ModuleInfo[mdl] and _ModuleInfo[mdl].Modules then
						mdl = _ModuleInfo[mdl].Modules[sub]
					else
						mdl = nil
					end

					if not mdl then return end
				end

				if mdl == parent then return end

				return mdl
			end
		end

		function __index(self, key)
			-- Check keywords
			if _ModuleEnv[key] then
				return _ModuleEnv[key]
			end

			-- Check self's namespace
			local ns = Reflector.GetCurrentNameSpace(self, true)
			local parent = _ModuleInfo[self].Parent

			while not ns and parent do
				ns = Reflector.GetCurrentNameSpace(parent, true)
				parent = _ModuleInfo[parent].Parent
			end

			if ns and Reflector.GetName(ns) then
				if key == Reflector.GetName(ns) then
					rawset(self, key, ns)
					return rawget(self, key)
				elseif ns[key] then
					rawset(self, key, ns[key])
					return rawget(self, key)
				end
			end

			local info = _ModuleInfo[self]

			-- Check imports
			if info.Import then
				for _, ns in ipairs(info.Import) do
					if key == Reflector.GetName(ns) then
						rawset(self, key, ns)
						return rawget(self, key)
					elseif ns[key] then
						rawset(self, key, ns[key])
						return rawget(self, key)
					end
				end
			end

			-- Check base namespace
			if Reflector.ForName(key) then
				rawset(self, key, Reflector.ForName(key))
				return rawget(self, key)
			end

			if info.Parent then
				local value = info.Parent[key]

				if type(value) == "userdata" or type(value) == "table" or type(value) == "function" then
					rawset(self, key, value)
				end

				return value
			else
				if key ~= "_G" and type(key) == "string" and key:find("^_") then
					return
				end

				local value = _G[key]
				if value then
					if type(value) == "userdata" or type(value) == "function" or type(value) == "table" then
						rawset(self, key, value)
						return rawget(self, key)
					end

					return value
				end
			end
		end

		function __newindex(self, key, value)
			if _ModuleEnv[key] then
				error(("%s is a keyword."):format(key), 2)
			end

			rawset(self, key, value)
		end

		function __call(self, version, depth)
			depth = type(depth) == "number" and depth > 0 and depth or 1

			local info = _ModuleInfo[self]

			if not info then
				error("The module is disposed", 2)
			end

			-- Check version
			if type(version) == "number" then
				version = tostring(version)
			elseif type(version) == "string" then
				version = strtrim(version)

				if version == "" then version = nil end
			end

			if type(version) == "string" then
				local number = version:match("^.-(%d+[%d%.]*).-$")

				if number then
					number = number:match("^(.-)[%.]*$")

					if info.Version then
						local onumber = info.Version:match("^.-(%d+[%d%.]*).-$")

						if onumber then
							onumber = onumber:match("^(.-)[%.]*$")

							local f1 = onumber:gmatch("%d+")
							local f2 = number:gmatch("%d+")

							local v1 = f1 and f1()
							local v2 = f2 and f2()

							local pass = false

							while true do
								v1 = tonumber(v1)
								v2 = tonumber(v2)

								if not v1 then
									if v2 then pass = true end
									break
								elseif not v2 then
									break
								elseif v1 < v2 then
									pass = true
									break
								elseif v1 > v2 then
									break
								end

								v1 = f1 and f1()
								v2 = f2 and f2()
							end

							-- Clear
							while f1 and f1() do end
							while f2 and f2() do end

							-- Check falg
							if pass then
								info.Version = version
							else
								error("The version must be greater than the current version of the module.", 2)
							end
						else
							info.Version = version
						end
					else
						info.Version = version
					end
				else
					error("The version string should contain version numbers like 'Ver 1.2323.13'.")
				end
			elseif info.Version then
				error("An available version is need for the module.", 2)
			end

			setfenv(depth + 1, self)
		end
	endclass "Module"
end

------------------------------------------------------
-- Global Settings
------------------------------------------------------
do
	function import_install(name, all)
		local ns = Reflector.ForName(name)
		local env = getfenv(2)

		if ns and env then
			env[Reflector.GetName(ns)] = ns

			if all then
				for _, subNs in ipairs(Reflector.GetSubNamespace(ns)) do
					env[subNs] = ns[subNs]
				end
			end
		else
			error("No such namespace.", 2)
		end
	end

	function Install_OOP(env)
		if type(env) == "table" then
			env.partinterface = partinterface
			env.partclass = partclass
			env.interface = interface
			env.class = class
			env.enum = enum
			env.namespace = namespace
			env.struct = struct
			env.import = import_install
			env.Module = Module
		end
	end

	-- Install to the global environment
	Install_OOP(_G)
end
