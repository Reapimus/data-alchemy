--!strict
local Classes = script.Parent
local QueryResult = require(Classes.QueryResult)
local Libraries = script.Parent.Parent.Libraries
local Promise = require(Libraries.Promise)

local class = {}
class.__metatable = "LOCKED"
class.__index = class
class.__newindex = function()
	error("This class is read-only!", 2)
end

function class:FilterByKey(key: string, version: number?)
	local model = self.__model
	local datastore = model.__datastore

	return Promise.async(function(resolve, reject)
		local snapshotSuccess, snapshot, snapshotInfo = pcall(function()
			return datastore:GetAsync(key.."_SNAPSHOT")
		end)

		if snapshotSuccess then
			if snapshot and not version then
				if os.time() - snapshotInfo.CreatedTime > 5 then
					-- If the snapshot is older than 5 seconds, assume the server performing the transaction crashed and revert it.
					local setoptions = Instance.new("DataStoreSetOptions")
					setoptions:SetMetadata(snapshotInfo:GetMetadata())
					datastore:SetAsync(key, snapshot, snapshotInfo:GetUserIds(), setoptions)

					local result = model:NewKey(key)
					if snapshotInfo then
						result:__SetKeyInfo(snapshotInfo)
					end

					for name, column in pairs(model:GetColumnList()) do
						result[name] = column:deserialize(snapshot[name]) or column.Default
					end

					resolve(result)
				else
					-- Return the snapshot instead of the actual value just in case the transaction fails while we are getting the key's value.
					local result = model:NewKey(key)
					if snapshotInfo then
						result:__SetKeyInfo(snapshotInfo)
					end

					for name, column in pairs(model:GetColumnList()) do
						result[name] = column:deserialize(snapshot[name]) or column.Default
					end

					resolve(result)
				end
			else
				local success, value, keyInfo = pcall(function()
					if version then
						return datastore:GetVersionAsync(key, version)
					else
						return datastore:GetAsync(key)
					end
				end)

				if success then
					if value then
						local result = model:NewKey(key)
						if keyInfo then
							result:__SetKeyInfo(keyInfo)
						end

						for name, column in pairs(model:GetColumnList()) do
							result[name] = column:deserialize(value[name]) or column.Default
						end

						resolve(result)
					else
						resolve(nil)
					end
				else
					reject(value)
				end
			end
		else
			reject(snapshot)
		end
	end)
end

function class:FilterByPrefix(prefix: string?, pageSize: number?)
	local model = self.__model
	local datastore = model.__datastore

	return Promise.async(function(resolve, reject)
		local success, pages = pcall(function()
			return datastore:ListKeysAsync(prefix, pageSize)
		end)

		if success then
			resolve(QueryResult.new(pages, model))
		else
			reject(pages)
		end
	end)
end

function class:FilterByKeyVersion(key: string, sortDirection: Enum.SortDirection?, minDate: number?, maxDate: number?, pageSize: number?)
	local model = self.__model
	local datastore = model.__datastore

	return Promise.async(function(resolve, reject)
		local success, pages = pcall(function()
			return datastore:ListVersionsAsync(key, sortDirection, minDate, maxDate, pageSize)
		end)

		if success then
			resolve(QueryResult.new(pages, model, key))
		else
			reject(pages)
		end
	end)
end

local constructor = {}

function constructor.new(model)
	return setmetatable({
		__model = model;
	}, class)
end

return constructor