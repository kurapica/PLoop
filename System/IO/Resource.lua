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
	_ResourceMapInfo = setmetatable({}, {__mode="kv"})

	----------------------------------
	-- FileLoadInfo
	----------------------------------
	__Cache__()
	FileLoadInfo = class {
		-- Constructor
		function (self, path) self.Path = path end,
		-- Meta-method
		__exist = function(path) return _ResourcePathMap[path] end,
	}

	function FileLoadInfo:AddRequireFileInfo(info)
		self.RequireFileInfo = self.RequireFileInfo or {}
		self.RequireFileInfo[info] = true

		info.NoticeFileInfo = self.NoticeFileInfo or {}
		info.NoticeFileInfo[self] = true
	end

	function FileLoadInfo:CheckReload()
		local requireReload = self.RequireReLoad
		local path = self.Path

		-- Check the file
		if not requireReload then
			if not self.Resource then
				if File.Exist(path) then requireReload = true end
			else
				local lastWriteTime = Resource.GetLastWriteTime(path)

				if not lastWriteTime then
					if not File.Exist(path) then requireReload = true end
				elseif lastWriteTime ~= self.LastWriteTime then
					requireReload = true
				end
			end
		end

		-- Check the required files
		if not requireReload and self.RequireFileInfo then
			for info in pairs(self.RequireFileInfo) do info:CheckReload() end
		end

		-- Relod the file
		if requireReload or self.RequireReLoad then
			local res = self:LoadFile()
			if res ~= self.Resource then
				-- Notice the other files
				if self.NoticeFileInfo then
					for info in pairs(self.NoticeFileInfo) do
						if not info.Resource and not Reflector.GetUpperNameSpace(info.Resource) then
							info.RequireReLoad = true
						end
					end
				end
				if res then _ResourceMapInfo[res] = self end
				self.Resource = res
			end
		end

		return self.Resource
	end

	function FileLoadInfo:LoadFile()
		local path = self.Path
		local suffix = Path.GetSuffix(path)
		local loader = suffix and __ResourceLoader__.GetResourceLoader(suffix)
		local res
		if loader then
			local res = loader():Load(path)
			if Resource.ReloadWhenModified then self.LastWriteTime = Resource.GetLastWriteTime(path) end
			Debug("[System.IO.Resource][Generate] %s [For] %s", tostring(res), path)
			return res
		end
	end

	function FileLoadInfo:Load()
		local res = self.Resource

		if not res or Resource.ReloadWhenModified then
			res = self:CheckReload()
		end

		if res then
			_ResourcePathMap[self.Path] = self
		elseif _ResourcePathMap[self.Path] then
			if not self.NoticeFileInfo then
				_ResourcePathMap[self.Path] = nil
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
	_ResourceLoadStack = {}

	__Doc__[[Load the target resource files]]
	__Static__()
	function LoadResource(path)
		if type(path) ~= "string" then return end
		path = path:lower()

		Trace("[System.IO.Resource][LoadResource] %s", path)

		local fileLoadInfo = FileLoadInfo(path)

		tinsert(_ResourceLoadStack, fileLoadInfo)

		local ok, res = pcall(fileLoadInfo.Load, fileLoadInfo)

		tremove(_ResourceLoadStack)

		if ok and res then
			for _, info in ipairs(_ResourceLoadStack) do
				Trace("[System.IO.Resource]%s[Require]%s", info.Path, fileLoadInfo.Path)
				info:AddRequireFileInfo(fileLoadInfo)
			end

			return res
		else
			Error("[System.IO.Resource][Load Fail] %s - %s", path, res)
		end
	end

	__Doc__[[Get the resource's path]]
	__Static__()
	function GetResourcePath(res) return _ResourceMapInfo[res] and _ResourceMapInfo[res].Path end
end)

-- Bind the default func
Resource.GetLastWriteTime = File.GetLastWriteTime