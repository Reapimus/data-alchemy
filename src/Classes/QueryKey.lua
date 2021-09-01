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
		return model.Query:FilterByKey(key, self.Version)
	else
		return model.Query:FilterByKey(key, version)
	end
end

local constructor = {}

function constructor.new(datastoreKey: DataStoreKey | DataStoreObjectVersionInfo, model: table, name: string?): {}
	if datastoreKey:IsA("DataStoreObjectVersionInfo") then
		return setmetatable({
			__key = datastoreKey;
			__model = model;

			Name = name or datastoreKey.KeyName;
			CreatedTime = datastoreKey.CreatedTime;
			IsDeleted = datastoreKey.IsDeleted;
			Version = datastoreKey.Version;
		}, class)
	else
		return setmetatable({
			__key = datastoreKey;
			__model = model;
			Name = name or datastoreKey.KeyName;
		}, class)
	end
end

return constructor