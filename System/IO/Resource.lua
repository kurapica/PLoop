--=============================
-- System.IO.Resource
--
-- Author : Kurapica
-- Create Date : 2016/01/28
--=============================
_ENV = Module "System.IO.Resource" "1.0.1"

namespace "System.IO"

__Doc__ [[The interface for the file loaders.]]
__Sealed__()
interface "IResourceLoader" (function (_ENV)
	__Doc__ [[Load the target resource]]
	__Require__() function Load(self, path, ...) end
end)

__Doc__ [[The resource loader for specific suffix files to generate type features or others.]]
__AttributeUsage__{AttributeTarget = AttributeTargets.Class, RunOnce = true}
__Final__() __Sealed__()
class "__ResourceLoader__" (function (_ENV)
	extend "IAttribute"

	_ResourceLoader = {}

	__Doc__[[The suffix of the file.]]
	property "Suffix" { Type = String }

	__Static__()
	__Doc__[[Get the resource loader for specific suffix]]
	function GetResourceLoader(suffix) return _ResourceLoader[suffix] end

	function ApplyAttribute(self, target)
		assert(Reflector.IsExtendedInterface(target, IResourceLoader), "The class must extend System.IO.IResourceLoader.")

		local suffix = self.Suffix and self.Suffix:lower()
		if suffix then
			if not suffix:find("^%.") then suffix = "." .. suffix end
			_ResourceLoader[suffix] = target
		end
	end

	__Arguments__{ String }
	function __ResourceLoader__(self, name) self.Suffix = name end
end)

__Final__() __Sealed__() __Abstract__()
class "Resource" (function (_ENV)
	_ResourcePathMap = {}
	_ResourcePathModifiedTime = {}
	_ResourceMapPath = setmetatable({}, {__mode="k"})
	_RelatedPath = {}

	--local _RootResource = nil

	----------------------------------
	-- Static Property
	----------------------------------
	__Static__()
	property "ReloadWhenModified" { Type = Boolean }

	__Static__()
	property "AutoAddRelatedPath" { Type = Boolean }

	__Static__()
	property "GetLastWriteTime" { Type = Callable }

	----------------------------------
	-- Static Method
	----------------------------------
	__Doc__[[Load the target resource files]]
	function LoadResource(path, ...)
		if type(path) ~= "string" then return end
		path = path:lower()

		Trace("[Resource][LoadResource] %s", path)

		--[[if not _RootResource then
			_RootResource = path
		elseif AutoAddRelatedPath then
			AddRelatedPath(_RootResource, path)
		end--]]

		local getLastWriteTime = Resource.GetLastWriteTime
		local lastModifiedTime

		if _ResourcePathMap[path] ~= nil then
			if not ReloadWhenModified then return _ResourcePathMap[path] end

			lastModifiedTime = getLastWriteTime(path)

			Trace("[Resource][Check][lastModifiedTime]%s - %s", path, lastModifiedTime)

			if lastModifiedTime == _ResourcePathModifiedTime[path] then
				local noModifed = true
				if _RelatedPath[path] then
					for _, rpath in ipairs(_RelatedPath[path]) do
						if _ResourcePathModifiedTime[rpath] ~= getLastWriteTime(rpath) then
							noModifed = false
							break
						end
					end
				end
				if noModifed then return _ResourcePathMap[path] end
			end
		end

		local suffix = Path.GetSuffix(path)
		local loader = suffix and __ResourceLoader__.GetResourceLoader(suffix)
		if loader then
			local res = loader():Load(path, ...)
			if res ~= nil then
				_ResourcePathMap[path] = res
				_ResourceMapPath[res] = path
			end
			if ReloadWhenModified then
				_ResourcePathModifiedTime[path] = lastModifiedTime or getLastWriteTime(path)
				Trace("[Resource][Save][lastModifiedTime]%s - %s", path, _ResourcePathModifiedTime[path])
			end
			Debug("[Resource][New] %s", tostring(res))
			return res
		end

		--if _RootResource == path then _RootResource = nil end

		if not ok then error(ret) end
		return ret
	end

	__Doc__[[Add related path, so the modified time should also be checked]]
	function AddRelatedPath(main, related)
		if type(main) ~= "string" or type(related) ~= "string" then return end
		main = main:lower()
		related = related:lower()

		local set = _RelatedPath[main] or {}
		for _, v in ipairs(set) do if v == related then return end end

		tinsert(set, related)

		_RelatedPath[main] = set
	end

	__Doc__[[Get the resource's path]]
	function GetResourcePath(res)
		return _ResourceMapPath[res]
	end
end)

-- Bind the default func
Resource.GetLastWriteTime = File.GetLastWriteTime