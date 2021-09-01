--!strict
local DataStoreService = game:GetService("DataStoreService")

local Classes = script.Parent
local Key = require(Classes.Key)
local Query = require(Classes.Query)
local Transaction = require(Classes.Transaction)

local class = {}
class.__index = class
class.__newindex = function(self, what: string, to: table)
	assert(to.ClassName == "Column", "Model only accepts Column objects as values.")
	assert(#what <= 50, "Key cannot be longer than 50 characters")

	self.__columns[what] = to
end
class.__metatable = "LOCKED"

local options = Instance.new("DataStoreOptions")
options:SetExperimentalFeatures{
	v2 = true;
}

function class:GetColumn(name: string): {}
	return self.__columns[name]
end

function class:GetColumnList()
	local columns = {}

	for i, v in pairs(self.__columns) do
		columns[i] = v
	end

	return columns
end

function class:NewKey(index: string): {}
	return Key.new(self, index)
end

function class:NewTransaction()
	return Transaction.new(self)
end

local constructor = {}

function constructor.new(name: string, scope: string?, datastoreService: any?): {}
	local self = {
		__columns = {};
		__datastore = (datastoreService or DataStoreService):GetDataStore(name, scope or nil, options);
	}

	self.Query = Query.new(self)
	self.Session = Transaction.new(self, true)

	return setmetatable(self, class)
end

return constructor