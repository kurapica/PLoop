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
	__Require__() function Load(self, path) end
end)

__Doc__ [[The resource loader for specific suffix files to generate type features or others.]]
__AttributeUsage__{AttributeTarget = AttributeTargets.Class, RunOnce = true, AllowMultiple = true}
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
	_ResourceMapInfo = setmetatable({}, {__mode="kv"})

	local preparePath

	if pcall(_G.require, [[PLoop.System.IO.casesensitivetest]]) then
		preparePath = function(path) return path:lower() end
	else
		preparePath = function(path) return path end
	end

	----------------------------------
	-- FileLoadInfo
	----------------------------------
	__Cache__()
	FileLoadInfo = class {
		-- Constructor
		function (self, path)
			self.Path = path
			self.ReloadWhenModified = Resource.ReloadWhenModified
			_ResourcePathMap[path] = self
		end,
		-- Meta-method
		__exist = function(path) return _ResourcePathMap[path] end,
	}

	function FileLoadInfo:AddRelatedPath(info)
		self.RequireFileInfo = self.RequireFileInfo or {}
		self.RequireFileInfo[info] = true

		info.NoticeFileInfo = self.NoticeFileInfo or {}
		info.NoticeFileInfo[self] = true
	end

	function FileLoadInfo:CheckReload()
		local requireReload = self.RequireReLoad

		Trace("[System.IO.Resource][CheckReload] %s - %s", self.Path, tostring(requireReload))

		-- Check the file
		if not requireReload then
			local path = self.Path

			if not self.Resource then
				if File.Exist(path) then
					Trace("[System.IO.Resource][CheckReload] Reload because File existed")
					requireReload = true
				end
			else
				local lastWriteTime = Resource.GetLastWriteTime(path)

				if not lastWriteTime then
					if not File.Exist(path) then
						Trace("[System.IO.Resource][CheckReload] Reload because File not existed")
						requireReload = true
					else
						Trace("[System.IO.Resource][CheckReload] Can't get changed status of the file")
					end
				elseif lastWriteTime ~= self.LastWriteTime then
					Trace("[System.IO.Resource][CheckReload] Reload because File changed at %s", lastWriteTime)
					requireReload = true
				else
					Trace("[System.IO.Resource][CheckReload]%s == %s", lastWriteTime, self.LastWriteTime)
				end
			end
		end

		-- Check the required files
		if not requireReload and self.RequireFileInfo then
			for info in pairs(self.RequireFileInfo) do info:Load() end
		end

		Trace("[System.IO.Resource][CheckReload] Result %s", tostring(requireReload or self.RequireReLoad))

		-- the RequireReLoad maybe changed by required files
		return requireReload or self.RequireReLoad
	end

	function FileLoadInfo:LoadFile()
		local path = self.Path
		local suffix = Path.GetSuffix(path)
		local loader = suffix and __ResourceLoader__.GetResourceLoader(suffix:lower())
		local res
		if loader then
			res = loader():Load(path) or false
			if res and self.ReloadWhenModified then self.LastWriteTime = Resource.GetLastWriteTime(path) end
			Debug("[System.IO.Resource][Generate] %s [For] %s", tostring(res), path)
		end

		self.RequireReLoad = false

		if res then
			_ResourcePathMap[path] = self
		elseif _ResourcePathMap[path] then
			if not self.NoticeFileInfo then
				_ResourcePathMap[path] = nil
			end
		end

		return res
	end

	function FileLoadInfo:Load()
		local res = self.Resource

		if res ~= nil and self.ReloadWhenModified and self:CheckReload() then
			if res and not Reflector.GetUpperNameSpace(res) and self.RequireFileInfo then
				-- Mark the same resource must be reloaded
				for info in pairs(self.RequireFileInfo) do if info.Resource == res then info.RequireReLoad = true end end
			end

			self.RequireReLoad = false
			res = nil
		end

		if not res then
			res = self:LoadFile()
			if res ~= self.Resource then
				-- Notice the other files
				if self.NoticeFileInfo and Resource.ReloadWhenModified then
					for info in pairs(self.NoticeFileInfo) do
						if info.Resource and not Reflector.GetUpperNameSpace(info.Resource) then
							info.RequireReLoad = true
						end
					end
				end
				if res then _ResourceMapInfo[res] = self end
				self.Resource = res
			end
		end

		return res
	end

	----------------------------------
	-- Static Property
	----------------------------------
	__Static__()
	property "ReloadWhenModified" { Type = Boolean }

	__Static__()
	property "GetLastWriteTime" { Type = Callable }

	----------------------------------
	-- Static Method
	----------------------------------
	__Doc__[[Load the target resource files]]
	__Static__()
	function LoadResource(path)
		if type(path) ~= "string" then return end
		path = preparePath(path)

		local ok, res = pcall(FileLoadInfo.Load, FileLoadInfo(path))

		if ok then return res end

		Error("[System.IO.Resource][Load Fail] %s - %s", path, res)
	end

	__Doc__[[Get the resource's path]]
	__Static__()
	function GetResourcePath(res) return _ResourceMapInfo[res] and _ResourceMapInfo[res].Path end

	__Doc__[[Add the related path for reload checking]]
	__Static__()
	__Arguments__{ String, String }
	function AddRelatedPath(path, related)
		local info = _ResourcePathMap[preparePath(path)]
		if info then
			info:AddRelatedPath(FileLoadInfo(preparePath(related)))
		end
	end

	__Doc__[[Mark the path reload when modified]]
	__Static__()
	__Arguments__{ String }
	function SetReloadRequired(path)
		FileLoadInfo(preparePath(path)).ReloadWhenModified = true
	end
end)

-- Bind the default func
Resource.GetLastWriteTime = File.GetLastWriteTime