--!strict
local Classes = script.Parent
local QueryKey = require(Classes.QueryKey)
local Libraries = script.Parent.Parent.Libraries
local Promise = require(Libraries.Promise)

local class = {}
class.__metatable = "LOCKED"
class.__index = class
class.__newindex = function()
	error("This class is read-only!", 2)
end

function class:GetCurrent()
	local pages = self.__pages
	local model = self.__model

	return Promise.async(function(resolve, reject)
		local success, currentPage = pcall(function()
			return pages:GetCurrentPage()
		end)

		if success then
			local result = {}

			for _, datastoreKey in pairs(currentPage) do
				table.insert(result, QueryKey.new(datastoreKey, model, self.__name))
			end

			resolve(result)
		else
			reject(currentPage)
		end
	end)
end

function class:GetNext()
	local pages = self.__pages

	return Promise.async(function(resolve, reject)
		if pages.IsFinished then
			reject("No more pages to get")
		else
			local success, result = pcall(function()
				pages:AdvanceToNextPageAsync()
			end)

			if success then
				local ok, value = self:GetCurrent():await()
				if ok then
					resolve(value)
				else
					reject(value)
				end
			else
				reject(result)
			end
		end
	end)
end

local constructor = {}

function constructor.new(datastoreKeyPages: DataStoreKeyPages | DataStoreVersionPages, model: table, name: string?): {}
	return setmetatable({
		__pages = datastoreKeyPages;
		__model = model;
		__name = name;
	}, class)
end

return constructor