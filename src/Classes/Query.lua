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

function class:FilterByKey(key: string, version: number?): table
	local model = self.__model
	local datastore = model.__datastore

	return Promise.async(function(resolve, reject)
		local success, value, keyInfo = pcall(function()
			if version then
				return datastore:GetVersionAsync(key, version)
			else
				return datastore:GetAsync(key)
			end
		end)

		if success then
			local result = model:NewKey(key)
			if keyInfo then
				result:__SetKeyInfo(keyInfo)
			end

			for name, column in pairs(model:GetColumnList()) do
				result[name] = column:deserialize(value[name]) or column.Default
			end

			resolve(result)
		else
			reject(value)
		end
	end)
end

function class:FilterByPrefix(prefix: string?, pageSize: int?)
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

function class:FilterByKeyVersion(key: string, sortDirection: Enum.SortDirection?, minDate: int?, maxDate: int?, pageSize: int?)
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