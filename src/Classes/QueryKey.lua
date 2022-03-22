--!strict
local Libraries = script.Parent.Parent.Libraries
local Promise = require(Libraries.Promise)

local class = {}
class.__metatable = "LOCKED"
class.__index = class
class.__newindex = function()
	error("This class is read-only!", 2)
end

function class:Get(version: number?)
	local model = self.__model
	local key = self.Name

	if self.Version then
		-- If we have a version, we need to get the specific version
		return model.Query:FilterByKey(key, self.Version)
	else
		-- Otherwise, we can just get the latest version or the specified version
		return model.Query:FilterByKey(key, version)
	end
end

local constructor = {}

function constructor.new(datastoreKey: DataStoreKey | DataStoreObjectVersionInfo, model: table, name: string?): {}
	-- Generate a new QueryKey depending on what type of object we were given
	if datastoreKey:IsA("DataStoreObjectVersionInfo") then
		-- This has version info, fill in the extra info it provides and return the QueryKey
		return setmetatable({
			__key = datastoreKey;
			__model = model;

			Name = name or datastoreKey.KeyName;
			CreatedTime = datastoreKey.CreatedTime;
			IsDeleted = datastoreKey.IsDeleted;
			Version = datastoreKey.Version;
		}, class)
	else
		-- This is an ordinary DataStoreKey, return the QueryKey without any extra info
		return setmetatable({
			__key = datastoreKey;
			__model = model;
			Name = name or datastoreKey.KeyName;
		}, class)
	end
end

return constructor