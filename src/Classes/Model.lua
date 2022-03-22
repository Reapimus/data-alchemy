--!strict
local DataStoreService = game:GetService("DataStoreService")

local Classes = script.Parent
local Key = require(Classes.Key)
local Query = require(Classes.Query)
local Transaction = require(Classes.Transaction)

local class = {}
class.__index = class
class.__newindex = function(self, what: string, to: table)
	-- Enforce value class type and the datastore key length limit of 50 characters
	assert(to.ClassName == "Column", "Model only accepts Column objects as values.")
	assert(#what <= 50, "Key cannot be longer than 50 characters")

	self.__columns[what] = to
end
class.__metatable = "LOCKED"

-- Indicate that we intend to use DataStore V2
local options = Instance.new("DataStoreOptions")
options:SetExperimentalFeatures{
	v2 = true;
}

function class:GetColumn(name: string): {}
	return self.__columns[name]
end

function class:GetColumnList()
	local columns = {}

	-- Create a shallow copy of the internal column list to prevent accidental modification
	for i, v in pairs(self.__columns) do
		columns[i] = v
	end

	return columns
end

function class:NewKey(index: string): {}
	-- Generate a new key for use in transactions for this model
	return Key.new(self, index)
end

function class:NewTransaction()
	-- Generate a new transaction for this model
	return Transaction.new(self)
end

local constructor = {}

function constructor.new(name: string, scope: string?, datastoreService: any?): {}
	local self = {
		__columns = {};
		__datastore = (datastoreService or DataStoreService):GetDataStore(name, scope or nil, options);
	}

	self.Query = Query.new(self)

	-- A Session object is a pre-made Transaction object for this model that can be reused easily for multiple transactions/sessions, must be manually flushed if the transaction fails to commit
	self.Session = Transaction.new(self, true)

	return setmetatable(self, class)
end

return constructor