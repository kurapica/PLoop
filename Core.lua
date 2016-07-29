--[[
Copyright (c) 2011-2016 WangXH <kurapica125@outlook.com>

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
-- Author           kurapica125@outlook.com
-- Create Date      2011/02/03
-- Last Update Date 2016/07/29
-- Version          r151
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

	LUA_VERSION = tonumber(_G._VERSION:match("[%d%.]+")) or 5.1

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
	loadfile = loadfile
end

------------------------------------------------------
-- GLOBAL Definition
------------------------------------------------------
do
	-- Used to enable/disable document system
	DOCUMENT_ENABLED = PLOOP_DOCUMENT_ENABLED == nil and true or PLOOP_DOCUMENT_ENABLED
	SAVE_MEMORY = PLOOP_SAVE_MEMORY and true or false

	TYPE_CLASS = "Class"
	TYPE_ENUM = "Enum"
	TYPE_STRUCT = "Struct"
	TYPE_INTERFACE = "Interface"

	TYPE_NAMESPACE = "NameSpace"
	TYPE_CLASSALIAS = "ClassAlias"

	-- Disposing method name
	DISPOSE_METHOD = "Dispose"

	-- Namespace field
	NAMESPACE_FIELD = "__PLOOP_NameSpace"

	-- Owner field
	OWNER_FIELD = "__PLOOP_OWNER"

	-- Base env field
	BASE_ENV_FIELD = "__PLOOP_BASE_ENV"

	-- Import env field
	IMPORT_ENV_FIELD = "__PLOOP_IMPORT_ENV"

	-- Attribute System
	ATTRIBUTE_INSTALLED = false

	-- MODIFIER
	MD_FINAL_FEATURE = 2^0
	MD_FLAGS_ENUM = 2^1
	MD_SEALED_FEATURE = 2^2
	MD_ABSTRACT_CLASS = 2^3
	MD_STATIC_FEATURE = 2^4
	MD_REQUIRE_FEATURE = 2^5
	MD_AUTO_PROPERTY = 2^6
end

------------------------------------------------------
-- Tools
------------------------------------------------------
do
	CACHE_TABLE = setmetatable({}, {__call = function(self, key)if key then if getmetatable(key) == nil then wipe(key) tinsert(self, key) end else return tremove(self) or {} end end})

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
	PrepareNameSpace_CACHE = setmetatable({}, WEAK_KEY)

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

		if IsNameSpace(obj1) then return false end
		local cls = getmetatable(obj1)

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
		ClearKeyword = function(self)
			self.Owner = nil
			self.Keyword = nil
		end,
	}
	local _KeyAccessor = newproxy(true)
	getmetatable(_KeyAccessor).__call = function (self, value, value2)
		self = _KeywordAccessorInfo[self]
		local keyword, owner = self.Keyword, self.Owner
		self.Keyword, self.Owner = nil, nil
		if keyword and owner then
			-- In 5.1, tail call for error & setfenv is not supported
			if value2 ~= nil then
				local ok, ret = pcall(keyword, owner, value, value2, 4)
				if not ok then error(ret:match("%d+:%s*(.-)$") or ret, 2) end
				return ret
			else
				local ok, ret = pcall(keyword, owner, value, 4)
				if not ok then error(ret:match("%d+:%s*(.-)$") or ret, 2) end
				return ret
			end
		end
	end
	getmetatable(_KeyAccessor).__metatable = false

	function _KeywordAccessor(key, value)
		if type(key) == "string" and type(value) == "function" then
			-- Save keywords to all accessors
			for _, info in pairs(_KeywordAccessorInfo) do if type(info) == "table" then info[key] = value end end
		else
			local keyAccessor = newproxy(_KeyAccessor)
			local info = { GetKeyword = _KeywordAccessorInfo.GetKeyword, ClearKeyword = _KeywordAccessorInfo.ClearKeyword, KeyAccessor = keyAccessor }
			_KeywordAccessorInfo[keyAccessor] = info
			return info
		end
	end

	-- 	ValidateFlags
	function ValidateFlags(checkValue, targetValue)
		if not targetValue then return false end
		targetValue = targetValue % (2 * checkValue)
		return (targetValue - targetValue % checkValue) == checkValue
	end

	function TurnOnFlags(checkValue, targetValue)
		if not ValidateFlags(checkValue, targetValue) then
			return checkValue + (targetValue or 0)
		end
		return targetValue
	end

	if LUA_VERSION >= 5.3 then
		ValidateFlags = loadstring [[
			return function(checkValue, targetValue)
				return (checkValue & (targetValue or 0)) > 0
			end
		]] ()

		TurnOnFlags = loadstring [[
			return function(checkValue, targetValue)
				return checkValue | (targetValue or 0)
			end
		]] ()
	elseif (LUA_VERSION == 5.2 and type(bit32) == "table") or (LUA_VERSION == 5.1 and type(bit) == "table") then
		local band = bit32 and bit32.band or bit.band
		local bor = bit32 and bit32.bor  or bit.bor

		ValidateFlags = function (checkValue, targetValue)
			return band(checkValue, targetValue or 0) > 0
		end

		TurnOnFlags = function (checkValue, targetValue)
			return bor(checkValue, targetValue or 0)
		end
	end
end

------------------------------------------------------
-- NameSpace & ClassAlias
------------------------------------------------------
do
	PROTYPE_NAMESPACE = newproxy(true)
	PROTYPE_CLASSALIAS = newproxy(true)

	_NSInfo = setmetatable({ [PROTYPE_NAMESPACE] = { Owner = PROTYPE_NAMESPACE } }, {
		__index = function(self, key)
			if type(key) == "string" then
				key = GetNameSpace(PROTYPE_NAMESPACE, key)
				return key and rawget(self, key)
			end
		end,
		__mode = "k",
	})

	_AliasMap = setmetatable({}, WEAK_ALL)

	-- metatable for namespaces
	_MetaNS = getmetatable(PROTYPE_NAMESPACE)
	do
		local _UnmStruct = {}
		local _MixedStruct = {}

		_MetaNS.__call = function(self, ...)
			local info = _NSInfo[self]
			local iType = info.Type

			if iType == TYPE_CLASS then
				-- Create Class object, using ret avoid tail call error stack
				local ret = Class2Obj(info, ...)
				return ret
			elseif iType == TYPE_STRUCT then
				-- Create Struct
				local ret = Struct2Obj(info, ...)
				return ret
			elseif iType == TYPE_INTERFACE then
				-- Create interface's anonymousClass' object
				local ret = Interface2Obj(info, ...)
				return ret
			elseif iType == TYPE_ENUM then
				-- Parse Enum
				local value = ...
				if info.MaxValue and type(value) == "number" and value == floor(value) and value >= 0 and value <= info.MaxValue then
					if value == 0 or info.Cache[value] then
						return info.Cache[value]
					else
						local rCache = CACHE_TABLE()
						local eCache = info.Cache
						local ckv = 1

						while ckv <= value do
							if ValidateFlags(ckv, value) then tinsert(rCache, eCache[ckv]) end
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
				return info.Method and info.Method[key] or nil
			elseif iType == TYPE_CLASS or iType == TYPE_INTERFACE then
				if iType == TYPE_CLASS then
					-- Meta-method
					if _KeyMeta[key] then return info.MetaTable[_KeyMeta[key]] end

					if key == "Super" then
						info = _NSInfo[info.SuperClass]
						if info then
							return info.ClassAlias or BuildClassAlias(info)
						else
							return error("The class has no super class.", 2)
						end
					end

					if key == "This" then return info.ClassAlias or BuildClassAlias(info) end
				end

				-- Method
				ret = info.Cache[key] or info.Method and info.Method[key]
				if type(ret) == "function" then return ret end

				-- Property
				ret = info.Property and info.Property[key]
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
							error(("%s can't be read."):format(key), 2)
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
				local val
				if type(key) == "string" then val = info.Enum[strupper(key)] end
				if val == nil and info.Cache[key] ~= nil then val = key end
				if val == nil then error(("%s is not an enumeration value of %s."):format(tostring(key), tostring(self)), 2) end
				return val
			end
		end

		_MetaNS.__newindex = function(self, key, value)
			local info = _NSInfo[self]

			if info.Type == TYPE_CLASS or info.Type == TYPE_INTERFACE then
				-- Static Property
				local oper = info.Property and info.Property[key]

				if oper and oper.IsStatic then
					if oper.Set == false then error(("%s can't be set."):format(key), 2) end

					-- Property
					if oper.Type then value = Validate4Type(oper.Type, value, key, key, 3) end
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
							error(("%s can't be set."):format(key), 2)
						end
					end
				else
					local ok, msg = pcall(SaveFeature, info, key, value)
					if not ok then error(msg:match("%d+:%s*(.-)$") or msg, 2) end
					return not info.BeginDefinition and RefreshCache(self)
				end
			elseif info.Type == TYPE_STRUCT then
				local ok, msg = pcall(SaveFeature, info, key, value)
				if not ok then error(msg:match("%d+:%s*(.-)$") or msg, 2) end
				return not info.BeginDefinition and RefreshStruct(self)
			end

			error(("Can't set data to %s, it's readonly."):format(tostring(self)), 2)
		end

		_MetaNS.__tostring = function(self)
			local info = _NSInfo[self]

			if info then
				if info.OriginNS then
					return "-" .. tostring(info.OriginNS)
				elseif info.CombineNS then
					local name = ""
					for _, ns in ipairs(info.CombineNS) do
						ns = tostring(ns)
						if ns:match("^%-") then ns = "(" .. ns .. ")" end
						if name ~= "" then
							name = name .. "+" .. ns
						else
							name = ns
						end
					end
					return name
				elseif info.OriginIF then
					return tostring(info.OriginIF) .. "." .. "AnonymousClass"
				else
					local name = info.Name

					while info and info.NameSpace do
						info = _NSInfo[info.NameSpace]

						if info.Name then name = info.Name.."."..name end
					end

					return name
				end
			end
		end

		_MetaNS.__unm = function(self)
			local sinfo = _NSInfo[self]
			if sinfo.Type == TYPE_CLASS or sinfo.Type == TYPE_INTERFACE then
				local strt = _UnmStruct[self]
				if not strt then
					if sinfo.Type == TYPE_CLASS then
						local errMsg = "%s must be child-class of [Class]" .. tostring(self)
						__Sealed__()
						__Default__(self)
						strt = struct {
							function (value)
								assert(IsChildClass(self, value), errMsg)
							end
						}
					else
						local errorMsg = "%s must extend the [Interface]" .. tostring(self)
						__Sealed__()
						__Default__(self)
						strt = struct {
							function (value)
								assert(IsExtend(self, value), errMsg)
							end
						}
					end

					_UnmStruct[self] = strt
					_NSInfo[strt].OriginNS = self
				end
				return strt
			else
				error("The unary '-' operation only support class and interface types", 2)
			end
		end

		_MetaNS.__add = function(self, other)
			local sinfo = _NSInfo[self]
			local oinfo = _NSInfo[other]
			if sinfo and oinfo then
				local sref = tostring(sinfo):match("%w+$")
				local oref = tostring(oinfo):match("%w+$")

				local strt = _MixedStruct[sref .. "_" .. oref] or _MixedStruct[oref .. "_" .. sref]
				if strt then return strt end

				local errMsg = "%s must be value of "

				__Sealed__()
				strt = struct {
					function (value)
						local ret = GetValidatedValue(self, value)
						if ret == nil then ret = GetValidatedValue(other, value) end
						assert(ret ~= nil, errMsg)
						return ret
					end
				}

				_MixedStruct[sref .. "_" .. oref] = strt
				_NSInfo[strt].CombineNS = { self, other }
				errMsg = errMsg .. tostring(strt)

				return strt
			end
		end

		_MetaNS.__metatable = TYPE_NAMESPACE

		_MetaNS = nil
	end

	-- metatable for super alias
	_MetaSA = getmetatable(PROTYPE_CLASSALIAS)
	do
		_MetaSA.__call = function(self, obj, ...)
			-- Init the class object
			local info = _AliasMap[self]
			if IsChildClass(info.Owner, getmetatable(obj)) then return Class1Obj(info, obj, ...) end
		end

		_MetaSA.__index = function(self, key)
			local info = _AliasMap[self]
			local ret = info.SubNS and info.SubNS[key]

			if ret then
				return ret
			elseif _KeyMeta[key] then
				return info.MetaTable[_KeyMeta[key]]
			else
				ret = info.Cache[key] or info.Method and info.Method[key]
				if type(ret) == "function" then return ret end
			end
		end

		_MetaSA.__tostring = function(self) return tostring(_AliasMap[self].Owner) end
		_MetaSA.__metatable = TYPE_CLASSALIAS

		_MetaSA = nil
	end

	-- BuildClassAlias
	function BuildClassAlias(info)
		local value = newproxy(PROTYPE_CLASSALIAS)
		info.ClassAlias = value
		_AliasMap[value] = info
		return value
	end

	-- IsNameSpace
	function IsNameSpace(ns) return rawget(_NSInfo, ns) and true or false end

	-- RecordNSFeatures
	local _newFeatures

	function RecordNSFeatures()
		_newFeatures = {}
	end

	function GetNsFeatures()
		local ret = _newFeatures
		_newFeatures = nil
		return ret
	end

	-- BuildNameSpace
	function BuildNameSpace(ns, namelist)
		if type(namelist) ~= "string" or (ns and not IsNameSpace(ns)) then return end

		local cls = ns
		local info = _NSInfo[cls]
		local parent = cls

		for name in namelist:gmatch("[_%w]+") do
			if not info then
				cls = newproxy(PROTYPE_NAMESPACE)
			elseif info.Type == TYPE_ENUM then
				return error(("The %s is an enumeration, can't define sub-namespace in it."):format(tostring(info.Owner)))
			else
				local scls = info.SubNS and info.SubNS[name]

				if not scls then
					-- No conflict
					if info.Members and info.Members[name] or info.Cache and info.Cache[name] or info.Method and info.Method[name] or info.Property and info.Property[name] then
						return error(("The [%s] %s - %s is defined, can't be used as namespace."):format(info.Type, tostring(info.Owner), name))
					end

					scls = newproxy(PROTYPE_NAMESPACE)
					info.SubNS = info.SubNS or {}
					info.SubNS[name] = scls

					if cls == PROTYPE_NAMESPACE and _G[name] == nil then _G[name] = scls end
				end

				cls = scls
			end

			info = _NSInfo[cls]
			if not info then
				info = { Owner = cls, Name = name, NameSpace = parent }
				_NSInfo[cls] = info
			end
			parent = cls
		end

		if cls == ns then return end

		if _newFeatures then _newFeatures[cls] = true end

		return cls
	end

	-- GetNameSpace
	function GetNameSpace(ns, namelist)
		if type(namelist) ~= "string" or not IsNameSpace(ns) then return end

		local cls = ns
		local info

		for name in namelist:gmatch("[_%w]+") do
			info = _NSInfo[cls]
			cls = info.SubNS and info.SubNS[name]

			if not cls then return end
		end

		if cls == ns then return end

		return cls
	end

	-- SetNameSpace
	function SetNameSpace4Env(env, name)
		if type(env) ~= "table" then return end

		local ns = type(name) == "string" and BuildNameSpace(PROTYPE_NAMESPACE, name) or IsNameSpace(name) and name or nil
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
	------------------------------------
	function namespace(env, name, stack)
		stack = stack or 2
		name = name or env
		if name ~= nil and type(name) ~= "string" and not IsNameSpace(name) then error([[Usage: namespace "namespace"]], stack) end
		env = type(env) == "table" and env or getfenv(stack) or _G

		local ok, ns = pcall(SetNameSpace4Env, env, name)

		if not ok then error(ns:match("%d+:%s*(.-)$") or ns, stack) end

		return ns and ATTRIBUTE_INSTALLED and ConsumePreparedAttributes(ns, AttributeTargets.NameSpace)
	end

	function GetDefineNS(env, name, ty)
		if not name then
			-- Anonymous
			return BuildNameSpace(nil, "Anonymous" .. ty)
		elseif IsNameSpace(name) then
			return name
		elseif type(name) == "string" then
			if not name:match("^[_%w]+$") then return end

			local ns = GetPrepareNameSpace() == nil and GetNameSpace4Env(env) or GetPrepareNameSpace() or nil

			if ns then
				return BuildNameSpace(ns, name)
			else
				local tar = env[name]
				info = _NSInfo[tar]

				if not (info and info.NameSpace == nil and info.Type == ty ) then
					tar = BuildNameSpace(nil, name)
				end

				return tar
			end
		end
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

		error(ret, stack or 2)
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
	_DocMap = setmetatable({}, WEAK_KEY)

	function getSuperDoc(info, key, dkey)
		if info.SuperClass then
			local sinfo = _NSInfo[info.SuperClass]

			while sinfo do
				if _DocMap[sinfo] and (_DocMap[sinfo][key] or _DocMap[sinfo][dkey]) then
					return _DocMap[sinfo][key] or _DocMap[sinfo][dkey]
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

				if _DocMap[sinfo] and (_DocMap[sinfo][key] or _DocMap[sinfo][dkey]) then
					return _DocMap[sinfo][key] or _DocMap[sinfo][dkey]
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

		_DocMap[info] = _DocMap[info] or {}
		_DocMap[info][key] = data
	end

	function GetDocument(owner, name, targetType)
		if not DOCUMENT_ENABLED then return end

		if type(owner) == "string" then owner = GetNameSpace(PROTYPE_NAMESPACE, owner) end

		local info = _NSInfo[owner]
		if not info then return end

		name = name or info.Name
		if type(name) ~= "string" then return end

		targetType = getTargetType(info, name, targetType)

		local key = targetType and tostring(targetType) .. name or nil

		return _DocMap[info] and (_DocMap[info][key] or _DocMap[info][name]) or (targetType ~= "CLASS" and targetType ~= "INTERFACE") and getSuperDoc(info, key, name) or nil
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

--------------------------------------------------
-- Refresh Cache
--------------------------------------------------
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

		-- Clear Ctor
		if info.Type == TYPE_CLASS then info.Ctor = nil end

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
		if info.Event then CloneWithOverride(iCache, info.Event) end

		-- Cache for Method
		if info.Method then
			for key, value in pairs(info.Method) do
				-- No static methods
				if not (info.FeatureModifier and ValidateFlags(MD_STATIC_FEATURE, info.FeatureModifier[key])) then
					iCache[key] = value
				end
			end
		end

		-- Cache for Property
		-- Validate the properties
		if info.Property then
			local autoProp = ValidateFlags(MD_AUTO_PROPERTY, info.Modifier)
			for name, prop in pairs(info.Property) do
				if prop.Predefined then
					local set = prop.Predefined

					prop.Predefined = nil

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
								if tInfo and tInfo.Type then prop.Type = v end
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
							elseif k == "isstatic" or k == "static" then
								prop.IsStatic = v and true or false
							end
						end
					end

					-- Validate the default
					if type(prop.Default) == "function" then
						prop.DefaultFunc = prop.Default
						prop.Default = nil
					end

					if prop.Default ~= nil and prop.Type then
						prop.Default = GetValidatedValue(prop.Type, prop.Default)
					end

					-- Clear
					if prop.Get ~= nil then prop.GetMethod = nil end
					if prop.Set ~= nil then prop.SetMethod = nil end

					local uname = name:gsub("^%a", strupper)

					if prop.IsStatic then
						-- Only use static methods
						if prop.GetMethod then
							if info.FeatureModifier and ValidateFlags(MD_STATIC_FEATURE, info.FeatureModifier[prop.GetMethod]) then
								prop.Get = info.Method[prop.GetMethod]
							end
							prop.GetMethod = nil
						end
						if prop.SetMethod then
							if info.FeatureModifier and ValidateFlags(MD_STATIC_FEATURE, info.FeatureModifier[prop.SetMethod]) then
								prop.Set = info.Method[prop.SetMethod]
							end
							prop.SetMethod = nil
						end

						if info.FeatureModifier and info.Method then
							-- Auto generate GetMethod
							if autoProp and ( prop.Get == nil or prop.Get == true ) and prop.Field == nil then
								-- GetMethod
								if info.Method["get" .. uname] and ValidateFlags(MD_STATIC_FEATURE, info.FeatureModifier["get" .. uname]) then
									prop.Get = info.Method["get" .. uname]
								elseif info.Method["Get" .. uname] and ValidateFlags(MD_STATIC_FEATURE, info.FeatureModifier["Get" .. uname]) then
									prop.Get = info.Method["Get" .. uname]
								elseif prop.Type == Boolean or prop.Type == BooleanNil then
									-- FlagEnabled -> IsFlagEnabled
									if info.Method["is" .. uname] and ValidateFlags(MD_STATIC_FEATURE, info.FeatureModifier["is" .. uname]) then
										prop.Get = info.Method["is" .. uname]
									elseif info.Method["Is" .. uname] and ValidateFlags(MD_STATIC_FEATURE, info.FeatureModifier["Is" .. uname]) then
										prop.Get = info.Method["Is" .. uname]
									else
										-- FlagEnable -> IsEnableFlag
										local pattern = ParseAdj(uname, true)

										if pattern then
											for mname, mod in pairs(info.FeatureModifier) do
												if info.Method[mname] and ValidateFlags(MD_STATIC_FEATURE, mod) and mname:match(pattern) then
													prop.Get = info.Method[mname]
													break
												end
											end
										end
									end
								end
							end

							-- Auto generate SetMethod
							if autoProp and ( prop.Set == nil or prop.Set == true ) and prop.Field == nil then
								-- SetMethod
								if info.Method["set" .. uname] and ValidateFlags(MD_STATIC_FEATURE, info.FeatureModifier["set" .. uname]) then
									prop.Set = info.Method["set" .. uname]
								elseif info.Method["Set" .. uname] and ValidateFlags(MD_STATIC_FEATURE, info.FeatureModifier["Set" .. uname]) then
									prop.Set = info.Method["Set" .. uname]
								elseif prop.Type == Boolean or prop.Type == BooleanNil then
									-- FlagEnabled -> EnableFlag, FlagDisabled -> DisableFlag
									local pattern = ParseAdj(uname)

									if pattern then
										for mname, mod in pairs(info.FeatureModifier) do
											if info.Method[mname] and ValidateFlags(MD_STATIC_FEATURE, mod) and mname:match(pattern) then
												prop.Set = info.Method[mname]
												break
											end
										end
									end
								end
							end
						end
					else
						if prop.GetMethod and type(iCache[prop.GetMethod]) ~= "function" then prop.GetMethod = nil end
						if prop.SetMethod and type(iCache[prop.SetMethod]) ~= "function" then prop.SetMethod = nil end

						-- Auto generate GetMethod
						if autoProp and ( prop.Get == nil or prop.Get == true ) and not prop.GetMethod and prop.Field == nil then
							-- GetMethod
							if type(iCache["get" .. uname]) == "function" then
								prop.GetMethod = "get" .. uname
							elseif type(iCache["Get" .. uname]) == "function" then
								prop.GetMethod = "Get" .. uname
							elseif prop.Type == Boolean or prop.Type == BooleanNil then
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
						if autoProp and ( prop.Set == nil or prop.Set == true ) and not prop.SetMethod and prop.Field == nil then
							-- SetMethod
							if type(iCache["set" .. uname]) == "function" then
								prop.SetMethod = "set" .. uname
							elseif type(iCache["Set" .. uname]) == "function" then
								prop.SetMethod = "Set" .. uname
							elseif prop.Type == Boolean or prop.Type == BooleanNil then
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
							info.Event = info.Event or {}
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
						prop.SetDeepClone = ValidateFlags(Setter.DeepClone, prop.Setter) or nil
						prop.SetClone = ValidateFlags(Setter.Clone, prop.Setter) or prop.SetDeepClone

						if prop.Set == nil and not prop.SetMethod then
							if ValidateFlags(Setter.Retain, prop.Setter) and prop.Type then
								local tinfo = _NSInfo[prop.Type]

								if tinfo.Type == TYPE_CLASS or tinfo.Type == TYPE_INTERFACE then
									prop.SetRetain = true
								end
							end

							if prop.Get == nil and not prop.GetMethod then
								if ValidateFlags(Setter.Weak, prop.Setter) then prop.SetWeak = true end
							end
						end

						prop.Setter = nil
					end

					-- Validate the Getter
					if prop.Getter then
						prop.GetDeepClone = ValidateFlags(Getter.DeepClone, prop.Getter) or nil
						prop.GetClone = ValidateFlags(Getter.Clone, prop.Getter) or prop.GetDeepClone

						prop.Getter = nil
					end

					-- Auto generate Default
					if prop.Type and prop.Default == nil and prop.DefaultFunc == nil then
						local pinfo = _NSInfo[prop.Type]
						if pinfo and (pinfo.Type == TYPE_STRUCT or pinfo.Type == TYPE_ENUM) then prop.Default = pinfo.Default end
					end

					-- Auto generate Field or methods
					if (prop.Set == nil or (prop.Set == false and prop.DefaultFunc)) and not prop.SetMethod and prop.Get == nil and not prop.GetMethod then
						if prop.Field == true then prop.Field = nil end
						local field = prop.Field or "_" .. info.Name:match("^_*(.-)$") .. "_" .. uname

						if set.Synthesize and prop.Set == nil then
							local getName, setName

							if set.Synthesize == __Synthesize__.NameCases.Pascal then
								getName, setName = "Get" .. uname, "Set" .. uname
								if prop.Type == Boolean or prop.Type == BooleanNil then getName = "Is" .. uname end
							elseif set.Synthesize == __Synthesize__.NameCases.Camel then
								getName, setName = "get" .. uname, "set" .. uname
								if prop.Type == Boolean or prop.Type == BooleanNil then getName = "is" .. uname end
							end

							if set.SynthesizeGet then getName = set.SynthesizeGet end
							if set.SynthesizeSet then setName = set.SynthesizeSet end

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

								info.Method = info.Method or {}
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
								if prop.Type then tinsert(gbody, ([[value = Validate4Type(pType, value, "%s", "%s", 3)]]):format(name, name)) end
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

								info.FeatureModifier = info.FeatureModifier or {}
								info.FeatureModifier[getName] = TurnOnFlags(MD_STATIC_FEATURE, info.FeatureModifier[getName])
								info.FeatureModifier[setName] = TurnOnFlags(MD_STATIC_FEATURE, info.FeatureModifier[setName])

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

								info.Method = info.Method or {}
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
								if prop.Type then tinsert(gbody, ([[value = Validate4Type(pType, value, "%s", "%s", 3)]]):format(name, name)) end
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
				end
			end

			--- self property
			CloneWithOverride(iCache, info.Property, true)
		end

		-- AutoCache
		if info.SuperClass and _NSInfo[info.SuperClass].AutoCache then info.AutoCache = true end

		-- Simple Class Check(No Constructor, No Property)
		if info.Type == TYPE_CLASS then
			local isSimpleClass = true

			if info.Constructor or info.Property or (info.SuperClass and not _NSInfo[info.SuperClass].IsSimpleClass) then
				isSimpleClass = false
			elseif info.ExtendInterface then
				for _, IF in ipairs(info.ExtendInterface) do
					if _NSInfo[IF].Property then
						isSimpleClass = false
						break
					end
				end
			end

			info.IsSimpleClass = isSimpleClass or nil
		end

		-- One-required method interface check
		if info.Type == TYPE_INTERFACE then
			local isOneReqMethod = nil
			if info.FeatureModifier and info.Method then
				for name, mod in pairs(info.FeatureModifier) do
					if info.Method[name] and ValidateFlags(MD_REQUIRE_FEATURE, mod) then
						if isOneReqMethod then isOneReqMethod = false break end
						isOneReqMethod = name
					end
				end

				if info.ExtendInterface then
					if isOneReqMethod ~= false then
						for _, IF in ipairs(info.ExtendInterface) do
							local iInfo = _NSInfo[IF]
							if isOneReqMethod then
								if iInfo.IsOneReqMethod and iInfo.IsOneReqMethod ~= isOneReqMethod then
									isOneReqMethod = false
									break
								elseif iInfo.IsOneReqMethod == false then
									isOneReqMethod = false
									break
								end
							else
								if iInfo.IsOneReqMethod then
									isOneReqMethod = iInfo.IsOneReqMethod
								elseif iInfo.IsOneReqMethod == false then
									isOneReqMethod = false
									break
								end
							end
						end
					end
				end
			end
			info.IsOneReqMethod = isOneReqMethod
		end

		-- Refresh branch
		if info.ChildClass then
			for _, subcls in ipairs(info.ChildClass) do RefreshCache(subcls) end
		elseif info.ExtendChild then
			for _, subcls in ipairs(info.ExtendChild) do RefreshCache(subcls) end
		end
	end

	function RefreshStruct(strt)
		local info = _NSInfo[strt]

		if info.SubType == STRUCT_TYPE_MEMBER and (not info.Members or #(info.Members) == 0) then
			info.SubType = STRUCT_TYPE_CUSTOM
			info.Members = nil
		end

		-- validate default value if existed
		if info.Default ~= nil then
			if info.SubType ~= STRUCT_TYPE_CUSTOM then
				info.Default = nil
			elseif not pcall(ValidateStruct, info.Owner, info.Default) then
				info.Default = nil
			end
		end

		if info.SubType == STRUCT_TYPE_ARRAY then
			local ele = info.ArrayElement

			if ele and ele.Predefined then
				for k, v in pairs(ele.Predefined) do
					if k:lower() == "type" and IsNameSpace(v) and _NSInfo[v].Type then
						ele.Type = v
						break
					end
				end
				ele.Predefined = nil
			end
		elseif info.SubType == STRUCT_TYPE_MEMBER then
			for _, mem in ipairs(info.Members) do
				if mem.Predefined then
					for k, v in pairs(mem.Predefined) do
						k = k:lower()

						if k == "type" then
							if IsNameSpace(v) and _NSInfo[v].Type then
								mem.Type = v
							end
						elseif k == "default" then
							mem.Default = v
						elseif k == "require" then
							mem.Require = true
						end
					end

					mem.Predefined = nil

					if mem.Require then
						mem.Default = nil
					elseif mem.Type then
						if mem.Default ~= nil then
							mem.Default = GetValidatedValue(mem.Type, mem.Default)
						end
						if mem.Default == nil and _NSInfo[mem.Type].Default ~= nil then
							mem.Default = _NSInfo[mem.Type].Default
						end
					end
				end
			end
		end
	end
end

--------------------------------------------------
-- Feature Definition
--------------------------------------------------
do
	function checkTypeParams(...)
		local cnt = select('#', ...)
		local env, target, defintion, stack

		if cnt > 0 then
			if cnt > 4 then cnt = 4 end

			stack = select(cnt, ...)

			if type(stack) == "number" then
				cnt = cnt - 1
			else
				stack = nil
			end

			if cnt == 1 then
				local val = select(1, ...)
				local ty = type(val)

				if ty == "table" then
					if getmetatable(val) == nil then
						defintion = val
					elseif _NSInfo[val] then
						target = val
					end
				elseif ty == "string" then
					if val:find("^[%w_]+$") then
						target = val
					else
						defintion = val
					end
				elseif ty == "function" then
					defintion = val
				elseif _NSInfo[val] then
					target = val
				end
			elseif cnt == 2 then
				local val = select(2, ...)
				local ty = type(val)

				if ty == "table" then
					if getmetatable(val) == nil then
						defintion = val
					elseif _NSInfo[val] then
						target = val
					end
				elseif ty == "string" then
					if val:find("^[%w_]+$") then
						target = val
					else
						defintion = val
					end
				elseif ty == "function" then
					defintion = val
				elseif _NSInfo[val] then
					target = val
				end

				-- Check first value
				val = select(1, ...)
				ty = type(val)

				if target then
					if ty == "table" then env = val end
				elseif defintion then
					if ty == "table" then
						if _NSInfo[val] then
							target = val
						else
							env = val
						end
					elseif ty == "string" then
						if val:find("^[%w_]+$") then
							target = val
						end
					elseif _NSInfo[val] then
						target = val
					end
				else
					if ty == "table" then
						if getmetatable(val) == nil then
							defintion = val
						elseif _NSInfo[val] then
							target = val
						end
					elseif ty == "string" then
						if val:find("^[%w_]+$") then
							target = val
						else
							defintion = val
						end
					elseif ty == "function" then
						defintion = val
					elseif _NSInfo[val] then
						target = val
					end
				end
			elseif cnt == 3 then
				-- No match just check
				env, target, defintion = ...
				if type(env) ~= "table" then env = nil end
				if type(target) ~= "string" and not _NSInfo[target] then target = nil end
				if type(target) == "string" and not target:find("^[%w_]+$") then target = nil end
				local ty = type(defintion)
				if not (ty == "function" or ty == "table" or ty == "string") then defintion = nil end
			end
		end

		stack = stack or 2

		if type(defintion) == "string" then
			local ret, msg = loadstring("return function(_ENV) " .. defintion .. " end")
			if not ret then error(msg:match("%d+:%s*(.-)$") or msg, stack + 1) end
			ret, msg = pcall(ret)
			if not ret then error(msg:match("%d+:%s*(.-)$") or msg, stack + 1) end
			defintion = msg
		end

		return env, target, defintion, stack
	end

	function IsPropertyReadable(ns, name)
		local info = _NSInfo[ns]

		if info and (info.Type == TYPE_INTERFACE or info.Type == TYPE_CLASS) then
			local prop = info.Cache[name]
			if prop then return type(prop) == "table" and getmetatable(prop) == nil and (prop.Get or prop.GetMethod or prop.Field or prop.Default ~= nil) and true or false end
			prop = info.Property and info.Property[name]
			if prop and prop.IsStatic then return (prop.Get or prop.GetMethod or prop.Default ~= nil) and true or false end
		end
	end

	function IsPropertyWritable(ns, name)
		local info = _NSInfo[ns]

		if info and (info.Type == TYPE_INTERFACE or info.Type == TYPE_CLASS) then
			local prop = info.Cache[name]
			if prop then return type(prop) == "table" and getmetatable(prop) == nil and (prop.Set or prop.SetMethod or prop.Field) and true or false end
			prop = info.Property and info.Property[name]
			if prop and prop.IsStatic then return (prop.Set or prop.SetMethod) and true or false end
		end
	end

	function IsFinalFeature(ns, name, isSuper)
		ns = _NSInfo[ns]

		if not ns then return false end

		if not name then
			return ValidateFlags(MD_FINAL_FEATURE, ns.Modifier)
		else
			if isSuper and not ns.Cache[name] then return nil end

			-- Check self
			if ns.FeatureModifier and ValidateFlags(MD_FINAL_FEATURE, ns.FeatureModifier[name]) then return true end
			if ns.Method and ns.Method[name] then return isSuper and ValidateFlags(MD_FINAL_FEATURE, ns.Modifier) or false end
			if ns.Property and ns.Property[name] then return isSuper and ValidateFlags(MD_FINAL_FEATURE, ns.Modifier) or false end

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

	function IsExtend(IF, cls)
		if not IF or not cls or not _NSInfo[IF] or _NSInfo[IF].Type ~= TYPE_INTERFACE or not _NSInfo[cls] then return false end

		if IF == cls then return true end

		local cache = _NSInfo[cls].Cache4Interface
		if cache then for _, pIF in ipairs(cache) do if pIF == IF then return true end end end

		return false
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
		local key = _KeyMeta[meta]

		if not info.MetaTable[key] or info.MetaTable[key] == pre then
			return SaveMethod(info, meta, now)
		end
	end

	function UpdateMeta4Children(meta, sub, pre, now)
		if sub and pre ~= now then for _, cls in ipairs(sub) do UpdateMeta4Child(meta, cls, pre, now) end end
	end

	function SaveMethod(info, key, value)
		local storage = info
		local isMeta, rMeta, oldValue, isConstructor
		local rkey = key

		if key == info.Name then
			if info.Type == TYPE_CLASS then
				-- Constructor
				if ValidateFlags(MD_SEALED_FEATURE, info.Modifier) then return error(("%s is sealed, can't set the constructor."):format(tostring(info.Owner))) end
				isConstructor = true
				rkey = "Constructor"
			elseif info.Type == TYPE_INTERFACE then
				-- Initializer
				if ValidateFlags(MD_SEALED_FEATURE, info.Modifier) then return error(("%s is sealed, can't set the initializer."):format(tostring(info.Owner))) end
				info.Initializer = value
				return
			elseif info.Type == TYPE_STRUCT then
				-- Valiator
				if ValidateFlags(MD_SEALED_FEATURE, info.Modifier) then return error(("%s is sealed, can't set the validator."):format(tostring(info.Owner))) end
				info.Validator = value
				return
			end
		elseif key == DISPOSE_METHOD and (info.Type == TYPE_CLASS or info.Type == TYPE_INTERFACE) then
			-- Dispose
			if ValidateFlags(MD_SEALED_FEATURE, info.Modifier) then return error(("%s is sealed, can't set the dispose method."):format(tostring(info.Owner))) end
			info[DISPOSE_METHOD] = value
			return
		elseif _KeyMeta[key] and info.Type == TYPE_CLASS then
			-- Meta-method
			if ValidateFlags(MD_SEALED_FEATURE, info.Modifier) then return error(("%s is sealed, can't set the meta-method."):format(tostring(info.Owner))) end
			isMeta = true
			rkey = _KeyMeta[key]
			storage = info.MetaTable
			oldValue = storage[rkey]
		else
			-- Method
			if info.Type == TYPE_INTERFACE or info.Type == TYPE_CLASS then
				if IsFinalFeature(info.Owner, key) then return error(("%s.%s is final, can't be overwrited."):format(tostring(info.Owner), key)) end
				if ValidateFlags(MD_SEALED_FEATURE, info.Modifier) and (info.Cache[key] or info.Method and info.Method[key]) then return error(("%s.%s is sealed, can't be overwrited."):format(tostring(info.Owner), key)) end
			elseif info.Type == TYPE_STRUCT then
				if ValidateFlags(MD_SEALED_FEATURE, info.Modifier) and info.Method and info.Method[key] then return error(("%s.%s is sealed, can't be overwrited."):format(tostring(info.Owner), key)) end
				if info.Members and info.Members[key] then return error(("'%s' already existed as struct member."):format(key)) end
			end
			info.Method = info.Method or {}
			storage = info.Method
		end

		if ATTRIBUTE_INSTALLED then
			storage[rkey] = ConsumePreparedAttributes(value, isConstructor and AttributeTargets.Constructor or AttributeTargets.Method, info.Owner, key) or value
		else
			storage[rkey] = value
		end

		-- Update child's meta-method
		if isMeta then return UpdateMeta4Children(key, info.ChildClass, oldValue, storage[rkey]) end
	end

	function SaveProperty(info, name, set)
		if type(set) ~= "table" then return error([[Usage: property "Name" { Property Definition }]]) end

		local prop = {}
		info.Property = info.Property or {}
		info.Property[name] = prop

		prop.Name = name
		prop.Predefined = set

		return ATTRIBUTE_INSTALLED and ConsumePreparedAttributes(prop, AttributeTargets.Property, info.Owner, name)
	end

	function SaveEvent(info, name)
		if ValidateFlags(MD_SEALED_FEATURE, info.Modifier) and (info.Cache[name] or info.Event and info.Event[name]) then return error(("%s.%s is sealed, can't be overwrited."):format(tostring(info.Owner), name)) end

		info.Event = info.Event or {}
		info.Event[name] = info.Event[name] or Event(name)

		return ATTRIBUTE_INSTALLED and ConsumePreparedAttributes(info.Event[name], AttributeTargets.Event, info.Owner, name)
	end

	function SaveExtend(info, IF)
		if ValidateFlags(MD_SEALED_FEATURE, info.Modifier) then return error(("%s is sealed, can't extend interface."):format(tostring(info.Owner))) end

		local IFInfo = _NSInfo[IF]

		if not IFInfo or IFInfo.Type ~= TYPE_INTERFACE then
			return error("Usage: extend (interface) : 'interface' - interface expected")
		elseif ValidateFlags(MD_FINAL_FEATURE, IFInfo.Modifier) then
			return error(("%s is marked as final, can't be extened."):format(tostring(IF)))
		end

		if info.Type == TYPE_CLASS then
			if IFInfo.RequireClass then
				if not IsChildClass(IFInfo.RequireClass, info.Owner) then
					return error(("Usage: extend (%s) : %s should be sub-class of %s."):format(tostring(IF), tostring(info.Owner), tostring(IFInfo.RequireClass)))
				end
			elseif IFInfo.ExtendInterface then
				for _, sIF in ipairs(IFInfo.ExtendInterface) do
					local req = _NSInfo[sIF].RequireClass

					if req and not IsChildClass(req, info.Owner) then
						return error(("Usage: extend (%s) : %s should be sub-class of %s."):format(tostring(IF), tostring(info.Owner), tostring(req)))
					end
				end
			end
		elseif info.Type == TYPE_INTERFACE then
			if IsExtend(info.Owner, IF) then
				return error(("%s is extended from %s, can't be used here."):format(tostring(IF), tostring(info.Owner)))
			end
			if info.RequireClass then
				if IFInfo.RequireClass then
					if not IsChildClass(IFInfo.RequireClass, info.RequireClass) then
						return error(("%s require class %s, it's conflicted with current settings."):format(tostring(IF), tostring(IFInfo.RequireClass)))
					end
				else
					if IFInfo.ExtendInterface then
						for _, sIF in ipairs(IFInfo.ExtendInterface) do
							local req = _NSInfo[sIF].RequireClass

							if req and not IsChildClass(req, info.RequireClass) then
								return error(("%s require class %s, it's conflicted with current settings."):format(tostring(sIF), tostring(req)))
							end
						end
					end
				end
			else
				if IFInfo.RequireClass then
					if info.ExtendInterface then
						for _, sIF in ipairs(info.ExtendInterface) do
							local req = _NSInfo[sIF].RequireClass

							if req and not IsChildClass(req, IFInfo.RequireClass) and not IsChildClass(IFInfo.RequireClass, req) then
								return error(("%s require class %s, it's conflicted with current settings."):format(tostring(IF), tostring(IFInfo.RequireClass)))
							end
						end
					end
				elseif info.ExtendInterface and IFInfo.ExtendInterface then
					local cache = CACHE_TABLE()
					local pass = true

					for _, sIF in ipairs(info.ExtendInterface) do
						local req = _NSInfo[sIF].RequireClass

						if req then tinsert(cache, req) end
					end

					if #cache > 0 then
						for _, sIF in ipairs(IFInfo.ExtendInterface) do
							local req = _NSInfo[sIF].RequireClass

							if req then
								for _, required in ipairs(cache) do
									if not IsChildClass(req, required) and not IsChildClass(required, req) then
										pass = false
										break
									end
								end
							end

							if not pass then break end
						end

						while tremove(cache) do end
					end

					CACHE_TABLE(cache)

					if not pass then
						return error(("%s require class %s, it's conflicted with current settings."):format(tostring(IF), tostring(IFInfo.RequireClass)))
					end
				end
			end
		end

		info.ExtendInterface = info.ExtendInterface or {}

		-- Check if IF is already extend by extend tree
		for _, pIF in ipairs(info.ExtendInterface) do if IsExtend(IF, pIF) then return end end

		local owner = info.Owner
		for i = #(info.ExtendInterface), 1, -1 do
			local pIF = info.ExtendInterface[i]
			if IsExtend(pIF, IF) then
				local pExtend = _NSInfo[pIF].ExtendChild
				for j, v in ipairs(pExtend) do
					if v == owner then
						tremove(pExtend, j)
						break
					end
				end
				tremove(info.ExtendInterface, i)
			end
		end

		IFInfo.ExtendChild = IFInfo.ExtendChild or setmetatable({}, WEAK_VALUE)
		tinsert(IFInfo.ExtendChild, owner)

		tinsert(info.ExtendInterface, IF)
	end

	function SaveInherit(info, superCls)
		if ValidateFlags(MD_SEALED_FEATURE, info.Modifier) then return error(("%s is sealed, can't set super class."):format(tostring(info.Owner))) end

		local superInfo = _NSInfo[superCls]

		if not superInfo or superInfo.Type ~= TYPE_CLASS then return error("Usage: inherit (class) : 'class' - class expected") end
		if ValidateFlags(MD_FINAL_FEATURE, superInfo.Modifier) then return error(("%s is marked as final, can't be inherited."):format(tostring(superCls))) end
		if IsChildClass(info.Owner, superCls) then return error(("%s is inherited from %s, can't be used as super class."):format(tostring(superCls), tostring(info.Owner))) end
		if info.SuperClass == superCls then return end
		if info.SuperClass then return error(("%s is inherited from %s, can't inherit another class."):format(tostring(info.Owner), tostring(info.SuperClass))) end

		superInfo.ChildClass = superInfo.ChildClass or setmetatable({}, WEAK_VALUE)
		tinsert(superInfo.ChildClass, info.Owner)

		info.SuperClass = superCls

		-- Copy MetaTable
		if ATTRIBUTE_INSTALLED then ClearPreparedAttributes() end

		for meta, rMeta in pairs(_KeyMeta) do
			if superInfo.MetaTable[rMeta] then UpdateMeta4Child(meta, info.Owner, nil, superInfo.MetaTable[rMeta]) end
		end

		-- Clone Attributes
		return ATTRIBUTE_INSTALLED and InheritAttributes(superCls, info.Owner, AttributeTargets.Class)
	end

	local function CheckRequireConflict(info, req, child)
		-- Only check the conflict caused by child interfaces or classes
		if child and info.RequireClass and not IsChildClass(req, info.RequireClass) then return false, info.Owner end

		if info.ExtendChild then
			for _, subcls in ipairs(info.ExtendChild) do
				local sinfo = _NSInfo[subcls]
				if sinfo.Type == TYPE_CLASS then
					if not IsChildClass(req, subcls) then return false, subcls end
				elseif sinfo.Type == TYPE_INTERFACE then
					local ok, ret = CheckRequireConflict(sinfo, req, true)
					if not ok then return false, ret end
				end
			end
		end

		return true
	end

	function SaveRequire(info, req)
		if ValidateFlags(MD_SEALED_FEATURE, info.Modifier) then return error(("%s is sealed, can't set the required class."):format(tostring(info.Owner))) end
		if not rawget(_NSInfo, req) or _NSInfo[req].Type ~= TYPE_CLASS then error("Usage : require 'class'") end

		local ok, ret = CheckRequireConflict(info, req)
		if not ok then return error(("The new required class is conflicted with %s that extened from the interface."):format(tostring(ret))) end

		info.RequireClass = req
	end

	function SaveStructMember(info, key, value)
		-- Check if a member setting
		if tonumber(key) and type(value) == "table" and getmetatable(value) == nil then
			for k, v in pairs(value) do
				if type(k) == "string" and k:lower() == "name" and type(v) == "string" and not tonumber(v) then
					key = v
					value[k] = nil
					break
				end
			end
		end

		-- Save member
		local memInfo = { Name = key }

		-- Validate the value
		if IsNameSpace(value) and _NSInfo[value].Type then value = { Type = value } end

		if type(value) ~= "table" then return error([[Usage: member "Name" { -- Field Definition }]]) end

		memInfo.Predefined = value

		-- Check the struct type
		if tonumber(key) then
			if info.SubType ~= STRUCT_TYPE_ARRAY then
				info.SubType = STRUCT_TYPE_ARRAY
				info.Members = nil
			end
		elseif info.SubType ~= STRUCT_TYPE_MEMBER then
			info.SubType = STRUCT_TYPE_MEMBER
			info.ArrayElement = nil
		end

		if info.SubType == STRUCT_TYPE_MEMBER then
			-- Insert member
			info.Members = info.Members or {}
			for _, v in ipairs(info.Members) do if v.Name == key then return error(("struct member '%s' already existed."):format(key)) end end
			tinsert(info.Members, memInfo)
			info.Members[key] = memInfo

			if ATTRIBUTE_INSTALLED then ConsumePreparedAttributes(memInfo, AttributeTargets.Member, info.Owner, key) end
		elseif info.SubType == STRUCT_TYPE_ARRAY then
			info.ArrayElement = memInfo
		end
	end

	function SaveFeature(info, key, value)
		-- Forbidden
		if key == DISPOSE_METHOD and type(value) ~= "function" and (info.Type == TYPE_CLASS or info.Type == TYPE_INTERFACE) then
			return error(("'%s' must be a function as the dispose method."):format(key))
		elseif key == info.Name and type(value) ~= "function" then
			return error(("'%s' must be a function as the %s."):format(key, info.Type == TYPE_CLASS and "Constructor" or info.Type == TYPE_INTERFACE and "Initializer" or "Validator"))
		elseif _KeyMeta[key] and type(value) ~= "function" and info.Type == TYPE_CLASS then
			return error(("'%s' must be a function as meta-method."):format(key))
		end

		-- Save feature
		if tonumber(key) then
			if IsNameSpace(value) then
				local vType = _NSInfo[value].Type

				if info.Type == TYPE_STRUCT then
					-- Array element
					return SaveStructMember(info, key, value)
				elseif vType == TYPE_CLASS then
					if info.Type == TYPE_CLASS then
						-- inherit
						return SaveInherit(info, value)
					elseif info.Type == TYPE_INTERFACE then
						-- require
						return SaveRequire(info, value)
					end
				elseif vType == TYPE_INTERFACE then
					if info.Type == TYPE_CLASS or info.Type == TYPE_INTERFACE then
						-- extend
						return SaveExtend(info, value)
					end
				end
			elseif type(value) == "string" and not tonumber(value) and (info.Type == TYPE_CLASS or info.Type == TYPE_INTERFACE) then
				-- event
				return SaveEvent(info, value)
			elseif type(value) == "function" then
				return SaveMethod(info, info.Name, value)
			elseif info.Type == TYPE_STRUCT then
				if type(value) == "table" then
					SaveStructMember(info, key, value)
				else
					-- Default value for struct
					info.Default = value
				end
				return
			end
		elseif type(key) == "string" then
			local vType = type(value)

			if IsNameSpace(value) then
				if info.Type == TYPE_CLASS or info.Type == TYPE_INTERFACE then
					return SaveProperty(info, key, { Type = value })
				elseif info.Type == TYPE_STRUCT then
					return SaveStructMember(info, key, value)
				end
			elseif vType == "table" then
				if info.Type == TYPE_CLASS or info.Type == TYPE_INTERFACE then
					return SaveProperty(info, key, value)
				elseif info.Type == TYPE_STRUCT then
					return SaveStructMember(info, key, value)
				end
			elseif vType == "function" then
				return SaveMethod(info, key, value)
			elseif value == true and (info.Type == TYPE_CLASS or info.Type == TYPE_INTERFACE) then
				return SaveEvent(info, key)
			end
		end

		return error(("The definition '%s' for %s is not supported."):format(tostring(key), tostring(info.Owner)))
	end

	function ParseTableDefinition(info, definition)
		-- Number keys means the core of the feature
		for k, v in ipairs(definition) do SaveFeature(info, k, v) end

		-- Only string key can be accepted(number is handled)
		for k, v in pairs(definition) do if type(k) == "string" then SaveFeature(info, k, v) end end
	end

	function import_Def(env, name)
		if type(name) ~= "string" and not IsNameSpace(name) then return error([[Usage: import "namespaceA.namespaceB"]]) end

		local ns

		if type(name) == "string" then
			ns = GetNameSpace(PROTYPE_NAMESPACE, name)
		elseif IsNameSpace(name) then
			ns = name
		end

		if not ns then return error(("No namespace is found with name : %s"):format(name)) end

		env[IMPORT_ENV_FIELD] = env[IMPORT_ENV_FIELD] or {}

		for _, v in ipairs(env[IMPORT_ENV_FIELD]) do if v == ns then return end end

		tinsert(env[IMPORT_ENV_FIELD], ns)
	end

	local fetchPropertyCache = setmetatable({}, WEAK_KEY)

	local function fetchPropertyDefine(set)
		local cache = fetchPropertyCache[running() or 0]
		if not cache then return end

		local info, name = cache.Info, cache.Name

		cache.Info = nil
		cache.Name = nil

		local ok, msg = pcall(SaveProperty, info, name, set)
		if not ok then error(msg:match("%d+:%s*(.-)$") or msg, 2) end
	end

	function property_Def(env, name)
		if type(name) ~= "string" or strtrim(name:match("[_%w]+")) == "" then
			return error([[Usage: property "Name" { Property Definition }]])
		end

		local cur = running() or 0

		fetchPropertyCache[cur] = fetchPropertyCache[cur] or {}

		fetchPropertyCache[cur].Info = _NSInfo[env[OWNER_FIELD]]
		fetchPropertyCache[cur].Name = name:match("[_%w]+")

		return fetchPropertyDefine
	end

	local fetchMemberCache = setmetatable({}, WEAK_KEY)

	local function fetchMemberDefine(set)
		local cache = fetchMemberCache[running() or 0]
		if not cache then return end

		local info, name = cache.Info, cache.Name

		cache.Info = nil
		cache.Name = nil

		local ok, msg = pcall(SaveStructMember, info, name, set)
		if not ok then error(msg:match("%d+:%s*(.-)$") or msg, 2) end
	end

	function member_Def(env, name)
		if type(name) ~= "string" or strtrim(name:match("[_%w]+")) == "" then
			return error([[Usage: member "Name" { -- Field Definition }]])
		end

		local cur = running() or 0

		fetchMemberCache[cur] = fetchMemberCache[cur] or {}

		fetchMemberCache[cur].Info = _NSInfo[env[OWNER_FIELD]]
		fetchMemberCache[cur].Name = name:match("[_%w]+")

		return fetchMemberDefine
	end

	function event_Def(env, name)
		if type(name) ~= "string" or not name:match("^[_%w]+$") then return error([[Usage: event "eventName"]]) end

		local info = _NSInfo[env[OWNER_FIELD]]

		if not info then return error("can't use event here.") end

		return SaveEvent(info, name)
	end

	function extend_Def(env, name)
		if name and type(name) ~= "string" and not IsNameSpace(name) then return error([[Usage: extend "namespace.interfacename"]]) end

		local info = _NSInfo[env[OWNER_FIELD]]
		local IF

		if type(name) == "string" then
			IF = GetNameSpace(info.NameSpace, name) or env[name]

			if not IF then
				for subname in name:gmatch("[_%w]+") do
					IF = IF and IF[subname] or env[subname]

					if not IsNameSpace(IF) then
						return error(("No interface is found with the name : %s"):format(name))
					end
				end
			end
		else
			IF = name
		end

		return SaveExtend(info, IF)
	end

	function extend_IF(env, name)
		extend_Def(env, name)
		return _KeyWord4IFEnv:GetKeyword(env, "extend")
	end

	function extend_Cls(env, name)
		extend_Def(env, name)
		return _KeyWord4ClsEnv:GetKeyword(env, "extend")
	end

	function inherit_Def(env, name)
		if name and type(name) ~= "string" and not IsNameSpace(name) then return error([[Usage: inherit "namespace.classname"]]) end

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

					if not IsNameSpace(superCls) then return error(("No class is found with the name : %s"):format(name)) end
				end
			end
		else
			superCls = name
		end

		return SaveInherit(info, superCls)
	end

	function require_IF(env, name)
		if name and type(name) ~= "string" and not IsNameSpace(name) then return error([[Usage: require "namespace.classname"]]) end

		local info = _NSInfo[env[OWNER_FIELD]]
		local cls

		if type(name) == "string" then
			cls = GetNameSpace(info.NameSpace, name) or env[name]

			if not cls then
				for subname in name:gmatch("[_%w]+") do
					cls = cls and cls[subname] or env[subname]

					if not IsNameSpace(cls) then return error(("No class is found with the name : %s"):format(name)) end
				end
			end
		else
			cls = name
		end

		return SaveRequire(info, cls)
	end
end

------------------------------------------------------
-- Interface
------------------------------------------------------
do
	_KeyWord4IFEnv = _KeywordAccessor()

	-- metatable for interface's env
	_MetaIFEnv = { __metatable = true }
	_MetaIFDefEnv = {}
	do
		local function __index(self, info, key)
			local value

			-- Check namespace
			if info.NameSpace then
				if key == _NSInfo[info.NameSpace].Name then
					return info.NameSpace
				else
					value = info.NameSpace[key]
					if value ~= nil then return value end
				end
			end

			-- Check imports
			if rawget(self, IMPORT_ENV_FIELD) then
				for _, ns in ipairs(self[IMPORT_ENV_FIELD]) do
					if key == _NSInfo[ns].Name then
						return ns
					else
						value = ns[key]
						if value ~= nil then return value end
					end
				end
			end

			-- Check base namespace
			value = GetNameSpace(PROTYPE_NAMESPACE, key)
			if value then return value end

			-- Check method, so definition environment can use existed method
			-- created by another definition environment for the same interface
			value = info.Method and info.Method[key]
			if value then return value end

			-- Check event
			value = info.Event and info.Event[key]
			if value then return value end

			-- Check Base
			return self[BASE_ENV_FIELD][key]
		end

		_MetaIFEnv.__index = function(self, key)
			local info = _NSInfo[self[OWNER_FIELD]]
			local value

			-- Check owner
			if key == info.Name then return info.Owner end

			-- Check keywords
			value = _KeyWord4IFEnv:GetKeyword(self, key)
			if value then return value end

			-- Check Static Property
			value = info.Property and info.Property[key]
			if value and value.IsStatic then return info.Owner[key] end

			-- Check others
			value = __index(self, info, key)
			if value ~= nil then rawset(self, key, value) return value end
		end

		-- Don't cache item in definition to reduce some one time access feature
		_MetaIFDefEnv.__index = function(self, key)
			local info = _NSInfo[self[OWNER_FIELD]]
			local value

			-- Check owner
			if key == info.Name then return info.Owner end

			-- Check keywords
			value = _KeyWord4IFEnv:GetKeyword(self, key)
			if value then return value end

			-- Check Static Property
			value = info.Property and info.Property[key]
			if value and value.IsStatic then return info.Owner[key] end

			-- Check others
			return __index(self, info, key)
		end

		_MetaIFDefEnv.__newindex = function(self, key, value)
			local info = _NSInfo[self[OWNER_FIELD]]

			if _KeyWord4IFEnv:GetKeyword(self, key) then error(("'%s' is a keyword."):format(key), 2) end

			if key == info.Name or key == DISPOSE_METHOD or (type(key) == "string" and type(value) == "function") then
				local ok, msg = pcall(SaveFeature, info, key, value)
				if not ok then error(msg:match("%d+:%s*(.-)$") or msg, 2) end
				return
			end

			-- Check Static Property
			if info.Property and info.Property[key] and info.Property[key].IsStatic then
				info.Owner[key] = value
				return
			end

			rawset(self, key, value)
		end

		_MetaIFDefEnv.__call = function(self, definition)
			ParseDefinition(self, definition)

			local owner = self[OWNER_FIELD]

			setfenv(2, self[BASE_ENV_FIELD])
			_KeyWord4IFEnv:ClearKeyword()
			pcall(setmetatable, self, _MetaIFEnv)
			RefreshCache(owner)

			if ATTRIBUTE_INSTALLED then ApplyRestAttribute(owner, AttributeTargets.Interface) end

			return owner
		end
	end

	------------------------------------
	--- Create interface in currect environment's namespace or default namespace
	------------------------------------
	function interface(...)
		local env, name, definition, stack = checkTypeParams(...)

		local fenv = env or getfenv(stack) or _G

		local ok, IF = pcall(GetDefineNS, fenv, name, TYPE_INTERFACE)
		if not ok then error(IF:match("%d+:%s*(.-)$") or IF, stack) end

		local info = _NSInfo[IF]

		if not info then
			error([[Usage: interface "name"]], stack)
		elseif info.Type and info.Type ~= TYPE_INTERFACE then
			error(("%s is existed as %s, not interface."):format(tostring(name), tostring(info.Type)), stack)
		end

		-- Check if the class is final
		if ValidateFlags(MD_SEALED_FEATURE, info.Modifier) then error("The interface is sealed, can't be re-defined.", stack) end

		if not info.Type then
			info.Type = TYPE_INTERFACE
			info.Cache = info.Cache or {}
		end

		-- No super target for interface
		if ATTRIBUTE_INSTALLED then ConsumePreparedAttributes(info.Owner, AttributeTargets.Interface) end

		if type(definition) == "table" then
			local ok, msg = pcall(ParseTableDefinition, info, definition)
			if not ok then error(msg:match("%d+:%s*(.-)$") or msg, stack) end

			RefreshCache(IF)
			if ATTRIBUTE_INSTALLED then ApplyRestAttribute(IF, AttributeTargets.Interface) end

			return IF
		else
			-- Generate the interface environment
			local interfaceEnv = setmetatable({
				[OWNER_FIELD] = IF,
				[BASE_ENV_FIELD] = fenv,
			}, _MetaIFDefEnv)

			-- Set namespace
			SetNameSpace4Env(interfaceEnv, IF)

			if definition then
				setfenv(definition, interfaceEnv)
				definition(interfaceEnv)

				_KeyWord4IFEnv:ClearKeyword()
				pcall(setmetatable, interfaceEnv, _MetaIFEnv)
				RefreshCache(IF)
				if ATTRIBUTE_INSTALLED then ApplyRestAttribute(IF, AttributeTargets.Interface) end

				return IF
			else
				-- save interface to the environment
				if type(name) == "string" then rawset(fenv, name, IF) end

				-- Set the environment to interface's environment
				setfenv(stack, interfaceEnv)

				return interfaceEnv
			end
		end
	end

	------------------------------------
	--- End the interface's definition and restore the environment
	------------------------------------
	function endinterface(env, name, stack)
		stack = stack or 2
		if ATTRIBUTE_INSTALLED then ClearPreparedAttributes() end

		local info = _NSInfo[env[OWNER_FIELD]]

		if info.Name == name or info.Owner == name then
			_KeyWord4IFEnv:ClearKeyword()
			setmetatable(env, _MetaIFEnv)
			setfenv(stack, env[BASE_ENV_FIELD])
			RefreshCache(info.Owner)
			if ATTRIBUTE_INSTALLED then ApplyRestAttribute(info.Owner, AttributeTargets.Interface) end
			return env[BASE_ENV_FIELD]
		else
			error(("%s is not closed."):format(info.Name), stack)
		end
	end

	function ParseDefinition(self, definition)
		local info = _NSInfo[self[OWNER_FIELD]]
		if type(definition) == "table" then
			local ok, msg = pcall(ParseTableDefinition, info, definition)
			if not ok then error(msg:match("%d+:%s*(.-)$") or msg, 3) end
		else
			if type(definition) == "string" then
				local errorMsg
				definition, errorMsg = loadstring("return function(_ENV) " .. definition .. " end")
				if definition then
					definition = definition()
				else
					error(errorMsg, 3)
				end
			end

			if type(definition) == "function" then
				setfenv(definition, self)
				return definition(self)
			end
		end
	end

	function BuildAnonymousClass(info)
		local cls = class {}
		local cInfo	= _NSInfo[cls]
		SaveExtend(_NSInfo[cls], info.Owner)
		RefreshCache(cls)
		cInfo.OriginIF = info.Owner
		info.AnonymousClass = cls
		return cls
	end

	function Interface2Obj(info, init)
		if  type(init) == "string" then
			local ok, ret = pcall(Lambda, init)
			if not ok then error(ret:match("%d+:%s*(.-)$") or ret, 3) end
			init = ret
		end

		if type(init) == "function" then
			if not info.IsOneReqMethod then error(("%s is not a one required method interface."):format(tostring(info.Owner)), 3) end
			init = { [info.IsOneReqMethod] = init }
		end

		return (info.AnonymousClass or BuildAnonymousClass(info))(init)
	end

	_KeyWord4IFEnv.extend = extend_IF
	_KeyWord4IFEnv.import = import_Def
	_KeyWord4IFEnv.event = event_Def
	_KeyWord4IFEnv.property = property_Def
	_KeyWord4IFEnv.endinterface = endinterface
	_KeyWord4IFEnv.require = require_IF

	_KeyWord4IFEnv.doc = document
end

------------------------------------------------------
-- Class
------------------------------------------------------
do
	_KeyWord4ClsEnv = _KeywordAccessor()

	_KeyMeta = {
		__add = "__add",            -- a + b
		__sub = "__sub",            -- a - b
		__mul = "__mul",            -- a * b
		__div = "__div",            -- a / b
		__mod = "__mod",            -- a % b
		__pow = "__pow",            -- a ^ b
		__unm = "__unm",            -- - a
		__concat = "__concat",      -- a..b
		__len = "__len",            -- #a
		__eq = "__eq",              -- a == b
		__lt = "__lt",              -- a < b
		__le = "__le",              -- a <= b
		__index = "___index",       -- return a[b]
		__newindex = "___newindex", -- a[b] = v
		__call = "__call",          -- a()
		__gc = "__gc",              -- dispose a
		__tostring = "__tostring",  -- tostring(a)
		__exist = "__exist",        -- ClassName(...)	-- return object if existed
		__idiv = "__idiv",          -- // floor division
		__band = "__band",          -- & bitwise and
		__bor = "__bor",            -- | bitwise or
		__bxor = "__bxor",          -- ~ bitwise exclusive or
		__bnot = "__bnot",          -- ~ bitwise unary not
		__shl = "__shl",            -- << bitwise left shift
		__shr = "__shr",            -- >> bitwise right shift
	}

	--------------------------------------------------
	-- Init & Dispose System
	--------------------------------------------------
	do
		function InitObjectWithInterface(info, obj)
			if not info.Cache4Interface then return end
			for _, IF in ipairs(info.Cache4Interface) do
				info = _NSInfo[IF]
				if info.Initializer then info.Initializer(obj) end
			end
		end

		------------------------------------
		--- Dispose this object
		------------------------------------
		function DisposeObject(self)
			local objCls = getmetatable(self)
			local info, disfunc

			info = objCls and _NSInfo[objCls]

			if not info then return end

			local cache = info.Cache4Interface
			if cache then
				for i = #(cache), 1, -1 do
					disfunc = _NSInfo[cache[i]][DISPOSE_METHOD]

					if disfunc then pcall(disfunc, self) end
				end
			end

			-- Call Class Dispose
			while objCls do
				disfunc = _NSInfo[objCls][DISPOSE_METHOD]

				if disfunc then pcall(disfunc, self) end

				objCls = _NSInfo[objCls].SuperClass
			end

			-- No dispose to a unique object
			if info.UniqueObject then return end

			-- Clear the table
			wipe(self)
			rawset(self, "Disposed", true)
		end
	end

	-- metatable for class's env
	_MetaClsEnv = { __metatable = true }
	_MetaClsDefEnv = {}
	do
		local function __index(self, info, key)
			if key == "Super" then
				info = _NSInfo[info.SuperClass]
				if info then
					return info.ClassAlias or BuildClassAlias(info)
				else
					error("The class has no super class.", 3)
				end
			end

			if key == "This" then return info.ClassAlias or BuildClassAlias(info) end

			local value

			-- Check namespace
			if info.NameSpace then
				if key == _NSInfo[info.NameSpace].Name then
					return info.NameSpace
				else
					value = info.NameSpace[key]
					if value ~= nil then return value end
				end
			end

			-- Check imports
			if rawget(self, IMPORT_ENV_FIELD) then
				for _, ns in ipairs(self[IMPORT_ENV_FIELD]) do
					if key == _NSInfo[ns].Name then
						return ns
					else
						value = ns[key]
						if value ~= nil then return value end
					end
				end
			end

			-- Check base namespace
			value = GetNameSpace(PROTYPE_NAMESPACE, key)
			if value then return value end

			-- Check method, so definition environment can use existed method
			-- created by another definition environment for the same class
			value = info.Method and info.Method[key]
			if value then return value end

			-- Check event
			value = info.Event and info.Event[key]
			if value then return value end

			-- Check meta-methods
			if _KeyMeta[key] then
				value = info.MetaTable[_KeyMeta[key]]
				if value then return value end
			end

			-- Check Base
			return self[BASE_ENV_FIELD][key]
		end

		_MetaClsEnv.__index = function(self, key)
			local info = _NSInfo[self[OWNER_FIELD]]
			local value

			-- Check owner
			if key == info.Name then return info.Owner end

			-- Check keywords
			value = _KeyWord4ClsEnv:GetKeyword(self, key)
			if value then return value end

			-- Check Static Property
			value = info.Property and info.Property[key]
			if value and value.IsStatic then return info.Owner[key] end

			-- Check others
			value = __index(self, info, key)
			if value ~= nil then rawset(self, key, value) return value end
		end

		_MetaClsDefEnv.__index = function(self, key)
			local info = _NSInfo[self[OWNER_FIELD]]
			local value

			-- Check owner
			if key == info.Name then return info.Owner end

			-- Check keywords
			value = _KeyWord4ClsEnv:GetKeyword(self, key)
			if value then return value end

			-- Check Static Property
			value = info.Property and info.Property[key]
			if value and value.IsStatic then return info.Owner[key] end

			-- Check others
			return __index(self, info, key)
		end

		_MetaClsDefEnv.__newindex = function(self, key, value)
			local info = _NSInfo[self[OWNER_FIELD]]

			if _KeyWord4ClsEnv:GetKeyword(self, key) then error(("'%s' is a keyword."):format(key), 2) end

			if key == info.Name or key == DISPOSE_METHOD or _KeyMeta[key] or (type(key) == "string" and type(value) == "function") then
				local ok, msg = pcall(SaveFeature, info, key, value)
				if not ok then error(msg:match("%d+:%s*(.-)$") or msg, 2) end
				return
			end

			-- Check Static Property
			if info.Property and info.Property[key] and info.Property[key].IsStatic then
				info.Owner[key] = value
				return
			end

			rawset(self, key, value)
		end

		_MetaClsDefEnv.__call = function(self, definition)
			ParseDefinition(self, definition)

			local owner = self[OWNER_FIELD]

			setfenv(2, self[BASE_ENV_FIELD])
			_KeyWord4ClsEnv:ClearKeyword()
			pcall(setmetatable, self, _MetaClsEnv)
			RefreshCache(owner)
			local info = _NSInfo[owner]
			if ATTRIBUTE_INSTALLED then ApplyRestAttribute(owner, AttributeTargets.Class) end

			-- Validate the interface
			ValidateClass(info, 3)

			return owner
		end
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
				if info.AutoCache then
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
				if oper.Set == false then error(("%s can't be set."):format(key), 2) end
				if oper.Type then value = Validate4Type(oper.Type, value, key, key, 3) end
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
						error(("%s can't be set."):format(key), 2)
					end
				end
			end
		end

		-- Custom newindex metametods
		oper = info.MetaTable.___newindex
		if oper then return oper(self, key, value) end

		rawset(self, key, value)
	end

	function GenerateMetaTable(info)
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
					if info.AutoCache then
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
					if oper.Set == false then error(("%s can't be set."):format(key), 2) end
					if oper.Type then value = Validate4Type(oper.Type, value, key, key, 3) end
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
							error(("%s can't be set."):format(key), 2)
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

	function ValidateClass(info, stack)
		if not info.ExtendInterface then return end
		for _, IF in ipairs(info.ExtendInterface) do
			local sinfo = _NSInfo[IF]

			if sinfo.FeatureModifier then
				if sinfo.Method then
					for name, func in pairs(sinfo.Method) do
						if ValidateFlags(MD_REQUIRE_FEATURE, sinfo.FeatureModifier[name]) and func == info.Cache[name] then
							error(("The %s lack method declaration for [%s] %s."):format(tostring(info.Owner), tostring(IF), name), stack)
						end
					end
				end

				if sinfo.Property then
					for name, prop in pairs(sinfo.Property) do
						if ValidateFlags(MD_REQUIRE_FEATURE, sinfo.FeatureModifier[name]) then
							local iprop = info.Cache[name]

							if not (iprop and type(iprop) == "table" and getmetatable(iprop) == nil) then
								error(("The %s lack property declaration for [%s] %s."):format(tostring(info.Owner), tostring(IF), name), stack)
							elseif (prop.Type and iprop.Type ~= prop.Type) or (IsPropertyReadable(IF, name) and not IsPropertyReadable(info.Owner, name)) or (IsPropertyWritable(IF, name) and not IsPropertyWritable(info.Owner, name)) then
								if not iprop.Type then
									iprop.Type = prop.Type
									if iprop.Default ~= nil then
										iprop.Default = GetValidatedValue(iprop.Type, iprop.Default)
									end
								else
									error(("The %s has wrong type property for [%s] %s(%s)."):format(tostring(info.Owner), tostring(IF), name, tostring(prop.Type)), stack)
								end
								if iprop.Default == nil then iprop.Default = prop.Default end
							end
						end
					end
				end
			end
		end
	end

	function LoadInitTable(obj, initTable)
		for name, value in pairs(initTable) do obj[name] = value end
	end

	-- Init the object with class's constructor
	function Class1Obj(info, obj, ...)
		local count = select('#', ...)
		local initTable = select(1, ...)
		local ctor = info.Constructor or info.Ctor

		if not ( count == 1 and type(initTable) == "table" and getmetatable(initTable) == nil ) then initTable = nil end

		if ctor == nil then
			local sinfo = info

			while sinfo and not sinfo.Constructor do sinfo = _NSInfo[sinfo.SuperClass] end

			ctor = sinfo and sinfo.Constructor or false
			info.Ctor = ctor
		end

		if ctor then return ctor(obj, ...) end

		-- No constructor
		if initTable then
			local ok, msg = pcall(LoadInitTable, obj, initTable)
			if not ok then error(msg:match("%d+:%s*(.-)$") or msg, 4) end
		end
	end

	-- The cache for constructor parameters
	function Class2Obj(info, ...)
		if ValidateFlags(MD_ABSTRACT_CLASS, info.Modifier) then error("The class is abstract, can't be used to create objects.", 3) end

		-- Check if the class is unique and already created one object to be return
		if getmetatable(info.UniqueObject) then
			-- Init the obj with new arguments
			Class1Obj(info, info.UniqueObject, ...)

			InitObjectWithInterface(info, info.UniqueObject)

			return info.UniqueObject
		end

		-- Check if this class has __exist so no need to create again.
		if info.MetaTable.__exist then
			local ok, obj = pcall(info.MetaTable.__exist, ...)

			if ok and getmetatable(obj) == info.Owner then return obj end
		end

		-- Create new object
		local obj

		if select('#', ...) == 1 then
			-- Save memory cost for simple class
			local init = ...
			if type(init) == "table" and getmetatable(init) == nil then
				if info.IsSimpleClass then
					obj = setmetatable(init, info.MetaTable)
				elseif info.AsSimpleClass then
					local noConflict = true
					for name, set in pairs(info.Cache) do
						if type(set) == "table" then
							-- Property | Event
							if init[name] ~= nil then noConflict = false break end
						else
							-- Method
							if init[name] ~= nil and type(init[name]) ~= "function" then noConflict = false break end
						end
					end
					if noConflict then
						obj = setmetatable(init, info.MetaTable)

						Class1Obj(info, obj)
					end
				end
			end
		end
		if not obj then
			obj = setmetatable({}, info.MetaTable)

			Class1Obj(info, obj, ...)
		end

		InitObjectWithInterface(info, obj)

		if info.UniqueObject then info.UniqueObject = obj end

		return obj
	end

	------------------------------------
	--- Create class in currect environment's namespace or default namespace
	------------------------------------
	function class(...)
		local env, name, definition, stack = checkTypeParams(...)

		local fenv = env or getfenv(stack) or _G

		local ok, cls = pcall(GetDefineNS, fenv, name, TYPE_CLASS)
		if not ok then error(cls:match("%d+:%s*(.-)$") or cls, stack) end

		local info = _NSInfo[cls]

		if not info then
			error([[Usage: class "name"]], stack)
		elseif info.Type and info.Type ~= TYPE_CLASS then
			error(("%s is existed as %s, not class."):format(tostring(name), tostring(info.Type)), stack)
		end

		-- Check if the class is final
		if ValidateFlags(MD_SEALED_FEATURE, info.Modifier) then error("The class is sealed, can't be re-defined.", stack) end

		if not info.Type then
			info.Type = TYPE_CLASS
			info.Cache = {}
			info.MetaTable = GenerateMetaTable(info)
		end

		if ATTRIBUTE_INSTALLED then ConsumePreparedAttributes(info.Owner, AttributeTargets.Class) end

		if type(definition) == "table" then
			local ok, msg = pcall(ParseTableDefinition, info, definition)
			if not ok then error(msg:match("%d+:%s*(.-)$") or msg, stack) end

			RefreshCache(cls)
			if ATTRIBUTE_INSTALLED then ApplyRestAttribute(cls, AttributeTargets.Class) end
			ValidateClass(info, stack + 1)

			return cls
		else
			local classEnv = setmetatable({
				[OWNER_FIELD] = cls,
				[BASE_ENV_FIELD] = fenv,
			}, _MetaClsDefEnv)

			-- Set namespace
			SetNameSpace4Env(classEnv, cls)

			if definition then
				setfenv(definition, classEnv)
				definition(classEnv)

				_KeyWord4ClsEnv:ClearKeyword()
				pcall(setmetatable, classEnv, _MetaClsEnv)
				RefreshCache(cls)
				if ATTRIBUTE_INSTALLED then ApplyRestAttribute(cls, AttributeTargets.Class) end

				-- Validate the interface
				ValidateClass(info, stack + 1)

				return cls
			else
				-- save class to the environment
				if type(name) == "string" then rawset(fenv, name, cls) end

				setfenv(stack, classEnv)

				return classEnv
			end
		end
	end

	------------------------------------
	--- End the class's definition and restore the environment
	------------------------------------
	function endclass(env, name, stack)
		stack = stack or 2
		if ATTRIBUTE_INSTALLED then ClearPreparedAttributes() end

		local info = _NSInfo[env[OWNER_FIELD]]

		if info.Name == name or info.Owner == name then
			_KeyWord4ClsEnv:ClearKeyword()
			setmetatable(env, _MetaClsEnv)
			setfenv(stack, env[BASE_ENV_FIELD])
			RefreshCache(info.Owner)
			if ATTRIBUTE_INSTALLED then ApplyRestAttribute(info.Owner, AttributeTargets.Class) end
		else
			error(("%s is not closed."):format(info.Name), stack)
		end

		-- Validate the interface
		ValidateClass(info, stack + 1)

		return env[BASE_ENV_FIELD]
	end

	_KeyWord4ClsEnv.inherit = inherit_Def
	_KeyWord4ClsEnv.extend = extend_Cls
	_KeyWord4ClsEnv.import = import_Def
	_KeyWord4ClsEnv.event = event_Def
	_KeyWord4ClsEnv.property = property_Def
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
	function enum(...)
		local env, name, definition, stack = checkTypeParams(...)

		local fenv = env or getfenv(stack) or _G

		local ok, enm = pcall(GetDefineNS, fenv, name, TYPE_ENUM)
		if not ok then error(enm:match("%d+:%s*(.-)$") or enm, stack) end

		local info = _NSInfo[enm]

		if not info then
			error([[Usage: enum "name" {}]], stack)
		elseif info.Type and info.Type ~= TYPE_ENUM then
			error(("%s is existed as %s, not enum."):format(tostring(name), tostring(info.Type)), stack)
		end

		-- Check if the enum is final
		if ValidateFlags(MD_SEALED_FEATURE, info.Modifier) then error("The enum is sealed, can't be re-defined.", stack) end

		info.Type = TYPE_ENUM
		info.Enum = nil
		info.Cache = nil
		info.MaxValue = nil

		if type(definition) == "table" then
			BuildEnum(info, definition)

			return enm
		else
			-- save enum to the environment
			if type(name) == "string" then rawset(fenv, name, enm) end

			return function(set) return BuildEnum(info, set) end
		end
	end
end

------------------------------------------------------
-- Struct
------------------------------------------------------
do
	_KeyWord4StrtEnv = _KeywordAccessor()

	STRUCT_TYPE_MEMBER = "MEMBER"
	STRUCT_TYPE_ARRAY = "ARRAY"
	STRUCT_TYPE_CUSTOM = "CUSTOM"

	-- metatable for struct's env
	_MetaStrtEnv = { __metatable = true }
	_MetaStrtDefEnv = {}
	do
		local function __index(self, info, key)
			local value

			-- Check namespace
			if info.NameSpace then
				if key == _NSInfo[info.NameSpace].Name then
					return info.NameSpace
				else
					value = info.NameSpace[key]
					if value ~= nil then return value end
				end
			end

			-- Check imports
			if rawget(self, IMPORT_ENV_FIELD) then
				for _, ns in ipairs(self[IMPORT_ENV_FIELD]) do
					if key == _NSInfo[ns].Name then
						return ns
					else
						value = ns[key]
						if value ~= nil then return value end
					end
				end
			end

			-- Check base namespace
			value = GetNameSpace(PROTYPE_NAMESPACE, key)
			if value then return value end

			-- Check Method
			value = info.Method and info.Method[key]
			if value then return value end

			-- Check Base
			return self[BASE_ENV_FIELD][key]
		end

		_MetaStrtEnv.__index = function(self, key)
			local info = _NSInfo[self[OWNER_FIELD]]
			local value

			-- Check owner
			if key == info.Name then return info.Owner end

			-- Check keywords
			value = _KeyWord4StrtEnv:GetKeyword(self, key)
			if value then return value end

			value = __index(self, info, key)
			if value ~= nil then rawset(self, key, value) return value end
		end

		_MetaStrtDefEnv.__index = function(self, key)
			local info = _NSInfo[self[OWNER_FIELD]]
			local value

			-- Check owner
			if key == info.Name then return info.Owner end

			-- Check keywords
			value = _KeyWord4StrtEnv:GetKeyword(self, key)
			if value then return value end

			return __index(self, info, key)
		end

		_MetaStrtDefEnv.__newindex = function(self, key, value)
			local info = _NSInfo[self[OWNER_FIELD]]

			if _KeyWord4StrtEnv:GetKeyword(self, key) then return error(("'%s' is a keyword."):format(key)) end

			if key == info.Name or ((tonumber(key) or type(key) == "string") and type(value) == "function") then
				local ok, msg = pcall(SaveFeature, info, key, value)
				if not ok then error(msg:match("%d+:%s*(.-)$") or msg, 2) end
				return
			end

			if (type(key) == "string" or tonumber(key)) and IsNameSpace(value) and _NSInfo[value].Type then
				local ok, msg = pcall(SaveStructMember, info, key, value)
				if not ok then error(msg:match("%d+:%s*(.-)$") or msg, 2) end
				return
			end

			return rawset(self, key, value)
		end

		_MetaStrtDefEnv.__call = function(self, definition)
			ParseStructDefinition(self, definition)

			local owner = self[OWNER_FIELD]

			setfenv(2, self[BASE_ENV_FIELD])
			_KeyWord4StrtEnv:ClearKeyword()
			pcall(setmetatable, self, _MetaStrtEnv)
			RefreshStruct(owner)

			if ATTRIBUTE_INSTALLED then ApplyRestAttribute(owner, AttributeTargets.Struct) end

			return owner
		end
	end

	-- Some struct object may ref to each others, that would crash the validation
	_ValidatedCache = setmetatable({}, WEAK_ALL)

	function ValidateStruct(strt, value)
		local info = _NSInfo[strt]

		local sType = info.SubType

		if sType ~= STRUCT_TYPE_CUSTOM then
			if type(value) ~= "table" then wipe(_ValidatedCache) return error(("%s must be a table, got %s."):format("%s", type(value))) end

			if _ValidatedCache[value] then return value end

			if not _ValidatedCache[1] then _ValidatedCache[1] = value end
			_ValidatedCache[value] = true

			if sType == STRUCT_TYPE_MEMBER then
				if info.Members then
					for _, mem in ipairs(info.Members) do
						local name = mem.Name
						local default = mem.Default
						local val = value[name]

						if val == nil then
							if default ~= nil then
								-- Deep clone to make sure no change on default value
								value[name] = CloneObj(default, true)
							elseif mem.Require then
								return error(("%s.%s can't be nil."):format("%s", name))
							end
						else
							value[name] = Validate4Type(mem.Type, val, name)
						end
					end
				end
			elseif sType == STRUCT_TYPE_ARRAY and info.ArrayElement then
				local flag, ret
				local ele = info.ArrayElement.Type

				if ele then
					for i, v in ipairs(value) do
						flag, ret = pcall(Validate4Type, ele, v, "Element")

						if flag then
							value[i] = ret
						else
							wipe(_ValidatedCache)
							return error(strtrim(ret:match(":%d+:%s*(.-)$") or ret):gsub("%%s[_%w]+", "%%s["..i.."]"))
						end
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

			if sType == STRUCT_TYPE_CUSTOM and ret ~= nil then value = ret end
		end

		if sType ~= STRUCT_TYPE_CUSTOM and _ValidatedCache[1] == value then wipe(_ValidatedCache) end

		return value
	end

	function CopyStructMethods(info, obj)
		if info.Method and type(obj) == "table" then
			for k, v in pairs(info.Method) do
				if obj[k] == nil and not(info.FeatureModifier and ValidateFlags(MD_STATIC_FEATURE, info.FeatureModifier[k])) then
					obj[k] = v
				end
			end
		end

		return obj
	end

	function Struct2Obj(info, ...)
		local strt = info.Owner

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
		if info.SubType == STRUCT_TYPE_MEMBER then
			local ret = {}

			if info.Members then for i, n in ipairs(info.Members) do ret[n.Name] = select(i, ...) end end

			local ok, value = pcall(ValidateStruct, strt, ret)

			if ok then
				return CopyStructMethods(info, value)
			else
				value = initErrMsg or value
				value = strtrim(value:match(":%d+:%s*(.-)$") or value)
				value = value:gsub("%%s%.", ""):gsub("%%s", "")

				local args = ""
				for i, n in ipairs(info.Members) do
					if i == 1 then args = n.Name else args = args..", "..n.Name end
				end
				--if args:find("%[") then args = args.."]" end
				error(("Usage : %s(%s) - %s"):format(tostring(strt), args, value), 3)
			end
		elseif info.SubType == STRUCT_TYPE_ARRAY then
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
	function struct(...)
		local env, name, definition, stack = checkTypeParams(...)

		local fenv = env or getfenv(stack) or _G

		local ok, strt = pcall(GetDefineNS, fenv, name, TYPE_STRUCT)
		if not ok then error(strt:match("%d+:%s*(.-)$") or strt, stack) end

		local info = _NSInfo[strt]

		if not info then
			error([[Usage: struct "name"]], stack)
		elseif info.Type and info.Type ~= TYPE_STRUCT then
			error(("%s is existed as %s, not struct."):format(tostring(name), tostring(info.Type)), stack)
		end

		-- Check if the struct is final
		if ValidateFlags(MD_SEALED_FEATURE, info.Modifier) then error("The struct is sealed, can't be re-defined.", stack) end

		info.Type = TYPE_STRUCT
		info.SubType = STRUCT_TYPE_MEMBER
		info.Members = nil
		info.Default = nil
		info.ArrayElement = nil
		info.Validator = nil
		info.Method = nil
		info.FeatureModifier = nil
		info.Modifier = nil

		-- Clear Attribute
		if ATTRIBUTE_INSTALLED then ConsumePreparedAttributes(info.Owner, AttributeTargets.Struct) end

		if type(definition) == "table" then
			local ok, msg = pcall(ParseTableDefinition, info, definition)
			if not ok then error(msg:match("%d+:%s*(.-)$") or msg, stack) end

			RefreshStruct(strt)
			if ATTRIBUTE_INSTALLED then ApplyRestAttribute(strt, AttributeTargets.Struct) end

			return strt
		else
			local strtEnv = setmetatable({
				[OWNER_FIELD] = strt,
				[BASE_ENV_FIELD] = fenv,
			}, _MetaStrtDefEnv)

			-- Set namespace
			SetNameSpace4Env(strtEnv, strt)

			if definition then
				setfenv(definition, strtEnv)
				definition(strtEnv)

				_KeyWord4StrtEnv:ClearKeyword()
				pcall(setmetatable, strtEnv, _MetaStrtEnv)
				RefreshStruct(strt)
				if ATTRIBUTE_INSTALLED then ApplyRestAttribute(strt, AttributeTargets.Struct) end

				return strt
			else
				-- save struct to the environment
				if type(name) == "string" then rawset(fenv, name, strt) end

				setfenv(stack, strtEnv)

				return strtEnv
			end
		end
	end

	------------------------------------
	--- End the class's definition and restore the environment
	------------------------------------
	function endstruct(env, name, stack)
		stack = stack or 2
		if ATTRIBUTE_INSTALLED then ClearPreparedAttributes() end

		local info = _NSInfo[env[OWNER_FIELD]]

		if info.Name == name or info.Owner == name then
			_KeyWord4StrtEnv:ClearKeyword()
			setmetatable(env, _MetaStrtEnv)
			setfenv(stack, env[BASE_ENV_FIELD])
			RefreshStruct(info.Owner)
			if ATTRIBUTE_INSTALLED then ApplyRestAttribute(info.Owner, AttributeTargets.Struct) end
			return env[BASE_ENV_FIELD]
		else
			error(("%s is not closed."):format(info.Name), stack)
		end
	end

	function ParseStructDefinition(self, definition)
		local info = _NSInfo[self[OWNER_FIELD]]

		if type(definition) == "table" then
			local ok, msg = pcall(ParseTableDefinition, info, definition)
			if not ok then error(msg:match("%d+:%s*(.-)$") or msg, 3) end
		else
			if type(definition) == "string" then
				local errorMsg
				definition, errorMsg = loadstring("return function(_ENV) " .. definition .. " end")
				if definition then
					definition = definition()
				else
					error(errorMsg, 3)
				end
			end

			if type(definition) == "function" then
				setfenv(definition, self)
				return definition(self)
			end
		end
	end

	_KeyWord4StrtEnv.struct = struct
	_KeyWord4StrtEnv.import = import_Def
	_KeyWord4StrtEnv.endstruct = endstruct
	_KeyWord4StrtEnv.member = member_Def
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

	struct "Boolean"	{ false, function (value) return value and true or false end }
	struct "BooleanNil"	{ function (value) return value and true or false end }
	struct "String"		{ function (value) if type(value) ~= "string" then error(("%s must be a string, got %s."):format("%s", type(value))) end end }
	struct "Number"		{ 0, function (value) if type(value) ~= "number" then error(("%s must be a number, got %s."):format("%s", type(value))) end end }
	struct "NumberNil"	{ function (value) if type(value) ~= "number" then error(("%s must be a number, got %s."):format("%s", type(value))) end end }
	struct "Function"	{ function (value) if type(value) ~= "function" then error(("%s must be a function, got %s."):format("%s", type(value))) end end }
	struct "Table"		{ function (value) if type(value) ~= "table" then error(("%s must be a table, got %s."):format("%s", type(value))) end end }
	struct "RawTable"	{ function (value) assert(type(value) == "table" and getmetatable(value) == nil, "%s must be a table without metatable.") end }
	struct "Userdata"	{ function (value) if type(value) ~= "userdata" then error(("%s must be a userdata, got %s."):format("%s", type(value))) end end }
	struct "Thread"		{ function (value) if type(value) ~= "thread" then error(("%s must be a thread, got %s."):format("%s", type(value))) end end }
	struct "Any"		{ }

	struct "Lambda" (function (_ENV)
		_LambdaCache = setmetatable({}, WEAK_VALUE)

		function Lambda(value)
			assert(type(value) == "string" and value:find("=>"), "%s must be a string like 'x,y=>x+y'")
			local func = _LambdaCache[value]
			if not func then
				local param, body = value:match("^(.-)=>(.+)$")
				local args
				if param then for arg in param:gmatch("[_%w]+") do args = (args and args .. "," or "") .. arg end end
				if args then
					func = loadstring(("local %s = ... return %s"):format(args, body or ""))
					if not func then
						func = loadstring(("local %s = ... %s"):format(args, body or ""))
					end
				else
					func = loadstring("return " .. (body or ""))
					if not func then
						func = loadstring(body or "")
					end
				end
				assert(func, "%s must be a string like 'x,y=>x+y'")
				_LambdaCache[value] = func
			end
			return func
		end
	end)

	struct "Callable"	{
		function (value)
			if type(value) == "string" then return Lambda(value) end
			assert(Reflector.IsCallable(value), "%s isn't callable.")
		end
	}

	struct "Guid" (function (_ENV)
		if math.randomseed and os.time then math.randomseed(os.time()) end

		local GUID_TEMPLTE = [[xx-x-x-x-xxx]]
		local GUID_FORMAT = "^" .. GUID_TEMPLTE:gsub("x", "%%x%%x%%x%%x"):gsub("%-", "%%-") .. "$"
		local function GenerateGUIDPart(v) return ("%04X"):format(math.random(0xffff)) end

		function Guid(value)
			if value == nil then
				return (GUID_TEMPLTE:gsub("x", GenerateGUIDPart))
			elseif type(value) ~= "string" or #value ~= 36 or not value:match(GUID_FORMAT) then
				error("%s require data with format like '" .. GUID_TEMPLTE:gsub("x", GenerateGUIDPart) .."'.")
			end
		end
	end)

	struct "Class"		{ function (value) assert(Reflector.IsClass(value), "%s must be a class.") end }
	struct "Interface"	{ function (value) assert(Reflector.IsInterface(value), "%s must be an interface.") end }
	struct "Struct"		{ function (value) assert(Reflector.IsStruct(value), "%s must be a struct.") end }
	struct "Enum"		{ function (value) assert(Reflector.IsEnum(value), "%s must be an enum.") end }
	struct "AnyType"	{ function (value) local info = _NSInfo[value] assert(info and info.Type, "%s must be a type, such as enum, struct, class or interface.") end }
	struct "NameSpace"	{ function (value) value = _NSInfo[value] assert(value, "%s must be a namespace") return value.Owner end}

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
			return GetNameSpace(PROTYPE_NAMESPACE, name)
		end

		doc "GetUpperNameSpace" [[
			<desc>Get the upper namespace of the target</desc>
			<param name="name" type="namespace|string">the target namespace</param>
			<return>The target's namesapce</return>
			<usage>ns = System.Reflector.GetUpperNameSpace("System.Object")</usage>
		]]
		function GetUpperNameSpace(ns)
			local info = _NSInfo[ns]
			return info and info.NameSpace
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
			assert(info and (info.Type == TYPE_CLASS or info.Type == TYPE_INTERFACE or info.Type == TYPE_STRUCT), "System.Reflector.BeginDefinition(ns) - ns must be a class, interface or struct.")
			info.BeginDefinition = true
		end

		doc "EndDefinition" [[
			<desc>End the definition of target namespace, refresh the cache</desc>
			<param name="namespace|string">the namespace</param>
		]]
		function EndDefinition(ns)
			local info = _NSInfo[ns]
			assert(info and (info.Type == TYPE_CLASS or info.Type == TYPE_INTERFACE or info.Type == TYPE_STRUCT), "System.Reflector.EndDefinition(ns) - ns must be a class, interface or struct.")
			info.BeginDefinition = nil
			if info.Type == TYPE_STRUCT then
				return RefreshStruct(info.Owner)
			else
				return RefreshCache(info.Owner)
			end
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
		IsNameSpace = IsNameSpace

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
			return info and ValidateFlags(MD_SEALED_FEATURE, info.Modifier) or false
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
			<desc>Whether the class is auto-cached</desc>
			<param name="object">the object to query</param>
			<return type="boolean">true if auto-cached</return>
			<usage>System.Reflector.IsAutoCache(System.Object)</usage>
		]]
		function IsAutoCache(ns, name)
			local info = _NSInfo[ns]
			return info and info.AutoCache or false
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
			_GetEventsIter = function (ns, key)
				local evt = _NSInfo[ns].Event
				return evt and next(evt, key)
			end
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

			if info and info.Cache then
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
			_GetPropertiesIter = function (ns, key)
				local prop = _NSInfo[ns].Property
				return prop and next(prop, key)
			end
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
				for k, v in next, _NSInfo[ns].Cache, key do if type(v) == "table" and not getmetatable(v) then return k end end
			end
		end
		function GetAllProperties(ns, result)
			local info = _NSInfo[ns]

			if info and info.Cache then
				if type(result) == "table" then
					for k, v in pairs(info.Cache) do if type(v) == "table" and not getmetatable(v) then tinsert(result, k) end end
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
							iter = function (ns, key)
								for k, v in next, cache, key do if type(v) == "table" and not getmetatable(v) then return k end end
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
			_GetMethodsIter = function (ns, key)
				local method = _NSInfo[ns].Method
				return method and next(method, key)
			end
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

				if methods then
					for k, v in next, methods, key do if type(v) == "function" then return k end end
				end
			end
		end
		function GetAllMethods(ns, result)
			local info = _NSInfo[ns]

			if info and (info.Cache or info.Method) then
				if type(result) == "table" then
					for k, v in pairs(info.Cache or info.Method) do if type(v) == "function" then tinsert(result, k) end end
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
							iter = function (ns, key)
								for k, v in next, cache, key do if type(v) == "function" then return k end end
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

		doc "HasMetaMethod" [[
			<desc>Whether the class has the meta-method</desc>
			<param name="class">the query class</param>
			<param name="meta-method">the result table</param>
			<return type="boolean">true if the class has the meta-method</return>
			<usage>print(System.Reflector.HasMetaMethod(System.Object, "__call")</usage>
		]]
		function HasMetaMethod(ns, name)
			local info = _NSInfo[ns]
			return info and info.MetaTable and info.MetaTable[_KeyMeta[name]] and true or false
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

			if info and (info.Type == TYPE_INTERFACE or info.Type == TYPE_CLASS) then
				local prop = info.Cache[name] or info.Property and info.Property[name]
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

			if info and (info.Type == TYPE_INTERFACE or info.Type == TYPE_CLASS) then
				local prop = info.Cache[name] or info.Property and info.Property[name]
				if type(prop) == "table" and getmetatable(prop) == nil then return true end
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
		IsPropertyReadable = IsPropertyReadable

		doc "IsPropertyWritable" [[
			<desc>whether the property is writable</desc>
			<param name="owner" type="class|interface">the property's owner</param>
			<param name="name" type="string">the property's name</param>
			<return type="boolean">true if the property is writable</return>
			<usage>System.Reflector.IsPropertyWritable(System.Object, "Name")</usage>
		]]
		IsPropertyWritable = IsPropertyWritable

		doc "IsRequiredMethod" [[
			<desc>Whether the method is required to be overwrited</desc>
			<param name="owner" type="interface">the method's owner</param>
			<param name="name" type="string">the method's name</param>
			<return type="boolean">true if the method must be overwrited</return>
		]]
		function IsRequiredMethod(ns, name)
			local info = _NSInfo[ns]
			return info and info.Method and info.Method[name] and info.FeatureModifier and ValidateFlags(MD_REQUIRE_FEATURE, info.FeatureModifier[name]) or false
		end

		doc "IsRequiredProperty" [[
			<desc>Whether the property is required to be overwrited</desc>
			<param name="owner" type="interface">the property's owner</param>
			<param name="name" type="string">the property's name</param>
			<return type="boolean">true if the property must be overwrited</return>
		]]
		function IsRequiredProperty(ns, name)
			local info = _NSInfo[ns]
			return info and info.Property and info.Property[name] and info.FeatureModifier and ValidateFlags(MD_REQUIRE_FEATURE, info.FeatureModifier[name]) or false
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
			return info and info.Method and info.Method[name] and info.FeatureModifier and ValidateFlags(MD_STATIC_FEATURE, info.FeatureModifier[name]) or false
		end

		doc "IsFlagsEnum" [[
			<desc>Whether the enum is flags or not</desc>
			<param name="object" type="enum">The enum type</param>
			<return name="boolean">true if the enum is a flag enumeration</return>
			<usage>System.Reflector.IsFlagsEnum(System.AttributeTargets)</usage>
		]]
		function IsFlagsEnum(ns)
			local info = _NSInfo[ns]
			return info and ValidateFlags(MD_FLAGS_ENUM, info.Modifier) or false
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
		ValidateFlags = ValidateFlags

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
			return info and info.Type == TYPE_STRUCT and info.SubType == STRUCT_TYPE_ARRAY and info.ArrayElement and info.ArrayElement.Type or nil
		end

		doc "HasStructMember" [[
			<desc>Whether the struct has the query member</desc>
			<param name="struct" type="struct">the struct type</param>
			<param name="member" type="string">the query member</param>
			<return type="boolean">true if the struct has the member</return>
		]]
		function HasStructMember(ns, member)
			local info = _NSInfo[ns]

			return info and info.Type == TYPE_STRUCT and info.SubType == STRUCT_TYPE_MEMBER
				and info.Members and info.Members[member] and true or false
		end

		doc "IsRequiredMember" [[
			<desc>Whether the member of the struct is required.</desc>
			<param name="struct" type="struct">the struct type</param>
			<param name="member" type="string">the query member</param>
			<return type="boolean">true if the struct has the member</return>
		]]
		function IsRequiredMember(ns, member)
			local info = _NSInfo[ns]

			if info and info.Type == TYPE_STRUCT and info.SubType == STRUCT_TYPE_MEMBER then
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
			_GetStructMembersIter = function (ns, key)
				local mem = _NSInfo[ns].Members[key]
				if mem then return key + 1, mem.Name end
			end
		end
		function GetStructMembers(ns, result)
			local info = _NSInfo[ns]

			if info and info.Members then
				if type(result) == "table" then
					for _, member in ipairs(info.Members) do tinsert(result, member.Name) end
					return result
				else
					if SAVE_MEMORY then
						return _GetStructMembersIter, info.Owner, 1
					else
						local members = info.Members
						local iter = _GetStructMembersCache[members]
						if not iter then
							iter = function (ns, key)
								local mem = members[key]
								if mem then return key + 1, mem.Name end
							end
							_GetStructMembersCache[members] = iter
						end
						return iter, ns, 1
					end
				end
			else
				return type(result) == "table" and result or iterForEmpty, info.Owner
			end
		end

		doc "GetStructMember" [[
			<desc>Get the member's type of the struct</desc>
			<param name="struct" type="struct">the struct type</param>
			<param name="member" type="string">the member's name</param>
			<return type="System.Type">the member's type</return>
			<return type="System.Any">the member's default value</return>
			<return type="System.Boolean">whether the member is required</return>
			<usage>System.Reflector.GetStructMember(Position, "x")</usage>
		]]
		function GetStructMember(ns, part)
			local info = _NSInfo[ns]

			if info and info.Type == TYPE_STRUCT then
				if info.SubType == STRUCT_TYPE_MEMBER and info.Members then
					local mem = info.Members[part]
					if mem then return mem.Type, mem.Default, mem.Require end
				elseif info.SubType == STRUCT_TYPE_ARRAY and info.ArrayElement then
					return info.ArrayElement.Type
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
			return info and ValidateFlags(MD_ABSTRACT_CLASS, info.Modifier)
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
			stacklevel = floor(type(stacklevel) == "number" and stacklevel > 1 and stacklevel or 1)

			if type(name) ~= "string" then name = "value" end
			if oType == nil then return value end

			assert(_NSInfo[oType] and _NSInfo[oType].Type, "Usage : System.Reflector.Validate(oType, value[, name[, prefix]]) : oType - must be enum, struct, class or interface.")

			local ok

			ok, value = pcall(Validate4Type, oType, value)

			if not ok then
				value = strtrim(value:match(":%d+:%s*(.-)$") or value):gsub("%%s[_%w]*", name)

				if type(prefix) == "string" then
					return error(prefix .. value, 1 + stacklevel)
				else
					return error(value)
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
					if info.SubType == STRUCT_TYPE_CUSTOM and not part then
						return info.Default
					elseif info.SubType == STRUCT_TYPE_MEMBER and part then
						local mem = info.Members and info.Members[part]
						if mem then return mem.Default end
					end
				end
			end
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

		doc "LoadLuaFile" [[
			<desc>Load the lua file and return any features that may be created by the file</desc>
			<param name="path">the file's path</param>
			<return type="table">the hash table use feature types as key</return>
		]]
		function LoadLuaFile(path)
			local f = assert(loadfile(path))

			if f then
				RecordNSFeatures()

				local ok, msg = pcall(f)

				local ret = GetNsFeatures()

				assert(ok, msg)

				return ret
			end
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

		_AttributeMap = setmetatable({}, WEAK_KEY)

		_ApplyRestAttribute = setmetatable({}, WEAK_KEY)

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

		function GetSuperAttributes(target, targetType, owner, name)
			local info = _NSInfo[owner or target]

			if targetType == AttributeTargets.Class then
				return info.SuperClass and _AttributeMap[info.SuperClass]
			end

			if targetType == AttributeTargets.Event or
				targetType == AttributeTargets.Method or
				targetType == AttributeTargets.Property then

				local star = info.SuperClass and _NSInfo[info.SuperClass].Cache[name]

				if not star and info.ExtendInterface then
					for _, IF in ipairs(info.ExtendInterface) do
						star = _NSInfo[IF].Cache[name]
						if star then break end
					end
				end

				if star then
					if targetType == AttributeTargets.Event and getmetatable(star) then return _AttributeMap[star] end
					if targetType == AttributeTargets.Method and type(star) == "function" then return _AttributeMap[star] end
					if targetType == AttributeTargets.Property and type(star) == "table" and not getmetatable(star) then return _AttributeMap[star] end
				end
			end
		end

		function SaveTargetAttributes(target, targetType, config)
			if targetType == AttributeTargets.Constructor then
				DisposeAttributes(config)
			else
				_AttributeMap[target] = config
			end
		end

		function GetAttributeUsage(target)
			local config = _AttributeMap[target]

			if not config then
				return
			elseif getmetatable(config) then
				return getmetatable(config) == __AttributeUsage__ and config or nil
			else
				for _, attr in ipairs(config) do if getmetatable(attr) == __AttributeUsage__ then return attr end end
			end
		end

		function ParseAttributeTarget(target, targetType, owner, name)
			if not owner or owner == target then
				return ("[%s]%s"):fromat(_NSInfo[owner].Type, tostring(owner))
			else
				return ("[%s]%s [%s]%s"):fromat(_NSInfo[owner].Type, tostring(owner), AttributeTargets(targetType), name or "anonymous")
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

		function ApplyRestAttribute(target, targetType)
			local args = _ApplyRestAttribute[target]
			if args then
				_ApplyRestAttribute[target] = nil
				local start, config = args[1], args[2]
				CACHE_TABLE(args)
				return ApplyAttributes(target, targetType, nil, nil, start, config, true, true)
			end
		end

		function ApplyAttributes(target, targetType, owner, name, start, config, halt, atLast)
			-- Check config
			config = config or _AttributeMap[target]

			-- Clear
			SaveTargetAttributes(target, targetType, nil)

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
				elseif targetType == AttributeTargets.Method or targetType == AttributeTargets.Constructor then
					arg1 = target
					arg2 = targetType
					arg3 = owner
					arg4 = name
				elseif targetType == AttributeTargets.Property or targetType == AttributeTargets.Member then
					arg1 = target.Predefined
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
							print(ret)

							config:Dispose()
							config = nil
						else
							if usage and not usage.Inherited and usage.RunOnce then
								config:Dispose()
								config = nil
							end

							if targetType == AttributeTargets.Method or targetType == AttributeTargets.Constructor then
								-- The method may be wrapped in the apply operation
								if ret and ret ~= target and type(ret) == "function" then
									target = ret
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
								print(ret)
							else
								if usage and not usage.Inherited and usage.RunOnce then
									tremove(config, i):Dispose()
								end

								if targetType == AttributeTargets.Method or targetType == AttributeTargets.Constructor then
									-- The method may be wrapped in the apply operation
									if ret and ret ~= target and type(ret) == "function" then
										target = ret
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
					local args = CACHE_TABLE()
					args[1] = start
					args[2] = config

					_ApplyRestAttribute[target] = args
				end
			end

			SaveTargetAttributes(target, targetType, config)

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
			if not noDispose then for _, attr in ipairs(prepared) do attr:Dispose() end end
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

					if usage and usage.AttributeTarget > 0 and not ValidateFlags(targetType, usage.AttributeTarget) then
						print("Can't apply the " .. tostring(cls) .. " attribute to the " .. ParseAttributeTarget(target, targetType, owner, name))
					elseif ValidateAttributeUsable(usableAttr, attr) then
						usableAttr[attr] = true
						tinsert(usableAttr, attr)
					else
						print("Can't apply the " .. tostring(cls) .. " attribute for multi-times.")
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
			local pconfig = _AttributeMap[target]

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
								SaveTargetAttributes(target, targetType, nil)
								pconfig:Dispose()
							end
						else
							for i = #pconfig, 1, -1 do
								if not ValidateAttributeUsable(prepared, pconfig[i]) then
									tremove(pconfig, i):Dispose()
								end
							end

							if #pconfig == 0 then SaveTargetAttributes(target, targetType, nil) end
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

			local sconfig = _AttributeMap[source]

			-- Save & apply the attributes for target
			if sconfig then
				local config = _AttributeMap[target]
				local hasAttr = false

				-- Check existed attributes
				if getmetatable(sconfig) then
					local usage = GetAttributeUsage(getmetatable(sconfig))
					if (not usage or usage.Inherited) and (not config or ValidateAttributeUsable(config, sconfig)) then
						sconfig:Clone()
						hasAttr = true
					end
				else
					for i = 1, #sconfig do
						local usage = GetAttributeUsage(getmetatable(sconfig[i]))
						if (not usage or usage.Inherited) and (not config or ValidateAttributeUsable(config, sconfig[i])) then
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
	-- System.IAttribute
	------------------------------------------------------
	interface "IAttribute" (function (_ENV)
		doc "IAttribute" [[The IAttribute associates predefined system information or user-defined custom information with a target element.]]

		-- Class Method
		local function IsDefined(target, type)
			local config = _AttributeMap[target]

			if not config then
				return false
			elseif type == IAttribute then
				return true
			elseif getmetatable(config) then
				return getmetatable(config) == type
			else
				for _, attr in ipairs(config) do if getmetatable(attr) == type then return true end end
			end
			return false
		end

		doc "IsNameSpaceAttributeDefined" [[
			<desc>Check whether the target contains such type attribute</desc>
			<param name="class">the attribute class type</param>
			<param name="target">the name space</param>
			<return type="boolean">true if the target contains attribute with the type</return>
		]]
		function IsNameSpaceAttributeDefined(cls, target)
			if type(target) == "string" then target = GetNameSpace(PROTYPE_NAMESPACE, target) end
			return target and IsDefined(target, cls) or false
		end

		doc "IsClassAttributeDefined" [[
			<desc>Check whether the target contains such type attribute</desc>
			<param name="class">the attribute class type</param>
			<param name="target">class</param>
			<return type="boolean">true if the target contains attribute with the type</return>
		]]
		function IsClassAttributeDefined(cls, target)
			if type(target) == "string" then target = GetNameSpace(PROTYPE_NAMESPACE, target) end
			return Reflector.IsClass(target) and IsDefined(target, cls)
		end

		doc "IsEnumAttributeDefined" [[
			<desc>Check whether the target contains such type attribute</desc>
			<param name="class">the attribute class type</param>
			<param name="target">enum</param>
			<return type="boolean">true if the target contains attribute with the type</return>
		]]
		function IsEnumAttributeDefined(cls, target)
			if type(target) == "string" then target = GetNameSpace(PROTYPE_NAMESPACE, target) end
			return Reflector.IsEnum(target) and IsDefined(target, cls)
		end

		doc "IsInterfaceAttributeDefined" [[
			<desc>Check whether the target contains such type attribute</desc>
			<param name="class">the attribute class type</param>
			<param name="target">interface</param>
			<return type="boolean">true if the target contains attribute with the type</return>
		]]
		function IsInterfaceAttributeDefined(cls, target)
			if type(target) == "string" then target = GetNameSpace(PROTYPE_NAMESPACE, target) end
			return Reflector.IsInterface(target) and IsDefined(target, cls)
		end

		doc "IsStructAttributeDefined" [[
			<desc>Check whether the target contains such type attribute</desc>
			<param name="class">the attribute class type</param>
			<param name="target">struct</param>
			<return type="boolean">true if the target contains attribute with the type</return>
		]]
		function IsStructAttributeDefined(cls, target)
			if type(target) == "string" then target = GetNameSpace(PROTYPE_NAMESPACE, target) end
			return Reflector.IsStruct(target) and IsDefined(target, cls)
		end

		doc "IsEventAttributeDefined" [[
			<desc>Check whether the target contains such type attribute</desc>
			<param name="class">the attribute class type</param>
			<param name="target">class | interface</param>
			<param name="event">the event's name</param>
			<return type="boolean">true if the target contains attribute with the type</return>
		]]
		function IsEventAttributeDefined(cls, target, evt)
			local info = _NSInfo[target]
			evt = info and info.Cache and info.Cache[evt]
			return getmetatable(evt) and IsDefined(evt, cls) or false
		end

		doc "IsMethodAttributeDefined" [[
			<desc>Check whether the target contains such type attribute</desc>
			<param name="class">the attribute class type</param>
			<param name="target">class | interface | struct</param>
			<param name="method">the method's name</param>
			<return type="boolean">true if the target contains attribute with the type</return>
		]]
		function IsMethodAttributeDefined(cls, target, method)
			local info = _NSInfo[target]
			method = info and (info.Cache and info.Cache[method] or info.Method and info.Method[method])
			return type(method) == "function" and IsDefined(method, cls) or false
		end

		doc "IsPropertyAttributeDefined" [[
			<desc>Check whether the target contains such type attribute</desc>
			<param name="class">the attribute class type</param>
			<param name="target">class | interface</param>
			<param name="property">the property's name</param>
			<return type="boolean">true if the target contains attribute with the type</return>
		]]
		function IsPropertyAttributeDefined(cls, target, prop)
			local info = _NSInfo[target]
			prop = info and (info.Cache and info.Cache[prop] or info.Property and info.Property[prop])
			return type(prop) == "table" and getmetatable(prop) == nil and IsDefined(prop, cls) or false
		end

		doc "IsMemberAttributeDefined" [[
			<desc>Check whether the target contains such type attribute</desc>
			<param name="class">the attribute class type</param>
			<param name="target">struct</param>
			<param name="member">the member's name</param>
			<return type="boolean">true if the target contains attribute with the type</return>
		]]
		function IsMemberAttributeDefined(cls, target, member)
			local info = _NSInfo[target]
			member = info and info.Members and info.Members[member]
			return member and IsDefined(member, cls) or false
		end

		local function GetCustomAttribute(target, type)
			local config = _AttributeMap[target]

			if not config then
				return
			elseif getmetatable(config) then
				return (type == IAttribute or getmetatable(config) == type) and config or nil
			elseif type == IAttribute then
				return unpack(config)
			else
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
			end
		end

		doc "GetNameSpaceAttribute" [[
			<desc>Return the attributes of the given type for the NameSpace</desc>
			<param name="class">the attribute class type</param>
			<param name="target">NameSpace</param>
			<return>the attribute objects</return>
		]]
		function GetNameSpaceAttribute(cls, target)
			if type(target) == "string" then target = GetNameSpace(PROTYPE_NAMESPACE, target) end
			if target then return GetCustomAttribute(target, cls) end
		end

		doc "GetClassAttribute" [[
			<desc>Return the attributes of the given type for the class</desc>
			<param name="class">the attribute class type</param>
			<param name="target">class</param>
			<return>the attribute objects</return>
		]]
		function GetClassAttribute(cls, target)
			if type(target) == "string" then target = GetNameSpace(PROTYPE_NAMESPACE, target) end
			if target and Reflector.IsClass(target) then return GetCustomAttribute(target, cls) end
		end

		doc "GetEnumAttribute" [[
			<desc>Return the attributes of the given type for the enum</desc>
			<param name="class">the attribute class type</param>
			<param name="target">enum</param>
			<return>the attribute objects</return>
		]]
		function GetEnumAttribute(cls, target)
			if type(target) == "string" then target = GetNameSpace(PROTYPE_NAMESPACE, target) end
			if target and Reflector.IsEnum(target) then return GetCustomAttribute(target, cls) end
		end

		doc "GetInterfaceAttribute" [[
			<desc>Return the attributes of the given type for the interface</desc>
			<param name="class">the attribute class type</param>
			<param name="target">interface</param>
			<return>the attribute objects</return>
		]]
		function GetInterfaceAttribute(cls, target)
			if type(target) == "string" then target = GetNameSpace(PROTYPE_NAMESPACE, target) end
			if target and Reflector.IsInterface(target) then return GetCustomAttribute(target, cls) end
		end

		doc "GetStructAttribute" [[
			<desc>Return the attributes of the given type for the struct</desc>
			<param name="class">the attribute class type</param>
			<param name="target">struct</param>
			<return>the attribute objects</return>
		]]
		function GetStructAttribute(cls, target)
			if type(target) == "string" then target = GetNameSpace(PROTYPE_NAMESPACE, target) end
			if target and Reflector.IsStruct(target) then return GetCustomAttribute(target, cls) end
		end

		doc "GetEventAttribute" [[
			<desc>Return the attributes of the given type for the class|interface's event</desc>
			<param name="class">the attribute class type</param>
			<param name="target">class|interface</param>
			<param name="event">the event's name</param>
			<return>the attribute objects</return>
		]]
		function GetEventAttribute(cls, target, evt)
			local info = _NSInfo[target]
			evt = info and info.Cache and info.Cache[evt]
			if getmetatable(evt) then return GetCustomAttribute(evt, cls) end
		end

		doc "GetMethodAttribute" [[
			<desc>Return the attributes of the given type for the class|interface's method</desc>
			<format>class, target, method</format>
			<format>class, method</format>
			<param name="class">the attribute class type</param>
			<param name="target">class|interface</param>
			<param name="method">the method's name(with target) or the method itself(without target)</param>
			<return>the attribute objects</return>
		]]
		function GetMethodAttribute(cls, target, method)
			local info = _NSInfo[target]
			method = info and (info.Cache and info.Cache[method] or info.Method and info.Method[method])
			if type(method) == "function" then return GetCustomAttribute(method, cls) end
		end

		doc "GetPropertyAttribute" [[
			<desc>Return the attributes of the given type for the class|interface's property</desc>
			<param name="class">the attribute class type</param>
			<param name="target">class|interface</param>
			<param name="prop">the property's name</param>
			<return>the attribute objects</return>
		]]
		function GetPropertyAttribute(cls, target, prop)
			local info = _NSInfo[target]
			prop = info and (info.Cache and info.Cache[prop] or info.Property and info.Property[prop])
			if type(prop) == "table" and getmetatable(prop) == nil then return GetCustomAttribute(prop, cls) end
		end

		doc "GetMemberAttribute" [[
			<desc>Return the attributes of the given type for the struct's field</desc>
			<param name="class">the attribute class type</param>
			<param name="target">struct</param>
			<param name="member">the member's name</param>
			<return>the attribute objects</return>
		]]
		function GetMemberAttribute(cls, target, member)
			local info = _NSInfo[target]
			member = info and info.Members and info.Members[member]
			if member then return GetCustomAttribute(member, cls) end
		end

		-- Object Method
		doc "ApplyAttribute" [[
			<desc>Apply the attribute to the target, overridable</desc>
			<param name="target">the attribute's target</param>
			<param name="targetType" type="System.AttributeTargets">the target's type</param>
			<param name="owner">the target's owner</param>
			<param name="name">the target's name</param>
			<return>the target, also can be modified</return>
		]]
		function ApplyAttribute(self, target, targetType, owner, name) end

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

		-- Initializer
		IAttribute = SendAttributeToPrepared
	end)

	-- Attribute system OnLine
	ATTRIBUTE_INSTALLED = true

	class "__Unique__" (function(_ENV)
		extend "IAttribute"

		doc "__Unique__" [[Mark the class will only create one unique object, and can't be disposed, also the class can't be inherited]]

		function ApplyAttribute(self, target, targetType)
			local info = _NSInfo[target]
			if info and info.Type == TYPE_CLASS then
				info.Modifier = TurnOnFlags(MD_FINAL_FEATURE, info.Modifier)
				info.UniqueObject = true
			end
		end
	end)

	class "__Flags__" (function(_ENV)
		extend "IAttribute"

		doc "__Flags__" [[Indicates that an enumeration can be treated as a bit field; that is, a set of flags.]]

		function ApplyAttribute(self, target, targetType)
			local info = _NSInfo[target]
			if info and info.Type == TYPE_ENUM then
				info.Modifier = TurnOnFlags(MD_FLAGS_ENUM, info.Modifier)

				local enums = info.Enum

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

				info.MaxValue = 2^count - 1

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
		extend "IAttribute"

		doc "__AttributeUsage__" [[Specifies the usage of another attribute class.]]

		------------------------------------------------------
		-- Property
		------------------------------------------------------
		doc "AttributeTarget" [[The attribute target type, default AttributeTargets.All]]
		property "AttributeTarget" { Default = AttributeTargets.All, Type = AttributeTargets }

		doc "Inherited" [[Whether your attribute can be inherited by classes that are derived from the classes to which your attribute is applied.]]
		property "Inherited" { Type = Boolean }

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
		extend "IAttribute"

		doc "__Sealed__" [[Mark the feature to be sealed, and can't be re-defined again]]

		function ApplyAttribute(self, target, targetType)
			_NSInfo[target].Modifier = TurnOnFlags(MD_SEALED_FEATURE, _NSInfo[target].Modifier)
		end
	end)

	class "__Final__" (function(_ENV)
		extend "IAttribute"

		doc "__Final__" [[Mark the class|interface can't be inherited, or method|property can't be overwrited by child-classes]]

		function ApplyAttribute(self, target, targetType, owner, name)
			local info = _NSInfo[owner or target]
			if targetType == AttributeTargets.Interface or targetType == AttributeTargets.Class then
				info.Modifier = TurnOnFlags(MD_FINAL_FEATURE, info.Modifier)
			elseif _NSInfo[owner].Type == TYPE_INTERFACE or _NSInfo[owner].Type == TYPE_CLASS then
				info.FeatureModifier = info.FeatureModifier or {}
				info.FeatureModifier[name] = TurnOnFlags(MD_FINAL_FEATURE, info.FeatureModifier[name])
			end
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

		------------------------------------------------------
		-- For Attribute system
		------------------------------------------------------
		-- System.IAttribute
		__Sealed__:ApplyAttribute(IAttribute)

		-- System.AttributeTargets
		__Flags__:ApplyAttribute(AttributeTargets)
		__Sealed__:ApplyAttribute(AttributeTargets)

		-- System.__Unique__
		__AttributeUsage__{AttributeTarget = AttributeTargets.Class, RunOnce = true, BeforeDefinition = true}
		ConsumePreparedAttributes(__Unique__, AttributeTargets.Class)
		__Unique__:ApplyAttribute(__Unique__)
		__Sealed__:ApplyAttribute(__Unique__)

		-- System.__Flags__
		__AttributeUsage__{AttributeTarget = AttributeTargets.Enum, RunOnce = true}
		ConsumePreparedAttributes(__Flags__, AttributeTargets.Class)
		__Unique__:ApplyAttribute(__Flags__)
		__Sealed__:ApplyAttribute(__Flags__)

		-- System.__AttributeUsage__
		__AttributeUsage__{AttributeTarget = AttributeTargets.Class}
		ConsumePreparedAttributes(__AttributeUsage__, AttributeTargets.Class)
		__Sealed__:ApplyAttribute(__AttributeUsage__)
		__Final__:ApplyAttribute(__AttributeUsage__, AttributeTargets.Class)

		-- System.__Sealed__
		__AttributeUsage__{AttributeTarget = AttributeTargets.Class + AttributeTargets.Interface + AttributeTargets.Struct + AttributeTargets.Enum, RunOnce = true}
		ConsumePreparedAttributes(__Sealed__, AttributeTargets.Class)
		__Unique__:ApplyAttribute(__Sealed__)
		__Sealed__:ApplyAttribute(__Sealed__)

		-- System.__Final__
		__AttributeUsage__{AttributeTarget = AttributeTargets.Class + AttributeTargets.Interface + AttributeTargets.Method + AttributeTargets.Property, RunOnce = true, BeforeDefinition = true}
		ConsumePreparedAttributes(__Final__, AttributeTargets.Class)
		__Unique__:ApplyAttribute(__Final__)
		__Sealed__:ApplyAttribute(__Final__)

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
	end

	__AttributeUsage__{AttributeTarget = AttributeTargets.Property + AttributeTargets.Method, RunOnce = true }
	__Sealed__() __Unique__()
	class "__Static__" (function(_ENV)
		extend "IAttribute"
		doc "__Static__" [[Used to mark the features as static.]]

		------------------------------------------------------
		-- Method
		------------------------------------------------------
		function ApplyAttribute(self, target, targetType, owner, name)
			if targetType == AttributeTargets.Property then
				target.IsStatic = true
			elseif targetType == AttributeTargets.Method then
				local info = _NSInfo[owner]

				info.FeatureModifier = info.FeatureModifier or {}
				info.FeatureModifier[name] = TurnOnFlags(MD_STATIC_FEATURE, info.FeatureModifier[name])
			end
		end
	end)

	__Sealed__()
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
				if info.SubType == STRUCT_TYPE_MEMBER then
					if info.Validator then return true end
					if info.Members then for _, n in ipairs(info.Members) do if isCloneNeeded(n.Type) then return true end end end
				elseif info.SubType == STRUCT_TYPE_ARRAY then
					return isCloneNeeded(info.ArrayElement and info.ArrayElement.Type)
				elseif info.SubType == STRUCT_TYPE_CUSTOM and info.Validator then
					return true
				end
			end

			return false
		end

		function Argument(value)
			if value.Type and value.Default ~= nil then
				value.Default = GetValidatedValue(value.Type, value.Default)
			end

			-- Auto generate Default
			if value.Default == nil and value.Type and value.Nilable then
				local info = _NSInfo[value.Type]
				if info and (info.Type == TYPE_STRUCT or info.Type == TYPE_ENUM) then value.Default = info.Default end
			end

			-- Whether the value should be clone, argument match would change some value, Just for safe
			value.CloneNeeded = isCloneNeeded(value.Type)
		end
	end)

	__AttributeUsage__{AttributeTarget = AttributeTargets.Method + AttributeTargets.Constructor, RunOnce = true }
	__Sealed__()
	class "__Arguments__" (function(_ENV)
		extend "IAttribute"

		doc "__Arguments__" [[The overload argument definitions for the target method or constructor]]

		_Error_Header = [[Usage : __Arguments__{ arg1[, arg2[, ...] ] } : ]]
		_Error_NotArgument = [[arg%d must be System.Argument]]
		_Error_NotOptional = [[arg%d must also be optional]]
		_Error_NotList = [[arg%d can't be a list]]

		_OverLoad = setmetatable({}, WEAK_KEY)

		local function serializeData(data)
			if type(data) == "string" then
				return strformat("%q", data)
			elseif type(data) == "number" or type(data) == "boolean" then
				return tostring(data)
			elseif type(data) == "table" and not Reflector.IsNameSpace(data) then
				local cache = CACHE_TABLE()

				tinsert(cache, "{")

				for k, v in pairs(data) do
					if type(k) == "number" or type(k) == "string" then
						local vs = serializeData(v)

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
				return tostring(data)
			else
				-- Don't support any point values
				return nil
			end
		end

		local function serialize(data, ns)
			if type(ns) == "string" then ns = GetNameSpaceForName(ns) end

			if _NSInfo[ns] then
				if Reflector.IsEnum(ns) then
					if _NSInfo[ns].MaxValue and type(data) == "number" then
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
					if Reflector.GetStructType(ns) == STRUCT_TYPE_MEMBER and type(data) == "table" then
						local members = Reflector.GetStructMembers(ns, {})

						if not members or not next(members) then
							return tostring(ns) .. "( )"
						else
							local ret = tostring(ns) .. "( "

							for i, member in ipairs(members) do
								local sty = Reflector.GetStructMember(ns, member)
								local value = data[member]

								value = serializeData(value, sty)

								if i == 1 then
									ret = ret .. tostring(value)
								else
									ret = ret .. ", " .. tostring(value)
								end
							end

							ret = ret .. " )"

							return ret
						end
					elseif Reflector.GetStructType(ns) == STRUCT_TYPE_ARRAY and type(data) == "table" then
						local ret = tostring(ns) .. "( "

						sty = Reflector.GetStructArrayElement(ns)

						for i, v in ipairs(data) do
							v = serialize(v, sty)

							if i == 1 then
								ret = ret .. tostring(v)
							else
								ret = ret .. ", " .. tostring(v)
							end
						end

						ret = ret .. " )"

						return ret
					elseif type(data) == "table" and type(data.__tostring) == "function" then
						return data:__tostring()
					else
						return serializeData(data)
					end
				end
			else
				-- Serialize normal datas
				return serializeData(data)
			end
		end

		local function validateArgument(self, i)
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

				return
			end

			error(_Error_Header .. _Error_NotArgument:format(i))
		end

		local function buildUsage(overLoads, info)
			if info.Usage then return info.Usage end

			-- Check if this is a static method
			if overLoads.HasSelf == nil then
				overLoads.HasSelf = true
				if overLoads.TargetType == AttributeTargets.Method then
					if Reflector.IsInterface(overLoads.Owner) and Reflector.IsFinal(overLoads.Owner) then overLoads.HasSelf = false end
					if overLoads.Name == "__exist" or Reflector.IsStaticMethod(overLoads.Owner, overLoads.Name) then overLoads.HasSelf = false end
				end
			end

			-- Generate usage message
			local usage = CACHE_TABLE()
			local name = overLoads.Name
			local owner = overLoads.Owner

			if overLoads.TargetType == AttributeTargets.Method then
				if not overLoads.HasSelf then
					tinsert(usage, "Usage : " .. tostring(owner) .. "." .. name .. "( ")
				else
					if overLoads.IsMeta and name:match("^___") then name = name:sub(2, -1) end
					tinsert(usage, "Usage : " .. tostring(owner) .. ":" .. name .. "( ")
				end
			else
				tinsert(usage, "Usage : " .. tostring(owner) .. "( ")
			end

			for i = 1, #info do
				local arg = info[i]
				local str = ""

				if i > 1 then tinsert(usage, ", ") end

				-- [name As type = default]
				if arg.Name then
					str = str .. arg.Name

					if arg.Type then str = str .. " As " end
				end

				if arg.Type then str = str .. tostring(arg.Type) end

				if arg.Default ~= nil and i > info.MinArgs then
					local default = serialize(arg.Default, arg.Type)

					if default then str = str .. " = " .. default end
				end

				if not arg.Type or arg.Nilable then str = "[" .. str .. "]" end

				tinsert(usage, str)
			end

			tinsert(usage, " )")

			info.Usage = tblconcat(usage, "")

			CACHE_TABLE(usage)

			return info.Usage
		end

		local function getSuperOverLoad(overLoads)
			if overLoads.TargetType == AttributeTargets.Constructor then
				-- Check super class's constructor
				local info = _NSInfo[_NSInfo[overLoads.Owner].SuperClass]

				while info and not info.Constructor do info = _NSInfo[info.SuperClass] end

				if info then
					local func = info.Constructor
					return _OverLoad[func] or func
				end
			elseif overLoads.IsMeta then
				-- Check super class's constructor
				local info = _NSInfo[_NSInfo[overLoads.Owner].SuperClass]
				if info then
					local func = info.MetaTable[overLoads.Name]
					return _OverLoad[func] or func
				end
			else
				local info = _NSInfo[overLoads.Owner]
				local name = overLoads.Name
				local func

				-- Check super class first
				if info.SuperClass then
					func = _NSInfo[info.SuperClass].Cache[name]

					if type(func) == "function" then return _OverLoad[func] or func end
				end

				-- Check extended interface
				if info.ExtendInterface then
					for _, IF in ipairs(info.ExtendInterface) do
						func = _NSInfo[IF].Cache[name]

						if type(func) == "function" then return _OverLoad[func] or func end
					end
				end
			end
		end

		local function getUsage(method, index)
			local overLoads = _OverLoad[method]

			if overLoads then
				index = (index or 0) + 1

				local info = overLoads[index]

				if info then return index, buildUsage(overLoads, info) end
			end
		end

		local function raiseError(overLoads)
			-- Check if this is a static method
			if overLoads.HasSelf == nil then
				overLoads.HasSelf = true
				if overLoads.TargetType == AttributeTargets.Method then
					if Reflector.IsInterface(overLoads.Owner) and Reflector.IsFinal(overLoads.Owner) then overLoads.HasSelf = false end
					if overLoads.Name == "__exist" or Reflector.IsStaticMethod(overLoads.Owner, overLoads.Name) then overLoads.HasSelf = false end
				end
			end

			-- Generate the usage list
			local usage = CACHE_TABLE()

			local index = 1
			local info = overLoads[index]

			while info do
				local fUsage = buildUsage(overLoads, info)
				local params = fUsage:match("Usage : %w+.(.+)")

				if params and not usage[params] then
					usage[params] = true
					tinsert(usage, fUsage)
				end

				index = index + 1
				info = overLoads[index]

				if not info then
					overLoads = getSuperOverLoad(overLoads)

					if type(overLoads) == "table" then
						index = 1
						info = overLoads[index]
					end
				end
			end

			local msg = tblconcat(usage, "\n")
			CACHE_TABLE(usage)

			error(msg, 2)
		end

		local function callOverLoadMethod( overLoads, ... )
			if overLoads.HasSelf == nil then
				overLoads.HasSelf = true
				if overLoads.TargetType == AttributeTargets.Method then
					if Reflector.IsInterface(overLoads.Owner) and Reflector.IsFinal(overLoads.Owner) then overLoads.HasSelf = false end
					if overLoads.Name == "__exist" or Reflector.IsStaticMethod(overLoads.Owner, overLoads.Name) then overLoads.HasSelf = false end
				end
			end

			local base = overLoads.HasSelf and 1 or 0
			local object = overLoads.HasSelf and ... or nil
			local count = select('#', ...) - base

			local cache = CACHE_TABLE()

			-- Cache first
			for i = 1, count do cache[i] = select(i+base, ...) end

			local coverLoads = overLoads
			local index = 1
			local info = coverLoads[index]
			local zeroMethod

			while info do
				local argsCount = #info
				local argsChanged = false
				local matched = true
				local maxCnt = count

				if argsCount == 0 and not zeroMethod then
					if count == 0 then return info.Method( ... ) end
					zeroMethod = info
				end

				-- Check argument settings
				if count >= info.MinArgs and count <= info.MaxArgs then
					-- Required
					for i = 1, info.MinArgs do
						local arg = info[i]
						local value = cache[i]

						if value == nil then
							-- Required argument can't be nil
							matched = false
							break
						elseif arg.Type then
							-- Clone if needed
							if arg.CloneNeeded then value = CloneObj(value, true) end
							-- Validate the value
							value = GetValidatedValue(arg.Type, value)
							if value == nil then
								matched = false
								break
							end
						end

						if cache[i] ~= value then
							argsChanged = true
							cache[i] = value
						end
					end

					-- Optional
					if matched then
						for i = info.MinArgs + 1, count >= argsCount and count or argsCount do
							local arg = info[i] or info[argsCount]
							local value = cache[i]

							if value == nil then
								-- No check
								if arg.Default ~= nil then value = CloneObj(arg.Default, true) end
							elseif arg.Type then
								-- Clone if needed
								if arg.CloneNeeded then value = CloneObj(value, true) end
								-- Validate the value
								value = GetValidatedValue(arg.Type, value)
								if value == nil then
									matched = false
									break
								end
							end

							if cache[i] ~= value then
								argsChanged = true
								cache[i] = value
								if i > maxCnt then maxCnt = i end
							end
						end
					end

					if matched then
						if not argsChanged then
							CACHE_TABLE(cache)
							cache = nil
						end

						if cache then
							if base == 1 then
								return info.Method( object, unpack(cache, 1, maxCnt) )
							else
								return info.Method( unpack(cache, 1, maxCnt) )
							end
						else
							return info.Method( ... )
						end
					elseif argsChanged then
						for i = 1, count do cache[i] = select(i+base, ...) end
					end
				end

				index = index + 1
				info = coverLoads[index]

				if not info then
					coverLoads = getSuperOverLoad(coverLoads)

					if type(coverLoads) == "function" then
						CACHE_TABLE(cache)
						return coverLoads( ... )
					elseif coverLoads then
						index = 1
						info = coverLoads[index]
					end
				end
			end

			if zeroMethod and count == 1 and overLoads.TargetType == AttributeTargets.Constructor then
				-- Check if the first arg is a init-table
				local data = cache[1]

				if type(data) == "table" and getmetatable(data) == nil then
					zeroMethod.Method( object )

					for k, v in pairs(data) do object[k] = v end

					return
				end
			end

			-- No match
			CACHE_TABLE(cache)
			return raiseError(overLoads)
		end

		------------------------------------------------------
		-- Method
		------------------------------------------------------
		function ApplyAttribute(self, target, targetType, owner, name)
			local isMeta = false

			-- Self validation once
			for i = 1, #self do validateArgument(self, i) end

			if targetType == AttributeTargets.Constructor then
				name = Reflector.GetNameSpaceName(owner)
			elseif _KeyMeta[name] then
				-- Meta-methods
				isMeta = true
			end

			if not self.MinArgs then self.MinArgs = #self end
			if not self.MaxArgs then self.MaxArgs = #self end
			if not self.Method then self.Method = target end

			_OverLoad[owner] = _OverLoad[owner] or {}
			_OverLoad[owner][name] = _OverLoad[owner][name] or {
				TargetType = targetType,
				Owner = owner,
				Name = name,
			}

			local overLoads = _OverLoad[owner][name]
			if not overLoads[0] then
				overLoads[0] = function(...) return callOverLoadMethod(overLoads, ...) end
				if isMeta then overLoads.IsMeta = true end

				-- For quick access
				_OverLoad[ overLoads[0] ] = overLoads
			end

			-- Insert or replace
			for _, info in ipairs(overLoads) do
				if #self == #info and self.MinArgs == info.MinArgs then
					local isEqual = true

					for i = 1, #self do
						if not IsEqual(self[i], info[i]) then
							isEqual = false
							break
						end
					end

					if isEqual then
						info.Method = self.Method
						return overLoads[0]
					end
				end
			end

			local overLoadInfo = {}
			for k, v in pairs(self) do overLoadInfo[k] = v end

			tinsert(overLoads, 1, overLoadInfo)

			return overLoads[0]
		end

		doc "GetOverloadUsage" [[Return the usage of the target method]]
		__Static__() function GetOverloadUsage(ns, name)
			if type(ns) == "function" then return getUsage, ns end
			local info = _NSInfo[ns]
			if info and (info.Cache or info.Method) then
				local tar = info.Cache[name] or info.Method[name]
				if type(tar) == "function" then return getUsage, tar end
			end
		end
	end)

	-- More usable attributes
	__AttributeUsage__{AttributeTarget = AttributeTargets.Event + AttributeTargets.Method, RunOnce = true}
	__Sealed__() __Unique__()
	class "__Delegate__" (function(_ENV)
		extend "IAttribute"
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
		end

		__Arguments__{ Function }
		function __Delegate__(self, value)
			self.Delegate = value
		end
	end)

	__AttributeUsage__{AttributeTarget = AttributeTargets.Class, RunOnce = true}
	__Sealed__() __Unique__()
	class "__Cache__" (function(_ENV)
		extend "IAttribute"
		doc "__Cache__" [[Mark the class so its objects will cache any methods they accessed, mark the method so the objects will cache the method when they are created, if using on an interface, all object methods defined in it would be marked with __Cache__ attribute .]]

		function ApplyAttribute(self, target, targetType, owner, name)
			_NSInfo[target].AutoCache = true
		end
	end)

	enum "StructType" {
		"MEMBER",
		"ARRAY",
		"CUSTOM"
	}

	__AttributeUsage__{AttributeTarget = AttributeTargets.Struct, RunOnce = true, BeforeDefinition = true}
	__Sealed__() __Unique__()
	class "__StructType__" (function(_ENV)
		extend "IAttribute"

		doc "__StructType__" [[Mark the struct's type, default 'Member']]

		------------------------------------------------------
		-- Method
		------------------------------------------------------
		function ApplyAttribute(self, target, targetType)
			if Reflector.IsStruct(target) then
				local info = _NSInfo[target]

				if self.Type == StructType.Member then
					-- use member list, default type
					info.SubType = STRUCT_TYPE_MEMBER
					info.ArrayElement = nil
				elseif self.Type == StructType.Array then
					-- user array list
					info.SubType = STRUCT_TYPE_ARRAY
					info.Members = nil
				else
					-- else all custom
					info.SubType = STRUCT_TYPE_CUSTOM
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
			self.Type = type
		end

		__Arguments__{ }
		function __StructType__(self)
			self.Type = StructType.Member
		end
	end)

	__AttributeUsage__{AttributeTarget = AttributeTargets.Struct, RunOnce = true}
	__Sealed__()
	class "__StructOrder__" (function(_ENV)
		extend "IAttribute"

		doc "__StructOrder__" [[Rearrange the struct member's order]]

		------------------------------------------------------
		-- Method
		------------------------------------------------------
		function ApplyAttribute(self, target, targetType)
			local info = _NSInfo[target]

			if info.SubType == StructType.Member and info.Members then
				local cache = CACHE_TABLE()

				for i, mem in ipairs(info.Members) do tinsert(cache, mem.Name) cache[mem.Name] = mem end
				wipe(info.Members)

				for i, name in ipairs(self) do if cache[name] then tinsert(info.Members, cache[name]) cache[name] = nil end end
				for i, name in ipairs(cache) do if cache[name] then tinsert(info.Members, cache[name]) end end

				CACHE_TABLE(cache)
			end
		end

		------------------------------------------------------
		-- Constructor
		------------------------------------------------------
		__Arguments__ { String }
	    function __StructOrder__(self, name)
	    	tinsert(self, name)
	    end

	    function __call(self, name)
	    	if type(name) == "string" then
	    		tinsert(self, name)
	    	end
	    	return self
	    end
	end)

	__AttributeUsage__{AttributeTarget = AttributeTargets.Class, RunOnce = true, BeforeDefinition = true}
	__Sealed__() __Unique__()
	class "__Abstract__" (function(_ENV)
		extend "IAttribute"
		doc "__Abstract__" [[Mark the class as abstract class, can't be used to create objects.]]

		function ApplyAttribute(self, target, targetType)
			_NSInfo[target].Modifier = TurnOnFlags(MD_ABSTRACT_CLASS, _NSInfo[target].Modifier)
		end
	end)

	__AttributeUsage__{AttributeTarget = AttributeTargets.Class, RunOnce = true}
	__Sealed__() __Unique__()
	class "__InitTable__" (function(_ENV)
		extend "IAttribute"

		doc "__InitTable__" [[Used to mark the class can use init table like: obj = cls(name) { Age = 123 }]]

		__Arguments__{ RawTable }
		function InitWithTable(self, initTable)
			for name, value in pairs(initTable) do self[name] = value end

			return self
		end

		function ApplyAttribute(self, target, targetType)
			if _NSInfo[target] and _NSInfo[target].Type == TYPE_CLASS then
				return SaveMethod(_NSInfo[target], "__call", __InitTable__["InitWithTable"])
			end
		end
	end)

	__AttributeUsage__{AttributeTarget = AttributeTargets.Interface + AttributeTargets.Method + AttributeTargets.Property + AttributeTargets.Member, RunOnce = true}
	__Sealed__() __Unique__()
	class "__Require__" (function(_ENV)
		extend "IAttribute"

		doc "__Require__" [[Whether the method or property is required to be override, or a member of a struct is required, or set the required class|interface for an interface.]]

		------------------------------------------------------
		-- Method
		------------------------------------------------------
		function ApplyAttribute(self, target, targetType, owner, name)
			if targetType == AttributeTargets.Interface then
				if self.Require then return SaveRequire(info, self.Require) end
			else
				local info = _NSInfo[owner]

				if info and type(name) == "string" then
					if targetType == AttributeTargets.Member then
						target.Require = true
					else
						info.FeatureModifier = info.FeatureModifier or {}
						info.FeatureModifier[name] = TurnOnFlags(MD_REQUIRE_FEATURE, info.FeatureModifier[name])
					end
				end
			end
		end

		------------------------------------------------------
		-- Constructor
		------------------------------------------------------
		__Arguments__{}
		function __Require__(self)
			self.Require = nil
		end

		__Arguments__{ Class }
		function __Require__(self, value)
			local IFInfo = rawget(_NSInfo, value)
			if ValidateFlags(MD_FINAL_FEATURE, IFInfo.Modifier) then
				error(("%s is marked as final, can't be used with __Require__ ."):format(tostring(value)), 3)
			end
			self.Require = value
		end

		__Arguments__{ String }
		function __Require__(self, value)
			value = GetNameSpace(PROTYPE_NAMESPACE, value)

			local IFInfo = rawget(_NSInfo, value)

			if not IFInfo or IFInfo.Type ~= TYPE_CLASS then
				error("Usage: __Require__ (class) : class expected", 3)
			elseif ValidateFlags(MD_FINAL_FEATURE, IFInfo.Modifier) then
				error(("%s is marked as final, can't be used with __Require__ ."):format(tostring(value)), 3)
			end

			self.Require = value
		end
	end)

	__AttributeUsage__{AttributeTarget = AttributeTargets.Property, RunOnce = true}
	__Sealed__() __Unique__()
	class "__Synthesize__" (function(_ENV)
		extend "IAttribute"

		doc "__Synthesize__" [[Used to generate property accessors automatically]]

		enum "NameCases" {
			"Camel",	-- setName
			"Pascal",	-- SetName
		}

		------------------------------------------------------
		-- Static Property
		------------------------------------------------------
		doc "NameCase" [[The name case of the generate method, in one program, only need to be set once, default is Pascal case]]
		property "NameCase" { Type = NameCases, Default = NameCases.Pascal, IsStatic = true }

		------------------------------------------------------
		-- Property
		------------------------------------------------------
		doc "Get" [[The get method name]]
		property "Get" { Type = String }

		doc "Set" [[The set method name]]
		property "Set" { Type = String }

		------------------------------------------------------
		-- Method
		------------------------------------------------------
		function ApplyAttribute(self, target, targetType, owner, name)
			target.Synthesize = __Synthesize__.NameCase
			target.SynthesizeGet = self.Get
			target.SynthesizeSet = self.Set
		end

		------------------------------------------------------
		-- Constructor
		------------------------------------------------------
		__Arguments__ {}
		function __Synthesize__(self)
			self.Get = nil
			self.Set = nil
		end
	end)

	__AttributeUsage__{AttributeTarget = AttributeTargets.Property, RunOnce = true}
	__Sealed__() __Unique__()
	class "__Event__" (function(_ENV)
		extend "IAttribute"

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
		end

		__Arguments__{ Event }
		function __Event__(self, value)
			self.Event = value
		end

		__Arguments__{ String }
		function __Event__(self, value)
			self.Event = value
		end
	end)

	__AttributeUsage__{AttributeTarget = AttributeTargets.Property, RunOnce = true}
	__Sealed__() __Unique__()
	class "__Handler__" (function(_ENV)
		extend "IAttribute"

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
		end

		__Arguments__{ HandlerType }
		function __Handler__(self, value)
			self.Handler = value
		end
	end)

	__AttributeUsage__{AttributeTarget = AttributeTargets.Struct + AttributeTargets.Enum + AttributeTargets.Property + AttributeTargets.Member, RunOnce = true}
	__Sealed__() __Unique__()
	class "__Default__" (function(_ENV)
		extend "IAttribute"

		doc "__Default__" [[Used to set a default value for features like custom struct, enum, struct member, property]]

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

			if targetType == AttributeTargets.Property or targetType == AttributeTargets.Member then
				target.Default = self.Default
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
		end

		__Arguments__{ Any }
		function __Default__(self, value)
			self.Default = value
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

	__AttributeUsage__{AttributeTarget = AttributeTargets.Property, RunOnce = true}
	__Sealed__() __Unique__()
	class "__Setter__" (function(_ENV)
		extend "IAttribute"

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
		end

		__Arguments__{ Setter }
		function __Setter__(self, value)
			self.Setter = value
		end
	end)

	__AttributeUsage__{AttributeTarget = AttributeTargets.Property, RunOnce = true}
	__Sealed__() __Unique__()
	class "__Getter__" (function(_ENV)
		extend "IAttribute"

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
		end

		__Arguments__{ Getter }
		function __Getter__(self, value)
			self.Getter = value
		end
	end)

	__AttributeUsage__{RunOnce = true, BeforeDefinition = true}
	__Sealed__() __Unique__()
	class "__Doc__" (function(_ENV)
		extend "IAttribute"

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

	__AttributeUsage__{AttributeTarget = AttributeTargets.Class + AttributeTargets.Interface + AttributeTargets.Struct + AttributeTargets.Enum, RunOnce = true, BeforeDefinition = true}
	__Sealed__() __Unique__()
	class "__NameSpace__" (function(_ENV)
		extend "IAttribute"
		doc "__NameSpace__" [[Used to set the namespace directly.]]

		------------------------------------------------------
		-- Method
		------------------------------------------------------
		function ApplyAttribute(self) return PrepareNameSpace(nil) end

		------------------------------------------------------
		-- Constructor
		------------------------------------------------------
		function __NameSpace__(self, ns)
			if IsNameSpace(ns) then
				PrepareNameSpace(ns)
			elseif type(ns) == "string" then
				PrepareNameSpace(BuildNameSpace(PROTYPE_NAMESPACE, ns))
			elseif ns == nil or ns == false then
				PrepareNameSpace(false)
			else
				error([[Usage: __NameSpace__(name|nil|false)]], 2)
			end
		end
	end)

	__AttributeUsage__{AttributeTarget = AttributeTargets.Class, RunOnce = true}
	__Sealed__() __Unique__()
	class "__SimpleClass__" (function(_ENV)
		extend "IAttribute"
		doc "__SimpleClass__" [[
			Mark the class as a simple class, if the class is a real simple class, the init-table would be converted as the object.
			If the class is not a simple class, the system would check the init-table's key-value pairs:
				i.   The table don't have key equals the class's property name.
				ii.  The table don't have key equals the class's event name.
				iii. The table don't have key equals the class's method name, or the value is a function.
			If the init-table follow the three rules, it would be converted as the class's object directly.
		]]

		------------------------------------------------------
		-- Method
		------------------------------------------------------
		function ApplyAttribute(self, target) _NSInfo[target].AsSimpleClass = true end
	end)

	__AttributeUsage__{AttributeTarget = AttributeTargets.Class + AttributeTargets.Interface, RunOnce = true, BeforeDefinition = true}
	__Sealed__() __Unique__()
	class "__AutoProperty__" (function(_ENV)
		extend "IAttribute"
		doc "__AutoProperty__" [[Mark the class|interface to bind property with method automatically.]]

		function ApplyAttribute(self, target, targetType)
			_NSInfo[target].Modifier = TurnOnFlags(MD_AUTO_PROPERTY, _NSInfo[target].Modifier)
		end
	end)
end

------------------------------------------------------
-- System Namespace (Object & Module)
------------------------------------------------------
do
	------------------------------------------------------
	-- System.ICloneable
	------------------------------------------------------ICloneable
	__Doc__ [[Supports cloning, which creates a new instance of a class with the same value as an existing instance.]]
	interface "ICloneable" (function(_ENV)
		------------------------------------------------------
		-- Method
		------------------------------------------------------
		__Require__()
		__Doc__[[Creates a new object that is a copy of the current instance.]]
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

		function __call(self, version, stack)
			stack = stack or 2
			local info = _ModuleInfo[self]

			if not info then error("The module is disposed", stack) end

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
								error("The version must be greater than the current version of the module.", stack)
							end
						else
							info.Version = version
						end
					else
						info.Version = version
					end
				else
					error("The version string should contain version numbers like 'Ver 1.2323.13'.", stack)
				end
			elseif info.Version then
				error("An available version is need for the module.", stack)
			end

			if not FAKE_SETFENV then setfenv(stack, self) end

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
		env.interface = interface
		env.class = class
		env.struct = struct
		env.enum = enum

		env.namespace = env.namespace or namespace
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
