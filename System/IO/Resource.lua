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
	_ResourceMapInfo = setmetatable({}, {__mode="kv"})

	----------------------------------
	-- FileLoadInfo
	----------------------------------
	FileLoadInfo = class {
		-- Property
		RequireReLoad = { Type = Boolean },

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

	function FileLoadInfo:Load(...)
		local path = self.Path
		local lastWriteTime

		if self.Resource then
			if Resource.ReloadWhenModified then
				local getLastWriteTime = Resource.GetLastWriteTime

				if self.RequireReLoad then
					self.RequireReLoad = false
				else
					lastWriteTime = getLastWriteTime(path)

					if not lastWriteTime then
						if File.Exist(path) then
							-- Failed to get the last writed time, wait for the next time
							return self.Resource
						end
						-- File not existed
						self.Resource = nil
						return
					end

					if lastWriteTime == self.LastWriteTime then
						local noModifed = true

						if self.RequireFileInfo then
							for info in pairs(self.RequireFileInfo) do
								local writedTime = getLastWriteTime(info.Path)

								if writedTime and writedTime ~= info.LastWriteTime then
									noModifed = false
									break
								end
							end
						end

						if noModifed then return self.Resource end
					end
				end
			else
				return self.Resource
			end
		end

		local suffix = Path.GetSuffix(path)
		local loader = suffix and __ResourceLoader__.GetResourceLoader(suffix)
		if loader then
			local res = loader():Load(path, ...)
			if res ~= nil then
				_ResourcePathMap[path] = self
				_ResourceMapInfo[res] = self

				if Resource.ReloadWhenModified then
					-- Notice other files to be reloaed
					if self.NoticeFileInfo and self.Resource ~= res then for info in pairs(self.NoticeFileInfo) do info.RequireReLoad = true end end

					self.LastWriteTime = lastWriteTime or Resource.GetLastWriteTime(path)
					Trace("[System.IO.Resource][Record][lastWriteTime]%s - %s", path, self.LastWriteTime)
				end
				self.Resource = res
				Debug("[System.IO.Resource][Generate] %s", tostring(res))
			else
				_ResourcePathMap[path] = nil
				if self.Resource then _ResourceMapInfo[self.Resource] = nil end
				self.Resource = nil
				Info("[System.IO.Resource][Nothing loaded] %s", path)
			end
			return res
		end
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
	function LoadResource(path, ...)
		if type(path) ~= "string" then return end
		path = path:lower()

		Trace("[System.IO.Resource][LoadResource] %s", path)

		local fileLoadInfo = FileLoadInfo(path)

		tinsert(_ResourceLoadStack, fileLoadInfo)

		local ok, res = pcall(fileLoadInfo.Load, fileLoadInfo, ...)

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