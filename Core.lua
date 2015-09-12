--[[
Copyright (c) 2011-2015 WangXH <kurapica125@outlook.com>

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

------------------------------------------------------------------------
--
-- Pure Lua Object-Oriented Program System
--
-- Config :
--    PLOOP_DOCUMENT_ENABLED - Whether enable/disable document system, default true
--    PLOOP_SAVE_MEMORY - Whether save the memory, default false
------------------------------------------------------------------------

------------------------------------------------------------------------
-- Author			kurapica125@outlook.com
-- Create Date		2011/02/01
-- Last Update Date 2015/09/11
-- Version			r129
------------------------------------------------------------------------

------------------------------------------------------
-- Object oriented program syntax system environment
------------------------------------------------------
do
	local _G, rawset = _G, rawset
	local _PLoopEnv = setmetatable({}, {
		__index = function(self,  key)
			local value = _G[key] if value ~= nil then rawset(self, key, value) return value end
		end, __metatable = true,
	})

	-- Local Environment
	if setfenv then setfenv(1, _PLoopEnv) else _ENV = _PLoopEnv end

	WEAK_KEY, WEAK_VALUE, WEAK_ALL = {__mode = "k"}, {__mode = "v"}, {__mode = "kv"}

	-- Common features
	strlen = string.len
	strformat = string.format
	strfind = string.find
	strsub = string.sub
	strbyte = string.byte
	strchar = string.char
	strrep = string.rep
	strgsub = string.gsub
	strupper = string.upper
	strlower = string.lower
	strtrim = strtrim or function(s) return s and (s:gsub("^%s*(.-)%s*$", "%1")) or "" end
	wipe = wipe or function(t) for k in pairs(t) do t[k] = nil end return t end

	tblconcat = tblconcat or table.concat
	tinsert = tinsert or table.insert
	tremove = tremove or table.remove
	sort = sort or table.sort
	floor = floor or math.floor
	log = log or math.log

	create = coroutine.create
	resume = coroutine.resume
	running = coroutine.running
	status = coroutine.status
	wrap = coroutine.wrap
	yield = coroutine.yield

	geterrorhandler = geterrorhandler or function() return print end
	errorhandler = errorhandler or function(err) return pcall(geterrorhandler(), err) end

	-- Check For lua 5.2
	newproxy = newproxy or (function ()
		local _METATABLE_MAP = setmetatable({}, {__mode = "k"})

		return function (prototype)
			-- mean no userdata can be created in lua, use the table instead
			if type(prototype) == "table" and _METATABLE_MAP[prototype] then
				return setmetatable({}, _METATABLE_MAP[prototype])
			elseif prototype == true then
				local meta = {}
				prototype = setmetatable({}, meta)
				_METATABLE_MAP[prototype] = meta
				return prototype
			else
				return setmetatable({}, {__metatable = false})
			end
		end
	end)()

	FAKE_SETFENV = false
	if setfenv and getfenv then
		-- AUTO ADDED PASS
	else
		if not debug and require then require "debug" end
		if debug and debug.getinfo and debug.getupvalue and debug.upvaluejoin and debug.getlocal then
			local getinfo = debug.getinfo
			local getupvalue = debug.getupvalue
			local upvaluejoin = debug.upvaluejoin
			local getlocal = debug.getlocal

			setfenv = function(f, t)
			    f = type(f) == 'function' and f or getinfo(f + 1, 'f').func
			    local up, name = 0
			    repeat
			        up = up + 1
			        name = getupvalue(f, up)
			    until name == '_ENV' or name == nil
			    if name then upvaluejoin(f, up, function() return t end, 1) end
			end

			getfenv = function(f)
			    local cf, up, name, val = type(f) == 'function' and f or getinfo(f + 1, 'f').func, 0
			    repeat
			        up = up + 1
			        name, val = getupvalue(cf, up)
			    until name == '_ENV' or name == nil
			    if val then return val end

			    if type(f) == "number" then
			    	f, up = f + 1, 0
				    repeat
				        up = up + 1
				        name, val = getlocal(f, up)
				    until name == '_ENV' or name == nil
				    if val then return val end
			    end
			end
		else
			local _FENV_Cache = setmetatable({ [running() or 0] = _ENV }, {
				__call = function (self, env)
					if env then
						self[running() or 0] = env
					else
						return self[running() or 0]
					end
				end, __mode = "k",
			})
			FAKE_SETFENV = true
			getfenv = function (lvl) return _FENV_Cache() end
			setfenv = function (lvl, env) _FENV_Cache(env) end
		end
	end

	-- In lua 5.2, the loadstring is deprecated
	loadstring = loadstring or load
end

------------------------------------------------------
-- GLOBAL Definition
------------------------------------------------------
do
	-- Used to enable/disable document system, not started with '_', so can be disabled outsider
	DOCUMENT_ENABLED = PLOOP_DOCUMENT_ENABLED == nil and true or PLOOP_DOCUMENT_ENABLED
	SAVE_MEMORY = PLOOP_SAVE_MEMORY and true or false

	TYPE_CLASS = "Class"
	TYPE_ENUM = "Enum"
	TYPE_STRUCT = "Struct"
	TYPE_INTERFACE = "Interface"

	TYPE_NAMESPACE = "NameSpace"
	TYPE_SUPERALIAS = "SuperAlias"
	TYPE_TYPE = "TYPE"

	-- Disposing method name
	DISPOSE_METHOD = "Dispose"

	-- Namespace field
	NAMESPACE_FIELD = "__PLOOP_NameSpace"

	-- Owner field
	OWNER_FIELD = "__PLOOP_OWNER"

	-- Base env field
	BASE_ENV_FIELD = "__PLOOP_BASE_ENV"

	-- Local env field
	LOCAL_ENV_FIELD = "__PLOOP_LOCAL"
end

------------------------------------------------------
-- Thread Pool & Tools
------------------------------------------------------
do
	ATTRIBUTE_INSTALLED = false

	THREAD_POOL_SIZE = 100

	-- This func means the function call is finished successful, so, we need send the running thread back to the pool
	local function retValueAndRecycle(...) THREAD_POOL( running() ) return ... end

	local function callFunc(func, ...) return retValueAndRecycle( func(...) ) end

	local function newRycThread(pool, func)
		while pool == THREAD_POOL and type(func) == "function" do pool, func = yield( callFunc ( func, yield() ) ) end
	end

	THREAD_POOL = setmetatable({}, {
		__call = function(self, value)
			if value then
				-- re-use the thread or use resume to kill
				if #self < THREAD_POOL_SIZE then tinsert(self, value) else resume(value) end
			else
				-- Keep safe from unexpected resume
				while not value or status(value) == "dead" do value = tremove(self) or create(newRycThread) end
				return value
			end
		end,
	})

	local function chkValue(flag, msg, ...)
		if flag then
			return msg, ...
		else
			return error(type(msg) == "string" and msg:match(":%d+:%s*(.-)$") or msg, 3)
		end
	end

	function CallThread(func, ...)
		if type(func) == "thread" and status(func) == "suspended" then return chkValue( resume(func, ...) ) end

		local th = THREAD_POOL()

		-- Register the function
		resume(th, THREAD_POOL, func)

		-- Call and return the result
		return chkValue( resume(th, ...) )
	end

	CACHE_TABLE = setmetatable({}, {
		__call = function(self, key)
			if key then
				wipe(key)
				tinsert(self, key)
			else
				return tremove(self) or {}
			end
		end,
	})

	function SaveFixedMethod(storage, key, value, owner, targetType)
		if ATTRIBUTE_INSTALLED then
			value = ConsumePreparedAttributes(value, targetType or AttributeTargets.Method, owner, key) or value
		end

		if ATTRIBUTE_INSTALLED and targetType ~= AttributeTargets.Constructor then
			-- Hide the real fixed method for method and meta-method, started with '0', strange but useful
			local rKey = "0" .. key

			if storage[rKey] then
				if type(value) == "function" and (not getmetatable(storage[rKey]) or storage[rKey].Owner ~= owner) then
					-- roll back to normal meta-methods
					storage[key] = value
					storage[rKey] = nil
					return
				end

				key = rKey
			elseif getmetatable(value) then
				storage[rKey] = storage[key]

				-- table can't be meta-methods & hide the details
				storage[key] = function(...)
					return storage[rKey](...)
				end

				key = rKey
			end
		end

		if getmetatable(storage[key]) then
			local prev
			local fixedMethod = storage[key]

			while getmetatable(fixedMethod) and fixedMethod.Owner == owner do
				if getmetatable(value) and #fixedMethod == #value and fixedMethod.MinArgs == value.MinArgs then
					local isEqual = true

					if fixedMethod == value then return end

					for i = 1, #fixedMethod do
						if not IsEqual(fixedMethod[i], value[i]) then
							isEqual = false
							break
						end
					end

					if isEqual then
						if prev then
							value.Next = fixedMethod.Next
							prev.Next = value
							value = nil
						else
							value.Next = fixedMethod.Next
							storage[key] = value
							value = nil
						end

						break
					end
				end

				prev = fixedMethod
				fixedMethod = fixedMethod.Next
			end

			if getmetatable(value) then
				value.Next = storage[key]
				storage[key] = value
			elseif value then
				if prev then prev.Next = value else storage[key] = value end
			end
		elseif storage[key] and getmetatable(value) then
			value.Next = storage[key]
			storage[key] = value
		else
			storage[key] = value
		end
	end

	-- Clone
	local function deepCloneObj(obj, cache)
		if type(obj) == "table" then
			if cache[obj] ~= nil then
				return cache[obj]
			elseif getmetatable(obj) then
				cache[obj] = type(obj.Clone) == "function" and obj:Clone(true) or obj
				return cache[obj]
			else
				local ret = {}
				cache[obj] = ret

				for k, v in pairs(obj) do ret[k] = deepCloneObj(v, cache) end

				return ret
			end
		else
			return obj
		end
	end

	function CloneObj(obj, deep)
		if type(obj) == "table" then
			if getmetatable(obj) then
				if type(obj.Clone) == "function" then return obj:Clone(deep) else return obj end
			else
				local ret = {}
				local cache = deep and CACHE_TABLE()

				if cache then cache[obj] = ret end

				for k, v in pairs(obj) do
					if deep then ret[k] = deepCloneObj(v, cache) else ret[k] = v == obj and ret or v end
				end

				if cache then CACHE_TABLE(cache) end

				return ret
			end
		else
			return obj
		end
	end

	-- Local marker
	LOCAL_CACHE = setmetatable({}, WEAK_KEY)
	PrepareNameSpace_CACHE = setmetatable({}, WEAK_KEY)

	function SetLocal(flag) LOCAL_CACHE[running() or 0] = flag or nil end
	function IsLocal() return LOCAL_CACHE[running() or 0] end

	function PrepareNameSpace(target) PrepareNameSpace_CACHE[running() or 0] = target end
	function GetPrepareNameSpace() return PrepareNameSpace_CACHE[running() or 0] end

	-- Equal Check
	local function checkEqual(obj1, obj2, cache)
		if obj1 == obj2 then return true end
		if type(obj1) ~= "table" then return false end
		if type(obj2) ~= "table" then return false end

		if cache[obj1] and cache[obj2] then
			return true
		elseif cache[obj1] or cache[obj2] then
			return false
		else
			cache[obj1] = true
			cache[obj2] = true
		end

		local cls = getmetatable(obj1)
		if cls == TYPE_NAMESPACE then return false end

		local info = cls and _NSInfo[cls]
		if info then
			if cls ~= getmetatable(obj2) then return false end
			if info.MetaTable.__eq then return false end

			-- Check properties
			for name, prop in pairs(info.Cache) do
				if type(prop) == "table" and not getmetatable(prop) and (prop.Get or prop.GetMethod or prop.Field) then
					if not checkEqual(obj1[name], obj2[name], cache) then return false end
				end
			end
			return true
		end

		-- Check fields
		for k, v in pairs(obj1) do if not checkEqual(v, obj2[k], cache) then return false end end
		for k, v in pairs(obj2) do if obj1[k] == nil then return false end end

		return true
	end

	function IsEqual(obj1, obj2)
		local cache = CACHE_TABLE()
		local result = checkEqual(obj1, obj2, cache)
		CACHE_TABLE(cache)
		return result
	end

	-- Keyword access system
	local _KeywordAccessorInfo = {
		GetKeyword = function(self, owner, key)
			if type(key) == "string" and key:match("^%l") and self[key] then
				self.Owner, self.Keyword = owner, self[key]
				return self.KeyAccessor
			end
		end,
	}
	local _KeyAccessor = newproxy(true)
	getmetatable(_KeyAccessor).__call = function (self, value)
		self = _KeywordAccessorInfo[self]
		local keyword, owner = self.Keyword, self.Owner
		self.Keyword, self.Owner = nil, nil
		if keyword and owner then local ret = keyword(owner, value, 2) return ret end
	end
	getmetatable(_KeyAccessor).__metatable = false

	function _KeywordAccessor(key, value)
		if type(key) == "string" and type(value) == "function" then
			-- Save keywords to all accessors
			for _, info in pairs(_KeywordAccessorInfo) do if type(info) == "table" then info[key] = value end end
		else
			local keyAccessor = newproxy(_KeyAccessor)
			local info = { GetKeyword = _KeywordAccessorInfo.GetKeyword, KeyAccessor = keyAccessor }
			_KeywordAccessorInfo[keyAccessor] = info
			return info
		end
	end

	-- Final Check
	function IsFinalFeature(ns, name, isSuper)
		ns = _NSInfo[ns]

		if not ns then return false end

		if not name then
			return ns.IsFinal
		else
			if isSuper and not ns.Cache[name] then return nil end

			-- Check self
			if ns.FinalFeatures and ns.FinalFeatures[name] then return true end
			if ns.Method and ns.Method[name] then return isSuper and ns.IsFinal or false end
			if ns.Property and ns.Property[name] then return isSuper and ns.IsFinal or false end

			-- Check Super class
			if ns.SuperClass then
				local ret = IsFinalFeature(ns.SuperClass, name, true)
				if ret ~= nil then return ret end
			end

			-- Check Extened interfaces
			if ns.ExtendInterface then
				for _, IF in ipairs(ns.ExtendInterface) do
					local ret = IsFinalFeature(IF, name, true)
					if ret ~= nil then return ret end
				end
			end

			return false
		end
	end
end

------------------------------------------------------
-- NameSpace & SuperAlias
------------------------------------------------------
do
	_NameSpace = newproxy(true)
	_SuperAlias = newproxy(true)

	_NSInfo = setmetatable({}, {
		__index = function(self, key)
			if type(key) == "string" then
				key = GetNameSpace(GetDefaultNameSpace(), key)
				if not key then return end
				local ret = rawget(self, key)
				if ret then return ret end
			end
			if not IsNameSpace(key) then return end
			local ret = { Owner = key }
			self[key] = ret
			return ret
		end,
		__mode = "k",
	})

	_SuperMap = setmetatable({}, WEAK_ALL)

	-- metatable for namespaces
	_MetaNS = getmetatable(_NameSpace)
	do
		_MetaNS.__call = function(self, ...)
			local info = _NSInfo[self]

			if info.Type == TYPE_CLASS then
				-- Create Class object
				return Class2Obj(self, ...)
			elseif info.Type == TYPE_STRUCT then
				-- Create Struct
				return Struct2Obj(self, ...)
			elseif info.Type == TYPE_ENUM then
				-- Parse Enum
				local value = ...
				if info.IsFlags and type(value) == "number" and value >= 0 and value <= info.MaxValue then
					if value == 0 or info.Cache[value] then
						return info.Cache[value]
					else
						local rCache = CACHE_TABLE()
						local eCache = info.Cache
						local ckv = 1

						while ckv <= value do
							local sub = value % (2 * ckv)
							if (sub - sub % ckv) == ckv then
								tinsert(rCache, eCache[ckv])
							end

							ckv = ckv * 2
						end

						return unpack(rCache)
					end
				else
					return info.Cache[value]
				end
			end

			error(tostring(self) .. " is not callable.", 2)
		end

		_MetaNS.__index = function(self, key)
			local info = _NSInfo[self]

			-- Sub-NS first
			local ret = info.SubNS and info.SubNS[key]
			if ret then return ret end

			local iType = info.Type

			if iType == TYPE_STRUCT then
				ret = info.Method and info.Method[key]
				if ret then return ret end
			elseif iType == TYPE_CLASS or iType == TYPE_INTERFACE then
				-- Method
				ret = info.Method[key] or info.Cache[key]
				if type(ret) == "function" then return ret end

				-- Property
				ret = info.Property[key]
				if ret and ret.IsStatic then
					-- Property
					local oper = ret
					local value
					local default = oper.Default

					-- Get Getter
					local operTar = oper.Get-- or info.Method[oper.GetMethod]

					-- Get Value
					if operTar then
						value = operTar()
					else
						operTar = oper.Field

						if operTar then
							value = oper.SetWeak and info.WeakStaticFields or info.StaticFields
							value = value and value[operTar]
						elseif default == nil then
							error(("%s can't be read."):format(key),2)
						end
					end

					if value == nil then
						operTar = oper.DefaultFunc
						if operTar then
							value = operTar(self)
							if value ~= nil then
								if oper.Set == false then
									operTar = oper.Field

									-- Check container
									local container

									if oper.SetWeak then
										container = info.WeakStaticFields
										if not container then
											container = setmetatable({}, WEAK_VALUE)
											info.WeakStaticFields = container
										end
									else
										container = info.StaticFields
										if not container then
											container = {}
											info.StaticFields = container
										end
									end

									-- Set the value
									container[operTar] = value
								else
									self[key] = value
								end
							end
						else
							value = default
						end
					end
					if oper.GetClone then value = CloneObj(value, oper.GetDeepClone) end

					return value
				end
			elseif iType == TYPE_ENUM then
				return type(key) == "string" and info.Enum[strupper(key)] or error(("%s is not an enumeration value of %s."):format(tostring(key), tostring(self)), 2)
			end
		end

		_MetaNS.__newindex = function(self, key, value)
			local info = _NSInfo[self]

			if info.Type == TYPE_STRUCT and type(key) == "string" and type(value) == "function" then
				if key == info.Name then
					if info.IsSealed then error(("%s is sealed, can't be overridden."):format(tostring(self)), 2) end
					info.Validator = value
					return
				else
					if info.IsSealed and ((info.Method and info.Method[key]) or (info.StructEnv[key])) then error(("%s.%s is sealed, can't be overridden."):format(tostring(self), key), 2) end
					info.Method = info.Method or {}
					return SaveFixedMethod(info.Method, key, value, info.Owner)
				end
			elseif (info.Type == TYPE_CLASS or info.Type == TYPE_INTERFACE) and type(key) == "string" then
				-- Static Property
				local oper = info.Property[key]

				if oper and oper.IsStatic then
					if oper.Set == false then error(("%s can't be written."):format(key), 2) end

					-- Property
					if oper.Type then value = Validate4Type(oper.Type, value, key, key, 2) end
					if oper.SetClone then value = CloneObj(value, oper.SetDeepClone) end

					-- Get Setter
					local operTar = oper.Set-- or info.Method[oper.SetMethod]

					-- Set Value
					if operTar then
						return operTar(value)
					else
						operTar = oper.Field

						if operTar then
							-- Check container
							local container
							local default = oper.Default

							if oper.SetWeak then
								container = info.WeakStaticFields
								if not container then
									container = setmetatable({}, WEAK_VALUE)
									info.WeakStaticFields = container
								end
							else
								container = info.StaticFields
								if not container then
									container = {}
									info.StaticFields = container
								end
							end

							-- Check old value
							local old = container[operTar]
							if old == nil then old = default end
							if old == value then return end

							-- Set the value
							container[operTar] = value

							-- Dispose old
							if oper.SetRetain and old and old ~= default then
								DisposeObject(old)
								old = nil
							end

							-- Call handler
							operTar = oper.Handler

							return operTar and operTar(self, value, old, key)
						else
							error(("%s can't be written."):format(key), 2)
						end
					end
				else
					if IsFinalFeature(self, key) then error(("%s.%s is final, can't be overridden."):format(tostring(self), key), 2) end
					if info.IsSealed and info.Cache[key] then error(("%s.%s is sealed, can't be overridden."):format(tostring(self), key), 2) end

					local vType = getmetatable(value)

					-- new feature
					if vType == TYPE_NAMESPACE then
						SetPropertyWithSet(info, key, { Type = value })
					elseif type(value) == "function" then
						-- Method
						SaveFixedMethod(info.Method, key, value, info.Owner)
					elseif type(value) == "table" then
						-- Property
						SetPropertyWithSet(info, key, value)
					elseif not tonumber(key) and value == true then
						-- Event
						info.Event[key] = info.Event[key] or Event(key)

						if ATTRIBUTE_INSTALLED then ConsumePreparedAttributes(info.Event[key], AttributeTargets.Event, info.Owner, key) end
					else
						error(("Can't set value for %s, it's readonly."):format(tostring(self)), 2)
					end

					return not info.BeginDefinition and RefreshCache(self)
				end
			end

			error(("Can't set value for %s, it's readonly."):format(tostring(self)), 2)
		end

		_MetaNS.__tostring = function(self)
			local info = _NSInfo[self]

			if info then
				local name = info.Name

				while info and info.NameSpace do
					info = _NSInfo[info.NameSpace]

					if info then name = info.Name.."."..name end
				end

				return name
			end
		end

		_MetaNS.__metatable = TYPE_NAMESPACE

		_MetaNS = nil
	end

	-- metatable for super alias
	_MetaSA = getmetatable(_SuperAlias)
	do
		_MetaSA.__call = function(self, ...)
			-- Init the class object
			local cls = _SuperMap[self].Owner

			if IsChildClass(cls, getmetatable(...)) then return Class1Obj(cls, ...) end
		end

		_MetaSA.__index = function(self, key)
			local info = _SuperMap[self]

			local ret = info.SubNS and info.SubNS[key]

			if ret then
				return ret
			elseif _KeyMeta[key] ~= nil then
				return _KeyMeta[key] and info.MetaTable[key] or info.MetaTable["_"..key]
			else
				ret = info.Method[key] or info.Cache[key]
				if type(ret) == "function" then return ret end
			end
		end

		_MetaSA.__tostring = function(self) return tostring(_SuperMap[self].Owner) end
		_MetaSA.__metatable = TYPE_SUPERALIAS

		_MetaSA = nil
	end

	-- IsNameSpace
	function IsNameSpace(ns) return getmetatable(ns) == TYPE_NAMESPACE end

	-- BuildNameSpace
	function BuildNameSpace(ns, namelist)
		if type(namelist) ~= "string" or (ns and not IsNameSpace(ns)) then return end

		local cls = ns
		local info = _NSInfo[cls]
		local parent = cls

		for name in namelist:gmatch("[_%w]+") do
			if not info then
				cls = newproxy(_NameSpace)
			elseif info.Type ~= TYPE_ENUM then
				info.SubNS = info.SubNS or {}
				info.SubNS[name] = info.SubNS[name] or newproxy(_NameSpace)

				if cls == _NameSpace then _G[name] = _G[name] or info.SubNS[name] end

				cls = info.SubNS[name]
			else
				error(("can't add item to a %s."):format(tostring(info.Type)), 2)
			end

			info = _NSInfo[cls]
			info.Name = name
			if not info.NameSpace and parent ~= _NameSpace then info.NameSpace = parent end
			parent = cls
		end

		if cls == ns then return end

		return cls
	end

	-- GetNameSpace
	function GetNameSpace(ns, namelist)
		if type(namelist) ~= "string" or not IsNameSpace(ns) then return end

		local cls = ns

		for name in namelist:gmatch("[_%w]+") do
			cls = cls[name]
			if not cls then return end
		end

		if cls == ns then return end

		return cls
	end

	-- GetDefaultNameSpace
	function GetDefaultNameSpace() return _NameSpace end

	-- SetNameSpace
	function SetNameSpace4Env(env, name)
		if type(env) ~= "table" then return end

		local ns = type(name) == "string" and BuildNameSpace(GetDefaultNameSpace(), name) or IsNameSpace(name) and name or nil
		rawset(env, NAMESPACE_FIELD, ns)

		return ns
	end

	-- GetEnvNameSpace
	function GetNameSpace4Env(env, rawOnly)
		local ns = type(env) == "table" and ((rawOnly and rawget(env, NAMESPACE_FIELD)) or (not rawOnly and env[NAMESPACE_FIELD]))

		if IsNameSpace(ns) then return ns end
	end

	------------------------------------
	--- Set the default namespace for the current environment, the class defined in this environment will be stored in this namespace
	-- @name namespace
	-- @class function
	-- <param name="name">the namespace's name list, using "." to split.</param>
	-- <usage>namespace "Widget"</usage>
	------------------------------------
	function namespace(env, name, depth)
		depth = tonumber(depth) or 1
		name = name or env
		if name ~= nil and type(name) ~= "string" and not IsNameSpace(name) then error([[Usage: namespace "namespace"]], depth + 1) end
		env = type(env) == "table" and env or getfenv(depth + 1) or _G

		local ns = SetNameSpace4Env(env, name)

		return ns and ATTRIBUTE_INSTALLED and ConsumePreparedAttributes(ns, AttributeTargets.NameSpace)
	end
end

------------------------------------------------------
-- Type Validation
------------------------------------------------------
do
	function Validate4Type(oType, value, partName, mainName, stack)
		if value == nil or not oType then return value end

		local info = _NSInfo[oType]
		if not info then return value end

		local iType = info.Type
		local flag, ret

		if iType == TYPE_STRUCT then
			flag, ret = pcall(ValidateStruct, oType, value)

			if flag then return ret end

			ret = strtrim(ret:match(":%d+:%s*(.-)$") or ret)
		elseif iType == TYPE_ENUM then
			-- Check if the value is an enumeration value of this enum
			if type(value) == "string" then
				local val = info.Enum[strupper(value)]
				if val ~= nil then return val end
			end

			if info.MaxValue then
				-- Bit flag validation, use MaxValue check to reduce cost
				value = tonumber(value)

				if value then
					value = floor(value)
					if (value == 0 and info.Cache[0]) or (value >= 1 and value <= info.MaxValue) then
						return value
					end
				end
			else
				if info.Cache[value] then return value end
			end

			ret = ("%s must be a value of [enum]%s ( %s )."):format("%s", tostring(oType), GetShortEnumInfo(oType))
		else
			local cls = getmetatable(value)

			if iType == TYPE_CLASS then
				if cls and IsChildClass(oType, cls) then return value end

				ret = ("%s must be an instance of [class]%s."):format("%s", tostring(oType))
			elseif iType == TYPE_INTERFACE then
				if cls and IsExtend(oType, cls) then return value end

				ret = ("%s must be an instance extended from [interface]%s."):format("%s", tostring(oType))
			end
		end

		if partName and partName ~= "" then
			if ret:find("%%s([_%w]+)") then
				ret = ret:gsub("%%s", "%%s"..partName..".")
			else
				ret = ret:gsub("%%s", "%%s"..partName)
			end
		end

		--if not ret:match("%(Optional%)$") then ret = ret .. "(Optional)" end

		if mainName and ret:find("%%s") then ret = ret:gsub("%%s[_%w]*", mainName) end

		error(ret, (stack or 1) + 1)
	end

	function GetValidatedValue(oType, value)
		if value == nil or not oType then return value end

		local info = _NSInfo[oType]
		if not info then return value end

		local iType = info.Type
		local flag, ret

		if iType == TYPE_STRUCT then
			flag, ret = pcall(ValidateStruct, oType, value)

			if flag then return ret end
		elseif iType == TYPE_ENUM then
			-- Check if the value is an enumeration value of this enum
			if type(value) == "string" then
				local val = info.Enum[strupper(value)]
				if val ~= nil then return val end
			end

			if info.MaxValue then
				-- Bit flag validation, use MaxValue check to reduce cost
				value = tonumber(value)

				if value then
					value = floor(value)
					if (value == 0 and info.Cache[0]) or (value >= 1 and value <= info.MaxValue) then
						return value
					end
				end
			else
				if info.Cache[value] then return value end
			end
		else
			local cls = getmetatable(value)

			if iType == TYPE_CLASS then
				if cls and IsChildClass(oType, cls) then return value end
			elseif iType == TYPE_INTERFACE then
				if cls and IsExtend(oType, cls) then return value end
			end
		end
	end
end

------------------------------------------------------
-- Documentation
------------------------------------------------------
do
	function getSuperDoc(info, key, dkey)
		if info.SuperClass then
			local sinfo = _NSInfo[info.SuperClass]

			while sinfo do
				if sinfo.Documentation and (sinfo.Documentation[key] or sinfo.Documentation[dkey]) then
					return sinfo.Documentation[key] or sinfo.Documentation[dkey]
				end

				if sinfo.SuperClass then
					sinfo = _NSInfo[sinfo.SuperClass]
				else
					break
				end
			end
		end

		-- Check Interface
		if info.Cache4Interface then
			for _, IF in ipairs(info.Cache4Interface) do
				local sinfo = _NSInfo[IF]

				if sinfo.Documentation and (sinfo.Documentation[key] or sinfo.Documentation[dkey]) then
					return sinfo.Documentation[key] or sinfo.Documentation[dkey]
				end
			end
		end
	end

	function getTargetType(info, name, targetType)
		if targetType == nil then
			-- Find the targetType based on the name
			if name == info.Name then
				targetType = AttributeTargets[info.Type or TYPE_NAMESPACE]
			elseif info.Cache[name] then
				local tar = info.Cache[name]
				if type(tar) == "function" then
					return AttributeTargets.Method
				elseif getmetatable(tar) then
					return AttributeTargets.Event
				else
					return AttributeTargets.Property
				end
			end
		elseif type(targetType) == "string" then
			targetType = AttributeTargets[targetType]
		elseif type(targetType) ~= "number" then
			targetType = nil
		end

		return targetType
	end

	function SaveDocument(data, name, targetType, owner)
		if not DOCUMENT_ENABLED or type(data) ~= "string" then return end

		local info = _NSInfo[owner]

		if not info then return end

		if not name then name = info.Name end

		-- Check the type
		targetType = getTargetType(info, name, targetType)

		-- Get the head space in the first line and remove it from all lines
		local space = data:match("^%s+")

		if space then data = data:gsub("^%s+", ""):gsub("([\n\r]+)"..space, "%1"):gsub("([\n\r]+)%s+$", "%1") end

		local key = name

		if targetType then key = tostring(targetType) .. name end

		info.Documentation = info.Documentation or {}
		info.Documentation[key] = data
	end

	function GetDocument(owner, name, targetType)
		if not DOCUMENT_ENABLED then return end

		if type(owner) == "string" then owner = GetNameSpace(GetDefaultNameSpace(), owner) end

		local info = _NSInfo[owner]
		if not info then return end

		name = name or info.Name
		if type(name) ~= "string" then return end

		targetType = getTargetType(info, name, targetType)

		local key = targetType and tostring(targetType) .. name or nil

		return info.Documentation and (info.Documentation[key] or info.Documentation[name]) or (targetType ~= "CLASS" and targetType ~= "INTERFACE") and getSuperDoc(info, key, name) or nil
	end

	do
		local _name
		local _owner

		local function parseDoc(data)
			local info = _NSInfo[_owner]
			if _name == info.Name then
				return SaveDocument(data, _name, AttributeTargets[info.Type], _owner)
			else
				return SaveDocument(data, _name, AttributeTargets.Method, _owner)
			end
		end

		function document(env, name)
			_name = name
			_owner = env[OWNER_FIELD]

			return parseDoc
		end
	end
end

------------------------------------------------------
-- Interface
------------------------------------------------------
do
	_KeyWord4IFEnv = _KeywordAccessor()

	do
		Verb2Adj = {
			"(.+)(ed)$",
			"(.+)(able)$",
			"(.+)(ing)$",
			"(.+)(ive)$",
			"(.+)(ary)$",
			"(.+)(al)$",
			"(.+)(ous)$",
			"(.+)(ior)$",
			"(.+)(ful)$",
		}

		function ParseAdj(str, useIs)
			local noun, adj = str:match("^(.-)(%u%l+)$")

			if noun and adj and #noun > 0 and #adj > 0 then
				for _, pattern in ipairs(Verb2Adj) do
					local head, tail = adj:match(pattern)

					if head and tail and #head > 0 and #tail > 0 then
						local c = head:sub(1, 1)

						if useIs then
							return "^[Ii]s[" .. strupper(c) .. strlower(c).."]" .. head:sub(2) .. "%w*" .. noun .. "$"
						else
							return "^[" .. strupper(c) .. strlower(c).."]" .. head:sub(2) .. "%w*" .. noun .. "$"
						end
					end
				end
			end
		end

		function CloneWithOverride(dest, src, chkStatic)
			for key, value in pairs(src) do if not (chkStatic and value.IsStatic) then dest[key] = value end end
		end

		function CloneWithoutOverride(dest, src)
			for key, value in pairs(src) do if dest[key] == nil then dest[key] = value end end
		end

		function CloneInterfaceCache(dest, src, cache)
			if not src then return end
			for _, IF in ipairs(src) do if not cache[IF] then cache[IF] = true tinsert(dest, IF) end end
		end

		function RefreshCache(ns)
			local info = _NSInfo[ns]
			local iCache = info.Cache

			-- Cache For Interface
			local cache = CACHE_TABLE()
			local cache4Interface = CACHE_TABLE()

			if info.SuperClass then CloneInterfaceCache(cache4Interface, _NSInfo[info.SuperClass].Cache4Interface, cache) end
			if info.ExtendInterface then
				for _, IF in ipairs(info.ExtendInterface) do CloneInterfaceCache(cache4Interface, _NSInfo[IF].Cache4Interface, cache) end
				CloneInterfaceCache(cache4Interface, info.ExtendInterface, cache)
			end

			CACHE_TABLE(cache)
			if next(cache4Interface) then
				info.Cache4Interface = cache4Interface
			else
				info.Cache4Interface = nil
				CACHE_TABLE(cache4Interface)
			end

			-- Cache for all
			wipe(iCache)
			if info.SuperClass then CloneWithOverride(iCache, _NSInfo[info.SuperClass].Cache) end
			if info.ExtendInterface then for _, IF in ipairs(info.ExtendInterface) do CloneWithoutOverride(iCache, _NSInfo[IF].Cache) end end

			-- Cache for event
			CloneWithOverride(iCache, info.Event)

			-- Cache for Method
			-- Validate fixedMethods, remove link to parent
			for name, method in pairs(info.Method) do
				while getmetatable(method) and method.Next do
					if method.IsLast then
						method.Next = nil
						method.IsLast = nil
						break
					else
						method = method.Next
					end
				end
			end
			local staticMethod = info.StaticMethod
			if staticMethod then
				for key, value in pairs(info.Method) do if not staticMethod[key] then iCache[key] = value end end
			else
				for key, value in pairs(info.Method) do iCache[key] = value end
			end

			-- Cache for Property
			-- Validate the properties
			for name, prop in pairs(info.Property) do
				if prop.Predefined then
					local set = prop.Predefined

					prop.Predefined = nil

					-- Static Property
					prop.IsStatic = set.IsStatic and true or false

					for k, v in pairs(set) do
						if type(k) == "string" then
							k = strlower(k)

							if k == "get" then
								if type(v) == "function" or type(v) == "boolean" then
									prop.Get = v
								elseif type(v) == "string" then
									prop.GetMethod = v
								end
							elseif k == "set" then
								if type(v) == "function" or type(v) == "boolean" then
									prop.Set = v
								elseif type(v) == "string" then
									prop.SetMethod = v
								end
							elseif k == "getmethod" then
								if type(v) == "string" then prop.GetMethod = v end
							elseif k == "setmethod" then
								if type(v) == "string" then prop.SetMethod = v end
							elseif k == "field" then
								prop.Field = v ~= name and v or nil
							elseif k == "type" then
								local tInfo = _NSInfo[v]

								if tInfo and (tInfo.Type == TYPE_ENUM or
												tInfo.Type == TYPE_STRUCT or
												tInfo.Type == TYPE_INTERFACE or
												tInfo.Type == TYPE_CLASS) then
									prop.Type = v
								end
							elseif k == "default" then
								prop.Default = v
							elseif k == "event" and (type(v) == "string" or getmetatable(v) == Event) then
								prop.Event = v
							elseif k == "handler" then
								if type(v) == "string" then
									prop.HandlerName = v
								elseif type(v) == "function" then
									prop.Handler = v
								end
							elseif k == "setter" and type(v) == "number" and floor(v) == v and v > 0 and v <= _NSInfo[Setter].MaxValue then
								prop.Setter = v
							elseif k == "getter" and type(v) == "number" and floor(v) == v and v > 0 and v <= _NSInfo[Getter].MaxValue then
								prop.Getter = v
							end
						end
					end

					-- Validate the default
					if prop.Default ~= nil then
						if prop.Type then
							local val = GetValidatedValue(prop.Type, prop.Default)
							if val == nil and type(prop.Default) == "function" then prop.DefaultFunc = prop.Default end
							prop.Default = val
						elseif type(prop.Default) == "function" then
							prop.DefaultFunc = prop.Default
							prop.Default = nil
						end
					end

					-- Clear
					if prop.Get ~= nil then prop.GetMethod = nil end
					if prop.Set ~= nil then prop.SetMethod = nil end

					local uname = name:gsub("^%a", strupper)

					if prop.IsStatic then
						if prop.GetMethod then
							if staticMethod and staticMethod[prop.GetMethod] then prop.Get = info.Method[prop.GetMethod] end
							prop.GetMethod = nil
						end
						if prop.SetMethod then
							if staticMethod and staticMethod[prop.SetMethod] then prop.Set = info.Method[prop.SetMethod] end
							prop.SetMethod = nil
						end

						if staticMethod then
							-- Auto generate GetMethod
							if ( prop.Get == nil or prop.Get == true ) and prop.Field == nil then
								-- GetMethod
								if staticMethod["get" .. uname] then
									prop.Get = info.Method["get" .. uname]
								elseif staticMethod["Get" .. uname] then
									prop.Get = info.Method["Get" .. uname]
								elseif prop.Type == Boolean then
									-- FlagEnabled -> IsFlagEnabled
									if staticMethod["is" .. uname] then
										prop.Get = info.Method["is" .. uname]
									elseif staticMethod["Is" .. uname] then
										prop.Get = info.Method["Is" .. uname]
									else
										-- FlagEnable -> IsEnableFlag
										local pattern = ParseAdj(uname, true)

										if pattern then
											for mname, method in pairs(staticMethod) do
												if method and mname:match(pattern) then prop.Get = info.Method[mname] break end
											end
										end
									end
								end
							end

							-- Auto generate SetMethod
							if ( prop.Set == nil or prop.Set == true ) and prop.Field == nil then
								-- SetMethod
								if staticMethod["set" .. uname] then
									prop.Set = info.Method["set" .. uname]
								elseif staticMethod["Set" .. uname] then
									prop.Set = info.Method["Set" .. uname]
								elseif prop.Type == Boolean then
									-- FlagEnabled -> EnableFlag, FlagDisabled -> DisableFlag
									local pattern = ParseAdj(uname)

									if pattern then
										for mname, method in pairs(staticMethod) do
											if method and mname:match(pattern) then prop.Set = info.Method[mname] break end
										end
									end
								end
							end
						end
					else
						if prop.GetMethod and type(iCache[prop.GetMethod]) ~= "function" then prop.GetMethod = nil end
						if prop.SetMethod and type(iCache[prop.SetMethod]) ~= "function" then prop.SetMethod = nil end

						-- Auto generate GetMethod
						if ( prop.Get == nil or prop.Get == true ) and not prop.GetMethod and prop.Field == nil then
							-- GetMethod
							if type(iCache["get" .. uname]) == "function" then
								prop.GetMethod = "get" .. uname
							elseif type(iCache["Get" .. uname]) == "function" then
								prop.GetMethod = "Get" .. uname
							elseif prop.Type == Boolean then
								-- FlagEnabled -> IsFlagEnabled
								if type(iCache["is" .. uname]) == "function" then
									prop.GetMethod = "is" .. uname
								elseif type(iCache["Is" .. uname]) == "function" then
									prop.GetMethod = "Is" .. uname
								else
									-- FlagEnable -> IsEnableFlag
									local pattern = ParseAdj(uname, true)

									if pattern then
										for mname, method in pairs(iCache) do
											if type(method) == "function" and mname:match(pattern) then prop.GetMethod = mname break end
										end
									end
								end
							end
						end

						-- Auto generate SetMethod
						if ( prop.Set == nil or prop.Set == true ) and not prop.SetMethod and prop.Field == nil then
							-- SetMethod
							if type(iCache["set" .. uname]) == "function" then
								prop.SetMethod = "set" .. uname
							elseif type(iCache["Set" .. uname]) == "function" then
								prop.SetMethod = "Set" .. uname
							elseif prop.Type == Boolean then
								-- FlagEnabled -> EnableFlag, FlagDisabled -> DisableFlag
								local pattern = ParseAdj(uname)

								if pattern then
									for mname, method in pairs(iCache) do
										if type(method) == "function" and mname:match(pattern) then prop.SetMethod = mname break end
									end
								end
							end
						end
					end

					-- Validate the Event
					if type(prop.Event) == "string" then
						local evt = iCache[prop.Event]
						if getmetatable(evt) then
							prop.Event = evt
						elseif evt == nil then
							-- Auto create
							local ename = prop.Event
							evt = Event(ename)
							info.Event[ename] = evt
							iCache[ename] = evt
							prop.Event = evt
						else
							prop.Event = nil
						end
					end

					-- Validate the Handler
					if prop.HandlerName then
						prop.Handler = iCache[prop.HandlerName]
						if type(prop.Handler) ~= "function" then prop.Handler = nil end
					end

					-- Validate the Setter
					if prop.Setter then
						prop.SetDeepClone = Reflector.ValidateFlags(Setter.DeepClone, prop.Setter) or nil
						prop.SetClone = Reflector.ValidateFlags(Setter.Clone, prop.Setter) or prop.SetDeepClone

						if prop.Set == nil and not prop.SetMethod then
							if Reflector.ValidateFlags(Setter.Retain, prop.Setter) and prop.Type then
								local tinfo = _NSInfo[prop.Type]

								if tinfo.Type == TYPE_CLASS or tinfo.Type == TYPE_INTERFACE then
									prop.SetRetain = true
								end
							end

							if prop.Get == nil and not prop.GetMethod then
								if Reflector.ValidateFlags(Setter.Weak, prop.Setter) then prop.SetWeak = true end
							end
						end

						prop.Setter = nil
					end

					-- Validate the Getter
					if prop.Getter then
						prop.GetDeepClone = Reflector.ValidateFlags(Getter.DeepClone, prop.Getter) or nil
						prop.GetClone = Reflector.ValidateFlags(Getter.Clone, prop.Getter) or prop.GetDeepClone

						prop.Getter = nil
					end

					-- Auto generate Field or methods
					if (prop.Set == nil or (prop.Set == false and prop.DefaultFunc)) and not prop.SetMethod and prop.Get == nil and not prop.GetMethod then
						if prop.Field == true then prop.Field = nil end
						local field = prop.Field or "_" .. info.Name:match("^_*(.-)$") .. "_" .. uname

						if set.Synthesize and prop.Set == nil then
							local getName, setName

							if set.Synthesize == __Synthesize__.NameCases.Pascal then
								getName, setName = "Get" .. uname, "Set" .. uname
							elseif set.Synthesize == __Synthesize__.NameCases.Camel then
								getName, setName = "get" .. uname, "set" .. uname
							end

							if prop.IsStatic then
								-- Generate getMethod
								local gbody = CACHE_TABLE()
								local upValues = CACHE_TABLE()

								tinsert(upValues, info) tinsert(gbody, "info")
								tinsert(upValues, field) tinsert(gbody, "field")
								if prop.GetClone then tinsert(upValues, CloneObj) tinsert(gbody, "CloneObj") end
								if prop.DefaultFunc then tinsert(upValues, prop.DefaultFunc) tinsert(gbody, "defaultFunc") end
								if prop.Default ~= nil then tinsert(upValues, prop.Default) tinsert(gbody, "default") end
								if prop.DefaultFunc then tinsert(upValues, name) tinsert(gbody, "propName") end

								local gHeader = "local " .. tblconcat(gbody, ", ") .. " = ..."
								wipe(gbody)
								tinsert(gbody, gHeader)

								tinsert(gbody, [[return function ()]])
								tinsert(gbody, [[local value]])
								if prop.SetWeak then
									tinsert(gbody, [[value = info.WeakStaticFields]])
									tinsert(gbody, [[value = value and value[field] ]])
								else
									tinsert(gbody, [[value = info.StaticFields]])
									tinsert(gbody, [[value = value and value[field] ]])
								end
								if prop.DefaultFunc then
									tinsert(gbody, [[if value == nil then]])
									tinsert(gbody, [[	value = defaultFunc(info.Owner)]])
									tinsert(gbody, [[	if value ~= nil then info.Owner[propName] = value end]])
									tinsert(gbody, [[end]])
								elseif prop.Default ~= nil then
									tinsert(gbody, [[if value == nil then value = default end]])
								end
								if prop.GetClone then
									if prop.GetDeepClone then
										tinsert(gbody, [[value = CloneObj(value, true)]])
									else
										tinsert(gbody, [[value = CloneObj(value)]])
									end
								end
								tinsert(gbody, [[return value]])
								tinsert(gbody, [[end]])

								info.Method[getName] = loadstring(tblconcat(gbody, "\n"))(unpack(upValues))

								-- Generate setMethod
								wipe(gbody)
								wipe(upValues)

								tinsert(upValues, info) tinsert(gbody, "info")
								if prop.Type then
									tinsert(upValues, Validate4Type) tinsert(gbody, "Validate4Type")
									tinsert(upValues, prop.Type) tinsert(gbody, "pType")
								end
								if prop.SetRetain then tinsert(upValues, DisposeObject) tinsert(gbody, "DisposeObject") end
								if prop.SetClone then tinsert(upValues, CloneObj) tinsert(gbody, "CloneObj") end
								if prop.SetWeak then tinsert(upValues, WEAK_VALUE) tinsert(gbody, "WEAK_VALUE") end
								tinsert(upValues, field) tinsert(gbody, "field")
								if prop.Default ~= nil then tinsert(upValues, prop.Default) tinsert(gbody, "default") end
								if prop.Handler then tinsert(upValues, prop.Handler) tinsert(gbody, "handler") end

								gHeader = "local " .. tblconcat(gbody, ", ") .. " = ..."
								wipe(gbody)
								tinsert(gbody, gHeader)

								tinsert(gbody, [[return function (value)]])
								if prop.Type then tinsert(gbody, ([[value = Validate4Type(pType, value, "%s", "%s", 2)]]):format(name, name)) end
								if prop.SetClone then
									if prop.SetDeepClone then
										tinsert(gbody, [[value = CloneObj(value, true)]])
									else
										tinsert(gbody, [[value = CloneObj(value)]])
									end
								end
								tinsert(gbody, [[local container]])
								if prop.SetWeak then
									tinsert(gbody, [[container = info.WeakStaticFields]])
									tinsert(gbody, [[if not container then]])
									tinsert(gbody, [[	container = setmetatable({}, WEAK_VALUE)]])
									tinsert(gbody, [[	info.WeakStaticFields = container]])
									tinsert(gbody, [[end]])
								else
									tinsert(gbody, [[container = info.StaticFields]])
									tinsert(gbody, [[if not container then]])
									tinsert(gbody, [[	container = {}]])
									tinsert(gbody, [[	info.StaticFields = container]])
									tinsert(gbody, [[end]])
								end
								tinsert(gbody, [[local old = container[field] ]])
								if prop.Default ~= nil then tinsert(gbody, [[if old == nil then old = default end]]) end
								tinsert(gbody, [[if old == value then return end]])
								tinsert(gbody, [[container[field] = value]])
								if prop.SetRetain then
									if prop.Default ~= nil then
										tinsert(gbody, [[if type(old) == "table" and getmetatable(old) and old ~= default then]])
									else
										tinsert(gbody, [[if type(old) == "table" and getmetatable(old) then]])
									end
									tinsert(gbody, [[DisposeObject(old)]])
									tinsert(gbody, [[old = nil]])
									tinsert(gbody, [[end]])
								end
								if prop.Handler then tinsert(gbody, ([[return handler(info.Owner, value, old, "%s")]]):format(name)) end

								tinsert(gbody, [[end]])

								info.Method[setName] = loadstring(tblconcat(gbody, "\n"))(unpack(upValues))

								CACHE_TABLE(gbody)
								CACHE_TABLE(upValues)

								info.StaticMethod = info.StaticMethod or {}
								info.StaticMethod[getName] = true
								info.StaticMethod[setName] = true

								prop.Get = info.Method[getName]
								prop.Set = info.Method[setName]
							else
								-- Generate getMethod
								local gbody = CACHE_TABLE()
								local upValues = CACHE_TABLE()

								tinsert(upValues, field) tinsert(gbody, "field")
								if prop.GetClone then tinsert(upValues, CloneObj) tinsert(gbody, "CloneObj") end
								if prop.DefaultFunc then tinsert(upValues, prop.DefaultFunc) tinsert(gbody, "defaultFunc") end
								if prop.Default ~= nil then tinsert(upValues, prop.Default) tinsert(gbody, "default") end
								if prop.DefaultFunc then tinsert(upValues, name) tinsert(gbody, "propName") end

								local gHeader = "local " .. tblconcat(gbody, ", ") .. " = ..."
								wipe(gbody)
								tinsert(gbody, gHeader)

								tinsert(gbody, [[return function (self)]])
								tinsert(gbody, [[local value]])
								if prop.SetWeak then
									tinsert(gbody, [[value = rawget(self, "__WeakFields")]])
									tinsert(gbody, [[if type(value) == "table" then]])
									tinsert(gbody, [[value = value[field] ]])
									tinsert(gbody, [[else]])
									tinsert(gbody, [[value = nil]])
									tinsert(gbody, [[end]])
								else
									tinsert(gbody, [[value = rawget(self, field)]])
								end
								if prop.DefaultFunc then
									tinsert(gbody, [[if value == nil then]])
									tinsert(gbody, [[	value = defaultFunc(self)]])
									tinsert(gbody, [[	if value ~= nil then self[propName] = value end]])
									tinsert(gbody, [[end]])
								elseif prop.Default ~= nil then
									tinsert(gbody, [[if value == nil then value = default end]])
								end
								if prop.GetClone then
									if prop.GetDeepClone then
										tinsert(gbody, [[value = CloneObj(value, true)]])
									else
										tinsert(gbody, [[value = CloneObj(value)]])
									end
								end
								tinsert(gbody, [[return value]])
								tinsert(gbody, [[end]])

								info.Method[getName] = loadstring(tblconcat(gbody, "\n"))(unpack(upValues))

								-- Generate setMethod
								wipe(gbody)
								wipe(upValues)

								if prop.Type then
									tinsert(upValues, Validate4Type) tinsert(gbody, "Validate4Type")
									tinsert(upValues, prop.Type) tinsert(gbody, "pType")
								end
								if prop.SetRetain then tinsert(upValues, DisposeObject) tinsert(gbody, "DisposeObject") end
								if prop.SetClone then tinsert(upValues, CloneObj) tinsert(gbody, "CloneObj") end
								if prop.SetWeak then tinsert(upValues, WEAK_VALUE) tinsert(gbody, "WEAK_VALUE") end
								tinsert(upValues, field) tinsert(gbody, "field")
								if prop.Default ~= nil then tinsert(upValues, prop.Default) tinsert(gbody, "default") end
								if prop.Handler then tinsert(upValues, prop.Handler) tinsert(gbody, "handler") end
								if prop.Event then tinsert(upValues, prop.Event) tinsert(gbody, "evt") end

								gHeader = "local " .. tblconcat(gbody, ", ") .. " = ..."
								wipe(gbody)
								tinsert(gbody, gHeader)

								tinsert(gbody, [[return function (self, value)]])
								if prop.Type then tinsert(gbody, ([[value = Validate4Type(pType, value, "%s", "%s", 2)]]):format(name, name)) end
								if prop.SetClone then
									if prop.SetDeepClone then
										tinsert(gbody, [[value = CloneObj(value, true)]])
									else
										tinsert(gbody, [[value = CloneObj(value)]])
									end
								end
								tinsert(gbody, [[local container = self]])
								if prop.SetWeak then
									tinsert(gbody, [[container = rawget(self, "__WeakFields")]])
									tinsert(gbody, [[if type(container) ~= "table" then]])
									tinsert(gbody, [[	container = setmetatable({}, WEAK_VALUE)]])
									tinsert(gbody, [[	rawset(self, "__WeakFields", container)]])
									tinsert(gbody, [[end]])
								end
								tinsert(gbody, [[local old = rawget(container, field)]])
								if prop.Default ~= nil then tinsert(gbody, [[if old == nil then old = default end]]) end
								tinsert(gbody, [[if old == value then return end]])
								tinsert(gbody, [[rawset(container, field, value)]])
								if prop.SetRetain then
									if prop.Default ~= nil then
										tinsert(gbody, [[if type(old) == "table" and getmetatable(old) and old ~= default then]])
									else
										tinsert(gbody, [[if type(old) == "table" and getmetatable(old) then]])
									end
									tinsert(gbody, [[DisposeObject(old)]])
									tinsert(gbody, [[old = nil]])
									tinsert(gbody, [[end]])
								end
								if prop.Handler then tinsert(gbody, ([[handler(self, value, old, "%s")]]):format(name)) end
								if prop.Event then tinsert(gbody, ([[return evt(self, value, old, "%s")]]):format(name)) end
								tinsert(gbody, [[end]])

								info.Method[setName] = loadstring(tblconcat(gbody, "\n"))(unpack(upValues))

								CACHE_TABLE(gbody)
								CACHE_TABLE(upValues)

								iCache[getName] = info.Method[getName]
								iCache[setName] = info.Method[setName]

								prop.GetMethod = getName
								prop.SetMethod = setName
							end
						else
							prop.Field = field
						end
					end

					-- Auto generate Default
					if prop.Type and prop.Default == nil then
						local pinfo = _NSInfo[prop.Type]

						if pinfo and (pinfo.Type == TYPE_STRUCT or pinfo.Type == TYPE_ENUM) then prop.Default = pinfo.Default end
					end
				end
			end
			--- self property
			CloneWithOverride(iCache, info.Property, true)

			-- Requires
			if info.Type == TYPE_INTERFACE then
				if info.ExtendInterface then
					for _, IF in ipairs(info.ExtendInterface) do
						if _NSInfo[IF].Requires and next(_NSInfo[IF].Requires) then
							info.Requires = info.Requires or {}
							CloneWithoutOverride(info.Requires, _NSInfo[IF].Requires)
						end
					end
				end
			end

			-- AutoCache
			if info.SuperClass and _NSInfo[info.SuperClass].AutoCache == true then
				info.AutoCache = true
			elseif info.AutoCache ~= true and info.Type == TYPE_CLASS then
				local cache = CACHE_TABLE()

				if info.SuperClass and _NSInfo[info.SuperClass].AutoCache then
					tinsert(cache, _NSInfo[info.SuperClass].AutoCache)
				end

				if info.ExtendInterface then
					for _, IF in ipairs(info.ExtendInterface) do
						if _NSInfo[IF].AutoCache == true then
							tinsert(cache, _NSInfo[IF].Method)
						elseif _NSInfo[IF].AutoCache then
							tinsert(cache, _NSInfo[IF].AutoCache)
						end
					end
				end

				if #cache > 0 then
					local autoCache = info.AutoCache or {}

					-- Clear if static
					if staticMethod then
						for name in pairs(autoCache) do if staticMethod[name] then autoCache[name] = nil end end
						for _, sCache in ipairs(cache) do for name in pairs(sCache) do if not staticMethod[name] then autoCache[name] = true end end end
					else
						for _, sCache in ipairs(cache) do for name in pairs(sCache) do autoCache[name] = true end end
					end

					if next(autoCache) then info.AutoCache = autoCache end
				end

				CACHE_TABLE(cache)
			end

			-- Refresh branch
			if info.ChildClass then
				for _, subcls in ipairs(info.ChildClass) do RefreshCache(subcls) end
			elseif info.ExtendClass then
				for _, subcls in ipairs(info.ExtendClass) do RefreshCache(subcls) end
			end
		end
	end

	-- metatable for interface's env
	_MetaIFEnv = { __metatable = true }
	_MetaIFDefEnv = {}
	do
		_MetaIFEnv.__index = function(self, key)
			local info = _NSInfo[self[OWNER_FIELD]]
			local value

			-- Check owner
			if key == info.Name then return info.Owner end

			-- Check keywords
			value = _KeyWord4IFEnv:GetKeyword(self, key)
			if value then return value end

			-- Check namespace
			if info.NameSpace then
				if key == _NSInfo[info.NameSpace].Name then
					value = info.NameSpace
					rawset(self, key, value)
					return value
				elseif info.NameSpace[key] then
					value = info.NameSpace[key]
					rawset(self, key, value)
					return value
				end
			end

			-- Check imports
			if info.Import4Env then
				for _, ns in ipairs(info.Import4Env) do
					if key == _NSInfo[ns].Name then
						value = ns
						rawset(self, key, value)
						return value
					elseif ns[key] then
						value = ns[key]
						rawset(self, key, value)
						return value
					end
				end
			end

			-- Check base namespace
			value = GetNameSpace(GetDefaultNameSpace(), key)
			if value then rawset(self, key, value) return value end

			-- Check method, so definition environment can use existed method
			-- created by another definition environment for the same interface
			value = info.Method[key]
			if value then rawset(self, key, value) return value end

			-- Check event
			value = info.Event[key]
			if value then rawset(self, key, value) return value end

			-- Check Local
			if rawget(self, LOCAL_ENV_FIELD) then
				value = self[LOCAL_ENV_FIELD][key]
				if value then rawset(self, key, value) return value end
			end

			-- Check Base
			value = self[BASE_ENV_FIELD][key]
			if value ~= nil then rawset(self, key, value) return value end
		end

		-- Don't cache item in definition to reduce some one time access feature
		_MetaIFDefEnv.__index = function(self, key)
			local info = _NSInfo[self[OWNER_FIELD]]
			local value

			-- Check owner
			if key == info.Name then return info.Owner end

			-- Check local
			if key == LOCAL_ENV_FIELD then local ret = {} rawset(self, key, ret) return ret end

			-- Check keywords
			value = _KeyWord4IFEnv:GetKeyword(self, key)
			if value then return value end

			-- Check namespace
			if info.NameSpace then
				if key == _NSInfo[info.NameSpace].Name then
					return info.NameSpace
				elseif info.NameSpace[key] then
					return info.NameSpace[key]
				end
			end

			-- Check imports
			if info.Import4Env then
				for _, ns in ipairs(info.Import4Env) do
					if key == _NSInfo[ns].Name then
						return ns
					elseif ns[key] then
						return ns[key]
					end
				end
			end

			-- Check base namespace
			value = GetNameSpace(GetDefaultNameSpace(), key)
			if value then return value end

			-- Check method, so definition environment can use existed method
			-- created by another definition environment for the same interface
			value = info.Method[key]
			if value then return value end

			-- Check event
			value = info.Event[key]
			if value then return value end

			-- Check Local
			if rawget(self, LOCAL_ENV_FIELD) then
				value = self[LOCAL_ENV_FIELD][key]
				if value then return value end
			end

			-- Check Base
			return self[BASE_ENV_FIELD][key]
		end

		_MetaIFDefEnv.__newindex = function(self, key, value)
			local info = _NSInfo[self[OWNER_FIELD]]

			if _KeyWord4IFEnv:GetKeyword(self, key) then error(("'%s' is a keyword."):format(key), 2) end

			if key == info.Name then
				-- No attribute for the initializer
				if type(value) == "function" then
					info.Initializer = value
					return
				else
					error(("'%s' must be a function as the Initializer."):format(key), 2)
				end
			end

			if key == DISPOSE_METHOD then
				if type(value) == "function" then
					info[DISPOSE_METHOD] = value
					return
				else
					error(("'%s' must be a function as dispose method."):format(DISPOSE_METHOD), 2)
				end
			end

			if type(key) == "string" and type(value) == "function" then
				-- Don't save to environment until need it
				if IsLocal() then
					return SaveFixedMethod(self[LOCAL_ENV_FIELD], key, value, info.Owner)
				else
					if IsFinalFeature(info.Owner, key) then error(("%s.%s is final, can't be overridden."):format(tostring(info.Owner), key), 2) end
					return SaveFixedMethod(info.Method, key, value, info.Owner)
				end
			end

			rawset(self, key, value)
		end

		_MetaIFDefEnv.__call = function(self, definition)
			local ok, msg = pcall(ParseDefinition, self, definition)
			local owner = self[OWNER_FIELD]

			setfenv(2, self[BASE_ENV_FIELD])
			pcall(setmetatable, self, _MetaIFEnv)
			RefreshCache(owner)

			local info = _NSInfo[owner]
			if info.ApplyAttributes then info.ApplyAttributes() end

			return not ok and error(strtrim(msg:match(":%d+:%s*(.-)$") or msg), 2) or self
		end

		_MetaIFEnv.__call = _MetaIFDefEnv.__call
	end

	function IsExtend(IF, cls)
		if not IF or not cls or not _NSInfo[IF] or _NSInfo[IF].Type ~= TYPE_INTERFACE or not _NSInfo[cls] then return false end

		if IF == cls then return true end

		local cache = _NSInfo[cls].Cache4Interface
		if cache then for _, pIF in ipairs(cache) do if pIF == IF then return true end end end

		return false
	end

	------------------------------------
	--- Create interface in currect environment's namespace or default namespace
	------------------------------------
	function interface(env, name, depth)
		depth = tonumber(depth) or 1
		name = name or env
		local fenv = type(env) == "table" and env or getfenv(depth + 1) or _G
		local ns = not IsLocal() and (GetPrepareNameSpace() == nil and GetNameSpace4Env(fenv) or GetPrepareNameSpace()) or nil

		-- Create interface or get it
		local IF, info

		if getmetatable(name) == TYPE_NAMESPACE then
			IF = name
			info = _NSInfo[IF]

			if info and info.Type and info.Type ~= TYPE_INTERFACE then
				error(("%s is existed as %s, not interface."):format(tostring(name), tostring(info.Type)), depth + 1)
			end

			name = info.Name
			ns = nil
		else
			if type(name) ~= "string" or not name:match("^[_%w]+$") then error([[Usage: interface "interfacename"]], depth + 1) end

			if ns then
				IF = BuildNameSpace(ns, name)
				info = _NSInfo[IF]

				if info and info.Type and info.Type ~= TYPE_INTERFACE then
					error(("%s is existed as %s, not interface."):format(name, tostring(info.Type)), depth + 1)
				end
			else
				IF = fenv[name]
				info = IF and _NSInfo[IF]

				if not (info and info.NameSpace == nil and info.Type == TYPE_INTERFACE ) then
					IF = BuildNameSpace(nil, name)
					info = nil
				end
			end
		end

		if not IF then error("No interface is created.", depth + 1) end

		-- Build interface
		info = info or _NSInfo[IF]

		-- Check if the class is final
		if info.IsSealed then error("The interface is final, can't be re-defined.", depth + 1) end

		info.Type = TYPE_INTERFACE
		info.NameSpace = info.NameSpace or ns
		info.Event = info.Event or {}
		info.Property = info.Property or {}
		info.Method = info.Method or {}

		-- Cache
		info.Cache = info.Cache or {}

		-- save interface to the environment
		rawset(fenv, name, IF)

		-- Generate the interface environment
		local interfaceEnv = setmetatable({
			[OWNER_FIELD] = IF,
			[BASE_ENV_FIELD] = fenv,
		}, _MetaIFDefEnv)

		-- Set namespace
		SetNameSpace4Env(interfaceEnv, IF)

		-- No super target for interface
		if ATTRIBUTE_INSTALLED then ConsumePreparedAttributes(info.Owner, AttributeTargets.Interface) end

		-- Set the environment to interface's environment
		setfenv(depth + 1, interfaceEnv)

		return interfaceEnv
	end

	------------------------------------
	--- Set the current interface' extended interface
	------------------------------------
	function extend_Inner(info, IF)
		local IFInfo = _NSInfo[IF]

		if not IFInfo or IFInfo.Type ~= TYPE_INTERFACE then
			error("Usage: extend (interface) : 'interface' - interface expected", 3)
		elseif IFInfo.IsFinal then
			error(("%s is non-inheritable."):format(tostring(IF)), 3)
		end

		if info.Type == TYPE_CLASS and IFInfo.Requires and next(IFInfo.Requires) then
			local pass = false

			for prototype in pairs(IFInfo.Requires) do
				if _NSInfo[prototype].Type == TYPE_INTERFACE then
					if IsExtend(prototype, info.Owner) then
						pass = true
						break
					end
				elseif _NSInfo[prototype].Type == TYPE_CLASS then
					if IsChildClass(prototype, info.Owner) then
						pass = true
						break
					end
				end
			end

			if not pass then
				local desc

				for prototype in pairs(IFInfo.Requires) do desc = desc and (desc .. "|" .. tostring(prototype)) or tostring(prototype) end

				error(("Usage: extend (%s) : %s should be sub-class of %s."):format(tostring(IF), tostring(info.Owner), desc), 3)
			end
		elseif info.Type == TYPE_INTERFACE and IsExtend(info.Owner, IF) then
			error(("%s is extended from %s, can't be used here."):format(tostring(IF), tostring(info.Owner)), 3)
		end


		info.ExtendInterface = info.ExtendInterface or {}

		-- Check if IF is already extend by extend tree
		for _, pIF in ipairs(info.ExtendInterface) do if IsExtend(IF, pIF) then return end end

		local owner = info.Owner
		for i = #(info.ExtendInterface), 1, -1 do
			local pIF = info.ExtendInterface[i]
			if IsExtend(pIF, IF) then
				local pExtend = _NSInfo[pIF].ExtendClass
				for j, v in ipairs(pExtend) do
					if v == owner then
						tremove(pExtend, j)
						break
					end
				end
				tremove(info.ExtendInterface, i)
			end
		end

		IFInfo.ExtendClass = IFInfo.ExtendClass or {}
		tinsert(IFInfo.ExtendClass, owner)

		tinsert(info.ExtendInterface, IF)
	end

	function extend_IF(env, name)
		if name and type(name) ~= "string" and not IsNameSpace(name) then error([[Usage: extend "namespace.interfacename"]], 2) end

		if type(name) == "string" and name:find("%.%s*%.") then error("The namespace 's name can't have empty string between dots.", 2) end

		local info = _NSInfo[env[OWNER_FIELD]]
		local IF

		if type(name) == "string" then
			IF = GetNameSpace(info.NameSpace, name) or env[name]

			if not IF then
				for subname in name:gmatch("[_%w]+") do
					IF = IF and IF[subname] or env[subname]

					if not IsNameSpace(IF) then
						error(("No interface is found with the name : %s"):format(name), 2)
					end
				end
			end
		else
			IF = name
		end

		extend_Inner(info, IF)

		return _KeyWord4IFEnv:GetKeyword(env, "extend")
	end

	------------------------------------
	--- import classes from the given name's namespace to the current environment
	------------------------------------
	function import_IF(env, name)
		if type(name) ~= "string" and not IsNameSpace(name) then error([[Usage: import "namespaceA.namespaceB"]], 2) end

		if type(name) == "string" and name:find("%.%s*%.") then error("The namespace 's name can't have empty string between dots.", 2) end

		local info = _NSInfo[env[OWNER_FIELD]]
		local ns

		if type(name) == "string" then
			ns = GetNameSpace(GetDefaultNameSpace(), name)
		elseif IsNameSpace(name) then
			ns = name
		end

		if not ns then error(("No namespace is found with name : %s"):format(name), 2) end

		info.Import4Env = info.Import4Env or {}

		for _, v in ipairs(info.Import4Env) do if v == ns then return end end

		tinsert(info.Import4Env, ns)
	end

	------------------------------------
	--- Add an event for current interface
	------------------------------------
	function event_IF(env, name)
		if type(name) ~= "string" or not name:match("^[_%w]+$") then
			error([[Usage: event "eventName"]], 2)
		end

		local info = _NSInfo[env[OWNER_FIELD]]

		info.Event[name] = info.Event[name] or Event(name)

		return ATTRIBUTE_INSTALLED and ConsumePreparedAttributes(info.Event[name], AttributeTargets.Event, info.Owner, name)
	end

	function SetPropertyWithSet(info, name, set)
		if type(set) ~= "table" then error([=[Usage: property "Name" { -- Property Definition }]=], 2) end

		local prop = info.Property[name] or {}
		info.Property[name] = prop

		wipe(prop)

		prop.Name = name
		prop.Predefined = set

		return ATTRIBUTE_INSTALLED and ConsumePreparedAttributes(prop, AttributeTargets.Property, info.Owner, name)
	end

	------------------------------------
	--- set a propert to the current interface
	------------------------------------
	function property_IF(env, name)
		if type(name) ~= "string" or strtrim(name:match("[_%w]+")) == "" then error([=[Usage: property "Name" { -- Property Definition }]=], 2) end

		return function(set) return SetPropertyWithSet(_NSInfo[env[OWNER_FIELD]], name:match("[_%w]+"), set) end
	end

	------------------------------------
	--- End the interface's definition and restore the environment
	------------------------------------
	function endinterface(env, name)
		if ATTRIBUTE_INSTALLED then ClearPreparedAttributes() end

		local info = _NSInfo[env[OWNER_FIELD]]

		if info.Name == name or info.Owner == name then
			setmetatable(env, _MetaIFEnv)
			setfenv(3, env[BASE_ENV_FIELD])
			RefreshCache(info.Owner)
			if info.ApplyAttributes then info.ApplyAttributes() end
			return env[BASE_ENV_FIELD]
		else
			error(("%s is not closed."):format(info.Name), 3)
		end
	end

	function require_IF(env, name)
		if name and type(name) ~= "string" and not IsNameSpace(name) then error([[Usage: require "namespace.interfacename|classname"]], 2) end

		if type(name) == "string" and name:find("%.%s*%.") then error("The namespace's name can't have empty string between dots.", 2) end

		local info = _NSInfo[env[OWNER_FIELD]]
		local IF

		if type(name) == "string" then
			IF = GetNameSpace(info.NameSpace, name) or env[name]

			if not IF then
				for subname in name:gmatch("[_%w]+") do
					IF = IF and IF[subname] or env[subname]

					if not IsNameSpace(IF) then error(("No interface|class is found with the name : %s"):format(name), 2) end
				end
			end
		else
			IF = name
		end

		local IFInfo = _NSInfo[IF]

		if not IFInfo or (IFInfo.Type ~= TYPE_INTERFACE and IFInfo.Type ~= TYPE_CLASS) then
			error("Usage: require (interface|class) : interface or class expected", 2)
		elseif IFInfo.IsFinal then
			error(("%s is non-inheritable."):format(tostring(IF)), 2)
		end

		info.Requires = info.Requires or {}
		info.Requires[IF] = true

		return require_IF
	end

	function ParseDefinition(self, definition)
		local info = _NSInfo[self[OWNER_FIELD]]

		if type(definition) == "table" then
			for i = 0, #definition do
				local v = definition[i]

				if getmetatable(v) == TYPE_NAMESPACE then
					if info.IsSealed then error(("%s is sealed, can't use inherit or extend."):format(tostring(info.Owner)), 2) end

					local vType = _NSInfo[v].Type

					if vType == TYPE_CLASS then
						if info.Type == TYPE_CLASS then
							inherit_Inner(info, v)
						else
							error(("%s can't have a super class"):format(info.Owner), 2)
						end
					elseif vType == TYPE_INTERFACE then
						extend_Inner(info, v)
					end
				elseif type(v) == "string" and not tonumber(v) then
					if info.IsSealed and info.Cache[v] then error(("%s.%s is sealed, can't be overridden."):format(tostring(info.Owner), v), 2) end
					info.Event[v] = info.Event[v] or Event(v)
				elseif type(v) == "function" then
					if info.IsSealed then error(("%s is sealed, can't set the constructor or initializer."):format(tostring(info.Owner)), 2) end
					if info.Type == TYPE_CLASS then
						SaveFixedMethod(info, "Constructor", v, info.Owner, AttributeTargets and AttributeTargets.Constructor or nil)
					elseif info.Type == TYPE_INTERFACE then
						info.Initializer = v
					end
				end
			end

			for k, v in pairs(definition) do
				if type(k) == "string" and not tonumber(k) then
					if IsFinalFeature(info.Owner, k) then error(("%s.%s is final, can't be overridden."):format(tostring(info.Owner), k), 2) end
					if info.IsSealed and (info.Cache[k] or k == info.Name or k == DISPOSE_METHOD or (_KeyMeta[k] ~= nil and info.Type == TYPE_CLASS)) then error(("%s.%s is sealed, can't be overridden."):format(tostring(info.Owner), k), 2) end

					local vType = getmetatable(v)

					if vType and type(v) ~= "string" then
						if vType == TYPE_NAMESPACE then
							SetPropertyWithSet(info, k, { Type = v })
						end
					elseif type(v) == "table" then
						SetPropertyWithSet(info, k, v)
					elseif type(v) == "function" then
						if k == info.Name then
							if info.Type == TYPE_CLASS then
								SaveFixedMethod(info, "Constructor", v, info.Owner, AttributeTargets and AttributeTargets.Constructor or nil)
							elseif info.Type == TYPE_INTERFACE then
								info.Initializer = v
							end
						elseif k == DISPOSE_METHOD then
							info[DISPOSE_METHOD] = v
						elseif _KeyMeta[k] ~= nil and info.Type == TYPE_CLASS then
							local rMeta = _KeyMeta[k] and k or "_"..k
							local oldValue = info.MetaTable["0" .. rMeta] or info.MetaTable[rMeta]

							SaveFixedMethod(info.MetaTable, rMeta, v, info.Owner)

							UpdateMeta4Children(rMeta, info.ChildClass, oldValue, info.MetaTable["0" .. rMeta] or info.MetaTable[rMeta])
						else
							SaveFixedMethod(info.Method, k, v, info.Owner)
						end
					else
						info.Event[k] = info.Event[k] or Event(k)
					end
				end
			end
		else
			if type(definition) == "string" then
				local errorMsg
				definition, errorMsg = loadstring("return function(_ENV) " .. definition .. " end")
				if definition then
					definition = definition()
				else
					error(errorMsg, 2)
				end
			end

			if type(definition) == "function" then
				setfenv(definition, self)
				return definition(self)
			end
		end
	end

	_KeyWord4IFEnv.extend = extend_IF
	_KeyWord4IFEnv.import = import_IF
	_KeyWord4IFEnv.event = event_IF
	_KeyWord4IFEnv.property = property_IF
	_KeyWord4IFEnv.endinterface = endinterface
	_KeyWord4IFEnv.require = require_IF

	_KeyWord4IFEnv.doc = document
end

------------------------------------------------------
-- Class
------------------------------------------------------
do
	_SuperIndex = "Super"
	_ThisIndex = "This"

	_KeyWord4ClsEnv = _KeywordAccessor()

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
		__gc = true,		-- dispose a
		__tostring = true,	-- tostring(a)
		__exist = true,		-- ClassName(...)	-- return object if existed
		__idiv = true,		-- // floor division
		__band = true,		-- & bitwise and
		__bor = true,		-- | bitwise or
		__bxor = true,		-- ~ bitwise exclusive or
		__bnot = true,		-- ~ bitwise unary not
		__shl = true,		-- << bitwise left shift
		__shr = true,		-- >> bitwise right shift
	}

	--------------------------------------------------
	-- Init & Dispose System
	--------------------------------------------------
	do
		function InitObjectWithInterface(cls, obj)
			local ok, msg, info
			local cache = _NSInfo[cls].Cache4Interface
			if cache then
				for _, IF in ipairs(cache) do
					info = _NSInfo[IF]
					if info.Initializer then
						ok, msg = pcall(info.Initializer, obj)

						if not ok then errorhandler(msg) end
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
			local info, disfunc

			info = objCls and _NSInfo[objCls]

			if not info then return end

			-- No dispose to a unique object
			if info.UniqueObject then return end

			local cache = info.Cache4Interface
			if cache then
				for i = #(cache), 1, -1 do
					disfunc = _NSInfo[cache[i]][DISPOSE_METHOD]

					if disfunc then pcall(disfunc, self) end
				end
			end

			-- Call Class Dispose
			while objCls and _NSInfo[objCls] do
				disfunc = _NSInfo[objCls][DISPOSE_METHOD]

				if disfunc then pcall(disfunc, self) end

				objCls = _NSInfo[objCls].SuperClass
			end

			-- Clear the table
			wipe(self)
			rawset(self, "Disposed", true)
		end
	end

	-- metatable for class's env
	_MetaClsEnv = { __metatable = true }
	_MetaClsDefEnv = {}
	do
		_MetaClsEnv.__index = function(self, key)
			local info = _NSInfo[self[OWNER_FIELD]]
			local value

			-- Check owner
			if key == info.Name then return info.Owner end

			if key == _SuperIndex then
				if info.SuperClass then
					local superInfo = _NSInfo[info.SuperClass]
					value = superInfo.SuperAlias

					if not value then
						-- Generate super alias when need
						superInfo.SuperAlias = newproxy(_SuperAlias)
						_SuperMap[superInfo.SuperAlias] = superInfo

						value = superInfo.SuperAlias
					end

					rawset(self, _SuperIndex, value)
					return value
				else
					error("No super class for the class.", 2)
				end
			end

			if key == _ThisIndex then
				value = info.SuperAlias

				if not value then
					-- Generate super alias when need
					info.SuperAlias = newproxy(_SuperAlias)
					_SuperMap[info.SuperAlias] = info

					value = info.SuperAlias
				end

				rawset(self, _ThisIndex, value)
				return value
			end

			-- Check keywords
			value = _KeyWord4ClsEnv:GetKeyword(self, key)
			if value then return value end

			-- Check namespace
			if info.NameSpace then
				if key == _NSInfo[info.NameSpace].Name then
					value = info.NameSpace
					rawset(self, key, value)
					return value
				elseif info.NameSpace[key] then
					value = info.NameSpace[key]
					rawset(self, key, value)
					return value
				end
			end

			-- Check imports
			if info.Import4Env then
				for _, ns in ipairs(info.Import4Env) do
					if key == _NSInfo[ns].Name then
						value = ns
						rawset(self, key, value)
						return value
					elseif ns[key] then
						value = ns[key]
						rawset(self, key, value)
						return value
					end
				end
			end

			-- Check base namespace
			value = GetNameSpace(GetDefaultNameSpace(), key)
			if value then rawset(self, key, value) return value end

			-- Check method, so definition environment can use existed method
			-- created by another definition environment for the same class
			value = info.Method[key]
			if value then rawset(self, key, value) return value end

			-- Check event
			value = info.Event[key]
			if value then rawset(self, key, value) return value end

			-- Check Local
			if rawget(self, LOCAL_ENV_FIELD) then
				value = self[LOCAL_ENV_FIELD][key]
				if value then rawset(self, key, value) return value end
			end

			-- Check meta-methods
			if _KeyMeta[key] ~= nil then
				local rMeta = _KeyMeta[key] and key or "_"..key
				value = info.MetaTable["0" .. rMeta] or info.MetaTable[rMeta]
				if value then rawset(self, key, value) return value end
			end

			-- Check Base
			value = self[BASE_ENV_FIELD][key]
			if value ~= nil then rawset(self, key, value) return value end
		end

		_MetaClsDefEnv.__index = function(self, key)
			local info = _NSInfo[self[OWNER_FIELD]]
			local value

			-- Check owner
			if key == info.Name then return info.Owner end

			-- Check local
			if key == LOCAL_ENV_FIELD then local ret = {} rawset(self, key, ret) return ret end

			if key == _SuperIndex then
				if info.SuperClass then
					local superInfo = _NSInfo[info.SuperClass]
					value = superInfo.SuperAlias

					if not value then
						-- Generate super alias when need
						superInfo.SuperAlias = newproxy(_SuperAlias)
						_SuperMap[superInfo.SuperAlias] = superInfo

						value = superInfo.SuperAlias
					end

					rawset(self, _SuperIndex, value)
					return value
				else
					error("No super class for the class.", 2)
				end
			end

			if key == _ThisIndex then
				value = info.SuperAlias

				if not value then
					-- Generate super alias when need
					info.SuperAlias = newproxy(_SuperAlias)
					_SuperMap[info.SuperAlias] = info

					value = info.SuperAlias
				end

				rawset(self, _ThisIndex, value)
				return value
			end

			-- Check keywords
			value = _KeyWord4ClsEnv:GetKeyword(self, key)
			if value then return value end

			-- Check namespace
			if info.NameSpace then
				if key == _NSInfo[info.NameSpace].Name then
					return info.NameSpace
				elseif info.NameSpace[key] then
					return info.NameSpace[key]
				end
			end

			-- Check imports
			if info.Import4Env then
				for _, ns in ipairs(info.Import4Env) do
					if key == _NSInfo[ns].Name then
						return ns
					elseif ns[key] then
						return ns[key]
					end
				end
			end

			-- Check base namespace
			value = GetNameSpace(GetDefaultNameSpace(), key)
			if value then return value end

			-- Check method, so definition environment can use existed method
			-- created by another definition environment for the same class
			value = info.Method[key]
			if value then return value end

			-- Check event
			value = info.Event[key]
			if value then return value end

			-- Check Local
			if rawget(self, LOCAL_ENV_FIELD) then
				value = self[LOCAL_ENV_FIELD][key]
				if value then return value end
			end

			-- Check meta-methods
			if _KeyMeta[key] ~= nil then
				local rMeta = _KeyMeta[key] and key or "_"..key
				value = info.MetaTable["0" .. rMeta] or info.MetaTable[rMeta]
				if value then return value end
			end

			-- Check Base
			return self[BASE_ENV_FIELD][key]
		end

		_MetaClsDefEnv.__newindex = function(self, key, value)
			local info = _NSInfo[self[OWNER_FIELD]]

			if _KeyWord4ClsEnv:GetKeyword(self, key) then error(("'%s' is a keyword."):format(key), 2) end

			if key == info.Name then
				if type(value) == "function" then
					return SaveFixedMethod(info, "Constructor", value, info.Owner, AttributeTargets and AttributeTargets.Constructor or nil)
				else
					error(("'%s' must be a function as constructor."):format(key), 2)
				end
			end

			if key == DISPOSE_METHOD then
				if type(value) == "function" then
					info[DISPOSE_METHOD] = value
					return
				else
					error(("'%s' must be a function as dispose method."):format(DISPOSE_METHOD), 2)
				end
			end

			if _KeyMeta[key] ~= nil then
				if type(value) == "function" then
					local rMeta = _KeyMeta[key] and key or "_"..key
					local oldValue = info.MetaTable["0" .. rMeta] or info.MetaTable[rMeta]

					SaveFixedMethod(info.MetaTable, rMeta, value, info.Owner)

					return UpdateMeta4Children(rMeta, info.ChildClass, oldValue, info.MetaTable["0" .. rMeta] or info.MetaTable[rMeta])
				else
					error(("'%s' must be a function."):format(key), 2)
				end
			end

			if type(key) == "string" and type(value) == "function" then
				-- Don't save to environment until need it
				if IsLocal() then
					return SaveFixedMethod(self[LOCAL_ENV_FIELD], key, value, info.Owner)
				else
					if IsFinalFeature(info.Owner, key) then error(("%s.%s is final, can't be overridden."):format(tostring(info.Owner), key), 2) end
					return SaveFixedMethod(info.Method, key, value, info.Owner)
				end
			end

			rawset(self, key, value)
		end

		_MetaClsDefEnv.__call = function(self, definition)
			local ok, msg = pcall(ParseDefinition, self, definition)
			local owner = self[OWNER_FIELD]

			setfenv(2, self[BASE_ENV_FIELD])
			pcall(setmetatable, self, _MetaClsEnv)
			RefreshCache(owner)
			local info = _NSInfo[owner]
			if info.ApplyAttributes then info.ApplyAttributes() end

			-- Validate the interface
			if info.ExtendInterface then
				local cache = CACHE_TABLE()
				local cacheIF = CACHE_TABLE()
				local ret

				for _, IF in ipairs(info.ExtendInterface) do
					local sinfo = _NSInfo[IF]
					local msg

					wipe(cacheIF)

					if sinfo.RequireMethod then
						for name in pairs(sinfo.RequireMethod) do
							if sinfo.Method[name] == info.Cache[name] then tinsert(cacheIF, name) end
						end

						if #cacheIF > 0 then msg = "[Method]" .. tblconcat(cacheIF, ", ") end
					end

					wipe(cacheIF)

					if sinfo.RequireProperty then
						for name in pairs(sinfo.RequireProperty) do
							if sinfo.Property[name] == info.Cache[name] then tinsert(cacheIF, name) end
						end

						if #cacheIF > 0 then
							msg = msg and (msg .. " ") or ""
							msg = msg .. "[Property]" .. tblconcat(cacheIF, ", ")
						end
					end

					if msg then tinsert(cache, tostring(IF) .. " - " .. msg) end
				end

				if #cache > 0 then
					tinsert(cache, 1, tostring(info.Owner) .. " lack declaration of :")
					ret = tblconcat(cache, "\n")
				end

				CACHE_TABLE(cacheIF)
				CACHE_TABLE(cache)

				if ret then error(ret, 3) end
			end

			return not ok and error(strtrim(msg:match(":%d+:%s*(.-)$") or msg), 2) or self
		end

		_MetaClsEnv.__call = _MetaClsDefEnv.__call
	end

	function IsChildClass(cls, child)
		if not cls or not child or not _NSInfo[cls] or _NSInfo[cls].Type ~= TYPE_CLASS then return false end

		if cls == child then return true end

		local info = _NSInfo[child]

		if not info or info.Type ~= TYPE_CLASS then return false end

		local scls = info.SuperClass

		while scls and scls ~= cls do scls = _NSInfo[scls].SuperClass end

		return scls == cls
	end

	function UpdateMeta4Child(meta, cls, pre, now)
		if pre == now then return end

		local info = _NSInfo[cls]
		local rMeta = "0" .. meta

		if not info.MetaTable[meta] then
			-- simple clone
			SaveFixedMethod(info.MetaTable, meta, now, cls)
			UpdateMeta4Children(meta, info.ChildClass, pre, now)
		elseif not info.MetaTable[rMeta] then
			-- mean not fixed method, can't make link on it
			if info.MetaTable[meta] == pre then
				info.MetaTable[meta] = nil

				SaveFixedMethod(info.MetaTable, meta, now, cls)
				UpdateMeta4Children(meta, info.ChildClass, pre, now)
			end
		else
			-- Update the fixed method link
			local fixedMethod = info.MetaTable[rMeta]

			if fixedMethod == pre then
				info.MetaTable[rMeta] = now
				UpdateMeta4Children(meta, info.ChildClass, pre, now)
			else
				while getmetatable(fixedMethod) and fixedMethod.Owner == cls and fixedMethod.Next ~= pre do fixedMethod = fixedMethod.Next end

				if getmetatable(fixedMethod) and fixedMethod.Next == pre then fixedMethod.Next = now end
			end
		end
	end

	function UpdateMeta4Children(meta, sub, pre, now)
		if sub and pre ~= now then for _, cls in ipairs(sub) do UpdateMeta4Child(meta, cls, pre, now) end end
	end

	function Class_Index(self, key)
		local info = _NSInfo[getmetatable(self)]

		-- Dispose Method
		if key == "Dispose" then return DisposeObject end

		local Cache = info.Cache

		local oper = Cache[key]
		if oper then
			if type(oper) == "function" then
				-- Method
				if info.AutoCache == true then
					rawset(self, key, oper)
					return oper
				else
					return oper
				end
			elseif getmetatable(oper) then
				-- Event
				local evt = rawget(self, "__Events")
				if type(evt) ~= "table" then
					evt = {}
					rawset(self, "__Events", evt)
				end

				-- No more check
				if evt[key] then
					return evt[key]
				else
					local ret = EventHandler(oper, self)
					evt[key] = ret
					return ret
				end
			else
				-- Property
				local value
				local default = oper.Default

				-- Get Getter
				local operTar = oper.Get or Cache[oper.GetMethod]

				-- Get Value
				if operTar then
					if default == nil and not oper.GetClone then return operTar(self) end
					value = operTar(self)
				else
					operTar = oper.Field

					if operTar then
						if oper.SetWeak then
							value = rawget(self, "__WeakFields")
							if type(value) == "table" then
								value = value[operTar]
							else
								value = nil
							end
						else
							value = rawget(self, operTar)
						end
					elseif default == nil then
						error(("%s can't be read."):format(key),2)
					end
				end

				if value == nil then
					operTar = oper.DefaultFunc
					if operTar then
						value = operTar(self)
						if value ~= nil then
							if oper.Set == false then
								operTar = oper.Field

								-- Check container
								local container = self

								if oper.SetWeak then
									container = rawget(self, "__WeakFields")
									if type(container) ~= "table" then
										container = setmetatable({}, WEAK_VALUE)
										rawset(self, "__WeakFields", container)
									end
								end

								-- Set the value
								rawset(container, operTar, value)
							else
								self[key] = value
							end
						end
					else
						value = default
					end
				end
				if oper.GetClone then value = CloneObj(value, oper.GetDeepClone) end

				return value
			end
		end

		-- Custom index metametods
		oper = info.MetaTable.___index
		if oper then return oper(self, key) end
	end

	function Class_NewIndex(self, key, value)
		local info = _NSInfo[getmetatable(self)]
		local Cache = info.Cache
		local oper = Cache[key]

		if type(oper) == "table" then
			if getmetatable(oper) then
				-- Event
				local evt = rawget(self, "__Events")
				if type(evt) ~= "table" then
					evt = {}
					rawset(self, "__Events", evt)
				end

				if value == nil and not evt[key] then return end

				if not evt[key] then evt[key] = EventHandler(oper, self) end
				evt = evt[key]

				if value == nil or type(value) == "function" then
					evt.Handler = value
					return
				elseif type(value) == "table" then
					return evt:Copy(value)
				else
					error("Can't set this value to the event handler.", 2)
				end
			else
				-- Property
				if oper.Set == false then error(("%s can't be written."):format(key), 2) end
				if oper.Type then value = Validate4Type(oper.Type, value, key, key, 2) end
				if oper.SetClone then value = CloneObj(value, oper.SetDeepClone) end

				-- Get Setter
				local operTar = oper.Set or Cache[oper.SetMethod]

				-- Set Value
				if operTar then
					return operTar(self, value)
				else
					operTar = oper.Field

					if operTar then
						-- Check container
						local container = self
						local default = oper.Default

						if oper.SetWeak then
							container = rawget(self, "__WeakFields")
							if type(container) ~= "table" then
								container = setmetatable({}, WEAK_VALUE)
								rawset(self, "__WeakFields", container)
							end
						end

						-- Check old value
						local old = rawget(container, operTar)
						if old == nil then old = default end
						if old == value then return end

						-- Set the value
						rawset(container, operTar, value)

						-- Dispose old
						if oper.SetRetain and old and old ~= default then
							DisposeObject(old)
							old = nil
						end

						-- Call handler
						operTar = oper.Handler
						if operTar then operTar(self, value, old, key) end

						-- Fire event
						operTar = oper.Event
						if operTar then return operTar(self, value, old, key) end

						return
					else
						error(("%s can't be written."):format(key), 2)
					end
				end
			end
		end

		-- Custom newindex metametods
		oper = info.MetaTable.___newindex
		if oper then return oper(self, key, value) end

		rawset(self, key, value)
	end

	function GenerateMetatable(info)
		local Cache = info.Cache

		local meta = {}
		meta.__metatable = info.Owner
		meta.__index = SAVE_MEMORY and Class_Index or function (self, key)
			-- Dispose Method
			if key == "Dispose" then return DisposeObject end

			local oper = Cache[key]
			if oper then
				if type(oper) == "function" then
					-- Method
					if info.AutoCache == true then
						rawset(self, key, oper)
						return oper
					else
						return oper
					end
				elseif getmetatable(oper) then
					-- Event
					local evt = rawget(self, "__Events")
					if type(evt) ~= "table" then
						evt = {}
						rawset(self, "__Events", evt)
					end

					-- No more check
					if evt[key] then
						return evt[key]
					else
						local ret = EventHandler(oper, self)
						evt[key] = ret
						return ret
					end
				else
					-- Property
					local value
					local default = oper.Default

					-- Get Getter
					local operTar = oper.Get or Cache[oper.GetMethod]

					-- Get Value
					if operTar then
						if default == nil and not oper.GetClone then return operTar(self) end
						value = operTar(self)
					else
						operTar = oper.Field

						if operTar then
							if oper.SetWeak then
								value = rawget(self, "__WeakFields")
								if type(value) == "table" then
									value = value[operTar]
								else
									value = nil
								end
							else
								value = rawget(self, operTar)
							end
						elseif default == nil then
							error(("%s can't be read."):format(key),2)
						end
					end

					if value == nil then
						operTar = oper.DefaultFunc
						if operTar then
							value = operTar(self)
							if value ~= nil then
								if oper.Set == false then
									operTar = oper.Field

									-- Check container
									local container = self
									local default = oper.Default

									if oper.SetWeak then
										container = rawget(self, "__WeakFields")
										if type(container) ~= "table" then
											container = setmetatable({}, WEAK_VALUE)
											rawset(self, "__WeakFields", container)
										end
									end

									-- Set the value
									rawset(container, operTar, value)
								else
									self[key] = value
								end
							end
						else
							value = default
						end
					end
					if oper.GetClone then value = CloneObj(value, oper.GetDeepClone) end

					return value
				end
			end

			-- Custom index metametods
			oper = meta["___index"]
			if oper then return oper(self, key) end
		end

		meta.__newindex = SAVE_MEMORY and Class_NewIndex or function (self, key, value)
			local oper = Cache[key]

			if type(oper) == "table" then
				if getmetatable(oper) then
					-- Event
					local evt = rawget(self, "__Events")
					if type(evt) ~= "table" then
						evt = {}
						rawset(self, "__Events", evt)
					end

					if value == nil and not evt[key] then return end

					if not evt[key] then evt[key] = EventHandler(oper, self) end
					evt = evt[key]

					if value == nil or type(value) == "function" then
						evt.Handler = value
						return
					elseif type(value) == "table" then
						return evt:Copy(value)
					else
						error("Can't set this value to the event handler.", 2)
					end
				else
					-- Property
					if oper.Set == false then error(("%s can't be written."):format(key), 2) end
					if oper.Type then value = Validate4Type(oper.Type, value, key, key, 2) end
					if oper.SetClone then value = CloneObj(value, oper.SetDeepClone) end

					-- Get Setter
					local operTar = oper.Set or Cache[oper.SetMethod]

					-- Set Value
					if operTar then
						return operTar(self, value)
					else
						operTar = oper.Field

						if operTar then
							-- Check container
							local container = self
							local default = oper.Default

							if oper.SetWeak then
								container = rawget(self, "__WeakFields")
								if type(container) ~= "table" then
									container = setmetatable({}, WEAK_VALUE)
									rawset(self, "__WeakFields", container)
								end
							end

							-- Check old value
							local old = rawget(container, operTar)
							if old == nil then old = default end
							if old == value then return end

							-- Set the value
							rawset(container, operTar, value)

							-- Dispose old
							if oper.SetRetain and old and old ~= default then
								DisposeObject(old)
								old = nil
							end

							-- Call handler
							operTar = oper.Handler
							if operTar then operTar(self, value, old, key) end

							-- Fire event
							operTar = oper.Event
							if operTar then return operTar(self, value, old, key) end

							return
						else
							error(("%s can't be written."):format(key), 2)
						end
					end
				end
			end

			-- Custom newindex metametods
			oper = meta["___newindex"]
			if oper then return oper(self, key, value) end

			rawset(self, key, value)
		end

		return meta
	end

	-- Init the object with class's constructor
	function Class1Obj(cls, obj, ...)
		local info = _NSInfo[cls]
		local count = select('#', ...)
		local initTable = select(1, ...)

		if not ( count == 1 and type(initTable) == "table" and getmetatable(initTable) == nil ) then initTable = nil end

		while info do
			if not info.Constructor then
				info = info.SuperClass and _NSInfo[info.SuperClass]
			elseif type(info.Constructor) == "function" then
				return info.Constructor(obj, ...)
			elseif getmetatable(info.Constructor) == FixedMethod then
				local fixedMethod = info.Constructor
				local noArgMethod = nil

				while getmetatable(fixedMethod) do
					if fixedMethod.ArgCache then
						CACHE_TABLE(fixedMethod.ArgCache)
					end
					fixedMethod.ArgCache = nil

					if #fixedMethod == 0 and initTable then
						noArgMethod = noArgMethod or fixedMethod
					elseif fixedMethod:MatchArgs(obj, ...) then
						if fixedMethod.ArgCache then
							return fixedMethod.Method(unpack(fixedMethod.ArgCache))
						else
							return fixedMethod.Method(obj, ...)
						end
					elseif fixedMethod.ArgCache then
						-- Remove argument container
						CACHE_TABLE(fixedMethod.ArgCache)
						fixedMethod.ArgCache = nil
					end

					fixedMethod = fixedMethod.Next
				end

				if noArgMethod then
					-- No arguments method can still using init table
					noArgMethod.Method(obj)
					break
				end

				if type(fixedMethod) == "function" then
					return fixedMethod(obj, ...)
				else
					return info.Constructor:RaiseError(obj)
				end
			end
		end

		-- No constructor or constructor with no arguments, so try init table
		if initTable then for name, value in pairs(initTable) do obj[name] = value end end
	end

	-- The cache for constructor parameters
	function Class2Obj(cls, ...)
		local info = _NSInfo[cls]

		if info.AbstractClass then error("The class is abstract, can't be used to create objects.", 2) end

		-- Check if the class is unique and already created one object to be return
		if getmetatable(info.UniqueObject) then
			-- Init the obj with new arguments
			Class1Obj(cls, info.UniqueObject, ...)

			-- Don't think there would be interfaces for the unique class, just for safe
			InitObjectWithInterface(cls, info.UniqueObject)

			return info.UniqueObject
		end

		-- Check if this class has __exist so no need to create again.
		if info.MetaTable.__exist then
			local ok, obj = pcall(info.MetaTable.__exist, ...)

			if ok and getmetatable(obj) == cls then return obj end
		end

		-- Create new object
		local obj = setmetatable({}, info.MetaTable)

		local ok, ret = pcall(Class1Obj, cls, obj, ...)

		if not ok then DisposeObject(obj) error(ret, 2) end

		InitObjectWithInterface(cls, obj)

		-- Auto-Cache methods
		if type(info.AutoCache) == "table" then
			for name in pairs(info.AutoCache) do
				if rawget(obj, name) == nil then
					rawset(obj, name, info.Cache[name])
				end
			end
		end

		if info.UniqueObject then info.UniqueObject = obj end

		return obj
	end

	------------------------------------
	--- Create class in currect environment's namespace or default namespace
	------------------------------------
	function class(env, name, depth)
		depth = tonumber(depth) or 1
		name = name or env
		local fenv = type(env) == "table" and env or getfenv(depth + 1) or _G
		local ns = not IsLocal() and (GetPrepareNameSpace() == nil and GetNameSpace4Env(fenv) or GetPrepareNameSpace()) or nil

		-- Create class or get it
		local cls, info

		if getmetatable(name) == TYPE_NAMESPACE then
			cls = name
			info = _NSInfo[cls]

			if info and info.Type and info.Type ~= TYPE_CLASS then
				error(("%s is existed as %s, not class."):format(tostring(name), tostring(info.Type)), depth + 1)
			end

			name = info.Name
			ns = nil
		else
			if type(name) ~= "string" or not name:match("^[_%w]+$") then error([[Usage: class "classname"]], depth + 1) end

			if ns then
				cls = BuildNameSpace(ns, name)
				info = _NSInfo[cls]

				if info and info.Type and info.Type ~= TYPE_CLASS then
					error(("%s is existed as %s, not class."):format(name, tostring(info.Type)), depth + 1)
				end
			else
				cls = fenv[name]
				info = cls and _NSInfo[cls]

				if not ( info and info.NameSpace == nil and info.Type == TYPE_CLASS ) then
					cls = BuildNameSpace(nil, name)
					info = nil
				end
			end
		end

		if not cls then error("No class is created.", depth + 1) end

		-- Build class
		info = info or _NSInfo[cls]

		-- Check if the class is final
		if info.IsSealed then error("The class is final, can't be re-defined.", depth + 1) end

		info.Type = TYPE_CLASS
		info.NameSpace = info.NameSpace or ns
		info.Event = info.Event or {}
		info.Property = info.Property or {}
		info.Method = info.Method or {}

		-- Cache
		info.Cache = info.Cache or {}

		-- save class to the environment
		rawset(fenv, name, cls)

		local classEnv = setmetatable({
			[OWNER_FIELD] = cls,
			[BASE_ENV_FIELD] = fenv,
		}, _MetaClsDefEnv)

		-- Set namespace
		SetNameSpace4Env(classEnv, cls)

		-- MetaTable
		info.MetaTable = info.MetaTable or GenerateMetatable(info)

		if ATTRIBUTE_INSTALLED then ConsumePreparedAttributes(info.Owner, AttributeTargets.Class) end

		setfenv(depth + 1, classEnv)

		return classEnv
	end

	------------------------------------
	--- Set the current class' super class
	------------------------------------
	function inherit_Inner(info, superCls)
		local superInfo = _NSInfo[superCls]

		if not superInfo or superInfo.Type ~= TYPE_CLASS then error("Usage: inherit (class) : 'class' - class expected", 2) end
		if superInfo.IsFinal then error(("%s is non-inheritable."):format(tostring(superCls)), 2) end
		if IsChildClass(info.Owner, superCls) then error(("%s is inherited from %s, can't be used as super class."):format(tostring(superCls), tostring(info.Owner)), 2) end
		if info.SuperClass == superCls then return end
		if info.SuperClass then error(("%s is inherited from %s, can't inherit another class."):format(tostring(info.Owner), tostring(info.SuperClass)), 2) end

		superInfo.ChildClass = superInfo.ChildClass or {}
		tinsert(superInfo.ChildClass, info.Owner)

		info.SuperClass = superCls

		-- Keep to the environmenet
		-- rawset(env, _SuperIndex, superCls)

		-- Copy Metatable
		if ATTRIBUTE_INSTALLED then ClearPreparedAttributes() end

		for meta, flag in pairs(_KeyMeta) do
			local rMeta = flag and meta or "_" .. meta

			if superInfo.MetaTable[rMeta] then UpdateMeta4Child(rMeta, info.Owner, nil, superInfo.MetaTable["0" .. rMeta] or superInfo.MetaTable[rMeta]) end
		end

		-- Clone Attributes
		return ATTRIBUTE_INSTALLED and InheritAttributes(superCls, info.Owner, AttributeTargets.Class)
	end

	function inherit_Cls(env, name)
		if name and type(name) ~= "string" and not IsNameSpace(name) then error([[Usage: inherit "namespace.classname"]], 2) end

		local info = _NSInfo[env[OWNER_FIELD]]

		local superCls

		if type(name) == "string" then
			superCls = GetNameSpace(info.NameSpace, name) or env[name]

			if not superCls then
				for subname in name:gmatch("[_%w]+") do
					if not superCls then
						superCls = env[subname]
					else
						superCls = superCls[subname]
					end

					if not IsNameSpace(superCls) then error(("No class is found with the name : %s"):format(name), 2) end
				end
			end
		else
			superCls = name
		end

		return inherit_Inner(info, superCls)
	end

	------------------------------------
	--- Set the current class' extended interface
	------------------------------------
	function extend_Cls(env, name)
		if name and type(name) ~= "string" and not IsNameSpace(name) then error([[Usage: extend "namespace.interfacename"]], 2) end

		local info = _NSInfo[env[OWNER_FIELD]]

		local IF

		if type(name) == "string" then
			IF = GetNameSpace(info.NameSpace, name) or env[name]

			if not IF then
				for subname in name:gmatch("[_%w]+") do
					IF = IF and IF[subname] or env[subname]

					if not IsNameSpace(IF) then error(("No interface is found with the name : %s"):format(name), 2) end
				end
			end
		else
			IF = name
		end

		extend_Inner(info, IF)

		return _KeyWord4ClsEnv:GetKeyword(env, "extend")
	end

	------------------------------------
	--- import classes from the given name's namespace to the current environment
	------------------------------------
	function import_Cls(env, name)
		if type(name) ~= "string" and not IsNameSpace(name) then error([[Usage: import "namespaceA.namespaceB"]], 2) end

		local info = _NSInfo[env[OWNER_FIELD]]
		local ns

		if type(name) == "string" then
			ns = GetNameSpace(GetDefaultNameSpace(), name)
		elseif IsNameSpace(name) then
			ns = name
		end

		if not ns then error(("No namespace is found with name : %s"):format(name), 2) end

		info.Import4Env = info.Import4Env or {}

		for _, v in ipairs(info.Import4Env) do if v == ns then return end end

		tinsert(info.Import4Env, ns)
	end

	------------------------------------
	--- Add an event for current class
	------------------------------------
	function event_Cls(env, name)
		if type(name) ~= "string" or not name:match("^[_%w]+$") then error([[Usage: event "eventName"]], 2) end

		local info = _NSInfo[env[OWNER_FIELD]]

		if not info then error("can't use event here.", 2) end

		info.Event[name] = info.Event[name] or Event(name)

		return ATTRIBUTE_INSTALLED and ConsumePreparedAttributes(info.Event[name], AttributeTargets.Event, info.Owner, name)
	end

	------------------------------------
	--- set a propert to the current class
	------------------------------------
	function property_Cls(env, name)
		if type(name) ~= "string" or strtrim(name:match("[_%w]+")) == "" then error([=[Usage: property "Name" { -- Property Definition }]=], 2) end

		return function(set) return SetPropertyWithSet(_NSInfo[env[OWNER_FIELD]], name:match("[_%w]+"), set) end
	end

	------------------------------------
	--- End the class's definition and restore the environment
	------------------------------------
	function endclass(env, name)
		if ATTRIBUTE_INSTALLED then ClearPreparedAttributes() end

		local info = _NSInfo[env[OWNER_FIELD]]

		if info.Name == name or info.Owner == name then
			setmetatable(env, _MetaClsEnv)
			setfenv(3, env[BASE_ENV_FIELD])
			RefreshCache(info.Owner)
			if info.ApplyAttributes then info.ApplyAttributes() end
		else
			error(("%s is not closed."):format(info.Name), 3)
		end

		-- Validate the interface
		if info.ExtendInterface then
			local cache = CACHE_TABLE()
			local cacheIF = CACHE_TABLE()
			local ret

			for _, IF in ipairs(info.ExtendInterface) do
				local sinfo = _NSInfo[IF]
				local msg

				wipe(cacheIF)

				if sinfo.RequireMethod then
					for name in pairs(sinfo.RequireMethod) do
						if sinfo.Method[name] == info.Cache[name] then tinsert(cacheIF, name) end
					end

					if #cacheIF > 0 then msg = "[Method]" .. tblconcat(cacheIF, ", ") end
				end

				wipe(cacheIF)

				if sinfo.RequireProperty then
					for name in pairs(sinfo.RequireProperty) do
						if sinfo.Property[name] == info.Cache[name] then tinsert(cacheIF, name) end
					end

					if #cacheIF > 0 then
						msg = msg and (msg .. " ") or ""
						msg = msg .. "[Property]" .. tblconcat(cacheIF, ", ")
					end
				end

				if msg then tinsert(cache, tostring(IF) .. " - " .. msg) end
			end

			if #cache > 0 then
				tinsert(cache, 1, tostring(info.Owner) .. " lack declaration of :")
				ret = tblconcat(cache, "\n")
			end

			CACHE_TABLE(cacheIF)
			CACHE_TABLE(cache)

			if ret then error(ret, 3) end
		end

		return env[BASE_ENV_FIELD]
	end

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
				info.Enum[strupper(i)] = v
			elseif type(v) == "string" then
				info.Enum[strupper(v)] = v
			end
		end

		if ATTRIBUTE_INSTALLED then ConsumePreparedAttributes(info.Owner, AttributeTargets.Enum) end

		-- Cache
		info.Cache = info.Cache or {}
		wipe(info.Cache)
		for k, v in pairs(info.Enum) do info.Cache[v] = k end

		if info.Default ~= nil then
			local default = info.Default

			if type(default) == "string" and info.Enum[strupper(default)] then
				info.Default = info.Enum[strupper(default)]
			elseif info.Cache[default] == nil then
				info.Default = nil
			end
		end
	end

	function GetShortEnumInfo(cls)
		if _NSInfo[cls] then
			local str

			for n in pairs(_NSInfo[cls].Enum) do
				if str and #str > 30 then str = str .. " | ..." break end

				str = str and (str .. " | " .. n) or n
			end

			return str or ""
		end

		return ""
	end

	------------------------------------
	--- create a enumeration
	------------------------------------
	function enum(env, name, depth)
		depth = tonumber(depth) or 1
		name = name or env

		local fenv = type(env) == "table" and env or getfenv(depth + 1) or _G
		local ns = not IsLocal() and (GetPrepareNameSpace() == nil and GetNameSpace4Env(fenv) or GetPrepareNameSpace()) or nil

		-- Create class or get it
		local enm, info

		if getmetatable(name) == TYPE_NAMESPACE then
			enm = name
			info = _NSInfo[enm]

			if info and info.Type and info.Type ~= TYPE_ENUM then
				error(("%s is existed as %s, not enumeration."):format(tostring(name), tostring(info.Type)), depth + 1)
			end

			name = info.Name
			ns = nil
		else
			if type(name) ~= "string" or not name:match("^[_%w]+$") then
				error([[Usage: enum "enumName" {
					"enumValue1",
					"enumValue2",
				}]], depth + 1)
			end

			if ns then
				enm = BuildNameSpace(ns, name)
				info = _NSInfo[enm]

				if info and info.Type and info.Type ~= TYPE_ENUM then
					error(("%s is existed as %s, not enumeration."):format(name, tostring(info.Type)), depth + 1)
				end
			else
				enm = fenv[name]
				info = enm and _NSInfo[enm]

				if not ( info and info.NameSpace == nil and info.Type == TYPE_ENUM ) then
					enm = BuildNameSpace(nil, name)
					info = nil
				end
			end
		end

		if not enm then error("No enumeration is created.", depth + 1) end

		-- save class to the environment
		rawset(fenv, name, enm)

		-- Build enm
		info = info or _NSInfo[enm]

		-- Check if the enum is final
		if info.IsSealed then error("The enum is final, can't be re-defined.", depth + 1) end

		info.Type = TYPE_ENUM
		info.NameSpace = info.NameSpace or ns

		-- Clear Attributes
		if ATTRIBUTE_INSTALLED then
			DisposeAttributes(info.Attribute)
			info.Attribute = nil
		end

		return function(set) return BuildEnum(info, set) end
	end
end

------------------------------------------------------
-- Struct
------------------------------------------------------
do
	_KeyWord4StrtEnv = _KeywordAccessor()

	_STRUCT_TYPE_MEMBER = "MEMBER"
	_STRUCT_TYPE_ARRAY = "ARRAY"
	_STRUCT_TYPE_CUSTOM = "CUSTOM"

	-- metatable for struct's env
	_MetaStrtEnv = { __metatable = true }
	_MetaStrtDefEnv = {}
	do
		_MetaStrtEnv.__index = function(self, key)
			local info = _NSInfo[self[OWNER_FIELD]]
			local value

			-- Check owner
			if key == info.Name then return info.Owner end

			-- Check keywords
			value = _KeyWord4StrtEnv:GetKeyword(self, key)
			if value then return value end

			-- Check namespace
			if info.NameSpace then
				if key == _NSInfo[info.NameSpace].Name then
					value = info.NameSpace
					rawset(self, key, value)
					return value
				elseif info.NameSpace[key] then
					value = info.NameSpace[key]
					rawset(self, key, value)
					return value
				end
			end

			-- Check imports
			if info.Import4Env then
				for _, ns in ipairs(info.Import4Env) do
					if key == _NSInfo[ns].Name then
						value = ns
						rawset(self, key, value)
						return value
					elseif ns[key] then
						value = ns[key]
						rawset(self, key, value)
						return value
					end
				end
			end

			-- Check base namespace
			value = GetNameSpace(GetDefaultNameSpace(), key)
			if value then rawset(self, key, value) return value end

			-- Check Method
			value = info.Method and info.Method[key]
			if value then rawset(self, key, value) return value end

			-- Check Local
			if rawget(self, LOCAL_ENV_FIELD) then
				value = self[LOCAL_ENV_FIELD][key]
				if value then rawset(self, key, value) return value end
			end

			-- Check Base
			value = self[BASE_ENV_FIELD][key]
			if value ~= nil then rawset(self, key, value) return value end
		end

		_MetaStrtDefEnv.__index = function(self, key)
			local info = _NSInfo[self[OWNER_FIELD]]
			local value

			-- Check owner
			if key == info.Name then return info.Owner end

			-- Check local
			if key == LOCAL_ENV_FIELD then local ret = {} rawset(self, key, ret) return ret end

			-- Check keywords
			value = _KeyWord4StrtEnv:GetKeyword(self, key)
			if value then return value end

			-- Check namespace
			if info.NameSpace then
				if key == _NSInfo[info.NameSpace].Name then
					return info.NameSpace
				elseif info.NameSpace[key] then
					return info.NameSpace[key]
				end
			end

			-- Check imports
			if info.Import4Env then
				for _, ns in ipairs(info.Import4Env) do
					if key == _NSInfo[ns].Name then
						return ns
					elseif ns[key] then
						return ns[key]
					end
				end
			end

			-- Check base namespace
			value = GetNameSpace(GetDefaultNameSpace(), key)
			if value then return value end

			-- Check Method
			value = info.Method and info.Method[key]
			if value then return value end

			-- Check Local
			if rawget(self, LOCAL_ENV_FIELD) then
				value = self[LOCAL_ENV_FIELD][key]
				if value then return value end
			end

			-- Check Base
			return self[BASE_ENV_FIELD][key]
		end

		_MetaStrtDefEnv.__newindex = function(self, key, value)
			local info = _NSInfo[self[OWNER_FIELD]]

			if _KeyWord4StrtEnv:GetKeyword(self, key) then error(("'%s' is a keyword."):format(key), 2) end

			if key == info.Name then
				if type(value) == "function" then
					info.Validator = value
					return
				else
					error(("'%s' must be a function as the Validator."):format(key), 2)
				end
			end

			if type(key) == "string" or tonumber(key) then
				if type(value) == "function" then
					if tonumber(key) then
						info.Validator = value
						return
					elseif IsLocal() then
						return SaveFixedMethod(self[LOCAL_ENV_FIELD], key, value, info.Owner)
					else
						-- Cache the method for the struct data
						info.Method = info.Method or {}

						-- Don't save to environment until need it
						return SaveFixedMethod(info.Method, key, value, info.Owner)
					end
				elseif _NSInfo[value] and _NSInfo[value].Type then
					return SaveStructField(self, info, key, value)
				end
			end

			return rawset(self, key, value)
		end

		_MetaStrtDefEnv.__call = function(self, definition)
			local ok, msg = pcall(ParseStructDefinition, self, definition)
			local owner = self[OWNER_FIELD]

			setfenv(2, self[BASE_ENV_FIELD])
			pcall(setmetatable, self, _MetaStrtEnv)
			RefreshStruct(owner)
			local info = _NSInfo[owner]
			if info.ApplyAttributes then info.ApplyAttributes() end

			return not ok and error(strtrim(msg:match(":%d+:%s*(.-)$") or msg), 2) or self
		end

		_MetaStrtEnv.__call = _MetaStrtDefEnv.__call
	end

	-- Some struct object may ref to each others, that would crash the validation
	_ValidatedCache = setmetatable({}, WEAK_ALL)

	function ValidateStruct(strt, value)
		local info = _NSInfo[strt]

		local sType = info.SubType

		if sType ~= _STRUCT_TYPE_CUSTOM then
			if type(value) ~= "table" then wipe(_ValidatedCache) error(("%s must be a table, got %s."):format("%s", type(value))) end

			if _ValidatedCache[value] then return value end

			if not _ValidatedCache[1] then _ValidatedCache[1] = value end
			_ValidatedCache[value] = true

			if sType == _STRUCT_TYPE_MEMBER then
				if info.Members then
					local env = info.StructEnv
					local default = info.DefaultField
					local require = info.RequireMember

					for _, n in ipairs(info.Members) do
						local val = value[n]

						if val == nil then
							if default and default[n] ~= nil then
								-- Deep clone to make sure no change on default value
								value[n] = CloneObj(default[n], true)
							elseif require and require[n] then
								error(("%s.%s can't be nil."):format("%s", n))
							end
						else
							value[n] = Validate4Type(env[n], val, n)
						end
					end
				end
			elseif sType == _STRUCT_TYPE_ARRAY and info.ArrayElement then
				local flag, ret
				local ele = info.ArrayElement

				for i, v in ipairs(value) do
					flag, ret = pcall(Validate4Type, ele, v, "Element")

					if flag then
						value[i] = ret
					else
						wipe(_ValidatedCache)
						error(strtrim(ret:match(":%d+:%s*(.-)$") or ret):gsub("%%s[_%w]+", "%%s["..i.."]"))
					end
				end
			end
		end

		if type(info.Validator) == "function" then
			local flag, ret = pcall(info.Validator, value)

			if not flag then
				wipe(_ValidatedCache)
				error(strtrim(ret:match(":%d+:%s*(.-)$") or ret))
			end

			if sType == _STRUCT_TYPE_CUSTOM and ret ~= nil then value = ret end
		end

		if sType ~= _STRUCT_TYPE_CUSTOM and _ValidatedCache[1] == value then wipe(_ValidatedCache) end

		return value
	end

	function CopyStructMethods(info, obj)
		if info.Method and type(obj) == "table" then
			if info.StaticMethod then
				for k, v in pairs(info.Method) do
					if not info.StaticMethod[k] and obj[k] == nil then obj[k] = v end
				end
			else
				for k, v in pairs(info.Method) do
					if obj[k] == nil then obj[k] = v end
				end
			end
		end

		return obj
	end

	function Struct2Obj(strt, ...)
		local info = _NSInfo[strt]

		local count = select("#", ...)
		local initTable = select(1, ...)
		local initErrMsg

		if not ( count == 1 and type(initTable) == "table" and getmetatable(initTable) == nil ) then initTable = nil end

		if initTable then
			local ok, value = pcall(ValidateStruct, strt, initTable)

			if ok then return CopyStructMethods(info, value) end

			initErrMsg = value
		end

		-- Default Constructor
		if info.SubType == _STRUCT_TYPE_MEMBER then
			local ret = {}

			if info.Members then for i, n in ipairs(info.Members) do ret[n] = select(i, ...) end end

			local ok, value = pcall(ValidateStruct, strt, ret)

			if ok then
				return CopyStructMethods(info, value)
			else
				value = initErrMsg or value
				value = strtrim(value:match(":%d+:%s*(.-)$") or value)
				value = value:gsub("%%s%.", ""):gsub("%%s", "")

				local args = ""
				for i, n in ipairs(info.Members) do
					--if info.StructEnv[n]:Is(nil) and not args:find("%[") then n = "["..n end
					if i == 1 then args = n else args = args..", "..n end
				end
				--if args:find("%[") then args = args.."]" end
				error(("Usage : %s(%s) - %s"):format(tostring(strt), args, value), 3)
			end
		elseif info.SubType == _STRUCT_TYPE_ARRAY then
			local ret = {}

			for i = 1, select('#', ...) do ret[i] = select(i, ...) end

			local ok, value = pcall(ValidateStruct, strt, ret)

			if ok then
				return CopyStructMethods(info, value)
			else
				value = initErrMsg or value
				value = strtrim(value:match(":%d+:%s*(.-)$") or value)
				value = value:gsub("%%s%.", ""):gsub("%%s", "")
				error(("Usage : %s(...) - %s"):format(tostring(strt), value), 3)
			end
		else
			-- For custom struct
			local ok, value = pcall(ValidateStruct, strt, ...)

			if not ok then error(strtrim(value:match(":%d+:%s*(.-)$") or value):gsub("%%s", "[".. info.Name .."]"), 3) end

			return value
		end
	end

	------------------------------------
	--- create a structure
	------------------------------------
	function struct(env, name, depth)
		depth = tonumber(depth) or 1
		name = name or env
		local fenv = type(env) == "table" and env or getfenv(depth + 1) or _G
		local ns = not IsLocal() and (GetPrepareNameSpace() == nil and GetNameSpace4Env(fenv) or GetPrepareNameSpace()) or nil

		-- Create class or get it
		local strt, info

		if getmetatable(name) == TYPE_NAMESPACE then
			strt = name
			info = _NSInfo[strt]

			if info and info.Type and info.Type ~= TYPE_STRUCT then
				error(("%s is existed as %s, not struct."):format(tostring(name), tostring(info.Type)), depth + 1)
			end

			name = info.Name
			ns = nil
		else
			if type(name) ~= "string" or not name:match("^[_%w]+$") then error([[Usage: struct "structname"]], depth + 1) end
			if ns then
				strt = BuildNameSpace(ns, name)
				info = _NSInfo[strt]

				if info and info.Type and info.Type ~= TYPE_STRUCT then
					error(("%s is existed as %s, not struct."):format(name, tostring(info.Type)), depth + 1)
				end
			else
				strt = fenv[name]
				info = strt and _NSInfo[strt]

				if not ( info and info.NameSpace == nil and info.Type == TYPE_STRUCT ) then
					strt = BuildNameSpace(nil, name)
					info = nil
				end
			end
		end

		if not strt then error("No struct is created.", depth + 1) end

		-- save class to the environment
		rawset(fenv, name, strt)

		-- Build class
		info = info or _NSInfo[strt]

		-- Check if the struct is final
		if info.IsSealed then error("The struct is final, can't be re-defined.", depth + 1) end

		info.Type = TYPE_STRUCT
		info.SubType = _STRUCT_TYPE_MEMBER
		info.NameSpace = info.NameSpace or ns
		info.Members = nil
		info.Default = nil
		info.DefaultField = nil
		info.ArrayElement = nil
		info.Validator = nil
		info.Method = nil
		info.StaticMethod = nil
		info.Import4Env = nil

		-- Clear Attribute
		if ATTRIBUTE_INSTALLED then
			DisposeAttributes(info.Attribute)
			DisposeAttributes(info.ElementAttribute)
			DisposeAttributes(info.Attributes)

			info.Attribute = nil
			info.ElementAttribute = nil
			info.Attributes = nil
		end

		info.StructEnv = setmetatable({
			[OWNER_FIELD] = strt,
			[BASE_ENV_FIELD] = fenv,
		}, _MetaStrtDefEnv)

		-- Set namespace
		SetNameSpace4Env(info.StructEnv, strt)

		setfenv(depth + 1, info.StructEnv)

		if ATTRIBUTE_INSTALLED then ConsumePreparedAttributes(info.Owner, AttributeTargets.Struct) end

		return info.StructEnv
	end

	------------------------------------
	--- import classes from the given name's namespace to the current environment
	------------------------------------
	function import_STRT(env, name)
		if type(name) ~= "string" and not IsNameSpace(name) then error([[Usage: import "namespaceA.namespaceB"]], 2) end

		local info = _NSInfo[env[OWNER_FIELD]]
		local ns

		if type(name) == "string" then
			ns = GetNameSpace(GetDefaultNameSpace(), name)
		elseif IsNameSpace(name) then
			ns = name
		end

		if not ns then error(("No namespace is found with name : %s"):format(name), 2) end

		info.Import4Env = info.Import4Env or {}

		for _, v in ipairs(info.Import4Env) do if v == ns then return end end

		tinsert(info.Import4Env, ns)
	end

	------------------------------------
	--- End the class's definition and restore the environment
	------------------------------------
	function endstruct(env, name)
		if ATTRIBUTE_INSTALLED then ClearPreparedAttributes() end

		local info = _NSInfo[env[OWNER_FIELD]]

		if info.Name == name or info.Owner == name then
			setmetatable(env, _MetaStrtEnv)
			setfenv(3, env[BASE_ENV_FIELD])
			RefreshStruct(info.Owner)
			if info.ApplyAttributes then info.ApplyAttributes() end
			return env[BASE_ENV_FIELD]
		else
			error(("%s is not closed."):format(info.Name), 3)
		end
	end

	function SaveStructField(self, info, key, value)
		rawset(self, key, value)

		if tonumber(key) and info.SubType ~= _STRUCT_TYPE_ARRAY then
			info.SubType = _STRUCT_TYPE_ARRAY
			info.Members = nil
		end

		if info.SubType == _STRUCT_TYPE_MEMBER then
			info.Members = info.Members or {}
			tinsert(info.Members, key)
			if ATTRIBUTE_INSTALLED then ConsumePreparedAttributes(key, AttributeTargets.Member, info.Owner, key) end

			-- Auto generate Default
			if not (info.RequireMember and info.RequireMember[key]) and (not info.DefaultField or info.DefaultField[key] == nil) then
				local rinfo = _NSInfo[value]

				if rinfo and (rinfo.Type == TYPE_STRUCT or rinfo.Type == TYPE_ENUM) and rinfo.Default ~= nil then
					info.DefaultField = info.DefaultField or {}
					info.DefaultField[key] = rinfo.Default
				end
			end
		elseif info.SubType == _STRUCT_TYPE_ARRAY then
			info.ArrayElement = value
			if ATTRIBUTE_INSTALLED then ConsumePreparedAttributes("ArrayElement", AttributeTargets.Member, info.Owner, "ArrayElement") end
		end
	end

	function RefreshStruct(strt)
		local info = _NSInfo[strt]

		if info.SubType == _STRUCT_TYPE_MEMBER and (not info.Members or #(info.Members) == 0) then
			info.SubType = _STRUCT_TYPE_CUSTOM
			info.Members = nil
		end

		-- validate default value if existed
		if info.Default ~= nil then
			if info.SubType ~= _STRUCT_TYPE_CUSTOM then
				info.Default = nil
			elseif not pcall(ValidateStruct, info.Owner, info.Default) then
				info.Default = nil
			end
		end
	end

	function ParseStructDefinition(self, definition)
		local info = _NSInfo[self[OWNER_FIELD]]

		if type(definition) == "table" then
			for k, v in pairs(definition) do
				local vType = getmetatable(v)

				if vType and type(v) ~= "string" then
					if vType == TYPE_NAMESPACE and (type(k) == "string" or tonumber(k)) then
						SaveStructField(self, info, k, v)
					end
				elseif type(v) == "function" then
					if k == info.Name or tonumber(k) then
						info.Validator = v
					else
						info.Method = info.Method or {}
						SaveFixedMethod(info.Method, k, v, info.Owner)
					end
				else
					info.Default = v
				end
			end
		else
			if type(definition) == "string" then
				local errorMsg
				definition, errorMsg = loadstring("return function(_ENV) " .. definition .. " end")
				if definition then
					definition = definition()
				else
					error(errorMsg, 2)
				end
			end

			if type(definition) == "function" then
				setfenv(definition, self)
				return definition(self)
			end
		end
	end

	_KeyWord4StrtEnv.struct = struct
	_KeyWord4StrtEnv.import = import_STRT
	_KeyWord4StrtEnv.endstruct = endstruct
end

------------------------------------------------------
-- Definition Environment Update
------------------------------------------------------
do
	_KeywordAccessor("interface", interface)
	_KeywordAccessor("class", class)
	_KeywordAccessor("enum", enum)
	_KeywordAccessor("struct", struct)
end

------------------------------------------------------
-- System Namespace (Base structs & Reflector)
------------------------------------------------------
do
	namespace "System"

	struct "Boolean"	{ Default = false, function (value) return value and true or false end }
	struct "BooleanNil"	{ function (value) return value and true or false end }
	struct "String"		{ function (value) if type(value) ~= "string" then error(("%s must be a string, got %s."):format("%s", type(value))) end end }
	struct "Number"		{ Default = 0, function (value) if type(value) ~= "number" then error(("%s must be a number, got %s."):format("%s", type(value))) end end }
	struct "NumberNil"	{ function (value) if type(value) ~= "number" then error(("%s must be a number, got %s."):format("%s", type(value))) end end }
	struct "Function"	{ function (value) if type(value) ~= "function" then error(("%s must be a function, got %s."):format("%s", type(value))) end end }
	struct "Table"		{ function (value) if type(value) ~= "table" then error(("%s must be a table, got %s."):format("%s", type(value))) end end }
	struct "RawTable"	{ function (value) assert(type(value) == "table" and getmetatable(value) == nil, "%s must be a table without metatable.") end }
	struct "Userdata"	{ function (value) if type(value) ~= "userdata" then error(("%s must be a userdata, got %s."):format("%s", type(value))) end end }
	struct "Thread"		{ function (value) if type(value) ~= "thread" then error(("%s must be a thread, got %s."):format("%s", type(value))) end end }
	struct "Any"		{ function (value) end }
	struct "Callable"	{ function (value) assert(Reflector.IsCallable(value), "%s isn't callable.") end }
	struct "Class"		{ function (value) assert(Reflector.IsClass(value), "%s must be a class.") end }
	struct "Interface"	{ function (value) assert(Reflector.IsInterface(value), "%s must be an interface.") end }
	struct "Struct"		{ function (value) assert(Reflector.IsStruct(value), "%s must be a struct.") end }
	struct "Enum"		{ function (value) assert(Reflector.IsEnum(value), "%s must be an enum.") end }
	struct "AnyType"	{ function (value) local info = _NSInfo[value] assert(info and info.Type, "%s must be a type, such as enum, struct, class or interface.") end }

	------------------------------------------------------
	-- System.AttributeTargets
	------------------------------------------------------
	enum "AttributeTargets" {
		All = 0,
		Class = 1,
		Constructor = 2,
		Enum = 4,
		Event = 8,
		Interface = 16,
		Method = 32,
		Property = 64,
		Struct = 128,
		Member = 256,
		NameSpace = 512,
	}

	------------------------------------------------------
	-- System.Reflector
	------------------------------------------------------
	interface "Reflector" (function(_ENV)

		local iterForEmpty = function() end

		doc "Reflector" [[This interface contains many apis used to get the running object-oriented system's informations.]]

		doc "GetCurrentNameSpace" [[
			<desc>Get the namespace used by the environment</desc>
			<param name="env" type="table" optional="true">the environment, default the current environment</param>
			<param name="rawOnly" type="boolean" optional="true">skip metatable settings if true</param>
			<return type="namespace">the namespace of the environment</return>
		]]
		function GetCurrentNameSpace(env, rawOnly)
			return GetNameSpace4Env(type(env) == "table" and env or getfenv(2) or _G, rawOnly)
		end

		doc "SetCurrentNameSpace" [[
			<desc>set the namespace used by the environment</desc>
			<param name="ns" type="namespace|string|nil">the namespace that set for the environment</param>
			<param name="env" type="table" optional="true">the environment, default the current environment</param>
		]]
		function SetCurrentNameSpace(ns, env)
			return SetNameSpace4Env(type(env) == "table" and env or getfenv(2) or _G, ns)
		end

		doc "GetNameSpaceForName" [[
			<desc>Get the namespace by the name</desc>
			<param name="name" type="string">the namespace's name, split by "."</param>
			<return type="namespace">the namespace</return>
			<usage>ns = System.Reflector.GetNameSpaceForName("System")</usage>
		]]
		function GetNameSpaceForName(name)
			return GetNameSpace(GetDefaultNameSpace(), name)
		end

		doc "GetNameSpaceType" [[
			<desc>Get the type of the namespace</desc>
			<param name="name" type="namespace|string">the namespace</param>
			<return type="string">The namespace's type like NameSpace|Class|Struct|Enum|Interface</return>
			<usage>type = System.Reflector.GetNameSpaceType("System.Object")</usage>
		]]
		function GetNameSpaceType(ns)
			local info = _NSInfo[ns]
			return info and info.Type
		end

		doc "GetNameSpaceName" [[
			<desc>Get the name of the namespace</desc>
			<param name="namespace">the namespace to query</param>
			<return type="string">the namespace's name</return>
			<usage>System.Reflector.GetNameSpaceName(System.Object)</usage>
		]]
		function GetNameSpaceName(ns)
			local info = _NSInfo[ns]
			return info and info.Name
		end

		doc "GetNameSpaceFullName" [[
			<desc>Get the full name of the namespace</desc>
			<param name="namespace">the namespace to query</param>
			<return type="string">the full path of the namespace</return>
			<usage>path = System.Reflector.GetNameSpaceFullName(System.Object)</usage>
		]]
		GetNameSpaceFullName = tostring

		doc "BeginDefinition" [[
			<desc>Begin the definition of target namespace, stop cache refresh</desc>
			<param name="namespace|string">the namespace</param>
		]]
		function BeginDefinition(ns)
			local info = _NSInfo[ns]
			assert(info and (info.Type == TYPE_CLASS or info.Type == TYPE_INTERFACE), "System.Reflector.BeginDefinition(ns) - ns must be a class or interface.")
			info.BeginDefinition = true
		end

		doc "EndDefinition" [[
			<desc>End the definition of target namespace, refresh the cache</desc>
			<param name="namespace|string">the namespace</param>
		]]
		function EndDefinition(ns)
			local info = _NSInfo[ns]
			assert(info and (info.Type == TYPE_CLASS or info.Type == TYPE_INTERFACE), "System.Reflector.BeginDefinition(ns) - ns must be a class or interface.")
			info.BeginDefinition = nil
			return RefreshCache(info.Owner)
		end

		doc "GetSuperClass" [[
			<desc>Get the superclass of the class</desc>
			<param name="class">the class object to query</param>
			<return type="class">the super class if existed</return>
			<usage>System.Reflector.GetSuperClass(System.Object)</usage>
		]]
		function GetSuperClass(ns)
			local info = _NSInfo[ns]
			return info and info.SuperClass
		end

		doc "IsNameSpace" [[
			<desc>Check if the object is a NameSpace</desc>
			<param name="object">the object to query</param>
			<return type="boolean">true if the object is a NameSpace</return>
			<usage>System.Reflector.IsNameSpace(System.Object)</usage>
		]]
		function IsNameSpace(ns) return _NSInfo[ns] and true or false end

		doc "IsClass" [[
			<desc>Check if the namespace is a class</desc>
			<param name="object">the object to query</param>
			<return type="boolean">true if the object is a class</return>
			<usage>System.Reflector.IsClass(System.Object)</usage>
		]]
		function IsClass(ns)
			local info = _NSInfo[ns]
			return info and info.Type == TYPE_CLASS or false
		end

		doc "IsStruct" [[
			<desc>Check if the namespace is a struct</desc>
			<param name="object">the object to query</param>
			<return type="boolean">true if the object is a struct</return>
			<usage>System.Reflector.IsStruct(System.Object)</usage>
		]]
		function IsStruct(ns)
			local info = _NSInfo[ns]
			return info and info.Type == TYPE_STRUCT or false
		end

		doc "IsEnum" [[
			<desc>Check if the namespace is an enum</desc>
			<param name="object">the object to query</param>
			<return type="boolean">true if the object is a enum</return>
			<usage>System.Reflector.IsEnum(System.Object)</usage>
		]]
		function IsEnum(ns)
			local info = _NSInfo[ns]
			return info and info.Type == TYPE_ENUM or false
		end

		doc "IsInterface" [[
			<desc>Check if the namespace is an interface</desc>
			<param name="object">the object to query</param>
			<return type="boolean">true if the object is an Interface</return>
			<usage>System.Reflector.IsInterface(System.IFSocket)</usage>
		]]
		function IsInterface(ns)
			local info = _NSInfo[ns]
			return info and info.Type == TYPE_INTERFACE or false
		end

		doc "IsSealed" [[
			<desc>Check if the feature is sealed, can't be re-defined</desc>
			<param name="object">the object to query</param>
			<return type="boolean">true if the feature is sealed</return>
			<usage>System.Reflector.IsSealed(System.Object)</usage>
		]]
		function IsSealed(ns)
			local info = _NSInfo[ns]
			return info and info.IsSealed or false
		end

		doc "IsFinal" [[
			<desc>Check if the class|interface is final</desc>
			<param name="object">the object to query</param>
			<param name="name" optional="true">the method or property's name</param>
			<return type="boolean">true if the feature is final</return>
			<usage>System.Reflector.IsFinal(System.Object)</usage>
		]]
		function IsFinal(ns, name)
			return IsFinalFeature(ns, type(name) == "string" and name or nil) or false
		end

		doc "IsUniqueClass" [[
			<desc>Check if the class is unique, can only have one object</desc>
			<param name="object">the object to query</param>
			<return type="boolean">true if the class is unique</return>
			<usage>System.Reflector.IsUniqueClass(System.Object)</usage>
		]]
		function IsUniqueClass(ns)
			local info = _NSInfo[ns]
			return info and info.UniqueObject and true or false
		end

		doc "IsAutoCache" [[
			<desc>Whether the class|interface|method is auto-cached</desc>
			<param name="object">the object to query</param>
			<param name="name" optional="true" type="string">the meethod name to query</param>
			<return type="boolean">true if auto-cached</return>
			<usage>System.Reflector.IsAutoCache(System.Object)</usage>
		]]
		function IsAutoCache(ns, name)
			local info = _NSInfo[ns]
			local autoCache = info and info.AutoCache
			return autoCache == true or (name and autoCache and autoCache[name]) or false
		end

		doc "GetSubNamespace" [[
			<desc>Get the sub namespace of the namespace</desc>
			<param name="namespace">the object to query</param>
			<param name="result" optional="true">the result table</param>
			<return name="iterator|result">the sub-namespace iterator|the result table</return>
			<usage>for name, ns in System.Reflector.GetSubNamespace(System) do print(name) end</usage>
		]]
		local _GetSubNamespaceCache, _GetSubNamespaceIter
		if not SAVE_MEMORY then
			_GetSubNamespaceCache = setmetatable({}, WEAK_ALL)
		else
			_GetSubNamespaceIter = function (ns, key) return next(_NSInfo[ns].SubNS, key) end
		end
		function GetSubNamespace(ns, result)
			local info = _NSInfo[ns]

			if info and info.SubNS then
				if type(result) == "table" then
					for k, v in pairs(info.SubNS) do result[k] = v end
					return result
				else
					if SAVE_MEMORY then
						return _GetSubNamespaceIter, info.Owner
					else
						ns = info.Owner
						local iter = _GetSubNamespaceCache[ns]
						if not iter then
							local subNS = info.SubNS
							iter = function (ns, key) return next(subNS, key) end
							_GetSubNamespaceCache[ns] = iter
						end
						return iter, ns
					end
				end
			else
				return type(result) == "table" and result or iterForEmpty, info.Owner
			end
		end

		doc "GetExtendInterfaces" [[
			<desc>Get the extend interfaces of the class|interface</desc>
			<param name="object">the object to query</param>
			<param name="result" optional="true">the result table</param>
			<return name="iterator|result">the extend interface iterator|the result table</return>
			<usage>for i, interface in System.Reflector.GetExtendInterfaces(System.Object) do print(interface) end</usage>
		]]
		local _GetExtendInterfacesCache, _GetExtendInterfacesIter
		if not SAVE_MEMORY then
			_GetExtendInterfacesCache = setmetatable({}, WEAK_ALL)
		else
			_GetExtendInterfacesIter = function (ns, index)
				index = index + 1
				local IF = _NSInfo[ns].ExtendInterface[index]
				if IF then return index, IF end
			end
		end
		function GetExtendInterfaces(ns, result)
			local info = _NSInfo[ns]

			if info and info.ExtendInterface then
				if type(result) == "table" then
					for _, IF in ipairs(info.ExtendInterface) do tinsert(result, IF) end
					return result
				else
					if SAVE_MEMORY then
						return _GetExtendInterfacesIter, info.Owner, 0
					else
						ns = info.Owner
						local iter = _GetExtendInterfacesCache[ns]
						if not iter then
							local eIF = info.ExtendInterface
							iter = function (ns, index)
								index = index + 1
								local IF = eIF[index]
								if IF then return index, IF end
							end
							_GetExtendInterfacesCache[ns] = iter
						end
						return iter, ns, 0
					end
				end
			else
				return type(result) == "table" and result or iterForEmpty, info.Owner, 0
			end
		end

		doc "GetAllExtendInterfaces" [[
			<desc>Get all the extend interfaces of the class|interface</desc>
			<param name="object">the object to query</param>
			<param name="result" optional="true">the result table</param>
			<return name="iterator|result">the all extend interface iterator|the result table</return>
			<usage>for _, IF in System.Reflector.GetAllExtendInterfaces(System.Object) do print(IF) end</usage>
		]]
		local _GetAllExtendInterfacesCache, _GetAllExtendInterfacesIter
		if not SAVE_MEMORY then
			_GetAllExtendInterfacesCache = setmetatable({}, WEAK_ALL)
		else
			_GetAllExtendInterfacesIter = function (ns, index)
				index = index + 1
				local IF = _NSInfo[ns].Cache4Interface[index]
				if IF then return index, IF end
			end
		end
		function GetAllExtendInterfaces(ns, result)
			local info = _NSInfo[ns]

			if info and info.Cache4Interface then
				if type(result) == "table" then
					for _, IF in ipairs(info.Cache4Interface) do tinsert(result, IF) end
					return result
				else
					if SAVE_MEMORY then
						return _GetAllExtendInterfacesIter, info.Owner, 0
					else
						ns = info.Owner
						local iter = _GetAllExtendInterfacesCache[ns]
						if not iter then
							local eIF = info.Cache4Interface
							iter = function (ns, index)
								index = index + 1
								local IF = eIF[index]
								if IF then return index, IF end
							end
							_GetAllExtendInterfacesCache[ns] = iter
						end
						return iter, ns, 0
					end
				end
			else
				return type(result) == "table" and result or iterForEmpty, info.Owner, 0
			end
		end

		doc "GetEvents" [[
			<desc>Get the events of the class|interface</desc>
			<param name="class|interface">the class or interface to query</param>
			<param name="result" optional="true">the result table</param>
			<return name="iterator|result">the event iterator|the result table</return>
			<usage>for name in System.Reflector.GetEvents(System.Object) do print(name) end</usage>
		]]
		local _GetEventsCache, _GetEventsIter
		if not SAVE_MEMORY then
			_GetEventsCache = setmetatable({}, WEAK_ALL)
		else
			_GetEventsIter = function (ns, key) return (next(_NSInfo[ns].Event, key)) end
		end
		function GetEvents(ns, result)
			local info = _NSInfo[ns]

			if info and info.Event then
				if type(result) == "table" then
					for k in pairs(info.Event) do tinsert(result, k) end
					sort(result)
					return result
				else
					if SAVE_MEMORY then
						return _GetEventsIter, info.Owner
					else
						ns = info.Owner
						local iter = _GetEventsCache[ns]
						if not iter then
							local evts = info.Event
							iter = function (ns, key) return (next(evts, key)) end
							_GetEventsCache[ns] = iter
						end
						return iter, ns
					end
				end
			else
				return type(result) == "table" and result or iterForEmpty, info.Owner
			end
		end

		doc "GetAllEvents" [[
			<desc>Get all the events of the class</desc>
			<param name="class|interface">the class or interface to query</param>
			<param name="result" optional="true">the result table</param>
			<return name="iterator|result">the event iterator|the result table</return>
			<usage>for name in System.Reflector.GetAllEvents(System.Object) do print(name) end</usage>
		]]
		local _GetAllEventsCache, _GetAllEventsIter
		if not SAVE_MEMORY then
			_GetAllEventsCache = setmetatable({}, WEAK_ALL)
		else
			_GetAllEventsIter = function (ns, key) for k, v in next, _NSInfo[ns].Cache, key do if getmetatable(v) then return k end end end
		end
		function GetAllEvents(ns, result)
			local info = _NSInfo[ns]

			if info and info.Event then
				if type(result) == "table" then
					for k, v in pairs(info.Cache) do if getmetatable(v) then tinsert(result, k) end end
					sort(result)
					return result
				else
					if SAVE_MEMORY then
						return _GetAllEventsIter, info.Owner
					else
						ns = info.Owner
						local iter = _GetAllEventsCache[ns]
						if not iter then
							local cache = info.Cache
							iter = function (ns, key) for k, v in next, cache, key do if getmetatable(v) then return k end end end
							_GetAllEventsCache[ns] = iter
						end
						return iter, ns
					end
				end
			else
				return type(result) == "table" and result or iterForEmpty, info.Owner
			end
		end

		doc "GetProperties" [[
			<desc>Get the properties of the class|interface</desc>
			<param name="object">the class or interface to query</param>|
			<param name="result" optional="true">the result table</param>
			<return name="iterator|result">the property iterator|the result table</return>
			<usage>for name in System.Reflector.GetProperties(System.Object) do print(name) end</usage>
		]]
		local _GetPropertiesCache, _GetPropertiesIter
		if not SAVE_MEMORY then
			_GetPropertiesCache = setmetatable({}, WEAK_ALL)
		else
			_GetPropertiesIter = function (ns, key) return (next(_NSInfo[ns].Property, key)) end
		end
		function GetProperties(ns, result)
			local info = _NSInfo[ns]

			if info and info.Property then
				if type(result) == "table" then
					for k in pairs(info.Property) do tinsert(result, k) end
					sort(result)
					return result
				else
					if SAVE_MEMORY then
						return _GetPropertiesIter, info.Owner
					else
						ns = info.Owner
						local iter = _GetPropertiesCache[ns]
						if not iter then
							local props = info.Property
							iter = function (ns, key) return (next(props, key)) end
							_GetPropertiesCache[ns] = iter
						end
						return iter, ns
					end
				end
			else
				return type(result) == "table" and result or iterForEmpty, info.Owner
			end
		end

		doc "GetAllProperties" [[
			<desc>Get all the properties of the class|interface</desc>
			<param name="object">the class or interface to query</param>|
			<param name="result" optional="true">the result table</param>
			<return name="iterator|result">the property iterator|the result table</return>
			<usage>for name in System.Reflector.GetAllProperties(System.Object) do print(name) end</usage>
		]]
		local _GetAllPropertiesCache, _GetAllPropertiesIter
		if not SAVE_MEMORY then
			_GetAllPropertiesCache = setmetatable({}, WEAK_ALL)
		else
			_GetAllPropertiesIter = function (ns, key)
				local info = _NSInfo[ns]
				local props = info.Cache

				if key == nil or props[key] then
					for k, v in next, props, key do if type(v) == "table" and not getmetatable(v) then return k end end
					key = nil
				end

				props = info.Property

				if key == nil or props[key] then
					for k, v in next, props, key do if v.IsStatic then return k end end
				end
			end
		end
		function GetAllProperties(ns, result)
			local info = _NSInfo[ns]

			if info and info.Property then
				if type(result) == "table" then
					for k, v in pairs(info.Cache) do if type(v) == "table" and not getmetatable(v) then tinsert(result, k) end end
					for k, v in pairs(info.Property) do if v.IsStatic then tinsert(result, k) end end
					sort(result)
					return result
				else
					if SAVE_MEMORY then
						return _GetAllPropertiesIter, info.Owner
					else
						ns = info.Owner
						local iter = _GetAllPropertiesCache[ns]
						if not iter then
							local cache = info.Cache
							local props = info.Property
							iter = function (ns, key)
								if key == nil or cache[key] then
									for k, v in next, cache, key do if type(v) == "table" and not getmetatable(v) then return k end end
									key = nil
								end

								if key == nil or props[key] then
									for k, v in next, props, key do if v.IsStatic then return k end end
								end
							end
							_GetAllPropertiesCache[ns] = iter
						end
						return iter, ns
					end
				end
			else
				return type(result) == "table" and result or iterForEmpty, info.Owner
			end
		end

		doc "GetMethods" [[
			<desc>Get the methods of the class|interface</desc>
			<param name="object">the class or interface to query</param>
			<param name="result" optional="true">the result table</param>
			<return name="iterator|result">the method iterator|the result table</return>
			<usage>for name in System.Reflector.GetMethods(System.Object) do print(name) end</usage>
		]]
		local _GetMethodsCache, _GetMethodsIter
		if not SAVE_MEMORY then
			_GetMethodsCache = setmetatable({}, WEAK_ALL)
		else
			_GetMethodsIter = function (ns, key) return (next(_NSInfo[ns].Method, key)) end
		end
		function GetMethods(ns, result)
			local info = _NSInfo[ns]

			if info and info.Method then
				if type(result) == "table" then
					for k in pairs(info.Method) do tinsert(result, k) end
					sort(result)
					return result
				else
					if SAVE_MEMORY then
						return _GetMethodsIter, info.Owner
					else
						ns = info.Owner
						local iter = _GetMethodsCache[ns]
						if not iter then
							local methods = info.Method
							iter = function (ns, key) return (next(methods, key)) end
							_GetMethodsCache[ns] = iter
						end
						return iter, ns
					end
				end
			else
				return type(result) == "table" and result or iterForEmpty, info.Owner
			end
		end

		doc "GetAllMethods" [[
			<desc>Get all the methods of the class|interface</desc>
			<param name="object">the class or interface to query</param>
			<param name="result" optional="true">the result table</param>
			<return name="iterator|result">the method iterator|the result table</return>
			<usage>for name in System.Reflector.GetAllMethods(System.Object) do print(name) end</usage>
		]]
		local _GetAllMethodsCache, _GetAllMethodsIter
		if not SAVE_MEMORY then
			_GetAllMethodsCache = setmetatable({}, WEAK_ALL)
		else
			_GetAllMethodsIter = function (ns, key)
				local info = _NSInfo[ns]
				local methods = info.Cache or info.Method

				if key == nil or methods[key] then
					for k, v in next, methods, key do if type(v) == "function" then return k end end
					key = nil
				end

				methods = info.StaticMethod

				if methods and (key == nil or methods[key]) then
					for k, v in next, methods, key do return k end
				end
			end
		end
		function GetAllMethods(ns, result)
			local info = _NSInfo[ns]

			if info and info.Method then
				if type(result) == "table" then
					for k, v in pairs(info.Cache or info.Method) do if type(v) == "function" then tinsert(result, k) end end
					if info.StaticMethod then for k, v in pairs(info.StaticMethod) do tinsert(result, k) end end
					sort(result)
					return result
				else
					if SAVE_MEMORY then
						return _GetAllMethodsIter, info.Owner
					else
						ns = info.Owner
						local iter = _GetAllMethodsCache[ns]
						if not iter then
							local cache = info.Cache or info.Method
							local static = info.StaticMethod
							iter = function (ns, key)
								if key == nil or cache[key] then
									for k, v in next, cache, key do if type(v) == "function" then return k end end
									key = nil
								end

								if static and (key == nil or static[key]) then
									for k, v in next, static, key do return k end
								end
							end
							_GetAllMethodsCache[ns] = iter
						end
						return iter, ns
					end
				end
			else
				return type(result) == "table" and result or iterForEmpty, info.Owner
			end
		end

		doc "GetPropertyType" [[
			<desc>Get the property type of the property</desc>
			<param name="owner" type="class|interface">the property's owner</param>
			<param name="name" type="string">the property name</param>
			<return type="System.Type">the property type</return>
			<usage>System.Reflector.GetPropertyType(System.Object, "Name")</usage>
		]]
		function GetPropertyType(ns, name)
			local info = _NSInfo[ns]

			if info and info.Property then
				local prop = info.Cache[name] or info.Property[name]
				return type(prop) == "table" and getmetatable(prop) == nil and prop.Type or nil
			end
		end

		doc "HasProperty" [[
			<desc>whether the property is existed</desc>
			<param name="owner" type="class|interface">The owner of the property</param>
			<param name="name" type="string">The property's name</param>
			<return type="boolean">true if the class|interface has the property</return>
			<usage>System.Reflector.HasProperty(System.Object, "Name")</usage>
		]]
		function HasProperty(ns, name)
			local info = _NSInfo[ns]

			if info and info.Property then
				local prop = info.Cache[name] or info.Property[name]
				if type(prop) == "table" and getmetatable(prop) == nil and prop.Type then return true end
			end
			return false
		end

		doc "IsPropertyReadable" [[
			<desc>whether the property is readable</desc>
			<param name="owner" type="class|interface">the property's owner</param>
			<param name="name" type="string">the property's name</param>
			<return type="boolean">true if the property is readable</return>
			<usage>System.Reflector.IsPropertyReadable(System.Object, "Name")</usage>
		]]
		function IsPropertyReadable(ns, name)
			local info = _NSInfo[ns]

			if info and info.Property then
				local prop = info.Cache[name]
				if prop then return type(prop) == "table" and getmetatable(prop) == nil and (prop.Get or prop.GetMethod or prop.Field or prop.Default ~= nil) and true or false end
				prop = info.Property[name]
				if prop and prop.IsStatic then return (prop.Get or prop.GetMethod or prop.Default ~= nil) and true or false end
			end
		end

		doc "IsPropertyWritable" [[
			<desc>whether the property is writable</desc>
			<param name="owner" type="class|interface">the property's owner</param>
			<param name="name" type="string">the property's name</param>
			<return type="boolean">true if the property is writable</return>
			<usage>System.Reflector.IsPropertyWritable(System.Object, "Name")</usage>
		]]
		function IsPropertyWritable(ns, name)
			local info = _NSInfo[ns]

			if info and info.Property then
				local prop = info.Cache[name]
				if prop then return type(prop) == "table" and getmetatable(prop) == nil and (prop.Set or prop.SetMethod or prop.Field) and true or false end
				prop = info.Property[name]
				if prop and prop.IsStatic then return (prop.Set or prop.SetMethod) and true or false end
			end
		end

		doc "IsRequiredMethod" [[
			<desc>Whether the method is required to be overridden</desc>
			<param name="owner" type="interface">the method's owner</param>
			<param name="name" type="string">the method's name</param>
			<return type="boolean">true if the method must be overridden</return>
		]]
		function IsRequiredMethod(ns, name)
			local info = _NSInfo[ns]
			return info and info.RequireMethod and info.RequireMethod[name] or false
		end

		doc "IsRequiredProperty" [[
			<desc>Whether the property is required to be overridden</desc>
			<param name="owner" type="interface">the property's owner</param>
			<param name="name" type="string">the property's name</param>
			<return type="boolean">true if the property must be overridden</return>
		]]
		function IsRequiredProperty(ns, name)
			local info = _NSInfo[ns]
			return info and info.RequireProperty and info.RequireProperty[name] or false
		end

		doc "IsOptionalMethod" [[
			<desc>Whether the method is optional to be overridden</desc>
			<param name="owner" type="interface">the method's owner</param>
			<param name="name" type="string">the method's name</param>
			<return type="boolean">true if the method should be overridden</return>
		]]
		function IsOptionalMethod(ns, name)
			local info = _NSInfo[ns]
			return info and info.OptionalMethod and info.OptionalMethod[name] or false
		end

		doc "IsOptionalProperty" [[
			<desc>Whether the property is optional to be overridden</desc>
			<param name="owner" type="interface">the property's owner</param>
			<param name="name" type="string">the property's name</param>
			<return type="boolean">true if the property should be overridden</return>
		]]
		function IsOptionalProperty(ns, name)
			local info = _NSInfo[ns]
			return info and info.OptionalProperty and info.OptionalProperty[name] or false
		end

		doc "IsStaticProperty" [[
			<desc>Whether the property is static</desc>
			<param name="owner" type="interface">the property's owner</param>
			<param name="name" type="string">the property's name</param>
			<return type="boolean">true if the property is static</return>
		]]
		function IsStaticProperty(ns, name)
			local info = _NSInfo[ns]

			info = info and info.Property
			info = info and info[name]

			return info and info.IsStatic or false
		end

		doc "IsStaticMethod" [[
			<desc>Whether the method is static</desc>
			<param name="owner" type="interface">the method's owner</param>
			<param name="name" type="string">the method's name</param>
			<return type="boolean">true if the method is static</return>
		]]
		function IsStaticMethod(ns, name)
			local info = _NSInfo[ns]
			return info and info.StaticMethod and info.StaticMethod[name] or false
		end

		doc "IsFlagsEnum" [[
			<desc>Whether the enum is flags or not</desc>
			<param name="object" type="enum">The enum type</param>
			<return name="boolean">true if the enum is a flag enumeration</return>
			<usage>System.Reflector.IsFlagsEnum(System.AttributeTargets)</usage>
		]]
		function IsFlagsEnum(ns)
			local info = _NSInfo[ns]
			return info and info.IsFlags or false
		end

		doc "GetEnums" [[
			<desc>Get the enumeration keys of the enum</desc>
			<param name="enum" type="enum">the enum tyep</param>
			<param name="result" optional="true">the result table</param>
			<return name="iterator|result">the enum key iterator|the result table</return>
			<usage>System.Reflector.GetEnums(System.AttributeTargets)</usage>
		]]
		local _GetEnumsCache, _GetEnumsIter
		if not SAVE_MEMORY then
			_GetEnumsCache = setmetatable({}, WEAK_ALL)
		else
			_GetEnumsIter = function (ns, key) return next(_NSInfo[ns].Enum, key) end
		end
		function GetEnums(ns, result)
			local info = _NSInfo[ns]

			if info and info.Enum then
				if type(result) == "table" then
					for k, v in pairs(info.Enum) do result[k] = v end
					return result
				else
					if SAVE_MEMORY then
						return _GetEnumsIter, info.Owner
					else
						ns = info.Owner
						local iter = _GetEnumsCache[ns]
						if not iter then
							local enums = info.Enum
							iter = function (ns, key) return next(enums, key) end
							_GetEnumsCache[ns] = iter
						end
						return iter, ns
					end
				end
			else
				return type(result) == "table" and result or iterForEmpty, info.Owner
			end
		end

		doc "ValidateFlags" [[
			<desc>Whether the value is contains on the target value</desc>
			<param name="checkValue" type="number">like 1, 2, 4, 8, ...</param>
			<param name="targetValue" type="number">like 3 : (1 + 2)</param>
			<return type="boolean">true if the targetValue contains the checkValue</return>
		]]
		function ValidateFlags(checkValue, targetValue)
			targetValue = targetValue % (2 * checkValue)
			return (targetValue - targetValue % checkValue) == checkValue
		end

		doc "HasEvent" [[
			<desc>Check if the class|interface has that event</desc>
			<param name="owner" type="class|interface">the event's owner</param>|interface
			<param name="event" type="string">the event's name</param>
			<return type="boolean">if the owner has the event</return>
			<usage>System.Reflector.HasEvent(Addon, "OnEvent")</usage>
		]]
		function HasEvent(ns, evt)
			local info = _NSInfo[ns]
			return info and info.Cache and getmetatable(info.Cache[evt]) or false
		end

		doc "GetStructType" [[
			<desc>Get the type of the struct type</desc>
			<param name="struct" type="struct">the struct</param>
			<return type="string">the type of the struct type</return>
		]]
		function GetStructType(ns)
			local info = _NSInfo[ns]
			return info and info.Type == TYPE_STRUCT and info.SubType or nil
		end

		doc "GetStructArrayElement" [[
			<desc>Get the array element types of the struct</desc>
			<param name="struct" type="struct">the struct type</param>
			<return type="System.Type">the array element's type</return>
		]]
		function GetStructArrayElement(ns)
			local info = _NSInfo[ns]
			return info and info.Type == TYPE_STRUCT and info.SubType == _STRUCT_TYPE_ARRAY and info.ArrayElement and info.ArrayElement:Clone() or nil
		end

		doc "HasStructMember" [[
			<desc>Whether the struct has the query member</desc>
			<param name="struct" type="struct">the struct type</param>
			<param name="member" type="string">the query member</param>
			<return type="boolean">true if the struct has the member</return>
		]]
		function HasStructMember(ns, member)
			local info = _NSInfo[ns]

			if info and info.Type == TYPE_STRUCT and info.SubType == _STRUCT_TYPE_MEMBER and info.Members then
				for _, part in ipairs(info.Members) do if part == member then return true end end
			end

			return false
		end

		doc "IsRequiredMember" [[
			<desc>Whether the member of the struct is required.</desc>
			<param name="struct" type="struct">the struct type</param>
			<param name="member" type="string">the query member</param>
			<return type="boolean">true if the struct has the member</return>
		]]
		function IsRequiredMember(ns, member)
			local info = _NSInfo[ns]

			if info and info.Type == TYPE_STRUCT and info.SubType == _STRUCT_TYPE_MEMBER then
				if info.RequireMember and info.RequireMember[member] then return true end
			end

			return false
		end

		doc "GetStructMembers" [[
			<desc>Get the parts of the struct type</desc>
			<param name="struct" type="struct">the struct type</param>
			<param name="result" optional="true">the result table</param>
			<return name="iterator|result">the member iterator|the result table</return>
			<usage>for _, member in System.Reflector.GetStructMembers(Position) do print(member) end</usage>
		]]
		local _GetStructMembersCache, _GetStructMembersIter
		if not SAVE_MEMORY then
			_GetStructMembersCache = setmetatable({}, WEAK_ALL)
		else
			_GetStructMembersIter = function (ns, key) return next(_NSInfo[ns].Members, key) end
		end
		function GetStructMembers(ns, result)
			local info = _NSInfo[ns]

			if info and info.Members then
				if type(result) == "table" then
					for _, member in ipairs(info.Members) do tinsert(result, member) end
					return result
				else
					if SAVE_MEMORY then
						return _GetStructMembersIter, info.Owner
					else
						local members = info.Members
						local iter = _GetStructMembersCache[members]
						if not iter then
							iter = function (ns, key) return next(members, key) end
							_GetStructMembersCache[members] = iter
						end
						return iter, ns
					end
				end
			else
				return type(result) == "table" and result or iterForEmpty, info.Owner
			end
		end

		doc "GetStructMember" [[
			<desc>Get the part's type of the struct</desc>
			<param name="struct" type="struct">the struct type</param>
			<param name="part" type="string">the part's name</param>
			<return type="System.Type">the part's type</return>
			<usage>System.Reflector.GetStructMember(Position, "x")</usage>
		]]
		function GetStructMember(ns, part)
			local info = _NSInfo[ns]

			if info and info.Type == TYPE_STRUCT then
				if info.SubType == _STRUCT_TYPE_MEMBER and info.Members then
					local mType = rawget(info.StructEnv, part)
					if IsNameSpace(mType) then return mType end
				elseif info.SubType == _STRUCT_TYPE_ARRAY and info.ArrayElement then
					return info.ArrayElement
				end
			end
		end

		doc "IsSuperClass" [[
			<desc>Check if this class is inherited from the target class</desc>
			<param name="class" type="class">the child class</param>
			<param name="superclass" type="class">the super class</param>
			<return type="boolean">true if the class is inherited from the target class</return>
			<usage>System.Reflector.IsSuperClass(UIObject, Object)</usage>
		]]
		function IsSuperClass(child, super)
			if type(child) == "string" then child = GetNameSpaceForName(child) end
			if type(super) == "string" then super = GetNameSpaceForName(super) end

			return IsClass(child) and IsClass(super) and IsChildClass(super, child)
		end

		doc "IsExtendedInterface" [[
			<desc>Check if the class|interface is extended from the interface</desc>
			<param name="object" type="interface|class">the class or interface</param>
			<param name="interface" type="interface">the target interface</param>
			<return type="boolean">true if the first arg is extend from the second</return>
			<usage>System.Reflector.IsExtendedInterface(UIObject, IFSocket)</usage>
		]]
		function IsExtendedInterface(cls, IF)
			if type(cls) == "string" then cls = GetNameSpaceForName(cls) end
			if type(IF) == "string" then IF = GetNameSpaceForName(IF) end

			return IsExtend(IF, cls)
		end

		doc "IsAbstractClass" [[
			<desc>Whether the class is an abstract class</desc>
			<param name="class" type="class">the class</param>
			<return type="boolean">true if the class is an abstract class</return>
		]]
		function IsAbstractClass(ns)
			local info = _NSInfo[ns]
			return info and info.AbstractClass or false
		end

		doc "GetObjectClass" [[
			<desc>Get the class type of the object</desc>
			<param name="object">the object</param>
			<return type="class">the object's class</return>
			<usage>System.Reflector.GetObjectClass(obj)</usage>
		]]
		function GetObjectClass(object)
			local cls = getmetatable(object)
			local info = _NSInfo[cls]
			return info and info.Type == TYPE_CLASS and cls or nil
		end

		doc "ObjectIsClass" [[
			<desc>Check if this object is an instance of the class</desc>
			<param name="object">the object</param>
			<param name="class">the class</param>
			<return type="boolean">true if the object is an instance of the class or it's child class</return>
			<usage>System.Reflector.ObjectIsClass(obj, Object)</usage>
		]]
		function ObjectIsClass(obj, ns)
			return IsChildClass(type(ns) == "string" and GetNameSpaceForName(ns) or ns, GetObjectClass(obj)) or false
		end

		doc "ObjectIsInterface" [[
			<desc>Check if this object is an instance of the interface</desc>
			<param name="object">the object</param>
			<param name="interface">the interface</param>
			<return type="boolean">true if the object's class is extended from the interface</return>
			<usage>System.Reflector.ObjectIsInterface(obj, IFSocket)</usage>
		]]
		function ObjectIsInterface(obj, ns)
			return IsExtend(type(ns) == "string" and GetNameSpaceForName(ns) or ns, GetObjectClass(obj)) or false
		end

		doc "FireObjectEvent" [[
			<desc>Fire an object's event, to trigger the object's event handlers</desc>
			<param name="object">the object</param>
			<param name="event">the event name</param>
			<param name="...">the event's arguments</param>
		]]
		function FireObjectEvent(obj, evt, ...)
			-- No more check , just fire the event as quick as we can
			local handler = rawget(obj, "__Events")
			handler = handler and rawget(handler, evt)
			if handler then return handler(obj, ...) end
		end

		doc "BlockEvent" [[
			<desc>Block event for object</desc>
			<param name="object">the object</param>
			<param name="...">the event name list</param>
			<usage>System.Reflector.BlockEvent(obj, "OnClick", "OnEnter")</usage>
		]]
		function BlockEvent(obj, ...)
			local cls = GetObjectClass(obj)
			local name

			if cls then
				for i = 1, select('#', ...) do
					name = select(i, ...)

					if HasEvent(cls, name) then obj[name].Blocked = true end
				end
			end
		end

		doc "IsEventBlocked" [[
			<desc>Whether the event is blocked for object</desc>
			<param name="object">the object</param>
			<param name="event">the event's name</param>
			<return type="boolean">true if the event is blocked</return>
			<usage>System.Reflector.IsEventBlocked(obj, "OnClick")</usage>
		]]
		function IsEventBlocked(obj, sc)
			local cls = GetObjectClass(obj)
			local name

			if cls and HasEvent(cls, sc) then return obj[sc].Blocked end

			return false
		end

		doc "UnBlockEvent" [[
			<desc>Un-Block event for object</desc>
			<param name="object">the object</param>
			<param name="...">the event name list</param>
			<usage>System.Reflector.UnBlockEvent(obj, "OnClick", "OnEnter")</usage>
		]]
		function UnBlockEvent(obj, ...)
			local cls = GetObjectClass(obj)
			local name

			if cls then
				for i = 1, select('#', ...) do
					name = select(i, ...)

					if HasEvent(cls, name) then obj[name].Blocked = false end
				end
			end
		end

		doc "Validate" [[
			<desc>Validating the value to the given type.</desc>
			<format>type, value, name[, prefix[, stacklevel] ]</format>
			<param name="oType">The test type</param>
			<param name="value">the test value</param>
			<param name="name">the parameter's name</param>
			<param name="prefix">the prefix string</param>
			<param name="stacklevel">set if not in the main function call, only work when prefix is setted</param>
			<return>the validated value</return>
			<usage>System.Reflector.Validate(System.String+nil, "Test")</usage>
		]]
		function Validate(oType, value, name, prefix, stacklevel)
			stacklevel = floor(type(stacklevel) == "number" and stacklevel > 0 and stacklevel or 0)

			if type(name) ~= "string" then name = "value" end
			if oType == nil then return value end

			assert(_NSInfo[oType] and _NSInfo[oType].Type, "Usage : System.Reflector.Validate(oType, value[, name[, prefix]]) : oType - must be enum, struct, class or interface.")

			local ok

			ok, value = pcall(Validate4Type, oType, value)

			if not ok then
				value = strtrim(value:match(":%d+:%s*(.-)$") or value):gsub("%%s[_%w]*", name)

				if type(prefix) == "string" then
					error(prefix .. value, 3 + stacklevel)
				else
					error(value, 2)
				end
			end

			return value
		end

		doc "GetValidatedValue" [[
			<desc>Get validated value for the type</desc>
			<param name="oType">The test type</param>
			<param name="value">the test value</param>
			<return>the validated value, nil if the value can't pass the validation</return>
		]]
		GetValidatedValue = GetValidatedValue

		doc "GetDocument" [[
			<desc>Get the document</desc>
			<param name="owner">the document's owner</param>
			<param name="name" optional="true">the query name, default the owner's name</param>
			<param name="targetType" optional="true" type="System.AttributeTargets">the query target type, can be auto-generated by the name</param>
			<return type="string">the document</return>
		]]
		GetDocument = GetDocument

		doc "Serialize" [[
			<desc>Serialize the data</desc>
			<param name="data">the data</param>
			<param name="type" optional="true">the data's type</param>
			<return type="string"></return>
		]]
		local function SerializeData(data)
			if type(data) == "string" then
				return strformat("%q", data)
			elseif type(data) == "number" or type(data) == "boolean" then
				return tostring(data)
			elseif type(data) == "table" and not Reflector.IsNameSpace(data) then
				local cache = CACHE_TABLE()

				tinsert(cache, "{")

				for k, v in pairs(data) do
					if type(k) == "number" or type(k) == "string" then
						local vs = SerializeData(v)

						if vs then
							if type(k) == "number" then
								tinsert(cache, ("[%s] = %s,"):format(tostring(k), vs))
							else
								tinsert(cache, ("%s = %s,"):format(k, vs))
							end
						end
					end
				end

				tinsert(cache, "}")

				local ret = tblconcat(cache, " ")

				CACHE_TABLE(cache)

				return ret
			elseif Reflector.IsNameSpace(data) then
				return Reflector.GetNameSpaceFullName(data)
			else
				-- Don't support any point values
				return nil
			end
		end

		function Serialize(data, ns)
			if type(ns) == "string" then ns = GetNameSpaceForName(ns) end

			if _NSInfo[ns] then
				if Reflector.IsEnum(ns) then
					if _NSInfo[ns].IsFlags and type(data) == "number" then
						local ret = {ns(data)}

						local result = ""

						for i, str in ipairs(ret) do
							if i > 1 then result = result .. " + " end
							result = result .. (tostring(ns) .. "." .. str)
						end

						return result
					else
						local str = ns(data)

						return str and (tostring(ns) .. "." .. str)
					end
				elseif Reflector.IsClass(ns) then
					-- Class handle the serialize itself with __tostring
					return tostring(data)
				elseif Reflector.IsStruct(ns) then
					if Reflector.GetStructType(ns) == "MEMBER" and type(data) == "table" then
						local parts = Reflector.GetStructMembers(ns)

						if not parts or not next(parts) then
							-- Well, what a no member struct can be used for?
							return tostring(ns) .. "( )"
						else
							local ret = tostring(ns) .. "( "

							for i, part in ipairs(parts) do
								local sty = Reflector.GetStructMember(ns, part)
								local value = data[part]

								if sty and #sty == 1 then
									value = Serialize(value, sty[1])
								else
									value = SerializeData(value)
								end

								if i == 1 then
									ret = ret .. tostring(value)
								else
									ret = ret .. ", " .. tostring(value)
								end
							end

							ret = ret .. " )"

							return ret
						end
					elseif Reflector.GetStructType(ns) == "ARRAY" and type(data) == "table" then
						local ret = tostring(ns) .. "( "

						sty = Reflector.GetStructArrayElement(ns)

						if sty and #sty == 1 then
							for i, v in ipairs(data) do
								v = Serialize(v, sty[1])

								if i == 1 then
									ret = ret .. tostring(v)
								else
									ret = ret .. ", " .. tostring(v)
								end
							end
						else
							for i, v in ipairs(data) do
								v = SerializeData(v)

								if i == 1 then
									ret = ret .. tostring(v)
								else
									ret = ret .. ", " .. tostring(v)
								end
							end
						end

						ret = ret .. " )"

						return ret
					elseif type(data) == "table" and type(data.__tostring) == "function" then
						return data:__tostring()
					else
						return SerializeData(data)
					end
				end
			else
				-- Serialize normal datas
				return SerializeData(data)
			end
		end

		doc "ThreadCall" [[
			<desc>Call the function in a thread from the thread pool of the system</desc>
			<param name="func">the function</param>
			<param name="...">the parameters</param>
			<return>the return value of the func</return>
		]]
		ThreadCall = CallThread

		doc "IsEqual" [[
			<desc>Whether the two objects are objects with same settings</desc>
			<param name="obj1">the object used to compare</param>
			<param name="obj2">the object used to compare to</param>
			<return type="boolean">true if the obj1 has same settings with the obj2</return>
		]]
		IsEqual = IsEqual

		doc "Clone" [[
			<desc>Clone the object if possible</desc>
			<param name="obj">the object to be cloned</param>
			<param name="deep" optional="true" type="boolean">whether deep clone</param>
			<return type="object">the clone or the object itself</return>
		]]
		Clone = CloneObj

		doc "GetDefaultValue" [[
			<desc>Get the default value of the target['s part]</desc>
			<param name="ns">the target(class, interface, struct)</param>
			<param name="part" optional="true">the target's part(property, member)</param>
			<return type="object">the default value if existed</return>
		]]
		function GetDefaultValue(ns, part)
			local info = _NSInfo[ns]
			if info then
				if (info.Type == TYPE_CLASS or info.Type == TYPE_INTERFACE) and part then
					part = info.Cache[part]
					if type(part) == "table" and getmetatable(part) == nil and type(part.Default) ~= "function" then
						return part.Default
					end
				elseif info.Type == TYPE_ENUM then
					return info.Default
				elseif info.Type == TYPE_STRUCT then
					if info.SubType == _STRUCT_TYPE_CUSTOM and not part then
						return info.Default
					elseif info.SubType == _STRUCT_TYPE_MEMBER and part then
						return info.DefaultField and info.DefaultField[part]
					end
				end
			end
		end

		doc "GetDefinitionEnvironmentOwner" [[
			<desc>Get the owner from a definition environment</desc>
			<param name="env">The environment like the return of (class "MyCls")</param>
			<return>the owner</return>
		]]
		function GetDefinitionEnvironmentOwner(env)
			if type(env) == "table" then return env[OWNER_FIELD] end
		end

		doc "IsCallable" [[
			<desc>Whether the object is callable(function or table with __call meta-method)</desc>
			<param name="obj">The object need to check</param>
			<return>boolean, true if the object is callable</return>
		]]
		function IsCallable(obj)
			if type(obj) == "function" then return true end
			local cls = GetObjectClass(obj)
			local info = cls and rawget(_NSInfo, cls)

			return info and info.Type == TYPE_CLASS and info.MetaTable.__call and true or false
		end
	end)
end

------------------------------------------------------
-- Local Namespace (Inner classes)
------------------------------------------------------
do
	namespace( nil )

	class "Event" (function(_ENV)
		doc "Event" [[The object event definition]]

		doc "Name" [[The event's name]]
		property "Name" { Type = String, Default = "Anonymous" }

		doc "Delegate" [[The delegate for the event handler, used to wrap the event call]]
		property "Delegate" { Type = Function }

		------------------------------------------------------
		-- Constructor
		------------------------------------------------------
		function Event(self, name)
			if type(name) == "string" then self.Name = name end
		end

		------------------------------------------------------
		-- Meta-Method
		------------------------------------------------------
		function __tostring(self) return ("%s( %q )"):format(tostring(Event), self.Name) end

		function __call(self, owner, ...)
			local handler = rawget(owner, "__Events")
			handler = handler and rawget(handler, self.Name)
			if handler then return handler(owner, ...) end
		end
	end)

	class "EventHandler" (function(_ENV)
		doc "EventHandler" [[The object event handler]]

		local function FireOnEventHandlerChanged(self) return Reflector.FireObjectEvent(self.Owner, "OnEventHandlerChanged", self.Event) end

		------------------------------------------------------
		-- Method
		------------------------------------------------------
		doc "IsEmpty" [[
			<desc>Check if the event handler is empty</desc>
			<return type="boolean">true if the event handler has no functions</return>
		]]
		function IsEmpty(self) return #self == 0 and self[0] == nil end

		doc "Clear" [[Clear all handlers]]
		function Clear(self)
			if #self > 0 or self[0] then
				for i = #self, 1, -1 do self[i] = nil end self[0] = nil
				return FireOnEventHandlerChanged(self)
			end
		end

		doc "Copy" [[
			<desc>Copy handlers from the source event handler</desc>
			<param name="src" type="System.EventHandler">the event handler source</param>
		]]
		function Copy(self, src)
			if self ~= src and getmetatable(src) == EventHandler and self.Event == src.Event then
				for i = #self, 1, -1 do self[i] = nil end self[0] = nil
				for i = #src, 1, -1 do self[i] = src[i] end self[0] = src[0]

				return FireOnEventHandlerChanged(self)
			end
		end

		------------------------------------------------------
		-- Property
		------------------------------------------------------
		doc "Owner" [[The owner of the event handler]]
		property "Owner" { Type = Table }

		doc "Event" [[The event's name]]
		property "Event" { Type = String }

		doc "Blocked" [[Whether the event handler is blocked]]
		property "Blocked" { Type = Boolean }

		doc "Handler" [[The customer's handler]]
		property "Handler" { Field = 0, Type = Function, Handler = FireOnEventHandlerChanged }

		doc "Delegate" [[The delegate for the event handler, used to wrap the event call]]
		property "Delegate" { Type = Function }

		------------------------------------------------------
		-- Constructor
		------------------------------------------------------
		function EventHandler(self, evt, owner)
			self.Event = evt.Name
			self.Owner = owner
			self.Delegate = evt.Delegate
		end

		------------------------------------------------------
		-- Meta-Method
		------------------------------------------------------
		function __add(self, func)
			if type(func) ~= "function" then error("Usage: obj.OnXXXX = obj.OnXXXX + func", 2) end

			for _, f in ipairs(self) do if f == func then return self end end

			tinsert(self, func)
			FireOnEventHandlerChanged(self)

			return self
		end

		function __sub(self, func)
			if type(func) ~= "function" then error("Usage: obj.OnXXXX = obj.OnXXXX - func", 2) end

			for i, f in ipairs(self) do if f == func then tremove(self, i) FireOnEventHandlerChanged(self) break end end

			return self
		end

		local function raiseEvent(self, owner, ...)
			local ret = false

			-- Call the stacked handlers
			for _, handler in ipairs(self) do
				ret = handler(owner, ...) or rawget(owner, "Disposed")

				-- Any handler return true means to stop all
				if ret then break end
			end

			-- Call the custom handler
			return not ret and self[0] and self[0](owner, ...)
		end

		function __call(self, obj, ...)
			if self.Blocked then return end

			local owner = self.Owner
			local delegte = self.Delegate

			if delegte then
				if owner == obj then
					return delegte(raiseEvent, self, obj, ...)
				else
					return delegte(raiseEvent, self, owner, obj, ...)
				end
			else
				if owner == obj then
					return raiseEvent(self, obj, ...)
				else
					return raiseEvent(self, owner, obj, ...)
				end
			end
		end
	end)

	class "FixedMethod" (function(_ENV)
		doc "FixedMethod" [[Used to control method with fixed arguments]]

		-- Find the real next method in class | interface
		local function getNextMethod(ns, name, noFunc, chkSelf)
			local info = _NSInfo[ns]

			if chkSelf and info.Method[name] then return info.Method["0" .. name] or (not noFunc and info.Method[name]) end

			if info.SuperClass then
				local handler = getNextMethod(info.SuperClass, name, noFunc, true)

				if handler then return handler end
			end

			if info.ExtendInterface then
				for _, IF in ipairs(info.ExtendInterface) do
					local handler = getNextMethod(IF, name, noFunc, true)

					if handler then return handler end
				end
			end
		end

		------------------------------------------------------
		-- Method
		------------------------------------------------------
		doc "MatchArgs" [[Whether the fixed method can handler the arguments]]
		function MatchArgs(self, ...)
			-- Check if this is a static method
			if self.HasSelf == nil then
				self.HasSelf = true
				if self.TargetType == AttributeTargets.Method then
					if Reflector.IsInterface(self.Owner) and Reflector.IsFinal(self.Owner) then self.HasSelf = false end
					if Reflector.IsStaticMethod(self.Owner, self.Name) then self.HasSelf = false end
				end
			end

			local base = self.HasSelf and 1 or 0
			local count = select('#', ...) - base
			local argsCount = #self
			local argsChanged = false

			-- Empty methods won't accept any arguments
			if argsCount == 0 then return count == 0 end

			-- Check argument settings
			if count >= self.MinArgs and count <= self.MaxArgs then
				local cache = CACHE_TABLE()

				-- Cache first
				if count == 1 then
					cache[1] = select(1 + base, ...)
				elseif count == 2 then
					cache[1], cache[2] = select(1 + base, ...)
				elseif count == 3 then
					cache[1], cache[2], cache[3] = select(1 + base, ...)
				elseif count == 4 then
					cache[1], cache[2], cache[3], cache[4] = select(1 + base, ...)
				else
					for i = 1, count do cache[i] = select(i + base, ...) end
				end

				-- Required
				for i = 1, self.MinArgs do
					local arg = self[i]
					local value = cache[i]

					if value == nil then
						-- Required argument can't be nil
						return CACHE_TABLE(cache)
					elseif arg.Type then
						-- Clone if needed
						if arg.CloneNeeded then value = CloneObj(value, true) end
						-- Validate the value
						value = GetValidatedValue(arg.Type, value)
						if value == nil then return CACHE_TABLE(cache) end
					end

					if cache[i] ~= value then
						argsChanged = true
						cache[i] = value
					end
				end

				-- Optional
				for i = self.MinArgs + 1, count >= argsCount and count or argsCount do
					local arg = self[i] or self[argsCount]
					local value = cache[i]

					if value == nil then
						-- No check
						if arg.Default ~= nil then value = CloneObj(arg.Default, true) end
					elseif arg.Type then
						-- Clone if needed
						if arg.CloneNeeded then value = CloneObj(value, true) end
						-- Validate the value
						value = GetValidatedValue(arg.Type, value)
						if value == nil then return CACHE_TABLE(cache) end
					end

					if cache[i] ~= value then
						argsChanged = true
						cache[i] = value
					end
				end

				if base == 1 then tinsert(cache, 1, (select(1, ...))) end

				-- Keep arguments waiting for recycle
				if argsChanged then
					self.ArgCache = cache
				else
					CACHE_TABLE(cache)
				end

				return true
			end
		end

		doc "RaiseError" [[Fire the error to show the usage of the fixedMethod link list]]
		function RaiseError(self, obj)
			-- Check if this is a static method
			if self.HasSelf == nil then
				self.HasSelf = true
				if self.TargetType == AttributeTargets.Method then
					if Reflector.IsInterface(self.Owner) and Reflector.IsFinal(self.Owner) then self.HasSelf = false end
					if Reflector.IsStaticMethod(self.Owner, self.Name) then self.HasSelf = false end
				end
			end

			-- Get the root call fixmethod
			if self.TargetType == AttributeTargets.Method then
				if self.HasSelf then
					local cls = getmetatable(obj)

					-- Can't figure out the class method that start the call
					if not cls then error(self.Usage, 2) end

					self = getNextMethod(cls, self.Name, true, true)
				else
					self = getNextMethod(self.Owner, self.Name, true, true)
				end
			else
				local info = _NSInfo[getmetatable(obj)]

				while info and not info.Constructor and info.SuperClass do
					info = _NSInfo[info.SuperClass]
				end

				self = info.Constructor
			end

			-- Generate the usage list
			local usage = CACHE_TABLE()

			while getmetatable(self) do
				local fUsage = self.Usage
				local params = fUsage:match("Usage : %w+.(.+)")

				if params and not usage[params] then
					usage[params] = true
					tinsert(usage, fUsage)
				end

				self = self.Next
			end

			local msg = tblconcat(usage, "\n")
			CACHE_TABLE(usage)

			error(msg, 2)
		end

		------------------------------------------------------
		-- Property
		------------------------------------------------------
		doc "Next" [[The next fixed method]]
		property "Next" {
			Field = "__Next",
			Get = function (self)
				if self.__Next == nil and self.HasSelf then
					if self.TargetType == AttributeTargets.Method then
						self.__Next = getNextMethod(self.Owner, self.Name) or false
						self.IsLast = true
					elseif self.TargetType == AttributeTargets.Constructor then
						local info = _NSInfo[self.Owner]

						while info and info.SuperClass do
							info = _NSInfo[info.SuperClass]

							-- No link for constructor
							if info.Constructor then return info.Constructor end
						end
					end
				end

				return self.__Next or nil
			end,
		}

		doc "Usage" [[The usage of the fixed method]]
		property "Usage" {
			Get = function (self)
				if self.__Usage then return self.__Usage end

				-- Check if this is a static method
				if self.HasSelf == nil then
					self.HasSelf = true
					if self.TargetType == AttributeTargets.Method then
						if Reflector.IsInterface(self.Owner) and Reflector.IsFinal(self.Owner) then self.HasSelf = false end
						if Reflector.IsStaticMethod(self.Owner, self.Name) then self.HasSelf = false end
					end
				end

				-- Generate usage message
				local usage = CACHE_TABLE()
				local name = self.Name
				local owner = self.Owner

				if self.TargetType == AttributeTargets.Method then
					if not self.HasSelf then
						tinsert(usage, "Usage : " .. tostring(owner) .. "." .. name .. "( ")
					else
						tinsert(usage, "Usage : " .. tostring(owner) .. ":" .. name .. "( ")
					end
				else
					tinsert(usage, "Usage : " .. tostring(owner) .. "( ")
				end

				for i = 1, #self do
					local arg = self[i]
					local str = ""

					if i > 1 then tinsert(usage, ", ") end

					-- [name As type = default]
					if arg.Name then
						str = str .. arg.Name

						if arg.Type then str = str .. " As " end
					end

					if arg.Type then str = str .. tostring(arg.Type) end

					if arg.Default ~= nil and i > self.MinArgs then
						local serialize = Reflector.Serialize(arg.Default, arg.Type)

						if serialize then str = str .. " = " .. serialize end
					end

					if not arg.Type or arg.Nilable then str = "[" .. str .. "]" end

					tinsert(usage, str)
				end

				tinsert(usage, " )")

				self.__Usage = tblconcat(usage, "")

				CACHE_TABLE(usage)

				return self.__Usage
			end
		}

		------------------------------------------------------
		-- Constructor
		------------------------------------------------------

		------------------------------------------------------
		-- Meta-methods
		------------------------------------------------------
		function __call(self, ...)
			local matchFunc = self

			-- FixedMethod
			while getmetatable(matchFunc) do
				if matchFunc.ArgCache then
					CACHE_TABLE(matchFunc.ArgCache)
				end
				matchFunc.ArgCache = nil

				if MatchArgs(matchFunc, ...) then
					if matchFunc.ArgCache then
						return matchFunc.Method( unpack(matchFunc.ArgCache) )
					else
						return matchFunc.Method( ... )
					end
				end

				-- Remove argument container
				if matchFunc.ArgCache then
					CACHE_TABLE(matchFunc.ArgCache)
				end
				matchFunc.ArgCache = nil

				matchFunc = matchFunc.Next
			end

			-- Function
			if matchFunc then return matchFunc( ... ) end

			return RaiseError(self, ...)
		end

		function __tostring(self) return self.Usage end
	end)
end

------------------------------------------------------
-- System Namespace (Attribute System)
------------------------------------------------------
do
	namespace "System"

	------------------------------------------------------
	-- Attribute Core
	------------------------------------------------------
	do
		_PreparedAttributes = {}

		-- Recycle the cache for dispose attributes
		_AttributeCache4Dispose = setmetatable({}, {
			__call = function(self, cache)
				if cache then
					for attr in pairs(cache) do
						if getmetatable(attr) then attr:Dispose() end
					end
					wipe(cache)
					tinsert(self, cache)
				else
					return tremove(self) or {}
				end
			end,
		})

		function DisposeAttributes(config)
			if type(config) ~= "table" then return end
			if getmetatable(config) then
				return config:Dispose()
			else
				for _, attr in pairs(config) do DisposeAttributes(attr) end
				return wipe(config)
			end
		end

		function GetTargetAttributes(target, targetType, owner, name, noSuper)
			local info = _NSInfo[owner or target]

			if targetType == AttributeTargets.Event then
				return target.Attribute
			elseif targetType == AttributeTargets.Method then
				if info.Attributes and info.Attributes[name] then
					return info.Attributes[name]
				elseif not noSuper then
					if info.SuperClass and type(_NSInfo[info.SuperClass].Cache[name]) == "function" then
						return GetTargetAttributes(target, targetType, info.SuperClass, name)
					end

					if info.ExtendInterface then
						for _, IF in ipairs(info.ExtendInterface) do
							if type(_NSInfo[IF].Cache[name]) == "function" then
								return GetTargetAttributes(target, targetType, IF, name)
							end
						end
					end
				end
			elseif targetType == AttributeTargets.Property then
				local pInfo = info.Cache[name]
				return type(pInfo) == "table" and not getmetatable(pInfo) and pInfo.Attribute or nil
			elseif targetType == AttributeTargets.Member then
				if info.SubType == _STRUCT_TYPE_MEMBER then
					return info.Attributes and info.Attributes[name]
				elseif info.SubType == _STRUCT_TYPE_ARRAY then
					return info.ElementAttribute
				end
			elseif targetType ~= AttributeTargets.Constructor then
				return info.Attribute
			end
		end

		function GetSuperAttributes(target, targetType, owner, name)
			local info = _NSInfo[owner or target]

			if targetType == AttributeTargets.Event then
				if info.SuperClass and getmetatable(_NSInfo[info.SuperClass].Cache[name]) then
					return _NSInfo[info.SuperClass].Cache[name].Attribute
				end

				if info.ExtendInterface then
					for _, IF in ipairs(info.ExtendInterface) do
						if getmetatable(_NSInfo[IF].Cache[name]) then
							return _NSInfo[IF].Cache[name].Attribute
						end
					end
				end
			elseif targetType == AttributeTargets.Method then
				if info.SuperClass and type(_NSInfo[info.SuperClass].Cache[name]) == "function" then
					return GetTargetAttributes(nil, targetType, info.SuperClass, name)
				end

				if info.ExtendInterface then
					for _, IF in ipairs(info.ExtendInterface) do
						if type(_NSInfo[IF].Cache[name]) == "function" then
							return GetTargetAttributes(nil, targetType, IF, name)
						end
					end
				end
			elseif targetType == AttributeTargets.Property then
				if info.SuperClass then
					local tar = _NSInfo[info.SuperClass].Cache[name]
					return type(tar) == "table" and not getmetatable(tar) and GetTargetAttributes(nil, targetType, info.SuperClass, name)
				end

				if info.ExtendInterface then
					for _, IF in ipairs(info.ExtendInterface) do
						local tar = _NSInfo[IF].Cache[name]
						if type(tar) == "table" and not getmetatable(tar) then
							return GetTargetAttributes(nil, targetType, IF, name)
						end
					end
				end
			elseif targetType == AttributeTargets.Class then
				if info.SuperClass then
					return _NSInfo[info.SuperClass].Attribute
				end
			end
		end

		function SaveTargetAttributes(target, targetType, owner, name, config)
			local info = _NSInfo[owner or target]

			if targetType == AttributeTargets.Event then
				target.Attribute = config
			elseif targetType == AttributeTargets.Method then
				if config then
					info.Attributes = info.Attributes or {}
					info.Attributes[name] = config
				elseif info.Attributes then
					info.Attributes[name] = nil
				end
			elseif targetType == AttributeTargets.Property then
				local pInfo = info.Property[name]
				if pInfo then pInfo.Attribute = config end
			elseif targetType == AttributeTargets.Member then
				if info.SubType == _STRUCT_TYPE_MEMBER then
					if config then
						info.Attributes = info.Attributes or {}
						info.Attributes[name] = config
					elseif info.Attributes then
						info.Attributes[name] = nil
					end
				elseif info.SubType == _STRUCT_TYPE_ARRAY then
					info.ElementAttribute = config
				end
			elseif targetType ~= AttributeTargets.Constructor then
				info.Attribute = config
			else
				DisposeAttributes(config)
			end
		end

		function GetAttributeUsage(target)
			local config = GetTargetAttributes(target, AttributeTargets.Class)

			if not config then
				return
			elseif getmetatable(config) then
				return getmetatable(config) == __AttributeUsage__ and config or nil
			else
				for _, attr in ipairs(config) do if getmetatable(attr) == __AttributeUsage__ then return attr end end
			end
		end

		function ParseAttributeTarget(target, targetType, owner, name)
			if targetType == AttributeTargets.Class then
				return "[Class]" .. tostring(target)
			elseif targetType == AttributeTargets.Constructor then
				return "[Class.Constructor]" .. tostring(owner)
			elseif targetType == AttributeTargets.Enum then
				return "[Enum]" .. tostring(target)
			elseif targetType == AttributeTargets.Event then
				return "[Class]" .. tostring(owner) .. " [Event]" .. tostring(target.Name)
			elseif targetType == AttributeTargets.Interface then
				return "[Interface]" .. tostring(target)
			elseif targetType == AttributeTargets.Method then
				if Reflector.IsClass(owner) then
					return "[Class]" .. tostring(owner) .. " [Method]" .. tostring(name or "anonymous")
				elseif Reflector.IsInterface(owner) then
					return "[Interface]" .. tostring(owner) .. " [Method]" .. tostring(name or "anonymous")
				else
					return "[Method]" .. tostring(name or "anonymous")
				end
			elseif targetType == AttributeTargets.Property then
				if Reflector.IsClass(owner) then
					return "[Class]" .. tostring(owner) .. " [Property]" .. tostring(target.Name  or "anonymous")
				elseif Reflector.IsInterface(owner) then
					return "[Interface]" .. tostring(owner) .. " [Property]" .. tostring(target.Name  or "anonymous")
				else
					return "[Property]" .. tostring(target.Name  or "anonymous")
				end
			elseif targetType == AttributeTargets.Struct then
				return "[Struct]" .. tostring(target)
			elseif targetType == AttributeTargets.Member then
				return "[Struct]" .. tostring(owner) .. " [Field]" .. tostring(name)
			elseif targetType == AttributeTargets.NameSpace then
				return "[NameSpace]" .. tostring(target)
			end
		end

		function ValidateAttributeUsable(config, attr, skipMulti, chkOverride)
			local cls = getmetatable(config)
			if cls then
				if cls == getmetatable(attr) then
					local usage = GetAttributeUsage(cls)
					if chkOverride and usage and usage.Overridable then return true end
					if IsEqual(config, attr) then return false end
					if not skipMulti and (not usage or not usage.AllowMultiple) then return false end
				end
			else
				for _, v in ipairs(config) do if not ValidateAttributeUsable(v, attr, skipMulti, chkOverride) then return false end end
			end

			return true
		end

		function ApplyAttributes(target, targetType, owner, name, start, config, halt, atLast)
			if halt and atLast then _NSInfo[target].ApplyAttributes = nil end

			-- Check config
			config = config or GetTargetAttributes(target, targetType, owner, name)

			-- Clear
			SaveTargetAttributes(target, targetType, owner, name, nil)

			-- Apply the attributes
			if config then
				local oldTarget = target
				local ok, ret, arg1, arg2, arg3, arg4
				local hasAfter = false

				-- Some target can't be send to the attribute's ApplyAttribute directly
				if targetType == AttributeTargets.Event then
					arg1 = target.Name
					arg2 = targetType
					arg3 = owner
					arg4 = target.Name
				elseif targetType == AttributeTargets.Method then
					arg1 = getmetatable(target) and target.Method or target
					arg2 = targetType
					arg3 = owner
					arg4 = name
				elseif targetType == AttributeTargets.Property then
					arg1 = target.Predefined
					arg2 = targetType
					arg3 = owner
					arg4 = name
				elseif targetType == AttributeTargets.Member then
					arg1 = name
					arg2 = targetType
					arg3 = owner
					arg4 = name
				elseif targetType == AttributeTargets.Constructor then
					arg1 = getmetatable(target) and target.Method or target
					arg2 = targetType
					arg3 = owner
					arg4 = name
				else
					arg1 = target
					arg2 = targetType
				end

				if getmetatable(config) then
					local usage = GetAttributeUsage(getmetatable(config))
					if not halt or atLast or (usage and usage.BeforeDefinition) then
						ok, ret = pcall(config.ApplyAttribute, config, arg1, arg2, arg3, arg4)

						if not ok then
							errorhandler(ret)

							config:Dispose()
							config = nil
						else
							if usage and not usage.Inherited and usage.RunOnce then
								config:Dispose()
								config = nil
							end

							if targetType == AttributeTargets.Method or targetType == AttributeTargets.Constructor then
								-- The method may be wrapped in the apply operation
								if ret and ret ~= target and (type(ret) == "function" or getmetatable(ret) == FixedMethod) then
									if getmetatable(target) then
										if getmetatable(ret) then
											target = ret
										else
											target.Method = ret
										end
									else
										target = ret
									end
								end
							end
						end
					else
						hasAfter = true
					end
				else
					start = start or 1

					for i = #config, start, -1 do
						local usage = GetAttributeUsage(getmetatable(config[i]))

						if not halt or (not atLast and usage and usage.BeforeDefinition) or (atLast and (not usage or not usage.BeforeDefinition)) then
							ok, ret = pcall(config[i].ApplyAttribute, config[i], arg1, arg2, arg3, arg4)

							if not ok then
								tremove(config, i):Dispose()
								errorhandler(ret)
							else
								if usage and not usage.Inherited and usage.RunOnce then
									tremove(config, i):Dispose()
								end

								if targetType == AttributeTargets.Method or targetType == AttributeTargets.Constructor then
									-- The method may be wrapped in the apply operation
									if ret and ret ~= target and (type(ret) == "function" or getmetatable(ret) == FixedMethod) then
										if getmetatable(target) then
											if getmetatable(ret) then
												target = ret
												arg1 = target.Method
											else
												target.Method = ret
											end
										else
											target = ret
										end
									end
								end
							end
						else
							hasAfter = true
						end
					end

					if #config == 0 or #config == 1 then config = config[1] or nil end
				end

				if halt and hasAfter then
					_NSInfo[target].ApplyAttributes = function()
						return ApplyAttributes(target, targetType, owner, name, start, config, true, true)
					end
				end
			end

			SaveTargetAttributes(target, targetType, owner, name, config)

			return target
		end

		function SendAttributeToPrepared(self)
			-- Send to prepared cache
			local prepared = _PreparedAttributes

			for i, v in ipairs(prepared) do if v == self then return end end

			tinsert(prepared, self)
		end

		function RemoveAttributeToPrepared(self)-- Send to prepared cache
			local prepared = _PreparedAttributes

			for i, v in ipairs(prepared) do if v == self then return tremove(prepared, i) end end
		end

		function ClearPreparedAttributes(noDispose)
			local prepared = _PreparedAttributes

			if not noDispose then
				for _, attr in ipairs(prepared) do attr:Dispose() end
			end
			wipe(prepared)
		end

		function ConsumePreparedAttributes(target, targetType, owner, name)
			owner = owner or target

			-- Consume the prepared Attributes
			local prepared = _PreparedAttributes

			-- Filter with the usage
			if #prepared > 0 then
				local cls, usage
				local noUseAttr = _AttributeCache4Dispose()
				local usableAttr = _AttributeCache4Dispose()

				for i = 1, #prepared do
					local attr = prepared[i]
					cls = getmetatable(attr)
					usage = GetAttributeUsage(cls)

					if usage and usage.AttributeTarget > 0 and not Reflector.ValidateFlags(targetType, usage.AttributeTarget) then
						errorhandler("Can't apply the " .. tostring(cls) .. " attribute to the " .. ParseAttributeTarget(target, targetType, owner, name))
					elseif ValidateAttributeUsable(usableAttr, attr) then
						usableAttr[attr] = true
						tinsert(usableAttr, attr)
					else
						errorhandler("Can't apply the " .. tostring(cls) .. " attribute for multi-times.")
					end
				end

				for i = #prepared, 1, -1 do
					local attr = prepared[i]
					if not usableAttr[attr] then
						noUseAttr[tremove(prepared, i)] = true
					end
				end

				wipe(usableAttr)
				_AttributeCache4Dispose(usableAttr)
				_AttributeCache4Dispose(noUseAttr)
			end

			-- Check if already existed
			local pconfig = GetTargetAttributes(target, targetType, owner, name, true)

			if pconfig then
				if #prepared > 0 then
					local noUseAttr = _AttributeCache4Dispose()

					-- remove equal attributes
					for i = #prepared, 1, -1 do
						if not ValidateAttributeUsable(pconfig, prepared[i], true, true) then
							noUseAttr[tremove(prepared, i)] = true
						end
					end

					_AttributeCache4Dispose(noUseAttr)

					if prepared and #prepared > 0 then
						-- Erase old no-multi attributes
						if getmetatable(pconfig) then
							if not ValidateAttributeUsable(prepared, pconfig) then
								SaveTargetAttributes(target, targetType, owner, name, nil)
								pconfig:Dispose()
							end
						else
							for i = #pconfig, 1, -1 do
								if not ValidateAttributeUsable(prepared, pconfig[i]) then
									tremove(pconfig, i):Dispose()
								end
							end

							if #pconfig == 0 then SaveTargetAttributes(target, targetType, owner, name, nil) end
						end
					end
				end
			else
				local sconfig = GetSuperAttributes(target, targetType, owner, name)
				if sconfig then
					-- get inheritable attributes from superTarget
					local usage

					if getmetatable(sconfig) then
						usage = GetAttributeUsage(getmetatable(sconfig))

						if not usage or usage.Inherited then
							if ValidateAttributeUsable(prepared, sconfig) then sconfig:Clone() end
						end
					else
						for _, attr in ipairs(sconfig) do
							usage = GetAttributeUsage(getmetatable(attr))

							if not usage or usage.Inherited then
								if ValidateAttributeUsable(prepared, attr) then attr:Clone() end
							end
						end
					end
				end
			end

			-- Save & apply the attributes for target
			if #prepared > 0 then
				local start = 1
				local config = nil

				if pconfig then
					config = pconfig

					if getmetatable(config) then config = { config } end

					start = #config + 1

					for _, attr in ipairs(prepared) do tinsert(config, attr) end

				else
					if #prepared == 1 then
						config = prepared[1]
					else
						config = { unpack(prepared) }
					end
				end

				wipe(prepared)

				if targetType == AttributeTargets.Interface or targetType == AttributeTargets.Struct or targetType == AttributeTargets.Class then
					ApplyAttributes(target, targetType, owner, name, start, config, true)
				else
					target = ApplyAttributes(target, targetType, owner, name, start, config) or target
				end
			end

			ClearPreparedAttributes()

			return target
		end

		function InheritAttributes(source, target, targetType)
			if source == target then return end

			local sconfig = GetTargetAttributes(source, targetType)

			-- Save & apply the attributes for target
			if sconfig then
				local config = GetTargetAttributes(target, targetType)
				local hasAttr = false

				-- Check existed attributes
				if getmetatable(sconfig) then
					if config and not ValidateAttributeUsable(config, sconfig) then return end

					sconfig:Clone()
					hasAttr = true
				else
					for i = 1, #sconfig do
						if not config or ValidateAttributeUsable(config, sconfig[i]) then
							sconfig[i]:Clone()
							hasAttr = true
						end
					end
				end

				return hasAttr and ConsumePreparedAttributes(target, targetType)
			end
		end
	end

	------------------------------------------------------
	-- System.__Attribute__
	------------------------------------------------------
	class "__Attribute__" (function(_ENV)

		doc "__Attribute__" [[The __Attribute__ class associates predefined system information or user-defined custom information with a target element.]]

		doc "ApplyAttribute" [[
			<desc>Apply the attribute to the target, overridable</desc>
			<param name="target">the attribute's target</param>
			<param name="targetType" type="System.AttributeTargets">the target's type</param>
			<param name="owner">the target's owner</param>
			<param name="name">the target's name</param>
			<return>the target, also can be modified</return>
		]]
		function ApplyAttribute(self, target, targetType, owner, name)
			-- Pass
		end

		doc [[Remove self from the prepared attributes]]
		RemoveSelf = RemoveAttributeToPrepared

		doc [[Creates a copy of the attribute.]]
		function Clone(self)
			-- Defualt behavior
			local cache = CACHE_TABLE()

			for name, prop in pairs(_NSInfo[getmetatable(self)].Cache) do
				if type(prop) == "table" and not getmetatable(prop) and (prop.Get or prop.GetMethod or prop.Field) and (prop.Set or prop.SetMethod or prop.Field) then
					cache[name] = self[name]
				end
			end

			-- Clone
			local obj = getmetatable(self)(cache)

			CACHE_TABLE(cache)

			return obj
		end

		------------------------------------------------------
		-- Constructor
		------------------------------------------------------
		__Attribute__ = SendAttributeToPrepared
	end)

	-- Attribute system OnLine
	ATTRIBUTE_INSTALLED = true

	class "__Unique__" (function(_ENV)
		inherit "__Attribute__"

		doc "__Unique__" [[Mark the class will only create one unique object, and can't be disposed, also the class can't be inherited]]

		function ApplyAttribute(self, target, targetType)
			if Reflector.IsClass(target) then
				_NSInfo[target].IsFinal = true
				_NSInfo[target].UniqueObject = true
			end
		end
	end)

	class "__Flags__" (function(_ENV)
		inherit "__Attribute__"

		doc "__Flags__" [[Indicates that an enumeration can be treated as a bit field; that is, a set of flags.]]

		function ApplyAttribute(self, target, targetType)
			if Reflector.IsEnum(target) then
				_NSInfo[target].IsFlags = true

				local enums = _NSInfo[target].Enum

				local cache = {}
				local count = 0
				local firstZero = true

				-- Count and clear
				for k, v in pairs(enums) do
					if v == 0 and firstZero then
						-- Only one may keep zero
						firstZero = false
					else
						cache[2^count] = true
						count = count + 1

						enums[k] = tonumber(v) or -1
						if enums[k] == 0 then enums[k] = -1 end
					end
				end

				_NSInfo[target].MaxValue = 2^count - 1

				-- Scan the existed bit values
				for k, v in pairs(enums) do
					if cache[v] == true then
						cache[v] = k
					elseif v ~= 0 then
						enums[k] = -1
					end
				end

				-- Apply the bit values
				local index = 0

				for k, v in pairs(enums) do
					if v == -1 then
						while cache[2^index] and cache[2^index] ~= true do
							index = index + 1
						end

						if cache[2^index] == true then
							cache[2^index] = k
							enums[k] = 2^index

							index = index + 1
						else
							error("There is something wrong")
						end
					end
				end
			end
		end
	end)

	class "__AttributeUsage__" (function(_ENV)
		inherit "__Attribute__"

		doc "__AttributeUsage__" [[Specifies the usage of another attribute class.]]

		------------------------------------------------------
		-- Property
		------------------------------------------------------
		doc "AttributeTarget" [[The attribute target type, default AttributeTargets.All]]
		property "AttributeTarget" { Default = AttributeTargets.All, Type = AttributeTargets }

		doc "Inherited" [[Whether your attribute can be inherited by classes that are derived from the classes to which your attribute is applied. Default true]]
		property "Inherited" { Default = true, Type = Boolean }

		doc "AllowMultiple" [[whether multiple instances of your attribute can exist on an element. default false]]
		property "AllowMultiple" { Type = Boolean }

		doc "RunOnce" [[Whether the property only apply once, when the Inherited is false, and the RunOnce is true, the attribute will be removed after apply operation]]
		property "RunOnce" { Type = Boolean }

		doc "BeforeDefinition" [[Whether the ApplyAttribute method is running before the feature's definition, only works on class, interface and struct.]]
		property "BeforeDefinition" { Type = Boolean }

		doc "" [[Whether the attribute can be override, default false.]]
		property "Overridable" { Type = Boolean }
	end)

	class "__Sealed__" (function(_ENV)
		inherit "__Attribute__"

		doc "__Sealed__" [[Mark the feature to be sealed, and can't be re-defined again]]

		function ApplyAttribute(self, target, targetType)
			_NSInfo[target].IsSealed = true
		end
	end)

	class "__Final__" (function(_ENV)
		inherit "__Attribute__"

		doc "__Final__" [[Mark the class|interface can't be inherited, or method|property can't be overridden by child-classes]]

		function ApplyAttribute(self, target, targetType, owner, name)
			if targetType == AttributeTargets.Interface or targetType == AttributeTargets.Class then
				_NSInfo[target].IsFinal = true
			elseif _NSInfo[owner].Type == TYPE_INTERFACE or _NSInfo[owner].Type == TYPE_CLASS then
				_NSInfo[owner].FinalFeatures = _NSInfo[owner].FinalFeatures or {}
				_NSInfo[owner].FinalFeatures[name] = true
			end
		end
	end)

	struct "Argument" (function(_ENV)
		Type = AnyType
		Nilable = Boolean
		Default = Any
		Name = String
		IsList = Boolean
		CloneNeeded = Boolean

		local function isCloneNeeded(ns)
			if not ns then return false end

			local info = _NSInfo[ns]

			if info and info.Type == TYPE_STRUCT then
				if info.SubType == _STRUCT_TYPE_MEMBER then
					if info.Validator then return true end

					if info.Members then
						for _, n in ipairs(info.Members) do
							if isCloneNeeded(info.StructEnv[n]) then return true end
						end
					end
				elseif info.SubType == _STRUCT_TYPE_ARRAY then
					return isCloneNeeded(info.ArrayElement)
				elseif info.SubType == _STRUCT_TYPE_CUSTOM and info.Validator then
					return true
				end
			end

			return false
		end

		function Argument(value)
			if value.Type and value.Default ~= nil then
				value.Default = GetValidatedValue(value.Type, value.Default)
			end

			-- Whether the value should be clone, argument match would change some value, Just for safe
			value.CloneNeeded = isCloneNeeded(value.Type)
		end
	end)

	class "__Arguments__" (function(_ENV)
		inherit "__Attribute__"

		doc "__Arguments__" [[The argument definitions of the target method or class's constructor]]

		_Error_Header = [[Usage : __Arguments__{ arg1[, arg2[, ...] ] } : ]]
		_Error_NotArgument = [[arg%d must be System.Argument]]
		_Error_NotOptional = [[arg%d must also be optional]]
		_Error_NotList = [[arg%d can't be a list]]

		local function ValidateArgument(self, i)
			local ok, arg = pcall(Argument, self[i])

			if ok then
				self[i] = arg

				-- Check ... args
				if arg.IsList then
					if i == #self then
						if self.MinArgs then
							error(_Error_Header .. _Error_NotList:format(i))
						else
							if not arg.Type or arg.Nilable then
								self.MinArgs = i - 1
							else
								-- Must have one parameter at least
								self.MinArgs = i
							end

							-- Just big enough
							self.MaxArgs = 9999

							arg.Name = "..."
						end
					else
						error(_Error_Header .. _Error_NotList:format(i))
					end
				elseif not arg.Type or arg.Nilable then
					if not self.MinArgs then self.MinArgs = i - 1 end
				elseif self.MinArgs then
					-- Only optional args can be defined after optional args
					error(_Error_Header .. _Error_NotOptional:format(i))
				end

				-- Auto generate Default
				if arg.Default == nil and arg.Type and arg.Nilable then
					local info = _NSInfo[arg.Type]
					if info and (info.Type == TYPE_STRUCT or info.Type == TYPE_ENUM) then arg.Default = info.Default end
				end

				return
			end

			error(_Error_Header .. _Error_NotArgument:format(i))
		end

		------------------------------------------------------
		-- Method
		------------------------------------------------------
		function ApplyAttribute(self, target, targetType, owner, name)
			-- Self validation once
			for i = 1, #self do ValidateArgument(self, i) end

			self.Owner = owner
			self.TargetType = targetType
			self.Name = name

			-- Quick match
			if not self.MinArgs then self.MinArgs = #self end
			if not self.MaxArgs then self.MaxArgs = #self end

			-- Save self to fixedmethod object
			local fixedObj = FixedMethod()

			for k, v in pairs(self) do fixedObj[k] = v end

			fixedObj.Method = target

			wipe(self)

			return fixedObj
		end

		------------------------------------------------------
		-- Constructor
		------------------------------------------------------
		function __Arguments__(self)
			wipe(self)

			return Super(self)
		end
	end)

	-- Apply Attribute to the previous definitions, since I can't use them before definition
	do
		------------------------------------------------------
		-- For structs
		------------------------------------------------------
		__Sealed__:ApplyAttribute(Boolean)
		__Sealed__:ApplyAttribute(String)
		__Sealed__:ApplyAttribute(Number)
		__Sealed__:ApplyAttribute(Function)
		__Sealed__:ApplyAttribute(Table)
		__Sealed__:ApplyAttribute(Userdata)
		__Sealed__:ApplyAttribute(Thread)
		__Sealed__:ApplyAttribute(Any)
		__Sealed__:ApplyAttribute(Callable)
		__Sealed__:ApplyAttribute(Class)
		__Sealed__:ApplyAttribute(Interface)
		__Sealed__:ApplyAttribute(Struct)
		__Sealed__:ApplyAttribute(Enum)
		__Sealed__:ApplyAttribute(AnyType)

		__Sealed__:ApplyAttribute(Argument)

		------------------------------------------------------
		-- For Attribute system
		------------------------------------------------------
		-- System.AttributeTargets
		__Flags__:ApplyAttribute(AttributeTargets)
		__Sealed__:ApplyAttribute(AttributeTargets)

		-- System.__Attribute__
		__Arguments__()
		SaveFixedMethod(_NSInfo[__Attribute__], "Constructor", _NSInfo[__Attribute__].Constructor, __Attribute__, AttributeTargets.Constructor)

		-- System.__Unique__
		__AttributeUsage__{AttributeTarget = AttributeTargets.Class, Inherited = false, RunOnce = true, BeforeDefinition = true}
		ConsumePreparedAttributes(__Unique__, AttributeTargets.Class)
		__Unique__:ApplyAttribute(__Unique__)
		__Sealed__:ApplyAttribute(__Unique__)

		-- System.__Flags__
		__AttributeUsage__{AttributeTarget = AttributeTargets.Enum, Inherited = false, RunOnce = true}
		ConsumePreparedAttributes(__Flags__, AttributeTargets.Class)
		__Unique__:ApplyAttribute(__Flags__)
		__Sealed__:ApplyAttribute(__Flags__)

		-- System.__AttributeUsage__
		__AttributeUsage__{AttributeTarget = AttributeTargets.Class, Inherited = false}
		ConsumePreparedAttributes(__AttributeUsage__, AttributeTargets.Class)
		__Sealed__:ApplyAttribute(__AttributeUsage__)
		__Final__:ApplyAttribute(__AttributeUsage__, AttributeTargets.Class)

		-- System.__Sealed__
		__AttributeUsage__{AttributeTarget = AttributeTargets.Class + AttributeTargets.Interface + AttributeTargets.Struct + AttributeTargets.Enum, Inherited = false, RunOnce = true}
		ConsumePreparedAttributes(__Sealed__, AttributeTargets.Class)
		__Unique__:ApplyAttribute(__Sealed__)
		__Sealed__:ApplyAttribute(__Sealed__)

		-- System.__Final__
		__AttributeUsage__{AttributeTarget = AttributeTargets.Class + AttributeTargets.Interface + AttributeTargets.Method + AttributeTargets.Property, Inherited = false, RunOnce = true, BeforeDefinition = true}
		ConsumePreparedAttributes(__Final__, AttributeTargets.Class)
		__Unique__:ApplyAttribute(__Final__)
		__Sealed__:ApplyAttribute(__Final__)

		-- System.__Arguments__
		__Sealed__:ApplyAttribute(__Arguments__)
		__Unique__:ApplyAttribute(__Arguments__)
		__AttributeUsage__{AttributeTarget = AttributeTargets.Method + AttributeTargets.Constructor, Inherited = false, RunOnce = true }
		ConsumePreparedAttributes(__Arguments__, AttributeTargets.Class)
		__Arguments__()
		SaveFixedMethod(_NSInfo[__Arguments__], "Constructor", _NSInfo[__Arguments__].Constructor, __Arguments__, AttributeTargets.Constructor)

		------------------------------------------------------
		-- For other classes
		------------------------------------------------------
		-- System.Reflector
		__Sealed__:ApplyAttribute(Reflector)
		__Final__:ApplyAttribute(Reflector, AttributeTargets.Interface)

		-- Event
		__Sealed__:ApplyAttribute(Event)
		__Final__:ApplyAttribute(Event, AttributeTargets.Class)

		-- EventHandler
		__Sealed__:ApplyAttribute(EventHandler)
		__Final__:ApplyAttribute(EventHandler, AttributeTargets.Class)

		-- FixedMethod
		__Sealed__:ApplyAttribute(FixedMethod)
		__Final__:ApplyAttribute(FixedMethod, AttributeTargets.Class)
	end

	-- More usable attributes
	__AttributeUsage__{AttributeTarget = AttributeTargets.Event + AttributeTargets.Method, Inherited = false, RunOnce = true}
	__Sealed__() __Unique__()
	class "__Delegate__" (function(_ENV)
		inherit "__Attribute__"
		doc "__Delegate__" [[Wrap the method/event call in a delegate function]]

		------------------------------------------------------
		-- Property
		------------------------------------------------------
		doc "Delegate" [[The delegate function]]
		property "Delegate" { Type = Function }

		------------------------------------------------------
		-- Method
		------------------------------------------------------
		function ApplyAttribute(self, target, targetType, owner, name)
			local delegate = self.Delegate
			if not delegate then return end

			if targetType == AttributeTargets.Method then
				if type(target) == "function" then
					-- Wrap the target method
					return function (...) return delegate(target, ...) end
				end
			elseif targetType == AttributeTargets.Event then
				_NSInfo[owner].Event[target].Delegate = delegate
			end

			self.Delegate = nil
		end

		------------------------------------------------------
		-- Constructor
		------------------------------------------------------
		__Arguments__{}
		function __Delegate__(self)
			self.Delegate = nil
			return Super(self)
		end

		__Arguments__{ Function }
		function __Delegate__(self, value)
			self.Delegate = value
			return Super(self)
		end
	end)

	__AttributeUsage__{AttributeTarget = AttributeTargets.Class + AttributeTargets.Method + AttributeTargets.Interface, Inherited = false, RunOnce = true}
	__Sealed__() __Unique__()
	class "__Cache__" (function(_ENV)
		inherit "__Attribute__"
		doc "__Cache__" [[Mark the class so its objects will cache any methods they accessed, mark the method so the objects will cache the method when they are created, if using on an interface, all object methods defined in it would be marked with __Cache__ attribute .]]

		function ApplyAttribute(self, target, targetType, owner, name)
			if targetType == AttributeTargets.Class or targetType == AttributeTargets.Interface then
				_NSInfo[target].AutoCache = true
			elseif Reflector.IsClass(owner) or Reflector.IsInterface(owner) then
				local info = _NSInfo[owner]
				if info.AutoCache == true then return end

				if not info.AutoCache then info.AutoCache = {} end
				info.AutoCache[name] = true
			end
		end
	end)

	enum "StructType" {
		"MEMBER",
		"ARRAY",
		"CUSTOM"
	}

	__AttributeUsage__{AttributeTarget = AttributeTargets.Struct, Inherited = false, RunOnce = true, BeforeDefinition = true}
	__Sealed__() __Unique__()
	class "__StructType__" (function(_ENV)
		inherit "__Attribute__"

		doc "__StructType__" [[Mark the struct's type, default 'Member']]

		------------------------------------------------------
		-- Method
		------------------------------------------------------
		function ApplyAttribute(self, target, targetType)
			if Reflector.IsStruct(target) then
				local info = _NSInfo[target]

				if self.Type == StructType.Member then
					-- use member list, default type
					info.SubType = _STRUCT_TYPE_MEMBER
					info.ArrayElement = nil
				elseif self.Type == StructType.Array then
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
		end

		------------------------------------------------------
		-- Property
		------------------------------------------------------
		doc "Type" [[The struct's type]]
		property "Type" { Type = StructType }

		------------------------------------------------------
		-- Constructor
		------------------------------------------------------
		__Arguments__{ StructType }
		function __StructType__(self, type)
			Super(self)

			self.Type = type
		end

		__Arguments__{ }
		function __StructType__(self)
			Super(self)

			self.Type = StructType.Member
		end
	end)

	__AttributeUsage__{AttributeTarget = AttributeTargets.Struct, Inherited = false, RunOnce = true}
	__Sealed__()
	class "__StructOrder__" (function(_ENV)
		inherit "__Attribute__"

		doc "__StructOrder__" [[Rearrange the struct member's order]]

		------------------------------------------------------
		-- Method
		------------------------------------------------------
		function ApplyAttribute(self, target, targetType)
			local info = _NSInfo[target]

			if info.SubType == StructType.Member and info.Members then
				local cache = CACHE_TABLE()

				for i, mem in ipairs(info.Members) do tinsert(cache, mem) cache[mem] = i end
				wipe(info.Members)

				for i, mem in ipairs(self) do if cache[mem] then tinsert(info.Members, mem) cache[mem] = nil end end
				for i, mem in ipairs(cache) do if cache[mem] then tinsert(info.Members, mem) end end

				CACHE_TABLE(cache)
			end
		end

		------------------------------------------------------
		-- Constructor
		------------------------------------------------------
		__Arguments__ { String }
	    function __StructOrder__(self, name)
	    	Super(self)
	    	tinsert(self, name)
	    end

	    function __call(self, name)
	    	if type(name) == "string" then
	    		tinsert(self, name)
	    	end
	    	return self
	    end
	end)

	__AttributeUsage__{AttributeTarget = AttributeTargets.Class, Inherited = false, RunOnce = true, BeforeDefinition = true}
	__Sealed__() __Unique__()
	class "__Abstract__" (function(_ENV)
		inherit "__Attribute__"
		doc "__Abstract__" [[Mark the class as abstract class, can't be used to create objects.]]

		function ApplyAttribute(self, target, targetType)
			if _NSInfo[target] then _NSInfo[target].AbstractClass = true end
		end
	end)

	__AttributeUsage__{AttributeTarget = AttributeTargets.Class, Inherited = false, RunOnce = true}
	__Sealed__() __Unique__()
	class "__InitTable__" (function(_ENV)
		inherit "__Attribute__"

		doc "__InitTable__" [[Used to mark the class can use init table like: obj = cls(name) { Age = 123 }]]

		__Arguments__{ RawTable }
		function InitWithTable(self, initTable)
			for name, value in pairs(initTable) do self[name] = value end

			return self
		end

		function ApplyAttribute(self, target, targetType)
			if _NSInfo[target] and _NSInfo[target].Type == TYPE_CLASS then
				SaveFixedMethod(_NSInfo[target].MetaTable, "__call", __InitTable__["InitWithTable"], target)
			end
		end
	end)

	__AttributeUsage__{AttributeTarget = AttributeTargets.Method + AttributeTargets.Property + AttributeTargets.Member, Inherited = false, RunOnce = true}
	__Sealed__() __Unique__()
	class "__Require__" (function(_ENV)
		inherit "__Attribute__"

		doc "__Require__" [[Whether the method or property is required to be override, or a member of a struct is required.]]

		------------------------------------------------------
		-- Method
		------------------------------------------------------
		function ApplyAttribute(self, target, targetType, owner, name)
			local info = _NSInfo[owner]

			if info and type(name) == "string" then
				if targetType == AttributeTargets.Method then
					info.RequireMethod = info.RequireMethod or {}
					info.RequireMethod[name] = true
				elseif targetType == AttributeTargets.Property then
					info.RequireProperty = info.RequireProperty or {}
					info.RequireProperty[name] = true
				elseif targetType == AttributeTargets.Member then
					info.RequireMember = info.RequireMember or {}
					info.RequireMember[name] = true
				end
			end
		end
	end)

	__AttributeUsage__{AttributeTarget = AttributeTargets.Method + AttributeTargets.Property, Inherited = false, RunOnce = true}
	__Sealed__() __Unique__()
	class "__Optional__" (function(_ENV)
		inherit "__Attribute__"

		doc "__Optional__" [[Whether the method or property is optional to be override]]

		------------------------------------------------------
		-- Method
		------------------------------------------------------
		function ApplyAttribute(self, target, targetType, owner, name)
			local info = _NSInfo[owner]

			if info and type(name) == "string" then
				if targetType == AttributeTargets.Method then
					info.OptionalMethod = info.OptionalMethod or {}
					info.OptionalMethod[name] = true
				elseif targetType == AttributeTargets.Property then
					info.OptionalProperty = info.OptionalProperty or {}
					info.OptionalProperty[name] = true
				end
			end
		end
	end)

	__AttributeUsage__{AttributeTarget = AttributeTargets.Property, Inherited = false, RunOnce = true}
	__Sealed__() __Unique__()
	class "__Synthesize__" (function(_ENV)
		inherit "__Attribute__"

		doc "__Synthesize__" [[Used to generate property accessors automatically]]

		enum "NameCases" {
			"Camel",	-- setName
			"Pascal",	-- SetName
		}

		------------------------------------------------------
		-- Property
		------------------------------------------------------
		doc "NameCase" [[The name case of the generate method, in one program, only need to be set once, default is Pascal case]]
		property "NameCase" { Type = NameCases, Default = NameCases.Pascal, IsStatic = true }

		------------------------------------------------------
		-- Method
		------------------------------------------------------
		function ApplyAttribute(self, target, targetType, owner, name)
			target.Synthesize = __Synthesize__.NameCase
		end
	end)

	__AttributeUsage__{AttributeTarget = AttributeTargets.Property, Inherited = false, RunOnce = true}
	__Sealed__() __Unique__()
	class "__Event__" (function(_ENV)
		inherit "__Attribute__"

		doc "__Event__" [[Used to bind an event to the property]]

		------------------------------------------------------
		-- Property
		------------------------------------------------------
		doc "Event" [[The event that bind to the property]]
		property "Event" { Type = String }

		------------------------------------------------------
		-- Method
		------------------------------------------------------
		function ApplyAttribute(self, target, targetType, owner, name)
			target.Event = self.Event
		end

		------------------------------------------------------
		-- Constructor
		------------------------------------------------------
		__Arguments__{}
		function __Event__(self)
			self.Event = nil

			return Super(self)
		end

		__Arguments__{ Event }
		function __Event__(self, value)
			self.Event = value

			return Super(self)
		end

		__Arguments__{ String }
		function __Event__(self, value)
			self.Event = value

			return Super(self)
		end
	end)

	__AttributeUsage__{AttributeTarget = AttributeTargets.Property, Inherited = false, RunOnce = true}
	__Sealed__() __Unique__()
	class "__Handler__" (function(_ENV)
		inherit "__Attribute__"

		doc "__Handler__" [[Used to bind an handler(method name or function) to the property]]

		__Sealed__()
		struct "HandlerType" { function(value) assert(type(value) == "function" or type(value) == "string", "%s must be a function or method name.") end }

		------------------------------------------------------
		-- Property
		------------------------------------------------------
		doc "Handler" [[The handler that bind to the property]]
		property "Handler" { Type = HandlerType }

		------------------------------------------------------
		-- Method
		------------------------------------------------------
		function ApplyAttribute(self, target, targetType, owner, name)
			target.Handler = self.Handler
			self.Handler = nil
		end

		------------------------------------------------------
		-- Constructor
		------------------------------------------------------
		__Arguments__{}
		function __Handler__(self)
			self.Handler = nil

			return Super(self)
		end

		__Arguments__{ HandlerType }
		function __Handler__(self, value)
			self.Handler = value

			return Super(self)
		end
	end)

	__AttributeUsage__{AttributeTarget = AttributeTargets.Struct + AttributeTargets.Enum + AttributeTargets.Property + AttributeTargets.Member, Inherited = false, RunOnce = true}
	__Sealed__() __Unique__()
	class "__Default__" (function(_ENV)
		inherit "__Attribute__"

		doc "__Default__" [[Used to set a default value for custom struct or enum]]

		------------------------------------------------------
		-- Property
		------------------------------------------------------
		doc "Default" [[The default value]]
		property "Default" { Type = Any }

		------------------------------------------------------
		-- Method
		------------------------------------------------------
		function ApplyAttribute(self, target, targetType, owner, name)
			if self.Default == nil then return end

			if targetType == AttributeTargets.Property then
				target.Default = self.Default
			elseif targetType == AttributeTargets.Member then
				local info = _NSInfo[owner]
				if not info or info.SubType ~= _STRUCT_TYPE_MEMBER then return end
				local val = GetValidatedValue(rawget(info.StructEnv, target), self.Default)
				if val == nil then return end

				info.DefaultField = info.DefaultField or {}
				info.DefaultField[target] = val
			else
				_NSInfo[target].Default = self.Default
			end
		end

		------------------------------------------------------
		-- Constructor
		------------------------------------------------------
		__Arguments__{}
		function __Default__(self)
			self.Default = nil

			return Super(self)
		end

		__Arguments__{ Any }
		function __Default__(self, value)
			self.Default = value

			return Super(self)
		end
	end)

	__Default__( "Assign" )
	__Flags__()
	enum "Setter" {
		Assign = 0,	-- set directly
		"Clone",	-- Clone struct or object of ICloneable
		"DeepClone",-- Deep clone struct
		"Retain",	-- Dispose old object
		-- "Strong", this is default for lua
		"Weak",		-- Weak value
	}

	__Default__( "Origin" )
	__Flags__()
	enum "Getter" {
		Origin = 0,
		"Clone",
		"DeepClone",
	}

	__AttributeUsage__{AttributeTarget = AttributeTargets.Property, Inherited = false, RunOnce = true}
	__Sealed__() __Unique__()
	class "__Setter__" (function(_ENV)
		inherit "__Attribute__"

		doc "__Setter__" [[Used to set the assign mode of the property]]

		------------------------------------------------------
		doc "Setter" [[The setter settings]]
		property "Setter" { Type = Setter }

		------------------------------------------------------
		-- Method
		------------------------------------------------------
		function ApplyAttribute(self, target, targetType, owner, name)
			target.Setter = self.Setter
		end

		------------------------------------------------------
		-- Constructor
		------------------------------------------------------
		__Arguments__{}
		function __Setter__(self)
			self.Setter = nil

			return Super(self)
		end

		__Arguments__{ Setter }
		function __Setter__(self, value)
			self.Setter = value

			return Super(self)
		end
	end)

	__AttributeUsage__{AttributeTarget = AttributeTargets.Property, Inherited = false, RunOnce = true}
	__Sealed__() __Unique__()
	class "__Getter__" (function(_ENV)
		inherit "__Attribute__"

		doc "__Getter__" [[Used to set the get mode of the property]]

		------------------------------------------------------
		doc "Getter" [[The getter settings]]
		property "Getter" { Type = Getter }

		------------------------------------------------------
		-- Method
		------------------------------------------------------
		function ApplyAttribute(self, target, targetType, owner, name)
			target.Getter = self.Getter
		end

		------------------------------------------------------
		-- Constructor
		------------------------------------------------------
		__Arguments__{}
		function __Getter__(self)
			self.Getter = nil

			return Super(self)
		end

		__Arguments__{ Getter }
		function __Getter__(self, value)
			self.Getter = value

			return Super(self)
		end
	end)

	__AttributeUsage__{Inherited = false, RunOnce = true, BeforeDefinition = true}
	__Sealed__() __Unique__()
	class "__Doc__" (function(_ENV)
		inherit "__Attribute__"

		doc "__Doc__" [[Used to document the features like : class, struct, enum, interface, property, event and method]]

		------------------------------------------------------
		-- Method
		------------------------------------------------------
		function ApplyAttribute(self, target, targetType, owner, name)
			if type(self.Doc) == "string" and targetType and (owner or target) then
				SaveDocument(self.Doc, name, targetType, owner or target)
			end

			self.Doc = nil
		end

		------------------------------------------------------
		-- Constructor
		------------------------------------------------------
		function __Doc__(self, data)
			self.Doc = data

			return Super(self)
		end

		------------------------------------------------------
		-- Meta-method
		------------------------------------------------------
		doc "__call" [[__Doc__ "Target" "Document"]]
		function __call(self, data)
			self:RemoveSelf()

			local owner = getfenv(2)[OWNER_FIELD]

			if type(self.Doc) == "string" and owner and IsNameSpace(owner) then SaveDocument(data, self.Doc, nil, owner) end

			self.Doc = nil
		end
	end)

	__AttributeUsage__{AttributeTarget = AttributeTargets.Class + AttributeTargets.Struct + AttributeTargets.Enum + AttributeTargets.Interface + AttributeTargets.Method, Inherited = false, RunOnce = true, BeforeDefinition = true}
	__Sealed__() __Unique__()
	class "__Local__" (function(_ENV)
		inherit "__Attribute__"

		doc "__Local__" [[Used to mark the features like class, struct, interface, enum and method as local.]]

		------------------------------------------------------
		-- Method
		------------------------------------------------------
		function ApplyAttribute(self) return SetLocal(false) end

		------------------------------------------------------
		-- Constructor
		------------------------------------------------------
		function __Local__(self) SetLocal(true) return Super(self) end
	end)

	__AttributeUsage__{AttributeTarget = AttributeTargets.Property + AttributeTargets.Method, Inherited = false, RunOnce = true }
	__Sealed__() __Unique__()
	class "__Static__" (function(_ENV)
		inherit "__Attribute__"
		doc "__Static__" [[Used to mark the features as static.]]

		------------------------------------------------------
		-- Method
		------------------------------------------------------
		function ApplyAttribute(self, target, targetType, owner, name)
			if targetType == AttributeTargets.Property then
				target.IsStatic = true
			elseif targetType == AttributeTargets.Method then
				local info = _NSInfo[owner]

				info.StaticMethod = info.StaticMethod or {}
				info.StaticMethod[name] = true
			end
		end
	end)

	__AttributeUsage__{AttributeTarget = AttributeTargets.Class + AttributeTargets.Interface + AttributeTargets.Struct + AttributeTargets.Enum, Inherited = false, RunOnce = true, BeforeDefinition = true}
	__Sealed__() __Unique__()
	class "__NameSpace__" (function(_ENV)
		inherit "__Attribute__"
		doc "__NameSpace__" [[Used to set the namespace directly.]]

		------------------------------------------------------
		-- Method
		------------------------------------------------------
		function ApplyAttribute(self) return PrepareNameSpace(nil) end

		------------------------------------------------------
		-- Constructor
		------------------------------------------------------
		function __NameSpace__(self, ns)
			if getmetatable(ns) == TYPE_NAMESPACE then
				PrepareNameSpace(ns)
			elseif type(ns) == "string" then
				PrepareNameSpace(BuildNameSpace(GetDefaultNameSpace(), ns))
			elseif ns == nil or ns == false then
				PrepareNameSpace(false)
			else
				error([[Usage: __NameSpace__(name|nil|false)]], 2)
			end

			return Super(self)
		end
	end)

	-- Static method for __Attribute__
	__Sealed__() class "__Attribute__" (function(_ENV)
		local function IsDefined(target, targetType, owner, name, type)
			local config = GetTargetAttributes(target, targetType, owner, name)

			if not config then
				return false
			elseif not type then
				return true
			elseif getmetatable(config) then
				return getmetatable(config) == type
			else
				for _, attr in ipairs(config) do if getmetatable(attr) == type then return true end end
			end
			return false
		end

		doc "IsClassAttributeDefined" [[
			<desc>Check whether the target contains such type attribute</desc>
			<param name="target">class</param>
			<param name="type">the attribute class type</param>
			<return type="boolean">true if the target contains attribute with the type</return>
		]]
		__Static__() function IsClassAttributeDefined(target, type)
			if Reflector.IsClass(target) then return IsDefined(target, AttributeTargets.Class, nil, nil, type) end
			return false
		end

		doc "IsEnumAttributeDefined" [[
			<desc>Check whether the target contains such type attribute</desc>
			<param name="target">enum</param>
			<param name="type">the attribute class type</param>
			<return type="boolean">true if the target contains attribute with the type</return>
		]]
		__Static__() function IsEnumAttributeDefined(target, type)
			if Reflector.IsEnum(target) then return IsDefined(target, AttributeTargets.Enum, nil, nil, type) end
			return false
		end

		doc "IsEventAttributeDefined" [[
			<desc>Check whether the target contains such type attribute</desc>
			<param name="target">class | interface</param>
			<param name="event">the event's name</param>
			<param name="type">the attribute class type</param>
			<return type="boolean">true if the target contains attribute with the type</return>
		]]
		__Static__() function IsEventAttributeDefined(target, event, type)
			local info = _NSInfo[target]

			if info and (info.Type == TYPE_CLASS or info.Type == TYPE_INTERFACE) and getmetatable(info.Cache[event]) then
				return IsDefined(info.Cache[event], AttributeTargets.Event, target, event, type)
			end
			return false
		end

		doc "IsInterfaceAttributeDefined" [[
			<desc>Check whether the target contains such type attribute</desc>
			<param name="target">interface</param>
			<param name="type">the attribute class type</param>
			<return type="boolean">true if the target contains attribute with the type</return>
		]]
		__Static__() function IsInterfaceAttributeDefined(target, type)
			if Reflector.IsInterface(target) then return IsDefined(target, AttributeTargets.Interface, nil, nil, type) end
			return false
		end

		doc "IsMethodAttributeDefined" [[
			<desc>Check whether the target contains such type attribute</desc>
			<param name="target">class | interface | struct</param>
			<param name="method">the method's name</param>
			<param name="type">the attribute class type</param>
			<return type="boolean">true if the target contains attribute with the type</return>
		]]
		__Static__() function IsMethodAttributeDefined(target, method, ty)
			if (Reflector.IsClass(target) or Reflector.IsInterface(target) or Reflector.IsStruct(target)) and type(method) == "string" then
				return IsDefined(nil, AttributeTargets.Method, target, method, ty)
			end
			return false
		end

		doc "IsPropertyAttributeDefined" [[
			<desc>Check whether the target contains such type attribute</desc>
			<param name="target">class | interface</param>
			<param name="property">the property's name</param>
			<param name="type">the attribute class type</param>
			<return type="boolean">true if the target contains attribute with the type</return>
		]]
		__Static__() function IsPropertyAttributeDefined(target, prop, ty)
			local info = _NSInfo[target]

			if info and (info.Type == TYPE_CLASS or info.Type == TYPE_INTERFACE) then
				local tar = info.Cache[prop]
				return type(tar) == "function" and not getmetatable(tar) and IsDefined(tar, AttributeTargets.Property, target, prop, ty)
			end
			return false
		end

		doc "IsStructAttributeDefined" [[
			<desc>Check whether the target contains such type attribute</desc>
			<param name="target">struct</param>
			<param name="type">the attribute class type</param>
			<return type="boolean">true if the target contains attribute with the type</return>
		]]
		__Static__() function IsStructAttributeDefined(target, type)
			if Reflector.IsStruct(target) then return IsDefined(target, AttributeTargets.Struct, nil, nil, type) end
			return false
		end

		doc "IsMemberAttributeDefined" [[
			<desc>Check whether the target contains such type attribute</desc>
			<param name="target">struct</param>
			<param name="field">the field's name</param>
			<param name="type">the attribute class type</param>
			<return type="boolean">true if the target contains attribute with the type</return>
		]]
		__Static__() function IsMemberAttributeDefined(target, field, ty)
			if Reflector.IsStruct(target) and type(field) == "string" then
				return IsDefined(nil, AttributeTargets.Member, target, field, ty)
			end

			return false
		end

		doc "IsNameSpaceAttributeDefined" [[
			<desc>Check whether the target contains such type attribute</desc>
			<param name="target">the name space</param>
			<param name="type">the attribute class type</param>
			<return type="boolean">true if the target contains attribute with the type</return>
		]]
		__Static__() function IsNameSpaceAttributeDefined(target, type)
			if Reflector.GetNameSpaceName(target) then return IsDefined(target, AttributeTargets.NameSpace, nil, nil, type) end
			return false
		end

		local function GetCustomAttribute(target, targetType, owner, name, type)
			local config = GetTargetAttributes(target, targetType, owner, name)

			if not config then
				return
			elseif getmetatable(config) then
				return (not type or getmetatable(config) == type) and config or nil
			elseif type then
				local cache = CACHE_TABLE()

				for _, attr in ipairs(config) do if getmetatable(attr) == type then tinsert(cache, attr) end end

				local count = #cache

				if count == 0 then
					CACHE_TABLE(cache)
					return
				elseif count == 1 then
					local r1 = cache[1]
					CACHE_TABLE(cache)
					return r1
				elseif count == 2 then
					local r1, r2 = cache[1], cache[2]
					CACHE_TABLE(cache)
					return r1, r2
				elseif count == 3 then
					local r1, r2, r3 = cache[1], cache[2], cache[3]
					CACHE_TABLE(cache)
					return r1, r2, r3
				else
					return unpack(cache)
				end
			else
				return unpack(config)
			end
		end

		doc "GetClassAttribute" [[
			<desc>Return the attributes of the given type for the class</desc>
			<param name="target">class</param>
			<param name="type">the attribute class type</param>
			<return>the attribute objects</return>
		]]
		__Static__() function GetClassAttribute(target, type)
			if Reflector.IsClass(target) then return GetCustomAttribute(target, AttributeTargets.Class, nil, nil, type) end
		end

		doc "GetEnumAttribute" [[
			<desc>Return the attributes of the given type for the enum</desc>
			<param name="target">enum</param>
			<param name="type">the attribute class type</param>
			<return>the attribute objects</return>
		]]
		__Static__() function GetEnumAttribute(target, type)
			if Reflector.IsEnum(target) then return GetCustomAttribute(target, AttributeTargets.Enum, nil, nil, type) end
		end

		doc "GetEventAttribute" [[
			<desc>Return the attributes of the given type for the class|interface's event</desc>
			<param name="target">class|interface</param>
			<param name="event">the event's name</param>
			<param name="type">the attribute class type</param>
			<return>the attribute objects</return>
		]]
		__Static__() function GetEventAttribute(target, event, type)
			local info = _NSInfo[target]

			if info and (info.Type == TYPE_CLASS or info.Type == TYPE_INTERFACE) and getmetatable(info.Cache[event]) then
				return GetCustomAttribute(info.Cache[event], AttributeTargets.Event, target, event, type)
			end
		end

		doc "GetInterfaceAttribute" [[
			<desc>Return the attributes of the given type for the interface</desc>
			<param name="target">interface</param>
			<param name="type">the attribute class type</param>
			<return>the attribute objects</return>
		]]
		__Static__() function GetInterfaceAttribute(target, type)
			if Reflector.IsInterface(target) then return GetCustomAttribute(target, AttributeTargets.Interface, nil, nil, type) end
		end

		doc "GetMethodAttribute" [[
			<desc>Return the attributes of the given type for the class|interface's method</desc>
			<format>target, method, type</format>
			<format>method, type</format>
			<param name="target">class|interface</param>
			<param name="method">the method's name(with target) or the method itself(without target)</param>
			<param name="type">the attribute class type</param>
			<return>the attribute objects</return>
		]]
		__Static__() function GetMethodAttribute(target, method, ty)
			if (Reflector.IsClass(target) or Reflector.IsInterface(target) or Reflector.IsStruct(target)) and type(method) == "string" then
				return GetCustomAttribute(nil, AttributeTargets.Method, target, method, ty)
			end
		end

		doc "GetPropertyAttribute" [[
			<desc>Return the attributes of the given type for the class|interface's property</desc>
			<param name="target">class|interface</param>
			<param name="prop">the property's name</param>
			<param name="type">the attribute class type</param>
			<return>the attribute objects</return>
		]]
		__Static__() function GetPropertyAttribute(target, prop, ty)
			local info = _NSInfo[target]

			if info and (info.Type == TYPE_CLASS or info.Type == TYPE_INTERFACE) then
				local tar = info.Cache[prop]
				return type(tar) == "table" and not getmetatable(tar) and GetCustomAttribute(tar, AttributeTargets.Property, target, prop, ty)
			end
		end

		doc "GetStructAttribute" [[
			<desc>Return the attributes of the given type for the struct</desc>
			<param name="target">struct</param>
			<param name="type">the attribute class type</param>
			<return>the attribute objects</return>
		]]
		__Static__() function GetStructAttribute(target, type)
			if Reflector.IsStruct(target) then return GetCustomAttribute(target, AttributeTargets.Struct, nil, nil, type) end
		end

		doc "GetMemberAttribute" [[
			<desc>Return the attributes of the given type for the struct's field</desc>
			<param name="target">struct</param>
			<param name="field">the field's name</param>
			<param name="type">the attribute class type</param>
			<return>the attribute objects</return>
		]]
		__Static__() function GetMemberAttribute(target, field, ty)
			if Reflector.IsStruct(target) and type(field) == "string" then
				return GetCustomAttribute(nil, AttributeTargets.Member, target, field, ty)
			end
		end

		doc "GetNameSpaceAttribute" [[
			<desc>Return the attributes of the given type for the NameSpace</desc>
			<param name="target">NameSpace</param>
			<param name="type">the attribute class type</param>
			<return>the attribute objects</return>
		]]
		__Static__() function GetNameSpaceAttribute(target, type)
			if Reflector.GetNameSpaceName(target) then return GetCustomAttribute(target, AttributeTargets.NameSpace, nil, nil, type) end
		end
	end)
end

------------------------------------------------------
-- System Namespace (Object & Module)
------------------------------------------------------
do
	------------------------------------------------------
	-- System.ICloneable
	------------------------------------------------------
	__Doc__ [[Supports cloning, which creates a new instance of a class with the same value as an existing instance.]]
	interface "ICloneable" (function(_ENV)
		------------------------------------------------------
		-- Method
		------------------------------------------------------
		__Require__() __Doc__[[Creates a new object that is a copy of the current instance.]]
		function Clone(self) end
	end)

	__Sealed__()
	__Doc__[[The root class of other classes. Object class contains several methodes for common use.]]
	class "Object" (function(_ENV)

		------------------------------------------------------
		-- Event
		------------------------------------------------------
		__Doc__[[
			<desc>Fired when an event's handler is changed</desc>
			<param name="name">the changed event handler's event name</param>
		]]
		event "OnEventHandlerChanged"

		------------------------------------------------------
		-- Method
		------------------------------------------------------
		__Doc__[[
			<desc>Check if the event type is supported by the object</desc>
			<param name="name">the event's name</param>
			<return type="boolean">true if the object has that event type</return>
		]]
		function HasEvent(self, name)
			if type(name) ~= "string" then
				error(("Usage : object:HasEvent(name) : 'name' - string expected, got %s."):format(type(name)), 2)
			end
			return Reflector.HasEvent(Reflector.GetObjectClass(self), name) or false
		end

		__Doc__[[
			<desc>Get the class type of the object</desc>
			<return type="class">the object's class</return>
		]]
		GetClass = Reflector.GetObjectClass

		__Doc__[[
			<desc>Check if the object is an instance of the class</desc>
			<param name="class"></param>
			<return type="boolean">true if the object is an instance of the class</return>
		]]
		IsClass = Reflector.ObjectIsClass

		__Doc__[[
			<desc>Check if the object is extend from the interface</desc>
			<param name="interface"></param>
			<return type="boolean">true if the object is extend from the interface</return>
		]]
		IsInterface = Reflector.ObjectIsInterface

		__Doc__[[
			<desc>Fire an object's event, to trigger the object's event handlers</desc>
			<param name="event">the event name</param>
			<param name="...">the event's arguments</param>
		]]
		Fire = Reflector.FireObjectEvent

		__Doc__[[
			<desc>Block some events for the object</desc>
			<param name="...">the event's name list</param>
		]]
		BlockEvent = Reflector.BlockEvent

		__Doc__[[
			<desc>Check if the event is blocked for the object</desc>
			<param name="event">the event's name</param>
			<return type="boolean">true if th event is blocked</return>
		]]
		IsEventBlocked = Reflector.IsEventBlocked

		__Doc__[[
			<desc>Un-Block some events for the object</desc>
			<param name="...">the event's name list</param>
		]]
		UnBlockEvent = Reflector.UnBlockEvent

		__Doc__[[
			<desc>Call method or function as a thread</desc>
			<param name="method" type="string|function">the target method</param>
			<param name="...">the arguments</param>
			<return>the return value of the target method</return>
		]]
		function ThreadCall(self, method, ...)
			if type(method) == "string" then method = self[method] end

			if type(method) == "function" then return CallThread(method, self, ...) end
		end
	end)

	_ModuleKeyWord = _KeywordAccessor()

	_ModuleKeyWord.namespace = namespace
	_ModuleKeyWord.class = class
	_ModuleKeyWord.interface = interface
	_ModuleKeyWord.enum = enum
	_ModuleKeyWord.struct = struct

	__Sealed__()
	__Doc__[[Used to create an hierarchical environment with class system settings, like : Module "Root.ModuleA" "v72"]]
	class "Module" (function(_ENV)
		inherit "Object"

		_Module = {}
		_ModuleInfo = setmetatable({}, WEAK_KEY)

		_ModuleKeyWord.import = function(self, name)
			local ns = name

			if type(name) == "string" then
				ns = Reflector.GetNameSpaceForName(name)
				if not ns then error(("no namespace is found with name : %s"):format(name), 2) end
			end

			if not Reflector.IsNameSpace(ns) then error([[Usage: import "namespaceA.namespaceB"]], 2) end

			local info = _ModuleInfo[self]
			if not info then error("can't use import here.", 2) end

			info.Import = info.Import or {}

			for _, v in ipairs(info.Import) do if v == ns then return end end

			tinsert(info.Import, ns)
		end

		------------------------------------------------------
		-- Event
		------------------------------------------------------
		__Doc__[[Fired when the module is disposed]]
		event "OnDispose"

		------------------------------------------------------
		-- Method
		------------------------------------------------------
		__Doc__[[
			<desc>Return true if the version is greater than the current version of the module</desc>
			<param name="version"></param>
			<return name="boolean">true if the version is a validated version</return>
		]]
		function ValidateVersion(self, version)
			local info = _ModuleInfo[self]

			if not info then error("The module is disposed", 2) end

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

		__Doc__[[
			<desc>Get the child-module with the name</desc>
			<param name="name">string, the child-module's name</param>
			<return name="System"></return>.Module the child-module
		]]
		function GetModule(self, name)
			if type(name) ~= "string" or strtrim(name) == "" then return end

			local mdl = self

			for sub in name:gmatch("[_%w]+") do
				mdl =  _ModuleInfo[mdl] and _ModuleInfo[mdl].Modules and _ModuleInfo[mdl].Modules[sub]

				if not mdl then return end
			end

			if mdl == self then return end

			return mdl
		end

		__Doc__[[
			<desc>Get all child-modules of the module</desc>
			<return name="table">the list of the the child-modules</return>
		]]
		function GetModules(self)
			if _ModuleInfo[self] and _ModuleInfo[self].Modules then
				local lst = {}

				for _, mdl in pairs(_ModuleInfo[self].Modules) do tinsert(lst, mdl) end

				return lst
			end
		end

		------------------------------------------------------
		-- Property
		------------------------------------------------------
		__Doc__[[The module itself]]
		property "_M" { Get = function(self) return self end }

		__Doc__[[The module's name]]
		property "_Name" { Get = function(self) return _ModuleInfo[self].Name end }

		__Doc__[[The module's parent module]]
		property "_Parent" { Get = function(self) return _ModuleInfo[self].Parent end }

		__Doc__[[The module's version]]
		property "_Version" { Get = function(self) return _ModuleInfo[self].Version end }

		------------------------------------------------------
		-- Dispose
		------------------------------------------------------
		function Dispose(self)
			local info = _ModuleInfo[self]

			if info then
				-- Clear child modules
				if info.Modules then
					for name, mdl in pairs(info.Modules) do mdl:Dispose() end

					wipe(info.Modules)

					info.Modules = nil
				end

				-- Fire the event
				OnDispose(self)

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

			if not Reflector.ObjectIsClass(parent, Module) then parent = nil end

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
			if Reflector.ObjectIsClass(parent, Module) then mdl = parent end

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
			local value = _ModuleKeyWord:GetKeyword(self, key)
			if value then return value end

			-- Check self's namespace
			local ns = Reflector.GetCurrentNameSpace(self, true)
			local parent = _ModuleInfo[self].Parent

			while not ns and parent do
				ns = Reflector.GetCurrentNameSpace(parent, true)
				parent = _ModuleInfo[parent].Parent
			end

			if ns and Reflector.GetNameSpaceName(ns) then
				if key == Reflector.GetNameSpaceName(ns) then
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
					if key == Reflector.GetNameSpaceName(ns) then
						rawset(self, key, ns)
						return rawget(self, key)
					elseif ns[key] then
						rawset(self, key, ns[key])
						return rawget(self, key)
					end
				end
			end

			-- Check base namespace
			if Reflector.GetNameSpaceForName(key) then
				rawset(self, key, Reflector.GetNameSpaceForName(key))
				return rawget(self, key)
			end

			if info.Parent then
				value = info.Parent[key]
				if value ~= nil then rawset(self, key, value) end
				return value
			else
				if key ~= "_G" and type(key) == "string" and key:find("^_") then return end
				value = _G[key]
				if value ~= nil then rawset(self, key, value) end
				return value
			end
		end

		function __newindex(self, key, value)
			if _ModuleKeyWord:GetKeyword(self, key) then error(("The %s is a keyword."):format(key)) end
			rawset(self, key, value)
		end

		function __call(self, version, depth)
			depth = tonumber(depth) or 1
			local info = _ModuleInfo[self]

			if not info then error("The module is disposed", 2) end

			-- Check version
			if type(version) == "number" then
				version = tostring(version)
			elseif type(version) == "string" then
				version = strtrim(version)

				if version == "" then version = nil end
			end

			if type(version) == "function" then
				ClearPreparedAttributes()
				if not FAKE_SETFENV then setfenv(version, self) return version() end
				return version(self)
			elseif type(version) == "string" then
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

			if not FAKE_SETFENV then setfenv(depth + 1, self) end

			ClearPreparedAttributes()

			return self
		end
	end)
end

------------------------------------------------------
-- Global Settings
------------------------------------------------------
do
	------------------------------------------------------
	-- Clear useless keywords
	------------------------------------------------------
	_KeyWord4IFEnv.doc = nil
	_KeyWord4ClsEnv.doc = nil

	if FAKE_SETFENV then setfenv() end

	-- Keep the root so can't be disposed
	System = Reflector.GetNameSpaceForName("System")

	function Install_OOP(env)
		env.interface = env.interface or interface
		env.class = env.class or class
		env.enum = env.enum or enum
		env.namespace = env.namespace or namespace
		env.struct = env.struct or struct
		env.import = env.import or function(env, name)
			local ns = Reflector.GetNameSpaceForName(name or env)
			if not ns then error("No such namespace.", 2) end
			env = type(env) == "table" and env or getfenv(2) or _G

			name = _NSInfo[ns].Name
			if env[name] == nil then env[name] = ns end
			for subNs, sub in Reflector.GetSubNamespace(ns) do
				if _NSInfo[sub].Type and env[subNs] == nil then env[subNs] = sub end
			end
		end
		env.Module = env.Module or Module
		env.System = env.System or System
	end

	-- Install to the global environment
	Install_OOP(_G)
	Install_OOP = nil
	collectgarbage()
end
